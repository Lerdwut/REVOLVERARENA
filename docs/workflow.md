# Git and GitHub workflow

The shared repository is [Lerdwut/REVOLVERARENA](https://github.com/Lerdwut/REVOLVERARENA). `main` is the integration branch. Day-to-day work should move through short-lived branches and pull requests.

## Standard sequence

```text
pull main
  -> create a branch
  -> edit
  -> test in Roblox Studio
  -> build with Rojo
  -> commit
  -> push
  -> open a pull request
  -> review
  -> merge
```

Example:

```bash
git switch main
git pull --ff-only origin main
git switch -c feature/gameplay-hit-validation

# Edit, run Rojo, and test in Studio.

git status
git diff
rojo build default.project.json -o REVOLVERARENA.rbxlx
git add <intentional-files>
git commit -m "fix(combat): tighten hit validation"
git push -u origin feature/gameplay-hit-validation
```

Open a pull request against `main`, complete the checklist in [CONTRIBUTING.md](CONTRIBUTING.md), address review, and merge only after the relevant owner approves.

## Branch names

Use a short category and area:

- `feature/gameplay-safe-spawns`
- `feature/ui-ammo-feedback`
- `feature/vfx-reload-pass`
- `fix/combat-roll-cooldown`
- `docs/setup-troubleshooting`
- `refactor/client-boundaries`

Keep one concern per branch. If a task crosses roles, agree on the integration order before both branches begin changing the same contract.

## Commit style

Use an imperative subject that explains the outcome. A lightweight Conventional Commits prefix keeps history scannable:

- `feat(ui): add wanted-state treatment`
- `fix(game): return respawns to lobby`
- `refactor(viewmodel): isolate weapon effects`
- `docs(setup): add macOS instructions`
- `asset(revolver): update first-person mesh`

Do not combine unrelated cleanup, asset replacement, and gameplay behavior in one commit.

## Pull request expectations

Every pull request should include:

- What changed and why
- The owning area and requested reviewer
- How it was tested, including Studio mode and player count
- Screenshots or a short capture for visible UI, animation, VFX, map, or asset changes
- Any remote, attribute, configuration, Tool hierarchy, or Rojo mapping changes
- Known limitations or follow-up work

At least one teammate reviews each pull request. The primary owner listed in [ownership.md](ownership.md) should review changes in their area. Shared contracts require review from each affected role.

The repository currently has no checked-in CI workflow, so local build and Studio validation are required evidence rather than optional safeguards.

## Before requesting review

1. Pull current `main` and resolve conflicts on the feature branch.
2. Inspect `git status` and `git diff`; stage only intentional files.
3. Run `rojo build default.project.json -o REVOLVERARENA.rbxlx`.
4. Test the affected path in Studio.
5. For replication, combat, spawning, death, or kill-feed changes, run a local server with at least two players.
6. Re-test lobby entry, death, respawn, and re-entry when lifecycle code changes.
7. Update docs when setup, ownership, architecture, contracts, or asset workflows changed.

## Conflict-prone areas

Coordinate before editing:

- `default.project.json`
- `src/ReplicatedStorage/Shared/Constants.luau`
- `src/ReplicatedStorage/Shared/GameState.luau`
- files under `src/ReplicatedStorage/Config/`
- `src/StarterPlayer/StarterPlayerScripts/Controllers/WeaponController.client.luau`
- `src/starterpack/Revolver.rbxmx`
- `src/workspace/Arena.model.json`
- shared documentation navigation in `README.md`

Large `.rbxmx`, `.model.json`, `.blend`, and image conflicts are difficult or impossible to merge safely. Prefer a single active editor, small changes, and serialized landing order for those files.

## Resolving conflicts

- Do not choose “ours” or “theirs” blindly for shared contracts.
- Re-read both branches and reconstruct the intended combined behavior.
- For model or binary asset conflicts, select the correct source version with the asset owner, reapply the other change if necessary, then test again.
- Re-run the Rojo build after any conflict resolution.
- Ask the relevant owner to re-review if resolution changed their area.

## Never commit

- `.env` files, tokens, cookies, API keys, credentials, or local machine paths
- Generated root `REVOLVERARENA.rbxlx` or `sourcemap.json`
- Studio lock files, logs, editor state, or temporary folders
- Blender autosaves such as `.blend1`
- Unlicensed third-party assets
- Roblox security cookies or deployment credentials

The tracked `Revolver_Final.blend` and `Revolver_Final.fbx` are intentional source assets. Coordinate replacements, avoid duplicate exports, and consider Git LFS before adding much larger binaries. Git LFS is not currently configured.

## After merge

Switch back to `main`, pull, and delete the local feature branch when it is no longer needed:

```bash
git switch main
git pull --ff-only origin main
git branch -d feature/gameplay-hit-validation
```

Delete the remote branch in GitHub after merge unless it is intentionally long-lived.
