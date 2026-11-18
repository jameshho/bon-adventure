extends SceneTree
## 17 Nov 2026 library top-down view with the roof removed (the 11 Nov "top" view showed the roof:
## render culling batches roof meshes, so hiding nodes does not remove them; this clips them with
## the camera's near plane instead).
## HOME=<scratch> VT_FOCUS=library VT_SPAWN=none \
##   godot --path . --resolution 1280x800 --script res://docs/evidence/library-topdown-20261117/capture.gd
## Writes top.png into this folder. Reads no saves.
const SITE := "RelocatedSites/Library"
const CEILING_BOTTOM_Y := 6.65  # world Y just under "Finished ceiling" (6.72)
const SIZE := 26.0

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 4: await process_frame
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	game.player.visible = false
	game.hud.hide()
	if game.day_night:
		game.day_night.pause()
		game.day_night.set_time(12 * 60.0)
	var top: Node3D = game.apartment.get_node_or_null(SITE)
	if top == null:
		print("CAPTURE library missing (dev_focus?)"); quit(); return
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.current = true
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = SIZE
	camera.far = 400.0
	# Low camera: render culling hides small props by distance, so a high one loses the furniture.
	camera.global_position = top.to_global(Vector3(-15, 12, 45))
	camera.look_at(top.to_global(Vector3(-15, 0, 45)), (top.global_basis * Vector3(0, 0, 1)).normalized())
	camera.near = camera.global_position.y - CEILING_BOTTOM_Y
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	var file := "res://docs/evidence/library-topdown-20261117/top.png"
	root.get_texture().get_image().save_png(file)
	print("CAPTURE ", file)
	quit()
