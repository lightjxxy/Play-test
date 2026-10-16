-- lang: Luau, file: evade_surf.lua, target: Roblox / Evade, executor: Xeno or equivalent
-- strips the AdminGhostEnabled gate, builds AlignOrientation on the fly, guards the GUI ref

local players           = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService        = game:GetService("RunService")
local debris            = game:GetService("Debris")

local LocalPlayer        = players.LocalPlayer
local character          = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoid           = character:WaitForChild("Humanoid")
local humanoidRootPart   = character:WaitForChild("HumanoidRootPart")
local CurrentCamera      = workspace.CurrentCamera

-- Speed GUI: create a minimal one if Evade's hasn't loaded
local number do
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    local sc = pg:FindFirstChild("Speed Counter")
    if sc then
        number = sc:FindFirstChild("Number")
    end
    if not number then
        local sg  = Instance.new("ScreenGui"); sg.Name = "Speed Counter"; sg.ResetOnSpawn = false; sg.Parent = pg
        local lbl = Instance.new("TextLabel");  lbl.Name = "Number"
        lbl.Size = UDim2.new(0,100,0,40); lbl.Position = UDim2.new(0.5,-50,0,10)
        lbl.BackgroundTransparency = 1; lbl.TextColor3 = Color3.new(1,1,1)
        lbl.TextScaled = true; lbl.Font = Enum.Font.GothamBold; lbl.Text = ""
        lbl.Parent = sg; number = lbl
    end
end

local workspaceGravity      = workspace.Gravity
local humanoidWalkSpeed     = humanoid.WalkSpeed
local humanoidJumpPower     = humanoid.JumpPower
local humanoidPlatformStand = humanoid.PlatformStand
local currentCameraFOV      = CurrentCamera.FieldOfView

local vector3    = Vector3.new()
local connection = nil
local clone      = nil
local clone2     = nil
local attachment = nil
local u19        = false
local u20        = false
local n1, n2     = 0, 0
local u25        = false

local function resetSpeedDisplay()
    n1 = 0; n2 = 0; u25 = false; number.Text = ""
end

local function updateSpeedLabel(speed, dt)
    if not u25 then n2 = speed; n1 = math.floor(speed + 0.5); u25 = true end
    n2 += (speed - n2) * (1 - math.exp(-4 * dt))
    if n2 >= n1 + 0.85 or n2 <= n1 - 0.85 then n1 = math.floor(n2 + 0.5) end
    number.Text = tostring(n1)
end

local function cleanupMovement()
    if connection then connection:Disconnect(); connection = nil end
    if clone      then clone:Destroy();        clone      = nil end
    if clone2     then clone2:Destroy();       clone2     = nil end
    if attachment then attachment:Destroy();   attachment = nil end
    vector3 = Vector3.new(); u20 = false
    humanoid.PlatformStand    = humanoidPlatformStand
    humanoid.WalkSpeed        = humanoidWalkSpeed
    humanoid.JumpPower        = humanoidJumpPower
    workspace.Gravity         = workspaceGravity
    CurrentCamera.FieldOfView = currentCameraFOV
    resetSpeedDisplay()
end

