# Road, police car, school and hospital update

**Hospital extension removed — 27 October 2026:** the hospital's rear extension and its four rooms no longer exist; their displays are in the main hospital rooms ([hospital guide](../guides/HOSPITAL_THREE_FLOORS.md)). The school's extension is unchanged.

**Design supersession — 25 October 2026:** The old school specialist-room and hospital learning-wing designs below are superseded by the 25 October programs. These records describe existing assets and past checks, not instructions to rebuild or permanently retain the old programs. See the [current town brief](../guides/TOWN_DESIGN_BRIEF.md).

> Historical implementation record. Use the [documentation map](../README.md)
> for current guides; positions, counts and test results below describe this snapshot.

The active game remains `scenes/main.tscn`; the saved level remains `scenes/world/town_complete.tscn`.

## Repairs

- The road in front of the clothing store contained folded ribbon triangles at tight Bezier corners. Replaced the road loop with straight sections and constant-radius 12m corners, wider than the road and sidewalk half-widths. Both surfaces now have consistent triangle winding and no folded corner cells.
- The police car's CSG body and cabin extruded toward negative Z from already negative offsets, pushing large slabs outside the wheel track. Centered both parts and baked them to ordinary mesh resources. The car retains its wheels, markings, lights, collision and vocabulary target.

## Expanded buildings

Both buildings retain their existing interiors and entrances. Each has a connected 24m rear wing, a clear central corridor, four open classroom/clinical doorways, and six individually editable learning displays per new room.

| Building | New rooms |
| --- | --- |
| School | Science lab; art studio; music room; geography and reading |
| Hospital | Emergency; examination; imaging; rehabilitation |

School displays include microscopes, laboratory glassware, an easel, painting tools, musical instruments, a globe, map and compass. Hospital displays include a stretcher, defibrillator, oxygen tank, syringe, examination bed, diagnostic instruments, X-ray equipment, MRI scanner and mobility aids.

48 new placed displays reuse existing props and 36 newly authored prefabs. All use the existing hover, click-to-study and Spanish popup system. The map reflects the larger footprints. Eight new discovery missions guide players to the themed rooms. Background trees and a hill have been moved clear of the extensions.

## Editing and regeneration

- Open `scenes/buildings/school_learning_wing.tscn` or `hospital_learning_wing.tscn` to edit their corridors and room placement.
- Open scenes in `scenes/buildings/rooms/` to rearrange an individual room.
- Vocabulary assets remain in `scenes/props/vocabulary/`.
- `tools/expand_civic_wings.py` authors the new props and room layouts. Running it overwrites its generated files.
- After intentional source changes, run `godot --headless --path . --script res://tools/bake_editable_town.gd` to refresh the complete level. This replaces manual edits made only to the complete snapshot.

## Verification

`docs/evidence/town-checks/check_civic_expansion.gd` checks road triangle winding, police body/cabin bounds, continuous routes from both original entrances through the extensions, all eight room doorways, all 48 placed learning targets and their popup translations. It passes with zero failures.

The existing interaction, shop, town-layout, house and public-interior checks also pass. The full asset check now loads and ray-tests 147 reusable vocabulary prefabs. Rendered review images are saved in `docs/evidence/civic-review/`.
