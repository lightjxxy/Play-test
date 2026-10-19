local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local guiPlayer = player:WaitForChild("PlayerGui")

local customAnimationId = "rbxassetid://113685905137377"

local blockedAnimationIds = {
	["11544336826"] = true,
	["8734717021"] = true,
	["8734714115"] = true,
	["8734713502"] = true,
	["9873188504"] = true,
	["9873601392"] = true,
	["9873600445"] = true,
	["10242911213"] = true,
	["11307978018"] = true,
	["9381947548"] = true,
	["9224101460"] = true,
	["9381958566"] = true,
	["9381957206"] = true,
	["10219164515"] = true
}

_G.GuiPosition = _G.GuiPosition or {}
_G.GuiLock = _G.GuiLock or {}

local active = false
local connections = {}
local myAnimTrack = nil
local previousFirstPerson = false

local function getPlayerFolder()
	local success, playerFolder = pcall(function()
		return Workspace:WaitForChild("Game", 5)
			:WaitForChild("Players", 5)
			:WaitForChild("4NMJJANG", 5)
	end)
	if success and playerFolder then
		return playerFolder
	end
	return nil
end

local function clearConnections()
	for _, c in ipairs(connections) do
		c:Disconnect()
	end
	connections = {}
end

local function setHudVisibility(visible)
	local success, hud = pcall(function()
		return guiPlayer:WaitForChild("HUD", 5)
	end)
	if not (success and hud) then return end

	local right = hud:FindFirstChild("Right")
	if right then
		local mobile = right:FindFirstChild("Mobile")
		if mobile then
			mobile.Visible = visible
		end
	end

	local center = hud:FindFirstChild("Center")
	if center then
		center.Visible = visible
	end
end

local function removeEmoteSpeed()
	local playerFolder = getPlayerFolder()
	if not playerFolder then return end

	local statChanges = playerFolder:FindFirstChild("StatChanges")
	if not statChanges then return end

	local speedFolder = statChanges:FindFirstChild("Speed")
	if not speedFolder then return end

	local emoteSpeed = speedFolder:FindFirstChild("EmoteSpeed")
	if emoteSpeed then
		emoteSpeed:Destroy()
	end
end

local function activateAll(character)
	clearConnections()

	local playerFolder = getPlayerFolder()

	if playerFolder then
		previousFirstPerson = playerFolder:GetAttribute("FirstPerson") == true
		
		table.insert(connections, RunService.Heartbeat:Connect(function()
			playerFolder:SetAttribute("FirstPerson", false)
			player.CameraMode = Enum.CameraMode.Classic
		end))
	end

	local playerScripts = player:FindFirstChild("PlayerScripts")
	if playerScripts then
		local shiftLockEnabled = playerScripts:FindFirstChild("ShiftLockEnabled")
		if shiftLockEnabled and shiftLockEnabled.Value ~= true then
			shiftLockEnabled.Value = true
		end

		local mouseLockOffset = playerScripts:FindFirstChild("MouseLockOffset")
		if mouseLockOffset then
			table.insert(connections, RunService.Heartbeat:Connect(function()
				if mouseLockOffset.Value ~= Vector3.new(0, 0, 0) then
					mouseLockOffset.Value = Vector3.new(0, 0, 0)
				end
			end))
		end
	end

	if playerFolder then
		local statChanges = playerFolder:FindFirstChild("StatChanges")
		if statChanges then
			local speedFolder = statChanges:FindFirstChild("Speed")
			if speedFolder then
				local existing = speedFolder:FindFirstChild("EmoteSpeed")
				if not existing then
					local emoteSpeed = Instance.new("NumberValue")
					emoteSpeed.Name = "EmoteSpeed"
					emoteSpeed.Value = 1
					emoteSpeed.Parent = speedFolder
				else
					existing.Value = 1
				end
			end
		end
	end

	player.CameraMode = Enum.CameraMode.Classic
	player.CameraMaxZoomDistance = 10
	player.CameraMinZoomDistance = 10

	setHudVisibility(false)

	local humanoid = character:WaitForChild("Humanoid")
	local animator = humanoid:WaitForChild("Animator")

	local function checkAndStopTrack(track)
		if track and track.Animation then
			local id = track.Animation.AnimationId:match("%d+")
			if id and blockedAnimationIds[id] then
				track:Stop(0)
			end
		end
	end

	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		checkAndStopTrack(track)
	end

	table.insert(connections, animator.AnimationPlayed:Connect(function(track)
		checkAndStopTrack(track)
	end))

	local animation = Instance.new("Animation")
	animation.AnimationId = customAnimationId
	myAnimTrack = animator:LoadAnimation(animation)
	myAnimTrack.Priority = Enum.AnimationPriority.Action4
	myAnimTrack.Looped = true
	myAnimTrack:Play()
