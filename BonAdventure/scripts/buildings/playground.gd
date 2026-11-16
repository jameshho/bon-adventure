extends RefCounted
## Playground own script (docs/guides/MODULAR_TOWN.md, "Changing a building"): code steps for the
## playground unit (scenes/town/playground.scn).
## Bake:  godot --headless --path . --script res://tools/bake_unit.gd -- playground
## Never rename or remove a baked step (add a new one that undoes it).
const STEPS := ["solid_roofs", "coplanar_gaps", "coplanar_gaps_2"]

## Collision for the decorative roofs and canopies (7 Nov 2026; scripts/buildings/roof_solids.gd).
func solid_roofs(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/roof_solids.gd").add(town, [
		"RelocatedSites/Playground/Playground equipment/West play tower/Roof eave",
		"RelocatedSites/Playground/Playground equipment/West play tower/Hipped roof",
		"RelocatedSites/Playground/Playground equipment/East play tower/Roof eave",
		"RelocatedSites/Playground/Playground equipment/East play tower/Hipped roof",
	])

## Faces that shared a plane and flickered are set apart (10 Nov 2026,
## scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "playground")

## Second pass: faces a first move brought into a new plane, and labels widened for translated
## text (10 Nov 2026, scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps_2(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "playground", 2)
