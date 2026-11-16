extends SceneTree
## 4 Nov 2026, UI Stage 3: every interface text in data/phrases.json (shown in the native
## language), the word card following the Display Mode, progress saved per foreign language
## (the older single-array save becomes the Spanish progress and stays untouched), and a
## language change ending a running minigame. Inside the real town (Main).
## Main saves progress and settings: run with an isolated HOME (README). The check backs up
## and restores the progress files and removes its user://settings.json at the end.
## A VT_FOCUS run that skips interiors must be reported as focused:
## HOME=<scratch>/home VT_FOCUS=supermarket,hospital godot --headless --path . --script res://docs/evidence/language-ui-20261104/verify_town.gd
const GameSettings := preload("res://scripts/core/game_settings.gd")
const UiText := preload("res://scripts/language/ui_text.gd")
const Progress := preload("res://scripts/learning/vocabulary_progress.gd")
const Board := preload("res://scripts/learning/activity_board.gd")
var failures := 0
var checks := 0
var backups: Dictionary = {}

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

func backup(path: String) -> void:
	backups[path] = FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else null

func restore() -> void:
	for path in backups:
		if backups[path] == null:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		else:
			var file := FileAccess.open(path, FileAccess.WRITE)
			file.store_string(backups[path])

func write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)

func finish() -> void:
	var settings = GameSettings.shared()
	settings.set_languages("en", "es")
	settings.set_display(GameSettings.FOREIGN)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))
	restore()
	print("language ui town: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func run() -> void:
	root.size = Vector2i(1600, 1000)
	# An older single-array save: it must load as the Spanish progress and stay untouched.
	backup(Progress.PROGRESS_FILE)
	backup(Progress.LANGUAGE_FILE)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Progress.LANGUAGE_FILE))
	var legacy := JSON.stringify(["sofa", "tap"])
	write(Progress.PROGRESS_FILE, legacy)
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

	# --- Progress per foreign language -----------------------------------------------------
	check(game.progress_language == "es" and game.studied_words.has("sofa") and game.studied_words.has("faucet"), "old save loads as the Spanish progress (aliases canonical): %s" % [game.studied_words.keys()])
	var by_language: Variant = JSON.parse_string(FileAccess.get_file_as_string(Progress.LANGUAGE_FILE))
	check(by_language is Dictionary and by_language.get("es", []).has("sofa"), "the Spanish progress is copied into " + Progress.LANGUAGE_FILE)
	game._on_word_studied("apple")
	check(FileAccess.get_file_as_string(Progress.PROGRESS_FILE) == legacy, "the old save file is never written (kept as a backup)")
	settings.set_languages("es", "en")
	check(game.progress_language == "en" and not game.studied_words.has("apple") and not game.studied_words.has("sofa"), "English as the foreign language starts its own progress: %s" % [game.studied_words.keys()])
	game._on_word_studied("banana")
	settings.set_languages("en", "es")
	check(game.studied_words.has("apple") and game.studied_words.has("sofa") and not game.studied_words.has("banana"), "back to Spanish: the Spanish progress returns: %s" % [game.studied_words.keys()])
	by_language = JSON.parse_string(FileAccess.get_file_as_string(Progress.LANGUAGE_FILE))
	check(by_language.get("en", []) == ["banana"] and by_language.get("es", []).has("apple"), "both languages saved side by side: %s" % [by_language])
	check(hud.bookmark_button != null and hud.bookmarks is Dictionary, "saved words stay one shared list (bookmarks file unchanged by the language)")

	# --- The word card follows the Display Mode -------------------------------------------
	settings.set_display(GameSettings.FOREIGN)
	hud.show_card("Apple", "la manzana", "Food & Drink", "apple")
	check(hud.primary_label.text == "la manzana" and hud.secondary_label.text == "", "Foreign only: the foreign word alone (%s / %s)" % [hud.primary_label.text, hud.secondary_label.text])
	check(hud.card_translate.visible, "Foreign only: the card has the translate bubble")
	check(hud.title_label.text == "SPANISH WORD" and hud.category_label.text == "FOOD & DRINK  /  VOCABULARY", "card titles: %s | %s" % [hud.title_label.text, hud.category_label.text])
	hud.card_translate.pressed.emit()
	check(hud.secondary_label.text == "apple", "the bubble reveals the native word from words.json: " + hud.secondary_label.text)
	settings.set_display(GameSettings.BOTH)
	hud.show_card("Apple", "la manzana", "Food & Drink", "apple")
	check(hud.primary_label.text == "la manzana" and hud.secondary_label.text == "apple" and not hud.card_translate.visible, "Both: both words, no bubble")
	settings.set_display(GameSettings.NATIVE)
	hud.show_card("Apple", "la manzana", "Food & Drink", "apple")
	check(hud.primary_label.text == "apple" and hud.secondary_label.text == "" and hud.title_label.text == "ENGLISH VOCABULARY", "Native only: the native word (%s, %s)" % [hud.primary_label.text, hud.title_label.text])
	check(game.interaction.action_hint_text({"phrase": "common.talk_prompt"}) == "E: Talk", "Native only: the NPC talk hint follows the world language")
	settings.set_display(GameSettings.FOREIGN)
	check(game.interaction.action_hint_text({"phrase": "common.talk_prompt"}) == "E: Hablar", "Foreign only: E: Hablar")
	hud.hide_card()
	check(not hud.card_translate.visible, "the bubble hides with the card")

	# --- The interface in Spanish (native es, foreign en) ---------------------------------
	settings.set_languages("es", "en")
	check(lex.native == "es" and lex.foreign == "en", "languages switched to es / en")
	var controls: Label = hud.ui_root.get_node("Controls")
	check(controls.text == lex.phrase("hud.controls", "es"), "controls summary re-renders in Spanish")
	hud.set_progress("Hospital · Floor 2 · Patient Rooms, ICU & Surgery", 3)
	check(hud.room_label.text == "Hospital · Planta 2 · Habitaciones, UCI y quirófanos  |  3 palabras encontradas", "place and count in Spanish: " + hud.room_label.text)
	hud.set_target("x", true)
	check(hud.hover_text.text.contains("Clic: estudiar") and hud.hover_text.text.contains("E: abrir"), "pointer hints in Spanish: " + hud.hover_text.text)
	check(hud.mode_button.text == lex.phrase("settings.mode_button", "es", {"mode": "Solo Inglés"}), "mode button in Spanish: " + hud.mode_button.text)
	hud.show_card("Apple", "la manzana", "Food & Drink", "apple")
	check(hud.primary_label.text == "apple" and hud.title_label.text == "PALABRA EN INGLÉS" and hud.category_label.text == "COMIDA Y BEBIDA  /  VOCABULARIO", "card for a Spanish speaker learning English: %s | %s | %s" % [hud.primary_label.text, hud.title_label.text, hud.category_label.text])
	hud.card_translate.pressed.emit()
	check(hud.secondary_label.text == "la manzana", "the bubble reveals the Spanish word")
	hud.hide_card()
	hud.toggle_help()
	var help_text := []
	for label in hud.help_overlay.find_children("*", "Label", true, false):
		help_text.append(label.text)
	check(help_text.has("CONTROLES") and help_text.has("Diario de vocabulario") and help_text.has("Clic derecho") and not help_text.has("Vocabulary journal"), "F1 guide rebuilt in Spanish")
	check(help_text.has(hud.mode_name(settings.display)), "guide's language pill shows the Display Mode")
	hud.toggle_help()
	hud.toggle_journal(game.studied_words, game.vocabulary, game.vocabulary_categories, game.area_vocabulary.groups, game.area_vocabulary.area_names)
	check(hud.journal_title.text.begins_with("DIARIO DE VOCABULARIO") and hud.journal_category_button.text == "Por categoría", "journal in Spanish: " + hud.journal_title.text)
	hud.set_journal_view(true)
	check(hud.journal_hint.text == lex.phrase("journal.hint_area", "es") and hud.journal_list.text.contains("descubiertas"), "journal by area in Spanish")
	hud.toggle_journal({}, {})
	hud.set_bookmarks_open(true)
	check(hud.bookmark_title.text.begins_with("PALABRAS GUARDADAS"), "saved words in Spanish: " + hud.bookmark_title.text)
	hud.set_bookmarks_open(false)
	hud.set_movement_mode(true, false)
	check(hud.movement_label.text == lex.phrase("hud.move_sprint", "es"), "movement label in Spanish")
	for vehicle in game.driveable_vehicles:
		var status: String = vehicle.flight_status()
		check(not "{" in status and not status.contains("DRIVING") and not status.contains("HELICOPTER") and not status.contains("TURBOPROP"), "%s status in Spanish: %s" % [vehicle.name, status.left(40)])

	# --- Every name the world code uses has a phrase (UiText.missing stays empty) ---------
	UiText.missing.clear()
	var player_start: Vector3 = game.player.global_position
	for y in [0.5, 6.0, 11.6, 17.5]:
		for x in range(-200, 201, 5):
			for z in range(-50, 301, 5):
				game.player.global_position = game.apartment.to_global(Vector3(x, y, z))
				UiText.place(game.current_room())
	game.player.global_position = player_start
	for id in game.zones.by_id:
		UiText.named("places", str(game.zones.by_id[id].name))
	for area in game.area_vocabulary.area_names:
		UiText.named("places", str(game.area_vocabulary.area_names[area]))
	for key in game.vocabulary_categories:
		UiText.named("categories", str(game.vocabulary_categories[key]))
	for npc in character_species(game):
		UiText.named("species", npc)
	for seat in game.seating.seats:
		UiText.named("seat_names", str(seat.label))
	for map in game.hud.find_children("TownMinimap", "Control", true, false):
		for label in map.labels:
			UiText.named("places", str(label.text))
	var costumes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/plush_costumes.json"))
	UiText.named("outfits", "BonBon's own look")
	for id in costumes.outfits:
		UiText.named("outfits", id)
	check(UiText.missing.is_empty(), "every place, map, category, species, seat and outfit name has a phrase; missing: %s" % [UiText.missing])

	# --- A language change ends a running minigame with the NPC's goodbye ------------------
	settings.set_languages("en", "es")
	var family = game.get_node("FamilySession")
	game.player.global_position = family.doctor.global_position - family.doctor.global_basis.z * 3.0
	family._process(.1)
	family.open_game()
	check(game.family_panel.visible, "family game open")
	settings.set_languages("es", "en")
	check(not game.family_panel.visible and box.visible, "language change closes the family game")
	check(str(family.doctor.get_meta("character_name")) == lex.phrase("hospital.dr_li", "en"), "Dr. Li's name follows the new foreign language: " + str(family.doctor.get_meta("character_name")))
	box.dialogue_closed.emit()
	settings.set_languages("en", "es")
	var cashier = game.get_node("CashierSession_supermarket")
	cashier.set_process(false)
	cashier.offered = true
	game.player.global_position = cashier.cashier.global_position - cashier.cashier.global_basis.z * 3.0
	game.interaction.clerk_activated.emit(cashier.cashier)
	box.choice_pressed.emit("cashier_count")
	check(cashier.activity_running() and game.money_panel.visible, "cashier round running")
	settings.set_languages("es", "en")
	check(not cashier.activity_running() and not game.money_panel.visible, "language change ends the cashier round")
	box.dialogue_closed.emit()
	settings.set_languages("en", "es")
	var shop = game.get_node("ShopSession_supermarket")
	shop.set_process(false)
	shop.needs_help = true
	game.interaction.clerk_activated.emit(shop.clerk)
	box.choice_pressed.emit("yes")
	box.dialogue_closed.emit()
	check(shop.activity_running(), "grocery order running")
	settings.set_languages("es", "en")
	check(not shop.activity_running(), "language change cancels the grocery order")
	check(Board.shared().blocker("family_dr_li") == "", "no activity left running")
	box.dialogue_closed.emit()
	# A Display Mode change alone does not end anything.
	settings.set_languages("en", "es")
	family.open_game()
	settings.set_display(GameSettings.BOTH)
	check(game.family_panel.visible, "a Display Mode change keeps the game open")
	family.close_game()
	box.dialogue_closed.emit()
	finish()

## Species of the house characters (their name cards).
func character_species(game) -> Array:
	var found: Array = []
	for node in game.find_children("*", "Node3D", true, false):
		if node.has_meta("character_species"):
			found.append(str(node.get_meta("character_species")))
	return found
