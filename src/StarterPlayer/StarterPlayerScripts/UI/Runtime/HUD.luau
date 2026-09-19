--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Fusion"))
local WeaponConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("WeaponConfig"))
local Theme = require(ReplicatedStorage:WaitForChild("UI"):WaitForChild("Theme"))
local StatusCard = require(ReplicatedStorage:WaitForChild("UI"):WaitForChild("Components"):WaitForChild("StatusCard"))
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local GameState = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameState"))
local KillFeed = require(script.Parent:WaitForChild("KillFeed"))
local RuntimeState = require(script.Parent:WaitForChild("RuntimeState"))

local HUD = {}

function HUD.mount(
	scope: Fusion.Scope,
	context: {state: RuntimeState.State, gameAudio: any}
)
	local state = context.state
	local playerGui = state.playerGui
	local old = playerGui:FindFirstChild("RevolverHUD")
	if old then
		old:Destroy()
	end

	local screenGui = scope:New "ScreenGui" {
		Name = "RevolverHUD",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 10,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = playerGui,
	}

	local crosshair = scope:New "Frame" {
		Name = "Crosshair",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		Visible = state.combatVisible,
		[Fusion.Children] = {
			scope:New "Frame" {
				Name = "Top",
				Position = UDim2.fromOffset(7, 0),
				Size = UDim2.fromOffset(2, 5),
				BorderSizePixel = 0,
				BackgroundColor3 = Color3.new(1, 1, 1),
			},
			scope:New "Frame" {
				Name = "Bottom",
				Position = UDim2.fromOffset(7, 11),
				Size = UDim2.fromOffset(2, 5),
				BorderSizePixel = 0,
				BackgroundColor3 = Color3.new(1, 1, 1),
			},
			scope:New "Frame" {
				Name = "Left",
				Position = UDim2.fromOffset(0, 7),
				Size = UDim2.fromOffset(5, 2),
				BorderSizePixel = 0,
				BackgroundColor3 = Color3.new(1, 1, 1),
			},
			scope:New "Frame" {
				Name = "Right",
				Position = UDim2.fromOffset(11, 7),
				Size = UDim2.fromOffset(5, 2),
				BorderSizePixel = 0,
				BackgroundColor3 = Color3.new(1, 1, 1),
			},
		},
	}

	local hitMarkerTarget = scope:Value(1)
	local hitMarkerTweenInfo = scope:Value(TweenInfo.new(0.1))
	local hitMarkerTransparency = scope:Tween(hitMarkerTarget, hitMarkerTweenInfo)
	local hitMarkerText = scope:Value("×")
	local hitMarkerColor = scope:Value(Color3.new(1, 1, 1))
	local hitMarkerSize = scope:Value(30)
	local hitMarkerStroke = scope:Value(0.35)
	local hitMarker = scope:New "TextLabel" {
		Name = "HitMarker",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(54, 54),
		BackgroundTransparency = 1,
		Font = Theme.Fonts.Bold,
		Text = hitMarkerText,
		TextColor3 = hitMarkerColor,
		TextSize = hitMarkerSize,
		TextStrokeTransparency = hitMarkerStroke,
		TextTransparency = hitMarkerTransparency,
		Visible = state.combatVisible,
		ZIndex = 5,
		Parent = screenGui,
	}

	local killNotificationTarget = scope:Value(1)
	local killNotificationTweenInfo = scope:Value(TweenInfo.new(0.25))
	local killNotificationTransparency = scope:Tween(killNotificationTarget, killNotificationTweenInfo)
	local killNotificationText = scope:Value("")
	local killNotification = scope:New "TextLabel" {
		Name = "KillNotification",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.61),
		Size = UDim2.fromOffset(420, 32),
		BackgroundTransparency = 1,
		Font = Theme.Fonts.Semibold,
		Text = killNotificationText,
		TextColor3 = Theme.Colors.Accent,
		TextSize = 20,
		TextStrokeTransparency = 0.45,
		TextTransparency = killNotificationTransparency,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Visible = state.combatVisible,
		ZIndex = 5,
		Parent = screenGui,
	}

	StatusCard(scope, {
		parent = screenGui,
		variant = "runtime",
		position = UDim2.fromScale(0, 0),
		anchorPoint = Vector2.new(0, 0),
		size = UDim2.fromScale(1, 1),
		ammo = state.ammo,
		capacity = state.capacity,
		streak = state.streak,
		wanted = state.localWanted,
		gameState = state.gameState,
	})

	local announcementText = scope:Value("")
	local announcementColor = scope:Value(Color3.fromRGB(255, 202, 92))
	local announcementTarget = scope:Value(1)
	local announcementBackgroundTarget = scope:Value(1)
	local announcementTweenInfo = scope:Value(TweenInfo.new(0.3))
	local announcementTransparency = scope:Tween(announcementTarget, announcementTweenInfo)
	local announcementBackgroundTransparency = scope:Tween(announcementBackgroundTarget, announcementTweenInfo)
	local announcementLabel = scope:New "TextLabel" {
		Name = "StreakAnnouncement",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 72),
		Size = UDim2.fromOffset(520, 58),
		BackgroundColor3 = Color3.fromRGB(28, 20, 15),
		BackgroundTransparency = announcementBackgroundTransparency,
		BorderSizePixel = 0,
		Font = Theme.Fonts.Bold,
		Text = announcementText,
		TextColor3 = announcementColor,
		TextSize = 22,
		TextStrokeTransparency = 0.45,
		TextTransparency = announcementTransparency,
		ZIndex = 6,
		Parent = screenGui,
	}

	local deathFlashTarget = scope:Value(1)
	local deathFlashTweenInfo = scope:Value(TweenInfo.new(0.4))
	local deathFlashTransparency = scope:Tween(deathFlashTarget, deathFlashTweenInfo)
	local deathFlashColor = scope:Value(Color3.fromRGB(130, 22, 16))
	local deathFlash = scope:New "Frame" {
		Name = "DeathFlash",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = deathFlashColor,
		BackgroundTransparency = deathFlashTransparency,
		BorderSizePixel = 0,
		ZIndex = 7,
		Parent = screenGui,
	}

	local deathText = scope:Value("")
	local deathLabelTarget = scope:Value(1)
	local deathLabelTweenInfo = scope:Value(TweenInfo.new(0.2))
	local deathLabelTransparency = scope:Tween(deathLabelTarget, deathLabelTweenInfo)
	local deathLabel = scope:New "TextLabel" {
		Name = "DeathFeedback",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.72),
		Size = UDim2.fromOffset(440, 38),
		BackgroundTransparency = 1,
		Font = Theme.Fonts.Semibold,
		Text = deathText,
		TextColor3 = Color3.fromRGB(255, 215, 190),
		TextSize = 21,
		TextStrokeTransparency = 0.35,
		TextTransparency = deathLabelTransparency,
		ZIndex = 8,
		Parent = screenGui,
	}

	local announcementSound = scope:New "Sound" {
		Name = "AnnouncementSound",
		SoundId = "rbxasset://sounds/electronicpingshort.wav",
		Volume = 0.35,
		SoundGroup = context.gameAudio.UIGroup,
		Parent = screenGui,
	}

	local rollLabelText = scope:Computed(function(use)
		if use(state.rolling) then
			return "E  ROLLING"
		end
		local remaining = use(state.rollRemaining)
		if remaining > 0 then
			return string.format("E  ROLL  %.1f", remaining)
		end
		return "E  ROLL"
	end)
	local rollLabelColor = scope:Computed(function(use)
		if use(state.rolling) then
			return Color3.fromRGB(255, 202, 92)
		end
		if use(state.rollRemaining) > 0 then
			return Color3.fromRGB(175, 180, 190)
		end
		return Color3.new(1, 1, 1)
	end)
	local cooldownFillColor = scope:Computed(function(use)
		if use(state.rolling) then
			return Color3.fromRGB(255, 160, 72)
		end
		if use(state.rollRemaining) > 0 then
			return Color3.fromRGB(103, 112, 128)
		end
		return Color3.fromRGB(87, 220, 134)
	end)
	local cooldownFillProgress = scope:Computed(function(use)
		if use(state.rolling) then
			return 1
		end
		local remaining = use(state.rollRemaining)
		if remaining > 0 then
			return 1 - math.clamp(remaining / WeaponConfig.RollCooldown, 0, 1)
		end
		return 1
	end)
	local smoothedCooldownFillProgress = scope:Spring(cooldownFillProgress, 100, 1)
	local cooldownFillSize = scope:Computed(function(use)
		if use(state.rolling) or use(state.rollRemaining) <= 0 then
			return UDim2.fromScale(1, 1)
		end
		return UDim2.fromScale(use(smoothedCooldownFillProgress), 1)
	end)

	local cooldownFill = scope:New "Frame" {
		Name = "Fill",
		Size = cooldownFillSize,
		BackgroundColor3 = cooldownFillColor,
		BorderSizePixel = 0,
	}
	local cooldownTrack = scope:New "Frame" {
		Name = "CooldownTrack",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 5),
		BackgroundColor3 = Color3.fromRGB(48, 51, 58),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		[Fusion.Children] = cooldownFill,
	}
	local rollPanel = scope:New "Frame" {
		Name = "RollPanel",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, Theme.Layout.HudMargin, 1, -26),
		Size = UDim2.fromOffset(170, 44),
		BackgroundColor3 = Color3.fromRGB(20, 22, 27),
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Visible = state.combatVisible,
		[Fusion.Children] = {
			scope:New "UIStroke" {
				Color = Color3.fromRGB(115, 122, 135),
				Thickness = 1,
				Transparency = 0.2,
			},
			scope:New "TextLabel" {
				Name = "Label",
				Size = UDim2.new(1, 0, 1, -5),
				BackgroundTransparency = 1,
				Font = Theme.Fonts.Bold,
				Text = rollLabelText,
				TextColor3 = rollLabelColor,
				TextSize = 19,
				TextStrokeTransparency = 0.65,
			},
			cooldownTrack,
		},
	}

	local killFeed = KillFeed.mount(scope, screenGui, state)

	local alive = true
	local markerGeneration = 0
	local notificationGeneration = 0
	local announcementGeneration = 0
	local deathGeneration = 0
	local markerScopes: {[Player]: Fusion.Scope} = {}
	local markerHeads: {[Player]: BasePart} = {}
	table.insert(scope, function()
		alive = false
		markerGeneration += 1
		notificationGeneration += 1
		announcementGeneration += 1
		deathGeneration += 1
	end)

	local function showMarker(markerType: string)
		if not Fusion.peek(state.combatVisible) or not Fusion.peek(state.settings.HitmarkerEnabled) then
			return
		end
		markerGeneration += 1
		local generation = markerGeneration
		local isKill = markerType == "Kill"
		hitMarkerText:set(if isKill then "✕" else "×")
		hitMarkerColor:set(if isKill then Color3.fromRGB(255, 103, 72) else Color3.new(1, 1, 1))
		hitMarkerSize:set(if isKill then 40 else 30)
		hitMarkerStroke:set(if isKill then 0.15 else 0.35)
		hitMarkerTweenInfo:set(TweenInfo.new(0))
		hitMarkerTarget:set(0)
		task.defer(function()
			if alive then
				hitMarkerTweenInfo:set(TweenInfo.new(0.1))
			end
		end)
		task.delay(if isKill then 0.28 else 0.12, function()
			if alive and markerGeneration == generation then
				hitMarkerTarget:set(1)
			end
		end)
	end

	local function showKillNotification(targetName: string)
		notificationGeneration += 1
		local generation = notificationGeneration
		killNotificationText:set(string.format("Eliminated %s", targetName))
		killNotificationTweenInfo:set(TweenInfo.new(0))
		killNotificationTarget:set(0)
		task.defer(function()
			if alive then
				killNotificationTweenInfo:set(TweenInfo.new(0.25))
			end
		end)
		task.delay(1.1, function()
			if alive and notificationGeneration == generation then
				killNotificationTarget:set(1)
			end
		end)
	end

	local function showAnnouncement(text: string, isStreakEnded: boolean)
		announcementGeneration += 1
		local generation = announcementGeneration
		announcementText:set(text)
		announcementColor:set(if isStreakEnded
			then Color3.fromRGB(255, 132, 92)
			else Color3.fromRGB(255, 202, 92))
		announcementTweenInfo:set(TweenInfo.new(0))
		announcementTarget:set(0)
		announcementBackgroundTarget:set(0.28)
		task.defer(function()
			if alive then
				announcementTweenInfo:set(TweenInfo.new(0.3))
			end
		end)
		announcementSound:Play()
		task.delay(2.1, function()
			if alive and announcementGeneration == generation then
				announcementTarget:set(1)
				announcementBackgroundTarget:set(1)
			end
		end)
	end

	local function showDeathFeedback(killerName: string)
		deathGeneration += 1
		local generation = deathGeneration
		deathText:set(if killerName ~= "" then string.format("Eliminated by %s", killerName) else "Eliminated")
		deathLabelTweenInfo:set(TweenInfo.new(0))
		deathLabelTarget:set(0)
		deathFlashColor:set(Color3.fromRGB(130, 22, 16))
		deathFlashTweenInfo:set(TweenInfo.new(0))
		deathFlashTarget:set(0.88)
		task.defer(function()
			if alive then
				deathLabelTweenInfo:set(TweenInfo.new(0.2))
				deathFlashTweenInfo:set(TweenInfo.new(0.4))
			end
		end)
		task.delay(0.4, function()
			if alive and deathGeneration == generation then
				deathFlashTarget:set(1)
			end
		end)
		task.delay(1.05, function()
			if alive and deathGeneration == generation then
				deathLabelTarget:set(1)
			end
		end)
	end

	local function clearTransientState()
		markerGeneration += 1
		notificationGeneration += 1
		announcementGeneration += 1
		hitMarkerTarget:set(1)
		killNotificationTarget:set(1)
		announcementTarget:set(1)
		announcementBackgroundTarget:set(1)
		killFeed.Clear()
	end

	local function clearMarker(player: Player)
		local markerScope = markerScopes[player]
		if markerScope then
			Fusion.doCleanup(markerScope)
			markerScopes[player] = nil
		end
		markerHeads[player] = nil
	end

	local function refreshWantedBillboard(player: Player)
		local character = player.Character
		local head = if character then character:FindFirstChild("Head") else nil
		local shouldShow = GameState.IsArena(player)
			and player:GetAttribute(Constants.Attributes.Wanted) == true
			and head ~= nil
			and head:IsA("BasePart")

		local markerScope = markerScopes[player]
		if markerScope and (not shouldShow or markerHeads[player] ~= head) then
			clearMarker(player)
			markerScope = nil
		end
		if not shouldShow or markerScope then
			return
		end

		markerScope = scope:innerScope()
		markerScopes[player] = markerScope
		markerHeads[player] = head :: BasePart
		markerScope:New "BillboardGui" {
			Name = "WantedMarker",
			Adornee = head :: BasePart,
			AlwaysOnTop = true,
			MaxDistance = 120,
			Size = UDim2.fromOffset(110, 28),
			StudsOffsetWorldSpace = Vector3.new(0, 3, 0),
			Parent = screenGui,
			[Fusion.Children] = markerScope:New "TextLabel" {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.fromRGB(62, 25, 15),
				BackgroundTransparency = 0.18,
				BorderSizePixel = 0,
				Font = Theme.Fonts.Bold,
				Text = "WANTED",
				TextColor3 = Color3.fromRGB(255, 192, 74),
				TextSize = 15,
				TextStrokeTransparency = 0.45,
			},
		}
	end

	local function trackWantedPlayer(player: Player)
		table.insert(scope, player:GetAttributeChangedSignal(Constants.Attributes.Wanted):Connect(function()
			refreshWantedBillboard(player)
		end))
		table.insert(scope, player:GetAttributeChangedSignal(GameState.Attribute):Connect(function()
			refreshWantedBillboard(player)
		end))
		table.insert(scope, player.CharacterAdded:Connect(function(character)
			task.spawn(function()
				character:WaitForChild("Head", 8)
				if alive then
					refreshWantedBillboard(player)
				end
			end)
		end))
		table.insert(scope, player.CharacterRemoving:Connect(function()
			clearMarker(player)
		end))
		refreshWantedBillboard(player)
	end

	for _, player in Players:GetPlayers() do
		trackWantedPlayer(player)
	end
	table.insert(scope, Players.PlayerAdded:Connect(trackWantedPlayer))
	table.insert(scope, Players.PlayerRemoving:Connect(function(player)
		clearMarker(player)
	end))

	table.insert(scope, state.combatFeedback.OnClientEvent:Connect(function(
		feedbackType: any,
		valueA: any,
		valueB: any,
		valueC: any
	)
		if feedbackType == "Hit" then
			showMarker("Hit")
		elseif feedbackType == "Kill" then
			showMarker("Kill")
			showKillNotification(if typeof(valueA) == "string" then valueA else "Player")
			if typeof(valueB) == "number" then
				state.streak:set(math.max(0, math.floor(valueB)))
			end
		elseif feedbackType == "Milestone" then
			if not Fusion.peek(state.combatVisible) then
				return
			end
			local playerName = if typeof(valueA) == "string" then valueA else "Player"
			local milestone = if typeof(valueB) == "string" then valueB else "HOT"
			local feedbackStreak = if typeof(valueC) == "number" then math.floor(valueC) else 0
			showAnnouncement(string.format("%s — %s  x%d", playerName, milestone, feedbackStreak), false)
		elseif feedbackType == "StreakEnded" then
			if not Fusion.peek(state.combatVisible) then
				return
			end
			local killerName = if typeof(valueA) == "string" then valueA else "Player"
			local wantedName = if typeof(valueB) == "string" then valueB else "Player"
			showAnnouncement(string.format("%s ended %s's streak!", killerName, wantedName), true)
		elseif feedbackType == "Death" then
			showDeathFeedback(if typeof(valueA) == "string" then valueA else "")
		end
	end))

	scope:Observer(state.combatVisible):onChange(function()
		if not Fusion.peek(state.combatVisible) then
			clearTransientState()
		end
	end)
	scope:Observer(state.settings.HitmarkerEnabled):onChange(function()
		if not Fusion.peek(state.settings.HitmarkerEnabled) then
			markerGeneration += 1
			hitMarkerTarget:set(1)
		end
	end)
	clearTransientState()

	return screenGui
end

return table.freeze(HUD)
