extends RefCounted
## Chapel own script (docs/guides/MODULAR_TOWN.md, "Changing a building"): code steps for the
## chapel unit (scenes/town/chapel.scn).
## Bake:  godot --headless --path . --script res://tools/bake_unit.gd -- chapel
## Never rename or remove a baked step (add a new one that undoes it).
##
## Rebuild (user, 10 Nov 2026: "the interior and exterior look old ... fix everything"; the
## CHAPEL sign was hidden behind the portico lintel). Program: docs/guides/TOWN_DESIGN_BRIEF.md, chapel
## row (small traditional chapel, pitched roof, small bell tower, welcoming entrance; one open
## sanctuary with pews, central aisle, altar, cross, stained glass, candles, flowers, lectern).
## Same 10 x 12 footprint and position as before; only its height grew (pitched roof, belfry).
##
## Coordinates are site-local (RelocatedSites/Chapel; town units, Apartment scale 1.3 applies):
## the door faces local -Z (town south), +X is west. Outer walls x 41.5..51.5, z 69..81.
## Parts that make up the front (front wall, gable, rose window, door surround, sign, lanterns,
## bell tower) live under Map facades/CHAPEL in a holder that shares the site's frame: they show
## the exterior word "church" and carry no collision except the tower's RoofSolid
## (docs/evidence/town-checks/check_map_facades.gd); the front wall's collision is a thin body in the site, behind
## the glass, so a street ray still picks the facade.
const STEPS := ["solid_roofs", "coplanar_gaps", "coplanar_gaps_2", "rebuild", "grand_chapel", "inner_ladder", "palette_snap"]

const Geo := preload("res://scripts/buildings/mystery.gd")
const SITE := "RelocatedSites/Chapel"
const FACADE := "Map facades/CHAPEL"
const FRONT_HOLDER := "Chapel front"

const CX := 46.5
var ZC := 75.0
## Outer half width, wall thickness, front and rear outer faces.
var W2 := 5.0
const T := 0.3
var FRONT := 69.0
var REAR := 81.0
## Floor top (stone floor on the lawn; a hidden ramp climbs the entrance step).
const FLOOR := 0.15
## Wall top at the eaves; roof pitch 35 degrees (walkable: normal 0.82 > 0.7, check_rooftops).
var EAVE := 4.7
const PITCH := 0.6108652
const ROOF_T := 0.2
const OVER_X := 0.5
const OVER_Z := 0.4
## The sizes above that are `var` (W2, FRONT, REAR, ZC, EAVE, DAIS_Z, PEW_*, SIDE_OPENINGS, TRUSS_Z,
## TOWER_*) hold the 10 Nov 2026 values; step grand_chapel (21 Nov 2026) sets the bigger chapel's
## and rebuilds. Other positions are given relative to them.
## Door: width, spring of its round head (above the ground).
const DOOR_W := 2.0
const DOOR_SPRING := 2.25
## Chancel platform: front edge, height; the altar stands on it.
var DAIS_Z := 77.6
const DAIS_H := 0.3
## Bell tower (belfry and spire) over the front of the ridge.
var TOWER_Z := 70.45
var TOWER_W2 := 1.0
## Pew rows (centre z) and the centres of the two pew blocks either side of the aisle.
var PEW_ROWS := [71.35, 72.75, 74.15, 75.55]
var PEW_X := [43.9, 49.1]
var PEW_L := 3.1
## Openings [u along the wall, width, sill, spring] (round heads of radius width / 2).
const FRONT_OPENINGS := [[0.0, DOOR_W, 0.0, DOOR_SPRING], [-3.1, 0.9, 1.35, 2.75], [3.1, 0.9, 1.35, 2.75]]
var SIDE_OPENINGS := [[-3.6, 1.0, 1.6, 3.3], [0.0, 1.0, 1.6, 3.3], [3.6, 1.0, 1.6, 3.3]]
const REAR_OPENINGS := [[-2.9, 0.8, 1.9, 3.55], [2.9, 0.8, 1.9, 3.55]]
## Trusses (and the buttresses outside them).
var TRUSS_Z := [73.2, 76.8]

const WALL := Color("f3ecdd")
const TRIM := Color("fbf7ee")
const STONE := Color("d9cbaa")
const STONE_DARK := Color("b5a581")
const SLATE := Color("55667f")
const SLATE_DARK := Color("435268")
const TIMBER := Color("6e4a2f")
const WOOD := Color("a8743f")
const WOOD_DARK := Color("7f512c")
const CEILING_WOOD := Color("c99a63")
const FLOOR_STONE := Color("e2d6bd")
const DAIS_STONE := Color("efe7d4")
const RUNNER := Color("9e2f38")
const GOLD := Color("d9ad48")
const CLOTH := Color("faf6ec")
const DOSSAL := Color("7d2632")
const BRONZE := Color("a87a36")
const LEAF := Color("3f8a3a")
const SIGN_FRAME := Color("4a5a72")
const SIGN_FACE := Color("fbf6ea")
const LETTERS := Color("263e4d")
const WARM_LIGHT := Color("ffe7b0")
const PIPE := Color("bac3c4")
const GLASS := [Color("d03a3f"), Color("2f5fc4"), Color("2f9a5c"), Color("efb23a"), Color("8653c9")]
const BLOSSOMS := [Color("f4f1ea"), Color("ec6fa6"), Color("f4cf3a"), Color("e8506a")]
const NIGHT_LIGHTS := "night_lights"

## Flagpole (site x, z) and the tower kind: false = the 10 Nov belfry on the roof (_tower), true
## = the 21 Nov ground tower with its ladder and ringable bell (_bell_tower).
var flag_at := Vector2(40.3, 67.2)
var ground_tower := false
## Step inner_ladder (23 Nov 2026): the ladder climbs inside the hollow tower, entered from the nave.
var ladder_inside := false
var game
var geo: Geo
var site: Node3D
var facade: Node3D
var front: Node3D
var _materials := {}

## Collision for the decorative roofs and canopies (7 Nov 2026; scripts/buildings/roof_solids.gd).
func solid_roofs(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/roof_solids.gd").add(town, [
		"Map facades/CHAPEL/Faceted roof cap",
	])

## Faces that shared a plane and flickered are set apart (10 Nov 2026,
## scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "chapel")

## Second pass: faces a first move brought into a new plane, and labels widened for translated
## text (10 Nov 2026, scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps_2(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "chapel", 2)

## The whole chapel rebuilt (10 Nov 2026, see the header). The old shell, furniture and front are
## removed; the CHAPEL lettering is kept (its translations) and moved onto the new sign over the
## door, where nothing stands in front of it. Word keys kept: wall, roof, ceiling, church, pew,
## altar, candle, flame, lectern, donation box, slot, flag, step, tile; added: floor, window,
## door, rug, cross, book, flower, planter, ceiling light (all existing dictionary words).
func rebuild(town: Node3D, main) -> void:
	game = main
	geo = Geo.new()
	site = town.get_node(SITE)
	facade = town.get_node(FACADE)
	# The CHAPEL lettering: on the facade before the first rebuild, on the front holder's sign after.
	var lettering := facade.get_node_or_null("Facade lettering") as Label3D
	if lettering == null:
		lettering = facade.get_node(FRONT_HOLDER + "/Facade lettering") as Label3D
	lettering.get_parent().remove_child(lettering)
	for parent in [site, facade]:
		for child in parent.get_children():
			parent.remove_child(child)
			child.free()
	front = Node3D.new()
	front.name = FRONT_HOLDER
	facade.add_child(front)
	front.global_transform = site.global_transform
	_shell()
	_front()
	_roof()
	_ceiling()
	if ground_tower:
		_bell_tower()
	else:
		_tower()
	_sign(lettering)
	_nave()
	_chancel()
	_grounds()
	_exterior_picks(front)
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "chapel", 3)

## A bigger chapel with a bell tower you can climb (user, 21 Nov 2026: "increase the size of the
## chapel. add a ladder that user can climb up to the bell area ... make the bell ringable ...
## redesign the chapel so the top doesn't look overly big but still can fit the user's avatar").
## Same door position and front line (z 69, the garden path); 12.6 wide (was 10) and 15 deep (was
## 12, growing north); walls 5.2 high (were 4.7); five side windows, six rows of pews, the chancel
## moved back with the rear wall. The old belfry on the ridge (2 x 2, no way up) is replaced by a
## square tower standing on the ground at the front east corner, 3.6 x 3.6: a stone shaft to a
## belfry floor at 6.2, an open belfry (four arches, parapets 1.2 high, 3.0 high under a low
## pyramid roof and cross) and an iron ladder on its south face (group "ladders", climbed with
## W, stepping off forward through a gap in the south parapet). The bell hangs north of the middle
## (chapel_bell.gd: E, click or tap rings it; it swings and emits `rung` for a sound later). The
## Chapel's town stamp coin floats in the belfry (data/achievements.json).
const GRAND_W2 := 6.3
const GRAND_REAR := 84.0
const GRAND_EAVE := 5.2
## Ground tower: outer square [x0, x1] x [z0, z1] (site), belfry floor top, belfry height.
const BELL_TOWER := Rect2(36.9, 68.7, 3.6, 3.6)
const BELFRY_FLOOR := 6.2
const BELFRY_H := 3.0
const PARAPET_H := 1.2
const PIER := 0.45
## The gap in the south parapet over the ladder (BonBon is 1.52 m = 1.17 units wide).
const LADDER_GAP := 1.7

