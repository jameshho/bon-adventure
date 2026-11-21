extends SceneTree
## Renders of the two-level shelf (user, 21 Nov 2026; docs/guides/WAREHOUSE.md#shelf-and-placing-21-nov-2026):
## the town warehouse's shelf, the minigame copy's shelf with boxes on both levels, and the
## player carrying a box toward the shelf with the put-down ghost snapped onto a top place.
## Needs a window (not --headless). Uses Main, which saves progress: run with an isolated HOME.
##   HOME=<scratch>/home VT_FOCUS=warehouse VT_SPAWN=none godot --path . --resolution 1400x900 --script res://docs/evidence/warehouse-shelf-20261121/capture.gd
const Warehouse := preload("res://scripts/world/warehouse.gd")
const FOLDER := "res://docs/evidence/warehouse-shelf-20261121"
var camera: Camera3D

func _initialize(): run.call_deferred()

func snap(file: String) -> void:
	for i in range(10): await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(FOLDER + "/" + file)
	print("saved ", file)

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
	var wh: Node3D = game.apartment.get_node("Warehouse")
	camera = Camera3D.new()
	camera.far = 400.0
	root.add_child(camera)
	game.player.global_position = wh.to_global(Vector3(-30, 1, -30))
	await create_timer(1.0).timeout
	view(wh, Vector3(9.5, 2.0, 9.0), Vector3(9.5, .7, 13.2))
	await snap("town-shelf.png")
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
	for spec in [["box_red", 1, -1.3], ["box_blue", 0, 0.0], ["box_yellow", 0, 1.3]]:
		goods.place_at(spec[0], goods.shelf_spot(spec[1], spec[2], goods.half(spec[0]).y) + Vector3(0, .02, 0))
	await create_timer(1.0).timeout
	game.player.global_position = copy.to_global(Vector3(5.0, 1, 2.0))
	view(copy, Vector3(8.6, 2.1, 8.6), Vector3(9.5, .7, 13.2))
	await snap("copy-shelf-both-levels.png")
	# "Put the yellow box on the top shelf": carried, the pointer on the top deck's front beam.
	var task: Dictionary = session.writer.make("top_shelf")
	session.tasks[session.current] = task if not task.is_empty() else keep
	session._show_task()
	var p = game.player
	p.global_position = copy.to_global(Vector3(9.9, Warehouse.FLOOR + .1, 10.2))
	p.rotation.y = atan2(0.0, -1.0) + PI
	var look: Vector3 = copy.to_global(Vector3(9.5, .5, 13.2)) - p.global_position
	p.rotation.y = atan2(-look.x, -look.z)
	p.camera_yaw = p.rotation.y
	p.camera_pitch = -0.25
	p.camera_distance = 4.5
	p.reset_camera()
	camera.clear_current()
	game.interaction.camera.make_current()
	var item := str(session.tasks[session.current].get("item", "box_yellow"))
	goods.pick_up(goods.items[item])
	await create_timer(.5).timeout
	game.interaction.pointer_position = game.interaction.camera.unproject_position(copy.to_global(Vector3(10.8, Warehouse.FLOOR + Warehouse.RACK_LEVELS[1] - .05, 12.7)))
	await create_timer(1.0).timeout
	print("pointer ", game.interaction.pointer_position, " mouse mode ", Input.mouse_mode, " ghost at ", goods._ghost.position, " drop ", goods._drop_point(goods.carried))
	await snap("carry-ghost-top.png")
	goods.put_down()
	await create_timer(1.5).timeout
	print("put at ", goods.center(item), " shelf spot ", goods.rack_spot(item))
	print("task: ", session.lexicon.text(session.tasks[session.current], "es"), " | done: ", session.writer.done(session.tasks[session.current]) if session.tasks[session.current].has("goal") else "-")
	print("WAREHOUSE SHELF 21 NOV CAPTURE done")
	quit()
