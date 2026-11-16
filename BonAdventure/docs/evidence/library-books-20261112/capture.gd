extends SceneTree
## 12 Nov 2026 larger library books (step big_books): views of the library interior.
## HOME=<scratch> VT_FOCUS=library VT_SPAWN=none \
##   godot --path . --resolution 1280x800 --script res://docs/evidence/library-books-20261112/capture.gd -- <before|after>
## Writes <prefix>-<view>.png into this folder (overwrites them). Reads no saves.
## Views are in the library's own frame (RelocatedSites/Library, town units; scale 1.3 applied):
## [name, camera, target, fov (perspective) or size (orthographic top), top view?]
const SITE := "RelocatedSites/Library"
const VIEWS := [
	["entrance", Vector3(-15, 2.1, 38.3), Vector3(-15, 1.1, 52), 80.0, false],
	["west", Vector3(-12.2, 2.0, 39.2), Vector3(-20.9, 1.2, 46.5), 80.0, false],
	["east", Vector3(-17.8, 2.0, 39.2), Vector3(-9.1, 1.2, 46.5), 80.0, false],
	["rear", Vector3(-15, 2.2, 42.5), Vector3(-15, 1.2, 52.4), 82.0, false],
	["back-to-door", Vector3(-15, 2.4, 51.0), Vector3(-15, 1.0, 38), 82.0, false],
	["close-returns", Vector3(-13.0, 1.7, 46.9), Vector3(-13.0, 1.25, 49.55), 66.0, false],
	["close-covers", Vector3(-13.6, 1.0, 48.4), Vector3(-13.6, 0.75, 49.4), 50.0, false],
	["close-shelf", Vector3(-17.6, 1.7, 44.0), Vector3(-20.9, 1.5, 44.0), 60.0, false],
	["close-librarian", Vector3(-15.0, 1.7, 47.6), Vector3(-15.0, 1.1, 51.0), 55.0, false],
	["top", Vector3(-15, 40, 45), Vector3(-15, 0, 45), 12.0, true],
]
const HIDE_FOR_TOP := ["roof", "ceiling", "parapet", "awning", "canopy", "ridge", "beam", "pendant", "lintel", "fascia", "cornice"]

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var args := Array(OS.get_cmdline_user_args())
	var prefix: String = args[0] if args.size() > 0 else "after"
	var out := "res://docs/evidence/library-books-20261112"
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
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.current = true
	camera.far = 400.0
	var top: Node3D = game.apartment.get_node_or_null(SITE)
	if top == null:
		print("CAPTURE library missing (dev_focus?)"); quit(); return
	var hidden: Array = []
	for view in VIEWS:
		var is_top: bool = view[4]
		if is_top:
			for n in [top] + top.find_children("*", "Node3D", true, false):
				var nm := String(n.name).to_lower()
				if n is VisualInstance3D or n.get_child_count() > 0:
					for word in HIDE_FOR_TOP:
						if nm.contains(word) and n.visible:
							n.visible = false; hidden.append(n); break
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL if is_top else Camera3D.PROJECTION_PERSPECTIVE
		camera.size = float(view[3]) * 1.3
		camera.fov = float(view[3])
		var up := Vector3.UP
		if is_top: up = (top.global_basis * Vector3(0, 0, 1)).normalized()
		camera.global_position = top.to_global(view[1])
		camera.look_at(top.to_global(view[2]), up)
		game.player.global_position = camera.global_position - Vector3(0, 1.4, 0)
		for i in 8: await process_frame
		await RenderingServer.frame_post_draw
		var file := "%s/%s-%s.png" % [out, prefix, view[0]]
		root.get_texture().get_image().save_png(file)
		print("CAPTURE ", file)
		if is_top:
			for n in hidden: n.visible = true
			hidden.clear()
	print("CAPTURE done")
	quit()
