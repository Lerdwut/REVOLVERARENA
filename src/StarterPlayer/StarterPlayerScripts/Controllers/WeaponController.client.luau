--!strict

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local configFolder = ReplicatedStorage:WaitForChild("Config")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local WeaponConfig = require(configFolder:WaitForChild("WeaponConfig"))
local Constants = require(sharedFolder:WaitForChild("Constants"))
local GameState = require(sharedFolder:WaitForChild("GameState"))

local clientRoot = script.Parent.Parent
local clientShared = clientRoot:WaitForChild("Shared")
local viewmodelFolder = clientRoot:WaitForChild("Viewmodel")
local SettingsStore = require(clientShared:WaitForChild("SettingsStore"))
local GameAudio = require(clientShared:WaitForChild("GameAudio"))
local WeaponAnimation = require(viewmodelFolder:WaitForChild("WeaponAnimation"))
local WeaponEffects = require(viewmodelFolder:WaitForChild("WeaponEffects"))
local WeaponViewmodel = require(viewmodelFolder:WaitForChild("WeaponViewmodel"))

local localPlayer = Players.LocalPlayer
local remotesFolder = ReplicatedStorage:WaitForChild(Constants.Remotes.Folder)
local fireRevolver = remotesFolder:WaitForChild(Constants.Remotes.Fire) :: RemoteEvent
local reloadRevolver = remotesFolder:WaitForChild(Constants.Remotes.Reload) :: RemoteEvent
local requestCombatRoll = remotesFolder:WaitForChild(Constants.Remotes.RequestRoll) :: RemoteEvent
local weaponEffectsRemote = remotesFolder:WaitForChild(Constants.Remotes.WeaponEffects) :: RemoteEvent

local AMMO_ATTRIBUTE = Constants.Attributes.Ammo
local RELOADING_ATTRIBUTE = Constants.Attributes.Reloading
local ROLLING_ATTRIBUTE = Constants.Attributes.Rolling
local ROLL_READY_AT_ATTRIBUTE = Constants.Attributes.RollReadyAt
local RENDER_STEP_NAME = "RevolverGunFeel"
local LOCAL_ROLL_REQUEST_INTERVAL = 0.2
local LOCAL_EMPTY_INTERVAL = 0.2
local PREDICTION_MATCH_WINDOW = 1.25

local viewmodel = WeaponViewmodel.new(localPlayer)
local effects = WeaponEffects.new(localPlayer, SettingsStore, GameAudio, viewmodel)
local animation = WeaponAnimation.new()

local lastLocalShotRequestAt = -math.huge
local lastLocalEmptyAt = -math.huge
local lastRollRequestAt = -math.huge
local lastPredictedShotAt = -math.huge
local lastPredictedReloadAt = -math.huge
local lastPredictedEmptyAt = -math.huge

local function getAmmo(): number
	local ammo = localPlayer:GetAttribute(AMMO_ATTRIBUTE)
	return if typeof(ammo) == "number" then ammo else WeaponConfig.AmmoCapacity
end

local function isServerRolling(): boolean
	return localPlayer:GetAttribute(ROLLING_ATTRIBUTE) == true
end

local function isServerReloading(): boolean
	return localPlayer:GetAttribute(RELOADING_ATTRIBUTE) == true
end

local requestShot = function() end

local function syncActiveTool(tool: Tool?, now: number)
	local changed = viewmodel.SetActiveTool(tool, function()
		requestShot()
	end)
	if changed then
		animation.OnToolChanged(tool, now)
	end
end

