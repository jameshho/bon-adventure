extends SceneTree
## Record player in the home's living room (user request, 25 Nov 2026; scripts/world/record_player.gd,
## scripts/ui/record_player_panel.gd). Checks: the stand stands beside the TV's media console,
## clear of it and of the wall; it is an interactable; E opens the close-up with every music
## track as a song; a song plays (sound.gd town_track, the label colour, the disc turns, the arm
## on the record); ◀ / ▶ step round the list; the green button stops (arm back, disc still) and
## plays again; the ✕ closes and gives the camera back. Music itself never plays in a check
## (sound.gd), so the panel's state and the turntable are checked, not the audio.
## Writes into this folder (overwrites): room.png (the living room), closeup.png (the panel open,
## a song changing), closeup_stopped.png, phone.png (844 × 390).
## Needs a window; isolated HOME, the home unit loaded:
##   HOME=<scratch>/home VT_FOCUS=home VT_SPAWN=none godot --path . --resolution 1200x800 --script res://docs/evidence/record-player-20261125/verify.gd
const ModularTown := preload("res://scripts/world/modular_town.gd")
const Interactable := preload("res://scripts/core/interactable.gd")
const Sound := preload("res://scripts/core/sound.gd")
const FOLDER := "res://docs/evidence/record-player-20261125/"

var game
var failures := 0

