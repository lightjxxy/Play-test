if getgenv().HX_MemeDash_Unload then
    pcall(getgenv().HX_MemeDash_Unload)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local lp = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local STATE = {
    speedOn = false,
    speed = 50,
    airOn = false,
    airAccel = 182,
    wallsOn = false,
    autoJump = false,
    flyOn = false,
    flySpeed = 60,
    lagOn = true,
    lagFlag = 1000,
    lagFlagOn = true,
    trimpOn = false,
    trimpPower = 100,
    bounceOn = false,
    bouncePower = 150,
}

local conns = {}
local function bind(c)
    conns[#conns + 1] = c
    return c
end

local function hum()
    local c = lp.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function hrp()
    local c = lp.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end


----------------------------------------------------------------
-- Movimento: detecta se o jogo usa o mesmo motor do Hyperion Evade
-- (MoveStats/BaseStats). Se usar, speed e air strafe mexem nos valores
-- do motor (é o que funciona). Se não, usa o Humanoid (WalkSpeed) sem
-- brigar com a física.
----------------------------------------------------------------
local Engine = { ok = false, mode = "humanoid", base = nil, tables = nil,
    orig = {}, lastScan = -100, scanning = false, running = true, warned = false,
    defaultWS = 16, wsConn = nil }

do
    local okReq, mod = pcall(function()
        return require(RS.Objects.Game.Character.Client.Movement.MoveStats.BaseStats)
    end)
    if okReq and type(mod) == "table" then
        Engine.base, Engine.ok, Engine.mode = mod, true, "engine"
    end
    local h0 = hum()
    if h0 and h0.WalkSpeed > 0 then Engine.defaultWS = h0.WalkSpeed end
end

local function engineScan()
    if Engine.scanning or (os.clock() - Engine.lastScan) < 3 or type(getgc) ~= "function" then
        return Engine.tables
    end
    Engine.scanning = true
    local res = {}
    local okGc, all = pcall(getgc, true)
    if okGc and type(all) == "table" then
        for i = 1, #all do
            local v = all[i]
            if type(v) == "table"
                and rawget(v, "AirStrafeAcceleration") ~= nil
                and rawget(v, "SprintAcceleration") ~= nil
                and rawget(v, "JumpCap") ~= nil
                and rawget(v, "Friction") ~= nil
            then
                res[#res + 1] = v
            end
            if i % 20000 == 0 then task.wait() end
        end
    end
    Engine.scanning = false
    Engine.lastScan = os.clock()
    if #res > 0 then Engine.tables = res end
    return Engine.tables
end

local function engineWanted()
    local w = {}
    if STATE.speedOn then w.Speed = STATE.speed * 90 end
    if STATE.airOn then w.AirStrafeAcceleration = STATE.airAccel end
    return w
end

function Engine.step()
    if not Engine.ok then return end
    local want = engineWanted()
    if next(want) ~= nil and not Engine.tables then
        engineScan()
        if not Engine.tables and not Engine.warned then
            Engine.warned = true
            warn("[MemeDash] MoveStats nao encontrado; usando so BaseStats. Use 'Copy diagnostic'.")
        end
    end
    for k, v in pairs(want) do
        if Engine.orig[k] == nil and Engine.base[k] ~= nil then Engine.orig[k] = Engine.base[k] end
        if Engine.base[k] ~= v then Engine.base[k] = v end
        if Engine.tables then
            for _, tb in ipairs(Engine.tables) do
                if tb[k] ~= v then tb[k] = v end
            end
        end
    end
    for k, o in pairs(Engine.orig) do
        if want[k] == nil then
            Engine.orig[k] = nil
            Engine.base[k] = o
            if Engine.tables then
                for _, tb in ipairs(Engine.tables) do tb[k] = o end
            end
        end
    end
end

-- modo Humanoid: se o jogo mexer no WalkSpeed, devolve na hora (sem esperar o frame)
local function bindWalkSpeed()
    if Engine.wsConn then Engine.wsConn:Disconnect() Engine.wsConn = nil end
    local h = hum()
    if not h then return end
    Engine.wsConn = h:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if STATE.speedOn and not Engine.ok and h.WalkSpeed ~= STATE.speed then
            h.WalkSpeed = STATE.speed
        end
    end)
end
bindWalkSpeed()

function Engine.onSpawn()
    Engine.tables = nil
    Engine.lastScan = os.clock() - 1
    bindWalkSpeed()
end

function Engine.shutdown()
    Engine.running = false
    if Engine.wsConn then Engine.wsConn:Disconnect() Engine.wsConn = nil end
    if Engine.ok then
        for k, o in pairs(Engine.orig) do
            Engine.base[k] = o
            if Engine.tables then
                for _, tb in ipairs(Engine.tables) do tb[k] = o end
            end
        end
        Engine.orig = {}
    end
    local h = hum()
    if h and not Engine.ok and STATE.speedOn then h.WalkSpeed = Engine.defaultWS end
end

task.spawn(function()
    while Engine.running do
        task.wait(0.3)
        pcall(Engine.step)
    end
end)

local floatParent = lp:WaitForChild("PlayerGui")
pcall(function()
    if gethui then floatParent = gethui() end
end)

local BTN_COLORS = {
    LagSwitch = Color3.fromRGB(255, 130, 90),
    AutoJump = Color3.fromRGB(110, 225, 255),
    Bounce = Color3.fromRGB(100, 200, 255),
}

local function makeFloatBtn(cfg)
    local TweenService = game:GetService("TweenService")
    local LOCK_HOLD = 2.0
    local VIS_HOLD = 3.0
    local DRAG_THRESHOLD = 28
    local BASE_W, BASE_H = cfg.Width or 132, cfg.Height or 46

    local baseColor = cfg.Color or BTN_COLORS[cfg.Name] or Color3.fromRGB(110, 225, 255)
    local active = false
    local visible = true
    local locked = false
    local sizePercent = 100
    local statusOverride = nil

    local old = floatParent:FindFirstChild(cfg.Name .. "Gui")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = cfg.Name .. "Gui"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 300
    gui.Enabled = false
    gui.Parent = floatParent

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
    button.Active = true
    button.Selectable = true
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
    title.TextStrokeTransparency = 0.5
    title.Active = false
    title.ZIndex = 11

    local status = Instance.new("TextLabel")
    status.Parent = button
    status.BackgroundTransparency = 1
    status.Position = UDim2.new(0, 0, 0, 27)
    status.Size = UDim2.new(1, 0, 0, 14)
    status.Font = Enum.Font.GothamMedium
    status.TextSize = 11
    status.Text = cfg.StatusOff or "OFF"
    status.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    status.TextStrokeTransparency = 0.7
    status.Active = false
    status.ZIndex = 11

    local function lighten(c, a)
        return c:Lerp(Color3.new(1, 1, 1), a)
    end

    local function applyLook()
        title.TextTransparency = visible and 0 or 1
        title.TextStrokeTransparency = visible and 0.5 or 1
        status.TextTransparency = visible and 0 or 1
        status.TextStrokeTransparency = visible and 0.7 or 1
        button.BackgroundTransparency = visible and 0.85 or 1
        stroke.Transparency = visible and (active and 0.15 or 0.35) or 1

        local statusText
        if statusOverride ~= nil and statusOverride ~= "" then
            statusText = tostring(statusOverride)
        else
            statusText = active and (cfg.StatusOn or "ON") or (cfg.StatusOff or "OFF")
        end

        if active then
            button.BackgroundColor3 = baseColor:Lerp(Color3.new(0, 0, 0), 0.6)
            stroke.Color = baseColor
            status.TextColor3 = lighten(baseColor, 0.35)
        else
            button.BackgroundColor3 = Color3.fromRGB(10, 14, 24)
            stroke.Color = Color3.fromRGB(255, 255, 255)
            status.TextColor3 = Color3.fromRGB(175, 180, 195)
        end
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        if locked then
            statusText = statusText .. " 🔒"
        end
        status.Text = statusText
    end

    local function tweenScale(s)
        TweenService:Create(uiScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Scale = s }):Play()
    end

    local spin = RunService.RenderStepped:Connect(function()
        if not gui.Parent then return end
        local t = os.clock() * 1.2
        grad.Rotation = (t * 60) % 360
        grad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, baseColor),
            ColorSequenceKeypoint.new(0.5, lighten(baseColor, 0.45)),
            ColorSequenceKeypoint.new(1, baseColor),
        })
    end)

    local token = 0
    local dragging, moved = false, false
    local dragStart, startPos
    local holdLock, holdVis = false, false
    local suppressClick = false

    local function doClick()
        if suppressClick or moved or not visible then return end
        if cfg.OnClick then
            pcall(cfg.OnClick)
        end
    end

    button.MouseButton1Click:Connect(function()
        doClick()
    end)
    button.Activated:Connect(function()
    end)

    button.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        token += 1
        local myToken = token
        moved = false
        suppressClick = false
        holdLock, holdVis = false, false
        dragStart = input.Position
        startPos = button.Position
        dragging = not locked
        tweenScale(sizePercent / 100 * 0.92)

        task.delay(LOCK_HOLD, function()
            if myToken ~= token or moved then return end
            holdLock = true
            suppressClick = true
            locked = not locked
            dragging = false
            applyLook()
            pcall(function()
                if WindUI then
                    WindUI:Notify({
                        Title = (cfg.Label or cfg.Name) .. (locked and " Locked" or " Unlocked"),
                        Content = locked and "Button locked in place." or "Button can be moved.",
                        Duration = 2,
                    })
                end
            end)
        end)

        task.delay(VIS_HOLD, function()
            if myToken ~= token or moved then return end
            holdVis = true
            suppressClick = true
            visible = not visible
            applyLook()
            pcall(function()
                if WindUI then
                    WindUI:Notify({
                        Title = (cfg.Label or cfg.Name) .. (visible and " Visible" or " Hidden"),
                        Content = visible and "Button visible." or "Hold again to show.",
                        Duration = 2,
                    })
                end
            end)
        end)
    end)

    button.InputEnded:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        token += 1
        dragging = false
        tweenScale(sizePercent / 100)
    end)

    UIS.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        if not dragStart then return end
        local dx = input.Position.X - dragStart.X
        local dy = input.Position.Y - dragStart.Y
        if not moved and Vector2.new(dx, dy).Magnitude > DRAG_THRESHOLD then
            moved = true
            suppressClick = true
        end
        if moved and not locked then
            button.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + dx,
                startPos.Y.Scale, startPos.Y.Offset + dy
            )
        end
    end)

    local self = {}
    function self:SetEnabled(v)
        gui.Enabled = v and true or false
    end
    function self:SetActive(v)
        active = v and true or false
        applyLook()
    end
    function self:SetStatusText(t)
        statusOverride = t
        applyLook()
    end
    function self:SetText(t)
        title.Text = tostring(t)
    end
    function self:SetSizePercent(p)
        sizePercent = math.clamp(tonumber(p) or 100, 30, 300)
        uiScale.Scale = sizePercent / 100
    end
    function self:Destroy()
        pcall(function() spin:Disconnect() end)
        gui:Destroy()
    end
    self.Gui = gui

    applyLook()
    return self