requestShot = function()
	if not GameState.IsArena(localPlayer) or SettingsStore.IsInputBlocked()
		or UserInputService:GetFocusedTextBox() then
		return
	end

	local tool = effects.GetEquippedRevolver(localPlayer)
	local camera = Workspace.CurrentCamera
	if not tool or not camera then
		return
	end

	local now = os.clock()
	if animation.IsVisualRolling(now, isServerRolling())
		or animation.IsVisualReloading(now, isServerReloading()) then
		return
	end

	if getAmmo() <= 0 then
		if now - lastLocalEmptyAt < LOCAL_EMPTY_INTERVAL then
			return
		end

		lastLocalEmptyAt = now
		lastPredictedEmptyAt = now
		animation.StartEmpty(now, true)
		effects.PlayEmpty()
		fireRevolver:FireServer(camera.CFrame.Position, camera.CFrame.LookVector)
		return
	end

	if now - lastLocalShotRequestAt < WeaponConfig.FireCooldown then
		return
	end

	lastLocalShotRequestAt = now
	lastPredictedShotAt = now
	syncActiveTool(tool, now)
	animation.StartFire(now)

	local muzzle = viewmodel.GetLocalVisualPart("BarrelTip")
	effects.FlashLocalMuzzle(camera.CFrame.LookVector)
	effects.PlayFireSound(localPlayer, muzzle or viewmodel.GetLocalVisualPart("Handle"))
	effects.PlayMechanism()

	-- Prediction is visual/audio only. The server still validates ammo, cadence and hit detection.
	fireRevolver:FireServer(camera.CFrame.Position, camera.CFrame.LookVector)
end

local function requestReload()
	if not GameState.IsArena(localPlayer) or SettingsStore.IsInputBlocked()
		or UserInputService:GetFocusedTextBox()
		or not effects.GetEquippedRevolver(localPlayer) then
		return
	end

	local now = os.clock()
	if animation.IsVisualRolling(now, isServerRolling())
		or animation.IsVisualReloading(now, isServerReloading())
		or getAmmo() >= WeaponConfig.AmmoCapacity then
		return
	end

	lastPredictedReloadAt = now
	animation.StartReload(now)
	effects.PlayReload(localPlayer)
	task.delay(0.31, function()
		if animation.GetReloadStartedAt() == now
			and animation.IsVisualReloading(os.clock(), isServerReloading()) then
			effects.PlayCylinder()
		end
	end)
	reloadRevolver:FireServer()
end

local function requestRoll()
	if not GameState.IsArena(localPlayer) or SettingsStore.IsInputBlocked()
		or UserInputService:GetFocusedTextBox() then
		return
	end

	local now = os.clock()
	if animation.IsVisualRolling(now, isServerRolling()) then
		return
	end

	local readyAt = localPlayer:GetAttribute(ROLL_READY_AT_ATTRIBUTE)
	if typeof(readyAt) == "number" and Workspace:GetServerTimeNow() < readyAt then
		return
	end
	if now - lastRollRequestAt < LOCAL_ROLL_REQUEST_INTERVAL then
		return
	end

	lastRollRequestAt = now
	animation.StartRoll(now)
	requestCombatRoll:FireServer()
end

