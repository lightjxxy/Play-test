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

    local okSource, source
    if _HX_Prefetched and type(_HX_Prefetched[url]) == "string" then
        okSource, source = true, _HX_Prefetched[url]
    else
        okSource, source = pcall(getRemoteSource, url)
    end
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

-- Download all UI modules in parallel (much faster than one-by-one)
_HX_Prefetched = {}
do
	local base = "https://raw.githubusercontent.com/StyearX/Script/refs/heads/main/Phantomwrym/Fluent-modded/"
	local names = { "Main.lua", "SaveManager.lua", "FloatingButtonManager.lua", "InterfaceManager.lua" }
	local pending = #names
	for _, n in ipairs(names) do
		task.spawn(function()
			local ok, src = pcall(getRemoteSource, base .. n)
			if ok and type(src) == "string" then _HX_Prefetched[base .. n] = src end
			pending -= 1
		end)
	end
	local t0 = os.clock()
	while pending > 0 and os.clock() - t0 < 20 do task.wait() end
end

local Fluent = loadRemote("https://raw.githubusercontent.com/StyearX/Script/refs/heads/main/Phantomwrym/Fluent-modded/Main.lua", "Fluent/Main.lua")
local SaveManager = loadRemote("https://raw.githubusercontent.com/StyearX/Script/refs/heads/main/Phantomwrym/Fluent-modded/SaveManager.lua", "Fluent/SaveManager.lua")
local FBM = loadRemote("https://raw.githubusercontent.com/StyearX/Script/refs/heads/main/Phantomwrym/Fluent-modded/FloatingButtonManager.lua", "Fluent/FloatingButtonManager.lua")
local InterfaceManager = loadRemote("https://raw.githubusercontent.com/StyearX/Script/refs/heads/main/Phantomwrym/Fluent-modded/InterfaceManager.lua", "Fluent/InterfaceManager.lua")

if _G.HyperionHubXIsAlreadyRunning then
	Fluent:Notify({
		Title = "Hyperion Hub X",
		Content = "Script is already running!",
		Duration = 5
	})

	return
end

_G.HyperionHubXIsAlreadyRunning = true

-- PC / Mobile detection and adaptive window size
local HX_UIS = game:GetService("UserInputService")
local HX_IsMobile = HX_UIS.TouchEnabled and not HX_UIS.KeyboardEnabled
local HX_View = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1280, 720)
local HX_Size = HX_IsMobile
	and UDim2.fromOffset(math.clamp(HX_View.X * 0.72, 380, 520), math.clamp(HX_View.Y * 0.78, 230, 340))
	or UDim2.fromOffset(580, 460)

local Window = Fluent:CreateWindow({
	Title = "Hyperion Hub X | Legacy",
	SubTitle = "Made by Nymmz and Lucaswyrm",
	TabWidth = HX_IsMobile and 120 or 160,
	Size = HX_Size,
	Acrylic = not HX_IsMobile, -- blur is heavy on phones
	Theme = "Dark",
	MinimizeKey = Enum.KeyCode.LeftControl, -- PC only; mobile uses the logo button
})

local executorName = "Unknown"
pcall(function()
	executorName = identifyexecutor()
end)

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
        table.insert(roots, game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"))

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
    end

    makePill(platform, Color3.fromRGB(240, 100, 50), Color3.fromRGB(255, 255, 255), 1)
    makePill(tostring(executorName), Color3.fromRGB(250, 220, 90), Color3.fromRGB(45, 35, 10), 2)

    if parent:FindFirstChildOfClass("UIListLayout") then
        container.Parent = parent
    else
        -- Sem layout automatico: posiciona logo depois do texto.
        container.AnchorPoint = Vector2.new(0, 0)
        container.Position = UDim2.new(0, label.AbsolutePosition.X - parent.AbsolutePosition.X + label.AbsoluteSize.X + 8, 0, 0)
        container.Parent = parent
    end
end)


-- === TITLE STYLE + OPEN ANIMATION ===
task.spawn(function()
	local TS = game:GetService("TweenService")
	local function findLabel(txt)
		local roots = {}
		if type(Fluent) == "table" and typeof(Fluent.GUI) == "Instance" then table.insert(roots, Fluent.GUI) end
		pcall(function() if gethui then table.insert(roots, gethui()) end end)
		table.insert(roots, game:GetService("CoreGui"))
		for _, root in ipairs(roots) do
			local ok, d = pcall(function() return root:GetDescendants() end)
			if ok then
				for _, o in ipairs(d) do
					if o:IsA("TextLabel") and o.Text == txt then return o end
				end
			end
		end
	end

	local title
	for _ = 1, 8 do
		title = findLabel("Hyperion Hub X | Legacy")
		if title then break end
		task.wait(0.4)
	end
	if title then
		pcall(function()
			title.Font = Enum.Font.GothamBlack
			title.TextColor3 = Color3.fromRGB(255, 255, 255)
			local g = Instance.new("UIGradient")
			g.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(110, 225, 255)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(175, 120, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 225, 255)),
			})
			g.Parent = title
			task.spawn(function()
				while title.Parent do
					g.Offset = Vector2.new(math.sin(os.clock() * 1.2) * 0.4, 0)
					game:GetService("RunService").RenderStepped:Wait()
				end
			end)
		end)
	end
	local sub = findLabel("Made by L1ght and LucasWyrm")
	if sub then pcall(function() sub.Font = Enum.Font.GothamMedium end) end

	-- Open animation: scale + slide + glowing border (plays on every open)
	local root = Window.Root
	if typeof(root) ~= "Instance" then return end
	local scale = Instance.new("UIScale")
	scale.Parent = root

	local glow = Instance.new("UIStroke")
	glow.Thickness = 3
	glow.Color = Color3.fromRGB(255, 255, 255)
	glow.Transparency = 1
	glow.Parent = root
	local glowGrad = Instance.new("UIGradient")
	glowGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(110, 225, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(175, 120, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 225, 255)),
	})
	glowGrad.Parent = glow

	local playing = 0
	local function playOpen()
		playing += 1
		local my = playing
		local base = root.Position
		scale.Scale = 0.72
		root.Position = base + UDim2.fromOffset(0, 46)
		glow.Transparency = 0
		glow.Thickness = 5

		TS:Create(scale, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		TS:Create(root, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = base }):Play()
		TS:Create(glow, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Transparency = 1, Thickness = 1 }):Play()
		task.spawn(function()
			local t0 = os.clock()
			while playing == my and os.clock() - t0 < 0.9 do
				glowGrad.Rotation = ((os.clock() - t0) * 420) % 360
				game:GetService("RunService").RenderStepped:Wait()
			end
		end)
	end
	playOpen()
	root:GetPropertyChangedSignal("Visible"):Connect(function()
		if root.Visible then playOpen() end
	end)
end)

-- Tabs (original legacy names, Info tab removed)
local Tabs = {
	Info = Window:AddTab({ Title = "| Info", Icon = "info" }),
	Main = Window:AddTab({ Title = "| Main", Icon = "swords" }),
	Combat = Window:AddTab({ Title = "| Combat", Icon = "crosshair" }),
	Misc = Window:AddTab({ Title = "| Misc", Icon = "layers" }),
	Visual = Window:AddTab({ Title = "| Visual", Icon = "eye" }),
	Model = Window:AddTab({ Title = "| Object Spawner", Icon = "box" }),
	Settings = Window:AddTab({ Title = "| Configuration", Icon = "settings" }),
	Folder = Window:AddTab({ Title = "| Macro", Icon = "keyboard" }),
	Extension = Window:AddTab({ Title = "| Optimization", Icon = "zap" }),
}

-- === INFO TAB ===
do
    Tabs.Info:AddParagraph({
        Title = "Owner Socials",
        Content = "Click the buttons below to visit the owners' TikTok pages.",
    })

    Tabs.Info:AddButton({
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

    Tabs.Info:AddButton({
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

-- PC only: every toggle gets its own keybind row right below it.
-- Pick a key once and it flips that function on/off from the keyboard.
if not HX_IsMobile then
	local wrapped = {}
	for _, tab in pairs(Tabs) do
		if not wrapped[tab] and type(tab.AddToggle) == "function" and type(tab.AddKeybind) == "function" then
			wrapped[tab] = true
			local originalAddToggle = tab.AddToggle
			tab.AddToggle = function(self, idx, cfg)
				local toggle = originalAddToggle(self, idx, cfg)
				pcall(function()
					self:AddKeybind(tostring(idx) .. "_Key", {
						Title = ((cfg and (cfg.Title or cfg.Name)) or tostring(idx)) .. " Keybind",
						Default = "None",
						CurrentKeybind = "None",
						HoldToInteract = false,
						Callback = function()
							local opt = Fluent.Options[idx]
							if opt and opt.SetValue then
								opt:SetValue(not opt.Value)
							end
						end,
					})
				end)
				return toggle
			end
		end
	end
end
Tabs.Info = Tabs.Settings -- credit line lives in Configuration now
local HXTabs = { Settings = Tabs.Settings, Config = Tabs.Settings }

local Options = Fluent.Options

-- Services

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService('Lighting')
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local CAS = game:GetService("ContextActionService")

-- Optimize (1)

local function GetAutoDuration()
	local dt = RunService.RenderStepped:Wait()
	local fps = 1 / dt

	local duration = 900 / math.clamp(fps, 5, 900)
	return math.clamp(duration, 1, 9)
end

local Duration = GetAutoDuration()

local openGui
do
local player = LocalPlayer
local UIS = UserInputService
-- === HYPERION X LOGO ===
local imageUrl = "https://i.ibb.co/ZzjhCDRm/Screenshot-20260917-164338-Roblox.jpg"
local fileName = "HyperionHubX_Logo.jpg"
local customAssetUrl
local FALLBACK_ICON = "rbxassetid://139104323768501"

local assetLoader = getcustomasset or getsynasset
local logoRef = {}

local function applyLogoAsset()
    if assetLoader and isfile and isfile(fileName) then
        pcall(function()
            customAssetUrl = assetLoader(fileName)
        end)
        if customAssetUrl and logoRef.img then
            logoRef.img.Image = customAssetUrl
        end
    end
end

applyLogoAsset()
if not customAssetUrl and assetLoader and writefile and isfile then
    -- download in the background so the script does not wait for it
    task.spawn(function()
        pcall(function()
            local imageData = game:HttpGet(imageUrl)
            if imageData and #imageData > 0 then
                writefile(fileName, imageData)
            end
        end)
        applyLogoAsset()
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
logoRef.img = frontImage
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
    while openshit.Parent do
        local timeNow = os.clock()
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

        RunService.RenderStepped:Wait()
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
local extraFX = {}

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
    for _, fx in ipairs(extraFX) do
        fx.Visible = visible
    end
end


-- === EXTRA LOGO EFFECTS (same cyan/purple palette) ===
local CYAN = Color3.fromRGB(110, 225, 255)
local VIOLET = Color3.fromRGB(175, 120, 255)

-- Outer counter-rotating ring
local outerRing = Instance.new("Frame")
outerRing.Name = "OuterRing"
outerRing.Parent = mainopen
outerRing.AnchorPoint = Vector2.new(0.5, 0.5)
outerRing.Position = UDim2.new(0.5, 0, 0.5, 0)
outerRing.Size = UDim2.new(0, 82, 0, 82)
outerRing.BackgroundTransparency = 1
outerRing.ZIndex = 1
outerRing.Active = false
Instance.new("UICorner", outerRing).CornerRadius = UDim.new(1, 0)
local outerStroke = Instance.new("UIStroke")
outerStroke.Thickness = 1.5
outerStroke.Color = Color3.fromRGB(255, 255, 255)
outerStroke.Transparency = 0.35
outerStroke.Parent = outerRing
local outerGrad = Instance.new("UIGradient")
outerGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, CYAN),
    ColorSequenceKeypoint.new(0.5, VIOLET),
    ColorSequenceKeypoint.new(1, CYAN),
})
outerGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),
    NumberSequenceKeypoint.new(0.45, 0.9),
    NumberSequenceKeypoint.new(0.55, 0.9),
    NumberSequenceKeypoint.new(1, 0),
})
outerGrad.Parent = outerStroke
table.insert(extraFX, outerRing)

-- Soft shimmer sweeping across the icon
frontImage.ClipsDescendants = true
local shimmer = Instance.new("Frame")
shimmer.Name = "Shimmer"
shimmer.Parent = frontImage
shimmer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
shimmer.BorderSizePixel = 0
shimmer.Size = UDim2.new(1, 0, 1, 0)
shimmer.ZIndex = 5
shimmer.Active = false
local shimmerGrad = Instance.new("UIGradient")
shimmerGrad.Rotation = 25
shimmerGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.42, 1),
    NumberSequenceKeypoint.new(0.5, 0.72),
    NumberSequenceKeypoint.new(0.58, 1),
    NumberSequenceKeypoint.new(1, 1),
})
shimmerGrad.Parent = shimmer
table.insert(extraFX, shimmer)

-- Pulse rings expanding outward (staggered)
local pulseRings = {}
for i = 1, 2 do
    local ring = Instance.new("Frame")
    ring.Name = "PulseRing" .. i
    ring.Parent = mainopen
    ring.AnchorPoint = Vector2.new(0.5, 0.5)
    ring.Position = UDim2.new(0.5, 0, 0.5, 0)
    ring.Size = UDim2.new(0, 58, 0, 58)
    ring.BackgroundTransparency = 1
    ring.ZIndex = 1
    ring.Active = false
    Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
    local st = Instance.new("UIStroke")
    st.Thickness = 2
    st.Color = CYAN
    st.Transparency = 1
    st.Parent = ring
    pulseRings[i] = { ring = ring, stroke = st, offset = (i - 1) * 0.5 }
    table.insert(extraFX, ring)
end

task.spawn(function()
    while openshit.Parent do
        local t = os.clock()

        outerGrad.Rotation = -(t * 45) % 360
        shimmerGrad.Offset = Vector2.new(-1 + ((t * 0.5) % 2.2), 0)

        local mix = (math.sin(t * 1.4) + 1) / 2
        local tone = CYAN:Lerp(VIOLET, mix)
        aura.BackgroundColor3 = tone
        outerStroke.Color = tone

        for _, pr in ipairs(pulseRings) do
            local phase = ((t * 0.5) + pr.offset) % 1
            local size = 58 + phase * 46
            pr.ring.Size = UDim2.new(0, size, 0, size)
            pr.stroke.Color = tone
            pr.stroke.Transparency = 1 - (1 - phase) * 0.7
        end

        RunService.RenderStepped:Wait()
    end
end)

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

            pcall(playRipple)
            pcall(playLogoSound, logoClickSounds[math.random(#logoClickSounds)])
        end
    end)
end)

openGui = openshit
end

local SizeBackMulti = 0.1

if not getgenv().ButtonGradients then
	getgenv().ButtonGradients = {
		Background = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 15, 15)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 30)),
		}),
		Stroke = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 170, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 0, 255)),
		}),
	}
end

local function MakeDraggable(topbarobject, object, locked)
	local Dragging = false
	local DragInput
	local DragStart
	local StartPosition

	local Holding = false
	local HoldTime = 1.0
	local MoveCancelThreshold = 6
	local HoldToken = 0

	object:SetAttribute("Locked", locked or false)

	local function Update(input)
		if object:GetAttribute("Locked") then return end
		local delta = input.Position - DragStart
		object.Position = UDim2.new(
			StartPosition.X.Scale,
			StartPosition.X.Offset + delta.X,
			StartPosition.Y.Scale,
			StartPosition.Y.Offset + delta.Y
		)
	end

	local function ToggleLock()
		local newState = not object:GetAttribute("Locked")
		object:SetAttribute("Locked", newState)

		Fluent:Notify({
			Title = newState and "Button Locked" or "Button Unlocked",
			Content = newState and "This button is now locked in place." or "This button can now be moved.",
			Duration = 2
		})
	end

	topbarobject.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		Dragging = not object:GetAttribute("Locked")
		Holding = true
		DragStart = input.Position
		StartPosition = object.Position

		HoldToken += 1
		local token = HoldToken

		task.delay(HoldTime, function()
			if Holding and token == HoldToken then
				ToggleLock()
			end
		end)

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				Dragging = false
				Holding = false
			end
		end)
	end)

	topbarobject.InputChanged:Connect(function(input)
		if not DragStart then return end

		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			if (input.Position - DragStart).Magnitude > MoveCancelThreshold then
				Holding = false
			end
			DragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == DragInput and Dragging then
			Update(input)
		end
	end)
end


-- FPS Counter

local fpsCounterGui = nil
local renderConnection = nil
local backgroundTask = nil
local strokeTask = nil

local function DestroyFpsCounter()
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end

	if fpsCounterGui then
		fpsCounterGui:Destroy()
		fpsCounterGui = nil
	end
end

local function CreateFpsCounter()
	DestroyFpsCounter()

	local folderPath = "CurrentPlayTime"
	local filePath = folderPath .. "/PlayTime.txt"
	local totalSavedSeconds = 0

	if typeof(makefolder) == "function" and typeof(isfolder) == "function" then
		if not isfolder(folderPath) then makefolder(folderPath) end
	end

	if typeof(readfile) == "function" and typeof(isfile) == "function" then
		if isfile(filePath) then
			totalSavedSeconds = tonumber(readfile(filePath)) or 0
		elseif typeof(writefile) == "function" then
			writefile(filePath, "0")
		end
	end

	local function SavePlayTime(seconds)
		if typeof(writefile) == "function" then
			pcall(function() writefile(filePath, tostring(math.floor(seconds))) end)
		end
	end

	fpsCounterGui = Instance.new("ScreenGui")
	fpsCounterGui.Name = "FPSCounter"
	fpsCounterGui.Parent = game:GetService("CoreGui")
	fpsCounterGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	fpsCounterGui.ResetOnSpawn = false

	local Frame = Instance.new("Frame")
	Frame.Parent = fpsCounterGui
	Frame.AnchorPoint = Vector2.new(0.5, 0)
	Frame.Size = UDim2.new(0, 420, 0, 26)
	Frame.Position = UDim2.new(0.5, 0, 0, 270)
	Frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Frame.BackgroundTransparency = 0.7

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = Frame

	local UiGradient = Instance.new("UIGradient")
	UiGradient.Color = getgenv().ButtonGradients and getgenv().ButtonGradients.Background or ColorSequence.new(Color3.fromRGB(15, 15, 15), Color3.fromRGB(30, 30, 30))
	UiGradient.Parent = Frame

	task.spawn(function()
		while fpsCounterGui and Frame.Parent do
			UiGradient.Rotation = (UiGradient.Rotation + 1) % 360
			if getgenv().ButtonGradients and getgenv().ButtonGradients.Background then
				UiGradient.Color = getgenv().ButtonGradients.Background
			end
			task.wait(0.03)
		end
	end)

	local UiStroke = Instance.new("UIStroke")
	UiStroke.Thickness = 1.5
	UiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	UiStroke.Color = Color3.new(1, 1, 1)
	UiStroke.Parent = Frame

	local UiStrokeGradient = Instance.new("UIGradient")
	UiStrokeGradient.Color = getgenv().ButtonGradients and getgenv().ButtonGradients.Stroke or ColorSequence.new(Color3.fromRGB(0, 170, 255), Color3.fromRGB(170, 0, 255))
	UiStrokeGradient.Rotation = 0
	UiStrokeGradient.Parent = UiStroke

	task.spawn(function()
		while fpsCounterGui and Frame.Parent do
			UiStrokeGradient.Rotation = (UiStrokeGradient.Rotation + 0.5) % 360
			if getgenv().ButtonGradients and getgenv().ButtonGradients.Stroke then
				UiStrokeGradient.Color = getgenv().ButtonGradients.Stroke
			end
			task.wait()
		end
	end)

	local label = Instance.new("TextLabel")
	label.Parent = Frame
	label.Size = UDim2.new(1, -12, 1, 0)
	label.Position = UDim2.new(0, 6, 0, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(240, 240, 240)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 11
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Text = "FPS -- | Ping -- | PlayTime 00h : 00m : 00s | GPU --ms | CPU --ms"

	if typeof(MakeDraggable) == "function" then
		MakeDraggable(Frame, Frame, true)
	end

	local function GetPing()
		local n = game:GetService("Stats"):FindFirstChild("Network")
		if not n then return 0 end
		local s = n:FindFirstChild("ServerStatsItem")
		if not s then return 0 end
		local p = s:FindFirstChild("Data Ping")
		if not p then return 0 end
		return math.floor(p:GetValue())
	end

	local function GetPerformanceStats()
		local perf = game:GetService("Stats"):FindFirstChild("PerformanceStats")
		local gpuMs, cpuMs = 0, 0
		if perf then
			local gpu = perf:FindFirstChild("GPU")
			local cpu = perf:FindFirstChild("CPU")
			if gpu then gpuMs = math.round(gpu:GetValue() * 1000) / 10 end
			if cpu then cpuMs = math.round(cpu:GetValue() * 1000) / 10 end
		end
		return gpuMs, cpuMs
	end

	local sessionStartTime = tick()
	local lastUpdateTime = sessionStartTime
	local lastSaveTime = sessionStartTime
	local frameCount = 0
	local previousText = ""

	renderConnection = game:GetService("RunService").RenderStepped:Connect(function()
		frameCount += 1
		local now = tick()
		local dt = now - lastUpdateTime

		if dt >= 0.5 then
			local fps = math.round(frameCount / dt)
			local currentSessionElapsed = now - sessionStartTime
			local totalPlayTime = totalSavedSeconds + currentSessionElapsed

			local h = math.floor(totalPlayTime / 3600)
			local m = math.floor((totalPlayTime % 3600) / 60)
			local s = math.floor(totalPlayTime % 60)

			local ping = GetPing()
			local gpu, cpu = GetPerformanceStats()

			local text = string.format("FPS %d  |  Ping %d ms  |  PlayTime %02dh : %02dm : %02ds  |  GPU %.1fms  |  CPU %.1fms", tonumber(fps) or 0, tonumber(ping) or 0, tonumber(h) or 0, tonumber(m) or 0, tonumber(s) or 0, tonumber(gpu) or 0, tonumber(cpu) or 0)
			if text ~= previousText then 
				label.Text = text 
				previousText = text 
			end

			lastUpdateTime = now
			frameCount = 0

			if now - lastSaveTime >= 5 then
				SavePlayTime(totalPlayTime)
				lastSaveTime = now
			end
		end
	end)
end

-- UNC Requirements

if not require then
	return print("UNC RESTRICTION MISSING: require(path) | PLEASE TRY OTHER EXECUTORS")
else
	print("Supported require()")
end

if not firetouchinterest  then
	return print("UNC RESTRICTION MISSING: firetouchinterest() | PLEASE TRY OTHER EXECUTORS")
else
	print("Supported firetouchinterest()")
end

if not setfpscap or setfpscap(900) then
	return print("UNC RESTRICTION MISSING: setfpscap() | PLEASE TRY OTHER EXECUTORS")
else
	print("Supported setfpscap()")
end

if game.Players then
	print("Advance Api")
else
	print("Common Api")
end

function CreateBillboardESP(Name, Part, Color, TextSize)
	if not Part or Part:FindFirstChild(Name) then return nil end

	local BillboardGui = Instance.new("BillboardGui")
	local TextLabel = Instance.new("TextLabel")
	local TextStroke = Instance.new("UIStroke")

	BillboardGui.Parent = Part
	BillboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	BillboardGui.Name = Name
	BillboardGui.AlwaysOnTop = true
	BillboardGui.LightInfluence = 1
	BillboardGui.Size = UDim2.new(0, 200, 0, 50)
	BillboardGui.StudsOffset = Vector3.new(0, 2.5, 0)
	BillboardGui.MaxDistance = 1000

	TextLabel.Parent = BillboardGui
	TextLabel.BackgroundTransparency = 1
	TextLabel.Size = UDim2.new(1, 0, 1, 0)
	TextLabel.TextScaled = false
	TextLabel.Font = Enum.Font.SourceSans
	TextLabel.TextSize = TextSize or 14
	TextLabel.TextColor3 = Color or Color3.fromRGB(255, 255, 255)

	TextStroke.Parent = TextLabel
	TextStroke.Thickness = 1
	TextStroke.Color = Color3.new(0, 0, 0)

	return BillboardGui
end

function UpdateBillboardESP(Name, Part, NameText, Color, TextSize, PartPosition)
	if not Part then return false end

	local esp = Part:FindFirstChild(Name)
	if esp and esp:FindFirstChildOfClass("TextLabel") then
		local label = esp:FindFirstChildOfClass("TextLabel")

		if Color then
			label.TextColor3 = Color
		end

		if TextSize then
			label.TextSize = TextSize
		end

		if PartPosition then
			local Pos 
			if typeof(PartPosition) == "Instance" and PartPosition:IsA("BasePart") then
				Pos = PartPosition.Position
			elseif typeof(PartPosition) == "Vector3" then
				Pos = PartPosition
			end

			if Pos then
				local distance = math.floor((Pos - Part.Position).Magnitude)
				local name = NameText or Part.Parent and Part.Parent.Name or Part.Name
				label.Text = string.format("%s - [ %d M ]", name, distance)
			end
		else
			local name = NameText or Part.Parent and Part.Parent.Name or Part.Name
			label.Text = name
		end    
		return true
	end
	return false
end

function DestroyBillboardESP(Name, Part)
	if not Part then return false end

	local esp = Part:FindFirstChild(Name)
	if esp then
		esp:Destroy()
		return true
	end

	return false
end

function CreateTracerESP(tracerTable, part, thickness, color)
	local tracer = Drawing.new("Line")
	tracer.Thickness = thickness or 2
	tracer.Color = color or Color3.fromRGB(255, 255, 255)
	tracer.Transparency = 1
	tracer.Visible = false
	tracerTable[part] = tracer
	return tracer
end

function UpdateTracerESP(tracerTable, part, color)
	local tracer = tracerTable[part]
	if not tracer then return end

	if typeof(part) ~= "Instance" then
		tracerTable[part] = nil
		return
	end

	if not part.Parent or not part:IsDescendantOf(workspace) then
		tracer.Visible = false
		DestroyTracerESP(tracerTable, part)
		return
	end

	local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(part.Position)  
	if onScreen then
		if color then tracer.Color = color end
		tracer.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y)
		tracer.To = Vector2.new(screenPos.X, screenPos.Y)
		tracer.Visible = true
	else
		tracer.Visible = false
	end
end

function DestroyTracerESP(tracerTable, part)
	if typeof(part) ~= "Instance" then
		tracerTable[part] = nil
		return
	end

	local tracer = tracerTable[part]
	if tracer then 
		if tracer.Remove then tracer:Remove() end
		tracerTable[part] = nil
	end 
end

function CreateHighlightESP(Name, Part, HighlightColor, OutlineColor, ShowHighlight)
	if not Part then return false end

	local Highlight = Instance.new("Highlight")
	Highlight.Name = Name
	Highlight.FillColor = HighlightColor or Color3.fromRGB(255, 255, 255)
	Highlight.OutlineColor = OutlineColor or Color3.fromRGB(0, 0, 0)

	if ShowHighlight then
		Highlight.FillTransparency = 0
	else
		Highlight.FillTransparency = 1
	end

	Highlight.OutlineTransparency = 0
	Highlight.Parent = Part

	return true
end

function UpdateHighlightESP(Name, Part, HighlightColor, OutlineColor, ShowHighlight)
	local Highlight = Part and Part:FindFirstChild(Name)

	if not Highlight or not Highlight:IsA("Highlight") then return false end

	if HighlightColor then Highlight.FillColor = HighlightColor end
	if OutlineColor then Highlight.OutlineColor = OutlineColor end

	if ShowHighlight ~= nil then
		Highlight.FillTransparency = ShowHighlight and 0 or 0.5
	end

	return true
end

function DestroyHighlightESP(Name, Part)
	local Highlight = Part and Part:FindFirstChild(Name)

	if Highlight and Highlight:IsA("Highlight") then
		Highlight:Destroy()
		return true
	end

	return false
end

-- Local Variables

