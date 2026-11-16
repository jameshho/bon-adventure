extends SceneTree
## Warehouse Worker sixth round (8 Nov 2026): the praise "¡Muy bien! Siguiente tarea." on the
## task card instead of a second box at the bottom, then a find task without "está en algún
## lugar del almacén". Uses Main, which saves progress: run with an isolated HOME.
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --resolution 1400x900 --script res://docs/evidence/warehouse-20261108/capture_round6.gd
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
	var id: String = goods.boxes.filter(func(k): return k.begins_with("box_small_"))[0]
	goods.place_at(id, Vector3(1.0, Warehouse.FLOOR + goods.half(id).y + .01, 13.5))
	var goal := {"pos": "on", "ref": "table"}
	session.tasks[session.current] = {"entry": "lift", "kind": "place", "lift": true, "item": id, "goal": goal, "phrase": "warehouse.task_lift", "values": {"item": session.writer.thing(id), "it": {"phrase": "warehouse.it_f"}, "place": session.writer.place(goal, true)}}
	var find := {"entry": "find", "kind": "place", "lift": true, "item": id, "goal": {"pos": "inside", "ref": goods.containers.keys()[0]}, "phrase": "warehouse.task_find", "values": {"item": session.writer.thing(id), "it": {"phrase": "warehouse.it_f"}, "place": session.writer.place({"pos": "inside", "ref": goods.containers.keys()[0]}, true)}}
	if session.tasks.size() > session.current + 1:
		session.tasks[session.current + 1] = find
	else:
		session.tasks.append(find)
	session._show_task()
	stand(Vector3(1.0, F, 11.0), Vector3(4.5, .8, 12.0), -0.3, 5.0)
	goods.place_at(id, Vector3(goods.WORK_TABLE.x, Warehouse.FLOOR + goods.TABLE_HEIGHT + goods.half(id).y + .02, goods.WORK_TABLE.z))
	await create_timer(1.0).timeout
	await snap(folder + "/r6-praise-on-card.png")
	await create_timer(2.0).timeout
	await snap(folder + "/r6-next-task.png")
	print("WAREHOUSE ROUND 6 CAPTURE done")
	quit()
