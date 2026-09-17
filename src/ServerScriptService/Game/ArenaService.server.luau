--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local configFolder = ReplicatedStorage:WaitForChild("Config")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(configFolder:WaitForChild("GameConfig"))
local Constants = require(sharedFolder:WaitForChild("Constants"))
local GameState = require(sharedFolder:WaitForChild("GameState"))

local ARENA_NAME = Constants.Instances.Arena
local LOBBY_NAME = Constants.Instances.Lobby
local LOBBY_ENTRY_NAME = "ArenaEntrance"
local LOBBY_SPAWN_PREFIX = "LobbySpawn"
local SPAWN_PROTECTION_NAME = Constants.Instances.SpawnProtection
local LOBBY_PROTECTION_NAME = Constants.Instances.LobbyProtection

type EnemyInfo = {
	character: Model,
	rootPart: BasePart,
}

local initializedPlayers: {[Player]: boolean} = {}
local trackedLobbyCharacters: {[Model]: boolean} = {}
local lastSpawnUse: {[BasePart]: number} = {}
local lobbyEntryDebounce: {[Player]: boolean} = {}
local random = Random.new()

Players.RespawnTime = GameConfig.RespawnDelay

local function getCombatMarkers(): {BasePart}
	local arena = Workspace:FindFirstChild(ARENA_NAME)
	if not arena then
		return {}
	end
	local spawns = arena:FindFirstChild("Spawns")
	if not spawns then
		return {}
	end

	local markers: {BasePart} = {}
	for _, descendant in spawns:GetChildren() do
		if descendant:IsA("BasePart") and string.sub(descendant.Name, 1, 5) == "Spawn" then
			table.insert(markers, descendant)
		end
	end

	return markers
end

