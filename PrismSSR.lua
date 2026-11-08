-- lang: Luau, file: PrismSSR.lua, target: Delta executor
-- replicates PrismShade SSR panel → Roblox Future lighting (native SSR)
-- Future tech enables screen-space reflections on floors + glossy surfaces
-- Reflection Intensity 1.0 → EnvironmentSpecularScale
-- Reflection Exponent 6.50 → no direct map; EnvironmentDiffuseScale inverse approximates sharpness
-- Vertical FOV 24.29 → Camera.FieldOfView
-- dark atmospheric grade matches the PrismShade SSR scene tone

local Lighting   = game:GetService("Lighting")
local Workspace  = game:GetService("Workspace")
local Players    = game:GetService("Players")
local PlayerGui  = Players.LocalPlayer:WaitForChild("PlayerGui")

local function wipe()
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:GetAttribute("PSTag_SSR") then v:Destroy() end
    end
    local old = PlayerGui:FindFirstChild("PrismSSR_UI")
    if old then old:Destroy() end
end
wipe()

-- snapshot
local snap = {
    tech    = Lighting.Technology,
    spec    = Lighting.EnvironmentSpecularScale,
    diff    = Lighting.EnvironmentDiffuseScale,
    exp     = Lighting.ExposureCompensation,
    amb     = Lighting.Ambient,
    out     = Lighting.OutdoorAmbient,
    fov     = Workspace.CurrentCamera and Workspace.CurrentCamera.FieldOfView or 70,
}

local cfg = {
    enabled       = true,
    -- SSR panel params
    fov           = 24.29,   -- Vertical FOV from panel
    refl_int      = 1.0,     -- Reflection Intensity → SpecularScale
    refl_exp      = 6.50,    -- Reflection Exponent  → tightens; inverse of DiffuseScale
    -- atmosphere (matches the dark moody scene in the screenshot)
    exposure      = -0.4,
    ambient_r     = 15,
    ambient_g     = 15,
    ambient_b     = 20,
    cc_contrast   = 0.15,
    cc_sat        = 0.08,
    cc_bright     = -0.06,
}

local function mkfx(cls, props)
    local fx = Instance.new(cls)
    fx:SetAttribute("PSTag_SSR", true)
    for k, v in pairs(props) do fx[k] = v end
    fx.Parent = Lighting
    return fx
end

local cc = mkfx("ColorCorrectionEffect", {
    Name       = "PSR_CC",
    Contrast   = cfg.cc_contrast,
    Saturation = cfg.cc_sat,
    Brightness = cfg.cc_bright,
    TintColor  = Color3.fromRGB(220, 225, 255),
    Enabled    = true,
})

local bloom = mkfx("BloomEffect", {
    Name      = "PSR_Bloom",
    Intensity = 0.4,
    Size      = 24,
    Threshold = 0.90,
    Enabled   = true,
})

local function apply()
    if cfg.enabled then
        -- Future tech = native SSR on floors and glossy surfaces
        pcall(function() Lighting.Technology = Enum.Technology.Future end)
        Lighting.EnvironmentSpecularScale = cfg.refl_int
        -- higher exponent = tighter/sharper reflections = lower diffuse bleed
        Lighting.EnvironmentDiffuseScale  = math.clamp(1.0 - (cfg.refl_exp / 20.0), 0.1, 1.0)
        Lighting.ExposureCompensation     = cfg.exposure
        Lighting.Ambient                  = Color3.fromRGB(cfg.ambient_r, cfg.ambient_g, cfg.ambient_b)
        Lighting.OutdoorAmbient           = Color3.fromRGB(cfg.ambient_r, cfg.ambient_g, cfg.ambient_b)
        if Workspace.CurrentCamera then
            Workspace.CurrentCamera.FieldOfView = cfg.fov
        end
        cc.Contrast   = cfg.cc_contrast
        cc.Saturation = cfg.cc_sat
        cc.Brightness = cfg.cc_bright
        cc.Enabled    = true
        bloom.Enabled = true
    else
        pcall(function() Lighting.Technology = snap.tech end)
        Lighting.EnvironmentSpecularScale = snap.spec
        Lighting.EnvironmentDiffuseScale  = snap.diff
        Lighting.ExposureCompensation     = snap.exp
        Lighting.Ambient                  = snap.amb
        Lighting.OutdoorAmbient           = snap.out
        if Workspace.CurrentCamera then
            Workspace.CurrentCamera.FieldOfView = snap.fov
        end
        cc.Enabled    = false
        bloom.Enabled = false
    end
