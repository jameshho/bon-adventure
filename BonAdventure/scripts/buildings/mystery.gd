extends RefCounted
## Mystery House ("Casa de las Estrellas") own script (docs/guides/MODULAR_TOWN.md, "Changing a
## building"); saved in scenes/town/mystery.scn. Design: docs/guides/TOWN_DESIGN_BRIEF.md, "Mystery
## House and Mystery Doors" (user brief and approval, 9 Nov 2026): a cream-stone house with purple
## roofs, a gold-ribbed purple dome and crystal, an arched purple entrance, stained-glass windows,
## lanterns and flowers; inside a hall with the shape and colour posters, then the high, starry
## mystery room under the dome with the twelve zodiac constellations and three locked doors that
## open only in the Mystery Doors minigame (scripts/learning/mystery_session.gd).
## Bake:  godot --headless --path . --script res://tools/bake_unit.gd -- mystery
## Never rename or remove a baked step (add a new one that undoes it).
##
## Coordinates are house-local (the MysteryHouse node; town units, Apartment scale 1.3 applies).
## The house is turned a quarter so its front (local -Z) faces the loop road to the east (town
## -X): local x runs south (+x = town -Z), local z runs west (+z = town +X). Shell x -12..12,
## z -15 (front) .. 15 (rear); floor top FLOOR. Hall z -15..-5; mystery room z -5..15 with the
## door wall at z DOOR_WALL and the three alcoves behind it.
const STEPS := ["build_house", "endless_hall", "hinges_right", "zodiac_signs", "door_faces", "room_ceiling", "room_twin", "coplanar_gaps", "coplanar_gaps_2", "entry_ramp", "interaction_metas"]

const ROOT := "MysteryHouse"
## Town position of the house centre and its turn (local -Z -> town -X, toward the road).
const ORIGIN := Vector3(131.0, 0.0, 82.0)
const TURN := PI / 2.0
const W2 := 12.0
const FRONT := -15.0
const REAR := 15.0
const WALL := 0.4
## Floor top, on a stone plinth (three steps at the entrance).
const FLOOR := 0.6
const HALL_REAR := -5.0
const HALL_H := 5.5
## The mystery room: walls ROOM_H high, a drum and dome rise over DOME_Z (peak about
## FLOOR + 16.5 inside: "high, mysterious ceiling", user 9 Nov 2026).
const ROOM_H := 7.0
const DOME_Z := 3.0
const DOME_R := 5.5
const HIP_RISE := 1.8
const DRUM_SHOW := 1.2
## The three doors' wall (its room-side face) and the door centres, left to right seen from the
## room (local +x is the viewer's left there: the doors face local -z).
const DOOR_WALL := 11.0
const DOOR_X := [6.5, 0.0, -6.5]
const DOOR_W := 2.6
const DOOR_H := 4.3
const DOOR_NAMES := ["MysteryDoor A", "MysteryDoor B", "MysteryDoor C"]
## Door look outside a game (the session recolours the leaves and swaps the symbols).
const DOOR_DEFAULTS := [["red", "circle"], ["yellow", "star"], ["blue", "triangle"]]
## Openings: front entrance and the arch from the hall into the mystery room (width, height).
const ENTRY := Vector2(3.2, 4.6)
const ARCH := Vector2(4.0, 4.8)
## Minigame spots (house-local, floor level). START: where every round begins, facing the doors.
const START := Vector3(0.0, FLOOR, 0.5)
const START_LOOK := Vector3(0, 0, 1)
## Madame Luna, the fortune-teller (cat plush), by the crystal-ball table, facing the room.
const LUNA := "MadameLuna"
const LUNA_SPOT := Vector3(8.6, FLOOR, -2.6)
const LUNA_LOOK := Vector3(-0.8, 0, 0.6)
## Leaving a game early (user, 10 Nov 2026): the player stands across the fortune table (centre
## LUNA_SPOT + (-1.3, 0, 1.0), cloth radius 0.9) from Luna, about 1.45 from its centre, facing her.
const GUEST_SPOT := Vector3(6.15, FLOOR, -0.72)
const GUEST_LOOK := Vector3(0.79, 0, -0.61)
## Leaving the room during a game: a trigger just inside the hall side of the arch; "No, I'll
## stay" puts the player at INSIDE.
const DOORWAY := Vector3(0.0, FLOOR + 2.0, HALL_REAR - 1.2)
const DOORWAY_SIZE := Vector3(4.4, 4.0, 1.2)
const INSIDE := Vector3(0.0, FLOOR, -2.4)
## Behind each door: the alcove a right answer walks into (the session's trigger).
const ALCOVE_Z := 13.2
const ALCOVE_SIZE := Vector3(2.4, 3.0, 2.2)
## The endless hall (user, 9 Nov 2026: "the mystery house should feel like an endless hall ... just
## one straight line"; the door shuts behind the player). Two identical rooms hidden under the
## house, joined by three identical door walls whose room-side faces stand at HALL_WALLS (like
## DOOR_WALL; each wall is WALL thick behind its face). The first round is played at the mystery
## room's doors; every later one at wall B. Once the right door has shut behind the player in the
## second room, the session moves them back HALL_STEP into the first room, which looks the same,
## so the line of rooms never ends. Hidden outside a game (hidden meshes are never batched by
## render_culling.gd, so showing it works). Floor top ENDLESS_FLOOR (Main respawns below -15).
const ENDLESS := "EndlessHall"
const ENDLESS_FLOOR := -11.0
const HALL_WALLS := [-12.0, 0.0, 12.0]
const HALL_WALL_NAMES := ["Wall A", "Wall B", "Wall C"]
const HALL_STEP := 12.0
## The end of a game (user, 9 Nov 2026): after the last door the second room shows a large
## treasure chest (TREASURE, hidden otherwise) with Luna's diamond; once it has flown back to her,
## one door of wall C opens onto a dark doorway EXIT_DEPTH deep (like the mystery room's alcoves),
## and walking in brings the player out of a mystery room door.
const TREASURE := "Treasure"
const TREASURE_Z := 6.2
const EXIT_DEPTH := 3.2
## Where the player arrived in the first room when Yes faded them into the hall (unused since
## 10 Nov 2026: the game starts in place and the first right door swaps them; kept for history).
const HALL_ARRIVE := 1.6

## Door colours the game uses (keys of words.json, colours of the leaf).
const COLORS := {
	"red": Color("d63c3c"), "blue": Color("2f6fd6"), "green": Color("33a852"), "yellow": Color("f2c230"),
	"purple": Color("8a4fd0"), "orange": Color("f08a24"), "pink": Color("f07ab0"),
}
const SHAPES := ["circle", "square", "triangle", "star"]

const CREAM := Color("efe2c4")
const STONE := Color("d9c9a5")
const STONE_DARK := Color("b8a785")
const GOLD := Color("e2b54e")
const ROOF := Color("7d4cc6")
const ROOF_DARK := Color("5b3499")
const TEAL := Color("2f7076")
const INDIGO := Color("2c2162")
const NAVY := Color("12173d")
const HALL_WALL := Color("f4ecdf")
const HALL_FLOOR := Color("e6d7b8")
## The mystery room follows the user's door-wall reference (9 Nov 2026): lilac stone walls and a
## pale tiled floor under the starry ceiling and dome.
const ROOM_FLOOR := Color("e9e1f1")
const LILAC := Color("c4b0e8")
const RUG := Color("7a4cc4")
const CARPET := Color("6b3fb0")
const LEAF_GREEN := Color("3f8a3a")
const FLOWER_PINK := Color("ec5fa4")
const FLOWER_YELLOW := Color("f4cf3a")
const SOIL := Color("6b4a2e")
const BRONZE := Color("5a4632")
const GLASS := Color("ffcf6b")
const SYMBOL := Color("fff4c8")
const SYMBOL_EDGE := Color("1b1f3f")

## The twelve zodiac constellations on the mystery room's side walls and in the endless hall
## (decoration only, user decision 9 Nov 2026: no zodiac words). Redrawn 10 Nov 2026 from the
## user's reference chart: star points in that chart's pixels (x right, y down; fitted to the
## plaque by _constellation()) and the lines joining them. Each plaque has its English name on a
## nameplate below, English in every game language (user, 10 Nov 2026; sign_translations _same).
const ZODIAC := [
	{"name": "Aries", "stars": [[70, 95], [147, 140], [193, 188], [195, 228]], "lines": [[0, 1], [1, 2], [2, 3]]},
	{"name": "Taurus", "stars": [[325, 57], [350, 103], [342, 135], [366, 142], [357, 172], [323, 172], [275, 100], [395, 205], [415, 240]], "lines": [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [4, 7], [7, 8]]},
	{"name": "Gemini", "stars": [[518, 73], [487, 115], [503, 150], [538, 158], [578, 126], [618, 143], [645, 135], [620, 168], [602, 196], [610, 238]], "lines": [[0, 1], [1, 2], [2, 3], [3, 8], [0, 4], [4, 5], [5, 6], [5, 7], [7, 8], [8, 9]]},
	{"name": "Cancer", "stars": [[732, 93], [785, 145], [800, 170], [873, 182], [808, 215]], "lines": [[0, 1], [1, 2], [2, 3], [2, 4]]},
	{"name": "Leo", "stars": [[116, 328], [156, 327], [101, 383], [122, 409], [160, 397], [198, 423], [130, 460], [90, 448], [83, 511]], "lines": [[1, 0], [0, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 8], [3, 7], [7, 8]]},
	{"name": "Virgo", "stars": [[362, 313], [368, 354], [358, 378], [327, 382], [288, 362], [318, 435], [362, 420], [380, 447], [363, 470], [340, 480], [332, 508], [292, 462], [286, 493]], "lines": [[0, 1], [1, 2], [2, 3], [3, 4], [2, 6], [6, 7], [3, 5], [5, 7], [5, 11], [11, 12], [7, 8], [8, 9], [9, 10]]},
	{"name": "Libra", "stars": [[540, 330], [452, 363], [472, 378], [502, 376], [595, 376], [575, 450], [520, 477], [530, 500]], "lines": [[1, 2], [2, 3], [3, 0], [0, 4], [4, 5], [0, 5], [5, 6], [6, 7]]},
	{"name": "Scorpio", "stars": [[822, 313], [852, 332], [866, 363], [866, 395], [862, 430], [815, 378], [767, 417], [762, 458], [706, 496], [658, 472], [672, 428]], "lines": [[0, 1], [1, 2], [2, 3], [3, 4], [2, 5], [5, 6], [6, 7], [7, 8], [8, 9], [9, 10]]},
	{"name": "Sagittarius", "stars": [[115, 600], [158, 638], [148, 658], [110, 645], [85, 665], [103, 698], [107, 725], [133, 715], [135, 735], [165, 672], [190, 645], [200, 613], [205, 675], [256, 666], [198, 700], [212, 725]], "lines": [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 7], [6, 8], [2, 9], [9, 10], [10, 11], [10, 12], [12, 13], [12, 14], [14, 15]]},
	{"name": "Capricorn", "stars": [[430, 580], [426, 607], [380, 673], [358, 697], [333, 748], [390, 746], [428, 723], [448, 707], [455, 680]], "lines": [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 7], [7, 8], [8, 1]]},
	{"name": "Aquarius", "stars": [[635, 582], [590, 622], [557, 646], [550, 668], [530, 672], [525, 695], [565, 740], [580, 716], [605, 716], [620, 732], [592, 668], [625, 670]], "lines": [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 7], [7, 8], [8, 9], [2, 10], [10, 11]]},
	{"name": "Pisces", "stars": [[803, 573], [782, 603], [828, 603], [805, 622], [808, 690], [828, 750], [800, 745], [740, 738], [720, 755], [702, 742]], "lines": [[0, 1], [1, 3], [3, 2], [2, 0], [3, 4], [4, 5], [5, 6], [6, 7], [7, 8], [8, 9]]},
]

var game
var house: Node3D
var _materials := {}

# --- The step -----------------------------------------------------------------------------

## The whole house (user brief and approval, 9 Nov 2026). Everything is built under one node,
## MysteryHouse, the unit's only part.
func build_house(town: Node3D, main) -> void:
	game = main
	house = Node3D.new()
	house.name = ROOT
	town.add_child(house)
	house.transform = Transform3D(Basis(Vector3.UP, TURN), ORIGIN)
	_shell()
	_hall_roof()
	_room_roof_and_dome()
	_room_interior()
	_doors()
	_hall_interior()
	_entrance()
	_garden()
	_luna()

# --- Shell ----------------------------------------------------------------------------------

func _shell() -> void:
	var shell := _group(house, "Shell")
	# Stone plinth: the floor stands FLOOR above the ground; its foot sinks into the lawn.
	_box(shell, "Plinth", Vector3(0, (FLOOR - 0.5) * 0.5, 0), Vector3(2 * W2 + 1.0, FLOOR + 0.5, REAR - FRONT + 1.0), STONE_DARK)
	_box(shell, "Plinth cap", Vector3(0, FLOOR - 0.04, 0), Vector3(2 * W2 + 1.2, 0.1, REAR - FRONT + 1.2), STONE, false)
	_box(shell, "Hall floor", Vector3(0, FLOOR + 0.012, (FRONT + HALL_REAR) * 0.5), Vector3(2 * W2 - 0.8, 0.024, HALL_REAR - FRONT - 0.8), HALL_FLOOR, false, "floor")
	_box(shell, "Mystery room floor", Vector3(0, FLOOR + 0.012, (HALL_REAR + DOOR_WALL) * 0.5), Vector3(2 * W2 - 0.8, 0.024, DOOR_WALL - HALL_REAR - 0.4), ROOM_FLOOR, false, "floor")
	var top_hall := FLOOR + HALL_H
	var top_room := FLOOR + ROOM_H
	# Front wall, with the entrance.
	_x_wall(shell, "Front wall", FRONT + WALL * 0.5, -W2, W2, FLOOR, top_hall, WALL, CREAM, [[0.0, ENTRY.x, ENTRY.y]])
	# Side walls: the hall part, then the taller mystery room part.
	for side in [-1.0, 1.0]:
		var x: float = side * (W2 - WALL * 0.5)
		_box(shell, "Side wall hall", Vector3(x, (FLOOR + top_hall) * 0.5, (FRONT + HALL_REAR) * 0.5), Vector3(WALL, HALL_H, HALL_REAR - FRONT), CREAM)
		_box(shell, "Side wall room", Vector3(x, (FLOOR + top_room) * 0.5, (HALL_REAR + REAR) * 0.5), Vector3(WALL, ROOM_H, REAR - HALL_REAR), CREAM)
		# Mystery room lining (lilac), on the inside face.
		_box(shell, "Room lining", Vector3(x - side * (WALL * 0.5 + 0.03), (FLOOR + top_room) * 0.5, (HALL_REAR + DOOR_WALL) * 0.5), Vector3(0.06, ROOM_H, DOOR_WALL - HALL_REAR - WALL), LILAC, false)
		# Cornices: gold bands at the tops of the walls.
		_box(shell, "Hall cornice", Vector3(side * (W2 + 0.05), top_hall - 0.15, (FRONT + HALL_REAR) * 0.5), Vector3(0.3, 0.3, HALL_REAR - FRONT + 0.3), GOLD, false)
		_box(shell, "Room cornice", Vector3(side * (W2 + 0.05), top_room - 0.15, (HALL_REAR + REAR) * 0.5), Vector3(0.3, 0.3, REAR - HALL_REAR + 0.3), GOLD, false)
	_box(shell, "Front cornice", Vector3(0, top_hall - 0.15, FRONT - 0.05), Vector3(2 * W2 + 0.4, 0.3, 0.3), GOLD, false)
	_box(shell, "Rear cornice", Vector3(0, top_room - 0.15, REAR + 0.05), Vector3(2 * W2 + 0.4, 0.3, 0.3), GOLD, false)
	_box(shell, "Room front cornice", Vector3(0, top_room - 0.15, HALL_REAR - 0.25), Vector3(2 * W2 + 0.4, 0.3, 0.3), GOLD, false)
	# Wall between the hall and the mystery room, with the arch; cream on the hall side.
	_x_wall(shell, "Hall rear wall", HALL_REAR, -W2, W2, FLOOR, top_room, WALL, CREAM, [[0.0, ARCH.x, ARCH.y]])
	_x_wall(shell, "Room front lining", HALL_REAR + WALL * 0.5 + 0.03, -W2 + WALL, W2 - WALL, FLOOR, top_room, 0.06, LILAC, [[0.0, ARCH.x, ARCH.y]], false)
	_arch_trim(shell, "Room arch trim", Vector3(0, FLOOR + ARCH.y, HALL_REAR - WALL * 0.5 - 0.05), ARCH.x * 0.5, Vector3(0, 0, -1))
	_arch_trim(shell, "Room arch trim inside", Vector3(0, FLOOR + ARCH.y, HALL_REAR + WALL * 0.5 + 0.1), ARCH.x * 0.5, Vector3(0, 0, 1))
	# Rear wall.
	_box(shell, "Rear wall", Vector3(0, (FLOOR + top_room) * 0.5, REAR - WALL * 0.5), Vector3(2 * W2, ROOM_H, WALL), CREAM)
	# Windows: arched stained glass, the same panel outside and in (the walls are solid).
	for side in [-1.0, 1.0]:
		var x_out: float = side * (W2 + 0.04)
		var x_in: float = side * (W2 - WALL - 0.04)
		var out_dir := Vector3(side, 0, 0)
		_window(shell, "Hall side window", Vector3(x_out, FLOOR + 1.3, -10.0), out_dir)
		for z in [-1.0, 4.0, 9.0]:
			_window(shell, "Room window", Vector3(x_out, FLOOR + 1.5, z), out_dir)
			_window(shell, "Room window inside", Vector3(x_in - side * 0.06, FLOOR + 1.5, z), -out_dir)
		_window(shell, "Front window", Vector3(side * 8.0, FLOOR + 1.3, FRONT - 0.04), Vector3(0, 0, -1))
		_window(shell, "Front window inside", Vector3(side * 8.0, FLOOR + 1.3, FRONT + WALL + 0.04), Vector3(0, 0, 1))
	for x in [-6.0, 6.0]:
		_window(shell, "Rear window", Vector3(x, FLOOR + 1.5, REAR + 0.04), Vector3(0, 0, 1))

