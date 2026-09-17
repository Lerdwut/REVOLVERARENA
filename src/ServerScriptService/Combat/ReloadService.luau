--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local configFolder = ReplicatedStorage:WaitForChild("Config")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local WeaponConfig = require(configFolder:WaitForChild("WeaponConfig"))
local Constants = require(sharedFolder:WaitForChild("Constants"))

local ReloadService = {}

local reloadTokens: {[Player]: number} = {}
local ammoByPlayer: {[Player]: number} = {}
local reloadingByPlayer: {[Player]: boolean} = {}

function ReloadService.GetAmmo(player: Player): number
	return ammoByPlayer[player] or WeaponConfig.AmmoCapacity
end

function ReloadService.SetAmmo(player: Player, ammo: number)
	local clampedAmmo = math.clamp(math.floor(ammo), 0, WeaponConfig.AmmoCapacity)
	ammoByPlayer[player] = clampedAmmo
	player:SetAttribute(Constants.Attributes.Ammo, clampedAmmo)
end

function ReloadService.IsReloading(player: Player): boolean
	return reloadingByPlayer[player] == true
end

local function setReloading(player: Player, reloading: boolean)
	reloadingByPlayer[player] = reloading
	player:SetAttribute(Constants.Attributes.Reloading, reloading)
end

function ReloadService.Initialize(player: Player)
	ReloadService.SetAmmo(player, WeaponConfig.AmmoCapacity)
	setReloading(player, false)
end

function ReloadService.Cancel(player: Player)
	reloadTokens[player] = (reloadTokens[player] or 0) + 1
	setReloading(player, false)
end

function ReloadService.Start(
	player: Player,
	character: Model,
	weaponEffects: RemoteEvent,
	canComplete: () -> boolean
)
	setReloading(player, true)
	weaponEffects:FireAllClients("Reload", player)

	local reloadToken = (reloadTokens[player] or 0) + 1
	reloadTokens[player] = reloadToken

	task.delay(WeaponConfig.ReloadDuration, function()
		if reloadTokens[player] ~= reloadToken then
			return
		end

		reloadTokens[player] = nil
		if player.Parent ~= Players or player.Character ~= character then
			return
		end

		if not canComplete() then
			setReloading(player, false)
			return
		end

		ReloadService.SetAmmo(player, WeaponConfig.AmmoCapacity)
		setReloading(player, false)
	end)
end

function ReloadService.Cleanup(player: Player)
	reloadTokens[player] = nil
	ammoByPlayer[player] = nil
	reloadingByPlayer[player] = nil
end

return table.freeze(ReloadService)
