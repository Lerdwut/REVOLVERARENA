--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(sharedFolder:WaitForChild("Constants"))

local KILLER_USER_ID_ATTRIBUTE = Constants.Attributes.KillerUserId
local DEATH_PROCESSED_ATTRIBUTE = Constants.Attributes.DeathProcessed
local KILL_STREAK_ATTRIBUTE = Constants.Attributes.KillStreak
local WANTED_ATTRIBUTE = Constants.Attributes.Wanted

local STREAK_MILESTONES: {[number]: string} = {
	[3] = "HOT",
	[5] = "GUNSLINGER",
	[10] = "WANTED",
	[15] = "OUTLAW",
	[20] = "LEGENDARY",
}

local remotesFolder = ReplicatedStorage:WaitForChild(Constants.Remotes.Folder)
local combatFeedback = remotesFolder:WaitForChild(Constants.Remotes.CombatFeedback) :: RemoteEvent
local killFeed = remotesFolder:WaitForChild(Constants.Remotes.KillFeed) :: RemoteEvent

local initializedPlayers: {[Player]: boolean} = {}
local trackedHumanoids: {[Humanoid]: boolean} = {}
local processedDeaths: {[Humanoid]: boolean} = {}

local function getHumanoid(character: Model): Humanoid?
	local candidate = character:FindFirstChildOfClass("Humanoid")
	if candidate and candidate:IsA("Humanoid") then
		return candidate
	end

	return nil
end

local function getOrCreateIntValue(parent: Instance, name: string): IntValue
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("IntValue") then
		return existing
	end

	local value = Instance.new("IntValue")
	value.Name = name
	value.Value = 0
	value.Parent = parent
	return value
end

local function createLeaderstats(player: Player): Folder
	local existing = player:FindFirstChild("leaderstats")
	local leaderstats: Folder

	if existing and existing:IsA("Folder") then
		leaderstats = existing
	else
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	getOrCreateIntValue(leaderstats, "Kills")
	getOrCreateIntValue(leaderstats, "Deaths")

	return leaderstats
end

local function incrementStat(player: Player, statName: string)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats or not leaderstats:IsA("Folder") then
		return
	end

	local stat = leaderstats:FindFirstChild(statName)
	if stat and stat:IsA("IntValue") then
		stat.Value += 1
	end
end

local function setKillStreak(player: Player, value: number)
	local streak = math.max(0, math.floor(value))
	player:SetAttribute(KILL_STREAK_ATTRIBUTE, streak)
	player:SetAttribute(WANTED_ATTRIBUTE, streak >= 10)
end

local function incrementKillStreak(player: Player): number
	local current = player:GetAttribute(KILL_STREAK_ATTRIBUTE)
	local nextStreak = if typeof(current) == "number" then current + 1 else 1
	setKillStreak(player, nextStreak)
	return nextStreak
end

local function recordDeath(victim: Player, humanoid: Humanoid)
	if processedDeaths[humanoid] or humanoid:GetAttribute(DEATH_PROCESSED_ATTRIBUTE) == true then
		return
	end

	processedDeaths[humanoid] = true
	humanoid:SetAttribute(DEATH_PROCESSED_ATTRIBUTE, true)
	incrementStat(victim, "Deaths")

	local victimStreakAttribute = victim:GetAttribute(KILL_STREAK_ATTRIBUTE)
	local victimStreak = if typeof(victimStreakAttribute) == "number"
		then math.max(0, math.floor(victimStreakAttribute))
		else 0
	setKillStreak(victim, 0)

	local killerUserId = humanoid:GetAttribute(KILLER_USER_ID_ATTRIBUTE)
	if typeof(killerUserId) ~= "number" then
		combatFeedback:FireClient(victim, "Death", "")
		return
	end

	local killer = Players:GetPlayerByUserId(killerUserId)
	if killer and killer ~= victim then
		incrementStat(killer, "Kills")
		local killStreak = incrementKillStreak(killer)
		combatFeedback:FireClient(killer, "Kill", victim.DisplayName, killStreak)
		combatFeedback:FireClient(victim, "Death", killer.DisplayName)
		killFeed:FireAllClients(killer.DisplayName, victim.DisplayName)

		local milestone = STREAK_MILESTONES[killStreak]
		if milestone then
			combatFeedback:FireAllClients("Milestone", killer.DisplayName, milestone, killStreak)
		end

		if victimStreak >= 10 then
			combatFeedback:FireAllClients(
				"StreakEnded",
				killer.DisplayName,
				victim.DisplayName,
				victimStreak
			)
		end
	else
		combatFeedback:FireClient(victim, "Death", "")
	end
end

local function trackCharacter(player: Player, character: Model)
	setKillStreak(player, 0)

	local humanoid = getHumanoid(character)
	if not humanoid then
		local candidate = character:WaitForChild("Humanoid", 10)
		if candidate and candidate:IsA("Humanoid") then
			humanoid = candidate
		end
	end

	if not humanoid or trackedHumanoids[humanoid] then
		return
	end

	trackedHumanoids[humanoid] = true
	humanoid.Destroying:Connect(function()
		trackedHumanoids[humanoid] = nil
		processedDeaths[humanoid] = nil
	end)
	humanoid.Died:Connect(function()
		recordDeath(player, humanoid)
	end)

	if humanoid.Health <= 0 then
		recordDeath(player, humanoid)
	end
end

local function initializePlayer(player: Player)
	if initializedPlayers[player] then
		return
	end

	initializedPlayers[player] = true
	createLeaderstats(player)
	setKillStreak(player, 0)

	player.CharacterAdded:Connect(function(character)
		trackCharacter(player, character)
	end)

	if player.Character then
		trackCharacter(player, player.Character)
	end
end

Players.PlayerAdded:Connect(initializePlayer)
Players.PlayerRemoving:Connect(function(player)
	initializedPlayers[player] = nil
end)

for _, player in Players:GetPlayers() do
	initializePlayer(player)
end
