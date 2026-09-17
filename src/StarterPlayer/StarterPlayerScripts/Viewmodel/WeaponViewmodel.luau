--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local WeaponPresentationConfig = require(
	ReplicatedStorage:WaitForChild("Config"):WaitForChild("WeaponPresentationConfig")
)
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local WeaponViewmodel = {}

local AVATAR_ARM_NAMES = {
	"Right Arm",
	"Left Arm",
	"RightUpperArm",
	"RightLowerArm",
	"RightHand",
	"LeftUpperArm",
	"LeftLowerArm",
	"LeftHand",
}

local function poseFromConfig(position: Vector3, rotation: Vector3): CFrame
	return CFrame.new(position) * CFrame.Angles(
		math.rad(rotation.X),
		math.rad(rotation.Y),
		math.rad(rotation.Z)
	)
end

local function findVisualMotor(tool: Tool, motorName: string, partNames: {string}): Motor6D?
	local namedMotor = tool:FindFirstChild(motorName, true)
	if namedMotor and namedMotor:IsA("Motor6D") then
		return namedMotor
	end

	for _, descendant in tool:GetDescendants() do
		if descendant:IsA("Motor6D") and descendant.Part1
			and table.find(partNames, descendant.Part1.Name) then
			return descendant
		end
	end

	return nil
end

local function makeArm(name: string, color: Color3, parent: Model): BasePart
	local arm = Instance.new("Part")
	arm.Name = name
	arm.Size = WeaponPresentationConfig.ArmSize
	arm.Color = color
	arm.Material = Enum.Material.SmoothPlastic
	arm.Anchored = true
	arm.CanCollide = false
	arm.CanQuery = false
	arm.CanTouch = false
	arm.Massless = true
	arm.CastShadow = false
	arm.Parent = parent
	return arm
end

