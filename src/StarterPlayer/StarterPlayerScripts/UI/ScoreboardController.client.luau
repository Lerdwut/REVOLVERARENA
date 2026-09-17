--!strict

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local clientShared = script.Parent.Parent:WaitForChild("Shared")
local SettingsStore = require(clientShared:WaitForChild("SettingsStore"))

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local KILL_STREAK_ATTRIBUTE = Constants.Attributes.KillStreak

task.spawn(function()
	for _ = 1, 8 do
		local succeeded = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
		end)
		if succeeded then
			return
		end
		task.wait(0.25)
	end
end)

local existing = playerGui:FindFirstChild("RevolverScoreboard")
if existing then
	existing:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RevolverScoreboard"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 20
screenGui.Enabled = false
screenGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0.12, 0)
panel.Size = UDim2.fromOffset(570, 390)
panel.BackgroundColor3 = Color3.fromRGB(25, 20, 17)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Parent = screenGui

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(147, 104, 62)
panelStroke.Thickness = 2
panelStroke.Transparency = 0.15
panelStroke.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Position = UDim2.fromOffset(18, 10)
title.Size = UDim2.new(1, -36, 0, 38)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "REVOLVER ARENA"
title.TextColor3 = Color3.fromRGB(255, 204, 116)
title.TextSize = 24
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local header = Instance.new("Frame")
header.Name = "Header"
header.Position = UDim2.fromOffset(14, 55)
header.Size = UDim2.new(1, -28, 0, 29)
header.BackgroundColor3 = Color3.fromRGB(74, 48, 31)
header.BackgroundTransparency = 0.15
header.BorderSizePixel = 0
header.Parent = panel

local columns = {
	{name = "PLAYER", position = 0.02, width = 0.49, alignment = Enum.TextXAlignment.Left},
	{name = "KILLS", position = 0.52, width = 0.15, alignment = Enum.TextXAlignment.Center},
	{name = "DEATHS", position = 0.68, width = 0.15, alignment = Enum.TextXAlignment.Center},
	{name = "STREAK", position = 0.84, width = 0.14, alignment = Enum.TextXAlignment.Center},
}

for _, column in columns do
	local label = Instance.new("TextLabel")
	label.Name = column.name
	label.Position = UDim2.fromScale(column.position, 0)
	label.Size = UDim2.new(column.width, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = column.name
	label.TextColor3 = Color3.fromRGB(224, 203, 175)
	label.TextSize = 14
	label.TextXAlignment = column.alignment
	label.Parent = header
end

local list = Instance.new("ScrollingFrame")
list.Name = "Rows"
list.Position = UDim2.fromOffset(14, 88)
list.Size = UDim2.new(1, -28, 1, -102)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.CanvasSize = UDim2.fromOffset(0, 0)
list.ScrollBarImageColor3 = Color3.fromRGB(167, 121, 75)
list.ScrollBarThickness = 5
list.Parent = panel

local rowLayout = Instance.new("UIListLayout")
rowLayout.Padding = UDim.new(0, 3)
rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
rowLayout.Parent = list

local function getStat(player: Player, name: string): number
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local stat = leaderstats:FindFirstChild(name)
		if stat and stat:IsA("IntValue") then
			return stat.Value
		end
	end
	return 0
end

type RowData = {
	player: Player,
	kills: number,
	deaths: number,
	streak: number,
}

local function rebuildRows()
	for _, child in list:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local rows: {RowData} = {}
	for _, player in Players:GetPlayers() do
		local streakAttribute = player:GetAttribute(KILL_STREAK_ATTRIBUTE)
		table.insert(rows, {
			player = player,
			kills = getStat(player, "Kills"),
			deaths = getStat(player, "Deaths"),
			streak = if typeof(streakAttribute) == "number" then math.floor(streakAttribute) else 0,
		})
	end

	table.sort(rows, function(a, b)
		if a.kills ~= b.kills then
			return a.kills > b.kills
		end
		if a.deaths ~= b.deaths then
			return a.deaths < b.deaths
		end
		return string.lower(a.player.DisplayName) < string.lower(b.player.DisplayName)
	end)

	for index, data in rows do
		local row = Instance.new("Frame")
		row.Name = tostring(data.player.UserId)
		row.Size = UDim2.new(1, -6, 0, 28)
		row.BackgroundColor3 = if data.player == localPlayer
			then Color3.fromRGB(92, 59, 34)
			else Color3.fromRGB(43, 36, 31)
		row.BackgroundTransparency = if data.player == localPlayer then 0.12 else 0.28
		row.BorderSizePixel = 0
		row.LayoutOrder = index
		row.Parent = list

		local values = {
			{text = data.player.DisplayName, position = 0.02, width = 0.49, alignment = Enum.TextXAlignment.Left},
			{text = tostring(data.kills), position = 0.52, width = 0.15, alignment = Enum.TextXAlignment.Center},
			{text = tostring(data.deaths), position = 0.68, width = 0.15, alignment = Enum.TextXAlignment.Center},
			{text = tostring(data.streak), position = 0.84, width = 0.14, alignment = Enum.TextXAlignment.Center},
		}

		for columnIndex, value in values do
			local label = Instance.new("TextLabel")
			label.Name = tostring(columnIndex)
			label.Position = UDim2.fromScale(value.position, 0)
			label.Size = UDim2.new(value.width, 0, 1, 0)
			label.BackgroundTransparency = 1
			label.Font = if columnIndex == 1 then Enum.Font.GothamSemibold else Enum.Font.Gotham
			label.Text = value.text
			label.TextColor3 = Color3.fromRGB(245, 237, 222)
			label.TextSize = 15
			label.TextTruncate = Enum.TextTruncate.AtEnd
			label.TextXAlignment = value.alignment
			label.Parent = row
		end
	end

	list.CanvasSize = UDim2.fromOffset(0, math.max(0, #rows * 31))
end

local refreshGeneration = 0
local function setVisible(visible: boolean)
	if screenGui.Enabled == visible then
		return
	end

	screenGui.Enabled = visible
	refreshGeneration += 1
	local generation = refreshGeneration
	if not visible then
		return
	end

	rebuildRows()
	task.spawn(function()
		while screenGui.Enabled and refreshGeneration == generation do
			task.wait(0.35)
			rebuildRows()
		end
	end)
end

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode ~= Enum.KeyCode.Tab or UserInputService:GetFocusedTextBox()
		or SettingsStore.IsOpen() then
		return
	end
	setVisible(true)
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Tab then
		setVisible(false)
	end
end)

UserInputService.WindowFocusReleased:Connect(function()
	setVisible(false)
end)

Players.PlayerRemoving:Connect(function()
	if screenGui.Enabled then
		rebuildRows()
	end
end)
