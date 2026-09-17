--!strict

local Constants = require(script.Parent:WaitForChild("Constants"))

local GameState = {
	Attribute = Constants.Attributes.GameState,
	Lobby = "Lobby",
	EnteringArena = "EnteringArena",
	Arena = "Arena",
	Dead = "Dead",
}

function GameState.IsArena(player: Player): boolean
	return player:GetAttribute(GameState.Attribute) == GameState.Arena
end

return table.freeze(GameState)
