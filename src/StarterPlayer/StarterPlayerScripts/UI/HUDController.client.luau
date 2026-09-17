--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local WeaponConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("WeaponConfig"))
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(sharedFolder:WaitForChild("Constants"))
local GameState = require(sharedFolder:WaitForChild("GameState"))
local clientShared = script.Parent.Parent:WaitForChild("Shared")
local SettingsStore = require(clientShared:WaitForChild("SettingsStore"))
local GameAudio = require(clientShared:WaitForChild("GameAudio"))
local KillFeedController = require(script.Parent:WaitForChild("KillFeedController"))
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local remotesFolder = ReplicatedStorage:WaitForChild(Constants.Remotes.Folder)
local combatFeedback = remotesFolder:WaitForChild(Constants.Remotes.CombatFeedback) :: RemoteEvent
local killFeed = remotesFolder:WaitForChild(Constants.Remotes.KillFeed) :: RemoteEvent

local HUD_NAME = "RevolverHUD"
local AMMO_ATTRIBUTE = Constants.Attributes.Ammo
local KILL_STREAK_ATTRIBUTE = Constants.Attributes.KillStreak
local WANTED_ATTRIBUTE = Constants.Attributes.Wanted
local ROLLING_ATTRIBUTE = Constants.Attributes.Rolling
local ROLL_READY_AT_ATTRIBUTE = Constants.Attributes.RollReadyAt

local existingHud = playerGui:FindFirstChild(HUD_NAME)
if existingHud then
	existingHud:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = HUD_NAME
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 10
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local crosshair = Instance.new("Frame")
crosshair.Name = "Crosshair"
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.Position = UDim2.fromScale(0.5, 0.5)
crosshair.Size = UDim2.fromOffset(16, 16)
crosshair.BackgroundTransparency = 1
crosshair.Parent = screenGui

local function createCrosshairLine(name: string, position: UDim2, size: UDim2)
	local line = Instance.new("Frame")
	line.Name = name
	line.Position = position
	line.Size = size
	line.BorderSizePixel = 0
	line.BackgroundColor3 = Color3.new(1, 1, 1)
	line.Parent = crosshair
end

createCrosshairLine("Top", UDim2.fromOffset(7, 0), UDim2.fromOffset(2, 5))
createCrosshairLine("Bottom", UDim2.fromOffset(7, 11), UDim2.fromOffset(2, 5))
createCrosshairLine("Left", UDim2.fromOffset(0, 7), UDim2.fromOffset(5, 2))
createCrosshairLine("Right", UDim2.fromOffset(11, 7), UDim2.fromOffset(5, 2))

local hitMarker = Instance.new("TextLabel")
hitMarker.Name = "HitMarker"
hitMarker.AnchorPoint = Vector2.new(0.5, 0.5)
hitMarker.Position = UDim2.fromScale(0.5, 0.5)
hitMarker.Size = UDim2.fromOffset(54, 54)
hitMarker.BackgroundTransparency = 1
hitMarker.Font = Enum.Font.GothamBold
hitMarker.Text = "×"
hitMarker.TextColor3 = Color3.new(1, 1, 1)
hitMarker.TextSize = 30
hitMarker.TextStrokeTransparency = 0.35
hitMarker.TextTransparency = 1
hitMarker.ZIndex = 5
hitMarker.Parent = screenGui

local killNotification = Instance.new("TextLabel")
killNotification.Name = "KillNotification"
killNotification.AnchorPoint = Vector2.new(0.5, 0.5)
killNotification.Position = UDim2.fromScale(0.5, 0.61)
killNotification.Size = UDim2.fromOffset(420, 32)
killNotification.BackgroundTransparency = 1
killNotification.Font = Enum.Font.GothamSemibold
killNotification.Text = ""
killNotification.TextColor3 = Color3.fromRGB(255, 190, 80)
killNotification.TextSize = 20
killNotification.TextStrokeTransparency = 0.45
killNotification.TextTransparency = 1
killNotification.ZIndex = 5
killNotification.Parent = screenGui