end
apply()

-- ── GUI ───────────────────────────────────────────────────────────────────
local sg = Instance.new("ScreenGui", PlayerGui)
sg.Name = "PrismSSR_UI"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true

local W, H = 300, 420
local frame = Instance.new("Frame", sg)
frame.Size = UDim2.new(0, W, 0, H)
frame.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
frame.BackgroundColor3 = Color3.fromRGB(10, 11, 18)
frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

-- drag
local dragging, dStart, fStart = false
frame.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
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
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

-- header
local hdr = Instance.new("TextLabel", frame)
hdr.Text = "⬡ PrismShade  SSR"
hdr.TextColor3 = Color3.fromRGB(100, 170, 255)
hdr.BackgroundTransparency = 1; hdr.Font = Enum.Font.GothamBold
hdr.TextSize = 14; hdr.TextXAlignment = Enum.TextXAlignment.Left
hdr.Position = UDim2.new(0, 12, 0, 8); hdr.Size = UDim2.new(1, -50, 0, 24)

local sub = Instance.new("TextLabel", frame)
sub.Text = "Screen-space reflections on floors and glossy surfaces."
sub.TextColor3 = Color3.fromRGB(120, 120, 140)
sub.BackgroundTransparency = 1; sub.Font = Enum.Font.Gotham
sub.TextSize = 10; sub.TextXAlignment = Enum.TextXAlignment.Left
sub.TextWrapped = true
sub.Position = UDim2.new(0, 12, 0, 28); sub.Size = UDim2.new(1, -50, 0, 22)

local close = Instance.new("TextButton", frame)
close.Size = UDim2.new(0, 28, 0, 22); close.Position = UDim2.new(1, -36, 0, 9)
close.Text = "✕"; close.TextColor3 = Color3.fromRGB(180, 60, 60)
close.BackgroundTransparency = 1; close.Font = Enum.Font.GothamBold; close.TextSize = 15
close.MouseButton1Click:Connect(function()
    cfg.enabled = false; apply(); wipe(); sg:Destroy()
end)

local scroll = Instance.new("ScrollingFrame", frame)
scroll.Size = UDim2.new(1, 0, 1, -54); scroll.Position = UDim2.new(0, 0, 0, 52)
scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3; scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
local layout = Instance.new("UIListLayout", scroll)
layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Padding = UDim.new(0, 2)

local order = 0

local function divider(text, color)
    order = order + 1
    local f = Instance.new("Frame", scroll)
    f.Size = UDim2.new(1, -16, 0, 20); f.LayoutOrder = order
    f.BackgroundColor3 = Color3.fromRGB(20, 22, 36); f.BorderSizePixel = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)
    local l = Instance.new("TextLabel", f)
    l.Text = "▸ "..text
    l.TextColor3 = color or Color3.fromRGB(90, 170, 240)
    l.BackgroundTransparency = 1; l.Font = Enum.Font.GothamBold; l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Position = UDim2.new(0, 8, 0, 3); l.Size = UDim2.new(1, 0, 1, 0)
end

local function row_toggle(text, getter, setter)
    order = order + 1
    local r = Instance.new("Frame", scroll)
    r.Size = UDim2.new(1, -16, 0, 32); r.BackgroundTransparency = 1; r.LayoutOrder = order
    local lbl = Instance.new("TextLabel", r)
    lbl.Text = text; lbl.TextColor3 = Color3.fromRGB(210, 210, 220)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Position = UDim2.new(0, 10, 0, 0); lbl.Size = UDim2.new(0.65, 0, 1, 0)
    local btn = Instance.new("TextButton", r)
    btn.Size = UDim2.new(0, 56, 0, 24); btn.Position = UDim2.new(1, -64, 0.5, -12)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 11; btn.BorderSizePixel = 0
    local function upd()
        local on = getter()
        btn.Text = on and "depth ●" or "OFF"
        btn.BackgroundColor3 = on and Color3.fromRGB(30, 80, 180) or Color3.fromRGB(60, 20, 20)
        btn.TextColor3 = Color3.fromRGB(240, 240, 240)
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)
    end
    upd()
    btn.MouseButton1Click:Connect(function() setter(not getter()); upd(); apply() end)
