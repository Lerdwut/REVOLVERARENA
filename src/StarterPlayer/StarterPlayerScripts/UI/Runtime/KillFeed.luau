--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Fusion"))
local Theme = require(ReplicatedStorage:WaitForChild("UI"):WaitForChild("Theme"))
local KillFeedView = require(ReplicatedStorage:WaitForChild("UI"):WaitForChild("Components"):WaitForChild("KillFeed"))
local RuntimeState = require(script.Parent:WaitForChild("RuntimeState"))

type Entry = {
	id: number,
	sequence: number,
	order: number,
	background: Fusion.Value<number>,
	textTransparency: Fusion.Value<number>,
	strokeTransparency: Fusion.Value<number>,
	offset: Fusion.Value<number>,
	killerName: string,
	victimName: string,
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

	KillFeedView.mount(scope, {
		parent = parent,
		entries = entries,
		visible = state.combatVisible,
	})

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
			sequence = nextId,
			order = -nextId,
			background = scope:Value(1),
			textTransparency = scope:Value(1),
			strokeTransparency = scope:Value(1),
			offset = scope:Value(14),
			killerName = killerName,
			victimName = victimName,
		}

		local nextEntries = table.clone(Fusion.peek(entries))
		nextEntries[entry.id] = entry
		local count = 0
		local oldestId: number? = nil
		local oldestSequence = math.huge
		for id, candidate in nextEntries do
			count += 1
			if candidate.sequence < oldestSequence then
				oldestSequence = candidate.sequence
				oldestId = id
			end
		end
		if count > Theme.Layout.KillFeedMaxEntries and oldestId ~= nil then
			nextEntries[oldestId] = nil
		end
		entries:set(nextEntries)

		task.defer(function()
			if alive and contains(entry) then
				entry.background:set(0.28)
				entry.textTransparency:set(0)
				entry.strokeTransparency:set(0.62)
				entry.offset:set(0)
			end
		end)

		task.delay(4.2, function()
			if not alive or not contains(entry) then
				return
			end
			entry.background:set(1)
			entry.textTransparency:set(1)
			entry.strokeTransparency:set(1)
			entry.offset:set(14)
			task.delay(0.3, function()
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