## A wall along x (constant z) from x0 to x1, with rectangular openings [centre x, width, height].
func _x_wall(parent: Node3D, title: String, z: float, x0: float, x1: float, y0: float, y1: float, thick: float, color: Color, openings: Array, solid := true) -> void:
	var cursor := x0
	var sorted := openings.duplicate()
	sorted.sort_custom(func(a, b): return a[0] < b[0])
	for o in sorted:
		var left: float = o[0] - o[1] * 0.5
		var right: float = o[0] + o[1] * 0.5
		if left > cursor + 0.01:
			_box(parent, title, Vector3((cursor + left) * 0.5, (y0 + y1) * 0.5, z), Vector3(left - cursor, y1 - y0, thick), color, solid)
		var top: float = y0 + o[2]
		if y1 > top + 0.01:
			_box(parent, title + " lintel", Vector3(o[0], (top + y1) * 0.5, z), Vector3(o[1], y1 - top, thick), color, solid)
		cursor = right
	if x1 > cursor + 0.01:
		_box(parent, title, Vector3((cursor + x1) * 0.5, (y0 + y1) * 0.5, z), Vector3(x1 - cursor, y1 - y0, thick), color, solid)

## Gold trim round a rectangular opening: a half-round arch over its top edge (centred at `at`,
## the middle of the top edge) and a bar along that edge, facing `facing`.
func _arch_trim(parent: Node3D, title: String, at: Vector3, half_width: float, facing: Vector3) -> void:
	var holder := _group(parent, title)
	holder.transform = Transform3D(_front(facing), at)
	_mesh(holder, "Arch", _arc_tube(Vector3.ZERO, Vector3.RIGHT, Vector3.UP, half_width + 0.12, 0.0, PI, 0.1, 24), Transform3D(), _mat(GOLD))
	_mesh(holder, "Arch keystone", _star_mesh(0.3, 0.13, 0.05), Transform3D(Basis(), Vector3(0, half_width + 0.12, 0.05)), _mat(GOLD))
	_mesh(holder, "Arch tympanum", _half_disc(half_width + 0.05, 0.04), Transform3D(Basis(), Vector3(0, 0, -0.02)), _mat(Color("3a2a7a")))

## An arched stained-glass window centred on its sill at `at`, its glass facing `facing`.
func _window(parent: Node3D, title: String, at: Vector3, facing: Vector3, scale := 1.0) -> void:
	var holder := _group(parent, title)
	holder.transform = Transform3D(_front(facing).scaled(Vector3.ONE * scale), at)
	_box(holder, "Window frame", Vector3(0, 1.2, -0.02), Vector3(1.5, 2.4, 0.08), STONE, false)
	_mesh(holder, "Window frame top", _disc(0.75, 0.08, 24), Transform3D(Basis(Vector3.RIGHT, PI / 2), Vector3(0, 2.4, -0.02)), _mat(STONE))
	var glass := _glow(GLASS, 0.9)
	_mesh(holder, "Stained glass", _box_mesh(Vector3(1.16, 2.2, 0.06)), Transform3D(Basis(), Vector3(0, 1.3, 0.03)), glass)
	_mesh(holder, "Stained glass top", _disc(0.58, 0.06, 24), Transform3D(Basis(Vector3.RIGHT, PI / 2), Vector3(0, 2.4, 0.03)), glass)
	var violet := _glow(Color("8f5ad6"), 0.7)
	_mesh(holder, "Glass diamond", _box_mesh(Vector3(0.5, 0.5, 0.05)), Transform3D(Basis(Vector3.FORWARD, PI / 4), Vector3(0, 1.45, 0.07)), violet)
	_mesh(holder, "Glass star", _star_mesh(0.28, 0.12, 0.04), Transform3D(Basis(), Vector3(0, 2.45, 0.07)), _glow(Color("fff2b0"), 1.0))
	_mesh(holder, "Window arch", _arc_tube(Vector3(0, 2.4, 0.06), Vector3.RIGHT, Vector3.UP, 0.66, 0.0, PI, 0.05, 16), Transform3D(), _mat(GOLD))
	_box(holder, "Window sill", Vector3(0, 0.05, 0.08), Vector3(1.7, 0.12, 0.24), STONE_DARK, false)

# --- Roofs, drum and dome ---------------------------------------------------------------------

func _hall_roof() -> void:
	var roof := _group(house, "HallRoof")
	var y0 := FLOOR + HALL_H
	_box(roof, "Hall ceiling", Vector3(0, y0 + 0.15, (FRONT + HALL_REAR) * 0.5), Vector3(2 * W2, 0.3, HALL_REAR - FRONT), Color("f6efe6"))
	# A purple hip roof, its rear eave stopping at the mystery room's wall.
	var outer := Rect2(-W2 - 0.6, FRONT - 0.6, 2 * W2 + 1.2, (HALL_REAR - WALL * 0.5) - (FRONT - 0.6))
	var depth := outer.size.y
	var inner := Rect2(outer.position.x + depth * 0.5, outer.position.y + depth * 0.5, outer.size.x - depth, 0.0)
	_roof_mesh(roof, "Hall roof", outer, inner, y0 + 0.3, y0 + 0.3 + 3.0)
	for side in [-1.0, 1.0]:
		_box(roof, "Hall eave trim", Vector3(side * (W2 + 0.6), y0 + 0.36, (outer.position.y + outer.end.y) * 0.5), Vector3(0.12, 0.14, depth), GOLD, false)
	_box(roof, "Hall eave trim", Vector3(0, y0 + 0.36, FRONT - 0.6), Vector3(2 * W2 + 1.32, 0.14, 0.12), GOLD, false)
	_box(roof, "Hall ridge", Vector3(0, y0 + 3.33, inner.position.y), Vector3(inner.size.x + 0.2, 0.12, 0.16), GOLD, false)

