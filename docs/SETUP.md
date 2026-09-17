# RevolverArena setup

This guide takes a new teammate from a clean computer to a local Roblox Studio session connected to the repository. The project currently pins Rojo 7.7.0 in both `rokit.toml` and `aftman.toml`; Rokit is the documented team path.

## Prerequisites

- A [GitHub](https://github.com/) account with access to the repository
- [Git](https://git-scm.com/downloads)
- [Roblox Studio](https://create.roblox.com/docs/studio/setup) and a Roblox account
- [Rokit](https://github.com/rojo-rbx/rokit), which installs the project-pinned Rojo CLI
- Permission to publish only if your role requires publishing; local development does not require publish access

The project does not currently use Wally, npm, a database, or environment secrets.

## Windows

### 1. Install Git and Roblox Studio

Install Git from the official installer or with Windows Package Manager:

```powershell
winget install --id Git.Git -e
```

Install Roblox Studio from Roblox Creator Hub, then launch it once so its local folders are initialized.

### 2. Install Rokit

Run the official installer from PowerShell:

```powershell
Invoke-RestMethod https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | Invoke-Expression
```

Close and reopen PowerShell. Verify:

```powershell
rokit --version
```

### 3. Clone and install project tools

```powershell
git clone https://github.com/Lerdwut/REVOLVERARENA.git
cd REVOLVERARENA
rokit install
rojo --version
```

`rojo --version` should report `Rojo 7.7.0`. Review `rokit.toml` before trusting tools. If Rokit asks for explicit trust:

```powershell
rokit trust rojo-rbx/rojo
rokit install
```

### 4. Install the Studio plugin

```powershell
rojo plugin install
```

Restart Roblox Studio if it was open. The Rojo plugin should appear on the Plugins toolbar.

## macOS

### 1. Install Git and Roblox Studio

Install Apple's command-line tools, which include Git:

```bash
xcode-select --install
```

Install Roblox Studio from Roblox Creator Hub, then launch it once.

### 2. Install Rokit

Run the official installer in Terminal:

```bash
curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash
```

Close and reopen Terminal. Verify:

```bash
rokit --version
```

### 3. Clone and install project tools

```bash
git clone https://github.com/Lerdwut/REVOLVERARENA.git
cd REVOLVERARENA
rokit install
rojo --version
```

`rojo --version` should report `Rojo 7.7.0`. If prompted, review `rokit.toml`, then trust and install the pinned tool:

```bash
rokit trust rojo-rbx/rojo
rokit install
```

### 4. Install the Studio plugin

```bash
rojo plugin install
```

Restart Roblox Studio if it was open.

## Build the place

From the repository root:

```bash
rojo build default.project.json -o REVOLVERARENA.rbxlx
```

Open `REVOLVERARENA.rbxlx` in Roblox Studio. This generated root place file is ignored by Git and can be rebuilt at any time.

## Start live sync

From the repository root:

```bash
rojo serve default.project.json
```

Rojo normally listens on `127.0.0.1:34872`. In Studio:

1. Open the Rojo plugin from the Plugins toolbar.
2. Select the local server shown by the plugin, or enter `localhost:34872`.
3. Connect and confirm that the tree matches `default.project.json`.
4. Keep the terminal running while you edit. Press `Ctrl+C` to stop the server.

Use a built place or a deliberate local test place. Connecting Rojo to an unrelated place can replace instances under Rojo-managed paths.

## Validate a change

Run a clean build:

```bash
rojo build default.project.json -o REVOLVERARENA.rbxlx
```

Optionally validate the full mapped instance graph:

```bash
rojo sourcemap default.project.json --include-non-scripts -o sourcemap.json
```

Both outputs are ignored. Then use Studio Test or Test Here. For combat, spawn, death, or replication changes, also run a local server with at least two players.

## Common setup failures

### `git`, `rokit`, or `rojo` is not recognized

- Close and reopen the terminal after installing.
- Confirm Git and Rokit are on `PATH`.
- Run `rokit self-install` if Rokit was downloaded manually.
- Run `rokit install` again from the repository root.
- Confirm the terminal's working directory contains `rokit.toml`.

### Rojo reports the wrong version

Run `rokit install`, then `rojo --version`. The repository expects 7.7.0. Avoid letting a separate global Aftman or Rojo installation shadow Rokit's executable.

### The Studio plugin cannot connect

- Confirm `rojo serve default.project.json` is still running.
- Confirm the plugin and CLI are both Rojo major version 7.
- Try `localhost:34872` and check whether another process already uses that port.
- Restart Studio after installing or upgrading the plugin.
- Check local firewall prompts; local development should not require exposing Rojo beyond `127.0.0.1`.

### The Studio tree is incomplete or unexpected

- Build and open `REVOLVERARENA.rbxlx` once before live sync.
- Confirm Rojo is serving this repository's `default.project.json`.
- Read [ROBLOX_STUDIO.md](ROBLOX_STUDIO.md) before editing mapped instances.
- Disconnect before experimenting with a Studio-only copy.

### Asset changes do not appear

`assets/revolver/` is not mapped into the DataModel. Blender, FBX, glTF, and PNG files are source/reference assets. The live Tool is `src/starterpack/Revolver.rbxmx`; imported visual changes must be intentionally captured there and reviewed. See [the import notes](../assets/revolver/IMPORT.md).

### Generated files appear in Git status

The root `REVOLVERARENA.rbxlx`, `sourcemap.json`, Studio lock files, logs, environment files, and Blender backup files should be ignored. Do not use `git add -f` to bypass these rules without team agreement.
