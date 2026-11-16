extends SceneTree
## Warehouse Worker third round (8 Nov 2026), with the HUD: the hall from the station (task card
## with the "?" hint and restyled exit buttons, no "0/10" count), the two containers where rack C
## was, a first hint (a clue in Ramón's box), a second hint (the thing marked green), the leave
## question at the roll-up loading gate. Uses Main, which saves progress: run with an isolated HOME.
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --resolution 1400x900 --script res://docs/evidence/warehouse-20261108/capture_round3.gd
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
	for task in session.tasks:
		print("plan: ", session.lexicon.text(task, "es"))
	# 1. The hall from the station: the card and the back of the hall.
	stand(Vector3(.6, F, 9.0), Vector3(-1.0, 1.0, 22.0), -0.24, 8.0)
	await create_timer(.8).timeout
	await snap(folder + "/r3-hall-from-station.png")
	# 2. The containers where rack C was.
	stand(Vector3(-3.5, F, 21.5), Vector3(-3.5, .4, 27.3), -0.3, 6.0)
	await snap(folder + "/r3-containers-at-rack-c.png")
	# 3-4. Hints for a "lift" task on a thing on the floor: a clue, then the green marker.
	var id: String = goods.items.keys().filter(func(k): return goods.bay_of(k) < 0 and not goods.trolley_only(k) and goods.inside_of(k) == "" and goods.on_floor(k))[0]
	session.tasks[session.current] = {"entry": "lift", "kind": "hold", "item": id, "phrase": "warehouse.task_lift", "values": {"item": session.writer.thing(id)}}
	session._new_task()
	session._show_task()
	var at: Vector3 = goods.center(id)
	stand(Vector3(at.x + 1.5, F, at.z - 4.0), Vector3(at.x, .3, at.z), -0.3, 6.0)
	game.warehouse_card.hint_button.pressed.emit()
	await create_timer(.5).timeout
	await snap(folder + "/r3-hint-1.png")
	game.warehouse_card.hint_button.pressed.emit()
	await create_timer(.5).timeout
	await snap(folder + "/r3-hint-2.png")
	session._close_dialogue()
	# 5. E at the roll-up loading gate asks to leave.
	stand(Vector3(-12.2, F, Warehouse.HALL_Z0 + 2.2), Vector3(-12.2, 1.8, Warehouse.HALL_Z0), -0.05, 4.0)
	for i in 3: await physics_frame
	game.interaction.pointer_position = game.interaction.camera.unproject_position(goods.to_world(Vector3(-12.2, Warehouse.FLOOR + 1.8, Warehouse.HALL_Z0 + .1)))
	print("gate asks: ", session.handle_use())
	await create_timer(.4).timeout
	await snap(folder + "/r3-leave-at-gate.png")
	print("WAREHOUSE ROUND 3 CAPTURE done")
	quit()