local DFunctions = {}
local DConfiguration = {
	ESP = {
		Players = false,
		Nextbots = false,
		Tickets = false,
		Objective = false,
	},

	Tracers = {
		Players = false,
		Nextbots = false,
		Tickets = false,
		Objective = false,
	},

	Highlight = {
		Players = false,
		Nextbots = false,
		Tickets = false,
		Objective = false,
		OutlineOnly = false,
	},

	Boxes = {
		Players = false,
		Nextbots = false,
		Tickets = false,
		Objective = false,
	},

	Removals = {
		CameraShake = false,
		InvisibleWalls = false,
		DamageParts = false,
	},

	Main = {
		AntiAFK = true,
		AutoRespawn = false,
		RespawnType = "Spawnpoint",
		AutoWhistle = false,
		ShowTimer = false,
		AutoPlace = false,
		AnimTrack = nil,
		Fly = false,
		FlySpeed = 20,
		Noclip = false,
	},

	Combat = {
		AntiNextbot = false,
		AntiNextbotRange = 15,
		AntiNextbotType = "Spawn",
	},

	Misc = {
		PlayerAdjustment = {
			Default = {
				RealSpeed = 1500,
				RealJumpHeight = 3,
				AirStrafe = 182,
				GroundAcceleration = 1,
			},

			Update = {
				RealSpeed = 1500,
				RealJumpHeight = 3,
				AirStrafe = 182,
				GroundAcceleration = 1,
			},

			Saved = {
				RealSpeed = 1500,
				RealJumpHeight = 3,
				AirStrafe = 182,
				GroundAcceleration = 1,
			},

			Tick = {
				RealSpeed = 0,
				RealJumpHeight = 0,
				AirStrafe = 0,
				GroundAcceleration = 0,
			},

			Debounce = {
				RealSpeed = false,
				RealJumpHeight = false,
				AirStrafe = false,
				GroundAcceleration = false,
			},
		},

		Humanoids = {
			WalkspeedCF = false,
			OriginalJumpHeight = false,
			CF = 5,
			JP = 20,
		},

		Utilities = {
			GetCurrentSpeed = 0,

			BounceModification = {
				Enabled = false,
				DefaultBounce = 80,
				EmoteBounce = 120,
			},

			LagSwitch = {
				MSDelay = 200,
				Mode = "Normal",
			},
		},

		GameAutomation = {
			Macro = {
				SelectedPrimary = 1,
				FloatingButton = false,
				Keybind = false,
			},
		},

		MovementModification = {
			EmoteModification = {
				AggressiveEmoteDash = {
					Enabled = false,
					Type = "Blatant",
					Speed = 3000,
					Acceleration = -2,
				},

				ModifyEmote = {
					Enabled = true,
					TurnSpeed = 0.5,
				},
			},

			Efling = {
				Enabled = false,
				Power = 230,
				Cooldown = false,

				MinEdgeHeight = 4,
				MinEdgeWidth = 2,
				MinModelSize = 9,
			},

			Gravity = {
				FloatingButton = false,
				Keybind = false,
				Value = 10,
			},

			BHOP = {
				Enabled = false,
				FloatingButton = false,
				AutoAcceleration = false,
				MaxSpeed = 70,
				JumpButton = false,
				HipHeight1 = 0,
				HipHeight2 = 0,
				Type = "Acceleration",
				JumpType = "Simulated",
				Acceleration = -0.1,
				lastTick = 0.01,
			},
		},

		AntiLags = {
			Low = false,
			Moderate = false,
			High = false,
		},
	},

	Visual = {
		OriginalCosmetics = {
			Cosmetics1 = "",
			Cosmetics2 = "",
			Cosmetics3 = "",
			Cosmetics4 = "",
		},

		ModifyCosmetics = {
			Cosmetics1 = "",
			Cosmetics2 = "",
			Cosmetics3 = "",
			Cosmetics4 = "",
		},

		OriginalEmotes = {
			Emote1 = "",
			Emote2 = "",
			Emote3 = "",
			Emote4 = "",
			Emote5 = "",
			Emote6 = "",
		},

		ModifyEmotes = {
			Emote1 = "",
			Emote2 = "",
			Emote3 = "",
			Emote4 = "",
			Emote5 = "",
			Emote6 = "",
		},
	},

	Settings = {
		GuiScale = {
			Respawn = 0,
			AutoCarry = 0,
			InstantRevive = 0,
			UseCola = 0,
			AutoEmoteDash = 0,
			MacroButton1 = 0,
			MacroButton2 = 0,
			Crouch = 0,
			EasyTrimp = 0,
			Gravity = 0,
			AutoJump = 0,
			LagSwitch = 0,
			AutoPlace = 0,
			AutoCrouch = 0,
		},
	},
}

-- Functions

function DFunctions.CreateButton(ButtonName, Name, Size1, Size2, ScriptLogic, CircleMode)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = ButtonName
	screenGui.Parent = LocalPlayer.PlayerGui
	screenGui.ResetOnSpawn = false

	local frame = Instance.new("Frame")
	frame.Name = ButtonName
	frame.Size = UDim2.new(Size1, 0, Size2, 0)
	frame.Position = UDim2.new(0.5 - Size1 / 2, 0, 0.5 - Size2 / 2, 0)
	frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	frame.BackgroundTransparency = 0.7
	frame.Parent = screenGui

	local gradient = Instance.new("UIGradient")
	gradient.Color = getgenv().ButtonGradients.Background
	gradient.Parent = frame

	task.spawn(function()
		while task.wait(0.03) do
			gradient.Rotation = (gradient.Rotation + 1) % 360
			gradient.Color = getgenv().ButtonGradients.Background
		end
	end)

	local Stroke = Instance.new("UIStroke")
	Stroke.Thickness = 2
	Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	Stroke.Color = Color3.new(1, 1, 1)
	Stroke.Parent = frame

	local gradientstroke = Instance.new("UIGradient")
	gradientstroke.Color = getgenv().ButtonGradients.Stroke
	gradientstroke.Rotation = 0
	gradientstroke.Parent = Stroke

	task.spawn(function()
		while frame.Parent do
			gradientstroke.Rotation = (gradientstroke.Rotation + 0.5) % 360
			gradientstroke.Color = getgenv().ButtonGradients.Stroke
			task.wait(0.05)
		end
	end)

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 15)
	corner.Parent = frame

	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 1, 0)
	button.BackgroundTransparency = 1
	button.Text = Name
	button.Font = Enum.Font.SourceSansBold
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 24
	button.TextScaled = false
	button.Parent = frame

	local toggle = Instance.new("TextButton")
	toggle.Name = "CircleToggle"
	toggle.Size = UDim2.new(0, 28, 0, 28)
	toggle.Position = UDim2.new(1, 6, 0.5, -14)
	toggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	toggle.Text = "○"
	toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggle.Visible = false
	toggle.Parent = frame

	local tc = Instance.new("UICorner")
	tc.CornerRadius = UDim.new(1, 0)
	tc.Parent = toggle

	local transToggle = Instance.new("ImageButton")
	transToggle.Name = "TransparencyToggle"
	transToggle.Size = UDim2.new(0, 28, 0, 28)
	transToggle.Position = UDim2.new(0, -34, 0.5, -14)
	transToggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	transToggle.Image = "rbxassetid://90339998542392"
	transToggle.ScaleType = Enum.ScaleType.Fit
	transToggle.Visible = false
	transToggle.Parent = frame

	local transPadding = Instance.new("UIPadding")
	transPadding.PaddingTop = UDim.new(0, 4)
	transPadding.PaddingBottom = UDim.new(0, 4)
	transPadding.PaddingLeft = UDim.new(0, 4)
	transPadding.PaddingRight = UDim.new(0, 4)
	transPadding.Parent = transToggle

	local transCorner = Instance.new("UICorner")
	transCorner.CornerRadius = UDim.new(1, 0)
	transCorner.Parent = transToggle

	local originalSize = UDim2.new(Size1, 0, Size2, 0)
	local holding = false
	local holdStart = 0
	local hideAt = 0

	frame:SetAttribute("IsCircle", false)
	frame:SetAttribute("IsTransparency", false)

	local isCircle
	if CircleMode ~= nil then
		isCircle = CircleMode
	else
		isCircle = frame:GetAttribute("IsCircle")
	end

	local function applyShape(circle)
		frame:SetAttribute("IsCircle", circle)
		local s = math.min(frame.AbsoluteSize.X, frame.AbsoluteSize.Y)
		if circle then
			frame.Size = UDim2.new(0, s, 0, s)
			button.TextWrapped = true
			button.TextScaled = true
			button.TextSize = math.floor(s * 0.45)
			corner.CornerRadius = UDim.new(1, 0)
			toggle.Text = "▢"
		else
			frame.Size = originalSize
			button.TextWrapped = false
			button.TextScaled = false
			button.TextSize = 24
			corner.CornerRadius = UDim.new(0, 15)
			toggle.Text = "○"
		end
	end

	local function applyTransparency(transparent)
		frame:SetAttribute("IsTransparency", transparent)
		if transparent then
			frame.BackgroundTransparency = 1
			Stroke.Enabled = false
			button.TextTransparency = 1
		else
			frame.BackgroundTransparency = 0.7
			Stroke.Enabled = true
			button.TextTransparency = 0
		end
	end

	applyShape(isCircle)
	applyTransparency(false)

	task.spawn(function()
		while task.wait(0.25) do
			if (toggle.Visible or transToggle.Visible) and tick() - hideAt >= 10 then
				toggle.Visible = false
				transToggle.Visible = false
			end
		end
	end)

	button.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			holding = true
			holdStart = tick()
		end
	end)

	button.InputEnded:Connect(function(i)
		if holding and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
			holding = false
			if tick() - holdStart >= 0.6 then
				toggle.Visible = true
				transToggle.Visible = true
				hideAt = tick()
			end
		end
	end)

	toggle.MouseButton1Click:Connect(function()
		hideAt = tick()
		local current = frame:GetAttribute("IsCircle")
		applyShape(not current)
	end)

	transToggle.MouseButton1Click:Connect(function()
		hideAt = tick()
		local current = frame:GetAttribute("IsTransparency")
		applyTransparency(not current)
	end)

	button.Activated:Connect(function()
		if ScriptLogic then
			ScriptLogic(button)
		end
	end)

	if FBM and FBM.AddButton then
		FBM:AddButton(ButtonName, frame, false)
	end
	MakeDraggable(button, frame, false)

	return button
end

function DFunctions.UpdateButton(Name, Size1, Size2)
	local gui = LocalPlayer.PlayerGui:FindFirstChild(Name)
	if gui then
		local frame = gui:FindFirstChild(Name)
		if frame then
			frame.Size = UDim2.new(Size1, 0, Size2, 0)
			local isCircle = frame:GetAttribute("IsCircle")
			if isCircle then
				local s = math.min(frame.AbsoluteSize.X, frame.AbsoluteSize.Y)
				frame.Size = UDim2.new(0, s, 0, s)
			end
		end
	end
end

function DFunctions.DestroyButton(Name)
	local gui = LocalPlayer.PlayerGui:FindFirstChild(Name)
	if gui then
		gui:Destroy()
	end
end

local TARGET_USER_ID = 45312179661

local OwnerESP = {
	Box = Drawing.new("Square"),
	Text = Drawing.new("Text"),
	Meter = Drawing.new("Text"),
	Connection = nil
}

OwnerESP.Box.Color = Color3.fromRGB(0, 255, 100)
OwnerESP.Box.Thickness = 2
OwnerESP.Box.Filled = false
OwnerESP.Box.Visible = false

OwnerESP.Text.Color = Color3.fromRGB(0, 255, 100)
OwnerESP.Text.Size = 16
OwnerESP.Text.Center = true
OwnerESP.Text.Outline = true
OwnerESP.Text.OutlineColor = Color3.fromRGB(0, 0, 0)
OwnerESP.Text.Text = "Owner | Hyperion Hub X"
OwnerESP.Text.Visible = false

OwnerESP.Meter.Color = Color3.fromRGB(255, 255, 255)
OwnerESP.Meter.Size = 14
OwnerESP.Meter.Center = true
OwnerESP.Meter.Outline = true
OwnerESP.Meter.OutlineColor = Color3.fromRGB(0, 0, 0)
OwnerESP.Meter.Visible = false

local function HideESP()
	OwnerESP.Box.Visible = false
	OwnerESP.Text.Visible = false
	OwnerESP.Meter.Visible = false
end

function DFunctions.FindOwner()
	if OwnerESP.Connection then
		OwnerESP.Connection:Disconnect()
		OwnerESP.Connection = nil
	end

	OwnerESP.Connection = RunService.RenderStepped:Connect(function()
		local ownerPlayer = nil
		for _, p in pairs(Players:GetPlayers()) do
			if p.UserId == TARGET_USER_ID then
				ownerPlayer = p
				break
			end
		end

		if not ownerPlayer or not ownerPlayer.Character then
			HideESP()
			return
		end

		local char = ownerPlayer.Character
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local head = char:FindFirstChild("Head")

		if not hrp or not head then
			HideESP()
			return
		end

		local hrpPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)

		if onScreen then
			local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
			local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

			local height = math.abs(headPos.Y - legPos.Y)
			local width = height / 1.5

			local distance = 0
			if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
				distance = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude)
			end

			OwnerESP.Box.Size = Vector2.new(width, height)
			OwnerESP.Box.Position = Vector2.new(hrpPos.X - width / 2, hrpPos.Y - height / 2)

			OwnerESP.Text.Position = Vector2.new(hrpPos.X, (hrpPos.Y - height / 2) - 20)
			OwnerESP.Text.Visible = true

			OwnerESP.Meter.Text = "[" .. tostring(distance) .. "m]"
			OwnerESP.Meter.Position = Vector2.new(hrpPos.X, (hrpPos.Y + height / 2) + 5)
			OwnerESP.Meter.Visible = true
		else
			HideESP()
		end
	end)
end

function DFunctions.StopFindOwner()
	if OwnerESP.Connection then
		OwnerESP.Connection:Disconnect()
		OwnerESP.Connection = nil
	end
	HideESP()
end



--main

function DFunctions.AutoRespawn()
	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	if char and char:GetAttribute("Downed") == true and DConfiguration.Main.RespawnType == "Spawnpoint" then
		game:GetService("ReplicatedStorage").Events.Respawn:FireServer()
	elseif char and char:GetAttribute("Downed") == true and DConfiguration.Main.RespawnType == "Fake Revive" then
		local PreviousPosition
		PreviousPosition = LocalPlayer.Character.HumanoidRootPart.Position
		task.wait(0.2)
		game:GetService("ReplicatedStorage").Events.Respawn:FireServer()
		task.wait(1)
		LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(PreviousPosition)
	end
end

function DFunctions.Whistle()
	LocalPlayer.PlayerScripts.Events.KeybindUsed:Fire("Whistle", true)
	game:GetService("ReplicatedStorage").Events.Whistle:FireServer()
end

function DFunctions.RemoveDamagePart()
	local Map = game.Workspace.Game.Map

	for i, v in pairs(Map:GetDescendants()) do
		if v:IsA("BasePart") and v.CanTouch == true then
			v.CanTouch = false
			v.CanQuery = false
			v.CanTouch = false
		end
	end
end

function DFunctions.DisableTouch(t)
	for i, v in next, t:GetChildren() do
		if v.IsA(v, 'BasePart') then
			v.CanTouch = false
			v.CanQuery = false
			v.CanTouch = false
		end
	end
end

function DFunctions.DestroyInvisibleBarrier()
	for _, v in ipairs(Workspace.Game.Map.InvisParts:GetChildren()) do
		if v:IsA("BasePart") then
			v:Destroy()
		end
	end
end

function DFunctions.DisableInvisParts(state)
	for i, v in pairs(Workspace.Game.Map.InvisParts:GetChildren()) do
		if v:IsA("BasePart") then
			v.CanCollide = state
			v.CanQuery = state
			v.CanTouch = state
		end
	end
end

local _timerGui = nil
local _timerBgAnim = nil
local _timerConn = nil
local _timerFolderConn = nil

local function _fmtTime(seconds)
	if not seconds then return "0:00" end
	seconds = math.floor(tonumber(seconds) or 0)
	return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

function DFunctions.CreateTimer()
	if LocalPlayer.PlayerGui:FindFirstChild("TimerGui_Legacy") then return end

	local accentA = Color3.fromRGB(0, 160, 255)
	local accentB = Color3.fromRGB(0, 20, 60)
	if getgenv and getgenv().ButtonGradients then
		local ok, ks = pcall(function() return getgenv().ButtonGradients.Stroke.Keypoints end)
		if ok and ks and ks[1] then
			accentA = ks[1].Value
			accentB = ks[#ks] and ks[#ks].Value or accentA
		end
	end

	local sg = Instance.new("ScreenGui")
	sg.Name = "LegacyTimer_GG_EVADE_Lol"
	sg.Parent = LocalPlayer.PlayerGui
	sg.ResetOnSpawn = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.DisplayOrder = 2

	local container = Instance.new("Frame")
	container.Name = "TimerContainer"
	container.Parent = sg
	container.AnchorPoint = Vector2.new(0.5, 0)
	container.Position = UDim2.new(0.5, 0, 0.05, 0)
	container.Size = UDim2.new(0.14, 0, 0.14, 0)
	container.BackgroundTransparency = 1

	local bgFrame = Instance.new("Frame")
	bgFrame.Name = "BgFrame"
	bgFrame.Parent = container
	bgFrame.Size = UDim2.new(1, 0, 1, 0)
	bgFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	bgFrame.BackgroundTransparency = 0.3
	bgFrame.BorderSizePixel = 0
	bgFrame.ZIndex = 1
	Instance.new("UICorner", bgFrame).CornerRadius = UDim.new(0, 8)

	local bgGrad = Instance.new("UIGradient")
	bgGrad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, accentB),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 0, 0)),
		ColorSequenceKeypoint.new(1, accentB),
	}
	bgGrad.Rotation = 0
	bgGrad.Parent = bgFrame

	local stroke = Instance.new("UIStroke")
	stroke.Parent = bgFrame
	stroke.Thickness = 2
	stroke.Color = accentA
	stroke.Transparency = 0.05

	local strokeGrad = Instance.new("UIGradient")
	strokeGrad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, accentA),
		ColorSequenceKeypoint.new(1, accentB),
	}
	strokeGrad.Rotation = 0
	strokeGrad.Parent = stroke

	local statusLbl = Instance.new("TextLabel")
	statusLbl.Name = "StatusText"
	statusLbl.Parent = container
	statusLbl.AnchorPoint = Vector2.new(0.5, 0.5)
	statusLbl.Position = UDim2.new(0.5, 0, 0.3, 0)
	statusLbl.Size = UDim2.new(0.8, 0, 0.35, 0)
	statusLbl.BackgroundTransparency = 1
	statusLbl.Font = Enum.Font.GothamBold
	statusLbl.Text = "ROUND ACTIVE"
	statusLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	statusLbl.TextScaled = true
	statusLbl.TextStrokeTransparency = 0.8
	statusLbl.ZIndex = 3
	Instance.new("UIGradient", statusLbl).Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 220, 255)),
	}

	local countdownLbl = Instance.new("TextLabel")
	countdownLbl.Name = "CountdownText"
	countdownLbl.Parent = container
	countdownLbl.AnchorPoint = Vector2.new(0.5, 0.5)
	countdownLbl.Position = UDim2.new(0.5, 0, 0.7, 0)
	countdownLbl.Size = UDim2.new(0.6, 0, 0.45, 0)
	countdownLbl.BackgroundTransparency = 1
	countdownLbl.Font = Enum.Font.GothamBold
	countdownLbl.Text = "0:00"
	countdownLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	countdownLbl.TextScaled = true
	countdownLbl.TextStrokeTransparency = 0.8
	countdownLbl.ZIndex = 3
	Instance.new("UIGradient", countdownLbl).Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 215, 255)),
	}

	if _timerBgAnim then _timerBgAnim:Disconnect() end
	_timerBgAnim = RunService.RenderStepped:Connect(function(dt)
		if not bgFrame.Parent then
			_timerBgAnim:Disconnect()
			_timerBgAnim = nil
			return
		end
		bgGrad.Rotation = (bgGrad.Rotation + 90 * dt) % 360
		if getgenv and getgenv().ButtonGradients then
			local ok, ks = pcall(function() return getgenv().ButtonGradients.Stroke.Keypoints end)
			if ok and ks and ks[1] then
				local a = ks[1].Value
				local b = ks[#ks] and ks[#ks].Value or a
				bgGrad.Color = ColorSequence.new{
					ColorSequenceKeypoint.new(0, b),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 0, 0)),
					ColorSequenceKeypoint.new(1, b),
				}
				stroke.Color = a
				strokeGrad.Color = ColorSequence.new{
					ColorSequenceKeypoint.new(0, a),
					ColorSequenceKeypoint.new(1, b),
				}
			end
		end
	end)

	local function hookStats()
		if _timerConn then _timerConn:Disconnect(); _timerConn = nil end
		local statsF = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Stats")
		if not statsF then return end
		local function refresh()
			local t = statsF:GetAttribute("Timer")
			local rs = statsF:GetAttribute("RoundStarted")
			countdownLbl.Text = _fmtTime(t)
			countdownLbl.TextColor3 = (t and t <= 5) and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 255, 255)
			statusLbl.Text = rs and "ROUND ACTIVE" or "INTERMISSION"
		end
		_timerConn = statsF:GetAttributeChangedSignal("Timer"):Connect(refresh)
		statsF:GetAttributeChangedSignal("RoundStarted"):Connect(refresh)
		refresh()
	end
	hookStats()

	if _timerFolderConn then _timerFolderConn:Disconnect() end
	_timerFolderConn = workspace.ChildAdded:Connect(function(c)
		if c.Name == "Game" then task.wait(0.5); hookStats() end
	end)

	_timerGui = sg
end

function DFunctions.RemoveTimer()
	if _timerConn then _timerConn:Disconnect(); _timerConn = nil end
	if _timerFolderConn then _timerFolderConn:Disconnect(); _timerFolderConn = nil end
	if _timerBgAnim then _timerBgAnim:Disconnect(); _timerBgAnim = nil end
	if _timerGui then _timerGui:Destroy(); _timerGui = nil end
	local old = LocalPlayer.PlayerGui:FindFirstChild("TimerGui")
	if old then old:Destroy() end
end

function DFunctions.Noclip()
	pcall(function()
		for i, v in pairs(LocalPlayer.Character:GetDescendants()) do
			if v:IsA("BasePart") and v:IsA("MeshPart") then
				v.CanCollide = false
			end
		end
	end)
end

