extends SceneTree
## EXPERIMENT (18 Nov 2026): character showcase for the shared-rig experiment (rig.gd). Loads only
## the nine plush scenes, never the town; writes PNGs and report.json into OUT.
##   godot --path . --resolution 960x540 --script res://docs/evidence/character-rig-20261118/showcase.gd -- <set>
## <set> is "baseline" (the production sculpts, typed costume anchors) or "experiment" (VARIANTS
## and the measured anchors). Run with VT_SCULPT_CACHE=0 VT_MESH_SHARE=0 and an isolated HOME,
## so nothing is read from or written to the sculpt cache or the learner's saves.
## Lineups use an orthographic camera (no perspective), the same ground, light and spacing, and
## the characters at their in-game scale (1.0, as avatars and house characters use them).

const OUT := "res://docs/evidence/character-rig-20261118/"
const Rig := preload("res://docs/evidence/character-rig-20261118/rig.gd")
const ExpCostume := preload("res://docs/evidence/character-rig-20261118/exp_costume.gd")
const COSTUME_DATA := "res://data/plush_costumes.json"
## Primary references first, then the four to bring closer to them.
const CAST := [
	["BonBon", "res://scenes/characters/pig_plush.tscn"],
	["Leo", "res://scenes/characters/lion_plush.tscn"],
	["Bruno", "res://scenes/characters/bear_plush.tscn"],
	["Sam", "res://scenes/characters/samoyed_plush.tscn"],
	["Cocodrilo", "res://scenes/characters/crocodile_plush.tscn"],
	["Poppy", "res://scenes/characters/sheep_plush.tscn"],
	["Miso", "res://scenes/characters/cat_plush.tscn"],
	["Sunny", "res://scenes/characters/golden_plush.tscn"],
	["Twinkle", "res://scenes/characters/beagle_plush.tscn"],
]
## Experimental sculpt per name (extends the production script; production files untouched).
const VARIANTS := {
	"Poppy": "res://docs/evidence/character-rig-20261118/variants/poppy.gd",
	"Miso": "res://docs/evidence/character-rig-20261118/variants/miso.gd",
	"Sunny": "res://docs/evidence/character-rig-20261118/variants/sunny.gd",
	"Twinkle": "res://docs/evidence/character-rig-20261118/variants/twinkle.gd",
}
## The prototype costume: one basic T-shirt and one simple cap, the same pieces for everyone.
const TEE := {"piece": "shirt", "color": "4f8fd8", "sleeve": 0.32, "bottom": 0.5}
const HAT := {"piece": "cap", "color": "e0603c", "band": "c24a2c", "visor": "c24a2c", "badge": "fafafa"}
const SPACING := 2.45
const TILE := Vector2i(400, 640)
const BG := Color("e8e6e1")

var mode := "baseline"
var vp: SubViewport
var cam: Camera3D
var stage: Node3D
var costume_data: Dictionary
var report := {}


func _initialize() -> void:
	run.call_deferred()


func shot() -> Image:
	for i in range(3):
		await process_frame
	RenderingServer.force_draw(false)
	await process_frame
	RenderingServer.force_draw(false)
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	return img


func setup_world(size: Vector2i) -> void:
	vp = SubViewport.new()
	vp.size = size
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	stage = Node3D.new()
	vp.add_child(stage)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BG
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.85, 0.85)
	var we := WorldEnvironment.new()
	we.environment = env
	stage.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-62, 25, 0)
	sun.shadow_enabled = true
	sun.light_energy = 1.0
	stage.add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(80, 80)
	ground.mesh = plane
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color("d6d3cc")
	gm.roughness = 1.0
	ground.material_override = gm
	stage.add_child(ground)
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.near = 0.1
	cam.far = 200
	stage.add_child(cam)
	cam.current = true


## Orthographic camera on `target`, looking along -`from` (horizontal, slightly from above).
func aim(target: Vector3, from: Vector3, height: float) -> void:
	cam.size = height
	cam.position = target + from.normalized() * 40.0
	cam.look_at(target, Vector3.UP)


func make_figure(entry: Array) -> Node3D:
	var figure: Node3D = load(entry[1]).instantiate()
	if mode == "experiment" and VARIANTS.has(entry[0]):
		var keep := {}
		for prop in figure.get_property_list():
			if prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
				keep[prop["name"]] = figure.get(prop["name"])
		figure.set_script(load(VARIANTS[entry[0]]))
		for k in keep:
			figure.set(k, keep[k])
	return figure


