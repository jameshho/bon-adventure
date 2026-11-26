extends RefCounted
## Warehouse own script (docs/guides/MODULAR_TOWN.md, "Changing a building"); saved in scenes/town/warehouse.scn.
## The hall and reception are built by scripts/world/warehouse.gd and the minigame scripts; this
## file only holds baked steps.
const STEPS := ["drivable_truck", "coplanar_gaps", "coplanar_gaps_2", "entrance_ramp", "glass_windows", "glass_windows_2", "half_depth_redesign", "two_level_shelf", "openable_cabinet", "door_sounds"]
const W := preload("res://scripts/world/warehouse.gd")

## The delivery truck (box_truck.tscn) became a DriveableVehicle on 8 Nov 2026. Its scene root now
## sits on the ground and faces -X like every road vehicle (the cab model is a child turned 90
## degrees), so the instance drops by the old model-centre height, 1.85 (y 1.94 -> 0.09), and
## turns by -90 degrees: the position and the heading in the lot (cab toward -Z, backed up to
## the roll-up door) are exactly what they were.
func drivable_truck(town: Node3D, _game) -> void:
	var truck := town.get_node("Warehouse/Exterior/Delivery truck") as Node3D
	truck.position.y -= 1.85
	truck.rotation.y = -PI / 2.0
	# The old baked scene still held the former StudyArea boxes at the same paths, in the old
	# frame; put the boxes of box_truck.tscn back (the cab and cargo boxes, turned with the model).
	var cargo := truck.get_node("StudyArea/Cargo") as Node3D
	cargo.transform = Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(0, 1.85, 0))
	var cab := truck.get_node("StudyArea/Cab") as Node3D
	cab.transform = Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(-3.27, 1.45, 0))

## Faces that shared a plane and flickered are set apart (10 Nov 2026,
## scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "warehouse")

## Second pass: faces a first move brought into a new plane, and labels widened for translated
## text (10 Nov 2026, scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps_2(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "warehouse", 2)

## Step (user, 10 Nov 2026: "a step blocks me at the open door, I have to jump in"): the
## reception floor stands FLOOR (0.15) above its base with its edge flush with the front wall,
## about 0.19 above the lot, and the player could not walk over it. A low concrete ramp in front
## of the entrance (wider than the door) now leads from the lot up to the floor.
func entrance_ramp(town: Node3D, game) -> void:
	_entrance_ramp(town, game, 0.0)

## The ramp of entrance_ramp(), centred on the entrance at x.
func _entrance_ramp(town: Node3D, game, x: float) -> void:
	var frame := town.get_node("Warehouse/Architecture") as Node3D
	var ground := -0.06                           # just under the lot (about -0.04 here)
	var run := 1.1
	var slope := atan2(W.FLOOR - ground, run)
	var z0 := -run - 0.15                         # starts buried in the lot
	var z1 := 0.06                                # ends just inside the threshold
	var along := (z1 - z0) / cos(slope)
	var mid_z := (z0 + z1) * 0.5
	var top_y := ground + (mid_z + run) * tan(slope)
	var normal := Vector3(0, cos(slope), -sin(slope))
	var ramp: Node3D = game.box("Warehouse entrance ramp", Vector3.ZERO, Vector3(2 * W.DOOR_W2 + 0.6, 0.12, along), Color(W.CONCRETE), "", true)
	ramp.reparent(frame, false)
	ramp.transform = Transform3D(Basis(Vector3.RIGHT, -slope), Vector3(x, top_y, mid_z) - normal * 0.06)


