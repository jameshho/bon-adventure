extends SceneTree
## Builds the clay-style chick display (scripts/characters/chick_clay.gd) into
## scenes/animals/chick_clay.tscn. The zoo's display (base step chick_clay_display)
## names its mesh files, so a rebuild reaches the farm while the part names stay the same.
##   godot --headless --path . --script res://tools/build_chick_clay.gd
const ClaySave := preload("res://tools/clay_save.gd")

func _initialize() -> void:
	var started := Time.get_ticks_msec()
	var script: GDScript = load("res://scripts/characters/chick_clay.gd")
	if script == null or not script.can_instantiate():
		quit(1)
		return
	var model: Node3D = script.new().build_display()
	var tris := 0
	for mi in model.find_children("*", "MeshInstance3D", false, false):
		tris += mi.mesh.get_faces().size() / 3
		print("  %s: %d" % [mi.name, mi.mesh.get_faces().size() / 3])
	var result := ClaySave.save(model, "chick", "res://scenes/animals/chick_clay.tscn")
	print("CHICK CLAY: %d triangles, %d ms, save %s" % [tris, Time.get_ticks_msec() - started, error_string(result)])
	model.free()
	quit(result)
