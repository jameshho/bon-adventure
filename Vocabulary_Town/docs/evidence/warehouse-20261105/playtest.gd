extends SceneTree
## Warehouse play-test (5 Nov 2026): plays the Warehouse Worker game with real input. The
## player's physics runs; W is held with key events to walk, the pointer is put on things
## and E is pressed through Main's input, as a learner would. Prints what happened and saves
## views. Uses Main, which saves progress: run with an isolated HOME (README).
## godot --path . --resolution 1400x900 --script res://docs/evidence/warehouse-20261105/playtest.gd
const Warehouse := preload("res://scripts/world/warehouse.gd")
func _initialize(): run.call_deferred()

var game
var session
var goods
var folder := "res://docs/evidence/warehouse-20261105"

func snap(file: String) -> void:
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder + "/" + file)

func key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)

func press(code: Key) -> void:
	key(code, true)
	await physics_frame
	key(code, false)
	await physics_frame

func say(text: String) -> void:
	print("PLAYTEST: ", text)

## Turns the camera toward a hall point and walks (W held) until within `stop` (hall units).
func walk_to(target: Vector3, stop: float) -> bool:
	key(KEY_W, true)
	var reached := false
	for i in 600:
		await physics_frame
		var feet: Vector3 = goods.to_hall(game.player.global_position)
		var d := Vector2(target.x - feet.x, target.z - feet.z)
		if d.length() < stop:
			reached = true
			break
		var world_dir: Vector3 = goods.to_world(target) - game.player.global_position
		game.player.camera_yaw = atan2(-world_dir.x, -world_dir.z)
	key(KEY_W, false)
	for i in 20: await physics_frame
	return reached

## Puts the pointer on a hall point (as the mouse would) and lets hovering catch up.
func point_at(target: Vector3) -> void:
	var camera: Camera3D = game.get_viewport().get_camera_3d()
	game.interaction.pointer_position = camera.unproject_position(goods.to_world(target))
	for i in 6: await physics_frame

