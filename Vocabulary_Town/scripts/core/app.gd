extends Node
## The game's entry scene (scenes/app.tscn, run/main_scene since PWA phase 3, 12 Nov 2026):
## Title (Play) -> Pick your character (saved ones, or a new one + languages) -> Loading -> Town
## (simplified 13 Nov 2026, user; app_screens.gd).
## The town is the unchanged scenes/main.tscn, instantiated only after a profile is chosen,
## so that profile's saves and languages are in place before anything builds text. Main is
## told to build in stages (Main.staged_loading) and reports loading_progress / town_ready to
## the loading screen. Checks and tools keep loading main.tscn directly (no profile: the flat
## user:// saves, see save_store.gd).
## Switching profile (Settings) reloads this scene straight to the profile select.
## When the town is built, the loading screen stays up while the first views are drawn
## (_warm_up(): the camera looks all round the player so every direction's shaders and
## textures are ready, then frames must come steadily) so play starts smoothly (user,
## 13 Nov 2026: the game must be well loaded before the player can play).
## Once the town is ready, a profile that has not finished the welcome tutorial plays it
## (tutorial.gd, phase 6); Settings' "Replay" plays it again.
## Home first (staged loading, 13 Nov 2026, user; measured in docs/guides/FINAL_VERIFICATION.md): a
## profile that will play the tutorial starts with only the base town and TUTORIAL_UNITS (the
## house and the shop, every place the tutorial goes; the park is in the base), so play starts
## about twice as soon. _load_rest() then adds the other buildings one at a time (each plush
## character in its own frame, so a freeze is one plush's sculpting at most), at quiet moments
## of the tutorial: a fade, the title cutscene or a line of dialogue being read. When the tutorial ends or is skipped, what is left loads at once
## behind the loading screen. Profiles that finished the tutorial load the whole town as before.
## Web, after the browser dropped the graphics (WebGL context loss, 14 Nov 2026): the page reloads
## and web_resume.gd's note sends this scene straight to that profile's town, at the same spot.
const MAIN_SCENE := "res://scenes/main.tscn"
const ProfileManager := preload("res://scripts/core/profile_manager.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const AppScreens := preload("res://scripts/ui/app_screens.gd")
const LoadingScreen := preload("res://scripts/ui/loading_screen.gd")
const Tutorial := preload("res://scripts/learning/tutorial.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
const WebResume := preload("res://scripts/core/web_resume.gd")

## Warm-up: the camera looks in WARM_HEADINGS directions, one drawn frame each (70° tall view,
## about 100° wide in landscape, so six overlap all round), then needs this many steady frames
## in a row, at most WARM_MAX_SECONDS. (14 Nov 2026: was a 1.6 s turn whose steps were capped at
## 0.1 s, so slow compiling frames stretched it, plus 20 steady frames. Native, shaders already
## cached: 1.65 s -> 0.25 s; with shaders to compile both take as long as compiling takes.)
const WARM_HEADINGS := 6
const WARM_STEADY_FRAMES := 8
const WARM_FRAME_SECONDS := 1.0 / 24.0
const WARM_MAX_SECONDS := 8.0

## The building units (data/buildings.json) the tutorial uses; the only ones built before it.
const TUTORIAL_UNITS := ["home", "supermarket"]
## Staged loading: at least this long between two buildings, and at most this long waiting for a
## quiet moment before adding the next one anyway.
const UNIT_GAP_MS := 1500
const UNIT_WAIT_MAX_MS := 20000

## Set by switch_profile(): the reloaded scene skips the splash.
static var _skip_splash := false

var screens: Control
var loading: CanvasLayer
var main: Node
## Web: keeps the resume note (web_resume.gd); the note this launch resumes from, or {}.
var web_resume: Node
var _resume := {}

func _init() -> void:
	# Chinese fallback font before any text is shaped (web builds have no system fonts).
	preload("res://scripts/ui/cjk_font.gd").install()

func _ready() -> void:
	# Before anything reads user://: carry saves over from an earlier project name.
	preload("res://scripts/core/save_migration.gd").run()
	var layer := CanvasLayer.new()
	layer.name = "Screens"
	add_child(layer)
	screens = AppScreens.new()
	layer.add_child(screens)
	screens.profile_chosen.connect(start_town)
	# Not one-shot: "Back" from the character grid returns to the title.
	screens.splash_done.connect(_after_splash)
	WebResume.set_page_texts()
	_resume = WebResume.take()
	if OS.has_feature("web"):
		# A newer published build (web_resume.gd, "New builds").
		JavaScriptBridge.pwa_update_available.connect(_on_update_available)
		if JavaScriptBridge.pwa_needs_update():
			_on_update_available.call_deferred()
	if not _resume.is_empty():
		start_town(str(_resume.profile))
	elif _skip_splash:
		_skip_splash = false
		_after_splash()
	else:
		screens.show_splash()

func _after_splash() -> void:
	# No profile is active on these screens (one can then be deleted); the default
	# languages show until a profile is picked.
	ProfileManager.shared().select("")
	GameSettings.shared().apply()
	screens.show_profiles()

## Loads the town for this profile behind the loading screen.
func start_town(id: String) -> void:
	ProfileManager.shared().select(id)
	_keep_saves()
	GameSettings.shared().apply()
	screens.get_parent().queue_free()
	screens = null
	loading = LoadingScreen.new()
	add_child(loading)
	# Let the first shot draw before the scene file loads (a stall without threads).
	await get_tree().process_frame
	await get_tree().process_frame
	main = (load(MAIN_SCENE) as PackedScene).instantiate()
	main.staged_loading = true
	if not bool(ProfileManager.shared().active_profile().get("tutorial", {}).get("done", false)):
		main.initial_units = _first_units()
	main.loading_progress.connect(loading.set_progress)
	main.town_ready.connect(_on_town_ready, CONNECT_ONE_SHOT)
	if OS.has_feature("web") and web_resume == null:
		web_resume = WebResume.new()
		web_resume.name = "WebResume"
		add_child(web_resume)
	# Nothing 3D is drawn while the town builds: the loading screen covers it.
	get_viewport().disable_3d = true
	add_child(main)

func _on_town_ready() -> void:
	get_viewport().disable_3d = false
	var resuming := not _resume.is_empty() and bool(ProfileManager.shared().active_profile().get("tutorial", {}).get("done", false))
	if resuming:
		web_resume.place(main, _resume)
	_resume = {}
	await _warm_up()
	loading.finish()
	loading = null
	if web_resume != null:
		web_resume.watch(main)
		if resuming:
			web_resume.tell_back(main)
	_load_rest(Tutorial.begin(main))

## Web: a new build is waiting. In the town, ask the player (web_resume.gd); before that
## (title, characters, loading) switch to it now: nothing is lost yet.
func _on_update_available() -> void:
	if web_resume != null:
		web_resume.offer_update()
	else:
		JavaScriptBridge.pwa_update()

## TUTORIAL_UNITS that the dev focus (dev_focus.txt) loads at all; never empty, so a focus
## without them still starts with its own buildings.
func _first_units() -> Array:
	var focused: Array = preload("res://scripts/world/modular_town.gd").focused_units()
	var first: Array = TUTORIAL_UNITS.filter(func(key) -> bool: return focused.has(key))
	return first if not first.is_empty() else focused

## Adds Main's pending building units one at a time while the tutorial plays (see the header).
func _load_rest(director: Node) -> void:
	var town: Node = main
	var last := Time.get_ticks_msec()
	while is_instance_valid(town) and not town.pending_units.is_empty():
		await get_tree().process_frame
		if not is_instance_valid(town):
			return
		var now := Time.get_ticks_msec()
		if not is_instance_valid(director) or not director.running:
			await _load_rest_now(town)
			return
		if now - last >= UNIT_GAP_MS and (_quiet_moment(director) or now - last >= UNIT_WAIT_MAX_MS):
			await town.add_unit(town.pending_units[0])
			last = Time.get_ticks_msec()

## A moment when a freeze is not felt: a fade, the title cutscene or a line being read.
func _quiet_moment(director: Node) -> bool:
	return bool(director.zone.fading) or is_instance_valid(director.get("_cutscene")) \
		or main.shop_panel.is_dialogue_visible()

## The rest at once, behind the loading screen (the tutorial ended or was skipped).
func _load_rest_now(town: Node) -> void:
	var screen := LoadingScreen.new()
	add_child(screen)
	screen.set_text(Lexicon.shared().phrase("app.getting_ready", Lexicon.shared().native))
	var total := float(town.pending_units.size())
	while is_instance_valid(town) and not town.pending_units.is_empty():
		screen.set_progress(1.0 - town.pending_units.size() / total)
		await get_tree().process_frame
		await town.add_unit(town.pending_units[0])
	screen.finish()

## Draws the town behind the loading screen until it runs smoothly: the camera looks in
## WARM_HEADINGS directions around the player, one drawn frame each (the first draw of each
## material compiles its shader, a stall on the web; a frame compiles everything in view however
## long it takes), then WARM_STEADY_FRAMES frames in a row under WARM_FRAME_SECONDS (or
## WARM_MAX_SECONDS in all).
func _warm_up() -> void:
	loading.set_text(Lexicon.shared().phrase("app.getting_ready", Lexicon.shared().native))
	var player: Node = main.player
	var start_yaw: float = player.camera_yaw
	var started := Time.get_ticks_msec()
	for i in WARM_HEADINGS:
		player.camera_yaw = start_yaw + TAU * float(i) / WARM_HEADINGS
		player.reset_camera()
		# Two frames: the second is drawn with this heading for sure (a signal from the renderer
		# could wait forever while a browser tab or window is hidden and draws nothing).
		await get_tree().process_frame
		await get_tree().process_frame
	player.camera_yaw = start_yaw
	player.reset_camera()
	var steady := 0
	while steady < WARM_STEADY_FRAMES and Time.get_ticks_msec() - started < WARM_MAX_SECONDS * 1000.0:
		await get_tree().process_frame
		steady = steady + 1 if get_process_delta_time() < WARM_FRAME_SECONDS else 0

## Settings' "Replay the welcome tour": the tutorial from the start, in the running town.
func replay_tutorial() -> void:
	if main != null and loading == null:
		Tutorial.begin(main, true)

## In a browser, saves live in the site's IndexedDB, which the browser may clear when space
## runs low; ask it to keep them (granted or not by the browser, often after installing the
## app; nothing to wait for). Godot copies each written save there on the next frame.
func _keep_saves() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("navigator.storage && navigator.storage.persist && navigator.storage.persist()", true)

## Settings' "Switch profile": back to "Who's playing?" (the town is rebuilt for the next one).
func switch_profile() -> void:
	_skip_splash = true
	get_tree().reload_current_scene()

