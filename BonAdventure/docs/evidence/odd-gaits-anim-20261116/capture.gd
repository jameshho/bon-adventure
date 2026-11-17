extends SceneTree
## Evidence for the clay gorilla, kangaroo, duck and flamingo walking rigs (16 Nov 2026; notes in
## notes.md beside this file). Loads only these animals' display and rigged scenes and the pig's
## rigged scene, never the town. Per species (<s> = gorilla, kangaroo, duck, flamingo):
##   <s>-compare.png  original display (top) and the rigged animal at rest (bottom), studio
##                    light, 4 views; the pixel difference is in report.json
##   <s>-seams.png    close-ups (upper body and neck, legs from the side, from above, from
##                    below) at both extremes of the gait with the head turned
##   <s>-walk.png     8 frames of one walk or hop cycle from the side, 4 from the front 3/4
##   <s>-blink.png    the face: eyes open, half, shut (plush_life.gd's set_eyes_open)
##   pig-walk.png     the rigged pig's walk re-rendered exactly as pig-anim-20261116/capture.gd
##                    did; report.json compares it with that folder's walk.png. The exact check
##                    that the new gait options leave the pig as it was is pig_check.gd.
## Writes only into this folder. Run with an isolated HOME (the window must be drawn):
##   godot --path . --resolution 1000x700 --script res://docs/evidence/odd-gaits-anim-20261116/capture.gd [-- duck ...]
const OUT := "res://docs/evidence/odd-gaits-anim-20261116/"
const W := 520
const H := 400
const PlushLife := preload("res://scripts/characters/plush_life.gd")
const SPECIES := ["gorilla", "kangaroo", "duck", "flamingo"]
## Gait phases shown in the seams sheet (the two extremes of each gait).
const SEAM_PHASES := {"gorilla": [0.0, 0.5], "kangaroo": [0.0, 0.5], "duck": [0.25, 0.75], "flamingo": [0.25, 0.75]}