end

local freezeCd = false
local function setLagFlag(value)
    value = tostring(value)
    pcall(function()
        if setfflag then
            setfflag("MaxMissedWorldStepsRemembered", value)
            setfflag("WorldStepMax", value)
            setfflag("TaskSchedulerLimitTargetFpsToPhysical2d", "False")
        end
    end)
    pcall(function()
        if setfflag then
            setfflag("S2PhysicsSenderRate", value == "1" and "15" or "1")
        end
    end)
end

local function setNetLag(seconds)
    pcall(function()
        settings().Network.IncomingReplicationLag = seconds
    end)
end

setLagFlag(1)
setNetLag(0)

local lagBtn
local function freezeNow()
    if freezeCd then return end
    freezeCd = true

    STATE.lagOn = true

    if lagBtn then
        lagBtn:SetActive(true)
        lagBtn:SetStatusText("Freezing...")
    end

    local flagVal = STATE.lagFlagOn and (tonumber(STATE.lagFlag) or 1000) or 1000
    if flagVal < 1 then flagVal = 1000 end

    setLagFlag(flagVal)
    setNetLag(math.clamp(flagVal / 200, 1, 8))

    local t0 = os.clock()
    while os.clock() - t0 < 0.45 do
        local a = 0
        for i = 1, 450000 do a += i end
    end

    setLagFlag(1)
    setNetLag(0)

    task.spawn(function()
        local cd = 1
        for i = cd, 1, -1 do
            if lagBtn then lagBtn:SetStatusText("Cooldown: " .. i) end
            task.wait(1)
        end
        if lagBtn then
            lagBtn:SetStatusText("Ready")
            lagBtn:SetActive(false)
        end
        freezeCd = false
    end)