local function getLobbySpawnMarkers(): {SpawnLocation}
	local arena = Workspace:FindFirstChild(ARENA_NAME)
	local lobby = if arena then arena:FindFirstChild(LOBBY_NAME) else nil
	if not lobby then
		return {}
	end

	local markers: {SpawnLocation} = {}
	for _, descendant in lobby:GetDescendants() do
		if descendant:IsA("SpawnLocation") and string.sub(descendant.Name, 1, #LOBBY_SPAWN_PREFIX) == LOBBY_SPAWN_PREFIX then
			table.insert(markers, descendant)
		end
	end
	table.sort(markers, function(a, b)
		return a.Name < b.Name
	end)
	return markers
end

local function getEnemies(player: Player): {EnemyInfo}
	local enemies: {EnemyInfo} = {}
	for _, otherPlayer in Players:GetPlayers() do
		if otherPlayer ~= player and GameState.IsArena(otherPlayer) then
			local character = otherPlayer.Character
			if character then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				local rootPart = character:FindFirstChild("HumanoidRootPart")
				if humanoid and humanoid.Health > 0 and rootPart and rootPart:IsA("BasePart") then
					table.insert(enemies, {character = character, rootPart = rootPart})
				end
			end
		end
	end

	return enemies
end

local function hasLineOfSight(
	spawnLocation: BasePart,
	enemy: EnemyInfo,
	excludedCharacter: Model?
): boolean
	local origin = spawnLocation.Position + Vector3.new(0, 3, 0)
	local target = enemy.rootPart.Position + Vector3.new(0, 1, 0)
	local direction = target - origin
	if direction.Magnitude <= 0.1 then
		return true
	end

	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Exclude
	local excludedInstances: {Instance} = {spawnLocation}
	if excludedCharacter then
		table.insert(excludedInstances, excludedCharacter)
	end
	parameters.FilterDescendantsInstances = excludedInstances
	parameters.IgnoreWater = true

	local result = Workspace:Raycast(origin, direction, parameters)
	return result == nil or result.Instance:IsDescendantOf(enemy.character)
end

local function scoreSpawn(
	spawnLocation: BasePart,
	enemies: {EnemyInfo},
	now: number,
	excludedCharacter: Model?
): number
	local score = random:NextNumber(-1.5, 1.5)
	local minimumDistance = math.huge
	local visibleEnemies = 0

	for _, enemy in enemies do
		local distance = (enemy.rootPart.Position - spawnLocation.Position).Magnitude
		minimumDistance = math.min(minimumDistance, distance)
		if hasLineOfSight(spawnLocation, enemy, excludedCharacter) then
			visibleEnemies += 1
		end
	end

	if minimumDistance < math.huge then
		score += math.min(minimumDistance, 90)
		if minimumDistance < GameConfig.MinimumSafeSpawnDistance then
			score -= 180
		elseif minimumDistance < GameConfig.PreferredSafeSpawnDistance then
			score -= 55
		end
	end

	score -= visibleEnemies * 24

	local previousUse = lastSpawnUse[spawnLocation]
	if previousUse then
		local elapsed = now - previousUse
		if elapsed < GameConfig.SpawnReuseWindow then
			score -= (GameConfig.SpawnReuseWindow - elapsed) * 18
		end
	end

	return score
end

local function chooseSpawn(player: Player): BasePart?
	local spawnLocations = getCombatMarkers()
	if #spawnLocations == 0 then
		return nil
	end

	local enemies = getEnemies(player)
	local now = os.clock()
	local bestSpawn = spawnLocations[1]
	local bestScore = -math.huge

	for _, spawnLocation in spawnLocations do
		local score = scoreSpawn(spawnLocation, enemies, now, player.Character)
		if score > bestScore then
			bestScore = score
			bestSpawn = spawnLocation
		end
	end

	lastSpawnUse[bestSpawn] = now
	return bestSpawn
end

local function protectCharacter(character: Model)
	local lobbyProtection = character:FindFirstChild(LOBBY_PROTECTION_NAME)
	if lobbyProtection and lobbyProtection:IsA("ForceField") then
		lobbyProtection:Destroy()
	end

	local existing = character:FindFirstChild(SPAWN_PROTECTION_NAME)
	if existing and existing:IsA("ForceField") then
		existing:Destroy()
	end

	local forceField = Instance.new("ForceField")
	forceField.Name = SPAWN_PROTECTION_NAME
	forceField.Visible = true
	forceField.Parent = character

	task.delay(GameConfig.SpawnProtectionDuration, function()
		if forceField.Parent == character then
			forceField:Destroy()
		end
	end)
end

local function protectLobbyCharacter(character: Model)
	local spawnProtection = character:FindFirstChild(SPAWN_PROTECTION_NAME)
	if spawnProtection and spawnProtection:IsA("ForceField") then
		spawnProtection:Destroy()
	end

	local existing = character:FindFirstChild(LOBBY_PROTECTION_NAME)
	if existing and existing:IsA("ForceField") then
		return
	end

	local forceField = Instance.new("ForceField")
	forceField.Name = LOBBY_PROTECTION_NAME
	forceField.Visible = false
	forceField.Parent = character
end

local function placeCharacter(player: Player, character: Model): boolean
	local rootPart = character:WaitForChild("HumanoidRootPart", 5)
	if not rootPart or not rootPart:IsA("BasePart") or player.Character ~= character then
		return false
	end

	local spawnLocation = chooseSpawn(player)
	if not spawnLocation then
		return false
	end

	protectCharacter(character)
	character:PivotTo(spawnLocation.CFrame * CFrame.new(0, 4, 0))
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
	return true
end

local function placeLobbyCharacter(player: Player, character: Model)
	if player.Character ~= character or trackedLobbyCharacters[character] then
		return
	end
	trackedLobbyCharacters[character] = true
	character.Destroying:Connect(function()
		trackedLobbyCharacters[character] = nil
	end)
	player:SetAttribute(GameState.Attribute, GameState.Lobby)
	player.RespawnLocation = nil
	protectLobbyCharacter(character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid:UnequipTools()
		humanoid.Died:Connect(function()
			if player.Character == character then
				player:SetAttribute(GameState.Attribute, GameState.Dead)
			end
		end)
		if humanoid.Health <= 0 then
			player:SetAttribute(GameState.Attribute, GameState.Dead)
		end
	end

	local rootPart = character:WaitForChild("HumanoidRootPart", 5)
	if not rootPart or not rootPart:IsA("BasePart") or player.Character ~= character then
		return
	end

	local markers = getLobbySpawnMarkers()
	if #markers == 0 then
		warn("Arena.Lobby has no LobbySpawn locations")
		return
	end

	local markerIndex = (math.abs(player.UserId) % #markers) + 1
	local marker = markers[markerIndex]
	player.RespawnLocation = marker
	character:PivotTo(marker.CFrame * CFrame.new(0, 4, 0))
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
end

local function enterArena(player: Player, entryPedestal: BasePart)
	if lobbyEntryDebounce[player] or player:GetAttribute(GameState.Attribute) ~= GameState.Lobby then
		return
	end

	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not rootPart or not rootPart:IsA("BasePart") then
		return
	end
	if (rootPart.Position - entryPedestal.Position).Magnitude > GameConfig.EntryInteractionDistance then
		return
	end
	if math.abs(rootPart.Position.X) > 27 or rootPart.Position.Z < -81
		or rootPart.Position.Z > -50.5 or rootPart.Position.Y > 50 then
		return
	end
	if #getCombatMarkers() == 0 then
		warn("Arena.Spawns has no combat markers")
		return
	end

	lobbyEntryDebounce[player] = true
	player:SetAttribute(GameState.Attribute, GameState.EnteringArena)
	humanoid:UnequipTools()
	task.delay(GameConfig.EntryTransitionDuration, function()
		if player.Parent ~= Players or player.Character ~= character
			or player:GetAttribute(GameState.Attribute) ~= GameState.EnteringArena
			or humanoid.Health <= 0 then
			lobbyEntryDebounce[player] = nil
			return
		end
		if placeCharacter(player, character) then
			player:SetAttribute(GameState.Attribute, GameState.Arena)
		else
			player:SetAttribute(GameState.Attribute, GameState.Lobby)
		end
		lobbyEntryDebounce[player] = nil
	end)
end

local function initializePlayer(player: Player)
	if initializedPlayers[player] then
		return
	end

	initializedPlayers[player] = true
	player:SetAttribute(GameState.Attribute, GameState.Lobby)

	player.CharacterAdded:Connect(function(character)
		task.defer(placeLobbyCharacter, player, character)
	end)

	if player.Character then
		task.defer(placeLobbyCharacter, player, player.Character)
	end
end

task.spawn(function()
	local arena = Workspace:WaitForChild(ARENA_NAME)
	local lobby = arena:WaitForChild(LOBBY_NAME)
	local entry = lobby:WaitForChild(LOBBY_ENTRY_NAME)
	local pedestal = entry:WaitForChild("EntryPedestal")
	local prompt = pedestal:WaitForChild("EnterPrompt")
	if not pedestal:IsA("BasePart") or not prompt:IsA("ProximityPrompt") then
		warn("Arena.Lobby.ArenaEntrance needs EntryPedestal and EnterPrompt")
		return
	end

	prompt.Triggered:Connect(function(player: Player)
		enterArena(player, pedestal)
	end)
end)

Players.PlayerAdded:Connect(initializePlayer)
Players.PlayerRemoving:Connect(function(player)
	initializedPlayers[player] = nil
	lobbyEntryDebounce[player] = nil
end)

for _, player in Players:GetPlayers() do
	initializePlayer(player)
end
