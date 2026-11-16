extends SceneTree
## 14 Nov 2026: plants cleared from the home's walkways and doorways (home step
## `clear_walkway_plants`) and only the tutorial's plushes left in the house
## (data/house_characters.json `in_house`). Posed stills, no timers. Graphics run, isolated HOME:
##   HOME=<scratch> VT_FOCUS=home VT_SPAWN=none godot --path . --resolution 1280x800 \
##     --script res://docs/evidence/home-plants-20261114/capture.gd -- <prefix> [view,view...]
## Writes <prefix><view>.png here. Positions are the home site's local coordinates.
const OUT := "res://docs/evidence/home-plants-20261114"
const DoorAnimator := preload("res://scripts/core/door_animator.gd")
## [name, camera, target]
const VIEWS := [
	["suite-door", Vector3(-1.2, 2.6, 2.6), Vector3(-3.7, 1.0, -3.0)],
	["suite-bath-door", Vector3(-5.0, 2.8, -7.5), Vector3(-7.6, 0.8, -2.0)],
	["east-hall", Vector3(17.4, 2.8, 13.7), Vector3(17.4, 0.4, 7.0)],
	["master-door", Vector3(21.5, 2.8, 3.0), Vector3(17.6, 0.6, 7.5)],
	["study-door", Vector3(21.5, 2.8, 18.5), Vector3(17.6, 0.6, 14.0)],
	["suite-bath-inside", Vector3(-9.6, 2.8, 1.8), Vector3(-7.0, 0.4, -3.0)],
	["family-door", Vector3(-2.4, 2.8, 8.4), Vector3(-6.4, 0.6, 8.6)],
	["yellow-door", Vector3(-1.4, 2.8, 12.6), Vector3(-5.0, 1.0, 14.8)],
	["entry", Vector3(1.0, 3.0, 16.2), Vector3(8.0, 0.6, 12.0)],
	["front-path", Vector3(2.2, 3.4, 29.0), Vector3(1.0, 1.0, 17.0)],
	["terrace", Vector3(6.0, 3.4, -9.0), Vector3(0.0, 0.8, -3.0)],
]

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var prefix: String = args[0] if args.size() > 0 else ""
	var only: PackedStringArray = args[1].split(",") if args.size() > 1 else PackedStringArray()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 6: await process_frame
	if game.day_night:
		game.day_night.pause()
		game.day_night.set_time(12 * 60.0)
	game.hud.visible = false
	var site: Node3D = game.apartment.get_node("RelocatedSites/Home")
	for door in game.doors:
		if is_instance_valid(door) and site.is_ancestor_of(door) and String(door.name).to_lower().contains("door") \
				and not String(door.name).to_lower().contains("garage") and not game.doors[door].get("open", false):
			DoorAnimator.toggle(game, door)
	game.player.global_position = site.to_global(Vector3(30, 0, 40))
	for i in 60: await process_frame
	var cam := Camera3D.new()
	cam.fov = 62
	cam.near = 0.05
	root.add_child(cam)
	for view in VIEWS:
		if not only.is_empty() and not only.has(view[0]):
			continue
		await _shot(cam, site.to_global(view[1]), site.to_global(view[2]), prefix + view[0])
	quit()

func _shot(cam: Camera3D, eye: Vector3, target: Vector3, title: String) -> void:
	cam.global_position = eye
	cam.look_at(target, Vector3.UP if absf((target - eye).normalized().y) < 0.95 else Vector3.FORWARD)
	cam.current = true
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [ProjectSettings.globalize_path(OUT), title])
	print("CAPTURE ", title)
