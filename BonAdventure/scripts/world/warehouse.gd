extends RefCounted
## Warehouse (Phase 1, 5 Nov 2026; redesigned 14 Nov 2026; design: docs/guides/WAREHOUSE.md). A tall
## silver-gray metal hall between the school and the airport.
##
## The town's warehouse is saved in scenes/town/warehouse.scn (modular town); its own script
## scripts/buildings/warehouse.gd holds the baked steps (the 14 Nov `half_depth_redesign` step
## rebuilt the shell and the hall with this file and placed the exterior and reception). This
## file builds the shared shell (`architecture()`) and hall equipment (`hall_equipment()`), the
## Warehouse Worker minigame copy (`build_copy()`) and holds the shared dimensions the minigame
## scripts read (Warehouse.FLOOR, SHELF_AT, ...). Local frame of the `Warehouse` root: +X west,
## +Z north (same as the town), the front on local z = 0 facing the road; town units (Apartment
## scale 1.3 applies).
##
## Redesign (user, 14 Nov 2026): half the depth (30 wide × 14.5 deep), the reception inside the
## footprint at the east end (-X) with the glass sliding entrance on the front, two outdoor
## truck-loading bays on the front of the hall, and the hall split by a low wall with a wide
## opening into a right (east) section, left empty, and a left (west) section with one large
## shelf, one table and the two-door supply cabinet. Left and right are as seen facing into the
## building from the front (north): left = +X (west).

## Town-local position of the building origin (front face of the front wall, x = 0).
const SITE := Vector3(-35, 0, 220.8)
## The whole building: 30 wide (x ±15) from z 0 to 14.5. The hall is 8 high, the reception 4.2.
const HW := 15.0
const HALL_Z0 := 0.0
const HALL_Z1 := 14.5
const H := 8.0
const T := .3
const AH := 4.2
## Finished floor level inside (slabs sit on the terrain).
const FLOOR := .15
const BASE := -.2
## The reception: x -15 .. RX - T; the partition between it and the hall is x RX - T .. RX.
const RX := -8.0
## Glass sliding entrance in the reception's front wall; it slides west into the wall.
const ENTRANCE_X := -12.2
const DOOR_W2 := 1.1
const DOOR_H := 2.7
## Hinged hall door in the partition, swinging into the reception.
const HALL_DOOR_Z := 3.6
const HALL_DOOR_W2 := .9
const HALL_DOOR_H := 2.7
## Two outdoor truck-loading bays: roll-up doors on the hall front, both into the right
## (east) section, [x0, x1] each (14 Nov 2026).
const LOADING_DOORS := [[-7.2, -3.4], [-2.2, 1.6]]
const ROLL_H := 4.6
## The low wall that divides the hall into a right (east) and a left (west) section, with a
## wide opening (hall z from .. to) between its two halves.
const DIVIDER_X := 3.0
const DIVIDER_H := 1.2
const DIVIDER_OPENING := Vector2(4.5, 9.5)
## Reception windows in the east wall (hall z of their centres, 3 wide).
const RECEPTION_WINDOWS := [4.5, 10.5]
## Roof trusses (hall z) and the x lines of the purlins and floor joints.
const TRUSS_Z := [5.0, 9.6]
const PURLINS_X := [-4.0, 1.0, 6.0, 11.0]

# Palette: silver-gray ribbed metal, charcoal trim, a little safety yellow; no green.
const WALL := "c3c9cf"
const YELLOW := "f2c230"
const ANNEX := "e6e8eb"
const ROOF := "d9dcdf"
const ROOF_TOP := "9aa1a8"
const INNER := "e4e6e8"
const INNER_RIB := "d2d6da"
const WAINSCOT := "7f8d9b"
const STEEL := "6b7580"
const CONCRETE := "b9bbb8"
const JOINT := "9c9f9d"
const TILE := "e7e2d8"
const TILE_JOINT := "d6cfc2"
const FRAME := "3e444b"
const ROLL := "aab1b8"
const HouseCharacters := preload("res://scripts/characters/house_characters.gd")

var game
var town: Node3D
var glass_mat: StandardMaterial3D
var frost_mat: StandardMaterial3D
var glow_mat: StandardMaterial3D
## True while building the minigame copy: its doors are not registered, so they stay shut
## (the session is left through Ramón or the task card, never by walking out).
var copy := false

