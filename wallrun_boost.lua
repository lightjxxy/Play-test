-- lang: Luau, file: wallrun_boost.lua
-- target: Roblox — Legacy Evade (executor: any)
-- wallrun anim + climb force + quake-style wall launch + speed calculator
-- mobile fix: grace window, loosened grounded check, both-side cast

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Character   = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- ── IDs ───────────────────────────────────────────────────────────────────────
local ANIM_LEFT  = "rbxassetid://18688623622"
local ANIM_RIGHT = "rbxassetid://18688628477"
local ANIM_NAME  = "WallrunAnim"

-- ── tuning ────────────────────────────────────────────────────────────────────
local CLIMB_FORCE      = 18
local LAUNCH_H         = 28
local LAUNCH_SIDE      = 1.8
local LAUNCH_FWD       = 0.7
local MOV_SCALE        = 90
local WALL_GRACE       = 0.35   -- seconds after leaving wall that launch still fires (mobile tap lag)

local DEFAULT_WISHSPEED = 30
local DEFAULT_ACCEL     = 10
local LAUNCH_FRAMES     = 6

-- ── state ─────────────────────────────────────────────────────────────────────
local currentTrack    = nil
local currentSide     = 0
local lastWallNormal  = Vector3.new(0, 0, 0)
local lastWallSide    = 0        -- last confirmed side (-1 / 1)
local lastWallTime    = -999     -- tick() of last frame we had a wall
local loopConn        = nil
local cachedMovTable  = nil

local function getMovementTable(char)
    if cachedMovTable and rawget(cachedMovTable, "Character") == char then
        return cachedMovTable
    end
    for _, obj in ipairs(getgc(true)) do
        if type(obj) == "table" then
            if rawget(obj, "Character") == char
            and rawget(obj, "d")
            and rawget(obj, "h") then
                cachedMovTable = obj
                return obj
            end
        end
    end
    return nil
end

-- ── raycast params ────────────────────────────────────────────────────────────
local function makeWallParams(char)
    local params = RaycastParams.new()
    params.FilterType        = Enum.RaycastFilterType.Exclude
    params.IgnoreWater       = true
    params.RespectCanCollide = true

    local map        = workspace:FindFirstChild("Map")
    local mapIgnore  = map and map:FindFirstChild("Ignore")
    local invisParts = map and map:FindFirstChild("InvisParts")
    local ladders    = map and map.Parts and map.Parts:FindFirstChild("Ladders")
    local interact   = map and map.Parts and map.Parts:FindFirstChild("Interactables")
    local objectives = map and map.Parts and map.Parts:FindFirstChild("Objectives")
    local vehicles   = workspace:FindFirstChild("Vehicles")
    local wpPlayers  = workspace:FindFirstChild("Players")
    local effects    = workspace:FindFirstChild("Effects")

    local list = { workspace.CurrentCamera, char }
    for _, v in ipairs({ effects, wpPlayers, vehicles, mapIgnore,
                         invisParts, ladders, interact, objectives }) do
        if v then table.insert(list, v) end
    end
    params.FilterDescendantsInstances = list
    return params
end