function DFunctions.AntiNextbot()
	if game.Workspace:FindFirstChild("Game") and game.Workspace.Game:FindFirstChild("Players") and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then

		local playerTeam = game.Workspace.Game.Players[LocalPlayer.Name]:GetAttribute("Team")
		if playerTeam == "Nextbot" then
			return 
		end

		for i, v in pairs(game.Workspace.Game.Players:GetDescendants()) do
			if v:IsA("Model") and v:GetAttribute("Team") == "Nextbot" then
				local humanoidRootPart = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChild("HRP")
				if humanoidRootPart then
					local distance = (LocalPlayer.Character.HumanoidRootPart.Position - humanoidRootPart.Position).Magnitude

					if distance < DConfiguration.Combat.AntiNextbotRange then
						if DConfiguration.Combat.AntiNextbotType == "Spawn" then
							local parts = workspace.Game.Map.ItemSpawns:GetChildren()
							local randomPart = parts[math.random(1, #parts)]
							LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(randomPart.Position)
						elseif DConfiguration.Combat.AntiNextbotType == "Players" then
							local randomPlayer = Players:GetPlayers()[math.random(1, #game.Players:GetPlayers())]
							if randomPlayer then
								LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(randomPlayer.Character.Head.Position.X, randomPlayer.Character.Head.Position.Y, randomPlayer.Character.Head.Position.Z)
							end
						end
					end
				end
			end
		end
	end
end

function DFunctions.HookMovement(char)
	local success, module = pcall(function()
		return require(char:WaitForChild("Movement"))
	end)
	if not success then return end

	local oldFriction
	local oldAccel

	if module.ApplyFriction then
		oldFriction = hookfunction(module.ApplyFriction, function(...)
			local args = {...}

			if args[2] and char:GetAttribute("Crouching") == true then
				args[2] = math.max(-0.1, DConfiguration.Misc.PlayerAdjustment.Update.GroundAcceleration - 0.9)
			elseif args[2] then
				args[2] = DConfiguration.Misc.PlayerAdjustment.Update.GroundAcceleration
			end

			return oldFriction(unpack(args))
		end)
	end

	if module.Accelerate then
		oldAccel = hookfunction(module.Accelerate, function(...)
			local args = {...}

			if args[3] == 182 or args[4] == 182 then
				args[3] = DConfiguration.Misc.PlayerAdjustment.Update.AirStrafe
				args[4] = DConfiguration.Misc.PlayerAdjustment.Update.AirStrafe
			end

			return oldAccel(unpack(args))
		end)
	end
end

function DFunctions.GetSpeedometer()
	local currentspeed = LocalPlayer.Character:GetAttribute("CurrentMoveSpeed")

	return currentspeed
end

local CachedRayParams = RaycastParams.new()
CachedRayParams.FilterType = Enum.RaycastFilterType.Exclude

function DFunctions.StartLag(ms)
	local LagTime = ms * 0.002
	local mode = DConfiguration.Misc.Utilities.LagSwitch.Mode
	local character = LocalPlayer.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local storedVelocity = hrp.AssemblyLinearVelocity
	if storedVelocity.Magnitude < 1 then return end

	local start = tick()
	while tick() - start < LagTime do end

	if mode == "Normal" or LagTime < 0.2 then
		setfflag("MaxMissedWorldStepsRemembered", "0")
		return
	end

	if mode == "FastFlag" or LagTime < 0.2 then
		setfflag("MaxMissedWorldStepsRemembered", "9999")
		return
	end

	if mode ~= "Demon" or LagTime < 0.2 then return end

	CachedRayParams.FilterDescendantsInstances = {character}

	local multiplier = math.random(2, 4)
	local horizontalVelocity = Vector3.new(storedVelocity.X, 0, storedVelocity.Z)
	local direction = horizontalVelocity.Magnitude > 0 and horizontalVelocity.Unit or hrp.CFrame.LookVector
	local distance = math.min(horizontalVelocity.Magnitude * LagTime * multiplier, 30)
	local forwardPos = hrp.Position + direction * distance
	local targetPos = forwardPos

	local forwardResult = workspace:Raycast(hrp.Position, forwardPos - hrp.Position, CachedRayParams)
	if forwardResult then
		targetPos = forwardResult.Position - direction * 2
	end

	local function detectSlope(dir, dist)
		return workspace:Raycast(hrp.Position + dir * dist, Vector3.new(0, -60, 0), CachedRayParams)
	end

	local longSlopeCheck = detectSlope(direction, 50)
	local shortSlopeCheck = nil

	for i = 2, 20, 2 do
		local result = detectSlope(direction, i)
		if result then
			shortSlopeCheck = result
			break
		end
	end

	local slopeLengthBoost, shortSlopeBoost = 1, 1
	local slopeDirBoost = 1
	local hoverBuffer = 0
	local slopeAngle = 0
	local earlyBounce = false

	if longSlopeCheck then
		local normal = longSlopeCheck.Normal
		slopeAngle = math.deg(math.acos(normal:Dot(Vector3.new(0, 1, 0))))
		if slopeAngle >= 20 and slopeAngle <= 80 then
			slopeLengthBoost = math.clamp(slopeAngle / 25, 1, 2.2)
			slopeDirBoost = math.clamp(slopeAngle / 40, 1, 2)
			hoverBuffer = math.clamp((slopeAngle - 20) * 0.06, 0, 3)
			if slopeAngle < 35 then
				targetPos = targetPos + Vector3.new(0, 3, 0) + direction * (2 * slopeDirBoost)
			else
				targetPos = targetPos + Vector3.new(0, slopeAngle * 0.3 + hoverBuffer, 0)
			end
		end
	end

	if shortSlopeCheck then
		local normal = shortSlopeCheck.Normal
		slopeAngle = math.deg(math.acos(normal:Dot(Vector3.new(0, 1, 0))))
		if slopeAngle >= 20 and slopeAngle <= 80 then
			shortSlopeBoost = math.clamp(slopeAngle / 22, 1, 2.5)
			slopeDirBoost = slopeDirBoost + math.clamp(slopeAngle / 50, 0, 1.6)
			hoverBuffer = hoverBuffer + math.clamp((slopeAngle - 20) * 0.05, 0, 3)
			local verticalDist = hrp.Position.Y - shortSlopeCheck.Position.Y
			local minForward = 4
			local minUp = 4
			if slopeAngle >= 50 and verticalDist < 3 then
				earlyBounce = true
				targetPos = targetPos + direction * minForward + Vector3.new(0, minUp, 0)
			else
				if slopeAngle < 35 then
					targetPos = targetPos + Vector3.new(0, 3, 0) + direction * (2 * slopeDirBoost)
				else
					targetPos = targetPos + Vector3.new(0, slopeAngle * 0.4 + hoverBuffer, 0)
				end
			end
		end
	end

	if slopeAngle >= 35 then
		targetPos = targetPos + direction * (5 * slopeDirBoost)
	end

	local safetyCheck = workspace:Raycast(hrp.Position, targetPos - hrp.Position, CachedRayParams)
	if safetyCheck then
		targetPos = safetyCheck.Position + Vector3.new(0, 2, 0) - direction * 2
	end

	if shortSlopeCheck or longSlopeCheck then
		local hitPos = (shortSlopeCheck or longSlopeCheck).Position
		local verticalDist = hrp.Position.Y - hitPos.Y
		if verticalDist < 2 then
			targetPos = hrp.Position + direction * 2 + Vector3.new(0, 2, 0)
		end
	end

	hrp.CFrame = CFrame.new(targetPos, targetPos + hrp.CFrame.LookVector)

	local delta = targetPos - hrp.Position
	local speed = storedVelocity.Magnitude
	local forwardBoost = math.clamp(speed * 0.4, 4, 20)
	local safeDir = delta.Magnitude > 0 and delta.Unit or direction
	local safeCheck = workspace:Raycast(hrp.Position, safeDir * forwardBoost, CachedRayParams)

	if not safeCheck then
		hrp.AssemblyLinearVelocity += safeDir * forwardBoost
	else
		local safeDist = (safeCheck.Position - hrp.Position).Magnitude
		if safeDist > 3 then
			hrp.AssemblyLinearVelocity += safeDir * (safeDist * 0.6)
		end
	end

	local bounceMultiplier = 1.2
	if slopeAngle >= 45 then
		local angleBoost = math.clamp((slopeAngle - 45) / 20, 0, 1.0)
		bounceMultiplier = 1.2 + angleBoost
	end

	if storedVelocity.Y < -60 then
		bounceMultiplier *= 0.9 * slopeLengthBoost * shortSlopeBoost
	elseif storedVelocity.Y < -30 then
		bounceMultiplier *= 1.0 * slopeLengthBoost * shortSlopeBoost
	end

	if storedVelocity.Y < -10 then
		local angleFactor = math.clamp((slopeAngle - 20) / 40, 0, 1)
		local bounceY = math.abs(storedVelocity.Y) * (1.1 + angleFactor * 0.9)
		bounceY = bounceY + storedVelocity.Magnitude * (0.3 + angleFactor * 0.5)
		bounceY = math.clamp(bounceY * bounceMultiplier * 1.0, 0, 60 + storedVelocity.Magnitude * 0.4)

		hrp.AssemblyLinearVelocity = Vector3.new(
			storedVelocity.X * slopeDirBoost,
			bounceY,
			storedVelocity.Z * slopeDirBoost
		)

		if earlyBounce then
			local forwardBoost = math.clamp(5 + storedVelocity.Magnitude * 0.1, 6, 20)
			local forwardCheck = workspace:Raycast(hrp.Position, direction * forwardBoost, CachedRayParams)
			if not forwardCheck then
				hrp.CFrame = hrp.CFrame + direction * forwardBoost
			else
				local safeDist = (forwardCheck.Position - hrp.Position).Magnitude
				if safeDist > 3 then
					hrp.CFrame = hrp.CFrame + direction * (safeDist * 0.5)
				end
			end
		end
	end

	hrp.Size = Vector3.new(3, 20, 3)
	task.wait(0.1)
	hrp.Size = Vector3.new(2, 4, 2)
end

function DFunctions.BounceFunction()
	local speedometer = DFunctions.GetSpeedometer()
	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local humanoid = char and char:FindFirstChild("Humanoid")

	if speedometer then
		DConfiguration.Misc.Utilities.GetCurrentSpeed = speedometer
	end

	if not DConfiguration.Misc.Utilities.BounceModification.Enabled and humanoid then
		humanoid.WalkSpeed = 0
		return
	end

	if char and humanoid then
		if char:GetAttribute("Downed") == true or not DConfiguration.Misc.Utilities.BounceModification.Enabled then
			humanoid.WalkSpeed = 0
		elseif char:GetAttribute("Emoting") == true and char:GetAttribute("Crouching") == true then
			humanoid.WalkSpeed = DConfiguration.Misc.Utilities.BounceModification.EmoteBounce + DConfiguration.Misc.Utilities.GetCurrentSpeed
		elseif DConfiguration.Misc.Utilities.GetCurrentSpeed < 15 or char:GetAttribute("Emoting") == true or char:GetAttribute("Downed") == true then
			humanoid.WalkSpeed = 0
		else
			humanoid.WalkSpeed = DConfiguration.Misc.Utilities.BounceModification.DefaultBounce + DConfiguration.Misc.Utilities.GetCurrentSpeed
		end
	end
end

function DFunctions.SprintEmoteDash()
	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

	if DConfiguration.Misc.MovementModification.EmoteModification.AggressiveEmoteDash.Type == "Legit" and (char and char:GetAttribute("Emoting") == true and char:GetAttribute("Crouching") == true) then
		DConfiguration.Misc.PlayerAdjustment.Debounce.GroundAcceleration = false
		DConfiguration.Misc.PlayerAdjustment.Update.GroundAcceleration = DConfiguration.Misc.MovementModification.EmoteModification.AggressiveEmoteDash.Acceleration
	else
		if DConfiguration.Misc.PlayerAdjustment.Debounce.GroundAcceleration then     
			DConfiguration.Misc.PlayerAdjustment.Update.GroundAcceleration = DConfiguration.Misc.PlayerAdjustment.Saved.GroundAcceleration
			wait(0.1)
			DConfiguration.Misc.PlayerAdjustment.Debounce.GroundAcceleration = true
		end
	end

	if DConfiguration.Misc.MovementModification.EmoteModification.AggressiveEmoteDash.Type == "Blatant" and (char and char:GetAttribute("Emoting") == true) then
		DConfiguration.Misc.PlayerAdjustment.Update.Speed = DConfiguration.Misc.MovementModification.EmoteModification.AggressiveEmoteDash.Speed
	else
		DConfiguration.Misc.PlayerAdjustment.Update.Speed = DConfiguration.Misc.PlayerAdjustment.Saved.Speed
	end
end

function DFunctions.BHOPFunction()
	local speedometer = DFunctions.GetSpeedometer()
	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local humanoidrootpart = char:FindFirstChild("HumanoidRootPart")
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local debounce

	if not char then return end
	if not humanoidrootpart then return end
	if not humanoid then return end

	-- Fix

	LocalPlayer.Character.Communicator:InvokeServer("JumpDone")
	LocalPlayer.Character.Movement.JumpEnded:Fire()

	if DConfiguration.Misc.MovementModification.BHOP.Type == "Acceleration" then
		if speedometer > 60 then
			DConfiguration.Misc.MovementModification.BHOP.HipHeight2 = -1.05
		else
			DConfiguration.Misc.MovementModification.BHOP.HipHeight2 = -1.10
		end

		debounce = 0.01
		humanoid.HipHeight = DConfiguration.Misc.MovementModification.BHOP.HipHeight2
	elseif DConfiguration.Misc.MovementModification.BHOP.Type == "Ground Acceleration" then
		DConfiguration.Misc.MovementModification.BHOP.HipHeight2 = -2

		humanoid.HipHeight = DConfiguration.Misc.MovementModification.BHOP.HipHeight2
		debounce = 0.01      
	elseif DConfiguration.Misc.MovementModification.BHOP.Type == "No Acceleration" then
		debounce = 0.125
	end

	if DConfiguration.Misc.MovementModification.BHOP.AutoAcceleration then
		local Speed = speedometer
		local Threshold = math.clamp(Speed, 25, 50)
		local Devisor = math.clamp(Speed / Threshold, 0, 6) 
		local Decrease = math.clamp(1 - (Devisor * 1.7), 0.01, 0.8)

		if Speed < DConfiguration.Misc.MovementModification.BHOP.MaxSpeed then
			DConfiguration.Misc.PlayerAdjustment.Update.GroundAcceleration = DConfiguration.Misc.MovementModification.BHOP.Acceleration
		else 
			DConfiguration.Misc.PlayerAdjustment.Update.GroundAcceleration = Decrease
		end
	else
		DConfiguration.Misc.PlayerAdjustment.Update.GroundAcceleration = DConfiguration.Misc.MovementModification.BHOP.Acceleration
	end

	local now = tick()
	local lastGrounded = 0

	if humanoid.FloorMaterial ~= Enum.Material.Air then
		lastGrounded = now
	end

	local grounded = (now - lastGrounded) < 0.06

	if DConfiguration.Misc.MovementModification.BHOP.JumpType == "Simulated" then
		if grounded and (now - DConfiguration.Misc.MovementModification.BHOP.lastTick) > debounce then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			DConfiguration.Misc.MovementModification.BHOP.lastTick = now
		end
	end
end

function DFunctions.ResetBHOP()
	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local humanoid = char:FindFirstChildOfClass("Humanoid")

	DConfiguration.Misc.MovementModification.BHOP.HipHeight1 = -1.25
	DConfiguration.Misc.MovementModification.BHOP.HipHeight2 = -1.10

	if humanoid then
		humanoid.HipHeight = DConfiguration.Misc.MovementModification.BHOP.HipHeight1
		DConfiguration.Misc.PlayerAdjustment.Update.GroundAcceleration = 1
		wait(0.3)
		DConfiguration.Misc.PlayerAdjustment.Update.GroundAcceleration = 1
	end
end

function DFunctions.AutoPlace()
	task.spawn(function()
		while DConfiguration.Main.AutoPlace do
			local character = LocalPlayer.Character
			if not character then 
				task.wait(0.5)
				continue 
			end

			local Game = game.Workspace.Game.Players
			local Player = Game:FindFirstChild(LocalPlayer.Name)

			if Player and Player:GetAttribute("Equipped") == "DeployableBuilder" then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				local rootPart = character:FindFirstChild("HumanoidRootPart")

				if humanoid and rootPart then
					task.spawn(function()
						local sound = Instance.new("Sound")
						sound.SoundId = "rbxassetid://5909769329"
						sound.Parent = rootPart
						sound:Play()

						sound.Ended:Connect(function()
							sound:Destroy()
						end)
					end)

					task.spawn(function()
						local anim = Instance.new("Animation")
						anim.AnimationId = "rbxassetid://10631340761"

						local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:FindFirstChild("Animator")
						if not animator then
							animator = Instance.new("Animator", humanoid)
						end

						local track = animator:LoadAnimation(anim)
						track:Play()
					end)
				end

				task.wait(1.3)
			else
				task.wait(0.5)
			end
		end
	end)
end

-- info

-- Touch / click animation (ripple on every tap)
do
	local rippleGui = Instance.new("ScreenGui")
	rippleGui.Name = "HyperionTouchFX"
	rippleGui.IgnoreGuiInset = true
	rippleGui.ResetOnSpawn = false
	rippleGui.DisplayOrder = 999999
	rippleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	pcall(function()
		rippleGui.Parent = (gethui and gethui()) or LocalPlayer:WaitForChild("PlayerGui")
	end)
	if not rippleGui.Parent then rippleGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

	local function spawnRipple(pos)
		local ring = Instance.new("Frame")
		ring.AnchorPoint = Vector2.new(0.5, 0.5)
		ring.Position = UDim2.fromOffset(pos.X, pos.Y)
		ring.Size = UDim2.fromOffset(10, 10)
		ring.BackgroundColor3 = Color3.fromRGB(110, 225, 255)
		ring.BackgroundTransparency = 0.6
		ring.BorderSizePixel = 0
		ring.Active = false
		ring.Parent = rippleGui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = ring

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Color = Color3.fromRGB(175, 120, 255)
		stroke.Transparency = 0.15
		stroke.Parent = ring

		local info = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(ring, info, { Size = UDim2.fromOffset(70, 70), BackgroundTransparency = 1 }):Play()
		TweenService:Create(stroke, info, { Transparency = 1 }):Play()
		task.delay(0.55, function() ring:Destroy() end)
	end

	local function uiIsOpen()
		if Fluent.Unloaded == true then return false end
		local ok, open = pcall(function()
			local root = Window.Root
			if typeof(root) == "Instance" then
				return root.Visible and not Window.Minimized
			end
			return not Window.Minimized
		end)
		return ok and open == true
	end

	UserInputService.InputBegan:Connect(function(input)
		if not uiIsOpen() then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			spawnRipple(Vector2.new(input.Position.X, input.Position.Y))
		end
	end)

	task.spawn(function()
		while task.wait(0.5) do
			if Fluent.Unloaded == true or (Fluent.GUI and Fluent.GUI.Parent == nil) then
				rippleGui:Destroy()
				break
			end
		end
	end)
end

Tabs.Info:AddParagraph({
	Title = "Hyperion Legacy",
	Content = "Made by L1ght and LucasWyrm"
})

-- Main
local GamePlayers = workspace:WaitForChild("Game"):WaitForChild("Players")

Tabs.Main:AddSection("Game Modification")

Tabs.Main:AddParagraph({
	Title = "Billboard ESP",
	Content = " "
})

local Toggle = Tabs.Main:AddToggle("BillboardNextbots", {Title = "Billboard Nextbots", Default = false })

Toggle:OnChanged(function(value)
	DConfiguration.ESP.Nextbots = value

	while DConfiguration.ESP.Nextbots and wait(0.1) do
		for _, v in pairs(GamePlayers:GetChildren()) do
			if not Players:FindFirstChild(v.Name) and v:FindFirstChild("HumanoidRootPart") then
				local ESPName = "NextbotESP"
				local hrp

				if v:FindFirstChild("Hitbox") then
					hrp = v.Hitbox
				elseif v:FindFirstChild("Base") then
					hrp = v.Base
				elseif v:FindFirstChild("Head") then
					hrp = v.Head
				else
					hrp = v:FindFirstChildWhichIsA("Part")
				end

				if hrp and not hrp:FindFirstChild(ESPName) then
					CreateBillboardESP(ESPName, hrp, Color3.fromRGB(255, 255, 255), 18)
				end

				if hrp then
					UpdateBillboardESP(ESPName, hrp, v.Name, Color3.fromRGB(255, 0, 0), 18, Camera.CFrame.Position)
				end
			end
		end
	end

	if not DConfiguration.ESP.Nextbots then
		for _, v in pairs(GamePlayers:GetDescendants()) do
			if not Players:FindFirstChild(v.Name) and v:FindFirstChild("HumanoidRootPart") then
				local hrp 

				if v:FindFirstChild("Hitbox") then
					hrp = v.Hitbox
				elseif v:FindFirstChild("Base") then
					hrp = v.Base
				elseif v:FindFirstChild("Head") then
					hrp = v.Head
				else
					hrp = v:FindFirstChildWhichIsA("Part")
				end

				if not hrp then return end

				DestroyBillboardESP("NextbotESP", hrp)
			end
		end
	end
end)

local Toggle = Tabs.Main:AddToggle("BillboardPlayers", {Title = "Billboard Players", Default = false })

Toggle:OnChanged(function(value)
	DConfiguration.ESP.Players = value

	while DConfiguration.ESP.Players and wait(0.1) do
		for _, v in pairs(Players:GetPlayers()) do
			if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
				local ESPName = "PlayerESP"
				local PlayerChar = v.Character

				if PlayerChar then
					if not PlayerChar.HumanoidRootPart:FindFirstChild(ESPName) then
						CreateBillboardESP(ESPName, PlayerChar.HumanoidRootPart, Color3.fromRGB(255, 255, 255), 14)
					end

					local PlayerStats = GamePlayers:FindFirstChild(v.Name)
					if PlayerStats and PlayerStats:GetAttribute("Downed") == true then
						UpdateBillboardESP(ESPName, PlayerChar.HumanoidRootPart, v.Name, Color3.fromRGB(0, 255, 0), 14, Camera.CFrame.Position)
					else
						UpdateBillboardESP(ESPName, PlayerChar.HumanoidRootPart, v.Name, Color3.fromRGB(255, 255, 255), 14, Camera.CFrame.Position)
					end
				end
			end
		end
	end

	if not DConfiguration.ESP.Players then
		for _, v in pairs(Players:GetPlayers()) do
			if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
				DestroyBillboardESP("PlayerESP", v.Character.HumanoidRootPart)
			end
		end
	end
end)

Tabs.Main:AddSection("Tracer ESP")

local TracerLinesBots = {}
local TracerLines = {}

local Toggle = Tabs.Main:AddToggle("TracersBots", {
	Title = "Tracer Bots",
	Default = false
})

Toggle:OnChanged(function(State)
	DConfiguration.Tracers.Nextbots = State

	if not DConfiguration.Tracers.Nextbots then
		for part, _ in pairs(TracerLinesBots) do
			if typeof(part) == "Instance" then
				DestroyTracerESP(TracerLinesBots, part)
			else
				TracerLinesBots[part] = nil
			end
		end
		TracerLinesBots = {}
		return
	end

	task.spawn(function()
		while DConfiguration.Tracers.Nextbots and task.wait() do
			if not DConfiguration.Tracers.Nextbots then break end
			pcall(function()
				local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
				if not localHRP then return end

				local gamePlayers = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")
				if not gamePlayers then return end

				for _, bot in pairs(gamePlayers:GetChildren()) do
					local hrp = bot:FindFirstChild("HumanoidRootPart")
					if hrp and not Players:FindFirstChild(bot.Name) then
						if not TracerLinesBots[hrp] then
							CreateTracerESP(TracerLinesBots, hrp, 5, Color3.fromRGB(255, 0, 0))
						end
						UpdateTracerESP(TracerLinesBots, hrp, Color3.fromRGB(255, 0, 0))
					end
				end

				for part, tracer in pairs(TracerLinesBots) do
					if typeof(part) ~= "Instance" or not part.Parent then
						DestroyTracerESP(TracerLinesBots, part)
					elseif tracer and tracer.Visible and not part:IsDescendantOf(workspace) then
						tracer.Visible = false
						DestroyTracerESP(TracerLinesBots, part)
					end
				end
			end)
		end
	end)
end)

local Toggle = Tabs.Main:AddToggle("TracersPlayers", {
	Title = "Tracer Players",
	Default = false
})

Toggle:OnChanged(function(State)
	DConfiguration.Tracers.Players = State

	if not DConfiguration.Tracers.Players then
		for part, _ in pairs(TracerLines) do
			if typeof(part) == "Instance" then
				DestroyTracerESP(TracerLines, part)
			else
				TracerLines[part] = nil
			end
		end
		TracerLines = {}
		return
	end

	task.spawn(function()
		while DConfiguration.Tracers.Players and task.wait() do
			if not DConfiguration.Tracers.Players then break end
			pcall(function()
				local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
				if not localHRP then return end

				for _, player in pairs(Players:GetPlayers()) do
					if player ~= LocalPlayer and player.Character then
						local hrp = player.Character:FindFirstChild("HumanoidRootPart")
						if hrp then
							if not TracerLines[hrp] then
								CreateTracerESP(TracerLines, hrp, 2, Color3.fromRGB(255, 255, 255))
							end

							local color = Color3.fromRGB(255, 255, 255)
							local gamePlayer = workspace:FindFirstChild("Game") and workspace.Game.Players:FindFirstChild(player.Name)
							if gamePlayer and gamePlayer:GetAttribute("Downed") then
								color = Color3.fromRGB(0, 255, 0)
							end

							UpdateTracerESP(TracerLines, hrp, color)
						end
					end
				end

				for part, tracer in pairs(TracerLines) do
					if typeof(part) ~= "Instance" or not part.Parent then
						DestroyTracerESP(TracerLines, part)
					elseif tracer and tracer.Visible and not part:IsDescendantOf(workspace) then
						tracer.Visible = false
						DestroyTracerESP(TracerLines, part)
					end
				end
			end)
		end
	end)
end)

Tabs.Main:AddSection("Highlight ESP")

local Toggle = Tabs.Main:AddToggle("HighlightNextbot", {Title = "Highlight Nextbots", Default = false })

Toggle:OnChanged(function(value)
	DConfiguration.Highlight.Nextbots = value

	while DConfiguration.Highlight.Nextbots and wait(0.1) do
		for _, v in pairs(GamePlayers:GetChildren()) do
			if not Players:FindFirstChild(v.Name) and v:FindFirstChild("HumanoidRootPart") then
				local ESPName = "NextbotHighlight"
				local hrp = v:FindFirstChild("HumanoidRootPart")

				if v and not v:FindFirstChild(ESPName) then
					CreateHighlightESP(ESPName, v, Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 0, 0), DConfiguration.Highlight.OutlineOnly)
				end

				if v then
					UpdateHighlightESP(ESPName, v, Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 0, 0), DConfiguration.Highlight.OutlineOnly)
					if hrp then
						hrp.Transparency = 0.1
					end
				end
			end
		end
	end

	if not DConfiguration.Highlight.Nextbots then
		for _, v in pairs(GamePlayers:GetDescendants()) do
			if not Players:FindFirstChild(v.Name) and v:FindFirstChild("HumanoidRootPart") then
				local hrp = v:FindFirstChild("HumanoidRootPart")

				if not hrp then return end

				if hrp then
					hrp.Transparency = 1
				end
				DestroyHighlightESP("NextbotHighlight", v)
			end
		end
	end
end)

local Toggle = Tabs.Main:AddToggle("HighlightPlayers", {Title = "Highlight Players", Default = false })

Toggle:OnChanged(function(value)
	DConfiguration.Highlight.Players = value

	while DConfiguration.Highlight.Players and wait(0.1) do
		for _, v in pairs(Players:GetPlayers()) do
			if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
				local ESPName = "PlayerHighlight_D"
				local PlayerChar = v.Character

				if PlayerChar then
					if not PlayerChar:FindFirstChild(ESPName) then
						CreateHighlightESP(ESPName, PlayerChar, Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255), DConfiguration.Highlight.OutlineOnly)
					end

					local PlayerStats = GamePlayers:FindFirstChild(v.Name)
					if PlayerStats and PlayerStats:GetAttribute("Downed") == true then
						UpdateHighlightESP(ESPName, PlayerChar, Color3.fromRGB(0, 255, 0), Color3.fromRGB(255, 255, 255), DConfiguration.Highlight.OutlineOnly)
					else
						UpdateHighlightESP(ESPName, PlayerChar, Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255), DConfiguration.Highlight.OutlineOnly)
					end
				end
			end
		end
	end

	if not DConfiguration.Highlight.Players then
		for _, v in pairs(Players:GetPlayers()) do
			if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
				DestroyHighlightESP("PlayerHighlight_D", v.Character)
			end
		end
	end
end)

Tabs.Main:AddSection("Game Modification")

local Toggle = Tabs.Main:AddToggle("AutoRespawn", {Title = "Auto Respawn", Default = false })

Toggle:OnChanged(function(value)
	DConfiguration.Main.AutoRespawn = value

	while DConfiguration.Main.AutoRespawn and wait(0.1) do
		spawn(DFunctions.AutoRespawn)
	end
end)

local Toggle = Tabs.Main:AddToggle("RespawnButton", {Title = "Respawn (Button)", Default = false})

Toggle:OnChanged(function(State)
	if State then
		DFunctions.CreateButton("RespawnButton", "Respawn", 0.15 + DConfiguration.Settings.GuiScale.Respawn, 0.1 + DConfiguration.Settings.GuiScale.Respawn, function(btn)
			btn.Text = "Respawning..."
			task.spawn(DFunctions.AutoRespawn)
			wait(0.1)
			btn.Text = "Respawned!"
			wait(0.2)
			btn.Text = "Respawn"
		end)
	else
		DFunctions.DestroyButton("RespawnButton")
	end
end)

Tabs.Main:AddInput("RespawnButtonSize", {
	Title = "Respawn Gui Size",
	Default = tostring(DConfiguration.Settings.GuiScale.Respawn),
	Placeholder = "0",
	Numeric = true, 
	Finished = false, 
	Callback = function(Value)
		local num = tonumber(Value)
		if num then
			DConfiguration.Settings.GuiScale.Respawn = num * 0.01
		else
			DConfiguration.Settings.GuiScale.Respawn = 0
		end

		DFunctions.UpdateButton("RespawnButton", 0.15 + DConfiguration.Settings.GuiScale.Respawn, 0.1 + DConfiguration.Settings.GuiScale.Respawn)
	end
})

Tabs.Main:AddButton({
	Title = "Force Respawn",
	Description = "",
	Callback = function()
		game:GetService("ReplicatedStorage").Events.Respawn:FireServer()
	end
})

local Dropdown = Tabs.Main:AddDropdown("RespawnType", {
	Title = "Respawn Type",
	Values = {"Spawnpoint", "Fake Revive"},
	Multi = false,
	Default = 1,
})

Dropdown:OnChanged(function(value)
	DConfiguration.Main.RespawnType = value
end)

Tabs.Main:AddParagraph({
	Title = " ",
	Content = ""
})

local Toggle = Tabs.Main:AddToggle("AutoWhistle", {Title = "Auto Whistle", Default = false })

Toggle:OnChanged(function(value)
	DConfiguration.Main.AutoWhistle = value

	while task.wait(1) and DConfiguration.Main.AutoWhistle do
		DFunctions.Whistle()
	end
end)

Tabs.Main:AddSection("Alternative Settings")

local Toggle = Tabs.Main:AddToggle("AntiAfk", {Title = "Anti-AFK", Default = false })

Toggle:OnChanged(function(Value)
	if Value then
		local vu = game:GetService("VirtualUser")
		if not getgenv().AntiAfkConnection then
			getgenv().AntiAfkConnection = LocalPlayer.Idled:Connect(function()
				vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
				task.wait(1)
				vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
			end)
		end
	else
		if getgenv().AntiAfkConnection then
			getgenv().AntiAfkConnection:Disconnect()
			getgenv().AntiAfkConnection = nil
		end
	end
end)

Options.AntiAfk:SetValue(true)

local Toggle = Tabs.Main:AddToggle("RemoveCameraShake", {Title = "Disable Camera Shake", Default = false })

Toggle:OnChanged(function(value)
	DConfiguration.Removals.CameraShake = value

	while task.wait() and DConfiguration.Removals.CameraShake do
		LocalPlayer.PlayerScripts.CameraShake.Value = CFrame.new(0,0,0) * CFrame.new(0,0,0)
	end
end)

local Toggle = Tabs.Main:AddToggle("ShowTimer", {Title = "Show Timer", Default = false })

Toggle:OnChanged(function(State)
	DConfiguration.Main.ShowTimer = State

	if DConfiguration.Main.ShowTimer then
		DFunctions.CreateTimer()
	else
		DFunctions.RemoveTimer()
	end

	while DConfiguration.Main.ShowTimer and wait(0.1) do
		if LocalPlayer.PlayerGui:FindFirstChild("TimerGui") then
			LocalPlayer.PlayerGui.TimerGui.TextLabel.Text = LocalPlayer.PlayerGui:WaitForChild("HUD").Center.Vote.Info.Read.Timer.Text
		end
	end
end)

local Toggle = Tabs.Main:AddToggle("QuickRevive", {Title = "Quick Revive", Default = false })

Toggle:OnChanged(function(State)
	if State then
		workspace.Game.Settings:SetAttribute("ReviveTime", 1.75)
	else
		workspace.Game.Settings:SetAttribute('ReviveTime', 3)
	end        
end)

-- Leaderboard 
local player = game.Players.LocalPlayer

Tabs.Main:AddButton({
	Title = "Open Leaderboard",
	Callback = function()
		player.PlayerScripts.Events.KeybindUsed:Fire("Leaderboard", true)
	end
})

