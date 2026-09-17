--!strict

local SoundService = game:GetService("SoundService")
local SettingsStore = require(script.Parent:WaitForChild("SettingsStore"))

local function getOrCreateGroup(name: string): SoundGroup
	local existing = SoundService:FindFirstChild(name)
	if existing then
		if existing:IsA("SoundGroup") then
			return existing
		end
		error(string.format("SoundService.%s must be a SoundGroup", name))
	end
	local group = Instance.new("SoundGroup")
	group.Name = name
	group.Parent = SoundService
	return group
end

local weaponGroup = getOrCreateGroup("RevolverWeaponAudio")
local uiGroup = getOrCreateGroup("RevolverUIAudio")

local function updateAudio()
	local master = SettingsStore.GetNumber("MasterVolume")
	weaponGroup.Volume = master * SettingsStore.GetNumber("WeaponVolume")
	uiGroup.Volume = master * SettingsStore.GetNumber("UIVolume")
end

SettingsStore.Changed:Connect(function()
	updateAudio()
end)
updateAudio()

return {
	WeaponGroup = weaponGroup,
	UIGroup = uiGroup,
}
