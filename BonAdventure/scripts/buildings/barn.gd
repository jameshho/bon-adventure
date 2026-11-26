extends RefCounted
## Farm barn own script (docs/guides/MODULAR_TOWN.md, "Changing a building"); the barn is saved in
## scenes/town/barn.scn. Design (1 Nov 2026, docs/guides/TOWN_DESIGN_BRIEF.md farm barn record):
## gambrel roof, open X-braced double doors, a walkable hayloft reached by a climbable ladder;
## 12 x 9 foundation. Barn frame: town units (Apartment scale 1.3 applies), door on local -Z,
## walls centred on x +-6 and z +-4.5. The constants were moved here from the deleted startup
## pass barn_interior.gd (6 Nov 2026); docs/evidence/barn-20261101/verify.gd uses them.
const STEPS := ["coplanar_gaps", "coplanar_gaps_2", "glass_windows", "hen_house", "walk_in_hen_house", "roomier_hen_house", "hen_house_flock", "palette_snap"]

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

## The walk-in hen house (user, 24 Nov 2026: "much bigger, at least 3x, the kind I can walk in";
## "no clear way to deposit the egg"). Replaces everything the `hen_house` step built under
## `Barn/Hen house` (same node, same script, same child names): a red coop BonBon walks into,
## 7.0 x 5.0 (6.5 times the little coop's floor), eave 3.0, ridge 4.3, standing on the lawn in the
## paddock's west half (x 81.5...88.5, z 73.8...78.8; south fence z 73, west fence x 90, hay
## bale at (82, 80.2)). A 2.0 x 2.6 doorway in its east wall faces the barn; inside, five nest
## boxes on the west wall, a straw nest in a corner, a roost and a feeder; five straw nests in
## the yard east of it. The egg crate stands on its table OUTSIDE, against the east wall north of
## the doorway, under a painted egg sign, so it is seen from the yard and the barn; hen_house.gd
## floats an arrow over it while an egg is carried. Two hens live inside, four in the yard.
const WALK_COOP := Vector3(85.0, 0.0, 76.3)
const WALK_W2 := 3.5
const WALK_D2 := 2.5
const WALK_EAVE := 3.0
const WALK_RIDGE := 4.3
const WALK_WALL := .12
const WALK_DOOR_W2 := 1.0
const WALK_DOOR_H := 2.6
## Nest boxes on the inside of the west wall (coop-local x), floor height and box width.
const WALK_NEST_LOW := .62
const WALK_NEST_HIGH := 1.22
const WALK_NEST_W := .7
const WALK_NEST_D := .6
## Straw nests in the yard (town x, z): east of the coop, clear of its doorway and the hay bale.
const WALK_GROUND_NESTS := [Vector2(76.4, 78.0), Vector2(79.2, 79.8), Vector2(74.8, 75.4),
    Vector2(78.3, 74.6), Vector2(76.9, 81.2)]
## The corner straw nest inside (town x, z).
const WALK_INSIDE_NEST := Vector2(87.2, 74.3)
const WALK_HEN_HOMES := [Vector3(76.0, 0, 79.4), Vector3(77.6, 0, 80.6), Vector3(79.2, 0, 77.4),
    Vector3(75.4, 0, 77.0), Vector3(84.4, 0, 75.4), Vector3(86.4, 0, 77.4)]
## The egg crate's table: outside, against the east wall north of the doorway (town).
const WALK_CRATE_TABLE := Vector3(81.0, LAWN, 78.1)