function WeaponViewmodel.new(localPlayer: Player)
	local activeTool: Tool? = nil
	local baseGrip = CFrame.new()
	local cylinderMotor: Motor6D? = nil
	local hammerMotor: Motor6D? = nil
	local triggerMotor: Motor6D? = nil
	local toolActivatedConnection: RBXScriptConnection? = nil

	local viewmodel: Model? = nil
	local viewmodelParts: {[string]: BasePart} = {}
	local viewmodelOffsets: {[BasePart]: CFrame} = {}
	local rightArm: BasePart? = nil
	local leftArm: BasePart? = nil
	local muzzleAttachment: Attachment? = nil
	local muzzleLight: PointLight? = nil
	local muzzleParticles: ParticleEmitter? = nil
	local flashSerial = 0

	local controller = {}

	local function getEquippedLocalTool(): Tool?
		local character = localPlayer.Character
		if not character then
			return nil
		end
		local revolver = character:FindFirstChild(Constants.Instances.Revolver)
		if revolver and revolver:IsA("Tool") then
			return revolver
		end
		return nil
	end

	local function clearViewmodel()
		flashSerial += 1
		if viewmodel then
			viewmodel:Destroy()
			viewmodel = nil
		end
		table.clear(viewmodelParts)
		table.clear(viewmodelOffsets)
		rightArm = nil
		leftArm = nil
		muzzleAttachment = nil
		muzzleLight = nil
		muzzleParticles = nil
	end

	local function getActualVisualPart(preferredName: string): BasePart?
		local tool = getEquippedLocalTool()
		if tool then
			local preferred = tool:FindFirstChild(preferredName, true)
			if preferred and preferred:IsA("BasePart") then
				return preferred
			end

			local handle = tool:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") then
				return handle
			end
		end

		local character = localPlayer.Character
		if character then
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			if rootPart and rootPart:IsA("BasePart") then
				return rootPart
			end
		end

		return nil
	end

	local function createViewmodel(tool: Tool)
		local handle = tool:FindFirstChild("Handle")
		if not handle or not handle:IsA("BasePart") then
			return
		end

		local camera = Workspace.CurrentCamera
		if camera then
			local stale = camera:FindFirstChild("RevolverViewmodel")
			if stale then
				stale:Destroy()
			end
		end

		local model = Instance.new("Model")
		model.Name = "RevolverViewmodel"
		local gun = Instance.new("Model")
		gun.Name = "Revolver"
		gun.Parent = model

		local skinColor = Color3.fromRGB(184, 145, 108)
		local character = localPlayer.Character
		if character then
			local avatarArm = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
			if avatarArm and avatarArm:IsA("BasePart") then
				skinColor = avatarArm.Color
			end
		end

		rightArm = makeArm("RightArm", skinColor, model)
		leftArm = makeArm("LeftArm", skinColor, model)
		for _, descendant in tool:GetDescendants() do
			if descendant:IsA("BasePart") then
				local clone = descendant:Clone() :: BasePart
				for _, child in clone:GetDescendants() do
					if child:IsA("JointInstance") or child:IsA("WeldConstraint")
						or child:IsA("Script") or child:IsA("LocalScript") or child:IsA("Sound") then
						child:Destroy()
					end
				end
				clone.Anchored = true
				clone.CanCollide = false
				clone.CanQuery = false
				clone.CanTouch = false
				clone.CastShadow = false
				clone.Massless = true
				clone.LocalTransparencyModifier = 0
				clone.Parent = gun
				viewmodelParts[descendant.Name] = clone
				viewmodelOffsets[clone] = handle.CFrame:ToObjectSpace(descendant.CFrame)
			end
		end

		local attachment = gun:FindFirstChild("Muzzle", true)
		if attachment and attachment:IsA("Attachment") then
			muzzleAttachment = attachment
		end
		if muzzleAttachment then
			local light = Instance.new("PointLight")
			light.Name = "MuzzleLight"
			light.Color = Color3.fromRGB(255, 190, 78)
			light.Brightness = 3.2
			light.Range = 7
			light.Shadows = false
			light.Enabled = false
			light.Parent = muzzleAttachment
			muzzleLight = light

			local particles = Instance.new("ParticleEmitter")
			particles.Name = "MuzzleFlash"
			particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			particles.Color = ColorSequence.new(
				Color3.fromRGB(255, 235, 150),
				Color3.fromRGB(255, 119, 45)
			)
			particles.LightEmission = 1
			particles.Lifetime = NumberRange.new(0.025, 0.045)
			particles.Rate = 0
			particles.Speed = NumberRange.new(4, 7)
			particles.SpreadAngle = Vector2.new(10, 10)
			particles.Size = NumberSequence.new(0.13, 0)
			particles.Transparency = NumberSequence.new(0.1, 1)
			particles.EmissionDirection = Enum.NormalId.Front
			particles.Parent = muzzleAttachment
			muzzleParticles = particles
		end

		viewmodel = model
	end

	local function positionViewmodel(
		root: CFrame,
		cylinderAngle: number,
		hammerAmount: number,
		triggerAmount: number,
		cylinderOpen: number
	)
		for clone, offset in viewmodelOffsets do
			if clone.Name == "Cylinder" and cylinderMotor then
				clone.CFrame = root * cylinderMotor.C0
					* CFrame.new(0, cylinderOpen, 0)
					* CFrame.Angles(cylinderAngle, 0, 0) * cylinderMotor.C1:Inverse()
			elseif clone.Name == "Cylinder" then
				clone.CFrame = root * offset * clone.PivotOffset
					* CFrame.new(0, cylinderOpen, 0)
					* CFrame.Angles(cylinderAngle, 0, 0) * clone.PivotOffset:Inverse()
			elseif clone.Name == "Hammer" and hammerMotor then
				clone.CFrame = root * hammerMotor.C0
					* CFrame.Angles(0, math.rad(-WeaponPresentationConfig.HammerPullDegrees * hammerAmount), 0)
					* hammerMotor.C1:Inverse()
			elseif clone.Name == "Hammer" then
				clone.CFrame = root * offset * clone.PivotOffset
					* CFrame.Angles(0, math.rad(-WeaponPresentationConfig.HammerPullDegrees * hammerAmount), 0)
					* clone.PivotOffset:Inverse()
			elseif clone.Name == "Trigger" and triggerMotor then
				clone.CFrame = root * triggerMotor.C0
					* CFrame.Angles(0, math.rad(WeaponPresentationConfig.TriggerPullDegrees * triggerAmount), 0)
					* triggerMotor.C1:Inverse()
			elseif clone.Name == "Trigger" then
				clone.CFrame = root * offset * clone.PivotOffset
					* CFrame.Angles(0, math.rad(WeaponPresentationConfig.TriggerPullDegrees * triggerAmount), 0)
					* clone.PivotOffset:Inverse()
			else
				clone.CFrame = root * offset
			end
		end

		if rightArm then
			rightArm.CFrame = root * poseFromConfig(
				WeaponPresentationConfig.RightArmPosition,
				WeaponPresentationConfig.RightArmRotation
			)
		end
		if leftArm then
			leftArm.CFrame = root * poseFromConfig(
				WeaponPresentationConfig.LeftArmPosition,
				WeaponPresentationConfig.LeftArmRotation
			)
		end
	end

	function controller.SetActiveTool(tool: Tool?, onActivated: () -> ()): boolean
		if tool == activeTool then
			return false
		end

		if activeTool and activeTool.Parent then
			activeTool.Grip = baseGrip
			for _, descendant in activeTool:GetDescendants() do
				if descendant:IsA("BasePart") then
					descendant.LocalTransparencyModifier = 0
				end
			end
		end
		if cylinderMotor and cylinderMotor.Parent then
			cylinderMotor.Transform = CFrame.new()
		end
		if hammerMotor and hammerMotor.Parent then
			hammerMotor.Transform = CFrame.new()
		end
		if triggerMotor and triggerMotor.Parent then
			triggerMotor.Transform = CFrame.new()
		end
		if toolActivatedConnection then
			toolActivatedConnection:Disconnect()
			toolActivatedConnection = nil
		end
		clearViewmodel()

		activeTool = tool
		baseGrip = if tool then tool.Grip else CFrame.new()
		cylinderMotor = if tool then findVisualMotor(tool, "CylinderMotor", {"Cylinder", "CylinderBlock"}) else nil
		hammerMotor = if tool then findVisualMotor(tool, "HammerMotor", {"Hammer"}) else nil
		triggerMotor = if tool then findVisualMotor(tool, "TriggerMotor", {"Trigger"}) else nil
		if tool then
			createViewmodel(tool)
			for _, descendant in tool:GetDescendants() do
				if descendant:IsA("BasePart") then
					descendant.CastShadow = false
				end
			end
			toolActivatedConnection = tool.Activated:Connect(onActivated)
		end

		return true
	end

	function controller.GetActiveTool(): Tool?
		return activeTool
	end

	function controller.GetLocalVisualPart(preferredName: string): BasePart?
		local camera = Workspace.CurrentCamera
		if viewmodel and camera and viewmodel.Parent == camera then
			local part = viewmodelParts[preferredName]
			if part then
				return part
			end
		end
		return getActualVisualPart(preferredName)
	end

	function controller.GetLocalMuzzlePosition(): Vector3?
		local camera = Workspace.CurrentCamera
		if viewmodel and camera and viewmodel.Parent == camera and muzzleAttachment then
			return muzzleAttachment.WorldPosition
		end
		local equippedTool = getEquippedLocalTool()
		if equippedTool then
			local toolMuzzle = equippedTool:FindFirstChild("Muzzle", true)
			if toolMuzzle and toolMuzzle:IsA("Attachment") then
				return toolMuzzle.WorldPosition
			end
		end
		local tip = controller.GetLocalVisualPart("BarrelTip")
		if tip then
			local toolMuzzle = tip:FindFirstChild("Muzzle")
			if toolMuzzle and toolMuzzle:IsA("Attachment") then
				return toolMuzzle.WorldPosition
			end
			return (tip.CFrame * CFrame.new(0, 0, -tip.Size.Z * 0.5)).Position
		end
		return nil
	end

	function controller.FlashMuzzle(direction: Vector3, fallback: (Vector3, Vector3) -> ())
		if muzzleAttachment and viewmodel and viewmodel.Parent == Workspace.CurrentCamera then
			flashSerial += 1
			local thisFlash = flashSerial
			if muzzleLight then
				muzzleLight.Enabled = true
			end
			if muzzleParticles then
				muzzleParticles:Emit(5)
			end
			task.delay(WeaponPresentationConfig.MuzzleFlashDuration, function()
				if thisFlash == flashSerial and muzzleLight then
					muzzleLight.Enabled = false
				end
			end)
		else
			local position = controller.GetLocalMuzzlePosition()
			if position then
				fallback(position, direction)
			end
		end
	end

	function controller.SetVisible(showViewmodel: boolean, camera: Camera?, character: Model?)
		if viewmodel then
			local desiredParent: Instance? = if showViewmodel then camera else nil
			if viewmodel.Parent ~= desiredParent then
				viewmodel.Parent = desiredParent
			end
		end
		if activeTool then
			for _, descendant in activeTool:GetDescendants() do
				if descendant:IsA("BasePart") then
					descendant.LocalTransparencyModifier = if showViewmodel then 1 else 0
				end
			end
		end
		if character then
			for _, name in AVATAR_ARM_NAMES do
				local avatarPart = character:FindFirstChild(name)
				if avatarPart and avatarPart:IsA("BasePart") then
					avatarPart.LocalTransparencyModifier = if showViewmodel then 1 else 0
				end
			end
		end
	end

	function controller.ApplyFrame(frame: any)
		if activeTool then
			activeTool.Grip = baseGrip
		end
		if frame.ViewRoot then
			positionViewmodel(
				frame.ViewRoot,
				frame.CylinderAngle,
				frame.HammerAmount,
				frame.TriggerAmount,
				frame.CylinderOpen
			)
		end

		if cylinderMotor and cylinderMotor.Parent then
			-- Imported Blender Local X is the cylinder spindle.
			cylinderMotor.Transform = CFrame.Angles(frame.CylinderAngle, 0, 0)
		end
		if hammerMotor and hammerMotor.Parent then
			hammerMotor.Transform = CFrame.Angles(
				0,
				math.rad(-WeaponPresentationConfig.HammerPullDegrees * frame.HammerAmount),
				0
			)
		end
		if triggerMotor and triggerMotor.Parent then
			triggerMotor.Transform = CFrame.Angles(
				0,
				math.rad(WeaponPresentationConfig.TriggerPullDegrees * frame.TriggerAmount),
				0
			)
		end
	end

	return table.freeze(controller)
end

return table.freeze(WeaponViewmodel)