func _room_roof_and_dome() -> void:
	var roof := _group(house, "RoomRoof")
	var y0 := FLOOR + ROOM_H
	var hole := Vector2(0, DOME_Z)
	var room := Rect2(-W2, HALL_REAR - WALL * 0.5, 2 * W2, REAR - (HALL_REAR - WALL * 0.5))
	# Ceiling slab with the round opening into the drum: a starry underside, a stone deck.
	var under := _holed_slab(room, hole, DOME_R, y0, false)
	_mesh(roof, "Starry ceiling", under, Transform3D(), _sky(NAVY))
	_mesh(roof, "Roof deck", _holed_slab(room, hole, DOME_R, y0 + 0.4, true), Transform3D(), _mat(STONE))
	_solid(roof, "Roof deck body", _holed_slab(room, hole, DOME_R, y0 + 0.4, true))
	# The purple roof rises from the eaves to a deck round the drum.
	var outer := Rect2(-W2 - 0.6, HALL_REAR - 0.8, 2 * W2 + 1.2, REAR + 0.6 - (HALL_REAR - 0.8))
	var inner := Rect2(-DOME_R - 0.5, DOME_Z - DOME_R - 0.5, 2 * DOME_R + 1.0, 2 * DOME_R + 1.0)
	_roof_mesh(roof, "Room roof", outer, inner, y0 + 0.4, y0 + 0.4 + HIP_RISE)
	_mesh(roof, "Roof top deck", _holed_slab(inner, hole, DOME_R, y0 + 0.4 + HIP_RISE, true), Transform3D(), _mat(ROOF_DARK))
	_box(roof, "Room eave trim", Vector3(0, y0 + 0.46, outer.position.y), Vector3(outer.size.x + 0.1, 0.14, 0.12), GOLD, false)
	_box(roof, "Room eave trim", Vector3(0, y0 + 0.46, outer.end.y), Vector3(outer.size.x + 0.1, 0.14, 0.12), GOLD, false)
	for side in [-1.0, 1.0]:
		_box(roof, "Room eave trim", Vector3(side * (W2 + 0.6), y0 + 0.46, (outer.position.y + outer.end.y) * 0.5), Vector3(0.12, 0.14, outer.size.y), GOLD, false)
	# Drum: from the ceiling to above the roof; cream outside, night sky inside.
	var drum_h := 0.4 + HIP_RISE + DRUM_SHOW
	var drum_mesh := CylinderMesh.new()
	drum_mesh.top_radius = DOME_R + 0.15
	drum_mesh.bottom_radius = DOME_R + 0.15
	drum_mesh.height = drum_h
	drum_mesh.radial_segments = 40
	drum_mesh.cap_top = false
	drum_mesh.cap_bottom = false
	_mesh(roof, "Drum", drum_mesh, Transform3D(Basis(), Vector3(0, y0 + drum_h * 0.5, DOME_Z)), _mat(CREAM))
	var drum_inner := drum_mesh.duplicate() as CylinderMesh
	drum_inner.top_radius = DOME_R
	drum_inner.bottom_radius = DOME_R
	_mesh(roof, "Drum inside", drum_inner, Transform3D(Basis(), Vector3(0, y0 + drum_h * 0.5, DOME_Z)), _sky(NAVY, true))
	var top := y0 + drum_h
	_mesh(roof, "Drum band", _arc_tube(Vector3(0, top - 0.25, DOME_Z), Vector3.RIGHT, Vector3.BACK, DOME_R + 0.2, 0.0, TAU, 0.12, 48), Transform3D(), _mat(GOLD))
	_mesh(roof, "Drum rim", _arc_tube(Vector3(0, top, DOME_Z), Vector3.RIGHT, Vector3.BACK, DOME_R + 0.18, 0.0, TAU, 0.16, 48), Transform3D(), _mat(GOLD))
	# Small round drum windows (glowing), eight round the drum.
	for i in 8:
		var a := TAU * (i + 0.5) / 8.0
		var dir := Vector3(cos(a), 0, sin(a))
		var at := Vector3(0, top - DRUM_SHOW * 0.5 - 0.1, DOME_Z) + dir * (DOME_R + 0.17)
		_mesh(roof, "Drum window", _disc(0.32, 0.05, 16), Transform3D(_front(dir) * Basis(Vector3.RIGHT, PI / 2), at), _glow(GLASS, 0.9))
	# The dome: purple outside with gold ribs, night sky inside, a crystal on top.
	var dome := SphereMesh.new()
	dome.radius = DOME_R + 0.15
	dome.height = DOME_R + 0.15
	dome.is_hemisphere = true
	dome.radial_segments = 40
	dome.rings = 14
	# A hemisphere's base is where its AABB starts: put that on the drum's top.
	# Without its flat base: from the room the base hid the starry inside (render review).
	_mesh(roof, "Dome", _open_dome(dome), Transform3D(Basis(), Vector3(0, top - dome.get_aabb().position.y, DOME_Z)), _mat(ROOF))
	var dome_inner := dome.duplicate() as SphereMesh
	dome_inner.radius = DOME_R
	dome_inner.height = DOME_R
	_mesh(roof, "Dome inside", dome_inner, Transform3D(Basis(), Vector3(0, top - dome_inner.get_aabb().position.y, DOME_Z)), _sky(NAVY, true))
	for i in 8:
		var a := TAU * i / 8.0
		_mesh(roof, "Dome rib", _arc_tube(Vector3(0, top, DOME_Z), Vector3(cos(a), 0, sin(a)), Vector3.UP, DOME_R + 0.2, 0.0, PI / 2, 0.09, 18), Transform3D(), _mat(GOLD))
	# Solid drum and dome, so the dome counts as a roof (day_night.gd's indoor probe) and can be
	# stood on.
	_solid(roof, "Drum body", _baked(drum_mesh, Transform3D(Basis(), Vector3(0, y0 + drum_h * 0.5, DOME_Z))))
	_solid(roof, "Dome body", _baked(dome, Transform3D(Basis(), Vector3(0, top - dome.get_aabb().position.y, DOME_Z))))
	var peak := top + DOME_R + 0.15
	var cap := CylinderMesh.new()
	cap.top_radius = 0.35
	cap.bottom_radius = 0.75
	cap.height = 0.5
	_mesh(roof, "Dome lantern base", cap, Transform3D(Basis(), Vector3(0, peak + 0.1, DOME_Z)), _mat(GOLD))
	var crystal := SphereMesh.new()
	crystal.radius = 0.55
	crystal.height = 1.9
	crystal.radial_segments = 6
	crystal.rings = 2
	_mesh(roof, "Crystal", crystal, Transform3D(Basis(), Vector3(0, peak + 1.25, DOME_Z)), _glow(Color("b98cff"), 0.6))
	# Stars: on the inside of the dome and drum, and on the flat ceiling round it.
	var star := _star_mesh(0.16, 0.07, 0.02)
	var star_light := _sky(Color("fff1b8"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261109
	for i in 70:
		var a := rng.randf() * TAU
		var up := rng.randf_range(0.15, 1.0)
		var dir := Vector3(cos(a) * sqrt(1.0 - up * up), up, sin(a) * sqrt(1.0 - up * up))
		var at := Vector3(0, top, DOME_Z) + dir * (DOME_R - 0.04)
		var s := rng.randf_range(0.6, 1.5)
		_mesh(roof, "Dome star", star, Transform3D(_front(-dir).scaled(Vector3.ONE * s), at), star_light)
	for i in 24:
		var a := rng.randf() * TAU
		var y := rng.randf_range(y0 + 0.2, top - 0.2)
		var dir := Vector3(cos(a), 0, sin(a))
		_mesh(roof, "Drum star", star, Transform3D(_front(-dir).scaled(Vector3.ONE * rng.randf_range(0.6, 1.2)), Vector3(0, y, DOME_Z) + dir * (DOME_R - 0.04)), star_light)
	var placed := 0
	while placed < 46:
		var p := Vector2(rng.randf_range(-W2 + 0.6, W2 - 0.6), rng.randf_range(HALL_REAR + 0.5, DOOR_WALL - 0.3))
		if p.distance_to(hole) < DOME_R + 0.4:
			continue
		placed += 1
		_mesh(roof, "Ceiling star", star, Transform3D(Basis(Vector3.RIGHT, PI / 2).scaled(Vector3.ONE * rng.randf_range(0.6, 1.6)), Vector3(p.x, y0 - 0.02, p.y)), star_light)
	# A soft violet light under the dome (one light for the room).
	var light := OmniLight3D.new()
	light.name = "Dome light"
	light.light_color = Color("c9b2ff")
	light.light_energy = 1.4
	light.omni_range = 15.0
	light.shadow_enabled = false
	roof.add_child(light)
	light.position = Vector3(0, FLOOR + 6.0, DOME_Z)

# --- Mystery room ---------------------------------------------------------------------------

func _room_interior() -> void:
	var room := _group(house, "MysteryRoom")
	# The zodiac wheel on the floor under the dome: a gold ring with twelve star markers.
	_mesh(room, "Zodiac wheel", _arc_tube(Vector3(0, FLOOR + 0.03, DOME_Z), Vector3.RIGHT, Vector3.BACK, 4.4, 0.0, TAU, 0.06, 64), Transform3D(), _mat(GOLD))
	_mesh(room, "Zodiac wheel inner", _arc_tube(Vector3(0, FLOOR + 0.03, DOME_Z), Vector3.RIGHT, Vector3.BACK, 3.6, 0.0, TAU, 0.04, 64), Transform3D(), _mat(GOLD))
	var marker := _star_mesh(0.22, 0.09, 0.02)
	for i in 12:
		var a := TAU * i / 12.0
		_mesh(room, "Zodiac marker", marker, Transform3D(Basis(Vector3.RIGHT, -PI / 2), Vector3(cos(a) * 4.0, FLOOR + 0.035, DOME_Z + sin(a) * 4.0)), _mat(GOLD))
	_mesh(room, "Floor star", _star_mesh(1.2, 0.5, 0.02), Transform3D(Basis(Vector3.RIGHT, -PI / 2), Vector3(0, FLOOR + 0.035, DOME_Z)), _mat(Color("c9a24a")))
	# The twelve constellations, six on each side wall, high up.
	for i in 12:
		var side := -1.0 if i < 6 else 1.0
		var z := HALL_REAR + 1.8 + (i % 6) * 2.45
		var at := Vector3(side * (W2 - WALL - 0.1), FLOOR + 5.8, z)
		_constellation(room, ZODIAC[i], at, Vector3(-side, 0, 0))
	# Madame Luna's round table with a crystal ball.
	var table: Node3D = _cyl(room, "Fortune table", Vector3(LUNA_SPOT.x - 1.3, FLOOR + 0.42, LUNA_SPOT.z + 1.0), 0.75, 0.84, Color("4b2f7a"), "table", true)
	var cloth := CylinderMesh.new()
	cloth.top_radius = 0.82
	cloth.bottom_radius = 0.9
	cloth.height = 0.5
	_mesh(table, "Table cloth", cloth, Transform3D(Basis(), Vector3(0, 0.2, 0)), _mat(Color("6c3fb5")))
	var ball := SphereMesh.new()
	ball.radius = 0.32
	ball.height = 0.64
	_mesh(table, "Crystal ball", ball, Transform3D(Basis(), Vector3(0, 0.82, 0)), _glow(Color("a8d8ff"), 0.8))
	var stand := CylinderMesh.new()
	stand.top_radius = 0.18
	stand.bottom_radius = 0.26
	stand.height = 0.16
	_mesh(table, "Ball stand", stand, Transform3D(Basis(), Vector3(0, 0.52, 0)), _mat(GOLD))
	# Wall sconces in the room (warm glow, no lights of their own).
	for side in [-1.0, 1.0]:
		for z in [-2.5, 6.5]:
			_lantern(room, "Room sconce", Vector3(side * (W2 - WALL - 0.36), FLOOR + 3.0, z), Vector3(-side, 0, 0))

## A round dark-blue plaque with gold stars joined by thin lines, its English name on a small
## nameplate below. The chart's pixel points are centred and scaled to fit the plaque.
func _constellation(parent: Node3D, sign: Dictionary, at: Vector3, facing: Vector3, size := 1.0) -> void:
	var holder := _group(parent, "Zodiac " + str(sign.name))
	holder.transform = Transform3D(_front(facing).scaled(Vector3.ONE * size), at)
	holder.set_meta("zodiac", sign.name)
	_mesh(holder, "Plaque", _disc(1.0, 0.06, 32), Transform3D(Basis(Vector3.RIGHT, PI / 2), Vector3.ZERO), _mat(Color("1e2a66")))
	_mesh(holder, "Plaque rim", _arc_tube(Vector3(0, 0, 0.04), Vector3.RIGHT, Vector3.UP, 1.0, 0.0, TAU, 0.05, 40), Transform3D(), _mat(GOLD))
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for p in sign.stars:
		low = Vector2(minf(low.x, p[0]), minf(low.y, p[1]))
		high = Vector2(maxf(high.x, p[0]), maxf(high.y, p[1]))
	var middle := (low + high) * 0.5
	var fit := 1.18 / maxf(high.x - low.x, high.y - low.y)
	var points: Array = []
	for p in sign.stars:
		points.append(Vector3((p[0] - middle.x) * fit, (middle.y - p[1]) * fit, 0.06))
	_mesh(holder, "Nameplate", _box_mesh(Vector3(2.1, 0.42, 0.04)), Transform3D(Basis(), Vector3(0, -1.27, 0.0)), _mat(Color("1e2a66")))
	_mesh(holder, "Nameplate rim", _box_mesh(Vector3(2.2, 0.52, 0.03)), Transform3D(Basis(), Vector3(0, -1.27, -0.02)), _mat(GOLD))
	var name_label := _label(holder, "Zodiac name", 58, Color("ffe7a3"))
	name_label.text = str(sign.name)
	name_label.position = Vector3(0, -1.27, 0.03)
	# Heavier strokes so the names stay readable from across the room (user, 10 Nov 2026).
	name_label.outline_size = 8
	name_label.outline_modulate = Color("ffe7a3")
	var line_mat := _sky(Color("c7b8ff"))
	for pair in sign.lines:
		var a: Vector3 = points[pair[0]]
		var b: Vector3 = points[pair[1]]
		var length := a.distance_to(b)
		var angle := atan2(b.y - a.y, b.x - a.x)
		_mesh(holder, "Line", _box_mesh(Vector3(length, 0.025, 0.01)), Transform3D(Basis(Vector3.BACK, angle), (a + b) * 0.5), line_mat)
	var star := _star_mesh(0.075, 0.033, 0.02)
	var star_mat := _sky(Color("fff1b8"))
	for p in points:
		_mesh(holder, "Star", star, Transform3D(Basis(), p + Vector3(0, 0, 0.01)), star_mat)

# --- The three doors --------------------------------------------------------------------------

func _doors() -> void:
	var wall := _group(house, "DoorWall")
	var top_room := FLOOR + ROOM_H
	_door_wall(wall, DOOR_WALL, FLOOR, false)
	# The alcoves behind the doors: dividers, a low starry ceiling, a glowing floor pad.
	for x in [-3.25, 3.25]:
		_box(wall, "Alcove divider", Vector3(x, (FLOOR + top_room) * 0.5, (DOOR_WALL + WALL + REAR - WALL) * 0.5), Vector3(0.3, ROOM_H, REAR - WALL - DOOR_WALL - WALL), INDIGO)
	var alcove_depth := REAR - WALL - DOOR_WALL - WALL
	_mesh(wall, "Alcove ceiling", _box_mesh(Vector3(2 * W2 - 2 * WALL, 0.2, alcove_depth)), Transform3D(Basis(), Vector3(0, FLOOR + DOOR_H + 0.4, DOOR_WALL + WALL + alcove_depth * 0.5)), _sky(NAVY))
	_box(wall, "Alcove floor", Vector3(0, FLOOR + 0.012, DOOR_WALL + WALL + alcove_depth * 0.5), Vector3(2 * W2 - 2 * WALL, 0.024, alcove_depth), Color("241b4d"), false)
	var star := _star_mesh(0.14, 0.06, 0.02)
	for x in DOOR_X:
		_mesh(wall, "Alcove glow", _disc(1.0, 0.03, 32), Transform3D(Basis(), Vector3(x, FLOOR + 0.03, ALCOVE_Z)), _glow(Color("b48cff"), 1.2))
		for k in 7:
			var p := Vector3(x + (k - 3) * 0.33, FLOOR + DOOR_H + 0.28, ALCOVE_Z + (0.5 if k % 2 == 0 else -0.4))
			_mesh(wall, "Alcove star", star, Transform3D(Basis(Vector3.RIGHT, PI / 2), p), _sky(Color("fff1b8")))
	_door_wall_decor(wall, DOOR_WALL, FLOOR)

## A lilac wall with the three doors, its room-side face at z, floor top f. `back`: the far side
## is seen too (the endless hall): a gold trim round each opening and lanterns and garlands there.
func _door_wall(wall: Node3D, z: float, f: float, back: bool) -> void:
	var openings: Array = []
	for x in DOOR_X:
		openings.append([x, DOOR_W + 0.2, DOOR_H + 0.1])
	_x_wall(wall, "Door wall", z + WALL * 0.5, -W2 + WALL, W2 - WALL, f, f + ROOM_H, WALL, LILAC, openings)
	for i in DOOR_X.size():
		_door(wall, i, z, f, back)
	if not back:
		return
	var face := z + WALL + 0.02
	for x in [-3.25, 3.25]:
		_lantern(wall, "Door lantern back", Vector3(x, f + 2.7, z + WALL + 0.36), Vector3(0, 0, 1))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1110
	for span in [[-11.2, -6.5], [-6.5, -1.7], [1.7, 6.5], [6.5, 11.2]]:
		_garland(wall, rng, Vector3(span[1], f + 6.4, face + 0.18), Vector3(span[0], f + 6.4, face + 0.18), 0.7, 1.0)

## One door, after the user's reference (9 Nov 2026): a cream stone arch on pedestals with gold
## capitals and keystone, and a hinged, arched leaf (the word root "door", with mystery_door.gd):
## planks, a gold border, a gold ring knocker and the four shape symbols (one shown). The leaf's
## painted meshes carry the meta leaf_paint (the session recolours them).
func _door(parent: Node3D, index: int, z := DOOR_WALL, f := FLOOR, back := false) -> void:
	var x: float = DOOR_X[index]
	var holder := _group(parent, DOOR_NAMES[index])
	# Holder +Z faces the room (local -z); holder +X is the viewer's right.
	holder.transform = Transform3D(_front(Vector3(0, 0, -1)), Vector3(x, f, z))
	holder.set_meta("mystery_door", index)
	var half := DOOR_W * 0.5
	var spring := DOOR_H - half
	# The wall above the leaf's round head (the opening in the wall is rectangular).
	_mesh(holder, "Door spandrel", _arch_panel(half + 0.02, half + 0.1, DOOR_H + 0.1 - spring, WALL), Transform3D(Basis(), Vector3(0, spring, -WALL * 0.5)), _mat(LILAC))
	# Stone surround: jambs on pedestals, gold capitals, the arch and a gold keystone.
	for side in [-1.0, 1.0]:
		var jx: float = side * (half + 0.27)
		_box(holder, "Door jamb", Vector3(jx, spring * 0.5, 0.15), Vector3(0.5, spring, 0.3), CREAM, false)
		_box(holder, "Door pedestal", Vector3(jx, 0.4, 0.2), Vector3(0.66, 0.8, 0.4), STONE, true)
		_mesh(holder, "Pedestal diamond rim", _disc(0.22, 0.02, 4, true), Transform3D(Basis(), Vector3(jx, 0.42, 0.405)), _mat(GOLD))
		_mesh(holder, "Pedestal diamond", _disc(0.16, 0.02, 4, true), Transform3D(Basis(), Vector3(jx, 0.42, 0.415)), _mat(RUG))
		_box(holder, "Door capital", Vector3(jx, spring - 0.08, 0.17), Vector3(0.62, 0.16, 0.36), GOLD, false)
	_mesh(holder, "Door arch stones", _half_ring(half + 0.02, half + 0.52, 0.3), Transform3D(Basis(), Vector3(0, spring, 0.15)), _mat(CREAM))
	_box(holder, "Door keystone", Vector3(0, spring + half + 0.27, 0.18), Vector3(0.44, 0.52, 0.36), GOLD, false)
	_mesh(holder, "Keystone diamond", _disc(0.12, 0.02, 4, true), Transform3D(Basis(), Vector3(0, spring + half + 0.27, 0.365)), _mat(RUG))
	if back:
		# The far side (the endless hall): a flat gold trim just outside the opening, clear of
		# the leaf, which swings out that way.
		# "Back": shown only for the door the player just came through (user, 9 Nov 2026: one
		# door behind); "Back cover": a plain lilac panel over the other openings (solid, so
		# nothing behind it can be picked). The session switches them.
		var b := -WALL - 0.03
		var trim := _group(holder, "Back")
		_mesh(trim, "Door back trim", _arc_tube(Vector3(0, spring, b), Vector3.RIGHT, Vector3.UP, half + 0.22, 0.0, PI, 0.07, 24), Transform3D(), _mat(GOLD))
		for side in [-1.0, 1.0]:
			_box(trim, "Door back jamb", Vector3(side * (half + 0.22), spring * 0.5, b), Vector3(0.14, spring, 0.06), GOLD, false)
		var cover := _group(holder, "Back cover")
		_box(cover, "Back cover panel", Vector3(0, (DOOR_H + 0.1) * 0.5, -WALL - 0.04), Vector3(DOOR_W + 0.24, DOOR_H + 0.1, 0.08), LILAC)
		cover.visible = false
	# The leaf turns on the hinge at the viewer's left edge; it opens away from the room
	# (step hinges_right moves the hinge to the right edge).
	var hinge := _group(holder, "Hinge")
	hinge.position = Vector3(-half, 0, -0.02)
	var defaults: Array = DOOR_DEFAULTS[index]
	var leaf: Node3D = game.box("Door leaf", Vector3.ZERO, Vector3(DOOR_W, spring, 0.12), COLORS[defaults[0]], "door", true)
	leaf.reparent(hinge, false)
	leaf.position = Vector3(half, spring * 0.5, 0)
	for child in leaf.get_children():
		if child is MeshInstance3D:
			child.set_meta("leaf_paint", true)
			break
	leaf.set_script(preload("res://scripts/world/mystery_door.gd"))
	leaf.set_meta("mystery_door", index)
	leaf.set_meta("door_color", defaults[0])
	leaf.set_meta("door_shape", defaults[1])
	# The round head of the leaf (painted with it, solid, so it can be clicked too).
	var head := _half_disc(half, 0.12, 32)
	var top := _mesh(leaf, "Leaf top", head, Transform3D(Basis(), Vector3(0, spring * 0.5, 0)), _mat(COLORS[defaults[0]]))
	top.set_meta("leaf_paint", true)
	var head_body := _group(leaf, "Leaf top body")
	head_body.position = Vector3(0, spring * 0.5, 0)
	_solid(head_body, "Leaf top solid", head)
	# Planks: faint dark grooves (any door colour).
	for gx in [-0.65, 0.0, 0.65]:
		var reach := spring * 0.5 + sqrt(half * half - gx * gx) - 0.06
		var from := -spring * 0.5 + 0.04
		_mesh(leaf, "Plank groove", _box_mesh(Vector3(0.03, reach - from, 0.01)), Transform3D(Basis(), Vector3(gx, (reach + from) * 0.5, 0.062)), _groove())
	# Gold border, ring knocker and two studs.
	var inset := 0.17
	for side in [-1.0, 1.0]:
		_mesh(leaf, "Leaf trim", _box_mesh(Vector3(0.06, spring - inset, 0.02)), Transform3D(Basis(), Vector3(side * (half - inset), inset * 0.5, 0.07)), _mat(GOLD))
		_mesh(leaf, "Leaf stud", _disc(0.07, 0.03, 4, true), Transform3D(Basis(), Vector3(side * (half - 0.4), -0.35, 0.075)), _mat(GOLD))
	_mesh(leaf, "Leaf trim", _box_mesh(Vector3(DOOR_W - 2 * inset + 0.06, 0.06, 0.02)), Transform3D(Basis(), Vector3(0, -spring * 0.5 + inset, 0.07)), _mat(GOLD))
	_mesh(leaf, "Leaf trim arch", _arc_tube(Vector3(0, spring * 0.5, 0.07), Vector3.RIGHT, Vector3.UP, half - inset, 0.0, PI, 0.03, 24), Transform3D(), _mat(GOLD))
	var ring := TorusMesh.new()
	ring.inner_radius = 0.12
	ring.outer_radius = 0.17
	_mesh(leaf, "Door knocker", ring, Transform3D(Basis(Vector3.RIGHT, PI / 2), Vector3(0, -0.4, 0.1)), _mat(GOLD))
	_mesh(leaf, "Knocker plate", _box_mesh(Vector3(0.14, 0.16, 0.03)), Transform3D(Basis(), Vector3(0, -0.2, 0.075)), _mat(GOLD))
	# The shape: a dark outline, a gold rim and a pale centre (it reads on every door colour).
	var symbols := _group(leaf, "Symbols")
	symbols.position = Vector3(0, 1.15, 0.07)
	for shape in SHAPES:
		var holder_shape := _group(symbols, shape)
		_mesh(holder_shape, "Edge", _shape_mesh(shape, 0.66, 0.02), Transform3D(Basis(), Vector3.ZERO), _mat(SYMBOL_EDGE))
		_mesh(holder_shape, "Rim", _shape_mesh(shape, 0.6, 0.02), Transform3D(Basis(), Vector3(0, 0, 0.012)), _mat(GOLD))
		_mesh(holder_shape, "Fill", _shape_mesh(shape, 0.46, 0.02), Transform3D(Basis(), Vector3(0, 0, 0.024)), _mat(SYMBOL))
		holder_shape.visible = shape == defaults[1]

## The door wall round the doors (user reference, 9 Nov 2026): lanterns between the doors, a
## stained-glass half window over the middle one, flowering garlands, urns, crystals and a purple
## rug with a gold compass star in front of the middle door.
func _door_wall_decor(wall: Node3D, z: float, f: float) -> void:
	var face := z - 0.02
	for x in [-3.25, 3.25]:
		_lantern(wall, "Door lantern", Vector3(x, f + 2.7, z - 0.36), Vector3(0, 0, -1))
	var window := _group(wall, "Star window")
	window.transform = Transform3D(_front(Vector3(0, 0, -1)), Vector3(0, f + 5.3, face))
	_mesh(window, "Star window glass", _half_disc(1.45, 0.04), Transform3D(), _glow(Color("7f55d6"), 0.8))
	_mesh(window, "Star window frame", _arc_tube(Vector3(0, 0, 0.03), Vector3.RIGHT, Vector3.UP, 1.5, 0.0, PI, 0.07, 28), Transform3D(), _mat(GOLD))
	_mesh(window, "Star window sill", _box_mesh(Vector3(3.2, 0.14, 0.12)), Transform3D(Basis(), Vector3(0, 0, 0.04)), _mat(GOLD))
	for a in [PI / 3.0, 2.0 * PI / 3.0]:
		var dir := Vector3(cos(a), sin(a), 0)
		_mesh(window, "Star window mullion", _box_mesh(Vector3(0.05, 1.45, 0.04)), Transform3D(Basis(Vector3.BACK, a - PI / 2), dir * 0.725 + Vector3(0, 0, 0.03)), _mat(GOLD))
	_mesh(window, "Star window star", _star_mesh(0.42, 0.16, 0.04), Transform3D(Basis(), Vector3(0, 0.62, 0.05)), _glow(Color("ffe08a"), 1.2))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1109
	for span in [[-11.2, -6.5], [-6.5, -1.7], [1.7, 6.5], [6.5, 11.2]]:
		_garland(wall, rng, Vector3(span[0], f + 6.4, face - 0.18), Vector3(span[1], f + 6.4, face - 0.18), 0.7)
	for side in [-1.0, 1.0]:
		_planter(wall, "Door urn", Vector3(side * 9.35, f, z - 0.9), 0.42, FLOWER_PINK)
		var pedestal := _box(wall, "Crystal pedestal", Vector3(side * 10.85, f + 0.55, z - 0.55), Vector3(0.6, 1.1, 0.6), CREAM)
		_box(pedestal, "Pedestal band", Vector3(0, 0.5, 0), Vector3(0.66, 0.1, 0.66), GOLD, false)
		var crystal := SphereMesh.new()
		crystal.radius = 0.12
		crystal.height = 0.6
		crystal.radial_segments = 6
		crystal.rings = 2
		for k in 3:
			var tilt := (k - 1) * 0.35
			_mesh(pedestal, "Crystal", crystal, Transform3D(Basis(Vector3.BACK, tilt).scaled(Vector3.ONE * (1.0 if k == 1 else 0.75)), Vector3((k - 1) * 0.1, 0.78 - absf(k - 1) * 0.06, 0)), _glow(Color("b98cff"), 1.1))
	# The rug in front of the middle door: purple, a gold ring and a four-point compass star.
	var rug_at := Vector3(0, f + 0.03, z - 2.0)
	_mesh(wall, "Door rug", _disc(1.6, 0.02, 40), Transform3D(Basis(), rug_at), _mat(RUG))
	_mesh(wall, "Door rug ring", _arc_tube(rug_at + Vector3(0, 0.012, 0), Vector3.RIGHT, Vector3.BACK, 1.4, 0.0, TAU, 0.03, 48), Transform3D(), _mat(GOLD))
	for k in 4:
		var long := 1.25 if k < 2 else 0.7
		var turn := Basis(Vector3.UP, k * PI / 2.0 if k < 2 else PI / 4.0 + (k - 2) * PI / 2.0)
		_mesh(wall, "Door rug star", _box_mesh(Vector3(1, 0.012, 1)), Transform3D(turn * Basis.from_scale(Vector3(0.28, 1, long)) * Basis(Vector3.UP, PI / 4), rug_at + Vector3(0, 0.014 + k * 0.001, 0)), _mat(GOLD))

## Step (user change, 9 Nov 2026: "the mystery house should feel like an endless hall"): the
## endless hall under the house, added to the baked house.
func endless_hall(town: Node3D, main) -> void:
	game = main
	house = town.get_node(ROOT)
	_endless_hall()

## Step (user, 9 Nov 2026: "place the hinges on the other side"): every mystery door turns on its
## right edge (seen from the side it is opened from) instead of its left; it still opens away
## from the player (meta swing -1 for mystery_door.gd).
func hinges_right(town: Node3D, main) -> void:
	game = main
	house = town.get_node(ROOT)
	var half := DOOR_W * 0.5
	for leaf in house.find_children("Door leaf", "", true, false):
		var hinge := leaf.get_parent() as Node3D
		if hinge == null or hinge.name != "Hinge" or not leaf.has_meta("mystery_door"):
			continue
		hinge.position.x = half
		leaf.position.x = -half
		leaf.set_meta("swing", -1.0)

## Redrawn constellations with English nameplates (user, 10 Nov 2026): the mystery room's twelve
## plaques (built by build_house) are replaced in place by the current _constellation(). The
## endless hall's plaques already use it (step endless_hall).
## The room's plaques are a little smaller and higher than build_house made them, so their
## nameplates clear the stained-glass windows below (window tops at FLOOR + 4.65).
const ROOM_ZODIAC_SIZE := 0.8
const ROOM_ZODIAC_Y := FLOOR + 6.0

func zodiac_signs(town: Node3D, main) -> void:
	game = main
	house = town.get_node(ROOT)
	var room := house.get_node("MysteryRoom") as Node3D
	for i in 12:
		var old := room.get_node_or_null("Zodiac " + str(ZODIAC[i].name)) as Node3D
		if old == null:
			continue
		var at := Vector3(old.position.x, ROOM_ZODIAC_Y, old.position.z)
		var facing := old.basis.z.normalized()
		room.remove_child(old)
		old.free()
		_constellation(room, ZODIAC[i], at, facing, ROOM_ZODIAC_SIZE)

## Step (user, 10 Nov 2026: "more texture on the doors, front and back, and a better overall
## design"): every mystery door leaf (the mystery room's and the endless hall's) gets storybook
## detail on both faces. Front: iron strap hinges with arrow tips and gold nails, barrel knuckles
## on the hinge edge, two carved raised panels (gold bead, gold diamond), an iron kick plate with
## nails and a gold star boss in the arch head; the planks, border, knocker, studs and shape symbol
## stay. Back: the gold border, three ledges and two braces (a ledged-and-braced door), iron straps
## on the ledges, a ring pull, a sliding bolt, the kick plate and the star boss. Each leaf's
## additions are merged into three meshes (gold, iron and the leaf's own paint; the painted one
## carries meta leaf_paint, so the session recolours it with the leaf) plus translucent dark lines
## along the battens' edges (they share the leaf's colour): the leaves are processed
## and never batched, so they stay a few draw calls each. The endless hall's "Back" surround (the
## one door seen behind the player) gets a cream stone arch, pilasters on pedestals, gold capitals
## and a keystone round the gold trim, all clear of the leaf's swing (it opens about 100 degrees
## that way and is only 0.12 thick near the hinge).
const IRON := Color("2f2a3a")
## Leaf half-thickness (mystery.gd _door: the leaf box is 0.12 deep).
const LEAF_T := 0.06

func door_faces(town: Node3D, main) -> void:
	game = main
	house = town.get_node(ROOT)
	for leaf in house.find_children("Door leaf", "", true, false):
		if not leaf.has_meta("mystery_door") or leaf.get_parent() == null or leaf.get_parent().name != "Hinge":
			continue
		_leaf_faces(leaf)
		var back := leaf.get_parent().get_parent().get_node_or_null("Back") as Node3D
		if back != null:
			_back_surround(back)

func _leaf_faces(leaf: Node3D) -> void:
	var half := DOOR_W * 0.5
	var spring := DOOR_H - half
	var bottom := -spring * 0.5
	# The centre of the round head (the leaf's origin is the middle of its square part).
	var head := spring * 0.5
	# The hinge edge: +1 at the leaf's local +x (step hinges_right), -1 at -x.
	var e := -float(leaf.get_meta("swing", 1.0))
	var gold: Array = []
	var iron: Array = []
	var paint: Array = []
	var shade: Array = []
	var inset := 0.17
	var nail := _disc(0.028, 0.02, 6, true)
	var boss := _star_mesh(0.15, 0.065, 0.03)
	for face in [1.0, -1.0]:
		var z: float = face * LEAF_T
		var turn := Basis() if face > 0.0 else Basis(Vector3.UP, PI)
		# An iron kick plate along the bottom with a row of gold nails.
		iron.append([_box_mesh(Vector3(DOOR_W - 0.12, 0.15, 0.02)), Transform3D(Basis(), Vector3(0, bottom + 0.1, z + face * 0.01))])
		for k in 7:
			gold.append([nail, Transform3D(turn, Vector3(-1.02 + k * 0.34, bottom + 0.1, z + face * 0.024))])
		# A gold star boss high in the arch head.
		gold.append([boss, Transform3D(turn, Vector3(0, head + 0.92, z + face * 0.018))])
	# Barrel knuckles on the hinge edge (seen from both sides).
	var knuckle := CylinderMesh.new()
	knuckle.top_radius = 0.05
	knuckle.bottom_radius = 0.05
	knuckle.height = 0.24
	knuckle.radial_segments = 8
	knuckle.rings = 1
	for y in [-0.62, 0.15, 1.2]:
		iron.append([knuckle, Transform3D(Basis(), Vector3(e * half, y, 0))])
	# Front (+z): three strap hinges from the hinge edge, clear of the knocker, studs and symbol.
	var fz := LEAF_T + 0.035
	_strap(iron, gold, -0.62, e * (half - 0.02), e * 0.35, fz, 1.0)
	_strap(iron, gold, 0.15, e * (half - 0.02), e * 0.42, fz, 1.0)
	var top_y := head + 0.6
	_strap(iron, gold, top_y, e * (sqrt(half * half - 0.36) - 0.04), -e * 0.55, fz, 1.0)
	# Two carved raised panels low on the front: a painted frame, a fielded centre, a gold bead
	# and a gold diamond.
	for side in [-1.0, 1.0]:
		var c := Vector3(side * 0.55, -1.0, 0)
		paint.append([_box_mesh(Vector3(0.82, 0.5, 0.03)), Transform3D(Basis(), c + Vector3(0, 0, LEAF_T + 0.015))])
		paint.append([_box_mesh(Vector3(0.58, 0.28, 0.02)), Transform3D(Basis(), c + Vector3(0, 0, LEAF_T + 0.04))])
		for bead in [[Vector3(0, 0.205, 0), Vector3(0.72, 0.022, 0.012)], [Vector3(0, -0.205, 0), Vector3(0.72, 0.022, 0.012)], [Vector3(0.35, 0, 0), Vector3(0.022, 0.43, 0.012)], [Vector3(-0.35, 0, 0), Vector3(0.022, 0.43, 0.012)]]:
			gold.append([_box_mesh(bead[1]), Transform3D(Basis(), c + bead[0] + Vector3(0, 0, LEAF_T + 0.036))])
		gold.append([_disc(0.07, 0.02, 4, true), Transform3D(Basis(), c + Vector3(0, 0, LEAF_T + 0.055))])
	# Back (-z): the gold border as on the front.
	var bz := -LEAF_T - 0.01
	for side in [-1.0, 1.0]:
		gold.append([_box_mesh(Vector3(0.06, spring - inset, 0.02)), Transform3D(Basis(), Vector3(side * (half - inset), inset * 0.5, bz))])
	gold.append([_box_mesh(Vector3(DOOR_W - 2 * inset + 0.06, 0.06, 0.02)), Transform3D(Basis(), Vector3(0, bottom + inset + 0.08, bz))])
	gold.append([_arc_tube(Vector3(0, head, bz), Vector3.RIGHT, Vector3.UP, half - inset, 0.0, PI, 0.03, 24), Transform3D()])
	# Ledges and braces (painted with the leaf), the braces rising from the hinge side.
	var ledges := [-0.95, 0.15, 1.2]
	var lz := -LEAF_T - 0.025
	# Dark shadow lines along every batten edge, on the leaf and on the batten's face, so the
	# battens read although they share the leaf's colour.
	var ledge_w := 2.0 * (half - inset) - 0.1
	for y in ledges:
		paint.append([_box_mesh(Vector3(ledge_w, 0.24, 0.05)), Transform3D(Basis(), Vector3(0, y, lz))])
		for edge in [-1.0, 1.0]:
			shade.append([_box_mesh(Vector3(ledge_w, 0.035, 0.004)), Transform3D(Basis(), Vector3(0, y + edge * 0.137, -LEAF_T - 0.003))])
			shade.append([_box_mesh(Vector3(ledge_w, 0.02, 0.004)), Transform3D(Basis(), Vector3(0, y + edge * 0.11, lz - 0.027))])
	for k in 2:
		var a := Vector2(e * 0.78, ledges[k] + 0.12)
		var b := Vector2(-e * 0.78, ledges[k + 1] - 0.12)
		var d := b - a
		var mid := (a + b) * 0.5
		var tilt := Basis(Vector3.BACK, d.angle())
		paint.append([_box_mesh(Vector3(d.length(), 0.2, 0.04)), Transform3D(tilt, Vector3(mid.x, mid.y, lz))])
		for edge in [-1.0, 1.0]:
			var off := tilt * Vector3(0, edge * 0.117, 0)
			shade.append([_box_mesh(Vector3(d.length() - 0.1, 0.035, 0.004)), Transform3D(tilt, Vector3(mid.x, mid.y, -LEAF_T - 0.003) + off)])
			off = tilt * Vector3(0, edge * 0.09, 0)
			shade.append([_box_mesh(Vector3(d.length() - 0.1, 0.02, 0.004)), Transform3D(tilt, Vector3(mid.x, mid.y, lz - 0.022) + off)])
	# The arched head reads as part of the same door (user, 10 Nov 2026: the back looked like a
	# rectangle under a plain half-circle): plank grooves from the bottom right up into the arch,
	# as on the front, and a painted arched head rail standing on the top ledge, with shadow lines.
	for gx in [-0.65, 0.0, 0.65]:
		var reach := head + sqrt(half * half - gx * gx) - 0.06
		var from := bottom + 0.04
		shade.append([_box_mesh(Vector3(0.03, reach - from, 0.004)), Transform3D(Basis(), Vector3(gx, (reach + from) * 0.5, -LEAF_T - 0.003))])
	var rail_r := half - inset - 0.16
	paint.append([_arc_tube(Vector3(0, head, lz), Vector3.RIGHT, Vector3.UP, rail_r, 0.0, PI, 0.1, 24), Transform3D()])
	# An iron band with gold nails along the rail, so the arch reads on every door colour (the
	# painted rail alone barely shows on the yellow door).
	iron.append([_arc_tube(Vector3(0, head, lz - 0.085), Vector3.RIGHT, Vector3.UP, rail_r, 0.0, PI, 0.04, 24), Transform3D()])
	var back_nail := _disc(0.026, 0.02, 6, true)
	for k in 7:
		var t := PI * (k + 0.5) / 7.0
		gold.append([back_nail, Transform3D(Basis(Vector3.UP, PI), Vector3(cos(t) * rail_r, head + sin(t) * rail_r, lz - 0.13))])
	# Short uprights carry the rail down onto the top ledge.
	var ledge_top: float = ledges[2] + 0.12
	for side in [-1.0, 1.0]:
		paint.append([_box_mesh(Vector3(0.2, head - ledge_top + 0.02, 0.04)), Transform3D(Basis(), Vector3(side * rail_r, (head + ledge_top) * 0.5, lz))])
	for edge in [-1.0, 1.0]:
		shade.append([_arc_tube(Vector3(0, head, -LEAF_T - 0.003), Vector3.RIGHT, Vector3.UP, rail_r + edge * 0.12, 0.0, PI, 0.017, 24), Transform3D()])
	# Iron straps on the ledges, a ring pull and a sliding bolt on the latch side.
	var sz := -LEAF_T - 0.05 - 0.012
	for y in ledges:
		_strap(iron, gold, y, e * (half - 0.02), -e * 0.25, sz, -1.0)
	iron.append([_box_mesh(Vector3(0.16, 0.2, 0.02)), Transform3D(Basis(), Vector3(-e * 0.8, -0.37, -LEAF_T - 0.01))])
	var ring := TorusMesh.new()
	ring.inner_radius = 0.1
	ring.outer_radius = 0.14
	ring.rings = 16
	ring.ring_segments = 6
	iron.append([ring, Transform3D(Basis(Vector3.RIGHT, PI / 2), Vector3(-e * 0.8, -0.45, -LEAF_T - 0.04))])
	iron.append([_box_mesh(Vector3(0.55, 0.05, 0.03)), Transform3D(Basis(), Vector3(-e * 0.86, 0.65, -LEAF_T - 0.035))])
	for x in [-e * 0.7, -e * 1.02]:
		iron.append([_box_mesh(Vector3(0.06, 0.12, 0.05)), Transform3D(Basis(), Vector3(x, 0.65, -LEAF_T - 0.025))])
	gold.append([_disc(0.035, 0.08, 8, true), Transform3D(Basis(), Vector3(-e * 0.62, 0.65, -LEAF_T - 0.07))])
	var painted: Material = null
	for child in leaf.get_children():
		if child is MeshInstance3D and child.get_meta("leaf_paint", false):
			painted = child.get_active_material(0)
			break
	_mesh(leaf, "Leaf carving", _merged(paint), Transform3D(), painted if painted != null else _mat(COLORS["red"])).set_meta("leaf_paint", true)
	_mesh(leaf, "Leaf ironwork", _merged(iron), Transform3D(), _mat(IRON))
	_mesh(leaf, "Leaf gilding", _merged(gold), Transform3D(), _mat(GOLD))
	_mesh(leaf, "Leaf batten shadows", _merged(shade), Transform3D(), _batten_shadow())

func _batten_shadow() -> StandardMaterial3D:
	if not _materials.has("batten_shadow"):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.05, 0.02, 0.1, 0.45)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 0.9
		_materials["batten_shadow"] = m
	return _materials["batten_shadow"]

## An iron strap hinge on a leaf face (`face` +1 front, -1 back) at height y, from x0 (the hinge
## edge) to x1, its centre `z` deep: a bar, a diamond arrow tip and gold nails.
func _strap(iron: Array, gold: Array, y: float, x0: float, x1: float, z: float, face: float) -> void:
	var length := absf(x1 - x0)
	iron.append([_box_mesh(Vector3(length, 0.11, 0.022)), Transform3D(Basis(), Vector3((x0 + x1) * 0.5, y, z))])
	iron.append([_disc(0.11, 0.022, 4, true), Transform3D(Basis(), Vector3(x1, y, z))])
	var nail := _disc(0.026, 0.02, 6, true)
	var count := maxi(2, int(length / 0.32))
	for k in count:
		var x := lerpf(x0, x1, (k + 0.5) / count)
		gold.append([nail, Transform3D(Basis(), Vector3(x, y, z + face * 0.014))])
	gold.append([nail, Transform3D(Basis(), Vector3(x1, y, z + face * 0.014))])

## The stone surround on the far side of a hall door (inside its "Back" group, holder space: the
## far wall face at z -WALL), outside the gold trim and clear of the swinging leaf.
func _back_surround(back: Node3D) -> void:
	var half := DOOR_W * 0.5
	var spring := DOOR_H - half
	var z := -WALL - 0.045
	var cream: Array = []
	var gold: Array = []
	cream.append([_half_ring(half + 0.3, half + 0.62, 0.09), Transform3D(Basis(), Vector3(0, spring, z))])
	for side in [-1.0, 1.0]:
		var x: float = side * (half + 0.46)
		cream.append([_box_mesh(Vector3(0.32, spring, 0.09)), Transform3D(Basis(), Vector3(x, spring * 0.5, z))])
		cream.append([_box_mesh(Vector3(0.44, 0.7, 0.13)), Transform3D(Basis(), Vector3(x, 0.35, z - 0.02))])
		gold.append([_box_mesh(Vector3(0.44, 0.12, 0.13)), Transform3D(Basis(), Vector3(x, spring - 0.06, z - 0.02))])
		gold.append([_box_mesh(Vector3(0.46, 0.06, 0.14)), Transform3D(Basis(), Vector3(x, 0.72, z - 0.02))])
		gold.append([_disc(0.12, 0.02, 4, true), Transform3D(Basis(Vector3.UP, PI), Vector3(x, 0.36, z - 0.09))])
	gold.append([_box_mesh(Vector3(0.38, 0.46, 0.13)), Transform3D(Basis(), Vector3(0, spring + half + 0.46, z - 0.02))])
	gold.append([_star_mesh(0.13, 0.055, 0.02), Transform3D(Basis(Vector3.UP, PI), Vector3(0, spring + half + 0.46, z - 0.095))])
	_mesh(back, "Door back stone", _merged(cream), Transform3D(), _mat(CREAM))
	_mesh(back, "Door back gold", _merged(gold), Transform3D(), _mat(GOLD))

## Several meshes (each [mesh, transform]) merged into one surface: one draw call. Every part is
## de-indexed first: appended to a tool that an indexed part (a box, a disc) had made indexed,
## the plain triangle lists (_tri_mesh: arcs, stars) were dropped (10 Nov 2026, the doors' arch
## borders, star bosses and the back's head rail never showed).
func _merged(parts: Array) -> ArrayMesh:
	var tool := SurfaceTool.new()
	for part in parts:
		var plain := SurfaceTool.new()
		plain.create_from(part[0], 0)
		plain.deindex()
		tool.append_from(plain.commit(), 0, part[1])
	return tool.commit()

## Step (user, 10 Nov 2026: the mystery room looked night-blue in most places at night, light
## lilac under the dome). day_night.gd counts a spot as indoors only if a ray straight up hits a
## StaticBody3D; the room's only roof collider was the deck's one-sided, upward-facing trimesh
## (build_house), which rays from below pass through, so only the dome counted and the rest of
## the room took the outdoor night ambient. A plain box collider just above the starry ceiling
## (over the whole room and alcoves, the dome opening too: out of reach) makes the whole room
## indoors. No mesh and no light (performance first); it also stops the camera arm at the ceiling.
func room_ceiling(town: Node3D, main) -> void:
	game = main
	house = town.get_node(ROOT)
	var roof := house.get_node("RoomRoof") as Node3D
	var z0 := HALL_REAR - WALL * 0.5
	var body := StaticBody3D.new()
	body.name = "Room ceiling body"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2 * W2, 0.3, REAR - z0)
	shape.shape = box
	body.add_child(shape)
	roof.add_child(body, true)
	body.position = Vector3(0, FLOOR + ROOM_H + 0.2, (z0 + REAR) * 0.5)