local ammoLabel = Instance.new("TextLabel")
ammoLabel.Name = "Ammo"
ammoLabel.AnchorPoint = Vector2.new(1, 1)
ammoLabel.Position = UDim2.new(1, -32, 1, -26)
ammoLabel.Size = UDim2.fromOffset(180, 42)
ammoLabel.BackgroundTransparency = 1
ammoLabel.Font = Enum.Font.GothamBold
ammoLabel.TextColor3 = Color3.new(1, 1, 1)
ammoLabel.TextStrokeTransparency = 0.5
ammoLabel.TextSize = 28
ammoLabel.TextXAlignment = Enum.TextXAlignment.Right
ammoLabel.Text = string.format("-- / %d", WeaponConfig.AmmoCapacity)
ammoLabel.Parent = screenGui

local streakLabel = Instance.new("TextLabel")
streakLabel.Name = "KillStreak"
streakLabel.AnchorPoint = Vector2.new(1, 0)
streakLabel.Position = UDim2.new(1, -32, 0, 65)
streakLabel.Size = UDim2.fromOffset(220, 34)
streakLabel.BackgroundTransparency = 1
streakLabel.Font = Enum.Font.GothamBold
streakLabel.TextColor3 = Color3.fromRGB(255, 202, 92)
streakLabel.TextStrokeTransparency = 0.5
streakLabel.TextSize = 22
streakLabel.TextXAlignment = Enum.TextXAlignment.Right
streakLabel.Text = "STREAK  x0"
streakLabel.Parent = screenGui

local killFeedController = KillFeedController.new(screenGui, killFeed, function(): boolean
	return GameState.IsArena(localPlayer)
end)

local announcementLabel = Instance.new("TextLabel")
announcementLabel.Name = "StreakAnnouncement"
announcementLabel.AnchorPoint = Vector2.new(0.5, 0)
announcementLabel.Position = UDim2.new(0.5, 0, 0, 72)
announcementLabel.Size = UDim2.fromOffset(520, 58)
announcementLabel.BackgroundColor3 = Color3.fromRGB(28, 20, 15)
announcementLabel.BackgroundTransparency = 1
announcementLabel.BorderSizePixel = 0
announcementLabel.Font = Enum.Font.GothamBold
announcementLabel.Text = ""
announcementLabel.TextColor3 = Color3.fromRGB(255, 202, 92)
announcementLabel.TextSize = 22
announcementLabel.TextStrokeTransparency = 0.45
announcementLabel.TextTransparency = 1
announcementLabel.ZIndex = 6
announcementLabel.Parent = screenGui

local deathFlash = Instance.new("Frame")
deathFlash.Name = "DeathFlash"
deathFlash.Size = UDim2.fromScale(1, 1)
deathFlash.BackgroundColor3 = Color3.fromRGB(130, 22, 16)
deathFlash.BackgroundTransparency = 1
deathFlash.BorderSizePixel = 0
deathFlash.ZIndex = 7
deathFlash.Parent = screenGui

local deathLabel = Instance.new("TextLabel")
deathLabel.Name = "DeathFeedback"
deathLabel.AnchorPoint = Vector2.new(0.5, 0.5)
deathLabel.Position = UDim2.fromScale(0.5, 0.72)
deathLabel.Size = UDim2.fromOffset(440, 38)
deathLabel.BackgroundTransparency = 1
deathLabel.Font = Enum.Font.GothamSemibold
deathLabel.Text = ""
deathLabel.TextColor3 = Color3.fromRGB(255, 215, 190)
deathLabel.TextSize = 21
deathLabel.TextStrokeTransparency = 0.35
deathLabel.TextTransparency = 1
deathLabel.ZIndex = 8
deathLabel.Parent = screenGui

