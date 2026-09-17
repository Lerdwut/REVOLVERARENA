--!strict

-- Cross-boundary names live here so client and server cannot silently drift.
local Constants = {
	Remotes = table.freeze({
		Folder = "RevolverRemotes",
		Fire = "FireRevolver",
		Reload = "ReloadRevolver",
		RequestRoll = "RequestCombatRoll",
		WeaponEffects = "WeaponEffects",
		CombatFeedback = "CombatFeedback",
		KillFeed = "KillFeed",
	}),

	Attributes = table.freeze({
		GameState = "RevolverGameState",
		Ammo = "RevolverAmmo",
		Reloading = "RevolverReloading",
		Rolling = "RevolverRolling",
		RollReadyAt = "RevolverRollReadyAt",
		KillerUserId = "RevolverKillerUserId",
		DeathProcessed = "RevolverDeathProcessed",
		KillStreak = "RevolverKillStreak",
		Wanted = "RevolverWanted",
	}),

	Instances = table.freeze({
		Arena = "Arena",
		Lobby = "Lobby",
		LobbyProtection = "LobbyProtection",
		Revolver = "Revolver",
		SpawnProtection = "SpawnProtection",
	}),
}

return table.freeze(Constants)