# ---------------------------------------------------------------- helpers

func part(parent: Node3D, title: String, center: Vector3, size: Vector3, tint: String, solid := false, word := "") -> Node3D:
	var node: Node3D = game.box(title, center, size, Color(tint), word, solid)
	node.reparent(parent, false)
	return node

## A solid box between two corners (local).
func block(parent: Node3D, title: String, a: Vector3, b: Vector3, tint: String, solid := true) -> Node3D:
	return part(parent, title, (a + b) * .5, (b - a).abs(), tint, solid)

func cylinder(parent: Node3D, title: String, p: Vector3, radius: float, height: float, tint: String, top := -1.0) -> MeshInstance3D:
	var node: Node3D = game.cylinder(title, p, radius, height, Color(tint), "", false)
	node.reparent(parent, false)
	var mesh := node.get_child(0) as MeshInstance3D
	if top >= 0.0:
		(mesh.mesh as CylinderMesh).top_radius = top
	return mesh

## The shared window component in place of a glass pane (docs/guides/WINDOWS.md), as the town's
## warehouse has since its `glass_windows` step (12 Nov 2026).
func window_glass(holder: Node3D, see_through: bool) -> void:
	for mesh in holder.find_children("*", "MeshInstance3D", true, false):
		preload("res://scripts/buildings/glass_windows.gd").replace(mesh, see_through)
		return

func paint(node: Node3D, mat: Material) -> void:
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		mesh.material_override = mat

func materials() -> void:
	if glass_mat != null:
		return
	glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(.72, .84, .9, .38)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.roughness = .08
	# Frosted clerestory glass: lit daylight from outside, but nothing beyond it shows.
	frost_mat = StandardMaterial3D.new()
	frost_mat.albedo_color = Color("cddfe9")
	frost_mat.emission_enabled = true
	frost_mat.emission = Color("dce9f2")
	frost_mat.emission_energy_multiplier = .35
	frost_mat.roughness = .6
	glow_mat = StandardMaterial3D.new()
	glow_mat.albedo_color = Color("fff3d6")
	glow_mat.emission_enabled = true
	glow_mat.emission = Color("ffe8b8")
	glow_mat.emission_energy_multiplier = 1.6

func label(parent: Node3D, text: String, p: Vector3, yaw: float, width: float, tint := Color.WHITE, size := 64) -> Label3D:
	var sign_label := Label3D.new()
	parent.add_child(sign_label)
	sign_label.name = "Warehouse lettering"
	sign_label.text = text
	sign_label.position = p
	sign_label.rotation.y = yaw
	sign_label.font_size = size
	sign_label.pixel_size = minf(.018, width / (maxi(text.length(), 1) * 40.0))
	sign_label.outline_size = 0
	sign_label.modulate = tint
	return sign_label

# ---------------------------------------------------------------- architecture

## The permanent shell, shared by the normal warehouse and the minigame copy.
func architecture(p: Node3D) -> void:
	materials()
	floors(p)
	walls(p)
	reception_walls(p)
	roofs(p)
	doors(p)
	clerestory(p)
	hall_interior(p)
	divider(p)
	tag_shell(p)

## The building word (Phase 2): every solid wall and roof answers "warehouse", as the
## school's shell answers "school". Doors and windows keep their own words; lining,
## ribs and fascia have no bodies, so a ray reaches the wall behind them.
func tag_shell(p: Node3D) -> void:
	for node in p.get_children():
		var title := String(node.name)
		for start in ["Warehouse rear wall", "Warehouse west wall", "Warehouse partition", "Warehouse front wall", "Warehouse roof", "Reception east wall", "Reception rear wall", "Reception front wall", "Reception window sill wall", "Reception window header", "Reception roof", "Roll-up door"]:
			if title.begins_with(start) and not title.contains("membrane") and not title.contains("slat"):
				node.set_meta("exterior_word", "warehouse")

