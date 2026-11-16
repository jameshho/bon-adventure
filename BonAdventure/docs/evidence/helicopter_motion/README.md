# Helicopter rotor and flight-attitude upgrade

Historical implementation. The 22 October rotor-physics rewrite supersedes the
velocity/attitude model and its acceptance tests below. See the
[current physics guide and checks](../../guides/helicopter_inertia/README.md).

The original hospital helicopter now has animated main and tail rotors, gradual spool-up after boarding, and a roughly four-second coast-down after landing and exiting. A faint transparent rotor disk makes high-speed motion legible. Rotors continue running during an airborne UI pause.

W/S produces smooth forward/reverse pitch; A/D banks into turns. Forward braking raises the nose, then the aircraft settles to a level hover. Maximum pitch is 20 degrees and maximum bank is 24 degrees, with damped transitions. The existing horizontal acceleration and independent Space/Ctrl lift controls remain. The aircraft levels near a landing surface, and the camera retains a level horizon.

This is physical aircraft tilt: the existing meshes, solid bodies, main-rotor swept disk and new tail-rotor swept disk rotate together. Small collision-checked orientation steps prevent banking through nearby solids. Existing vocabulary, boarding, landing and blocked/unsafe-exit behavior are retained.

Controls: **E** board/exit when landed; **W/S** pitch and accelerate; **A/D** bank and turn; **Space/Ctrl** rise/descend; release movement controls to brake into hover. The F1 help has been updated.

## Verification

- Graphical Godot 4.7.2 launch of the actual main scene, with a captured banked flight and both rotors animating.
- 21 focused checks cover rotor startup/axes/blur/shutdown, forward/reverse pitch, left/right bank and heading, braking, level hover, altitude stability, tilted collision volumes, tail-rotor protection and leveling/landing from a banked approach.
- The existing 41-check main-scene regression suite passed, including vocabulary coverage, helicopter rotor/overhead collisions, safe landing, boarding and exiting.
- `test_results.txt` contains the focused results; `flight_preview.gif` is a short capture of the running Godot flight animation.

Changed existing files: `scripts/world/driveable_vehicle.gd` and `scripts/ui/vocabulary_hud.gd`. Their pre-change versions are saved in `backups/helicopter_motion_20261018/`. Vocabulary, scene files and saved progress were not changed.

Re-run with `godot --headless --path . --script docs/evidence/helicopter_motion/verify.gd`. Omit `--headless` to capture the graphical demonstration; keep its window visible so macOS continues rendering frames.