end

lagBtn = makeFloatBtn({
    Name = "LagSwitch",
    Label = "Freeze Now",
    StatusOff = "Ready",
    StatusOn = "Freezing...",
    Position = UDim2.new(0.75, 0, 0.2, 0),
    Color = BTN_COLORS.LagSwitch,
    OnClick = freezeNow,
})
lagBtn:SetActive(false)
lagBtn:SetStatusText("Ready")

local ajBtn = makeFloatBtn({
    Name = "AutoJump",
    Label = "Auto Jump",
    StatusOff = "OFF",
    StatusOn = "ON",
    Position = UDim2.new(0.2, 0, 0.75, 0),
    Color = BTN_COLORS.AutoJump,
    OnClick = function()
        STATE.autoJump = not STATE.autoJump
        ajBtn:SetActive(STATE.autoJump)
        ajBtn:SetStatusText(STATE.autoJump and "ON" or "OFF")
    end,
})
ajBtn:SetActive(false)
ajBtn:SetStatusText("OFF")

local bounceBtn = makeFloatBtn({
    Name = "Bounce",
    Label = "Auto Bounce",
    StatusOff = "OFF",
    StatusOn = "ON",
    Position = UDim2.new(0.5, 0, 0.75, 0),
    Color = BTN_COLORS.Bounce,
    OnClick = function()
        STATE.bounceOn = not STATE.bounceOn
        bounceBtn:SetActive(STATE.bounceOn)
        bounceBtn:SetStatusText(STATE.bounceOn and "ON" or "OFF")
    end,
})
bounceBtn:SetActive(false)
bounceBtn:SetStatusText("OFF")

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Hyperion · MemeDash",
    Author = "Hyperion Hub X",
    Folder = "HyperionMemeDash",
    Size = UDim2.fromOffset(560, 440),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 160,
})