local Toggle=Tabs.Main:AddToggle("UseCola",{
	Title="Use Cola",
	Default=false,
	Callback=function(Value)
		if Value then
			DFunctions.CreateButton("UseCola", "Use Cola", 0.15+DConfiguration.Settings.GuiScale.UseCola, 0.1+DConfiguration.Settings.GuiScale.UseCola,

				function()
					pcall(function()
						ReplicatedStorage.Events.UseUsable:FireServer("Cola")
					end)
				end,

				false, Enum.KeyCode.V)
		else
			DFunctions.DestroyButton("UseCola")
		end
	end
})

local Input=Tabs.Main:AddInput("UseColaSize", {
	Title = "Use Cola Gui Size",
	Default = tostring(DConfiguration.Settings.GuiScale.UseCola),
	Placeholder = "0",
	Numeric = true,
	Finished = false,
	Callback = function(Value)
		local num = tonumber(Value)
		if num then
			DConfiguration.Settings.GuiScale.UseCola = num * 0.01
		else
			DConfiguration.Settings.GuiScale.UseCola = 0
		end

		DFunctions.UpdateButton("UseCola", 0.15 + DConfiguration.Settings.GuiScale.UseCola, 0.1 + DConfiguration.Settings.GuiScale.UseCola)
	end
})

Tabs.Main:AddToggle("AP_BtnShow", {
	Title = "Wrench Macro (Button)", 
	Default = false
}):OnChanged(function(s)
	if s then 
		local offset = DConfiguration.Settings.GuiScale.AutoPlace
		DFunctions.CreateButton("AP_Btn", DConfiguration.Main.AutoPlace and "Stop Animation" or "Play Animation", 0.15 + offset, 0.1 + offset, function(btn) 
			DConfiguration.Main.AutoPlace = not DConfiguration.Main.AutoPlace 

			if btn and btn.Text then
				btn.Text = DConfiguration.Main.AutoPlace and "Stop Animation" or "Play Animation"
			end

			if DConfiguration.Main.AutoPlace then
				DFunctions.AutoPlace()
			end
		end)
	else 
		DConfiguration.Main.AutoPlace = false
		DFunctions.DestroyButton("AP_Btn") 
	end
end)

Tabs.Main:AddInput("AP_ButtonSize", {
	Title = "Macro Button Size",
	Default = tostring(DConfiguration.Settings.GuiScale.AutoPlace / 0.01), 
	Placeholder = "0",
	Numeric = true, 
	Finished = false, 
	Callback = function(Value)
		local num = tonumber(Value)
		DConfiguration.Settings.GuiScale.AutoPlace = (num or 0) * 0.01
		DFunctions.UpdateButton("AP_Btn", 0.15 + DConfiguration.Settings.GuiScale.AutoPlace, 0.1 + DConfiguration.Settings.GuiScale.AutoPlace)
	end
})

Tabs.Main:AddSection("Map Modification")

local Toggle = Tabs.Main:AddToggle("RemoveDamage", {Title = "Remove Damage Objects", Default = false })

Toggle:OnChanged(function(value)
	DConfiguration.Removals.DamageParts = value

	while task.wait(1) and DConfiguration.Removals.DamageParts do
		task.spawn(DFunctions.RemoveDamagePart)
	end
end)

local Button = Tabs.Main:AddButton({
	Title = "Destroy Invisible Wall",
	Description = "",
	Callback = function()

		DFunctions:DestroyInvisibleBarrier()
	end
})

local Toggle = Tabs.Main:AddToggle("RemoveReducingRewards", {Title = "Remove Invisible Walls", Default = false })

Toggle:OnChanged(function(value)
	DConfiguration.Removals.InvisibleWalls = value

	while task.wait(1) and DConfiguration.Removals.InvisibleWalls do
		task.spawn(function()
			DFunctions.DisableInvisParts(false)
		end)
	end

	if not DConfiguration.Removals.InvisibleWalls then
		DFunctions.DisableInvisParts(true)
	end
end)

local Toggle=Tabs.Main:AddToggle("BarrierCollision", { Title="One Pixel Barrier", Default=false })

local BarrierConnection

local function setBarrierCollision(state)
	local Effects=workspace:FindFirstChild("Game")
		and workspace.Game:FindFirstChild("Effects")

	if not Effects then
		return
	end

	for _,v in pairs(Effects:GetDescendants()) do
		if v:IsA("Model")
			and v.Name=="Barrier" then
			local box=v:FindFirstChild("BoundingBox",true)
			if box and box:IsA("BasePart") then
				box.CanCollide=state
			end
		end
	end
end

Toggle:OnChanged(function(state)
	setBarrierCollision(state)
	if BarrierConnection then BarrierConnection:Disconnect()
	end

	if state then
		BarrierConnection=workspace.Game.Effects.DescendantAdded:Connect(function(v)
			if v:IsA("Model") and v.Name=="Barrier" then
				task.wait()

				local box=v:FindFirstChild("BoundingBox",true)
				if box and box:IsA("BasePart") then
					box.CanCollide=true
				end
			end
		end)
	end
end)

Tabs.Main:AddSection("Player Modification")

local Toggle = Tabs.Main:AddToggle("Noclip", {Title = "Noclip", Default = false })

Toggle:OnChanged(function(value)
	DConfiguration.Main.Noclip = value

	while DConfiguration.Main.Noclip and wait(0.1) do
		DFunctions.Noclip()
	end
end)

Options.Noclip:SetValue(false)

local FLYING = false
local velocityHandlerName = "VelocityHandler"
local gyroHandlerName = "GyroHandler"
local mfly1, mfly2
local currentCharacter

local function getRoot(character)
	return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
end

local function unmobilefly(player)
	pcall(function()
		FLYING = false
		local character = player.Character
		if character then
			local root = getRoot(character)
			if root then
				local velocityHandler = root:FindFirstChild(velocityHandlerName)
				local gyroHandler = root:FindFirstChild(gyroHandlerName)

				if velocityHandler then
					velocityHandler:Destroy()
				end

				if gyroHandler then
					gyroHandler:Destroy()
				end

				local humanoid = character:FindFirstChildWhichIsA("Humanoid")
				if humanoid then
					humanoid.PlatformStand = false
				end
			end
		end

		if mfly1 then
			mfly1:Disconnect()
		end

		if mfly2 then
			mfly2:Disconnect()
		end
	end)
end

local function mobilefly(player, vfly)
	unmobilefly(player)
	FLYING = true

	local character = player.Character
	local root = getRoot(character)

	if character and root then
		local camera = workspace.CurrentCamera
		local v3none = Vector3.new()
		local v3zero = Vector3.new(0, 0, 0)
		local v3inf = Vector3.new(9e9, 9e9, 9e9)

		local controlModule = require(player.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
		local bv = Instance.new("BodyVelocity")
		bv.Name = velocityHandlerName
		bv.Parent = root
		bv.MaxForce = v3zero
		bv.Velocity = v3zero

		local bg = Instance.new("BodyGyro")
		bg.Name = gyroHandlerName
		bg.Parent = root
		bg.MaxTorque = v3inf
		bg.P = 1000
		bg.D = 2

		mfly1 = player.CharacterAdded:Connect(function()
			unmobilefly(player)
			currentCharacter = player.Character
			mobilefly(player, vfly)
		end)

		mfly2 = RunService.RenderStepped:Connect(function()
			root = getRoot(player.Character)
			camera = workspace.CurrentCamera
			if player.Character:FindFirstChildWhichIsA("Humanoid") and root and root:FindFirstChild(velocityHandlerName) and root:FindFirstChild(gyroHandlerName) then
				local humanoid = player.Character:FindFirstChildWhichIsA("Humanoid")
				local VelocityHandler = root:FindFirstChild(velocityHandlerName)
				local GyroHandler = root:FindFirstChild(gyroHandlerName)

				if VelocityHandler and GyroHandler then
					VelocityHandler.MaxForce = v3inf
					GyroHandler.MaxTorque = v3inf

					if not vfly and humanoid then
						humanoid.PlatformStand = false
					end

					GyroHandler.CFrame = camera.CoordinateFrame
					VelocityHandler.Velocity = v3none

					local direction = controlModule:GetMoveVector()
					if direction.X ~= 0 or direction.Z ~= 0 then
						local moveVector = Vector3.new(direction.X, 0, direction.Z).unit
						local rightVector = camera.CFrame.RightVector
						local forwardVector = camera.CFrame.LookVector

						local flyDirection = (rightVector * moveVector.X - forwardVector * moveVector.Z).unit

						VelocityHandler.Velocity = flyDirection * (_G.flySpeed * 20)
						RunService.RenderStepped:Wait()
					end
				end
			end
		end)
	end
end

local function toggleFly(player, toggleValue)
	if toggleValue then
		mobilefly(player, true)
	else
		unmobilefly(player)
	end
end

_G.Fly = false

local function flyLoop()
	while wait(10) do
		if _G.Fly then
			local player = LocalPlayer
			if player and player.Character then
				mobilefly(player, true)
			end
		end
	end
end

local FlyButtonToggle = Tabs.Main:AddToggle("FlyButtonToggle", {Title = "Fly (Button)", Default = false})

FlyButtonToggle:OnChanged(function(State)
	if State then
		local currentScale = DConfiguration.Settings.GuiScale.Fly or 0
		DFunctions.CreateButton("FlyButton", "Fly: OFF", 0.15 + currentScale, 0.1 + currentScale, function(btn)
			_G.Fly = not _G.Fly
			toggleFly(LocalPlayer, _G.Fly)

			if _G.Fly then
				btn.Text = "Fly: ON"
			else
				btn.Text = "Fly: OFF"
			end
		end)
	else
		DFunctions.DestroyButton("FlyButton")
		_G.Fly = false
		toggleFly(LocalPlayer, false)
	end
end)

Tabs.Main:AddInput("FlyButtonSize", {
	Title = "Fly Gui Size",
	Default = tostring(DConfiguration.Settings.GuiScale.Fly or 0),
	Placeholder = "0",
	Numeric = true, 
	Finished = false, 
	Callback = function(Value)
		local num = tonumber(Value)
		if num then
			DConfiguration.Settings.GuiScale.Fly = num * 0.01
		else
			DConfiguration.Settings.GuiScale.Fly = 0
		end

		local currentScale = DConfiguration.Settings.GuiScale.Fly or 0
		DFunctions.UpdateButton("FlyButton", 0.15 + currentScale, 0.1 + currentScale)
	end
})

_G.flySpeed = 20 

local FlySpeedInput = Tabs.Main:AddInput("FlySpeedInput", {
	Title = "Fly Speed",
	Default = tostring(_G.flySpeed),
	Placeholder = "Enter fly speed",
	Numeric = true,
	Finished = false,
	Callback = function(Value)
		_G.flySpeed = tonumber(Value) or 20
	end
})

task.spawn(flyLoop)

task.wait(Duration)

local TasSec = Tabs.Main:AddSection("TAS")

TasSec:AddDropdown("TASMode", {
	Title = "Play Mode",
	Values = {"Single", "Loop"},
	Default = "Single",
	Callback = function(Value)
		_G.TAS_Data.Mode = Value
	end
})

local RecToggle = TasSec:AddToggle("RecButtonToggle", {Title = "Show Rec Button", Default = false})
RecToggle:OnChanged(function(State)
	if State then
		local s = DConfiguration.Settings and DConfiguration.Settings.GuiScale and DConfiguration.Settings.GuiScale.TAS_Rec or 0
		if DFunctions and DFunctions.UpdateButton then
			DFunctions.UpdateButton("TAS_Rec", 0.15 + s, 0.1 + s)
		end
	else
		if DFunctions and DFunctions.DestroyButton then
			DFunctions.DestroyButton("TAS_Rec")
		end
	end
end)

local s = DConfiguration.Settings and DConfiguration.Settings.GuiScale and DConfiguration.Settings.GuiScale.TAS_Rec or 0
DFunctions.CreateButton("TAS_Rec", "Rec: OFF", 0.15 + s, 0.1 + s, function(btn)
	if not _G.TAS_Data.Run then
		_G.TAS_Lib.StartRec()
		btn.Text = "Rec: ON"
		btn.TextColor3 = Color3.fromRGB(255, 100, 100)
	else
		_G.TAS_Data.Run = false
		btn.Text = "Rec: OFF"
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
end)
TasSec:AddInput("TASRecSize", {
	Title = "Rec Button Size",
	Default = tostring(DConfiguration.Settings.GuiScale.TAS_Rec or 0),
	Placeholder = "0",
	Numeric = true,
	Finished = false,
	Callback = function(Value)
		local num = tonumber(Value) or 0
		DConfiguration.Settings.GuiScale.TAS_Rec = num * 0.01
		local s = DConfiguration.Settings.GuiScale.TAS_Rec
		DFunctions.UpdateButton("TAS_Rec", 0.15 + s, 0.1 + s)
	end
})

local ClearToggle = TasSec:AddToggle("ClearButtonToggle", {Title = "Show Clear Button", Default = false})
ClearToggle:OnChanged(function(State)
	if State then
		local s = DConfiguration.Settings.GuiScale.TAS_Clear or 0
		DFunctions.CreateButton("TAS_Clear", "Clear", 0.15 + s, 0.1 + s, function(btn) 
			_G.TAS_Data.Run = false 
			_G.TAS_Data.Playing = false
			_G.TAS_Data.Frames = {}

			btn.Text = "Cleared!"
			btn.TextColor3 = Color3.fromRGB(255, 200, 0)

			local pg = game:GetService("Players").LocalPlayer.PlayerGui
			local recGui = pg:FindFirstChild("TAS_Rec")
			if recGui then 
				local b = recGui:FindFirstChild("TAS_Rec"):FindFirstChildOfClass("TextButton")
				if b then b.Text = "Rec: OFF" b.TextColor3 = Color3.fromRGB(255, 255, 255) end
			end
			local playGui = pg:FindFirstChild("TAS_Play")
			if playGui then 
				local b = playGui:FindFirstChild("TAS_Play"):FindFirstChildOfClass("TextButton")
				if b then b.Text = "Play: OFF" b.TextColor3 = Color3.fromRGB(255, 255, 255) end
			end

			task.wait(1)
			btn.Text = "Clear"
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		end)
	else
		DFunctions.DestroyButton("TAS_Clear")
	end
end)

TasSec:AddInput("TASClearSize", {
	Title = "Clear Button Size",
	Default = tostring(DConfiguration.Settings.GuiScale.TAS_Clear or 0),
	Placeholder = "0",
	Numeric = true,
	Finished = false,
	Callback = function(Value)
		local num = tonumber(Value) or 0
		DConfiguration.Settings.GuiScale.TAS_Clear = num * 0.01
		local s = DConfiguration.Settings.GuiScale.TAS_Clear
		DFunctions.UpdateButton("TAS_Clear", 0.15 + s, 0.1 + s)
	end
})

local PlayToggle = TasSec:AddToggle("PlayButtonToggle", {Title = "Show Play Button", Default = false})
PlayToggle:OnChanged(function(State)
	if State then
		local s = DConfiguration.Settings.GuiScale.TAS_Play or 0
		DFunctions.CreateButton("TAS_Play", "Play: OFF", 0.15 + s, 0.1 + s, function(btn)
			if _G.TAS_Data.Playing then
				_G.TAS_Data.Playing = false
				btn.Text = "Play: OFF"
				btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			else
				btn.Text = "Play: ON"
				btn.TextColor3 = Color3.fromRGB(100, 255, 100)
				_G.TAS_Lib.Play()
				task.spawn(function()
					while _G.TAS_Data.Playing do task.wait(0.1) end
					btn.Text = "Play: OFF"
					btn.TextColor3 = Color3.fromRGB(255, 255, 255)
				end)
			end
		end)
	else
		DFunctions.DestroyButton("TAS_Play")
	end
end)

TasSec:AddInput("TASPlaySize", {
	Title = "Play Button Size",
	Default = tostring(DConfiguration.Settings.GuiScale.TAS_Play or 0),
	Placeholder = "0",
	Numeric = true,
	Finished = false,
	Callback = function(Value)
		local num = tonumber(Value) or 0
		DConfiguration.Settings.GuiScale.TAS_Play = num * 0.01
		local s = DConfiguration.Settings.GuiScale.TAS_Play
		DFunctions.UpdateButton("TAS_Play", 0.15 + s, 0.1 + s)
	end
})

-- Combat

Tabs.Combat:AddSection("Nextbot Modification")

local Toggle = Tabs.Combat:AddToggle("AntiNextbotToggle", {Title = "Anti Nextbot Toggle", Default = false })

Toggle:OnChanged(function(value)
	DConfiguration.Combat.AntiNextbot = value

	while DConfiguration.Combat.AntiNextbot and wait(0.1) do
		task.spawn(DFunctions.AntiNextbot)
	end
end)

local Dropdown = Tabs.Combat:AddDropdown("AntiBotTeleport", {
	Title = "Anti Nextbot Teleport Type",
	Values = {"Spawn", "Players"},
	Multi = false,
	Default = 1,
})

Dropdown:OnChanged(function(Value)
	DConfiguration.Combat.AntiNextbotType = Value
end)

Tabs.Combat:AddInput("NextbotDistance", {
	Title = "Anti Nextbot Distance",
	Default = 15,
	Placeholder = "Number",
	Numeric = false, 
	Finished = false, 
	Callback = function(Value)
		DConfiguration.Combat.AntiNextbotRange = tonumber(Value) or 15 
	end
})

wait(Duration)

-- Misc

Tabs.Misc:AddSection("Player Adjustments")

Tabs.Misc:AddInput("PlayerSpeed", {
	Title = "Player Speed",
	Description = "",
	Default = "1500",
	Placeholder = "Speed Number",
	Numeric = false, 
	Finished = false, 
	Callback = function(Value)
		DConfiguration.Misc.PlayerAdjustment.Update.RealSpeed = tonumber(Value) or 1500
		DConfiguration.Misc.PlayerAdjustment.Saved.RealSpeed = tonumber(Value) or 1500
	end
})

Tabs.Misc:AddInput("PlayerJump", {
	Title = "Player Jump",
	Description = "",
	Default = "3",
	Placeholder = "Jump Number",
	Numeric = false, 
	Finished = false, 
	Callback = function(Value)
		DConfiguration.Misc.PlayerAdjustment.Update.RealJumpHeight = tonumber(Value) or 3
		DConfiguration.Misc.PlayerAdjustment.Saved.RealJumpHeight = tonumber(Value) or 3
	end
})

Tabs.Misc:AddInput("PlayerStrafeAcceleration", {
	Title = "Player Strafe Acceleration",
	Description = "",
	Default = "182",
	Placeholder = "Number",
	Numeric = false, 
	Finished = false, 
	Callback = function(Value)
		DConfiguration.Misc.PlayerAdjustment.Update.AirStrafe = tonumber(Value) or 182
		DConfiguration.Misc.PlayerAdjustment.Saved.AirStrafe = tonumber(Value) or 182
	end
})

Tabs.Misc:AddParagraph({
	Title = " ",
	Content = ""
})

local Toggle = Tabs.Misc:AddToggle("PlayerJumpPower", {Title = "Jump Power Toggle", Default = false })

Toggle:OnChanged(function(State)
	DConfiguration.Misc.Humanoids.OriginalJumpHeight = State

	while DConfiguration.Misc.Humanoids.OriginalJumpHeight and wait(0.1) do
		local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
		if not UseOriginalJump and humanoid then
			humanoid.UseJumpPower = false
			humanoid.JumpPower = 20
		end

		if LocalPlayer.Character and humanoid then
			humanoid.UseJumpPower = true
			humanoid.JumpPower = DConfiguration.Misc.Humanoids.JP
		end
	end
end)

Tabs.Misc:AddInput("PlayerJumpPower", {
	Title = "Player Jump Power",
	Default = "20",
	Placeholder = "Jump Number",
	Numeric = false, 
	Finished = false, 
	Callback = function(Value)
		DConfiguration.Misc.Humanoids.JP = tonumber(Value) or 20
	end
})

local Toggle = Tabs.Misc:AddToggle("PlayerWalkspeed", {Title = "Walkspeed Toggle", Default = false })

Toggle:OnChanged(function(State)
	DConfiguration.Misc.Humanoids.WalkspeedCF = State

	while DConfiguration.Misc.Humanoids.WalkspeedCF and wait(0.01) do
		local hb = RunService.Heartbeat
		local speaker = game.Players.LocalPlayer
		local chr = speaker.Character
		local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
		local delta = hb:Wait()

		if chr and hum.MoveDirection.Magnitude > 0 then
			chr:TranslateBy(hum.MoveDirection * DConfiguration.Misc.Humanoids.CF * delta * 10)
		end
	end
end)

Tabs.Misc:AddInput("PlayerWalkCf", {
	Title = "Player Walkspeed",
	Default = "5",
	Placeholder = "Walk Number",
	Numeric = false, 
	Finished = false, 
	Callback = function(Value)
		DConfiguration.Misc.Humanoids.CF = tonumber(Value) or 5
	end
})

Tabs.Misc:AddSection("Utilities")

local Toggle = Tabs.Misc:AddToggle("LagSwitch", {Title = "Lag Switch (Button)", Default = false})

Toggle:OnChanged(function(State)
	if State then
		DFunctions.CreateButton("LagSwitchButton", "Start Lag", 0.15 + DConfiguration.Settings.GuiScale.LagSwitch, 0.1 + DConfiguration.Settings.GuiScale.LagSwitch, function(btn)
			task.spawn(function() 
				DFunctions.StartLag(DConfiguration.Misc.Utilities.LagSwitch.MSDelay) 
			end)
			btn.Text = "..."
			wait(0.1)
			btn.Text = "Start Lag"
		end)
	else
		DFunctions.DestroyButton("LagSwitchButton")
	end
end)

Tabs.Misc:AddInput("LagSwitchButtonSize", {
	Title = "Lag Switch Gui Size",
	Default = tostring(DConfiguration.Settings.GuiScale.LagSwitch),
	Placeholder = "Size",
	Numeric = true,
	Finished = false,
	Callback = function(Value)
		local num = tonumber(Value)
		if num then
			DConfiguration.Settings.GuiScale.LagSwitch = num * 0.01
		else
			DConfiguration.Settings.GuiScale.LagSwitch = 0
		end
		DFunctions.UpdateButton("LagSwitchButton", 0.15 + DConfiguration.Settings.GuiScale.LagSwitch, 0.1 + DConfiguration.Settings.GuiScale.LagSwitch)
	end
})

Tabs.Misc:AddInput("DelayMS", {
	Title = "Delay MS",
	Default = "200",
	Placeholder = "Value",
	Numeric = false, -- Only allows numbers
	Finished = false, -- Only calls callback when you press enter
	Callback = function(Value)
		DConfiguration.Misc.Utilities.LagSwitch.MSDelay = tonumber(Value) or 200
	end
})

local Dropdown = Tabs.Misc:AddDropdown("LagMode", {
	Title = "Lag Mode",
	Values = {"Normal", "Demon", "FastFlag"},
	Multi = false,
	Default = 1,
})

Dropdown:OnChanged(function(Value)
	DConfiguration.Misc.Utilities.LagSwitch.Mode = Value
end)

Tabs.Misc:AddParagraph({
	Title = " ",
	Content = ""
})

local Toggle = Tabs.Misc:AddToggle("AdjustBounce", {Title = "Modify Bounce", Default = false })

Toggle:OnChanged(function(State)
	DConfiguration.Misc.Utilities.BounceModification.Enabled = State

	while DConfiguration.Misc.Utilities.BounceModification.Enabled and wait(0.1) do
		task.spawn(DFunctions.BounceFunction)
	end
end)

Tabs.Misc:AddInput("PlayerBounce", {
	Title = "Player Bounce",
	Default = "80",
	Placeholder = "Bounce Number",
	Numeric = false,
	Finished = false, 
	Callback = function(Value)
		DConfiguration.Misc.Utilities.BounceModification.DefaultBounce = tonumber(Value) or 80
	end
})

Tabs.Misc:AddInput("EmoteBounce", {
	Title = "Emote Bounce",
	Default = "120",
	Placeholder = "Bounce Number",
	Numeric = false, 
	Finished = false, 
	Callback = function(Value)
		DConfiguration.Misc.Utilities.BounceModification.EmoteBounce = tonumber(Value) or 120
	end
})

Tabs.Misc:AddToggle("EnableEfling", {
	Title = "Efling Modified",
	Default = false,

	Callback = function(v)
		DConfiguration.Misc.MovementModification.Efling.Enabled = v
	end
})

local function isValidEdge(part, root)
	local Config = DConfiguration.Misc.MovementModification.Efling
	if part:IsA("WedgePart") then
		return false
	end

	local size = part.Size
	if size.Magnitude <
		Config.MinModelSize then
		return false
	end

	if size.X <= Config.MinEdgeWidth or size.Z <= Config.MinEdgeWidth then
		return false
	end

	if size.Y <= 2 then
		return false
	end

	local localPos = part.CFrame:PointToObjectSpace(root.Position)
	local sx = size.X / 2
	local sz = size.Z / 2
	local hitX = math.abs(localPos.X) >= (sx - 0.15)
	local hitZ = math.abs(localPos.Z) >= (sz - 0.15)
	if not (hitX or hitZ) then
		return false
	end

	local centerDist =Vector2.new(localPos.X,localPos.Z).Magnitude
	if centerDist < 2 then
		return false
	end

	local edgeHeight =root.Position.Y - part.Position.Y
	if edgeHeight < Config.MinEdgeHeight then
		return false
	end

	return true
end

local function fling(root)
	local Config = DConfiguration.Misc.MovementModification.Efling
	if Config.Cooldown then
		return
	end

	Config.Cooldown = true
	local vel = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = Vector3.new(vel.X, Config.Power, vel.Z)

	task.delay(0.25, function()
		Config.Cooldown = false
	end
	)
end

local function setupCharacter(char)
	local root = char:WaitForChild("HumanoidRootPart")
	root.Touched:Connect(function(hit)
		local Config = DConfiguration.Misc.MovementModification.Efling

		if not Config.Enabled then
			return
		end

		if not hit or not hit:IsA("BasePart") then
			return
		end

		if hit:IsDescendantOf(char) then
			return
		end

		local speed = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude

		if speed < 26 then
			return
		end

		if isValidEdge(hit, root) then
			fling(root)
		end
	end)
end

if player.Character then
	setupCharacter(player.Character)
end

player.CharacterAdded:Connect(setupCharacter)

Tabs.Misc:AddParagraph({
	Title = " ",
	Content = ""
})

do
	local PlatData = {
		Enabled = false,
		Size = 10,
		Transparency = 0.1,
		List = {}
	}

	local function ClearPlates()
		for _, p in pairs(PlatData.List) do
			if p and p.Parent then p:Destroy() end
		end
		PlatData.List = {}
	end

	local function GetFolder()
		local g = workspace:FindFirstChild("Game")
		local m = g and g:FindFirstChild("Map")
		local p = m and m:FindFirstChild("Parts")
		return p and p:FindFirstChild("ImmovableProps")
	end

	local function CreatePlates()
		ClearPlates()
		if not PlatData.Enabled then return end
		local folder = GetFolder()
		if not folder then return end

		for _, obj in pairs(folder:GetChildren()) do
			if obj.Name == "Cactus1" or obj.Name == "Cactus2" then
				local pos, size
				if obj:IsA("Model") then
					local cf, s = obj:GetBoundingBox()
					pos, size = cf.Position, s
				elseif obj:IsA("BasePart") then
					pos, size = obj.Position, obj.Size
				end

				if pos and size then
					local p = Instance.new("Part")
					p.Name = "PhantomWyrm"
					p.Size = Vector3.new(PlatData.Size, 1, PlatData.Size)
					p.Anchored, p.CanCollide = true, true
					p.Material = Enum.Material.Neon
					p.Transparency = PlatData.Transparency
					p.Color = Color3.fromRGB(0, 255, 150)
					p.Position = pos + Vector3.new(0, (size.Y / 2) + 0.5, 0)
					p.Parent = workspace
					table.insert(PlatData.List, p)
				end
			end
		end
	end

	Tabs.Misc:AddToggle("CactusToggle", {
		Title = "Cactus Platform",
		Default = false,
		Callback = function(Value)
			PlatData.Enabled = Value
			CreatePlates()
		end
	})

	Tabs.Misc:AddInput("CactusTransInput", {
		Title = "Platform Transparency (0-1)",
		Description = "make platforms invisible 3-5",
		Default = "0.5",
		Numeric = true,
		Finished = true,
		Callback = function(Value)
			local num = tonumber(Value) or 0.5
			PlatData.Transparency = math.clamp(num, 0, 1)
			for _, p in pairs(PlatData.List) do
				if p and p.Parent then p.Transparency = PlatData.Transparency end
			end
		end
	})

	Tabs.Misc:AddInput("CactusSizeInput", {
		Title = "Platform Size",
		Default = "12",
		Numeric = true,
		Finished = true,
		Callback = function(Value)
			PlatData.Size = tonumber(Value) or 12
			if PlatData.Enabled then CreatePlates() end
		end
	})

	task.spawn(function()
		while task.wait(3) do
			if PlatData.Enabled and #PlatData.List == 0 then
				CreatePlates()
			end
		end
	end)
end

Tabs.Misc:AddSection("Camera Adjustment")

if not _G.Hyperion then
	_G.Hyperion = {}
end
_G.Hyperion.ResolutionValue = 1
local a = workspace.CurrentCamera
if _G.HyperionCameraLoop == nil then
	_G.HyperionCameraLoop =
		game:GetService("RunService").RenderStepped:Connect(
			function()
				local b = _G.Hyperion.ResolutionValue
				if b and b ~= 1 then
					a.CFrame = a.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, b, 0, 0, 0, 1)
				end
			end
		)
