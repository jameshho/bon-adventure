extends SceneTree
## Electronics store makeover views (18 Nov 2026, docs/guides/TOWN_DESIGN_BRIEF.md "Electronics store
## makeover"). Needs a window; writes <prefix>-<view>.png into this folder (overwrites them).
##   HOME=<scratch>/home VT_FOCUS=electronics VT_SPAWN=none godot --path . --resolution 1200x800 \
##     --script res://docs/evidence/electronics-makeover-20261118/capture.gd -- prefix=before [apply]
## `apply`: run the unit's steps that are not baked yet at load (a preview before the bake).
const FOLDER := "res://docs/evidence/electronics-makeover-20261118/"

var args := {}

func _initialize(): run.call_deferred()

func settle(frames: int) -> void:
	for i in range(frames):
		await process_frame

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	for arg in OS.get_cmdline_user_args():
		var kv := arg.split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var prefix: String = args.get("prefix", "view")
	var game = load("res://scenes/main.tscn").instantiate()
	if args.has("apply"):
		game.set_meta("editing_snapshot", true)
	root.add_child(game)
	if args.has("apply"):
		var script = load("res://scripts/buildings/electronics.gd").new()
		var store0: Node3D = game.apartment.get_node("Buildings/ElectronicsStore")
		var done: Array = store0.get_meta("applied_steps", []) if store0.has_meta("applied_steps") else []
		for step in script.STEPS:
			if step in args.get("steps", "").split(","):
				script.call(step, game.apartment, game)
		pass
	await settle(5)
	game.player.set_physics_process(false)
	game.player.visible = false
	game.interaction.set_physics_process(false)
	game.day_night.pause()
	game.day_night.set_time(12 * 60)
	game.hud.hide()
	var store: Node3D = game.apartment.get_node("Buildings/ElectronicsStore")
	var camera := Camera3D.new()
	camera.near = 0.05
	camera.fov = 65.0
	game.add_child(camera)
	camera.current = true
	# [name, eye, target] in the store frame: door gap on -Z (z=-7.6), rear wall z=+7.6.
	for spec in [
		["entrance", Vector3(0, 1.7, -7.3), Vector3(0, 1.1, 6)],
		["left", Vector3(1.8, 2.0, -4.5), Vector3(-5.6, 1.0, 0.5)],
		["right", Vector3(-1.8, 2.0, -4.5), Vector3(5.6, 1.0, 0.5)],
		["rear", Vector3(0, 2.2, 5.6), Vector3(0, 1.0, -7.6)],
		["counter", Vector3(-1.5, 1.8, 2.0), Vector3(4.6, 1.0, 6.4)],
		["phones", Vector3(-0.9, 1.7, 0.6), Vector3(-2.6, 1.1, 1.9)],
		["overview", Vector3(4.9, 4.6, -7.2), Vector3(-2.5, 0, 3.5)],
		["overview-rear", Vector3(-4.9, 4.6, 7.2), Vector3(2.5, 0, -3.5)],
	]:
		camera.global_position = store.to_global(spec[1])
		camera.look_at(store.to_global(spec[2]))
		await settle(10)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(FOLDER + prefix + "-" + spec[0] + ".png"))
	print("ELECTRONICS CAPTURE done")
	quit(0)