local MainTab = Window:Tab({ Title = "Main", Icon = "zap" })
local UtilTab = Window:Tab({ Title = "Utility", Icon = "wrench" })
local LagTab = Window:Tab({ Title = "Lagswitch", Icon = "snowflake" })
local MapTab = Window:Tab({ Title = "Map", Icon = "map" })

MainTab:Section({ Title = "Movement", TextSize = 14 })

MainTab:Toggle({
    Title = "Speed Changer",
    Desc = "Instant WalkSpeed every frame",
    Value = false,
    Callback = function(v)
        STATE.speedOn = v and true or false
        local h = hum()
        if not Engine.ok and h then
            h.WalkSpeed = STATE.speedOn and STATE.speed or Engine.defaultWS
        end
    end,
})

MainTab:Slider({
    Title = "Speed",
    Step = 1,
    Value = { Min = 16, Max = 300, Default = 50 },
    Callback = function(v)
        STATE.speed = tonumber(v) or STATE.speed
        local h = hum()
        if STATE.speedOn and h and not Engine.ok then
            h.WalkSpeed = STATE.speed
        end
    end,
})

MainTab:Space()

MainTab:Toggle({
    Title = "Air Strafe Accel",
    Desc = "Boost while airborne (not only Freefall)",
    Value = false,
    Callback = function(v)
        STATE.airOn = v and true or false
    end,
})

MainTab:Slider({
    Title = "Air Acceleration",
    Step = 1,
    Value = { Min = 10, Max = 1000, Default = 182 },
    Callback = function(v)
        STATE.airAccel = tonumber(v) or STATE.airAccel
    end,
})

MainTab:Space()

MainTab:Toggle({
    Title = "Fly",
    Value = false,
    Callback = function(v)
        STATE.flyOn = v and true or false
        local h = hum()
        if h then h.PlatformStand = STATE.flyOn end
    end,
})

MainTab:Slider({
    Title = "Fly Speed",
    Step = 1,
    Value = { Min = 10, Max = 250, Default = 60 },
    Callback = function(v)
        STATE.flySpeed = tonumber(v) or STATE.flySpeed
    end,
})

MainTab:Space()

MainTab:Toggle({
    Title = "Auto Jump",
    Desc = "Spams jump every frame until you turn it off",
    Value = false,
    Callback = function(v)
        STATE.autoJump = v and true or false
        if ajBtn then
            ajBtn:SetActive(STATE.autoJump)
            ajBtn:SetStatusText(STATE.autoJump and "ON" or "OFF")
        end
    end,
})

