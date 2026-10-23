-- ============================================================
-- EMOTE DATA (for Overhaul Emotes)
-- ============================================================
local EMOTE_LIST = {
    {Name = "Addendum", ID = "98353589933644"},
    {Name = "Aerobics", ID = "70991205968842"},
    {Name = "AngelicWings", ID = "86486649250821"},
    {Name = "APose", ID = "137297087666508"},
    {Name = "AprilShower", ID = "92380165396377"},
    {Name = "AstroSlide", ID = "103095884226031"},
    {Name = "AuspiciousWell", ID = "138562011720601"},
    {Name = "AvariceLounge", ID = "71012795192901"},
    {Name = "Banger", ID = "89805417778763"},
    {Name = "BeachChairLounge", ID = "102430893964277"},
    {Name = "Beg", ID = "14364419776"},
    {Name = "Bhop", ID = "117792243648257"},
    {Name = "BobointheBox", ID = "97010515896022"},
    {Name = "BoldMarch", ID = "89755710041366"},
    {Name = "Boneless", ID = "14159896606"},
    {Name = "BoogieDown", ID = "83988952764455"},
    {Name = "Breakdown", ID = "16000647827"},
    {Name = "BringItAround", ID = "86199903463665"},
    {Name = "Broom", ID = "112692937680187"},
    {Name = "BumperKart", ID = "135065396132475"},
    {Name = "California", ID = "111882132420151"},
    {Name = "CampfireDoze", ID = "81247167265055"},
    {Name = "Caramelldansen", ID = "110855399872700"},
    {Name = "Carlton", ID = "133342001252138"},
    {Name = "CasualSurfing", ID = "101369991147366"},
    {Name = "CatDance", ID = "90029575757611"},
    {Name = "Catdown", ID = "140587543416841"},
    {Name = "Catjam", ID = "80324453439938"},
    {Name = "CatParty", ID = "93623152287516"},
    {Name = "ChristmasBoogie", ID = "79641081025427"},
    {Name = "Clap", ID = "130422022353171"},
    {Name = "ClassicDance", ID = "81884406535584"},
    {Name = "ClassicJeep", ID = "139943758174146"},
    {Name = "ClassicStride", ID = "107959449912241"},
    {Name = "ClubDance", ID = "105454357433011"},
    {Name = "CompanyMan", ID = "74991422668267"},
    {Name = "Conga", ID = "73214129581849"},
    {Name = "Crabby", ID = "133453148109220"},
    {Name = "CrouchDance", ID = "100551486224404"},
    {Name = "CuerdasDelAlma", ID = "112880689713373"},
    {Name = "CyberBroom", ID = "135077128137148"},
    {Name = "DeadBoneStride", ID = "130325042908255"},
    {Name = "Distraction", ID = "97024934103158"},
    {Name = "DuckyMarch", ID = "97000597420945"},
    {Name = "DynastyDrumming", ID = "83743598679080"},
    {Name = "Epicaricacy", ID = "90155085831620"},
    {Name = "Facepalm", ID = "101666391136986"},
    {Name = "FastFoodDelight", ID = "123151304810811"},
    {Name = "Fazbore", ID = "101602766112342"},
    {Name = "FireworkBlast", ID = "86187695224000"},
    {Name = "FlashingLights", ID = "104352652711688"},
    {Name = "Flexing", ID = "82879834895614"},
    {Name = "FlyingSleigh", ID = "138783504572427"},
    {Name = "Freestyle", ID = "105281636928075"},
    {Name = "FrightFunk", ID = "70504745132311"},
    {Name = "GalacticBound", ID = "94775974258908"},
    {Name = "Gangnam", ID = "94132011707270"},
    {Name = "GhastlyGrimoire", ID = "101017483819755"},
    {Name = "GhoulishGalleon", ID = "119226805386886"},
    {Name = "Gmod", ID = "138311974981291"},
    {Name = "GoldRitual", ID = "134809423758510"},
    {Name = "GoofyStride", ID = "105096650263337"},
    {Name = "GraveRider", ID = "72714452071290"},
    {Name = "Griddy", ID = "82579103193493"},
    {Name = "Gyrating", ID = "118544963401115"},
    {Name = "HarpRecital", ID = "102355450544398"},
    {Name = "HeadlessBaller", ID = "113685905137377"},
    {Name = "HeadlessHorseman", ID = "114920060138138"},
    {Name = "Heaventaker", ID = "112075181605701"},
    {Name = "Hired", ID = "124772196353875"},
    {Name = "HoveringCrystal", ID = "73427223913404"},
    {Name = "IceFishing", ID = "119919787915284"},
    {Name = "Infectious", ID = "96298052808131"},
    {Name = "IrishJig", ID = "127223897144273"},
    {Name = "Kickback", ID = "91560894679006"},
    {Name = "LDance", ID = "125862186100196"},
    {Name = "LemonadeStand", ID = "97893245575182"},
    {Name = "LineDance", ID = "115004542051762"},
    {Name = "LittleJiggy", ID = "124772196353875"},
    {Name = "LunarParty", ID = "110642810848080"},
    {Name = "M3GANDance", ID = "115961578572580"},
    {Name = "Macarena", ID = "117882062660271"},
    {Name = "ManyFans", ID = "92028746617057"},
    {Name = "MaracaTime", ID = "119820592973823"},
    {Name = "Marching", ID = "105574167239622"},
    {Name = "MarchShowcase", ID = "72860650157777"},
    {Name = "MariachiBand", ID = "105574167239622"},
    {Name = "Mashle", ID = "136550947878370"},
    {Name = "Moonwalk", ID = "97074392214454"},
    {Name = "Nizmoo", ID = "109398914692202"},
    {Name = "Nostalgia", ID = "89797553863845"},
    {Name = "Nutcracker", ID = "93154169858474"},
    {Name = "Outlaw", ID = "102721513920411"},
    {Name = "ParkerPride", ID = "123648977789777"},
    {Name = "PawsClaws", ID = "88836132161647"},
    {Name = "PBJT", ID = "122351687084490"},
    {Name = "PonPon", ID = "81650319096334"},
    {Name = "PoolTime", ID = "137318271200459"},
    {Name = "Popipopi", ID = "99271761094605"},
    {Name = "Popular", ID = "126396646825215"},
    {Name = "PotionMash", ID = "73605307889672"},
    {Name = "PumpItUp", ID = "113372924666104"},
    {Name = "RainingTacos", ID = "116591515901923"},
    {Name = "Rambunctious", ID = "120235017241819"},
    {Name = "Reanimated", ID = "89560208378800"},
    {Name = "Robot", ID = "119224892167747"},
    {Name = "RobotM3GAN", ID = "126906584355569"},
    {Name = "RockefellerStreet", ID = "135541441041414"},
    {Name = "Rocket", ID = "126743178095185"},
    {Name = "RockinStride", ID = "111570274714712"},
    {Name = "RowBoat", ID = "99304013507632"},
    {Name = "RudolphMount", ID = "82960040445937"},
    {Name = "RushinAround", ID = "131846902642125"},
    {Name = "RussianDance", ID = "99998524695361"},
    {Name = "SantaMech", ID = "126115378927453"},
    {Name = "ScorchedEarth", ID = "113826325934853"},
    {Name = "SeeTinh", ID = "100799217478531"},
    {Name = "SerenePerch", ID = "124466912852054"},
    {Name = "SeriousMarch", ID = "138862235352327"},
    {Name = "ShubaDance", ID = "137711127620160"},
    {Name = "SightlessDance", ID = "126396646825215"},
    {Name = "Sit", ID = "91295376169507"},
    {Name = "SkateboardStroll", ID = "86722151207683"},
    {Name = "SledDrifting", ID = "127034258162338"},
    {Name = "Sleep", ID = "120022858325689"},
    {Name = "Sleepybara", ID = "109485375637969"},
    {Name = "Smile", ID = "78030274414057"},
    {Name = "Smug", ID = "80026702634826"},
    {Name = "SnowmanConstruction", ID = "122003989330869"},
    {Name = "SnowmobileCruise", ID = "93752350043299"},
    {Name = "SolarBike", ID = "79914736566137"},
    {Name = "SolarConqueror", ID = "113826325934853"},
    {Name = "SolarSlayer", ID = "111930618562488"},
    {Name = "SpiritedAway", ID = "124678897719514"},
    {Name = "SpookyTime", ID = "81516192155106"},
    {Name = "StarPower", ID = "73819456976413"},
    {Name = "Stride", ID = "83021322945282"},
    {Name = "SummerDays", ID = "113526417860482"},
    {Name = "SwagWalk", ID = "80539291158095"},
    {Name = "Tank", ID = "121450786846620"},
    {Name = "TexasStyle", ID = "132729415704029"},
    {Name = "Thriller", ID = "110141849317544"},
    {Name = "ToyTrainRide", ID = "105484146283074"},
    {Name = "TPose", ID = "74295023461454"},
    {Name = "TurkeyJockey", ID = "80524413582849"},
    {Name = "TurtleHobble", ID = "92110518228602"},
    {Name = "Twist", ID = "127123417439136"},
    {Name = "WerewolfHowl", ID = "104147836673711"},
    {Name = "Wess", ID = "82965081375297"},
    {Name = "WindupDance", ID = "122919501717227"},
    {Name = "WindUpPose", ID = "125990713228297"},
    {Name = "WinterRide", ID = "85255422433919"},
    {Name = "Writhing", ID = "118337616190939"},
    {Name = "Xylobone", ID = "78034310760809"},
    {Name = "ZenSerenity", ID = "78776853614910"},
    {Name = "ZombieStride", ID = "125497596837433"},
}

