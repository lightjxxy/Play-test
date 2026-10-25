-- lang: Lua, file: hub.lua, target: Roblox LocalScript, build: Hyperion Hub X
-- *paste into a LocalScript inside StarterPlayerScripts or a loader*

--// ── SERVICES ────────────────────────────────────────────────────────────────
local UIS          = game:GetService("UserInputService")
local RS           = game:GetService("RunService")
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

--// ── FLUENT STACK ────────────────────────────────────────────────────────────
local Fluent           = loadstring(game:HttpGet("https://raw.githubusercontent.com/StyearX/Script/refs/heads/main/Phantomwrym/Fluent-modded/Main.lua"))()
local SaveManager      = loadstring(game:HttpGet("https://raw.githubusercontent.com/StyearX/Script/refs/heads/main/Phantomwrym/Fluent-modded/SaveManager.lua"))()
local FBM              = loadstring(game:HttpGet("https://raw.githubusercontent.com/StyearX/Script/refs/heads/main/Phantomwrym/Fluent-modded/FloatingButtonManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/StyearX/Script/refs/heads/main/Phantomwrym/Fluent-modded/InterfaceManager.lua"))()

--// ── PLAYER / CHARACTER ──────────────────────────────────────────────────────
local lp   = Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()
local hum  = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

lp.CharacterAdded:Connect(function(c)
    char = c
    hum  = c:WaitForChild("Humanoid")
    root = c:WaitForChild("HumanoidRootPart")
end)

--// ── BOUNCE STATE ────────────────────────────────────────────────────────────
local bounceOn  = false
local bouncePow = 150

RS.Heartbeat:Connect(function()
    if bounceOn and char and root and hum then
        if hum.FloorMaterial ~= Enum.Material.Air then
            root.AssemblyLinearVelocity = Vector3.new(
                root.AssemblyLinearVelocity.X,
                bouncePow,
                root.AssemblyLinearVelocity.Z
            )
        end
    end
end)

--// ── FLUENT WINDOW ───────────────────────────────────────────────────────────
local Window = Fluent:CreateWindow({
    Title       = "Hyperion Hub X",
    SubTitle    = "Made by Nymmz and Lucaswyrm",
    TabWidth    = 160,
    Size        = UDim2.fromOffset(580, 460),
    Acrylic     = true,
    Theme       = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl,
})

local Tabs = {
    Main     = Window:AddTab({ Title = "Main",     Icon = "home"     }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
}

Tabs.Main:AddToggle("AutoBounce", {
    Title       = "Auto Bounce",
    Description = "Continuously launches your character upward",
    Default     = false,
    Callback    = function(v) bounceOn = v end,
})

Tabs.Main:AddSlider("BouncePower", {
    Title       = "Bounce Power",
    Description = "Vertical launch force  (50 – 800)",
    Default     = 150,
    Min         = 50,
    Max         = 800,
    Rounding    = 0,
    Callback    = function(v) bouncePow = v end,
})

InterfaceManager:SetLibrary(Fluent)
SaveManager:SetLibrary(Fluent)
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoSave()

--// ── FLOATING BUTTON ─────────────────────────────────────────────────────────
local old = lp.PlayerGui:FindFirstChild("HyperionFloat")
if old then old:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name           = "HyperionFloat"
sg.ResetOnSpawn   = false
sg.IgnoreGuiInset = true
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent         = lp.PlayerGui

local circle = Instance.new("Frame")
circle.Name             = "Circle"
circle.Size             = UDim2.fromOffset(62, 62)
circle.Position         = UDim2.new(0, 24, 0.5, -31)
circle.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
circle.Active           = true
circle.Parent           = sg
Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

local stroke = Instance.new("UIStroke", circle)
stroke.Color     = Color3.fromRGB(100, 100, 210)
stroke.Thickness = 2

local lbl = Instance.new("TextLabel", circle)
lbl.Size                   = UDim2.new(1, 0, 1, 0)
lbl.BackgroundTransparency = 1
lbl.Text                   = "H"
lbl.TextColor3             = Color3.new(1, 1, 1)
lbl.TextSize               = 22
lbl.Font                   = Enum.Font.GothamBold

local lockRing = Instance.new("Frame", circle)
lockRing.Size                   = UDim2.new(1, 10, 1, 10)
lockRing.Position               = UDim2.new(0, -5, 0, -5)
lockRing.BackgroundColor3       = Color3.fromRGB(0, 255, 120)
lockRing.BackgroundTransparency = 1
lockRing.ZIndex                 = 0
Instance.new("UICorner", lockRing).CornerRadius = UDim.new(1, 0)

local minBtn = Instance.new("TextButton", circle)
minBtn.Name             = "MinBtn"
minBtn.Size             = UDim2.fromOffset(20, 20)
minBtn.Position         = UDim2.new(1, -20, 0, 0)
minBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 85)
minBtn.Text             = "–"
minBtn.TextColor3       = Color3.new(1, 1, 1)
minBtn.TextSize         = 13
minBtn.Font             = Enum.Font.GothamBold
minBtn.ZIndex           = 8
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(1, 0)

