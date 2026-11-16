extends SceneTree
## Town-wide z-fighting scan (10 Nov 2026), geometry only, no rendering:
##   VT_FOCUS=all godot --headless --path . --script res://docs/evidence/coplanar-scan-20261110/scan.gd -- <out.tsv>
## Use an isolated HOME (Main may save progress). Lists every visible pair of fighting faces that
## scripts/buildings/coplanar_gaps.gd finds (same plane within 1 mm, same facing, different look,
## overlap of 2 × 2 cm or more), largest visible overlap first, with the building unit of each
## node, in town coordinates (Apartment space, +X west, +Z north), and the offset the
## `coplanar_gaps` steps would give each face (move_a/move_b, world metres; plan line
## "COPLANAR GAPS plan"). Writes only <out.tsv>.
func _initialize(): run.call_deferred()

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	for i in 4:
		await process_frame
	var finder = load("res://scripts/buildings/coplanar_gaps.gd").new()
	var plan: Dictionary = finder.plan(game.apartment)
	var town: Node3D = game.apartment
	print("CENSUS ", finder.census)
	var out := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	out.store_line("visible_m2\topen\tunit_a\tunit_b\tnormal\tcentre_town\tnode_a\tlook_a\tmove_a\tnode_b\tlook_b\tmove_b")
	var units := {}
	for r in plan.pairs:
		var fa: Array = r[1]
		var fb: Array = r[2]
		var c := Vector3.ZERO
		for p in fa[2]:
			c += p
		c = town.to_local(c / fa[2].size())
		var n: Vector3 = (town.global_transform.basis.inverse() * fa[0]).normalized()
		var ua: String = plan.unit_of[fa[4]]
		var ub: String = plan.unit_of[fb[4]]
		units[ua] = units.get(ua, 0) + 1
		out.store_line("%.4f\t%.2f\t%s\t%s\t(%.2f,%.2f,%.2f)\t(%.3f,%.3f,%.3f)\t%s\t%s\t%.3f\t%s\t%s\t%.3f" % [
			r[0], r[3], ua, ub, n.x, n.y, n.z, c.x, c.y, c.z,
			town.get_path_to(fa[4]), fa[3], plan.offsets.get(fa, 0.0),
			town.get_path_to(fb[4]), fb[3], plan.offsets.get(fb, 0.0)])
	out.close()
	print("COPLANAR pairs by unit ", units)
	print("COPLANAR pairs=%d unfixable=%d" % [plan.pairs.size(), plan.unfixed.size()])
	quit()