## Step (user, 10 Nov 2026: the game starts in the mystery room; approved: at the first right
## door the player is swapped, in the same frame, to the hall's wall B, mystery_session.gd
## _swap_into_hall): each endless hall room is dressed like the mystery room's door end, at the
## same distances from its door wall (DOOR_WALL there, HALL_WALLS[1] / [2] here), so the player's
## view does not change at the swap. Both rooms stay identical (the step back still works). Out:
## the runner (word carpet), the hall plaques and sconces, and the hall's cornice and skirting
## (the room has none). In: the room's inside windows, sconces and constellation plaques (the same
## signs, size and height as zodiac_signs) and the floor's zodiac wheel, cut where it meets the
## wall behind. Not matched: the dome above the room and Luna's corner (well behind the player).
func room_twin(town: Node3D, main) -> void:
	game = main
	house = town.get_node(ROOT)
	var hall := house.get_node(ENDLESS) as Node3D
	for child in hall.get_children():
		var title := str(child.name)
		if title.begins_with("Endless cornice") or title.begins_with("Endless skirting"):
			hall.remove_child(child)
			child.free()
	for k in HALL_WALLS.size() - 1:
		var room := hall.get_node("Endless room %d" % (k + 1)) as Node3D
		for child in room.get_children():
			var title := str(child.name)
			if title.begins_with("Runner") or title.begins_with("Zodiac ") or title.begins_with("Hall sconce"):
				room.remove_child(child)
				child.free()
		_room_twin(room, float(HALL_WALLS[k]) + WALL, float(HALL_WALLS[k + 1]), ENDLESS_FLOOR)

