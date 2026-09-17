--!strict

export type WeaponConfig = {
	AmmoCapacity: number,
	FireCooldown: number,
	ReloadDuration: number,
	Range: number,
	RollCooldown: number,
	RollDistance: number,
	RollDuration: number,
}

local WeaponConfig: WeaponConfig = {
	AmmoCapacity = 6,
	FireCooldown = 0.65,
	ReloadDuration = 1.5,
	Range = 1000,
	RollCooldown = 5,
	RollDistance = 12,
	RollDuration = 0.35,
}

return table.freeze(WeaponConfig)