func grand_chapel(town: Node3D, main) -> void:
	W2 = GRAND_W2
	REAR = GRAND_REAR
	ZC = (FRONT + REAR) * 0.5
	EAVE = GRAND_EAVE
	DAIS_Z = REAR - 3.4
	PEW_L = 3.6
	PEW_X = [CX - 2.95, CX + 2.95]
	PEW_ROWS = [71.35, 72.75, 74.15, 75.55, 76.95, 78.35]
	SIDE_OPENINGS = [[-5.4, 1.0, 1.7, 3.6], [-2.7, 1.0, 1.7, 3.6], [0.0, 1.0, 1.7, 3.6], [2.7, 1.0, 1.7, 3.6], [5.4, 1.0, 1.7, 3.6]]
	TRUSS_Z = [73.9, 78.8]
	flag_at = Vector2(35.0, 67.3)
	ground_tower = true
	if ladder_inside:
		PEW_ROWS = PEW_ROWS.slice(2)
	rebuild(town, main)
	var tower := site.get_node("Bell tower") as Node3D
	print("CHAPEL grand_chapel: %.1f x %.1f, eave %.1f, tower %s, belfry floor %.1f" % [2 * W2, REAR - FRONT, EAVE, tower.position, BELFRY_FLOOR])

## The ladder moves inside (user, 23 Nov 2026: "I don't like the fact that the ladder is outside.
## Can you remove the last one or two rows of the chairs in the chapel and then add a ladder that
## would connect up to the bell"). The two pew rows nearest the door go (four rows left), the
## stained-glass window in the east wall's front bay (it only ever looked into the solid tower)
## becomes a round-headed doorway into the tower, and the tower is hollow: stone walls, a stone
## floor level with the chapel's, a lantern, and the iron ladder on the inside of its south wall
## climbing 6.09 to a hatch in a solid belfry floor (default ladder: step off backwards, north,
## onto the floor; walking into the hatch takes it down). The outside ladder and the gap in the
## south parapet are gone. Same footprint, belfry, bell and coin.
## Doorway [u along the east wall, width, sill, spring]: z 70.55..71.95, inside the tower's 69..72.
const TOWER_DOOR := [-5.25, 1.4, 0.0, 2.2]
## Tower wall thickness, and the belfry hatch over the ladder (tower x, z; local).
const TOWER_T := 0.3
const HATCH := Rect2(-0.75, -1.5, 1.5, 1.3)

func inner_ladder(town: Node3D, main) -> void:
	ladder_inside = true
	grand_chapel(town, main)
	var ladder := site.get_node("Bell tower/Tower ladder") as Node3D
	print("CHAPEL inner_ladder: %d pew rows, ladder at %s up %.2f" % [PEW_ROWS.size(), ladder.position, ladder.get_meta("ladder_height")])

# --- Shell ------------------------------------------------------------------------------------

## Roof top surface height at distance d from the ridge line, and its underside.
func _roof_top(d: float) -> float:
	return EAVE + ROOF_T / cos(PITCH) + (W2 - d) * tan(PITCH)

func _roof_under(d: float) -> float:
	return _roof_top(d) - ROOF_T / cos(PITCH)

func _shell() -> void:
	# Stone floor (the old chapel stood on the lawn) with the threshold in the door.
	var floor_root := _box(site, "Chapel floor", Vector3(CX, (FLOOR - 0.05) * 0.5, ZC), Vector3(2 * (W2 - T), FLOOR + 0.05, REAR - FRONT - 2 * T), FLOOR_STONE, true, "floor")
	_box(floor_root, "Threshold", Vector3(0, 0, FRONT + T * 0.5 - ZC), Vector3(DOOR_W, FLOOR + 0.05, T), STONE, true)
	# Side and rear walls (word "wall"), each in a frame: local x along the wall, +z outward.
	var side_len := REAR - FRONT - 2 * T
	var west := _wall(site, "Chapel side wall", Transform3D(Basis(Vector3.FORWARD, Vector3.UP, Vector3.RIGHT), Vector3(CX + W2 - T * 0.5, 0, ZC)), side_len * 0.5, EAVE + 0.2, SIDE_OPENINGS, true)
	var east_openings := _east_openings()
	var east := _wall(site, "Chapel side wall2", Transform3D(Basis(Vector3.BACK, Vector3.UP, Vector3.LEFT), Vector3(CX - W2 + T * 0.5, 0, ZC)), side_len * 0.5, EAVE + 0.2, east_openings, true)
	var rear := _wall(site, "Chapel rear wall", Transform3D(Basis(Vector3.RIGHT, Vector3.UP, Vector3.BACK), Vector3(CX, 0, REAR - T * 0.5)), W2, EAVE, REAR_OPENINGS, true)
	for wall in [west, east, rear]:
		wall.set_meta("word_key", "wall")
		# Plinth course outside and wainscot inside.
		var half: float = W2 if wall == rear else side_len * 0.5 + (T if wall != rear else 0.0)
		var inner: float = side_len * 0.5 if wall != rear else W2 - T
		# On the east wall with the tower doorway these three strips stop either side of it.
		var gap: Array = [TOWER_DOOR[0] - TOWER_DOOR[1] * 0.5, TOWER_DOOR[0] + TOWER_DOOR[1] * 0.5] if wall == east and ladder_inside else []
		_strip(wall, "Plinth", -half, half, gap, Vector3(0, 0.22, T * 0.5 + 0.04), Vector2(0.44, 0.08), STONE_DARK)
		_strip(wall, "Wainscot", -inner, inner, gap, Vector3(0, FLOOR + 0.475, -T * 0.5 - 0.02), Vector2(0.95, 0.04), WOOD)
		_strip(wall, "Chair rail", -inner, inner, gap, Vector3(0, FLOOR + 0.98, -T * 0.5 - 0.04), Vector2(0.07, 0.08), WOOD_DARK)
	# Stained glass in every window (not the tower doorway).
	for o in SIDE_OPENINGS:
		_glass(west, o, 0.06)
	for o in east_openings:
		if o[2] > 0.01:
			_glass(east, o, 0.06)
	for o in REAR_OPENINGS:
		_glass(rear, o, 0.06)
	# Rear gable and string course (inside the roof's ends; no collision needed above the eaves).
	var rear_gable := geo._prism([Vector2(-W2, EAVE), Vector2(W2, EAVE), Vector2(0, _roof_under(0))], T)
	_mesh(site, "Rear gable", rear_gable, Transform3D(Basis(), Vector3(CX, 0, REAR - T * 0.5)), _mat(WALL))
	_box(site, "Rear string course", Vector3(CX, EAVE + 0.08, REAR + 0.06), Vector3(2 * W2 + 0.24, 0.16, 0.12), STONE, false)
	# Buttresses: stepped stone piers at the corners and under each truss.
	var piers := _group(site, "Buttresses")
	for side in [-1.0, 1.0]:
		for z in [FRONT + 0.25] + TRUSS_Z + [REAR - 0.25]:
			var x: float = CX + side * W2
			if ground_tower and side < 0 and z < FRONT + 0.5:
				continue
			_box(piers, "Buttress", Vector3(x + side * 0.27, 1.1, z), Vector3(0.55, 2.2, 0.5), STONE, true)
			_box(piers, "Buttress upper", Vector3(x + side * 0.17, 2.9, z), Vector3(0.34, 1.4, 0.42), STONE, true)
			_box(piers, "Buttress cap", Vector3(x + side * 0.12, 3.68, z), Vector3(0.3, 0.12, 0.46), STONE_DARK, false, "", Basis(Vector3.BACK, -side * 0.6))
	# The front wall's collision: thin, behind the facade glass, with the doorway open.
	var body := _body(site, "Front wall body")
	var wz := FRONT + T - 0.05
	var side_w := W2 - DOOR_W * 0.5
	_shape(body, Vector3(CX - DOOR_W * 0.5 - side_w * 0.5, EAVE * 0.5, wz), Vector3(side_w, EAVE, 0.1))
	_shape(body, Vector3(CX + DOOR_W * 0.5 + side_w * 0.5, EAVE * 0.5, wz), Vector3(side_w, EAVE, 0.1))
	_shape(body, Vector3(CX, (DOOR_SPRING + EAVE) * 0.5, wz), Vector3(DOOR_W, EAVE - DOOR_SPRING, 0.1))
	# Front wainscot inside, either side of the door.
	for side in [-1.0, 1.0]:
		var w := W2 - T - DOOR_W * 0.5
		var x: float = CX + side * (DOOR_W * 0.5 + w * 0.5)
		_box(site, "Front wainscot", Vector3(x, FLOOR + 0.475, FRONT + T + 0.02), Vector3(w, 0.95, 0.04), WOOD, false)
		_box(site, "Front chair rail", Vector3(x, FLOOR + 0.98, FRONT + T + 0.04), Vector3(w, 0.07, 0.08), WOOD_DARK, false)

## A wall in `frame` (local x along it from -half to half, y up from the ground, +z outward,
## centred on its mid-plane), y1 high, T thick, with round-headed openings [u, width, sill,
## spring]. Pieces are boxes; the panel over each opening has the round head cut out.
## The east wall's openings: the side windows, or (ladder_inside) the front bay's window replaced by
## the tower doorway.
func _east_openings() -> Array:
	if not ladder_inside:
		return SIDE_OPENINGS
	var list := [TOWER_DOOR]
	for o in SIDE_OPENINGS:
		if absf(o[0] - TOWER_DOOR[0]) > 1.0:
			list.append(o)
	return list

## A strip along a wall frame from u0 to u1 at `at` (y, z), size (height, depth); `gap` [a, b] is
## left open.
func _strip(wall: Node3D, title: String, u0: float, u1: float, gap: Array, at: Vector3, size: Vector2, color: Color) -> void:
	var spans := [[u0, u1]] if gap.is_empty() else [[u0, gap[0]], [gap[1], u1]]
	for s in spans:
		if s[1] - s[0] > 0.01:
			_box(wall, title, Vector3((s[0] + s[1]) * 0.5, at.y, at.z), Vector3(s[1] - s[0], size.x, size.y), color, false)