MainTab:Toggle({
    Title = "Auto Jump Button",
    Value = false,
    Callback = function(v)
        if ajBtn then ajBtn:SetEnabled(v) end
    end,
})

MainTab:Space()

MainTab:Toggle({
    Title = "Easy Edge Trimp",
    Desc = "Like Hyperion Evade: boost up when hitting an edge while falling",
    Value = false,
    Callback = function(v)
        STATE.trimpOn = v and true or false
    end,
})

MainTab:Slider({
    Title = "Edge Trimp Power",
    Step = 10,
    Value = { Min = 50, Max = 400, Default = 100 },
    Callback = function(v)
        STATE.trimpPower = tonumber(v) or STATE.trimpPower
    end,
})

MainTab:Space()

MainTab:Section({ Title = "Bounce", TextSize = 14 })

MainTab:Toggle({
    Title = "Auto Bounce",
    Desc = "Launches you upward every time you touch the floor",
    Value = false,
    Callback = function(v)
        STATE.bounceOn = v and true or false
        if bounceBtn then
            bounceBtn:SetActive(STATE.bounceOn)
            bounceBtn:SetStatusText(STATE.bounceOn and "ON" or "OFF")
        end
    end,
})

MainTab:Slider({
    Title = "Bounce Power",
    Step = 10,
    Value = { Min = 50, Max = 800, Default = 150 },
    Callback = function(v)
        STATE.bouncePower = tonumber(v) or STATE.bouncePower
    end,
})

MainTab:Toggle({
    Title = "Bounce Button",
    Desc = "Show/hide the mobile float button",
    Value = false,
    Callback = function(v)
        if bounceBtn then bounceBtn:SetEnabled(v) end
    end,
})

UtilTab:Section({ Title = "Helpers", TextSize = 14 })

UtilTab:Toggle({
    Title = "Invis Wall Remover",
    Value = false,
    Callback = function(v)
        STATE.wallsOn = v and true or false
        if STATE.wallsOn then
            task.spawn(function()
                for _, inst in ipairs(Workspace:GetDescendants()) do
                    if inst:IsA("BasePart") and inst.Transparency >= 1 and inst.CanCollide then
                        inst.CanCollide = false
                    end
                end
            end)
        end
    end,
})


