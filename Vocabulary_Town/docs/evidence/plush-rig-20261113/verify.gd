extends SceneTree
## 13 Nov 2026 shared plush eyes, blinking and gestures (scripts/characters/plush_life.gd,
## docs/guides/COMPONENTS.md#plush-characters): the town blinker, the sleep override, the player's
## lying eyes and the whole-body gestures at the mahjong table.
## Checks (headless):  HOME=<scratch> VT_FOCUS=home VT_SPAWN=none \
##   godot --headless --fixed-fps 60 --path . --script res://docs/evidence/plush-rig-20261113/verify.gd
## Views (graphics, same environment, no --headless; add --resolution 1280x800): poses each
## figure at the peak of a move and writes <view>.png here; no timed checks, because a window
## in the background runs too slowly for them. Reads no saves.
const OUT := "res://docs/evidence/plush-rig-20261113"
const PlushLife := preload("res://scripts/characters/plush_life.gd")
var checks := 0
var failures := 0
var game
var graphics := false

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

func wait(seconds: float) -> void:
	await create_timer(seconds).timeout

## A view of `figure` from in front (it faces its local -Z), `back` metres away.
func shot(figure: Node3D, title: String, back := 3.4, up := 1.5) -> void:
	if not graphics:
		return
	var cam := Camera3D.new()
	cam.fov = 40
	root.add_child(cam)
	var facing := -figure.global_basis.z
	facing.y = 0
	cam.global_position = figure.global_position + facing.normalized() * back + Vector3(0, up + 0.5, 0)
	cam.look_at(figure.global_position + Vector3(0, up, 0), Vector3.UP)
	cam.current = true
	game.hud.visible = false
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [OUT, title])
	print("CAPTURE ", title)
	game.hud.visible = true
	cam.queue_free()
	game.camera.current = true

func run() -> void:
	graphics = DisplayServer.get_name() != "headless"
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 4: await process_frame
	if game.day_night:
		game.day_night.pause()
		game.day_night.set_time(12 * 60.0)
	if graphics:
		await render()
		quit()
		return
	var town: Node = game.plush_life
	check(town != null and not town.gestures and town.blink_gap == PlushLife.TOWN_BLINK_GAP, "Main has the town blinker (no gestures, slow gap)")
	await wait(2.2)
	var leo := game.get_node_or_null("HouseCharacters/leo") as Node3D
	check(leo != null and town.figures.has(leo), "a house character is in the town blinker's set (%d figures)" % town.figures.size())
	var animals := 0
	for figure in town.figures:
		if not figure.has_node("Head/LeftEye"):
			animals += 1
	check(animals == 0, "only figures with plush eyes are followed")
	if leo != null:
		town.blink(leo)
		for i in 2: await process_frame
		check(PlushLife.eyes_shut(leo), "a town NPC blinks")
		await wait(0.3)
		check(not PlushLife.eyes_shut(leo), "the blink ends with the eyes open")
		# Sleeping holds the eyes shut: a blink neither starts nor opens them.
		PlushLife.hold_eyes(leo, true)
		town.blink(leo)
		await wait(0.4)
		check(PlushLife.eyes_shut(leo), "held eyes stay shut through a blink")
		PlushLife.hold_eyes(leo, false)
		check(not PlushLife.eyes_shut(leo), "releasing the hold opens the eyes")
	# The mahjong players belong to the session's own PlushLife, not the town's.
	var session = game.get_node_or_null("MahjongSession")
	var bao: Node3D = session.npcs[1] if session != null and session.npcs.size() > 1 else null
	check(bao != null and session.life.figures.has(bao) and not town.figures.has(bao), "a mahjong player is blinked by its session only")
	if bao != null:
		var rest := bao.transform
		var face: Transform3D = (bao.get_node("Head") as Node3D).transform
		for kind in ["shake", "nod", "tilt", "hop"]:
			session.life.gesture(bao, kind)
			await wait(0.3 if kind == "tilt" else 0.1)
			check(session.life.moving(bao) and not bao.transform.is_equal_approx(rest), "%s moves the whole figure" % kind)
			check((bao.get_node("Head") as Node3D).transform.is_equal_approx(face), "%s leaves the face on the body" % kind)
			await wait(1.3)
			check(not session.life.moving(bao) and bao.transform.is_equal_approx(rest), "%s ends at rest" % kind)
	# The player lying down: eyes close with the pose and open on standing.
	var player = game.player
	var bonbon: Node3D = player.get_node("Visual/BonBon")
	player.begin_sitting(player.global_position + Vector3(0, 0.4, 0), player.rotation.y, true)
	await wait(0.9)
	check(player.lying and PlushLife.eyes_held(bonbon) and PlushLife.eyes_shut(bonbon), "lying shuts and holds the player's eyes")
	player.end_sitting(player.global_position)
	await wait(0.8)
	check(not player.seated and not PlushLife.eyes_held(bonbon) and not PlushLife.eyes_shut(bonbon), "standing up opens the player's eyes")
	print("PLUSH LIFE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

## Posed views: each figure at the peak of a move (see the header).
func render() -> void:
	var leo := game.get_node_or_null("HouseCharacters/leo") as Node3D
	if leo != null:
		await shot(leo, "npc-open")
		PlushLife.set_eyes_open(leo, 0.0)
		await shot(leo, "npc-blink")
		PlushLife.set_eyes_open(leo, 1.0)
	var session = game.get_node_or_null("MahjongSession")
	var bao: Node3D = session.npcs[1] if session != null and session.npcs.size() > 1 else null
	if bao != null:
		var rest := bao.rotation
		await shot(bao, "gesture-rest")
		for pose in [["shake", Vector3(0, 0.18, 0)], ["nod", Vector3(-0.09, 0, 0)], ["tilt", Vector3(0, 0, 0.09)]]:
			bao.rotation = rest + (pose[1] as Vector3)
			await shot(bao, "gesture-%s" % pose[0])
		bao.rotation = rest
	var player = game.player
	player.begin_sitting(player.global_position + Vector3(0, 0.4, 0), player.rotation.y, true)
	player.sit_tween.kill()
	player.sit_blend = 1.0
	for i in 3: await physics_frame
	var cam := Camera3D.new()
	cam.fov = 50
	root.add_child(cam)
	cam.global_position = player.global_position + Vector3(0.4, 7.0, 0.4)
	cam.look_at(player.global_position, Vector3.UP)
	cam.current = true
	game.hud.visible = false
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/player-lying.png" % OUT)
	print("CAPTURE player-lying")