func _wall(parent: Node3D, title: String, frame: Transform3D, half: float, y1: float, openings: Array, solid: bool) -> Node3D:
	var holder := _group(parent, title)
	holder.transform = frame
	var cursor := -half
	var sorted := openings.duplicate()
	sorted.sort_custom(func(a, b): return a[0] < b[0])
	for o in sorted:
		var r: float = o[1] * 0.5
		var left: float = o[0] - r
		if left > cursor + 0.01:
			_box(holder, "Wall", Vector3((cursor + left) * 0.5, y1 * 0.5, 0), Vector3(left - cursor, y1, T), WALL, solid)
		if o[2] > 0.01:
			_box(holder, "Wall under", Vector3(o[0], o[2] * 0.5, 0), Vector3(o[1], o[2], T), WALL, solid)
		var top: float = y1 - o[3]
		_mesh(holder, "Wall arch", geo._arch_panel(r, r, top, T), Transform3D(Basis(), Vector3(o[0], o[3], 0)), _mat(WALL))
		if solid and top > r + 0.02:
			_shape(_body(holder, "Wall arch body"), Vector3(o[0], o[3] + r + (top - r) * 0.5, 0), Vector3(o[1], top - r, T))
		# Stone reveal round the head and a sill, both faces.
		_mesh(holder, "Arch stones", geo._half_ring(r + 0.01, r + 0.15, T + 0.04), Transform3D(Basis(), Vector3(o[0], o[3], 0)), _mat(STONE))
		if o[2] > 0.01:
			_box(holder, "Sill", Vector3(o[0], o[2] - 0.04, 0), Vector3(o[1] + 0.24, 0.1, T + 0.16), STONE, false)
		cursor = o[0] + r
	if half > cursor + 0.01:
		_box(holder, "Wall", Vector3((cursor + half) * 0.5, y1 * 0.5, 0), Vector3(half - cursor, y1, T), WALL, solid)
	return holder

## Stained glass filling opening `o` of a wall frame: 2 x 3 coloured panes with lead cames and a
## round head (word "window"). Panes are solid so the opening stays closed (not on the front:
## facade parts have no collision; the site's front wall body closes it).
func _glass(holder: Node3D, o: Array, depth: float, solid := true) -> void:
	var r: float = o[1] * 0.5
	var h: float = o[3] - o[2]
	var root := _word(holder, "Stained glass window", "window", Vector3(o[0], 0, 0))
	for row in 3:
		for col in 2:
			var pane := _box(root, "Glass", Vector3((col - 0.5) * r, o[2] + h * (row + 0.5) / 3.0, 0), Vector3(r, h / 3.0, depth), GLASS[0], solid)
			_paint(pane, _glow(GLASS[(row + col * 2 + int(o[0] * 3.0)) % GLASS.size()], 0.35))
	_mesh(root, "Glass head", geo._half_disc(r, depth), Transform3D(Basis(), Vector3(0, o[3], 0)), _glow(GLASS[3], 0.4))
	_mesh(root, "Glass rose", geo._disc(r * 0.35, depth + 0.02, 16, true), Transform3D(Basis(), Vector3(0, o[3] + r * 0.4, 0)), _glow(GLASS[0], 0.45))
	var lead := _mat(Color("2b2b33"))
	_mesh(root, "Came", _bm(Vector3(0.04, h, depth + 0.03)), Transform3D(Basis(), Vector3(0, o[2] + h * 0.5, 0)), lead)
	for row in [1, 2, 3]:
		_mesh(root, "Came", _bm(Vector3(o[1], 0.04, depth + 0.03)), Transform3D(Basis(), Vector3(0, o[2] + h * row / 3.0, 0)), lead)
	_mesh(root, "Came arch", geo._arc_tube(Vector3(0, o[3], 0), Vector3.RIGHT, Vector3.UP, r * 0.62, 0.0, PI, 0.025, 12), Transform3D(), lead)

# --- Front (facade: exterior word "church") ---------------------------------------------------

func _front() -> void:
	var frame := Transform3D(Basis(Vector3.LEFT, Vector3.UP, Vector3.FORWARD), Vector3(CX, 0, FRONT + T * 0.5))
	var wall := _wall(front, "Front wall", frame, W2, EAVE, FRONT_OPENINGS, false)
	for o in FRONT_OPENINGS.slice(1):
		_glass(wall, o, 0.06, false)
	_box(wall, "Plinth", Vector3(-(W2 + DOOR_W * 0.5 + 0.26) * 0.5, 0.22, T * 0.5 + 0.04), Vector3(W2 - DOOR_W * 0.5 - 0.26, 0.44, 0.08), STONE_DARK, false)
	_box(wall, "Plinth", Vector3((W2 + DOOR_W * 0.5 + 0.26) * 0.5, 0.22, T * 0.5 + 0.04), Vector3(W2 - DOOR_W * 0.5 - 0.26, 0.44, 0.08), STONE_DARK, false)
	# Gable with the rose window; string course under it, bargeboards on its edges.
	var gable := geo._prism([Vector2(-W2, EAVE), Vector2(W2, EAVE), Vector2(0, _roof_under(0))], T)
	_mesh(front, "Front gable", gable, Transform3D(Basis(), Vector3(CX, 0, FRONT + T * 0.5)), _mat(WALL))
	_box(front, "String course", Vector3(CX, EAVE + 0.08, FRONT - 0.06), Vector3(2 * W2 + 0.24, 0.16, 0.12), STONE, false)
	_rose(Vector3(CX, EAVE + 1.45, FRONT + T * 0.5))
	# Door surround: stone jambs, arch and keystone; a fanlight in the round head.
	var r := DOOR_W * 0.5
	for side in [-1.0, 1.0]:
		_box(front, "Door jamb", Vector3(CX + side * (r + 0.12), DOOR_SPRING * 0.5, FRONT - 0.06), Vector3(0.24, DOOR_SPRING, 0.12), STONE, false)
	_mesh(front, "Door arch", geo._half_ring(r, r + 0.24, 0.12), Transform3D(Basis(), Vector3(CX, DOOR_SPRING, FRONT - 0.06)), _mat(STONE))
	_box(front, "Keystone", Vector3(CX, DOOR_SPRING + r + 0.17, FRONT - 0.08), Vector3(0.3, 0.36, 0.16), STONE_DARK, false)
	_box(front, "Transom", Vector3(CX, DOOR_SPRING, FRONT + T * 0.5), Vector3(DOOR_W, 0.1, T * 0.7), TIMBER, false)
	_mesh(front, "Fanlight", geo._half_disc(r - 0.02, 0.06), Transform3D(Basis(), Vector3(CX, DOOR_SPRING + 0.05, FRONT + T * 0.5)), _glow(GLASS[3], 0.4))
	for k: int in [1, 2, 3]:
		var a := PI * k / 4.0
		_mesh(front, "Fanlight came", _bm(Vector3(0.04, r - 0.05, 0.09)), Transform3D(Basis(Vector3.BACK, a - PI / 2), Vector3(CX, DOOR_SPRING + 0.05, FRONT + T * 0.5) + Vector3(cos(a), sin(a), 0) * (r - 0.05) * 0.5), _mat(Color("2b2b33")))
	# Lanterns either side of the door (they glow at night).
	for side in [-1.0, 1.0]:
		_lantern(front, Vector3(CX + side * 1.65, 2.6, FRONT - 0.26))

func _rose(at: Vector3) -> void:
	var rose := _group(front, "Rose window")
	rose.position = at
	_mesh(rose, "Rose stones", geo._arc_tube(Vector3.ZERO, Vector3.RIGHT, Vector3.UP, 0.93, 0.0, TAU, 0.1, 32), Transform3D(Basis(), Vector3(0, 0, -T * 0.5 - 0.02)), _mat(STONE))
	_mesh(rose, "Rose glass", geo._disc(0.86, T + 0.04, 32, true), Transform3D(), _glow(GLASS[1], 0.4))
	for k in 8:
		var a := TAU * k / 8.0
		_mesh(rose, "Rose petal", geo._disc(0.17, T + 0.07, 16, true), Transform3D(Basis(), Vector3(cos(a), sin(a), 0) * 0.52), _glow(GLASS[0] if k % 2 == 0 else GLASS[3], 0.45))
	for k in 4:
		_mesh(rose, "Rose came", _bm(Vector3(0.05, 1.72, T + 0.05)), Transform3D(Basis(Vector3.BACK, PI * k / 4.0), Vector3.ZERO), _mat(Color("2b2b33")))
	_mesh(rose, "Rose heart", geo._disc(0.2, T + 0.1, 16, true), Transform3D(), _glow(GLASS[2], 0.5))

func _lantern(parent: Node3D, at: Vector3) -> void:
	var lamp := _group(parent, "Door lantern")
	lamp.position = at
	var iron := Color("2f3238")
	_box(lamp, "Lantern bracket", Vector3(0, 0.26, 0.13), Vector3(0.05, 0.05, 0.26), iron, false)
	_box(lamp, "Lantern base", Vector3(0, -0.18, 0), Vector3(0.24, 0.05, 0.24), iron, false)
	var glass := _box(lamp, "Lantern glass", Vector3.ZERO, Vector3(0.19, 0.3, 0.19), WARM_LIGHT, false)
	glass.add_to_group(NIGHT_LIGHTS, true)
	var cap := CylinderMesh.new()
	cap.top_radius = 0.02
	cap.bottom_radius = 0.19
	cap.height = 0.16
	cap.radial_segments = 4
	cap.rings = 1
	_mesh(lamp, "Lantern cap", cap, Transform3D(Basis(Vector3.UP, PI / 4), Vector3(0, 0.23, 0)), _mat(iron))

# --- Roof and ceiling -------------------------------------------------------------------------

