extends SceneTree
## Rendered views of the LEARN-06 levels that change what is on screen (25 Nov 2026): Spot the
## Suspect at level 4 (five suspects, three clues), Feel the Clues at level 4 (five objects),
## Library Helper's level 4 cart (plain spines) and Wire It Up! at level 3 (six wires).
## Graphics required; Main writes progress, so run it with an isolated HOME (README):
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --audio-driver Dummy --resolution 1280x800 --script res://docs/evidence/levels-20261125/capture.gd
const FOLDER := "res://docs/evidence/levels-20261125"
const Progress := preload("res://scripts/learning/game_progress.gd")
const Board := preload("res://scripts/learning/activity_board.gd")

func _initialize() -> void:
	run.call_deferred()

func shot(title: String, frames := 10) -> void:
	for i in frames:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(FOLDER + "/" + title + ".png"))
	print("saved " + title)

## Unlocks and selects level `n` of `id`.
func reach(id: String, n: int) -> void:
	Progress.shared().unlock(id, n)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		print("LEVELS CAPTURE needs graphics")
		quit(1)
		return
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.player.set_physics_process(false)
	await create_timer(2.0).timeout
	Progress.shared().data = {}
	reach("lineup_rocco", 4)
	var lineup = game.get_node("PoliceDetective_lineup")
	lineup.start_game()
	await shot("lineup-l4", 60)
	print("lineup: %d suspects, clues %s" % [lineup.round.candidates.size(), lineup.round.clues.map(func(c): return c.id)])
	lineup.end_game("")
	await create_timer(1.0).timeout
	reach("evidence_mimi", 4)
	var evidence = game.get_node("PoliceDetective_evidence")
	evidence.start_game()
	await shot("evidence-l4", 60)
	print("evidence: %d objects" % evidence.round.candidates.size())
	evidence.end_game("")
	await create_timer(1.0).timeout
	reach("library_rosa", 4)
	var library = Board.shared().session("library_rosa")
	library._fill_cart()
	var eye := Camera3D.new()
	game.add_child(eye)
	var cart: Node3D = library.cart
	eye.global_position = cart.global_position + cart.global_basis * Vector3(0, 1.6, -1.5)
	eye.look_at(cart.global_position + Vector3(0, .7, 0), Vector3.UP)
	eye.current = true
	game.hud.hide()
	await shot("library-l4-cart", 30)
	eye.current = false
	game.hud.show()
	reach("electrical_box", 3)
	var wires = Board.shared().session("electrical_box")
	wires.launch()
	await create_timer(2.0).timeout
	await shot("wires-l3", 10)
	print("wires: %d" % wires.panel.wires.size())
	wires.close_box()
	await create_timer(1.0).timeout
	print("LEVELS CAPTURE done")
	quit()
