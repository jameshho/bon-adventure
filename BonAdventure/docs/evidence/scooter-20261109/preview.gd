extends SceneTree
## Scooter and rider preview without the town (9 Nov 2026): the scooter prefab at town scale on a
## flat ground, BonBon riding it through the real boarding/riding code.
##   godot --path . --resolution 1200x900 --script res://docs/evidence/scooter-20261109/preview.gd -- [out_dir]
## Writes PNGs to out_dir (default user://scooter-preview). Touches no saves.
const Rider := preload("res://scripts/player/motorcycle_rider.gd")
var out := "user://scooter-preview"
var cam: Camera3D

func _initialize() -> void:
	run.call_deferred()

func shot(title: String) -> void:
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(title + ".png"))
	print("SHOT ", title)

## Distance from each of BonBon's paw tips to its grip (world metres).
func reach_report(player, bike, title: String) -> void:
	var bonbon: Node3D = player.get_node("Visual/BonBon")
	var line := title
	for key in ["Arm", "Arm_2"]:
		var side := -1.0 if key.ends_with("_2") else 1.0
		var moved: Transform3D = player.parts[key].transform * player.rest_poses[key].affine_inverse()
		var tip: Vector3 = bonbon.global_transform * (moved * Vector3(Rider.ARM_TIP.x * side, Rider.ARM_TIP.y, Rider.ARM_TIP.z))
		var shoulder := Vector3(Rider.SHOULDER.x * side, Rider.SHOULDER.y, Rider.SHOULDER.z)
		var hang := Vector3(Rider.ARM_TIP.x * side, Rider.ARM_TIP.y, Rider.ARM_TIP.z) - shoulder
		var reach: Vector3 = bonbon.global_transform.affine_inverse() * Rider.grip(bike, "Near" if side > 0 else "Far").global_position - shoulder
		line += " k=%.2f reach=%s" % [reach.length() / hang.length(), reach]
		line += " %s->grip %.3f" % [key, tip.distance_to(Rider.grip(bike, "Near" if side > 0 else "Far").global_position)]
	var seat_gap: float = player.visual.global_position.distance_to(bike.boarding_seat().origin)
	print("REACH ", line, " seat offset %.3f" % seat_gap, " belly-to-cushion %.3f" % seat_contact(player, bike))

## Smallest height of BonBon's belly above the seat cushion's surface (negative: pressed into it).
static func seat_contact(player, bike) -> float:
	var cushion: MeshInstance3D = bike.get_node("Seat/Visual")
	var to_cushion: Transform3D = cushion.global_transform.affine_inverse()
	var torso: Node3D = player.get_node("Visual/BonBon/Torso")
	var best := INF
	for m in torso.find_children("*", "MeshInstance3D", true, false):
		if m.mesh == null: continue
		for v in m.mesh.get_faces():
			var p: Vector3 = m.global_transform * v
			var q: Vector3 = to_cushion * p
			var r2 := q.x * q.x + q.z * q.z
			if r2 >= .2: continue
			var surface: Vector3 = cushion.global_transform * Vector3(q.x, sqrt(.25 - r2), q.z)
			best = minf(best, p.y - surface.y)
	return best

func view(target: Vector3, from: Vector3) -> void:
	cam.global_position = target + from
	cam.look_at(target, Vector3.UP)

func run() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty(): out = args[0]
	# Ticks are stepped by hand between frames here; interpolation would draw stale poses.
	physics_interpolation = false
	DirAccess.make_dir_recursive_absolute(out)
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(.72, .84, .93)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(.75, .78, .82)
	env.environment.ambient_light_energy = .7
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.shadow_enabled = true
	world.add_child(sun)
	var ground := StaticBody3D.new()
	var plane := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400, 1, 400)
	plane.shape = box
	plane.position.y = -.5
	ground.add_child(plane)
	var floor_mesh := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(400, 400)
	floor_mesh.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(.55, .57, .58)
	floor_mesh.material_override = fm
	ground.add_child(floor_mesh)
	ground.name = "Road terrain"
	world.add_child(ground)
	var holder := Node3D.new()
	holder.scale = Vector3.ONE * 1.3
	world.add_child(holder)
	var bike: DriveableVehicle = load("res://scenes/props/vehicles/scooter.tscn").instantiate()
	holder.add_child(bike)
	# _ready switches physics processing on; this preview steps the scooter by hand.
	bike.set_physics_process(false)
	bike.position = Vector3(0, .05, 0)
	var player = load("res://scenes/player/bonbon_player.tscn").instantiate()
	world.add_child(player)
	player.set_physics_process(false)
	player.set_process(false)
	player.set_process_input(false)
	player.set_process_unhandled_input(false)
	player.global_position = bike.to_global(Vector3(-.6, 0, 3.2))
	cam = Camera3D.new()
	cam.fov = 38
	world.add_child(cam)
	cam.current = true
	for i in range(3): await physics_frame
	var c := bike.global_position + Vector3.UP * .8
	player.visible = false
	view(c, Vector3(-3.2, 1.4, 3.6))
	await shot("parked-three-quarter")
	player.visible = true
	# Board through the real sequence and grab the hop halfway.
	bike.occupied = true
	bike.begin_boarding()
	player.board_vehicle(bike)
	var t := 0.0
	var mid_shot := false
	while bike.boarding_busy():
		bike.drive_step(1.0 / 60, 0, 0, 0)
		player._physics_process(1.0 / 60)
		if not mid_shot and bike.boarding_progress > .62:
			mid_shot = true
			view(c, Vector3(-1.5, 1.6, 5.0))
			await shot("mount-hop")
	for i in range(30):
		bike.drive_step(1.0 / 60, 0, 0, 0)
		player._physics_process(1.0 / 60)
	view(c + Vector3.UP * .5, Vector3(0, .5, 5.8))
	reach_report(player, bike, "seated-side")
	await shot("seated-side")
	view(c + Vector3.UP * .4, Vector3(-4.2, 1.2, 3.2))
	await shot("seated-front-quarter")
	view(c + Vector3.UP * .4, Vector3(4.0, 2.2, 2.5))
	await shot("seated-rear-quarter")
	# Ride: accelerate, then a steady left turn, then brake.
	for i in range(90):
		bike.drive_step(1.0 / 60, 1, 0, 0)
		player._physics_process(1.0 / 60)
	view(bike.global_position + Vector3.UP * 1.2, bike.global_basis.orthonormalized() * Vector3(-4.2, .5, 1.6))
	reach_report(player, bike, "accelerating")
	await shot("accelerating")
	for i in range(80):
		bike.drive_step(1.0 / 60, .6, -1, 0)
		player._physics_process(1.0 / 60)
	print("LEAN ", bike.lean, " speed ", bike.current_speed)
	view(bike.global_position + Vector3.UP * 1.1, bike.global_basis.orthonormalized() * Vector3(-4.6, .6, 0))
	reach_report(player, bike, "turn-lean-front")
	await shot("turn-lean-front")
	for i in range(25):
		bike.drive_step(1.0 / 60, -1, 0, 0)
		player._physics_process(1.0 / 60)
	print("BRAKE accel ", bike.longitudinal_accel)
	view(bike.global_position + Vector3.UP * 1.1, bike.global_basis.orthonormalized() * Vector3(-.5, .5, 4.4))
	reach_report(player, bike, "braking-side")
	await shot("braking-side")
	quit()
