# Revolver asset and import notes

This directory contains the authoring, interchange, generated reference, and QA files for the signature RevolverArena weapon. It is not mapped into Roblox Studio by Rojo.

## Asset inventory

- `Revolver_Final.blend`: editable Blender source
- `Revolver_Final.fbx`: interchange export
- `stylized_low_poly_revolver.gltf`: generated low-poly reference with baked scale and rotation
- `stylized_low_poly_revolver_manifest.json`: node, mesh, and bounds metadata for the generated glTF
- `revolver_*.png`, `qa_revolver_*.png`, and `qa/`: review renders
- `../../tools/generate_low_poly_revolver.py`: generates the stylized glTF, manifest, and its review images

Blender backup files such as `.blend1` are ignored and must not be committed.

## Current Roblox Tool contract

The live Rojo-managed Tool is `src/starterpack/Revolver.rbxmx`. It currently contains:

- `Handle`
- visual MeshParts including `Frame`, `Barrel`, `Cylinder`, `Hammer`, `Trigger`, `Grip`, `FrontSight`, `EjectorRod`, and `CylinderRelease`
- a `Muzzle` attachment under `Barrel`
- `CylinderMotor`, `HammerMotor`, and `TriggerMotor`
- welds for static visual parts

Code discovers those names at runtime. Do not rename or remove them without coordinating with Gameplay / Backend and updating every consumer.

The client still contains a `BarrelTip` fallback for older Tool layouts, but the current authoritative muzzle reference is the `Muzzle` attachment. New asset work should preserve the attachment.

## Importing a new visual revision

1. Work from the approved Blender source and export FBX or glTF with transforms applied.
2. In Studio, use the 3D Importer and inspect scale, orientation, normals, materials, and pivots.
3. Place imported visual geometry inside a copy of the `Revolver` Tool.
4. Preserve `Handle`, `Muzzle`, and the three named Motor6Ds.
5. Weld static visual parts. Attach animated parts through their intended Motor6D and verify each pivot.
6. Set visual geometry to `CanCollide = false`, `CanQuery = false`, `CanTouch = false`, and `Massless = true` where appropriate.
7. Capture the approved hierarchy back into `src/starterpack/Revolver.rbxmx`.
8. Rebuild the project from disk and reconnect Rojo to prove the tracked file reproduces the Tool.
9. Test equip, first-person display, third-person display, fire, empty, reload, cylinder motion, hammer motion, trigger motion, roll, death, and respawn.
10. Update review renders and this file when the contract changes.

Do not treat a local Studio place or a published place as the only copy of the imported hierarchy.

## Generated low-poly reference

The generated glTF uses +Y up and -Z forward, with the weapon origin centered on the grip. Cylinder and hammer nodes retain local pivot translations; other rotation and scale are baked into vertex positions. The generator's gameplay scale is 80 percent of its original hero blockout.

To regenerate only that reference set:

```powershell
python tools/generate_low_poly_revolver.py
```

On macOS, use `python3` if needed. This script does not update `Revolver_Final.blend`, `Revolver_Final.fbx`, or `src/starterpack/Revolver.rbxmx`.

## Cloud assets and licensing

If a Studio import creates Roblox mesh or texture asset IDs, confirm that development and publishing accounts can use them. Record the source, license, uploader, and any required IDs in the pull request. Do not commit or upload third-party content without permission.
