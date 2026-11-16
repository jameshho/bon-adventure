extends SceneTree
## Measuring aid: level orthographic side, front and back views of the prefab at 1.5 screen px
## per blueprint px; the outlines of its parts (body, tail, nose, eyes, face lines) are drawn in
## magenta over the matching part of the user's blueprint (overlay-side.png, overlay-front.png,
## overlay-back.png), so shapes can be compared directly.
##   godot --path . --script res://docs/evidence/golden-retriever-clay-20261111/overlay.gd -- <blueprint image>
const OUT := "res://docs/evidence/golden-retriever-clay-20261111/"
const VW := 900
const VH := 700
const ZOOM := 1.5
const UNIT := 0.8 / 353.0      # town units per blueprint px (golden_retriever_clay.gd: DH, DY - DTOP)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	root.size = Vector2i(VW, VH)
	root.always_on_top = true      # a covered window is not drawn on macOS, and the capture stalls
	var sheet := Image.load_from_file(OS.get_cmdline_user_args()[0])
	sheet.convert(Image.FORMAT_RGBA8)
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color.WHITE
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 1.0
	stage.add_child(env)
	var dog: Node3D = load("res://scenes/animals/golden_retriever_clay.tscn").instantiate()
	stage.add_child(dog)
	var shades := {"Body": 0.0, "Ears": 0.12, "Tail": 0.25, "Nose": 0.45, "Eyes": 0.65, "Face details": 0.85}
	for mi in dog.find_children("*", "MeshInstance3D", false, false):
		var flat := StandardMaterial3D.new()
		flat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var v: float = shades.get(String(mi.name), 0.5)
		flat.albedo_color = Color(v, v, v)
		mi.material_override = flat
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = VH / ZOOM * UNIT
	stage.add_child(cam)
	cam.current = true
	var cy := 525.0
	# [file, blueprint x at the view's centre, camera direction, model point at the centre]
	for view in [["side", 820.0, Vector3(-1, 0, 0), Vector3(0, 0, 20.0 * UNIT)], ["front", 464.0, Vector3(0, 0, -1), Vector3.ZERO],
			["back", 1157.0, Vector3(0, 0, 1), Vector3.ZERO]]:
		var target: Vector3 = view[3] + Vector3(0, (700.0 - cy) * UNIT, 0)
		cam.position = target + view[2] * 10.0
		cam.look_at(target)
		for i in range(8): await process_frame
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		var w := int(VW / ZOOM)
		var h := int(VH / ZOOM)
		var crop := sheet.get_region(Rect2i(int(view[1]) - w / 2, int(cy) - h / 2, w, h))
		crop.resize(VW, VH, Image.INTERPOLATE_CUBIC)
		for y in VH - 1:
			for x in VW - 1:
				var v := img.get_pixel(x, y).r
				if absf(v - img.get_pixel(x + 1, y).r) > 0.08 or absf(v - img.get_pixel(x, y + 1).r) > 0.08:
					crop.set_pixel(x, y, Color(1, 0, 0.8))
					crop.set_pixel(x + 1, y, Color(1, 0, 0.8))
		img = crop
		img.save_png(OUT + "overlay-" + view[0] + ".png")
	print("OVERLAYS saved")
	quit()