-- ===== Overhaul Emotes (ORIGINAL SCRIPT LOGIC) =====
local secOverhaul = Tabs.EmoteFunctions:AddSection("Overhaul Emotes", "solar/star-bold")

secOverhaul:AddParagraph({
    Title = "⚠️ WARNING!",
    Content = "This only works perfectly with Overhaul Emotes and not the old ones that already exists in Legacy GameMode. Other players can see the animation/emote. Supports PC (keybind) and Mobile (UI button).",
})

-- Emote List (searchable dropdown)
local emoteNames = {}
for _, emote in ipairs(EMOTE_LIST) do
    table.insert(emoteNames, emote.Name)
end

local selectedEmoteName = EMOTE_LIST[1].Name
local selectedEmoteID = EMOTE_LIST[1].ID

secOverhaul:AddDropdown("OverhaulEmoteDropdown", {
    Title = "Emotes List",
    Icon = "solar/list-bold",
    Values = emoteNames,
    Default = emoteNames[1],
    Description = "Search or scroll to select an emote",
    Callback = function(v)
        selectedEmoteName = v
        for _, emote in ipairs(EMOTE_LIST) do
            if emote.Name == v then
                selectedEmoteID = emote.ID
                break
            end
        end
    end,
})

secOverhaul:AddDivider()

