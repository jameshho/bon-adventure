extends SceneTree
## 24 Nov 2026 (user): clicking a word on a vocabulary poster opens a close-up of the whole poster
## (scripts/ui/poster_inspect_ui.gd) instead of the word card. In the close-up a tap on a word
## shows its card, a tap off the poster closes, and the copy goes away with the wall poster shown
## again. One poster per building of the focus (posters below).
## HOME=<scratch> VT_FOCUS=school,police,restaurants,warehouse,airport VT_SPAWN=none \
##   godot --path . --resolution 1280x800 --script res://docs/evidence/poster-closeup-20261124/verify.gd
## (headless: checks only). With graphics writes *.png here.
const OUT := "res://docs/evidence/poster-closeup-20261124"
const PosterUI := preload("res://scripts/ui/poster_inspect_ui.gd")
const POSTERS := ["Classroom poster family", "Police poster evidence", "Restaurant menu board",
	"Warehouse poster verbs", "Airport poster when"]
var checks := 0
var failures := 0
var game
var graphics := false

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + label)
	if not ok:
		failures += 1

func run() -> void:
	graphics = DisplayServer.get_name() != "headless"
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 4: await process_frame
	if game.day_night:
		game.day_night.pause()
		game.day_night.set_time(12 * 60.0)
	var ui = game.poster_ui
	check(ui != null, "Main has the poster close-up")
	# Not posters: a shelf of category words, a single sign.
	var shelves: Node3D = game.find_child("CategoryShelves", true, false)
	if shelves != null:
		var shelf_word: Node = shelves.get_children().filter(func(n): return n.has_meta("word_key")).front()
		check(PosterUI.poster_of(shelf_word) == null, "a library shelf header is no poster")
	for title in POSTERS:
		var poster: Node3D = game.find_child(title, true, false)
		check(poster != null, "%s found" % title)
		if poster != null:
			await try_poster(ui, poster, title)
	finish()

func try_poster(ui, poster: Node3D, title: String) -> void:
	print("  %s at %s, basis z %s" % [poster.get_path(), poster.global_position, poster.global_basis.z])
	var words: Array = poster.get_children().filter(func(n): return str(n.get_meta("word_key", "")) != "")
	check(PosterUI.poster_of(words[0]) == poster, "%s: its words belong to the poster" % title)
	var player = game.player
	var opened := false
	var word: Node3D = words[words.size() / 2]
	for side in [-1.0, 1.0]:
		for reach in [2.2, 3.2, 4.5]:
			var normal: Vector3 = poster.global_basis.z * side
			normal.y = 0
			var spot: Vector3 = poster.global_position + normal.normalized() * reach
			var space: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
			var down := PhysicsRayQueryParameters3D.create(spot + Vector3(0, -1.0, 0), spot + Vector3(0, -8, 0))
			down.exclude = [player.get_rid()]
			var hit := space.intersect_ray(down)
			if hit.is_empty():
				print("  side %d reach %.1f: no floor under %s" % [side, reach, spot])
				continue
			player.velocity = Vector3.ZERO
			player.global_position = hit.position + Vector3(0, .05, 0)
			player.look_at(Vector3(poster.global_position.x, player.global_position.y, poster.global_position.z), Vector3.UP)
			var toward: Vector3 = -normal.normalized()
			player.camera_yaw = atan2(-toward.x, -toward.z)
			player.camera_rig.rotation.y = player.camera_yaw
			for i in 20: await physics_frame
			var view: Camera3D = root.get_viewport().get_camera_3d()
			var at: Vector3 = word.global_position
			if view.is_position_behind(at):
				print("  side %d reach %.1f: word behind the camera (player %s)" % [side, reach, player.global_position])
				continue
			game.interaction.pointer_position = view.unproject_position(at)
			game.interaction.click()
			if ui.inspecting():
				# A second click at once (a double click, or a tap seen as touch and mouse) while
				# the poster still glides in: no card, no close.
				await create_timer(.1).timeout
				var middle := Vector2(root.get_visible_rect().size) * .5
				for point in [game.interaction.pointer_position, middle]:
					game.interaction.pointer_position = point
					game.interaction.click()
				await process_frame
				check(not game.hud.is_card_visible() and ui.inspecting() and not ui.zoomed_in(), "%s: clicks during the zoom-in do nothing" % title)
			await create_timer(.7).timeout
			if ui.inspecting():
				check(ui.zoomed_in(), "%s: words can be tapped once zoomed in" % title)
				opened = true
				break
			var aimed: Dictionary = game.interaction.aimed_hit()
			var collider = aimed.get("collider")
			print("  side %d reach %.1f: aimed %s in %s, card %s" % [side, reach, collider, collider.get_parent().get_path() if collider else "-", game.hud.current_word_key if game.hud.is_card_visible() else "none"])
			game.interaction.clear_card()
		if opened:
			break
	check(opened, "%s: a click on a word opens the close-up" % title)
	if not opened:
		return
	check(not game.hud.is_card_visible(), "%s: no word card on opening" % title)
	check(not poster.visible and ui._copy != null and ui._copy.get_parent() != null, "%s: wall poster hidden, its copy on the stage" % title)
	check(not player.controls_enabled, "%s: movement off while open" % title)
	var copy_rect: Rect2 = PosterUI._screen_rect(ui._copy, game.camera)
	var screen: Vector2 = root.get_visible_rect().size
	check(copy_rect.size.x > screen.x * .6 or copy_rect.size.y > screen.y * .6, "%s: fills the view (%s of %s)" % [title, copy_rect.size, screen])
	if graphics:
		await shot(_file(title) + "-closeup")
	# A tap on a word of the copy shows its card.
	var copy_words: Array = ui._copy.get_children().filter(func(n): return str(n.get_meta("word_key", "")) != "")
	var target: Node3D = copy_words[0]
	game.interaction.pointer_position = PosterUI._screen_rect(target, game.camera).get_center()
	game.interaction.click()
	await process_frame
	check(game.hud.is_card_visible() and game.hud.current_word_key == game.interaction.word_key(target), "%s: tapping %s shows its card (%s)" % [title, target.get_meta("word_key"), game.hud.current_word_key])
	check(ui.inspecting(), "%s: still open with the card" % title)
	if graphics:
		await shot(_file(title) + "-card")
	check(game.hud.game_buttons_hidden(), "%s: game buttons hidden while open" % title)
	# Any tap closes the card first; the close-up stays.
	game.interaction.pointer_position = Vector2(4, 4)
	game.interaction.click()
	await process_frame
	check(not game.hud.is_card_visible() and ui.inspecting(), "%s: a tap closes the card, the close-up stays" % title)
	# A tap off the poster closes.
	game.interaction.pointer_position = Vector2(4, 4)
	game.interaction.click()
	await create_timer(.6).timeout
	check(not ui.inspecting() and poster.visible and ui._copy == null, "%s: a tap off the poster closes, the wall poster back" % title)
	check(player.controls_enabled and not game.hud.game_buttons_hidden(), "%s: movement and game buttons back" % title)
	check(not game.hud.is_card_visible(), "%s: card gone" % title)

func _file(title: String) -> String:
	return title.to_lower().replace(" ", "-")

func shot(title: String) -> void:
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [OUT, title])
	print("CAPTURE ", title)

func finish() -> void:
	print("POSTER CLOSE-UP: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
