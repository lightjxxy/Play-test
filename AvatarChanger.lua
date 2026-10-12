-- ══════════════════════════════════════════════════════════════
--  AVATAR CHANGER CONFIGURATION
-- ══════════════════════════════════════════════════════════════
local DEFAULT_USERNAME = "Omitfr"        -- Username or UserId to copy
local TOGGLE_KEY       = Enum.KeyCode.E  -- Key to toggle on/off
-- ══════════════════════════════════════════════════════════════

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local StarterGui        = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title    = title,
            Text     = text,
            Duration = 4,
        })
    end)
end

-- ── State ──────────────────────────────────────────────────────
local avatarChangerEnabled     = false
local avatarAppliedOnce        = false
local targetUserId             = DEFAULT_USERNAME
local avatarCharacterAddedConn = nil
local attributeConnsHS         = {}
local renderConn               = nil
local rigsWatcherConns         = {}
local appliedDupeInstances     = setmetatable({}, { __mode = "k" })

-- ── Hidden-accessories storage folder ─────────────────────────
local storageFolder = ReplicatedStorage:FindFirstChild("HiddenAccessories")
if not storageFolder then
    storageFolder = Instance.new("Folder")
    storageFolder.Name   = "HiddenAccessories"
    storageFolder.Parent = ReplicatedStorage
end

-- ── Attachment / accessory maps ────────────────────────────────
local ACCESSORY_ATTACHMENT_MAP = {
    [Enum.AccessoryType.Hat]      = { bodyPart = "Head",  attachmentName = "HatAttachment" },
    [Enum.AccessoryType.Hair]     = { bodyPart = "Head",  attachmentName = "HairAttachment" },
    [Enum.AccessoryType.Face]     = { bodyPart = "Head",  attachmentName = "FaceFrontAttachment" },
    [Enum.AccessoryType.Neck]     = { bodyPart = "Torso", attachmentName = "NeckAttachment" },
    [Enum.AccessoryType.Shoulder] = { bodyPart = "Torso", attachmentName = "RightShoulderAttachment" },
    [Enum.AccessoryType.Front]    = { bodyPart = "Torso", attachmentName = "FrontAttachment" },
    [Enum.AccessoryType.Back]     = { bodyPart = "Torso", attachmentName = "BackAttachment" },
    [Enum.AccessoryType.Waist]    = { bodyPart = "Torso", attachmentName = "WaistCenterAttachment" },
    [Enum.AccessoryType.Eyebrow]  = { bodyPart = "Head",  attachmentName = "FaceFrontAttachment" },
    [Enum.AccessoryType.Eyelash]  = { bodyPart = "Head",  attachmentName = "FaceFrontAttachment" },
    [Enum.AccessoryType.TShirt]   = { bodyPart = "Torso", attachmentName = "BodyFrontAttachment" },
    [Enum.AccessoryType.Shirt]    = { bodyPart = "Torso", attachmentName = "BodyFrontAttachment" },
    [Enum.AccessoryType.Pants]    = { bodyPart = "Torso", attachmentName = "BodyFrontAttachment" },
    [Enum.AccessoryType.Unknown]  = { bodyPart = "Head",  attachmentName = "HatAttachment" },
}

local ATTACHMENT_TO_BODYPART = {
    HatAttachment           = "Head",
    HairAttachment          = "Head",
    FaceFrontAttachment     = "Head",
    FaceCenterAttachment    = "Head",
    NeckAttachment          = "Torso",
    BodyFrontAttachment     = "Torso",
    BodyBackAttachment      = "Torso",
    FrontAttachment         = "Torso",
    BackAttachment          = "Torso",
    WaistCenterAttachment   = "Torso",
    WaistFrontAttachment    = "Torso",
    WaistBackAttachment     = "Torso",
    LeftCollarAttachment    = "Torso",
    RightCollarAttachment   = "Torso",
    LeftShoulderAttachment  = "Left Arm",
    RightShoulderAttachment = "Right Arm",
    LeftGripAttachment      = "Left Arm",
    RightGripAttachment     = "Right Arm",
}

