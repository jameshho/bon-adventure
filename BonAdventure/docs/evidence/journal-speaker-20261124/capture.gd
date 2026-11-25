extends SceneTree
## Journal speaker and animal word pictures (24 Nov 2026; guides docs/guides/VOICE.md,
## docs/guides/ARCHITECTURE_REVIEW_PART1.md#word-pictures). Lets the park animals move for 400
## frames, draws the lion as it was drawn before the fix (lion-before.png: every part at its posed
## place) and with gather() (lion-after.png), then opens the journal at "red panda" (journal-rows.png,
## journal-detail.png) and prints whether the speakers show. Presses nothing; plays no sound.
##   OUT=<folder> HOME=<scratch>/home VT_FOCUS=home VT_SPAWN=none godot --path . --resolution 1600x1000 \
##     --script res://docs/evidence/journal-speaker-20261124/capture.gd
const WordPictures := preload("res://scripts/ui/word_pictures.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const Sound := preload("res://scripts/core/sound.gd")
func _initialize(): run.call_deferred()
func shot(path: String) -> void:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run():
	var out := OS.get_environment("OUT")
	GameSettings.shared().set_languages("en", "es")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	game.set_process_input(false)
	game.set_process_unhandled_input(false)
	await process_frame
	var wp = WordPictures.shared()
	# Let the animals walk and look around (bones posed away from rest).
	for i in 400: await process_frame
	for key in ["lion", "elephant"]:
		var targets: Array = wp.targets.get(key, [])
		if targets.is_empty():
			continue
		var t: Node3D = targets[0]
		var att = t.find_children("Head", "BoneAttachment3D", true, false)
		if not att.is_empty():
			print(key, " head moved from rest by ", WordPictures._rest_correction(att[0]).origin.length())
		if key == "lion":
			# Before the fix: every part at its posed place (no rest correction).
			var parts: Dictionary = WordPictures.gather(t)
			var inv := t.global_transform.affine_inverse()
			var i := 0
			for n in t.find_children("*", "", true, false):
				if n is MeshInstance3D and n.mesh != null:
					pass
			var raw: Array = []
			var bounds: AABB = parts.bounds
			for n in t.find_children("*", "MeshInstance3D", true, false):
				var c := MeshInstance3D.new()
				c.mesh = n.mesh
				for k in n.get_surface_override_material_count():
					c.set_surface_override_material(k, n.get_surface_override_material(k))
				c.material_override = n.material_override
				c.transform = inv * n.global_transform
				raw.append(c)
			for n in parts.nodes: n.free()
			var old: Texture2D = await WordPictures.draw(wp, raw, bounds, 128, WordPictures.ANIMAL_VIEW)
			old.get_image().save_png(out + "/pic_lion_before.png")
		var tex: Texture2D = wp.picture(key)
		var frames := 0
		while tex == null and frames < 240:
			await process_frame
			tex = wp.picture(key)
			frames += 1
		if tex:
			tex.get_image().save_png("%s/pic_%s.png" % [out, key.replace(" ", "_")])
	print("voices on ", Sound.shared().voice_enabled())
	game.toggle_study_journal()
	for i in 30: await process_frame
	var book = game.hud.vocabulary_book if "vocabulary_book" in game.hud else null
	if book == null:
		for n in root.find_children("*", "VBoxContainer", true, false):
			if n.has_method("open_detail"):
				book = n
	print("book ", book != null)
	if book:
		book.scroll_to("red panda")
		for i in 60: await process_frame
		var row = book.row_for("red panda")
		print("row speaker shown ", row != null and row.get_meta("line").get_child(book.SPEAKER_CELL).visible and not row.get_meta("line").get_child(book.SPEAKER_CELL).disabled)
		await shot(out + "/journal_rows.png")
		book.open_detail("red panda")
		for i in 30: await process_frame
		print("detail speaker shown ", book.detail_speaker.visible)
		await shot(out + "/journal_detail.png")
	print("nothing played ", not Sound.shared().is_playing())
	print("DONE")
	quit()
