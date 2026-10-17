-- Shader Settings Only
-- Client-side Roblox LocalScript (also usable in a client execution environment).
-- Adds only local Lighting post-processing and a small settings panel.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
if not player then
    warn("Shader Settings Only must run on the client.")
    return
end

local playerGui = player:WaitForChild("PlayerGui")
local GUI_NAME = "ShaderSettingsOnlyGui"
local VIGNETTE_GUI_NAME = "ShaderSettingsOnlyVignette"
local EFFECT_PREFIX = "ShaderSettingsOnly_"

-- Remove effects/UI left behind by an earlier run of this script only.
for _, child in ipairs(Lighting:GetChildren()) do
    if child.Name:sub(1, #EFFECT_PREFIX) == EFFECT_PREFIX then
        child:Destroy()
    end
end
for _, child in ipairs(playerGui:GetChildren()) do
    if child.Name == GUI_NAME or child.Name == VIGNETTE_GUI_NAME then
        child:Destroy()
    end
end

local state = {
    Saturation = 0,
    Brightness = 0,
    Contrast = 0,
    Blur = 0,
    BloomIntensity = 0,
    BloomSize = 24,
    SunRaysIntensity = 0,
    DOFFarIntensity = 0,
    DOFNearIntensity = 0,
    DOFFocusDistance = 10,
    AtmosphereDensity = 0,
    MotionBlurStrength = 0,
    VignetteStrength = 0,
}

local effects = {}
local destroyed = false
local motionConnection = nil
local previousCamera = nil
local previousCameraCFrame = nil
local atmosphereTarget = nil
local atmosphereSnapshot = nil
local ownedAtmosphere = false
local vignetteGui = nil
local vignetteEdges = {}
local sliderSetters = {}

local function clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

local function createEffect(className, key)
    local effect = Instance.new(className)
    effect.Name = EFFECT_PREFIX .. key
    effect.Parent = Lighting
    effects[key] = effect
    return effect
end

local function getEffect(className, key)
    local effect = effects[key]
    if effect and effect.Parent then
        return effect
    end
    return createEffect(className, key)
end

local function removeEffect(key)
    local effect = effects[key]
    if effect then
        effect:Destroy()
        effects[key] = nil
    end
end

local function applyColorCorrection()
    if state.Saturation == 0 and state.Brightness == 0 and state.Contrast == 0 then
        removeEffect("ColorCorrection")
        return
    end
    local effect = getEffect("ColorCorrectionEffect", "ColorCorrection")
    effect.Saturation = state.Saturation
    effect.Brightness = state.Brightness
    effect.Contrast = state.Contrast
end

local function applyBlur()
    if state.Blur <= 0 then
        removeEffect("Blur")
        return
    end
    local effect = getEffect("BlurEffect", "Blur")
    effect.Size = state.Blur
end

local function applyBloom()
    if state.BloomIntensity <= 0 then
        removeEffect("Bloom")
        return
    end
    local effect = getEffect("BloomEffect", "Bloom")
    effect.Intensity = state.BloomIntensity
    effect.Size = state.BloomSize
    effect.Threshold = 1
end

local function applySunRays()
    if state.SunRaysIntensity <= 0 then
        removeEffect("SunRays")
        return
    end
    local effect = getEffect("SunRaysEffect", "SunRays")
    effect.Intensity = state.SunRaysIntensity
    effect.Spread = 0.8
end

local function applyDepthOfField()
    if state.DOFFarIntensity <= 0 and state.DOFNearIntensity <= 0 then
        removeEffect("DepthOfField")
        return
    end
    local effect = getEffect("DepthOfFieldEffect", "DepthOfField")
    effect.FarIntensity = state.DOFFarIntensity
    effect.NearIntensity = state.DOFNearIntensity
    effect.FocusDistance = state.DOFFocusDistance
    effect.InFocusRadius = 20
end

local function restoreAtmosphere()
    if atmosphereSnapshot and atmosphereTarget and atmosphereTarget.Parent then
        pcall(function()
            atmosphereTarget.Density = atmosphereSnapshot.Density
        end)
    end
    if ownedAtmosphere and atmosphereTarget then
        pcall(function()
            atmosphereTarget:Destroy()
        end)
    end
    atmosphereTarget = nil
    atmosphereSnapshot = nil
    ownedAtmosphere = false
end

local function applyAtmosphere()
    if state.AtmosphereDensity <= 0 then
        restoreAtmosphere()
        return
    end

    if not atmosphereTarget or not atmosphereTarget.Parent then
        atmosphereTarget = Lighting:FindFirstChildOfClass("Atmosphere")
        if atmosphereTarget then
            atmosphereSnapshot = { Density = atmosphereTarget.Density }
            ownedAtmosphere = false
        else
            atmosphereTarget = createEffect("Atmosphere", "Atmosphere")
            atmosphereTarget.Color = Color3.fromRGB(200, 200, 200)
            atmosphereTarget.Decay = Color3.fromRGB(106, 112, 125)
            atmosphereTarget.Haze = 0
            atmosphereTarget.Glare = 0
            ownedAtmosphere = true
        end
    end

    atmosphereTarget.Density = state.AtmosphereDensity
end

local function ensureVignette()
    if vignetteGui and vignetteGui.Parent then
        return vignetteGui
    end
    local screen = Instance.new("ScreenGui")
    screen.Name = VIGNETTE_GUI_NAME
    screen.IgnoreGuiInset = true
    screen.ResetOnSpawn = false
    screen.DisplayOrder = 5
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screen.Parent = playerGui

    local function addEdge(name, size, position, anchor, rotation)
        local edge = Instance.new("Frame")
        edge.Name = name
        edge.Size = size
        edge.Position = position
        edge.AnchorPoint = anchor or Vector2.new(0, 0)
        edge.BackgroundColor3 = Color3.new(0, 0, 0)
        edge.BorderSizePixel = 0
        edge.Parent = screen
        local gradient = Instance.new("UIGradient")
        gradient.Rotation = rotation
        gradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        })
        gradient.Parent = edge
        return edge
    end

    vignetteGui = screen
    vignetteEdges = {
        addEdge("Top", UDim2.new(1, 0, 0.22, 0), UDim2.new(0, 0, 0, 0), Vector2.new(0, 0), 90),
        addEdge("Bottom", UDim2.new(1, 0, 0.22, 0), UDim2.new(0, 0, 1, 0), Vector2.new(0, 1), 270),
        addEdge("Left", UDim2.new(0.18, 0, 1, 0), UDim2.new(0, 0, 0, 0), Vector2.new(0, 0), 0),
        addEdge("Right", UDim2.new(0.18, 0, 1, 0), UDim2.new(1, 0, 0, 0), Vector2.new(1, 0), 180),
    }
    return vignetteGui
