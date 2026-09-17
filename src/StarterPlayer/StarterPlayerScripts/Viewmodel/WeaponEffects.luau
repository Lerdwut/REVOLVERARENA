--!strict

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local configFolder = ReplicatedStorage:WaitForChild("Config")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local WeaponPresentationConfig = require(configFolder:WaitForChild("WeaponPresentationConfig"))
local Constants = require(sharedFolder:WaitForChild("Constants"))

local MAX_TRACER_DISTANCE = 300

local WeaponEffects = {}

function WeaponEffects.new(localPlayer: Player, settingsStore: any, gameAudio: any, viewmodel: any)
	local random = Random.new()
	local activeSounds: {[string]: Sound} = {}
	local controller = {}

	function controller.GetEquippedRevolver(player: Player): Tool?
		local character = player.Character
		if not character then
			return nil
		end

		local revolver = character:FindFirstChild(Constants.Instances.Revolver)
		if revolver and revolver:IsA("Tool") then
			return revolver
		end

		return nil
	end

	function controller.GetEffectPart(player: Player, preferredName: string): BasePart?
		local revolver = controller.GetEquippedRevolver(player)
		if revolver then
			local preferred = revolver:FindFirstChild(preferredName, true)
			if preferred and preferred:IsA("BasePart") then
				return preferred
			end

			local handle = revolver:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") then
				return handle
			end
		end

		local character = player.Character
		if character then
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			if rootPart and rootPart:IsA("BasePart") then
				return rootPart
			end
		end

		return nil
	end

	function controller.PlayControlledSound(
		channel: string,
		parent: BasePart?,
		soundId: string,
		volume: number,
		playbackSpeed: number
	)
		if not parent or soundId == "" then
			return
		end

		local previous = activeSounds[channel]
		if previous then
			activeSounds[channel] = nil
			previous:Stop()
			previous:Destroy()
		end

		local sound = Instance.new("Sound")
		sound.Name = "RevolverAudio"
		sound.SoundId = soundId
		sound.Volume = volume
		sound.PlaybackSpeed = playbackSpeed
		sound.SoundGroup = gameAudio.WeaponGroup
		sound.RollOffMinDistance = 8
		sound.RollOffMaxDistance = 110
		sound.Parent = parent
		activeSounds[channel] = sound

		sound.Ended:Connect(function()
			if activeSounds[channel] == sound then
				activeSounds[channel] = nil
			end
			sound:Destroy()
		end)
		sound.Destroying:Connect(function()
			if activeSounds[channel] == sound then
				activeSounds[channel] = nil
			end
		end)

		sound:Play()
		Debris:AddItem(sound, 4)
	end

	function controller.PlayFireSound(player: Player, parent: BasePart?)
		local pitchVariation = WeaponPresentationConfig.FirePitchVariation
		controller.PlayControlledSound(
			string.format("Fire:%d", player.UserId),
			parent,
			WeaponPresentationConfig.FireSoundId,
			WeaponPresentationConfig.FireVolume,
			1 + random:NextNumber(-pitchVariation, pitchVariation)
		)
	end

	function controller.PlayMechanism()
		controller.PlayControlledSound(
			string.format("Mechanism:%d", localPlayer.UserId),
			viewmodel.GetLocalVisualPart("Handle"),
			WeaponPresentationConfig.MechanicalSoundId,
			WeaponPresentationConfig.MechanicalVolume,
			1.06
		)
	end

	function controller.PlayReload(player: Player)
		controller.PlayControlledSound(
			string.format("Reload:%d", player.UserId),
			if player == localPlayer
				then viewmodel.GetLocalVisualPart("Handle")
				else controller.GetEffectPart(player, "Handle"),
			WeaponPresentationConfig.ReloadSoundId,
			WeaponPresentationConfig.ReloadVolume,
			1
		)
	end

	function controller.PlayCylinder()
		controller.PlayControlledSound(
			string.format("Cylinder:%d", localPlayer.UserId),
			viewmodel.GetLocalVisualPart("Cylinder"),
			WeaponPresentationConfig.CylinderSoundId,
			WeaponPresentationConfig.CylinderVolume,
			1.02
		)
	end

	function controller.PlayEmpty()
		controller.PlayControlledSound(
			string.format("Empty:%d", localPlayer.UserId),
			viewmodel.GetLocalVisualPart("Handle"),
			WeaponPresentationConfig.EmptySoundId,
			WeaponPresentationConfig.EmptyVolume,
			1.08
		)
	end

	function controller.PlayEquip()
		controller.PlayControlledSound(
			string.format("Equip:%d", localPlayer.UserId),
			viewmodel.GetLocalVisualPart("Handle"),
			WeaponPresentationConfig.EquipSoundId,
			WeaponPresentationConfig.EquipVolume,
			1
		)
	end

	function controller.CreateMuzzleFlash(position: Vector3, requestedDirection: Vector3)
		local direction = if requestedDirection.Magnitude > 0.01
			then requestedDirection.Unit
			else Vector3.new(0, 0, -1)
		local duration = WeaponPresentationConfig.MuzzleFlashDuration

		local flash = Instance.new("Part")
		flash.Name = "RevolverMuzzleFlash"
		flash.Anchored = true
		flash.CanCollide = false
		flash.CanQuery = false
		flash.CanTouch = false
		flash.CastShadow = false
		flash.Color = Color3.fromRGB(255, 197, 78)
		flash.Material = Enum.Material.Neon
		flash.Shape = Enum.PartType.Ball
		flash.Size = Vector3.new(0.24, 0.24, 0.36)
		flash.CFrame = CFrame.lookAt(position, position + direction)
		flash.Parent = Workspace

		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 178, 62)
		light.Brightness = 3.2
		light.Range = 8
		light.Shadows = false
		light.Parent = flash

		local sparks = Instance.new("ParticleEmitter")
		sparks.Name = "Sparks"
		sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparks.Color = ColorSequence.new(
			Color3.fromRGB(255, 226, 130),
			Color3.fromRGB(255, 128, 42)
		)
		sparks.LightEmission = 1
		sparks.Lifetime = NumberRange.new(duration * 0.55, duration)
		sparks.Rate = 0
		sparks.Speed = NumberRange.new(6, 11)
		sparks.SpreadAngle = Vector2.new(12, 12)
		sparks.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.11),
			NumberSequenceKeypoint.new(1, 0),
		})
		sparks.Transparency = NumberSequence.new(0.05, 1)
		sparks.EmissionDirection = Enum.NormalId.Front
		sparks.Parent = flash
		sparks:Emit(4)

		TweenService:Create(
			flash,
			TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = Vector3.new(0.5, 0.5, 0.7), Transparency = 1}
		):Play()
		task.delay(duration, function()
			if light.Parent then
				light.Enabled = false
			end
		end)
		Debris:AddItem(flash, duration + 0.04)
	end

	function controller.FlashLocalMuzzle(direction: Vector3)
		viewmodel.FlashMuzzle(direction, controller.CreateMuzzleFlash)
	end

	function controller.CreateTracer(startPosition: Vector3, requestedEndPosition: Vector3)
		if not settingsStore.GetBoolean("TracersEnabled") then
			return
		end
		local displacement = requestedEndPosition - startPosition
		local distance = displacement.Magnitude
		if distance < 0.05 then
			return
		end

		local direction = displacement.Unit
		local endPosition = requestedEndPosition
		if distance > MAX_TRACER_DISTANCE then
			distance = MAX_TRACER_DISTANCE
			endPosition = startPosition + direction * distance
		end

		local segmentLength = math.min(distance, WeaponPresentationConfig.TracerLength)
		local startCenter = startPosition + direction * (segmentLength * 0.5)
		local endCenter = endPosition - direction * (segmentLength * 0.5)

		local tracer = Instance.new("Part")
		tracer.Name = "RevolverTracer"
		tracer.Anchored = true
		tracer.CanCollide = false
		tracer.CanQuery = false
		tracer.CanTouch = false
		tracer.CastShadow = false
		tracer.Color = Color3.fromRGB(255, 218, 126)
		tracer.Material = Enum.Material.Neon
		tracer.Transparency = 0.12
		tracer.Size = Vector3.new(
			WeaponPresentationConfig.TracerWidth,
			WeaponPresentationConfig.TracerWidth,
			segmentLength
		)
		tracer.CFrame = CFrame.lookAt(startCenter, startCenter + direction)
		tracer.Parent = Workspace

		TweenService:Create(
			tracer,
			TweenInfo.new(WeaponPresentationConfig.TracerLifetime, Enum.EasingStyle.Linear),
			{
				CFrame = CFrame.lookAt(endCenter, endCenter + direction),
				Transparency = 0.82,
			}
		):Play()
		Debris:AddItem(tracer, WeaponPresentationConfig.TracerLifetime + 0.015)
	end

	return table.freeze(controller)
end

return table.freeze(WeaponEffects)
