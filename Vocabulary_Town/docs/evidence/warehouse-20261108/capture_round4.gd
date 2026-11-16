extends SceneTree
## Warehouse Worker fourth round (8 Nov 2026): every cardboard thing is a box (eight boxes, eight
## colours, no packages), the containers redrawn as plastic totes (light rim, dark inside, ribs,
## grips, label, dark base) and the boxes' new print (flap edges, bottom band, "this way up"
## arrows). Views: the two containers with boxes inside, one from above, all goods in a row, and
## the hall from the station. Uses Main, which saves progress: run with an isolated HOME.
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --resolution 1400x900 --script res://docs/evidence/warehouse-20261108/capture_round4.gd
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
	# 1. Both containers, a medium and a small box in one, a small box in the other.
	var cids: Array = goods.containers.keys()
	for id in goods.items:
		if cids.has(goods.inside_of(id)):
			goods.place_at(id, Vector3(6.0, Warehouse.FLOOR + goods.half(id).y + .01, 16.0))
	var c0: Vector3 = goods.containers[cids[0]].center
	var c1: Vector3 = goods.containers[cids[1]].center
	goods.place_at(mediums[0], c0 + Vector3(-.4, goods.half(mediums[0]).y + .02, 0))
	goods.place_at(smalls[0], c0 + Vector3(.5, goods.half(smalls[0]).y + .02, .2))
	goods.place_at(smalls[1], c1 + Vector3(.2, goods.half(smalls[1]).y + .02, -.1))
	await create_timer(.6).timeout
	var mid := (c0 + c1) * .5
	stand(Vector3(mid.x + 1.2, F, mid.z - 4.0), mid + Vector3(0, .4, 0), -0.32, 5.0)
	await snap(folder + "/r4-containers.png")
	# 2. One container from close above: rim, dark inside, boxes inside.
	stand(Vector3(c0.x, F, c0.z - 2.2), c0, -0.75, 3.6)
	await snap(folder + "/r4-container-above.png")
	# 3. All goods (but the big box) in a row on the floor.
	var row: Array = goods.items.keys().filter(func(id): return id != goods.big_box)
	for i in row.size():
		goods.place_at(row[i], Vector3(7.0 - i * 1.1, Warehouse.FLOOR + goods.half(row[i]).y + .01, 13.6))
	await create_timer(.6).timeout
	stand(Vector3(2.6, F, 16.4), Vector3(2.6, .3, 13.6), -0.55, 6.5)
	await snap(folder + "/r4-goods-row.png")
	stand(Vector3(5.8, F, 15.4), Vector3(5.8, .3, 13.6), -0.5, 3.6)
	await snap(folder + "/r4-goods-close.png")
	# 4. The hall from the station.
	stand(Vector3(.6, F, 9.0), Vector3(-1.0, 1.0, 22.0), -0.24, 8.0)
	await snap(folder + "/r4-hall.png")
	print("WAREHOUSE ROUND 4 CAPTURE done")
	quit()