end

local function applyVignette()
    if state.VignetteStrength <= 0 then
        if vignetteGui then
            vignetteGui:Destroy()
            vignetteGui = nil
            vignetteEdges = {}
        end
        return
    end
    local screen = ensureVignette()
    local transparency = clamp(1 - state.VignetteStrength * 0.78, 0.20, 0.98)
    for _, edge in ipairs(vignetteEdges) do
        edge.BackgroundTransparency = transparency
    end
end

local function stopMotionBlur()
    if motionConnection then
        motionConnection:Disconnect()
        motionConnection = nil
    end
    removeEffect("MotionBlur")
    previousCamera = nil
    previousCameraCFrame = nil
end

local function applyMotionBlur()
    if state.MotionBlurStrength <= 0 then
        stopMotionBlur()
        return
    end

    local effect = getEffect("BlurEffect", "MotionBlur")
    if motionConnection then
        return
    end

    previousCamera = workspace.CurrentCamera
    previousCameraCFrame = previousCamera and previousCamera.CFrame or nil
    motionConnection = RunService.RenderStepped:Connect(function(deltaTime)
        if destroyed or state.MotionBlurStrength <= 0 then
            stopMotionBlur()
            return
        end
        local camera = workspace.CurrentCamera
        if not camera then
            effect.Size = 0
            previousCamera = nil
            previousCameraCFrame = nil
            return
        end
        if camera ~= previousCamera or not previousCameraCFrame then
            previousCamera = camera
            previousCameraCFrame = camera.CFrame
            effect.Size = 0
            return
        end

        local current = camera.CFrame
        local relative = previousCameraCFrame:ToObjectSpace(current)
        local rotation = math.acos(clamp(relative.LookVector:Dot(Vector3.new(0, 0, -1)), -1, 1))
        local movement = (current.Position - previousCameraCFrame.Position).Magnitude
        local motion = clamp(rotation * 5 + movement * 0.02, 0, 1)
        local target = 24 * state.MotionBlurStrength * motion
        effect.Size = effect.Size + (target - effect.Size) * clamp(deltaTime * 12, 0, 1)
        previousCameraCFrame = current
    end)
