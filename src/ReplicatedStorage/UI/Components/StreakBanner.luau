--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Fusion"))
local Theme = require(ReplicatedStorage:WaitForChild("UI"):WaitForChild("Theme"))

type Scope = Fusion.Scope

export type StreakBannerProps = {
	parent: Instance,
	title: Fusion.UsedAs<string>,
	detail: Fusion.UsedAs<string>,
	accentColor: Fusion.UsedAs<Color3>,
	textTransparency: Fusion.UsedAs<number>,
	backgroundTransparency: Fusion.UsedAs<number>,
	visible: Fusion.UsedAs<boolean>,
	position: UDim2?,
	size: Fusion.UsedAs<UDim2>?,
}

local function StreakBanner(scope: Scope, props: StreakBannerProps): Frame
	return scope:New "Frame" {
		Name = "StreakBanner",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = props.position or UDim2.new(0.5, 0, 0, Theme.Layout.StreakBannerTopOffset),
		Size = props.size or UDim2.new(0.6, 0, 0, Theme.Layout.StreakBannerHeight),
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = props.backgroundTransparency,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Visible = props.visible,
		ZIndex = 6,
		Parent = props.parent,
		[Fusion.Children] = {
			scope:New "UICorner" {
				CornerRadius = UDim.new(0, 8),
			},
			scope:New "UIStroke" {
				Color = props.accentColor,
				Thickness = 2,
				Transparency = props.backgroundTransparency,
			},
			scope:New "UISizeConstraint" {
				MinSize = Vector2.new(Theme.Layout.StreakBannerMinWidth, Theme.Layout.StreakBannerHeight),
				MaxSize = Vector2.new(Theme.Layout.StreakBannerMaxWidth, Theme.Layout.StreakBannerHeight),
			},
			scope:New "UIPadding" {
				PaddingLeft = UDim.new(0, Theme.Spacing.Medium),
				PaddingRight = UDim.new(0, Theme.Spacing.Medium),
				PaddingTop = UDim.new(0, Theme.Spacing.Small),
				PaddingBottom = UDim.new(0, Theme.Spacing.Small),
			},
			scope:New "TextLabel" {
				Name = "Title",
				Size = UDim2.new(1, 0, 0, 26),
				BackgroundTransparency = 1,
				Font = Theme.Fonts.Bold,
				Text = props.title,
				TextColor3 = props.accentColor,
				TextSize = 22,
				TextStrokeTransparency = 0.45,
				TextTransparency = props.textTransparency,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				ZIndex = 6,
			},
			scope:New "TextLabel" {
				Name = "Detail",
				Position = UDim2.fromOffset(0, 26),
				Size = UDim2.new(1, 0, 0, 18),
				BackgroundTransparency = 1,
				Font = Theme.Fonts.Semibold,
				Text = props.detail,
				TextColor3 = Theme.Colors.TextMuted,
				TextSize = 13,
				TextStrokeTransparency = 0.7,
				TextTransparency = props.textTransparency,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				ZIndex = 6,
			},
		},
	}
end

return StreakBanner
