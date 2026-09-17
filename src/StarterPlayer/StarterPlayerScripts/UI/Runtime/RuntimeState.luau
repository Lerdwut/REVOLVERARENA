--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Fusion = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Fusion"))
local WeaponConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("WeaponConfig"))
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local GameState = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameState"))

export type RuntimeSettings = {
	MouseSensitivity: Fusion.Value<number>,
	MasterVolume: Fusion.Value<number>,
	WeaponVolume: Fusion.Value<number>,
	UIVolume: Fusion.Value<number>,
	CameraBobEnabled: Fusion.Value<boolean>,
	WeaponSwayEnabled: Fusion.Value<boolean>,
	TracersEnabled: Fusion.Value<boolean>,
	HitmarkerEnabled: Fusion.Value<boolean>,
}

export type State = {
	localPlayer: Player,
	playerGui: PlayerGui,
	gameState: Fusion.Value<string>,
	ammo: Fusion.Value<number>,
	capacity: Fusion.Value<number>,
	streak: Fusion.Value<number>,
	localWanted: Fusion.Value<boolean>,
	rolling: Fusion.Value<boolean>,
	rollReadyAt: Fusion.Value<number>,
	rollRemaining: Fusion.Value<number>,
	combatVisible: Fusion.Computed<boolean>,
	panelOpen: Fusion.Value<boolean>,
	settings: RuntimeSettings,
	combatFeedback: RemoteEvent,
	killFeed: RemoteEvent,
}

local function getNumberAttribute(player: Player, attributeName: string, fallback: number): number
	local value = player:GetAttribute(attributeName)
	if typeof(value) ~= "number" then
		return fallback
	end
	return value
end

local function getIntegerAttribute(player: Player, attributeName: string, fallback: number): number
	return math.floor(getNumberAttribute(player, attributeName, fallback))
end

local function bindNumberAttribute(
	scope: Fusion.Scope,
	player: Player,
	attributeName: string,
	state: Fusion.Value<number>,
	fallback: number,
	integer: boolean
)
	local function update()
		local value = getNumberAttribute(player, attributeName, fallback)
		state:set(if integer then math.floor(value) else value)
	end

	table.insert(scope, player:GetAttributeChangedSignal(attributeName):Connect(update))
	update()
end

local function bindBooleanAttribute(
	scope: Fusion.Scope,
	player: Player,
	attributeName: string,
	state: Fusion.Value<boolean>
)
	local function update()
		state:set(player:GetAttribute(attributeName) == true)
	end

	table.insert(scope, player:GetAttributeChangedSignal(attributeName):Connect(update))
	update()
end

local function bindStringAttribute(
	scope: Fusion.Scope,
	player: Player,
	attributeName: string,
	state: Fusion.Value<string>,
	fallback: string
)
	local function update()
		local value = player:GetAttribute(attributeName)
		state:set(if typeof(value) == "string" then value else fallback)
	end

	table.insert(scope, player:GetAttributeChangedSignal(attributeName):Connect(update))
	update()
end

local function RuntimeState(
	scope: Fusion.Scope,
	localPlayer: Player,
	playerGui: PlayerGui,
	settingsStore: any
): State
	local remotesFolder = ReplicatedStorage:WaitForChild(Constants.Remotes.Folder)
	local combatFeedback = remotesFolder:WaitForChild(Constants.Remotes.CombatFeedback) :: RemoteEvent
	local killFeed = remotesFolder:WaitForChild(Constants.Remotes.KillFeed) :: RemoteEvent

	local gameState = scope:Value(GameState.Lobby)
	local ammo = scope:Value(-1)
	local capacity = scope:Value(WeaponConfig.AmmoCapacity)
	local streak = scope:Value(0)
	local localWanted = scope:Value(false)
	local rolling = scope:Value(false)
	local rollReadyAt = scope:Value(0)
	local rollRemaining = scope:Value(0)
	local panelOpen = scope:Value(settingsStore.IsOpen())

	local settings: RuntimeSettings = {
		MouseSensitivity = scope:Value(settingsStore.GetNumber("MouseSensitivity")),
		MasterVolume = scope:Value(settingsStore.GetNumber("MasterVolume")),
		WeaponVolume = scope:Value(settingsStore.GetNumber("WeaponVolume")),
		UIVolume = scope:Value(settingsStore.GetNumber("UIVolume")),
		CameraBobEnabled = scope:Value(settingsStore.GetBoolean("CameraBobEnabled")),
		WeaponSwayEnabled = scope:Value(settingsStore.GetBoolean("WeaponSwayEnabled")),
		TracersEnabled = scope:Value(settingsStore.GetBoolean("TracersEnabled")),
		HitmarkerEnabled = scope:Value(settingsStore.GetBoolean("HitmarkerEnabled")),
	}

	bindStringAttribute(scope, localPlayer, GameState.Attribute, gameState, GameState.Lobby)
	bindNumberAttribute(scope, localPlayer, Constants.Attributes.Ammo, ammo, -1, true)
	bindNumberAttribute(scope, localPlayer, Constants.Attributes.KillStreak, streak, 0, true)
	bindBooleanAttribute(scope, localPlayer, Constants.Attributes.Wanted, localWanted)
	bindBooleanAttribute(scope, localPlayer, Constants.Attributes.Rolling, rolling)
	bindNumberAttribute(scope, localPlayer, Constants.Attributes.RollReadyAt, rollReadyAt, 0, false)

	table.insert(scope, settingsStore.Changed:Connect(function(key: string, value: number | boolean)
		local target = (settings :: {[string]: any})[key]
		if target then
			target:set(value)
		end
	end))
	table.insert(scope, settingsStore.OpenChanged:Connect(function(isOpen: boolean)
		panelOpen:set(isOpen)
	end))

	local lastRemaining = -1
	table.insert(scope, RunService.RenderStepped:Connect(function()
		local remaining = math.max(0, getNumberAttribute(localPlayer, Constants.Attributes.RollReadyAt, 0)
			- Workspace:GetServerTimeNow())
		if math.abs(remaining - lastRemaining) > 0.01 or remaining == 0 or lastRemaining < 0 then
			lastRemaining = remaining
			rollRemaining:set(remaining)
		end
	end))

	local combatVisible = scope:Computed(function(use)
		return use(gameState) == GameState.Arena
	end)

	return {
		localPlayer = localPlayer,
		playerGui = playerGui,
		gameState = gameState,
		ammo = ammo,
		capacity = capacity,
		streak = streak,
		localWanted = localWanted,
		rolling = rolling,
		rollReadyAt = rollReadyAt,
		rollRemaining = rollRemaining,
		combatVisible = combatVisible,
		panelOpen = panelOpen,
		settings = settings,
		combatFeedback = combatFeedback,
		killFeed = killFeed,
	}
end

return RuntimeState
