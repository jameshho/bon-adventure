extends RefCounted
## Bathroom fixtures (user request, 8 Nov 2026; record: docs/guides/TOWN_DESIGN_BRIEF.md "Bathroom
## fixtures"): models for the interactive toilet (scripts/world/toilet.gd) and faucet
## (scripts/world/faucet.gd), the washbasins they sit on, and the helpers building steps use to
## place them. Same look as the rest of the town: low-poly rounded shapes from the fountain's
## mesh builder (monument_plaza.gd Geo) with vertex colours, no textures, three finishes
## (porcelain, metal, matte), water from the fountain stream shader.
##
## Units are town units (the Apartment's 1.3 scale is applied above). Every fixture's origin is
## on the floor (toilet) or on the surface it stands on (faucet, basin), with its front facing +Z:
## a toilet's back and a faucet's base are at z = 0, the spout reaches toward +Z.
##
## Placing one from a building step (scripts/buildings/<unit>.gd):
##   const BathFixtures := preload("res://scripts/world/bath_fixtures.gd")
##   BathFixtures.add_toilet(parent, "Guest toilet", floor_point, yaw, "home")
##   BathFixtures.add_faucet(parent, "Basin faucet", deck_point, yaw, "home_basin", landing_y)
## Or drag scenes/props/fixtures/toilet.tscn / faucet.tscn into a scene in the editor and set
## `style` (and the faucet's `drop`). Styles: STYLES below.

const Geo := preload("res://scripts/buildings/monument_plaza.gd").Geo
const TOILET_SCENE := preload("res://scenes/props/fixtures/toilet.tscn")
const FAUCET_SCENE := preload("res://scenes/props/fixtures/faucet.tscn")
const STREAM_SHADER := preload("res://shaders/fountain_stream.gdshader")
const SWIRL_SHADER := preload("res://shaders/bowl_swirl.gdshader")
const FLUSH_CONTROL := preload("res://scripts/world/flush_control.gd")

## Porcelain whites match the Home's existing toilet and basin (f7f3e9 / ffffff); brass is the
## Home's door hardware, chrome the kitchen tap and the store fixtures' silver.
const PORCELAIN := Color("f7f3e9")
const SEAT_WHITE := Color("ffffff")
const BRASS := Color("b79258")
const CHROME := Color("c3cbd1")
const KITCHEN_CHROME := Color("a6b5bb")
const DARK := Color("3a4044")

## toilet: "floor" (close-coupled with a cistern, lid up, lever) or "wall" (wall-hung, no lid,
## push plate). faucet: column height, spout reach, lever kind and finish.
const STYLES := {
	"home": {"toilet": "floor", "metal": BRASS},
	"public": {"toilet": "wall", "metal": CHROME},
	"home_basin": {"faucet": "lever", "metal": BRASS, "height": .34, "reach": .27},
	"kitchen": {"faucet": "gooseneck", "metal": KITCHEN_CHROME, "height": .44, "reach": .3},
	"public_basin": {"faucet": "lever", "metal": CHROME, "height": .2, "reach": .16},
}

## Bowl outline shared by the floor and wall toilets: oval scale (x, z) and the bowl's centre
## distance from the back (z), rim height and water height.
const BOWL_OVAL := Vector2(.82, 1.18)
const BOWL_Z := .6
const RIM_Y := .585
const WATER_Y := .51
const WATER_RADIUS := .19

static var _materials := {}
static var _meshes := {}

# --- Materials -------------------------------------------------------------------------

static func finish(kind: String) -> StandardMaterial3D:
	if not _materials.has(kind):
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.vertex_color_is_srgb = true
		match kind:
			"porcelain": m.roughness = .32
			"metal":
				m.roughness = .3
				m.metallic = .45
			_: m.roughness = .85
		_materials[kind] = m
	return _materials[kind]

## Shared plain metal (brass, chrome) for one colour; the parts' vertex colours are white.
static func metal_finish(color: Color) -> StandardMaterial3D:
	var key := "metal " + color.to_html(false)
	if not _materials.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = .3
		m.metallic = .45
		_materials[key] = m
	return _materials[key]

## A fresh water material for one stream (each faucet sets its own uniforms).
static func stream_material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = STREAM_SHADER
	m.set_shader_parameter("bands", 9.0)
	m.set_shader_parameter("speed", 3.2)
	m.set_shader_parameter("opacity", .75)
	m.set_shader_parameter("water_color", Color(.58, .8, .94))
	return m

