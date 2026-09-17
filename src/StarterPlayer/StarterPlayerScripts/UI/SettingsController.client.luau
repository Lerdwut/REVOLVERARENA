--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local GameState = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameState"))
local clientShared = script.Parent.Parent:WaitForChild("Shared")
local SettingsStore = require(clientShared:WaitForChild("SettingsStore"))
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("RevolverSettingsUI")
if old then
	old:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RevolverSettingsUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 30
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local function corner(parent: Instance, radius: number)
	local item = Instance.new("UICorner")
	item.CornerRadius = UDim.new(0, radius)
	item.Parent = parent
end

local function label(name: string, parent: Instance, position: UDim2, size: UDim2,
	value: string, textSize: number, color: Color3, bold: boolean?): TextLabel
	local item = Instance.new("TextLabel")
	item.Name = name
	item.Position = position
	item.Size = size
	item.BackgroundTransparency = 1
	item.Font = if bold then Enum.Font.GothamBold else Enum.Font.Gotham
	item.Text = value
	item.TextColor3 = color
	item.TextSize = textSize
	item.TextXAlignment = Enum.TextXAlignment.Left
	item.Parent = parent
	return item
end

local settingsButton = Instance.new("TextButton")
settingsButton.Name = "SettingsButton"
settingsButton.AnchorPoint = Vector2.new(1, 0)
settingsButton.Position = UDim2.new(1, -20, 0, 18)
settingsButton.Size = UDim2.fromOffset(110, 36)
settingsButton.BackgroundColor3 = Color3.fromRGB(43, 35, 29)
settingsButton.BackgroundTransparency = 0.08
settingsButton.BorderSizePixel = 0
settingsButton.Font = Enum.Font.GothamBold
settingsButton.Text = "SETTINGS"
settingsButton.TextColor3 = Color3.fromRGB(248, 218, 172)
settingsButton.TextSize = 13
settingsButton.Parent = screenGui
corner(settingsButton, 6)

-- A visible-only-while-open modal GuiButton releases Roblox's FPS mouse lock.
-- It also consumes clicks outside the panel, so Tool.Activated cannot fire.
local inputSink = Instance.new("TextButton")
inputSink.Name = "SettingsInputSink"
inputSink.Size = UDim2.fromScale(1, 1)
inputSink.BackgroundTransparency = 1
inputSink.Text = ""
inputSink.AutoButtonColor = false
inputSink.BorderSizePixel = 0
inputSink.Modal = true
inputSink.Visible = false
inputSink.Active = true
inputSink.ZIndex = 1
inputSink.Parent = screenGui

local panel = Instance.new("Frame")
panel.Name = "SettingsPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(560, 630)
panel.BackgroundColor3 = Color3.fromRGB(32, 27, 24)
panel.BorderSizePixel = 0
panel.Visible = false
panel.ZIndex = 2
panel.Parent = screenGui
corner(panel, 10)
local scale = Instance.new("UIScale")
scale.Parent = panel
local outline = Instance.new("UIStroke")
outline.Color = Color3.fromRGB(154, 105, 58)
outline.Thickness = 2
outline.Transparency = 0.15
outline.Parent = panel

label("Title", panel, UDim2.fromOffset(22, 15), UDim2.fromOffset(290, 38),
	"SETTINGS", 26, Color3.fromRGB(250, 222, 182), true)
label("SessionNote", panel, UDim2.fromOffset(330, 24), UDim2.fromOffset(210, 25),
	"Saved for this session", 11, Color3.fromRGB(176, 166, 153))

local divider = Instance.new("Frame")
divider.Position = UDim2.fromOffset(20, 57)
divider.Size = UDim2.fromOffset(520, 2)
divider.BackgroundColor3 = Color3.fromRGB(156, 103, 48)
divider.BorderSizePixel = 0
divider.Parent = panel

local content = Instance.new("ScrollingFrame")
content.Name = "Content"
content.Position = UDim2.fromOffset(18, 67)
content.Size = UDim2.fromOffset(524, 483)
content.CanvasSize = UDim2.fromOffset(0, 601)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 5
content.ScrollBarImageColor3 = Color3.fromRGB(178, 122, 71)
content.Parent = panel

local function section(name: string, y: number)
	label(name, content, UDim2.fromOffset(10, y), UDim2.fromOffset(480, 26),
		name, 15, Color3.fromRGB(239, 178, 96), true)