local function enableMovement()
    if u19 then return end
    u19 = true
    vector3 = Vector3.new(); u20 = false
    resetSpeedDisplay()

    -- physics setup
    humanoid.PlatformStand    = true
    humanoid.WalkSpeed        = 0
    humanoid.JumpPower        = 1
    workspace.Gravity         = 0
    CurrentCamera.FieldOfView = 100
    character.PrimaryPart     = humanoidRootPart

    -- collision sphere (must exist in Evade's ReplicatedStorage)
    clone = replicatedStorage:WaitForChild("Collision"):Clone()
    clone.CollisionGroup = "PlayerCollider"
    clone.Position = humanoidRootPart.Position
    clone.Parent   = workspace

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = { character, clone }
    raycastParams.RespectCanCollide = true

    -- weld clone → HRP
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = clone; weld.Part1 = humanoidRootPart; weld.Parent = clone

    -- rotate HRP flat (surf orientation)
    humanoidRootPart:PivotTo(clone.CFrame * CFrame.Angles(0, 0, -math.pi / 2))

    -- AlignOrientation built inline (no script children on injection)
    local ao = Instance.new("AlignOrientation")
    ao.RigidityEnabled   = false
    ao.MaxAngularVelocity = 1e5
    ao.MaxTorque         = 1e5
    clone2     = ao
    attachment = Instance.new("Attachment")
    attachment.Parent  = humanoidRootPart
    ao.Attachment0     = attachment
    ao.Parent          = humanoidRootPart
    ao.Enabled         = true

    local Y = Vector3.new(0, 1, 0)

    connection = runService.RenderStepped:Connect(function(dt)
        if not u19 then return end
        if not clone then return end

        local onGround = workspace:Raycast(clone.Position, Vector3.new(0, -3.3, 0), raycastParams)

        if onGround then
            -- grounded: strafe accel (CS surf wish-vel)
            local md     = humanoid.MoveDirection
            local wish   = (vector3 - vector3 * Y):Dot(md)
            local addspd = md.Magnitude * 20
            if addspd - wish > 0 then
                vector3 += md * (addspd * 15 * dt)
            end
            -- ground friction
            local horiz = vector3 - vector3 * Y
            local drop  = 10 * dt
            vector3 = if horiz.Magnitude - drop < 0
                      then vector3 - horiz
                      else vector3 - horiz * drop
        else
            -- airborne: reduced strafing + gravity
            local md     = humanoid.MoveDirection
            local wish   = (vector3 - vector3 * Y):Dot(md)
            local addspd = md.Magnitude * 3
            if addspd - wish > 0 then
                vector3 += md * (addspd * 200 * dt)
            end
            vector3 -= Vector3.new(0, dt * 45, 0)
        end

        -- surface deflection: redirect velocity along ramp normal (the actual surf)
        local hit = workspace:Shapecast(clone, vector3 * dt, raycastParams)
        if hit then
            local dot = vector3:Dot(hit.Normal)
            vector3   = vector3 - hit.Normal * dot
        end

        -- jump
        if onGround then
            u20 = humanoid.Jump
            if u20 then
                local jp = 16.5
                if onGround.Instance then
                    local c = onGround.Instance:GetAttribute("CustomJumpPower")
                    if typeof(c) == "number" and c > 0 then jp = c end
                end
                vector3 = Vector3.new(0, jp, 0) + (vector3 - vector3 * Y)
            end
        end

        clone.Velocity = vector3

        -- camera-aligned orientation
        local _, camY, _ = CurrentCamera.CFrame:ToOrientation()
        local cloneAO = clone:FindFirstChildOfClass("AlignOrientation")
        if cloneAO then
            cloneAO.CFrame = CFrame.Angles(0, camY + math.pi / 2, math.pi / 2)
        end
        if clone2 then
            clone2.CFrame = CFrame.Angles(0, camY, 0)
        end

        -- speed display (horizontal only)
        local horiz = vector3 - vector3 * Y
        updateSpeedLabel(horiz.Magnitude, dt)
    end)
end

-- entry point
if humanoid.Health > 0 then
    enableMovement()
end

humanoid.Died:Connect(function()
    u19 = false
    if connection then connection:Disconnect(); connection = nil end
    if clone      then debris:AddItem(clone, 1); clone = nil end
    if clone2     then clone2:Destroy(); clone2 = nil end
    if attachment then attachment:Destroy(); attachment = nil end
    resetSpeedDisplay()
end)

-- respawn reattach
LocalPlayer.CharacterAdded:Connect(function(c)
    character        = c
    humanoid         = c:WaitForChild("Humanoid")
    humanoidRootPart = c:WaitForChild("HumanoidRootPart")
    humanoidWalkSpeed     = humanoid.WalkSpeed
    humanoidJumpPower     = humanoid.JumpPower
    humanoidPlatformStand = humanoid.PlatformStand
    humanoid.Died:Connect(function()
        u19 = false
        if connection then connection:Disconnect(); connection = nil end
        if clone      then debris:AddItem(clone, 1); clone = nil end
        if clone2     then clone2:Destroy(); clone2 = nil end
        if attachment then attachment:Destroy(); attachment = nil end
        resetSpeedDisplay()
    end)
    task.wait(0.5)
    if humanoid.Health > 0 then enableMovement() end
end)
