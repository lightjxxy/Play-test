-- Memetrash

if getgenv().MT_Unload then
    pcall(getgenv().MT_Unload)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local lp = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local WindUI

local STATE = {

    speedOn = false, speed = 50,
    airOn = false, airAccel = 182,
    flyOn = false, flySpeed = 60,
    frontalOn = false, frontalSpeed = 60,
    backOn = false, backSpeed = 60,

    autoJump = false,
    bounceOn = false, bouncePower = 150,
    crouchOn = false, crouchSpeed = 7,
    edgeTrimpOn = false,
    edgeLaunchMult = 1.5, edgeLaunchCap = 95, edgeLaunchFloor = 30,
    edgeCastDist = 6, edgeMinSpeed = 12, edgeConeWidth = 0.35,
    edgeEdgeDrop = 3, edgeCooldown = 0.35, edgeNormalDotMin = 0.707,

    lagMode = "Freeze", lagDuration = 0.45,

    farmOn = false, farmExtra = 150,
    antiBlock = false, antiBlockKeyword = "nextbot,hitbox",

    wallsOn = false,
    vipStrafeOn = false, vipStrafeMult = 1,
    vipSpeedOn = false, vipSpeed = 60,
    vipJumpOn = false, vipJump = 10,
    vipSkyOn = false,
    amoledOn = false,

    uiBlur = false,
    neonAura = true,
    activateFx = true,
    uiAccent = "Cyan",

    espOn = false,
    espBox = true,
    espName = true,
    espDist = true,
    espTracer = false,
    espTeam = false,
    espColor = Color3.fromRGB(0, 229, 255),
    espOutline = Color3.fromRGB(255, 255, 255),
    espFill = true,
    espLine = true,
    espMaxDist = 2000,
    spinOn = false,
    spinSpeed = 12,
    flingOn = false,
    flingForce = 180,
    voteOn = false,
    voteMap = "",
    voteCount = 5,
    keybindsOn = true,
}

local KEYBINDS = {
    Speed = Enum.KeyCode.V,
    AirStrafe = Enum.KeyCode.B,
    Fly = Enum.KeyCode.F,
    AutoJump = Enum.KeyCode.J,
    Bounce = Enum.KeyCode.G,
    Crouch = Enum.KeyCode.C,
    EdgeTrimp = Enum.KeyCode.T,
    LagFreeze = Enum.KeyCode.X,
    ESP = Enum.KeyCode.H,
    Spin = Enum.KeyCode.Y,
    Fling = Enum.KeyCode.U,
    Farm = Enum.KeyCode.K,
    EmoteMacro = Enum.KeyCode.E,
}

local KEYBIND_ORDER = {
    "Speed", "AirStrafe", "Fly", "AutoJump", "Bounce", "Crouch",
    "EdgeTrimp", "LagFreeze", "ESP", "Spin", "Fling", "Farm", "EmoteMacro",
}

local KEYBIND_LABELS = {
    Speed = "Speed",
    AirStrafe = "Air Strafe",
    Fly = "Fly",
    AutoJump = "Auto Jump",
    Bounce = "Bounce",
    Crouch = "Auto Crouch",
    EdgeTrimp = "Edge Trimp",
    LagFreeze = "Lag Freeze",
    ESP = "ESP",
    Spin = "Spin",
    Fling = "Fling",
    Farm = "Farm",
    EmoteMacro = "Emote Macro",
}

local BindCapture = { active = nil } -- feature name waiting for key

local function isMobile()
    local ok, touch = pcall(function() return UIS.TouchEnabled end)
    local ok2, kb = pcall(function() return UIS.KeyboardEnabled end)
    if ok and touch and ok2 and not kb then return true end
    if ok and touch and not (ok2 and kb) then return true end
    return false
end

local function keycodeFromName(name)
    name = tostring(name or ""):gsub("%s+", "")
    if name == "" or name:lower() == "none" then return nil end
    local ok, k = pcall(function() return Enum.KeyCode[name] end)
    if ok and k then return k end
    return nil
end

local function keycodeToName(k)
    if typeof(k) == "EnumItem" then return k.Name end
    return tostring(k or "None")
end


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

local function notify(title, content, dur)
    pcall(function()
        if WindUI then
            WindUI:Notify({ Title = title, Content = content, Duration = dur or 3 })
        end
        if type(_G.MT_ActivateFx) == "function" then
            _G.MT_ActivateFx(Color3.fromRGB(0, 229, 255))
        end
    end)
end

local function applyVip()
    pcall(function()
        lp:SetAttribute("VipStrafe", STATE.vipStrafeOn and STATE.vipStrafeMult or nil)
        lp:SetAttribute("VipSpeed", STATE.vipSpeedOn and STATE.vipSpeed or nil)
        lp:SetAttribute("VipJump", STATE.vipJumpOn and STATE.vipJump or nil)
    end)
end

local edgeLastTrimp = -999
local edgeRayParams = RaycastParams.new()
edgeRayParams.FilterType = Enum.RaycastFilterType.Exclude
edgeRayParams.FilterDescendantsInstances = lp.Character and { lp.Character } or {}
local edgeDirs = { Vector3.zero, Vector3.zero, Vector3.zero }
local function edgeNorm(v)
    local m = v.Magnitude
    return m > 0.0001 and v / m or Vector3.zero
end
local lastAutoJump = 0

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
            warn("[Memetrash] MoveStats not found; using BaseStats only. Use 'Copy diagnostic'.")
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

local NEON_CYAN = Color3.fromRGB(0, 229, 255)
local NEON_BLUE = Color3.fromRGB(64, 120, 255)
local NEON_PURPLE = Color3.fromRGB(180, 70, 255)
local NEON_MAGENTA = Color3.fromRGB(220, 40, 255)
local NEON_BG = Color3.fromRGB(6, 4, 14)

local BTN_COLORS = {
    LagSwitch = NEON_MAGENTA,
    AutoJump = NEON_CYAN,
    Bounce = NEON_BLUE,
    AutoCrouch = NEON_PURPLE,
}

local function makeFloatBtn(cfg)
    local TweenService = game:GetService("TweenService")
    local LOCK_HOLD = cfg.LockHold or 2.0
    local VIS_HOLD = cfg.VisHold or 3.0
    local DRAG_THRESHOLD = 14
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
    button.BackgroundColor3 = NEON_BG
    button.BackgroundTransparency = 0.55
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
    stroke.Thickness = 2.2
    stroke.Color = baseColor
    stroke.Transparency = 0.2
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
        button.BackgroundTransparency = visible and (active and 0.08 or 0.45) or 1
        stroke.Transparency = visible and (active and 0.15 or 0.35) or 1

        local statusText
        if statusOverride ~= nil and statusOverride ~= "" then
            statusText = tostring(statusOverride)
        else
            statusText = active and (cfg.StatusOn or "ON") or (cfg.StatusOff or "OFF")
        end

        if active then
            button.BackgroundColor3 = baseColor
            stroke.Color = baseColor
            status.TextColor3 = lighten(baseColor, 0.35)
        else
            button.BackgroundColor3 = baseColor:Lerp(NEON_BG, 0.72)
            stroke.Color = baseColor
            status.TextColor3 = baseColor:Lerp(Color3.new(1,1,1), 0.35)
        end
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
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
    local activeInput = nil

    local clickGuard = false
    local function doClick()
        if suppressClick or not visible then return end
        if clickGuard then return end
        clickGuard = true
        task.defer(function() clickGuard = false end)
        if cfg.OnClick then
            pcall(cfg.OnClick)
        end
    end

    button.Activated:Connect(function()
        doClick()
    end)

    button.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        token = token + 1
        local myToken = token
        moved = false
        suppressClick = false
        holdLock, holdVis = false, false
        activeInput = input
        dragStart = input.Position
        startPos = button.Position
        dragging = not locked
        tweenScale(sizePercent / 100 * 0.92)

        task.delay(LOCK_HOLD, function()
            if myToken ~= token or moved then return end
            holdLock = true
            suppressClick = true
            notify(cfg.Label or cfg.Name,
                "Release to " .. (locked and "unlock" or "lock")
                    .. " · keep holding to " .. VIS_HOLD .. "s to " .. (visible and "hide" or "show"), 2)
        end)

        task.delay(VIS_HOLD, function()
            if myToken ~= token or moved then return end
            holdVis = true
            suppressClick = true
            notify(cfg.Label or cfg.Name, "Release to " .. (visible and "hide" or "show"), 2)
        end)
    end)

    button.InputEnded:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        local wasLock, wasVis = holdLock, holdVis
        token = token + 1
        dragging = false
        activeInput = nil
        tweenScale(sizePercent / 100)
        if wasVis then
            visible = not visible
            applyLook()
            notify(cfg.Label or cfg.Name, visible and "Button visible" or "Button hidden (hold again to show)", 2)
        elseif wasLock then
            locked = not locked
            applyLook()
            notify(cfg.Label or cfg.Name, locked and "Button locked" or "Button unlocked", 2)
        end
    end)

    button.InputChanged:Connect(function(input)
        if not dragging or locked then return end
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
        if moved then
            button.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + dx,
                startPos.Y.Scale, startPos.Y.Offset + dy
            )
        end
    end)

    bind(UIS.InputChanged:Connect(function(input)
        if not dragging or locked then return end
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
        if moved then
            button.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + dx,
                startPos.Y.Scale, startPos.Y.Offset + dy
            )
        end
    end))

    local self = {}
    function self:SetEnabled(v)
        gui.Enabled = v and true or false
    end
    function self:SetActive(v)
        local was = active
        active = v and true or false
        applyLook()
        if active and not was and visible then
            pcall(function()
                local TS = game:GetService("TweenService")
                local s = button:FindFirstChildOfClass("UIScale")
                if not s then
                    s = Instance.new("UIScale")
                    s.Parent = button
                end
                s.Scale = 1.14
                TS:Create(s, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
                local ot = stroke.Transparency
                stroke.Transparency = 0
                TS:Create(stroke, TweenInfo.new(0.35), { Transparency = ot }):Play()
            end)
        end
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

_G.MT_ActivateFx = function(color)
    if STATE and STATE.activateFx == false then return end
    pcall(function()
        local TS = game:GetService("TweenService")
        local pg = floatParent
        local g = pg:FindFirstChild("MT_ActivateFx")
        if g then g:Destroy() end
        g = Instance.new("ScreenGui")
        g.Name = "MT_ActivateFx"
        g.IgnoreGuiInset = true
        g.DisplayOrder = 999
        g.ResetOnSpawn = false
        g.Parent = pg
        local f = Instance.new("Frame")
        f.Size = UDim2.fromScale(1, 1)
        f.BackgroundColor3 = color or NEON_CYAN
        f.BackgroundTransparency = 0.82
        f.BorderSizePixel = 0
        f.Parent = g
        TS:Create(f, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1
        }):Play()
        task.delay(0.4, function() pcall(function() g:Destroy() end) end)
    end)
end
local Lag = {
    enabled = false,
    flagOn = true,
    flagValue = 1000,
    cooldown = false,
    cooldownSec = 1,
    duration = 0.35,
    btn = nil,
}

local function lagApplyFlag()
    local value = 1
    if Lag.enabled and Lag.flagOn then
        value = Lag.flagValue
    end
    pcall(function()
        if setfflag then
            setfflag("MaxMissedWorldStepsRemembered", tostring(value))
        end
    end)
end

pcall(function()
    if setfflag then setfflag("MaxMissedWorldStepsRemembered", "1") end
end)

task.spawn(function()
    while true do
        task.wait(5)
        if Lag.enabled and Lag.flagOn then
            local want = tostring(Lag.flagValue)
            pcall(function()
                if (not getfflag) or tostring(getfflag("MaxMissedWorldStepsRemembered")) ~= want then
                    if setfflag then setfflag("MaxMissedWorldStepsRemembered", want) end
                end
            end)
        end
    end
end)

function Lag.fire()
    if Lag.cooldown then return end
    if not Lag.enabled then
        Lag.enabled = true
        lagApplyFlag()
    end
    Lag.cooldown = true
    if Lag.btn then
        Lag.btn:SetActive(true)
        Lag.btn:SetStatusText("Freezing...")
    end

    local dur = math.clamp(tonumber(Lag.duration) or 0.35, 0.1, 2)
    local t = os.clock()
    while os.clock() - t < dur do
        local acc = 0
        for i = 1, 400000 do
            acc = acc + i
        end
    end

    task.spawn(function()
        local sec = math.max(1, math.floor(tonumber(Lag.cooldownSec) or 1))
        for i = sec, 1, -1 do
            if Lag.btn then Lag.btn:SetStatusText("Cooldown: " .. i) end
            task.wait(1)
        end
        if Lag.btn then
            Lag.btn:SetStatusText("Ready")
            Lag.btn:SetActive(false)
        end
        Lag.cooldown = false
    end)
end

function Lag.setEnabled(v)
    Lag.enabled = v and true or false
    lagApplyFlag()
end

function Lag.setFlagValue(v)
    Lag.flagValue = math.clamp(tonumber(v) or 1000, 0, 1000)
    if Lag.enabled then lagApplyFlag() end
end

function Lag.apply(_limitNet)
    Lag.setEnabled(true)
end
function Lag.release()
    Lag.setEnabled(false)
end
function Lag.hold(v)
    if v then
        Lag.setEnabled(true)
        if Lag.btn then Lag.btn:SetActive(true) Lag.btn:SetStatusText("HOLD") end
    else
        Lag.setEnabled(false)
        if Lag.btn then Lag.btn:SetStatusText("Ready") Lag.btn:SetActive(false) end
    end
end

Lag.btn = makeFloatBtn({
    Name = "LagSwitch",
    Label = "Freeze Now",
    StatusOff = "Ready",
    StatusOn = "Freezing...",
    Position = UDim2.new(0.8, 0, 0.75, 0),
    Color = BTN_COLORS.LagSwitch,
    OnClick = function() Lag.fire() end,
})
Lag.btn:SetActive(false)
Lag.btn:SetStatusText("Ready")

local Farm = { plate = nil, saved = nil, token = 0, afk = nil, lastCheck = 0 }
local FARM_IMAGE_URL = "https://i.ibb.co/6J8BJQfg/3-F79468-B-CF48-4-DC5-B275-C39-CB79-DDE8-C.png"
local FARM_FALLBACK_IMAGE = "rbxassetid://120731213216995"