static func bowl_water_material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SWIRL_SHADER
	return m

static func foam_material() -> StandardMaterial3D:
	if not _materials.has("foam"):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(1, 1, 1, .8)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = .35
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_materials["foam"] = m
	return _materials["foam"]

# --- Geometry helpers ------------------------------------------------------------------

## Transforms the vertices (and normals) appended to `g` since index `from`.
static func _shape(g: Geo, from: int, xform: Transform3D) -> void:
	var normal_basis := xform.basis.inverse().transposed()
	for i in range(from, g.verts.size()):
		g.verts[i] = xform * g.verts[i]
		g.norms[i] = (normal_basis * g.norms[i]).normalized()

## Lathe squashed into the bowl's oval about `centre`.
static func _oval_lathe(g: Geo, centre: Vector3, profile: Array, smooth := true, segs := 24) -> void:
	var from := g.verts.size()
	g.lathe(Vector3.ZERO, profile, segs, smooth)
	_shape(g, from, Transform3D(Basis.from_scale(Vector3(BOWL_OVAL.x, 1, BOWL_OVAL.y)), centre))

## Rounded box: a chamfered block (side = Z, up = Y) extruded along X.
static func _rounded_box(g: Geo, centre: Vector3, size: Vector3, chamfer: float) -> void:
	var hz := size.z * .5
	var hy := size.y * .5
	var c := minf(chamfer, minf(hz, hy) * .9)
	g.block(centre, Vector3.RIGHT, size.x, [Vector2(-hz + c, -hy), Vector2(hz - c, -hy), Vector2(hz, -hy + c), Vector2(hz, hy - c),
		Vector2(hz - c, hy), Vector2(-hz + c, hy), Vector2(-hz, hy - c), Vector2(-hz, -hy + c)])

