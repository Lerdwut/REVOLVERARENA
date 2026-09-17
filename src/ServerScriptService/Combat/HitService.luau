--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local configFolder = ReplicatedStorage:WaitForChild("Config")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(configFolder:WaitForChild("GameConfig"))
local WeaponConfig = require(configFolder:WaitForChild("WeaponConfig"))
local Constants = require(sharedFolder:WaitForChild("Constants"))
local GameState = require(sharedFolder:WaitForChild("GameState"))

local MAX_ORIGIN_DISTANCE = 20
local MAX_ABSOLUTE_COORDINATE = 1_000_000
local MIN_DIRECTION_MAGNITUDE = 0.9
local MAX_DIRECTION_MAGNITUDE = 1.1

local HitService = {}

local function isFiniteNumber(value: number): boolean
	return value == value and math.abs(value) < math.huge and math.abs(value) <= MAX_ABSOLUTE_COORDINATE
end

local function isFiniteVector3(value: any): boolean
	if typeof(value) ~= "Vector3" then
		return false
	end

	return isFiniteNumber(value.X) and isFiniteNumber(value.Y) and isFiniteNumber(value.Z)
end

local function getHumanoid(character: Model): Humanoid?
	local candidate = character:FindFirstChildOfClass("Humanoid")
	if candidate and candidate:IsA("Humanoid") then
		return candidate
	end

	return nil
end

function HitService.IsInsideCombatArena(position: Vector3): boolean
	return math.abs(position.X) <= GameConfig.CombatArenaHalfWidth
		and math.abs(position.Z) <= GameConfig.CombatArenaHalfDepth
		and position.Y >= GameConfig.CombatArenaMinY
		and position.Y <= GameConfig.CombatArenaMaxY
end

function HitService.IsValidRay(rootPart: BasePart, origin: any, direction: any): boolean
	if not isFiniteVector3(origin) or not isFiniteVector3(direction) then
		return false
	end

	if (origin - rootPart.Position).Magnitude > MAX_ORIGIN_DISTANCE then
		return false
	end

	local directionMagnitude = direction.Magnitude
	return directionMagnitude >= MIN_DIRECTION_MAGNITUDE
		and directionMagnitude <= MAX_DIRECTION_MAGNITUDE
end

function HitService.GetMuzzlePosition(revolver: Tool, fallback: Vector3): Vector3
	local muzzle = revolver:FindFirstChild("Muzzle", true)
	if muzzle and muzzle:IsA("Attachment") then
		return muzzle.WorldPosition
	end

	local barrelTip = revolver:FindFirstChild("BarrelTip", true)
	if barrelTip and barrelTip:IsA("BasePart") then
		return barrelTip.Position
	end

	local handle = revolver:FindFirstChild("Handle")
	if handle and handle:IsA("BasePart") then
		return handle.Position
	end

	return fallback
end

function HitService.Cast(character: Model, origin: Vector3, direction: Vector3): (RaycastResult?, Vector3)
	local raycastParameters = RaycastParams.new()
	raycastParameters.FilterType = Enum.RaycastFilterType.Exclude
	local excludedInstances: {Instance} = {character}
	for _, otherPlayer in Players:GetPlayers() do
		if not GameState.IsArena(otherPlayer) and otherPlayer.Character then
			table.insert(excludedInstances, otherPlayer.Character)
		end
	end
	raycastParameters.FilterDescendantsInstances = excludedInstances
	raycastParameters.IgnoreWater = true

	local unitDirection = direction.Unit
	local result = Workspace:Raycast(origin, unitDirection * WeaponConfig.Range, raycastParameters)
	local hitPosition = if result then result.Position else origin + unitDirection * WeaponConfig.Range
	return result, hitPosition
end

function HitService.ApplyHit(shooter: Player, result: RaycastResult, combatFeedback: RemoteEvent): boolean
	local character = result.Instance:FindFirstAncestorOfClass("Model")
	if not character then
		return false
	end

	local hitPlayer = Players:GetPlayerFromCharacter(character)
	local hitHumanoid = getHumanoid(character)
	if not hitPlayer or not hitHumanoid or not GameState.IsArena(hitPlayer)
		or hitPlayer.Character ~= character then
		return false
	end

	if hitPlayer == shooter or hitHumanoid.Health <= 0
		or character:FindFirstChildOfClass("ForceField") ~= nil then
		return false
	end

	-- GameModeService consumes this server-written attribution when the humanoid dies.
	hitHumanoid:SetAttribute(Constants.Attributes.KillerUserId, shooter.UserId)
	combatFeedback:FireClient(shooter, "Hit", hitPlayer.DisplayName)
	hitHumanoid.Health = 0
	return true
end

return table.freeze(HitService)