## The mystery room's door-end dressing in one hall room from z0 (the far face of the wall
## behind) to wz (the next door wall's room face), floor top f: a room z maps to wz - (DOOR_WALL - z).
func _room_twin(room: Node3D, z0: float, wz: float, f: float) -> void:
	var twin := _group(room, "Room twin")
	var at := func(z: float) -> float: return wz - (DOOR_WALL - z)
	for side in [-1.0, 1.0]:
		var x_in: float = side * (W2 - WALL - 0.04)
		for z in [4.0, 9.0]:
			_window(twin, "Room window inside", Vector3(x_in - side * 0.06, f + 1.5, at.call(z)), Vector3(-side, 0, 0))
		_lantern(twin, "Room sconce", Vector3(side * (W2 - WALL - 0.36), f + 3.0, at.call(6.5)), Vector3(-side, 0, 0))
	for i in 12:
		var side := -1.0 if i < 6 else 1.0
		var z: float = at.call(HALL_REAR + 1.8 + (i % 6) * 2.45)
		if z - ROOM_ZODIAC_SIZE < z0:
			continue
		_constellation(twin, ZODIAC[i], Vector3(side * (W2 - WALL - 0.1), f + (ROOM_ZODIAC_Y - FLOOR), z), Vector3(-side, 0, 0), ROOM_ZODIAC_SIZE)
	# The zodiac wheel (as _room_interior), its rings cut at the wall behind.
	var c := Vector3(0, f + 0.03, at.call(DOME_Z))
	for ring in [[4.4, 0.06, "Zodiac wheel"], [3.6, 0.04, "Zodiac wheel inner"]]:
		var r: float = ring[0]
		var reach := (z0 + 0.05 - c.z) / r
		var a0 := -PI if reach <= -1.0 else asin(reach)
		var a1 := PI if reach <= -1.0 else PI - asin(reach)
		_mesh(twin, ring[2], _arc_tube(c, Vector3.RIGHT, Vector3.BACK, r, a0, a1, ring[1], 64), Transform3D(), _mat(GOLD))
	var marker := _star_mesh(0.22, 0.09, 0.02)
	for i in 12:
		var a := TAU * i / 12.0
		var p := Vector3(cos(a) * 4.0, 0.005, sin(a) * 4.0) + c
		if p.z - 0.25 < z0:
			continue
		_mesh(twin, "Zodiac marker", marker, Transform3D(Basis(Vector3.RIGHT, -PI / 2), p), _mat(GOLD))
	_mesh(twin, "Floor star", _star_mesh(1.2, 0.5, 0.02), Transform3D(Basis(Vector3.RIGHT, -PI / 2), c + Vector3(0, 0.005, 0)), _mat(Color("c9a24a")))

## The endless hall under the house (see ENDLESS): a closed lilac corridor ROOM_H high with a
## starry ceiling, cut into two identical rooms by walls A, B and C (A and C close the ends from
## the inside; only their room sides are dressed). Each room has the same plaques, sconces, runner
## and ceiling stars, so the session can move the player back a room without a visible change.
func _endless_hall() -> void:
	var hall := _group(house, ENDLESS)
	hall.visible = false
	var f := ENDLESS_FLOOR
	var top := f + ROOM_H
	var z0: float = HALL_WALLS[0] - 0.6
	var z1: float = HALL_WALLS[2] + WALL + EXIT_DEPTH
	var mid := (z0 + z1) * 0.5
	var length := z1 - z0
	_box(hall, "Endless floor slab", Vector3(0, f - 0.25, mid), Vector3(2 * W2, 0.5, length), STONE_DARK)
	_box(hall, "Endless floor", Vector3(0, f + 0.012, mid), Vector3(2 * W2 - 2 * WALL, 0.024, length - 2 * WALL), ROOM_FLOOR, false, "floor")
	# The ceiling: the night sky, solid (infinite jumps stop there).
	var ceiling := _group(hall, "Endless ceiling")
	ceiling.position = Vector3(0, top + 0.15, mid)
	var sky := _box_mesh(Vector3(2 * W2, 0.3, length))
	_mesh(ceiling, "Endless sky", sky, Transform3D(), _sky(NAVY))
	_solid(ceiling, "Endless ceiling solid", sky)
	for side in [-1.0, 1.0]:
		_box(hall, "Endless side wall", Vector3(side * (W2 - WALL * 0.5), (f + top) * 0.5, mid), Vector3(WALL, ROOM_H, length), LILAC)
		_box(hall, "Endless cornice", Vector3(side * (W2 - WALL - 0.08), top - 0.2, mid), Vector3(0.16, 0.24, length - 2 * WALL), GOLD, false)
		_box(hall, "Endless skirting", Vector3(side * (W2 - WALL - 0.05), f + 0.12, mid), Vector3(0.1, 0.24, length - 2 * WALL), STONE, false)
	for end in [z0 + WALL * 0.5, z1 - WALL * 0.5]:
		_box(hall, "Endless end", Vector3(0, (f + top) * 0.5, end), Vector3(2 * W2, ROOM_H, WALL), INDIGO)
	for i in HALL_WALLS.size():
		var wall := _group(hall, HALL_WALL_NAMES[i])
		var z: float = HALL_WALLS[i]
		_door_wall(wall, z, f, i < HALL_WALLS.size() - 1)
		if i > 0:
			_door_wall_decor(wall, z, f)
	for k in HALL_WALLS.size() - 1:
		_endless_room(hall, "Endless room %d" % (k + 1), float(HALL_WALLS[k]) + WALL, float(HALL_WALLS[k + 1]), f)
	_exit_alcove(hall, float(HALL_WALLS[2]) + WALL, z1 - WALL, f)
	_treasure(hall, Vector3(0, f, TREASURE_Z))