func floors(p: Node3D) -> void:
	block(p, "Warehouse hall floor", Vector3(RX - T, -.55, HALL_Z0), Vector3(HW, FLOOR, HALL_Z1), CONCRETE)
	block(p, "Warehouse reception floor", Vector3(-HW, -.55, HALL_Z0), Vector3(RX - T, FLOOR, HALL_Z1), TILE)
	# Saw-cut control joints give the polished concrete its industrial grid.
	for x in PURLINS_X:
		part(p, "Floor joint", Vector3(x, FLOOR + .003, (HALL_Z0 + HALL_Z1) * .5), Vector3(.05, .006, HALL_Z1 - HALL_Z0 - 2 * T), JOINT)
	for z in TRUSS_Z:
		part(p, "Floor joint", Vector3((RX + HW - T) * .5, FLOOR + .003, z), Vector3(HW - T - RX, .006, .05), JOINT)
	var x := -HW + 1.0
	while x < RX - T - .5:
		part(p, "Tile joint", Vector3(x, FLOOR + .003, (HALL_Z0 + HALL_Z1) * .5), Vector3(.03, .006, HALL_Z1 - HALL_Z0 - 2 * T), TILE_JOINT)
		x += 1.0
	for z in range(1, int(HALL_Z1)):
		part(p, "Tile joint", Vector3((-HW + RX - T) * .5, FLOOR + .003, z), Vector3(RX - T + HW - 2 * T, .006, .03), TILE_JOINT)

## Hall walls: front (two roll-up doors), rear, west and the partition to the reception (the
## hall door), all 8 high. The front and rear walls start at the partition.
func walls(p: Node3D) -> void:
	var z0 := HALL_Z0
	var z1 := HALL_Z0 + T
	block(p, "Warehouse rear wall", Vector3(RX - T, BASE, HALL_Z1 - T), Vector3(HW, H, HALL_Z1), WALL)
	block(p, "Warehouse west wall", Vector3(HW - T, BASE, HALL_Z0), Vector3(HW, H, HALL_Z1), WALL)
	var x := RX - T
	for door in LOADING_DOORS:
		block(p, "Warehouse front wall", Vector3(x, BASE, z0), Vector3(door[0], H, z1), WALL)
		block(p, "Warehouse front wall", Vector3(door[0], ROLL_H, z0), Vector3(door[1], H, z1), WALL)
		x = door[1]
	block(p, "Warehouse front wall", Vector3(x, BASE, z0), Vector3(HW, H, z1), WALL)
	# The partition, with the hall door (its opening runs along z).
	var d0 := HALL_DOOR_Z - HALL_DOOR_W2
	var d1 := HALL_DOOR_Z + HALL_DOOR_W2
	block(p, "Warehouse partition", Vector3(RX - T, BASE, z1), Vector3(RX, H, d0), WALL)
	block(p, "Warehouse partition", Vector3(RX - T, FLOOR + HALL_DOOR_H, d0), Vector3(RX, H, d1), WALL)
	block(p, "Warehouse partition", Vector3(RX - T, BASE, d1), Vector3(RX, H, HALL_Z1 - T), WALL)
	# Closed roll-up doors with their slats on both faces.
	for i in LOADING_DOORS.size():
		var door: Array = LOADING_DOORS[i]
		block(p, "Roll-up door " + "AB"[i], Vector3(door[0], BASE, z0 + .06), Vector3(door[1], ROLL_H, z1 - .06), ROLL)
		var slat_y := .45
		while slat_y < ROLL_H - .1:
			for face in [z0 + .04, z1 - .04]:
				part(p, "Roll-up door slat", Vector3((door[0] + door[1]) * .5, slat_y, face), Vector3(door[1] - door[0] - .1, .05, .03), "959da5")
			slat_y += .45

