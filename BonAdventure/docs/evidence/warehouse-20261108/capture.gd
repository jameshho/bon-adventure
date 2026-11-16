extends SceneTree
## Warehouse Worker goods resize (8 Nov 2026), with the HUD: the hall from the station, the pig
## beside the trolley-only big box (a small box on top, the too-heavy toast), a wide low
## container with goods inside, the bigger scale and measuring table, the racks with medium
## and small boxes, the left-wall bays, the conveyor, a close-up of
## the goods (boxes, suitcase, barrel) and carrying a medium box. Uses Main, which
## saves progress: run with an isolated HOME (README).
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --resolution 1400x900 --script res://docs/evidence/warehouse-20261108/capture.gd
const Warehouse := preload("res://scripts/world/warehouse.gd")
func _initialize(): run.call_deferred()
func snap(file: String) -> void:
	for i in range(8): await process_frame
	# Draw now even when the OS has stopped drawing the window (hidden or occluded on macOS,
	# where waiting for frame_post_draw hangs).
	RenderingServer.force_draw(false)
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

func floor_at(id: String, x: float, z: float) -> void:
	goods.place_at(id, Vector3(x, Warehouse.FLOOR + goods.half(id).y + .01, z))

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
	# Keep the session from finishing tasks while things are moved for the views.
	var hold := {"kind": "where", "item": session.goods.big_box, "entry": "be", "phrase": "warehouse.task_where", "values": {"item": session.writer.thing(session.goods.big_box)}}
	session.tasks[session.current] = hold
	session._show_task()
	var big: String = goods.big_box
	var smalls: Array = goods.boxes.filter(func(id): return id.begins_with("box_small_"))
	var mediums: Array = goods.boxes.filter(func(id): return id.begins_with("box_medium_"))
	var suitcase: String = goods.items.keys().filter(func(id): return id.begins_with("suitcase_"))[0]
	var barrel: String = goods.items.keys().filter(func(id): return id.begins_with("barrel_"))[0]
	print("goods: ", goods.items.keys(), " big ", big)
	# 1. The hall from the station, as the game starts.
	stand(Vector3(.6, F, 9.0), Vector3(2.0, 1.0, 20.0), -0.28, 9.0)
	await create_timer(.8).timeout
	await snap(folder + "/hall-from-station.png")
	# 2. The wall bays, all on the left wall (as the game arranged them), seen across the hall.
	stand(Vector3(6.5, F, 15.6), Vector3(13.0, .4, 19.25), -0.28, 7.0)
	await snap(folder + "/bays-left-wall.png")
	# 2. The pig beside the big box on its trolley, a small box on top; E says it is too heavy.
	var carrier: Dictionary = {}
	for trolley in goods.trolleys:
		if trolley.get("cargo", "") == big:
			carrier = trolley
	goods._move_trolley(carrier, goods.TROLLEY_Z.y)
	for id in goods.items:
		if id != big and goods.on_top_of(id, big):
			floor_at(id, 2.0, 20.0)
	await create_timer(.3).timeout
	var top: Vector3 = goods.center(big)
	goods.place_at(smalls[0], Vector3(top.x, top.y + goods.half(big).y + goods.half(smalls[0]).y + .02, top.z))
	await create_timer(.4).timeout
	stand(Vector3(carrier.lane + 1.9, F, carrier.z), Vector3(carrier.lane + 1.9, F, carrier.z + 6.0), -0.12, 5.5)
	goods.too_heavy.emit()
	await create_timer(.4).timeout
	await snap(folder + "/big-box-and-pig.png")
	# 3. A wide, low container with a medium box and a small box inside.
	var cid: String = goods.containers.keys()[0]
	var c: Vector3 = goods.containers[cid].center
	for id in goods.items:
		if goods.inside_of(id) == cid:
			floor_at(id, -1.0, 13.0)
	goods.place_at(mediums[2], c + Vector3(-.5, goods.half(mediums[2]).y + .02, 0))
	goods.place_at(smalls[2], c + Vector3(.6, goods.half(smalls[2]).y + .02, .2))
	await create_timer(.5).timeout
	stand(Vector3(c.x, F, c.z - 2.6), c, -0.5, 4.5)
	await snap(folder + "/container.png")
	# 4. The scale and the measuring table, bigger, with readouts.
	for id in goods.items:
		if id != big and (goods.on_scale(id) or goods.on_table(id, "measure")):
			floor_at(id, 0.0, 14.5)
	goods.place_at(barrel, goods.SCALE_AT + Vector3(0, Warehouse.FLOOR + goods.SCALE_TOP + goods.half(barrel).y + .02, 0))
	goods.place_at(mediums[1], goods.MEASURE_TABLE + Vector3(-.4, Warehouse.FLOOR + Warehouse.MEASURE_PLATE_TOP + goods.half(mediums[1]).y + .02, -.1))
	await create_timer(.6).timeout
	stand(Vector3(9.6, F, 8.6), Vector3(9.6, 1.0, 14.5), -0.3, 5.5)
	await snap(folder + "/scale-and-measure.png")
	# 5. Racks with medium and small boxes on the shelves.
	for i in 3:
		var level: int = [0, 1, 2][i]
		var id: String = [mediums[0], smalls[1], mediums[3]][i]
		if goods.bay_of(id) >= 0:
			continue
		goods.place_at(id, Vector3(3.5 + [-1.4, 0.0, 1.4][i], Warehouse.FLOOR + Warehouse.RACK_LEVELS[level] + .02 + goods.half(id).y, Warehouse.RACK_Z))
	await create_timer(.4).timeout
	stand(Vector3(3.5, F, 21.0), Vector3(3.5, 1.2, 27.3), -0.12, 5.0)
	await snap(folder + "/racks.png")
	# 9. The conveyor belt without yellow parts.
	stand(Vector3(-9.0, F, 19.5), Vector3(-13.5, .8, 25.0), -0.2, 5.0)
	await snap(folder + "/conveyor.png")
	# 10. Close-up of the goods in a row: small and medium boxes, suitcase, barrel.
	var row: Array = [smalls[0], mediums[2], smalls[2], mediums[3], suitcase, barrel]
	for i in row.size():
		goods.place_at(row[i], Vector3(5.5 - i * 1.15, Warehouse.FLOOR + goods.half(row[i]).y + .01, 13.6))
	await create_timer(.6).timeout
	stand(Vector3(3.2, F, 15.4), Vector3(2.6, .3, 13.6), -0.72, 4.2)
	await snap(folder + "/goods-close.png")
	# 7. Carrying a medium box: it floats ahead, the ghost shows where E puts it.
	floor_at(mediums[2], 1.0, 17.2)
	stand(Vector3(1.0, F, 16.0), Vector3(1.0, F, 19.0), -0.42, 5.0)
	goods.pick_up(goods.items[mediums[2]])
	game.interaction.pointer_position = game.get_viewport().get_visible_rect().size * Vector2(.5, .62)
	for i in 6: await physics_frame
	await snap(folder + "/carry-medium.png")
	goods.drop_carried()
	print("WAREHOUSE RESIZE CAPTURE done")
	quit()
