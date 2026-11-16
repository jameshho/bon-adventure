# Editor import repair

> Historical implementation record. Use the [documentation map](../../README.md)
> for current guides; positions, counts and test results below describe this snapshot.

Added `backups/.gdignore` so archived scripts and resources cannot register duplicate global classes or resource identities. All backup contents remain intact.

Removed the copied UID from `scenes/props/vehicles/truck 2.tscn`; the canonical truck keeps its original UID. Both scenes are preserved. The old copy is backed up at `backups/editor_import_fix_20261018/scenes/props/vehicles/truck 2.tscn`.

Validation: Godot 4.7.2 graphical editor startup completed with no warnings or errors; global script cache points DriveableVehicle to scripts/world/driveable_vehicle.gd. Helicopter main-scene regression: 21 checks, zero failures. `verify.py` checks backup exclusion, unique scene/resource UIDs and global classes, and the canonical vehicle class path.

If an already-open editor retains the old error messages, reopen the project and clear the previous output. Saved learner progress and vocabulary were not edited by this repair.
