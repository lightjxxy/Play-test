-- lang: Luau, file: wallrun_anim.lua
-- target: Roblox — Legacy Evade (executor: any)
-- plays directional wallrun anims using the game's own character attributes

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Character   = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- ── IDs ───────────────────────────────────────────────────────────────────────
local ANIM_LEFT  = "rbxassetid://18688623622"
local ANIM_RIGHT = "rbxassetid://18688628477"
local ANIM_NAME  = "WallrunAnim"

-- ── state ─────────────────────────────────────────────────────────────────────
local currentTrack = nil
local currentSide  = 0   -- 0 = none  |  1 = left  |  -1 = right
local loopConn     = nil

-- ── raycast params ────────────────────────────────────────────────────────────
-- mirrors WallrunIgnoreList from Terms.lua
local function makeWallParams(char)
    local params = RaycastParams.new()
    params.FilterType            = Enum.RaycastFilterType.Exclude
    params.IgnoreWater           = true
    params.RespectCanCollide     = true

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
    if currentSide == side then return end   -- already correct

    stopAnim()

    local animator = getAnimator(char)
    if not animator then return end

    local anim        = Instance.new("Animation")
    anim.AnimationId  = id
    anim.Name         = ANIM_NAME

    local track       = animator:LoadAnimation(anim)
    track.Priority    = Enum.AnimationPriority.Action3
    track.Looped      = true
    track:Play(0.15)

    currentTrack = track
    currentSide  = side
end

-- ── wallrun detection ─────────────────────────────────────────────────────────
-- mirrors WallrunDirection CalculateFunction in Terms.lua
-- uses the two character attributes the movement script already writes:
--   "Grounded"     → bool
--   "MoveDirection" → Vector3 (camera-relative input unit, X = strafe)
local function detectSide(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return 0 end

    -- must be in the air
    if char:GetAttribute("Grounded") == true then return 0 end

    local moveDir = char:GetAttribute("MoveDirection")
    if not moveDir or moveDir.X == 0 then return 0 end

    local params    = makeWallParams(char)
    local halfWidth = hrp.Size.X / 2 + 0.9

    local function wallHit(rayDir)
        local result = workspace:Raycast(hrp.CFrame.p, rayDir, params)
        if not result then return false end
        local angle = math.deg(math.acos(
            math.clamp(result.Normal:Dot(Vector3.new(0, 1, 0)), -1, 1)
        ))
        return angle >= 85 and angle <= 95
    end

    if moveDir.X > 0 then
        -- strafing right → cast right → wall on right side
        if wallHit(hrp.CFrame.rightVector * halfWidth) then
            return -1   -- RIGHT wall → RIGHT anim
        end
    elseif moveDir.X < 0 then
        -- strafing left → cast left → wall on left side
        if wallHit(hrp.CFrame.rightVector * -halfWidth) then
            return 1    -- LEFT wall → LEFT anim
        end
    end

    return 0
end

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
        elseif side == 1 then
            playAnim(Character, ANIM_LEFT, 1)
        end
    end)
end

-- ── respawn ───────────────────────────────────────────────────────────────────
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    stopAnim()
    task.wait(0.5)
    startLoop()
end)

-- ── boot ──────────────────────────────────────────────────────────────────────
task.wait(1)
startLoop()
print("[wallrun_anim] ready")
