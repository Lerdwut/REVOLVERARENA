--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Fusion"))
local SettingsStore = require(script.Parent.Parent:WaitForChild("Shared"):WaitForChild("SettingsStore"))
local GameAudio = require(script.Parent.Parent:WaitForChild("Shared"):WaitForChild("GameAudio"))

local runtimeFolder = script.Parent:WaitForChild("Runtime")
local RuntimeState = require(runtimeFolder:WaitForChild("RuntimeState"))
local HUD = require(runtimeFolder:WaitForChild("HUD"))
local Lobby = require(runtimeFolder:WaitForChild("Lobby"))
local Scoreboard = require(runtimeFolder:WaitForChild("Scoreboard"))
local Settings = require(runtimeFolder:WaitForChild("Settings"))
local Transition = require(runtimeFolder:WaitForChild("Transition"))

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local scope = Fusion.scoped(Fusion)
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
