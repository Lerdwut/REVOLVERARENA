--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Fusion"))
local UILabs = require(ReplicatedStorage:WaitForChild("DevPackages"):WaitForChild("UILabs"))
local StatusCard = require(ReplicatedStorage:WaitForChild("UI"):WaitForChild("Components"):WaitForChild("StatusCard"))

local controls = {
	ammo = UILabs.Slider(6, 0, 12, 1),
	capacity = UILabs.Slider(6, 1, 12, 1),
	streak = UILabs.Slider(3, 0, 20, 1),
	wanted = UILabs.Boolean(false),
	gameState = UILabs.EnumList({
		Lobby = "Lobby",
		Arena = "Arena",
		Dead = "Dead",
	}, "Arena"),
}

return UILabs.CreateFusionStory({
	fusion = Fusion,
	controls = controls,
}, function(props)
		return StatusCard(props.scope, {
			parent = props.target,
			position = UDim2.fromScale(0.5, 0.5),
			anchorPoint = Vector2.new(0.5, 0.5),
			ammo = props.controls.ammo,
			capacity = props.controls.capacity,
			streak = props.controls.streak,
			wanted = props.controls.wanted,
			gameState = props.controls.gameState,
		})
	end)