func walk_in_hen_house(town: Node3D, game) -> void:
    var barn: Node3D = town.get_node("Barn")
    var old: Node3D = barn.get_node("Hen house")
    var xf := old.transform
    barn.remove_child(old)
    old.free()
    var house := Node3D.new()
    house.name = "Hen house"
    house.set_script(preload("res://scripts/world/hen_house.gd"))
    barn.add_child(house)
    house.transform = xf
    var coop := _node(house, "Coop", WALK_COOP)
    var spots := _node(house, "Egg spots", Vector3.ZERO)
    var t := WALK_WALL
    # Floor: planks and straw on the lawn, not solid (the hens' step test and BonBon stand on the
    # lawn under it).
    _part(game, coop, "Coop floor", Vector3(0, LAWN + .015, 0), Vector3(WALK_W2 * 2 - t * 2, .03, WALK_D2 * 2 - t * 2), COOP_WOOD)
    _part(game, coop, "Coop floor straw", Vector3(.6, LAWN + .035, 0), Vector3(WALK_W2 * 2 - 2.2, .012, WALK_D2 * 2 - .8), STRAW)
    # Walls (solid): back (west, +X), north and south full; east split by the doorway.
    var wall_y := LAWN + (WALK_EAVE - LAWN) * .5
    var wall_h := WALK_EAVE - LAWN
    _part(game, coop, "Coop back wall", Vector3(WALK_W2 - t * .5, wall_y, 0), Vector3(t, wall_h, WALK_D2 * 2), COOP_RED, true)
    for sz in [-1, 1]:
        _part(game, coop, "Coop side wall", Vector3(0, wall_y, sz * (WALK_D2 - t * .5)), Vector3(WALK_W2 * 2, wall_h, t), COOP_RED, true)
        var side := WALK_D2 - WALK_DOOR_W2
        _part(game, coop, "Coop front wall", Vector3(-WALK_W2 + t * .5, wall_y, sz * (WALK_DOOR_W2 + side * .5)), Vector3(t, wall_h, side), COOP_RED, true)
    var lintel_h := WALK_EAVE - (LAWN + WALK_DOOR_H)
    _part(game, coop, "Coop door header", Vector3(-WALK_W2 + t * .5, WALK_EAVE - lintel_h * .5, 0), Vector3(t, lintel_h, WALK_DOOR_W2 * 2), COOP_RED, true)
    # Cream trim: corner boards and the door frame (on the outer face).
    for sx in [-1, 1]:
        for sz in [-1, 1]:
            _part(game, coop, "Coop corner board", Vector3(sx * (WALK_W2 - .03), wall_y, sz * (WALK_D2 - .03)), Vector3(.16, wall_h + .02, .16), COOP_CREAM)
    for sz in [-1, 1]:
        _part(game, coop, "Coop door frame", Vector3(-WALK_W2 - .02, LAWN + WALK_DOOR_H * .5, sz * (WALK_DOOR_W2 + .06)), Vector3(.08, WALK_DOOR_H, .14), COOP_CREAM)
    _part(game, coop, "Coop door frame", Vector3(-WALK_W2 - .02, LAWN + WALK_DOOR_H + .06, 0), Vector3(.08, .14, WALK_DOOR_W2 * 2 + .26), COOP_CREAM)
    # The barn-style door, swung open flat against the wall south of the doorway (outside; not
    # solid so it never blocks the way in), with its X brace.
    var leaf_w := 1.3
    var leaf_h := WALK_DOOR_H - .1
    var leaf := _node(coop, "Coop door", Vector3(-WALK_W2 - .1, LAWN + .05, -WALK_DOOR_W2 - .15 - leaf_w * .5))
    _part(game, leaf, "Coop door leaf", Vector3(0, leaf_h * .5, 0), Vector3(.06, leaf_h, leaf_w), COOP_RED)
    for k in 2:
        var brace := _part(game, leaf, "Coop door brace", Vector3(-.04, leaf_h * .5, 0), Vector3(.03, sqrt(leaf_h * leaf_h + leaf_w * leaf_w) - .15, .12), COOP_CREAM)
        brace.basis = Basis(Vector3.RIGHT, (1 if k == 0 else -1) * atan2(leaf_w, leaf_h))
    # Gables and roof (ridge along X, like the barn's).
    for sx in [-1, 1]:
        var gable := MeshInstance3D.new()
        gable.name = "Coop gable"
        var prism := PrismMesh.new()
        prism.size = Vector3(WALK_D2 * 2, WALK_RIDGE - WALK_EAVE, t)
        gable.mesh = prism
        gable.material_override = game.material_for(COOP_RED)
        coop.add_child(gable, true)
        gable.transform = Transform3D(Basis(Vector3.UP, PI / 2), Vector3(sx * (WALK_W2 - t * .5), WALK_EAVE + (WALK_RIDGE - WALK_EAVE) * .5, 0))
    var rise := WALK_RIDGE - WALK_EAVE
    var tilt := atan2(rise, WALK_D2)
    var run := WALK_D2 + .35
    var slab := run / cos(tilt)
    for sz in [-1, 1]:
        var roof := _part(game, coop, "Coop roof", Vector3(0, WALK_RIDGE - run * tan(tilt) * .5 + .07, sz * run * .5), Vector3(WALK_W2 * 2 + .5, .1, slab + .08), COOP_SLATE, true)
        roof.basis = Basis(Vector3.RIGHT, sz * tilt)
    _part(game, coop, "Coop ridge cap", Vector3(0, WALK_RIDGE + .09, 0), Vector3(WALK_W2 * 2 + .56, .1, .2), COOP_CREAM)
    # Windows: a cream frame and a sky pane on each long wall's outer and inner face.
    for sz in [-1, 1]:
        for wx in [-1.2, 1.4]:
            for face in [1, -1]:
                var z: float = sz * (WALK_D2 + (.02 if face == 1 else -t - .02))
                _part(game, coop, "Coop window frame", Vector3(wx, 1.9, z), Vector3(1.0, .8, .03), COOP_CREAM)
                _part(game, coop, "Coop window pane", Vector3(wx, 1.9, z + sz * face * .01), Vector3(.8, .6, .02), Color("bfe3f2"))
    # Nest boxes on the inside of the west wall, open toward the door.
    var nest_x := WALK_W2 - t - WALK_NEST_D * .5
    var span := WALK_NEST_W * 5.0
    _part(game, coop, "Nest box floor", Vector3(nest_x, WALK_NEST_LOW, 0), Vector3(WALK_NEST_D, .05, span), COOP_WOOD, true)
    _part(game, coop, "Nest box front lip", Vector3(nest_x - WALK_NEST_D * .5 + .02, WALK_NEST_LOW + .08, 0), Vector3(.04, .12, span), COOP_CREAM)
    var lid := _part(game, coop, "Nest box lid", Vector3(nest_x, WALK_NEST_HIGH + .06, 0), Vector3(WALK_NEST_D + .1, .05, span + .1), COOP_SLATE, true)
    lid.basis = Basis(Vector3.BACK, .22)
    for k in 6:
        _part(game, coop, "Nest box divider", Vector3(nest_x, (WALK_NEST_LOW + WALK_NEST_HIGH) * .5, -span * .5 + k * WALK_NEST_W), Vector3(WALK_NEST_D, WALK_NEST_HIGH - WALK_NEST_LOW, .04), COOP_RED)
    for k in 2:
        _part(game, coop, "Nest box leg", Vector3(nest_x - WALK_NEST_D * .5 + .06, (LAWN + WALK_NEST_LOW) * .5, (k * 2 - 1) * (span * .5 - .06)), Vector3(.08, WALK_NEST_LOW - LAWN, .08), COOP_WOOD)
    for k in 5:
        var z := -span * .5 + (k + .5) * WALK_NEST_W
        _part(game, coop, "Nest straw", Vector3(nest_x + .02, WALK_NEST_LOW + .05, z), Vector3(WALK_NEST_D - .12, .05, WALK_NEST_W - .14), STRAW)
        _spot(spots, WALK_COOP + Vector3(nest_x + .02, WALK_NEST_LOW + .075, z))
    # The corner nest inside.
    var inner: Node3D = game.cylinder("Straw nest", Vector3.ZERO, .26, .05, STRAW)
    inner.reparent(house, false)
    inner.position = Vector3(WALK_INSIDE_NEST.x, LAWN + .05, WALK_INSIDE_NEST.y)
    _spot(spots, Vector3(WALK_INSIDE_NEST.x, LAWN + .075, WALK_INSIDE_NEST.y))
    # A roost (two perch poles on posts) along the south wall, and a feeder and waterer by the
    # north wall: scenery, not solid.
    for px in [-1.6, 1.0]:
        _part(game, coop, "Roost post", Vector3(px, LAWN + .7, -WALK_D2 + .55), Vector3(.08, 1.4, .08), COOP_WOOD)
    for k in 2:
        var pole: Node3D = game.cylinder("Roost pole", Vector3.ZERO, .04, 2.8, COOP_WOOD)
        pole.reparent(coop, false)
        pole.position = Vector3(-.3, LAWN + .75 + k * .55, -WALK_D2 + .45 + k * .2)
        pole.basis = Basis(Vector3.BACK, PI / 2)
    var feeder: Node3D = game.cylinder("Hen feeder", Vector3.ZERO, .22, .5, COOP_SLATE)
    feeder.reparent(coop, false)
    feeder.position = Vector3(1.3, LAWN + .25, WALK_D2 - .5)
    var water: Node3D = game.cylinder("Hen waterer", Vector3.ZERO, .2, .4, Color("8fb7c9"))
    water.reparent(coop, false)
    water.position = Vector3(.5, LAWN + .2, WALK_D2 - .5)
    # Straw nests in the yard.
    for p in WALK_GROUND_NESTS:
        var nest: Node3D = game.cylinder("Straw nest", Vector3.ZERO, .24, .05, STRAW)
        nest.reparent(house, false)
        nest.position = Vector3(p.x, LAWN + .025, p.y)
        _spot(spots, Vector3(p.x, LAWN + .05, p.y))
    # The hens, at the farm hen's size: four in the yard, two inside.
    var hens := _node(house, "Hens", Vector3.ZERO)
    var size: Vector3 = (town.get_node("ParkZoo/Hen") as Node3D).scale
    var hen_scene: PackedScene = load("res://scenes/animals/hen.tscn")
    for i in WALK_HEN_HOMES.size():
        var hen: Node3D = hen_scene.instantiate()
        hen.name = "Hen %d" % (i + 1)
        hen.scale = size
        hen.position = WALK_HEN_HOMES[i] + Vector3(0, LAWN, 0)
        hen.rotation.y = i * 2.4
        hens.add_child(hen)
    # The egg crate on its table outside the door, long side along the wall, and the egg sign.
    var table := _node(house, "Egg table", WALK_CRATE_TABLE)
    table.rotation.y = PI / 2
    var top_y := .78
    _part(game, table, "Egg table top", Vector3(0, top_y - .03, 0), Vector3(1.2, .06, .62), COOP_WOOD, true)
    for sx in [-1, 1]:
        for sz in [-1, 1]:
            _part(game, table, "Egg table leg", Vector3(sx * .52, (top_y - .06) * .5, sz * .24), Vector3(.06, top_y - .06, .06), COOP_DARK)
    var crate := _node(house, "Egg crate", WALK_CRATE_TABLE + Vector3(0, top_y, 0))
    crate.rotation.y = PI / 2
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
    # The sign over the crate: a cream board with a big egg and a small crate (no words).
    var sign := _node(house, "Egg sign", Vector3(WALK_COOP.x - WALK_W2 - .05, 2.0, WALK_CRATE_TABLE.z))
    _part(game, sign, "Egg sign board", Vector3(-.02, 0, 0), Vector3(.05, .9, 1.1), COOP_CREAM)
    _part(game, sign, "Egg sign rim", Vector3(-.005, 0, 0), Vector3(.04, .98, 1.18), COOP_WOOD)
    var big: Node3D = game.cylinder("Egg sign egg", Vector3.ZERO, .2, .03, Color("fbf6ea"))
    big.reparent(sign, false)
    # The disc faces out (its axis along X), stretched up into an egg.
    big.position = Vector3(-.06, .1, 0)
    big.basis = Basis.from_scale(Vector3(1.0, 1.3, 1.0)) * Basis(Vector3.BACK, PI / 2)
    _part(game, sign, "Egg sign crate", Vector3(-.06, -.28, 0), Vector3(.03, .14, .56), Color("c9a679"))
    _part(game, sign, "Egg sign arrow", Vector3(-.06, -.12, 0), Vector3(.03, .1, .06), COOP_RED)

