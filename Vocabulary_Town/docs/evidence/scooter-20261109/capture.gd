extends SceneTree
## In-town views of the scooter (9 Nov 2026): parked in the restaurant lot, BonBon getting on,
## riding (game loop, scooter stepped by the script) and braking.
##   HOME=<scratch>/home VT_FOCUS=restaurants VT_SPAWN=none godot --path . --resolution 1200x900 \
##     --script res://docs/evidence/scooter-20261109/capture.gd -- <out_dir>
## Writes PNGs to out_dir only; run with an isolated HOME so study progress is not saved.
var out := "user://scooter-town"
var game

func _initialize() -> void:
	run.call_deferred()

func shot(title: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(title + ".png"))
	print("SHOT ", title)

func ride(bike, ticks: int, gas: float, steer: float, brake: float) -> void:
	for i in range(ticks):
		await physics_frame
		# A fresh HOME opens the help overlay, during which Main parks the vehicle (occupied false).
		bike.occupied = true
		bike.drive_step(1.0 / 60, gas, steer, brake)

func wait(ticks: int) -> void:
	for i in range(ticks): await physics_frame

func run() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty(): out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	root.size = Vector2i(1200, 900)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await wait(30)
	var bike: DriveableVehicle = game.apartment.get_node("Vehicles/Motorcycle")
	var player = game.player
	# Stand at the mounting step, camera behind-left of the scooter.
	player.global_position = bike.boarding_step_point() + Vector3(0, .2, 0)
	player.camera_yaw = bike.global_basis.orthonormalized().get_euler().y - 2.2
	player.camera_pitch = -.32
	player.camera_distance = 7.0
	await wait(40)
	await shot("parked-in-lot")
	game.toggle_vehicle()
	await wait(int(bike.boarding_duration * 60 * .62))
	await shot("getting-on")
	await wait(80)
	player.camera_yaw = bike.global_basis.orthonormalized().get_euler().y - 2.4
	await wait(30)
	await shot("seated-in-lot")
	# Ride out: the scooter's own input reads the real keyboard, so it is stepped here instead,
	# on each physics tick before BonBon's (the order the game uses): gas, then a left turn, then brakes.
	bike.set_physics_process(false)
	# Back out of the stall swinging the nose round, then ride off along the lot in a left turn.
	await ride(bike, 110, -1, 1, 0)
	await ride(bike, 40, 0, 0, 1)
	await ride(bike, 60, 1, 0, 0)
	player.camera_yaw = bike.global_basis.orthonormalized().get_euler().y + PI * .5 + .5
	await ride(bike, 45, .7, -1, 0)
	print("LEAN ", bike.lean, " speed ", bike.current_speed)
	await shot("riding-turn")
	await ride(bike, 30, 1, 0, 0)
	player.camera_yaw = bike.global_basis.orthonormalized().get_euler().y - PI * .5
	await ride(bike, 25, 0, 0, 1)
	print("BRAKE accel ", bike.longitudinal_accel)
	await shot("braking")
	bike.set_physics_process(true)
	quit()
