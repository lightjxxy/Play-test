-- lang: Luau, file: wallrun_anim.lua
-- target: Roblox — Legacy Evade (executor: any)
-- wallrun anims + speed preservation + wall jump boost

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Character   = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- ── config ────────────────────────────────────────────────────────────────────
local ANIM_LEFT      = "rbxassetid://18688623622"
local ANIM_RIGHT     = "rbxassetid://18688628477"
local ANIM_NAME      = "WallrunAnim"
local BOOST_AMOUNT   = 20     -- studs/s added in wall-normal direction on wall jump
local BOOST_DURATION = 0.15   -- seconds to sustain the boost

-- ── state ─────────────────────────────────────────────────────────────────────
local currentTrack  = nil
local currentSide   = 0           -- 0 | 1 (wall left) | -1 (wall right)
local storedNormal  = Vector3.new()
local capturedSpeed = 0           -- XZ studs/s at the frame wallrun started
local isWallrunning = false

local boostDir   = Vector2.new()  -- XZ unit vector away from wall
local boostUntil = 0              -- tick() deadline; apply boost while tick() < boostUntil

local renderConn  = nil
local steppedConn = nil

-- ── raycast params ────────────────────────────────────────────────────────────
-- mirrors WallrunIgnoreList from Terms.lua exactly
local function makeWallParams(char)
    local params = RaycastParams.new()
    params.FilterType        = Enum.RaycastFilterType.Exclude
    params.IgnoreWater       = true
    params.RespectCanCollide = true

    local map  = workspace:FindFirstChild("Map")
    local list = { workspace.CurrentCamera, char }

    for _, v in ipairs({
        workspace:FindFirstChild("Effects"),
        workspace:FindFirstChild("Players"),
        workspace:FindFirstChild("Vehicles"),
        map and map:FindFirstChild("Ignore"),
        map and map:FindFirstChild("InvisParts"),
        map and map.Parts and map.Parts:FindFirstChild("Ladders"),
        map and map.Parts and map.Parts:FindFirstChild("Interactables"),
        map and map.Parts and map.Parts:FindFirstChild("Objectives"),
    }) do
        if v then table.insert(list, v) end
    end

    params.FilterDescendantsInstances = list
    return params
end