local R6_ATTACHMENT_OFFSETS = {
    HatAttachment           = CFrame.new(0,    0.5,  0),
    HairAttachment          = CFrame.new(0,    0.5,  0),
    FaceFrontAttachment     = CFrame.new(0,    0,   -0.6),
    FaceCenterAttachment    = CFrame.new(0,    0,   -0.6),
    NeckAttachment          = CFrame.new(0,    1,    0),
    RightShoulderAttachment = CFrame.new(1,    0.5,  0),
    LeftShoulderAttachment  = CFrame.new(-1,   0.5,  0),
    RightGripAttachment     = CFrame.new(1,   -1,    0),
    LeftGripAttachment      = CFrame.new(-1,  -1,    0),
    FrontAttachment         = CFrame.new(0,    0.5, -0.5),
    BackAttachment          = CFrame.new(0,    0.5,  0.5),
    BodyBackAttachment      = CFrame.new(0,    0.5,  0.5),
    WaistCenterAttachment   = CFrame.new(0,   -1,    0),
    WaistFrontAttachment    = CFrame.new(0,   -1,   -0.5),
    WaistBackAttachment     = CFrame.new(0,   -1,    0.5),
    LeftCollarAttachment    = CFrame.new(-0.5, 1,    0),
    RightCollarAttachment   = CFrame.new(0.5,  1,    0),
    BodyFrontAttachment     = CFrame.new(0,    0,   -0.5),
}

-- ── Helpers ────────────────────────────────────────────────────
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
    [Enum.AccessoryType.Hat]     = true,
    [Enum.AccessoryType.Hair]    = true,
    [Enum.AccessoryType.Face]    = true,
    [Enum.AccessoryType.Eyebrow] = true,
    [Enum.AccessoryType.Eyelash] = true,
    [Enum.AccessoryType.Unknown] = true,
}

local function isHeadAccessory(accessory, headPart)
    local ok, accessoryType = pcall(function() return accessory.AccessoryType end)
    if ok and accessoryType and HEAD_ACCESSORY_TYPES[accessoryType] then return true end
    local handle = accessory:FindFirstChild("Handle")
    if not handle then return false end
    for _, joint in ipairs(handle:GetChildren()) do
        if (joint:IsA("Weld") or joint:IsA("Motor6D")) then
            if joint.Part0 == headPart or joint.Part1 == headPart then return true end
        end
    end
    local attachment = handle:FindFirstChildWhichIsA("Attachment")
    if attachment and ATTACHMENT_TO_BODYPART[attachment.Name] == "Head" then return true end
    if (handle.Position - headPart.Position).Magnitude < 4 then return true end
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
        if LocalPlayer.Character then table.insert(targets, LocalPlayer.Character) end
        for _, folder in ipairs(getActiveRigsFolders()) do
            local rig = folder:FindFirstChild(LocalPlayer.Name)
            if rig and rig:IsA("Model") then table.insert(targets, rig) end
        end
        for _, character in ipairs(targets) do
            local head = character:FindFirstChild("Head")
            if head then
                local distance = (camera.CFrame.Position - head.Position).Magnitude
                local v = (distance < FIRST_PERSON_DISTANCE) and 1 or 0
                head.Transparency = v
                head.LocalTransparencyModifier = v
                local face = head:FindFirstChild("face")
                if face and face:IsA("Decal") then face.Transparency = v end
                setHeadAccessoriesTransparency(character, head, v)
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
        local fetchOk, fetched = pcall(function()
            return Players:GetHumanoidDescriptionFromUserId(userId)
        end)
        local desc = (fetchOk and fetched) and fetched or Instance.new("HumanoidDescription")
        return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R6)
    end)
    if not ok or not model then
        local ok2, model2 = pcall(function() return Players:CreateHumanoidModelFromUserId(userId) end)
        if ok2 and model2 then return model2 end
        return nil
    end
    return model
end

local function getOrCreateAttachment(bodyPart, attachmentName)
    local attachment = bodyPart:FindFirstChild(attachmentName)
    if attachment and attachment:IsA("Attachment") then return attachment end
    local offset = R6_ATTACHMENT_OFFSETS[attachmentName]
    if not offset then return nil end
    attachment = Instance.new("Attachment")
    attachment.Name   = attachmentName
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
    if direct and direct:IsA("Attachment") then return direct, expected end
    return nil, nil
end

