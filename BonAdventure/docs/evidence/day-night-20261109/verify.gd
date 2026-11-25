extends SceneTree
## Day-night cycle and HUD clock (9 Nov 2026; scripts/world/day_night.gd, scripts/ui/day_clock.gd,
## data/day_night.json). Headless, writes no files.
## Checks: one sun (no new lights), start at the shared "now", keyframe blending and sun path,
## no sun shadows, lamp heads glow only at night and keep their material through batching,
## midnight wrap both ways, −/+ pause the cycle, Resume restarts it, the clock text and panel
## (open, − / +, Close keeps the time, Esc closes it), warm fill indoors at night with the outside left at night (roof and walls;
## since 10 Nov 2026 a probe box fitted to the building, the street outside the door outside it),
## the sun disc / moon in the light's direction and the cloud tint by hour; the one graphics setting
## (23 Nov 2026; Low and High until then): no sun shadows at any hour and a fogged view distance.
## Uses Main, which saves progress and settings: run with an isolated HOME (README), e.g.
##   python3 tools/run_checks.py --only day_night
const GameClock := preload("res://scripts/learning/game_clock.gd")
const ModularTown := preload("res://scripts/world/modular_town.gd")
var failures := 0
var checks := 0

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok:
		failures += 1

func wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var cycle = game.day_night
	check(cycle != null and cycle.sun != null, "Main has the day-night cycle and its sun")
	check(cycle.sun.get_parent() == game and cycle.sun.name == "Soft daylight", "the sun is Main's \"Soft daylight\" (render_culling finds it)")
	var world: World3D = game.get_world_3d()
	var suns := 0
	for light in root.find_children("*", "DirectionalLight3D", true, false):
		if light.get_world_3d() == world:
			suns += 1
	check(suns == 1, "one directional light in the town world (found %d)" % suns)
	check(cycle.find_children("*", "Light3D", true, false).is_empty(), "the cycle adds no other lights")
	check(absf(cycle.minutes - GameClock.shared().now) < 5.0, "starts at the shared now (%s vs %s)" % [GameClock.clock(int(cycle.minutes)), GameClock.clock(GameClock.shared().now)])
	check(is_equal_approx(cycle.cycle_minutes, 30.0), "default cycle is 30 minutes")
	check(is_equal_approx(game.get_viewport().scaling_3d_scale, 1.0), "desktop keeps full 3D resolution (the web-only scale is off)")

	# One graphics setting (23 Nov 2026, render_culling.gd apply_view()): no sun shadows and depth
	# fog opaque at the 130 m view distance.
	cycle.set_time(12 * 60.0)
	check(not cycle.sun.shadow_enabled, "no sun shadows at noon")
	check(cycle.environment.fog_mode == Environment.FOG_MODE_DEPTH and is_equal_approx(cycle.environment.fog_depth_end, game.player.camera.far) and is_equal_approx(game.player.camera.far, 130.0),
		"depth fog is opaque at the camera's far plane (%.0f m)" % game.player.camera.far)

	# Lamps: 19 streetlight heads and 8 bridge globes, the zoo zones' 4 lamp posts and 2 gate
	# lanterns (base step zoo_zones, 12 Nov 2026) and the chapel's 2 door lanterns and 12
	# chandelier bulbs (chapel.gd night_lights, 11-12 Nov 2026): 47 heads, one glow material per
	# original material (4).
	var glowing: Array = game.apartment.find_children("*", "MeshInstance3D", true, false).filter(func(m): return m.has_meta("night_glow"))
	check(glowing.size() == 47, "47 lamp heads glow at night (found %d)" % glowing.size())
	check(cycle.lamp_materials.size() >= 1 and cycle.lamp_materials.size() <= 4, "lamps share %d glow material(s)" % cycle.lamp_materials.size())
	var batched_glow := 0
	for batch in game.apartment.find_children("*", "MultiMeshInstance3D", true, false):
		# lamp_materials is typed (StandardMaterial3D): other batches may carry a ShaderMaterial.
		if batch.material_override is StandardMaterial3D and batch.material_override in cycle.lamp_materials:
			batched_glow += batch.multimesh.instance_count
	var unbatched_glow := glowing.filter(func(m): return m.is_visible_in_tree()).size()
	check(batched_glow + unbatched_glow == 47, "every lamp head is drawn with a glow material (batched %d, own %d)" % [batched_glow, unbatched_glow])

	# Noon: the original daylight, softened; shadows on, lamps off.
	cycle.pause()
	cycle.set_time(12 * 60)
	check(not cycle.sun.shadow_enabled, "noon: no sun shadows (one graphics setting)")
	check(absf(cycle.sun.rotation_degrees.x + 53.0) < 0.5 and absf(cycle.sun.rotation_degrees.y + 18.0) < 0.5, "noon: sun at the old direction (%s)" % cycle.sun.rotation_degrees)
	check(absf(cycle.sun.light_energy - 0.56) < 0.01, "noon: sun energy 0.56 (%.3f)" % cycle.sun.light_energy)
	check(cycle.environment.sky.sky_material.sky_top_color.is_equal_approx(Color("4f8fd0")), "noon: original sky top colour")
	check(cycle.lamp_materials.all(func(m): return m.emission_energy_multiplier == 0.0), "noon: lamps off")
	var noon_sky: Color = cycle.environment.sky.sky_material.sky_top_color
	# Sky decor follows the light (sun disc / moon, cloud tint).
	var camera: Camera3D = game.get_viewport().get_camera_3d()
	check(cycle.sky_disc != null and cycle.sky_disc.get_parent() == cycle and game.apartment.find_child("Sky sun", true, false) == null, "the sun disc left the batched town")
	var cloud_meshes := 0
	for mesh_node in game.apartment.find_children("*", "MeshInstance3D", true, false):
		if cycle.cloud_materials.has(mesh_node.material_override):
			cloud_meshes += 1
	check(cycle.cloud_materials.size() == 1 and cloud_meshes == 32, "the 32 cloud puffs share one tint material (%d materials, %d puffs)" % [cycle.cloud_materials.size(), cloud_meshes])
	var toward := func(light: DirectionalLight3D) -> float:
		return (cycle.sky_disc.global_position - camera.global_position).normalized().dot(light.global_basis.z)
	check(cycle.sky_disc.visible and toward.call(cycle.sun) > 0.99, "noon: the disc sits where the light comes from (dot %.3f)" % toward.call(cycle.sun))
	check(Color(cycle.disc_material.get_shader_parameter("disc_color")).is_equal_approx(Color("ffe271")) and cycle.cloud_materials[0].albedo_color.is_equal_approx(Color.WHITE), "noon: yellow sun, white clouds")
	var noon_clouds: Color = cycle.cloud_materials[0].albedo_color
	cycle.set_time(18 * 60 + 45)
	check(cycle.sky_disc.global_position.y < camera.global_position.y, "18:45: the sun disc has set below the horizon")
	cycle.set_time(18 * 60)
	check(cycle.cloud_materials[0].albedo_color.b < cycle.cloud_materials[0].albedo_color.r - 0.1 and Color(cycle.disc_material.get_shader_parameter("disc_color")).g < 0.8, "18:00: orange sun, warm clouds")
	# Golden hour, sunset, night.
	cycle.set_time(17 * 60 + 45)
	check(cycle.sun.light_color.r > cycle.sun.light_color.b + 0.2 , "golden hour: warm sun")
	check(cycle.sun.rotation_degrees.x > -30.0, "golden hour: low sun (%.1f°)" % -cycle.sun.rotation_degrees.x)
	cycle.set_time(0)
	check(not cycle.sun.shadow_enabled, "midnight: no shadows (moon)")
	check(cycle.sun.light_color.b > cycle.sun.light_color.r, "midnight: cool moonlight")
	check(cycle.environment.sky.sky_material.sky_top_color.v < noon_sky.v * 0.5, "midnight: dark sky")
	check(cycle.environment.ambient_light_energy >= 0.4, "midnight: ambient stays bright enough to navigate (%.2f)" % cycle.environment.ambient_light_energy)
	check(cycle.lamp_materials.all(func(m): return m.emission_energy_multiplier > 1.0), "midnight: lamps on")
	check(cycle.sky_disc.visible and toward.call(cycle.sun) > 0.99 and Color(cycle.disc_material.get_shader_parameter("disc_color")).b >= Color(cycle.disc_material.get_shader_parameter("disc_color")).r, "midnight: a pale moon where the moonlight comes from")
	check(cycle.cloud_materials[0].albedo_color.v < noon_clouds.v * 0.7, "midnight: clouds dimmed")
	cycle.set_time(19 * 60)
	check(not cycle.sky_disc.visible, "19:00: no disc while the light is off (the moon fades in after)")
	cycle.set_time(6 * 60 + 30)
	check(cycle.lamp_materials.all(func(m): return m.emission_energy_multiplier > 0.0 and m.emission_energy_multiplier < 1.0), "sunrise: lamps dimming")
	# Continuity: no jumps in any blended value across the keyframes and the sun/moon switch.
	var worst := 0.0
	var previous: Dictionary = cycle.sample(0.0)
	for step in range(1, 24 * 12 + 1):
		var now: Dictionary = cycle.sample(step / 12.0)
		for key in now:
			var a = previous[key]
			var b = now[key]
			var jump: float = (absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)) if a is Color else absf(a - b) / maxf(1.0, absf(a))
			worst = maxf(worst, jump)
		previous = now
	check(worst < 0.35, "keyframes blend smoothly in 5-minute steps (largest step %.3f)" % worst)
	check(cycle.sample(5.5).sun_energy < 0.01 and cycle.sample(19.0).sun_energy < 0.01, "sun and moon swap while the light is off (05:30, 19:00)")

	# Midnight wrap and one-hour steps.
	cycle.resume()
	cycle.set_time(23 * 60 + 30)
	cycle.step_hours(1)
	check(cycle.clock_minute() == 30, "23:30 + 1 h = 00:30 (got %s)" % GameClock.clock(cycle.clock_minute()))
	check(cycle.paused, "a step pauses the cycle")
	check(game.day_clock.time_text().begins_with("12:30") or game.day_clock.time_text().contains("12:30"), "clock shows 12:30 after midnight (%s)" % game.day_clock.time_text())
	cycle.step_hours(-1)
	check(cycle.clock_minute() == 23 * 60 + 30, "00:30 − 1 h = 23:30")
	cycle.set_time(11 * 60 + 15)
	cycle.step_hours(1)
	check(game.day_clock.time_text().contains("12:15"), "noon hour shows 12:15 (%s)" % game.day_clock.time_text())
	var held: float = cycle.minutes
	await wait(0.6)
	check(cycle.minutes == held, "paused time does not move")
	cycle.resume()
	await wait(0.6)
	var moved: float = cycle.minutes - held
	check(moved > 0.3 and moved < 2.0, "resumed time moves at the 30-minute day (%.2f game minutes in 0.6 s)" % moved)

	# The clock panel.
	var clock = game.day_clock
	check(clock.pill.visible and not clock.panel.visible, "clock pill shown, panel closed")
	clock.pill.pressed.emit()
	check(clock.panel.visible, "clicking the clock opens the panel")
	check(game.popups.top() == clock.panel, "the open panel is the top popup (Esc closes it)")
	cycle.resume()
	var before: int = cycle.clock_minute()
	clock.forward_button.pressed.emit()
	check(cycle.paused and (cycle.clock_minute() - before + 1440) % 1440 == 60, "+ moves one hour and pauses")
	check(clock.status_label.text == clock.UiText.t("hud.clock_paused") and not clock.resume_button.disabled, "panel says paused; Resume enabled")
	clock.back_button.pressed.emit()
	clock.back_button.pressed.emit()
	check((before - cycle.clock_minute() + 1440) % 1440 == 60, "− twice moves back two hours")
	var chosen: int = cycle.clock_minute()
	clock.close_button.pressed.emit()
	check(not clock.panel.visible and cycle.clock_minute() == chosen and cycle.paused, "Close keeps the chosen time")
	clock.pill.pressed.emit()
	clock.resume_button.pressed.emit()
	check(not cycle.paused and clock.resume_button.disabled, "Resume restarts time")
	clock.close()

	# Indoors: the ambient keeps its daytime value under a roof at night.
	cycle.pause()
	cycle.set_time(0)
	var market := ModularTown.building(game.apartment, "supermarket")
	game.player.set_physics_process(false)
	game.player.global_position = market.to_global(Vector3(-33.0, 0.1, 44.0))
	await wait(1.6)
	check(cycle.indoor > 0.99, "inside the supermarket counts as indoors")
	# Since 10 Nov 2026 the warm fill is a ReflectionProbe box fitted to the building; the
	# environment keeps the night ambient, so the street seen through the door stays night.
	var probe: ReflectionProbe = cycle.room_probe
	var head: Vector3 = game.player.global_position + Vector3.UP * 1.6
	check(probe != null and probe.visible and cycle.in_room_fill(head), "indoors at night: the indoor fill box is shown around the player")
	# The fill strength is data/day_night.json "indoor" (0.54 until 25 Nov 2026, then 0.62 with the sun fading indoors).
	check(probe != null and absf(probe.ambient_color_energy - cycle._indoor_energy) < 0.01, "indoors at night: warm ambient fill inside the box (%.2f)" % (probe.ambient_color_energy if probe != null else 0.0))
	check(cycle.environment.ambient_light_color.is_equal_approx(cycle.sample(0.0).ambient_color), "indoors at night: the global ambient keeps the night colour")
	check(not cycle.in_room_fill(market.to_global(Vector3(-33.0, 1.7, 22.0))), "indoors at night: the street outside the door is outside the fill box")
	check(cycle.sun.light_energy < 0.01 and not cycle.sun.shadow_enabled, "indoors at night: no moonlight through the roof, no noon sun")
	check(cycle.environment.sky.sky_material.sky_top_color.v < 0.5, "indoors at night: the sky stays night")
	cycle.set_time(12 * 60)
	# Since 25 Nov 2026 (improvement plan GFX-03) the sun fades indoors like the moon (no shadows
	# stop it at the roof); its direction and colour, and the sky, stay the time of day's.
	check(cycle.sun.light_energy < 0.01 and cycle.sun.rotation_degrees.is_equal_approx(cycle.sun_rotation(12.0)), "indoors by day: the sun fades through the roof, its direction unchanged")
	cycle.set_time(0)
	game.player.global_position = market.to_global(Vector3(-33.0, 0.1, 22.0))
	await wait(1.6)
	check(cycle.indoor < 0.01, "outside the door counts as outdoors")
	check(cycle.sun.light_energy > 0.1 and cycle.sun.light_energy < 0.3 and not cycle.sun.shadow_enabled, "outdoors at night: moonlight without shadows")
	check(cycle.sun.sky_mode == DirectionalLight3D.SKY_MODE_LIGHT_ONLY, "the sun is not drawn in the sky (no dark sunset halo)")

	print("DAY NIGHT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