func check(ok: bool, label: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok:
		failures += 1

func _initialize() -> void:
	run.call_deferred()

func frames(n: int) -> void:
	for i in n:
		await process_frame

## Waits until `ready` is true or `seconds` have passed (frame rates vary: other Godot runs).
func wait_for(ready: Callable, seconds: float) -> void:
	var end := Time.get_ticks_msec() + int(seconds * 1000.0)
	while not ready.call() and Time.get_ticks_msec() < end:
		await process_frame

func wait_seconds(seconds: float) -> void:
	await wait_for(func() -> bool: return false, seconds)

## Saves the window. Never waits on frame_post_draw: a hidden or busy window may not draw, and the
## check would hang (25 Nov 2026); a few frames, then the last drawn image.
func shot(path: String) -> void:
	await frames(3)
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		print("NOTE: no image for " + path)
		return
	image.save_png(FOLDER + path)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		print("needs a window")
		quit(1)
		return
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(40)
	game.day_night.pause()
	game.day_night.set_time(11.0 * 60.0)
	var rp: Node3D = null
	for node in get_nodes_in_group("record_players"):
		rp = node
	check(rp != null, "a record player in the town")
	if rp == null:
		quit(1)
		return
	var site: Node3D = rp.get_parent()
	check(site.name == "Home", "it belongs to the home (%s)" % site.name)
	var console: Node3D = rp.get_parent().get_node("Media console")
	# Placement in the home's own coordinates: console x -4.80..-4.10, z 2.80..6.00; wall x -4.91.
	var at: Vector3 = rp.position
	var half_w: float = rp.STAND_SIZE.x * 0.5
	var half_d: float = rp.STAND_SIZE.z * 0.5
	check(at.z - half_w > 6.0 + 0.1, "the stand is north of the console with a gap (from z %.2f)" % (at.z - half_w))
	check(at.z + half_w < 8.46 - 0.6, "clear of the bathroom door (to z %.2f)" % (at.z + half_w))
	check(at.x - half_d > -4.91, "in front of the wall (back at x %.3f)" % (at.x - half_d))
	check(absf(at.z - half_w - (console.position.z + 1.6)) < 0.6, "right beside the console")
	check((rp.facing() - rp.get_parent().global_transform.basis.x.normalized()).length() < 0.01, "faces the room (+X)")
	check(rp.get_node_or_null(Interactable.NODE_NAME) != null, "has an Interactable")
	check(rp.has_meta("keep_own_draw"), "kept out of the static batches")
	var model_count := 0
	for child in rp.get_children():
		if child.name == "Model":
			model_count += 1
	check(model_count == 1, "one model (the saved copy rebuilt, not doubled)")
	# The room view.
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	var player_spot: Vector3 = site.to_global(Vector3(-2.4, 0.05, 6.4))
	game.player.global_position = player_spot
	var view := Camera3D.new()
	view.near = 0.05
	game.add_child(view)
	view.fov = 70
	view.global_position = site.to_global(Vector3(0.8, 2.6, 6.2))
	view.look_at(site.to_global(Vector3(-4.6, 0.9, 5.4)))
	view.current = true
	game.player.visible = false
	game.hud.hide()
	await frames(30)
	await shot("room.png")
	view.current = false
	game.player.camera.make_current()
	game.player.visible = true
	game.hud.show()
	game.player.set_physics_process(true)
	game.interaction.set_physics_process(true)
	# Stand in front of it and use it like E does.
	game.player.global_position = site.to_global(Vector3(-3.4, 0.05, 6.7))
	await frames(20)
	var panel = game.record_player_panel
	check(panel != null, "Main has the record player panel")
	check(rp.can_interact() == true, "usable while no game runs")
	check(rp.use(), "use() opens the panel")
	await wait_for(func() -> bool: return panel.state == "open", 10.0)
	await frames(5)
	check(panel.state == "open", "the close-up is open (%s)" % panel.state)
	check(get_root().get_viewport().get_camera_3d() == panel.camera, "the close-up camera is current")
	check(not game.player.controls_enabled, "the player is locked while it is open")
	var sound = Sound.shared()
	var names: Array = sound.track_names()
	check(names.size() == 7, "seven songs (%d)" % names.size())
	var songs: Node = panel.find_child("Songs", true, false)
	check(songs != null and songs.get_child_count() == names.size(), "one row per song")
	var card: Control = panel.find_child("Card", true, false)
	var screen := Rect2(Vector2.ZERO, panel.size)
	check(card != null and screen.encloses(card.get_global_rect()), "the card fits the window")
	var tt: Rect2 = panel.turntable_rect()
	check(tt.size.x > 120 and screen.encloses(tt), "the turntable is in view (%s)" % tt)
	check(card != null and not tt.intersects(card.get_global_rect()), "the card does not cover the turntable")
	for song in names:
		var id: String = "record_player.song_" + str(song)
		check(panel.UiText.has(id), "title for " + str(song))
	# Play a song from the list (the row's own button).
	var row: Button = songs.get_node_or_null("Song_mystery") if songs != null else null
	if row == null:
		print("RECORD PLAYER: no song rows, stopping")
		quit(1)
		return
	row.pressed.emit()
	await frames(5)
	check(rp.track == "mystery" and rp.playing, "a tap on a song puts that record on")
	check(sound.town_track == "mystery", "it stays the town's music after games (town_track)")
	check(rp._label_material.albedo_color.is_equal_approx(rp.label_color("mystery")) or rp._changing, "the label changes colour")
	await wait_seconds(0.5)
	await shot("closeup.png")
	await wait_for(func() -> bool: return not rp._changing and absf(rp.get_node("Model/Turntable/ToneArm").rotation.y + rp.ARM_PLAY) < 0.02, 8.0)
	await wait_seconds(1.0)
	var turn_a: float = rp.get_node("Model/Turntable/Disc").rotation.y
	await frames(10)
	var turn_b: float = rp.get_node("Model/Turntable/Disc").rotation.y
	check(not is_equal_approx(turn_a, turn_b), "the disc turns")
	check(absf(rp.get_node("Model/Turntable/ToneArm").rotation.y + rp.ARM_PLAY) < 0.02, "the arm is on the record")
	check(rp._label_material.albedo_color.is_equal_approx(rp.label_color("mystery")), "the label shows the mystery colour")
	# ▶ and ◀ step round the list.
	panel.find_child("Next", true, false).pressed.emit()
	await frames(3)
	var after: String = names[(names.find("mystery") + 1) % names.size()]
	check(rp.track == after, "▶ plays the next song (%s)" % rp.track)
	panel.find_child("Previous", true, false).pressed.emit()
	await frames(3)
	check(rp.track == "mystery", "◀ goes back (%s)" % rp.track)
	await wait_for(func() -> bool: return not rp._changing, 8.0)
	await wait_seconds(1.0)
	# Stop, then play again.
	panel.find_child("PlayPause", true, false).pressed.emit()
	await frames(3)
	check(not rp.playing and sound.town_track == "", "the green button stops the record")
	await wait_seconds(4.0)
	check(absf(rp.get_node("Model/Turntable/ToneArm").rotation.y) < 0.02, "the arm goes back to its rest")
	var still_a: float = rp.get_node("Model/Turntable/Disc").rotation.y
	await frames(10)
	check(is_equal_approx(still_a, rp.get_node("Model/Turntable/Disc").rotation.y), "the disc stops")
	var status: Label = panel.find_child("Status", true, false)
	check(status != null and status.text == panel.UiText.t("record_player.stopped"), "the card says it is stopped")
	await shot("closeup_stopped.png")
	panel.toggle()
	await frames(3)
	check(rp.playing and rp.track == "mystery" and sound.town_track == "mystery", "play again resumes the same record")
	# A phone-sized window.
	DisplayServer.window_set_size(Vector2i(844, 390))
	await wait_seconds(1.5)
	card = panel.find_child("Card", true, false)
	screen = Rect2(Vector2.ZERO, panel.size)
	check(card != null and screen.grow(1).encloses(card.get_global_rect()), "the card fits a phone window (%s in %s)" % [card.get_global_rect() if card else Rect2(), screen])
	await shot("phone.png")
	DisplayServer.window_set_size(Vector2i(1200, 800))
	await wait_seconds(1.0)
	# Close: the camera comes back and the player can move.
	panel.close_requested.emit()
	await wait_for(func() -> bool: return panel.state == "", 10.0)
	await frames(3)
	check(panel.state == "" and not panel.visible, "✕ closes the panel")
	check(get_root().get_viewport().get_camera_3d() == game.player.camera, "the player's camera is back")
	check(game.player.controls_enabled, "the player can move again")
	check(rp.playing, "the record keeps playing after closing")
	print("RECORD PLAYER: %d failures" % failures)
	quit(1 if failures > 0 else 0)
