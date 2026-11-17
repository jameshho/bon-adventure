extends SceneTree
## Evidence for the rigged clay cow, zebra, deer and rhino (16 Nov 2026; notes.md in this folder).
## Loads only each species' display and rig, never the town. Per species <p>:
##   <p>-compare.png  display (top) and rig at rest (bottom), studio light, 4 views; the pixel
##                    difference is printed and saved in report.json
##   <p>-seams.png    neck and hips close up at both extremes of the swing with the head turned
##                    (rows: phase 0.25 + head left, phase 0.75 + head right; side, rear 3/4,
##                    above, below)
##   <p>-walk.png     8 frames of one walk cycle, side view, then 4 from the front 3/4
##   <p>-blink.png    the face: eyes open, half, shut (plush_life.gd's set_eyes_open)
##   report.json      pixel differences, triangle counts, and the lowest point of the skinned
##                    mesh (CPU skinning) at rest and over the walk cycle (ground check)
## Writes only into this folder. Run with an isolated HOME and a time limit:
##   godot --path . --resolution 1000x700 --script res://docs/evidence/hoofed-anim-20261116/capture.gd [-- cow zebra]
const OUT := "res://docs/evidence/hoofed-anim-20261116/"
const W := 520
const H := 400
const PlushLife := preload("res://scripts/characters/plush_life.gd")
const SPECIES := ["cow", "zebra", "deer", "rhino"]

var cam: Camera3D


func _initialize() -> void:
	run.call_deferred()


func shot() -> Image:
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	return img


func aim(target: Vector3, dir: Vector3, size: float) -> void:
	cam.size = size
	cam.position = target + dir.normalized() * 14.0
	cam.look_at(target)


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


## Mean colour difference (0-255) over the pixels either image covers, and the share of those
## pixels that differ by more than 8 levels in any channel.
func difference(a: Image, b: Image, bg: Color) -> Array:
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


func _near(c: Color, bg: Color) -> bool:
	return absf(c.r - bg.r) + absf(c.g - bg.g) + absf(c.b - bg.b) < 0.02


## Lowest y of the skinned meshes in the current pose (CPU skinning), model space.
func lowest(rigged: Node3D) -> float:
	var skeleton: Skeleton3D = rigged.get_node("Skeleton3D")
	var low := INF
	for mi: MeshInstance3D in skeleton.get_children().filter(func(c): return c is MeshInstance3D):
		var skin := mi.skin
		var mats := []
		for b in skin.get_bind_count():
			mats.append(skeleton.get_bone_global_pose(skeleton.find_bone(skin.get_bind_name(b))) * skin.get_bind_pose(b))
		var arrays := mi.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		for v in verts.size():
			var y := 0.0
			for k in 4:
				var w := weights[v * 4 + k]
				if w > 0.0:
					y += w * ((mats[bones[v * 4 + k]] as Transform3D) * verts[v]).y
			low = minf(low, y)
	return low


