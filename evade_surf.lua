-- lang: Luau, file: evade_surf.lua, target: Roblox / Evade, executor: Xeno or equivalent
-- Surf-only hook: reads current velocity, deflects on ramps, touches nothing else

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local lp   = Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()
local hrp  = char:WaitForChild("HumanoidRootPart")

local FLAT_Y     = 0.85  -- normal.Y >= this = flat ground, ignore
local RAMP_Y_MIN = 0.1   -- normal.Y >= this and < FLAT_Y = ramp, deflect

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = {char}
params.RespectCanCollide = true

-- Heartbeat runs after physics so we read the velocity Evade already set
RunService.Heartbeat:Connect(function(dt)
    local vel = hrp.AssemblyLinearVelocity
    if vel.Magnitude < 0.5 then return end

    local hit = workspace:Shapecast(hrp, vel * dt, params)
    if not hit then return end

    local ny = hit.Normal.Y
    if ny >= RAMP_Y_MIN and ny < FLAT_Y then
        local dot = vel:Dot(hit.Normal)
        if dot < 0 then
            -- project velocity onto ramp surface plane (the surf)
            hrp.AssemblyLinearVelocity = vel - hit.Normal * dot
        end
    end
end)

-- Reattach on respawn
lp.CharacterAdded:Connect(function(c)
    char = c
    hrp  = c:WaitForChild("HumanoidRootPart")
    params.FilterDescendantsInstances = {char}
end)
