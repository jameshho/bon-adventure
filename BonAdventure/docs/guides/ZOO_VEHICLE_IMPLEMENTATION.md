# Road vehicle physics and boarding

Road physics implementation: **22 October 2026**; integrated doors updated **5 November 2026**. Cars and the other ground vehicles
now integrate engine/braking forces, tire grip, yaw inertia, drag, gravity and
raycast spring/damper loads. This replaces direct target-speed movement and three
obstacle rays. The existing models, vocabulary roots, parking positions, boarding,
player collision restoration and camera remain in use.

## Controls

| Action | Control |
| --- | --- |
| Board / exit (at any speed since 14 Nov 2026) | E |
| Accelerate forward | W |
| Brake to a stop, then reverse while held | S |
| Steer | A / D |
| Service brakes | Space |
| Recover while falling/airborne | R, then release |

Release the accelerator to coast with drag/engine braking. Use Space to stop
before exiting. Steering eases toward the input; since 21 Nov 2026 a held key sets the
path curvature and the car follows its nose
([path steering](#path-steering-and-chase-camera--21-november-2026); before: tyre forces and
yaw inertia, which barely turned at speed). The camera swings round behind a moving car. Front wheels steer and
all wheels spin and respond to suspension compression. Reverse steering follows
the vehicle's direction of travel. The HUD shows speed in km/h and D/R selection.
Opening a blocking overlay suspends motion without discarding momentum.

If a vehicle leaves the ground, wheel traction is lost and gravity acts. R returns
it to its initial pickup/parking point with a small vertical clearance, only if the
complete body fits there. Vehicle positions are not persisted between game runs;
learner save identity/format is unchanged. *Stale since 14 Nov 2026:* E no longer
waits for a stop and leaving no longer stops the vehicle; it coasts on
([exit while moving](#arcade-collisions-exit-while-moving-and-resets--14-november-2026)).

## Ownership and tuning

`scripts/world/road_vehicle_physics.gd` owns dynamics and wheel animation;
`DriveableVehicle::drive_step()` delegates to it for ground vehicles. The shared
controller still owns E/exit compatibility and body sweep helpers; Main still
owns registration/input blocking. Helicopter and turboprop use their separate
force solvers. No saved-world bake or replacement vehicle scene is required.

World metres/seconds are used explicitly, including Apartment's 1.3 scale.
Wheelbase and wheel radius come from existing wheel roots/meshes. Body/cabin sweep
volumes come from the existing solid `StudyArea` collision boxes. Tire roots keep
their selection Areas and word metadata as they animate. The older body collision
boxes have differing bottom clearances; suspension preload/droop is calibrated
against each box so it cannot unload the tires simply by supporting the body.

| Vehicle | Effective mass (kg) | Engine acceleration before drag/grip limits (m/s²) | Top speed (m/s) |
| --- | ---: | ---: | ---: |
| Car (also Subi) | 1,250 | 6.5 | 25 |
| Taxi | 1,400 | 5.9 | 24 |
| Police car | 1,450 | 7.4 | 27 |
| Truck | 4,200 | 3.8 | 22 |
| Bus / school bus | 6,500 | 3.2 | 21 |
| Ambulance | 3,600 | 4.8 | 24 |
| Fire truck | 6,800 | 3.7 | 21 |
| Motorcycle | 260 | 7.8 | 27 |

Profiles live in `RoadVehiclePhysics.PROFILES` as `[mass, acceleration, top speed]`.
The former shared limit was 14 m/s; every top speed is now 1.5–2× that. A vehicle's
exported `top_speed` above 0 overrides its profile value (0 = use the profile).

**Shared controller and handling — 29 October 2026** (user request: Subi could not
be driven; smoother acceleration/braking/reverse, more responsive steering, 1.5–2×
top speed with calmer high-speed steering, configurable parameters, car boarding
animation like the airplane's):

- **Registration.** Every `DriveableVehicle` joins the `driveable_vehicles` group;
  Main registers each one under Apartment. Subi (`RelocatedSites/Home/SubaruOutback`)
  and the school bus (`RelocatedSites/School/SchoolBus`) were previously skipped
  because only `Vehicles/` children were collected, so E never offered them. Twelve
  vehicles are registered. Subi's garage door must be open to drive out.
- **Configurable handling.** The "Road handling" export group on
  `driveable_vehicle.gd` holds `throttle_response` 3, `brake_deceleration` 8.5,
  `brake_response` 6, `coast_deceleration` .8, `reverse_speed` 6.5,
  `reverse_power` .6, `steering_speed` 3.8, `steering_return` 5.5,
  `steering_falloff_speed` 13, `max_lateral_acceleration` 8 and
  `high_speed_yaw_damping` .05 (*stale since 21 Nov 2026:* steering exports are now
  `steering_speed` 4.5, `steering_return` 6 and `max_lateral_acceleration` 11; the falloff
  and yaw damping were removed, see [path steering](#path-steering-and-chase-camera--21-november-2026)). Throttle and brake pressure ease in at their
  response rates and release twice as fast. The steering lock shrinks with
  `1/(1+(v/falloff)²)` and is capped so the lateral acceleration stays under the
  limit. The steering rate slows as speed rises, and yaw damping grows with speed.
  Reverse is limited by `reverse_speed` (replacing 35% of top speed).
- **Axle centre.** Tire lever arms are measured from the midpoint of the front and
  rear axles, not the body origin. Subi's unequal overhangs had made it spin out at
  speed.
- **Boarding and exit.** E starts a `boarding_duration` (1.8 s) sequence, shared
  with the turboprop through `animated_boarding()`, `advance_boarding()`,
  `boarding_step_point()`, `boarding_seat()` and the player's `animate_boarding()`.
  BonBon walks to the model's actual entrance, waits for the permanent door assembly
  to open, climbs in, and the same assembly closes. Exit reverses the sequence.
  The 5 November implementation below supersedes the former inferred panel and
  `driver_door` metadata. Motorcycles retain their open-seat boarding.


**Driving feel update — 28 October 2026** (user request: accelerate faster, get
stuck less, more natural turning, braking and uneven ground):

- Engine acceleration is about 1.6× the earlier values (table above); throttle
  ramps in at 6/s (was 3/s). After 3 s from rest the car reaches 12.5 (was 9.4).
- Steering moves at 3.5 rad/s toward the input and returns to centre at 5 rad/s
  (was 1.8 both ways); high-speed lock reduction starts later (speed/15, was /12).
- Wheel rays start `RAY_HEADROOM` (.35) above the wheel centre instead of .12, so a
  curb or bump just ahead of the tyre registers as ground before the body sweep
  meets it; the spring length subtracts the extra headroom, so suspension rest is
  unchanged. Contacts count up to normal.y .55 (was .65) for park slopes.
- `step_up()`: when a planar body sweep is blocked while the wheels are supported,
  the body tries lifts of up to `STEP_HEIGHT` (.3) and continues if the rest of the
  move is then clear. Curbs and small ledges are climbed; walls, posts and vehicles
  still stop the body. In the curb test the car previously stopped at the road edge
  at one of three spots; it now crosses the curb at all three.

These are gameplay profiles, not manufacturer specifications. Existing `top_speed`
sets the forward speed range via engine-force falloff; reverse is limited by
`reverse_speed`. Existing `steering_rate` scales the steering-angle range. Dry paved
surfaces use friction coefficient .95, lawn/meadow/terrain .65, beach .45. Spring
normal loads scale available tire force; longitudinal and lateral demands share
one friction budget (*stale since 21 Nov 2026:* the tyre model is gone; the surface grip now
scales the cornering limit, the sideways-slip damping and the drive/brake limit). Throttle/steering ease in, brakes oppose current motion, and
reverse engages only after slowing. Physics substeps are at most 1/120 second,
consuming up to .25 seconds per call.

Full body/cabin shapes sweep forward, backward and sideways. Rotation is checked
in increments no larger than .003 radians so corners cannot swing through nearby
obstacles. Supporting floor slabs are excluded from planar body queries and handled
by wheel contacts/minimum body clearance; walls and other vehicles remain solid.
The same shared sweep methods keep their original default behavior for aircraft.

This is an assisted upright-body driving model: planar tire/yaw dynamics plus
vertical support/gravity, with the motorcycle balanced upright. It does not model
rollovers, full suspension pitch/roll, gearbox/clutch internals, independent wheel
spin/burnouts, engine audio, damage or vehicle-to-vehicle momentum exchange. The
town has gentle park slopes and 0.17-high curbs (climbed by `step_up`); steep
ramps and real off-road simulation are not validated.

## Path steering and chase camera — 21 November 2026

User request: driving did not feel good and the cars were not turning. Measured on the real
parked cars before the change: holding D at speed gave a front-wheel angle of about 0.09 rad and
the yaw rate fell while the key was held (taxi 0.83 → 0.17 rad/s, a ~90 m circle at 16 m/s);
the tyre model understeered and the speed-scaled yaw damping cancelled the rest.

- **Path steering** (`road_vehicle_physics.gd` `steer_curvature()` and `integrate()`): cars
  now use the same "follow the path" model as the scooter. A/D ease a steering input in at
  `steering_speed` 4.5/s (slower at speed: halved at `STEER_SLOWDOWN_SPEED` 25 m/s) and back
  at `steering_return` 6/s. The input sets the path curvature: up to `tan(STEER_LOCK 0.6)` /
  wheelbase at low speed, capped at speed by `max_lateral_acceleration` 11 m/s² (scaled by
  the surface grip). The yaw rate follows speed × curvature (`YAW_RESPONSE` 10/s), sideways
  slip dies away (`CAR_GRIP` 9/s on asphalt, less on grass and sand) and the speed is carried
  round the bend. Reversing turns the other way, as before. Engine, brakes and coasting act
  along the nose through the wheels on the ground; suspension, kerb step-up and wall slides are
  unchanged, except that a car now also turns `CAR_ALIGN` 0.5 of the way to the wall line at a
  hit (the motorcycle keeps 0.8). The scooter's lean steering is unchanged.
- **Measured** (flat pad, D held, `docs/evidence/car-driving-20261121/diagnose.gd`): car
  circles 3.9 m at 4 m/s, 5.8 m at 8 m/s, 23 m at 16 m/s, 44 m at 22 m/s, steady while held;
  the turn starts within 0.08–0.2 s. Bus 7.8 m at low speed, 21 m at 15 m/s.
- **Chase camera** (`player_controller.gd` `chase_view()`): in a car or on the scooter the
  view eases round behind the nose (`CHASE_RATE` 2.2/s from 8 m/s, gentler when slower;
  also while reversing). Dragging the view pauses it for `follow_pause_seconds`, as on foot.
- **Removed:** `tire_force()`, per-tyre lateral forces and yaw torque, `yaw_inertia`,
  `axle_center`, and the `steering_falloff_speed` and `high_speed_yaw_damping` exports
  (no scene overrode them).
- Check: `check_road_physics.gd` replaces its two tyre-force checks with a 15–30 m circle at
  16 m/s, the grip limit, a tight circle at low speed and less cornering on grass. Results in
  [Final verification](FINAL_VERIFICATION.md#car-path-steering-and-chase-camera--21-november-2026).
  Views: [straight](../evidence/car-driving-20261121/turn-2-straight.png) ·
  [turning](../evidence/car-driving-20261121/turn-3-turning.png) ·
  [turned, camera behind](../evidence/car-driving-20261121/turn-4-turned.png).
- Not done: no hands-on play-test with keyboard or touch; the tuning numbers are a first pass.

## Arcade collisions, exit while moving and resets — 14 November 2026

User requests (vehicles workstream). Check: `docs/evidence/town-checks/check_vehicle_arcade.gd` (run_checks id
`vehicle_arcade`); results in [Final verification](FINAL_VERIFICATION.md#vehicles-parked-cars-arcade-collisions-exit-while-moving-resets--14-november-2026).

- **Wall slides** (`road_vehicle_physics.gd` `integrate()` / `wall_contact()`; before: a blocked
  axis lost all its speed and the yaw rate was cut to 25%, so cars stopped dead). The planar move
  is swept whole; when it is blocked the rest first tries `step_up()` (kerbs, unchanged), else
  `DriveableVehicle.contact_normal()` (a shape cast plus `get_rest_info()`, flattened) gives the
  surface normal. The into-wall speed is removed, `WALL_BOUNCE` 0.15 of it bounces back, and the
  speed along the wall keeps `SLIDE_KEEP_CAR` 0.85 / `SLIDE_KEEP_BIKE` 0.95, scaled by
  the hit (full loss from `IMPACT_REFERENCE` 3 m/s into the wall, so a long scrape does not bleed
  speed every step). Hard hits (`MAJOR_IMPACT_SPEED` 9 to `MAJOR_IMPACT_FULL` 15 m/s into
  the wall) keep only `MAJOR_KEEP` 0.45. Steering keeps working: the yaw rate keeps
  `YAW_KEEP` 0.8 plus a nudge toward the wall line (`YAW_NUDGE` 2/s per radian, at most
  0.6 rad/s); a motorcycle (no tyre forces to swing it round) turns `BIKE_ALIGN` 0.8 of the way
  to the wall line at once, as far as it can without touching anything. The rest of the move is
  swept again along the wall (up to `SLIDE_PASSES` 3 sweeps; a second surface in a corner only
  removes the speed into it), so nothing passes through solids. Measured in the check (speed
  0.05 s after the hit / before it): car glancing at 20° and 15 m/s 0.78, motorcycle 0.89,
  car at 60° and 20 m/s 0.24; a 5 cm wall at 27 m/s (head-on, 15°, −30°, car and motorcycle) is
  never crossed; a concave corner holds the car.
- **Exit at any speed** (`driveable_vehicle.gd` `safe_exit()` / `moving_exit()`). A vehicle
  that moves faster than `STOPPED_SPEED` 0.6 m/s or is off the ground (`is_moving()`) lets
  BonBon out at once, with no door or climb-out sequence: 3.3 m to the right of the travel
  direction (cars, motorcycles), 7 m (helicopter, clear of the rotor), 10.5 m (plane, clear of
  the wings), else the left, else behind; the capsule and the line from the vehicle must be
  clear. On supported wheels the point snaps to the floor; in the air she falls (no fall
  damage; she lands normally and the camera follows). Stopped vehicles keep the door sequence.
- **Coasting.** After such an exit the vehicle keeps its momentum with no input (`coasting`):
  cars and motorcycles roll and slow down with the normal coast drag (14 m/s rolled 118 m in
  17 s in the check), the helicopter's rotor spins down (it autorotates or crashes), the plane
  glides unpowered. Physics only runs while `needs_physics()` (driven, coasting, crashed or
  boarding): `_physics_process` returns at once for a parked vehicle, and a coasting one is
  parked again once it has been still for `SETTLE_TIME` 0.4 s (road: wheels supported, under
  0.08 m/s; helicopter: landed with the rotor stopped; plane: on its wheels under 0.3 m/s).
  A car that falls 60 m below where it started (off the map) is parked where it is.
  The Main overlay pause (occupied off while a window is open) still freezes the driven vehicle.
- **Resets** (aircraft only; cars stay where they crash or stop, R still recovers an airborne
  car). `reset_to_start()` puts a vehicle back at the pose it loaded with (`start_pose()`),
  stopped, the driver still aboard; the plane's red HUD Reset button calls it. The helicopter and
  the plane reset by themselves `EASY_RECOVER` 2.5 s after a crash (helicopter: a hit or
  touchdown faster than `HELI_CRASH_SPEED` 10 m/s, or 60 m below its start; plane: as
  before), when left unoccupied more than `AIRCRAFT_RESET_DISTANCE` 300 m from the player
  (`vehicle_controls.gd` `update_aircraft()`, four times a second) and, for the plane, at the
  [map edge](aircraft.md#exit-in-flight-resets-and-the-map-edge).
- Status and help lines (`vehicle.status_*`, `toast.driving_help`, `toast.helicopter_help`,
  `help.get_out`, `help.heli_exit`) now say E works while moving / in flight; new line
  `vehicle.status_heli_crash`.

## More parked vehicles — 14 November 2026

**18 Nov 2026 (user): the red motorcycles are gone.** Base step `tutorial_lot_clear` removes
every `motorcycle.tscn` (the 15 below: 14 in lots, 1 by the road), moves the east delivery
lot's white car two bays south (clear of the supermarket entrance, where the tutorial's market
act starts; the bay between is on the lot's drive) and parks the supermarket's delivery truck
(`Vehicles/Truck`, a pickup) in the warehouse lot's west bay that motorcycle used (half a unit
further west, clear of the truck corridors). BonBon's teal scooter (`Vehicles/Motorcycle`) is
the town's only motorcycle; 16 parked cars remain (27 road vehicles and the helicopter).
Checks `vehicle_arcade` and `zoo_vehicles` count and test those (the scooter for the motorcycle
tests). The table below is the 14 Nov state.

User request: every parking lot has at least one car and one motorcycle, plus a few cars by the
roads. Base step `parked_vehicles` (`scripts/buildings/base.gd`, baked into `base.scn`) adds 31
real `DriveableVehicle` prefabs under `Vehicles/` (registered like the others, so 43 road
vehicles and the helicopter in all): 16 `car.tscn` (a few shared paints: red, silver, white,
green, black or the original blue) and 15 `motorcycle.tscn`.

| Lot | Added | Already there |
| --- | --- | --- |
| Hospital, School, East delivery, Furniture, Sports, Bakery, Electronics, Bank, Clothing, Restaurant, Library, Warehouse | a car and a motorcycle | ambulance (hospital), bus (school; the school bus is in `school.scn`), truck (east delivery), scooter (restaurant), delivery truck at loading bay A (warehouse) |
| Police | a motorcycle | the police car |
| Airport | a motorcycle | the taxi |
| Loop road | four cars and a motorcycle, 4 town units off the centre line in the travel direction, away from crossings and drives | |

Lot spots are the painted bays nearest each lot's central entrance aisle, nose in toward the end
line, taken from a scan of every bay for bodies, figures (two bays next to figure blockers were
skipped) and vehicles; the check re-tests each one (stands on its wheels, body clear of walls,
figures and vehicles 15 cm up, at least 3 m from other vehicles, clear of every driveway) and
backs a car and a motorcycle out of their bays. The motorcycle prefab's body box reaches 10 cm
below its tyres; parked, the tyres stand on the lot and driving lifts the body as before.

**Warehouse lot** (added later the same day, for the warehouse redesign in
`scripts/world/warehouse.gd`): the car and the motorcycle use the lot's west bays (warehouse-local
x 11.5 and 5.5), leaving the central aisle and the drive (local x −3.4..3.4) to the trucks of
loading bays A and B (apron local x −8.2..2.6) and the east bays to the walk. Step
`warehouse_entrance_walk` moves the map/walk ribbon "Warehouse entrance connection" 12.2 east
(town x −48.8..−45.6), from the lot's north edge straight to the glass entrance at local x −12.2,
between the canopy posts and clear of the apron. `check_vehicle_arcade.gd` tests both against the
new geometry numerically (warehouse frame at town (−35, 0, 220.8)).

**Lighter motorcycle** (user, same day: cheaper to draw, still the real motorcycle).
`tools/merge_motorcycle.gd` merged `motorcycle.tscn`'s 217 single-part meshes into 7 (one surface
per material, saved as binary `scenes/props/vehicles/motorcycle_*.res`): each wheel keeps its tyre
`Visual` and one `Detail` mesh (rim, spokes, hub, brake; still spins, still the word "wheel"),
`FrontFork` keeps its node (it turns with the steering) with one `Visual`, and the rest is
`Parts` (frame, tank, seat, bars, fenders, lights, foot controls) and `Mechanics` (engine,
exhaust, rear suspension) on the root, so the lean still rolls everything. `StudyArea`, metas,
script and word keys are unchanged. Same 30,264 vertices and bounds; close-ups from three angles
look the same, and the lot views show the same primitive counts. The static body is two meshes,
not one, because a single mesh had 32k triangles and `render_culling.gd` hides any mesh of 30k+
(`HEAVY_TRIANGLES`) beyond 40 m on Low graphics (seen in a test render: only the wheels and fork
of a distant motorcycle showed). Draw calls per motorcycle: 217 → 37 surfaces.

**Render cost** (`docs/evidence/parked-vehicles-20261114/capture.gd`, 1400×900, default Low graphics,
the added vehicles shown vs hidden, same views; frame times at the 120 Hz vsync cap unless noted):

| View | 29 vehicles, 217-mesh motorcycle | 31 vehicles, merged motorcycle |
| --- | --- | --- |
| Restaurant lot | 687 → 981 (+294) | 687 → 801 (+114) |
| Bakery and electronics lots | 414 → 1002 (+588) | 414 → 642 (+228) |
| Hospital and school lots | 2027 → 2594 (+567); 9.5 → 12.5 ms | 2027 → 2234 (+207); 10.3 → 10.6 ms |
| Road-side car | 654 → 1319 (+665) | 654 → 959 (+305) |
| Overview | 4566 → 4830 (+264); 14.2 → 15.9 ms | 4566 → 4971 (+405); 15.4 → 16.2 ms |
| Warehouse lot (new view) | | 888 → 1002 (+114) |

Mesh instances added: 4,358 → 1,513 (now with the two warehouse vehicles). The overview costs
more than before: the old per-part ranges hid most small motorcycle parts beyond 120 m, while the
merged `Parts`/`Mechanics` keep the whole bike's range (300 m). Views:
[restaurant lot](../evidence/parked-vehicles-20261114/restaurant-lot.png) ·
[bakery and electronics](../evidence/parked-vehicles-20261114/bakery-electronics-lots.png) ·
[hospital and school](../evidence/parked-vehicles-20261114/hospital-school-lots.png) ·
[road-side car](../evidence/parked-vehicles-20261114/roadside-car.png) · [overview](../evidence/parked-vehicles-20261114/overview.png) ·
[warehouse lot](../evidence/parked-vehicles-20261114/warehouse-lot.png) (this worktree still had the old warehouse building).

## Open-source adaptation and checks

The spring compression/damper calculation, normal-load-scaled tire-force curve,
combined-grip approach and eased steering adapt Dechode's MIT
[Godot-Simple-Vehicle](https://github.com/Dechode/Godot-Simple-Vehicle), pinned to
`f448b000f896053319938e4f67ddd230623da853`:
[Wheels.gd](https://github.com/Dechode/Godot-Simple-Vehicle/blob/f448b000f896053319938e4f67ddd230623da853/scripts/Wheels.gd),
[BaseCar.gd](https://github.com/Dechode/Godot-Simple-Vehicle/blob/f448b000f896053319938e4f67ddd230623da853/scripts/BaseCar.gd).
The original [MIT license](licenses/godot-simple-vehicle-LICENSE.txt) is retained.
The upstream Godot 3 implementation is ported/adapted to this project's Godot 4
Node3D vehicle contract. Its rigid-body scene, curve resources, models, audio,
camera and full drivetrain are not imported. Local additions include upright-body
integration, profiles, automatic drive/reverse, full-body sweeps and recovery.

Use the README's isolated learner-data configuration:

```
godot --headless --path . --fixed-fps 60 --script res://docs/evidence/town-checks/check_road_physics.gd
godot --headless --path . --fixed-fps 60 --script res://docs/evidence/town-checks/check_zoo_vehicles.gd
godot --headless --path . --fixed-fps 60 --script res://docs/evidence/town-checks/check_vehicle_boarding.gd
godot --path . --resolution 1400x1000 --script res://docs/evidence/town-checks/render_road_physics.gd
godot --path . --resolution 1280x800 --script res://docs/evidence/town-checks/render_vehicle_boarding.gd
```

`render_vehicle_boarding.gd` overwrites only `docs/evidence/vehicle-boarding-20261029/*.png`
(Subi approach, door open, climbing in, seated, driven out, getting out, on foot,
police-car door).

The graphical check actually boards the home garage car, drives out, turns,
brakes and exits. It overwrites only `docs/evidence/town-checks/road-*.png`. Evidence and limitations
are in [Final verification](FINAL_VERIFICATION.md#road-vehicle-physics-rewrite--22-october-2026).
[Driveway exit](../evidence/town-checks/road-driveway.png) · [Turning](../evidence/town-checks/road-turn.png) · [Parked](../evidence/town-checks/road-parked.png)

## Historical zoo/vehicle implementation — superseded for road physics

This report is historical. The current fixed-wing aircraft has its own
[controls, physics and boarding guide](aircraft.md). Current baseline failures and
runtime test results are recorded in [Final verification](FINAL_VERIFICATION.md).

Based on `Vocabulary_Town_v27_Transportation_Navigation_Time_Expanded.zip`.

## Changes

- Removed only the strange canopy beside the giraffe pen (`Shelter roof2`) and its two associated posts and static collisions. The giraffe, animal habitat, water trough, and other roofs are unchanged.
- Opened the south side of the wild-animal enclosure at local zoo coordinates **x = -34, z = 69** by splitting the low/high fence rails and the corresponding invisible physical barrier. Removed the center fence post only.
- Added `scenes/world/zoo_gate.tscn`, with two swinging physical gate leaves and a vocabulary target. When BonBon is within roughly 4 world units on either side of the gate, press **E** to open or close it. It animates over time and its physical collision shapes move with the leaves. Click to study **gate: el portón / la puerta de la cerca**.
- The existing rooftop helicopter scene now carries `helicopter` vocabulary metadata and a reused motor-control script; click its body or other collidable parts to study **helicopter: el helicóptero**.
- Attached `scripts/world/driveable_vehicle.gd` to the eight pre-existing land vehicle prefabs (car, truck, bus, taxi, police car, ambulance, fire truck, motorcycle) and to the helicopter. This changes their control behavior, not their meshes or placement.
- Added player seat handling. E boards the nearest vehicle in range and E again exits to one side. BonBon is temporarily hidden, her physical collisions are disabled while seated, and the existing orbit camera follows the driven object. On exit, the player appears next to the vehicle and the original collision settings are restored.
- Preserved earlier vocabulary expansions, metadata, buildings, and roads; there are now **500 vocabulary entries**, 500 category mappings, and **168 learning-catalog records**.

## Controls

| Action | Controls |
| --- | --- |
| Open or close zoo gate | E when close to the gate |
| Board nearby vehicle | E |
| Exit vehicle | E |
| Drive forward / reverse | W / S |
| Steer | A / D |
| Helicopter ascend / descend | Space / Ctrl |
| Helicopter turn and move horizontally | A / D and W / S |
| Study an object | Aim and left click |
| Camera orbit | Hold right mouse button |
| Help | F1 |

The driving implementation is a **simple arcade controller**, not wheel-by-wheel rigid-body simulation. It includes forward obstacle probes to reduce wall penetration but does not model suspension, traction, traffic rules, fuel, damage, autonomous vehicles, or realistic aerodynamic flight. Exiting a helicopter while airborne will leave BonBon subject to gravity.

## Files changed

- `scenes/world/park_zoo.tscn`
- `scenes/world/zoo_gate.tscn` (new)
- `scripts/world/zoo_gate.gd` (new)
- `scripts/world/driveable_vehicle.gd` (new)
- `scenes/props/vehicles/*.tscn` (nine edited vehicle scene roots)
- `scripts/core/main.gd`
- `scripts/player/player_controller.gd`
- `scripts/player/interaction_controller.gd`
- `scripts/ui/vocabulary_hud.gd`
- `data/words.json` (then `vocabulary.json`, `vocabulary_categories.json` and `learning_catalog.json`, merged on 28 October 2026)
- Regression check scripts in `docs/`.

## Verification

Static project checks performed on this updated archive:

- Zoo, vehicle, scene structure and vocabulary: **78 passed, 0 failed**.
- Earlier food and shopping regression: **345 passed, 0 failed**.
- Earlier transportation and time regression: **505 passed, 0 failed**.
- Latin American Spanish translation/category/embedded metadata audit: **passed**.
- General project checker: **two pre-existing flags**, unchanged from the input ZIP. `docs/check_building_exteriors.gd` contains a dynamically-built `res://docs/building-...` filename the static checker treats as a missing file; `town_editable.tscn` already had a nonmatching `load_steps` value.

**Godot engine was not available in the working environment**, so launch, rendered visibility, actual physics animation and real input click-through were **not executed**. `docs/evidence/town-checks/check_zoo_vehicles.gd` was added as an engine-based regression check. Run it in the project directory using Godot 4:

```sh
godot --headless --path . --script res://docs/evidence/town-checks/check_zoo_vehicles.gd
```

Then open the project in the editor and visually confirm that the gate does not intersect fence posts, that there is enough clearance to walk through when open, that BonBon exits onto safe ground, and that the helicopter can be approached on the roof. In particular, test in-editor with your actual Godot engine version before publishing.

## Integrated vehicle doors and warehouse box truck — 5 November 2026

The warehouse truck was procedural decoration in `warehouse.gd::delivery_truck()`;
it was unrelated to the driveable `truck.tscn` (the teal pickup). It now instances
`scenes/props/vehicles/box_truck.tscn` at the **same local transform**:
`rear + Vector3(0, 1.85, -2.4)`, with the same -Z facing. Its `truck` word and
warehouse ownership remain. It remains decorative, as before.

The new scene has `Cabin`, `Cargo`, `Chassis` and `StudyArea` roots. The blue-gray
cab has framed windscreen/side glass, mirrors, wipers, headlights/indicators,
grille, bumper, steps and seats. The light cargo body has separate walls/floor/roof,
corner rails, yellow stripe, rear lights, and two rear doors with locking bars.
Four tires and hubs retain the former axle locations. Cab and cargo are separate;
`Cabin/LeftDoor`, `Cabin/RightDoor`, `Cargo/LeftRearDoor` and `Cargo/RightRearDoor`
are permanent hinges. Rear opening/loading gameplay is not implemented; a future
loading feature must also replace the cargo's enclosing collision box with wall
collisions. No warehouse building or other vehicle placement was changed.

### Runtime ownership

- `scripts/world/vehicle_door.gd`: reusable permanent hinge node. `closed_transform`
  records its authored pose (`_ready()` or `seal_pose()` after positioning).
  `set_open_amount(0…1)` rotates by exported `open_angle` and applies exported local
  `slide`; it never toggles visibility. `boarding_amount(progress)` eases open
  at .28–.44, holds open during transfer, and closes at .82–.98. Exit runs backward.
- `scripts/world/vehicle_doors.gd`: explicit measured model profiles plus a one-time
  adapter for the existing solid models. At vehicle readiness, triangle clipping
  separates **the existing painted surfaces** inside the door bounds from the fixed
  shell. Glass, body paint, trim, mirrors and handles retain their actual geometry
  and materials. CSG depth polygons are triangulated before partitioning. Original
  nodes/metadata/collision references remain, with their render layers set to zero
  and `door_partitioned` metadata; `*FixedShell` and `*DoorSkin` render the partition.
  No mesh generation or partitioning occurs during interaction. This adapter is for
  the existing untextured, normal-bearing triangle meshes and depth CSG polygons;
  textured/skinned models should author door assemblies directly.
- `driveable_vehicle.gd` owns `vehicle_doors`, keeps `driver_door` as the first-leaf
  compatibility reference, and drives these assemblies through the existing boarding
  progress. The wheel/body collision bounds no longer guess a door's dimensions.
  Door-side ground/capsule checks remain; blocked door exits are refused instead of
  teleporting through a different side of a closed cabin. Driving physics and wheel
  collision geometry are unchanged. The door leaves are visual assemblies; the
  existing whole-vehicle collision envelope remains during the scripted transfer.
- `turboprop.gd` retains its authored `CabinDoor`, now uses the same hinge/easing,
  swings outward to port, and removes the fixed sill behind its lower leaf. Its
  port entrance now supports animated exit as well as entry. Existing flight and
  safe-landing checks remain.

Affected models: car, taxi, police car, teal pickup (`truck`), ambulance, fire truck,
bus, school bus, Subaru Outback, helicopter and turboprop. The motorcycle remains
doorless. Road prefabs and saved-world overrides are adapted at runtime rather than
rebaked. The bus and school bus use both leaves of their actual **-Z passenger
entrance**, with opposite hinge angles; road cabs use +Z. The helicopter uses its
port pilot door, with its existing window, and now participates in the boarding
sequence. This replaces the former temporary-looking `DriverDoorSwing` panel and
`DriverDoorOpening` mask entirely.

### Warehouse box truck is drivable — 8 November 2026

`box_truck.tscn` now runs `driveable_vehicle.gd`: root on the ground facing −X, the old model
as the turned child `Model`, four `Tire*` wheels, `StudyArea` boxes in the −X frame, and
`vehicle_door_spec` for the driver door. Details and check:
[warehouse guide](WAREHOUSE.md#drivable-delivery-truck--8-november-2026).

### Scooter and rider — 9 November 2026

User decision: the restaurant-lot motorcycle became a **toy-like scooter** shaped around BonBon, so
she rides it **visibly** instead of disappearing (word stays `motorcycle`; zone override
`Vehicles/Motorcycle` → `fine_dining` unchanged). Car, bus, truck and aircraft boarding are
unchanged (BonBon still hides inside cabins).

| Piece | Owner |
| --- | --- |
| Model (`scenes/props/vehicles/scooter.tscn`, faces −X, town scale 1.3; world sizes below), built around BonBon at her **full size** (user follow-up, same day: no shrinking, a bigger scooter instead): 3.65 m long, wheels `Wheel`/`Wheel_2` (CylinderMesh `Visual`, radius 0.38), `Bodywork` (floorboard `FloorMat` top 0.42 = her paw soles, rear cowl, `SeatBase`, leg shield ahead of her belly, fender, lights), `Seat` cushion under the back of her belly, `FrontFork/Handlebar` bars crossing in front of her belly and sweeping back to grips tagged `rider_grip` = `Near`/`Far`, markers `RiderMount` (her origin when seated; meta `rider_scale` 1.0) and `MountStep`, one `StudyArea` box | generated by `tools/build_scooter.gd` from BonBon's measured underside (0.17 below her centre, rising to 0.25 at 0.4 behind it; paws under the middle); the saved .tscn is the source of truth |
| Placement: replaces the motorcycle instance at the same path, transform and metas. The bake keeps its own copy of every part, so **a changed scooter.tscn needs a new base step that places it again** (`toy_scooter_full_size` calls `toy_scooter`) | base steps `toy_scooter`, `toy_scooter_full_size` (`scripts/buildings/base.gd`) |
| Lean (atan(v·yaw/g), ≤ 0.42 rad, smoothed) on every visible child, `FrontFork` turns with 0.45 × the front-wheel angle, fore-aft acceleration for the rider, a rider sweep box | `driveable_vehicle.gd` (`has_rider()`, `update_rider_visuals()`, `set_lean_applied()`, `add_rider_hull()`); physics and `StudyArea` stay upright: the lean is removed before each road step and put back after |
| Rider pose: walk to `MountStep` (t 0–.4), hop onto the seat turning forward (.4–.8), settle (.8–1); getting off is the reverse. Riding: feet stay where she stands (joined to her body) on the floorboard, belly resting on the cushion, arms aimed and stretched (0.55–1.5×) so the paws stay on the grips, slight hunch (0.06 rad), extra lean 0.2 × the scooter's, rock ±0.1 rad about her seat contact (0.022 rad per m/s²; back when accelerating, forward when braking), head turns with the bars, small speed bob | `scripts/player/motorcycle_rider.gd`, called from `player_controller.gd::animate_boarding()` when `has_rider()` |
| Sync: while riding, the player's `process_physics_priority` is 10, so BonBon is posed after the vehicle moved in the same tick | `player_controller.gd` (`board_vehicle()` / `leave_vehicle()`) |

**Lean steering (user follow-up, same day: "turns at a fixed angle", "resets its balance").**
Probe (`docs/evidence/scooter-20261109/handling_probe.gd`): with the car tyre model, holding A/D reached
the speed-limited lock in 0.25 s and then turned at a constant 0.3-0.4 rad/s; crossing a kerb
with only two tyres spiked one tyre's load (grip demand > 600x), reversed the yaw while A was
held, and the lean (computed from yaw) snapped upright and over. Two-wheelers (`wheels.size()
<= 2`) now steer by leaning in `road_vehicle_physics.gd`: A/D builds `lean_angle` at 0.5 rad/s to
0.6 (released or reversed: 1.6 rad/s), the path curvature is 1.2·g·tan(lean)/v², capped at
walking pace by the bars' lock, the yaw follows that path, sideways slip dies away (14/s),
deep lean scrubs speed (up to 5 m/s² at full grip) so a held turn keeps tightening, and one tyre
on a kerb still counts as supported. Cars, buses and trucks keep the tyre model (identical
handling figures). The scooter's visible lean is `lean_angle` scaled to `MAX_LEAN`, faded out
below 6 m/s and in reverse.
Second pass (user: a held turn "still not turning enough"): `LEAN_GRIP` 1.2 → 2.4 (lateral
acceleration up to ~16 m/s², arcade) and `CORNER_DRAG` 5 → 6, so a held key turns 0.65 rad/s
after 1 s and tightens to the 1.8 rad/s cap as the turn scrubs speed. The bars' visible turn is
capped at `BAR_TURN_MAX` (0.06 rad, `driveable_vehicle.gd`) and the arm may shorten to 0.5
(`ARM_STRETCH`), otherwise tight turns pulled the near paw off its grip.
Third pass (user: "start at a greater angle", "change more the longer I press", "shouldn't
decelerate that quickly" off W): a press snaps to `LEAN_START` 0.35 at 3 rad/s, then builds at
0.28 rad/s to `LEAN_MAX` 1.0 (~2.4 s); turn cap `LEAN_YAW_MAX` 2.6 rad/s, bars' lock 0.8. The
velocity now turns with the nose each tick (before, damping the sideways slip bled ~4-6 m/s² in
tight turns), `CORNER_DRAG` is 2 and two-wheelers coast at `LEAN_COAST` 0.35 m/s² (cars keep
`coast_deceleration`). Current values are the constants in `road_vehicle_physics.gd`.

Tuning lives in the rider script's constants (`PAW_OFFSET` (zero here), `ARM_STRETCH`, `HUNCH`,
`EXTRA_LEAN`, `ROCK_PER_ACCEL`, `MAX_ROCK`, `HIP`) and the vehicle's `BAR_STEER`/`MAX_LEAN`.
Another open-seat vehicle needs only the same markers and tagged grips. The old
`motorcycle.tscn` prefab is no longer placed in the town (*stale since 14 Nov 2026:* the parked
motorcycles use it again, see [more parked vehicles](#more-parked-vehicles--14-november-2026)). Results:
[Final verification](FINAL_VERIFICATION.md#scooter-with-a-visible-rider--9-november-2026).

### Future models

Prefer authored doors: attach `vehicle_door.gd` to each hinge, place its complete
leaf (glass, handles, trim) below it, and set `metadata/boarding_door = true`.
The controller discovers these and skips surface partitioning. Author a genuine
opening in the fixed cabin. All marked leaves animate together (use this for
paired entry doors, not unrelated cargo doors).

Set root `vehicle_door_spec` metadata to a dictionary with `hinge`, `length`,
`bottom`, `top`, `side`, `inner`, `door` in **model-local units** for a -X-facing road
vehicle. `side` is signed Z; the step sits 1.05 units outboard and the seat is inside
that side. `inner` is the inner Z cut for a legacy model. Alternatively, `door_profile`
selects an existing profile (`car`, `taxi`, `police car`, `subaru`, `truck`,
`ambulance`, `fire truck`, `bus`). New orientations should override
`boarding_step_point()`/`boarding_seat()`/`preferred_exit_points()` as the aircraft
do. Keep a new profile explicit and inspect closed/open poses; never infer a cabin
from cargo or collision-box dimensions. Restart the world after edits.

### Verification tools

`docs/evidence/town-checks/check_vehicle_doors.gd` loads the full town and runs E entry, hinge opening,
closure, safe door exit, walking restoration and stable node-count checks for every
registered vehicle on a clear test pad. `-- --capture` renders closed/open model
views (BonBon hidden only for these inspection snapshots) and the truck in its actual
warehouse position to `/tmp/vt-vehicle-views/`. Use README save isolation.
`check_vehicle_boarding.gd` retains the garage driving/handling checks, with closed
visibility expectations updated for permanent doors. Results and limits are recorded
in [Final verification](FINAL_VERIFICATION.md#integrated-vehicle-doors--5-november-2026).
