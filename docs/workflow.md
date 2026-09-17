# Team workflow

Use this sequence for every change:

```text
git pull
-> create a feature branch
-> rojo serve
-> edit and test in Roblox Studio
-> commit
-> push
-> merge through main
```

Example branch names:

- `feature/gameplay-hit-validation`
- `feature/ui-ammo-feedback`
- `feature/animation-reload-pass`
- `refactor/client-boundaries`

## Starting work

1. Pull before starting so the branch begins from current `main`.
2. Create a narrowly scoped branch.
3. Check `docs/ownership.md` before editing a shared file.
4. Run `rojo serve` and connect Studio to `default.project.json`.

Do not have multiple people casually edit the same large controller, config, remote contract, or `default.project.json`. Agree on the change and landing order first when shared files are unavoidable.

## Before merge

1. Build or parse the Rojo project.
2. Test the affected flow in Roblox Studio, including respawn or re-entry when lifecycle code changed.
3. Pull the latest target branch and resolve conflicts deliberately.
4. Review remote names, attributes, and config values for accidental contract changes.
5. Commit only source and intentional assets, then push and merge through `main`.

Never commit secrets, API keys, local credentials, Studio lock files, temporary place builds, logs, or Blender autosave backups. Do not commit generated files such as `sourcemap.json` unless the team explicitly adopts them as source.

## Useful validation commands

```powershell
rojo build default.project.json -o REVOLVERARENA.rbxlx
rojo sourcemap default.project.json --include-non-scripts -o sourcemap.json
```

The root place file and sourcemap are ignored because they are generated validation artifacts.
