--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameState = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameState"))
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("RevolverTransitionUI")
if old then
	old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "RevolverTransitionUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 24
gui.Enabled = false
gui.Parent = playerGui

local fade = Instance.new("Frame")
fade.Name = "Fade"
fade.Size = UDim2.fromScale(1, 1)
fade.BackgroundColor3 = Color3.fromRGB(22, 16, 12)
fade.BackgroundTransparency = 1
fade.BorderSizePixel = 0
fade.Active = false
fade.Parent = gui

local generation = 0
local currentTween: Tween? = nil
local function animate(transparency: number, duration: number)
	if currentTween then
		currentTween:Cancel()
	end
	currentTween = TweenService:Create(fade, TweenInfo.new(duration,
		Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = transparency,
	})
	currentTween:Play()
end

local function updateTransition()
	generation += 1
	local thisGeneration = generation
	local state = localPlayer:GetAttribute(GameState.Attribute)
	if state == GameState.EnteringArena then
		gui.Enabled = true
		fade.BackgroundColor3 = Color3.fromRGB(22, 16, 12)
		animate(0.04, 0.17)
	elseif state == GameState.Dead then
		gui.Enabled = true
		fade.BackgroundColor3 = Color3.fromRGB(66, 21, 16)
		animate(0.48, 0.12)
	else
		if not gui.Enabled then
			return
		end
		animate(1, 0.24)
		task.delay(0.25, function()
			if generation == thisGeneration then
				gui.Enabled = false
			end
		end)
	end
end

localPlayer:GetAttributeChangedSignal(GameState.Attribute):Connect(updateTransition)
-- No startup fade or modal: joining Lobby immediately leaves this GUI disabled.
