--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local GameState = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameState"))
local clientRoot = script.Parent.Parent
local SettingsStore = require(clientRoot:WaitForChild("Shared"):WaitForChild("SettingsStore"))
local localPlayer = Players.LocalPlayer
local RENDER_STEP_NAME = "RevolverCameraBob"

local function updateCameraMode()
	local desiredMode = if GameState.IsArena(localPlayer)
		then Enum.CameraMode.LockFirstPerson
		else Enum.CameraMode.Classic
	if localPlayer.CameraMode ~= desiredMode then
		localPlayer.CameraMode = desiredMode
	end
end

local function updateSensitivity()
	-- Keep Roblox's default camera controller. This scales its mouse input delta.
	UserInputService.MouseDeltaSensitivity = SettingsStore.GetNumber("MouseSensitivity")
end

local bobClock = 0
local bobBlend = 0
pcall(function()
	RunService:UnbindFromRenderStep(RENDER_STEP_NAME)
end)
RunService:BindToRenderStep(RENDER_STEP_NAME, Enum.RenderPriority.Camera.Value + 1, function(dt)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local humanoid: Humanoid? = nil
	local character = localPlayer.Character
	if character then
		humanoid = character:FindFirstChildOfClass("Humanoid")
	end
	local moving = GameState.IsArena(localPlayer)
		and SettingsStore.GetBoolean("CameraBobEnabled")
		and humanoid ~= nil and humanoid.Health > 0
		and humanoid.MoveDirection.Magnitude > 0.1
		and humanoid.FloorMaterial ~= Enum.Material.Air
	bobBlend += ((if moving then 1 else 0) - bobBlend) * (1 - math.exp(-12 * math.min(dt, 1 / 15)))
	if moving and humanoid then
		bobClock += dt * (7.8 + humanoid.WalkSpeed * 0.05)
	end
	if bobBlend > 0.001 and GameState.IsArena(localPlayer) then
		camera.CFrame *= CFrame.new(
			math.sin(bobClock) * 0.006 * bobBlend,
			math.cos(bobClock * 2) * 0.008 * bobBlend,
			0
		)
	end
end)

localPlayer:GetAttributeChangedSignal(GameState.Attribute):Connect(updateCameraMode)
localPlayer:GetPropertyChangedSignal("CameraMode"):Connect(updateCameraMode)
localPlayer.CharacterAdded:Connect(function()
	bobBlend = 0
	task.defer(updateCameraMode)
end)
SettingsStore.Changed:Connect(function(key)
	if key == "MouseSensitivity" then
		updateSensitivity()
	end
end)
updateSensitivity()
updateCameraMode()
