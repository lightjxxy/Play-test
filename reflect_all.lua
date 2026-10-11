--[[
    Reflect Everything Script
    Forces Future lighting + reflectance on all parts
]]

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local REFLECTANCE = 0.6

-- Force Future lighting (required for reflections to actually render)
pcall(function()
    Lighting.Technology = Enum.Technology.Future
end)

-- Max out specular so reflections are visible
pcall(function() Lighting.EnvironmentSpecularScale = 1.0 end)
pcall(function() Lighting.EnvironmentDiffuseScale  = 0.8 end)
pcall(function() Lighting.Brightness = 3.0 end)

-- Apply reflectance to a part
local function applyReflect(part)
    if part:IsA("BasePart") then
        pcall(function()
            part.Reflectance = REFLECTANCE
        end)
    end
end

-- Apply to all existing parts
for _, v in ipairs(Workspace:GetDescendants()) do
    applyReflect(v)
end

-- Apply to new parts as they load
Workspace.DescendantAdded:Connect(function(v)
    task.wait()
    applyReflect(v)
end)

print("[ReflectAll] Done!")
