extends SceneTree
## 17 Nov 2026 library readable signs (scripts/buildings/library.gd step readable_signs): eye-level
## views at a phone's 720-line 3D size (landscape 1280 x 720, 70° view), signs in the default
## foreign language (Spanish, the longest).
## HOME=<scratch> VT_FOCUS=library VT_SPAWN=none \
##   godot --path . --resolution 1280x720 --script res://docs/evidence/library-signs-20261117/capture.gd -- <prefix>
## Writes <prefix>-<view>.png into this folder. Reads no saves.
const OUT := "res://docs/evidence/library-signs-20261117"
const SITE := "RelocatedSites/Library"
## [name, eye, look-at] in the library source frame (doorway x -15 z 37.7; eye 1.55 = 2 m in town).
const VIEWS := [
	["doorway", Vector3(-15, 1.55, 38.6), Vector3(-15, 1.6, 50)],
	["mid-west", Vector3(-13.0, 1.55, 44.0), Vector3(-20.8, 2.6, 46.6)],
	["mid-east", Vector3(-17.0, 1.55, 44.0), Vector3(-9.1, 2.6, 46.6)],
	["mid-rear", Vector3(-15, 1.55, 44.5), Vector3(-15, 2.4, 52.3)],
	["mid-front", Vector3(-15, 1.55, 46.0), Vector3(-12.5, 2.4, 37.7)],
]

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var prefix: String = args[0] if args.size() > 0 else "after"
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
	var site: Node3D = game.apartment.get_node_or_null(SITE)
	if site == null:
		print("CAPTURE library missing (dev_focus?)"); quit(); return
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.current = true
	camera.fov = 70
	camera.near = .05
	for view in VIEWS:
		camera.global_position = site.to_global(view[1])
		camera.look_at(site.to_global(view[2]), Vector3.UP)
		await shot("%s-%s" % [prefix, view[0]])
	quit()

func shot(title: String) -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [OUT, title])
	print("CAPTURE ", title)
