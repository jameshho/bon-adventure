extends SceneTree
## 4 Nov 2026, UI Stage 1: Settings (Display Mode, languages), the popup stack behind Esc,
## the standard dialogue box (translate bubble, centred choices with icons) and the money
## panel's icon buttons, inside the real town (Main). Main saves progress and settings, so
## run with an isolated HOME (README); the check removes its user://settings.json at the end.
## A VT_FOCUS run that skips interiors must be reported as focused:
## HOME=<scratch>/home VT_FOCUS=supermarket,hospital godot --headless --path . --script res://docs/evidence/ui-settings-20261104/verify_town.gd
const GameSettings := preload("res://scripts/core/game_settings.gd")
const TranslateButton := preload("res://scripts/ui/translate_button.gd")
var failures := 0
var checks := 0

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

func finish() -> void:
	var settings = GameSettings.shared()
	settings.set_languages("en", "es")
	settings.set_display(GameSettings.FOREIGN)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))
	print("ui settings town: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func esc(game) -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	game._unhandled_input(key)

func key(game, code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	game._unhandled_input(event)

func run() -> void:
	root.size = Vector2i(1600, 1000)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	await physics_frame
	await physics_frame
	var settings = GameSettings.shared()
	var lex = preload("res://scripts/language/lexicon.gd").shared()
	var hud = game.hud
	var box = game.shop_panel
	# Defaults (user decision): native English, foreign Spanish, Foreign only.
	check(settings.display == GameSettings.FOREIGN and settings.native == "en" and settings.foreign == "es", "defaults: Foreign only, en / es (%d %s %s)" % [settings.display, settings.native, settings.foreign])
	check(hud.mode == GameSettings.FOREIGN, "HUD mode follows the settings: %d" % hud.mode)
	check(hud.mode_button.text == lex.phrase("settings.mode_button", "en", {"mode": "Spanish only"}), "mode button: " + hud.mode_button.text)
	check(hud.settings_button != null and hud.settings_button.icon != null and hud.settings_button.visible, "gear button on the HUD")
	check(hud.bookmark_button.position.is_equal_approx(hud.top_slot(0).position), "the saved-words book sits under the gear (14 Nov 2026; bottom-right cluster since 10 Nov 2026)")
	# Esc with nothing open opens Settings; Esc again closes it and gives controls back.
	check(game.popups.is_empty(), "nothing open at the start")
	esc(game)
	check(game.settings_panel.visible and game.popups.top() == game.settings_panel, "Esc with nothing open opens Settings")
	check(not game.player.controls_enabled, "player controls are off in Settings")
	check(game.settings_panel._title.text == "Settings" and game.settings_panel._native_pick.item_count == lex.playable_codes().size(), "Settings lists every complete language: %d" % game.settings_panel._native_pick.item_count)
	check(game.settings_panel._mode_buttons[GameSettings.FOREIGN].button_pressed, "Settings shows Foreign only selected")
	var card_size: Vector2 = game.settings_panel._card.size
	check(card_size.x > 300 and card_size.y < 1000 and card_size.y > 200, "Settings card fits the window: %s" % card_size)
	esc(game)
	check(not game.settings_panel.visible and game.player.controls_enabled, "Esc in Settings closes it; controls return")
	hud.settings_requested.emit()
	check(game.settings_panel.visible, "the gear opens Settings")
	game.settings_panel._x_button.pressed.emit()
	check(not game.settings_panel.visible, "the ✕ closes Settings")
	# Topmost first: help, then map; Esc closes the map, then help, then opens Settings.
	hud.toggle_help()
	hud.toggle_map()
	check(game.popups.top() == hud.map_overlay, "the map is on top of help")
	esc(game)
	check(not hud.is_map_open() and hud.is_help_open(), "Esc closes the map first")
	esc(game)
	check(not hud.is_help_open() and not game.settings_panel.visible, "then help, without opening Settings")
	esc(game)
	check(game.settings_panel.visible, "then Settings")
	esc(game)
	# The cashier: the dialogue box, the money panel and its quit question.
	var cashier_session = game.get_node_or_null("CashierSession_supermarket")
	if cashier_session != null and cashier_session.cashier != null:
		cashier_session.set_process(false)
		var money = game.money_panel
		game.interaction.clerk_activated.emit(cashier_session.cashier)
		check(box.is_dialogue_visible() and game.popups.top() == box.dialogue_card, "the cashier's dialogue is the top popup")
		var bubble: Button = box.translate_button
		check(bubble is TranslateButton and bubble.visible and bubble.badge == "EN", "translate bubble shows EN in Foreign only")
		check(bubble.get_parent() == box.speaker_label.get_parent(), "translate bubble sits in the top row beside the speaker")
		check(box.choice_row.alignment == BoxContainer.ALIGNMENT_CENTER and box.choice_row.get_child_count() == 2, "two centred choices")
		check(box.choice_row.get_children().all(func(b): return b.icon != null), "every choice has an icon")
		check(not box.native_label.visible, "translation hidden by default")
		bubble.pressed.emit()
		check(box.native_label.visible and box.native_label.text == box._line.native and bubble.on, "the bubble reveals the native line")
		bubble.pressed.emit()
		await process_frame
		await process_frame
		var rect: Rect2 = box.dialogue_card.get_rect()
		check(rect.size.y < 1000 * 0.45 and rect.end.y <= 1000.5, "dialogue box stays at the bottom: %s" % rect)
		box.choice_pressed.emit("cashier_count")
		check(money.visible and game.popups.top() == money, "the money panel is the top popup")
		check(money._tray_empty.visible and money._tray_empty is TextureRect, "empty tray shows the hand icon, no hint text")
		check(money._clear_button.icon != null and money._submit_button.icon != null and money._close_button.icon != null, "Clear, Hand over and Close have icons")
		check(money._clear_button.disabled and money._submit_button.disabled, "Clear and Hand over start disabled")
		check(money._submit_button.custom_minimum_size.x > money._clear_button.custom_minimum_size.x, "Hand over is the widest button")
		check(money._clear_button.custom_minimum_size == money._close_button.custom_minimum_size, "Clear and Close have equal sizes")
		check(money._total_label.text.begins_with(lex.phrase("money.total", "es")), "Total in Spanish: " + money._total_label.text)
		money.toggle_translation()
		# "Total" is the same word in both languages, so the tray title shows the pairing.
		check(money._tray_title.text == lex.phrase("money.tray", "es") + " / " + lex.phrase("money.tray", "en"), "labels follow the translation: " + money._tray_title.text)
		money.toggle_translation()
		esc(game)
		check(not money.visible and box.is_dialogue_visible() and box.foreign_label.text == lex.phrase("cashier.quit_confirm", "es"), "Esc on the money panel asks to quit: " + box.foreign_label.text)
		esc(game)
		check(money.visible, "Esc on the quit question means stay: back to the money panel")
		money.close_requested.emit()
		box.choice_pressed.emit("cashier_leave")
		await process_frame
		if box.is_dialogue_visible():
			esc(game)
		check(not money.visible and not cashier_session.busy(), "leaving ends the round")
		check(game.player.controls_enabled, "controls return after the cashier")
	else:
		print("NOTE: no supermarket cashier in this run (VT_FOCUS); cashier checks skipped")
	# Display Mode: L cycles Foreign only -> Both -> Native only -> Foreign only.
	key(game, KEY_L)
	check(settings.display == GameSettings.BOTH and hud.mode == GameSettings.BOTH, "L: Both")
	check(FileAccess.file_exists(GameSettings.PATH) and JSON.parse_string(FileAccess.get_file_as_string(GameSettings.PATH)).display == GameSettings.BOTH, "the mode is saved")
	box.show_dialogue("Test", {"foreign": "Hola", "native": "Hello"}, [{"id": "t_yes", "label": {"foreign": "Sí", "native": "Yes"}, "icon": "check"}])
	check(box.foreign_label.text == "Hola" and box.native_label.visible and box.native_label.text == "Hello" and not box.translate_button.visible, "Both: two lines, no translate bubble")
	check(box.choice_row.get_child(0).text == "Sí\nYes", "Both: two-line choice: " + box.choice_row.get_child(0).text.c_escape())
	key(game, KEY_L)
	check(settings.display == GameSettings.NATIVE, "L: Native only")
	check(box.foreign_label.text == "Hello" and not box.native_label.visible and box.choice_row.get_child(0).text == "Yes", "Native only: the native text alone")
	var english_signs: Array = game.get_tree().get_nodes_in_group("translated_signs").filter(func(l): return l.text == l.get_meta("sign_english"))
	var signs: Array = game.get_tree().get_nodes_in_group("translated_signs")
	check(signs.is_empty() or english_signs.size() == signs.size(), "Native only: world signs in English (%d of %d)" % [english_signs.size(), signs.size()])
	key(game, KEY_L)
	check(settings.display == GameSettings.FOREIGN and box.foreign_label.text == "Hola" and not box.native_label.visible and box.translate_button.visible, "L: back to Foreign only")
	signs = game.get_tree().get_nodes_in_group("translated_signs")
	check(signs.is_empty() or signs.all(func(l): return l.text == l.get_meta("sign_spanish")), "Foreign only: world signs in Spanish")
	# Settings buttons set the same value as L. (No session owns the test dialogue, so
	# nobody answers its ✕: it is hidden directly.)
	box.hide_dialogue()
	esc(game)
	check(game.settings_panel.visible, "Esc with nothing open opens Settings again")
	game.settings_panel._mode_buttons[GameSettings.BOTH].pressed.emit()
	check(settings.display == GameSettings.BOTH and hud.mode == GameSettings.BOTH, "the Settings button sets Both")
	# Languages: the same language for both is allowed (user decision).
	game.settings_panel._foreign_pick.select(lex.playable_codes().find("en"))
	game.settings_panel._foreign_pick.item_selected.emit(lex.playable_codes().find("en"))
	check(settings.foreign == "en" and lex.foreign == "en" and settings.native == "en", "native and foreign may both be English")
	game.settings_panel._native_pick.select(lex.playable_codes().find("es"))
	game.settings_panel._native_pick.item_selected.emit(lex.playable_codes().find("es"))
	check(settings.native == "es" and lex.native == "es" and game.settings_panel._title.text == "Ajustes", "a Spanish native language relabels Settings: " + game.settings_panel._title.text)
	check(hud.mode_button.text == lex.phrase("settings.mode_button", "es", {"mode": "Ambos"}), "the HUD button follows the native language: " + hud.mode_button.text)
	check(box.translate_button.badge == "ES", "the bubble shows the native badge ES")
	settings.set_languages("en", "es")
	settings.set_display(GameSettings.FOREIGN)
	esc(game)
	check(game.popups.is_empty() and game.player.controls_enabled, "everything closed; controls back")
	finish()
