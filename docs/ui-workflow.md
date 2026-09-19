# Fusion and UI Labs workflow

This guide covers the reusable Fusion UI layer, the single Fusion-owned runtime UI root, and the UI Labs storybook workflow for RevolverArena. Runtime HUD, lobby, scoreboard, settings, transition, kill-feed, and wanted-marker presentation is composed by `StarterPlayerScripts/UI/UIController.client.luau`; the gameplay and settings contracts it observes remain outside the UI layer.

## UI-01–UI-03 status

The implementation work for the first three UI/UX tasks is complete on branch `feat/ui-01-03-polish`. The remaining status is Roblox Studio Play Mode visual and interaction QA.

| Task | Status | Implementation summary |
| --- | --- | --- |
| UI-01 Combat HUD cleanup | Implemented; Studio QA pending | Shared HUD layout tokens, readable ammo/streak/roll presentation, kill-feed truncation, safe margins, and hotbar re-application after respawn |
| UI-02 Lobby HUD state | Implemented; Studio QA pending | Responsive lobby hint, Fusion state visibility gates, settings closure on non-play states, and preserved no-auto-modal behavior |
| UI-03 Settings panel polish | Implemented; Studio QA pending | Modal backdrop, spring-smoothed sliders, responsive panel scale, validated SettingsStore writes, mouse-lock restoration, and scoped cleanup |

The implementation leaves `SettingsStore`'s public API and the gameplay, camera, weapon, audio, and remotes contracts unchanged.

## Toolchain

| Tool or package | Version | Role |
| --- | --- | --- |
| Rojo | 7.7.0 | Maps source files into the Roblox DataModel |
| Wally | 0.3.2 | Resolves and locks Luau packages |
| Fusion | 0.3.0 | Reactive UI state and scoped instance construction |
| UI Labs utility package | 2.4.2 | Fusion story helpers and configurable controls |
| UI Labs Studio plugin | Current Creator Store version | Discovers and previews stories |

