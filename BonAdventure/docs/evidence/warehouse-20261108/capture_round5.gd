extends SceneTree
## Warehouse Worker fifth round (8 Nov 2026): goods about a fifth bigger, the upright ruler in
## place of the measuring table (reading a box's height), a two-verb task on the card with
## Ramón's "¡Bien! Ahora …" after the pick-up, and the hover hint without "Click: Study".
## Uses Main, which saves progress: run with an isolated HOME.
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --resolution 1400x900 --script res://docs/evidence/warehouse-20261108/capture_round5.gd
const Warehouse := preload("res://scripts/world/warehouse.gd")
func _initialize(): run.call_deferred()
func snap(file: String) -> void:
	for i in range(8): await process_frame
	# Draw now even when the OS has stopped drawing the window (see capture.gd).
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(file)

var game
var goods

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
	var folder := "res://docs/evidence/warehouse-20261108"
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
	var F := Warehouse.FLOOR + .1
	print("goods: ", goods.items.keys())
	# Keep the session from finishing tasks while things are moved for the views.
	session.tasks[session.current] = {"kind": "where", "item": goods.big_box, "entry": "be", "phrase": "warehouse.task_where", "values": {"item": session.writer.thing(goods.big_box)}}
	session._show_task()
	var smalls: Array = goods.boxes.filter(func(id): return id.begins_with("box_small_"))
	var mediums: Array = goods.boxes.filter(func(id): return id.begins_with("box_medium_"))
	# 1. All goods (but the big box) in a row, the pig beside them for scale.
	var row: Array = goods.items.keys().filter(func(id): return id != goods.big_box)
	for i in row.size():
		goods.place_at(row[i], Vector3(7.5 - i * 1.25, Warehouse.FLOOR + goods.half(row[i]).y + .01, 18.6))
	await create_timer(.6).timeout
	stand(Vector3(1.8, F, 15.6), Vector3(1.8, .5, 18.6), -0.3, 7.5)
	await snap(folder + "/r5-goods-row.png")
	# 2. The upright ruler with a medium box on its base.
	goods.place_at(mediums[0], goods.MEASURE_TABLE + Vector3(-.3, Warehouse.FLOOR + Warehouse.MEASURE_PLATE_TOP + goods.half(mediums[0]).y + .02, 0))
	await create_timer(.6).timeout
	stand(Vector3(7.6, F, 12.0), Vector3(11.2, 1.2, 12.0), -0.15, 5.0)
	await snap(folder + "/r5-ruler.png")
	# 3. A two-verb task on the card; picking its thing up, Ramón says what comes next.
	var id: String = smalls[0]
	goods.place_at(id, Vector3(1.0, Warehouse.FLOOR + goods.half(id).y + .01, 13.5))
	var goal := {"pos": "on", "ref": "table"}
	session.tasks[session.current] = {"entry": "lift", "kind": "place", "lift": true, "item": id, "goal": goal, "phrase": "warehouse.task_lift", "values": {"item": session.writer.thing(id), "it": {"phrase": "warehouse.it_f"}, "place": session.writer.place(goal, true)}}
	session._new_task()
	session._show_task()
	await create_timer(.4).timeout
	stand(Vector3(1.0, F, 11.4), Vector3(1.0, .3, 13.5), -0.3, 5.0)
	await snap(folder + "/r5-two-verb-task.png")
	goods.pick_up(goods.items[id])
	await create_timer(.5).timeout
	await snap(folder + "/r5-lift-then.png")
	print("WAREHOUSE ROUND 5 CAPTURE done")
	quit()
