extends SceneTree
## Evidence for the clay tiger's rig (17 Nov 2026; tools/build_tiger_clay_rig.gd), after
## docs/evidence/bears-dog-anim-20261116/capture.gd. Loads only the tiger's display and rig
## scenes, never the town. Into this folder:
##   tiger_clay-compare.png  display (top) and rig at rest (bottom), studio light, 4 views; the
##                           pixel difference is printed and saved in report.json
##   tiger_clay-weights.png  each vertex coloured by its bones (rest, and the walk's extreme with
##                           the head turned): where the skin bends
##   tiger_clay-seams.png    neck and hips close up at both extremes of the swing, head turned
##   tiger_clay-walk.png     8 frames of one walk cycle from the side on a ground plane, then 4
##                           from the front 3/4
##   tiger_clay-tail.png     walking, from above and behind, 8 frames 0.08 s apart: tail and ears
##   tiger_clay-blink.png    the face: eyes open, half, shut (plush_life.gd's set_eyes_open)
## Run with an isolated HOME; frames are drawn on demand, so a covered window does not stall it:
##   godot --path . --resolution 1000x700 --script res://docs/evidence/tiger-anim-20261117/capture.gd
## It quits when done.
const OUT := "res://docs/evidence/tiger-anim-20261117/"
const W := 480
const H := 360
const PlushLife := preload("res://scripts/characters/plush_life.gd")
const ANIMALS := ["tiger_clay"]
const BONE_COLOURS := [Color("9a9a9a"), Color("4f8fe0"), Color("f2c14e"), Color("e05a8a"), Color("3fbf7f"),
		Color("e0743a"), Color("8a5be0"), Color("3fc6d8"), Color("b6d84a"), Color("ff8fd0"), Color("7a4a2a"), Color("ffffff")]

var cam: Camera3D
var bg := Color("fdf0e9")


func _initialize() -> void:
	run.call_deferred()


func shot() -> Image:
	for i in range(3): await process_frame
	for i in range(2): RenderingServer.force_draw(false)
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	return img


func aim(target: Vector3, dir: Vector3, size: float) -> void:
	cam.size = size
	cam.position = target + dir.normalized() * 14.0
	cam.look_at(target, Vector3.UP if absf(dir.normalized().y) < 0.95 else Vector3.FORWARD)


func tile(img: Image) -> Image:
	var out := img.duplicate() as Image
	out.resize(W, H, Image.INTERPOLATE_LANCZOS)
	return out


