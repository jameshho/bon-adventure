extends SceneTree
## Delivery truck made drivable (8 Nov 2026): registered as a DriveableVehicle, E boards through
## the driver door, W/S/A/D drive it, E leaves. Prints DRIVE lines; with --capture writes PNGs
## next to this script. Uses Main (saves progress): run with an isolated HOME (README).
## HOME=<scratch>/home VT_FOCUS=warehouse VT_SPAWN=none godot --path . --resolution 1400x900 --script res://docs/evidence/warehouse-20261108/truck_drive.gd -- --capture
var game
var truck
var failures := 0
var capture := false
func _initialize(): run.call_deferred()
func check(ok: bool, label: String) -> void:
	print("DRIVE ", "ok   " if ok else "FAIL ", label)
	if not ok: failures += 1
func snap(file: String) -> void:
	if not capture: return
	for i in range(6): await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png("res://docs/evidence/warehouse-20261108/" + file)
var cam: Camera3D
func look(eye: Vector3, target: Vector3) -> void:
	if cam == null:
		cam = Camera3D.new()
		game.add_child(cam)
		cam.fov = 48
	cam.current = true
	cam.global_position = eye
	cam.look_at(target)
func step(frames: int, gas := 0.0, steer := 0.0) -> void:
	for i in range(frames):
		truck.drive_step(1.0 / 60, gas, steer, 0.0)
		game.player._physics_process(1.0 / 60)
		await physics_frame
func run():
	capture = "--capture" in OS.get_cmdline_user_args()
	root.size = Vector2i(1400, 900)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(10): await process_frame
	truck = game.apartment.get_node("Warehouse/Exterior/Delivery truck")
	for v in game.driveable_vehicles:
		v.set_physics_process(false)
	check(truck is DriveableVehicle, "delivery truck is a DriveableVehicle")
	check(game.driveable_vehicles.has(truck), "registered with Main")
	check(truck.road_physics != null and truck.road_physics.wheels.size() == 4, "four road wheels")
	check(truck.vehicle_doors.size() == 1 and truck.vehicle_doors[0].name == "LeftDoor", "only the driver door is a boarding door")
	var home: Transform3D = truck.global_transform
	print("DRIVE start ", home.origin, " forward ", truck.travel_forward())
	check(truck.travel_forward().dot(Vector3(0, 0, -1)) > 0.99, "nose points the same way as before (-Z)")
	await physics_frame
	await physics_frame
	await step(60)
	check(absf(truck.global_position.y - home.origin.y) < 0.15, "settles on its wheels without sinking or floating (dy %.3f)" % (truck.global_position.y - home.origin.y))
	game.player.global_position = truck.boarding_step_point()
	await physics_frame
	check(game.closest_vehicle() == truck, "standing at the door picks the truck")
	look(truck.to_global(Vector3(-8, 3, 6)), truck.to_global(Vector3(-3.0, 1.4, .5)))
	await snap("truck-closed.png")
	check(game.toggle_vehicle() and game.active_vehicle == truck, "E boards")
	await step(int(truck.boarding_duration * .5 * 60))
	look(truck.to_global(Vector3(-8, 3, 6)), truck.to_global(Vector3(-3.0, 1.4, .5)))
	check(absf(truck.vehicle_doors[0].rotation.y) > .9, "driver door swings open")
	await snap("truck-boarding.png")
	await step(int(truck.boarding_duration * .8 * 60))
	check(not truck.boarding_busy(), "boarding finishes")
	var before: Vector3 = truck.global_position
	await step(240, 1.0)
	var moved: Vector3 = truck.global_position - before
	print("DRIVE forward 4 s: moved ", moved, " speed ", truck.current_speed)
	check(moved.z < -5.0 and absf(moved.x) < 1.0, "W drives it forward (-Z) about %.1f m" % -moved.z)
	check(absf(truck.global_position.y - home.origin.y) < 0.3, "stays on the ground while driving")
	truck.global_transform = home
	truck.road_physics.reset()
	await step(30)
	await step(90, 1.0)
	await step(90, 1.0, 1.0)
	var heading: Vector3 = truck.travel_forward()
	check(heading.dot(Vector3(0, 0, -1)) < 0.95, "steering turns it (heading %s)" % heading)
	look(truck.to_global(Vector3(-9, 4, 8)), truck.to_global(Vector3(-2, 1.2, 0)))
	await snap("truck-driving.png")
	await step(180, -1.0)
	check(truck.current_speed < 1.0 or truck.current_speed > -12.0, "S brakes / reverses")
	# Drive it back into the wall behind the lot: it must stop, not pass through.
	truck.global_transform = home
	truck.road_physics.reset()
	await step(60)
	await step(300, -1.0)
	var back: float = truck.global_position.z - home.origin.z
	print("DRIVE reversed toward the roll-up door: moved ", back)
	check(back < 4.5, "reversing into the building stops against it (moved %.1f m)" % back)
	await step(60)
	check(game.toggle_vehicle(), "E leaves")
	await step(int(truck.boarding_duration * 1.3 * 60))
	check(game.active_vehicle == null and game.player.riding_vehicle == null, "back on foot")
	print("DRIVE done, failures ", failures)
	quit(1 if failures > 0 else 0)
