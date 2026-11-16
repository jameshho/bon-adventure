extends SceneTree
## Renders of the Grammar Classroom (writes PNGs into this folder; not in the check runner).
## Uses Main, which saves progress: run with an isolated HOME (README), windowed (not headless),
## with VT_FOCUS=school for speed:
##   HOME=<scratch>/home VT_FOCUS=school godot --path . --script res://docs/evidence/grammar-class-20261106/capture.gd -- room
##   ... -- game      (a class in Spanish, Chinese and English; `-- game en` renders one)
##   ... -- dialogue before   (Lana's dialogue box in class: dialogue-*-before.png)
##   ... -- board     (14 Nov 2026: the bigger board from the start, Spanish and Chinese, and the
##                     months poster on the side wall; PNGs in docs/evidence/grammar-class-20261114/)
const School := preload("res://scripts/buildings/school.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const Questions := preload("res://scripts/learning/grammar_questions.gd")
var OUT := "res://docs/evidence/grammar-class-20261106/"
var game
var school: Node3D
var cam: Camera3D

func _initialize(): run.call_deferred()

func shot(title: String, from: Vector3, at: Vector3, up := Vector3.UP) -> void:
	cam.global_position = school.to_global(from)
	cam.look_at(school.to_global(at), up)
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + title + ".png")
	print("saved ", title)

## The player's own camera, seated at answer chair `letter` (what the learner sees).
func seated_shot(title: String, letter: String) -> void:
	var session = game.get_node_or_null("GrammarSession")
	var chair: Node3D = null
	for node in school.find_children("*", "Node3D", true, false):
		if str(node.get_meta("grammar_seat", "")) == letter:
			chair = node
	if game.player.seated:
		game.seating.stand()
		for i in 40: await physics_frame
	game.player.global_position = chair.global_position + school.global_basis * Vector3(.8, .1, 0)
	await physics_frame
	game.seating.try_sit()
	for i in 50: await physics_frame
	if session and not session.is_processing():
		session._process(0.0)
	game.player.camera_yaw = game.player.rotation.y
	game.player.reset_camera()
	cam.current = false
	game.camera.current = true
	_close_map()
	for i in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + title + ".png")
	print("saved ", title, " seated=", game.player.seated, " at ", session.seated_letter() if session else "")
	cam.current = true

## Seats the player at answer chair `letter` without saving a picture.
func _sit_quietly(letter: String) -> void:
	var chair: Node3D = null
	for node in school.find_children("*", "Node3D", true, false):
		if str(node.get_meta("grammar_seat", "")) == letter:
			chair = node
	game.player.global_position = chair.global_position + school.global_basis * Vector3(.8, .1, 0)
	await physics_frame
	game.seating.try_sit()
	for i in 50: await physics_frame
	game.player.camera_yaw = game.player.rotation.y
	game.player.reset_camera()

## What the player's camera shows now (the HUD and dialogue box included).
func _player_shot(title: String) -> void:
	cam.current = false
	game.camera.current = true
	_close_map()
	for i in 20: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + title + ".png")
	print("saved ", title)
	cam.current = true

## The render window may get stray keys (M opens the map): keep it closed for the pictures.
func _close_map() -> void:
	if game.hud.is_map_open():
		game.hud.toggle_map()

