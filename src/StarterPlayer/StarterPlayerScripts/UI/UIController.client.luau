--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Fusion"))
local SettingsStore = require(script.Parent.Parent:WaitForChild("Shared"):WaitForChild("SettingsStore"))
local GameAudio = require(script.Parent.Parent:WaitForChild("Shared"):WaitForChild("GameAudio"))

local RuntimeState = require(script:WaitForChild("Runtime"):WaitForChild("RuntimeState"))
local HUD = require(script:WaitForChild("Runtime"):WaitForChild("HUD"))
local Lobby = require(script:WaitForChild("Runtime"):WaitForChild("Lobby"))
local Scoreboard = require(script:WaitForChild("Runtime"):WaitForChild("Scoreboard"))
local Settings = require(script:WaitForChild("Runtime"):WaitForChild("Settings"))
local Transition = require(script:WaitForChild("Runtime"):WaitForChild("Transition"))

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local scope = Fusion.scoped()
local alive = true

table.insert(scope, function()
	alive = false
end)

local state = RuntimeState(scope, localPlayer, playerGui, SettingsStore)
local context = {
	state = state,
	settingsStore = SettingsStore,
	gameAudio = GameAudio,
}

HUD.mount(scope, context)
Lobby.mount(scope, state)
Scoreboard.mount(scope, state)
Settings.mount(scope, state, SettingsStore)
Transition.mount(scope, state)

table.insert(scope, script.Destroying:Connect(function()
	if alive then
		Fusion.doCleanup(scope)
	end
end))