local function farmImage()
    if Farm.imageAsset then return Farm.imageAsset end
    local ok, asset = pcall(function()
        assert(type(writefile) == "function" and type(getcustomasset) == "function", "no getcustomasset")
        local data = game:HttpGet(FARM_IMAGE_URL)
        assert(type(data) == "string" and #data > 1000, "empty download")
        writefile("hyperion_farm_plate.png", data)
        return getcustomasset("hyperion_farm_plate.png")
    end)
    Farm.imageAsset = (ok and asset) or FARM_FALLBACK_IMAGE
    return Farm.imageAsset
end

local function farmMapTop()
    local top, n = -math.huge, 0
    local char = lp.Character
    for _, d in ipairs(Workspace:GetDescendants()) do
        n = n + 1
        if n % 2500 == 0 then task.wait() end
        if d:IsA("BasePart") and not (char and d:IsDescendantOf(char)) and d.Size.Magnitude < 1500 then
            local y = d.Position.Y + d.Size.Y / 2
            if y > top and y < 20000 then top = y end
        end
    end
    return top == -math.huge and 100 or top
end

local function farmTarget()
    return Farm.plate and (Farm.plate.Position + Vector3.new(0, Farm.plate.Size.Y / 2 + 3.5, 0)) or nil
end

local function farmTeleport()
    local root = hrp()
    local pos = farmTarget()
    if not root or not pos then return end
    root.CFrame = CFrame.new(pos)
    root.AssemblyLinearVelocity = Vector3.zero
end

function Farm.start()
    Farm.token = Farm.token + 1
    local my = Farm.token
    local root = hrp()
    if not root then
        notify("Auto Farm", "No character right now", 3)
        return
    end
    Farm.saved = root.CFrame
    notify("Auto Farm", "Looking for the top of the map...", 2)
    local top = farmMapTop()
    if my ~= Farm.token or not STATE.farmOn then return end

    local plate = Instance.new("Part")
    plate.Name = "MT_FarmPlate"
    plate.Anchored = true
    plate.CanCollide = true
    plate.Size = Vector3.new(36, 2, 36)
    plate.Material = Enum.Material.SmoothPlastic
    plate.Color = Color3.fromRGB(12, 14, 24)
    plate.Position = Vector3.new(Farm.saved.Position.X, top + STATE.farmExtra, Farm.saved.Position.Z)
    local decal = Instance.new("Decal")
    decal.Face = Enum.NormalId.Top
    decal.Texture = farmImage()
    decal.Parent = plate
    plate.Parent = Workspace
    Farm.plate = plate

    farmTeleport()
    if not Farm.afk then
        local VU = game:GetService("VirtualUser")
        Farm.afk = lp.Idled:Connect(function()
            pcall(function()
                VU:CaptureController()
                VU:ClickButton2(Vector2.new())
            end)
        end)
    end
    notify("Auto Farm", "You are on the platform", 3)
end

function Farm.stop()
    Farm.token = Farm.token + 1
    if Farm.afk then Farm.afk:Disconnect() Farm.afk = nil end
    if Farm.plate then Farm.plate:Destroy() Farm.plate = nil end
    local root = hrp()
    if root and Farm.saved then
        root.CFrame = Farm.saved
        root.AssemblyLinearVelocity = Vector3.zero
    end
    Farm.saved = nil
end

function Farm.step(root)
    if not Farm.plate then return end
    local now = os.clock()
    if now - Farm.lastCheck < 0.3 then return end
    Farm.lastCheck = now
    local target = farmTarget()
    if target and (root.Position - target).Magnitude > 14 then
        farmTeleport()
    end
end

local Anti = { hooked = false, hookLive = false, keys = {}, seen = {} }

function Anti.setKeywords(text)
    STATE.antiBlockKeyword = tostring(text or "")
    Anti.keys = {}
    for word in STATE.antiBlockKeyword:gmatch("[^,]+") do
        word = word:lower():match("^%s*(.-)%s*$")
        if word ~= "" then Anti.keys[#Anti.keys + 1] = word end
    end
end
Anti.setKeywords(STATE.antiBlockKeyword)

function Anti.installHook()
    if Anti.hooked then
        Anti.hookLive = true
        return true
    end
    if type(hookmetamethod) ~= "function" or type(getnamecallmethod) ~= "function" then return false end
    local old
    local function hook(self, ...)
        if Anti.hookLive and STATE.antiBlock then
            local m = getnamecallmethod()
            if (m == "FireServer" or m == "InvokeServer") and typeof(self) == "Instance" then
                local n = self.Name:lower()
                for _, k in ipairs(Anti.keys) do
                    if n:find(k, 1, true) then
                        if not Anti.seen[self] then
                            Anti.seen[self] = true
                            task.spawn(function() print("[Memetrash] Anti Hitbox blocked:", self:GetFullName()) end)
                        end
                        return
                    end
                end
            end
        end
        return old(self, ...)
    end
    local ok = pcall(function()
        old = hookmetamethod(game, "__namecall", (type(newcclosure) == "function") and newcclosure(hook) or hook)
    end)
    Anti.hooked = ok
    Anti.hookLive = ok
    return ok
end

function Anti.set(v)
    STATE.antiBlock = v and true or false
    if STATE.antiBlock then
        if Anti.installHook() then
            notify("Anti Hitbox", "Enabled: blocking remotes containing: " .. table.concat(Anti.keys, ", "), 3)
        else
            notify("Anti Hitbox", "Your executor does not support hookmetamethod", 4)
        end
    else
        notify("Anti Hitbox", "Disabled", 2)
    end
end

local Crouch = { btn = nil, conns = nil, stamp = 0, acc = 0, keyDown = false, btnObj = nil }

local function crouchFindBtn()
    local pg = lp:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local ok, btn = pcall(function()
        local g = pg:FindFirstChild("Game")
        local hud = g and g:FindFirstChild("HUD")
        local mob = hud and hud:FindFirstChild("Mobile")
        local right = mob and mob:FindFirstChild("Right")
        local inner = right and right:FindFirstChild("Mobile")
        return inner and inner:FindFirstChild("CrouchButton")
    end)
    if ok and btn then return btn end
    for _, d in ipairs(pg:GetDescendants()) do
        if d:IsA("GuiButton") and d.Name:lower():find("crouch", 1, true) then return d end
    end
    return nil
end

local function crouchRefresh(force)
    local now = os.clock()
    if not force and Crouch.btn and Crouch.btn.Parent and (now - Crouch.stamp) < 5 then return end
    if not force and not Crouch.btn and (now - Crouch.stamp) < 2 then return end
    Crouch.stamp = now
    Crouch.btn = crouchFindBtn()
    Crouch.conns = nil
    if Crouch.btn and type(getconnections) == "function" then
        pcall(function()
            local list = {}
            for _, sig in ipairs({ Crouch.btn.MouseButton1Click, Crouch.btn.Activated }) do
                for _, c in ipairs(getconnections(sig)) do list[#list + 1] = c end
            end
            Crouch.conns = list
        end)
    end
end

local function crouchFire()
    crouchRefresh(false)
    local fired = false
    if Crouch.conns and #Crouch.conns > 0 then
        for _, c in ipairs(Crouch.conns) do
            if pcall(function() c:Fire() end) then fired = true end
        end
    end
    if not fired then
        Crouch.keyDown = not Crouch.keyDown
        fired = pcall(function()
            lp.PlayerScripts.Events.temporary_events.UseKeybind:Fire({ Key = "Crouch", Down = Crouch.keyDown })
        end)
    end
    if not fired then
        pcall(function()
            Crouch.keyDown = not Crouch.keyDown
            game:GetService("VirtualInputManager"):SendKeyEvent(Crouch.keyDown, Enum.KeyCode.C, false, game)
        end)
    end
end

function Crouch.step(dt)
    if not STATE.crouchOn then return end
    Crouch.acc = Crouch.acc + dt
    local s = math.clamp(tonumber(STATE.crouchSpeed) or 7, 1, 10)
    local interval = math.clamp(0.13 - s * 0.011, 0.02, 0.15)
    if Crouch.acc >= interval then
        Crouch.acc = 0
        pcall(crouchFire)
    end
end

function Crouch.set(v)
    STATE.crouchOn = v and true or false
    Crouch.acc = 0
    if STATE.crouchOn then crouchRefresh(true) end
    if Crouch.btnObj then
        Crouch.btnObj:SetActive(STATE.crouchOn)
        Crouch.btnObj:SetStatusText(STATE.crouchOn and "ON" or "OFF")
    end
end

Crouch.btnObj = makeFloatBtn({
    Name = "AutoCrouch", Label = "Auto Crouch",
    StatusOff = "OFF", StatusOn = "ON",
    Position = UDim2.new(0.35, 0, 0.75, 0),
    Color = BTN_COLORS.AutoCrouch,
    OnClick = function() Crouch.set(not STATE.crouchOn) end,
})
Crouch.btnObj:SetActive(false)
Crouch.btnObj:SetStatusText("OFF")

local Macro = {
    slot = 1, active = false, busy = false, btn = nil,
    ids = nil, byName = nil, localTrack = nil,
    normalWS = 16, normalAR = true, lastStep = 0, lastLabel = "",
    _playAt = 0, _guiWasEnabled = nil,
}

local function macroValues()
    local char = lp.Character
    return char and char:FindFirstChild("Values")
end

local function macroSetEmoting(on, speed)
    local vals = macroValues()
    if not vals then return false end
    local em = vals:FindFirstChild("Emoting")
    if em then pcall(function() em.Value = on and true or false end) end
    local es = vals:FindFirstChild("EmoteSpeed")
    if es then
        pcall(function()
            if on then
                es.Value = (tonumber(speed) and tonumber(speed) > 0) and tonumber(speed) or 30
            else
                es.Value = 0
            end
        end)
    end
    return em ~= nil
end

local function macroSlotName(slot)
    local f = lp:FindFirstChild("EquippedEmotes")
    local v = f and f:FindFirstChild("Sector" .. tostring(slot))
    if not v then return "" end
    return tostring(v.Value or ""):match("^%s*(.-)%s*$") or ""
end

local function macroEnsureEmotesGui()
    local pg = lp:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local gui = pg:FindFirstChild("EmotesGui")
    if not gui then
        local sg = game:GetService("StarterGui"):FindFirstChild("EmotesGui")
        if sg then
            pcall(function()
                gui = sg:Clone()
                gui.Parent = pg
            end)
            gui = pg:FindFirstChild("EmotesGui")
        end
    end
    if not gui then
        for _, g in ipairs(pg:GetChildren()) do
            if g:IsA("ScreenGui") and (g.Name:lower():find("emote") or g:FindFirstChild("MainGui", true)) then
                local hasSector = false
                for _, d in ipairs(g:GetDescendants()) do
                    if d.Name:match("^Sector%d+$") then hasSector = true break end
                end
                if hasSector then gui = g break end
            end
        end
    end
    return gui
end

local function macroSectorButton(slot)
    local gui = macroEnsureEmotesGui()
    if not gui then return nil, nil end
    local want = "Sector" .. tostring(slot)
    local main = gui:FindFirstChild("MainGui") or gui
    local best = nil
    for _, d in ipairs(main:GetDescendants()) do
        if d.Name == want then
            if d:IsA("GuiButton") or d:IsA("TextButton") or d:IsA("ImageButton") then
                return d, gui
            end
            for _, c in ipairs(d:GetDescendants()) do
                if c:IsA("GuiButton") or c:IsA("TextButton") or c:IsA("ImageButton") then
                    return c, gui
                end
            end
            best = d
        end
    end
    if best then
        for _, c in ipairs(best:GetDescendants()) do
            if c:IsA("GuiButton") or c:IsA("TextButton") or c:IsA("ImageButton") then
                return c, gui
            end
        end
    end
    return nil, gui
end

local function macroClickButton(btn)
    if not btn then return false end
    local fired = false

    if type(getconnections) == "function" then
        for _, sigName in ipairs({ "Activated", "MouseButton1Click", "MouseButton1Down", "MouseButton1Up" }) do
            local sig = btn[sigName]
            if typeof(sig) == "RBXScriptSignal" then
                local ok, list = pcall(getconnections, sig)
                if ok and type(list) == "table" then
                    for _, c in ipairs(list) do
                        pcall(function()
                            if c.Enabled == false then c.Enabled = true end
                        end)
                        pcall(function()
                            if c.Fire then
                                c:Fire()
                            elseif type(c.Function) == "function" then
                                c.Function()
                            end
                        end)
                        fired = true
                    end
                end
            end
        end
    end

    pcall(function() if firesignal then firesignal(btn.Activated) end end)
    pcall(function() if firesignal then firesignal(btn.MouseButton1Click) end end)

    pcall(function()
        if typeof(btn.Activate) == "function" then btn:Activate() end
    end)

    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        local ap, asz = btn.AbsolutePosition, btn.AbsoluteSize
        if asz.X < 1 or asz.Y < 1 then return end
        local x = ap.X + asz.X / 2
        local y = ap.Y + asz.Y / 2
        vim:SendMouseButtonEvent(x, y, 0, true, game, 1)
        task.wait()
        vim:SendMouseButtonEvent(x, y, 0, false, game, 1)
        fired = true
    end)

    return fired
end

local function macroOpenGuiForClick(gui)
    if not gui then return end
    Macro._guiWasEnabled = gui.Enabled
    pcall(function()
        gui.Enabled = true
        gui.DisplayOrder = math.max(gui.DisplayOrder, 50)
    end)
    local main = gui:FindFirstChild("MainGui")
    if main and main:IsA("GuiObject") then
        pcall(function() main.Visible = true end)
    end
end

local function macroRestoreGui(gui)
    if not gui then return end
    if Macro._guiWasEnabled ~= nil then
        pcall(function() gui.Enabled = Macro._guiWasEnabled end)
        Macro._guiWasEnabled = nil
    end
end

local function macroLoadEmotes()
    Macro.ids = Macro.ids or {}
    Macro.byName = Macro.byName or {}
    local roots = {}
    local items = RS:FindFirstChild("Items")
    if items and items:FindFirstChild("Emotes") then roots[#roots+1] = items.Emotes end
    local inv = lp:FindFirstChild("Inventory")
    if inv and inv:FindFirstChild("Emotes") then roots[#roots+1] = inv.Emotes end
    for _, folder in ipairs(roots) do
        for _, a in ipairs(folder:GetDescendants()) do
            if a:IsA("Animation") then
                Macro.ids[a.AnimationId] = a
                Macro.byName[a.Name:lower()] = a
            end
        end
    end
end

local function macroFindAnim(name)
    if not name or name == "" then return nil end
    macroLoadEmotes()
    local key = name:lower()
    if Macro.byName[key] then return Macro.byName[key] end
    for n, a in pairs(Macro.byName) do
        if n:find(key, 1, true) then return a end
    end
    return nil
end

local function macroPlayAnim(name)
    local anim = macroFindAnim(name)
    local h = hum()
    if not (anim and h) then return false end
    local animator = h:FindFirstChildOfClass("Animator") or Instance.new("Animator", h)
    if Macro.localTrack then pcall(function() Macro.localTrack:Stop(0.05) end) end
    local ok, tr = pcall(function() return animator:LoadAnimation(anim) end)
    if not ok or not tr then return false end
    tr.Priority = Enum.AnimationPriority.Action4
    tr.Looped = true
    tr:Play(0.1)
    Macro.localTrack = tr
    return true
end

local function macroStopAnim()
    if Macro.localTrack then
        pcall(function() Macro.localTrack:Stop(0.08) end)
        Macro.localTrack = nil
    end
    local h = hum()
    local animator = h and h:FindFirstChildOfClass("Animator")
    if animator then
        for _, tr in ipairs(animator:GetPlayingAnimationTracks()) do
            local p = tr.Priority
            if p == Enum.AnimationPriority.Action
                    or p == Enum.AnimationPriority.Action2
                    or p == Enum.AnimationPriority.Action3
                    or p == Enum.AnimationPriority.Action4 then
                pcall(function() tr:Stop(0.08) end)
            end
        end
    end
end

local function macroTryGcPlay(name, slot)
    if type(getgc) ~= "function" then return false end
    local hit = false
    pcall(function()
        local pg = lp.PlayerGui:FindFirstChild("EmotesGui")
        local ls = pg and pg:FindFirstChild("MainGui") and pg.MainGui:FindFirstChild("EmotesGameLocal")
        if not ls then
            ls = pg and pg:FindFirstChild("EmotesGameLocal", true)
        end
        if ls and ls:IsA("LocalScript") and type(getsenv) == "function" then
            local env = getsenv(ls)
            if type(env) == "table" then
                for _, key in ipairs({ "PlayEmote", "playEmote", "EquipEmote", "SelectEmote", "OnEmote", "Activate" }) do
                    local fn = env[key]
                    if type(fn) == "function" then
                        pcall(fn, slot)
                        pcall(fn, name)
                        pcall(fn, slot, name)
                        hit = true
                    end
                end
            end
        end
    end)
    return hit
end

function Macro.label()
    local name = macroSlotName(Macro.slot)
    if name == "" then name = "empty" end
    return (Macro.active and "Playing · " or ("Slot " .. Macro.slot .. " · ")) .. name
end

function Macro.refresh()
    if not Macro.btn then return end
    local label = Macro.label()
    if label ~= Macro.lastLabel then
        Macro.lastLabel = label
        Macro.btn:SetStatusText(label)
    end
    Macro.btn:SetActive(Macro.active)
end

function Macro.play()
    Macro._playAt = os.clock()
    local name = macroSlotName(Macro.slot)
    if name == "" then
        return
    end

    local btn, gui = macroSectorButton(Macro.slot)
    local clicked = false
    if gui then
        macroOpenGuiForClick(gui)
        task.wait(0.05)         btn = btn or select(1, macroSectorButton(Macro.slot))
        if btn then
            clicked = macroClickButton(btn)
        end
        task.defer(function()
            task.wait(0.15)
            macroRestoreGui(gui)
        end)
    end

    local gcOk = macroTryGcPlay(name, Macro.slot)

    macroSetEmoting(true, 30)

    task.spawn(function()
        task.wait(0.25)
        if not Macro.active then return end
        local h = hum()
        local animator = h and h:FindFirstChildOfClass("Animator")
        local hasAction = false
        if animator then
            for _, tr in ipairs(animator:GetPlayingAnimationTracks()) do
                local p = tr.Priority
                if p == Enum.AnimationPriority.Action4 or p == Enum.AnimationPriority.Action3
                        or p == Enum.AnimationPriority.Action then
                    hasAction = true
                    break
                end
            end
        end
        if not hasAction then
            macroPlayAnim(name)
        end
    end)

    local h = hum()
    if h then
        Macro.normalAR = h.AutoRotate
        h.AutoRotate = false
    end

    Macro.active = true
    Macro.refresh()
end

function Macro.stop()
    local name = macroSlotName(Macro.slot)

    local btn, gui = macroSectorButton(Macro.slot)
    if gui then
        macroOpenGuiForClick(gui)
        task.wait(0.03)
        btn = btn or select(1, macroSectorButton(Macro.slot))
        if btn then macroClickButton(btn) end
        task.defer(function()
            task.wait(0.1)
            macroRestoreGui(gui)
        end)
    end

    macroSetEmoting(false, 0)
    macroStopAnim()

    local h = hum()
    if h then
        h.AutoRotate = Macro.normalAR ~= false
        if h.WalkSpeed <= 6 then h.WalkSpeed = Macro.normalWS or 16 end
        pcall(function() h:ChangeState(Enum.HumanoidStateType.Running) end)
    end
    Macro.active = false
    Macro.refresh()
end

function Macro.toggle()
    if Macro.busy then return end
    Macro.busy = true
    local ok, err = pcall(function()
        if Macro.active then Macro.stop() else Macro.play() end
    end)
    if not ok then
        warn("[Memetrash] Emote Macro: " .. tostring(err))
    end
    Macro.busy = false
    Macro.refresh()
end

function Macro.setSlot(n)
    Macro.slot = math.clamp(tonumber(n) or 1, 1, 10)
    Macro.refresh()
end

function Macro.step(dt)
    local now = os.clock()
    if now - Macro.lastStep < 0.3 then return end
    Macro.lastStep = now
    if Macro.active and not Macro.busy then
        local vals = macroValues()
        local em = vals and vals:FindFirstChild("Emoting")
        if em and em.Value ~= true then
            pcall(function() em.Value = true end)
        end
    end
    if not Macro.busy and not Macro.active then
        local h = hum()
        if h then
            if h.WalkSpeed > 8 then Macro.normalWS = h.WalkSpeed end
            Macro.normalAR = h.AutoRotate
        end
    end
    Macro.refresh()
end

function Macro.reset()
    Macro.active, Macro.localTrack = false, nil
    pcall(function() macroSetEmoting(false, 0) end)
end

-- SCRIPT 1: fires the mobile emote wheel button — used when emote IS active
local function fireEmoteBtn()
    local pg = lp:WaitForChild("PlayerGui")
    local mobileFolder = pg:FindFirstChild("Mobile")
    local emoteBtn = mobileFolder and mobileFolder:FindFirstChild("Emote")
    if not emoteBtn then
        warn("[Memetrash] Could not find PlayerGui.Mobile.Emote")
        return
    end
    local fired = false
    if typeof(getconnections) == "function" and emoteBtn.Activated then
        for _, conn in ipairs(getconnections(emoteBtn.Activated)) do
            if conn.Function then
                local ok, err = pcall(conn.Function)
                if ok then fired = true
                else warn("[Memetrash] Connection error:", err) end
            end
        end
    elseif typeof(firesignal) == "function" and emoteBtn.Activated then
        local ok, err = pcall(firesignal, emoteBtn.Activated)
        if ok then fired = true
        else warn("[Memetrash] firesignal error:", err) end
    end
    if not fired and emoteBtn:IsA("GuiButton") then
        pcall(function() emoteBtn:Activate() fired = true end)
    end
    if not fired then
        warn("[Memetrash] Could not trigger Mobile.Emote")
    end
end

-- SCRIPT 2: finds and clicks the sector button — used when emote is NOT active
local function fireSectorEmote(sectorIndex)
    local pg = lp:WaitForChild("PlayerGui")
    local equipped = lp:FindFirstChild("EquippedEmotes")
    local invFolder = lp:FindFirstChild("Inventory")
    local emotesInv = invFolder and invFolder:FindFirstChild("Emotes")
    if equipped then
        local slot = equipped:FindFirstChild("Sector" .. sectorIndex)
        print("[Memetrash] Equipped slot value:", slot and slot.Value or "none")
        if slot and slot.Value ~= "" and emotesInv then
            print("[Memetrash] In inventory:", emotesInv:FindFirstChild(slot.Value) ~= nil)
        end
    end
    local targetSector
    for _, desc in ipairs(pg:GetDescendants()) do
        if desc.Name == "Sector" .. sectorIndex
                and desc.Parent
                and desc.Parent:FindFirstChild("EmoteName") then
            targetSector = desc
            break
        end
    end
    if not targetSector then
        warn("[Memetrash] Could not find Sector" .. sectorIndex .. " inside emote menu")
        return
    end
    local menuFrame = targetSector.Parent
    local btn = targetSector:FindFirstChild("button")
    if not (btn and btn:IsA("GuiButton")) then
        warn("[Memetrash] Missing GuiButton child named 'button' on Sector" .. sectorIndex)
        return
    end
    local wasVisible = menuFrame.Visible
    menuFrame.Visible = true
    if typeof(getconnections) == "function" then
        for _, conn in ipairs(getconnections(btn.Activated)) do
            if conn.Function then pcall(conn.Function) end
        end
    elseif typeof(firesignal) == "function" then
        pcall(firesignal, btn.Activated)
    else
        warn("[Memetrash] Neither getconnections nor firesignal is available")
    end
    task.wait(0.1)
    if not wasVisible and menuFrame.Visible then
        menuFrame.Visible = false
    end
end

Macro.btn = makeFloatBtn({
    Name = "EmoteMacro", Label = "Emote Macro",
    StatusOff = "Slot 1", StatusOn = "Playing",
    Position = UDim2.new(0.65, 0, 0.55, 0),
    Color = NEON_MAGENTA,
    LockHold = 3,
    VisHold = 4,
    OnClick = function()
        if Macro.active then
            pcall(fireEmoteBtn)
        else
            pcall(fireSectorEmote, Macro.slot)
            Macro.active = true
            Macro.refresh()
        end
    end,
})
Macro.btn:SetActive(false)
Macro.refresh()

local ajBtn = makeFloatBtn({
    Name = "AutoJump", Label = "Auto Jump",
    StatusOff = "OFF", StatusOn = "ON",
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
    Name = "Bounce", Label = "Auto Bounce",
    StatusOff = "OFF", StatusOn = "ON",
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

local function stepSpeedAir(h, root, dt)

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
end

local function stepAutoJump(h, root, dt)

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
end

local function jumpPush(name, active, dir, speed, h, root)
    local bv = root:FindFirstChild(name)
    if active and h.FloorMaterial == Enum.Material.Air then
        if not bv then
            bv = Instance.new("BodyVelocity")
            bv.Name = name
            bv.MaxForce = Vector3.new(4e5, 0, 4e5)
            bv.P = 1250
            bv.Parent = root
        end
        bv.Velocity = dir * speed
    elseif bv then
        bv:Destroy()
    end
end

local function stepDirectionalJump(h, root, dt)
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local look = cam.CFrame.LookVector
    look = Vector3.new(look.X, 0, look.Z)
    look = look.Magnitude > 0.01 and look.Unit or Vector3.new(0, 0, -1)
    jumpPush("MT_FrontalJump", STATE.frontalOn, look, STATE.frontalSpeed, h, root)
    jumpPush("MT_BackJump", STATE.backOn and not STATE.frontalOn, -look, STATE.backSpeed, h, root)
end

local function stepEdgeTrimp(h, root, dt)

    if STATE.edgeTrimpOn then
        local now = os.clock()
        if now > edgeLastTrimp and h.Health > 0 then
            local vel = root.AssemblyLinearVelocity
            local flatVel = Vector3.new(vel.X, 0, vel.Z)
            local spd = flatVel.Magnitude
            if spd >= STATE.edgeMinSpeed and vel.Y < 15 then
                local unit = edgeNorm(flatVel)
                local pZ   = -unit.Z
                local pX   =  unit.X
                local org  = root.Position
                local dist = STATE.edgeCastDist
                local cw   = STATE.edgeConeWidth
                edgeDirs[1] = unit
                edgeDirs[2] = edgeNorm(Vector3.new(unit.X + pZ * cw, 0, unit.Z + pX * cw))
                edgeDirs[3] = edgeNorm(Vector3.new(unit.X - pZ * cw, 0, unit.Z - pX * cw))
                for i = 1, 3 do
                    local dir      = edgeDirs[i]
                    local ed = STATE.edgeEdgeDrop
                    local bodyHit  = workspace:Raycast(org,                          dir * dist, edgeRayParams)
                    local floorHit = workspace:Raycast(org + Vector3.new(0, -ed, 0), dir * dist, edgeRayParams)
                    if bodyHit      then continue end
                    if not floorHit then continue end
                    if not (math.abs(floorHit.Normal.Y) < 0.5) then continue end
                    local enf = edgeNorm(Vector3.new(floorHit.Normal.X, 0, floorHit.Normal.Z))
                    if enf.Magnitude <= 0 then continue end
                    if (-enf):Dot(unit) < STATE.edgeNormalDotMin then continue end
                    local abv = workspace:Raycast(
                        floorHit.Position + Vector3.new(0, ed, 0) + dir * 0.1,
                        Vector3.new(0, -(ed + 0.5), 0),
                        edgeRayParams
                    )
                    local ledgeY = abv and abv.Position.Y or floorHit.Position.Y
                    local baseY  = org.Y - 2.5
                    local topY   = org.Y
                    local n50    = math.clamp((ledgeY - baseY) / math.max(topY - baseY, 0.1), 0, 1) * 0.5 + 0.5
                    local launch = math.clamp(spd * 0.95, STATE.edgeLaunchFloor, STATE.edgeLaunchCap) * n50 * STATE.edgeLaunchMult
                    h:ChangeState(Enum.HumanoidStateType.Jumping)
                    root.AssemblyLinearVelocity = Vector3.new(vel.X, launch, vel.Z)
                    edgeLastTrimp = now + STATE.edgeCooldown
                    break
                end
            end
        end
    end
end

local function stepFly(h, root, dt)
    camera = Workspace.CurrentCamera or camera
    if STATE.flyOn then
        local move = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then move = move - camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then move = move - camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.C) then move = move - Vector3.yAxis end
        if move.Magnitude > 0 then
            root.AssemblyLinearVelocity = move.Unit * STATE.flySpeed
        else
            root.AssemblyLinearVelocity = Vector3.zero
        end
    end
end

local function stepWalls(h, root, dt)
    if STATE.wallsOn then
        for _, inst in ipairs(Workspace:GetPartBoundsInRadius(root.Position, 45)) do
            if inst:IsA("BasePart") and inst.Transparency >= 1 and inst.CanCollide then
                inst.CanCollide = false
            end
        end
    end
end

local function stepBounce(h, root, dt)
    if STATE.bounceOn then
        if h.FloorMaterial ~= Enum.Material.Air then
            root.AssemblyLinearVelocity = Vector3.new(
                root.AssemblyLinearVelocity.X,
                STATE.bouncePower,
                root.AssemblyLinearVelocity.Z
            )
        end
    end
end

local Skybox = {
    on = false,
    sky = nil,
    saved = nil,
    IMAGE = "https://i.ibb.co/xqHTvJkh/E4-D186-EF-C2-F8-48-BC-9-DD2-4-BDB0-B141-A26.png",
    asset = nil,
}

local function skyResolveAsset()
    if Skybox.asset then return Skybox.asset end
    local url = Skybox.IMAGE
    local fpath = "MT_Sky.png"
    pcall(function()
        if writefile and getcustomasset then
            local body = nil
            if syn and syn.request then
                local r = syn.request({ Url = url, Method = "GET" })
                body = r and (r.Body or r.body)
            elseif http and http.request then
                local r = http.request({ Url = url, Method = "GET" })
                body = r and (r.Body or r.body)
            elseif request then
                local r = request({ Url = url, Method = "GET" })
                body = r and (r.Body or r.body)
            elseif game.HttpGet then
                body = game:HttpGet(url)
            end
            if type(body) == "string" and #body > 500 then
                writefile(fpath, body)
            end
            if isfile and isfile(fpath) then
                Skybox.asset = getcustomasset(fpath)
            end
        end
    end)
    if not Skybox.asset then
        pcall(function()
            if getsynasset and isfile and isfile(fpath) then
                Skybox.asset = getsynasset(fpath)
            end
        end)
    end

    if not Skybox.asset then
        Skybox.asset = url
    end
    return Skybox.asset
end

function Skybox.apply(on)
    local ok, err = pcall(function()
        local Lighting = game:GetService("Lighting")
        if on then
            if not Skybox.saved then
                Skybox.saved = {}
                for _, ch in ipairs(Lighting:GetChildren()) do
                    if ch:IsA("Sky") then
                        Skybox.saved[#Skybox.saved + 1] = ch:Clone()
                        ch.Parent = nil
                    end
                end
            end
            if Skybox.sky and Skybox.sky.Parent then
                Skybox.sky:Destroy()
            end
            local img = skyResolveAsset()
            local sky = Instance.new("Sky")
            sky.Name = "MT_Sky"
            sky.SkyboxBk = img
            sky.SkyboxDn = img
            sky.SkyboxFt = img
            sky.SkyboxLf = img
            sky.SkyboxRt = img
            sky.SkyboxUp = img
            sky.Parent = Lighting
            Skybox.sky = sky
            Skybox.on = true
            STATE.vipSkyOn = true
        else
            if Skybox.sky then
                pcall(function() Skybox.sky:Destroy() end)
                Skybox.sky = nil
            end
            for _, ch in ipairs(Lighting:GetChildren()) do
                if ch:IsA("Sky") and ch.Name == "MT_Sky" then
                    pcall(function() ch:Destroy() end)
                end
            end
            if Skybox.saved then
                for _, cl in ipairs(Skybox.saved) do
                    pcall(function() cl.Parent = Lighting end)
                end
                Skybox.saved = nil
            end
            Skybox.on = false
            STATE.vipSkyOn = false
        end
    end)
    if not ok then
        warn("[Memetrash] Skybox: ", err)
    end
end

local Cheats = {
    espFolder = nil,
    spinConn = nil,
    flingConn = nil,
    nextbotConn = nil,
    voteConn = nil,
}

local function cheatsAccent()
    local a = STATE.uiAccent or "Cyan"
    if a == "Purple" then return NEON_PURPLE
    elseif a == "Magenta" then return NEON_MAGENTA
    elseif a == "Blue" then return NEON_BLUE
    end
    return NEON_CYAN
end

local Esp = { gui = nil, items = {}, loop = nil, added = nil, removing = nil }

local function espColor() return STATE.espColor or cheatsAccent() end

local function espEnsureGui()
    if Esp.gui and Esp.gui.Parent then return Esp.gui end
    local g = Instance.new("ScreenGui")
    g.Name = "MT_ESP"
    g.IgnoreGuiInset = true
    g.ResetOnSpawn = false
    g.DisplayOrder = 50
    g.Parent = floatParent
    Esp.gui = g
    return g
end

local function espDestroyItem(plr)
    local it = Esp.items[plr]
    if not it then return end
    Esp.items[plr] = nil
    pcall(function() it.bill:Destroy() end)
    pcall(function() it.hl:Destroy() end)
    pcall(function() it.line:Destroy() end)
end

local function espNewItem(plr)
    if plr == lp or Esp.items[plr] then return end
    local gui = espEnsureGui()

    local bill = Instance.new("BillboardGui")
    bill.Name = "MT_EspTag"
    bill.AlwaysOnTop = true
    bill.Size = UDim2.fromOffset(180, 40)
    bill.StudsOffset = Vector3.new(0, 3.4, 0)
    bill.MaxDistance = math.huge
    bill.Parent = gui

    local nameL = Instance.new("TextLabel")
    nameL.BackgroundTransparency = 1
    nameL.Size = UDim2.new(1, 0, 0.55, 0)
    nameL.Font = Enum.Font.GothamBold
    nameL.TextSize = 15
    nameL.TextStrokeTransparency = 0.25
    nameL.Text = plr.DisplayName ~= plr.Name and (plr.DisplayName .. " (@" .. plr.Name .. ")") or plr.Name
    nameL.Parent = bill

    local distL = Instance.new("TextLabel")
    distL.BackgroundTransparency = 1
    distL.Position = UDim2.new(0, 0, 0.55, 0)
    distL.Size = UDim2.new(1, 0, 0.45, 0)
    distL.Font = Enum.Font.Gotham
    distL.TextSize = 12
    distL.TextColor3 = Color3.fromRGB(230, 235, 255)
    distL.TextStrokeTransparency = 0.4
    distL.Parent = bill

    local hl = Instance.new("Highlight")
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.OutlineTransparency = 0
    hl.Parent = gui

    local line = Instance.new("Frame")
    line.Name = "Tracer"
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.BorderSizePixel = 0
    line.Visible = false
    line.ZIndex = 5
    line.Parent = gui

    Esp.items[plr] = { bill = bill, name = nameL, dist = distL, hl = hl, line = line }
end

local function espHide(it)
    it.bill.Enabled = false
    it.hl.Enabled = false
    it.line.Visible = false
end

local function espStep()
    local cam = Workspace.CurrentCamera
    local my = hrp()
    local col = espColor()
    local maxD = STATE.espMaxDist or 2000
    local vp = cam and cam.ViewportSize or Vector2.new(0, 0)
    local origin = Vector2.new(vp.X / 2, vp.Y)
    for plr, it in pairs(Esp.items) do
        local ch = plr.Character
        local root = ch and (ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Head"))
        if not (my and cam and root) then
            espHide(it)
        else
            local d = (my.Position - root.Position).Magnitude
            if d > maxD then
                espHide(it)
            else
                if it.bill.Adornee ~= root then it.bill.Adornee = root end
                if it.hl.Adornee ~= ch then it.hl.Adornee = ch end
                it.bill.Enabled = true
                it.hl.Enabled = STATE.espBox ~= false
                it.hl.FillColor = col
                it.hl.OutlineColor = STATE.espOutline or Color3.new(1, 1, 1)
                it.hl.FillTransparency = STATE.espFill and 0.35 or 0.75
                it.name.TextColor3 = col
                it.name.Visible = STATE.espName ~= false
                it.dist.Visible = STATE.espDist ~= false
                if STATE.espDist ~= false then it.dist.Text = string.format("%.0f studs", d) end

                if STATE.espLine ~= false then
                    local p = cam:WorldToViewportPoint(root.Position)
                    if p.Z > 0 then
                        local target = Vector2.new(p.X, p.Y)
                        local delta = target - origin
                        local len = delta.Magnitude
                        if len > 1 and len < 20000 then
                            local mid = origin + delta / 2
                            it.line.BackgroundColor3 = col
                            it.line.Size = UDim2.fromOffset(len, 2)
                            it.line.Position = UDim2.fromOffset(mid.X, mid.Y)
                            it.line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
                            it.line.Visible = true
                        else
                            it.line.Visible = false
                        end
                    else
                        it.line.Visible = false
                    end
                else
                    it.line.Visible = false
                end
            end
        end
    end
end

local function cheatsClearEsp()
    for _, c in ipairs({ "loop", "added", "removing" }) do
        if Esp[c] then pcall(function() Esp[c]:Disconnect() end) Esp[c] = nil end
    end
    for plr in pairs(Esp.items) do espDestroyItem(plr) end
    if Esp.gui then pcall(function() Esp.gui:Destroy() end) Esp.gui = nil end
    for _, g in ipairs(floatParent:GetChildren()) do
        if g.Name == "MT_ESP" then pcall(function() g:Destroy() end) end
    end
end

function Cheats.setEsp(on)
    STATE.espOn = on and true or false
    cheatsClearEsp()
    if not STATE.espOn then return end
    for _, p in ipairs(Players:GetPlayers()) do espNewItem(p) end
    Esp.added = Players.PlayerAdded:Connect(espNewItem)
    Esp.removing = Players.PlayerRemoving:Connect(espDestroyItem)
    Esp.loop = RunService.RenderStepped:Connect(function()
        local ok, err = pcall(espStep)
        if not ok then warn("[Memetrash] ESP: " .. tostring(err)) end
    end)
    if _G.MT_ActivateFx then _G.MT_ActivateFx(espColor()) end
end

function Cheats.refreshEspColors()
    if STATE.espOn and Esp.loop then pcall(espStep) end
end

function Cheats.setSpin(on)
    STATE.spinOn = on and true or false
    if Cheats.spinConn then
        pcall(function() Cheats.spinConn:Disconnect() end)
        Cheats.spinConn = nil
    end
    if not on then return end
    local ang = 0
    Cheats.spinConn = RunService.RenderStepped:Connect(function(dt)
        if not STATE.spinOn then return end
        local root = hrp()
        local h = hum()
        if not (root and h) or h.Health <= 0 then return end

        local speed = tonumber(STATE.spinSpeed) or 12
        ang = (ang + math.rad(speed * 60) * dt) % (math.pi * 2)
        local pos = root.Position
        local _, y, _ = root.CFrame:ToOrientation()

        root.CFrame = CFrame.new(pos) * CFrame.Angles(0, ang, 0)
        root.AssemblyAngularVelocity = Vector3.zero
    end)
    if _G.MT_ActivateFx then _G.MT_ActivateFx(NEON_PURPLE) end
end

function Cheats.setFling(on)
    STATE.flingOn = on and true or false
    if Cheats.flingConn then
        pcall(function() Cheats.flingConn:Disconnect() end)
        Cheats.flingConn = nil
    end
    if not on then return end

    local function hookChar(char)
        local root = char:WaitForChild("HumanoidRootPart", 8)
        if not root then return end
        Cheats.flingConn = root.Touched:Connect(function(hit)
            if not STATE.flingOn then return end
            local other = hit:FindFirstAncestorOfClass("Model")
            if not other or other == char then return end
            local oh = other:FindFirstChildOfClass("Humanoid")
            local oroot = other:FindFirstChild("HumanoidRootPart")
            if not (oh and oroot) then return end
            if Players:GetPlayerFromCharacter(other) == nil then return end
            local force = tonumber(STATE.flingForce) or 180
            local dir = (oroot.Position - root.Position)
            if dir.Magnitude < 0.05 then
                dir = root.CFrame.LookVector
            else
                dir = dir.Unit
            end
            local up = Vector3.new(0, 0.55, 0)
            pcall(function()
                oroot.AssemblyLinearVelocity = (dir + up) * force
            end)
            pcall(function()
                local bv = Instance.new("BodyVelocity")
                bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                bv.Velocity = (dir + up) * force
                bv.Parent = oroot
                task.delay(0.12, function() pcall(function() bv:Destroy() end) end)
            end)
        end)
    end

    if lp.Character then hookChar(lp.Character) end
    bind(lp.CharacterAdded:Connect(function(c)
        if Cheats.flingConn then pcall(function() Cheats.flingConn:Disconnect() end) end
        if STATE.flingOn then hookChar(c) end
    end))
    if _G.MT_ActivateFx then _G.MT_ActivateFx(NEON_MAGENTA) end
end

-- // NbDetector — proximity anti-nextbot: fires PlayEvent on approach, double-snap on teleport

local NbDetector = {
    active       = false,
    detectRadius = 20,
    cooldown     = 5.5,
    pollRate     = 0.1,
    teleThresh   = 8,
    charConn     = nil,
    heartbeats   = {},
}

function NbDetector.startChar(char)
    local root   = char:WaitForChild("HumanoidRootPart", 10)
    local hitbox = char:WaitForChild("Hitbox", 10)
    if not root or not hitbox then return end

    local ok, rem = pcall(function()
        return RS:WaitForChild("REs", 5):WaitForChild("PlayEvent", 5)
    end)
    if not ok or not rem then return end

    local nextbotFolder = workspace:FindFirstChild("Nextbots")
    if not nextbotFolder then return end

    local lastFire = -math.huge
    local firing   = false
    local lastSnap = nil
    local alive    = true

    char.AncestryChanged:Connect(function()
        if not char:IsDescendantOf(workspace) then alive = false end
    end)

    local function getRoots()
        local roots = {}
        for _, model in ipairs(nextbotFolder:GetChildren()) do
            local r = model:FindFirstChild("HumanoidRootPart")
                   or model:FindFirstChildOfClass("BasePart")
            if r then roots[#roots + 1] = r end
        end
        return roots
    end

    local function waitForInvulnEnd()
        local conn
        conn = char:GetAttributeChangedSignal("Invulnerable"):Connect(function()
            if not char:GetAttribute("Invulnerable") then
                conn:Disconnect()
                lastFire = tick()
                firing   = false
            end
        end)
    end

    local snap = RunService.Heartbeat:Connect(function()
        if not alive or firing then return end
        lastSnap = root.CFrame
    end)
    NbDetector.heartbeats[#NbDetector.heartbeats + 1] = snap

    local timer = 0
    local det = RunService.Heartbeat:Connect(function(dt)
        if not alive then return end
        timer = timer + dt
        if timer < NbDetector.pollRate then return end
        timer = 0

        if firing or not lastSnap then return end
        if tick() - lastFire < NbDetector.cooldown then return end

        local hitboxPos = hitbox.Position

        for _, nbRoot in ipairs(getRoots()) do
            if (nbRoot.Position - hitboxPos).Magnitude <= NbDetector.detectRadius then
                local snapCF = lastSnap
                firing = true

                local prevPos = root.Position
                local conn
                conn = root:GetPropertyChangedSignal("CFrame"):Connect(function()
                    if not alive then conn:Disconnect() return end
                    local delta = (root.Position - prevPos).Magnitude
                    if delta > NbDetector.teleThresh then
                        conn:Disconnect()
                        local vel = root.AssemblyLinearVelocity
                        root.CFrame = snapCF
                        root.AssemblyLinearVelocity = vel
                        task.defer(function()
                            if alive and root and root.Parent then
                                root.CFrame = snapCF
                                root.AssemblyLinearVelocity = vel
                            end
                        end)
                    else
                        prevPos = root.Position
                    end
                end)

                task.delay(2, function() conn:Disconnect() end)
                pcall(function() rem:FireServer() end)
                waitForInvulnEnd()
                break
            end
        end
    end)
    NbDetector.heartbeats[#NbDetector.heartbeats + 1] = det
end

function NbDetector.start()
    if NbDetector.active then return end
    NbDetector.active = true

    NbDetector.charConn = lp.CharacterAdded:Connect(function(char)
        task.spawn(NbDetector.startChar, char)
    end)
    if lp.Character then task.spawn(NbDetector.startChar, lp.Character) end

    notify("Anti-Nextbot", "Detector active (r=" .. NbDetector.detectRadius .. " cd=" .. NbDetector.cooldown .. "s)", 3)
    if _G.MT_ActivateFx then _G.MT_ActivateFx(NEON_MAGENTA) end
end

function NbDetector.stop()
    if not NbDetector.active then return end
    NbDetector.active = false

    if NbDetector.charConn then
        pcall(function() NbDetector.charConn:Disconnect() end)
        NbDetector.charConn = nil
    end
    for _, c in ipairs(NbDetector.heartbeats) do
        pcall(function() c:Disconnect() end)
    end
    NbDetector.heartbeats = {}
    notify("Anti-Nextbot", "Detector off", 2)
end

function Cheats.castVoteBots()
    local mapName = tostring(STATE.voteMap or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local count = math.clamp(tonumber(STATE.voteCount) or 5, 1, 50)
    if mapName == "" then
        notify("Votes", "Set a map name first", 3)
        return
    end
    local fired = 0
    local clicked = 0
    local foundRemotes = {}

    local function tryFire(ev, args)
        if not ev then return end
        pcall(function()
            if ev:IsA("RemoteEvent") then
                for _ = 1, count do
                    ev:FireServer(table.unpack(args))
                    fired = fired + 1
                end
            elseif ev:IsA("RemoteFunction") then
                for _ = 1, count do
                    ev:InvokeServer(table.unpack(args))
                    fired = fired + 1
                end
            end
        end)
    end

    local roots = {
        RS:FindFirstChild("REs"),
        RS:FindFirstChild("Remotes"),
        RS:FindFirstChild("Events"),
        RS:FindFirstChild("Packages"),
        RS,
    }
    for _, folder in ipairs(roots) do
        if folder then
            for _, ch in ipairs(folder:GetDescendants()) do
                if ch:IsA("RemoteEvent") or ch:IsA("RemoteFunction") then
                    local n = ch.Name:lower()
                    if n:find("vote") or n:find("map") or n:find("choose") or n:find("ballot")
                            or n:find("poll") or n:find("select") or n:find("round") then
                        foundRemotes[#foundRemotes + 1] = ch:GetFullName()
                        tryFire(ch, { mapName })
                        tryFire(ch, { mapName, count })
                        tryFire(ch, { true, mapName })
                        tryFire(ch, { count, mapName })
                        tryFire(ch, { mapName, true })
                        tryFire(ch, { { Name = mapName, Votes = count } })
                        tryFire(ch, { mapName, "vote" })
                    end
                end
            end
        end
    end

    local pg = lp:FindFirstChild("PlayerGui")
    if pg then
        for _, d in ipairs(pg:GetDescendants()) do
            if d:IsA("TextButton") or d:IsA("ImageButton") or d:IsA("TextLabel") then
                local text = ""
                pcall(function() text = tostring(d.Text or d.Name or "") end)
                if text ~= "" and text:lower():find(mapName:lower(), 1, true) then
                    local btn = d
                    if not (btn:IsA("GuiButton") or btn:IsA("TextButton") or btn:IsA("ImageButton")) then
                        btn = d:FindFirstAncestorWhichIsA("GuiButton") or d.Parent
                    end
                    if btn and (btn:IsA("GuiButton") or btn:IsA("TextButton") or btn:IsA("ImageButton")) then
                        if type(getconnections) == "function" then
                            for _, sigName in ipairs({ "Activated", "MouseButton1Click", "MouseButton1Down" }) do
                                local sig = btn[sigName]
                                if typeof(sig) == "RBXScriptSignal" then
                                    local ok, list = pcall(getconnections, sig)
                                    if ok and type(list) == "table" then
                                        for _, c in ipairs(list) do
                                            pcall(function()
                                                if c.Fire then c:Fire()
                                                elseif type(c.Function) == "function" then c.Function() end
                                            end)
                                            clicked = clicked + 1
                                        end
                                    end
                                end
                            end
                        end
                        pcall(function() if firesignal then firesignal(btn.Activated) end end)
                        for _ = 1, math.min(count, 5) do
                            pcall(function()
                                if typeof(btn.Activate) == "function" then btn:Activate() end
                            end)
                        end
                    end
                end
            end
        end
    end

    local msg = "Map '" .. mapName .. "' | remotes~" .. tostring(fired) .. " | ui~" .. tostring(clicked)
    if #foundRemotes > 0 then
        msg = msg .. " | hit: " .. foundRemotes[1]
    else
        msg = msg .. " | no vote remote name matched (open vote UI once)"
    end
    notify("Votes", msg, 5)
    if _G.MT_ActivateFx then _G.MT_ActivateFx(cheatsAccent()) end
end

function Cheats.cleanup()
    STATE.espOn = false
    STATE.spinOn = false
    STATE.flingOn = false
    cheatsClearEsp()
    pcall(NbDetector.stop)
    if Cheats.spinConn then pcall(function() Cheats.spinConn:Disconnect() end) end
    if Cheats.flingConn then pcall(function() Cheats.flingConn:Disconnect() end) end
    Cheats.spinConn, Cheats.flingConn = nil, nil
end

-- // CosUnlock v5 — itemIndex-aware fakeOwn, emote-block, slot-restore, connector mount

local CosUnlock = { active = false, charConn = nil, oldCall = nil }

function CosUnlock.start()
    if CosUnlock.active then return end
    CosUnlock.active = true

    local rEs             = RS:FindFirstChild("REs")
    local itemsFolder     = RS:FindFirstChild("Items")
    if not rEs or not itemsFolder then
        notify("Cosmetics", "REs or Items folder missing", 3)
        CosUnlock.active = false return
    end

    local equipCosEvent   = rEs:FindFirstChild("EquipCosmeticEvent")
    local equipEmoteEvent = rEs:FindFirstChild("EquipEvent")
    local emoteStateEvent = rEs:FindFirstChild("EmoteStateEvent")
    local cosmeticsFolder = itemsFolder:FindFirstChild("Cosmetics")
    local emotesFolder    = itemsFolder:FindFirstChild("Emotes")
    local titlesFolder    = itemsFolder:FindFirstChild("Titles")

    local itemIndex = nil
    pcall(function()
        itemIndex = require(RS:WaitForChild("ItemIndex"))
    end)

    local inventory         = lp:FindFirstChild("Inventory")
    local invCosmetics      = inventory and inventory:FindFirstChild("Cosmetics")
    local invEmotes         = inventory and inventory:FindFirstChild("Emotes")
    local invTitles         = inventory and inventory:FindFirstChild("Titles")
    local equippedCosmetics = lp:FindFirstChild("EquippedCosmetics")
    local equippedEmotes    = lp:FindFirstChild("EquippedEmotes")

    local bodyPartMap = {
        "Head", "Torso", "Left Arm", "Right Arm",
        "Left Leg", "Right Leg", "HumanoidRootPart"
    }

    -- snapshot real emote inventory before injecting fakes
    local realOwnedEmotes = {}
    if invEmotes then
        for _, sv in ipairs(invEmotes:GetChildren()) do
            realOwnedEmotes[sv.Name] = true
        end
    end

    -- fakeOwn via itemIndex.GetGroups (preferred), fallback to folder scan
    local function fakeOwnFromGroups(folder, category)
        if not itemIndex then return false end
        local ok, groups = pcall(itemIndex.GetGroups, category)
        if not ok or type(groups) ~= "table" then return false end
        for _, group in ipairs(groups) do
            if type(group.Items) == "table" then
                for _, item in ipairs(group.Items) do
                    if typeof(item) == "Instance" and not folder:FindFirstChild(item.Name) then
                        local sv    = Instance.new("StringValue")
                        sv.Name     = item.Name
                        sv.Value    = item.Name
                        sv.Parent   = folder
                    end
                end
            end
        end
        return true
    end

    local function fakeOwnFromFolder(folder, reg)
        if not folder or not reg then return end
        for _, item in ipairs(reg:GetChildren()) do
            if not folder:FindFirstChild(item.Name) then
                local sv    = Instance.new("StringValue")
                sv.Name     = item.Name
                sv.Value    = item.Name
                sv.Parent   = folder
            end
        end
    end

    if invCosmetics then
        if not fakeOwnFromGroups(invCosmetics, "Cosmetics") then fakeOwnFromFolder(invCosmetics, cosmeticsFolder) end
    end
    if invEmotes then
        if not fakeOwnFromGroups(invEmotes, "Emotes") then fakeOwnFromFolder(invEmotes, emotesFolder) end
    end
    if invTitles then
        if not fakeOwnFromGroups(invTitles, "Titles") then fakeOwnFromFolder(invTitles, titlesFolder) end
    end

    -- build set of injected emote names for the hook to filter
    local fakeOwnedEmotes = {}
    if invEmotes then
        for _, sv in ipairs(invEmotes:GetChildren()) do
            if not realOwnedEmotes[sv.Name] then
                fakeOwnedEmotes[sv.Name] = true
            end
        end
    end

    local function forceEquipped(folder, slotName, value)
        if not folder then return end
        local sv = folder:FindFirstChild(slotName)
        if sv and sv:IsA("StringValue") then
            sv.Value = value
        else
            local new   = Instance.new("StringValue")
            new.Name    = slotName
            new.Value   = value
            new.Parent  = folder
        end
    end

    -- slot-restore: if server clears a fake emote slot, write it back
    local desiredEmotes = {}
    local restoringSlot = {}

    local function watchEmoteSlot(sv)
        if not sv:IsA("StringValue") then return end
        sv.Changed:Connect(function(val)
            if restoringSlot[sv.Name] then return end
            local desired = desiredEmotes[sv.Name]
            if val == "" and desired then
                restoringSlot[sv.Name] = true
                task.wait(0.25)
                if desiredEmotes[sv.Name] then sv.Value = desiredEmotes[sv.Name] end
                restoringSlot[sv.Name] = false
            end
        end)
    end

    if equippedEmotes then
        equippedEmotes.ChildAdded:Connect(watchEmoteSlot)
        for _, sv in ipairs(equippedEmotes:GetChildren()) do watchEmoteSlot(sv) end
    end

    -- connector-aware mount (matches game's attachment scheme)
    local function isCosmeticConnector(att)
        if not att:IsA("Attachment") then return false end
        local n = string.lower(att.Name):gsub("%s+", "")
        return n:match("^connector%d*$") ~= nil or n:match("^connecter%d*$") ~= nil
    end

    local function getCosmeticConnectors(itemDef)
        local list = {}
        for _, desc in ipairs(itemDef:GetDescendants()) do
            if isCosmeticConnector(desc) then table.insert(list, desc) end
        end
        table.sort(list, function(a, b)
            local na = tonumber(a.Name:match("(%d+)$")) or 0
            local nb = tonumber(b.Name:match("(%d+)$")) or 0
            return na == nb and a.Name < b.Name or na < nb
        end)
        return list
    end

    local function getConnectionPartName(cp)
        if not cp then return nil end
        if cp:IsA("ObjectValue") then
            return (cp.Value and cp.Value:IsA("BasePart")) and cp.Value.Name or nil
        elseif cp:IsA("ValueBase") then
            local v = cp.Value
            local n = tonumber(v)
            if n then return bodyPartMap[n] end
            if typeof(v) == "string" and v ~= "" then return v end
        end
        return nil
    end

    local function getCosmetic(name)
        local def = nil
        if itemIndex then
            pcall(function()
                local reg = itemIndex.Get("Cosmetics")
                if reg then def = reg:FindFirstChild(name) end
            end)
        end
        if not def and cosmeticsFolder then
            def = cosmeticsFolder:FindFirstChild(name)
        end
        return def
    end

    local function clearSlotCosmetic(character, slotName)
        for _, child in ipairs(character:GetChildren()) do
            if child.Name == "LocalCosmetic_" .. slotName then child:Destroy() end
        end
    end

    local function mountCosmetic(character, itemDef, tag)
        if not (character and itemDef) then return nil end
        local connectors = getCosmeticConnectors(itemDef)
        local clone      = itemDef:Clone()
        clone.Name       = tag
        local price      = clone:FindFirstChild("Price")
        if price then price:Destroy() end

        if #connectors > 0 then
            local pivotCF = itemDef:IsA("Model") and itemDef:GetPivot() or CFrame.identity
            local welded  = 0
            clone.Parent  = character
            for _, connector in ipairs(connectors) do
                local cpChild  = connector:FindFirstChild("ConnectionPart", true)
                local partName = getConnectionPartName(cpChild)
                local charPart = partName and character:FindFirstChild(partName)
                if charPart and charPart:IsA("BasePart") then
                    local cloneAtt = clone:FindFirstChild(connector.Name, true)
                    if cloneAtt and cloneAtt:IsA("Attachment") then
                        local worldCF = pivotCF * connector.CFrame
                        for _, desc in ipairs(cloneAtt:GetDescendants()) do
                            if desc:IsA("BasePart") then
                                desc.Anchored   = false
                                desc.CanCollide = false
                                desc.CanQuery   = false
                                desc.CanTouch   = false
                                desc.Massless   = true
                                desc.CFrame     = charPart.CFrame * worldCF:ToObjectSpace(desc.CFrame)
                                local weld      = Instance.new("WeldConstraint")
                                weld.Part0      = charPart
                                weld.Part1      = desc
                                weld.Parent     = desc
                                welded          = welded + 1
                            end
                        end
                    end
                end
            end
            if welded == 0 then clone:Destroy() return nil end
            return clone
        else
            local cp       = itemDef:FindFirstChild("ConnectionPart")
            local partName = getConnectionPartName(cp) or "Torso"
            local anchor   = character:FindFirstChild(partName)
            if not anchor then return nil end
            clone.Parent = character
            local cpClone = clone:FindFirstChild("ConnectionPart")
            if cpClone then cpClone:Destroy() end
            local firstPart = nil
            for _, desc in ipairs(clone:GetDescendants()) do
                if desc:IsA("BasePart") then
                    desc.Anchored   = false
                    desc.CanCollide = false
                    desc.CanQuery   = false
                    desc.CanTouch   = false
                    desc.Massless   = true
                    desc.CFrame     = anchor.CFrame
                    firstPart       = firstPart or desc
                end
            end
            local attach = clone:FindFirstChild("Attach", true)
            if attach and firstPart then
                local worldCF = attach.WorldCFrame
                local charAtt = anchor:FindFirstChild("CosmeticCharAttachment")
                if not charAtt then
                    charAtt        = Instance.new("Attachment")
                    charAtt.Name   = "CosmeticCharAttachment"
                    charAtt.Parent = anchor
                end
                local mountAtt       = Instance.new("Attachment")
                mountAtt.WorldCFrame = worldCF
                mountAtt.Parent      = firstPart
                attach:Destroy()
                local rc             = Instance.new("RigidConstraint")
                rc.Attachment0       = charAtt
                rc.Attachment1       = mountAtt
                rc.Parent            = clone
            end
            return clone
        end
    end

    local function applyCosmetics(character)
        if not equippedCosmetics then return end
        for _, child in ipairs(character:GetChildren()) do
            if string.match(child.Name, "^LocalCosmetic_") then child:Destroy() end
        end
        local seen = {}
        for _, slot in ipairs(equippedCosmetics:GetChildren()) do
            if slot:IsA("StringValue") and slot.Value ~= "" then
                local name = slot.Value
                if not seen[name] then
                    seen[name]    = true
                    local itemDef = getCosmetic(name)
                    if itemDef then mountCosmetic(character, itemDef, "LocalCosmetic_" .. slot.Name) end
                end
            end
        end
    end

    local function onCharacter(character)
        character:WaitForChild("HumanoidRootPart", 10)
        task.wait(0.3)
        applyCosmetics(character)
    end

    CosUnlock.charConn = lp.CharacterAdded:Connect(onCharacter)
    if lp.Character then task.spawn(onCharacter, lp.Character) end

    if equippedCosmetics then
        local function watchCosSlot(sv)
            if not sv:IsA("StringValue") then return end
            sv.Changed:Connect(function(val)
                local character = lp.Character
                if not character then return end
                clearSlotCosmetic(character, sv.Name)
                if val ~= "" then
                    local itemDef = getCosmetic(val)
                    if itemDef then mountCosmetic(character, itemDef, "LocalCosmetic_" .. sv.Name) end
                end
            end)
        end
        equippedCosmetics.ChildAdded:Connect(watchCosSlot)
        for _, sv in ipairs(equippedCosmetics:GetChildren()) do watchCosSlot(sv) end
    end

    local mt    = getrawmetatable(game)
    local okRO  = pcall(setreadonly, mt, false)
    if not okRO then notify("Cosmetics", "setreadonly failed — hook skipped", 3) return end

    local oldCall       = mt.__namecall
    CosUnlock.oldCall   = oldCall

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" then

            -- block emoteStateEvent for fake-owned emotes:
            -- animation already plays locally; suppressing the server call means
            -- the server never validates → never sends StopEmote back → loop holds
            if emoteStateEvent and self == emoteStateEvent then
                local action, emoteName = ...
                if action == true and fakeOwnedEmotes[emoteName] then
                    return
                end
            end

            if equipCosEvent and self == equipCosEvent then
                local action, slotName, itemName = ...
                if action == "Equip" and slotName and itemName then
                    forceEquipped(equippedCosmetics, slotName, itemName)
                elseif action == "Unequip" and slotName then
                    forceEquipped(equippedCosmetics, slotName, "")
                end
            elseif equipEmoteEvent and self == equipEmoteEvent then
                local action, sectorName, emoteName = ...
                if action == "Equip" and sectorName and emoteName then
                    desiredEmotes[sectorName] = emoteName
                    forceEquipped(equippedEmotes, sectorName, emoteName)
                elseif action == "Unequip" and sectorName then
                    desiredEmotes[sectorName] = nil
                    forceEquipped(equippedEmotes, sectorName, "")
                end
            end
        end
        return oldCall(self, ...)
    end)

    pcall(setreadonly, mt, true)
    notify("Cosmetics", "All cosmetics unlocked", 3)
    if _G.MT_ActivateFx then _G.MT_ActivateFx(NEON_CYAN) end
end

function CosUnlock.stop()
    if not CosUnlock.active then return end
    CosUnlock.active = false

    if CosUnlock.oldCall then
        pcall(function()
            local mt = getrawmetatable(game)
            setreadonly(mt, false)
            mt.__namecall = CosUnlock.oldCall
            setreadonly(mt, true)
        end)
        CosUnlock.oldCall = nil
    end

    if CosUnlock.charConn then
        pcall(function() CosUnlock.charConn:Disconnect() end)
        CosUnlock.charConn = nil
    end

    local char = lp.Character
    if char then
        for _, child in ipairs(char:GetChildren()) do
            if string.match(child.Name, "^LocalCosmetic_") then
                pcall(function() child:Destroy() end)
            end
        end
    end

    notify("Cosmetics", "Cosmetic unlock off", 2)
end

do
    local okW, resW = pcall(function()
        return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
    end)
    if not okW or not resW then
        warn("[Memetrash] WindUI failed to load: ", resW)
        error("[Memetrash] WindUI failed: " .. tostring(resW))
    end
    WindUI = resW
end

local Window = WindUI:CreateWindow({
    Title = "Memetrash",
    Author = "Memetrash",
    Folder = "Memetrash",
    Size = UDim2.fromOffset(560, 440),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 160,
})

pcall(function()
    local TweenService = game:GetService("TweenService")
    local Lighting = game:GetService("Lighting")
    local RunService = game:GetService("RunService")

    pcall(function()
        if WindUI.SetTheme then
            WindUI:SetTheme("Dark")
        end
    end)
    pcall(function()
        if type(WindUI.AddTheme) == "function" then
            WindUI:AddTheme({
                Name = "MemetrashNeon",
                Accent = Color3.fromRGB(0, 229, 255),
                Outline = Color3.fromRGB(180, 70, 255),
                Text = Color3.fromRGB(240, 245, 255),
                Placeholder = Color3.fromRGB(140, 150, 180),
                Background = Color3.fromRGB(8, 6, 16),
                Button = Color3.fromRGB(18, 12, 32),
                Icon = Color3.fromRGB(0, 229, 255),
            })
            if WindUI.SetTheme then WindUI:SetTheme("MemetrashNeon") end
        end
    end)

    local blur = Lighting:FindFirstChild("MT_UIBlur")
    if not blur then
        blur = Instance.new("BlurEffect")
        blur.Name = "MT_UIBlur"
        blur.Parent = Lighting
    end
    blur.Size = 0
    blur.Enabled = false
    local colorCc = Lighting:FindFirstChild("MT_UIColor")
    if not colorCc then
        colorCc = Instance.new("ColorCorrectionEffect")
        colorCc.Name = "MT_UIColor"
        colorCc.TintColor = Color3.fromRGB(200, 180, 255)
        colorCc.Saturation = 0.05
        colorCc.Contrast = 0.05
        colorCc.Enabled = false
        colorCc.Parent = Lighting
    end

    local function setUiFx(open)
        local goalBlur = (open and STATE.uiBlur == true) and 16 or 0
        TweenService:Create(blur, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = goalBlur
        }):Play()
        colorCc.Enabled = false
    end

    local function findRoot()
        if Window and Window.Root and typeof(Window.Root) == "Instance" then
            return Window.Root
        end
        local pg = lp:FindFirstChild("PlayerGui")
        if not pg then return nil end
        for _, g in ipairs(pg:GetDescendants()) do
            if g:IsA("Frame") and g.Name:lower():find("window") then
                return g
            end
        end
        return nil
    end

    task.defer(function()
        local root = findRoot()
        if not root then return end
        setUiFx(true)

        local stroke = root:FindFirstChild("MT_NeonStroke")
        if not stroke then
            stroke = Instance.new("UIStroke")
            stroke.Name = "MT_NeonStroke"
            stroke.Thickness = 2
            stroke.Transparency = 0.25
            stroke.Color = Color3.fromRGB(0, 229, 255)
            stroke.Parent = root
            local g = Instance.new("UIGradient")
            g.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 229, 255)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 80, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 40, 255)),
            })
            g.Parent = stroke
            RunService.RenderStepped:Connect(function()
                if not stroke.Parent then return end
                g.Rotation = (os.clock() * 40) % 360
            end)
        end

        local scale = root:FindFirstChildOfClass("UIScale")
        if not scale then
            scale = Instance.new("UIScale")
            scale.Parent = root
        end
        scale.Scale = 0.92
        TweenService:Create(scale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Scale = 1
        }):Play()
    end)

    local rawNotify = WindUI.Notify
    if type(rawNotify) == "function" then
        WindUI.Notify = function(self, opts)
            if type(opts) == "table" then
                opts.Duration = opts.Duration or 3
            end
            return rawNotify(self, opts)
        end
    end

    local prevUnload = getgenv().MT_Unload

    getgenv().__MT_ClearUiFx = function()
        pcall(function()
            blur.Size = 0
            colorCc.Enabled = false
        end)
    end
end)

do
    local menuOpen = true
    local TS = game:GetService("TweenService")
    local Lighting = game:GetService("Lighting")
    bind(UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.RightControl then
            menuOpen = not menuOpen
            pcall(function()
                local blur = Lighting:FindFirstChild("MT_UIBlur")
                local cc   = Lighting:FindFirstChild("MT_UIColor")
                if blur then
                    TS:Create(blur, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = (menuOpen and STATE.uiBlur ~= false) and 16 or 0
                    }):Play()
                end
                if cc then cc.Enabled = menuOpen end
            end)
        end
    end))
end

local Amoled = { on = false, conns = {}, saved = {} }

local function amoledIsPanel(g)
    if not g:IsA("GuiObject") then return false end
    if g:IsA("TextLabel") or g:IsA("TextButton") or g:IsA("ImageLabel") or g:IsA("ImageButton") then

        if g:IsA("TextLabel") and g.BackgroundTransparency >= 0.95 then return false end
    end
    return g:IsA("Frame") or g:IsA("ScrollingFrame") or g:IsA("CanvasGroup")
        or (g:IsA("TextButton") and g.Text == "")
end

function Amoled.apply(on)
    Amoled.on = on and true or false
    STATE.amoledOn = Amoled.on
    local root = Window and Window.Root
    if typeof(root) ~= "Instance" then

        pcall(function()
            local pg = lp:FindFirstChild("PlayerGui")
            if pg then
                for _, d in ipairs(pg:GetDescendants()) do
                    if d:IsA("Frame") and d.Name:lower():find("window") then
                        root = d
                        break
                    end
                end
            end
        end)
    end
    if typeof(root) ~= "Instance" then return end

    if on then
        Amoled.saved = Amoled.saved or {}
        local function paint(g)
            if not amoledIsPanel(g) then return end
            if g:GetAttribute("MT_AmoledSkip") then return end
            local key = g
            if Amoled.saved[key] == nil then
                Amoled.saved[key] = {
                    bg = g.BackgroundColor3,
                    bt = g.BackgroundTransparency,
                }
            end
            g.BackgroundColor3 = Color3.new(0, 0, 0)
            if g.BackgroundTransparency < 0.4 then
                g.BackgroundTransparency = 0
            end
        end
        paint(root)
        for _, d in ipairs(root:GetDescendants()) do
            paint(d)
        end

        for _, c in ipairs(Amoled.conns) do pcall(function() c:Disconnect() end) end
        Amoled.conns = {}
        Amoled.conns[#Amoled.conns + 1] = root.DescendantAdded:Connect(function(d)
            if Amoled.on then task.defer(paint, d) end
        end)

        pcall(function()
            for _, b in ipairs({ Lag.btn, ajBtn, bounceBtn, Crouch.btnObj, Macro.btn }) do
                if b and b.Gui then
                    for _, d in ipairs(b.Gui:GetDescendants()) do
                        if d:IsA("TextButton") or d:IsA("Frame") then
                            if d.BackgroundTransparency < 0.9 then
                                d.BackgroundColor3 = Color3.new(0, 0, 0)
                            end
                        end
                    end
                end
            end
        end)
    else
        for g, s in pairs(Amoled.saved or {}) do
            pcall(function()
                if g and g.Parent then
                    g.BackgroundColor3 = s.bg
                    g.BackgroundTransparency = s.bt
                end
            end)
        end
        Amoled.saved = {}
        for _, c in ipairs(Amoled.conns) do pcall(function() c:Disconnect() end) end
        Amoled.conns = {}
    end
end

local MoveTab = Window:Tab({ Title = "Movement", Icon = "zap" })
local JumpTab = Window:Tab({ Title = "Jump & Trimp", Icon = "arrow-up" })
local SafeTab = Window:Tab({ Title = "Safety & Farm", Icon = "shield" })
local LagTab = Window:Tab({ Title = "Lagswitch", Icon = "snowflake" })
local VipTab = Window:Tab({ Title = "VIP", Icon = "crown" })
local UtilTab = Window:Tab({ Title = "Utility", Icon = "wrench" })
local ConfigTab = Window:Tab({ Title = "Config", Icon = "settings" })
local CheatsTab = Window:Tab({ Title = "Cheats", Icon = "swords" })
local VisualTab = Window:Tab({ Title = "Visuals", Icon = "eye" })

local function num(v, fallback)
    return tonumber(v) or fallback
end

MoveTab:Section({ Title = "Speed", TextSize = 14 })
MoveTab:Toggle({
    Title = "Speed Changer", Value = false,
    Callback = function(v)
        STATE.speedOn = v and true or false
        local h = hum()
        if not Engine.ok and h then
            h.WalkSpeed = STATE.speedOn and STATE.speed or Engine.defaultWS
        end
    end,
})
MoveTab:Slider({
    Title = "Speed", Step = 1, Value = { Min = 16, Max = 300, Default = 50 },
    Callback = function(v)
        STATE.speed = num(v, STATE.speed)
        local h = hum()
        if STATE.speedOn and h and not Engine.ok then h.WalkSpeed = STATE.speed end
    end,
})
MoveTab:Space()

MoveTab:Section({ Title = "Air", TextSize = 14 })
MoveTab:Toggle({
    Title = "Air Strafe Accel", Value = false,
    Callback = function(v) STATE.airOn = v and true or false end,
})
MoveTab:Slider({
    Title = "Air Acceleration", Step = 1, Value = { Min = 10, Max = 1000, Default = 182 },
    Callback = function(v) STATE.airAccel = num(v, STATE.airAccel) end,
})
MoveTab:Space()

MoveTab:Section({ Title = "Frontal / Back Jump", TextSize = 14 })
MoveTab:Toggle({
    Title = "Frontal Jump", Value = false,
    Callback = function(v) STATE.frontalOn = v and true or false end,
})
MoveTab:Slider({
    Title = "Frontal Speed", Step = 1, Value = { Min = 10, Max = 250, Default = 60 },
    Callback = function(v) STATE.frontalSpeed = num(v, STATE.frontalSpeed) end,
})
MoveTab:Toggle({
    Title = "Back Jump", Value = false,
    Callback = function(v) STATE.backOn = v and true or false end,
})
MoveTab:Slider({
    Title = "Back Speed", Step = 1, Value = { Min = 10, Max = 250, Default = 60 },
    Callback = function(v) STATE.backSpeed = num(v, STATE.backSpeed) end,
})
MoveTab:Space()

MoveTab:Section({ Title = "Fly", TextSize = 14 })
MoveTab:Toggle({
    Title = "Fly", Value = false,
    Callback = function(v)
        STATE.flyOn = v and true or false
        local h = hum()
        if h then h.PlatformStand = STATE.flyOn end
    end,
})
MoveTab:Slider({
    Title = "Fly Speed", Step = 1, Value = { Min = 10, Max = 250, Default = 60 },
    Callback = function(v) STATE.flySpeed = num(v, STATE.flySpeed) end,
})

JumpTab:Section({ Title = "Auto Jump", TextSize = 14 })
JumpTab:Toggle({
    Title = "Auto Jump", Value = false,
    Callback = function(v)
        STATE.autoJump = v and true or false
        ajBtn:SetActive(STATE.autoJump)
        ajBtn:SetStatusText(STATE.autoJump and "ON" or "OFF")
    end,
})
JumpTab:Toggle({
    Title = "Auto Jump Button", Value = false,
    Callback = function(v) ajBtn:SetEnabled(v) end,
})
JumpTab:Slider({
    Title = "Auto Jump Button Size (%)",
    Step = 5,
    Value = { Min = 50, Max = 250, Default = 100 },
    Callback = function(v)
        if ajBtn then ajBtn:SetSizePercent(v) end
    end,
})
JumpTab:Space()

JumpTab:Section({ Title = "Auto Crouch", TextSize = 14 })
JumpTab:Toggle({
    Title = "Auto Crouch", Value = false,
    Callback = function(v) Crouch.set(v) end,
})
JumpTab:Slider({
    Title = "Crouch Speed", Step = 1, Value = { Min = 1, Max = 10, Default = 7 },
    Callback = function(v) STATE.crouchSpeed = num(v, STATE.crouchSpeed) end,
})
JumpTab:Toggle({
    Title = "Auto Crouch Button", Value = false,
    Callback = function(v) Crouch.btnObj:SetEnabled(v) end,
})
JumpTab:Slider({
    Title = "Auto Crouch Button Size (%)",
    Step = 5,
    Value = { Min = 50, Max = 250, Default = 100 },
    Callback = function(v)
        if Crouch.btnObj then Crouch.btnObj:SetSizePercent(v) end
    end,
})
JumpTab:Space()

JumpTab:Section({ Title = "Edge Trimp", TextSize = 14 })
JumpTab:Toggle({
    Title = "Edge Trimp", Value = false,
    Callback = function(v)
        STATE.edgeTrimpOn = v and true or false
        if not v then edgeLastTrimp = -999 end
    end,
})
JumpTab:Input({
    Title = "Launch Mult", Default = "1.5", Placeholder = "default 1.5",
    Callback = function(v) STATE.edgeLaunchMult = num(v, STATE.edgeLaunchMult) end,
})
JumpTab:Input({
    Title = "Edge Trimp Offset", Default = "6", Placeholder = "default 6",
    Callback = function(v) STATE.edgeCastDist = num(v, STATE.edgeCastDist) end,
})
JumpTab:Space()

JumpTab:Section({ Title = "Bounce", TextSize = 14 })
JumpTab:Toggle({
    Title = "Auto Bounce", Value = false,
    Callback = function(v)
        STATE.bounceOn = v and true or false
        bounceBtn:SetActive(STATE.bounceOn)
        bounceBtn:SetStatusText(STATE.bounceOn and "ON" or "OFF")
    end,
})
JumpTab:Slider({
    Title = "Bounce Power", Step = 10, Value = { Min = 50, Max = 800, Default = 150 },
    Callback = function(v) STATE.bouncePower = num(v, STATE.bouncePower) end,
})
JumpTab:Toggle({
    Title = "Bounce Button", Value = false,
    Callback = function(v) bounceBtn:SetEnabled(v) end,
})
JumpTab:Slider({
    Title = "Bounce Button Size (%)",
    Step = 5,
    Value = { Min = 50, Max = 250, Default = 100 },
    Callback = function(v)
        if bounceBtn then bounceBtn:SetSizePercent(v) end
    end,
})

SafeTab:Section({ Title = "Auto Farm", TextSize = 14 })
SafeTab:Toggle({
    Title = "Auto Farm (platform at the top of the map)",
    Value = false,
    Callback = function(v)
        STATE.farmOn = v and true or false
        if STATE.farmOn then task.spawn(Farm.start) else Farm.stop() end
    end,
})
SafeTab:Slider({
    Title = "Height above the map", Step = 10, Value = { Min = 50, Max = 1000, Default = 150 },
    Callback = function(v) STATE.farmExtra = num(v, STATE.farmExtra) end,
})
SafeTab:Space()

SafeTab:Section({ Title = "Anti-Nextbot Detector", TextSize = 14 })
SafeTab:Toggle({
    Title = "Anti-Nextbot",
    Value = false,
    Callback = function(v)
        if v then NbDetector.start() else NbDetector.stop() end
    end,
})
SafeTab:Input({
    Title = "Detection Radius",
    Default = "20",
    Placeholder = "studs (e.g. 20)",
    Callback = function(v)
        local n = tonumber(v)
        if n then NbDetector.detectRadius = n end
    end,
})
SafeTab:Input({
    Title = "Cooldown (s)",
    Default = "5.5",
    Placeholder = "seconds (e.g. 5.5)",
    Callback = function(v)
        local n = tonumber(v)
        if n then NbDetector.cooldown = n end
    end,
})

LagTab:Section({ Title = "Lagswitch / Freeze", TextSize = 14 })
LagTab:Toggle({
    Title = "FFlag for Lagswitch",
    Value = false,
    Callback = function(v)
        Lag.setEnabled(v)
    end,
})
LagTab:Slider({
    Title = "FFlag Value (0-1000)",
    Step = 10,
    Value = { Min = 0, Max = 1000, Default = 1000 },
    Callback = function(v)
        Lag.setFlagValue(v)
    end,
})
LagTab:Slider({
    Title = "Freeze Duration (s)",
    Step = 0.05,
    Value = { Min = 0.1, Max = 1.5, Default = 0.35 },
    Callback = function(v)
        Lag.duration = num(v, 0.35)
    end,
})
LagTab:Slider({
    Title = "Freeze Cooldown (s)",
    Step = 1,
    Value = { Min = 0, Max = 10, Default = 1 },
    Callback = function(v)
        Lag.cooldownSec = num(v, 1)
    end,
})
LagTab:Button({
    Title = "Freeze Now",
    Justify = "Center",
    Callback = function() Lag.fire() end,
})
LagTab:Toggle({
    Title = "Lagswitch Button",
    Value = false,
    Callback = function(v) Lag.btn:SetEnabled(v) end,
})
LagTab:Slider({
    Title = "Lagswitch Button Size (%)",
    Step = 5,
    Value = { Min = 50, Max = 250, Default = 100 },
    Callback = function(v)
        if Lag.btn then Lag.btn:SetSizePercent(v) end
    end,
})

VipTab:Section({ Title = "VIP Commands", TextSize = 14 })
VipTab:Toggle({
    Title = "VipStrafe", Value = false,
    Callback = function(v) STATE.vipStrafeOn = v and true or false applyVip() end,
})
VipTab:Input({
    Title = "Strafe Mult", Default = "1", Placeholder = "e.g. 1 or 2",
    Callback = function(v)
        local n = tonumber(v)
        if n then STATE.vipStrafeMult = n if STATE.vipStrafeOn then applyVip() end end
    end,
})
VipTab:Toggle({
    Title = "VipSpeed", Value = false,
    Callback = function(v) STATE.vipSpeedOn = v and true or false applyVip() end,
})
VipTab:Input({
    Title = "VipSpeed Value", Default = "60", Placeholder = "e.g. 60",
    Callback = function(v)
        local n = tonumber(v)
        if n then STATE.vipSpeed = n if STATE.vipSpeedOn then applyVip() end end
    end,
})
VipTab:Toggle({
    Title = "VipJump", Value = false,
    Callback = function(v) STATE.vipJumpOn = v and true or false applyVip() end,
})
VipTab:Input({
    Title = "VipJump Value", Default = "10", Placeholder = "e.g. 10",
    Callback = function(v)
        local n = tonumber(v)
        if n then STATE.vipJump = n if STATE.vipJumpOn then applyVip() end end
    end,
})

ConfigTab:Section({ Title = "Visuals", TextSize = 14 })
ConfigTab:Toggle({
    Title = "AMOLED Mode",
    Value = false,
    Callback = function(v)
        Amoled.apply(v and true or false)
        if v and _G.MT_ActivateFx then _G.MT_ActivateFx(Color3.new(0,0,0)) end
    end,
})
ConfigTab:Toggle({
    Title = "UI Blur",
    Value = true,
    Callback = function(v)
        STATE.uiBlur = v and true or false
        pcall(function()
            local Lighting = game:GetService("Lighting")
            local blur = Lighting:FindFirstChild("MT_UIBlur")
            if not blur then
                blur = Instance.new("BlurEffect")
                blur.Name = "MT_UIBlur"
                blur.Parent = Lighting
            end
            blur.Enabled = true
            game:GetService("TweenService"):Create(blur, TweenInfo.new(0.25), {
                Size = v and 16 or 0
            }):Play()
        end)
        if _G.MT_ActivateFx then _G.MT_ActivateFx(NEON_CYAN) end
    end,
})
ConfigTab:Toggle({
    Title = "Neon Aura",
    Value = true,
    Callback = function(v)
        STATE.neonAura = v and true or false
        pcall(function()
            local root = Window and Window.Root
            if typeof(root) == "Instance" then
                local stroke = root:FindFirstChild("MT_NeonStroke")
                if stroke then stroke.Enabled = v and true or false end
            end
        end)
        if _G.MT_ActivateFx then _G.MT_ActivateFx(NEON_PURPLE) end
    end,
})
ConfigTab:Toggle({
    Title = "Activation Flash",
    Value = true,
    Callback = function(v)
        STATE.activateFx = v and true or false
    end,
})
ConfigTab:Button({
    Title = "Cycle UI Accent Color",
    Callback = function()
        local order = { "Cyan", "Blue", "Purple", "Magenta" }
        local cur = STATE.uiAccent or "Cyan"
        local idx = 1
        for i, n in ipairs(order) do if n == cur then idx = i break end end
        idx = idx % #order + 1
        STATE.uiAccent = order[idx]
        local c = NEON_CYAN
        if STATE.uiAccent == "Blue" then c = NEON_BLUE
        elseif STATE.uiAccent == "Purple" then c = NEON_PURPLE
        elseif STATE.uiAccent == "Magenta" then c = NEON_MAGENTA end
        notify("Config", "Accent: " .. STATE.uiAccent, 2)
        if _G.MT_ActivateFx then _G.MT_ActivateFx(c) end
    end,
})

ConfigTab:Section({ Title = "Keybinds (PC)", TextSize = 14 })
ConfigTab:Toggle({
    Title = "Enable Keybinds",
    Desc = "PC only. Mobile uses floating buttons + menu toggles.",
    Value = true,
    Callback = function(v) STATE.keybindsOn = v and true or false end,
})
ConfigTab:Section({
    Title = "Click a button, then press a key. Esc cancels.",
    TextSize = 11,
})
ConfigTab:Button({
    Title = "Bind: Speed",
    Callback = function()
        BindCapture.active = "Speed"
        local cur = KEYBINDS.Speed
        notify("Keybind", "Press a key for Speed (now: " .. (cur and cur.Name or "None") .. ") | Esc = cancel", 4)
    end,
})
ConfigTab:Button({
    Title = "Bind: Air Strafe",
    Callback = function()
        BindCapture.active = "AirStrafe"
        local cur = KEYBINDS.AirStrafe
        notify("Keybind", "Press a key for Air Strafe (now: " .. (cur and cur.Name or "None") .. ") | Esc = cancel", 4)
    end,
})
ConfigTab:Button({
    Title = "Bind: Fly",
    Callback = function()
        BindCapture.active = "Fly"
        local cur = KEYBINDS.Fly
        notify("Keybind", "Press a key for Fly (now: " .. (cur and cur.Name or "None") .. ") | Esc = cancel", 4)
    end,
})
ConfigTab:Button({
    Title = "Bind: Auto Jump",
    Callback = function()
        BindCapture.active = "AutoJump"
        local cur = KEYBINDS.AutoJump
        notify("Keybind", "Press a key for Auto Jump (now: " .. (cur and cur.Name or "None") .. ") | Esc = cancel", 4)
    end,
})
ConfigTab:Button({
    Title = "Bind: Bounce",
    Callback = function()
        BindCapture.active = "Bounce"
        local cur = KEYBINDS.Bounce
        notify("Keybind", "Press a key for Bounce (now: " .. (cur and cur.Name or "None") .. ") | Esc = cancel", 4)
    end,
})
ConfigTab:Button({
    Title = "Bind: Auto Crouch",
    Callback = function()
        BindCapture.active = "Crouch"
        local cur = KEYBINDS.Crouch
        notify("Keybind", "Press a key for Auto Crouch (now: " .. (cur and cur.Name or "None") .. ") | Esc = cancel", 4)
    end,
})
ConfigTab:Button({
    Title = "Bind: Edge Trimp",
    Callback = function()
        BindCapture.active = "EdgeTrimp"
        local cur = KEYBINDS.EdgeTrimp
        notify("Keybind", "Press a key for Edge Trimp (now: " .. (cur and cur.Name or "None") .. ") | Esc = cancel", 4)
    end,
})
ConfigTab:Button({
    Title = "Bind: Lag Freeze",
    Callback = function()
        BindCapture.active = "LagFreeze"
        local cur = KEYBINDS.LagFreeze
        notify("Keybind", "Press a key for Lag Freeze (now: " .. (cur and cur.Name or "None") .. ") | Esc = cancel", 4)
    end,
})
ConfigTab:Button({
    Title = "Bind: ESP",
    Callback = function()
        BindCapture.active = "ESP"
        local cur = KEYBINDS.ESP
        notify("Keybind", "Press a key for ESP (now: " .. (cur and cur.Name or "None") .. ") | Esc = cancel", 4)
    end,
})
ConfigTab:Button({
    Title = "Bind: Spin",
    Callback = function()
        BindCapture.active = "Spin"
        local cur = KEYBINDS.Spin
        notify("Keybind", "Press a key for Spin (now: " .. (cur and cur.Name or "None") .. ") | Esc = cancel", 4)
    end,
})
ConfigTab:Button({
    Title = "Bind: Fling",
    Callback = function()
        BindCapture.active = "Fling"
        local cur = KEYBINDS.Fling
        notify("Keybind", "Press a key for Fling (now: " .. (cur and cur.Name or "None") .. ") | Esc = cancel", 4)
    end,
})
ConfigTab:Button({
    Title = "Bind: Farm",
    Callback = function()
        BindCapture.active = "Farm"
        local cur = KEYBINDS.Farm
        notify("Keybind", "Press a key for Farm (now: " .. (cur and cur.Name or "None") .. ") | Esc = cancel", 4)
    end,
})
ConfigTab:Button({
    Title = "Bind: Emote Macro",
    Callback = function()
        BindCapture.active = "EmoteMacro"
        local cur = KEYBINDS.EmoteMacro
        notify("Keybind", "Press a key for Emote Macro (now: " .. (cur and cur.Name or "None") .. ") | Esc = cancel", 4)
    end,
})
ConfigTab:Button({
    Title = "Reset Keybinds to Default",
    Callback = function()
        KEYBINDS.Speed = Enum.KeyCode.V
        KEYBINDS.AirStrafe = Enum.KeyCode.B
        KEYBINDS.Fly = Enum.KeyCode.F
        KEYBINDS.AutoJump = Enum.KeyCode.J
        KEYBINDS.Bounce = Enum.KeyCode.G
        KEYBINDS.Crouch = Enum.KeyCode.C
        KEYBINDS.EdgeTrimp = Enum.KeyCode.T
        KEYBINDS.LagFreeze = Enum.KeyCode.X
        KEYBINDS.ESP = Enum.KeyCode.H
        KEYBINDS.Spin = Enum.KeyCode.Y
        KEYBINDS.Fling = Enum.KeyCode.U
        KEYBINDS.Farm = Enum.KeyCode.K
        KEYBINDS.EmoteMacro = Enum.KeyCode.E
        BindCapture.active = nil
        notify("Keybind", "Defaults restored", 3)
    end,
})
ConfigTab:Section({ Title = "Skybox", TextSize = 14 })
ConfigTab:Toggle({
    Title = "Custom Skybox",
    Value = false,
    Callback = function(v)
        Skybox.apply(v and true or false)
        if _G.MT_ActivateFx then _G.MT_ActivateFx(NEON_MAGENTA) end
    end,
})
ConfigTab:Section({ Title = "Floating Buttons", TextSize = 14 })
ConfigTab:Section({ Title = "Tip: button sizes are on each feature tab. ON = full neon fill.", TextSize = 12 })

CheatsTab:Section({ Title = "Spin", TextSize = 14 })
CheatsTab:Toggle({
    Title = "Spin",
    Value = false,
    Callback = function(v) Cheats.setSpin(v and true or false) end,
})
CheatsTab:Slider({
    Title = "Spin Speed",
    Step = 1,
    Value = { Min = 1, Max = 40, Default = 12 },
    Callback = function(v) STATE.spinSpeed = v end,
})

CheatsTab:Section({ Title = "Fling", TextSize = 14 })
CheatsTab:Toggle({
    Title = "Fling on Touch",
    Value = false,
    Callback = function(v) Cheats.setFling(v and true or false) end,
})
CheatsTab:Slider({
    Title = "Fling Force",
    Step = 10,
    Value = { Min = 40, Max = 500, Default = 180 },
    Callback = function(v) STATE.flingForce = v end,
})

CheatsTab:Section({ Title = "Map Votes", TextSize = 14 })
CheatsTab:Section({ Title = "Votes: client-side attempt only (server may ignore)", TextSize = 12 })
CheatsTab:Input({
    Title = "Map Name",
    Default = "",
    Placeholder = "Exact map name",
    Callback = function(v) STATE.voteMap = tostring(v or "") end,
})
CheatsTab:Slider({
    Title = "Bot Vote Count",
    Step = 1,
    Value = { Min = 1, Max = 30, Default = 5 },
    Callback = function(v) STATE.voteCount = v end,
})
CheatsTab:Button({
    Title = "Cast Bot Votes",
    Callback = function() Cheats.castVoteBots() end,
})

UtilTab:Section({ Title = "Helpers", TextSize = 14 })
UtilTab:Toggle({
    Title = "Invis Wall Remover", Value = false,
    Callback = function(v)
        STATE.wallsOn = v and true or false
        if STATE.wallsOn then
            task.spawn(function()
                local n = 0
                for _, inst in ipairs(Workspace:GetDescendants()) do
                    n = n + 1
                    if n % 3000 == 0 then task.wait() end
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
                            n = n + 1
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
                    n = n + 1
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
                n = n + 1
            end
        end
        WindUI:Notify({ Title = "Walls", Content = "Cleared " .. n, Duration = 3 })
    end,
})

UtilTab:Section({ Title = "Server attempts", TextSize = 14 })

UtilTab:Button({
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

UtilTab:Space()

UtilTab:Section({ Title = "Emote Macro", TextSize = 14 })
UtilTab:Section({ Title = "Set the sector slot (1–10), then enable the floating button.", TextSize = 12 })
UtilTab:Input({
    Title = "Sector Number",
    Default = "1",
    Placeholder = "1 to 10",
    Callback = function(v)
        local n = math.clamp(math.floor(tonumber(v) or 1), 1, 10)
        Macro.setSlot(n)
        notify("Emote Macro", "Slot set to " .. n, 2)
    end,
})
UtilTab:Toggle({
    Title = "Show Emote Macro Button",
    Desc = "Floating button: tap to play that slot. If already emoting, tapping fires the mobile Emote button instead.",
    Value = false,
    Callback = function(v)
        if Macro.btn then Macro.btn:SetEnabled(v) end
        notify("Emote Macro", v and "Button visible" or "Button hidden", 2)
    end,
})
UtilTab:Slider({
    Title = "Emote Macro Button Size (%)",
    Step = 5,
    Value = { Min = 50, Max = 250, Default = 100 },
    Callback = function(v)
        if Macro.btn then Macro.btn:SetSizePercent(v) end
    end,
})

VisualTab:Section({ Title = "Cosmetic Unlocker", TextSize = 14 })
VisualTab:Toggle({
    Title = "Unlock All Cosmetics",
    Value = false,
    Callback = function(v)
        if v then CosUnlock.start() else CosUnlock.stop() end
    end,
})

VisualTab:Space()

VisualTab:Section({ Title = "Player ESP", TextSize = 14 })
VisualTab:Toggle({
    Title = "ESP",
    Value = false,
    Callback = function(v) Cheats.setEsp(v and true or false) end,
})
VisualTab:Toggle({
    Title = "ESP Fill (Chams)",
    Value = true,
    Callback = function(v)
        STATE.espFill = v and true or false
        Cheats.refreshEspColors()
    end,
})
VisualTab:Toggle({
    Title = "ESP Boxes / Highlight",
    Value = true,
    Callback = function(v)
        STATE.espBox = v and true or false
        Cheats.refreshEspColors()
    end,
})
VisualTab:Toggle({
    Title = "ESP Names",
    Value = true,
    Callback = function(v)
        STATE.espName = v and true or false
        Cheats.refreshEspColors()
    end,
})
VisualTab:Toggle({
    Title = "ESP Distance",
    Value = true,
    Callback = function(v)
        STATE.espDist = v and true or false
        Cheats.refreshEspColors()
    end,
})
VisualTab:Toggle({
    Title = "ESP Line (Tracers)",
    Value = true,
    Callback = function(v)
        STATE.espLine = v and true or false
    end,
})
VisualTab:Slider({
    Title = "ESP Max Distance",
    Step = 50,
    Value = { Min = 200, Max = 5000, Default = 2000 },
    Callback = function(v) STATE.espMaxDist = v end,
})
VisualTab:Section({ Title = "ESP Color Changer", TextSize = 14 })
VisualTab:Button({
    Title = "ESP Color: Cyan",
    Callback = function()
        STATE.espColor = Color3.fromRGB(0, 229, 255)
        Cheats.refreshEspColors()
        notify("ESP", "Color: Cyan", 2)
        if _G.MT_ActivateFx then _G.MT_ActivateFx(STATE.espColor) end
    end,
})
VisualTab:Button({
    Title = "ESP Color: Red",
    Callback = function()
        STATE.espColor = Color3.fromRGB(255, 50, 80)
        Cheats.refreshEspColors()
        notify("ESP", "Color: Red", 2)
        if _G.MT_ActivateFx then _G.MT_ActivateFx(STATE.espColor) end
    end,
})
VisualTab:Button({
    Title = "ESP Color: Purple",
    Callback = function()
        STATE.espColor = Color3.fromRGB(180, 70, 255)
        Cheats.refreshEspColors()
        notify("ESP", "Color: Purple", 2)
        if _G.MT_ActivateFx then _G.MT_ActivateFx(STATE.espColor) end
    end,
})
VisualTab:Button({
    Title = "ESP Color: Green",
    Callback = function()
        STATE.espColor = Color3.fromRGB(80, 255, 140)
        Cheats.refreshEspColors()
        notify("ESP", "Color: Green", 2)
        if _G.MT_ActivateFx then _G.MT_ActivateFx(STATE.espColor) end
    end,
})
VisualTab:Button({
    Title = "ESP Color: Magenta",
    Callback = function()
        STATE.espColor = Color3.fromRGB(220, 40, 255)
        Cheats.refreshEspColors()
        notify("ESP", "Color: Magenta", 2)
        if _G.MT_ActivateFx then _G.MT_ActivateFx(STATE.espColor) end
    end,
})
VisualTab:Button({
    Title = "ESP Color: White",
    Callback = function()
        STATE.espColor = Color3.fromRGB(255, 255, 255)
        Cheats.refreshEspColors()
        notify("ESP", "Color: White", 2)
        if _G.MT_ActivateFx then _G.MT_ActivateFx(STATE.espColor) end
    end,
})
VisualTab:Button({
    Title = "Outline: White",
    Callback = function()
        STATE.espOutline = Color3.fromRGB(255, 255, 255)
        Cheats.refreshEspColors()
        notify("ESP", "Outline: White", 2)
    end,
})
VisualTab:Button({
    Title = "Outline: Black",
    Callback = function()
        STATE.espOutline = Color3.fromRGB(0, 0, 0)
        Cheats.refreshEspColors()
        notify("ESP", "Outline: Black", 2)
    end,
})


----------------------------------------------------------------
----------------------------------------------------------------
local function keyName(k)
    if typeof(k) == "EnumItem" then return k.Name end
    return tostring(k)
end

local function fireToggle(name, setFn, getOn)
    local on = not getOn()
    setFn(on)
    notify(name, on and "ON" or "OFF", 2)
end

bind(UIS.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local code = input.KeyCode

    if BindCapture.active then
        local feat = BindCapture.active
        BindCapture.active = nil
        if code == Enum.KeyCode.Escape then
            notify("Keybind", KEYBIND_LABELS[feat] or feat .. " cancelled", 2)
            return
        end
        for name, k in pairs(KEYBINDS) do
            if name ~= feat and k == code then
                KEYBINDS[name] = nil
            end
        end
        KEYBINDS[feat] = code
        notify("Keybind", (KEYBIND_LABELS[feat] or feat) .. " = " .. code.Name, 3)
        return
    end

    if not STATE.keybindsOn then return end
    if gameProcessed then return end
    local focused = UIS:GetFocusedTextBox()
    if focused then return end

    if code == KEYBINDS.Speed then
        STATE.speedOn = not STATE.speedOn
        if not Engine.ok then
            local h = hum()
            if h then h.WalkSpeed = STATE.speedOn and STATE.speed or Engine.defaultWS end
        end
        notify("Speed", STATE.speedOn and ("ON " .. tostring(STATE.speed)) or "OFF", 2)
    elseif code == KEYBINDS.AirStrafe then
        STATE.airOn = not STATE.airOn
        notify("Air Strafe", STATE.airOn and "ON" or "OFF", 2)
    elseif code == KEYBINDS.Fly then
        STATE.flyOn = not STATE.flyOn
        local h = hum()
        if h then h.PlatformStand = STATE.flyOn and true or false end
        notify("Fly", STATE.flyOn and "ON" or "OFF", 2)
    elseif code == KEYBINDS.AutoJump then
        STATE.autoJump = not STATE.autoJump
        if ajBtn then ajBtn:SetActive(STATE.autoJump) end
        notify("Auto Jump", STATE.autoJump and "ON" or "OFF", 2)
    elseif code == KEYBINDS.Bounce then
        STATE.bounceOn = not STATE.bounceOn
        if bounceBtn then bounceBtn:SetActive(STATE.bounceOn) end
        notify("Bounce", STATE.bounceOn and "ON" or "OFF", 2)
    elseif code == KEYBINDS.Crouch then
        STATE.crouchOn = not STATE.crouchOn
        if Crouch and Crouch.btnObj then Crouch.btnObj:SetActive(STATE.crouchOn) end
        notify("Auto Crouch", STATE.crouchOn and "ON" or "OFF", 2)
    elseif code == KEYBINDS.EdgeTrimp then
        STATE.edgeTrimpOn = not STATE.edgeTrimpOn
        notify("Edge Trimp", STATE.edgeTrimpOn and "ON" or "OFF", 2)
    elseif code == KEYBINDS.LagFreeze then
        if Lag and Lag.fire then Lag.fire() end
    elseif code == KEYBINDS.ESP then
        if Cheats and Cheats.setEsp then Cheats.setEsp(not STATE.espOn) end
        notify("ESP", STATE.espOn and "ON" or "OFF", 2)
    elseif code == KEYBINDS.Spin then
        if Cheats and Cheats.setSpin then Cheats.setSpin(not STATE.spinOn) end
        notify("Spin", STATE.spinOn and "ON" or "OFF", 2)
    elseif code == KEYBINDS.Fling then
        if Cheats and Cheats.setFling then Cheats.setFling(not STATE.flingOn) end
        notify("Fling", STATE.flingOn and "ON" or "OFF", 2)
    elseif code == KEYBINDS.Farm then
        STATE.farmOn = not STATE.farmOn
        if STATE.farmOn then task.spawn(Farm.start) else Farm.stop() end
        notify("Farm", STATE.farmOn and "ON" or "OFF", 2)
    elseif code == KEYBINDS.EmoteMacro then
        if Macro and Macro.toggle then Macro.toggle() end
    end
end))

bind(RunService.Heartbeat:Connect(function(dt)
    local h = hum()
    local root = hrp()
    if not h or not root then return end

    stepSpeedAir(h, root, dt)
    stepAutoJump(h, root, dt)
    stepDirectionalJump(h, root, dt)
    stepEdgeTrimp(h, root, dt)
    stepFly(h, root, dt)
    stepWalls(h, root, dt)
    stepBounce(h, root, dt)
    Crouch.step(dt)
    Macro.step(dt)
    Farm.step(root)
end))

bind(lp.CharacterAdded:Connect(function()
    task.wait(0.2)
    Engine.onSpawn()
    Macro.reset()
    edgeRayParams.FilterDescendantsInstances = { lp.Character }
    edgeLastTrimp = -999
    if STATE.flyOn then
        local h = hum()
        if h then h.PlatformStand = true end
    end
    if STATE.speedOn and not Engine.ok then
        local h = hum()
        if h then h.WalkSpeed = STATE.speed end
    end
    if STATE.farmOn and Farm.plate then
        task.wait(1)
        farmTeleport()
    end
end))

getgenv().MT_Unload = function()
    STATE.farmOn, STATE.antiBlock, STATE.crouchOn = false, false, false
    pcall(Engine.shutdown)
    pcall(Farm.stop)
    pcall(function() if Macro.active then Macro.stop() end end)
    Anti.hookLive = false
    pcall(function() if Lag.holding then Lag.hold(false) else Lag.release() end end)
    pcall(function() Skybox.apply(false) end)
    pcall(function() Amoled.apply(false) end)
    pcall(Cheats.cleanup)
    pcall(function()
        lp:SetAttribute("VipStrafe", nil)
        lp:SetAttribute("VipSpeed", nil)
        lp:SetAttribute("VipJump", nil)
    end)
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    local root = hrp()
    if root then
        for _, n in ipairs({ "MT_FrontalJump", "MT_BackJump" }) do
            local bv = root:FindFirstChild(n)
            if bv then bv:Destroy() end
        end
    end
    for _, b in ipairs({ Lag.btn, ajBtn, bounceBtn, Crouch.btnObj, Macro.btn }) do
        pcall(function() if b and b.Gui then b.Gui:Destroy() end end)
    end
    pcall(function() if Window and Window.Destroy then Window:Destroy() end end)
    getgenv().MT_Unload = nil
end

if isMobile() then
    notify("Memetrash", "Mobile: use menu toggles + floating buttons", 4)
else
    notify("Memetrash", "Loaded | Keybinds on (Config tab)", 3)
end
