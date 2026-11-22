extends SceneTree
## Vehicle headlights and the shared siren / flashing-lights component (21 Nov 2026;
## scripts/world/vehicle_headlights.gd, scripts/world/emergency_lights.gd, DriveableVehicle).
## Loads each road vehicle scene on its own (no Main, no saves, no town), so it is quick:
##   godot --headless --path . --script res://docs/evidence/vehicle-lights-20261121/verify.gd
## With `-- capture` (not headless) it also renders the three emergency vehicles and a car at
## night, lights and sirens on, to docs/evidence/vehicle-lights-20261121/night.png.
const Sound := preload("res://scripts/core/sound.gd")
const ROAD := ["car", "taxi", "police_car", "ambulance", "fire_truck", "truck", "box_truck", "bus",
		"subaru_outback", "scooter", "motorcycle"]
const SIRENS := ["police_car", "ambulance", "fire_truck"]
var failures := 0
var checks := 0

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok:
		failures += 1

func run() -> void:
	var sound = Sound.new()
	root.add_child(sound)
	var stage := Node3D.new()
	root.add_child(stage)
	var vehicles := {}
	var x := 0.0
	for scene_name in ROAD:
		var path := "res://scenes/props/vehicles/%s.tscn" % scene_name
		if not ResourceLoader.exists(path):
			continue
		var vehicle = load(path).instantiate()
		vehicle.position = Vector3(x, 0, 0)
		x += 7.0
		stage.add_child(vehicle)
		vehicles[scene_name] = vehicle
	await process_frame
	await physics_frame
	for scene_name in vehicles:
		var vehicle = vehicles[scene_name]
		if not vehicle is DriveableVehicle:
			print("note: %s is not a DriveableVehicle; skipped" % scene_name)
			continue
		check(vehicle.has_headlights(), "%s has headlights" % scene_name)
		check(vehicle.has_siren() == (scene_name in SIRENS), "%s siren only on emergency vehicles (%s)" % [scene_name, vehicle.has_siren()])
		vehicle.toggle_headlights()
		var lights = vehicle.get_node_or_null("Headlights")
		check(lights != null and lights.is_on and vehicle.headlights_on(), "%s: F turns the headlights on" % scene_name)
		if lights == null:
			continue
		var beam: SpotLight3D = lights.get_node_or_null("Beam")
		check(beam != null and beam.visible and not beam.shadow_enabled, "%s: one shadowless beam shows" % scene_name)
		if beam != null:
			var ahead: Vector3 = -beam.global_basis.z
			check(ahead.dot(vehicle.travel_forward()) > 0.9, "%s: the beam points forward (%.2f)" % [scene_name, ahead.dot(vehicle.travel_forward())])
		print("  %s: %d front lamp meshes, %d rear" % [scene_name, lights._front.size(), lights._rear.size()])
		# The motorcycle's model is merged meshes with no lamp parts: it gets the beam only.
		if scene_name != "motorcycle":
			check(lights._front.size() >= 1, "%s: front lamp meshes glow" % scene_name)
		for mesh in lights._front:
			check(mesh.material_override == lights._front_glow, "%s: %s glows white" % [scene_name, mesh.name])
			break
		var authored: Dictionary = lights._front.duplicate()
		vehicle.finish_exit()
		check(not vehicle.headlights_on() and not beam.visible, "%s: leaving switches the headlights off" % scene_name)
		var restored := true
		for mesh in authored:
			restored = restored and mesh.material_override == authored[mesh]
		check(restored, "%s: off restores the authored lamp materials" % scene_name)
	for scene_name in SIRENS:
		var vehicle = vehicles.get(scene_name)
		if vehicle == null:
			check(false, "%s scene loads" % scene_name)
			continue
		vehicle.toggle_siren()
		var siren = vehicle.get_node_or_null("EmergencyLights")
		check(siren != null and siren.is_on and vehicle.siren_on(), "%s: Q turns the siren on" % scene_name)
		if siren == null:
			continue
		print("  %s: %d red beacons, %d blue" % [scene_name, siren._beacons.red.size(), siren._beacons.blue.size()])
		check(siren._beacons.red.size() >= 1 and siren._beacons.blue.size() >= 1, "%s: red and blue beacons found" % scene_name)
		var loop = sound.looping(siren.cue, vehicle)
		check(loop != null and loop.playing, "%s: the %s loop plays" % [scene_name, siren.cue])
		if loop != null:
			var wav := loop.stream as AudioStreamWAV
			check(wav != null and wav.loop_mode != AudioStreamWAV.LOOP_DISABLED, "%s: the siren sound loops" % scene_name)
		var seen := {}
		for i in 60:
			siren._process(0.02)
			seen[siren._lit] = true
		check(seen.has("red") and seen.has("blue"), "%s: red and blue take turns (%s)" % [scene_name, seen.keys()])
		siren._show("red")
		check(siren._flash.red.emission_energy_multiplier > siren._flash.blue.emission_energy_multiplier, "%s: the lit side outshines the other" % scene_name)
		vehicle.finish_exit()
		check(not vehicle.siren_on() and sound.looping(siren.cue, vehicle) == null, "%s: leaving stops the siren and its sound" % scene_name)
		var restored := true
		for colour in siren._beacons:
			for mesh in siren._beacons[colour]:
				restored = restored and mesh.material_override == siren._beacons[colour][mesh]
		check(restored, "%s: off restores the beacons' authored materials" % scene_name)
	if "capture" in OS.get_cmdline_user_args():
		await capture(vehicles)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

## The emergency vehicles and a car side by side at night, all lights on.
func capture(vehicles: Dictionary) -> void:
	var stage: Node3D = vehicles.values()[0].get_parent()
	for scene_name in vehicles:
		if not scene_name in ["car", "police_car", "ambulance", "fire_truck"]:
			vehicles[scene_name].visible = false
	var spots := {"car": Vector3(-6, 0, 0), "police_car": Vector3(-2, 0, 6), "ambulance": Vector3(4, 0, 13), "fire_truck": Vector3(11, 0, 21)}
	for scene_name in spots:
		var v = vehicles[scene_name]
		v.position = spots[scene_name]
		v.rotation = Vector3(0, -0.5, 0)
		v.set_headlights(true)
		v.toggle_siren()
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(120, 120)
	ground.mesh = plane
	var asphalt := StandardMaterial3D.new()
	asphalt.albedo_color = Color(0.22, 0.23, 0.25)
	ground.material_override = asphalt
	stage.add_child(ground)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.03, 0.05, 0.1)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.25, 0.3, 0.45)
	env.environment.ambient_light_energy = 0.35
	env.environment.glow_enabled = true
	stage.add_child(env)
	var moon := DirectionalLight3D.new()
	moon.light_energy = 0.12
	moon.rotation = Vector3(-0.9, 0.6, 0)
	stage.add_child(moon)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.look_at_from_position(Vector3(-17, 4.5, 21), Vector3(3, 0.8, 8))
	camera.fov = 55
	camera.current = true
	for i in 8:
		await process_frame
	# One shot with every beacon bar on red, one on blue.
	for side in ["red", "blue"]:
		for scene_name in SIRENS:
			var siren = vehicles[scene_name].get_node("EmergencyLights")
			siren.set_process(false)
			siren._show(side)
		for i in 3:
			await process_frame
		root.get_texture().get_image().save_png("res://docs/evidence/vehicle-lights-20261121/night-%s.png" % side)
		print("captured night-%s.png" % side)
