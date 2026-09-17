--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Fusion"))
local Theme = require(script.Parent.Parent:WaitForChild("Theme"))

type Scope = Fusion.Scope

export type StatusCardProps = {
	parent: Instance,
	ammo: Fusion.UsedAs<number>,
	capacity: Fusion.UsedAs<number>,
	streak: Fusion.UsedAs<number>,
	wanted: Fusion.UsedAs<boolean>,
	gameState: Fusion.UsedAs<string>,
	position: UDim2?,
	anchorPoint: Vector2?,
	size: UDim2?,
}

local function StatusCard(scope: Scope, props: StatusCardProps): Frame
	local safeCapacity = scope:Computed(function(use)
		return math.max(1, math.floor(use(props.capacity)))
	end)

	local safeAmmo = scope:Computed(function(use)
		local capacity = use(safeCapacity)
		local ammo = math.max(0, math.floor(use(props.ammo)))
		return math.min(ammo, capacity)
	end)

	local safeStreak = scope:Computed(function(use)
		return math.max(0, math.floor(use(props.streak)))
	end)

	local ammoText = scope:Computed(function(use)
		return string.format("%d / %d", use(safeAmmo), use(safeCapacity))
	end)

	local streakText = scope:Computed(function(use)
		return string.format("STREAK  x%d", use(safeStreak))
	end)

	local stateText = scope:Computed(function(use)
		local state = use(props.gameState)
		if state == "" then
			return "UNKNOWN"
		end
		return string.upper(state)
	end)

	local wantedText = scope:Computed(function(use)
		return if use(props.wanted) then "WANTED" else "CLEAR"
	end)

	local wantedColor = scope:Computed(function(use)
		return if use(props.wanted) then Theme.Colors.Danger else Theme.Colors.Success
	end)

	local root = scope:New "Frame" {
		Name = "StatusCard",
		Parent = props.parent,
		AnchorPoint = props.anchorPoint or Vector2.new(1, 1),
		Position = props.position or UDim2.new(1, -32, 1, -28),
		Size = props.size or Theme.Sizes.StatusCard,
		BackgroundColor3 = Theme.Colors.Surface,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		[ Fusion.Children ] = {
			scope:New "UICorner" {
				CornerRadius = UDim.new(0, 8),
			},
			scope:New "UIStroke" {
				Color = Theme.Colors.Border,
				Thickness = 2,
				Transparency = 0.15,
			},
			scope:New "TextLabel" {
				Name = "Title",
				Position = UDim2.fromOffset(14, 10),
				Size = UDim2.new(1, -28, 0, 22),
				BackgroundTransparency = 1,
				Font = Theme.Fonts.Bold,
				Text = "COMBAT STATUS",
				TextColor3 = Theme.Colors.Accent,
				TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left,
			},
			scope:New "TextLabel" {
				Name = "State",
				Position = UDim2.new(0, 14, 0, 34),
				Size = UDim2.new(0.5, -18, 0, 20),
				BackgroundTransparency = 1,
				Font = Theme.Fonts.Semibold,
				Text = stateText,
				TextColor3 = Theme.Colors.TextMuted,
				TextSize = 12,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
			},
			scope:New "TextLabel" {
				Name = "WantedStatus",
				Position = UDim2.new(0.5, 4, 0, 34),
				Size = UDim2.new(0.5, -18, 0, 20),
				BackgroundTransparency = 1,
				Font = Theme.Fonts.Bold,
				Text = wantedText,
				TextColor3 = wantedColor,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Right,
			},
			scope:New "Frame" {
				Name = "Divider",
				Position = UDim2.fromOffset(14, 60),
				Size = UDim2.new(1, -28, 0, 1),
				BackgroundColor3 = Theme.Colors.Border,
				BackgroundTransparency = 0.45,
				BorderSizePixel = 0,
			},
			scope:New "TextLabel" {
				Name = "AmmoLabel",
				Position = UDim2.fromOffset(14, 72),
				Size = UDim2.new(0.5, -18, 0, 18),
				BackgroundTransparency = 1,
				Font = Theme.Fonts.Regular,
				Text = "AMMO",
				TextColor3 = Theme.Colors.TextMuted,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
			},
			scope:New "TextLabel" {
				Name = "AmmoValue",
				Position = UDim2.new(0, 14, 0, 88),
				Size = UDim2.new(0.5, -18, 0, 26),
				BackgroundTransparency = 1,
				Font = Theme.Fonts.Bold,
				Text = ammoText,
				TextColor3 = Theme.Colors.Text,
				TextSize = 20,
				TextXAlignment = Enum.TextXAlignment.Left,
			},
			scope:New "TextLabel" {
				Name = "StreakLabel",
				Position = UDim2.new(0.5, 4, 0, 72),
				Size = UDim2.new(0.5, -18, 0, 18),
				BackgroundTransparency = 1,
				Font = Theme.Fonts.Regular,
				Text = "STREAK",
				TextColor3 = Theme.Colors.TextMuted,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Right,
			},
			scope:New "TextLabel" {
				Name = "StreakValue",
				Position = UDim2.new(0.5, 4, 0, 88),
				Size = UDim2.new(0.5, -18, 0, 26),
				BackgroundTransparency = 1,
				Font = Theme.Fonts.Bold,
				Text = streakText,
				TextColor3 = Theme.Colors.Accent,
				TextSize = 18,
				TextXAlignment = Enum.TextXAlignment.Right,
			},
		},
	}

	return root
end

return StatusCard
