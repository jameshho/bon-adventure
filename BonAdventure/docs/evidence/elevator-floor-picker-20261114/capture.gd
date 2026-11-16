extends SceneTree
## Rendered views of the elevator floor picker (14 Nov 2026; docs/guides/HOSPITAL_THREE_FLOORS.md
## "Floor picker"): the player in the hospital car and in the control-tower car, E at the cabin
## panel, the camera's close-up with the slim title bar and ✕ (a button lit in the hospital view).
## Needs a window (kept on top: a hidden window stops rendering); isolated HOME:
## HOME=<scratch>/home VT_FOCUS="hospital, airport" VT_SPAWN=none godot --path . --always-on-top --resolution 1400x900 --script res://docs/evidence/elevator-floor-picker-20261114/capture.gd [-- <out folder>]
## Writes <view>.png into the out folder (default: next to this script).
const ModularTown := preload("res://scripts/world/modular_town.gd")
const Interactable := preload("res://scripts/core/interactable.gd")
var out := "res://docs/evidence/elevator-floor-picker-20261114/"
var game

func _initialize(): run.call_deferred()

func shot(title: String) -> void:
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	var path := out.path_join(title + ".png")
	root.get_texture().get_image().save_png(path)
	print("FLOOR PICKER CAPTURE: ", path)

func open_on(lift: Node3D) -> void:
	var player: CharacterBody3D = game.player
	player.velocity = Vector3.ZERO
	player.global_position = lift.to_global(Vector3(minf(.8, lift.cw() / 4.0), lift.floor_ys[lift.current_floor] + .3, -lift.cd() / 2.0 + .9))
	var to_panel: Vector3 = lift.cabin_panel.global_position - player.global_position
	player.rotation.y = atan2(-to_panel.x, -to_panel.z)
	for i in 30: await physics_frame
	Interactable.on(lift.cabin_panel).activate()
	var picker = game.elevator_floor_picker
	while picker.state != "open":
		await process_frame
	for i in 20: await process_frame

func run():
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	await physics_frame
	var hospital: Node3D = ModularTown.building(game.apartment, "hospital", 1)
	var lift: Node3D = hospital.get_node_or_null("Elevator") if hospital != null else null
	var tower: Node3D = game.apartment.get_node_or_null("Airport/ControlTower/Interior/Elevator")
	if lift == null or tower == null:
		print("FLOOR PICKER CAPTURE: the hospital or airport unit is not loaded")
		quit(1)
		return
	if game.day_night != null:
		game.day_night.pause()
		game.day_night.set_time(12 * 60.0)
	# Hospital: floor 3 already called from the landing, so its cabin button glows.
	lift.call_elevator(2)
	await open_on(lift)
	await shot("hospital-picker")
	game.elevator_floor_picker.close()
	while game.elevator_floor_picker.state != "":
		await process_frame
	await open_on(tower)
	await shot("tower-picker")
	quit(0)
