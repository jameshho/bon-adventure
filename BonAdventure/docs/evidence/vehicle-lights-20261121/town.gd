extends SceneTree
## Vehicle lights in the real town (21 Nov 2026): at night BonBon boards each emergency vehicle
## (headlights come on by themselves), the HUD shows Lights and Siren, Siren starts the flashing
## lights and the sound, a plain car shows Lights only, and getting out switches everything off.
## Main saves: run with an isolated HOME (README), e.g.
##   HOME=$(mktemp -d) VT_FOCUS=all VT_SPAWN=none godot --path . --resolution 1280x800 \
##     --script res://docs/evidence/vehicle-lights-20261121/town.gd
## Not headless, it also saves town-<vehicle>.png here (the HUD and the lit vehicle at night).
var game
var checks := 0
var failures := 0

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok:
		failures += 1

func button(title: String) -> Button:
	return game.hud.ui_root.find_child(title, true, false) as Button

func drive_frames(vehicle, count: int, gas := 0.0) -> void:
	for i in count:
		vehicle.drive_step(1.0 / 60, gas, 0.0, 0.0)
		game.player._physics_process(1.0 / 60)
		await process_frame

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 4:
		await process_frame
	game.day_night.set_time(22 * 60)
	game.day_night.pause()
	var by_key := {}
	for vehicle in game.driveable_vehicles:
		var key := str(vehicle.get_meta("word_key", ""))
		if not by_key.has(key):
			by_key[key] = vehicle
	print("road vehicles in town: ", by_key.keys())
	var shots := DisplayServer.get_name() != "headless"
	for key in ["police car", "ambulance", "fire truck", "car"]:
		var vehicle = by_key.get(key)
		if vehicle == null:
			print("note: no driveable %s in the town" % key)
			continue
		game.player.global_position = vehicle.boarding_step_point() + Vector3(0, 0.1, 0)
		await physics_frame
		check(game.board_vehicle(vehicle) and game.active_vehicle == vehicle, "%s: BonBon boards it" % key)
		await drive_frames(vehicle, roundi(vehicle.boarding_duration * 60) + 30)
		check(vehicle.headlights_on(), "%s: headlights on by themselves at night" % key)
		var lights := button("Headlights button")
		var siren := button("Siren button")
		check(lights != null and lights.visible, "%s: the Lights button shows" % key)
		check(siren != null and siren.visible == vehicle.has_siren(), "%s: the Siren button shows only on emergency vehicles" % key)
		if lights != null and lights.visible:
			lights.pressed.emit()
			check(not vehicle.headlights_on(), "%s: Lights switches them off" % key)
			lights.pressed.emit()
			check(vehicle.headlights_on(), "%s: and on again" % key)
		if siren != null and siren.visible:
			siren.pressed.emit()
			check(vehicle.siren_on(), "%s: Siren starts the flashing lights" % key)
			var sound = preload("res://scripts/core/sound.gd").shared()
			var cue: String = vehicle.get_node("EmergencyLights").cue
			check(sound != null and sound.looping(cue, vehicle) != null, "%s: the siren sound plays" % key)
		await drive_frames(vehicle, 50, 0.6)
		if shots:
			for i in 6:
				await process_frame
			root.get_texture().get_image().save_png("res://docs/evidence/vehicle-lights-20261121/town-%s.png" % key.replace(" ", "-"))
		await drive_frames(vehicle, 120, 0.0)
		game.toggle_vehicle()
		for i in 200:
			if game.active_vehicle == null:
				break
			await drive_frames(vehicle, 1)
		check(game.active_vehicle == null, "%s: BonBon gets out" % key)
		check(not vehicle.headlights_on() and not vehicle.siren_on(), "%s: getting out switches the lights and siren off" % key)
		check(lights == null or not lights.visible, "%s: the buttons hide on foot" % key)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
