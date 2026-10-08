-- lang: Luau, file: hyperion_chat.lua, target: Roblox Executor (any)
-- discord-style in-script chat via Firebase Realtime Database REST
-- no ServerScript, no RemoteEvents — pure HTTP polling between clients
--
-- SETUP (one-time):
--   1. console.firebase.google.com → create project → Realtime Database → create database
--   2. Rules tab → paste: { "rules": { ".read": true, ".write": true } }
--   3. Copy your database URL and paste it into FIREBASE_URL below
--      format: https://YOUR-PROJECT-ID-default-rtdb.firebaseio.com

local FIREBASE_URL = "https://hyperion-chat-36da6-default-rtdb.firebaseio.com/hyperion-chat"
local POLL_RATE    = 3   -- seconds between message polls
local MAX_MESSAGES = 80  -- max messages held in the scroll frame

-- ──────────────────────────────────────────────────────────────────────────────
-- SERVICES
-- ──────────────────────────────────────────────────────────────────────────────
local Players    = game:GetService("Players")
local HttpSvc    = game:GetService("HttpService")
local LP         = Players.LocalPlayer
local PlayerGui  = LP:WaitForChild("PlayerGui")

-- ──────────────────────────────────────────────────────────────────────────────
-- HTTP WRAPPER
-- ──────────────────────────────────────────────────────────────────────────────
local function httpReq(method, url, body)
    local fn = (syn  and type(syn.request)       == "function" and syn.request)
            or (type(http_request)               == "function" and http_request)
            or (type(request)                    == "function" and request)
            or (fluxus and type(fluxus.request)  == "function" and fluxus.request)
    if not fn then warn("[HyperionChat] no http api found") return nil end
    local cfg = {
        Url     = url,
        Method  = method,
        Headers = { ["Content-Type"] = "application/json" },
    }
    if body then cfg.Body = HttpSvc:JSONEncode(body) end
    local ok, res = pcall(fn, cfg)
    return ok and res or nil
end

local function fbGet(path)
    local res = httpReq("GET", FIREBASE_URL .. path .. ".json", nil)
    if not res or res.StatusCode ~= 200 or not res.Body or res.Body == "null" then return nil end
    local ok, data = pcall(HttpSvc.JSONDecode, HttpSvc, res.Body)
    return ok and data or nil
end

local function fbPush(path, data)
    return httpReq("POST", FIREBASE_URL .. path .. ".json", data)
end

-- ──────────────────────────────────────────────────────────────────────────────
-- HELPERS
-- ──────────────────────────────────────────────────────────────────────────────
local NAME_COLORS = {
    Color3.fromRGB(255, 114, 114), -- red
    Color3.fromRGB(255, 178,  88), -- orange
    Color3.fromRGB(255, 220, 100), -- yellow
    Color3.fromRGB( 87, 219, 146), -- green
    Color3.fromRGB( 88, 166, 255), -- blue
    Color3.fromRGB(171, 115, 255), -- purple
    Color3.fromRGB(255, 107, 185), -- pink
    Color3.fromRGB( 92, 225, 230), -- cyan
}

