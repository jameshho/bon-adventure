extends RefCounted
## Farm barn own script (docs/guides/MODULAR_TOWN.md, "Changing a building"); the barn is saved in
## scenes/town/barn.scn. Design (1 Nov 2026, docs/guides/TOWN_DESIGN_BRIEF.md farm barn record):
## gambrel roof, open X-braced double doors, a walkable hayloft reached by a climbable ladder;
## 12 x 9 foundation. Barn frame: town units (Apartment scale 1.3 applies), door on local -Z,
## walls centred on x +-6 and z +-4.5. The constants were moved here from the deleted startup
## pass barn_interior.gd (6 Nov 2026); docs/evidence/barn-20261101/verify.gd uses them.
const STEPS := ["coplanar_gaps", "coplanar_gaps_2", "glass_windows", "hen_house"]

const W2 := 6.0
const D2 := 4.5
const IN_X := 5.875
const IN_Z := 4.375
## Gambrel profile (x, y) on the right half: wall top at the outer face, knee, ridge.
const EAVE := 6.0
const KNEE := Vector2(4.3, 8.7)
const RIDGE := 10.5
## Plank floor top: above the farm lawn slab (LA GRANJA lawn, top 0.12) that runs under the barn.
const FLOOR := .16
const DOOR_W2 := 1.7
const DOOR_H := 4.0
## Hayloft over the rear band; the ladder rises through a notch in its front edge, standing at
## the notch's back and facing the door.
const LOFT := 3.0
const LOFT_Z := .6
const NOTCH_X := .7
const NOTCH_Z := 2.1
## Parts of the old 5-high shell that the remodel removed (the check confirms they stay gone).
const OLD_SHELL := ["WestWall", "EastWall", "RearWall", "FrontPier", "FrontPier2", "DoorHeader", "Roof"]

## Faces that shared a plane and flickered are set apart (10 Nov 2026,
## scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps(town: Node3D, _game) -> void:
    preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "barn")

## Second pass: faces a first move brought into a new plane, and labels widened for translated
## text (10 Nov 2026, scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps_2(town: Node3D, _game) -> void:
    preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "barn", 2)


## Window glass as the shared window component (12 Nov 2026, docs/guides/WINDOWS.md).
func glass_windows(town: Node3D, _game) -> void:
    preload("res://scripts/buildings/glass_windows.gd").migrate(town, "barn")


## Hen house and eggs (user, 24 Nov 2026; record: docs/guides/TOWN_DESIGN_BRIEF.md#hen-house-and-eggs--24-november-2026).
## A little red coop on legs in the paddock west of the barn (between its wall, x 72, and the west
## fence, x 90; south of the sheep), six hens around it, egg spots (four nest boxes on its north
## face, seven straw nests on the ground) and an egg crate on a table inside the barn door, west
## of the doorway. Everything goes under `Barn/Hen house`, whose frame is the town's (TOWN units,
## +X west, +Z north), with scripts/world/hen_house.gd, which lays and hands out the eggs at run
## time (nothing of that is baked).
const COOP := Vector3(79.0, 0.0, 76.6)
const COOP_W2 := 1.5
const COOP_D2 := .9
const COOP_FLOOR := .7
const COOP_EAVE := 1.9
const COOP_RIDGE := 2.55
const LAWN := .12
const COOP_RED := Color("a63a2e")
const COOP_CREAM := Color("efe2c2")
const COOP_SLATE := Color("59626b")
const COOP_WOOD := Color("9a6a3f")
const COOP_DARK := Color("3b2a20")
const STRAW := Color("e3c46a")
## Ground straw nests (town x, z): by the ramp's foot, west of the front, by the hay bale, behind
## the coop (two), its south-east corner by the barn and its west side.
const GROUND_NESTS := [Vector2(76.4, 78.0), Vector2(81.3, 78.6), Vector2(83.3, 79.1), Vector2(78.3, 74.6),
    Vector2(80.3, 74.4), Vector2(75.3, 75.4), Vector2(82.0, 75.6)]
const HEN_HOMES := [Vector3(76.0, 0, 79.4), Vector3(77.6, 0, 80.6), Vector3(79.4, 0, 79.8),
    Vector3(81.2, 0, 80.9), Vector3(82.6, 0, 77.6), Vector3(75.4, 0, 77.4)]
## The egg crate's table, inside the barn's front wall west of the doorway (town).
const CRATE_TABLE := Vector3(69.0, FLOOR, 83.7)

