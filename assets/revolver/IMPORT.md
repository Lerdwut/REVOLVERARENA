# RevolverArena signature revolver

`stylized_low_poly_revolver.gltf` is the production low-poly mesh export. It has
seven separate named nodes: Handle, Frame, Barrel, Cylinder, Hammer, Trigger,
and FrontSight. It uses +Y up, -Z forward, and Roblox-stud-sized geometry.
Materials are simple gunmetal, lighter steel, and brown wood; no textures.
The export is scaled to 80% of the initial hero blockout for better Roblox
first-person readability and grip proportions.

The weapon origin is the center of the grip. Cylinder and Hammer have their own
local pivots in the glTF node hierarchy (both animate around +X). Scale and
rotation are already baked into the geometry; node translations are retained
only to place these animation pivots.

QA renders: `revolver_first_person.png`, `revolver_side.png`,
`revolver_perspective.png`, and `revolver_front.png`. The contact sheet is
`revolver_review.png`. Mesh counts and world bounds are in
`stylized_low_poly_revolver_manifest.json`.

The Rojo-managed `src/starterpack/Revolver.rbxmx` is a gameplay-ready Part
approximation of the same silhouette. It remains directly visible in Studio
while Rojo is connected and preserves Handle, BarrelTip, CylinderMotor,
HammerMotor, and welds for the current scripts.

To replace its Parts with the imported mesh later, use Studio's 3D Importer for
the glTF, then keep the imported MeshParts inside the Revolver Tool. Preserve
the Handle and BarrelTip gameplay reference parts, weld the static objects, and
use Motor6Ds at the Cylinder and Hammer pivots. Set the visual MeshParts to
CanCollide=false, CanQuery=false, CanTouch=false, and Massless=true. Test the
Tool in multiplayer before removing the Part approximation.
