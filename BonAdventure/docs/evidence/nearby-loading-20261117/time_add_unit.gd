extends SceneTree
## Where Main.add_unit()'s time goes (17 Nov 2026, nearby loading stage 1): runs the same steps
## as Main.add_unit() for each named unit with a timer around each, plush put-backs one per frame.
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --resolution 1280x800 \
##   --script res://docs/evidence/nearby-loading-20261117/time_add_unit.gd -- home restaurants mystery hospital
const ModularTown := preload("res://scripts/world/modular_town.gd")
const DoorAnimator := preload("res://scripts/core/door_animator.gd")
const VehicleControls := preload("res://scripts/core/vehicle_controls.gd")
var main: Node
var rows := {}
var t := 0

func _initialize() -> void:
	run.call_deferred()

func lap(key: String, step: String) -> void:
	var now := Time.get_ticks_usec()
	rows[key].append("%s %.1f" % [step, (now - t) / 1000.0])
	t = now

func run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 800))
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	main.staged_loading = true
	main.initial_units = ["barn"]
	get_root().add_child(main)
	await main.town_ready
	for i in 30:
		await process_frame
	for key in OS.get_cmdline_user_args():
		rows[key] = []
		main.pending_units.erase(key)
		t = Time.get_ticks_usec()
		var held: Array = []
		var parts: Array = ModularTown.add_unit(main.apartment, key, held)
		lap(key, "instance+place+ready")
		var worst := 0.0
		for entry in held:
			await process_frame
			var t0 := Time.get_ticks_usec()
			ModularTown.put_back(main.apartment, entry)
			worst = maxf(worst, (Time.get_ticks_usec() - t0) / 1000.0)
		rows[key].append("plush %d worst %.1f" % [held.size(), worst])
		t = Time.get_ticks_usec()
		ModularTown.finish_refs(main.apartment)
		var SignLanguage := preload("res://scripts/world/sign_language.gd")
		for part in parts:
			main.restore_editor_door_states(part)
			SignLanguage.translate_all(part)
		lap(key, "doors+signs")
		main.reference_layout.add_unit()
		lap(key, "reference_layout")
		main.register_driveable_vehicles()
		lap(key, "vehicles")
		for part in parts:
			main.area_vocabulary.add(part, main.apartment, main.zones, main.vocabulary, main.vocabulary_aliases)
		lap(key, "area_vocabulary")
		for part in parts:
			main.seating.add_seats(part)
		lap(key, "seats")
		for part in parts:
			preload("res://scripts/characters/house_characters.gd").solidify_figures(main, part)
		lap(key, "solidify")
		DoorAnimator.make_interactables(main)
		lap(key, "door interactables (town)")
		VehicleControls.make_interactables(main)
		lap(key, "vehicle interactables")
		main.area_vocabulary.drop_interactables(main.apartment)
		lap(key, "drop_interactables (town)")
		for part in parts:
			main.day_night.bind_lamps(part)
		lap(key, "lamps")
		main.render_culling.add_parts(main, parts, key)
		lap(key, "render add_parts")
		main.apply_world_language()
		lap(key, "world language (town)")
		main.update_progress_display()
		main.unit_added.emit(key)
		lap(key, "unit_added listeners")
		for i in 10:
			await process_frame
		print("TIMING ", key, ": ", ", ".join(rows[key]))
	quit()