-- ── anim helpers ──────────────────────────────────────────────────────────────
local function getAnimator(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum:FindFirstChildOfClass("Animator")
end

local function stopAnim()
    if currentTrack then
        currentTrack:Stop(0.15)
        currentTrack = nil
    end
end

local function playAnim(char, id, side)
    if currentSide == side then return end
    stopAnim()
    local animator = getAnimator(char)
    if not animator then return end

    local anim       = Instance.new("Animation")
    anim.AnimationId = id
    anim.Name        = ANIM_NAME

    local track    = animator:LoadAnimation(anim)
    track.Priority = Enum.AnimationPriority.Action3
    track.Looped   = true
    track:Play(0.15)

    currentTrack = track
end

-- ── wall detection ────────────────────────────────────────────────────────────
-- reads the two character attributes the movement script writes every 0.1s:
--   "Grounded"      → bool
--   "MoveDirection" → Vector3 local-space input (X = strafe)
-- returns: side (0 | 1 | -1), wallNormal
local function detectWall(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return 0, Vector3.new() end

    if char:GetAttribute("Grounded") == true then return 0, Vector3.new() end

    local moveDir = char:GetAttribute("MoveDirection")
    if not moveDir or moveDir.X == 0 then return 0, Vector3.new() end

    local params    = makeWallParams(char)
    local halfWidth = hrp.Size.X / 2 + 0.9

    local function checkSide(dir)
        local result = workspace:Raycast(hrp.CFrame.p, dir, params)
        if not result then return false, Vector3.new() end
        local ang = math.deg(math.acos(math.clamp(
            result.Normal:Dot(Vector3.new(0, 1, 0)), -1, 1
        )))
        return (ang >= 85 and ang <= 95), result.Normal
    end

    if moveDir.X > 0 then
        local hit, n = checkSide(hrp.CFrame.rightVector * halfWidth)
        if hit then return -1, n end   -- wall on right
    elseif moveDir.X < 0 then
        local hit, n = checkSide(hrp.CFrame.rightVector * -halfWidth)
        if hit then return 1, n end    -- wall on left
    end

    return 0, Vector3.new()
end

-- ── speed preservation + boost hook ──────────────────────────────────────────
-- Stepped fires between Heartbeat (where movement sets PlaneVelocity = d/90)
-- and physics (which reads PlaneVelocity to drive the LinearVelocity constraint).
-- Modifying PlaneVelocity here affects exactly one physics frame per Stepped call.
-- Speed preservation: clamp PlaneVelocity magnitude upward to capturedSpeed each frame.
-- Boost: add boostDir * BOOST_AMOUNT to PlaneVelocity each frame until deadline.
-- Both are NOT accumulative — movement resets PlaneVelocity to d/90 each Heartbeat,
-- and we re-apply on the next Stepped. Net effect: sustained +N studs/s override.
local function hookStepped()
    if steppedConn then steppedConn:Disconnect() end

    steppedConn = RunService.Stepped:Connect(function()
        if not Character or not Character.Parent then return end
        local hrp = Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local lv = hrp:FindFirstChildOfClass("LinearVelocity")
        if not lv then return end

        -- ── speed preservation ──
        if isWallrunning and capturedSpeed > 0 then
            local pv  = lv.PlaneVelocity
            local mag = pv.Magnitude
            if mag > 0.1 and mag < capturedSpeed then
                lv.PlaneVelocity = pv.Unit * capturedSpeed
            end
        end

        -- ── wall jump boost ──
        if tick() < boostUntil and boostDir.Magnitude > 0.01 then
            lv.PlaneVelocity = lv.PlaneVelocity + boostDir * BOOST_AMOUNT
        end
    end)
end

-- ── main loop (anim state + wallrun tracking) ─────────────────────────────────
local function startLoop()
    if renderConn then renderConn:Disconnect() end

    renderConn = RunService.RenderStepped:Connect(function()
        if not Character or not Character.Parent then return end

        local hum = Character:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then
            isWallrunning = false
            capturedSpeed = 0
            currentSide   = 0
            stopAnim()
            return
        end

        local side, normal = detectWall(Character)

        if side == 0 then
            if isWallrunning then
                -- left the wall — clear wallrun state
                isWallrunning = false
                capturedSpeed = 0
                storedNormal  = Vector3.new()
            end
            currentSide = 0
            stopAnim()
        else
            if not isWallrunning then
                -- just touched a wall — lock in current speed
                capturedSpeed = Character:GetAttribute("CurrentMoveSpeed") or 0
                isWallrunning = true
            end

            storedNormal = normal
            currentSide  = side

            if side == -1 then
                playAnim(Character, ANIM_RIGHT, -1)
            else
                playAnim(Character, ANIM_LEFT,  1)
            end
        end
    end)
end

-- ── wall jump boost trigger ───────────────────────────────────────────────────
-- fires when player presses jump while wallrunning AND is pressing
-- the opposite strafe direction (away from the wall)
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode ~= Enum.KeyCode.Space
    and input.KeyCode ~= Enum.KeyCode.ButtonB then return end
    if not isWallrunning then return end

    -- check "opposite way" — player must be pressing away from the wall
    local moveDir    = Character and Character:GetAttribute("MoveDirection")
    local awayFromWall = moveDir and (
        (currentSide == -1 and moveDir.X < 0) or   -- wall right, pressing left  ✓
        (currentSide ==  1 and moveDir.X > 0)       -- wall left,  pressing right ✓
    )

    if awayFromWall then
        local nXZ = Vector2.new(storedNormal.X, storedNormal.Z)
        if nXZ.Magnitude > 0.01 then
            boostDir   = nXZ.Unit
            boostUntil = tick() + BOOST_DURATION
        end
    end
end)

-- ── respawn handling ──────────────────────────────────────────────────────────
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character     = newChar
    isWallrunning = false
    capturedSpeed = 0
    currentSide   = 0
    boostUntil    = 0
    boostDir      = Vector2.new()
    stopAnim()
    task.wait(0.5)
    startLoop()
    hookStepped()
end)

-- ── boot ──────────────────────────────────────────────────────────────────────
task.wait(1)
startLoop()
hookStepped()
print("[wallrun] ready — anims + speed preservation + wall jump boost")
