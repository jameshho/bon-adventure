extends SceneTree
## Rendered views of the chapel (10 Nov 2026) at noon: the front at walking height, the front
## from further back, two aerials, the sanctuary toward the altar and toward the door, and a
## top-down view of the site. Needs a window; isolated HOME:
## HOME=<scratch>/home VT_FOCUS="chapel, airport" VT_SPAWN=none godot --path . --always-on-top --resolution 1400x1000 --script res://docs/evidence/chapel-20261110/capture.gd [-- <out folder> [hour]]
## Writes <view>.png into the out folder (default: next to this script).
## Camera spots are site-local (RelocatedSites/Chapel; town units): the chapel's door faces
## local -Z (town south), the sanctuary runs from z 69 (front) to z 81 (rear) around x 46.5.
const ModularTown := preload("res://scripts/world/modular_town.gd")
var out := "res://docs/evidence/chapel-20261110/"

func _initialize(): run.call_deferred()

func shot(title: String) -> void:
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	var path := out.path_join(title + ".png")
	root.get_texture().get_image().save_png(path)
	print("CHAPEL CAPTURE: ", path)

func run():
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	var hour := 12.0
	if args.size() > 1:
		hour = float(args[1])
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.player.visible = false
	await process_frame
	for child in game.get_children():
		if child is CanvasLayer:
			child.visible = false
	if game.day_night != null:
		game.day_night.pause()
		game.day_night.set_time(hour * 60.0)
	var site: Node3D = ModularTown.building(game.apartment, "chapel")
	if site == null:
		print("CHAPEL CAPTURE: the chapel unit is not loaded")
		quit(1)
		return
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.make_current()
	camera.fov = 62
	var views := [
		["front-walk", Vector3(46.5, 1.6, 60.5), Vector3(46.5, 4.2, 75)],
		["front-wide", Vector3(43.0, 3.0, 50.0), Vector3(46.5, 5.5, 75)],
		["aerial-front", Vector3(30.0, 18.0, 52.0), Vector3(46.5, 4.0, 75)],
		["aerial-rear", Vector3(64.0, 16.0, 96.0), Vector3(46.5, 4.0, 75)],
		["side-west", Vector3(62.0, 2.5, 72.0), Vector3(46.5, 4.0, 75)],
		["inside-altar", Vector3(46.5, 1.7, 69.8), Vector3(46.5, 1.8, 81)],
		["inside-door", Vector3(46.5, 2.2, 79.6), Vector3(46.5, 1.5, 68)],
		["inside-side", Vector3(42.6, 1.9, 70.4), Vector3(50.5, 2.3, 79.0)],
	]
	for view in views:
		camera.global_position = site.to_global(view[1])
		camera.look_at(site.to_global(view[2]), Vector3.UP)
		await shot(view[0])
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 40.0 * 1.3
	camera.far = 2000
	camera.global_position = site.to_global(Vector3(46.5, 120, 74))
	camera.look_at(site.to_global(Vector3(46.5, 0, 74)), Vector3(0, 0, 1))
	await shot("site-top")
	quit(0)