UtilTab:Button({
    Title = "Copy diagnostic",
    Justify = "Center",
    Callback = function()
        local L = {}
        local function add(s) L[#L + 1] = tostring(s) end
        add("mode=" .. Engine.mode .. " baseStats=" .. tostring(Engine.base ~= nil)
            .. " liveTables=" .. tostring(Engine.tables and #Engine.tables or 0))
        local h = hum()
        if h then
            add(("Humanoid WalkSpeed=%s UseJumpPower=%s JumpPower=%s JumpHeight=%s state=%s floor=%s PlatformStand=%s"):format(
                tostring(h.WalkSpeed), tostring(h.UseJumpPower), tostring(h.JumpPower),
                tostring(h.JumpHeight), tostring(h:GetState()), tostring(h.FloorMaterial), tostring(h.PlatformStand)))
        end
        local char = lp.Character
        if char then
            for _, d in ipairs(char:GetDescendants()) do
                if d:IsA("BodyMover") or d:IsA("LinearVelocity") or d:IsA("VectorForce")
                    or d:IsA("AlignPosition") or d:IsA("AlignOrientation") or d:IsA("PlaneConstraint") then
                    add("mover: " .. d:GetFullName())
                end
            end
        end
        local n = 0
        pcall(function()
            local o = RS:FindFirstChild("Objects")
            if o then
                for _, d in ipairs(o:GetDescendants()) do
                    if d:IsA("ModuleScript") then
                        local nm = d.Name:lower()
                        if nm:find("move") or nm:find("stat") or nm:find("jump") or nm:find("state")
                            or nm:find("constraint") or nm:find("control") then
                            n += 1
                            if n <= 80 then add("module: " .. d:GetFullName()) end
                        end
                    end
                end
            end
        end)
        n = 0
        pcall(function()
            for _, d in ipairs(lp.PlayerScripts:GetDescendants()) do
                if d:IsA("LocalScript") or d:IsA("ModuleScript") then
                    n += 1
                    if n <= 60 then add("playerscript: " .. d:GetFullName()) end
                end
            end
        end)
        local text = table.concat(L, "\n")
        pcall(function() if setclipboard then setclipboard(text) end end)
        pcall(function() if writefile then writefile("memedash_diag.txt", text) end end)
        print(text)
        WindUI:Notify({ Title = "Diagnostic", Content = "Copied (mode: " .. Engine.mode .. ")", Duration = 3 })
    end,
})

UtilTab:Button({
    Title = "Clear transparent colliders",
    Justify = "Center",
    Callback = function()
        local n = 0
        for _, inst in ipairs(Workspace:GetDescendants()) do
            if inst:IsA("BasePart") and inst.Transparency >= 0.95 and inst.CanCollide then
                inst.CanCollide = false
                n += 1
            end
        end
        WindUI:Notify({ Title = "Walls", Content = "Cleared " .. n, Duration = 3 })
    end,
})

LagTab:Section({ Title = "FFlag Lagswitch", TextSize = 14 })

LagTab:Toggle({
    Title = "FFlag for Lagswitch",
    Desc = "Arms lagswitch (flag applied only while freezing)",
    Value = true,
    Callback = function(v)
        STATE.lagOn = v and true or false
        setLagFlag(1)
        setNetLag(0)
    end,
})

LagTab:Toggle({
    Title = "Lagswitch Button",
    Value = false,
    Callback = function(v)
        if lagBtn then lagBtn:SetEnabled(v) end
    end,
})

LagTab:Slider({
    Title = "FFlag Value",
    Step = 10,
    Value = { Min = 0, Max = 1000, Default = 1000 },
    Callback = function(v)
        STATE.lagFlag = tonumber(v) or STATE.lagFlag
    end,
})

LagTab:Button({
    Title = "Freeze Now",
    Justify = "Center",
    Callback = freezeNow,
})

MapTab:Section({ Title = "Server attempts", TextSize = 14 })

MapTab:Button({
    Title = "Try Map Regen",
    Justify = "Center",
    Callback = function()
        local found = {}
        local function scan(root)
            for _, d in ipairs(root:GetDescendants()) do
                if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
                    local n = string.lower(d.Name)
                    if n:find("regen") or n:find("reset") or n:find("map")
                        or n:find("reload") or n:find("stage") or n:find("generate") then
                        found[#found + 1] = d
                    end
                end
            end
        end
        pcall(scan, RS)
        pcall(scan, Workspace)
        for _, remote in ipairs(found) do
            for _, args in ipairs({ {}, { true }, { "reset" }, { "regen" }, { 1 } }) do
                pcall(function()
                    if remote:IsA("RemoteEvent") then remote:FireServer(table.unpack(args))
                    else remote:InvokeServer(table.unpack(args)) end
                end)
            end
        end
        WindUI:Notify({ Title = "Map", Content = "Fired " .. #found .. " remotes", Duration = 3 })
    end,
})

local lastTrimp = 0
local lastAutoJump = 0
local wasGrounded = false
bind(RunService.Heartbeat:Connect(function(dt)
    local h = hum()
    local root = hrp()
    if not h or not root then return end

    -- Speed: só WalkSpeed (antes também forçava a velocidade a cada frame, o que brigava
    -- com o jogo e deixava o movimento bugado). No modo "engine" o Engine.step cuida disso.
    if STATE.speedOn and not Engine.ok then
        if h.WalkSpeed ~= STATE.speed then
            h.WalkSpeed = STATE.speed
        end
    end

    if STATE.airOn and not Engine.ok then
        local airborne = h.FloorMaterial == Enum.Material.Air
            or h:GetState() == Enum.HumanoidStateType.Freefall
            or h:GetState() == Enum.HumanoidStateType.Jumping
            or h:GetState() == Enum.HumanoidStateType.FallingDown
        if airborne then
            local dir = h.MoveDirection
            if dir.Magnitude > 0.05 then
                local v = root.AssemblyLinearVelocity
                local add = dir.Unit * (STATE.airAccel * math.clamp(dt, 0, 0.05))
                local nv = Vector3.new(v.X + add.X, v.Y, v.Z + add.Z)
                -- o teto nunca reduz a velocidade que você já tem
                local cur = Vector3.new(v.X, 0, v.Z).Magnitude
                local maxAir = math.max(STATE.speed * 1.5, 80, cur)
                local horiz = Vector3.new(nv.X, 0, nv.Z)
                if horiz.Magnitude > maxAir then
                    horiz = horiz.Unit * maxAir
                    nv = Vector3.new(horiz.X, nv.Y, horiz.Z)
                end
                root.AssemblyLinearVelocity = nv
            end
        end
    end

    -- Auto Jump: só pula quando está NO CHÃO (igual ao do Hyperion Evade). Antes forçava o
    -- estado de pulo todo frame, mesmo no ar, e isso empurrava o personagem pra cima = voar.
    if STATE.autoJump then
        local now = os.clock()
        if h.Health > 0 and not h.Sit and h.FloorMaterial ~= Enum.Material.Air
            and now - lastAutoJump > 0.1 then
            local st = h:GetState()
            if st ~= Enum.HumanoidStateType.Jumping and st ~= Enum.HumanoidStateType.Freefall
                and st ~= Enum.HumanoidStateType.Dead then
                lastAutoJump = now
                if not h.UseJumpPower and h.JumpHeight < 1 then h.JumpHeight = 7.2 end
                h:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
                h:ChangeState(Enum.HumanoidStateType.Jumping)
                h.Jump = true
            end
        end
    end

    if STATE.trimpOn then
        local v = root.AssemblyLinearVelocity
        if v.Y < -35 then
            local touching = false
            pcall(function()
                local parts = root:GetTouchingParts()
                if #parts > 0 then touching = true end
            end)
            if not touching then
                local ray = Workspace:Raycast(root.Position, root.CFrame.LookVector * 2.2 + Vector3.new(0, -1, 0))
                if ray and ray.Instance and ray.Instance.CanCollide then
                    touching = true
                end
            end
            if touching then
                local now = os.clock()
                if now - lastTrimp > 0.08 then
                    lastTrimp = now
                    local horizontal = Vector3.new(v.X, 0, v.Z)
                    root.AssemblyLinearVelocity = horizontal + Vector3.new(0, STATE.trimpPower, 0)
                end
            end
        end
    end

    if STATE.flyOn then
        local move = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then move += camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then move -= camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then move -= camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then move += camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.C) then move -= Vector3.yAxis end
        if move.Magnitude > 0 then
            root.AssemblyLinearVelocity = move.Unit * STATE.flySpeed
        else
            root.AssemblyLinearVelocity = Vector3.zero
        end
    end

    if STATE.wallsOn then
        for _, inst in ipairs(Workspace:GetPartBoundsInRadius(root.Position, 45)) do
            if inst:IsA("BasePart") and inst.Transparency >= 1 and inst.CanCollide then
                inst.CanCollide = false
            end
        end
    end

    if STATE.bounceOn then
        if h.FloorMaterial ~= Enum.Material.Air then
            root.AssemblyLinearVelocity = Vector3.new(
                root.AssemblyLinearVelocity.X,
                STATE.bouncePower,
                root.AssemblyLinearVelocity.Z
            )
        end
    end
end))

bind(lp.CharacterAdded:Connect(function()
    task.wait(0.2)
    Engine.onSpawn()
    if STATE.flyOn then
        local h = hum()
        if h then h.PlatformStand = true end
    end
    if STATE.speedOn and not Engine.ok then
        local h = hum()
        if h then h.WalkSpeed = STATE.speed end
    end
end))

getgenv().HX_MemeDash_Unload = function()
    pcall(Engine.shutdown)
    pcall(function() setLagFlag(1) end)
    pcall(function() setNetLag(0) end)
    for _, c in ipairs(conns) do
        pcall(function() c:Disconnect() end)
    end
    pcall(function() if lagBtn and lagBtn.Gui then lagBtn.Gui:Destroy() end end)
    pcall(function() if ajBtn and ajBtn.Gui then ajBtn.Gui:Destroy() end end)
    pcall(function() if bounceBtn and bounceBtn.Gui then bounceBtn.Gui:Destroy() end end)
    pcall(function() if Window and Window.Destroy then Window:Destroy() end end)
    getgenv().HX_MemeDash_Unload = nil
end

WindUI:Notify({
    Title = "Hyperion · MemeDash",
    Content = "Loaded (WindUI)",
    Duration = 3,
})