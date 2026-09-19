--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Fusion"))
local Theme = require(ReplicatedStorage:WaitForChild("UI"):WaitForChild("Theme"))

export type Entry = {
	killerName: Fusion.UsedAs<string>,
	victimName: Fusion.UsedAs<string>,
	order: number,
	backgroundTransparency: Fusion.UsedAs<number>,
	textTransparency: Fusion.UsedAs<number>,
	strokeTransparency: Fusion.UsedAs<number>,
	offset: Fusion.UsedAs<number>,
}

export type Props = {
	parent: Instance,
	entries: Fusion.UsedAs<{[number]: Entry}>,
	visible: Fusion.UsedAs<boolean>?,
	position: UDim2?,
	anchorPoint: Vector2?,
	size: UDim2?,
}

local KillFeed = {}

function KillFeed.mount(scope: Fusion.Scope, props: Props): Frame
	local renderedEntries = scope:ForPairs(props.entries, function(use, entryScope, key, entry)
		local backgroundTransparency = entryScope:Tween(entry.backgroundTransparency, TweenInfo.new(
			0.18,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		))
		local textTransparency = entryScope:Tween(entry.textTransparency, TweenInfo.new(
			0.18,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		))
		local strokeTransparency = entryScope:Tween(entry.strokeTransparency, TweenInfo.new(
			0.18,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		))
		local offset = entryScope:Tween(entry.offset, TweenInfo.new(
			0.2,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		))
		local surfacePosition = entryScope:Computed(function(use)
			return UDim2.new(0, -use(offset), 0, 0)
		end)

		return key, entryScope:New "Frame" {
			Name = "Kill",
			Size = UDim2.fromOffset(Theme.Layout.KillFeedWidth, Theme.Layout.KillFeedEntryHeight),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			LayoutOrder = entry.order,
			[Fusion.Children] = {
				entryScope:New "Frame" {
					Name = "Surface",
					Position = surfacePosition,
					Size = UDim2.fromOffset(Theme.Layout.KillFeedWidth, Theme.Layout.KillFeedEntryHeight),
					BackgroundColor3 = Theme.Colors.KillFeedBackground,
					BackgroundTransparency = backgroundTransparency,
					BorderSizePixel = 0,
					[Fusion.Children] = {
						entryScope:New "UICorner" {
							CornerRadius = UDim.new(0, 6),
						},
						entryScope:New "UIStroke" {
							Color = Theme.Colors.Border,
							Thickness = 1,
							Transparency = strokeTransparency,
						},
						entryScope:New "UIPadding" {
							PaddingLeft = UDim.new(0, Theme.Spacing.Medium),
							PaddingRight = UDim.new(0, Theme.Spacing.Medium),
						},
						entryScope:New "UIListLayout" {
							FillDirection = Enum.FillDirection.Horizontal,
							HorizontalAlignment = Enum.HorizontalAlignment.Center,
							VerticalAlignment = Enum.VerticalAlignment.Center,
							Padding = UDim.new(0, Theme.Spacing.Small),
							SortOrder = Enum.SortOrder.LayoutOrder,
						},
						entryScope:New "TextLabel" {
							Name = "Killer",
						LayoutOrder = 1,
						Size = UDim2.new(0.41, 0, 1, 0),
						BackgroundTransparency = 1,
						Font = Theme.Fonts.Semibold,
						Text = entry.killerName,
						TextColor3 = Theme.Colors.Accent,
						TextSize = 14,
						TextStrokeTransparency = 0.8,
						TextTransparency = textTransparency,
						TextTruncate = Enum.TextTruncate.AtEnd,
						TextXAlignment = Enum.TextXAlignment.Right,
						TextYAlignment = Enum.TextYAlignment.Center,
					},
						entryScope:New "TextLabel" {
							Name = "Icon",
						LayoutOrder = 2,
						Size = UDim2.fromOffset(18, Theme.Layout.KillFeedEntryHeight),
						BackgroundTransparency = 1,
						Font = Theme.Fonts.Bold,
						Text = "×",
						TextColor3 = Theme.Colors.Danger,
						TextSize = 18,
						TextStrokeTransparency = 0.75,
						TextTransparency = textTransparency,
						TextXAlignment = Enum.TextXAlignment.Center,
						TextYAlignment = Enum.TextYAlignment.Center,
					},
						entryScope:New "TextLabel" {
							Name = "Victim",
						LayoutOrder = 3,
						Size = UDim2.new(0.41, 0, 1, 0),
						BackgroundTransparency = 1,
						Font = Theme.Fonts.Regular,
						Text = entry.victimName,
						TextColor3 = Theme.Colors.KillFeedText,
						TextSize = 14,
						TextStrokeTransparency = 0.8,
						TextTransparency = textTransparency,
						TextTruncate = Enum.TextTruncate.AtEnd,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Center,
					},
					},
				},
			},
		}
	end)

	return scope:New "Frame" {
		Name = "KillFeed",
		AnchorPoint = props.anchorPoint or Vector2.new(1, 0),
		Position = props.position or UDim2.new(1, -Theme.Layout.HudMargin, 0, Theme.Layout.KillFeedTopOffset),
		Size = props.size or UDim2.fromOffset(
			Theme.Layout.KillFeedWidth,
			Theme.Layout.KillFeedEntryHeight * Theme.Layout.KillFeedMaxEntries
				+ Theme.Layout.KillFeedGap * (Theme.Layout.KillFeedMaxEntries - 1)
		),
		BackgroundTransparency = 1,
		Visible = if props.visible == nil then true else props.visible,
		ClipsDescendants = true,
		[Fusion.Children] = {
			scope:New "UIListLayout" {
				Padding = UDim.new(0, Theme.Layout.KillFeedGap),
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Top,
			},
			renderedEntries,
		},
		Parent = props.parent,
	}
end

return table.freeze(KillFeed)
