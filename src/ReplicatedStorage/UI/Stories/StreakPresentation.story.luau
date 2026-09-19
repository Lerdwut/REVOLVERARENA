--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Fusion"))
local UILabs = require(ReplicatedStorage:WaitForChild("DevPackages"):WaitForChild("UILabs"))
local Theme = require(ReplicatedStorage:WaitForChild("UI"):WaitForChild("Theme"))
local StatusCard = require(ReplicatedStorage:WaitForChild("UI"):WaitForChild("Components"):WaitForChild("StatusCard"))
local StreakBanner = require(ReplicatedStorage:WaitForChild("UI"):WaitForChild("Components"):WaitForChild("StreakBanner"))

local controls = {
	streak = UILabs.Slider(5, 0, 20, 1),
	wanted = UILabs.Boolean(false),
	mode = UILabs.EnumList({
		Hidden = "Hidden",
		Milestone = "Milestone",
		StreakEnded = "StreakEnded",
	}, "Milestone"),
	milestone = UILabs.EnumList({
		HOT = "HOT",
		GUNSLINGER = "GUNSLINGER",
		WANTED = "WANTED",
		OUTLAW = "OUTLAW",
		LEGENDARY = "LEGENDARY",
	}, "GUNSLINGER"),
	playerName = UILabs.String("Marshal"),
	victimName = UILabs.String("Outlaw"),
	compact = UILabs.Boolean(false),
}

return UILabs.CreateFusionStory({
	fusion = Fusion,
	controls = controls,
}, function(props)
	local mode = props.scope:Computed(function(use)
		return use(props.controls.mode)
	end)
	local safeStreak = props.scope:Computed(function(use)
		return math.max(0, math.floor(use(props.controls.streak)))
	end)
	local visible = props.scope:Computed(function(use)
		return use(mode) ~= "Hidden"
	end)
	local title = props.scope:Computed(function(use)
		if use(mode) == "StreakEnded" then
			return "STREAK ENDED"
		end
		return use(props.controls.milestone)
	end)
	local detail = props.scope:Computed(function(use)
		if use(mode) == "StreakEnded" then
			return string.format(
				"%s ended %s's streak · x%d",
				use(props.controls.playerName),
				use(props.controls.victimName),
				use(safeStreak)
			)
		end
		return string.format(
			"%s · STREAK x%d",
			use(props.controls.playerName),
			use(safeStreak)
		)
	end)
	local accentColor = props.scope:Computed(function(use)
		if use(mode) == "StreakEnded" then
			return Theme.Colors.Danger
		end
		return Theme.StreakTiers[use(props.controls.milestone)] or Theme.Colors.Accent
	end)
	local textTransparency = props.scope:Computed(function(use)
		return if use(visible) then 0 else 1
	end)
	local backgroundTransparency = props.scope:Computed(function(use)
		return if use(visible) then 0.18 else 1
	end)
	local bannerSize = props.scope:Computed(function(use)
		return if use(props.controls.compact)
			then UDim2.fromOffset(300, Theme.Layout.StreakBannerHeight)
			else UDim2.new(0.6, 0, 0, Theme.Layout.StreakBannerHeight)
	end)

	local preview = props.scope:New "Frame" {
		Name = "StreakPresentationPreview",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Colors.Background,
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = props.target,
	}

	StatusCard(props.scope, {
		parent = preview,
		variant = "runtime",
		position = UDim2.fromScale(0, 0),
		anchorPoint = Vector2.new(0, 0),
		size = UDim2.fromScale(1, 1),
		ammo = props.scope:Value(6),
		capacity = props.scope:Value(6),
		streak = safeStreak,
		wanted = props.controls.wanted,
		gameState = props.scope:Value("Arena"),
	})

	StreakBanner(props.scope, {
		parent = preview,
		title = title,
		detail = detail,
		accentColor = accentColor,
		textTransparency = textTransparency,
		backgroundTransparency = backgroundTransparency,
		visible = visible,
		position = UDim2.new(0.5, 0, 0, Theme.Layout.StreakBannerTopOffset),
		size = bannerSize,
	})

	return preview
end)