## The reception walls (4.2 high): front with the glass entrance, east with two windows, rear.
func reception_walls(p: Node3D) -> void:
	var x1 := RX - T
	block(p, "Reception front wall", Vector3(-HW, BASE, 0), Vector3(ENTRANCE_X - DOOR_W2, AH, T), ANNEX)
	block(p, "Reception front wall", Vector3(ENTRANCE_X - DOOR_W2, FLOOR + DOOR_H, 0), Vector3(ENTRANCE_X + DOOR_W2, AH, T), ANNEX)
	block(p, "Reception front wall", Vector3(ENTRANCE_X + DOOR_W2, BASE, 0), Vector3(x1, AH, T), ANNEX)
	block(p, "Reception rear wall", Vector3(-HW, BASE, HALL_Z1 - T), Vector3(x1, AH, HALL_Z1), ANNEX)
	var z := T
	for c in RECEPTION_WINDOWS:
		block(p, "Reception east wall", Vector3(-HW, BASE, z), Vector3(-HW + T, AH, c - 1.5), ANNEX)
		block(p, "Reception window sill wall", Vector3(-HW, BASE, c - 1.5), Vector3(-HW + T, .9, c + 1.5), ANNEX)
		block(p, "Reception window header", Vector3(-HW, 2.6, c - 1.5), Vector3(-HW + T, AH, c + 1.5), ANNEX)
		var pane := part(p, "Reception window", Vector3(-HW + .1, 1.75, c), Vector3(.04, 1.7, 3.0), "c8dbe6", true, "window")
		paint(pane, glass_mat)
		window_glass(pane, true)
		for bar in [[Vector3(-HW + .02, .93, c), Vector3(.1, .07, 3.0)], [Vector3(-HW + .02, 2.57, c), Vector3(.1, .07, 3.0)], [Vector3(-HW + .02, 1.75, c - 1.47), Vector3(.1, 1.7, .07)], [Vector3(-HW + .02, 1.75, c + 1.47), Vector3(.1, 1.7, .07)], [Vector3(-HW + .02, 1.75, c), Vector3(.1, 1.7, .06)]]:
			part(p, "Reception window frame", bar[0], bar[1], FRAME)
		z = c + 1.5
	block(p, "Reception east wall", Vector3(-HW, BASE, z), Vector3(-HW + T, AH, HALL_Z1 - T), ANNEX)

func roofs(p: Node3D) -> void:
	block(p, "Warehouse roof", Vector3(RX - T, H, HALL_Z0), Vector3(HW, H + .3, HALL_Z1), ROOF)
	part(p, "Warehouse roof membrane", Vector3((RX - T + HW) * .5, H + .31, (HALL_Z0 + HALL_Z1) * .5), Vector3(HW - RX + T - .5, .02, HALL_Z1 - HALL_Z0 - .5), ROOF_TOP)
	block(p, "Reception roof", Vector3(-HW, AH, HALL_Z0), Vector3(RX - T, AH + .25, HALL_Z1), ROOF)
	part(p, "Reception roof membrane", Vector3((-HW + RX - T) * .5, AH + .26, (HALL_Z0 + HALL_Z1) * .5), Vector3(RX - T + HW - .4, .02, HALL_Z1 - HALL_Z0 - .4), ROOF_TOP)

func doors(p: Node3D) -> void:
	# Entrance: one wide glass sliding door (E), sliding west into the solid front wall.
	var door: Node3D = game.box("Warehouse entrance door", Vector3(ENTRANCE_X, FLOOR + 1.275, .2), Vector3(2 * DOOR_W2, 2.55, .06), Color("c8dbe6"), "door", true)
	door.reparent(p, false)
	paint(door, glass_mat)
	window_glass(door, true)
	for bar in [[Vector3(0, 1.27, 0), Vector3(2 * DOOR_W2, .08, .09)], [Vector3(0, -1.24, 0), Vector3(2 * DOOR_W2, .08, .09)], [Vector3(-DOOR_W2 + .04, 0, 0), Vector3(.08, 2.55, .09)], [Vector3(DOOR_W2 - .04, 0, 0), Vector3(.08, 2.55, .09)], [Vector3(0, 0, 0), Vector3(.07, 2.55, .09)]]:
		part(door, "Entrance door frame", bar[0], bar[1], FRAME)
	for x in [-.18, .18]:
		part(door, "Entrance door handle", Vector3(x, 0, -.08), Vector3(.04, .6, .04), "c9d1d6")
	if not copy:
		game.doors[door] = {"type": "slide", "origin": door.position, "shift": Vector3(2 * DOOR_W2 + .15, 0, 0), "open": false, "safe_slide": true}
	# Hall door in the partition: hinged on its north jamb, the leaf running south (local -z),
	# swinging into the reception (E). Closed at rotation 0 (door_animator.gd).
	var pivot := Node3D.new()
	pivot.name = "Warehouse hall door"
	pivot.position = Vector3(RX - T * .5, FLOOR, HALL_DOOR_Z + HALL_DOOR_W2)
	p.add_child(pivot)
	var leaf := part(pivot, "Hall door leaf", Vector3(0, (HALL_DOOR_H - .05) * .5, -HALL_DOOR_W2), Vector3(.07, HALL_DOOR_H - .05, 2 * HALL_DOOR_W2 - .04), "8796a5", true, "door")
	for body in leaf.find_children("*", "CollisionObject3D", true, false):
		body.set_meta("root", pivot)
	pivot.set_meta("word_key", "door")
	var vision := part(pivot, "Hall door window", Vector3(0, 1.75, -HALL_DOOR_W2), Vector3(.09, .7, .5), "c8dbe6")
	paint(vision, glass_mat)
	window_glass(vision, false)
	for x in [-.06, .06]:
		part(pivot, "Hall door handle", Vector3(x, 1.0, -(2 * HALL_DOOR_W2 - .2)), Vector3(.04, .04, .22), "c9d1d6")
		part(pivot, "Hall door kick plate", Vector3(x * .8, .15, -HALL_DOOR_W2), Vector3(.02, .25, 2 * HALL_DOOR_W2 - .1), YELLOW)
	if not copy:
		game.doors[pivot] = {"open": false, "type": "hinge", "angle": 1.75}
	for x in [RX - T - .02, RX + .02]:
		for z in [HALL_DOOR_Z - HALL_DOOR_W2 - .05, HALL_DOOR_Z + HALL_DOOR_W2 + .05]:
			part(p, "Hall door frame", Vector3(x, FLOOR + HALL_DOOR_H * .5, z), Vector3(.04, HALL_DOOR_H, .1), FRAME)
		part(p, "Hall door frame", Vector3(x, FLOOR + HALL_DOOR_H + .05, HALL_DOOR_Z), Vector3(.04, .1, 2 * HALL_DOOR_W2 + .2), FRAME)