end

local function applyAll()
    applyColorCorrection()
    applyBlur()
    applyBloom()
    applySunRays()
    applyDepthOfField()
    applyAtmosphere()
    applyMotionBlur()
    applyVignette()
end

local function rounded(value, step)
    local result = math.floor(value / step + 0.5) * step
    return clamp(result, -1000000, 1000000)
end

-- Build the settings panel.
local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
local panelWidth = math.min(380, math.max(300, viewport.X - 24))
local panelHeight = math.min(560, math.max(340, viewport.Y - 24))

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(panelWidth, panelHeight)
panel.BackgroundColor3 = Color3.fromRGB(22, 24, 31)
panel.BorderSizePixel = 0
panel.Parent = screenGui
local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel
local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(76, 84, 105)
panelStroke.Transparency = 0.35
panelStroke.Parent = panel

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 48)
header.BackgroundColor3 = Color3.fromRGB(31, 34, 44)
header.BorderSizePixel = 0
header.Active = true
header.Parent = panel
local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(16, 0)
title.Size = UDim2.new(1, -126, 1, 0)
title.Font = Enum.Font.GothamSemibold
title.Text = "Shader Settings"
title.TextColor3 = Color3.fromRGB(240, 242, 248)
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local function makeHeaderButton(text, width, rightOffset, color)
    local button = Instance.new("TextButton")
    button.Size = UDim2.fromOffset(width, 28)
    button.Position = UDim2.new(1, rightOffset, 0.5, -14)
    button.BackgroundColor3 = color
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamMedium
    button.Text = text
    button.TextSize = 12
    button.TextColor3 = Color3.fromRGB(245, 246, 250)
    button.AutoButtonColor = true
    button.Parent = header
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = button
    return button
end

local resetButton = makeHeaderButton("Reset", 52, -68, Color3.fromRGB(72, 78, 96))
local closeButton = makeHeaderButton("×", 28, -34, Color3.fromRGB(115, 48, 58))

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "ShaderControls"
scroll.Position = UDim2.fromOffset(10, 56)
scroll.Size = UDim2.new(1, -20, 1, -68)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = Color3.fromRGB(117, 130, 164)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = panel

local scrollPadding = Instance.new("UIPadding")
scrollPadding.PaddingTop = UDim.new(0, 3)
scrollPadding.PaddingBottom = UDim.new(0, 10)
scrollPadding.PaddingLeft = UDim.new(0, 3)
scrollPadding.PaddingRight = UDim.new(0, 3)
scrollPadding.Parent = scroll
local list = Instance.new("UIListLayout")
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Padding = UDim.new(0, 6)
list.Parent = scroll

local function addSection(text, order)
    local label = Instance.new("TextLabel")
    label.Name = text:gsub("%s+", "")
    label.LayoutOrder = order
    label.Size = UDim2.new(1, -4, 0, 24)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamSemibold
    label.Text = text:upper()
    label.TextColor3 = Color3.fromRGB(145, 160, 195)
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = scroll
end

local function addSlider(definition, order)
    local row = Instance.new("Frame")
    row.Name = definition.key
    row.LayoutOrder = order
    row.Size = UDim2.new(1, -4, 0, 52)
    row.BackgroundColor3 = Color3.fromRGB(31, 34, 44)
    row.BorderSizePixel = 0
    row.Parent = scroll
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = row

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.fromOffset(11, 5)
    label.Size = UDim2.new(1, -94, 0, 18)
    label.Font = Enum.Font.Gotham
    label.Text = definition.name
    label.TextColor3 = Color3.fromRGB(228, 231, 240)
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local valueLabel = Instance.new("TextLabel")
    valueLabel.BackgroundTransparency = 1
    valueLabel.Position = UDim2.new(1, -76, 0, 5)
    valueLabel.Size = UDim2.fromOffset(64, 18)
    valueLabel.Font = Enum.Font.GothamMedium
    valueLabel.TextColor3 = Color3.fromRGB(167, 184, 224)
    valueLabel.TextSize = 11
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = row

    local track = Instance.new("TextButton")
    track.Name = "Track"
    track.Position = UDim2.new(0, 11, 0, 32)
    track.Size = UDim2.new(1, -22, 0, 8)
    track.BackgroundColor3 = Color3.fromRGB(55, 59, 73)
    track.BorderSizePixel = 0
    track.Text = ""
    track.AutoButtonColor = false
    track.Active = true
    track.Parent = row
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(121, 151, 235)
    fill.BorderSizePixel = 0
    fill.Parent = track
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(0, 0, 0.5, 0)
    knob.Size = UDim2.fromOffset(14, 14)
    knob.BackgroundColor3 = Color3.fromRGB(244, 246, 255)
    knob.BorderSizePixel = 0
    knob.Parent = track
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local function updateVisual(value)
        local alpha = (value - definition.min) / (definition.max - definition.min)
        alpha = clamp(alpha, 0, 1)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        if definition.step < 1 then
            valueLabel.Text = string.format("%.2f", value)
        else
            valueLabel.Text = string.format("%.0f", value)
        end
    end

    local function setValue(value)
        value = clamp(rounded(value, definition.step), definition.min, definition.max)
        state[definition.key] = value
        updateVisual(value)
        applyAll()
    end

    local dragging = false
    local function setFromX(x)
        local width = math.max(track.AbsoluteSize.X, 1)
        local alpha = clamp((x - track.AbsolutePosition.X) / width, 0, 1)
        setValue(definition.min + alpha * (definition.max - definition.min))
    end
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    sliderSetters[definition.key] = function(value)
        state[definition.key] = value
        updateVisual(value)
    end
    updateVisual(state[definition.key])