end

Tabs.Misc:AddInput("PhantomFOV", {
	Title = "Stretch",
	Description = "write 0.8 or 0.1",
	Default = "1",
	Placeholder = "",
	Numeric = false,
	Finished = false,
	Callback = function(c)
		local d = tonumber(c)
		if d and d > 0 then
			_G.Hyperion.ResolutionValue = d
		else
			_G.Hyperion.ResolutionValue = 1
		end
	end
}
)

_G.FinalStrictFOV = 90

if _G.StrictFovLoop then
	_G.StrictFovLoop:Disconnect()
	_G.StrictFovLoop = nil
end

if _G.FovChangedConnection then
	_G.FovChangedConnection:Disconnect()
	_G.FovChangedConnection = nil
end

local camera = workspace.CurrentCamera

local function enforceFov()
	if camera and camera.FieldOfView ~= _G.FinalStrictFOV then
		camera.FieldOfView = _G.FinalStrictFOV
	end
end

local mt = getrawmetatable(game)
local oldNewIndex = mt.__newindex
setreadonly(mt, false)

mt.__newindex = newcclosure(function(self, property, value)
	if self == workspace.CurrentCamera and property == "FieldOfView" then
		return oldNewIndex(self, property, _G.FinalStrictFOV)
	end
	return oldNewIndex(self, property, value)
end)

setreadonly(mt, true)

if camera then
	camera.FieldOfView = _G.FinalStrictFOV
	_G.FovChangedConnection = camera:GetPropertyChangedSignal("FieldOfView"):Connect(enforceFov)
end

Tabs.Misc:AddInput("PlayerFOV", {
	Title = "Player FOV (Optimized Lock)",
	Description = "Minimum 30 │ Max 120",
	Default = "70",
	Placeholder = "FOV Number",
	Numeric = true,
	Finished = false,
	Callback = function(text)
		local number = tonumber(text)
		if number and number >= 30 and number <= 120 then
			_G.FinalStrictFOV = number
			if workspace.CurrentCamera then
				workspace.CurrentCamera.FieldOfView = number
			end
		end
	end
})

Tabs.Misc:AddSection("Game Automations")

local Toggle = Tabs.Misc:AddToggle("MacroMode", {Title = "Macro Button Toggle", Default = false})

Toggle:OnChanged(function(State)
	if State then
		DFunctions.CreateButton("MacroButton1", "Emote or Crouch", 0.15, 0.1, function()
			game:GetService("ReplicatedStorage").Events.Emote:FireServer(DConfiguration.Misc.GameAutomation.SelectedPrimary)
			LocalPlayer.Character.Communicator:InvokeServer("Crouching", true)
		end)

		DFunctions.CreateButton("MacroButton2", "Uncrouch", 0.15, 0.1, function()
			LocalPlayer.Character.Communicator:InvokeServer("Crouching", false)
		end)
	else
		DFunctions.DestroyButton("MacroButton1")
		DFunctions.DestroyButton("MacroButton2")
	end
end)

Tabs.Misc:AddInput("MacroButton1Size", {
	Title = "Macro Button 1 Size",
	Default = tostring(DConfiguration.Settings.GuiScale.MacroButton1),
	Placeholder = "0",
	Numeric = true, 
	Finished = false, 
	Callback = function(Value)
		local num = tonumber(Value)
		if num then
			DConfiguration.Settings.GuiScale.MacroButton1 = num * 0.01
		else
			DConfiguration.Settings.GuiScale.MacroButton1 = 0
		end

		DFunctions.UpdateButton("MacroButton1", 0.15 + DConfiguration.Settings.GuiScale.MacroButton1, 0.1 + DConfiguration.Settings.GuiScale.MacroButton1)
	end
})

Tabs.Misc:AddInput("MacroButton2Size", {
	Title = "Macro Button 2 Size",
	Default = tostring(DConfiguration.Settings.GuiScale.MacroButton2),
	Placeholder = "0",
	Numeric = true, 
	Finished = false, 
	Callback = function(Value)
		local num = tonumber(Value)
		if num then
			DConfiguration.Settings.GuiScale.MacroButton2 = num * 0.01
		else
			DConfiguration.Settings.GuiScale.MacroButton2 = 0
		end

		DFunctions.UpdateButton("MacroButton2", 0.15 + DConfiguration.Settings.GuiScale.MacroButton2, 0.1 + DConfiguration.Settings.GuiScale.MacroButton2)
	end
})

local Dropdown = Tabs.Misc:AddDropdown("SelectionEmoteSlot", {
	Title = "Select Emote Slots",
	Values = {"1", "2", "3", "4", "5", "6"},
	Multi = false,
	Default = 1,
})

Dropdown:OnChanged(function(Value)
	DConfiguration.Misc.GameAutomation.SelectedPrimary = Value
end)

Tabs.Misc:AddSection("Movement Modification")

local LP = game.Players.LocalPlayer
local RS = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Cam = workspace.CurrentCamera

getgenv().EasyTrimp = getgenv().EasyTrimp or {
	Enabled = false,
	BaseSpeed = 50,
	ExtraSpeed = 100
}

local ET = getgenv().EasyTrimp

local state = {
	speed = ET.BaseSpeed,
	last = tick(),
	airTick = 0,
	airSum = 0,
	airborne = false,
	bv = nil
}

local function getMeter()
	local ok, v = pcall(function()
		return LP.PlayerGui.Shared.HUD.Overlay.Default.CharacterInfo.Item.Speedometer.Players
	end)
	return ok and v or nil
end

local function cut(n) return math.floor(n * 10) / 10 end

RS.RenderStepped:Connect(function()
	local dt = tick() - state.last
	state.last = tick()

	local ch = LP.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local hum = ch and ch:FindFirstChild("Humanoid")
	if not hrp or not hum then return end

	local inAir = hum.FloorMaterial == Enum.Material.Air
	local spdUI = getMeter()

	if state.airborne and not inAir then
		state.speed = math.max(ET.BaseSpeed, state.speed - 10)
		if ET.Enabled and spdUI then spdUI.Text = cut(state.speed) end
		state.airSum = 0
	end
	state.airborne = inAir

	if ET.Enabled then
		if inAir then
			state.airSum = state.airSum + dt
			state.airTick = state.airTick + dt
			while state.airTick >= 0.04 do
				state.airTick = state.airTick - 0.04
				state.speed = math.min(ET.BaseSpeed + ET.ExtraSpeed, state.speed + 0.1)
			end
		else
			state.airTick, state.airSum = 0, 0
			state.speed = math.max(ET.BaseSpeed, state.speed - (2.5 * dt))
		end

		if state.bv then state.bv:Destroy() end
		local moveDir = Cam.CFrame.LookVector
		moveDir = Vector3.new(moveDir.X, 0, moveDir.Z).Unit

		local bv = Instance.new("BodyVelocity")
		bv.Velocity = moveDir * state.speed
		bv.MaxForce = Vector3.new(4e5, 0, 4e5)
		bv.Parent = hrp
		Debris:AddItem(bv, 0.1)
		state.bv = bv

		if spdUI then spdUI.Text = cut(state.speed) end
	else
		if state.bv then 
			state.bv:Destroy() 
			state.bv = nil 
		end
		state.speed = ET.BaseSpeed
	end
end)

do
	Tabs.Misc:AddToggle("ET_Master", {
		Title = "Easy Trimp", 
		Default = ET.Enabled, 
		Callback = function(v) 
			ET.Enabled = v 
		end
	})

	Tabs.Misc:AddInput("ET_Base", {
		Title = "Base Speed", 
		Default = tostring(ET.BaseSpeed), 
		Numeric = true, 
		Finished = true, 
		Callback = function(v) 
			ET.BaseSpeed = tonumber(v) or 50 
			state.speed = ET.BaseSpeed
		end
	})

	Tabs.Misc:AddInput("ET_Extra", {
		Title = "Extra Speed (Boost)", 
		Default = tostring(ET.ExtraSpeed), 
		Numeric = true, 
		Finished = true, 
		Callback = function(v) 
			ET.ExtraSpeed = tonumber(v) or 100 
		end
	})

	DConfiguration.Settings.GuiScale = DConfiguration.Settings.GuiScale or {}
	DConfiguration.Settings.GuiScale.EasyTrimp = DConfiguration.Settings.GuiScale.EasyTrimp or 0

	Tabs.Misc:AddToggle("ET_BtnShow", {
		Title = "Easy Trimp (Button)", 
		Default = false
	}):OnChanged(function(s)
		if s then 
			local offset = DConfiguration.Settings.GuiScale.EasyTrimp
			DFunctions.CreateButton("ET_Btn", ET.Enabled and "Trimp: ON" or "Trimp: OFF", 0.15 + offset, 0.1 + offset, function(btn) 
				ET.Enabled = not ET.Enabled 
				if btn and btn.Text then
					btn.Text = ET.Enabled and "Trimp: ON" or "Trimp: OFF"
				end
			end)
		else 
			ET.Enabled = false
			DFunctions.DestroyButton("ET_Btn") 
		end
	end)

	Tabs.Misc:AddInput("ET_ButtonSize", {
		Title = "Easy Trimp (Button Size)",
		Default = tostring(DConfiguration.Settings.GuiScale.EasyTrimp / 0.01), 
		Placeholder = "0",
		Numeric = true, 
		Finished = false, 
		Callback = function(Value)
			local num = tonumber(Value)
			DConfiguration.Settings.GuiScale.EasyTrimp = (num or 0) * 0.01
			DFunctions.UpdateButton("ET_Btn", 0.15 + DConfiguration.Settings.GuiScale.EasyTrimp, 0.1 + DConfiguration.Settings.GuiScale.EasyTrimp)
		end
	})
end

Tabs.Misc:AddParagraph({
	Title = " ",
	Content = ""
})

local Toggle = Tabs.Misc:AddToggle("SprintEmoteDash", {Title = "Aggressive Emote Dash", Default = false })

Toggle:OnChanged(function(State)
	DConfiguration.Misc.MovementModification.EmoteModification.AggressiveEmoteDash.Enabled = State

	if not DConfiguration.Misc.MovementModification.EmoteModification.AggressiveEmoteDash.Enabled then
		DConfiguration.Misc.PlayerAdjustment.Debounce.GroundAcceleration = false
		DConfiguration.Misc.PlayerAdjustment.Update.Speed = DConfiguration.Misc.PlayerAdjustment.Saved.Speed
	end
end)

local Dropdown = Tabs.Misc:AddDropdown("SprintEmoteType", {
	Title = "Aggressive Emote Type",
	Values = {"Legit", "Blatant"},
	Multi = false,
	Default = 2,
})

Dropdown:OnChanged(function(Value)
	DConfiguration.Misc.MovementModification.EmoteModification.AggressiveEmoteDash.Type = Value
end)

Tabs.Misc:AddInput("EmoteSpeed", {
	Title = "Aggressive Emote Speed",
	Default = "2000",
	Placeholder = "Emote Speed Number",
	Numeric = false, 
	Finished = false, 
	Callback = function(Value)
		DConfiguration.Misc.MovementModification.EmoteModification.AggressiveEmoteDash.Speed = tonumber(Value) or 2000
	end
})

Tabs.Misc:AddInput("CrouchSpeed", {
	Title = "Aggressive Emote Acceleration (Negative Only)",
	Default = "-2",
	Placeholder = "Acceleration Number",
	Numeric = false, 
	Finished = false, 
	Callback = function(Value)
		DConfiguration.Misc.MovementModification.EmoteModification.AggressiveEmoteDash.Acceleration = tonumber(Value) or 0.2
	end
})

Tabs.Misc:AddParagraph({
	Title = " ",
	Content = ""
})

local Toggle = Tabs.Misc:AddToggle("ModifyEmote", {
	Title = "Modify Emote Movement",
	Default = false
})

local connection

Toggle:OnChanged(function(State)
	DConfiguration.Misc.MovementModification.EmoteModification.ModifyEmote.Enabled = State  

	if connection then
		connection:Disconnect()
		connection = nil
	end

	if not State then return end

	connection = RunService.RenderStepped:Connect(function(dt)
		if not DConfiguration.Misc.MovementModification.EmoteModification.ModifyEmote.Enabled then
			connection:Disconnect()
			connection = nil
			return
		end

		local char = LocalPlayer.Character
		if not char then return end

		local hum = char:FindFirstChildOfClass("Humanoid")
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hum or not hrp then return end

		local moveDir = hum.MoveDirection
		if moveDir.Magnitude <= 0 then return end

		local emoting = char:GetAttribute("Emoting")
		local downed = char:GetAttribute("Downed")
		if not (emoting or downed) then return end

		local targetCF = CFrame.lookAt(
			hrp.Position,
			hrp.Position + moveDir
		)

		local turnSpeed = DConfiguration.Misc.MovementModification.EmoteModification.ModifyEmote.TurnSpeed
		local alpha = math.clamp(turnSpeed * dt * 16, 0, 1)

		hrp.CFrame = hrp.CFrame:Lerp(targetCF, alpha)
	end)
end)

Tabs.Misc:AddInput("EmoteRotation", {
	Title = "Emote Rotation Speed",
	Default = "0.5",
	Placeholder = "Rotation Number",
	Numeric = false, 
	Finished = false, 
	Callback = function(Value)
		DConfiguration.Misc.MovementModification.EmoteModification.ModifyEmote.TurnSpeed = tonumber(Value) or 0.5
	end
})

Tabs.Misc:AddParagraph({
	Title = " ",
	Content = ""
})

local NormalGravity = game.Workspace.Gravity

local Toggle = Tabs.Misc:AddToggle("GravityToggle", {Title = "Gravity Button", Default = false })

Toggle:OnChanged(function(State)
	if State then
		DFunctions.CreateButton("GravityGui", "Gravity: OFF", 0.15 + DConfiguration.Settings.GuiScale.Gravity, 0.1 + DConfiguration.Settings.GuiScale.Gravity, function(btn)
			DConfiguration.Misc.MovementModification.Gravity.FloatingButton = not DConfiguration.Misc.MovementModification.Gravity.FloatingButton
			btn.Text = DConfiguration.Misc.MovementModification.Gravity.FloatingButton and "Gravity: ON" or "Gravity: OFF"
		end)
	else
		DFunctions.DestroyButton("GravityGui")
	end
end)

Tabs.Misc:AddInput("GravityButtonSize", {
	Title = "Gravity Gui Size",
	Default = tostring(DConfiguration.Settings.GuiScale.Gravity),
	Placeholder = "0",
	Numeric = true, 
	Finished = false, 
	Callback = function(Value)
		local num = tonumber(Value)
		if num then
			DConfiguration.Settings.GuiScale.Gravity = num * 0.01
		else
			DConfiguration.Settings.GuiScale.Gravity = 0
		end

		DFunctions.UpdateButton("GravityGui", 0.15 + DConfiguration.Settings.GuiScale.Gravity, 0.1 + DConfiguration.Settings.GuiScale.Gravity)
	end
})


Tabs.Misc:AddInput("GravityAdjust", {
	Title = "Gravity Adjustment",
	Default = "10",
	Placeholder = " Number",
	Numeric = false, 
	Finished = false, 
	Callback = function(Value)
		DConfiguration.Misc.MovementModification.Gravity.Value = tonumber(Value) or  10
	end
})

Tabs.Misc:AddParagraph({
	Title = " ",
	Content = ""
})

local Toggle = Tabs.Misc:AddToggle("BHOPToggle", {Title = "BHOP (Button)", Default = false })

Toggle:OnChanged(function(State)

	if State then
		DFunctions.CreateButton("BHOPGui", "Auto Jump: OFF", 0.15 + DConfiguration.Settings.GuiScale.AutoJump, 0.1 + DConfiguration.Settings.GuiScale.AutoJump, function(btn)
			DConfiguration.Misc.MovementModification.BHOP.FloatingButton = not DConfiguration.Misc.MovementModification.BHOP.FloatingButton
			btn.Text = DConfiguration.Misc.MovementModification.BHOP.FloatingButton and "Auto Jump: ON" or "Auto Jump: OFF"

			while DConfiguration.Misc.MovementModification.BHOP.FloatingButton and wait(0.1) do
				DConfiguration.Misc.MovementModification.BHOP.Enabled = DConfiguration.Misc.MovementModification.BHOP.FloatingButton
			end

			if not DConfiguration.Misc.MovementModification.BHOP.FloatingButton then          
				task.spawn(DFunctions.ResetBHOP)
				wait(0.1)
				task.spawn(DFunctions.ResetBHOP)
				DConfiguration.Misc.MovementModification.BHOP.Enabled = false
			end
		end)
	else
		DFunctions.DestroyButton("BHOPGui")
	end
end)

local Toggle = Tabs.Misc:AddToggle("BHOPJumpButton", {Title = "BHOP (Jump Button)", Default = false })

Toggle:OnChanged(function(State)
	DConfiguration.Misc.MovementModification.BHOP.JumpButton = State
end)

if UserInputService.TouchEnabled then
	local JumpButton = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("TouchGui"):WaitForChild("TouchControlFrame"):FindFirstChild("JumpButton")

	if JumpButton then
		local isJumping = false

		JumpButton.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch and DConfiguration.Misc.MovementModification.BHOP.JumpButton then
				if not isJumping then
					isJumping = true
					DConfiguration.Misc.MovementModification.BHOP.Enabled = true
				end
			end
		end)

		JumpButton.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch and DConfiguration.Misc.MovementModification.BHOP.JumpButton and not DConfiguration.Misc.MovementModification.BHOP.FloatingButton then
				if isJumping then
					isJumping = false
					DConfiguration.Misc.MovementModification.BHOP.Enabled = false
					task.spawn(DFunctions.ResetBHOP)
				end
			end
		end)
	end
end

Tabs.Misc:AddInput("BHOPButtonSize", {
	Title = "BHOP Gui Size",
	Default = tostring(DConfiguration.Settings.GuiScale.AutoJump),
	Placeholder = "0",
	Numeric = true, 
	Finished = false, 
	Callback = function(Value)
		local num = tonumber(Value)
		if num then
			DConfiguration.Settings.GuiScale.AutoJump = num * 0.01
		else
			DConfiguration.Settings.GuiScale.AutoJump = 0
		end

		DFunctions.UpdateButton("BHOPGui", 0.15 + DConfiguration.Settings.GuiScale.AutoJump, 0.1 + DConfiguration.Settings.GuiScale.AutoJump)
	end
})

local Dropdown = Tabs.Misc:AddDropdown("BHOPVersion", {
	Title = "Select BHOP Version",
	Values = {"Acceleration", "Ground Acceleration", "No Acceleration"},
	Multi = false,
	Default = 1,
})

Dropdown:OnChanged(function(Value)
	DConfiguration.Misc.MovementModification.BHOP.Type = Value
end)

local Dropdown = Tabs.Misc:AddDropdown("JumpType", {
	Title = "Select Jump Type",
	Values = {"Simulated", "Nil"},
	Multi = false,
	Default = 1,
})

Dropdown:OnChanged(function(Value)
	DConfiguration.Misc.MovementModification.BHOP.JumpType = Value
end)

Tabs.Misc:AddInput("BHOPAcceleration", {
	Title = "BHOP Acceleration (Negative Only)",
	Default = "-0.1",
	Placeholder = "-1",
	Numeric = false, -- Only allows numbers
	Finished = false, -- Only calls callback when you press enter
	Callback = function(Value)
		DConfiguration.Misc.MovementModification.BHOP.Acceleration = tonumber(Value) or -0.1
	end
})

Tabs.Misc:AddParagraph({
	Title = " ",
	Content = ""
})

local Toggle = Tabs.Misc:AddToggle("BHOPAutoAccelerate", {Title = "Auto Acceleration (Legit)", Default = false })

Toggle:OnChanged(function(State)
	DConfiguration.Misc.MovementModification.BHOP.AutoAcceleration = State
end)

Tabs.Misc:AddInput("BHOPAcceleration", {
	Title = "Max Speed Acceleration",
	Default = "70",
	Placeholder = "70",
	Numeric = false, -- Only allows numbers
	Finished = false, -- Only calls callback when you press enter
	Callback = function(Value)
		DConfiguration.Misc.MovementModification.BHOP.MaxSpeed = tonumber(Value) or 70
	end
})

RunService.Heartbeat:Connect(function()
	local stop = false

	if DConfiguration.Misc.MovementModification.BHOP.Enabled or DConfiguration.Misc.MovementModification.BHOP.Keybind then
		task.spawn(DFunctions.BHOPFunction)
		stop = true
	end

	if DConfiguration.Misc.MovementModification.Gravity.FloatingButton or DConfiguration.Misc.MovementModification.Gravity.Keybind then
		game.Workspace.Gravity = DConfiguration.Misc.MovementModification.Gravity.Value
	else
		game.Workspace.Gravity = NormalGravity
	end

	if not stop then
		if DConfiguration.Misc.MovementModification.EmoteModification.AggressiveEmoteDash.Enabled then
			task.spawn(DFunctions.SprintEmoteDash)
		end
	end

	RunService.RenderStepped:Wait()
end)

-- Visual



local ItemsFolder = ReplicatedStorage.Items

local Folder = Instance.new("Folder", ItemsFolder)
Folder.Name = "D-Folder"

local ChangeEmote1 = ""
local ChangeEmote2 = ""

local ChangeCosmetics1 = "" 
local ChangeCosmetics2 = ""

function Normalize(input)
	return input:lower():gsub("%s+", "") 
end

function FindRealName(folder, userInput)
	local normalizedInput = Normalize(userInput)
	for _, item in ipairs(folder:GetChildren()) do
		if Normalize(item.Name) == normalizedInput then
			return item.Name
		end
	end
	return nil
end

function ChangeCosmetics(Name1, Name2)
	local Cosmetics = ReplicatedStorage.Items.Cosmetics
	local RealName1 = FindRealName(Cosmetics, Name1)
	local RealName2 = FindRealName(Cosmetics, Name2)

	if RealName1 and RealName2 then
		local I = Cosmetics:FindFirstChild(RealName1)
		local V = Cosmetics:FindFirstChild(RealName2)
		if I and V then
			I.Name = RealName2
			task.wait()
			V.Name = RealName1
		end
	end
end

function ChangeEmotes(Name1, Name2)
	local Emotes = ReplicatedStorage.Items.Emotes
	local RealName1 = FindRealName(Emotes, Name1)
	local RealName2 = FindRealName(Emotes, Name2)

	if RealName1 and RealName2 then
		local I = Emotes:FindFirstChild(RealName1)
		local V = Emotes:FindFirstChild(RealName2)
		if I and V then
			I.Name = RealName2
			task.wait()
			V.Name = RealName1
		end
	end
end

Tabs.Visual:AddSection("Emote Changer")

local Input = Tabs.Visual:AddInput("EmoteChange1", {
	Title = "Current Emote",
	Default = "",
	Placeholder = "BoldMarch",
	Numeric = false, -- Only allows numbers
	Finished = false, -- Only calls callback when you press enter
	Callback = function(Value)
		ChangeEmote1 = Value
	end
})

local Input = Tabs.Visual:AddInput("EmoteChange2", {
	Title = "Select Emote",
	Default = "",
	Placeholder = "RockinStride",
	Numeric = false, -- Only allows numbers
	Finished = false, -- Only calls callback when you press enter
	Callback = function(Value)
		ChangeEmote2 = Value
	end
})

Tabs.Visual:AddButton({
	Title = "Change Emote",
	Description = "" ,
	Callback = function()
		task.spawn(function()
			ChangeEmotes(ChangeEmote1, ChangeEmote2)
		end)
	end
})

Tabs.Visual:AddSection("Skin/Cosmetics Changer")

local Input = Tabs.Visual:AddInput("CosmeticsChange1", {
	Title = "Current Cosmetics",
	Default = "",
	Placeholder = "HeartSkaters",
	Numeric = false, -- Only allows numbers
	Finished = false, -- Only calls callback when you press enter
	Callback = function(Value)
		ChangeCosmetics1 = Value
	end
})

local Input = Tabs.Visual:AddInput("CosmeticsChange2", {
	Title = "Select Cosmetics",
	Default = "",
	Placeholder = "ToxicInferno",
	Numeric = false, -- Only allows numbers
	Finished = false, -- Only calls callback when you press enter
	Callback = function(Value)
		ChangeCosmetics2 = Value
	end
})


Tabs.Visual:AddButton({
	Title = "Change Cosmetics",
	Description = "" ,
	Callback = function()
		task.spawn(function()
			ChangeCosmetics(ChangeCosmetics1, ChangeCosmetics2)
		end)
	end
})

Tabs.Misc:AddSection("Auto Crouch")

do
	local _acEnabled = false
	local _acDelay   = 0.3
	local _acMode    = "Rapid"
	local _acThread  = nil

	local function stopAutoCrouch()
		_acEnabled = false
		if _acThread then task.cancel(_acThread); _acThread = nil end
		pcall(function()
			local char = LocalPlayer.Character
			if char and char:FindFirstChild("Communicator") then
				char.Communicator:InvokeServer("Crouching", false)
			end
		end)
	end

	local function startAutoCrouch()
		if _acThread then task.cancel(_acThread) end
		_acThread = task.spawn(function()
			while _acEnabled do
				pcall(function()
					local char = LocalPlayer.Character
					if not char then return end
					local comm = char:FindFirstChild("Communicator")
					local hum  = char:FindFirstChildOfClass("Humanoid")
					if not comm or not hum then return end

					if _acMode == "Rapid" then
						comm:InvokeServer("Crouching", true)
						task.wait(_acDelay)
						comm:InvokeServer("Crouching", false)
					elseif _acMode == "Ground" then
						comm:InvokeServer("Crouching", hum.FloorMaterial ~= Enum.Material.Air)
					elseif _acMode == "Air" then
						comm:InvokeServer("Crouching", hum.FloorMaterial == Enum.Material.Air)
					elseif _acMode == "Hold" then
						comm:InvokeServer("Crouching", true)
					end
				end)
				-- Dipindahkan ke sini agar selalu tereksekusi dan mencegah crash/freeze
				task.wait(_acDelay) 
			end
		end)
	end

	local ACToggle = Tabs.Misc:AddToggle("AutoCrouchButton", { Title = "Auto Crouch (Button)", Default = false })
	ACToggle:OnChanged(function(State)
		if State then
			DFunctions.CreateButton("AutoCrouchBtn",
				"Auto Crouch: OFF",
				0.15 + DConfiguration.Settings.GuiScale.AutoCrouch,
				0.1  + DConfiguration.Settings.GuiScale.AutoCrouch,
				function(btn)
					_acEnabled = not _acEnabled
					btn.Text   = _acEnabled and "Auto Crouch: ON" or "Auto Crouch: OFF"
					if _acEnabled then startAutoCrouch() else stopAutoCrouch() end
				end,
				false, Enum.KeyCode.Z)
		else
			stopAutoCrouch()
			DFunctions.DestroyButton("AutoCrouchBtn")
		end
	end)

	Tabs.Misc:AddDropdown("AutoCrouchMode", {
		Title = "Crouch Mode",
		Values = { "Rapid", "Ground", "Air", "Hold" },
		Multi = false,
		Search = false,
		Default = "Rapid",
	}):OnChanged(function(Value) _acMode = Value end)

	Tabs.Misc:AddInput("AutoCrouchDelay", {
		Title = "Crouch Interval (seconds)",
		Default = "0.3",
		Placeholder = "0.3",
		Numeric = false,
		Finished = false,
		Callback = function(Value) _acDelay = tonumber(Value) or 0.3 end,
	})

	Tabs.Misc:AddInput("AutoCrouchGuiSize", {
		Title = "Auto Crouch Gui Size",
		Default = tostring(DConfiguration.Settings.GuiScale.AutoCrouch),
		Placeholder = "0",
		Numeric = true,
		Finished = false,
		Callback = function(Value)
			local num = tonumber(Value)
			DConfiguration.Settings.GuiScale.AutoCrouch = num and num * 0.01 or 0
			DFunctions.UpdateButton("AutoCrouchBtn",
				0.15 + DConfiguration.Settings.GuiScale.AutoCrouch,
				0.1  + DConfiguration.Settings.GuiScale.AutoCrouch)
		end,
	})