## The dark doorway behind wall C (seen only through its open exit door): indigo linings, a
## low starry ceiling and a glowing pad behind each door.
func _exit_alcove(hall: Node3D, z0: float, z1: float, f: float) -> void:
	var alcove := _group(hall, "Exit alcove")
	var depth := z1 - z0
	var mid := (z0 + z1) * 0.5
	_box(alcove, "Exit alcove floor", Vector3(0, f + 0.014, mid), Vector3(2 * W2 - 2 * WALL, 0.028, depth), Color("241b4d"), false)
	for side in [-1.0, 1.0]:
		_box(alcove, "Exit alcove lining", Vector3(side * (W2 - WALL - 0.03), f + ROOM_H * 0.5, mid), Vector3(0.06, ROOM_H, depth), INDIGO, false)
	_box(alcove, "Exit alcove end", Vector3(0, f + ROOM_H * 0.5, z1 - 0.03), Vector3(2 * W2 - 2 * WALL, ROOM_H, 0.06), INDIGO, false)
	_mesh(alcove, "Exit alcove ceiling", _box_mesh(Vector3(2 * W2 - 2 * WALL, 0.2, depth)), Transform3D(Basis(), Vector3(0, f + DOOR_H + 0.4, mid)), _sky(NAVY))
	var star := _star_mesh(0.14, 0.06, 0.02)
	for x in DOOR_X:
		_mesh(alcove, "Exit glow", _disc(1.0, 0.03, 32), Transform3D(Basis(), Vector3(x, f + 0.03, mid)), _glow(Color("b48cff"), 1.2))
		for k in 7:
			var p := Vector3(x + (k - 3) * 0.33, f + DOOR_H + 0.28, mid + (0.5 if k % 2 == 0 else -0.4))
			_mesh(alcove, "Exit star", star, Transform3D(Basis(Vector3.RIGHT, PI / 2), p), _sky(Color("fff1b8")))

## The treasure chest in the middle of the second room, facing the door the player comes in by
## (local -z), its lid hinged at the back ("Lid", opens by turning +x), Luna's diamond inside.
## The chest root is an interactable (treasure_chest.gd adds it at load).
## Hidden, and its collision switched off by the session, except after the last door.
func _treasure(hall: Node3D, at: Vector3) -> void:
	var treasure := _group(hall, TREASURE)
	treasure.position = at
	treasure.visible = false
	var chest := _group(treasure, "Chest")
	chest.set_script(preload("res://scripts/world/treasure_chest.gd"))
	var wood := Color("8a4f2a")
	var w := 1.8
	var d := 1.1
	var h := 0.95
	_box(chest, "Chest body", Vector3(0, h * 0.5, 0), Vector3(w, h, d), wood, true)
	_box(chest, "Chest inside", Vector3(0, h - 0.04, 0), Vector3(w - 0.16, 0.02, d - 0.16), Color("2a1630"), false)
	for x in [-w * 0.5 + 0.18, w * 0.5 - 0.18]:
		_box(chest, "Chest band", Vector3(x, h * 0.5, 0), Vector3(0.12, h + 0.02, d + 0.04), GOLD, false)
	_box(chest, "Chest rim", Vector3(0, h - 0.06, 0), Vector3(w + 0.04, 0.1, d + 0.04), GOLD, false)
	_box(chest, "Chest foot band", Vector3(0, 0.06, 0), Vector3(w + 0.04, 0.12, d + 0.04), GOLD, false)
	var lid := _group(chest, "Lid")
	lid.position = Vector3(0, h, d * 0.5)
	_box(lid, "Lid base", Vector3(0, 0.1, -d * 0.5), Vector3(w + 0.02, 0.2, d + 0.02), wood, false)
	var dome := _half_disc(d * 0.5 + 0.01, w + 0.02, 24)
	_mesh(lid, "Lid dome", dome, Transform3D(Basis(Vector3.UP, PI / 2), Vector3(0, 0.2, -d * 0.5)), _mat(wood))
	for x in [-w * 0.5 + 0.18, w * 0.5 - 0.18]:
		_mesh(lid, "Lid band", _arc_tube(Vector3(x, 0.2, -d * 0.5), Vector3.BACK, Vector3.UP, d * 0.5 + 0.03, 0.0, PI, 0.05, 16), Transform3D(), _mat(GOLD))
	_box(lid, "Lock plate", Vector3(0, 0.05, -d - 0.02), Vector3(0.3, 0.34, 0.06), GOLD, false)
	_mesh(lid, "Lock gem", _disc(0.07, 0.03, 4, true), Transform3D(Basis(), Vector3(0, 0.05, -d - 0.06)), _mat(RUG))
	# The diamond, inside the closed lid (shown when it opens).
	var diamond := _group(chest, "Diamond")
	diamond.position = Vector3(0, h + 0.1, 0)
	var crown := CylinderMesh.new()
	crown.top_radius = 0.13
	crown.bottom_radius = 0.24
	crown.height = 0.1
	crown.radial_segments = 8
	crown.rings = 1
	var pavilion := CylinderMesh.new()
	pavilion.top_radius = 0.24
	pavilion.bottom_radius = 0.0
	pavilion.height = 0.28
	pavilion.radial_segments = 8
	pavilion.rings = 1
	var gem := _glow(Color("9fe9ff"), 1.4)
	_mesh(diamond, "Diamond crown", crown, Transform3D(Basis(), Vector3(0, 0.33, 0)), gem)
	_mesh(diamond, "Diamond pavilion", pavilion, Transform3D(Basis(), Vector3(0, 0.14, 0)), gem)

## One room of the endless hall from z0 (the far face of the wall behind) to z1 (the next door
## wall); both rooms are built the same way (the same random seed).
func _endless_room(hall: Node3D, title: String, z0: float, z1: float, f: float) -> void:
	var room := _group(hall, title)
	# A purple runner with gold edges from the door behind to the rug before the next doors.
	var r0 := z0 + 0.6
	var r1 := z1 - 3.8
	_box(room, "Runner", Vector3(0, f + 0.03, (r0 + r1) * 0.5), Vector3(2.2, 0.02, r1 - r0), CARPET, false, "carpet")
	for side in [-1.0, 1.0]:
		_box(room, "Runner edge", Vector3(side * 1.05, f + 0.045, (r0 + r1) * 0.5), Vector3(0.08, 0.012, r1 - r0), GOLD, false)
	# Two zodiac plaques and a sconce on each side wall, the same in every room.
	for i in 4:
		var side := -1.0 if i < 2 else 1.0
		var z := lerpf(z0, z1, 0.3 if i % 2 == 0 else 0.62)
		_constellation(room, ZODIAC[[0, 4, 8, 10][i]], Vector3(side * (W2 - WALL - 0.1), f + 5.2, z), Vector3(-side, 0, 0))
	for side in [-1.0, 1.0]:
		_lantern(room, "Hall sconce", Vector3(side * (W2 - WALL - 0.36), f + 3.0, lerpf(z0, z1, 0.46)), Vector3(-side, 0, 0))
	# Stars on the ceiling.
	var rng := RandomNumberGenerator.new()
	rng.seed = 2611
	var star := _star_mesh(0.16, 0.07, 0.02)
	for k in 30:
		var p := Vector3(rng.randf_range(-W2 + 1.0, W2 - 1.0), f + ROOM_H - 0.02, rng.randf_range(z0 + 0.6, z1 - 0.6))
		_mesh(room, "Ceiling star", star, Transform3D(Basis(Vector3.RIGHT, PI / 2).scaled(Vector3.ONE * rng.randf_range(0.6, 1.4)), p), _sky(Color("fff1b8")))

## A garland of leaves and pink flowers from `a` to `b`, sagging `sag` in the middle, a few
## sprigs hanging below.
func _garland(parent: Node3D, rng: RandomNumberGenerator, a: Vector3, b: Vector3, sag: float, toward := -1.0) -> void:
	var garland := _group(parent, "Flower garland")
	var leaf := SphereMesh.new()
	leaf.radius = 0.2
	leaf.height = 0.16
	var bloom := SphereMesh.new()
	bloom.radius = 0.11
	bloom.height = 0.1
	var count := int(a.distance_to(b) / 0.26)
	for i in count + 1:
		var t := float(i) / count
		var p := a.lerp(b, t) - Vector3(0, sag * 4.0 * t * (1.0 - t), 0)
		_mesh(garland, "Garland leaves", leaf, Transform3D(Basis(), p + Vector3(0, rng.randf_range(-0.06, 0.06), 0)), _mat(LEAF_GREEN))
		if rng.randf() < 0.45:
			_mesh(garland, "Garland flower", bloom, Transform3D(Basis(), p + Vector3(rng.randf_range(-0.12, 0.12), rng.randf_range(-0.1, 0.1), 0.12 * toward)), _mat(FLOWER_PINK))
		if rng.randf() < 0.12:
			for d in 3:
				_mesh(garland, "Garland sprig", leaf, Transform3D(Basis(), p - Vector3(0, 0.22 * (d + 1), 0)), _mat(LEAF_GREEN))

## A faint dark line on a door leaf (its planks), the same on every door colour.
func _groove() -> StandardMaterial3D:
	if not _materials.has("groove"):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0, 0, 0, 0.22)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 0.9
		_materials["groove"] = m
	return _materials["groove"]

## A flat shape facing +Z, `size` its half-extent: circle, square, triangle (point up), star.
func _shape_mesh(shape: String, size: float, depth: float) -> Mesh:
	match shape:
		"circle":
			return _disc(size, depth, 40, true)
		"square":
			return _box_mesh(Vector3(size * 1.8, size * 1.8, depth))
		"triangle":
			# An explicit prism: CylinderMesh keeps at least 4 sides, so a 3-sided one is a
			# diamond (render review, 9 Nov 2026). One corner up, centred, so the layers nest evenly.
			var corners: Array = []
			for k in 3:
				var a := PI / 2 + TAU * k / 3.0
				corners.append(Vector2(cos(a), sin(a)) * size * 1.15)
			return _prism(corners, depth)
		_:
			return _star_mesh(size * 1.15, size * 0.48, depth)

# --- The hall -------------------------------------------------------------------------------

func _hall_interior() -> void:
	var hall := _group(house, "Hall")
	# A purple runner with gold edges from the entrance to the arch.
	var length := HALL_REAR - FRONT - WALL * 1.5
	_box(hall, "Runner", Vector3(0, FLOOR + 0.03, (FRONT + HALL_REAR) * 0.5), Vector3(2.2, 0.02, length), CARPET, false, "rug")
	for side in [-1.0, 1.0]:
		_box(hall, "Runner edge", Vector3(side * 1.12, FLOOR + 0.035, (FRONT + HALL_REAR) * 0.5), Vector3(0.08, 0.02, length), GOLD, false)
	# The teaching posters: shapes on the left wall (seen entering), colours on the right.
	_poster(hall, "Shapes poster", Vector3(W2 - WALL - 0.03, FLOOR + 2.6, -10.0), Vector3(-1, 0, 0), "mystery.poster_shapes", SHAPES, true)
	_poster(hall, "Colors poster", Vector3(-W2 + WALL + 0.03, FLOOR + 2.6, -10.0), Vector3(1, 0, 0), "mystery.poster_colors", ["red", "blue", "green", "yellow", "purple", "orange", "pink"], false)
	# Potted plants in the corners by the arch, and wall sconces.
	for side in [-1.0, 1.0]:
		_planter(hall, "Hall planter", Vector3(side * 9.8, FLOOR, -6.2), 0.45, FLOWER_PINK)
		_lantern(hall, "Hall sconce", Vector3(side * 3.2, FLOOR + 3.2, HALL_REAR - WALL * 0.5 - 0.36), Vector3(0, 0, -1))
	var lamp := OmniLight3D.new()
	lamp.name = "Hall light"
	lamp.light_color = Color("ffe2b0")
	lamp.light_energy = 0.8
	lamp.omni_range = 11.0
	hall.add_child(lamp)
	lamp.position = Vector3(0, FLOOR + 4.6, -10.0)

## A teaching poster: a title (phrase, follows the Display Mode) and one card per word, each its
## own word root (pick area) with a picture (a shape, or a colour swatch) and its word label.
func _poster(parent: Node3D, title: String, at: Vector3, facing: Vector3, phrase: String, words: Array, shapes: bool) -> void:
	var LiveLabels = preload("res://scripts/language/live_labels.gd")
	var poster := _group(parent, title)
	poster.transform = Transform3D(_front(facing), at)
	poster.set_meta("learning_object", true)
	var w := 6.2
	var h := 3.4
	_box(poster, "Poster board", Vector3(0, 0, -0.03), Vector3(w, h, 0.06), Color("2a2160"), false)
	_box(poster, "Poster frame", Vector3(0, 0, -0.05), Vector3(w + 0.22, h + 0.22, 0.04), GOLD, false)
	var heading := _label(poster, "Poster title", 64, Color("ffe7a3"))
	heading.position = Vector3(0, h * 0.5 - 0.38, 0.02)
	LiveLabels.bind(heading, {"phrase": phrase}, w - 0.6)
	var per_row := 4
	var rows := ceili(float(words.size()) / per_row)
	for i in words.size():
		var key: String = words[i]
		var row := i / per_row
		var in_row: int = mini(per_row, words.size() - row * per_row)
		var col := i % per_row
		var cx := (col - (in_row - 1) * 0.5) * 1.42
		var cy := 0.45 - row * (1.25 if rows > 1 else 0.0) - (0.25 if rows == 1 else 0.0)
		var card: Node3D = game.box("Poster " + key, Vector3.ZERO, Vector3(1.24, 1.12, 0.03), Color("f6efe1"), key, false)
		card.reparent(poster, false)
		card.position = Vector3(cx, cy - 0.12, 0.0)
		card.set_meta("learning_object", true)
		if shapes:
			_mesh(card, "Picture", _shape_mesh(key, 0.27, 0.02), Transform3D(Basis(), Vector3(0, 0.14, 0.03)), _mat(Color("7a4bc8")))
		else:
			_mesh(card, "Swatch", _disc(0.27, 0.02, 32, true), Transform3D(Basis(), Vector3(0, 0.14, 0.03)), _mat(COLORS[key]))
		var label := _label(card, "Word", 40, Color("2a2160"))
		label.position = Vector3(0, -0.36, 0.03)
		LiveLabels.bind(label, {"word": key, "form": "label"}, 1.1)

# --- Entrance and front ---------------------------------------------------------------------