func _roof() -> void:
	var roof := _group(site, "Roof")
	var half_l := (W2 + OVER_X) * 0.5
	var length := (W2 + OVER_X) / cos(PITCH)
	var depth := REAR - FRONT + 2 * OVER_Z
	for side in [1.0, -1.0]:
		var basis := Basis(Vector3.BACK, -side * PITCH)
		var normal := Vector3(side * sin(PITCH), cos(PITCH), 0)
		var top := Vector3(CX + side * half_l, _roof_top(half_l), ZC)
		var title := "Chapel roof" if side > 0 else "Chapel roof2"
		_box(roof, title, top - normal * ROOF_T * 0.5, Vector3(length, ROOF_T, depth), SLATE, true, "roof", basis)
		# Slate courses along the slope, a fascia board at the eaves, bargeboards at both gables.
		for k in range(1, 6):
			var d := (W2 + OVER_X) * k / 6.0
			_box(roof, "Slate course", Vector3(CX + side * d, _roof_top(d) + 0.015, ZC), Vector3(0.05, 0.04, depth), SLATE_DARK, false, "", basis)
		var low := W2 + OVER_X
		_box(roof, "Fascia", Vector3(CX + side * low, _roof_top(low) - 0.12, ZC), Vector3(0.08, 0.26, depth), TRIM, false)
		for z in [FRONT - OVER_Z - 0.04, REAR + OVER_Z + 0.04]:
			var board := top - normal * 0.08
			board.z = z
			var parent: Node3D = front if z < ZC else roof
			_box(parent, "Bargeboard", board, Vector3(length, 0.3, 0.08), TRIM, false, "", basis)
	_box(roof, "Ridge cap", Vector3(CX, _roof_top(0) + 0.03, ZC), Vector3(0.34, 0.14, depth + 0.08), SLATE_DARK, false)

## Warm timber boarding under both slopes (word "ceiling"), a ridge beam and two trusses with
## the chandeliers hanging from their tie beams.
func _ceiling() -> void:
	var inner := W2 - T
	var length := inner / cos(PITCH)
	var depth := REAR - FRONT - 2 * T
	var holder := _group(site, "Ceiling timbers")
	for side in [1.0, -1.0]:
		var basis := Basis(Vector3.BACK, -side * PITCH)
		var normal := Vector3(side * sin(PITCH), cos(PITCH), 0)
		var d := inner * 0.5
		var at := Vector3(CX + side * d, _roof_under(d), ZC) - normal * 0.06
		_box(site, "Ceiling" if side > 0 else "Ceiling2", at, Vector3(length, 0.06, depth), CEILING_WOOD, false, "ceiling", basis)
		for z in TRUSS_Z:
			var rafter := Vector3(CX + side * d, _roof_under(d), z) - normal * 0.2
			_box(holder, "Truss rafter", rafter, Vector3(length, 0.22, 0.2), TIMBER, false, "", basis)
			# Strut from the king post's foot up to the rafter's middle.
			var foot := Vector2(0.1, EAVE + 0.17)
			var head := Vector2(d, _roof_under(d) - 0.3)
			var lean := atan2(head.x - foot.x, head.y - foot.y)
			var mid := (foot + head) * 0.5
			_box(holder, "Truss strut", Vector3(CX + side * mid.x, mid.y, z), Vector3(0.14, foot.distance_to(head), 0.16), TIMBER, false, "", Basis(Vector3.BACK, -side * lean))
	var apex := _roof_under(0) - 0.09
	_box(holder, "Ridge beam", Vector3(CX, apex - 0.15, ZC), Vector3(0.22, 0.26, depth), TIMBER, false)
	for z in TRUSS_Z:
		_box(holder, "Truss tie beam", Vector3(CX, EAVE + 0.05, z), Vector3(2 * inner, 0.24, 0.22), TIMBER, false)
		_box(holder, "Truss king post", Vector3(CX, (EAVE + apex) * 0.5, z), Vector3(0.2, apex - EAVE, 0.2), TIMBER, false)
		_chandelier(Vector3(CX, 3.45, z))

func _chandelier(at: Vector3) -> void:
	var hub := _cyl(site, "Chandelier", at, 0.08, 0.26, GOLD, "ceiling light")
	var chain_h := EAVE + 0.05 - 0.12 - at.y
	_mesh(hub, "Chandelier chain", _cyl_mesh(0.018, chain_h), Transform3D(Basis(), Vector3(0, chain_h * 0.5, 0)), _mat(BRONZE))
	_mesh(hub, "Chandelier ring", geo._arc_tube(Vector3.ZERO, Vector3.RIGHT, Vector3.BACK, 0.55, 0.0, TAU, 0.03, 28), Transform3D(Basis(), Vector3(0, -0.08, 0)), _mat(GOLD))
	for k in 6:
		var a := TAU * k / 6.0
		var p := Vector3(cos(a) * 0.55, -0.08, sin(a) * 0.55)
		_mesh(hub, "Chandelier arm", _bm(Vector3(0.55, 0.025, 0.025)), Transform3D(Basis(Vector3.UP, -a), p * 0.5), _mat(GOLD))
		_mesh(hub, "Chandelier cup", _cyl_mesh(0.05, 0.04), Transform3D(Basis(), p + Vector3(0, 0.03, 0)), _mat(GOLD))
		_mesh(hub, "Chandelier candle", _cyl_mesh(0.025, 0.14), Transform3D(Basis(), p + Vector3(0, 0.12, 0)), _mat(CLOTH))
		var bulb := _mesh(hub, "Chandelier bulb", _sphere_mesh(0.045), Transform3D(Basis().scaled(Vector3(0.8, 1.4, 0.8)), p + Vector3(0, 0.23, 0)), _mat(WARM_LIGHT))
		bulb.add_to_group(NIGHT_LIGHTS, true)

# --- Bell tower -------------------------------------------------------------------------------

## A small square belfry over the front of the ridge: stone shaft, four open round arches with the
## bell inside, cornice, slate spire and a gold cross. Collision: one RoofSolid body.
func _tower() -> void:
	var tower := _group(front, "Bell tower")
	tower.position = Vector3(CX, 0, TOWER_Z)
	var w := 2 * TOWER_W2
	var shaft_y0 := 7.6
	var belfry_y0 := 9.06
	var belfry_h := 1.9
	_box(tower, "Tower shaft", Vector3(0, (shaft_y0 + 9.0) * 0.5, 0), Vector3(w, 9.0 - shaft_y0, w), WALL, false)
	_box(tower, "Tower band", Vector3(0, 9.0, 0), Vector3(w + 0.16, 0.12, w + 0.16), STONE, false)
	_box(tower, "Belfry floor", Vector3(0, belfry_y0, 0), Vector3(w - 0.1, 0.1, w - 0.1), STONE_DARK, false)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_box(tower, "Belfry post", Vector3(sx * (TOWER_W2 - 0.16), belfry_y0 + belfry_h * 0.5, sz * (TOWER_W2 - 0.16)), Vector3(0.32, belfry_h, 0.32), WALL, false)
	var opening := TOWER_W2 - 0.32
	for k in 4:
		var face := _group(tower, "Belfry arch")
		face.transform = Transform3D(Basis(Vector3.UP, PI * k / 2.0), Vector3(0, belfry_y0 + 1.0, 0)).translated_local(Vector3(0, 0, TOWER_W2 - 0.08))
		_mesh(face, "Belfry spandrel", geo._arch_panel(opening, opening, belfry_h - 1.0, 0.14), Transform3D(), _mat(WALL))
		_mesh(face, "Belfry arch stones", geo._half_ring(opening, opening + 0.1, 0.18), Transform3D(), _mat(STONE))
		_box(face, "Belfry rail", Vector3(0, -0.62, 0.02), Vector3(2 * opening, 0.08, 0.1), STONE, false)
	_box(tower, "Belfry cornice", Vector3(0, belfry_y0 + belfry_h + 0.11, 0), Vector3(w + 0.4, 0.22, w + 0.4), STONE, false)
	var spire_y0 := belfry_y0 + belfry_h + 0.22
	var spire := CylinderMesh.new()
	spire.top_radius = 0.03
	spire.bottom_radius = (TOWER_W2 + 0.15) * sqrt(2.0)
	spire.height = 3.1
	spire.radial_segments = 4
	spire.rings = 1
	var spire_xf := Transform3D(Basis(Vector3.UP, PI / 4), Vector3(0, spire_y0 + 1.55, 0))
	_mesh(tower, "Spire", spire, spire_xf, _mat(SLATE))
	var top := spire_y0 + 3.1
	_box(tower, "Spire cross", Vector3(0, top + 0.5, 0), Vector3(0.13, 1.1, 0.13), GOLD, false)
	_box(tower, "Spire cross bar", Vector3(0, top + 0.7, 0), Vector3(0.62, 0.13, 0.13), GOLD, false)
	# The bell on its headstock.
	_box(tower, "Bell headstock", Vector3(0, belfry_y0 + 1.25, 0), Vector3(w - 0.4, 0.14, 0.16), TIMBER, false)
	var bell := CylinderMesh.new()
	bell.top_radius = 0.2
	bell.bottom_radius = 0.4
	bell.height = 0.52
	_mesh(tower, "Bell", bell, Transform3D(Basis(), Vector3(0, belfry_y0 + 0.92, 0)), _mat(BRONZE))
	_mesh(tower, "Bell crown", _sphere_mesh(0.2), Transform3D(Basis(), Vector3(0, belfry_y0 + 1.12, 0)), _mat(BRONZE))
	_mesh(tower, "Bell clapper", _sphere_mesh(0.08), Transform3D(Basis(), Vector3(0, belfry_y0 + 0.6, 0)), _mat(Color("5a4632")))
	# Collision for the whole tower (above head height, check_map_facades.gd).
	var solid := StaticBody3D.new()
	solid.name = "RoofSolid"
	tower.add_child(solid)
	_shape(solid, Vector3(0, (shaft_y0 + spire_y0) * 0.5, 0), Vector3(w, spire_y0 - shaft_y0, w))
	var spire_shape := CollisionShape3D.new()
	spire_shape.shape = spire.create_convex_shape()
	spire_shape.transform = spire_xf
	solid.add_child(spire_shape)

