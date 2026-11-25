extends SceneTree
## UI scale renders (25 Nov 2026; improvement plan UI-01, UI-06, D5, P3-15;
## docs/guides/UI_STYLE.md#window-scale). Renders the start screens (title, players, character,
## languages), the loading screen, the HUD (plain, with a word card, with its status texts),
## Settings, the results card, the minigame picker, the map, the Passport and the stars card,
## and writes the pixel size of every visible button, slider and text box on each to
## `sizes.md`. Everything goes to docs/evidence/ui-scale-20261125/<UI_SHOTS>/ (default "shots").
## UI_FLAT=1 renders the UI over an empty world (no 3D), so two runs can be compared pixel for
## pixel (compare.py). Needs graphics and an isolated HOME (it creates a profile; Main saves):
##   HOME=<scratch>/home VT_FOCUS=home VT_SPAWN=none UI_SHOTS=after-1280 UI_FLAT=1 \
##     godot --path . --resolution 1280x800 --script res://docs/evidence/ui-scale-20261125/capture.gd
## The phone size is --resolution 844x390. Add --fixed-fps 60 for runs to compare (animations
## then advance the same in both).
const AppScreens := preload("res://scripts/ui/app_screens.gd")
const LoadingScreen := preload("res://scripts/ui/loading_screen.gd")
const ProfileManager := preload("res://scripts/core/profile_manager.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const CjkFont := preload("res://scripts/ui/cjk_font.gd")
const BASE := "res://docs/evidence/ui-scale-20261125/"

var out := ""
var sizes: PackedStringArray = []

func _initialize() -> void:
	run.call_deferred()

func shot(name: String, measure: Node = null) -> void:
	# 40 frames: tweens such as the results card's pop (0.35 s) finish at --fixed-fps 60.
	for i in 40:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(out + name + ".png"))
	print("captured ", name)
	if measure != null:
		_measure(name, measure)

## Buttons, sliders and text boxes on screen, in window pixels (after any Control scale).
func _measure(name: String, from: Node) -> void:
	var found: Array = []
	_collect(from, found)
	var smallest := Vector2(INF, INF)
	var lines: PackedStringArray = []
	for c: Control in found:
		var rect := c.get_global_rect()
		var label := c.name as String
		if c is Button and (c as Button).text != "":
			label = "\"%s\"" % (c as Button).text.replace("\n", " ").left(28)
		elif c is Button and (c as Button).tooltip_text != "":
			label = "%s (%s)" % [c.name, (c as Button).tooltip_text.left(24)]
		lines.append("| %s | %s | %d × %d |" % [label, c.get_class(), roundi(rect.size.x), roundi(rect.size.y)])
		smallest = Vector2(minf(smallest.x, rect.size.x), minf(smallest.y, rect.size.y))
	sizes.append("\n### %s (%d controls; smallest width %d, smallest height %d px)\n" % [name, found.size(), roundi(smallest.x) if found.size() else 0, roundi(smallest.y) if found.size() else 0])
	sizes.append("| Control | Type | Size (px) |\n| --- | --- | --- |")
	sizes.append_array(lines)