## High frosted windows on the rear, west and east (above the reception roof) walls of the
## hall, inside and out.
func clerestory(p: Node3D) -> void:
	var y := 6.15
	for x in [-5.0, 0.0, 5.5, 10.5]:
		for face in [[HALL_Z1 + .03, 1.0], [HALL_Z1 - T - .03, -1.0]]:
			paint(part(p, "Clerestory window", Vector3(x, y, face[0]), Vector3(2.6, 1.1, .03), "e3ecf1"), frost_mat)
			for dy in [-.58, .58]:
				part(p, "Clerestory frame", Vector3(x, y + dy, face[0] + face[1] * .02), Vector3(2.75, .08, .04), FRAME)
	for z in [3.6, 10.9]:
		for face in [[HW + .03, 1.0], [HW - T - .03, -1.0], [RX - T - .03, -1.0], [RX + .03, 1.0]]:
			paint(part(p, "Clerestory window", Vector3(face[0], y, z), Vector3(.03, 1.1, 2.6), "e3ecf1"), frost_mat)
			for dy in [-.58, .58]:
				part(p, "Clerestory frame", Vector3(face[0] + face[1] * .02, y + dy, z), Vector3(.04, .08, 2.75), FRAME)

## Hall finishes: painted lining with ribs, a blue-gray wainscot and yellow line, steel
## columns at both ends of two roof trusses, purlins, and three pendant lamps.
func hall_interior(p: Node3D) -> void:
	var in_z0 := HALL_Z0 + T
	var in_z1 := HALL_Z1 - T
	var in_x := HW - T
	# Painted lining (upper) and wainscot (lower) on each inner face; openings left clear.
	var x := RX
	for door in LOADING_DOORS:
		lining(p, Vector3(x, 0, in_z0 + .015), Vector3(door[0], 0, in_z0 + .015), true)
		part(p, "Hall lining", Vector3((door[0] + door[1]) * .5, (ROLL_H + H) * .5, in_z0 + .015), Vector3(door[1] - door[0], H - ROLL_H, .02), INNER)
		x = door[1]
	lining(p, Vector3(x, 0, in_z0 + .015), Vector3(in_x, 0, in_z0 + .015), true)
	lining(p, Vector3(RX, 0, in_z1 - .015), Vector3(in_x, 0, in_z1 - .015), true)
	lining(p, Vector3(in_x - .015, 0, in_z0), Vector3(in_x - .015, 0, in_z1), false)
	lining(p, Vector3(RX + .015, 0, in_z0), Vector3(RX + .015, 0, HALL_DOOR_Z - HALL_DOOR_W2), false)
	lining(p, Vector3(RX + .015, 0, HALL_DOOR_Z + HALL_DOOR_W2), Vector3(RX + .015, 0, in_z1), false)
	part(p, "Hall lining", Vector3(RX + .015, (FLOOR + HALL_DOOR_H + H) * .5, HALL_DOOR_Z), Vector3(.02, H - FLOOR - HALL_DOOR_H, 2 * HALL_DOOR_W2), INNER)
	for z in TRUSS_Z:
		for cx in [in_x - .2, RX + .2]:
			part(p, "Steel column", Vector3(cx, (FLOOR + H) * .5, z), Vector3(.4, H - FLOOR, .4), STEEL, true)
		# Truss: bottom and top chords with vertical webs.
		var span := in_x - RX
		part(p, "Roof truss chord", Vector3((in_x + RX) * .5, 6.95, z), Vector3(span, .22, .22), STEEL)
		part(p, "Roof truss chord", Vector3((in_x + RX) * .5, 7.8, z), Vector3(span, .22, .22), STEEL)
		var web := RX + 1.25
		while web < in_x:
			part(p, "Roof truss web", Vector3(web, 7.37, z), Vector3(.1, .65, .1), STEEL)
			web += 2.5
	for px in PURLINS_X:
		part(p, "Roof purlin", Vector3(px, H - .09, (in_z0 + in_z1) * .5), Vector3(.16, .16, in_z1 - in_z0), "7b8591")
	# Pendant lamps: one over the right section, two over the left.
	for at in [Vector3(-2.5, 0, 7.3), Vector3(6.0, 0, 7.3), Vector3(11.0, 0, 7.3)]:
		pendant(p, at)

