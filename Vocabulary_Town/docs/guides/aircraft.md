# Single-engine turboprop

Added 21 October 2026. Restart Main and walk to the airport runway. The blue/ivory
high-wing aircraft is parked near its southern threshold, pointing down the
existing runway. Approach the left cabin step and press **E**. BonBon visibly climbs
the step over 2.4 seconds, the door swings, and she stays visible in the pilot seat.

Since 14 November 2026 the plane and the helicopter start in [easy flying](#easy-flying);
the table below is the expert control set (press **C** in the cockpit to switch).
Note: the code reads Space / Shift for throttle and B for brakes (the table's Shift / Ctrl
and Space are older); the cockpit status line and F1 show the keys the code uses.

| Action | Control |
| --- | --- |
| Board / exit (also in flight since 14 Nov 2026) | E beside cabin / while seated |
| Increase / decrease throttle | Hold Shift / Ctrl; throttle stays where released |
| Nose up / down | S / W |
| Bank right / left; steer on ground | D / A |
| Rudder / nosewheel left / right | Z / X |
| Flaps: half, full, retracted | F cycles; starts at half for takeoff |
| Wheel brakes | Hold Space |
| Level assist; recover after impact | Hold R in flight; R after a crash |
| Orbit / zoom | Hold right mouse / wheel; chase view resumes after orbit |

For a first flight, board and wait for BonBon to sit, hold Shift until throttle is
100%, then gently pull S above about 40 knots. Release S once climbing; hold R
to ease toward wings-level flight. F retracts the flaps after takeoff (from the
initial half setting, press twice). Bank gently with A/D. For landing, reduce
throttle with Ctrl, extend flaps and descend toward the runway; keep wings level
and a shallow descent. Hold Space after touching down, then E to exit. The HUD
shows airspeed in knots, altitude above the starting runway in world metres,
throttle, flap setting, ground/airborne state and a stall warning. It is not an
AGL terrain radar. F1 includes the aircraft controls.

## Easy flying

User request, 14 November 2026: an easy control for the plane and the helicopter. It is on
by default for both (`DriveableVehicle.easy_flying`, a static flag, not saved); **C** in the
cockpit switches between easy and the expert controls above (the status line and the boarding
toast say which). Everything goes through InputMap actions, so the touch stick and buttons fly
too: a **▼** button (the `descend` action) appears left of jump while flying either aircraft
(`touch_controls.gd`).

| | Turboprop (easy) | Helicopter (easy) |
| --- | --- | --- |
| W / stick up | take off (full power, lifts off at ~21 m/s), then climb | fly forward |
| S / stick down | descend; on the ground idle and brake | fly back |
| A / D | turn (bank ≈ 34°; ≈ 6° below 8 m) | turn |
| Space / jump | the same as W | up |
| Shift / Ctrl / ▼ | the same as S | down (Ctrl and ▼ also in expert mode) |
| Let go | hold the height and fly level, wings level | brake to a hover (the R hover assist) |
| After a crash | back on the runway after 2.5 s (or R) | back on its pad after 2.5 s (since 14 Nov 2026) |

The turboprop's `easy_inputs()` works the real flight model's elevator, ailerons, throttle,
flaps and brakes (`aircraft_step()` is unchanged): a vertical-speed controller (climb 6 m/s,
descend 5 m/s, or hold the height captured on release), automatic throttle (cruise 38 m/s,
approach 25 m/s), flaps half below 32 m/s and full while descending slowly, stall protection
below 21 m/s, and near the ground (a ray up to 120 m down) a sink-rate limit, small bank and
idle power, so holding "down" lands gently on anything flat. The runway is only about 115 m
long with the sea past its end, so a landing usually rolls onto the grass beyond it; that is
fine. The helicopter's easy mode only turns on the existing hover assist whenever the stick is
centred.

Check: `docs/evidence/town-checks/check_easy_flying.gd` (run_checks id `easy_flying`): boarding, take-off and climb
on "up" alone, level hold, a right turn, wings levelling, a descent and landing on "down"
alone, crash recovery, and the helicopter braking to a hover. Rendered views:
[helicopter + touch ▼](../evidence/easy-flying-20261114/helicopter-touch.png),
[turboprop easy status](../evidence/easy-flying-20261114/turboprop-touch.png),
[F1 guide](../evidence/easy-flying-20261114/help.png) (`docs/evidence/easy-flying-20261114/capture.gd`).

## Exit in flight, resets and the map edge

User request, 14 November 2026 (code: `driveable_vehicle.gd`, `turboprop.gd`,
`vehicle_controls.gd`; check `docs/evidence/town-checks/check_vehicle_arcade.gd`, run_checks id `vehicle_arcade`).

- **Exit at any speed.** E in the air, rolling or crashed lets BonBon out 10.5 m to the side of
  the plane (clear of the 8.8 m half span), with no door sequence; in the air she falls to the
  ground (no fall damage). The plane glides on unpowered with the controls released (engine off,
  `coasting`) until it rests on the ground, then it is parked again and its physics stops. A
  stopped plane on the ground still plays the door and climb-out sequence.
- **Resets.** `reset_to_start()` (shared with the helicopter) puts the plane back where it
  was parked, stopped, with the pilot still in the cockpit if aboard; the red HUD **Reset**
  button calls `main.active_vehicle.reset_to_start()`. It happens by itself after a crash
  (`EASY_RECOVER` 2.5 s, in both easy and expert flying; R still recovers at once), when the
  plane is left unoccupied more than 300 m from the player (checked four times a second by
  `vehicle_controls.gd` `update_aircraft()`), and at the map edge below.
- **Map edge.** The playable area is the town's `reference_map_bounds` (the full map's frame,
  town units) grown by `MAP_MARGIN` 150 m. Past it the HUD flashes `vehicle.map_edge` (again
  every 6 s while outside) and the easy autopilot flies the plane: it banks toward the centre of
  the map and turns back, a gentle turn rather than a wall (up/down still work in easy flying;
  expert flying is taken over until it is back inside). `MAP_RESET_MARGIN` (400 m) further out,
  or unoccupied past the edge, the plane resets to the runway, so it cannot be lost. In the
  check, a plane flying straight out at 38 m/s, 40 m past the edge, turned back with its widest
  point about 300 m past the edge. The older 2,500 m crash limit stays as a last resort.

