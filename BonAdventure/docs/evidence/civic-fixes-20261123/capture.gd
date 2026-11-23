extends SceneTree
## Renders for the civic fixes of 23 Nov 2026 (docs/evidence/civic-fixes-20261123/): the home
## garage, the school classroom, the police lockers (shut and open), the warehouse supply
## cabinet (shut and open) and the zoo entrance (gate opened from outside and from inside).
## Needs a window (not --headless). Uses Main, which saves progress: run with an isolated HOME.
##   HOME=<scratch>/home VT_FOCUS=home,school,police,warehouse VT_SPAWN=none VT_SHEET=after \
##     godot --path . --resolution 1280x800 --script res://docs/evidence/civic-fixes-20261123/capture.gd
## VT_SHEET (before / after) prefixes the file names; "before" skips the opened views.
const FOLDER := "res://docs/evidence/civic-fixes-20261123"
var camera: Camera3D
var sheet := "after"
var game

func _initialize(): run.call_deferred()

func snap(file: String) -> void:
	for i in range(12): await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(FOLDER + "/" + sheet + "-" + file)
	print("saved ", sheet, "-", file)

func view(frame: Node3D, from: Vector3, at: Vector3, fov := 70.0) -> void:
	camera.fov = fov
	camera.look_at_from_position(frame.to_global(from), frame.to_global(at), Vector3.UP)
	camera.make_current()

## Opens (or shuts) every registered door below `node`.
func set_doors(node: Node, open_them: bool) -> int:
	var n := 0
	for door in game.doors.keys():
		if is_instance_valid(door) and node.is_ancestor_of(door) and bool(game.doors[door]["open"]) != open_them:
			preload("res://scripts/core/door_animator.gd").toggle(game, door)
			n += 1
	return n

func run():
	if DisplayServer.get_name() == "headless": quit(1); return
	sheet = OS.get_environment("VT_SHEET") if OS.get_environment("VT_SHEET") != "" else "after"
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.player.set_physics_process(false)
	for i in 4: await physics_frame
	var town: Node3D = game.apartment
	camera = Camera3D.new()
	camera.far = 400.0
	root.add_child(camera)
	game.player.global_position = town.to_global(Vector3(0, 1, 300))
	await create_timer(1.5).timeout
	# Home garage: the back wall where the bicycle stood.
	var home: Node3D = town.get_node("RelocatedSites/Home")
	view(home, Vector3(10.0, 2.0, 9.6), Vector3(12.5, .8, 14.6))
	await snap("garage.png")
	# School classroom (x < 0 half): both side walls and the room.
	var school: Node3D = town.get_node("Buildings/School")
	view(school, Vector3(-1.0, 2.2, -10.5), Vector3(-8.0, 1.4, 0.0), 75.0)
	await snap("classroom-from-door.png")
	view(school, Vector3(-3.0, 2.0, -4.0), Vector3(-11.8, 1.8, -4.0), 80.0)
	await snap("classroom-west-wall.png")
	view(school, Vector3(-9.0, 2.0, -4.0), Vector3(0.0, 1.8, -2.0), 80.0)
	await snap("classroom-divider-wall.png")
	view(school, Vector3(-6.0, 2.0, -6.0), Vector3(-6.0, 1.8, -12.2), 80.0)
	await snap("classroom-front-wall.png")
	# The other half (x > 0, on the left when coming in): science, art and geography.
	view(school, Vector3(1.0, 2.2, -10.5), Vector3(8.0, 1.4, 0.0), 75.0)
	await snap("school-left-from-door.png")
	view(school, Vector3(6.5, 2.0, -3.0), Vector3(6.5, 1.8, -12.2), 80.0)
	await snap("school-left-front-wall.png")
	view(school, Vector3(2.0, 2.0, -2.0), Vector3(11.8, 1.6, -2.0), 80.0)
	await snap("school-left-east-wall.png")
	view(school, Vector3(6.5, 2.0, -6.0), Vector3(6.5, 1.6, 5.5), 80.0)
	await snap("school-left-rear-wall.png")
	view(school, Vector3(7.0, 2.0, -7.0), Vector3(11.8, 2.1, -10.0), 70.0)
	await snap("school-left-continent-chart.png")
	# Police lockers, shut then open.
	var interior: Node3D = town.get_node("RelocatedSites/Police/Interior")
	view(interior, Vector3(45.9, 1.9, 56.6), Vector3(45.9, 1.0, 59.2))
	await snap("police-lockers.png")
	if sheet != "before":
		print("police lockers opened: ", set_doors(interior, true))
		await create_timer(1.2).timeout
		await snap("police-lockers-open.png")
	# Warehouse supply cabinet.
	var hall: Node3D = town.get_node("Warehouse/Hall")
	view(hall, Vector3(5.2, 1.8, 10.8), Vector3(5.2, 1.0, 13.75))
	await snap("warehouse-cabinet.png")
	if sheet != "before":
		print("warehouse cabinet doors opened: ", set_doors(hall, true))
		await create_timer(1.2).timeout
		await snap("warehouse-cabinet-open.png")
	# Zoo entrance from outside (the welcome board stood west of the arch).
	view(town, Vector3(-83.0, 3.0, 138.0), Vector3(-80.5, 1.8, 126.0))
	await snap("zoo-entrance.png")
	if sheet != "before":
		var gate = game.zoo_gate
		for side in [["outside", 130.0, Vector3(-78.0, 9.0, 133.0)], ["inside", 122.0, Vector3(-78.0, 9.0, 119.0)]]:
			game.player.global_position = town.to_global(Vector3(-78.0, .2, side[1]))
			preload("res://scripts/core/vehicle_controls.gd").toggle_gate(game, gate)
			await create_timer(2.0).timeout
			var tip: Vector3 = gate.left_hinge.to_global(Vector3(1.8, 0, 0))
			print("zoo gate opened from %s: player z %.1f, left leaf tip town z %.2f (gate z 126)" % [side[0], side[1], town.to_local(tip).z])
			view(town, side[2], Vector3(-78.0, 0.5, 126.0), 70.0)
			await snap("zoo-gate-from-%s.png" % side[0])
			preload("res://scripts/core/vehicle_controls.gd").toggle_gate(game, gate)
			await create_timer(2.0).timeout
	print("CIVIC FIXES CAPTURE done")
	quit()