end

local refreshers: {() -> ()} = {}

local function slider(settingKey: string, title: string, y: number, minimum: number,
	maximum: number, decimalPlaces: number)
	label(settingKey .. "Label", content, UDim2.fromOffset(10, y), UDim2.fromOffset(315, 24),
		title, 14, Color3.fromRGB(243, 229, 208), true)
	local numberLabel = label(settingKey .. "Value", content,
		UDim2.fromOffset(410, y), UDim2.fromOffset(82, 24), "", 14,
		Color3.fromRGB(255, 207, 126), true)
	numberLabel.TextXAlignment = Enum.TextXAlignment.Right

	local track = Instance.new("TextButton")
	track.Name = settingKey .. "Slider"
	track.Position = UDim2.fromOffset(10, y + 29)
	track.Size = UDim2.fromOffset(480, 24)
	track.BackgroundTransparency = 1
	track.BorderSizePixel = 0
	track.Text = ""
	track.AutoButtonColor = false
	track.Parent = content

	local rail = Instance.new("Frame")
	rail.Name = "Rail"
	rail.Position = UDim2.fromOffset(0, 8)
	rail.Size = UDim2.new(1, 0, 0, 8)
	rail.BackgroundColor3 = Color3.fromRGB(91, 77, 64)
	rail.BorderSizePixel = 0
	rail.Parent = track
	corner(rail, 4)

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Color3.fromRGB(222, 151, 75)
	fill.BorderSizePixel = 0
	fill.Parent = rail
	corner(fill, 4)

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.fromScale(0, 0.5)
	knob.Size = UDim2.fromOffset(16, 16)
	knob.BackgroundColor3 = Color3.fromRGB(255, 226, 176)
	knob.BorderSizePixel = 0
	knob.Parent = track
	corner(knob, 8)

	local function refresh()
		local value = SettingsStore.GetNumber(settingKey)
		local fraction = math.clamp((value - minimum) / (maximum - minimum), 0, 1)
		fill.Size = UDim2.fromScale(fraction, 1)
		knob.Position = UDim2.fromScale(fraction, 0.5)
		numberLabel.Text = string.format("%." .. decimalPlaces .. "f", value)
	end
	table.insert(refreshers, refresh)
	refresh()

	local dragging = false
	local dragType: Enum.UserInputType? = nil
	local function updateFromX(x: number)
		local width = track.AbsoluteSize.X
		if width <= 0 then
			return
		end
		local fraction = math.clamp((x - track.AbsolutePosition.X) / width, 0, 1)
		local factor = 10 ^ decimalPlaces
		SettingsStore.Set(settingKey, math.round((minimum + (maximum - minimum) * fraction) * factor) / factor)
	end
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragType = input.UserInputType
			updateFromX(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and ((dragType == Enum.UserInputType.MouseButton1
			and input.UserInputType == Enum.UserInputType.MouseMovement)
			or (dragType == Enum.UserInputType.Touch and input.UserInputType == Enum.UserInputType.Touch)) then
			updateFromX(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if dragging and input.UserInputType == dragType then
			dragging = false
			dragType = nil
		end
	end)
end

local function toggle(settingKey: string, title: string, y: number)
	label(settingKey .. "Label", content, UDim2.fromOffset(10, y), UDim2.fromOffset(355, 32),
		title, 14, Color3.fromRGB(243, 229, 208), true)
	local button = Instance.new("TextButton")
	button.Name = settingKey .. "Toggle"
	button.Position = UDim2.fromOffset(388, y)
	button.Size = UDim2.fromOffset(102, 32)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextSize = 13
	button.Parent = content
	corner(button, 5)
	local function refresh()
		local enabled = SettingsStore.GetBoolean(settingKey)
		button.Text = if enabled then "ON" else "OFF"
		button.BackgroundColor3 = if enabled
			then Color3.fromRGB(95, 139, 94)
			else Color3.fromRGB(89, 79, 71)
		button.TextColor3 = Color3.fromRGB(250, 239, 217)
	end
	table.insert(refreshers, refresh)
	refresh()
	button.Activated:Connect(function()
		SettingsStore.Set(settingKey, not SettingsStore.GetBoolean(settingKey))
	end)
end

section("CONTROLS", 0)
slider("MouseSensitivity", "Mouse Sensitivity", 32, 0.1, 2, 2)
section("AUDIO", 111)
slider("MasterVolume", "Master Volume", 143, 0, 1, 2)
slider("WeaponVolume", "Weapon Volume", 213, 0, 1, 2)
slider("UIVolume", "UI Volume", 283, 0, 1, 2)
section("VISUAL", 359)
toggle("CameraBobEnabled", "Camera Bob", 391)
toggle("WeaponSwayEnabled", "Weapon Sway", 437)
toggle("TracersEnabled", "Tracers", 483)
toggle("HitmarkerEnabled", "Hitmarker", 529)

local resetButton = Instance.new("TextButton")
resetButton.Name = "ResetToDefault"
resetButton.Position = UDim2.fromOffset(20, 567)
resetButton.Size = UDim2.fromOffset(245, 43)
resetButton.BackgroundColor3 = Color3.fromRGB(73, 60, 49)
resetButton.BorderSizePixel = 0
resetButton.Font = Enum.Font.GothamBold
resetButton.Text = "RESET TO DEFAULT"
resetButton.TextColor3 = Color3.fromRGB(241, 220, 186)
resetButton.TextSize = 13
resetButton.Parent = panel
corner(resetButton, 6)

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.Position = UDim2.fromOffset(294, 567)
closeButton.Size = UDim2.fromOffset(245, 43)
closeButton.BackgroundColor3 = Color3.fromRGB(159, 76, 46)
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "CLOSE"
closeButton.TextColor3 = Color3.fromRGB(252, 233, 204)
closeButton.TextSize = 14
closeButton.Parent = panel
corner(closeButton, 6)

local function updateScale()
	local camera = Workspace.CurrentCamera
	if camera then
		local viewport = camera.ViewportSize
		scale.Scale = math.clamp(math.min(viewport.X / 650, viewport.Y / 720), 0.55, 1)
	end
end
local viewportConnection: RBXScriptConnection? = nil
local function bindCamera()
	if viewportConnection then
		viewportConnection:Disconnect()
		viewportConnection = nil
	end
	local camera = Workspace.CurrentCamera
	if camera then
		viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
	end
	updateScale()
end
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
bindCamera()

local function updatePanel(isOpen: boolean)
	inputSink.Visible = isOpen
	panel.Visible = isOpen
	if isOpen then
		UserInputService.MouseIconEnabled = true
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	else
		if GameState.IsArena(localPlayer) then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			UserInputService.MouseIconEnabled = false
		else
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			UserInputService.MouseIconEnabled = true
		end
	end
end

SettingsStore.Changed:Connect(function()
	for _, refresh in refreshers do
		refresh()
	end
end)
SettingsStore.OpenChanged:Connect(updatePanel)
settingsButton.Activated:Connect(function()
	SettingsStore.SetOpen(not SettingsStore.IsOpen())
end)
inputSink.Activated:Connect(function()
	SettingsStore.SetOpen(false)
end)
resetButton.Activated:Connect(SettingsStore.Reset)
closeButton.Activated:Connect(function()
	SettingsStore.SetOpen(false)
end)
UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Escape and SettingsStore.IsOpen() then
		SettingsStore.SetOpen(false)
	end
end)
localPlayer:GetAttributeChangedSignal(GameState.Attribute):Connect(function()
	local state = localPlayer:GetAttribute(GameState.Attribute)
	settingsButton.Visible = state == GameState.Lobby or state == GameState.Arena
	if state == GameState.EnteringArena or state == GameState.Dead then
		SettingsStore.SetOpen(false)
	end
end)

task.spawn(function()
	local arena = Workspace:WaitForChild("Arena")
	local lobby = arena:WaitForChild("Lobby")
	local access = lobby:WaitForChild("SettingsAccess")
	local board = access:WaitForChild("SettingsBoard")
	local prompt = board:WaitForChild("SettingsPrompt")
	if prompt:IsA("ProximityPrompt") then
		prompt.Triggered:Connect(function()
			if localPlayer:GetAttribute(GameState.Attribute) == GameState.Lobby then
				SettingsStore.SetOpen(true)
			end
		end)
	end
end)

updatePanel(false)
settingsButton.Visible = localPlayer:GetAttribute(GameState.Attribute) == GameState.Lobby
	or GameState.IsArena(localPlayer)
