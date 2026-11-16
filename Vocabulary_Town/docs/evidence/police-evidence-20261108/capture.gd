extends SceneTree
## Rendered views of Officer Mimi's evidence game after the 8 Nov 2026 redesign (one property
## word per round; find and report rounds; Apretar / Tocar / Levantar with result icons) and the
## evidence room poster; since the object change (8 Nov 2026, second pass) also the shelves and
## the card with its translation on (report-translated). Graphics required; isolated user directory (Main writes progress).
## Writes PNGs here. Needs the police unit loaded (dev_focus.txt "all" or listing police).
## godot --path . --resolution 1280x800 --script res://docs/evidence/police-evidence-20261108/capture.gd
const FOLDER := "res://docs/evidence/police-evidence-20261108"

func _initialize() -> void:
	run.call_deferred()

func shot(title: String, frames := 10) -> void:
	for i in frames:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(FOLDER + "/" + title + ".png")
	print("shot ", title)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	var station: Node3D = game.apartment.get_node("RelocatedSites/Police")
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.fov = 60.0
	camera.far = 900.0
	camera.current = true
	game.hud.hide()
	var poster := station.get_node("Interior/Police poster evidence") as Node3D
	var face: Vector3 = poster.global_basis.z.normalized()
	camera.global_position = poster.global_position - face * 2.6 + Vector3(0, .1, 0)
	camera.look_at(poster.global_position)
	await shot("poster-evidence", 20)
	# The shelves: the ten labelled exhibits (objects changed 8 Nov 2026, second pass).
	camera.global_position = station.to_global(Vector3(48.9, 1.3, 42.5))
	camera.look_at(station.to_global(Vector3(52.56, 1.05, 42.5)))
	await shot("shelf-evidence", 20)
	game.hud.show()
	var evidence = game.get_node("PoliceDetective_evidence")
	game.shop_panel.hide_dialogue()
	evidence.offered = true
	evidence.start_game()
	await shot("find-start", 60)
	var clue: Dictionary = evidence.round.clues[0]
	evidence._on_tool(str(clue.tool))
	await shot("find-tool", 120)
	var target := int(evidence.round.target)
	evidence.choose((target + 1) % evidence.round.candidates.size())
	await shot("find-wrong", 20)
	evidence.choose(target)
	await shot("find-right", 30)
	evidence.next_round()
	await shot("report-start", 40)
	# The translate bubble: the clue, the answer buttons and the tools show their translation.
	evidence.card.toggle_translation()
	await shot("report-translated", 10)
	evidence.card.toggle_translation()
	var report: Dictionary = evidence.round
	var right := 0 if str(report.options[0].id) == str(report.clues[0].id) else 1
	evidence.answer(1 - right)
	await shot("report-wrong", 70)
	evidence.answer(right)
	await shot("report-right", 30)
	# Rounds 3 and 4, a tool per round so every tool's icons are seen once, then the summary.
	for k in 2:
		evidence.next_round()
		await process_frame
		var tools := ["squeeze", "touch", "lift"].filter(func(t): return t != str(clue.tool))
		evidence._on_tool(str(tools[k]))
		await shot("tool-%s" % tools[k], 120)
		if evidence.round.has("options"):
			evidence.answer(0 if str(evidence.round.options[0].id) == str(evidence.round.clues[0].id) else 1)
		else:
			evidence.choose(int(evidence.round.target))
	evidence.next_round()
	await shot("summary", 20)
	print("POLICE EVIDENCE CAPTURE done")
	quit()
