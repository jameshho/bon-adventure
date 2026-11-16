extends SceneTree
## Builds the clay-style kangaroo display (scripts/characters/kangaroo_clay.gd) into
## scenes/animals/kangaroo_clay.tscn. The base step `kangaroo_clay_display` places that scene in the zoo.
##   godot --headless --path . --script res://tools/build_kangaroo_clay.gd
const ClaySave := preload("res://tools/clay_save.gd")

func _initialize() -> void:
	var started := Time.get_ticks_msec()
	var script: GDScript = load("res://scripts/characters/kangaroo_clay.gd")
	if script == null or not script.can_instantiate():
		quit(1)
		return
	var model: Node3D = script.new().build_display()
	var tris := 0
	for mi in model.find_children("*", "MeshInstance3D", false, false):
		tris += mi.mesh.get_faces().size() / 3
	var result := ClaySave.save(model, "kangaroo", "res://scenes/animals/kangaroo_clay.tscn")
	print("KANGAROO CLAY: %d triangles, %d ms, save %s" % [tris, Time.get_ticks_msec() - started, error_string(result)])
	model.free()
	quit(result)