func species_key(entry: Array) -> String:
	return str(entry[1]).get_file().get_basename()


## A walker: Visual (bobs) > figure, as the player is built.
func place(entry: Array, at: Vector3, yaw := 0.0) -> Node3D:
	var visual := Node3D.new()
	visual.name = "Walker" + entry[0]
	visual.position = at
	visual.rotation.y = yaw
	visual.set_meta("spawned", true)
	stage.add_child(visual)
	var figure := make_figure(entry)
	figure.name = entry[0]
	visual.add_child(figure)
	return figure


func label(text: String, at: Vector3) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = 64
	l.pixel_size = 0.0042
	l.outline_size = 0
	l.modulate = Color("3a3631")
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.position = at
	l.set_meta("spawned", true)
	stage.add_child(l)
	return l


func clear_stage() -> void:
	for child in stage.get_children():
		if child.has_meta("spawned"):
			child.free()


func dress(figure: Node3D, entry: Array, profile: Dictionary) -> Node3D:
	var c: Node3D = ExpCostume.new()
	c.name = "Costume"
	c.pieces = [TEE, HAT]
	if mode == "experiment":
		var fitted := Rig.fit(costume_data["species"].get(species_key(entry), {}), profile)
		c.anchors = {"shoulder": fitted["shoulder"], "hand": fitted["hand"]}
	figure.add_child(c)
	return c


