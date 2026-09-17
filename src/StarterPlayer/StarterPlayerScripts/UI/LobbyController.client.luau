--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local GameState = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameState"))
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local existing = playerGui:FindFirstChild("RevolverLobbyUI")
if existing then
	existing:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RevolverLobbyUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 8
screenGui.Enabled = false
screenGui.Parent = playerGui

local hint = Instance.new("Frame")
hint.Name = "LobbyHint"
hint.AnchorPoint = Vector2.new(0.5, 1)
hint.Position = UDim2.new(0.5, 0, 1, -24)
hint.Size = UDim2.fromOffset(490, 68)
hint.BackgroundColor3 = Color3.fromRGB(37, 29, 23)
hint.BackgroundTransparency = 0.16
hint.BorderSizePixel = 0
hint.Active = false
hint.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = hint
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(173, 120, 63)
stroke.Transparency = 0.3
stroke.Parent = hint

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Position = UDim2.fromOffset(16, 8)
title.Size = UDim2.new(1, -32, 0, 24)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "SAFE LOBBY  ·  REVOLVER ARENA"
title.TextColor3 = Color3.fromRGB(255, 204, 116)
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = hint

local directions = Instance.new("TextLabel")
directions.Name = "Directions"
directions.Position = UDim2.fromOffset(16, 32)
directions.Size = UDim2.new(1, -32, 0, 26)
directions.BackgroundTransparency = 1
directions.Font = Enum.Font.Gotham
directions.Text = "Walk to the gate and press F to enter · G at the board for settings"
directions.TextColor3 = Color3.fromRGB(239, 225, 201)
directions.TextSize = 13
directions.TextXAlignment = Enum.TextXAlignment.Left
directions.Parent = hint

local function updateLobbyHint()
	screenGui.Enabled = localPlayer:GetAttribute(GameState.Attribute) == GameState.Lobby
end

local backpackGeneration = 0
local function updateBackpack()
	backpackGeneration += 1
	local generation = backpackGeneration
	task.spawn(function()
		for _ = 1, 8 do
			if generation ~= backpackGeneration then
				return
			end
			local success = pcall(function()
				-- The revolver remains a Tool internally, but RevolverArena uses its own HUD.
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
			end)
			if success then
				return
			end
			task.wait(0.25)
		end
	end)
end

localPlayer:GetAttributeChangedSignal(GameState.Attribute):Connect(function()
	updateLobbyHint()
	updateBackpack()
end)
updateLobbyHint()
updateBackpack()