func _entrance() -> void:
	var front := _group(house, "Entrance")
	var z := FRONT - 0.3
	# The raised portal round the door, crowned by a half-oval gable with a gold edge.
	var portal_top := FLOOR + 7.4
	for side in [-1.0, 1.0]:
		_box(front, "Portal pier", Vector3(side * (ENTRY.x * 0.5 + 1.2), (FLOOR + portal_top) * 0.5, z), Vector3(2.4, portal_top - FLOOR, 0.6), CREAM)
		_box(front, "Portal pilaster", Vector3(side * (ENTRY.x * 0.5 + 2.3), (FLOOR + portal_top) * 0.5, z - 0.32), Vector3(0.36, portal_top - FLOOR, 0.1), STONE, false)
	_box(front, "Portal head", Vector3(0, (FLOOR + ENTRY.y + portal_top) * 0.5, z), Vector3(ENTRY.x, portal_top - FLOOR - ENTRY.y, 0.6), CREAM)
	_mesh(front, "Portal gable", _half_disc(4.0, 0.6), Transform3D(Basis().scaled(Vector3(1, 0.45, 1)), Vector3(0, portal_top, z)), _mat(CREAM))
	_mesh(front, "Portal gable edge", _half_disc(4.25, 0.4), Transform3D(Basis().scaled(Vector3(1, 0.5, 1)), Vector3(0, portal_top - 0.02, z + 0.12)), _mat(GOLD))
	_box(front, "Portal cornice", Vector3(0, portal_top, z - 0.05), Vector3(8.4, 0.3, 0.72), GOLD, false)
	# The teal emblem with a gold star, high on the portal.
	var emblem := _group(front, "Portal emblem")
	emblem.transform = Transform3D(_front(Vector3(0, 0, -1)), Vector3(0, FLOOR + 8.35, z - 0.5))
	_box(emblem, "Emblem shield", Vector3(0, 0, 0), Vector3(1.2, 1.3, 0.08), TEAL, false)
	_mesh(emblem, "Emblem point", _disc(0.6, 0.08, 4, true), Transform3D(Basis(Vector3.BACK, PI / 4), Vector3(0, -0.65, 0)), _mat(TEAL))
	_mesh(emblem, "Emblem star", _star_mesh(0.42, 0.17, 0.05), Transform3D(Basis(), Vector3(0, 0, 0.06)), _mat(GOLD))
	# Arched transom over the door: a purple half-disc with a gold star inside a gold arch.
	var door_front := Vector3(0, 0, -1)
	var transom := _group(front, "Transom")
	transom.transform = Transform3D(_front(door_front), Vector3(0, FLOOR + ENTRY.y, z - 0.31))
	_mesh(transom, "Transom", _half_disc(ENTRY.x * 0.5, 0.04), Transform3D(), _mat(Color("6a3ab8")))
	_mesh(transom, "Transom star", _star_mesh(0.45, 0.19, 0.04), Transform3D(Basis(), Vector3(0, 0.62, 0.03)), _glow(Color("ffe08a"), 0.9))
	_mesh(transom, "Transom arch", _arc_tube(Vector3(0, 0, 0.04), Vector3.RIGHT, Vector3.UP, ENTRY.x * 0.5 + 0.12, 0.0, PI, 0.11, 22), Transform3D(), _mat(GOLD))
	for side in [-1.0, 1.0]:
		_box(front, "Door jamb", Vector3(side * (ENTRY.x * 0.5 + 0.06), FLOOR + ENTRY.y * 0.5, z - 0.32), Vector3(0.16, ENTRY.y, 0.1), GOLD, false)
	# Purple double doors with gold stars, standing open into the hall.
	for side in [-1.0, 1.0]:
		var hinge := _group(front, "Entrance door hinge")
		hinge.position = Vector3(side * ENTRY.x * 0.5, FLOOR, FRONT + WALL + 0.06)
		hinge.rotation.y = side * deg_to_rad(80)
		var leaf: Node3D = game.box("Entrance door", Vector3.ZERO, Vector3(ENTRY.x * 0.5 - 0.05, ENTRY.y - 0.05, 0.1), Color("7440c4"), "door", true)
		leaf.reparent(hinge, false)
		leaf.position = Vector3(-side * (ENTRY.x * 0.25), ENTRY.y * 0.5, 0)
		for face in [-1.0, 1.0]:
			_mesh(leaf, "Door star", _star_mesh(0.3, 0.13, 0.03), Transform3D(Basis(Vector3.UP, 0.0 if face > 0 else PI), Vector3(0, 0.4, face * 0.06)), _mat(GOLD))
			_mesh(leaf, "Door panel line", _box_mesh(Vector3(0.05, ENTRY.y - 0.6, 0.02)), Transform3D(Basis(), Vector3(side * (ENTRY.x * 0.25 - 0.18), 0, face * 0.06)), _mat(GOLD))
	# Steps (visual) on a ramp collider, with a purple carpet down their middle.
	var step_w := ENTRY.x + 2.2
	for k in 3:
		var top := FLOOR - 0.2 * k
		var zz := FRONT - 0.6 - 0.65 * k
		_box(front, "Step", Vector3(0, (top - 0.3) * 0.5, zz - 0.325), Vector3(step_w, top + 0.3, 0.65), STONE, false)
		_box(front, "Step carpet", Vector3(0, top + 0.012, zz - 0.325), Vector3(2.2, 0.024, 0.66), CARPET, false)
		_box(front, "Step carpet edge", Vector3(0, top + 0.016, zz - 0.65 + 0.03), Vector3(2.3, 0.03, 0.06), GOLD, false)
	var run := 0.65 * 3 + 0.6
	var ramp := StaticBody3D.new()
	ramp.name = "Step ramp"
	var shape := CollisionShape3D.new()
	var ramp_box := BoxShape3D.new()
	var slope := atan2(FLOOR, run)
	ramp_box.size = Vector3(step_w, 0.1, sqrt(run * run + FLOOR * FLOOR))
	shape.shape = ramp_box
	ramp.add_child(shape)
	front.add_child(ramp)
	ramp.transform = Transform3D(Basis(Vector3.RIGHT, -slope), Vector3(0, FLOOR * 0.5 - 0.05, FRONT - run * 0.5))
	# Lanterns either side of the door.
	for side in [-1.0, 1.0]:
		_lantern(front, "Entrance lantern", Vector3(side * (ENTRY.x * 0.5 + 0.8), FLOOR + 3.3, z - 0.62), door_front)

## A wall lantern (render review, 9 Nov 2026: larger and brighter than the first version, which
## read as a small dark box from the path).
func _lantern(parent: Node3D, title: String, at: Vector3, facing: Vector3) -> void:
	var lantern := _group(parent, title)
	lantern.transform = Transform3D(_front(facing), at)
	_box(lantern, "Bracket", Vector3(0, 0.62, -0.25), Vector3(0.1, 0.1, 0.5), BRONZE, false)
	var roof := CylinderMesh.new()
	roof.top_radius = 0.04
	roof.bottom_radius = 0.42
	roof.height = 0.3
	roof.radial_segments = 4
	_mesh(lantern, "Lantern cap", roof, Transform3D(Basis(Vector3.UP, PI / 4), Vector3(0, 0.55, 0)), _mat(BRONZE))
	_mesh(lantern, "Lantern glass", _box_mesh(Vector3(0.48, 0.72, 0.48)), Transform3D(Basis(), Vector3(0, 0.04, 0)), _glow(Color("ffb547"), 1.0))
	for corner in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
		_box(lantern, "Lantern frame", Vector3(corner.x * 0.25, 0.04, corner.y * 0.25), Vector3(0.05, 0.76, 0.05), BRONZE, false)
	_box(lantern, "Lantern base", Vector3(0, -0.36, 0), Vector3(0.56, 0.1, 0.56), BRONZE, false)

# --- Garden ---------------------------------------------------------------------------------

func _garden() -> void:
	var garden := _group(house, "Garden")
	# Urns with pink flowers either side of the steps.
	for side in [-1.0, 1.0]:
		_planter(garden, "Entrance urn", Vector3(side * 3.6, 0.0, FRONT - 1.0), 0.6, FLOWER_PINK)
	# Flower beds along the front wall and the sides, below the windows.
	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	for side in [-1.0, 1.0]:
		_bed(garden, rng, Vector3(side * 8.0, 0, FRONT - 1.1), Vector2(6.6, 1.0))
		_bed(garden, rng, Vector3(side * (W2 + 1.0), 0, -10.0), Vector2(1.0, 6.0))
		_bed(garden, rng, Vector3(side * (W2 + 1.0), 0, 4.0), Vector2(1.0, 12.0))
	# Flowering vines up the front corners and either side of the portal.
	for x in [-11.6, -4.9, 4.9, 11.6]:
		_vine(garden, rng, Vector3(x, FLOOR, FRONT - 0.08), 4.6)
	# A paved path from the sidewalk to the steps, and the name sign beside it.
	var path_from := FRONT - 0.65 * 3 - 0.6
	var path_to := 110.4 - ORIGIN.x
	_box(garden, "Front path", Vector3(0, 0.05, (path_from + path_to) * 0.5), Vector3(3.6, 0.1, path_from - path_to), Color("d8cdb6"), false, "path")
	var sign := _group(garden, "Name sign")
	sign.transform = Transform3D(_front(Vector3(0, 0, -1)), Vector3(4.2, 0, path_to + 1.6))
	_box(sign, "Sign post", Vector3(0, 1.2, 0), Vector3(0.2, 2.4, 0.2), BRONZE)
	# Wide enough for "CASA DE LAS ESTRELLAS" (sign_translations.json; render review 9 Nov 2026).
	_box(sign, "Sign board", Vector3(0, 2.15, 0.12), Vector3(3.9, 1.0, 0.1), Color("5b2fa3"), false, "sign")
	_box(sign, "Sign frame", Vector3(0, 2.15, 0.1), Vector3(4.05, 1.15, 0.06), GOLD, false)
	var label := _label(sign, "Sign text", 48, Color("ffe7a3"))
	label.text = "MYSTERY HOUSE"
	label.position = Vector3(0, 2.25, 0.18)
	label.double_sided = true
	_mesh(sign, "Sign star", _star_mesh(0.16, 0.07, 0.03), Transform3D(Basis(), Vector3(0, 1.88, 0.18)), _mat(GOLD))

func _planter(parent: Node3D, title: String, at: Vector3, size: float, flower: Color) -> void:
	var urn := CylinderMesh.new()
	urn.top_radius = size
	urn.bottom_radius = size * 0.62
	urn.height = size * 1.4
	var pot: Node3D = _cyl(parent, title, at + Vector3(0, size * 0.7, 0), size, size * 1.4, CREAM, "", true)
	(pot.get_child(0) as MeshInstance3D).mesh = urn
	var bush := SphereMesh.new()
	bush.radius = size * 0.9
	bush.height = size * 1.2
	_mesh(pot, "Leaves", bush, Transform3D(Basis(), Vector3(0, size * 0.85, 0)), _mat(LEAF_GREEN))
	var bloom := SphereMesh.new()
	bloom.radius = size * 0.2
	bloom.height = size * 0.3
	for i in 8:
		var a := TAU * i / 8.0
		var r := size * (0.55 if i % 2 == 0 else 0.3)
		_mesh(pot, "Flower", bloom, Transform3D(Basis(), Vector3(cos(a) * r, size * (1.2 if i % 2 == 0 else 1.35), sin(a) * r)), _mat(flower))

func _bed(parent: Node3D, rng: RandomNumberGenerator, at: Vector3, size: Vector2) -> void:
	var bed := _group(parent, "Flower bed")
	bed.position = at
	_box(bed, "Bed edging", Vector3(0, 0.12, 0), Vector3(size.x + 0.2, 0.24, size.y + 0.2), STONE, false)
	_box(bed, "Bed soil", Vector3(0, 0.25, 0), Vector3(size.x, 0.04, size.y), SOIL, false)
	var bush := SphereMesh.new()
	bush.radius = 0.38
	bush.height = 0.5
	var bloom := SphereMesh.new()
	bloom.radius = 0.12
	bloom.height = 0.16
	var count := int(size.x * size.y * 1.6)
	for i in count:
		var p := Vector3(rng.randf_range(-size.x, size.x) * 0.42, 0.42, rng.randf_range(-size.y, size.y) * 0.42)
		_mesh(bed, "Bush", bush, Transform3D(Basis(), p), _mat(LEAF_GREEN))
		_mesh(bed, "Flower", bloom, Transform3D(Basis(), p + Vector3(rng.randf_range(-0.2, 0.2), 0.26, rng.randf_range(-0.2, 0.2))), _mat(FLOWER_PINK if rng.randf() < 0.65 else FLOWER_YELLOW))

func _vine(parent: Node3D, rng: RandomNumberGenerator, at: Vector3, height: float) -> void:
	var vine := _group(parent, "Flowering vine")
	vine.position = at
	var leaf := SphereMesh.new()
	leaf.radius = 0.22
	leaf.height = 0.18
	var bloom := SphereMesh.new()
	bloom.radius = 0.13
	bloom.height = 0.12
	var y := 0.0
	while y < height:
		var x := sin(y * 1.7) * 0.25
		_mesh(vine, "Vine leaves", leaf, Transform3D(Basis(), Vector3(x, y, -0.08)), _mat(LEAF_GREEN))
		if rng.randf() < 0.55:
			_mesh(vine, "Vine flower", bloom, Transform3D(Basis(), Vector3(x + rng.randf_range(-0.25, 0.25), y + 0.1, -0.16)), _mat(FLOWER_PINK))
		y += 0.32

# --- Madame Luna ----------------------------------------------------------------------------

func _luna() -> void:
	var room := house.get_node("MysteryRoom") as Node3D
	var characters = preload("res://scripts/characters/house_characters.gd").new()
	var look := house.global_basis * LUNA_LOOK.normalized()
	characters.worker("res://scenes/characters/cat_plush.tscn", "fortune_teller", "cat", room, LUNA, house.to_global(LUNA_SPOT), look)

# --- Helpers --------------------------------------------------------------------------------

func _group(parent: Node3D, title: String) -> Node3D:
	var node := Node3D.new()
	node.name = title
	parent.add_child(node, true)
	return node

## Main's box (mesh, collision when solid, a pick area with a word) under `parent`.
func _box(parent: Node3D, title: String, pos: Vector3, size: Vector3, color: Color, solid := true, word := "") -> Node3D:
	var part: Node3D = game.box(title, Vector3.ZERO, size, color, word, solid)
	part.reparent(parent, false)
	part.position = pos
	return part

func _cyl(parent: Node3D, title: String, pos: Vector3, radius: float, height: float, color: Color, word := "", solid := false) -> Node3D:
	var part: Node3D = game.cylinder(title, Vector3.ZERO, radius, height, color, word, solid)
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

## A static body with the exact shape of `mesh` (decorative roofs that should be walkable).
func _solid(parent: Node3D, title: String, mesh: Mesh) -> void:
	var body := StaticBody3D.new()
	body.name = title
	var shape := CollisionShape3D.new()
	shape.shape = mesh.create_trimesh_shape()
	body.add_child(shape)
	parent.add_child(body, true)

func _label(parent: Node3D, title: String, font_size: int, color: Color) -> Label3D:
	var label := Label3D.new()
	label.name = title
	label.font_size = font_size
	label.pixel_size = 0.006
	label.modulate = color
	label.outline_size = 0
	label.shaded = false
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label, true)
	return label

## A basis whose +Z faces `dir` (so +X is the right of someone looking at its front).
func _front(dir: Vector3) -> Basis:
	return Basis.looking_at(-dir.normalized(), Vector3.UP)

func _mat(color: Color) -> StandardMaterial3D:
	return game.material_for(color)

## A glowing material (stained glass, lanterns): lit colour plus emission.
func _glow(color: Color, energy: float) -> StandardMaterial3D:
	var key := "glow" + color.to_html() + str(energy)
	if not _materials.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = energy
		m.roughness = 0.5
		_materials[key] = m
	return _materials[key]

## The night sky and its stars: unshaded (the same at any hour), optionally seen from inside a
## closed mesh (the drum and dome show their inner faces).
func _sky(color: Color, inside := false) -> StandardMaterial3D:
	var key := "sky" + color.to_html() + str(inside)
	if not _materials.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.cull_mode = BaseMaterial3D.CULL_FRONT if inside else BaseMaterial3D.CULL_BACK
		_materials[key] = m
	return _materials[key]

func _box_mesh(size: Vector3) -> BoxMesh:
	return game.shared_box_mesh(size)