end

-- Old folder

local Dropdown = Tabs.Folder:AddDropdown("SelectEmote", {
	Title = "Select Emote",
	Values = {"1","2","3","4","5","6"},
	Multi = false,
	Default = "1",
	Callback = function(v)
		_G.EmoteNumber = tonumber(v)
	end
})

local Loaded = false

Tabs.Folder:AddToggle("MacroToggle", { Title = "Enable Macro", Default = false,
	Callback = function(state)
		if state then
			if not Loaded then
				Loaded = true

				loadstring(game:HttpGet("https://raw.githubusercontent.com/justmoon56/MacroGui/refs/heads/main/Macro.lua"))()

				task.wait(.2)

				if _G.CreateMacroUI then
					_G.CreateMacroUI()
				end
			end
		end

		local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
		local emoteGui = PlayerGui:FindFirstChild("EmoteGui")
		local crouchGui = PlayerGui:FindFirstChild("CrouchGui")

		if emoteGui then
			emoteGui.Enabled = state
		end

		if crouchGui then
			crouchGui.Enabled = state

		end
	end
})

local textTransparency=0.6
local iconTransparency=0.6
local BtnSize=80

function updateAllTransparency()
	if emoteGui then
		local emoteBtn=emoteGui:FindFirstChildWhichIsA("ImageButton", true)

		if emoteBtn then
			emoteBtn.ImageTransparency=1
			local emoteIcon=emoteBtn:FindFirstChildWhichIsA("TextLabel", true)
			if emoteIcon then
				emoteIcon.TextTransparency=textTransparency
			end
		end
	end

	if crouchGui then
		local crouchBtn=crouchGui:FindFirstChildWhichIsA("ImageButton", true)
		if crouchBtn then
			crouchBtn.ImageTransparency=1
			local crouchIcon=crouchBtn:FindFirstChildWhichIsA("ImageLabel", true)
			if crouchIcon then
				crouchIcon.ImageTransparency=iconTransparency
			end
		end
	end
end

local function updateButtonSize()
	local function apply(gui)
		if not gui then
			return
		end

		local btn=gui:FindFirstChildWhichIsA("ImageButton", true)
		if btn then
			btn.Size=UDim2.new(0,BtnSize,0,BtnSize)
		end
	end

	apply(emoteGui)
	apply(crouchGui)
end

Tabs.Folder:AddInput("TextTransparency", { Title="Emote Transparency", Default="0.6",
	Numeric=true,
	Finished=true,
	Callback=function(v)
		local n=tonumber(v)
		if n then
			textTransparency=math.clamp(n,0,1)

			updateAllTransparency()
		end
	end
})

Tabs.Folder:AddInput("IconTransparency", { Title="Crouch Transparency", Default="0.6",
	Numeric=true,
	Finished=true,
	Callback=function(v)
		local n=tonumber(v)
		if n then
			iconTransparency=math.clamp(n,0,1)

			updateAllTransparency()
		end
	end
})

Tabs.Folder:AddInput("MacroButtonSize", { Title="Button Size", Default="80",
	Numeric=true,
	Finished=true,
	Callback=function(v)
		local n=tonumber(v)
		if n then
			BtnSize=
				math.clamp(n,40,250)

			updateButtonSize()
		end
	end
})

task.spawn(function()
	repeat
		task.wait()

		local pg=game.Players.LocalPlayer:FindFirstChild("PlayerGui")
		if pg then
			emoteGui=pg:FindFirstChild("EmoteGui")
			crouchGui=pg:FindFirstChild("CrouchGui")
		end

	until emoteGui and crouchGui

	updateAllTransparency()
	updateButtonSize()
end)

-- Spawn Ramp
local spawnedRamp = nil

local rampX = 40
local rampY = 20
local rampZ = 60

Tabs.Model:AddInput("RampX", {
	Title = "Size X",
	Default = "40",
	Numeric = true,
	Callback = function(v)
		local n = tonumber(v)
		if n then
			rampX = math.clamp(n,1,500)
		end
	end
})

Tabs.Model:AddInput("RampY", {
	Title = "Size Y",
	Default = "20",
	Numeric = true,
	Callback = function(v)
		local n = tonumber(v)
		if n then
			rampY = math.clamp(n,1,500)
		end
	end
})

Tabs.Model:AddInput("RampZ", {
	Title = "Size Z",
	Default = "60",
	Numeric = true,
	Callback = function(v)
		local n = tonumber(v)
		if n then
			rampZ = math.clamp(n,1,500)
		end
	end
})

Tabs.Model:AddButton({
	Title = "Spawn Ramp",
	Callback = function()
		local char = player.Character
		if not char then return end

		local root = char:FindFirstChild("HumanoidRootPart")
		if not root then return end

		if spawnedRamp then
			spawnedRamp:Destroy()
			spawnedRamp = nil
		end

		local ramp = Instance.new("WedgePart")
		ramp.Name = "Ramp_GG_EVADE_Lol"
		ramp.Size = Vector3.new(rampX, rampY, rampZ)
		ramp.Material = Enum.Material.SmoothPlastic
		ramp.Color = Color3.fromRGB(255,140,0)
		ramp.Anchored = true
		ramp.CanCollide = true
		ramp.Position = root.Position + root.CFrame.LookVector * 15
		ramp.Parent = workspace
		spawnedRamp = ramp

		Fluent:Notify({
			Title = "Ramp",
			Content = "Ramp spawned",
			Duration = 2
		})
	end
})

Tabs.Model:AddButton({
	Title = "Delete Ramp",
	Callback = function()

		if spawnedRamp then
			spawnedRamp:Destroy()
			spawnedRamp = nil

			Fluent:Notify({
				Title = "Ramp",
				Content = "Ramp deleted",
				Duration = 2
			})
		end
	end
})

Tabs.Model:AddSection("Spawn 3D Model")

Tabs.Model:AddParagraph({
	Title = "Support Legacy Asset",
	Content = ""
})

local assetId = ""
local spawnedModel = nil
local anchored = true

local scaleValue = 1
local scaleX, scaleY, scaleZ = 1,1,1
local originalSizes = {}

Tabs.Model:AddInput("ModelID", {
	Title = "Asset ID",
	Placeholder = "rbxassetid://123456789",
	Numeric = true,
	Callback = function(v)
		assetId = v
	end
})

Tabs.Model:AddInput("ScaleNormal", {
	Title = "Uniform Scale",
	Default = "1",
	Numeric = true,
	Callback = function(v)
		local n = tonumber(v)
		if n then scaleValue = math.clamp(n,0.1,20) end
	end
})

Tabs.Model:AddInput("ScaleX", {
	Title = "Scale X",
	Default = "1",
	Numeric = true,
	Callback = function(v)
		local n = tonumber(v)
		if n then scaleX = math.clamp(n,0.1,20) end
	end
})

Tabs.Model:AddInput("ScaleY", {
	Title = "Scale Y",
	Default = "1",
	Numeric = true,
	Callback = function(v)
		local n = tonumber(v)
		if n then scaleY = math.clamp(n,0.1,20) end
	end
})

Tabs.Model:AddInput("ScaleZ", {
	Title = "Scale Z",
	Default = "1",
	Numeric = true,
	Callback = function(v)
		local n = tonumber(v)
		if n then scaleZ = math.clamp(n,0.1,20) end
	end
})

local function loadAssetUniversal(id)
	local success, result

	success, result = pcall(function()
		return game:GetService("InsertService"):LoadAsset(id)
	end)

	if success and result then
		return result:GetChildren()[1]
	end

	success, result = pcall(function()
		return game:GetObjects("rbxassetid://"..id)
	end)

	if success and result and result[1] then
		return result[1]
	end

	return nil
end

local function saveOriginalSizes()
	originalSizes = {}

	for _,v in pairs(spawnedModel:GetDescendants()) do
		if v:IsA("BasePart") then
			originalSizes[v] = v.Size
		end
	end
end

local function applyUniformScale()
	if not spawnedModel then return end

	if spawnedModel:IsA("Model") then
		pcall(function()
			spawnedModel:ScaleTo(scaleValue)
		end)
	elseif spawnedModel:IsA("BasePart") then
		spawnedModel.Size = spawnedModel.Size * scaleValue
	end
end

local function applyAxisScale()
	if not spawnedModel then return end

	for part,origSize in pairs(originalSizes) do
		if part and part.Parent then
			part.Size = Vector3.new(
				origSize.X * scaleX,
				origSize.Y * scaleY,
				origSize.Z * scaleZ
			)
		end
	end
end

local function smartCollision(model)
	for _,v in pairs(model:GetDescendants()) do
		if v:IsA("BasePart") then

			local name = v.Name:lower()

			local isInvisible = v.Transparency >= 0.8
			local isHitbox = name:find("hitbox") 
				or name:find("wall") 
				or name:find("collision")

			if isInvisible or isHitbox then
				v.CanCollide = true
				v.CanTouch = true
				v.CanQuery = true
			else
				v.CanCollide = true
				v.Anchored = true
			end
		end
	end
end

local function spawnModel()
	local success, err = pcall(function()
		local Players = game:GetService("Players")
		local player = Players.LocalPlayer
		local char = player.Character or player.CharacterAdded:Wait()
		local root = char:WaitForChild("HumanoidRootPart")
		local id = tonumber(assetId)
		assert(id, "Invalid ID")
		local obj = loadAssetUniversal(id)
		assert(obj, "Failed to load asset")

		spawnedModel = obj

		local ok = pcall(function()
			obj.Parent = workspace
		end)

		if not ok then
			obj.Parent = char
		end

		local cf = root.CFrame * CFrame.new(0,0,-10)

		if obj:IsA("Model") then
			obj:PivotTo(cf)
		elseif obj:IsA("BasePart") then
			obj.CFrame = cf
		end

		smartCollision(obj)
		saveOriginalSizes()
		applyUniformScale()
	end)
end

Tabs.Model:AddButton({
	Title = "Spawn Model",
	Callback = spawnModel
})

Tabs.Model:AddButton({
	Title = "Delete Model",
	Callback = function()
		if spawnedModel then
			spawnedModel:Destroy()
			spawnedModel = nil
		end
	end
})

Tabs.Model:AddButton({
	Title = "Apply Uniform Scale",
	Callback = applyUniformScale
})

Tabs.Model:AddButton({
	Title = "Apply Axis Scale",
	Callback = applyAxisScale
})

-- Extension

Tabs.Extension:AddSection("Character Extension")

local Asset = {
	Right = {
		Upper = "rbxassetid://9598310133",
		Texture = "rbxassetid://902843398"
	},
	OverlayTexture = {
		R6 = {
			TextureId = "rbxassetid://101851254",
		},
	},
	Left = {
		Upper = "rbxassetid://9598310131",
		Lower = "rbxassetid://9598310137",
		Texture = "rbxassetid://902842271"
	}
}

local BLACK_COLOR = Color3.fromRGB(0, 0, 0)

local function CreateFakeLimbPart(targetPart, fakeName, meshId, textureId, c0_offset, c1_offset)
	if not targetPart or not targetPart.Parent then return nil end

	local oldFake = targetPart:FindFirstChild(fakeName)
	if oldFake then oldFake:Destroy() end

	local fakePart = Instance.new("Part")
	fakePart.Name = fakeName
	fakePart.Size = Vector3.new(0.9, 0.9, 0.9)
	fakePart.CanCollide = false
	fakePart.Massless = true
	fakePart.CastShadow = false
	fakePart.Transparency = 0
	fakePart.Material = Enum.Material.SmoothPlastic
	fakePart.Color = BLACK_COLOR

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = meshId or ""
	mesh.TextureId = textureId or ""
	mesh.Scale = Vector3.new(1, 1, 1)
	mesh.Parent = fakePart

	fakePart.CFrame = targetPart.CFrame
	fakePart.Parent = targetPart

	local weld = Instance.new("Weld")
	weld.Name = "ManualWeld"
	weld.Part0 = targetPart
	weld.Part1 = fakePart
	weld.C0 = c0_offset or CFrame.new()
	weld.C1 = c1_offset or CFrame.new()
	weld.Parent = fakePart

	return fakePart
end

Tabs.Extension:AddButton(
	{
		Title = "Korblox RightLeg",
		Description = "",
		Callback = function()
			local player = game:GetService("Players").LocalPlayer

			if holderPart then
				local Rightleg = holderPart:FindFirstChild("Holder_RightUpperLeg")
				local lowerleg = holderPart:FindFirstChild("Holder_RightLowerLeg")
				local Foot = holderPart:FindFirstChild("Holder_RightFoot")

				if Rightleg and lowerleg and Foot then
					Rightleg:Destroy()
					lowerleg:Destroy()
					Foot:Destroy()
				end
			end

			local function applyRightLeg(character)
				local humanoid = character:WaitForChild("Humanoid", 5)
				if not humanoid then return end

				if humanoid.RigType == Enum.HumanoidRigType.R15 then
					local upper = character:WaitForChild("RightUpperLeg", 5)
					local lower = character:FindFirstChild("RightLowerLeg")
					local foot  = character:FindFirstChild("RightFoot")

					if upper then upper.Transparency = 1 end
					if lower then lower.Transparency = 1 end
					if foot then foot.Transparency = 1 end

					if upper then
						local c0_offset = CFrame.new(0, 0, 0)
						local c1_offset = CFrame.new(0, -0.1, 0)

						CreateFakeLimbPart(
							upper, 
							"FakeKorbloxLeg", 
							Asset.Right.Upper, 
							Asset.Right.Texture, 
							c0_offset, 
							c1_offset
						)
					end

					local root = character:FindFirstChild("HumanoidRootPart")
					if root then root.CFrame = root.CFrame * CFrame.new(0, 0.001, 0) end
				else
					local rightLeg = character:WaitForChild("Right Leg", 5)
					if rightLeg then
						rightLeg.Transparency = 1

						CreateFakeLimbPart(
							rightLeg,
							"RightLeg",
							"rbxassetid://101851696",
							Asset.OverlayTexture.R6.TextureId,
							CFrame.new(0, 0, 0),
							CFrame.new(0, 0, 0)
						)
					end
				end
			end

			if player.Character then
				applyRightLeg(
					player.Character
				)
			end

			player.CharacterAdded:Connect(
				applyRightLeg
			)
		end
	}
)

Tabs.Extension:AddButton(
	{
		Title = "Korblox LeftLeg",
		Description = "",
		Callback = function()
			local player = game:GetService("Players").LocalPlayer

			if holderPart then
				local Leftleg = holderPart:FindFirstChild("Holder_LeftUpperLeg")
				local lowerleg = holderPart:FindFirstChild("Holder_LeftLowerLeg")
				local Foot = holderPart:FindFirstChild("Holder_LeftFoot")

				if Leftleg and lowerleg and Foot then
					Leftleg:Destroy()
					lowerleg:Destroy()
					Foot:Destroy()
				end
			end

			local function applyLeftLeg(character)
				local humanoid = character:WaitForChild("Humanoid", 5)
				if not humanoid then return end

				if humanoid.RigType == Enum.HumanoidRigType.R15 then
					local upper = character:WaitForChild("LeftUpperLeg", 5)
					local lower = character:WaitForChild("LeftLowerLeg", 5)
					local foot  = character:FindFirstChild("LeftFoot")

					if upper then upper.Transparency = 1 end
					if lower then lower.Transparency = 1 end
					if foot then foot.Transparency = 1 end

					if upper then
						CreateFakeLimbPart(
							upper, 
							"LeftUpperLeg", 
							Asset.Left.Upper, 
							Asset.Left.Texture, 
							CFrame.new(0, 0, 0), 
							CFrame.new(0, 0, 0)
						)
					end

					if lower then
						local knee_c0 = CFrame.new(0, -0.4, 0)
						local knee_c1 = CFrame.new(0, 0.3, 0)

						CreateFakeLimbPart(
							lower, 
							"LeftLowerLeg", 
							Asset.Left.Lower, 
							Asset.Left.Texture, 
							knee_c0, 
							knee_c1
						)
					end

					local root = character:FindFirstChild("HumanoidRootPart")
					if root then root.CFrame = root.CFrame * CFrame.new(0, 0.001, 0) end
				else
					local leftLeg = character:WaitForChild("Left Leg", 5)
					if leftLeg then
						leftLeg.Transparency = 1

						CreateFakeLimbPart(
							leftLeg,
							"LeftLeg",
							"rbxassetid://101851582",
							Asset.OverlayTexture.R6.TextureId,
							CFrame.new(0, 0, 0),
							CFrame.new(0, 0, 0)
						)
					end
				end
			end

			if player.Character then
				applyLeftLeg(
					player.Character
				)
			end

			player.CharacterAdded:Connect(
				applyLeftLeg
			)
		end
	}
)

Tabs.Extension:AddButton(
	{
		Title = "Headless",
		Description = "",
		Callback = function()
			local Players = game:GetService("Players")
			local player = Players.LocalPlayer
			local RunService = game:GetService("RunService")
			local HEADLESS_MESH_ID = "rbxassetid://1095708"    -- Tiny invisible headless mesh

			local function applyHeadless(head)
				if not head then
					return
				end

				head.Transparency = 1
				head.CanCollide = false

				local function removeFace()
					local face = head:FindFirstChild("face")
					if face then
						face:Destroy()
					end
				end

				removeFace()

				local mesh = Instance.new("SpecialMesh")
				mesh.MeshType = Enum.MeshType.FileMesh
				mesh.MeshId = HEADLESS_MESH_ID
				mesh.Scale = Vector3.new(0.001, 0.001, 0.001)
				mesh.Parent = head

				head:GetPropertyChangedSignal("Transparency"):Connect(
					function()
						if head.Transparency ~= 1 then
							head.Transparency = 1
						end
					end
				)

				head.ChildAdded:Connect(
					function(child)
						if child.Name == "face" and child:IsA("Decal") then
							child:Destroy()
						end
					end
				)
			end

			local function applyCharacter(character)
				local head = character:WaitForChild("Head", 9e9)
				if head then
					applyHeadless(head)
				end
			end

			local function applyToLocalPlayer()
				if player.Character then
					applyCharacter(player.Character)
				end
			end


			player.CharacterAdded:Connect(
				function(character)
					applyCharacter(character)
				end
			)

			applyToLocalPlayer()
		end
	}
)

Tabs.Extension:AddButton({
	Title = "AvatarChanger",
	Description = "Server side only",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/L4rdberk/l4rd/refs/heads/main/avchalf3nonotileak.txt"))()
	end
})

Tabs.Extension:AddButton({
	Title = "Camera Sensitivity",
	Description = "in process",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/justmoon56/Sensitivity/refs/heads/main/Sensitivity.lua.txt"))()
	end
})

Tabs.Extension:AddSection("Accessories added")

Tabs.Extension:AddInput("AssetID", {
	Title = "Custom Accsesory / Hair ID",
	Default = "",
	Numeric = true,
	Callback = function(Value)
		_G.SavedID = tonumber(Value)
	end
})

Tabs.Extension:AddButton({
	Title = "Apply Accessory",
	Callback = function()
		if _G.SavedID then
			local success, code = pcall(game.HttpGet, game, "https://raw.githubusercontent.com/twinkilya0-jpg/Fluent-Modded/refs/heads/master/SkinExtensions/SkinChanger.lua")
			if success then
				local func = loadstring(code)
				if func then
					func()
				end
			end
		end
	end
})

Tabs.Extension:AddButton({
	Title = "No Accessories",
	Callback = function()
		local char = game.Players.LocalPlayer.Character
		if char then
			for _, obj in ipairs(char:GetChildren()) do
				if obj:IsA("Accessory") then
					obj:Destroy()
				end
			end
		end
	end
})

do 
	Tabs.Extension:AddToggle("RemoveAccs", {Title = "Remove Accessories", Default = false})

	task.spawn(function()
		while task.wait(0.2) do
			if Fluent.Options.RemoveAccs.Value then
				local lp = game:GetService("Players").LocalPlayer
				if lp and lp.Character then
					for _, v in ipairs(lp.Character:GetChildren()) do
						if v:IsA("Accessory") then
							v:Destroy()
						end
					end
				end
			end
		end
	end)
end

Tabs.Extension:AddParagraph({
	Title = " ",
	Content = ""
})

_G.Players = game:GetService("Players")
_G.LPlayer = _G.Players.LocalPlayer

_G.ExtStates = {
	Wings = false,
	Poison = false,
	Frozen = false,
	Fire = false,
	Doomsekkar = false,
}

_G.ApplySingleExt = function(id, name, state)
	if not state then
		if _G.LPlayer.Character and _G.LPlayer.Character:FindFirstChild(name) then
			_G.LPlayer.Character[name]:Destroy()
		end
		return
	end

	local char = _G.LPlayer.Character
	if not char or char:FindFirstChild(name) then return end

	local s, obj = pcall(function() return game:GetObjects("rbxassetid://" .. id)[1] end)
	if s and obj then
		obj.Name = name
		obj.Parent = char

		local h = obj:FindFirstChild("Handle")
		if h and h:IsA("BasePart") then
			h.CanCollide = false

			local w = Instance.new("Weld")
			w.Part0 = h

			if name == "Wings_Acc" then
				local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
				if torso then
					w.Part1 = torso
					w.C0 = obj.AttachmentPoint
					w.C1 = CFrame.new(0, 1.7, 0.3) 
				else
					w.Part1 = char:FindFirstChild("Head")
					w.C0 = obj.AttachmentPoint
					w.C1 = CFrame.new(0, 0.5, 0)
				end
			else
				w.Part1 = char:FindFirstChild("Head")
				w.C0 = obj.AttachmentPoint
				w.C1 = CFrame.new(0, 0.5, 0) 
			end

			w.Parent = h
		end
	end
end

_G.RefreshExts = function()
	if _G.ExtStates.Wings then _G.ApplySingleExt(192557913, "Wings_Acc", true) end
	if _G.ExtStates.Poison then _G.ApplySingleExt(1744060292, "Poison_Acc", true) end
	if _G.ExtStates.Frozen then _G.ApplySingleExt(74891470, "Frozen_Acc", true) end
	if _G.ExtStates.Fire then _G.ApplySingleExt(215718515, "Fire_Acc", true) end
	if _G.ExtStates.Doomsekkar then _G.ApplySingleExt(132809431, "Doomsekkar_Acc", true) end
	if _G.ExtStates.Frostsekkar then _G.ApplySingleExt(182672520, "Frostsekkar_Acc", true) end
	if _G.ExtStates.Infernosekkar then _G.ApplySingleExt(319643443, "Infernosekkar_Acc", true) end
	if _G.ExtStates.PoisonDusekkar then _G.ApplySingleExt(174405374, "PoisonDusekkar_Acc", true) end
end

_G.LPlayer.CharacterAdded:Connect(function()
	task.wait(1.5) 
	_G.RefreshExts()
end)

_G.Players = game:GetService("Players")
_G.LPlayer = _G.Players.LocalPlayer

_G.ExtStates = {
	Wings = false,
	Poison = false,
	Frozen = false,
	Fire = false,
	Doomsekkar = false,
}

_G.ApplySingleExt = function(id, name, state)
	if not state then
		if _G.LPlayer.Character and _G.LPlayer.Character:FindFirstChild(name) then
			_G.LPlayer.Character[name]:Destroy()
		end
		return
	end

	local char = _G.LPlayer.Character
	if not char or char:FindFirstChild(name) then return end

	local s, obj = pcall(function() return game:GetObjects("rbxassetid://" .. id)[1] end)
	if s and obj then
		obj.Name = name
		obj.Parent = char

		local h = obj:FindFirstChild("Handle")
		if h and h:IsA("BasePart") then
			h.CanCollide = false

			local w = Instance.new("Weld")
			w.Part0 = h

			if name == "Wings_Acc" then
				local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
				if torso then
					w.Part1 = torso
					w.C0 = obj.AttachmentPoint
					w.C1 = CFrame.new(0, 1.7, 0.3) 
				else
					w.Part1 = char:FindFirstChild("Head")
					w.C0 = obj.AttachmentPoint
					w.C1 = CFrame.new(0, 0.5, 0)
				end
			else
				w.Part1 = char:FindFirstChild("Head")
				w.C0 = obj.AttachmentPoint
				w.C1 = CFrame.new(0, 0.5, 0) 
			end

			w.Parent = h
		end
	end
end

_G.RefreshExts = function()
	if _G.ExtStates.Wings then _G.ApplySingleExt(192557913, "Wings_Acc", true) end
	if _G.ExtStates.Poison then _G.ApplySingleExt(1744060292, "Poison_Acc", true) end
	if _G.ExtStates.Frozen then _G.ApplySingleExt(74891470, "Frozen_Acc", true) end
	if _G.ExtStates.Fire then _G.ApplySingleExt(215718515, "Fire_Acc", true) end
	if _G.ExtStates.Doomsekkar then _G.ApplySingleExt(132809431, "Doomsekkar_Acc", true) end
	if _G.ExtStates.Frostsekkar then _G.ApplySingleExt(182672520, "Frostsekkar_Acc", true) end
	if _G.ExtStates.Infernosekkar then _G.ApplySingleExt(319643443, "Infernosekkar_Acc", true) end
	if _G.ExtStates.PoisonDusekkar then _G.ApplySingleExt(174405374, "PoisonDusekkar_Acc", true) end
end

_G.LPlayer.CharacterAdded:Connect(function()
	task.wait(1.5) 
	_G.RefreshExts()
end)

Tabs.Extension:AddToggle("TogWings", {
	Title = "Angelic Wings",
	Default = false,
	Callback = function(state) 
		_G.ExtStates.Wings = state 
		_G.ApplySingleExt(192557913, "Wings_Acc", state) 
	end
})

Tabs.Extension:AddToggle("TogPoison", {
	Title = "Poisonous Horns",
	Default = false,
	Callback = function(state) 
		_G.ExtStates.Poison = state 
		_G.ApplySingleExt(1744060292, "Poison_Acc", state) 
	end
})

Tabs.Extension:AddToggle("TogFrozen", {
	Title = "Frozen Horn",
	Default = false,
	Callback = function(state) 
		_G.ExtStates.Frozen = state 
		_G.ApplySingleExt(74891470, "Frozen_Acc", state) 
	end
})

Tabs.Extension:AddToggle("TogFire", {
	Title = "Fire Horn",
	Default = false,
	Callback = function(state) 
		_G.ExtStates.Fire = state 
		_G.ApplySingleExt(215718515, "Fire_Acc", state) 
	end
})

Tabs.Extension:AddToggle("TogDoomsekkar", {
	Title = "Doomsekkar",
	Default = false,
	Callback = function(state) 
		_G.ExtStates.Doomsekkar = state 
		_G.ApplySingleExt(132809431, "Doomsekkar_Acc", state) 
	end
})

Tabs.Extension:AddSection("Fence Spawner")

local SpawnedFences = {}