end

local function deactivateAll()
	clearConnections()

	if myAnimTrack then
		myAnimTrack:Stop(0.15)
		myAnimTrack = nil
	end

	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local currentState = humanoid:GetState()
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			task.defer(function()
				humanoid:ChangeState(currentState)
			end)
		end
	end

	removeEmoteSpeed()
	setHudVisibility(true)

	local playerFolder = getPlayerFolder()
	local playerScripts = player:FindFirstChild("PlayerScripts")
	local mouseLockOffset = playerScripts and playerScripts:FindFirstChild("MouseLockOffset")

	if not previousFirstPerson then
		-- It was on third person
		if mouseLockOffset then
			mouseLockOffset.Value = Vector3.new(2, 0.5, 0)
		end
		player.CameraMinZoomDistance = 6
		player.CameraMaxZoomDistance = 6
		player.CameraMode = Enum.CameraMode.Classic
		if playerFolder then
			playerFolder:SetAttribute("FirstPerson", false)
		end
	else
		-- It was on first person
		if mouseLockOffset then
			mouseLockOffset.Value = Vector3.new(0, 0, 0)
		end
		player.CameraMode = Enum.CameraMode.LockFirstPerson
		player.CameraMinZoomDistance = 0.5
		player.CameraMaxZoomDistance = 0.5
		if playerFolder then
			playerFolder:SetAttribute("FirstPerson", true)
		end
	end
end

-- GUI

if guiPlayer:FindFirstChild("EmoteGui") then
	guiPlayer["EmoteGui"]:Destroy()
end

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

local function holdSystem(button, callback, name)
	local HoldTime = 5
	local locked = _G.GuiLock[name] or false
	local holding = false
	local holdStart = 0
	local holdTriggered = false

	button.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		holding = true
		holdStart = tick()
		holdTriggered = false
		if callback then callback() end
	end)

	button.InputEnded:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		holding = false
	end)

	RunService.RenderStepped:Connect(function()
		if holding and not holdTriggered then
			if tick() - holdStart >= HoldTime then
				holdTriggered = true
				locked = not locked
				_G.GuiLock[name] = locked
			end
		end
	end)

	return function()
		return locked
	end
end

local function drag(button, isLocked, name)
	local dragging = false
	local dragInput
	local dragStart
	local startPos

	if _G.GuiPosition[name] then
		button.Position = _G.GuiPosition[name]
	end

	button.InputBegan:Connect(function(input)
		if isLocked and isLocked() then return end
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
			_G.GuiPosition[name] = button.Position
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input == dragInput then
			dragging = false
			dragInput = nil
		end
	end)
end

local emoteGui = Instance.new("ScreenGui")
emoteGui.Name = "EmoteGui"
emoteGui.ResetOnSpawn = false
emoteGui.Parent = guiPlayer
addScale(emoteGui)

local emoteBtn = Instance.new("ImageButton", emoteGui)
emoteBtn.BackgroundTransparency = 1
emoteBtn.Size = UDim2.new(0, 80, 0, 80)
emoteBtn.AnchorPoint = Vector2.new(0, 0.5)
emoteBtn.Position = UDim2.new(0, 20, 0.5, 0)
emoteBtn.Image = "rbxassetid://16803802267"

local emoteIcon = Instance.new("ImageLabel", emoteBtn)
emoteIcon.BackgroundTransparency = 1
emoteIcon.Size = UDim2.new(0.85, 0, 0.85, 0)
emoteIcon.Position = UDim2.new(0.075, 0, 0.075, 0)
emoteIcon.Image = "rbxassetid://93850065438718"
emoteIcon.ImageTransparency = 0.6

local emoteLock = holdSystem(emoteBtn, nil, "emote")
drag(emoteBtn, emoteLock, "emote")

local isDragging = false
local dragMoved = false

emoteBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		isDragging = false
		dragMoved = false
	end
end)

emoteBtn.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragMoved = true
	end
end)

emoteBtn.InputEnded:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
	if emoteLock() then return end
	if dragMoved then return end

	if not active then
		active = true
		emoteIcon.ImageTransparency = 0
		local character = player.Character or player.CharacterAdded:Wait()
		activateAll(character)
	else
		active = false
		emoteIcon.ImageTransparency = 0.6
		deactivateAll()
	end
end)

player.CharacterAdded:Connect(function(character)
	if active then
		activateAll(character)
	end
end)
