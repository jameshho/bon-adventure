extends SceneTree
## Warehouse Phase 5 views (5 Nov 2026), with the HUD: the copy's goods from the station,
## carrying a box with its put-down ghost, holding a trolley, a wrong place with Ramón's
## green marker, the weight question at the scale, the measuring readout and the open
## cabinet. Uses Main, which saves progress: run with an isolated HOME (README).
## godot --path . --resolution 1400x900 --script res://docs/evidence/warehouse-20261105/capture_tasks.gd
const Warehouse := preload("res://scripts/world/warehouse.gd")
func _initialize(): run.call_deferred()
func snap(file: String) -> void:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(file)

var game
var goods

## Stands the player at a hall-local spot looking toward another, camera behind.
func stand(at: Vector3, toward: Vector3, pitch := -0.32, distance := 6.5) -> void:
	game.player.global_position = goods.to_world(at)
	var look: Vector3 = goods.to_world(toward) - goods.to_world(at)
	game.player.rotation.y = atan2(-look.x, -look.z)
	game.player.camera_yaw = game.player.rotation.y
	game.player.camera_pitch = pitch
	game.player.camera_distance = distance
	game.player.reset_camera()

func run():
	if DisplayServer.get_name() == "headless": quit(1); return
	var folder := "res://docs/evidence/warehouse-20261105"
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.player.set_physics_process(false)
	for i in 4: await physics_frame
	var town: Node3D = game.apartment
	var ramon: Node3D = town.get_node("Warehouse/Exterior/Ramon")
	var session = game.get_node("WarehouseSession")
	game.interaction.clerk_activated.emit(ramon)
	game.shop_panel.choice_pressed.emit("warehouse_play")
	await create_timer(1.6).timeout
	game.shop_panel.dialogue_closed.emit()
	goods = session.goods
	var writer = session.writer
	var F := Warehouse.FLOOR + .1
	# Keep the session from finishing tasks while things are moved for the views.
	var hold := {"kind": "where", "item": session.goods.big_box, "entry": "be", "phrase": "warehouse.task_where", "values": {"item": session.writer.thing(session.goods.big_box)}}
	session.tasks[session.current] = hold
	session._show_task()
	stand(Vector3(.6, F, 9.0), Vector3(2.0, 1.0, 20.0), -0.28, 9.0)
	await snap(folder + "/game5-goods.png")
	# Carrying: the box floats ahead, the ghost shows where E puts it.
	goods.place_at(goods.boxes[1], Vector3(1.0, Warehouse.FLOOR + goods.half(goods.boxes[1]).y + .01, 17.2))
	stand(Vector3(1.0, F, 16.0), Vector3(1.0, F, 19.0), -0.42, 5.0)
	goods.pick_up(goods.items[goods.boxes[1]])
	game.interaction.pointer_position = game.get_viewport().get_visible_rect().size * Vector2(.5, .62)
	for i in 6: await physics_frame
	await snap(folder + "/game5-carry.png")
	goods.drop_carried()
	# Holding the IN trolley.
	var trolley: Dictionary = goods.trolley_for("zone_in")
	goods._move_trolley(trolley, goods.TROLLEY_Z.y)
	goods.grab_trolley(trolley)
	for i in 3: await physics_frame
	game.player.camera_yaw = game.player.rotation.y + .5
	game.player.camera_pitch = -.35
	game.player.reset_camera()
	await snap(folder + "/game5-trolley.png")
	goods.release_trolley()
	# A wrong place, then "tell me what went wrong": the green marker.
	var task: Dictionary = writer.make("inside")
	while task.get("kind", "") != "place":
		task = writer.make("inside")
	session.tasks[session.current] = task
	session._show_task()
	goods.pick_up(goods.items[task.item])
	goods._release_at(Vector3(-.5, Warehouse.FLOOR + goods.half(task.item).y + .02, 16.5))
	await create_timer(1.3).timeout
	var bin: Vector3 = goods.containers[task.goal.ref].center
	stand(bin + Vector3(0, 0, -4.0), bin, -0.4, 6.0)
	await snap(folder + "/game5-wrong.png")
	game.shop_panel.choice_pressed.emit("warehouse_hint")
	await snap(folder + "/game5-hint.png")
	session._close_dialogue()
	# Weighing: Ramón asks once the thing is on the scale.
	var weigh: Dictionary = writer.make("weigh")
	while weigh.get("kind", "") != "weigh":
		weigh = writer.make("weigh")
	session.tasks[session.current] = weigh
	session._show_task()
	goods.place_at(weigh.item, goods.SCALE_AT + Vector3(0, Warehouse.FLOOR + goods.SCALE_TOP + goods.half(weigh.item).y + .02, 0))
	stand(Vector3(8.0, F, 12.6), Vector3(8.0, 1.0, 16.0), -0.3, 4.5)
	await create_timer(1.0).timeout
	await snap(folder + "/game5-weigh.png")
	session._close_dialogue()
	session.tasks[session.current] = hold
	session._show_task()
	var long_box: String = goods.boxes[2]
	goods.place_at(long_box, goods.MEASURE_TABLE + Vector3(-.3, Warehouse.FLOOR + Warehouse.MEASURE_PLATE_TOP + goods.half(long_box).y + .02, -.1))
	stand(Vector3(11.0, F, 9.8), Vector3(11.0, 1.0, 12.4), -0.4, 4.0)
	await create_timer(.6).timeout
	await snap(folder + "/game5-measure.png")
	goods.set_cabinet(true)
	stand(Vector3(-8.5, F, 23.5), Vector3(-8.5, 1.0, 28.0), -0.2, 5.0)
	await create_timer(.6).timeout
	await snap(folder + "/game5-cabinet.png")
	print("WAREHOUSE TASK CAPTURE done")
	quit()