local announcementSound = Instance.new("Sound")
announcementSound.Name = "AnnouncementSound"
announcementSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
announcementSound.Volume = 0.35
announcementSound.SoundGroup = GameAudio.UIGroup
announcementSound.Parent = screenGui

local rollPanel = Instance.new("Frame")
rollPanel.Name = "RollPanel"
rollPanel.AnchorPoint = Vector2.new(0, 1)
rollPanel.Position = UDim2.new(0, 32, 1, -26)
rollPanel.Size = UDim2.fromOffset(170, 44)
rollPanel.BackgroundColor3 = Color3.fromRGB(20, 22, 27)
rollPanel.BackgroundTransparency = 0.15
rollPanel.BorderSizePixel = 0
rollPanel.Parent = screenGui

local rollStroke = Instance.new("UIStroke")
rollStroke.Color = Color3.fromRGB(115, 122, 135)
rollStroke.Thickness = 1
rollStroke.Transparency = 0.2
rollStroke.Parent = rollPanel

local rollLabel = Instance.new("TextLabel")
rollLabel.Name = "Label"
rollLabel.Size = UDim2.new(1, 0, 1, -5)
rollLabel.BackgroundTransparency = 1
rollLabel.Font = Enum.Font.GothamBold
rollLabel.Text = "E  ROLL"
rollLabel.TextColor3 = Color3.new(1, 1, 1)
rollLabel.TextSize = 19
rollLabel.TextStrokeTransparency = 0.65
rollLabel.Parent = rollPanel

local cooldownTrack = Instance.new("Frame")
cooldownTrack.Name = "CooldownTrack"
cooldownTrack.AnchorPoint = Vector2.new(0, 1)
cooldownTrack.Position = UDim2.fromScale(0, 1)
cooldownTrack.Size = UDim2.new(1, 0, 0, 5)
cooldownTrack.BackgroundColor3 = Color3.fromRGB(48, 51, 58)
cooldownTrack.BorderSizePixel = 0
cooldownTrack.ClipsDescendants = true
cooldownTrack.Parent = rollPanel

local cooldownFill = Instance.new("Frame")
cooldownFill.Name = "Fill"
cooldownFill.Size = UDim2.fromScale(1, 1)
cooldownFill.BackgroundColor3 = Color3.fromRGB(87, 220, 134)
cooldownFill.BorderSizePixel = 0
cooldownFill.Parent = cooldownTrack

local function updateLobbyHud()
	local showCombatHud = GameState.IsArena(localPlayer)
	crosshair.Visible = showCombatHud
	hitMarker.Visible = showCombatHud
	killNotification.Visible = showCombatHud
	ammoLabel.Visible = showCombatHud
	streakLabel.Visible = showCombatHud
	killFeedController.SetVisible(showCombatHud)
	rollPanel.Visible = showCombatHud
end

local markerGeneration = 0
local notificationGeneration = 0
local announcementGeneration = 0
local deathGeneration = 0
local wantedBillboards: {[Player]: BillboardGui} = {}

local function updateHudState()
	updateLobbyHud()
	if not GameState.IsArena(localPlayer) then
		markerGeneration += 1
		notificationGeneration += 1
		hitMarker.TextTransparency = 1
		killNotification.TextTransparency = 1
		killFeedController.Clear()
	end
end

local function updateAmmo()
	local ammo = localPlayer:GetAttribute(AMMO_ATTRIBUTE)
	if typeof(ammo) == "number" then
		ammoLabel.Text = string.format("%d / %d", ammo, WeaponConfig.AmmoCapacity)
	else
		ammoLabel.Text = string.format("-- / %d", WeaponConfig.AmmoCapacity)
	end
end

local function updateKillStreak(overrideValue: number?)
	local streak = overrideValue
	if streak == nil then
		local attribute = localPlayer:GetAttribute(KILL_STREAK_ATTRIBUTE)
		streak = if typeof(attribute) == "number" then attribute else 0
	end

	streakLabel.Text = string.format("STREAK  x%d", math.max(0, math.floor(streak)))
end

