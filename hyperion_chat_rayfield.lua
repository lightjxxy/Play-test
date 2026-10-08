-- lang: Luau, file: hyperion_chat_rayfield.lua, target: Roblox Executor
-- discord-style chat using Rayfield UI + Firebase REST

local FIREBASE_URL = "https://hyperion-chat-36da6-default-rtdb.firebaseio.com/hyperion-chat"
local POLL_RATE    = 3
local MAX_SHOWN    = 15  -- lines shown in the message window

-- ── SERVICES ──
local Players  = game:GetService("Players")
local HttpSvc  = game:GetService("HttpService")
local LP       = Players.LocalPlayer

-- ── RAYFIELD ──
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name             = "Hyperion Chat",
    LoadingTitle     = "Hyperion Chat",
    LoadingSubtitle  = "by AIwolfie",
    ConfigurationSaving = { Enabled = false },
    Discord          = { Enabled = false },
    KeySystem        = false,
})

-- ── TABS ──
local ChatTab     = Window:CreateTab("Chat",     "message-circle")
local SettingsTab = Window:CreateTab("Settings", "settings")

-- ── HTTP ──
local function httpReq(method, url, body)
    local fn = (syn  and type(syn.request)      == "function" and syn.request)
            or (type(http_request)              == "function" and http_request)
            or (type(request)                   == "function" and request)
            or (fluxus and type(fluxus.request) == "function" and fluxus.request)
    if not fn then return nil end
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
    httpReq("POST", FIREBASE_URL .. path .. ".json", data)
end

-- ── HELPERS ──
local function stamp()
    local t = os.time()
    return string.format("%02d:%02d", math.floor(t / 3600) % 24, math.floor(t / 60) % 60)
end

-- ── STATE ──
local username   = LP.Name
local pendingMsg = ""
local seen       = {}
local msgLines   = {}  -- list of formatted strings

-- ── CHAT TAB UI ──
ChatTab:CreateSection("Messages")

local msgDisplay = ChatTab:CreateParagraph({
    Title   = "💬 Chat",
    Content = "No messages yet — send one below.",
})

ChatTab:CreateSection("Compose")

ChatTab:CreateInput({
    Name                    = "Message",
    Info                    = "Type here then hit Send",
    PlaceholderText         = "Message #hyperion-chat...",
    RemoveTextAfterFocusLost = false,
    Callback                = function(val)
        pendingMsg = val or ""
    end,
})

ChatTab:CreateButton({
    Name     = "  ↑  Send",
    Info     = "Send your message to all players running this script",
    Callback = function()
        local txt = pendingMsg:match("^%s*(.-)%s*$")
        if txt == "" then
            Rayfield:Notify({ Title = "Chat", Content = "Nothing to send.", Duration = 2 })
            return
        end
        pendingMsg = ""
        task.spawn(function()
            fbPush("/messages", {
                user = username,
                msg  = txt,
                ts   = stamp(),
            })
        end)
    end,
})

-- ── SETTINGS TAB UI ──
SettingsTab:CreateSection("Identity")

SettingsTab:CreateInput({
    Name                    = "Display Name",
    Info                    = "Name others see in chat (default: your Roblox name)",
    PlaceholderText         = LP.Name,
    RemoveTextAfterFocusLost = true,
    Callback                = function(val)
        local trimmed = (val or ""):match("^%s*(.-)%s*$")
        if trimmed ~= "" then
            username = trimmed
            Rayfield:Notify({ Title = "Chat", Content = "Name set to: " .. trimmed, Duration = 3 })
        end
    end,
})

SettingsTab:CreateSection("Info")

SettingsTab:CreateParagraph({
    Title   = "How it works",
    Content = "Messages sync via Firebase every " .. POLL_RATE .. "s.\n"
           .. "Anyone running this script sees the same chat.\n"
           .. "History loads on join — no messages are lost.",
})

-- ── MESSAGE RENDERING ──
local function refreshDisplay()
    if #msgLines == 0 then
        msgDisplay:Set("💬 Chat", "No messages yet.")
        return
    end
    -- show last MAX_SHOWN lines
    local start  = math.max(1, #msgLines - MAX_SHOWN + 1)
    local visible = {}
    for i = start, #msgLines do
        table.insert(visible, msgLines[i])
    end
    msgDisplay:Set("💬 Chat", table.concat(visible, "\n"))
end

local function process(data)
    if type(data) ~= "table" then return end
    local batch = {}
    for k, v in pairs(data) do
        if type(v) == "table" and not seen[k] then
            seen[k] = true
            table.insert(batch, { key = k, data = v })
        end
    end
    if #batch == 0 then return end
    table.sort(batch, function(a, b) return a.key < b.key end)
    for _, entry in ipairs(batch) do
        local d = entry.data
        if d.user and d.msg then
            local line = string.format("[%s] %s: %s", d.ts or "??:??", d.user, d.msg)
            table.insert(msgLines, line)
            -- notify if message is from someone else
            if d.user ~= username then
                Rayfield:Notify({
                    Title    = d.user,
                    Content  = d.msg,
                    Duration = 4,
                    Image    = "message-circle",
                })
            end
        end
    end
    refreshDisplay()
end

-- ── INIT + POLL ──
task.spawn(function()
    process(fbGet("/messages"))
end)

task.spawn(function()
    while true do
        task.wait(POLL_RATE)
        process(fbGet("/messages"))
    end
end)
