# The small plane

Added 21 October 2026. Restart Main and walk to the airport runway. The blue/ivory
high-wing plane is parked near its southern threshold, pointing down the
existing runway. Approach the left cabin step and press **E**. BonBon visibly climbs
the step over 2.4 seconds, the door swings, and she stays visible in the pilot seat.

Since 23 November 2026 (user) both aircraft have [one set of flying controls](#flying-controls)
on every device, and the plane is a [smaller, slower plane with a new, steady flight
model](#flight-model): the old one wobbled up and down by itself and its nose tilt was
inconsistent. The expert controls (throttle, pitch, rudder, flaps and brakes on raw keys, C to
switch) and the aerodynamic model were removed then.

The HUD status line shows airspeed in knots, height above the starting runway in metres and
ground / airborne. It is not an AGL terrain radar. F1 includes the flying controls.

## Flying controls

User request, 23 November 2026: one simple, consistent control for all devices, with ascend and
descend buttons (replacing easy flying of 14 November and the C expert mode). The same inputs
fly the turboprop and the helicopter, through InputMap actions, so a keyboard, a mouse and a
touch screen all work:

| | Keyboard | On screen | Plane | Helicopter |
| --- | --- | --- | --- | --- |
| Up | Space | **▲** (jump slot, bottom right) | climb (4 m/s); on the runway: take off | rise |
| Down | Shift or Ctrl | **▼** (left of ▲) | descend (3 m/s), slows and lands gently | sink |
| Forward / back | W / S | stick | faster (22 m/s) / slower (12 m/s) than cruise (17 m/s); on the runway W takes off and S brakes | fly forward / back |
| Turn | A / D | stick | up to 0.5 rad/s, banking up to 26° (less near the ground) | turn |
| Let go | | | hold the height, fly level, wings level | brake to a hover |
| Reset | (R after a crash) | red **Reset** above ▼ | back on the runway | back on its pad |
| Get out | E | E | also in flight | also in flight |

- **▲ / ▼** (`touch_controls.gd` `ascend_button` / `descend_button`) are real HUD Buttons shown
  whenever the player flies either aircraft, with a mouse as well as on a touch screen; held,
  they hold the `jump` / `descend` actions. On a touch screen they take the places of the jump
  button and the old touch-only ▼. Both aircraft read them through
  `DriveableVehicle.ascend_input()`.
- **Plane:** `turboprop.gd` `fly_step(delta, up, turn, stick)`; see [flight model](#flight-model).
- **Helicopter:** the existing physics with the hover assist whenever the stick is centred.
- A crash returns either aircraft to its start after 2.5 s (or at once with R / Reset).

Check: `docs/evidence/town-checks/check_easy_flying.gd` (run_checks id `easy_flying`): the ▲ / ▼
Buttons show in both aircraft (and not on foot) and hold up / down; holding up while boarding
does not move the plane, take-off and climb on up alone, level hold, faster / slower on the
stick at the same height, a right turn, wings levelling, a descent and landing on down alone,
crash recovery, a take-off on the stick alone (levels off about 15 m up), and the helicopter
braking to a hover. Rendered views
(`docs/evidence/flying-controls-20261123/capture.gd`):
[helicopter, mouse](../evidence/flying-controls-20261123/helicopter-mouse.png),
[helicopter, touch](../evidence/flying-controls-20261123/helicopter-touch.png),
[plane on the runway](../evidence/flying-controls-20261123/turboprop-touch.png),
[F1 guide](../evidence/flying-controls-20261123/help.png).

## Exit in flight, resets and the map edge

User request, 14 November 2026 (code: `driveable_vehicle.gd`, `turboprop.gd`,
`vehicle_controls.gd`; check `docs/evidence/town-checks/check_vehicle_arcade.gd`, run_checks id `vehicle_arcade`).

- **Exit at any speed.** E in the air, rolling or crashed lets BonBon out 6.8 m to the side of
  the plane (`moving_exit_offset()`, clear of the 5.7 m half span), with no door sequence; in the air she falls to the
  ground (no fall damage). The plane glides on unpowered with the controls released (engine off,
  `coasting`) until it rests on the ground, then it is parked again and its physics stops. A
  stopped plane on the ground still plays the door and climb-out sequence.
- **Resets.** `reset_to_start()` (shared with the helicopter) puts the plane back where it
  was parked, stopped, with the pilot still in the cockpit if aboard; the red HUD **Reset**
  button calls `main.active_vehicle.reset_to_start()`. It happens by itself after a crash
  (`EASY_RECOVER` 2.5 s; R still recovers at once), when the
  plane is left unoccupied more than 300 m from the player (checked four times a second by
  `vehicle_controls.gd` `update_aircraft()`), and at the map edge below.
- **Map edge.** The playable area is the town's `reference_map_bounds` (the full map's frame,
  town units) grown by `MAP_MARGIN` 150 m. Past it the HUD flashes `vehicle.map_edge` (again
  every 6 s while outside) and the plane steers itself: it banks toward the centre of
  the map and turns back, a gentle turn rather than a wall (up/down and the speed stick still
  work). `MAP_RESET_MARGIN` (400 m) further out,
  or unoccupied past the edge, the plane resets to the runway, so it cannot be lost. In the
  check (23 Nov 2026), a plane flying straight out at cruise speed, 40 m past the edge, turned
  back with its widest point about 80 m past the edge (300 m with the old, faster plane). The older 2,500 m crash limit stays as a last resort.

## Flight model

Rewritten 23 November 2026 (user: "the plane feels unnatural, its up and down tilt is not
consistent, and keeps wobbling up and down even when I'm not pressing any button"; "make it a
smaller slower plane"). Code: `scripts/world/turboprop.gd` (`fly_step()` and the constants at
the top).

- **Arcade, not aerodynamics.** The controls set a target speed, climb rate and turn rate; each
  eases toward its target at a steady rate (first order, so nothing overshoots, bounces or
  bobs). The plane travels along its heading at `airspeed` and climbs at `flight_velocity.y`.
  The nose pitch is the climb angle (plus a small 0.04 rad nose-up) and the bank follows the
  turn rate; both only show the motion and never steer it, so the tilt always means the same
  thing. Let go and it flies level at exactly the current height.
- **Speeds** (m/s): cruise 17, fast 22, slow 12, approach 14 (12 below 10 m), lift-off 11;
  climb 4, sink 3. Speeding up 3 m/s², slowing 2 m/s², braking 4 m/s². Take-off takes about
  20 m of the roughly 115 m runway; a landing on ▼ from 6 m touches down at about 0.5 m/s and
  stops within about 80 m.
- **Near the ground** the sink eases off (0.5 m/s + 0.25 × height) and the bank is limited, so
  holding ▼ lands gently on anything flat. Touching down faster than 4.5 m/s or banked more than
  0.35 rad, or hitting something above 5 m/s, is a crash (back on the runway after 2.5 s).
- **Nobody aboard** (exit in flight): it glides down at about 2.4 m/s at slow speed until it
  rests, then is parked again.
- **Size.** The saved model is shown at `SIZE` 0.65 (scaled about the wheels in `_ready()`, so
  no re-bake): a span of about 11.5 m. BonBon sits in it at the same scale
  (`boarding_seat_scale()`), and the chase camera is closer (16 m, `player_controller.gd`).

## View from the air

Since 23 November 2026 (user: the town vanished in the fog when flying high) the view distance
grows with the aircraft's height above the town, from the game's 130 m to at most 330 m, and the
plane's chase view tilts down as it climbs so the town stays below it. There is no height limit:
above about 250 m the town fades into a pale haze floor. Leaving the aircraft or landing eases
the view back to 130 m. Owner: `vehicle_controls.gd` `update_flight_view()`; numbers, cost and
pictures in [one graphics setting and the flight view](performance/README.md#one-graphics-setting-and-the-flight-view--23-november-2026).

## Ownership

- `scenes/props/vehicles/turboprop.tscn` owns the airplane vocabulary root; the town scene saves
  its primitive parts (made once by `build_model()` with Main's material/geometry helpers) and
  the exported part references.
- `scripts/world/turboprop.gd` extends the existing `DriveableVehicle` contract.
  Main still owns E boarding and input blocking; existing swept body queries
  (`flight_fraction()`, `can_rotate()`) check the fuselage, full wings, tail and propeller
  disk. The wheels follow the ground under a simple ray (`support()`), not wheel suspension.
- The propeller, ailerons, elevator, rudder, flaps, wheels and boarding door animate from the
  controls (they show the input; they do not drive the motion).
  `player_controller.gd` uses BonBon's existing arm/foot nodes for boarding and
  seating; it restores walking transforms and collision on exit. Since 29 Oct the
  sequence is the shared `animate_boarding()`/`advance_boarding()` also used by
  cars ([road vehicles](ZOO_VEHICLE_IMPLEMENTATION.md)); the plane keeps its
  2.4 s duration, visible pilot and instant exit.
- E is blocked while boarding or without a clear exit (before 14 Nov 2026 also while
  airborne or moving: [now allowed](#exit-in-flight-resets-and-the-map-edge)). Below-world travel
  or exceeding a 2,500-world-unit radius also counts as a crash. No damage persistence, fuel,
  wind, engine sound or cockpit camera. Other vehicles retain their own controllers.
- Opening a blocking overlay pauses the plane. Leaving the plane shuts the engine off. The
  aircraft is not saved between runs. Existing learner save identity/format is unchanged.

## Earlier flight model and license

From 21 October to 23 November 2026 the plane flew on a lift / drag / thrust model whose force
directions and dynamic pressure adapted
[`VehicleWing3D::_calculate_section_forces`](https://github.com/wmigor/godot-aircraft-plugin/blob/395a707dd81edd6530be8e89f3c1a177164289d6/addons/aircraft/scripts/vehicle_wing_3d.gd)
from Igor Akulov's **godot-aircraft-plugin** (MIT, [license](licenses/godot-aircraft-plugin-LICENSE.txt)),
with an autopilot on top for easy flying. The autopilot fighting that model caused the bobbing.
No code from it remains; read it in git history.

## Validation and previews

Use the README's isolated user directory, or `python3 tools/run_checks.py --only aircraft,easy_flying`.
`check_aircraft.gd` covers the size, boarding, BonBon's seat scale, take-off distance, a minute
of hands-off flight with no height change or bobbing, levelling off after a climb without a dip,
the nose following the climb angle, banking and levelling, the unpowered glide, landing and
braking, disembarking, wing sweeps, crashes and recovery. Rendered views of the current plane:
`docs/evidence/small-plane-20261123/capture.gd` →
[parked](../evidence/small-plane-20261123/parked.png),
[cockpit](../evidence/small-plane-20261123/cockpit.png),
[take-off](../evidence/small-plane-20261123/takeoff.png),
[climb](../evidence/small-plane-20261123/climb.png),
[turn](../evidence/small-plane-20261123/turn.png),
[level](../evidence/small-plane-20261123/level.png).
The older previews below (`render_aircraft.gd`) show the full-size plane before 23 Nov 2026.

[Parked aircraft](../evidence/town-checks/aircraft-parked.png) · [Boarding](../evidence/town-checks/aircraft-boarding.png) ·
[Pilot seating](../evidence/town-checks/aircraft-cockpit.png) · [Flight appearance](../evidence/town-checks/aircraft-flight.png)
