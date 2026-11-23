extends SceneTree
## Zoo plaza benches removed (base step `zoo_plaza_benches_removed`, 23 Nov 2026): no bench part
## stands on the zoo plaza, and a rendered view of the plaza is saved to this folder (plaza.png).
## Run with an isolated HOME (README), VT_FOCUS=all VT_SPAWN=none:
##   godot --path . --resolution 1200x800 --script res://docs/evidence/zoo-benches-20261123/verify.gd
const OUT := "res://docs/evidence/zoo-benches-20261123/"

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	root.size = Vector2i(1200, 800)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(40): await process_frame
	game.player.set_physics_process(false)
	var zoo: Node3D = game.apartment.get_node("ParkZoo")
	var left := 0
	for node in zoo.get_node("ZooZones").get_children():
		if String(node.name).begins_with("Park bench"): left += 1
	print("ZOO PLAZA BENCH PARTS LEFT: %d" % left)
	game.player.get_node("Visual").hide()
	for layer in game.find_children("*", "CanvasLayer", true, false): layer.hide()
	var cam := Camera3D.new()
	game.add_child(cam)
	cam.current = true
	cam.fov = 50
	cam.global_position = zoo.to_global(Vector3(-78, 3.5, 115.5))
	cam.look_at(zoo.to_global(Vector3(-78, 1.2, 104)))
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + "plaza.png")
	print("ZOO PLAZA BENCHES CHECK: %s" % ("PASS" if left == 0 else "FAIL"))
	game.free()
	quit()
