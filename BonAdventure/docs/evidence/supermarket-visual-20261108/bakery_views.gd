extends SceneTree
## Café fridge and bread rack with the reused product models (8 Nov 2026); graphics required.
## HOME=<scratch> VT_FOCUS=bakery godot --path . --resolution 1000x700 --script res://docs/evidence/supermarket-visual-20261108/bakery_views.gd -- res://docs/evidence/supermarket-visual-20261108
## Writes fridge.png and rack.png into the given folder (renamed props-bakery-*.png in the record).
func _initialize(): run.call_deferred()
func run():
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	game.hud.hide()
	await process_frame
	var cam := Camera3D.new()
	game.add_child(cam)
	cam.current = true
	cam.fov = 50
	var out: String = OS.get_cmdline_user_args()[0]
	for v in [["fridge", Vector3(189.9, 1.5, 208.4), Vector3(191.76, 1.2, 208.5)], ["rack", Vector3(190.1, 1.2, 210.5), Vector3(191.9, .55, 210.2)]]:
		cam.global_position = v[1]
		cam.look_at(v[2])
		for i in 8: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out + "/" + v[0] + ".png")
	quit()
