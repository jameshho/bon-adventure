extends SceneTree
## Renders the player as a pig in each long-sleeved outfit, from behind and above like the follow
## camera, and from the side (21 Nov 2026: the arm showed through a dark outfit's sleeves).
## Run windowed: Godot --path . --script docs/evidence/outfit-sleeves-20261121/render.gd -- [tag]
const Costume := preload("res://scripts/characters/plush_costume.gd")
const OUT := "res://docs/evidence/outfit-sleeves-20261121/"
const OUTFITS := ["waiter", "chef", "police", "pilot"]

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var tag: String = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "before"
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.85, 0.72, 0.5)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.8, 0.8, 0.8)
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	world.add_child(sun)
	var player: Node3D = load("res://scenes/player/bonbon_player.tscn").instantiate()
	world.add_child(player)
	player.set_physics_process(false)
	player.set_process(false)
	player.set_avatar(load("res://scenes/characters/pig_plush.tscn"))
	await process_frame
	var model: Node3D = player.get_node("Visual/BonBon")
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.fov = 40
	var centre := model.global_position + Vector3.UP * 0.9 * model.global_basis.get_scale().y
	var back := model.global_basis.z.normalized()
	var side := model.global_basis.x.normalized()
	for outfit in OUTFITS:
		Costume.dress_player(player, outfit)
		for i in 4:
			await process_frame
		for view in ["back", "side"]:
			var dir: Vector3 = (back * 1.0 + Vector3.UP * 1.4).normalized() if view == "back" else (side + Vector3.UP * 0.3).normalized()
			cam.global_position = centre + dir * 4.2
			cam.look_at(centre, Vector3.UP)
			cam.make_current()
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "%s-%s-%s.png" % [tag, outfit, view]))
	print("RENDERED ", OUTFITS.size())
	quit()
