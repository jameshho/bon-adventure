extends SceneTree
## Form study of the clay tiger against the user's sheet (reference.png), one build stage at a
## time (tiger_clay.gd `stage`: 1 bare skull ... 6 everything). Builds the model in memory (the
## saved scene is not read or written) and renders it orthographically from the sheet's own
## angles, at the sheet's scale. For each view, top: the sheet with the model's outline in
## magenta; bottom: the model with the sheet's outline in blue. Where the lines part, the
## silhouettes differ.
##   godot --path . --script res://docs/evidence/tiger-clay-20261116/study.gd -- <stage> <head|body|paws|muzzle> <out.png>
## Views: screen x of a point = L cos(yaw) + x sin(yaw) + c in sheet px (L = toward the animal's
## left, x = true x toward the tail). Front: yaw 0; front 3/4: 29; the sheet's "side": 65 (it
## is turned 25 degrees toward the front); back: 180; rear 3/4: -132 (fitted to the figures' widths).
const REF := "res://docs/evidence/tiger-clay-20261116/reference.png"
const UNIT := 2.1 / 315.0
const BG := Color("fcefe6")
# [yaw degrees, c, rect in the sheet, y shift]
const HEAD := [[0.0, 501.0, Rect2i(385, 200, 235, 195), 0.0], [29.0, -248.7, Rect2i(20, 200, 245, 195), 2.0],
		[65.0, 74.7, Rect2i(676, 196, 215, 195), 0.0], [180.0, 1350.0, Rect2i(1235, 196, 230, 195), 0.0]]
const BODY := [[0.0, 501.0, Rect2i(380, 196, 245, 336), 0.0], [29.0, -248.7, Rect2i(15, 196, 365, 336), 2.0],
		[65.0, 74.7, Rect2i(676, 196, 520, 336), 0.0], [180.0, 1350.0, Rect2i(1230, 196, 240, 336), 0.0],
		[-132.0, 2444.0, Rect2i(1520, 196, 460, 336), 2.0]]

# Close-ups: the paws (front view, the fore and hind paws of the side view, back view) and the muzzle.
const PAWS := [[0.0, 501.0, Rect2i(385, 440, 240, 92), 0.0], [65.0, 74.7, Rect2i(765, 440, 190, 92), 0.0],
		[65.0, 74.7, Rect2i(945, 440, 190, 92), 0.0], [180.0, 1350.0, Rect2i(1238, 440, 230, 92), 0.0]]
const MUZZLE := [[0.0, 501.0, Rect2i(425, 300, 150, 80), 0.0], [29.0, -248.7, Rect2i(45, 302, 150, 80), 2.0],
		[65.0, 74.7, Rect2i(672, 300, 130, 80), 0.0]]

var sheet: Image
var SS := 3

func _initialize() -> void:
	run.call_deferred()

func at(x: float, y: float, l := 0.0) -> Vector3:
	return Vector3(-l, 523.0 - y, x - 945.0) * UNIT

func fig(x: int, y: int) -> bool:
	var c := sheet.get_pixel(clampi(x, 0, sheet.get_width() - 1), clampi(y, 0, sheet.get_height() - 1))
	return c.s > 0.2 or c.v < 0.75

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var stage := int(args[0])
	var views: Array = {"head": HEAD, "body": BODY, "paws": PAWS, "muzzle": MUZZLE}[args[1]]
	SS = 3 if args[1] in ["head", "body"] else 6
	sheet = Image.load_from_file(ProjectSettings.globalize_path(REF))
	sheet.convert(Image.FORMAT_RGBA8)
	var port := SubViewport.new()
	port.own_world_3d = true
	port.transparent_bg = true
	port.msaa_3d = Viewport.MSAA_4X
	port.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(port)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("fff4e6")
	env.environment.ambient_light_energy = 0.62
	port.add_child(env)
	var tiger = load("res://scripts/characters/tiger_clay.gd").new()
	tiger.stage = stage
	var started := Time.get_ticks_msec()
	var model: Node3D = tiger.build_display()
	var tris := 0
	for mi in model.find_children("*", "MeshInstance3D", false, false):
		tris += mi.mesh.get_faces().size() / 3
	print("STUDY stage %d: %d triangles, %d ms" % [stage, tris, Time.get_ticks_msec() - started])
	port.add_child(model)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	port.add_child(cam)
	cam.current = true
	for lamp in [[Vector3(-55, -22, 0), 0.85], [Vector3(-8, 30, 0), 0.2]]:
		var light := DirectionalLight3D.new()
		light.rotation_degrees = lamp[0]
		light.light_energy = lamp[1]
		cam.add_child(light)
	var total := 0
	var tall := 0
	for v in views:
		total += (v[2] as Rect2i).size.x * SS + 12
		tall = maxi(tall, (v[2] as Rect2i).size.y * SS)
	var out := Image.create(total, tall * 2 + 12, false, Image.FORMAT_RGBA8)
	out.fill(Color.WHITE)
	var x0 := 0
	for v in views:
		var r: Rect2i = v[2]
		var yaw := deg_to_rad(v[0])
		var dir := Vector3(-sin(yaw), 0, -cos(yaw))
		var right := Vector3(-cos(yaw), 0, sin(yaw))
		var mid := Vector2(r.position) + Vector2(r.size) * 0.5
		var shift: float = mid.x - (795.0 * sin(yaw) + v[1])
		var target: Vector3 = at(795, mid.y - v[3]) + right * UNIT * shift
		port.size = r.size * SS
		cam.size = r.size.y * UNIT
		cam.position = target + dir * 20.0
		cam.look_at(target)
		for i in 3: await process_frame
		for i in 3: RenderingServer.force_draw(false)
		var shot := port.get_texture().get_image()
		shot.convert(Image.FORMAT_RGBA8)
		var w := r.size.x * SS
		var h := r.size.y * SS
		var crop := sheet.get_region(r)
		crop.resize(w, h, Image.INTERPOLATE_CUBIC)
		var lower := Image.create(w, h, false, Image.FORMAT_RGBA8)
		lower.fill(BG)
		lower.blend_rect(shot, Rect2i(0, 0, w, h), Vector2i.ZERO)
		# The model's outline on the sheet.
		for y in h - 1:
			for x in w - 1:
				var a := shot.get_pixel(x, y).a > 0.5
				if a != (shot.get_pixel(x + 1, y).a > 0.5) or a != (shot.get_pixel(x, y + 1).a > 0.5):
					for q in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
						crop.set_pixel(x + q.x, y + q.y, Color(1, 0, 0.9))
		# The sheet's outline on the model.
		for y in r.size.y - 1:
			for x in r.size.x - 1:
				var a := fig(r.position.x + x, r.position.y + y)
				if a != fig(r.position.x + x + 1, r.position.y + y):
					for i in SS:
						lower.set_pixel((x + 1) * SS, y * SS + i, Color(0, 0.25, 1))
						lower.set_pixel((x + 1) * SS - 1, y * SS + i, Color(0, 0.25, 1))
				if a != fig(r.position.x + x, r.position.y + y + 1):
					for i in SS:
						lower.set_pixel(x * SS + i, (y + 1) * SS, Color(0, 0.25, 1))
						lower.set_pixel(x * SS + i, (y + 1) * SS - 1, Color(0, 0.25, 1))
		out.blit_rect(crop, Rect2i(0, 0, w, h), Vector2i(x0, 0))
		out.blit_rect(lower, Rect2i(0, 0, w, h), Vector2i(x0, tall + 12))
		x0 += w + 12
	out.save_png(args[2])
	print("STUDY saved ", args[2])
	quit()
