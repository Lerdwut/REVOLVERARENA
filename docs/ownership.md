# Team ownership

Ownership identifies the default implementer and reviewer. It is not exclusive permission to edit a file. Coordinate before changing another role's area or any shared contract.

## Ownership matrix

| Area | Primary owner | Responsibilities |
| --- | --- | --- |
| `src/ServerScriptService/Combat/` | Gameplay / Backend | Fire, reload, ammo, roll, raycast and hit validation |
| `src/ServerScriptService/Game/` | Gameplay / Backend | Lobby, arena entry, spawn selection, protection, death, stats, and game mode |
| `src/ReplicatedStorage/Shared/` | Gameplay / Backend, shared review | Cross-boundary names and game-state contract |
| Authoritative parts of `src/ReplicatedStorage/Config/` | Gameplay / Backend | Server-enforced timing, capacity, range, spawn, and lifecycle values |
| `src/StarterPlayer/StarterPlayerScripts/UI/` | UI / UX | HUD, kill feed, scoreboard, lobby, transitions, and settings interface |
| `SettingsStore.luau` | UI / UX | Session-local user settings and UI input blocking |
| `CameraController.client.luau` | UI / UX with Gameplay review | Camera mode, sensitivity, and state-driven camera behavior |
| `src/StarterPlayer/StarterPlayerScripts/Viewmodel/` | 3D / Animation / VFX | Viewmodel structure, poses, weapon animation, VFX, and weapon sounds |
| `WeaponPresentationConfig.luau` | 3D / Animation / VFX | Presentation-only tuning |
| `assets/revolver/` | 3D / Animation / VFX | Blender/FBX/glTF sources, manifests, import notes, and QA renders |
| `src/starterpack/Revolver.rbxmx` | 3D / Animation / VFX + Gameplay | Visual Tool hierarchy plus gameplay-required references |
| `src/workspace/Arena.model.json` | 3D / Animation / VFX + Gameplay | Arena geometry plus lobby/spawn gameplay markers |

## Gameplay / Backend Programmer

Primary responsibilities:

- Keep the server authoritative for ammo, cadence, reload completion, roll acceptance, raycasts, targets, damage, kills, and lifecycle state.
- Validate every client request for type, state, character, equipment, timing, and bounds.
- Maintain `Constants.luau`, `GameState.luau`, and authoritative configuration with affected-role review.
- Keep runtime remote creation and all server/client payloads compatible.
- Review changes to required Tool references, arena markers, controller requests, and replicated attributes.

Gameplay should not put presentation tuning into authoritative config or make UI/viewmodel modules responsible for game outcomes.

## UI / UX Programmer

Primary responsibilities:

- Maintain HUD, ammo and roll displays, feedback, kill feed, scoreboard, lobby hints, transitions, and settings.
- Treat server attributes and feedback remotes as authoritative.
- Keep UI runtime lifecycle under `PlayerGui` consistent with the existing code-built approach.
- Maintain accessible scale, contrast, input behavior, and state transitions.
- Coordinate camera and input-blocking changes with Gameplay and viewmodel input owners.

UI should not infer hits, kills, reload completion, or roll approval from local effects.

## 3D / Animation / VFX Programmer

Primary responsibilities:

- Maintain revolver source files, pivots, naming, materials, imports, and QA renders.
- Maintain viewmodel creation, weapon poses, animation state, recoil, sway, bob, flashes, tracers, and presentation audio.
- Keep `WeaponPresentationConfig.luau` presentation-only.
- Preserve Tool references used by code: `Handle`, the `Muzzle` attachment, and `CylinderMotor`, `HammerMotor`, and `TriggerMotor`.
- Coordinate arena geometry edits that affect bounds, line of sight, lobby entry, or spawn markers.

Visual changes must not silently change server timing or gameplay collision/query behavior.

## Shared contracts

The following require coordination before implementation:

- `default.project.json`
- remote names, direction, or payloads
- attribute names, types, or meanings
- game-state names or lifecycle transitions
- `WeaponConfig.luau` and `GameConfig.luau`
- `WeaponController.client.luau`
- `src/starterpack/Revolver.rbxmx`
- arena lobby entry and spawn-marker hierarchy

For a shared change:

1. Name the contract in the issue or pull request.
2. Identify every producer and consumer.
3. Agree on landing order if multiple branches are involved.
4. Include reviewers from every affected role.
5. Update [architecture.md](architecture.md) or [ROBLOX_STUDIO.md](ROBLOX_STUDIO.md) when the contract or source-of-truth boundary changes.

## Review expectations

- Gameplay reviews server authority, security, replication, and lifecycle implications.
- UI / UX reviews player-facing state, feedback, controls, and accessibility implications.
- 3D / Animation / VFX reviews hierarchy, pivot, animation, visual, audio, and asset-pipeline implications.
- The pull request author supplies test evidence; reviewers do not have to rediscover the intended test plan.
- A reviewer who requests a change should re-check the affected section after it is addressed.

## Documentation ownership

- Setup and Git workflow: the teammate changing tooling or repository process
- Architecture and contracts: Gameplay / Backend, with affected-role review
- Studio and asset workflow: 3D / Animation / VFX, with Gameplay review for mapped instances
- UI behavior documentation: UI / UX
- README status: whoever lands the change that makes the status stale

## Systems not yet owned

There is no persistence, inventory, progression, cosmetics, shop, badge, or persistent leaderboard implementation. Do not add empty services or claim ownership for those systems until the team approves a concrete design.
