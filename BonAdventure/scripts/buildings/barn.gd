extends RefCounted
## Farm barn own script (docs/guides/MODULAR_TOWN.md, "Changing a building"); the barn is saved in
## scenes/town/barn.scn. Design (1 Nov 2026, docs/guides/TOWN_DESIGN_BRIEF.md farm barn record):
## gambrel roof, open X-braced double doors, a walkable hayloft reached by a climbable ladder;
## 12 x 9 foundation. Barn frame: town units (Apartment scale 1.3 applies), door on local -Z,
## walls centred on x +-6 and z +-4.5. The constants were moved here from the deleted startup
## pass barn_interior.gd (6 Nov 2026); docs/evidence/barn-20261101/verify.gd uses them.
const STEPS := ["coplanar_gaps", "coplanar_gaps_2", "glass_windows"]

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
