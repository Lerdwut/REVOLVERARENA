--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Fusion"))
local UILabs = require(ReplicatedStorage:WaitForChild("DevPackages"):WaitForChild("UILabs"))
local KillFeed = require(ReplicatedStorage:WaitForChild("UI"):WaitForChild("Components"):WaitForChild("KillFeed"))

local controls = {
	count = UILabs.Slider(3, 0, 5, 1),
	killer = UILabs.String("Marshal"),
	victim = UILabs.String("Outlaw"),
	longNames = UILabs.Boolean(false),
}

return UILabs.CreateFusionStory({
	fusion = Fusion,
	controls = controls,
}, function(props)
	local entries = props.scope:Computed(function(use)
		local count = math.clamp(math.floor(use(props.controls.count)), 0, 5)
		local killer = use(props.controls.killer)
		local victim = use(props.controls.victim)
		local longNames = use(props.controls.longNames)
		local result: {[number]: KillFeed.Entry} = {}

		for index = 1, count do
			result[index] = {
				killerName = if longNames then string.format("%s Gunslinger %d", killer, index) else killer,
				victimName = if longNames then string.format("%s Outlaw %d", victim, index) else victim,
				order = -index,
				backgroundTransparency = 0.28,
				textTransparency = 0,
				strokeTransparency = 0.62,
				offset = 0,
			}
		end

		return result
	end)

	return KillFeed.mount(props.scope, {
		parent = props.target,
		entries = entries,
		position = UDim2.new(1, -24, 0, 96),
		anchorPoint = Vector2.new(1, 0),
		size = UDim2.fromOffset(360, 166),
	})
end)