func _collect(node: Node, found: Array) -> void:
	if node is CanvasItem and not (node as CanvasItem).is_visible_in_tree():
		return
	if node is Control and (node is BaseButton or node is Range and not node is ProgressBar or node is LineEdit):
		var rect := (node as Control).get_global_rect()
		if rect.size.x >= 1.0 and rect.size.y >= 1.0 and Rect2(Vector2.ZERO, Vector2(root.size)).intersects(rect):
			found.append(node)
	for child in node.get_children():
		_collect(child, found)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		print("capture: needs graphics")
		quit(1)
		return
	if FileAccess.file_exists("user://profiles/index.json"):
		print("capture: refusing to run, profiles exist (use an isolated HOME)")
		quit(1)
		return
	out = BASE + OS.get_environment("UI_SHOTS").strip_edges().trim_suffix("/") + "/"
	if out == BASE + "/":
		out = BASE + "shots/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var flat := OS.get_environment("UI_FLAT") == "1"
	root.disable_3d = flat
	sizes.append("# UI sizes at %d × %d%s\n" % [root.size.x, root.size.y, " (no 3D)" if flat else ""])
	sizes.append("Window pixels of each visible button, slider and text box (capture.gd).")
	CjkFont.install()

	# --- Start screens ------------------------------------------------------------------------
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var screens = AppScreens.new()
	layer.add_child(screens)
	screens.show_splash()
	await shot("start-title", screens)
	screens.show_new_profile()
	await shot("start-character", screens)
	screens._show("languages")
	await shot("start-languages", screens)
	var manager = ProfileManager.shared()
	var id: String = manager.create("Leo", "Leo", "leo")
	manager.select(id)
	GameSettings.shared().set_languages("en", "es")
	screens.show_profiles()
	await shot("start-players", screens)
	layer.queue_free()
	var loading = LoadingScreen.new()
	root.add_child(loading)
	loading.set_text("Getting everything ready…")
	loading.set_progress(0.5)
	await shot("loading", loading)
	loading.queue_free()

	# --- The town's HUD and panels --------------------------------------------------------------
	var game = load("res://scenes/main.tscn").instantiate()
	if game == null or game.get_script() == null:
		print("capture: Main did not load (a script error?)")
		quit(1)
		return
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	for i in 30:
		await process_frame
	var hud = game.hud
	await shot("hud", hud)
	hud.show_card("apple", "la manzana", "Food & Drink", "apple")
	await shot("hud-card", hud)
	hud.hide_card()
	# UI-06: the status texts (FPS, sprint line, noclip, quest toast, flight line).
	hud.toggle_fps()
	hud.fps_label.text = "60 FPS"
	hud.set_process(false)
	hud.set_movement_mode(true, false)
	hud.set_noclip(true)
	hud.flash_quest_message("Quest updated! Find the bakery")
	hud.set_flight_status("Flying: hold Space to climb")
	await shot("hud-status", hud)
	hud.set_process(true)
	hud.toggle_fps()
	hud.set_movement_mode(false, false)
	hud.set_noclip(false)
	hud.quest_toast.visible = false
	hud.set_flight_status("")
	game.open_settings()
	await shot("settings", game.settings_panel)
	game.settings_panel.close()
	await process_frame
	game.results_screen.show_results({
		"title": "Well done!",
		"line": "You helped Rosa find her books.",
		"words": {"new": ["apple", "bread", "milk"], "practiced": ["cat", "dog"], "struggled": ["bread"], "all": ["apple", "bread", "milk", "cat", "dog"], "highlights": ["apple", "bread", "milk", "cat", "dog"]},
		"rewards": [{"kind": "quest", "text": "Quest updated!"}, {"kind": "xp", "amount": 30}],
		"replay": true,
	})
	await shot("results", game.results_screen)
	game.results_screen.visible = false
	if game.game_launcher != null:
		game.game_launcher.open()
		await shot("picker", game.game_launcher)
		game.game_launcher.close()
	if game.town_map != null:
		hud.toggle_map()
		await shot("map", hud.map_overlay)
		hud.toggle_map()
		print("map closed")
	if game.passport != null:
		game.passport.open()
		print("passport open")
		await shot("passport", game.passport)
		game.passport.close()
	if game.star_card != null:
		game.star_card.show_result("shop_supermarket", {"stars": 2, "level": 2, "count": 3})
		await shot("stars", game.star_card)

	var file := FileAccess.open(ProjectSettings.globalize_path(out + "sizes.md"), FileAccess.WRITE)
	file.store_string("\n".join(sizes) + "\n")
	file.close()
	print("UI SCALE CAPTURE: done (%s)" % out)
	quit(0)