func run() -> void:
	root.size = Vector2i(1000, 700)
	DisplayServer.window_set_size(Vector2i(1000, 700))
	var wanted := OS.get_cmdline_user_args()
	var report := {}
	var old := FileAccess.get_file_as_string(OUT + "report.json")
	if old != "":
		report = JSON.parse_string(old)
	for p in SPECIES:
		if wanted.is_empty() or wanted.has(p):
			report[p] = await species(p)
			print("HOOFED ", p, " ", JSON.stringify(report[p]))
	var f := FileAccess.open(OUT + "report.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	f.close()
	print("HOOFED ANIM REPORT DONE")
	quit()


## Studio views (the light of docs/evidence/pig-anim-20261116/capture.gd).
func species(p: String) -> Dictionary:
	var result := {}
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	var bg := Color("fdf0e9")
	env.environment.background_color = bg
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("fff4e6")
	env.environment.ambient_light_energy = 0.6
	stage.add_child(env)
	var original: Node3D = load("res://scenes/animals/%s_clay.tscn" % p).instantiate()
	stage.add_child(original)
	var rigged: Node3D = load("res://scenes/animals/%s_clay_rigged.scn" % p).instantiate()
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
	for i in range(30): await process_frame
	# Framing from the display's bounds and the rig's bones.
	var box: AABB = rigged.get_meta("anim_aabb").grow(-0.15)
	var centre := box.get_center()
	var size := maxf(box.size.z, box.size.y) * 1.12
	var neck := skeleton.get_bone_global_rest(skeleton.find_bone("head")).origin
	var hips := (skeleton.get_bone_global_rest(skeleton.find_bone("leg_bl")).origin + skeleton.get_bone_global_rest(skeleton.find_bone("leg_br")).origin) * 0.5
	hips.x = 0.0
	neck.x = 0.0
	var eyes: Vector3 = (rigged.get_node("Head/LeftEye").global_position + rigged.get_node("Head/RightEye").global_position) * 0.5
	var tris := 0
	for mi: MeshInstance3D in rigged.find_children("*", "MeshInstance3D", true, false):
		tris += mi.mesh.get_faces().size() / 3
	var shown := 0
	for mi: MeshInstance3D in original.find_children("*", "MeshInstance3D", true, false):
		shown += mi.mesh.get_faces().size() / 3
	result["triangles"] = {"rig": tris, "display": shown}
	result["skinned_surfaces"] = skeleton.get_children().filter(func(c): return c is MeshInstance3D).size()
	# compare.png: rest pose against the display.
	skeleton.reset_bone_poses()
	result["lowest_rest"] = snappedf(lowest(rigged), 0.0001)
	var views := [Vector3(-0.72, 0.12, -0.69), Vector3(0, 0.1, -1), Vector3(-1, 0.08, 0), Vector3(0.7, 0.14, 0.7)]
	var top := []
	var bottom := []
	var diffs := []
	for v in views:
		aim(centre, v, size)
		rigged.hide()
		original.show()
		var a: Image = await shot()
		original.hide()
		rigged.show()
		var b: Image = await shot()
		diffs.append(difference(a, b, bg))
		top.append(tile(a))
		bottom.append(tile(b))
	sheet([top, bottom], p + "-compare.png")
	result["rest_difference"] = diffs
	original.hide()
	# walk.png: one cycle, side view (the animal walks toward the left of the picture).
	anim.speed_override = 0.6
	anim.speed = 0.6
	anim.walk = 1.0
	var row := []
	var lows := []
	for k in 8:
		anim.phase = k / 8.0
		anim.advance(0.0)
		lows.append(snappedf(lowest(rigged), 0.0001))
		aim(centre, Vector3(-1, 0.08, 0), size)
		row.append(tile(await shot()))
	result["lowest_walk"] = lows
	var row2 := []
	for k in 4:
		anim.phase = k / 4.0 + 0.125
		anim.advance(0.0)
		aim(centre, Vector3(-0.7, 0.2, -0.7), size)
		row2.append(tile(await shot()))
	sheet([row.slice(0, 4), row.slice(4, 8), row2], p + "-walk.png")
	# seams.png: extreme swing with the head turned; neck and hips close up.
	var near := box.size.y * 0.62
	var seams := []
	for ph in [0.25, 0.75]:
		anim.phase = ph
		var turn: float = anim.head_turn_deg if ph < 0.5 else -anim.head_turn_deg
		anim.look(turn, 100.0)
		anim.set("_yaw", anim.get("_yaw_goal"))
		anim.advance(0.0)
		var r := []
		aim(neck, Vector3(-1, 0.15, 0.1), near)
		r.append(tile(await shot()))
		aim(neck, Vector3(0.5, 0.35, -0.8), near)
		r.append(tile(await shot()))
		aim(hips, Vector3(-1, 0.1, 0.2), near)
		r.append(tile(await shot()))
		aim(hips, Vector3(0.6, -0.3, 0.75), near)
		r.append(tile(await shot()))
		aim(centre, Vector3(0.6, 1.0, -0.4), size)
		r.append(tile(await shot()))
		aim(centre + Vector3(0, -box.size.y * 0.15, 0), Vector3(-0.8, -0.35, 0.5), size)
		r.append(tile(await shot()))
		seams.append(r)
	sheet(seams, p + "-seams.png")
	# blink.png: open, half, shut; front and 3/4, standing.
	anim.speed_override = 0.0
	anim.speed = 0.0
	anim.walk = 0.0
	anim.look(0.0, 100.0)
	anim.set("_yaw", 0.0)
	skeleton.reset_bone_poses()
	var blink := [[], []]
	var face := box.size.y * 0.3
	for open in [1.0, 0.5, 0.0]:
		PlushLife.set_eyes_open(rigged, open)
		aim(eyes, Vector3(0, 0.02, -1), face)
		blink[0].append(tile(await shot()))
		aim(eyes, Vector3(-0.72, 0.05, -0.69), face)
		blink[1].append(tile(await shot()))
	PlushLife.set_eyes_open(rigged, 1.0)
	sheet(blink, p + "-blink.png")
	stage.queue_free()
	await process_frame
	return result
