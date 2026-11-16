extends SceneTree
## Stage 4a view (4 Nov 2026): the new mothers_side tree in the family panel. Graphics
## required, isolated HOME (Main saves progress):
## HOME=<scratch>/home2 VT_FOCUS=hospital godot --path . --resolution 1600x1000 --script res://docs/evidence/chinese-kinship-20261104/capture.gd
func _initialize(): run.call_deferred()

func run():
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	await process_frame
	var family = game.get_node("FamilySession")
	game.player.global_position = family.doctor.global_position - family.doctor.global_basis.z * 3.0
	family._process(.1)
	for attempt in 30:
		family.open_game()
		if family.tree.template_id == "mothers_side":
			break
		family.panel.hide_panel()
	for i in range(10): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/chinese-kinship-20261104/mothers-side-tree.png")
	print("KINSHIP CAPTURE done ", family.tree.template_id)
	quit()
