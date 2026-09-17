--!strict

-- Session-local preferences. Only this module owns values and the panel-open flag.
local defaults: {[string]: number | boolean} = {
	MouseSensitivity = 1,
	MasterVolume = 1,
	WeaponVolume = 1,
	UIVolume = 1,
	CameraBobEnabled = true,
	WeaponSwayEnabled = true,
	TracersEnabled = true,
	HitmarkerEnabled = true,
}
local values: {[string]: number | boolean} = table.clone(defaults)
local panelOpen = false
local inputBlockedUntil = -math.huge
local changed = Instance.new("BindableEvent")
local openChanged = Instance.new("BindableEvent")

local SettingsStore = {
	Changed = changed.Event,
	OpenChanged = openChanged.Event,
}

function SettingsStore.GetNumber(key: string): number
	local value = values[key]
	return if typeof(value) == "number" then value else 0
end

function SettingsStore.GetBoolean(key: string): boolean
	return values[key] == true
end

function SettingsStore.GetDefault(key: string): number | boolean | nil
	return defaults[key]
end

function SettingsStore.Set(key: string, value: number | boolean)
	local default = defaults[key]
	if default == nil or typeof(value) ~= typeof(default) then
		warn(string.format("Unknown or invalid Revolver setting: %s", key))
		return
	end
	if typeof(value) == "number" then
		value = if key == "MouseSensitivity"
			then math.clamp(value, 0.1, 2)
			else math.clamp(value, 0, 1)
	end
	if values[key] == value then
		return
	end
	values[key] = value
	changed:Fire(key, value)
end

function SettingsStore.Reset()
	for key, value in defaults do
		SettingsStore.Set(key, value)
	end
end

function SettingsStore.IsOpen(): boolean
	return panelOpen
end

function SettingsStore.IsInputBlocked(): boolean
	return panelOpen or os.clock() < inputBlockedUntil
end

function SettingsStore.SetOpen(isOpen: boolean)
	if panelOpen == isOpen then
		return
	end
	panelOpen = isOpen
	if not isOpen then
		inputBlockedUntil = os.clock() + 0.12
	end
	openChanged:Fire(isOpen)
end

return SettingsStore
