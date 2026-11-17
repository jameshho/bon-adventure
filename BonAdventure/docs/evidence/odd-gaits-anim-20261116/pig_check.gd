extends SceneTree
## The pig's walk with clay_animator.gd as it is now against the animator before the gait
## options of 16 Nov 2026 (its source passed as a file, e.g. from
## `git show 6815754:BonAdventure/scripts/characters/clay_animator.gd > old.gd`): two rigged
## pigs with the same settings and state, every bone pose compared at 8 phases of the walk.
## Expected: 0.0 at every phase (notes.md). Headless, loads only the pig rig:
##   godot --headless --path . --script res://docs/evidence/odd-gaits-anim-20261116/pig_check.gd -- old.gd
func _initialize() -> void:
	var old := GDScript.new()
	old.source_code = FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0])
	old.reload()
	var a: Node3D = load("res://scenes/animals/pig_clay_rigged.scn").instantiate()
	var b: Node3D = load("res://scenes/animals/pig_clay_rigged.scn").instantiate()
	var an_a = a.get_node("ClayAnimator")
	var values := {}
	for p in an_a.get_property_list():
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and p.usage & PROPERTY_USAGE_STORAGE:
			values[p.name] = an_a.get(p.name)
	b.get_node("ClayAnimator").set_script(old)
	var n := 0
	for key in values:
		if key in b.get_node("ClayAnimator"):
			b.get_node("ClayAnimator").set(key, values[key]); n += 1
	print("copied ", n, " of ", values.size())
	b.name = "Twin"
	root.add_child(a); root.add_child(b)
	await process_frame
	for r in [a, b]:
		var an = r.get_node("ClayAnimator")
		an.set_process(false)
		an.speed_override = 0.6; an.speed = 0.6; an.walk = 1.0
		an.set("_clock", 5.0); an.set("_next_look", 50.0)
	for k in 8:
		for r in [a, b]:
			r.get_node("ClayAnimator").phase = k / 8.0
			r.get_node("ClayAnimator").advance(0.0)
		var sa: Skeleton3D = a.get_node("Skeleton3D"); var sb: Skeleton3D = b.get_node("Skeleton3D")
		var worst := 0.0
		var which := ""
		for i in sa.get_bone_count():
			var ta := sa.get_bone_pose(i); var tb := sb.get_bone_pose(i)
			var d := (ta.origin - tb.origin).length() + (ta.basis.x - tb.basis.x).length() + (ta.basis.y - tb.basis.y).length() + (ta.basis.z - tb.basis.z).length()
			if d > worst: worst = d; which = sa.get_bone_name(i)
		print("pig phase %.3f max bone difference %s (%s)" % [k / 8.0, worst, which])
	quit()
