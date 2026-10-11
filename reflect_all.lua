--[[
    Reflect Everything Script
    Sets reflectance on all current and future parts
]]

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local REFLECTANCE = 0.4 -- 0 = none, 1 = full mirror (0.3-0.5 looks best)

-- Apply to a single part
local function applyReflect(part)
    if part:IsA("BasePart") then
        part.Reflectance = REFLECTANCE
    end
end

-- Apply to all existing parts
for _, v in ipairs(Workspace:GetDescendants()) do
    applyReflect(v)
end

-- Apply to any new parts that get added
Workspace.DescendantAdded:Connect(function(v)
    task.wait() -- wait a frame so the part is fully initialized
    applyReflect(v)
end)

print("[ReflectAll] Done! Reflectance set to " .. REFLECTANCE)
