# Architecture review — Part 1

Reviewed October 20, 2026. The assessment and verification below record Part 1,
before visual changes. Current additions: [Part 2](../evidence/part2/HANDOFF.md),
[final checks](FINAL_VERIFICATION.md), and the current editing rules at the end
of this document. Start with the [README](../../README.md) for the live entry point.

**Current sections (contents added 18 Nov 2026; nothing moved):**

- Rules: [world and asset workflow](#world-and-asset-workflow),
  [coordinates, roads and visual standards](#coordinates-roads-and-visual-standards),
  [vocabulary data procedure](#vocabulary-data-procedure),
  [vocabulary usage report](#vocabulary-usage-report), [maintaining these docs](#maintaining-these-docs).
- Structure: [architecture and ownership](#architecture-and-ownership) (its "Active world" row;
  the rest of the opening assessment is dated history),
  [interaction system](#interaction-system), [clickable word items](#clickable-word-items--9-november-2026),
  [saved place and respawn](#saved-place-and-respawn), [naming](#naming-16-nov-2026),
  [welcome tutorial](#welcome-tutorial).
- Learning: [practice tracker](#practice-tracker), [vocabulary book](#vocabulary-book),
  [zones](#zone-boundaries--stage-1-inspection-28-october-2026),
  [category and area journal](#category-and-area-journal--stage-2-28-october-2026).
- Per-feature ownership sections (dated) are listed with their feature in the
  [documentation map](../README.md#current-guides-where-to-make-decisions).

## Assessment and scope

The existing Godot architecture is suitable for targeted world improvements. No
runtime refactor is justified before Part 2: useful boundaries and geometry helpers
already exist, and extracting another layer would increase regression risk without
resolving the main problem, which is knowing which authored snapshot owns a change.
No scripts, scenes, assets, data, interiors, transforms, or project settings were
intentionally changed. Updated the README's stale world entry point and added this
handoff. The existing helicopter inertia test also rewrote its own
`docs/guides/helicopter_inertia/test_results.txt` with the current baseline result.

## Architecture and ownership

| System | Current owner and contract |
| --- | --- |
| Entry and orchestration | `project.godot` → `scenes/app.tscn` (`scripts/core/app.gd`, since 12 Nov 2026: splash, profiles, staged loading; [README](../../README.md#web-app-pwa)) → `scenes/main.tscn` → `scripts/core/main.gd`. Main wires world, player, HUD, progress, vehicles, shared door state and the shop minigame sessions (`make_shops()`). **Since 7 Nov 2026** (last modular-town restructure step) Main keeps its public methods and fields but delegates the bodies to static helpers: `scripts/core/minigame_wiring.gd` (every shop/minigame session and panel, their Esc entries, Settings refresh and control lock: add a new minigame there), `scripts/core/vehicle_controls.gd` (boarding/exits, zoo and farm gates, the Home garage door and roof), `scripts/core/door_animator.gd` (door states and animation) and `scripts/world/room_names.gd` (`current_room()`). Missions/quests were removed 3 Nov 2026; mentions of them below are historical. |
| Active world | **Since 6 Nov 2026: the [modular town](MODULAR_TOWN.md).** Main instances `scenes/town/base.scn` as `Apartment`, scaled uniformly by 1.3; `modular_town.gd` adds the building units of `data/buildings.json` (`scenes/town/<unit>.scn`, only the focused ones with `dev_focus.txt`). Before that: `scenes/world/town_public_garden.tscn` plus the startup passes; both, and the one-time full bake, were deleted on 6 Nov 2026 (git history, `a5059dd`). Buildings change through their unit scene or own script `scripts/buildings/<unit>.gd` + `tools/bake_unit.gd` ([how](MODULAR_TOWN.md#changing-a-building)). |
| Construction | `main.gd::build_world()`: load the units into the base (`modular_town.gd`), restore doors, `reference_world_layout.gd::restore()`, translate signs. Runtime code finds a building with `modular_town.gd::building(town, unit, part, below)` (null when dev focus leaves it out), never by spelling its node path ([address book](MODULAR_TOWN.md#finding-a-building-at-runtime)). The older construction paths (`bind()`, the startup passes, `house_builder.gd` / `town_builder.gd`) were deleted on 6 Nov 2026. |
| Older generation | Deleted 6 Nov 2026 with the old saved worlds (`town_complete`, `town_reference`, `town_public_garden`, `town_editable`); see git history. `natural_town_layout.gd` remains as a landscape helper library for own-script steps. |
| Layout and terrain | `data/reference_layout.json` defines site sources/targets, spawn and bounds; `reference_world_layout.gd` restores the baked layout (site pivots and bounds, roads, map entries and details) and answers site lookups (`site_at`, `location_name`, `world_point`, `bounds`); its relocation pass was deleted 6 Nov 2026. `natural_town_layout.gd` provides `smooth`, `surface`, `patch`, and `ribbon`. |
| Geometry | Main provides cached materials/box meshes and `box`, `sphere`, `cylinder`; bakes save identical materials once in the shared [material palette](MODULAR_TOWN.md#material-palette), so change a material found on a town node only after `duplicate()` (its unused `piece`, `add_ceiling_light` and the original neighbourhood builders were deleted 6 Nov 2026). Local world helpers add coordinate conversion or different collision semantics; superficially similar helpers are not all duplicates. |
| Rendering | Godot Compatibility renderer, Main daylight/environment, `garden_rendering.gd` runtime MultiMeshes and `shaders/garden_water.gdshader` (translucent lagoon over the sunken bed; see [public garden](public-garden/README.md#lowered-lagoon-bridge-clearance-and-water--28-october-2026)). Batching hides source meshes but preserves collision and vocabulary roots. `editing_snapshot` skips runtime batching. |
| Animals | `scenes/animals/*.tscn` supplies reusable models; saved world nodes contain transforms and child overrides. `park_animals.gd` owns bounded wandering, capturing its starting position as `home`. Species display sizes are `park_animals.gd` `ANIMAL_HEIGHTS` / `SMALL_ANIMAL_LENGTHS` (the zoo is saved at them in `base.scn`). |
| Player and vehicles | `player_controller.gd` owns movement/camera/jumps/seating; `bonbon_effects.gd` owns effects. `driveable_vehicle.gd` owns road/flight physics and safe exits; permanent vehicle-door assemblies and legacy model partitioning are owned by `vehicle_door.gd`/`vehicle_doors.gd` ([guide](ZOO_VEHICLE_IMPLEMENTATION.md#integrated-vehicle-doors-and-warehouse-box-truck--5-november-2026)); `zoo_gate.gd` owns gate animation. Main routes input and registers vehicles/gates. |
| Road dynamics (22 October replacement) | `road_vehicle_physics.gd` owns tire/suspension loads, drivetrain forces, yaw, wheel animation and unsupported recovery. The shared vehicle controller retains boarding/exits and full-body swept queries. [Road vehicle guide](ZOO_VEHICLE_IMPLEMENTATION.md) owns profiles, source attribution, controls, limits and checks. |
| Helicopter dynamics (22 October replacement) | `helicopter_physics.gd` integrates rotor forces and body inertia through the existing vehicle contract; `DriveableVehicle` retains swept collision queries, rotor visuals and exits. [Current rotor guide](helicopter_inertia/README.md) owns dimensions, controls, upstream license, limitations and acceptance checks. |
| Fixed-wing aircraft (21 October addition) | `turboprop.gd` extends `DriveableVehicle`; the world refinement pass installs its prefab on the existing runway. Main reuses vehicle registration/E handling; Player animates the visible pig into `PilotSeat`. [Aircraft guide](aircraft.md) owns controls, dimensions, physics and upstream license attribution. |
| Interaction and learning | `interaction_controller.gd` resolves physics hits to vocabulary roots and emits `word_studied`, and since 12 Nov 2026 runs the [interaction system](#interaction-system) (Interactable components, one focus target with the "E" badge, input claims); Main updates progress and animates doors. Dictionary, categories and aliases live in `data/`; `learning_catalog.json` describes prefab vocabulary, dimensions and categories. |
| UI and persistence | `vocabulary_hud.gd` and `town_minimap.gd` consume game/map state. `vocabulary_progress.gd` preserves save format and normalizes aliases. Keep application name and canonical keys stable. |
| Authoring and history | `tools/` contains builders/bakers; `docs/` contains checks and historical reports. `backups/.gdignore` excludes archived resources from Godot. No AGENTS.md was found in the workspace search. |

## Issues identified, deliberately not rewritten

- Main (1,028 lines) still mixes orchestration, geometry, location rules and older
  construction routines; TownBuilder (1,069 lines) is also large. Existing focused
  controllers make the requested changes possible without splitting either file.
- Coordinates and scales exist in JSON, procedural passes, prefab resources and
  baked overrides. A global scaling configuration would not automatically update
  baked instances. Changing only a generator may have no effect in the live scene.
- Construction is order-dependent and depends on node names and metadata.
  `bind()` and `build()` have distinct responsibilities; do not rerun relocation on
  an already relocated town or remove guards to force an update.
- Road ribbons and pedestrian connections are authored curves, not a connectivity
  graph. Check joins, height, collision and vehicle clearance after future edits.
- Eight cached category tags and 40 cached Spanish tags disagree with current data
  across `town_reference.tscn` and `town_public_garden.tscn`. Runtime study cards use
  the dictionaries, but editor/export consumers can see stale tags. Do not change
  translations or keys as part of aesthetic work.
- Historical tests and documents assume older counts, geometry or resource IDs.
  The broad Python checker includes backups and cannot reliably resolve inherited
  scene parents; its reported errors are not equivalent to Godot loading failures.
- No package manager or external runtime dependency layer needs simplification.
  Existing prefab and procedural ownership should be preserved until a particular
  Part 2 edit demonstrates a concrete need for extraction.

## Verification performed before documentation edits

Godot 4.7.2, headless, fixed physics FPS 60. Python checks used the bundled Python
runtime because `/usr/bin/python3` requires unavailable Xcode command-line tools.
Godot used a temporary project configuration linking unchanged project resources.
Its custom learner-data location was separate from the real save location; sandbox
permissions prevented creation of that directory. Certificate lookup also emitted
the existing host error. Save persistence and graphical rendering were not verified.

| Check under `docs/` | Observed result |
| --- | --- |
| `check_runtime_resources.gd` | 304 scenes/scripts loaded; zero failures. |
| `check_interaction.gd` | Passed picking, highlights, cards, signals, doors, dismissal and range. |
| `check_bonbon.gd` | Zero failures. |
| `docs/guides/performance/check_rendering.gd` | Zero failures; runtime batching, map rebuilding and door restart checks. This is not rendered visual QA. |
| `check_public_garden.gd` | Zero failures; 2,004 path samples; bridge crossed in both directions. |
| `check_zoo_vehicles.gd` | 67 checks; 20 failures in flight/movement/exit assertions. The existing public-garden report documents the same count and failure class. No gameplay code changed during this review. |
| `docs/guides/helicopter_inertia/verify.gd` | 15 checks; one failure: wind-driven drift respects the full rotor collision envelope. Treat this as an unresolved baseline issue, not a verified-safe collision system. |
| `check_vocabulary_categories.py` | 103,963 checks; eight stale cached categories; 502 words, 168 catalog entries, 271 scenes. |
| `check_vocabulary_translations.py` | 40 stale scene translation tags. |
| `check_zoo_vehicles.py` | 78 checks; two failures: assumes 500 words and literal helicopter script ID `drive_script`. Current dictionary has 502 words; helicopter attaches the driver with ID `1_ms1o8`. |
| `check_food_shopping_vocab.py` | 345 checks passed. |
| `check_transport_navigation_time.py` | 505 checks passed. |
| `check_project.py` | 2,997 reported errors; includes inherited-parent, dynamic-path and load-step flags and scans archives. Not used as the runtime loading verdict. |
| Main-scene smoke run | Completed 120 headless iterations, exit 0; 1,831 garden meshes in 174 batches. Only the user-data-directory and certificate host errors noted above were logged. |

Logs are in `/tmp/spanish-part1/` for this session. No export build, manual keyboard/
mouse playthrough, visual-quality inspection or full historical-suite run was done.
No post-refactor test run is needed because no runtime refactor was made.
After the documentation edits, SHA-256 comparison confirmed all 436 captured files
under scripts, scenes, assets, data, shaders and tools plus `project.godot` were
unchanged. README/report relative links were checked successfully.

## Part 2 Handoff

| Target | Files and reusable systems |
| --- | --- |
| Road connectivity | `reference_world_layout.gd::rebuild_ground_and_roads()`, `connect_sites()`, `ribbon()`; `natural_town_layout.gd` curve/mesh helpers; `reference_layout.json`; active saved road overrides and `reference_road_points`/`reference_road_width` metadata. Garden paths are in `public_garden.gd::path()`. |
| Washington | `scenes/layout/washington_statue.tscn` is the base; `public_garden.gd::equestrian_statue()` and `statue_garden()` add/pose horse, rider and surroundings. Inspect the active `WashingtonStatue` instance overrides before changing the prefab. |
| Snake | `scenes/animals/snake.tscn`; both saved reference and garden worlds contain `ParkZoo/Snake` overrides, including `BodyPath`, `BodyContinuousCoil`, materials and body details. Prefab edits alone may be masked. |
| Animal scale | Inspect prefab dimensions, each saved animal transform and the parent 1.3 scale together. The active snake's local basis scale is about 0.499861. Keep feet at ground level, update collision/picking bounds as needed, and retain wandering origins and habitat clearance. |
| General aesthetics | Reuse existing geometry/material helpers, terrain ribbons and garden batching. Preserve `word_key`, `vocabulary_root_path`, door metadata, collision bodies and map tags. Batches assume stationary primitive meshes and simple materials; reassess eligibility if new materials or animation are introduced. |

Coordinate constraint: layout points are town-local; canonical image-west is -X,
but the baked scene has `reference_west_positive_x=true`. Use
`reference_world_layout.gd::world_point()` (garden wrapper `w()`) and proper
`to_global`/`to_local` conversions rather than applying another reflection or scale.
Moving whole site pivots preserves building interiors.

Regeneration constraint: `bake_public_garden.gd` starts from `town_reference.tscn`
and overwrites `town_public_garden.tscn`; it does not preserve arbitrary edits made
only in the latter. `bake_reference_world.gd` starts from `town_complete.tscn` and
overwrites the reference snapshot. Main currently runs garden/home passes during
construction, so do not assume that rebuilding the reference snapshot produces an
untouched pre-garden source. Compare outputs in a temporary copy before replacing
either authored world. No bake was run for Part 1.

For Part 2, resolve the intended source of each change first, then make small edits
and rerun resource, garden, interaction, rendering and relevant vehicle checks.
Keep the existing vehicle and rotor-clearance failures visible when comparing
results. Current passing checks establish a useful baseline, not a clean full suite.

## Current editing rules (Parts 2–3)

The [latest town design brief](TOWN_DESIGN_BRIEF.md) owns approved future building
programs. Existing rooms/routes below describe current implementation and remain
protected during exterior-only work; they are not permanent school/hospital/market
design requirements when a separately scoped future redesign is approved.

### Approved school and supermarket dimensions — 25 October 2026

`world_refinements.gd` now applies `resize_school()` / `resize_supermarket()` before
`building_outlines()` and facade generation, in the original saved source frames.
`compact_town()` then performs its existing rigid site transforms. Site/prefab roots
are not scaled or relocated by resizing. The dimension guards require a fresh Main
run; do not clear them to reapply edits. Saved editor scenes retain their old shells.

School's runtime `ApprovedShell` and `RetainedLearningObjects` replace the old
floors/wing; keep the `Buildings/School` root stable. Separately baked school props
and NPCs need coordinated preservation. `reference_world_layout.gd::relocate_quests()`
uses surviving classroom positions without changing mission IDs/words/saves;
`location_name()` recognizes the one-story school. Market shell box resources are
duplicated before resizing; its saved non-uniform part scales are reset explicitly,
while all inventory/display roots keep their original scale and transforms.

See [exact dimensions and scope](BUILDING_DIMENSION_REVIEW.md#implemented-resize--25-october-2026)
and `docs/check_building_dimensions.gd` (retired 7 Nov 2026, see [building access](FINAL_VERIFICATION.md#snapshot-checks-retired--7-november-2026)) for pre-resize fingerprints, retained keys,
real-player capsule routes, mission-range selection, foundation support and guards.
The baseline JSON is dated pre-change evidence, not a golden file to regenerate
from current code just to clear failures. Facade bounds remain in their original
frame: tests must transform rays through each facade, not through town alone.

### Supermarket exterior ownership — 25 October 2026

`building_exteriors.gd::decorate()` selects `finish_market()` only for the
supermarket. The school follow-up adds its own `finish_school()` branch. Shared
`building_part()` / `building_lettering()` (formerly `market_part()` /
`market_lettering()`) transform building-local points into the pre-compact facade
frame, so `compact_town()` and facade picking keep their existing contract.
`finish_market()` adds non-solid skin/framing/canopies, locally overrides the roof
and selected frontage materials, and hides only superseded non-learning ornament
meshes. Do not remove the original collision/interaction trees. Existing window,
sign, cart, planter and inventory roots retain their transforms and metadata.
Glazing panels are opaque stylized surfaces over unchanged physical walls.
See [the current exterior review](TOWN_DESIGN_BRIEF.md#supermarket-exterior-review--25-october-2026).

`docs/check_supermarket_exterior.gd` (retired 7 Nov 2026, see [building access](FINAL_VERIFICATION.md#snapshot-checks-retired--7-november-2026)) compared against its own pre-exterior baseline,
including other facade appearances and the school, all 301 market components,
market collision transforms/shapes, learning roots, display appearance, missions,
door count and the existing parked-truck clearance pattern. Do not regenerate its
baseline from the new implementation to make a failed comparison pass.

### School exterior ownership — 25 October 2026

Interior preservation statements in this dated exterior record precede the
[26 October single-divider change](#school-single-divider-ownership--26-october-2026).

The single-story school selects `building_exteriors.gd::finish_school()` instead
of the generic multi-floor facade. Its original `ApprovedShell`, `MainRoof` and
`RetainedLearningObjects` remain unchanged; all new surfaces live in the separate
`Map facades/SCHOOL` tree. Classroom-side frames follow the existing glass bands.
Front glazing overlays the entry walls; it does not cut new physical openings.
The compact clock, canopy, apron and planting stay below the original roof height
and outside the full 3.6-wide entry. No collider or provisional interior is edited.

The existing building-frame helpers now have generic names `building_part()` and
`building_lettering()` for two actual users: market and school. The math and market
output are unchanged. `prepare()` returns early only on explicitly tagged
`skip_exterior_pick` decoration, used by new school planting/apron; these have no
Area/body or vocabulary key. Existing untagged picking behavior is unchanged.
See [current school result](TOWN_DESIGN_BRIEF.md#school-exterior-review--25-october-2026)
and `docs/check_school_exterior.gd` (retired 7 Nov 2026, see [building access](FINAL_VERIFICATION.md#snapshot-checks-retired--7-november-2026)) for exact before comparisons, including the
school's complete core visuals, collision shapes, site props, people/mascots and
all other building facades. Dated exterior baselines protect their own snapshots;
the older supermarket test's school-appearance assertions describe the pre-school
facade and should not be treated as today's appearance acceptance gate.

### World and asset workflow

1. Identify the owner: prefab, saved instance override, generator, or runtime pass.
   The active chain is saved public garden → bind reference layout → guarded
   garden/home builders → `world_refinements.gd` → UI → garden rendering. A prefab
   change can be masked by an override; a generator change can be skipped by a
   baked-content guard. Play Main to check the actual result.
2. Reuse a suitable existing prefab or Main's `box`, `sphere`, `cylinder`
   and cached materials. For terrain/paths use `natural_town_layout.gd`'s curve,
   ribbon and surface helpers. Python authors can reuse `tools/scene_writer.py`;
   the vocabulary generator has its own metadata/bounds-aware writer. Inspect
   generators before invoking them: several overwrite inventories, data or scenes.
3. Keep model-local geometry beneath a stable object root. Moving that root must
   move mesh, collision and interaction together. Use descriptive names for new
   parts and existing snake_case filenames. Do not rename existing path-dependent
   nodes casually. Preserve the row/column convention when writing `.tscn`
   transforms; verify a rotated/scaled example in Godot rather than transcribing
   a GDScript Basis blindly (Part 2 corrected this issue in tiger cylinders).
4. For a new building/site, reuse the building and vocabulary prefab systems,
   choose a clear plot, preserve its interior coordinate frame and provide a
   collision-free entrance. Coordinate the saved instance/pivot with
   `reference_layout.json` site definitions, layout binding/classification,
   map labels, `current_room()` and quest relocation where applicable. JSON edits
   alone do not move the current baked world. Compare runtime map and walking
   routes before accepting a placement. Do not move existing buildings as a side
   effect of adding content.
5. For a new animal, start with a suitable `scenes/animals/` model, retain its word
   root/Area and optional `park_animals.gd` behavior, and add an appropriate display
   target in `world_refinements.gd`. That pass currently selects ParkZoo animals by
   node name. Preserve foot contact and `home` after scaling/repositioning; allow
   for the wandering radius when checking habitat/fence/path clearance. Mascot
   characters outside ParkZoo use their own scene conventions.
6. For interactive objects, reuse an existing vocabulary prefab's Area/shape and
   metadata rather than a new input handler. Use `word_key` on the object root;
   persisted collider references use `vocabulary_root_path` (a relative NodePath),
   while runtime builders can use `root` references. `exterior_word` takes picking
   precedence on building surfaces. Solid objects also need appropriate physics
   bodies; an Area alone provides selection, not movement collision. Door leaves
   must retain their registry/`door_state` data and moving colliders.

### Coordinates, roads and visual standards

**Current layout — 23 October 2026:** the compact redesign supersedes the older
21–22 October placement descriptions below. `reference_layout.json` retains the
saved snapshot's original `sites` table and adds `compact_layout`: rigid source /
target points and yaw angles in **town-local +X west / +Z north** coordinates.
`world_refinements.gd::compact_town()` applies these after facades, animals and
planting, before UI/vehicle registration/batching. Do not replace the original
site table with final positions: binding and mission transforms still need the
snapshot's source frames. Do not rebake the world as part of a routine edit.

The loop spans x=-112..103 and z=65..200 (215 × 135), with 16-unit corner radii;
road/sidewalk widths remain 10.8/16. The inner park is approximately 199 × 119.
The lagoon, bridge and statue keep their geometry and frames. Wildlife moves
southeast, the farm/barn southwest, playground northwest and chapel northeast;
restaurants, library, police and home form the southern frontage. West/east shops
face inward. All buildings retain scale. Detailed placement belongs to the JSON,
not a second coordinate inventory in documentation.

The final pass moves associated pivots, buildings, facades, trim, parking stripes,
people and vehicles together, updates animal wandering origins and aircraft
recovery pose, rebuilds road arrays/entrance ribbons, republishes map bounds and
site bounds, and leaves mission relocation to Main's existing post-build step.
Wildlife and farm children remain under `ParkZoo` to preserve existing gate and
animal bindings. Coastal ground meshes/collisions compress only the empty north
and south margins; landscape trees are retained and relocated to clear habitats
and trails. The existing refinement guard covers the entire operation; restart
Main to preview changes. Opening the saved world alone still shows the old layout.

`public_garden.gd::refresh_walks_and_boats()` owns the final canonical-coordinate
walking routes. The lagoon loop remains intact; the monument ring, outer walk and cross-paths
now follow the [4 November aerial reference](public-garden/README.md#boston-inspired-garden--4-november-2026). Destination branches and
outer entrances follow the compact placements. `docs/evidence/town-checks/check_compact_layout.gd`
checks structural invariants, while the existing Part 2 and garden checks cover
road/path collision clearance. See the [dated verification](FINAL_VERIFICATION.md#compact-town-redesign--23-october-2026)
and [rendered overview](../evidence/part2/compact-overview.png).


The [building design blueprint](BUILDING_DESIGN_BLUEPRINT.md) defines the shared
building art direction, proposed dimensions, building identities and improvement
sequence. Use it for design briefs; the technical ownership and preservation rules
in this guide still apply. Its proposed targets are not current-world measurements.

- Model coordinates belong to the prefab; layout points are town-local; physics
  and cameras often require global coordinates. Use `to_global` / `to_local`.
  Apartment multiplies local distances by 1.3. Canonical reference coordinates
  use image-right +X and north +Z; the current reflected town uses west +X.
  `world_point()` converts according to `reference_west_positive_x`.
- `reference_layout.json` contains the map bounds, site definitions and reference
  image parameters. Canonical map bounds are `Rect2(-198,-42,402,387)`; reflection
  changes the X origin to -204. These are map extents, not an enforced world fence.
  `from_pixel()` currently hardcodes the corresponding 0.3 factor and (627,1080)
  origin plus Z offset 6: changing only JSON's pixel parameters is insufficient.
- Inspect `RelocatedSites`, `Buildings`, `ParkZoo`, `WashingtonStatue`, `Airport`,
  `Barn` and `Restaurants` for current placement; avoid duplicating a coordinate
  inventory in prose. Main's saved player position is replaced by its spawn logic (and, for a
  profile, by its [saved place](#saved-place-and-respawn), 14 Nov 2026).
- Main road width is 10.8 local units, airport access 9, refined parking drives 6.8.
  Pedestrian paths are narrower and remain distinct. Width changes must preserve
  road metadata, mesh, collision and map footprints. End connections inside an
  existing surface, use smooth turns, avoid coplanar overlaps and test clearance
  across both lane sides. Roads serving a parking pad or building may terminate
  there; runway endpoints are intentional, not missing streets.
- The [saved town map](design-references/town-map-blueprint.png) is the requested blueprint for future
  development. The 21 October road pass in `world_refinements.gd` uses
  `blueprint_loop()` before `connect_parking()`: a rounded rectangular loop spans
  town-local x=-112..103, z=30..225 with 20-unit corner radii, retaining the 10.8
  road width and 16-unit sidewalk ribbon. `blueprint_parking()` adds eight front
  lots to the five existing pads (13 total), stripes bays with a clear 8-unit
  center aisle, and connects them plus the home garage using 6.8-unit drives.
  Existing structures, door positions and vehicles are not moved. Map road arrays
  and detail references are refreshed when replaced geometry is freed.
- `building_outlines()` adds non-colliding eave and corner trim from existing flat
  roof bounds, including civic wings, shops, airport, restaurants, chapel, gazebo
  and barn. This historical outline pass gave the then-open-top home wall caps; the current home also has the later decorative lifting hip roof. This is a basic
  outline pass, not a facade redesign; no shared prefab or saved world is rebaked.
  The existing refinement guard still requires restarting Main after edits.
- After outlines, `building_exteriors.gd::decorate()` adds the map-inspired facades
  under `Apartment/Map facades`. It reuses the existing exterior picking helper,
  Main's material/box helpers, actual roof bounds and instance material overrides.
  It does not replace prefab geometry or physical roof/door collisions. Its own
  group guard prevents duplicate decoration. Features and scope are listed in the
  [building blueprint](BUILDING_DESIGN_BLUEPRINT.md#town-map-blueprint).
- Use stylized, readable primitive geometry, matte color materials, warm stone/
  wood, muted vegetation and coherent asphalt. Reuse the existing palette before
  adding colors/textures. The game's interior lighting and existing daylight are
  shared constraints; verify interiors before changing global lighting/exposure.
- The 21 October outdoor polish also belongs to `world_refinements.gd`:
  `outdoor_materials()` overrides specific ground/road/path meshes and garden tree
  visuals, without mutating shared prefab materials. `garden_planting()` uses the
  existing tree prefab, sphere helper and landscape ovals under
  `PublicGarden/Town planting`, before garden batching. Its fixed seed and
  clearance checks currently yield six beds and three accent trees. The existing
  `world_refinements` guard covers this work too; restart Main to preview changes.
  See the [dated handoff addition](../evidence/part2/HANDOFF.md#town-appearance-polish--21-october-2026)
  for rendered evidence and verification.
- The runtime park trail centerlines are owned by
  `public_garden.gd::refresh_walks_and_boats()`, called before garden planting and
  batching. The 22 October blueprint pass replaces the saved walking ribbons and
  their validation metadata together; see the [garden guide](public-garden/README.md#central-trails-matched-to-blueprint--22-october-2026).
  Edit that runtime route list for the active game, not only `build()`'s historical
  bake layout. The existing guard requires restarting Main.
- Central animal dimensions live in `ANIMAL_HEIGHTS` / `SMALL_ANIMAL_LENGTHS`;
  see the Part 2 handoff for measured examples. The mouse's 0.22 local height is
  the current smallest land-animal target, not a global minimum for every prop.
  Fish/turtle use length; giraffe stays taller than tiger/elephant. Other props
  should remain recognizable from the usual camera and within the interaction
  controller's 8-unit normal / 40-unit exterior world-space picking limits.
  Raise small inventory items on displays rather than enlarging an entire room.
- Building/vehicle proportions come from their existing scenes and must keep
  doorways, seating, wheel contact, safe exits and paths usable. Avoid nonuniform
  root scaling of a building/interior or vehicle just to fix one detail.
- Garden batching only handles suitable stationary BoxMesh/SphereMesh decorations.
  Preserve hidden source nodes, vocabulary Areas, colliders and map tags. Complex
  materials, animation or altered batching eligibility need a rendered regression
  check; headless success does not establish lighting or material quality.

### Vocabulary data procedure

**One source per kind of text, one reader** (4 November 2026). Every word and sentence
the player reads in a taught language lives in data and is read only through
`scripts/language/lexicon.gd` (`Lexicon.shared()`):

| File | Holds |
| --- | --- |
| `data/languages.json` | the known languages (display name, rules module) and which is `native` (translations, help) and `foreign` (taught) |
| `data/words.json` | every listed word: display `text` per language, its `tier` (1–4, how early a learner meets it; `Lexicon.tier(key, lang)`, [draft 24 Nov 2026](../game/minigames.md#word-tiers)), optional grammar `forms` (below) |
| `data/phrases.json` | every sentence and button label, grouped by feature; id `group.key` (`shop.success`), one line per language |
| `scripts/language/rules_<code>.gd` | one per language, extending `language_rules.gd`: grammatical forms, numbers, money amounts, list joining |
| `data/language_samples.json` | human-checked expected outputs of the rules and of every grammar phrase, per language |
| `data/names.json` | personal names for generated characters, per language and gender (`Lexicon.names()`); not vocabulary |

**What counts as a word.** *Listed words* are a finite set of things in `words.json`, and
each needs an object in town (rule below). *Generated language* is endless and comes from
the rules modules instead: numbers (`number_words`), money amounts (`money_words`; the
"$147.38" digit form stays in `currency.gd`) and, later, dates. Generated language has no
object and no journal entry. Months are listed words (twelve, with a poster object). Words
with no natural object get a teaching poster: the family, month, before/after and
older/younger words are on four school posters (saved in the school unit; their builder `school_posters.gd` was deleted 6 Nov 2026 with its last caller, see git history and the
[design record](TOWN_DESIGN_BRIEF.md#hospital-family-game--4-november-2026)); each poster word
is its own root with its pick area, and its label text comes from the Lexicon.

**World labels that follow the Display Mode** (the L toggle until 7 Nov 2026). `scripts/language/live_labels.gd` binds a
Label3D to a text reference instead of fixed text: `{"word": key, "form": "label",
"gender": "f"}`, `{"phrase": id, "values": {...}}` (a value may itself be a reference), and
`"in": "other"` for the other taught language. `Lexicon.text(ref, lang)` renders one.
Main's `language_changed` handler calls `LiveLabels.set_language()`: English mode shows the
native language, Foreign mode the foreign one (the same rule as signs). A bound label
with a fit width shrinks when a translation is longer. The `label` form is how a word is
written on a card: "la prima" in Spanish, "cousin" in English. The school posters use it;
any new world text that should switch languages should bind the same way.
**Hold-to-peek (user decision, 9 Nov 2026).** Holding L (Main `_unhandled_input`) or the
HUD's native-badge button left of the gear (`peek_button`, for touch) sets
`GameSettings.peeking`; `world_language()` then names the native language and Main's
`apply_world_language()` re-renders signs and bound labels until it is released. It is not
a Display Mode: it is never saved, does not change cards or practice recording, and the
button is hidden in Native mode. Since 17 Nov 2026 (user) it is the one language toggle for
the dialogue box too: while it is held the box (`shop_order_panel.gd`) shows its lines in the
native language (`translation_shown("")` marks the open question translated), and the box's
own translate bubble is gone. Since 23 Nov 2026 (user: "two EN buttons" on the mahjong table)
every panel's bubble is hidden too: `translate_button.gd` stays invisible and, while EN is held,
presses itself so its panel (mahjong, lessons, money, family, restaurant and menu book, flight,
mystery, detective, warehouse, outfit picker) switches language, and again on release; a card
opened while EN is held opens in the native language. Panels that follow `peek_changed`
themselves (the dialogue box, the grammar card) set `follows_peek = false`. Check:
`docs/evidence/one-language-toggle-20261123/verify.gd`. The HUD ends a peek whose release was missed
(neither key nor button held).

**World signs in every taught language (user decision, 9 Nov 2026).** `data/sign_translations.json`
keys each sign by its English text with `{code: text}` for every other playable language
(it was English → Spanish only). `sign_language.gd` treats a Label3D as a sign when its authored
text is a key or any translation (the hospital, zoo, vehicle and poster signs were authored in
Spanish), keeps the authored text in `sign_source` (bake_unit restores it) and shows
`GameSettings.world_language()`. `_glosses` are poster meaning lines (always the native
language), `_pairs` poster titles ("foreign  ·  native"), `_nodes` resolves one authored text
two keys share by node path, `_same` lists names and codes that read the same everywhere.
Runtime-written labels (the elevator) set meta `sign_dynamic` and call `SignLanguage.say()`.
A new sign needs a table entry in every playable language; `docs/evidence/signs-20261109/verify.gd`
(full suite, `signs`) fails on any visible Label3D that is not covered.

**Game code never holds taught-language text and never joins words into a sentence.**
A sentence is a phrase; a phrase that needs grammar asks for it with `{slot:form}` (for
example `{clerk:definite}` gives "el vendedor" / "the salesperson") and names the word
category that may fill the slot in `"slots"`. Plain `{name}` takes a string, a
language → text dictionary, or a word reference `{"word": key, "gender": "m"}` (its
display text). Shop and cashier rules (clerk node, zone, NPC gender) are in
`data/shops.json`; `shop_dialogue.gd` only adds shop-specific fillers.

**Grammar forms.** `words.json` `"forms"` is per language and needed only by words that
fill a `{slot:form}`; the shape belongs to the language's rules module (documented at
the top of each `rules_<code>.gd`). Spanish: `{"m": "vendedor", "f": "vendedora"}` for a
person, `{"noun": "persona", "gender": "f"}` (plus `"article"` for exceptions such as
*el agua*). The display text must equal what the forms make; the check enforces it. English
builds every form from its text and needs no forms. The 12 People and 19 person words of
the Family category have Spanish forms.

**Check:** `godot --headless --path . --script res://tools/language_check.gd` (seconds, no
town, no saves). It fails on: a language without a rules module or with an
unimplemented function; a word or phrase missing a language; forms that are malformed or
disagree with the text; placeholders that differ between languages; a `{slot:form}` whose
form is unknown or whose slot category has a word that cannot make it (rendered for both
genders); any sample that differs or a missing sample section / grammar-phrase sample;
taught-language letters (á, ñ, ¿, …) or glued articles (`"the " +`) in `scripts/` code
outside the rules modules. Known scheduled exceptions are listed, with reasons, in its
`CODE_EXCEPTIONS`. It ends with a per-language coverage report.

#### Adding or changing a language

1. Add the code to `data/languages.json` (`name`, `badge`, `rules`) and a
   `language.<code>` phrase (its name in every language, for Settings). `native` /
   `foreign` there are only the defaults: the player picks both for a new profile and in
   Settings (4 Nov 2026, the profile's `settings.json`); nothing else needs editing if the
   check passes. A playable language becomes a pill on the new-profile language page
   (`app_screens.gd`, since 18 Nov 2026: its round `flag` from `bon_style.gd` (`flag_<id>`
   SVG; add one for a new flag) and the English `language.<code>` name).
   That page and the other screens before the town show in the `native` default, English
   (14 Nov 2026), which is also what a new profile starts with.
2. Write `scripts/language/rules_<code>.gd` extending `language_rules.gd`; override every
   function and document its `forms` shape at the top.
3. Add the language's `text` to every word in `words.json` and its line to every phrase in
   `phrases.json`; add `forms` for the words in grammar-phrase slot categories if the
   rules need them.
4. Add a `<code>` section to `data/language_samples.json` with every section (numbers,
   numbers_before_noun, money, forms, phrases) and a sample for every grammar phrase,
   checked by a speaker of the language.
5. Add at least `min_per_gender` names per gender to `data/names.json`.
6. Run `python3 tools/word_data.py` and `tools/language_check.gd` until both are clean.

A language that is still being written carries `"status": "draft"` in `languages.json`
(Traditional Chinese, `zh`, was one from Stage 4b until it became playable on 4 Nov 2026; no
language is a draft now). Both checks then validate the text it has
(placeholders, forms, samples for the grammar phrases it has) and report what it lacks
instead of failing; `Lexicon.playable_codes()` leaves it out of Settings, and a saved draft
choice falls back to the defaults. Remove the status when every word and phrase has a line.
Chinese kinship words carry `forms.zh.terms`, a list of `{"when": kin details, "text"}`
chosen by `rules_zh.gd` from the family tree's `kin()` (see the family game record).

A language may add `"reading"` in `languages.json`: a data file its rules module turns into a
pronunciation line shown under the foreign text (`Lexicon.reading()`, `GameSettings.reading()`;
none in Native only). Chinese uses `data/pinyin_zh.json` (Stage 4c, 4 Nov 2026): `chars` gives
each character's default pinyin, `words` whole words (neutral tones, characters with several
readings, capitals), and the zh names in `names.json` read as one word. Because pinyin is made
from the text, generated numbers and names get it too. The line appears under the dialogue
box line, the family question, the money request and the word card; buttons, titles and world
signs have none. When Chinese text gains a character, add it to `chars` (and a `words` entry
if its reading differs there): the language check fails on a character without a reading,
and the `readings` samples in `language_samples.json` pin down the spacing and capitals.
Every pronunciation line goes through `scripts/ui/pinyin_text.gd`: `PinyinText.style(label)`
when the label is built, then `PinyinText.show(label, line)` when it is drawn. It gives the line
Noto Sans SemiBold (`fonts/NotoSans-SemiBold.ttf`, SIL Open Font License), because the built-in
Open Sans lacks the third-tone letters ǎ ǐ ǒ ǔ ǚ and ǖ ǘ ǜ (user decision, 4 Nov 2026: this
line only; the rest of the interface keeps the built-in font). Use it for any new pinyin line.
Chinese characters themselves come from a fallback font (13 Nov 2026, needed by the web build,
which has no system fonts): a Noto Sans TC subset of the characters in the data and scripts. When
Chinese text gains a character, also run `python3 tools/build_cjk_font.py`
([web app](../../README.md#web-app-pwa)).

Adding a new **form** (possessive, plural, …): add it to `FORMS` and a function in
`language_rules.gd`, implement it in every rules module, add samples; the check fails
until each language has it.

**Joins after filling** (5 Nov 2026, Warehouse Phase 5). `Lexicon.phrase()` passes every
phrase with filled slots through the rules module's optional `polish(text)` (default: no
change). Spanish writes the compulsory contractions there: *de el → del*, *a el → al*
(*Saca la botella del contenedor azul*, *Ve al estante B*). Prefer ready-made noun phrases
(`warehouse.thing_*`) over a `{slot:form}` when a whole category could not supply the form;
`language_samples.json` pins the contractions (`warehouse.task_*` rows).

**Not yet covered (Stage 1 of the language work, 4 November 2026).** Still English- or
Spanish-specific, scheduled for later stages: HUD and journal text and the
English/Spanish/Both language cycle (`vocabulary_hud.gd`), the word card's English line
(built from the key in `interaction_controller.gd`), sign text (`data/sign_translations.json`
and the lettering listed in `CODE_EXCEPTIONS`), and the derived `catalog` field name
`spanish` (both readers keep it for existing checks). Old one-off generators
(`tools/build_learning_assets.py`, `tools/expand_civic_wings.py`,
`tools/add_vocabulary_articles.py`) still write the retired `"spanish"` field and must be
updated before reuse. Non-Latin scripts would need a fallback font.

**`data/words.json` is the only word source** (28 October 2026). It replaced
`vocabulary.json`, `vocabulary_categories.json`, `vocabulary_aliases.json` and
`learning_catalog.json`, and scenes no longer cache `english` / `spanish` /
`category` metadata: a scene node stores only its `word_key`.

| Part of `data/words.json` | Schema / responsibility |
| --- | --- |
| `categories` | category name → one-line rule for what belongs there. The order is the order of the file's word groups. 19 categories (Travel added 28 October 2026 for the airport) |
| `aliases` | legacy/synonym key → existing word key; aliases are not extra words (old saves and scenes) |
| `removed_with_objects` | deleted words whose tagged objects the game removes from town at load (`world_refinements.gd::apply_word_list`) |
| `words` | key → `{"text": {code: display text, …}, "forms"?: {code: {…}}, "category", "prefab_size"?, "picture"?, "note"?, "sold_in"?}`. `"picture": false` (23 Nov 2026) means no [word picture](#word-pictures). The key is a permanent id (saves use it), not display text. One line per word, grouped by category. Until 4 Nov 2026 the Spanish was a `"spanish"` field |
| `about` | short description of the file |

A word may also carry `"sold_in": [store ids]` (3 Nov 2026): the stores whose customer-order minigame can ask for it (the 80 supermarket products use `["supermarket"]`). `tools/word_data.py` validates it (list of unique non-empty strings) and `word_data.gd` exposes it as `sold_in`. Adding a product to a store's orders means adding the store id; the object must also exist inside the store's zone to be clickable into the cart.

`data/sign_translations.json` (world sign text in every taught language, see
[world signs](#vocabulary-data-procedure)) is separate: signs are not
vocabulary. See [Spanish signs](spanish-signs-20261027/README.md).

Readers: the game uses `scripts/learning/word_data.gd::load_all()`, which derives
the same `vocabulary` / `categories` / `aliases` / `catalog` dictionaries the code has
always used from the shared Lexicon (`vocabulary` is the display text in the foreign
language of `languages.json`). Python tools and checks use `tools/word_data.py` (`load`, `save`,
`vocabulary`, `categories`, `catalog`, `problems`). Never write those derived
dictionaries back to separate files.

To add, edit or delete a word:

1. Search `words.json` (words and aliases) and the [word audit](../archive/WORD_AUDIT.md)
   first. Prefer the existing concept to a duplicate synonym. Keys are lowercase
   English words with spaces (`tiger`, `kitchen table`).
2. Edit only `words.json`: Spanish and category together; pick the category whose
   rule fits (add a category only with a rule, and keep the set small). Give
   **one** primary translation in everyday Mexican Spanish (A2/B1 level) with its
   article; never list regional alternatives (Spain, South America) and do not give
   two English words the same Spanish. Use ` / ` only for the masculine/feminine
   forms of a person (`el niño / la niña`) and for genuinely different senses such
   as `el pez (animal) / el pescado (comida)`. Directions/adverbs take no article.
   Decisions and flagged ambiguities: [word audit](../archive/WORD_AUDIT.md#one-mexican-translation-per-word--28-october-2026).
   `prefab_size` only for generated learning prefabs. Add `"picture": false` when the word's
   town object makes a poor [word picture](#word-pictures) (a blank board, a plain slab).
3. Run `python3 tools/word_data.py`: it validates (unknown category, missing
   Spanish, broken alias, empty category) and re-formats the file.
4. To show the word in town, give a prop a `word_key` and a clear picking shape.
   The By Area journal picks it up automatically from where it stands.
5. To delete a word, remove its line and either strip its `word_key` tags from scenes
   (the object stays as decoration) or list it in `removed_with_objects` (the object
   is removed at load). To rename, add an alias from the old key.
6. Body-part and organ words (`BODY_WORDS` in `world_refinements.gd`) are taught only
   by the hospital anatomy model (Floor 2, [hospital guide](HOSPITAL_THREE_FLOORS.md#polish-floors-reception-waiting-room-anatomy-model--31-october-2026));
   `apply_word_list` strips them from people and animal figures before freeing
   retired words, so people keep their (retired-word) torsos. Hover glow: buildings
   (`exterior_word`) and anything longer than `LARGE_HOVER_EXTENT` (8 world m: roads,
   big surfaces) show the label but no overlay (`interaction_controller.gd::glows()`). Every tree crown has a standable, clickable platform
   (`standable_tree_crowns`); clouds already have platform collision.
7. Run `tools/vocabulary_report.gd` ([usage report](#vocabulary-usage-report): unplaced words, unknown keys, duplicates),
   `check_vocabulary_categories.gd` / `.py`, `check_vocabulary_translations.py`,
   `check_vocabulary_aliases.gd`, resource loading and the picking checks for
   affected objects.

### Vocabulary usage report

**7 Nov 2026 (Stage A of the vocabulary tracking work; replaces `docs/word_audit.gd`).**
`tools/vocabulary_report.gd` loads the whole town once (headless, isolated `HOME`,
`VT_FOCUS=all`) and lists every word of `data/words.json`:

- **where it is placed:** objects with a `word_key` / `exterior_word` meta per building unit
  (`data/buildings.json` parts, else `base`) and site (town zone), split into *saved* (from
  the saved scenes) and *runtime* (built by scripts at load); world labels bound to the word
  (`live_labels.gd`); and *clickable* objects (the journal's By Area index);
- **which games test it**, as game ids from `data/activities.json`, following decision 6
  (user, 7 Nov 2026): the shop order item (`sold_in`), the family relative
  (`family_tree.gd` `WORDS`), the restaurant dish, the warehouse item (`warehouse_goods.gd`
  `_item` calls), the flight question's time word (`flight_questions.gd` `DAY_WORDS`, `PARTS`,
  `WEEKDAYS`, `HOUR_WORDS`) and destination country, and the noun of a Chinese measure-word
  question (`grammar_lana`; only the Chinese bank has nouns), and the evidence game's property
  word (`evidence_mimi`, since its redesign of 8 Nov 2026: `detective_game.json` evidence clue
  `words`);
- **which games only show it:** restaurant properties, the police lineup and the evidence
  game's object nouns (two clue words a lineup round, so not tracked), the family game's month and weekday words and the flight board's
  weekday and month words (the day column and the calendar; since 8 Nov 2026 the session also
  tracks the target day's weekday, which this report does not list as tested yet);
- **phrase slots:** the `slots` categories of `data/phrases.json` it can fill. Dialogue words
  written as plain text are not matched.

It prints a `FAIL:` line for every hard error: a word key in game data, the town, a label,
an alias, a phrase slot or the clickable index that `words.json` lacks. `-- --write` also
refreshes `docs/guides/vocabulary-report/report.csv`, `summary.md` and, since 16 Nov 2026, the game
guide's per-game word list [`docs/game/words.md`](../game/words.md) (the only files it writes;
`report.csv.import` sets Godot's importer to `keep`, since Godot otherwise imports any `.csv`
as a game translation table). **The report updates itself** (user decision, 8 Nov 2026): the
runner check `vocabulary_report` (full suite) runs with `--write`, and the files are rewritten
only when their content changed (a new date alone is not a change) and only when there is no
hard error, so a run on a partial town (`dev_focus.txt`) never writes. When the check's details
say `VOCABULARY REPORT FILES: updated`, commit the two files with the change that caused it.
Unplaced words, objects without pick collision, duplicates (an alias that is also a word,
singular and plural, the same text twice in one language) and `removed_with_objects` words
still placed are report-only. A new minigame that tests or shows words adds its source to
`_game_words()`; its next full-suite run refreshes the report.

### Practice tracker

**7 Nov 2026 (Stage B of the vocabulary tracking work; user decisions 7 Nov 2026).** The
learner's progress stays yes/no ("studied" once an object is clicked). Separately,
`scripts/learning/practice_log.gd` (`PracticeLog.shared()`) counts how each **tested** word
was answered, per learned (foreign) language and game:
`user://practice_log.json` = `{language: {word key: {game id: {positive, negative, translated}}}}`
(learner data: tests use an isolated `HOME`). Word totals are sums (`totals()`), never stored.
Old saves start at zero. Read it with `games_for(language, key)` / `totals(language, key)`.

**Interface for a minigame** (game ids are `data/activities.json` ids):

| Call | When |
| --- | --- |
| `begin(game_id, word_keys)` | a new question with its tested word(s); an open question is abandoned first |
| `first_answer(correct)` | every answer; only the first per question counts. `correct` is a bool, or `{key: bool}` when one question tests several words (a shop order) |
| `complete()` | the question's result is final: records one outcome per word, then the question is closed (later calls change nothing) |
| `abandon()` | quit, walked away, game closed, language changed: records nothing |

**Rules.** *Translated* = the native meaning of a tested word was shown before `complete()`:
the translate bubble on screen (`translate_button.gd` emits `translation_shown("")` for
every word of the question, deferred and only while the bubble is visible, so a panel that
keeps its bubble on marks the next question too), the word card of that word opening
(`translation_shown(key)`; since 21 Nov 2026 the card has no bubble of its own, holding the HUD's
peek badge or L adds the native word to it), or Native mode switched on mid-question. Otherwise the
first answer decides positive / negative; `complete()` without an answer records nothing.
A question begun in Native mode records nothing. Games never call `mark_translated()`.

**Tracked questions** (decision 6): shop order items (`shop_session.gd`: an item is right
when the first Done misses none of it; complete on success, reveal or declined retry), the
family relation question's relative (`family_session.gd`; other family questions are not
tracked), the restaurant order's target dishes (`restaurant_session.gd`, since 11 Nov 2026:
the tablet opens the question with every course asked, one Send answers each dish, ending the
game abandons an open order), the
warehouse task's thing (`warehouse_session.gd`: tasks that name a thing; colour tasks name a
box by its place and are not tracked; any wrong attempt before the task is done is a wrong
first answer), the flight question's time word and destination country (`flight_session.gd`,
redesign of 7 Nov 2026: `flight_questions.gd` `time_key()` is the tested expression's word
key: a day word, a part-of-day word, a weekday, *hace / dentro de una hora*, the day word of a
clock question; *hace / dentro de 2–3 horas* have none; the country only when the question
names it. On the first tap the time word is right when the tapped flight fits the expression,
`time_right()`, for a clock question its day; the country when it goes there; since 8 Nov 2026
day, part and clock questions about a day other than today also record that day's weekday,
right when the tapped flight leaves that day, `WEEKDAY_TRACKED`; a country-less question on a
board with arrivals records *to arrive* / *to depart*, right when the tapped flight goes that
way), and the grammar class's Chinese
measure-word noun (`grammar_session.gd`: questions with a `noun`; the submitted desk is the
answer and completes the question; an unanswered question records nothing unless the
translation was shown; ending the class abandons), and the police evidence game
(`police_detective_session.gd`, since its redesign of 8 Nov 2026: one property word decides
each round, so each round is one question on that word; the first answer counts, the solved
round completes it, leaving abandons). **Not tracked:** cashier (money), the grammar class's
Spanish and English questions, flight clock times, and the police lineup. **The lineup is
deliberately untracked** (user decision, 7 Nov 2026): each round names two clue words and the
answer is a suspect, so no single word can be credited or blamed (the
[usage report](#vocabulary-usage-report) lists its words as "shows"). Option (b) of that
decision, rounds decided by one clue, was taken for the evidence game on 8 Nov 2026; for the
lineup the options remain, **not approved**: (a) credit both clue words of a round (noisy, but
`begin()` already accepts several word keys); (b) the same redesign. A new minigame with one clear tested word calls the four functions above, adds
its source to `tools/vocabulary_report.gd` `_game_words()`, and adds its readable name
`games.<activity id>` (es / en / zh) to `data/phrases.json` for the
[vocabulary book](#vocabulary-book)'s detail view; the `vocabulary_book` check fails for an
activity without one.

Check: `docs/evidence/practice-log-20261107/verify.gd` (runner id `practice_log`): every grocery
example row on the tracker, Native mode, a language change, several words and the saved
file, then each wired game in the town. Stage C reads these counts in the
[vocabulary book](#vocabulary-book).

### Vocabulary book

**8 Nov 2026 (Stage C of the vocabulary tracking work; user decisions 7 Nov 2026).** The J
journal's body is `scripts/ui/vocabulary_book.gd`, hosted by `vocabulary_hud.gd`
(`toggle_journal` / `render_journal` hand it the studied words, dictionary, categories, areas
and the HUD's `bookmarks`). The journal window, its title, the **By Category / By Area**
buttons (now section headings of the table) and the hint stay in the HUD.

- **Rows:** every word of the dictionary (not only discovered ones, which changes the
  [Stage 2](#category-and-area-journal--stage-2-28-october-2026) discovered-only list):
  ★ | foreign | native | studied ✓ | right | wrong (since 23 Nov 2026 a picture column after ★:
  [word pictures](#word-pictures)). The ★ toggles the existing bookmark
  (`vocabulary_hud.gd` `toggle_bookmark()`, saved at once to `VocabularyProgress.BOOKMARKS_FILE`;
  the card star uses the same function).
- **Filters:** All / Studied / Saved (the bookmarked words; the game calls them "saved"),
  search in either language (case and Spanish accents ignored), category, sorting (foreign
  A–Z, native A–Z, most right, most wrong; sorting is inside each section). Area sections
  repeat a shared word and show found/total. **Show / Hide scores** hides the studied, right
  and wrong columns only. The state stays while the journal is closed.
- **Detail view** (click a row; ← Back or Esc returns, Main's popup stack watches it):
  studied, right, wrong and translated totals, then one row per game that has a record,
  named from `data/phrases.json` `games.<activity id>` (a new tracked game needs one; an id
  without a name shows the id). Pinyin under the word when Chinese is learned. The detail
  always shows its numbers, also with scores hidden.
- **Data:** read only. Counts are `PracticeLog.shared()` of the current foreign language;
  word totals are sums of the per-game counts. The book never records or writes practice.
- **Speed:** virtual rows: only the rows that fit are controls (about 20), reused while
  scrolling. Measured with 781 words: rebuild 3.5 ms, scroll step 0.3 ms.
- **Scale:** window and fonts follow min(height / 800, width / 1100); buttons 44 px × scale.
  All text is in `data/phrases.json` (`journal.*`, `games.*`).

### Word pictures

**23 Nov 2026 (user decision: the in-world word card stays text-only, since the object is right
there; pictures go where the object is not).** `scripts/ui/word_pictures.gd` (Main's
`word_pictures`, `WordPictures.shared()`) draws a word's own town object into a 128 px
transparent picture, at runtime, so a picture always matches what the player clicked and the
project ships no image files. It shows in the journal (a picture column after ★, and big in
the detail view) and on the [results screen](MINIGAMES.md#results-screen) word rows.

- **Source:** `area_vocabulary.gd` `targets` (word key → every target carrying it,
  interactables included). Only the target's meshes are copied into a SubViewport (no scripts
  run, the town is untouched); hidden parts are left out except originals the render batchers
  hid. `Label3D` text is never copied (it would give the word away).
- **Rigged animals (24 Nov 2026, user: "the face of the animal is misplaced"):** the skinned body
  is copied without its skeleton, so it is drawn in its rest pose, while the eyes and face ride a
  `BoneAttachment3D` on the animated head. `gather()` puts parts under an attachment back at
  the bone's rest place (`_rest_correction()`), so a picture taken while an animal walks or looks
  around keeps the face on the head.
- **No picture:** words of `NO_PICTURE_CATEGORIES` (Time & Directions, Colors & Descriptions,
  Actions: not nouns; Places & Rooms: their object is the place's name sign, a blank board
  without its text), words marked `"picture": false` in `data/words.json`, and targets over
  300 meshes or 24 m (a building, the bus).
- **Cost:** no download. Drawn on demand, newest request first, two at a time; at most 200 kept
  (64 KB of texture each). Measured 23 Nov (M5, whole town, 1600 × 1000): 621 pictures in
  11.5 s, 19 ms each. Headless runs draw nothing. `product_pictures.gd` (shop orders) uses
  the same `draw()`.
- **View:** from the object's front (-Z), a little from above and the left; Animals from their
  +Z, the way `park_animals.gd` turns them to walk (until 23 Nov evening every animal showed its
  back). Still seen from behind or the side: cat, monkey, field mouse, kangaroo, dog (their models
  face another way; open, P3).
- **Web cost (measured 23 Nov 2026, [numbers](FINAL_VERIFICATION.md#word-pictures-in-the-journal-and-results-card--23-november-2026)):**
  nothing is drawn during play. In the web build on a fast laptop, reading a picture back from
  the GPU (`get_image()`) took 3–5 ms (at most 10 ms) and frames stayed at 60 fps while pictures
  drew, except the first one or two journal pages of a session: one frame of 250 ms and one of
  115 ms (the picture view's shaders compiling once). Fixed the same day (user): `app.gd`
  `_warm_up()` calls `word_pictures.warm_up()`, which draws one Animals and one Food & Drink
  picture behind the loading screen (kept in the cache; at most 30 frames, skipped headless);
  re-measured, the worst journal frame was 23 ms. Not measured on a phone (likely several times
  slower).
- **Weak pictures turned off (user, 23 Nov 2026):** 147 words carry `"picture": false`, chosen
  from contact sheets of every picture: the body-chart parts (loose blobs), flat ground and
  building slabs (floor, road, path, step, tile, counter, ...), blank boards and signs (the flight
  board's words, store section signs such as *electronics*, *suspect*), and plain boxes, discs and
  cylinders that name nothing (tea, wine, rice, soup, cloud, flower, ...). 439 of 795 words keep a
  picture. When a word gets a better town object, remove its flag (`python3 tools/word_data.py`
  re-formats and checks it may only be `false`).
- **Check:** `docs/evidence/word-pictures-20261123/verify.gd` (per-category counts, journal,
  detail and results rows; with graphics it draws every picture and saves the views; with
  `WORD_PICTURE_SHEETS=<folder>` contact sheets of every picture). A covered or minimised
  Godot window draws no frames, so drawing waits: keep the window visible during a graphics run.

**9 Nov 2026: saved words merged into the journal, new look (user: the journal interface was
"really bad"; combine Saved words and the Journal; bigger gear and book icons).**
- The separate saved-words panel (top-right list) is gone: the book button opens the journal
  like J (`vocabulary_hud.gd` signal `journal_toggle_requested`, connected by Main to
  `toggle_study_journal`), and the **Saved** tab is the saved-words list. With nothing saved it
  shows `bookmarks.empty` (how to save a word). The journal's own ✕ closes it (tooltip
  `journal.close`); J and Esc still work.
- Layout, top to bottom: header (book icon, title, "{count} of {total} words studied" with a
  progress bar, ✕); tab row (All / Studied / Saved pills with icons, the HUD's By Category /
  By Area on the right); one tools row (search with a magnifier, category, sorting, Show / Hide
  scores); the table in a darker frame (column rule, striped rows, underlined section headings);
  footer (count left, view hint right). Buttons, menus, search and scroll bar are styled by
  `vocabulary_book.gd` `style_button()` / `_style()`, whose margins and corners follow the
  window scale. The title no longer carries the count (`journal.title`, `journal.progress`).
- The gear and book (top right) are one size, `60 × scale` px (52–120 px; were 46 × 44), same
  dark box; the book drawing scales with the button. The quest toast and FPS sit below / left of
  them. New `UiIcons` shapes `star` and `book`.
- **Same day, second round (user):** category and area are **multi-select menus**
  (`MenuButton`s with check items, kept open while ticking; first item "All" clears; none ticked
  = all; label "All …", the one name, or `journal.some_categories` / `some_areas`). Area keeps
  the words of any ticked area (`areas` from Main's `area_vocabulary.groups`); By Area then shows
  only the ticked areas' sections. A press on a row's ★ only saves / unsaves (the star stops the
  press; the wheel still scrolls); the rest of the row opens the detail. Rows are 56 px and the
  scroll bar 24 px (× scale; were 42 and 12) for touch: the user wants the game usable on mobile
  too. Show / Hide scores became a short **Scores** toggle in the tab row (✓ when on; tooltip
  says Show / Hide) to make room for the area menu.

Check: `docs/evidence/vocabulary-book-20261108/verify.gd` (runner id `vocabulary_book`): seeds a test
save (studied words, bookmarks and practice counts in es and zh), then checks every word
listed, totals against practice_log, the star saving and unsaving, the filters, search,
category and sorting, Show / Hide scores, the detail totals and game names, Esc order, the
virtual rows' size and speed, and that nothing is written to the practice log; since 9 Nov
2026 also the Saved tab (its empty note), the ✕ and the book button opening the journal, and
the gear and book sizes. With graphics it renders the PNGs in its folder (en/es table, Saved,
empty Saved, Studied filter, scores hidden and detail; es/zh table and detail; zh/es scores
hidden and detail; `hud-buttons.png` the town with the gear and book).

### Maintaining these docs

Use the [documentation map](../README.md) to select a current guide or historical
record. Use the project README for startup/current behavior, this document for editing contracts,
and `FINAL_VERIFICATION.md` for dated checks and unresolved issues. Keep focused
feature reports and evidence where they already live. Update the relevant guide
when ownership, controls, data or dimensions change; add a short dated result when
verification changes. Link to one source of detail rather than copying it into
multiple reports. Historical counts remain historical; mark conflicting guidance.
Remove superseded one-time reports when their useful rules are covered here;
retain test fixtures, licenses and useful dated evidence. Never claim old checks
passed again.

### Café and bank facade ownership — 25 October 2026

`building_exteriors.gd::decorate()` selects `finish_cafe()` for `Buildings/BakeryCafe`
and `finish_bank()` for `RelocatedSites/Bank`. The restaurant-cluster Cafe was
unchanged then (it became the taquería on 28 October 2026; see below). Both use the existing building-frame helpers; the bank's baked model
coordinates are intentionally retained and transformed through its actual frame.
`hide_front_labels()` extracts the former generic label-hiding loop unchanged.
New skin remains beneath Map facades; no scene rebake or interior migration.
Legacy bank ornament is hidden only when it has no word root or solid body below it.
Original collision trees and learning roots remain authoritative. Glazing is opaque
facade skin, not a wall opening. See the [design record](TOWN_DESIGN_BRIEF.md#café-and-bank-exterior-review--25-october-2026).

`check_cafe_bank_exteriors.gd` (retired 7 Nov 2026, see [building access](FINAL_VERIFICATION.md#snapshot-checks-retired--7-november-2026)) used source-building metadata to identify facade
ownership (Godot sanitizes slashes in facade names). Its pre-change baseline protects
all other facades, school/market, café/bank source visuals, word roots, collision
shapes/transforms, missions and doors, plus real-player capsule entrance routes.
Older supermarket/school appearance baselines describe earlier snapshots and will
flag later authorized facade changes; do not regenerate those historical baselines.

### Supermarket interior ownership — 26 October 2026

> **2 November 2026 refit:** `refine_market()` now frees every saved interior root of the
> old fit-out (`MARKET_REBUILT` prefixes) and all MarketDisplays children except the tile
> floor, and rebuilds the store in `MarketInterior` with the same words. Products are
> word roots built by `goods()` (one row, bin or tray each, with a pick `Area3D`; the
> per-product shapes are in `item()`, footprints in `FOOT`); fixtures use
> `market_box()`/`volume()`, and unworded fittings carry `market_fitting` metadata.
> `stock_shelves()`, `market_place()` and the decorative MultiMesh stock below are gone;
> `dress_market()` now adds only floor inlays and wall bands. See the
> [refit record](TOWN_DESIGN_BRIEF.md#supermarket-refit-fruit-checkout-by-the-door-and-clerks--2-november-2026).
> The older checks `check_market_interior.gd`, `check_learning_stores.gd` (MarketDisplays
> count) and `check_food_shopping_vocab.gd` describe the previous layout.

The separately authorized nine-department fit-out belongs to
`library_market_interiors.gd::refine_market()`. It runs from `world_refinements.gd`
after `resize_supermarket()` and before facade generation/`compact_town()`. It does
not call the older procedural `build_market()` or alter library construction.
`MarketInterior` under the existing supermarket root guards repeat application.
Its last step, `dress_market()`, applies the `MARKET_ACCENTS` table (sign board,
floor inlay and wall band per department) and `stock_shelves()` adds decorative
MultiMesh stock under `MarketInterior/Shelf stock` (no collision, no word; skips
spots overlapping real items). Edit department colours/rectangles in that table.
New geometry uses Main's cached materials/primitive helpers; existing prefabs and
learning roots keep meshes and picking children together. New local geometry is
in the supermarket source frame; `market_place()` converts that frame to the
existing parent's coordinates through global transforms. Both supermarket and
MarketDisplays retain their existing rigid compact-layout ownership.

Existing learning nodes are retained at their paths; anonymous old display tables,
supports and obsolete interior lettering are retired at runtime. New clear counter
guards have a local alpha material and no collision; solid fixture bases block
walking. Dictionary/alias/catalog data remain unchanged. The grocery mission in
`reference_world_layout.gd::relocate_quests()` uses store center (-33,0,47) in the
source frame and radius 19 only when the new interior exists; stable mission IDs,
word lists and save format are preserved.

Use `docs/check_market_interior.gd` (retired 7 Nov 2026, see [building access](FINAL_VERIFICATION.md#snapshot-checks-retired--7-november-2026)) in an isolated test copy: it writes grocery
quest test progress. The dated baseline predates the fit-out. Older dimension and
exterior tests asserting unchanged display positions describe the pre-interior
stage; do not regenerate their historical baselines to clear expected differences.
Use the new preservation, shell, actual-capsule circulation, per-key vocabulary
picking/card, bounds and quest checks for the interior. Historical `check_public_interiors.gd`
also uses superseded source coordinates and a smaller capsule.
See [design and rendered evidence](TOWN_DESIGN_BRIEF.md#supermarket-interior-review--26-october-2026).

### School single-divider ownership — 26 October 2026

`world_refinements.gd::resize_school()` now creates only `Center dividing wall`
inside `ApprovedShell`: source-local center (0,2.3,1.3), size (.2,4.6,9), running
from depth midpoint z=-3.2 to the rear z=5.8. Previous paired classroom-front and
hall walls and classroom doorway headers are no longer created. Exterior shell,
floor, roof and entrance header are unchanged. Four wall-mounted lesson props
move to the inside front exterior wall; general/science text moves to the rear.
The existing dimension guard and compact-transform order remain unchanged.

Use [the current floor plan](TOWN_DESIGN_BRIEF.md#school-single-divider-layout--26-october-2026)
and `docs/check_school_partition.gd` (retired 7 Nov 2026, see [building access](FINAL_VERIFICATION.md#snapshot-checks-retired--7-november-2026)) for new work. The check preserves all other
sites/facades/contents and verifies one divider, exact endpoints, front crossings,
access along both rear sides, the rear collision barrier and remounted picking.
Historical `check_school_exterior.gd` and `check_building_dimensions.gd` assertions
about an unchanged school interior or a walkable center hall to the rear describe
the previous layout; do not rebaseline their dated evidence to claim new passes.

### Hospital interior ownership — 26 October 2026

`build_hospital_floors.py` now delegates hospital authoring to
`build_hospital_remodel.py`; `--school` retains its previous behavior. The generated
hospital includes the aligned stair core, shaft controller and existing helipad
instance. Only stale hospital floor/shell overrides were removed from the active
saved world; wing/helipad/unrelated nodes were retained. Runtime
`world_refinements.gd::remodel_hospital_displays()` moves existing display roots
out of the new shaft before compact relocation. The elevator uses physics-driven
`AnimatableBody3D` cabin travel; no player controller replacement or package import.
See [the hospital guide](HOSPITAL_THREE_FLOORS.md) for coordinates, regenerated-file
boundaries, MIT attribution, controls, floor plans and focused checks.

### Hospital surface and stair repair — 26 October 2026

The user authorized replacing the cramped switchbacks and repairing interior/exterior
surfaces. The implemented straight stairs have front and rear approaches on every
floor. See the [current hospital guide](HOSPITAL_THREE_FLOORS.md) for dimensions, facade ownership,
normal-control tests and screenshots. This supersedes earlier switchback guidance.

### Park terrain ownership — 27 October 2026

After compact layout, species and grass materials, `world_refinements.gd` calls
`park_terrain.gd::build()`. This owns the static raised ground, fitted path collision,
path-height metadata and ground-relative planting. The bridge's new rise belongs
to `public_garden.gd::height_at()` and is regenerated in the existing guarded trail
refresh. This supersedes earlier instructions to retain the bridge's vertical
geometry, while preserving its plan and level endpoints. See the
[current garden grading](public-garden/README.md#boston-inspired-garden--4-november-2026).
The 4 November photographic revision adds more pronounced northern lawn shoulders,
a level statue island and fountain aprons, and a new monument path network; the
earlier rolling-hill, raised-shoulder and first subdued-lawn profiles are historical.

### Taquería, pool opening and sidewalk ownership — 28 October 2026

- `restaurant_interiors.gd::build()` runs in `world_refinements.gd` right after the
  supermarket fit-out and owns `Restaurants/Cafe/Taqueria` (shell-local coordinates,
  door on local −Z). It also sets the shell's old `CafeSign` label to TAQUERÍA and
  one-sided. The facade row in `building_exteriors.gd` owns sign text and colours.
- `reference_home.gd::pool()` owns the sunken basin and publishes the opening as
  `pool_opening` metadata on `RelocatedSites/Home`. `ground_openings.gd` (after
  `park_terrain.gd`) cuts that rectangle from `Natural town terrain`, `Island beaches`,
  `Coastal shallows` and `Surrounding water`, rebuilding their collision. Surface 0
  keeps its original vertex array because the minimap reads it as the outline; cut
  pieces go in a second surface.
- `world_refinements.gd::raised_sidewalks()` (called from `blueprint_loop()`) sweeps
  the curbed profile into `Loop road sidewalks` (with collision and the sidewalk
  word) and `Loop road curbs`. Swept ribbons publish `map_ribbon_points` /
  `map_ribbon_width` for `town_minimap.gd`. `park_off_sidewalks()` runs after the
  ground openings and moves any vehicle whose wheels straddle the curbed band.
- Streets polish (28 October 2026): `off_road()` keeps `driveway()` and
  `compact_walk()` ends off the road; `blueprint_loop()` publishes `loop_crossings`
  and `drop_curbs()` ramps the sidewalks at drives and crosswalks; swept strips carry
  UVs (u = distance along the loop). `street_furniture()` replaces loose streetlight
  parts with whole `Streetlight` roots (word on the root, solid pole) and one
  `Traffic light`; `road_surfaces()` runs last and assigns `shaders/road.tres` /
  `paving.tres` per colour, keeping the flat colour in `map_color` for the minimap.

## Zone boundaries — Stage 1 inspection, 28 October 2026

**Stage 1 completed and subsequently approved. Stage 2 is documented below.**
The vocabulary journal, category assignments, canonical keys, aliases, discovery,
location-specific missions and learner-save formats are unchanged by this feature.

### What changed and why

`data/zones.json` owns editable X/Z polygons, names, colors, priorities, exclusions
and label positions. `scripts/world/town_zones.gd` resolves locations and renders
inspection guides. Main attaches it to Apartment after final world construction
and UI setup. This keeps boundaries out of the large saved scenes and makes them
follow the actual runtime layout, including the current hospital, taquería and pool.
No building, fence, road, door, vehicle or learnable object is moved by this feature.

Press **B** to toggle **zone walls**. The overlay is off at every launch and has
no saved setting. Remap `toggle_zone_walls` in **Project Settings → Input Map**;
B was chosen after auditing player, Main, elevator and vehicle inputs, and the
user explicitly ruled out function keys. The existing function-key controls are
unchanged. The compact help line advertises the default B binding; the zone status
line reads the actual binding, including a remapped key.

Translucent colored walls extend from -0.15 to 4.85 town units, with narrow top caps
for overhead visibility, outlined names and a live current-zone status. Wall height
is only an inspection display: **resolution ignores Y**, including underground,
upper-floor and rooftop positions. Hospital therefore covers every floor and helipad.
The overlay contains only mesh/label/UI nodes, with no physics bodies, areas,
collision shapes or vocabulary metadata. Its UI ignores mouse events. Geometry is
created on first use and hidden with processing disabled when the overlay is off.

### Zone inventory and boundary rationale

Coordinates below are final **Apartment-local X/Z**, +X west / +Z north. Apartment
scales these by 1.3 in global space. `zones.json` is authoritative for exact vertices;
these bounds summarize each zone, not a second editable layout.

| Zone (stable ID) | Polygon extent or shape | Why this boundary |
| --- | --- | --- |
| Farm (`farm`) | X 42…90; Z 73…109 | Fence centerlines at x=42/90, z=73/109; includes the barn and gate opening. |
| Playground (`playground`) | X 40…84; Z 163…194 | Flat playground pad and full equipment envelope; since 1 November 2026 the 38 × 24 m mulch pad (town X 44.4…73.6, Z 172.2…190.7) plus the sandbox/tent south-west of it. |
| Church (`church`) | X -87…-69; Z 164…185 | Flat chapel pad plus its immediate entrance grounds; public approach continues in Central Park. |
| Zoo (`zoo`) | X -102…-54; Z 84…126 | Fence centerlines at x=-102/-54, z=84/126; includes both sides of the visitor gate. |
| Gazebo (`gazebo`) | X -102…-88; Z 145…158 | Separate structure and immediate flat grounds, cut out of Central Park. |
| Home (`home`) | X -17…23; Z 12…59.6 | Runtime home, garage, sunken pool and immediate grounds; driveway ends at the asphalt edge. |
| Hospital (`hospital`) | X 41…74; Z 200…255 | All three floors, rear lounge extension, helipad, front grounds and complete parking pad. |
| School (`school`) | X -16…16; Z 202…241 | School shell, front grounds, parking and vehicle frontage. |
| Furniture Store (`furniture`) | X 103…139; Z 194…259; multiple polygons | Store and parking; extra diagonal polygon follows the oblique driveway to the loop. |
| Sports Store (`sports`) | X 85…107; Z 203…256; multiple polygons | Store and parking; extra diagonal polygon covers its driveway. |
| Bakery / Café (`bakery`) | X 108.4…151; Z 154…179 | Combined bakery/café shell and parking to the road-facing edge. |
| Electronics Store (`electronics`) | X 108.4…144; Z 125…149 | Electronics shop, frontage and parking. |
| Bank (`bank`) | X 108.4…145; Z 96…121 | Bank, frontage and parking. |
| Clothing Store (`clothing`) | X -148…-117.4; Z 152…177 | Clothing shop, frontage and parking. |
| Supermarket (`supermarket`) | X -162…-117.4; Z 101…142 | Expanded supermarket and east delivery lot/driveway. |
| Library (`library`) | X 38…64; Z 18…59.6 | Library and full front parking pad, with approach to the asphalt edge. |
| Police Station (`police`) | X -162…-117.4; Z 61…101 (moved 28 Oct 2026; was X -106…-79, Z 20…59.6) | Police station south of the supermarket on the east loop road, with its front parking/driveway. |
| Fine Dining (`fine_dining`) | X -53…-20; Z 17…59.6 (1 Nov 2026: Z from 17 for the kitchen wing; 28 Oct 2026: Z 23…; was Pizzeria X -37…-20) | Merged old Pizza + Burger shells and the shared restaurant parking. |
| Pizza and Burger (`burger`) | X -106…-70; Z 23…59.6 (28 Oct 2026; was the middle Burger shell X -53…-37) | L-shaped Pizza and Burger in the former police lot with its own parking. |
| Taquería (`taqueria`) | X -70…-53; Z 23…59.6 | Mexican restaurant in Cafe shell and provisional western-screen-side parking share. |
| Airport (`airport`) | X -175…-59; Z 182…279 | Terminal, parking, transport approach, taxiway, apron and full diagonal runway; excludes Control Tower. |
| Control Tower (`control_tower`) | X -77…-65; Z 243…255 | Separate tower/cabin structure and immediate grounds, nested within Airport. |
| Town Road (`town_road`) | X -120…111; Z 57…208; rounded loop | Rounded loop plus both sidewalks, following the existing 16-unit-wide corridor; inner park excluded. |
| Central Park (`central_park`) | X -104…95; Z 73…192; rounded loop | Interior of the loop’s inner sidewalk edge, minus explicit Farm, Playground, Church, Zoo and Gazebo cutouts. |
| Coast (`coast`) | Complement / fallback | Complement of all named properties, park and road: shoreline, coastal paths and intervening outer meadow. Also the offshore fallback. |

### Priority, cutouts and edge ownership

Control Tower has priority 110; other properties/attractions 100; Town Road 50;
Central Park 10; Coast 0. Equal-priority ties resolve in JSON file order, explicitly
preserved by sorting. A query always returns one stable ID. Shared edge points are
resolved deterministically by the same polygon test and ordered priority scan.
The public methods are `resolve_local(Vector3)` and `resolve_global(Vector3)`.

`exclude` lists subtract the **raw footprint polygons** of the named zones. Central
Park explicitly subtracts Farm, Playground, Church, Zoo and Gazebo. Airport subtracts
Control Tower. Town Road subtracts the park’s full inner footprint, so attractions
do not accidentally become road. Coast is the complement of the other footprints
and the fallback outside the island; there is no invented ocean perimeter wall.
Its visible inland edges are the walls of the neighboring zones.

The wall renderer samples segments at no more than 0.5 town-unit spacing and draws
only portions that separate different resolved zones. Overlapped polygon joins are
hidden; rendering is an approximation near intersections, while resolution uses the
full polygons. The display does not draw vertical walls to infinite altitude.

### Provisional edges requiring layout review

- **Restaurants:** three distinct shells are retained. The existing continuous
  parking pad has no three-property dividers. Proposed boundaries at X=-53 and -37
  split it between Taquería, Burger Restaurant and Pizzeria.
  The common central driveway resolves to Burger Restaurant. This is a reviewable
  ownership convention, not evidence of a real fence or permission to change signs.
- **Road versus frontage:** Town Road includes sidewalks. Individual property
  fronts can supersede it where existing parking/driveways overlap the road band,
  especially Hospital (its pad begins at Z=200) and School (Z=202). Those surfaces
  already overlap; zones preserve their positions and give the property priority.
- **Unfenced grounds:** Church, Playground, Gazebo and shop rear/side edges use
  measured flat pads, building envelopes, parking and immediate grounds. They are
  proposed property edges, not newly built fences. Shared public approach paths
  remain park or road beyond each property envelope.
- **Coast extent:** all outer meadow gaps are provisionally Coast as well as the
  shoreline and coastal paths, so there are no unnamed leftover locations. Review
  this broad interpretation if outer meadow should instead belong to a property.
- **Secondary structures:** Home includes its garage/pool; Farm includes Barn as
  requested. Gazebo and Control Tower receive separate zones under “each remaining
  structure”; Control Tower is a cutout inside Airport. Review that granularity.
- **Airport:** the property includes operational airfield surfaces, measured after
  runtime relocation, not just the terminal node’s footprint. Its outer grass
  margins are provisional; the western edge follows the runway’s full envelope.

### Editing and inspecting

1. Edit only `data/zones.json` for normal boundary changes. Each polygon is an
   ordered list of `[x,z]` pairs without a repeated final vertex. Keep polygons
   simple (no self-intersections), IDs unique and all exclusion IDs valid.
2. `polygons` may contain several overlapping outlines to cover a building and an
   angled driveway. Adjust `label`, `color` or optional `display_label` separately.
   Use `exclude` for explicit holes; never encode a hole by self-crossing vertices.
3. Use final runtime town coordinates, not the saved snapshot’s pre-relocation
   transforms. Do not change `reference_layout.json` or rebake a world to edit zones.
4. Restart the game to reload the JSON; toggle B. Walk across the edge and check the
   status. Existing N noclip plus Space/Ctrl can inspect from above; turn noclip off
   afterward. Check street/entrance, parking, roof and corner cases after edits.
5. Run `docs/evidence/town-checks/check_zones.gd` in an isolated copy using the README save-isolation
   instructions. Update intentional expected samples only after reviewing the map.

### Verification and scope

Godot 4.7.2 Compatibility, temporary project copy with
`custom_user_dir_name="VocabularyTownChecks/zones-20261028"`. No learner directory
was used for testing. Resource-load baseline: **323 resources, zero failures**;
after implementation: **324 resources, zero failures**. Focused zone checks:
**5,091 checks, zero failures** (cutouts, property envelopes, hospital heights,
borders, 4,941 grid locations, B toggle/repeat/remap, default-off state, unchanged
collision inventory and identical ray target with the walls enabled).
Existing compact layout: **683 checks, zero failures**. Existing interaction fixture:
**PASS** (targeting, cards, signals, doors, dismissal and range).

Graphical runs captured and inspected overview, park, restaurants, hospital and
normal player-camera views. Initial inspection led to full-runway Airport coverage,
more visible top caps and shorter multiline restaurant labels. A missing legacy
map image in the first temporary copy was corrected by copying/importing the assets;
it was a test-copy omission, not a shipped project error. Existing SpatialMaterial
remapping warnings and restricted headless log/certificate/editor-setting warnings
remain. No full vehicle suite, exhaustive manual playthrough or performance benchmark
is claimed. Stage 2’s shared-sofa/area-list/moving-home-area/save-mission acceptance
checks remain deferred with Stage 2 itself.

Stage 1 does not bind objects to areas, change discovery or replace mission site
resolution. The new resolver is ready for an approved Stage 2 integration, but
journal/category/area behavior must not be inferred as implemented.

Rendered zone evidence: [overview](../evidence/town-checks/zones-overview.png), [park](../evidence/town-checks/zones-park.png), [restaurants](../evidence/town-checks/zones-restaurants.png), [hospital](../evidence/town-checks/zones-hospital.png), [player view](../evidence/town-checks/zones-player.png).

## Category and area journal — Stage 2, 28 October 2026

**Stage 1 boundaries approved by the user; Stage 2 implemented.** The approval was
“ok proceed to next step.” Approved polygons and the B-key inspection overlay are
unchanged. This section supersedes earlier “Stage 2 pending” status statements.

### What changed and why

*8 Nov 2026: the journal now lists every word in a table with filters and scores; see the
[vocabulary book](#vocabulary-book). The grouping below still applies to its sections.*

The J journal now has **By Category** and **By Area** buttons. Both show the same
canonical discoveries, Spanish first and displayed English second. Group names
sort alphabetically; rows sort by the displayed English label, ignoring case, with
a stable key tie-breaker. Undiscovered translations remain hidden, preserving the
previous discovered-only behavior. By Category omits groups with no discoveries.
By Area shows every approved zone, including empty ones, with **discovered/total
unique words** and the explanation: “Shared words count as discovered in every area.”
The total is vocabulary available in that area, not the number of object instances
or a count of visits. Changing view neither discovers words nor writes saves.

The previous categories mixed places (Home, School) with types (Animals). They have
been replaced by consistent type/topic groups. For example: sofa → Furniture,
refrigerator → Appliances, bowl → Kitchenware, guitar → Music, bedroom → Buildings
& Spaces. Category labels describe kinds of things or concepts, never the zone
where an instance happens to stand. Existing word meanings and keys remain intact;
no synonyms were added or merged and no Spanish translation was changed.

### Resulting categories

> **Superseded 28 October 2026.** The 26 labels below were merged into **18 categories**,
> each with a written rule in `data/words.json`, and the scene-cached category tags
> were removed (see [vocabulary data procedure](#vocabulary-data-procedure)). Old →
> new: Food → Food & Drink; Kitchenware → Kitchen & Dining; Household Items and
> Lighting & Decor → Around the House; Electronics and Appliances → Electronics &
> Appliances; Buildings & Spaces → Places & Rooms; Structures & Fixtures → Building
> Parts; Transport Infrastructure and Signs → Streets & Town; Transportation →
> Vehicles; Commerce → Shopping & Money; Books & Learning, Art & Crafts and Music →
> School & Arts; Health, Body and Personal Care → Health & Body; Time and Directions →
> Time & Directions. About 35 words moved individually to a better fit (for example
> menu → Food & Drink, store counters → Shopping & Money, piñata → Sports & Play).

There are **486 words, 19 categories and 12 aliases** (28 October 2026: 464 after the word clean-up, plus pizza, hamburger, french fries, wine and soda for the new restaurants, then skis, ski poles, snowboard, ski boots, gloves, winter hat, ski goggles and sled added for the sports store's winter department; passport, boarding pass, suitcase, luggage cart, check-in counter, metal detector and flight board (new Travel category) plus airport and baggage claim for the airport terminal):

| Category | Words |
| --- | ---: |
| Food & Drink | 63 |
| Kitchen & Dining | 19 |
| Furniture | 27 |
| Around the House | 17 |
| Electronics & Appliances | 29 |
| Places & Rooms | 35 |
| Building Parts | 22 |
| Streets & Town | 17 |
| Vehicles | 17 |
| Travel | 7 |
| Shopping & Money | 26 |
| School & Arts | 39 |
| Health & Body | 53 |
| Clothing | 24 |
| Sports & Play | 20 |
| People | 13 |
| Animals | 20 |
| Nature | 25 |
| Time & Directions | 13 |

Historical record (26 labels, 28 October 2026, before the merge):

There were 534 canonical entries, 26 category labels, 15 aliases and 183 catalog
records. Each canonical key has exactly one category. Counts below include all
dictionary entries, even if no current object exposes the word.

| Category | Canonical words |
| --- | ---: |
| Animals | 20 |
| Appliances | 13 |
| Art & Crafts | 5 |
| Body | 16 |
| Books & Learning | 33 |
| Buildings & Spaces | 37 |
| Clothing | 23 |
| Commerce | 18 |
| Directions | 5 |
| Electronics | 21 |
| Food | 57 |
| Furniture | 43 |
| Health | 32 |
| Household Items | 23 |
| Kitchenware | 30 |
| Lighting & Decor | 14 |
| Music | 6 |
| Nature | 26 |
| People | 14 |
| Personal Care | 8 |
| Signs | 6 |
| Sports & Play | 14 |
| Structures & Fixtures | 33 |
| Time | 8 |
| Transport Infrastructure | 12 |
| Transportation | 17 |

`data/vocabulary_categories.json` was then the category authority (merged into `data/words.json` `categories` on 28 Oct 2026). Corresponding category
fields in `learning_catalog.json` and cached category tags in **80 scene files**
were synchronized. Those scene edits are metadata-only: no transforms, geometry,
resource references, vocabulary keys, aliases or translations changed. This also
corrected the eight pre-existing cached-category failures detected in the baseline.
The old Godot category/alias tests contained stale 469-word/137-catalog/13-alias
inventory assertions; these were updated to the inspected current inventory.

### How actual objects determine area vocabulary

`scripts/learning/area_vocabulary.gd` builds once after Main finishes world
construction and creates the interaction controller, before garden rendering batches.
It scans enabled collision shapes on nonzero-layer collision objects, resolves each
to the same vocabulary target as clicking, and canonicalizes its key through the
existing alias table. The shared resolver is
`interaction_controller.gd::vocabulary_target()`: exterior ancestors, saved root
paths, legacy root references and ancestor `word_key` metadata keep their existing
precedence. The original 8-unit object / 40-unit exterior picking range remains.
Decorative nodes with vocabulary metadata but no picking geometry do not add words.

Each target receives one `assigned_zone` metadata value. Its default position is
the combined collider-envelope center, converted to final Apartment-local
coordinates and resolved by the approved polygons. Collider geometry is used
because generated surfaces can have offset vertices and a root at the origin.
Y is ignored by zone resolution, so hospital upper floors and the roof resolve
consistently. Area dictionaries deduplicate canonical keys; many chairs or sofas
create one entry per area. A word may appear in several area dictionaries.

The current audit found **2,559 learnable targets**, **450 distinct placed canonical
words**, **704 unique area/word memberships**, and **zero unknown keys**. The 84
remaining dictionary words are not invented into any area list. Previously saved
discoveries for them still appear By Category. Control Tower currently has no
pickable vocabulary target, so it correctly displays 0/0 rather than a fabricated
word. The existing Fine Dining/Pizza shell has only its exterior learnable entry.

| Area | Unique available words |
| --- | ---: |
| Airport | 27 |
| Bakery / Café | 36 |
| Bank | 42 |
| Burger Restaurant | 5 |
| Central Park | 34 |
| Church | 15 |
| Clothing Store | 37 |
| Coast | 14 |
| Control Tower | 0 |
| Electronics Store | 28 |
| Farm | 10 |
| Pizzeria | 1 |
| Furniture Store | 19 |
| Gazebo | 2 |
| Home | 30 |
| Hospital | 85 |
| Library | 41 |
| Playground | 8 |
| Police Station | 43 |
| School | 70 |
| Sports Store | 18 |
| Supermarket | 77 |
| Taquería | 38 |
| Town Road | 13 |
| Zoo | 11 |

### Boundary overrides and moving vehicles

Edit `data/zone_object_overrides.json` for boundary cases. Its keys are **exact
Apartment-relative node paths** and each record has a valid zone ID plus a reason.
An object or ancestor may alternatively carry `zone_override` metadata. Search
starts at the resolved vocabulary target and walks upward; the closest override
wins, with metadata taking precedence over the JSON entry on that node. Without
an override, spatial zone resolution applies. Restart after editing boundaries,
overrides or placements so the index is rebuilt from the final world.

Documented overrides currently cover:

- Home car → Home; delivery truck → Supermarket; school bus/fire truck → School;
  police car → Police Station; ambulance → Hospital; taxi/turboprop → Airport;
  rooftop helicopter → Hospital; restaurant motorcycle → Fine Dining (was Burger Restaurant before 28 October 2026).
  Descendant learnable wheels/lamps inherit the same ownership. The fire truck
  retains its existing school-frontage home; no fire station was invented.
- The loop road and sidewalk/curb rings → Town Road, because their envelope centers
  fall inside the park even though their surfaces surround it. The curb override
  is harmless if no learnable target is exposed by that surface.

Assignments are fixed for the session. Driving/flying a vehicle changes the player's
current zone shown by B, but never changes that vehicle's home-area vocabulary.
This index is placement data, not persistent player state. Dynamically spawned
learnable content would require an explicit index rebuild or registration path;
the current town builds its learnable objects before this index is created.

### Discovery and mission compatibility

Global discovery lived only in `vocabulary_apartment_progress.json`, as a
canonical-key array. *(Since UI Stage 3, 4 Nov 2026: per foreign language in
`vocabulary_progress_by_language.json`; the old array is read once as Spanish and kept
untouched — see the Stage 3 notes under shared dialogue, popups and settings.)* Quest state still lives in `vocabulary_town_quests_v21.json`,
with the same mission IDs, active index and per-mission found arrays. Application
identity, alias migration and both save implementations are unchanged.

A sofa discovered in Home immediately counts as discovered in Home, Hospital and
Furniture Store. That **does not** complete the Furniture Store mission. Main still
calls `quests.register_word(key, player_local_position)` on every study event,
including an already discovered word. That independent destination/radius check
continues to require studying at the mission location. The area index never reads
or writes mission completion and does not replace existing mission destinations.

### Verification

Godot 4.7.2 Compatibility; temporary copy with isolated user directory
`VocabularyTownChecks/journal-20261028`. `docs/evidence/town-checks/check_area_journal.gd` refuses to run
in any other user directory. It temporarily seeds old-format discovery/quest saves,
then restores fixture files after completion. No learner profile was used.

| Check | Result |
| --- | --- |
| Python category/catalog/scene integrity | 94,880 checks, 0 failures (baseline: 8 cached-category failures) |
| `check_area_journal.gd` | 237 checks, 0 failures; real shared sofas, all hospital targets, border fixtures, override/alias resolution, moving car, unique totals, sorting, view switches, old-save loading/roundtrip and location-specific mission registration |
| `check_zones.gd` | 5,091 checks, 0 failures; approved boundaries unchanged |
| Godot category and alias checks | PASS; canonical normalization and prefab loading |
| Interaction fixture | PASS; targeting, highlights, cards, signals, doors, dismissal and range |
| Runtime resource loading | 325 checked, 0 failures |
| Source preservation | Vocabulary, aliases, zone polygons, discovery/quest implementations unchanged; all 80 scene diffs contain only category-tag edits |
| Rendered journal | Both views inspected at 1280×720; actual pointer press/release switched to By Area; scrolled shared-sofa view inspected |

Screenshots use clearly synthetic in-memory discoveries, not learner progress:
[By Category](../evidence/town-checks/journal-by-category.png), [By Area](../evidence/town-checks/journal-by-area.png),
[shared sofa](../evidence/town-checks/journal-shared-sofa.png).
Existing SpatialMaterial warnings and restricted headless log/certificate warnings
remain. No full vehicle/physics suite, exhaustive playthrough or performance
benchmark is claimed. Moving-vehicle ownership was verified by relocating the
actual car; mission separation by actual Main study-event registration at wrong
and correct destinations, not a full manual quest playthrough.

### Maintenance

Keep canonical words and aliases in their existing dictionaries. Assign new words
a type category, synchronize catalog/cached category fields, and place real picking
geometry before expecting an area entry. Never add a second vocabulary dictionary
per area or a second discovery save. Use override data only for genuine ownership
ambiguities; normal placements should resolve spatially. Rerun the area test in an
isolated profile after changing zones, targets, aliases or journal behavior.

## Clickable word items — 9 November 2026

The pointer (`interaction_controller.gd`) casts a ray against every collision layer except
`FIGURE_LAYER` (256), areas included; the nearest ancestor of the hit with `word_key` meta is the
word (`vocabulary_target()`). An item is therefore clickable only if its own word root holds a
collider and nothing else is hit first. The [interiors polish](TOWN_DESIGN_BRIEF.md#interiors-polish--9-november-2026)
audit (`docs/evidence/interiors-polish-20261109/audit.gd`, rays from around every root) found these
causes of "some copies click, others do not":

| Cause | Where | Fix used |
| --- | --- | --- |
| A builder rule taught only the first copy of a word (`restaurant_venues.gd` `once()`, deleted 6 Nov; food excepted from 1 Nov) | Pizza and Burger chairs, trays, food | Rebuild each copy as its own word item |
| A fixture's invisible player blocker on a pickable layer enclosed the goods | sports shelves, Pizza and Burger fridge, police evidence and equipment shelving | Blocker on `FIGURE_LAYER`, mask 0: stops the player, not the pointer |
| Item buried inside another item's pick area or mesh (cushions in a sofa, pillows in a mattress, soda in a fridge) | furniture store, Pizza and Burger | Pick areas fitted to the frame or leaving the top free; items placed on top |
| A pick area switched off (collision layer 0) | `tennis_ball.tscn` | Layer 2 again |
| Look-alike meshes with no word root (built as decoration) | every audited building | Tag with an existing key and add a fitted pick `Area3D` (layer 2) |
| Prefabs placed backwards (fronts are −Z; a builder assumed +Z) | furniture store | Turn them; not a pick fault but it hid fronts (TV, drawers) from the player |

Rules for new interiors: one word root per visible item (repeats reuse the vocabulary prefab or
the step helpers in `scripts/buildings/sports.gd`: `item()`, `fixture()`, `pick_area()`,
`solid(…, player_only)`); any blocker that encloses or covers word items goes on
`FIGURE_LAYER`; a seat keeps a separate low mesh (≤ 0.55 high) for the seating controller;
check with the audit's `--rays` before committing. Checks that test solidity with the default
mask (`docs/evidence/police-interior-20261028/verify.gd` `clear_at`) still see `FIGURE_LAYER` blockers.

## Interaction system

**Since 12 Nov 2026 (user design; replaces the E chain in `Main.use_pressed`, the click metas
and the hover hints).** Every way of using something in the world — talking to an NPC, a
vehicle, a door, a seat, a faucet, a minigame station — goes through one path:

| Part | Owner | Contract |
| --- | --- | --- |
| **Interactable** | `scripts/core/interactable.gd` (a `Node` named `Interactable`, child of the object; group `interactables`; load with `preload`, no `class_name`) | Data only: `kind` (USE, TALK, DRIVE, BOARD, OPEN, SIT, PLAY), `prompt_distance` (horizontal metres), `discover_distance`, `needs_facing`, `needs_aim`, `priority`, `indicator` (NONE, CALL = the NPC "!", STATION = a subtle dot), `badge_offset`. The owner's `use()` is the action and an optional `can_interact()` returns true, false (not a candidate) or a reason line (focusable; activation flashes the line). Code-made ones set `on_use`, `on_check`, `on_point(from)`, `on_badge()`, `on_rank(from, heading)` instead. `Interactable.attach(owner, {...})`, `on(node)`, `find_for(collider)`. |
| **Focus pass** | `interaction_controller.gd` `refresh_focus()` (every `FOCUS_INTERVAL` 0.1 s and on every E) | One pass over the group: skips far owners at once (`COARSE_RANGE`), places the discovery icons, and picks ONE focus target — the interactable under the pointer (screen centre while the view is dragged) if in range, else the best in range and in the forward cone (score: distance + facing term − `priority`, − `CALL_BONUS` 2 for an NPC calling with its "!", so it beats nearer chairs in talking range). Range is horizontal to `point()` with a `MAX_RISE` 2.6 m height limit; an NPC's point is its own position, not its head badge. `check()` runs only on ranked candidates, best first. No per-object processing. |
| **Icons** | `scripts/ui/interact_badge.gd` (`interaction.icons`) | One "E" badge (HUD style: dark teal disc, gold edge, cream E; `fixed_size`, drawn on top, one texture) on the focus target; pooled "!" labels (moved out of `npc_presence.gd`) for TALK interactables whose `calling` is set by `npc_presence.animate()` (the host's offer rule, unchanged); pooled dots over STATION interactables within `discover_distance` while no minigame runs (since 23 Nov 2026 measured in 3D, only from 1.5 below to 4.5 above the feet and in sight: `_station_near`). Nothing while driving, seated, on a ladder or with a menu open (the pass does not run). The focused NPC's "!" becomes the "E". |
| **Input claims** | `interaction.claim(id, wants, use, click)`; `Main.use_pressed()` | A modal owner holds E and the click while `wants()` is true, and hides the focus: `vehicle` (E leaves; click nothing), `seat` (E stands; click nothing), `warehouse` (carrying or holding a trolley: E / click put down or let go; on Ramón's twin they talk). Otherwise E calls `activate_focus()`. |
| **Click / tap** | `interaction.click()` (Main's left click; touch is emulated as the mouse) | Claim → a tap within the badge's finger-sized radius (`TAP_RADIUS` 34 px × min(h/800, w/1100), at least 22) activates the focus → an interactable under the pointer in range activates (out of range: nothing) → the shop cart's `pick_hook` → a plain word's card (none while a minigame runs). |

Rules (user, 12 Nov 2026): the prompt is a bare "E" for everything; **an interactable is not a
word** — clicking it uses it, `aimed_object()` skips it and `area_vocabulary.drop_interactables()`
takes its word out of the area lists (journal counts only hold words a click can study); no hover
glow, no hover word line and no "Click: study" hint; prompt toasts are gone (the garage's arrival
toast, the hospital elevator's landing card), feedback toasts stay. Random-event probability is
unchanged: `activity_board.gd` and the roll in `minigame_host.tick()` were not touched.

Where each kind is made (all at load, so bakes never save them; `tools/bake_unit.gd` drops
ownerless nodes): doors `door_animator.gd make_interactables()`; vehicles, zoo / farm gates and the
Home garage door `vehicle_controls.gd make_interactables()` (boarding within 5.2 m of the cabin or
driver door; the garage door yields to a car beside it inside the garage unless aimed at); seats and
beds `seating_controller.gd make_interactables()` (one per seat node, a sofa's nearest free cushion,
the old "seat behind you" rule as `on_rank`); NPC talkers `minigame_host.gd add_talker()`; the
objects' own `_ready()`: `faucet.gd`, `flush_control.gd` (needs aim), `elevator_call_button.gd`
(cabin buttons need aim), `electrical_box.gd` and `radar_console.gd` (stations), `treasure_chest.gd`,
`mystery_door.gd`; the flight board and booklet `flight_session.gd`; warehouse goods, trolleys and
cabinet `warehouse_goods.gd`, the copy's exits `warehouse_session.gd`. The old baked metas were
removed by the `interaction_metas` step of the home, airport and mystery units
(`scripts/buildings/interaction_metas.gd`).

**Adding an interactive object:** give it a `use()` and, in its `_ready()` (skip in the editor for
`@tool` scripts), `Interactable.attach(self, {...})`; never add a key handler, a click meta or a
hint label. A minigame NPC gets its interactable from the host. Check: `docs/evidence/town-checks/check_interaction.gd`
(focus, badge, E, click, tap on the badge, claims, no card).

## Saved place and respawn

**Since 14 Nov 2026 (user).** A profile's game goes on where it was left. Owner:
`scripts/core/player_place.gd` (rules, file, spawn search); `player_place_keeper.gd` saves;
`Main._restore_place()` restores; building entrances are `Main.ENTRANCES` (the former
`DEV_SPAWNS`, shared with the dev `spawn=`).

| Part | Where |
| --- | --- |
| File | `player_place.json` per profile (`save_store.gd` `PROFILE_FILES`, atomic write): feet in **town** coordinates (`Main.apartment` local frame; the warehouse minigame copy saves the real warehouse spot, the player's `map_position`; driving saves the vehicle's position and `"vehicle": true`), `yaw`, `entrance` (an `ENTRANCES` key or `""`), `time`, `version` |
| Saving | The keeper node (added by Main once the town is ready): every 10 s when the player moved 1.5 m or more, on a close request, app pause or focus loss, when the town leaves the tree (quit, "Switch profile") and when the web page is hidden (`web_resume.gd` `_on_page_event()`). Only with a profile selected (`PlayerPlace.enabled()`), never while baking (`save_store.gd` `read_only`) |
| Which building | Indoors = a static roof overhead and static walls on 3 of 4 sides (as `indoor_visibility.gd`); the unit owning the roof's collider (`data/buildings.json` parts), else the town zone there (`data/zones.json`, `ZONE_UNITS`); then the unit's entrance whose door is nearest. Units with several buildings list each: restaurants (Alta Cocina, Pizza and Burger, Taquería), airport (terminal, `tower`) |
| Restoring | Before `town_ready`, after two physics frames (every collider in the space): only for a profile that finished the welcome tutorial, with no dev `spawn=`. Inside a building → that entrance's standing point, facing the door (searched within 6 m if blocked). Outdoors → `safe_spot()`: the saved spot, then rings 1.5 m apart to 15 m; each needs walkable ground (normal.y > 0.85) by a downward ray, not the sea (zone `coast`), not more than 2.5 m above the lowest solid below (roofs, decks, vehicle tops), no roof overhead, the player capsule clear (world and figure layers: walls, vehicles, props) and, when the saved spot was standable, in sight of it at waist height. Nothing found, an unknown entrance or a building whose unit is not loaded (dev focus) → the usual supermarket spawn. A new profile has no file: the tutorial start is unchanged. The web resume note (`web_resume.gd`, after a lost WebGL context) still places the player afterwards |
| Check | `player_place` (full suite; [record](FINAL_VERIFICATION.md#save-and-respawn--14-november-2026)) |

## Naming (16 Nov 2026)

User decision: the pig player character is **BonBon** (é¦é¦, a girl; ids and files use `bonbon`, node
`BonBonPlayer`, phrase id `bonbon_s_own_look`, avatar `bonbon`), renamed from her earlier name, and the game
is **Bon Adventure: Little Town of Words** (project and app name "Bon Adventure"). Profiles saved with the old
avatar id are migrated on load, and the old browser resume key is read once and deleted. The repository is
moving to `jameshho/bon-adventure`; no redirect repository is kept. Git history is not rewritten.

## Welcome tutorial

**Since 12 Nov 2026 (PWA restructure phase 6, design agreed with the user).** "Welcome to
Bon Adventure" is played once per profile after the town loads (`app.gd` `_on_town_ready()` →
`Tutorial.begin(main)`). One director, `scripts/learning/tutorial.gd`, plays the steps of
`data/tutorial.json`; checks and tools that load `main.tscn` directly have no profile and never
see it.

| Part | Where |
| --- | --- |
| Acts and steps (place, say, hint, wait for stand / view / move / near / door / use / study / journal, door, walk, cutscene, shop, words, lock, confine; since 17 Nov 2026 also controls, strip, pause, find and a `place` with a `picnic`) | `data/tutorial.json` (its `about` explains the fields); spaces are a unit's site (`home`, town units) or `world` (metres) |
| Controls (16 Nov 2026, user) | Right after the player stands up BonBon teaches the two controls, each a `hint` and a `wait`: "Have a look around! Drag with the mouse to turn the view." (`for: "view"`: done once the view was turned 0.6 rad by hand, `player_controller.gd` `look_turned`, counted in `look_by()` only, so the follow camera does not count; or zoomed 1.5 m) and "Now walk a little! Use the W, A, S and D keys." (`for: "move"`: done after 1.5 m on foot). There is no separate camera / POV key: the view turns by dragging (right or left mouse button, a finger on the world) and zooms with the wheel or a pinch. On a touch screen (`hud.touch_mode`, set by `touch_controls.gd` on a touch screen or at the first touch) the steps' `touch_line` / `touch_where` say "Slide a finger on the right side of the screen…" and "Put your thumb on the left side of the screen and slide it — that's your joystick." (a first touch re-shows a hint in the touch wording). Meanwhile the control pulses: `scripts/ui/tutorial_cue.gd` (no words; a mouse or a fingertip gliding between two arrows right of the middle, outside the joystick's 40 %; the W A S D keys bottom left) and on a touch screen the joystick's own ring (`touch_controls.gd` `highlight_stick()`). When the player has tried it the cue and the hint go. Check: `tutorial` drives both steps and checks both wordings, the cue and the stick highlight |
| Lines | `tutorial.*` in `data/phrases.json`, spoken in the NATIVE language (`narration()`: the same text in both slots, with meta `narration`, so the dialogue box shows no reading or translation); `"learning": true` lines (the friends' greeting) and the clerk's and cashier's `cashier.*` lines are in the language being learned; key words come in through `{word}` / `{items}` values |
| Cast | Standing plushes of the house characters (`house_characters.gd` `worker()`, `spec_of()`, `ids()`); their seated twins are hidden and their blockers off meanwhile. The cast is solid too (`HouseCharacters.fit_blocker()`, 14 Nov 2026: the player cannot walk through BonBon). A friend who is the player's avatar is replaced by the next character in data order (since 17 Nov 2026 the guide too); since 14 Nov 2026 that stand-in (Bruno first) has no house twin to hide (`"in_house": false`, [record](REFERENCE_HOME.md#fewer-plushes-and-clear-walkways--14-november-2026)) |
| Shop act | `scripts/learning/tutorial_shop.gd`: the supermarket's clerk and cashier (from `data/shops.json`) only speak, their interactables are off; the shared cart (`pick_hook`), dialogue box and money panel; a fixed order and price. Since 13 Nov 2026 the order is one apple and one banana for $2.50 (the order of two apples left players who had picked one of each waiting with no hint), the fruit is on the fruit table inside the door (supermarket step `tutorial_fruit`, [record](TOWN_DESIGN_BRIEF.md#tutorial-fruit-table--13-november-2026)), and after paying BonBon says to walk out (before, nothing told the player to leave the store). **User review, 14 Nov 2026:** the clerk first says "Hello, nice to meet you. Here's your shopping basket (*la canasta*)." and hands over a basket the player holds (`shopping_basket.gd` `give()`, hand profile `basket`); the picked fruit shows in it and it is taken back once the player walks out; the clerk and cashier speak the native language (`cashier.*` lines through `narration()`), with the order's words and the amount in the language being learned coloured in the dialogue box, the amount with its digits ("dos dólares con cincuenta centavos (= $2.50)", [coloured words](COMPONENTS.md#coloured-words-in-the-dialogue-box)); the cashier's thanks closes itself after 3 s (`THANKS_SECONDS`); and while the player is inside and has not paid, an invisible wall stands in the store's doorway (`tutorial.json` shop `door`, `minigame_zone.gd` `make_door_guard()`, walking into it says "Please pay at the checkout first!") |
| Other NPCs | `activity_board.gd` `hold` = "tutorial": every activity's `blocker()` names it, so no "!" and no game starts; word cards still work |
| Words | The shower curtain (when pulled back), the picked fruit and the statue go through `interaction.word_studied`, so they are saved and shown in the journal; nothing is written to the practice log |
| Word cards (clicking a plain object to learn its word) | Off from the start (`interaction_controller.gd` `word_cards`) until the park act's `words` step, just before the statue (user, 13 Nov 2026); interactables and the shop cart's pick hook still work; `_stop()` turns them back on. Since 14 Nov 2026 (user) a card opened during the tutorial closes by itself after `card_seconds` (3.5 s, `data/tutorial.json` → `interaction_controller.gd` `card_seconds`; 0 = stays until dismissed, the default outside the tutorial) |
| Hidden props | `data/tutorial.json` `hide` (node paths under the town): the mahjong table with its players (user, 14 Nov 2026) is hidden, not solid and its seats and talker are off while the tutorial runs (`tutorial.gd` `_hide()`, as for the house twins); its render-batched copies are shrunk away and back with `render_culling.gd` `show_batched()` (hiding the node alone leaves the merged copy drawn). Back when the tutorial ends or is skipped |
| Talking to BonBon | The guide's standing plush is a TALK [interactable](#interaction-system) (`_make_guide_talker()`, the same settings as a minigame host's talker; no "!"). While a `wait` step runs, E, a click or a tap on her says that step's `where` line (`data/tutorial.json`; `where_line()`); in the shop act the trip's phase decides (`tutorial_shop.gd` `where()`: fruit, till, walk out). Not offered while a line with a Next button, the cashier's request, a fade or the cutscene is up (13 Nov 2026) |
| Progress | The profile's `"tutorial": {"act", "done"}` (`profile_manager.gd` `update()`), saved at the start of each act (each act begins with a `place` step, so it can resume there) |
| Skip / Replay | The "Skip tutorial" button (`tutorial.skip`, says what it skips since 14 Nov 2026; it widens to its text; top centre, below the clock, hidden behind the journal, map, help and Settings; a BonStyle soft blue pill since 18 Nov 2026, restyled only when the window scale changes) ends it and places the player at `skip_to` outside the home; Settings' "Replay the welcome tour" (`app.gd` `replay_tutorial()`) restarts it in the running town |
| Start behind the loading screen (17 Nov 2026, user: the first dialogue boxes in the house lagged on the web; a longer first load is fine if the bar shows real progress) | `app.gd` `_on_town_ready()` starts the tutorial with `Tutorial.begin(main, false, true)` (`covered`) while the loading screen is still up: the cast is built one plush per frame (`cast_built` / `cast_total` move the bar), the act's first `place` step puts the player and the cast in place without a fade and the director holds there (`prepared`; only `place`, `door`, `lock`, `confine`, `words` steps run while covered). The warm-up then looks round from the bed and draws every view the act shows up to its cutscene (`warm_views()`: each cast member's face close-up, then four headings from each spot of the act's place, walk and wait steps, 1.8 m up, spots closer than 1.5 m merged) and the dialogue box once (`warm_dialogue()`), so their shaders compile behind the screen; then `release()` and the `open_on` close-up starts. The loading bar: scene file 0–15 % (read in the background where threads exist), town build steps to 55 % (weighted, `main.gd` `LOADING_STEP_WEIGHTS`), cast to 70 %, one share per warm-up view to 100 %. Measured: [tutorial-lag-20261117](../evidence/tutorial-lag-20261117/README.md) |
| Cutscene | The loading screen's town pictures with the title (`loading_screen.gd` `show_title()`). Since 16 Nov 2026 (user: the house act lagged) it is also the loading screen for the buildings not loaded yet: `app.gd` `_load_rest()` adds none during the house act and all of them, one after another, while the cutscene is up; it stays at least `cutscene_seconds` (7 s) and until they are in, at most `cutscene_max_seconds` (60 s), with the progress bar under the title ([staged loading](MODULAR_TOWN.md#units-added-while-the-game-runs-home-first--13-november-2026)) |

**Review 2, 21 Nov 2026 (user).** Where this disagrees with the notes below, this wins. Checked
from the market act on (64 checks, 0 failures, with views):
[tutorial-review2-20261121](../evidence/tutorial-review2-20261121/README.md); the house act is
not re-run.
- **Price:** the fruit costs $1.25 (`shop.price_cents` 125: one $1 bill and one quarter; the
  money panel still offers only $1 bills and quarters). The dated check
  `tutorial-polish-20261118/verify.gd` still expects $1.50 (historical; it will fail there).
- **Cashier:** she asks for the money in her face close-up (`tutorial_shop.gd`
  `_hold_cashier_face()`, held by the director as `_held_face`), which stays while the money
  panel is up and through "Perfect! Thank you!"; the shopping list is hidden from the request on
  (`panel.hide_cart()`). The camera then pans to BonBon's close-up (always, wherever she is) for
  "Great job! Let's meet outside!".
- **Leaving the store:** two lines before the park: BonBon's "Everyone ready? Let's go to the
  park!" (`everyone_ready`, `to_park` merged in and removed) and Leo's (`friend_2`) "Yay! Picnic
  time!", the camera panning between them.
- **Faces:** a say step's `"face": "always"` on BonBon's lines keeps the close-up chain whatever
  her distance, so the camera pans from Sunny's "what's that?" to her "Let's take a closer look!"
  and between every picnic line (Sunny and Leo have `"face": true`).
- **Statue:** a `wait` step `"for": "card"` waits until the word card is closed (by itself after
  `card_seconds` or by a click; `hud.is_card_visible()`), then `after` seconds: "It's a statue of
  George Washington!" comes 0.2 s after the card closes.
- **Journal:** `journal_intro` and `take_a_look` are one line ("Every word you find goes into
  your journal. Let's have a look!"; `take_a_look` removed).
- **Last line:** "The whole town is now yours to explore. Have fun!" (`goodbye`, es/en/zh).
- **Box after a pan:** when the close-up pans to the next speaker, that line's box waits for the
  pan (`npc_presence.gd` `PAN_SECONDS` 0.7) and `tutorial.gd` `PAN_BOX_DELAY` (0.25 s) before it
  shows.
- **Picnic blanket:** 6 x 4.75 m, 2.5 times the first 2.4 x 1.9 m (`tutorial.gd` `PICNIC_SIZE`,
  same check size: `PICNIC_CHECKS`), so everyone fits round it; the picnic moved 1.6 m east to
  (77.0, 184.6) to clear the statue's plinth (x up to 72.3), with the standing cast and the
  player on its edges.
- **Produce price tag:** the supermarket's "$1.50" tag reads "$1.25" like the tutorial's price
  (`supermarket.gd` step `price_sign`, baked).
- **After the tutorial:** played to the end (not skipped), the guide and both friends sit round
  the picnic blanket behind a fade, on its edges (`tutorial.json` `after`: `seats` per role and `lines`;
  `tutorial.gd` `_leave_party()`, `house_characters.gd` `seated()` with the house characters'
  seated pose, dressed afterwards, solid with `fit_blocker()`). Each is a TALK
  [interactable](#interaction-system) (E, click or tap) that says its next line in a bubble that
  closes by itself, three per character in turn (`tutorial.after_guide_*`, `after_sunny_*`,
  `after_leo_*`; the seat is `PARTY_SEAT_LIFT` 0.16 m up, on the blanket's top). They are not saved: a reload of a finished profile does not show them, a replay
  removes them at its start (`start()` `_clear_party()`), and a skip never makes them. The house
  twins of the same characters are back at home meanwhile (the same character in two places;
  unresolved, low priority). No face close-up when talking to them.

**Review, 20 Nov 2026 (user).** Where this disagrees with the notes below, this wins. Not
verified in the game yet (parse check only; no tutorial check run, no screenshots).
- **Timings:** the `pause` after the view step is 1 s and after the walk step 0.5 s.
- **Living room:** BonBon says `join_me` in her close-up, a 0.6 s `pause`, then walks to the
  living room at 80 % of the walking speed (a `walk` step's `speed`, a factor; `tutorial.gd`
  `_walk()`).
- **Going outside:** `more_to_show` and `lets_go_outside` are one line, "Let's go outside! There's
  so much more I want to show you!" (3.5 s); the front door opens just before it.
- **Close-ups and box:** the tutorial's close-ups are closer and lower (`tutorial.gd`
  `FACE_DISTANCE` 2.8 m, `FACE_ELEVATION` 8°, set on each `npc_presence.gd` instance's
  `face_distance` / `face_elevation`; minigames keep 3.6 m and 18°); the dialogue box has no tail
  while the tutorial runs (`shop_order_panel.gd` `tail`).
- **Market:** BonBon's "What a beautiful day! Let's have a picnic!", the friend's "Yay! Let's pick
  up some fruit for our picnic!" (`need_food`), then straight to the clerk's "Hello! Welcome to the
  supermarket!" and "Here's a basket for you!" (`to_supermarket`, `get_list` and the
  `click_item` bubble are gone from the script). The first time the player comes within 3 m of the
  fruit table's apples (`tutorial_shop.gd` `_apple_close_up()`), the camera eases in on them and
  BonBon's `click_apple` line shows until something is picked; the player holds still meanwhile
  and clicks aim from the camera on screen (`interaction_controller.gd` `aimed_hit()`).
- **21 Nov 2026 additions (user):** back-to-back close-ups now PAN from face to face
  (`npc_presence.gd` `cut_from()`, `PAN_SECONDS` 0.7; was a cut); the clerk's two lines keep one
  close-up; the close-up hides the player's model when any part of the body (not only its centre
  line) is in the picture or the camera is inside it (`_hide_player_if_in_view()`,
  `PLAYER_RADIUS` 0.6; Leo greeted from in front); a right item picked hops with gold sparks
  (`success_burst.gd`, the library game's, now shared); 3 s in the apple close-up without a click
  shows a pulsing ring and a mouse pointer or fingertip on the apple (`tap_hint.gd`). Parse check
  only; not played.

**Polish, 18 Nov 2026 (user's list).** Where this disagrees with the notes below, this wins.
Check: [`tutorial-polish-20261118/verify.gd`](../evidence/tutorial-polish-20261118/README.md)
(the `tutorial` check).
- **Timings in the data:** a say step's `seconds` replaces the reading time (`look_around` 1.8 s,
  `meet_friends` 2.0, `where_are_they` 2.3, `help_find` 2.0, `more_to_show` 3.0,
  `lets_go_outside` 2.0); the view step needs `turn` 2 rad and is followed by a 2 s `pause`, the
  walk step 10 m and a 1 s `pause`; `remark_seconds` (phrase id → seconds) shortens remarks
  (`not_right_place`, "That's not where we are going right now!", and `not_there` 2 s,
  `not_on_list` 1.5 s). A `door` step may name its door (`name`): the front door opens itself
  after `more_to_show`.
- **Screen:** the dialogue box has no ✕ (`shop_order_panel.gd` `closable`), the HUD clock is
  hidden (`day_clock.gd` `set_hidden()`), the Skip button sits where the clock was and hides while
  an instruction strip shows; no "press E to open the shower curtain" strip (the objective stays).
- **Close-ups cut:** a line followed by another line with a face keeps its close-up and the next
  one cuts straight to the new face (`npc_presence.gd` `cut_from()`), never through the player's
  view (Sunny → BonBon after the hunt, BonBon → Sunny at the market).
- **Market:** the cast stands behind the player from the start and never walks during the act
  (the walks and the closing pause are gone); the clerk and cashier are named in the native
  language; "Great! We got everything! Let's go pay!" (`got_everything_pay`) is one 2 s bubble in
  BonBon's close-up; the cashier's amount has no digits and the strip shows "Don't understand?
  Hold EN…" (`show_peek_strip()`) while the request is up; no Inspect button while the money panel
  is open (`hold_inspect_ui.gd`); walking out counts anywhere 0.5 m past the doorway
  (`tutorial_shop.gd` `_walked_out()`), so "walk out of the store" is no longer said outside.
- **Lot:** base step `tutorial_lot_clear` (see [parked vehicles](ZOO_VEHICLE_IMPLEMENTATION.md#more-parked-vehicles--14-november-2026)).

**Script revision, 17 Nov 2026 (user script "Little Town of Words").** The current tour; where
this disagrees with the rows above or the 13–14 Nov notes below, this wins.
- **Pacing:** no Next buttons. Each line stays for a reading time (`tutorial.gd`
  `reading_seconds()`: 1.4 s + 0.055 s per character, 2.2–8 s), then 0.6 s (`LINE_GAP`) before
  the next; a click, a tap, E or Enter skips ahead. BonBon's short remarks (`remark()`: wrong
  door, locked door, "Hey! The supermarket is this way!", "Oops!", "Wait! We haven't paid yet!")
  are timed bubbles that never hold the steps.
- **Instruction strip:** the "UI" lines of the script ("Press E to get up", "Drag the curtain to
  open it", "Find BonBon's two friends 1/2") show in the reusable
  [instruction strip](COMPONENTS.md#instruction-strip) (`scripts/ui/instruction_strip.gd`), not
  the speech bubble. Steps set it with `strip` / `touch_strip`, or the `strip` step type.
- **Controls unlock in order** (`controls` step; `player_controller.gd` `look_allowed` /
  `move_allowed`, `interaction_controller.gd` `interact_allowed`): only E in bed, then the view,
  then walking (interactions still off), then everything. Nothing moves while a line is spoken.
- **Find the friends** (`find` step): the bathtub friend (Sunny) and Leo in the yellow bedroom may
  be found in either order. Leo does not move (user: only his lines changed). The curtain opens by
  dragging it across (`DRAG_PIXELS` 90 × scale, within `CURTAIN_REACH` 4.5 m); a plain click does
  not open it. Each find: the word card, a pause, then the friend's hello in the language being
  learned with a face close-up. Hints come only when the player talks to BonBon, more precise
  each time, always about a friend not found yet. The house's other doors: open-able rooms that
  are not part of the hunt get BonBon's remark; the rest say "This door is locked! Let's look
  somewhere else." (`lock` `remark` doors and `line`).
- **Cutscene** shows the subtitle "Little Town of Words" (`loading_screen.gd` `show_title()`
  `subtitle`) and can be skipped by a click, tap or key after 1 s.
- **Market:** 1 apple, 2 bananas, 3 cookies for $2.50 (`data/tutorial.json` shop `items`). The
  list stays up; a line done gets a check mark and a bounce (`shop_order_panel.gd` `done` / `pop`,
  sound later); a wrong item gets "Oops!". Paying is "Pay with cash" in the
  [money panel](COMPONENTS.md#money-panel-options) with only $1 bills and 25¢ (`only`) and the
  instruction in the empty tray (`hint`); a wrong amount gets "Hmm... try again", unlimited, with
  the panel's reset. The cast walks in and out on fixed waypoints.
- **Park:** the statue card reads "statue of George Washington" (`data/words.json` `statue`), then
  the journal (open, close), then a simple picnic east of the statue: a gingham blanket with the
  basket of what was bought (`_make_picnic()`; 13 cm up, since the park lawn is drawn 5–10 cm
  above its collider), the cast around it and closing lines (placeholders, to be rewritten).
- Check: `docs/evidence/tutorial-script-20261117/verify.gd` (the `tutorial` check until the
  second review below; since 18 Nov 2026 `tutorial-polish-20261118/verify.gd`, see the polish below), see its [README](../evidence/tutorial-script-20261117/README.md). The older check
  `tutorial-20261112/verify.gd` and its notes below are history.

**User review, 17 Nov 2026 (evening).** Where this disagrees with the notes above, this wins.
- **Close-ups:** BonBon's lines are shown in her face close-up (`npc_presence.gd`) whenever she is
  within `GUIDE_FACE_RANGE` 8 m and not walking (`_say_face()`, `_guide_face_ok()`); consecutive
  lines of the same speaker keep the close-up (`_held_face`).
- **Replies:** a `say` step's `reply` is a button the line waits for (a click elsewhere does not
  move it on; E / Enter presses it). "Ready for an adventure?" waits for "Yes!" before the
  close-up eases back; each friend's greeting waits for "Hi! Nice to meet you!" in the language
  being learned (`find` step `reply`).
- **Controls:** the view step waits for a real drag of 1.5 rad (zooming counts only where a step
  sets `zoom`; walking stays off); the walk step counts the way walked, 6 m. Only doors (and the
  shower curtain) and BonBon can be used during the tutorial (`interaction_controller.gd`
  `interact_filter`; seats, faucets, stations and vehicles are not even focused). In the market
  and park acts every door outside the supermarket says "That's not where we're going right
  now!" (`lock` step `space: world`, `open_in` units; doors of buildings that load later are
  locked when they come in). Most town buildings have open doorways and register no doors (the
  supermarket, library, school and bakery among them, measured 17 Nov 2026); the 14 town doors
  are inside buildings such as the bank, police station and hospital.
- **Shower curtain:** shut until the hunt (`_lock_curtain()`), then it opens with E or a click
  like any door; the strip says "Press E to open the shower curtain." (no drag, no "someone
  behind the curtain?" line).
- **HUD:** the minigame picker (▶) and the Run button are hidden for the whole tutorial and running is off (`_process()`); the EN button and the
  journal button are hidden until introduced and pulse then (`vocabulary_hud.gd`
  `tutorial_hidden`, `tutorial_pulse`). The EN button comes with the first friend's greeting:
  the strip says to hold it, and the reply shows once it was held (`_introduce_peek()`; skipped in
  Native mode). The journal button comes with the journal step and stops pulsing once opened.
- **One language toggle:** holding EN (or L) also flips the dialogue box to the native language
  (`shop_order_panel.gd` follows `GameSettings.peek_changed`); the box has no translate bubble
  of its own any more. See hold-to-peek in [vocabulary data procedure](#vocabulary-data-procedure).
- **Clock and pace:** it starts at noon (`START_MINUTES`, `day_night.gd` `set_time()`); the cast
  walks at the player's walking speed (`_walk_speed()`, `player_controller.gd` `walk_speed`).
- **Title cutscene:** not skippable until every building is in (bar to 80 %) and the market and
  park acts' views (cast and shop-staff close-ups, a look round each spot, the picnic) are drawn
  behind it (to 100 %); only then does "Click or tap to skip" show. The market and park acts used
  to lag because it could be skipped with 14–17 buildings still loading, which then came in at
  their quiet moments ([lag notes](../evidence/tutorial-lag-20261117/README.md)).

**User review, 17 Nov 2026 (second round, nine fixes).** Where this disagrees with the notes
above, this wins.
- **House doors:** the player can open only the hiding friend's door (Yellow bedroom) and, after
  the hunt, the front door. Every other home door stays shut and the guide says in a bubble "I
  don't think my friends would hide there." during the hunt, "That's not where we're going right
  now!" otherwise (`lock` step `say: true`, `remark_line`, `line`; `_say_locked()`). A locked door
  the tutorial opened (the suite door, the family bathroom) cannot be used, so it cannot shut the
  player in. The old `remark` doors (open with a remark) and `tutorial.door_locked` are gone.
- **Close-ups:** "You found one / everyone", "There's so much more I want to show you!" and
  "Let's go outside!" are in the guide's close-up although she waits in the living room
  (`say()` `always`; a step's `"face": "always"`); Sunny's "But wait... we need some food first!"
  is in her close-up (`face: true`). "Let's take a peek!" was dropped.
- **Guide stand-in:** a player whose avatar is BonBon (the default avatar) is guided by the next
  house character in data order not in the cast (Bruno today), like the friends' stand-ins
  (`_cast_actors()`).
- **House twins:** every seated house character is hidden while the tutorial runs, not only the
  cast's twins (the player's own character sat on the couch), and their naps are off: sleepers
  go back to their seats (`house_characters.gd` Bedtime `wake_all()`, `_set_naps()`).
- **Replay:** act 1 starts with every home door shut (`_reset_props()`; a replay found the front
  door open and a twin napping on the guest bed).
- **Market:** the cast walks to the store front south of the player's way to the door (the old
  spots boxed the player in); the list is 1 apple and 2 bananas for $1.50 (the cookies and their
  hints were dropped; the picnic line is "These bananas are yummy!").
- Check: `docs/evidence/tutorial-review-20261117/verify.gd` (`tutorial`, replaces
  `tutorial-script-20261117`), see its [README](../evidence/tutorial-review-20261117/README.md).

Props it uses: the family bathtub's own curtain (`Family bathtub/Shower curtain`, a
`door_animator.gd` `curtain` built by `home_furnishing.gd`; the tutorial draws it across the tub
when act 1 starts and waits for the player to pull it back; since 13 Nov 2026 the tub is on the
bathroom's west wall, so the drawn curtain faces the doorway, and the friend inside stands at
home (-10.16, 0.3, 9.61) looking east, [record](REFERENCE_HOME.md#family-bathroom-re-laid--13-november-2026)) and the word "statue" on the
Washington statue (base step `statue_word`). Since the 13 Nov 2026 merge with the bigger home
the tutorial's own curtain (`shower_curtain.gd`, step `shower_curtain`) is gone, and act 1 was
re-placed: the player wakes in the yellow bedroom, the second friend waits in the guest suite.
**User review, 13 Nov 2026** (the current tour, `data/tutorial.json`):
- The player wakes in the **guest suite** (the bigger south-east bedroom), BonBon leads through the
  living room to the family bathroom, and the second friend hides in the **yellow bedroom**.
- `lock` steps: every home door except the suite, family bathroom and yellow bedroom ones answers
  "They're not hiding in here!" (the door's interactable `on_check` returns the line); the front
  door joins them before the walk outside; unlocked when the market act starts and on stop.
- The family bathroom door opens inwards (home step `family_bath_door_inward`).
- Living-room staging (user, 14 Nov 2026, from a phone screenshot: "where I am standing here,
  next to the chair"): the family bathroom door is opened by a `door` step before the first
  `place`, so the bathtub friend is behind one thing (the curtain) instead of two; the wait for
  it is now "near" the bathroom inside. BonBon walks to the living room beside the teal chair
  (site (-0.3, 7.0), out from the west wall; she used to wait at (-3.4, 7.0) by the TV) and the
  walk's `look` turns her whole body between that door and the suite the player comes from, as
  if inviting them from the bedroom into the bathroom (a plush's `Head` is never rotated,
  [components](COMPONENTS.md#ownership-and-priority)). Doors opened by `door` steps are closed
  again when the tutorial ends or is skipped (`tutorial.gd` `_opened`; before, they stayed open).
- The bathtub friend's close-up uses a fixed camera spot (cast `camera` → meta
  `talk_camera_at`, `npc_presence.gd`), straight in front of the tub; the automatic spot was
  blocked by the tub and walls and swung to the side.
- `confine` steps (`tutorial.gd` `_physics_process`): the market act keeps the player inside the
  supermarket and its parking lot (two world rects, "Let's stay together by the supermarket for
  now!"); the statue step holds the player still (`hold`) until the statue is clicked.
- The statue step says "Click on the statue to reveal it!", only the statue opens a card
  (`words` `only` → `interaction_controller.gd` `word_filter`), and BonBon then says "It's the
  statue of George Washington!".
- These limits keep the player in places that are loaded, so more of the town can load later
  ([staged loading](MODULAR_TOWN.md#units-added-while-the-game-runs-home-first--13-november-2026)).
Face close-ups (`npc_presence.gd`)
wait until the previous one has eased back, since a close-up returns to the camera that was
current when it started.

Check (before 17 Nov 2026, superseded by `tutorial-script-20261117`): `docs/evidence/tutorial-20261112/verify.gd`: a play-through with simulated
events; with graphics it saves the views `wake`, `bath-door`, `bathroom`, `friend`, `cutscene`,
`shop-greeting`, `shop`, `fruit`, `basket`, `pay`, `statue`, `journal` in that folder (the greeting, basket,
coloured terms, door wall and 3 s thanks since 14 Nov 2026).
Run of 14 Nov 2026 (shop basket review), headless, `VT_FOCUS=all`: **81 checks, 1 failure**,
"the cart opens for the order": the check looked two frames after the clerk's second line, which
first waits up to 0.8 s for the greeting's close-up to ease back; every later shop check passed
(fruit picked into the basket, door wall inside and unpaid, walking out stopped, native amount
with digits, thanks closing itself after 3 s, door open after paying, basket taken back). The
check now waits for the cart; not re-run. The graphics run of the same day stopped drawing after
the cutscene (no error), so the new views `shop-greeting`, `basket` and `pay` were not rendered.
`docs/evidence/shop-basket-20261114/verify.gd` (supermarket order game, `VT_FOCUS=supermarket`):
**13 checks, 0 failures**. `tools/language_check.gd`: 2 failures that predate this change
(`restaurant.miss_also` placeholders in zh; zh readings missing for 備 質 素 暢 揭 喬 臥 桌). Since the 13 Nov 2026 review it also checks the
suite start, the locked doors, the inward bathroom door, the bathtub camera spot, the lot limit
and the statue hold and filter (66 checks). Since 14 Nov 2026 also the open family bathroom door,
BonBon's living-room spot, the hidden and restored mahjong table, the "Skip tutorial" label, the statue card
closing by itself and the doors closed after Skip, with views `wake-bed`, `living-approach` and `living-player`. Since 13 Nov 2026 it also clicks for real (the pointer on the
object's screen point, then `interaction.click()`): the suite's bed (was the bedroom curtain) during the house tour (no
card), the fruit table's apple and banana, and the statue when it is under that point; and it
talks to BonBon during the bathroom step and checks every wait step's `where` line. Walking the cast uses fixed waypoints (no navigation): keep them clear
when changing the home, the supermarket front or the statue lawn.

## Chair/bench interaction ownership — 28 October 2026

Main creates `scripts/player/seating_controller.gd` after world construction and
interaction setup, before garden batching. It owns seat registration/reach/exit
queries; player_controller owns the animated seated state. Since 12 Nov 2026 each seat is an
[interactable](#interaction-system) and E while seated goes through Main's `seat` claim. No learning or save schema changes.
See [BonBon sitting guide](BONBON_VALIDATION.md#sitting-on-chairs-and-benches--28-october-2026)
for controls, optional seat metadata, source references and verification.

### Animal scale and movement — 31 October 2026

Current behavior, fixed measured snake minimum, all species scales, post-layout
configuration, terrain exclusions and verification are owned by
[Animal system](ANIMAL_SYSTEM.md). This supersedes earlier circular wandering
and sub-snake display sizes; preserve the existing prefab/word-root ownership.

### Customer order ownership — 3 November 2026

Missions (`learning_quests.gd`, Q key, quest panel, `relocate_quests`) were deleted; `flash_quest_message` in
the HUD stays as the generic toast. The shop minigame is data-driven; see the
[design record](TOWN_DESIGN_BRIEF.md#customer-order-minigame--3-november-2026) for purpose and flow.

| Part | Owner |
| --- | --- |
| Per-store rules (zone, clerk node name, `clerk_gender`, item counts, retries, `needs_help_chance`) | `data/shops.json`, read by `scripts/learning/shop_dialogue.gd` |
| Phrases (`shop.*`, `common.*`), words, languages | `data/phrases.json`, `data/words.json`, `data/languages.json` through the shared Lexicon ([vocabulary data procedure](#vocabulary-data-procedure)); `shop_dialogue.gd` adds the order-list, word-pair, role and money fillers. Until 4 Nov 2026 all of this was `data/shop_dialogue.json` |
| Order rules and state machine (no nodes) | `scripts/learning/shop_order.gd` |
| One controller per store: clerk tagging, zone enter/leave, click routing, retries | `scripts/learning/shop_session.gd`, created per store by `Main.make_shops()` |
| "!" marker, hop and face-zoom `TalkCamera` of any minigame NPC (moved out of `shop_session.gd` on 4 Nov 2026; the session decides when it calls) | `scripts/learning/npc_presence.gd` (child node `Presence` of each session) |
| Dialogue box, cart card, quit prompt (text only, draws what it is told) | `scripts/ui/shop_order_panel.gd` |
| Clerk click / E and cart clicks | The clerk is a TALK [interactable](#interaction-system) (`minigame_host.gd add_talker()`; the `clerk_activated` signal and `shop_clerk` meta were removed 12 Nov 2026); cart clicks: `interaction_controller.gd` `pick_hook` |
| Clerk placement | `library_market_interiors.gd::staff()` (BeagleClerk, market-local (-37.6, 0.1, 31.0), outside, left of the door) |

Session flow: dialogue → (zoom out) cart → Listo → "return to the clerk" (`awaiting_return`) → next clerk click reports the verdict. The face-zoom `TalkCamera` lives in the session's `npc_presence.gd` child. Store goods are enlarged by `goods_scale()` and fridge/cooler fronts use `blocker()` (non-word pick stoppers) in `library_market_interiors.gd`.

Placement rule: never put a door and a clerk within one click/E target of each other (both would fire).

### Cashier money minigame ownership — 4 November 2026

Design record: [Cashier money minigame](TOWN_DESIGN_BRIEF.md#cashier-money-minigame--4-november-2026).

| Part | Owner |
| --- | --- |
| Denominations, weighted random cents, validation, `usd()` digit form (pure, no scene) | `scripts/learning/currency.gd` |
| Amounts in words | each language's `money_words()` (`scripts/language/rules_es.gd`; moved from `currency.gd::spanish_amount()` on 4 Nov 2026), paired with `usd()` by `shop_dialogue.gd::money_values()` |
| Money screen (modal, key lock, tray, scaling) and drawn bills/coins | `scripts/ui/money_panel.gd`, `money_piece.gd` |
| Flow per cashier (request → count → verdict → retry/explain/quit) | `scripts/learning/cashier_session.gd`, created per `cashiers` entry by `Main.make_shops()`. Since 21 Nov 2026 the till: it charges the Grocery Run basket and free-shopping baskets, owns the basket racks and the shop door ([checkout](TOWN_DESIGN_BRIEF.md#grocery-checkout-and-free-shopping--21-november-2026)) |
| Phrases (`cashier.*`, `money.*`) and `cashiers` {zone, npc, npc_gender} | `data/phrases.json` (Lexicon) and `data/shops.json` (`shop_dialogue.gd`) |
| Dialogue box (shared with the clerk) | `scripts/ui/shop_order_panel.gd`; both sessions listen to its signals and each acts only while it owns the box (`cashier_*` choice ids never clash with the clerk's) |
| Player lock while the screen is open | `Main.sync_player_controls()` (also driven by the panel's `visibility_changed`) |
| Cashier | `SamoyedCashier` (`library_market_interiors.gd::staff()`), a TALK interactable through the host (until 12 Nov 2026 the `shop_clerk` meta and `clerk_activated`) |

### Hospital family game ownership — 4 November 2026

Design record: [Hospital family game](TOWN_DESIGN_BRIEF.md#hospital-family-game--4-november-2026).

| Part | Owner |
| --- | --- |
| Age gap rules, portrait species, question-kind weights, tree templates (people, parents, partners, layout cells) | `data/family_game.json` |
| One round's family: names (`data/names.json`, foreign language), ages and birth dates from the shared "today" (`scripts/learning/game_clock.gd`, since 5 Nov 2026), kinship `relation(a, b)` → Family word key and `kin(a, b)` → the word plus `side`, `elder`, `link`, `by_marriage` for languages that need them, such as Chinese (Stage 4a); `labeler` makes relationship questions unique by the learner's label (pure). The Lexicon passes `kin` to the rules modules inside the word entry | `scripts/learning/family_tree.gd` |
| Question generator and validator (8 kinds; `answers()` recomputes the answer set; only one-answer questions are returned; yes/no truth chosen first) (pure) | `scripts/learning/family_questions.gd` |
| Sentences (`family.*`; `posters.age` for card ages) | `data/phrases.json` through the Lexicon |
| Family panel (modal, key lock, Esc, cards with portrait / name / gender icon / age / MM/DD/YYYY, lines, Yes/No, marks, highlight of the people the question names (`ui.named` from `family_questions.gd` `named()`), scaling) | `scripts/ui/family_panel.gd` |
| Plush head portraits, rendered once per species into a SubViewport and reused | `scripts/ui/plush_portraits.gd` |
| Flow (Dr. Li's "!" when the player is within 30 m, greeting in the shared dialogue box, panel, retry, next, goodbye, walk-away) | `scripts/learning/family_session.gd`, created by `Main.make_shops()`; makes `DrLi` a TALK [interactable](#interaction-system) through the host (until 12 Nov 2026 the `shop_clerk` meta) |
| Player lock while the panel is open | `Main.sync_player_controls()` |

Adding a question kind: a phrase per language in `family.*`, a `_draft()` and `answers()` case
in `family_questions.gd`, a weight in `kinds`; `docs/evidence/family-game-20261104/verify.gd` then
checks that every generated question has one answer and renders in every language. A new tree
template needs only data; keep 7 people (user decision; the logic check enforces it) and make
sure the templates together still give every relationship word.

### Airport flight game ownership — 5 November 2026

Design record: [Airport flight game](TOWN_DESIGN_BRIEF.md#airport-flight-game--5-november-2026).
The startup-pass owner `airport_interior.gd` named below was baked into `scenes/town/airport.scn`
and deleted on 6 Nov 2026; change the terminal with steps in `scripts/buildings/airport.gd`.

| Part | Owner |
| --- | --- |
| Shared "today" and "now" (random 2026–2027, once per launch), date/weekday/clock helpers (24-hour `clock()` for logs, 12-hour `clock12()` / `is_am()`, `month_day()`, Sunday-first `sunday_column()`); also the family game's reference date | `scripts/learning/game_clock.gd` |
| Country pool (8) and their airport codes, `directions` (dep / arr), board size (since the night of 8 Nov 2026: `tab_rows` 6 a tab, `target_rows` 3 of the asked country, `max_per_country` 3 a tab), `cluster_for` (which cluster kind each question kind is built from), `min_decoys` (2), `long_kinds` (no country, no *va a*), `max_words` (12), `no_flight_hours` (12, 19, 20), board range, question-kind weights, `day_in_words` | `data/flight_game.json` |
| The flights (codes, dates, times, direction, departed / arrived or not, unique times): the clusters of related times, `make()` / `filler()` / `finish()` used by the question's board (since 8 Nov 2026 the board is built per question, not at setup) | `scripts/learning/flight_schedule.gd` |
| Question generator and the board built for it (`design()`: answer, near misses, country trap, verb trap, fillers; one per question since the night of 8 Nov 2026): predicates, validation (one match, decoys with the same direction, near miss; a country-less question only when the verb decides, `verb_misses()`), tense and direction (`_to` / `_from` / `_arr` phrases), explanations naming the tested expression, the tracked time word, the time expressions as Lexicon refs | `scripts/learning/flight_questions.gd` |
| Sentences (`flight.*`; a.m. / p.m. markers `flight.time_am` / `time_pm`, calendar `calendar_title` and `cal_sun`…`cal_sat`, play again `again` / `play_again`), poster titles (`posters.relative_title`, `calendar_title`, `airport_title`), new words | `data/phrases.json`, `data/words.json` through the Lexicon |
| Panel (board only since 7 Nov 2026: flag + airport code, one day column, no status; no scroll bar (rows shrink to a 12 pt minimum; 6 rows a tab fit); two-label bilingual cells; since 8 Nov 2026 a digital clock (today's weekday and the time) and a Sunday-first month calendar without day names (native-language names with translations) right of the board, and Salidas / Llegadas tabs over it (`tab`, `select_tab()`; the player's choice); marks, explanation, summary, translation, scaling) | `scripts/ui/flight_panel.gd`, created by `Main.make_shops()` |
| Country flags (painted in code, cached textures; panel rows and poster cards) | `scripts/ui/flags.gd` |
| Flow (Bruno's "!", offer, questions, first-try progress, practice tracking, leave question, summary, play-again question after Finish; E on the board or the booklet prop opens the board). Also what the panel shows: the day column's content (weekday word, or month/day date for weekday questions), 12-hour times with the foreign marker, the clock and the calendar cells | `scripts/learning/flight_session.gd`; `Main` E branch calls `handle_use()` |
| Desk right of the door, sign, booklet prop (`flight_info` meta), four front-wall posters (countries with flags), Captain Bruno (`PilotBruno`) | `scripts/world/airport_interior.gd` `information_desk()` (layout of 6 Nov 2026) |
| Offer chance and target (5) | `data/activities.json` `flight_bruno` |

Poster labels on the airport's front wall carry the `interior_label` meta so
`building_exteriors.gd` `hide_front_labels()` (which hides old facade sign text) keeps them.
Adding a question kind (redesign of 7 Nov 2026): a `time_for` / `fits` / `near_misses` /
`time_key` case in `flight_questions.gd`, a schedule cluster in `flight_schedule.gd` that gives it
near misses, its phrases in every language, a weight in `flight_game.json`; the logic check
(`docs/evidence/flight-board-20261107/verify.gd`, runner id `flight_logic`) then proves every kind can be
asked in every schedule, each question has one matching flight, enough decoys and a near miss,
and everything renders in every language. With 3 shown countries and 4 cluster kinds, a new
cluster kind must either serve kinds no other cluster serves (and then every board needs it)
or join an alternative list such as `["days", "mix"]` (8 Nov 2026: leaving the hours cluster
out of a quarter of the boards made *hace / dentro de … horas* unaskable there). The panel and
flow in the town: `docs/evidence/flight-board-20261108/capture.gd` (graphical, not in the runner).

### Restaurant game ownership — 6 November 2026

Design record: [Alta Cocina restaurant game](TOWN_DESIGN_BRIEF.md#alta-cocina-restaurant-game--6-november-2026).

| Part | Owner |
| --- | --- |
| Courses, menu size, difficulty (sizes, intensity and negation chances), property schema (taste colours, temperature levels and words, ingredients with their *con / sin* phrases; textures and extras removed 11 Nov 2026), the 38 dishes with explicit properties and art | `data/restaurant_game.json` |
| Menus, the matcher, order generation (exactly one match, partial distractors, recent properties avoided; fewer requirements when a size has no unique set, 11 Nov 2026), the missed requirement, order text, the customer's "I'd like to order ..." (`intro_ref`), several sentences in one line (`sentences`) and Twinkle's wrong-dish report, one sentence per wrong dish (`report_ref`), as Lexicon refs | `scripts/learning/restaurant_orders.gd` |
| Sentences (`restaurant.*`: orders, fragments, joiners, feedback, UI), poster titles (`posters.tastes_title`, `textures_title`, `ingredients_title`, `menu_title`), new words | `data/phrases.json`, `data/words.json` through the Lexicon |
| Dish pictures, 28 property icons, bars, thermometer, poster icon sheets | `scripts/ui/food_icons.gd` |
| Order tablet since 11 Nov 2026 (bezel and screen, customer and order bubble, four course tabs, dish list, inspection page with taste rows of pill bars, Choose this dish, the order slip (each course's request and its chosen dish; the bubble shows only the courses) and Send order, "Order sent!" with every dish, summary, translation, scaling; `taste_rows()`, `thermometer()`, `ingredient_icons()` shared with the book) | `scripts/ui/restaurant_panel.gd`, created in `minigame_wiring.gd` |
| Menu book (cover and one spread per course, bookmark tabs, ◀ ▶ and ← →, page-turn animation, translation) | `scripts/ui/restaurant_menu_book.gd` (Main field `restaurant_menu_book`, in `PANELS`, locking the player) |
| Flow (11 Nov 2026: Twinkle's offer, sending the player to one of two customers (unnamed), the customers' "!" and lines, 2–3 courses per visit with the courses first and the requests `INTRO_SECONDS` later, order -> tablet -> send, thanks and the verdict after `VERDICT_SECONDS`, Twinkle's report, next customer / stop, the words at the target, new guests and a new menu after a game; the menu book on the table; the entrance wall and leave question while a game runs, `_build_door` with the shared door guard `minigame_zone.gd` `make_door_guard`) | `scripts/learning/restaurant_session.gd`; `minigame_host.gd` `ask_leave(question_id)` asks a game's own question |
| Seating a runtime plush on a seat | `scripts/characters/house_characters.gd` `seated()` |
| Customer seat markers (`RestaurantCustomerSeat`; `RestaurantCustomerSeat2` and the menu table with `RestaurantMenuBook` from step `dining_game_tables`, 11 Nov 2026, which also took the textures poster down) and the icon posters | Built by `scripts/world/restaurant_venues.gd` `restaurant_game_room()`, `icon_poster()` (deleted 6 Nov 2026 with the startup passes; now saved in `scenes/town/restaurants.scn`). Posters moved to the rear wall, Twinkle/host stand and the west table moved inward, window glass and wall finish: `scripts/buildings/restaurants.gd` `dining_room_refresh` (8 Nov 2026) |
| Offer chance and target (4) | `data/activities.json` `restaurant_twinkle` |

Adding a dish: an entry in `restaurant_game.json` (its word must exist in `words.json` and
appear in town, e.g. on the MENÚ board), art from `food_icons.gd` layers. Adding a property:
the schema entry, its icon in `food_icons.gd` `PROPERTY_ICONS`, its word and phrases in
every language. Then run the logic check, which proves every generated order has exactly one
matching dish and renders in every language.

### Police detective games ownership — 6 November 2026

Design record: [Police station enlargement and detective games](TOWN_DESIGN_BRIEF.md#police-station-enlargement-and-detective-games--6-november-2026).
Practice tracking: the lineup is deliberately untracked (two clue words a round; user
decision 7 Nov 2026); the evidence game is tracked since its redesign (8 Nov 2026, one word a
round); see the [practice tracker](#practice-tracker).
**Evidence game redesign, 8 Nov 2026** ([decision](TOWN_DESIGN_BRIEF.md#police-evidence-game-redesign--8-november-2026)):
the rows below marked *(8 Nov)* replace the original evidence design (two clues on colour,
size, length, shiny/dark, hard/soft, rough/smooth, wet/dry and loud/quiet/noisy; Mirar /
Tocar / Escuchar / Elegir; the card inset). The startup-pass owners named below
(`police_interior.gd`, `police_posters.gd`, `world_refinements.gd`) were baked into
`scenes/town/police.scn` and deleted on 6 Nov 2026; change the station with steps in
`scripts/buildings/police.gd`.

| Part | Owner |
| --- | --- |
| Shell 20 × 22 (front fixed), new roof, moving the baked rooms, partitions; finishes, lineup room, evidence room and table, game anchors (`LineupStage`, `LineupCamera`, `EvidenceTable`, `EvidenceCamera`), lights | `scripts/world/police_interior.gd` `enlarge()` (always, after `resize_supermarket()`) and `build()` (dev focus `police`). Coordinates in that file are **design coordinates** mirrored about the door axis x 43 when placed (`mirror_point()`, `mirror_node()`; see its header) |
| The two teaching posters | `scripts/world/police_posters.gd` (school poster kit; baked). *(8 Nov)* The evidence poster's words: `scripts/buildings/police.gd` step `evidence_poster_words` (three columns, tool verb over its two properties) |
| Lobby layout *(8 Nov)*: reception against the right side wall, waiting chairs by the entrance, second workstation and OFFICERS sign removed, *¿Cómo es?* poster on the side wall, lineup room door (hinge, opens inward) and dark window; follow-up: reception 1.7 from the wall, beagle receptionist (`ReceptionOfficer`) on a staff platform, modelled chairs with legs (`_chair_mesh()`) ([decisions](TOWN_DESIGN_BRIEF.md#police-lobby-rearrangement--8-november-2026)) | `scripts/buildings/police.gd` steps `lobby_layout`, `reception_officer_chairs`; views `docs/evidence/police-lobby-20261108/capture.gd` |
| Officers: crocodile (lineup) and cat (evidence), both "police officer" | `world_refinements.gd` `police_officer()` |
| Suspect attributes and looks, evidence objects and properties, clue lists, counts. *(8 Nov)* Evidence: `rounds` (find / report order), `dims` (property pair -> tool), fixed real properties per object kind (`weight_from` can derive weight from length; unused since the second pass), `opposite` and `adjective` per clue. *(8 Nov, second pass)* Ten objects: stone, coconut, frying pan, dumbbell, key, pencil, ball, pillow, sponge, towel, one size each, colour variants only ([audit](TOWN_DESIGN_BRIEF.md#second-pass-objects-result-badges-button-translations-8-nov-2026)) | `data/detective_game.json` |
| Round generation and checking (exactly one answer, near-miss distractors, balance, no repeated pair, the failing clue). *(8 Nov)* Evidence: `generate_evidence(rng, type)`, one clue, three opposite distractors or one object with two `options`; `round_type()`, `opposite()`, `values_of()` | `scripts/learning/detective_clues.gd` |
| Building a suspect (cream bear plush; hair and beard as shells fitted to the bear's body profile: cap with combed grooves and fringe, long hair to the shoulders, jaw beard; moustache, nose with gloss, lashes, shirt with round collar and rolled neckband, height × width, untested blush / ear variety, pick area). The bear's parts are re-centred meshes: change them through their node transforms ([art pass](TOWN_DESIGN_BRIEF.md#police-station-enlargement-and-detective-games--6-november-2026)) | `scripts/learning/suspect_builder.gd`; shirt through `plush_costume.gd` `dress_pieces()`, dressed first so it comes from the sculpt cache |
| Evidence objects and the shelf exhibits' models. *(8 Nov)* The tool result icons over the objects (`badge()`, SVG like `ui_icons.gd`: soft, hard, rough, smooth, heavy, light); the dark tint and wet drops are gone. *(8 Nov, second pass)* Models in the product art style through the shared builder of `supermarket_products.gd` (`model(kind, tint)`, one merged mesh); badges are navy pins in the card's colours (`badge_svg()`) | `scripts/learning/evidence_props.gd`; the shelf exhibits are swapped by `scripts/buildings/police.gd` step `evidence_shelf_objects` |
| Card (round, progress, clue, feedback, tools, next, end-of-game word summary; clicking a suspect or an object answers, no "¡Es este!" button since 8 Nov 2026). *(8 Nov)* The report round's answer buttons (`set_choices()`, `choice_pressed`); the Tocar / Escuchar inset was removed; with the translate bubble on, every button shows its translation on a second line (`GameSettings.stacked()`) | `scripts/ui/detective_card.gd`, created by `Main.make_shops()`; tool icons `squeeze`, `touch`, `lift` in `ui_icons.gd` (`look`, `ear`, `choose` unused since 8 Nov) |
| Flow for both games (offer, fixed camera, picking, keys, tools, feedback, leave question, word summary, suspects' breathing / blinking / lean and the hovered spot light). *(8 Nov)* Evidence: tools examine every object in turn (`_on_tool()`, `_examine()`), find answers (`_answer_object()`), report answers (`answer()`), agreement (`_agreed()`: a phrase's `_f` variant when the object's noun is feminine in that language, `words.json` forms `gender`), practice records | `scripts/learning/police_detective_session.gd` (modes `lineup`, `evidence`; two instances) |
| Sentences (`police.*`), poster titles, 33 new words. *(8 Nov)* Evidence: `police.find`, `report`, `correct_found`, `wrong_found`, `wrong_report`, `summary_first_try`, `tool_squeeze` / `tool_touch` / `tool_lift`, fragments `e_*` (is hard) and `a_*` (hard) with `_f` variants; word `to squeeze` (apretar); the ten object words got Spanish `forms` (noun, gender) | `data/phrases.json`, `data/words.json` through the Lexicon |
| Offer chance and target (4 each) | `data/activities.json` `lineup_rocco`, `evidence_mimi` |

Adding a suspect feature: an attribute with values and looks in `detective_game.json`, its
clues with `police.s_*` phrases in every language, drawing in `suspect_builder.gd`; then run
`docs/evidence/police-detective-20261106/verify_clues.gd`. Evidence (8 Nov 2026): a new object kind
needs real, fixed values for every property pair in `detective_game.json`, a model in
`evidence_props.gd` (`model()`, product art style), Spanish `forms` (noun, gender) on its word,
and, to show it on the shelves, a new bake step (the shelf has ten exhibits); a new property pair needs a
`dims` entry and tool, two clues with `e_*` / `a_*` phrases (and `_f` variants) in every
language, a tool in the session's `TOOLS` with its icon, the tool's animation in `_examine()`
and two badges. Then run `verify_clues.gd`.

### Grammar Classroom ownership — 7 November 2026

Guide: [GRAMMAR_CLASS.md](GRAMMAR_CLASS.md). The room is the school unit: `scripts/buildings/school.gd`
step `grammar_classroom` (baked into `scenes/town/school.scn`) moves the desks, chairs, music
corner and two posters, builds the board (`Whiteboard`, meta `grammar_board`) and Lana
(`Buildings/School/TeacherLana`), and marks the four answer desks and chairs (metas
`grammar_desk` / `grammar_seat`, letters A–D); its constants (desk grid, board, start, doorway)
are the game's coordinates. `scripts/learning/grammar_session.gd` (made in `Main.make_shops()`,
node `GrammarSession`) owns the game and builds only runtime, unsaved things: board and desk
`Label3D`s, the green `material_override` on a desk top (a new material; shared palette
materials are never edited), the doorway `Area3D` and the fade. It reads the seat through the
seating controller (`main.seating.current`) and never seats or moves the player between
questions. `scripts/learning/grammar_questions.gd` loads and validates
`data/grammar_class/<code>.json` (one file per taught language; `tools/language_check.gd`
runs the same rules); `scripts/ui/grammar_card.gd` is the card (under the dialogue box in
`hud.ui_root`, on the popup stack, re-rendered by `_on_settings_changed()`). Text lives in
`phrases.json` group `grammar`; the activity is `grammar_lana` in `activities.json`.

### Warehouse ownership — 5 November 2026

Update 6 Nov 2026: the town warehouse is saved in `scenes/town/warehouse.scn`; `warehouse.gd` keeps only the shell, hall equipment, shared constants and `build_copy()` (the minigame copy). `build()`, `exterior()`, `furnish_reception()`, `posters()`, `hall_stock()` and the goods helpers below were deleted (git history, `b6bc6f8`); the paragraphs below describe how the saved building was made.

Guide: [WAREHOUSE.md](WAREHOUSE.md). `scripts/world/warehouse.gd` builds the whole warehouse
(root `Apartment/Warehouse`, town-local (−35, 0, 220.8), entrance on local z = 0) right after
`compact_town()`, so it needs no compact-layout entry; it adds its own lot, drive, entrance
walk, map entry (`site_bounds["Warehouse"]`) and registers its two doors in `game.doors`.
`architecture(parent)` is the shell shared with the planned minigame copy; `exterior()` and
`furnish_reception()` are the town building only. The school's position is data: the
`compact_layout.sites.School` target in `data/reference_layout.json` (moved to x 10 on
5 Nov 2026); the school crossing in `blueprint_loop()` and the school pair in
`FOUNDATION_PLANTING` are town-space and moved with it. `dev_focus.txt` name: `warehouse`
(reception furnishing only; the shell always loads).
Phase 2 (5 Nov 2026): `tag_shell()` gives the solid walls and roofs `exterior_word`
"warehouse" inside `architecture()`; `exterior()` also builds the pallet boxes, the
`trolley` platform cart and Ramón (`boss()`, via `house_characters.gd` `worker()`, outfit
`warehouse_worker`); `furnish_reception()` adds the desk package and `posters()`, which
reuses `school_posters.gd` (frame/header repainted charcoal) for the verbs, positions and
colours/sizes posters. Word lists are the `VERBS` / `PLACES` constants there; all text
comes from the Lexicon. `docs/evidence/town-checks/check_vocabulary_translations.py` treats the Actions and
Colors & Descriptions categories and the position phrases as article-free.
Phase 3 (5 Nov 2026): `hall_equipment(parent)` builds the fixed hall equipment (shared with
the planned copy; layout constants `RACKS`, `RACK_LEVELS`, `ZONE_IN/OUT`, `LANES`) and
`hall_stock()` the town's static goods, both under `Warehouse/Hall` and skipped like the
reception when `dev_focus.txt` excludes `warehouse`. Goods helpers (`cardboard_box()`,
`package()`, `container()`, `fruit_crate()`, `platform_cart()`) take the resting base point,
for reuse by the Phase 5 movable goods.
Phase 4 (5 Nov 2026): `scripts/learning/warehouse_session.gd` (made in `Main.make_shops()`)
owns the game: offer, fade, `Warehouse.build_copy(main, town)` (`WarehouseCopy`, lifted
`COPY_LIFT`; `copy = true` skips door registration), station, task card
(`scripts/ui/warehouse_task_card.gd`, under the dialogue box in `hud.ui_root`, on the popup
stack so Esc asks to leave), the shared quit card for the leave question, fall recovery,
`end_activity()` on a language change, and freeing the copy. While in the copy the player
carries a `map_position` meta that `town_minimap.gd` (`tracked_position()`) and
`Main.current_room()` read instead of the real position.
Phase 5 (5 Nov 2026): `scripts/learning/warehouse_goods.gd` (a child of the session per
game) builds the goods, containers, trolleys, cabinet hinges, readouts and the green marker
into the copy's `Session` node, with physics bodies in a top-level `Bodies` node (world
space, because rigid bodies cannot sit under the town's 1.3 scale); its queries use
hall-local coordinates (`to_hall()` / `to_world()`). `scripts/learning/warehouse_tasks.gd`
writes and checks tasks (no language: phrase ids only). Goods, trolleys, the cabinet and
the copy's exits are [interactables](#interaction-system); while carrying (or holding a trolley,
walking off) the session's `warehouse` input claim takes E and the click (until 12 Nov 2026
`warehouse_session.handle_use()` before Main's E chain). `warehouse.gd` `supply_cabinet()` names its doors and handles
`west` / `east` so the copy can hinge them.
Play-test refinements (5 Nov 2026): directions come from wall bays — `warehouse_goods.gd`
`bay_of()`, `side_axis(ref, side)` (the frame of a reference standing in a bay, facing the
wall) and `reach()` (centre-to-centre touch distance), used by both `beside()` and the task
writer's `region()`. The writer's `question(task)` returns the ask phrase, answer, choices and
labels for every question kind (weigh, measure, where, color, what, compare) and
`question_hint()` its green-marker help; the session only shows them. Walking pushes goods
by setting a velocity in `_nudge()`, not by impulses.
`interaction_controller.gd` no longer passes a freed hovered object to `highlight_object()`
(freeing the copy under the cursor raised script errors every frame; the hover glow was removed
on 12 Nov 2026).

### Shared dialogue, popups and settings — 4 November 2026

**Approved by the user (4 Nov 2026)**, staged: 1 shared UI (popup stack and Esc, standard
dialogue box, icons, money panel tidy-up, Settings window); 2 progress bar and shared random
events; 3 every remaining UI string into `phrases.json`, live re-rendering of open dialogues,
per-language progress; 4 Traditional Chinese (needs its own kinship design first; decisions in the [family game record](TOWN_DESIGN_BRIEF.md#hospital-family-game--4-november-2026)).
- **Translate button:** a speech bubble with the native language's code (EN, ES, 中),
  outlined when off, filled when on; the same button and place (top right, left of ✕) in
  every dialogue and minigame.
- **Display Mode** *(superseded 7 Nov 2026, see below)* (Settings, and the **L** key as a shortcut cycling Foreign only → Both →
  Native only): *Foreign only* (default) shows the foreign text and the translate button
  reveals the native line; *Both* shows both lines and no button; *Native only* shows only
  the native text. Signs and posters show the foreign language except in Native only.
- **Display Mode, 7 Nov 2026 (user decision, reverses the three modes above):** *Both* is
  removed, and so are the **L** key and the bottom-left HUD mode button; the translate bubble
  is the quick way to peek. Two modes remain: Foreign (default) and **Native mode**, a
  Settings checkbox "Show everything in my language" (`settings.native_mode`), off by
  default. While Native mode is on no practice is recorded (practice tracking: planned, see
  the vocabulary tracking stages). A saved `display` of 2 (old Both) loads as Foreign.
- **Language dropdowns** (native, foreign) are in Settings from Stage 1 with English and
  Spanish; choosing the same language for both is allowed (the user tests with it).
- **Esc:** closes the topmost open popup or minigame (its ✕ behaviour); with nothing open it
  opens Settings; in Settings it closes Settings.
- **Talk camera and dialogue look, 8 Nov 2026 (user request; renders and before/after in
  `docs/evidence/talk-camera-20261108/`, rerun with its `capture.gd`):**
  - **Camera** (`npc_presence.gd`, shared by every minigame NPC): 3.6 units out, 18° above
    the face looking down, face a third of the way down the screen, so the box never covers it
    (it used to sit level with the face, centred, and the box hid all but the top of the head).
  - **Walls and furniture:** if a ray from the face to the camera hits something, the camera
    tries 30°, 60° and 90° round the NPC on either side; if every side is blocked it moves in
    front of the nearest blocker (not closer than 1.6).
  - **The player:** the camera stays on the player's side of the NPC, so the player's model
    is hidden while it would stand in the shot and shown again on zoom-out.
  - **Box** (`shop_order_panel.gd`): narrower and lower (`DIALOGUE_RECT`), with a soft shadow
    and the speaker's name on a tag. Choice buttons are larger (200 × 58 at 800 px), rounded,
    with icon and words centred together; the first choice is teal, the others dark blue; ✕
    is flat until hovered.
  - **Quit card:** the question is centred. Leave has a door icon and a coral edge; Stay has
    a play icon (`play` in `ui_icons.gd`) and is teal. Both used to be arrows.

**Stage 1 as built (4 Nov 2026)** — ownership:
- `scripts/core/game_settings.gd` (`GameSettings.shared()`): Display Mode (`NATIVE` 0,
  `FOREIGN` 1, the same numbers as the HUD's `mode`; `BOTH` 2 removed 7 Nov 2026;
  `set_native(on)` / `is_native()` for the checkbox), native and foreign codes;
  saved in `user://settings.json` (learner data: tests use an isolated HOME). Main calls
  `apply()` first in `_ready`, so the Lexicon has the saved languages before any text is
  built. `view(line, revealed)`, `inline()` and `stacked()` are the one rule for what a
  `{"foreign", "native"}` line shows; every panel renders through them. `changed` fires on
  every change; Main's `_on_settings_changed` re-renders the HUD, the dialogue box, the
  money and family panels, the word card and the world labels (`apply_world_language()`).
  Text built earlier from the old languages (a family tree in progress, names) keeps them
  until it is built again; *(superseded by Stage 3: a language change now ends a running
  minigame and every interface text re-renders.)*
- `scripts/ui/popup_stack.gd` (Main's `popups`): every popup is registered once in
  `Main.make_popups()` (minigame panels: `minigame_wiring.gd` `PANELS`) with what its ✕ does; Esc in `Main._unhandled_input` runs the
  topmost one, or opens Settings when none is open. **No other script handles Esc**; the
  money and family panels swallow every key except Esc. Registered: word card, saved
  words, map, journal, help, the dialogue box, the shopping cart (asks to quit), the quit
  question, money panel, family panel, Settings. A new popup must be added there.
- `scripts/ui/translate_button.gd`: the bubble (badge from `languages.json` `badge`),
  hidden unless the mode is Foreign only. `scripts/ui/ui_icons.gd`: line-art SVG icons
  rasterised at runtime (check, no, close, money, hand, trash, next, exit, retry, question,
  back, gear).
- `scripts/ui/shop_order_panel.gd`, the dialogue box of every NPC: speaker, bubble and ✕ in
  the top row; choices centred, each `{"id", "label", "icon"}` (the sessions' `CHOICE_ICONS`),
  translated choices on a second line. The dialogue and cart cards are placed by hand (no
  anchors): anchors plus hand-set sizes stretched the box to ~1200 px at start-up.
- Money panel: no hint text (a faint hand fills the empty tray); Clear all (trash) and Close
  (✕) the same size, Hand over (hand) larger and in the accent colour, faded when disabled;
  every label including Total follows the Display Mode. Family panel: bubble, icons on
  Yes / No / Another question / Exit.
- `scripts/ui/settings_panel.gd`: the Native mode checkbox (was three Display Mode buttons
  until 7 Nov 2026; its box icons `box` / `box_checked` are redrawn at the scaled size), native and foreign dropdowns (every
  `languages.json` language; the same language for both is allowed), Close. Labels in the
  native language from `phrases.json` `settings.*` and `language.*` (a language's name in
  each language; every language code needs one). The HUD gear (left of the journal's book button)
  and Esc open it. *(The bottom-left HUD mode button and L were removed 7 Nov 2026.)*
- Checks: `docs/evidence/ui-settings-20261104/verify_town.gd` (Esc order, Settings, display modes,
  the bubble, money panel buttons); renders in the same folder.
  *(7 Nov 2026: that check and its `capture.gd` still use the removed `BOTH`, L and mode
  buttons and no longer compile; the current display checks and renders are
  `docs/evidence/display-mode-20261107/capture.gd` (graphics, isolated HOME; prints `DISPLAY MODE:
  N checks, M failures`), and the shared interaction check flips Native mode through
  `GameSettings.set_native`.)*

**Stage 2 as built (4 Nov 2026): activity board and progress bar.** User decisions: every
offer chance 100 % for testing; cashier **5** rounds per session, family **20**, the grocery
order is one round with no bar; only a round answered right the **first time** counts; at
the target the NPC says "Well done. Thank you for your help." and the session ends; while
one activity runs, other NPCs politely refuse (`common.finish_first`) and hide their "!".
- `data/activities.json`: per activity id (`shop_<store>`, `cashier_<store>`,
  `family_dr_li`) the offer `chance` and the `progress` target (0: no bar). The clerk's old
  `needs_help_chance` moved here from `shops.json`.
- `scripts/learning/activity_board.gd` (`Board.shared()`): `register(id, session)` (the
  session's `activity_running()`; held as a weak reference, because the static board
  outlives the town and holding callables bound to the sessions crashed Godot on quit),
  `roll(id, rng)` (on arrival: entering the store, or coming within Dr. Li's calling
  distance, and once at start-up), `blocker(id)` (another running activity, or ""),
  `begin(id)` / `add_success(id)` / `done(id)` / `target(id)`. Overlap is derived from each
  session's state, so no exit path has to remember to release a lock.
- `scripts/ui/progress_bar.gd`: bar + "7/20", in the money and family panels' top row left
  of the translate bubble (`set_progress(done, target)`); hidden when the target is 0.
- A new minigame: add a data entry, `register` in setup, `roll` on arrival, refuse when
  `blocker()` is set, `begin` per session and `add_success` per first-try round, and put a
  `progress_bar.gd` in its panel. The dialogue box draws above the grocery cart, so an NPC's
  refusal is visible while shopping.
- Checks: `docs/evidence/activities-20261104/verify_town.gd`; renders in the same folder.

**Stage 3 as built (4 Nov 2026): interface text in data, live re-rendering, progress per
language.** User decisions: *all* player-facing text moves into `data/phrases.json` and shows
in the **native** language; the word card works like the dialogue; progress is kept per
foreign language (the old save becomes the Spanish progress, the old file stays as a
backup) while saved words stay one shared list; changing a language in Settings ends a
running minigame with its NPC's goodbye, and everything else re-renders.
- `scripts/language/ui_text.gd` (`UiText`), the one way game code shows interface text:
  `t(id, values)` (a phrase in the native language), `place(english)` (a place name built
  as "Hospital · Floor 2 · Patient Rooms, ICU & Surgery", translated part by part; "Floor N"
  through `places.floor_n`), `named(group, english)` (an English name looked up by its slug,
  accents folded: "Bakery / Café" → `places.bakery_cafe`), `word(key, lang)` (a words.json
  word), `maybe(text)` (a metadata value that may be a phrase id). A name without a phrase
  shows in English and is recorded in `UiText.missing`, which the Stage 3 check reads.
- World code keeps **English names as lookup keys** (room names in `Main.current_room()`,
  site and map titles, zone names, word categories, species, seat labels, outfit ids) and
  translates them only where they are shown. Seat `sit_message` metadata holds a phrase id.
  (`seated_hint` and `action_hint` hints, and `common.talk_prompt`, were removed with the
  [interaction system](#interaction-system) on 12 Nov 2026; a few baked `seated_hint` metas remain
  unused in the base, playground and clothing units.)
- New phrase groups: `hud`, `card`, `bookmarks`, `journal`, `help`, `hint`, `seats`,
  `seat_names`, `outfits`, `toast`, `vehicle`, `elevator`, `map`, `places`, `categories`,
  `species`. A new name the world shows needs an entry in its group in every language.
- HUD (`vocabulary_hud.gd`): `phrase_label(node, id)` remembers labels showing one phrase;
  `refresh_language()` (on every `GameSettings.changed`) re-sets them, rebuilds the F1 guide
  (its toggle pills keep their state in `help_states`) and re-renders the room line,
  movement label, open journal, saved words and card. The minimap, flight status and hints
  are built each time they are drawn.
- HUD layout (user, 10 Nov 2026): top left the minimap (`town_minimap.gd` `side_for()`: 268 px
  at 1100 × 800, scaled, never under 208; a click or tap opens the full map), with the place
  and words-found line under it; top centre the clock; top right the peek badge and the gear
  (`TOP_SCALE` 1.5: 90 px at 1100 × 800; since 21 Nov 2026, user, these two are `TOP_BIG` 1.1 ×
  that, `top_corner_size()`, and sit `top_right_inset()` (12 + max(20, 30 × scale) px) in from the
  right edge so a phone's rounded corner does not clip them; the second row lines up under them); bottom right a 2 × 2 cluster of equal buttons from
  `bottom_slot(i)` (`CLUSTER_SCALE` 2.0: 120 px; user, 10 Nov 2026, after trying 2.8): the journal and the full map
  on the bottom row, the ▶ [minigame picker](MINIGAMES.md#minigame-picker) and ? (the F1 help)
  above them. Since 14 Nov 2026 (user) the journal and ▶ are a second top-right row under the
  gear and peek badge (`top_slot(i)`), the ? button is hidden (F1 still opens the guide, which
  has its own ✕), and the bottom right holds the touch jump button (`jump_slot()`, 1.25 × a
  cluster button) with E above it; the map slot stays empty while the map is hidden. The old controls text at
  the top left is hidden (its node "Controls" stays and re-renders; the same keys are in F1),
  and the movement line shows only while sprinting or in hyper speed. A cluster button the NPC
  dialogue box overlaps hides while the box shows (`cluster_cover`, `cluster_hidden()`).
- Moving closes menus (user, 10 Nov 2026): W, A, S, D or Space (`Main.MOVE_KEYS`) closes the
  minigame picker, F1 help, the full map, the journal and Settings (`Main.close_menus()`); a
  running minigame's own panels stay. A focused text field (the journal's search) keeps its keys.
- Word card: native and foreign words come from `words.json` (`UiText.word`), not the
  capitalized key; `GameSettings.view()` decides what shows, and a translate bubble at the
  card's top left reveals the native word in Foreign only. The pointed-at word (hover)
  follows the Display Mode too. The journal and saved words list foreign then native.
- Progress (`vocabulary_progress.gd`): `user://vocabulary_progress_by_language.json`
  `{"es": [...], "en": [...]}`. With no Spanish entry yet, the older single array
  (`user://vocabulary_apartment_progress.json`, or the v0.20 location) is copied in as
  `es`; the old file is never written again. Main keeps `progress_language` and reloads
  `studied_words` when the foreign language changes.
- Language change: Main compares `native/foreign` in `_on_settings_changed`; on a change it
  calls `end_activity()` on every session that has one (shop: as leaving the store; cashier:
  ends the round with his goodbye; family: closes the game with Dr. Li's goodbye and renames
  her in the new foreign language). A Display Mode change alone ends nothing.
- Still English or Spanish-only by design or for a later stage: world signs and lettering
  (sign stage), the elevator's in-world floor plates, house characters' proper names, key
  names on key caps (Shift, Ctrl, Esc). `tools/language_check.gd` lists the remaining code
  exceptions.
- Checks: `docs/evidence/language-ui-20261104/verify_town.gd`; renders in the same folder.


