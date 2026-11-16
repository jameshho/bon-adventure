extends SceneTree
## Standalone views of the three shared door components (docs/guides/DOORS.md): writes
## docs/evidence/doors-20261113/components.png (closed) and components-open.png. Graphical run:
##   godot --path . --resolution 1400x800 --script res://docs/evidence/doors-20261113/components.gd
const Door := preload("res://scenes/props/door.tscn")
const Double := preload("res://scenes/props/double_door.tscn")
const Sliding := preload("res://scenes/props/sliding_door.tscn")
var doors: Array = []

func wall(root: Node3D, x0: float, x1: float, y0: float, y1: float) -> void:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(x1 - x0, y1 - y0, 0.2)
	m.mesh = b
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("d9d2c3")
	m.material_override = mat
	m.position = Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, 0)
	root.add_child(m)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var root := Node3D.new()
	get_root().add_child(root)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("aac4d6")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.6, 0.6, 0.6)
	root.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	root.add_child(sun)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20, 8)
	floor_mesh.mesh = plane
	root.add_child(floor_mesh)
	# Openings: hinged 0.9 at x -3, double 1.6 at x 0, sliding 1.0 at x 3.2, glass hinged at x 6
	var specs := [[Door, -3.0, 0.9, {}], [Double, 0.0, 1.6, {"leaf_color": Color("6f8f9e")}], [Sliding, 3.2, 1.0, {"leaf_color": Color("b5c9bc")}], [Door, 6.0, 0.9, {"vision_glass": true, "hinge": 1, "sign": 2}]]
	var x := -5.0
	for s in specs:
		var cx: float = s[1]
		var w: float = s[2]
		wall(root, x, cx - w * 0.5, 0, 2.6)
		wall(root, cx - w * 0.5, cx + w * 0.5, 2.1, 2.6)
		x = cx + w * 0.5
		var d: Node3D = s[0].instantiate()
		d.set("width", w)
		for k in s[3]: d.set(k, s[3][k])
		d.position = Vector3(cx, 0, 0)
		root.add_child(d)
		doors.append(d)
	wall(root, x, 8.0, 0, 2.6)
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.look_at_from_position(Vector3(1.5, 1.6, 6.5), Vector3(1.5, 1.1, 0))
	cam.current = true
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("res://docs/evidence/doors-20261113/components.png")
	# Open every leaf as the animator would.
	for d in doors:
		for leaf in d.leaves():
			var st: Dictionary = leaf.get_meta("door_state")
			if st.type == "hinge": leaf.rotation.y = st.angle
			else: leaf.position += st.shift * 0.6
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("res://docs/evidence/doors-20261113/components-open.png")
	quit()