## A wall lining from a to b (one horizontal axis): wainscot to 1.2, a yellow line, then the
## painted upper panel with subtle vertical ribs.
func lining(p: Node3D, a: Vector3, b: Vector3, along_x: bool) -> void:
	var length: float = absf(b.x - a.x) if along_x else absf(b.z - a.z)
	if length < .05:
		return
	var mid := (a + b) * .5
	var size := func(h: float, d: float) -> Vector3: return Vector3(length, h, d) if along_x else Vector3(d, h, length)
	part(p, "Hall wainscot", Vector3(mid.x, FLOOR + .6, mid.z), size.call(1.2, .02), WAINSCOT)
	part(p, "Hall safety line", Vector3(mid.x, FLOOR + 1.24, mid.z), size.call(.08, .025), YELLOW)
	part(p, "Hall lining", Vector3(mid.x, (FLOOR + 1.28 + H) * .5, mid.z), size.call(H - FLOOR - 1.28, .02), INNER)
	var step := 1.5
	var t := step * .5
	while t < length:
		var at := Vector3(minf(a.x, b.x) + t, 0, mid.z) if along_x else Vector3(mid.x, 0, minf(a.z, b.z) + t)
		part(p, "Hall lining rib", Vector3(at.x, 3.55, at.z), Vector3(.08, 3.9, .04) if along_x else Vector3(.04, 3.9, .08), INNER_RIB)
		t += step

func pendant(p: Node3D, at: Vector3) -> void:
	cylinder(p, "Lamp rod", Vector3(at.x, 7.25, at.z), .025, 1.5, FRAME)
	cylinder(p, "Lamp shade", Vector3(at.x, 6.35, at.z), .55, .45, "4f5862", .22)
	var bulb := cylinder(p, "Lamp glow", Vector3(at.x, 6.11, at.z), .48, .03, "fff3d6")
	bulb.material_override = glow_mat
	var light := OmniLight3D.new()
	light.name = "Warehouse lamp light"
	light.position = Vector3(at.x, 5.8, at.z)
	light.light_color = Color("fff0d6")
	light.light_energy = .9
	light.omni_range = 13.0
	light.omni_attenuation = .9
	light.shadow_enabled = false
	p.add_child(light)

## The low wall between the right (east) and left (west) sections: two solid halves with a
## yellow cap, and a wide opening between them (DIVIDER_OPENING).
func divider(p: Node3D) -> void:
	for span in [[HALL_Z0 + T, DIVIDER_OPENING.x, "south"], [DIVIDER_OPENING.y, HALL_Z1 - T, "north"]]:
		block(p, "Hall divider wall", Vector3(DIVIDER_X - .1, FLOOR, span[0]), Vector3(DIVIDER_X + .1, FLOOR + DIVIDER_H, span[1]), WAINSCOT).name = "Hall divider wall " + span[2]
		part(p, "Hall divider cap", Vector3(DIVIDER_X, FLOOR + DIVIDER_H + .02, (span[0] + span[1]) * .5), Vector3(.24, .04, span[1] - span[0]), YELLOW).name = "Hall divider cap " + span[2]

