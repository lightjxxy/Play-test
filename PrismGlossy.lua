-- lang: Luau, file: PrismGlossy.lua, target: Delta executor
-- approximates AstrayFX/Clarity.fx → EnvironmentSpecularScale + bloom + CC
-- Clarity works by: blur the frame, subtract, blend back via Hard Light/Overlay
-- Roblox equivalent: specular scale lifts surface sheen, bloom bleeds highlights,
-- contrast punches midtones — same visual result, different path

local Lighting   = game:GetService("Lighting")
local PlayerGui  = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

-- wipe prior glossy run
local function wipe()
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:GetAttribute("PSGloss") then v:Destroy() end
    end
    local old = PlayerGui:FindFirstChild("PrismGlossyUI")
    if old then old:Destroy() end
end
wipe()

-- snapshot originals for clean rollback
local snap = {
    spec    = Lighting.EnvironmentSpecularScale,
    diff    = Lighting.EnvironmentDiffuseScale,
    exp     = Lighting.ExposureCompensation,
}

local cfg = {
    enabled     = true,
    spec        = 1.0,    -- EnvironmentSpecularScale  (0–2)  → surface gloss
    diff        = 0.6,    -- EnvironmentDiffuseScale   (0–1)  → fill light
    exposure    = 0.3,    -- ExposureCompensation             → blows out highlights
    bloom_int   = 1.4,    -- high intensity, low threshold = highlight bleed
    bloom_size  = 32,
    bloom_thresh= 0.55,   -- low threshold = glossy highlight spread
    contrast    = 0.22,   -- punches midtones like Clarity's Hard Light blend
    saturation  = 0.18,   -- Clarity also lifts saturation on lit surfaces
    brightness  = 0.04,
}

local function mkfx(cls, props)
    local fx = Instance.new(cls)
    fx:SetAttribute("PSGloss", true)
    for k, v in pairs(props) do fx[k] = v end
    fx.Parent = Lighting
    return fx
end

local bloom = mkfx("BloomEffect", {
    Name = "PG_Bloom",
    Intensity = cfg.bloom_int,
    Size      = cfg.bloom_size,
    Threshold = cfg.bloom_thresh,
    Enabled   = true,
})
local cc = mkfx("ColorCorrectionEffect", {
    Name       = "PG_CC",
    Contrast   = cfg.contrast,
    Saturation = cfg.saturation,
    Brightness = cfg.brightness,
    TintColor  = Color3.fromRGB(255, 252, 246),
    Enabled    = true,
})

local function apply()
    Lighting.EnvironmentSpecularScale = cfg.spec
    Lighting.EnvironmentDiffuseScale  = cfg.diff
    Lighting.ExposureCompensation     = cfg.exposure
    bloom.Intensity  = cfg.bloom_int
    bloom.Size       = cfg.bloom_size
    bloom.Threshold  = cfg.bloom_thresh
    bloom.Enabled    = cfg.enabled
    cc.Contrast      = cfg.contrast
    cc.Saturation    = cfg.saturation
    cc.Brightness    = cfg.brightness
    cc.Enabled       = cfg.enabled
    if not cfg.enabled then
        Lighting.EnvironmentSpecularScale = snap.spec
        Lighting.EnvironmentDiffuseScale  = snap.diff
        Lighting.ExposureCompensation     = snap.exp
    end
end
apply()

-- ── GUI ───────────────────────────────────────────────────────────────────
local sg = Instance.new("ScreenGui", PlayerGui)
sg.Name = "PrismGlossyUI"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true

local W, H = 300, 370
local frame = Instance.new("Frame", sg)
frame.Size = UDim2.new(0, W, 0, H)
frame.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
frame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

-- drag
local dragging, dStart, fStart = false
frame.InputBegan:Connect(function(i)
    if i.UserInputType.Name:match("MouseButton1") or i.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dStart = i.Position; fStart = frame.Position
    end
end)
frame.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
    or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - dStart
        frame.Position = UDim2.new(fStart.X.Scale, fStart.X.Offset + d.X,
                                    fStart.Y.Scale, fStart.Y.Offset + d.Y)
    end