## Window glass as the shared window component (12 Nov 2026, docs/guides/WINDOWS.md).
func glass_windows(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/glass_windows.gd").migrate(town, "warehouse")


## Transparent panes the first pass missed (auto-named under a room; 12 Nov 2026, docs/guides/WINDOWS.md).
func glass_windows_2(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/glass_windows.gd").migrate_leftovers(town, "warehouse")


## Redesign (user, 14 Nov 2026; docs/guides/WAREHOUSE.md#redesign-14-nov-2026): half the depth
## (30 x 14.5), the reception inside the footprint at the east end (-X) with the glass sliding
## entrance, two outdoor loading bays on the hall front, a low divider wall, one shelf, one
## table and the supply cabinet. The shell (Architecture) and the hall equipment (Hall) are
## rebuilt with scripts/world/warehouse.gd; the exterior trim is rebuilt here; the reception
## furniture, Paty, the posters, the truck and Ramón are moved (not rebuilt), so their words,
## metadata and looks stay as they were.
const LINING := "f3efe7"
const FASCIA := "3f464e"
const PLINTH := "4b525a"
const RIB := "a9b1ba"
## Old reception frame -> new: the desk group turns a quarter (it faced the walkway, west,
## and now faces the entrance, south) and moves to the back of the new reception.
const DESK_MOVE := Transform3D(Basis(Vector3.UP, -PI / 2.0), Vector3(-8.1, 0, 7.25))
const DESK_GROUP := ["Reception desk", "Reception desk top", "Reception desk stripe", "Reception computer", "Desk phone", "Package", "Desk clipboard", "Clipboard paper", "Receptionist chair", "Receptionist"]
## Waiting chairs and the plant move to the east wall of the new reception.
const SEATING_SHIFT := Vector3(-9.2, 0, 3.3)
## The truck backs up to loading bay A; Ramón stands between the entrance and the bays.
const TRUCK_SHIFT := Vector3(5.2, 0, -5.9)
const RAMON_SHIFT := Vector3(-4.6, 0, -0.9)
## The lot's north edge (local z), where the loading apron begins.
const APRON_FRONT := -5.8

func half_depth_redesign(town: Node3D, game) -> void:
	var root := town.get_node("Warehouse") as Node3D
	# Nodes built at runtime (character meshes) are ownerless now; the nodes this step builds
	# get the town as owner before the gaps pass, which only looks at saved nodes.
	var runtime := {}
	for node in root.find_children("*", "", true, false):
		if node.owner == null:
			runtime[node] = true
	var w = W.new()
	w.game = game
	w.town = town
	w.materials()
	# Shell: rebuilt (its doors register in game.doors and are saved as door_state).
	var frame := root.get_node("Architecture") as Node3D
	for child in frame.get_children():
		child.free()
	w.architecture(frame)
	_entrance_ramp(town, game, W.ENTRANCE_X)
	# Hall: one shelf, one table and the supply cabinet.
	var hall := root.get_node("Hall") as Node3D
	for child in hall.get_children():
		child.free()
	w.hall_equipment(hall)
	_reception(w, root.get_node("Reception") as Node3D)
	_exterior(w, root.get_node("Exterior") as Node3D)
	for node in root.find_children("*", "", true, false):
		if node.owner == null and not runtime.has(node):
			node.owner = town
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "warehouse", 3)

func _reception(w, p: Node3D) -> void:
	# The old lining, wainscot and lights fitted the old annex: replaced below.
	for child in p.get_children():
		var title := String(child.name)
		var word := str(child.get_meta("word_key", ""))
		if title.begins_with("Reception lining") or title.begins_with("Reception wainscot") or title == "Reception light" or word == "ceiling light" or (title.begins_with("@") and word == ""):
			child.free()
	for title in DESK_GROUP:
		var node := p.get_node(title) as Node3D
		node.transform = DESK_MOVE * node.transform
		if node.has_meta("seat_point"):
			var seat: Vector3 = node.get_meta("seat_point")
			node.set_meta("seat_point", p.to_global(DESK_MOVE * p.to_local(seat)))
	for child in p.get_children():
		if str(child.get_meta("word_key", "")) in ["chair", "plant"]:
			(child as Node3D).position += SEATING_SHIFT
	# Posters: verbs on the rear wall behind the desk, positions and colours on the partition.
	var rear := W.HALL_Z1 - W.T - .07
	var partition := W.RX - W.T - .07
	_put(p, "Warehouse poster verbs", Vector3((-W.HW + W.RX - W.T) * .5, 2.75, rear), 0.0)
	_put(p, "Warehouse poster positions", Vector3(partition, 2.75, 7.15), PI / 2.0)
	_put(p, "Warehouse poster colors sizes", Vector3(partition, 2.75, 11.85), PI / 2.0)
	# RECEPTION on the east wall between the windows; WAREHOUSE above the hall door.
	_put(p, "Warehouse lettering", Vector3(-W.HW + W.T + .03, 3.15, 7.5), PI / 2.0)
	_put(p, "Warehouse lettering2", Vector3(W.RX - W.T - .04, 3.35, W.HALL_DOOR_Z), -PI / 2.0)
	# A scale and a ruler on the counter, on its public side (user, 14 Nov 2026).
	var top := W.FLOOR + 1.16
	var scale: Node3D = w.part(p, "Counter scale", Vector3(-12.93, top + .03, 10.3), Vector3(.34, .06, .3), "aab1b8", false, "scale")
	w.part(scale, "Scale plate", Vector3(0, .04, 0), Vector3(.28, .02, .24), "d0d5da")
	w.paint(w.part(scale, "Scale display", Vector3(0, .01, -.155), Vector3(.16, .04, .01), "9fc3df"), w.glow_mat)
	var ruler: Node3D = w.part(p, "Counter ruler", Vector3(-11.35, top + .006, 9.98), Vector3(.6, .012, .06), W.YELLOW, false, "ruler")
	for i in 7:
		w.part(ruler, "Ruler mark", Vector3(-.27 + i * .09, .007, -.02), Vector3(.008, .002, .02), "3e444b")
	# Lining with a wainscot on the four inner faces, openings left clear.
	var x0 := -W.HW + W.T
	var x1 := W.RX - W.T
	var z0 := W.T
	var z1 := W.HALL_Z1 - W.T
	var d := W.DOOR_W2
	_lining(w, p, [x0, W.ENTRANCE_X - d], z0 + .012, true)
	_lining(w, p, [W.ENTRANCE_X + d, x1], z0 + .012, true)
	w.part(p, "Reception lining", Vector3(W.ENTRANCE_X, (W.FLOOR + W.DOOR_H + W.AH) * .5, z0 + .012), Vector3(2 * d, W.AH - W.FLOOR - W.DOOR_H, .02), LINING)
	_lining(w, p, [x0, x1], z1 - .012, true)
	_lining(w, p, [W.HALL_DOOR_Z + W.HALL_DOOR_W2 + .1, z1], x1 - .012, false)
	_lining(w, p, [z0, W.HALL_DOOR_Z - W.HALL_DOOR_W2 - .1], x1 - .012, false)
	w.part(p, "Reception lining", Vector3(x1 - .012, (W.FLOOR + W.HALL_DOOR_H + .1 + W.AH) * .5, W.HALL_DOOR_Z), Vector3(.02, W.AH - W.FLOOR - W.HALL_DOOR_H - .1, 2 * W.HALL_DOOR_W2 + .2), LINING)
	var z := z0
	for c in W.RECEPTION_WINDOWS:
		_lining(w, p, [z, c - 1.5], x0 + .012, false)
		w.part(p, "Reception lining", Vector3(x0 + .012, (W.FLOOR + .9) * .5, c), Vector3(.02, .9 - W.FLOOR, 3.0), LINING)
		w.part(p, "Reception lining", Vector3(x0 + .012, (2.6 + W.AH) * .5, c), Vector3(.02, W.AH - 2.6, 3.0), LINING)
		z = c + 1.5
	_lining(w, p, [z, z1], x0 + .012, false)
	# Ceiling light panels and the room light.
	for at in [Vector3(-11.5, 0, 4.2), Vector3(-11.5, 0, 9.6)]:
		w.paint(w.part(p, "Ceiling light", Vector3(at.x, W.AH - .03, at.z), Vector3(2.4, .04, .7), "fff3d6", false, "ceiling light"), w.glow_mat)
	var light := OmniLight3D.new()
	light.name = "Reception light"
	light.position = Vector3(-11.5, W.AH - .6, W.HALL_Z1 * .5)
	light.light_color = Color("fff0d6")
	light.light_energy = .8
	light.omni_range = 9.0
	light.shadow_enabled = false
	p.add_child(light)

func _put(p: Node3D, title: String, at: Vector3, yaw: float) -> void:
	var node := p.get_node(title) as Node3D
	node.position = at
	node.rotation = Vector3(0, yaw, 0)

## A lining panel (floor to ceiling) and a 1.0 high wainscot just in front of it, over `span`
## (along x at z = `at` when along_x, else along z at x = `at`).
func _lining(w, p: Node3D, span: Array, at: float, along_x: bool) -> void:
	var length: float = span[1] - span[0]
	if length < .05:
		return
	var mid: float = (span[0] + span[1]) * .5
	# Into the room: the room's centre is at z 7.25 and x -11.5.
	var inward := .005 * (1.0 if at < (W.HALL_Z1 * .5 if along_x else -11.5) else -1.0)
	var c := Vector3(mid, 0, at) if along_x else Vector3(at, 0, mid)
	var size := Vector3(length, 0, .02) if along_x else Vector3(.02, 0, length)
	w.part(p, "Reception lining", Vector3(c.x, (W.FLOOR + W.AH) * .5, c.z), Vector3(size.x, W.AH - W.FLOOR, size.z), LINING)
	var wainscot := c + (Vector3(0, 0, inward) if along_x else Vector3(inward, 0, 0))
	w.part(p, "Reception wainscot", Vector3(wainscot.x, W.FLOOR + .5, wainscot.z), Vector3(size.x, 1.0, size.z), W.WAINSCOT)

func _exterior(w, p: Node3D) -> void:
	for child in p.get_children():
		if not String(child.name) in ["Delivery truck", "Ramon"]:
			child.free()
	(p.get_node("Delivery truck") as Node3D).position += TRUCK_SHIFT
	(p.get_node("Ramon") as Node3D).position += RAMON_SHIFT
	var hx0 := W.RX - W.T          # the hall's east face
	var z1 := W.HALL_Z1
	var top := W.H
	# Hall: fascia with a yellow line, plinth, parapet; reception: plinth and coping.
	for face in [[Vector3((hx0 + W.HW) * .5, 0, -.04), Vector3(W.HW - hx0 + .1, 0, .06)], [Vector3((hx0 + W.HW) * .5, 0, z1 + .04), Vector3(W.HW - hx0 + .1, 0, .06)], [Vector3(W.HW + .04, 0, z1 * .5), Vector3(.06, 0, z1 + .1)], [Vector3(hx0 - .04, 0, z1 * .5), Vector3(.06, 0, z1 + .1)]]:
		var c: Vector3 = face[0]
		var s: Vector3 = face[1]
		w.part(p, "Warehouse fascia", Vector3(c.x, (7.4 + top + .8) * .5, c.z), Vector3(s.x, top + .8 - 7.4, s.z), FASCIA)
		w.part(p, "Warehouse yellow line", Vector3(c.x, 7.32, c.z), Vector3(s.x, .08, s.z), W.YELLOW)
	w.part(p, "Warehouse plinth", Vector3((hx0 + W.HW) * .5, .25, z1 + .04), Vector3(W.HW - hx0 + .1, .9, .06), PLINTH)
	w.part(p, "Warehouse plinth", Vector3(W.HW + .04, .25, z1 * .5), Vector3(.06, .9, z1 + .1), PLINTH)
	var x := hx0
	for door in W.LOADING_DOORS:
		w.part(p, "Warehouse plinth", Vector3((x + door[0] - .15) * .5, .25, -.04), Vector3(door[0] - .15 - x, .9, .06), PLINTH)
		x = door[1] + .15
	w.part(p, "Warehouse plinth", Vector3((x + W.HW + .05) * .5, .25, -.04), Vector3(W.HW + .05 - x, .9, .06), PLINTH)
	w.block(p, "Warehouse parapet", Vector3(hx0, top + .3, 0), Vector3(W.HW, top + .8, .25), FASCIA, false)
	w.block(p, "Warehouse parapet", Vector3(hx0, top + .3, z1 - .25), Vector3(W.HW, top + .8, z1), FASCIA, false)
	w.block(p, "Warehouse parapet", Vector3(W.HW - .25, top + .3, 0), Vector3(W.HW, top + .8, z1), FASCIA, false)
	w.block(p, "Warehouse parapet", Vector3(hx0, top + .3, 0), Vector3(hx0 + .25, top + .8, z1), FASCIA, false)
	# Cladding ribs: clear of the loading doors; the side, rear and upper east faces stop at
	# the clerestory band.
	x = hx0 + .5
	while x < W.HW:
		w.part(p, "Cladding rib", Vector3(x, 3.05, z1 + .05), Vector3(.1, 4.7, .07), RIB)
		var clear := true
		for door in W.LOADING_DOORS:
			if x > door[0] - .35 and x < door[1] + .35:
				clear = false
		if clear:
			w.part(p, "Cladding rib", Vector3(x, 4.05, -.05), Vector3(.1, 6.7, .07), RIB)
		x += 1.0
	var z := .5
	while z < z1:
		w.part(p, "Cladding rib", Vector3(W.HW + .05, 3.05, z), Vector3(.07, 4.7, .1), RIB)
		if absf(z - 3.6) > 1.45 and absf(z - 10.9) > 1.45:
			w.part(p, "Cladding rib", Vector3(hx0 - .05, (W.AH + .6 + 7.4) * .5, z), Vector3(.07, 7.4 - W.AH - .6, .1), RIB)
		z += 1.0
	var e := W.ENTRANCE_X
	for span in [[-W.HW - .02, e - W.DOOR_W2 - .1], [e + W.DOOR_W2 + .1, hx0]]:
		w.part(p, "Reception plinth", Vector3((span[0] + span[1]) * .5, .2, -.04), Vector3(span[1] - span[0], .8, .06), PLINTH)
	w.part(p, "Reception plinth", Vector3((-W.HW + hx0) * .5, .2, z1 + .04), Vector3(hx0 + W.HW, .8, .06), PLINTH)
	w.part(p, "Reception plinth", Vector3(-W.HW - .04, .2, z1 * .5), Vector3(.06, .8, z1 + .1), PLINTH)
	w.block(p, "Reception coping", Vector3(-W.HW - .08, W.AH + .25, -.08), Vector3(hx0, W.AH + .6, .2), FASCIA, false)
	w.block(p, "Reception coping", Vector3(-W.HW - .08, W.AH + .25, z1 - .2), Vector3(hx0, W.AH + .6, z1 + .08), FASCIA, false)
	w.block(p, "Reception coping", Vector3(-W.HW - .08, W.AH + .25, -.08), Vector3(-W.HW + .2, W.AH + .6, z1 + .08), FASCIA, false)
	# Entrance: canopy on two posts, wall lamps, planters with bushes.
	w.part(p, "Entrance canopy", Vector3(e, 3.05, -.85), Vector3(3.9, .16, 1.9), FASCIA)
	w.part(p, "Entrance canopy soffit", Vector3(e, 2.96, -.85), Vector3(3.7, .02, 1.7), "e9ecef")
	for side in [-1.75, 1.75]:
		w.part(p, "Entrance canopy post", Vector3(e + side, 1.5, -1.65), Vector3(.12, 3.0, .12), FASCIA, true)
	for side in [-1.5, 1.5]:
		_wall_lamp(w, p, Vector3(e + side, 2.25, 0))
	for side in [-2.3, 2.5]:
		w.part(p, "Entrance planter", Vector3(e + side, .3, -.75), Vector3(.9, .6, .9), "b9bcbf", true)
		var bush: Node3D = w.game.sphere("Entrance bush", Vector3.ZERO, .48, Color("5f8a4c"), "plant", false)
		bush.reparent(p, false)
		bush.position = Vector3(e + side, 1.0, -.75)
	# Sign on the hall front, west of the loading bays.
	var sign_x := 8.5
	w.part(p, "Warehouse sign panel", Vector3(sign_x, 5.95, -.12), Vector3(9.0, 1.5, .14), FASCIA)
	w.part(p, "Warehouse sign trim", Vector3(sign_x, 5.17, -.13), Vector3(9.0, .06, .15), W.YELLOW)
	var icon := Vector3(sign_x + 3.35, 5.95, -.21)
	for bar in [[Vector3(0, .38, 0), Vector3(.86, .07, .02)], [Vector3(0, -.38, 0), Vector3(.86, .07, .02)], [Vector3(.4, 0, 0), Vector3(.07, .83, .02)], [Vector3(-.4, 0, 0), Vector3(.07, .83, .02)], [Vector3(0, .13, 0), Vector3(.86, .06, .02)], [Vector3(0, .25, 0), Vector3(.16, .26, .02)]]:
		w.part(p, "Warehouse sign icon", icon + bar[0], bar[1], "ffffff")
	w.label(p, "WAREHOUSE", Vector3(sign_x - .75, 5.95, -.21), PI, 6.2)
	# Two loading bays: yellow jambs, a hood and a lamp over each roll-up door, bollards, one
	# concrete apron to the lot with yellow bay markings. Bay A has the truck; bay B is empty.
	var doors: Array = W.LOADING_DOORS
	for d in doors.size():
		var door: Array = doors[d]
		var bay: String = "AB"[d]
		var mid: float = (door[0] + door[1]) * .5
		var wide: float = door[1] - door[0]
		for side in [door[0] - .12, door[1] + .12]:
			w.part(p, "Roll-up door jamb", Vector3(side, (W.BASE + W.ROLL_H) * .5, -.07), Vector3(.22, W.ROLL_H - W.BASE, .12), W.YELLOW).name = "Roll-up door jamb %s %s" % [bay, "east" if side < mid else "west"]
		w.part(p, "Roll-up door hood", Vector3(mid, W.ROLL_H + .25, -.16), Vector3(wide + .6, .5, .32), FASCIA)
		_wall_lamp(w, p, Vector3(mid, W.ROLL_H + .75, 0))
		for side in [-1.0, 1.0]:
			w.part(p, "Loading bay marking", Vector3(mid + side * (wide * .5 + .05), .096, (APRON_FRONT - .45) * .5), Vector3(.12, .006, -.45 - APRON_FRONT - .2), W.YELLOW).name = "Loading bay marking %s %s" % [bay, "west" if side > 0 else "east"]
		w.part(p, "Loading bay marking", Vector3(mid, .096, -.45), Vector3(wide + .22, .006, .12), W.YELLOW).name = "Loading bay marking %s stop" % bay
	var bollards := [doors[0][0] - .6, (doors[0][1] + doors[1][0]) * .5, doors[1][1] + .6]
	for i in bollards.size():
		w.cylinder(p, "Bollard", Vector3(bollards[i], .55, -.7), .14, 1.0, W.YELLOW).get_parent().name = "Bollard %d" % (i + 1)
		w.cylinder(p, "Bollard cap", Vector3(bollards[i], 1.07, -.7), .15, .05, FASCIA).get_parent().name = "Bollard cap %d" % (i + 1)
	var ax0: float = doors[0][0] - 1.0
	var ax1: float = doors[-1][1] + 1.0
	w.part(p, "Loading apron", Vector3((ax0 + ax1) * .5, .05, APRON_FRONT * .5), Vector3(ax1 - ax0, .08, -APRON_FRONT), "c8c8c0", true)
	# A trolley with a container by the loading doors, and a pallet with cardboard boxes.
	_trolley(w, p, Vector3(doors[1][1] + 1.6, 0, -1.4))
	var pallet := Vector3(6.2, 0, -.9)
	for i in 3:
		w.part(p, "Pallet board", pallet + Vector3(0, .13, -.4 + i * .4), Vector3(1.2, .04, .25), "b9874f")
		w.part(p, "Pallet block", pallet + Vector3(0, .05, -.4 + i * .4), Vector3(1.1, .1, .12), "a0743f")
	for spec in [[Vector3(-.2, .45, 0), Vector3(.7, .6, .6)], [Vector3(.3, .4, .05), Vector3(.5, .5, .55)], [Vector3(-.15, .97, 0), Vector3(.55, .45, .5)]]:
		var box: Node3D = w.part(p, "Cardboard box", pallet + spec[0], spec[1], "c79a5b", false, "cardboard box")
		w.part(box, "Packing tape", Vector3(0, spec[1].y * .5 + .005, 0), Vector3(spec[1].x + .01, .01, .1), "e2c48d")

func _wall_lamp(w, p: Node3D, at: Vector3) -> void:
	w.part(p, "Wall lamp bracket", at + Vector3(0, .2, -.12), Vector3(.08, .08, .24), "2d2f3a")
	w.part(p, "Wall lamp hood", at + Vector3(0, .2, -.27), Vector3(.3, .08, .3), "2d2f3a")
	w.paint(w.part(p, "Wall lamp glass", at + Vector3(0, 0, -.27), Vector3(.2, .32, .2), "ffe2a0"), w.glow_mat)

## A flat platform cart (the word "trolley"), handle toward the wall, with an open plastic bin
## (the word "container") on it: the warehouse's container since the hall stock was cleared.
func _trolley(w, p: Node3D, at: Vector3) -> void:
	var deck: Node3D = w.part(p, "Platform cart", at + Vector3(0, .3, 0), Vector3(.7, .06, 1.1), "9aa3ad", true, "trolley")
	w.part(deck, "Cart deck edge", Vector3(0, -.04, 0), Vector3(.72, .025, 1.12), W.FRAME)
	for corner in [Vector2(.27, .44), Vector2(-.27, .44), Vector2(.27, -.44), Vector2(-.27, -.44)]:
		w.part(deck, "Cart wheel fork", Vector3(corner.x, -.1, corner.y), Vector3(.05, .14, .05), W.STEEL)
		var wheel: MeshInstance3D = w.cylinder(deck, "Cart wheel", Vector3(corner.x, -.2, corner.y), .1, .06, "2d3138")
		wheel.rotation.z = PI / 2
	for side in [-.31, .31]:
		w.part(deck, "Cart handle post", Vector3(side, .45, .52), Vector3(.04, .9, .04), W.YELLOW)
	w.part(deck, "Cart handle bar", Vector3(0, .9, .52), Vector3(.66, .04, .04), W.YELLOW)
	var size := Vector3(.6, .32, .42)
	var base := at + Vector3(0, .33, -.15)
	var tint: String = W.BOX_COLORS.blue
	var bin: Node3D = w.part(p, "Container", base + Vector3(0, .02, 0), Vector3(size.x, .04, size.z), tint, false, "container")
	for spec in [[Vector3(0, size.y * .5, size.z * .5 - .015), Vector3(size.x, size.y, .03)], [Vector3(0, size.y * .5, -size.z * .5 + .015), Vector3(size.x, size.y, .03)], [Vector3(size.x * .5 - .015, size.y * .5, 0), Vector3(.03, size.y, size.z)], [Vector3(-size.x * .5 + .015, size.y * .5, 0), Vector3(.03, size.y, size.z)]]:
		w.part(bin, "Container wall", spec[0], spec[1], tint)

## The shelf rebuilt with two clear levels (21 Nov 2026, user: "the shelf should have clear two
## levels"): W.shelf() now ends at the top deck, with a back panel and painted places. The old
## shelf's parts are the Hall children inside its footprint.
func two_level_shelf(town: Node3D, game) -> void:
	var hall := town.get_node("Warehouse/Hall") as Node3D
	for child in hall.get_children():
		var at := (child as Node3D).position
		if absf(at.x - W.SHELF_AT.x) < W.RACK_LENGTH * .5 + .2 and absf(at.z - W.SHELF_AT.z) < W.RACK_DEPTH * .5 + .2:
			child.free()
	var w = W.new()
	w.game = game
	w.town = town
	w.materials()
	var before := hall.get_child_count()
	w.shelf(hall, W.SHELF_AT, W.RACK_LENGTH)
	for i in range(before, hall.get_child_count()):
		var node := hall.get_child(i)
		node.owner = town
		for inner in node.find_children("*", "", true, false):
			inner.owner = town

## The town warehouse's supply cabinet opens (user, 23 Nov 2026: the cabinets should open when no
## game is running). Its two doors (warehouse.gd supply_cabinet(), static parts) get hinges on
## their outer edges with a door_animator door_state (COMPONENTS.md "Things that open": E, a
## click or a tap) and a pick area each; the solid block's mesh gives way to a hollow carcass
## (back, sides, top, base, dark inside, two shelves with supplies) so an open door shows
## something. The cabinet's collision (word "cabinet") stays. The minigame copy builds its own
## cabinet from supply_cabinet() and keeps hinging it in warehouse_goods.gd.
const CABINET_OPEN := 1.75
func openable_cabinet(town: Node3D, game) -> void:
	var body := town.get_node("Warehouse/Hall/Supply cabinet") as Node3D
	var size := Vector3(1.8, 2.0, .6)
	var shell := Color("8a96a3")
	var dark := Color("4d5864")
	var hidden := 0
	for mesh in body.get_children():
		if mesh is MeshInstance3D:
			mesh.free()
			hidden += 1
	assert(hidden == 1, "openable_cabinet: expected the body's one mesh, found %d" % hidden)
	var parts := [
		["Cabinet back", Vector3(0, 0, size.z * .5 - .02), Vector3(size.x, size.y, .04), shell],
		["Cabinet side west", Vector3(size.x * .5 - .02, 0, 0), Vector3(.04, size.y, size.z), shell],
		["Cabinet side east", Vector3(-size.x * .5 + .02, 0, 0), Vector3(.04, size.y, size.z), shell],
		["Cabinet top", Vector3(0, size.y * .5 - .02, 0), Vector3(size.x, .04, size.z), shell],
		["Cabinet base", Vector3(0, -size.y * .5 + .05, 0), Vector3(size.x, .1, size.z), shell],
		["Cabinet inside", Vector3(0, 0, size.z * .5 - .045), Vector3(size.x - .1, size.y - .1, .01), dark],
		["Cabinet shelf", Vector3(0, -.3, .02), Vector3(size.x - .08, .03, size.z - .1), shell],
		["Cabinet shelf", Vector3(0, .35, .02), Vector3(size.x - .08, .03, size.z - .1), shell],
	]
	for spec in parts:
		_cabinet_part(game, body, spec[0], spec[1], spec[2], spec[3])
	# Supplies on the shelves and the base: tape rolls, boxes of labels, folded sheets.
	var supplies := [
		["Cabinet supply box", Vector3(-.55, -.17, .05), Vector3(.4, .23, .3), Color("c8a46e")],
		["Cabinet supply box", Vector3(-.1, -.2, .05), Vector3(.3, .17, .3), Color("3f74b5")],
		["Cabinet supply box", Vector3(.5, .49, .05), Vector3(.45, .25, .32), Color("c8a46e")],
		["Cabinet folded sheets", Vector3(-.45, .39, .05), Vector3(.5, .05, .34), Color("eef1f3")],
		["Cabinet folded sheets", Vector3(-.45, .44, .05), Vector3(.48, .05, .32), Color("f2c230")],
		["Cabinet supply box", Vector3(.45, -.76, .05), Vector3(.55, .28, .36), Color("4f9a4c")],
	]
	for spec in supplies:
		_cabinet_part(game, body, spec[0], spec[1], spec[2], spec[3])
	for tape_x in [.35, .55]:
		var roll: Node3D = game.cylinder("Cabinet tape roll", Vector3.ZERO, .08, .06, Color("d9534a"))
		roll.reparent(body, false)
		roll.position = Vector3(tape_x, -.255, 0)
	# The doors: a hinge on each outer edge; "Cabinet door west" (+x) and its handle turn with it.
	var hinged := 0
	for hand in ["west", "east"]:
		var door := body.get_node("Cabinet door " + hand) as Node3D
		var handle := body.get_node("Cabinet handle " + hand) as Node3D
		var side := signf(door.position.x)
		var hinge := Node3D.new()
		hinge.name = "Cabinet hinge " + hand
		hinge.position = Vector3(side * .88, 0, door.position.z)
		# The leaf lies toward -side from its hinge; turning by -side * angle brings it to -z (the hall).
		hinge.set_meta("door_state", {"open": false, "type": "hinge", "angle": -side * CABINET_OPEN})
		body.add_child(hinge)
		door.reparent(hinge, true)
		handle.reparent(hinge, true)
		var area := Area3D.new()
		area.name = "Cabinet door pick"
		area.set_meta("object_name", "Cabinet door")
		door.add_child(area)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(.87, 1.94, .04)
		shape.shape = box
		area.add_child(shape)
		hinged += 1
	print("openable_cabinet: hollow carcass, %d hinged doors" % hinged)

func _cabinet_part(game, parent: Node3D, title: String, pos: Vector3, size: Vector3, color: Color) -> Node3D:
	var part: Node3D = game.box(title, Vector3.ZERO, size, color, "", false)
	part.reparent(parent, false)
	part.position = pos
	return part

## Door sounds (user, 25 Nov 2026: "each door should have different sound"): the supply
## cabinet's two steel doors sound like a steel cabinet (door_animator.gd set_sound_kind; cues
## door.cabinet.* in data/sounds.json).
func door_sounds(town: Node3D, game) -> void:
	var DoorAnimator := preload("res://scripts/core/door_animator.gd")
	var cabinet: Node3D = town.get_node("Warehouse/Hall/Supply cabinet")
	var tagged := 0
	for path in ["Cabinet hinge west", "Cabinet hinge east"]:
		tagged += int(DoorAnimator.set_sound_kind(game, cabinet.get_node_or_null(path), "cabinet"))
	if tagged != 2:
		push_error("warehouse door_sounds: expected 2 doors, tagged %d" % tagged)
	print("WAREHOUSE door_sounds: %d doors" % tagged)