# ---------------------------------------------------------------- hall equipment

## Fixed equipment of the left (west) section (user, 14 Nov 2026), shared by the town
## warehouse and the minigame copy: one large shelf (two levels, three goods on each, capacity
## six) against the rear wall, one table, and the two-door supply cabinet. The right (east)
## section by the loading doors stays empty. Every surface goods rest on is solid.
const RACK_UPRIGHT := "4b525a"
const RACK_DECK := "b7bfc7"
## The painted places on each deck and the back panel (21 Nov 2026).
const RACK_PAD := "eef1f3"
const RACK_BACK := "5d7186"
## Shelf deck heights (bottom, top) above the floor; the player pig is 1.71 hall units tall.
## 21 Nov 2026 (user: "the shelf should have clear two levels"): the bottom deck stands clear
## of the floor and the frame ends at the top deck, so the top deck is the top of the shelf.
const RACK_LEVELS := [.3, 1.1]
const RACK_DECK_THICK := .05
const SHELF_AT := Vector3(9.5, 0, 13.2)
const RACK_LENGTH := 4.0
const RACK_DEPTH := 1.0
## The three places on each level (hall x from the shelf centre).
const SHELF_SLOTS := [-1.3, 0.0, 1.3]
const CABINET_AT := Vector3(5.2, 0, 13.75)
const TABLE_TOP := "c9b48f"
const TABLE_HEIGHT := .9
const WORK_TABLE := Vector3(8.5, 0, 6.0)
const WORK_TABLE_SIZE := Vector2(3.0, 1.4)
## Goods colours (warehouse_goods.gd, the town's exterior container).
const BOX_COLORS := {"red": "d9534a", "blue": "3f74b5", "green": "4f9a4c", "yellow": "f2c230", "brown": "7a4b2c", "orange": "ec8a2e", "purple": "7d4fa8", "pink": "e88fb4", "black": "33363b"}

func hall_equipment(p: Node3D) -> void:
	materials()
	shelf(p, SHELF_AT, RACK_LENGTH)
	work_table(p, "Work table", WORK_TABLE, WORK_TABLE_SIZE)
	supply_cabinet(p, CABINET_AT)

## A two-level shelf (21 Nov 2026, user: "clear two levels"): four uprights that end just
## above the top deck (no frame above it, so the top deck reads as the top of the shelf), a
## dark back panel between the decks, a yellow beam under each deck's front and back, and on
## each deck three light painted places (SHELF_SLOTS), one per box. Front faces -z, toward
## the hall. Each deck is a "shelf".
func shelf(p: Node3D, at: Vector3, length: float) -> void:
	var depth := RACK_DEPTH
	var tall: float = RACK_LEVELS[-1] + RACK_DECK_THICK * .5 + .06
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		part(p, "Rack upright", at + Vector3(corner.x * (length * .5 - .04), FLOOR + tall * .5, corner.y * (depth * .5 - .04)), Vector3(.08, tall, .08), RACK_UPRIGHT, true)
		part(p, "Rack upright cap", at + Vector3(corner.x * (length * .5 - .04), FLOOR + tall + .015, corner.y * (depth * .5 - .04)), Vector3(.1, .03, .1), YELLOW)
	# The back panel fills the space between the decks (just in front of the rear uprights).
	var low: float = FLOOR + RACK_LEVELS[0] + RACK_DECK_THICK * .5
	var high: float = FLOOR + RACK_LEVELS[-1] - RACK_DECK_THICK * .5
	part(p, "Rack back panel", at + Vector3(0, (low + high) * .5, depth * .5 - .1), Vector3(length - .18, high - low - .004, .03), RACK_BACK, true)
	for i in RACK_LEVELS.size():
		var y: float = FLOOR + RACK_LEVELS[i]
		part(p, "Shelf level " + str(i), at + Vector3(0, y, 0), Vector3(length - .1, RACK_DECK_THICK, depth - .06), RACK_DECK, true, "shelf")
		for side in [-1, 1]:
			part(p, "Rack beam", at + Vector3(0, y - RACK_DECK_THICK * .5 - .055, side * (depth * .5 - .04)), Vector3(length - .1, .11, .05), YELLOW)
		for slot in SHELF_SLOTS:
			part(p, "Shelf place", at + Vector3(slot, y + RACK_DECK_THICK * .5 + .003, -.02), Vector3(1.08, .004, depth - .26), RACK_PAD)

