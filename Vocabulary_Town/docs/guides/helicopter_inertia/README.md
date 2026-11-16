# Helicopter rotor physics

Since 14 November 2026 the helicopter starts in [easy flying](../aircraft.md#easy-flying)
(the hover assist whenever the stick is centred; C switches to the controls below).

Current implementation: **22 October 2026**. The helicopter now integrates main
rotor blade forces, tail rotor force/torque, gravity, air drag, wind-relative flow
and body angular inertia. It replaces the old target-velocity/forced-attitude
flight routine. The hospital helicopter, its model, scene overrides, vocabulary,
boarding, camera, safe exits and learner save format retain their existing owners.

## Controls and behavior

**E** boards. Allow about 2.3 seconds for the rotor governor to reach operating
speed. **W/S** commands forward/reverse cyclic; **A/D** commands bank and coordinated
tail-rotor turning. **Space/Shift** requests climb/descent, with collective assistance
adjusting blade pitch. **Hold R** to brake into a hover; this cancels ground-relative
drift, including wind and anti-torque side-force. A slight hover bank can be normal
because the main rotor must counter the tail rotor's lateral force. Release to
coast. Land and stop, then **E** exits (since 14 Nov 2026 **E** also works in the air:
see below). The HUD shows physical rotor speed and
collective pitch; visual rotor speed follows the simulation rather than frame rate.

The landing assist eases cyclic toward level near a surface during descent. Three
wheel probes determine support; stationary ground braking prevents sliding while
spooling. Rotors coast down after a grounded exit. Blocking overlays suspend flight
without deleting momentum, following Main's existing occupied/input-block contract.

**Exit in flight, crashes and resets — 14 November 2026** (user). **E** in the air or while
moving lets BonBon out 7 m to the side, clear of the 5.3 m rotor disk, with no door sequence; she
falls to the ground (there is no fall damage). The helicopter flies on with no input and the
rotor spinning down (`coasting`), so it comes down autorotating or crashes; once landed with the
rotor stopped it is parked again and its physics stops. Hitting something, or touching down,
faster than `HELI_CRASH_SPEED` (10 m/s; holding "down" in easy flying lands at about 7 m/s) is
a crash: the status line shows `vehicle.status_heli_crash` and 2.5 s later
(`EASY_RECOVER`) it is back on its pad, the pilot still aboard if there was one. Left
unoccupied more than 300 m from the player it also goes back to its pad. Owners and checks:
[road vehicles, 14 Nov](../ZOO_VEHICLE_IMPLEMENTATION.md#arcade-collisions-exit-while-moving-and-resets--14-november-2026).

## Ownership, dimensions and source

- `scripts/world/helicopter_physics.gd`: force/torque solver and flight assistance.
  `DriveableVehicle::flight_step()` delegates to it. Physical time is integrated
  in steps no longer than 1/120 second, consuming up to 0.25 seconds per call.
- Main rotor: four blades, eight azimuth samples per revolution and four radial
  sections per blade; the azimuth average avoids timestep/rotor-phase aliasing.
  Dynamic pressure and blade angle of attack determine thrust and drag; cyclic
  changes differential blade loading, which generates pitch/roll moments.
- Tail rotor: relative side-flow, blade speed, pitch, lateral force and yaw moment.
  Automatic anti-torque trim cancels shaft reaction; pilot turning adds yaw demand.
  Quaternion attitude feedback requests cyclic moments, with body angular inertia
  and gyroscopic coupling integrated explicitly. Motion is caused by forces,
  rather than assigning horizontal velocity or forcing the visible body pose.
- Physics uses world metres/seconds. The 4.05 model-unit main radius and .83 tail
  radius become 5.265/1.079 world units under Apartment's 1.3 scale. Effective mass
  is 1,800 kg, body inertia is (14,000, 16,000, 9,000) kg m², and governed rotor speed
  is 36 rad/s (344 RPM). These are town-scale tuning values, not Black Hawk specs.
  Existing exported pitch/bank limits, attitude response, steering rate, climb
  speed, drag and wind settings remain active; shared `top_speed` controls road
  vehicles, while helicopter speed follows tilt, thrust and drag.
- `driveable_vehicle.gd`: shared swept queries, safe exits and rotor animation.
  Body hulls follow physical model parts; both rotor disks use circumscribed
  24-sided convex shapes. Each shape encloses the full rotor circle at every
  animation phase. Translation checks include tiny-motion destination overlap;
  attitude changes are checked against the full aircraft envelope. No scene bake
  or collision-shape edits to the saved world are required.

The rotor blade force/moment summation and tail-rotor algorithm adapt
[`VehicleRotor3D`](https://github.com/wmigor/godot-aircraft-plugin/blob/395a707dd81edd6530be8e89f3c1a177164289d6/addons/aircraft/scripts/vehicle_rotor_3d.gd)
and the pressure/force projection from
[`VehicleWing3D`](https://github.com/wmigor/godot-aircraft-plugin/blob/395a707dd81edd6530be8e89f3c1a177164289d6/addons/aircraft/scripts/vehicle_wing_3d.gd),
by Igor Akulov, pinned to commit `395a707dd81edd6530be8e89f3c1a177164289d6`.
The original [MIT license](../licenses/godot-aircraft-plugin-LICENSE.txt) is retained.
This is an adaptation to the existing Node3D vehicle/swept-collision contract;
the upstream addon, demo assets and VehicleBody3D hierarchy are not imported.
Local additions include revolution averaging, induced-flow approximation,
governor, trim/hover assistance and body integration.

This remains an assisted game flight model: no full blade flapping, vortex-ring
state, autorotation, fuel, damage, weather turbulence or collision impulse solver.
Contact clips blocked velocity components and prevents penetration. Test release
builds and manual flight circuits before treating this as a simulator.

## Current verification

Use the [README's isolated test configuration](../../../README.md#verification):

```
godot --headless --path . --fixed-fps 60 --script res://docs/evidence/town-checks/check_helicopter_physics.gd
godot --headless --path . --fixed-fps 60 --script res://docs/evidence/town-checks/check_zoo_vehicles.gd
godot --path . --resolution 1400x1000 --script res://docs/guides/helicopter_inertia/render_physics.gd
```

The visual script flies the real hospital helicopter through takeoff, bank, hover,
landing and exit; it overwrites only `rotor-*.png` in this directory. Current results
are recorded in [Final verification](../FINAL_VERIFICATION.md#helicopter-physics-rewrite--22-october-2026).
The earlier `verify.gd` and `../helicopter_motion/verify.gd` encode the superseded
velocity/animation-driven model and are retained as historical evidence. They are
not the current acceptance checks. Their old captures/results remain untouched.

[Hospital takeoff](rotor-takeoff.png) · [Banked flight](rotor-banked.png) ·
[Landed on hospital](rotor-landing.png)

## Historical inertia implementation — superseded 22 October 2026

Implemented plan: preserve horizontal momentum after releasing cyclic, add gentle smooth wind, ease yaw response, provide deliberate hover assistance, and keep the aircraft stable on its wheels. Altitude remains assisted: this is approachable helicopter handling rather than a full aerodynamic simulation.

W/S pitches and accelerates. Release to coast; momentum decays with an approximately 1.8-second half-life. Wind gently changes horizontal drift over time, without random frame-to-frame kicks. A/D banks and turns with a short yaw acceleration/deceleration delay. Hold R to actively damp horizontal motion and cancel wind; it brakes to a steady hover rather than returning to an earlier position. Space/Ctrl still controls climb/descent. Main wheels stay planted when landed until positive lift is requested. Hold R while descending for a precise landing, then E to exit. Help and boarding instructions describe the new controls.

All motion, including wind, uses the existing full-aircraft swept collisions. Added destination-overlap checks and a small impact separation to stop very slow gust motion from bypassing the physics sweep tolerance. Original rotor animations, Black Hawk-inspired model, vocabulary and saved progress are retained.

Backups: backups/helicopter_inertia_20261018 contains the previous controller, HUD, main script and both adjusted regression suites. Existing stable-hover tests now explicitly hold the pilot assist, reflecting the changed hands-off behavior; their collision/landing checks remain.

Validation: 15 new checks cover wind, altitude stability, assist/release, coasting, reverse braking, yaw easing/settling, 30 versus 120 Hz consistency, sustained wind against a rotor-height wall, parked stability, safe exit and takeoff. The existing 21 motion checks and 41 town checks also pass, with 501/501 vocabulary coverage. Graphical testing loads the actual main scene; flight.png captures the final flight demonstration. Tests disable learning callbacks so they do not record learner progress.

Run: godot --headless --path . --script docs/guides/helicopter_inertia/verify.gd
Omit --headless for graphical validation and capture.
