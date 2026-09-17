# Contributing to RevolverArena

Thank you for contributing. This repository is organized for a three-person team, so small branches, clear ownership, and reproducible Studio tests matter more than process ceremony.

## Before you start

1. Complete [SETUP.md](SETUP.md).
2. Read [architecture.md](architecture.md) and [ownership.md](ownership.md).
3. Pull current `main`.
4. Tell the relevant owner before changing a shared contract or hard-to-merge asset.
5. Create a focused branch as described in [workflow.md](workflow.md).

## Luau conventions

Match the current codebase:

- Start Luau files with `--!strict`.
- Use tabs for Luau indentation.
- Use `PascalCase` for modules and exported tables, and `camelCase` for locals and functions.
- Use `.server.luau` for server entry points and `.client.luau` for client entry points.
- Keep reusable modules as `.luau`.
- Prefer small modules with one clear responsibility.
- Centralize remote, attribute, and shared instance names in `Shared/Constants.luau`.
- Put authoritative game values in `WeaponConfig.luau` or `GameConfig.luau`; put presentation-only tuning in `WeaponPresentationConfig.luau`.
- Validate all client input on the server. Client prediction may present an action but must not decide outcomes.
- Do not add another weapon viewmodel render loop; `WeaponController.client.luau` owns that integration point.

Avoid broad formatting or renaming in behavior changes. It makes three-way review and conflict resolution harder.

## Assets and models

- Follow [ROBLOX_STUDIO.md](ROBLOX_STUDIO.md) for mapped instances and imports.
- Preserve gameplay-required Tool and arena marker names.
- Include before/after screenshots for visual changes.
- Commit the editable source plus the intentional runtime representation when both are required.
- Do not commit Blender backups, duplicate exports, or unlicensed assets.
- Coordinate before replacing tracked binary files. Git LFS is not configured.

## Documentation

Update documentation in the same pull request when you change:

- setup commands or tool versions
- directory or Rojo mappings
- remote, attribute, state, or Tool hierarchy contracts
- ownership boundaries
- Studio, map, Terrain, import, or publishing procedures
- README project status

Use repository-relative links and keep filenames exactly cased as they appear in `docs/`.

## Required validation

Every change:

```bash
rojo build default.project.json -o REVOLVERARENA.rbxlx
```

Then test proportionally:

| Change | Minimum manual validation |
| --- | --- |
| Shared/config | Start Studio, exercise every affected consumer |
| Combat or remotes | Local server with at least two players; fire, hit, reload, roll, death |
| Arena/lifecycle | Lobby entry, spawn safety, death, respawn, and re-entry |
| UI/settings | Relevant states, common viewport sizes, settings open/close, respawn |
| Viewmodel/VFX/audio | Equip, fire, empty, reload, movement, roll, first/third person |
| Tool or 3D asset | Rojo rebuild plus first/third-person multiplayer check |
| Docs only | Check links, commands, filenames, and rendered Markdown |

There is no checked-in automated test or CI suite at present. Do not claim automated coverage that does not exist.

## Pull request checklist

- [ ] The branch contains one coherent change.
- [ ] `git diff` contains only intentional files.
- [ ] `rojo build default.project.json -o REVOLVERARENA.rbxlx` succeeds.
- [ ] The affected flow was tested in Studio.
- [ ] Multiplayer-sensitive changes were tested with at least two players.
- [ ] Remote, attribute, config, state, Tool, and map contracts remain compatible or are documented.
- [ ] Visible changes include screenshots or a short capture.
- [ ] No secrets, generated place files, logs, backups, or unlicensed assets are included.
- [ ] Relevant docs and README status are current.
- [ ] Review is requested from the primary owner and every affected shared-area owner.

## Security

Never commit Roblox cookies, personal access tokens, API keys, credentials, private environment files, or deployment secrets. If a secret is committed, revoke it immediately and tell the team; deleting it in a later commit is not sufficient.

Report gameplay trust-boundary issues to the Gameplay / Backend owner before publicly detailing an exploitable path. Fixes should preserve server authority and include a regression test plan.

## Review behavior

Review the outcome, contract, and evidence—not only line style. Keep comments specific and actionable. Authors should answer unresolved questions, rerun affected tests after material changes, and avoid merging while required-owner concerns remain open.
