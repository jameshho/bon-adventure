extends SceneTree
## Shops polish views (23 Nov 2026): electronics products 20% bigger and the small appliances as
## words, the café's table meals redrawn. Needs a window; writes <prefix>-<view>.png into this
## folder (overwrites them).
##   HOME=<scratch>/home VT_FOCUS=electronics,bakery VT_SPAWN=none godot --path . --resolution 1200x800 \
##     --script res://docs/evidence/shops-polish-20261123/capture.gd -- prefix=after
const FOLDER := "res://docs/evidence/shops-polish-20261123/"

func _initialize(): run.call_deferred()

func settle(frames: int) -> void:
	for i in range(frames):
		await process_frame

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	var prefix := "view"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("prefix="):
			prefix = arg.split("=")[1]
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await settle(5)
	game.player.set_physics_process(false)
	game.player.visible = false
	game.interaction.set_physics_process(false)
	game.day_night.pause()
	game.day_night.set_time(12 * 60)
	game.hud.hide()
	var camera := Camera3D.new()
	camera.near = 0.05
	camera.fov = 60.0
	game.add_child(camera)
	camera.current = true
	# [frame, name, eye, target] in the building's own frame.
	var store: Node3D = game.apartment.get_node("Buildings/ElectronicsStore")
	var cafe: Node3D = game.apartment.get_node("Buildings/BakeryCafe")
	for spec in [
		[store, "electronics-entrance", Vector3(0, 1.7, -7.3), Vector3(0, 1.1, 6)],
		[store, "electronics-computers", Vector3(-.6, 1.75, -3.4), Vector3(-2.6, 1.0, -3.4)],
		[store, "electronics-phones", Vector3(-.7, 1.7, .8), Vector3(-2.6, 1.05, 1.6)],
		[store, "electronics-cameras", Vector3(.6, 1.75, -1.4), Vector3(2.6, 1.0, -1.0)],
		[store, "electronics-appliances", Vector3(3.0, 1.55, .2), Vector3(5.4, 1.0, 0)],
		[store, "electronics-gaming", Vector3(-3.0, 1.7, 5.0), Vector3(-5.3, 1.0, 6.0)],
		[store, "electronics-counter", Vector3(2.4, 1.8, 3.6), Vector3(4.0, 1.0, 5.9)],
		[cafe, "cafe-left-tables", Vector3(-1.4, 1.75, -9.6), Vector3(-3.6, .8, -4.6)],
		[cafe, "cafe-breakfast", Vector3(-2.7, 1.45, -8.0), Vector3(-3.7, .8, -8.0)],
		[cafe, "cafe-lunch", Vector3(-2.7, 1.45, -4.6), Vector3(-3.7, .8, -4.6)],
		[cafe, "cafe-dinner", Vector3(-2.7, 1.45, -1.2), Vector3(-3.7, .8, -1.2)],
		[cafe, "cafe-right-tables", Vector3(1.3, 1.75, -10.0), Vector3(3.6, .8, -5.0)],
		[cafe, "cafe-food", Vector3(2.5, 1.45, -8.4), Vector3(3.6, .8, -8.4)],
		[cafe, "cafe-coffee", Vector3(2.6, 1.4, -5.0), Vector3(3.6, .82, -5.0)],
	]:
		var frame: Node3D = spec[0]
		camera.global_position = frame.to_global(spec[2])
		camera.look_at(frame.to_global(spec[3]))
		await settle(10)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(FOLDER + prefix + "-" + spec[1] + ".png"))
	print("SHOPS CAPTURE done")
	quit(0)
