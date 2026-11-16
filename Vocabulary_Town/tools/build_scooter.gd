extends SceneTree
## Builds scenes/props/vehicles/scooter.tscn: the town's toy-like scooter (vocabulary word
## "motorcycle"), shaped around BonBon riding at her full size (user decisions, 9 Nov 2026; see
## docs/guides/ZOO_VEHICLE_IMPLEMENTATION.md#scooter-and-rider--9-november-2026). The saved .tscn is the source of
## truth; rerun this only to regenerate it:
##   godot --headless --path . --script res://tools/build_scooter.gd
## Coordinates below are WORLD metres (the town scales vehicles by 1.3); W() converts to model
## units. Road vehicles face -X; +Z is the near (mounting) side.
const OUT := "res://scenes/props/vehicles/scooter.tscn"
const TOWN_SCALE := 1.3
const RIDER_SCALE := 1.0
## Floorboard top: BonBon's origin (her paw soles) when seated. Her belly's underside measured from
## her origin, by distance behind her centre: 0.17 at 0, 0.21 at 0.2, 0.25 at 0.4, 0.49 at 0.6;
## her paws fill 0.3 ahead to 0.2 behind her centre and reach 0.32 up into her belly.
const FLOOR := .42
const RUBBER := Color(.07, .075, .085)
const BODY := Color(.27, .69, .72)
const BODY_DARK := Color(.17, .5, .53)
const CREAM := Color(1, .92, .78)
const SEAT := Color(.62, .38, .24)
const CHROME := Color(.78, .82, .85)
var model: Node3D
var materials := {}

func _initialize() -> void:
	model = Node3D.new()
	model.name = "Motorcycle"
	model.set_script(load("res://scripts/world/driveable_vehicle.gd"))
	model.set_meta("word_key", "motorcycle")
	build()
	for node in model.find_children("*", "", true, false): node.owner = model
	var packed := PackedScene.new()
	packed.pack(model)
	print("SCOOTER saved: ", ResourceSaver.save(packed, OUT))
	model.free()
	quit()

static func W(v: Variant) -> Variant:
	return v / TOWN_SCALE

func mat(color: Color, metal := 0.0, rough := .55, glow := false) -> StandardMaterial3D:
	var key := "%s/%s/%s/%s" % [color.to_html(), metal, rough, glow]
	if not materials.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.metallic = metal
		m.roughness = rough
		if glow:
			m.emission_enabled = true
			m.emission = color
			m.emission_energy_multiplier = .5
		materials[key] = m
	return materials[key]

func mesh(parent: Node, title: String, m: Mesh, at: Vector3, size: Vector3, material: Material, basis := Basis.IDENTITY) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = title
	node.mesh = m
	node.material_override = material
	parent.add_child(node)
	node.transform = Transform3D(basis.scaled_local(W(size)), W(at))
	return node