Tabs.Extension:AddButton({
	Title = "Spawn Fence",
	Description = "",
	Callback = function()
		if not player then return end
		local char = player.Character
		if not char then return end

		local root = char:FindFirstChild("HumanoidRootPart")
		if not root then return end

		local success, objects = pcall(function()
			return game:GetObjects("rbxassetid://104216557096252")
		end)

		if success and objects and objects[1] then
			local asset = objects[1]
			asset.Name = "Fence_GG_EVADE_Lol"

			if asset:IsA("Model") then
				if not asset.PrimaryPart then
					local pp = asset:FindFirstChildWhichIsA("BasePart", true)
					if pp then 
						asset.PrimaryPart = pp 
					end
				end
			end

			asset.Parent = workspace

			local cf = (root.CFrame * CFrame.new(0, 2, -8)) * CFrame.Angles(0, math.rad(90), 0)

			if asset:IsA("Model") then
				if asset.PrimaryPart then
					asset:PivotTo(cf)
				end
			elseif asset:IsA("BasePart") then
				asset.CFrame = cf
			end

			for _, child in pairs(asset:GetDescendants()) do
				if child:IsA("BasePart") then
					child.Anchored = true
				end
			end

			if asset:IsA("Model") then
				local boxPart = Instance.new("Part")
				boxPart.Name = "InvisParts"
				boxPart.Massless = true
				boxPart.Transparency = 1
				boxPart.Anchored = true
				boxPart.CanCollide = false
				boxPart.Size = Vector3.new(10.4, 6.7, 1.2)
				boxPart.CFrame = (cf * CFrame.new(0, 1.1, 0)) * CFrame.Angles(0, math.rad(-90), 0)
				boxPart.Parent = asset

				local boundingBox = Instance.new("SelectionBox")
				boundingBox.Name = "BoundingBox"
				boundingBox.Adornee = boxPart
				boundingBox.Color3 = Color3.fromRGB(128, 255, 255)
				boundingBox.LineThickness = 0
				boundingBox.Transparency = 1
				boundingBox.Parent = asset
			end

			table.insert(SpawnedFences, asset)

			Fluent:Notify({
				Title = "Success",
				Content = "Fence Success Fully Loaded!",
				Duration = 2
			})
		else
			Fluent:Notify({
				Title = "Error",
				Content = "Failed to load model assets.",
				Duration = 2
			})
		end
	end
})

Tabs.Extension:AddButton({
	Title = "Delete Fence",
	Description = "",
	Callback = function()
		local deleted = 0

		for _, v in pairs(SpawnedFences) do
			if v and v.Parent then
				v:Destroy()
				deleted = deleted + 1
			end
		end

		table.clear(SpawnedFences)

		Fluent:Notify({
			Title = "Success",
			Content = "Deleted " .. deleted .. " Fence",
			Duration = 2
		})
	end
})

Tabs.Extension:AddSection("Crosshair")

do
	local AdvancedConfig = {
		Enabled = false,
		SpinEnabled = false,
		UseCustomAsset = false,
		UseCustomSize = false,
		RotationSpeed = 5,
		Size = 30,
		DefaultSize = 30,
		AssetId = "7831350554",
		DefaultAsset = "7831350554"
	}

	local function updateLogoProperties()
		local lp = game:GetService("Players").LocalPlayer
		local pgui = lp:FindFirstChild("PlayerGui")
		local sg = pgui and pgui:FindFirstChild("GribabasCenter")
		if sg then
			local img = sg:FindFirstChild("RotatingLogo")
			if img then
				local targetSize = AdvancedConfig.UseCustomSize and AdvancedConfig.Size or AdvancedConfig.DefaultSize
				local targetAsset = AdvancedConfig.UseCustomAsset and AdvancedConfig.AssetId or AdvancedConfig.DefaultAsset

				img.Size = UDim2.new(0, targetSize, 0, targetSize)
				img.Image = "rbxassetid://" .. targetAsset:gsub("%D", "")

				if not AdvancedConfig.SpinEnabled then
					img.Rotation = 0
				end
			end
		end
	end

	local function startCheat()
		local lp = game:GetService("Players").LocalPlayer
		local pgui = lp:WaitForChild("PlayerGui")

		if pgui:FindFirstChild("GribabasCenter") then return end

		local sg = Instance.new("ScreenGui")
		sg.Name = "GribabasCenter"
		sg.IgnoreGuiInset = true
		sg.ResetOnSpawn = false
		sg.Parent = pgui

		local img = Instance.new("ImageLabel", sg)
		img.Name = "RotatingLogo"
		img.Position = UDim2.new(0.5, 0, 0.5, 0)
		img.AnchorPoint = Vector2.new(0.5, 0.5)
		img.BackgroundTransparency = 1

		updateLogoProperties()

		task.spawn(function()
			while img and img.Parent and AdvancedConfig.Enabled do
				if AdvancedConfig.SpinEnabled then
					img.Rotation = img.Rotation + AdvancedConfig.RotationSpeed
				else
					img.Rotation = 0
				end
				task.wait()
			end
			if sg.Parent then sg:Destroy() end
		end)
	end

	Tabs.Extension:AddToggle("MainLogoToggle", {
		Title = "Show Logo",
		Default = false,
		Callback = function(Value)
			AdvancedConfig.Enabled = Value
			if Value then startCheat() else updateLogoProperties() end
		end
	})

	Tabs.Extension:AddToggle("AssetToggle", {
		Title = "Use Custom ID",
		Default = false,
		Callback = function(Value)
			AdvancedConfig.UseCustomAsset = Value
			updateLogoProperties()
		end
	})

	Tabs.Extension:AddInput("AssetInput", {
		Title = "Custom Asset ID",
		Default = AdvancedConfig.AssetId,
		Numeric = true,
		Finished = true,
		Callback = function(Value)
			AdvancedConfig.AssetId = Value
			if AdvancedConfig.UseCustomAsset then updateLogoProperties() end
		end
	})

	Tabs.Extension:AddToggle("SpinToggle", {
		Title = "Enable Spin",
		Default = false,
		Callback = function(Value)
			AdvancedConfig.SpinEnabled = Value
			updateLogoProperties()
		end
	})

	Tabs.Extension:AddSlider("SpinSlider", {
		Title = "Spin Speed",
		Default = 5,
		Min = 1,
		Max = 100,
		Rounding = 1,
		Callback = function(Value)
			AdvancedConfig.RotationSpeed = Value
		end
	})

	Tabs.Extension:AddToggle("SizeToggle", {
		Title = "Enable Custom Size",
		Default = false,
		Callback = function(Value)
			AdvancedConfig.UseCustomSize = Value
			updateLogoProperties()
		end
	})

	Tabs.Extension:AddSlider("SizeSlider", {
		Title = "Custom Size",
		Default = 30,
		Min = 10,
		Max = 300,
		Rounding = 0,
		Callback = function(Value)
			AdvancedConfig.Size = Value
			if AdvancedConfig.UseCustomSize then updateLogoProperties() end
		end
	})

	task.spawn(function()
		while true do
			if AdvancedConfig.Enabled then
				local lp = game:GetService("Players").LocalPlayer
				local pgui = lp:FindFirstChild("PlayerGui")
				if pgui and not pgui:FindFirstChild("GribabasCenter") then
					startCheat()
				end
			end
			task.wait(1)
		end
	end)
end

Tabs.Extension:AddSection("Shader Extension")

local function ClearLighting()
	for _, child in ipairs(Lighting:GetChildren()) do
		if child.Name ~= "MenuBlur" then
			child:Destroy()
		end
	end
end

Tabs.Extension:AddButton(
	{
		Title = "Day",
		Description = "",
		Callback = function()
			ClearLighting()

			Lighting.Ambient = Color3.new(0, 0, 0)
			Lighting.OutdoorAmbient = Color3.new(0.568627, 0.501961, 0.372549)
			Lighting.Brightness = 3.130000114440918
			Lighting.ClockTime = 14.5
			Lighting.ExposureCompensation = 0
			Lighting.FogColor = Color3.new(0.572549, 0.815686, 1)
			Lighting.FogEnd = 3000
			Lighting.FogStart = 300
			Lighting.GlobalShadows = true
			Lighting.GeographicLatitude = 143
			Lighting.EnvironmentDiffuseScale = 0.5830000042915344
			Lighting.EnvironmentSpecularScale = 1
			Lighting.ShadowSoftness = 0.03999999910593033
			Lighting.ColorShift_Top = Color3.new(0.737255, 0.552941, 0.00392157)
			Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
			Lighting.Technology = Enum.Technology.ShadowMap
			Lighting.TimeOfDay = "14:30:00"

			local Sky = Instance.new("Sky")
			Sky.Name = "Sky"
			Sky.SkyboxBk = "rbxassetid://6444884337"
			Sky.SkyboxDn = "rbxassetid://6444884785"
			Sky.SkyboxFt = "rbxassetid://6444884337"
			Sky.SkyboxLf = "rbxassetid://6444884337"
			Sky.SkyboxRt = "rbxassetid://6444884337"
			Sky.SkyboxUp = "rbxassetid://6412503613"
			Sky.MoonAngularSize = 11
			Sky.SunAngularSize = 11
			Sky.MoonTextureId = "rbxassetid://6444320592"
			Sky.SunTextureId = "rbxassetid://1084351190"
			Sky.StarCount = 0
			Sky.Parent = Lighting

			local Bloom = Instance.new("BloomEffect")
			Bloom.Name = "Bloom"
			Bloom.Enabled = true
			Bloom.Intensity = 1
			Bloom.Threshold = 2
			Bloom.Size = 90
			Bloom.Parent = Lighting

			local ColorCorrection = Instance.new("ColorCorrectionEffect")
			ColorCorrection.Name = "ColorCorrection"
			ColorCorrection.Enabled = true
			ColorCorrection.Brightness = 0.03999999910593033
			ColorCorrection.Contrast = 0.1899999976158142
			ColorCorrection.Saturation = 0.11999999731779099
			ColorCorrection.TintColor = Color3.new(1, 1, 1)
			ColorCorrection.Parent = Lighting
		end
	}
)

Tabs.Extension:AddButton(
	{
		Title = "Sunset",
		Description = "",
		Callback = function()
			ClearLighting()

			Lighting.Ambient = Color3.new(0.67451, 0.67451, 0.67451)
			Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
			Lighting.Brightness = 3.799999952316284
			Lighting.ClockTime = 7.099999904632568
			Lighting.ExposureCompensation = -0.23999999463558197
			Lighting.FogColor = Color3.new(0, 0, 0)
			Lighting.FogEnd = 100000000
			Lighting.FogStart = 20
			Lighting.GlobalShadows = true
			Lighting.GeographicLatitude = 72
			Lighting.EnvironmentDiffuseScale = 0.30000001192092896
			Lighting.EnvironmentSpecularScale = 0.05999999865889549
			Lighting.ShadowSoftness = 0.10000000149011612
			Lighting.ColorShift_Top = Color3.new(1, 0.682353, 0.168627)
			Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
			Lighting.Technology = Enum.Technology.Future
			Lighting.TimeOfDay = "07:06:00"

			local Sky = Instance.new("Sky")
			Sky.Name = "Sky"
			Sky.CelestialBodiesShown = true
			Sky.SkyboxBk = "rbxassetid://1009082031"
			Sky.SkyboxDn = "rbxassetid://1009082487"
			Sky.SkyboxFt = "rbxassetid://1009082252"
			Sky.SkyboxLf = "rbxassetid://1009082137"
			Sky.SkyboxRt = "rbxassetid://1009081946"
			Sky.SkyboxUp = "rbxassetid://1009082428"
			Sky.MoonAngularSize = 0
			Sky.SunAngularSize = 9
			Sky.MoonTextureId = "rbxasset://sky/moon.jpg"
			Sky.SunTextureId = "rbxasset://sky/sun.jpg"
			Sky.StarCount = 3000
			Sky.Parent = Lighting

			local Bloom = Instance.new("BloomEffect")
			Bloom.Name = "Bloom"
			Bloom.Enabled = true
			Bloom.Intensity = 1
			Bloom.Threshold = 1.8240000009536743
			Bloom.Size = 56
			Bloom.Parent = Lighting

			local SunRays = Instance.new("SunRaysEffect")
			SunRays.Name = "SunRays"
			SunRays.Enabled = true
			SunRays.Intensity = 0.18000000715255737
			SunRays.Spread = 0.11999999731779099
			SunRays.Parent = Lighting

			local ColorCorrection = Instance.new("ColorCorrectionEffect")
			ColorCorrection.Name = "ColorCorrection"
			ColorCorrection.Enabled = true
			ColorCorrection.Brightness = 0
			ColorCorrection.Contrast = 0.10000000149011612
			ColorCorrection.Saturation = -0.20000000298023224
			ColorCorrection.TintColor = Color3.new(1, 1, 1)
			ColorCorrection.Parent = Lighting

			local Atmosphere = Instance.new("Atmosphere")
			Atmosphere.Name = "Atmosphere"
			Atmosphere.Color = Color3.new(0.780392, 0.666667, 0.419608)
			Atmosphere.Density = 0.41999998688697815
			Atmosphere.Offset = 0
			Atmosphere.Glare = 0
			Atmosphere.Haze = 0
			Atmosphere.Parent = Lighting
		end
	}
)

Tabs.Extension:AddButton(
	{
		Title = "Shore",
		Description = "",
		Callback = function()
			ClearLighting()

			Lighting.Ambient = Color3.new(0.427451, 0.458824, 0.529412)
			Lighting.OutdoorAmbient = Color3.new(0.141176, 0.184314, 0.227451)
			Lighting.Brightness = 1.9210000038146973
			Lighting.ClockTime = -6.399722099304199
			Lighting.ExposureCompensation = -0.20000000298023224
			Lighting.FogColor = Color3.new(0.752941, 0.752941, 0.752941)
			Lighting.FogEnd = 100000
			Lighting.FogStart = 0
			Lighting.GlobalShadows = true
			Lighting.GeographicLatitude = 0
			Lighting.EnvironmentDiffuseScale = 0.1720000058412552
			Lighting.EnvironmentSpecularScale = 0.6380000114440918
			Lighting.ShadowSoftness = 0.25
			Lighting.ColorShift_Top = Color3.new(0.886275, 0.294118, 0)
			Lighting.ColorShift_Bottom = Color3.new(0.972549, 0.647059, 0.623529)
			Lighting.Technology = Enum.Technology.ShadowMap
			Lighting.TimeOfDay = "-06:23:59"

			local Sky = Instance.new("Sky")
			Sky.Name = "Sky"
			Sky.CelestialBodiesShown = true
			Sky.SkyboxBk = "rbxassetid://88585370973398"
			Sky.SkyboxDn = "rbxassetid://128014535205529"
			Sky.SkyboxFt = "rbxassetid://85323615042244"
			Sky.SkyboxLf = "rbxassetid://77415797450913"
			Sky.SkyboxRt = "rbxassetid://127566931602371"
			Sky.SkyboxUp = "rbxassetid://102320981098060"
			Sky.MoonAngularSize = 0
			Sky.SunAngularSize = 4
			Sky.MoonTextureId = "rbxasset://sky/moon.jpg"
			Sky.SunTextureId = "rbxasset://sky/sun.jpg"
			Sky.StarCount = 5000
			Sky.Parent = Lighting

			local SunRays = Instance.new("SunRaysEffect")
			SunRays.Name = "SunRays"
			SunRays.Enabled = true
			SunRays.Intensity = 0.024000000208616257
			SunRays.Spread = 0.46299999952316284
			SunRays.Parent = Lighting

			local Bloom = Instance.new("BloomEffect")
			Bloom.Name = "Bloom"
			Bloom.Enabled = true
			Bloom.Intensity = 1
			Bloom.Threshold = 2.2911999225616455
			Bloom.Size = 50
			Bloom.Parent = Lighting

			local ColorCorrection = Instance.new("ColorCorrectionEffect")
			ColorCorrection.Name = "ColorCorrection"
			ColorCorrection.Enabled = true
			ColorCorrection.Brightness = 0
			ColorCorrection.Contrast = 0.20000000298023224
			ColorCorrection.Saturation = 0
			ColorCorrection.TintColor = Color3.new(1, 1, 1)
			ColorCorrection.Parent = Lighting

			local Atmosphere = Instance.new("Atmosphere")
			Atmosphere.Name = "Atmosphere"
			Atmosphere.Color = Color3.new(1, 0.847059, 0.760784)
			Atmosphere.Density = 0.35899999737739563
			Atmosphere.Offset = 0
			Atmosphere.Glare = 2.9700000286102295
			Atmosphere.Haze = 1.5199999809265137
			Atmosphere.Parent = Lighting

			local Blur = Instance.new("BlurEffect")
			Blur.Name = "Blur"
			Blur.Size = 4
			Blur.Parent = Lighting
		end
	}
)

Tabs.Extension:AddButton(
	{
		Title = "Cloudy",
		Description = "",
		Callback = function()
			ClearLighting()

			Lighting.Ambient = Color3.new(0, 0, 0)
			Lighting.OutdoorAmbient = Color3.new(0.34902, 0.266667, 0.184314)
			Lighting.Brightness = 5.630000114440918
			Lighting.ClockTime = 17.628889083862305
			Lighting.ExposureCompensation = 0.6299999952316284
			Lighting.FogColor = Color3.new(0.572549, 0.815686, 1)
			Lighting.FogEnd = 3000
			Lighting.FogStart = 300
			Lighting.GlobalShadows = true
			Lighting.GeographicLatitude = 21.58930015563965
			Lighting.EnvironmentDiffuseScale = 0.5830000042915344
			Lighting.EnvironmentSpecularScale = 1
			Lighting.ShadowSoftness = 0.03999999910593033
			Lighting.ColorShift_Top = Color3.new(0.811765, 0.447059, 0)
			Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
			Lighting.Technology = Enum.Technology.ShadowMap
			Lighting.TimeOfDay = "17:37:44"

			local Sky = Instance.new("Sky")
			Sky.Name = "Sky"
			Sky.CelestialBodiesShown = true
			Sky.SkyboxBk = "rbxassetid://2177969403"
			Sky.SkyboxDn = "rbxassetid://2177972406"
			Sky.SkyboxFt = "rbxassetid://2177970251"
			Sky.SkyboxLf = "rbxassetid://2177969836"
			Sky.SkyboxRt = "rbxassetid://2177968823"
			Sky.SkyboxUp = "rbxassetid://2177971305"
			Sky.MoonAngularSize = 1.5
			Sky.SunAngularSize = 3
			Sky.MoonTextureId = "rbxassetid://1075087760"
			Sky.SunTextureId = "rbxasset://sky/sun.jpg"
			Sky.StarCount = 500
			Sky.Parent = Lighting

			local Bloom = Instance.new("BloomEffect")
			Bloom.Name = "Bloom"
			Bloom.Enabled = true
			Bloom.Intensity = 1
			Bloom.Threshold = 2
			Bloom.Size = 90
			Bloom.Parent = Lighting

			local ColorCorrection = Instance.new("ColorCorrectionEffect")
			ColorCorrection.Name = "ColorCorrection"
			ColorCorrection.Enabled = true
			ColorCorrection.Brightness = 0.03999999910593033
			ColorCorrection.Contrast = 0.15000000596046448
			ColorCorrection.Saturation = 0.20000000298023224
			ColorCorrection.TintColor = Color3.new(1, 1, 1)
			ColorCorrection.Parent = Lighting

			local SunRays = Instance.new("SunRaysEffect")
			SunRays.Name = "SunRays"
			SunRays.Enabled = true
			SunRays.Intensity = 0.004000000189989805
			SunRays.Spread = 0.16699999570846558
			SunRays.Parent = Lighting

			local Atmosphere = Instance.new("Atmosphere")
			Atmosphere.Name = "Atmosphere"
			Atmosphere.Color = Color3.new(0.647059, 0.647059, 0.647059)
			Atmosphere.Density = 0.3569999933242798
			Atmosphere.Offset = 0
			Atmosphere.Glare = 0.20999999344348907
			Atmosphere.Haze = 1.4600000381469727
			Atmosphere.Parent = Lighting
		end
	}
)

Tabs.Extension:AddButton(
	{
		Title = "Night",
		Description = "",
		Callback = function()
			ClearLighting()

			Lighting.Ambient = Color3.new(0, 0, 0)
			Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
			Lighting.Brightness = 2
			Lighting.ClockTime = 3
			Lighting.ExposureCompensation = 0
			Lighting.FogColor = Color3.new(0, 0, 0)
			Lighting.FogEnd = 100000
			Lighting.FogStart = 0
			Lighting.GlobalShadows = true
			Lighting.GeographicLatitude = 41.733001708984375
			Lighting.EnvironmentDiffuseScale = 0
			Lighting.EnvironmentSpecularScale = 0
			Lighting.ShadowSoftness = 0.20000000298023224
			Lighting.ColorShift_Top = Color3.new(0, 0, 0)
			Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
			Lighting.Technology = Enum.Technology.Future
			Lighting.TimeOfDay = "03:00:00"

			local Sky = Instance.new("Sky")
			Sky.Name = "Sky"
			Sky.CelestialBodiesShown = true
			Sky.SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex"
			Sky.SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex"
			Sky.SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex"
			Sky.SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex"
			Sky.SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex"
			Sky.SkyboxUp = "rbxasset://textures/sky/sky512_up.tex"
			Sky.MoonAngularSize = 11
			Sky.SunAngularSize = 21
			Sky.MoonTextureId = "rbxasset://sky/moon.jpg"
			Sky.SunTextureId = "rbxasset://sky/sun.jpg"
			Sky.StarCount = 5000
			Sky.Parent = Lighting

			local Blur = Instance.new("BlurEffect")
			Blur.Name = "Blur"
			Blur.Enabled = true
			Blur.Size = 0
			Blur.Parent = Lighting

			local Atmosphere = Instance.new("Atmosphere")
			Atmosphere.Name = "Atmosphere"
			Atmosphere.Color = Color3.new(0, 0, 0)
			Atmosphere.Density = 0.5600000023841858
			Atmosphere.Offset = 0
			Atmosphere.Glare = 0
			Atmosphere.Haze = 0
			Atmosphere.Parent = Lighting
		end
	}
)

do
	Tabs.Extension:AddSection("Custom Skybox")

	local SkyboxFaces = {
		{ prop = "SkyboxBk", label = "Slot 1 — Back" },
		{ prop = "SkyboxFt", label = "Slot 2 — Front" },
		{ prop = "SkyboxLf", label = "Slot 3 — Left" },
		{ prop = "SkyboxRt", label = "Slot 4 — Right" },
		{ prop = "SkyboxUp", label = "Slot 5 — Top" },
		{ prop = "SkyboxDn", label = "Slot 6 — Bottom" },
	}
	local SkyboxValues = {}
	for _, face in ipairs(SkyboxFaces) do
		SkyboxValues[face.prop] = ""
		Tabs.Extension:AddInput("SkyIn_" .. face.prop, {
			Title     = face.label,
			Placeholder = "https://... or rbxasset://...",
			Numeric   = false,
			Finished  = false,
			Callback  = function(Value) SkyboxValues[face.prop] = Value end,
		})
	end

	local function ApplyCustomSkybox()
		local LightingSvc = game:GetService("Lighting")
		for _, v in pairs(LightingSvc:GetChildren()) do
			if v:IsA("Sky") then v:Destroy() end
		end
		local Sky = Instance.new("Sky")
		Sky.Name = "Sky"
		Sky.CelestialBodiesShown = false
		Sky.StarCount = 0
		local applied, failed = 0, 0
		if not isfolder("customsky") then makefolder("customsky") end
		for _, face in ipairs(SkyboxFaces) do
			local val = SkyboxValues[face.prop] or ""
			if val ~= "" then
				local ok, err = pcall(function()
					if val:sub(1, 4) == "http" then
						local fname = "customsky/Sky_" .. face.prop .. ".png"
						writefile(fname, game:HttpGet(val, true))
						Sky[face.prop] = getcustomasset(fname)
					else
						Sky[face.prop] = val
					end
				end)
				if ok then
					applied = applied + 1
				else
					failed = failed + 1
					Fluent:Notify({ Title = "Skybox Error", Content = face.prop .. " failed: " .. tostring(err):sub(1, 60), Duration = 5 })
				end
			end
		end
		if applied > 0 then
			Sky.Parent = LightingSvc
			Fluent:Notify({ Title = "Skybox", Content = "Applied " .. applied .. "/6 face(s)" .. (failed > 0 and " | " .. failed .. " failed" or ""), Duration = 3 })
		else
			Sky:Destroy()
			Fluent:Notify({ Title = "Skybox", Content = "All faces failed. Check your URLs.", Duration = 5 })
		end
	end

	Tabs.Extension:AddButton({
		Title     = "Apply Custom Skybox",
		Description = "Supports https:// and rbxasset://",
		Callback  = function() task.spawn(ApplyCustomSkybox) end,
	})

	Tabs.Extension:AddSection("Skybox")

	local function _makeSkybox(folder, faces)
		local LightingSvc = game:GetService("Lighting")
		for _, v in pairs(LightingSvc:GetChildren()) do
			if v:IsA("Sky") then v:Destroy() end
		end
		if not isfolder(folder) then makefolder(folder) end
		local Sky = Instance.new("Sky")
		Sky.Name = "Sky"
		Sky.CelestialBodiesShown = false
		Sky.StarCount = 0
		local loaded = 0
		for _, v in ipairs(faces) do
			local path = folder .. "/" .. v.file
			local ok, err = pcall(function()
				if not isfile(path) then
					writefile(path, game:HttpGet(v.url, true))
				end
				Sky[v.prop] = getcustomasset(path)
			end)
			if ok then
				loaded = loaded + 1
			else
				pcall(function() if isfile(path) then delfile(path) end end)
				Fluent:Notify({
					Title = "Skybox Error",
					Content = v.file .. " failed: " .. tostring(err):sub(1, 60),
					Duration = 5
				})
			end
		end
		if loaded > 0 then
			Sky.Parent = LightingSvc
			if loaded < #faces then
				Fluent:Notify({
					Title = "Skybox",
					Content = loaded .. "/" .. #faces .. " faces loaded",
					Duration = 4
				})
			end
		else
			Sky:Destroy()
			Fluent:Notify({
				Title = "Skybox",
				Content = "Failed to load all faces. Try again.",
				Duration = 5
			})
		end
	end

	local BuiltinSkyboxes = {
		["Hakari Hananozo"] = function()
			_makeSkybox("hk", {
				{ prop = "SkyboxBk", url = "https://od.lk/d/NjNfOTg0NjEzMTVf/SkyBk.tex", file = "SkyBk.png" },
				{ prop = "SkyboxFt", url = "https://od.lk/s/NjNfOTg0NjEzMTdf/SkyFt.tex", file = "SkyFt.png" },
				{ prop = "SkyboxLf", url = "https://od.lk/s/NjNfOTg0NjEzMThf/SkyIf.tex", file = "SkyIf.png" },
				{ prop = "SkyboxRt", url = "https://od.lk/d/NjNfOTg0NjEzMTlf/SkyRt.tex", file = "SkyRt.png" },
				{ prop = "SkyboxUp", url = "https://od.lk/d/NjNfOTg0NjEzMjBf/SkyUp.tex", file = "SkyUp.png" },
				{ prop = "SkyboxDn", url = "https://od.lk/d/NjNfOTg0NjEzMTZf/Skydn.tex", file = "Skydn.png" },
			})
		end,
		["Xenovia Quarta"] = function()
			_makeSkybox("Xenovia Quarta", {
				{ prop = "SkyboxLf", url = "https://od.lk/d/NjNfOTg0NjM0ODhf/if.png", file = "if.png" },
				{ prop = "SkyboxBk", url = "https://od.lk/d/NjNfOTg0NjM0ODlf/ft.png", file = "ft.png" },
				{ prop = "SkyboxDn", url = "https://od.lk/d/NjNfOTg0NjM0OTBf/dn.png", file = "dn.png" },
				{ prop = "SkyboxFt", url = "https://od.lk/d/NjNfOTg0NjM0OTFf/bk.png", file = "bk.png" },
				{ prop = "SkyboxUp", url = "https://od.lk/d/NjNfOTg0NjM0ODZf/up.png", file = "up.png" },
				{ prop = "SkyboxRt", url = "https://od.lk/d/NjNfOTg0NjM0ODdf/rt.png", file = "rt.png" },
			})
		end,
		["Yotsuba Nakano"] = function()
			_makeSkybox("Yotsuba Nakano", {
				{ prop = "SkyboxBk", url = "https://od.lk/d/ODhfMjAzNDU5Njlf/Back.png", file = "Back.png" },
				{ prop = "SkyboxFt", url = "https://od.lk/d/ODhfMjAzNDU5NzBf/Front.png", file = "Front.png" },
				{ prop = "SkyboxLf", url = "https://od.lk/d/ODhfMjAzNDU5NzFf/Left.png", file = "Left.png" },
				{ prop = "SkyboxRt", url = "https://od.lk/d/ODhfMjAzNDU5Njhf/Right.png", file = "Right.png" },
				{ prop = "SkyboxUp", url = "https://od.lk/d/ODhfMjAzNDU5NzJf/Up.png", file = "Up.png" },
				{ prop = "SkyboxDn", url = "https://od.lk/d/ODhfMjAzNDU5NzNf/Down.png", file = "Down.png" },
			})
		end,
		["Nakano Miku"] = function()
			_makeSkybox("Nakano Miku", {
				{ prop = "SkyboxBk", url = "https://od.lk/d/ODhfMjAzNDcxNzVf/SkyLeft.png", file = "Bk.png" },
				{ prop = "SkyboxFt", url = "https://od.lk/d/ODhfMjAzNDcxNzdf/SkyRight.png", file = "Ft.png" },
				{ prop = "SkyboxLf", url = "https://od.lk/d/ODhfMjAzNDcxNzZf/SkyFront.png", file = "Lt.png" },
				{ prop = "SkyboxRt", url = "https://od.lk/d/ODhfMjAzNDcxNzhf/SkyBack.png", file = "Rt.png" },
				{ prop = "SkyboxUp", url = "https://od.lk/d/ODhfMjAzNDcxNzRf/SkyUp.png", file = "Up.png" },
				{ prop = "SkyboxDn", url = "https://od.lk/d/ODhfMjAzNDcxNzNf/SkyDown.png", file = "Dn.png" },
			})
		end,
		["Rias Gremory"] = function()
			_makeSkybox("Rias Gremory", {
				{ prop = "SkyboxBk", url = "https://od.lk/d/ODhfMjA1MDA1NzZf/cubemap4.png", file = "SkyBack.png" },
				{ prop = "SkyboxFt", url = "https://od.lk/d/ODhfMjA1MDA1NzRf/cubemap2.png", file = "SkyFront.png" },
				{ prop = "SkyboxLf", url = "https://od.lk/d/ODhfMjA1MDA1Nzdf/cubemap3.png", file = "SkyLeft.png" },
				{ prop = "SkyboxRt", url = "https://od.lk/d/ODhfMjA1MDA1NzVf/cubemap1.png", file = "SkyRight.png" },
				{ prop = "SkyboxUp", url = "https://od.lk/d/ODhfMjA1MDA1Nzhf/cubemap5.png", file = "SkyTop.png" },
				{ prop = "SkyboxDn", url = "https://od.lk/d/ODhfMjA1MDA1Nzlf/cubemap6.png", file = "SkyDown.png" },
			})
		end,
	}

	local _skyAutoApply = false
	local SkyboxDropdown

	local function _applySelectedSkybox()
		local selected = SkyboxDropdown and SkyboxDropdown.Value
		local fn = selected and BuiltinSkyboxes[selected]
		if fn then
			fn()
		else
			Fluent:Notify({
				Title = "Skybox",
				Content = "Select a skybox from the dropdown first.",
				Duration = 3
			})
		end
	end

	SkyboxDropdown = Tabs.Extension:AddDropdown("BuiltinSkyboxDrop", {
		Title = "Built-in Skybox",
		Values= { "Hakari Hananozo",  "Nakano Miku", "Rias Gremory", "Xenovia Quarta", "Yotsuba Nakano", },
		Multi = false,
		Search= false,
		Default = 1,
	})
	SkyboxDropdown:OnChanged(function()
		if _skyAutoApply then _applySelectedSkybox() end
	end)

	Tabs.Extension:AddToggle("SkyAutoApplyToggle", {
		Title     = "Auto Apply",
		Description = "Automatically applies skybox when the dropdown changes",
		Default   = false,
		Callback  = function(Value)
			_skyAutoApply = Value
			if Value then _applySelectedSkybox() end
		end,
	})

	Tabs.Extension:AddButton({
		Title     = "Apply Built-in Skybox",
		Description = "",
		Callback  = function() task.spawn(_applySelectedSkybox) end,
	})