## The 21 Nov 2026 bell tower (grand_chapel): on the ground at the front east corner, in the site
## (solid), its own frame centred on the square. Local +z is north; the ladder is on the south (-z)
## face. Pieces: shaft (solid, with plinth, a string course at the eaves and a slit window),
## belfry floor, four corner piers, parapets (solid; a gap over the ladder), round arches over the
## four openings, cornice, ceiling slab (solid), a low slate pyramid with a gold cross, the bell
## and its rope, the ladder.
func _bell_tower() -> void:
	var r := BELL_TOWER
	var half := r.size.x * 0.5
	var tower := _group(site, "Bell tower")
	tower.position = Vector3(r.position.x + half, 0, r.position.y + half)
	var top := BELFRY_FLOOR + BELFRY_H
	# Shaft (word "wall") up to the belfry floor: solid, or (ladder_inside) hollow.
	if ladder_inside:
		_hollow_shaft(tower, half)
	else:
		_box(tower, "Tower shaft", Vector3(0, BELFRY_FLOOR * 0.5, 0), Vector3(2 * half, BELFRY_FLOOR, 2 * half), WALL, true, "wall")
	if ladder_inside:
		# Rings round the outside, so the hollow shaft and the hatch stay open (no plinth in the
		# doorway on the chapel side).
		_ring(tower, "Tower plinth", 0.25, 0.5, half + 0.06, half, STONE_DARK, false)
		_ring(tower, "Tower string course", EAVE + 0.08, 0.16, half + 0.08, half, STONE)
		_ring(tower, "Tower floor band", BELFRY_FLOOR - 0.06, 0.14, half + 0.1, half, STONE)
	else:
		_box(tower, "Tower plinth", Vector3(0, 0.25, 0), Vector3(2 * half + 0.12, 0.5, 2 * half + 0.12), STONE_DARK, false)
		_box(tower, "Tower string course", Vector3(0, EAVE + 0.08, 0), Vector3(2 * half + 0.16, 0.16, 2 * half + 0.16), STONE, false)
		_box(tower, "Tower floor band", Vector3(0, BELFRY_FLOOR - 0.06, 0), Vector3(2 * half + 0.2, 0.14, 2 * half + 0.2), STONE, false)
	for face in [Vector3(-1, 0, 0), Vector3(0, 0, -1)]:
		# A narrow round-headed slit window on the east and south faces (dark glass).
		var at: Vector3 = face * (half + 0.01) + Vector3(0, 3.4, 0)
		var basis := Basis(Vector3.UP, atan2(face.x, face.z))
		_mesh(tower, "Tower slit", _bm(Vector3(0.36, 1.1, 0.04)), Transform3D(basis, at), _mat(Color("33414c")))
		_mesh(tower, "Tower slit head", geo._half_disc(0.18, 0.04), Transform3D(basis, at + Vector3(0, 0.55, 0)), _mat(Color("33414c")))
		_mesh(tower, "Tower slit stones", geo._half_ring(0.18, 0.3, 0.06), Transform3D(basis, at + Vector3(0, 0.55, 0)), _mat(STONE))
	# Belfry floor (word "floor": stone flags over the shaft; ladder_inside: solid, round the hatch).
	if ladder_inside:
		_belfry_floor(tower, half)
	else:
		_box(tower, "Belfry floor", Vector3(0, BELFRY_FLOOR + 0.02, 0), Vector3(2 * half - 0.1, 0.04, 2 * half - 0.1), STONE_DARK, false, "floor")
	# Corner piers.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_box(tower, "Belfry pier", Vector3(sx * (half - PIER * 0.5), BELFRY_FLOOR + BELFRY_H * 0.5, sz * (half - PIER * 0.5)), Vector3(PIER, BELFRY_H, PIER), WALL, true)
	# Parapets between the piers (solid), the south one split by the ladder gap.
	var span := 2 * half - 2 * PIER
	var py := BELFRY_FLOOR + PARAPET_H * 0.5
	var pt := 0.3
	for k in 4:
		var basis := Basis(Vector3.UP, PI * k / 2.0)
		var out: Vector3 = basis * Vector3(0, 0, half - pt * 0.5)
		if k == 2 and not ladder_inside:
			# South (-z): two short pieces either side of the gap over the ladder.
			var piece := (span - LADDER_GAP) * 0.5
			for side in [-1.0, 1.0]:
				_box(tower, "Belfry parapet", Vector3(side * (LADDER_GAP + piece) * 0.5, py, out.z), Vector3(piece, PARAPET_H, pt), WALL, true, "", basis)
				_box(tower, "Parapet coping", Vector3(side * (LADDER_GAP + piece) * 0.5, BELFRY_FLOOR + PARAPET_H + 0.04, out.z), Vector3(piece + 0.04, 0.08, pt + 0.1), STONE, false, "", basis)
		else:
			_box(tower, "Belfry parapet", Vector3(out.x, py, out.z), Vector3(span, PARAPET_H, pt), WALL, true, "", basis)
			_box(tower, "Parapet coping", Vector3(out.x, BELFRY_FLOOR + PARAPET_H + 0.04, out.z), Vector3(span + 0.04, 0.08, pt + 0.1), STONE, false, "", basis)
		# The round arch over the opening (decoration; the spandrel closes the top corners).
		var opening := span * 0.5
		var spring := top - opening - 0.12
		var face := _group(tower, "Belfry arch")
		face.transform = Transform3D(basis, Vector3(0, spring, 0)).translated_local(Vector3(0, 0, half - 0.08))
		_mesh(face, "Belfry spandrel", geo._arch_panel(opening, opening, top - spring, 0.16), Transform3D(), _mat(WALL))
		_mesh(face, "Belfry arch stones", geo._half_ring(opening, opening + 0.1, 0.2), Transform3D(), _mat(STONE))
	# Cornice, a solid ceiling slab, the pyramid roof and the cross.
	_box(tower, "Belfry cornice", Vector3(0, top + 0.11, 0), Vector3(2 * half + 0.4, 0.22, 2 * half + 0.4), STONE, false)
	_box(tower, "Belfry ceiling", Vector3(0, top - 0.04, 0), Vector3(2 * half - 0.1, 0.08, 2 * half - 0.1), CEILING_WOOD, true, "ceiling")
	var roof_h := 2.0
	var spire := CylinderMesh.new()
	spire.top_radius = 0.03
	spire.bottom_radius = (half + 0.2) * sqrt(2.0)
	spire.height = roof_h
	spire.radial_segments = 4
	spire.rings = 1
	var spire_xf := Transform3D(Basis(Vector3.UP, PI / 4), Vector3(0, top + 0.22 + roof_h * 0.5, 0))
	var spire_mesh := _mesh(tower, "Tower roof", spire, spire_xf, _mat(SLATE))
	spire_mesh.set_meta("word_key", "roof")
	var peak := top + 0.22 + roof_h
	_box(tower, "Tower cross", Vector3(0, peak + 0.45, 0), Vector3(0.12, 1.0, 0.12), GOLD, false)
	_box(tower, "Tower cross bar", Vector3(0, peak + 0.62, 0), Vector3(0.56, 0.12, 0.12), GOLD, false)
	var roof_body := _body(tower, "Tower roof body")
	var roof_shape := CollisionShape3D.new()
	roof_shape.shape = spire.create_convex_shape()
	roof_shape.transform = spire_xf
	roof_body.add_child(roof_shape)
	# The bell: a headstock beam east-west across the belfry, the bell on a pivot under it.
	var beam_y := top - 0.42
	var bell_z := 0.35
	_box(tower, "Bell headstock", Vector3(0, beam_y, bell_z), Vector3(2 * half - 0.2, 0.16, 0.18), TIMBER, false)
	var bell := Node3D.new()
	bell.name = "Chapel bell"
	bell.set_script(preload("res://scripts/world/chapel_bell.gd"))
	bell.set_meta("word_key", "bell")
	tower.add_child(bell, true)
	bell.position = Vector3(0, beam_y - 0.08, bell_z)
	var cup := CylinderMesh.new()
	cup.top_radius = 0.22
	cup.bottom_radius = 0.44
	cup.height = 0.56
	cup.radial_segments = 24
	_mesh(bell, "Bell", cup, Transform3D(Basis(), Vector3(0, -0.36, 0)), _mat(BRONZE))
	_mesh(bell, "Bell crown", _sphere_mesh(0.22), Transform3D(Basis(), Vector3(0, -0.1, 0)), _mat(BRONZE))
	_mesh(bell, "Bell lip", geo._arc_tube(Vector3(0, -0.64, 0), Vector3.RIGHT, Vector3.BACK, 0.44, 0.0, TAU, 0.03, 24), Transform3D(), _mat(GOLD))
	_mesh(bell, "Bell yoke", _bm(Vector3(0.5, 0.1, 0.12)), Transform3D(Basis(), Vector3(0, 0.02, 0)), _mat(TIMBER))
	var clapper := _group(bell, "Bell clapper")
	clapper.position = Vector3(0, -0.2, 0)
	_mesh(clapper, "Clapper rod", _cyl_mesh(0.02, 0.4), Transform3D(Basis(), Vector3(0, -0.2, 0)), _mat(Color("5a4632")))
	_mesh(clapper, "Clapper ball", _sphere_mesh(0.07), Transform3D(Basis(), Vector3(0, -0.42, 0)), _mat(Color("5a4632")))
	# Rope down from the bell's wheel to hand height, with a red and cream sally (the grip).
	var rope_x := 0.32
	var rope_top := -0.05
	var rope_low := BELFRY_FLOOR + 0.75 - bell.position.y
	_mesh(bell, "Bell wheel", geo._arc_tube(Vector3(rope_x, rope_top, 0), Vector3.BACK, Vector3.UP, 0.16, 0.0, TAU, 0.02, 16), Transform3D(), _mat(TIMBER))
	_mesh(bell, "Bell rope", _cyl_mesh(0.02, rope_top - 0.16 - rope_low), Transform3D(Basis(), Vector3(rope_x, (rope_top - 0.16 + rope_low) * 0.5, 0)), _mat(Color("d8c49a")))
	_mesh(bell, "Rope sally", _cyl_mesh(0.045, 0.34), Transform3D(Basis(), Vector3(rope_x, rope_low + 0.4, 0)), _mat(RUNNER))
	_mesh(bell, "Rope sally band", _cyl_mesh(0.047, 0.06), Transform3D(Basis(), Vector3(rope_x, rope_low + 0.4, 0)), _mat(CLOTH))
	bell.set("badge_offset", Vector3(rope_x, rope_low + 0.4, 0))
	# The ladder (word "ladder"): iron rails and rungs, wall brackets. Its node's +z points away
	# from the wall. Outside (21 Nov) on the south face, climbed to the belfry floor and stepped off
	# forward (north) through the parapet gap; inside (ladder_inside) on the south wall's inner face,
	# from the tower floor up through the hatch, stepped off backwards (north) onto the belfry floor
	# (player_controller.gd update_ladder).
	var ladder := Node3D.new()
	ladder.name = "Tower ladder"
	ladder.set_meta("word_key", "ladder")
	var rise := BELFRY_FLOOR + 0.04 - FLOOR if ladder_inside else BELFRY_FLOOR
	ladder.set_meta("ladder_height", rise)
	if not ladder_inside:
		ladder.set_meta("ladder_exit", "forward")
	tower.add_child(ladder, true)
	ladder.add_to_group("ladders", true)
	if ladder_inside:
		ladder.transform = Transform3D(Basis(), Vector3(0, FLOOR, -half + TOWER_T + 0.08))
	else:
		ladder.transform = Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, -half - 0.08))
	var iron := Color("2f3238")
	var rail_h := rise + 1.0
	for side in [-1.0, 1.0]:
		_box(ladder, "Ladder rail", Vector3(side * 0.3, rail_h * 0.5, 0), Vector3(0.06, rail_h, 0.06), iron, false)
	var rungs := int(rise / 0.3)
	for k in range(1, rungs + 1):
		_mesh(ladder, "Ladder rung", _cyl_mesh(0.022, 0.6), Transform3D(Basis(Vector3.BACK, PI / 2), Vector3(0, k * 0.3, 0)), _mat(iron))
	for k in range(1, 5):
		for side in [-1.0, 1.0]:
			_box(ladder, "Ladder bracket", Vector3(side * 0.3, k * rise / 4.0 - 0.2, -0.06), Vector3(0.05, 0.05, 0.14), iron, false)
	# A pick body so the word card works (clicking the rails), no collision with the player.
	_word_pick(ladder, Vector3(0, rail_h * 0.5, 0), Vector3(0.7, rail_h, 0.12))
	_word_pick(bell, Vector3(0, -0.34, 0), Vector3(0.9, 0.62, 0.9))

