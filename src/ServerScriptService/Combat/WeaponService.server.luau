--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local configFolder = ReplicatedStorage:WaitForChild("Config")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local WeaponConfig = require(configFolder:WaitForChild("WeaponConfig"))
local Constants = require(sharedFolder:WaitForChild("Constants"))
local GameState = require(sharedFolder:WaitForChild("GameState"))
local HitService = require(script.Parent:WaitForChild("HitService"))
local ReloadService = require(script.Parent:WaitForChild("ReloadService"))

local REMOTES_FOLDER_NAME = Constants.Remotes.Folder
local FIRE_REMOTE_NAME = Constants.Remotes.Fire
local RELOAD_REMOTE_NAME = Constants.Remotes.Reload
local ROLL_REMOTE_NAME = Constants.Remotes.RequestRoll
local EFFECTS_REMOTE_NAME = Constants.Remotes.WeaponEffects
local FEEDBACK_REMOTE_NAME = Constants.Remotes.CombatFeedback
local KILL_FEED_REMOTE_NAME = Constants.Remotes.KillFeed
local REVOLVER_NAME = Constants.Instances.Revolver
local SPAWN_PROTECTION_NAME = Constants.Instances.SpawnProtection
local ROLLING_ATTRIBUTE = Constants.Attributes.Rolling
local ROLL_READY_AT_ATTRIBUTE = Constants.Attributes.RollReadyAt

local EMPTY_CLICK_INTERVAL = 0.2

local initializedPlayers: {[Player]: boolean} = {}
local lastShotAt: {[Player]: number} = {}
local lastEmptyAt: {[Player]: number} = {}
local lastRollAt: {[Player]: number} = {}
local rollTokens: {[Player]: number} = {}
local activeRollCleanup: {[Player]: () -> ()} = {}

local function getOrCreateRemotesFolder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER_NAME)
	if existing then
		if existing:IsA("Folder") then
			return existing
		end

		error(string.format("ReplicatedStorage.%s must be a Folder", REMOTES_FOLDER_NAME))
	end

	local folder = Instance.new("Folder")
	folder.Name = REMOTES_FOLDER_NAME
	folder.Parent = ReplicatedStorage
	return folder
end

local function getOrCreateRemoteEvent(parent: Instance, name: string): RemoteEvent
	local existing = parent:FindFirstChild(name)
	if existing then
		if existing:IsA("RemoteEvent") then
			return existing
		end

		error(string.format("%s.%s must be a RemoteEvent", parent:GetFullName(), name))
	end

	local remoteEvent = Instance.new("RemoteEvent")
	remoteEvent.Name = name
	remoteEvent.Parent = parent
	return remoteEvent
end

local remotesFolder = getOrCreateRemotesFolder()
local fireRevolver = getOrCreateRemoteEvent(remotesFolder, FIRE_REMOTE_NAME)
local reloadRevolver = getOrCreateRemoteEvent(remotesFolder, RELOAD_REMOTE_NAME)
local requestCombatRoll = getOrCreateRemoteEvent(remotesFolder, ROLL_REMOTE_NAME)
local weaponEffects = getOrCreateRemoteEvent(remotesFolder, EFFECTS_REMOTE_NAME)
local combatFeedback = getOrCreateRemoteEvent(remotesFolder, FEEDBACK_REMOTE_NAME)
getOrCreateRemoteEvent(remotesFolder, KILL_FEED_REMOTE_NAME)

local function getHumanoid(character: Model): Humanoid?
	local candidate = character:FindFirstChildOfClass("Humanoid")
	if candidate and candidate:IsA("Humanoid") then
		return candidate
	end

	return nil
end

