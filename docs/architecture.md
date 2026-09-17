# RevolverArena architecture

RevolverArena uses a server-authoritative combat model with client-side presentation and prediction.

The core rule is:

> The client requests, the server validates, and the client presents.

## Runtime flow

### Client

```text
Player input
  -> Controllers/WeaponController
     -> RemoteEvent request
     -> Viewmodel/WeaponAnimation state
     -> Viewmodel/WeaponViewmodel geometry
     -> Viewmodel/WeaponEffects audio and VFX
  -> UI controllers observe attributes and feedback remotes
```

`WeaponController.client.luau` is the only owner of the weapon render-step connection. The viewmodel modules do not connect to `RenderStepped` themselves; they receive state from the controller and return or apply presentation data.

UI is currently created at runtime under `PlayerGui`. It remains code-built to preserve the existing visuals and lifecycle. No empty `StarterGui` hierarchy was added just to mirror a target diagram.

### Server

```text
RemoteEvent request
  -> Combat/WeaponService
     -> player, state, cadence, and equipped-tool checks
     -> Combat/HitService ray and target validation
     -> Combat/ReloadService authoritative ammo/reload state
  -> authoritative attributes and game state
  -> result/effect RemoteEvents
  -> client presentation
```

`WeaponService.server.luau` creates `ReplicatedStorage.RevolverRemotes` at runtime. The folder and event names are intentionally unchanged:

- `FireRevolver`
- `ReloadRevolver`
- `RequestCombatRoll`
- `WeaponEffects`
- `CombatFeedback`
- `KillFeed`

`GameModeService.server.luau` owns kills, deaths, streaks, wanted state, and kill-feed publication. `ArenaService.server.luau` owns lobby placement, arena entry, safe combat spawn selection, spawn protection, death state, and return-to-lobby placement.

## Lobby and arena lifecycle

1. A joining or respawning player is placed at a deterministic lobby spawn.
2. The server sets `RevolverGameState` to `Lobby`, applies invisible lobby protection, disables/equips no weapon, and shows lobby UI on the client.
3. The lobby `EnterPrompt` moves the player to `EnteringArena` for the existing transition interval.
4. `ArenaService` chooses a combat spawn using enemy distance, line of sight, and recent-spawn reuse scoring.
5. A successful placement sets state to `Arena`, applies the existing short spawn protection, resets ammo, and enables/equips the revolver.
6. Fire, reload, and roll requests are accepted only when server state and validation allow them.
7. Death changes state to `Dead`. Roblox respawn creates a new character, which is returned to `Lobby`; arena re-entry starts a fresh combat lifecycle.

## Shared state and configuration

- `ReplicatedStorage/Shared/Constants.luau` is the single source for remote, attribute, and cross-boundary instance names.
- `ReplicatedStorage/Shared/GameState.luau` defines the lobby/arena states.
- `ReplicatedStorage/Config/WeaponConfig.luau` contains authoritative weapon and roll values used by both client and server.
- `ReplicatedStorage/Config/GameConfig.luau` contains arena lifecycle, spawn, and combat-bound values.
- `ReplicatedStorage/Config/WeaponPresentationConfig.luau` contains presentation-only offsets, animation timing, recoil, sway, VFX, and audio tuning.

Authoritative values must not be copied into a client-only module. Presentation-only changes must not be used as server validation rules.

## Studio-managed assets

The source revolver files remain in `assets/revolver/`, including `Revolver_Final.blend` and `Revolver_Final.fbx`. The Rojo-managed `src/starterpack/Revolver.rbxmx` remains the gameplay Tool and preserves the names used by code: `Handle`, `Muzzle`, `CylinderMotor`, `HammerMotor`, and `TriggerMotor`.

The arena model remains in `src/workspace/Arena.model.json`. Studio-only imports should stay outside `src` unless the current import pipeline explicitly requires a Rojo-managed instance.
