extends SceneTree
## 13 Nov 2026: the home's toilet rooms and curtains, and the welcome tutorial's fruit in the
## supermarket (home step `toilet_rooms_and_curtains`, supermarket step `tutorial_fruit`). Posed
## stills, no timers. Graphics run, isolated HOME, home and supermarket only:
##   HOME=<scratch> VT_FOCUS=home,supermarket VT_SPAWN=none godot --path . --resolution 1280x800 \
##     --script res://docs/evidence/home-tutorial-20261113/capture.gd -- [prefix]
## Writes <prefix><view>.png here. Home views use the home site's local coordinates, store views
## the supermarket interior's.
const OUT := "res://docs/evidence/home-tutorial-20261113"
const DoorAnimator := preload("res://scripts/core/door_animator.gd")
## [name, camera, target] in the home site.
const HOME_VIEWS := [
	["suite-toilet", Vector3(-10.3, 3.4, -2.4), Vector3(-5.6, 0.7, 1.0)],
	["suite-room", Vector3(-5.6, 3.6, 2.5), Vector3(-9.0, 0.6, -2.0)],
	["family-toilet", Vector3(-5.6, 3.4, 10.4), Vector3(-10.4, 0.7, 3.9)],
	["family-room", Vector3(-10.4, 3.6, 3.6), Vector3(-6.0, 0.8, 9.5)],
	["east-toilet", Vector3(19.0, 3.4, 13.4), Vector3(21.7, 0.7, 8.2)],
	["east-room", Vector3(25.4, 3.6, 13.4), Vector3(20.0, 0.8, 8.4)],
	["suite-door", Vector3(-8.0, 2.8, -6.0), Vector3(-8.0, 1.2, 2.0)],
	["family-door", Vector3(-2.6, 2.8, 9.5), Vector3(-10.0, 1.2, 7.0)],
	["east-door", Vector3(16.0, 2.8, 10.5), Vector3(25.0, 1.2, 10.5)],
	["suite-plan", Vector3(-8.0, 6.9, 0.0), Vector3(-8.0, 0.0, 0.01)],
	["family-plan", Vector3(-8.0, 6.9, 7.0), Vector3(-8.0, 0.0, 7.01)],
	["east-plan", Vector3(22.2, 6.9, 10.75), Vector3(22.2, 0.0, 10.76)],
]
## Window curtains: [wall point, inward] (home_furnishing.gd WINDOWS).
const CURTAINS := [
	[Vector2(-11, -7.5), Vector2(1, 0)], [Vector2(-6.75, -12), Vector2(0, 1)], [Vector2(-2.5, -9.0), Vector2(-1, 0)],
	[Vector2(24, -3), Vector2(0, 1)], [Vector2(26, 2.0), Vector2(-1, 0)],
	[Vector2(-11, 14.0), Vector2(1, 0)],
	[Vector2(21, 23), Vector2(0, -1)], [Vector2(26, 18.5), Vector2(-1, 0)],
]
## [name, camera, target] in the supermarket interior.
const STORE_VIEWS := [
	["fruit-entrance", Vector3(-30.0, 3.4, 36.0), Vector3(-22.0, 1.0, 45.0)],
	["fruit-close", Vector3(-26.0, 2.6, 40.5), Vector3(-22.0, 1.0, 45.0)],
	["fruit-door", Vector3(-33.0, 2.6, 31.8), Vector3(-30.2, 1.0, 38.4)],
	["fruit-table", Vector3(-31.7, 2.0, 36.9), Vector3(-30.2, 1.0, 38.4)],
]

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var prefix: String = args[0] if args.size() > 0 else ""
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 6: await process_frame
	if game.day_night:
		game.day_night.pause()
		game.day_night.set_time(12 * 60.0)
	game.hud.visible = false
	var site: Node3D = game.apartment.get_node("RelocatedSites/Home")
	# Bathroom doors open, so the doorway shows.
	for door in game.doors:
		if is_instance_valid(door) and site.is_ancestor_of(door) and String(door.name).to_lower().contains("door") \
				and not game.doors[door].get("open", false):
			DoorAnimator.toggle(game, door)
	for i in 60: await process_frame
	var cam := Camera3D.new()
	cam.fov = 62
	cam.near = 0.05
	root.add_child(cam)
	game.player.global_position = site.to_global(Vector3(0, 0, 30))
	for view in HOME_VIEWS:
		await _shot(cam, site.to_global(view[1]), site.to_global(view[2]), prefix + view[0])
	# The tutorial's family bathtub with its curtain drawn (act 1), from the doorway.
	var curtain: Node3D = site.get_node_or_null("Family bathtub/Shower curtain")
	if curtain != null:
		if not game.doors[curtain].get("open", false):
			DoorAnimator.toggle(game, curtain)
		for i in 60: await process_frame
		await _shot(cam, site.to_global(Vector3(-3.4, 2.8, 9.5)), site.to_global(Vector3(-10.0, 1.6, 9.0)), prefix + "family-curtain-drawn")
		DoorAnimator.toggle(game, curtain)
		for i in 60: await process_frame
	for i in CURTAINS.size():
		var wall: Vector2 = CURTAINS[i][0]
		var inward: Vector2 = CURTAINS[i][1]
		var side := Vector2(-inward.y, inward.x)
		var eye := wall + inward * 4.2 + side * 1.2
		await _shot(cam, site.to_global(Vector3(eye.x, 2.6, eye.y)), site.to_global(Vector3(wall.x, 2.9, wall.y)), "%scurtain-%d" % [prefix, i + 1])
	var store: Node3D = game.apartment.get_node_or_null("RelocatedSites/Supermarket/MarketInterior")
	if store != null:
		for view in STORE_VIEWS:
			await _shot(cam, store.to_global(view[1]), store.to_global(view[2]), prefix + view[0])
	quit()

func _shot(cam: Camera3D, eye: Vector3, target: Vector3, title: String) -> void:
	cam.global_position = eye
	cam.look_at(target, Vector3.UP if absf((target - eye).normalized().y) < 0.95 else Vector3.FORWARD)
	cam.current = true
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [ProjectSettings.globalize_path(OUT), title])
	print("CAPTURE ", title)