## A steel-legged table; the top is the word "table", legs leave the space under it open.
func work_table(p: Node3D, title: String, at: Vector3, size: Vector2) -> void:
	var height := TABLE_HEIGHT
	var top := part(p, title, at + Vector3(0, FLOOR + height - .025, 0), Vector3(size.x, .05, size.y), TABLE_TOP, true, "table")
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		part(top, "Table leg", Vector3(corner.x * (size.x * .5 - .06), -height * .5, corner.y * (size.y * .5 - .06)), Vector3(.06, height - .05, .06), STEEL, true)
	part(top, "Table rail", Vector3(0, -.08, 0), Vector3(size.x - .12, .08, size.y - .12), STEEL)

## A tall two-door supply cabinet against the rear wall. The doors are static here; in the
## minigame copy warehouse_goods.gd hinges them so E opens and shuts them.
func supply_cabinet(p: Node3D, at: Vector3) -> void:
	var body := part(p, "Supply cabinet", at + Vector3(0, FLOOR + 1.0, 0), Vector3(1.8, 2.0, .6), "8a96a3", true, "cabinet")
	for side in [-1, 1]:
		# Unique names: the minigame copy finds each door and its handle to hinge them.
		var hand := "west" if side > 0 else "east"
		part(body, "Cabinet door", Vector3(side * .445, 0, -.305), Vector3(.87, 1.94, .02), "9aa6b2").name = "Cabinet door " + hand
		part(body, "Cabinet handle", Vector3(side * .07, .05, -.33), Vector3(.03, .3, .03), "d0d5da").name = "Cabinet handle " + hand
	part(body, "Cabinet vent", Vector3(0, .8, -.32), Vector3(1.2, .05, .01), "6f7b88")

# ---------------------------------------------------------------- minigame copy (Phase 4)

## The Warehouse Worker copy: the same shell and hall equipment, COPY_LIFT above the real
## warehouse (same orientation, so map positions are the real ones minus the lift), with
## Ramón's twin at his station in the left section and a `Session` node for the round's goods
## (the wall bay is painted by warehouse_goods.gd). Built by warehouse_session.gd when a game
## starts and freed when it ends. Hall-local points as everywhere in this file.
const COPY_LIFT := Vector3(0, 300, 0)
## The player starts in the left section by the divider's opening, facing west into it.
const STATION := Vector3(4.6, FLOOR, 7.0)
const STATION_LOOK := Vector3(1, 0, 0)
## Ramón's twin stands by the divider, looking into the left section.
const TWIN_SPOT := Vector3(4.3, FLOOR, 11.0)
const TWIN_FACING := Vector3(1, 0, -.8)

func build_copy(main, world: Node3D) -> Node3D:
	game = main
	town = world
	copy = true
	var root := Node3D.new()
	root.name = "WarehouseCopy"
	root.position = SITE + COPY_LIFT
	root.set_meta("warehouse_copy", true)
	town.add_child(root)
	var shell := Node3D.new()
	shell.name = "Architecture"
	root.add_child(shell)
	architecture(shell)
	var hall := Node3D.new()
	hall.name = "Hall"
	root.add_child(hall)
	hall_equipment(hall)
	# A way out (the hall door, the entrance door, the two roll-up loading doors) is an
	# interactable that asks to leave (warehouse_session.gd _build_round()); the doors stay shut.
	for node in shell.get_children():
		var title := String(node.name)
		if title.begins_with("Warehouse hall door") or title.begins_with("Warehouse entrance door") or (title.begins_with("Roll-up door") and not title.contains("slat")):
			node.set_meta("warehouse_exit", true)
	var twin: Node3D = HouseCharacters.new().worker("res://scenes/characters/lion_plush.tscn", "warehouse_worker", "boss", hall, "Ramon", root.to_global(TWIN_SPOT), root.global_basis * TWIN_FACING)
	twin.set_meta("character_id", "ramon")
	var goods := Node3D.new()
	goods.name = "Session"
	root.add_child(goods)
	return root