## Ownership and physics

- `scenes/props/vehicles/turboprop.tscn` owns the airplane vocabulary root.
  `world_refinements.gd::airport_aircraft()` instances it under `Vehicles` and
  builds its editable primitive children with Main's existing material/geometry
  helpers. No saved-world bake or airport relocation is required.
- `scripts/world/turboprop.gd` extends the existing `DriveableVehicle` contract.
  Main still owns E boarding and input blocking; existing swept body queries
  check the fuselage, full wings, tail and propeller disk. Three visible wheels
  use a simplified central support/landing calculation, not wheel suspension.
- Model spans 13.6 town units before Apartment's 1.3 scale. Physics integrates
  world-unit velocity, effective 900 kg mass, 28 m² wing area and 6,200 N maximum
  static thrust. These are gameplay tuning values for the short runway, not a
  certified aircraft specification or scaled replica.
- Forces include speed-squared lift/drag, angle of attack, post-stall lift loss,
  induced drag, gravity, flap effects and a spooling engine. Bank redirects lift
  and produces coordinated turns. Pitch/roll/yaw use damped control rates with
  speed-dependent authority and simplified tail stability; this is a semi-realistic
  game model, not a full six-degree-of-freedom aerodynamic solver.
- Power-off flight trades height and speed, losing total energy through drag.
  The propeller, wheels, ailerons, elevator, rudder, flaps and boarding door animate.
  `player_controller.gd` uses BonBon's existing arm/foot nodes for boarding and
  seating; it restores walking transforms and collision on exit. Since 29 Oct the
  sequence is the shared `animate_boarding()`/`advance_boarding()` also used by
  cars ([road vehicles](ZOO_VEHICLE_IMPLEMENTATION.md)); the plane keeps its
  2.4 s duration, visible pilot and instant exit.
- E is blocked while boarding or without a clear exit (before 14 Nov 2026 also while
  airborne or moving: [now allowed](#exit-in-flight-resets-and-the-map-edge)). Impacts
  above 5 m/s or a hard/steep landing stop the plane; it returns to the runway after
  2.5 s or at once with R. Below-world travel or exceeding a 2,500-world-unit radius also
  counts as a crash. No damage persistence, fuel model, wind, engine sound, cockpit camera
  or retractable gear is implemented. Other vehicles retain their own controllers.
- Opening a blocking overlay pauses aircraft physics while retaining velocity;
  closing it resumes flight. Leaving the plane shuts the engine off. The aircraft
  is not saved between runs. Existing learner save identity/format is unchanged.

## Open-source reference and license

The force-direction and dynamic-pressure calculation adapts
[`VehicleWing3D::_calculate_section_forces`](https://github.com/wmigor/godot-aircraft-plugin/blob/395a707dd81edd6530be8e89f3c1a177164289d6/addons/aircraft/scripts/vehicle_wing_3d.gd)
from Igor Akulov's **godot-aircraft-plugin**, pinned to commit
`395a707dd81edd6530be8e89f3c1a177164289d6`. Its
[MIT license](licenses/godot-aircraft-plugin-LICENSE.txt) is retained verbatim.
This adaptation uses one effective wing with local lift/drag coefficient curves;
it does not import the plugin's per-section rigid-body solver, editor tools or
demo assets. The project was inspected alongside
[Godot Simplified FlightSim](https://github.com/fbcosentino/godot-simplified-flightsim)
and [Flight-sim](https://github.com/Feeflak/Flight-sim); no code/assets from those
two alternatives were copied.

## Validation and previews

Use the README's isolated user directory, then run:

```
godot --headless --path . --fixed-fps 60 --script res://docs/evidence/town-checks/check_aircraft.gd
godot --path . --resolution 1400x1000 --script res://docs/evidence/town-checks/render_aircraft.gd
```

The first command covers boarding, visible pilot placement, vocabulary targeting,
takeoff, banking, sustained assisted flight, powerless glide, stall forces,
landing/braking, safe exit, wing impacts and recovery. The second overwrites four
current preview images; its flight pose is staged for visual inspection, not a
recorded flight. Simulation evidence and limitations are in
[Final verification](FINAL_VERIFICATION.md).

[Parked aircraft](../evidence/town-checks/aircraft-parked.png) · [Boarding](../evidence/town-checks/aircraft-boarding.png) ·
[Pilot seating](../evidence/town-checks/aircraft-cockpit.png) · [Flight appearance](../evidence/town-checks/aircraft-flight.png)