-- Keybind input
local overhaulKeybind = "E"

secOverhaul:AddInput("OverhaulKeybindInput", {
    Title = "Keybind (Only for PC)",
    Icon = "solar/keyboard-bold",
    Placeholder = "E",
    Default = "E",
    Callback = function(v)
        if v and v ~= "" then
            overhaulKeybind = v:gsub("^%s*", ""):gsub("%s*$", ""):upper()
            Notify("Keybind Updated", "Overhaul Emote keybind set to: " .. overhaulKeybind, "Success", "solar/keyboard-bold", 2)
        end
    end,
})

secOverhaul:AddDivider()

-- ===== ORIGINAL OVERHAUL EMOTE SCRIPT LOGIC =====
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local isOverhaulActive = false
local overhaulAnimTrack = nil
local overhaulAnimBlockConnection = nil
local overhaulLookYConnection = nil

-- Detect device
local function isMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled
end

-- Animation functions
local function stopOverhaulAnimation()
    if overhaulAnimTrack then
        overhaulAnimTrack:Stop()
        overhaulAnimTrack = nil
    end
end

local function playOverhaulAnimationLoop()
    while Character and Character.Parent and isOverhaulActive do
        local humanoid = Character:FindFirstChild("Humanoid")
        if not humanoid then break end
        local animator = humanoid:FindFirstChild("Animator")
        if not animator then break end
        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
            if track.Name == "ForceAnimation" then track:Stop() end
        end
        local animation = Instance.new("Animation")
        animation.AnimationId = "rbxassetid://" .. selectedEmoteID
        animation.Name = "ForceAnimation"
        overhaulAnimTrack = animator:LoadAnimation(animation)
        overhaulAnimTrack.Looped = true
        overhaulAnimTrack:Play()
        while Character and Character.Parent and isOverhaulActive and overhaulAnimTrack and overhaulAnimTrack.IsPlaying do
            task.wait(0.1)
        end
        task.wait(0.1)
    end
    stopOverhaulAnimation()