## The nine in a row, figure i at x = (4 - i) * SPACING, so the front camera (at -Z) shows
## BonBon on the left. Returns the figures.
func lineup(yaw := 0.0, dressed := false) -> Array:
	clear_stage()
	var figures := []
	for i in CAST.size():
		var x := (4 - i) * SPACING
		figures.append(place(CAST[i], Vector3(x, 0, 0), yaw))
	for i in range(3):
		await process_frame
	for i in CAST.size():
		var fig: Node3D = figures[i]
		var collar := float(costume_data["species"].get(species_key(CAST[i]), {}).get("collar_y", 1.25))
		var profile := Rig.measure(fig, collar)
		fig.set_meta("profile", profile)
		if dressed:
			var c := dress(fig, CAST[i], profile)
	for i in range(3):
		await process_frame
	return figures


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		mode = arg
	costume_data = JSON.parse_string(FileAccess.get_file_as_string(COSTUME_DATA))
	if mode == "walk":
		await walk_compare()
		quit()
		return
	var width := TILE.x * CAST.size()
	setup_world(Vector2i(width, TILE.y))
	var view_h := float(TILE.y) / float(width) * SPACING * CAST.size()
	var centre := Vector3(0, view_h * 0.5 - 0.75, 0)

	# 1 front, 2 back, 3 side.
	var figures := await lineup()
	for i in CAST.size():
		label(CAST[i][0], Vector3((4 - i) * SPACING, -0.42, -1.2))
	record(figures)
	aim(centre, Vector3(0, 0.08, -1), view_h)
	(await shot()).save_png(OUT + mode + "-1-front.png")
	for l in stage.get_children():
		if l is Label3D:
			l.position.z = 1.2
	aim(centre, Vector3(0, 0.08, 1), view_h)
	(await shot()).save_png(OUT + mode + "-2-back.png")
	# Side: each turned a quarter in place, all facing screen right.
	figures = await lineup(PI * 0.5)
	for i in CAST.size():
		label(CAST[i][0], Vector3((4 - i) * SPACING, -0.42, -1.2))
	aim(centre, Vector3(0, 0.08, -1), view_h)
	(await shot()).save_png(OUT + mode + "-3-side.png")
	# 4 costume: front and three-quarter back.
	figures = await lineup(0.0, true)
	for i in CAST.size():
		label(CAST[i][0], Vector3((4 - i) * SPACING, -0.42, -1.2))
	aim(centre, Vector3(0, 0.08, -1), view_h)
	(await shot()).save_png(OUT + mode + "-4-costume.png")
	figures = await lineup(PI * 0.5, true)
	for i in CAST.size():
		label(CAST[i][0], Vector3((4 - i) * SPACING, -0.42, -1.2))
	aim(centre, Vector3(0, 0.08, -1), view_h)
	(await shot()).save_png(OUT + mode + "-4-costume-side.png")
	# Costume, mid-stride (arms at the swing's peak), so sleeves can be seen following.
	figures = await lineup(0.6, true)
	for i in CAST.size():
		label(CAST[i][0], Vector3((4 - i) * SPACING, -0.42, -1.2))
	for i in CAST.size():
		var fig: Node3D = figures[i]
		var profile: Dictionary = fig.get_meta("profile")
		var rest := Rig.rest_poses(fig)
		if mode == "experiment":
			Rig.attach_sleeves(fig, fig.get_node("Costume"), rest)
		Rig.walk(fig.get_parent(), fig, rest, PI * 0.5, 1.0, profile if mode == "experiment" else null)
	aim(centre, Vector3(0.0, 0.08, -1), view_h)
	(await shot()).save_png(OUT + mode + "-4-costume-stride.png")
	# Close-ups of the same stride, one tile per character from the front three-quarter, so
	# sleeves, collars and the cap's seat can be judged.
	var tiles := Image.create(TILE.x * CAST.size(), TILE.x, false, Image.FORMAT_RGBA8)
	for i in CAST.size():
		for j in CAST.size():
			figures[j].get_parent().visible = i == j
		aim(Vector3((4 - i) * SPACING, 1.25, 0), Vector3(-0.35, 0.18, -1.0), 2.7)
		var img := await shot()
		var crop := img.get_region(Rect2i((img.get_width() - img.get_height()) / 2, 0, img.get_height(), img.get_height()))
		crop.resize(TILE.x, TILE.x, Image.INTERPOLATE_LANCZOS)
		tiles.blit_rect(crop, Rect2i(Vector2i.ZERO, crop.get_size()), Vector2i(i * TILE.x, 0))
	tiles.save_png(OUT + mode + "-4-costume-closeup.png")
	var f := FileAccess.open(OUT + mode + "-report.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	f.close()
	print("showcase done: ", mode)
	quit()


func r3(v: Vector3) -> Array:
	return [snappedf(v.x, 0.001), snappedf(v.y, 0.001), snappedf(v.z, 0.001)]


func record(figures: Array) -> void:
	for i in CAST.size():
		var p: Dictionary = figures[i].get_meta("profile")
		var data: Dictionary = costume_data["species"].get(species_key(CAST[i]), {})
		report[CAST[i][0]] = {
			"height": snappedf(p["height"], 0.001),
			"torso_size": r3(p["torso"].size),
			"shoulder_r": r3(p["shoulder_r"]), "hand_r": r3(p["hand_r"]),
			"arm_length": snappedf(p["arm_length_r"], 0.001),
			"hip_r": r3(p["hip_r"]), "foot_size": r3(p["foot_size_r"]),
			"typed_shoulder": data.get("shoulder"), "typed_hand": data.get("hand"),
			"collar_y": data.get("collar_y"),
			"walk_pivot_error": snappedf((p["shoulder_r"] as Vector3).distance_to(Vector3(Rig.ORIGINAL_PIVOT.x, Rig.ORIGINAL_PIVOT.y, 0)), 0.001),
		}


## 5 walking comparison. For each subject, original (production sculpt, today's walk with
## BonBon's pivot) beside experimental (variant sculpt if any, measured pivots), same phase,
## speed (walk_speed 7.2: gait weight 0.6, 11.8 rad/s as animate_bonbon computes), camera and
## duration (two strides, 30 fps). Undressed rows, then a dressed row (T-shirt + cap) that also
## turns, to check that the sleeves and cap follow. Raw frames go to the folder in VT_FRAMES for
## make_gif.py; a contact sheet of every 4th frame and the pixel difference go to OUT.
## [name, dressed+turning, speed]: walk_speed 7.2, or sprint_speed 12 to show the pivot at full swing.
const WALK_SUBJECTS := [["BonBon", false, 7.2], ["Leo", false, 7.2], ["Leo", false, 12.0], ["Poppy", false, 7.2], ["Miso", true, 7.2]]
const FPS := 30.0
const FRAMES := 32
const PANEL := Vector2i(420, 460)

func entry_of(name: String) -> Array:
	for e in CAST:
		if e[0] == name:
			return e
	return []


func walk_compare() -> void:
	var frames_dir := OS.get_environment("VT_FRAMES")
	setup_world(PANEL)
	var diffs := {}
	var sheet_rows := []
	for subject in WALK_SUBJECTS:
		var entry := entry_of(subject[0])
		var dressed: bool = subject[1]
		var speed: float = subject[2]
		var tag: String = subject[0] + ("-run" if speed > 10.0 else "")
		clear_stage()
		# Both walkers stand on the same spot; each frame is drawn once per walker with the
		# other hidden, so the two panels are exactly the same view.
		var walkers := []
		var labels := []
		for k in range(2):
			mode = "baseline" if k == 0 else "experiment"
			walkers.append(place(entry, Vector3.ZERO))
			labels.append(label(subject[0] + (" running" if speed > 10.0 else "") + (" — original" if k == 0 else " — experiment"), Vector3(0, -0.55, 0)))
		for i in range(3):
			await process_frame
		var rests := []
		var profiles := []
		for k in range(2):
			mode = "baseline" if k == 0 else "experiment"
			var fig: Node3D = walkers[k]
			var collar := float(costume_data["species"].get(species_key(entry), {}).get("collar_y", 1.25))
			var profile := Rig.measure(fig, collar)
			profiles.append(profile)
			rests.append(Rig.rest_poses(fig))
			if dressed:
				dress(fig, entry, profile)
		for i in range(3):
			await process_frame
		if dressed:
			# The player has its sleeves moved onto the arms (dress_player); same for both here.
			for k in range(2):
				Rig.attach_sleeves(walkers[k], walkers[k].get_node("Costume"), rests[k])
		aim(Vector3(0, 0.95, 0), Vector3(-0.6, 0.25, -1.0), 3.3)
		var row := []
		var total := 0.0
		for f in range(FRAMES):
			var phase := f / FPS * lerpf(7.0, 15.0, speed / 12.0)
			var halves := []
			for k in range(2):
				var fig: Node3D = walkers[k]
				fig.get_parent().visible = true
				walkers[1 - k].get_parent().visible = false
				labels[k].visible = true
				labels[1 - k].visible = false
				if dressed:
					# A full turn over the clip, as the player turns when steering.
					fig.get_parent().rotation.y = TAU * f / FRAMES
				Rig.walk(fig.get_parent(), fig, rests[k], phase, speed / 12.0, null if k == 0 else profiles[k])
				halves.append(await shot())
			total += difference(halves[0], halves[1])
			var img := Image.create(PANEL.x * 2, PANEL.y, false, Image.FORMAT_RGBA8)
			img.blit_rect(halves[0], Rect2i(Vector2i.ZERO, PANEL), Vector2i.ZERO)
			img.blit_rect(halves[1], Rect2i(Vector2i.ZERO, PANEL), Vector2i(PANEL.x, 0))
			img.fill_rect(Rect2i(PANEL.x - 1, 0, 2, PANEL.y), Color("b8b3aa"))
			if frames_dir != "":
				var rgb := img.duplicate() as Image
				rgb.convert(Image.FORMAT_RGB8)
				var file := FileAccess.open(frames_dir.path_join("%s-%02d.rgb" % [tag, f]), FileAccess.WRITE)
				file.store_buffer(rgb.get_data())
				file.close()
			if f % 4 == 0:
				row.append(img)
		diffs[tag + (" dressed+turning" if dressed else "")] = snappedf(total / FRAMES, 0.0001)
		sheet_rows.append(row)
	var tw := PANEL.x
	var th := PANEL.y / 2
	var sheet := Image.create(tw * 8, th * sheet_rows.size(), false, Image.FORMAT_RGBA8)
	sheet.fill(Color.WHITE)
	for r in sheet_rows.size():
		for c in sheet_rows[r].size():
			var t := (sheet_rows[r][c] as Image).duplicate() as Image
			t.resize(tw, th, Image.INTERPOLATE_LANCZOS)
			sheet.blit_rect(t, Rect2i(Vector2i.ZERO, t.get_size()), Vector2i(c * tw, r * th))
	sheet.save_png(OUT + "5-walk-sheet.png")
	var f2 := FileAccess.open(OUT + "walk-report.json", FileAccess.WRITE)
	f2.store_string(JSON.stringify({"mean_pixel_difference_original_vs_experiment": diffs, "frames": FRAMES, "fps": FPS, "panel": [PANEL.x, PANEL.y]}, "  "))
	f2.close()
	print("walk done ", diffs)


## Mean colour difference per pixel above the label (0 identical ... 3 black vs white),\n## every 2nd pixel.
func difference(a: Image, b: Image) -> float:
	var total := 0.0
	var n := 0
	# The bottom 15 % holds the panel's label, which differs on purpose.
	for y in range(0, int(a.get_height() * 0.85), 2):
		for x in range(0, a.get_width(), 2):
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			total += absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b)
			n += 1
	return total / n
