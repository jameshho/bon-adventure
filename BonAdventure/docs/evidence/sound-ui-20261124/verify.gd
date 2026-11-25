extends SceneTree
## Sound and HUD icons check (24 Nov 2026; guides docs/guides/VOICE.md, docs/guides/UI_STYLE.md).
## Loads the town (any VT_FOCUS works; the HUD is the same) and checks:
## - the journal button and the journal's title use BonStyle's "journal" icon (no drawn J),
## - key hint circles: on HUD buttons with the key from the input map (J, Esc, L, F9), shown with
##   a keyboard, hidden after a touch, shown again after a key press,
## - the word card's speaker: hidden while spoken words are off; shown for a word with a clip
##   once they are on (switched on in memory only; nothing is pressed or played),
## - Settings: four volume sliders that set the Master, Music, SFX / Ambience / UI and Voice buses,
## - the sound service plays nothing.
## Writes user:// saves: run with an isolated HOME. Plays no sound.
##   HOME=<scratch>/home VT_FOCUS=home godot --headless --path . --script res://docs/evidence/sound-ui-20261124/verify.gd
## With graphics it also saves hud-card.png, hud-touch.png, journal.png and settings.png here:
##   HOME=<scratch>/home VT_FOCUS=home godot --path . --resolution 1600x1000 --script res://docs/evidence/sound-ui-20261124/verify.gd
const GameSettings := preload("res://scripts/core/game_settings.gd")
const Sound := preload("res://scripts/core/sound.gd")
const DIR := "res://docs/evidence/sound-ui-20261124/"
var failures := 0
var checks := 0
var game

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

func graphics() -> bool:
	return DisplayServer.get_name() != "headless"

func shot(path: String) -> void:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func hints_shown(hud) -> int:
	var shown := 0
	for hint in hud.key_hints:
		if is_instance_valid(hint) and hint.visible:
			shown += 1
	return shown

func run():
	GameSettings.shared().set_languages("en", "es")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	game.set_process_input(false)
	game.set_process_unhandled_input(false)
	for i in 4: await process_frame
	var hud = game.hud
	var sound = Sound.shared()
	check(sound != null, "Main made the sound service")

	# --- Icons ------------------------------------------------------------------------------
	check(hud.bookmark_button.icon != null and not hud.bookmark_button.draw.is_connected(Callable(hud, "_draw_bookmark_book")) if hud.has_method("_draw_bookmark_book") else hud.bookmark_button.icon != null, "the journal button shows the journal icon")
	check(hud.bookmark_button.get_theme_color("icon_normal_color") == Color.WHITE, "the journal icon keeps its own colours")
	check(hud.journal_icon.texture != null and hud.journal_icon.modulate == Color.WHITE, "the journal title shows the journal icon untinted")

	# --- Key hint circles ---------------------------------------------------------------------
	check(hud.key_label("journal") == "J", "journal key J (%s)" % hud.key_label("journal"))
	check(hud.key_label("back") == "Esc", "back key Esc (%s)" % hud.key_label("back"))
	check(hud.key_label("peek") == "L", "peek key L")
	check(hud.key_label("games") == "F9", "games key F9 (%s)" % hud.key_label("games"))
	var keys: Array = []
	for hint in hud.key_hints:
		keys.append(str(hint.get_meta("key")) + "@" + str(hint.get_parent().name))
	print("KEY HINTS: " + ", ".join(keys))
	check(hud.key_hints.size() >= 5, "journal, map, gear, peek and picker have key hints (%d)" % hud.key_hints.size())
	if not DisplayServer.is_touchscreen_available():
		check(hud.keyboard_hints and hints_shown(hud) == hud.key_hints.size(), "shown at start without a touch screen")
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	hud._input(touch)
	check(not hud.keyboard_hints and hints_shown(hud) == 0, "hidden after a touch")
	if graphics():
		await shot(DIR + "hud-touch.png")
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_W
	hud._input(key)
	check(hud.keyboard_hints and hints_shown(hud) == hud.key_hints.size(), "shown again after a key press")

	# --- The word card's speaker ---------------------------------------------------------------
	var was_on: bool = sound.voice_enabled()  # on since 24 Nov 2026 (user); the check turns it off first
	sound.voice["enabled"] = false
	hud.show_card("apple", "la manzana", "Food & Drink", "apple")
	await process_frame
	check(not hud.speaker_button.visible, "no speaker while spoken words are off")
	sound.voice["enabled"] = true
	hud.update_card()
	await process_frame
	check(hud.speaker_button.visible, "the speaker shows for apple once spoken words are on")
	check(hud.speaker_button.position.x < hud.bookmark_star.position.x and absf(hud.speaker_button.position.y - hud.bookmark_star.position.y) < 1.0, "the speaker sits top left, level with the star")
	if graphics():
		await shot(DIR + "hud-card.png")
	hud.show_name_card("Mei", "cat")
	await process_frame
	check(not hud.speaker_button.visible, "no speaker on a character's name card")
	hud.hide_card()
	check(not hud.speaker_button.visible, "the speaker hides with the card")
	sound.voice["enabled"] = was_on
	check(not sound.is_playing() and sound.get_child_count() == 0, "nothing played")

	# --- Journal ------------------------------------------------------------------------------
	if graphics():
		game.toggle_study_journal()
		for i in 20: await process_frame
		await shot(DIR + "journal.png")
		game.toggle_study_journal()

	# --- Settings: volume sliders ---------------------------------------------------------------
	game.open_settings()
	await process_frame
	var panel = game.settings_panel
	check(panel._volume_rows.size() == 4, "Settings has four volume sliders")
	for group in GameSettings.VOLUME_ORDER:
		var row: Array = panel._volume_rows.get(group, [])
		check(row.size() == 2 and row[0].text != "" and is_equal_approx(row[1].value, GameSettings.shared().volumes[group]), "%s slider titled and at the saved level" % group)
	check(AudioServer.get_bus_index("Music") >= 0, "the Music bus exists")
	GameSettings.shared().set_volume("effects", 0.5, false)
	var half := linear_to_db(0.5)
	for bus_name in ["SFX", "Ambience", "UI"]:
		check(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus_name)) - half) < 0.01, "Sound effects sets %s" % bus_name)
	GameSettings.shared().set_volume("voice", 0.0, false)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Voice")), "0 mutes the Voice bus")
	GameSettings.shared().set_volume("effects", 1.0, false)
	GameSettings.shared().set_volume("voice", 1.0, false)
	check(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Voice")) and absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))) < 0.01, "back to full")
	if graphics():
		panel._volume_rows["music"][1].value = 0.6
		await shot(DIR + "settings.png")
		panel._volume_rows["music"][1].set_value_no_signal(1.0)
	panel.close()

	print("SOUND UI CHECK: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
