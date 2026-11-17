extends SceneTree
## Evidence for the big clay animals' walking rigs (elephant, giraffe, lion; 16 Nov 2026; record
## in notes.md beside this file). Modelled on docs/evidence/pig-anim-20261116/capture.gd. Loads
## only each species' display and rigged scenes, never the town. Per species <s>:
##   <s>-compare.png  display (top) and rig at rest (bottom), 4 views, studio light; the pixel
##                    difference goes into report.json
##   <s>-seams.png    neck, hips and the species' own joint (trunk, neck chain, mane) close up at
##                    both extremes of the swing with the head turned each way
##   <s>-walk.png     8 frames of one walk cycle from the side (+ 4 from the front 3/4), on a
##                    ground plane; the lowest skinned vertex per frame goes into report.json
##   <s>-blink.png    eyes open, half, shut (plush_life.gd's set_eyes_open)
##   <s>-idle.png     6 frames 0.6 s apart standing (trunk sway, ear fan, breathing, tail)
## Writes only into this folder. Run with an isolated HOME and a time limit (the window must be
## drawn):
##   godot --path . --resolution 1000x700 --script res://docs/evidence/big-anim-20261116/capture.gd [-- elephant giraffe lion]
const OUT := "res://docs/evidence/big-anim-20261116/"
const W := 520
const H := 400
const PlushLife := preload("res://scripts/characters/plush_life.gd")

## centre and size: whole-animal framing; face: eye close-up centre and size; seams: [target,
## view direction, size] close-ups.
const SPECIES := {
	"elephant": {"display": "res://scenes/animals/elephant_clay.tscn", "rig": "res://scenes/animals/elephant_clay_rigged.scn",
		"centre": Vector3(0, 1.55, -0.1), "size": 4.6, "face": [Vector3(0, 2.35, -1.3), 1.4],
		"seams": [[Vector3(0, 2.1, -0.9), Vector3(-1, 0.15, 0.1), 2.2], [Vector3(0, 1.4, 0.9), Vector3(-1, 0.1, 0.2), 2.2],
			[Vector3(0, 1.6, -1.5), Vector3(-0.6, 0.2, -1), 2.2], [Vector3(0, 2.2, -0.4), Vector3(0.6, 1.0, -0.4), 3.2],
			[Vector3(0, 1.2, -0.2), Vector3(-0.8, -0.35, 0.5), 3.2]]},
	"giraffe": {"display": "res://scenes/animals/giraffe_clay.tscn", "rig": "res://scenes/animals/giraffe_clay_rigged.scn",
		"centre": Vector3(0, 2.2, -0.3), "size": 5.2, "face": [Vector3(0, 3.75, -1.45), 1.3],
		"seams": [[Vector3(0, 3.0, -0.9), Vector3(-1, 0.15, 0.1), 2.4], [Vector3(0, 1.3, 0.6), Vector3(-1, 0.1, 0.2), 1.6],
			[Vector3(0, 3.0, -0.8), Vector3(-0.3, 0.3, -1), 2.4], [Vector3(0, 2.8, -0.5), Vector3(0.6, 1.0, -0.4), 3.2],
			[Vector3(0, 1.2, 0.0), Vector3(-0.8, -0.35, 0.5), 2.4]]},
	"lion": {"display": "res://scenes/animals/lion_clay.scn", "rig": "res://scenes/animals/lion_clay_rigged.scn",
		"centre": Vector3(0, 0.95, 0.0), "size": 3.4, "face": [Vector3(0, 1.3, -1.25), 1.0],
		"seams": [[Vector3(0, 1.1, -0.7), Vector3(-1, 0.15, 0.1), 1.6], [Vector3(0, 0.6, 0.7), Vector3(-1, 0.1, 0.2), 1.5],
			[Vector3(0, 1.1, -0.7), Vector3(-0.5, 0.3, -1), 2.0], [Vector3(0, 1.1, -0.3), Vector3(0.6, 1.0, -0.4), 2.4],
			[Vector3(0, 0.6, -0.2), Vector3(-0.8, -0.35, 0.5), 2.4]]},
}

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
	cam.position = target + dir.normalized() * 20.0
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


## Lowest point of the skinned clay in the current pose (model units), computed on the CPU from
## the skin's binds and the skeleton's pose (every 3rd vertex).
func lowest(rig: Node3D) -> float:
	var skeleton: Skeleton3D = rig.get_node("Skeleton3D")
	var low := INF
	for mi: MeshInstance3D in skeleton.get_children().filter(func(n): return n is MeshInstance3D):
		var arrays := mi.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var ids: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var ws: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var mats := []
		for b in mi.skin.get_bind_count():
			var bone := skeleton.find_bone(mi.skin.get_bind_name(b))
			mats.append(skeleton.get_bone_global_pose(bone) * mi.skin.get_bind_pose(b))
		for v in range(0, verts.size(), 3):
			var p := Vector3.ZERO
			for k in 4:
				var w := ws[v * 4 + k]
				if w > 0.0:
					p += (mats[ids[v * 4 + k]] as Transform3D) * verts[v] * w
			low = minf(low, p.y)
	return low