end

local definitions = {
    { key = "Saturation", name = "Saturation", min = -1, max = 1, step = 0.01 },
    { key = "Brightness", name = "Brightness", min = -1, max = 1, step = 0.01 },
    { key = "Contrast", name = "Contrast", min = -1, max = 1, step = 0.01 },
    { key = "Blur", name = "Blur", min = 0, max = 24, step = 1 },
    { key = "BloomIntensity", name = "Bloom intensity", min = 0, max = 2, step = 0.01 },
    { key = "BloomSize", name = "Bloom size", min = 1, max = 56, step = 1 },
    { key = "SunRaysIntensity", name = "Sun rays", min = 0, max = 1, step = 0.01 },
    { key = "DOFFarIntensity", name = "Depth of field · far", min = 0, max = 1, step = 0.01 },
    { key = "DOFNearIntensity", name = "Depth of field · near", min = 0, max = 1, step = 0.01 },
    { key = "DOFFocusDistance", name = "Depth of field · focus", min = 1, max = 100, step = 1 },
    { key = "AtmosphereDensity", name = "Atmosphere density", min = 0, max = 1, step = 0.01 },
    { key = "MotionBlurStrength", name = "Motion blur", min = 0, max = 1, step = 0.01 },
    { key = "VignetteStrength", name = "Vignette", min = 0, max = 1, step = 0.01 },
}

addSection("Color", 1)
for index = 1, 4 do
    addSlider(definitions[index], index + 1)
end
addSection("Lighting effects", 6)
for index = 5, 11 do
    addSlider(definitions[index], index + 2)
end
addSection("Camera & screen", 14)
for index = 12, #definitions do
    addSlider(definitions[index], index + 2)
end

local draggingPanel = false
local dragInput = nil
local dragStart = nil
local panelStart = nil
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingPanel = true
        dragInput = input
        dragStart = input.Position
        panelStart = panel.Position
    end
end)
header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingPanel and input == dragInput then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(panelStart.X.Scale, panelStart.X.Offset + delta.X, panelStart.Y.Scale, panelStart.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingPanel = false
    end
end)

local function resetSettings()
    for key, value in pairs({
        Saturation = 0,
        Brightness = 0,
        Contrast = 0,
        Blur = 0,
        BloomIntensity = 0,
        BloomSize = 24,
        SunRaysIntensity = 0,
        DOFFarIntensity = 0,
        DOFNearIntensity = 0,
        DOFFocusDistance = 10,
        AtmosphereDensity = 0,
        MotionBlurStrength = 0,
        VignetteStrength = 0,
    }) do
        state[key] = value
        if sliderSetters[key] then
            sliderSetters[key](value)
        end
    end
    applyAll()
end

local function unload()
    if destroyed then
        return
    end
    destroyed = true
    stopMotionBlur()
    restoreAtmosphere()
    for key in pairs(effects) do
        removeEffect(key)
    end
    if vignetteGui then
        vignetteGui:Destroy()
        vignetteGui = nil
        vignetteEdges = {}
    end
    if screenGui then
        screenGui:Destroy()
    end
end

resetButton.Activated:Connect(resetSettings)
closeButton.Activated:Connect(unload)
applyAll()
