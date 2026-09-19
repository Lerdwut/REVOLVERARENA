--!strict

local Theme = {
	Colors = table.freeze({
		Background = Color3.fromRGB(24, 17, 13),
		Surface = Color3.fromRGB(37, 29, 23),
		SurfaceRaised = Color3.fromRGB(74, 48, 31),
		Border = Color3.fromRGB(173, 120, 63),
		Text = Color3.fromRGB(245, 237, 222),
		TextMuted = Color3.fromRGB(224, 203, 175),
		Accent = Color3.fromRGB(255, 204, 116),
		Success = Color3.fromRGB(87, 220, 134),
		Warning = Color3.fromRGB(255, 160, 72),
		Danger = Color3.fromRGB(255, 103, 72),
		KillFeedBackground = Color3.fromRGB(43, 35, 29),
		KillFeedText = Color3.fromRGB(245, 237, 222),
		Panel = Color3.fromRGB(32, 27, 24),
		PanelBorder = Color3.fromRGB(154, 105, 58),
		SliderRail = Color3.fromRGB(91, 77, 64),
		SliderFill = Color3.fromRGB(222, 151, 75),
		SliderKnob = Color3.fromRGB(255, 226, 176),
		ToggleOn = Color3.fromRGB(95, 139, 94),
		ToggleOff = Color3.fromRGB(89, 79, 71),
	}),
	Fonts = table.freeze({
		Regular = Enum.Font.Gotham,
		Semibold = Enum.Font.GothamSemibold,
		Bold = Enum.Font.GothamBold,
	}),
	Spacing = table.freeze({
		XSmall = 4,
		Small = 8,
		Medium = 12,
		Large = 16,
		XLarge = 24,
	}),
	Layout = table.freeze({
		ScreenMargin = 24,
		HudMargin = 32,
		LobbyHintWidth = 490,
		LobbyHintHeight = 68,
		SettingsPanelWidth = 560,
		SettingsPanelHeight = 630,
		SettingsViewportWidth = 650,
		SettingsViewportHeight = 720,
		SettingsMinScale = 0.55,
		SettingsContentHeight = 601,
	}),
	Sizes = table.freeze({
		StatusCard = UDim2.fromOffset(286, 126),
	}),
}

return table.freeze(Theme)
