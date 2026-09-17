--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Fusion"))
local GameState = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameState"))
local RuntimeState = require(script.Parent:WaitForChild("RuntimeState"))

local Transition = {}

function Transition.mount(scope: Fusion.Scope, state: RuntimeState.State)
	local old = state.playerGui:FindFirstChild("RevolverTransitionUI")
	if old then
		old:Destroy()
	end

	local enabled = scope:Value(false)
	local transparencyTarget = scope:Value(1)
	local tweenInfo = scope:Value(TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
	local transparency = scope:Tween(transparencyTarget, tweenInfo)
	local color = scope:Value(Color3.fromRGB(22, 16, 12))
	local generation = 0
	local alive = true
	table.insert(scope, function()
		alive = false
		generation += 1
	end)

	local fade = scope:New "Frame" {
		Name = "Fade",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = color,
		BackgroundTransparency = transparency,
		BorderSizePixel = 0,
		Active = false,
	}
	local gui = scope:New "ScreenGui" {
		Name = "RevolverTransitionUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 24,
		Enabled = enabled,
		Parent = state.playerGui,
		[Fusion.Children] = fade,
	}

	local function updateTransition()
		generation += 1
		local thisGeneration = generation
		local currentState = Fusion.peek(state.gameState)
		if currentState == GameState.EnteringArena then
			enabled:set(true)
			color:set(Color3.fromRGB(22, 16, 12))
			tweenInfo:set(TweenInfo.new(0.17, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
			transparencyTarget:set(0.04)
		elseif currentState == GameState.Dead then
			enabled:set(true)
			color:set(Color3.fromRGB(66, 21, 16))
			tweenInfo:set(TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
			transparencyTarget:set(0.48)
		else
			if not Fusion.peek(enabled) then
				return
			end
			tweenInfo:set(TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
			transparencyTarget:set(1)
			task.delay(0.25, function()
				if alive and generation == thisGeneration then
					enabled:set(false)
				end
			end)
		end
	end

	scope:Observer(state.gameState):onChange(updateTransition)
	updateTransition()

	return gui
end

return table.freeze(Transition)