func sheet(rows: Array, file: String) -> void:
	var cols := 0
	for r in rows: cols = maxi(cols, r.size())
	var img := Image.create(W * cols, H * rows.size(), false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	for y in rows.size():
		for x in rows[y].size():
			img.blit_rect(rows[y][x], Rect2i(0, 0, W, H), Vector2i(x * W, y * H))
	img.save_png(OUT + file)


func difference(a: Image, b: Image) -> Array:
	var total := 0.0
	var counted := 0
	var off := 0
	for y in range(0, a.get_height(), 2):
		for x in range(0, a.get_width(), 2):
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			if _near(ca, bg) and _near(cb, bg): continue
			counted += 1
			var d := maxf(absf(ca.r - cb.r), maxf(absf(ca.g - cb.g), absf(ca.b - cb.b))) * 255.0
			total += d
			if d > 8.0: off += 1
	return [snappedf(total / maxi(counted, 1), 0.01), snappedf(float(off) / maxi(counted, 1), 0.0001)]


func _near(c: Color, b: Color) -> bool:
	return absf(c.r - b.r) + absf(c.g - b.g) + absf(c.b - b.b) < 0.02


func run() -> void:
	root.size = Vector2i(1000, 700)
	DisplayServer.window_set_size(Vector2i(1000, 700))
	var report := {}
	var old := FileAccess.get_file_as_string(OUT + "report.json")
	if old != "":
		report = JSON.parse_string(old)
	var which: Array = OS.get_cmdline_user_args()
	if which.is_empty():
		which = ANIMALS
	for prefab in which:
		report[prefab] = await animal(prefab)
		print("ANIM ", prefab, " ", JSON.stringify(report[prefab]))
	var f := FileAccess.open(OUT + "report.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	f.close()
	print("TIGER ANIM REPORT done")
	quit()


func animal(prefab: String) -> Dictionary:
	var result := {}
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = bg
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("fff4e6")
	env.environment.ambient_light_energy = 0.6
	stage.add_child(env)
	var original: Node3D = load("res://scenes/animals/%s.tscn" % prefab).instantiate()
	stage.add_child(original)
	var rigged: Node3D = load("res://scenes/animals/%s_rigged.scn" % prefab).instantiate()
	stage.add_child(rigged)
	var anim = rigged.get_node("ClayAnimator")
	anim.set_process(false)
	var skeleton: Skeleton3D = rigged.get_node("Skeleton3D")
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	stage.add_child(cam)
	cam.current = true
	for lamp in [[Vector3(-58, -20, 0), 0.9], [Vector3(-8, 30, 0), 0.22]]:
		var light := DirectionalLight3D.new()
		light.rotation_degrees = lamp[0]
		light.light_energy = lamp[1]
		cam.add_child(light)
	var box := AABB()
	for mi: MeshInstance3D in original.find_children("*", "MeshInstance3D", true, false):
		box = mi.get_aabb() if box.size == Vector3.ZERO else box.merge(mi.get_aabb())
	var mid := box.get_center()
	var size := maxf(box.size.y, box.size.z) * 1.3
	var head := Vector3(0, box.end.y * 0.7, box.position.z + box.size.z * 0.25)
	var hips := Vector3(0, box.end.y * 0.35, box.end.z - box.size.z * 0.3)
	for i in range(30): await process_frame
	# Compare: rest pose against the display.
	skeleton.reset_bone_poses()
	var views := [Vector3(-0.72, 0.12, -0.69), Vector3(0, 0.1, -1), Vector3(-1, 0.08, 0), Vector3(0.7, 0.14, 0.7)]
	var top := []
	var bottom := []
	var diffs := []
	for v in views:
		aim(mid, v, size)
		rigged.hide()
		original.show()
		var a: Image = await shot()
		original.hide()
		rigged.show()
		var b: Image = await shot()
		diffs.append(difference(a, b))
		top.append(tile(a))
		bottom.append(tile(b))
	sheet([top, bottom], prefab + "-compare.png")
	result["rest_difference"] = diffs
	original.hide()
	# Walk: one cycle, side view on a ground plane (feet must not sink), then front 3/4.
	var ground := MeshInstance3D.new()
	var plane := BoxMesh.new()
	plane.size = Vector3(8, 0.02, 8)
	ground.mesh = plane
	ground.position.y = -0.01
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color("9fb08a")
	ground.material_override = gm
	stage.add_child(ground)
	anim.speed_override = 0.6
	anim.speed = 0.6
	anim.walk = 1.0
	var row := []
	for k in 8:
		anim.phase = k / 8.0
		anim.advance(0.0)
		aim(mid, Vector3(-1, 0.02, 0), size)
		row.append(tile(await shot()))
	var row2 := []
	for k in 4:
		anim.phase = k / 4.0 + 0.125
		anim.advance(0.0)
		aim(mid, Vector3(-0.7, 0.2, -0.7), size)
		row2.append(tile(await shot()))
	sheet([row.slice(0, 4), row.slice(4, 8), row2], prefab + "-walk.png")
	ground.queue_free()
	# Seams: extreme swing (phase 0.25 and 0.75) with the head turned; neck and hips close up
	# from the side, from above the back and from below.
	var seams := []
	for p in [0.25, 0.75]:
		anim.phase = p
		anim.look(24.0 if p < 0.5 else -24.0, 100.0)
		anim.set("_yaw", anim.get("_yaw_goal"))
		anim.advance(0.0)
		var r := []
		aim(head, Vector3(-1, 0.15, 0.1), size * 0.6)
		r.append(tile(await shot()))
		aim(hips, Vector3(-1, 0.1, 0.2), size * 0.6)
		r.append(tile(await shot()))
		aim(mid, Vector3(0.6, 1.0, -0.4), size * 0.9)
		r.append(tile(await shot()))
		aim(Vector3(mid.x, box.end.y * 0.3, mid.z), Vector3(-0.8, -0.35, 0.5), size * 0.9)
		r.append(tile(await shot()))
		seams.append(r)
	sheet(seams, prefab + "-seams.png")
	# Tail and ears: walking, seen from above and behind, 8 frames 0.08 s apart (the wag runs on
	# the animator's clock, the legs on the phase).
	anim.look(0.0, 100.0)
	anim.set("_yaw", 0.0)
	var tail := []
	for k in 8:
		anim.phase = k / 8.0
		anim.advance(0.08)
		aim(mid, Vector3(0.35, 1.0, 0.75), size)
		tail.append(tile(await shot()))
	sheet([tail.slice(0, 4), tail.slice(4, 8)], prefab + "-tail.png")
	# Blink: open, half, shut; front and 3/4.
	anim.speed_override = 0.0
	anim.speed = 0.0
	anim.walk = 0.0
	anim.look(0.0, 100.0)
	anim.set("_yaw", 0.0)
	skeleton.reset_bone_poses()
	var face := Vector3(0, box.end.y * 0.72, box.position.z + box.size.z * 0.15)
	var blink := [[], []]
	for open in [1.0, 0.5, 0.0]:
		PlushLife.set_eyes_open(rigged, open)
		aim(face, Vector3(0, 0.05, -1), size * 0.45)
		blink[0].append(tile(await shot()))
		aim(face, Vector3(-0.72, 0.05, -0.69), size * 0.45)
		blink[1].append(tile(await shot()))
	PlushLife.set_eyes_open(rigged, 1.0)
	sheet(blink, prefab + "-blink.png")
	result["eyes"] = rigged.has_node("Head/LeftEye") and rigged.has_node("Head/RightEye")
	# Weights: every vertex coloured by its bones (BONE_COLOURS in bone order).
	var legend := []
	for i in skeleton.get_bone_count():
		legend.append("%s=%s" % [skeleton.get_bone_name(i), BONE_COLOURS[i % BONE_COLOURS.size()].to_html(false)])
	result["weight_colours"] = " ".join(legend)
	for mi: MeshInstance3D in skeleton.get_children():
		var arrays := mi.mesh.surface_get_arrays(0)
		var ids: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var ws: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var cols := PackedColorArray()
		for v in (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size():
			var c := Color(0, 0, 0)
			for k in 4:
				c += BONE_COLOURS[ids[v * 4 + k] % BONE_COLOURS.size()] * ws[v * 4 + k]
			cols.append(c)
		arrays[Mesh.ARRAY_COLOR] = cols
		var m := ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mi.mesh = m
		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mi.material_override = mat
	var wrows := [[], []]
	for pose in 2:
		if pose == 1:
			anim.speed_override = 0.6
			anim.speed = 0.6
			anim.walk = 1.0
			anim.phase = 0.25
			anim.look(24.0, 100.0)
			anim.set("_yaw", anim.get("_yaw_goal"))
			anim.advance(0.0)
		for v in [Vector3(-1, 0.08, 0), Vector3(-0.72, 0.12, -0.69), Vector3(0.6, 1.0, -0.4), Vector3(0.7, -0.3, 0.6)]:
			aim(mid, v, size)
			wrows[pose].append(tile(await shot()))
	sheet(wrows, prefab + "-weights.png")
	stage.queue_free()
	await process_frame
	return result
