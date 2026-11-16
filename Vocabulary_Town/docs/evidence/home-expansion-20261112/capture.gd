extends SceneTree
## Rendered views of the bigger home (12 Nov 2026, scripts/buildings/home_expansion.gd) at noon:
## a top-down plan without the roof (doors shut, then all home doors open to show their swings),
## two aerials, the hot tub, and the new and changed rooms. Needs a window; isolated HOME:
## HOME=<scratch>/home VT_FOCUS=home VT_SPAWN=none godot --path . --resolution 1400x1000 \
##   --script res://docs/evidence/home-expansion-20261112/capture.gd [-- <out folder> [hour]]
## Writes <view>.png into the out folder (default: next to this script). Read-only: saves nothing.
## Camera spots are site-local (RelocatedSites/Home, town units; +Z street side, -Z backyard).
const ModularTown := preload("res://scripts/world/modular_town.gd")
var out := "res://docs/evidence/home-expansion-20261112/"

func _initialize(): run.call_deferred()

func shot(title: String) -> void:
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	var path := out.path_join(title + ".png")
	root.get_texture().get_image().save_png(path)
	print("HOME CAPTURE: ", path)

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
	var site: Node3D = ModularTown.building(game.apartment, "home")
	var roof: Node3D = site.get_node("Home roof")
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.make_current()
	camera.fov = 66
	camera.near = .05
	# Plan views.
	roof.visible = false
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 44.0 * 1.3
	camera.far = 2000
	camera.global_position = site.to_global(Vector3(7.5, 120, 4))
	camera.look_at(site.to_global(Vector3(7.5, 0, 4)), Vector3(0, 0, -1))
	await shot("plan-top")
	var opened := []
	for leaf in game.doors:
		if is_instance_valid(leaf) and site.is_ancestor_of(leaf) and str(game.doors[leaf].get("type", "")) == "hinge":
			opened.append([leaf, leaf.rotation.y])
			leaf.rotation.y += float(game.doors[leaf].angle)
	await shot("plan-top-doors-open")
	camera.size = 16.0 * 1.3
	camera.global_position = site.to_global(Vector3(20.0, 120, 8.0))
	camera.look_at(site.to_global(Vector3(20.0, 0, 8.0)), Vector3(0, 0, -1))
	await shot("plan-east-doors-open")
	camera.global_position = site.to_global(Vector3(-6.0, 120, 2.0))
	camera.look_at(site.to_global(Vector3(-6.0, 0, 2.0)), Vector3(0, 0, -1))
	await shot("plan-west-doors-open")
	for entry in opened:
		entry[0].rotation.y = entry[1]
	roof.visible = true
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	var views := [
		["aerial-front-east", Vector3(42.0, 24.0, 44.0), Vector3(8.0, 1.0, 4.0)],
		["aerial-back-west", Vector3(-20.0, 20.0, -34.0), Vector3(6.0, 0.0, -6.0)],
		["street-front", Vector3(10.0, 2.2, 36.0), Vector3(10.0, 3.0, 10.0)],
		["hot-tub", Vector3(-4.5, 3.6, -18.5), Vector3(2.0, 0.0, -10.5)],
		["inside-master", Vector3(17.0, 2.4, 6.8), Vector3(22.5, 0.8, -1.5)],
		["inside-hall", Vector3(17.2, 2.0, 13.5), Vector3(17.2, 1.4, 7.0)],
		["inside-bathroom", Vector3(19.0, 2.4, 8.0), Vector3(24.5, 0.6, 12.5)],
		["inside-study", Vector3(17.0, 2.4, 14.6), Vector3(23.5, 0.8, 21.0)],
		["inside-kitchen-hall-door", Vector3(7.0, 2.4, 9.0), Vector3(16.0, 1.4, 12.5)],
		["inside-guest-suite", Vector3(-3.2, 2.5, -3.5), Vector3(-8.5, 0.6, -10.5)],
		["inside-guest-bath", Vector3(-5.6, 2.5, 2.6), Vector3(-9.5, 0.5, -1.2)],
		["inside-family-bath", Vector3(-5.6, 2.5, 10.6), Vector3(-9.0, 0.5, 3.6)],
		["eaves-west", Vector3(-19.0, 3.0, 8.0), Vector3(-11.0, 4.6, 4.0)],
		["inside-living", Vector3(-4.0, 2.5, 15.5), Vector3(6.0, 0.8, 2.0)],
		["inside-kitchen", Vector3(2.0, 2.5, 2.0), Vector3(14.0, 0.8, 11.0)],
		["inside-dining", Vector3(4.0, 2.5, 12.0), Vector3(13.0, 0.8, -1.0)],
		["inside-yellow-bedroom", Vector3(-5.6, 2.5, 16.4), Vector3(-9.5, 0.6, 11.5)],
		["inside-garage", Vector3(15.2, 2.6, 22.3), Vector3(8.0, 0.8, 14.5)],
	]
	for view in views:
		camera.global_position = site.to_global(view[1])
		camera.look_at(site.to_global(view[2]), Vector3.UP)
		await shot(view[0])
	quit(0)