weaponEffectsRemote.OnClientEvent:Connect(function(
	effectName: any,
	actor: any,
	startPosition: any,
	endPosition: any
)
	if typeof(effectName) ~= "string" or typeof(actor) ~= "Instance" or not actor:IsA("Player") then
		return
	end

	local actorPlayer = actor :: Player
	local now = os.clock()
	if effectName == "Shot" then
		if typeof(startPosition) ~= "Vector3" or typeof(endPosition) ~= "Vector3" then
			return
		end

		local direction = endPosition - startPosition
		local usedPrediction = actorPlayer == localPlayer
			and now - lastPredictedShotAt <= PREDICTION_MATCH_WINDOW
		if usedPrediction then
			lastPredictedShotAt = -math.huge
		else
			if actorPlayer == localPlayer then
				effects.FlashLocalMuzzle(direction)
			else
				local actualTool = effects.GetEquippedRevolver(actorPlayer)
				local actualMuzzle = if actualTool then actualTool:FindFirstChild("Muzzle", true) else nil
				local actualTip = effects.GetEffectPart(actorPlayer, "BarrelTip")
				local flashPosition = if actualMuzzle and actualMuzzle:IsA("Attachment")
					then actualMuzzle.WorldPosition
					elseif actualTip then actualTip.Position else startPosition
				effects.CreateMuzzleFlash(flashPosition, direction)
			end
			effects.PlayFireSound(
				actorPlayer,
				if actorPlayer == localPlayer
					then viewmodel.GetLocalVisualPart("BarrelTip")
					else effects.GetEffectPart(actorPlayer, "BarrelTip")
			)
			if actorPlayer == localPlayer then
				animation.StartFire(now)
				effects.PlayMechanism()
			end
		end

		-- The tracer always uses the server-confirmed ray result.
		local visualMuzzle: Vector3? = nil
		if actorPlayer == localPlayer then
			visualMuzzle = viewmodel.GetLocalMuzzlePosition()
		else
			local actualTool = effects.GetEquippedRevolver(actorPlayer)
			local toolAttachment = if actualTool then actualTool:FindFirstChild("Muzzle", true) else nil
			if toolAttachment and toolAttachment:IsA("Attachment") then
				visualMuzzle = toolAttachment.WorldPosition
			else
				local actualTip = effects.GetEffectPart(actorPlayer, "BarrelTip")
				if actualTip then
					local attachment = actualTip:FindFirstChild("Muzzle")
					visualMuzzle = if attachment and attachment:IsA("Attachment")
						then attachment.WorldPosition else actualTip.Position
				end
			end
		end
		effects.CreateTracer(visualMuzzle or startPosition, endPosition)
	elseif effectName == "Reload" then
		local usedPrediction = actorPlayer == localPlayer
			and now - lastPredictedReloadAt <= PREDICTION_MATCH_WINDOW
		if usedPrediction then
			lastPredictedReloadAt = -math.huge
		else
			effects.PlayReload(actorPlayer)
			if actorPlayer == localPlayer then
				animation.StartReload(now)
			end
		end
	elseif effectName == "Empty" and actorPlayer == localPlayer then
		local usedPrediction = now - lastPredictedEmptyAt <= PREDICTION_MATCH_WINDOW
		if usedPrediction then
			lastPredictedEmptyAt = -math.huge
		else
			effects.PlayEmpty()
			animation.StartEmpty(now, false)
		end
	end
end)

pcall(function()
	RunService:UnbindFromRenderStep(RENDER_STEP_NAME)
end)
RunService:BindToRenderStep(RENDER_STEP_NAME, Enum.RenderPriority.Camera.Value + 2, function(deltaTime: number)
	local now = os.clock()
	local equippedTool = effects.GetEquippedRevolver(localPlayer)
	syncActiveTool(equippedTool, now)
	local tool = viewmodel.GetActiveTool()
	local camera = Workspace.CurrentCamera
	local inArena = GameState.IsArena(localPlayer)
	local showViewmodel = tool ~= nil and camera ~= nil and inArena
		and localPlayer.CameraMode == Enum.CameraMode.LockFirstPerson
	local character = localPlayer.Character
	local frame = animation.Step(
		deltaTime,
		now,
		tool,
		camera,
		character,
		inArena,
		showViewmodel,
		isServerRolling(),
		isServerReloading(),
		SettingsStore.GetBoolean("WeaponSwayEnabled"),
		SettingsStore.GetBoolean("CameraBobEnabled")
	)
	viewmodel.SetVisible(showViewmodel, camera, character)
	if frame then
		if frame.PlayEquipSound then
			effects.PlayEquip()
		end
		viewmodel.ApplyFrame(frame)
	end
end)

localPlayer.CharacterAdded:Connect(function()
	animation.Reset(Workspace.CurrentCamera)
	viewmodel.SetActiveTool(nil, function()
		requestShot()
	end)
	lastLocalShotRequestAt = -math.huge
	lastLocalEmptyAt = -math.huge
end)

localPlayer:GetAttributeChangedSignal(GameState.Attribute):Connect(function()
	if not GameState.IsArena(localPlayer) then
		animation.ClearCombatState()
	end
end)

ContextActionService:BindAction("RevolverReloadAction", function(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	if SettingsStore.IsInputBlocked() then
		return Enum.ContextActionResult.Sink
	end
	if GameState.IsArena(localPlayer) then
		requestReload()
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.R, Enum.KeyCode.ButtonX)

ContextActionService:BindAction("RevolverRollAction", function(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	if SettingsStore.IsInputBlocked() then
		return Enum.ContextActionResult.Sink
	end
	if GameState.IsArena(localPlayer) then
		requestRoll()
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.E, Enum.KeyCode.ButtonB)