end

-- EmoteSpeed
local function createOverhaulEmoteSpeed()
    local myName = LocalPlayer.Name
    local myPlayer = workspace.Game.Players:FindFirstChild(myName)
    if myPlayer then
        local statChanges = myPlayer:FindFirstChild("StatChanges")
        if not statChanges then
            statChanges = Instance.new("Folder")
            statChanges.Name = "StatChanges"
            statChanges.Parent = myPlayer
        end
        local speed = statChanges:FindFirstChild("Speed")
        if not speed then
            speed = Instance.new("Folder")
            speed.Name = "Speed"
            speed.Parent = statChanges
        end
        local emoteSpeed = speed:FindFirstChild("EmoteSpeed")
        if not emoteSpeed then
            emoteSpeed = Instance.new("NumberValue")
            emoteSpeed.Name = "EmoteSpeed"
            emoteSpeed.Value = 1
            emoteSpeed.Parent = speed
        else
            emoteSpeed.Value = 1
        end
        return true
    end
    return false
end

local function removeOverhaulEmoteSpeed()
    local myName = LocalPlayer.Name
    local myPlayer = workspace.Game.Players:FindFirstChild(myName)
    if myPlayer then
        local statChanges = myPlayer:FindFirstChild("StatChanges")
        if statChanges then
            local speed = statChanges:FindFirstChild("Speed")
            if speed then
                local emoteSpeed = speed:FindFirstChild("EmoteSpeed")
                if emoteSpeed then emoteSpeed:Destroy() end
            end
        end
    end
end

-- Block Crouch/Slide animations
local function iniciarBloqueioOverhaulAnimacoes()
    if not Character then return end
    local humanoid = Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    local animator = humanoid:FindFirstChild("Animator")
    if not animator then return end
    local animsParaRemover = {"Crouch", "Slide"}
    local function verificarETreinarTrack(track)
        if track and track.Stop then
            local anim = track.Animation
            if anim then
                local nome = anim.Name or ""
                local id = anim.AnimationId or ""
                for _, palavra in pairs(animsParaRemover) do
                    if string.find(nome, palavra) or string.find(id, palavra) then
                        track:Stop()
                        track:Destroy()
                        break
                    end
                end
            end
        end
    end
    for _, track in pairs(animator:GetPlayingAnimationTracks()) do
        verificarETreinarTrack(track)
    end
    for _, palavra in pairs(animsParaRemover) do
        for _, obj in pairs(humanoid:GetChildren()) do
            if obj:IsA("Animation") and (string.find(obj.Name, palavra) or string.find(obj.AnimationId or "", palavra)) then
                obj:Destroy()
            end
        end
    end
    if overhaulAnimBlockConnection then overhaulAnimBlockConnection:Disconnect() end
    overhaulAnimBlockConnection = animator.AnimationPlayed:Connect(verificarETreinarTrack)
end

local function pararBloqueioOverhaulAnimacoes()
    if overhaulAnimBlockConnection then
        overhaulAnimBlockConnection:Disconnect()
        overhaulAnimBlockConnection = nil
    end
end

