--!strict

local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local KillFeedController = {}

function KillFeedController.new(
	parent: ScreenGui,
	killFeedRemote: RemoteEvent,
	canDisplay: () -> boolean
)
	local frame = Instance.new("Frame")
	frame.Name = "KillFeed"
	frame.AnchorPoint = Vector2.new(1, 0)
	frame.Position = UDim2.new(1, -32, 0, 107)
	frame.Size = UDim2.fromOffset(360, 150)
	frame.BackgroundTransparency = 1
	frame.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Parent = frame

	local entries: {TextLabel} = {}
	local controller = {}

	function controller.Clear()
		for _, entry in entries do
			entry:Destroy()
		end
		table.clear(entries)
	end

	function controller.SetVisible(visible: boolean)
		frame.Visible = visible
	end

	function controller.Add(killerName: string, victimName: string)
		local entry = Instance.new("TextLabel")
		entry.Name = "Kill"
		entry.Size = UDim2.fromOffset(340, 25)
		entry.BackgroundColor3 = Color3.fromRGB(20, 18, 17)
		entry.BackgroundTransparency = 1
		entry.BorderSizePixel = 0
		entry.Font = Enum.Font.GothamSemibold
		entry.Text = string.format("%s   [REVOLVER]   %s", killerName, victimName)
		entry.TextColor3 = Color3.fromRGB(239, 229, 211)
		entry.TextSize = 15
		entry.TextStrokeTransparency = 0.75
		entry.TextTransparency = 1
		entry.TextXAlignment = Enum.TextXAlignment.Right
		entry.LayoutOrder = math.floor(Workspace:GetServerTimeNow() * 100)
		entry.Parent = frame
		table.insert(entries, entry)
		TweenService:Create(entry, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.28,
			TextTransparency = 0,
		}):Play()

		while #entries > 5 do
			local oldest = table.remove(entries, 1)
			oldest:Destroy()
		end

		task.delay(4.2, function()
			if not entry.Parent then
				return
			end

			local fade = TweenService:Create(entry, TweenInfo.new(0.55), {
				BackgroundTransparency = 1,
				TextTransparency = 1,
			})
			fade:Play()
			fade.Completed:Wait()

			local index = table.find(entries, entry)
			if index then
				table.remove(entries, index)
			end
			entry:Destroy()
		end)
	end

	killFeedRemote.OnClientEvent:Connect(function(killerName: any, victimName: any)
		if canDisplay() and typeof(killerName) == "string" and typeof(victimName) == "string" then
			controller.Add(killerName, victimName)
		end
	end)

	return table.freeze(controller)
end

return table.freeze(KillFeedController)
