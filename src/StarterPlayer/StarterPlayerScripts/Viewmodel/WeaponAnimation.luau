--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local configFolder = ReplicatedStorage:WaitForChild("Config")
local WeaponConfig = require(configFolder:WaitForChild("WeaponConfig"))
local WeaponPresentationConfig = require(configFolder:WaitForChild("WeaponPresentationConfig"))

type VisualState = "Hidden" | "Equip" | "Idle" | "Fire" | "Reload" | "Roll"

export type Frame = {
	VisualState: VisualState,
	ViewRoot: CFrame?,
	CylinderAngle: number,
	HammerAmount: number,
	TriggerAmount: number,
	CylinderOpen: number,
	PlayEquipSound: boolean,
}

local WeaponAnimation = {}

local function easeOutCubic(value: number): number
	local inverse = 1 - math.clamp(value, 0, 1)
	return 1 - inverse * inverse * inverse
end

local function smoothStep(value: number): number
	local clamped = math.clamp(value, 0, 1)
	return clamped * clamped * (3 - 2 * clamped)
end

local function poseFromConfig(position: Vector3, rotation: Vector3): CFrame
	return CFrame.new(position) * CFrame.Angles(
		math.rad(rotation.X),
		math.rad(rotation.Y),
		math.rad(rotation.Z)
	)
end