end

local function row_slider(text, min, max, getter, setter, fmt)
    order = order + 1
    local r = Instance.new("Frame", scroll)
    r.Size = UDim2.new(1, -16, 0, 40); r.BackgroundTransparency = 1; r.LayoutOrder = order
    local lbl = Instance.new("TextLabel", r)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(180, 180, 200); lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Position = UDim2.new(0, 10, 0, 2); lbl.Size = UDim2.new(0.6, 0, 0, 14)
    local val = Instance.new("TextLabel", r)
    val.BackgroundTransparency = 1; val.Font = Enum.Font.GothamBold; val.TextSize = 11
    val.TextColor3 = Color3.fromRGB(100, 170, 255); val.TextXAlignment = Enum.TextXAlignment.Right
    val.Position = UDim2.new(0.6, 0, 0, 2); val.Size = UDim2.new(0.4, -10, 0, 14)
    local function rlbl()
        lbl.Text = text
        val.Text = string.format(fmt or "%.2f", getter())
    end
    rlbl()
    local track = Instance.new("Frame", r)
    track.Size = UDim2.new(1, -20, 0, 6); track.Position = UDim2.new(0, 10, 0, 24)
    track.BackgroundColor3 = Color3.fromRGB(35, 38, 58); track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame", track)
    fill.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
    fill.BorderSizePixel = 0
    local range = max - min
    fill.Size = UDim2.new(math.clamp((getter() - min) / range, 0, 1), 0, 1, 0)
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local sliding = false
    local function drag(inp)
        local rel = math.clamp((inp.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        setter(math.floor((min + rel * range) * 1000 + 0.5) / 1000)
        fill.Size = UDim2.new(math.clamp((getter() - min) / range, 0, 1), 0, 1, 0)
        rlbl(); apply()
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then sliding = true; drag(i) end
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

divider("Screen-Space Reflections", Color3.fromRGB(100, 170, 255))
row_toggle("Screen-space reflections",
    function() return cfg.enabled end,
    function(v) cfg.enabled = v end)

divider("Global")
row_slider("Vertical Field of View", 10, 120,
    function() return cfg.fov end,
    function(v) cfg.fov = v end, "%.2f")
row_slider("Reflection Intensity",   0, 2,
    function() return cfg.refl_int end,
    function(v) cfg.refl_int = v end, "%.3f")
row_slider("Reflection Exponent",    1, 20,
    function() return cfg.refl_exp end,
    function(v) cfg.refl_exp = v end, "%.2f")

divider("Atmosphere", Color3.fromRGB(140, 100, 220))
row_slider("Exposure", -3, 2,
    function() return cfg.exposure end,
    function(v) cfg.exposure = v end)
row_slider("Contrast", -1, 1,
    function() return cfg.cc_contrast end,
    function(v) cfg.cc_contrast = v end)
row_slider("Saturation", -1, 1,
    function() return cfg.cc_sat end,
    function(v) cfg.cc_sat = v end)

-- cleanup hooks
Players.LocalPlayer.CharacterRemoving:Connect(function()
    pcall(function() Lighting.Technology = snap.tech end)
    Lighting.EnvironmentSpecularScale = snap.spec
    Lighting.EnvironmentDiffuseScale  = snap.diff
    Lighting.ExposureCompensation     = snap.exp
    Lighting.Ambient                  = snap.amb
    Lighting.OutdoorAmbient           = snap.out
    if Workspace.CurrentCamera then
        Workspace.CurrentCamera.FieldOfView = snap.fov
    end
end)
