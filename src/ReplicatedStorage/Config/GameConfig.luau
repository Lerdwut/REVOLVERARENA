--!strict

export type GameConfig = {
	RespawnDelay: number,
	SpawnProtectionDuration: number,
	EntryInteractionDistance: number,
	EntryTransitionDuration: number,
	MinimumSafeSpawnDistance: number,
	PreferredSafeSpawnDistance: number,
	SpawnReuseWindow: number,
	CombatArenaHalfWidth: number,
	CombatArenaHalfDepth: number,
	CombatArenaMinY: number,
	CombatArenaMaxY: number,
}

local GameConfig: GameConfig = {
	RespawnDelay = 1.5,
	SpawnProtectionDuration = 1,
	EntryInteractionDistance = 12,
	EntryTransitionDuration = 0.2,
	MinimumSafeSpawnDistance = 18,
	PreferredSafeSpawnDistance = 28,
	SpawnReuseWindow = 4,
	CombatArenaHalfWidth = 67,
	CombatArenaHalfDepth = 45,
	CombatArenaMinY = -10,
	CombatArenaMaxY = 55,
}

return table.freeze(GameConfig)
