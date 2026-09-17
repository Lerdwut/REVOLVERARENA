# Team ownership

Ownership identifies the default reviewer and editor; it does not prevent collaboration. Changes to a shared contract require coordination before implementation.

## Gameplay / Backend Programmer

Primary ownership:

- `src/ServerScriptService/`
- `src/ReplicatedStorage/Shared/` gameplay contracts
- authoritative sections of `src/ReplicatedStorage/Config/`
- runtime remotes and server validation
- lobby/arena state, combat, ammo, reload, roll, spawn, respawn, stats, and game-mode state

The server remains authoritative for ammo, fire cadence, reload completion, roll acceptance, raycasts, target validation, and kills.

## UI / UX Programmer

Primary ownership:

- `src/StarterPlayer/StarterPlayerScripts/UI/`
- future Rojo-managed `StarterGui` content
- `src/StarterPlayer/StarterPlayerScripts/Shared/SettingsStore.luau`
- HUD, ammo display, roll cooldown, hit/death feedback, kill feed, scoreboard, lobby hint, transitions, and settings presentation

`GameAudio.luau` is client-shared infrastructure; coordinate with the 3D / Animation / VFX owner when changing weapon audio routing.

## 3D / Animation / VFX Programmer

Primary ownership:

- `src/StarterPlayer/StarterPlayerScripts/Viewmodel/`
- weapon visual animation, recoil presentation, sway, bob, muzzle flash, tracers, and weapon sounds
- `assets/revolver/`
- Studio-side visual import and setup

Visual edits to `src/starterpack/Revolver.rbxmx` require coordination with Gameplay / Backend because scripts rely on `Handle`, `Muzzle`, and the named Motor6Ds.

## Shared coordination areas

Coordinate before changing:

- `src/ReplicatedStorage/Config/`
- `src/ReplicatedStorage/Shared/Constants.luau`
- remote names or payloads
- player attribute names or meanings
- `Controllers/WeaponController.client.luau`
- `src/starterpack/Revolver.rbxmx`
- `default.project.json`

`WeaponController` is intentionally a thin integration point shared by gameplay input and visual presentation. Prefer extending the relevant `Viewmodel` module or UI controller instead of growing the integration file again.

## Not yet created

There is no persistence or inventory implementation, so no empty `Data`, `PlayerDataService`, or `InventoryService` placeholders exist. Add those boundaries only when a real system is ready to own them.
