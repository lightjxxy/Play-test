-- The old bootstrap called game:HttpGet/loadstring directly.  If either API
-- is unavailable, Lua reports only "attempt to call a nil value" on line 1.
-- Resolve the APIs first so the script works with supported runners and gives
-- a useful error when it is being run as a normal Roblox LocalScript.
local function getRemoteSource(url)
    local httpGet = game and game.HttpGet
    if type(httpGet) == "function" then
        return game:HttpGet(url)
    end

    local requestApi
    if syn and type(syn.request) == "function" then
        requestApi = syn.request
    elseif http and type(http.request) == "function" then
        requestApi = http.request
    elseif type(request) == "function" then
        requestApi = request
    elseif fluxus and type(fluxus.request) == "function" then
        requestApi = fluxus.request
    end

    if type(requestApi) == "function" then
        local response = requestApi({
            Url = url,
            Method = "GET",
        })
        if type(response) == "table" then
            if response.Success == false
                or (type(response.StatusCode) == "number" and response.StatusCode >= 400) then
                error("HTTP request failed for " .. url)
            end
            return response.Body or response.body
        end
        return response
    end

    error("No supported HTTP API was found. Run this in a supported environment; a normal Roblox LocalScript cannot download and execute this UI.")
end

local function loadRemote(url, moduleName)
    local compiler = loadstring or load
    if type(compiler) ~= "function" then
        error("No Lua loader was found. This environment does not support loadstring/load.")
    end

    local okSource, source = pcall(getRemoteSource, url)
    if not okSource or type(source) ~= "string" then
        error("Could not download " .. moduleName .. ": " .. tostring(source))
    end

    local okChunk, chunk = pcall(compiler, source, "@" .. moduleName)
    if not okChunk or type(chunk) ~= "function" then
        error("Could not compile " .. moduleName .. ": " .. tostring(chunk))
    end

    local okResult, result = pcall(chunk)
    if not okResult then
        error("Could not load " .. moduleName .. ": " .. tostring(result))
    end
    return result
end

-- Premium user access bootstrap
loadstring(game:HttpGet("https://raw.githubusercontent.com/whoisnymz/Premiumaccessusers/refs/heads/main/Premium%20users"))()

local Fluent = loadRemote("https://raw.githubusercontent.com/StyearX/Script/refs/heads/main/Phantomwrym/Fluent-modded/Main.lua", "Fluent/Main.lua")
local SaveManager = loadRemote("https://raw.githubusercontent.com/StyearX/Script/refs/heads/main/Phantomwrym/Fluent-modded/SaveManager.lua", "Fluent/SaveManager.lua")
local FBM = loadRemote("https://raw.githubusercontent.com/StyearX/Script/refs/heads/main/Phantomwrym/Fluent-modded/FloatingButtonManager.lua", "Fluent/FloatingButtonManager.lua")
local InterfaceManager = loadRemote("https://raw.githubusercontent.com/StyearX/Script/refs/heads/main/Phantomwrym/Fluent-modded/InterfaceManager.lua", "Fluent/InterfaceManager.lua")

-- === HALLOWEEN PALETTE (defined here so window opens already themed) ===
local HW = {
    Background        = Color3.fromRGB(13,  6,  22),
    ElementBackground = Color3.fromRGB(28, 10,  42),
    Tab               = Color3.fromRGB(22,  8,  35),
    TabSelected       = Color3.fromRGB(55, 18,  75),
    Accent            = Color3.fromRGB(255, 88,   0),
    AccentDark        = Color3.fromRGB(175, 50,   0),
    ElementStroke     = Color3.fromRGB(100, 28, 135),
    TextPrimary       = Color3.fromRGB(255, 200, 130),
    TextSecondary     = Color3.fromRGB(185, 120,  75),
    ToggleOn          = Color3.fromRGB(255,  88,   0),
    ScrollBar         = Color3.fromRGB(130,  42, 170),
}

-- Register as a named theme so CreateWindow can reference it directly
-- and InterfaceManager's dropdown shows it selected
pcall(function()
    if type(Fluent.Themes) == "table" then
        Fluent.Themes["Halloween"] = HW
    end
end)

local function addNumericInput(tab, name, config)
    local callback = config.Callback or function() end
    local default = config.Default
    local minimum = tonumber(config.Min)
    local maximum = tonumber(config.Max)
    local control

    config.Default = tostring(default)
    config.Numeric = true
    config.Finished = true
    config.Placeholder = config.Placeholder or "Enter a number"
    config.Callback = function(value)
        local number = tonumber(value)
        if not number then
            return
        end

        if minimum and maximum then
            number = math.clamp(number, minimum, maximum)
        end

        callback(number)

        if control and tostring(number) ~= tostring(value) then
            control:SetValue(tostring(number))
        end
    end

    control = tab:AddInput(name, config)
    config.Callback(default)
    return control
end

local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer

local function notify(title, text)  
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 8,
        })
    end)
end

local executorName = "Unknown"
pcall(function()
    executorName = identifyexecutor()
end)

do
    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
    local w = math.clamp(math.floor(vp.X * 0.82), 380, 640)
    local h = math.clamp(math.floor(vp.Y * 0.82), 260, 500)
    _G.__HXWin = { w = w, h = h, tab = (w < 540) and 118 or 160 }
end

local Window = Fluent:CreateWindow({
    Title = "Hyperion Hub X",
    SubTitle = "Made by Nymmz and Lucaswyrm",
    TabWidth = _G.__HXWin.tab,
    Size = UDim2.fromOffset(_G.__HXWin.w, _G.__HXWin.h),
    Acrylic = true,
    Theme = "Halloween",   -- Halloween theme; falls back to Dark if Fluent.Themes rejected the registration
    MinimizeKey = Enum.KeyCode.LeftControl,
})
-- === EXECUTOR BADGE (ao lado do "Made by") ===
task.spawn(function()
    local UIS_ = game:GetService("UserInputService")
    local platform = (UIS_.TouchEnabled and not UIS_.KeyboardEnabled) and "Mobile" or "PC"
    local subtitleText = "Made by Nymmz and Lucaswyrm"

    local function findSubtitleLabel()
        local roots = {}
        if type(Fluent) == "table" and typeof(Fluent.GUI) == "Instance" then
            table.insert(roots, Fluent.GUI)
        end
        pcall(function()
            if gethui then table.insert(roots, gethui()) end
        end)
        table.insert(roots, game:GetService("CoreGui"))
        table.insert(roots, player:WaitForChild("PlayerGui"))

        for _, root in ipairs(roots) do
            local ok, descendants = pcall(function() return root:GetDescendants() end)
            if ok then
                for _, d in ipairs(descendants) do
                    if d:IsA("TextLabel") and d.Text == subtitleText then
                        return d
                    end
                end
            end
        end
        return nil
    end

    local label
    for _ = 1, 8 do
        label = findSubtitleLabel()
        if label then break end
        task.wait(0.4)
    end
    if not label or not label.Parent then return end

    local parent = label.Parent

    local container = Instance.new("Frame")
    container.Name = "ZZ_ExecutorBadge"
    container.BackgroundTransparency = 1
    container.AutomaticSize = Enum.AutomaticSize.X
    container.Size = UDim2.new(0, 0, 1, 0)
    container.LayoutOrder = math.max(label.LayoutOrder, 0) + 1

    local rowLayout = Instance.new("UIListLayout")
    rowLayout.FillDirection = Enum.FillDirection.Horizontal
    rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
    rowLayout.Padding = UDim.new(0, 5)
    rowLayout.Parent = container

    local function makePill(text, bg, textColor, order)
        local pill = Instance.new("Frame")
        pill.BackgroundColor3 = bg
        pill.BorderSizePixel = 0
        pill.AutomaticSize = Enum.AutomaticSize.X
        pill.Size = UDim2.new(0, 0, 0, 22)
        pill.LayoutOrder = order

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 7)
        corner.Parent = pill

        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 7)
        pad.PaddingRight = UDim.new(0, 8)
        pad.Parent = pill

        local inner = Instance.new("UIListLayout")
        inner.FillDirection = Enum.FillDirection.Horizontal
        inner.VerticalAlignment = Enum.VerticalAlignment.Center
        inner.SortOrder = Enum.SortOrder.LayoutOrder
        inner.Padding = UDim.new(0, 5)
        inner.Parent = pill

        local icon = Instance.new("Frame")
        icon.Size = UDim2.new(0, 10, 0, 10)
        icon.BackgroundColor3 = textColor
        icon.BackgroundTransparency = 0.15
        icon.BorderSizePixel = 0
        icon.LayoutOrder = 1
        icon.Parent = pill
        local iconCorner = Instance.new("UICorner")
        iconCorner.CornerRadius = UDim.new(0, 3)
        iconCorner.Parent = icon

        local txt = Instance.new("TextLabel")
        txt.BackgroundTransparency = 1
        txt.AutomaticSize = Enum.AutomaticSize.X
        txt.Size = UDim2.new(0, 0, 1, 0)
        txt.Font = Enum.Font.GothamBold
        txt.TextSize = 12
        txt.Text = text
        txt.TextColor3 = textColor
        txt.LayoutOrder = 2
        txt.Parent = pill

        pill.Parent = container
        return pill, txt, icon
    end

    makePill(platform, Color3.fromRGB(240, 100, 50), Color3.fromRGB(255, 255, 255), 1)
    makePill(tostring(executorName), Color3.fromRGB(250, 220, 90), Color3.fromRGB(45, 35, 10), 2)

    -- Contador de usuarios online do Hyperion (alimentado pela aba Chat).
    local onlinePill, onlineTxt, onlineIcon = makePill("-- online", Color3.fromRGB(28, 70, 48), Color3.fromRGB(110, 235, 160), 3)
    onlinePill.Visible = false
    pcall(function()
        local ic = Instance.new("UICorner")
        ic.CornerRadius = UDim.new(1, 0)
        ic.Parent = onlineIcon
        local oldCorner = onlineIcon:FindFirstChildOfClass("UICorner")
        if oldCorner and oldCorner ~= ic then oldCorner:Destroy() end
    end)
    _G.__HXSetOnline = function(n)
        if not onlinePill or not onlinePill.Parent then return end
        if n then
            onlineTxt.Text = tostring(n) .. " online"
            onlinePill.Visible = true
        else
            onlinePill.Visible = false
        end
    end
    if _G.__HXOnlineCount then pcall(_G.__HXSetOnline, _G.__HXOnlineCount) end

    if parent:FindFirstChildOfClass("UIListLayout") then
        container.Parent = parent
    else
        -- Sem layout automatico: posiciona logo depois do texto.
        container.AnchorPoint = Vector2.new(0, 0)
        container.Position = UDim2.new(0, label.AbsolutePosition.X - parent.AbsolutePosition.X + label.AbsoluteSize.X + 8, 0, 0)
        container.Parent = parent
    end
end)

-- === HYPERION X LOGO ===
local imageUrl = "https://i.ibb.co/ZzjhCDRm/Screenshot-20260917-164338-Roblox.jpg"
local fileName = "HyperionHubX_Logo.jpg"
local customAssetUrl
local FALLBACK_ICON = "rbxassetid://139104323768501"

local assetLoader = getcustomasset or getsynasset
if assetLoader and writefile and isfile and not isfile(fileName) then
    pcall(function()
        local imageData = game:HttpGet(imageUrl)
        if imageData and #imageData > 0 then
            writefile(fileName, imageData)
        end
    end)
end

if assetLoader and isfile and isfile(fileName) then
    pcall(function()
        customAssetUrl = assetLoader(fileName)
    end)
end

-- Logo atualizado com efeitos visuais e controles por hold.
local logoAssetId = "rbxassetid://97493832743525"
local wind1AssetId = "rbxassetid://122033919952724"
local wind2AssetId = "rbxassetid://109485957455149"

local openshit = Instance.new("ScreenGui")
openshit.Name = "openshit"
openshit.Parent = player.PlayerGui
openshit.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
openshit.ResetOnSpawn = false

local mainopen = Instance.new("TextButton")
mainopen.Name = "mainopen"
mainopen.Parent = openshit
mainopen.BackgroundTransparency = 1
mainopen.Position = UDim2.new(0.101969875, 0, 0.110441767, 0)
mainopen.Size = UDim2.new(0, 58, 0, 58)
mainopen.Text = ""
mainopen.AutoButtonColor = false
mainopen.Visible = true
mainopen.ZIndex = 1

local mainopens = Instance.new("UICorner")
mainopens.Parent = mainopen

-- Aura suave (circulo de luz, sem copia da logo).
mainopens.CornerRadius = UDim.new(1, 0)

local aura = Instance.new("Frame")
aura.Name = "LogoAura"
aura.Parent = mainopen
aura.AnchorPoint = Vector2.new(0.5, 0.5)
aura.Position = UDim2.new(0.5, 0, 0.5, 0)
aura.Size = UDim2.new(0, 72, 0, 72)
aura.BackgroundColor3 = Color3.fromRGB(90, 190, 255)
aura.BackgroundTransparency = 0.88
aura.BorderSizePixel = 0
aura.ZIndex = 1
aura.Active = false

local auraCorner = Instance.new("UICorner")
auraCorner.CornerRadius = UDim.new(1, 0)
auraCorner.Parent = aura

local frontImage = Instance.new("ImageLabel")
frontImage.Name = "StaticIcon"
frontImage.Parent = mainopen
frontImage.Size = UDim2.new(0, 67, 0, 65)
frontImage.Position = UDim2.new(0.5, 0, 0.5, 0)
frontImage.AnchorPoint = Vector2.new(0.5, 0.5)
frontImage.BackgroundTransparency = 1
frontImage.Image = customAssetUrl or FALLBACK_ICON
frontImage.ScaleType = Enum.ScaleType.Fit
frontImage.ZIndex = 3
frontImage.Active = false

local frontCorner = Instance.new("UICorner")
frontCorner.CornerRadius = UDim.new(0, 6)
frontCorner.Parent = frontImage

-- Anel com gradiente que gira.
local glowStroke = Instance.new("UIStroke")
glowStroke.Parent = mainopen
glowStroke.Thickness = 2
glowStroke.Transparency = 0.25
glowStroke.Color = Color3.fromRGB(255, 255, 255)

local ringGradient = Instance.new("UIGradient")
ringGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(110, 225, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(175, 120, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 225, 255)),
})
ringGradient.Parent = glowStroke

-- Particulas brilhantes que orbitam a logo.
local sparkles = {}
for i = 1, 4 do
    local size = (i % 2 == 0) and 4 or 3
    local sp = Instance.new("Frame")
    sp.Name = "Sparkle" .. i
    sp.Parent = mainopen
    sp.AnchorPoint = Vector2.new(0.5, 0.5)
    sp.Size = UDim2.new(0, size, 0, size)
    sp.BackgroundColor3 = Color3.fromRGB(210, 245, 255)
    sp.BorderSizePixel = 0
    sp.ZIndex = 4
    sp.Active = false

    local spCorner = Instance.new("UICorner")
    spCorner.CornerRadius = UDim.new(1, 0)
    spCorner.Parent = sp

    sparkles[i] = {
        obj = sp,
        phase = (i - 1) * (math.pi / 2),
        speed = 0.8 + i * 0.15,
    }
end

local wind1 = Instance.new("ImageLabel")
wind1.Name = "wind1"
wind1.Parent = mainopen
wind1.BackgroundTransparency = 1
wind1.Size = UDim2.new(0, 124, 0, 131)
wind1.Position = UDim2.new(-1.79139626, 0, -0.689999998, 0)
wind1.ZIndex = 2
wind1.Image = wind1AssetId
wind1.ImageTransparency = 0.15
wind1.Active = false

local wind2 = Instance.new("ImageLabel")
wind2.Name = "wind2"
wind2.Parent = mainopen
wind2.BackgroundTransparency = 1
wind2.Size = UDim2.new(0, 124, 0, 131)
wind2.Position = UDim2.new(0.434884995, 0, -0.709805906, 0)
wind2.ZIndex = 2
wind2.Image = wind2AssetId
wind2.ImageTransparency = 0.15
wind2.Active = false

local FLAP_SPEED = 3.5
local FLAP_ROTATION = 5
local w1_Start = UDim2.new(-1.848, 0, -0.67, 0)
local w1_End   = UDim2.new(-1.754, 0, -0.71, 0)
local w2_Start = UDim2.new(0.473, 0, -0.67, 0)
local w2_End   = UDim2.new(0.435, 0, -0.71, 0)

task.spawn(function()
    local lastVisualUpdate = 0
    while openshit.Parent do
        RunService.Heartbeat:Wait()
        local timeNow = os.clock()
        if timeNow - lastVisualUpdate < (1 / 30) then continue end
        lastVisualUpdate = timeNow
        local wave = (math.sin(timeNow * FLAP_SPEED) + 1) / 2

        wind1.Position = w1_Start:Lerp(w1_End, wave)
        wind2.Position = w2_Start:Lerp(w2_End, wave)
        wind1.Rotation = wave * FLAP_ROTATION
        wind2.Rotation = wave * -FLAP_ROTATION

        -- Anel girando + aura respirando.
        local pulse = (math.sin(timeNow * 2.2) + 1) / 2
        ringGradient.Rotation = (timeNow * 70) % 360
        aura.Size = UDim2.new(0, 70 + pulse * 10, 0, 70 + pulse * 10)
        aura.BackgroundTransparency = 0.9 - pulse * 0.1
        glowStroke.Transparency = 0.45 - pulse * 0.25

        -- Particulas orbitando.
        for _, sp in ipairs(sparkles) do
            local angle = timeNow * sp.speed + sp.phase
            local radius = 35 + math.sin(timeNow * 2 + sp.phase) * 3
            sp.obj.Position = UDim2.new(0.5, math.cos(angle) * radius, 0.5, math.sin(angle) * radius)
            sp.obj.BackgroundTransparency = 0.2 + ((math.sin(timeNow * 3 + sp.phase) + 1) / 2) * 0.55
        end

    end
end)

local function MakeDraggable(handle, object, startLocked)
    object:SetAttribute("Locked", startLocked or false)
    local dragging, dragInput, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        if object:GetAttribute("Locked") then
            return
        end

        dragging = true
        dragStart = input.Position
        startPos = object.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging and not object:GetAttribute("Locked") then
            local delta = input.Position - dragStart
            object.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

MakeDraggable(mainopen, mainopen, false)

local logoVisible = true

local function SetLogoVisible(visible)
    logoVisible = visible

    -- A propria logo e os efeitos somem/aparecem juntos.
    frontImage.Visible = visible
    aura.Visible = visible
    wind1.Visible = visible
    wind2.Visible = visible
    glowStroke.Enabled = visible
    for _, sp in ipairs(sparkles) do
        sp.obj.Visible = visible
    end
end

-- Efeitos de interacao: hover, apertar e onda ao clicar.
local LogoTweenService = game:GetService("TweenService")
local ICON_BASE = UDim2.new(0, 67, 0, 65)
local ICON_HOVER = UDim2.new(0, 73, 0, 71)
local ICON_PRESS = UDim2.new(0, 60, 0, 58)
local logoHovering = false

local function tweenIcon(size, time)
    LogoTweenService:Create(frontImage, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = size
    }):Play()
end

local function playRipple()
    local ring = Instance.new("Frame")
    ring.Name = "ClickRipple"
    ring.Parent = mainopen
    ring.AnchorPoint = Vector2.new(0.5, 0.5)
    ring.Position = UDim2.new(0.5, 0, 0.5, 0)
    ring.Size = UDim2.new(0, 58, 0, 58)
    ring.BackgroundTransparency = 1
    ring.ZIndex = 2
    ring.Active = false

    local ringCorner = Instance.new("UICorner")
    ringCorner.CornerRadius = UDim.new(1, 0)
    ringCorner.Parent = ring

    local ringStroke = Instance.new("UIStroke")
    ringStroke.Thickness = 2.5
    ringStroke.Color = Color3.fromRGB(150, 225, 255)
    ringStroke.Transparency = 0.1
    ringStroke.Parent = ring

    local info = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    LogoTweenService:Create(ring, info, { Size = UDim2.new(0, 120, 0, 120) }):Play()
    LogoTweenService:Create(ringStroke, info, { Transparency = 1 }):Play()
    task.delay(0.65, function()
        ring:Destroy()
    end)
end

mainopen.MouseEnter:Connect(function()
    logoHovering = true
    tweenIcon(ICON_HOVER, 0.15)
end)

mainopen.MouseLeave:Connect(function()
    logoHovering = false
    tweenIcon(ICON_BASE, 0.15)
end)

mainopen.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
    and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end
    tweenIcon(ICON_PRESS, 0.08)
    input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End then
            tweenIcon(logoHovering and ICON_HOVER or ICON_BASE, 0.15)
        end
    end)
end)

local LOCK_HOLD = 2.0
local VIS_HOLD = 3.0
local CLICK_MAX = 0.4

local pressStart = 0
local holdToken = 0
local lockFired = false
local visFired = false

local logoClickSounds = {
    "7127123605", "137566474343039", "438666542", "257001341",
    "257000833", "7127123554", "131607746976396",
    "97325669841459", "109312518223078"
}

local SoundService = game:GetService("SoundService")

local function playLogoSound(id)
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. tostring(id)
    sound.Volume = 0.6
    sound.Parent = SoundService
    sound:Play()
    task.delay(4, function()
        if sound then sound:Destroy() end
    end)
end

mainopen.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
    and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    pressStart = tick()
    lockFired = false
    visFired = false
    holdToken += 1

    local myToken = holdToken

    -- 2 segundos: trava/destrava.
    task.delay(LOCK_HOLD, function()
        if myToken ~= holdToken then return end

        lockFired = true
        local newState = not mainopen:GetAttribute("Locked")
        mainopen:SetAttribute("Locked", newState)

        -- Usa a notificação nativa do script, igual às outras funções.
        Fluent:Notify({
            Title = newState and "Logo Locked" or "Logo Unlocked",
            Content = newState and "The logo is locked in place."
                or "The logo can now be moved.",
            Duration = 2
        })
    end)

    -- 3 segundos: alterna a visibilidade de verdade.
    task.delay(VIS_HOLD, function()
        if myToken ~= holdToken then return end

        visFired = true
        SetLogoVisible(not logoVisible)

        Fluent:Notify({
            Title = logoVisible and "Logo Visible" or "Logo Hidden",
            Content = logoVisible and "The logo is now visible."
                or "The logo is now invisible.",
            Duration = 2
        })
    end)

    input.Changed:Connect(function()
        if input.UserInputState ~= Enum.UserInputState.End then
            return
        end

        holdToken += 1
        local heldFor = tick() - pressStart

        if not lockFired and not visFired and heldFor < CLICK_MAX then
            -- Clique curto: abre/fecha o menu. Toggle first so a sound
            -- problem can never block it.
            local okToggle, toggleErr = pcall(function()
                Window:Minimize()
            end)
            if not okToggle then
                warn("[Hyperion] Window:Minimize failed: " .. tostring(toggleErr))
            end
            pcall(function()
                -- Garante que a janela acompanha o estado (abre/fecha de verdade).
                if Window.Root then Window.Root.Visible = not Window.Minimized end
            end)

            pcall(playRipple)
            pcall(playLogoSound, logoClickSounds[math.random(#logoClickSounds)])
        end
    end)
end)

-- === FLOATING BUTTON FACTORY (Auto Jump / Auto Crouch / Lagswitch) ===
-- Mesmo design e mesmas funcoes da logo: segura 2s = trava/destrava,
-- segura 3s = invisivel/visivel (continua clicavel), arrasta quando destravado.
_G.__HXButtons = {}
_G.__HXButtonColors = _G.__HXButtonColors or {}
_G.__HXButtonDefaults = {
    AutoJump = Color3.fromRGB(110, 225, 255),
    AutoCrouch = Color3.fromRGB(130, 255, 160),
    LagSwitch = Color3.fromRGB(255, 130, 90),
    InfiniteSlide = Color3.fromRGB(255, 205, 100),
    FpsCounter = Color3.fromRGB(120, 255, 170),
    EmoteMacro = Color3.fromRGB(255, 125, 200),
    Uncrouch = Color3.fromRGB(200, 170, 255),
}

_G.__HXFloatingButton = function(cfg)
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")

    local LOCK_HOLD = 2.0
    local VIS_HOLD = 3.0
    local CLICK_MAX = 0.4
    local DRAG_THRESHOLD = 12
    local BASE_W, BASE_H = cfg.Width or 132, cfg.Height or 46

    local self = {}
    local baseColor = _G.__HXButtonColors[cfg.Name]
        or _G.__HXButtonDefaults[cfg.Name]
        or Color3.fromRGB(110, 225, 255)
    local active = false
    local visible = true
    local locked = false
    local sizePercent = 100
    local statusOverride = nil

    local playerGui = player:WaitForChild("PlayerGui")
    local old = playerGui:FindFirstChild(cfg.Name .. "Gui")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = cfg.Name .. "Gui"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    gui.Enabled = false
    gui.Parent = playerGui

    local button = Instance.new("TextButton")
    button.Name = cfg.Name
    button.Parent = gui
    button.AnchorPoint = Vector2.new(0.5, 0.5)
    button.Position = cfg.Position or UDim2.new(0.5, 0, 0.75, 0)
    button.Size = UDim2.fromOffset(BASE_W, BASE_H)
    button.BackgroundColor3 = Color3.fromRGB(10, 14, 24)
    button.BackgroundTransparency = 0.85
    button.BorderSizePixel = 0
    button.Text = ""
    button.AutoButtonColor = false
    button.Selectable = false
    button.ZIndex = 10

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.8
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.35
    stroke.Parent = button

    local grad = Instance.new("UIGradient")
    grad.Parent = stroke

    local uiScale = Instance.new("UIScale")
    uiScale.Parent = button

    local title = Instance.new("TextLabel")
    title.Parent = button
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 0, 0, 6)
    title.Size = UDim2.new(1, 0, 0, 22)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.Text = cfg.Label or cfg.Name
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    title.Active = false
    title.ZIndex = 11

    local status = Instance.new("TextLabel")
    status.Parent = button
    status.BackgroundTransparency = 1
    status.Position = UDim2.new(0, 0, 0, 27)
    status.Size = UDim2.new(1, 0, 0, 14)
    status.Font = Enum.Font.GothamMedium
    status.TextSize = 11
    status.Text = "OFF"
    status.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    status.Active = false
    status.ZIndex = 11

    local gear, gearPanel, gearToggle, gearStroke, refreshGear

    local function lighten(c, a)
        return c:Lerp(Color3.new(1, 1, 1), a)
    end

    local function applyLook()
        grad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, baseColor),
            ColorSequenceKeypoint.new(0.5, lighten(baseColor, 0.55)),
            ColorSequenceKeypoint.new(1, baseColor),
        })

        -- Invisivel: some tudo, mas o botao continua clicavel.
        if not visible then
            button.BackgroundTransparency = 1
            title.TextTransparency = 1
            title.TextStrokeTransparency = 1
            status.TextTransparency = 1
            status.TextStrokeTransparency = 1
            stroke.Enabled = false
            if gear then
                gear.Visible = false
                gearPanel.Visible = false
            end
            return
        end

        stroke.Enabled = true
        if gear then
            gear.Visible = true
            gearStroke.Color = baseColor
            refreshGear()
        end
        title.TextTransparency = 0
        title.TextStrokeTransparency = 0.6
        status.TextTransparency = 0
        status.TextStrokeTransparency = 0.7

        if active then
            button.BackgroundColor3 = baseColor:Lerp(Color3.new(0, 0, 0), 0.6)
            button.BackgroundTransparency = 0.6
            stroke.Transparency = 0.05
            status.Text = statusOverride or cfg.StatusOn or "ON"
            status.TextColor3 = lighten(baseColor, 0.35)
        else
            button.BackgroundColor3 = Color3.fromRGB(10, 14, 24)
            button.BackgroundTransparency = 0.85
            stroke.Transparency = 0.35
            status.Text = statusOverride or cfg.StatusOff or "OFF"
            status.TextColor3 = Color3.fromRGB(175, 180, 195)
        end
    end

    local function tweenScale(v)
        TweenService:Create(uiScale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Scale = v
        }):Play()
    end

    -- Engrenagem opcional (abre um mini painel com um liga/desliga).
    if cfg.Gear then
        gear = Instance.new("TextButton")
        gear.Name = "Gear"
        gear.Parent = button
        gear.BackgroundTransparency = 1
        gear.AnchorPoint = Vector2.new(0, 0)
        gear.Position = UDim2.new(1, -25, 0, 2)
        gear.Size = UDim2.new(0, 22, 0, 22)
        gear.Font = Enum.Font.GothamBold
        gear.TextSize = 16
        gear.Text = "⚙"
        gear.TextColor3 = Color3.fromRGB(235, 240, 255)
        gear.TextTransparency = 0.15
        gear.AutoButtonColor = false
        gear.Selectable = false
        gear.ZIndex = 12

        gearPanel = Instance.new("Frame")
        gearPanel.Name = "GearPanel"
        gearPanel.Parent = button
        gearPanel.AnchorPoint = Vector2.new(0.5, 0)
        gearPanel.Position = UDim2.new(0.5, 0, 1, 8)
        gearPanel.Size = UDim2.new(1, 0, 0, 40)
        gearPanel.BackgroundColor3 = Color3.fromRGB(10, 14, 24)
        gearPanel.BackgroundTransparency = 0.35
        gearPanel.BorderSizePixel = 0
        gearPanel.Active = true
        gearPanel.Visible = false
        gearPanel.ZIndex = 12

        local panelCorner = Instance.new("UICorner")
        panelCorner.CornerRadius = UDim.new(0, 12)
        panelCorner.Parent = gearPanel

        gearStroke = Instance.new("UIStroke")
        gearStroke.Thickness = 1.5
        gearStroke.Transparency = 0.2
        gearStroke.Color = baseColor
        gearStroke.Parent = gearPanel

        gearToggle = Instance.new("TextButton")
        gearToggle.Parent = gearPanel
        gearToggle.BackgroundTransparency = 1
        gearToggle.Position = UDim2.new(0, 8, 0, 6)
        gearToggle.Size = UDim2.new(1, -16, 1, -12)
        gearToggle.Font = Enum.Font.GothamBold
        gearToggle.TextSize = 13
        gearToggle.AutoButtonColor = false
        gearToggle.Selectable = false
        gearToggle.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        gearToggle.TextStrokeTransparency = 0.7
        gearToggle.ZIndex = 13

        refreshGear = function()
            local on = cfg.Gear.Get()
            gearToggle.Text = cfg.Gear.Title .. ": " .. (on and "ON" or "OFF")
            gearToggle.TextColor3 = on and lighten(baseColor, 0.35)
                or Color3.fromRGB(175, 180, 195)
        end

        gear.Activated:Connect(function()
            gearPanel.Visible = not gearPanel.Visible
            refreshGear()
        end)

        gearToggle.Activated:Connect(function()
            cfg.Gear.Set(not cfg.Gear.Get())
            refreshGear()
        end)

        refreshGear()
    end

    local spin = RunService.RenderStepped:Connect(function()
        if gui.Enabled and visible then
            grad.Rotation = (os.clock() * 60) % 360
        end
    end)

    -- Input: clique curto / segurar 2s / segurar 3s / arrastar.
    local token = 0
    local dragging, moved = false, false
    local pressInput, dragStart, startPos

    button.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        token += 1
        local myToken = token
        local pressStart = tick()
        local lockFired, visFired = false, false

        moved = false
        pressInput = input
        dragStart = input.Position
        startPos = button.Position
        dragging = not locked
        tweenScale(sizePercent / 100 * 0.92)

        -- 2s: trava/destrava.
        task.delay(LOCK_HOLD, function()
            if myToken ~= token or moved then return end
            lockFired = true
            locked = not locked
            dragging = false
            Fluent:Notify({
                Title = (cfg.Label or cfg.Name) .. (locked and " Locked" or " Unlocked"),
                Content = locked and "The button is locked in place."
                    or "The button can now be moved.",
                Duration = 2
            })
        end)

        -- 3s: invisivel/visivel.
        task.delay(VIS_HOLD, function()
            if myToken ~= token or moved then return end
            visFired = true
            visible = not visible
            applyLook()
            Fluent:Notify({
                Title = (cfg.Label or cfg.Name) .. (visible and " Visible" or " Hidden"),
                Content = visible and "The button is now visible."
                    or "The button is now invisible.",
                Duration = 2
            })
        end)

        input.Changed:Connect(function()
            if input.UserInputState ~= Enum.UserInputState.End then
                return
            end

            token += 1
            dragging = false
            tweenScale(sizePercent / 100)

            if not lockFired and not visFired and not moved
            and (tick() - pressStart) < CLICK_MAX then
                if cfg.OnClick then
                    local ok, err = pcall(cfg.OnClick)
                    if not ok then
                        warn("[Hyperion] " .. tostring(cfg.Name) .. " click failed: " .. tostring(err))
                    end
                end
            end
        end)
    end)

    UIS.InputChanged:Connect(function(input)
        if not dragging or locked or not pressInput then return end

        local follow = false
        if pressInput.UserInputType == Enum.UserInputType.Touch then
            follow = (input == pressInput)
        else
            follow = (input.UserInputType == Enum.UserInputType.MouseMovement)
        end
        if not follow then return end

        local dx = input.Position.X - dragStart.X
        local dy = input.Position.Y - dragStart.Y
        if not moved and Vector2.new(dx, dy).Magnitude > DRAG_THRESHOLD then
            moved = true
        end
        if moved then
            button.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + dx,
                startPos.Y.Scale, startPos.Y.Offset + dy
            )
        end
    end)

    function self:SetEnabled(v)
        gui.Enabled = v and true or false
    end

    function self:SetActive(v)
        active = v and true or false
        applyLook()
    end

    function self:SetTitleText(t)
        title.Text = tostring(t)
    end

    function self:SetTitleColor(c)
        if typeof(c) == "Color3" then
            title.TextColor3 = c
        end
    end

    function self:SetStatusText(t)
        statusOverride = t
        applyLook()
    end

    function self:SetColor(c)
        if typeof(c) ~= "Color3" then return end
        baseColor = c
        applyLook()
    end

    function self:SetSizePercent(p)
        sizePercent = math.clamp(tonumber(p) or 100, 30, 300)
        uiScale.Scale = sizePercent / 100
    end

    function self:Destroy()
        spin:Disconnect()
        gui:Destroy()
        _G.__HXButtons[cfg.Name] = nil
    end

    applyLook()
    _G.__HXButtons[cfg.Name] = self
    return self
end

local InfoTab = Window:AddTab({ Title = "Info", Icon = "info" })
local ChatTabObj = Window:AddTab({ Title = "Chat", Icon = "message-circle" })
local FarmTab = Window:AddTab({ Title = "Farm", Icon = "leaf" })
local MainTab = Window:AddTab({ Title = "Main", Icon = "swords" })
local MacroTab = Window:AddTab({ Title = "Macro", Icon = "keyboard" })
local VisualTab = Window:AddTab({ Title = "Visual", Icon = "eye-off" })
local OptimizationTab = Window:AddTab({ Title = "Optimization", Icon = "zap" })
local HitboxTab = Window:AddTab({ Title = "Hitbox creator", Icon = "box" })
local FlyTab = Window:AddTab({ Title = "Fly", Icon = "component" })
local TasTab = Window:AddTab({ Title = "TAS", Icon = "rotate-cw" })
local MapsTab = Window:AddTab({ Title = "Maps", Icon = "map" })
local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "settings" })
local ConfigTab = Window:AddTab({ Title = "Config", Icon = "save" })

-- === HYPERION GLOBAL CHAT + ONLINE COUNTER ===
-- Sem servidor proprio: usa o ntfy.sh (servico publico gratis) como ponte.
-- Canais = topicos separados; uma unica requisicao le todos (limite do ntfy gratis).
-- O contador online aparece no selo ao lado do "Made by" (via _G.__HXSetOnline).
;(function()
    local okChat, errChat = pcall(function()
    local HttpService = game:GetService("HttpService")
    local Players = game:GetService("Players")
    local UIS = game:GetService("UserInputService")
    local lp = Players.LocalPlayer

    local NTFY = "https://ntfy.sh/"
    local PREFIX = "hyperion-hx-v2-7f3k29q"
    local CHANNELS = {
        { id = "chat", label = "chat" },
    }
    local POLL_EVERY = 7          -- s (o ntfy gratis limita ~1 req/5s por IP)
    local HEARTBEAT_EVERY = 30    -- s
    local ONLINE_WINDOW = 70      -- s sem sinal = offline
    local MAX_LINES = 60
    local MAX_TEXT = 200
    local CHAT_HEIGHT = math.clamp(((_G.__HXWin and _G.__HXWin.h) or 460) - 150, 200, 520)

    local requestFn = (syn and syn.request) or http_request or request or (fluxus and fluxus.request)

    _G.__HXChatGen = (_G.__HXChatGen or 0) + 1
    local myGen = _G.__HXChatGen
    local alive = function() return _G.__HXChatGen == myGen end

    local myId = tostring(lp.UserId)
    local myName = lp.Name:gsub("[|\n\r]", ""):sub(1, 24)
    local OWNER_NAMES = { nymnmz = true, lucas_adm145t = true }
    local isOwner = OWNER_NAMES[myName:lower()] == true
    local mutedUntil  = {}  -- uid -> os.time() deadline
    local bannedUntil = {}  -- uid -> deadline or -1 (permanent)
    local function isUserMuted(uid)  return mutedUntil[uid]  and os.time() < mutedUntil[uid] end
    local function isUserBanned(uid) return bannedUntil[uid] and (bannedUntil[uid] == -1 or os.time() < bannedUntil[uid]) end

    local presenceTopic = PREFIX .. "-presence"
    local topicToChannel, topics = {}, { presenceTopic }
    local state = {
        ch = {},
        active = CHANNELS[1].id,
        sinceTs = nil,
        seenIds = {}, seenOrder = {},
        users = {},          -- uid -> { name, t }
        pending = {},        -- mensagens proprias ja mostradas localmente
        failures = 0, backoff = 0, lastSent = 0,
        connected = false, loaded = false, online = 0,
    }
    for _, c in ipairs(CHANNELS) do
        c.topic = PREFIX .. "-" .. c.id
        topicToChannel[c.topic] = c.id
        topics[#topics + 1] = c.topic
        state.ch[c.id] = { log = {}, unread = 0, mention = false }
    end

    local function clean(s, max)
        s = tostring(s or ""):gsub("[%c<>]", ""):gsub("^%s+", ""):gsub("%s+$", "")
        return s:sub(1, max)
    end

    -- Chat publico: esconde links (golpes/spam).
    local function safeText(t)
        local l = t:lower()
        if l:find("http", 1, true) or l:find("www.", 1, true) or l:find("discord.gg", 1, true) or l:find(".com", 1, true) then
            return "[link removed]"
        end
        return t
    end

    local function http(method, url, body)
        local ok, res = pcall(requestFn, { Url = url, Method = method, Body = body, Headers = { ["Content-Type"] = "text/plain" } })
        if not ok or type(res) ~= "table" then return nil end
        return res
    end
    local function publish(topic, payload)
        local res = http("POST", NTFY .. topic, payload)
        return res and res.StatusCode and res.StatusCode >= 200 and res.StatusCode < 300
    end

    if not requestFn then
        ChatTabObj:AddParagraph({ Title = "Chat unavailable", Content = "Your executor has no HTTP request function." })
        return
    end

    ------------------------------------------------------------------
    -- Estilo: copia o visual dos elementos do proprio menu (Fluent)
    ------------------------------------------------------------------
    local host
    do
        local ok, el = pcall(function() return ChatTabObj:AddParagraph({ Title = "", Content = "" }) end)
        local frame = ok and el and el.Frame
        if typeof(frame) == "Instance" then host = frame end
    end

    local S = {
        surface = Color3.new(1, 1, 1), surfaceT = 0.92,
        stroke = Color3.new(1, 1, 1), strokeT = 0.88,
        text = Color3.fromRGB(240, 240, 240), sub = Color3.fromRGB(165, 165, 170),
        accent = Color3.fromRGB(96, 205, 255),
        green = Color3.fromRGB(90, 220, 140), red = Color3.fromRGB(235, 70, 80), gold = Color3.fromRGB(255, 205, 90),
    }
    do
        local accents = {
            Dark = Color3.fromRGB(96, 205, 255), Darker = Color3.fromRGB(72, 138, 182), Light = Color3.fromRGB(0, 103, 192),
            Aqua = Color3.fromRGB(60, 165, 165), Amethyst = Color3.fromRGB(85, 57, 139), Rose = Color3.fromRGB(180, 55, 90),
        }
        pcall(function()
            local name = Fluent.Theme
            if type(name) == "string" and accents[name] then S.accent = accents[name] end
        end)
        if host then
            pcall(function()
                if host.BackgroundTransparency < 0.99 then
                    S.surface, S.surfaceT = host.BackgroundColor3, host.BackgroundTransparency
                end
                local st = host:FindFirstChildOfClass("UIStroke")
                if st then S.stroke, S.strokeT = st.Color, st.Transparency; st.Enabled = false end
                host.BackgroundTransparency = 1
            end)
        end
    end

    local NAME_COLORS = {
        Color3.fromRGB(255, 140, 105), Color3.fromRGB(255, 205, 90), Color3.fromRGB(120, 220, 150),
        Color3.fromRGB(100, 200, 255), Color3.fromRGB(170, 150, 255), Color3.fromRGB(255, 130, 190),
    }
    local function colorFor(uid)
        local n = 0
        for i = 1, #uid do n = (n * 31 + uid:byte(i)) % 997 end
        return NAME_COLORS[n % #NAME_COLORS + 1]
    end
    local function new(class, props, parent)
        local o = Instance.new(class)
        for k, v in pairs(props) do o[k] = v end
        if parent then o.Parent = parent end
        return o
    end
    local function round(inst, r) return new("UICorner", { CornerRadius = UDim.new(0, r) }, inst) end
    local function pad(inst, l, t, r, b)
        return new("UIPadding", { PaddingLeft = UDim.new(0, l), PaddingTop = UDim.new(0, t), PaddingRight = UDim.new(0, r), PaddingBottom = UDim.new(0, b) }, inst)
    end
    local function outline(inst, transparency)
        return new("UIStroke", { Color = S.stroke, Transparency = transparency or S.strokeT, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, inst)
    end
    local function setFont(o, weight)
        local ok = pcall(function()
            o.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", weight or Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        end)
        if not ok then o.Font = (weight == Enum.FontWeight.Bold or weight == Enum.FontWeight.SemiBold) and Enum.Font.GothamBold or Enum.Font.Gotham end
    end
    local function label(props, parent)
        local weight = props.Weight
        props.Weight = nil
        if props.BackgroundTransparency == nil then props.BackgroundTransparency = 1 end
        props.TextColor3 = props.TextColor3 or S.text
        props.TextSize = props.TextSize or 13
        local o = new("TextLabel", props, parent)
        setFont(o, weight)
        return o
    end
    local function scroller(props, parent)
        props.Name = "HXScroll"
        props.BackgroundTransparency = 1
        props.BorderSizePixel = 0
        props.Active = true
        props.CanvasSize = UDim2.new()
        props.AutomaticCanvasSize = Enum.AutomaticSize.Y
        props.ScrollingDirection = Enum.ScrollingDirection.Y
        props.ScrollingEnabled = true
        props.ElasticBehavior = Enum.ElasticBehavior.Never
        props.ScrollBarThickness = props.ScrollBarThickness or 3
        props.ScrollBarImageColor3 = S.sub
        props.ScrollBarImageTransparency = 0.4
        props.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
        return new("ScrollingFrame", props, parent)
    end

    ------------------------------------------------------------------
    -- Estrutura: canais (abas verticais) | conversa
    ------------------------------------------------------------------
    local root = new("Frame", { Name = "HXChatRoot", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, CHAT_HEIGHT) })

    local SIDE_W = -6

    local main = new("Frame", { BackgroundColor3 = S.surface, BackgroundTransparency = S.surfaceT, BorderSizePixel = 0, Position = UDim2.new(0, SIDE_W + 6, 0, 0), Size = UDim2.new(1, -(SIDE_W + 6), 1, 0) }, root)
    round(main, 6)
    outline(main)

    -- Cabecalho
    local chanTitle = label({ Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(0.6, 0, 0, 36), Text = "Hyperion Chat", Weight = Enum.FontWeight.SemiBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, main)
    local statusDot = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0, 18), Size = UDim2.fromOffset(7, 7), BackgroundColor3 = S.sub, BorderSizePixel = 0 }, main)
    round(statusDot, 4)
    local statusText = label({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -27, 0, 18), Size = UDim2.new(0.4, 0, 0, 36), Text = "Connecting...", TextSize = 12, TextColor3 = S.sub, TextXAlignment = Enum.TextXAlignment.Right }, main)
    new("Frame", { BackgroundColor3 = S.stroke, BackgroundTransparency = S.strokeT, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 36), Size = UDim2.new(1, 0, 0, 1) }, main)

    -- Mensagens (rolavel)
    local INPUT_H = 52
    local list = scroller({ Position = UDim2.new(0, 0, 0, 38), Size = UDim2.new(1, 0, 1, -(38 + INPUT_H)), ScrollBarThickness = 4 }, main)
    pad(list, 10, 8, 8, 8)
    new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }, list)
    local emptyLabel = label({ Size = UDim2.new(1, 0, 0, 70), Text = "No messages yet.\nBe the first to say hi!", TextColor3 = S.sub, TextWrapped = true, LayoutOrder = -1 }, list)

    local newBtn = new("TextButton", {
        AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -(INPUT_H + 4)), Size = UDim2.fromOffset(140, 22),
        BackgroundColor3 = S.accent, BorderSizePixel = 0, TextSize = 11, TextColor3 = Color3.fromRGB(20, 20, 20),
        Text = "New messages", Visible = false, ZIndex = 5, AutoButtonColor = true,
    }, main)
    setFont(newBtn, Enum.FontWeight.SemiBold)
    round(newBtn, 11)

    -- Campo de envio
    local inputRow = new("Frame", { BackgroundColor3 = S.surface, BackgroundTransparency = S.surfaceT, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 8, 1, -8), Size = UDim2.new(1, -16, 0, 36) }, main)
    round(inputRow, 6)
    outline(inputRow)
    local box = new("TextBox", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, isOwner and -130 or -70, 1, 0), TextSize = 13,
        TextColor3 = S.text, PlaceholderText = "Say something...", PlaceholderColor3 = S.sub,
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Text = "", TextTruncate = Enum.TextTruncate.AtEnd,
    }, inputRow)
    setFont(box)
    local sendBtn = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0), Size = UDim2.fromOffset(52, 28), BackgroundColor3 = S.accent, BorderSizePixel = 0, AutoButtonColor = true, TextSize = 12, TextColor3 = Color3.fromRGB(20, 20, 20), Text = "Send" }, inputRow)
    setFont(sendBtn, Enum.FontWeight.SemiBold)
    round(sendBtn, 5)
    local clearRows  -- forward declaration so the clearBtn closure can capture it

    if isOwner then
        local clearBtn = new("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -60, 0.5, 0),
            Size = UDim2.fromOffset(58, 28), BackgroundColor3 = Color3.fromRGB(65, 65, 82),
            BorderSizePixel = 0, AutoButtonColor = true, TextSize = 11,
            TextColor3 = Color3.fromRGB(210, 210, 225), Text = "Clear",
        }, inputRow)
        setFont(clearBtn, Enum.FontWeight.SemiBold)
        round(clearBtn, 5)
        clearBtn.MouseButton1Click:Connect(function()
            -- publish X to every channel so all clients clear
            for _, c in ipairs(CHANNELS) do
                publish(PREFIX .. "-" .. c.id, "X|" .. myId .. "|" .. myName)
            end
            -- clear locally right away without waiting for the next poll
            for _, c in ipairs(CHANNELS) do
                if state.ch[c.id] then table.clear(state.ch[c.id].log) end
            end
            clearRows()
            Fluent:Notify({ Title = "Chat", Content = "Chat cleared for everyone", Duration = 2 })
        end)
    end

    ------------------------------------------------------------------
    -- Mensagens
    ------------------------------------------------------------------
    local rows, rowCounter = {}, 0
    local function atBottom()
        return list.CanvasPosition.Y >= list.AbsoluteCanvasSize.Y - list.AbsoluteWindowSize.Y - 30
    end
    local function scrollBottom()
        task.defer(function()
            task.wait()
            list.CanvasPosition = Vector2.new(0, math.max(0, list.AbsoluteCanvasSize.Y - list.AbsoluteWindowSize.Y))
            newBtn.Visible = false
        end)
    end
    list:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        if newBtn.Visible and atBottom() then newBtn.Visible = false end
    end)
    newBtn.MouseButton1Click:Connect(scrollBottom)

    local showCtxMenu = nil  -- assigned later by owner-context-menu block

    local function addRow(m)
        emptyLabel.Visible = false
        local mine = m.uid == myId
        rowCounter += 1
        local row = new("Frame", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), LayoutOrder = rowCounter }, list)
        local nameColor = mine and S.accent or colorFor(m.uid)

        -- Roblox profile thumbnail (cached by Roblox; keep a letter fallback if it fails).
        local avatar = new("ImageLabel", {
            Size = UDim2.fromOffset(26, 26), AnchorPoint = Vector2.new(mine and 1 or 0, 0),
            Position = UDim2.new(mine and 1 or 0, 0, 0, 0), BackgroundTransparency = 0,
            BackgroundColor3 = nameColor, BorderSizePixel = 0, Image = "",
            ScaleType = Enum.ScaleType.Crop,
        }, row)
        round(avatar, 13)
        if isOwner and not mine then
            local ctxHit = new("TextButton", {
                BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
                Text = "", ZIndex = avatar.ZIndex + 2, BorderSizePixel = 0,
            }, avatar)
            ctxHit.MouseButton1Click:Connect(function()
                if showCtxMenu then showCtxMenu(m.uid, m.name, avatar.AbsolutePosition) end
            end)
        end
        local avatarFallback = label({ Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
            Weight = Enum.FontWeight.Bold, TextSize = 12, TextColor3 = Color3.fromRGB(20, 20, 20),
            Text = (m.name:sub(1, 1)):upper(), ZIndex = 2 }, avatar)
        task.spawn(function()
            local uid = tonumber(m.uid)
            if not uid or not avatar.Parent then return end
            local ok, imageUrl, ready = pcall(function()
                return Players:GetUserThumbnailAsync(uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
            end)
            if ok and avatar.Parent and type(imageUrl) == "string" and imageUrl ~= "" then
                avatar.Image = imageUrl
                avatarFallback.Visible = false
            end
        end)

        local body = new("Frame", {
            BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, AnchorPoint = Vector2.new(mine and 1 or 0, 0),
            Position = UDim2.new(mine and 1 or 0, mine and -34 or 34, 0, 0), Size = UDim2.new(1, -42, 0, 0),
        }, row)
        new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2), HorizontalAlignment = mine and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left }, body)

        local header = new("Frame", { LayoutOrder = 1, BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(1, 0, 0, 16) }, body)
        new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6) }, header)
        label({ LayoutOrder = 1, AutomaticSize = Enum.AutomaticSize.XY, Weight = Enum.FontWeight.SemiBold,
            TextSize = 11, TextColor3 = nameColor, Text = m.name }, header)
        local ownerNames = { nymnmz = true, lucas_adm145t = true }
        if ownerNames[tostring(m.name):lower()] then
            local ownerTag = label({ LayoutOrder = 2, AutomaticSize = Enum.AutomaticSize.XY,
                BackgroundColor3 = Color3.fromRGB(220, 105, 35), TextColor3 = Color3.fromRGB(255, 255, 255),
                Weight = Enum.FontWeight.Bold, TextSize = 9, Text = "OWNER" }, header)
            round(ownerTag, 4)
            pad(ownerTag, 5, 1, 5, 1)
        end
        label({ LayoutOrder = 3, AutomaticSize = Enum.AutomaticSize.XY, TextSize = 10,
            TextColor3 = S.sub, Text = os.date("%H:%M", m.t) }, header)

        local mentioned = (not mine) and m.text:lower():find("@" .. myName:lower(), 1, true) ~= nil
        local bubble = label({
            LayoutOrder = 2, AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundTransparency = mine and 0.15 or S.surfaceT, BackgroundColor3 = mine and S.accent or S.surface,
            TextColor3 = mine and Color3.fromRGB(15, 15, 15) or S.text,
            TextWrapped = true, RichText = false, TextXAlignment = Enum.TextXAlignment.Left, Text = m.text,
        }, body)
        round(bubble, 6)
        pad(bubble, 10, 6, 10, 6)
        new("UISizeConstraint", { MaxSize = Vector2.new(250, math.huge) }, bubble)
        if mentioned then new("UIStroke", { Color = S.gold, Thickness = 1.5 }, bubble)
        elseif not mine then outline(bubble) end
        return row
    end

    clearRows = function()
        for _, r in ipairs(rows) do r:Destroy() end
        table.clear(rows)
        emptyLabel.Visible = true
    end

    local function renderActive()
        clearRows()
        for _, m in ipairs(state.ch[state.active].log) do rows[#rows + 1] = addRow(m) end
        scrollBottom()
    end

    local function pushMessage(chId, m)
        if m.uid ~= myId and (isUserMuted(m.uid) or isUserBanned(m.uid)) then return end
        local ch = state.ch[chId]
        ch.log[#ch.log + 1] = m
        while #ch.log > MAX_LINES do table.remove(ch.log, 1) end
        if chId == state.active then
            local wasBottom = atBottom()
            rows[#rows + 1] = addRow(m)
            while #rows > MAX_LINES do
                local r = table.remove(rows, 1)
                if r then r:Destroy() end
            end
            if wasBottom or m.uid == myId then scrollBottom() else newBtn.Visible = true end
        end
    end

    ------------------------------------------------------------------
    -- Owner context menu (avatar click → mute / ban)
    ------------------------------------------------------------------
    if isOwner then
        local ctxTargetUid, ctxTargetName = nil, nil

        local ctxMenu = new("Frame", {
            Name = "HXCtxMenu",
            BackgroundColor3 = Color3.fromRGB(18, 18, 26),
            BackgroundTransparency = 0.04,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(154, 138),
            Visible = false,
            ZIndex = 30,
        }, main)
        round(ctxMenu, 7)
        outline(ctxMenu, 0.45)
        pad(ctxMenu, 7, 7, 7, 7)
        new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5) }, ctxMenu)

        -- name header
        local ctxNameLabel = label({
            LayoutOrder = 1,
            Size = UDim2.new(1, 0, 0, 14),
            Weight = Enum.FontWeight.Bold,
            TextSize = 11,
            TextColor3 = S.accent,
            Text = "",
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 31,
        }, ctxMenu)

        -- helper: build a sub-row with a prefix label and a frame of buttons
        local function makeActionRow(order, prefix, btnDefs, btnBg, btnTc, callback)
            local row = new("Frame", { LayoutOrder = order, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), ZIndex = 31 }, ctxMenu)
            label({ Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.fromOffset(34, 14), Text = prefix, TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = S.sub, ZIndex = 31 }, row)
            local bf = new("Frame", { Position = UDim2.new(0, 36, 0, 0), Size = UDim2.new(1, -36, 1, 0), BackgroundTransparency = 1, ZIndex = 31 }, row)
            new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3), VerticalAlignment = Enum.VerticalAlignment.Center }, bf)
            for i, def in ipairs(btnDefs) do
                local b = new("TextButton", {
                    LayoutOrder = i, AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2.new(0, 0, 0.88, 0), BackgroundColor3 = btnBg,
                    BorderSizePixel = 0, AutoButtonColor = true, TextSize = 10,
                    TextColor3 = btnTc, Text = def[1], ZIndex = 31,
                }, bf)
                round(b, 4); pad(b, 5, 0, 5, 0)
                local secs = def[2]
                b.MouseButton1Click:Connect(function()
                    callback(secs, def[1])
                    ctxMenu.Visible = false
                end)
            end
        end

        makeActionRow(2, "Mute:", {
            { "5m",  300 }, { "30m", 1800 }, { "1h", 3600 },
        }, Color3.fromRGB(42, 76, 128), Color3.fromRGB(175, 210, 255),
        function(secs, label_)
            if ctxTargetUid then
                mutedUntil[ctxTargetUid] = os.time() + secs
                Fluent:Notify({ Title = "Chat", Content = (ctxTargetName or "User") .. " muted for " .. label_, Duration = 3 })
            end
        end)

        makeActionRow(3, "Ban:", {
            { "1h", 3600 }, { "24h", 86400 }, { "Perm", -1 },
        }, Color3.fromRGB(100, 28, 38), Color3.fromRGB(255, 175, 175),
        function(secs, label_)
            if ctxTargetUid then
                bannedUntil[ctxTargetUid] = (secs == -1) and -1 or (os.time() + secs)
                Fluent:Notify({ Title = "Chat", Content = (ctxTargetName or "User") .. " banned for " .. label_, Duration = 3 })
            end
        end)

        -- close button
        local closeFrame = new("Frame", { LayoutOrder = 4, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), ZIndex = 31 }, ctxMenu)
        local closeBtn = new("TextButton", { Size = UDim2.new(1, 0, 1, 0), ZIndex = 31,
            BackgroundColor3 = Color3.fromRGB(38, 38, 50), BorderSizePixel = 0,
            AutoButtonColor = true, TextSize = 10, TextColor3 = S.sub, Text = "✕  Close" }, closeFrame)
        round(closeBtn, 4)
        closeBtn.MouseButton1Click:Connect(function() ctxMenu.Visible = false end)

        -- dismiss on click outside
        main.InputBegan:Connect(function(inp)
            if ctxMenu.Visible and inp.UserInputType == Enum.UserInputType.MouseButton1 then
                local mp = inp.Position
                local cp = ctxMenu.AbsolutePosition
                local cs = ctxMenu.AbsoluteSize
                if mp.X < cp.X or mp.X > cp.X + cs.X or mp.Y < cp.Y or mp.Y > cp.Y + cs.Y then
                    ctxMenu.Visible = false
                end
            end
        end)

        showCtxMenu = function(uid, name, absPos)
            ctxTargetUid  = uid
            ctxTargetName = name
            ctxNameLabel.Text = "@" .. name
            local relX = absPos.X - main.AbsolutePosition.X
            local relY = absPos.Y - main.AbsolutePosition.Y + 30
            local mw, mh = 154, 138
            ctxMenu.Position = UDim2.fromOffset(
                math.clamp(relX, 0, math.max(0, main.AbsoluteSize.X - mw)),
                math.clamp(relY, 0, math.max(0, main.AbsoluteSize.Y - mh))
            )
            ctxMenu.Visible = true
        end
    end

    ------------------------------------------------------------------
    -- Canais (abas verticais com rolagem)
    ------------------------------------------------------------------
    local function refreshChannels() end

    local function setActive(id)
        state.active = id
        state.ch[id].unread, state.ch[id].mention = 0, false
        for _, c in ipairs(CHANNELS) do
            if c.id == id then
            end
        end
        refreshChannels()
        renderActive()
    end

    ------------------------------------------------------------------
    -- Encaixe na aba (ou janela simples se o menu nao deixar embutir)
    ------------------------------------------------------------------
    local floatGui
    if host then
        for _, ch in ipairs(host:GetChildren()) do
            if ch:IsA("TextLabel") or ch:IsA("TextButton") then ch.Visible = false end
        end
        pcall(function()
            host.AutomaticSize = Enum.AutomaticSize.None
            host.Size = UDim2.new(1, 0, 0, CHAT_HEIGHT)
        end)
        root.Parent = host
    else
        floatGui = new("ScreenGui", { Name = "HX_ChatWindow", ResetOnSpawn = false, DisplayOrder = 40 })
        local ok = pcall(function() floatGui.Parent = (type(gethui) == "function" and gethui()) or game:GetService("CoreGui") end)
        if not ok then floatGui.Parent = lp:WaitForChild("PlayerGui") end
        root.AnchorPoint = Vector2.new(0.5, 0.5)
        root.Position = UDim2.fromScale(0.5, 0.5)
        root.Size = UDim2.fromOffset(500, 360)
        root.Visible = false
        root.Parent = floatGui
        ChatTabObj:AddToggle("HXChatWindowToggle", {
            Title = "Show chat",
            Default = false,
            Callback = function(v) root.Visible = v and true or false end,
        })
    end

    ------------------------------------------------------------------
    -- Rede
    ------------------------------------------------------------------
    local function refreshUsers()
        local now, n = os.time(), 0
        state.users[myId] = { name = myName, t = now }
        for uid, u in pairs(state.users) do
            if now - u.t <= ONLINE_WINDOW then n += 1 else state.users[uid] = nil end
        end
        state.online = n
    end

    local function setOnlineUI()
        local n = state.online
        _G.__HXOnlineCount = state.connected and n or nil
        if type(_G.__HXSetOnline) == "function" then pcall(_G.__HXSetOnline, state.connected and n or nil) end
        statusDot.BackgroundColor3 = state.connected and S.green or S.sub
        statusText.Text = state.connected and (n .. " online") or "Offline"
    end

    -- Formato: P|<uid>|<nome> (presenca)  /  M|<uid>|<nome>|<texto> (mensagem)
    local function handleEvent(ev)
        if type(ev) ~= "table" or ev.event ~= "message" or type(ev.message) ~= "string" or type(ev.id) ~= "string" then return end
        if state.seenIds[ev.id] then return end
        state.seenIds[ev.id] = true
        state.seenOrder[#state.seenOrder + 1] = ev.id
        if #state.seenOrder > 800 then state.seenIds[table.remove(state.seenOrder, 1)] = nil end

        local t = tonumber(ev.time) or os.time()
        if not state.maxTs or t > state.maxTs then state.maxTs = t end

        local kind, uid, rest = ev.message:match("^(%u)|(%d+)|(.*)$")
        if not kind or #uid > 20 then return end

        if ev.topic == presenceTopic and kind == "P" then
            local name = clean(rest, 24)
            if name ~= "" then
                local u = state.users[uid]
                if not u or t >= u.t then state.users[uid] = { name = name, t = t } end
            end
            return
        end

        local chId = topicToChannel[ev.topic]

        if chId and kind == "X" then
            local name = clean(rest, 24)
            if OWNER_NAMES[name:lower()] then
                if state.ch[chId] then table.clear(state.ch[chId].log) end
                if chId == state.active then clearRows() end
            end
            return
        end

        if chId and kind == "M" then
            local name, text = rest:match("^([^|]*)|(.*)$")
            name, text = clean(name, 24), clean(text, MAX_TEXT)
            if name == "" or text == "" then return end
            if uid == myId then
                for i, p in ipairs(state.pending) do
                    if p.ch == chId and p.text == text then
                        table.remove(state.pending, i)
                        return -- ja foi mostrada ao enviar
                    end
                end
            end
            text = safeText(text)
            pushMessage(chId, { uid = uid, name = name, text = text, t = t })
            if state.loaded and chId ~= state.active and uid ~= myId then
                local ch = state.ch[chId]
                ch.unread += 1
                if text:lower():find("@" .. myName:lower(), 1, true) then ch.mention = true end
                refreshChannels()
            end
        end
    end

    local function poll()
        local since = state.maxTs and tostring(state.maxTs - 1) or "30m"
        local res = http("GET", NTFY .. table.concat(topics, ",") .. "/json?poll=1&since=" .. since)
        if res and res.StatusCode == 200 then
            state.failures = 0
            state.connected = true
            for line in tostring(res.Body or ""):gmatch("[^\n]+") do
                local ok, ev = pcall(HttpService.JSONDecode, HttpService, line)
                if ok then handleEvent(ev) end
            end
            state.loaded = true
            refreshUsers()
            setOnlineUI()
            return
        end
        state.failures += 1
        if res and res.StatusCode == 429 then state.backoff = 20 end
        if state.failures >= 3 then
            state.connected = false
            setOnlineUI()
        end
    end

    local function sendMessage()
        local text = clean(box.Text, MAX_TEXT)
        if text == "" then return end
        if os.clock() - state.lastSent < 2 then
            Fluent:Notify({ Title = "Chat", Content = "Slow down a little", Duration = 2 })
            return
        end
        state.lastSent = os.clock()
        box.Text = ""
        local chId = state.active
        state.pending[#state.pending + 1] = { ch = chId, text = text }
        pushMessage(chId, { uid = myId, name = myName, text = text, t = os.time() })
        task.spawn(function()
            if not publish(PREFIX .. "-" .. chId, "M|" .. myId .. "|" .. myName .. "|" .. text) then
                Fluent:Notify({ Title = "Chat", Content = "Could not send your message", Duration = 3 })
            end
        end)
    end

    sendBtn.MouseButton1Click:Connect(sendMessage)
    box.FocusLost:Connect(function(enter) if enter then sendMessage() end end)

    setActive(state.active)
    refreshUsers()

    task.spawn(function()
        local lastBeat = 0
        while alive() do
            if os.clock() - lastBeat >= HEARTBEAT_EVERY then
                lastBeat = os.clock()
                publish(presenceTopic, "P|" .. myId .. "|" .. myName)
            end
            pcall(poll)
            local wait = POLL_EVERY
            if state.backoff > 0 then wait = state.backoff; state.backoff = 0
            elseif state.failures >= 3 then wait = 20 end
            task.wait(wait)
        end
        if floatGui then floatGui:Destroy() end
        root:Destroy()
    end)
    end)
    if not okChat then warn("[Hyperion] Chat failed to load: " .. tostring(errChat)) end
end)()

-- === HYPERION UI TOOLS: auto-fit por resolucao, rolagem e tema Halloween ===
pcall(function()
    local RunService = game:GetService("RunService")
    local Root = Window.Root
    if typeof(Root) ~= "Instance" then return end
    local gui = (typeof(Fluent.GUI) == "Instance" and Fluent.GUI) or Root:FindFirstAncestorOfClass("ScreenGui")
    if not gui then return end

    local cfg = {
        userScale = 1, autoFit = true,
        hw = false, hwAccent = Color3.fromRGB(255, 120, 20), hwTint = 25, hwDeco = true, hwBats = true,
    }

    ------------------------------------------------------------------
    -- 1) Tamanho da UI conforme a resolucao (UIScale no Root)
    ------------------------------------------------------------------
    local uiScale = Instance.new("UIScale")
    uiScale.Name = "HX_UIScale"
    uiScale.Parent = Root

    local function applyScale()
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
        local sz = Window.Size
        local bw = (typeof(sz) == "UDim2" and sz.X.Offset > 0) and sz.X.Offset or 580
        local bh = (typeof(sz) == "UDim2" and sz.Y.Offset > 0) and sz.Y.Offset or 460
        local fit = 1
        if cfg.autoFit then fit = math.min(1, (vp.X * 0.96) / bw, (vp.Y * 0.94) / bh) end
        uiScale.Scale = math.clamp(cfg.userScale * fit, 0.5, 1.5)
    end
    local function watchCamera()
        local cam = workspace.CurrentCamera
        if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(applyScale) end
    end
    watchCamera()
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() watchCamera(); applyScale() end)
    applyScale()

    ------------------------------------------------------------------
    -- 2) Rolagem de cima para baixo em tudo (abas da esquerda e paginas)
    ------------------------------------------------------------------
    local hooked = setmetatable({}, { __mode = "k" })
    local function fixScroll(sf)
        if hooked[sf] or sf.Name:sub(1, 2) == "HX" then return end
        hooked[sf] = true
        sf.ScrollingEnabled = true
        sf.Active = true
        sf.ScrollingDirection = Enum.ScrollingDirection.Y
        sf.ElasticBehavior = Enum.ElasticBehavior.Never
        if sf.ScrollBarThickness < 3 then sf.ScrollBarThickness = 3 end
        if sf.ScrollBarImageTransparency > 0.5 then sf.ScrollBarImageTransparency = 0.5 end
        local layout = sf:FindFirstChildOfClass("UIListLayout")
        if layout and sf.AutomaticCanvasSize == Enum.AutomaticSize.None then
            local function upd() sf.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8) end
            layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(upd)
            upd()
        end
    end
    local function scanScroll()
        for _, d in ipairs(Root:GetDescendants()) do
            if d:IsA("ScrollingFrame") then pcall(fixScroll, d) end
        end
    end
    task.spawn(function()
        for _, t in ipairs({ 0.5, 1.5, 4 }) do task.wait(t); pcall(scanScroll) end
        while Root.Parent do task.wait(4); pcall(scanScroll) end
    end)

    ------------------------------------------------------------------
    -- 3) Tema Halloween personalizavel
    ------------------------------------------------------------------
    local THEME_ACCENTS = {
        Dark = Color3.fromRGB(96, 205, 255), Darker = Color3.fromRGB(72, 138, 182), Light = Color3.fromRGB(0, 103, 192),
        Aqua = Color3.fromRGB(60, 165, 165), Amethyst = Color3.fromRGB(85, 57, 139), Rose = Color3.fromRGB(180, 55, 90),
    }
    local COLOR_PROPS = { "BackgroundColor3", "TextColor3", "ImageColor3", "Color", "ScrollBarImageColor3" }
    local tracked = {}   -- inst -> { prop = corOriginal }
    local fx = {}        -- tint, layer, stroke, deco, bats
    local batConn
    local origTitle

    local function near(a, b) return math.abs(a.R - b.R) + math.abs(a.G - b.G) + math.abs(a.B - b.B) < 0.07 end

    local function recolor()
        local old = THEME_ACCENTS[Fluent.Theme] or THEME_ACCENTS.Dark
        for _, d in ipairs(gui:GetDescendants()) do
            if d.Name:sub(1, 5) ~= "HX_HW" and not (fx.layer and d:IsDescendantOf(fx.layer)) then
                for _, prop in ipairs(COLOR_PROPS) do
                    local ok, v = pcall(function() return d[prop] end)
                    if ok and typeof(v) == "Color3" and near(v, old) then
                        tracked[d] = tracked[d] or {}
                        if tracked[d][prop] == nil then tracked[d][prop] = v end
                        pcall(function() d[prop] = cfg.hwAccent end)
                    end
                end
            end
        end
        for inst, props in pairs(tracked) do
            if inst.Parent then
                for prop in pairs(props) do pcall(function() inst[prop] = cfg.hwAccent end) end
            else
                tracked[inst] = nil
            end
        end
        if fx.stroke then fx.stroke.Color = cfg.hwAccent end
    end

    local function restoreColors()
        for inst, props in pairs(tracked) do
            if inst.Parent then
                for prop, v in pairs(props) do pcall(function() inst[prop] = v end) end
            end
        end
        table.clear(tracked)
    end

    local function copyCorner(frame)
        local c = Root:FindFirstChildOfClass("UICorner")
        if c then c:Clone().Parent = frame end
    end

    local function updateTint()
        if not fx.tint then return end
        fx.tint.BackgroundTransparency = 1 - math.clamp(cfg.hwTint, 0, 60) / 100 * 0.5
    end

    local function buildFx()
        if fx.layer then return end
        fx.tint = Instance.new("Frame")
        fx.tint.Name = "HX_HW_Tint"
        fx.tint.Size = UDim2.fromScale(1, 1)
        fx.tint.BackgroundColor3 = Color3.new(1, 1, 1)
        fx.tint.BorderSizePixel = 0
        fx.tint.Active = false
        fx.tint.ZIndex = 50
        local g = Instance.new("UIGradient")
        g.Color = ColorSequence.new(Color3.fromRGB(255, 110, 20), Color3.fromRGB(80, 0, 130))
        g.Rotation = 90
        g.Parent = fx.tint
        copyCorner(fx.tint)
        fx.tint.Parent = Root

        fx.stroke = Instance.new("UIStroke")
        fx.stroke.Name = "HX_HW_Stroke"
        fx.stroke.Thickness = 2
        fx.stroke.Color = cfg.hwAccent
        fx.stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        fx.stroke.Parent = Root

        fx.layer = Instance.new("Frame")
        fx.layer.Name = "HX_HW_Layer"
        fx.layer.Size = UDim2.fromScale(1, 1)
        fx.layer.BackgroundTransparency = 1
        fx.layer.ClipsDescendants = true
        fx.layer.Active = false
        fx.layer.ZIndex = 60
        copyCorner(fx.layer)
        fx.layer.Parent = Root

        updateTint()
    end

    local function destroyFx()
        if batConn then batConn:Disconnect(); batConn = nil end
        for _, k in ipairs({ "tint", "stroke", "layer" }) do
            if fx[k] then fx[k]:Destroy() end
            fx[k] = nil
        end
        fx.deco, fx.bats = nil, nil
    end

    local function emoji(parent, text, size, props)
        local l = Instance.new("TextLabel")
        l.Name = "HX_HW_Emoji"
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextSize = size
        l.Font = Enum.Font.Gotham
        l.Active = false
        l.ZIndex = 61
        for k, v in pairs(props or {}) do l[k] = v end
        l.Parent = parent
        return l
    end

    local function updateDeco()
        if fx.deco then fx.deco:Destroy(); fx.deco = nil end
        if not (cfg.hw and cfg.hwDeco and fx.layer) then return end
        local f = Instance.new("Frame")
        f.Name = "HX_HW_Deco"
        f.BackgroundTransparency = 1
        f.Size = UDim2.fromScale(1, 1)
        f.Active = false
        f.ZIndex = 61
        f.Parent = fx.layer
        emoji(f, "🕸", 40, { Position = UDim2.new(0, -4, 0, -6), Size = UDim2.fromOffset(44, 44), TextTransparency = 0.25 })
        emoji(f, "🎃", 30, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -8, 1, -6), Size = UDim2.fromOffset(34, 34) })
        emoji(f, "👻", 24, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -44, 1, -8), Size = UDim2.fromOffset(28, 28), TextTransparency = 0.2 })
        fx.deco = f
    end

    local function updateBats()
        if batConn then batConn:Disconnect(); batConn = nil end
        if fx.bats then fx.bats:Destroy(); fx.bats = nil end
        if not (cfg.hw and cfg.hwBats and fx.layer) then return end
        local holder = Instance.new("Frame")
        holder.Name = "HX_HW_Bats"
        holder.BackgroundTransparency = 1
        holder.Size = UDim2.fromScale(1, 1)
        holder.Active = false
        holder.ZIndex = 61
        holder.Parent = fx.layer
        fx.bats = holder
        local chars, bats = { "🦇", "🦇", "🦇", "👻", "🦇", "🎃" }, {}
        for i, ch in ipairs(chars) do
            bats[i] = {
                label = emoji(holder, ch, 18 + (i % 3) * 4, { Size = UDim2.fromOffset(28, 28), TextTransparency = 0.3 }),
                x = math.random(), y = 0.1 + math.random() * 0.7,
                speed = 0.02 + math.random() * 0.03, amp = 0.02 + math.random() * 0.03, phase = math.random() * 6,
            }
        end
        batConn = RunService.Heartbeat:Connect(function(dt)
            if not Root.Visible then return end
            local t = os.clock()
            for _, b in ipairs(bats) do
                b.x = (b.x + b.speed * dt) % 1.1
                b.label.Position = UDim2.new(b.x - 0.05, 0, b.y + math.sin(t * 1.5 + b.phase) * b.amp, 0)
            end
        end)
    end

    local function updateTitle(on)
        for _, d in ipairs(gui:GetDescendants()) do
            if d:IsA("TextLabel") and d.Text:find("^Hyperion Hub X") then
                if on then
                    origTitle = origTitle or d.Text
                    if not d.Text:find("🎃") then d.Text = d.Text .. " 🎃" end
                elseif origTitle then
                    d.Text = origTitle
                end
                break
            end
        end
        if not on then origTitle = nil end
    end

    local function applyHalloween()
        if cfg.hw then
            buildFx()
            updateTint()
            updateDeco()
            updateBats()
            pcall(recolor)
            pcall(updateTitle, true)
        else
            pcall(updateTitle, false)
            destroyFx()
            restoreColors()
        end
    end

    task.spawn(function()
        while Root.Parent do
            task.wait(2.5)
            if cfg.hw then pcall(recolor) end
        end
    end)

    ------------------------------------------------------------------
    -- Controles na aba Settings
    ------------------------------------------------------------------
    SettingsTab:AddParagraph({ Title = "Interface size", Content = "Fits the menu to your screen. Changes apply instantly." })
    SettingsTab:AddToggle("HXAutoFit", {
        Title = "Auto fit to screen", Description = "Shrinks the menu if your resolution is small", Default = true,
        Callback = function(v) cfg.autoFit = v and true or false; applyScale() end,
    })
    SettingsTab:AddSlider("HXUIScale", {
        Title = "UI scale", Description = "Manual menu size (percent)", Default = 100, Min = 50, Max = 130, Rounding = 0,
        Callback = function(v) cfg.userScale = (tonumber(v) or 100) / 100; applyScale() end,
    })

    SettingsTab:AddParagraph({ Title = "Halloween UI", Content = "Custom spooky theme for the menu." })
    SettingsTab:AddToggle("HXHalloween", {
        Title = "Halloween theme", Description = "Orange accent, purple glow and decorations", Default = false,
        Callback = function(v) cfg.hw = v and true or false; applyHalloween() end,
    })
    SettingsTab:AddColorpicker("HXHalloweenAccent", {
        Title = "Halloween accent", Description = "Main accent color", Default = cfg.hwAccent,
        Callback = function(c)
            if typeof(c) == "Color3" then
                cfg.hwAccent = c
                if cfg.hw then pcall(recolor) end
            end
        end,
    })
    SettingsTab:AddSlider("HXHalloweenTint", {
        Title = "Glow strength", Description = "Purple/orange tint over the menu", Default = 25, Min = 0, Max = 60, Rounding = 0,
        Callback = function(v) cfg.hwTint = tonumber(v) or 25; updateTint() end,
    })
    SettingsTab:AddToggle("HXHalloweenDeco", {
        Title = "Decorations", Description = "Cobweb, pumpkin and ghost", Default = true,
        Callback = function(v) cfg.hwDeco = v and true or false; updateDeco() end,
    })
    SettingsTab:AddToggle("HXHalloweenBats", {
        Title = "Floating bats", Description = "Bats and ghosts drifting over the menu", Default = true,
        Callback = function(v) cfg.hwBats = v and true or false; updateBats() end,
    })
end)


-- === INFO TAB ===
do
    InfoTab:AddParagraph({
        Title = "Owner Socials",
        Content = "Click the buttons below to visit the owners' TikTok pages.",
    })

    InfoTab:AddButton({
        Title = "Nymmz Socials",
        Description = "Visit Nymmz on TikTok",
        Callback = function()
            if setclipboard then
                setclipboard("https://www.tiktok.com/@nymmz?_r=1&_t=ZP-9AFvn5PBmCU")
                Fluent:Notify({ Title = "Nymmz Socials", Content = "Link copied to clipboard!", Duration = 5 })
            end
            pcall(function()
                if syn and syn.open_url then
                    syn.open_url("https://www.tiktok.com/@nymmz?_r=1&_t=ZP-9AFvn5PBmCU")
                elseif open_url then
                    open_url("https://www.tiktok.com/@nymmz?_r=1&_t=ZP-9AFvn5PBmCU")
                end
            end)
        end,
    })

    InfoTab:AddButton({
        Title = "Lucaswyrms Socials",
        Description = "Visit Lucaswyrm on TikTok",
        Callback = function()
            if setclipboard then
                setclipboard("https://www.tiktok.com/@lucaswyrm?_r=1&_t=ZP-9AFvnKNfcPG")
                Fluent:Notify({ Title = "Lucaswyrms Socials", Content = "Link copied to clipboard!", Duration = 5 })
            end
            pcall(function()
                if syn and syn.open_url then
                    syn.open_url("https://www.tiktok.com/@lucaswyrm?_r=1&_t=ZP-9AFvnKNfcPG")
                elseif open_url then
                    open_url("https://www.tiktok.com/@lucaswyrm?_r=1&_t=ZP-9AFvnKNfcPG")
                end
            end)
        end,
    })
end

local headlessEnabled = false
local korbloxRightEnabled = false
local korbloxLeftEnabled = false
local fullbrightEnabled = false
local KorbloxRightToggleObject = nil
local KorbloxLeftToggleObject = nil
 
local NormalLightingSettings = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogStart = Lighting.FogStart,
    FogColor = Lighting.FogColor,
}
 
local savedAtmosphere = nil
local savedSky = nil
 
local function clearAtmosphereAndSky()
    local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmo then
        if atmo:GetAttribute("WeatherCreated") then
            atmo:Destroy()
        else
            savedAtmosphere = atmo:Clone()
            savedAtmosphere.Parent = nil
        end
    end
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if sky then
        if sky:GetAttribute("WeatherCreated") then
            sky:Destroy()
        else
            savedSky = sky:Clone()
            savedSky.Parent = nil
        end
    end
end
 
local function restoreAtmosphereAndSky()
    if savedAtmosphere then savedAtmosphere.Parent = Lighting end
    if savedSky then savedSky.Parent = Lighting end
end
 
local function applyFullbright()
    clearAtmosphereAndSky()
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    Lighting.FogEnd = 100000
    Lighting.FogStart = 0
    Lighting.GlobalShadows = false
    Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    Lighting.FogColor = Color3.fromRGB(255, 255, 255)
end
 
local function restoreFullbright()
    restoreAtmosphereAndSky()
    Lighting.Brightness = NormalLightingSettings.Brightness
    Lighting.ClockTime = NormalLightingSettings.ClockTime
    Lighting.FogEnd = NormalLightingSettings.FogEnd
    Lighting.GlobalShadows = NormalLightingSettings.GlobalShadows
    Lighting.Ambient = NormalLightingSettings.Ambient
    Lighting.OutdoorAmbient = NormalLightingSettings.OutdoorAmbient
    Lighting.FogStart = NormalLightingSettings.FogStart or 0
    Lighting.FogColor = NormalLightingSettings.FogColor or Color3.fromRGB(255, 255, 255)
end
 
local function findFaceDecal(head)
    return head:FindFirstChild("face")
end
 
local headTransparencyLocks = setmetatable({}, { __mode = "k" }) -- [Instance] = {desired = number, conn = RBXScriptConnection}
 
local function lockTransparency(inst, desired)
    local existing = headTransparencyLocks[inst]
    if existing then
        existing.conn:Disconnect()
    end
 
    local state = { desired = desired, guarding = false }
 
    local conn = inst:GetPropertyChangedSignal("Transparency"):Connect(function()
        if state.guarding then return end
        if inst.Transparency ~= state.desired then
            state.guarding = true
            inst.Transparency = state.desired
            state.guarding = false
        end
    end)
 
    state.conn = conn
    headTransparencyLocks[inst] = state
 
    if inst.Transparency ~= desired then
        inst.Transparency = desired
    end
end
 
local function unlockTransparency(inst)
    local existing = headTransparencyLocks[inst]
    if existing then
        existing.conn:Disconnect()
        headTransparencyLocks[inst] = nil
    end
end
 
local function applyKorbloxRight(character, enable)
    if not character then return end
 
    if enable then
        local oldRight = character:FindFirstChild("Korblox Deathspeaker v Right Leg")
        if oldRight then oldRight:Destroy() end
        local right = character:FindFirstChild("Korblox Deathspeaker Right Leg")
        if right then right:Destroy() end
 
        right = Instance.new("CharacterMesh")
        right.Name = "Korblox Deathspeaker Right Leg"
        right.OverlayTextureId = 101851254
        right.MeshId = 101851696
        right.BodyPart = Enum.BodyPart.RightLeg
        right.Parent = character
    else
        local right = character:FindFirstChild("Korblox Deathspeaker Right Leg")
        if right then right:Destroy() end
        local oldRight = character:FindFirstChild("Korblox Deathspeaker v Right Leg")
        if oldRight then oldRight:Destroy() end
    end
end
 
local function applyKorbloxLeft(character, enable)
    if not character then return end
 
    if enable then
        local oldLeft = character:FindFirstChild("Korblox Deathspeaker v Left Leg")
        if oldLeft then oldLeft:Destroy() end
        local left = character:FindFirstChild("Korblox Deathspeaker Left Leg")
        if left then left:Destroy() end
 
        left = Instance.new("CharacterMesh")
        left.Name = "Korblox Deathspeaker Left Leg"
        left.OverlayTextureId = 101851254
        left.MeshId = 101851582
        left.BodyPart = Enum.BodyPart.LeftLeg
        left.Parent = character
    else
        local left = character:FindFirstChild("Korblox Deathspeaker Left Leg")
        if left then left:Destroy() end
        local oldLeft = character:FindFirstChild("Korblox Deathspeaker v Left Leg")
        if oldLeft then oldLeft:Destroy() end
    end
end
 
local function applyKorblox(character)
    applyKorbloxRight(character, korbloxRightEnabled)
    applyKorbloxLeft(character, korbloxLeftEnabled)
end
 
local function applyHeadless(character, enable)
    if not character then return end
    local head = character:WaitForChild("Head", 5)
    if not head then return end
 
    if enable then
        lockTransparency(head, 1)
        local face = findFaceDecal(head)
        if face then
            lockTransparency(face, 1)
        end
    else
        unlockTransparency(head)
        head.Transparency = 0
        local face = findFaceDecal(head)
        if face then
            unlockTransparency(face)
            face.Transparency = 0
        end
    end
end
 
local watchdogConns = setmetatable({}, { __mode = "k" }) -- [character] = { [key] = conn }

local function clearWatchdogFor(character)
    local conns = watchdogConns[character]
    if not conns then return end
    for _, conn in pairs(conns) do
        conn:Disconnect()
    end
    watchdogConns[character] = nil
end

local function setWatchdogConn(character, key, conn)
    local conns = watchdogConns[character]
    if not conns then
        conns = {}
        watchdogConns[character] = conns
    end
    if conns[key] then
        conns[key]:Disconnect()
    end
    conns[key] = conn
end

local function watchKorbloxRight(character)
    local conn = character.ChildRemoved:Connect(function(child)
        if child.Name ~= "Korblox Deathspeaker Right Leg" then return end
        if not character.Parent then return end
        if korbloxRightEnabled then
            applyKorbloxRight(character, true)
        end
    end)
    setWatchdogConn(character, "KorbloxRight", conn)
end

local function watchKorbloxLeft(character)
    local conn = character.ChildRemoved:Connect(function(child)
        if child.Name ~= "Korblox Deathspeaker Left Leg" then return end
        if not character.Parent then return end
        if korbloxLeftEnabled then
            applyKorbloxLeft(character, true)
        end
    end)
    setWatchdogConn(character, "KorbloxLeft", conn)
end

local function watchHeadlessHead(character)
    local conn = character.ChildRemoved:Connect(function(child)
        if child.Name ~= "Head" then return end
        if not character.Parent then return end
        if not headlessEnabled then return end
        task.defer(function()
            local newHead = character:WaitForChild("Head", 5)
            if newHead and character.Parent then
                applyHeadless(character, true)
            end
        end)
    end)
    setWatchdogConn(character, "HeadlessHead", conn)
end

local function armWatchdog(character)
    clearWatchdogFor(character)
    watchKorbloxRight(character)
    watchKorbloxLeft(character)
    watchHeadlessHead(character)
end

local function applyToCharacter(character)
    applyKorblox(character)
    applyHeadless(character, headlessEnabled)
    armWatchdog(character)
end
 
local function getActiveRigsFolders()
    local result = {}
    for _, child in ipairs(workspace:GetChildren()) do
        if child.Name == "Rigs" and #child:GetChildren() > 0 then
            table.insert(result, child)
        end
    end
    return result
end
 
local function applyToOwnRigInFolder(folder)
    if not folder then return end
    local rig = folder:FindFirstChild(player.Name)
    if rig then
        applyKorblox(rig)
        applyHeadless(rig, headlessEnabled)
        armWatchdog(rig)
    end
end
 
local function applyToAllActiveRigs()
    for _, rigsFolder in ipairs(getActiveRigsFolders()) do
        applyToOwnRigInFolder(rigsFolder)
    end
end
 
if _G.HKCharConn then
    _G.HKCharConn:Disconnect()
    _G.HKCharConn = nil
end
 
_G.HKCharConn = player.CharacterAdded:Connect(function(character)
    task.wait(0.01)
    applyToCharacter(character)
    task.defer(applyToAllActiveRigs)
end)

-- FARM TAB
-- Adapted from the uploaded platform and ticket-farm scripts.  Their
-- standalone draggable ScreenGuis are intentionally omitted; all controls
-- are kept inside this hub.
if _G.EvawareFarmCleanup then
    pcall(_G.EvawareFarmCleanup)
end

local farmTeleportPosition = Vector3.new(0, 10000, 0)
local safePlatformEnabled = false
local ticketFarmEnabled = false
local antiAfkEnabled = false
local autoReviveEnabled = false
local farmPlatform = nil
local farmRenderConnection = nil
local farmAntiAfkConnection = nil
local farmAutoReviveConnection = nil
local farmGameUISetType = nil
local farmSetPlayerMode = nil

local function ensureFarmPlatform()
    if farmPlatform and farmPlatform.Parent then
        return
    end

    farmPlatform = Instance.new("Part")
    farmPlatform.Name = "EvawareFarmPlatform"
    farmPlatform.Size = Vector3.new(50, 2, 50)
    farmPlatform.Position = farmTeleportPosition
    farmPlatform.Anchored = true
    farmPlatform.CanCollide = true
    farmPlatform.Transparency = 0.25
    farmPlatform.Color = Color3.fromRGB(80, 170, 255)
    farmPlatform.Parent = workspace
end

local function destroyFarmPlatform()
    if farmPlatform then
        farmPlatform:Destroy()
        farmPlatform = nil
    end
end

local function getFarmRoot()
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function getFirstTicket()
    local effects = workspace:FindFirstChild("Effects")
    local ticketFolder = effects and effects:FindFirstChild("Tickets")
    if not ticketFolder then
        return nil
    end

    for _, ticket in ipairs(ticketFolder:GetChildren()) do
        if ticket:IsA("Model") or ticket:IsA("BasePart") then
            return ticket
        end
    end

    return nil
end

local function refreshFarmLoop()
    local shouldRun = safePlatformEnabled or ticketFarmEnabled

    if not shouldRun then
        if farmRenderConnection then
            farmRenderConnection:Disconnect()
            farmRenderConnection = nil
        end
        destroyFarmPlatform()
        return
    end

    ensureFarmPlatform()
    if farmRenderConnection then
        return
    end

    farmRenderConnection = RunService.RenderStepped:Connect(function()
        local root = getFarmRoot()
        if not root then
            return
        end

        if ticketFarmEnabled then
            local ticket = getFirstTicket()
            if ticket then
                local ok, ticketPivot = pcall(function()
                    return ticket:GetPivot()
                end)
                if ok and ticketPivot then
                    root.CFrame = ticketPivot
                    return
                end
            end
        end

        if safePlatformEnabled or ticketFarmEnabled then
            local platformPosition = farmTeleportPosition + Vector3.new(0, 5, 0)
            if (root.Position - platformPosition).Magnitude > 10 then
                root.CFrame = CFrame.new(platformPosition)
            end
        end
    end)
end

local function setAntiAfk(state)
    antiAfkEnabled = state

    if state and not farmAntiAfkConnection then
        farmAntiAfkConnection = player.Idled:Connect(function()
            if not antiAfkEnabled then
                return
            end
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    elseif not state and farmAntiAfkConnection then
        farmAntiAfkConnection:Disconnect()
        farmAntiAfkConnection = nil
    end
end

local function getFarmEvent(eventName)
    local ok, event = pcall(function()
        local events = ReplicatedStorage:WaitForChild("Events", 5)
        if not events then
            return nil
        end
        return events:WaitForChild(eventName, 5)
    end)

    if ok and event then
        return event
    end
end

local function getLocalTag()
    local character = player.Character
    return character and character:GetAttribute("Tag")
end

local function setAutoRevive(state)
    autoReviveEnabled = state

    if not state then
        if farmAutoReviveConnection then
            farmAutoReviveConnection:Disconnect()
            farmAutoReviveConnection = nil
        end
        return
    end

    if farmAutoReviveConnection then
        return
    end

    farmGameUISetType = getFarmEvent("GameUISetType")
    farmSetPlayerMode = getFarmEvent("SetPlayerMode")
    if not farmGameUISetType or not farmSetPlayerMode then
        autoReviveEnabled = false
        return
    end

    farmAutoReviveConnection = farmGameUISetType.OnClientEvent:Connect(function(feedType, subType, data)
        if not autoReviveEnabled then
            return
        end
        if feedType ~= "DeathFeed" or subType ~= "Death" or type(data) ~= "table" then
            return
        end

        local myTag = getLocalTag()
        if myTag ~= nil and data.Recipient == myTag and data.Downed ~= nil then
            farmSetPlayerMode:FireServer(data.Downed)
        end
    end)
end

local function farmCleanup()
    safePlatformEnabled = false
    ticketFarmEnabled = false
    setAntiAfk(false)
    setAutoRevive(false)
    refreshFarmLoop()
end

_G.EvawareFarmCleanup = farmCleanup

FarmTab:AddToggle("SafePlatformFarm", {
    Title = "Safe Platform",
    Default = false,
    Callback = function(value)
        safePlatformEnabled = value
        refreshFarmLoop()
    end,
})

FarmTab:AddToggle("AutoTicketFarm", {
    Title = "Auto Ticket Farm",
    Default = false,
    Callback = function(value)
        ticketFarmEnabled = value
        refreshFarmLoop()
    end,
})

FarmTab:AddToggle("FarmAntiAFK", {
    Title = "Anti-AFK",
    Default = false,
    Callback = function(value)
        setAntiAfk(value)
    end,
})

FarmTab:AddToggle("FarmAutoRevive", {
    Title = "Auto Revive",
    Default = false,
    Callback = function(value)
        setAutoRevive(value)
    end,
})

FarmTab:AddButton({
    Title = "Force Revive",
    Callback = function()
        local setPlayerMode = farmSetPlayerMode or getFarmEvent("SetPlayerMode")
        if setPlayerMode then
            farmSetPlayerMode = setPlayerMode
            setPlayerMode:FireServer(true)
        end
    end,
})

-- VISUAL TAB

pcall(function()
-- === UNLOCK ALL (portado do Yin Yang) ===
do
local GENV = (type(getgenv) == "function" and getgenv()) or _G
if GENV.YY_UnlockAll and GENV.YY_UnlockAll.Disable then
    pcall(GENV.YY_UnlockAll.Disable)
end
GENV.YY_UnlockAll = (function()
    local M = {}
    local Players = game:GetService("Players")
    local RS = game:GetService("ReplicatedStorage")
    local StarterGui = game:GetService("StarterGui")
    local LP = Players.LocalPlayer
    local PREFIX = "[Unlock All]"
    local LOG = {}
    local function log(...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[i] = tostring((select(i, ...)))
        end
        local line = PREFIX .. " " .. table.concat(parts, " ")
        LOG[#LOG + 1] = line
        if #LOG > 200 then
            table.remove(LOG, 1)
        end
        print(line)
    end
    local function path(root, ...)
        local cur = root
        for _, name in ipairs({ ... }) do
            if not cur then
                return nil
            end
            cur = cur:WaitForChild(name, 10)
        end
        return cur
    end
    local function req(label, ...)
        local names = { ... }
        local ok, res = pcall(function()
            local inst = path(RS, table.unpack(names))
            if not inst then
                error("no se encontro la ruta")
            end
            return require(inst)
        end)
        if not ok then
            log("FALLO cargando", label, "->", tostring(res))
            return nil
        end
        return res
    end
    local active = false -- parches aplicados
    local gen = 0 -- invalida un Enable en curso cuando se llama Disable/Enable de nuevo
    local patches = {}
    local patchResults = {}
    local fakeE = {} -- emotes:    [indiceSlot 1..12] = idEmoteVisual
    local fakeC = {} -- cosmeticos: [nombreSlot]      = idItemVisual (p.ej. "CosmeticSlot_1")
    local pending = nil -- ultimo slot pulsado en la rueda { slot, t }
    local popupInst = nil -- instancia del popup de la rueda
    local warnedOverlay = false
    local lastBuild = {} -- diagnostico del ultimo armado de TU personaje
    local emoteOn, cosOn = false, false
    local Registry, Inventory, Loadout, PopupService, EmotePopup, EmoteClass, ItemSvc, RigClass, DataRegClass
    local origGetOwned, origOwns, origIsEquipped, origGetFromSlot, origSlotTypeForSlot, origSetEquipped
    local ALL, ALLSET = {}, {} -- emotes
    local TYPE_NAMES = { "Cosmetic", "Character", "Unusual", "Perk", "CarryAnimation", "Nametag" }
    local ENABLED, KNOWN = {}, {}
    for _, n in ipairs(TYPE_NAMES) do
        ENABLED[n] = true
        KNOWN[n] = true
    end
    local INGAME = { Perk = true, Nametag = true }
    local function emptyByType()
        local t = {}
        for _, n in ipairs(TYPE_NAMES) do
            t[n] = {}
        end
        return t
    end
    local BYTYPE = emptyByType()
    local TYPE_OF = {} -- [id] = tipo
    M.Log = LOG
    M.FakeEmotes = fakeE
    M.FakeCosmetics = fakeC
    M.LastBuild = lastBuild
    local function writable(t)
        local function probe()
            return pcall(function()
                t.__yy_probe = nil
            end)
        end
        if probe() then
            return true
        end
        if type(setreadonly) == "function" then
            pcall(setreadonly, t, false)
        end
        if probe() then
            return true
        end
        if type(make_writeable) == "function" then
            pcall(make_writeable, t)
        end
        return probe()
    end
    local function patch(label, tbl, key, build)
        local orig = tbl[key]
        if type(orig) ~= "function" then
            log("PARCHE NO APLICADO (no existe la funcion):", label)
            patchResults[#patchResults + 1] = { label = label, ok = false }
            return false
        end
        if not writable(tbl) then
            log("PARCHE NO APLICADO (tabla de solo lectura, falta setreadonly):", label)
            patchResults[#patchResults + 1] = { label = label, ok = false }
            return false
        end
        patches[#patches + 1] = { tbl = tbl, key = key, orig = orig }
        tbl[key] = build(orig)
        patchResults[#patchResults + 1] = { label = label, ok = true }
        return true
    end
    local function slotIndex(slot)
        return tonumber(string.match(tostring(slot), "^EmoteSlot_(%d+)$"))
    end
    local function realSlotId(idx)
        local ok, id = pcall(origGetFromSlot, "EmoteSlot_" .. idx)
        if ok and type(id) == "number" then
            return id
        end
        return 0
    end
    local function owns(id)
        local ok, res = pcall(origOwns, id)
        return ok and res == true
    end
    local function pickBase()
        local ok, owned = pcall(origGetOwned, "Emote")
        if not ok or type(owned) ~= "table" then
            return nil
        end
        local list = table.clone(owned)
        table.sort(list)
        for _, id in ipairs(list) do
            if not origIsEquipped(id) then
                return id
            end
        end
        return nil
    end
    local function getPopup()
        if popupInst and popupInst.Frame then
            return popupInst
        end
        if PopupService and type(PopupService.GetPopup) == "function" then
            local ok, p = pcall(PopupService.GetPopup, PopupService, "Emote")
            if ok and p then
                popupInst = p
                return p
            end
        end
        return nil
    end
    local function wheelSlotFrame(popup, idx)
        local wheel = popup.Frame:FindFirstChild(idx <= 6 and "Wheel" or "Wheel2")
        return wheel and wheel:FindFirstChild("Emote" .. ((idx - 1) % 6 + 1))
    end
    local function applyOverlay(popup)
        if not popup or not popup.Frame or type(popup.Emotes) ~= "table" then
            return
        end
        for idx, fid in pairs(fakeE) do
            if popup.Emotes[idx] then
                local ok, err = pcall(function()
                    local sf = wheelSlotFrame(popup, idx)
                    local item = ItemSvc:GetItemFromID(fid)
                    ItemSvc:ClearViewport(sf.ViewportFrame)
                    ItemSvc:CreateViewport(item, sf.ViewportFrame)
                    sf.TextLabel.Text = ItemSvc:GetName(item)
                end)
                if not ok and not warnedOverlay then
                    warnedOverlay = true
                    log("Aviso: no se pudo dibujar el visual en la rueda ->", tostring(err))
                end
            end
        end
    end
    local function refreshWheel()
        local p = getPopup()
        if not p or type(p.Emotes) ~= "table" then
            return
        end
        pcall(origSetEquipped, p, p.Emotes) -- redibuja lo real
        applyOverlay(p) -- y encima el visual
    end
    local function isLocalEmote(self)
        local char = self.Character
        local lc = LP.Character
        if not char or not lc then
            return false
        end
        if char == lc then
            return true
        end
        local a, b = char:GetAttribute("Tag"), lc:GetAttribute("Tag")
        return a ~= nil and a == b
    end
    local function resolveFake(self)
        local mod = self.EmoteModule
        local modId = mod and mod:GetAttribute("ID")
        if not modId then
            return nil
        end
        if pending and tick() - pending.t < 5 then
            local fid = fakeE[pending.slot]
            if fid and realSlotId(pending.slot) == modId then
                pending = nil
                return fid
            end
        end
        for idx = 1, 12 do
            local fid = fakeE[idx]
            if fid and realSlotId(idx) == modId then
                return fid
            end
        end
        return nil
    end
    local function swapTo(fid)
        if type(firesignal) ~= "function" then
            log("Tu ejecutor no tiene firesignal: no se puede cambiar el emote local")
            return
        end
        local char = LP.Character
        local tag = char and char:GetAttribute("Tag")
        if not tag then
            log("Character tag was not found; the emote was not changed.")
            return
        end
        local ok, err = pcall(function()
            local tagBuf = buffer.create(2)
            buffer.writeu16(tagBuf, 0, tag)
            firesignal(RS.Events.UpdateCharacterDataRegistry.OnClientEvent, {
                buffer.fromstring("\24\1"),
                fid,
                tagBuf,
            })
        end)
        if not ok then
            log("Fallo el cambio local de emote ->", tostring(err))
        end
    end
    local function slotType(slot)
        if type(slot) ~= "string" or type(origSlotTypeForSlot) ~= "function" then
            return nil
        end
        local ok, st = pcall(origSlotTypeForSlot, slot)
        if ok and KNOWN[st] then
            return st
        end
        return nil
    end
    local function collectEmoteIds()
        local raw, seen = {}, {}
        local items = RS:FindFirstChild("Items")
        local function walk(parent)
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("Folder") then
                    if child.Name == "Emotes" then
                        for _, e in ipairs(child:GetChildren()) do
                            if e:IsA("ModuleScript") then
                                local id = e:GetAttribute("ID")
                                if type(id) == "number" and not seen[id] then
                                    seen[id] = true
                                    raw[#raw + 1] = id
                                end
                            end
                        end
                    else
                        walk(child)
                    end
                end
            end
        end
        if items then
            walk(items)
        end
        local filtered = {}
        for _, id in ipairs(raw) do
            local okSlot, st = pcall(Inventory.GetSlotType, id)
            local okReg, entry = pcall(Registry.GetById, id)
            if okSlot and st == "Emote" and okReg and entry and entry.Module then
                filtered[#filtered + 1] = id
            end
        end
        if #filtered == 0 and #raw > 0 then
            log("Aviso: el filtro por slot 'Emote' dejo 0; se usa la lista sin filtrar (", #raw, ")")
            filtered = raw
        end
        table.sort(filtered)
        return filtered, #raw
    end
    local function collectCosmetics()
        local okAll, all = pcall(Registry.GetAll)
        if not okAll or type(all) ~= "table" then
            return nil
        end
        local bytype = emptyByType()
        local typeOf = {}
        local n = 0
        for id in pairs(all) do
            n = n + 1
            if n % 400 == 0 then
                task.wait() -- ceder para no congelar el cliente al leer cientos de modulos
            end
            if type(id) == "number" then
                local ok, st = pcall(Inventory.GetSlotType, id)
                if ok and KNOWN[st] then
                    local list = bytype[st]
                    list[#list + 1] = id
                    typeOf[id] = st
                end
            end
        end
        for _, list in pairs(bytype) do
            table.sort(list)
        end
        return bytype, typeOf, n
    end
    local function substitutePerks(value)
        if type(value) ~= "table" or not (INGAME.Perk and ENABLED.Perk) then
            return value
        end
        local removed, any = {}, false
        for slot in pairs(fakeC) do
            if slotType(slot) == "Perk" then
                any = true
                local okR, rid = pcall(origGetFromSlot, slot)
                if okR and type(rid) == "number" and rid ~= 0 then
                    removed[rid] = true
                end
            end
        end
        if not any then
            return value
        end
        local out, seen = {}, {}
        for _, id in ipairs(value) do
            if not removed[id] then
                out[#out + 1] = id
                seen[id] = true
            end
        end
        for slot, fid in pairs(fakeC) do
            if slotType(slot) == "Perk" and not seen[fid] then
                out[#out + 1] = fid
                seen[fid] = true
            end
        end
        return out
    end
    local function substituteNametag(value)
        local fid = fakeC["NametagSlot"]
        if type(fid) == "number" and INGAME.Nametag and ENABLED.Nametag then
            return fid
        end
        return value
    end
    local function applyPatches()
        patch("useInventory.GetOwnedBySlotType", Inventory, "GetOwnedBySlotType", function(orig)
            return function(st, ...)
                local list = orig(st, ...)
                if type(list) ~= "table" then
                    return list
                end
                local extra
                if st == "Emote" then
                    if not emoteOn then
                        return list
                    end
                    extra = ALL
                elseif cosOn and ENABLED[st] then
                    extra = BYTYPE[st]
                else
                    return list
                end
                local have = {}
                for _, id in ipairs(list) do
                    have[id] = true
                end
                local out = table.clone(list)
                for _, id in ipairs(extra) do
                    if not have[id] then
                        out[#out + 1] = id
                    end
                end
                return out
            end
        end)
        patch("useLoadout.TryEquip", Loadout, "TryEquip", function(orig)
            return function(slot, id, ...)
                local idx = emoteOn and slotIndex(slot) or nil
                if idx then
                    if type(id) == "number" and id ~= 0 then
                        if ALLSET[id] and not owns(id) then
                            if realSlotId(idx) == 0 then
                                local base = pickBase()
                                if not base then
                                    log("No tienes ningun emote real para usar de base en el slot", idx)
                                    return
                                end
                                log("Slot", idx, "vacio: se equipa el emote real base", base)
                                orig(slot, base)
                            end
                            fakeE[idx] = id
                            log("Slot", idx, "-> emote visual", id)
                            refreshWheel()
                            return
                        end
                        local had = fakeE[idx] ~= nil
                        fakeE[idx] = nil
                        local r = orig(slot, id, ...)
                        if had then
                            refreshWheel()
                        end
                        return r
                    end
                    if id == nil or id == 0 then
                        fakeE[idx] = nil
                    end
                    return orig(slot, id, ...)
                end
                local st = cosOn and slotType(slot) or nil
                if st and ENABLED[st] then
                    if type(id) == "number" and id ~= 0 then
                        if TYPE_OF[id] == st and not owns(id) then
                            fakeC[slot] = id
                            log("Slot", slot, "-> visual", id)
                            return
                        end
                        fakeC[slot] = nil
                        return orig(slot, id, ...)
                    end
                    if (id == nil or id == 0) and fakeC[slot] ~= nil then
                        fakeC[slot] = nil
                        log("Slot", slot, "-> visual quitado")
                        return
                    end
                end
                return orig(slot, id, ...)
            end
        end)
        patch("useLoadout.TryUnequip", Loadout, "TryUnequip", function(orig)
            return function(slot, ...)
                if cosOn and fakeC[slot] ~= nil then
                    fakeC[slot] = nil
                    log("Slot", slot, "-> visual quitado")
                    return
                end
                local idx = emoteOn and slotIndex(slot) or nil
                local had = idx and fakeE[idx] ~= nil
                if idx then
                    fakeE[idx] = nil
                end
                local r = orig(slot, ...)
                if had then
                    refreshWheel()
                end
                return r
            end
        end)
        patch("useLoadout.GetEquipped", Loadout, "GetEquipped", function(orig)
            return function(...)
                local real = orig(...)
                if type(real) ~= "table" or (next(fakeE) == nil and next(fakeC) == nil) then
                    return real
                end
                local out = table.clone(real)
                for idx, fid in pairs(fakeE) do
                    local name = "EmoteSlot_" .. idx
                    if out[name] then
                        out[name] = fid
                    end
                end
                for slot, fid in pairs(fakeC) do
                    out[slot] = fid
                end
                return table.freeze(out)
            end
        end)
        patch("useLoadout.IsEquipped", Loadout, "IsEquipped", function(orig)
            return function(id)
                local eq, s = orig(id)
                if eq then
                    return eq, s
                end
                for idx, fid in pairs(fakeE) do
                    if fid == id then
                        return true, "EmoteSlot_" .. idx
                    end
                end
                for slot, fid in pairs(fakeC) do
                    if fid == id then
                        return true, slot
                    end
                end
                return false, nil
            end
        end)
        if emoteOn then
            patch("EmotePopup.SetEquipped", EmotePopup, "SetEquipped", function(orig)
                return function(self, list, ...)
                    local r = orig(self, list, ...)
                    popupInst = self
                    applyOverlay(self)
                    return r
                end
            end)
            patch("EmotePopup.Show", EmotePopup, "Show", function(orig)
                return function(self, ...)
                    local r = orig(self, ...)
                    popupInst = self
                    applyOverlay(self)
                    return r
                end
            end)
            patch("EmotePopup.KeyActivated", EmotePopup, "KeyActivated", function(orig)
                return function(self, slot, ...)
                    if type(slot) == "number" then
                        pending = { slot = slot, t = tick() }
                    end
                    return orig(self, slot, ...)
                end
            end)
            patch("Emote.Activate", EmoteClass, "Activate", function(orig)
                return function(self, preview, p3)
                    local fid = nil
                    if not preview then
                        pcall(function()
                            if isLocalEmote(self) then
                                fid = resolveFake(self)
                            end
                        end)
                    end
                    if fid then
                        task.defer(swapTo, fid)
                    end
                    return orig(self, preview, p3)
                end
            end)
        end
        if cosOn then
            if RigClass then
                patch("Rig.BuildRig (partida)", RigClass, "BuildRig", function(orig)
                    return function(self, ...)
                        if not self.Built
                            and type(self.Cosmetics) == "table"
                            and self.RigTerm and self.Actions and self.ToolSkins and self.Boombox
                            and next(fakeC) ~= nil
                        then
                            local isLocal = false
                            pcall(function()
                                isLocal = self.Parent ~= nil and self.Parent.Local == true
                            end)
                            if isLocal then
                                local ok, err = pcall(function()
                                    local real = self.Cosmetics
                                    local removed = {}
                                    for slot in pairs(fakeC) do
                                        local okR, rid = pcall(origGetFromSlot, slot)
                                        if okR and type(rid) == "number" and rid ~= 0 then
                                            removed[rid] = true
                                        end
                                    end
                                    local out, seen = {}, {}
                                    for _, id in ipairs(real) do
                                        if not removed[id] then
                                            out[#out + 1] = id
                                            seen[id] = true
                                        end
                                    end
                                    for _, fid in pairs(fakeC) do
                                        if not seen[fid] then
                                            out[#out + 1] = fid
                                            seen[fid] = true
                                        end
                                    end
                                    table.clear(lastBuild)
                                    lastBuild.Real = table.clone(real)
                                    lastBuild.Fake = table.clone(fakeC)
                                    lastBuild.Final = table.clone(out)
                                    self.Cosmetics = out
                                    log(
                                        "BuildRig local: real = {" .. table.concat(real, ",") .. "}",
                                        "| final = {" .. table.concat(out, ",") .. "}"
                                    )
                                end)
                                if not ok then
                                    log("Fallo al cambiar Cosmetics en BuildRig ->", tostring(err))
                                end
                            end
                        end
                        return orig(self, ...)
                    end
                end)
            else
                log("PARCHE NO APLICADO (no se pudo cargar Objects.Game.Character.Rig): cosmeticos en partida no funcionan")
                patchResults[#patchResults + 1] = { label = "Rig.BuildRig (partida)", ok = false }
            end
            if DataRegClass then
                patch("DataRegistry.SetTerm (ventajas/etiqueta)", DataRegClass, "SetTerm", function(orig)
                    return function(self, term, value, ...)
                        if (term == "Perks" or term == "Nametag") and next(fakeC) ~= nil then
                            local ok, res = pcall(function()
                                if self.Parent == nil or self.Parent.Local ~= true then
                                    return value
                                end
                                if term == "Perks" then
                                    return substitutePerks(value)
                                end
                                return substituteNametag(value)
                            end)
                            if ok and res ~= nil and res ~= value then
                                log("En partida:", term, "->", type(res) == "table" and ("{" .. table.concat(res, ",") .. "}") or tostring(res))
                                value = res
                            end
                        end
                        return orig(self, term, value, ...)
                    end
                end)
            else
                log("PARCHE NO APLICADO (no se pudo cargar Objects.Game.Character.DataRegistry): ventajas/etiqueta en partida no funcionan")
                patchResults[#patchResults + 1] = { label = "DataRegistry.SetTerm (ventajas/etiqueta)", ok = false }
            end
        end
    end
    function M.Disable()
        gen = gen + 1 -- cancela un Enable que este leyendo listas
        if not active then
            return
        end
        for i = #patches, 1, -1 do
            local p = patches[i]
            pcall(function()
                p.tbl[p.key] = p.orig
            end)
        end
        patches = {}
        table.clear(fakeE)
        table.clear(fakeC)
        table.clear(lastBuild)
        pending = nil
        emoteOn, cosOn = false, false
        active = false
        refreshWheel()
        log("Descargado: todo restaurado")
    end
    local emoteCache, cosCache = nil, nil
    local function enableImpl(myGen)
        for _, name in ipairs({ "YY_CosmeticTest", "YY_EmoteTest" }) do
            local ok, t = pcall(function()
                return GENV[name]
            end)
            if ok and type(t) == "table" and type(t.Unload) == "function" then
                pcall(t.Unload)
                log("Se descargo el script de prueba suelto:", name)
            end
        end
        Registry = req("Items.Registry", "Items", "Registry")
        Inventory = req("useInventory", "Shared", "UserData", "ClientHooks", "useInventory")
        Loadout = req("useLoadout", "Shared", "UserData", "ClientHooks", "useLoadout")
        if not (Registry and Inventory and Loadout) then
            log("ABORTADO: falta al menos un modulo necesario. No se aplico ningun parche.")
            return
        end
        RigClass = req("Objects.Game.Character.Rig", "Objects", "Game", "Character", "Rig")
        DataRegClass = req("Objects.Game.Character.DataRegistry", "Objects", "Game", "Character", "DataRegistry")
        PopupService = req("PopupService", "Services", "UI", "PopupService")
        EmotePopup = req("PopupService.Types.Emote", "Services", "UI", "PopupService", "Types", "Emote")
        EmoteClass = req("Objects.Items.Emote", "Objects", "Items", "Emote")
        ItemSvc = req("ClientItemService", "Services", "Items", "ClientItemService")
        local emoteMods = (EmotePopup and EmoteClass and ItemSvc) and true or false
        if not emoteMods then
            log("Note: emote modules are missing; Unlock All applies only to cosmetics, characters, and auras.")
        end
        local newAll, newAllSet, rawCount = {}, {}, 0
        if emoteMods then
            if not emoteCache then
                local ids, raw = collectEmoteIds()
                emoteCache = { ids = ids, raw = raw }
            end
            newAll, rawCount = emoteCache.ids, emoteCache.raw
            for _, id in ipairs(newAll) do
                newAllSet[id] = true
            end
            log("Emotes encontrados:", rawCount, "| validos:", #newAll)
        end
        if not cosCache then
            local by, typeOf, n = collectCosmetics() -- puede ceder (task.wait)
            if by then
                cosCache = { by = by, typeOf = typeOf, n = n }
            end
        end
        local newBy, newTypeOf, regCount
        if cosCache then
            newBy, newTypeOf, regCount = cosCache.by, cosCache.typeOf, cosCache.n
        end
        if myGen ~= gen then
            return -- se apago (o se re-encendio) mientras se leian las listas
        end
        if active then
            return
        end
        if not newBy then
            log("Aviso: Registry.GetAll no devolvio una tabla; cosmeticos/personajes/auras desactivados")
            newBy = emptyByType()
            newTypeOf = {}
            regCount = 0
        end
        local cosTotal = 0
        local counts = {}
        for _, n in ipairs(TYPE_NAMES) do
            cosTotal = cosTotal + #newBy[n]
            counts[#counts + 1] = n .. ": " .. #newBy[n]
        end
        log("Items en Registry:", regCount, "|", table.concat(counts, " | "))
        if #newAll == 0 and cosTotal == 0 then
            log("ABORTADO: no se encontro ningun emote ni cosmetico. No se aplico ningun parche.")
            return
        end
        ALL, ALLSET = newAll, newAllSet
        BYTYPE, TYPE_OF = newBy, newTypeOf
        emoteOn = emoteMods and #newAll > 0
        cosOn = cosTotal > 0
        patches, patchResults = {}, {}
        table.clear(fakeE)
        table.clear(fakeC)
        pending = nil
        popupInst = nil
        warnedOverlay = false
        origGetOwned = Inventory.GetOwnedBySlotType
        origOwns = Inventory.Owns
        origIsEquipped = Loadout.IsEquipped
        origGetFromSlot = Loadout.GetEquippedFromSlot
        origSlotTypeForSlot = Loadout.GetSlotTypeForSlot
        origSetEquipped = EmotePopup and EmotePopup.SetEquipped or nil
        applyPatches()
        active = true
        local okCount = 0
        for _, r in ipairs(patchResults) do
            if r.ok then
                okCount = okCount + 1
            end
        end
        log("Ready:", okCount .. "/" .. #patchResults, "patches applied")
        if okCount < #patchResults then
            log("Some patches failed. Run getgenv().YY_UnlockAll.Status() to inspect the details.")
        end
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = okCount == #patchResults and "Unlock All — Complete" or "Unlock All — Partial",
                Text = okCount .. " of " .. #patchResults .. " patches applied. " .. (okCount == #patchResults and "All available patches are active." or "Check the Unlock All status log for details."),
                Duration = 6,
            })
        end)
    end
    function M.Enable()
        if active then
            return
        end
        gen = gen + 1
        local myGen = gen
        task.spawn(function()
            local ok, err = pcall(enableImpl, myGen)
            if not ok then
                log("Enable failed ->", tostring(err))
            end
        end)
    end
    function M.IsEnabled()
        return active
    end
    function M.Status()
        log("---- STATUS ---- enabled:", tostring(active), "| emotes:", tostring(emoteOn), "| cosmeticos:", tostring(cosOn))
        for _, r in ipairs(patchResults) do
            log(r.ok and "OK     " or "FAILED ", r.label)
        end
        for st in pairs(KNOWN) do
            log("Type", st, ENABLED[st] and "enabled" or "disabled", "| items:", #BYTYPE[st])
        end
        local any = false
        for idx = 1, 12 do
            if fakeE[idx] then
                any = true
                log("Emote slot", idx, "real:", realSlotId(idx), "| visual:", fakeE[idx])
            end
        end
        for slot, fid in pairs(fakeC) do
            any = true
            local okReal, real = pcall(Loadout.GetEquippedFromSlot, slot)
            log("Slot", slot, "real:", okReal and real or "?", "| visual:", fid)
        end
        if not any then
            log("No visual slots are currently active.")
        end
    end
    function M.SetType(name, state)
        if not KNOWN[name] then
            log("Unknown type:", tostring(name), "(usa " .. table.concat(TYPE_NAMES, ", ") .. ")")
            return
        end
        ENABLED[name] = state and true or false
        if not ENABLED[name] then
            for slot in pairs(fakeC) do
                if slotType(slot) == name then
                    fakeC[slot] = nil
                end
            end
        end
        log("Type", name, ENABLED[name] and "activado" or "disabled", "(se aplica la proxima vez que abras el selector)")
    end
    function M.SetInGame(name, state)
        if INGAME[name] == nil then
            log("This option only supports Perk or Nametag.")
            return
        end
        INGAME[name] = state and true or false
        log("En partida:", name, INGAME[name] and "activado" or "disabled", "(aplica en la proxima actualizacion del servidor)")
    end
    return M
end)()
end


end)

VisualTab:AddToggle("UnlockAllToggle", {
    Title = "Unlock All",
    Description = "Unlock everything",
    Default = false,
    Callback = function(state)
        local genv = (type(getgenv) == "function" and getgenv()) or _G
        local ua = genv.YY_UnlockAll
        if not ua then
            Fluent:Notify({ Title = "Unlock All", Content = "Module not available", Duration = 3 })
            return
        end
        if state then
            task.spawn(pcall, ua.Enable)
        else
            task.spawn(pcall, ua.Disable)
        end
    end,
})

VisualTab:AddParagraph({ Title = "Visual Advanced", Content = "" })
pcall(function()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local spectatorListEnabled = false
local spectatorGui = nil
local spectatorConn = nil

local function destroySpectatorGui()
    if spectatorGui then
        spectatorGui:Destroy()
        spectatorGui = nil
    end
    if spectatorConn then
        spectatorConn:Disconnect()
        spectatorConn = nil
    end
end

local function createSpectatorGui()
    destroySpectatorGui()

    local ITEM_H = 34
    local PAD = 8
    local HEADER_H = 36
    local WIDTH = 260
    local MIN_H = HEADER_H + PAD

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SpectatorListGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    spectatorGui = screenGui

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.new(0, WIDTH, 0, MIN_H)
    panel.Position = UDim2.new(1, -WIDTH - 20, 0.5, -MIN_H / 2)
    panel.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
    panel.BorderSizePixel = 0
    panel.ClipsDescendants = true
    panel.Parent = screenGui

    local panelCorner = Instance.new("UICorner", panel)
    panelCorner.CornerRadius = UDim.new(0, 8)

    local outerStroke = Instance.new("UIStroke", panel)
    outerStroke.Color = Color3.fromRGB(35, 35, 42)
    outerStroke.Thickness = 1

    local header = Instance.new("Frame", panel)
    header.Size = UDim2.new(1, 0, 0, HEADER_H)
    header.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    header.BorderSizePixel = 0

    local headerCorner = Instance.new("UICorner", header)
    headerCorner.CornerRadius = UDim.new(0, 8)

    local headerFix = Instance.new("Frame", header)
    headerFix.Size = UDim2.new(1, 0, 0, 8)
    headerFix.Position = UDim2.new(0, 0, 1, -8)
    headerFix.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    headerFix.BorderSizePixel = 0

    local titleLabel = Instance.new("TextLabel", header)
    titleLabel.Size = UDim2.new(1, -50, 1, 0)
    titleLabel.Position = UDim2.new(0, PAD + 4, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Possible spectators"
    titleLabel.TextSize = 13
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextColor3 = Color3.fromRGB(240, 240, 242)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    local countLabel = Instance.new("TextLabel", header)
    countLabel.Size = UDim2.new(0, 30, 1, 0)
    countLabel.Position = UDim2.new(1, -38, 0, 0)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = "(0)"
    countLabel.TextSize = 12
    countLabel.Font = Enum.Font.GothamBold
    countLabel.TextColor3 = Color3.fromRGB(130, 130, 135)
    countLabel.TextXAlignment = Enum.TextXAlignment.Right

    local listFrame = Instance.new("Frame", panel)
    listFrame.Name = "List"
    listFrame.Position = UDim2.new(0, PAD, 0, HEADER_H + PAD)
    listFrame.Size = UDim2.new(1, -PAD * 2, 0, 0)
    listFrame.BackgroundTransparency = 1
    listFrame.BorderSizePixel = 0

    local listLayout = Instance.new("UIListLayout", listFrame)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 4)

    local dragging = false
    local dragStart, startPos

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = panel.Position
        end
    end)

    local dragConn1 = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            panel.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    local dragConn2 = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local function makeRow(playerName, stateText)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, ITEM_H)
        row.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
        row.BorderSizePixel = 0
        row.Parent = listFrame

        local rc = Instance.new("UICorner", row)
        rc.CornerRadius = UDim.new(0, 6)

        local rowStroke = Instance.new("UIStroke", row)
        rowStroke.Color = Color3.fromRGB(28, 28, 34)
        rowStroke.Thickness = 1

        local avatarImg = Instance.new("ImageLabel", row)
        avatarImg.Size = UDim2.new(0, 24, 0, 24)
        avatarImg.Position = UDim2.new(0, 6, 0.5, -12)
        avatarImg.BackgroundTransparency = 1
        
        local ac = Instance.new("UICorner", avatarImg)
        ac.CornerRadius = UDim.new(1, 0)

        local pObj = Players:FindFirstChild(playerName)
        if pObj then
            task.spawn(function()
                local content, isReady = Players:GetUserThumbnailAsync(pObj.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                if isReady then avatarImg.Image = content end
            end)
        end

        local nameLabel = Instance.new("TextLabel", row)
        nameLabel.Size = UDim2.new(1, -40, 1, 0)
        nameLabel.Position = UDim2.new(0, 36, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = playerName .. " " .. stateText
        nameLabel.TextSize = 11
        nameLabel.Font = Enum.Font.GothamMedium
        nameLabel.TextColor3 = Color3.fromRGB(220, 220, 225)
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd

        return row
    end

    local lastHash = ""
    local updateCooldown = 0

    local function updateList()
        updateCooldown = updateCooldown + 1
        if updateCooldown % 10 ~= 0 then return end

        local entries = {}
        
        local activeCharacters = {}
        local gamePlayersFolder = Workspace:FindFirstChild("Game") and Workspace.Game:FindFirstChild("Players")
        if gamePlayersFolder then
            for _, char in pairs(gamePlayersFolder:GetChildren()) do
                if char:GetAttribute("Tag") and char:GetAttribute("Team") ~= "Menu" then
                    activeCharacters[char.Name] = true
                end
            end
        end

        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local isDeadOrMenu = false
                local stateReason = ""

                if not activeCharacters[player.Name] then
                    isDeadOrMenu = true
                end

                if gamePlayersFolder then
                    local pCharInGame = gamePlayersFolder:FindFirstChild(player.Name)
                    if pCharInGame and pCharInGame:GetAttribute("Team") == "Menu" then
                        isDeadOrMenu = true
                        stateReason = ""
                    end
                end

                if isDeadOrMenu then
                    table.insert(entries, { name = player.Name, target = stateReason })
                end
            end
        end

        table.sort(entries, function(a, b) return a.name < b.name end)

        local hash = ""
        for _, e in ipairs(entries) do hash = hash .. e.name .. e.target .. "|" end
        if hash == lastHash then return end
        lastHash = hash

        for _, child in pairs(listFrame:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end

        for i, entry in ipairs(entries) do
            local row = makeRow(entry.name, entry.target)
            row.LayoutOrder = i
        end

        countLabel.Text = "(" .. tostring(#entries) .. ")"

        local listH = #entries > 0 and (#entries * ITEM_H + (#entries - 1) * 4) or 0
        listFrame.Size = UDim2.new(1, -PAD * 2, 0, listH)

        local totalH = HEADER_H + PAD + listH + (#entries > 0 and PAD or 0)
        panel.Size = UDim2.new(0, WIDTH, 0, math.max(totalH, MIN_H))
    end

    spectatorConn = RunService.Heartbeat:Connect(function()
        pcall(updateList)
    end)

    screenGui.Destroying:Connect(function()
        if spectatorConn then
            spectatorConn:Disconnect()
            spectatorConn = nil
        end
    end)
end

local function setSpectatorList(value)
    if value == spectatorListEnabled then return end
    spectatorListEnabled = value
    if value then
        createSpectatorGui()
    else
        destroySpectatorGui()
    end
end

VisualTab:AddToggle("SpectatorList", {
    Title = "Spectator List",
    Default = false,
    Callback = function(value)
        pcall(setSpectatorList, value)
    end,
})
end)

-- Fiery Horns Section
pcall(function()
local fieryHornsEnabled = false
local fieryHornsAccessories = {}
local FieryHornsToggleObject = nil

local function findAttachment(model, name)
    for _, v in pairs(model:GetChildren()) do
        if v:IsA("Attachment") and v.Name == name then
            return v
        elseif not v:IsA("Accoutrement") and not v:IsA("Tool") then
            local found = findAttachment(v, name)
            if found then return found end
        end
    end
end

local function weldAttachments(a0, a1)
    local weld = Instance.new("Weld")
    weld.Part0 = a0.Parent
    weld.Part1 = a1.Parent
    weld.C0 = a0.CFrame
    weld.C1 = a1.CFrame
    weld.Parent = a0.Parent
    return weld
end

local function attachToRig(rig, accessory)
    accessory.Parent = rig
    for _, part in pairs(accessory:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
        end
    end

    local handle = accessory:FindFirstChild("Handle")
    if not handle then return end

    local att = handle:FindFirstChildOfClass("Attachment")
    if att then
        local rigAtt = findAttachment(rig, att.Name)
        if rigAtt then
            weldAttachments(rigAtt, att)
        end
    else
        local head = rig:FindFirstChild("Head")
        if head then
            local weld = Instance.new("Weld")
            weld.Name = "HeadWeld"
            weld.Part0 = head
            weld.Part1 = handle
            weld.C0 = CFrame.new(0, 0.5, 0)
            weld.C1 = accessory.AttachmentPoint
            weld.Parent = head
        end
    end
end

local function getActiveRigsFolders()
    local result = {}
    for _, child in ipairs(workspace:GetChildren()) do
        if child.Name == "Rigs" and #child:GetChildren() > 0 then
            table.insert(result, child)
        end
    end
    return result
end

local function unloadAll(accessories)
    for _, acc in ipairs(accessories) do if acc and acc.Parent then acc:Destroy() end end
    table.clear(accessories)
end

local function applyToOwnRigInFolder(folder)
    if not folder then return end
    local rig = folder:FindFirstChild(game.Players.LocalPlayer.Name)
    if not rig then return end

    local ok, result = pcall(function()
        return game:GetObjects("rbxassetid://215718515")[1]
    end)
    if ok and result then
        attachToRig(rig, result)
        table.insert(fieryHornsAccessories, result)
    end
end

local function applyToAllActiveRigs()
    if not fieryHornsEnabled then return end
    unloadAll(fieryHornsAccessories)
    for _, rigsFolder in ipairs(getActiveRigsFolders()) do
        applyToOwnRigInFolder(rigsFolder)
    end
end

local function setFieryHorns(state)
    fieryHornsEnabled = state
    if state then
        applyToAllActiveRigs()
        if #fieryHornsAccessories == 0 then
            Fluent:Notify({ Title = "Fiery Horns", Content = "Failed to load", Duration = 3 })
            fieryHornsEnabled = false
            task.spawn(function() task.wait(); if FieryHornsToggleObject then Options["FieryHorns"]:SetValue(false) end end)
            return
        end
    else
        unloadAll(fieryHornsAccessories)
    end
end

if _G.FieryHornsCharConn then
    _G.FieryHornsCharConn:Disconnect()
    _G.FieryHornsCharConn = nil
end

_G.FieryHornsCharConn = game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.01)
    task.defer(applyToAllActiveRigs)
end)

FieryHornsToggleObject = VisualTab:AddToggle("FieryHorns", {
    Title = "Fiery Horns of the Netherworld",
    Default = false,
    Callback = function(value)
        if value == fieryHornsEnabled then return end
        setFieryHorns(value)
    end,
})
end)

-- Poisoned Horns Section
pcall(function()
local poisonedHornsEnabled = false
local poisonedHornsAccessories = {}
local PoisonedHornsToggleObject = nil
local POISONED_ASSETS = {{ id = "1744060292", extraY = 0 }}

local function findAttachment(model, name)
    for _, v in pairs(model:GetChildren()) do
        if v:IsA("Attachment") and v.Name == name then
            return v
        elseif not v:IsA("Accoutrement") and not v:IsA("Tool") then
            local found = findAttachment(v, name)
            if found then return found end
        end
    end
end

local function weldAttachments(a0, a1, extraY)
    local weld = Instance.new("Weld")
    weld.Part0 = a0.Parent
    weld.Part1 = a1.Parent
    weld.C0 = a0.CFrame * CFrame.new(0, extraY or 0, 0)
    weld.C1 = a1.CFrame
    weld.Parent = a0.Parent
    return weld
end

local function attachToRig(rig, accessory, extraY)
    accessory.Parent = rig
    for _, part in pairs(accessory:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
        end
    end

    local handle = accessory:FindFirstChild("Handle")
    if not handle then return end
    local att = handle:FindFirstChildOfClass("Attachment")
    if att then
        local rigAtt = findAttachment(rig, att.Name)
        if rigAtt then weldAttachments(rigAtt, att, extraY) end
    else
        local head = rig:FindFirstChild("Head")
        if head then
            local weld = Instance.new("Weld")
            weld.Name = "HeadWeld"
            weld.Part0 = head
            weld.Part1 = handle
            weld.C0 = CFrame.new(0, 0.5 + (extraY or 0), 0)
            weld.C1 = accessory.AttachmentPoint
            weld.Parent = head
        end
    end
end

local function getActiveRigsFolders()
    local result = {}
    for _, child in ipairs(workspace:GetChildren()) do
        if child.Name == "Rigs" and #child:GetChildren() > 0 then
            table.insert(result, child)
        end
    end
    return result
end

local function unloadAll(accessories)
    for _, acc in ipairs(accessories) do if acc and acc.Parent then acc:Destroy() end end
    table.clear(accessories)
end

local function applyToOwnRigInFolder(folder)
    if not folder then return end
    local rig = folder:FindFirstChild(game.Players.LocalPlayer.Name)
    if not rig then return end

    for _, asset in ipairs(POISONED_ASSETS) do
        local ok, result = pcall(function() return game:GetObjects("rbxassetid://" .. asset.id)[1] end)
        if ok and result then
            attachToRig(rig, result, asset.extraY)
            table.insert(poisonedHornsAccessories, result)
        end
    end
end

local function applyToAllActiveRigs()
    if not poisonedHornsEnabled then return end
    unloadAll(poisonedHornsAccessories)
    for _, rigsFolder in ipairs(getActiveRigsFolders()) do
        applyToOwnRigInFolder(rigsFolder)
    end
end

local function setPoisonedHorns(state)
    poisonedHornsEnabled = state
    if state then
        applyToAllActiveRigs()
        if #poisonedHornsAccessories == 0 then
            Fluent:Notify({ Title = "Poisoned Horns", Content = "Failed to load", Duration = 3 })
            poisonedHornsEnabled = false
            task.spawn(function() task.wait(); if PoisonedHornsToggleObject then Options["PoisonedHorns"]:SetValue(false) end end)
            return
        end
    else
        unloadAll(poisonedHornsAccessories)
    end
end

if _G.PoisonedHornsCharConn then
    _G.PoisonedHornsCharConn:Disconnect()
    _G.PoisonedHornsCharConn = nil
end

_G.PoisonedHornsCharConn = game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.01)
    task.defer(applyToAllActiveRigs)
end)

PoisonedHornsToggleObject = VisualTab:AddToggle("PoisonedHorns", {
    Title = "Poisoned Horns of the Toxic Wasteland",
    Default = false,
    Callback = function(value)
        if value == poisonedHornsEnabled then return end
        setPoisonedHorns(value)
    end,
})
end)

-- Frozen Horns Section
pcall(function()
local frozenHornsEnabled = false
local frozenHornsAccessories = {}
local FrozenHornsToggleObject = nil
local FROZEN_ASSETS = {{ id = "74891470", extraY = 0 }}

local function findAttachment(model, name)
    for _, v in pairs(model:GetChildren()) do
        if v:IsA("Attachment") and v.Name == name then
            return v
        elseif not v:IsA("Accoutrement") and not v:IsA("Tool") then
            local found = findAttachment(v, name)
            if found then return found end
        end
    end
end

local function weldAttachments(a0, a1, extraY)
    local weld = Instance.new("Weld")
    weld.Part0 = a0.Parent
    weld.Part1 = a1.Parent
    weld.C0 = a0.CFrame * CFrame.new(0, extraY or 0, 0)
    weld.C1 = a1.CFrame
    weld.Parent = a0.Parent
    return weld
end

local function attachToRig(rig, accessory, extraY)
    accessory.Parent = rig
    for _, part in pairs(accessory:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
        end
    end

    local handle = accessory:FindFirstChild("Handle")
    if not handle then return end
    local att = handle:FindFirstChildOfClass("Attachment")
    if att then
        local rigAtt = findAttachment(rig, att.Name)
        if rigAtt then weldAttachments(rigAtt, att, extraY) end
    else
        local head = rig:FindFirstChild("Head")
        if head then
            local weld = Instance.new("Weld")
            weld.Name = "HeadWeld"
            weld.Part0 = head
            weld.Part1 = handle
            weld.C0 = CFrame.new(0, 0.5 + (extraY or 0), 0)
            weld.C1 = accessory.AttachmentPoint
            weld.Parent = head
        end
    end
end

local function getActiveRigsFolders()
    local result = {}
    for _, child in ipairs(workspace:GetChildren()) do
        if child.Name == "Rigs" and #child:GetChildren() > 0 then
            table.insert(result, child)
        end
    end
    return result
end

local function unloadAll(accessories)
    for _, acc in ipairs(accessories) do if acc and acc.Parent then acc:Destroy() end end
    table.clear(accessories)
end

local function applyToOwnRigInFolder(folder)
    if not folder then return end
    local rig = folder:FindFirstChild(game.Players.LocalPlayer.Name)
    if not rig then return end

    for _, asset in ipairs(FROZEN_ASSETS) do
        local ok, result = pcall(function() return game:GetObjects("rbxassetid://" .. asset.id)[1] end)
        if ok and result then
            attachToRig(rig, result, asset.extraY)
            table.insert(frozenHornsAccessories, result)
        end
    end
end

local function applyToAllActiveRigs()
    if not frozenHornsEnabled then return end
    unloadAll(frozenHornsAccessories)
    for _, rigsFolder in ipairs(getActiveRigsFolders()) do
        applyToOwnRigInFolder(rigsFolder)
    end
end

local function setFrozenHorns(state)
    frozenHornsEnabled = state
    if state then
        applyToAllActiveRigs()
        if #frozenHornsAccessories == 0 then
            Fluent:Notify({ Title = "Frozen Horns", Content = "Failed to load", Duration = 3 })
            frozenHornsEnabled = false
            task.spawn(function() task.wait(); if FrozenHornsToggleObject then Options["FrozenHorns"]:SetValue(false) end end)
            return
        end
    else
        unloadAll(frozenHornsAccessories)
    end
end

if _G.FrozenHornsCharConn then
    _G.FrozenHornsCharConn:Disconnect()
    _G.FrozenHornsCharConn = nil
end

_G.FrozenHornsCharConn = game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.01)
    task.defer(applyToAllActiveRigs)
end)

FrozenHornsToggleObject = VisualTab:AddToggle("FrozenHorns", {
    Title = "Frozen Horns of the Frigid Planes",
    Default = false,
    Callback = function(value)
        if value == frozenHornsEnabled then return end
        setFrozenHorns(value)
    end,
})
end)

VisualTab:AddToggle("HeadlessToggle", {
   Title = "Headless",
   Default = false,
   Callback = function(Value)
      headlessEnabled = Value
      applyToAllActiveRigs()
   end,
})
 
KorbloxRightToggleObject = VisualTab:AddToggle("KorbloxRightToggle", {
    Title = "Korblox right leg",
    Default = false,
    Callback = function(Value)
        if Value == korbloxRightEnabled then return end
        korbloxRightEnabled = Value
        applyToAllActiveRigs()
    end,
})
 
KorbloxLeftToggleObject = VisualTab:AddToggle("KorbloxLeftToggle", {
    Title = "Korblox left leg",
    Default = false,
    Callback = function(Value)
        if Value == korbloxLeftEnabled then return end
        korbloxLeftEnabled = Value
        applyToAllActiveRigs()
    end,
})

local FullbrightToggleObject = VisualTab:AddToggle("FullbrightToggle", {
   Title = "Fullbright",
   Default = false,
   Callback = function(Value)
      fullbrightEnabled = Value
      if Value then
          applyFullbright()
      else
          restoreFullbright()
      end
   end,
})

pcall(function()
local optimizeEnabled = false
local OptimizeToggleObject = nil
local hiddenObjects = {}
local hiddenLights = {}
local hiddenTerrainDecoration = nil
local gcLightsCache = nil

local destroyedLightsBackup = {}
local lightsAddedConnections = {}

local MAP_REMOVE_NAMES = {
    "walldeco","window1","macete","painting","prueba3","deco1","figure1","figura2","figure5",
    "pen","plant 1","plant","sprayer","flower","flowerbowl","jar","radiomusic","rat trap",
    "nomopoly","book_03","ropa cochina","ropa cochina2","soap dispenser","books 1","bottle2",
    "bottle4","cobweb","cobweb_a","cobweb_b","coffee mug","books","books 2","book",
    "freddy plush","groundedreceptacleoutlet","old books","pc","plant 01a","squeezepouch",
    "feet_009_u_mesh","dogfoodbowls","boardgame2","pot","water","waterfalllower","fakegrass",
    "puddle","pebbles","barrel fire","crate","crate1","crate4","crate4long",
    "crate1long","dock pole","lava","soda bottle","trashcan","trash dumpster",
    "trash dumpster 02a","bobo boombox","krustykrab01","kitchen_shelf001a","keyboard",
    "poster","elysiumposter","mouse","monitor","mousepad","phone","printer","radio",
    "portrait","ac","shelf","fridge", "WindowModel", "window3", "window 2", "Yosemite-National-Park",
    "MousePad", "pen", "pen_metal", "paper", "BoardGame5", "BoardGame3", "BoardGame2", "Meshes/CardDeck",
    "book_03", "book", "Nomopoly", "Books 1", "Books 2", "Old Books", "Meshes/vinyl", "ropa cochina", "ropa cochina2",
    "Detritus_B", "Detritus_A", "Plant 01a", "BoardGame6", "DogFoodBowls", "Dr. Robotnik in pajamas",
    "GroundedReceptacleOutlet", "sock", "SqueezePouch", "HydrogenPeroxideBottleBin", "soap dispenser",
    "Meshes/toothbrush", "Meshes/Medkit3", "Meshes/Medkit4", "Meshes/lotion_sweet_apple_LG_LOD00", "Sprayer",
    "soap", "plant 01", "Button", "Window1", "LargePaperDoor", "prueba3", "painting", "bookshelf large",
    "macete", "closet", "Route 66 Sign", "Window",
    "Pipe", "Metal Shelve", "RoadLine", "solid_2494", "Bookshelf 1", "Bathroom Sink Drain",
    "Station Sign", "Bobo's Pizza", "Nitro Bomb Crate", "ParkingLot", "Shoe Box", "Subway Sign",
    "Old Image", "Storage Thingy", "building(mesh)", "Big Door", "Mesh building",
    "Meshes/fixedextrudedgrass1", "Graffiti", "Leaves Image", "TreeBac", "TrackSection",
    "Scrapyard Dumpster", "BackgroundTrees", "Treebox", "tree", 'Bush1', 'Bush1Fake',
}

local IMMOVABLE_REMOVE_NAMES = {
    "bush","big bush","hev_case","miniteleport","servers","bloxy","microwave","top",
    "file cabinet 3","computer01_keyboard","partsbin01","monitor02","plotter","powerbox02c",
    "powerbox01a","powerbox02a","binderredlabel","locker","garage shelf","fan",
    "bathroom sink drain","trash","pushcart","extrasmall crate","tyre pile",
    "planterbase_largesquare_var01","droppedtires","cooler","bucket tools","fuel cask",
    "prison bracket","electrical box 1","nitro bomb crate","haultruck","potted_plant",
    "small bookcase","p2","shelf","fridge","lab counter","orange banner","boxes","egg",
    "elgato","warehouse shelf 1","hotell_luggage","hotel_laundry_cart001_0",
    "kitchen_shelf001a","scaffolding","sandcastle", "Rug001a", "green rug", "Bookshelf 1",
    "Floor Lamp","Portrait Painting E", "Portrait Painting D", "Portrait Painting G", "console table",
    "wood__staff:wooden_chair_001_0", "table", "pantry", "sofa", "sofa chair", "BoxFlowers",
    "elysiumlogo", "Chair2", "Button", "CubeTabe", "ExtendedChair", "WetFloorCone", "PalmTree3",
    "PalmTree2", "PalmTree1", "Window1", "wood shelf", "prueba3", "bookshelf large", "closet",
    "Warehouse Shelf 4", "Warehouse Shelf 5", "Warehouse Shelf 3", "Warehouse Shelf 2", "Warehouse Shelf 1",
    "Warehouse Shelf 6", "Chicken", "Meshes/Sheep (1)", "Meshes/cow (1)", "UFO Stuff",
    "powertower01", "CompanyName", "CompanyFullName", "CompanyNameShortened", "Copy Machine",
    "Egg", "Clock", "AC", "Chairs", "Clipboard", "Gun Cabinet 1", "Vending Machine", "Couch",
    "Desk", "Equipment 1", "Meshes/70desk", "Meshes/Com_Book11", "Meshes/chair70",
    "Warehouse Shelf 1 (New)", "Meshes/Chair", "tree",
}

local PARTS_REMOVE_NAMES = {
    "planterbase_largesquare_var01","fakedoor",
}

local FOLIAGE_FOLDERS = {"bushes","grass","trees","bobo sightings"}

local CAMERA_REMOVE_NAMES = {"rain","snow","thunderstorm"}

local function normName(name)
    return name:lower():gsub("%s+","")
end

local function shouldRemove(obj, nameList)
    if not (obj:IsA("MeshPart") or obj:IsA("Model") or obj:IsA("BasePart") or obj:IsA("UnionOperation")) then
        return false
    end
    local n = normName(obj.Name)
    for _, v in ipairs(nameList) do
        if n == normName(v) then return true end
    end
    return false
end

local function disableLightInstance(obj, processedLights)
    if processedLights[obj] then return end

    if obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") or obj:IsA("Light") then
        processedLights[obj] = true
        local prevEnabled = obj.Enabled
        pcall(function() obj.Enabled = false end)
        table.insert(hiddenLights, {instance = obj, enabled = prevEnabled})
        return
    end

    if obj:IsA("Beam") then
        processedLights[obj] = true
        local prevEnabled = obj.Enabled
        pcall(function() obj.Enabled = false end)
        table.insert(hiddenLights, {instance = obj, enabled = prevEnabled})
        return
    end

    if obj:IsA("Decal") or obj:IsA("Texture") then
        processedLights[obj] = true
        local prevTransparency = obj.Transparency
        pcall(function() obj.Transparency = 1 end)
        table.insert(hiddenLights, {instance = obj, transparency = prevTransparency})
        return
    end

    if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
        processedLights[obj] = true
        local prevEnabled = obj.Enabled
        pcall(function() obj.Enabled = false end)
        table.insert(hiddenLights, {instance = obj, enabled = prevEnabled})
        return
    end

    if obj:IsA("SurfaceGui") or obj:IsA("BillboardGui") then
        processedLights[obj] = true
        local prevEnabled = obj.Enabled
        pcall(function() obj.Enabled = false end)
        table.insert(hiddenLights, {instance = obj, enabled = prevEnabled})
        return
    end

    if obj:IsA("GuiObject") then
        processedLights[obj] = true
        local prevVisible = obj.Visible
        pcall(function() obj.Visible = false end)
        table.insert(hiddenLights, {instance = obj, visible = prevVisible})
        return
    end
end

local function disableLightsIn(obj, processedLights)
    if not obj then return end
    disableLightInstance(obj, processedLights)
    if obj.GetDescendants then
        for _, d in ipairs(obj:GetDescendants()) do
            disableLightInstance(d, processedLights)
        end
    end
end

local function hideObject(obj, processed, processedLights)
    local saved = {}
    if obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("UnionOperation") then
        if not processed[obj] then
            processed[obj] = true
            saved[obj] = obj.Transparency
            pcall(function() obj.Transparency = 1 end)
        end
        if processedLights then disableLightsIn(obj, processedLights) end
    elseif obj:IsA("Model") then
        for _, d in ipairs(obj:GetDescendants()) do
            if (d:IsA("BasePart") or d:IsA("MeshPart") or d:IsA("UnionOperation")) and not processed[d] then
                processed[d] = true
                saved[d] = d.Transparency
                pcall(function() d.Transparency = 1 end)
            end
        end
        if processedLights then disableLightsIn(obj, processedLights) end
    elseif processedLights then
        disableLightsIn(obj, processedLights)
    end
    return saved
end

local function hideFromFolder(folder, nameList, processed, processedLights)
    if not folder then return end
    for _, obj in ipairs(folder:GetChildren()) do
        if shouldRemove(obj, nameList) then
            local transp = hideObject(obj, processed, processedLights)
            if next(transp) ~= nil then
                table.insert(hiddenObjects, {transparencies = transp})
            end
        end
    end
end

local function destroyLightChild(obj)
    if not obj or not obj.Parent then return end

    local ok, clone = pcall(function() return obj:Clone() end)
    if ok and clone then
        table.insert(destroyedLightsBackup, {
            clone = clone,
            parent = obj.Parent,
            name = obj.Name,
        })
    end

    pcall(function() obj:Destroy() end)
end

local function destroyAllLightsChildren(Lights)
    if not Lights then return end
    for _, child in ipairs(Lights:GetChildren()) do
        destroyLightChild(child)
    end
end

local function hookLightsChildAdded(Lights)
    if not Lights then return end
    local conn = Lights.ChildAdded:Connect(function(child)
        if not optimizeEnabled then return end
        destroyLightChild(child)
    end)
    table.insert(lightsAddedConnections, conn)
end

local function isUnderLights(inst)
    local current = inst
    local depth = 0
    while current and depth < 12 do
        if current:IsA("Folder") or current:IsA("Model") then
            if normName(current.Name) == "lights" then
                return true
            end
        end
        current = current.Parent
        depth += 1
    end
    return false
end

local function collectLightsViaGC()
    local found = {}
    local seen = {}
    local ok, gcTable = pcall(function() return getgc(true) end)
    if not ok or not gcTable then return found end

    for _, v in ipairs(gcTable) do
        if type(v) == "table" and not seen[v] then
            local okInst, inst = pcall(function() return v.Instance end)
            if okInst and typeof(inst) == "Instance" then
                v = inst
            end
        end
        if typeof(v) == "userdata" or typeof(v) == "Instance" then
            local okIsA, isInstance = pcall(function() return typeof(v) == "Instance" end)
            if okIsA and isInstance and not seen[v] then
                local okClass, isLightLike = pcall(function()
                    return v:IsA("Light") or v:IsA("Beam") or v:IsA("ParticleEmitter")
                        or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles")
                        or v:IsA("Trail") or v:IsA("SurfaceGui") or v:IsA("BillboardGui")
                        or v:IsA("Decal") or v:IsA("Texture")
                        or ((v:IsA("BasePart") or v:IsA("MeshPart") or v:IsA("UnionOperation")) and v.Material == Enum.Material.Neon)
                end)
                if okClass and isLightLike then
                    local okParent, underLights = pcall(isUnderLights, v)
                    if okParent and underLights then
                        seen[v] = true
                        table.insert(found, v)
                    end
                end
            end
        end
    end

    return found
end

local function hideFoliageFolderChildren(mapFolder, processed, processedLights)
    if not mapFolder then return end
    for _, folderName in ipairs(FOLIAGE_FOLDERS) do
        local folder = mapFolder:FindFirstChild(folderName)
        if folder then
            for _, child in ipairs(folder:GetChildren()) do
                local transp = hideObject(child, processed, processedLights)
                if next(transp) ~= nil then
                    table.insert(hiddenObjects, {transparencies = transp})
                end
            end
        end
    end
end

local function hideCameraWeather(processed, processedLights)
    local camera = workspace.CurrentCamera
    if not camera then return end
    for _, obj in ipairs(camera:GetChildren()) do
        if obj:IsA("MeshPart") then
            local n = normName(obj.Name)
            for _, v in ipairs(CAMERA_REMOVE_NAMES) do
                if n == normName(v) then
                    local transp = hideObject(obj, processed, processedLights)
                    if next(transp) ~= nil then
                        table.insert(hiddenObjects, {transparencies = transp})
                    end
                    break
                end
            end
        end
    end
end

local function hideWallDeco(mapFolder, processed, processedLights)
    local decoNames = {"walldeco","window1","macete","painting","prueba3","deco1","figure1","figura2","figure5"}
    if not mapFolder then return end
    for _, obj in ipairs(mapFolder:GetDescendants()) do
        local n = normName(obj.Name)
        for _, v in ipairs(decoNames) do
            if n == normName(v) then
                if obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("UnionOperation") then
                    local transp = hideObject(obj, processed, processedLights)
                    if next(transp) ~= nil then
                        table.insert(hiddenObjects, {transparencies = transp})
                    end
                end
                break
            end
        end
    end
end

local function applyOptimizations()
    hiddenObjects = {}
    hiddenLights = {}
    destroyedLightsBackup = {}
    local processed = {}
    local processedLights = {}

    local ok, Parts = pcall(function() return workspace.Map.Parts end)
    if not ok or not Parts then return end

    local Map        = Parts:FindFirstChild("Map")
    local Immovable  = Parts:FindFirstChild("ImmovableProps")
    local WaterFolder = Parts:FindFirstChild("Water")
    local Lights     = Parts:FindFirstChild("Lights")

    hideFromFolder(Map, MAP_REMOVE_NAMES, processed, processedLights)
    hideFromFolder(Immovable, IMMOVABLE_REMOVE_NAMES, processed, processedLights)
    hideFromFolder(Parts, PARTS_REMOVE_NAMES, processed, processedLights)

    if WaterFolder then
        for _, child in ipairs(WaterFolder:GetChildren()) do
            local transp = hideObject(child, processed, processedLights)
            if next(transp) ~= nil then
                table.insert(hiddenObjects, {transparencies = transp})
            end
        end
    end

    if Lights then
        destroyAllLightsChildren(Lights)
        hookLightsChildAdded(Lights)
    end

    gcLightsCache = collectLightsViaGC()
    for _, obj in ipairs(gcLightsCache) do
        pcall(isUnderLights, obj)
        destroyLightChild(obj)
    end
    gcLightsCache = nil

    hideFoliageFolderChildren(Map, processed, processedLights)

    pcall(function()
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            hiddenTerrainDecoration = terrain.Decoration
            terrain.Decoration = false
        end
    end)

    hideCameraWeather(processed, processedLights)
    hideWallDeco(Map, processed, processedLights)

    pcall(function()
        for _, effect in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if effect:IsA("BlurEffect") or effect:IsA("DepthOfFieldEffect")
                or effect:IsA("SunRaysEffect") or effect:IsA("BloomEffect") then
                    effect.Enabled = false
                end
            end)
        end
    end)

    pcall(function()
        local ignore = workspace.Map:FindFirstChild("Ignore")
        if not ignore then return end
        for _, child in ipairs(ignore:GetDescendants()) do
            local transp = hideObject(child, processed, processedLights)
            if next(transp) ~= nil then
                table.insert(hiddenObjects, {transparencies = transp})
            end
        end
    end)

    Fluent:Notify({ Title = "Optimizer", Content = "Enabled - " .. #hiddenObjects .. " objects hidden, " .. #destroyedLightsBackup .. " lights removed", Duration = 2})
end

local function removeOptimizations()
    for _, conn in ipairs(lightsAddedConnections) do
        pcall(function() conn:Disconnect() end)
    end
    lightsAddedConnections = {}

    for _, data in ipairs(hiddenObjects) do
        if data.transparencies then
            for part, t in pairs(data.transparencies) do
                if part and part.Parent then
                    pcall(function() part.Transparency = t end)
                end
            end
        end
    end
    hiddenObjects = {}
    hiddenLights = {}

    for _, backup in ipairs(destroyedLightsBackup) do
        pcall(function()
            if backup.parent then
                backup.clone.Parent = backup.parent
            end
        end)
    end
    destroyedLightsBackup = {}

    pcall(function()
        if hiddenTerrainDecoration ~= nil then
            local terrain = workspace:FindFirstChildOfClass("Terrain")
            if terrain then
                terrain.Decoration = hiddenTerrainDecoration
            end
            hiddenTerrainDecoration = nil
        end
    end)

    pcall(function()
        for _, effect in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if effect:IsA("BlurEffect") or effect:IsA("DepthOfFieldEffect")
                or effect:IsA("SunRaysEffect") or effect:IsA("BloomEffect") then
                    effect.Enabled = true
                end
            end)
        end
    end)

    Fluent:Notify({ Title = "Optmizer", Content = "Disabled", Duration = 2})
end

local function setOptimize(state)
    if state == optimizeEnabled then return end
    optimizeEnabled = state
    if state then
        applyOptimizations()
    else
        removeOptimizations()
    end
end

OptimizeToggleObject = VisualTab:AddToggle("OptimizerToggle", {
    Title = "Optimize game",
    Default = false,
    Callback = function(value)
        setOptimize(value)
    end,
})
end)

pcall(function()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Lighting = game:GetService("Lighting")

local HiddenElements = {
    {root = CoreGui,            path = {"TopBarApp", "TopBarApp", "UnibarLeftFrame", "UnibarMenu"}},
    {root = CoreGui,            path = {"TopBarApp", "TopBarApp", 'MenuIconHolder'}},
    {root = CoreGui,            path = {"TopBarApp", "TopBarApp", "UnibarLeftFrame", 'TopBarLeftContainer'}},
    {root = PlayerGui,          path = {"Game"},    recursive = true},
    {root = PlayerGui,          path = {"Shared"},  recursive = true},
    {root = PlayerGui,          path = {"Shared", "Popups", "Vote"}},
    {root = PlayerGui,          path = {"Shared", "Popups", "VoteActive"}},
    {root = PlayerGui,          path = {"Shared", "GenericPopup"}},
    {root = PlayerGui,          path = {"Shared", "GameUpdated"}},
    {root = PlayerGui,          path = {"Shared", "Notifications"}},
}

local ExcludedPaths = {
    {root = PlayerGui, path = {"Shared", "Centered"}},
}

local HiderActive = false
local VoteBlurConn = nil
local originalPositions = {}

local function resolvePath(root, path)
    local current = root
    for _, name in ipairs(path) do
        current = current:FindFirstChild(name)
        if not current then return nil end
    end
    return current
end

local function pathStartsWith(root, path, excl)
    if excl.root ~= root then return false end
    for i, name in ipairs(excl.path) do
        if path[i] ~= name then return false end
    end
    return true
end

local function isExcluded(root, path)
    for _, excl in ipairs(ExcludedPaths) do
        if pathStartsWith(root, path, excl) then return true end
    end
    return false
end

local function setHidden(inst, hide, key)
    if not inst or not inst:IsA("GuiObject") then return end

    if hide then
        if not originalPositions[key] then
            originalPositions[key] = inst.Position
        end
        inst.Position = UDim2.new(99, 0, 99, 0)
    else
        if originalPositions[key] then
            inst.Position = originalPositions[key]
            originalPositions[key] = nil
        end
    end
end

local function applyRecursive(root, basePath, inst, hide)
    for _, child in ipairs(inst:GetChildren()) do
        local childPath = table.clone(basePath)
        table.insert(childPath, child.Name)

        if not isExcluded(root, childPath) then
            local key = root:GetFullName() .. "/" .. table.concat(childPath, "/")
            setHidden(child, hide, key)
        end
    end
end

local function applyHideState(hide)
    for i, entry in ipairs(HiddenElements) do
        if not isExcluded(entry.root, entry.path) then
            local inst = resolvePath(entry.root, entry.path)
            if inst then
                if entry.recursive then
                    applyRecursive(entry.root, entry.path, inst, hide)
                else
                    setHidden(inst, hide, i)
                end
            end
        end
    end
end

local function killVoteBlur()
    local vb = Lighting:FindFirstChild("VoteBlur")
    if vb then
        vb:Destroy()
    end
end

local function setVoteBlurBlock(active)
    if active then
        if not VoteBlurConn then
            VoteBlurConn = Lighting.ChildAdded:Connect(function(child)
                if child.Name == "VoteBlur" then
                    task.defer(function()
                        pcall(killVoteBlur)
                    end)
                end
            end)
        end
        pcall(killVoteBlur)
    else
        if VoteBlurConn then
            VoteBlurConn:Disconnect()
            VoteBlurConn = nil
        end
    end
end

task.spawn(function()
    while true do
        if HiderActive then
            pcall(function()
                applyHideState(true)
            end)
        end
        task.wait(0.5)
    end
end)

VisualTab:AddToggle("HideHUDElementsToggle", {
    Title = "Hide HUD Elements",
    Default = false,
    Callback = function(Value)
        HiderActive = Value
        setVoteBlurBlock(Value)
        if not Value then
            pcall(applyHideState, false)
        else
            pcall(applyHideState, true)
        end
    end,
})
end)

pcall(function()
local colaAnimEnabled = false
local colaAnimTrack = nil
local colaAnimObj = nil
local ColaAnimToggleObject = nil
local colaLoop = nil
local triggered = false
local sessionId = 0
local savedSoundVolumes = {}

local COLA_ANIM_ID = "rbxassetid://72451312796377"
local SOUND_IDS = {
    Open  = "rbxassetid://6911756259",
    Drink = "rbxassetid://6911756959",
    Throw = "rbxassetid://608509471",
}

local COLA_SOUND_IDS = {
    ["6911756959"] = true,
    ["6911756259"] = true,
    ["608509471"]  = true,
    ["6457617769"] = true,
}

local function isColaTool(model)
    local handle = model:FindFirstChild("Handle", true)
    if not handle then return false end
    for _, v in ipairs(handle:GetChildren()) do
        if v:IsA("Sound") then
            local id = v.SoundId:match("%d+")
            if id and COLA_SOUND_IDS[id] then
                return true
            end
        end
    end
    return false
end

local function muteOriginalSounds()
    local variants = game:GetService("ReplicatedStorage"):FindFirstChild("Tools")
    if not variants then return end
    local cola = variants:FindFirstChild("Cola")
    if not cola then return end
    local variantsFolder = cola:FindFirstChild("Variants")
    if not variantsFolder then return end

    savedSoundVolumes = {}
    for _, skinFolder in ipairs(variantsFolder:GetChildren()) do
        local char = skinFolder:FindFirstChild("Character")
        if char then
            local tool = char:FindFirstChild("Tool")
            if tool then
                local handle = tool:FindFirstChild("Handle")
                if handle then
                    for _, sound in ipairs(handle:GetChildren()) do
                        if sound:IsA("Sound") then
                            savedSoundVolumes[sound] = sound.Volume
                            sound.Volume = 0
                        end
                    end
                end
            end
        end
    end
end

local function unmuteOriginalSounds()
    for sound, vol in pairs(savedSoundVolumes) do
        if sound and sound.Parent then
            sound.Volume = vol
        end
    end
    savedSoundVolumes = {}
end

local function playSound(soundId, duration)
    local char = game.Players.LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = 0.4
    sound.Parent = hrp
    sound:Play()
    if duration then
        task.delay(duration, function()
            if sound and sound.Parent then
                sound:Stop()
                sound:Destroy()
            end
        end)
    else
        game:GetService("Debris"):AddItem(sound, 5)
    end
end

local function stopColaAnim()
    sessionId = sessionId + 1
    if colaAnimTrack and colaAnimTrack.IsPlaying then
        colaAnimTrack:Stop(0.3)
    end
    colaAnimTrack = nil
    if colaAnimObj then
        pcall(function() colaAnimObj:Destroy() end)
        colaAnimObj = nil
    end
    triggered = false
end

local function startColaAnim()
    local char = game.Players.LocalPlayer.Character
    if not char then triggered = false return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if not animator then triggered = false return end

    sessionId = sessionId + 1
    local mySession = sessionId

    if colaAnimTrack and colaAnimTrack.IsPlaying then
        colaAnimTrack:Stop(0)
    end
    if colaAnimObj then
        pcall(function() colaAnimObj:Destroy() end)
        colaAnimObj = nil
    end

    playSound(SOUND_IDS.Open)

    local anim = Instance.new("Animation")
    anim.AnimationId = COLA_ANIM_ID
    anim.Parent = char
    colaAnimObj = anim

    colaAnimTrack = animator:LoadAnimation(anim)
    colaAnimTrack.Priority = Enum.AnimationPriority.Action4
    colaAnimTrack.Looped = false
    colaAnimTrack:Play(0)
    colaAnimTrack:AdjustSpeed(1.1)

    local animLength = colaAnimTrack.Length / 1.1

    task.delay(0.6, function()
        if sessionId ~= mySession then return end
        if not colaAnimEnabled then return end
        playSound(SOUND_IDS.Drink, 2.5)
    end)

    task.delay(math.max(0.1, animLength - 0.8), function()
        if sessionId ~= mySession then return end
        if not colaAnimEnabled then return end
        playSound(SOUND_IDS.Throw, 0.8)
    end)

    colaAnimTrack.Stopped:Connect(function()
        if sessionId ~= mySession then return end
        pcall(function() anim:Destroy() end)
        colaAnimObj = nil
        colaAnimTrack = nil
        task.delay(0.5, function()
            if sessionId == mySession then
                triggered = false
            end
        end)
    end)
end

local function setupWatcher()
    if colaLoop then
        colaLoop:Disconnect()
        colaLoop = nil
    end

    local playersFolder = workspace:FindFirstChild("Game")
    if not playersFolder then return end
    playersFolder = playersFolder:FindFirstChild("Players")
    if not playersFolder then return end
    local playerFolder = playersFolder:FindFirstChild(game.Players.LocalPlayer.Name)
    if not playerFolder then return end

    colaLoop = playerFolder.ChildAdded:Connect(function(child)
        if not colaAnimEnabled then return end
        if child.Name == "Tool" and child:IsA("Model") then
            if triggered then return end
            task.wait(0.05)
            if not isColaTool(child) then return end
            triggered = true
            task.spawn(startColaAnim)
        end
    end)
end

local function reapply()
    if not colaAnimEnabled then return end
    colaAnimTrack = nil
    colaAnimObj = nil
    triggered = false
    sessionId = sessionId + 1
    task.wait(0.3)
    if not colaAnimEnabled then return end
    muteOriginalSounds()
    setupWatcher()
end

local function setColaAnim(state)
    if state == colaAnimEnabled then return end
    colaAnimEnabled = state

    if state then
        triggered = false
        muteOriginalSounds()
        setupWatcher()
        Fluent:Notify({ Title = "Cola Animation", Content = "Enabled", Duration = 2 })
    else
        if colaLoop then
            colaLoop:Disconnect()
            colaLoop = nil
        end
        stopColaAnim()
        unmuteOriginalSounds()
        Fluent:Notify({ Title = "Cola Animation", Content = "Disabled", Duration = 2 })
    end

    task.spawn(function()
        task.wait()
        syncToggle(ColaAnimToggleObject, colaAnimEnabled)
    end)
end

game.Players.LocalPlayer.CharacterAdded:Connect(function()
    task.spawn(reapply)
end)

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    task.spawn(reapply)
end)

ColaAnimToggleObject = VisualTab:AddToggle("ForceColaUse", {
    Title = "Fixed cola animation",
    Default = false,
    Callback = function(value)
        if value == colaAnimEnabled then return end
        setColaAnim(value)
    end,
})
end)

do 
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local avatarChangerEnabled = false
local AvatarChangerToggleObject = nil
local avatarAppliedOnce = false
local avatarInputBox = nil
local targetUserId = ""
local avatarCharacterAddedConn = nil
local attributeConnsHS = {}
local renderConn = nil
local rigsWatcherConns = {}
local appliedDupeInstances = setmetatable({}, { __mode = "k" })

local storageFolder = ReplicatedStorage:FindFirstChild("HiddenAccessories")
if not storageFolder then
    storageFolder = Instance.new("Folder")
    storageFolder.Name = "HiddenAccessories"
    storageFolder.Parent = ReplicatedStorage
end

local ACCESSORY_ATTACHMENT_MAP = {
    [Enum.AccessoryType.Hat] = { bodyPart = "Head", attachmentName = "HatAttachment" },
    [Enum.AccessoryType.Hair] = { bodyPart = "Head", attachmentName = "HairAttachment" },
    [Enum.AccessoryType.Face] = { bodyPart = "Head", attachmentName = "FaceFrontAttachment" },
    [Enum.AccessoryType.Neck] = { bodyPart = "Torso", attachmentName = "NeckAttachment" },
    [Enum.AccessoryType.Shoulder] = { bodyPart = "Torso", attachmentName = "RightShoulderAttachment" },
    [Enum.AccessoryType.Front] = { bodyPart = "Torso", attachmentName = "FrontAttachment" },
    [Enum.AccessoryType.Back] = { bodyPart = "Torso", attachmentName = "BackAttachment" },
    [Enum.AccessoryType.Waist] = { bodyPart = "Torso", attachmentName = "WaistCenterAttachment" },
    [Enum.AccessoryType.Eyebrow] = { bodyPart = "Head", attachmentName = "FaceFrontAttachment" },
    [Enum.AccessoryType.Eyelash] = { bodyPart = "Head", attachmentName = "FaceFrontAttachment" },
    [Enum.AccessoryType.TShirt] = { bodyPart = "Torso", attachmentName = "BodyFrontAttachment" },
    [Enum.AccessoryType.Shirt] = { bodyPart = "Torso", attachmentName = "BodyFrontAttachment" },
    [Enum.AccessoryType.Pants] = { bodyPart = "Torso", attachmentName = "BodyFrontAttachment" },
    [Enum.AccessoryType.Unknown] = { bodyPart = "Head", attachmentName = "HatAttachment" },
}

local ATTACHMENT_TO_BODYPART = {
    HatAttachment = "Head",
    HairAttachment = "Head",
    FaceFrontAttachment = "Head",
    FaceCenterAttachment = "Head",
    NeckAttachment = "Torso",
    BodyFrontAttachment = "Torso",
    BodyBackAttachment = "Torso",
    FrontAttachment = "Torso",
    BackAttachment = "Torso",
    WaistCenterAttachment = "Torso",
    WaistFrontAttachment = "Torso",
    WaistBackAttachment = "Torso",
    LeftCollarAttachment = "Torso",
    RightCollarAttachment = "Torso",
    LeftShoulderAttachment = "Left Arm",
    RightShoulderAttachment = "Right Arm",
    LeftGripAttachment = "Left Arm",
    RightGripAttachment = "Right Arm",
}

local R6_ATTACHMENT_OFFSETS = {
    HatAttachment = CFrame.new(0, 0.5, 0),
    HairAttachment = CFrame.new(0, 0.5, 0),
    FaceFrontAttachment = CFrame.new(0, 0, -0.6),
    FaceCenterAttachment = CFrame.new(0, 0, -0.6),
    NeckAttachment = CFrame.new(0, 1, 0),
    RightShoulderAttachment = CFrame.new(1, 0.5, 0),
    LeftShoulderAttachment = CFrame.new(-1, 0.5, 0),
    RightGripAttachment = CFrame.new(1, -1, 0),
    LeftGripAttachment = CFrame.new(-1, -1, 0),
    FrontAttachment = CFrame.new(0, 0.5, -0.5),
    BackAttachment = CFrame.new(0, 0.5, 0.5),
    BodyBackAttachment = CFrame.new(0, 0.5, 0.5),
    WaistCenterAttachment = CFrame.new(0, -1, 0),
    WaistFrontAttachment = CFrame.new(0, -1, -0.5),
    WaistBackAttachment = CFrame.new(0, -1, 0.5),
    LeftCollarAttachment = CFrame.new(-0.5, 1, 0),
    RightCollarAttachment = CFrame.new(0.5, 1, 0),
    BodyFrontAttachment = CFrame.new(0, 0, -0.5),
}

local function restoreAllStoredAccessories()
    local character = LocalPlayer.Character
    if not character then return end
    for _, child in ipairs(storageFolder:GetChildren()) do
        if child:GetAttribute("Owner") == LocalPlayer.Name then
            child.Parent = character
        end
    end
end

local function stopRenderLoop()
    if renderConn then
        pcall(function()
            RunService:UnbindFromRenderStep("AvatarChangerFirstPersonFix")
        end)
        renderConn = nil
    end
    
    pcall(function()
        if LocalPlayer.Character then
            local head = LocalPlayer.Character:FindFirstChild("Head")
            if head then 
                head.Transparency = 0 
                head.LocalTransparencyModifier = 0 
                local face = head:FindFirstChild("face")
                if face then face.Transparency = 0 end
            end
        end
        for _, folder in ipairs(workspace:GetChildren()) do
            if folder.Name == "Rigs" then
                local rig = folder:FindFirstChild(LocalPlayer.Name)
                if rig then
                    local head = rig:FindFirstChild("Head")
                    if head then 
                        head.Transparency = 0 
                        head.LocalTransparencyModifier = 0 
                        local face = head:FindFirstChild("face")
                        if face then face.Transparency = 0 end
                    end
                end
            end
        end
    end)
    
    restoreAllStoredAccessories()
end

local HEAD_ACCESSORY_TYPES = {
    [Enum.AccessoryType.Hat] = true,
    [Enum.AccessoryType.Hair] = true,
    [Enum.AccessoryType.Face] = true,
    [Enum.AccessoryType.Eyebrow] = true,
    [Enum.AccessoryType.Eyelash] = true,
    [Enum.AccessoryType.Unknown] = true,
}

local function isHeadAccessory(accessory, headPart)
    local ok, accessoryType = pcall(function() return accessory.AccessoryType end)
    if ok and accessoryType and HEAD_ACCESSORY_TYPES[accessoryType] then
        return true
    end

    local handle = accessory:FindFirstChild("Handle")
    if not handle then return false end

    for _, joint in ipairs(handle:GetChildren()) do
        if (joint:IsA("Weld") or joint:IsA("Motor6D")) then
            if joint.Part0 == headPart or joint.Part1 == headPart then
                return true
            end
        end
    end

    local attachment = handle:FindFirstChildWhichIsA("Attachment")
    if attachment and ATTACHMENT_TO_BODYPART[attachment.Name] == "Head" then
        return true
    end
    
    if (handle.Position - headPart.Position).Magnitude < 4 then
        return true
    end

    return false
end

local FIRST_PERSON_DISTANCE = 2.18

local function setHeadAccessoriesTransparency(character, head, value)
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Accessory") or child:IsA("Hat") then
            if isHeadAccessory(child, head) then
                for _, part in ipairs(child:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Transparency = value
                        part.LocalTransparencyModifier = value
                    elseif part:IsA("Decal") or part:IsA("Texture") then
                        part.Transparency = value
                    end
                end
            end
        end
    end
end

local function getActiveRigsFolders()
    local result = {}
    for _, child in ipairs(workspace:GetChildren()) do
        if child.Name == "Rigs" and #child:GetChildren() > 0 then
            table.insert(result, child)
        end
    end
    return result
end

local function startRenderLoop()
    stopRenderLoop()
    
    RunService:BindToRenderStep("AvatarChangerFirstPersonFix", Enum.RenderPriority.Last.Value, function()
        local camera = workspace.CurrentCamera
        if not camera then return end

        local targets = {}
        if LocalPlayer.Character then
            table.insert(targets, LocalPlayer.Character)
        end
        
        for _, folder in ipairs(getActiveRigsFolders()) do
            local rig = folder:FindFirstChild(LocalPlayer.Name)
            if rig and rig:IsA("Model") then
                table.insert(targets, rig)
            end
        end

        for _, character in ipairs(targets) do
            local head = character:FindFirstChild("Head")
            if head then
                local distance = (camera.CFrame.Position - head.Position).Magnitude
                local isFirstPerson = (distance < FIRST_PERSON_DISTANCE)
                
                if isFirstPerson then
                    head.Transparency = 1
                    head.LocalTransparencyModifier = 1
                    
                    local face = head:FindFirstChild("face")
                    if face and face:IsA("Decal") then
                        face.Transparency = 1
                    end
                    
                    setHeadAccessoriesTransparency(character, head, 1)
                else
                    head.Transparency = 0
                    head.LocalTransparencyModifier = 0
                    
                    local face = head:FindFirstChild("face")
                    if face and face:IsA("Decal") then
                        face.Transparency = 0
                    end
                    
                    setHeadAccessoriesTransparency(character, head, 0)
                end
            end
        end
    end)
    renderConn = true
end

local function clearOldCosmetics(character)
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("CharacterMesh") or child:IsA("Accessory") or child:IsA("Hat")
            or child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic")
            or child:IsA("BodyColors") then
            child:Destroy()
        end
    end
    for _, child in ipairs(storageFolder:GetChildren()) do
        if child:GetAttribute("Owner") == LocalPlayer.Name then
            child:Destroy()
        end
    end
end

local function buildReferenceModel(userId)
    local ok, model = pcall(function()
        local desc
        local fetchOk, fetched = pcall(function()
            return Players:GetHumanoidDescriptionFromUserId(userId)
        end)
        if fetchOk and fetched then
            desc = fetched
        else
            desc = Instance.new("HumanoidDescription")
        end
        return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R6)
    end)
    if not ok or not model then
        warn("[Evaware] CreateHumanoidModelFromDescription (R6) failed: " .. tostring(model))
        local ok2, model2 = pcall(function()
            return Players:CreateHumanoidModelFromUserId(userId)
        end)
        if ok2 and model2 then
            return model2
        end
        return nil
    end
    return model
end

local function getOrCreateAttachment(bodyPart, attachmentName)
    local attachment = bodyPart:FindFirstChild(attachmentName)
    if attachment and attachment:IsA("Attachment") then
        return attachment
    end

    local offset = R6_ATTACHMENT_OFFSETS[attachmentName]
    if not offset then return nil end

    attachment = Instance.new("Attachment")
    attachment.Name = attachmentName
    attachment.CFrame = offset
    attachment.Parent = bodyPart
    return attachment
end

local function findR6HandleAttachment(handle, mapping)
    for _, child in ipairs(handle:GetChildren()) do
        if child:IsA("Attachment") and ATTACHMENT_TO_BODYPART[child.Name] then
            return child, child.Name
        end
    end
    local expected = mapping.attachmentName
    local direct = handle:FindFirstChild(expected)
    if direct and direct:IsA("Attachment") then
        return direct, expected
    end
    return nil, nil
end

local function weldAccessoryByType(character, accessoryClone)
    local handle = accessoryClone:FindFirstChild("Handle")
    if not handle then return false end

    local accessoryType = accessoryClone.AccessoryType
    local mapping = ACCESSORY_ATTACHMENT_MAP[accessoryType] or ACCESSORY_ATTACHMENT_MAP[Enum.AccessoryType.Unknown]

    local handleAttachment, attachmentName = findR6HandleAttachment(handle, mapping)
    if not handleAttachment then
        attachmentName = mapping.attachmentName
        handleAttachment = Instance.new("Attachment")
        handleAttachment.Name = attachmentName
        handleAttachment.CFrame = CFrame.new()
        handleAttachment.Parent = handle
    end

    local bodyPartName = ATTACHMENT_TO_BODYPART[attachmentName] or mapping.bodyPart
    local bodyPart = character:FindFirstChild(bodyPartName)
    if not bodyPart then
        bodyPart = character:FindFirstChild("Head")
        if not bodyPart then return false end
    end

    local bodyAttachment = getOrCreateAttachment(bodyPart, attachmentName)
    if not bodyAttachment then return false end

    handle.CFrame = bodyPart.CFrame * bodyAttachment.CFrame * handleAttachment.CFrame:Inverse()

    local weld = Instance.new("Weld")
    weld.Name = "AccessoryWeld"
    weld.Part0 = bodyPart
    weld.Part1 = handle
    weld.C0 = bodyAttachment.CFrame
    weld.C1 = handleAttachment.CFrame
    weld.Parent = handle

    return true
end

local function transferHeadAppearance(character, refModel)
    local refHead = refModel:FindFirstChild("Head")
    local targetHead = character:FindFirstChild("Head")
    if not refHead or not targetHead then return end

    local existingMesh = targetHead:FindFirstChildWhichIsA("SpecialMesh")
    if existingMesh then
        existingMesh:Destroy()
    end
    local existingFace = targetHead:FindFirstChild("face")
    if existingFace and existingFace:IsA("Decal") then
        existingFace:Destroy()
    end

    local refMesh = refHead:FindFirstChildWhichIsA("SpecialMesh")
    if refMesh then
        local meshClone = refMesh:Clone()
        meshClone.Parent = targetHead
    end

    local refFace = refHead:FindFirstChild("face")
    if refFace and refFace:IsA("Decal") then
        local faceClone = refFace:Clone()
        faceClone.Parent = targetHead
    end

    if refHead:IsA("BasePart") and targetHead:IsA("BasePart") then
        targetHead.Color = refHead.Color
    end
end

local function transferCosmetics(character, refModel)
    transferHeadAppearance(character, refModel)

    for _, child in ipairs(refModel:GetChildren()) do
        if child:IsA("CharacterMesh") or child:IsA("Shirt") or child:IsA("Pants")
            or child:IsA("ShirtGraphic") or child:IsA("BodyColors") then
            local clone = child:Clone()
            clone.Parent = character

        elseif child:IsA("Accessory") or child:IsA("Hat") then
            local clone = child:Clone()
            clone.Parent = character

            weldAccessoryByType(character, clone)
        end
    end
end

local function convertToUserId(input)
    local numericId = tonumber(input)
    if numericId then
        return numericId
    end
    
    local success, result = pcall(function()
        return Players:GetUserIdFromNameAsync(input)
    end)
    
    if success and result then
        return result
    end
    
    return nil
end

local function applyAvatarFromInput(character, input)
    if not character then
        warn("[Evaware] applyAvatarFromInput: character is nil")
        return
    end

    local id = convertToUserId(input)
    if not id then
        warn("[Evaware] Failed to resolve UserId for input: " .. tostring(input))
        return
    end

    local refModel = buildReferenceModel(id)
    if not refModel then
        warn("[Evaware] buildReferenceModel returned nil for id " .. tostring(id))
        return
    end

    local okClear, errClear = pcall(clearOldCosmetics, character)
    if not okClear then
        warn("[Evaware] clearOldCosmetics failed: " .. tostring(errClear))
    end

    local okTransfer, errTransfer = pcall(transferCosmetics, character, refModel)
    if not okTransfer then
        warn("[Evaware] transferCosmetics failed: " .. tostring(errTransfer))
    end

    refModel:Destroy()

    if okClear and okTransfer then
        warn("[Evaware] Avatar applied successfully for " .. character.Name)
        if renderConn == nil then
            startRenderLoop()
        end
    end
end

local function disconnectAttributeWatchers()
    for _, conn in ipairs(attributeConnsHS) do
        conn:Disconnect()
    end
    attributeConnsHS = {}
end

local function hookCharacterAttributes(character)
    disconnectAttributeWatchers()

    local function reapply()
        if not avatarChangerEnabled then return end
        if LocalPlayer.Character ~= character then return end
        applyAvatarFromInput(character, targetUserId)
    end

    table.insert(attributeConnsHS, character:GetAttributeChangedSignal("Team"):Connect(reapply))
    table.insert(attributeConnsHS, character:GetAttributeChangedSignal("Tag"):Connect(reapply))
end

local function applyToDuplicateIfNeeded(instance)
    if not instance then return end
    if not avatarChangerEnabled then return end
    if instance == LocalPlayer.Character then return end
    if not instance:IsA("Model") then return end
    if appliedDupeInstances[instance] then return end

    appliedDupeInstances[instance] = true
    applyAvatarFromInput(instance, targetUserId)
end

local function scanKnownDupeFolders()
    if not avatarChangerEnabled then return end

    for _, rigsFolder in ipairs(getActiveRigsFolders()) do
        local rig = rigsFolder:FindFirstChild(LocalPlayer.Name)
        if rig then
            applyToDuplicateIfNeeded(rig)
        end
    end
end

local function disconnectDupeWatchers()
    for _, conn in ipairs(rigsWatcherConns) do
        conn:Disconnect()
    end
    rigsWatcherConns = {}
end

local function hookRigsFolder(folder)
    local addedConn = folder.ChildAdded:Connect(function(child)
        if not avatarChangerEnabled then return end
        if child.Name ~= LocalPlayer.Name then return end
        applyToDuplicateIfNeeded(child)
    end)
    table.insert(rigsWatcherConns, addedConn)
end

local function watchDupeFolders()
    disconnectDupeWatchers()

    for _, rigsFolder in ipairs(getActiveRigsFolders()) do
        hookRigsFolder(rigsFolder)
    end

    local topLevelConn = workspace.ChildAdded:Connect(function(child)
        if not avatarChangerEnabled then return end
        if child.Name ~= "Rigs" then return end
        hookRigsFolder(child)
        scanKnownDupeFolders()
    end)
    table.insert(rigsWatcherConns, topLevelConn)
end

local function setAvatarChanger(state)
    avatarChangerEnabled = state

    if avatarCharacterAddedConn then
        avatarCharacterAddedConn:Disconnect()
        avatarCharacterAddedConn = nil
    end

    disconnectAttributeWatchers()
    disconnectDupeWatchers()
    stopRenderLoop()
    appliedDupeInstances = setmetatable({}, { __mode = "k" })

         if state then
         avatarAppliedOnce = true
            if LocalPlayer.Character then
            applyAvatarFromInput(LocalPlayer.Character, targetUserId)
            hookCharacterAttributes(LocalPlayer.Character)
        end

        avatarCharacterAddedConn = LocalPlayer.CharacterAdded:Connect(function(character)
            if not avatarChangerEnabled then return end
            appliedDupeInstances = setmetatable({}, { __mode = "k" })
            applyAvatarFromInput(character, targetUserId)
            hookCharacterAttributes(character)
            scanKnownDupeFolders()
        end)

        watchDupeFolders()
        scanKnownDupeFolders()
        startRenderLoop()
    end
end

local AvatarChangerSection = VisualTab:AddParagraph({ Title = "Avatar Changer", Content = "" })

avatarInputBox = VisualTab:AddInput("username", {
    Title = "Username",
    Placeholder = "Put here username or userid",
    ClearOnFocus = false,
    Callback = function(text)
        targetUserId = text
    end,
})

VisualTab:AddButton({
    Title = "Apply Avatar",
    Callback = function()
        if LocalPlayer.Character then
            avatarAppliedOnce = true
            applyAvatarFromInput(LocalPlayer.Character, targetUserId)
        end
    end,
})

AvatarChangerToggleObject = VisualTab:AddToggle("AvatarChangerToggle", {
    Title = "Re-apply on respawn",
    Default = false,
    Callback = function(value)
        setAvatarChanger(value)
    end
})
end

VisualTab:AddParagraph({ Title = "World & Character visuals", Content = "" })

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

do
    local jumpCirclesEnabled = false
    local circleMode = "Circle"
    local circleColor = Color3.fromRGB(0, 255, 127)
    local jumpConnection = nil
    local maxRadius = 3.3
    local circleSpeed = 0.3
    local circleLightEnabled = false

    local circleTextureId = "rbxassetid://96432955075542"
    local glowTextureId = "rbxassetid://112001307716587"

    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local LocalPlayer = Players.LocalPlayer

    local activeCircleParts = {}

local function getGroundPosition(character, rootPart)
    local raycastParams = RaycastParams.new()
    local filterList = {workspace:FindFirstChild("Players") or character, character}
    for part in pairs(activeCircleParts) do
        table.insert(filterList, part)
    end
    raycastParams.FilterDescendantsInstances = filterList
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true

    local castHeight = 3
    local castDistance = 50

    -- 1) пробуем строго по центру (под HumanoidRootPart)
    local centerOrigin = rootPart.Position + Vector3.new(0, castHeight, 0)
    local centerResult = workspace:Raycast(centerOrigin, Vector3.new(0, -castDistance, 0), raycastParams)
    if centerResult then
        return centerResult.Position
    end

    -- 2) если центр промахнулся (например, дырка в геометрии под ногами) — пробуем офсеты
    local offsets = {
        Vector3.new(0.6, 0, 0),
        Vector3.new(-0.6, 0, 0),
        Vector3.new(0, 0, 0.6),
        Vector3.new(0, 0, -0.6),
    }

    local bestResult = nil
    local bestDist = nil
    for _, offset in ipairs(offsets) do
        local origin = rootPart.Position + offset + Vector3.new(0, castHeight, 0)
        local result = workspace:Raycast(origin, Vector3.new(0, -castDistance, 0), raycastParams)
        if result then
            -- берём ближайший к позиции игрока по горизонтали, а не самый высокий по Y
            local horizDist = (Vector3.new(result.Position.X, 0, result.Position.Z) - Vector3.new(rootPart.Position.X, 0, rootPart.Position.Z)).Magnitude
            if not bestDist or horizDist < bestDist then
                bestDist = horizDist
                bestResult = result
            end
        end
    end

    if bestResult then
        return bestResult.Position
    end

    local fallbackResult = workspace:Raycast(rootPart.Position + Vector3.new(0, 5, 0), Vector3.new(0, -100, 0), raycastParams)
    if fallbackResult then
        return fallbackResult.Position
    end

    return nil
end

    local function createJumpCircle(pos)
        local startDiameter = 0.6
        local endDiameter = math.max(maxRadius, 0.1) * 2

        local circlePart = Instance.new("Part")
        circlePart.Size = Vector3.new(startDiameter, 0.05, startDiameter)
        circlePart.CFrame = CFrame.new(pos + Vector3.new(0, 0.15, 0))
        circlePart.Anchored = true
        circlePart.CanCollide = false
        circlePart.CanQuery = false
        circlePart.CanTouch = false
        circlePart.Transparency = 1
        circlePart.Material = Enum.Material.SmoothPlastic
        circlePart.Parent = workspace

        activeCircleParts[circlePart] = true

        local decal = Instance.new("Decal")
        decal.Face = Enum.NormalId.Top
        decal.Color3 = circleColor
        decal.Texture = (circleMode == "Circle") and circleTextureId or glowTextureId
        decal.Transparency = 0.15
        decal.Parent = circlePart

        local light = nil
        if circleLightEnabled then
            light = Instance.new("PointLight")
            light.Color = circleColor
            light.Brightness = 3
            light.Range = math.max(maxRadius * 0.5, 0.4)
            light.Shadows = false
            light.Parent = circlePart
        end

        local speedFactor = math.max(circleSpeed, 0.05)
        local growDuration = 0.45 / speedFactor
        local fadeDuration = 0.55 / speedFactor
        local fadeDelay = 0.1 / speedFactor
        local cleanupDelay = 0.35 / speedFactor

        local growInfo = TweenInfo.new(growDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local fadeInfo = TweenInfo.new(fadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

        local growTween = TweenService:Create(circlePart, growInfo, {
            Size = Vector3.new(endDiameter, 0.05, endDiameter)
        })
        local fadeTween = TweenService:Create(decal, fadeInfo, {Transparency = 1})
        local lightFadeTween = nil
        if light then
            lightFadeTween = TweenService:Create(light, fadeInfo, {Brightness = 0})
        end

        growTween:Play()

        task.delay(fadeDelay, function()
            if circlePart and circlePart.Parent then
                fadeTween:Play()
                if lightFadeTween then
                    lightFadeTween:Play()
                end
            end
        end)

        growTween.Completed:Connect(function()
            task.delay(cleanupDelay, function()
                if circlePart then
                    activeCircleParts[circlePart] = nil
                    circlePart:Destroy()
                end
            end)
        end)
    end

    local function startWatcher()
        if jumpConnection then
            jumpConnection:Disconnect()
            jumpConnection = nil
        end

        local character = LocalPlayer.Character
        if not character then return end

        local humanoid = character:WaitForChild("Humanoid", 5)
        local rootPart = character:WaitForChild("HumanoidRootPart", 5)
        if not humanoid or not rootPart then return end

jumpConnection = humanoid.Jumping:Connect(function(isActive)
    if isActive and jumpCirclesEnabled then
        local groundPos = getGroundPosition(character, rootPart)
        if groundPos then
            createJumpCircle(groundPos)
                  end
             end
        end)
    end

    local function stopWatcher()
        if jumpConnection then
            jumpConnection:Disconnect()
            jumpConnection = nil
        end
    end

    LocalPlayer.CharacterAdded:Connect(function(char)
        if jumpCirclesEnabled then
            char:WaitForChild("Humanoid")
            task.wait(0.3)
            startWatcher()
        end
    end)

    VisualTab:AddToggle("JumpCirclesToggle", {
        Title = "Jump Circles",
        Default = false,
        Callback = function(value)
            jumpCirclesEnabled = value
            if value then
                startWatcher()
            else
                stopWatcher()
            end
        end,
    })

    local circleColorPicker = VisualTab:AddColorpicker("circleColor", {
        Title = "Circle Color",
        Default = Color3.fromRGB(0, 255, 127),
        Callback = function(value)
            circleColor = value
        end
    })

    task.defer(function()
        if circleColorPicker then
            local pickerValue = circleColorPicker.Color or circleColorPicker.CurrentValue
            if typeof(pickerValue) == "Color3" then
                circleColor = pickerValue
            end
        end
    end)

    VisualTab:AddDropdown("circleMode", {
        Title = "Circle Mode",
        Values = {"Circle", "Glow"},
        Default = "Circle",
        Callback = function(option)
            circleMode = type(option) == "table" and option[1] or option
        end,
    })

local circleRadiusSlider = addNumericInput(VisualTab, "circleRadius", {
        Title = "Circle Radius",
        Min = 1, Max = 6.5,
        Increment = 0.1,
        Rounding = 1,
        Default = 3.3,
        Callback = function(value)
            maxRadius = value
        end,
    })

    local circleSpeedSlider = addNumericInput(VisualTab, "circleSpeed", {
        Title = "Circle Speed",
        Min = 0.2, Max = 1,
        Increment = 0.1,
        Rounding = 1,
        Default = 0.3,
        Callback = function(value)
            circleSpeed = value
        end,
    })

    task.defer(function()
        if circleRadiusSlider then
            local v = circleRadiusSlider.CurrentValue or circleRadiusSlider.Value
            if typeof(v) == "number" then
                maxRadius = v
            end
        end
        if circleSpeedSlider then
            local v = circleSpeedSlider.CurrentValue or circleSpeedSlider.Value
            if typeof(v) == "number" then
                circleSpeed = v
            end
        end
    end)

    VisualTab:AddToggle("JumpCircleLightToggle", {
        Title = "Circle Light",
        Default = false,
        Callback = function(value)
            circleLightEnabled = value
        end,
    })
end

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local assetId = 116402178504134
local skyboxActive = false
local fogEnabled = false
local fogColor = Color3.fromRGB(53, 124, 142)

local reapplySkyOnRespawn = false
local reapplyFogOnRespawn = false

local createdAtmo = false

local ATMO_PROPS = { Density = 0.6, Offset = 0.25, Color = fogColor, Decay = Color3.fromRGB(90, 100, 110), Glare = 0, Haze = 0.6 }

local ourSky = nil
local originalSky = nil
local originalSkyCaptured = false

local function captureOriginalSky()
    if originalSkyCaptured then return end
    originalSkyCaptured = true

    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") then
            originalSky = obj:Clone()
            break
        end
    end
end

local function destroyForeignSkies()
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") and obj ~= ourSky then
            obj:Destroy()
        end
    end
end

local function restoreOriginalSky()
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") then
            obj:Destroy()
        end
    end
    ourSky = nil

    if originalSky then
        local restored = originalSky:Clone()
        restored.Parent = Lighting
    end
end

local function cleanAndLoad()
    destroyForeignSkies()

    task.delay(0.01, function()
        if not skyboxActive then return end

        local currentId = assetId
        local attempts = 0
        local loaded = false

        while attempts < 5 and not loaded do
            attempts += 1
            local success, objects = pcall(function() return game:GetObjects("rbxassetid://" .. currentId) end)
            if success and objects and objects[1] then
                if currentId == assetId and skyboxActive then
                    destroyForeignSkies()
                    if ourSky then ourSky:Destroy() end
                    ourSky = objects[1]
                    ourSky.Name = "EvawareCustomSky"
                    ourSky.Parent = Lighting
                    loaded = true
                else
                    loaded = true
                end
            else
                task.wait(0.15)
            end
        end
    end)
end

local function applyFog()
    local atmo = Lighting:FindFirstChild("FancyAtmosphere")
    if not atmo then
        atmo = Instance.new("Atmosphere")
        atmo.Name = "FancyAtmosphere"
        atmo.Parent = Lighting
        createdAtmo = true
    end
    for p, v in pairs(ATMO_PROPS) do atmo[p] = v end
end

local function setFog(state)
    fogEnabled = state
    if state then
        applyFog()
    else
        local a = Lighting:FindFirstChild("FancyAtmosphere") if a then a:Destroy() end
        createdAtmo = false
    end
end

local function reapplyIfEnabled()
    if reapplySkyOnRespawn and skyboxActive then
        cleanAndLoad()
    end
    if reapplyFogOnRespawn and fogEnabled then
        applyFog()
    end
end

captureOriginalSky()

Lighting.ChildAdded:Connect(function(obj)
    if skyboxActive and obj:IsA("Sky") and obj ~= ourSky then
        obj:Destroy()
        if ourSky and ourSky.Parent ~= Lighting then
            ourSky.Parent = Lighting
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    reapplyIfEnabled()
    task.spawn(function()
        task.wait(1)
        reapplyIfEnabled()
    end)
end)

local function reapplyForInstance(_inst)
    reapplyIfEnabled()
    task.spawn(function()
        task.wait(1)
        reapplyIfEnabled()
    end)
end

local function bindRigsWatcher(rigsRoot)
    for _, obj in ipairs(rigsRoot:GetChildren()) do
        if obj.Name == LocalPlayer.Name then
            reapplyForInstance(obj)
        end
    end

    rigsRoot.ChildAdded:Connect(function(child)
        if child.Name == LocalPlayer.Name then
            reapplyForInstance(child)
        end
    end)
end

local rigsOuter = workspace:WaitForChild("Rigs")

local function tryBindInnerRigs()
    local inner = rigsOuter:FindFirstChild("Rigs")
    if inner then
        bindRigsWatcher(inner)
    end
end

tryBindInnerRigs()

rigsOuter.ChildAdded:Connect(function(child)
    if child.Name == "Rigs" then
        bindRigsWatcher(child)
    end
end)

local playersFolder = workspace:WaitForChild("Players")

for _, obj in ipairs(playersFolder:GetChildren()) do
    if obj.Name == LocalPlayer.Name then
        reapplyForInstance(obj)
    end
end

playersFolder.ChildAdded:Connect(function(child)
    if child.Name == LocalPlayer.Name then
        reapplyForInstance(child)
    end
end)

-- [ UI ]
VisualTab:AddInput("skyboxAssetId", {
    Title = "Skybox asset ID",
    Placeholder = "116402178504134",
    Callback = function(value)
        local id = tonumber(value)
        if id then assetId = id; if skyboxActive then cleanAndLoad() end end
    end,
})

VisualTab:AddToggle("CustomSkyboxToggle", {
    Title = "Enable Custom Skybox",
    Default = false,
    Callback = function(value)
        skyboxActive = value
        if skyboxActive then
            cleanAndLoad()
        else
            restoreOriginalSky()
        end
    end,
})

VisualTab:AddToggle("FancyFogToggle", {
    Title = "Fancy Fog",
    Default = false,
    Callback = function(value) setFog(value) end,
})

VisualTab:AddColorpicker("fogColor", {
    Title = "Fog Color",
    Default = fogColor,
    Callback = function(color)
        fogColor = color
        ATMO_PROPS.Color = color
        local a = Lighting:FindFirstChild("FancyAtmosphere")
        if a then a.Color = color end
    end,
})

VisualTab:AddToggle("ReapplyCustomSky", {
    Title = "Re-apply custom skybox on respawn",
    Default = false,
    Callback = function(value)
        reapplySkyOnRespawn = value
    end,
})

VisualTab:AddToggle("Reapplyfancyfog", {
    Title = "Re-apply fancy fog on respawn",
    Default = false,
    Callback = function(value)
        reapplyFogOnRespawn = value
    end,
})

--shaders

local weatherParts = {}

local function safeSpawnWeatherPart(name, cframe, size)
    local part = Instance.new("Part")
    part.Name = name
    part.CFrame = cframe
    part.Size = size
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    part.CastShadow = false
    part.Massless = true
    part.CanQuery = false
    part.Parent = workspace
    table.insert(weatherParts, part)
    return part
end

VisualTab:AddParagraph({ Title = "Shaders", Content = "" })
local Players = game:GetService("Players")
local lp = Players.LocalPlayer

local function notifyBlocked()
    Fluent:Notify({
        Title = "Weather",
        Content = "You can't enable 2 shaders at once",
        Duration = 2,
    })
end

local function turnOffCurrent()
    if currentCleanupFn then
        local fn = currentCleanupFn
        currentCleanupFn = nil
        pcall(fn)
    end
    activeWeather = nil
end

local function clearAllWeatherPartsOnMap()
    for _, part in ipairs(weatherParts) do
        pcall(function() part:Destroy() end)
    end
    weatherParts = {}

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name:find("WeatherFX_") then
            pcall(function() obj:Destroy() end)
        end
    end

    local camera = workspace.CurrentCamera
    local oldFX = camera:FindFirstChild("WeatherFX")
    if oldFX then oldFX:Destroy() end
end

-- [ RTX SHADER WATCHER ]
_G.RTXShaderRegistry = _G.RTXShaderRegistry or {}

local function registerRTXShader(id, names, reapplyFn)
    _G.RTXShaderRegistry[id] = {
        names = names,
        reapply = reapplyFn,
    }
end

local function unregisterRTXShader(id)
    _G.RTXShaderRegistry[id] = nil
end

if not _G.RTXShaderWatcherConnected then
    _G.RTXShaderWatcherConnected = true

    local WatcherLighting = game:GetService("Lighting")

    WatcherLighting.ChildRemoved:Connect(function(obj)
        for id, entry in pairs(_G.RTXShaderRegistry) do
            for _, name in ipairs(entry.names) do
                if obj.Name == name then
                    task.defer(function()
                        if not _G.RTXShaderRegistry[id] then return end
                        if not WatcherLighting:FindFirstChild(name) then
                            pcall(entry.reapply)
                        end
                    end)
                    break
                end
            end
        end
    end)
end

VisualTab:AddButton({
    Title = "🌧  RTX Rain",
    Callback = function()
        if activeWeather == "rtxrain" then
            turnOffCurrent()
            return
        end
        if activeWeather then
            notifyBlocked()
            return
        end
        activeWeather = "rtxrain"

        local RunService = game:GetService("RunService")
        local lp = game:GetService("Players").LocalPlayer

        local savedLighting = {
            TimeOfDay = Lighting.TimeOfDay,
            Brightness = Lighting.Brightness,
            OutdoorAmbient = Lighting.OutdoorAmbient,
            Ambient = Lighting.Ambient,
            ColorShift_Top = Lighting.ColorShift_Top,
            ColorShift_Bottom = Lighting.ColorShift_Bottom,
            GlobalShadows = Lighting.GlobalShadows,
            ShadowSoftness = Lighting.ShadowSoftness,
            FogColor = Lighting.FogColor,
            FogStart = Lighting.FogStart,
            FogEnd = Lighting.FogEnd,
        }

        local existingSky = Lighting:FindFirstChildOfClass("Sky")
        local removedSky = nil
        if existingSky then
            removedSky = existingSky:Clone()
            existingSky:Destroy()
        end

        Lighting.TimeOfDay         = "13:30:00"
        Lighting.Brightness        = 1.4
        Lighting.OutdoorAmbient    = Color3.fromRGB(45, 55, 75)
        Lighting.Ambient           = Color3.fromRGB(65, 78, 98)
        Lighting.ColorShift_Top    = Color3.fromRGB(60, 75, 95)
        Lighting.ColorShift_Bottom = Color3.fromRGB(35, 45, 60)
        Lighting.GlobalShadows     = true
        Lighting.ShadowSoftness    = 0.2
        Lighting.FogColor          = Color3.fromRGB(120, 125, 130)
        Lighting.FogStart          = 20
        Lighting.FogEnd            = 175

        local RTXRAIN_NAMES = {
            "RTXRainSky", "RTXRainAtmosphere", "RTXRainBloom",
            "RTXRainColorCorrection", "RTXRainDOF", "RTXRainBlur",
        }

        local cc, blur
        local function applyRainLightingEffects()
            if not Lighting:FindFirstChild("RTXRainSky") then
                local existing = Lighting:FindFirstChildOfClass("Sky")
                if existing then existing:Destroy() end
                local sky = Instance.new("Sky")
                sky.Name = "RTXRainSky"
                sky.CelestialBodiesShown = true
                sky.MoonAngularSize = 1
                sky.SkyboxBk = "http://www.roblox.com/asset/?id=4495864450"
                sky.SkyboxDn = "http://www.roblox.com/asset/?id=4495864887"
                sky.SkyboxFt = "http://www.roblox.com/asset/?id=4495865458"
                sky.SkyboxLf = "http://www.roblox.com/asset/?id=4495866035"
                sky.SkyboxRt = "http://www.roblox.com/asset/?id=4495866584"
                sky.SkyboxUp = "http://www.roblox.com/asset/?id=4495867486"
                sky.StarCount = 3000
                sky.SunAngularSize = 1
                sky.Parent = Lighting
            end

            if not Lighting:FindFirstChild("RTXRainAtmosphere") then
                local atmo = Instance.new("Atmosphere")
                atmo.Name = "RTXRainAtmosphere"
                atmo.Density = 0.52
                atmo.Offset = 0.15
                atmo.Color = Color3.fromRGB(120, 125, 130)
                atmo.Haze = 1
                atmo.Glare = 0.4
                atmo.Decay = Color3.fromRGB(145, 152, 162)
                atmo.Parent = Lighting
            end

            if not Lighting:FindFirstChild("RTXRainBloom") then
                local bloom = Instance.new("BloomEffect")
                bloom.Name = "RTXRainBloom"
                bloom.Intensity = 0.45
                bloom.Size = 24
                bloom.Threshold = 0.82
                bloom.Parent = Lighting
            end

            if not Lighting:FindFirstChild("RTXRainColorCorrection") then
                cc = Instance.new("ColorCorrectionEffect")
                cc.Name = "RTXRainColorCorrection"
                cc.Saturation = -0.52
                cc.Contrast = -0.25
                cc.Brightness = -0.12
                cc.TintColor = Color3.fromRGB(175, 190, 215)
                cc.Parent = Lighting
            else
                cc = Lighting.RTXRainColorCorrection
            end

            if not Lighting:FindFirstChild("RTXRainDOF") then
                local dof = Instance.new("DepthOfFieldEffect")
                dof.Name = "RTXRainDOF"
                dof.FarIntensity = 0.65
                dof.NearIntensity = 0.10
                dof.FocusDistance = 28
                dof.InFocusRadius = 18
                dof.Parent = Lighting
            end

            if not Lighting:FindFirstChild("RTXRainBlur") then
                blur = Instance.new("BlurEffect")
                blur.Name = "RTXRainBlur"
                blur.Size = 1.33
                blur.Parent = Lighting
            else
                blur = Lighting.RTXRainBlur
            end

            local terrain = workspace:FindFirstChildOfClass("Terrain")
            if terrain and not terrain:FindFirstChild("RTXRainClouds") then
                local clouds = Instance.new("Clouds")
                clouds.Name = "RTXRainClouds"
                clouds.Cover = 0.88
                clouds.Density = 0.80
                clouds.Color = Color3.fromRGB(55, 65, 80)
                clouds.Parent = terrain
            end
        end

        applyRainLightingEffects()
        registerRTXShader("rtxrain", RTXRAIN_NAMES, applyRainLightingEffects)

        local TweenService = game:GetService("TweenService")
        local Camera       = workspace.CurrentCamera

        local CFG = {
            DROP_COUNT   = 320,
            DROP_SPEED   = 88,
            DROP_WIND    = Vector3.new(4.5, 0, 1.5),
            DROP_RANGE   = 55,
            DROP_HEIGHT  = 42,
            DROP_LEN     = 2.4,
            DROP_W       = 0.045,
            SPLASH_COUNT = 3,
            SPLASH_LIFE  = 0.32,
            CELL_SIZE         = 4.0,
            HITS_TO_SPAWN     = 14,
            PUDDLE_MAX        = 25,
            PUDDLE_LIFE       = 120,
            PUDDLE_SIZE_START = 0.45,
            PUDDLE_SIZE_MAX   = 8.0,
            PUDDLE_H          = 0.028,
        }

        local RAIN_DIR = (Vector3.new(0,-1,0) + CFG.DROP_WIND * 0.055).Unit
        local RAIN_VEL = RAIN_DIR * CFG.DROP_SPEED + CFG.DROP_WIND

        local _cr = RAIN_DIR:Cross(Vector3.new(0,0,1))
        if _cr.Magnitude < 0.01 then _cr = RAIN_DIR:Cross(Vector3.new(1,0,0)) end
        _cr = _cr.Unit
        local DROP_ROT = CFrame.fromMatrix(Vector3.zero, RAIN_DIR, _cr:Cross(RAIN_DIR), -_cr)
        local function dropCF(p) return CFrame.new(p) * DROP_ROT end

        local function diskCF(pos, normal)
            local r = normal:Cross(Vector3.new(0,0,1))
            if r.Magnitude < 0.01 then r = normal:Cross(Vector3.new(1,0,0)) end
            r = r.Unit
            return CFrame.fromMatrix(pos + normal * 0.014, normal, r:Cross(normal), -r)
        end

        local ROOT = Instance.new("Folder")
        ROOT.Name="RTXRainDrops"; ROOT.Parent=workspace

        local rtxRainState = {
            active = true,
            conns = {},
            puddles = {},
            sounds = {},
        }

        local rayP = RaycastParams.new()
        rayP.FilterType = Enum.RaycastFilterType.Exclude
        rayP.FilterDescendantsInstances = { ROOT }

        local function mkPart(props)
            local p = Instance.new("Part")
            p.Anchored=true; p.CanCollide=false; p.CanTouch=false
            p.CanQuery=false; p.CastShadow=false; p.Locked=true
            for k,v in pairs(props) do p[k]=v end
            p.Parent=ROOT; return p
        end

        local function makeSound(id, vol, pitch, looped, parent, playOnCreate)
            if playOnCreate == nil then playOnCreate = true end
            local s = Instance.new("Sound", parent or workspace)

            if string.find(id, "://") or string.find(id, "rbxasset") then
                s.SoundId = id
            else
                s.SoundId = "rbxassetid://" .. id
            end

            s.Volume = vol
            s.PlaybackSpeed = pitch
            s.Looped = looped
            s.RollOffMaxDistance = 9999

            if playOnCreate then
                s:Play()
            end
            return s
        end

        local sRain = makeSound("http://roblox.com/asset/?id=132152136", 0.65, 1.0, true)
        local sDrip = makeSound("6284526478", 0.25, 1.0, true)

        local sThunder1 = makeSound("rbxasset://sounds/HalloweenThunder.wav", 0.80, 1.0, false, nil, false)
        local sThunder2 = makeSound("rbxasset://sounds/HalloweenLightning.wav", 0.80, 1.0, false, nil, false)

        rtxRainState.sounds = { sRain, sDrip, sThunder1, sThunder2 }

        local function drawLightningBolt(startPos, endPos)
            if not rtxRainState.active then return end
            local points = {}
            local segments = 8
            table.insert(points, startPos)

            for i = 1, segments - 1 do
                local ratio = i / segments
                local linearPoint = startPos:Lerp(endPos, ratio)
                local offset = Vector3.new(
                    (math.random() - 0.5) * 8,
                    (math.random() - 0.5) * 4,
                    (math.random() - 0.5) * 8
                )
                table.insert(points, linearPoint + offset)
            end
            table.insert(points, endPos)

            local segmentParts = {}
            for i = 1, #points - 1 do
                local pA = points[i]
                local pB = points[i + 1]
                local distance = (pB - pA).Magnitude

                local seg = Instance.new("Part")
                seg.Name = "RTXLightningSegment"
                seg.Anchored = true
                seg.CanCollide = false
                seg.CanTouch = false
                seg.CanQuery = false
                seg.CastShadow = false
                seg.Material = Enum.Material.Neon
                seg.Color = Color3.fromRGB(215, 235, 255)
                seg.Size = Vector3.new(0.4, 0.4, distance)
                seg.CFrame = CFrame.new((pA + pB) / 2, pB)
                seg.Parent = ROOT
                table.insert(segmentParts, seg)

                if math.random() < 0.25 and i < #points - 1 then
                    task.spawn(function()
                        local branchEnd = pB + Vector3.new(
                            (math.random() - 0.5) * 15,
                            -math.random() * 15,
                            (math.random() - 0.5) * 15
                        )
                        local branchPoints = {pB, (pB + branchEnd)/2 + Vector3.new((math.random()-0.5)*3, 0, (math.random()-0.5)*3), branchEnd}
                        local branchParts = {}
                        for j = 1, #branchPoints - 1 do
                            local bA = branchPoints[j]
                            local bB = branchPoints[j+1]
                            local bDist = (bB - bA).Magnitude
                            local bSeg = Instance.new("Part")
                            bSeg.Name = "RTXLightningBranch"
                            bSeg.Anchored = true
                            bSeg.CanCollide = false
                            bSeg.CanTouch = false
                            bSeg.CanQuery = false
                            bSeg.CastShadow = false
                            bSeg.Material = Enum.Material.Neon
                            bSeg.Color = Color3.fromRGB(180, 205, 255)
                            bSeg.Size = Vector3.new(0.2, 0.2, bDist)
                            bSeg.CFrame = CFrame.new((bA + bB) / 2, bB)
                            bSeg.Parent = ROOT
                            table.insert(branchParts, bSeg)
                        end

                        for step = 1, 8 do
                            task.wait(0.02)
                            local trans = step / 8
                            for _, p in ipairs(branchParts) do
                                if p and p.Parent then p.Transparency = trans end
                            end
                        end
                        for _, p in ipairs(branchParts) do
                            if p and p.Parent then p:Destroy() end
                        end
                    end)
                end
            end

            task.spawn(function()
                for step = 1, 10 do
                    task.wait(0.02)
                    local trans = step / 10
                    for _, seg in ipairs(segmentParts) do
                        if seg and seg.Parent then
                            seg.Transparency = trans
                        end
                    end
                end
                for _, seg in ipairs(segmentParts) do
                    if seg and seg.Parent then
                        seg:Destroy()
                    end
                end
            end)
        end

        task.spawn(function()
            while rtxRainState.active do
                task.wait(math.random(70, 80) / 10)
                if not rtxRainState.active then break end

                task.spawn(function()
                    local camCF = Camera.CFrame
                    local startOffset = Vector3.new(
                        (math.random() * 2 - 1) * 130,
                        180,
                        -math.random(60, 180)
                    )
                    local strikeStart = camCF:PointToWorldSpace(startOffset)
                    local rayResult = workspace:Raycast(strikeStart, Vector3.new(0, -300, 0), rayP)
                    local strikeEnd = rayResult and rayResult.Position or (strikeStart - Vector3.new(0, 180, 0))

                    drawLightningBolt(strikeStart, strikeEnd)
                end)

                if cc and blur then
                    local origBright = cc.Brightness
                    local origTint = cc.TintColor

                    cc.Brightness = 0.3
                    cc.TintColor = Color3.fromRGB(220, 235, 255)
                    blur.Size = 7
                    task.wait(0.08)

                    cc.Brightness = origBright
                    cc.TintColor = origTint
                    blur.Size = 2
                    task.wait(0.1)

                    cc.Brightness = 0.15
                    task.wait(0.05)
                    cc.Brightness = origBright
                end

                if rtxRainState.active then
                    local chosenSound = math.random(1, 2) == 1 and sThunder1 or sThunder2
                    if chosenSound and chosenSound.Parent then
                        chosenSound.TimePosition = 0
                        chosenSound:Play()
                    end
                end
            end
        end)

        local hitGrid    = {}
        local puddleList = rtxRainState.puddles
        local puddleCount = 0

        local function cellKey(pos)
            return math.floor(pos.X / CFG.CELL_SIZE)
                .."_"..math.floor(pos.Z / CFG.CELL_SIZE)
        end

        local function spawnPuddle(pos, normal)
            if puddleCount >= CFG.PUDDLE_MAX then
                local old = table.remove(puddleList, 1)
                if old and old.part and old.part.Parent then old.part:Destroy() end
                puddleCount = math.max(0, puddleCount - 1)
            end

            local sx = 0.70 + math.random() * 0.60
            local sz = 0.70 + math.random() * 0.60
            local d0 = CFG.PUDDLE_SIZE_START
            local dMax = CFG.PUDDLE_SIZE_MAX * (0.40 + math.random() * 0.60)

            local p = mkPart({
                Material    = Enum.Material.SmoothPlastic,
                Color       = Color3.fromRGB(45, 65, 85),
                Reflectance = 0.85,
                Transparency = 0.15,
                Size        = Vector3.new(CFG.PUDDLE_H, d0 * sx, d0 * sz),
            })
            p.CFrame = diskCF(pos, normal)

            local mesh = Instance.new("SpecialMesh", p)
            mesh.MeshType = Enum.MeshType.Cylinder

            local pd = { part=p, sx=sx, sz=sz, curD=d0, maxD=dMax, hits=0 }
            table.insert(puddleList, pd)
            puddleCount = puddleCount + 1

            task.delay(CFG.PUDDLE_LIFE, function()
                if not (p and p.Parent) then return end
                TweenService:Create(p, TweenInfo.new(3.5), { Transparency=1 }):Play()
                task.wait(3.6)
                for i=#puddleList,1,-1 do
                    if puddleList[i]==pd then table.remove(puddleList,i); break end
                end
                puddleCount = math.max(0, puddleCount-1)
                if p and p.Parent then p:Destroy() end
            end)

            return pd
        end

        local function onDropHit(hitPos, hitNormal)
            local key  = cellKey(hitPos)
            local cell = hitGrid[key]

            if not cell then
                hitGrid[key] = { hits = 1, pos = hitPos, normal = hitNormal, puddle = nil }
                return
            end

            cell.hits   = cell.hits + 1
            cell.pos    = hitPos
            cell.normal = hitNormal

            if cell.puddle then
                local pd  = cell.puddle
                pd.hits   = pd.hits + 1
                pd.curD   = math.min(pd.curD + (pd.maxD - pd.curD) * 0.008, pd.maxD)
                if pd.part and pd.part.Parent then
                    pd.part.Size = Vector3.new(CFG.PUDDLE_H, pd.curD * pd.sx, pd.curD * pd.sz)
                end
            elseif cell.hits >= CFG.HITS_TO_SPAWN then
                cell.puddle = spawnPuddle(cell.pos, cell.normal)
            end
        end

        local function clearAllPuddles()
            for _, pd in ipairs(puddleList) do
                if pd.part and pd.part.Parent then pd.part:Destroy() end
            end
            for i=#puddleList,1,-1 do table.remove(puddleList,i) end
            for k in pairs(hitGrid) do hitGrid[k]=nil end
            puddleCount = 0
        end

        local splashPool   = {}
        local activeSplash = {}
        local GY           = -22

        local function getSplash()
            local p = table.remove(splashPool)
            if not p then
                p = mkPart({
                    Shape=Enum.PartType.Cylinder,
                    Material=Enum.Material.SmoothPlastic,
                    Color=Color3.fromRGB(185,215,242),
                    Transparency=0.45,
                    Size=Vector3.new(0.014,0.055,0.055),
                })
            else p.Parent=ROOT end
            return p
        end
        local function freeSplash(p) p.Parent=nil; table.insert(splashPool,p) end

        local function spawnSplash(hitPos)
            for _=1,CFG.SPLASH_COUNT do
                local ang = math.random()*math.pi*2
                local spd = 2+math.random()*5
                local p   = getSplash()
                p.CFrame  = CFrame.new(hitPos+Vector3.new(0,0.04,0))
                table.insert(activeSplash,{
                    part=p,
                    vx=math.cos(ang)*spd*0.5,
                    vy=3+math.random()*2.5,
                    vz=math.sin(ang)*spd*0.5,
                    life=CFG.SPLASH_LIFE, maxL=CFG.SPLASH_LIFE,
                })
            end
        end

        local dropPool    = {}
        local activeDrops = {}
        local DROP_SIZE   = Vector3.new(CFG.DROP_LEN, CFG.DROP_W, CFG.DROP_W)

        local function getDrop()
            local p = table.remove(dropPool)
            if not p then
                p = mkPart({
                    Shape=Enum.PartType.Cylinder,
                    Material=Enum.Material.SmoothPlastic,
                    Color=Color3.fromRGB(175, 210, 240),
                    Transparency=0.50, Size=DROP_SIZE,
                })
            else p.Parent=ROOT end
            return p
        end

        local function spawnDrop(cam)
            local pos = cam + Vector3.new(
                (math.random()*2-1)*CFG.DROP_RANGE,
                math.random()*CFG.DROP_HEIGHT,
                (math.random()*2-1)*CFG.DROP_RANGE
            )
            local p=getDrop(); p.CFrame=dropCF(pos)
            p.Transparency=0.45+math.random()*0.25
            table.insert(activeDrops,{part=p,pos=pos})
        end

        local cam0 = Camera.CFrame.Position
        for _=1,CFG.DROP_COUNT do spawnDrop(cam0) end

        local function hookMap(folder)
            local c = folder.AncestryChanged:Connect(function(_,newParent)
                if newParent ~= workspace then clearAllPuddles() end
            end)
            table.insert(rtxRainState.conns, c)
        end
        local mapNow = workspace:FindFirstChild("Map")
        if mapNow then hookMap(mapNow) end
        table.insert(rtxRainState.conns,
            workspace.ChildAdded:Connect(function(child)
                if child.Name=="Map" then task.wait(0.1); hookMap(child) end
            end)
        )

        local BATCH = 20

        table.insert(rtxRainState.conns,
            RunService.Heartbeat:Connect(function(dt)
                if not rtxRainState.active then return end
                dt = math.min(dt, 0.05)

                local cam  = Camera.CFrame.Position
                local lowY = cam.Y - CFG.DROP_RANGE * 0.55
                local hiY  = cam.Y + CFG.DROP_HEIGHT + 8
                local n    = #activeDrops

                for i=1,n do
                    local d  = activeDrops[i]
                    local nx = d.pos.X + RAIN_VEL.X*dt
                    local ny = d.pos.Y + RAIN_VEL.Y*dt
                    local nz = d.pos.Z + RAIN_VEL.Z*dt
                    local respawn = false

                    if i <= BATCH then
                        local hit = workspace:Raycast(
                            d.pos,
                            Vector3.new(RAIN_VEL.X*dt*2.5, RAIN_VEL.Y*dt*2.5, RAIN_VEL.Z*dt*2.5),
                            rayP
                        )
                        if hit then
                            spawnSplash(hit.Position)
                            if hit.Normal.Y > 0.65 then
                                onDropHit(hit.Position, hit.Normal)
                            end
                            respawn = true
                        end
                    end

                    if not respawn and (
                        ny < lowY or ny > hiY
                        or math.abs(nx-cam.X) > CFG.DROP_RANGE+10
                        or math.abs(nz-cam.Z) > CFG.DROP_RANGE+10
                    ) then respawn=true end

                    if respawn then
                        nx=cam.X+(math.random()*2-1)*CFG.DROP_RANGE
                        ny=cam.Y+math.random()*CFG.DROP_HEIGHT
                        nz=cam.Z+(math.random()*2-1)*CFG.DROP_RANGE
                        d.part.Transparency=0.45+math.random()*0.25
                    end

                    d.pos=Vector3.new(nx,ny,nz)
                    d.part.CFrame=dropCF(d.pos)
                end

                local si = 1
                while si <= #activeSplash do
                    local s = activeSplash[si]
                    s.vy = s.vy + GY * dt
                    local px = s.part.Position.X + s.vx * dt
                    local py = s.part.Position.Y + s.vy * dt
                    local pz = s.part.Position.Z + s.vz * dt
                    s.life = s.life - dt
                    s.part.Transparency = 0.38 + 0.58 * (1 - s.life / s.maxL)
                    s.part.CFrame = CFrame.new(px, py, pz)
                    if s.life <= 0 or py < lowY then
                        freeSplash(s.part); table.remove(activeSplash, si)
                    else si = si + 1 end
                end
            end)
        )

        local function reapplyOnSpawn()
            task.wait(0.4)
            if activeWeather ~= "rtxrain" then return end
            Lighting.TimeOfDay         = "13:30:00"
            Lighting.Brightness        = 1.4
            Lighting.OutdoorAmbient    = Color3.fromRGB(45, 55, 75)
            Lighting.Ambient           = Color3.fromRGB(65, 78, 98)
            Lighting.GlobalShadows     = true
            Lighting.ShadowSoftness    = 0.2
            Lighting.FogColor          = Color3.fromRGB(120, 125, 130)
            Lighting.FogStart          = 20
            Lighting.FogEnd            = 175

            applyRainLightingEffects()

            local terrain = workspace:FindFirstChildOfClass("Terrain")
            if terrain and not terrain:FindFirstChild("RTXRainClouds") then
                local cl = Instance.new("Clouds")
                cl.Name = "RTXRainClouds"; cl.Cover = 0.88
                cl.Density = 0.80; cl.Color = Color3.fromRGB(55, 65, 80)
                cl.Parent = terrain
            end
        end
        local charConn = lp.CharacterAdded:Connect(reapplyOnSpawn)
        table.insert(rtxRainState.conns, charConn)

        currentCleanupFn = function()
            rtxRainState.active = false
            unregisterRTXShader("rtxrain")
            for _, c in ipairs(rtxRainState.conns) do
                pcall(function() c:Disconnect() end)
            end
            if ROOT and ROOT.Parent then ROOT:Destroy() end
            clearAllPuddles()
            for _, s in ipairs(rtxRainState.sounds) do
                if s and s.Parent then s:Stop(); s:Destroy() end
            end

            for _, name in ipairs(RTXRAIN_NAMES) do
                local eff = Lighting:FindFirstChild(name)
                if eff then eff:Destroy() end
            end

            local terrain = workspace:FindFirstChildOfClass("Terrain")
            if terrain then
                local cl = terrain:FindFirstChild("RTXRainClouds")
                if cl then cl:Destroy() end
            end

            for prop, value in pairs(savedLighting) do
                pcall(function() Lighting[prop] = value end)
            end
            if removedSky then
                removedSky.Parent = Lighting
            end
        end
    end,
})

VisualTab:AddButton({
    Title = "🌅  RTX Sunset",
    Callback = function()
        local Lighting = game:GetService("Lighting")

        local function cleanup()
            local toRemove = {
                "RTXSunsetSky", "RTXSunsetAtmosphere", "RTXSunsetSunRays",
                "RTXSunsetBloom", "RTXSunsetColorCorrection", "RTXSunsetBlur",
            }
            for _, name in ipairs(toRemove) do
                local eff = Lighting:FindFirstChild(name)
                if eff then eff:Destroy() end
            end

            if _G.RTXSunsetSavedLighting then
                for prop, val in pairs(_G.RTXSunsetSavedLighting) do
                    pcall(function() Lighting[prop] = val end)
                end
                _G.RTXSunsetSavedLighting = nil
            end

            unregisterRTXShader("rtxsunset")
        end

        if activeWeather == "rtxsunset" then
            cleanup()
            currentCleanupFn = nil
            activeWeather = nil
            return
        end
        if activeWeather then
            notifyBlocked()
            return
        end
        activeWeather = "rtxsunset"
        currentCleanupFn = cleanup

        _G.RTXSunsetSavedLighting = {
            ClockTime = Lighting.ClockTime,
            GeographicLatitude = Lighting.GeographicLatitude,
            Brightness = Lighting.Brightness,
            ExposureCompensation = Lighting.ExposureCompensation,
            GlobalShadows = Lighting.GlobalShadows,
            ShadowSoftness = Lighting.ShadowSoftness,
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient,
            FogColor = Lighting.FogColor,
            FogStart = Lighting.FogStart,
            FogEnd = Lighting.FogEnd,
            EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
            EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
            ColorShift_Top = Lighting.ColorShift_Top,
            ColorShift_Bottom = Lighting.ColorShift_Bottom,
        }

        Lighting.ClockTime = 16.6
        Lighting.GeographicLatitude = 42.0
        Lighting.Brightness = 1.15
        Lighting.ExposureCompensation = 0.35
        Lighting.GlobalShadows = true
        Lighting.ShadowSoftness = 0.15
        Lighting.Ambient = Color3.fromRGB(90, 65, 35)
        Lighting.OutdoorAmbient = Color3.fromRGB(175, 125, 60)
        Lighting.FogColor = Color3.fromRGB(220, 175, 100)
        Lighting.FogStart = 600
        Lighting.FogEnd = 3000
        Lighting.EnvironmentDiffuseScale = 0.72
        Lighting.EnvironmentSpecularScale = 0.80
        Lighting.ColorShift_Top = Color3.fromRGB(255, 180, 100)
        Lighting.ColorShift_Bottom = Color3.fromRGB(150, 110, 60)

        local RTXSUNSET_NAMES = {
            "RTXSunsetSky", "RTXSunsetAtmosphere", "RTXSunsetSunRays",
            "RTXSunsetBloom", "RTXSunsetColorCorrection", "RTXSunsetBlur",
        }

        local function addIfMissing(className, props)
            if Lighting:FindFirstChild(props.Name) then return end
            local inst = Instance.new(className)
            for k, v in pairs(props) do inst[k] = v end
            inst.Parent = Lighting
        end

        local function applySunsetLightingEffects()
            addIfMissing("Sky", {
                Title = "RTXSunsetSky",
                CelestialBodiesShown = true,
                MoonAngularSize = 11,
                MoonTextureId = "rbxasset://sky/moon.jpg",
                SkyboxBk = "http://www.roblox.com/asset/?id=151165214",
                SkyboxDn = "http://www.roblox.com/asset/?id=151165197",
                SkyboxFt = "http://www.roblox.com/asset/?id=151165224",
                SkyboxLf = "http://www.roblox.com/asset/?id=151165191",
                SkyboxRt = "http://www.roblox.com/asset/?id=151165206",
                SkyboxUp = "http://www.roblox.com/asset/?id=151165227",
                StarCount = 3000,
                SunAngularSize = 10,
                SunTextureId = "rbxasset://sky/sun.jpg"
            })

            addIfMissing("Atmosphere", {
                Title = "RTXSunsetAtmosphere",
                Density = 0.364,
                Offset = 0.556,
                Color = Color3.fromRGB(199, 175, 166),
                Haze = 1.3,
                Glare = 0.2,
                Decay = Color3.fromRGB(44, 39, 33)
            })

            addIfMissing("SunRaysEffect", {
                Title = "RTXSunsetSunRays",
                Intensity = 0.1,
                Spread = 0.727,
                Enabled = true
            })

            addIfMissing("BloomEffect", {
                Title = "RTXSunsetBloom",
                Intensity = 0.08,
                Size = 5,
                Threshold = 1.1,
                Enabled = true
            })

            addIfMissing("ColorCorrectionEffect", {
                Title = "RTXSunsetColorCorrection",
                Brightness = 0.1,
                Contrast = 0.2,
                Saturation = -0.3,
                TintColor = Color3.fromRGB(255, 235, 203),
                Enabled = true
            })

            addIfMissing("BlurEffect", {
                Title = "RTXSunsetBlur",
                Size = 2.0,
                Enabled = true
            })
        end

        applySunsetLightingEffects()
        registerRTXShader("rtxsunset", RTXSUNSET_NAMES, applySunsetLightingEffects)
    end,
})

VisualTab:AddButton({
    Title = "❄️ RTX Snow",
    Callback = function()
        local Lighting = game:GetService("Lighting")
        local RunService = game:GetService("RunService")
        local Camera = workspace.CurrentCamera
        local Player = game:GetService("Players").LocalPlayer
        local snowPartName = "CustomSnow"

local function cleanup()
    if _G.RTXSnowConnection then _G.RTXSnowConnection:Disconnect() end
    if Camera:FindFirstChild(snowPartName) then Camera[snowPartName]:Destroy() end

    local toRemove = {"RTXSnowAtmosphere", "RTXSnowCC", "RTXSnowBloom", "RTXSnowSky"}
    for _, name in ipairs(toRemove) do
        local eff = Lighting:FindFirstChild(name)
        if eff then eff:Destroy() end
    end

    if _G.RTXSnowSavedLighting then
        for prop, val in pairs(_G.RTXSnowSavedLighting) do
            pcall(function() Lighting[prop] = val end)
        end
        _G.RTXSnowSavedLighting = nil
    end

    unregisterRTXShader("rtxsnow")
end

        if activeWeather == "rtxsnow" then
            cleanup()
            currentCleanupFn = nil
            activeWeather = nil
            return
        end
        if activeWeather then
            notifyBlocked()
            return
        end
        activeWeather = "rtxsnow"
        currentCleanupFn = cleanup

_G.RTXSnowSavedLighting = {
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ClockTime = Lighting.ClockTime,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
    FogColor = Lighting.FogColor
}

        Lighting.Brightness = 1.08
        Lighting.Ambient = Color3.fromRGB(150, 160, 180)
        Lighting.OutdoorAmbient = Color3.fromRGB(180, 170, 190)
        Lighting.ClockTime = 0.55
        Lighting.FogStart = 66
        Lighting.FogEnd = 155
        Lighting.FogColor = Color3.fromRGB(210, 220, 235)

        local RTXSNOW_NAMES = {"RTXSnowSky", "RTXSnowAtmosphere", "RTXSnowCC", "RTXSnowBloom"}

        local function addIfMissing(className, props)
            if Lighting:FindFirstChild(props.Name) then return end
            local inst = Instance.new(className)
            for k, v in pairs(props) do inst[k] = v end
            inst.Parent = Lighting
        end

        local function applySnowLightingEffects()
            addIfMissing("Sky", {
                Title = "RTXSnowSky",
                CelestialBodiesShown = true,
                MoonAngularSize = 11,
                MoonTextureId = "rbxasset://sky/moon.jpg",
                SunAngularSize = 10,
                SunTextureId = "rbxasset://sky/moon.jpg",
                StarCount = 3000,
                SkyboxBk = "http://www.roblox.com/asset/?id=134364569",
                SkyboxDn = "http://www.roblox.com/asset/?id=134364429",
                SkyboxFt = "http://www.roblox.com/asset/?id=134364439",
                SkyboxLf = "http://www.roblox.com/asset/?id=134364507",
                SkyboxRt = "http://www.roblox.com/asset/?id=134364451",
                SkyboxUp = "http://www.roblox.com/asset/?id=134364512"
            })

            addIfMissing("Atmosphere", {
                 Title = "RTXSnowAtmosphere",
                 Density = 0.45,
                 Offset = 0.25,
                 Glare = 4,
                 Haze = 8,
                 Color = Color3.fromRGB(215, 225, 240),
                 Decay = Color3.fromRGB(140, 155, 180)
            })

            addIfMissing("ColorCorrectionEffect", {
                Title = "RTXSnowCC",
                Saturation = -0.6,
                Contrast = 0.4,
                TintColor = Color3.fromRGB(160, 200, 255)
            })

            addIfMissing("BloomEffect", {
                Title = "RTXSnowBloom",
                Intensity = 0.8,
                Size = 1.8,
                Threshold = 1.2,
            })
        end

applySnowLightingEffects()
        registerRTXShader("rtxsnow", RTXSNOW_NAMES, applySnowLightingEffects)

        local snowPart = Instance.new("Part", Camera)
        snowPart.Name = snowPartName
        snowPart.Transparency = 1
        snowPart.Anchored = true
        snowPart.CanCollide = false
        snowPart.CanTouch = false
        snowPart.CanQuery = false
        snowPart.EnableFluidForces = false
        snowPart.Size = Vector3.new(190, 170, 190)

        _G.RTXSnowConnection = RunService.RenderStepped:Connect(function()
            Lighting.ClockTime = 0.55
            
            local char = Player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                snowPart.CFrame = root.CFrame * CFrame.new(0, 40, 0)
            end
        end)

        local e1 = Instance.new("ParticleEmitter", snowPart)
        e1.Name = "ParticleEmitter"
        e1.Texture = "rbxassetid://242109931"
        e1.Brightness = 2
        e1.Color = ColorSequence.new(Color3.new(0.9, 0.92, 1))
        e1.LightEmission = 0.4
        e1.LightInfluence = 0.6
        e1.Orientation = Enum.ParticleOrientation.VelocityParallel
        e1.Size = NumberSequence.new(0.6)
        e1.Squash = NumberSequence.new(-0.7)
        e1.Transparency = NumberSequence.new(0.15)
        e1.EmissionDirection = Enum.NormalId.Bottom
        e1.Enabled = true
        e1.Lifetime = NumberRange.new(4, 6)
        e1.Rate = 4000
        e1.Rotation = NumberRange.new(-15, 15)
        e1.RotSpeed = NumberRange.new(40, 40)
        e1.Speed = NumberRange.new(6, 10)
        e1.SpreadAngle = Vector2.new(35, 35)
        e1.VelocitySpread = 40
        e1.Acceleration = Vector3.new(-8, -10, -8)
        e1.Drag = 0.5
        e1.LockedToPart = false
        e1.TimeScale = 1
        e1.VelocityInheritance = 0.4
        e1.FlipbookBlendFrames = true
        e1.FlipbookFramerate = NumberRange.new(1, 1)
        e1.FlipbookLayout = Enum.ParticleFlipbookLayout.None
        e1.FlipbookMode = Enum.ParticleFlipbookMode.Loop
        e1.Shape = Enum.ParticleEmitterShape.Box
        e1.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
        e1.ShapePartial = 1
        e1.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume

        local WIND_STRENGTH = 12

        task.spawn(function()
          while e1 and e1.Parent do
            task.wait(0.5)
            if not (e1 and e1.Parent) then break end
            local angle = math.random() * math.pi * 2
            e1.Acceleration = Vector3.new(
                math.cos(angle) * WIND_STRENGTH,
                -8 + math.random() * -4,
                math.sin(angle) * WIND_STRENGTH
            )
         end
     end)

        local e2 = Instance.new("ParticleEmitter", snowPart)
        e2.Name = "ParticleEmitter2"
        e2.Texture = "rbxassetid://6852254721"
        e2.Brightness = 1.5
        e2.Color = ColorSequence.new(Color3.new(0.9, 0.92, 1))
        e2.LightEmission = 0.2
        e2.LightInfluence = 0.6
        e2.Orientation = Enum.ParticleOrientation.FacingCameraWorldUp
        e2.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 10), NumberSequenceKeypoint.new(1, 14)})
        e2.Squash = NumberSequence.new(0)
        e2.Transparency = NumberSequence.new(0.88)
        e2.EmissionDirection = Enum.NormalId.Bottom
        e2.Enabled = true
        e2.Lifetime = NumberRange.new(2, 3)
        e2.Rate = 600
        e2.Rotation = NumberRange.new(180, 180)
        e2.RotSpeed = NumberRange.new(0, 0)
        e2.Speed = NumberRange.new(8, 8)
        e2.SpreadAngle = Vector2.new(30, 30)
        e2.VelocitySpread = 30
        e2.Acceleration = Vector3.new(0, -25, 0)
        e2.Drag = 0
        e2.LockedToPart = true
        e2.TimeScale = 1
        e2.VelocityInheritance = 0
        e2.Shape = Enum.ParticleEmitterShape.Sphere
    end
})

VisualTab:AddButton({
    Title = "Disable Shader",
    Description = "Turns off the current shader so you can use another one",
    Callback = function()
        turnOffCurrent()
        clearAllWeatherPartsOnMap()
        for id in pairs(_G.RTXShaderRegistry) do
            unregisterRTXShader(id)
        end
        Fluent:Notify({ Title = "Shaders", Content = "Shader disabled", Duration = 2 })
    end,
})

VisualTab:AddParagraph({ Title = "Emote Changer", Content = "" })
pcall(function()
local emoteSlots = {}
local savedEmoteData = {}
local emoteInputs = {}
local zombieStrideVariant = "1"
local solarSlayerVariant = "1"

local ZOMBIE_STRIDE_BLACKLIST = {
    classicdance = true,
    marching = true,
    mariachiband = true,
}

local SOLAR_SLAYER_BLACKLIST = {
    ["fastfooddelight"] = true,
    ["potionmash"]      = true,
    ["toytrainride"]    = true,
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function normalizeName(name)
    return name:lower():gsub("%s+", "")
end

local function fuzzyScore(query, target)
    query = normalizeName(query)
    target = normalizeName(target)

    if query == "" then return 0 end
    if query == target then return 1000 end
    if target:find(query, 1, true) then
        return 500 - (target:len() - query:len())
    end

    local qi = 1
    local qlen = query:len()
    local matched = 0
    local lastPos = 0
    local gapPenalty = 0

    for ti = 1, target:len() do
        if qi > qlen then break end
        local qc = query:sub(qi, qi)
        local tc = target:sub(ti, ti)
        if qc == tc then
            if lastPos ~= 0 then
                gapPenalty = gapPenalty + (ti - lastPos - 1)
            end
            lastPos = ti
            matched = matched + 1
            qi = qi + 1
        end
    end

    if matched < qlen then
        return nil
    end

    local score = 200 - gapPenalty - (target:len() - qlen)
    return score
end

local function fuzzyFindBest(query, candidates, getName)
    local bestItem, bestScore = nil, nil

    for _, item in ipairs(candidates) do
        local name = getName(item)
        local score = fuzzyScore(query, name)
        if score and (not bestScore or score > bestScore) then
            bestScore = score
            bestItem = item
        end
    end

    return bestItem, bestScore
end

local function isEmoteModule(obj)
    if not obj:IsA("ModuleScript") then return false end
    local ok, stats = pcall(require, obj)
    if not ok or type(stats) ~= "table" then return false end
    local equipInfo = stats.EquipInfo
    if type(equipInfo) ~= "table" then return false end
    return equipInfo.SlotType == "Emote"
end

local function scanEmotes()
    local items = ReplicatedStorage:FindFirstChild("Items")
    if not items then return {} end

    local emotes = {}
    local function scan(container)
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("ModuleScript") then
                if isEmoteModule(child) then
                    table.insert(emotes, child)
                end
            elseif child:IsA("Folder") or child:IsA("Configuration") or child:IsA("Model") then
                scan(child)
            end
        end
    end
    scan(items)
    return emotes
end

local function findEmote(name)
    return (fuzzyFindBest(name, scanEmotes(), function(e) return e.Name end))
end

local function getZombieEmote()
    return findEmote("ZombieStride")
end

local function getSolarEmote()
    return findEmote("SolarSlayer")
end

local function applyZombieVariantAnimations(zombieEmote, variant)
    if not zombieEmote then return nil end

    local newAnimId = nil

    local selection = zombieEmote:FindFirstChild("Selection")
    if selection then
        local variantFolder = selection:FindFirstChild(variant)
        if variantFolder then
            local sourceAnim = variantFolder:FindFirstChild("ZombieAnim")
            if sourceAnim then
                newAnimId = sourceAnim.AnimationId
                local mainAnim = zombieEmote:FindFirstChild("Animation")
                if mainAnim then
                    pcall(function() mainAnim.AnimationId = newAnimId end)
                end
            end
        end
    end

    return newAnimId
end

local function plainSwapEmote(currentEmote, selectEmote)
    local okC, currentStats = pcall(require, currentEmote)
    local okS, selectStats  = pcall(require, selectEmote)

    for _, child in ipairs(currentEmote:GetChildren()) do child:Destroy() end
    for _, child in ipairs(selectEmote:GetChildren()) do child:Clone().Parent = currentEmote end

    if okC and okS and type(currentStats) == "table" and type(selectStats) == "table" then
        for key, tbl in pairs(currentStats) do
            if type(tbl) == "table" then
                for k in pairs(tbl) do tbl[k] = nil end
                if selectStats[key] and type(selectStats[key]) == "table" then
                    for k, v in pairs(selectStats[key]) do tbl[k] = v end
                end
            end
        end
    end
end

local function applyZombieStride(currentName)
    local zombieEmote = getZombieEmote()
    if not zombieEmote then return false end

    local currentEmote = findEmote(currentName)
    if not currentEmote then return false end

    local nameLower = currentName:lower():gsub("%s+", "")

    if ZOMBIE_STRIDE_BLACKLIST[nameLower] then
        plainSwapEmote(currentEmote, zombieEmote)
        return true
    end

    applyZombieVariantAnimations(zombieEmote, zombieStrideVariant)

    local okC, currentStats = pcall(require, currentEmote)
    local okS, selectStats  = pcall(require, zombieEmote)

    for _, child in ipairs(currentEmote:GetChildren()) do child:Destroy() end
    for _, child in ipairs(zombieEmote:GetChildren()) do
        if child.Name == "Selection" then
            local selectionClone = child:Clone()
            for _, variantFolder in ipairs(selectionClone:GetChildren()) do
                if variantFolder.Name ~= zombieStrideVariant then
                    variantFolder:Destroy()
                end
            end
            selectionClone.Parent = currentEmote
        else
            child:Clone().Parent = currentEmote
        end
    end

    if okC and okS and type(currentStats) == "table" and type(selectStats) == "table" then
        for key, tbl in pairs(currentStats) do
            if type(tbl) == "table" then
                for k in pairs(tbl) do tbl[k] = nil end
                if selectStats[key] and type(selectStats[key]) == "table" then
                    for k, v in pairs(selectStats[key]) do tbl[k] = v end
                end
            end
        end
    end

    return true
end

local function applySolarSlayer(currentName)
    local solarEmote = getSolarEmote()
    if not solarEmote then return false end

    local currentEmote = findEmote(currentName)
    if not currentEmote then return false end

    local nameLower = currentName:lower():gsub("%s+", "")

    if SOLAR_SLAYER_BLACKLIST[nameLower] then
        plainSwapEmote(currentEmote, solarEmote)
        return true
    end

    local newAnimId = nil
    local selection = solarEmote:FindFirstChild("Selection")
    if selection then
        local vf = selection:FindFirstChild(solarSlayerVariant)
        if vf then
            local sa = vf:FindFirstChild("Animation")
            if sa then newAnimId = sa.AnimationId end
        end
    end

    local okC, currentStats = pcall(require, currentEmote)
    local okS, selectStats  = pcall(require, solarEmote)

    for _, child in ipairs(currentEmote:GetChildren()) do child:Destroy() end
    for _, child in ipairs(solarEmote:GetChildren()) do
        if child.Name == "Selection" then
            local folderClone = child:Clone()
            for _, variantFolder in ipairs(folderClone:GetChildren()) do
                if variantFolder.Name ~= solarSlayerVariant then
                    variantFolder:Destroy()
                end
            end
            folderClone.Parent = currentEmote
        else
            child:Clone().Parent = currentEmote
        end
    end

    if newAnimId then
        local mainAnim = currentEmote:FindFirstChild("Animation")
        if mainAnim then pcall(function() mainAnim.AnimationId = newAnimId end) end
    end

    if okC and okS and type(currentStats) == "table" and type(selectStats) == "table" then
        for key, tbl in pairs(currentStats) do
            if type(tbl) == "table" then
                for k in pairs(tbl) do tbl[k] = nil end
                if selectStats[key] and type(selectStats[key]) == "table" then
                    for k, v in pairs(selectStats[key]) do tbl[k] = v end
                end
            end
        end
    end

    return true
end

local function deepCopy(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = type(v) == "table" and deepCopy(v) or v
    end
    return copy
end

local function saveEmoteSnapshot()
    local emotes = scanEmotes()

    savedEmoteData = {}
    for _, emote in ipairs(emotes) do
        local clones = {}
        for _, child in ipairs(emote:GetChildren()) do
            table.insert(clones, child:Clone())
        end
        local ok, stats = pcall(require, emote)
        savedEmoteData[emote] = {
            originalName = emote.Name,
            children = clones,
            stats = (ok and type(stats) == "table") and deepCopy(stats) or nil,
        }
    end
end

local function restoreAllEmotes()
    if next(savedEmoteData) == nil then
        return
    end

    local restored = 0

    for emoteObj, data in pairs(savedEmoteData) do
        local ok = pcall(function()
            if not emoteObj or not emoteObj.Parent then return end
            emoteObj.Name = data.originalName
            for _, child in ipairs(emoteObj:GetChildren()) do child:Destroy() end
            for _, clone in ipairs(data.children) do clone:Clone().Parent = emoteObj end

            if data.stats then
                local okStats, stats = pcall(require, emoteObj)
                if okStats and type(stats) == "table" then
                    for key, tbl in pairs(stats) do
                        if type(tbl) == "table" then
                            for k in pairs(tbl) do tbl[k] = nil end
                            if data.stats[key] and type(data.stats[key]) == "table" then
                                for k, v in pairs(data.stats[key]) do tbl[k] = v end
                            end
                        end
                    end
                end
            end
        end)
        if ok then restored = restored + 1 end
    end

    Fluent:Notify({ Title = "Emote changer", Content = "Restored: " .. restored, Duration = 3 })
end

local function swapEmote(currentName, selectName)
local selectScoreSolar  = fuzzyScore(selectName, "SolarSlayer")
local selectScoreZombie = fuzzyScore(selectName, "ZombieStride")

if selectScoreSolar and (not selectScoreZombie or selectScoreSolar >= selectScoreZombie) then
    return applySolarSlayer(currentName)
end

if selectScoreZombie then
    return applyZombieStride(currentName)
end

    local currentEmote = findEmote(currentName)
    local selectEmote  = findEmote(selectName)
    if not currentEmote or not selectEmote then
        Fluent:Notify({ Title = "Emote changer", Content = "Emote not found", Duration = 3 })
        return false
    end

    plainSwapEmote(currentEmote, selectEmote)
    return true
end

saveEmoteSnapshot()

for i = 1, 12 do
    emoteSlots[i] = { current = "", select = "" }
    emoteInputs[i] = {}
    emoteInputs[i].current = VisualTab:AddInput("CurrentEmote", {
        Title = "Current emote " .. i,
        Placeholder = "Current emote",
        ClearOnFocus = false,
        Callback = function(Text) emoteSlots[i].current = Text end
    })
end

for i = 1, 12 do
    emoteInputs[i].select = VisualTab:AddInput("SelectEmote", {
        Title = "Select emote " .. i,
        Placeholder = "Select emote",
        ClearOnFocus = false,
        Callback = function(Text) emoteSlots[i].select = Text end
    })
end

local function applyAllEmotes(silent)
    local applied, skipped = 0, 0
    for i = 1, 12 do
        local c = emoteSlots[i].current or ""
        local s = emoteSlots[i].select  or ""
        if c ~= "" and s ~= "" then
            if swapEmote(c, s) then applied = applied + 1 end
        else
            skipped = skipped + 1
        end
    end
    if not silent then
        Fluent:Notify({ Title = "Emote changer ", Content = "Applied: " .. applied, Duration = 3 })
    end
end

VisualTab:AddButton({
    Title = "Apply all emotes",
    Callback = function() applyAllEmotes(false) end
})

VisualTab:AddButton({
    Title = "Restore all emotes",
    Callback = function() restoreAllEmotes() end
})

local BroomFixEnabled = true
local BroomFixC0 = CFrame.new(0.25, -1.125, 0.025) * CFrame.fromMatrix(
    Vector3.new(0, 0, 0),
    Vector3.new(1, 0, 1.192e-07),
    Vector3.new(0, 1, 0),
    Vector3.new(-1.192e-07, 0, 1)
) * CFrame.Angles(0, math.rad(-90), 0)

local watchedWelds = {}

local function applyBroomFix(handleWeld)
    if not handleWeld or not handleWeld.Parent then return false end
    local ok = pcall(function()
        handleWeld.C0 = BroomFixC0
        local handle = handleWeld.Parent:FindFirstChild("Handle")
        if handle then
            local parts = handle:IsA("BasePart") and {handle} or handle:GetDescendants()
            for _, part in ipairs(parts) do
                if part:IsA("BasePart") then
                    part.Transparency = 0
                    part.LocalTransparencyModifier = 0
                end
            end
        end
    end)
    return ok
end

local function watchWeld(handleWeld)
    if not handleWeld or watchedWelds[handleWeld] then return end
    watchedWelds[handleWeld] = true
    local conn
    conn = handleWeld:GetPropertyChangedSignal("C0"):Connect(function()
        if not BroomFixEnabled then return end
        if handleWeld.C0 ~= BroomFixC0 then
            applyBroomFix(handleWeld)
        end
    end)
    handleWeld.AncestryChanged:Connect(function(_, parent)
        if not parent then
            watchedWelds[handleWeld] = nil
            conn:Disconnect()
        end
    end)
end

local function fixAndWatchBroom()
    local fixedCount = 0
    local broomEmote = findEmote("Broom")
    if broomEmote then
        local character = broomEmote:FindFirstChild("CharacterClassic")
        local emoteModel = character and character:FindFirstChild("EmoteModel")
        local handleWeld = emoteModel and emoteModel:FindFirstChild("HandleWeld")
        if handleWeld and applyBroomFix(handleWeld) then
            fixedCount = fixedCount + 1
            watchWeld(handleWeld)
        end
    end
    local char = player.Character
    if char then
        local liveEmoteModel = char:FindFirstChild("EmoteModel")
        if liveEmoteModel then
            local liveWeld = liveEmoteModel:FindFirstChild("HandleWeld")
            if liveWeld and applyBroomFix(liveWeld) then
                fixedCount = fixedCount + 1
                watchWeld(liveWeld)
            end
        end
    end
    return fixedCount
end

VisualTab:AddToggle("BroomWeldFixToggle", {
    Title = "Broom R6 weld fix",
    Default = false,
    Callback = function(Value)
        BroomFixEnabled = Value
        if Value then
            local fixedCount = fixAndWatchBroom()
            Fluent:Notify({
                Title = "Emote changer",
                Content = fixedCount > 0 and ("HandleWeld C0 fixed: (" .. fixedCount .. ")") or "HandleWeld not found",
                Duration = 3
            })
        end
    end
})

VisualTab:AddDropdown("zombieStrideAnimationVariant", {
    Title = "Zombie Stride animation variant",
    Values = {"1", "2", "3"},
    Default = "1",
    Callback = function(option)
        zombieStrideVariant = type(option) == "table" and option[1] or option

        local zombieEmote = getZombieEmote()
        if not zombieEmote then return end

        local newAnimId = nil

        local selection = zombieEmote:FindFirstChild("Selection")
        if selection then
            local variantFolder = selection:FindFirstChild(zombieStrideVariant)
            if variantFolder then
                local sourceAnim = variantFolder:FindFirstChild("ZombieAnim")
                if sourceAnim then newAnimId = sourceAnim.AnimationId end
            end
        end

        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end

        if not newAnimId then return end

        for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
            local anim = track.Animation
            if anim and anim.Name == "ZombieAnim" then
                local wasLooped = track.Looped
                local timePos   = track.TimePosition
                local priority  = track.Priority

                track:Stop(0)

                local newAnim = Instance.new("Animation")
                newAnim.Name = "ZombieAnim"
                newAnim.AnimationId = newAnimId

                local newTrack = humanoid:LoadAnimation(newAnim)
                newTrack.Looped   = wasLooped
                newTrack.Priority = priority
                newTrack:Play(0)
                pcall(function() newTrack.TimePosition = timePos end)
            end
        end
    end,
})

VisualTab:AddDropdown("solarSlayerAnimationVariant", {
    Title = "Solar Slayer animation variant",
    Values = {"1", "2"},
    Default = "1",
    Callback = function(option)
        solarSlayerVariant = type(option) == "table" and option[1] or option

        local solarEmote = getSolarEmote()
        if not solarEmote then return end

        local newAnimId = nil

        local selection = solarEmote:FindFirstChild("Selection")
        if selection then
            local vf = selection:FindFirstChild(solarSlayerVariant)
            if vf then
                local sa = vf:FindFirstChild("Animation")
                if sa then newAnimId = sa.AnimationId end
            end
        end

        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end

        if not newAnimId then return end

        for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
            local anim = track.Animation
            if anim and anim.Name == "Animation" then
                local wasLooped = track.Looped
                local timePos   = track.TimePosition
                local priority  = track.Priority

                track:Stop(0)

                local newAnim = Instance.new("Animation")
                newAnim.Name = "Animation"
                newAnim.AnimationId = newAnimId

                local newTrack = humanoid:LoadAnimation(newAnim)
                newTrack.Looped   = wasLooped
                newTrack.Priority = priority
                newTrack:Play(0)
                pcall(function() newTrack.TimePosition = timePos end)
            end
        end
    end,
})

task.delay(1, function()
    for i = 1, 12 do
        local ic = emoteInputs[i] and emoteInputs[i].current
        local is = emoteInputs[i] and emoteInputs[i].select
        local cv = ic and ic.CurrentValue or ""
        local sv = is and is.CurrentValue or ""
        if cv ~= "" then emoteSlots[i].current = cv end
        if sv ~= "" then emoteSlots[i].select  = sv end
    end

    local hasAny = false
    for i = 1, 12 do
        if emoteSlots[i].current ~= "" and emoteSlots[i].select ~= "" then
            hasAny = true
            break
        end
    end

    if hasAny then applyAllEmotes(true) end
end)
end)

VisualTab:AddParagraph({ Title = "Unusual changer", Content = "" })

do local Players = game:GetService("Players")
local player = Players.LocalPlayer

local savedCosmeticData = {}
local unusualModules = {}
local originalColors = {}
local originalColors3 = {}

local BRIGHTNESS_THRESHOLD = 60

local function deepCopy(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            copy[k] = deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

local function luminance(color)
    return 0.299 * color.R * 255 + 0.587 * color.G * 255 + 0.114 * color.B * 255
end

local function isBright(color)
    return luminance(color) >= BRIGHTNESS_THRESHOLD
end

local function normalizeName(name)
    return name:lower():gsub("%s+", "")
end

local function scanUnusualModules()
    unusualModules = {}
    local objects = getgc(true)

    for _, obj in ipairs(objects) do
        if typeof(obj) == "Instance" and obj.ClassName == "ModuleScript" then
            if obj:IsDescendantOf(ReplicatedStorage.Items) then
                local ok, data = pcall(require, obj)
                if ok and type(data) == "table" and type(data.EquipInfo) == "table" and data.EquipInfo.SlotType == "Unusual" then
                    unusualModules[normalizeName(obj.Name)] = obj
                end
            end
        end
    end
end

local function findUnusualModule(name)
    if not name or name == "" then return nil end
    local query = normalizeName(name)

    local exact = unusualModules[query]
    if exact then return exact end

    for key, obj in pairs(unusualModules) do
        if key:find(query, 1, true) or query:find(key, 1, true) then
            return obj
        end
    end
    return nil
end

local function saveCosmeticSnapshot()
    savedCosmeticData = {}
    for key, moduleObj in pairs(unusualModules) do
        local clones = {}
        for _, child in ipairs(moduleObj:GetChildren()) do
            table.insert(clones, child:Clone())
        end

        local ok, stats = pcall(require, moduleObj)
        local statsCopy = nil
        if ok and type(stats) == "table" then
            statsCopy = deepCopy(stats)
        end

        savedCosmeticData[moduleObj] = {
            children = clones,
            stats = statsCopy,
        }
    end
end

local function copyUnusualInto(sourceName, targetName)
    local sourceObj = findUnusualModule(sourceName)
    local targetObj = findUnusualModule(targetName)

    if not sourceObj then
        Fluent:Notify({ Title = "Unusual changer", Content = "'" .. sourceName .. "' not found!", Duration = 3 })
        return false
    end
    if not targetObj then
        Fluent:Notify({ Title = "Unusual changer", Content = "'" .. targetName .. "' not found!", Duration = 3 })
        return false
    end

    local okS, sourceStats = pcall(require, sourceObj)
    local okT, targetStats = pcall(require, targetObj)

    for _, child in ipairs(targetObj:GetChildren()) do
        child:Destroy()
    end
    for _, child in ipairs(sourceObj:GetChildren()) do
        child:Clone().Parent = targetObj
    end

    if okS and okT and type(sourceStats) == "table" and type(targetStats) == "table" then
        for key, tbl in pairs(targetStats) do
            if type(tbl) == "table" then
                for k in pairs(tbl) do tbl[k] = nil end
                if sourceStats[key] and type(sourceStats[key]) == "table" then
                    for k, v in pairs(sourceStats[key]) do tbl[k] = v end
                end
            end
        end
    end

    originalColors[targetObj] = nil
    originalColors3[targetObj] = nil

    Fluent:Notify({ Title = "Unusual changer", Content = "Applied: 1", Duration = 2 })
    return true
end

local function findLocalPlayerRig()
    local plr = Players.LocalPlayer
    if not plr then return nil end

    for _, folder in ipairs(workspace:GetChildren()) do
        if folder.Name == "Rigs" and folder:IsA("Folder") then
            local rig = folder:FindFirstChild(plr.Name)
            if rig then
                return rig
            end
        end
    end
    return nil
end

local function collectPaintableSequence(obj)
    local list = {}
    for _, desc in ipairs(obj:GetDescendants()) do
        if desc:IsA("ParticleEmitter") or desc:IsA("Beam") or desc:IsA("Trail") then
            table.insert(list, desc)
        end
    end
    return list
end

local function collectPaintableColor3(obj)
    local list = {}
    for _, desc in ipairs(obj:GetDescendants()) do
        if desc:IsA("SurfaceAppearance") or desc:IsA("MeshPart") or desc:IsA("BasePart") then
            table.insert(list, desc)
        end
    end
    return list
end

local function getOriginalColorMap(root, paintableList)
    local map = originalColors[root]
    if not map then
        map = {}
        for _, inst in ipairs(paintableList) do
            local ok, seq = pcall(function() return inst.Color end)
            if ok then
                map[inst] = seq
            end
        end
        originalColors[root] = map
    else
        for _, inst in ipairs(paintableList) do
            if map[inst] == nil then
                local ok, seq = pcall(function() return inst.Color end)
                if ok then
                    map[inst] = seq
                end
            end
        end
    end
    return map
end

local function getOriginalColor3Map(root, paintableList)
    local map = originalColors3[root]
    if not map then
        map = {}
        for _, inst in ipairs(paintableList) do
            local ok, col = pcall(function() return inst.Color end)
            if ok then
                map[inst] = col
            end
        end
        originalColors3[root] = map
    else
        for _, inst in ipairs(paintableList) do
            if map[inst] == nil then
                local ok, col = pcall(function() return inst.Color end)
                if ok then
                    map[inst] = col
                end
            end
        end
    end
    return map
end

local function recolorSequenceFull(color)
    return ColorSequence.new(color)
end

local function recolorSequenceBrightOnly(originalSeq, color)
    local newKeypoints = {}
    for i, kp in ipairs(originalSeq.Keypoints) do
        local newColor = kp.Value
        if isBright(kp.Value) then
            newColor = color
        end
        table.insert(newKeypoints, ColorSequenceKeypoint.new(kp.Time, newColor))
    end

    if #newKeypoints == 1 then
        table.insert(newKeypoints, ColorSequenceKeypoint.new(math.min(1, newKeypoints[1].Time + 0.001), newKeypoints[1].Value))
    end

    local ok, result = pcall(function() return ColorSequence.new(newKeypoints) end)
    if ok then return result end
    return originalSeq
end

local function recolorColor3BrightOnly(originalColor, color)
    if isBright(originalColor) then
        return color
    end
    return originalColor
end

local function paintInstanceList(root, list, color, mode)
    local originalMap = getOriginalColorMap(root, list)
    local applied = 0

    for _, inst in ipairs(list) do
        local originalSeq = originalMap[inst]
        if originalSeq then
            pcall(function()
                if mode == "Full Recolor" then
                    inst.Color = recolorSequenceFull(color)
                else
                    inst.Color = recolorSequenceBrightOnly(originalSeq, color)
                end
            end)
            applied = applied + 1
        end
    end

    return applied
end

local function paintColor3List(root, list, color, mode)
    local originalMap = getOriginalColor3Map(root, list)
    local applied = 0

    for _, inst in ipairs(list) do
        local originalColor = originalMap[inst]
        if originalColor then
            pcall(function()
                if mode == "Full Recolor" then
                    inst.Color = color
                else
                    inst.Color = recolorColor3BrightOnly(originalColor, color)
                end
            end)
            applied = applied + 1
        end
    end

    return applied
end

local function applyPaint(targetName, color, mode, silent)
    local targetObj = findUnusualModule(targetName)
    local totalApplied = 0
    local foundAny = false

    if targetObj then
        local seqList = collectPaintableSequence(targetObj)
        local c3List  = collectPaintableColor3(targetObj)

        if #seqList > 0 then
            foundAny = true
            totalApplied = totalApplied + paintInstanceList(targetObj, seqList, color, mode)
        end
        if #c3List > 0 then
            foundAny = true
            totalApplied = totalApplied + paintColor3List(targetObj, c3List, color, mode)
        end
    end

    local rig = findLocalPlayerRig()
    if rig then
        local rigSeqList = collectPaintableSequence(rig)
        if #rigSeqList > 0 then
            foundAny = true
            totalApplied = totalApplied + paintInstanceList(rig, rigSeqList, color, mode)
        end
    end

    if not foundAny then
        return false
    end

    return true
end

scanUnusualModules()
saveCosmeticSnapshot()

local unusualSlot = { current = "", select = "" }
local unusualInputs = {}

unusualInputs.current = VisualTab:AddInput("currentUnusual", {
    Title = "Current unusual",
    Placeholder = "Current unusual",
    ClearOnFocus = false,
    Callback = function(Text) unusualSlot.current = Text end
})

unusualInputs.select = VisualTab:AddInput("selectUnusual", {
    Title = "Select unusual",
    Placeholder = "Select unusual",
    ClearOnFocus = false,
    Callback = function(Text) unusualSlot.select = Text end
})

VisualTab:AddButton({
    Title = "Apply unusual",
    Callback = function()
        if unusualSlot.current ~= "" and unusualSlot.select ~= "" then
            copyUnusualInto(unusualSlot.select, unusualSlot.current)
        else
            Fluent:Notify({ Title = "Unusual changer", Content = "Fill both fields.", Duration = 3 })
        end
    end
})

VisualTab:AddButton({
    Title = "Restore all unusuals",
    Callback = function()
        local restored, failed = 0, 0

        for moduleObj, data in pairs(savedCosmeticData) do
            local ok = pcall(function()
                if not moduleObj or not moduleObj.Parent then return end

                for _, child in ipairs(moduleObj:GetChildren()) do
                    child:Destroy()
                end
                for _, clone in ipairs(data.children) do
                    clone:Clone().Parent = moduleObj
                end

                if data.stats then
                    local okReq, stats = pcall(require, moduleObj)
                    if okReq and type(stats) == "table" then
                        for key, tbl in pairs(stats) do
                            if type(tbl) == "table" then
                                for k in pairs(tbl) do tbl[k] = nil end
                                if data.stats[key] and type(data.stats[key]) == "table" then
                                    for k, v in pairs(data.stats[key]) do tbl[k] = v end
                                end
                            end
                        end
                    end
                end
            end)

            if ok then
                restored = restored + 1
                originalColors[moduleObj] = nil
                originalColors3[moduleObj] = nil
            else
                failed = failed + 1
            end
        end

        Fluent:Notify({ Title = "Unusual changer", Content = "Restored: " .. restored, Duration = 3 })
    end
})

-- recolor section
VisualTab:AddParagraph({ Title = "Unusual Recolor", Content = "" })

local recolorTarget = ""
local recolorColor = Color3.fromRGB(255, 255, 255)
local recolorMode = "Bright Only"
local recolorEnabled = false
local rigWatchConnections = {}

local function disconnectRigWatch()
    for _, conn in ipairs(rigWatchConnections) do
        pcall(function() conn:Disconnect() end)
    end
    rigWatchConnections = {}
end

local function applyCurrentColor()
    applyPaint(recolorTarget, recolorColor, recolorMode, true)
end

local function watchRigsFolders()
    disconnectRigWatch()

    for _, folder in ipairs(workspace:GetChildren()) do
        if folder.Name == "Rigs" and folder:IsA("Folder") then
            table.insert(rigWatchConnections, folder.ChildAdded:Connect(function(child)
                local plr = Players.LocalPlayer
                if plr and child.Name == plr.Name then
                    task.wait()
                    reapplyIfEnabled()
                end
            end))
        end
    end
end

VisualTab:AddInput("recolorTarget", {
    Title = "Recolor target",
    Placeholder = "Unusual name that u have",
    ClearOnFocus = false,
    Callback = function(Text)
        recolorTarget = Text
        applyCurrentColor()
    end
})

VisualTab:AddDropdown("recolorMode", {
    Title = "Recolor mode",
    Values = {"Bright Only", "Full Recolor"},
    Default = "Bright Only",
    Multi = false,
    Callback = function(Option)
        recolorMode = type(Option) == "table" and Option[1] or Option
        applyCurrentColor()
    end
})

VisualTab:AddColorpicker("recolor", {
    Title = "Recolor",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(Color)
        recolorColor = Color
        applyCurrentColor()
    end
})

VisualTab:AddToggle("RecolorToggle", {
    Title = "Re-apply recolor on respawn",
    Default = false,
    Callback = function(Value)
        recolorEnabled = Value
        if recolorEnabled then
            watchRigsFolders()
            applyCurrentColor()
        else
            disconnectRigWatch()
        end
    end
})

player.CharacterAdded:Connect(function()
    task.wait(1)
    if recolorEnabled then
        originalColors[findLocalPlayerRig()] = nil
        originalColors3[findLocalPlayerRig()] = nil
        applyCurrentColor()
    end
end)

task.delay(1, function()
    local cv = unusualInputs.current and unusualInputs.current.CurrentValue or ""
    local sv = unusualInputs.select  and unusualInputs.select.CurrentValue  or ""

    if cv ~= "" then unusualSlot.current = cv end
    if sv ~= "" then unusualSlot.select  = sv end

    if unusualSlot.current ~= "" and unusualSlot.select ~= "" then
        copyUnusualInto(unusualSlot.select, unusualSlot.current)
    end
end)
end
--cosmetics changer
 VisualTab:AddParagraph({ Title = "Cosmetic changer", Content = "Current = cosmetic you own. Select = cosmetic you want." })

do
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local SLOT_COUNT = 3
    local cosmeticSlots = {}
    local cosmeticInputs = {}
    local cosSwaps = {}   -- ["atual_desejado"] = { current, target, a, b }

    for i = 1, SLOT_COUNT do
        cosmeticSlots[i] = { current = "", select = "" }
        cosmeticInputs[i] = {}
    end

    for i = 1, SLOT_COUNT do
        cosmeticInputs[i].current = VisualTab:AddInput(i == 1 and "CurrentCosmetic" or ("CurrentCosmetic" .. i), {
            Title = "Current cosmetic " .. i,
            Placeholder = "Cosmetic you own",
            ClearOnFocus = false,
            Callback = function(Text) cosmeticSlots[i].current = Text end,
        })
    end

    for i = 1, SLOT_COUNT do
        cosmeticInputs[i].select = VisualTab:AddInput(i == 1 and "SelectCosmetic" or ("SelectCosmetic" .. i), {
            Title = "Select cosmetic " .. i,
            Placeholder = "Cosmetic you want",
            ClearOnFocus = false,
            Callback = function(Text) cosmeticSlots[i].select = Text end,
        })
    end

    local function normalizeName(name)
        return (tostring(name):lower():gsub("%s+", ""))
    end

    -- Varre Items (so Folders/Models) ate achar uma pasta "Cosmetics" que
    -- contenha o cosmetico pedido. Cede o frame a cada 100 nos.
    local function findCosmetic(items, name)
        name = tostring(name or "")
        if name == "" then return nil end

        local wanted = normalizeName(name)
        local queue, head, visited = { items }, 1, 0
        local fuzzy = nil

        while head <= #queue do
            local node = queue[head]
            head += 1

            if node.Name == "Cosmetics" then
                local exact = node:FindFirstChild(name)
                if exact then return exact end
                if not fuzzy then
                    for _, child in ipairs(node:GetChildren()) do
                        if normalizeName(child.Name) == wanted then
                            fuzzy = child
                            break
                        end
                    end
                end
            end

            for _, child in ipairs(node:GetChildren()) do
                if child:IsA("Folder") or child:IsA("Model") then
                    table.insert(queue, child)
                end
            end

            visited += 1
            if visited % 100 == 0 then
                task.wait()
            end
        end

        if fuzzy then return fuzzy end

        -- Estrutura diferente: procura direto pelo nome dentro de Items.
        return items:FindFirstChild(name, true)
    end

    -- Troca o conteudo das duas pastas (A <-> B) passando por uma pasta temporaria.
    local function swapChildren(a, b)
        local temp = Instance.new("Folder")
        temp.Name = "__temp_cos_swap_" .. tostring(os.clock())
        temp.Parent = ReplicatedStorage

        local aKids = a:GetChildren()
        local bKids = b:GetChildren()

        for _, child in ipairs(aKids) do child.Parent = temp end
        for _, child in ipairs(bKids) do child.Parent = a end
        for _, child in ipairs(aKids) do child.Parent = b end

        temp:Destroy()
    end

    -- current = o que voce tem, target = o que voce quer.
    local function changeCosmetics(current, target)
        current = tostring(current or "")
        target = tostring(target or "")
        if current == "" or target == "" or current == target then
            return false
        end

        local key = current .. "_" .. target
        if cosSwaps[key] then
            return true   -- ja aplicado (evita desfazer sem querer)
        end

        local items = ReplicatedStorage:FindFirstChild("Items")
        if not items then return false end

        local a = findCosmetic(items, current)
        if not a then return false, current end
        local b = findCosmetic(items, target)
        if not b then return false, target end
        if a == b then return false end

        swapChildren(a, b)
        cosSwaps[key] = { current = current, target = target, a = a, b = b }
        return true
    end

    local function restoreCosmetics()
        local restored = 0
        local items = ReplicatedStorage:FindFirstChild("Items")

        for _, swap in pairs(cosSwaps) do
            local a, b = swap.a, swap.b
            if not (a and a.Parent and b and b.Parent) and items then
                a = findCosmetic(items, swap.current)
                b = findCosmetic(items, swap.target)
            end
            if a and b then
                swapChildren(a, b)
                restored += 1
            end
        end

        cosSwaps = {}
        return restored
    end

    local function applyAllCosmetics(silent)
        local applied, missing = 0, {}

        for i = 1, SLOT_COUNT do
            local c = cosmeticSlots[i].current or ""
            local sel = cosmeticSlots[i].select or ""
            if c ~= "" and sel ~= "" then
                local ok, notFound = changeCosmetics(c, sel)
                if ok then
                    applied += 1
                elseif notFound then
                    table.insert(missing, notFound)
                end
            end
        end

        if not silent then
            local msg = "Applied: " .. applied
            if #missing > 0 then
                msg = msg .. "\nNot found: " .. table.concat(missing, ", ")
            end
            Fluent:Notify({ Title = "Cosmetic changer", Content = msg, Duration = 4 })
        end
    end

    VisualTab:AddButton({ Title = "Apply all cosmetics", Callback = function()
        task.spawn(applyAllCosmetics, false)
    end })

    VisualTab:AddButton({ Title = "Restore all cosmetics", Callback = function()
        task.spawn(function()
            local restored = restoreCosmetics()
            Fluent:Notify({ Title = "Cosmetic changer", Content = "Restored: " .. restored, Duration = 3 })
        end)
    end })

    -- Aplica sozinho os valores salvos na config.
    task.delay(1, function()
        for i = 1, SLOT_COUNT do
            local ic = cosmeticInputs[i] and cosmeticInputs[i].current
            local is = cosmeticInputs[i] and cosmeticInputs[i].select
            local cv = ic and (ic.Value or ic.CurrentValue) or ""
            local sv = is and (is.Value or is.CurrentValue) or ""
            if cv ~= "" then cosmeticSlots[i].current = cv end
            if sv ~= "" then cosmeticSlots[i].select = sv end
        end

        for i = 1, SLOT_COUNT do
            if cosmeticSlots[i].current ~= "" and cosmeticSlots[i].select ~= "" then
                applyAllCosmetics(true)
                break
            end
        end
    end)
end
--item skin changer
VisualTab:AddParagraph({ Title = "Item skin changer", Content = "" })

do local ReplicatedStorage = game:GetService("ReplicatedStorage")

local savedToolSkinData = {}     -- Variants snapshot
local savedToolModuleData = {}   -- ItemPacks deepcopy snapshot
local savedDeployableData = {}   -- Loadout deepcopy snapshot

local skinInputs = {}
local skinSlots = {}

local DEPLOYABLE_KEYWORDS = {
    SpeedPad = { "speedpad", "speed pad" },
    Landmine = { "landmine", "land mine" },
    JumpPad  = { "jumppad" },
}

local deployableFields = {}

local function normalizeName(name)
    return name:lower():gsub("%s+", "")
end

local function fuzzyScore(query, target)
    query = normalizeName(query)
    target = normalizeName(target)

    if query == "" then return 0 end
    if query == target then return 1000 end
    if target:find(query, 1, true) then
        return 500 - (target:len() - query:len())
    end

    local qi = 1
    local qlen = query:len()
    local matched = 0
    local lastPos = 0
    local gapPenalty = 0

    for ti = 1, target:len() do
        if qi > qlen then break end
        local qc = query:sub(qi, qi)
        local tc = target:sub(ti, ti)
        if qc == tc then
            if lastPos ~= 0 then
                gapPenalty = gapPenalty + (ti - lastPos - 1)
            end
            lastPos = ti
            matched = matched + 1
            qi = qi + 1
        end
    end

    if matched < qlen then
        return nil
    end

    local score = 200 - gapPenalty - (target:len() - qlen)
    return score
end

local function fuzzyFindBest(query, candidates, getName)
    local bestItem, bestScore = nil, nil

    for _, item in ipairs(candidates) do
        local name = getName(item)
        local score = fuzzyScore(query, name)
        if score and (not bestScore or score > bestScore) then
            bestScore = score
            bestItem = item
        end
    end

    return bestItem, bestScore
end

local function matchesAnyKeyword(text, keywords)
    local normalized = normalizeName(text)
    for _, kw in ipairs(keywords) do
        if normalized == normalizeName(kw) then
            return true
        end
    end
    return false
end

local function findVariant(variantsFolder, name)
    return (fuzzyFindBest(name, variantsFolder:GetChildren(), function(v) return v.Name end))
end

local TOOL_NAMES = {"Cola","Breacher","Decoy","Flashlight","GrappleHook","Lantern","Timer"}

local itemPackModulesByType = nil -- { [normalizedTypeName] = { [normalizedVariantName] = ModuleScript } }

local function categorizeModule(moduleScript)
    local parent = moduleScript.Parent
    if not parent then return nil end
    return parent.Name
end

local function scanItemPackModules()
    if itemPackModulesByType then return itemPackModulesByType end

    local Items = ReplicatedStorage:FindFirstChild("Items")
    if not Items then
        itemPackModulesByType = {}
        return itemPackModulesByType
    end

    local itemPacks = Items:FindFirstChild("ItemPacks")
    local scanRoot = itemPacks or Items

    local found = {}

    for _, obj in ipairs(getgc(true)) do
        if typeof(obj) == "Instance" and obj:IsA("ModuleScript") and obj:IsDescendantOf(scanRoot) then
            local typeName = categorizeModule(obj)
            if typeName then
                local typeKey = normalizeName(typeName)
                found[typeKey] = found[typeKey] or {}
                found[typeKey][normalizeName(obj.Name)] = obj
            end
        end
    end

    itemPackModulesByType = found
    return found
end

local function findItemPackModule(typeName, variantName)
    local byType = scanItemPackModules()
    local group = byType[normalizeName(typeName)]
    if not group then return nil end

    local candidates = {}
    for name, mod in pairs(group) do
        table.insert(candidates, mod)
    end

    return (fuzzyFindBest(variantName, candidates, function(m) return m.Name end))
end

local function replaceModuleContents(targetModule, sourceModule)
    local okS, sourceStats = pcall(require, sourceModule)
    local okT, targetStats = pcall(require, targetModule)

    for _, child in ipairs(targetModule:GetChildren()) do
        child:Destroy()
    end
    for _, child in ipairs(sourceModule:GetChildren()) do
        child:Clone().Parent = targetModule
    end

    if okS and okT and type(sourceStats) == "table" and type(targetStats) == "table" then
        for key, tbl in pairs(targetStats) do
            if type(tbl) == "table" then
                for k in pairs(tbl) do tbl[k] = nil end
                if sourceStats[key] and type(sourceStats[key]) == "table" then
                    for k, v in pairs(sourceStats[key]) do tbl[k] = v end
                end
            end
        end
    end
end

local function snapshotModuleFull(moduleScript)
    local snap = { children = {} }
    for _, child in ipairs(moduleScript:GetChildren()) do
        table.insert(snap.children, child:Clone())
    end
    local ok, stats = pcall(require, moduleScript)
    if ok and type(stats) == "table" then
        snap.stats = {}
        for key, tbl in pairs(stats) do
            if type(tbl) == "table" then
                local copy = {}
                for k, v in pairs(tbl) do copy[k] = v end
                snap.stats[key] = copy
            end
        end
    end
    return snap
end

local function restoreModuleFull(moduleScript, snap)
    for _, child in ipairs(moduleScript:GetChildren()) do child:Destroy() end
    for _, clone in ipairs(snap.children) do clone:Clone().Parent = moduleScript end

    if snap.stats then
        local ok, stats = pcall(require, moduleScript)
        if ok and type(stats) == "table" then
            for key, tbl in pairs(stats) do
                if type(tbl) == "table" then
                    for k in pairs(tbl) do tbl[k] = nil end
                    if snap.stats[key] and type(snap.stats[key]) == "table" then
                        for k, v in pairs(snap.stats[key]) do tbl[k] = v end
                    end
                end
            end
        end
    end
end

local function saveToolSkinSnapshot()
    local toolsFolder = ReplicatedStorage:FindFirstChild("Tools")
    if not toolsFolder then return end

    for _, toolName in ipairs(TOOL_NAMES) do
        local toolFolder = toolsFolder:FindFirstChild(toolName)
        if not toolFolder then continue end
        local variantsFolder = toolFolder:FindFirstChild("Variants")
        if not variantsFolder then continue end

        savedToolSkinData[toolName] = {}
        for _, variant in ipairs(variantsFolder:GetChildren()) do
            local entry = {}

            local charFolder = variant:FindFirstChild("Character")
            if charFolder then
                local toolObj = charFolder:FindFirstChild("Tool")
                if toolObj then entry.tool = toolObj:Clone() end
            end

            local vmFolder = variant:FindFirstChild("Viewmodel")
            if vmFolder then
                local vmObj = vmFolder:FindFirstChild("Viewmodel")
                if vmObj then entry.viewmodel = vmObj:Clone() end
            end

            savedToolSkinData[toolName][variant.Name] = entry
        end
    end
end

local function swapToolVariant(toolName, currentSkin, selectedSkin)
    local toolsFolder = ReplicatedStorage:FindFirstChild("Tools")
    if not toolsFolder then return false, "Tools folder not found" end

    local toolFolder = toolsFolder:FindFirstChild(toolName)
    if not toolFolder then return false, toolName .. " folder not found" end

    local variantsFolder = toolFolder:FindFirstChild("Variants")
    if not variantsFolder then return false, "Variants not found for " .. toolName end

    local currentVariant  = findVariant(variantsFolder, currentSkin)
    local selectedVariant = findVariant(variantsFolder, selectedSkin)
    if not currentVariant  then return false, "'" .. currentSkin .. "' not found" end
    if not selectedVariant then return false, "'" .. selectedSkin .. "' not found" end

    local currentChar  = currentVariant:FindFirstChild("Character")
    local selectedChar = selectedVariant:FindFirstChild("Character")
    if currentChar and selectedChar then
        local currentTool  = currentChar:FindFirstChild("Tool")
        local selectedTool = selectedChar:FindFirstChild("Tool")
        if currentTool and selectedTool then
            currentTool:Destroy()
            selectedTool:Clone().Parent = currentChar
        end
    end

    local currentVm  = currentVariant:FindFirstChild("Viewmodel")
    local selectedVm = selectedVariant:FindFirstChild("Viewmodel")
    if currentVm and selectedVm then
        local currentVmObj  = currentVm:FindFirstChild("Viewmodel")
        local selectedVmObj = selectedVm:FindFirstChild("Viewmodel")
        if currentVmObj and selectedVmObj then
            currentVmObj:Destroy()
            selectedVmObj:Clone().Parent = currentVm
        end
    end

    return true
end

local function swapToolModule(toolName, currentSkin, selectedSkin)
    local currentModule = findItemPackModule(toolName, currentSkin)
    local selectModule  = findItemPackModule(toolName, selectedSkin)

    if not currentModule then
        return false, "'" .. currentSkin .. "' module not found for " .. toolName
    end
    if not selectModule then
        return false, "'" .. selectedSkin .. "' module not found for " .. toolName
    end

    if not savedToolModuleData[currentModule] then
        savedToolModuleData[currentModule] = snapshotModuleFull(currentModule)
    end

    replaceModuleContents(currentModule, selectModule)
    return true
end

local function swapToolSkin(toolName, currentSkin, selectedSkin)
    local okVariant, errVariant = swapToolVariant(toolName, currentSkin, selectedSkin)
    local okModule, errModule = swapToolModule(toolName, currentSkin, selectedSkin)

    if okVariant or okModule then
        return true
    end

    return false, errVariant or errModule
end

local function findLoadoutDeployable(typeName)
    local Items = ReplicatedStorage:FindFirstChild("Items")
    if not Items then return nil end

    local baseItems = Items:FindFirstChild("BaseItems")
    if not baseItems then return nil end

    local loadout = baseItems:FindFirstChild("Loadout")
    if not loadout then return nil end

    local deployables = loadout:FindFirstChild("Deployables")
    if not deployables then return nil end

    local typeKey = normalizeName(typeName)
    for _, obj in ipairs(getgc(true)) do
        if typeof(obj) == "Instance" and obj:IsDescendantOf(deployables) and normalizeName(obj.Name) == typeKey then
            return obj
        end
    end
    return nil
end

local function swapLoadoutClient(typeName, selectSkinName)
    local deployableObj = findLoadoutDeployable(typeName)
    if not deployableObj then
        return false, typeName .. " not found in Loadout"
    end

    local sourceModule = findItemPackModule(typeName, selectSkinName)
    if not sourceModule then
        return false, "'" .. selectSkinName .. "' not found for " .. typeName
    end

    local sourceClient = sourceModule:FindFirstChild("Client")
    if not sourceClient then
        return false, "No Client in '" .. selectSkinName .. "'"
    end

    if not savedDeployableData[deployableObj] then
        local existingSnap = deployableObj:FindFirstChild("Client")
        savedDeployableData[deployableObj] = {
            mode = "client",
            client = existingSnap and existingSnap:Clone() or nil,
        }
    end

    local existing = deployableObj:FindFirstChild("Client")
    if existing then existing:Destroy() end
    sourceClient:Clone().Parent = deployableObj

    return true
end

local function swapDeployableModuleSkin(typeName, currentSkinName, selectSkinName)
    local currentModule = findItemPackModule(typeName, currentSkinName)
    local selectModule  = findItemPackModule(typeName, selectSkinName)

    if not currentModule then
        return false, "'" .. currentSkinName .. "' not found for " .. typeName
    end
    if not selectModule then
        return false, "'" .. selectSkinName .. "' not found for " .. typeName
    end

    if not savedDeployableData[currentModule] then
        savedDeployableData[currentModule] = {
            mode = "module",
            snap = snapshotModuleFull(currentModule),
        }
    end

    replaceModuleContents(currentModule, selectModule)
    return true
end

local function applyDeployableSkin(typeName, currentText, selectText, keywords)
    if selectText == "" then return true, "skip" end

    if currentText ~= "" and matchesAnyKeyword(currentText, keywords) then
        return swapLoadoutClient(typeName, selectText)
    end

    if currentText == "" then
        return false, "Current " .. typeName .. " field is empty"
    end

    return swapDeployableModuleSkin(typeName, currentText, selectText)
end

saveToolSkinSnapshot()

local DEPLOYABLE_UI = {
    { type = "SpeedPad", label = "speed pad" },
    { type = "Landmine", label = "landmine" },
    { type = "JumpPad",  label = "jump pad" },
}


skinSlots["Cola"] = { current = "", selected = "" }
skinInputs["Cola"] = {}
skinInputs["Cola"].current = VisualTab:AddInput("currentColaSkin", {
    Title = "Current cola skin",
    Placeholder = "Default or name of skin that u have",
    ClearOnFocus = false,
    Callback = function(Text) skinSlots["Cola"].current = Text end
})
skinInputs["Cola"].selected = VisualTab:AddInput("selectColaSkin", {
    Title = "Select cola skin",
    Placeholder = "Select cola skin",
    ClearOnFocus = false,
    Callback = function(Text) skinSlots["Cola"].selected = Text end
})

skinSlots["Breacher"] = { current = "", selected = "" }
skinInputs["Breacher"] = {}
skinInputs["Breacher"].current = VisualTab:AddInput("currentBreacherSkin", {
    Title = "Current breacher skin",
    Placeholder = "Default or name of skin that u have",
    ClearOnFocus = false,
    Callback = function(Text) skinSlots["Breacher"].current = Text end
})
skinInputs["Breacher"].selected = VisualTab:AddInput("selectBreacherSkin", {
    Title = "Select breacher skin",
    Placeholder = "Select breacher skin",
    ClearOnFocus = false,
    Callback = function(Text) skinSlots["Breacher"].selected = Text end
})

skinSlots["GrappleHook"] = { current = "", selected = "" }
skinInputs["GrappleHook"] = {}
skinInputs["GrappleHook"].current = VisualTab:AddInput("currentGrapplehookSkin", {
    Title = "Current grappleHook skin",
    Placeholder = "Default or name of skin that u have",
    ClearOnFocus = false,
    Callback = function(Text) skinSlots["GrappleHook"].current = Text end
})
skinInputs["GrappleHook"].selected = VisualTab:AddInput("selectGrapplehookSkin", {
    Title = "Select grappleHook skin",
    Placeholder = "Select grappleHook skin",
    ClearOnFocus = false,
    Callback = function(Text) skinSlots["GrappleHook"].selected = Text end
})

skinSlots["Flashlight"] = { current = "", selected = "" }
skinInputs["Flashlight"] = {}
skinInputs["Flashlight"].current = VisualTab:AddInput("currentFlashlightSkin", {
    Title = "Current flashlight skin",
    Placeholder = "Default or name of skin that u have",
    ClearOnFocus = false,
    Callback = function(Text) skinSlots["Flashlight"].current = Text end
})
skinInputs["Flashlight"].selected = VisualTab:AddInput("selectFlashlightSkin", {
    Title = "Select flashlight skin",
    Placeholder = "Select flashlight skin",
    ClearOnFocus = false,
    Callback = function(Text) skinSlots["Flashlight"].selected = Text end
})

skinSlots["Lantern"] = { current = "", selected = "" }
skinInputs["Lantern"] = {}
skinInputs["Lantern"].current = VisualTab:AddInput("currentLanternSkin", {
    Title = "Current lantern skin",
    Placeholder = "Default or name of skin that u have",
    ClearOnFocus = false,
    Callback = function(Text) skinSlots["Lantern"].current = Text end
})
skinInputs["Lantern"].selected = VisualTab:AddInput("selectLanternSkin", {
    Title = "Select lantern skin",
    Placeholder = "Select lantern skin",
    ClearOnFocus = false,
    Callback = function(Text) skinSlots["Lantern"].selected = Text end
})

skinSlots["Decoy"] = { current = "", selected = "" }
skinInputs["Decoy"] = {}
skinInputs["Decoy"].current = VisualTab:AddInput("currentDecoySkin", {
    Title = "Current decoy skin",
    Placeholder = "Default or name of skin that u have",
    ClearOnFocus = false,
    Callback = function(Text) skinSlots["Decoy"].current = Text end
})
skinInputs["Decoy"].selected = VisualTab:AddInput("selectDecoySkin", {
    Title = "Select decoy skin",
    Placeholder = "Select decoy skin",
    ClearOnFocus = false,
    Callback = function(Text) skinSlots["Decoy"].selected = Text end
})

skinSlots["Timer"] = { current = "", selected = "" }
skinInputs["Timer"] = {}
skinInputs["Timer"].current = VisualTab:AddInput("currentTimerSkin", {
    Title = "Current timer skin",
    Placeholder = "Default or name of skin that u have",
    ClearOnFocus = false,
    Callback = function(Text) skinSlots["Timer"].current = Text end
})
skinInputs["Timer"].selected = VisualTab:AddInput("selectTimerSkin", {
    Title = "Select timer skin",
    Placeholder = "Select timer skin",
    ClearOnFocus = false,
    Callback = function(Text) skinSlots["Timer"].selected = Text end
})

deployableFields["SpeedPad"] = { current = "", select = "" }
deployableFields["SpeedPad"].currentInput = VisualTab:AddInput("currentSpeedPad", {
    Title = "Current speed pad",
    Placeholder = "Speed pad or name of skin that u have",
    ClearOnFocus = false,
    Callback = function(Text) deployableFields["SpeedPad"].current = Text end
})
deployableFields["SpeedPad"].selectInput = VisualTab:AddInput("selectSpeedPad", {
    Title = "Select speed pad",
    Placeholder = "Select speed pad",
    ClearOnFocus = false,
    Callback = function(Text) deployableFields["SpeedPad"].select = Text end
})

deployableFields["JumpPad"] = { current = "", select = "" }
deployableFields["JumpPad"].currentInput = VisualTab:AddInput("currentJumpPad", {
    Title = "Current jump pad",
    Placeholder = "Jump pad or name of skin that u have",
    ClearOnFocus = false,
    Callback = function(Text) deployableFields["JumpPad"].current = Text end
})
deployableFields["JumpPad"].selectInput = VisualTab:AddInput("selectJumpPad", {
    Title = "Select jump pad",
    Placeholder = "Select jump pad",
    ClearOnFocus = false,
    Callback = function(Text) deployableFields["JumpPad"].select = Text end
})

deployableFields["Landmine"] = { current = "", select = "" }
deployableFields["Landmine"].currentInput = VisualTab:AddInput("currentLandmine", {
    Title = "Current landmine",
    Placeholder = "Landmine or name of skin that u have",
    ClearOnFocus = false,
    Callback = function(Text) deployableFields["Landmine"].current = Text end
})
deployableFields["Landmine"].selectInput = VisualTab:AddInput("selectLandmine", {
    Title = "Select landmine",
    Placeholder = "Select landmine",
    ClearOnFocus = false,
    Callback = function(Text) deployableFields["Landmine"].select = Text end
})

-- apply and restore

local function applyAllToolSkins(silent)
    local applied, skipped = 0, 0
    local firstError = nil

    for _, toolName in ipairs(TOOL_NAMES) do
        local c = skinSlots[toolName].current  or ""
        local s = skinSlots[toolName].selected or ""
        if c ~= "" and s ~= "" then
            local ok, err = swapToolSkin(toolName, c, s)
            if ok then
                applied = applied + 1
            else
                firstError = firstError or err
            end
        else
            skipped = skipped + 1
        end
    end

    for _, entry in ipairs(DEPLOYABLE_UI) do
        local typeName = entry.type
        local fields = deployableFields[typeName]
        local keywords = DEPLOYABLE_KEYWORDS[typeName]

        if fields.select == "" then
            skipped = skipped + 1
        else
            local ok, err = applyDeployableSkin(typeName, fields.current, fields.select, keywords)
            if ok then
                applied = applied + 1
            else
                firstError = firstError or err
            end
        end
    end

    if not silent then
        if firstError then
            Fluent:Notify({ Title = "Item skin changer", Content = firstError, Duration = 3 })
        else
            Fluent:Notify({ Title = "Item skin changer", Content = "Applied: " .. applied, Duration = 3 })
        end
    end
end

VisualTab:AddButton({
    Title = "Apply all item skins",
    Callback = function() applyAllToolSkins(false) end
})

VisualTab:AddButton({
    Title = "Restore all item skins",
    Callback = function()
        local restored = 0
        local toolsFolder = ReplicatedStorage:FindFirstChild("Tools")
        if toolsFolder then
            for toolName, variants in pairs(savedToolSkinData) do
                local toolFolder = toolsFolder:FindFirstChild(toolName)
                if toolFolder then
                    local variantsFolder = toolFolder:FindFirstChild("Variants")
                    if variantsFolder then
                        for variantName, entry in pairs(variants) do
                            local variant = variantsFolder:FindFirstChild(variantName)
                            if variant then
                                if entry.tool then
                                    local charFolder = variant:FindFirstChild("Character")
                                    if charFolder then
                                        local ok = pcall(function()
                                            local existing = charFolder:FindFirstChild("Tool")
                                            if existing then existing:Destroy() end
                                            entry.tool:Clone().Parent = charFolder
                                        end)
                                        if ok then restored = restored + 1 end
                                    end
                                end

                                if entry.viewmodel then
                                    local vmFolder = variant:FindFirstChild("Viewmodel")
                                    if vmFolder then
                                        local ok = pcall(function()
                                            local existing = vmFolder:FindFirstChild("Viewmodel")
                                            if existing then existing:Destroy() end
                                            entry.viewmodel:Clone().Parent = vmFolder
                                        end)
                                        if ok then restored = restored + 1 end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        for moduleScript, snap in pairs(savedToolModuleData) do
            if moduleScript and moduleScript.Parent then
                local ok = pcall(function()
                    restoreModuleFull(moduleScript, snap)
                end)
                if ok then restored = restored + 1 end
            end
            savedToolModuleData[moduleScript] = nil
        end

        for obj, data in pairs(savedDeployableData) do
            local ok = pcall(function()
                if not obj or not obj.Parent then return end

                if data.mode == "client" then
                    local existing = obj:FindFirstChild("Client")
                    if existing then existing:Destroy() end
                    if data.client then
                        data.client:Clone().Parent = obj
                    end
                elseif data.mode == "module" then
                    restoreModuleFull(obj, data.snap)
                end
            end)
            if ok then restored = restored + 1 end
            savedDeployableData[obj] = nil
        end

        Fluent:Notify({ Title = "Item skin changer", Content = "Restored: " .. restored, Duration = 3 })
    end
})

task.delay(1, function()
    for _, toolName in ipairs(TOOL_NAMES) do
        local ic = skinInputs[toolName] and skinInputs[toolName].current
        local is = skinInputs[toolName] and skinInputs[toolName].selected
        local cv = ic and ic.CurrentValue or ""
        local sv = is and is.CurrentValue or ""
        if cv ~= "" then skinSlots[toolName].current  = cv end
        if sv ~= "" then skinSlots[toolName].selected = sv end
    end

    local hasAny = false
    for _, toolName in ipairs(TOOL_NAMES) do
        if skinSlots[toolName].current ~= "" and skinSlots[toolName].selected ~= "" then
            hasAny = true
            break
        end
    end

    for _, entry in ipairs(DEPLOYABLE_UI) do
        local typeName = entry.type
        local fields = deployableFields[typeName]
        local ci = fields.currentInput and fields.currentInput.CurrentValue or ""
        local si = fields.selectInput  and fields.selectInput.CurrentValue  or ""
        if ci ~= "" then fields.current = ci end
        if si ~= "" then fields.select  = si end
        if fields.select ~= "" then hasAny = true end
    end

    if hasAny then applyAllToolSkins(true) end
end)
end
VisualTab:AddParagraph({ Title = "Carry animation changer", Content = "" })
pcall(function()
local savedCarryData = {}
local savedDefaultCarry = nil
local carrySlot = { current = "", select = "" }
local carryInputs = {}

local function deepCopyStats(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            copy[k] = deepCopyStats(v)
        else
            copy[k] = v
        end
    end
    return copy
end

local function isCarryAnimationModule(inst)
    if not inst:IsA("ModuleScript") then return false end
    local ok, stats = pcall(require, inst)
    if not ok or type(stats) ~= "table" then return false end
    local equipInfo = stats.EquipInfo
    if type(equipInfo) ~= "table" then return false end
    return equipInfo.SlotType == "CarryAnimation"
end

local function scanCarryAnimations()
    local result = {}
    local items = ReplicatedStorage:FindFirstChild("Items")
    if not items then return result end

    for _, inst in ipairs(items:GetDescendants()) do
        if isCarryAnimationModule(inst) then
            table.insert(result, inst)
        end
    end

    return result
end

local function findCarry(name)
    local nameLower = name:lower():gsub("%s+", "")
    for _, item in ipairs(scanCarryAnimations()) do
        if item.Name:lower():gsub("%s+", "") == nameLower then
            return item
        end
    end
    return nil
end

local function getDefaultCarryFolder()
    local objects = ReplicatedStorage:FindFirstChild("Objects")
    if not objects then return nil end
    local game_ = objects:FindFirstChild("Game")
    if not game_ then return nil end
    local character = game_:FindFirstChild("Character")
    if not character then return nil end
    local animations = character:FindFirstChild("Animations")
    if not animations then return nil end
    return animations:FindFirstChild("DefaultCarry")
end

local function isDefaultTarget(text)
    return text:lower():gsub("%s+", "") == "default"
end

local function saveCarrySnapshot()
    savedCarryData = {}
    for _, carry in ipairs(scanCarryAnimations()) do
        local clones = {}
        for _, child in ipairs(carry:GetChildren()) do
            table.insert(clones, child:Clone())
        end

        local ok, stats = pcall(require, carry)
        local statsCopy = nil
        if ok and type(stats) == "table" then
            statsCopy = deepCopyStats(stats)
        end

        savedCarryData[carry] = {
            originalName = carry.Name,
            children = clones,
            stats = statsCopy,
        }
    end

    local defaultCarry = getDefaultCarryFolder()
    if defaultCarry then
        local clones = {}
        for _, child in ipairs(defaultCarry:GetChildren()) do
            table.insert(clones, child:Clone())
        end

        local ok, stats = pcall(require, defaultCarry)
        local statsCopy = nil
        if ok and type(stats) == "table" then
            statsCopy = deepCopyStats(stats)
        end

        savedDefaultCarry = {
            children = clones,
            stats = statsCopy,
        }
    end
end

saveCarrySnapshot()

local function applyStatsMerge(targetStats, sourceStats)
    for key in pairs(targetStats) do
        targetStats[key] = nil
    end
    local function deepMerge(target, source)
        for k, v in pairs(source) do
            if type(v) == "table" then
                target[k] = {}
                deepMerge(target[k], v)
            else
                target[k] = v
            end
        end
    end
    deepMerge(targetStats, sourceStats)
end

local function applyCarrySwap(currentText, selectText)
    if currentText == "" or selectText == "" then
        Fluent:Notify({ Title="Carry animation changer", Content="Fill both fields.", Duration=3 })
        return
    end

    local selectedCarry = findCarry(selectText)
    if not selectedCarry then
        Fluent:Notify({ Title="Carry animation changer", Content="'"..selectText.."' not found!", Duration=3 })
        return
    end

    if isDefaultTarget(currentText) then
        local defaultCarry = getDefaultCarryFolder()
        if not defaultCarry then
            Fluent:Notify({ Title="Carry animation changer", Content="DefaultCarry not found!", Duration=3 })
            return
        end

        local okS, selectedStats = pcall(require, selectedCarry)
        local okC, currentStats = pcall(require, defaultCarry)

        for _, child in ipairs(defaultCarry:GetChildren()) do child:Destroy() end
        local applied = 0
        for _, child in ipairs(selectedCarry:GetChildren()) do
            child:Clone().Parent = defaultCarry
            applied = applied + 1
        end

        if okC and okS and type(currentStats) == "table" and type(selectedStats) == "table" then
            applyStatsMerge(currentStats, selectedStats)
        end

        Fluent:Notify({ Title="Carry animation changer", Content="Applied: "..applied, Duration=2 })
        return
    end

    local currentCarry = findCarry(currentText)
    if not currentCarry then
        Fluent:Notify({ Title="Carry animation changer", Content="'"..currentText.."' not found!", Duration=3 })
        return
    end

    local okC, currentStats  = pcall(require, currentCarry)
    local okS, selectedStats = pcall(require, selectedCarry)

    for _, child in ipairs(currentCarry:GetChildren())  do child:Destroy() end
    for _, child in ipairs(selectedCarry:GetChildren()) do child:Clone().Parent = currentCarry end
    selectedCarry.Name = currentCarry.Name

    if okC and okS and type(currentStats) == "table" and type(selectedStats) == "table" then
        applyStatsMerge(currentStats, selectedStats)
    end

    Fluent:Notify({ Title="Carry animation changer", Content=selectText.." → "..currentText, Duration=2 })
end

carryInputs.current = VisualTab:AddInput("currentCarryAnimation", { Title = "Current carry animation", Placeholder ="Default or name of carry that u have", ClearOnFocus = false, Callback=function(Text) carrySlot.current = Text end })
carryInputs.select  = VisualTab:AddInput("selectCarryAnimation", { Title = "Select carry animation",  Placeholder ="Select carry animation",  ClearOnFocus = false,  Callback=function(Text) carrySlot.select  = Text end })

VisualTab:AddButton({ Title = "Apply carry animation", Callback=function()
    applyCarrySwap(carrySlot.current, carrySlot.select)
end })

VisualTab:AddButton({ Title = "Restore all carry animations", Callback=function()
    local restored, failed = 0, 0

    for carryObj, data in pairs(savedCarryData) do
        pcall(function()
            if not carryObj or not carryObj.Parent then return end

            carryObj.Name = data.originalName

            for _, child in ipairs(carryObj:GetChildren()) do child:Destroy() end
            for _, clone in ipairs(data.children) do clone:Clone().Parent = carryObj end

            if data.stats then
                local ok, stats = pcall(require, carryObj)
                if ok and type(stats) == "table" then
                    for key, tbl in pairs(stats) do
                        if type(tbl) == "table" then
                            for k in pairs(tbl) do tbl[k] = nil end
                            if data.stats[key] and type(data.stats[key]) == "table" then
                                for k, v in pairs(data.stats[key]) do tbl[k] = v end
                            end
                        end
                    end
                end
            end

            restored = restored + 1
        end)
    end

    if savedDefaultCarry then
        pcall(function()
            local defaultCarry = getDefaultCarryFolder()
            if not defaultCarry then return end

            for _, child in ipairs(defaultCarry:GetChildren()) do child:Destroy() end
            for _, clone in ipairs(savedDefaultCarry.children) do clone:Clone().Parent = defaultCarry end

            if savedDefaultCarry.stats then
                local ok, stats = pcall(require, defaultCarry)
                if ok and type(stats) == "table" then
                    applyStatsMerge(stats, savedDefaultCarry.stats)
                end
            end

            restored = restored + 1
        end)
    end

    Fluent:Notify({ Title="Carry animation changer", Content="Restored: "..restored, Duration=3 })
end })

task.delay(1, function()
    local cv = carryInputs.current and carryInputs.current.CurrentValue or ""
    local sv = carryInputs.select  and carryInputs.select.CurrentValue  or ""

    if cv ~= "" then carrySlot.current = cv end
    if sv ~= "" then carrySlot.select  = sv end

    if carrySlot.current ~= "" and carrySlot.select ~= "" then
        applyCarrySwap(carrySlot.current, carrySlot.select)
    end
end)
end)

VisualTab:AddParagraph({ Title = "Custom Model Changer", Content = "" })
do
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")

    local guitarAssetId = "10244931512"
    local guitarEnabled = false
    local guitarScale = 0.8
    local offsetX, offsetY, offsetZ = 0, 1.5, 0
    local rotX, rotY, rotZ = 0, 0, 0

    -- [EmoteModel] = { model = Model, weld = ManualWeld, guitarHead = BasePart }
    local activeGuitars = setmetatable({}, { __mode = "k" })

    -- [BasePart] = originalTransparency, so we can restore it when the toggle is turned off
    local originalTransparency = setmetatable({}, { __mode = "k" })

    local itemsAddedConn = nil
    local itemsRemovedConn = nil
    local emoteWatchConns = setmetatable({}, { __mode = "k" }) -- [EmoteModel] = { conns... }
    local heartbeatConn = nil

    -- Only these two parents count as "RockinStride" emote models — never
    -- touch any other emote (Broom, FrightFunk, etc.) even if it also has
    -- a part named "Handle".
    local VALID_CHARACTER_NAMES = {
        Character = true,
        CharacterClassic = true,
    }

    -- The only thing that qualifies an EmoteModel as "the guitar one" is
    -- that it actually contains a GuitarHead part — nothing else (folder
    -- names, other emotes' own "Handle" parts, etc.) should ever qualify.
    local function isGuitarEmoteModel(emoteModel)
        if emoteModel.Name ~= "EmoteModel" then return false end
        local charFolder = emoteModel.Parent
        if not charFolder or not VALID_CHARACTER_NAMES[charFolder.Name] then return false end
        return emoteModel:FindFirstChild("GuitarHead", true) ~= nil
    end

    local function findGuitarHead(emoteModel)
        return emoteModel:FindFirstChild("GuitarHead", true)
    end

    local function findHandles(emoteModel)
        local handles = {}
        for _, desc in ipairs(emoteModel:GetDescendants()) do
            if desc.Name == "Handle" and desc:IsA("BasePart") then
                table.insert(handles, desc)
            end
        end
        return handles
    end

    local function rememberOriginalTransparency(part)
        if originalTransparency[part] == nil then
            originalTransparency[part] = part.Transparency
        end
    end

    local function applyEmoteTransparency(emoteModel)
        local guitarHead = findGuitarHead(emoteModel)
        if guitarHead then
            rememberOriginalTransparency(guitarHead)
            pcall(function() guitarHead.Transparency = 1 end)
        end
        for _, handle in ipairs(findHandles(emoteModel)) do
            rememberOriginalTransparency(handle)
            pcall(function() handle.Transparency = 1 end)
        end
    end

    local function restoreEmoteTransparency(emoteModel)
        local guitarHead = findGuitarHead(emoteModel)
        if guitarHead and originalTransparency[guitarHead] ~= nil then
            pcall(function() guitarHead.Transparency = originalTransparency[guitarHead] end)
            originalTransparency[guitarHead] = nil
        end
        for _, handle in ipairs(findHandles(emoteModel)) do
            if originalTransparency[handle] ~= nil then
                pcall(function() handle.Transparency = originalTransparency[handle] end)
                originalTransparency[handle] = nil
            end
        end
    end

    -- Instance classes we never want to keep from a loaded catalog asset —
    -- sounds, animations, scripts, cameras, and the Tool wrapper itself.
    local IGNORED_CLASSES = {
        Sound = true,
        Animation = true,
        AnimationController = true,
        Script = true,
        LocalScript = true,
        ModuleScript = true,
        Camera = true,
        Tool = true,
        StringValue = true,
        NumberValue = true,
        BoolValue = true,
        Attachment = true,
        Weld = true,
        WeldConstraint = true,
        Motor6D = true,
    }

    -- Recursively collects every BasePart from a loaded asset, ignoring
    -- sounds/animations/scripts/the Tool wrapper/etc, and welds them all
    -- into a single flat Model so there's exactly one rigid piece instead
    -- of a half-loaded skeleton of Models/Unions/Cylinders.
    local function buildFlatGuitarModel(loadedObjects)
        local parts = {}

        local function collect(inst)
            for _, child in ipairs(inst:GetChildren()) do
                if child:IsA("BasePart") then
                    table.insert(parts, child)
                    collect(child)
                elseif not IGNORED_CLASSES[child.ClassName] then
                    collect(child)
                end
            end
        end

        for _, obj in ipairs(loadedObjects) do
            if obj:IsA("BasePart") then
                table.insert(parts, obj)
                collect(obj)
            elseif not IGNORED_CLASSES[obj.ClassName] then
                collect(obj)
            end
        end

        if #parts == 0 then return nil end

        local model = Instance.new("Model")
        model.Name = "CustomRockinStride"

        -- Prefer a part literally named "Handle" as the root (standard
        -- Roblox catalog convention for tools); otherwise fall back to
        -- the largest part by volume.
        local root = nil
        for _, part in ipairs(parts) do
            if part.Name == "Handle" then
                root = part
                break
            end
        end
        if not root then
            local bestVolume = -1
            for _, part in ipairs(parts) do
                local size = part.Size
                local volume = size.X * size.Y * size.Z
                if volume > bestVolume then
                    bestVolume = volume
                    root = part
                end
            end
        end

        for _, part in ipairs(parts) do
            part.Parent = model
            part.Anchored = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.CastShadow = false
            part.Massless = true
        end

        for _, part in ipairs(parts) do
            if part ~= root then
                local weld = Instance.new("WeldConstraint")
                weld.Name = "GuitarPartWeld"
                weld.Part0 = root
                weld.Part1 = part
                weld.Parent = part
            end
        end

        -- Only the root needs to be free; WeldConstraint keeps every other
        -- part locked to it regardless of anchor state, and unanchoring
        -- everything at once (mid-loop, as before) gave physics a frame to
        -- nudge parts before their weld existed, which is what broke the
        -- guitar's shape.
        root.Anchored = false

        model.PrimaryPart = root
        return model, root
    end

    local function destroyGuitarFor(emoteModel)
        local entry = activeGuitars[emoteModel]
        if entry and entry.model and entry.model.Parent then
            entry.model:Destroy()
        end
        activeGuitars[emoteModel] = nil
    end

    local function loadGuitarFor(emoteModel)
        if guitarAssetId == "" then return end
        local assetId = guitarAssetId:match("%d+")
        if not assetId then return end

        local guitarHead = findGuitarHead(emoteModel)
        if not guitarHead then return end

        destroyGuitarFor(emoteModel)

        local success, result = pcall(function()
            return game:GetObjects("rbxassetid://" .. assetId)
        end)

        if not success or not result or #result == 0 then
            Fluent:Notify({Title="Rockin Stride",Content="Failed to load: "..tostring(result),Duration=5})
            return
        end

        local model, root = buildFlatGuitarModel(result)
        if not model or not root then
            Fluent:Notify({Title="Rockin Stride",Content="No usable parts found in asset!",Duration=5})
            return
        end

        pcall(function() model:ScaleTo(guitarScale) end)

        model.Parent = emoteModel

        local offset = CFrame.new(offsetX, offsetY, offsetZ)
            * CFrame.Angles(math.rad(rotX), math.rad(rotY), math.rad(rotZ))
        root.CFrame = guitarHead.CFrame * offset

        local weld = Instance.new("ManualWeld")
        weld.Name = "GuitarWeld"
        weld.Part0 = guitarHead
        weld.Part1 = root
        weld.C0 = CFrame.new(0, 0, 0)
        weld.C1 = (guitarHead.CFrame:Inverse() * root.CFrame):Inverse()
        weld.Parent = root

        activeGuitars[emoteModel] = { model = model, weld = weld, guitarHead = guitarHead }

        applyEmoteTransparency(emoteModel)
    end

    local function clearEmoteWatch(emoteModel)
        local conns = emoteWatchConns[emoteModel]
        if not conns then return end
        for _, conn in ipairs(conns) do
            conn:Disconnect()
        end
        emoteWatchConns[emoteModel] = nil
    end

    -- Watchdog: reapplies transparency if it drifts, and reloads the guitar
    -- model if it gets removed, for as long as guitarEnabled is true.
    -- Only ever attached to RockinStride's EmoteModel.
    local function watchEmoteModel(emoteModel)
        clearEmoteWatch(emoteModel)
        local conns = {}

        table.insert(conns, emoteModel.ChildRemoved:Connect(function(child)
            if not guitarEnabled then return end
            if child.Name == "CustomRockinStride" then
                task.defer(function()
                    if emoteModel.Parent then
                        loadGuitarFor(emoteModel)
                    end
                end)
            elseif child.Name == "GuitarHead" then
                destroyGuitarFor(emoteModel)
            end
        end))

        table.insert(conns, emoteModel.DescendantAdded:Connect(function(desc)
            if not guitarEnabled then return end
            if desc.Name == "GuitarHead" and desc:IsA("BasePart") then
                rememberOriginalTransparency(desc)
                pcall(function() desc.Transparency = 1 end)
                if not activeGuitars[emoteModel] then
                    loadGuitarFor(emoteModel)
                end
            elseif desc.Name == "Handle" and desc:IsA("BasePart") then
                rememberOriginalTransparency(desc)
                pcall(function() desc.Transparency = 1 end)
            end
        end))

        table.insert(conns, RunService.Heartbeat:Connect(function()
            if not guitarEnabled then return end
            if not emoteModel.Parent then
                clearEmoteWatch(emoteModel)
                return
            end
            local guitarHead = findGuitarHead(emoteModel)
            if guitarHead and guitarHead.Transparency ~= 1 then
                pcall(function() guitarHead.Transparency = 1 end)
            end
            for _, handle in ipairs(findHandles(emoteModel)) do
                if handle.Transparency ~= 1 then
                    pcall(function() handle.Transparency = 1 end)
                end
            end
        end))

        emoteWatchConns[emoteModel] = conns
    end

    local function handleNewEmoteModel(emoteModel)
        if not guitarEnabled then return end
        if not isGuitarEmoteModel(emoteModel) then return end
        applyEmoteTransparency(emoteModel)
        loadGuitarFor(emoteModel)
        watchEmoteModel(emoteModel)
    end

    local function forgetEmoteModel(emoteModel)
        clearEmoteWatch(emoteModel)
        destroyGuitarFor(emoteModel)
        restoreEmoteTransparency(emoteModel)
    end

    local function scanExistingEmoteModels(items)
        for _, desc in ipairs(items:GetDescendants()) do
            if isGuitarEmoteModel(desc) then
                handleNewEmoteModel(desc)
            end
        end
    end

    local function startWatcher()
        local items = ReplicatedStorage:FindFirstChild("Items")
        if not items then
            Fluent:Notify({Title="Rockin Stride",Content="ReplicatedStorage.Items not found!",Duration=5})
            return
        end

        scanExistingEmoteModels(items)

        -- Catches two cases: (1) a whole EmoteModel that already contains
        -- GuitarHead gets added, and (2) an EmoteModel gets added empty and
        -- GuitarHead is parented into it slightly later.
        itemsAddedConn = items.DescendantAdded:Connect(function(desc)
            if not guitarEnabled then return end

            if desc.Name == "EmoteModel" then
                if isGuitarEmoteModel(desc) then
                    handleNewEmoteModel(desc)
                end
            elseif desc.Name == "GuitarHead" and desc:IsA("BasePart") then
                local emoteModel = desc.Parent
                if emoteModel and isGuitarEmoteModel(emoteModel) and not activeGuitars[emoteModel] then
                    handleNewEmoteModel(emoteModel)
                end
            end
        end)

        itemsRemovedConn = items.DescendantRemoving:Connect(function(desc)
            if desc.Name == "EmoteModel" and isGuitarEmoteModel(desc) then
                forgetEmoteModel(desc)
            end
        end)
    end

    local function stopWatcher()
        if itemsAddedConn then
            itemsAddedConn:Disconnect()
            itemsAddedConn = nil
        end
        if itemsRemovedConn then
            itemsRemovedConn:Disconnect()
            itemsRemovedConn = nil
        end

        -- Snapshot keys before iterating: destroyGuitarFor/clearEmoteWatch
        -- mutate emoteWatchConns/activeGuitars by setting entries to nil,
        -- and mutating a table while pairs() is iterating it is undefined
        -- behavior in Lua — it was silently skipping entries, which is why
        -- some models never got their transparency restored.
        local watchedModels = {}
        for emoteModel in pairs(emoteWatchConns) do
            table.insert(watchedModels, emoteModel)
        end
        for _, emoteModel in ipairs(watchedModels) do
            clearEmoteWatch(emoteModel)
        end

        local guitaredModels = {}
        for emoteModel in pairs(activeGuitars) do
            table.insert(guitaredModels, emoteModel)
        end
        for _, emoteModel in ipairs(guitaredModels) do
            destroyGuitarFor(emoteModel)
            restoreEmoteTransparency(emoteModel)
        end
    end

    VisualTab:AddInput("guitarAssetId", {
        Title = "Guitar Asset ID",
        Placeholder = "10244931512",
        Default = "10244931512",
        ClearOnFocus = false,
        Callback = function(value)
            guitarAssetId = value ~= "" and value or "10244931512"
        end,
    })

    VisualTab:AddToggle("GuitarChangerToggle", {
        Title = "Custom guitar",
    Default = false,
        Callback = function(value)
            guitarEnabled = value
            if value then
                startWatcher()
            else
                stopWatcher()
            end
        end,
    })

    addNumericInput(VisualTab, "guitarScale", {
        Title = "Guitar Scale",
        Min = 0.1, Max = 5,
        Increment = 0.1,
        Rounding = 1,
        Default = 1,
        Callback = function(value)
            guitarScale = value
            for _, entry in pairs(activeGuitars) do
                if entry.model and entry.model.Parent then
                    pcall(function() entry.model:ScaleTo(guitarScale) end)
                end
            end
        end,
    })

    addNumericInput(VisualTab, "offsetX", {
        Title = "Offset X",
        Min = -5, Max = 5,
        Increment = 0.1,
        Rounding = 1,
        Default = 0,
        Callback = function(value) offsetX = value end,
    })

    addNumericInput(VisualTab, "offsetY", {
        Title = "Offset Y",
        Min = -5, Max = 5,
        Increment = 0.1,
        Rounding = 1,
        Default = 1,
        Callback = function(value) offsetY = value end,
    })

    addNumericInput(VisualTab, "offsetZ", {
        Title = "Offset Z",
        Min = -5, Max = 5,
        Increment = 0.1,
        Rounding = 1,
        Default = 0,
        Callback = function(value) offsetZ = value end,
    })

    heartbeatConn = RunService.Heartbeat:Connect(function()
        if not guitarEnabled then return end
        for emoteModel, entry in pairs(activeGuitars) do
            if not emoteModel.Parent then
                destroyGuitarFor(emoteModel)
            elseif entry.model and entry.model.Parent and entry.guitarHead and entry.guitarHead.Parent then
                local root = entry.model.PrimaryPart or entry.model:FindFirstChildWhichIsA("BasePart")
                if root then
                    local targetCFrame = entry.guitarHead.CFrame
                        * CFrame.new(offsetX, offsetY, offsetZ)
                        * CFrame.Angles(math.rad(rotX), math.rad(rotY), math.rad(rotZ))
                    root.CFrame = targetCFrame
                    if entry.weld and entry.weld.Parent then
                        entry.weld.C1 = (entry.guitarHead.CFrame:Inverse() * root.CFrame):Inverse()
                    end
                end
            end
        end
    end)
end

MapsTab:AddParagraph({ Title = "Map Loader", Content = "" })

local mapAssetId = ""
local mapScaleFactor = 1
local mapSpawnHeight = 0
local loadedMapModel = nil

local presetMaps = {
    { Name = "War map", Id = "106309926500291" },
}

local presetNames = {}
for _, v in ipairs(presetMaps) do
    table.insert(presetNames, v.Name)
end

MapsTab:AddDropdown("presetMaps", {
    Title = "Preset Maps",
    Values = presetNames,
    Default = "Select a map...",
    Callback = function(selected)
        local name = selected[1] or selected
        for _, v in ipairs(presetMaps) do
            if v.Name == name then
                mapAssetId = v.Id
                Fluent:Notify({ Title = "Map Loader", Content = "Selected: " .. name, Duration = 2 })
                break
            end
        end
    end,
})

MapsTab:AddInput("assetId", {
    Title = "Asset ID",
    Placeholder = "Enter Asset ID...",
    ClearOnFocus = false,
    Callback = function(value)
        mapAssetId = value:match("^%s*(.-)%s*$")
    end,
})

MapsTab:AddInput("scaleFactor", {
    Title = "Scale Factor",
    Placeholder = "Enter scale",
    ClearOnFocus = false,
    Callback = function(value)
        local num = tonumber(value)
        if num and num > 0 then
            mapScaleFactor = num
        end
    end,
})

MapsTab:AddInput("spawnHeight", {
    Title = "Spawn Height",
    Placeholder = "Enter height",
    ClearOnFocus = false,
    Callback = function(value)
        local num = tonumber(value)
        if num then
            mapSpawnHeight = num
        end
    end,
})

local function teleportToMap(map)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local cf
    if map:IsA("Model") then
        cf = map:GetModelCFrame()
    elseif map:IsA("BasePart") then
        cf = map.CFrame
    end

    if cf then
        hrp.CFrame = CFrame.new(cf.X, cf.Y + 300, cf.Z)
    end
end

MapsTab:AddButton({
    Title = "Load Map",
    Callback = function()
        local id = tonumber(mapAssetId)
        if not id then
            Fluent:Notify({ Title = "Map Loader", Content = "Invalid Asset ID", Duration = 3 })
            return
        end

        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            Fluent:Notify({ Title = "Map Loader", Content = "Character not found in game", Duration = 3 })
            return
        end

        if loadedMapModel and loadedMapModel.Parent then
            loadedMapModel:Destroy()
            loadedMapModel = nil
        end

        Fluent:Notify({ Title = "Map Loader", Content = "Loading...", Duration = 2 })

        task.spawn(function()
            local success, result = pcall(function()
                local objects = game:GetObjects("rbxassetid://" .. id)
                if not objects or #objects == 0 then error("No objects returned") end

                local map = objects[1]

                if map:IsA("Model") and mapScaleFactor ~= 1 then
                    map:ScaleTo(mapScaleFactor)
                end

                map.Parent = workspace
                task.wait()

                if map:IsA("Model") then
                    map:PivotTo(CFrame.new(0, mapSpawnHeight, 0))
                elseif map:IsA("BasePart") then
                    map.Position = Vector3.new(0, mapSpawnHeight, 0)
                end

                loadedMapModel = map

                local freshHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if freshHrp then
                    task.wait(0.1)
                    freshHrp.CFrame = CFrame.new(0, mapSpawnHeight + 100, 0)
                end
            end)

            if success then
                Fluent:Notify({ Title = "Map Loader", Content = "Map loaded! Teleporting...", Duration = 3 })
            else
                Fluent:Notify({ Title = "Map Loader", Content = "Failed: " .. tostring(result), Duration = 4 })
            end
        end)
    end,
})

MapsTab:AddButton({
    Title = "Remove Map",
    Callback = function()
        if loadedMapModel and loadedMapModel.Parent then
            loadedMapModel:Destroy()
            loadedMapModel = nil
            Fluent:Notify({ Title = "Map Loader", Content = "Map removed", Duration = 2 })
        else
            Fluent:Notify({ Title = "Map Loader", Content = "No map loaded", Duration = 2 })
        end
    end,
})

MapsTab:AddParagraph({ Title = "Custom Maps", Content = "" })

pcall(function()

local customLoadedMap = nil
local mapScaleValue = 1

MapsTab:AddInput("mapScale", {
    Title = "Map Scale",
    Placeholder = "Enter scale",
    ClearOnFocus = false,
    Default = "1",
    Callback = function(text)
        local num = tonumber(text)
        if num and num > 0 then
            mapScaleValue = num
        end
    end,
})

local mapHeightValue = -1000

MapsTab:AddInput("mapHeight", {
    Title = "Map Height",
    Placeholder = "Enter height",
    ClearOnFocus = false,
    Default = "-1000",
    Callback = function(text)
        local num = tonumber(text)
        if num then
            mapHeightValue = num
        end
    end,
})

local function loadMap(assetId, mapName)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if not char or not hrp then
        Fluent:Notify({ Title = "Custom Map", Content = "Character not found", Duration = 3 })
        return
    end

    if customLoadedMap and customLoadedMap.Parent then
        customLoadedMap:Destroy()
        customLoadedMap = nil
    end

    Fluent:Notify({ Title = "Custom Map", Content = "Loading " .. mapName .. "...", Duration = 2 })

    task.spawn(function()
        local success, result = pcall(function()
            local objects = game:GetObjects("rbxassetid://" .. assetId)
            if not objects or #objects == 0 then error("Asset returned empty result") end

            local container = Instance.new("Model")
            container.Name = mapName
            container.Parent = workspace

            for _, obj in ipairs(objects) do
                if typeof(obj) == "Instance" then
                    obj.Parent = container
                end
            end

            task.wait()

            if mapScaleValue ~= 1 then
                local pivot = container:GetPivot()
                for _, obj in ipairs(container:GetDescendants()) do
                    if obj:IsA("BasePart") and not obj:IsA("Terrain") then
                        obj.Size = obj.Size * mapScaleValue
                        local relCF = pivot:ToObjectSpace(obj.CFrame)
                        local scaledPos = relCF.Position * mapScaleValue
                        obj.CFrame = pivot * CFrame.new(scaledPos) * (relCF - relCF.Position)
                    end
                end
            end

            container:PivotTo(CFrame.new(0, mapHeightValue, 0))
            customLoadedMap = container

            local function findSpawn(parent)
                for _, obj in pairs(parent:GetChildren()) do
                    if obj.Name == "Map" then continue end
                    if obj:IsA("SpawnLocation") then return obj end
                    if obj:IsA("Folder") and obj.Name == "Spawn" then
                        local spawn = obj:FindFirstChildOfClass("SpawnLocation")
                        if spawn then return spawn end
                    end
                    local found = findSpawn(obj)
                    if found then return found end
                end
                return nil
            end

            local function teleportToSpawn()
                local c = player.Character
                local h = c and c:FindFirstChild("HumanoidRootPart")
                if not h then return end
                local spawnLocation = findSpawn(workspace)
                if spawnLocation then
                    h.CFrame = spawnLocation.CFrame + Vector3.new(0, 5, 0)
                else
                h.CFrame = CFrame.new(0, mapHeightValue + 10, 0)
                end
            end

            task.wait(0.1)
            teleportToSpawn()

            player.CharacterAdded:Connect(function(c)
                c:WaitForChild("HumanoidRootPart", 10)
                task.wait(0.1)
                if customLoadedMap and customLoadedMap.Parent then
                    teleportToSpawn()
                end
            end)
        end)

        if success then
            Fluent:Notify({ Title = "Custom Map", Content = mapName .. " loaded!", Duration = 3 })
        else
            Fluent:Notify({ Title = "Custom Map", Content = "Error: " .. tostring(result), Duration = 5 })
        end
    end)
end


MapsTab:AddButton({ Title = "Load NN_Russia",     Callback = function() loadMap("109911090838929",  "NN_Russia")     end })
MapsTab:AddButton({ Title = "Load NN_Outpost",    Callback = function() loadMap("128822473152020",  "NN_Outpost")    end })
MapsTab:AddButton({ Title = "Load NN_LostRuins",  Callback = function() loadMap("110864892116141",  "NN_LostRuins")  end })
MapsTab:AddButton({ Title = "Load VD Mercy Hospital",     Callback = function() loadMap("131056830668998",  "Mercy Hospital")     end })
MapsTab:AddButton({ Title = "Load Frost Year",    Callback = function() loadMap("140716368265143",  "Frost Year")    end })
MapsTab:AddButton({ Title = "Load Trimp map from legacy",    Callback = function() loadMap("93312304074940",  "Trimp")    end })

MapsTab:AddButton({
    Title = "Remove Custom Map",
    Callback = function()
        local removed = false
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Model") and (
                obj.Name == "NN_Russia" or obj.Name == "NN_Outpost" or
                obj.Name == "NN_Heights" or obj.Name == "NN_LostRuins" or
                obj.Name == "Frost Year" or obj.Name == "Mercy Hospital" or
                obj.Name == "Trimp"
            ) then
                obj:Destroy()
                removed = true
            end
        end
        if removed then
            Fluent:Notify({ Title = "Custom Maps", Content = "Map removed", Duration = 2 })
        else
            Fluent:Notify({ Title = "Custom Maps", Content = "No map loaded", Duration = 2 })
        end
    end,
})
end)

MainTab:AddParagraph({ Title = "Utilities unlocker", Content = "" })
pcall(function()
    local RS = game:GetService("ReplicatedStorage")
    local loadout = RS:WaitForChild("Items"):WaitForChild("BaseItems"):WaitForChild("Loadout")
    local toolsFolder = RS:WaitForChild("Tools")

    local function normalizeL(name)
        return name:lower():gsub("%s", ""):gsub("[^%a%d]", "")
    end

    -- !! Все require делаются ОДИН РАЗ здесь, при загрузке скрипта !!
    local loadoutCache = {}
    for _, module in ipairs(loadout:GetChildren()) do
        if module:IsA("ModuleScript") then
            local ok, data = pcall(require, module)
            if ok and type(data) == "table" then
                loadoutCache[normalizeL(module.Name)] = data
            end
        end
    end

    local toolCache = {}
    for _, obj in ipairs(toolsFolder:GetDescendants()) do
        if obj:IsA("ModuleScript") then
            local key = normalizeL(obj.Name)
            if not toolCache[key] then
                local ok, data = pcall(require, obj)
                if ok and type(data) == "table" then
                    toolCache[key] = data
                end
            end
        end
    end

    local function getLoadoutItem(name)
        return loadoutCache[normalizeL(name)]
    end

    local function getToolData(name)
        return toolCache[normalizeL(name)]
    end

    local function deepSet(tbl, key, value, visited)
        visited = visited or {}
        if type(tbl) ~= "table" or visited[tbl] then return end
        visited[tbl] = true
        for k, v in pairs(tbl) do
            if k == key then tbl[k] = value end
            if type(v) == "table" then deepSet(v, key, value, visited) end
        end
    end

    local function saveAndSet(tbl, key, newVal, store, visited)
        visited = visited or {}
        if type(tbl) ~= "table" or visited[tbl] then return end
        visited[tbl] = true
        for k, v in pairs(tbl) do
            if k == key then
                local id = tostring(tbl) .. "__" .. key
                if store[id] == nil then store[id] = v end
                tbl[k] = newVal
            end
            if type(v) == "table" then saveAndSet(v, key, newVal, store, visited) end
        end
    end

    local function restoreDeep(tbl, key, store, visited)
        visited = visited or {}
        if type(tbl) ~= "table" or visited[tbl] then return end
        visited[tbl] = true
        for k, v in pairs(tbl) do
            if k == key then
                local id = tostring(tbl) .. "__" .. key
                if store[id] ~= nil then tbl[k] = store[id] end
            end
            if type(v) == "table" then restoreDeep(v, key, store, visited) end
        end
    end
-- remove cooldown
local cdOriginals = {}
local cdEnabled = false

local CD_EXCEPTIONS = {
    ["stunbaton"] = 0.2,
    ["cola"] = 0.35,
}

local function collectCooldownNodes(data, results, visited)
    visited = visited or {}
    if type(data) ~= "table" or visited[data] then return end
    visited[data] = true
    for k, v in pairs(data) do
        if k == "Cooldown" and type(v) == "number" and v > 0 then
            table.insert(results, data)
        end
        if type(v) == "table" then
            collectCooldownNodes(v, results, visited)
        end
    end
end

local function collectKeybindActionTables(results)
    for _, v in ipairs(getgc(true)) do
        if type(v) == "table" and rawget(v, "Type") == "Keybind" and type(rawget(v, "Cooldown")) == "number" and v.Cooldown > 0 then
            table.insert(results, v)
        end
    end
end

local function applyZeroCooldowns()
    local count = 0

    for key, data in pairs(toolCache) do
        local exceptionCd = CD_EXCEPTIONS[key]
        local nodes = {}
        collectCooldownNodes(data, nodes)
        for _, info in ipairs(nodes) do
            local id = tostring(info)
            if cdOriginals[id] == nil then
                cdOriginals[id] = { tbl = info, orig = info.Cooldown }
                info.Cooldown = exceptionCd or 0
                count += 1
            end
        end
    end

    local keybindNodes = {}
    collectKeybindActionTables(keybindNodes)
    for _, info in ipairs(keybindNodes) do
        local id = tostring(info)
        if cdOriginals[id] == nil then
            local exceptionCd = CD_EXCEPTIONS[info.Keybind and info.Keybind:lower() or ""]
            cdOriginals[id] = { tbl = info, orig = info.Cooldown }
            info.Cooldown = exceptionCd or 0
            count += 1
        end
    end

    return count
end

local function restoreCooldowns()
    for _, e in pairs(cdOriginals) do
        if type(e.tbl) == "table" then
            e.tbl.Cooldown = e.orig
        end
    end
    cdOriginals = {}
end

local player = game:GetService("Players").LocalPlayer

player.CharacterAdded:Connect(function()
    if cdEnabled then
        task.wait(1)
        applyZeroCooldowns()
    end
end)

MainTab:AddToggle("ZeroCooldownsAll", {
    Title = "Tools cooldown remover",
    Default = false,
    Callback = function(value)
        cdEnabled = value
        if value then
            cdOriginals = {}
            local count = applyZeroCooldowns()
            Fluent:Notify({ Title = "Tools cooldown remover", Content = "Enabled (" .. count .. " tables)", Duration = 2 })
        else
            restoreCooldowns()
        end
    end,
})
    -- grapplehook patcher
    pcall(function()
        local grappleEnabled = false
        local grappleCached = nil
        local boostCached = nil
        local grappleOriginals = {}
        local origGrappleActivate = nil
        local origBoostActivate = nil
        local origBoostCooldown = nil
        local patchLoop = nil

        local function findGrappleTables()
            for _, v in ipairs(getgc(true)) do
                if type(v) == "table" then
                    if not grappleCached
                        and rawget(v, "Wheel") ~= nil
                        and rawget(v, "Wheel2") ~= nil
                        and rawget(v, "Names") ~= nil
                        and rawget(v, "Frame") ~= nil
                    then
                        local mt = getmetatable(v)
                        if mt and type(rawget(mt, "Activate")) == "function" then
                            grappleCached = v
                        end
                    end
                    if not boostCached and rawget(v, "FakeName") == "Boost" then
                        boostCached = v
                    end
                end
                if grappleCached and boostCached then break end
            end
        end

        local function patchGrapple()
            if grappleCached then
                local mt = getmetatable(grappleCached)
                if mt and type(rawget(mt, "Activate")) == "function" then
                    if not origGrappleActivate then origGrappleActivate = rawget(mt, "Activate") end
                    rawset(mt, "Activate", function(self, p33, p34)
                        self.Frame.Visible = false
                        if require(RS.Modules.Shared.TablesAndMethods.GetInteractType)() == "Keyboard" or p34 ~= true then
                            RS.Events.Character.Emote:FireServer(self.Names[p33])
                        end
                        self.Wheel.Current = nil
                        self.Wheel2.Current = nil
                        self.Frame.Wheel.Visible = true
                        self.Frame.Wheel2.Visible = false
                    end)
                end
            end
            if boostCached then
                if not origBoostCooldown then origBoostCooldown = boostCached.Cooldown end
                boostCached.Cooldown = 0.3
                local mt = getmetatable(boostCached)
                if mt and type(rawget(mt, "Activate")) == "function" then
                    if not origBoostActivate then origBoostActivate = rawget(mt, "Activate") end
                    rawset(mt, "Activate", function(self)
                        if tick() - (self.LastUsed or 0) > self.Cooldown then
                            if self.Character:GetAttribute("Teleported") ~= true then
                                self.LastUsed = tick()
                                return "Dodge"
                            end
                        end
                    end)
                end
            end
        end

        local function restoreGrapple()
            if grappleCached then
                local mt = getmetatable(grappleCached)
                if mt and origGrappleActivate then rawset(mt, "Activate", origGrappleActivate) end
            end
            if boostCached then
                if origBoostCooldown ~= nil then boostCached.Cooldown = origBoostCooldown end
                local mt = getmetatable(boostCached)
                if mt and origBoostActivate then rawset(mt, "Activate", origBoostActivate) end
            end
            origGrappleActivate = nil
            origBoostActivate = nil
            origBoostCooldown = nil
            grappleCached = nil
            boostCached = nil
        end

        MainTab:AddToggle("GrappleHookEnhance", {
            Title = "GrappleHook Enhance",
    Default = false,
            Callback = function(value)
                grappleEnabled = value
                if value then
                    local data = getToolData("GrappleHook")
                    if data then
                        if data.Actions and data.Actions.LookBack then
                            if grappleOriginals["LookBack_Enabled"] == nil then
                                grappleOriginals["LookBack_Enabled"] = data.Actions.LookBack["Enabled"]
                            end
                            data.Actions.LookBack["Enabled"] = true
                        end
                        saveAndSet(data, "Cap", 999, grappleOriginals)
                    end
                    if not grappleCached or not boostCached then findGrappleTables() end
                    patchGrapple()
                    if not patchLoop then
                        patchLoop = task.spawn(function()
                            while grappleEnabled do
                                task.wait(5)
                                if not grappleEnabled then break end
                                if not grappleCached or not boostCached then findGrappleTables() end
                                if grappleEnabled then patchGrapple() end
                            end
                            patchLoop = nil
                        end)
                    end
                    notify("GrappleHook Enhance", true)
                else
                    local data = getToolData("GrappleHook")
                    if data then
                        if data.Actions and data.Actions.LookBack and grappleOriginals["LookBack_Enabled"] ~= nil then
                            data.Actions.LookBack["Enabled"] = grappleOriginals["LookBack_Enabled"]
                        end
                        restoreDeep(data, "Cap", grappleOriginals)
                    end
                    restoreGrapple()
                    grappleOriginals = {}
                    notify("GrappleHook Enhance", false)
                end
            end,
        })
    end)

    -- breacher patcher
    pcall(function()
        local breacherOriginals = {}
        MainTab:AddToggle("BreacherEnhance", {
            Title = "Breacher Enhance",
    Default = false,
            Callback = function(value)
                local data = getToolData("Breacher")
                if not data then Fluent:Notify({ Title = "Breacher Enhance", Content = "Not found!", Duration = 3 }) return end
                if value then
                    breacherOriginals = {}
                    if data.Actions and data.Actions.LookBack then
                        breacherOriginals["LookBack_Enabled"] = data.Actions.LookBack["Enabled"]
                        data.Actions.LookBack["Enabled"] = true
                    end
                    saveAndSet(data, "Cap", 9999, breacherOriginals)
                    saveAndSet(data, "Range", 9999, breacherOriginals)
                    notify("Breacher Enhance", true)
                else
                    if data.Actions and data.Actions.LookBack and breacherOriginals["LookBack_Enabled"] ~= nil then
                        data.Actions.LookBack["Enabled"] = breacherOriginals["LookBack_Enabled"]
                    end
                    restoreDeep(data, "Cap", breacherOriginals)
                    restoreDeep(data, "Range", breacherOriginals)
                    breacherOriginals = {}
                    notify("Breacher Enhance", false)
                end
            end,
        })
    end)

    -- defibs patcher
    pcall(function()
        local defiOriginals = {}
        MainTab:AddToggle("DefibrillatorEnhance", {
            Title = "Defibrillator Enhance",
    Default = false,
            Callback = function(value)
                local data = getToolData("Defibrillator")
                if not data then Fluent:Notify({ Title = "Defibrillator Enhance", Content = "Not found!", Duration = 3 }) return end
                if value then
                    defiOriginals = {}
                    saveAndSet(data, "Range", 9999, defiOriginals)
                    notify("Defibrillator Enhance", true)
                else
                    restoreDeep(data, "Range", defiOriginals)
                    defiOriginals = {}
                    notify("Defibrillator Enhance", false)
                end
            end,
        })
    end)
end)

MainTab:AddParagraph({ Title = "Speed Changer", Content = "" })

pcall(function()
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseStats = require(ReplicatedStorage.Objects.Game.Character.Client.Movement.MoveStats.BaseStats)

local AirStrafeDefaults = {
    Speed = 1500,
    AirStrafeAcceleration = 182,
    JumpHeight = 3,
    Friction = 5,
}

local ORIGINAL_BASESTATS = {
    SprintAcceleration    = 1,
    Friction              = 5,
    RunAccel              = 1,
    AirStrafeAcceleration = 182,
    AirAcceleration       = 1,
    Speed                 = 1500,
    JumpHeight            = 3,
    JumpSpeedMultiplier   = 1.45,
}

local IGNORED_RV_DEFAULTS = {
    SprintAcceleration  = 1,
    JumpSpeedMultiplier = 1.45,
    RunAccel            = 1,
    Friction            = 5,
}

-- Live slider state. Only meaningful while Enabled == true.
local AirStrafeSettings = {
    Enabled = false,
    Speed = 1500,
    AirStrafeAcceleration = 182,
    AirAcceleration = 1,
    JumpHeight = 3,
    SprintAcceleration = 1,
    JumpSpeedMultiplier = 1.45,
    RunAccel = 1,
    Friction = 5,
}

local airStrafeRetryThread = nil
local rvRetryThread = nil
local watchdogThread = nil
local playersWatchConn = nil
local watchdogFolderConn = nil
local hardStrafeStateConn = nil

local cachedMoveStatsTables = nil
local spawnGeneration = 0

local function isHardStrafeActive()
    return _G.HardStrafeActive == true
end

local function isPlayerAlive()
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    return true
end

local function isInPlayersFolder()
    local ok, playersFolder = pcall(function() return workspace.Game.Players end)
    if not ok or not playersFolder then return false end
    return playersFolder:FindFirstChild(player.Name) ~= nil
end

local function computeExpected()
    local hsActive = isHardStrafeActive()
    return {
        SprintAcceleration  = AirStrafeSettings.SprintAcceleration,
        JumpSpeedMultiplier = hsActive and IGNORED_RV_DEFAULTS.JumpSpeedMultiplier or AirStrafeSettings.JumpSpeedMultiplier,
        RunAccel            = hsActive and IGNORED_RV_DEFAULTS.RunAccel or AirStrafeSettings.RunAccel,
        Friction            = hsActive and IGNORED_RV_DEFAULTS.Friction or AirStrafeSettings.Friction,
        JumpHeight          = hsActive and AirStrafeDefaults.JumpHeight or AirStrafeSettings.JumpHeight,
        Speed                 = AirStrafeSettings.Speed,
        AirStrafeAcceleration = AirStrafeSettings.AirStrafeAcceleration,
        AirAcceleration       = AirStrafeSettings.AirAcceleration,
    }
end

local function patchBaseStats()
    if not AirStrafeSettings.Enabled then return end
    local expected = computeExpected()
    for k, v in pairs(expected) do
        BaseStats[k] = v
    end
end

local function resetBaseStats()
    for k, v in pairs(ORIGINAL_BASESTATS) do
        BaseStats[k] = v
    end
end

local function scanForMoveStats()
    local results = {}
    for _, v in pairs(getgc(true)) do
        if type(v) == "table"
            and rawget(v, "AirStrafeAcceleration") ~= nil
            and rawget(v, "SprintAcceleration") ~= nil
            and rawget(v, "JumpCap") ~= nil
            and rawget(v, "Friction") ~= nil
        then
            table.insert(results, v)
        end
    end
    return results
end

local function getAllMoveStats()
    if cachedMoveStatsTables and #cachedMoveStatsTables > 0 then
        return cachedMoveStatsTables
    end
    local results = scanForMoveStats()
    if #results > 0 then
        cachedMoveStatsTables = results
    end
    return results
end

local function patchLiveMoveStats()
    if not AirStrafeSettings.Enabled then return false end

    local list = getAllMoveStats()
    if #list == 0 then return false end

    local expected = computeExpected()
    for _, v in ipairs(list) do
        for k, val in pairs(expected) do
            v[k] = val
        end
    end

    return true
end

local function resetLiveMoveStats()
    local list = getAllMoveStats()
    for _, v in ipairs(list) do
        v.SprintAcceleration    = ORIGINAL_BASESTATS.SprintAcceleration
        v.JumpSpeedMultiplier   = ORIGINAL_BASESTATS.JumpSpeedMultiplier
        v.RunAccel              = ORIGINAL_BASESTATS.RunAccel
        v.Friction              = ORIGINAL_BASESTATS.Friction
        v.Speed                 = ORIGINAL_BASESTATS.Speed
        v.AirStrafeAcceleration = ORIGINAL_BASESTATS.AirStrafeAcceleration
        v.AirAcceleration       = ORIGINAL_BASESTATS.AirAcceleration
        v.JumpHeight            = ORIGINAL_BASESTATS.JumpHeight
    end
end

local function applyAll()
    if not AirStrafeSettings.Enabled then return end
    patchBaseStats()
    patchLiveMoveStats()
end

local function resetAll()
    resetBaseStats()
    resetLiveMoveStats()
end

-- ===== retry threads (initial apply on spawn) =====

local function stopAirStrafeRetry()
    if airStrafeRetryThread then
        task.cancel(airStrafeRetryThread)
        airStrafeRetryThread = nil
    end
end

local function stopRVRetry()
    if rvRetryThread then
        task.cancel(rvRetryThread)
        rvRetryThread = nil
    end
end

local function tryApplyAirStrafe()
    stopAirStrafeRetry()
    if not AirStrafeSettings.Enabled then return end
    if not isPlayerAlive() then return end
    if not isInPlayersFolder() then return end

    local myGeneration = spawnGeneration

    airStrafeRetryThread = task.spawn(function()
        for _ = 1, 6 do
            if myGeneration ~= spawnGeneration then break end
            if not AirStrafeSettings.Enabled then break end
            if not isPlayerAlive() then break end
            if not isInPlayersFolder() then break end

            if patchLiveMoveStats() then break end
            task.wait(0.5)
        end
        airStrafeRetryThread = nil
    end)
end

local function tryApplyRV()
    stopRVRetry()
    if not AirStrafeSettings.Enabled then return end
    if not isPlayerAlive() then return end
    if not isInPlayersFolder() then return end

    local myGeneration = spawnGeneration

    rvRetryThread = task.spawn(function()
        for _ = 1, 6 do
            if myGeneration ~= spawnGeneration then break end
            if not isPlayerAlive() then break end
            if not isInPlayersFolder() then break end

            if patchLiveMoveStats() then break end
            task.wait(0.5)
        end
        rvRetryThread = nil
    end)
end

-- ===== watchdog: only alive while Enabled == true =====

local function valuesMatchExpected(list, expected)
    for _, v in ipairs(list) do
        for key, val in pairs(expected) do
            if v[key] ~= val then
                return false
            end
        end
    end

    for key, val in pairs(expected) do
        if BaseStats[key] ~= val then
            return false
        end
    end

    return true
end

local function stopWatchdog()
    if watchdogThread then
        task.cancel(watchdogThread)
        watchdogThread = nil
    end
end

local function startWatchdog()
    stopWatchdog()

    watchdogThread = task.spawn(function()
        while AirStrafeSettings.Enabled do
            task.wait(0.5)
            if not AirStrafeSettings.Enabled then break end
            if isPlayerAlive() and isInPlayersFolder() then
                local list = getAllMoveStats()
                local expected = computeExpected()
                if #list > 0 and not valuesMatchExpected(list, expected) then
                    applyAll()
                end
            end
        end
        watchdogThread = nil
    end)
end

-- ===== character lifecycle =====

local function onCharacterSpawned(char)
    spawnGeneration += 1
    cachedMoveStatsTables = nil

    if AirStrafeSettings.Enabled then
        patchBaseStats()
    end

    local hum = char:WaitForChild("Humanoid", 10)
    if hum then
        hum.Died:Connect(function()
            stopAirStrafeRetry()
            stopRVRetry()
        end)
    end

    task.wait(0.5)

    if AirStrafeSettings.Enabled then
        tryApplyAirStrafe()
        tryApplyRV()
    end
end

player.CharacterAdded:Connect(onCharacterSpawned)

player.CharacterRemoving:Connect(function()
    stopAirStrafeRetry()
    stopRVRetry()
end)

if player.Character then
    onCharacterSpawned(player.Character)
end

local function watchPlayersFolder()
    local ok, playersFolder = pcall(function() return workspace.Game.Players end)
    if not ok or not playersFolder then return end

    if playersWatchConn then
        playersWatchConn:Disconnect()
        playersWatchConn = nil
    end

    playersWatchConn = playersFolder.ChildAdded:Connect(function(child)
        if child.Name ~= player.Name then return end
        task.wait(0.3)
        if AirStrafeSettings.Enabled then
            if not airStrafeRetryThread then
                tryApplyAirStrafe()
            end
            if not rvRetryThread then
                tryApplyRV()
            end
        end
    end)
end

watchPlayersFolder()

task.spawn(function()
    while true do
        task.wait(2)
        local ok, playersFolder = pcall(function() return workspace.Game.Players end)
        if not ok or not playersFolder then continue end
        if not playersWatchConn or not playersWatchConn.Connected then
            watchPlayersFolder()
        end
    end
end)

-- Hooks NCP Movement calls into when HardStrafe toggles, so Speed Changer's
-- own values get re-asserted on top of whatever NCP just wrote.
_G.OnHardStrafeDisabled = function()
    cachedMoveStatsTables = nil
    if AirStrafeSettings.Enabled and isPlayerAlive() then
        applyAll()
    end
end

_G.OnHardStrafeEnabled = function()
    cachedMoveStatsTables = nil
    if AirStrafeSettings.Enabled and isPlayerAlive() then
        applyAll()
    end
end

-- React to HardStrafe state flips (affects which stat set is "expected").
local function stopHardStrafeStatePoll()
    if hardStrafeStateConn then
        task.cancel(hardStrafeStateConn)
        hardStrafeStateConn = nil
    end
end

local function startHardStrafeStatePoll()
    stopHardStrafeStatePoll()
    hardStrafeStateConn = task.spawn(function()
        local lastState = isHardStrafeActive()
        while AirStrafeSettings.Enabled do
            task.wait(0.2)
            if not AirStrafeSettings.Enabled then break end
            local currentState = isHardStrafeActive()
            if currentState ~= lastState then
                lastState = currentState
                cachedMoveStatsTables = nil
                if isPlayerAlive() then
                    applyAll()
                end
            end
        end
        hardStrafeStateConn = nil
    end)
end

MainTab:AddToggle("AirStrafeEnabled", {
    Title = "Strafe speed",
    Default = false,
    Callback = function(value)
    AirStrafeSettings.Enabled = value

    if value then
        cachedMoveStatsTables = nil
        applyAll()
        tryApplyAirStrafe()
        tryApplyRV()
        startWatchdog()
        startHardStrafeStatePoll()
    else
        stopAirStrafeRetry()
        stopRVRetry()
        stopWatchdog()
        stopHardStrafeStatePoll()

        if isPlayerAlive() then
            resetAll()
        else
            resetBaseStats()
        end
    end
end,
})

addNumericInput(MainTab, "speed", {
    Title = "Speed",
    Min = 1500, Max = 3000,
    Increment = 10,
    Rounding = 0,
    Default = 1500,
    Callback = function(value)
        AirStrafeSettings.Speed = value
        applyAll()
    end,
})

addNumericInput(MainTab, "airStrafeAcceleration", {
    Title = "Air Strafe Acceleration",
    Min = 182, Max = 5000,
    Increment = 10,
    Rounding = 0,
    Default = 182,
    Callback = function(value)
        AirStrafeSettings.AirStrafeAcceleration = value
        applyAll()
    end,
})

addNumericInput(MainTab, "airAcceleration", {
    Title = "Air Acceleration",
    Min = 1, Max = 20,
    Increment = 0.5,
    Rounding = 1,
    Default = 1,
    Callback = function(value)
        AirStrafeSettings.AirAcceleration = value
        applyAll()
    end,
})

addNumericInput(MainTab, "jumpHeight", {
    Title = "Jump Height",
    Min = 1, Max = 10,
    Increment = 0.1,
    Rounding = 1,
    Default = 3,
    Callback = function(value)
        AirStrafeSettings.JumpHeight = value
        applyAll()
    end,
})

addNumericInput(MainTab, "jumpSpeedMultiplier", {
    Title = "Jump Speed Multiplier",
    Min = 1, Max = 3,
    Increment = 0.1,
    Rounding = 1,
    Default = 1.45,
    Callback = function(value)
        AirStrafeSettings.JumpSpeedMultiplier = value
        applyAll()
    end,
})

addNumericInput(MainTab, "sprintAcceleration", {
    Title = "Sprint Acceleration",
    Min = 1, Max = 10,
    Increment = 0.1,
    Rounding = 1,
    Default = 1,
    Callback = function(value)
        AirStrafeSettings.SprintAcceleration = value
        applyAll()
    end,
})

addNumericInput(MainTab, "runAcceleration", {
    Title = "Run Acceleration",
    Min = 1, Max = 10,
    Increment = 0.1,
    Rounding = 1,
    Default = 1,
    Callback = function(value)
        AirStrafeSettings.RunAccel = value
        applyAll()
    end,
})

addNumericInput(MainTab, "friction", {
    Title = "Friction",
    Min = 0, Max = 5,
    Increment = 0.1,
    Rounding = 1,
    Default = 5,
    Callback = function(value)
        AirStrafeSettings.Friction = value
        applyAll()
    end,
})

-- ===== unlock jump (unrelated feature, kept as-is) =====

local unlockedMT = nil
local originalUpdateCanJump = nil
local originalAttemptJump = nil
local originalJump = nil
local originalJumpReact = nil

local AUTO_JUMP_INTERVAL = 0

local CANJUMP_FALSE_STATES = {
    CarryIdle = true,
    CarryMove = true,
    CarryCrouchIdle = true,
    CarryCrouchMove = true,
    CarrySlide = true,
    CarrySlideAir = true,
    CarryAir = true,
    Downed = true,
    Carried = true,
    Ragdolling = true,
    Climbing = true,
    Swimming = true,
}

local function findMovementMT()
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" then
            if rawget(v, "UpdateCanJump") ~= nil and rawget(v, "Jump") ~= nil and rawget(v, "testMultipleJumps") ~= nil and rawget(v, "JumpReact") ~= nil and rawget(v, "AttemptJump") ~= nil then
                return v
            end
        end
    end
    return nil
end

local function stripCanJumpFromStateInfo()
    local StateInfo = require(ReplicatedStorage.Objects.Game.Character.Shared.StateInfo)
    for _, state in ipairs(StateInfo.States) do
        if state.Movement and rawget(state.Movement, "CanJump") == false then
            rawset(state.Movement, "CanJump", nil)
        end
    end
end

local function patchUnlockJump()
    stripCanJumpFromStateInfo()

    unlockedMT = findMovementMT()
    if not unlockedMT then
        return
    end

    if not originalUpdateCanJump then
        originalUpdateCanJump = rawget(unlockedMT, "UpdateCanJump")
    end
    if not originalAttemptJump then
        originalAttemptJump = rawget(unlockedMT, "AttemptJump")
    end
    if not originalJump then
        originalJump = rawget(unlockedMT, "Jump")
    end
    if not originalJumpReact then
        originalJumpReact = rawget(unlockedMT, "JumpReact")
    end

    rawset(unlockedMT, "UpdateCanJump", function(self)
        if self.Character.Humanoid.Health <= 0 or self.CanJump == false then
            self.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
            return
        end
        self.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
    end)

    rawset(unlockedMT, "AttemptJump", function(self, p2, p3)
        self:EndClimb()
        if self.DataRegistry:Get("Grounded") then
            if self.DataRegistry:Get("Grounded") then
                self.JumpAmount = 0
            end
        elseif self.JumpAmount == 0 then
            self.JumpAmount = 1
        end

        local v2
        if p2 then
            v2 = p2
        else
            v2 = self.MoveStats:GetMoveStats()
        end
        if self.DataRegistry:Get("Grounded") or self.State == "WallrunLeft" or self.State == "WallrunRight" or self.JumpAmount < 1 then
            self:Jump(v2, true)
            return
        end
        if p3 ~= true then
            self:testMultipleJumps(v2)
        end
    end)

    rawset(unlockedMT, "Jump", function(self, p2, p3, p4)
        if not (self.DataRegistry:Get("Carrying") or 0 == 0) or self.MoveStats.MoveStats.Speed == 0 then
            return
        end
        local v1
        if p2 then
            v1 = p2
        else
            v1 = self.MoveStats:GetMoveStats()
        end
        local v2 = self.DataRegistry:Get("Velocity")
        local v3 = self.DataRegistry:Get("Sprint")
        if v2 ~= Vector3.new() and self.DataRegistry:Get("Crouching") ~= true and p3 == true then
            local Speed = v1.Speed
            local v4 = v1.JumpSpeedMultiplier * self.Character.HumanoidRootPart.CFrame.lookVector:Dot(v2.unit) ^ 2
            local magnitude = v2.magnitude
            if magnitude < v3 * Speed * v4 then
                local v5 = math.min(magnitude * v1.JumpSpeedMultiplier, v3 * Speed * v4)
                self.DataRegistry:Set("Velocity", (self.DataRegistry:Get("Velocity") * Vector3.new(1, 0, 1)).unit * v5)
            end
        end
        local JumpHeight = p4
        if not JumpHeight then
            JumpHeight = v1.JumpHeight
        end
        self.Character.Humanoid.JumpHeight = JumpHeight
        self.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        if self.State == "WallrunRight" then
            self.DataRegistry:Set("IgnoreXMove", tick())
            local Y = self.Character.HumanoidRootPart.AssemblyLinearVelocity.Y
            local v7 = self.DataRegistry:Get("Velocity")
            local v8 = self.DataRegistry:Get("WallrunDir")
            if not v8 then
                v8 = Vector3.new()
            end
            self.DataRegistry:Set("Velocity", v7 + v8 * 90 * 30)
            task.spawn(function()
                task.wait()
                self.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(self.Character.HumanoidRootPart.AssemblyLinearVelocity.X, Y * 0.1 + 10, self.Character.HumanoidRootPart.AssemblyLinearVelocity.Z)
            end)
        end
    end)

    -- Автоджамп: держим space -> прыгаем в каждом кадре, где это возможно,
    -- вместо блокировки повтора до отпускания кнопки.
    rawset(unlockedMT, "JumpReact", function(self, p2)
        if self.CanJump == false then
            return
        end

        self.JumpHeldDown = true

        task.spawn(function()
            while self.JumpHeldDown do
                self:UpdateCanJump()
                self:AttemptJump()
                game:GetService("RunService").Heartbeat:Wait()
            end
        end)

        if p2 ~= true then
            while true do
                game:GetService("RunService").Heartbeat:Wait()
                if self.JumpHeldDown == false then
                    break
                end
            end
        end
    end)
end

local function restoreUnlockJump()
    local StateInfo = require(ReplicatedStorage.Objects.Game.Character.Shared.StateInfo)
    for _, state in ipairs(StateInfo.States) do
        if state.Movement and CANJUMP_FALSE_STATES[state.State] then
            rawset(state.Movement, "CanJump", false)
        end
    end

    if unlockedMT then
        if originalUpdateCanJump then
            rawset(unlockedMT, "UpdateCanJump", originalUpdateCanJump)
        end
        if originalAttemptJump then
            rawset(unlockedMT, "AttemptJump", originalAttemptJump)
        end
        if originalJump then
            rawset(unlockedMT, "Jump", originalJump)
        end
        if originalJumpReact then
            rawset(unlockedMT, "JumpReact", originalJumpReact)
        end
        unlockedMT = nil
    end

    originalUpdateCanJump = nil
    originalAttemptJump = nil
    originalJump = nil
    originalJumpReact = nil
end

MainTab:AddToggle("UnlockJumpToggle", {
    Title = "Unlock jump in all states",
    Default = false,
    Callback = function(value)
        if value then
            local lp = game:GetService("Players").LocalPlayer

            patchUnlockJump()

            if _G.UnlockJumpCharConn then
                _G.UnlockJumpCharConn:Disconnect()
            end

_G.UnlockJumpCharConn = lp.CharacterAdded:Connect(function(newChar)
    newChar:WaitForChild("HumanoidRootPart", 10)
    newChar:WaitForChild("Humanoid", 10)
    task.wait(0.5)
    if _G.UnlockJumpEnabled then
        unlockedMT = nil
        originalUpdateCanJump = nil
        originalAttemptJump = nil
        originalJump = nil
        originalJumpReact = nil
        patchUnlockJump()
    end
end)

            _G.UnlockJumpEnabled = true
        else
            _G.UnlockJumpEnabled = false

            if _G.UnlockJumpCharConn then
                _G.UnlockJumpCharConn:Disconnect()
                _G.UnlockJumpCharConn = nil
            end

            restoreUnlockJump()
        end
    end,
})

-- === AUTO JUMP ===
do
    local RunService = game:GetService("RunService")
    local lp = game:GetService("Players").LocalPlayer

    local ajRunning = false
    local ajConn = nil
    local ajButton = nil
    local AutoJumpToggleObject = nil

    local function ajJump()
        local char = lp.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return end

        if not hum.UseJumpPower and hum.JumpHeight < 1 then
            hum.JumpHeight = 7.2
        end
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
        hum.Jump = true
    end

    -- Pula sem parar (cada vez que toca o chao) ate ser desligado.
    local function ajSetRunning(state)
        ajRunning = state and true or false
        if ajConn then
            ajConn:Disconnect()
            ajConn = nil
        end
        if ajRunning then
            ajConn = RunService.Heartbeat:Connect(function()
                local char = lp.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 and hum.FloorMaterial ~= Enum.Material.Air then
                    ajJump()
                end
            end)
        end
        if ajButton then ajButton:SetActive(ajRunning) end
    end

    -- Botao / tecla passam pelo toggle do menu para manter tudo sincronizado.
    local function ajToggleFromUI()
        if AutoJumpToggleObject and type(AutoJumpToggleObject.SetValue) == "function" then
            AutoJumpToggleObject:SetValue(not ajRunning)
        else
            ajSetRunning(not ajRunning)
        end
    end

    ajButton = _G.__HXFloatingButton({
        Name = "AutoJump",
        Label = "Auto Jump",
        Position = UDim2.new(0.5, 0, 0.75, 0),
        OnClick = ajToggleFromUI,
    })

    AutoJumpToggleObject = MainTab:AddToggle("AutoJumpToggle", {
        Title = "Auto Jump",
        Default = false,
        Callback = function(value)
            ajSetRunning(value)
        end,
    })

    MainTab:AddToggle("AutoJumpButtonToggle", {
        Title = "Auto Jump Button",
        Default = false,
        Callback = function(value)
            ajButton:SetEnabled(value)
        end,
    })

    addNumericInput(MainTab, "autoJumpButtonSize", {
        Title = "Auto Jump Button Size (%)",
        Min = 50, Max = 250,
        Increment = 5,
        Rounding = 0,
        Default = 100,
        Callback = function(value)
            ajButton:SetSizePercent(value)
        end,
    })

    MainTab:AddKeybind("AutoJumpKeybind", {
        Title = "Auto Jump Keybind",
        Default = "None",
        CurrentKeybind = "None",
        HoldToInteract = false,
        Callback = function()
            ajToggleFromUI()
        end,
    })
end
end)

do
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local hardStrafeEnabled = false
local characterAddedConnHS = nil
local diedConnHS = nil
local renderConn = nil
local cachedMovement = nil

local HardStrafeConfig = {
    JumpSpeedMultiplier = 1.9,
    Speed = 1500,
    StrafeAcceleration = 600,
    StrafeSpeedCap = 110 * 110,
    StaticSpeedEnabled = false,
    StaticSpeed = 65,
}

local RELEASE_GRACE_PERIOD = 0.15
local MIN_DIR_MAGNITUDE = 0.001

local function isMovementController(obj)
    if typeof(obj) ~= "table" then return false end

    local ok, result = pcall(function()
        return obj.Character ~= nil
            and obj.DataRegistry ~= nil
            and obj.StateInfo ~= nil
            and obj.Constraints ~= nil
            and obj.MoveStats ~= nil
            and obj.MoveFunction ~= nil
            and obj.Update ~= nil
            and obj.SetState ~= nil
    end)

    return ok and result
end

local function scanForMovementController()
    local character = LocalPlayer.Character
    if not character then return nil end

    local objects = getgc(true)
    for i = 1, #objects do
        local obj = objects[i]
        if isMovementController(obj) and obj.Character == character then
            return obj
        end
    end

    return nil
end

local function patchHardStrafeRV(movement)
    if not movement or not movement.MoveStats then return false end

    local ok = pcall(function()
        local stats = movement.MoveStats:GetMoveStats()
        stats.JumpSpeedMultiplier = HardStrafeConfig.JumpSpeedMultiplier
        stats.Speed = HardStrafeConfig.Speed
        stats.BaseSpeed = HardStrafeConfig.Speed
    end)

    if ok and _G.OnHardStrafeEnabled then
        pcall(_G.OnHardStrafeEnabled)
    end

    return ok
end

local function getHeldMoveDirection()
    local x, z = 0, 0

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then z = z - 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then z = z + 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then x = x - 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then x = x + 1 end

    if x == 0 and z == 0 then
        return nil
    end

    local vec = Vector3.new(x, 0, z)
    if vec.Magnitude < MIN_DIR_MAGNITUDE then
        return nil
    end
    return vec.Unit
end

local lastFrameTime = nil
local persistentSpeed = 30 * 90
local lastMoveInputTime = nil

local function resetStrafeAccumulator()
    lastFrameTime = nil
    persistentSpeed = 30 * 90
    lastMoveInputTime = nil
end

-- Same check as before: only push velocity into BaseMover when it's actually
-- the enabled constraint for the character's current state (not Climbing,
-- Carried, Ragdolling, Grappling, Lunge, Disabled, Inert, Still).
local function isBaseMoverActive(movement)
    local constraintsWrapper = movement.Constraints
    if not constraintsWrapper then return false end
    local constraintsTable = constraintsWrapper.Constraints
    if not constraintsTable then return false end
    local baseMover = constraintsTable["BaseMover"]
    if not baseMover then return false end

    local ok, enabled = pcall(function() return baseMover.Enabled end)
    return ok and enabled == true
end

local function applyStrafeVelocity(movement, newVel)
    if newVel.X ~= newVel.X or newVel.Y ~= newVel.Y or newVel.Z ~= newVel.Z then
        return
    end

    movement.Velocity = newVel
    movement.DataRegistry:Set("Velocity", newVel)

    if movement.Constraints and movement.Constraints.Constraints and movement.Constraints.Constraints["BaseMover"] then
        movement.Constraints:UpdateConstraint("BaseMover", {
            PlaneVelocity = Vector2.new(newVel.X, newVel.Z),
        })
    end
end

-- Runs on RenderStepped, AFTER the game's own CharacterService:Update has
-- already run this frame (also on RenderStepped, connected earlier in
-- CharacterService — Roblox fires same-event connections in connect order,
-- so as long as this connects after the game's script already loaded, ours
-- runs second). This reads/writes the same Movement object the game just
-- finished updating, without ever touching Update itself — no hookfunction,
-- no wrapping, so nothing about the game's own call chain changes.
local function onRenderStepped(dt)
    if not hardStrafeEnabled then return end
    if not cachedMovement then return end

    local now = tick()
    local deltaTime = dt or (lastFrameTime and (now - lastFrameTime)) or (1 / 60)
    lastFrameTime = now

    local moveDir = getHeldMoveDirection()

    if moveDir then
        lastMoveInputTime = now

        local camera = workspace.CurrentCamera
        if camera and isBaseMoverActive(cachedMovement) then
            local worldDir = camera.CFrame:VectorToWorldSpace(moveDir)
            worldDir = Vector3.new(worldDir.X, 0, worldDir.Z)

            if worldDir.Magnitude > MIN_DIR_MAGNITUDE then
                worldDir = worldDir.Unit

                local currentVel = cachedMovement.Velocity or Vector3.new()
                local newVel

                if HardStrafeConfig.StaticSpeedEnabled then
                    local staticVel = worldDir * (HardStrafeConfig.StaticSpeed * 90)
                    newVel = Vector3.new(staticVel.X, currentVel.Y, staticVel.Z)
                else
                    persistentSpeed = math.min(persistentSpeed + HardStrafeConfig.StrafeAcceleration * deltaTime, HardStrafeConfig.StrafeSpeedCap)

                    local targetVel = worldDir * persistentSpeed
                    newVel = Vector3.new(targetVel.X, currentVel.Y, targetVel.Z)
                end

                applyStrafeVelocity(cachedMovement, newVel)
            end
        end
    else
        if lastMoveInputTime == nil or (now - lastMoveInputTime) > RELEASE_GRACE_PERIOD then
            persistentSpeed = 30 * 90
        end
    end
end

local function stopRenderLoop()
    if renderConn then
        renderConn:Disconnect()
        renderConn = nil
    end
end

local function startRenderLoop()
    stopRenderLoop()
    renderConn = RunService.RenderStepped:Connect(onRenderStepped)
end

local function setupForCurrentCharacter()
    cachedMovement = scanForMovementController()
    resetStrafeAccumulator()

    if cachedMovement and hardStrafeEnabled then
        patchHardStrafeRV(cachedMovement)
    end
end

local rvRetryThread = nil

local function tryPatchRVWithRetry()
    if rvRetryThread then
        task.cancel(rvRetryThread)
        rvRetryThread = nil
    end

    rvRetryThread = task.spawn(function()
        for i = 1, 10 do
            if not hardStrafeEnabled then break end
            if not cachedMovement then
                cachedMovement = scanForMovementController()
            end
            if cachedMovement and patchHardStrafeRV(cachedMovement) then break end
            task.wait(0.3)
        end
        rvRetryThread = nil
    end)
end

local function stopDiedWatch()
    if diedConnHS then
        diedConnHS:Disconnect()
        diedConnHS = nil
    end
end

local function watchCurrentCharacterDeath()
    stopDiedWatch()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    diedConnHS = hum.Died:Connect(function()
        resetStrafeAccumulator()
        cachedMovement = nil
    end)
end

local function setHardStrafe(state)
    hardStrafeEnabled = state
    _G.HardStrafeActive = state

    if state then
        setupForCurrentCharacter()
        watchCurrentCharacterDeath()
        tryPatchRVWithRetry()
        startRenderLoop()

        if characterAddedConnHS then
            characterAddedConnHS:Disconnect()
        end

        characterAddedConnHS = LocalPlayer.CharacterAdded:Connect(function()
            task.wait(0.4)
            setupForCurrentCharacter()
            watchCurrentCharacterDeath()
            tryPatchRVWithRetry()
        end)
    else
        if characterAddedConnHS then
            characterAddedConnHS:Disconnect()
            characterAddedConnHS = nil
        end

        stopDiedWatch()
        stopRenderLoop()

        if rvRetryThread then
            task.cancel(rvRetryThread)
            rvRetryThread = nil
        end

        resetStrafeAccumulator()
        cachedMovement = nil

        if _G.OnHardStrafeDisabled then
            _G.OnHardStrafeDisabled()
        end
    end
end

MainTab:AddParagraph({ Title = "NCP Movement", Content = "" })

MainTab:AddToggle("NCPMovement", {
    Title = "NCP Speed Movement",
    Default = false,
    Callback = function(value)
        setHardStrafe(value)
    end,
})

addNumericInput(MainTab, "ncpStrafeAcceleration", {
    Title = "NCP Strafe Acceleration",
    Min = 100, Max = 5000,
    Increment = 50,
    Rounding = 0,
    Default = 600,
    Callback = function(value)
        HardStrafeConfig.StrafeAcceleration = value
    end,
})

addNumericInput(MainTab, "ncpSpeedLimit", {
    Title = "NCP Speed Limit",
    Min = 35, Max = 500,
    Increment = 5,
    Rounding = 0,
    Default = 110,
    Callback = function(value)
        HardStrafeConfig.StrafeSpeedCap = value * 90
    end,
})

MainTab:AddToggle("NCPStaticSpeed", {
    Title = "NCP Static Speed",
    Default = false,
    Callback = function(value)
        HardStrafeConfig.StaticSpeedEnabled = value
    end,
})

addNumericInput(MainTab, "ncpStaticSpeed", {
    Title = "NCP Static Speed",
    Min = 40, Max = 130,
    Increment = 5,
    Rounding = 0,
    Default = 65,
    Callback = function(value)
        HardStrafeConfig.StaticSpeed = value
    end,
})
end

local function syncToggle(toggleObject, value)
    if not toggleObject then return end
    if type(toggleObject.SetValue) == "function" then
        toggleObject:SetValue(value)
    elseif type(toggleObject.Set) == "function" then
        -- Compatibility with older Fluent builds.
        toggleObject:Set(value)
    end
end

do -- world_mov
MainTab:AddParagraph({ Title = "World & Movement", Content = "" })
-- wallstick
local EasyBounceToggle = nil
local EasyBounceEnabled = false
local toggleEasyBounce  -- forward declaration
local YLockToggle = nil
local yLockEnabled = false
local invisWallEnabled = false
local setInvisWall  -- forward
local legitBounceEnabled = false
local setLegitBounce  -- forward
local edgeBoostEnabled = false
local setEdgeBoost  -- forward
local emoteFlingEnabled = false
local setEmoteFling  -- forward
local wallLaunchEnabled = false

pcall(function()
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local yLockConnection = nil
yLockEnabled = false
local frozenY = nil

local function enableYLock()
    if yLockConnection then return end

    local character = player.Character
    if not character then return end

    local h = character:FindFirstChild("HumanoidRootPart")
    if not h then return end

    frozenY = h.Position.Y

    yLockConnection = RunService.RenderStepped:Connect(function()
        local char = player.Character
        if not char then return end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local vel = hrp.AssemblyLinearVelocity
        hrp.AssemblyLinearVelocity = Vector3.new(vel.X, 0, vel.Z)
        hrp.CFrame = CFrame.new(hrp.Position.X, frozenY, hrp.Position.Z)
            * CFrame.Angles(0, select(2, hrp.CFrame:ToEulerAnglesYXZ()), 0)
    end)
end

local function disableYLock()
    if yLockConnection then
        yLockConnection:Disconnect()
        yLockConnection = nil
    end
    frozenY = nil
end

local function toggleYLock(state)
    if state then
        enableYLock()
    else
        disableYLock()
    end
end
YLockToggle = MainTab:AddToggle("YLockToggle", {
    Title = "Y Lock Surf",
    Default = false,
    Callback = function(state)
        yLockEnabled = state
        toggleYLock(state)
    end,
})

invisWallEnabled = false
local removedParts = {}
local InvisWallToggleObject = nil

local SKIP_NAMES = {
    ["StairBarriers"] = true,
    ["Stair Barriers"] = true,
    ["Car Barrier"] = true,
    ["Car Barrier Wedge"] = true,
    ["Stair Barriers 2"] = true,
    ["Wedge Corner Barrier"] = true,
    ["Wedge Barrier"] = true,
    ["CobblestoneWhite2"] = true,
    ["CobblestoneWhite1"] = true,
    ["Veh4Barrier"] = true,
    ["TankBarrier"] = true,
    ["FakeStair"] = true,
}

local SKIP_SIZES = {
    Vector3.new(65.36, 9.68, 0.72),
    Vector3.new(0.56, 9.68, 13.12),
    Vector3.new(39.68, 9.68, 0.48),
    Vector3.new(42, 1, 14.5),
    Vector3.new(44, 1, 15.5),
    Vector3.new(43, 1, 16.5),
    Vector3.new(43, 1, 14.5),
    Vector3.new(8, 4, 114.83999633789062),
    Vector3.new(8, 4, 114.83999633789062),
    Vector3.new(7, 4, 114.83999633789062),
    Vector3.new(7, 4, 114.83999633789062),
    Vector3.new(0.39999160170555115, 9.680005073547363, 39.679988861083984),
    Vector3.new(7.359990119934082, 4.160007476806641, 7.519986629486084),
    Vector3.new(14.959990501403809, 10.48000717163086, 20.95998764038086),
    Vector3.new(0.5599914789199829, 9.680005073547363, 13.279986381530762),
    Vector3.new(13.359990119934082, 9.680005073547363, 0.7199859619140625),
    Vector3.new(25.839990615844727, 9.680005073547363, 0.4799865782260895),
    Vector3.new(0.39999160170555115, 9.680005073547363, 12.399986267089844),
    Vector3.new(52.22676467895508, 9.679999351501465, 0.7199859619140625),
    Vector3.new(52.71999740600586, 9.680005073547363, 0.3999877870082855),
    Vector3.new(0.39999085664749146, 9.680005073547363, 78.15998840332031),
    Vector3.new(43.79999542236328, 12.899993896484375, 25.799991607666016),
    Vector3.new(58, 1, 14.5),
    Vector3.new(21.626476287841797, 14, 55.5),
    Vector3.new(20.639999389648438, 0.6400018334388733, 19.600006103515625),
    Vector3.new(16.319997787475586, 0.6400018334388733, 43.52000427246094),
    Vector3.new(64.4800033569336, 0.6400018334388733, 20.480005264282227),
    Vector3.new(42.96000289916992, 0.6400018334388733, 20.480005264282227),
    Vector3.new(8.239999771118164, 0.6400018334388733, 13.120004653930664),
    Vector3.new(13.920000076293945, 0.6400018334388733, 47.200008392333984),
    Vector3.new(29.860002517700195, 2.8800010681152344, 18.220008850097656),
    Vector3.new(34.79999923706055, 0.6400018334388733, 17.600006103515625),
    Vector3.new(14.479998588562012, 0.6400018334388733, 28.640005111694336),
    Vector3.new(16.239999771118164, 0.6400018334388733, 20.160005569458008),
    Vector3.new(22.239999771118164, 0.6400018334388733, 19.84000587463379),
    Vector3.new(22.079999923706055, 0.6400018334388733, 13.12000560760498),
    Vector3.new(12.479999542236328, 0.6400018334388733, 28.080005645751953),
    Vector3.new(9.119999885559082, 13.920001029968262, 36.24000549316406),
    Vector3.new(17.760000228881836, 0.6400018334388733, 14.8800048828125),
    Vector3.new(17.760000228881836, 0.6400018334388733, 13.4400053024292),
    Vector3.new(11.65548038482666, 11.526007652282715, 5.5),
    Vector3.new(8.793645858764648, 9.309903144836426, 6.769292831420898),
    Vector3.new(3.1837501525878906, 1.9161412715911865, 6.769292831420898),
    Vector3.new(14.5600004196167, 7.28000020980835, 9.680000305175781),
    Vector3.new(11.515069007873535, 5.757534503936768, 7.655622482299805),
    Vector3.new(13.360000610351562, 1.600000023841858, 9.760000228881836),
    Vector3.new(13.360000610351562, 1.600000023841858, 9.760000228881836),
    Vector3.new(23.68000030517578, 0.800000011920929, 39.92000198364258),
    Vector3.new(32.005638122558594, 45.72038650512695, 1.9700241088867188),
    Vector3.new(10.260000228881836, 26.729999542236328, 46.2599983215332),
    Vector3.new(454.2156677246094, 132.99752807617188, 154.57232666015625),
    Vector3.new(35.8399772644043, 73.9200210571289, 40.13996505737305),
    Vector3.new(9.947713851928711, 1.2951278686523438, 45.69872283935547),
    Vector3.new(6.516521453857422, 1.2951278686523438, 45.69872283935547),
    Vector3.new(9.841439247131348, 1.2951278686523438, 51.02950668334961),
    Vector3.new(21.5, 10, 2.1000001430511475),
    Vector3.new(6.284273147583008, 6.894408226013184, 6.769292831420898),
    Vector3.new(),
    Vector3.new(),
    Vector3.new(),
    Vector3.new(),
    Vector3.new(),
}

local SKIP_CFRAME_POS = Vector3.new(123.034, -65.697, -221.464)
local SKIP_CFRAME_POS = Vector3.new(264.23999, 108.810059, -390.169922)
local SKIP_CFRAME_POS = Vector3.new(47.28785705566406, 36.30036163330078, 96.56423950195312)
local SKIP_CFRAME_POS = Vector3.new(450.40625, -19.328125, -242.8984375)
local SKIP_CFRAME_POS = Vector3.new(264.239990234375, 108.81005859375, -377.169921875)
local SKIP_CFRAME_ROT = {1, -0, 0, 0, 0.777, 0.63, -0, -0.63, 0.777}
local SKIP_CFRAME_ROT = {0, 0, 1, 0, 1, -0, -1, 0, 0}
local SKIP_CFRAME_ROT = {1, 0, 0, 0, 1, 0, 0, 0, 1}
local CFRAME_EPS = 0.01

local function sizeMatches(a, b)
    return math.abs(a.X - b.X) < 0.01
        and math.abs(a.Y - b.Y) < 0.01
        and math.abs(a.Z - b.Z) < 0.01
end

local function isSkippedSize(part)
    for _, sz in ipairs(SKIP_SIZES) do
        if sizeMatches(part.Size, sz) then
            return true
        end
    end
    return false
end

local function isSkippedCFrame(part)
    local cf = part.CFrame
    local pos = cf.Position
    if math.abs(pos.X - SKIP_CFRAME_POS.X) > CFRAME_EPS
        or math.abs(pos.Y - SKIP_CFRAME_POS.Y) > CFRAME_EPS
        or math.abs(pos.Z - SKIP_CFRAME_POS.Z) > CFRAME_EPS then
        return false
    end

    local _, _, _, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()

    local rot = {r00, r01, r02, r10, r11, r12, r20, r21, r22}
    for i = 1, 9 do
        if math.abs(rot[i] - SKIP_CFRAME_ROT[i]) > CFRAME_EPS then
            return false
        end
    end
    return true
end

local function hasRoverVehicles()
    local ok, vehicles = pcall(function()
        return workspace.Vehicles
    end)
    if not ok or not vehicles then return false end
    for _, child in ipairs(vehicles:GetChildren()) do
        if child:IsA("Model") and child.Name == "Rover" then
            return true
        end
    end
    return false
end

local function shouldSkip(part, allowWedge)
    if not allowWedge then
        if part:IsA("WedgePart") then return true end
        if part:IsA("Part") and part.Shape == Enum.PartType.Wedge then return true end
    end
    if part:IsA("UnionOperation") then return true end
    if SKIP_NAMES[part.Name] then return true end
    if isSkippedSize(part) then return true end
    if isSkippedCFrame(part) then return true end
    return false
end

local function removeInvisWalls()
    removedParts = {}
    local ok, InvisParts = pcall(function()
    return workspace.Map.InvisParts
    end)
    if not ok or not InvisParts then
        Fluent:Notify({ Title = "Invis Wall Remover", Content = "InvisParts not found!", Duration = 3 })
        return
    end

    local allowWedge = hasRoverVehicles()

    local removed = 0
    for _, child in ipairs(InvisParts:GetDescendants()) do
        if not child:IsA("BasePart") then continue end
        if shouldSkip(child, allowWedge) then continue end

        local success = pcall(function()
            table.insert(removedParts, { part = child, parent = child.Parent })
            child.Parent = nil
        end)
        if success then
            removed += 1
        end
    end

    Fluent:Notify({ Title = "Invis Wall Remover", Content = "Removed " .. removed .. " parts", Duration = 3 })
end

local function restoreInvisWalls()
    for _, data in ipairs(removedParts) do
        pcall(function()
            if data.part then
                data.part.Parent = data.parent
            end
        end)
    end
    removedParts = {}
    Fluent:Notify({ Title = "Invis Wall Remover", Content = "Disabled", Duration = 2 })
end

setInvisWall = function(state)
    invisWallEnabled = state
    if state then
        removeInvisWalls()
    else
        restoreInvisWalls()
    end
    task.spawn(function()
        task.wait()
        syncToggle(InvisWallToggleObject, state)
    end)
end

InvisWallToggleObject = MainTab:AddToggle("InvisWallRemover", {
    Title = "Invis Wall Remover",
    Default = false,
    Callback = function(value)
        if value == invisWallEnabled then return end
        setInvisWall(value)
    end,
})
-- legitbounce
legitBounceEnabled = false
local legitBounceForce = 100
local legitBounceMinSpeed = 0
local legitBounceConnection = nil
local LegitToggleObject = nil

local GROUND_DIRS = {Vector3.new(0,-8,0), Vector3.new(-2,-8,0), Vector3.new(2,-8,0)}
local GROUND_DIST = 5
local GROUND_HITS_NEEDED = 2

local cachedRayParams = RaycastParams.new()
cachedRayParams.FilterType = Enum.RaycastFilterType.Exclude

local cachedNoCollideParams = RaycastParams.new()
cachedNoCollideParams.FilterType = Enum.RaycastFilterType.Exclude
cachedNoCollideParams.RespectCanCollide = false

local cachedOverlapParams = OverlapParams.new()
cachedOverlapParams.FilterType = Enum.RaycastFilterType.Exclude
cachedOverlapParams.MaxParts = 10
local lastCharacter = nil

local function updateRayParams(character)
    if character ~= lastCharacter then
        cachedRayParams.FilterDescendantsInstances = {character}
        cachedNoCollideParams.FilterDescendantsInstances = {character}
        cachedOverlapParams.FilterDescendantsInstances = {character}
        lastCharacter = character
    end
end

local function checkOverlapGround(hrp)
    local checkCFrame = CFrame.new(hrp.Position + Vector3.new(0, -2.5, 0))
    local checkSize = Vector3.new(2, 2, 2)
    local parts = workspace:GetPartBoundsInBox(checkCFrame, checkSize, cachedOverlapParams)
    for _, part in ipairs(parts) do
        if part:IsA("BasePart") and part ~= hrp then
            return true
        end
    end
    return false
end

local function isGroundHit(origin, dir)
    local r = workspace:Raycast(origin, dir, cachedRayParams)
    if r and (origin - r.Position).Magnitude <= GROUND_DIST then
        return true
    end
    local r2 = workspace:Raycast(origin, dir, cachedNoCollideParams)
    if r2 and r2.Instance and (origin - r2.Position).Magnitude <= GROUND_DIST then
        return true
    end
    return false
end

local function checkIsOnGround(hrp)
    local hits = 0
    local origin = hrp.Position
    for _, dir in ipairs(GROUND_DIRS) do
        if isGroundHit(origin, dir) then
            hits += 1
            if hits >= GROUND_HITS_NEEDED then return true end
        end
    end
    return checkOverlapGround(hrp)
end

local function startLegitBounce()
    if legitBounceConnection then
        legitBounceConnection:Disconnect()
        legitBounceConnection = nil
    end

    legitBounceConnection = RunService.Heartbeat:Connect(function()
        if not legitBounceEnabled then return end

        local character = player.Character
        if not character then return end

        local hrp = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not hrp or not humanoid or humanoid.Health <= 0 then return end

        if humanoid:GetState() ~= Enum.HumanoidStateType.Landed then return end

        updateRayParams(character)

        if checkIsOnGround(hrp) then
            local vel = hrp.AssemblyLinearVelocity
            local horizSpeed = Vector3.new(vel.X, 0, vel.Z).Magnitude
            if horizSpeed >= legitBounceMinSpeed then
                hrp.AssemblyLinearVelocity = Vector3.new(vel.X, legitBounceForce, vel.Z)
            end
        end
    end)
end

local function stopLegitBounce()
    if legitBounceConnection then
        legitBounceConnection:Disconnect()
        legitBounceConnection = nil
    end
    lastCharacter = nil
end

setLegitBounce = function(state)
    if state == legitBounceEnabled then return end
    legitBounceEnabled = state
    if state then
        startLegitBounce()
    else
        stopLegitBounce()
    end
    task.spawn(function()
        task.wait()
        syncToggle(LegitToggleObject, state)
    end)
end

LegitToggleObject = MainTab:AddToggle("LegitBounce", {
    Title = "Legit Bounce",
    Default = false,
    Callback = function(value)
        setLegitBounce(value)
    end,
})

addNumericInput(MainTab, "legitBouncePower", {
    Title = "Legit Bounce Power",
    Min = 50, Max = 400,
    Increment = 10,
    Rounding = 0,
    Suffix = "",
    Default = legitBounceForce,
    Callback = function(value) legitBounceForce = value end,
})

addNumericInput(MainTab, "legitBounceMinSpeed", {
    Title = "Legit Bounce Min Speed",
    Min = 0, Max = 100,
    Increment = 1,
    Rounding = 0,
    Suffix = "",
    Default = 0,
    Callback = function(value) legitBounceMinSpeed = value end,
})

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local player = Players.LocalPlayer or Players.PlayerAdded:Wait()

    EasyBounceEnabled = false
    local EASY_BOUNCE_STEP = 1 / 55
    local easyBounceSpeedMult = 1.65

    local easyBounceLastTime = tick()
    local easyBounceCharacter = nil
    local easyBounceHrp = nil
    local easyBounceHumanoid = nil

    local easyBounceConn = nil
    local easyBounceCharConn = nil

    local function refreshEasyBounceCharacter(char)
        easyBounceCharacter = char or player.Character
        easyBounceHrp = nil
        easyBounceHumanoid = nil

        if not easyBounceCharacter then return end
        easyBounceHrp = easyBounceCharacter:FindFirstChild("HumanoidRootPart")
        easyBounceHumanoid = easyBounceCharacter:FindFirstChildOfClass("Humanoid")
        easyBounceLastTime = tick()
    end

    local function simulateEasyBounceStep(dt)
        if not EasyBounceEnabled or not easyBounceHrp or not easyBounceHumanoid then return end
        if easyBounceHumanoid:GetState() ~= Enum.HumanoidStateType.Jumping then return end

        local vel = easyBounceHrp.AssemblyLinearVelocity * easyBounceSpeedMult
        easyBounceHrp.CFrame = easyBounceHrp.CFrame + vel * dt
    end

    local function smoothEasyBounce(a, b, t)
        return a + (b - a) * t
    end

    local function startEasyBounce()
        refreshEasyBounceCharacter(player.Character)

        if easyBounceCharConn then
            easyBounceCharConn:Disconnect()
            easyBounceCharConn = nil
        end
        easyBounceCharConn = player.CharacterAdded:Connect(function(char)
            refreshEasyBounceCharacter(char)
        end)

        if easyBounceConn then
            easyBounceConn:Disconnect()
            easyBounceConn = nil
        end

        easyBounceConn = RunService.Stepped:Connect(function()
            if not EasyBounceEnabled then return end

            if not easyBounceHrp or not easyBounceHrp.Parent
                or not easyBounceHumanoid or not easyBounceHumanoid.Parent then
                refreshEasyBounceCharacter(player.Character)
                return
            end

            local now = tick()
            local dt = now - easyBounceLastTime
            easyBounceLastTime = now

            if easyBounceHumanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
                return
            end

            local stepDt = dt
            while stepDt > EASY_BOUNCE_STEP do
                simulateEasyBounceStep(EASY_BOUNCE_STEP)
                stepDt -= EASY_BOUNCE_STEP
            end
            if stepDt > 0 then
                simulateEasyBounceStep(stepDt)
            end

            local targetPos = easyBounceHrp.Position
            local finalPos = smoothEasyBounce(easyBounceHrp.Position, targetPos, 0.5)
            easyBounceHrp.CFrame = CFrame.new(finalPos, finalPos + easyBounceHrp.CFrame.LookVector)
        end)
    end

    local function stopEasyBounce()
        if easyBounceConn then
            easyBounceConn:Disconnect()
            easyBounceConn = nil
        end
        if easyBounceCharConn then
            easyBounceCharConn:Disconnect()
            easyBounceCharConn = nil
        end
        easyBounceCharacter = nil
        easyBounceHrp = nil
        easyBounceHumanoid = nil
    end

    toggleEasyBounce = function(value)
        if value == EasyBounceEnabled then return end
        EasyBounceEnabled = value
        if value then
            startEasyBounce()
        else
            stopEasyBounce()
        end
    end

    ----------------------------------------------------------------
    -- Fluent UI
    ----------------------------------------------------------------
    EasyBounceToggle = MainTab:AddToggle("EasyBounceToggle", {
        Title = "Easy Bounce",
    Default = false,
        Callback = function(value)
            toggleEasyBounce(value)
        end,
    })
local EdgeToggleObject = nil
edgeBoostEnabled = false
local edgeBoostPower = 100
local edgeBoostConnection = nil
local MIN_Y_VELOCITY = 1
local SPAWN_GUARD_TIME = 0.5
local WORKSPACE_RESET_GUARD_TIME = 2.3
local spawnGuardUntil = 0

local function isDownedInEvade(char)
    return char:GetAttribute("Downed") == true or char:GetAttribute("State") == "Downed"
end

local function isBouncePart(part)
    if CollectionService:HasTag(part, "StreetlampExpander") then return false end
    local bounceKeywords = {"bounce", "boost", "launch", "jump", "pad", "ramp", "platform", "bus"}
    local name = string.lower(part.Name)
    for _, keyword in pairs(bounceKeywords) do
        if name:find(keyword) then return true end
    end
    if part.Parent and (part.Parent:IsA("Model") or part.Parent:IsA("Folder")) then
        local parentName = string.lower(part.Parent.Name)
        for _, keyword in pairs(bounceKeywords) do
            if parentName:find(keyword) then return true end
        end
    end
    return false
end

local function applyEdgeBoost()
    if not edgeBoostEnabled then return end
    if os.clock() < spawnGuardUntil then return end

    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    local downed = isDownedInEvade(char)

    local currentYVelocity = hrp.AssemblyLinearVelocity.Y
    if currentYVelocity < -MIN_Y_VELOCITY then
        local touchingParts = hrp:GetTouchingParts()
        if #touchingParts > 0 then
            local isTouchingBounce = false
            for _, part in pairs(touchingParts) do
                if isBouncePart(part) then isTouchingBounce = true break end
            end
            
            if not isTouchingBounce then
                local horizontal = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
                
                if downed then
                    hrp.AssemblyLinearVelocity = horizontal + Vector3.new(0, edgeBoostPower * 0.8, 0)
                else
                    if hum.Health > 0 then
                        hrp.AssemblyLinearVelocity = horizontal + Vector3.new(0, edgeBoostPower, 0)
                    end
                end
            end
        end
    end
end

local function onCharacterAdded(char)
    spawnGuardUntil = os.clock() + SPAWN_GUARD_TIME
end

if player.Character then
    onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

local function getPlayersFolder()
    local ok, playersFolder = pcall(function() return workspace.Game.Players end)
    if ok and playersFolder then return playersFolder end
    return nil
end

local function watchPlayersFolder()
    local playersFolder = getPlayersFolder()
    if not playersFolder then return end

    if _G.EBPlayersConn then
        _G.EBPlayersConn:Disconnect()
        _G.EBPlayersConn = nil
    end

    _G.EBPlayersConn = playersFolder.ChildAdded:Connect(function()
        if not edgeBoostEnabled then return end
        spawnGuardUntil = os.clock() + WORKSPACE_RESET_GUARD_TIME
    end)
end

local function startEdgeBoost()
    if edgeBoostConnection then edgeBoostConnection:Disconnect() edgeBoostConnection = nil end
    edgeBoostConnection = RunService.Stepped:Connect(applyEdgeBoost)
    watchPlayersFolder()

    if not _G.EBLobbyLoop then
        _G.EBLobbyLoop = task.spawn(function()
            while true do
                task.wait(1)
                local playersFolder = getPlayersFolder()
                if playersFolder and #playersFolder:GetChildren() == 0 then
                    if _G.EBPlayersConn then
                        _G.EBPlayersConn:Disconnect()
                        _G.EBPlayersConn = nil
                    end
                    playersFolder.ChildAdded:Wait()
                    if edgeBoostEnabled then
                        spawnGuardUntil = os.clock() + WORKSPACE_RESET_GUARD_TIME
                    end
                    watchPlayersFolder()
                end
            end
        end)
    end
end

local function stopEdgeBoost()
    if edgeBoostConnection then edgeBoostConnection:Disconnect() edgeBoostConnection = nil end
    if _G.EBPlayersConn then _G.EBPlayersConn:Disconnect() _G.EBPlayersConn = nil end
    if _G.EBLobbyLoop then
        task.cancel(_G.EBLobbyLoop)
        _G.EBLobbyLoop = nil
    end
end

setEdgeBoost = function(state)
    edgeBoostEnabled = state
    if state then
        startEdgeBoost()
    else
        stopEdgeBoost()
    end
    task.spawn(function()
        task.wait()
        syncToggle(EdgeToggleObject, state)
    end)
end

EdgeToggleObject = MainTab:AddToggle("EdgeBoost", {
    Title = "Easy Edge Trimp",
    Default = false,
    Callback = function(value)
        if value == edgeBoostEnabled then return end
        setEdgeBoost(value)
    end,
})

addNumericInput(MainTab, "edgeBoostPower", {
    Title = "Edge Boost Power",
    Min = 50, Max = 400,
    Increment = 10,
    Rounding = 0,
    Suffix = "",
    Default = edgeBoostPower,
    Callback = function(value) edgeBoostPower = value end,
})
-- emote fling
emoteFlingEnabled = false
local EmoteFlingToggleObject = nil
local FLING_POWER = 120

local animTrackConns = nil
local animPlayedConn = nil
local emoteModelConn = nil
local activeEmoteNames = {}

local EMOTE_ANIMATION_NAMES = {
    Animation = true,
    AnimationClassic = true,
    AnimationR6 = true,
    Intro = true,
}

local function doFling()
    local char = player.Character
    if not char then return end

    local playerFolder = workspace:FindFirstChild("Players")
    if not playerFolder then return end
    local rig = playerFolder:FindFirstChild(player.Name)
    if not rig then return end

    local hrp = rig:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(hrp.AssemblyLinearVelocity.X, FLING_POWER, hrp.AssemblyLinearVelocity.Z)
    bv.MaxForce = Vector3.new(0, math.huge, 0)
    bv.P = FLING_POWER * 500
    bv.Parent = hrp
    game:GetService("Debris"):AddItem(bv, 0.15)
end

local function cleanupAnimWatch()
    if animTrackConns then
        for _, conn in ipairs(animTrackConns) do
            conn:Disconnect()
        end
        animTrackConns = nil
    end
    if animPlayedConn then
        animPlayedConn:Disconnect()
        animPlayedConn = nil
    end
    activeEmoteNames = {}
end

local function cleanupEmoteModelWatch()
    if emoteModelConn then
        emoteModelConn:Disconnect()
        emoteModelConn = nil
    end
end

local function cleanupEmoteFling()
    cleanupAnimWatch()
    cleanupEmoteModelWatch()
end

local function watchTrack(track)
    if not EMOTE_ANIMATION_NAMES[track.Animation.Name] then return end

    local name = track.Animation.Name
    local conn
    conn = track.Stopped:Connect(function()
        if not emoteFlingEnabled then return end
        activeEmoteNames[name] = nil
        doFling()
    end)

    table.insert(animTrackConns, conn)
    activeEmoteNames[name] = true
end

local function startAnimWatch()
    cleanupAnimWatch()
    animTrackConns = {}

    local char = player.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
        watchTrack(track)
    end

    animPlayedConn = humanoid.AnimationPlayed:Connect(function(track)
        if not emoteFlingEnabled then return end
        watchTrack(track)
    end)
end

local function startEmoteModelWatch()
    cleanupEmoteModelWatch()

    local rigsFolders = {}
    for _, child in ipairs(workspace:GetChildren()) do
        if child.Name == "Rigs" and #child:GetChildren() > 0 then
            table.insert(rigsFolders, child)
        end
    end

    local playerRigsFolder = rigsFolders[1]
    if not playerRigsFolder then return end
    local rig = playerRigsFolder:FindFirstChild(player.Name)
    if not rig then return end

    emoteModelConn = rig.ChildRemoved:Connect(function(child)
        if child.Name ~= "EmoteModel" then return end
        if not emoteFlingEnabled then return end
        doFling()
    end)
end

local function startEmoteFling()
    cleanupEmoteFling()
    startAnimWatch()
    startEmoteModelWatch()
end

setEmoteFling = function(value)
    if value == emoteFlingEnabled then return end
    emoteFlingEnabled = value
    if value then
        startEmoteFling()
        player.CharacterAdded:Connect(function()
            if emoteFlingEnabled then
                task.wait(1)
                startEmoteFling()
            end
        end)
    else
        cleanupEmoteFling()
    end
    syncToggle(EmoteFlingToggleObject, value)
end

EmoteFlingToggleObject = MainTab:AddToggle("EmoteFlingToggle", {
    Title = "Emote Fling",
    Default = false,
    Callback = function(value)
        setEmoteFling(value)
    end,
})

addNumericInput(MainTab, "emoteFlingPower", {
    Title = "Emote Fling Power",
    Min = 50, Max = 400,
    Increment = 10,
    Rounding = 0,
    Suffix = "",
    Default = 120,
    Callback = function(value)
        FLING_POWER = value
    end,
})
wallLaunchEnabled = false
local WallLaunchToggleObject = nil
local wallLaunchConn = nil
local wallLaunchSuppressed = false
local wallLaunchCooldown = false
local wallLaunchPower = 80
local currentWallNormal = nil
local lastWallNormal = nil
local activeProtrusion = nil
local lockedY = nil
local lockedYTimer = 0
local protrusionAttachTime = 0
local wallAttached = false
local wallContactTime = 0
local ATTACH_MIN_TIME = 0.087

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local lp = Players.LocalPlayer

local WALL_DIST = 1.3
local CAST_DIST = 1.3
local PROTRUSION_CAST = 1.5
local PROTRUSION_MIN_THICKNESS = 1.2
local PROTRUSION_MIN_WIDTH = 1.45
local PROTRUSION_MAX_STUCK_TIME = 0.45

local WALL_NORMAL_THRESHOLD_STRICT = 0.4
local WALL_NORMAL_THRESHOLD_ATTACHED = 0.7

local EDGE_CAST = 1.8
local EDGE_MIN_ANGLE_DOT = 0.3
local EDGE_MAX_ANGLE_DOT = 0.85
local EDGE_MIN_DEPTH = 1.2

local function getRayParams(char)
    local filter = { char }
    for _, player in ipairs(Players:GetPlayers()) do
        local c = player.Character
        if c then table.insert(filter, c) end
    end
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj ~= char and obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
            table.insert(filter, obj)
        end
    end
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = filter
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.RespectCanCollide = true
    return rp
end

local function getBodyOffsets()
    return {
        Vector3.new(0, 0, 0),
        Vector3.new(0, 2.2, 0),
        Vector3.new(0, -2.2, 0),
        Vector3.new(0, 1, 0),
        Vector3.new(0, -1, 0),
        Vector3.new(0, 1.6, 0),
        Vector3.new(0, -1.6, 0),
        Vector3.new(0.5, 0, 0),
        Vector3.new(-0.5, 0, 0),
        Vector3.new(0.5, 1.5, 0),
        Vector3.new(-0.5, 1.5, 0),
        Vector3.new(0.5, -1.5, 0),
        Vector3.new(-0.5, -1.5, 0),
        Vector3.new(0.5, 2.2, 0),
        Vector3.new(-0.5, 2.2, 0),
        Vector3.new(0.5, -2.2, 0),
        Vector3.new(-0.5, -2.2, 0),
    }
end

local function getCastDirs()
    return {
        Vector3.new(1, 0, 0),
        Vector3.new(-1, 0, 0),
        Vector3.new(0, 0, 1),
        Vector3.new(0, 0, -1),
        Vector3.new(1, 0, 1).Unit,
        Vector3.new(-1, 0, 1).Unit,
        Vector3.new(1, 0, -1).Unit,
        Vector3.new(-1, 0, -1).Unit,
    }
end

local function getYSweepCasts(hrp, char, normalThreshold)
    local rayParams = getRayParams(char)
    local results = {}
    local sideOffsets = {
        Vector3.new(0.8, 0, 0), Vector3.new(-0.8, 0, 0),
        Vector3.new(0, 0, 0.8), Vector3.new(0, 0, -0.8),
        Vector3.new(0.6, 0, 0.6), Vector3.new(-0.6, 0, 0.6),
        Vector3.new(0.6, 0, -0.6), Vector3.new(-0.6, 0, -0.6),
    }
    local yLevels = { 0, 1, -1, 2, -2, 2.2, -2.2 }
    local sideDirs = {
        Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0),
        Vector3.new(0, 0, 1), Vector3.new(0, 0, -1),
        Vector3.new(1, 0, 1).Unit, Vector3.new(-1, 0, 1).Unit,
        Vector3.new(1, 0, -1).Unit, Vector3.new(-1, 0, -1).Unit,
    }
    for _, yOff in ipairs(yLevels) do
        for _, sideOff in ipairs(sideOffsets) do
            local origin = hrp.Position + Vector3.new(sideOff.X, yOff, sideOff.Z)
            for _, dir in ipairs(sideDirs) do
                local result = workspace:Raycast(origin, dir * CAST_DIST, rayParams)
                if result and math.abs(result.Normal.Y) < normalThreshold then
                    table.insert(results, result)
                end
            end
        end
    end
    return results
end

local function findWall(hrp, char, normalThreshold)
    local rayParams = getRayParams(char)
    local normalAccum = Vector3.zero
    local hitCount = 0
    local bestHitPos = nil
    local bestDist = math.huge

    for _, offset in ipairs(getBodyOffsets()) do
        local origin = hrp.Position + offset
        for _, dir in ipairs(getCastDirs()) do
            local result = workspace:Raycast(origin, dir * CAST_DIST, rayParams)
            if result and math.abs(result.Normal.Y) < normalThreshold then
                normalAccum = normalAccum + result.Normal
                hitCount = hitCount + 1
                local dist = (result.Position - hrp.Position).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    bestHitPos = result.Position
                end
            end
        end
    end

    local sweepResults = getYSweepCasts(hrp, char, normalThreshold)
    for _, result in ipairs(sweepResults) do
        normalAccum = normalAccum + result.Normal
        hitCount = hitCount + 1
        local dist = (result.Position - hrp.Position).Magnitude
        if dist < bestDist then
            bestDist = dist
            bestHitPos = result.Position
        end
    end

    if hitCount == 0 then
        if lastWallNormal then
            local result = workspace:Raycast(hrp.Position, -lastWallNormal * (CAST_DIST + 1), getRayParams(char))
            if result and math.abs(result.Normal.Y) < normalThreshold then
                return result.Normal, result.Position
            end
        end
        return nil, nil
    end

    local avgNormal = normalAccum / hitCount
    if avgNormal.Magnitude < 0.01 then return nil, nil end
    return avgNormal.Unit, bestHitPos
end

local function measureProtrusionThickness(rayParams, hitPos, hitInstance, along)
    local probeStart = hitPos + along * 0.05
    local backResult = workspace:Raycast(probeStart, along * PROTRUSION_CAST, rayParams)
    if not backResult or backResult.Instance ~= hitInstance then return 0 end
    return (backResult.Position - hitPos).Magnitude
end

local function measureProtrusionWidth(rayParams, hitPos, hitInstance, wallNormal)
    local sideVec = Vector3.new(-wallNormal.Z, 0, wallNormal.X).Unit
    local leftPos, rightPos
    local leftResult = workspace:Raycast(hitPos + sideVec * 0.05, sideVec * 4, rayParams)
    if leftResult and leftResult.Instance == hitInstance then
        leftPos = leftResult.Position
    end
    local rightResult = workspace:Raycast(hitPos - sideVec * 0.05, -sideVec * 4, rayParams)
    if rightResult and rightResult.Instance == hitInstance then
        rightPos = rightResult.Position
    end
    if not leftPos or not rightPos then return 0 end
    return (leftPos - rightPos).Magnitude
end

local function findProtrusion(hrp, char, along, wallNormal)
    local rayParams = getRayParams(char)
    local castOffsets = {
        Vector3.new(0, 0, 0), Vector3.new(0, 1.5, 0), Vector3.new(0, -1.5, 0),
        Vector3.new(0, 2.2, 0), Vector3.new(0, -2.2, 0),
    }
    for _, offset in ipairs(castOffsets) do
        local origin = hrp.Position + offset
        local result = workspace:Raycast(origin, along * PROTRUSION_CAST, rayParams)
        if result then
            local dot = math.abs(result.Normal:Dot(wallNormal))
            if dot > 0.7 then
                local thickness = measureProtrusionThickness(rayParams, result.Position, result.Instance, along)
                if thickness >= PROTRUSION_MIN_THICKNESS then
                    local width = measureProtrusionWidth(rayParams, result.Position, result.Instance, wallNormal)
                    if width >= PROTRUSION_MIN_WIDTH then
                        return result.Normal, result.Instance, result.Position
                    end
                end
            end
        end
    end
    return nil, nil, nil
end

local function protrusionEnded(hrp, char, protrusionInst, along)
    local rayParams = getRayParams(char)
    local checkDirs = {
        along * 1.5 + Vector3.new(0, -1, 0),
        along * 1.0 + Vector3.new(0, -2, 0),
    }
    for _, dir in ipairs(checkDirs) do
        local result = workspace:Raycast(hrp.Position, dir, rayParams)
        if result and result.Instance == protrusionInst then return false end
    end
    return true
end

local function measureSurfaceDepth(rayParams, hitPos, hitInstance, normal)
    local probeStart = hitPos - normal * 0.05
    local backResult = workspace:Raycast(probeStart, -normal * EDGE_CAST, rayParams)
    if not backResult then return EDGE_CAST end
    if backResult.Instance ~= hitInstance then return (backResult.Position - hitPos).Magnitude end
    return 0
end

local function findEdge(hrp, char, along, wallNormal)
    local rayParams = getRayParams(char)
    local sideVec = Vector3.new(-along.Z, 0, along.X)
    local probeOffsets = {
        Vector3.new(0, 0, 0), Vector3.new(0, 1.5, 0), Vector3.new(0, -1.5, 0),
        Vector3.new(0, 2.2, 0), Vector3.new(0, -2.2, 0),
    }
    local probeSides = { sideVec, -sideVec }
    for _, side in ipairs(probeSides) do
        for _, offset in ipairs(probeOffsets) do
            local origin = hrp.Position + offset + side * 0.9
            local result = workspace:Raycast(origin, along * EDGE_CAST, rayParams)
            if result then
                local dot = math.abs(result.Normal:Dot(wallNormal))
                if dot >= EDGE_MIN_ANGLE_DOT and dot <= EDGE_MAX_ANGLE_DOT then
                    local depth = measureSurfaceDepth(rayParams, result.Position, result.Instance, result.Normal)
                    if depth >= EDGE_MIN_DEPTH then
                        return result.Normal, result.Instance, result.Position
                    end
                end
            end
        end
    end
    return nil, nil, nil
end

local function getEdgeSurfaceY(hrp, char)
    local rayParams = getRayParams(char)
    local result = workspace:Raycast(hrp.Position, Vector3.new(0, -4, 0), rayParams)
    if result then
        return result.Position.Y + 3.0
    end
    return nil
end

local function resetWallState()
    currentWallNormal = nil
    lastWallNormal = nil
    activeProtrusion = nil
    lockedY = nil
    protrusionAttachTime = 0
    wallAttached = false
    wallContactTime = 0
end

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode ~= Enum.KeyCode.Space then return end
    if not wallLaunchEnabled then return end
    if not currentWallNormal then return end
    if not wallAttached then return end
    if wallLaunchCooldown then return end

    local char = lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    wallLaunchCooldown = true
    local savedNormal = currentWallNormal
    resetWallState()

    wallLaunchSuppressed = true
    task.delay(1, function() wallLaunchSuppressed = false end)
    task.delay(0.6, function() wallLaunchCooldown = false end)

    local launchDir = (Vector3.new(0, 1, 0) + savedNormal * 0.4).Unit
    hrp.AssemblyLinearVelocity = launchDir * wallLaunchPower
end)

WallLaunchToggleObject = MainTab:AddToggle("WallLaunch", {
    Title = "Wall Launch",
    Default = false,
    Callback = function(value)
        wallLaunchEnabled = value

        if not value then
            wallLaunchSuppressed = false
            resetWallState()
            if wallLaunchConn then
                wallLaunchConn:Disconnect()
                wallLaunchConn = nil
            end
            return
        end

        wallLaunchConn = RunService.Heartbeat:Connect(function(dt)
            if not wallLaunchEnabled then return end

            local char = lp.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum then return end

            if wallLaunchSuppressed then
                currentWallNormal = nil
                lockedY = nil
                wallAttached = false
                wallContactTime = 0
                return
            end

            if hum.FloorMaterial ~= Enum.Material.Air then
                resetWallState()
                return
            end

            local normalThreshold = currentWallNormal and WALL_NORMAL_THRESHOLD_ATTACHED or WALL_NORMAL_THRESHOLD_STRICT
            local wallNormal, wallHitPos = findWall(hrp, char, normalThreshold)

            if not wallNormal then
                currentWallNormal = nil
                lockedY = nil
                wallAttached = false
                wallContactTime = 0
                return
            end

            if currentWallNormal then
                wallNormal = (currentWallNormal + wallNormal * 4).Unit
            end

            currentWallNormal = wallNormal
            lastWallNormal = wallNormal

            wallContactTime = wallContactTime + dt
            if wallContactTime >= ATTACH_MIN_TIME then
                wallAttached = true
            end

            local cam = workspace.CurrentCamera
            local look = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
            if look.Magnitude < 0.01 then return end
            look = look.Unit

            local along = look - wallNormal * look:Dot(wallNormal)
            if along.Magnitude < 0.05 then return end
            along = along.Unit

            local yVel = 0
            local effectiveNormal = wallNormal
            local effectiveHitPos = wallHitPos

            if activeProtrusion then
                protrusionAttachTime = protrusionAttachTime + dt

                if protrusionAttachTime >= PROTRUSION_MAX_STUCK_TIME then
                    activeProtrusion = nil
                    lockedY = nil
                    protrusionAttachTime = 0
                    yVel = -8
                elseif protrusionEnded(hrp, char, activeProtrusion, along) then
                    activeProtrusion = nil
                    lockedY = nil
                    protrusionAttachTime = 0
                    yVel = -15
                else
                    local pResult = workspace:Raycast(hrp.Position, -wallNormal * (CAST_DIST + 1), getRayParams(char))
                    if pResult and pResult.Instance == activeProtrusion then
                        effectiveNormal = pResult.Normal
                        effectiveHitPos = pResult.Position
                    end

                    local surfY = getEdgeSurfaceY(hrp, char)
                    if surfY then
                        if not lockedY then
                            lockedY = surfY
                            lockedYTimer = 0
                        else
                            lockedYTimer = lockedYTimer + dt
                            local diff = lockedY - hrp.Position.Y
                            yVel = diff * 12
                            yVel = math.clamp(yVel, -20, 20)
                        end
                    end
                end
            else
                local protNormal, protInst, protPos = findProtrusion(hrp, char, along, wallNormal)
                if protInst then
                    activeProtrusion = protInst
                    protrusionAttachTime = 0
                    effectiveNormal = protNormal
                    effectiveHitPos = protPos
                else
                    local edgeNormal, edgeInst, edgePos = findEdge(hrp, char, along, wallNormal)
                    if edgeInst then
                        activeProtrusion = edgeInst
                        protrusionAttachTime = 0
                        effectiveNormal = edgeNormal
                        effectiveHitPos = edgePos
                    end
                end
                lockedY = nil
            end

            local finalAlong = look - effectiveNormal * look:Dot(effectiveNormal)
            if finalAlong.Magnitude > 0.05 then
                along = finalAlong.Unit
            end

            local wallPoint = Vector3.new(effectiveHitPos.X, hrp.Position.Y, effectiveHitPos.Z)
            local toWall = wallPoint - hrp.Position
            local pushX = effectiveNormal.X * -WALL_DIST + toWall.X
            local pushZ = effectiveNormal.Z * -WALL_DIST + toWall.Z

            local targetVelX = along.X * wallLaunchPower + pushX * 18
            local targetVelZ = along.Z * wallLaunchPower + pushZ * 18

            for _, fOff in ipairs({
                Vector3.new(0, 0, 0),
                Vector3.new(0, 1.0, 0),
                Vector3.new(0, -1.0, 0),
                Vector3.new(0, 2.0, 0),
            }) do
                local fResult = workspace:Raycast(hrp.Position + fOff, along * 1.4, getRayParams(char))
                if fResult then
                    local fDot = fResult.Normal:Dot(effectiveNormal)
                    local fVertical = math.abs(fResult.Normal.Y)
                    if fDot < 0.5 and fVertical < 0.6 then
                        local obstDist = (fResult.Position - (hrp.Position + fOff)).Magnitude
                        local pushStrength = (1.4 - obstDist) / 1.4 * 30
                        targetVelX = targetVelX + fResult.Normal.X * pushStrength
                        targetVelZ = targetVelZ + fResult.Normal.Z * pushStrength
                        break
                    end
                end
            end

            local current = hrp.AssemblyLinearVelocity
            local lerpT = math.min(14 * dt, 1)

            hrp.AssemblyLinearVelocity = Vector3.new(
                current.X + (targetVelX - current.X) * lerpT,
                yVel ~= 0 and yVel or 0,
                current.Z + (targetVelZ - current.Z) * lerpT
            )
        end)
    end,
})

addNumericInput(MainTab, "wallLaunchPower", {
    Title = "Wall Launch Power",
    Min =  20, Max = 200 ,
    Increment = 5,
    Rounding = 0,
    Default = 80,
    Callback = function(value)
        wallLaunchPower = value
    end,
})

MainTab:AddParagraph({ Title = "Keybinds", Content = "" })

MainTab:AddKeybind("YLockSurfKeybind", {
    Title = "Y Lock Surf Keybind",
    Default = "None",
    CurrentKeybind = "None",
    HoldToInteract = false,
    Callback = function()
        syncToggle(YLockToggle, not yLockEnabled)
    end,
})

MainTab:AddKeybind("InvisWallKeybind", {
    Title = "Invis Wall Remover Keybind",
    Default = "None",
    CurrentKeybind = "None",
    HoldToInteract = false,
    Callback = function()
        setInvisWall(not invisWallEnabled)
    end,
})

MainTab:AddKeybind("LegitBounceKeybind", {
    Title = "Legit Bounce Keybind",
    Default = "None",
    CurrentKeybind = "None",
    HoldToInteract = false,
    Callback = function() setLegitBounce(not legitBounceEnabled) end,
})

    MainTab:AddKeybind("EasyBounceKeybind", {
        Title = "Easy Bounce Keybind",
        Default = "None",
        CurrentKeybind = "None",
        HoldToInteract = false,
        Callback = function()
            local newState = not EasyBounceEnabled
            -- синхронизируем тоггл Fluent, если метод есть
            if EasyBounceToggle and EasyBounceToggle.SetValue then
                syncToggle(EasyBounceToggle, newState)
            else
                toggleEasyBounce(newState)
            end
        end,
    })

MainTab:AddKeybind("EdgeTrimpKeybind", {
    Title = "Easy Edge Trimp Keybind",
    Default = "None",
    CurrentKeybind = "None",
    HoldToInteract = false,
    Callback = function() setEdgeBoost(not edgeBoostEnabled) end,
})

MainTab:AddKeybind("EmoteFlingKeybind", {
    Title = "Emote Fling Keybind",
    Default = "None",
    CurrentKeybind = "None",
    HoldToInteract = false,
    Callback = function()
        setEmoteFling(not emoteFlingEnabled)
    end,
})

MainTab:AddKeybind("WallLaunchKeybind", {
    Title = "Wall Launch Keybind",
    Default = "None",
    CurrentKeybind = "None",
    HoldToInteract = false,
    Callback = function()
        syncToggle(WallLaunchToggleObject, not wallLaunchEnabled)
    end,
})
end)

end -- /do world_mov
do -- char_adv
MainTab:AddParagraph({ Title = "Character Advanced", Content = "" })
pcall(function()

local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local camera = workspace.CurrentCamera

do 
local smoothMovementEnabled = false
local currentLeftKey = nil
local currentRightKey = nil
local connection = nil

local function pressKey(keyCode)
    VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
end

local function releaseKey(keyCode)
    VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
end

local function cleanupKeys()
    if currentLeftKey then releaseKey(currentLeftKey); currentLeftKey = nil end
    if currentRightKey then releaseKey(currentRightKey); currentRightKey = nil end
end

local function isGuiFocused()
    if UIS:GetFocusedTextBox() then return true end
    return false
end

local SmoothMovementToggleObject
SmoothMovementToggleObject = MainTab:AddToggle("SmoothMovementToggle", {
    Title = "Smart Turnbinds",
    Default = false,
    Callback = function(Value)
        smoothMovementEnabled = Value

        if Value then
            local isBackward = false
            local smoothedVelocity = Vector3.new()
            
            connection = RunService.Heartbeat:Connect(function(deltaTime)
                if isGuiFocused() then
                    cleanupKeys()
                    return
                end

                local character = Players.LocalPlayer.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                
                if hrp then
                    local rawVelocity = hrp.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
                    smoothedVelocity = smoothedVelocity:Lerp(rawVelocity, math.clamp(deltaTime * 15, 0, 1))
                    
                    if smoothedVelocity.Magnitude > 10 then
                        local dot = camera.CFrame.LookVector:Dot(smoothedVelocity.Unit)
                        if dot < -0.15 then
                            isBackward = true
                        elseif dot > 0.15 then
                            isBackward = false
                        end
                    end
                end

                local targetLeftKey = isBackward and Enum.KeyCode.Right or Enum.KeyCode.Left
                local targetRightKey = isBackward and Enum.KeyCode.Left or Enum.KeyCode.Right

                if UIS:IsKeyDown(Enum.KeyCode.A) then
                    if currentLeftKey ~= targetLeftKey then
                        if currentLeftKey then releaseKey(currentLeftKey) end
                        currentLeftKey = targetLeftKey
                        pressKey(currentLeftKey)
                    end
                else
                    if currentLeftKey then releaseKey(currentLeftKey); currentLeftKey = nil end
                end

                if UIS:IsKeyDown(Enum.KeyCode.D) then
                    if currentRightKey ~= targetRightKey then
                        if currentRightKey then releaseKey(currentRightKey) end
                        currentRightKey = targetRightKey
                        pressKey(currentRightKey)
                    end
                else
                    if currentRightKey then releaseKey(currentRightKey); currentRightKey = nil end
                end
            end)
        else
            if connection then
                connection:Disconnect()
                connection = nil
            end
            cleanupKeys()
        end
    end,
})

MainTab:AddKeybind("TurnbindKeybind", {
    Title = "Turnbind Keybind",
    Default = "None",
    CurrentKeybind = "None",
    HoldToInteract = false,
    Callback = function()
        syncToggle(SmoothMovementToggleObject, not smoothMovementEnabled)
    end,
})
end

local lagswitchEnabled = false
local lagswitchFlagValue = 1000
local lagswitchButton = nil
local lagswitchFlagOn = true
local freezeOnCooldown = false
local freezeCooldownSeconds = 1

local function applyLagswitchFlag()
    local value = (lagswitchEnabled and lagswitchFlagOn) and lagswitchFlagValue or 1
    pcall(setfflag, "MaxMissedWorldStepsRemembered", tostring(value))
end

task.spawn(function()
    while task.wait(5) do
        if lagswitchEnabled and lagswitchFlagOn then
            local want = tostring(lagswitchFlagValue)
            if not getfflag or getfflag("MaxMissedWorldStepsRemembered") ~= want then
                pcall(setfflag, "MaxMissedWorldStepsRemembered", want)
            end
        end
    end
end)

-- Freeze: trava o cliente por um instante e entra em cooldown.
local function freezeNow()
    if not lagswitchEnabled or freezeOnCooldown then return end
    freezeOnCooldown = true
    if lagswitchButton then lagswitchButton:SetActive(true) end

    local t = os.clock()
    while os.clock() - t < 0.3 do
        for _ = 1, 500000 do end
    end

    task.spawn(function()
        for i = math.floor(freezeCooldownSeconds), 1, -1 do
            if lagswitchButton then
                lagswitchButton:SetStatusText("Cooldown: " .. i)
            end
            task.wait(1)
        end
        if lagswitchButton then
            lagswitchButton:SetStatusText(nil)
            lagswitchButton:SetActive(false)
        end
        freezeOnCooldown = false
    end)
end

lagswitchButton = _G.__HXFloatingButton({
    Name = "LagSwitch",
    Label = "Freeze Now",
    StatusOff = "Ready",
    StatusOn = "Freezing...",
    Position = UDim2.new(0.75, 0, 0.2, 0),
    OnClick = freezeNow,
    Gear = {
        Title = "FFlag",
        Get = function() return lagswitchFlagOn end,
        Set = function(value)
            lagswitchFlagOn = value and true or false
            applyLagswitchFlag()
        end,
    },
})

LagswitchFFLAGToggleObject = MainTab:AddToggle("LagswitchFFLAGToggle", {
    Title = "FFlag for Lagswitch",
    Default = false,
    Callback = function(value)
        lagswitchEnabled = value and true or false
        applyLagswitchFlag()
        -- Ativar o lagswitch mostra o botao Freeze Now.
        if lagswitchButton then lagswitchButton:SetEnabled(lagswitchEnabled) end
    end,
})

addNumericInput(MainTab, "lagswitchFFlagValue", {
    Title = "Lagswitch FFlag Value (0-1000)",
    Min = 0, Max = 1000,
    Increment = 10,
    Rounding = 0,
    Default = 1000,
    Callback = function(value)
        lagswitchFlagValue = value
        if lagswitchEnabled then
            applyLagswitchFlag()
        end
    end,
})

addNumericInput(MainTab, "freezeCooldown", {
    Title = "Freeze Cooldown (s)",
    Min = 0, Max = 30,
    Increment = 1,
    Rounding = 0,
    Default = 1,
    Callback = function(value)
        freezeCooldownSeconds = value
    end,
})

addNumericInput(MainTab, "freezeButtonSize", {
    Title = "Freeze Button Size (%)",
    Min = 50, Max = 250,
    Increment = 5,
    Rounding = 0,
    Default = 100,
    Callback = function(value)
        lagswitchButton:SetSizePercent(value)
    end,
})

MainTab:AddKeybind("FreezeKeybind", {
    Title = "Freeze Keybind",
    Default = "None",
    CurrentKeybind = "None",
    HoldToInteract = false,
    Callback = function()
        freezeNow()
    end,
})

-- === AUTO CROUCH ===
local autoCrouchEnabled = false
local crouchBtnObj = nil

local function getCrouchBtn()
    local lp = game.Players.LocalPlayer
    local hud = lp.PlayerGui:FindFirstChild("Game") and lp.PlayerGui.Game:FindFirstChild("HUD")
    if hud and hud:FindFirstChild("Mobile") and hud.Mobile:FindFirstChild("Right") then
        return hud.Mobile.Right.Mobile:FindFirstChild("CrouchButton")
    end
    return nil
end

local function triggerCrouchBtn(btn)
    if not btn then return end
    pcall(function()
        for _, connection in ipairs(getconnections(btn.MouseButton1Click)) do
            connection:Fire()
        end
    end)
    pcall(function()
        for _, connection in ipairs(getconnections(btn.Activated)) do
            connection:Fire()
        end
    end)
end

task.spawn(function()
    while true do
        if autoCrouchEnabled then
            local crouchBtn = getCrouchBtn()
            if crouchBtn and crouchBtn.Visible then
                triggerCrouchBtn(crouchBtn)
            end
            task.wait(0.04)
        else
            task.wait(0.2)
        end
    end
end)

local function setAutoCrouch(state)
    state = state and true or false
    autoCrouchEnabled = state
    if crouchBtnObj then crouchBtnObj:SetActive(state) end
end

local function autoCrouchToggleFromUI()
    if AutoCrouchToggleObject and type(AutoCrouchToggleObject.SetValue) == "function" then
        AutoCrouchToggleObject:SetValue(not autoCrouchEnabled)
    else
        setAutoCrouch(not autoCrouchEnabled)
    end
end

crouchBtnObj = _G.__HXFloatingButton({
    Name = "AutoCrouch",
    Label = "Auto Crouch",
    Position = UDim2.new(1, -90, 0.5, 0),
    OnClick = autoCrouchToggleFromUI,
})

AutoCrouchToggleObject = MainTab:AddToggle("AutoCrouchToggle", {
    Title = "Auto Crouch",
    Default = false,
    Callback = function(value)
        setAutoCrouch(value)
    end,
})

MainTab:AddToggle("AutoCrouchButtonToggle", {
    Title = "Auto Crouch Button",
    Default = false,
    Callback = function(value)
        crouchBtnObj:SetEnabled(value)
    end,
})

addNumericInput(MainTab, "autoCrouchButtonSize", {
    Title = "Auto Crouch Button Size (%)",
    Min = 50, Max = 250,
    Increment = 5,
    Rounding = 0,
    Default = 100,
    Callback = function(value)
        crouchBtnObj:SetSizePercent(value)
    end,
})

MainTab:AddKeybind("AutoCrouchKeybind", {
    Title = "Auto Crouch Keybind",
    Default = "None",
    CurrentKeybind = "None",
    HoldToInteract = false,
    Callback = function()
        autoCrouchToggleFromUI()
    end,
})
-- === END AUTO CROUCH ===
-- === LEGIT AUTO BOUNCE (scanner de rampas) ===
do
    local WorkspaceService = game:GetService("Workspace")
    local bounceRun = game:GetService("RunService")

    local bounceEnabled = false
    local bouncePower = 150
    local lastBounce = 0
    local bounceConn = nil
    local scanId = 0
    local slopeParts = {}   -- [part] = true
    local savedColors = {}  -- [part] = cor original
    local LegitBounceToggleObject = nil

    -- Normais possiveis da superficie (Terrain usa raycast ao redor do jogador).
    local function getNormals(part)
        if part:IsA("Terrain") then
            local found = {}
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local pos = hrp.Position
                for x = -10, 10, 5 do
                    for z = -10, 10, 5 do
                        local hit = WorkspaceService:Raycast(pos + Vector3.new(x, 50, z), Vector3.new(0, -100, 0))
                        if hit and hit.Instance == part then
                            table.insert(found, hit.Normal)
                        end
                    end
                end
            end
            if #found > 0 then return found end
            return { Vector3.new(0, 1, 0) }
        end

        local normals = {}
        for _, dir in ipairs({
            Vector3.new(0, 1, 0), Vector3.new(0, -1, 0),
            Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0),
            Vector3.new(0, 0, 1), Vector3.new(0, 0, -1),
        }) do
            table.insert(normals, part.CFrame:VectorToWorldSpace(dir))
        end
        return normals
    end

    -- Rampa = inclinacao entre 10 e 85 graus.
    local function isSlope(normal)
        local angle = math.deg(math.acos(math.clamp(normal:Dot(Vector3.new(0, 1, 0)), -1, 1)))
        return angle >= 10 and angle <= 85
    end

    local function clearHighlights()
        for part, color in pairs(savedColors) do
            if part and part.Parent then
                pcall(function() part.Color = color end)
            end
        end
        slopeParts = {}
        savedColors = {}
    end

    -- Escaneia o mapa, pinta as rampas de vermelho e devolve quantas achou.
    local function scanSlopes()
        scanId += 1
        local myScan = scanId
        clearHighlights()

        local count = 0
        local checked = 0
        for _, obj in ipairs(WorkspaceService:GetDescendants()) do
            if myScan ~= scanId or not bounceEnabled then break end

            if obj:IsA("BasePart") and (obj:IsA("Terrain") or obj.CanCollide) then
                local size = obj:IsA("Terrain") and 100 or (obj.Size.X + obj.Size.Y + obj.Size.Z)
                if size >= 1 and size <= 1000 then
                    for _, normal in ipairs(getNormals(obj)) do
                        if isSlope(normal) then
                            local okColor, original = pcall(function() return obj.Color end)
                            if okColor then
                                savedColors[obj] = original
                                pcall(function() obj.Color = Color3.fromRGB(255, 0, 0) end)
                            end
                            slopeParts[obj] = true
                            count += 1
                            break
                        end
                    end
                end
            end

            checked += 1
            if checked % 400 == 0 then
                task.wait()   -- nao trava o jogo em mapas grandes
            end
        end

        if myScan ~= scanId or not bounceEnabled then
            clearHighlights()
            return 0
        end

        Fluent:Notify({
            Title = "Legit Auto Bounce",
            Content = "Scanned " .. count .. " bounceable slopes!",
            Duration = 3,
        })
        return count
    end

    -- Quica ao cair em cima de uma superficie.
    local function bounceStep()
        if not bounceEnabled then return end
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local vel = hrp.AssemblyLinearVelocity
        if vel.Y > -10 then return end

        local now = tick()
        if now - lastBounce < 0.3 then return end

        local grounded = false
        for _, part in ipairs(hrp:GetTouchingParts()) do
            if part.CanCollide
            and (hrp.Position - part.Position).Magnitude <= 10
            and part.Position.Y <= hrp.Position.Y + 2 then
                grounded = true
                break
            end
        end
        if not grounded then return end

        hrp.AssemblyLinearVelocity = Vector3.new(vel.X * 0.3, math.abs(bouncePower), vel.Z * 0.3)
        lastBounce = now

        pcall(function()
            local snd = Instance.new("Sound")
            snd.Name = "BounceSound"
            snd.SoundId = "rbxassetid://9114488953"
            snd.Volume = 0.5
            snd.Parent = hrp
            snd:Play()
            task.delay(0.5, function() snd:Destroy() end)
        end)
    end

    local function setLegitBounce(state)
        state = state and true or false
        if state == bounceEnabled then return end
        bounceEnabled = state

        if bounceConn then
            bounceConn:Disconnect()
            bounceConn = nil
        end

        if state then
            bounceConn = bounceRun.Heartbeat:Connect(bounceStep)
            task.spawn(scanSlopes)
        else
            scanId += 1
            clearHighlights()
        end
    end

    LegitBounceToggleObject = MainTab:AddToggle("LegitAutoBounceToggle", {
        Title = "Legit Auto Bounce",
        Default = false,
        Callback = function(value)
            setLegitBounce(value)
        end,
    })

    addNumericInput(MainTab, "legitBouncePower", {
        Title = "Legit Bounce Power",
        Min = 50, Max = 500,
        Increment = 10,
        Rounding = 0,
        Default = 150,
        Callback = function(value)
            bouncePower = value
        end,
    })

    MainTab:AddButton({
        Title = "Rescan Slopes",
        Callback = function()
            if bounceEnabled then
                task.spawn(scanSlopes)
            end
        end,
    })

    MainTab:AddKeybind("LegitAutoBounceKeybind", {
        Title = "Legit Auto Bounce Keybind",
        Default = "None",
        CurrentKeybind = "None",
        HoldToInteract = false,
        Callback = function()
            if LegitBounceToggleObject and type(LegitBounceToggleObject.SetValue) == "function" then
                LegitBounceToggleObject:SetValue(not bounceEnabled)
            else
                setLegitBounce(not bounceEnabled)
            end
        end,
    })
end
-- === END LEGIT AUTO BOUNCE ===

-- === INFINITE SLIDE === (codigo original por HzShawde)
do
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local slideEnabled = false
    local slideButton = nil
    local InfiniteSlideToggleObject = nil

    local slideFriction = -8
    local defaultFriction = 5
    local lastFriction = nil

    local fireSignalFunc = firesignal or function(signal, ...)
        if signal and typeof(signal) == "RBXScriptSignal" then
            for _, connection in ipairs(getconnections(signal)) do
                connection:Fire(...)
            end
        end
    end

    -- Hook no Movement.Update do jogo (em segundo plano, nao trava o carregamento).
    task.spawn(function()
        local ok, err = pcall(function()
            local CharacterService = require(
                ReplicatedStorage:WaitForChild("Services", 10)
                    :WaitForChild("Asset", 10)
                    :WaitForChild("CharacterService", 10)
            )
            local Movement = require(ReplicatedStorage.Objects.Game.Character.Client.Movement)

            local function getCharacterTag(character)
                if not character then return nil end
                local charData = CharacterService:GetCharacterFromPlayer(player)
                if charData and charData.Tag then
                    return charData.Tag
                end
                return character.Name
            end

            local function setFriction(value)
                local tag = getCharacterTag(player.Character)
                if not tag then return end
                pcall(function()
                    fireSignalFunc(ReplicatedStorage.Events.CharacterTask.OnClientEvent,
                        tag, "ModifyMovement", { "Friction", value })
                end)
            end

            -- Guarda o Update original para nao empilhar hooks se rodar de novo.
            local original = Movement.__HXOrigUpdate or Movement.Update
            Movement.__HXOrigUpdate = original

            Movement.Update = function(self, ...)
                original(self, ...)

                local data = CharacterService:GetCharacterFromPlayer(player)
                local movementData = data and data.Movement
                local state = movementData and movementData.State or self.State
                local isSlide = (state == "Slide" or state == "EmotingSlide" or state == "CarrySlide")

                if slideEnabled and isSlide then
                    if lastFriction ~= slideFriction then
                        setFriction(slideFriction)
                        lastFriction = slideFriction
                    end
                elseif lastFriction ~= nil then
                    setFriction(defaultFriction)
                    lastFriction = nil
                end
            end
        end)

        if not ok then
            warn("[Hyperion] Infinite Slide setup failed: " .. tostring(err))
        end
    end)

    local function setInfiniteSlide(state)
        slideEnabled = state and true or false
        if slideButton then slideButton:SetActive(slideEnabled) end
    end

    local function infiniteSlideToggleFromUI()
        if InfiniteSlideToggleObject and type(InfiniteSlideToggleObject.SetValue) == "function" then
            InfiniteSlideToggleObject:SetValue(not slideEnabled)
        else
            setInfiniteSlide(not slideEnabled)
        end
    end

    slideButton = _G.__HXFloatingButton({
        Name = "InfiniteSlide",
        Label = "Infinite Slide",
        Position = UDim2.new(0.25, 0, 0.75, 0),
        OnClick = infiniteSlideToggleFromUI,
    })

    InfiniteSlideToggleObject = MainTab:AddToggle("InfiniteSlideToggle", {
        Title = "Infinite Slide",
        Default = false,
        Callback = function(value)
            setInfiniteSlide(value)
        end,
    })

    MainTab:AddToggle("InfiniteSlideButtonToggle", {
        Title = "Infinite Slide Button",
        Default = false,
        Callback = function(value)
            slideButton:SetEnabled(value)
        end,
    })

    addNumericInput(MainTab, "infiniteSlideButtonSize", {
        Title = "Infinite Slide Button Size (%)",
        Min = 50, Max = 250,
        Increment = 5,
        Rounding = 0,
        Default = 100,
        Callback = function(value)
            slideButton:SetSizePercent(value)
        end,
    })

    MainTab:AddKeybind("InfiniteSlideKeybind", {
        Title = "Infinite Slide Keybind",
        Default = "None",
        CurrentKeybind = "None",
        HoldToInteract = false,
        Callback = function()
            infiniteSlideToggleFromUI()
        end,
    })
end
-- === END INFINITE SLIDE ===

-- === EMOTE MACRO (aba Macro) - Evade Overhaul ===
do
    local RS = game:GetService("ReplicatedStorage")

    local selectedEmote = "BoldMarch"
    local crouchMode = "Crouch"
    local emoteMacroButton, uncrouchButton, emoteDropdown

    -- Sistema do Volta Spark X: cada emote tem um ID (atributo "ID" do modulo)
    -- e o disparo e CharacterTask:FireServer("Emote", ID).
    local emoteIds = {}   -- [nome] = id (ou false se nao tiver)

    local function collectEmotes()
        emoteIds = {}
        local names = {}

        local items = RS:FindFirstChild("Items")
        if items then
            for _, folder in ipairs(items:GetDescendants()) do
                if folder.Name == "Emotes" and (folder:IsA("Folder") or folder:IsA("Configuration")) then
                    for _, child in ipairs(folder:GetChildren()) do
                        if (child:IsA("ModuleScript") or child:IsA("LocalScript"))
                        and emoteIds[child.Name] == nil then
                            emoteIds[child.Name] = child:GetAttribute("ID") or false
                            table.insert(names, child.Name)
                        end
                    end
                end
            end
        end

        table.sort(names)
        if #names == 0 then
            names = { "BoldMarch" }
        end
        return names
    end

    local emoteNames = collectEmotes()
    if not table.find(emoteNames, selectedEmote) then
        selectedEmote = emoteNames[1]
    end

    local function fireEmote()
        local id = emoteIds[selectedEmote]
        local fired = false

        if id then
            fired = pcall(function()
                RS.Events.CharacterTask:FireServer("Emote", id)
            end)
        end

        -- Sem ID: tenta o remote antigo que recebe o nome.
        if not fired then
            fired = pcall(function()
                RS.Events.Character.Emote:FireServer(selectedEmote)
            end)
        end
        return fired
    end

    -- Crouch / uncrouch pelo mesmo evento de tecla que o jogo usa.
    local function useCrouchKey(down)
        pcall(function()
            player.PlayerScripts.Events.temporary_events.UseKeybind:Fire({
                Key = "Crouch",
                Down = down,
            })
        end)
    end

    local function flash(btn)
        if not btn then return end
        btn:SetActive(true)
        task.delay(0.15, function() btn:SetActive(false) end)
    end

    -- Estado do emote. Ordem de confianca:
    -- 1) DataRegistry "Emote" do Movement do jogo (0/nil = sem emote)
    -- 2) atributo State do personagem
    -- 3) o ultimo estado que o proprio macro iniciou
    local macroEmoting = false
    local emoteRun = 0
    local movementCache = nil

    local function findMovement()
        if movementCache and rawget(movementCache, "DataRegistry") ~= nil then
            return movementCache
        end
        movementCache = nil
        local ok, gc = pcall(getgc, true)
        if not ok or type(gc) ~= "table" then return nil end
        for _, v in ipairs(gc) do
            if type(v) == "table"
            and rawget(v, "MoveStats")
            and rawget(v, "MoveFunction")
            and rawget(v, "Constraints")
            and rawget(v, "JumpAmount") then
                movementCache = v
                return v
            end
        end
        return nil
    end

    -- true / false se der para saber pelo jogo; nil se nao der.
    local function emoteFromGame()
        local movement = findMovement()
        local dr = movement and rawget(movement, "DataRegistry")
        if dr then
            local ok, value = pcall(function() return dr:Get("Emote") end)
            if ok then
                return value ~= nil and value ~= 0 and value ~= false
            end
        end

        local char = player.Character
        local state = char and char:GetAttribute("State")
        if type(state) == "string" then
            return state:sub(1, 7) == "Emoting"
        end
        return nil
    end

    local function isEmoting()
        local fromGame = emoteFromGame()
        if fromGame ~= nil then
            return fromGame
        end
        return macroEmoting
    end

    local function resetEmoteButton()
        macroEmoting = false
        emoteRun += 1
        if emoteMacroButton then
            emoteMacroButton:SetActive(false)
            emoteMacroButton:SetStatusText(selectedEmote)
        end
    end

    -- Cancela o emote tentando varios metodos, um por vez, ate o jogo dizer
    -- que o personagem parou de emotar.
    local function cancelEmote()
        resetEmoteButton()

        task.spawn(function()
            local attempts = {
                function() RS.Events.CharacterTask:FireServer("CancelEmote") end,
                function() RS.Events.Character.Emote:FireServer() end,
                function() RS.Events.CharacterTask:FireServer("Emote", 0) end,
                function()
                    -- Reenvia o mesmo emote (o jogo alterna).
                    local id = emoteIds[selectedEmote]
                    if id then
                        RS.Events.CharacterTask:FireServer("Emote", id)
                    else
                        RS.Events.Character.Emote:FireServer(selectedEmote)
                    end
                end,
            }

            for i, attempt in ipairs(attempts) do
                pcall(attempt)
                task.wait(0.25)

                local state = emoteFromGame()
                if state == false then
                    break               -- parou de emotar
                end
                if state == nil and i >= 2 then
                    break               -- sem como confirmar: nao arrisca alternar
                end
            end
        end)
    end

    -- Emote + crouch. Clicar de novo enquanto esta emotando cancela o emote.
    local function emoteMacro()
        if isEmoting() then
            cancelEmote()
            return
        end

        fireEmote()
        -- Volta: o crouch vem logo depois do emote, sem espera.
        if crouchMode == "Crouch" then
            useCrouchKey(true)
        end

        macroEmoting = true
        emoteRun += 1
        local myRun = emoteRun
        emoteMacroButton:SetActive(true)
        emoteMacroButton:SetStatusText("Cancel")

        -- Volta ao normal sozinho quando o jogo diz que o emote acabou.
        task.spawn(function()
            task.wait(0.8)
            local waited = 0
            while myRun == emoteRun and waited < 180 do
                if emoteFromGame() == false then
                    resetEmoteButton()
                    return
                end
                task.wait(0.25)
                waited += 0.25
            end
        end)
    end

    local function uncrouch()
        flash(uncrouchButton)
        useCrouchKey(false)
        task.delay(0.1, function()
            useCrouchKey(false)
        end)
    end

    emoteMacroButton = _G.__HXFloatingButton({
        Name = "EmoteMacro",
        Label = "Emote Macro",
        StatusOff = selectedEmote,
        StatusOn = selectedEmote,
        Position = UDim2.new(0.12, 0, 0.55, 0),
        OnClick = emoteMacro,
    })
    emoteMacroButton:SetStatusText(selectedEmote)

    uncrouchButton = _G.__HXFloatingButton({
        Name = "Uncrouch",
        Label = "Uncrouch",
        StatusOff = "Tap",
        StatusOn = "Tap",
        Position = UDim2.new(0.12, 0, 0.67, 0),
        OnClick = uncrouch,
    })

    emoteDropdown = MacroTab:AddDropdown("SelectEmoteName", {
        Title = "Select Emote",
        Values = emoteNames,
        Multi = false,
        Search = true,
        Default = table.find(emoteNames, selectedEmote) or 1,
        Callback = function(value)
            if type(value) == "string" and value ~= "" then
                selectedEmote = value
                emoteMacroButton:SetStatusText(value)
            end
        end,
    })

    MacroTab:AddButton({
        Title = "Refresh Emote List",
        Callback = function()
            emoteNames = collectEmotes()
            pcall(function()
                emoteDropdown:SetValues(emoteNames)
            end)
            Fluent:Notify({
                Title = "Emote Macro",
                Content = "Found " .. #emoteNames .. " emotes",
                Duration = 2,
            })
        end,
    })

    MacroTab:AddDropdown("EmoteMacroCrouchMode", {
        Title = "Crouch Setting",
        Values = { "Crouch", "Don't Crouch" },
        Multi = false,
        Default = "Crouch",
        Callback = function(value)
            crouchMode = value
        end,
    })

    -- Emote Macro
    MacroTab:AddToggle("EmoteMacroButtonToggle", {
        Title = "Emote Macro Button",
        Default = false,
        Callback = function(value)
            emoteMacroButton:SetEnabled(value)
        end,
    })

    addNumericInput(MacroTab, "emoteMacroButtonSize", {
        Title = "Emote Macro Button Size (%)",
        Min = 50, Max = 250,
        Increment = 5,
        Rounding = 0,
        Default = 100,
        Callback = function(value)
            emoteMacroButton:SetSizePercent(value)
        end,
    })

    MacroTab:AddKeybind("EmoteMacroKeybind", {
        Title = "Emote Macro Keybind",
        Default = "None",
        CurrentKeybind = "None",
        HoldToInteract = false,
        Callback = function()
            emoteMacro()
        end,
    })

    -- Uncrouch
    MacroTab:AddToggle("UncrouchButtonToggle", {
        Title = "Uncrouch Button",
        Default = false,
        Callback = function(value)
            uncrouchButton:SetEnabled(value)
        end,
    })

    addNumericInput(MacroTab, "uncrouchButtonSize", {
        Title = "Uncrouch Button Size (%)",
        Min = 50, Max = 250,
        Increment = 5,
        Rounding = 0,
        Default = 100,
        Callback = function(value)
            uncrouchButton:SetSizePercent(value)
        end,
    })

    MacroTab:AddKeybind("UncrouchKeybind", {
        Title = "Uncrouch Keybind",
        Default = "None",
        CurrentKeybind = "None",
        HoldToInteract = false,
        Callback = function()
            uncrouch()
        end,
    })
end
-- === END EMOTE MACRO ===

-- === OPTIMIZATION (FPS boost + FPS counter) ===
do
    local Players_ = game:GetService("Players")
    local Lighting_ = game:GetService("Lighting")
    local RunService_ = game:GetService("RunService")
    local Stats_ = game:GetService("Stats")
    local Workspace_ = game:GetService("Workspace")

    local function newStore()
        return setmetatable({}, { __mode = "k" })
    end

    ------------------------------------------------------------------
    -- Boosts por instancia (guardam o valor original para restaurar)
    ------------------------------------------------------------------
    local function rootsWorkspace() return { Workspace_ } end
    local function rootsFx() return { Lighting_, Workspace_.CurrentCamera } end

    local INSTANCE_FEATURES = {
        {
            id = "Particles", title = "Disable Particles & Effects",
            desc = "Particles, trails, beams, fire, smoke and sparkles.",
            roots = rootsWorkspace,
            rules = {
                { "ParticleEmitter", { Enabled = false } },
                { "Trail", { Enabled = false } },
                { "Beam", { Enabled = false } },
                { "Fire", { Enabled = false } },
                { "Smoke", { Enabled = false } },
                { "Sparkles", { Enabled = false } },
            },
        },
        {
            id = "Lights", title = "Disable Dynamic Lights",
            desc = "Point, spot and surface lights.",
            roots = rootsWorkspace,
            rules = {
                { "PointLight", { Enabled = false } },
                { "SpotLight", { Enabled = false } },
                { "SurfaceLight", { Enabled = false } },
            },
        },
        {
            id = "Textures", title = "Hide Textures & Decals",
            desc = "Makes decals/textures invisible (faces are kept).",
            roots = rootsWorkspace, skipCharacters = true,
            rules = {
                { "Decal", { Transparency = 1 } },
                { "Texture", { Transparency = 1 } },
            },
        },
        {
            id = "Materials", title = "Smooth Materials",
            desc = "SmoothPlastic and no reflectance on every part.",
            roots = rootsWorkspace, skipCharacters = true,
            rules = {
                { "BasePart", { Material = Enum.Material.SmoothPlastic, Reflectance = 0 } },
            },
        },
        {
            id = "CastShadow", title = "Disable Part Shadows",
            desc = "Parts stop casting shadows.",
            roots = rootsWorkspace,
            rules = {
                { "BasePart", { CastShadow = false } },
            },
        },
        {
            id = "MeshFidelity", title = "Low Mesh Fidelity",
            desc = "Meshes render with the Performance fidelity.",
            roots = rootsWorkspace,
            rules = {
                { "MeshPart", { RenderFidelity = Enum.RenderFidelity.Performance } },
            },
        },
        {
            id = "PostFX", title = "Remove Post Effects",
            desc = "Bloom, blur, color correction, depth of field, sun rays, atmosphere and clouds.",
            roots = rootsFx,
            rules = {
                { "PostEffect", { Enabled = false } },
                { "Atmosphere", { Density = 0, Haze = 0 } },
                { "Clouds", { Enabled = false } },
            },
        },
    }

    local function isCharacterPart(inst)
        local model = inst:FindFirstAncestorOfClass("Model")
        while model do
            if model:FindFirstChildOfClass("Humanoid") then
                return true
            end
            model = model:FindFirstAncestorOfClass("Model")
        end
        return false
    end

    for _, feature in ipairs(INSTANCE_FEATURES) do
        feature.saved = newStore()
        feature.token = 0
        feature.conns = {}
        feature.enabled = false
    end

    local function applyToInstance(feature, inst)
        for _, rule in ipairs(feature.rules) do
            if inst:IsA(rule[1]) then
                if inst:IsA("Terrain") then return end
                if feature.skipCharacters and isCharacterPart(inst) then return end

                for prop, value in pairs(rule[2]) do
                    local okRead, original = pcall(function() return inst[prop] end)
                    if okRead and original ~= value then
                        local saved = feature.saved[inst]
                        if not saved then
                            saved = {}
                            feature.saved[inst] = saved
                        end
                        if saved[prop] == nil then
                            saved[prop] = original
                        end
                        pcall(function() inst[prop] = value end)
                    end
                end
                return
            end
        end
    end

    local function enableFeature(feature)
        feature.enabled = true
        feature.token += 1
        local myToken = feature.token

        for _, root in ipairs(feature.roots()) do
            if root then
                table.insert(feature.conns, root.DescendantAdded:Connect(function(inst)
                    if feature.enabled and feature.token == myToken then
                        task.defer(applyToInstance, feature, inst)
                    end
                end))

                task.spawn(function()
                    local descendants = root:GetDescendants()
                    for i, inst in ipairs(descendants) do
                        if feature.token ~= myToken or not feature.enabled then return end
                        applyToInstance(feature, inst)
                        if i % 400 == 0 then
                            RunService_.Heartbeat:Wait()
                        end
                    end
                end)
            end
        end
    end

    local function disableFeature(feature)
        feature.enabled = false
        feature.token += 1

        for _, conn in ipairs(feature.conns) do
            conn:Disconnect()
        end
        feature.conns = {}

        local count = 0
        task.spawn(function()
            for inst, props in pairs(feature.saved) do
                if inst and inst.Parent then
                    for prop, value in pairs(props) do
                        pcall(function() inst[prop] = value end)
                    end
                end
                feature.saved[inst] = nil
                count += 1
                if count % 400 == 0 then
                    RunService_.Heartbeat:Wait()
                end
            end
        end)
    end

    ------------------------------------------------------------------
    -- Boosts de configuracao (qualidade, sombras, mesh, agua)
    ------------------------------------------------------------------
    local SETTING_FEATURES = {
        {
            id = "LowQuality", title = "Lowest Graphics Quality",
            desc = "Sets the render quality level to 1.",
            store = {},
            apply = function(store)
                local r = settings().Rendering
                store.value = r.QualityLevel
                r.QualityLevel = Enum.QualityLevel.Level01
            end,
            restore = function(store)
                if store.value ~= nil then settings().Rendering.QualityLevel = store.value end
            end,
        },
        {
            id = "NoShadows", title = "Disable Global Shadows",
            desc = "Turns off all shadow rendering.",
            store = {},
            apply = function(store)
                store.value = Lighting_.GlobalShadows
                Lighting_.GlobalShadows = false
            end,
            restore = function(store)
                if store.value ~= nil then Lighting_.GlobalShadows = store.value end
            end,
        },
        {
            id = "MeshDetail", title = "Lowest Mesh Detail Level",
            desc = "Uses the lowest mesh LOD level.",
            store = {},
            apply = function(store)
                local r = settings().Rendering
                store.value = r.MeshPartDetailLevel
                r.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
            end,
            restore = function(store)
                if store.value ~= nil then settings().Rendering.MeshPartDetailLevel = store.value end
            end,
        },
        {
            id = "SimpleWater", title = "Simplify Water & Grass",
            desc = "No waves or reflections on water, and no terrain grass.",
            store = {},
            apply = function(store)
                local terrain = Workspace_:FindFirstChildOfClass("Terrain")
                if not terrain then return end
                store.props = {
                    WaterWaveSize = terrain.WaterWaveSize,
                    WaterWaveSpeed = terrain.WaterWaveSpeed,
                    WaterReflectance = terrain.WaterReflectance,
                }
                terrain.WaterWaveSize = 0
                terrain.WaterWaveSpeed = 0
                terrain.WaterReflectance = 0

                if sethiddenproperty and gethiddenproperty then
                    local ok, deco = pcall(gethiddenproperty, terrain, "Decoration")
                    if ok then
                        store.decoration = deco
                        pcall(sethiddenproperty, terrain, "Decoration", false)
                    end
                end
            end,
            restore = function(store)
                local terrain = Workspace_:FindFirstChildOfClass("Terrain")
                if not terrain then return end
                if store.props then
                    for prop, value in pairs(store.props) do
                        pcall(function() terrain[prop] = value end)
                    end
                end
                if store.decoration ~= nil and sethiddenproperty then
                    pcall(sethiddenproperty, terrain, "Decoration", store.decoration)
                end
            end,
        },
    }

    ------------------------------------------------------------------
    -- UI
    ------------------------------------------------------------------
    OptimizationTab:AddParagraph({
        Title = "FPS Boost",
        Content = "Every option can be turned off to restore the original look.",
    })

    local boostToggles = {}

    for _, feature in ipairs(INSTANCE_FEATURES) do
        boostToggles[#boostToggles + 1] = OptimizationTab:AddToggle("Opt_" .. feature.id, {
            Title = feature.title,
            Description = feature.desc,
            Default = false,
            Callback = function(value)
                if value and not feature.enabled then
                    enableFeature(feature)
                elseif not value and feature.enabled then
                    disableFeature(feature)
                end
            end,
        })
    end

    for _, feature in ipairs(SETTING_FEATURES) do
        feature.enabled = false
        boostToggles[#boostToggles + 1] = OptimizationTab:AddToggle("Opt_" .. feature.id, {
            Title = feature.title,
            Description = feature.desc,
            Default = false,
            Callback = function(value)
                if value and not feature.enabled then
                    feature.enabled = true
                    feature.store = {}
                    pcall(feature.apply, feature.store)
                elseif not value and feature.enabled then
                    feature.enabled = false
                    pcall(feature.restore, feature.store)
                end
            end,
        })
    end

    OptimizationTab:AddButton({
        Title = "Enable All Boosts",
        Description = "Turns on every FPS boost above.",
        Callback = function()
            for _, toggle in ipairs(boostToggles) do
                pcall(function() toggle:SetValue(true) end)
            end
        end,
    })

    OptimizationTab:AddButton({
        Title = "Restore Everything",
        Description = "Turns every FPS boost off and restores the original values.",
        Callback = function()
            for _, toggle in ipairs(boostToggles) do
                pcall(function() toggle:SetValue(false) end)
            end
        end,
    })

    OptimizationTab:AddButton({
        Title = "Clean Memory",
        Description = "Runs the garbage collector.",
        Callback = function()
            local before = collectgarbage("count")
            collectgarbage("collect")
            local after = collectgarbage("count")
            Fluent:Notify({
                Title = "Clean Memory",
                Content = string.format("Freed %.1f MB (now %.1f MB)", math.max(before - after, 0) / 1024, after / 1024),
                Duration = 3,
            })
        end,
    })

    ------------------------------------------------------------------
    -- FPS cap
    ------------------------------------------------------------------
    local originalCap = nil
    pcall(function()
        if getfpscap then originalCap = getfpscap() end
    end)
    local capValue = 144
    local capEnabled = false

    local function applyCap()
        if not setfpscap then return end
        if capEnabled then
            pcall(setfpscap, capValue)
        else
            pcall(setfpscap, originalCap or 60)
        end
    end

    OptimizationTab:AddToggle("Opt_FpsCap", {
        Title = "Custom FPS Cap",
        Description = "Needs an executor with setfpscap. Use 0 for unlimited.",
        Default = false,
        Callback = function(value)
            capEnabled = value and true or false
            applyCap()
        end,
    })

    addNumericInput(OptimizationTab, "optFpsCapValue", {
        Title = "FPS Cap Value",
        Min = 0, Max = 1000,
        Increment = 10,
        Rounding = 0,
        Default = 144,
        Callback = function(value)
            capValue = value
            if capEnabled then applyCap() end
        end,
    })

    ------------------------------------------------------------------
    -- FPS counter moderno (mesmo botao dos outros: arrasta, trava, esconde)
    ------------------------------------------------------------------
    local showPing = true
    local showFrameTime = true
    local counterConn = nil

    local fpsCounter = _G.__HXFloatingButton({
        Name = "FpsCounter",
        Label = "-- FPS",
        Width = 150,
        Position = UDim2.new(0.5, 0, 0, 36),
    })
    fpsCounter:SetActive(true)
    fpsCounter:SetStatusText("measuring...")

    local function fpsColor(fps)
        if fps >= 60 then
            return Color3.fromRGB(120, 255, 150)
        elseif fps >= 30 then
            return Color3.fromRGB(255, 220, 90)
        end
        return Color3.fromRGB(255, 95, 95)
    end

    local function readPing()
        local ok, value = pcall(function()
            return Stats_.Network.ServerStatsItem["Data Ping"]:GetValue()
        end)
        if ok and type(value) == "number" then
            return math.floor(value + 0.5)
        end
        return nil
    end

    local function startCounter()
        if counterConn then return end
        local acc, frames = 0, 0
        counterConn = RunService_.RenderStepped:Connect(function(dt)
            acc += dt
            frames += 1
            if acc < 0.5 then return end

            local fps = math.floor(frames / acc + 0.5)
            local frameMs = acc / frames * 1000
            acc, frames = 0, 0

            fpsCounter:SetTitleText(fps .. " FPS")
            fpsCounter:SetTitleColor(fpsColor(fps))

            local parts = {}
            if showFrameTime then
                table.insert(parts, string.format("%.1f ms", frameMs))
            end
            if showPing then
                local ping = readPing()
                if ping then table.insert(parts, ping .. " ping") end
            end
            fpsCounter:SetStatusText(table.concat(parts, "  •  "))
        end)
    end

    local function stopCounter()
        if counterConn then
            counterConn:Disconnect()
            counterConn = nil
        end
    end

    OptimizationTab:AddParagraph({ Title = "FPS Counter", Content = "" })

    OptimizationTab:AddToggle("Opt_FpsCounter", {
        Title = "FPS Counter",
        Description = "Hold 2s to lock/unlock, hold 3s to hide/show. Drag to move.",
        Default = false,
        Callback = function(value)
            fpsCounter:SetEnabled(value)
            if value then startCounter() else stopCounter() end
        end,
    })

    OptimizationTab:AddToggle("Opt_FpsShowFrameTime", {
        Title = "Show Frame Time",
        Default = true,
        Callback = function(value) showFrameTime = value and true or false end,
    })

    OptimizationTab:AddToggle("Opt_FpsShowPing", {
        Title = "Show Ping",
        Default = true,
        Callback = function(value) showPing = value and true or false end,
    })

    addNumericInput(OptimizationTab, "optFpsCounterSize", {
        Title = "FPS Counter Size (%)",
        Min = 50, Max = 250,
        Increment = 5,
        Rounding = 0,
        Default = 100,
        Callback = function(value)
            fpsCounter:SetSizePercent(value)
        end,
    })
end
-- === END OPTIMIZATION ===
local SPECIAL_ROUND_NAMES = {
    "Slasher",
    "No Jumping",
    "Moon Jump",
    "Lurking",
    "Reversed Controls",
    "Upside Down",
    "Damnation",
    "Fog",
    "Darkness",
    "Slow",
}
 
local originalSpecialData = {}
local specialBlockApplied = false
 
local function getSpecialRoundsFolder()
    return ReplicatedStorage.Info.SpecialRounds
end
 
local function patchSpecialRounds()
    local folder = getSpecialRoundsFolder()
    originalSpecialData = {}
 
    for _, name in ipairs(SPECIAL_ROUND_NAMES) do
        local moduleScript = folder:FindFirstChild(name)
        if moduleScript then
            local ok, data = pcall(require, moduleScript)
            if ok and type(data) == "table" then
                originalSpecialData[name] = {
                    Shared = data.Shared,
                    ClientFunction = data.Client and data.Client.Function or nil,
                }
 
                rawset(data, "Shared", {})
 
                if type(data.Client) == "table" then
                    rawset(data.Client, "Function", function() end)
                end
            end
        end
    end
end
 
local function restoreSpecialRounds()
    local folder = getSpecialRoundsFolder()
 
    for _, name in ipairs(SPECIAL_ROUND_NAMES) do
        local moduleScript = folder:FindFirstChild(name)
        local saved = originalSpecialData[name]
        if moduleScript and saved then
            local ok, data = pcall(require, moduleScript)
            if ok and type(data) == "table" then
                rawset(data, "Shared", saved.Shared)
                if type(data.Client) == "table" and saved.ClientFunction then
                    rawset(data.Client, "Function", saved.ClientFunction)
                end
            end
        end
    end
 
    originalSpecialData = {}
end
 
MainTab:AddToggle("BlockSpecialRound", {
    Title = "Special rounds effects blocker",
    Default = false,
    Callback = function(value)
        if value then
            if not specialBlockApplied then
                patchSpecialRounds()
                specialBlockApplied = true
            end
        else
            if specialBlockApplied then
                restoreSpecialRounds()
                specialBlockApplied = false
            end
        end
    end,
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Event = ReplicatedStorage.Events.SetPlayerMode
local LocalPlayer = Players.LocalPlayer

-- how long we keep re-applying the saved CFrame after a revive before giving
-- the character back to normal physics/input
local RESTORE_TIMEOUT = 5
-- how long we wait for the game to hand us the new HumanoidRootPart
local NEW_HRP_TIMEOUT = 3
-- the position counts as "stuck" (restore done) once the HRP stays within this
-- many studs of the target for RESTORE_SETTLE_FRAMES frames in a row
local RESTORE_SETTLE_DISTANCE = 1
local RESTORE_SETTLE_FRAMES = 3
-- The ONLY case in which we deliberately don't restore: we were lying down
-- longer than this and then came up. That is a round reset, not a teammate
-- reviving us. Set to math.huge to always restore, no matter what.
local MAX_DOWNED_TIME = 120
-- how long the position handed over by unhookAll() stays valid. Only has to
-- survive CharacterAdded -> hookDowned, which is near-instant.
local HANDOFF_TIMEOUT = 5

local AutoReviveEnabled = false
local pollConn = nil
local freezeConn = nil
local characterObj = nil
local wasDowned = false
local frozenPart = nil
local frozenPartOriginalAnchored = false
local freezeToken = 0

-- CFrame of the HumanoidRootPart sampled on the last frame we were up, plus
-- the copy we lock in the moment we go down. The HRP itself is destroyed and
-- recreated across down/revive, so the saved value is all we have to put the
-- new one back where the old one was standing.
local lastGoodCFrame = nil
local savedCFrame = nil
local restoreToken = 0
local restoreActive = false
-- os.clock() of the moment we went down, used to tell a real revive apart from
-- a round restart that happened to clear the Downed flag
local downedAt = 0
-- This game rebuilds the WHOLE Character model on revive, not just the
-- HumanoidRootPart. That fires CharacterAdded, which re-hooks and wipes our
-- state before the poll loop below ever sees the Downed flag clear -- so the
-- saved position has to survive the re-hook. This is the main restore path.
local pendingRestoreCFrame = nil
local pendingRestoreAt = 0
local pendingDownedFor = 0

local function findCharacterObject(targetModel)
    for _, obj in pairs(getgc(true)) do
        if type(obj) == "table"
            and rawget(obj, "Model") == targetModel
            and rawget(obj, "DataRegistry") then
            return obj
        end
    end
    return nil
end

local function unhookAll()
    if pollConn then
        pollConn:Disconnect()
        pollConn = nil
    end
    if freezeConn then
        freezeConn:Disconnect()
        freezeConn = nil
    end
    -- if a freeze was mid-flight when we unhook (toggle off, respawn, etc),
    -- make sure we don't leave the part stuck Anchored forever
    freezeToken += 1
    if frozenPart and frozenPart.Parent then
        frozenPart.Anchored = frozenPartOriginalAnchored
    end
    frozenPart = nil
    -- cancel any in-flight position restore too, otherwise it keeps yanking
    -- the character back after the feature was turned off
    restoreToken += 1
    restoreActive = false
    -- Getting unhooked while down means the character was replaced under us,
    -- i.e. we are being revived. Carry the position over to the next hook.
    if wasDowned and savedCFrame then
        pendingRestoreCFrame = savedCFrame
        pendingRestoreAt = os.clock()
        pendingDownedFor = os.clock() - downedAt
    end
    savedCFrame = nil
    lastGoodCFrame = nil
    characterObj = nil
    wasDowned = false
end

local function getHRP()
    -- deliberately re-read LocalPlayer.Character every call: the HumanoidRootPart
    -- (and sometimes the whole model) is a different instance after a revive
    local character = LocalPlayer.Character
    if not character or not character.Parent then return nil end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then
        return hrp
    end
    return nil
end

local function getRigRoot()
    -- workspace.Players.<username>.HumanoidRootPart gets recreated/respawned
    -- so anchoring it doesn't reliably hold the character in place.
    -- workspace.Rigs.<username>.ArmRot is the actual root part the rest
    -- of the rig hangs off of (via Motor6D/weld) and is NOT recreated,
    -- so anchoring that instead reliably freezes the whole body.
    --
    -- There are TWO Folders named "Rigs" directly under workspace, one of
    -- them empty (a leftover/decoy). We scan every child named "Rigs" and
    -- skip empty ones until we find the real rig model by username.
    for _, rigsFolder in ipairs(workspace:GetChildren()) do
        if rigsFolder.Name == "Rigs" and #rigsFolder:GetChildren() > 0 then
            local rigModel = rigsFolder:FindFirstChild(LocalPlayer.Name)
            if rigModel then
                local armRot = rigModel:FindFirstChild("ArmRot")
                if armRot and armRot:IsA("BasePart") then
                    return armRot
                end
            end
        end
    end

    return nil
end

local function freezeCFrame()
    -- Lock in where we were standing BEFORE anything else, and before the
    -- early-out below: the position restore has to work even on a frame where
    -- the rig root can't be found. The HRP is often already destroyed by the
    -- time the Downed flag flips, so fall back to the sample the poll loop
    -- took on the last frame we were still up.
    local hrp = getHRP()
    savedCFrame = (hrp and hrp.CFrame) or lastGoodCFrame

    local armRot = getRigRoot()
    if not armRot then return end

    -- Only take a fresh reading of the part's real Anchored state when we are
    -- NOT already holding a freeze on this exact part.
    --
    -- Fast down -> revive -> down inside the 3s window re-enters this function
    -- while the previous freeze is still mid-flight. At that moment
    -- armRot.Anchored is already true *because we set it*, so re-reading it
    -- would overwrite frozenPartOriginalAnchored with true and the delayed
    -- restore below would "restore" the player to anchored -> stuck forever.
    if frozenPart ~= armRot then
        -- a different part was frozen before (e.g. rig replaced on respawn),
        -- restore it before we take ownership of the new one
        if frozenPart and frozenPart.Parent then
            frozenPart.Anchored = frozenPartOriginalAnchored
        end
        frozenPartOriginalAnchored = armRot.Anchored
    end

    frozenPart = armRot
    armRot.Anchored = true

    freezeToken += 1
    local myToken = freezeToken

    task.delay(3, function()
        -- only revert if nothing else has taken over (e.g. re-entered
        -- Downed again, or unhookAll already reverted and reset state)
        if myToken == freezeToken and frozenPart == armRot and armRot.Parent then
            armRot.Anchored = frozenPartOriginalAnchored
            frozenPart = nil
        end
    end)
end

local function restoreCFrame()
    local target = savedCFrame
    if not target then
        return
    end

    restoreToken += 1
    local myToken = restoreToken
    restoreActive = true

    task.spawn(function()
        -- phase 1: wait for the game to hand us the new HumanoidRootPart.
        -- The old one is destroyed on down, so the instance we see here is
        -- usually not the one that existed when we saved the CFrame.
        local hrp = nil
        local deadline = os.clock() + NEW_HRP_TIMEOUT
        while os.clock() < deadline do
            if myToken ~= restoreToken or not AutoReviveEnabled then
                restoreActive = false
                return
            end
            hrp = getHRP()
            if hrp then break end
            RunService.Heartbeat:Wait()
        end

        if not hrp then
            restoreActive = false
            return
        end

        -- phase 2: re-apply the saved CFrame every frame until it sticks.
        -- One assignment is not enough: the server places the fresh HRP at a
        -- spawn point (or lets it fall) over the next few frames, so we have
        -- to keep overwriting until the position stops drifting.
        local settled = 0
        local stuck = false
        deadline = os.clock() + RESTORE_TIMEOUT
        while os.clock() < deadline do
            if myToken ~= restoreToken or not AutoReviveEnabled then break end

            local current = getHRP()
            if not current then break end
            if current ~= hrp then
                -- HRP got swapped out again mid-restore, start counting over
                hrp = current
                settled = 0
            end

            if (current.Position - target.Position).Magnitude <= RESTORE_SETTLE_DISTANCE then
                settled += 1
                if settled >= RESTORE_SETTLE_FRAMES then
                    stuck = true
                    break
                end
            else
                settled = 0
            end

            current.CFrame = target
            -- kill the momentum the fall/respawn gave us, otherwise we get
            -- shot away from the position we just restored
            current.AssemblyLinearVelocity = Vector3.zero
            current.AssemblyAngularVelocity = Vector3.zero

            RunService.Heartbeat:Wait()
        end

        if myToken == restoreToken then
            restoreActive = false
            if stuck then
            end
        end
    end)
end

local function hookDowned(character)
    unhookAll()

    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return end

    if pendingRestoreCFrame and (os.clock() - pendingRestoreAt) < HANDOFF_TIMEOUT then
        local downedFor = pendingDownedFor
        savedCFrame = pendingRestoreCFrame
        pendingRestoreCFrame = nil

        if downedFor > MAX_DOWNED_TIME then
            savedCFrame = nil
        else
            restoreCFrame()
        end
    else
        pendingRestoreCFrame = nil
    end

    task.spawn(function()
        local attempts = 0
        while AutoReviveEnabled and character.Parent and not characterObj and attempts < 50 do
            characterObj = findCharacterObject(character)
            if not characterObj then
                attempts += 1
                task.wait(0.1)
            end
        end
        if characterObj then
        else
        end
    end)

    pollConn = RunService.Heartbeat:Connect(function()
        if not AutoReviveEnabled then return end
        if not characterObj then return end

        local dataRegistry = rawget(characterObj, "DataRegistry")
        if not dataRegistry then return end

        local isDowned = dataRegistry:Get("Downed") == true

        if not isDowned and not restoreActive then
            local hrp = getHRP()
            if hrp then
                lastGoodCFrame = hrp.CFrame
            end
        end

        if isDowned and not wasDowned then
            wasDowned = true
            downedAt = os.clock()
            freezeCFrame()
            Event:FireServer(true)
        elseif not isDowned and wasDowned then
            wasDowned = false
            local downedFor = os.clock() - downedAt
            if downedFor > MAX_DOWNED_TIME then
                savedCFrame = nil
            else
                restoreCFrame()
            end
        end
    end)
end

local function onCharacterAdded(character)
    if AutoReviveEnabled then
        hookDowned(character)
    end
end

if LocalPlayer.Character then
    onCharacterAdded(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

MainTab:AddToggle("AutoRevive", {
    Title = "Auto-revive while downed",
    Default = false,
    Callback = function(value)
        AutoReviveEnabled = value

        if value then
            local character = LocalPlayer.Character
            if character then
                hookDowned(character)
            end
        else
            unhookAll()
            pendingRestoreCFrame = nil
        end
    end,
})

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local AntiEmoteEnabled = false

local Hooks = {
    ActionsRF = nil,
    ActionsRF_Orig = nil,
    StateRF = nil,
    StateRF_Orig = nil,
    MoveStats_Obj = nil,
    OrigSpeedChange = nil,
}

local function FindActionsRF()
    for _, v in pairs(getgc(true)) do
        if type(v) == "table"
            and rawget(v, "Emoting")
            and rawget(v, "MouseActive")
            and rawget(v, "FirstPerson")
        then
            return v
        end
    end
end

local function FindStateRF()
    for _, v in pairs(getgc(true)) do
        if type(v) == "table"
            and rawget(v, "Emoting")
            and rawget(v, "RelativeSpeedTest")
            and rawget(v, "WallrunDirection")
            and rawget(v, "Lunging")
        then
            return v
        end
    end
end

local function FindMovement()
    for _, v in pairs(getgc(true)) do
        if type(v) == "table"
            and rawget(v, "MoveStats")
            and rawget(v, "MoveFunction")
            and rawget(v, "Constraints")
            and rawget(v, "JumpAmount")
        then
            return v
        end
    end
end

local function InstallActionsHook()
    if Hooks.ActionsRF then return true end

    local RF = FindActionsRF()
    if not RF then
        warn("[Evaware] RequirementFunctions not found")
        return false
    end

    Hooks.ActionsRF = RF
    Hooks.ActionsRF_Orig = RF.Emoting

    RF.Emoting = function(p1, p2)
        if AntiEmoteEnabled then
            return false == p1
        end
        return Hooks.ActionsRF_Orig(p1, p2)
    end
    return true
end

local function InstallStateHook()
    if Hooks.StateRF then return true end

    local RF = FindStateRF()
    if not RF then
        return false
    end

    Hooks.StateRF = RF
    Hooks.StateRF_Orig = RF.Emoting

    RF.Emoting = function(p1, p2, p3)
        if AntiEmoteEnabled then
            return false == p2
        end
        return Hooks.StateRF_Orig(p1, p2, p3)
    end
    return true
end

-- Хук 3: MoveStats:SpeedChange игнорирует reason "Emote"
local function InstallSpeedHook()
    if Hooks.MoveStats_Obj then return true end

    local Movement = FindMovement()
    if not Movement or not Movement.MoveStats then
        warn("[Evaware] Movement/MoveStats not found")
        return false
    end

    local MoveStats = Movement.MoveStats
    Hooks.MoveStats_Obj = MoveStats
    Hooks.OrigSpeedChange = MoveStats.SpeedChange

    MoveStats.SpeedChange = function(self, reason, value)
        if AntiEmoteEnabled and reason == "Emote" then
            return Hooks.OrigSpeedChange(self, "Emote", nil)
        end
        return Hooks.OrigSpeedChange(self, reason, value)
    end
    return true
end

local function RemoveHooks()
    if Hooks.ActionsRF and Hooks.ActionsRF_Orig then
        Hooks.ActionsRF.Emoting = Hooks.ActionsRF_Orig
        Hooks.ActionsRF = nil
        Hooks.ActionsRF_Orig = nil
    end

    if Hooks.StateRF and Hooks.StateRF_Orig then
        Hooks.StateRF.Emoting = Hooks.StateRF_Orig
        Hooks.StateRF = nil
        Hooks.StateRF_Orig = nil
    end

    if Hooks.MoveStats_Obj and Hooks.OrigSpeedChange then
        Hooks.MoveStats_Obj.SpeedChange = Hooks.OrigSpeedChange
        Hooks.MoveStats_Obj = nil
        Hooks.OrigSpeedChange = nil
    end
end

local function EmergencyUnfreeze()
    local player = Players.LocalPlayer
    local char = player.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")

    if hrp then
        hrp.Anchored = false
    end
    if hum then
        hum.PlatformStand = false
    end
end

local AntiEmote = MainTab:AddToggle("AntiEmote", {
    Title = "Move while any emote - bypass",
    Default = false,
    Callback = function(Value)
        AntiEmoteEnabled = Value

        if Value then
            local ok1 = InstallActionsHook()
            local ok2 = InstallStateHook()
            local ok3 = InstallSpeedHook()

            if not ok1 or not ok2 or not ok3 then
                warn("[Evaware] Failed to install hooks")
                AntiEmoteEnabled = false
                return
            end
        else
            AntiEmoteEnabled = false

            if Hooks.MoveStats_Obj and Hooks.OrigSpeedChange then
                local Movement = FindMovement()
                if Movement then
                    local DR = Movement.DataRegistry
                    local emoteVal = DR and DR:Get("Emote")
                    if emoteVal and emoteVal ~= 0 then
                        local Services = game:GetService("ReplicatedStorage"):WaitForChild("Services")
                        local ClientItemService = require(Services.Items.ClientItemService)
                        local ItemFromID = ClientItemService:GetItemFromID(emoteVal)
                        if ItemFromID then
                            local EmoteInfo = require(ItemFromID).EmoteInfo or {}
                            Hooks.OrigSpeedChange(Hooks.MoveStats_Obj, "Emote", EmoteInfo.SpeedMult or 1)
                        end
                    else
                        Hooks.OrigSpeedChange(Hooks.MoveStats_Obj, "Emote", nil)
                    end
                end
            end

            RemoveHooks()

            task.wait()
            EmergencyUnfreeze()
        end
    end,
})

local vehicleEnabled = false
local vehicleSpeed = 45
local vehicleTorque = 80000
local gravity = workspace.Gravity / 196.2
local VehicleToggleObject

local function applyVehicle()
    pcall(function()
        local gravity = workspace.Gravity / 196.2

        for _, v in pairs(getgc(true)) do
            if type(v) == "table" 
                and rawget(v, "MaxSpeed") ~= nil 
                and rawget(v, "DrivingTorque") ~= nil 
                and rawget(v, "WheelFriction") ~= nil 
            then
                v.MaxSpeed = vehicleSpeed / 0.6263
                v.ReverseSpeed = (vehicleSpeed * 0.35) / 0.6263
                v.DrivingTorque = vehicleTorque
                v.BrakingTorque = vehicleTorque * 1.2
            end

            if type(v) == "table" and rawget(v, "UpdateThrottle") ~= nil then
                local ok, upvals = pcall(getupvalues, v.UpdateThrottle)
                if ok and upvals then
                    for i, val in pairs(upvals) do
                        if type(val) == "number" and val > 100 and val < 10000000 then
                            setupvalue(v.UpdateThrottle, i, vehicleTorque * gravity)
                        end
                    end
                end
            end
        end

        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("CylindricalConstraint") 
                and obj.Name ~= "MotorFL" 
                and obj.Name ~= "MotorFR" 
            then
                obj.MotorMaxTorque = vehicleTorque * gravity
                obj.MotorMaxAngularAcceleration = math.huge
                obj.AngularVelocity = vehicleSpeed / 0.6263
            end
        end
    end)
end

VehicleToggleObject = MainTab:AddToggle("VehicleSpeedToggle", {
    Title = "Change Vehicle Speed",
    Default = false,
    Callback = function(value)
        vehicleEnabled = value
        if value then
            applyVehicle()
        end
    end,
})

addNumericInput(MainTab, "vehicleMaxSpeed", {
    Title = "Vehicle Max Speed",
    Min = 45, Max = 500,
    Increment = 5,
    Rounding = 0,
    Suffix = " studs",
    Default = 45,
    Callback = function(value)
        vehicleSpeed = value
        if vehicleEnabled then applyVehicle() end
    end,
})

addNumericInput(MainTab, "vehicleTorque", {
    Title = "Vehicle Torque",
    Min = 80000, Max = 10000000,
    Increment = 10000,
    Rounding = 0,
    Default = 80000,
    Callback = function(value)
        vehicleTorque = value
        if vehicleEnabled then applyVehicle() end
    end,
})
end)

end -- /do char_adv
do -- extra_mov
MainTab:AddParagraph({ Title = "Extra Movement", Content = "" })
local downedSurfEnabled = false
local downedSurfConnection = nil
local downedCharConnection = nil
local downedVelocity = nil
local downedAttachment = nil
local downedDashMode = "Air Move"

local DASH_SPEED = 55.5
local ACCEL = 12
local DECEL = 18
local RAY_DIST = 3.5

local currentSpeed = 0

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ORIGINAL_DOWNED_MOVETYPE = "Run"
local ORIGINAL_DOWNED_CANJUMP = false

local function getDownedState()
    local StateInfo = require(ReplicatedStorage.Objects.Game.Character.Shared.StateInfo)
    for _, state in ipairs(StateInfo.States) do
        if state.State == "Downed" then
            return state
        end
    end
    return nil
end

local function patchDownedState()
    local state = getDownedState()
    if not state or not state.Movement then return end
    rawset(state.Movement, "MoveType", "Air")
    rawset(state.Movement, "CanJump", true)
end

local function restoreDownedState()
    local state = getDownedState()
    if not state or not state.Movement then return end
    rawset(state.Movement, "MoveType", ORIGINAL_DOWNED_MOVETYPE)
    rawset(state.Movement, "CanJump", ORIGINAL_DOWNED_CANJUMP)
    rawset(state.Movement, "SpeedMult", 0.3)
end

local function createConstraint(hrp)
    if downedAttachment then downedAttachment:Destroy() downedAttachment = nil end
    if downedVelocity then downedVelocity:Destroy() downedVelocity = nil end

    downedAttachment = Instance.new("Attachment")
    downedAttachment.Parent = hrp

    downedVelocity = Instance.new("LinearVelocity")
    downedVelocity.Attachment0 = downedAttachment
    downedVelocity.MaxForce = math.huge
    downedVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
    downedVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
    downedVelocity.PrimaryTangentAxis = Vector3.new(1, 0, 0)
    downedVelocity.SecondaryTangentAxis = Vector3.new(0, 0, 1)
    downedVelocity.PlaneVelocity = Vector2.new(0, 0)
    downedVelocity.Enabled = false
    downedVelocity.Parent = hrp
end

local function removeConstraint()
    if downedVelocity then downedVelocity:Destroy() downedVelocity = nil end
    if downedAttachment then downedAttachment:Destroy() downedAttachment = nil end
    currentSpeed = 0
end

local function isInDownedState()
    local char = player.Character
    if not char then return false end
    return char:GetAttribute("Downed") == true
end

local function isWallAhead(hrp, dir)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = { player.Character }
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local result = workspace:Raycast(hrp.Position, dir * RAY_DIST, rayParams)
    if result then
        local normal = result.Normal
        if math.abs(normal.Y) < 0.5 then
            return true
        end
    end
    return false
end

local function applyMode()
    if downedDashMode == "Air Move" then
        patchDownedState()
    else
        restoreDownedState()
    end
end

local function startDownedSurf()
    if downedSurfConnection then downedSurfConnection:Disconnect() downedSurfConnection = nil end

    applyMode()

    downedSurfConnection = RunService.Heartbeat:Connect(function(dt)
        if not downedSurfEnabled then return end
        if downedDashMode ~= "Default" then return end

        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        if not isInDownedState() then
            if downedVelocity then
                downedVelocity.PlaneVelocity = Vector2.new(0, 0)
                downedVelocity.Enabled = false
            end
            currentSpeed = 0
            return
        end

        if not downedVelocity or not downedVelocity.Parent then
            createConstraint(hrp)
        end

        local holding = UIS:IsKeyDown(Enum.KeyCode.LeftControl)
        local look = workspace.CurrentCamera.CFrame.LookVector
        local forward = Vector3.new(look.X, 0, look.Z).Unit

        local wallBlocked = holding and isWallAhead(hrp, forward)

        if holding and not wallBlocked then
            currentSpeed = math.min(currentSpeed + ACCEL * dt * 60, DASH_SPEED)
        else
            local decel = wallBlocked and (DECEL * 3) or DECEL
            currentSpeed = math.max(currentSpeed - decel * dt * 60, 0)
        end

        if currentSpeed > 0 then
            downedVelocity.PlaneVelocity = Vector2.new(forward.X * currentSpeed, forward.Z * currentSpeed)
            downedVelocity.Enabled = true
        else
            downedVelocity.PlaneVelocity = Vector2.new(0, 0)
            downedVelocity.Enabled = false
        end
    end)
end

local function stopDownedSurf()
    if downedSurfConnection then downedSurfConnection:Disconnect() downedSurfConnection = nil end
    removeConstraint()
    restoreDownedState()
end

local function setDownedSurf(state)
    downedSurfEnabled = state
    if state then
        if downedCharConnection then downedCharConnection:Disconnect() end
        downedCharConnection = player.CharacterAdded:Connect(function()
            removeConstraint()
            if downedSurfEnabled then
                applyMode()
            end
        end)
        startDownedSurf()
        Fluent:Notify({ Title = "Downed Dash", Content = "Enabled", Duration = 1.5 })
    else
        if downedCharConnection then downedCharConnection:Disconnect() downedCharConnection = nil end
        stopDownedSurf()
        Fluent:Notify({ Title = "Downed Dash", Content = "Disabled", Duration = 1.5 })
    end
end

MainTab:AddDropdown("downedDashMode", {
    Title = "Downed Dash Mode",
    Values = {"Default", "Air Move"},
    Default = "Air Move",
    Callback = function(value)
        downedDashMode = value[1] or value
        if downedSurfEnabled then
            restoreDownedState()
            removeConstraint()
            if downedSurfConnection then downedSurfConnection:Disconnect() downedSurfConnection = nil end
            startDownedSurf()
        end
    end,
})

MainTab:AddToggle("DownedDashToggle", {
    Title = "Downed Dash",
    Default = false,
    Callback = function(value)
        setDownedSurf(value)
    end,
})
pcall(function()
local cactusHitboxSize = 1
local cactusHitboxEnabled = false
local spawnedHitboxParts = {}

local function findCacti()
    local cacti = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("UnionOperation") then
            local nameLower = obj.Name:lower()
            local parentNameLower = obj.Parent and obj.Parent.Name:lower() or ""
            if nameLower:find("cact") or parentNameLower:find("cact")
            or nameLower:find("spike") or parentNameLower:find("spike")
            or nameLower:find("needle") or parentNameLower:find("needle") then
                table.insert(cacti, obj)
            end
        end
    end
    return cacti
end

local function expandCactusHitboxes()
    spawnedHitboxParts = {}
    local cacti = findCacti()
    local count = 0
    for _, part in ipairs(cacti) do
        if part and part.Parent then
            local hitbox = Instance.new("Part")
            hitbox.Name         = "CactusHitboxExpander"
            hitbox.Anchored     = true
            hitbox.CanCollide   = true
            hitbox.Transparency = 1
            hitbox.CanQuery     = false
            hitbox.CastShadow   = false
            hitbox.Massless     = true
            hitbox.Size = part.Size + Vector3.new(cactusHitboxSize, 0, cactusHitboxSize)
            local pos = part.CFrame.Position
            local _, yRot, _ = part.CFrame:ToEulerAnglesYXZ()
            hitbox.CFrame = CFrame.new(pos) * CFrame.Angles(0, yRot, 0)
            hitbox.Parent = workspace
            local weld = Instance.new("WeldConstraint")
            weld.Part0  = hitbox
            weld.Part1  = part
            weld.Parent = hitbox
            hitbox.Anchored = false
            table.insert(spawnedHitboxParts, hitbox)
            count = count + 1
        end
    end
    return count
end

local function removeCactusHitboxes()
    local count = 0
    for _, hitbox in ipairs(spawnedHitboxParts) do
        if hitbox and hitbox.Parent then
            hitbox:Destroy()
            count = count + 1
        end
    end
    spawnedHitboxParts = {}
    return count
end

local CactusToggleObject = nil

local function setCactusHitbox(state)
    cactusHitboxEnabled = state
    if state then
        local count = expandCactusHitboxes()
        if count == 0 then
            Fluent:Notify({ Title = "Cactus Hitbox", Content = "No cactuses found on this map!", Duration = 3 })
            cactusHitboxEnabled = false
            task.spawn(function() task.wait() if CactusToggleObject then Options["CactusHitboxToggle"]:SetValue(false) end end)
            return
        end
        Fluent:Notify({ Title = "Cactus Hitbox", Content = "Added hitbox on " .. count .. " parts (+" .. cactusHitboxSize .. " size)", Duration = 3 })
    else
        local count = removeCactusHitboxes()
        Fluent:Notify({ Title = "Cactus Hitbox", Content = "Removed " .. count .. " hitbox parts", Duration = 2 })
    end
end

addNumericInput(MainTab, "cactusHitboxSize", {
    Title = "Cactus Hitbox Size",
    Min = 1, Max = 10,
    Increment = 0.5,
    Rounding = 1,
    Suffix = "X/Z",
    Default = 1,
    Callback = function(val)
        cactusHitboxSize = val
        if cactusHitboxEnabled then
            removeCactusHitboxes()
            local count = expandCactusHitboxes()
            Fluent:Notify({ Title = "Cactus Hitbox", Content = "Updated: +" .. val .. " size on " .. count .. " parts", Duration = 1.5 })
        end
    end,
})

CactusToggleObject = MainTab:AddToggle("CactusHitboxToggle", {
    Title = "Expand Cactus Hitbox",
    Default = false,
    Callback = function(value)
        if value == cactusHitboxEnabled then return end
        setCactusHitbox(value)
    end,
})
end)

pcall(function()
local bollardHitboxSize = 1
local bollardHitboxEnabled = false
local spawnedBollardParts = {}

local function getCharacterModels()
    local chars = {}
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player.Character then chars[player.Character] = true end
    end
    return chars
end

local function isPlayerPart(obj, charCache)
    local ancestor = obj
    while ancestor do
        if charCache[ancestor] then return true end
        ancestor = ancestor.Parent
    end
    return false
end

local function findBollards()
    local bollards = {}
    local charCache = getCharacterModels()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("UnionOperation") then
            if isPlayerPart(obj, charCache) then continue end
            if obj.Name == "BollardHitboxExpander" then continue end
            local nameLower = obj.Name:lower()
            local parentNameLower = obj.Parent and obj.Parent.Name:lower() or ""
            local nameMatch =
                nameLower:find("bollard") or nameLower:find("post") or nameLower:find("pole") or
                nameLower:find("fence") or nameLower:find("railing") or nameLower:find("column") or
                nameLower:find("cone") or nameLower:find("sign") or nameLower:find("wirerod") or
                nameLower:find("ladder") or nameLower:find("lego") or nameLower:find("lamppost") or
                nameLower:find("lampposts") or nameLower:find("bench") or nameLower:find("woodenfence") or
                nameLower:find("telephone") or nameLower:find("fenc") or
                parentNameLower:find("bollard") or parentNameLower:find("post") or parentNameLower:find("pole") or
                parentNameLower:find("fence") or parentNameLower:find("railing") or parentNameLower:find("column") or
                parentNameLower:find("cone") or parentNameLower:find("sign") or parentNameLower:find("wirerod") or
                parentNameLower:find("ladder") or parentNameLower:find("lego") or parentNameLower:find("lamppost") or
                parentNameLower:find("lampposts") or parentNameLower:find("bench") or parentNameLower:find("woodenfence") or
                parentNameLower:find("telephone") or parentNameLower:find("fenc")
            local shapeMatch = false
            if obj:IsA("BasePart") then
                local s = obj.Size
                local isNarrow = s.X < 3 and s.Z < 3
                local isTall   = s.Y > s.X * 1.5
                local notFloor = s.Y > 1
                local notBodyPart = s.Y > 1.5 or (s.X > 0.5 and s.Z > 0.5)
                shapeMatch = isNarrow and isTall and notFloor and notBodyPart
            end
            if (nameMatch or shapeMatch) and obj.CanCollide then
                table.insert(bollards, obj)
            end
        end
    end
    return bollards
end

local function expandBollardHitboxes()
    spawnedBollardParts = {}
    local bollards = findBollards()
    local count = 0
    local charCache = getCharacterModels()
    for _, part in ipairs(bollards) do
        if part and part.Parent and not isPlayerPart(part, charCache) then
            local hitbox = Instance.new("Part")
            hitbox.Name = "BollardHitboxExpander"
            hitbox.Anchored = true
            hitbox.CanCollide = true
            hitbox.Transparency = 1
            hitbox.CanQuery = false
            hitbox.CastShadow = false
            hitbox.Massless = true
            hitbox.Size = Vector3.new(
                math.max(1, part.Size.X + bollardHitboxSize),
                part.Size.Y,
                math.max(1, part.Size.Z + bollardHitboxSize)
            )
            local pos = part.CFrame.Position
            local _, yRot, _ = part.CFrame:ToEulerAnglesYXZ()
            hitbox.CFrame = CFrame.new(pos) * CFrame.Angles(0, yRot, 0)
            hitbox.Parent = workspace
            table.insert(spawnedBollardParts, hitbox)
            count = count + 1
        end
    end
    return count
end

local function removeBollardHitboxes()
    local count = 0
    for _, hitbox in ipairs(spawnedBollardParts) do
        if hitbox and hitbox.Parent then
            hitbox:Destroy()
            count = count + 1
        end
    end
    spawnedBollardParts = {}
    return count
end

local BollardToggleObject = nil

local function setBollardHitbox(state)
    bollardHitboxEnabled = state
    if state then
        local count = expandBollardHitboxes()
        if count == 0 then
            Fluent:Notify({ Title = "Signs/Bollards Hitbox", Content = "Signs/Bollards not found!", Duration = 3 })
            bollardHitboxEnabled = false
            task.spawn(function() task.wait() if BollardToggleObject then Options["BollardHitboxToggle"]:SetValue(false) end end)
            return
        end
        Fluent:Notify({ Title = "Signs/Bollards Hitbox", Content = "Added hitboxes on " .. count .. " parts (+" .. bollardHitboxSize .. " X/Z)", Duration = 3 })
    else
        local count = removeBollardHitboxes()
        Fluent:Notify({ Title = "Signs/Bollards Hitbox", Content = "Removed " .. count .. " hitbox parts", Duration = 2 })
    end
end

addNumericInput(MainTab, "signsbollardsHitboxSize", {
    Title = "Signs/Bollards Hitbox Size",
    Min = 1, Max = 10,
    Increment = 0.5,
    Rounding = 1,
    Default = 1,
    Suffix = "X/Z",
    Callback = function(val)
        bollardHitboxSize = val
        if bollardHitboxEnabled then
            pcall(function()
                removeBollardHitboxes()
                local count = expandBollardHitboxes()
                Fluent:Notify({ Title = "Signs/Bollards Hitbox", Content = "Updated: +" .. val .. " X/Z size on " .. count .. " parts", Duration = 1.5 })
            end)
        end
    end,
})

BollardToggleObject = MainTab:AddToggle("BollardHitboxToggle", {
    Title = "Expand Signs/Bollards Hitboxes",
    Default = false,
    Callback = function(value)
        if value == bollardHitboxEnabled then return end
        pcall(function() setBollardHitbox(value) end)
    end,
})
end)

pcall(function()
local streetlampHitboxSize = 1
local streetlampHitboxEnabled = false
local streetlampHitboxMode = "Box"
local spawnedStreetlampParts = {}

local function expandStreetlampHitboxes()
    spawnedStreetlampParts = {}
    local lights = workspace:FindFirstChild("Map")
     and workspace.Map:FindFirstChild("Parts")
     and workspace.Map.Parts:FindFirstChild("Lights")

    if not lights then
        Fluent:Notify({ Title = "Streetlamp Hitbox", Content = "Lights folder not found!", Duration = 3 })
        return 0
    end

    local count = 0
    for _, part in ipairs(lights:GetDescendants()) do
        if part:IsA("BasePart") then
            if streetlampHitboxMode == "Default" then
                local hitbox = Instance.new("Part")
                hitbox.Name = "StreetlampHitboxExpander"
                hitbox.Anchored = true
                hitbox.CanCollide = true
                hitbox.Transparency = 1
                hitbox.CanQuery = true
                CollectionService:AddTag(hitbox, "StreetlampExpander")
                hitbox.CastShadow = false
                hitbox.Massless = true
                hitbox.Size = part.Size
                hitbox.CFrame = part.CFrame
                hitbox.Parent = workspace
                table.insert(spawnedStreetlampParts, hitbox)
            else
                local hitbox = Instance.new("Part")
                hitbox.Name = "StreetlampHitboxExpander"
                hitbox.Anchored = true
                hitbox.CanCollide = true
                hitbox.Transparency = 1
                hitbox.CanQuery = false
                hitbox.CastShadow = false
                hitbox.Massless = true
                hitbox.Size = Vector3.new(
                    part.Size.X + streetlampHitboxSize,
                    part.Size.Y,
                    part.Size.Z + streetlampHitboxSize
                )
                local pos = part.CFrame.Position
                local _, yRot, _ = part.CFrame:ToEulerAnglesYXZ()
                hitbox.CFrame = CFrame.new(pos) * CFrame.Angles(0, yRot, 0)
                hitbox.Parent = workspace
                table.insert(spawnedStreetlampParts, hitbox)
            end
            count += 1
        end
    end
    return count
end

local function removeStreetlampHitboxes()
    for _, hitbox in ipairs(spawnedStreetlampParts) do
        if hitbox and hitbox.Parent then
            hitbox:Destroy()
        end
    end
    spawnedStreetlampParts = {}
end

local function setStreetlampHitbox(state)
    streetlampHitboxEnabled = state
    if state then
        local count = expandStreetlampHitboxes()
        Fluent:Notify({ Title = "Streetlamp Hitbox", Content = "Added hitboxes on " .. count .. " parts", Duration = 3 })
    else
        removeStreetlampHitboxes()
        Fluent:Notify({ Title = "Streetlamp Hitbox", Content = "Removed", Duration = 2 })
    end
end

MainTab:AddDropdown("streetlampHitboxMode", {
    Title = "Streetlamp Hitbox Mode",
    Values = {"Default", "Box"},
    Default = "Box",
    Callback = function(selected)
        streetlampHitboxMode = selected[1]
        if streetlampHitboxEnabled then
            removeStreetlampHitboxes()
            local count = expandStreetlampHitboxes()
            Fluent:Notify({ Title = "Streetlamp Hitbox", Content = "Mode: " .. streetlampHitboxMode .. " | " .. count .. " parts", Duration = 2 })
        end
    end,
})

MainTab:AddToggle("StreetlampHitbox", {
    Title = "Create Streetlamp Hitbox",
    Default = false,
    Callback = function(value)
        setStreetlampHitbox(value)
    end,
})

addNumericInput(MainTab, "streetlampHitboxSize", {
    Title = "Streetlamp Hitbox Size",
    Min = 1, Max = 10,
    Increment = 0.5,
    Rounding = 1,
    Default = 1,
    Suffix = "X/Z",
    Callback = function(val)
        streetlampHitboxSize = val
        if streetlampHitboxEnabled and streetlampHitboxMode == "Box" then
            removeStreetlampHitboxes()
            local count = expandStreetlampHitboxes()
            Fluent:Notify({ Title = "Streetlamp Hitbox", Content = "Updated: " .. count .. " parts", Duration = 1.5 })
        end
    end,
})
end)

end -- /do extra_mov
do -- emote_act
MainTab:AddParagraph({ Title = "Emote Actions", Content = "" })
pcall(function()
local movableEmoteEnabled = false
local originalSpeedMults = {}
local cachedEmoteModules = nil
local emoteWatchdogThread = nil

local function isEmoteStats(stats)
    if type(stats) ~= "table" then return false end
    local equip = stats.EquipInfo
    if type(equip) ~= "table" then return false end
    return equip.SlotType == "Emote"
end

local function collectEmoteModulesViaGC()
    local found = {}
    local seen = {}

    local ok, gcTable = pcall(function() return getgc(true) end)
    if not ok or not gcTable then return found end

    for _, v in ipairs(gcTable) do
        local okIsInst, isInst = pcall(function() return typeof(v) == "Instance" end)
        if okIsInst and isInst and not seen[v] then
            local okClass, isModule = pcall(function() return v:IsA("ModuleScript") end)
            if okClass and isModule then
                seen[v] = true

                local okAncestor, underItems = pcall(function()
                    return v:IsDescendantOf(game:GetService("ReplicatedStorage").Items)
                end)

                if okAncestor and underItems then
                    local okReq, stats = pcall(require, v)
                    if okReq and isEmoteStats(stats) then
                        table.insert(found, {module = v, stats = stats})
                    end
                end
            end
        end
    end

    return found
end

local function applyEmoteEntry(entry)
    local stats = entry.stats
    if type(stats) ~= "table" or type(stats.EmoteInfo) ~= "table" or stats.EmoteInfo.SpeedMult == nil then
        return
    end

    if originalSpeedMults[entry.module] == nil then
        originalSpeedMults[entry.module] = stats.EmoteInfo.SpeedMult
    end
    stats.EmoteInfo.SpeedMult = 1
end

local function stopEmoteWatchdog()
    if emoteWatchdogThread then
        task.cancel(emoteWatchdogThread)
        emoteWatchdogThread = nil
    end
end

local function startEmoteWatchdog()
    stopEmoteWatchdog()

    emoteWatchdogThread = task.spawn(function()
        while movableEmoteEnabled do
            task.wait(0.5)
            if not movableEmoteEnabled then break end
            if cachedEmoteModules then
                for _, entry in ipairs(cachedEmoteModules) do
                    local stats = entry.stats
                    if type(stats) == "table" and type(stats.EmoteInfo) == "table"
                        and stats.EmoteInfo.SpeedMult ~= nil
                        and stats.EmoteInfo.SpeedMult ~= 1 then
                        applyEmoteEntry(entry)
                    end
                end
            end
        end
        emoteWatchdogThread = nil
    end)
end

local function patchAllEmotes(enable)
    if enable then
        cachedEmoteModules = collectEmoteModulesViaGC()
    end

    if not cachedEmoteModules then return end

    for _, entry in ipairs(cachedEmoteModules) do
        if enable then
            applyEmoteEntry(entry)
        else
            local stats = entry.stats
            if type(stats) == "table" and type(stats.EmoteInfo) == "table"
                and originalSpeedMults[entry.module] ~= nil then
                stats.EmoteInfo.SpeedMult = originalSpeedMults[entry.module]
                originalSpeedMults[entry.module] = nil
            end
        end
    end

    if not enable then
        cachedEmoteModules = nil
    end
end

MainTab:AddToggle("NonmovableEmoteHopToggle", {
    Title = "Nonmovable emote hop",
    Default = false,
    Callback = function(value)
        movableEmoteEnabled = value
        patchAllEmotes(movableEmoteEnabled)

        if value then
            startEmoteWatchdog()
        else
            stopEmoteWatchdog()
        end
    end,
})

local unlockStatesEnabled = false
local stateInfoModule = nil
local originalStatesValues = {}

local TARGET_FIELDS = {"CanUseTools", "CanEmote", "CanInteract"}

local function findStateInfoModule()
    if stateInfoModule then return stateInfoModule end

    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ok, result = pcall(function()
        return require(ReplicatedStorage.Objects.Game.Character.Shared.StateInfo)
    end)

    if ok and type(result) == "table" and type(result.States) == "table" then
        stateInfoModule = result
        return stateInfoModule
    end

    warn("StateInfo module not found")
    return nil
end

local function patchAll(enable)
    local info = findStateInfoModule()
    if not info then return end

    if enable then
        originalStatesValues = {}
        for _, stateData in ipairs(info.States) do
            local stateName = stateData.State
            for _, field in ipairs(TARGET_FIELDS) do
                if stateData[field] == false then
                    if not originalStatesValues[stateName] then
                        originalStatesValues[stateName] = {}
                    end
                    originalStatesValues[stateName][field] = false
                    stateData[field] = true
                end
            end
        end
    else
        for _, stateData in ipairs(info.States) do
            local stateName = stateData.State
            local savedFields = originalStatesValues[stateName]
            if savedFields then
                for field, originalVal in pairs(savedFields) do
                    stateData[field] = originalVal
                end
            end
        end
        originalStatesValues = {}
    end
end

MainTab:AddToggle("UnlockAllStatesToggle", {
    Title = "Unlock using items & emotes in every state",
    Default = false,
    Callback = function(value)
        unlockStatesEnabled = value
        patchAll(value)
    end,
})

local spinFastEnabled = false
local spinFastConnection = nil
local SpinFastToggleObject = nil
local spinSpeed = 250

local function cleanupSpinFast()
    if spinFastConnection then
        spinFastConnection:Disconnect()
        spinFastConnection = nil
    end
end
local function startSpinFast()
    cleanupSpinFast()

    spinFastConnection = RunService.Heartbeat:Connect(function()
        if not spinFastEnabled then return end
        local char = player.Character
        if not char or not char.Parent then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        hrp.AssemblyAngularVelocity = Vector3.new(0, spinSpeed, 0)
    end)
end

local function stopSpinFast()
    cleanupSpinFast()
end

local function setSpinFast(state)
    if state == spinFastEnabled then return end

    spinFastEnabled = state
    if state then
        startSpinFast()
        Fluent:Notify({
            Title = "360 Spin",
            Content = "Enabled",
            Duration = 2
        })
    else
        stopSpinFast()
        Fluent:Notify({
            Title = "360 Spin",
            Content = "Disabled",
            Duration = 2
        })
    end

    if SpinFastToggleObject then
        syncToggle(SpinFastToggleObject, state)
    end
end

SpinFastToggleObject = MainTab:AddToggle("EmoteSpinToggle", {
    Title = "360 Spin",
    Default = false,
    Callback = function(value)
        setSpinFast(value)
    end,
})

addNumericInput(MainTab, "spinSpeed", {
    Title = "Spin Speed",
    Min = 250, Max = 2000,
    Increment = 10,
    Rounding = 0,
    Suffix = "",
    Default = 250,
    Callback = function(value)
        spinSpeed = value
    end,
})

MainTab:AddKeybind("SpinKeybind", {
    Title = "360 Spin Keybind",
    Default = "None",
    CurrentKeybind = "None",
    HoldToInteract = false,
    Callback = function()
        setSpinFast(not spinFastEnabled)
    end,
})

local spinFastEnabled = false
local spinFastConnection = nil
local SpinFastToggleObject = nil

local function cleanupSpinFast()
    if spinFastConnection then
        spinFastConnection:Disconnect()
        spinFastConnection = nil
    end
end

local function startSpinFast()
    cleanupSpinFast()

    spinFastConnection = RunService.Heartbeat:Connect(function(dt)
        if not spinFastEnabled then return end

        local char = player.Character
        if not char or not char.Parent then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local angle = math.rad(360 * 7 * dt)
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, angle, 0)
    end)
end

local function stopSpinFast()
    cleanupSpinFast()
end

local function setSpinFast(state)
    if state == spinFastEnabled then return end

    spinFastEnabled = state
    if state then
        startSpinFast()
        Fluent:Notify({
            Title = "360 Emote Hop",
            Content = "Enabled",
            Duration = 2
        })
    else
        stopSpinFast()
        Fluent:Notify({
            Title = "360 Emote hop",
            Content = "Disabled",
            Duration = 2
        })
    end

    if SpinFastToggleObject then
        syncToggle(SpinFastToggleObject, state)
    end
end

SpinFastToggleObject = MainTab:AddToggle("EmoteHopToggle360", {
    Title = "360 Emote Hop",
    Default = false,
    Callback = function(value)
        setSpinFast(value)
    end,
})

MainTab:AddKeybind("EmoteHopKeybind", {
    Title = "360 Emote Hop Keybind",
    Default = "None",
    CurrentKeybind = "None",
    HoldToInteract = false,
    Callback = function()
        setSpinFast(not spinFastEnabled)
    end,
})

local fasterEmoteTurnEnabled = false
local fasterEmoteTurnLoop = nil
local FasterEmoteTurnToggleObject = nil
local currentAngle = 0

local function getVehicleRoot()
    local char = game.Players.LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    for _, v in ipairs(hrp:GetChildren()) do
        if v.Name == "SeatWLD" and (v:IsA("Weld") or v:IsA("WeldConstraint")) then
            local driver = v.Part0
            if driver then
                local root = driver.AssemblyRootPart
                return root
            end
        end
    end
    return nil
end

local function setFasterEmoteTurn(state)
    fasterEmoteTurnEnabled = state

    if state then
        local char = game.Players.LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                currentAngle = math.deg(select(2, hrp.CFrame:ToEulerAnglesYXZ()))
            end
        end

        fasterEmoteTurnLoop = game:GetService("RunService").RenderStepped:Connect(function(dt)
            local char = game.Players.LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local hum = char:FindFirstChildOfClass("Humanoid")
            local vehicleRoot = getVehicleRoot()

            if not vehicleRoot then
                local animator = hum and hum:FindFirstChildOfClass("Animator")
                if not animator then return end

                local isEmoting = false
                local EMOTE_TRACKS = {
                    "AnimationClassic", "Animation", "IntroAnimation",
                    "IntroAnimationClassic", "Character", "CharacterClassic",
                    "AnimationLEGACY", "Intro", "Walk"
                }
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    for _, name in ipairs(EMOTE_TRACKS) do
                        if track.Name == name then
                            isEmoting = true
                            break
                        end
                    end
                    if isEmoting then break end
                end
                if not isEmoting then return end
            end

            local camera = workspace.CurrentCamera
            local _, camY, _ = camera.CFrame:ToEulerAnglesYXZ()
            local camDeg = math.deg(camY)

            local targetAngle = nil
            if UIS:IsKeyDown(Enum.KeyCode.A) then
                targetAngle = camDeg + 90
            elseif UIS:IsKeyDown(Enum.KeyCode.D) then
                targetAngle = camDeg - 90
            elseif UIS:IsKeyDown(Enum.KeyCode.S) then
                targetAngle = camDeg + 180
            elseif UIS:IsKeyDown(Enum.KeyCode.W) then
                targetAngle = camDeg
            end

            if targetAngle == nil then return end

            local diff = ((targetAngle - currentAngle) + 180) % 360 - 180
            currentAngle = currentAngle + diff * math.min(1, dt * 30)

            if vehicleRoot then
                vehicleRoot.CFrame = CFrame.new(vehicleRoot.Position) * CFrame.Angles(0, math.rad(currentAngle), 0)
            else
                hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(currentAngle), 0)
            end
        end)

        Fluent:Notify({ Title = "Faster Emote Turn", Content = "Enabled", Duration = 2 })
    else
        if fasterEmoteTurnLoop then
            fasterEmoteTurnLoop:Disconnect()
            fasterEmoteTurnLoop = nil
        end
        Fluent:Notify({ Title = "Faster Emote Turn", Content = "Disabled", Duration = 2 })
    end

    task.spawn(function()
        task.wait()
        syncToggle(FasterEmoteTurnToggleObject, state)
    end)
end

FasterEmoteTurnToggleObject = MainTab:AddToggle("FasterEmoteTurn", {
    Title = "Faster Emote Turn",
    Default = false,
    Callback = function(value)
        if value == fasterEmoteTurnEnabled then return end
        setFasterEmoteTurn(value)
    end,
})

local legacyEmoteTurnEnabled = false
local legacyEmoteTurnLoop = nil
local LegacyEmoteTurnToggleObject = nil
local currentAngle = 0
local savedVehicleRx = 0
local savedVehicleRz = 0
local wasGrounded = true

local EMOTE_TRACKS = {
    "AnimationClassic", "Animation", "IntroAnimation",
    "IntroAnimationClassic", "Character", "CharacterClassic",
    "AnimationLEGACY", "Intro", "Walk"
}

local function getVehicleRoot()
    local char = game.Players.LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    for _, v in ipairs(hrp:GetChildren()) do
        if v.Name == "SeatWLD" and (v:IsA("Weld") or v:IsA("WeldConstraint")) then
            local driver = v.Part0
            if driver then
                return driver.AssemblyRootPart
            end
        end
    end
    return nil
end

local function setLegacyEmoteTurn(state)
    legacyEmoteTurnEnabled = state

    if state then
        local char = game.Players.LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                currentAngle = math.deg(select(2, hrp.CFrame:ToEulerAnglesYXZ()))
            end
        end

        legacyEmoteTurnLoop = game:GetService("RunService").RenderStepped:Connect(function(dt)
            local char = game.Players.LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local hum = char:FindFirstChildOfClass("Humanoid")
            local vehicleRoot = getVehicleRoot()
            local downed = char:GetAttribute("Downed") == true

            if not vehicleRoot then
                local animator = hum and hum:FindFirstChildOfClass("Animator")
                if not animator then return end

                local isEmoting = false
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    for _, name in ipairs(EMOTE_TRACKS) do
                        if track.Name == name then
                            isEmoting = true
                            break
                        end
                    end
                    if isEmoting then break end
                end

                if not isEmoting and not downed then return end
            end

            local camera = workspace.CurrentCamera
            local _, camY, _ = camera.CFrame:ToEulerAnglesYXZ()
            local camDeg = math.deg(camY)

            local targetAngle = nil
            if UIS:IsKeyDown(Enum.KeyCode.A) then
                targetAngle = camDeg + 90
            elseif UIS:IsKeyDown(Enum.KeyCode.D) then
                targetAngle = camDeg - 90
            elseif UIS:IsKeyDown(Enum.KeyCode.S) then
                targetAngle = camDeg + 180
            elseif UIS:IsKeyDown(Enum.KeyCode.W) then
                targetAngle = camDeg
            end

            if targetAngle == nil then return end

            local speed = downed and 7 or 10
            local diff = ((targetAngle - currentAngle) + 180) % 360 - 180
            currentAngle = currentAngle + diff * math.min(1, dt * speed)

            if vehicleRoot then
                local cf = vehicleRoot.CFrame
                local rx, _, rz = cf:ToEulerAnglesYXZ()

                local isGrounded = hum and (
                    hum:GetState() == Enum.HumanoidStateType.Running or
                    hum:GetState() == Enum.HumanoidStateType.Seated
                )

                if isGrounded then
                    savedVehicleRx = rx
                    savedVehicleRz = rz
                    wasGrounded = true
                else
                    wasGrounded = false
                end
                vehicleRoot.CFrame = CFrame.new(vehicleRoot.Position)
                    * CFrame.Angles(savedVehicleRx, math.rad(currentAngle), savedVehicleRz)
            else
                local currentCF = hrp.CFrame
                local rx, _, rz = currentCF:ToEulerAnglesYXZ()
                hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(rx, math.rad(currentAngle), rz)
            end
        end)

        Fluent:Notify({ Title = "Legacy Emote Turn", Content = "Enabled", Duration = 2 })
    else
        if legacyEmoteTurnLoop then
            legacyEmoteTurnLoop:Disconnect()
            legacyEmoteTurnLoop = nil
        end
        Fluent:Notify({ Title = "Legacy Emote Turn", Content = "Disabled", Duration = 2 })
    end

    task.spawn(function()
        task.wait()
        syncToggle(LegacyEmoteTurnToggleObject, state)
    end)
end

LegacyEmoteTurnToggleObject = MainTab:AddToggle("LegacyEmoteTurn", {
    Title = "Legacy 60 FPS Animation Emote Turn",
    Default = false,
    Callback = function(value)
        if value == legacyEmoteTurnEnabled then return end
        setLegacyEmoteTurn(value)
    end,
})
end)

local emotingShiftlock = false

local function setEmotingShiftlock(state)
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" then
            local targets = {"Emoting", "EmotingAir", "EmotingSlide", "EmotingSlideAir", "EmoteSwimming"}
            for _, key in ipairs(targets) do
                local entry = rawget(v, key)
                if entry and type(entry) == "table" then
                    local rootOri = rawget(entry, "RootPartOrientation")
                    if rootOri and type(rootOri) == "table" and rawget(rootOri, "Type") ~= nil then
                        if state then
                            rootOri.Type = "Camera"
                        else
                            rootOri.Type = "MoveDir"
                        end
                    end
                end
            end
        end
    end
end

MainTab:AddToggle("EmoteShiftlock", {
    Title = "Unlock shiftlock while in emote",
    Default = false,
    Callback = function(value)
        emotingShiftlock = value
        setEmotingShiftlock(value)
        Fluent:Notify({
            Title = "Emote Shiftlock",
            Content = value and "Enabled" or "Disabled",
            Duration = 1.5,
        })
    end,
})

end -- /do emote_act
do -- hitbox
HitboxTab:AddParagraph({ Title = "Hitbox Creator", Content = "" })

local hitboxSizeX = 5
local hitboxSizeY = 5
local hitboxSizeZ = 5
local hitboxMode = "hitbox"
local hitboxCreatorEnabled = false
local showHitboxesEnabled = false
local allCreatedHitboxes = {}

addNumericInput(HitboxTab, "x", {
    Title = "X",
    Min = 5, Max = 100,
    Increment = 1,
    Rounding = 0,
    Suffix = "",
    Default = 5,
    Callback = function(val) hitboxSizeX = val end,
})

addNumericInput(HitboxTab, "y", {
    Title = "Y",
    Min = 5, Max = 100,
    Increment = 1,
    Rounding = 0,
    Suffix = "",
    Default = 5,
    Callback = function(val) hitboxSizeY = val end,
})

addNumericInput(HitboxTab, "z", {
    Title = "Z",
    Min = 5, Max = 100,
    Increment = 1,
    Rounding = 0,
    Suffix = "",
    Default = 5,
    Callback = function(val) hitboxSizeZ = val end,
})

HitboxTab:AddDropdown("placementMode", {
    Title = "Placement Mode",
    Values = {"Hitbox", "Slope"},
    Default = "Hitbox",
    Multi = false,
    Callback = function(option)
        if type(option) == "table" then
            option = option[1]
        end
        if option == "Hitbox" then
            hitboxMode = "hitbox"
        elseif option == "Slope" then
            hitboxMode = "slopes"
        end
        Fluent:Notify({
            Title = "Hitbox Creator",
            Content = "Mode: " .. option,
            Duration = 1.5,
        })
    end,
})

local function spawnHitbox(mode)
    if #allCreatedHitboxes >= 170 then
        Fluent:Notify({
            Title = "Hitbox Creator",
            Content = "Limit reached: 170 hitboxes max",
            Duration = 2,
        })
        return
    end

    local camera = workspace.CurrentCamera
    local mouse  = player:GetMouse()

    local unitRay = camera:ScreenPointToRay(mouse.X, mouse.Y)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {player.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, rayParams)
    local spawnPos = result and result.Position or (unitRay.Origin + unitRay.Direction * 20)

if mode == "slopes" then
    local wedge = Instance.new("WedgePart")
    wedge.Anchored = true
    wedge.CanCollide = true
    wedge.CastShadow = false
    wedge.Size = Vector3.new(hitboxSizeX, hitboxSizeY, hitboxSizeZ)
    wedge.Name = "CreatedSlope"
    wedge.Material = Enum.Material.SmoothPlastic
    wedge.Transparency = 0.5
    wedge.Color = Color3.fromRGB(255, 255, 255)

    local excluded = {player.Character}
    for _, data in ipairs(allCreatedHitboxes) do
        if data.part then table.insert(excluded, data.part) end
    end

    local slopeRayParams = RaycastParams.new()
    slopeRayParams.FilterDescendantsInstances = excluded
    slopeRayParams.FilterType = Enum.RaycastFilterType.Exclude

    local slopeResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, slopeRayParams)
    local slopePos = slopeResult and slopeResult.Position or (unitRay.Origin + unitRay.Direction * 20)

    local camLook = camera.CFrame.LookVector
    local flatLook = Vector3.new(camLook.X, 0, camLook.Z)
    if flatLook.Magnitude < 0.001 then
        flatLook = Vector3.new(0, 0, -1)
    end
    flatLook = flatLook.Unit

    local right = flatLook:Cross(Vector3.new(0, 1, 0)).Unit
    wedge.CFrame = CFrame.fromMatrix(
        Vector3.new(slopePos.X, slopePos.Y + wedge.Size.Y / 2, slopePos.Z),
        right,
        Vector3.new(0, 1, 0),
        -flatLook
    )

    local selectionBox = Instance.new("SelectionBox")
    selectionBox.Adornee = wedge
    selectionBox.Color3 = Color3.fromRGB(150, 200, 255)
    selectionBox.LineThickness = 0.05
    selectionBox.SurfaceTransparency = 1
    selectionBox.Visible = showHitboxesEnabled
    selectionBox.Parent = wedge

    wedge.Parent = workspace
    table.insert(allCreatedHitboxes, { part = wedge, type = "slope", box = selectionBox })
    return
end

    local part = Instance.new("Part")
    part.Anchored    = true
    part.CanCollide  = true
    part.CastShadow  = false
    part.Size        = Vector3.new(hitboxSizeX, hitboxSizeY, hitboxSizeZ)
    part.Name        = "CreatedHitbox"
    part.Transparency = showHitboxesEnabled and 0.5 or 0.85
    part.Color        = showHitboxesEnabled
        and Color3.fromRGB(50, 220, 80)
        or  Color3.fromRGB(200, 200, 200)
    part.CFrame = CFrame.new(spawnPos)
    part.Parent = workspace

    local selectionBox = Instance.new("SelectionBox")
    selectionBox.Adornee             = part
    selectionBox.Color3              = Color3.fromRGB(50, 220, 80)
    selectionBox.LineThickness       = 0.05
    selectionBox.SurfaceTransparency = 1
    selectionBox.Visible             = showHitboxesEnabled
    selectionBox.Parent              = part

    table.insert(allCreatedHitboxes, { part = part, type = "hitbox", box = selectionBox })
end

local creatorClickConn = nil

HitboxTab:AddToggle("HitboxCreatorToggle", {
    Title = "Hitbox Creator (LMB)",
    Default = false,
    Callback = function(val)
        hitboxCreatorEnabled = val
        if val then
            creatorClickConn = UIS.InputBegan:Connect(function(input, gp)
                if gp then return end
                if not hitboxCreatorEnabled then return end
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    spawnHitbox(hitboxMode)
                end
            end)
            Fluent:Notify({ Title = "Hitbox Creator", Content = "Enabled - LMB to place", Duration = 2 })
        else
            if creatorClickConn then
                creatorClickConn:Disconnect()
                creatorClickConn = nil
            end
            Fluent:Notify({ Title = "Hitbox Creator", Content = "Disabled", Duration = 1.5 })
        end
    end,
})

HitboxTab:AddButton({
    Title = "Remove Last Hitbox",
    Callback = function()
        if #allCreatedHitboxes == 0 then
            Fluent:Notify({
                Title = "Hitbox Creator",
                Content = "No hitboxes to remove",
                Duration = 1.5,
            })
            return
        end

        local last = table.remove(allCreatedHitboxes)
        if last.box then pcall(function() last.box:Destroy() end) end
        if last.part and last.part.Parent then
            pcall(function() last.part:Destroy() end)
        end

        Fluent:Notify({
            Title = "Hitbox Creator",
            Content = "Removed last " .. last.type,
            Duration = 1.5,
        })
    end,
})

HitboxTab:AddButton({
    Title = "Remove All Hitboxes",
    Callback = function()
        local count = 0
        for _, data in ipairs(allCreatedHitboxes) do
            if data.part and data.part.Parent then
                if data.box then pcall(function() data.box:Destroy() end) end
                pcall(function() data.part:Destroy() end)
                count = count + 1
            end
        end
        allCreatedHitboxes = {}

        Fluent:Notify({
            Title = "Hitbox Creator",
            Content = "Removed " .. count .. " hitboxes",
            Duration = 2,
        })
    end,
})

HitboxTab:AddKeybind("HitboxCreatorKeybind", {
    Title = "Hitbox Creator Keybind",
    Default = "None",
    CurrentKeybind = "None",
    HoldToInteract = false,
    Callback = function()
        local newVal = not hitboxCreatorEnabled
        Options["HitboxCreatorToggle"]:SetValue(newVal)
    end,
})

HitboxTab:AddKeybind("RemoveLastHitboxKeybind", {
    Title = "Remove Last Hitbox Keybind",
    Default = "None",
    CurrentKeybind = "None",
    HoldToInteract = false,
    Callback = function()
        if #allCreatedHitboxes == 0 then return end
        local last = table.remove(allCreatedHitboxes)
        if last.box then pcall(function() last.box:Destroy() end) end
        if last.part and last.part.Parent then
            pcall(function() last.part:Destroy() end)
        end
        Fluent:Notify({ Title = "Hitbox Creator", Content = "Removed last " .. last.type, Duration = 1.5 })
    end,
})

HitboxTab:AddKeybind("RemoveAllHitboxesKeybind", {
    Title = "Remove All Hitboxes Keybind",
    Default = "None",
    CurrentKeybind = "None",
    HoldToInteract = false,
    Callback = function()
        local count = 0
        for _, data in ipairs(allCreatedHitboxes) do
            if data.part and data.part.Parent then
                if data.box then pcall(function() data.box:Destroy() end) end
                pcall(function() data.part:Destroy() end)
                count = count + 1
            end
        end
        allCreatedHitboxes = {}
        Fluent:Notify({ Title = "Hitbox Creator", Content = "Removed " .. count .. " hitboxes", Duration = 2 })
    end,
})

HitboxTab:AddParagraph({ Title = "Hitbox selector", Content = "" })
--Hitbox selector
pcall(function()
    local expandX = 1
    local expandY = 1
    local expandZ = 1
    local selectorEnabled = false
    local selectedParts = {}
    local hoveredPart = nil
    local hoverBox = nil
    local inputConn = nil
    local mouseConn = nil

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local lp = Players.LocalPlayer
    local mouse = lp:GetMouse()

    local function getExcluded()
        local t = { workspace.CurrentCamera }
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then table.insert(t, p.Character) end
        end
        for _, data in pairs(selectedParts) do
            if data.hitbox then table.insert(t, data.hitbox) end
        end
        if hoverBox then table.insert(t, hoverBox) end
        return t
    end

    local function getTargetPart()
        local unitRay = workspace.CurrentCamera:ScreenPointToRay(mouse.X, mouse.Y)
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = getExcluded()
        local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, rayParams)
        if result and result.Instance and result.Instance:IsA("BasePart") then
            return result.Instance
        end
        return nil
    end

    local function makeSelectionBox(part, color, surfAlpha, thickness)
        local sb = Instance.new("SelectionBox")
        sb.Color3 = color
        sb.LineThickness = thickness
        sb.SurfaceTransparency = surfAlpha
        sb.SurfaceColor3 = color
        sb.Adornee = part
        sb.Parent = workspace
        return sb
    end

local function applyHitbox(part, data)
    if data.hitbox and data.hitbox.Parent then
        data.hitbox:Destroy()
        data.hitbox = nil
    end

    local orig = data.origSize

    local hb = Instance.new("Part")
    hb.Name = "CustomHitboxExpander"
    hb.Anchored = false
    hb.CanCollide = true
    hb.Transparency = 1
    hb.CanQuery = false
    hb.CastShadow = false
    hb.Massless = true
    hb.Size = Vector3.new(
        math.max(0.1, orig.X + expandX),
        math.max(0.1, orig.Y + expandY),
        math.max(0.1, orig.Z + expandZ)
    )
    hb.CFrame = part.CFrame
    hb.Parent = workspace

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = hb
    weld.Part1 = part
    weld.Parent = hb

    data.hitbox = hb

    if data.selBox and data.selBox.Parent then
        data.selBox:Destroy()
    end
    data.selBox = makeSelectionBox(hb, Color3.fromRGB(0, 200, 60), 0.45, 0.06)
end

    local function removeSelected(part)
        local data = selectedParts[part]
        if not data then return end
        if data.hitbox and data.hitbox.Parent then data.hitbox:Destroy() end
        if data.selBox and data.selBox.Parent then data.selBox:Destroy() end
        selectedParts[part] = nil
    end

    local function clearAllHitboxes()
        local count = 0
        for part, _ in pairs(selectedParts) do
            count += 1
            removeSelected(part)
        end
        selectedParts = {}
        return count
    end

    local function clearAllHighlights()
        for _, data in pairs(selectedParts) do
            if data.selBox and data.selBox.Parent then
                data.selBox:Destroy()
                data.selBox = nil
            end
        end
        if hoverBox and hoverBox.Parent then
            hoverBox:Destroy()
            hoverBox = nil
        end
        hoveredPart = nil
    end

    local function updateAllHitboxes()
        for part, data in pairs(selectedParts) do
            if part and part.Parent then
                applyHitbox(part, data)
            end
        end
    end

    local function startSelector()
        mouseConn = RunService.RenderStepped:Connect(function()
            local target = getTargetPart()
            if target ~= hoveredPart then
                if hoverBox then hoverBox:Destroy() hoverBox = nil end
                hoveredPart = target
                if target and not selectedParts[target] then
                    hoverBox = makeSelectionBox(target, Color3.fromRGB(0, 255, 80), 0.6, 0.04)
                end
            end
        end)

        inputConn = UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            local target = getTargetPart()
            if not target then return end

            if selectedParts[target] then
                if hoverBox then hoverBox:Destroy() hoverBox = nil end
                hoveredPart = nil
                removeSelected(target)
                local count = 0
                for _ in pairs(selectedParts) do count += 1 end
                Fluent:Notify({ Title = "Hitbox Selector", Content = "Deselected - " .. count .. " object(s) remaining", Duration = 2 })
            else
                if hoverBox then hoverBox:Destroy() hoverBox = nil end
                hoveredPart = nil
                local data = { hitbox = nil, selBox = nil, origSize = target.Size }
                selectedParts[target] = data
                applyHitbox(target, data)
                local count = 0
                for _ in pairs(selectedParts) do count += 1 end
                Fluent:Notify({ Title = "Hitbox Selector", Content = "Selected - " .. count .. " object(s) active", Duration = 2 })
            end
        end)
    end

    local function stopSelector()
        if mouseConn then mouseConn:Disconnect() mouseConn = nil end
        if inputConn then inputConn:Disconnect() inputConn = nil end
        if hoverBox then hoverBox:Destroy() hoverBox = nil end
        hoveredPart = nil
    end

    HitboxTab:AddToggle("HitboxSelector", {
        Title = "Hitbox Selector",
        Default = false,
        Callback = function(value)
            selectorEnabled = value
            if value then
                startSelector()
                Fluent:Notify({ Title = "Hitbox Selector", Content = "Click any object to expand its hitbox", Duration = 3 })
            else
                stopSelector()
                Fluent:Notify({ Title = "Hitbox Selector", Content = "Selector off - hitboxes preserved", Duration = 2 })
            end
        end,
    })

addNumericInput(HitboxTab, "expandX", {
    Title = "Expand X",
    Min = 0, Max = 10,
    Increment = 0.1,
    Rounding = 1,
    Default = 0,
    Callback = function(val)
        expandX = val
        updateAllHitboxes()
    end,
})

addNumericInput(HitboxTab, "expandY", {
    Title = "Expand Y",
    Min = 0, Max = 10,
    Increment = 0.1,
    Rounding = 1,
    Default = 0,
    Callback = function(val)
        expandY = val
        updateAllHitboxes()
    end,
})

addNumericInput(HitboxTab, "expandZ", {
    Title = "Expand Z",
    Min = 0, Max = 10,
    Increment = 0.1,
    Rounding = 1,
    Default = 0,
    Callback = function(val)
        expandZ = val
        updateAllHitboxes()
    end,
})

    HitboxTab:AddButton({
        Title = "Clear all highlights",
        Callback = function()
            clearAllHighlights()
            Fluent:Notify({ Title = "Hitbox Selector", Content = "All highlights removed", Duration = 2 })
        end,
    })

    HitboxTab:AddButton({
        Title = "Clear all custom hitboxes",
        Callback = function()
            local count = clearAllHitboxes()
            Fluent:Notify({ Title = "Hitbox Selector", Content = count .. " custom hitbox(es) cleared", Duration = 2 })
        end,
    })
end)

HitboxTab:AddParagraph({ Title = "Player Collision Proxy", Content = "" })
pcall(function()

    local Players    = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local lp         = Players.LocalPlayer

    local proxies     = {}
    local syncConn    = nil
    local addedConn   = nil
    local charConns   = {}
    local proxyExpand = 0
    local enabled     = false

    local function makeProxy(charPart)
        if proxies[charPart] then return end
        if not charPart or not charPart.Parent then return end
        local proxy        = Instance.new("Part")
        proxy.Name         = "PlayerCollisionProxy"
        proxy.Size         = charPart.Size + Vector3.new(proxyExpand, proxyExpand, proxyExpand)
        proxy.CFrame       = charPart.CFrame
        proxy.Transparency = 1
        proxy.CanCollide   = true
        proxy.CanQuery     = false
        proxy.CanTouch     = false
        proxy.CastShadow   = false
        proxy.Anchored     = true
        pcall(function()
            proxy.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition
        end)
        proxy.Parent       = workspace
        proxies[charPart]  = proxy
    end

    local function removeProxy(charPart)
        local proxy = proxies[charPart]
        if proxy and proxy.Parent then proxy:Destroy() end
        proxies[charPart] = nil
    end

    local function buildForCharacter(char)
        task.wait(0.1)
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then makeProxy(part) end
        end
        char.DescendantAdded:Connect(function(d)
            if d:IsA("BasePart") then makeProxy(d) end
        end)
        char.DescendantRemoving:Connect(function(d)
            if d:IsA("BasePart") then removeProxy(d) end
        end)
    end

    local function clearAllProxies()
        for _, proxy in pairs(proxies) do
            if proxy and proxy.Parent then proxy:Destroy() end
        end
        proxies = {}
    end

    local function startSyncLoop()
        if syncConn then return end
        syncConn = RunService.Heartbeat:Connect(function()
            for charPart, proxy in pairs(proxies) do
                if charPart and charPart.Parent and proxy and proxy.Parent then
                    proxy.CFrame = charPart.CFrame
                    proxy.Size   = charPart.Size + Vector3.new(proxyExpand, proxyExpand, proxyExpand)
                else
                    if proxy and proxy.Parent then proxy:Destroy() end
                    proxies[charPart] = nil
                end
            end
        end)
    end

    local function stopSyncLoop()
        if syncConn then syncConn:Disconnect() syncConn = nil end
    end

    local function enableProxies()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= lp and player.Character then
                task.spawn(buildForCharacter, player.Character)
            end
        end
        addedConn = Players.PlayerAdded:Connect(function(player)
            if player == lp then return end
            charConns[player] = player.CharacterAdded:Connect(function(char)
                task.spawn(buildForCharacter, char)
            end)
        end)
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= lp then
                charConns[player] = player.CharacterAdded:Connect(function(char)
                    task.spawn(buildForCharacter, char)
                end)
            end
        end
        startSyncLoop()
        Fluent:Notify({
            Title    = "Player Collision Proxy",
            Content  = "Enabled",
            Duration = 3,
        })
    end

    local function disableProxies()
        stopSyncLoop()
        if addedConn then addedConn:Disconnect() addedConn = nil end
        for _, conn in pairs(charConns) do conn:Disconnect() end
        charConns = {}
        clearAllProxies()
        Fluent:Notify({
            Title    = "Player Collision Proxy",
            Content  = "Disabled",
            Duration = 2,
        })
    end

    local function updateProxySizes()
        for charPart, proxy in pairs(proxies) do
            if charPart and charPart.Parent and proxy and proxy.Parent then
                proxy.Size = charPart.Size + Vector3.new(proxyExpand, proxyExpand, proxyExpand)
            end
        end
    end

    HitboxTab:AddToggle("HBProxyEnabled", {
        Title = "Player Collision Proxy",
        Default = false,
        Callback     = function(v)
            enabled = v
            if v then enableProxies() else disableProxies() end
        end,
    })

    addNumericInput(HitboxTab, "proxySizeExpand", {
        Title = "Proxy Size Expand",
        Min = 0, Max = 5,
        Increment    = 0.1,
        Rounding     = 1,
        Suffix       = "studs",
        Default = 0,
        Callback     = function(val)
            proxyExpand = val
            updateProxySizes()
        end,
    })

    HitboxTab:AddButton({
        Title = "Rebuild Proxies",
        Callback = function()
            if not enabled then
                Fluent:Notify({
                    Title    = "Player Collision Proxy",
                    Content  = "Enable the toggle first",
                    Duration = 2,
                })
                return
            end
            clearAllProxies()
            stopSyncLoop()
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= lp and player.Character then
                    task.spawn(buildForCharacter, player.Character)
                end
            end
            startSyncLoop()
            task.wait(0.3)
            local count = 0
            for _ in pairs(proxies) do count += 1 end
            Fluent:Notify({
                Title    = "Rebuild",
                Content  = "Done - " .. count .. " proxy parts active",
                Duration = 2,
            })
        end,
    })

end)

HitboxTab:AddParagraph({ Title = "Object picker & changer", Content = "" })
pcall(function()
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local lp         = Players.LocalPlayer
local mouse      = lp:GetMouse()
local cam        = workspace.CurrentCamera

local selectedParts  = {}
local hoveredParts   = {}
local selectionBoxes = {}
local hoverBoxes     = {}
local hoverConn      = nil
local clickConn      = nil
local originalStates = {}
local pickerActive   = false

local cfg = {
    CanCollide        = false,
    CanTouch          = false,
    CanQuery          = false,
    CollisionFidelity = Enum.CollisionFidelity.Default,
    CollisionGroup    = "Default",
}

local function getParts(inst)
    local t = {}
    if inst:IsA("BasePart") then
        t[1] = inst
    else
        for _, d in ipairs(inst:GetDescendants()) do
            if d:IsA("BasePart") then t[#t+1] = d end
        end
    end
    return t
end

local partCache = {}
local cacheConn = nil

local function buildCache()
    partCache = {}
    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            partCache[#partCache+1] = part
        end
    end
end

local function startCache()
    buildCache()
    cacheConn = workspace.DescendantAdded:Connect(function(d)
        if d:IsA("BasePart") then
            partCache[#partCache+1] = d
        end
    end)
end

local function stopCache()
    if cacheConn then cacheConn:Disconnect() cacheConn = nil end
    partCache = {}
end

local function rayTarget()
    local ray = cam:ScreenPointToRay(mouse.X, mouse.Y)
    local origin = ray.Origin
    local unitDir = ray.Direction.Unit

    local bestPart = nil
    local bestDist = math.huge

    for _, part in ipairs(partCache) do
        if part and part.Parent and not part:IsDescendantOf(lp.Character) then
            local toCenter = part.Position - origin
            local along = toCenter:Dot(unitDir)
            if along > 0.5 then
                local closest = origin + unitDir * along
                local diff = closest - part.Position
                local cf = part.CFrame
                local lx = math.abs(diff:Dot(cf.RightVector))
                local ly = math.abs(diff:Dot(cf.LookVector))
                local lz = math.abs(diff:Dot(cf.UpVector))
                if lx <= part.Size.X*0.5 and ly <= part.Size.Z*0.5 and lz <= part.Size.Y*0.5 then
                    if along < bestDist then
                        bestDist = along
                        bestPart = part
                    end
                end
            end
        end
    end

    return bestPart
end

local function makeBox(part, color, alpha)
    local b = Instance.new("SelectionBox")
    b.Color3              = color
    b.LineThickness       = 0.05
    b.SurfaceColor3       = color
    b.SurfaceTransparency = alpha
    b.Adornee             = part
    b.Parent              = workspace
    return b
end

local function destroyList(list)
    for i = #list, 1, -1 do
        pcall(function() list[i]:Destroy() end)
        list[i] = nil
    end
end

local function clearHover()
    destroyList(hoverBoxes)
    hoveredParts = {}
end

local function clearSelection()
    destroyList(selectionBoxes)
    selectedParts = {}
end

local function applySettings()
    if #selectedParts == 0 then return end
    for _, p in ipairs(selectedParts) do
        pcall(function()
            p.CanCollide        = cfg.CanCollide
            p.CanTouch          = cfg.CanTouch
            p.CanQuery          = cfg.CanQuery
            p.CollisionFidelity = cfg.CollisionFidelity
            p.CollisionGroup    = cfg.CollisionGroup
        end)
    end
end

local function saveState(parts)
    for _, p in ipairs(parts) do
        if not originalStates[p] then
            originalStates[p] = {
                CanCollide        = p.CanCollide,
                CanTouch          = p.CanTouch,
                CanQuery          = p.CanQuery,
                CollisionFidelity = p.CollisionFidelity,
                CollisionGroup    = p.CollisionGroup,
            }
        end
    end
end

local function doSelect(inst)
    local parts = getParts(inst)
    if #parts == 0 then return end
    saveState(parts)
    for _, p in ipairs(parts) do
        local alreadySelected = false
        for _, sp in ipairs(selectedParts) do
            if sp == p then alreadySelected = true break end
        end
        if not alreadySelected then
            selectedParts[#selectedParts+1] = p
            selectionBoxes[#selectionBoxes+1] = makeBox(p, Color3.fromRGB(0, 170, 255), 0.75)
        end
    end
    applySettings()
    Fluent:Notify({
        Title    = "Selected",
        Content  = inst.Name .. " · " .. #selectedParts .. " total part(s)",
        Duration = 2,
    })
end

local function doHover(inst)
    local parts = getParts(inst)
    if #parts == 0 then clearHover() return end
    if hoveredParts[1] == parts[1] then return end
    clearHover()
    hoveredParts = parts
    for _, p in ipairs(parts) do
        hoverBoxes[#hoverBoxes+1] = makeBox(p, Color3.fromRGB(255, 255, 255), 0.85)
    end
end

local function startPicker()
    pickerActive = true
    startCache()
    hoverConn = RunService.RenderStepped:Connect(function()
        local t = rayTarget()
        if t then doHover(t) else clearHover() end
    end)
    clickConn = UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            local t = rayTarget()
            if t then doSelect(t) end
        end
    end)
end

local function stopPicker()
    pickerActive = false
    if hoverConn then hoverConn:Disconnect() hoverConn = nil end
    if clickConn then clickConn:Disconnect() clickConn = nil end
    stopCache()
    clearHover()
end

HitboxTab:AddToggle("HBPicker", {
    Title = "Object Picker",
    Default = false,
    Callback     = function(v)
        if v then startPicker() else stopPicker() clearSelection() end
    end,
})

HitboxTab:AddToggle("HBCanCollide", {
    Title = "CanCollide",
    Default = false,
    Callback     = function(v)
        cfg.CanCollide = v
        applySettings()
    end,
})

HitboxTab:AddToggle("HBCanTouch", {
    Title = "CanTouch",
    Default = false,
    Callback     = function(v)
        cfg.CanTouch = v
        applySettings()
    end,
})

HitboxTab:AddToggle("HBCanQuery", {
    Title = "CanQuery",
    Default = false,
    Callback     = function(v)
        cfg.CanQuery = v
        applySettings()
    end,
})

HitboxTab:AddDropdown("collisionfidelity", {
    Title = "CollisionFidelity",
    Values = {
        "Default",
        "Box",
        "Hull",
        "PreciseConvexDecomposition",
        "Scalable",
    },
    Default = "Default",
    Multi = false,
    Callback = function(selected)
        local map = {
            ["Default"]                   = Enum.CollisionFidelity.Default,
            ["Box"]                       = Enum.CollisionFidelity.Box,
            ["Hull"]                      = Enum.CollisionFidelity.Hull,
            ["PreciseConvexDecomposition"] = Enum.CollisionFidelity.PreciseConvexDecomposition,
            ["Scalable"]                  = Enum.CollisionFidelity.Scalable,
        }
        local fidelity = map[selected[1]]
        if not fidelity then return end
        cfg.CollisionFidelity = fidelity
        for _, p in ipairs(selectedParts) do
            pcall(function()
                p.CollisionFidelity = fidelity
            end)
        end
    end,
})

HitboxTab:AddInput("collisiongroup", {
    Title = "CollisionGroup",
    Placeholder = "Default",
    ClearOnFocus = false,
    Callback         = function(text)
        if text == "" then text = "Default" end
        cfg.CollisionGroup = text
        for _, p in ipairs(selectedParts) do
            pcall(function()
                p.CollisionGroup = text
            end)
        end
    end,
})

HitboxTab:AddButton({
    Title = "Reset to Original",
    Callback = function()
        local n = 0
        for part, state in pairs(originalStates) do
            pcall(function()
                part.CanCollide = state.CanCollide
                part.CanTouch   = state.CanTouch
                part.CanQuery   = state.CanQuery
                part.CollisionFidelity = state.CollisionFidelity
                part.CollisionGroup    = state.CollisionGroup
            end)
            n = n + 1
        end
        originalStates = {}
        clearSelection()
        clearHover()
        Fluent:Notify({
            Title    = "Reset",
            Content  = n .. " part(s) restored",
            Duration = 2,
        })
    end,
})

HitboxTab:AddButton({
    Title = "Clear Selection",
    Callback = function()
        clearSelection()
        clearHover()
    end,
})
end)
end -- /do hitbox
do -- fly
FlyTab:AddParagraph({ Title = "Fly settings", Content = "" })
pcall(function()
local flyEnabled = false
local flyLoop = nil
local flySpeed = 100
local flyToggleObject = nil
local noclipEnabled = false
local noclipLoop = nil
local noclipToggleObject = nil
local noclipCharConn = nil

local function cleanupFly(char)
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hrp then
        for _, name in ipairs({"FlyVelocity", "FlyGyro"}) do
            local obj = hrp:FindFirstChild(name)
            if obj then obj:Destroy() end
        end
    end
    if hum then hum.PlatformStand = false end
end

local function setFly(state)
    flyEnabled = state

    if state then
        Fluent:Notify({ Title = "Fly", Content = "Enabled", Duration = 2 })
    else
        Fluent:Notify({ Title = "Fly", Content = "Disabled", Duration = 2 })
    end

    if state then
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end

        hum.PlatformStand = true

        for _, name in ipairs({"FlyVelocity", "FlyGyro"}) do
            local old = hrp:FindFirstChild(name)
            if old then old:Destroy() end
        end

        local bodyVel = Instance.new("BodyVelocity")
        bodyVel.Name = "FlyVelocity"
        bodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyVel.Velocity = Vector3.zero
        bodyVel.Parent = hrp

        local bodyGyro = Instance.new("BodyGyro")
        bodyGyro.Name = "FlyGyro"
        bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bodyGyro.P = 5e4
        bodyGyro.D = 1e3
        bodyGyro.CFrame = hrp.CFrame
        bodyGyro.Parent = hrp

        flyLoop = RunService.Heartbeat:Connect(function()
            local char2 = player.Character
            if not char2 then return end
            local hrp2 = char2:FindFirstChild("HumanoidRootPart")
            if not hrp2 then return end

            local cam = workspace.CurrentCamera
            local camCF = cam.CFrame
            local dir = Vector3.zero

            if UIS:IsKeyDown(Enum.KeyCode.W) then dir += camCF.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= camCF.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= camCF.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then dir += camCF.RightVector end

            local bv = hrp2:FindFirstChild("FlyVelocity")
            local bg = hrp2:FindFirstChild("FlyGyro")

            if bv then
                bv.Velocity = dir.Magnitude > 0 and dir.Unit * flySpeed or Vector3.zero
            end
            if bg then
                bg.CFrame = camCF
            end
        end)
    else
        if flyLoop then flyLoop:Disconnect(); flyLoop = nil end

        local char = player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hrp then
                for _, name in ipairs({"FlyVelocity", "FlyGyro"}) do
                    local obj = hrp:FindFirstChild(name)
                    if obj then obj:Destroy() end
                end
            end
            if hum then hum.PlatformStand = false end
        end
    end

    task.spawn(function()
        task.wait(0.05)
        syncToggle(flyToggleObject, state)
    end)
end

local function isPlayerCharacter(part)
    for _, p in ipairs(Players:GetPlayers()) do
        local char = p.Character
        if char and part:IsDescendantOf(char) then
            return true
        end
    end
    return false
end

local function setNoclip(state)
    noclipEnabled = state

    if state then
        local charParts = {}
        local charAddedConn = nil

        local function refreshCharParts()
            charParts = {}
            local char = player.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    table.insert(charParts, part)
                end
            end
        end

        refreshCharParts()

        charAddedConn = player.CharacterAdded:Connect(function()
            task.wait(0.1)
            refreshCharParts()
        end)

        noclipLoop = RunService.Stepped:Connect(function()
            for _, part in ipairs(charParts) do
                if part and part.Parent then
                    part.CanCollide = false
                end
            end
        end)

        noclipCharConn = charAddedConn

        Fluent:Notify({ Title = "Noclip", Content = "Enabled", Duration = 2 })
    else
        if noclipLoop then noclipLoop:Disconnect(); noclipLoop = nil end
        if noclipCharConn then noclipCharConn:Disconnect(); noclipCharConn = nil end

        local char = player.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end

        Fluent:Notify({ Title = "Noclip", Content = "Disabled", Duration = 2 })
    end

    task.spawn(function()
        task.wait(0.05)
        syncToggle(noclipToggleObject, state)
    end)
end

flyToggleObject = FlyTab:AddToggle("FlyTabToggle", {
    Title = "Fly",
    Default = false,
    Callback = function(value)
        if value == flyEnabled then return end
        setFly(value)
    end,
})

addNumericInput(FlyTab, "flySpeed", {
    Title = "Fly Speed",
    Min = 10, Max = 1000,
    Increment = 10,
    Rounding = 0,
    Suffix = "",
    Default = 300,
    Callback = function(value)
        flySpeed = value
    end,
})

noclipToggleObject = FlyTab:AddToggle("FlyTabNoclip", {
    Title = "Noclip",
    Default = false,
    Callback = function(value)
        if value == noclipEnabled then return end
        setNoclip(value)
    end,
})

FlyTab:AddKeybind("FlyKeybind", {
    Title = "Fly Keybind",
    Default = "None",
    CurrentKeybind = "None",
    HoldToInteract = false,
    Callback = function()
        setFly(not flyEnabled)
    end,
})

FlyTab:AddKeybind("NoclipKeybind", {
    Title = "Noclip Keybind",
    Default = "None",
    CurrentKeybind = "None",
    HoldToInteract = false,
    Callback = function()
        setNoclip(not noclipEnabled)
    end,
})
end)

local Running = false
local Frames = {}
local TimeStart = tick()
local loopEnabled = false
local currentTASLoop = nil

local Player = game:GetService("Players").LocalPlayer
local getChar = function()
    local Character = Player.Character
    if Character then
        return Character
    else
        Player.CharacterAdded:Wait()
        return getChar()
    end
end

local StartRecord = function()
    Frames = {}
    Running = true
    TimeStart = tick()
    while Running == true do
        game:GetService("RunService").Heartbeat:wait()
        local Character = getChar()
        table.insert(Frames, {
            Character.HumanoidRootPart.CFrame,
            Character.Humanoid:GetState().Value,
            tick() - TimeStart
        })
    end
end

local StopRecord = function()
    Running = false
end

local PlayTAS
PlayTAS = function()
    if #Frames == 0 then return end
    if currentTASLoop then
        currentTASLoop:Disconnect()
        currentTASLoop = nil
    end

    local Character = getChar()
    local TimePlay = tick()
    local FrameCount = #Frames
    local OldFrame = 1

    currentTASLoop = game:GetService("RunService").Heartbeat:Connect(function()
        local NewFrames = OldFrame + 60
        local CurrentTime = tick()

        if (CurrentTime - TimePlay) >= Frames[FrameCount][3] then
            if loopEnabled then
                TimePlay = tick()
                OldFrame = 1
                return
            else
                currentTASLoop:Disconnect()
                currentTASLoop = nil
                return
            end
        end

        for i = OldFrame, math.min(NewFrames, FrameCount) do
            local Frame = Frames[i]
            if Frame[3] <= CurrentTime - TimePlay then
                OldFrame = i
                Character.HumanoidRootPart.CFrame = Frame[1]
                Character.Humanoid:ChangeState(Frame[2])
            end
        end
    end)
end

end -- /do fly
do -- tas
TasTab:AddParagraph({ Title = "Settings", Content = "" })

TasTab:AddButton({
    Title = "Start Recording",
    Callback = StartRecord,
})

TasTab:AddButton({
    Title = "Stop Recording",
    Callback = StopRecord,
})

TasTab:AddButton({
    Title = "Play",
    Callback = PlayTAS,
})

TasTab:AddButton({
    Title = "Stop Loop Playback",
    Callback = function()
        if currentTASLoop then
            currentTASLoop:Disconnect()
            currentTASLoop = nil
        end
    end,
})

TasTab:AddKeybind("TASStartRecording", {
    Title = "Start Recording",
    Default = "None",
    CurrentKeybind = "",
    HoldToInteract = false,
    Callback = StartRecord,
})

TasTab:AddKeybind("TASStopRecording", {
    Title = "Stop Recording",
    Default = "None",
    CurrentKeybind = "",
    HoldToInteract = false,
    Callback = StopRecord,
})

TasTab:AddKeybind("TASPlay", {
    Title = "Play",
    Default = "None",
    CurrentKeybind = "",
    HoldToInteract = false,
    Callback = PlayTAS,
})

TasTab:AddToggle("TASLoop", {
    Title = "Loop Playback",
    Default = false,
    Callback = function(value)
        loopEnabled = value
    end,
})

-- Cores dos botoes flutuantes (aba Config)
pcall(function()
    ConfigTab:AddParagraph({
        Title = "Button Colors",
        Content = "Change the color of the floating buttons.",
    })

    for _, def in ipairs({
        { id = "AutoJump",   title = "Auto Jump Button Color" },
        { id = "AutoCrouch", title = "Auto Crouch Button Color" },
        { id = "LagSwitch",  title = "Freeze Button Color" },
        { id = "InfiniteSlide", title = "Infinite Slide Button Color" },
        { id = "FpsCounter", title = "FPS Counter Color" },
        { id = "EmoteMacro", title = "Emote Macro Button Color" },
        { id = "Uncrouch", title = "Uncrouch Button Color" },
    }) do
        ConfigTab:AddColorpicker(def.id .. "ButtonColor", {
            Title = def.title,
            Default = _G.__HXButtonDefaults[def.id],
            Callback = function(color)
                _G.__HXButtonColors[def.id] = color
                local btn = _G.__HXButtons[def.id]
                if btn then btn:SetColor(color) end
            end,
        })
    end
end)

-- Fluent SaveManager & InterfaceManager setup
local managerSetupOk, managerSetupError = pcall(function()
    SaveManager:SetLibrary(Fluent)
    InterfaceManager:SetLibrary(Fluent)

    SaveManager:IgnoreThemeSettings()

    InterfaceManager:SetFolder("Evaware")
    SaveManager:SetFolder("Evaware/configs")

    InterfaceManager:BuildInterfaceSection(SettingsTab)
    SaveManager:BuildConfigSection(ConfigTab)
end)

if not managerSetupOk then
    SettingsTab:AddParagraph({
        Title = "Settings unavailable",
        Content = tostring(managerSetupError),
    })
    ConfigTab:AddParagraph({
        Title = "Config unavailable",
        Content = tostring(managerSetupError),
    })
end

Window:SelectTab(1)

if managerSetupOk then
    pcall(function()
        SaveManager:LoadAutoloadConfig()
    end)
end

-- === HALLOWEEN THEME OVERRIDE ===
-- Runs after LoadAutoloadConfig so no saved theme can stomp it.
-- No DescendantAdded hook — that fires hundreds of times/sec and causes lag.
-- Three timed full-sweeps instead: catches late-building elements without a hot loop.
task.spawn(function()
    -- resolve GUI root once
    local guiRoot
    pcall(function()
        if typeof(Fluent.GUI) == "Instance" then guiRoot = Fluent.GUI end
    end)
    if not guiRoot then pcall(function() guiRoot = gethui() end) end
    if not guiRoot then guiRoot = game:GetService("CoreGui") end

    -- Try Fluent's own theme API first (named theme was registered above)
    pcall(function()
        if type(Fluent.SetTheme)       == "function" then Fluent:SetTheme("Halloween")
        elseif type(Fluent.ApplyTheme) == "function" then Fluent:ApplyTheme("Halloween")
        end
    end)

    local function paintAll(root)
        if not root then return end
        local ok, desc = pcall(function() return root:GetDescendants() end)
        if not ok then return end
        for _, d in ipairs(desc) do
            pcall(function()
                if d:IsA("Frame") or d:IsA("ScrollingFrame") then
                    if d.BackgroundTransparency < 0.9 then
                        local bc = d.BackgroundColor3
                        local bright = (bc.R + bc.G + bc.B) * 255 / 3
                        if     bright < 45  then d.BackgroundColor3 = HW.Background
                        elseif bright < 85  then d.BackgroundColor3 = HW.ElementBackground
                        elseif bright < 135 then d.BackgroundColor3 = HW.Tab
                        elseif bright < 180 then d.BackgroundColor3 = HW.TabSelected
                        end
                    end
                    if d.BorderSizePixel > 0 then
                        d.BorderColor3 = HW.ElementStroke
                    end
                end

                if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                    local tc = d.TextColor3
                    local bright = (tc.R + tc.G + tc.B) * 255 / 3
                    if     bright > 190 then d.TextColor3 = HW.TextPrimary
                    elseif bright >  80 then d.TextColor3 = HW.TextSecondary
                    end
                    if d:IsA("TextButton") and d.BackgroundTransparency < 0.7 then
                        local bc = d.BackgroundColor3
                        if (bc.R + bc.G + bc.B) * 255 / 3 > 160 then
                            d.BackgroundColor3 = HW.Accent
                            d.TextColor3 = Color3.fromRGB(255, 255, 255)
                        end
                    end
                end

                if d:IsA("UIStroke") then
                    d.Color = HW.ElementStroke
                end

                if d:IsA("ImageLabel") or d:IsA("ImageButton") then
                    local ic = d.ImageColor3
                    if ic.R > 0.78 and ic.G > 0.78 and ic.B > 0.78 then
                        d.ImageColor3 = HW.Accent
                    end
                end

                -- title label orange branding
                if d:IsA("TextLabel") and d.Text == "Hyperion Hub X" then
                    d.TextColor3 = HW.Accent
                end
            end)
        end
    end

    -- Sweep 1 — right after config loads (catches most elements)
    task.wait(0.15)
    paintAll(guiRoot)

    -- Sweep 2 — half a second in (catches deferred Fluent elements)
    task.wait(0.5)
    paintAll(guiRoot)

    -- Sweep 3 — 2 seconds in (catches anything lazy-built on tab switch etc.)
    task.wait(1.5)
    paintAll(guiRoot)

    -- Done. No continuous hook. No per-frame work. Zero ongoing cost.
end)
-- === END HALLOWEEN THEME OVERRIDE ===

end -- /do tas