## The roomier hen house (user, 25 Nov 2026: "improve the interior of the hen house and make it
## bigger by 20%. also fix the flickering, the baskets in the house is flickering"; and "the new
## hen should replace the old ones"). Replaces everything `walk_in_hen_house` built under
## `Barn/Hen house` (same node, script, child names and spot order: five nest boxes, the corner
## nest, five yard nests, so saved eggs keep their spots). Every size is the walk-in coop's
## times 1.2: 8.4 x 6.0, eave 3.58, ridge 5.14, doorway 2.4 x 3.1, on the lawn at town
## x 81.1...89.5, z 73.4...79.4 (west fence x 90, south fence z 73).
## Flicker fix: the old nest row put its straw's underside on the shelf top and its dividers' and
## lip's faces in the shelf's planes. Here no two parts share a face plane: boards meet edge to
## face, dividers stop short of the shelf fronts, straw floats a centimetre up, and window panes
## sit inside their frame bars instead of behind them.
## Inside: a plank floor with loose straw patches (each at its own height), a wood wainscot on
## three walls, tie beams and a ridge beam, five separate nest cubbies on a stand with a perch
## bar and a ladder plank up to it, a ladder roost against the south wall, a hanging tube feeder
## and a bell waterer on a block, a dust bath, a hay bale with a feed sack and a lantern. The
## six hens are copies of the farm's clay hen ParkZoo/Hen (base step `hen_clay_roams`; bake the
## base first): four in the yard, two inside.
const ROOMY := 1.2
const ROOMY_COOP := Vector3(85.3, 0.0, 76.4)
const ROOMY_W2 := WALK_W2 * ROOMY
const ROOMY_D2 := WALK_D2 * ROOMY
const ROOMY_EAVE := LAWN + (WALK_EAVE - LAWN) * ROOMY
const ROOMY_RIDGE := LAWN + (WALK_RIDGE - LAWN) * ROOMY
const ROOMY_DOOR_W2 := WALK_DOOR_W2 * ROOMY
const ROOMY_DOOR_H := WALK_DOOR_H * ROOMY
const ROOMY_NEST_LOW := WALK_NEST_LOW * ROOMY
const ROOMY_NEST_HIGH := WALK_NEST_HIGH * ROOMY
const ROOMY_NEST_W := WALK_NEST_W * ROOMY
const ROOMY_NEST_D := WALK_NEST_D * ROOMY
## The corner straw nest inside (town x, z): south-west corner, clear of the nest stand.
const ROOMY_INSIDE_NEST := Vector2(88.7, 74.0)
const ROOMY_HEN_HOMES := [Vector3(76.0, 0, 79.4), Vector3(77.6, 0, 80.6), Vector3(79.2, 0, 77.4),
    Vector3(75.4, 0, 77.0), Vector3(84.2, 0, 75.4), Vector3(86.6, 0, 77.6)]