local function showMarker(markerType: string)
	if not GameState.IsArena(localPlayer) or not SettingsStore.GetBoolean("HitmarkerEnabled") then
		return
	end
	markerGeneration += 1
	local generation = markerGeneration
	local isKill = markerType == "Kill"

	hitMarker.Text = if isKill then "✕" else "×"
	hitMarker.TextColor3 = if isKill then Color3.fromRGB(255, 103, 72) else Color3.new(1, 1, 1)
	hitMarker.TextSize = if isKill then 40 else 30
	hitMarker.TextTransparency = 0
	hitMarker.TextStrokeTransparency = if isKill then 0.15 else 0.35

	task.delay(if isKill then 0.28 else 0.12, function()
		if markerGeneration ~= generation then
			return
		end

		TweenService:Create(hitMarker, TweenInfo.new(0.1), {TextTransparency = 1}):Play()
	end)
end

local function showAnnouncement(text: string, isStreakEnded: boolean)
	announcementGeneration += 1
	local generation = announcementGeneration
	announcementLabel.Text = text
	announcementLabel.TextColor3 = if isStreakEnded
		then Color3.fromRGB(255, 132, 92)
		else Color3.fromRGB(255, 202, 92)
	announcementLabel.TextTransparency = 0
	announcementLabel.BackgroundTransparency = 0.28
	announcementSound:Play()

	task.delay(2.1, function()
		if announcementGeneration ~= generation then
			return
		end

		TweenService:Create(announcementLabel, TweenInfo.new(0.3), {
			TextTransparency = 1,
			BackgroundTransparency = 1,
		}):Play()
	end)
end