## The hollow tower shaft (ladder_inside), in the tower's frame (+x toward the chapel, +z north):
## south, east and north stone walls (word "wall") from the ground to the belfry floor; on the
## chapel side the chapel's east wall (with the doorway) closes it, and a thick band above the
## doorway's height closes the rest and hides the chapel roof's eave inside it. The walls stop
## inside the chapel wall so no face lies in its inner face. A stone floor at the chapel's level
## with a threshold through the doorway, and a lantern on the east wall.
func _hollow_shaft(tower: Node3D, half: float) -> void:
	var h := BELFRY_FLOOR
	var wt := TOWER_T
	var reach := half - T + 0.1
	var shaft := _word(tower, "Tower shaft", "wall", Vector3.ZERO)
	_box(shaft, "Shaft wall south", Vector3(0, h * 0.5, -half + wt * 0.5), Vector3(2 * half, h, wt), WALL, true)
	_box(shaft, "Shaft wall north", Vector3((reach - half) * 0.5, h * 0.5, half - wt * 0.5), Vector3(reach + half, h, wt), WALL, true)
	_box(shaft, "Shaft wall east", Vector3(-half + wt * 0.5, h * 0.5, 0), Vector3(wt, h, 2 * half - 2 * wt), WALL, true)
	# Above the chapel wall's top (EAVE + 0.2, inside its roof) the west band and the north wall
	# reach the tower's own face again.
	var band_y := EAVE - 0.45
	var band_x0 := half - T - 0.55
	var top_y := EAVE + 0.25
	_box(shaft, "Shaft wall west", Vector3((band_x0 + reach) * 0.5, (band_y + top_y) * 0.5, 0), Vector3(reach - band_x0, top_y - band_y, 2 * half - 2 * wt), WALL, true)
	_box(shaft, "Shaft wall west top", Vector3((band_x0 + half) * 0.5, (top_y + h) * 0.5, 0), Vector3(half - band_x0, h - top_y, 2 * half - 2 * wt), WALL, true)
	_box(shaft, "Shaft wall north top", Vector3(reach + (half - reach) * 0.5, (top_y + h) * 0.5, half - wt * 0.5), Vector3(half - reach, h - top_y, wt), WALL, true)
	var inner := half - wt
	var floor_root := _box(tower, "Tower floor", Vector3(0, FLOOR * 0.5, 0), Vector3(2 * inner, FLOOR, 2 * inner), FLOOR_STONE, true, "floor")
	var door_z: float = TOWER_DOOR[0] + ZC - tower.position.z
	_box(floor_root, "Tower threshold", Vector3(inner + T * 0.5, 0, door_z), Vector3(T, FLOOR, TOWER_DOOR[1]), STONE, true)
	var lamp := _group(tower, "Tower lamp")
	lamp.transform = Transform3D(Basis(Vector3.UP, -PI / 2), Vector3(-inner + 0.27, 3.0, 0.4))
	_lantern(lamp, Vector3.ZERO)

## A band of height h at y round the tower's outside, out to `o` (inner faces 0.05 inside the
## walls); west = false leaves out the chapel side.
func _ring(tower: Node3D, title: String, y: float, h: float, o: float, half: float, color: Color, west := true) -> void:
	var i := half - 0.05
	for sz in [-1.0, 1.0]:
		_box(tower, title, Vector3(0, y, sz * (o + i) * 0.5), Vector3(2 * o, h, o - i), color, false)
	for sx in ([-1.0, 1.0] if west else [-1.0]):
		_box(tower, title, Vector3(sx * (o + i) * 0.5, y, 0), Vector3(o - i, h, 2 * i), color, false)

## The solid belfry floor (ladder_inside): stone flags (word "floor") over the tower's inner square
## round the hatch over the ladder, with a timber rim round the hatch.
func _belfry_floor(tower: Node3D, half: float) -> void:
	var inner := half - TOWER_T
	var t := 0.3
	var y := BELFRY_FLOOR + 0.04 - t * 0.5
	var hx0 := HATCH.position.x
	var hx1 := HATCH.end.x
	var hz1 := HATCH.end.y
	var root := _box(tower, "Belfry floor", Vector3(0, y, (hz1 + inner) * 0.5), Vector3(2 * inner, t, inner - hz1), STONE_DARK, true, "floor")
	for s in [[-inner, hx0], [hx1, inner]]:
		_box(root, "Belfry floor side", Vector3((s[0] + s[1]) * 0.5, 0, (-inner + hz1) * 0.5 - root.position.z), Vector3(s[1] - s[0], t, hz1 + inner), STONE_DARK, true)
	var rim_y := t * 0.5 + 0.02
	_box(root, "Hatch rim", Vector3((hx0 + hx1) * 0.5, rim_y, hz1 + 0.04 - root.position.z), Vector3(hx1 - hx0 + 0.16, 0.04, 0.08), TIMBER, false)
	for x in [hx0 - 0.04, hx1 + 0.04]:
		_box(root, "Hatch rim", Vector3(x, rim_y, (-inner + hz1) * 0.5 - root.position.z), Vector3(0.08, 0.04, hz1 + inner), TIMBER, false)

## A pick-only Area3D for a word root built of plain meshes (layer 1, like _box's word areas).
func _word_pick(root: Node3D, at: Vector3, size: Vector3) -> void:
	var area := Area3D.new()
	area.name = "Word pick"
	area.collision_mask = 0
	area.monitoring = false
	area.set_meta("object_name", str(root.name))
	area.set_meta("root", root)
	root.add_child(area)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = at
	area.add_child(shape)

# --- Sign -------------------------------------------------------------------------------------

## The CHAPEL sign over the door: a framed board on the wall face; nothing projects in front of it
## (the old portico lintel hid the letters' upper half, user screenshot 10 Nov 2026).
func _sign(lettering: Label3D) -> void:
	var y := 4.1
	_box(front, "Sign frame", Vector3(CX, y, FRONT - 0.05), Vector3(4.9, 0.8, 0.1), SIGN_FRAME, false)
	_box(front, "Sign face", Vector3(CX, y, FRONT - 0.12), Vector3(4.7, 0.62, 0.04), SIGN_FACE, false)
	front.add_child(lettering)
	lettering.transform = Transform3D(Basis(Vector3.UP, PI), Vector3(CX, y, FRONT - 0.15))
	lettering.font_size = 64
	lettering.pixel_size = 0.0105
	lettering.modulate = LETTERS
	lettering.text = "CHAPEL"

# --- Sanctuary --------------------------------------------------------------------------------