-- Force LookY
local function iniciarForcadorOverhaulLookY()
    if overhaulLookYConnection then overhaulLookYConnection:Disconnect() end
    local function forceAttribute()
        pcall(function()
            if LocalPlayer:GetAttribute("LookY") ~= nil then
                LocalPlayer:SetAttribute("LookY", 0)
                if rawset then
                    local attrs = LocalPlayer:FindFirstChild("Attributes")
                    if attrs then rawset(attrs, "LookY", 0) end
                end
            end
            if LocalPlayer.Character then
                LocalPlayer.Character:SetAttribute("LookY", 0)
            end
        end)
    end
    overhaulLookYConnection = RunService.Heartbeat:Connect(function()
        if isOverhaulActive then forceAttribute() end
    end)
    forceAttribute()
end

local function pararForcadorOverhaulLookY()
    if overhaulLookYConnection then
        overhaulLookYConnection:Disconnect()
        overhaulLookYConnection = nil
    end
end

-- ShiftLock
local function ativarOverhaulShiftLock()
    local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
    if playerScripts then
        local shiftLock = playerScripts:FindFirstChild("ShiftLockEnabled")
        if shiftLock and shiftLock:IsA("BoolValue") then
            shiftLock.Value = true
            return true
        end
    end
    return false
end

local function desativarOverhaulShiftLock()
    local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
    if playerScripts then
        local shiftLock = playerScripts:FindFirstChild("ShiftLockEnabled")
        if shiftLock and shiftLock:IsA("BoolValue") then
            shiftLock.Value = false
            return true
        end
    end
    return false
end

-- Camera configs
local function aplicarOverhaulConfiguracoesAtivacao()
    local player = LocalPlayer
    local targetPlayer = workspace.Game.Players:FindFirstChild(player.Name)
    if not targetPlayer then
        for _, otherPlayer in pairs(workspace.Game.Players:GetChildren()) do
            if otherPlayer.Name ~= player.Name then
                targetPlayer = otherPlayer
                break
            end
        end
    end
    if targetPlayer then
        player.CameraMaxZoomDistance = 10
        player.CameraMinZoomDistance = 10
        player.CameraMode = Enum.CameraMode.Classic
        if player:FindFirstChild("PlayerScripts") then
            local mouseLockOffset = player.PlayerScripts:FindFirstChild("MouseLockOffset")
            if mouseLockOffset then mouseLockOffset.Value = Vector3.new(0,0,0) end
        end
        targetPlayer:SetAttribute("FirstPerson", false)
    end
    ativarOverhaulShiftLock()
end

local function aplicarOverhaulConfiguracoesDesativacao()
    local player = LocalPlayer
    local targetPlayer = workspace.Game.Players:FindFirstChild(player.Name)
    if not targetPlayer then
        for _, otherPlayer in pairs(workspace.Game.Players:GetChildren()) do
            if otherPlayer.Name ~= player.Name then
                targetPlayer = otherPlayer
                break
            end
        end
    end
    if targetPlayer then
        player.CameraMaxZoomDistance = 0.502
        player.CameraMinZoomDistance = 0.5
        player.CameraMode = Enum.CameraMode.LockFirstPerson
        targetPlayer:SetAttribute("FirstPerson", true)
    end
    desativarOverhaulShiftLock()
end

-- Toggle everything
local function activateOverhaulEverything()
    if isOverhaulActive then return end
    isOverhaulActive = true
    task.spawn(playOverhaulAnimationLoop)
    task.spawn(function()
        local attempts = 0
        while isOverhaulActive and attempts < 20 do
            if createOverhaulEmoteSpeed() then break end
            attempts = attempts + 1
            task.wait(1)
        end
    end)
    iniciarBloqueioOverhaulAnimacoes()
    iniciarForcadorOverhaulLookY()
    aplicarOverhaulConfiguracoesAtivacao()
    Notify("Overhaul Emote", selectedEmoteName .. " activated!", "Success", "solar/star-bold", 3)
end

