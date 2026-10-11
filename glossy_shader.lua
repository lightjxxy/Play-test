--[[
    Glossy Shader Script
    Standalone - no UI required
    Based on the "Ocean Glass" style with high specular reflections
]]

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

-- Remove any existing post-processing effects
for _, v in ipairs(Lighting:GetChildren()) do
    if v:IsA("BloomEffect")
    or v:IsA("DepthOfFieldEffect")
    or v:IsA("ColorCorrectionEffect")
    or v:IsA("SunRaysEffect")
    or v:IsA("Atmosphere") then
        v:Destroy()
    end
end

--============================================================
-- LIGHTING
--============================================================

pcall(function() Lighting.ClockTime             = 13.4  end)  -- midday bright sun
pcall(function() Lighting.Brightness            = 2.8   end)  -- high brightness for glossy look
pcall(function() Lighting.ExposureCompensation  = 0.12  end)  -- slight exposure boost
pcall(function() Lighting.EnvironmentDiffuseScale  = 0.82 end) -- soft diffuse light
pcall(function() Lighting.EnvironmentSpecularScale = 1.0  end) -- MAX specular = glossy reflections
pcall(function() Lighting.Ambient               = Color3.fromRGB(55, 110, 120) end)
pcall(function() Lighting.OutdoorAmbient        = Color3.fromRGB(45, 95, 105)  end)
pcall(function() Lighting.GlobalShadows         = true  end)

--============================================================
-- BLOOM (makes shiny surfaces glow)
--============================================================

local bloom = Instance.new("BloomEffect")
bloom.Intensity  = 0.52
bloom.Size       = 30
bloom.Threshold  = 0.58
bloom.Enabled    = true
bloom.Parent     = Lighting

--============================================================
-- COLOR CORRECTION (warm-teal tint, punchy contrast)
--============================================================

local cc = Instance.new("ColorCorrectionEffect")
cc.Brightness  = 0.05
cc.Contrast    = 0.10
cc.Saturation  = 0.28
cc.TintColor   = Color3.fromRGB(170, 245, 240) -- ocean glass teal tint
cc.Enabled     = true
cc.Parent      = Lighting

--============================================================
-- DEPTH OF FIELD (cinematic blur, keeps floor sharp)
--============================================================

local dof = Instance.new("DepthOfFieldEffect")
dof.FarIntensity   = 0.38
dof.NearIntensity  = 0.10
dof.FocusDistance  = 16
dof.InFocusRadius  = 22
dof.Enabled        = true
dof.Parent         = Lighting

--============================================================
-- SUN RAYS (adds to glossy light shafts)
--============================================================

local sunRays = Instance.new("SunRaysEffect")
sunRays.Intensity = 0.26
sunRays.Spread    = 0.70
sunRays.Enabled   = true
sunRays.Parent    = Lighting

--============================================================
-- ATMOSPHERE (soft aerial depth)
--============================================================

local atm = Instance.new("Atmosphere")
atm.Density  = 0.18
atm.Offset   = 0
atm.Color    = Color3.fromRGB(95, 205, 205)
atm.Decay    = Color3.fromRGB(65, 155, 175)
atm.Glare    = 0.16
atm.Haze     = 0.10
atm.Parent   = Lighting

print("[GlossyShader] Loaded successfully!")
