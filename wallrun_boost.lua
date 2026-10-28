-- lang: Luau, file: wallrun_boost.lua
-- target: Roblox — Legacy Evade (executor: any)
-- wallrun anim + upward climb force + wall-launch as function (mobile safe)

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
local CLIMB_FORCE   = 18     -- upward velocity added per frame while wallrunning
local LAUNCH_H      = 28     -- vertical kick on wall-launch
local LAUNCH_SIDE   = 1.2    -- lateral kick multiplier away from wall
local MOV_SCALE     = 90     -- movement table multiplier (match game's internal)

-- ── state ─────────────────────────────────────────────────────────────────────
local currentTrack    = nil
local currentSide     = 0        -- 0=none | 1=left | -1=right
local lastWallNormal  = Vector3.new(0, 0, 0)
local loopConn        = nil
local cachedMovTable  = nil

local function getMovementTable(char)
    if cachedMovTable and rawget(cachedMovTable, "Character") == char then
        return cachedMovTable
    end
    for _, obj in ipairs(getgc(true)) do
        if type(obj) == "table" then
            if rawget(obj, "Character") == char and rawget(obj, "d") and rawget(obj, "h") then
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
    if currentTrack then
        currentTrack:Stop(0.15)
        currentTrack = nil
    end
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
local function detectSide(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return 0 end
    if char:GetAttribute("Grounded") == true then return 0 end

    local moveDir = char:GetAttribute("MoveDirection")
    if not moveDir or moveDir.X == 0 then return 0 end

    local params    = makeWallParams(char)
    local halfWidth = hrp.Size.X / 2 + 0.9

    local function wallHit(rayDir)
        local result = workspace:Raycast(hrp.CFrame.p, rayDir, params)
        if not result then return false, Vector3.zero end
        local angle = math.deg(math.acos(
            math.clamp(result.Normal:Dot(Vector3.new(0, 1, 0)), -1, 1)
        ))
        return (angle >= 85 and angle <= 95), result.Normal
    end

    if moveDir.X > 0 then
        local hit, normal = wallHit(hrp.CFrame.rightVector * halfWidth)
        if hit then
            lastWallNormal = normal
            return -1
        end
    elseif moveDir.X < 0 then
        local hit, normal = wallHit(hrp.CFrame.rightVector * -halfWidth)
        if hit then
            lastWallNormal = normal
            return 1
        end
    end

    return 0
end

-- ── wall launch — standalone function (mobile + desktop) ─────────────────────
local function doWallLaunch(char)
    if not char or not char.Parent then return end
    if char:GetAttribute("Grounded") ~= false then return end

    local side = detectSide(char)
    if side == 0 then return end

    local movTable = getMovementTable(char)
    if not (movTable and movTable.Character and movTable.Character.PrimaryPart) then return end

    local hrp = movTable.Character.PrimaryPart

    local wallAway   = Vector3.new(lastWallNormal.X, 0, lastWallNormal.Z).Unit
    local forward    = hrp.CFrame.LookVector
    local launchFlat = (forward + wallAway * LAUNCH_SIDE).Unit
    local launchDir  = Vector3.new(launchFlat.X, 0, launchFlat.Z).Unit

    local horizontal = launchDir * 20 * MOV_SCALE
    local vertical   = Vector3.new(0, LAUNCH_H * MOV_SCALE, 0)

    movTable.d = movTable.d + horizontal + vertical
end

-- ── upward climb force ────────────────────────────────────────────────────────
local function applyClimbForce(char)
    local movTable = getMovementTable(char)
    if not (movTable and movTable.Character and movTable.Character.PrimaryPart) then return end
    movTable.d = movTable.d + Vector3.new(0, CLIMB_FORCE * MOV_SCALE, 0)
end

-- ── input (desktop jump / mobile JumpRequest) ─────────────────────────────────
UserInputService.JumpRequest:Connect(function()
    doWallLaunch(Character)
end)

-- ── main loop ─────────────────────────────────────────────────────────────────
local function startLoop()
    if loopConn then loopConn:Disconnect() end

    loopConn = RunService.RenderStepped:Connect(function()
        if not Character or not Character.Parent then return end

        local hum = Character:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then
            stopAnim()
            return
        end

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
    stopAnim()
    task.wait(0.5)
    startLoop()
end)

-- ── boot ──────────────────────────────────────────────────────────────────────
task.wait(1)
startLoop()
print("[wallrun_boost] ready")