## The egg crate's table: outside, against the east wall north of the doorway (town).
const ROOMY_CRATE_TABLE := Vector3(80.45, LAWN, 78.6)
const COOP_LINING := Color("c79a63")
const COOP_STEEL := Color("9aa4ab")
const SAND := Color("d9c08f")
const BURLAP := Color("c8b48a")

func roomier_hen_house(town: Node3D, game) -> void:
    var hen_model: Node3D = town.get_node("ParkZoo/Hen")
    assert(hen_model.has_node("ClayHen"), "roomier_hen_house: bake the base (hen_clay_roams) first")
    var barn: Node3D = town.get_node("Barn")
    var old: Node3D = barn.get_node("Hen house")
    var xf := old.transform
    barn.remove_child(old)
    old.free()
    var house := Node3D.new()
    house.name = "Hen house"
    house.set_script(preload("res://scripts/world/hen_house.gd"))
    barn.add_child(house)
    house.transform = xf
    var coop := _node(house, "Coop", ROOMY_COOP)
    var spots := _node(house, "Egg spots", Vector3.ZERO)
    var t := WALK_WALL
    var w2 := ROOMY_W2
    var d2 := ROOMY_D2
    var in_w2 := w2 - t
    var in_d2 := d2 - t
    # Floor: planks on the lawn (not solid: the hens' step test and BonBon stand on the lawn).
    _part(game, coop, "Coop floor", Vector3(0, LAWN + .015, 0), Vector3(in_w2 * 2, .03, in_d2 * 2), COOP_WOOD)
    # Loose straw patches, each a centimetre above the last so no two tops share a plane.
    var patches := [[Vector3(1.6, 0, .4), 2.0], [Vector3(-.4, 0, -1.2), 1.6], [Vector3(.4, 0, 1.5), 1.4],
        [Vector3(2.6, 0, -1.9), 1.1], [Vector3(-2.0, 0, .9), 1.2], [Vector3(-1.2, 0, 2.1), .8]]
    for k in patches.size():
        var patch: Node3D = game.cylinder("Coop floor straw", Vector3.ZERO, patches[k][1] * .5, .01, STRAW)
        patch.reparent(coop, false)
        patch.position = patches[k][0] + Vector3(0, LAWN + .04 + k * .012, 0)
        patch.basis = Basis.from_scale(Vector3(1.0, 1.0, .7))
    # Walls (solid): back (west, +X) between the side walls; north and south full length; east
    # split by the doorway, also between the side walls.
    var wall_h := ROOMY_EAVE - LAWN
    var wall_y := LAWN + wall_h * .5
    _part(game, coop, "Coop back wall", Vector3(w2 - t * .5, wall_y, 0), Vector3(t, wall_h, in_d2 * 2), COOP_RED, true)
    var side := in_d2 - ROOMY_DOOR_W2
    for sz in [-1, 1]:
        _part(game, coop, "Coop side wall", Vector3(0, wall_y, sz * (d2 - t * .5)), Vector3(w2 * 2, wall_h, t), COOP_RED, true)
        _part(game, coop, "Coop front wall", Vector3(-w2 + t * .5, wall_y, sz * (ROOMY_DOOR_W2 + side * .5)), Vector3(t, wall_h, side), COOP_RED, true)
    var lintel_h := ROOMY_EAVE - (LAWN + ROOMY_DOOR_H)
    _part(game, coop, "Coop door header", Vector3(-w2 + t * .5, ROOMY_EAVE - lintel_h * .5, 0), Vector3(t, lintel_h, ROOMY_DOOR_W2 * 2), COOP_RED, true)
    # Cream trim: corner boards and the door frame (on the outer face).
    for sx in [-1, 1]:
        for sz in [-1, 1]:
            _part(game, coop, "Coop corner board", Vector3(sx * (w2 - .03), wall_y, sz * (d2 - .03)), Vector3(.17, wall_h + .02, .17), COOP_CREAM)
    for sz in [-1, 1]:
        _part(game, coop, "Coop door frame", Vector3(-w2 - .045, LAWN + ROOMY_DOOR_H * .5, sz * (ROOMY_DOOR_W2 + .07)), Vector3(.08, ROOMY_DOOR_H, .14), COOP_CREAM)
    _part(game, coop, "Coop door frame", Vector3(-w2 - .045, LAWN + ROOMY_DOOR_H + .07, 0), Vector3(.08, .14, ROOMY_DOOR_W2 * 2 + .28), COOP_CREAM)
    # The barn-style door, swung open flat against the wall south of the doorway (outside; not
    # solid so it never blocks the way in), with its X brace.
    var leaf_w := 1.4
    var leaf_h := ROOMY_DOOR_H - .1
    var leaf := _node(coop, "Coop door", Vector3(-w2 - .12, LAWN + .05, -ROOMY_DOOR_W2 - .17 - leaf_w * .5))
    _part(game, leaf, "Coop door leaf", Vector3(0, leaf_h * .5, 0), Vector3(.06, leaf_h, leaf_w), COOP_RED)
    for k in 2:
        var brace := _part(game, leaf, "Coop door brace", Vector3(-.045, leaf_h * .5, 0), Vector3(.03, sqrt(leaf_h * leaf_h + leaf_w * leaf_w) - .15, .12), COOP_CREAM)
        brace.basis = Basis(Vector3.RIGHT, (1 if k == 0 else -1) * atan2(leaf_w, leaf_h))
    # Gables and roof (ridge along X, like the barn's).
    for sx in [-1, 1]:
        var gable := MeshInstance3D.new()
        gable.name = "Coop gable"
        var prism := PrismMesh.new()
        prism.size = Vector3(d2 * 2, ROOMY_RIDGE - ROOMY_EAVE, t)
        gable.mesh = prism
        gable.material_override = game.material_for(COOP_RED)
        coop.add_child(gable, true)
        gable.transform = Transform3D(Basis(Vector3.UP, PI / 2), Vector3(sx * (w2 - t * .5), ROOMY_EAVE + (ROOMY_RIDGE - ROOMY_EAVE) * .5, 0))
    var rise := ROOMY_RIDGE - ROOMY_EAVE
    var tilt := atan2(rise, d2)
    var run := d2 + .4
    var slab := run / cos(tilt)
    for sz in [-1, 1]:
        var roof := _part(game, coop, "Coop roof", Vector3(0, ROOMY_RIDGE - run * tan(tilt) * .5 + .08, sz * run * .5), Vector3(w2 * 2 + .6, .1, slab + .08), COOP_SLATE, true)
        roof.basis = Basis(Vector3.RIGHT, sz * tilt)
    _part(game, coop, "Coop ridge cap", Vector3(0, ROOMY_RIDGE + .1, 0), Vector3(w2 * 2 + .66, .1, .22), COOP_CREAM)
    # Windows on each long wall, outside and inside: a pane with four frame bars around it (not
    # behind it, so pane and frame never overlap in one plane) and a cross of muntins proud of it.
    var win_y := LAWN + 2.15
    for sz in [-1, 1]:
        for wx in [-1.6, 1.4]:
            for face in [1, -1]:
                var z: float = sz * (d2 + .02) if face == 1 else sz * (in_d2 - .02)
                var out: float = sz * face * .012
                _part(game, coop, "Coop window pane", Vector3(wx, win_y, z), Vector3(.96, .72, .02), Color("bfe3f2"))
                for sy in [-1, 1]:
                    _part(game, coop, "Coop window frame", Vector3(wx, win_y + sy * .42, z), Vector3(1.2, .12, .03), COOP_CREAM)
                    _part(game, coop, "Coop window frame", Vector3(wx + sy * .54, win_y, z), Vector3(.12, .72, .03), COOP_CREAM)
                _part(game, coop, "Coop window muntin", Vector3(wx, win_y, z + out), Vector3(.04, .74, .02), COOP_CREAM)
                _part(game, coop, "Coop window muntin", Vector3(wx, win_y, z + out * 1.5), Vector3(.98, .04, .02), COOP_CREAM)
    # Wood wainscot inside the back and side walls, two centimetres off them, with a cream rail.
    var wain := 1.15
    var lining := [[Vector3(in_w2 - .035, 0, 0), Vector3(.03, wain, in_d2 * 2 - .1)]]
    for sz in [-1, 1]:
        lining.append([Vector3(.05, 0, sz * (in_d2 - .035)), Vector3(in_w2 * 2 - .2, wain, .03)])
    for l in lining:
        var at: Vector3 = l[0]
        var size: Vector3 = l[1]
        _part(game, coop, "Coop wainscot", at + Vector3(0, LAWN + .03 + wain * .5, 0), size, COOP_LINING)
        var rail_size := Vector3(size.x + (.03 if size.x < .1 else 0.0), .06, size.z + (.03 if size.z < .1 else 0.0))
        var inward := Vector3(-.015 if size.x < .1 else 0.0, 0, 0)
        if size.z < .1:
            inward = Vector3(0, 0, -.015 * signf(at.z))
        _part(game, coop, "Coop wainscot rail", at + inward + Vector3(0, LAWN + .03 + wain + .03, 0), rail_size, COOP_CREAM)
    # Roof frame inside: three tie beams across the walls and a ridge beam.
    for bx in [-2.4, 0.0, 2.4]:
        _part(game, coop, "Coop tie beam", Vector3(bx, ROOMY_EAVE - .12, 0), Vector3(.14, .16, in_d2 * 2), COOP_WOOD)
    _part(game, coop, "Coop ridge beam", Vector3(0, ROOMY_RIDGE - .22, 0), Vector3(in_w2 * 2, .16, .14), COOP_WOOD)
    for bx in [-2.4, 0.0, 2.4]:
        _part(game, coop, "Coop king post", Vector3(bx, (ROOMY_EAVE - .04 + ROOMY_RIDGE - .3) * .5, 0), Vector3(.1, ROOMY_RIDGE - .3 - ROOMY_EAVE + .04, .1), COOP_WOOD)
    # A lantern hanging from the middle tie beam.
    var chain: Node3D = game.cylinder("Coop lantern chain", Vector3.ZERO, .012, .5, COOP_DARK)
    chain.reparent(coop, false)
    chain.position = Vector3(0, ROOMY_EAVE - .2 - .25, .9)
    _part(game, coop, "Coop lantern top", Vector3(0, ROOMY_EAVE - .72, .9), Vector3(.2, .05, .2), COOP_DARK)
    _part(game, coop, "Coop lantern glass", Vector3(0, ROOMY_EAVE - .87, .9), Vector3(.15, .24, .15), Color("ffd98a"))
    _part(game, coop, "Coop lantern base", Vector3(0, ROOMY_EAVE - 1.015, .9), Vector3(.2, .05, .2), COOP_DARK)
    # Nest boxes: five separate cubbies on a stand against the west wall, open toward the door.
    # Shelf and top boards run the row's length; dividers stand between them and stop 2 cm short
    # of the boards' front edges; the straw floats 1 cm above the shelf.
    var nd := ROOMY_NEST_D
    var nw := ROOMY_NEST_W
    var span := nw * 5.0
    var nest_x := in_w2 - .045 - nd * .5
    var board := .05
    var low := ROOMY_NEST_LOW
    var high := ROOMY_NEST_HIGH
    _part(game, coop, "Nest box shelf", Vector3(nest_x, low - board * .5, 0), Vector3(nd, board, span + .08), COOP_WOOD, true)
    _part(game, coop, "Nest box top", Vector3(nest_x, high + board * .5, 0), Vector3(nd + .06, board, span + .14), COOP_RED, true)
    _part(game, coop, "Nest box top trim", Vector3(nest_x - nd * .5 - .015, high + board + .03, 0), Vector3(.03, .06, span + .14), COOP_CREAM)
    for k in 6:
        var dz := -span * .5 + k * nw
        _part(game, coop, "Nest box divider", Vector3(nest_x + .01, (low + high) * .5, dz), Vector3(nd - .02, high - low, .04 if k in [0, 5] else .03), COOP_RED)
    _part(game, coop, "Nest box front lip", Vector3(nest_x - nd * .5 + .03, low + .0725, 0), Vector3(.03, .135, span - .02), COOP_CREAM)
    for k in 3:
        _part(game, coop, "Nest box leg", Vector3(nest_x - nd * .5 + .07, (LAWN + low - board) * .5, (k - 1) * (span * .5 - .08)), Vector3(.08, low - board - LAWN, .08), COOP_WOOD)
        _part(game, coop, "Nest box brace", Vector3(nest_x + .035, low - board - .06, (k - 1) * (span * .5 - .08)), Vector3(nd - .07, .07, .06), COOP_WOOD)
    var perch: Node3D = game.cylinder("Nest box perch", Vector3.ZERO, .03, span, COOP_WOOD)
    perch.reparent(coop, false)
    perch.position = Vector3(nest_x - nd * .5 - .2, low - .12, 0)
    perch.basis = Basis(Vector3.RIGHT, PI / 2)
    for sz in [-1, 1]:
        _part(game, coop, "Nest box perch arm", Vector3(nest_x - nd * .5 - .07, low - .12, sz * (span * .5 - .08)), Vector3(.28, .04, .04), COOP_WOOD)
    for k in 5:
        var z := -span * .5 + (k + .5) * nw
        var straw: Node3D = game.cylinder("Nest straw", Vector3.ZERO, nw * .38, .06, STRAW)
        straw.reparent(coop, false)
        straw.position = Vector3(nest_x + .02, low + .04, z)
        straw.basis = Basis.from_scale(Vector3(1.0, 1.0, 1.15))
        _spot(spots, ROOMY_COOP + Vector3(nest_x + .02, low + .075, z))
    # A ladder plank from the floor up to the perch, with cleats.
    var climb_run := 1.1
    var climb_rise := low - .14 - LAWN
    var ladder := _part(game, coop, "Nest ladder", Vector3(nest_x - nd * .5 - .25 - climb_run * .5, LAWN + climb_rise * .5 + .02, -nw), Vector3(sqrt(climb_run * climb_run + climb_rise * climb_rise), .04, .32), COOP_WOOD)
    ladder.basis = Basis(Vector3.BACK, atan2(climb_rise, climb_run))
    for k in 4:
        var f := (k + .5) / 4.0
        var cleat := _part(game, coop, "Nest ladder cleat", Vector3(nest_x - nd * .5 - .25 - climb_run * (1.0 - f), LAWN + climb_rise * f + .055, -nw), Vector3(.035, .03, .3), COOP_DARK)
        cleat.basis = ladder.basis
    # The corner nest inside.
    var inner: Node3D = game.cylinder("Straw nest", Vector3.ZERO, .3, .05, STRAW)
    inner.reparent(house, false)
    inner.position = Vector3(ROOMY_INSIDE_NEST.x, LAWN + .07, ROOMY_INSIDE_NEST.y)
    _spot(spots, Vector3(ROOMY_INSIDE_NEST.x, LAWN + .095, ROOMY_INSIDE_NEST.y))
    # A ladder roost leaning on the south wall: two rails and four rungs (scenery, not solid).
    var roost_x := [-2.6, 0.8]
    var foot_z := -in_d2 + 1.25
    var top_z := -in_d2 + .12
    var top_y := LAWN + 1.9
    var rail_len := Vector2(foot_z - top_z, top_y - LAWN).length()
    var lean := atan2(foot_z - top_z, top_y - LAWN)
    for rx in roost_x:
        var rail := _part(game, coop, "Roost rail", Vector3(rx, (LAWN + top_y) * .5, (foot_z + top_z) * .5), Vector3(.07, rail_len, .07), COOP_WOOD)
        rail.basis = Basis(Vector3.RIGHT, -lean)
    for k in 4:
        var f := (k + .7) / 4.4
        var rung: Node3D = game.cylinder("Roost rung", Vector3.ZERO, .035, roost_x[1] - roost_x[0] + .2, COOP_WOOD)
        rung.reparent(coop, false)
        rung.position = Vector3((roost_x[0] + roost_x[1]) * .5, LAWN + (top_y - LAWN) * f, foot_z + (top_z - foot_z) * f)
        rung.basis = Basis(Vector3.BACK, PI / 2)
    # A hanging tube feeder and a bell waterer on a block, by the north wall.
    var feeder_at := Vector3(.6, 0, in_d2 - .9)
    var tube: Node3D = game.cylinder("Hen feeder", Vector3.ZERO, .13, .6, COOP_STEEL)
    tube.reparent(coop, false)
    tube.position = feeder_at + Vector3(0, LAWN + .62, 0)
    var pan: Node3D = game.cylinder("Hen feeder pan", Vector3.ZERO, .26, .06, COOP_SLATE)
    pan.reparent(coop, false)
    pan.position = feeder_at + Vector3(0, LAWN + .3, 0)
    # It hangs from a bar under the tie beams at x 0 and 2.4.
    var cord: Node3D = game.cylinder("Hen feeder cord", Vector3.ZERO, .01, ROOMY_EAVE - .25 - (LAWN + .92), COOP_DARK)
    cord.reparent(coop, false)
    cord.position = feeder_at + Vector3(0, (ROOMY_EAVE - .25 + LAWN + .92) * .5, 0)
    var beam: Node3D = game.cylinder("Hen feeder bar", Vector3.ZERO, .025, 2.54, COOP_WOOD)
    beam.reparent(coop, false)
    beam.position = Vector3(1.2, ROOMY_EAVE - .225, feeder_at.z)
    beam.basis = Basis(Vector3.BACK, PI / 2)
    _part(game, coop, "Hen waterer block", Vector3(-.7, LAWN + .03 + .09, in_d2 - .7), Vector3(.5, .18, .5), Color("a8a39a"))
    var water: Node3D = game.cylinder("Hen waterer", Vector3.ZERO, .2, .38, Color("8fb7c9"))
    water.reparent(coop, false)
    water.position = Vector3(-.7, LAWN + .21 + .19 + .01, in_d2 - .7)
    var drink: Node3D = game.cylinder("Hen waterer tray", Vector3.ZERO, .27, .05, Color("6f9fb5"))
    drink.reparent(coop, false)
    drink.position = Vector3(-.7, LAWN + .21 + .025, in_d2 - .7)
    # A dust bath: a low frame of boards with sand, in the north-east corner by the door.
    var bath := Vector3(-2.9, 0, in_d2 - .75)
    _part(game, coop, "Dust bath sand", bath + Vector3(0, LAWN + .07, 0), Vector3(1.0, .06, .8), SAND)
    for sz in [-1, 1]:
        _part(game, coop, "Dust bath board", bath + Vector3(0, LAWN + .07, sz * .43), Vector3(1.12, .14, .06), COOP_WOOD)
    for sx in [-1, 1]:
        _part(game, coop, "Dust bath board", bath + Vector3(sx * .53, LAWN + .07, 0), Vector3(.06, .14, .8), COOP_WOOD)
    # A hay bale with a feed sack in the south-west corner past the roost.
    var bale := Vector3(2.2, 0, -in_d2 + .55)
    _part(game, coop, "Coop hay bale", bale + Vector3(0, LAWN + .03 + .3, 0), Vector3(1.1, .6, .7), STRAW, true)
    for bx in [-.3, .3]:
        _part(game, coop, "Coop hay twine", bale + Vector3(bx, LAWN + .03 + .3, 0), Vector3(.03, .62, .72), COOP_DARK)
    var sack := _part(game, coop, "Coop feed sack", bale + Vector3(-.95, LAWN + .03 + .3, .05), Vector3(.45, .6, .32), BURLAP)
    sack.basis = Basis(Vector3.BACK, -.08)
    _part(game, coop, "Coop feed sack tie", bale + Vector3(-.97, LAWN + .66, .05), Vector3(.3, .08, .22), BURLAP.darkened(.15))
    # Straw nests in the yard (same spots as before, all east of the coop).
    for p in WALK_GROUND_NESTS:
        var nest: Node3D = game.cylinder("Straw nest", Vector3.ZERO, .24, .05, STRAW)
        nest.reparent(house, false)
        nest.position = Vector3(p.x, LAWN + .025, p.y)
        _spot(spots, Vector3(p.x, LAWN + .05, p.y))
    # The hens: copies of the farm's clay hen, at its size (ParkZoo's frame undone), soles on the
    # lawn; four in the yard, two inside.
    var hens := _node(house, "Hens", Vector3.ZERO)
    var zoo: Node3D = town.get_node("ParkZoo")
    var size: float = (zoo.transform.basis * hen_model.transform.basis).get_scale().x
    var bounds: AABB = hen_model.call("_visible_bounds")
    for i in ROOMY_HEN_HOMES.size():
        var hen: Node3D = hen_model.duplicate()
        hen.name = "Hen %d" % (i + 1)
        hen.transform = Transform3D(Basis(Vector3.UP, i * 2.4).scaled(Vector3.ONE * size), ROOMY_HEN_HOMES[i] + Vector3(0, LAWN - bounds.position.y * size, 0))
        hens.add_child(hen)
    print("ROOMIER HEN HOUSE: %d hens, %.3f tall, %d egg spots" % [hens.get_child_count(), bounds.size.y * size, spots.get_child_count()])
    # The egg crate on its table outside the door, long side along the wall, and the egg sign.
    var table := _node(house, "Egg table", ROOMY_CRATE_TABLE)
    table.rotation.y = PI / 2
    var table_top := .78
    _part(game, table, "Egg table top", Vector3(0, table_top - .03, 0), Vector3(1.2, .06, .62), COOP_WOOD, true)
    for sx in [-1, 1]:
        for sz in [-1, 1]:
            _part(game, table, "Egg table leg", Vector3(sx * .52, (table_top - .06) * .5, sz * .24), Vector3(.06, table_top - .06, .06), COOP_DARK)
    var crate := _node(house, "Egg crate", ROOMY_CRATE_TABLE + Vector3(0, table_top, 0))
    crate.rotation.y = PI / 2
    _part(game, crate, "Egg crate tray", Vector3(0, .03, 0), Vector3(.96, .06, .38), Color("c9a679"))
    for sz in [-1, 1]:
        _part(game, crate, "Egg crate rail", Vector3(0, .075, sz * .19), Vector3(.94, .08, .02), COOP_WOOD)
    for sx in [-1, 1]:
        _part(game, crate, "Egg crate end", Vector3(sx * .48, .075, 0), Vector3(.02, .09, .4), COOP_WOOD)
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
    # The sign over the crate: a cream board with a big egg and a small crate (no words).
    var sign := _node(house, "Egg sign", Vector3(ROOMY_COOP.x - w2 - .05, 2.3, ROOMY_CRATE_TABLE.z))
    _part(game, sign, "Egg sign rim", Vector3(-.005, 0, 0), Vector3(.04, .98, 1.18), COOP_WOOD)
    _part(game, sign, "Egg sign board", Vector3(-.03, 0, 0), Vector3(.03, .9, 1.1), COOP_CREAM)
    var big: Node3D = game.cylinder("Egg sign egg", Vector3.ZERO, .2, .03, Color("fbf6ea"))
    big.reparent(sign, false)
    big.position = Vector3(-.06, .1, 0)
    big.basis = Basis.from_scale(Vector3(1.0, 1.3, 1.0)) * Basis(Vector3.BACK, PI / 2)
    _part(game, sign, "Egg sign crate", Vector3(-.06, -.28, 0), Vector3(.03, .14, .56), Color("c9a679"))
    _part(game, sign, "Egg sign arrow", Vector3(-.055, -.12, 0), Vector3(.02, .1, .06), COOP_RED)

