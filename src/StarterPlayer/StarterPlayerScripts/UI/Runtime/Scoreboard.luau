--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local Fusion = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Fusion"))
local Theme = require(ReplicatedStorage:WaitForChild("UI"):WaitForChild("Theme"))
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local RuntimeState = require(script.Parent:WaitForChild("RuntimeState"))

type RowData = {
	displayName: string,
	kills: number,
	deaths: number,
	streak: number,
	isLocal: boolean,
	layoutOrder: number,
}

local Scoreboard = {}

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

function Scoreboard.mount(scope: Fusion.Scope, state: RuntimeState.State)
	local old = state.playerGui:FindFirstChild("RevolverScoreboard")
	if old then
		old:Destroy()
	end

	local visible = scope:Value(false)
	local rows = scope:Value({} :: {[number]: RowData})
	local rowsCanvasSize = scope:Computed(function(use)
		local count = 0
		for _ in use(rows) do
			count += 1
		end
		return UDim2.fromOffset(0, math.max(0, count * 31))
	end)

	local renderedRows = scope:ForPairs(rows, function(use, rowScope, userId, data)
		local rowColor = if data.isLocal
			then Color3.fromRGB(92, 59, 34)
			else Color3.fromRGB(43, 36, 31)
		local rowTransparency = if data.isLocal then 0.12 else 0.28
		local values = {
			{text = data.displayName, position = 0.02, width = 0.49, alignment = Enum.TextXAlignment.Left},
			{text = tostring(data.kills), position = 0.52, width = 0.15, alignment = Enum.TextXAlignment.Center},
			{text = tostring(data.deaths), position = 0.68, width = 0.15, alignment = Enum.TextXAlignment.Center},
			{text = tostring(data.streak), position = 0.84, width = 0.14, alignment = Enum.TextXAlignment.Center},
		}
		local labels = {}
		for columnIndex, value in values do
			labels[columnIndex] = rowScope:New "TextLabel" {
				Name = tostring(columnIndex),
				Position = UDim2.fromScale(value.position, 0),
				Size = UDim2.new(value.width, 0, 1, 0),
				BackgroundTransparency = 1,
				Font = if columnIndex == 1 then Theme.Fonts.Semibold else Theme.Fonts.Regular,
				Text = value.text,
				TextColor3 = Theme.Colors.Text,
				TextSize = 15,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = value.alignment,
			}
		end

		return userId, rowScope:New "Frame" {
			Name = tostring(userId),
			Size = UDim2.new(1, -6, 0, 28),
			BackgroundColor3 = rowColor,
			BackgroundTransparency = rowTransparency,
			BorderSizePixel = 0,
			LayoutOrder = data.layoutOrder,
			[Fusion.Children] = labels,
		}
	end)
	local headerColumns = {
		{name = "PLAYER", position = 0.02, width = 0.49, alignment = Enum.TextXAlignment.Left},
		{name = "KILLS", position = 0.52, width = 0.15, alignment = Enum.TextXAlignment.Center},
		{name = "DEATHS", position = 0.68, width = 0.15, alignment = Enum.TextXAlignment.Center},
		{name = "STREAK", position = 0.84, width = 0.14, alignment = Enum.TextXAlignment.Center},
	}
	local renderedHeaderColumns = scope:ForValues(headerColumns, function(use, headerScope, column)
		return headerScope:New "TextLabel" {
			Name = column.name,
			Position = UDim2.fromScale(column.position, 0),
			Size = UDim2.new(column.width, 0, 1, 0),
			BackgroundTransparency = 1,
			Font = Theme.Fonts.Bold,
			Text = column.name,
			TextColor3 = Color3.fromRGB(224, 203, 175),
			TextSize = 14,
			TextXAlignment = column.alignment,
		}
	end)

	local screenGui = scope:New "ScreenGui" {
		Name = "RevolverScoreboard",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 20,
		Enabled = visible,
		Parent = state.playerGui,
		[Fusion.Children] = {
			scope:New "Frame" {
				Name = "Panel",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0.12, 0),
				Size = UDim2.fromOffset(570, 390),
				BackgroundColor3 = Color3.fromRGB(25, 20, 17),
				BackgroundTransparency = 0.08,
				BorderSizePixel = 0,
				[Fusion.Children] = {
					scope:New "UIStroke" {
						Color = Color3.fromRGB(147, 104, 62),
						Thickness = 2,
						Transparency = 0.15,
					},
					scope:New "TextLabel" {
						Name = "Title",
						Position = UDim2.fromOffset(18, 10),
						Size = UDim2.new(1, -36, 0, 38),
						BackgroundTransparency = 1,
						Font = Theme.Fonts.Bold,
						Text = "REVOLVER ARENA",
						TextColor3 = Theme.Colors.Accent,
						TextSize = 24,
						TextXAlignment = Enum.TextXAlignment.Left,
					},
					scope:New "Frame" {
						Name = "Header",
						Position = UDim2.fromOffset(14, 55),
						Size = UDim2.new(1, -28, 0, 29),
						BackgroundColor3 = Color3.fromRGB(74, 48, 31),
						BackgroundTransparency = 0.15,
						BorderSizePixel = 0,
						[Fusion.Children] = {
							renderedHeaderColumns,
						},
					},
					scope:New "ScrollingFrame" {
						Name = "Rows",
						Position = UDim2.fromOffset(14, 88),
						Size = UDim2.new(1, -28, 1, -102),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						CanvasSize = rowsCanvasSize,
						ScrollBarImageColor3 = Color3.fromRGB(167, 121, 75),
						ScrollBarThickness = 5,
						[Fusion.Children] = {
							scope:New "UIListLayout" {
								Padding = UDim.new(0, 3),
								SortOrder = Enum.SortOrder.LayoutOrder,
							},
							renderedRows,
						},
					},
				},
			},
		},
	}

	local alive = true
	local refreshGeneration = 0
	table.insert(scope, function()
		alive = false
		refreshGeneration += 1
	end)

	local function rebuildRows()
		local sorted: {{player: Player, kills: number, deaths: number, streak: number}} = {}
		for _, player in Players:GetPlayers() do
			local streakAttribute = player:GetAttribute(Constants.Attributes.KillStreak)
			table.insert(sorted, {
				player = player,
				kills = getStat(player, "Kills"),
				deaths = getStat(player, "Deaths"),
				streak = if typeof(streakAttribute) == "number" then math.floor(streakAttribute) else 0,
			})
		end

		table.sort(sorted, function(a, b)
			if a.kills ~= b.kills then
				return a.kills > b.kills
			end
			if a.deaths ~= b.deaths then
				return a.deaths < b.deaths
			end
			return string.lower(a.player.DisplayName) < string.lower(b.player.DisplayName)
		end)

		local nextRows: {[number]: RowData} = {}
		for index, data in sorted do
			nextRows[data.player.UserId] = {
				displayName = data.player.DisplayName,
				kills = data.kills,
				deaths = data.deaths,
				streak = math.max(0, data.streak),
				isLocal = data.player == state.localPlayer,
				layoutOrder = index,
			}
		end
		rows:set(nextRows)
	end

	local function setVisible(isVisible: boolean)
		if Fusion.peek(visible) == isVisible then
			return
		end
		visible:set(isVisible)
		refreshGeneration += 1
		local generation = refreshGeneration
		if not isVisible then
			return
		end

		rebuildRows()
		task.spawn(function()
			while alive and Fusion.peek(visible) and refreshGeneration == generation do
				task.wait(0.35)
				if alive and Fusion.peek(visible) and refreshGeneration == generation then
					rebuildRows()
				end
			end
		end)
	end

	task.spawn(function()
		for _ = 1, 8 do
			if not alive then
				return
			end
			local succeeded = pcall(function()
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
			end)
			if succeeded then
				return
			end
			task.wait(0.25)
		end
	end)

	table.insert(scope, UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode ~= Enum.KeyCode.Tab or UserInputService:GetFocusedTextBox()
			or Fusion.peek(state.panelOpen) then
			return
		end
		setVisible(true)
	end))
	table.insert(scope, UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Tab then
			setVisible(false)
		end
	end))
	table.insert(scope, UserInputService.WindowFocusReleased:Connect(function()
		setVisible(false)
	end))
	table.insert(scope, Players.PlayerRemoving:Connect(function()
		if Fusion.peek(visible) then
			rebuildRows()
		end
	end))

	return screenGui
end

return table.freeze(Scoreboard)
