--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Fusion = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Fusion"))
local Theme = require(ReplicatedStorage:WaitForChild("UI"):WaitForChild("Theme"))
local GameState = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameState"))
local RuntimeState = require(script.Parent:WaitForChild("RuntimeState"))

local Lobby = {}

function Lobby.mount(scope: Fusion.Scope, state: RuntimeState.State)
	local old = state.playerGui:FindFirstChild("RevolverLobbyUI")
	if old then
		old:Destroy()
	end

	local screenGui = scope:New "ScreenGui" {
		Name = "RevolverLobbyUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 8,
		Enabled = scope:Computed(function(use)
			return use(state.gameState) == GameState.Lobby
		end),
		Parent = state.playerGui,
		[Fusion.Children] = {
			scope:New "Frame" {
				Name = "LobbyHint",
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -Theme.Layout.ScreenMargin),
				Size = UDim2.new(1, -Theme.Layout.ScreenMargin * 2, 0, Theme.Layout.LobbyHintHeight),
				BackgroundColor3 = Theme.Colors.Surface,
				BackgroundTransparency = 0.16,
				BorderSizePixel = 0,
				Active = false,
				[Fusion.Children] = {
					scope:New "UISizeConstraint" {
						MinSize = Vector2.new(280, Theme.Layout.LobbyHintHeight),
						MaxSize = Vector2.new(Theme.Layout.LobbyHintWidth, Theme.Layout.LobbyHintHeight),
					},
					scope:New "UICorner" {
						CornerRadius = UDim.new(0, 8),
					},
					scope:New "UIStroke" {
						Color = Theme.Colors.Border,
						Transparency = 0.3,
					},
					scope:New "TextLabel" {
						Name = "Title",
						Position = UDim2.fromOffset(16, 8),
						Size = UDim2.new(1, -32, 0, 24),
						BackgroundTransparency = 1,
						Font = Theme.Fonts.Bold,
						Text = "SAFE LOBBY  ·  REVOLVER ARENA",
						TextColor3 = Theme.Colors.Accent,
						TextSize = 16,
						TextXAlignment = Enum.TextXAlignment.Left,
					},
					scope:New "TextLabel" {
						Name = "Directions",
						Position = UDim2.fromOffset(16, 32),
						Size = UDim2.new(1, -32, 0, 26),
						BackgroundTransparency = 1,
						Font = Theme.Fonts.Regular,
						Text = "Walk to the gate and press F to enter · G at the board for settings",
						TextColor3 = Color3.fromRGB(239, 225, 201),
						TextSize = 13,
						TextWrapped = true,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Center,
					},
				},
			},
		},
	}

	local alive = true
	local backpackGeneration = 0
	table.insert(scope, function()
		alive = false
		backpackGeneration += 1
	end)

	local function updateBackpack()
		backpackGeneration += 1
		local generation = backpackGeneration
		task.spawn(function()
			for _ = 1, 8 do
				if not alive or generation ~= backpackGeneration then
					return
				end
				local success = pcall(function()
					-- The revolver remains a Tool internally, but the game uses its own HUD.
					StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
				end)
				if success then
					return
				end
				task.wait(0.25)
			end
		end)
	end

	scope:Observer(state.gameState):onChange(updateBackpack)
	table.insert(scope, state.localPlayer.CharacterAdded:Connect(updateBackpack))
	updateBackpack()

	return screenGui
end

return table.freeze(Lobby)