local function getAliveCharacter(player: Player): (Model?, Humanoid?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil, nil
	end

	local humanoid = getHumanoid(character)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not rootPart or not rootPart:IsA("BasePart") then
		return nil, nil, nil
	end

	return character, humanoid, rootPart
end

local function getEquippedRevolver(character: Model): Tool?
	local revolver = character:FindFirstChild(REVOLVER_NAME)
	if revolver and revolver:IsA("Tool") then
		return revolver
	end

	return nil
end

local function isRolling(player: Player): boolean
	return player:GetAttribute(ROLLING_ATTRIBUTE) == true
end

local function setRolling(player: Player, rolling: boolean)
	player:SetAttribute(ROLLING_ATTRIBUTE, rolling)
end

local function cancelRoll(player: Player)
	rollTokens[player] = (rollTokens[player] or 0) + 1

	local cleanup = activeRollCleanup[player]
	activeRollCleanup[player] = nil
	if cleanup then
		cleanup()
	end

	setRolling(player, false)
end

local function removeSpawnProtection(character: Model)
	local forceField = character:FindFirstChild(SPAWN_PROTECTION_NAME)
	if forceField and forceField:IsA("ForceField") then
		forceField:Destroy()
	end
end

local function updateWeaponAvailability(player: Player)
	local inArena = GameState.IsArena(player)
	local character = player.Character
	local backpack = player:FindFirstChildOfClass("Backpack")
	local humanoid = if character then getHumanoid(character) else nil
	local function setToolEnabled(container: Instance?)
		if container then
			local tool = container:FindFirstChild(REVOLVER_NAME)
			if tool and tool:IsA("Tool") then
				tool.Enabled = inArena
			end
		end
	end
	setToolEnabled(backpack)
	setToolEnabled(character)
	if humanoid and humanoid.Health > 0 then
		if inArena and backpack then
			local tool = backpack:FindFirstChild(REVOLVER_NAME)
			if tool and tool:IsA("Tool") then
				humanoid:EquipTool(tool)
			end
		elseif not inArena then
			humanoid:UnequipTools()
		end
	end
end

local function setupCharacter(player: Player, character: Model)
	ReloadService.Cancel(player)
	cancelRoll(player)
	ReloadService.SetAmmo(player, WeaponConfig.AmmoCapacity)
	lastShotAt[player] = nil
	lastEmptyAt[player] = nil
	lastRollAt[player] = nil
	player:SetAttribute(ROLL_READY_AT_ATTRIBUTE, 0)

	local humanoid = getHumanoid(character)
	if humanoid then
		humanoid.Died:Connect(function()
			if player.Character == character then
				ReloadService.Cancel(player)
				cancelRoll(player)
			end
		end)
	end

	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child.Name == REVOLVER_NAME then
			task.defer(updateWeaponAvailability, player)
		end
	end)
	task.defer(updateWeaponAvailability, player)
end

local function initializePlayer(player: Player)
	if initializedPlayers[player] then
		return
	end

	initializedPlayers[player] = true
	ReloadService.Initialize(player)
	setRolling(player, false)
	player:SetAttribute(ROLL_READY_AT_ATTRIBUTE, 0)
	player:GetAttributeChangedSignal(GameState.Attribute):Connect(function()
		if GameState.IsArena(player) then
			ReloadService.SetAmmo(player, WeaponConfig.AmmoCapacity)
			lastShotAt[player] = nil
		else
			ReloadService.Cancel(player)
			cancelRoll(player)
		end
		updateWeaponAvailability(player)
	end)
	task.spawn(function()
		local backpack = player:WaitForChild("Backpack", 5)
		if backpack and backpack:IsA("Backpack") then
			backpack.ChildAdded:Connect(function(child)
				if child:IsA("Tool") and child.Name == REVOLVER_NAME then
					task.defer(updateWeaponAvailability, player)
				end
			end)
			updateWeaponAvailability(player)
		end
	end)

	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
	end)

	if player.Character then
		setupCharacter(player, player.Character)
	end
end

fireRevolver.OnServerEvent:Connect(function(player: Player, origin: any, direction: any)
	local character, humanoid, rootPart = getAliveCharacter(player)
	if not character or not humanoid or not rootPart then
		return
	end
	if not GameState.IsArena(player) then
		return
	end
	if not HitService.IsInsideCombatArena(rootPart.Position) then
		return
	end

	local revolver = getEquippedRevolver(character)
	if not revolver or isRolling(player) or ReloadService.IsReloading(player) then
		return
	end

	if not HitService.IsValidRay(rootPart, origin, direction) then
		return
	end

	if ReloadService.GetAmmo(player) <= 0 then
		local now = os.clock()
		local previousEmpty = lastEmptyAt[player]
		if not previousEmpty or now - previousEmpty >= EMPTY_CLICK_INTERVAL then
			lastEmptyAt[player] = now
			weaponEffects:FireClient(player, "Empty", player)
		end
		return
	end

	local now = os.clock()
	local previousShot = lastShotAt[player]
	if previousShot and now - previousShot < WeaponConfig.FireCooldown then
		return
	end

	lastShotAt[player] = now
	ReloadService.SetAmmo(player, ReloadService.GetAmmo(player) - 1)
	removeSpawnProtection(character)

	local result, hitPosition = HitService.Cast(character, origin, direction)
	local muzzlePosition = HitService.GetMuzzlePosition(revolver, origin)
	weaponEffects:FireAllClients("Shot", player, muzzlePosition, hitPosition)

	if result then
		HitService.ApplyHit(player, result, combatFeedback)
	end
end)

