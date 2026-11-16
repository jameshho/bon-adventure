# Three-floor hospital

## Current remodel — 26 October 2026

The user authorized the interior implementation, a compact left staircase and a
functional right elevator on all three floors. This supersedes the former
pediatrics/cardiology layout and the earlier optional-elevator/deferred-interior
status. The master brief remains the authority for room purposes.

### Floor plans

View from the front entrance: **+X is left, +Z is toward the rear** in the hospital
prefab. Main retains the building's existing placement and scale. The entrance is
at (0,0,-12.2). Floor elevations are 0, 5.6 and 11.2 town units.

| Position | Floor 1 | Floor 2 | Floor 3 |
| --- | --- | --- | --- |
| Front left | Room 1: reception | Patient room 201 | Imaging |
| Core left | Wide straight stairs; two approaches | Same core | Same core |
| Core right | Lift lobby; elevator in the side tower | Same | Same (lift and stairs also reach the roof) |
| Lounge | Open seating left; pharmacy right | Open seating, open to the annex | Open seating, open to the annex |
| Back left | Room 2: emergency care | Patient room 202 | Laboratory |
| Back right | Room 3: examination | Intensive care | Physical therapy |
| Front right | Waiting room | Operating room | Doctors' office |

The brief did not number Rooms 1–3; the first-floor purposes above follow its
listed order. This mapping is recorded explicitly rather than presented as an
older documented assignment. The previous department arrangement conflicts with
the approved program and has been superseded. The old side annex envelope remains a gallery; no building resize
or site relocation was made. Its ground-floor display cluster retains the trolley,
medicine shelf, treatment, X-ray, scale and patient-chart lessons formerly occupying
the new shaft. Existing anatomy displays, pharmacy plaque and other useful content
remain available.

Main block: 18 × 32.1 (z −12.2..19.9, one room deeper since 27 October 2026);
central hall: 4 wide; corner bays: 7 × 7.7. Front rooms are centered at x=±5.5,
z=−8.35, back rooms at x=±5.5, z=16.05; the stair/elevator core spans z −4.5..4.5 and
the open lounge z 4.5..12.2. Door openings are 3.3 wide.
The retained annex is x=9..16, z=-2..12. Its rear gallery provides the return route between straight flights and a second
stair approach from the hall on every floor.

### Polish: floors, reception, waiting room, anatomy model — 31 October 2026

User-requested fixes; generator changes are in `tools/build_hospital_remodel.py`
(regenerate `hospital.tscn`), runtime ones in `remodel_hospital_displays()`.
This supersedes the receptionist, the floor runners/insets and the painted stair
arrows described in the sections below.

- **No "floor" word.** `Floor1–3` no longer carry `word_key = "floor"`; it made each
  whole storey one hover target, so the entire interior flashed.
- **Stairs.** The flat landing guards (`LandingRail`/`LandingPost`) are gone: each
  opening is filled by the flight that starts on that floor, whose own rails guard both
  edges, and the flat rails poked out at the foot of every flight. The painted
  `↑ PLANTA 2/3`, `↑ AZOTEA` floor arrows are removed; wall signs stay.
- **Floors.** The pale tinted strips (`HallRunner`, both `LandingInset`s,
  `LiftLobbyInset`) are removed. Every floor slab and room inset uses
  `shaders/hospital_floor.gdshader` via `tiled()`: 60 cm world-aligned tiles (0.78 world
  m) with grout, a faint tone shift and speckle, in the slab's own colour. Rugs stay plain.
- **Roof door.** `RoofDoor` is hinged on the side-wall jamb (x=15.5, `reverse=True`
  leaf) and swings inward to rest along the stair house's side wall (angle −1.6).
