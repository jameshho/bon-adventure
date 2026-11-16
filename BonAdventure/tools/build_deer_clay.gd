extends SceneTree
## Builds the clay-style deer display (scripts/characters/deer_clay.gd) into
## scenes/animals/deer_clay.tscn. The base step `deer_clay_display` places that scene in the zoo.
##   godot --headless --path . --script res://tools/build_deer_clay.gd
const ClaySave := preload("res://tools/clay_save.gd")

func _initialize() -> void:
	var started := Time.get_ticks_msec()
	var script: GDScript = load("res://scripts/characters/deer_clay.gd")
	if script == null or not script.can_instantiate():
		quit(1)
		return
	var model: Node3D = script.new().build_display()
	var tris := 0
	for mi in model.find_children("*", "MeshInstance3D", false, false):
		tris += mi.mesh.get_faces().size() / 3
	var result := ClaySave.save(model, "deer", "res://scenes/animals/deer_clay.tscn")
	print("DEER CLAY: %d triangles, %d ms, save %s" % [tris, Time.get_ticks_msec() - started, error_string(result)])
	model.free()
	quit(result)
