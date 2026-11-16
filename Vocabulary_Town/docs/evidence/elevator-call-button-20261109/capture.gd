extends SceneTree
## Rendered views of the elevator call buttons (9-10 Nov 2026): the hospital's floor 1 landing with
## the button dark, then lit while the car is called down from floor 2 (wide and close, noon and
## evening), the cabin buttons with one lit, the car's front wall with the number display, and the
## control tower's lobby landing and widened shaft. Needs a window
## (kept on top: a hidden window stops rendering); isolated HOME:
## HOME=<scratch>/home VT_FOCUS="hospital, airport" VT_SPAWN=none godot --path . --always-on-top --resolution 1400x900 --script res://docs/evidence/elevator-call-button-20261109/capture.gd [-- <out folder>]
## Writes <view>.png into the out folder (default: next to this script).
const ModularTown := preload("res://scripts/world/modular_town.gd")
var out := "res://docs/evidence/elevator-call-button-20261109/"
var camera: Camera3D

func _initialize(): run.call_deferred()

func shot(title: String) -> void:
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	var path := out.path_join(title + ".png")
	root.get_texture().get_image().save_png(path)
	print("CALL BUTTON CAPTURE: ", path)

func aim(button: Node3D, lift: Node3D, distance: float, side: float, look_at_button: bool) -> void:
	var face: Vector3 = button.global_basis.z.normalized()
	var across: Vector3 = face.cross(Vector3.UP).normalized()
	camera.global_position = button.global_position + face * distance + across * side + Vector3.UP * .25
	var doors: Vector3 = lift.to_global(Vector3(0, 1.6, -lift.hd()))
	camera.look_at(button.global_position if look_at_button else doors, Vector3.UP)

func run():
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.player.visible = false
	await process_frame
	for child in game.get_children():
		if child is CanvasLayer:
			child.visible = false
	var hospital: Node3D = ModularTown.building(game.apartment, "hospital", 1)
	var lift: Node3D = hospital.get_node_or_null("Elevator") if hospital != null else null
	var tower: Node3D = game.apartment.get_node_or_null("Airport/ControlTower/Interior/Elevator")
	if lift == null or tower == null:
		print("CALL BUTTON CAPTURE: the hospital or airport unit is not loaded")
		quit(1)
		return
	var button: Node3D = lift.landing_buttons[0]
	camera = Camera3D.new()
	root.add_child(camera)
	camera.make_current()
	camera.fov = 60
	if game.day_night != null:
		game.day_night.pause()
		game.day_night.set_time(12 * 60.0)
	aim(button, lift, 5.0, 1.6, false)
	await shot("landing-idle")
	# Send the car up, then call it back from floor 1 with the button.
	lift.call_elevator(1)
	while lift.current_floor != 1 or lift.state != lift.State.OPEN:
		await physics_frame
	button.press()
	for i in 20: await process_frame
	# The cabin panel on the front jamb seen from inside, floor 1's button lit (the destination).
	camera.global_position = lift.car.to_global(Vector3(-.6, 1.7, 1.2))
	camera.look_at(lift.car.to_global(Vector3(1.4, 1.5, -lift.cd() / 2.0)), Vector3.UP)
	await shot("cabin-buttons")
	# The car's front wall from the back: the number display centred above the door (rebuild).
	camera.global_position = lift.car.to_global(Vector3(-.4, 1.8, lift.cd() / 2.0 - .4))
	camera.look_at(lift.car.to_global(Vector3(0, 2.3, -lift.cd() / 2.0)), Vector3.UP)
	await shot("cabin-front")
	aim(button, lift, 5.0, 1.6, false)
	await shot("landing-lit")
	aim(button, lift, 1.1, .35, true)
	await shot("button-lit-close")
	if game.day_night != null:
		game.day_night.set_time(21 * 60.0)
	aim(button, lift, 1.1, .35, true)
	await shot("button-lit-evening")
	game.day_night.set_time(12 * 60.0) if game.day_night != null else null
	# Tower lobby: the car sent up, then called back with the lobby button.
	tower.call_elevator(1)
	while tower.current_floor != 1 or tower.state != tower.State.OPEN:
		await physics_frame
	tower.landing_buttons[0].press()
	for i in 20: await process_frame
	aim(tower.landing_buttons[0], tower, 2.2, 1.0, false)
	await shot("tower-landing")
	# The widened tower shaft fills the lobby wall up to the stair wall (rebuild).
	camera.global_position = tower.to_global(Vector3(1.0, 1.7, -tower.hd() - 4.2))
	camera.look_at(tower.to_global(Vector3(-.8, 1.9, -tower.hd())), Vector3.UP)
	await shot("tower-lobby-wide")
	aim(tower.landing_buttons[0], tower, 1.1, .35, true)
	await shot("tower-button-close")
	quit(0)