## Ellipsoid with the given full size (world metres).
func blob(parent: Node, title: String, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = .5
	s.height = 1
	s.radial_segments = 28
	s.rings = 14
	return mesh(parent, title, s, at, size, material)

func block(parent: Node, title: String, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var b := BoxMesh.new()
	return mesh(parent, title, b, at, size, material)

## Round bar between two points (world metres, in the parent's frame).
func rod(parent: Node, title: String, from: Vector3, to: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = .5
	c.bottom_radius = .5
	c.height = 1
	c.radial_segments = 14
	var axis := (to - from).normalized()
	var basis := Basis(Quaternion(Vector3.UP, axis))
	return mesh(parent, title, c, (from + to) * .5, Vector3(radius * 2, from.distance_to(to), radius * 2), material, basis)

func wheel(title: String, x: float) -> void:
	const R := .38
	var w := Node3D.new()
	w.name = title
	w.set_meta("word_key", "wheel")
	model.add_child(w)
	w.position = W(Vector3(x, R, 0))
	w.rotation_degrees = Vector3(90, 0, 0)
	# Physics reads the tyre radius from Visual (CylinderMesh top_radius * scale.x).
	var tyre := CylinderMesh.new()
	tyre.top_radius = .5
	tyre.bottom_radius = .5
	tyre.height = 1
	tyre.radial_segments = 28
	mesh(w, "Visual", tyre, Vector3.ZERO, Vector3(R * 2, .26, R * 2), mat(RUBBER, 0, .95))
	var bulge := TorusMesh.new()
	bulge.inner_radius = R - .13
	bulge.outer_radius = R
	bulge.rings = 20
	bulge.ring_segments = 12
	var t := MeshInstance3D.new()
	t.name = "TyreBulge"
	t.mesh = bulge
	t.material_override = mat(RUBBER, 0, .95)
	w.add_child(t)
	t.scale = Vector3(W(1.0), W(2.0), W(1.0))
	blob(w, "Rim", Vector3.ZERO, Vector3(R * 1.2, .3, R * 1.2), mat(CREAM, .1, .35))
	blob(w, "Hub", Vector3.ZERO, Vector3(.16, .34, .16), mat(CHROME, .8, .2))
	var area := Area3D.new()
	area.name = "Body"
	area.collision_mask = 0
	area.set_meta("word", "wheel")
	w.add_child(area)
	var shape := CollisionShape3D.new()
	shape.name = "Collision"
	var cyl := CylinderShape3D.new()
	cyl.radius = W(R)
	cyl.height = W(.26)
	shape.shape = cyl
	area.add_child(shape)

## BonBon sits with her origin at (0, FLOOR, 0); her centre-behind distance is +X here.
func build() -> void:
	var body := mat(BODY, .15, .38)
	var cream := mat(CREAM, .05, .4)
	var chrome := mat(CHROME, .8, .2)
	var rubber := mat(RUBBER, 0, .9)
	wheel("Wheel", -1.35)
	wheel("Wheel_2", 1.4)
	var shell := Node3D.new()
	shell.name = "Bodywork"
	model.add_child(shell)
	# Floorboard under her paws (0.3 ahead to 0.2 behind her centre), with a cream mat.
	block(shell, "FloorPan", Vector3(-.2, FLOOR - .06, 0), Vector3(1.0, .12, 1.0), body)
	block(shell, "FloorMat", Vector3(-.22, FLOOR - .005, 0), Vector3(.86, .02, .9), mat(CREAM.darkened(.15), 0, .9))
	# Rear: a round cowl over the rear wheel that rises behind her, clear of her tail.
	blob(shell, "RearCowl", Vector3(1.15, FLOOR + .02, 0), Vector3(1.5, .74, .96), body)
	blob(shell, "CowlStripe", Vector3(1.15, FLOOR + .02, 0), Vector3(1.44, .12, 1.0), cream)
	blob(shell, "Taillight", Vector3(1.9, FLOOR + .1, 0), Vector3(.08, .14, .26), mat(Color(.98, .1, .06), .1, .25, true))
	# Front: leg shield ahead of her belly (front at 0.61), fat fender over the front wheel.
	blob(shell, "LegShield", Vector3(-.82, FLOOR + .5, 0), Vector3(.24, 1.15, .86), body)
	blob(shell, "ShieldTrim", Vector3(-.79, FLOOR + .5, 0), Vector3(.2, 1.19, .9), cream)
	blob(shell, "FrontFender", Vector3(-1.35, .72, 0), Vector3(.8, .3, .44), body)
	blob(shell, "Headlight", Vector3(-.95, FLOOR + .98, 0), Vector3(.14, .24, .24), mat(Color(1, .97, .72), 0, .2, true))
	blob(shell, "HeadlightRing", Vector3(-.92, FLOOR + .98, 0), Vector3(.14, .3, .3), chrome)
	blob(shell, "Horn", Vector3(-.95, FLOOR + .72, 0), Vector3(.07, .12, .16), chrome)
	# Cushion under the back of her belly (0.25-0.65 behind her centre): its top meets her
	# underside (0.22-0.26 there), so she sits on it.
	var seat := Node3D.new()
	seat.name = "Seat"
	seat.set_meta("word_key", "seat")
	model.add_child(seat)
	blob(shell, "SeatBase", Vector3(.55, FLOOR + .02, 0), Vector3(.8, .26, .92), body)
	blob(seat, "Visual", Vector3(.47, FLOOR + .13, 0), Vector3(.62, .24, .86), mat(SEAT, 0, .75))
	blob(seat, "Piping", Vector3(.47, FLOOR + .1, 0), Vector3(.65, .07, .89), cream)
	# Steering: fork and bars turn about a vertical axis at x -0.82 (FrontFork). The bars cross in
	# front of her belly, then sweep back to grips at her paws (k ~ 1 arm reach).
	var fork := Node3D.new()
	fork.name = "FrontFork"
	model.add_child(fork)
	fork.position = W(Vector3(-.82, 0, 0))
	for z in [-.15, .15]:
		rod(fork, "ForkLeg" + ("Near" if z > 0 else "Far"), Vector3(-.53, .38, z), Vector3(-.12, FLOOR + .5, z), .035, chrome)
	rod(fork, "SteeringColumn", Vector3(-.06, FLOOR + .9, 0), Vector3(0, FLOOR + 1.06, 0), .05, chrome)
	var bar := Node3D.new()
	bar.name = "Handlebar"
	fork.add_child(bar)
	bar.position = W(Vector3(0, FLOOR + 1.06, 0))
	blob(bar, "Clamp", Vector3.ZERO, Vector3(.14, .1, .16), chrome)
	blob(bar, "Speedometer", Vector3(.03, .07, 0), Vector3(.18, .06, .18), cream)
	for side in [1.0, -1.0]:
		var tag := "Near" if side > 0 else "Far"
		var grip := Vector3(.46, -.02, .76 * side)
		rod(bar, tag + "Bar", Vector3(0, 0, .05 * side), Vector3(0, 0, .62 * side), .026, chrome)
		blob(bar, tag + "Bend", Vector3(0, 0, .62 * side), Vector3(.052, .052, .052), chrome)
		rod(bar, tag + "BarBack", Vector3(0, 0, .62 * side), grip - Vector3(.04, 0, 0), .026, chrome)
		var g := rod(bar, tag + "Grip", grip - Vector3(.06, 0, 0), grip + Vector3(.1, 0, 0), .045, rubber)
		g.set_meta("rider_grip", tag)
	# BonBon's origin once seated, and the spot beside the near floorboard where she climbs on.
	var mount := Marker3D.new()
	mount.name = "RiderMount"
	model.add_child(mount)
	mount.position = W(Vector3(0, FLOOR, 0))
	mount.set_meta("rider_scale", RIDER_SCALE)
	var step := Marker3D.new()
	step.name = "MountStep"
	model.add_child(step)
	step.position = W(Vector3(0, 0, 1.55))
	var study := StaticBody3D.new()
	study.name = "StudyArea"
	study.collision_mask = 0
	study.set_meta("word", "motorcycle")
	model.add_child(study)
	var shape := CollisionShape3D.new()
	shape.name = "StudyShape"
	var box := BoxShape3D.new()
	box.size = W(Vector3(3.65, 1.52, 1.0))
	shape.shape = box
	shape.position = W(Vector3(.02, .78, 0))
	study.add_child(shape)
