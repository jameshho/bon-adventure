extends SceneTree
## Plays both police games with REAL input events (Input.parse_input_event): walk up to the
## officer, aim with the mouse, press E, click the dialogue's Play button, click suspects /
## tools / objects / answer buttons on screen (a click on a suspect or an object is the
## answer; the evidence game since 8 Nov 2026: a tool button, an object, then a report
## round's answer button). Graphics required; isolated user directory.
## godot --path . --resolution 1280x800 --script res://docs/evidence/police-detective-20261106/play_input.gd
const Interior := preload("res://scripts/buildings/police.gd")
var game

func _initialize() -> void:
	run.call_deferred()

func say(text: String) -> void:
	print("PLAY: ", text)

func frames(n: int) -> void:
	for i in n:
		await process_frame

func move_mouse(at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	Input.parse_input_event(motion)
	Input.warp_mouse(at)
	await frames(3)

func click(at: Vector2) -> void:
	await move_mouse(at)
	for pressed in [true, false]:
		var button := InputEventMouseButton.new()
		button.button_index = MOUSE_BUTTON_LEFT
		button.pressed = pressed
		button.position = at
		button.global_position = at
		Input.parse_input_event(button)
		await frames(2)
	await frames(4)

func key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await frames(2)
	await frames(4)

func center(control: Control) -> Vector2:
	return control.get_global_rect().get_center()

func screen_of(point: Vector3) -> Vector2:
	return root.get_viewport().get_camera_3d().unproject_position(point)

## Walk the player to `spot` (design coords), turned toward `npc`, mouse on its body.
func approach(station: Node3D, spot: Vector3, npc: Node3D) -> void:
	game.player.global_position = station.to_global(Interior.mirror_point(spot)) + Vector3(0, .1, 0)
	game.player.velocity = Vector3.ZERO
	var look: Vector3 = npc.global_position - game.player.global_position
	var yaw := atan2(-look.x, -look.z)
	game.player.rotation.y = yaw
	game.player.camera_yaw = yaw
	game.player.reset_camera()
	await frames(30)
	var box := AABB()
	var first := true
	for mesh in npc.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = mesh.global_transform * mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	var counter: Node3D = station.find_child("Evidence counter top", true, false)
	say("%s top y %.2f, bottom %.2f; counter top y %.2f" % [npc.name, box.end.y, box.position.y, counter.global_position.y if counter else -1.0])
	# Let the follow camera settle, then aim at the visible body: above the evidence counter,
	# below the "!" marker.
	await frames(60)
	await aim(npc, counter)
	var hit: Dictionary = game.interaction.aimed_hit()
	say("ray hits: %s" % (hit.collider.get_path() if not hit.is_empty() else "nothing"))
	say("aimed object: %s (officer %s), distance %.2f" % [game.interaction.aimed_object(), npc.name, game.player.global_position.distance_to(npc.global_position)])

func aim(npc: Node3D, counter: Node3D) -> void:
	var aim_y: float = maxf(npc.global_position.y + 1.0, (counter.global_position.y + .3) if counter else 0.0)
	await move_mouse(screen_of(Vector3(npc.global_position.x, aim_y, npc.global_position.z)))

func play(session, station: Node3D, spot: Vector3, label: String) -> void:
	var npc: Node3D = session.officer
	await approach(station, spot, npc)
	say("%s offered=%s near=%s" % [label, session.offered, session.host._near])
	await aim(npc, station.find_child("Evidence counter top", true, false))
	await key(KEY_E)
	var panel = game.shop_panel
	say("after E: dialogue visible=%s line='%s' has_choices=%s" % [panel.is_dialogue_visible(), session.host.line_id, panel.has_choices()])
	# Click the first choice button (Play).
	var buttons: Array = panel.dialogue_card.find_children("*", "Button", true, false).filter(func(b): return b.is_visible_in_tree() and b.text != "")
	say("dialogue buttons: %s" % [buttons.map(func(b): return b.text)])
	if not buttons.is_empty():
		await click(center(buttons[0]))
	await frames(60)
	var card = game.detective_card
	say("after Play: running=%s card visible=%s camera is game camera=%s controls=%s" % [session._running, card.visible, root.get_viewport().get_camera_3d() == session._camera, game.player.controls_enabled])
	if not session._running:
		return
	await root.get_texture().get_image().save_png("res://docs/evidence/police-detective-20261106/input-%s-start.png" % label)
	var target := int(session.round.target)
	var node: Node3D = session._nodes[target]
	if label == "evidence":
		# Redesigned 8 Nov 2026: the round's tool examines every object; a click on one answers.
		var tool: Button = card._tool_buttons.get(str(session.round.clues[0].tool))
		await click(center(tool))
		await frames(100)
		say("tool after clicking %s: %s; badges: %d" % [tool.text, session._tool, session._nodes.filter(func(n): return n.has_node("Badge")).size()])
		await root.get_texture().get_image().save_png("res://docs/evidence/police-detective-20261106/input-evidence-tool.png")
	var at := screen_of(node.global_position + Vector3(0, .25 if label == "evidence" else 1.0, 0))
	await click(at)
	say("clicked candidate %d at %s: solved=%s feedback='%s' accuse button visible=%s" % [target, at, session._solved, card.feedback_label.text, card.accuse_button.visible])
	await root.get_texture().get_image().save_png("res://docs/evidence/police-detective-20261106/input-%s-answer.png" % label)
	if session._solved:
		await click(center(card.next_button))
		await frames(10)
		say("after Next: new round built=%s, card shows round 2=%s" % [not session.round.is_empty(), card.title_label.text.contains("2")])
		if label == "evidence" and session.round.has("options"):
			# Round 2 is a report round: answer with the right button.
			var right := 0 if str(session.round.options[0].id) == str(session.round.clues[0].id) else 1
			await frames(30)
			await root.get_texture().get_image().save_png("res://docs/evidence/police-detective-20261106/input-evidence-report.png")
			await click(center(card._choice_buttons[right]))
			await frames(30)
			say("clicked answer %d of a report round: solved=%s feedback='%s'" % [right, session._solved, card.feedback_label.text])
			await root.get_texture().get_image().save_png("res://docs/evidence/police-detective-20261106/input-evidence-report-answer.png")
	await key(KEY_ESCAPE)
	say("after Esc: quit open=%s" % panel.is_quit_open())
	panel.quit_answered.emit(true)
	await frames(60)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(30)
	var station: Node3D = game.apartment.get_node("RelocatedSites/Police")
	var lineup = game.get_node("PoliceDetective_lineup")
	var evidence = game.get_node("PoliceDetective_evidence")
	await play(lineup, station, Interior.LINEUP_OFFICER_SPOT + Vector3(0, 0, -1.6), "lineup")
	await play(evidence, station, Interior.EVIDENCE_OFFICER_SPOT + Vector3(2.4, 0, 0), "evidence")
	say("done")
	quit()
