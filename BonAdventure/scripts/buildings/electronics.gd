extends RefCounted
## Electronics store own script (docs/guides/MODULAR_TOWN.md, "Changing a building"): code steps for the
## electronics unit (scenes/town/electronics.scn).
## Bake:  godot --headless --path . --script res://tools/bake_unit.gd -- electronics
## Never rename or remove a baked step (add a new one that undoes it).
const STEPS := ["coplanar_gaps", "coplanar_gaps_2", "glass_windows"]

## Faces that shared a plane and flickered are set apart (10 Nov 2026,
## scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "electronics")

## Second pass: faces a first move brought into a new plane, and labels widened for translated
## text (10 Nov 2026, scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps_2(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "electronics", 2)


## Window glass as the shared window component (12 Nov 2026, docs/guides/WINDOWS.md).
func glass_windows(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/glass_windows.gd").migrate(town, "electronics")
