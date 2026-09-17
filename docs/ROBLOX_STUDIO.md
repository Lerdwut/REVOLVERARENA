# Roblox Studio and Rojo workflow

Roblox Studio is the runtime, visual editing, multiplayer testing, and publishing environment. Git is the durable team history. Rojo connects the two, but only for paths declared in `default.project.json`.

## Source-of-truth map

| Content | Source of truth | Notes |
| --- | --- | --- |
| Luau under `src/` | Git filesystem | Edit in a code editor; Rojo syncs scripts into Studio |
| `Workspace.Arena` | `src/workspace/Arena.model.json` | Includes environment, lobby, entry prompt, and combat spawn markers |
| `StarterPack.Revolver` | `src/starterpack/Revolver.rbxmx` | Full gameplay Tool hierarchy |
| Lighting and its effects | `default.project.json` | Ambient, technology, atmosphere, color correction, and sun rays |
| Revolver authoring files and QA renders | `assets/revolver/` | Not inserted into the DataModel by Rojo |
| Remotes, PlayerGui UI, viewmodels, attributes, leaderstats, tracers, and protection objects | Runtime scripts | Do not create or maintain these by hand in Studio |
| Published place state | Roblox cloud / Studio | Publishing is separate from Rojo sync and does not replace a Git commit |
| Terrain | Not represented in the current repository | Studio Terrain edits are not reproducible from this repository as configured |

Anything under a mapped Rojo path should be assumed replaceable by the filesystem version. A Studio save or publish is not proof that a mapped change exists in Git.

## Safe live-sync routine

1. Start with a clean or intentionally understood `git status`.
2. Run `rojo build default.project.json -o REVOLVERARENA.rbxlx`.
3. Open that generated place or a designated development copy.
4. Run `rojo serve default.project.json`.
5. Connect the Rojo 7 plugin and inspect the proposed tree before accepting unexpected changes.
6. Make one scoped change.
7. Confirm the change is represented in the intended repository file with `git diff`.
8. Disconnect or stop the server before broad Studio-only experiments.
9. Rebuild and test before committing.

Do not connect this project to an unrelated production or personal place. Rojo may replace instances at managed paths.

## Code and runtime UI

Edit Luau on disk. Runtime UI controllers construct interfaces under `PlayerGui`; there is no `StarterGui` source hierarchy. Test UI changes in Play mode, because the relevant instances do not exist in Edit mode.

Runtime-created objects such as `ReplicatedStorage.RevolverRemotes`, leaderstats, player attributes, local viewmodels, force fields, and tracers should never be copied back into source as hand-authored instances.

## Arena and map editing

The current arena is Git-managed through `src/workspace/Arena.model.json`. It contains gameplay-sensitive structures:

- `Arena.Lobby`, including the entry pedestal and `EnterPrompt`
- `Arena.Spawns`, used for server spawn selection
- arena bounds, cover, and sight lines used by combat validation and spawn scoring

`tools/generate_western_arena.py` can regenerate the tracked model. For generator-based changes:

```powershell
python tools/generate_western_arena.py
```

On macOS, use `python3` if `python` is unavailable.

The generator overwrites `src/workspace/Arena.model.json`. Do not run it over uncommitted manual model edits. A pull request should make clear whether the generator or a reviewed exported model is the intended source path.

For Studio-authored geometry changes, verify that the final hierarchy is captured in the tracked model file, inspect the diff, rebuild, and test lobby entry plus two-player spawn behavior. A local `.rbxlx` save alone is not a contribution.

## Lighting

Lighting properties and the named effects `WesternAtmosphere`, `WesternColorGrade`, and `SoftSunRays` are declared in `default.project.json`. Treat that file as canonical.

Prototype visual values in Studio if helpful, then transfer the approved values to `default.project.json`. Reconnect or rebuild to confirm the filesystem reproduces the look.

## Revolver and 3D imports

The authoring and reference files live in `assets/revolver/`:

- `Revolver_Final.blend`
- `Revolver_Final.fbx`
- `stylized_low_poly_revolver.gltf`
- manifest and QA renders

These files do not live-sync. The gameplay Tool is `src/starterpack/Revolver.rbxmx`.

When importing or replacing visual geometry:

1. Preserve scale, forward direction, pivots, material intent, and part naming.
2. Keep the Tool named `Revolver`.
3. Preserve `Handle`, the `Muzzle` attachment, and `CylinderMotor`, `HammerMotor`, and `TriggerMotor`.
4. Keep non-gameplay visual geometry non-collidable, non-queryable, non-touchable, and massless where appropriate.
5. Weld static visual parts and use the named Motor6Ds for animated parts.
6. Capture the approved Tool back into `src/starterpack/Revolver.rbxmx`.
7. Build from disk, reconnect Studio, and test first-person and third-person behavior.
8. Update QA renders and [the import notes](../assets/revolver/IMPORT.md) when the asset contract changes.

If a MeshPart or texture uses a Roblox cloud asset ID, every development and publishing account must have permission to use it. Record the source and license in the pull request. Do not commit downloaded third-party assets without confirmed rights.

## Terrain

No Terrain payload is tracked today. Before adding Terrain, agree on a reproducible export/import or generation workflow and document it in this file. Until then, Terrain edited in Studio may exist only in a local place or published version and can be lost when another teammate rebuilds.

## Publishing

Rojo sync changes a local Studio DataModel; it does not publish the game. Only teammates with explicit publish permission should publish. Before publishing:

1. Pull the approved `main` commit.
2. Build or sync from that commit.
3. Run the agreed Studio smoke and multiplayer tests.
4. Confirm the destination experience and place.
5. Publish from Studio.
6. Record the deployed commit in the team's release note or issue.

Never put a `.ROBLOSECURITY` cookie or deployment credential in this repository.

## Avoiding lost work

- Commit or stash filesystem changes before a risky sync.
- Save a separate local backup place before restructuring large Studio hierarchies.
- Keep one active editor for `.rbxmx`, `.model.json`, Blender, and other hard-to-merge assets.
- Never assume Publish to Roblox updates Git.
- Never assume a Git pull updates an already-open Studio place until Rojo reconnects or the place is rebuilt.
- Resolve source-control conflicts before reconnecting Rojo.
- After sync, inspect both the Studio tree and `git diff`.