reloadRevolver.OnServerEvent:Connect(function(player: Player)
	if not GameState.IsArena(player) then
		return
	end
	local character, humanoid = getAliveCharacter(player)
	if not character or not humanoid or not getEquippedRevolver(character) then
		return
	end

	if isRolling(player) or ReloadService.IsReloading(player)
		or ReloadService.GetAmmo(player) >= WeaponConfig.AmmoCapacity then
		return
	end

	ReloadService.Start(player, character, weaponEffects, function(): boolean
		local currentCharacter, currentHumanoid = getAliveCharacter(player)
		if not currentCharacter or not currentHumanoid then
			return false
		end
		return not isRolling(player) and getEquippedRevolver(currentCharacter) ~= nil
	end)
end)

requestCombatRoll.OnServerEvent:Connect(function(player: Player)
	local character, humanoid, rootPart = getAliveCharacter(player)
	if not character or not humanoid or not rootPart then
		return
	end
	if not GameState.IsArena(player) then
		return
	end
	if not HitService.IsInsideCombatArena(rootPart.Position) then
		return
	end

	if isRolling(player) or humanoid.Sit or humanoid.PlatformStand then
		return
	end

	local now = os.clock()
	local previousRoll = lastRollAt[player]
	if previousRoll and now - previousRoll < WeaponConfig.RollCooldown then
		return
	end

	local rollDirection = Vector3.new(humanoid.MoveDirection.X, 0, humanoid.MoveDirection.Z)
	if rollDirection.Magnitude < 0.1 then
		local horizontalVelocity = Vector3.new(
			rootPart.AssemblyLinearVelocity.X,
			0,
			rootPart.AssemblyLinearVelocity.Z
		)
		if horizontalVelocity.Magnitude >= 2 then
			rollDirection = horizontalVelocity.Unit
		end
	end

	if rollDirection.Magnitude < 0.1 then
		local lookVector = rootPart.CFrame.LookVector
		rollDirection = Vector3.new(lookVector.X, 0, lookVector.Z)
	end

	if rollDirection.Magnitude < 0.1 then
		return
	end

	rollDirection = rollDirection.Unit
	lastRollAt[player] = now
	player:SetAttribute(ROLL_READY_AT_ATTRIBUTE, Workspace:GetServerTimeNow() + WeaponConfig.RollCooldown)
	ReloadService.Cancel(player)
	setRolling(player, true)

	local rollToken = (rollTokens[player] or 0) + 1
	rollTokens[player] = rollToken

	local originalWalkSpeed = humanoid.WalkSpeed
	local originalAutoRotate = humanoid.AutoRotate
	local cleanedUp = false

	pcall(function()
		rootPart:SetNetworkOwner(nil)
	end)

	humanoid.WalkSpeed = 0
	humanoid.AutoRotate = false
	humanoid.Jump = false
	rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + rollDirection)

	local attachment = Instance.new("Attachment")
	attachment.Name = "CombatRollAttachment"
	attachment.Parent = rootPart

	local velocity = Instance.new("LinearVelocity")
	velocity.Name = "CombatRollVelocity"
	velocity.Attachment0 = attachment
	velocity.ForceLimitsEnabled = false
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	velocity.VectorVelocity = rollDirection * (WeaponConfig.RollDistance / WeaponConfig.RollDuration)
	velocity.MaxForce = 150_000
	velocity.Parent = rootPart

	local function cleanupRoll()
		if cleanedUp then
			return
		end
		cleanedUp = true

		velocity:Destroy()
		attachment:Destroy()

		if humanoid.Parent == character then
			humanoid.WalkSpeed = originalWalkSpeed
			humanoid.AutoRotate = originalAutoRotate
		end

		if rootPart.Parent == character then
			local currentVelocity = rootPart.AssemblyLinearVelocity
			rootPart.AssemblyLinearVelocity = Vector3.new(0, currentVelocity.Y, 0)
			pcall(function()
				rootPart:SetNetworkOwnershipAuto()
			end)
		end
	end

	activeRollCleanup[player] = cleanupRoll

	task.delay(WeaponConfig.RollDuration, function()
		if rollTokens[player] ~= rollToken then
			return
		end

		activeRollCleanup[player] = nil
		cleanupRoll()
		setRolling(player, false)

		if player.Parent ~= Players or player.Character ~= character then
			return
		end

		local currentCharacter, currentHumanoid = getAliveCharacter(player)
		if currentCharacter and currentHumanoid then
			ReloadService.SetAmmo(player, WeaponConfig.AmmoCapacity)
		end
	end)
end)

Players.PlayerAdded:Connect(initializePlayer)
Players.PlayerRemoving:Connect(function(player)
	cancelRoll(player)
	initializedPlayers[player] = nil
	lastShotAt[player] = nil
	lastEmptyAt[player] = nil
	lastRollAt[player] = nil
	rollTokens[player] = nil
	ReloadService.Cleanup(player)
end)

for _, player in Players:GetPlayers() do
	initializePlayer(player)
end
