extends SceneTree
## 13 Nov 2026: home doors back to their height before the house raise (home step
## `door_heights`), and the places the welcome tutorial's house act uses in the bigger home.
## Posed stills, no timers. Graphics run, isolated HOME, home only:
##   HOME=<scratch> VT_FOCUS=home VT_SPAWN=none godot --path . --resolution 1280x800 \
##     --script res://docs/evidence/home-doors-20261113/capture.gd
## Writes <view>.png here. Positions are the home site's local coordinates.
const OUT := "res://docs/evidence/home-doors-20261113"
const DoorAnimator := preload("res://scripts/core/door_animator.gd")
## [name, camera, target, player spot]
const VIEWS := [
	["bedroom-door", Vector3(-0.6, 2.6, 13.2), Vector3(-5.0, 1.9, 14.8), Vector3(-3.6, 0, 15.6)],
	["front-door", Vector3(2.6, 2.6, 23.5), Vector3(0.9, 2.0, 17.0), Vector3(-0.6, 0, 19.0)],
	["bathroom-curtain", Vector3(-6.0, 3.2, 5.6), Vector3(-9.6, 1.6, 10.2), Vector3(-7.4, 0, 8.6)],
	["wake-up", Vector3(-5.6, 5.6, 11.6), Vector3(-7.4, 0.6, 14.2), Vector3(-6.4, 0, 13.97)],
	["suite-door", Vector3(-1.2, 2.6, 1.6), Vector3(-3.7, 1.9, -3.0), Vector3(-2.6, 0, -1.4)],
	["suite-friend", Vector3(-3.4, 5.0, -3.6), Vector3(-5.2, 0.6, -6.0), Vector3(-5.0, 0, -5.4)],
]

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 6: await process_frame
	if game.day_night:
		game.day_night.pause()
		game.day_night.set_time(12 * 60.0)
	var site: Node3D = game.apartment.get_node("RelocatedSites/Home")
	var curtain: Node3D = site.get_node("Family bathtub/Shower curtain")
	if not game.doors[curtain].get("open", false):
		DoorAnimator.toggle(game, curtain)
	curtain.scale.x = float(game.doors[curtain].get("drawn", 1.0))
	game.hud.visible = false
	var cam := Camera3D.new()
	cam.fov = 60
	root.add_child(cam)
	for view in VIEWS:
		game.player.global_position = site.to_global(view[3])
		game.player.velocity = Vector3.ZERO
		game.player.reset_physics_interpolation()
		cam.global_position = site.to_global(view[1])
		cam.look_at(site.to_global(view[2]), Vector3.UP)
		cam.current = true
		for i in 4: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/%s.png" % [OUT, view[0]])
		print("CAPTURE ", view[0])
	quit()