local function deactivateOverhaulEverything()
    if not isOverhaulActive then return end
    isOverhaulActive = false
    stopOverhaulAnimation()
    removeOverhaulEmoteSpeed()
    pararBloqueioOverhaulAnimacoes()
    pararForcadorOverhaulLookY()
    aplicarOverhaulConfiguracoesDesativacao()
    Notify("Overhaul Emote", selectedEmoteName .. " stopped!", "Info", "solar/music-bold", 2)
end

local function toggleOverhaulScript()
    if isOverhaulActive then deactivateOverhaulEverything() else activateOverhaulEverything() end
end

-- Apply button
secOverhaul:AddButton({
    Title = "Apply the Emote!",
    Icon = "solar/play-bold",
    Callback = function()
        toggleOverhaulScript()
    end,
})

-- ===== MOBILE GUI (COLA BUTTON) =====
if isMobile() then
    task.spawn(function()
        local guiPlayer = LocalPlayer:WaitForChild("PlayerGui")
        
        -- Remove old GUIs
        for _, v in pairs({"CrouchGui", "EmoteGui", "LeaderboardGui", "ColaGui", "EmoteNumGui", "FlyToggleGUI"}) do
            if guiPlayer:FindFirstChild(v) then
                guiPlayer[v]:Destroy()
            end
        end
        
        -- Scale function
        local function addScale(gui)
            local s = Instance.new("UIScale")
            local cam = workspace.CurrentCamera
            local function update()
                s.Scale = math.clamp(cam.ViewportSize.Y / 720, 0.85, 1.35)
            end
            update()
            cam:GetPropertyChangedSignal("ViewportSize"):Connect(update)
            s.Parent = gui
        end
        
        -- Drag function
        local function drag(button)
            local dragging = false
            local dragInput
            local dragStart
            local startPos
        
            button.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    dragInput = input
                    dragStart = input.Position
                    startPos = button.Position
                end
            end)
        
            button.InputChanged:Connect(function(input)
                if input == dragInput and dragging then
                    local delta = input.Position - dragStart
                    button.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end)
        
            UserInputService.InputEnded:Connect(function(input)
                if input == dragInput then
                    dragging = false
                    dragInput = nil
                end
            end)
        end
        
        -- Create Cola GUI
        local colaGui = Instance.new("ScreenGui")
        colaGui.Name = "ColaGui"
        colaGui.ResetOnSpawn = false
        colaGui.Parent = guiPlayer
        addScale(colaGui)
        
        local colaBtn = Instance.new("ImageButton", colaGui)
        colaBtn.BackgroundTransparency = 1
        colaBtn.Size = UDim2.new(0, 80, 0, 80)
        colaBtn.Position = UDim2.new(0.5, -40, 0.5, -40)
        colaBtn.Image = "rbxassetid://16803802267"
        
        local colaIcon = Instance.new("ImageLabel", colaBtn)
        colaIcon.BackgroundTransparency = 1
        colaIcon.Size = UDim2.new(0.75, 0, 0.75, 0)
        colaIcon.Position = UDim2.new(0.125, 0, 0.125, 0)
        colaIcon.Image = "rbxassetid://119701596834118"
        colaIcon.ImageTransparency = 0.6
        
        colaBtn.MouseButton1Click:Connect(toggleOverhaulScript)
        drag(colaBtn)
    end)
end

-- ===== PC KEYBIND =====
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    local targetKey = nil
    pcall(function()
        local keyStr = overhaulKeybind:upper()
        if keyStr == "SPACEBAR" then
            targetKey = Enum.KeyCode.Space
        else
            targetKey = Enum.KeyCode[keyStr]
        end
    end)
    if targetKey and input.KeyCode == targetKey then
        toggleOverhaulScript()
    end
end)

-- Character monitor
LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    if isOverhaulActive then
        stopOverhaulAnimation()
        pararBloqueioOverhaulAnimacoes()
        task.wait(0.5)
        if isOverhaulActive then
            task.spawn(playOverhaulAnimationLoop)
            iniciarBloqueioOverhaulAnimacoes()
        end
    end
end)

secOverhaul:AddDivider()