func run() -> void:
	root.size = Vector2i(1000, 700)
	DisplayServer.window_set_size(Vector2i(1000, 700))
	var names: Array = OS.get_cmdline_user_args()
	if names.is_empty():
		names = SPECIES.keys()
	var report := {}
	var old := FileAccess.get_file_as_string(OUT + "report.json")
	if old != "":
		report = JSON.parse_string(old)
	for s in names:
		report[s] = await species(s, SPECIES[s])
		print("BIG ANIM ", s, " ", JSON.stringify(report[s]))
	var f := FileAccess.open(OUT + "report.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	f.close()
	print("BIG ANIM REPORT done")
	quit()


func species(s: String, cfg: Dictionary) -> Dictionary:
	var out := {}
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
	var original: Node3D = load(cfg.display).instantiate()
	stage.add_child(original)
	var rigged: Node3D = load(cfg.rig).instantiate()
	stage.add_child(rigged)
	var anim = rigged.get_node("ClayAnimator")
	anim.set_process(false)
	var skeleton: Skeleton3D = rigged.get_node("Skeleton3D")
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(12, 12)
	ground.mesh = plane
	var grass := StandardMaterial3D.new()
	grass.albedo_color = Color("c9dcb0")
	ground.material_override = grass
	stage.add_child(ground)
	ground.hide()
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.far = 60.0
	stage.add_child(cam)
	cam.current = true
	for lamp in [[Vector3(-58, -20, 0), 0.9], [Vector3(-8, 30, 0), 0.22]]:
		var light := DirectionalLight3D.new()
		light.rotation_degrees = lamp[0]
		light.light_energy = lamp[1]
		cam.add_child(light)
	for i in range(30): await process_frame
	var centre: Vector3 = cfg.centre
	var size: float = cfg.size
	# compare: rest pose against the display.
	skeleton.reset_bone_poses()
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
	sheet([top, bottom], s + "-compare.png")
	out["rest_difference"] = diffs
	out["rest_lowest"] = snappedf(lowest(rigged), 0.0001)
	original.hide()
	ground.show()
	# walk: one cycle from the side (walking toward the left of the picture), then 3/4.
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
	var row2 := []
	for k in 4:
		anim.phase = k / 4.0 + 0.125
		anim.advance(0.0)
		aim(centre, Vector3(-0.7, 0.2, -0.7), size)
		row2.append(tile(await shot()))
	sheet([row.slice(0, 4), row.slice(4, 8), row2], s + "-walk.png")
	out["walk_lowest"] = lows
	# seams: extreme swing (phase 0.25 and 0.75) with the head turned each way.
	var seams := []
	for p in [0.25, 0.75]:
		anim.phase = p
		anim.look(90.0 if p < 0.5 else -90.0, 100.0)
		anim.set("_yaw", anim.get("_yaw_goal"))
		anim.advance(0.0)
		var r := []
		for c in cfg.seams:
			aim(c[0], c[1], c[2])
			r.append(tile(await shot()))
		seams.append(r)
	sheet(seams, s + "-seams.png")
	# idle: 6 frames 0.6 s apart, front 3/4 and side.
	anim.speed_override = 0.0
	anim.speed = 0.0
	anim.walk = 0.0
	anim.look(0.0, 100.0)
	anim.set("_yaw", 0.0)
	var idle := [[], []]
	for k in 6:
		anim.advance(0.6)
		aim(centre, Vector3(-0.72, 0.12, -0.69), size)
		idle[0].append(tile(await shot()))
		aim(centre, Vector3(-1, 0.08, 0), size)
		idle[1].append(tile(await shot()))
	sheet(idle, s + "-idle.png")
	# blink: open, half, shut; front and 3/4.
	ground.hide()
	skeleton.reset_bone_poses()
	var blink := [[], []]
	for open in [1.0, 0.5, 0.0]:
		PlushLife.set_eyes_open(rigged, open)
		aim(cfg.face[0], Vector3(0, 0.02, -1), cfg.face[1])
		blink[0].append(tile(await shot()))
		aim(cfg.face[0], Vector3(-0.72, 0.05, -0.69), cfg.face[1])
		blink[1].append(tile(await shot()))
	PlushLife.set_eyes_open(rigged, 1.0)
	sheet(blink, s + "-blink.png")
	stage.queue_free()
	for i in 3: await process_frame
	return out
