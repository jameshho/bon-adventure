# House lighting, pig placements, and Godot fixes

> Historical implementation record. Use the [documentation map](../../README.md)
> for current guides; positions, counts and test results below describe this snapshot.

- Giant Soft Plush pig: moved from town z=-81 to -45, one 36-unit block behind the house rear wall; retains its eight-house height. Shortened and rerouted the meadow approach to meet its new position. Updated rear-area name threshold.
- Supermarket pig: (-33, 0.04, 49.9), at the far end before the chilled cabinets.
- Library pig: (-15, 0.04, 49.1), at the far end before the borrowing desk.
- House ceiling lights: energy 0.8 to 0.32 (60% lower), warmer color. Other buildings retain their lighting settings.
- Driver parse fix: seven transforms used nested Vector3 constructors, which are invalid in serialized TSCN Transform3D values. Flattened them into Godot's twelve-number format, preserving all basis and origin values.
- Explicitly listed the inherited giant StudyArea parent so the project reference checker recognizes the inherited selection-shape override.

Verification: all 50 scene/script resources loaded and scenes instantiated; project references pass; seven house routes and four doors pass; eight public-interior routes pass; all six normal pigs clear of visible geometry and selectable; giant bounds, ground contact and approach selection pass. GUI game render reports no project errors. The headless macOS process emits a system certificate-store warning independently of project files.

Backups are in `backups/home_lighting_pig_fixes_before/`. Preview PNGs show the final game state.