var cam: Camera3D
var bg := Color("fdf0e9")


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
	var wanted := []
	for a in OS.get_cmdline_user_args():
		if a in SPECIES or a == "pig": wanted.append(a)
	if wanted.is_empty():
		wanted = SPECIES + ["pig"]
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
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	stage.add_child(cam)
	cam.current = true
	for lamp in [[Vector3(-58, -20, 0), 0.9], [Vector3(-8, 30, 0), 0.22]]:
		var light := DirectionalLight3D.new()
		light.rotation_degrees = lamp[0]
		light.light_energy = lamp[1]
		cam.add_child(light)
	for s in wanted:
		if s == "pig":
			report["pig_walk_vs_pilot"] = await pig(stage)
		else:
			report[s] = await species(stage, s)
		print("ODD GAITS ", s, " ", JSON.stringify(report.get(s, report.get("pig_walk_vs_pilot"))))
	var f := FileAccess.open(OUT + "report.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	f.close()
	print("ODD GAITS REPORT done")
	quit()


func _bounds(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mi: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = mi.global_transform * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


func species(stage: Node3D, s: String) -> Dictionary:
	var result := {}
	var original: Node3D = load("res://scenes/animals/%s_clay.tscn" % s).instantiate()
	stage.add_child(original)
	var rigged: Node3D = load("res://scenes/animals/%s_clay_rigged.scn" % s).instantiate()
	stage.add_child(rigged)
	var anim = rigged.get_node("ClayAnimator")
	anim.set_process(false)
	var skeleton: Skeleton3D = rigged.get_node("Skeleton3D")
	for i in range(30): await process_frame
	var box := _bounds(original)
	var size := maxf(box.size.y, box.size.z) * 1.12
	var mid := box.get_center()
	var h := box.size.y
	# compare.png: rest pose against the display.
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
	sheet([top, bottom], "%s-compare.png" % s)
	result["rest_difference"] = diffs
	original.hide()
	# walk.png: one cycle from the side (walking toward the left of the picture), then 4 from
	# the front 3/4. The ground line is drawn by a thin plate at y = 0.
	var ground := MeshInstance3D.new()
	var plate := BoxMesh.new()
	plate.size = Vector3(box.size.x * 3.0, 0.002, box.size.z * 3.0)
	ground.mesh = plate
	ground.position = Vector3(mid.x, -0.001, mid.z)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("c9b8a8")
	ground.material_override = mat
	stage.add_child(ground)
	anim.speed_override = 1.0
	anim.speed = 1.0
	anim.walk = 1.0
	var row := []
	for k in 8:
		anim.phase = k / 8.0
		anim.advance(0.0)
		aim(mid + Vector3(0, h * 0.05, 0), Vector3(-1, 0.04, 0), size * 1.1)
		row.append(tile(await shot()))
	var row2 := []
	for k in 4:
		anim.phase = k / 4.0 + 0.125
		anim.advance(0.0)
		aim(mid + Vector3(0, h * 0.05, 0), Vector3(-0.7, 0.2, -0.7), size * 1.1)
		row2.append(tile(await shot()))
	sheet([row.slice(0, 4), row.slice(4, 8), row2], "%s-walk.png" % s)
	# Feet against the ground over the cycle: the lowest point of the skinned mesh.
	var lows := []
	for k in 16:
		anim.phase = k / 16.0
		anim.advance(0.0)
		lows.append(snappedf(_lowest(skeleton), 0.0001))
	result["lowest_y_over_cycle"] = lows
	# seams.png: both extremes of the gait with the head turned; upper body and legs close up
	# from the side, the back from above, the belly and legs from below.
	ground.hide()
	var seams := []
	var turn: float = anim.head_turn_deg
	for p in SEAM_PHASES[s]:
		anim.phase = p
		anim.look(turn if p < 0.4 else -turn, 100.0)
		anim.set("_yaw", anim.get("_yaw_goal"))
		anim.advance(0.0)
		var r := []
		aim(mid + Vector3(0, h * 0.2, -box.size.z * 0.15), Vector3(-1, 0.15, -0.2), size * 0.62)
		r.append(tile(await shot()))
		aim(mid + Vector3(0, -h * 0.25, 0), Vector3(-1, 0.1, 0.25), size * 0.62)
		r.append(tile(await shot()))
		aim(mid + Vector3(0, h * 0.1, 0), Vector3(0.5, 1.0, 0.3), size * 0.9)
		r.append(tile(await shot()))
		aim(mid + Vector3(0, -h * 0.15, 0), Vector3(-0.8, -0.35, 0.5), size * 0.9)
		r.append(tile(await shot()))
		seams.append(r)
	sheet(seams, "%s-seams.png" % s)
	ground.queue_free()
	# blink.png: open, half, shut; front and 3/4 (rest pose).
	anim.speed_override = 0.0
	anim.speed = 0.0
	anim.walk = 0.0
	anim.phase = 0.0
	anim.look(0.0, 100.0)
	anim.set("_yaw", 0.0)
	skeleton.reset_bone_poses()
	var le: Node3D = rigged.get_node("Head/LeftEye")
	var re: Node3D = rigged.get_node("Head/RightEye")
	var eyes := (le.global_position + re.global_position) * 0.5
	var span := le.global_position.distance_to(re.global_position)
	var blink := [[], []]
	for open in [1.0, 0.5, 0.0]:
		PlushLife.set_eyes_open(rigged, open)
		aim(eyes, Vector3(0, 0.02, -1), span * 3.2)
		blink[0].append(tile(await shot()))
		aim(eyes, Vector3(-0.72, 0.05, -0.69), span * 3.2)
		blink[1].append(tile(await shot()))
	PlushLife.set_eyes_open(rigged, 1.0)
	sheet(blink, "%s-blink.png" % s)
	result["eyes"] = {"left": str(le.position), "right": str(re.position)}
	original.queue_free()
	rigged.queue_free()
	await process_frame
	return result


## Lowest y of the skinned surfaces in the current pose (CPU skinning of the rest vertices).
func _lowest(skeleton: Skeleton3D) -> float:
	var low := INF
	for mi: MeshInstance3D in skeleton.get_children():
		if not mi is MeshInstance3D: continue
		var arrays := mi.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var pose := []
		for b in skeleton.get_bone_count():
			pose.append(skeleton.get_bone_global_pose(b) * mi.skin.get_bind_pose(b))   # binds follow the bone order
		for v in verts.size():
			var p := Vector3.ZERO
			for k in 4:
				var w := weights[v * 4 + k]
				if w > 0.0:
					p += (pose[bones[v * 4 + k]] * verts[v]) * w
			low = minf(low, p.y)
	return low


## The pig's walk exactly as docs/evidence/pig-anim-20261116/capture.gd rendered it (same
## light, camera, speed 0.6 and phases), compared tile by tile with that folder's walk.png.
func pig(stage: Node3D) -> Dictionary:
	var rigged: Node3D = load("res://scenes/animals/pig_clay_rigged.scn").instantiate()
	stage.add_child(rigged)
	var anim = rigged.get_node("ClayAnimator")
	anim.set_process(false)
	for i in range(60): await process_frame
	anim.speed_override = 0.6
	anim.speed = 0.6
	anim.walk = 1.0
	var row := []
	var pilot := Image.load_from_file(ProjectSettings.globalize_path("res://docs/evidence/pig-anim-20261116/walk.png"))
	pilot.convert(Image.FORMAT_RGBA8)
	var diffs := []
	for k in 8:
		anim.phase = k / 8.0
		anim.advance(0.0)
		aim(Vector3(0, 0.47, 0), Vector3(-1, 0.08, 0), 1.36)
		var t := tile(await shot())
		row.append(t)
		var then := pilot.get_region(Rect2i((k % 4) * W, (k / 4) * H, W, H))
		diffs.append(difference(then, t))
	sheet([row.slice(0, 4), row.slice(4, 8)], "pig-walk.png")
	var result := {"tile_difference_vs_pilot_walk_png": diffs,
			"note": "pig_check.gd compares the bone poses with the animator before the change"}
	rigged.queue_free()
	await process_frame
	return result