end)
frame.InputEnded:Connect(function(i)
    if i.UserInputType.Name:match("MouseButton1") or i.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- title
local title = Instance.new("TextLabel", frame)
title.Text = "✦ PrismShade Glossy"
title.TextColor3 = Color3.fromRGB(180, 220, 255)
title.BackgroundTransparency = 1; title.Font = Enum.Font.GothamBold
title.TextSize = 14; title.TextXAlignment = Enum.TextXAlignment.Left
title.Position = UDim2.new(0, 12, 0, 8); title.Size = UDim2.new(1, -50, 0, 24)

local close = Instance.new("TextButton", frame)
close.Size = UDim2.new(0, 28, 0, 22); close.Position = UDim2.new(1, -36, 0, 9)
close.Text = "✕"; close.TextColor3 = Color3.fromRGB(180, 60, 60)
close.BackgroundTransparency = 1; close.Font = Enum.Font.GothamBold; close.TextSize = 15
close.MouseButton1Click:Connect(function()
    Lighting.EnvironmentSpecularScale = snap.spec
    Lighting.EnvironmentDiffuseScale  = snap.diff
    Lighting.ExposureCompensation     = snap.exp
    wipe(); sg:Destroy()
end)

local scroll = Instance.new("ScrollingFrame", frame)
scroll.Size = UDim2.new(1, 0, 1, -40); scroll.Position = UDim2.new(0, 0, 0, 38)
scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3; scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
local layout = Instance.new("UIListLayout", scroll)
layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Padding = UDim.new(0, 2)

local order = 0
local function row_toggle(text, getter, setter)
    order = order + 1
    local r = Instance.new("Frame", scroll)
    r.Size = UDim2.new(1, -16, 0, 30); r.BackgroundTransparency = 1; r.LayoutOrder = order
    local lbl = Instance.new("TextLabel", r)
    lbl.Text = text; lbl.TextColor3 = Color3.fromRGB(210, 210, 210)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Position = UDim2.new(0, 10, 0, 0); lbl.Size = UDim2.new(0.65, 0, 1, 0)
    local btn = Instance.new("TextButton", r)
    btn.Size = UDim2.new(0, 46, 0, 20); btn.Position = UDim2.new(1, -54, 0.5, -10)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 11; btn.BorderSizePixel = 0
    local function upd()
        local on = getter()
        btn.Text = on and "ON" or "OFF"
        btn.BackgroundColor3 = on and Color3.fromRGB(40, 170, 70) or Color3.fromRGB(80, 25, 25)
        btn.TextColor3 = Color3.fromRGB(240, 240, 240)
        local c = Instance.new("UICorner", btn); c.CornerRadius = UDim.new(0, 4)
    end
    upd()
    btn.MouseButton1Click:Connect(function() setter(not getter()); upd(); apply() end)
end

local function row_slider(text, min, max, getter, setter)
    order = order + 1
    local r = Instance.new("Frame", scroll)
    r.Size = UDim2.new(1, -16, 0, 38); r.BackgroundTransparency = 1; r.LayoutOrder = order
    local lbl = Instance.new("TextLabel", r)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(190, 190, 190); lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Position = UDim2.new(0, 10, 0, 2); lbl.Size = UDim2.new(1, -16, 0, 14)
    local function refresh_lbl() lbl.Text = text.."  "..string.format("%.2f", getter()) end
    refresh_lbl()

    local track = Instance.new("Frame", r)
    track.Size = UDim2.new(1, -20, 0, 6); track.Position = UDim2.new(0, 10, 0, 22)
    track.BackgroundColor3 = Color3.fromRGB(40, 40, 60); track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", track)
    fill.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
    fill.BorderSizePixel = 0
    fill.Size = UDim2.new((getter() - min) / (max - min), 0, 1, 0)
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local sliding = false
    local function drag(inp)
        local rel = math.clamp((inp.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = min + rel * (max - min)
        v = math.floor(v * 1000 + 0.5) / 1000
        setter(v)
        fill.Size = UDim2.new((getter() - min) / (max - min), 0, 1, 0)
        refresh_lbl()
        apply()
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            sliding = true; drag(i)
        end
    end)
    track.InputChanged:Connect(function(i)
        if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then drag(i) end
    end)
    track.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then sliding = false end
    end)
end

local function divider(text)
    order = order + 1
    local f = Instance.new("Frame", scroll)
    f.Size = UDim2.new(1, -16, 0, 20); f.LayoutOrder = order
    f.BackgroundColor3 = Color3.fromRGB(22, 22, 36); f.BorderSizePixel = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)
    local l = Instance.new("TextLabel", f)
    l.Text = "▸ "..text; l.TextColor3 = Color3.fromRGB(90, 170, 240)
    l.BackgroundTransparency = 1; l.Font = Enum.Font.GothamBold; l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Position = UDim2.new(0, 8, 0, 3); l.Size = UDim2.new(1, 0, 1, 0)
end

divider("Master")
row_toggle("Glossy Enabled", function() return cfg.enabled end, function(v) cfg.enabled = v end)
divider("Surface Gloss  (Clarity core)")
row_slider("Specular Scale", 0, 2,  function() return cfg.spec end,     function(v) cfg.spec = v end)
row_slider("Diffuse Scale",  0, 1,  function() return cfg.diff end,     function(v) cfg.diff = v end)
divider("Highlight Bleed")
row_slider("Bloom Intensity", 0, 3, function() return cfg.bloom_int end,    function(v) cfg.bloom_int = v end)
row_slider("Bloom Threshold", 0, 1, function() return cfg.bloom_thresh end, function(v) cfg.bloom_thresh = v end)
row_slider("Bloom Size",      0, 72,function() return cfg.bloom_size end,   function(v) cfg.bloom_size = v end)
divider("Midtone Punch  (Hard Light sim)")
row_slider("Contrast",   -1, 1, function() return cfg.contrast end,   function(v) cfg.contrast = v end)
row_slider("Saturation", -1, 1, function() return cfg.saturation end, function(v) cfg.saturation = v end)
divider("Exposure")
row_slider("Exposure", -3, 3, function() return cfg.exposure end, function(v) cfg.exposure = v end)

game:GetService("Players").LocalPlayer.CharacterRemoving:Connect(function()
    Lighting.EnvironmentSpecularScale = snap.spec
    Lighting.EnvironmentDiffuseScale  = snap.diff
    Lighting.ExposureCompensation     = snap.exp
end)