## More birds round the hen house (user, 25 Nov 2026: "place few chicken and chick around the hen
## house, have them move naturally"): two more clay hens (copies of Hen 1, word "hen"), the clay
## rooster (rooster_clay.tscn, 1.2 times a hen's height) and five clay chicks (chick_clay.tscn,
## 0.55 times a hen's height), all under `Hen house/Hens`, so hen_house.gd gives them the hen yard.
## The rooster and chicks have no word (no picking area); their `wander_profile` meta names their
## park_animals.gd profile. Three chicks follow Hen 1 and two follow Hen 4 (meta "follow"): their
## home moves to their hen whenever they choose where to go. Movement: park_animals.gd GAITS.
const FLOCK_HENS := [Vector2(74.4, 80.6), Vector2(80.4, 80.7)]
const FLOCK_ROOSTER := Vector2(78.0, 75.6)
const FLOCK_CHICKS := [[Vector2(75.3, 80.2), "Hen 1"], [Vector2(76.7, 80.3), "Hen 1"], [Vector2(76.5, 78.7), "Hen 1"],
    [Vector2(74.6, 77.6), "Hen 4"], [Vector2(76.1, 76.4), "Hen 4"]]
const ROOSTER_SIZE := 1.2
const CHICK_SIZE := .55

func hen_house_flock(town: Node3D, _game) -> void:
    var hens: Node3D = town.get_node("Barn/Hen house/Hens")
    var first: Node3D = hens.get_node("Hen 1")
    var bounds: AABB = first.call("_visible_bounds")
    var hen_size: float = first.transform.basis.get_scale().x
    var hen_h: float = bounds.size.y * hen_size
    for i in FLOCK_HENS.size():
        var hen: Node3D = first.duplicate()
        hen.name = "Hen %d" % (hens.get_child_count() + 1)
        hen.transform = Transform3D(Basis(Vector3.UP, 1.1 + i * 2.7).scaled(Vector3.ONE * hen_size), Vector3(FLOCK_HENS[i].x, LAWN - bounds.position.y * hen_size, FLOCK_HENS[i].y))
        hens.add_child(hen)
        for node in [hen] + hen.find_children("*", "", true, false):
            node.owner = town
    _flock_bird(town, hens, "Rooster", "rooster", hen_h * ROOSTER_SIZE, FLOCK_ROOSTER, 2.2, "")
    for i in FLOCK_CHICKS.size():
        _flock_bird(town, hens, "Chick %d" % (i + 1), "chick", hen_h * CHICK_SIZE, FLOCK_CHICKS[i][0], i * 1.9, FLOCK_CHICKS[i][1])
    print("HEN HOUSE FLOCK: %d birds, hen %.3f tall" % [hens.get_child_count(), hen_h])

