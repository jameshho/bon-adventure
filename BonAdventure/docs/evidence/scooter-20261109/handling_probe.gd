extends SceneTree
## Scooter handling probe (9 Nov 2026): holds a steering key for several seconds, on a flat pad and
## on the real route out of the restaurant lot, and logs steering, turn rate, lean and support, plus
## every tick where the turn stops dead or the lean drops sharply.
##   HOME=<scratch>/home VT_FOCUS=restaurants VT_SPAWN=none godot --headless --path . \
##     --fixed-fps 60 --script res://docs/evidence/scooter-20261109/handling_probe.gd
## Writes no files.
var game
var bike: DriveableVehicle

func _initialize() -> void:
	run.call_deferred()

func step(gas: float, steer: float, brake := 0.0) -> void:
	bike.occupied = true
	bike.drive_step(1.0 / 60, gas, steer, brake)
	game.player._physics_process(1.0 / 60)

## Holds the inputs for `ticks`, logging every 15 ticks and any sudden change.
func hold(title: String, ticks: int, gas: float, steer: float) -> void:
	var physics = bike.road_physics
	var last_yaw: float = physics.yaw_velocity
	var last_lean := bike.lean
	var last_supported: bool = physics.supported
	var turned := 0.0
	var heading := bike.global_basis.orthonormalized().get_euler().y
	for i in range(ticks):
		step(gas, steer)
		var h := bike.global_basis.orthonormalized().get_euler().y
		turned += absf(angle_difference(heading, h))
		heading = h
		var events := []
		if absf(last_yaw) > .2 and absf(physics.yaw_velocity) < .02: events.append("YAW STOPPED")
		if last_lean - bike.lean > .05 or bike.lean - last_lean > .05: events.append("LEAN JUMP %.2f->%.2f" % [last_lean, bike.lean])
		if physics.supported != last_supported: events.append("SUPPORTED %s" % physics.supported)
		if i % 15 == 0 or not events.is_empty():
			print("%s t=%.2f v=%.1f steer=%.3f yaw=%.2f lean=%.2f contacts=%d grip=%.2f y=%.2f %s" % [title, i / 60.0, bike.current_speed, physics.steering_angle, physics.yaw_velocity, bike.lean, physics.contacts.size(), physics.grip_usage, bike.global_position.y, " ".join(events)])
		last_yaw = physics.yaw_velocity
		last_lean = bike.lean
		last_supported = physics.supported
	print("%s total turned %.0f deg" % [title, rad_to_deg(turned)])

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(3): await physics_frame
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	for vehicle in game.driveable_vehicles:
		vehicle.set_physics_process(false)
	bike = game.apartment.get_node("Vehicles/Motorcycle")
	var parked := bike.global_transform
	# Board (skipping the walk) on a flat pad far from the town.
	var pad = game.box("Probe pad", Vector3.ZERO, Vector3(900, .4, 900), Color.WHITE, "", true)
	pad.global_position = Vector3(3000, 0, 3000)
	await physics_frame
	bike.global_transform = Transform3D(parked.basis, Vector3(3000, .45, 3000))
	game.player.global_position = bike.boarding_step_point()
	game.toggle_vehicle()
	for i in range(160): step(0, 0)
	hold("PAD accel", 150, 1, 0)
	hold("PAD coast", 120, 0, 0)
	hold("PAD accel2", 120, 1, 0)
	hold("PAD left-hold", 360, .6, -1)
	hold("PAD coast-left", 120, 0, -1)
	hold("PAD release", 90, .6, 0)
	hold("PAD right-hold-fast", 300, 1, 1)
	hold("PAD brake", 200, 0, 0)
	# The town: back out of the stall and hold left onto the street, as a learner would.
	bike.road_physics.reset()
	bike.global_transform = parked
	for i in range(30): step(0, 0)
	hold("TOWN reverse", 110, -1, 1)
	hold("TOWN stop", 40, 0, 0)
	hold("TOWN accel", 60, 1, 0)
	hold("TOWN left-hold", 300, .7, -1)
	hold("TOWN right-hold", 300, .7, 1)
	quit()