func hen_house(town: Node3D, game) -> void:
    var barn: Node3D = town.get_node("Barn")
    assert(barn.get_node_or_null("Hen house") == null, "hen_house: already built")
    var house := Node3D.new()
    house.name = "Hen house"
    house.set_script(preload("res://scripts/world/hen_house.gd"))
    barn.add_child(house)
    # Town coordinates inside: the barn part's own transform undone.
    house.transform = barn.transform.affine_inverse()
    var coop := _node(house, "Coop", COOP)
    var spots := _node(house, "Egg spots", Vector3.ZERO)
    # Legs, floor, walls.
    for sx in [-1, 1]:
        for sz in [-1, 1]:
            _part(game, coop, "Coop leg", Vector3(sx * (COOP_W2 - .1), (LAWN + COOP_FLOOR) * .5, sz * (COOP_D2 - .1)), Vector3(.14, COOP_FLOOR - LAWN, .14), COOP_WOOD, true)
    _part(game, coop, "Coop floor", Vector3(0, COOP_FLOOR - .05, 0), Vector3(COOP_W2 * 2, .1, COOP_D2 * 2), COOP_WOOD, true)
    var wall_h := COOP_EAVE - COOP_FLOOR
    var wall_y := COOP_FLOOR + wall_h * .5
    _part(game, coop, "Coop back wall", Vector3(0, wall_y, -COOP_D2 + .04), Vector3(COOP_W2 * 2, wall_h, .08), COOP_RED, true)
    _part(game, coop, "Coop front wall", Vector3(0, wall_y, COOP_D2 - .04), Vector3(COOP_W2 * 2, wall_h, .08), COOP_RED, true)
    for sx in [-1, 1]:
        _part(game, coop, "Coop side wall", Vector3(sx * (COOP_W2 - .04), wall_y, 0), Vector3(.08, wall_h, COOP_D2 * 2 - .16), COOP_RED, true)
        for sz in [-1, 1]:
            _part(game, coop, "Coop corner board", Vector3(sx * (COOP_W2 - .02), wall_y, sz * (COOP_D2 - .02)), Vector3(.12, wall_h + .02, .12), COOP_CREAM)
        # Gable end: a triangle under the roof.
        var gable := MeshInstance3D.new()
        gable.name = "Coop gable"
        var prism := PrismMesh.new()
        prism.size = Vector3(COOP_D2 * 2, COOP_RIDGE - COOP_EAVE, .08)
        gable.mesh = prism
        gable.material_override = game.material_for(COOP_RED)
        coop.add_child(gable, true)
        gable.transform = Transform3D(Basis(Vector3.UP, PI / 2), Vector3(sx * (COOP_W2 - .04), COOP_EAVE + (COOP_RIDGE - COOP_EAVE) * .5, 0))
    # Roof: two slate slabs from the ridge down over the wall tops, 0.25 beyond them, along X.
    var rise := COOP_RIDGE - COOP_EAVE
    var tilt := atan2(rise, COOP_D2)
    var run := COOP_D2 + .25
    var slab := run / cos(tilt)
    for sz in [-1, 1]:
        var roof := _part(game, coop, "Coop roof", Vector3(0, COOP_RIDGE - run * tan(tilt) * .5 + .05, sz * run * .5), Vector3(COOP_W2 * 2 + .4, .08, slab + .06), COOP_SLATE, true)
        roof.basis = Basis(Vector3.RIGHT, sz * tilt)
    _part(game, coop, "Coop ridge cap", Vector3(0, COOP_RIDGE + .06, 0), Vector3(COOP_W2 * 2 + .44, .08, .16), COOP_CREAM)
    # Pop door and ramp on the east side (-X), down toward the barn.
    _part(game, coop, "Coop pop door", Vector3(-COOP_W2 - .005, COOP_FLOOR + .25, 0), Vector3(.02, .45, .38), COOP_DARK)
    _part(game, coop, "Coop pop door frame", Vector3(-COOP_W2 - .01, COOP_FLOOR + .5, 0), Vector3(.03, .06, .5), COOP_CREAM)
    var foot := 1.45
    var drop := COOP_FLOOR - LAWN
    var ramp := _part(game, coop, "Coop ramp", Vector3(-COOP_W2 - foot * .5, LAWN + drop * .5 + .02, 0), Vector3(sqrt(foot * foot + drop * drop), .05, .4), COOP_WOOD, false)
    ramp.basis = Basis(Vector3.BACK, -atan2(drop, foot))
    for k in 4:
        var t := (k + .5) / 4.0
        var cleat := _part(game, coop, "Coop ramp cleat", Vector3(-COOP_W2 - foot * t, COOP_FLOOR - drop * t + .05, 0), Vector3(.04, .03, .38), COOP_DARK)
        cleat.basis = ramp.basis
    # Nest boxes: a row of four open boxes hung on the north face (+Z), straw inside.
    var nest_z := COOP_D2 + .28
    var nest_low := .55
    var nest_high := 1.12
    _part(game, coop, "Nest box floor", Vector3(0, nest_low, nest_z), Vector3(2.44, .05, .56), COOP_WOOD, true)
    _part(game, coop, "Nest box front lip", Vector3(0, nest_low + .08, nest_z + .26), Vector3(2.44, .12, .04), COOP_CREAM)
    var lid := _part(game, coop, "Nest box lid", Vector3(0, nest_high + .06, nest_z), Vector3(2.56, .05, .66), COOP_SLATE, true)
    lid.basis = Basis(Vector3.RIGHT, .22)
    for k in 5:
        _part(game, coop, "Nest box divider", Vector3(-1.2 + k * .6, (nest_low + nest_high) * .5, nest_z), Vector3(.04, nest_high - nest_low, .56), COOP_RED)
    for sx in [-1, 1]:
        _part(game, coop, "Nest box bracket", Vector3(sx * 1.0, nest_low - .14, nest_z - .1), Vector3(.06, .24, .3), COOP_WOOD)
    for k in 4:
        var x := -0.9 + k * .6
        _part(game, coop, "Nest straw", Vector3(x, nest_low + .05, nest_z - .02), Vector3(.5, .05, .44), STRAW)
        _spot(spots, COOP + Vector3(x, nest_low + .075, nest_z - .02))
    # Straw nests on the ground.
    for p in GROUND_NESTS:
        var nest: Node3D = game.cylinder("Straw nest", Vector3.ZERO, .24, .05, STRAW)
        nest.reparent(house, false)
        nest.position = Vector3(p.x, LAWN + .025, p.y)
        _spot(spots, Vector3(p.x, LAWN + .05, p.y))
    # The hens, at the farm hen's size.
    var hens := _node(house, "Hens", Vector3.ZERO)
    var size: Vector3 = (town.get_node("ParkZoo/Hen") as Node3D).scale
    var hen_scene: PackedScene = load("res://scenes/animals/hen.tscn")
    for i in HEN_HOMES.size():
        var hen: Node3D = hen_scene.instantiate()
        hen.name = "Hen %d" % (i + 1)
        hen.scale = size
        hen.position = HEN_HOMES[i] + Vector3(0, LAWN, 0)
        hen.rotation.y = i * 2.4
        hens.add_child(hen)
    # The egg crate on its table inside the barn door.
    var table := _node(house, "Egg table", CRATE_TABLE)
    var top_y := .72
    _part(game, table, "Egg table top", Vector3(0, top_y - .03, 0), Vector3(1.1, .06, .6), COOP_WOOD, true)
    for sx in [-1, 1]:
        for sz in [-1, 1]:
            _part(game, table, "Egg table leg", Vector3(sx * .48, (top_y - .06) * .5, sz * .23), Vector3(.06, top_y - .06, .06), COOP_DARK)
    var crate := _node(house, "Egg crate", CRATE_TABLE + Vector3(0, top_y, 0))
    _part(game, crate, "Egg crate tray", Vector3(0, .03, 0), Vector3(.96, .06, .4), Color("c9a679"))
    for sz in [-1, 1]:
        _part(game, crate, "Egg crate rail", Vector3(0, .07, sz * .19), Vector3(.96, .08, .02), COOP_WOOD)
    for sx in [-1, 1]:
        _part(game, crate, "Egg crate end", Vector3(sx * .47, .07, 0), Vector3(.02, .08, .4), COOP_WOOD)
    var slots := _node(crate, "Slots", Vector3.ZERO)
    for row in 2:
        for col in 6:
            var at := Vector3(-.375 + col * .15, .06, -.08 + row * .16)
            var cup: Node3D = game.cylinder("Egg cup", Vector3.ZERO, .055, .02, Color("e8d6b4"))
            cup.reparent(crate, false)
            cup.position = at + Vector3(0, .005, 0)
            var slot := Marker3D.new()
            slot.name = "Slot %d" % (row * 6 + col + 1)
            slots.add_child(slot)
            slot.position = at + Vector3(0, -.02, 0)

func _node(parent: Node3D, title: String, pos: Vector3) -> Node3D:
    var node := Node3D.new()
    node.name = title
    parent.add_child(node, true)
    node.position = pos
    return node

func _spot(spots: Node3D, at: Vector3) -> void:
    var spot := Marker3D.new()
    spot.name = "Spot %d" % (spots.get_child_count() + 1)
    spots.add_child(spot)
    spot.position = at

func _part(game, parent: Node3D, title: String, pos: Vector3, size: Vector3, color: Color, solid := false, word := "") -> Node3D:
    var part: Node3D = game.box(title, Vector3.ZERO, size, color, word, solid)
    part.reparent(parent, false)
    part.position = pos
    return part
