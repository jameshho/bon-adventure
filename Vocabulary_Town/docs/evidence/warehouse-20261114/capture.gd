extends SceneTree
## Renders of the warehouse redesign (user, 14 Nov 2026; docs/guides/WAREHOUSE.md#redesign-14-nov-2026):
## the front with both loading bays, the reception, the hall's left and right sections, the
## shelf with boxes on both levels (minigame copy) and the minigame mid-task with the task card.
## Needs a window (not --headless). Uses Main, which saves progress: run with an isolated HOME.
##   HOME=<scratch>/home VT_FOCUS=warehouse VT_SPAWN=none godot --path . --resolution 1400x900 --script res://docs/evidence/warehouse-20261114/capture.gd
const Warehouse := preload("res://scripts/world/warehouse.gd")
const FOLDER := "res://docs/evidence/warehouse-20261114"
var camera: Camera3D

func _initialize(): run.call_deferred()

func snap(file: String) -> void:
	for i in range(10): await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(FOLDER + "/" + file)
	print("saved ", file)

## A free camera at hall-local `from`, looking at hall-local `at` of `frame`.
func view(frame: Node3D, from: Vector3, at: Vector3, fov := 70.0) -> void:
	camera.fov = fov
	camera.look_at_from_position(frame.to_global(from), frame.to_global(at), Vector3.UP)
	camera.make_current()

func run():
	if DisplayServer.get_name() == "headless": quit(1); return
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.player.set_physics_process(false)
	for i in 4: await physics_frame
	var town: Node3D = game.apartment
	var wh: Node3D = town.get_node("Warehouse")
	camera = Camera3D.new()
	camera.far = 400.0
	root.add_child(camera)
	# Keep the player out of the shots.
	game.player.global_position = wh.to_global(Vector3(-30, 1, -30))
	await create_timer(1.0).timeout
	view(wh, Vector3(-3.0, 4.2, -17.0), Vector3(-3.0, 2.2, 3.0))
	await snap("front-bays.png")
	view(wh, Vector3(6.0, 10.0, -26.0), Vector3(0.0, 2.5, 6.0))
	await snap("front-wide.png")
	view(wh, Vector3(-9.0, 2.4, 1.0), Vector3(-12.3, 1.1, 10.5))
	await snap("reception-desk.png")
	view(wh, Vector3(-11.6, 1.9, 9.3), Vector3(-11.9, 1.25, 10.2), 45.0)
	await snap("reception-counter.png")
	view(wh, Vector3(-14.3, 2.4, 13.6), Vector3(-8.3, 1.6, 4.5))
	await snap("reception-partition.png")
	view(wh, Vector3(2.2, 3.4, 13.8), Vector3(-6.0, 1.0, 1.5))
	await snap("hall-right.png")
	view(wh, Vector3(-7.4, 3.6, 1.0), Vector3(10.0, 1.0, 11.0))
	await snap("hall-left.png")
	# The minigame copy: boxes on both shelf levels, then the player mid-task with the card.
	var ramon: Node3D = wh.get_node("Exterior/Ramon")
	var session = game.get_node("WarehouseSession")
	game.player.global_position = wh.to_global(Vector3(-10.0, .2, -3.6))
	preload("res://scripts/core/interactable.gd").on(ramon).activate()
	game.shop_panel.choice_pressed.emit("warehouse_play")
	await create_timer(2.0).timeout
	game.shop_panel.dialogue_closed.emit()
	var goods = session.goods
	var copy: Node3D = session.copy_root
	var keep: Dictionary = session.tasks[session.current]
	session.tasks[session.current] = {"kind": "none"}
	var shelf := Warehouse.SHELF_AT
	var spots := [["box_red", 1, -1.3], ["box_blue", 1, 0.0], ["box_yellow", 0, -1.3], ["box_plain", 0, 1.3]]
	for spec in spots:
		var id: String = spec[0]
		goods.place_at(id, Vector3(shelf.x + spec[2], Warehouse.FLOOR + Warehouse.RACK_LEVELS[spec[1]] + .02 + goods.half(id).y + .02, shelf.z))
	await create_timer(1.0).timeout
	game.player.global_position = copy.to_global(Vector3(5.0, 1, 2.0))
	view(copy, Vector3(9.5, 1.9, 9.4), Vector3(9.5, .75, 13.2))
	await snap("shelf-both-levels.png")
	# Mid-task: "to the right of the green box", the red box carried toward the bay.
	var task: Dictionary = session.writer.make("right")
	session.tasks[session.current] = task if not task.is_empty() else keep
	session._show_task()
	var p = game.player
	p.global_position = copy.to_global(Vector3(10.6, Warehouse.FLOOR + .1, 5.2))
	var look: Vector3 = copy.to_global(Vector3(13.6, .5, 7.2)) - p.global_position
	p.rotation.y = atan2(-look.x, -look.z)
	p.camera_yaw = p.rotation.y
	p.camera_pitch = -0.32
	p.camera_distance = 5.0
	p.reset_camera()
	camera.clear_current()
	game.interaction.camera.make_current()
	var item := str(session.tasks[session.current].get("item", "box_red"))
	goods.pick_up(goods.items[item])
	game.interaction.pointer_position = game.interaction.camera.unproject_position(copy.to_global(Vector3(13.6, Warehouse.FLOOR, 7.9)))
	await create_timer(1.0).timeout
	await snap("minigame-mid-task.png")
	print("task: ", session.lexicon.text(session.tasks[session.current], "es"), " | ", session.lexicon.text(session.tasks[session.current], "en"))
	print("WAREHOUSE 14 NOV CAPTURE done")
	quit()
