local v_u_1 = game:GetService("UserInputService")
local v_u_2 = game:GetService("RunService")
local v_u_3 = game:GetService("Players")
local v4 = game:GetService("HttpService")
local v_u_ContextActionService = game:GetService("ContextActionService")
local v_u_OriginalMouseIconEnabled = v_u_1.MouseIconEnabled
local v_u_5 = UserSettings():GetService("UserGameSettings")
local v_u_6 = math.exp
local v_u_7 = math.sin
local v_u_8 = math.cos
local v_u_9 = math.atan2
local v_u_10 = math.abs
local v_u_11 = math.clamp
local v_u_12 = v_u_3.LocalPlayer
local v_u_13 = v_u_12:WaitForChild("PlayerGui"):WaitForChild("Settings"):WaitForChild("Sensitivity")
local v_u_14 = workspace.CurrentCamera
local v_u_15 = v_u_12.Character or v_u_12.CharacterAdded:Wait()
local v_u_16 = v_u_12:WaitForChild("PlayerGui"):WaitForChild("Cursor"):WaitForChild("Cursor")
local v_u_17 = v_u_16.BackgroundTransparency
local v_u_18 = "CustomCameraUpdate_" .. v4:GenerateGUID(false)
local v_u_19 = Enum.KeyCode.Z
local v_u_20 = v_u_14.FieldOfView
local v_u_21 = v_u_14.FieldOfView
local v_u_22 = {
	[Enum.KeyCode.V] = true,
	[Enum.KeyCode.ButtonR2] = true
}
local v_u_23 = v_u_14.CFrame
local v_u_24 = CFrame.new()
v_u_14.CameraType = Enum.CameraType.Scriptable
v_u_12.CameraMode = Enum.CameraMode.Classic
local v_u_25 = RaycastParams.new()
v_u_25.FilterType = Enum.RaycastFilterType.Exclude
local function v_u_29() -- name: updateRaycastFilter
	-- upvalues: (copy) v_u_3, (copy) v_u_25
	local v26 = {}
	for _, v27 in ipairs(v_u_3:GetPlayers()) do
		local v28 = v27.Character
		if not v28 then
			continue
		end
		v26[#v26 + 1] = v28
	end
	v_u_25.FilterDescendantsInstances = v26
end
local v_u_30 = {}
local function v_u_34(p31) -- name: connectPlayer
	-- upvalues: (copy) v_u_30, (copy) v_u_29
	local v32 = v_u_30[p31]
	if v32 then
		for _, v33 in ipairs(v32) do
			v33:Disconnect()
		end
		v_u_30[p31] = nil
	end
	v_u_30[p31] = { p31.CharacterAdded:Connect(v_u_29), p31.CharacterRemoving:Connect(function()
			-- upvalues: (ref) v_u_29
			task.defer(v_u_29)
		end) }
end
local v_u_35 = 0
local v_u_36 = false
local v_u_37 = nil
local v_u_38 = 0
local v_u_39 = 0
local v_u_40 = false
local v_u_41 = {}
local v_u_42 = false
local v_u_43 = nil
local v_u_44 = false
local v_u_45 = false
local v_u_46 = false
local v_u_47 = nil
local v_u_48 = nil
local v_u_49 = false
local v_u_50 = false
local v_u_51 = false
local v_u_52 = 0
local v_u_53 = nil
local v_u_54 = false
local v_u_55 = 1
local v_u_56 = nil
local v_u_57 = nil
local v_u_58 = (-1 / 0)
local v_u_59 = (-1 / 0)
local v_u_60 = 6
local v_u_61 = 1.8
local v_u_62 = nil
local v_u_63 = nil
local v_u_64 = false
local v_u_65 = false
local v_u_66 = false
local v_u_67 = false
local v_u_68 = 6
local v_u_69 = 1.6
local v_u_70 = false
local v_u_71 = 0
local v_u_72 = true
local v_u_73 = false
local v_u_74 = nil
local v_u_75 = false
local v_u_76 = false
local v_u_77 = nil
local v_u_ArrowPanKeys = {}
local v_u_ArrowPanAction = "GameCameraArrowPan"
local v_u_RightClickHeld = false
local v_u_RightClickToggle = false
local v_u_RightClickStartedAt = 0
local v_u_RightClickThreshold = 0.3
local function v_u_81() -- name: isMouseUnlocked
	-- upvalues: (copy) v_u_12
	if not (v_u_RightClickHeld or v_u_RightClickToggle) then
		return true
	end
	local v78 = v_u_12.Character
	if v78 and v78:GetAttribute("InMenu") == true then
		return true
	end
	if v_u_12:GetAttribute("Spectating") then
		return true
	end
	for v79, v80 in pairs(v_u_12:GetAttributes()) do
		if v80 ~= true or string.sub(v79, 1, 12) ~= "MouseUnlock_" then
			continue
		end
		return true
	end
	return v_u_12:GetAttribute("PanelOpen") == true
end
v_u_41[#v_u_41 + 1] = v_u_1.InputBegan:Connect(function(pInput)
	if pInput.UserInputType == Enum.UserInputType.MouseButton2 then
		v_u_RightClickHeld = true
		v_u_RightClickStartedAt = os.clock()
	end
end)
v_u_41[#v_u_41 + 1] = v_u_1.InputEnded:Connect(function(pInput)
	if pInput.UserInputType == Enum.UserInputType.MouseButton2 and v_u_RightClickStartedAt > 0 then
		local vHoldDuration = os.clock() - v_u_RightClickStartedAt
		v_u_RightClickHeld = false
		if vHoldDuration < v_u_RightClickThreshold then
			v_u_RightClickToggle = not v_u_RightClickToggle
		end
		v_u_RightClickStartedAt = 0
	end
end)
v_u_41[#v_u_41 + 1] = v_u_1.WindowFocusReleased:Connect(function()
	v_u_RightClickHeld = false
	v_u_RightClickStartedAt = 0
end)
local function v_u_ArrowPanInput(_, pInputState, pInputObject)
	if not pInputObject then
		return Enum.ContextActionResult.Pass
	end
	local vKey = pInputObject.KeyCode
	if v_u_81() or v_u_1:GetFocusedTextBox() then
		v_u_ArrowPanKeys[vKey] = nil
		return Enum.ContextActionResult.Pass
	end
	if pInputState == Enum.UserInputState.Begin then
		v_u_ArrowPanKeys[vKey] = true
	elseif pInputState == Enum.UserInputState.End or pInputState == Enum.UserInputState.Cancel then
		v_u_ArrowPanKeys[vKey] = nil
	end
	return Enum.ContextActionResult.Sink
end
v_u_ContextActionService:BindActionAtPriority(
	v_u_ArrowPanAction,
	v_u_ArrowPanInput,
	false,
	Enum.ContextActionPriority.High.Value + 1,
	Enum.KeyCode.Left,
	Enum.KeyCode.Right,
	Enum.KeyCode.Up,
	Enum.KeyCode.Down
)
v_u_1.WindowFocusReleased:Connect(function()
	table.clear(v_u_ArrowPanKeys)
end)
for _, v82 in ipairs(v_u_3:GetPlayers()) do
	v_u_34(v82)
end
v_u_29()
local v84 = v_u_3.PlayerAdded:Connect(function(p83)
	-- upvalues: (copy) v_u_34, (copy) v_u_29
	v_u_34(p83)
	v_u_29()
end)
v_u_41[#v_u_41 + 1] = v84
local v88 = v_u_3.PlayerRemoving:Connect(function(p85)
	-- upvalues: (copy) v_u_30, (copy) v_u_29
	local v86 = v_u_30[p85]
	if v86 then
		for _, v87 in ipairs(v86) do
			v87:Disconnect()
		end
		v_u_30[p85] = nil
	end
	task.defer(v_u_29)
end)
v_u_41[#v_u_41 + 1] = v88
local v_u_89 = nil
local v_u_90 = nil
local v_u_91 = Vector2.zero
local v_u_92 = {}
local v_u_93 = {}
local v_u_94 = {}
local v_u_95 = {}
local v_u_96 = setmetatable({}, {
	["__mode"] = "k"
})
local v_u_97 = {}
local v_u_98 = setmetatable({}, {
	["__mode"] = "k"
})
local v_u_99 = {}
local v_u_100 = setmetatable({}, {
	["__mode"] = "k"
})
local v_u_101 = {
	["ParticleEmitter"] = true,
	["Trail"] = true,
	["Beam"] = true,
	["Fire"] = true,
	["Smoke"] = true,
	["Sparkles"] = true,
	["PointLight"] = true,
	["SpotLight"] = true,
	["SurfaceLight"] = true
}
local v_u_102 = {
	["Head"] = true
}
local v_u_103 = {
	["Left Arm"] = true,
	["Right Arm"] = true
}
local v_u_104 = false
local v_u_105 = 0
local v_u_106 = 0
local function v_u_108(p107) -- name: isRelevant
	-- upvalues: (copy) v_u_101
	return p107:IsA("Folder") and p107.Name:match("^Cosmetic%d+$") and true or (p107:IsA("BasePart") or p107:IsA("Accessory") or (p107:IsA("Decal") or p107:IsA("BillboardGui") or v_u_101[p107.ClassName] == true))
end
local v_u_109 = {}
local v_u_110 = {
	[Enum.AccessoryType.Hat] = true,
	[Enum.AccessoryType.Hair] = true,
	[Enum.AccessoryType.Face] = true,
	[Enum.AccessoryType.Eyebrow] = true,
	[Enum.AccessoryType.Eyelash] = true
}
local function v_u_119(p111) -- name: isHeadAccessoryHandle
	-- upvalues: (copy) v_u_109, (copy) v_u_110
	local v112 = v_u_109[p111]
	if v112 == nil then
		local v_u_113 = p111.Parent
		local v114 = nil
		local v115 = p111:FindFirstChild("AccessoryWeld") or p111:FindFirstChildWhichIsA("JointInstance")
		if v115 then
			local v116 = v115.Part0 == p111 and v115.Part1 or v115.Part0
			if v116 then
				v114 = v116.Name == "Head"
			end
		end
		if v114 == nil then
			local v117, v118 = pcall(function()
				-- upvalues: (copy) v_u_113
				return v_u_113.AccessoryType
			end)
			if v117 and (v118 and v118 ~= Enum.AccessoryType.Unknown) then
				return v_u_110[v118] == true
			else
				return false
			end
		else
			v_u_109[p111] = v114
			return v114
		end
	else
		return v112
	end
end
local v_u_120 = {}
local v_u_121 = setmetatable({}, {
	["__mode"] = "k"
})
local v_u_122 = false
local v_u_123 = false
local function v_u_130() -- name: cacheCharacterParts
	-- upvalues: (copy) v_u_92, (copy) v_u_93, (copy) v_u_94, (copy) v_u_95, (copy) v_u_97, (copy) v_u_99, (copy) v_u_109, (copy) v_u_120, (ref) v_u_15, (copy) v_u_96, (copy) v_u_98, (copy) v_u_101, (copy) v_u_121, (ref) v_u_122, (ref) v_u_123, (copy) v_u_100
	table.clear(v_u_92)
	table.clear(v_u_93)
	table.clear(v_u_94)
	table.clear(v_u_95)
	table.clear(v_u_97)
	table.clear(v_u_99)
	table.clear(v_u_109)
	for _, v124 in ipairs(v_u_120) do
		v124:Disconnect()
	end
	table.clear(v_u_120)
	if v_u_15 and v_u_15.Parent then
		local v125 = 0
		for _, v126 in ipairs(v_u_15:GetChildren()) do
			local v127 = nil
			if v126:IsA("BasePart") then
				if v126.Name ~= "HumanoidRootPart" then
					v127 = v126
				end
			elseif v126:IsA("Accessory") then
				v127 = v126:FindFirstChild("Handle")
			end
			if v127 then
				v125 = v125 + 1
				v_u_92[v125] = v127
				v_u_93[v125] = v127:FindFirstChildOfClass("Decal") or false
			end
			if not (v126:IsA("Folder") and v126.Name:match("^Cosmetic%d+$")) then
				continue
			end
			for _, v128 in ipairs(v126:GetDescendants()) do
				if v128:IsA("BasePart") then
					v_u_95[#v_u_95 + 1] = v128
					if v_u_96[v128] ~= nil then
						continue
					end
					v_u_96[v128] = v128.LocalTransparencyModifier
				else
					if not v128:IsA("Decal") then
						continue
					end
					v_u_97[#v_u_97 + 1] = v128
					if v_u_98[v128] ~= nil then
						continue
					end
					v_u_98[v128] = v128.LocalTransparencyModifier
				end
			end
		end
		for _, v_u_129 in ipairs(v_u_15:GetDescendants()) do
			if v_u_101[v_u_129.ClassName] then
				if v_u_121[v_u_129] == nil then
					v_u_121[v_u_129] = v_u_129.Enabled
				end
				v_u_94[#v_u_94 + 1] = v_u_129
				v_u_120[#v_u_120 + 1] = v_u_129:GetPropertyChangedSignal("Enabled"):Connect(function()
					-- upvalues: (ref) v_u_122, (ref) v_u_123, (copy) v_u_129, (ref) v_u_121
					if v_u_122 then
						return
					elseif v_u_123 then
						if v_u_129.Enabled then
							v_u_122 = true
							v_u_129.Enabled = false
							v_u_122 = false
						end
					else
						v_u_121[v_u_129] = v_u_129.Enabled
					end
				end)
			else
				if not v_u_129:IsA("BillboardGui") then
					continue
				end
				v_u_99[#v_u_99 + 1] = v_u_129
				if v_u_100[v_u_129] ~= nil then
					continue
				end
				v_u_100[v_u_129] = v_u_129.Enabled
			end
		end
	end
end
local function v_u_154(p131, p132) -- name: updateRealBodyTransparency
	-- upvalues: (ref) v_u_15, (ref) v_u_43, (ref) v_u_123, (copy) v_u_92, (copy) v_u_102, (ref) v_u_42, (copy) v_u_103, (copy) v_u_119, (copy) v_u_93, (copy) v_u_95, (copy) v_u_96, (copy) v_u_97, (copy) v_u_98, (copy) v_u_99, (copy) v_u_100, (copy) v_u_94, (copy) v_u_121, (ref) v_u_122
	if v_u_15 and (v_u_15.Parent and v_u_43) then
		v_u_123 = p131
		for v133 = 1, #v_u_92 do
			local v134 = v_u_92[v133]
			if not (v134 and v134.Parent) then
				continue
			end
			local v135 = 0
			if p131 then
				local v136
				if v_u_102[v134.Name] or v_u_42 and v_u_103[v134.Name] then
					v136 = true
				else
					local v137 = v134.Parent
					if v137 == nil or not v137:IsA("Accessory") then
						v136 = false
					else
						v136 = v_u_119(v134)
					end
				end
				v135 = v136 and 1 or v135
			end
			if v134.LocalTransparencyModifier ~= v135 then
				v134.LocalTransparencyModifier = v135
			end
			local v138 = v_u_93[v133]
			if not v138 or (not v138.Parent or v138.LocalTransparencyModifier == v135) then
				continue
			end
			v138.LocalTransparencyModifier = v135
		end
		for v139 = 1, #v_u_95 do
			local v140 = v_u_95[v139]
			if not (v140 and v140.Parent) then
				continue
			end
			local v141 = p131 and 1 or (v_u_96[v140] or 0)
			if v140.LocalTransparencyModifier == v141 then
				continue
			end
			v140.LocalTransparencyModifier = v141
		end
		for v142 = 1, #v_u_97 do
			local v143 = v_u_97[v142]
			if not (v143 and v143.Parent) then
				continue
			end
			local v144 = p131 and 1 or (v_u_98[v143] or 0)
			if v143.LocalTransparencyModifier == v144 then
				continue
			end
			v143.LocalTransparencyModifier = v144
		end
		for v145 = 1, #v_u_99 do
			local v146 = v_u_99[v145]
			if not (v146 and v146.Parent) then
				continue
			end
			local v147 = v_u_100[v146]
			local v148 = not p131 and (v147 == nil and true or v147)
			if v146.Enabled == v148 then
				continue
			end
			v146.Enabled = v148
		end
		local v149 = p132 and p131
		for v150 = 1, #v_u_94 do
			local v151 = v_u_94[v150]
			if not (v151 and v151.Parent) then
				continue
			end
			local v152 = v_u_121[v151]
			local v153 = not p131 and (v152 == nil and true or v152)
			if v151.Enabled ~= v153 then
				v_u_122 = true
				v151.Enabled = v153
				v_u_122 = false
			end
			if not (v149 and (v151:IsA("ParticleEmitter") or v151:IsA("Trail"))) then
				continue
			end
			v151:Clear()
		end
	end
end
local function v156() -- name: toggleCameraView
	-- upvalues: (ref) v_u_44, (ref) v_u_45, (ref) v_u_72, (ref) v_u_73, (ref) v_u_54, (ref) v_u_36, (ref) v_u_55, (ref) v_u_23, (ref) v_u_14, (ref) v_u_67, (ref) v_u_46
	if not (v_u_44 or v_u_45) then
		v_u_72 = not v_u_72
		v_u_73 = false
		local v155 = v_u_36
		if v155 then
			v155 = v_u_55 < 1
		end
		v_u_54 = v155
		v_u_23 = v_u_14.CFrame
		v_u_36 = true
		v_u_55 = 0
		v_u_67 = false
		v_u_46 = true
	end
end
local v_u_157 = false
local v_u_158 = {}
local v_u_159 = 0
local function v_u_162() -- name: disconnectCharConns
	-- upvalues: (copy) v_u_158, (copy) v_u_120
	for _, v160 in ipairs(v_u_158) do
		v160:Disconnect()
	end
	table.clear(v_u_158)
	for _, v161 in ipairs(v_u_120) do
		v161:Disconnect()
	end
	table.clear(v_u_120)
end
local function v_u_193(p163) -- name: setupCharacter
	-- upvalues: (ref) v_u_159, (ref) v_u_76, (copy) v_u_162, (ref) v_u_15, (ref) v_u_43, (ref) v_u_77, (copy) v_u_12, (ref) v_u_44, (ref) v_u_53, (ref) v_u_70, (ref) v_u_71, (ref) v_u_20, (ref) v_u_21, (ref) v_u_14, (copy) v_u_16, (copy) v_u_17, (ref) v_u_62, (ref) v_u_72, (ref) v_u_63, (ref) v_u_74, (ref) v_u_47, (ref) v_u_48, (ref) v_u_45, (ref) v_u_49, (ref) v_u_75, (ref) v_u_50, (copy) v_u_158, (ref) v_u_51, (ref) v_u_52, (copy) v_u_7, (copy) v_u_8, (copy) v_u_9, (ref) v_u_39, (ref) v_u_36, (ref) v_u_55, (ref) v_u_67, (ref) v_u_54, (ref) v_u_40, (ref) v_u_64, (ref) v_u_46, (ref) v_u_73, (ref) v_u_65, (ref) v_u_42, (ref) v_u_66, (ref) v_u_37, (ref) v_u_56, (ref) v_u_57, (ref) v_u_58, (ref) v_u_59, (ref) v_u_38, (ref) v_u_60, (ref) v_u_61, (ref) v_u_68, (ref) v_u_69, (ref) v_u_35, (ref) v_u_157, (ref) v_u_104, (ref) v_u_89, (ref) v_u_90, (copy) v_u_29, (copy) v_u_130, (copy) v_u_154, (copy) v_u_108, (ref) v_u_23
	v_u_159 = v_u_159 + 1
	table.clear(v_u_ArrowPanKeys)
	local v164 = v_u_159
	v_u_76 = false
	v_u_162()
	v_u_15 = p163
	v_u_43 = v_u_15:WaitForChild("Humanoid")
	v_u_77 = v_u_15:WaitForChild("HumanoidRootPart")
	if v164 == v_u_159 and v_u_12.Character == p163 then
		v_u_43.AutoRotate = false
		v_u_44 = false
		v_u_53 = nil
		v_u_70 = false
		v_u_71 = 0
		v_u_20 = 100
		v_u_21 = 100
		v_u_14 = workspace.CurrentCamera
		v_u_14.FieldOfView = 100
		v_u_16.BackgroundTransparency = v_u_17
		if v_u_62 ~= nil then
			v_u_72 = v_u_62
			v_u_62 = nil
		end
		local v165 = v_u_15:WaitForChild("Values", 2)
		local v166
		if v165 then
			v166 = v165:WaitForChild("Emoting", 2)
		else
			v166 = v165
		end
		v_u_63 = v166
		local v167
		if v165 then
			v167 = v165:WaitForChild("BackwardsSlide", 2)
		else
			v167 = v165
		end
		v_u_74 = v167
		local v168
		if v165 then
			v168 = v165:WaitForChild("Crouch", 2)
		else
			v168 = v165
		end
		v_u_47 = v168
		if v165 then
			v165 = v165:WaitForChild("Slide", 2)
		end
		v_u_48 = v165
		if v164 == v_u_159 and v_u_12.Character == p163 then
			local v169
			if v_u_63 == nil then
				v169 = false
			else
				v169 = v_u_63.Value == true
			end
			v_u_45 = v169
			local v170
			if v_u_74 == nil then
				v170 = false
			else
				v170 = v_u_74.Value == true
			end
			v_u_49 = v170
			local v171
			if v_u_47 == nil then
				v171 = false
			else
				v171 = v_u_47.Value == true
			end
			v_u_75 = v171
			local v172
			if v_u_48 == nil then
				v172 = false
			else
				v172 = v_u_48.Value == true
			end
			v_u_50 = v172
			local v173 = v_u_74
			local function v175(p174)
				-- upvalues: (ref) v_u_49
				v_u_49 = p174 == true
			end
			if v173 then
				v_u_158[#v_u_158 + 1] = v173.Changed:Connect(v175)
			end
			local v176 = v_u_47
			local function v178(p177)
				-- upvalues: (ref) v_u_75
				v_u_75 = p177 == true
			end
			if v176 then
				v_u_158[#v_u_158 + 1] = v176.Changed:Connect(v178)
			end
			local v179 = v_u_48
			local function v181(p180)
				-- upvalues: (ref) v_u_50
				v_u_50 = p180 == true
			end
			if v179 then
				v_u_158[#v_u_158 + 1] = v179.Changed:Connect(v181)
			end
			local v182 = v_u_43:GetState()
			v_u_51 = v182 == Enum.HumanoidStateType.Freefall and true or v182 == Enum.HumanoidStateType.Jumping
			v_u_158[#v_u_158 + 1] = v_u_43.StateChanged:Connect(function(_, p183)
				-- upvalues: (ref) v_u_51
				v_u_51 = p183 == Enum.HumanoidStateType.Freefall and true or p183 == Enum.HumanoidStateType.Jumping
			end)
			local _, v184, _ = v_u_77.CFrame:ToOrientation()
			v_u_52 = v_u_9(v_u_7(v184), (v_u_8(v184)))
			v_u_39 = 0
			v_u_36 = false
			v_u_55 = 1
			v_u_67 = false
			v_u_54 = false
			v_u_40 = false
			v_u_64 = false
			v_u_46 = false
			v_u_73 = false
			v_u_65 = false
			v_u_42 = false
			v_u_66 = false
			v_u_37 = nil
			v_u_56 = nil
			v_u_57 = nil
			v_u_58 = (-1 / 0)
			v_u_59 = (-1 / 0)
			v_u_38 = 0
			v_u_60 = 6
			v_u_61 = 1.8
			v_u_68 = 6
			v_u_69 = 1.6
			v_u_35 = 0
			v_u_157 = false
			v_u_104 = false
			v_u_89 = nil
			v_u_90 = nil
			v_u_29()
			v_u_130()
			v_u_154(v_u_72, true)
			v_u_158[#v_u_158 + 1] = v_u_15.DescendantAdded:Connect(function(p185)
				-- upvalues: (ref) v_u_108, (ref) v_u_104
				if v_u_108(p185) then
					v_u_104 = true
				end
			end)
			v_u_158[#v_u_158 + 1] = v_u_15.DescendantRemoving:Connect(function(p186)
				-- upvalues: (ref) v_u_108, (ref) v_u_104
				if v_u_108(p186) then
					v_u_104 = true
				end
			end)
			if v_u_63 then
				v_u_158[#v_u_158 + 1] = v_u_63.Changed:Connect(function(p187)
					-- upvalues: (ref) v_u_45, (ref) v_u_64, (ref) v_u_40, (ref) v_u_72, (ref) v_u_73, (ref) v_u_54, (ref) v_u_36, (ref) v_u_55, (ref) v_u_23, (ref) v_u_14, (ref) v_u_67, (ref) v_u_46
					local v188 = p187 == true
					if v188 ~= v_u_45 then
						v_u_45 = v188
						if v188 then
							v_u_64 = true
							v_u_40 = v_u_72
							v_u_73 = false
							if v_u_72 then
								v_u_72 = false
								local v189 = v_u_36
								if v189 then
									v189 = v_u_55 < 1
								end
								v_u_54 = v189
								v_u_23 = v_u_14.CFrame
								v_u_36 = true
								v_u_55 = 0
								v_u_67 = false
								return
							end
						else
							local v190 = v_u_64
							if v190 then
								v190 = v_u_40 == true
							end
							if v190 then
								v_u_72 = true
								local v191 = v_u_36
								if v191 then
									v191 = v_u_55 < 1
								end
								v_u_54 = v191
								v_u_23 = v_u_14.CFrame
								v_u_36 = true
								v_u_55 = 0
								v_u_67 = false
								v_u_73 = true
							end
							v_u_64 = false
							v_u_40 = false
							v_u_46 = true
						end
					end
				end)
			end
			v_u_158[#v_u_158 + 1] = v_u_43.Died:Connect(function()
				-- upvalues: (ref) v_u_44, (ref) v_u_53, (ref) v_u_20, (ref) v_u_21, (ref) v_u_71, (ref) v_u_70, (ref) v_u_14, (ref) v_u_62, (ref) v_u_45, (ref) v_u_40, (ref) v_u_72, (ref) v_u_54, (ref) v_u_36, (ref) v_u_55, (ref) v_u_23, (ref) v_u_67
				v_u_44 = true
				v_u_53 = nil
				v_u_20 = 100
				v_u_21 = 100
				v_u_71 = 0
				v_u_70 = false
				v_u_14.FieldOfView = 100
				v_u_62 = v_u_45 and v_u_40 or v_u_72
				v_u_40 = false
				if v_u_72 then
					v_u_72 = false
					local v192 = v_u_36
					if v192 then
						v192 = v_u_55 < 1
					end
					v_u_54 = v192
					v_u_23 = v_u_14.CFrame
					v_u_36 = true
					v_u_55 = 0
					v_u_67 = false
				end
			end)
			v_u_14 = workspace.CurrentCamera
			v_u_14.CameraType = Enum.CameraType.Scriptable
			v_u_76 = true
		end
	else
		return
	end
end
local v194 = v_u_12.PlayerGui:WaitForChild("Mobile", 5)
if v194 then
	v194 = v194:WaitForChild("Camera", 5)
end
if v194 and v194:IsA("GuiButton") then
	local v195 = v194.Activated:Connect(v156)
	v_u_41[#v_u_41 + 1] = v195
end
local v199 = v_u_1.InputBegan:Connect(function(p196, p197)
	-- upvalues: (copy) v_u_22, (ref) v_u_44, (ref) v_u_45, (ref) v_u_72, (ref) v_u_73, (ref) v_u_54, (ref) v_u_36, (ref) v_u_55, (ref) v_u_23, (ref) v_u_14, (ref) v_u_67, (ref) v_u_46, (copy) v_u_19, (ref) v_u_70
	if not p197 then
		if v_u_22[p196.KeyCode] and not (v_u_44 or v_u_45) then
			v_u_72 = not v_u_72
			v_u_73 = false
			local v198 = v_u_36
			if v198 then
				v198 = v_u_55 < 1
			end
			v_u_54 = v198
			v_u_23 = v_u_14.CFrame
			v_u_36 = true
			v_u_55 = 0
			v_u_67 = false
			v_u_46 = true
		end
		if p196.KeyCode == v_u_19 and not v_u_44 then
			v_u_70 = true
		end
	end
end)
v_u_41[#v_u_41 + 1] = v199
local v200 = v_u_1.WindowFocusReleased:Connect(function()
	-- upvalues: (ref) v_u_70, (ref) v_u_89, (ref) v_u_90
	v_u_70 = false
	v_u_89 = nil
	v_u_90 = nil
end)
v_u_41[#v_u_41 + 1] = v200
local v206 = v_u_1.InputChanged:Connect(function(p201, p202)
	-- upvalues: (ref) v_u_44, (ref) v_u_45, (ref) v_u_72, (ref) v_u_73, (ref) v_u_54, (ref) v_u_36, (ref) v_u_55, (ref) v_u_23, (ref) v_u_14, (ref) v_u_67, (ref) v_u_46, (ref) v_u_91
	if p201.UserInputType == Enum.UserInputType.MouseWheel and not p202 then
		if v_u_44 or v_u_45 then
			return
		end
		local v203 = p201.Position.Z
		if v203 > 0 and not v_u_72 then
			v_u_72 = true
			v_u_73 = false
			local v204 = v_u_36
			if v204 then
				v204 = v_u_55 < 1
			end
			v_u_54 = v204
			v_u_23 = v_u_14.CFrame
			v_u_36 = true
			v_u_55 = 0
			v_u_67 = false
			v_u_46 = true
		elseif v203 < 0 and v_u_72 then
			v_u_72 = false
			v_u_73 = false
			local v205 = v_u_36
			if v205 then
				v205 = v_u_55 < 1
			end
			v_u_54 = v205
			v_u_23 = v_u_14.CFrame
			v_u_36 = true
			v_u_55 = 0
			v_u_67 = false
			v_u_46 = true
		end
	end
	if p201.KeyCode == Enum.KeyCode.Thumbstick2 then
		v_u_91 = Vector2.new(p201.Position.X, p201.Position.Y)
	end
end)
v_u_41[#v_u_41 + 1] = v206
local v208 = v_u_1.InputEnded:Connect(function(p207)
	-- upvalues: (ref) v_u_91, (copy) v_u_19, (ref) v_u_70
	if p207.KeyCode == Enum.KeyCode.Thumbstick2 then
		v_u_91 = Vector2.zero
	end
	if p207.KeyCode == v_u_19 then
		v_u_70 = false
	end
end)
v_u_41[#v_u_41 + 1] = v208
local v214 = v_u_1.TouchStarted:Connect(function(p209, p210)
	-- upvalues: (ref) v_u_89, (ref) v_u_14, (ref) v_u_90
	if p210 or v_u_89 then
		return
	else
		local v211 = p209.Position
		local v212 = v_u_14.ViewportSize
		local v213
		if v211.X < v212.X * 0.35 then
			v213 = v211.Y > v212.Y * 0.4
		else
			v213 = false
		end
		if not v213 then
			v_u_89 = p209
			v_u_90 = p209.Position
		end
	end
end)
v_u_41[#v_u_41 + 1] = v214
local v219 = v_u_1.TouchMoved:Connect(function(p215)
	-- upvalues: (ref) v_u_89, (ref) v_u_90, (copy) v_u_13, (copy) v_u_11, (ref) v_u_52, (copy) v_u_7, (copy) v_u_8, (copy) v_u_9, (ref) v_u_39
	if p215 == v_u_89 and v_u_90 then
		local v216 = p215.Position - v_u_90
		v_u_90 = p215.Position
		local v217 = 0.016 * v_u_11(v_u_13.Value, 0.1, 3)
		local v218 = v_u_52 - v216.X * v217
		if v218 > 3.141592653589793 or v218 < -3.141592653589793 then
			v218 = v_u_9(v_u_7(v218), (v_u_8(v218)))
		end
		v_u_52 = v218
		v_u_39 = v_u_11(v_u_39 - v216.Y * v217, -1.3962634015954636, 1.3962634015954636)
	end
end)
v_u_41[#v_u_41 + 1] = v219
local v221 = v_u_1.TouchEnded:Connect(function(p220)
	-- upvalues: (ref) v_u_89, (ref) v_u_90
	if p220 == v_u_89 then
		v_u_89 = nil
		v_u_90 = nil
	end
end)
v_u_41[#v_u_41 + 1] = v221
local v_u_222 = false
local function v226() -- name: cleanup
	-- upvalues: (ref) v_u_222, (ref) v_u_159, (ref) v_u_76, (copy) v_u_41, (copy) v_u_162, (ref) v_u_35, (ref) v_u_15, (ref) v_u_14, (ref) v_u_20, (copy) v_u_1, (copy) v_u_16, (copy) v_u_17, (copy) v_u_30, (copy) v_u_2, (copy) v_u_18
	if not v_u_222 then
		v_u_222 = true
		v_u_159 = v_u_159 + 1
		v_u_76 = false
		for _, v223 in ipairs(v_u_41) do
			v223:Disconnect()
		end
		table.clear(v_u_41)
		v_u_162()
		v_u_35 = 0
		if v_u_15 and v_u_15.Parent then
			v_u_15:SetAttribute("FPBodyShift", nil)
		end
		if v_u_14 then
			v_u_14.FieldOfView = v_u_20
			v_u_14.CameraType = Enum.CameraType.Custom
		end
		v_u_1.MouseBehavior = Enum.MouseBehavior.Default
		v_u_1.MouseIconEnabled = v_u_OriginalMouseIconEnabled
		v_u_16.BackgroundTransparency = v_u_17
		for _, v224 in pairs(v_u_30) do
			for _, v225 in ipairs(v224) do
				v225:Disconnect()
			end
		end
		table.clear(v_u_30)
		v_u_2:UnbindFromRenderStep(v_u_18)
		v_u_ContextActionService:UnbindAction(v_u_ArrowPanAction)
		table.clear(v_u_ArrowPanKeys)
	end
end
script.Destroying:Connect(v226)
local v228 = v_u_12.CharacterRemoving:Connect(function(p227)
	-- upvalues: (ref) v_u_15, (ref) v_u_76, (ref) v_u_159, (copy) v_u_162, (copy) v_u_29
	if p227 == v_u_15 then
		v_u_76 = false
		v_u_159 = v_u_159 + 1
		v_u_162()
		task.defer(v_u_29)
	end
end)
v_u_41[#v_u_41 + 1] = v228
local v230 = v_u_12.CharacterAdded:Connect(function(p229)
	-- upvalues: (copy) v_u_193
	task.spawn(v_u_193, p229)
end)
v_u_41[#v_u_41 + 1] = v230
local function v_u_234() -- name: getSlideTargetYaw
	-- upvalues: (ref) v_u_77, (ref) v_u_37, (copy) v_u_9
	if v_u_77 then
		if not (v_u_37 and v_u_37.Parent) then
			v_u_37 = v_u_77:FindFirstChild("BhopLinearVelocity")
		end
		local v231 = v_u_37
		if v231 then
			if v231.MaxAxesForce.X ~= 0 or (v231.MaxAxesForce.Y ~= 0 or v231.MaxAxesForce.Z ~= 0) then
				local v232 = v231.VectorVelocity
				if v232.X * v232.X + v232.Z * v232.Z > 4 then
					return v_u_9(-v232.X, -v232.Z)
				end
			end
			return nil
		else
			local v233 = v_u_77.AssemblyLinearVelocity
			if v233.X * v233.X + v233.Z * v233.Z > 4 then
				return v_u_9(-v233.X, -v233.Z)
			else
				return nil
			end
		end
	else
		return nil
	end
end
v_u_193(v_u_15)
v_u_2:BindToRenderStep(v_u_18, Enum.RenderPriority.Camera.Value, function(p235)
	-- upvalues: (ref) v_u_76, (ref) v_u_77, (ref) v_u_43, (ref) v_u_14, (ref) v_u_45, (ref) v_u_65, (ref) v_u_58, (ref) v_u_50, (ref) v_u_56, (ref) v_u_42, (ref) v_u_51, (ref) v_u_59, (copy) v_u_1, (copy) v_u_81, (copy) v_u_13, (copy) v_u_11, (ref) v_u_21, (ref) v_u_20, (ref) v_u_52, (copy) v_u_7, (copy) v_u_8, (copy) v_u_9, (ref) v_u_39, (ref) v_u_91, (copy) v_u_5, (ref) v_u_44, (ref) v_u_49, (ref) v_u_57, (copy) v_u_234, (copy) v_u_10, (ref) v_u_36, (ref) v_u_55, (copy) v_u_6, (ref) v_u_61, (ref) v_u_68, (ref) v_u_75, (ref) v_u_38, (ref) v_u_72, (ref) v_u_69, (ref) v_u_35, (ref) v_u_53, (ref) v_u_15, (copy) v_u_25, (ref) v_u_60, (ref) v_u_67, (ref) v_u_24, (ref) v_u_23, (ref) v_u_54, (ref) v_u_70, (ref) v_u_71, (copy) v_u_16, (copy) v_u_17, (ref) v_u_73, (ref) v_u_157, (ref) v_u_46, (ref) v_u_104, (ref) v_u_106, (ref) v_u_66, (ref) v_u_105, (copy) v_u_130, (copy) v_u_154
	if not v_u_76 then
		return
	end
	if not (v_u_77 and (v_u_77.Parent and v_u_43)) then
		return
	end
	v_u_14 = workspace.CurrentCamera
	if v_u_14.CameraType ~= Enum.CameraType.Scriptable then
		v_u_14.CameraType = Enum.CameraType.Scriptable
	end
	local v236 = p235 < 0.1 and p235 and p235 or 0.1
	local v237 = os.clock()
	local v238 = v_u_45
	local v239 = v_u_77.CFrame
	local v240 = v239.Position
	local v241 = v_u_77.AssemblyLinearVelocity
	local v242 = v241.X * v241.X + v241.Z * v241.Z
	if v_u_65 then
		if v242 < 100 then
			v_u_65 = false
		end
	elseif v242 >= 324 then
		v_u_65 = true
	end
	if v_u_65 then
		v_u_58 = v237
	end
	local v243 = v_u_50
	if v243 then
		if not v_u_56 then
			v_u_56 = v237
		end
	else
		v_u_56 = nil
	end
	local v244
	if v_u_56 == nil then
		v244 = false
	else
		v244 = v237 - v_u_56 >= 0.12
	end
	local v245 = not v244
	if v245 then
		v245 = v237 - v_u_58 < 0.35
	end
	v_u_42 = v245
	if v_u_51 then
		v_u_59 = v237
	end
	local v246 = v237 - v_u_59 < 0.1
	if v_u_1.MouseEnabled then
		if not v_u_81() then
			if v_u_1.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
				v_u_1.MouseBehavior = Enum.MouseBehavior.LockCenter
			end
			v_u_1.MouseIconEnabled = false
			local v247 = v_u_1:GetMouseDelta()
			local v248 = v247.X
			local v249 = v247.Y
			if v248 ~= 0 or v249 ~= 0 then
				local v250 = 0.005 * v_u_11(v_u_13.Value, 0.1, 3) * (v_u_21 / v_u_20)
				local v251 = v_u_52 - v248 * v250
				if v251 > 3.141592653589793 or v251 < -3.141592653589793 then
					v251 = v_u_9(v_u_7(v251), (v_u_8(v251)))
				end
				v_u_52 = v251
				v_u_39 = v_u_11(v_u_39 - v249 * v250, -1.3962634015954636, 1.3962634015954636)
			end
		else
			if v_u_1.MouseBehavior == Enum.MouseBehavior.LockCenter then
				v_u_1.MouseBehavior = Enum.MouseBehavior.Default
			end
			v_u_1.MouseIconEnabled = v_u_OriginalMouseIconEnabled
		end
	end
	if v_u_91.Magnitude >= 0.15 then
		local v252 = v_u_91.Magnitude
		local v253 = (v252 - 0.15) / 0.85 / v252
		local v254 = v_u_91.X * v253
		local v255 = v_u_91.Y * v253
		local v256 = 3.5 * v_u_5.GamepadCameraSensitivity * v_u_11(v_u_13.Value, 0.1, 3)
		local v257 = v_u_52 - v254 * v256 * v236
		if v257 > 3.141592653589793 or v257 < -3.141592653589793 then
			v257 = v_u_9(v_u_7(v257), (v_u_8(v257)))
		end
		v_u_52 = v257
		v_u_39 = v_u_11(v_u_39 + v255 * v256 * v236, -1.3962634015954636, 1.3962634015954636)
	end
	local vArrowHorizontal = 0
	if v_u_ArrowPanKeys[Enum.KeyCode.Left] then
		vArrowHorizontal = vArrowHorizontal + 1
	end
	if v_u_ArrowPanKeys[Enum.KeyCode.Right] then
		vArrowHorizontal = vArrowHorizontal - 1
	end
	local vArrowVertical = 0
	if v_u_ArrowPanKeys[Enum.KeyCode.Up] then
		vArrowVertical = vArrowVertical + 1
	end
	if v_u_ArrowPanKeys[Enum.KeyCode.Down] then
		vArrowVertical = vArrowVertical - 1
	end
	if vArrowHorizontal ~= 0 then
		local vArrowYaw = v_u_52 + vArrowHorizontal * 2.5 * v236
		if vArrowYaw > 3.141592653589793 or vArrowYaw < -3.141592653589793 then
			vArrowYaw = v_u_9(v_u_7(vArrowYaw), v_u_8(vArrowYaw))
		end
		v_u_52 = vArrowYaw
	end
	if vArrowVertical ~= 0 then
		v_u_39 = v_u_11(
			v_u_39 + vArrowVertical * 2.5 * v236,
			-1.3962634015954636,
			1.3962634015954636
		)
	end
	local v258, v259, v260, v261, v262, v263, v264, v265, v266, v267, v268, v269, v270, v271, v272, v273, v274, v275, v276, v277, v278, v279, v280, v281, v282, v283, v284, v285, v286, v287, v288, v289, v290, v291, v292, v293, v294, v295, v296, v297, v298, v299, v300, v301, v302, v303, v304, v305
	if v238 or v_u_44 then
		if v_u_36 then
			v_u_55 = v_u_11(v_u_55 + v236 / 0.2, 0, 1)
			if v_u_55 >= 1 then
				v_u_36 = false
			end
		end
		v258 = 1 - v_u_6(-12 * v236)
		v_u_61 = v_u_61 + ((v238 and 0 or 1.8) - v_u_61) * v258
		v_u_68 = v_u_68 + ((v238 and 12 or 6) - v_u_68) * v258
		v259 = v_u_75 and not (v238 or v_u_44) and 1 or 0
		if v_u_38 ~= v259 then
			v_u_38 = v_u_38 + (v259 - v_u_38) * (1 - v_u_6(-14 * v236))
			if v_u_10(v259 - v_u_38) < 0.0005 then
				v_u_38 = v259
			end
		end
		v260 = (not v_u_72 or (v238 or v_u_44)) and 0 or v_u_69
		v_u_35 = v_u_35 + (v260 - v_u_35) * (1 - v_u_6(-14 * v236))
		if v_u_10(v260 - v_u_35) < 0.0005 then
			v_u_35 = v260
		end
		if v_u_72 then
			v_u_69 = v_u_69 + ((v246 and 1.6 or (v_u_65 and 2.2 or 1.6)) - v_u_69) * (1 - v_u_6(-12 * v236))
			v261 = -v_u_7(v_u_52)
			v262 = -v_u_8(v_u_52)
			v263 = Vector3.new(v261, 0, v262)
			v264 = v240.X
			v265 = v240.Y + 1.5 - v_u_38
			v266 = v240.Z
			v267 = Vector3.new(v264, v265, v266) + v263 * v_u_35
			v268 = CFrame.new(v267) * CFrame.fromOrientation(v_u_39, v_u_52, 0)
		else
			v269 = 1.5 - v_u_38
			if v_u_44 then
				if not (v_u_53 and v_u_53.Parent) then
					v_u_53 = v_u_15:FindFirstChild("Head") or v_u_15:FindFirstChild("Torso")
				end
				if v_u_53 and v_u_53.Parent then
					v270 = v_u_53.Position
				else
					v270 = v240
				end
				v269 = 0.5
			else
				v270 = v240
			end
			v271 = v270.X
			v272 = v270.Y + v269
			v273 = v270.Z
			v274 = Vector3.new(v271, v272, v273)
			v275 = CFrame.new(v274) * CFrame.fromOrientation(v_u_39, v_u_52, 0)
			v276 = v_u_61
			v277 = v_u_68
			v278 = v275 * Vector3.new(v276, 0, v277) - v274
			v279 = workspace:Spherecast(v274, 0.5, v278, v_u_25)
			if v279 then
				v280 = v_u_11((v279.Position - v274).Magnitude - 0.5, 0.4, v_u_68)
			else
				v280 = v_u_68
			end
			v281 = v_u_60 < v280 and 15 or 35
			v_u_60 = v_u_60 + (v280 - v_u_60) * (1 - v_u_6(-v281 * v236))
			v282 = v_u_60 / (v_u_68 > 0 and v_u_68 or 1)
			v268 = v275 * CFrame.new(v_u_61 * v282, 0, v_u_60)
		end
		if v_u_36 then
			if not v_u_67 then
				v_u_67 = true
				v_u_24 = v268:ToObjectSpace(v_u_23)
			end
			v283 = v_u_55
			v284 = 0
			if v_u_54 then
				v285 = 1 - (1 - v283) ^ 3
				v286 = v285
				v287 = v286
				v288 = v287
				v289 = v286
				v286 = v288
				v289 = v287
				v287 = v286
				v289 = v288
			else
				if v283 < 0.5 then
					v287 = 4 * v283 * v283 * v283
				else
					v287 = 1 - (-2 * v283 + 2) ^ 3 / 2
				end
				v290 = v_u_11((v283 - 0.15) / 0.85, 0, 1)
				if v290 < 0.5 then
					v285 = 4 * v290 * v290 * v290
				else
					v285 = 1 - (-2 * v290 + 2) ^ 3 / 2
				end
				v288 = 1 - (1 - v283) ^ 3
				if v283 < 0.5 then
					v286 = 4 * v283 * v283 * v283
				else
					v286 = 1 - (-2 * v283 + 2) ^ 3 / 2
				end
				v284 = v_u_7(3.141592653589793 * v283) * 0.5
			end
			v291 = v_u_24.Position
			v292 = v291.X * (1 - v285)
			v293 = v291.Y * (1 - v288) + v284
			v294 = v291.Z * (1 - v287)
			v295 = Vector3.new(v292, v293, v294)
			v296 = v_u_24.Rotation:Lerp(CFrame.identity, v286)
			v_u_14.CFrame = v268 * (CFrame.new(v295) * v296)
		else
			v_u_14.CFrame = v268
		end
		if v_u_15 and v_u_15:GetAttribute("FPBodyShift") ~= Vector3.new(0, 0, 0) then
			v_u_15:SetAttribute("FPBodyShift", Vector3.new(0, 0, 0))
		end
		if v_u_44 then
			v_u_70 = false
			v_u_71 = 0
			v_u_20 = 100
			v_u_21 = 100
			if v_u_14.FieldOfView ~= 100 then
				v_u_14.FieldOfView = 100
			end
			v_u_16.BackgroundTransparency = v_u_17
		else
			v297 = v_u_70 and 1 or 0
			if v_u_71 ~= v297 then
				v_u_71 = v_u_71 + (v297 - v_u_71) * (1 - v_u_6(-14 * v236))
				if v_u_10(v297 - v_u_71) < 0.0005 then
					v_u_71 = v297
				end
			end
			v_u_16.BackgroundTransparency = v_u_17 + (1 - v_u_17) * v_u_71
			v298 = v_u_14.FieldOfView
			if v_u_10(v298 - v_u_21) > 0.01 then
				v_u_20 = v298
			end
			v299 = v_u_11(v_u_20 * (1 - v_u_71 * 0.5), 1, 120)
			if v_u_10(v299 - v298) > 0.001 then
				v_u_14.FieldOfView = v299
			end
			v_u_21 = v299
		end
		if v_u_73 and (v_u_72 and not v238) then
			v300 = true
			if not v_u_36 then
				v_u_73 = false
			end
		elseif v_u_36 then
			v301 = v_u_15:FindFirstChild("Head")
			v302 = v301 and v301.Position or v240 + Vector3.new(0, 1.5, 0)
			v300 = (v_u_14.CFrame.Position - v302).Magnitude <= v_u_69 + 0.4
		else
			v300 = v_u_72
		end
		if v300 then
			v303 = not v_u_157
		else
			v303 = v300
		end
		v304 = not v300
		if v304 then
			v304 = v_u_157
		end
		v_u_157 = v300
		if v_u_46 then
			v_u_104 = true
			v_u_106 = (-1 / 0)
			v_u_46 = false
		end
		v305 = v_u_42 ~= v_u_66
		v_u_66 = v_u_42
		if v_u_104 and v237 - v_u_105 > 0.25 then
			v_u_104 = false
			v_u_105 = v237
			v_u_106 = v237
			v_u_130()
			v_u_154(v300, true)
		elseif v303 or (v304 or v305 and v300) or v237 - v_u_106 > 0.5 then
			v_u_106 = v237
			v_u_154(v300, v303 or v304)
		end
	else
		local v306 = v_u_49
		local _, v307, _ = v239:ToOrientation()
		local v308
		if v243 then
			if v_u_57 == nil then
				v_u_57 = v307
			end
			local v309
			if v_u_43.MoveDirection.Magnitude > 0 then
				v309 = v306 and v_u_52 + 3.141592653589793 or v_u_52
				if v309 > 3.141592653589793 or v309 < -3.141592653589793 then
					v309 = v_u_9(v_u_7(v309), (v_u_8(v309)))
				end
			else
				v309 = v_u_234()
			end
			if v309 then
				v_u_57 = v309
			end
			v308 = v_u_57
		else
			v_u_57 = nil
			v308 = v306 and v_u_52 + 3.141592653589793 or v_u_52
			if v308 > 3.141592653589793 or v308 < -3.141592653589793 then
				v308 = v_u_9(v_u_7(v308), (v_u_8(v308)))
			end
		end
		local v310, v311, v312, v313
		if v243 then
			v_u_77.CFrame = CFrame.new(v240) * CFrame.Angles(0, v308, 0)
			v310 = v_u_77.AssemblyAngularVelocity
			if v243 or v_u_10(v310.Y) > 0.001 then
				v311 = v_u_77
				v312 = v310.X
				v313 = v310.Z
				v311.AssemblyAngularVelocity = Vector3.new(v312, 0, v313)
			end
		else
			local v314 = v308 - v307
			if v314 > 3.141592653589793 or v314 < -3.141592653589793 then
				v314 = v_u_9(v_u_7(v314), (v_u_8(v314)))
			end
			if v_u_10(v314) > 0.0001 then
				v_u_77.CFrame = CFrame.new(v240) * CFrame.Angles(0, v308, 0)
				v310 = v_u_77.AssemblyAngularVelocity
				if v243 or v_u_10(v310.Y) > 0.001 then
					v311 = v_u_77
					v312 = v310.X
					v313 = v310.Z
					v311.AssemblyAngularVelocity = Vector3.new(v312, 0, v313)
				end
			else
				v310 = v_u_77.AssemblyAngularVelocity
				if v243 or v_u_10(v310.Y) > 0.001 then
					v311 = v_u_77
					v312 = v310.X
					v313 = v310.Z
					v311.AssemblyAngularVelocity = Vector3.new(v312, 0, v313)
				end
			end
		end
		if v_u_36 then
			v_u_55 = v_u_11(v_u_55 + v236 / 0.2, 0, 1)
			if v_u_55 >= 1 then
				v_u_36 = false
			end
		end
		v258 = 1 - v_u_6(-12 * v236)
		v_u_61 = v_u_61 + ((v238 and 0 or 1.8) - v_u_61) * v258
		v_u_68 = v_u_68 + ((v238 and 12 or 6) - v_u_68) * v258
		v259 = v_u_75 and not (v238 or v_u_44) and 1 or 0
		if v_u_38 ~= v259 then
			v_u_38 = v_u_38 + (v259 - v_u_38) * (1 - v_u_6(-14 * v236))
			if v_u_10(v259 - v_u_38) < 0.0005 then
				v_u_38 = v259
			end
		end
		v260 = (not v_u_72 or (v238 or v_u_44)) and 0 or v_u_69
		v_u_35 = v_u_35 + (v260 - v_u_35) * (1 - v_u_6(-14 * v236))
		if v_u_10(v260 - v_u_35) < 0.0005 then
			v_u_35 = v260
		end
		if v_u_72 then
			v_u_69 = v_u_69 + ((v246 and 1.6 or (v_u_65 and 2.2 or 1.6)) - v_u_69) * (1 - v_u_6(-12 * v236))
			v261 = -v_u_7(v_u_52)
			v262 = -v_u_8(v_u_52)
			v263 = Vector3.new(v261, 0, v262)
			v264 = v240.X
			v265 = v240.Y + 1.5 - v_u_38
			v266 = v240.Z
			v267 = Vector3.new(v264, v265, v266) + v263 * v_u_35
			v268 = CFrame.new(v267) * CFrame.fromOrientation(v_u_39, v_u_52, 0)
		else
			v269 = 1.5 - v_u_38
			if v_u_44 then
				if not (v_u_53 and v_u_53.Parent) then
					v_u_53 = v_u_15:FindFirstChild("Head") or v_u_15:FindFirstChild("Torso")
				end
				if v_u_53 and v_u_53.Parent then
					v270 = v_u_53.Position
				else
					v270 = v240
				end
				v269 = 0.5
			else
				v270 = v240
			end
			v271 = v270.X
			v272 = v270.Y + v269
			v273 = v270.Z
			v274 = Vector3.new(v271, v272, v273)
			v275 = CFrame.new(v274) * CFrame.fromOrientation(v_u_39, v_u_52, 0)
			v276 = v_u_61
			v277 = v_u_68
			v278 = v275 * Vector3.new(v276, 0, v277) - v274
			v279 = workspace:Spherecast(v274, 0.5, v278, v_u_25)
			if v279 then
				v280 = v_u_11((v279.Position - v274).Magnitude - 0.5, 0.4, v_u_68)
			else
				v280 = v_u_68
			end
			v281 = v_u_60 < v280 and 15 or 35
			v_u_60 = v_u_60 + (v280 - v_u_60) * (1 - v_u_6(-v281 * v236))
			v282 = v_u_60 / (v_u_68 > 0 and v_u_68 or 1)
			v268 = v275 * CFrame.new(v_u_61 * v282, 0, v_u_60)
		end
		if v_u_36 then
			if not v_u_67 then
				v_u_67 = true
				v_u_24 = v268:ToObjectSpace(v_u_23)
			end
			v283 = v_u_55
			v284 = 0
			if v_u_54 then
				v285 = 1 - (1 - v283) ^ 3
				v286 = v285
				v287 = v286
				v288 = v287
				v289 = v286
				v286 = v288
				v289 = v287
				v287 = v286
				v289 = v288
			else
				if v283 < 0.5 then
					v287 = 4 * v283 * v283 * v283
				else
					v287 = 1 - (-2 * v283 + 2) ^ 3 / 2
				end
				v290 = v_u_11((v283 - 0.15) / 0.85, 0, 1)
				if v290 < 0.5 then
					v285 = 4 * v290 * v290 * v290
				else
					v285 = 1 - (-2 * v290 + 2) ^ 3 / 2
				end
				v288 = 1 - (1 - v283) ^ 3
				if v283 < 0.5 then
					v286 = 4 * v283 * v283 * v283
				else
					v286 = 1 - (-2 * v283 + 2) ^ 3 / 2
				end
				v284 = v_u_7(3.141592653589793 * v283) * 0.5
			end
			v291 = v_u_24.Position
			v292 = v291.X * (1 - v285)
			v293 = v291.Y * (1 - v288) + v284
			v294 = v291.Z * (1 - v287)
			v295 = Vector3.new(v292, v293, v294)
			v296 = v_u_24.Rotation:Lerp(CFrame.identity, v286)
			v_u_14.CFrame = v268 * (CFrame.new(v295) * v296)
		else
			v_u_14.CFrame = v268
		end
		if v_u_15 and v_u_15:GetAttribute("FPBodyShift") ~= Vector3.new(0, 0, 0) then
			v_u_15:SetAttribute("FPBodyShift", Vector3.new(0, 0, 0))
		end
		if v_u_44 then
			v_u_70 = false
			v_u_71 = 0
			v_u_20 = 100
			v_u_21 = 100
			if v_u_14.FieldOfView ~= 100 then
				v_u_14.FieldOfView = 100
			end
			v_u_16.BackgroundTransparency = v_u_17
		else
			v297 = v_u_70 and 1 or 0
			if v_u_71 ~= v297 then
				v_u_71 = v_u_71 + (v297 - v_u_71) * (1 - v_u_6(-14 * v236))
				if v_u_10(v297 - v_u_71) < 0.0005 then
					v_u_71 = v297
				end
			end
			v_u_16.BackgroundTransparency = v_u_17 + (1 - v_u_17) * v_u_71
			v298 = v_u_14.FieldOfView
			if v_u_10(v298 - v_u_21) > 0.01 then
				v_u_20 = v298
			end
			v299 = v_u_11(v_u_20 * (1 - v_u_71 * 0.5), 1, 120)
			if v_u_10(v299 - v298) > 0.001 then
				v_u_14.FieldOfView = v299
			end
			v_u_21 = v299
		end
		if v_u_73 and (v_u_72 and not v238) then
			v300 = true
			if not v_u_36 then
				v_u_73 = false
			end
		elseif v_u_36 then
			v301 = v_u_15:FindFirstChild("Head")
			v302 = v301 and v301.Position or v240 + Vector3.new(0, 1.5, 0)
			v300 = (v_u_14.CFrame.Position - v302).Magnitude <= v_u_69 + 0.4
		else
			v300 = v_u_72
		end
		if v300 then
			v303 = not v_u_157
		else
			v303 = v300
		end
		v304 = not v300
		if v304 then
			v304 = v_u_157
		end
		v_u_157 = v300
		if v_u_46 then
			v_u_104 = true
			v_u_106 = (-1 / 0)
			v_u_46 = false
		end
		v305 = v_u_42 ~= v_u_66
		v_u_66 = v_u_42
		if v_u_104 and v237 - v_u_105 > 0.25 then
			v_u_104 = false
			v_u_105 = v237
			v_u_106 = v237
			v_u_130()
			v_u_154(v300, true)
		elseif v303 or (v304 or v305 and v300) or v237 - v_u_106 > 0.5 then
			v_u_106 = v237
			v_u_154(v300, v303 or v304)
		end
	end
end)