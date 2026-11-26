extends SceneTree
## F1 controls guide renders (25 Nov 2026; improvement plan UI-04; docs/game/playing.md#controls).
## Renders Settings with its Controls button, then the guide in the keyboard and the touch view
## (every page) in English, page 1 of each view in Spanish and Chinese, and the guide opened from
## Settings on a touch device. For every page it checks that no card runs past the page area or
## the card edge (the pages are packed from font measurements, vocabulary_hud.gd
## _paginate_help()) and prints "F1 GUIDE FIT: ok" or the overflowing cards; it writes the pixel
## size of the guide's buttons to <out>/sizes.md. Needs graphics and an isolated HOME:
##   HOME=<scratch>/home VT_FOCUS=home VT_SPAWN=none F1_SHOTS=laptop-1280x800 \
##     godot --path . --resolution 1280x800 --script res://docs/evidence/f1-guide-20261125/capture.gd
## The phone size is --resolution 844x390 (F1_SHOTS=phone-844x390).
const ProfileManager := preload("res://scripts/core/profile_manager.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const CjkFont := preload("res://scripts/ui/cjk_font.gd")
const BASE := "res://docs/evidence/f1-guide-20261125/"

var out := ""
var sizes: PackedStringArray = []
var overflow: PackedStringArray = []

func _initialize() -> void:
	run.call_deferred()

func shot(name: String) -> void:
	for i in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(out + name + ".png"))
	print("captured ", name)

## Cards past the page area (or a row past its card) on the page now shown.
func check_fit(name: String, hud: Node) -> void:
	var area: Rect2 = hud.help_body.get_global_rect()
	if hud.help_overlay.get_global_rect().end.y > root.size.y or hud.help_overlay.get_global_rect().end.x > root.size.x:
		overflow.append("%s: the card runs off the window (%s)" % [name, hud.help_overlay.get_global_rect()])
	for stack in hud.help_columns.get_children():
		for card in stack.get_children():
			var rect: Rect2 = card.get_global_rect()
			if rect.end.y > area.end.y + 1.0 or rect.end.x > area.end.x + 1.0:
				overflow.append("%s: card %s ends at %s, page area ends at %s" % [name, card.get_child(0).get_child(0).text, rect.end, area.end])
			var inner: Rect2 = card.get_child(0).get_global_rect()
			if inner.end.y > rect.end.y + 1.0:
				overflow.append("%s: rows of %s run past the card" % [name, card.get_child(0).get_child(0).text])

func measure(name: String, hud: Node) -> void:
	sizes.append("\n### %s\n\n| Control | Size (px) |\n| --- | --- |" % name)
	for button in [hud.help_close] + hud.help_tabs + [hud.help_prev, hud.help_next]:
		if button.is_visible_in_tree():
			var rect: Rect2 = button.get_global_rect()
			sizes.append("| %s | %d × %d |" % [button.name, roundi(rect.size.x), roundi(rect.size.y)])

func pages(prefix: String, hud: Node, all := true) -> void:
	var count: int = hud.help_pages.size()
	for page in (count if all else 1):
		hud.help_page = page
		hud._show_help_page()
		var name := "%s-page%d" % [prefix, page + 1]
		await shot(name)
		check_fit(name, hud)
	print("%s: %d pages" % [prefix, count])
	sizes.append("\n%s: %d page(s)" % [prefix, count])

func run() -> void:
	if DisplayServer.get_name() == "headless":
		print("capture: needs graphics")
		quit(1)
		return
	if FileAccess.file_exists("user://profiles/index.json"):
		print("capture: refusing to run, profiles exist (use an isolated HOME)")
		quit(1)
		return
	out = BASE + OS.get_environment("F1_SHOTS").strip_edges().trim_suffix("/") + "/"
	if out == BASE + "/":
		out = BASE + "shots/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	sizes.append("# F1 guide button sizes at %d × %d (capture.gd)" % [root.size.x, root.size.y])
	CjkFont.install()
	var manager = ProfileManager.shared()
	manager.select(manager.create("Leo", "Leo", "leo"))
	GameSettings.shared().set_languages("en", "es")
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

	game.open_settings()
	await shot("settings")
	var controls: Button = game.settings_panel._controls_button
	var rect := controls.get_global_rect()
	sizes.append("\nSettings \"%s\" button: %d × %d" % [controls.text, roundi(rect.size.x), roundi(rect.size.y)])
	game.settings_panel.close()

	# Keyboard view (F1 on a laptop: no touch yet).
	hud.set_touch_mode(false)
	hud.set_keyboard_hints(true)
	hud.toggle_help()
	measure("keyboard view", hud)
	await pages("keys-en", hud)
	hud.set_help_view(true)
	measure("touch view", hud)
	await pages("touch-en", hud)
	hud.toggle_help()

	# Spanish and Chinese menus: page 1 of each view.
	for lang in ["es", "zh"]:
		GameSettings.shared().set_languages(lang, "en" if lang == "es" else "es")
		await process_frame
		hud.toggle_help()
		hud.set_help_view(false)
		await pages("keys-" + lang, hud, false)
		hud.set_help_view(true)
		await pages("touch-" + lang, hud, false)
		hud.toggle_help()
	GameSettings.shared().set_languages("en", "es")
	await process_frame

	# A touch device: Settings -> Controls opens the guide in the touch view.
	hud.set_touch_mode(true)
	game.open_settings()
	await process_frame
	game.settings_panel._controls_button.pressed.emit()
	await shot("settings-to-guide")
	print("from Settings: guide open %s, touch view %s, settings closed %s" % [hud.is_help_open(), hud.help_touch, not game.settings_panel.visible])
	if not (hud.is_help_open() and hud.help_touch and not game.settings_panel.visible):
		overflow.append("Settings -> Controls did not open the touch guide")

	var file := FileAccess.open(ProjectSettings.globalize_path(out + "sizes.md"), FileAccess.WRITE)
	file.store_string("\n".join(sizes) + "\n")
	file.close()
	for line in overflow:
		print("F1 GUIDE OVERFLOW: ", line)
	print("F1 GUIDE FIT: %s (%s)" % ["ok" if overflow.is_empty() else "%d problems" % overflow.size(), out])
	quit(0 if overflow.is_empty() else 1)
