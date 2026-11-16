> Stair geometry and exterior screenshots superseded by [the repair audit](hospital-repair-audit.md).

# Hospital remodel — implementation and review

Implemented directly in:
`/Users/james/Documents/Codex/Spanish World/Vocabulary_Town_v27`

The first floor now has reception (Room 1) at bottom left, emergency care (Room 2)
at top left, examination (Room 3) at top right, and waiting at bottom right, with
the front entrance at bottom center. Stairs occupy the middle-left bay; the
three-floor elevator occupies the middle-right bay, facing the entrance.

Floors 2 and 3 follow the documented patient/ICU/operating and
imaging/laboratory/therapy/office programs. The compact switchback incline is 30.26°;
its core uses 63 square town units instead of the former 98. Continuous ramp
collision lets the existing player walk both directions without jumping.

The elevator has moving cabin and landing doors, physical floor buttons, hall calls,
three stops and obstruction recovery. Click buttons or use **1 / 2 / 3** inside;
press **E** at a landing to call it. The existing player rides using Godot moving
platform collision. No external runtime package was installed.

## Screenshots

These are actual Godot Main renders, with annotated inspection cutaways for the
floor plans. Upper floors, roofs and facade are hidden only for the captures.

- [Floor 1](floor1.png)
- [Floor 2](floor2.png)
- [Floor 3](floor3.png)
- [Entrance](entrance.png)
- [Compact stairs](stairs.png)
- [Elevator cabin and buttons](elevator.png)

## Documentation conflicts resolved or retained

The older hospital guide's pediatrics/cardiology department arrangement conflicts
with the newer approved program; the new program and this request take precedence.
The newer brief did not number Rooms 1–3. The implemented numbering follows its
listed order: reception, emergency, examination. This interpretation is documented.

Rear-wing removal was not authorized, so the wing and all 24 learning displays
remain. The original side-annex envelope also remains; its gallery holds the old
medical display cluster moved out of the new elevator shaft. Hospital dimensions,
site placement, bed asset, helicopter/helipad, vocabulary data and learner-save
identity are preserved.

## Source and license

Adapted from [Yni-Viar/advanced-elevator-system](https://github.com/Yni-Viar/advanced-elevator-system),
a Godot 4 implementation, at commit `273438265a4879f9d78759d8db1d5dd8ee24e367`.
Its MIT license permits this modification and distribution without requiring the
rest of the game to be relicensed. The full copyright/license notice is retained
in the project's `docs/guides/licenses/advanced-elevator-system-LICENSE.txt`.
The adaptation uses its floor-target movement and close/move/open sequence with
project-specific collision, controls, doors and obstruction handling.

## Verification

Godot 4.7.2 / GL Compatibility, using an isolated copy to protect learner saves:

- Hospital routes/elevator: **717 assertions, zero failures**. Includes real player
  traversal through every main-floor room, both stair storeys, all galleries and
  rear access; rides/exits on all floors; mouse button, keyboard and hall calls;
  obstruction recovery and absent-cabin landing doors.
- Retained learning wing: **24 displays**, all targeting/cards/passages pass.
- Runtime resources: **310 loaded, zero failures**.
- Existing interaction checks: **pass**.
- Helicopter physics: **34 checks, zero failures**.
- All retained saved-world node/resource blocks are byte-identical to the original;
  only obsolete hospital override blocks/editable paths were removed.
- All three floor cutaways and entrance/stair/elevator renders were inspected.

The assertion count includes repeated checks that doors stay closed during motion.
This is targeted validation, not a full-project or performance certification.
Existing unrelated metadata/vehicle issues were not changed.

## Project files and reproducibility

Authoring: `tools/build_hospital_remodel.py`, invoked by the existing
`tools/build_hospital_floors.py` (school branch preserved). Generated scene:
`scenes/buildings/hospital.tscn`. Elevator: `scripts/world/hospital_elevator.gd`.
Saved hospital override cleanup: `scenes/world/town_public_garden.tscn`.
Preserved-display relocation: `world_refinements.gd::remodel_hospital_displays()`.
Floor HUD labels: `reference_world_layout.gd` and Main's fallback labels.

Updated guides: project README, documentation map, master design brief,
`HOSPITAL_THREE_FLOORS.md`, architecture ownership guide and final verification.
The hospital guide includes coordinate floor plans, staircase dimensions/headroom,
elevator mechanics, pinned source attribution, regeneration boundaries and commands.

Run the new focused checks using the README's isolated-save configuration:

```sh
godot --headless --path . --fixed-fps 60 --script res://docs/evidence/town-checks/check_hospital_remodel.gd
godot --headless --path . --fixed-fps 60 --script res://docs/check_hospital_learning.gd
godot --path . --resolution 1440x1100 --script res://docs/evidence/town-checks/check_hospital_remodel.gd -- --capture --capture-only
```