func run():
	root.size = Vector2i(1280, 800)
	var args := OS.get_cmdline_user_args()
	var mode: String = args[0] if not args.is_empty() else "room"
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 30: await process_frame
	school = preload("res://scripts/world/modular_town.gd").building(game.apartment, "school", 1)
	cam = Camera3D.new()
	game.add_child(cam)
	cam.fov = 60
	cam.current = true
	var roof: Node3D = school.get_node("MainRoof")
	if mode == "board":
		var session = game.get_node("GrammarSession")
		OUT = "res://docs/evidence/grammar-class-20261114/"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
		for pair in [["en", "es"], ["en", "zh"]]:
			GameSettings.shared().set_languages(pair[0], pair[1])
			for i in 5: await process_frame
			session.offered = true
			await session.start_class()
			session.set_process(false)
			# The longest question in the class, so the shot shows the wrapping at its worst.
			var longest := 0
			for i in session.questions.size():
				if Questions.blanked(session.questions[i]).length() > Questions.blanked(session.questions[longest]).length():
					longest = i
			session._show_board(Questions.blanked(session.questions[longest]))
			game.player.camera_yaw = game.player.rotation.y
			game.player.reset_camera()
			await _player_shot("board-" + pair[1] + "-from-start")
			session.end_class("")
			session.set_process(true)
		for c in game.get_children():
			if c is CanvasLayer: c.visible = false
		game.player.visible = false
		await shot("months-side-wall", Vector3(-5.0, 1.8, -8.0), Vector3(-11.7, 2.4, -9.6))
		await shot("room-from-entrance", Vector3(0, 1.7, -11.6), Vector3(-6.5, 1.4, 2.0))
		roof.visible = false
		await shot("room-top", Vector3(-4, 17, -3.4), Vector3(-4, 0, -3.35), Vector3(0, 0, 1))
		roof.visible = true
	elif mode == "dialogue":
		# Lana's dialogue box during a class, from the player's seat (-- dialogue <suffix>).
		var session = game.get_node("GrammarSession")
		var suffix: String = args[1] if args.size() > 1 else "now"
		GameSettings.shared().set_languages("en", "es")
		for i in 5: await process_frame
		session.offered = true
		await session.start_class()
		session.set_process(false)
		await _sit_quietly("C")
		session._say("grammar.keep_going")
		await _player_shot("dialogue-keep-going-" + suffix)
		session._close_dialogue()
		session._finish_questions()
		await _player_shot("dialogue-final-" + suffix)
		session._close_dialogue()
		session.end_class("")
		session.set_process(true)
	elif mode == "room":
		for c in game.get_children():
			if c is CanvasLayer: c.visible = false
		game.player.visible = false
		roof.visible = false
		await shot("room-top", Vector3(-4, 17, -3.4), Vector3(-4, 0, -3.35), Vector3(0, 0, 1))
		roof.visible = true
		await shot("room-from-start", School.START + Vector3(0, 1.7, -1.2), Vector3(-6.4, 1.4, 5.5))
		await shot("room-board", Vector3(-6.8, 1.9, 0.0), Vector3(-6.8, 1.9, 5.5))
		await shot("room-from-entrance", Vector3(0, 1.7, -11.6), Vector3(-6.5, 1.0, 0.0))
		await shot("room-front-wall", Vector3(-6.5, 1.8, -4.0), Vector3(-7.0, 1.9, -12.0))
		await shot("room-music-corner", Vector3(-6.0, 1.8, -6.0), Vector3(-11.0, 0.8, -4.4))
		game.player.visible = true
		for letter in School.ANSWER_DESKS:
			await seated_shot("seat-" + letter, letter)
	else:
		var session = game.get_node("GrammarSession")
		var pairs := [["en", "es"], ["en", "zh"], ["es", "en"]]
		if args.size() > 1:
			# One learned language only, e.g. -- game en
			pairs = pairs.filter(func(pair: Array) -> bool: return pair[1] == args[1])
		for pair in pairs:
			GameSettings.shared().set_languages(pair[0], pair[1])
			for i in 5: await process_frame
			session.offered = true
			await session.start_class()
			# Freeze the countdown while rendering (a hidden window renders slowly).
			session.set_process(false)
			for i in 5: await process_frame
			await seated_shot("class-" + pair[1] + "-question", "C")
			await shot("class-" + pair[1] + "-board", Vector3(-6.8, 1.9, -0.6), Vector3(-6.8, 1.6, 5.5))
			session.submit()
			for i in 5: await process_frame
			cam.current = false
			game.camera.current = true
			_close_map()
			for i in 6: await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUT + "class-" + pair[1] + "-feedback.png")
			cam.current = true
			session.end_class("")
			session.set_process(true)
	game.free()
	quit()
