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

    local function notify(title, content, sub, dur)
        pcall(function()
            local text = tostring(content or "")
            if sub and sub ~= "" then
                text = text .. "\n" .. tostring(sub)
            end
            StarterGui:SetCore("SendNotification", {
                Title = tostring(title or "Unlock All"),
                Text = text,
                Duration = dur or 4,
            })
        end)
    end

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
            if not cur then return nil end
            cur = cur:FindFirstChild(name)
        end
        return cur
    end

    local function req(label, ...)
        local names = { ... }
        local ok, res = pcall(function()
            local inst = path(RS, table.unpack(names))
            if not inst then error("path not found") end
            return require(inst)
        end)
        if not ok then
            log("FAILED loading", label, "->", tostring(res))
            return nil
        end
        return res
    end

    local active = false
    local gen = 0
    local patches = {}
    local patchResults = {}
    local fakeE = {}
    local fakeC = {}
    local fakeSkin = {}
    local pending = nil
    local popupInst = nil
    local currentEmoteId = nil

    local Registry = req("Items.Registry", "Items", "Registry")
    local OwnedBitset = req("OwnedBitset", "Shared", "UserData", "Codecs", "OwnedBitset")
    local EquippedCodec = req("EquippedCodec", "Shared", "UserData", "Codecs", "Equipped")
    local Store = req("Store", "Client", "Services", "UserData", "Inventory", "Store")
    local Loadout = req("Loadout", "Client", "Services", "UserData", "Inventory", "Loadout")
    local InvService = req("Inventory", "Client", "Services", "UserData", "Inventory")

    local RigClass = req("Objects.Game.Character.Rig", "Objects", "Game", "Character", "Rig")
    local DataRegClass = req("Objects.Game.Character.DataRegistry", "Objects", "Game", "Character", "DataRegistry")
    local PopupService = req("PopupService", "Services", "UI", "PopupService")
    local EmotePopup = req("PopupService.Types.Emote", "Services", "UI", "PopupService", "Types", "Emote")
    local EmoteClass = req("Objects.Items.Emote", "Objects", "Items", "Emote")
    local EmoteService = req("EmoteService", "Services", "Items", "EmoteService")
    local ItemSvc = req("ClientItemService", "Services", "Items", "ClientItemService")

    local EquipRemote = path(RS, "Shared", "UserData", "Remotes", "Equip")
    local SetSkinRemote = path(RS, "Shared", "UserData", "Remotes", "SetSkin")

    local InvView
    pcall(function()
        InvView = require(RS.Objects.Menu.Menu.Views.Inventory)
    end)
    local MenuMgr
    pcall(function()
        MenuMgr = require(RS.Objects.Menu.Menu)
    end)

    local ALL_ITEMS = {}
    local ALL_EMOTES = {}
    local EMOTE_SET = {}
    local UNUSUAL_SET = {}
    local TYPE_OF = {}

    M.Log = LOG
    M.FakeEmotes = fakeE
    M.FakeCosmetics = fakeC
    M.FakeSkins = fakeSkin

    local function getFieldStore()
        return Store and Store._fieldStore
    end

    local function getCache()
        local fs = getFieldStore()
        return fs and fs._cache
    end

    local function refreshUI()
        if MenuMgr then
            pcall(function()
                if MenuMgr.LoadoutUpdated then task.spawn(MenuMgr.LoadoutUpdated, MenuMgr) end
                if MenuMgr.InventoryUpdated then task.spawn(MenuMgr.InventoryUpdated, MenuMgr) end
            end)
        end
        if InvView then
            pcall(function()
                if InvView.UpdateLoadout then task.spawn(InvView.UpdateLoadout, InvView) end
                if InvView.UpdateInventory then task.spawn(InvView.UpdateInventory, InvView) end
                if InvView.Update then task.spawn(InvView.Update, InvView) end
            end)
        end
    end

    local function fireListener(key)
        local fs = getFieldStore()
        local c = getCache()
        if fs and fs._listeners and fs._listeners[key] and c and c[key] then
            for _, l in ipairs(fs._listeners[key]) do
                pcall(l, c[key])
            end
        end
    end

    local function makeWritable(t)
        if typeof(setreadonly) == "function" then pcall(setreadonly, t, false) end
        if typeof(make_writeable) == "function" then pcall(make_writeable, t) end
    end

    local function patch(label, tbl, key, build)
        local orig = tbl[key]
        if type(orig) ~= "function" then
            log("PATCH NOT APPLIED (function does not exist):", label)
            patchResults[#patchResults + 1] = { label = label, ok = false }
            return false
        end

        makeWritable(tbl)
        local ok, err = pcall(function()
            local replacement = build(orig)
            rawset(tbl, key, replacement)
        end)

        if not ok then
            log("PATCH FAILED:", label, "->", tostring(err))
            patchResults[#patchResults + 1] = { label = label, ok = false }
            return false
        end

        patches[#patches + 1] = { tbl = tbl, key = key, orig = orig }
        patchResults[#patchResults + 1] = { label = label, ok = true }
        return true
    end

    local function clearVisualRigParticles()
        local char = LP.Character
        if not char then return end
        for _, desc in ipairs(char:GetDescendants()) do
            if desc:IsA("ParticleEmitter") or desc:IsA("Beam") or desc:IsA("Trail") then
                local pName = desc.Parent and desc.Parent.Name or ""
                if pName ~= "Slide" and pName ~= "JumpPos" and pName ~= "RootPart" then
                    desc.Enabled = false
                    task.delay(0.1, function() pcall(desc.Destroy, desc) end)
                end
            end
        end
    end

    local function slotToBufferIndex(slot)
        if type(slot) == "number" then return slot end
        local str = tostring(slot)
        local eNum = string.match(str, "^EmoteSlot_(%d+)$") or string.match(str, "^Emote_(%d+)$") or string.match(str, "^Emote(%d+)$")
        local num = tonumber(eNum)
        if num then
            return 12 + num
        end
        local map = {
            Character = 1,
            Skin = 2,
            PerkSlot_1 = 8,
            Perk1 = 8,
            PerkSlot_2 = 9,
            Perk2 = 9,
            LightSlot = 10,
            Light = 10,
            NametagSlot = 5,
            Nametag = 5,
            CarryAnimationSlot = 7,
            CarryAnimation = 7,
            ConsumableSlot_1 = 25,
            ConsumableSlot_2 = 26,
            ConsumableSlot_3 = 27,
            Unusual = 11,
            UnusualSlot = 11,
        }
        return map[str] or tonumber(str) or 0
    end

    local function localEquip(slot, id)
        local c = getCache()
        if not (c and c.Equipped and EquippedCodec) then return end

        local bufIdx = slotToBufferIndex(slot)
        local slotStr = tostring(slot)
        local isEmote = EMOTE_SET[id] or (bufIdx >= 13 and bufIdx <= 24) or string.find(slotStr, "Emote")
        local isUnusual = UNUSUAL_SET[id] or slotStr == "Unusual" or slotStr == "UnusualSlot"

        if isEmote then
            local emoteIdx = (bufIdx >= 13 and bufIdx <= 24) and (bufIdx - 12) or tonumber(string.match(slotStr, "%d+")) or 1
            bufIdx = 12 + emoteIdx
            c.Equipped = EquippedCodec.With(c.Equipped, bufIdx, id)
            fireListener("Equipped")
            fakeE[emoteIdx] = id
            fakeE["EmoteSlot_" .. emoteIdx] = id
            log("Equipped Emote Slot", emoteIdx, "-> ID", id)
        elseif isUnusual then
            fakeC["Unusual"] = id
            fakeC["UnusualSlot"] = id
            for _, baseId in ipairs({ 139, 141, 147, 149 }) do
                if not c.Attributes then c.Attributes = {} end
                if not c.Attributes[baseId] then c.Attributes[baseId] = {} end
                c.Attributes[baseId][3] = id
                fakeSkin[baseId] = id
            end
            fireListener("Attributes")
            log("Equipped Unusual -> ID", id)
        else
            if type(bufIdx) == "number" and bufIdx > 0 then
                c.Equipped = EquippedCodec.With(c.Equipped, bufIdx, id)
                fireListener("Equipped")
            end
            fakeC[slotStr] = id
            log("Equipped Cosmetic", slotStr, "-> ID", id)
        end

        refreshUI()
    end

    local function localUnequip(slot)
        local c = getCache()
        if not (c and c.Equipped and EquippedCodec) then return end

        local bufIdx = slotToBufferIndex(slot)
        local slotStr = tostring(slot)

        if (bufIdx >= 13 and bufIdx <= 24) or string.find(slotStr, "Emote") then
            local emoteIdx = (bufIdx >= 13 and bufIdx <= 24) and (bufIdx - 12) or tonumber(string.match(slotStr, "%d+")) or 1
            bufIdx = 12 + emoteIdx
            c.Equipped = EquippedCodec.With(c.Equipped, bufIdx, 0)
            fireListener("Equipped")
            fakeE[emoteIdx] = nil
            fakeE["EmoteSlot_" .. emoteIdx] = nil
            log("Cleared Emote Slot", emoteIdx, "to None")
        elseif slotStr == "Unusual" or slotStr == "UnusualSlot" or bufIdx == 11 then
            fakeC["Unusual"] = nil
            fakeC["UnusualSlot"] = nil
            table.clear(fakeSkin)
            if c.Attributes then
                for baseId in pairs(c.Attributes) do
                    c.Attributes[baseId][3] = nil
                end
            end
            fireListener("Attributes")
            clearVisualRigParticles()
            log("Cleared Unusual to None")
        else
            if type(bufIdx) == "number" and bufIdx > 0 then
                c.Equipped = EquippedCodec.With(c.Equipped, bufIdx, 0)
                fireListener("Equipped")
            end
            fakeC[slotStr] = nil
            log("Cleared Slot", slotStr, "to None")
        end

        refreshUI()
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
        if not popup or not popup.Frame or type(popup.Emotes) ~= "table" or not ItemSvc then
            return
        end
        for idx = 1, 12 do
            local fid = fakeE[idx] or fakeE["EmoteSlot_" .. idx]
            if fid then
                popup.Emotes[idx] = fid
                pcall(function()
                    local sf = wheelSlotFrame(popup, idx)
                    local item = ItemSvc:GetItemFromID(fid)
                    if sf and item then
                        ItemSvc:ClearViewport(sf.ViewportFrame)
                        ItemSvc:CreateViewport(item, sf.ViewportFrame)
                        sf.TextLabel.Text = ItemSvc:GetName(item)
                    end
                end)
            end
        end
    end

    local function collectAllRegistry()
        if not Registry then return end
        local all = pcall(Registry.GetAll) and Registry.GetAll() or {}
        local allList, emoteList = {}, {}
        table.clear(EMOTE_SET)
        table.clear(UNUSUAL_SET)

        for id, item in pairs(all) do
            if type(id) == "number" then
                table.insert(allList, id)
                if item and item.Categories then
                    for _, cat in ipairs(item.Categories) do
                        if cat == "Emotes" then
                            table.insert(emoteList, id)
                            EMOTE_SET[id] = true
                        elseif cat == "Unusual" then
                            UNUSUAL_SET[id] = true
                        end
                        TYPE_OF[id] = cat
                    end
                end
            end
        end
        ALL_ITEMS = allList
        ALL_EMOTES = emoteList
        log("Indexed", #ALL_ITEMS, "items |", #ALL_EMOTES, "emotes |", #UNUSUAL_SET, "unusuals")
    end

    local function unlockAllInCache()
        local c = getCache()
        if not (c and c.OwnedBits and OwnedBitset) then return end
        local cur = c.OwnedBits
        for _, id in ipairs(ALL_ITEMS) do
            cur = OwnedBitset.Add(cur, id)
        end
        c.OwnedBits = cur
        fireListener("OwnedBits")
        refreshUI()
        log("Injected all items into OwnedBits")
    end

    local origNamecall
    local function hookRemotes()
        if typeof(hookmetamethod) == "function" then
            origNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                if method == "FireServer" then
                    if EquipRemote and self == EquipRemote then
                        local args = { ... }
                        local slot = args[1]
                        local id = args[2]
                        if id and id ~= 0 then
                            localEquip(slot, id)
                            return
                        else
                            localUnequip(slot)
                            return
                        end
                    elseif SetSkinRemote and self == SetSkinRemote then
                        local args = { ... }
                        local baseId = args[1]
                        local skinId = args[2]
                        if skinId and skinId ~= 0 then
                            localEquip("Unusual", skinId)
                            return
                        else
                            localUnequip("Unusual")
                            return
                        end
                    end
                end
                return origNamecall(self, ...)
            end)
            log("Equip & SetSkin Remotes hooked via __namecall")
        end
    end

    local function hookServices()
        if Loadout and type(Loadout.GetEquipped) == "function" then
            patch("Loadout.GetEquipped", Loadout, "GetEquipped", function(orig)
                return function(self, ...)
                    local real = orig(self, ...)
                    if type(real) ~= "table" then return real end
                    local out = table.clone(real)
                    for k, fid in pairs(fakeE) do out[k] = fid end
                    for k, fid in pairs(fakeC) do
                        if not EMOTE_SET[fid] then
                            out[k] = fid
                        end
                    end
                    return out
                end
            end)
        end

        if InvService then
            if type(InvService.GetLoadout) == "function" then
                patch("Inventory.GetLoadout", InvService, "GetLoadout", function(orig)
                    return function(self, ...)
                        local real = orig(self, ...)
                        if type(real) ~= "table" then return real end
                        local out = table.clone(real)
                        for k, fid in pairs(fakeE) do out[k] = fid end
                        for k, fid in pairs(fakeC) do
                            if not EMOTE_SET[fid] then
                                out[k] = fid
                            end
                        end
                        return out
                    end
                end)
            end

            if type(InvService.GetSkin) == "function" then
                patch("Inventory.GetSkin", InvService, "GetSkin", function(orig)
                    return function(self, baseId, ...)
                        local actualBase = (type(baseId) == "number") and baseId or self
                        if fakeSkin[actualBase] then
                            return fakeSkin[actualBase]
                        end
                        if fakeC["Unusual"] == nil and fakeC["UnusualSlot"] == nil then
                            return nil
                        end
                        return orig(self, baseId, ...)
                    end
                end)
            end
        end
    end

    local function applyPatches()
        hookRemotes()
        hookServices()

        if EmoteService and type(EmoteService.SetEmote) == "function" then

            -- purely client-side: fake UpdateCharacterDataRegistry client event
            -- server never sees this — fid > 0 plays, fid == 0 clears (same opcode both ways)
            local function fireVisual(fid)
                local char = LP.Character
                local tag = char and char:GetAttribute("Tag")
                if tag and type(firesignal) == "function" then
                    pcall(function()
                        local tagBuf = buffer.create(2)
                        buffer.writeu16(tagBuf, 0, tag)
                        firesignal(RS.Events.UpdateCharacterDataRegistry.OnClientEvent, {
                            buffer.fromstring("\24\1"),
                            fid,
                            tagBuf,
                        })
                    end)
                end
            end

            -- belt-and-suspenders: also stop the AnimationTrack directly
            local function stopLocalTrack()
                pcall(function()
                    local char = LP.Character
                    if not char then return end
                    local humanoid = char:FindFirstChildOfClass("Humanoid")
                    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
                    if not animator then return end
                    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                        if track.Animation and track.Animation:HasTag("RelicsEmote") then
                            track:Stop()
                        end
                    end
                end)
            end

            local function doCancel(self, orig, ...)
                currentEmoteId = nil
                fireVisual(0)      -- fid=0: DataRegistry clears the emote slot
                stopLocalTrack()   -- kill the AnimationTrack in case DataRegistry lags
                return orig(self, nil, ...)
            end

            patch("EmoteService.SetEmote", EmoteService, "SetEmote", function(orig)
                return function(self, targetModule, ...)
                    -- pending check runs FIRST — game fires SetEmote(nil) for empty/fake slots;
                    -- old order let nil eat pending before fake emote logic ever ran
                    if pending and pending.slot then
                        local fid = fakeE[pending.slot] or fakeE["EmoteSlot_" .. pending.slot]
                        pending = nil

                        if fid then
                            -- toggle: same emote running → cancel
                            if currentEmoteId == fid then
                                return doCancel(self, orig, ...)
                            end

                            -- play: fireVisual fakes it client-side, orig syncs EmoteService state
                            local itemEntry = Registry.GetById(fid)
                            if itemEntry and itemEntry.Module then
                                currentEmoteId = fid
                                fireVisual(fid)
                                return orig(self, itemEntry.Module, ...)
                            end
                        end
                    end

                    -- no fake emote pending — pass through
                    if not targetModule then
                        if currentEmoteId then
                            return doCancel(self, orig, ...)
                        end
                        currentEmoteId = nil
                        return orig(self, nil, ...)
                    end

                    -- real owned emote
                    currentEmoteId = nil
                    return orig(self, targetModule, ...)
                end
            end)

            for _, cancelFn in ipairs({ "CancelEmote", "StopEmote", "Stop" }) do
                if type(EmoteService[cancelFn]) == "function" then
                    patch("EmoteService." .. cancelFn, EmoteService, cancelFn, function(orig)
                        return function(self, ...)
                            if currentEmoteId then
                                currentEmoteId = nil
                                fireVisual(0)
                                stopLocalTrack()
                            end
                            return orig(self, ...)
                        end
                    end)
                end
            end
        end

        if EmotePopup then
            patch("EmotePopup.SetEquipped", EmotePopup, "SetEquipped", function(orig)
                return function(self, list, ...)
                    popupInst = self
                    if type(list) == "table" then
                        for idx = 1, 12 do
                            local fid = fakeE[idx] or fakeE["EmoteSlot_" .. idx]
                            if fid then list[idx] = fid end
                        end
                    end
                    local r = orig(self, list, ...)
                    applyOverlay(self)
                    return r
                end
            end)

            patch("EmotePopup.Show", EmotePopup, "Show", function(orig)
                return function(self, ...)
                    popupInst = self
                    if type(self.Emotes) == "table" then
                        for idx = 1, 12 do
                            local fid = fakeE[idx] or fakeE["EmoteSlot_" .. idx]
                            if fid then self.Emotes[idx] = fid end
                        end
                    end
                    local r = orig(self, ...)
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

            patch("EmotePopup.KeyUsed", EmotePopup, "KeyUsed", function(orig)
                return function(self, slot, ...)
                    if type(slot) == "number" then
                        pending = { slot = slot, t = tick() }
                    end
                    return orig(self, slot, ...)
                end
            end)

            -- mobile cancel button + G key direct-cancel path
            -- on mobile the stop button bypasses KeyActivated entirely and calls one of these;
            -- on PC the G key can also hit these directly when the wheel isn't open
            for _, cancelMethod in ipairs({
                "StopCurrentEmote", "CancelCurrentEmote", "OnStopPressed",
                "OnCancelPressed", "StopEmote", "CancelEmote", "Deactivate",
            }) do
                if type(EmotePopup[cancelMethod]) == "function" then
                    patch("EmotePopup." .. cancelMethod, EmotePopup, cancelMethod, function(orig)
                        return function(self, ...)
                            if currentEmoteId then
                                fireVisual(0)
                                stopLocalTrack()
                                currentEmoteId = nil
                                if EmoteService then
                                    pcall(function() EmoteService:SetEmote(nil) end)
                                end
                            end
                            return orig(self, ...)
                        end
                    end)
                end
            end

            -- fallback: watch the popup frame for a GuiButton named Stop/Cancel/StopEmote
            -- covers mobile executors where the button fires Activated directly
            task.spawn(function()
                task.wait(3)
                local popup = getPopup()
                if not (popup and popup.Frame) then return end
                local function tryBindButton(btn)
                    if btn and btn:IsA("GuiButton") then
                        btn.Activated:Connect(function()
                            if currentEmoteId then
                                fireVisual(0)
                                stopLocalTrack()
                                currentEmoteId = nil
                                if EmoteService then
                                    pcall(function() EmoteService:SetEmote(nil) end)
                                end
                            end
                        end)
                        log("Bound mobile cancel button:", btn.Name)
                    end
                end
                for _, name in ipairs({ "Stop", "StopButton", "Cancel", "CancelButton", "StopEmote", "CancelEmote" }) do
                    tryBindButton(popup.Frame:FindFirstChild(name, true))
                end
            end)

            -- G key guard (PC): if G fires outside the wheel and currentEmoteId is live
            -- KeyActivated handles the in-wheel case; this catches the direct cancel
            local UIS = game:GetService("UserInputService")
            UIS.InputBegan:Connect(function(input, processed)
                if processed then return end
                if input.KeyCode == Enum.KeyCode.G and currentEmoteId then
                    fireVisual(0)
                    stopLocalTrack()
                    currentEmoteId = nil
                    if EmoteService then
                        pcall(function() EmoteService:SetEmote(nil) end)
                    end
                end
            end)
        end

        if RigClass and RigClass.BuildRig then
            patch("Rig.BuildRig", RigClass, "BuildRig", function(orig)
                return function(self, ...)
                    if not self.Built and type(self.Cosmetics) == "table" and next(fakeC) ~= nil then
                        local isLocal = false
                        pcall(function()
                            isLocal = self.Parent ~= nil and self.Parent.Local == true
                        end)
                        if isLocal then
                            pcall(function()
                                local real = self.Cosmetics
                                local out, seen = {}, {}
                                for _, id in ipairs(real) do
                                    out[#out + 1] = id
                                    seen[id] = true
                                end
                                for _, fid in pairs(fakeC) do
                                    if not seen[fid] and not EMOTE_SET[fid] then
                                        out[#out + 1] = fid
                                        seen[fid] = true
                                    end
                                end
                                self.Cosmetics = out
                                log("Rig equipped cosmetics: " .. table.concat(out, ", "))
                            end)
                        end
                    end
                    return orig(self, ...)
                end
            end)
        end
    end

    function M.Disable()
        gen = gen + 1
        if not active then return end
        for i = #patches, 1, -1 do
            local p = patches[i]
            if p.tbl and p.key then
                makeWritable(p.tbl)
                pcall(function()
                    rawset(p.tbl, p.key, p.orig)
                end)
            end
        end
        patches = {}
        table.clear(fakeE)
        table.clear(fakeC)
        table.clear(fakeSkin)
        pending = nil
        popupInst = nil
        currentEmoteId = nil
        active = false
        clearVisualRigParticles()
        refreshUI()
        log("Disabled")
        notify("Unlock All disabled", "Restored normal.", nil, 4)
    end

    local function enableImpl(myGen)
        if not (Registry and OwnedBitset and EquippedCodec and Store) then
            log("ABORTED: required modules missing.")
            return
        end

        collectAllRegistry()
        applyPatches()
        unlockAllInCache()

        local fs = getFieldStore()
        if fs and fs._listeners and fs._listeners.OwnedBits then
            table.insert(fs._listeners.OwnedBits, function(newBuf)
                local cur = newBuf
                for _, id in ipairs(ALL_ITEMS) do
                    if not OwnedBitset.Has(cur, id) then
                        cur = OwnedBitset.Add(cur, id)
                    end
                end
                local c = getCache()
                if c then c.OwnedBits = cur end
            end)
        end

        if fs and fs._listeners and fs._listeners.Equipped then
            table.insert(fs._listeners.Equipped, function(newBuf)
                local c = getCache()
                if not c then return end
                local buf = newBuf
                for k, fid in pairs(fakeE) do
                    local bIdx = slotToBufferIndex(k)
                    if bIdx and bIdx > 0 then
                        buf = EquippedCodec.With(buf, bIdx, fid)
                    end
                end
                for k, fid in pairs(fakeC) do
                    if not EMOTE_SET[fid] then
                        local bIdx = slotToBufferIndex(k)
                        if bIdx and bIdx > 0 then
                            buf = EquippedCodec.With(buf, bIdx, fid)
                        end
                    end
                end
                c.Equipped = buf
            end)
        end

        if fs and fs._listeners and fs._listeners.Attributes then
            table.insert(fs._listeners.Attributes, function(newAttrs)
                local c = getCache()
                if not c or not c.Attributes then return end
                for baseId, sId in pairs(fakeSkin) do
                    if not c.Attributes[baseId] then c.Attributes[baseId] = {} end
                    c.Attributes[baseId][3] = sId
                end
            end)
        end

        active = true
        log("Unlock All Ready! Single-track emote execution, natural cancel, and instant None checkmark clear.")
        notify("Unlock All enabled", #ALL_ITEMS .. " items ready!", nil, 5)
    end

    function M.Enable()
        if active then return end
        gen = gen + 1
        local myGen = gen
        task.spawn(function()
            local ok, err = pcall(enableImpl, myGen)
            if not ok then
                log("Enable failed ->", tostring(err))
            end
        end)
    end

    return M
end)()

task.spawn(pcall, GENV.YY_UnlockAll.Enable)