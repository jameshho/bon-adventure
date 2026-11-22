extends SceneTree
## 21 Nov 2026: the stamp coin in the real town for the user's review (nothing is placed for good:
## the coins are added at run time only). Outside the library door: close (face-on and at an
## angle), near and from the street. Since 21 Nov 2026 (later) the face is the user's pig coin.
## HOME=<scratch> VT_FOCUS=library VT_SPAWN=library godot --path . --resolution 1280x800 \
##   --script res://docs/evidence/stamp-coin-20261121/town_view.gd
const OUT := "res://docs/evidence/stamp-coin-20261121"
const StampCoin := preload("res://scripts/world/stamp_coin.gd")

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 30: await process_frame
	if game.day_night:
		game.day_night.pause()
		game.day_night.set_time(11 * 60.0)
	var player: Node3D = game.player
	player.visible = false
	var camera := Camera3D.new()
	camera.fov = 65
	game.add_child(camera)
	camera.make_current()
	var forward: Vector3 = -player.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var side := forward.cross(Vector3.UP).normalized()
	# Outside: beside the path to the door, at chest height.
	var at := player.global_position + forward * 4.0 + side * 1.6 + Vector3.UP * 1.1
	var coin: Node3D = StampCoin.make("library")
	coin.preview = true
	game.add_child(coin)
	coin.global_position = at
	# Face-on close-ups: the spin stopped with the face turned to the camera.
	# (set_process(false) does not hold: the on-screen notifier turns it back on.)
	coin.spin_speed = 0.0
	coin.bob_height = 0.0
	var close_from := at - forward * 1.1 - side * 0.2 + Vector3.UP * 0.1
	coin.look_at(close_from, Vector3.UP)
	await view(camera, at, close_from, "town-coin-close")
	var three_quarter := at - forward * 1.3 + side * 0.9 + Vector3.UP * 0.25
	await view(camera, at, three_quarter, "town-coin-angle")
	coin.spin_speed = 0.35
	coin.bob_height = 0.08
	coin.rotation = Vector3.ZERO
	await view(camera, at, at - forward * 3.2 - side * 0.8 + Vector3.UP * 0.5, "town-outside-door")
	await view(camera, at, at - forward * 11.0 + Vector3.UP * 1.6, "town-outside-far")
	quit()

func view(camera: Camera3D, look: Vector3, from: Vector3, title: String) -> void:
	camera.global_position = from
	camera.look_at(look, Vector3.UP)
	for i in 25: await process_frame
	await shot(title)

func shot(title: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [ProjectSettings.globalize_path(OUT), title])
	print("wrote ", title)