func _nave() -> void:
	# Red runner up the central aisle (word "rug") with gold edges.
	var z0 := FRONT + T + 0.1
	var z1 := DAIS_Z - 0.4
	var rug := _box(site, "Aisle runner", Vector3(CX, FLOOR + 0.01, (z0 + z1) * 0.5), Vector3(1.5, 0.02, z1 - z0), RUNNER, false, "rug")
	for side in [-1.0, 1.0]:
		_box(rug, "Runner edge", Vector3(side * 0.72, 0.004, 0), Vector3(0.06, 0.026, z1 - z0), GOLD, false)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1110
	var n := 0
	for z in PEW_ROWS:
		for x in PEW_X:
			_pew("Pew" + ("" if n == 0 else str(n + 1)), Vector3(x, FLOOR, z), rng)
			n += 1
	# Open doors, swung back against the jambs inside.
	for side in [-1.0, 1.0]:
		var leaf := _box(site, "Chapel door", Vector3(CX + side * (DOOR_W * 0.5 - 0.04), FLOOR + 1.05, FRONT + T + 0.5), Vector3(0.07, 2.1, 1.0), WOOD_DARK, true, "door")
		for y in [-0.6, 0.6]:
			_box(leaf, "Door strap", Vector3(-side * 0.045, y, 0), Vector3(0.025, 0.06, 0.9), Color("2f3238"), false)
			_box(leaf, "Door strap", Vector3(side * 0.045, y, 0), Vector3(0.025, 0.06, 0.9), Color("2f3238"), false)
	# Donation box (with its slot) by the left door, votive candles by the right.
	_box(site, "Donation Box", Vector3(CX - W2 + 0.95, FLOOR + 0.45, FRONT + 1.0), Vector3(0.55, 0.9, 0.45), WOOD_DARK, true, "donation box")
	_box(site, "Donation box lid", Vector3(CX - W2 + 0.95, FLOOR + 0.92, FRONT + 1.0), Vector3(0.6, 0.04, 0.5), BRONZE, false)
	_box(site, "Slot", Vector3(CX - W2 + 0.95, FLOOR + 0.945, FRONT + 1.0), Vector3(0.3, 0.012, 0.05), Color("2b2b33"), false, "slot")
	var votive := _box(site, "Votive candles", Vector3(CX + W2 - 1.15, FLOOR + 0.4, FRONT + 1.05), Vector3(1.0, 0.8, 0.5), WOOD_DARK, true, "candle")
	for tier in 3:
		var ty := 0.4 + tier * 0.12
		var tz := 0.12 - tier * 0.12
		_box(votive, "Votive tier", Vector3(0, ty + 0.03, tz), Vector3(0.96, 0.06, 0.24), BRONZE, false)
		for k in 5:
			var p := Vector3(-0.38 + k * 0.19, ty + 0.1, tz)
			_mesh(votive, "Votive light", _cyl_mesh(0.035, 0.08), Transform3D(Basis(), p), _mat(CLOTH))
			_mesh(votive, "Votive flame", _sphere_mesh(0.025), Transform3D(Basis().scaled(Vector3(0.8, 1.6, 0.8)), p + Vector3(0, 0.08, 0)), _glow(Color("ffb14f"), 1.2))

## A wooden pew facing the altar (+z): seat, raked back, end panels, a book ledge on the back for
## the row behind with a couple of hymn books.
func _pew(title: String, at: Vector3, rng: RandomNumberGenerator) -> void:
	var pew := _word(site, title, "pew", at)
	_box(pew, "Pew seat", Vector3(0, 0.45, 0.02), Vector3(PEW_L, 0.07, 0.48), WOOD, true)
	_box(pew, "Pew back", Vector3(0, 0.8, -0.25), Vector3(PEW_L, 0.62, 0.06), WOOD, true, "", Basis(Vector3.RIGHT, -0.14))
	_box(pew, "Pew rail", Vector3(0, 1.1, -0.29), Vector3(PEW_L + 0.04, 0.05, 0.12), WOOD_DARK, false)
	_box(pew, "Book ledge", Vector3(0, 0.62, -0.38), Vector3(PEW_L - 0.2, 0.04, 0.14), WOOD_DARK, false)
	for side in [-1.0, 1.0]:
		_box(pew, "Pew end", Vector3(side * PEW_L * 0.5, 0.5, -0.06), Vector3(0.07, 1.0, 0.64), WOOD_DARK, true)
	for k in 2:
		var x := rng.randf_range(-PEW_L * 0.4, PEW_L * 0.4)
		var color: Color = [Color("7d2632"), Color("2f4f7a"), Color("2f5a3c")][rng.randi() % 3]
		_box(pew, "Hymn book", Vector3(x, 0.74, -0.37), Vector3(0.14, 0.2, 0.06), color, false)

func _chancel() -> void:
	var inner := W2 - T
	var back := REAR - T
	var top := FLOOR + DAIS_H
	# Platform (word "tile") with a step in front (word "step") and a hidden ramp over both.
	var ramp_end := DAIS_Z + 0.35
	_box(site, "Chancel", Vector3(CX, FLOOR + DAIS_H * 0.5, (ramp_end + back) * 0.5), Vector3(2 * inner - 1.6, DAIS_H, back - ramp_end), DAIS_STONE, true, "tile")
	_box(site, "Chancel front", Vector3(CX, FLOOR + DAIS_H * 0.5, (DAIS_Z + ramp_end) * 0.5), Vector3(2 * inner - 1.6, DAIS_H, ramp_end - DAIS_Z), DAIS_STONE, false)
	_box(site, "Chancel step", Vector3(CX, FLOOR + 0.075, DAIS_Z - 0.175), Vector3(2 * inner - 1.6, 0.15, 0.35), STONE, false, "step")
	_ramp(site, "Chancel ramp", inner - 0.8, DAIS_Z - 0.75, FLOOR, ramp_end, top)
	for k in range(1, 4):
		_box(site, "Chancel joint", Vector3(CX, top + 0.002, ramp_end + (back - ramp_end) * k / 4.0), Vector3(2 * inner - 1.6, 0.006, 0.03), STONE_DARK, false)
	# Red dossal with a gold border on the rear wall and the cross over it.
	_box(site, "Dossal border", Vector3(CX, 3.0, back - 0.015), Vector3(2.25, 3.05, 0.03), GOLD, false)
	_box(site, "Dossal", Vector3(CX, 3.0, back - 0.04), Vector3(2.05, 2.85, 0.03), DOSSAL, false)
	var cross := _box(site, "Altar cross", Vector3(CX, 3.1, back - 0.11), Vector3(0.2, 2.2, 0.1), GOLD, true, "cross")
	_box(cross, "Cross bar", Vector3(0, 0.45, 0), Vector3(1.2, 0.2, 0.1), GOLD, true)
	# Altar: stone table, white cloth, red frontal with a gold cross, two candles.
	var altar_z := REAR - 1.3
	var altar := _box(site, "Altar", Vector3(CX, top + 0.475, altar_z), Vector3(2.2, 0.95, 0.9), DAIS_STONE, true, "altar")
	_box(altar, "Altar cloth", Vector3(0, 0.495, 0), Vector3(2.4, 0.04, 1.0), CLOTH, false)
	_box(altar, "Altar cloth drop", Vector3(0, 0.36, -0.505), Vector3(2.4, 0.3, 0.012), CLOTH, false)
	_box(altar, "Altar frontal", Vector3(0, -0.05, -0.47), Vector3(1.2, 0.62, 0.04), DOSSAL, false)
	_box(altar, "Frontal cross", Vector3(0, -0.05, -0.495), Vector3(0.08, 0.4, 0.02), GOLD, false)
	_box(altar, "Frontal cross bar", Vector3(0, 0.03, -0.495), Vector3(0.26, 0.08, 0.02), GOLD, false)
	var table := top + 0.95 + 0.04
	for i in 2:
		var x := CX + (-0.8 if i == 0 else 0.8)
		var suffix := "" if i == 0 else "2"
		_mesh(site, "Candlestick", _cyl_mesh(0.08, 0.05), Transform3D(Basis(), Vector3(x, table + 0.025, altar_z)), _mat(GOLD))
		_mesh(site, "Candlestick stem", _cyl_mesh(0.03, 0.18), Transform3D(Basis(), Vector3(x, table + 0.14, altar_z)), _mat(GOLD))
		_cyl(site, "Chapel candle" + suffix, Vector3(x, table + 0.38, altar_z), 0.045, 0.3, CLOTH, "candle")
		var flame := _sphere(site, "Candle flame" + suffix, Vector3(x, table + 0.58, altar_z), 0.05, Color("ffb14f"), "flame")
		flame.scale = Vector3(0.6, 1.6, 0.6)
		_paint(flame, _glow(Color("ffb14f"), 1.4))
	# Lectern with an open book, front left of the platform.
	var lectern := _word(site, "Lectern", "lectern", Vector3(CX - 2.75, top, REAR - 2.55))
	_box(lectern, "Lectern base", Vector3(0, 0.03, 0), Vector3(0.5, 0.06, 0.42), WOOD_DARK, true)
	_box(lectern, "Lectern post", Vector3(0, 0.55, 0), Vector3(0.16, 1.0, 0.16), WOOD, true)
	var tilt := Basis(Vector3.RIGHT, 0.35)
	# The desk slopes down toward the reader (+z, facing the pews); the lip holds its low edge.
	_box(lectern, "Lectern desk", Vector3(0, 1.1, 0), Vector3(0.64, 0.06, 0.48), WOOD, true, "", tilt)
	_box(lectern, "Lectern lip", Vector3(0, 1.1, 0) + tilt * Vector3(0, 0.04, 0.24), Vector3(0.64, 0.06, 0.03), WOOD_DARK, false, "", tilt)
	var book := _box(site, "Lectern book", lectern.position + Vector3(0, 1.1, 0) + tilt * Vector3(0, 0.05, 0), Vector3(0.46, 0.03, 0.32), CLOTH, false, "book", tilt)
	_box(book, "Book cover", Vector3(0, -0.02, 0), Vector3(0.5, 0.012, 0.35), DOSSAL, false)
	_box(book, "Book spine", Vector3(0, 0.017, 0), Vector3(0.012, 0.004, 0.32), Color("b8a785"), false)
	# Flowers on stands either side of the altar.
	var n := 0
	for x in [CX - 2.3, CX + 2.3]:
		_cyl(site, "Flower stand", Vector3(x, top + 0.42, REAR - 0.95), 0.14, 0.84, WOOD_DARK, "", true)
		_mesh(site, "Flower vase", _cyl_mesh(0.12, 0.26), Transform3D(Basis(), Vector3(x, top + 0.97, REAR - 0.95)), _mat(CLOTH))
		_bouquet("Altar flowers" + ("" if n == 0 else "2"), Vector3(x, top + 1.26, REAR - 0.95), 0.26)
		n += 1
	# Small pipe organ against the west wall, between two windows, with its bench.
	var ox := CX + inner - 0.38
	var organ := _box(site, "Chapel pipe organ", Vector3(ox, FLOOR + 0.62, REAR - 3.9), Vector3(0.75, 1.24, 1.5), WOOD_DARK, true)
	_box(organ, "Organ keys", Vector3(-0.5, 0.36, 0), Vector3(0.3, 0.05, 1.25), CLOTH, false)
	_box(organ, "Organ key shelf", Vector3(-0.47, 0.32, 0), Vector3(0.36, 0.04, 1.3), WOOD, false)
	_box(organ, "Organ music stand", Vector3(-0.3, 0.75, 0), Vector3(0.04, 0.3, 0.7), WOOD, false)
	for k in 7:
		var h := 1.0 + 0.8 * (1.0 - absf(k - 3) / 3.0)
		_mesh(organ, "Organ pipe", _cyl_mesh(0.06, h), Transform3D(Basis(), Vector3(0.2, 0.62 + h * 0.5, -0.6 + k * 0.2)), _mat(PIPE))
	_box(site, "Organ bench", Vector3(ox - 0.95, FLOOR + 0.24, REAR - 3.9), Vector3(0.35, 0.48, 0.9), WOOD, true)