local function weldAccessoryByType(character, accessoryClone)
    local handle = accessoryClone:FindFirstChild("Handle")
    if not handle then return false end
    local accessoryType = accessoryClone.AccessoryType
    local mapping = ACCESSORY_ATTACHMENT_MAP[accessoryType] or ACCESSORY_ATTACHMENT_MAP[Enum.AccessoryType.Unknown]
    local handleAttachment, attachmentName = findR6HandleAttachment(handle, mapping)
    if not handleAttachment then
        attachmentName   = mapping.attachmentName
        handleAttachment = Instance.new("Attachment")
        handleAttachment.Name   = attachmentName
        handleAttachment.CFrame = CFrame.new()
        handleAttachment.Parent = handle
    end
    local bodyPartName = ATTACHMENT_TO_BODYPART[attachmentName] or mapping.bodyPart
    local bodyPart     = character:FindFirstChild(bodyPartName) or character:FindFirstChild("Head")
    if not bodyPart then return false end
    local bodyAttachment = getOrCreateAttachment(bodyPart, attachmentName)
    if not bodyAttachment then return false end
    handle.CFrame = bodyPart.CFrame * bodyAttachment.CFrame * handleAttachment.CFrame:Inverse()
    local weld  = Instance.new("Weld")
    weld.Name   = "AccessoryWeld"
    weld.Part0  = bodyPart
    weld.Part1  = handle
    weld.C0     = bodyAttachment.CFrame
    weld.C1     = handleAttachment.CFrame
    weld.Parent = handle
    return true
end

local function transferHeadAppearance(character, refModel)
    local refHead    = refModel:FindFirstChild("Head")
    local targetHead = character:FindFirstChild("Head")
    if not refHead or not targetHead then return end
    local existingMesh = targetHead:FindFirstChildWhichIsA("SpecialMesh")
    if existingMesh then existingMesh:Destroy() end
    local existingFace = targetHead:FindFirstChild("face")
    if existingFace and existingFace:IsA("Decal") then existingFace:Destroy() end
    local refMesh = refHead:FindFirstChildWhichIsA("SpecialMesh")
    if refMesh then refMesh:Clone().Parent = targetHead end
    local refFace = refHead:FindFirstChild("face")
    if refFace and refFace:IsA("Decal") then refFace:Clone().Parent = targetHead end
    if refHead:IsA("BasePart") and targetHead:IsA("BasePart") then
        targetHead.Color = refHead.Color
    end
end

local function transferCosmetics(character, refModel)
    transferHeadAppearance(character, refModel)
    for _, child in ipairs(refModel:GetChildren()) do
        if child:IsA("CharacterMesh") or child:IsA("Shirt") or child:IsA("Pants")
            or child:IsA("ShirtGraphic") or child:IsA("BodyColors") then
            child:Clone().Parent = character
        elseif child:IsA("Accessory") or child:IsA("Hat") then
            local clone = child:Clone()
            clone.Parent = character
            weldAccessoryByType(character, clone)
        end
    end
end

local function convertToUserId(input)
    local numericId = tonumber(input)
    if numericId then return numericId end
    local success, result = pcall(function() return Players:GetUserIdFromNameAsync(input) end)
    if success and result then return result end
    return nil
end

local function applyAvatarFromInput(character, input)
    if not character then return end
    local id = convertToUserId(input)
    if not id then return end
    local refModel = buildReferenceModel(id)
    if not refModel then return end
    local okClear    = pcall(clearOldCosmetics, character)
    local okTransfer = pcall(transferCosmetics, character, refModel)
    refModel:Destroy()
    if okClear and okTransfer then
        if renderConn == nil then startRenderLoop() end
    end
end

local function disconnectAttributeWatchers()
    for _, conn in ipairs(attributeConnsHS) do conn:Disconnect() end
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
        if rig then applyToDuplicateIfNeeded(rig) end
    end
end

local function disconnectDupeWatchers()
    for _, conn in ipairs(rigsWatcherConns) do conn:Disconnect() end
    rigsWatcherConns = {}
end

local function hookRigsFolder(folder)
    table.insert(rigsWatcherConns, folder.ChildAdded:Connect(function(child)
        if not avatarChangerEnabled then return end
        if child.Name ~= LocalPlayer.Name then return end
        applyToDuplicateIfNeeded(child)
    end))
end

local function watchDupeFolders()
    disconnectDupeWatchers()
    for _, rigsFolder in ipairs(getActiveRigsFolders()) do hookRigsFolder(rigsFolder) end
    table.insert(rigsWatcherConns, workspace.ChildAdded:Connect(function(child)
        if not avatarChangerEnabled then return end
        if child.Name ~= "Rigs" then return end
        hookRigsFolder(child)
        scanKnownDupeFolders()
    end))
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
        notify("Avatar Changer", "Enabled — copying " .. DEFAULT_USERNAME)
    else
        notify("Avatar Changer", "Disabled")
    end
end

-- ── E key toggle ───────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == TOGGLE_KEY then
        setAvatarChanger(not avatarChangerEnabled)
    end
end)

-- ── Auto-enable on execution ───────────────────────────────────
setAvatarChanger(true)
