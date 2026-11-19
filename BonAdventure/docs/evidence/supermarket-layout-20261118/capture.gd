extends SceneTree
## Views of the compact supermarket layout of 18 Nov 2026 (supermarket step compact_layout): two
## top-down plans (roof, ceiling and lights hidden; the second also without the hanging signs),
## the entrance, the cold wall, the snack and home aisles, the fruit islands, the back counters and
## the staff door. Positions are local to RelocatedSites/Supermarket. Overwrites the PNGs here.
## dev_focus.txt must list the supermarket (or read all).
## HOME=<isolated> godot --path . --resolution 1280x800 --script res://docs/evidence/supermarket-layout-20261118/capture.gd
func _initialize(): run.call_deferred()
func run():
	if DisplayServer.get_name()=="headless": quit(1); return
	var folder := "res://docs/evidence/supermarket-layout-20261118"
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	game.hud.hide()
	game.player.visible = false
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.current = true
	camera.fov = 70.0
	var market: Node3D = game.apartment.get_node("RelocatedSites/Supermarket")
	var interior: Node3D = market.get_node("MarketInterior")
	var overhead := [market.get_node("Supermarket roof"), interior.get_node("Interior ceiling finish")]
	for node in interior.get_children():
		if str(node.get_meta("word_key", "")) == "ceiling light": overhead.append(node)
	var signs := []
	for node in interior.get_children():
		if node is Node3D and (node as Node3D).position.y > 3.0 and (node as Node3D).position.y < 5.0: signs.append(node)
	# Plans: orthographic, +Z (the back) at the top of the picture.
	for node in overhead: node.visible = false
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 27.0
	camera.global_position = market.to_global(Vector3(-33, 20, 43.6))
	camera.look_at(market.to_global(Vector3(-33, 0, 43.6)), market.global_basis * Vector3(0, 0, 1))
	await shot(folder, "0a-plan-signs")
	for node in signs: node.visible = false
	await shot(folder, "0b-plan")
	for node in signs: node.visible = true
	for node in overhead: node.visible = true
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	for spec in [
		["1-entrance", Vector3(-33,2.0,34.6), Vector3(-33,1.4,45)],
		["2-cold-wall", Vector3(-27.5,2.3,36.4), Vector3(-20.8,1.3,43.5)],
		["3-cold-wall-signs", Vector3(-31,1.7,36), Vector3(-21.5,3.4,42)],
		["4-snacks-home-aisle", Vector3(-42.3,2.2,41.2), Vector3(-42.3,1.0,47.5)],
		["5-snacks-cookie-face", Vector3(-37.4,2.2,41.4), Vector3(-38.9,1.0,46.5)],
		["6-produce-islands", Vector3(-31.5,3.0,36.2), Vector3(-25.5,0.9,43.5)],
		["7-fruit-island-back", Vector3(-28.5,2.3,48.9), Vector3(-25.2,1.0,45.6)],
		["8-back-counters", Vector3(-33,2.7,45.8), Vector3(-33,1.3,53)],
		["9-staff-door", Vector3(-37.7,1.8,47.6), Vector3(-37.7,1.4,53)],
	]:
		camera.global_position = market.to_global(spec[1])
		camera.look_at(market.to_global(spec[2]))
		await shot(folder, spec[0])
	print("LAYOUT CAPTURE DONE")
	quit()

func shot(folder: String, title: String) -> void:
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder) + "/" + title + ".png")