local hitbox = Instance.new("TextButton", circle)
hitbox.Size                   = UDim2.new(1, 0, 1, 0)
hitbox.BackgroundTransparency = 1
hitbox.Text                   = ""
hitbox.ZIndex                 = 7

--// ── STATE ───────────────────────────────────────────────────────────────────
local locked      = false
local minimized   = false
local hubVisible  = true
local invisible   = false
local holdStart   = nil
local holdThread  = nil
local dragging    = false
local dragOrigin  = nil
local circleStart = nil
local DRAG_THRESH = 7

local function cancelTimer()
    if holdThread then task.cancel(holdThread) end
    holdThread = nil
end

local function toggleHub()
    hubVisible = not hubVisible
    local guiObj = Window.Gui or Window.MainGui or Window.ScreenGui
    if guiObj then guiObj.Enabled = hubVisible end
end

local function setCircleAlpha(a)
    circle.BackgroundTransparency  = a
    lbl.TextTransparency           = a
    stroke.Transparency            = a
    minBtn.BackgroundTransparency  = a
    minBtn.TextTransparency        = a
end

local function setMinimized(state)
    minimized = state
    if state then
        TweenService:Create(circle, TweenInfo.new(0.18), { Size = UDim2.fromOffset(36, 36) }):Play()
        lbl.Text       = "●"
        minBtn.Visible = false
    else
        TweenService:Create(circle, TweenInfo.new(0.18), { Size = UDim2.fromOffset(62, 62) }):Play()
        lbl.Text       = "H"
        minBtn.Visible = true
    end
end

minBtn.MouseButton1Click:Connect(function()
    setMinimized(not minimized)
end)

--// ── INPUT: press ────────────────────────────────────────────────────────────
hitbox.InputBegan:Connect(function(input)
    local t = input.UserInputType
    if t ~= Enum.UserInputType.MouseButton1
    and t ~= Enum.UserInputType.Touch then return end

    holdStart   = tick()
    dragging    = false
    dragOrigin  = input.Position
    circleStart = circle.Position

    holdThread = task.spawn(function()

        if invisible then
            -- hold 3s to restore from invisible
            task.wait(3)
            if holdStart == nil then return end
            invisible = false
            holdStart = nil
            cancelTimer()
            TweenService:Create(circle, TweenInfo.new(0.25),
                { BackgroundTransparency = 0 }):Play()
            lbl.TextTransparency          = 0
            stroke.Transparency           = 0
            minBtn.BackgroundTransparency = 0
            minBtn.TextTransparency       = 0

        elseif locked then
            -- hold 2s to unlock
            task.wait(2)
            if holdStart == nil then return end
            locked = false
            holdStart = nil
            cancelTimer()
            TweenService:Create(lockRing, TweenInfo.new(0.2),
                { BackgroundTransparency = 1 }):Play()

        else
            -- normal: 2s locks, 3s goes invisible
            task.wait(2)
            if holdStart == nil then return end
            locked = true
            TweenService:Create(lockRing, TweenInfo.new(0.2),
                { BackgroundTransparency = 0.45 }):Play()

            task.wait(1)
            if holdStart == nil then return end
            invisible = true
            holdStart = nil
            cancelTimer()
            TweenService:Create(circle, TweenInfo.new(0.25),
                { BackgroundTransparency = 1 }):Play()
            lbl.TextTransparency          = 1
            stroke.Transparency           = 1
            minBtn.BackgroundTransparency = 1
            minBtn.TextTransparency       = 1
        end
    end)
end)

--// ── INPUT: move ─────────────────────────────────────────────────────────────
UIS.InputChanged:Connect(function(input)
    local t = input.UserInputType
    if t ~= Enum.UserInputType.MouseMovement
    and t ~= Enum.UserInputType.Touch then return end
    if holdStart == nil or locked or invisible then return end

    local delta = input.Position - dragOrigin
    if delta.Magnitude > DRAG_THRESH then
        dragging = true
        cancelTimer()
    end

    if dragging then
        circle.Position = UDim2.new(
            circleStart.X.Scale,
            circleStart.X.Offset + delta.X,
            circleStart.Y.Scale,
            circleStart.Y.Offset + delta.Y
        )
    end
end)

--// ── INPUT: release ──────────────────────────────────────────────────────────
UIS.InputEnded:Connect(function(input)
    local t = input.UserInputType
    if t ~= Enum.UserInputType.MouseButton1
    and t ~= Enum.UserInputType.Touch then return end
    if holdStart == nil then return end

    local elapsed = holdStart and (tick() - holdStart) or 99
    local wasDrag = dragging

    cancelTimer()
    holdStart = nil
    dragging  = false

    if wasDrag then return end

    if not locked and not invisible and elapsed < 1.8 then
        if minimized then
            setMinimized(false)
        else
            toggleHub()
        end
    end
end)