end

do
	Tabs.Extension:AddSection("Effects Remover")

	local function _getLighting()
		return game:GetService("Lighting")
	end

	Tabs.Extension:AddButton({
		Title     = "Clear All Lighting Effects",
		Description = "Removes Fog, Atmosphere, Bloom, Blur, DepthOfField, SunRays, ColorCorrection",
		Callback  = function()
			local L = _getLighting()
			local removed = 0
			for _, v in pairs(L:GetChildren()) do
				if v:IsA("ColorCorrectionEffect")
					or v:IsA("BloomEffect")  or v:IsA("BlurEffect")
					or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") then
					v.Enabled = false
					removed = removed + 1
				end
			end
			L.FogEnd = 100000
			L.FogStart = 0
			Fluent:Notify({
				Title = "Lighting",
				Content = "Removed " .. removed .. " effect(s) and reset fog.",
				Duration = 3
			})
		end,
	})

	Tabs.Extension:AddButton({
		Title     = "Remove Fog",
		Description = "Pushes FogEnd to maximum to make fog invisible",
		Callback  = function()
			local L = _getLighting()
			L.FogEnd = 100000
			L.FogStart = 0
			Fluent:Notify({
				Title = "Lighting",
				Content = "Fog removed.",
				Duration = 3
			})
		end,
	})

	Tabs.Extension:AddButton({
		Title     = "Remove Atmosphere",
		Description = "Destroys the Atmosphere object from Lighting",
		Callback  = function()
			local L = _getLighting()
			local found = false
			for _, v in pairs(L:GetChildren()) do
				if v:IsA("Atmosphere") then v:Destroy(); found = true end
			end
			Fluent:Notify({
				Title = "Lighting",
				Content = found and "Atmosphere removed." or "No Atmosphere found.",
				Duration = 3
			})
		end,
	})

	Tabs.Extension:AddButton({
		Title     = "Reset Lighting",
		Description = "Restores default Roblox lighting values",
		Callback  = function()
			local L = _getLighting()
			L.FogEnd = 100000
			L.FogStart = 0
			Fluent:Notify({
				Title = "Lighting",
				Content = "Lighting reset to defaults.",
				Duration = 3
			})
		end,
	})
end

Tabs.Extension:AddSection("Lightning Extension")

local normalLighting = {
	Ambient = Lighting.Ambient,
	ColorShift_Bottom = Lighting.ColorShift_Bottom,
	ColorShift_Top = Lighting.ColorShift_Top,
	FogEnd = Lighting.FogEnd,
	FogStart = Lighting.FogStart,
	GlobalShadows = Lighting.GlobalShadows,
	ClockTime = Lighting.ClockTime,
	Brightness = Lighting.Brightness
}

local function applyFullBright()
	Lighting.Ambient = Color3.new(1, 1, 1)
	Lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
	Lighting.ColorShift_Top = Color3.new(1, 1, 1)
	Lighting.FogEnd = 100000
	Lighting.FogStart = 0
	Lighting.GlobalShadows = false
	Lighting.ClockTime = 14
	Lighting.Brightness = 2
end

local function restoreLighting()
	for prop, value in pairs(normalLighting) do
		Lighting[prop] = value
	end
end

local Fullbrighting = false

local Toggle = Tabs.Extension:AddToggle("FullBright", {Title = "Full Bright", Default = false})

Toggle:OnChanged(
	function(state)
		Fullbrighting = state
		if Fullbrighting then
			applyFullBright()
		else
			restoreLighting()
		end
	end
)

Options.FullBright:SetValue(false)

Tabs.Extension:AddSection("Render")

do
	local renderLoop = false
	local renderBusy = false
	local requestedCells = {}

	local CELL = 300      -- studs per streaming cell
	local PER_BATCH = 4   -- requests per step (keeps frame time flat)

	-- Collect one sample point per grid cell (cheap, done once, in slices)
	local function collectCells()
		local cells, seen, n = {}, {}, 0
		for _, obj in ipairs(Workspace:GetDescendants()) do
			n += 1
			if n % 400 == 0 then task.wait() end
			if obj:IsA("BasePart") and obj.Anchored then
				local p = obj.Position
				local key = math.floor(p.X / CELL) .. "," .. math.floor(p.Y / CELL) .. "," .. math.floor(p.Z / CELL)
				if not seen[key] then
					seen[key] = true
					cells[#cells + 1] = { key = key, pos = p }
				end
			end
		end
		return cells
	end

	local function renderWholeGame()
		if renderBusy then return 0 end
		renderBusy = true
		pcall(function() sethiddenproperty(Workspace, "StreamingMinRadius", 2048) end)
		pcall(function() sethiddenproperty(Workspace, "StreamingTargetRadius", 4096) end)

		local done = 0
		local ok = pcall(function()
			local cells = collectCells()
			for i, c in ipairs(cells) do
				if not requestedCells[c.key] then
					requestedCells[c.key] = true
					task.spawn(function()
						pcall(function() LocalPlayer:RequestStreamAroundAsync(c.pos, 0.05) end)
					end)
					done += 1
					if done % PER_BATCH == 0 then
						-- wait a few frames between batches so FPS stays stable
						for _ = 1, 3 do RunService.Heartbeat:Wait() end
					end
				end
			end
		end)
		renderBusy = false
		return done
	end

	Tabs.Extension:AddButton({
		Title = "Render Entire Game",
		Description = "Streams the whole map in small batches (no FPS drop).",
		Callback = function()
			task.spawn(function()
				requestedCells = {}
				local n = renderWholeGame()
				Fluent:Notify({
					Title = "Render",
					Content = "Entire game rendered (" .. tostring(n) .. " areas loaded).",
					Duration = 3
				})
			end)
		end
	})

	local Toggle = Tabs.Extension:AddToggle("Render_Entire_Game", {Title = "Auto Render Entire Game", Default = false})

	Toggle:OnChanged(function(Value)
		renderLoop = Value
		if Value then
			task.spawn(function()
				while renderLoop do
					renderWholeGame()
					task.wait(20)
				end
			end)
		end
	end)

	Options.Render_Entire_Game:SetValue(false)

	-- Max performance: uncapped FPS + lowest-cost render settings
	local perfOn = false
	local perfBackup = {}

	local Perf = Tabs.Extension:AddToggle("Max_Performance", {
		Title = "Max Performance (CPU/GPU)",
		Description = "Uncaps FPS and removes throttling so the device runs at full speed.",
		Default = false
	})

	Perf:OnChanged(function(Value)
		perfOn = Value
		if Value then
			pcall(function() perfBackup.fps = getfpscap and getfpscap() end)
			pcall(function() if setfpscap then setfpscap(0) end end)
			pcall(function() perfBackup.q = settings().Rendering.QualityLevel end)
			pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
			pcall(function() perfBackup.ms = settings().Rendering.MeshPartDetailLevel end)
			pcall(function() settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04 end)
			pcall(function() perfBackup.sh = Lighting.GlobalShadows end)
			pcall(function() Lighting.GlobalShadows = false end)
			pcall(function() settings().Physics.AllowSleep = false end)
			pcall(function() settings().Network.IncomingReplicationLag = 0 end)
			pcall(function() RunService:Set3dRenderingEnabled(true) end)
			Fluent:Notify({ Title = "Performance", Content = "Max performance mode ON", Duration = 3 })
		else
			pcall(function() if setfpscap then setfpscap(perfBackup.fps or 60) end end)
			pcall(function() if perfBackup.q then settings().Rendering.QualityLevel = perfBackup.q end end)
			pcall(function() if perfBackup.ms then settings().Rendering.MeshPartDetailLevel = perfBackup.ms end end)
			pcall(function() if perfBackup.sh ~= nil then Lighting.GlobalShadows = perfBackup.sh end end)
			Fluent:Notify({ Title = "Performance", Content = "Max performance mode OFF", Duration = 3 })
		end
	end)

	Options.Max_Performance:SetValue(false)
end

Tabs.Extension:AddSection("Anti Lags Extension")

local Lag1 = false

local Toggle = Tabs.Extension:AddToggle("Anti_Lag1", {Title = "Anti Lag 1", Default = false})

Toggle:OnChanged(
	function(Value1)
		Lag1 = Value1
		if Lag1 then
			for _, v in pairs(Workspace:GetDescendants()) do
				if v:IsA("BasePart") and not v.Parent:FindFirstChild("Humanoid") then
					v.Material = Enum.Material.SmoothPlastic
					if v:IsA("Texture") then
						v:Destroy()
					end
				end
			end
		end
	end
)

Options.Anti_Lag1:SetValue(false)

local Toggle = Tabs.Extension:AddToggle("Anti_Lag2", {Title = "Anti Lag 2", Default = false})

Toggle:OnChanged(
	function(Value3)
		if Value3 then
			local decalsyeeted = true -- Leaving this on makes games look shitty but the fps goes up by at least 20.
			local g = game
			local w = g.Workspace
			local l = g.Lighting
			local t = w.Terrain
			t.WaterWaveSize = 0
			t.WaterWaveSpeed = 0
			t.WaterReflectance = 0
			t.WaterTransparency = 0
			l.GlobalShadows = false
			l.FogEnd = 9e9
			l.Brightness = 0
			settings().Rendering.QualityLevel = "Level01"
			wait(1)
			for i, v in pairs(g:GetDescendants()) do
				if v:IsA("Part") or v:IsA("Union") or v:IsA("MeshPart") then
					v.Material = "Plastic"
					v.Reflectance = 0
				elseif v:IsA("Decal") and decalsyeeted then
					v.Transparency = 1
				elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
					v.Lifetime = NumberRange.new(0)
				end
			end
		end
	end
)

Options.Anti_Lag2:SetValue(false)

local Toggle = Tabs.Extension:AddToggle("Anti_Lag3", {Title = "Anti Lag 3", Default = false})

Toggle:OnChanged(
	function(Value4)
		if Value4 then
			local decalsyeeted = true
			local g = game
			local w = g.Workspace
			local l = g.Lighting
			local t = w.Terrain
			sethiddenproperty(l, "Technology", 2)
			sethiddenproperty(t, "Decoration", false)
			t.WaterWaveSize = 0
			t.WaterWaveSpeed = 0
			t.WaterReflectance = 0
			t.WaterTransparency = 0
			l.GlobalShadows = 0
			l.FogEnd = 9e9
			l.Brightness = 0
			settings().Rendering.QualityLevel = "Level01"
			for i, v in pairs(w:GetDescendants()) do
				if v:IsA("BasePart") and not v:IsA("MeshPart") then
					v.Material = "Plastic"
					v.Reflectance = 0
				elseif (v:IsA("Decal") or v:IsA("Texture")) and decalsyeeted then
					v.Transparency = 1
				elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
					v.Lifetime = NumberRange.new(0)
				elseif v:IsA("Explosion") then
					v.BlastPressure = 1
					v.BlastRadius = 1
				elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") then
					v.Enabled = false
				elseif v:IsA("MeshPart") and decalsyeeted then
					v.Material = "Plastic"
					v.Reflectance = 0
					v.TextureID = 10385902758728957
				elseif v:IsA("SpecialMesh") and decalsyeeted then
					v.TextureId = 0
				elseif v:IsA("ShirtGraphic") and decalsyeeted then
					v.Graphic = 0
				elseif (v:IsA("Shirt") or v:IsA("Pants")) and decalsyeeted then
					v[v.ClassName .. "Template"] = 0
				end
			end
			for i = 1, #l:GetChildren() do
				e = l:GetChildren()[i]
				if
					e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or
					e:IsA("BloomEffect") or
					e:IsA("DepthOfFieldEffect")
				then
					e.Enabled = false
				end
			end
			w.DescendantAdded:Connect(
				function(v)
					task.wait(1)
					if v:IsA("BasePart") and not v:IsA("MeshPart") then
						v.Material = "Plastic"
						v.Reflectance = 0
					elseif v:IsA("Decal") or v:IsA("Texture") and decalsyeeted then
						v.Transparency = 1
					elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
						v.Lifetime = NumberRange.new(0)
					elseif v:IsA("Explosion") then
						v.BlastPressure = 1
						v.BlastRadius = 1
					elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") then
						v.Enabled = false
					elseif v:IsA("MeshPart") and decalsyeeted then
						v.Material = "Plastic"
						v.Reflectance = 0
						v.TextureID = 10385902758728957
					elseif v:IsA("SpecialMesh") and decalsyeeted then
						v.TextureId = 0
					elseif v:IsA("ShirtGraphic") and decalsyeeted then
						v.ShirtGraphic = 0
					elseif (v:IsA("Shirt") or v:IsA("Pants")) and decalsyeeted then
						v[v.ClassName .. "Template"] = 0
					end
				end
			)
		end
	end
)

Options.Anti_Lag3:SetValue(false)

Tabs.Extension:AddButton({
	Title = "No Render",
	Description = "",
	Callback = function()
		local Lighting = game:GetService("Lighting")
		local Terrain = workspace:FindFirstChildOfClass("Terrain")
		local Players = game:GetService("Players")
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 1e10
		Lighting.Brightness = 1
		if Terrain then
			Terrain.WaterWaveSize = 0
			Terrain.WaterWaveSpeed = 0
			Terrain.WaterReflectance = 0
			Terrain.WaterTransparency = 1
		end
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("BasePart") then
				obj.Material = Enum.Material.Plastic
				obj.Reflectance = 0
			elseif obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
				obj:Destroy()
			elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
				obj:Destroy()
			end
		end
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			if char then
				for _, part in ipairs(char:GetDescendants()) do
					if part:IsA("Accessory") or part:IsA("Clothing") then
						part:Destroy()
					end
				end
			end
		end
	end
})

Tabs.Extension:AddParagraph({
	Title = " ",
	Content = ""
})

local Lighting = game:GetService("Lighting")
local defaultGlobalShadows = Lighting.GlobalShadows
local defaultTechnology = Lighting.Technology

local ShadowsToggle = Tabs.Extension:AddToggle("ShadowsToggle", {
	Title = "Remove All Shadows",
	Description = "",
	Default = false
})

ShadowsToggle:OnChanged(function(state)
	pcall(function()
		Lighting.GlobalShadows = not state
		Lighting.Technology = state and Enum.Technology.Compatibility or defaultTechnology

		task.spawn(function()
			for _, obj in ipairs(workspace:GetDescendants()) do
				if obj:IsA("BasePart") then
					obj.CastShadow = not state
				end
			end
		end)
	end)
end)

local DarknessToggle = Tabs.Extension:AddToggle("DarknessToggle", {
	Title = "Disable Light",
	Description = "",
	Default = false
})

DarknessToggle:OnChanged(function(state)
	task.spawn(function()
		for _, light in ipairs(workspace:GetDescendants()) do
			if light:IsA("Light") then
				pcall(function()
					light.Enabled = not state
				end)
			end
		end
	end)
end)

getgenv().FpsConfig = {
	Enabled = false
}

local function updateFps()
	pcall(function()
		local target = getgenv().FpsConfig.Enabled and 9999 or 60
		if setfflag then
			setfflag("TaskSchedulerTargetFps", tostring(target))
			setfflag("DFIntTaskSchedulerTargetFps", tostring(target))
		end
		if setfpscap then
			setfpscap(target)
		end
	end)
end

local networkPausedConn = nil
local AntiGPTPause = Tabs.Extension:AddToggle("AntiNetworkPause", {
	Title = "Anti Gameplay Paused", 
	Default = false, 
	Description = ""
})

AntiGPTPause:OnChanged(function(Value)
	if Value then
		pcall(function()
			local RobloxGui = game:GetService("CoreGui"):WaitForChild("RobloxGui")
			local currentPause = RobloxGui:FindFirstChild("CoreScripts/NetworkPause")

			if currentPause then 
				currentPause:Destroy() 
			end

			networkPausedConn = RobloxGui.ChildAdded:Connect(function(obj)
				if obj.Name == "CoreScripts/NetworkPause" then
					task.wait() 
					obj:Destroy()
				end
			end)
		end)
	else
		if networkPausedConn then
			networkPausedConn:Disconnect()
			networkPausedConn = nil
		end
	end
end)

local FpsUnlockToggle = Tabs.Extension:AddToggle("FpsUnlockToggle", {
	Title = "Unlock FPS",
	Description = "",
	Default = false
})

FpsUnlockToggle:OnChanged(function(Value)
	getgenv().FpsConfig.Enabled = Value
	updateFps()
end)

game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function(character)
	pcall(function()
		character:WaitForChild("Humanoid", 5)
		task.wait(1)
		if getgenv().FpsConfig.Enabled then
			updateFps()
		end
	end)
end)

if game:GetService("Players").LocalPlayer.Character and getgenv().FpsConfig.Enabled then
	updateFps()
end

Tabs.Extension:AddSection("Fast Flag Extension")

if setfflag then
	Tabs.Extension:AddButton(
		{
			Title = "Blox Strap Script",
			Description = "",
			Callback = function()
				loadstring(game:HttpGet('https://raw.githubusercontent.com/qwertyui-is-back/Bloxstrap/main/Initiate.lua'), 'lol')()
			end
		}
	)

	Tabs.Extension:AddButton(
		{
			Title = "Accurate Low Quality",
			Description = "(FastFlag)",
			Callback = function()

				if setfpscap then
					pcall(function() setfpscap(900) end)
				end

				local function safeSetFFlag(flag, value)
					pcall(function()
						if setfflag then
							setfflag(flag, value)
						end
					end)
				end

				safeSetFFlag("TaskSchedulerTargetFps", "900")

				local function removeWater()
					for _, obj in pairs(workspace:GetDescendants()) do
						if obj:IsA("Terrain") then
							obj.WaterTransparency = 1
							obj.WaterWaveSize = 0
							obj.WaterWaveSpeed = 0
							obj.WaterReflectance = 0
						end
					end
				end

				local function removeReflections()
					local lighting = game:GetService("Lighting")
					lighting.EnvironmentSpecularScale = 0
					lighting.EnvironmentDiffuseScale = 0
				end

				local function removeEffects()
					local lighting = game:GetService("Lighting")
					for _, effect in pairs(lighting:GetChildren()) do
						if effect:IsA("BlurEffect") or effect:IsA("SunRaysEffect") or effect:IsA("BloomEffect") or effect:IsA("DepthOfFieldEffect") then
							effect.Enabled = false
						end
					end

					for _, effect in pairs(workspace:GetDescendants()) do
						if
							effect:IsA("ParticleEmitter") or effect:IsA("Smoke") or effect:IsA("Fire") or
							effect:IsA("Sparkles")
						then
							effect.Enabled = false
						end
					end
				end

				local function removeGrass()
					safeSetFFlag("FRMMinGrassDistance", "0")
					safeSetFFlag("FRMMaxGrassDistance", "0")
					safeSetFFlag("RenderGrassDetailStrands", "0")
				end

				local function removeExplosions()
					for _, explosion in pairs(workspace:GetDescendants()) do
						if explosion:IsA("Explosion") then
							explosion:Destroy()
						end
					end
				end

				local function setLowShadows()
					pcall(function()
						game.Lighting.Technology = Enum.Technology.Voxel
					end)
					game.Lighting.GlobalShadows = false
				end

				local function setLowQuality()
					pcall(function()
						settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
					end)
				end

				local function setFlagsGraphics()
					safeSetFFlag("DebugGraphicsPreferVulkan", "true")
					safeSetFFlag("DebugTextureManagerSkipMips", "2")
					safeSetFFlag("TaskSchedulerLimitTargetFpsTo2402", "false")
					safeSetFFlag("TaskSchedulerTargetFps", "900")   
					safeSetFFlag("FFlagDebugDisableDirectMotionBlur", "true")
					safeSetFFlag("FFlagGraphicsGnm", "true") 
					safeSetFFlag("DFFlagTextureQualityOverride", "1")
					safeSetFFlag("FFlagRenderLocalLightsFrontToBack", "true")
					safeSetFFlag("FFlagRenderFixAA", "false")
					safeSetFFlag("DFreqRenderAntialiasing", "0")
					safeSetFFlag("FFlagVisualEngineEnableLOD", "true")
					safeSetFFlag("FFlagDebugForceAllDecalsLowRes", "true")
				end

				local function reduceLag()
					removeWater()
					removeReflections()
					removeEffects()
					removeExplosions()
					setLowShadows()
					setLowQuality()
					setFlagsGraphics()
					removeGrass()
				end

				reduceLag()

				workspace.DescendantAdded:Connect(
					function(descendant)
						if descendant:IsA("Terrain") then
							task.wait(0.5)
							reduceLag()
						end
					end
				)
			end
		}
	)
end

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
	local Args = {...}
	local method = getnamecallmethod()

	if self.Name == "Communicator" and method == "InvokeServer" and Args[1] == "update" then
		local SpeedCap = DConfiguration.Misc.PlayerAdjustment.Update.RealSpeed or 1500
		local JumpHeight = DConfiguration.Misc.PlayerAdjustment.Update.RealJumpHeight or 3

		return SpeedCap, JumpHeight
	end

	return oldNamecall(self, ...)
end))

LocalPlayer.CharacterAdded:Connect(function(character)
	task.delay(5, function()
		DFunctions.HookMovement(character)
	end)
end)

if LocalPlayer.Character then
	DFunctions.HookMovement(LocalPlayer.Character)
end

-- Settings
Tabs.Settings:AddSection("Settings")

Tabs.Settings:AddButton({
	Title = "Configuration",
	Description = "Customize your interface appearance. Select and apply any theme preset from the options below to match your visual preference.",
	Icon = "network",
	Callback = function()
	end
})

Tabs.Settings:AddButton({
	Title = "Having trouble with interface?",
	Description = "Click this button to destroy the interface.",
	Icon = "shield-alert",
	Callback = function()
		Window:Dialog({
			Title = "Close", 
			Content = "Are you sure you want to unload the interface?",
			Buttons = {
				{
					Title = "Yes",
					Callback = function()
						if Fluent and Fluent.Unload then
							pcall(function() Fluent:Unload() end)
						elseif Fluent and Fluent.GUI then
							pcall(function() Fluent.GUI:Destroy() end)
						end

						task.spawn(function()
							local players = game:GetService("Players")
							local localPlayer = players.LocalPlayer
							local playerGui = localPlayer:WaitForChild("PlayerGui")

							while task.wait(0.5) do
								if Fluent.Unloaded == true or (Fluent.GUI and Fluent.GUI.Parent == nil) then
									openGui:Destroy()
									if fpsCounterGui then fpsCounterGui:Destroy() end

									_G.HyperionHubXIsAlreadyRunning = nil
									break
								end
							end
						end)
					end
				},
				{
					Title = "No",
					Callback = function()
					end
				},
			},
		})
	end
})

Tabs.Settings:AddButton({
	Title = "Performance stats",
	Callback = function(Value)
		if Value then
			CreateFpsCounter()
		else
			DestroyFpsCounter()
		end
	end
})

Tabs.Settings:AddButton({
	Title = "ServerHop",
	Description = "Instantly teleports you to a different server.",
	Icon = "redo",
	Callback = function()
		loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Free-private-server-works-with-any-game-193304"))()
	end
})

pcall(function()
	SaveManager:SetLibrary(Fluent)
	InterfaceManager:SetLibrary(Fluent)
	pcall(function() FBM:SetLibrary(Fluent) end)

	SaveManager:IgnoreThemeSettings()
	SaveManager:SetIgnoreIndexes({})

	InterfaceManager:SetFolder("HyperionHubX")
	pcall(function() FBM:SetFolder("HyperionHubX/Legacy-Evade/FloatingButtons") end)
	SaveManager:SetFolder("HyperionHubX/Legacy-Evade")

	InterfaceManager:BuildInterfaceSection(HXTabs.Settings)
	pcall(function() FBM:BuildConfigSection(HXTabs.Config) end)
	SaveManager:BuildConfigSection(HXTabs.Config)
end)

Window:SelectTab(1)

-- Auto Load Configuration
SaveManager:LoadAutoloadConfig()

-- Unload The Window
task.spawn(function()
	while task.wait(0.5) do
		if Fluent.Unloaded == true or (Fluent.GUI and Fluent.GUI.Parent == nil) then
			if fpsCounterGui then fpsCounterGui:Destroy() end
			openGui:Destroy()

			_G.HyperionHubXIsAlreadyRunning = nil
			task.wait(0.2)

			Fluent:Notify({
				Title = "Interface",
				Content = "Confirmed." .. " - " .. "Windows has been unloaded.",
				Duration = 5
			})
		end

		break
	end
end)