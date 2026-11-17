extends SceneTree
## Builds the clay-style tiger display (scripts/characters/tiger_clay.gd) into
## scenes/animals/tiger_clay.tscn. The zoo's tiger uses its rig: rebuild that afterwards with
## tools/build_tiger_clay_rig.gd (base step tiger_clay_walks).
##   godot --headless --path . --script res://tools/build_tiger_clay.gd
const ClaySave := preload("res://tools/clay_save.gd")

func _initialize() -> void:
	var started := Time.get_ticks_msec()
	var script: GDScript = load("res://scripts/characters/tiger_clay.gd")
	if script == null or not script.can_instantiate():
		quit(1)
		return
	var model: Node3D = script.new().build_display()
	var tris := 0
	for mi in model.find_children("*", "MeshInstance3D", false, false):
		var part: int = mi.mesh.get_faces().size() / 3
		print("  %s: %d triangles" % [mi.name, part])
		tris += part
	var result := ClaySave.save(model, "tiger", "res://scenes/animals/tiger_clay.tscn")
	print("TIGER CLAY: %d triangles, %d ms, save %s" % [tris, Time.get_ticks_msec() - started, error_string(result)])
	model.free()
	quit(result)
