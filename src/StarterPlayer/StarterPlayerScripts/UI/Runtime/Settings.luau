--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Fusion = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Fusion"))
local Theme = require(ReplicatedStorage:WaitForChild("UI"):WaitForChild("Theme"))
local GameState = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameState"))
local RuntimeState = require(script.Parent:WaitForChild("RuntimeState"))

local Settings = {}

local function corner(scope: Fusion.Scope, parent: Instance, radius: number)
	return scope:New "UICorner" {
		CornerRadius = UDim.new(0, radius),
		Parent = parent,
	}
end

local function makeLabel(
	scope: Fusion.Scope,
	name: string,
	parent: Instance,
	position: UDim2,
	size: UDim2,
	value: Fusion.UsedAs<string>,
	textSize: number,
	color: Color3,
	bold: boolean?,
	alignment: Enum.TextXAlignment?
): TextLabel
	return scope:New "TextLabel" {
		Name = name,
		Position = position,
		Size = size,
		BackgroundTransparency = 1,
		Font = if bold then Theme.Fonts.Bold else Theme.Fonts.Regular,
		Text = value,
		TextColor3 = color,
		TextSize = textSize,
		TextXAlignment = alignment or Enum.TextXAlignment.Left,
		Parent = parent,
	}
end

function Settings.mount(scope: Fusion.Scope, state: RuntimeState.State, settingsStore: any)
	local old = state.playerGui:FindFirstChild("RevolverSettingsUI")
	if old then
		old:Destroy()
	end
	local alive = true
	table.insert(scope, function()
		alive = false
		if settingsStore.IsOpen() then
			settingsStore.SetOpen(false)
		end
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end)

	local scaleValue = scope:Value(1)
	local visibleInState = scope:Computed(function(use)
		local currentState = use(state.gameState)
		return currentState == GameState.Lobby or currentState == GameState.Arena
	end)
	if not Fusion.peek(visibleInState) then
		settingsStore.SetOpen(false)
	end
	local settingsButtonVisible = scope:Computed(function(use)
		return use(visibleInState) and not use(state.panelOpen)
	end)

	local settingsButton = scope:New "TextButton" {
		Name = "SettingsButton",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -Theme.Layout.ScreenMargin, 0, 18),
		Size = UDim2.fromOffset(110, 36),
		BackgroundColor3 = Theme.Colors.Surface,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		Font = Theme.Fonts.Bold,
		Text = "SETTINGS",
		TextColor3 = Color3.fromRGB(248, 218, 172),
		TextSize = 13,
		AutoButtonColor = false,
		ZIndex = 2,
		Visible = settingsButtonVisible,
		[Fusion.OnEvent("Activated")] = function()
			settingsStore.SetOpen(not settingsStore.IsOpen())
		end,
	}
	corner(scope, settingsButton, 6)

	local settingsBackdrop = scope:New "Frame" {
		Name = "SettingsBackdrop",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.52,
		BorderSizePixel = 0,
		Visible = state.panelOpen,
		ZIndex = 0,
	}

	local inputSink = scope:New "TextButton" {
		Name = "SettingsInputSink",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Modal = true,
		Visible = state.panelOpen,
		Active = true,
		ZIndex = 1,
		Selectable = false,
		[Fusion.OnEvent("Activated")] = function()
			settingsStore.SetOpen(false)
		end,
	}

	local panel = scope:New "Frame" {
		Name = "SettingsPanel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(Theme.Layout.SettingsPanelWidth, Theme.Layout.SettingsPanelHeight),
		BackgroundColor3 = Theme.Colors.Panel,
		BorderSizePixel = 0,
		Visible = state.panelOpen,
		ZIndex = 2,
		Active = true,
		ClipsDescendants = true,
		[Fusion.Children] = {
			scope:New "UIStroke" {
				Color = Theme.Colors.PanelBorder,
				Thickness = 2,
				Transparency = 0.15,
			},
		},
	}
	corner(scope, panel, 10)
	scope:New "UIScale" {
		Scale = scaleValue,
		Parent = panel,
	}

	makeLabel(scope, "Title", panel, UDim2.fromOffset(22, 15), UDim2.fromOffset(290, 38),
		"SETTINGS", 26, Color3.fromRGB(250, 222, 182), true)
	makeLabel(scope, "SessionNote", panel, UDim2.fromOffset(330, 24), UDim2.fromOffset(210, 25),
		"Saved for this session", 11, Color3.fromRGB(176, 166, 153))

	scope:New "Frame" {
		Position = UDim2.fromOffset(20, 57),
		Size = UDim2.fromOffset(520, 2),
		BackgroundColor3 = Color3.fromRGB(156, 103, 48),
		BorderSizePixel = 0,
		Parent = panel,
	}

	local content = scope:New "ScrollingFrame" {
		Name = "Content",
		Position = UDim2.fromOffset(18, 67),
		Size = UDim2.fromOffset(524, 483),
		CanvasSize = UDim2.fromOffset(0, Theme.Layout.SettingsContentHeight),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = Color3.fromRGB(178, 122, 71),
		Parent = panel,
	}

	local function section(name: string, y: number)
		makeLabel(scope, name, content, UDim2.fromOffset(10, y), UDim2.fromOffset(480, 26),
			name, 15, Color3.fromRGB(239, 178, 96), true)
	end

	local function slider(
		settingKey: string,
		title: string,
		y: number,
		minimum: number,
		maximum: number,
		decimalPlaces: number
	)
		local valueState = ((state.settings :: {[string]: any})[settingKey] :: Fusion.Value<number>)
		makeLabel(scope, settingKey .. "Label", content, UDim2.fromOffset(10, y), UDim2.fromOffset(315, 24),
			title, 14, Color3.fromRGB(243, 229, 208), true)
		local fraction = scope:Computed(function(use)
			return math.clamp((use(valueState) - minimum) / (maximum - minimum), 0, 1)
		end)
		local visualFraction = scope:Spring(fraction, 180, 1)
		local numberText = scope:Computed(function(use)
			return string.format("%." .. decimalPlaces .. "f", use(valueState))
		end)
		local numberLabel = makeLabel(scope, settingKey .. "Value", content,
			UDim2.fromOffset(410, y), UDim2.fromOffset(82, 24), numberText, 14,
			Color3.fromRGB(255, 207, 126), true, Enum.TextXAlignment.Right)

		local track = scope:New "TextButton" {
			Name = settingKey .. "Slider",
			Position = UDim2.fromOffset(10, y + 29),
			Size = UDim2.fromOffset(480, 24),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			Active = true,
			Selectable = false,
			Parent = content,
		}
		local rail = scope:New "Frame" {
			Name = "Rail",
			Position = UDim2.fromOffset(0, 8),
			Size = UDim2.new(1, 0, 0, 8),
			BackgroundColor3 = Theme.Colors.SliderRail,
			BorderSizePixel = 0,
			Parent = track,
		}
		corner(scope, rail, 4)
		local fill = scope:New "Frame" {
			Name = "Fill",
			Size = scope:Computed(function(use)
				return UDim2.fromScale(use(visualFraction), 1)
			end),
			BackgroundColor3 = Theme.Colors.SliderFill,
			BorderSizePixel = 0,
			Parent = rail,
		}
		corner(scope, fill, 4)
		local knob = scope:New "Frame" {
			Name = "Knob",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = scope:Computed(function(use)
				return UDim2.fromScale(use(visualFraction), 0.5)
			end),
			Size = UDim2.fromOffset(16, 16),
			BackgroundColor3 = Theme.Colors.SliderKnob,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = track,
		}
		corner(scope, knob, 8)

		local dragging = false
		local dragType: Enum.UserInputType? = nil
		local function updateFromX(x: number)
			local width = track.AbsoluteSize.X
			if width <= 0 then
				return
			end
			local fractionValue = math.clamp((x - track.AbsolutePosition.X) / width, 0, 1)
			local factor = 10 ^ decimalPlaces
			settingsStore.Set(settingKey,
				math.round((minimum + (maximum - minimum) * fractionValue) * factor) / factor)
		end

		table.insert(scope, track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragType = input.UserInputType
				updateFromX(input.Position.X)
			end
		end))
		table.insert(scope, UserInputService.InputChanged:Connect(function(input)
			if dragging and ((dragType == Enum.UserInputType.MouseButton1
				and input.UserInputType == Enum.UserInputType.MouseMovement)
				or (dragType == Enum.UserInputType.Touch and input.UserInputType == Enum.UserInputType.Touch)) then
				updateFromX(input.Position.X)
			end
		end))
		table.insert(scope, UserInputService.InputEnded:Connect(function(input)
			if dragging and input.UserInputType == dragType then
				dragging = false
				dragType = nil
			end
		end))
	end

	local function toggle(settingKey: string, title: string, y: number)
		local valueState = ((state.settings :: {[string]: any})[settingKey] :: Fusion.Value<boolean>)
		makeLabel(scope, settingKey .. "Label", content, UDim2.fromOffset(10, y), UDim2.fromOffset(355, 32),
			title, 14, Color3.fromRGB(243, 229, 208), true)
		local button = scope:New "TextButton" {
			Name = settingKey .. "Toggle",
			Position = UDim2.fromOffset(388, y),
			Size = UDim2.fromOffset(102, 32),
			BorderSizePixel = 0,
			Font = Theme.Fonts.Bold,
			Text = scope:Computed(function(use)
				return if use(valueState) then "ON" else "OFF"
			end),
			TextSize = 13,
			BackgroundColor3 = scope:Computed(function(use)
				return if use(valueState)
					then Theme.Colors.ToggleOn
					else Theme.Colors.ToggleOff
			end),
			TextColor3 = Color3.fromRGB(250, 239, 217),
			AutoButtonColor = false,
			Selectable = false,
			[Fusion.OnEvent("Activated")] = function()
				settingsStore.Set(settingKey, not settingsStore.GetBoolean(settingKey))
			end,
			Parent = content,
		}
		corner(scope, button, 5)
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

	local resetButton = scope:New "TextButton" {
		Name = "ResetToDefault",
		Position = UDim2.fromOffset(20, 567),
		Size = UDim2.fromOffset(245, 43),
		BackgroundColor3 = Theme.Colors.SurfaceRaised,
		BorderSizePixel = 0,
		Font = Theme.Fonts.Bold,
		Text = "RESET TO DEFAULT",
		TextColor3 = Color3.fromRGB(241, 220, 186),
		TextSize = 13,
		AutoButtonColor = false,
		Selectable = false,
		[Fusion.OnEvent("Activated")] = function()
			settingsStore.Reset()
		end,
		Parent = panel,
	}
	corner(scope, resetButton, 6)

	local closeButton = scope:New "TextButton" {
		Name = "Close",
		Position = UDim2.fromOffset(294, 567),
		Size = UDim2.fromOffset(245, 43),
		BackgroundColor3 = Theme.Colors.Danger,
		BorderSizePixel = 0,
		Font = Theme.Fonts.Bold,
		Text = "CLOSE",
		TextColor3 = Color3.fromRGB(252, 233, 204),
		TextSize = 14,
		AutoButtonColor = false,
		Selectable = false,
		[Fusion.OnEvent("Activated")] = function()
			settingsStore.SetOpen(false)
		end,
		Parent = panel,
	}
	corner(scope, closeButton, 6)

	local function updateScale()
		local camera = Workspace.CurrentCamera
		if camera then
			local viewport = camera.ViewportSize
			scaleValue:set(math.clamp(
				math.min(
					viewport.X / Theme.Layout.SettingsViewportWidth,
					viewport.Y / Theme.Layout.SettingsViewportHeight
				),
				Theme.Layout.SettingsMinScale,
				1
			))
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
			table.insert(scope, viewportConnection)
		end
		updateScale()
	end
	table.insert(scope, Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera))
	bindCamera()

	local function updatePanel(isOpen: boolean)
		if isOpen then
			UserInputService.MouseIconEnabled = true
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		elseif Fusion.peek(state.gameState) == GameState.Arena then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			UserInputService.MouseIconEnabled = false
		else
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			UserInputService.MouseIconEnabled = true
		end
	end
	scope:Observer(state.panelOpen):onChange(function()
		updatePanel(Fusion.peek(state.panelOpen))
	end)
	updatePanel(Fusion.peek(state.panelOpen))

	table.insert(scope, UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Escape and Fusion.peek(state.panelOpen) then
			settingsStore.SetOpen(false)
		end
	end))
	scope:Observer(state.gameState):onChange(function()
		local currentState = Fusion.peek(state.gameState)
		if currentState == GameState.EnteringArena or currentState == GameState.Dead then
			settingsStore.SetOpen(false)
		end
		updatePanel(Fusion.peek(state.panelOpen))
	end)
	scope:Observer(visibleInState):onChange(function()
		if not Fusion.peek(visibleInState) then
			settingsStore.SetOpen(false)
		end
	end)

	task.spawn(function()
		local arena = Workspace:WaitForChild("Arena")
		local lobby = arena:WaitForChild("Lobby")
		local access = lobby:WaitForChild("SettingsAccess")
		local board = access:WaitForChild("SettingsBoard")
		local prompt = board:WaitForChild("SettingsPrompt")
		if not alive then
			return
		end
		if prompt:IsA("ProximityPrompt") then
			table.insert(scope, prompt.Triggered:Connect(function()
				if Fusion.peek(state.gameState) == GameState.Lobby then
					settingsStore.SetOpen(true)
				end
			end))
		end
	end)

	local gui = scope:New "ScreenGui" {
		Name = "RevolverSettingsUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 30,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Enabled = visibleInState,
		Parent = state.playerGui,
		[Fusion.Children] = {
			settingsButton,
			settingsBackdrop,
			inputSink,
			panel,
		},
	}

	return gui
end

return table.freeze(Settings)
