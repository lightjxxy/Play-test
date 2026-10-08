-- lang: Luau, file: hyperion_chat_v2.lua, target: Roblox Executor
-- v2: CoreGui, manual drag, no ClipsDescendants

local FIREBASE_URL = "https://hyperion-chat-36da6-default-rtdb.firebaseio.com/hyperion-chat"
local POLL_RATE    = 3
local MAX_MESSAGES = 80

local Players   = game:GetService("Players")
local HttpSvc   = game:GetService("HttpService")
local RunSvc    = game:GetService("RunService")
local UIS       = game:GetService("UserInputService")
local LP        = Players.LocalPlayer

-- use CoreGui — more reliable in executors than PlayerGui
local root = game:GetService("CoreGui")

-- ── HTTP ──
local function httpReq(method, url, body)
    local fn = (syn  and type(syn.request)      == "function" and syn.request)
            or (type(http_request)              == "function" and http_request)
            or (type(request)                   == "function" and request)
            or (fluxus and type(fluxus.request) == "function" and fluxus.request)
    if not fn then return nil end
    local cfg = { Url = url, Method = method, Headers = { ["Content-Type"] = "application/json" } }
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
    httpReq("POST", FIREBASE_URL .. path .. ".json", data)
end

-- ── HELPERS ──
local COLORS = {
    Color3.fromRGB(255,114,114), Color3.fromRGB(255,178,88),
    Color3.fromRGB(87,219,146),  Color3.fromRGB(88,166,255),
    Color3.fromRGB(171,115,255), Color3.fromRGB(255,107,185),
    Color3.fromRGB(92,225,230),
}
local function nameColor(n)
    local h = 0
    for i=1,#n do h=h+string.byte(n,i) end
    return COLORS[(h%#COLORS)+1]
end
local function toHex(c)
    return string.format("#%02x%02x%02x",
        math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
end
local function stamp()
    local t = os.time()
    return string.format("%02d:%02d", math.floor(t/3600)%24, math.floor(t/60)%60)
end

-- ── DESTROY OLD ──
pcall(function()
    local old = root:FindFirstChild("HyperionChat")
    if old then old:Destroy() end
end)

-- ── SCREENGUI ──
local sg = Instance.new("ScreenGui")
sg.Name           = "HyperionChat"
sg.ResetOnSpawn   = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent         = root

-- ── WINDOW ──
local W, H   = 380, 500
local TOPBAR = 48
local INPUT  = 58

local win = Instance.new("Frame")
win.Name             = "Win"
win.Size             = UDim2.fromOffset(W, H)
win.Position         = UDim2.new(0.5,-W/2,0.5,-H/2)
win.BackgroundColor3 = Color3.fromRGB(54,57,63)
win.BorderSizePixel  = 0
win.Parent           = sg
Instance.new("UICorner", win).CornerRadius = UDim.new(0,8)

-- ── TOP BAR ──
local top = Instance.new("Frame")
top.Size            = UDim2.new(1,0,0,TOPBAR)
top.BackgroundColor3= Color3.fromRGB(47,49,54)
top.BorderSizePixel = 0
top.ZIndex          = 5
top.Parent          = win

-- square off bottom edge of topbar
local topSquare = Instance.new("Frame")
topSquare.Size            = UDim2.new(1,0,0.5,0)
topSquare.Position        = UDim2.new(0,0,0.5,0)
topSquare.BackgroundColor3= Color3.fromRGB(47,49,54)
topSquare.BorderSizePixel = 0
topSquare.ZIndex          = 5
topSquare.Parent          = top

Instance.new("UICorner", top).CornerRadius = UDim.new(0,8)

-- icon
local ico = Instance.new("Frame")
ico.Size            = UDim2.fromOffset(28,28)
ico.Position        = UDim2.new(0,12,0.5,-14)
ico.BackgroundColor3= Color3.fromRGB(88,101,242)
ico.BorderSizePixel = 0
ico.ZIndex          = 6
ico.Parent          = top
Instance.new("UICorner", ico).CornerRadius = UDim.new(0,6)
local icoTxt = Instance.new("TextLabel")
icoTxt.Size                = UDim2.new(1,0,1,0)
icoTxt.BackgroundTransparency = 1
icoTxt.Text                = "#"
icoTxt.TextColor3          = Color3.fromRGB(255,255,255)
icoTxt.Font                = Enum.Font.GothamBold
icoTxt.TextSize             = 14
icoTxt.ZIndex               = 7
icoTxt.Parent               = ico

-- title
local titleLbl = Instance.new("TextLabel")
titleLbl.Size               = UDim2.new(1,-120,1,0)
titleLbl.Position           = UDim2.fromOffset(48,0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text               = "hyperion-chat"
titleLbl.TextColor3         = Color3.fromRGB(255,255,255)
titleLbl.Font               = Enum.Font.GothamBold
titleLbl.TextSize            = 14
titleLbl.TextXAlignment      = Enum.TextXAlignment.Left
titleLbl.ZIndex              = 6
titleLbl.Parent              = top

-- minimize
local minBtn = Instance.new("TextButton")
minBtn.Size            = UDim2.fromOffset(28,28)
minBtn.Position        = UDim2.new(1,-66,0.5,-14)
minBtn.BackgroundColor3= Color3.fromRGB(64,68,75)
minBtn.TextColor3      = Color3.fromRGB(220,221,222)
minBtn.Text            = "–"
minBtn.Font            = Enum.Font.GothamBold
minBtn.TextSize         = 14
minBtn.BorderSizePixel  = 0
minBtn.ZIndex           = 6
minBtn.Parent           = top
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0,4)

-- close
local closeBtn = Instance.new("TextButton")
closeBtn.Size            = UDim2.fromOffset(28,28)
closeBtn.Position        = UDim2.new(1,-32,0.5,-14)
closeBtn.BackgroundColor3= Color3.fromRGB(220,55,55)
closeBtn.TextColor3      = Color3.fromRGB(255,255,255)
closeBtn.Text            = "✕"
closeBtn.Font            = Enum.Font.GothamBold
closeBtn.TextSize         = 13
closeBtn.BorderSizePixel  = 0
closeBtn.ZIndex           = 6
closeBtn.Parent           = top
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,4)

-- ── MANUAL DRAG ──
local dragging, dragStart, winStart = false, nil, nil
top.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = i.Position
        winStart  = win.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if not dragging then return end
    if i.UserInputType == Enum.UserInputType.MouseMovement
    or i.UserInputType == Enum.UserInputType.Touch then
        local delta = i.Position - dragStart
        win.Position = UDim2.new(
            winStart.X.Scale, winStart.X.Offset + delta.X,
            winStart.Y.Scale, winStart.Y.Offset + delta.Y)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ── SCROLL AREA ──
local scroll = Instance.new("ScrollingFrame")
scroll.Name                 = "Msgs"
scroll.Size                 = UDim2.new(1,0,1,-(TOPBAR+INPUT+1))
scroll.Position             = UDim2.fromOffset(0,TOPBAR)
scroll.BackgroundColor3     = Color3.fromRGB(54,57,63)
scroll.BorderSizePixel      = 0
scroll.ScrollBarThickness   = 4
scroll.ScrollBarImageColor3 = Color3.fromRGB(32,34,37)
scroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
scroll.CanvasSize           = UDim2.new(0,0,0,0)
scroll.ScrollingDirection   = Enum.ScrollingDirection.Y
scroll.ZIndex               = 2
scroll.Parent               = win

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding   = UDim.new(0,0)
layout.Parent    = scroll

local pad = Instance.new("UIPadding")
pad.PaddingLeft   = UDim.new(0,12)
pad.PaddingRight  = UDim.new(0,12)
pad.PaddingTop    = UDim.new(0,10)
pad.PaddingBottom = UDim.new(0,8)
pad.Parent        = scroll

-- ── DIVIDER ──
local div = Instance.new("Frame")
div.Size            = UDim2.new(1,0,0,1)
div.Position        = UDim2.new(0,0,1,-(INPUT+1))
div.BackgroundColor3= Color3.fromRGB(30,30,35)
div.BorderSizePixel = 0
div.ZIndex          = 3
div.Parent          = win

-- ── INPUT BAR ──
local bar = Instance.new("Frame")
bar.Size            = UDim2.new(1,0,0,INPUT)
bar.Position        = UDim2.new(0,0,1,-INPUT)
bar.BackgroundColor3= Color3.fromRGB(47,49,54)
bar.BorderSizePixel = 0
bar.ZIndex          = 3
bar.Parent          = win

-- square off top edge
local barSquare = Instance.new("Frame")
barSquare.Size            = UDim2.new(1,0,0.5,0)
barSquare.BackgroundColor3= Color3.fromRGB(47,49,54)
barSquare.BorderSizePixel = 0
barSquare.ZIndex          = 3
barSquare.Parent          = bar
Instance.new("UICorner", bar).CornerRadius = UDim.new(0,8)

local boxBg = Instance.new("Frame")
boxBg.Size            = UDim2.new(1,-58,0,36)
boxBg.Position        = UDim2.new(0,12,0.5,-18)
boxBg.BackgroundColor3= Color3.fromRGB(64,68,75)
boxBg.BorderSizePixel = 0
boxBg.ZIndex          = 4
boxBg.Parent          = bar
Instance.new("UICorner", boxBg).CornerRadius = UDim.new(0,6)

local boxPad = Instance.new("UIPadding")
boxPad.PaddingLeft  = UDim.new(0,10)
boxPad.PaddingRight = UDim.new(0,10)
boxPad.Parent       = boxBg

local tb = Instance.new("TextBox")
tb.Size               = UDim2.new(1,0,1,0)
tb.BackgroundTransparency = 1
tb.TextColor3         = Color3.fromRGB(220,221,222)
tb.PlaceholderText    = "Message #hyperion-chat"
tb.PlaceholderColor3  = Color3.fromRGB(114,118,125)
tb.Font               = Enum.Font.Gotham
tb.TextSize            = 13
tb.TextXAlignment      = Enum.TextXAlignment.Left
tb.ClearTextOnFocus    = false
tb.MultiLine           = false
tb.Text                = ""
tb.ZIndex              = 5
tb.Parent              = boxBg

local sendB = Instance.new("TextButton")
sendB.Size            = UDim2.fromOffset(36,36)
sendB.Position        = UDim2.new(1,-48,0.5,-18)
sendB.BackgroundColor3= Color3.fromRGB(88,101,242)
sendB.TextColor3      = Color3.fromRGB(255,255,255)
sendB.Text            = "↑"
sendB.Font            = Enum.Font.GothamBold
sendB.TextSize         = 18
sendB.BorderSizePixel  = 0
sendB.ZIndex           = 4
sendB.Parent           = bar
Instance.new("UICorner", sendB).CornerRadius = UDim.new(0,6)

-- ── RENDER ──
local order    = 0
local seen     = {}
local rows     = {}

local function scrollBot()
    task.defer(function() scroll.CanvasPosition = Vector2.new(0,1e9) end)
end

local function renderMsg(data)
    if type(data)~="table" or not data.msg or not data.user then return end
    order = order + 1

    local col = nameColor(data.user)
    local hex = toHex(col)

    local row = Instance.new("Frame")
    row.Size              = UDim2.new(1,0,0,0)
    row.AutomaticSize     = Enum.AutomaticSize.Y
    row.BackgroundTransparency = 1
    row.LayoutOrder       = order
    row.ZIndex            = 2
    row.Parent            = scroll
    table.insert(rows, row)

    local rpad = Instance.new("UIPadding")
    rpad.PaddingTop    = UDim.new(0,5)
    rpad.PaddingBottom = UDim.new(0,5)
    rpad.Parent        = row

    -- avatar
    local av = Instance.new("Frame")
    av.Size            = UDim2.fromOffset(30,30)
    av.Position        = UDim2.fromOffset(0,2)
    av.BackgroundColor3= col
    av.BorderSizePixel = 0
    av.ZIndex          = 3
    av.Parent          = row
    Instance.new("UICorner", av).CornerRadius = UDim.new(1,0)
    local avL = Instance.new("TextLabel")
    avL.Size               = UDim2.new(1,0,1,0)
    avL.BackgroundTransparency = 1
    avL.Text               = string.upper(string.sub(data.user,1,1))
    avL.TextColor3         = Color3.fromRGB(255,255,255)
    avL.Font               = Enum.Font.GothamBold
    avL.TextSize            = 13
    avL.ZIndex              = 4
    avL.Parent              = av

    -- content
    local cf = Instance.new("Frame")
    cf.Size          = UDim2.new(1,-42,0,0)
    cf.Position      = UDim2.fromOffset(42,0)
    cf.AutomaticSize = Enum.AutomaticSize.Y
    cf.BackgroundTransparency = 1
    cf.ZIndex        = 3
    cf.Parent        = row

    local hdr = Instance.new("TextLabel")
    hdr.Size              = UDim2.new(1,0,0,18)
    hdr.BackgroundTransparency = 1
    hdr.RichText          = true
    hdr.TextXAlignment    = Enum.TextXAlignment.Left
    hdr.Text              = string.format(
        '<font color="%s"><b>%s</b></font>  <font color="#72767d" size="11">%s</font>',
        hex, data.user, data.ts or "")
    hdr.Font              = Enum.Font.Gotham
    hdr.TextSize           = 13
    hdr.ZIndex             = 4
    hdr.Parent             = cf

    local msg = Instance.new("TextLabel")
    msg.Size              = UDim2.new(1,0,0,0)
    msg.Position          = UDim2.fromOffset(0,20)
    msg.AutomaticSize     = Enum.AutomaticSize.Y
    msg.BackgroundTransparency = 1
    msg.TextColor3        = Color3.fromRGB(220,221,222)
    msg.TextXAlignment    = Enum.TextXAlignment.Left
    msg.TextWrapped       = true
    msg.Font              = Enum.Font.Gotham
    msg.TextSize           = 13
    msg.Text               = data.msg
    msg.ZIndex             = 4
    msg.Parent             = cf

    if #rows > MAX_MESSAGES then
        local old = table.remove(rows, 1)
        if old then old:Destroy() end
    end

    scrollBot()
end

-- ── POLL ──
local function process(data)
    if type(data)~="table" then return end
    local batch = {}
    for k,v in pairs(data) do
        if type(v)=="table" and not seen[k] then
            seen[k] = true
            table.insert(batch, {key=k, data=v})
        end
    end
    table.sort(batch, function(a,b) return a.key<b.key end)
    for _,e in ipairs(batch) do renderMsg(e.data) end
end

task.spawn(function() process(fbGet("/messages")) end)

task.spawn(function()
    while sg.Parent do
        task.wait(POLL_RATE)
        process(fbGet("/messages"))
    end
end)

-- ── SEND ──
local busy = false
local function doSend()
    if busy then return end
    local txt = tb.Text:match("^%s*(.-)%s*$")
    if txt=="" then return end
    tb.Text = ""
    busy = true
    task.spawn(function()
        fbPush("/messages", { user=LP.Name, msg=txt, ts=stamp() })
        busy = false
    end)
end
sendB.MouseButton1Click:Connect(doSend)
tb.FocusLost:Connect(function(enter) if enter then doSend() end end)

-- ── MINIMIZE / CLOSE ──
local mini = false
minBtn.MouseButton1Click:Connect(function()
    mini = not mini
    scroll.Visible  = not mini
    bar.Visible     = not mini
    div.Visible     = not mini
    win.Size = mini and UDim2.fromOffset(W,TOPBAR) or UDim2.fromOffset(W,H)
    minBtn.Text = mini and "□" or "–"
end)
closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)