local function nameColor(name)
    local h = 0
    for i = 1, #name do h = h + string.byte(name, i) end
    return NAME_COLORS[(h % #NAME_COLORS) + 1]
end

local function toHex(c)
    return string.format("#%02x%02x%02x",
        math.clamp(math.floor(c.R * 255), 0, 255),
        math.clamp(math.floor(c.G * 255), 0, 255),
        math.clamp(math.floor(c.B * 255), 0, 255))
end

local function timestamp()
    -- os.time() returns UTC seconds; format as HH:MM
    local t = os.time()
    return string.format("Today at %02d:%02d", math.floor(t / 3600) % 24, math.floor(t / 60) % 60)
end

-- ──────────────────────────────────────────────────────────────────────────────
-- DESTROY OLD INSTANCE
-- ──────────────────────────────────────────────────────────────────────────────
local old = PlayerGui:FindFirstChild("HyperionChat")
if old then old:Destroy() end

-- ──────────────────────────────────────────────────────────────────────────────
-- ROOT GUI
-- ──────────────────────────────────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name            = "HyperionChat"
sg.ResetOnSpawn    = false
sg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
sg.IgnoreGuiInset  = true
sg.Parent          = PlayerGui

-- ── MAIN WINDOW ──
local W = 380
local H = 500

local main = Instance.new("Frame")
main.Name                  = "Window"
main.Size                  = UDim2.fromOffset(W, H)
main.Position              = UDim2.new(0.5, -W/2, 0.5, -H/2)
main.BackgroundColor3      = Color3.fromRGB(54, 57, 63)
main.BorderSizePixel       = 0
main.Active                = true
main.Draggable             = true
main.ClipsDescendants      = true
main.Parent                = sg
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

-- ── TOP BAR ──
local topH = 48

local topBar = Instance.new("Frame")
topBar.Name              = "TopBar"
topBar.Size              = UDim2.new(1, 0, 0, topH)
topBar.BackgroundColor3  = Color3.fromRGB(47, 49, 54)
topBar.BorderSizePixel   = 0
topBar.ZIndex            = 3
topBar.Parent            = main

-- pill for drag
local dragPill = Instance.new("TextLabel")
dragPill.Size                = UDim2.fromOffset(120, 4)
dragPill.Position            = UDim2.new(0.5, -60, 1, -1)
dragPill.BackgroundColor3    = Color3.fromRGB(80, 83, 90)
dragPill.BorderSizePixel     = 0
dragPill.Text                = ""
dragPill.ZIndex              = 4
dragPill.Parent              = topBar
Instance.new("UICorner", dragPill).CornerRadius = UDim.new(1, 0)

-- icon
local icon = Instance.new("TextLabel")
icon.Size               = UDim2.fromOffset(32, 32)
icon.Position           = UDim2.new(0, 12, 0.5, -16)
icon.BackgroundColor3   = Color3.fromRGB(88, 101, 242)
icon.TextColor3         = Color3.fromRGB(255, 255, 255)
icon.Text               = "#"
icon.Font               = Enum.Font.GothamBold
icon.TextSize           = 16
icon.BorderSizePixel    = 0
icon.ZIndex             = 4
icon.Parent             = topBar
Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 6)

-- channel name
local chanLabel = Instance.new("TextLabel")
chanLabel.Size              = UDim2.new(1, -130, 1, 0)
chanLabel.Position          = UDim2.fromOffset(52, 0)
chanLabel.BackgroundTransparency = 1
chanLabel.TextColor3        = Color3.fromRGB(255, 255, 255)
chanLabel.Text              = "hyperion-chat"
chanLabel.Font              = Enum.Font.GothamBold
chanLabel.TextSize          = 15
chanLabel.TextXAlignment    = Enum.TextXAlignment.Left
chanLabel.ZIndex            = 4
chanLabel.Parent            = topBar

-- minimize button
local minBtn = Instance.new("TextButton")
minBtn.Size             = UDim2.fromOffset(28, 28)
minBtn.Position         = UDim2.new(1, -68, 0.5, -14)
minBtn.BackgroundColor3 = Color3.fromRGB(64, 68, 75)
minBtn.TextColor3       = Color3.fromRGB(185, 187, 190)
minBtn.Text             = "–"
minBtn.Font             = Enum.Font.GothamBold
minBtn.TextSize         = 14
minBtn.BorderSizePixel  = 0
minBtn.ZIndex           = 4
minBtn.Parent           = topBar
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 4)

-- close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size             = UDim2.fromOffset(28, 28)
closeBtn.Position         = UDim2.new(1, -34, 0.5, -14)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 55, 55)
closeBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
closeBtn.Text             = "✕"
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.TextSize         = 13
closeBtn.BorderSizePixel  = 0
closeBtn.ZIndex           = 4
closeBtn.Parent           = topBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)

-- ── MESSAGE AREA ──
local inputH = 58

local msgScroll = Instance.new("ScrollingFrame")
msgScroll.Name                  = "Messages"
msgScroll.Size                  = UDim2.new(1, 0, 1, -(topH + inputH + 1))
msgScroll.Position              = UDim2.fromOffset(0, topH)
msgScroll.BackgroundColor3      = Color3.fromRGB(54, 57, 63)
msgScroll.BorderSizePixel       = 0
msgScroll.ScrollBarThickness    = 4
msgScroll.ScrollBarImageColor3  = Color3.fromRGB(32, 34, 37)
msgScroll.CanvasSize            = UDim2.new(0, 0, 0, 0)
msgScroll.AutomaticCanvasSize   = Enum.AutomaticSize.Y
msgScroll.ScrollingDirection    = Enum.ScrollingDirection.Y
msgScroll.Parent                = main

local msgLayout = Instance.new("UIListLayout")
msgLayout.SortOrder     = Enum.SortOrder.LayoutOrder
msgLayout.Padding       = UDim.new(0, 0)
msgLayout.Parent        = msgScroll

local msgPad = Instance.new("UIPadding")
msgPad.PaddingLeft   = UDim.new(0, 14)
msgPad.PaddingRight  = UDim.new(0, 14)
msgPad.PaddingTop    = UDim.new(0, 12)
msgPad.PaddingBottom = UDim.new(0, 8)
msgPad.Parent        = msgScroll