The UI Labs plugin is installed separately from the [Roblox Creator Store](https://create.roblox.com/store/asset/14293316215/UI-Labs). Fusion and the UI Labs utility package are declared in `wally.toml`; `wally.lock` is the reproducible version record. Generated `Packages/` and `DevPackages/` folders are ignored by Git.

## First-time setup

From the repository root:

```powershell
rokit install
wally install
rojo build default.project.json -o REVOLVERARENA.rbxlx
```

Install the UI Labs Studio plugin once, then restart Roblox Studio if it was open. The generated place is a development/test artifact and is ignored by Git.

Install the Rojo Studio plugin from the same pinned CLI before connecting:

```powershell
rojo plugin install
```

This overwrites an older Rojo plugin with the version that matches the server. Restart Roblox Studio after installing it so the old plugin protocol is unloaded.

Wally 0.3.2 does not support the requested `wally install --locked` invocation. With the committed `wally.lock` present, `wally install` is the pinned install command for this repository; it resolves the versions recorded in the lockfile. If the dependency manifest changes, run `wally install`, review the resulting `wally.lock`, and commit the lockfile. Do not edit `wally.lock` by hand.

## Start the local preview

1. Open `REVOLVERARENA.rbxlx` in Roblox Studio, or open the designated local development place.
2. From the repository root, run:

   ```powershell
   rojo serve default.project.json
   ```

3. Open the Rojo 7 plugin in Studio and connect to `localhost:34872`.
4. Open UI Labs, regenerate storybooks if necessary, and select `Revolver Arena UI`.
5. Mount `ArenaStatusCard` and use the controls panel to change its state.
6. Keep the Rojo server running while editing. Stop it with `Ctrl+C` when finished.

Rojo owns the mapped source tree. Do not copy the preview instances from UI Labs or `PlayerGui` back into the repository.

## Source layout

```text
src/ReplicatedStorage/UI/
├── Theme.luau                         shared colors, typography, spacing, and sizes
├── Components/                        pure reusable Fusion components
│   └── StatusCard.luau
├── Stories/                            UI Labs story modules
│   └── ArenaStatusCard.story.luau
└── RevolverArena.storybook.luau        storybook grouping module
```

`ReplicatedStorage.UI.Components` contains pure components used by runtime feature modules and stories. `ReplicatedStorage.UI.Stories` exists for visual development and must not be required by gameplay entry points. The runtime side is organized as follows:

```text
src/StarterPlayer/StarterPlayerScripts/UI/
├── UIController.client.luau             single runtime entry point and root Fusion scope
└── Runtime/                             scoped runtime feature modules and state adapters
```

Only `UIController.client.luau` has a client entry suffix; files under `Runtime/` are modules and never initialize themselves.

## Runtime ownership and state flow

`UIController.client.luau` creates one Fusion scope and passes it to every feature mount. `RuntimeState.luau` observes public player attributes, the combat and kill-feed remotes, roll timing, and the existing `SettingsStore`. Feature modules convert those values into `Computed`, `Tween`, `Spring`, `ForPairs`, and `ForValues` bindings.

The adapter keeps `SettingsStore.Get*`, `Set`, `Reset`, `Changed`, `OpenChanged`, `IsOpen`, and `IsInputBlocked` stable for camera, weapon, audio, and effects. Settings controls write through the store; they do not maintain a second source of truth. Remote payload validation and authoritative gameplay decisions remain outside the UI layer.

All instances, observers, input connections, player/character listeners, and transient UI timers belong to the root scope. Feature-specific child scopes are used for dynamic wanted markers and collection entries. Unmounting the root destroys the generated UI and disconnects the associated work.

## Component rules

Reusable components follow the Fusion 0.3 scope pattern:

```luau
local function Component(scope: Fusion.Scope, props: Props): GuiObject
	return scope:New "Frame" {
		Parent = props.parent,
	}
end
```

The component owns all instances it creates through the supplied scope. Dynamic props should use `Fusion.UsedAs<T>` so callers may provide either a literal value or a Fusion state object. Components must receive game state and layout through props rather than reading `Players`, remotes, or authoritative configuration themselves.

The current `StatusCard` interface is:

```luau
StatusCard(scope, {
	parent = Instance,
	ammo = Fusion.UsedAs<number>,
	capacity = Fusion.UsedAs<number>,
	streak = Fusion.UsedAs<number>,
	wanted = Fusion.UsedAs<boolean>,
	gameState = Fusion.UsedAs<string>,
	variant = "card" | "runtime"?,
	showState = boolean?,
	showWanted = boolean?,
	position = UDim2?,
	anchorPoint = Vector2?,
	size = UDim2?,
}) -> Frame
```

The default `card` variant is the grouped UI Labs presentation. The `runtime` variant is a transparent full-screen composition that preserves the legacy ammo and streak placements and hides the grouped-only status rows unless explicitly enabled.

Numeric display values are clamped for presentation: capacity is at least one, ammo is non-negative and no greater than capacity, and streak is non-negative. This does not change authoritative gameplay state.

## Story rules

Story modules end in `.story.luau` and return a UI Labs Fusion story. Storybooks end in `.storybook.luau` and return a table containing `storyRoots`.

Fusion stories should:

- Provide the same `Fusion` module through the `fusion` key.
- Use `UILabs.CreateFusionStory` when controls are needed.
- Read control state from `props.controls` and mount under `props.target`.
- Use `props.scope` and `scope:New`, `scope:Computed`, or other scoped Fusion APIs.
- Avoid `Players.LocalPlayer`, `PlayerGui`, remotes, server services, network calls, and permanent global connections.
- Avoid manual destruction of instances created by the story scope; unmounting the story performs cleanup.

The sample story uses `UILabs.Slider` for ammo, capacity, and streak, `UILabs.Boolean` for wanted state, and `UILabs.EnumList` for lobby/arena/dead state. UI Labs passes those controls to Fusion as reactive values.

## UI development loop

1. Create a short-lived branch using the Git process in [`workflow.md`](workflow.md).
2. Add or update visual tokens in `Theme.luau`.
3. Implement a pure component under `Components/` with an explicit props type.
4. Add a `.story.luau` module with controls for meaningful visual states.
5. Run `wally install` and rebuild the Rojo place.
6. Connect Studio, open the story in UI Labs, and verify default, edge, and compact states.
7. Reload and unmount the story repeatedly to check that instances and connections do not accumulate.
8. Run Roblox Play mode to verify the existing runtime UI and input-blocking behavior.
9. Include screenshots or a short capture for visible UI changes in the pull request.

## Visual QA matrix

| Area | Required checks |
| --- | --- |
| Ammo | Empty, full, and capacity changes never show invalid or clipped values |
| Streak | Zero, normal, and high streak values remain readable |
| Status | Lobby, arena, dead, wanted, and clear states have the intended text and color |
| Layout | Default and compact viewport sizes have no overlap, clipping, or unreadable text |
| Lifecycle | Story reload and unmount remove old instances and reactive work |
| Runtime | The single Fusion root owns the current `PlayerGui` interfaces and inputs without duplicate ScreenGuis or changed gameplay contracts |

## Validation commands

```powershell
wally install
rojo sourcemap default.project.json --include-non-scripts -o sourcemap.json
rojo build default.project.json -o REVOLVERARENA.rbxlx
```

`sourcemap.json` and `REVOLVERARENA.rbxlx` are generated validation artifacts and must not be committed. Confirm that the source tree contains the intended changes with `git status` and `git diff` before opening a pull request.

## Troubleshooting

### Wally cannot resolve a package

Run `rokit install`, confirm the package alias and version in `wally.toml`, and run `wally install` to refresh the lockfile. Review the lockfile diff before committing it.

### The storybook is missing

Confirm that Rojo is serving this repository's `default.project.json`, that `ReplicatedStorage.UI` and `ReplicatedStorage.DevPackages` are present in Studio, and that the modules retain the `.story` and `.storybook` suffixes after Rojo mapping. Regenerate storybooks in UI Labs.

### The story mounts but does not update

Make sure the story uses the Fusion story contract, passes `fusion = Fusion`, reads `props.controls`, and creates instances through `props.scope`. A story should not snapshot a control by reading it outside a reactive Fusion computation.

### Runtime UI changes unexpectedly

Disconnect Rojo before experimenting with unrelated Studio-only instances. Runtime UI is created under `PlayerGui`; UI Labs preview instances are isolated and should never be treated as source-of-truth content.

## Review checklist

- [ ] `wally.toml` and `wally.lock` agree; generated package folders remain ignored.
- [ ] The component is pure, scoped, typed, and does not decide gameplay outcomes.
- [ ] The story exposes useful controls and covers edge states.
- [ ] UI Labs preview was checked at default and compact sizes.
- [ ] Story reload/unmount was checked for cleanup.
- [ ] Rojo sourcemap and build pass.
- [ ] Existing runtime UI was tested in Play mode.
- [ ] Screenshots/capture and known limitations are included in the pull request.
