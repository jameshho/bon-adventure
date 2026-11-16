extends RefCounted
## Hospital own script (docs/guides/MODULAR_TOWN.md, "Changing a building"): code steps for the
## hospital unit (scenes/town/hospital.scn).
## Bake:  godot --headless --path . --script res://tools/bake_unit.gd -- hospital
## Never rename or remove a baked step (add a new one that undoes it).
const STEPS := ["solid_roofs", "coplanar_gaps", "coplanar_gaps_2", "rename_doctor_plush"]

## Collision for the decorative roofs and canopies (7 Nov 2026; scripts/buildings/roof_solids.gd).
func solid_roofs(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/roof_solids.gd").add(town, [
		"Map facades/HOSPITAL/Hospital single canopy",
		"Map facades/HOSPITAL/Hospital canopy soffit",
	])

## Faces that shared a plane and flickered are set apart (10 Nov 2026,
## scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "hospital")

## Second pass: faces a first move brought into a new plane, and labels widened for translated
## text (10 Nov 2026, scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps_2(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "hospital", 2)

## Baked on 16 Nov 2026 (BonBon rename, user): gave the doctor plush named after the player
## character's old name its current name, "BonBonDoctor". The old name is no longer kept in
## the code (user: no trace of it), so a new run does nothing; nothing looks it up by name.
func rename_doctor_plush(_town: Node3D, _game) -> void:
	pass