-- ── animation helpers ─────────────────────────────────────────────────────────
local function getAnimator(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    return hum:FindFirstChildOfClass("Animator")
end

local function stopAnim()
    if currentTrack then currentTrack:Stop(0.15); currentTrack = nil end
    currentSide = 0
end

local function playAnim(char, id, side)
    if currentSide == side then return end
    stopAnim()
    local animator = getAnimator(char)
    if not animator then return end
    local anim       = Instance.new("Animation")
    anim.AnimationId = id
    anim.Name        = ANIM_NAME
    local track      = animator:LoadAnimation(anim)
    track.Priority   = Enum.AnimationPriority.Action3
    track.Looped     = true
    track:Play(0.15)
    currentTrack = track
    currentSide  = side
end

-- ── wallrun detection ─────────────────────────────────────────────────────────
-- FIX: cast both sides when airborne — mobile joystick rarely gives a clean X value
local function detectSide(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return 0 end

    -- FIX: treat nil Grounded as airborne (mobile attribute lag)
    local grounded = char:GetAttribute("Grounded")
    if grounded == true then return 0 end

    local params    = makeWallParams(char)
    local halfWidth = hrp.Size.X / 2 + 0.9

    local function wallHit(rayDir)
        local result = workspace:Raycast(hrp.CFrame.p, rayDir, params)
        if not result then return false, Vector3.zero end
        local angle = math.deg(math.acos(
            math.clamp(result.Normal:Dot(Vector3.new(0,1,0)), -1, 1)
        ))
        return (angle >= 85 and angle <= 95), result.Normal
    end

    -- FIX: always check both sides — don't gate on moveDir.X anymore
    -- right wall
    local hitR, normalR = wallHit(hrp.CFrame.rightVector * halfWidth)
    if hitR then
        lastWallNormal = normalR
        lastWallSide   = -1
        lastWallTime   = tick()
        return -1
    end

    -- left wall
    local hitL, normalL = wallHit(hrp.CFrame.rightVector * -halfWidth)
    if hitL then
        lastWallNormal = normalL
        lastWallSide   = 1
        lastWallTime   = tick()
        return 1
    end

    return 0
end

-- ── quake Accelerate ──────────────────────────────────────────────────────────
local function QuakeAccelerate(vel, wishdir, wishspeed, accel, dt)
    local currentspeed = vel:Dot(wishdir)
    local addspeed     = wishspeed - currentspeed
    if addspeed <= 0 then return vel end
    local accelspeed = math.min(accel * wishspeed * dt, addspeed)
    return vel + wishdir * accelspeed
end

-- ── speed calculator ──────────────────────────────────────────────────────────
local function calcLaunchSpeed(velRaw, wishdir, wishspeed, accel)
    local dt  = 1/60
    local vel = velRaw / MOV_SCALE

    local speedBefore = vel.Magnitude
    local flatVel     = Vector3.new(vel.X, 0, vel.Z)

    for _ = 1, LAUNCH_FRAMES do
        flatVel = QuakeAccelerate(flatVel, wishdir, wishspeed, accel, dt)
    end

    local finalVel   = Vector3.new(flatVel.X, vel.Y + LAUNCH_H, flatVel.Z)
    local speedAfter = finalVel.Magnitude

    print(string.format(
        "[wallrun_boost] launch | before: %.2f | after: %.2f | gain: +%.2f studs/s",
        speedBefore, speedAfter, speedAfter - speedBefore
    ))

    return finalVel * MOV_SCALE
end

-- ── wall launch ───────────────────────────────────────────────────────────────
local function doWallLaunch(char)
    if not char or not char.Parent then return end

    -- FIX: treat nil as airborne
    local grounded = char:GetAttribute("Grounded")
    if grounded == true then return end

    -- live check first
    local side = detectSide(char)

    -- FIX: grace window — if we lost the wall within WALL_GRACE seconds, still launch
    -- covers mobile tap timing where JumpRequest fires a frame after thumb lifts
    if side == 0 then
        if (tick() - lastWallTime) <= WALL_GRACE and lastWallSide ~= 0 then
            side = lastWallSide
        else
            return
        end
    end

    local movTable = getMovementTable(char)
    if not (movTable and movTable.Character and movTable.Character.PrimaryPart) then return end

    local hrp = movTable.Character.PrimaryPart

    local wallAway   = Vector3.new(lastWallNormal.X, 0, lastWallNormal.Z).Unit
    local forward    = hrp.CFrame.LookVector
    local launchFlat = (forward * LAUNCH_FWD + wallAway * LAUNCH_SIDE).Unit
    local wishdir    = Vector3.new(launchFlat.X, 0, launchFlat.Z).Unit

    local wishspeed = rawget(movTable, "maxspeed")
                   or rawget(movTable, "s")
                   or DEFAULT_WISHSPEED
    local accel     = rawget(movTable, "accel")
                   or rawget(movTable, "a")
                   or DEFAULT_ACCEL

    -- consume grace so double-tap can't fire twice
    lastWallSide = 0
    lastWallTime = -999

    local newVel = calcLaunchSpeed(movTable.d, wishdir, wishspeed, accel)
    movTable.d   = newVel
end

-- ── climb force ───────────────────────────────────────────────────────────────
local function applyClimbForce(char)
    local movTable = getMovementTable(char)
    if not (movTable and movTable.Character and movTable.Character.PrimaryPart) then return end
    movTable.d = movTable.d + Vector3.new(0, CLIMB_FORCE * MOV_SCALE, 0)
end

-- ── input ─────────────────────────────────────────────────────────────────────
UserInputService.JumpRequest:Connect(function()
    doWallLaunch(Character)
end)

-- ── main loop ─────────────────────────────────────────────────────────────────
local function startLoop()
    if loopConn then loopConn:Disconnect() end
    loopConn = RunService.RenderStepped:Connect(function()
        if not Character or not Character.Parent then return end
        local hum = Character:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then stopAnim(); return end

        local side = detectSide(Character)
        if side == 0 then
            stopAnim()
        elseif side == -1 then
            playAnim(Character, ANIM_RIGHT, -1)
            applyClimbForce(Character)
        elseif side == 1 then
            playAnim(Character, ANIM_LEFT, 1)
            applyClimbForce(Character)
        end
    end)
end

-- ── respawn ───────────────────────────────────────────────────────────────────
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character      = newChar
    cachedMovTable = nil
    lastWallSide   = 0
    lastWallTime   = -999
    stopAnim()
    task.wait(0.5)
    startLoop()
end)

-- ── boot ──────────────────────────────────────────────────────────────────────
task.wait(1)
startLoop()
print("[wallrun_boost] ready")
