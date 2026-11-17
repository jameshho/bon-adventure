extends SceneTree
## The app flow (PWA phase 3, 12 Nov 2026; simplified 13 Nov 2026): scenes/app.tscn is the main
## scene; the title's Play leads to the character grid when there are no profiles; a new profile
## (avatar, then language tiles that never pick the same language twice) is created, named after
## its character, and selected; the town then builds in stages behind the loading screen (progress
## rises to 1, nothing 3D drawn meanwhile) with the profile's avatar as the player model; a new
## profile starts with the tutorial's units and gets the rest during the tutorial (home first);
## Settings lets the native language change (unlocked 14 Nov 2026) and offers "Switch player".
## Writes profile saves: isolated HOME, refuses to run when saves exist:
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --headless --path . --script res://docs/evidence/app-flow-20261112/verify.gd
## Prints "APP FLOW: N checks, M failures".
const SaveStore := preload("res://scripts/core/save_store.gd")
const ProfileManager := preload("res://scripts/core/profile_manager.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
var failures := 0
var checks := 0
var progress: Array = []
func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

func run():
	if FileAccess.file_exists("user://profiles/index.json") or FileAccess.file_exists(GameSettings.PATH):
		print("APP FLOW: refusing to run, saves exist (use an isolated HOME)")
		quit(1)
		return
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/app.tscn", "app.tscn is the main scene")
	var app: Node = load("res://scenes/app.tscn").instantiate()
	root.add_child(app)
	current_scene = app
	await process_frame
	var screens = app.screens
	check(screens != null and screens._page == "splash", "the splash shows first")
	screens.splash_done.emit()
	await process_frame
	check(screens._page == "avatar" and screens._content != null, "with no profiles Play leads to the character grid")
	screens._draft.avatar = "bruno"
	screens._show("languages")
	screens._pick_language("native", "en")
	screens._pick_language("foreign", "es")
	screens._pick_language("native", "es")
	check(screens._draft.native == "es" and screens._draft.foreign == "en", "picking the other side's language swaps the two")
	screens._pick_language("native", "en")
	screens._pick_language("foreign", "zh")
	var chosen := []
	screens.profile_chosen.connect(func(id: String) -> void: chosen.append(id))
	screens._create_profile()
	var manager = ProfileManager.shared()
	check(chosen == ["p1"] and manager.active_id == "p1", "Start creates and selects the profile")
	check(str(manager.active_profile().get("profile_name", "")) == "Bruno", "the profile is named after its character")
	check(GameSettings.shared().foreign == "zh", "the picked languages are saved to the profile")
	# start_town ran through the connection; wait for the town.
	for i in 6:
		await process_frame
	var main: Node = app.main
	check(main != null and main.staged_loading, "the town is built in stages")
	if main == null:
		finish()
		return
	main.loading_progress.connect(func(f: float) -> void: progress.append(f))
	check(root.disable_3d, "nothing 3D is drawn while the town loads")
	var frames := 0
	while main.process_mode == Node.PROCESS_MODE_DISABLED and frames < 3000:
		await process_frame
		frames += 1
	await process_frame
	# Home first (13 Nov 2026): a new profile's town is built with the tutorial's units only.
	var first_units: Array = main.apartment.get_meta("loaded_units", []).duplicate()
	check(frames > 2, "loading spans several frames (%d)" % frames)
	check(first_units == ["home", "supermarket"] and main.pending_units.size() == 17, "a new profile starts with the home and the supermarket only (%s)" % str(first_units))
	check(not progress.is_empty() and progress[-1] >= 0.999, "progress reaches 1 (%s)" % str(progress.back() if not progress.is_empty() else "none"))
	var rising := true
	for i in range(1, progress.size()):
		rising = rising and progress[i] >= progress[i - 1]
	check(rising, "progress only rises")
	check(not root.disable_3d and main.hud != null and main.player != null, "the town is drawn and playable after loading")
	var model: Node = main.player.get_node_or_null("Visual/BonBon")
	check(model != null and str(model.get_script().resource_path).ends_with("bear_sculpt.gd"), "the avatar (Bruno) is the player model")
	check(main.player.parts.size() == 4 and main.player.parts["Arm"].get_parent() == model, "the player animates the avatar's arms and feet")
	var shown: String = load("res://scripts/ui/app_screens.gd").new()._progress_text("p1")
	check(shown.contains("0"), "a saved character shows its language and words found (%s)" % shown)
	main.open_settings()
	check(not main.settings_panel._native_pick.disabled and main.settings_panel._switch_button.visible, "Settings lets the native language change and offers Switch player")
	main.close_menus()
	# The other units arrive one at a time while the tutorial plays (app.gd _load_rest()): none
	# in the house act, all behind the title cutscene, which waits for them (16 Nov 2026).
	check(main.get_node_or_null("FamilySession") == null, "the hospital's game waits for the hospital")
	# The tutorial begins after the warm-up (app.gd _on_town_ready()).
	var begin_by := Time.get_ticks_msec() + 30000
	while main.get_node_or_null("Tutorial") == null and Time.get_ticks_msec() < begin_by:
		await process_frame
	var tutorial: Node = main.get_node_or_null("Tutorial")
	var quiet_until := Time.get_ticks_msec() + 4000
	while Time.get_ticks_msec() < quiet_until:
		await process_frame
	check(tutorial != null and tutorial.act == 0 and main.pending_units.size() == 17, "no unit is added during the house act (%d pending)" % main.pending_units.size())
	var cut_started := Time.get_ticks_msec()
	if tutorial != null:
		await tutorial._play_cutscene("tutorial.title")
	var loaded: Array = main.apartment.get_meta("loaded_units", [])
	check(main.pending_units.is_empty() and loaded.size() == 19, "every unit is added behind the title cutscene (%d, %.1f s)" % [loaded.size(), (Time.get_ticks_msec() - cut_started) / 1000.0])
	var hospital: Node = main.apartment.get_node_or_null("RelocatedSites/Hospital")
	check(hospital != null and not hospital.has_meta("unit_placeholder") and hospital.get_child_count() > 0, "a late unit takes its site's place (no renamed copy)")
	check(main.get_node_or_null("FamilySession") != null and main.get_node("FamilySession").host != null, "a late unit's minigame is set up when it arrives")
	check(main.apartment.get_node("StaticRenderBatches").get_node_or_null("Unit_hospital") != null, "a late unit gets its render batches")
	finish()

func finish() -> void:
	SaveStore.remove_tree("user://profiles")
	print("APP FLOW: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