- **Reception.** `People/Doctor` and `People/Nurse` and their scenes are deleted from
  the game and all world snapshots. A sheep plush in the `doctor` outfit
  (`Floor1/Room1/SheepDoctor`, word **doctor**; inside the room so `compact_town()` moves it with the hospital) stands behind the counter. Poppy stays home.
  *Corrected the same day:* it was forced to 2.7 town units (≈3.5 world units, 1.57×
  BonBon's 2.24) to clear the 1.27 ledge. It now keeps world scale 1, like every plush
  character (BonBon-sized), and the counter is lowered instead: ledge 0.95, worktop and
  return top ≈0.72.
  *1 Nov 2026:* three ward doctors joined it: `BonBonDoctor` (pig, Floor1/Room3),
  `CatDoctor` (Floor2/Room3) and `BeagleDoctor` (Floor3/Room1); see the
  [record](TOWN_DESIGN_BRIEF.md#hospital-ward-doctors--1-november-2026).
  *4 Nov 2026:* **Dr. Li** (`Buildings/Hospital/DrLi`, pig plush, doctor outfit, a woman)
  stands **outside**, right of the entrance as you face it, at hospital-local
  (−3.7, 0, −13.9), clear of the canopy post at x −2.35; she runs the family game
  (`family_session.gd`, built 4 Nov 2026;
  [record](TOWN_DESIGN_BRIEF.md#hospital-family-game--4-november-2026)).
- **Waiting room** (`waiting_room()`): two sofas facing over a rug and coffee table,
  an armchair, lamp, magazines, three framed pictures, an aquarium on a
  cabinet, a kids' corner (mat, toy blocks, ball), two plants and a warm light; the
  hall doorway is kept clear.
- **Floor-2 lounge.** The stair-side seating group (sofa, table, armchairs, rug, lamp,
  light) moved into the annex corner, sofa against the annex rear wall; the gallery
  route (z<5) stays clear. Floors 1 and 3 are unchanged.
- **Anatomy model** (`anatomy_model()`, Floor2 at (5.6,0,11.3), facing the hall). A
  friendly child figure: skin, hair and a smile on one half; a soft cut-away on the
  other with pastel lungs, heart, liver, stomach, small and large intestine, a peek of
  brain and one simple leg bone. No skull or veins. Each of its 28 words is its own
  root with a non-solid pick area, so small front parts (eyes, teeth, tongue, fingers,
  toes, knees) win the click; only the plinth is solid. It replaces the outdoor display
  (freed from `RelocatedSites/Hospital`; `vocabulary_completion.gd::anatomy()` removed).
  Words: see [word audit](../archive/WORD_AUDIT.md#body-and-organ-words--31-october-2026).
- **Eaves.** `MainRoof` carries `authored_outline`, so `building_outlines()` skips it; the
  generator authors the main-block eaves and corner posts itself, leaving out the +X eave
  across the open floor-3 annex and the annex corner post inside the stairwell (both
  showed indoors as a brown beam and post).
- Check and views: `docs/evidence/hospital-polish-20261031/verify.gd` (isolated copy, windowed).
- **Wall colours (31 Oct 2026, later).** Every room's inner walls (partitions, door
  header, side and facade window walls) carry its feature-wall colour
  `tint(room,.62)` — reception is soft yellow all round — and the pharmacy's annex walls
  its green. Hall, lounges, lift lobby and the upper-floor annex show `WALL` (`f4f1ea`)
  throughout. These are non-solid `WallSkin` panels from `skin_room()`/`skin_shared()`;
  facades, hall faces and collisions are unchanged. Sofas and wheelchairs are seats
  ([sitting guide](BONBON_VALIDATION.md#sitting-on-chairs-and-benches--28-october-2026)).
  Check: `docs/evidence/hospital-walls-seating-20261031/verify.gd` (isolated copy, windowed), run
  once: 13/13 PASS (doctor 2.34 vs BonBon 2.26 world units; 21 hospital sofa seats, 1
  wheelchair seat; BonBon sat on both). Views in that folder; `sit-wheelchair.png`'s camera
  clips a cabinet. The run also printed GDScript backtraces that the output filter hid;
  not investigated. The older seat suite (`check_seats_and_swan_boats.gd`) was not run.

### Pharmacy, side-tower elevator and roof access — 31 October 2026

The user approved these choices: a side tower for the elevator, a roof parapet as the
exterior improvement, and a pharmacy door opening from the main hall. Everything is authored in
`tools/build_hospital_remodel.py` (regenerate `hospital.tscn`) and
`scripts/world/hospital_elevator.gd`. This section supersedes the elevator position,
the directory alcove and the StairRoof described in the sections below.

- **Exterior.** The coloured facade bars (`accents`) are removed, and the facade
  header is now plain `edf0e8`. A 1.45-high roof parapet with a teal `478e91`
  coping runs around the main roof and the annex roof. The helipad scene's own low
  parapets are deleted from `build_rooftop_assets.gd` and
  `hospital_helipad.tscn`, along with their four stale overrides in
  `town_public_garden.tscn`.
- **Open lounges.** The glass wall between the lounge and the annex gallery
  (side +X, z 8.35) is removed on every floor. On floors 2–3 the lounge now opens
  straight into the annex. Floor 1 keeps only the −X lounge, since the +X side
  became the pharmacy.
- **Pharmacy (floor 1).** It now fills the +X lounge and the annex rear. A glass
  shopfront sits at x=2, with a hinged glass door (`PharmacyDoor`, word `door`) at
  (2,0,5.1), a green cross and a FARMACIA sign on the hall side. Inside: a pale
  green floor, a green feature wall, a counter (computer, medicine, card terminal,
  tray), back shelving with medicine boxes, a wall shelf, a gondola (bandage,
  first aid kit), two waiting chairs, a plant and two ceiling lights.
- **Elevator.** The shaft moved into a new tower outside the −X side wall
  (`LIFT_X=-11.6`). It has a teal cap, floor bands and tan corners, and rises
  `LIFT_TOP=5` above the roof. Its doors open onto a lift lobby where the old shaft
  stood (x −9..−2), and the directory moved to the lobby's front wall. It has four
  stops: `floor_ys` 0, 5.6, 11.2 and 16.925 (`roof_stop`). The roof stop is named
  **A / AZOTEA** and uses the colour `6d8f9c`. A west deck ramp leads from the roof
  landing up onto the helipad.
- **Stairs to the roof.** The same straight flight continues from floor 3
  (rise 16.925−11.2), signed **↑ AZOTEA**. The roof is open over the whole flight
  (TopSlab pieces), so the camera never clips the ceiling. On the roof, a stair
  house (x 5..16.15, z −2..2.75) has a hinged **RoofDoor** on its rear face, an
  ESCALERAS sign, and a rear ramp onto the helipad deck. `MainRoof` stays as a
  hidden, non-solid full-size bounds reference for `building_exteriors.gd`. New
  node names avoid "roof" so `building_outlines()` doesn't add eaves to them.
- `reference_world_layout.gd::location_name()` reports
  "Hospital · Roof · Helipad" above y 16.5.

### Reception and final polish — 27 October 2026

Step 4 of the user's hospital plan. Reception (floor 1, room 1) is now a counter with
a tall wood front, yellow accent stripe, dark kick plate and a visitor ledge, with a
lower worktop and return behind it, a monitor facing the receptionist, three pendant
lights, a wood-slat feature wall with a red cross on a white panel, two plants, and a
single **RECEPCIÓN / BIENVENIDOS** sign. The duplicate wall sign, desk lettering and
separate welcome panel are gone. *(Superseded 31 Oct 2026: the receptionist is now the
sheep doctor.)* A warm
ceiling panel under the roof gives floor 3 the same ceiling as floors 1–2. All of
the reception is authored in `furnish()`; regenerate to change it.

### One room deeper, with a lounge on every floor — 27 October 2026

The user asked for matching footprints on all three floors (the removed rear
extension had made floor 1 deeper) and for the back room that blocked the space
behind the stairs to move. The main block now runs to a rear facade at z=19.9
(`REAR`), 7.7 deeper; the back rooms (Emergency/Examination, 202/Intensive care,
Laboratory/Physical therapy) moved to a new back row at z=16.05 (`BACK_Z`) with
their colours, furniture and displays, and their inner wall now faces the lounge.
The band they left, directly behind the stairs and elevator, is an **open lounge**
on every floor: either side of the hall a floor-tinted rug, sofa, coffee table, two
armchairs facing each other, floor lamp, plant and ceiling light (`lounge()` in the
generator). Sofa, armchair, coffee table and lamp are existing vocabulary props.
The stairs, elevator, annex and front facade are unchanged; the side walls gain a
third window bay and the rear facade matches the front's window rhythm. The rear
now reaches town z≈253.1, inside the land the removed extension used; only the
hospital's own roof-derived outline trims occupy the new volume. Mission targets
follow the moved rooms automatically. The old rear stair sign on the removed
cross wall was dropped; sign layout is reworked in the next step.

### Department displays from the former rear extension — 27 October 2026

The user asked to remove the single-storey extension that sat behind the ground
floor; it repeated four main-floor programs in four extra rooms. It is gone from
the game (prefab, four room scenes and its saved-world overrides), and the rear
wall on floor 1 is now closed. Its 24 vocabulary displays moved into the matching
rooms, generated by `former_wing_displays()` in `tools/build_hospital_remodel.py`:

| Room | Displays |
| --- | --- |
| Floor 1, 2 · Urgencias | stretcher, defibrillator, first aid kit, oxygen tank, syringe, surgical mask (plus the existing stethoscope, thermometer, bed and monitor) |
| Floor 1, 3 · Exámenes | blood pressure monitor, reflex hammer, medicine; the examination bed's sheet teaches **sheet** |
| Floor 3, Imágenes | MRI scanner; computer, clipboard and headphones on a supply table (plus the existing X-ray machine and medical monitor) |
| Floor 3, Fisioterapia | prosthetic leg; bandage and medicine on a supply table (plus the existing wheelchair, crutches and walker) |

The four room missions (Emergency Equipment, Patient Examination, Medical Imaging,
Recovery and Mobility) keep their IDs, words and saved progress; their targets now
come from `HOSPITAL_ROOM_MISSIONS` in `reference_world_layout.gd`, which reads each
room's live position. `docs/evidence/town-checks/check_hospital_departments.gd` verifies placement,
picking, the sheet word and mission reach.

### Colours, floor signs and elevator orientation — 27 October 2026

The user asked for a more modern, colourful and welcoming interior with the layout
and exterior unchanged, the elevator facing the main hall, clear floor signs near
the elevator and stairs, and a nicer, easier staircase. All of it is authored in
`tools/build_hospital_remodel.py` (regenerate `hospital.tscn`) plus
`scripts/world/hospital_elevator.gd`; no runtime pass recolours the hospital.

**Palette.** Walls are warm white `f4f1ea`, floor slabs warm grey `e6e2da`. Each
storey has an identity colour (`FLOOR_TINTS`): **1 teal `2a9d8f`, 2 blue `3d7fc1`,
3 orange `e38b3c`**, used on the hall runner (pale), a wayfinding stripe on every
hall-side partition, the hanging hall sign, stair signs, landings, the elevator
header and its cabin buttons. Every room has its own colour (`ROOM_TINTS`) on its
door header, room sign, pale floor inset and a soft feature wall on its inner wall:

| Floor | Bottom left | Top left | Top right | Bottom right |
| --- | --- | --- | --- | --- |
| 1 | Reception, yellow | Emergency, red | Examination, light blue | Waiting room, green |
| 2 | Room 201, peach | Room 202, lavender | Intensive care, teal | Operating room, blue |
| 3 | Imaging, indigo | Laboratory, green | Physical therapy, orange | Doctors' office, pink |

Facade colours (`accents`, facade bands, sills, annex exterior) are unchanged.
Reception furniture is warm wood; medical stands and counters are light neutral.

**Floor signs** (sign clean-up, 27 October 2026: nothing hangs over the corridors;
every sign is on a wall or painted on the floor). On every floor: **PLANTA n** in
large letters on the floor-coloured elevator header, above the live
**ELEVADOR · n** status; two matching small signs on the stair-front wall,
**ESCALERAS · PLANTA n** and **↑ PLANTA n+1** (2.6 × 0.55, side by side; the top
floor has only the first); a large numeral **arrival sign** on the annex pier
straight ahead at the top of each flight (no "↓" sign beside it); floor-painted
**↑ PLANTA n+1** on the inner landing, on a thin tinted inset above the slab so the
surfaces cannot z-fight; a room-coloured **door plaque** beside every room door,
facing the hall; and the floor **directory** (all four rooms) in the alcove the
elevator used to face. Removed: the hanging hall signs, the green
"ESCALERAS ← → ELEVADOR" directory, the rear stair sign, the "↓ PLANTA" sign and
floor arrow at the stair top, the old CLÍNICA plaque (the only **clinic** word in
town, removed at the user's request), and three unbacked display labels in the annex
gallery (TREATMENT, X RAY, PATIENT CHART; the displays stay pickable). **imaging**
moved from an old plaque, stranded outside after the rear extension's removal, onto
the Imágenes door plaque. The inside faces of the front and rear facade header bands
are wall-coloured so they no longer read as panels at the ends of the hall.

**Elevator.** The `Elevator` node is rotated −90° about Y, so its doors (local
z=−2.61) open onto the hall at hospital x≈−2.9, z=0, across the existing 1-unit
lift-side floor strip. The 5.2×5.2 shaft keeps its footprint and slabs; controls,
obstruction and floor detection use elevator-local coordinates and are unchanged.
The old front lobby (x −8..−3, z −4.5..−2.6) is now the directory alcove. Cabin:
warm walls, darker floor, wood handrails, buttons coloured by floor; steel doors.

**Staircase.** Same walking geometry and collision as below (no route change):
light-oak treads with a contrasting nosing in the destination floor's colour,
destination-coloured side stringers, wood top rails on steel posts, and
floor-tinted landings. A climb from floor *n* is coloured for floor *n+1*.

### Stairs

The usability repair supersedes the compact switchback. Each storey has one
straight flight, x=5..13.4 and z=-1.8..2.4: **4.2 units wide**, 8.4 run, 5.6 rise,
**33.69°** incline, and 28 closed visual treads. The flight is 40% wider than the
superseded 3-unit flight. It uses the existing annex without enlarging the envelope.
Inner and outer landings are 3 and 2.6 units wide. Front approach z=-3.15 and rear
approach z=3.45 connect the hall on all three floors; the rear gallery connects to
the outer landing and returns to the next ascending flight. Follow the PLANTA signs and floor arrow.

A continuous 0.35-thick convex sloped slab supplies collision. Its underside
follows the slope, retaining headroom below the next flight; a full solid wedge
would obstruct the lower flight and must not be substituted. Matching stairs are
5.6 units apart vertically. Slim rails, inset end posts, concealed edge collision,
and guarded upper-floor openings provide safe landings without projecting into
turns. No player shrink, jump requirement, or controller modification was needed.
The existing camera still retracts near walls; testing includes normal W movement,
default camera pitch, off-center lanes, ascent/descent, and both approaches.

### Exterior and surface repair

The prefab owns solid wall openings, framed transparent windows and the restrained
wall cross. `building_exteriors.gd::finish_hospital()` supplies one entrance canopy
and signage, bypassing the generic fake windows, roof crown and duplicate canopy.
Annex windows match the main facade. Continuous annex floor bands close the wall
seams that previously exposed interior rail fragments. Existing streetlight 6 is
moved sideways to clear the entrance sign; its node and children are preserved.
The actual Main geometry is inspected from front, side, rear, hall and stairs using
`docs/evidence/town-checks/inspect_hospital_surfaces.gd`; screenshots are in `docs/evidence/hospital-surface-review/`.

### Elevator mechanics and controls

Since 31 October 2026 the shaft is in the side tower at x=-11.6. It has four stops,
and the keys are **1 / 2 / 3 / 4**, with 4 for the roof. Elsewhere, this section
describes the original placement.
`hospital_elevator.gd` creates an enclosed shaft at x=-5.5, z=0 with landing doors at
elevator-local z=-2.61; since 27 October 2026 the node is rotated so they face the
central hall (hospital x≈-2.9). The cabin is an `AnimatableBody3D`, approximately 4.8 × 5
with a 3.4-high ceiling (since the 10 Nov 2026 rebuild 4.7 × 4.88 outside, 3.8 high inside);
its clear doorway is 3 wide and 3.2 high. Motion updates in physics at 2 town units/second
(eased, up to 3.0, since 10 Nov 2026). Godot's moving-platform support carries the actual
player without teleporting, reparenting or replacing the player controller.

- Click the numbered cabin buttons, or press **1 / 2 / 3** inside. Since 14 Nov 2026 **E** at
  the cabin panel (or on a cabin button) opens the [floor picker](#floor-picker--14-november-2026).
- Click (or E on) a landing call button, or press **E** near its doorway. Since 10 Nov 2026 the
  buttons are ElevatorCallButtons and the car waits 2 s before it leaves (see "Elevator call
  buttons and departure delay").
- Since 10 Nov 2026 (user) the line above each landing door and the display in the car show
  only the number of the stop the car is at or passing (`car_stop()`, e.g. "2", "A"). Contextual control
  hints appear only near the elevator (since 10 Nov 2026 not inside it: the "choose a floor"
  card was removed, user).
- State sequence: open → closing → moving → opening. Cabin and departure doors
  close before motion; only the arrival landing opens. All absent-cabin landings
  remain physically closed. Doors stay open while idle.
- The player capsule obstructing either door plane causes closing to reverse.
  Since 10 Nov 2026 the call is kept and the car leaves 2 s after the doorway clears. Calls during a trip are queued
  without duplicate targets and served after an arrival dwell.
- Normal vocabulary clicks, doors, vehicles and overlays keep their controls.
  Elevator input is ignored when player controls are disabled or in a vehicle.

### Elevator call buttons and departure delay — 9–10 November 2026

A reusable call button, `ElevatorCallButton`
([`scripts/world/elevator_call_button.gd`](../../scripts/world/elevator_call_button.gd), scene
[`scenes/props/fixtures/elevator_call_button.tscn`](../../scenes/props/fixtures/elevator_call_button.tscn)).
Since 10 Nov 2026 (user) `hospital_elevator.gd` builds them itself, so the hospital and the
airport control tower (same script) both have them: one on every landing (`Button<i>` on the
elevator node, on the right-hand door jamb seen from the landing; the old ↑↓ box button and the
call lamp above it are removed) and one per stop on the cabin panel (`Car/Button<i>`: the stop's
number printed on the button, a sky-blue glow `CABIN_GLOW` instead of the landings' amber).
**E** while aiming at a button, or a click on it, calls that stop; **1–4** inside the car and
**E** at the doorway still work. (Since 14 Nov 2026 E on a *cabin* button opens the
[floor picker](#floor-picker--14-november-2026) instead; a click still presses it.)

- **Look** (10 Nov 2026 rebuild). A round ivory push button in a steel bezel with a halo ring;
  lit, the face and the ring take the glow colour. The caption is printed on the face; without
  one (landings) the face shows ▲▼. A landing button sits on its own brushed-steel plate.
- **Exports.** `elevator` (NodePath), `floor_index`, `caption` (printed on the face; empty =
  ▲▼ marks), `glow_color` (default amber `ff9a2e`), `glow_energy`, `light_energy` / `light_range`
  (a small OmniLight3D, hidden while dark; 0 = emission only), `idle_color` (face, ivory
  `e9e7e0`), `mark_color` (print), `plate_color` (steel `c3c7c9`), `plate_size` (0.3 × 0.5;
  `Vector2.ZERO` = no plate, for a button on a shared panel), `button_radius` (0.085); since
  14 Nov 2026 `pick_size` (click box; zero = plate or 2.8 r square) and `picker_on_e` (E opens
  the elevator's floor picker; a plate-less button picks through an `Area3D`). It works
  with any node that has `call_elevator(i)` and `is_floor_requested(i)`.
- **State.** The glow is never stored: every frame the button reads
  `hospital_elevator.gd::is_floor_requested()` (queued, or the target until the car arrives). So
  the landing and cabin buttons of a stop light together, whatever made the call; they go dark
  the moment the car arrives, do not light for the car's current floor, and a press while the
  stop is already called adds nothing. Signals `pressed(floor_index)` and `lit_changed(lit)` are
  there for sound later.
- **Departure delay.** After a floor is chosen the doors stay open `DEPART_DELAY` = 2 s (state
  `WAITING`) before closing, so a rider can choose a floor, step out and send the car on alone.
  Someone in the doorway when the wait ends holds the car open until the doorway is clear; if
  someone steps in while the doors close they reopen and the call is **kept** (it used to be
  dropped) and the car leaves 2 s later. A call for the floor where the car still stands (landing
  or cabin button, while it waits or closes) works like a door-open button: the 2 s start again
  and closing doors reopen, instead of the car leaving and coming back (user, 10 Nov 2026). Queued stops are served after the 1.5 s arrival dwell
  plus the 2 s wait.
- **Review changes (10 Nov 2026, user: "make all the improvements").**
  - *Doors* stood half underground (each leaf's centre at floor level, so a closed landing was
    open above ~1.6 m): `box()` now sets `sync_to_physics` and the position before the body
    enters the tree. Doors are two-speed (a centre and a slow panel per side, 5.6 cm apart) so
    open panels stack behind the jambs instead of sticking out of the tower's free-standing
    shaft; brushed steel with a centre seam.
  - *Signs*: the number above each door and in the car show only the car's stop (`car_stop()`).
    Short headers (tower top) use smaller title and number so they no longer overlap; tall ones
    (tower lobby) keep the title just above the number instead of up by the next level.
  - *Motion*: eased, `ACCEL` 3.5, `MAX_SPEED` 3.0 (was a constant 2.0): one hospital floor
    ~2.7 s, floor 1 → roof ~6.5 s. A called floor the car is about to pass (with room to brake)
    becomes the next stop; the trip's target is queued first. No 1.5 s dwell before a queued
    stop (only its 2 s wait).
  - *Cabin* (panel layout and display superseded by the rebuild below): the panel moved to the inside of the front jamb beside the door (columns as fit:
    hospital 2 × 2, tower 1 × 3, floor 1 at the bottom) with the number display above it; a
    ceiling light panel (emissive, no extra light), a brushed back panel, steel kick plates and
    a floor mat 3 cm up (the control room carpet crossed the tower shaft 2.2 cm above the car
    floor and showed through).
  - *Hint*: a dark card under the clock, scaled with the window (min(h/800, w/1100)); it used to
    sit over the minimap at a fixed size.
  - *Sound-ready signals*: `doors_opening(floor)`, `doors_closing(floor)`, `departed(from, to)`
    beside `arrived(floor)`.
- **Rebuild (10 Nov 2026, user: "fix the flicker… obvious gaps… the elevator and the buttons
  look bad").**
  - *Flicker*: the tower's lobby plinth (top 3.6 cm up) and floor crossed the shaft level with
    the car's floor, so the car floor and mat fought with them. The car's floor finish is now
    `FINISH` = 5 cm above its collision floor (the player's feet sink 5 cm, not noticeable); the
    landing threshold and car sill are level with it. Shaft parts no longer share planes with each
    other: side and rear walls are one piece each from floor 1 to the top, plus a cap; each
    stop's door wall (jambs, and the floor-tinted header up to the next stop) ends flush with the
    side walls and changes 1 cm below each floor level (a floor slab's top there flickered with
    the header's). A coplanar-face scan (the finder of `docs/evidence/coplanar-scan-20261110/`,
    filtered to elevator parts, both units loaded) went from 37 elevator pairs to 0.
  - *Gaps*: the old walls stopped 20 cm short of every floor (a slot round the shaft); the car's
    side walls cut 4 cm into the shaft's, and the car had no wall above its door (the shaft showed
    through). The car is now 1 cm clear of the shaft (`cw()` = shaft − 0.3, `cd()` = shaft −
    0.32), 3.8 tall inside (`CAR_H`) with a full front wall: two jambs and a header.
  - *Number display*: one dark display with the amber stop number, centred above the door inside
    the car, and above each landing door under the floor title (both only the number).
  - *Cabin panel*: one brushed-steel strip on the inside of the right-hand front jamb, the
    buttons in a single column (floor 1 at the bottom), each with a small floor-colour tag.
  - *No "choose a floor" card* in the car (user); the landing call hint stays. The phrase
    `elevator.inside` in `data/phrases.json` is no longer used.
  - Handrails stand off the walls on brackets; light panel, back panel and kick plates fit the
    taller car.
  - *Control tower*: the shaft is wider and fills its alcove (user). It was 3 × 3, 1.3 clear of
    the stair wall; airport bake step `widen_tower_elevator` makes it 4.24 wide (doors 2.2, leaf
    1.1), from the room's east wall (2 cm, as before) into the stair wall. The empty level's
    floor (16.5) and the control-room slab (22) are cut back to the new shaft (the slab split in
    three), the empty level's front strip now meets the door wall (it stopped 6 cm short), and
    the two control-room displays on the shaft's west face moved 1.24 west with it.
- **Pressing while the car moves; click and E; tower lobby flicker (10 Nov 2026, user).**
  - Every button takes a press while the car moves (the stop is queued, or becomes the next stop
    if the car can still brake for it), by **E** on the button or a **click**; checked in the real
    game with clicks sent through Godot's input on the landing button and a cabin button mid-trip.
  - In the control tower the clicks and E aimed at the lobby call button hit an invisible wall:
    the "Void guard" that closed the old alcove beside the lift, left 20 cm in front of the
    widened shaft. Airport bake step `remove_tower_void_guard` removes it. The elevator's own
    click ray now takes the pointer as the interaction controller does (screen centre while the
    view is dragged).
  - The flicker in front of the tower lift was the camera, not the lift: in that 4.6-deep lobby
    the third-person spring arm rests on the back wall, its shape cast is only accurate to about
    1/256 of its length, and `player_controller.gd` fed each result into the next cast, so the
    camera bounced ~2 cm every frame and every edge shimmered (measured: ~1150 changed pixels
    between still frames, 0 after). While blocked, arm changes under `ARM_SETTLE` (0.08) are now
    skipped; the camera still stops at the wall and eases out as before. This steadies the
    camera in any tight room.
- **Building.** The button's parts are internal children with scene-local materials and the
  elevator's own children are not saved by a bake, so no unit scene stores them.
- **Checks and views.** `docs/evidence/elevator-call-button-20261109/verify.gd` (runner id
  `elevator_call_button`, full suite: both elevators, the delay, stepping out, the doorway hold;
  since the rebuild also the car's clearance, the display above the door, no card in the car and
  the tower shaft meeting the stair wall);
  `docs/evidence/town-checks/check_hospital_remodel.gd` and `docs/evidence/control-tower-20261029/verify.gd` were updated for
  the delay and the new buttons. `capture.gd` renders the hospital landing dark / lit, close-ups
  at noon and evening, the cabin buttons, the car's front wall with its display, the tower lobby
  button and the widened tower shaft (PNGs in the same folder).

### Floor picker — 14 November 2026

User request: **E at the cabin panel** opens a floor-selection close-up, like the electrical box
([ELECTRICAL_BOX.md](ELECTRICAL_BOX.md)). Same code in the hospital and the control tower; built
at runtime, so no unit was rebaked. Files: [`scripts/ui/elevator_floor_picker.gd`](../../scripts/ui/elevator_floor_picker.gd)
(the overlay and the camera), `hospital_elevator.gd` (`cabin_panel`, `panel_size()`,
`open_floor_picker()`, `panel_view_transform()`), `elevator_call_button.gd` (`pick_size`,
`picker_on_e`, `pick_extent()`); wired in `minigame_wiring.gd` (`PANELS` entry
`elevator_floor_picker`: Esc and the player lock) with a `main.elevator_floor_picker` field.

- **Opening.** The cabin panel is an interactable (`prompt_distance` 4.2, reach measured at the
  player's height, no aim needed): E facing it opens the picker, as does a click on the steel
  between the buttons. **E while a single cabin button is aimed at also opens the picker** (it
  does not press that button): `picker_on_e` buttons check `Input.is_action_pressed("use")`,
  which only E and the touch E button hold. A **click or tap on a cabin button still presses it
  directly**, without the picker. Landing buttons and keys 1–4 are unchanged.
- **Close-up.** A temporary camera glides (0.6 s) from the player camera to straight in front of
  the panel (it fills 72 % of the view height); the player model hides past 55 % of the glide.
  On screen: the HUD hides (`hide_for_game`, reason `elevator_picker`), a teal ring marks each
  floor button, and a slim bottom bar shows `elevator.choose_floor` and a ✕ (52 px × scale),
  scaled with min(h/800, w/1100).
- **Choosing.** A tap or click inside a button's projected pick box presses that button
  (`ElevatorCallButton.press()` → `call_elevator()`), then the camera glides back (0.5 s) and the
  player is free. A tap outside the panel, the ✕ or Esc (popup stack) closes it without a call;
  a tap on the panel between buttons does nothing.
- **Car moving.** While the picker is open the player stays locked; if the car moves (an earlier
  call) the close-up follows the panel every frame, and choosing queues the stop as usual.
- **Bigger direct targets.** A cabin button's pick box is 1.5× wider (0.294 instead of 0.196,
  `CABIN_PICK`); its height is clipped to the 0.22 button pitch less 4 mm (0.216, ×1.1), so
  neighbouring targets never overlap. Cabin picks (and the panel's) are `Area3D`s
  (`monitoring` off): clicks and taps find them, the player never collides with them. Landing
  picks stay `StaticBody3D`s over their plates.
- **Checks and views.** `docs/evidence/elevator-call-button-20261109/verify.gd` covers the picker (E via
  focus, E on an aimed button, open/lock/Esc stack, close-up camera, large separate targets,
  outside tap, Esc, ✕, floor choice and ride, the moving car, a direct click, 1.5× ray hits,
  the tower). Views: `docs/evidence/elevator-floor-picker-20261114/capture.gd` → `hospital-picker.png`,
  `tower-picker.png`.
- **Open.** The HUD corner buttons (language, settings, ▶, journal) stay visible and clickable
  during the close-up, as with the electrical box. Not tried on a real touch device.

### Open-source adaptation and license

Source: [Yni-Viar/advanced-elevator-system](https://github.com/Yni-Viar/advanced-elevator-system),
Godot 4 implementation, pinned revision
`273438265a4879f9d78759d8db1d5dd8ee24e367`.
Inspected `src/Scripts/ElevatorSystem/ElevatorSystem.gd` and `ElevatorFloor.gd`.
The adaptation retains the floor-target / physics `move_toward` motion and
close-before-travel / open-at-destination design. It specializes the multi-waypoint
implementation to three vertical stops and replaces its player-specific bindings,
animation assets and audio with this project's primitive architecture, moving-body
collision, floor buttons, obstruction handling and input rules. No upstream models,
textures, player controller, plugins or runtime package dependencies were imported.

The repository's **MIT License**, copyright 2024–2026 Yni-Viar, permits modification
and distribution and does not require relicensing this game. Retain the complete
notice in [advanced-elevator-system-LICENSE.txt](licenses/advanced-elevator-system-LICENSE.txt)
when distributing the adaptation. The source header records attribution.

### Ownership and preservation

- `tools/build_hospital_floors.py` delegates hospital generation to
  `tools/build_hospital_remodel.py`; its `--school` branch remains unchanged.
  Regeneration overwrites `scenes/buildings/hospital.tscn`, including the retained
  helipad instance at (-1,16.925,-1). Preserve editor changes before regenerating.
- The active `town_public_garden.tscn` had baked overrides masking the prefab.
  Only obsolete hospital floor/shell override blocks and their obsolete editable
  paths were removed. The hospital root, learning-wing and helipad override blocks,
  unrelated sites, and all existing resource definitions are retained.
- `world_refinements.gd::remodel_hospital_displays()` runs before compact relocation.
  It moves the old shaft-overlapping display cluster rigidly into the annex and
  remounts patient-room/pharmacy signs; children, collisions, metadata and keys stay
  with their existing roots and paths.
- `reference_world_layout.gd::location_name()` uses 5.6-unit floors and the new
  programs; Main's fallback names also reflect the program.
- Vocabulary dictionaries, aliases, catalog, save identity, controls, bed asset and
  helipad/vehicle assets are unchanged. All 21 distinct word keys
  found in the retired floor overrides are still represented in the hospital.

### Verification and screenshots

Use the README's isolated-save configuration. Commands (from project root):

```sh
godot --headless --path . --fixed-fps 60 --script res://docs/evidence/town-checks/check_hospital_remodel.gd
godot --headless --path . --fixed-fps 60 --script res://docs/evidence/town-checks/check_hospital_departments.gd
godot --path . --fixed-fps 60 --script res://docs/evidence/town-checks/check_hospital_stair_access.gd -- --capture
godot --path . --script res://docs/evidence/town-checks/inspect_hospital_surfaces.gd
godot --path . --resolution 1440x1100 --script res://docs/evidence/town-checks/check_hospital_remodel.gd -- --capture --capture-only
```

`check_hospital_remodel.gd` loads actual Main, walks the real player through all
rooms, stairs and gallery, rides and exits every elevator floor, checks floor
keys/buttons/hall calls, obstruction reversal and absent-cabin doors.
`check_hospital_departments.gd` checks the 24 department displays, their picking,
the sheet word and the four room missions. Since 31 October 2026 it also covers the
pharmacy door and counter, the open lounges, the roof stairs, the roof door,
parapet, ramps and the AZOTEA elevator stop. The obsolete `check_hospital_floors.gd`
was deleted that day. It tested the superseded switchback routes and the
pre-resize school stairs, and failed on every run. Git history keeps it.

**Verification budget.** For a hospital change, run the two headless checks above
once, then render one batch of views. `check_hospital_stair_access.gd` is graphical
and flaky whenever any other Godot window is open, at HEAD as well. Run it only when
the stair geometry or the camera changes. Run it once, alone, and record the
result; don't keep re-running it. Each run loads the whole town, which takes minutes.
The route/elevator suite drives velocity directly for deterministic coverage.

Colour/signage review views (elevator from the hall, stair bottom/top, alcove
directory, patient room, floor halls), before and after:
`godot --path . --resolution 1200x900 --script res://docs/evidence/hospital-colours-20261027/capture.gd -- [--before]`,
images in `docs/evidence/hospital-colours-20261027/`. `check_hospital_remodel.gd` locates elevator
walking points with `lift_point()` in elevator-local coordinates.

Rendered cutaways: [Floor 1](../evidence/hospital-remodel/floor1.png),
[Floor 2](../evidence/hospital-remodel/floor2.png), [Floor 3](../evidence/hospital-remodel/floor3.png).
Also: [stairs](../evidence/hospital-remodel/stairs.png), [elevator](../evidence/hospital-remodel/elevator.png),
[entrance](../evidence/hospital-remodel/entrance.png). These are actual Godot Main renders with
upper floors/roofs/exterior facade hidden for inspection, low wall-cut proxies and
English annotations. The elevator is parked at each pictured floor; gameplay signs
are Spanish. The inspection visibility changes are not saved to the game.
See `FINAL_VERIFICATION.md` for dated results and remaining limits.

## Historical implementation — superseded

> Historical implementation record. Use the [documentation map](../README.md)
> for current guides; positions, counts and test results below describe this snapshot.

The editable `scenes/buildings/hospital.tscn` now contains three furnished floors and an enclosed switchback stairwell on the east side. It continues to instance the existing rear medical learning wing at its original ground-floor position.

- Ground / Planta baja (1): reception, urgent care, consultations and nursing, with access to the rear emergency, examination, imaging and rehabilitation learning rooms.
- Floor 2: pediatrics, cardiology, children's consultations and diagnostics.
- Floor 3: patient rooms, rehabilitation, rest and physiotherapy.

Floor colors, overhead department arrows, stair directions and landing directories support navigation. The HUD identifies the current hospital floor. Reused medical furniture keeps its vocabulary interaction metadata.

Stairs have visible treads, solid guards and handrails. Hidden continuous ramp collision underneath the treads allows the existing player controller to climb without step-handling or jumping. Floors leave the stair flights open, with half landings between storeys.

`tools/build_hospital_floors.py` is the reproducible scene authoring source. Running it overwrites `hospital.tscn`; preserve any manual editor changes before regeneration. The old runtime hospital decoration pass is skipped for this scene to avoid duplicate interior objects.

Validation: `docs/check_hospital_floors.gd` drives the actual player up both storeys, enters upper-floor rooms, checks floor labels, and descends to reception. Run with `--headless --fixed-fps 60`. Add `-- --capture --capture-only` in graphical Godot for screenshots in `docs/evidence/hospital-review/`. Existing civic-expansion tests cover the unchanged learning-wing connections and all 48 school/hospital displays.

Second design pass: larger two-line direction signs, an exterior all-floor directory and entry canopy, four waiting chairs, an L-shaped reception desk, ticket dispenser, window mullions and protective corridor rails. Department-specific details include the pediatric reading corner and alphabet mural, cardiology ECG artwork, bedside storage and medical outlets, and rehabilitation parallel bars with gait markers.