## One wandering clay bird without a word under `hens` (house frame = town coordinates): the
## clay model turned half round (it faces -Z, wanderers +Z), its Footprint body off, `height`
## tall, soles on the lawn, stored as plain nodes (the web export leaves the clay prefabs out).
func _flock_bird(town: Node3D, hens: Node3D, title: String, prefab: String, height: float, at: Vector2, yaw: float, follow: String) -> void:
    var bird := Node3D.new()
    bird.name = title
    bird.set_script(preload("res://scripts/world/park_animals.gd"))
    bird.set_meta("wander_profile", prefab)
    if follow != "":
        bird.set_meta("follow", follow)
    var model: Node3D = load("res://scenes/animals/%s_clay.tscn" % prefab).instantiate()
    model.name = "Clay" + prefab.capitalize()
    model.rotation.y = PI
    var footprint := model.get_node("Footprint") as CollisionObject3D
    footprint.collision_layer = 0
    footprint.collision_mask = 0
    bird.add_child(model)
    hens.add_child(bird)
    var box: AABB = bird.call("_visible_bounds")
    var size := height / box.size.y
    bird.transform = Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * size), Vector3(at.x, LAWN - box.position.y * size, at.y))
    model.scene_file_path = ""
    for node in [bird] + bird.find_children("*", "", true, false):
        node.owner = town
    print("hen house flock: %s %.3f tall at %s" % [title, box.size.y * size, bird.position])

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


## Colours snapped to the game palette with the hue guard (P3-22, decision D14: approved by the
## user 26 Nov 2026 after the library/police trial; scripts/buildings/palette_snap.gd,
## docs/evidence/pastel-20261125/).
func palette_snap(town: Node3D, _game) -> void:
    preload("res://scripts/buildings/palette_snap.gd").snap(town, "barn")
