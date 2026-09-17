--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Fusion = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Fusion"))
local Theme = require(ReplicatedStorage:WaitForChild("UI"):WaitForChild("Theme"))
local RuntimeState = require(script.Parent:WaitForChild("RuntimeState"))

type Entry = {
	id: number,
	layoutOrder: number,
	text: string,
	background: Fusion.Value<number>,
	textTransparency: Fusion.Value<number>,
}

local KillFeed = {}

function KillFeed.mount(
	scope: Fusion.Scope,
	parent: ScreenGui,
	state: RuntimeState.State
)
	local entries = scope:Value({} :: {[number]: Entry})
	local alive = true
	local nextId = 0
	table.insert(scope, function()
		alive = false
	end)

	local renderedEntries = scope:ForPairs(entries, function(use, entryScope, key, entry)
		local background = entryScope:Tween(entry.background, TweenInfo.new(
			0.14,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		))
		local textTransparency = entryScope:Tween(entry.textTransparency, TweenInfo.new(
			0.14,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		))

		return key, entryScope:New "TextLabel" {
			Name = "Kill",
			Size = UDim2.fromOffset(340, 25),
			BackgroundColor3 = Theme.Colors.KillFeedBackground,
			BackgroundTransparency = background,
			BorderSizePixel = 0,
			Font = Theme.Fonts.Semibold,
			Text = entry.text,
			TextColor3 = Theme.Colors.KillFeedText,
			TextSize = 15,
			TextStrokeTransparency = 0.75,
			TextTransparency = textTransparency,
			TextXAlignment = Enum.TextXAlignment.Right,
			LayoutOrder = entry.layoutOrder,
		}
	end)

	local frame = scope:New "Frame" {
		Name = "KillFeed",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -32, 0, 107),
		Size = UDim2.fromOffset(360, 150),
		BackgroundTransparency = 1,
		Visible = state.combatVisible,
		[Fusion.Children] = {
			scope:New "UIListLayout" {
				Padding = UDim.new(0, 4),
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Top,
			},
			renderedEntries,
		},
	}

	local function contains(entry: Entry): boolean
		return Fusion.peek(entries)[entry.id] == entry
	end

	local controller = {}
	function controller.Clear()
		entries:set({})
	end

	function controller.Add(killerName: string, victimName: string)
		if not alive or not Fusion.peek(state.combatVisible) then
			return
		end

		nextId += 1
		local entry: Entry = {
			id = nextId,
			layoutOrder = math.floor(Workspace:GetServerTimeNow() * 100),
			text = string.format("%s   [REVOLVER]   %s", killerName, victimName),
			background = scope:Value(1),
			textTransparency = scope:Value(1),
		}

		local nextEntries = table.clone(Fusion.peek(entries))
		nextEntries[entry.id] = entry
		local count = 0
		local oldestId: number? = nil
		local oldestOrder = math.huge
		for id, candidate in nextEntries do
			count += 1
			if candidate.layoutOrder < oldestOrder then
				oldestOrder = candidate.layoutOrder
				oldestId = id
			end
		end
		if count > 5 and oldestId ~= nil then
			nextEntries[oldestId] = nil
		end
		entries:set(nextEntries)

		task.defer(function()
			if alive and contains(entry) then
				entry.background:set(0.28)
				entry.textTransparency:set(0)
			end
		end)

		task.delay(4.2, function()
			if not alive or not contains(entry) then
				return
			end
			entry.background:set(1)
			entry.textTransparency:set(1)
			task.delay(0.55, function()
				if not alive or not contains(entry) then
					return
				end
				local current = table.clone(Fusion.peek(entries))
				current[entry.id] = nil
				entries:set(current)
			end)
		end)
	end

	table.insert(scope, state.killFeed.OnClientEvent:Connect(function(killerName: any, victimName: any)
		if typeof(killerName) == "string" and typeof(victimName) == "string" then
			controller.Add(killerName, victimName)
		end
	end))

	scope:Observer(state.combatVisible):onChange(function()
		if not Fusion.peek(state.combatVisible) then
			controller.Clear()
		end
	end)

	return table.freeze(controller)
end

return table.freeze(KillFeed)
