extends SceneTree
## 17 Nov 2026 library refresh: before/after views (top-down with the roof clipped, as in
## docs/evidence/library-topdown-20261117/capture.gd, plus two eye-level views).
## HOME=<scratch> VT_FOCUS=library VT_SPAWN=none \
##   godot --path . --resolution 1280x800 --script res://docs/evidence/library-refresh-20261117/capture.gd -- <before|after>
## Writes <prefix>-top.png, <prefix>-entrance.png, <prefix>-rear.png into this folder. Reads no saves.
const OUT := "res://docs/evidence/library-refresh-20261117"
const SITE := "RelocatedSites/Library"
const CEILING_BOTTOM_Y := 6.65  # world Y just under "Finished ceiling" (6.72)

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
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 26.0
	camera.far = 400.0
	camera.global_position = site.to_global(Vector3(-15, 12, 45))
	camera.look_at(site.to_global(Vector3(-15, 0, 45)), (site.global_basis * Vector3(0, 0, 1)).normalized())
	camera.near = camera.global_position.y - CEILING_BOTTOM_Y
	await shot("%s-top" % prefix)
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 70
	camera.near = .05
	for view in [["entrance", Vector3(-15, 1.55, 38.6), Vector3(-15, 1.0, 50)], ["rear", Vector3(-19.4, 2.0, 51.6), Vector3(-11.5, .6, 41.5)]]:
		camera.global_position = site.to_global(view[1])
		camera.look_at(site.to_global(view[2]), Vector3.UP)
		await shot("%s-%s" % [prefix, view[0]])
	quit()

func shot(title: String) -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [OUT, title])
	print("CAPTURE ", title)
