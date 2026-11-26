extends SceneTree
## Animal gait (improvement plan ANIM-02, 25 Nov 2026): the clay pig in the zoo is sent to a target
## behind it and filmed from above with a fixed camera. turn.png shows 8 frames 0.2 s apart (60 fps
## fixed steps): it should turn on the spot first, then ease into its walk, never crab-walk.
## Prints yaw, heading error, pace and distance moved per frame.
## Isolated HOME, full town, windowed:
##   HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --fixed-fps 60 --path . --script res://docs/evidence/animal-gait-20261125/turn.gd -- <folder>

func _initialize() -> void:
	run.call_deferred()

func shot() -> Image:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func run() -> void:
	var folder: String = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(folder)
	# A covered window stops drawing on macOS (frame_post_draw never comes).
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	root.size = Vector2i(900, 600)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(40): await process_frame
	game.day_night.pause()
	game.day_night.set_time(12 * 60.0)
	game.player.set_physics_process(false)
	game.player.set_process(false)
	game.interaction.set_physics_process(false)
	game.player.get_node("Visual").hide()
	for layer in game.find_children("*", "CanvasLayer", true, false): layer.hide()
	var zoo: Node3D = game.apartment.get_node("ParkZoo")
	var pig: Node3D = zoo.get_node("Pig")
	print("GAIT: interpolation mode %d (off = %d)" % [pig.physics_interpolation_mode, Node.PHYSICS_INTERPOLATION_MODE_OFF])
	var cam := Camera3D.new()
	game.add_child(cam)
	cam.current = true
	cam.fov = 40
	var height: float = (pig.get_meta("display_size") as Vector3).y * zoo.global_basis.get_scale().y
	# Stand it at home, facing +Z (local), and send it to a point straight behind it.
	pig.set("state", "idle")
	pig.set("_timer", 99.0)
	for i in range(5): await process_frame
	pig.position = pig.get("home")
	pig.rotation.y = 0.0
	var radius: float = pig.get("radius")
	var target: Vector3 = pig.position - Vector3(0, 0, radius * 0.8)
	var anim: Node = pig.get_node_or_null("ClayPig/ClayAnimator")
	cam.global_position = pig.global_position + Vector3.UP * height * 5.0 + pig.global_basis.x.normalized() * height * 3.0
	cam.look_at(zoo.to_global(pig.position.lerp(target, 0.4)) + Vector3.UP * height * 0.3)
	for i in range(3): await process_frame
	pig.set("target", target)
	pig.set("state", "walking")
	pig.set("_timer", 8.0)
	pig.set("_direction", (target - pig.position).normalized())
	pig.set("_probe_timer", 0.0)
	pig.set("_pace", 0.0)
	var frames: Array[Image] = []
	var last: Vector3 = pig.position
	for i in range(8):
		var img: Image = await shot()
		frames.append(img)
		var yaw: float = pig.rotation.y
		var goal := atan2(target.x - pig.position.x, target.z - pig.position.z)
		print("GAIT frame %d: state %s yaw %.0f° error %.0f° pace %.3f moved %.3f walk %s" % [i, pig.get("state"), rad_to_deg(yaw), rad_to_deg(absf(angle_difference(yaw, goal))), pig.get("_pace"), pig.position.distance_to(last), "-" if anim == null else "%.2f" % anim.get("walk")])
		last = pig.position
		for f in range(12): await process_frame
	var w := frames[0].get_width() / 2
	var h := frames[0].get_height() / 2
	var strip := Image.create(w * 4, h * 2, false, frames[0].get_format())
	for i in frames.size():
		var f := frames[i]
		f.resize(w, h)
		strip.blit_rect(f, Rect2i(0, 0, w, h), Vector2i((i % 4) * w, (i / 4) * h))
	strip.save_png(folder.path_join("turn.png"))
	game.free()
	quit()