static func _node(parent: Node3D, title: String, mesh: Mesh, mat: Material, pos := Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = title
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	parent.add_child(node)
	return node

static func _cached(key: String, build: Callable) -> ArrayMesh:
	if not _meshes.has(key):
		var g := Geo.new()
		build.call(g)
		var mesh: ArrayMesh = g.commit()
		mesh.resource_name = key
		_meshes[key] = mesh
	return _meshes[key]

# --- Toilet ----------------------------------------------------------------------------

## The bowl: outer wall up to the rim, rim, inner wall down to the water.
static func _bowl(g: Geo, bottom: float) -> void:
	g.color = PORCELAIN
	_oval_lathe(g, Vector3(0, 0, BOWL_Z), [Vector2(0, bottom), Vector2(.15, bottom), Vector2(.25, bottom + .1), Vector2(.295, RIM_Y - .05),
		Vector2(.3, RIM_Y - .01), Vector2(.285, RIM_Y), Vector2(.25, RIM_Y), Vector2(.21, RIM_Y - .05), Vector2(.17, WATER_Y + .02),
		Vector2(.12, WATER_Y - .03), Vector2(0, WATER_Y - .04)])

static func _seat(g: Geo) -> void:
	g.color = SEAT_WHITE
	_oval_lathe(g, Vector3(0, 0, BOWL_Z), [Vector2(.205, RIM_Y), Vector2(.305, RIM_Y), Vector2(.31, RIM_Y + .015), Vector2(.3, RIM_Y + .03),
		Vector2(.215, RIM_Y + .03), Vector2(.2, RIM_Y + .015), Vector2(.205, RIM_Y)], false)

static func toilet_body(kind: String) -> ArrayMesh:
	return _cached("Toilet body " + kind, func(g: Geo) -> void:
		if kind == "floor":
			_bowl(g, .36)
			# Pedestal down to the floor and the neck back to the cistern.
			_oval_lathe(g, Vector3(0, 0, BOWL_Z - .03), [Vector2(.17, 0), Vector2(.17, .02), Vector2(.14, .08), Vector2(.13, .28), Vector2(.17, .37)])
			_rounded_box(g, Vector3(0, .47, .3), Vector3(.34, .2, .24), .06)
			# Cistern and its lid.
			_rounded_box(g, Vector3(0, .78, .13), Vector3(.56, .5, .24), .04)
			_rounded_box(g, Vector3(0, 1.045, .13), Vector3(.6, .05, .27), .02)
		else:
			_bowl(g, .3)
			# Carrier to the wall.
			_rounded_box(g, Vector3(0, .45, .14), Vector3(.36, .28, .28), .06))

static func toilet_seat() -> ArrayMesh:
	return _cached("Toilet seat", func(g: Geo) -> void: _seat(g))

## Raised lid, built in its hinge frame (hinge on the local X axis, lid standing up, its
## seat-side face toward +Z).
static func toilet_lid() -> ArrayMesh:
	return _cached("Toilet lid", func(g: Geo) -> void:
		g.color = SEAT_WHITE
		var from := g.verts.size()
		g.lathe(Vector3.ZERO, [Vector2(0, 0), Vector2(.3, 0), Vector2(.31, .012), Vector2(.3, .025), Vector2(0, .025)], 24, false)
		# Disc in the XZ plane -> oval -> stood up about X with its far edge at the top.
		_shape(g, from, Transform3D(Basis(Vector3.RIGHT, -PI * .5) * Basis.from_scale(Vector3(BOWL_OVAL.x, 1, BOWL_OVAL.y)), Vector3(0, .31 * BOWL_OVAL.y, 0)))
	)

## Flush lever (floor toilet), on the cistern's left side clear of the raised lid: escutcheon
## facing -X plus an arm reaching forward (+Z) from the pivot.
static func toilet_lever() -> ArrayMesh:
	return _cached("Toilet lever", func(g: Geo) -> void:
		g.color = Color.WHITE
		g.loft([Vector3(.01, 0, 0), Vector3(-.02, 0, 0)], [Vector2(.03, .03), Vector2(.03, .03)], Vector3.UP, 12)
		g.loft([Vector3(-.03, 0, -.01), Vector3(-.035, -.005, .1)], [Vector2(.012, .012), Vector2(.014, .01)], Vector3.UP, 8)
	)

## Push plate on the wall (wall toilet), and its button.
static func flush_plate() -> ArrayMesh:
	return _cached("Flush plate", func(g: Geo) -> void:
		g.color = Color.WHITE
		_rounded_box(g, Vector3.ZERO, Vector3(.3, .2, .02), .008))

static func flush_button() -> ArrayMesh:
	return _cached("Flush button", func(g: Geo) -> void:
		g.color = Color(.86, .88, .9)
		_rounded_box(g, Vector3.ZERO, Vector3(.13, .1, .025), .008))

## Water surface disc of radius 1 (the toilet scales it to the bowl).
static func water_disc() -> ArrayMesh:
	return _cached("Water disc", func(g: Geo) -> void:
		g.lathe(Vector3.ZERO, [Vector2(1, 0), Vector2(0, 0)], 28, false))

## Builds the toilet's parts under `root` (scripts/world/toilet.gd calls this once).
static func build_toilet(root: Node3D, style: String) -> void:
	var spec: Dictionary = STYLES.get(style, STYLES["home"])
	var kind: String = spec.get("toilet", "floor")
	var metal := metal_finish(spec["metal"])
	var model := Node3D.new()
	model.name = "Model"
	root.add_child(model)
	_node(model, "Body", toilet_body(kind), finish("porcelain"))
	_node(model, "Seat", toilet_seat(), finish("porcelain"))
	# The flush control is its own pick target and interactable (9 Nov 2026, user;
	# flush_control.gd): E or a click on it flushes, while E on the bowl sits down. Word: the lever is a handle; the push plate keeps toilet.
	var flush := Node3D.new()
	flush.name = "Flush"
	flush.set_script(FLUSH_CONTROL)
	flush.set_meta("word_key", "handle" if kind == "floor" else "toilet")
	model.add_child(flush)
	var lever := Node3D.new()
	lever.name = "Lever"
	flush.add_child(lever)
	var pick := Area3D.new()
	pick.name = "Pick"
	flush.add_child(pick)
	var pick_shape := CollisionShape3D.new()
	var pick_box := BoxShape3D.new()
	pick_shape.shape = pick_box
	pick.add_child(pick_shape)
	pick.set_meta("object_name", str(root.name))
	if kind == "floor":
		_node(model, "Lid", toilet_lid(), finish("porcelain"), Vector3(0, RIM_Y + .03, .28))
		lever.position = Vector3(-.28, .93, .16)
		_node(lever, "Handle", toilet_lever(), metal)
		# A little larger than the lever and standing proud of the cistern, so the ray finds it.
		pick_box.size = Vector3(.2, .16, .34)
		pick_shape.position = Vector3(-.31, .93, .2)
	else:
		_node(flush, "Plate", flush_plate(), metal, Vector3(0, 1.05, .01))
		lever.position = Vector3(0, 1.05, .025)
		_node(lever, "Button", flush_button(), metal)
		pick_box.size = Vector3(.34, .26, .08)
		pick_shape.position = Vector3(0, 1.05, .04)
	var water := _node(model, "Water", water_disc(), bowl_water_material(), Vector3(0, WATER_Y, BOWL_Z))
	water.scale = Vector3(WATER_RADIUS * BOWL_OVAL.x, 1, WATER_RADIUS * BOWL_OVAL.y)
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Solid boxes: the player walks round them; picking finds the toilet root from them. The
	# floor toilet has a tall back (cistern, raised lid) and a low bowl, so the lever beside the
	# cistern can be aimed at over the bowl.
	var body := StaticBody3D.new()
	body.name = "Solid"
	root.add_child(body)
	var boxes := [[Vector3(.6, 1.07, .32), Vector3(0, .535, .16)], [Vector3(.6, .64, .63), Vector3(0, .32, .635)]]
	if kind == "wall":
		boxes = [[Vector3(.52, .62, .95), Vector3(0, .31, .475)]]
	for spec_box in boxes:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = spec_box[0]
		shape.position = spec_box[1]
		shape.shape = box
		body.add_child(shape)
	body.set_meta("object_name", str(root.name))

# --- Faucet ----------------------------------------------------------------------------

## Faucet body (base, column, spout) for a style; the spout tip is faucet_tip(style).
static func faucet_body(style: String) -> ArrayMesh:
	var spec: Dictionary = STYLES[style]
	var h: float = spec["height"]
	var reach: float = spec["reach"]
	return _cached("Faucet body " + style, func(g: Geo) -> void:
		g.color = Color.WHITE
		g.lathe(Vector3.ZERO, [Vector2(0, 0), Vector2(.055, 0), Vector2(.055, .012), Vector2(.04, .03), Vector2(.03, .035), Vector2(0, .035)], 16, false)
		if spec["faucet"] == "gooseneck":
			var pts := [Vector3(0, .03, 0), Vector3(0, h * .7, 0), Vector3(0, h, reach * .25), Vector3(0, h + .02, reach * .6),
				Vector3(0, h - .03, reach * .92), Vector3(0, h - .1, reach)]
			var radii := []
			for p in pts: radii.append(Vector2(.022, .022))
			g.loft(pts, radii, Vector3.RIGHT, 12)
		else:
			g.loft([Vector3(0, .03, 0), Vector3(0, h, 0)], [Vector2(.028, .028), Vector2(.026, .026)], Vector3.RIGHT, 12)
			g.loft([Vector3(0, h - .03, 0), Vector3(0, h - .01, reach * .5), Vector3(0, h - .04, reach)],
				[Vector2(.02, .016), Vector2(.019, .015), Vector2(.017, .014)], Vector3.UP, 10)
	)

## Spout tip, where the water leaves the faucet (faucet-local).
static func faucet_tip(style: String) -> Vector3:
	var spec: Dictionary = STYLES[style]
	var h: float = spec["height"]
	var reach: float = spec["reach"]
	if spec["faucet"] == "gooseneck":
		return Vector3(0, h - .12, reach)
	return Vector3(0, h - .055, reach)

## The lever, built in its pivot frame: a short arm leaning back (-Z) and up.
static func faucet_lever() -> ArrayMesh:
	return _cached("Faucet lever", func(g: Geo) -> void:
		g.color = Color.WHITE
		g.ellipsoid(Vector3.ZERO, Vector3(.03, .025, .03), Basis(), 10, 5)
		g.loft([Vector3(0, .01, 0), Vector3(0, .035, -.1)], [Vector2(.011, .009), Vector2(.013, .008)], Vector3.UP, 8)
	)

## Stream: radius .016 tapering slightly, from y = 0 down to y = -1 (the faucet scales it).
static func stream_mesh() -> ArrayMesh:
	return _cached("Faucet stream", func(g: Geo) -> void:
		g.loft([Vector3(0, 0, 0), Vector3(0, -.5, 0), Vector3(0, -1, 0)], [Vector2(.021, .021), Vector2(.019, .019), Vector2(.018, .018)], Vector3.BACK, 10, false))

## Splash ring where the stream lands.
static func splash_mesh() -> ArrayMesh:
	return _cached("Faucet splash", func(g: Geo) -> void:
		g.color = Color.WHITE
		g.lathe(Vector3.ZERO, [Vector2(.02, 0), Vector2(.055, .004), Vector2(.065, .012), Vector2(.045, .02), Vector2(.025, .014), Vector2(.0, .02)], 16)
		for i in 5:
			var a := TAU * i / 5.0
			g.ellipsoid(Vector3(cos(a) * .045, .03, sin(a) * .045), Vector3(.008, .012, .008), Basis(), 6, 3))

static func build_faucet(root: Node3D, style: String, drop: float) -> Dictionary:
	if not STYLES.has(style) or not STYLES[style].has("faucet"):
		style = "home_basin"
	var spec: Dictionary = STYLES[style]
	var metal := metal_finish(spec["metal"])
	var model := Node3D.new()
	model.name = "Model"
	root.add_child(model)
	_node(model, "Body", faucet_body(style), metal)
	var h: float = spec["height"]
	var lever := Node3D.new()
	lever.name = "Lever"
	model.add_child(lever)
	# Top lever leaning back; the gooseneck's lever is on its side, pointing +X.
	lever.position = Vector3(0, h, 0)
	if spec["faucet"] == "gooseneck":
		lever.position = Vector3(.03, h * .55, 0)
		lever.rotation.y = -PI * .5
	_node(lever, "Handle", faucet_lever(), metal)
	var tip := faucet_tip(style)
	var stream := _node(model, "Stream", stream_mesh(), stream_material(), tip)
	stream.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stream.visible = false
	var splash := _node(model, "Splash", splash_mesh(), foam_material(), tip - Vector3(0, drop, 0))
	splash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	splash.visible = false
	# A generous pick area round the column and spout (faucets are small; UI decision 4 Nov 2026).
	var area := Area3D.new()
	area.name = "Pick"
	root.add_child(area)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(.16, h + .1, tip.z + .14)
	shape.shape = box
	shape.position = Vector3(0, (h + .1) * .5, tip.z * .5)
	area.add_child(shape)
	area.set_meta("object_name", str(root.name))
	return {"tip": tip}

# --- Washbasins ------------------------------------------------------------------------

## Round vessel basin (Home), origin on the counter: 0.84 across, 0.16 high, like the old disc.
static func vessel_basin() -> ArrayMesh:
	return _cached("Vessel basin", func(g: Geo) -> void:
		g.color = SEAT_WHITE
		g.lathe(Vector3.ZERO, [Vector2(0, 0), Vector2(.33, 0), Vector2(.4, .1), Vector2(.42, .16), Vector2(.39, .165), Vector2(.36, .1),
			Vector2(.25, .045), Vector2(0, .04)], 28)
		g.color = Color("aab4b8")
		g.lathe(Vector3(0, .002, 0), [Vector2(.035, .04), Vector2(0, .04)], 12, false))

## Wall-hung public basin, origin on the wall at the rim's height (front +Z): 0.58 wide.
static func wall_basin() -> ArrayMesh:
	return _cached("Wall basin", func(g: Geo) -> void:
		g.color = SEAT_WHITE
		_rounded_box(g, Vector3(0, -.08, .23), Vector3(.58, .16, .46), .05)
		var from := g.verts.size()
		g.color = Color("e8eef0")
		g.lathe(Vector3.ZERO, [Vector2(1, .002), Vector2(0, .002)], 24, false)
		_shape(g, from, Transform3D(Basis.from_scale(Vector3(.22, 1, .15)), Vector3(0, 0, .27)))
		g.color = Color("aab4b8")
		g.lathe(Vector3(0, .004, .27), [Vector2(.03, 0), Vector2(0, 0)], 12, false))

## Landing height (basin-local y) of a faucet's water in each basin.
const VESSEL_FLOOR := .045
const WALL_BASIN_FLOOR := .002

# --- Placing ---------------------------------------------------------------------------

static func _place(node: Node3D, parent: Node3D, title: String, pos: Vector3, yaw: float) -> Node3D:
	node.name = title
	parent.add_child(node, true)
	node.position = pos
	node.rotation = Vector3(0, yaw, 0)
	return node

## Rebuilds the parts of every toilet under `parent` (a bake step, after the parts change: baked
## toilets keep their saved parts). Returns how many.
static func rebuild_toilets(parent: Node) -> int:
	# Found first: rebuilding frees the old parts, which a single walk would visit.
	var toilets := parent.find_children("*", "Node3D", true, false).filter(func(node: Node) -> bool:
		return node.get_script() != null and node.get_script().resource_path == "res://scripts/world/toilet.gd")
	for toilet in toilets:
		toilet.rebuild()
	if toilets.is_empty():
		push_error("rebuild_toilets: no toilets under " + str(parent.name))
	return toilets.size()

## A toilet (word "toilet") with its back at `pos` (parent-local, on the floor), facing yaw.
static func add_toilet(parent: Node3D, title: String, pos: Vector3, yaw: float, style := "home") -> Node3D:
	var toilet: Node3D = TOILET_SCENE.instantiate()
	toilet.set("style", style)
	return _place(toilet, parent, title, pos, yaw)

## A faucet (word "faucet") standing at `pos`; `landing_y` is the parent-local height where its
## water lands (the basin floor), so the stream ends there.
static func add_faucet(parent: Node3D, title: String, pos: Vector3, yaw: float, style: String, landing_y: float) -> Node3D:
	var faucet: Node3D = FAUCET_SCENE.instantiate()
	faucet.set("style", style)
	faucet.set("drop", pos.y + faucet_tip(style).y - landing_y)
	return _place(faucet, parent, title, pos, yaw)

# --- Bathtub, shower curtain, vanity and accessories (13 Nov 2026) ---------------------
# Home bathroom refit (scripts/buildings/home_furnishing.gd): the same rounded low-poly look as
# the toilets. Origins: on the floor (tub, tray) or on the wall face (vanity, mirror, rails),
# front +Z, like the toilet.

## Alcove bathtub `size` = (length x, height, depth z); origin at the middle of its back edge.
## A rounded rim around a deep well with a pale floor.
const TUB_WALL := .15
const TUB_FLOOR := .2
static func bathtub_body(size: Vector3) -> ArrayMesh:
	return _cached("Bathtub %.2f %.2f %.2f" % [size.x, size.y, size.z], func(g: Geo) -> void:
		var l := size.x
		var h := size.y
		var d := size.z
		var w := TUB_WALL
		g.color = PORCELAIN
		_rounded_box(g, Vector3(0, TUB_FLOOR / 2, d / 2), Vector3(l - .02, TUB_FLOOR, d - .02), .04)
		_rounded_box(g, Vector3(0, h / 2, w / 2), Vector3(l, h, w), .06)
		_rounded_box(g, Vector3(0, h / 2, d - w / 2), Vector3(l, h, w), .06)
		for side in [-1.0, 1.0]:
			var from := g.verts.size()
			_rounded_box(g, Vector3.ZERO, Vector3(d - w * 2 + .04, h, w), .06)
			_shape(g, from, Transform3D(Basis(Vector3.UP, PI / 2), Vector3(side * (l / 2 - w / 2), h / 2, d / 2)))
		g.color = Color("eaf2f3")
		_rounded_box(g, Vector3(0, TUB_FLOOR + .005, d / 2), Vector3(l - w * 2 + .02, .01, d - w * 2 + .02), .004))

## The water in a tub (a flat sheet in the well, `level` above the floor).
static func tub_water(size: Vector3) -> Mesh:
	var plane := PlaneMesh.new()
	plane.size = Vector2(size.x - TUB_WALL * 2 + .02, size.z - TUB_WALL * 2 + .02)
	return plane

static func water_finish() -> StandardMaterial3D:
	if not _materials.has("tub water"):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(.55, .82, .92, .55)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = .08
		m.metallic_specular = .8
		_materials["tub water"] = m
	return _materials["tub water"]

## A gathered shower curtain `length` x `height`, hanging from y 0 down, running along +X from
## the origin (the end fixed at the wall). Soft pleats; vertical stripes every other pleat.
static func shower_curtain(length: float, height: float, color: Color, stripe: Color) -> ArrayMesh:
	return _cached("Shower curtain %.2f %.2f %s %s" % [length, height, color.to_html(false), stripe.to_html(false)], func(g: Geo) -> void:
		var pleats := maxi(4, int(round(length / .22)))
		var depth := .055
		for i in pleats:
			var x0 := length * i / pleats
			var x1 := length * (i + 1) / pleats
			var z0 := depth if i % 2 == 0 else -depth
			var z1 := -z0
			g.color = stripe if i % 4 < 2 else color
			var n := Vector3(-(z1 - z0), 0, x1 - x0).normalized()
			for face in [1.0, -1.0]:
				var nn: Vector3 = n * face
				var a := Vector3(x0, 0, z0)
				var b := Vector3(x1, 0, z1)
				var c := Vector3(x1, -height, z1)
				var e := Vector3(x0, -height, z0)
				if face > 0: g.quad(a, b, c, e, nn, nn, nn, nn)
				else: g.quad(b, a, e, c, nn, nn, nn, nn)
		# Hem along the bottom.
		g.color = stripe
		_rounded_box(g, Vector3(length / 2, -height + .03, 0), Vector3(length, .06, depth * 2.2), .02))

static func cloth_finish() -> StandardMaterial3D:
	if not _materials.has("cloth"):
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.vertex_color_is_srgb = true
		m.roughness = .9
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_materials["cloth"] = m
	return _materials["cloth"]

## Wall-hung vanity cabinet `size` (width x, height, depth z), origin on the wall at its top
## centre: a painted two-door cabinet with brass knobs and a pale stone top.
static func vanity_body(size: Vector3, paint: Color) -> ArrayMesh:
	return _cached("Vanity %.2f %.2f %.2f %s" % [size.x, size.y, size.z, paint.to_html(false)], func(g: Geo) -> void:
		g.color = paint
		_rounded_box(g, Vector3(0, -size.y / 2 - .04, size.z / 2), Vector3(size.x, size.y - .08, size.z - .02), .04)
		g.color = paint.lightened(.12)
		for side in [-1.0, 1.0]:
			_rounded_box(g, Vector3(side * size.x / 4, -size.y / 2 - .04, size.z + .005), Vector3(size.x / 2 - .1, size.y - .22, .03), .012)
		g.color = Color("ece8de")
		_rounded_box(g, Vector3(0, -.03, size.z / 2 + .02), Vector3(size.x + .06, .06, size.z + .06), .02))

## Brass knobs for a vanity (separate: metal finish).
static func vanity_knobs(size: Vector3) -> ArrayMesh:
	return _cached("Vanity knobs %.2f %.2f %.2f" % [size.x, size.y, size.z], func(g: Geo) -> void:
		g.color = Color.WHITE
		for side in [-1.0, 1.0]:
			g.ellipsoid(Vector3(side * .07, -size.y * .35, size.z + .04), Vector3(.035, .035, .03), Basis(), 10, 5))

## Wall mirror `size` (x, y), origin on the wall at its centre: rounded frame and glass.
static func mirror_frame(size: Vector2) -> ArrayMesh:
	return _cached("Mirror frame %.2f %.2f" % [size.x, size.y], func(g: Geo) -> void:
		g.color = Color.WHITE
		var t := .08
		_rounded_box(g, Vector3(0, size.y / 2 - t / 2, .03), Vector3(size.x, t, .06), .025)
		_rounded_box(g, Vector3(0, -size.y / 2 + t / 2, .03), Vector3(size.x, t, .06), .025)
		for side in [-1.0, 1.0]:
			_rounded_box(g, Vector3(side * (size.x / 2 - t / 2), 0, .03), Vector3(t, size.y - t * 2 + .01, .06), .025))

static func mirror_glass_finish() -> StandardMaterial3D:
	if not _materials.has("mirror glass"):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color("c9dde3")
		m.roughness = .05
		m.metallic = .65
		_materials["mirror glass"] = m
	return _materials["mirror glass"]

## Towel rail `width` wide on two brackets, origin on the wall at the bar's height (metal).
static func towel_rail(width: float) -> ArrayMesh:
	return _cached("Towel rail %.2f" % width, func(g: Geo) -> void:
		g.color = Color.WHITE
		g.loft([Vector3(-width / 2, 0, .12), Vector3(width / 2, 0, .12)], [Vector2(.022, .022), Vector2(.022, .022)], Vector3.UP, 10)
		for side in [-1.0, 1.0]:
			g.loft([Vector3(side * (width / 2 - .05), 0, 0), Vector3(side * (width / 2 - .05), 0, .12)], [Vector2(.02, .02), Vector2(.02, .02)], Vector3.UP, 8))

## A towel folded over a rail (`width` wide, hanging `drop` below the bar on both sides).
static func hanging_towel(width: float, drop: float, color: Color) -> ArrayMesh:
	return _cached("Hanging towel %.2f %.2f %s" % [width, drop, color.to_html(false)], func(g: Geo) -> void:
		g.color = color
		_rounded_box(g, Vector3(0, -drop / 2 + .02, .07), Vector3(width, drop, .035), .015)
		_rounded_box(g, Vector3(0, -drop * .35 + .02, .17), Vector3(width, drop * .7, .035), .015)
		_rounded_box(g, Vector3(0, .025, .12), Vector3(width, .04, .12), .02)
		g.color = color.darkened(.12)
		_rounded_box(g, Vector3(0, -drop * .55, .19), Vector3(width, .05, .02), .008))

## Toilet roll holder (metal arm) with its roll (porcelain white), origin on the wall.
static func roll_holder() -> ArrayMesh:
	return _cached("Roll holder", func(g: Geo) -> void:
		g.color = Color.WHITE
		g.loft([Vector3(0, 0, 0), Vector3(0, 0, .1)], [Vector2(.03, .03), Vector2(.03, .03)], Vector3.UP, 8)
		g.loft([Vector3(-.03, 0, .1), Vector3(.17, 0, .1)], [Vector2(.015, .015), Vector2(.015, .015)], Vector3.FORWARD, 8))

static func toilet_roll() -> ArrayMesh:
	return _cached("Toilet roll", func(g: Geo) -> void:
		g.color = SEAT_WHITE
		g.loft([Vector3(-.0, 0, .1), Vector3(.14, 0, .1)], [Vector2(.07, .07), Vector2(.07, .07)], Vector3.FORWARD, 14)
		g.color = Color("d9d2c4")
		g.loft([Vector3(-.005, 0, .1), Vector3(.145, 0, .1)], [Vector2(.025, .025), Vector2(.025, .025)], Vector3.FORWARD, 8))

## Shower tray `size` (x, z), origin on the floor at its centre.
static func shower_tray(size: Vector2) -> ArrayMesh:
	return _cached("Shower tray %.2f %.2f" % [size.x, size.y], func(g: Geo) -> void:
		g.color = PORCELAIN
		_rounded_box(g, Vector3(0, .05, 0), Vector3(size.x, .1, size.y), .03)
		g.color = Color("aab4b8")
		g.lathe(Vector3(0, .101, 0), [Vector2(.06, 0), Vector2(0, 0)], 12, false))

## Shower head on an arm from the wall plus a round mixer below it, origin on the wall at the
## mixer: the riser runs up `rise` to the arm (metal).
static func shower_set(rise: float) -> ArrayMesh:
	return _cached("Shower set %.2f" % rise, func(g: Geo) -> void:
		g.color = Color.WHITE
		var from := g.verts.size()
		g.lathe(Vector3.ZERO, [Vector2(0, 0), Vector2(.11, 0), Vector2(.11, .03), Vector2(0, .03)], 18)
		_shape(g, from, Transform3D(Basis(Vector3.RIGHT, PI / 2), Vector3(0, 0, .0)))
		g.loft([Vector3(0, .0, .04), Vector3(0, .0, .12)], [Vector2(.025, .025), Vector2(.025, .025)], Vector3.UP, 8)
		g.loft([Vector3(0, 0, .03), Vector3(0, rise, .03)], [Vector2(.022, .022), Vector2(.022, .022)], Vector3.FORWARD, 8)
		g.loft([Vector3(0, rise, .03), Vector3(0, rise + .05, .1), Vector3(0, rise + .02, .38)], [Vector2(.022, .022), Vector2(.022, .022), Vector2(.022, .022)], Vector3.UP, 8)
		g.lathe(Vector3(0, rise - .03, .44), [Vector2(0, -.02), Vector2(.15, -.02), Vector2(.16, .0), Vector2(.12, .04), Vector2(0, .05)], 20))