local function showDeathFeedback(killerName: string)
	deathGeneration += 1
	local generation = deathGeneration
	deathLabel.Text = if killerName ~= "" then string.format("Eliminated by %s", killerName) else "Eliminated"
	deathLabel.TextTransparency = 0
	deathFlash.BackgroundTransparency = 0.88
	TweenService:Create(deathFlash, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()

	task.delay(1.05, function()
		if deathGeneration ~= generation then
			return
		end

		TweenService:Create(deathLabel, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
	end)
end

local function refreshWantedBillboard(player: Player)
	local existing = wantedBillboards[player]
	local character = player.Character
	local head = if character then character:FindFirstChild("Head") else nil
	local shouldShow = GameState.IsArena(player)
		and player:GetAttribute(WANTED_ATTRIBUTE) == true and head and head:IsA("BasePart")

	if existing and (not shouldShow or existing.Adornee ~= head) then
		existing:Destroy()
		wantedBillboards[player] = nil
		existing = nil
	end

	if not shouldShow or existing then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "WantedMarker"
	billboard.Adornee = head :: BasePart
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 120
	billboard.Size = UDim2.fromOffset(110, 28)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
	billboard.Parent = screenGui

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(62, 25, 15)
	label.BackgroundTransparency = 0.18
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBold
	label.Text = "WANTED"
	label.TextColor3 = Color3.fromRGB(255, 192, 74)
	label.TextSize = 15
	label.TextStrokeTransparency = 0.45
	label.Parent = billboard

	wantedBillboards[player] = billboard
end

local function trackWantedPlayer(player: Player)
	player:GetAttributeChangedSignal(WANTED_ATTRIBUTE):Connect(function()
		refreshWantedBillboard(player)
	end)
	player:GetAttributeChangedSignal(GameState.Attribute):Connect(function()
		refreshWantedBillboard(player)
	end)
	player.CharacterAdded:Connect(function(character)
		task.spawn(function()
			character:WaitForChild("Head", 8)
			refreshWantedBillboard(player)
		end)
	end)
	refreshWantedBillboard(player)
end

local function showKillNotification(targetName: string)
	notificationGeneration += 1
	local generation = notificationGeneration
	killNotification.Text = string.format("Eliminated %s", targetName)
	killNotification.TextTransparency = 0

	task.delay(1.1, function()
		if notificationGeneration ~= generation then
			return
		end

		TweenService:Create(killNotification, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
	end)
end

combatFeedback.OnClientEvent:Connect(function(feedbackType: any, valueA: any, valueB: any, valueC: any)
	if feedbackType == "Hit" then
		showMarker("Hit")
	elseif feedbackType == "Kill" then
		showMarker("Kill")
		showKillNotification(if typeof(valueA) == "string" then valueA else "Player")
		if typeof(valueB) == "number" then
			updateKillStreak(valueB)
		end
	elseif feedbackType == "Milestone" then
		if not GameState.IsArena(localPlayer) then
			return
		end
		local playerName = if typeof(valueA) == "string" then valueA else "Player"
		local milestone = if typeof(valueB) == "string" then valueB else "HOT"
		local streak = if typeof(valueC) == "number" then math.floor(valueC) else 0
		showAnnouncement(string.format("%s — %s  x%d", playerName, milestone, streak), false)
	elseif feedbackType == "StreakEnded" then
		if not GameState.IsArena(localPlayer) then
			return
		end
		local killerName = if typeof(valueA) == "string" then valueA else "Player"
		local wantedName = if typeof(valueB) == "string" then valueB else "Player"
		showAnnouncement(string.format("%s ended %s's streak!", killerName, wantedName), true)
	elseif feedbackType == "Death" then
		showDeathFeedback(if typeof(valueA) == "string" then valueA else "")
	end
end)

Players.PlayerAdded:Connect(trackWantedPlayer)
Players.PlayerRemoving:Connect(function(player)
	local billboard = wantedBillboards[player]
	if billboard then
		billboard:Destroy()
		wantedBillboards[player] = nil
	end
end)

for _, player in Players:GetPlayers() do
	trackWantedPlayer(player)
end

localPlayer:GetAttributeChangedSignal(AMMO_ATTRIBUTE):Connect(updateAmmo)
localPlayer:GetAttributeChangedSignal(GameState.Attribute):Connect(updateHudState)
localPlayer:GetAttributeChangedSignal(KILL_STREAK_ATTRIBUTE):Connect(function()
	updateKillStreak()
end)
SettingsStore.Changed:Connect(function(key)
	if key == "HitmarkerEnabled" and not SettingsStore.GetBoolean("HitmarkerEnabled") then
		markerGeneration += 1
		hitMarker.TextTransparency = 1
	end
end)

RunService.RenderStepped:Connect(function()
	local rolling = localPlayer:GetAttribute(ROLLING_ATTRIBUTE) == true
	local readyAt = localPlayer:GetAttribute(ROLL_READY_AT_ATTRIBUTE)
	local remaining = if typeof(readyAt) == "number"
		then math.max(0, readyAt - Workspace:GetServerTimeNow())
		else 0

	if rolling then
		rollLabel.Text = "E  ROLLING"
		rollLabel.TextColor3 = Color3.fromRGB(255, 202, 92)
		cooldownFill.BackgroundColor3 = Color3.fromRGB(255, 160, 72)
		cooldownFill.Size = UDim2.fromScale(1, 1)
	elseif remaining > 0 then
		local progress = 1 - math.clamp(remaining / WeaponConfig.RollCooldown, 0, 1)
		rollLabel.Text = string.format("E  ROLL  %.1f", remaining)
		rollLabel.TextColor3 = Color3.fromRGB(175, 180, 190)
		cooldownFill.BackgroundColor3 = Color3.fromRGB(103, 112, 128)
		cooldownFill.Size = UDim2.fromScale(progress, 1)
	else
		rollLabel.Text = "E  ROLL"
		rollLabel.TextColor3 = Color3.new(1, 1, 1)
		cooldownFill.BackgroundColor3 = Color3.fromRGB(87, 220, 134)
		cooldownFill.Size = UDim2.fromScale(1, 1)
	end
end)

updateAmmo()
updateHudState()
updateKillStreak()