-- ── DIVIDER ──
local divider = Instance.new("Frame")
divider.Size             = UDim2.new(1, 0, 0, 1)
divider.Position         = UDim2.new(0, 0, 1, -(inputH + 1))
divider.BackgroundColor3 = Color3.fromRGB(32, 34, 37)
divider.BorderSizePixel  = 0
divider.Parent           = main

-- ── INPUT AREA ──
local inputArea = Instance.new("Frame")
inputArea.Name             = "InputArea"
inputArea.Size             = UDim2.new(1, 0, 0, inputH)
inputArea.Position         = UDim2.new(0, 0, 1, -inputH)
inputArea.BackgroundColor3 = Color3.fromRGB(47, 49, 54)
inputArea.BorderSizePixel  = 0
inputArea.ZIndex           = 2
inputArea.Parent           = main

local inputPad = Instance.new("UIPadding")
inputPad.PaddingLeft   = UDim.new(0, 12)
inputPad.PaddingRight  = UDim.new(0, 12)
inputPad.PaddingTop    = UDim.new(0, 11)
inputPad.PaddingBottom = UDim.new(0, 11)
inputPad.Parent        = inputArea

local inputBox = Instance.new("Frame")
inputBox.Size            = UDim2.new(1, -50, 1, 0)
inputBox.BackgroundColor3 = Color3.fromRGB(64, 68, 75)
inputBox.BorderSizePixel = 0
inputBox.ZIndex          = 3
inputBox.Parent          = inputArea
Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 6)

local inputPad2 = Instance.new("UIPadding")
inputPad2.PaddingLeft  = UDim.new(0, 10)
inputPad2.PaddingRight = UDim.new(0, 10)
inputPad2.Parent       = inputBox

local textInput = Instance.new("TextBox")
textInput.Size                = UDim2.new(1, 0, 1, 0)
textInput.BackgroundTransparency = 1
textInput.TextColor3          = Color3.fromRGB(220, 221, 222)
textInput.PlaceholderText     = "Message #hyperion-chat"
textInput.PlaceholderColor3   = Color3.fromRGB(114, 118, 125)
textInput.Font                = Enum.Font.Gotham
textInput.TextSize            = 13
textInput.TextXAlignment      = Enum.TextXAlignment.Left
textInput.ClearTextOnFocus    = false
textInput.MultiLine           = false
textInput.Text                = ""
textInput.ZIndex              = 4
textInput.Parent              = inputBox

local sendBtn = Instance.new("TextButton")
sendBtn.Size             = UDim2.fromOffset(36, 36)
sendBtn.Position         = UDim2.new(1, -36, 0.5, -18)
sendBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
sendBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
sendBtn.Text             = "↑"
sendBtn.Font             = Enum.Font.GothamBold
sendBtn.TextSize         = 18
sendBtn.BorderSizePixel  = 0
sendBtn.ZIndex           = 3
sendBtn.Parent           = inputArea
Instance.new("UICorner", sendBtn).CornerRadius = UDim.new(0, 6)

-- ──────────────────────────────────────────────────────────────────────────────
-- MESSAGE RENDERING
-- ──────────────────────────────────────────────────────────────────────────────
local msgOrder   = 0
local seenKeys   = {}
local rowCount   = 0
local rowObjects = {}  -- track for MAX_MESSAGES trim

local function scrollToBottom()
    task.defer(function()
        msgScroll.CanvasPosition = Vector2.new(0, math.huge)
    end)
end