function WeaponAnimation.new()
	local random = Random.new()
	local visualState: VisualState = "Idle"
	local sway = Vector2.zero
	local movementBlend = 0
	local walkClock = 0
	local rollBlend = 0
	local strafeBlend = 0
	local landingBlend = 0
	local wasAirborne = false
	local equipStartedAt = -math.huge
	local lastEquipSoundAt = -math.huge
	local emptyStartedAt = -math.huge

	local fireStartedAt = -math.huge
	local fireYawDegrees = 0
	local cylinderStartAngle = 0
	local cylinderTargetAngle = 0
	local reloadCylinderStartAngle = 0
	local reloadStartedAt = -math.huge
	local predictedReloadUntil = -math.huge
	local predictedRollUntil = -math.huge
	local cameraFovOffset = 0

	local controller = {}

	local function getFirePose(now: number): (number, number, number)
		local elapsed = now - fireStartedAt
		if elapsed < 0 then
			return 0, 0, cylinderTargetAngle
		end

		if elapsed < WeaponPresentationConfig.FireKickDuration then
			local alpha = easeOutCubic(elapsed / WeaponPresentationConfig.FireKickDuration)
			local hammerAmount = 1 - alpha
			local cylinderAngle = cylinderStartAngle
				+ (cylinderTargetAngle - cylinderStartAngle) * alpha
			return alpha, hammerAmount, cylinderAngle
		end

		local recoveryElapsed = elapsed - WeaponPresentationConfig.FireKickDuration
		if recoveryElapsed < WeaponPresentationConfig.FireRecoveryDuration then
			local alpha = smoothStep(recoveryElapsed / WeaponPresentationConfig.FireRecoveryDuration)
			return 1 - alpha, 0, cylinderTargetAngle
		end

		return 0, 0, cylinderTargetAngle
	end

	local function resolveVisualState(
		now: number,
		fireAmount: number,
		serverRolling: boolean,
		serverReloading: boolean
	): VisualState
		if serverRolling or now < predictedRollUntil then
			return "Roll"
		end
		if serverReloading or now < predictedReloadUntil then
			return "Reload"
		end
		if fireAmount > 0.0001 then
			return "Fire"
		end
		if now - equipStartedAt < WeaponPresentationConfig.EquipDuration then
			return "Equip"
		end
		return "Idle"
	end

	function controller.OnToolChanged(tool: Tool?, now: number)
		if tool then
			equipStartedAt = now
			lastEquipSoundAt = -math.huge
		end
	end

	function controller.StartEmpty(now: number, cancelEquip: boolean)
		if cancelEquip then
			equipStartedAt = -math.huge
		end
		emptyStartedAt = now
	end

	function controller.StartFire(now: number)
		fireStartedAt = now
		equipStartedAt = -math.huge
		fireYawDegrees = random:NextNumber(
			-WeaponPresentationConfig.CameraYawDegrees,
			WeaponPresentationConfig.CameraYawDegrees
		)
		cylinderStartAngle = cylinderTargetAngle
		cylinderTargetAngle += math.rad(60)
		emptyStartedAt = -math.huge
	end

	function controller.StartReload(now: number)
		reloadStartedAt = now
		equipStartedAt = -math.huge
		reloadCylinderStartAngle = cylinderTargetAngle
		cylinderTargetAngle += math.rad(WeaponPresentationConfig.ReloadCylinderSpinDegrees)
		predictedReloadUntil = now + WeaponConfig.ReloadDuration
	end

	function controller.StartRoll(now: number)
		equipStartedAt = -math.huge
		predictedRollUntil = now + WeaponConfig.RollDuration
		predictedReloadUntil = -math.huge
	end

	function controller.IsVisualRolling(now: number, serverRolling: boolean): boolean
		return serverRolling or now < predictedRollUntil
	end

	function controller.IsVisualReloading(now: number, serverReloading: boolean): boolean
		return serverReloading or now < predictedReloadUntil
	end

	function controller.GetReloadStartedAt(): number
		return reloadStartedAt
	end

	function controller.ClearCombatState()
		fireStartedAt = -math.huge
		predictedReloadUntil = -math.huge
		predictedRollUntil = -math.huge
	end

	function controller.Reset(camera: Camera?)
		if camera then
			camera.FieldOfView -= cameraFovOffset
		end
		cameraFovOffset = 0
		visualState = "Idle"
		sway = Vector2.zero
		movementBlend = 0
		rollBlend = 0
		strafeBlend = 0
		landingBlend = 0
		wasAirborne = false
		equipStartedAt = -math.huge
		emptyStartedAt = -math.huge
		fireStartedAt = -math.huge
		reloadStartedAt = -math.huge
		predictedReloadUntil = -math.huge
		predictedRollUntil = -math.huge
		cylinderStartAngle = 0
		cylinderTargetAngle = 0
		reloadCylinderStartAngle = 0
	end

	function controller.Step(
		deltaTime: number,
		now: number,
		tool: Tool?,
		camera: Camera?,
		character: Model?,
		inArena: boolean,
		showViewmodel: boolean,
		serverRolling: boolean,
		serverReloading: boolean,
		swayEnabled: boolean,
		bobEnabled: boolean
	): Frame?
		local dt = math.min(deltaTime, 1 / 15)
		local fireAmount, hammerAmount, cylinderAngle = getFirePose(now)
		visualState = if tool and inArena
			then resolveVisualState(now, fireAmount, serverRolling, serverReloading)
			else "Hidden"
		local activeFireAmount = if visualState == "Fire" then fireAmount else 0

		if camera then
			camera.FieldOfView -= cameraFovOffset
			cameraFovOffset = if tool then WeaponPresentationConfig.CameraFovDegrees * activeFireAmount else 0
			camera.FieldOfView += cameraFovOffset
			if tool and visualState == "Fire" then
				camera.CFrame *= CFrame.Angles(
					math.rad(WeaponPresentationConfig.CameraPitchDegrees * activeFireAmount),
					math.rad(fireYawDegrees * activeFireAmount),
					0
				)
			end
		end

		if not tool then
			return nil
		end

		local playEquipSound = showViewmodel and visualState == "Equip"
			and lastEquipSoundAt ~= equipStartedAt
		if playEquipSound then
			lastEquipSoundAt = equipStartedAt
		end

		local mouseDelta = UserInputService:GetMouseDelta()
		local swayTarget = if swayEnabled
			then Vector2.new(
				math.clamp(-mouseDelta.X / 18, -1, 1),
				math.clamp(-mouseDelta.Y / 18, -1, 1)
			)
			else Vector2.zero
		sway = if swayEnabled
			then sway:Lerp(swayTarget, 1 - math.exp(-WeaponPresentationConfig.SwayResponse * dt))
			else Vector2.zero

		local humanoid: Humanoid? = nil
		if character then
			local candidate = character:FindFirstChildOfClass("Humanoid")
			if candidate and candidate:IsA("Humanoid") then
				humanoid = candidate
			end
		end

		local moving = humanoid ~= nil
			and humanoid.MoveDirection.Magnitude > 0.1
			and humanoid.FloorMaterial ~= Enum.Material.Air
		local targetMovementBlend = if moving then 1 else 0
		movementBlend += (targetMovementBlend - movementBlend)
			* (1 - math.exp(-WeaponPresentationConfig.MovementResponse * dt))
		if moving and humanoid then
			walkClock += dt * (WeaponPresentationConfig.WalkBobSpeed + humanoid.WalkSpeed * 0.035)
		end
		local airborne = humanoid ~= nil and humanoid.FloorMaterial == Enum.Material.Air
		if wasAirborne and not airborne then
			landingBlend = 1
		end
		wasAirborne = airborne
		landingBlend *= math.exp(-WeaponPresentationConfig.LandingRecovery * dt)
		local strafeTarget = 0
		if humanoid and camera then
			strafeTarget = math.clamp(humanoid.MoveDirection:Dot(camera.CFrame.RightVector), -1, 1)
		end
		strafeBlend += (strafeTarget - strafeBlend)
			* (1 - math.exp(-WeaponPresentationConfig.MovementResponse * dt))

		local motionScale = 1
		if visualState == "Fire" then
			motionScale = 1 - activeFireAmount * 0.82
		elseif visualState == "Reload" then
			motionScale = 0.35
		elseif visualState == "Roll" then
			motionScale = 0.12
		end

		local swayAmount = WeaponPresentationConfig.SwayDegrees * motionScale
		local swayPose = CFrame.Angles(
			math.rad(sway.Y * swayAmount),
			math.rad(sway.X * swayAmount),
			math.rad(-sway.X * swayAmount * 0.35)
		)

		local bobScale = if bobEnabled then movementBlend * motionScale else 0
		local bobX = math.sin(walkClock) * WeaponPresentationConfig.WalkBobDistance * bobScale
		local bobY = math.cos(walkClock * 2) * WeaponPresentationConfig.WalkBobDistance * 0.55 * bobScale
		local bobRotation = math.sin(walkClock) * WeaponPresentationConfig.WalkBobDegrees * bobScale
		local bobPose = CFrame.new(bobX, bobY, 0)
			* CFrame.Angles(math.rad(-math.abs(bobRotation) * 0.35), 0, math.rad(-bobRotation))
		local movementPose = CFrame.new(0, -landingBlend * WeaponPresentationConfig.LandingDip, 0)
			* CFrame.Angles(0, 0, math.rad(-strafeBlend * WeaponPresentationConfig.StrafeLeanDegrees))

		local firePose = poseFromConfig(
			WeaponPresentationConfig.FireKickPosition * activeFireAmount,
			WeaponPresentationConfig.FireKickRotation * activeFireAmount
		)
		local emptyElapsed = now - emptyStartedAt
		local emptyAmount = if (visualState == "Idle" or visualState == "Equip")
			and emptyElapsed >= 0 and emptyElapsed < WeaponPresentationConfig.EmptyClickDuration
			then math.sin(math.pi * emptyElapsed / WeaponPresentationConfig.EmptyClickDuration)
			else 0
		local emptyPose = poseFromConfig(
			WeaponPresentationConfig.EmptyClickPosition * emptyAmount,
			WeaponPresentationConfig.EmptyClickRotation * emptyAmount
		)
		local equipAmount = if visualState == "Equip"
			then 1 - easeOutCubic((now - equipStartedAt) / WeaponPresentationConfig.EquipDuration)
			else 0
		local equipPose = poseFromConfig(
			WeaponPresentationConfig.EquipStartPosition * equipAmount,
			WeaponPresentationConfig.EquipStartRotation * equipAmount
		)

		local reloadPose = CFrame.new()
		local cylinderOpen = 0
		local visualCylinderAngle = cylinderAngle
		if visualState == "Reload" then
			local reloadAlpha = math.clamp((now - reloadStartedAt) / WeaponConfig.ReloadDuration, 0, 1)
			local hold = smoothStep(reloadAlpha / 0.18)
				* (1 - smoothStep((reloadAlpha - 0.78) / 0.22))
			reloadPose = CFrame.new(
				-WeaponPresentationConfig.ReloadCenterDistance * hold,
				-WeaponPresentationConfig.ReloadLowerDistance * hold,
				WeaponPresentationConfig.ReloadBackDistance * hold
			) * CFrame.Angles(
				math.rad(WeaponPresentationConfig.ReloadPitchDegrees * hold),
				0,
				math.rad(WeaponPresentationConfig.ReloadTiltDegrees * hold)
			)
			local open = smoothStep((reloadAlpha - 0.19) / 0.11)
				* (1 - smoothStep((reloadAlpha - 0.73) / 0.13))
			cylinderOpen = WeaponPresentationConfig.ReloadCylinderOpenDistance * open
			visualCylinderAngle = reloadCylinderStartAngle
				+ math.rad(WeaponPresentationConfig.ReloadCylinderSpinDegrees)
					* smoothStep((reloadAlpha - 0.32) / 0.46)
		end

		local rollTarget = if visualState == "Roll" then 1 else 0
		rollBlend += (rollTarget - rollBlend) * (1 - math.exp(-14 * dt))
		local rollPose = CFrame.new(
			WeaponPresentationConfig.RollSideDistance * rollBlend,
			-WeaponPresentationConfig.RollLowerDistance * rollBlend,
			WeaponPresentationConfig.RollBackDistance * rollBlend
		) * CFrame.Angles(
			math.rad(WeaponPresentationConfig.RollPitchDegrees * rollBlend),
			0,
			math.rad(WeaponPresentationConfig.RollTiltDegrees * rollBlend)
		)

		local triggerElapsed = now - fireStartedAt
		local triggerAmount = if visualState == "Fire" and triggerElapsed >= 0
			and triggerElapsed < 0.11
			then math.sin(math.pi * triggerElapsed / 0.11)
			else 0
		local activeHammerAmount = if visualState == "Fire" then hammerAmount else 0
		local viewRoot: CFrame? = nil
		if showViewmodel and camera then
			viewRoot = camera.CFrame
				* poseFromConfig(
					WeaponPresentationConfig.ViewmodelPosition,
					WeaponPresentationConfig.ViewmodelRotation
				)
				* CFrame.new(
					sway.X * WeaponPresentationConfig.SwayPosition,
					sway.Y * WeaponPresentationConfig.SwayPosition * 0.5,
					0
				)
				* swayPose * bobPose * movementPose * equipPose
				* reloadPose * rollPose * emptyPose * firePose
		end

		return {
			VisualState = visualState,
			ViewRoot = viewRoot,
			CylinderAngle = visualCylinderAngle,
			HammerAmount = activeHammerAmount,
			TriggerAmount = triggerAmount,
			CylinderOpen = cylinderOpen,
			PlayEquipSound = playEquipSound,
		}
	end

	return table.freeze(controller)
end

return table.freeze(WeaponAnimation)