func run():
	if DisplayServer.get_name() == "headless": quit(1); return
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 4: await physics_frame
	var ramon: Node3D = game.apartment.get_node("Warehouse/Exterior/Ramon")
	session = game.get_node("WarehouseSession")
	game.interaction.clerk_activated.emit(ramon)
	game.shop_panel.choice_pressed.emit("warehouse_play")
	await create_timer(1.8).timeout
	game.shop_panel.dialogue_closed.emit()
	goods = session.goods
	for i in 40: await physics_frame  # let the goods settle into their bays
	var writer = session.writer
	var lexicon = session.lexicon
	# Five tasks the writer would give, in Spanish and English.
	for i in 6:
		var task: Dictionary = writer.next()
		say("task %s (%s): %s | %s" % [task.entry, task.kind, lexicon.text(task, "es"), lexicon.text(task, "en")])
	# Keep the session's own task from finishing while we play around.
	session.tasks[session.current] = {"kind": "where", "item": session.goods.big_box, "entry": "be", "phrase": "warehouse.task_where", "values": {"item": session.writer.thing(session.goods.big_box)}}
	session._show_task()
	game.player.camera_pitch = -.45
	# 1. Walk to a box in a wall bay, aim at it, E: carried?
	var ref := ""
	var box := ""
	for id in goods.boxes:
		if goods.bay_of(id) >= 0:
			ref = id if ref == "" else ref
		elif box == "" and goods.rack_spot(id).is_empty() and goods.inside_of(id) == "":
			box = id
	if box == "":
		box = goods.boxes[1]
	var start: Vector3 = goods.center(box)
	var arrived := await walk_to(start, 1.8)
	await point_at(start)
	say("walked to %s: %s; hovered %s" % [box, arrived, game.interaction.hovered.name if is_instance_valid(game.interaction.hovered) else "nothing"])
	await press(KEY_E)
	for i in 10: await physics_frame
	say("E picks up: %s" % (goods.carried == goods.items[box]))
	await snap("play-carry.png")
	# 2. Carry it to the right of the bay reference and put it down by aiming at the floor.
	if ref != "":
		var r: Vector3 = goods.ref_center(ref)
		var right: Vector2 = goods.side_axis(ref, "right")
		var spot := Vector3(r.x + right.x * (goods.reach(goods.ref_half(ref), goods.half(box), right) + .5), Warehouse.FLOOR, r.z + right.y * (goods.reach(goods.ref_half(ref), goods.half(box), right) + .5))
		var out: Vector2 = goods.side_axis(ref, "front")
		await walk_to(spot + Vector3(out.x * 1.8, 0, out.y * 1.8), .6)
		await point_at(spot)
		await snap("play-aim.png")
		await press(KEY_E)
		for i in 40: await physics_frame
		say("put down right of %s: carried=%s beside(right)=%s at %s (wanted %s)" % [ref, goods.carried != null, goods.beside(box, ref, "right"), goods.center(box), spot])
		await snap("play-placed.png")
	# 3. Walking into a free floor box nudges it (pushed toward the middle of the hall, away from walls).
	var nudge := ""
	for id in goods.boxes:
		if id != box and goods.bay_of(id) < 0 and goods.on_floor(id) and goods.inside_of(id) == "":
			nudge = id
	if nudge == "":
		goods.place_at(box, Vector3(4.0, Warehouse.FLOOR + goods.half(box).y + .02, 19.0))
		nudge = box
	for i in 20: await physics_frame
	var before: Vector3 = goods.center(nudge)
	var inward := Vector2(-before.x, 20.0 - before.z).normalized()
	await walk_to(before - Vector3(inward.x, 0, inward.y) * 1.6, .3)
	await walk_to(before + Vector3(inward.x, 0, inward.y) * 1.2, .3)
	say("nudge moved %s %.2f m (from %s)" % [nudge, goods.center(nudge).distance_to(before), before])
	# 4. Grab a trolley with E, hold W, let go with E.
	var trolley: Dictionary = goods.trolley_for("zone_in")
	goods._move_trolley(trolley, goods.TROLLEY_Z.y)
	var handle := Vector3(trolley.lane, Warehouse.FLOOR, trolley.z + 1.6)
	await walk_to(handle, .5)
	await point_at(Vector3(trolley.lane, Warehouse.FLOOR + .9, trolley.z + .52))
	await press(KEY_E)
	say("E grabs the trolley: %s" % (not goods.held_trolley.is_empty()))
	var z0: float = trolley.z
	key(KEY_W, true)
	for i in 120: await physics_frame
	key(KEY_W, false)
	await snap("play-trolley.png")
	say("W pushed the trolley %.2f m; in area: %s" % [z0 - trolley.z, goods.trolley_in_zone("zone_in")])
	await press(KEY_E)
	say("E lets go: %s; walking back: %s" % [goods.held_trolley.is_empty(), game.player.controls_enabled])
	# 5. The cabinet with E.
	var was: bool = goods.cabinet_open
	await walk_to(Vector3(-8.5, Warehouse.FLOOR, 26.2), .5)
	await point_at(Vector3(-8.5, Warehouse.FLOOR + 1.0, 27.6))
	await press(KEY_E)
	await create_timer(.5).timeout
	say("E on the cabinet toggled it: %s" % (goods.cabinet_open != was))
	await snap("play-cabinet.png")
	# 6. A colour question and a comparison, answered through the dialogue.
	var color: Dictionary = writer.make("look_for")
	for i in 20:
		if color.kind == "color":
			break
		color = writer.make("look_for")
	if color.kind == "color":
		session.tasks[session.current] = color
		session._show_task()
		game.interaction.clerk_activated.emit(session.twin)
		await snap("play-color.png")
		say("colour question: %s → %s" % [lexicon.text(color, "es"), session._talking])
		session._close_dialogue()
	var pair: Dictionary = writer.make("weigh")
	for i in 20:
		if pair.kind == "compare":
			break
		pair = writer.make("weigh")
	if pair.kind == "compare":
		session.tasks[session.current] = pair
		session._show_task()
		for id in pair.items:
			goods.place_at(id, goods.SCALE_AT + Vector3(0, Warehouse.FLOOR + goods.SCALE_TOP + goods.half(id).y + .02, 0))
			for i in 30: await physics_frame
			goods.place_at(id, Vector3(6.5, Warehouse.FLOOR + goods.half(id).y + .02, 17.0 + pair.items.find(id)))
			for i in 10: await physics_frame
		await snap("play-compare.png")
		say("comparison: %s → asked %s" % [lexicon.text(pair, "es"), session._talking])
	print("PLAYTEST done")
	quit()