## A bunch of flowers (word "flower"): a leafy ball with coloured blossoms.
func _bouquet(title: String, at: Vector3, r: float) -> void:
	var bunch := _sphere(site, title, at, r, LEAF, "flower")
	for k in 9:
		var a := TAU * k / 9.0
		var p := Vector3(cos(a) * r * 0.75, 0.05 + (k % 3) * 0.06, sin(a) * r * 0.75)
		_mesh(bunch, "Blossom", _sphere_mesh(r * 0.32), Transform3D(Basis(), p), _mat(BLOSSOMS[k % BLOSSOMS.size()]))
	_mesh(bunch, "Blossom", _sphere_mesh(r * 0.36), Transform3D(Basis(), Vector3(0, r * 0.7, 0)), _mat(BLOSSOMS[1]))

# --- Grounds ----------------------------------------------------------------------------------

func _grounds() -> void:
	# Entrance step (word "step") over a hidden ramp, planters with flowers either side.
	_box(site, "Step", Vector3(CX, FLOOR * 0.5, FRONT - 0.5), Vector3(3.2, FLOOR, 1.0), STONE, false, "step")
	_ramp(site, "Entrance ramp", 1.6, FRONT - 1.6, -0.02, FRONT + T * 0.5, FLOOR)
	var n := 0
	for x in [CX - 2.25, CX + 2.25]:
		var suffix := "" if n == 0 else "2"
		var planter := _box(site, "Planter" + suffix, Vector3(x, 0.25, FRONT - 0.6), Vector3(0.8, 0.5, 0.7), STONE, true, "planter")
		_box(planter, "Planter soil", Vector3(0, 0.24, 0), Vector3(0.68, 0.04, 0.58), Color("6b4a2e"), false)
		_bouquet("Planter flowers" + suffix, Vector3(x, 0.66, FRONT - 0.6), 0.3)
		n += 1
	# Notice board by the path (word "church"; its sign reads CHURCH in the world language).
	var board := _word(site, "Church notice board", "church", Vector3(CX + W2 + 1.7, 0, FRONT - 2.1))
	for side in [-1.0, 1.0]:
		_box(board, "Board post", Vector3(side * 0.68, 0.85, 0), Vector3(0.1, 1.7, 0.1), TIMBER, true)
	_box(board, "Board panel", Vector3(0, 1.3, 0), Vector3(1.5, 0.75, 0.08), SIGN_FRAME, true)
	_box(board, "Board face", Vector3(0, 1.3, -0.05), Vector3(1.36, 0.6, 0.02), SIGN_FACE, false)
	for side in [-1.0, 1.0]:
		_box(board, "Board cap", Vector3(side * 0.42, 1.82, 0), Vector3(1.0, 0.06, 0.24), SLATE, false, "", Basis(Vector3.BACK, -side * 0.38))
	var label := Label3D.new()
	label.name = "Church board sign"
	label.text = "CHURCH"
	label.font_size = 48
	label.pixel_size = 0.0075
	label.modulate = LETTERS
	label.outline_size = 0
	label.shaded = false
	label.double_sided = false
	board.add_child(label)
	label.transform = Transform3D(Basis(Vector3.UP, PI), Vector3(0, 1.3, -0.065))
	# Flag on a white pole on the east lawn.
	var fx := flag_at.x
	var fz := flag_at.y
	_cyl(site, "Flagpole", Vector3(fx, 3.0, fz), 0.05, 6.0, TRIM, "", true)
	_mesh(site, "Flagpole finial", _sphere_mesh(0.09), Transform3D(Basis(), Vector3(fx, 6.05, fz)), _mat(GOLD))
	_box(site, "Flagpole base", Vector3(fx, 0.05, fz), Vector3(0.5, 0.1, 0.5), STONE, false)
	var flag := _box(site, "Flag", Vector3(fx - 0.7, 5.45, fz), Vector3(1.3, 0.8, 0.03), Color("82a9bf"), false, "flag")
	_box(flag, "Flag band", Vector3(0, 0, 0), Vector3(1.3, 0.2, 0.05), TRIM, false)

# --- Helpers ----------------------------------------------------------------------------------

## ExteriorPick areas on every front mesh (the deleted building_exteriors.gd did this for the
## original fronts): picking them shows the facade's exterior word.
func _exterior_picks(node: Node) -> void:
	if node is MeshInstance3D and node.mesh != null and not node.has_node("ExteriorPick"):
		var area := Area3D.new()
		area.name = "ExteriorPick"
		area.collision_layer = 1
		area.collision_mask = 0
		area.monitoring = false
		area.monitorable = false
		var shape := CollisionShape3D.new()
		shape.shape = node.mesh.create_convex_shape()
		area.add_child(shape)
		node.add_child(area)
	for child in node.get_children():
		if child is MeshInstance3D or child.get_class() == "Node3D":
			_exterior_picks(child)

func _group(parent: Node3D, title: String) -> Node3D:
	var node := Node3D.new()
	node.name = title
	parent.add_child(node, true)
	return node

## A word root (meta word_key) for an item made of several parts.
func _word(parent: Node3D, title: String, word: String, pos: Vector3) -> Node3D:
	var node := _group(parent, title)
	node.position = pos
	node.set_meta("word_key", word)
	return node

## Main's box (mesh, collision when solid, a pick area with a word) under `parent`.
func _box(parent: Node3D, title: String, pos: Vector3, size: Vector3, color: Color, solid := false, word := "", basis := Basis()) -> Node3D:
	var part: Node3D = game.box(title, Vector3.ZERO, size, color, word, solid)
	part.reparent(parent, false)
	part.transform = Transform3D(basis, pos)
	return part

func _cyl(parent: Node3D, title: String, pos: Vector3, radius: float, height: float, color: Color, word := "", solid := false) -> Node3D:
	var part: Node3D = game.cylinder(title, Vector3.ZERO, radius, height, color, word, solid)
	part.reparent(parent, false)
	part.position = pos
	return part

func _sphere(parent: Node3D, title: String, pos: Vector3, radius: float, color: Color, word := "") -> Node3D:
	var part: Node3D = game.sphere(title, Vector3.ZERO, radius, color, word, false)
	part.reparent(parent, false)
	part.position = pos
	return part

func _mesh(parent: Node3D, title: String, mesh: Mesh, xform: Transform3D, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = title
	node.mesh = mesh
	node.material_override = material
	parent.add_child(node, true)
	node.transform = xform
	return node

## The first mesh of a part made by Main's helpers gets `material`.
func _paint(part: Node3D, material: Material) -> void:
	for child in part.get_children():
		if child is MeshInstance3D:
			child.material_override = material
			return

func _body(parent: Node3D, title: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = title
	parent.add_child(body, true)
	return body

func _shape(body: StaticBody3D, pos: Vector3, size: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = pos
	body.add_child(shape)

## A hidden walkable slope over x -half..half (around CX), rising from (z0, y0) to (z1, y1):
## steps the player cannot climb (no step-up) become ramps (as the Mystery House entry, 10 Nov).
func _ramp(parent: Node3D, title: String, half: float, z0: float, y0: float, z1: float, y1: float) -> void:
	var slope := atan2(y1 - y0, z1 - z0)
	var along := Vector2(z1 - z0, y1 - y0).length()
	var normal := Vector3(0, cos(slope), -sin(slope))
	var body := _body(parent, title)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2 * half, 0.1, along)
	shape.shape = box
	body.add_child(shape)
	body.transform = Transform3D(Basis(Vector3.RIGHT, -slope), Vector3(CX, (y0 + y1) * 0.5, (z0 + z1) * 0.5) - normal * 0.05)

func _mat(color: Color) -> StandardMaterial3D:
	return game.material_for(color)

## Stained glass, flames: lit colour plus a little emission.
func _glow(color: Color, energy: float) -> StandardMaterial3D:
	var key := color.to_html() + str(energy)
	if not _materials.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = energy
		m.roughness = 0.4
		_materials[key] = m
	return _materials[key]

func _bm(size: Vector3) -> BoxMesh:
	return game.shared_box_mesh(size)

func _cyl_mesh(radius: float, height: float) -> CylinderMesh:
	var key := "cyl%s:%s" % [radius, height]
	if not _materials.has(key):
		var m := CylinderMesh.new()
		m.top_radius = radius
		m.bottom_radius = radius
		m.height = height
		m.radial_segments = 12
		m.rings = 1
		_materials[key] = m
	return _materials[key]

func _sphere_mesh(radius: float) -> SphereMesh:
	var key := "sph%s" % radius
	if not _materials.has(key):
		var m := SphereMesh.new()
		m.radius = radius
		m.height = radius * 2.0
		m.radial_segments = 12
		m.rings = 6
		_materials[key] = m
	return _materials[key]


## Colours snapped to the game palette with the hue guard (P3-22, decision D14: approved by the
## user 26 Nov 2026 after the library/police trial; scripts/buildings/palette_snap.gd,
## docs/evidence/pastel-20261125/).
func palette_snap(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/palette_snap.gd").snap(town, "chapel")
