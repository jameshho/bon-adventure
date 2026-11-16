extends SceneTree
## Compares, at their peak, the old face-group gestures (the "Head" node turned about the
## character's feet) with whole-body gestures (docs/guides/COMPONENTS.md). Graphical run:
##   godot --path . --resolution 1750x800 --script res://docs/evidence/plush-rig-20261113/gestures.gd
## Writes docs/evidence/plush-rig-20261113/gestures.png. Columns: rest | old shake, nod, tilt | body
## shake, nod, tilt. Rows: pig, golden retriever.
const SCENES := ["pig_plush", "golden_plush"]
## [target ("" rest, "head" or "body"), axis, angle]
const POSES := [["", Vector3.UP, 0.0],
	["head", Vector3.UP, 0.18], ["head", Vector3.RIGHT, 0.14], ["head", Vector3.BACK, 0.16],
	["body", Vector3.UP, 0.18], ["body", Vector3.RIGHT, -0.09], ["body", Vector3.BACK, 0.09]]

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var root := Node3D.new()
	get_root().add_child(root)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("cfd8dc")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.7, 0.7)
	root.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 200, 0)
	root.add_child(sun)
	for row in SCENES.size():
		for col in POSES.size():
			var plush: Node3D = load("res://scenes/characters/%s.tscn" % SCENES[row]).instantiate()
			root.add_child(plush)
			# Turned a little so a nod reads from the camera.
			plush.transform = Transform3D(Basis(Vector3.UP, 0.45), Vector3(-(col - 3) * 2.6, -row * 3.6, 0))
			var pose: Array = POSES[col]
			var turn := Basis(pose[1], pose[2])
			if pose[0] == "head":
				(plush.get_node("Head") as Node3D).basis = turn
			elif pose[0] == "body":
				plush.basis = plush.basis * turn
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 8.6
	root.add_child(cam)
	cam.look_at_from_position(Vector3(0, -0.6, -20), Vector3(0, -0.6, 0))
	cam.current = true
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("res://docs/evidence/plush-rig-20261113/gestures.png")
	quit()