## A flat disc facing +Y (or +Z when `facing_z`), `segments` round (4 makes a diamond).
func _disc(radius: float, depth: float, segments: int, facing_z := false) -> Mesh:
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = depth
	disc.radial_segments = segments
	disc.rings = 1
	if facing_z:
		return _baked(disc, Transform3D(Basis(Vector3.RIGHT, PI / 2), Vector3.ZERO))
	return disc

## A half disc facing +Z: flat edge along x at y = 0, the round edge above.
func _half_disc(radius: float, depth: float, segments := 24) -> ArrayMesh:
	var f := depth * 0.5
	var pts := PackedVector3Array()
	for i in segments:
		var a := PI * i / segments
		var b := PI * (i + 1) / segments
		var p := Vector3(cos(a) * radius, sin(a) * radius, 0)
		var q := Vector3(cos(b) * radius, sin(b) * radius, 0)
		pts.append_array([Vector3(0, 0, f), p + Vector3(0, 0, f), q + Vector3(0, 0, f)])
		pts.append_array([Vector3(0, 0, -f), q - Vector3(0, 0, f), p - Vector3(0, 0, f)])
		pts.append_array([p + Vector3(0, 0, f), p - Vector3(0, 0, f), q - Vector3(0, 0, f)])
		pts.append_array([p + Vector3(0, 0, f), q - Vector3(0, 0, f), q + Vector3(0, 0, f)])
	pts.append_array([Vector3(-radius, 0, f), Vector3(-radius, 0, -f), Vector3(radius, 0, -f)])
	pts.append_array([Vector3(-radius, 0, f), Vector3(radius, 0, -f), Vector3(radius, 0, f)])
	return _tri_mesh(pts)

## A flat panel facing +Z over x -half_w..half_w, y 0..top, `depth` thick, with a half-round
## hole of `radius` at the origin: the wall above the round head of an arched door.
func _arch_panel(radius: float, half_w: float, top: float, depth: float) -> ArrayMesh:
	var rect := Rect2(-half_w, 0.0, 2.0 * half_w, top)
	var angles: Array = []
	for i in 33:
		angles.append(PI * i / 32.0)
	angles.append(atan2(top, half_w))
	angles.append(atan2(top, -half_w))
	angles.sort()
	var f := depth * 0.5
	var pts := PackedVector3Array()
	for i in angles.size() - 1:
		var a1: float = angles[i]
		var a2: float = angles[i + 1]
		if is_equal_approx(a1, a2):
			continue
		var d1 := Vector2(cos(a1), sin(a1))
		var d2 := Vector2(cos(a2), sin(a2))
		var p1 := d1 * radius
		var p2 := d2 * radius
		var q1 := d1 * _ray_to_rect(Vector2.ZERO, d1, rect)
		var q2 := d2 * _ray_to_rect(Vector2.ZERO, d2, rect)
		var fr := [Vector3(p1.x, p1.y, f), Vector3(q1.x, q1.y, f), Vector3(q2.x, q2.y, f), Vector3(p2.x, p2.y, f)]
		var bk := [Vector3(p1.x, p1.y, -f), Vector3(q1.x, q1.y, -f), Vector3(q2.x, q2.y, -f), Vector3(p2.x, p2.y, -f)]
		pts.append_array([fr[0], fr[1], fr[2], fr[0], fr[2], fr[3]])
		pts.append_array([bk[0], bk[2], bk[1], bk[0], bk[3], bk[2]])
		# The curved reveal, facing the hole's centre.
		pts.append_array([fr[0], fr[3], bk[3], fr[0], bk[3], bk[0]])
	return _tri_mesh(pts)

## A half ring facing +Z from `r0` to `r1`, `depth` thick, its ends on y = 0: an arch's stones.
func _half_ring(r0: float, r1: float, depth: float, segments := 24) -> ArrayMesh:
	var zf := Vector3(0, 0, depth * 0.5)
	var pts := PackedVector3Array()
	for i in segments:
		var d1 := Vector3(cos(PI * i / segments), sin(PI * i / segments), 0)
		var d2 := Vector3(cos(PI * (i + 1) / segments), sin(PI * (i + 1) / segments), 0)
		var i1 := d1 * r0
		var o1 := d1 * r1
		var i2 := d2 * r0
		var o2 := d2 * r1
		pts.append_array([i1 + zf, o1 + zf, o2 + zf, i1 + zf, o2 + zf, i2 + zf])
		pts.append_array([i1 - zf, o2 - zf, o1 - zf, i1 - zf, i2 - zf, o2 - zf])
		pts.append_array([o1 + zf, o1 - zf, o2 - zf, o1 + zf, o2 - zf, o2 + zf])
		pts.append_array([i1 + zf, i2 + zf, i2 - zf, i1 + zf, i2 - zf, i1 - zf])
	return _tri_mesh(pts)

## A hemisphere without its flat base (Godot's hemisphere SphereMesh closes its bottom).
func _open_dome(dome: SphereMesh) -> ArrayMesh:
	var arrays := dome.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var base := dome.get_aabb().position.y
	var kept := PackedInt32Array()
	for i in range(0, indices.size(), 3):
		var flat := true
		for k in 3:
			if verts[indices[i + k]].y > base + 0.001:
				flat = false
		if not flat:
			kept.append_array([indices[i], indices[i + 1], indices[i + 2]])
	arrays[Mesh.ARRAY_INDEX] = kept
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

## A flat prism facing +Z from a convex outline (points counter-clockwise seen from the front).
func _prism(outline: Array, depth: float) -> ArrayMesh:
	var f := depth * 0.5
	var pts := PackedVector3Array()
	var n := outline.size()
	for i in range(1, n - 1):
		var a: Vector2 = outline[0]
		var b: Vector2 = outline[i]
		var c: Vector2 = outline[i + 1]
		pts.append_array([Vector3(a.x, a.y, f), Vector3(b.x, b.y, f), Vector3(c.x, c.y, f)])
		pts.append_array([Vector3(a.x, a.y, -f), Vector3(c.x, c.y, -f), Vector3(b.x, b.y, -f)])
	for i in n:
		var a: Vector2 = outline[i]
		var b: Vector2 = outline[(i + 1) % n]
		pts.append_array([Vector3(a.x, a.y, f), Vector3(a.x, a.y, -f), Vector3(b.x, b.y, -f)])
		pts.append_array([Vector3(a.x, a.y, f), Vector3(b.x, b.y, -f), Vector3(b.x, b.y, f)])
	return _tri_mesh(pts)

## A primitive mesh's surface moved by `xform`, as an ArrayMesh.
func _baked(primitive: PrimitiveMesh, xform: Transform3D) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.create_from(primitive, 0)
	var arrays := tool.commit_to_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	for i in verts.size():
		verts[i] = xform * verts[i]
		normals[i] = (xform.basis * normals[i]).normalized()
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TANGENT] = null
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

## Triangles (each three points, front faces seen counter-clockwise from outside) to a mesh.
func _tri_mesh(points: PackedVector3Array) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0, points.size(), 3):
		# Godot's front faces wind clockwise: emit each triangle reversed.
		tool.add_vertex(points[i])
		tool.add_vertex(points[i + 2])
		tool.add_vertex(points[i + 1])
	tool.generate_normals()
	return tool.commit()

## A five-pointed star, flat, facing +Z, centred on the origin.
func _star_mesh(outer: float, inner: float, depth: float) -> ArrayMesh:
	var ring: Array = []
	for i in 10:
		var a := PI / 2 + TAU * i / 10.0
		var r := outer if i % 2 == 0 else inner
		ring.append(Vector2(cos(a), sin(a)) * r)
	var pts := PackedVector3Array()
	var f := depth * 0.5
	for i in 10:
		var a: Vector2 = ring[i]
		var b: Vector2 = ring[(i + 1) % 10]
		pts.append_array([Vector3(0, 0, f), Vector3(a.x, a.y, f), Vector3(b.x, b.y, f)])
		pts.append_array([Vector3(0, 0, -f), Vector3(b.x, b.y, -f), Vector3(a.x, a.y, -f)])
		pts.append_array([Vector3(a.x, a.y, f), Vector3(a.x, a.y, -f), Vector3(b.x, b.y, -f)])
		pts.append_array([Vector3(a.x, a.y, f), Vector3(b.x, b.y, -f), Vector3(b.x, b.y, f)])
	return _tri_mesh(pts)

## A roof from the `outer` eave rectangle (x, z) at y0 up to the `inner` rectangle at y1: a hip
## roof when `inner` has no depth. Purple, with collision.
func _roof_mesh(parent: Node3D, title: String, outer: Rect2, inner: Rect2, y0: float, y1: float) -> void:
	var o := [Vector3(outer.position.x, y0, outer.position.y), Vector3(outer.end.x, y0, outer.position.y), Vector3(outer.end.x, y0, outer.end.y), Vector3(outer.position.x, y0, outer.end.y)]
	var n := [Vector3(inner.position.x, y1, inner.position.y), Vector3(inner.end.x, y1, inner.position.y), Vector3(inner.end.x, y1, inner.end.y), Vector3(inner.position.x, y1, inner.end.y)]
	var pts := PackedVector3Array()
	for k in 4:
		var a: Vector3 = o[k]
		var b: Vector3 = o[(k + 1) % 4]
		var c: Vector3 = n[(k + 1) % 4]
		var d: Vector3 = n[k]
		pts.append_array([a, c, b, a, d, c])
	var mesh := _tri_mesh(pts)
	_mesh(parent, title, mesh, Transform3D(), _roof_material())
	_solid(parent, title + " body", mesh)
	# Tile courses: thin gold-free darker lines across each slope suggest the tiles.
	for k in range(1, 4):
		var t := k / 4.0
		var y := lerpf(y0, y1, t)
		var r := Rect2(outer.position.lerp(inner.position, t), outer.size.lerp(inner.size, t))
		var line := PackedVector3Array()
		var rr := [Vector3(r.position.x, y, r.position.y), Vector3(r.end.x, y, r.position.y), Vector3(r.end.x, y, r.end.y), Vector3(r.position.x, y, r.end.y)]
		for q in 4:
			var p0: Vector3 = rr[q]
			var p1: Vector3 = rr[(q + 1) % 4]
			var out := (Vector3((p0.x + p1.x) * 0.5, 0, (p0.z + p1.z) * 0.5) - Vector3(r.get_center().x, 0, r.get_center().y)).normalized() * 0.03
			_mesh(parent, "Tile course", _box_mesh(Vector3(maxf(p0.distance_to(p1), 0.01), 0.05, 0.08)), Transform3D(Basis(Vector3.UP, -atan2(p1.z - p0.z, p1.x - p0.x)), (p0 + p1) * 0.5 + out + Vector3(0, 0.03, 0)), _mat(ROOF_DARK))

func _roof_material() -> StandardMaterial3D:
	if not _materials.has("roof"):
		var m := StandardMaterial3D.new()
		m.albedo_color = ROOF
		m.roughness = 0.7
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_materials["roof"] = m
	return _materials["roof"]

## A flat slab face over `rect` (x, z) with a round hole of `radius` at `center`, at height y;
## facing up or down.
func _holed_slab(rect: Rect2, center: Vector2, radius: float, y: float, up: bool) -> ArrayMesh:
	var angles: Array = []
	for i in 64:
		angles.append(TAU * i / 64.0)
	for corner in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
		angles.append(fposmod(atan2(corner.y - center.y, corner.x - center.x), TAU))
	angles.sort()
	var pts := PackedVector3Array()
	for i in angles.size():
		var a1: float = angles[i]
		var a2: float = angles[(i + 1) % angles.size()]
		if is_equal_approx(a1, a2):
			continue
		var d1 := Vector2(cos(a1), sin(a1))
		var d2 := Vector2(cos(a2), sin(a2))
		var p1 := center + d1 * radius
		var p2 := center + d2 * radius
		var q1 := center + d1 * _ray_to_rect(center, d1, rect)
		var q2 := center + d2 * _ray_to_rect(center, d2, rect)
		var v := [Vector3(p1.x, y, p1.y), Vector3(q1.x, y, q1.y), Vector3(q2.x, y, q2.y), Vector3(p2.x, y, p2.y)]
		# Angles grow from +x toward +z: seen from above that is clockwise.
		if up:
			pts.append_array([v[0], v[2], v[1], v[0], v[3], v[2]])
		else:
			pts.append_array([v[0], v[1], v[2], v[0], v[2], v[3]])
	return _tri_mesh(pts)

func _ray_to_rect(c: Vector2, d: Vector2, rect: Rect2) -> float:
	var t := INF
	if d.x > 0.0001: t = minf(t, (rect.end.x - c.x) / d.x)
	if d.x < -0.0001: t = minf(t, (rect.position.x - c.x) / d.x)
	if d.y > 0.0001: t = minf(t, (rect.end.y - c.y) / d.y)
	if d.y < -0.0001: t = minf(t, (rect.position.y - c.y) / d.y)
	return t

## A round tube along an arc: centre + (u cos t + v sin t) * radius for t in a0..a1.
func _arc_tube(center: Vector3, u: Vector3, v: Vector3, radius: float, a0: float, a1: float, tube: float, segments: int) -> ArrayMesh:
	var sides := 6
	var rings: Array = []
	for s in segments + 1:
		var t := lerpf(a0, a1, float(s) / segments)
		var radial := (u * cos(t) + v * sin(t)).normalized()
		var tangent := (-u * sin(t) + v * cos(t)).normalized()
		var side := tangent.cross(radial).normalized()
		var p := center + radial * radius
		var ring: Array = []
		for k in sides:
			var phi := TAU * k / sides
			ring.append(p + (radial * cos(phi) + side * sin(phi)) * tube)
		rings.append(ring)
	var pts := PackedVector3Array()
	for s in segments:
		for k in sides:
			var a: Vector3 = rings[s][k]
			var b: Vector3 = rings[s][(k + 1) % sides]
			var c: Vector3 = rings[s + 1][(k + 1) % sides]
			var d: Vector3 = rings[s + 1][k]
			pts.append_array([a, b, c, a, c, d])
	return _tri_mesh(pts)

## Faces that shared a plane and flickered are set apart (10 Nov 2026,
## scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "mystery")

## Second pass: faces a first move brought into a new plane, and labels widened for translated
## text (10 Nov 2026, scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps_2(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "mystery", 2)

## Step (user, 10 Nov 2026: "a step blocks me at the open door, I have to jump in"): the steps'
## ramp collider ended 0.48 high where the plinth (FLOOR, 0.6) begins, a 12 cm lip the player
## could not walk over. The ramp now runs through the step nosings (0.2 rise per 0.65 run, from
## the ground at the foot of the lowest step) and ends just on the plinth top, so the walk from
## the path into the hall is smooth. Visible steps are unchanged.
func entry_ramp(town: Node3D, _game) -> void:
	var ramp := town.get_node(ROOT + "/Entrance/Step ramp") as StaticBody3D
	var shape := ramp.get_child(0) as CollisionShape3D
	var foot := FRONT - 0.6 - 0.65 * 3           # ground line at the lowest step's nose
	var slope := atan2(0.2, 0.65)
	var z0 := foot - 0.3                          # starts buried in the lawn
	var z1 := FRONT - 0.55                        # ends 5 cm onto the plinth top
	var along := (z1 - z0) / cos(slope)
	var box := BoxShape3D.new()
	box.size = Vector3((shape.shape as BoxShape3D).size.x, 0.1, along)
	shape.shape = box
	var mid_z := (z0 + z1) * 0.5
	var top_y := (mid_z - foot) * tan(slope)
	# Box centre sits half its thickness below the top surface, along the slope's normal.
	var normal := Vector3(0, cos(slope), -sin(slope))
	ramp.transform = Transform3D(Basis(Vector3.RIGHT, -slope), Vector3(0, top_y, mid_z) - normal * 0.05)

## The old hover-hint and click metas baked on this unit's nodes go (12 Nov 2026, interaction
## system; scripts/buildings/interaction_metas.gd): their objects have Interactables now.
func interaction_metas(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/interaction_metas.gd").strip(town, "mystery")
