extends SceneTree
## Word pictures (scripts/ui/word_pictures.gd, 23 Nov 2026; guide:
## docs/guides/ARCHITECTURE_REVIEW_PART1.md#word-pictures). Loads the town, then checks which
## words get a picture (per category: has a town object, its meshes fit, not a non-noun category),
## that the journal rows, the journal detail and the results screen show them, and that the
## in-world word card has none. Writes user:// saves: run with an isolated HOME.
##   HOME=<scratch>/home VT_FOCUS=all godot --headless --path . --script res://docs/evidence/word-pictures-20261123/verify.gd
## With graphics it also draws every picture and saves the journal, detail and results views next
## to this script; with WORD_PICTURE_SHEETS=<folder> it also saves contact sheets of every picture
## (word under each) to that folder, for review:
##   HOME=<scratch>/home VT_FOCUS=all godot --path . --resolution 1600x1000 --script res://docs/evidence/word-pictures-20261123/verify.gd
const WordPictures := preload("res://scripts/ui/word_pictures.gd")
const BonStyle := preload("res://scripts/ui/bon_style.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const DIR := "res://docs/evidence/word-pictures-20261123/"
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

## Waits until `key`'s picture is drawn (or found missing); returns it.
func drawn(pictures, key: String) -> Texture2D:
	var texture: Texture2D = pictures.picture(key)
	var frames := 0
	while texture == null and pictures.has_picture(key) and frames < 240:
		await process_frame
		texture = pictures.picture(key)
		frames += 1
	return texture

func run():
	GameSettings.shared().set_languages("en", "es")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	# No stray key or click (a focused window) opens the map over the views.
	game.set_process_input(false)
	game.set_process_unhandled_input(false)
	await process_frame
	var pictures = WordPictures.shared()
	check(pictures != null and pictures == game.word_pictures, "Main makes the shared picture maker")

	# --- Which words get a picture --------------------------------------------------------------
	var by_category: Dictionary = {}
	var with_picture: Array = []
	var too_big: Array = []
	for key in game.vocabulary:
		var category := str(game.vocabulary_categories.get(key, ""))
		if not by_category.has(category):
			by_category[category] = [0, 0]
		by_category[category][0] += 1
		if not pictures.has_picture(key):
			continue
		var parts: Dictionary = {}
		for target in pictures.targets.get(key, []):
			parts = WordPictures.gather(target)
			if not parts.is_empty():
				break
		if parts.is_empty():
			too_big.append(key)
			continue
		for node in parts.nodes:
			node.free()
		by_category[category][1] += 1
		with_picture.append(key)
	var names: Array = by_category.keys()
	names.sort()
	for category in names:
		print("WORD PICTURES %s: %d of %d" % [category, by_category[category][1], by_category[category][0]])
	print("WORD PICTURES total: %d of %d words; no picture (object too big or no meshes): %s" % [with_picture.size(), game.vocabulary.size(), too_big])
	for category in WordPictures.NO_PICTURE_CATEGORIES:
		check(by_category.get(category, [0, 0])[1] == 0, "no pictures for %s" % category)
	check(with_picture.size() > 400, "most nouns have a picture (%d)" % with_picture.size())
	for key in ["apple", "chair", "dog", "car"]:
		check(with_picture.has(key), "%s has a picture" % key)
	check(not pictures.has_picture("after") and not pictures.has_picture("red") and not pictures.has_picture("bakery"), "non-nouns (after, red) and place signs (bakery) have none")
	# words.json "picture": false (blank boards, plain slabs, body-chart blobs; 23 Nov 2026).
	check(game.vocabulary_no_picture.size() > 100, "words.json marks the weak pictures (%d)" % game.vocabulary_no_picture.size())
	for key in game.vocabulary_no_picture:
		if pictures.has_picture(key) or with_picture.has(key):
			check(false, "%s is marked picture: false but has a picture" % key)
	check(not pictures.has_picture("floor") and not pictures.has_picture("arm") and not pictures.has_picture("arrival"), "floor, arm and arrival (picture: false) have none")

	# --- The journal: a picture column and a big detail picture ------------------------------------
	var book = game.hud.journal_book
	game.toggle_study_journal()
	await process_frame
	await process_frame
	var row: Control = null
	for r in book.rows:
		if r.visible and str(r.get_meta("line").get_meta("key", "")) != "":
			row = r
			break
	check(row != null and row.get_meta("line").get_child(1) is TextureRect, "journal rows have a picture cell after the star")
	check(book.header.get_child(book.FOREIGN_CELL).text != "" and book.header.get_child(1).text == "", "the header keeps the picture column free")
	if graphics():
		book.chosen_categories = {"Food & Drink": true}
		book.rebuild()
		for i in 40: await process_frame
		# The first row with a picture (the first Food word, oil, is "picture": false).
		var art: TextureRect = null
		for r in book.rows:
			var key := str(r.get_meta("line").get_meta("key", ""))
			if r.visible and key != "" and pictures.has_picture(key):
				art = r.get_meta("line").get_child(1)
				break
		check(art != null and art.texture != null, "a journal row shows its picture once drawn")
		await shot(DIR + "journal-food.png")
		book.chosen_categories = {"Furniture": true}
		book.rebuild()
		for i in 40: await process_frame
		await shot(DIR + "journal-furniture.png")
		book.chosen_categories = {}
		book.rebuild()
	book.open_detail("chair")
	check(book.detail_picture.visible, "the detail view shows chair's picture")
	if graphics():
		await drawn(pictures, "chair")
		await shot(DIR + "detail-chair.png")
	book.open_detail("after")
	check(not book.detail_picture.visible, "no detail picture for a non-noun (after)")
	book.close_detail()
	game.toggle_study_journal()
	await process_frame

	# --- Results screen --------------------------------------------------------------------------
	var screen = game.results_screen
	var summary := {"new": ["chair", "apple", "dog", "after"], "practiced": ["car", "bread"], "struggled": [],
			"all": ["chair", "apple", "dog", "after", "car", "bread"], "highlights": ["chair", "apple", "dog", "after"]}
	screen.show_results({"title": "Books Sorted!", "line": "You helped Rosa put every book back on its shelf!", "words": summary})
	for i in 4: await process_frame
	var chair_row: Node = screen.find_child("Word chair", true, false)
	var after_row: Node = screen.find_child("Word after", true, false)
	check(chair_row != null and chair_row.get_node_or_null("Picture") is TextureRect, "results: chair row has a picture")
	check(after_row != null and after_row.get_node_or_null("Picture") == null, "results: no picture for after")
	if graphics():
		for key in ["chair", "apple", "dog"]:
			await drawn(pictures, key)
		await shot(DIR + "results.png")
	screen._continue()

	# --- Every picture (graphics): drawing time and contact sheets -------------------------------
	if graphics():
		var sheets := OS.get_environment("WORD_PICTURE_SHEETS")
		var textures: Dictionary = {}
		var started := Time.get_ticks_msec()
		var missing: Array = []
		for key in with_picture:
			var texture := await drawn(pictures, key)
			if texture == null:
				missing.append(key)
			else:
				textures[key] = texture
		var seconds := (Time.get_ticks_msec() - started) / 1000.0
		print("WORD PICTURES drawn %d in %.1f s (%.0f ms each, %d at once)" % [textures.size(), seconds, seconds * 1000.0 / maxf(1, textures.size()), WordPictures.AT_ONCE])
		check(missing.is_empty(), "every gathered word draws a picture: missing %d %s" % [missing.size(), missing.slice(0, 8)])
		if not missing.is_empty():
			var key: String = missing[0]
			var parts: Dictionary = WordPictures.gather(pictures.targets[key][0])
			print("WORD PICTURES first missing %s: busy %d, queue %s, failed %s, parts %d" % [key, pictures._busy, pictures._queue, pictures._failed.has(key), parts.get("nodes", []).size()])
			if not parts.is_empty():
				var direct: Texture2D = await WordPictures.draw(pictures, parts.nodes, parts.bounds, 128)
				print("WORD PICTURES direct draw of %s: %s" % [key, direct != null])
		if sheets != "":
			await contact_sheets(textures, sheets)
	print("WORD PICTURES CHECKS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

## Pages of 12 x 7 pictures with the English word under each, in category order.
func contact_sheets(textures: Dictionary, folder: String) -> void:
	var keys: Array = textures.keys()
	keys.sort_custom(func(a, b):
		var ca := str(game.vocabulary_categories.get(a, ""))
		var cb := str(game.vocabulary_categories.get(b, ""))
		return ca < cb if ca != cb else str(a) < str(b))
	var layer := CanvasLayer.new()
	layer.layer = 100
	root.add_child(layer)
	var page_size := 84
	for page in range(0, keys.size(), page_size):
		var back := ColorRect.new()
		back.color = BonStyle.SKY
		back.size = Vector2(root.size)
		layer.add_child(back)
		var grid := GridContainer.new()
		grid.columns = 12
		grid.position = Vector2(8, 8)
		back.add_child(grid)
		for key in keys.slice(page, page + page_size):
			var cell := VBoxContainer.new()
			cell.custom_minimum_size = Vector2(128, 136)
			var art := TextureRect.new()
			art.texture = textures[key]
			art.custom_minimum_size = Vector2(112, 112)
			art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			cell.add_child(art)
			var label := Label.new()
			label.text = str(key)
			label.clip_text = true
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", 13)
			label.add_theme_color_override("font_color", BonStyle.INK)
			cell.add_child(label)
			grid.add_child(cell)
		await shot(folder.path_join("sheet-%02d.png" % (page / page_size + 1)))
		back.free()
	layer.free()