local function renderMessage(data)
    if type(data) ~= "table" or not data.msg or not data.user then return end

    msgOrder = msgOrder + 1
    rowCount = rowCount + 1

    local col = nameColor(data.user)
    local hex = toHex(col)

    -- outer row
    local row = Instance.new("Frame")
    row.Name               = "row_" .. msgOrder
    row.Size               = UDim2.new(1, 0, 0, 0)
    row.AutomaticSize      = Enum.AutomaticSize.Y
    row.BackgroundTransparency = 1
    row.LayoutOrder        = msgOrder
    row.Parent             = msgScroll
    table.insert(rowObjects, row)

    -- hover tint (subtle)
    local hover = Instance.new("Frame")
    hover.Size             = UDim2.new(1, 0, 1, 0)
    hover.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    hover.BackgroundTransparency = 1
    hover.BorderSizePixel  = 0
    hover.ZIndex           = row.ZIndex
    hover.Parent           = row

    -- padding inside row
    local rowPad = Instance.new("UIPadding")
    rowPad.PaddingTop    = UDim.new(0, 4)
    rowPad.PaddingBottom = UDim.new(0, 4)
    rowPad.Parent        = row

    -- avatar circle
    local avatar = Instance.new("Frame")
    avatar.Size            = UDim2.fromOffset(32, 32)
    avatar.Position        = UDim2.fromOffset(0, 4)
    avatar.BackgroundColor3 = col
    avatar.BorderSizePixel = 0
    avatar.Parent          = row
    Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)

    local avatarLetter = Instance.new("TextLabel")
    avatarLetter.Size              = UDim2.new(1, 0, 1, 0)
    avatarLetter.BackgroundTransparency = 1
    avatarLetter.TextColor3        = Color3.fromRGB(255, 255, 255)
    avatarLetter.Text              = string.upper(string.sub(data.user, 1, 1))
    avatarLetter.Font              = Enum.Font.GothamBold
    avatarLetter.TextSize          = 14
    avatarLetter.Parent            = avatar

    -- content frame (right of avatar)
    local contentFrame = Instance.new("Frame")
    contentFrame.Size          = UDim2.new(1, -44, 0, 0)
    contentFrame.Position      = UDim2.fromOffset(44, 0)
    contentFrame.AutomaticSize = Enum.AutomaticSize.Y
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent        = row

    -- username + timestamp
    local header = Instance.new("TextLabel")
    header.Size              = UDim2.new(1, 0, 0, 18)
    header.BackgroundTransparency = 1
    header.RichText          = true
    header.TextXAlignment    = Enum.TextXAlignment.Left
    header.Text              = string.format(
        '<font color="%s"><b>%s</b></font>  <font color="#72767d" size="11"><i>%s</i></font>',
        hex, data.user, data.ts or "")
    header.Font              = Enum.Font.Gotham
    header.TextSize          = 13
    header.Parent            = contentFrame

    -- message body
    local body = Instance.new("TextLabel")
    body.Size              = UDim2.new(1, 0, 0, 0)
    body.Position          = UDim2.fromOffset(0, 20)
    body.AutomaticSize     = Enum.AutomaticSize.Y
    body.BackgroundTransparency = 1
    body.TextColor3        = Color3.fromRGB(220, 221, 222)
    body.TextXAlignment    = Enum.TextXAlignment.Left
    body.TextWrapped       = true
    body.RichText          = false
    body.Font              = Enum.Font.Gotham
    body.TextSize          = 13
    body.Text              = data.msg
    body.Parent            = contentFrame

    -- trim oldest messages past MAX_MESSAGES
    if rowCount > MAX_MESSAGES then
        local oldest = table.remove(rowObjects, 1)
        if oldest then oldest:Destroy() end
        rowCount = rowCount - 1
    end

    scrollToBottom()
end

-- ──────────────────────────────────────────────────────────────────────────────
-- FIREBASE LOAD + POLL
-- ──────────────────────────────────────────────────────────────────────────────
local function processData(data)
    if type(data) ~= "table" then return end
    local batch = {}
    for k, v in pairs(data) do
        if type(v) == "table" and not seenKeys[k] then
            seenKeys[k] = true
            table.insert(batch, { key = k, data = v })
        end
    end
    table.sort(batch, function(a, b) return a.key < b.key end)
    for _, entry in ipairs(batch) do
        renderMessage(entry.data)
    end
end

-- initial load
task.spawn(function()
    processData(fbGet("/messages"))
end)

-- poll loop
task.spawn(function()
    while sg.Parent do
        task.wait(POLL_RATE)
        processData(fbGet("/messages"))
    end
end)

-- ──────────────────────────────────────────────────────────────────────────────
-- SEND
-- ──────────────────────────────────────────────────────────────────────────────
local sending = false

local function doSend()
    if sending then return end
    local txt = textInput.Text:match("^%s*(.-)%s*$")
    if txt == "" then return end
    textInput.Text = ""
    sending = true
    task.spawn(function()
        fbPush("/messages", {
            user = LP.Name,
            msg  = txt,
            ts   = timestamp(),
        })
        sending = false
    end)
end

sendBtn.MouseButton1Click:Connect(doSend)

textInput.FocusLost:Connect(function(enter)
    if enter then doSend() end
end)

-- ──────────────────────────────────────────────────────────────────────────────
-- MINIMIZE / CLOSE
-- ──────────────────────────────────────────────────────────────────────────────
local minimized = false

minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    msgScroll.Visible  = not minimized
    inputArea.Visible  = not minimized
    divider.Visible    = not minimized
    main.Size = minimized
        and UDim2.fromOffset(W, topH)
        or  UDim2.fromOffset(W, H)
    minBtn.Text = minimized and "□" or "–"
end)

closeBtn.MouseButton1Click:Connect(function()
    sg:Destroy()
end)
