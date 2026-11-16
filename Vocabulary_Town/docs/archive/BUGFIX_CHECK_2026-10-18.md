# Runtime bug check — October 18, 2026

> Historical implementation record. Use the [documentation map](../README.md)
> for current guides; positions, counts and test results below describe this snapshot.

Checked the local project with Godot 4.7.2, using its headless engine.

## Fixed

- The vehicle obstacle probe inferred a Vector3 from an untyped loop value. This
  caused a GDScript parse error and prevented the main game script from compiling.
  The probe now declares its Vector3 type explicitly.
- Thirty vocabulary scenes contained 124 string-based Color constructors, which
  are valid in GDScript but invalid in serialized scene files. Converted them to
  numeric RGBA values, preserving the colors. This restores food, shopping,
  transportation, navigation, and time props that failed to load.
- Station and ticket collision sizes used leading decimal points unsupported by
  the scene parser. Added the required zeroes.
- Vehicle D/A steering turned in the opposite direction. Corrected steering for
  both road vehicles and the helicopter, including reverse steering.
- Noclip could restore BonBon's collisions while she was seated inside a vehicle.
  Noclip changes are now ignored while seated.
- Hyper effects were disabled on boarding but never restored on exit. They now
  resume when hyper mode is active; toggling H while seated keeps the effects hidden.
- Vehicle Space input no longer queues an on-foot jump while flying.

## Verification

- All 552 active scene and script resources load and compile.
- Zoo and vehicles: 67 checks, zero failures, including steering and seated states.
- Vehicle collision: all eight road vehicle types block the player from four
  directions, allow walking around, and remain selectable in the saved town.
- Rooftops and jumping: 258 checks, zero failures.
- Interaction, BonBon movement, and BonBon UI checks pass.
- All 13 food/shopping and 16 travel/navigation/time targets pass real physics ray
  picking and vocabulary popup checks.

The older food and travel tests were updated to expect the current 500-word
dictionary. Their test cameras are detached from the live SpringArm3D, which was
overwriting their deliberate camera positions during physics frames. A new
`check_runtime_resources.gd` checks every scene and gameplay script, since passing
gameplay assertions alone previously missed scene loading errors.

Godot emits a macOS system certificate warning in this sandbox. These checks do
not establish rendered visual quality or replace a manual keyboard/mouse playtest.
The older Python project checker also reports existing dynamic screenshot-path
flags and load_steps discrepancies in the editable town scenes and their duplicates.

Original changed gameplay files are saved outside the project in
`../backups/before-runtime-bugfixes-2026-10-18.zip`. The original full project ZIP
is unchanged. The repaired project remains in the existing folder.
