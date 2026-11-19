# Animal system

Authoritative project location: `/Users/james/Documents/Codex/Bon Adventure/BonAdventure/docs/guides/ANIMAL_SYSTEM.md`.

Current implementation and measurements: 31 October 2026. This guide supersedes
animal scale/movement descriptions in the historical Part 2 handoff.

## Animal scale reference

Playable BonBon's visible mesh height is **2.239191 world units** (not the 2.2-unit
movement capsule or rounded 2.24 metadata). The original runtime snake's visible
height is **1.014000 world units**: its repaired mesh, saved scene overrides,
local uniform scale **0.602782**, and Apartment's **1.3** scale are included.
Its model-space height is approximately 1.294. The resulting town-local height
is 0.78. This measured world height is now the fixed absolute animal minimum,
`MIN_ANIMAL_WORLD_HEIGHT = 1.014`; changing the snake later must not silently move
that reference. Units describe the game, not a real-world zoological calibration.

Measurements merge the AABBs of visible MeshInstance3D children transformed into
the animal root's coordinates, then apply the root's world scale. Hidden broken
snake CSG/scale disks are excluded; the generated continuous body is included.
The same method measures `Player/Visual/BonBon`, including the sculpted mesh.
The table is the rest pose, before wandering/bobbing, rounded to six decimals.
The before column is the previous **runtime** display, not the raw prefab.

Scaling is uniform: multiply the complete animal word root, preserve its foot or
perch elevation, then reset `home`. Existing species targets remain except lion (1.5 → 1.95 town units, +30%),
tiger (1.6 → 2.1) and bear (1.85 → 2.2), resized 31 Oct 2026 so the big cats and bear
stay ordered against BonBon (table rows below are computed, not re-measured), elephant (2.8 → 3.15), giraffe (3.846154 → 4.4), and the
minimum-height corrections. Mesh designs, materials and relative body proportions
are preserved. Small animals share the required minimum when necessary; large
species remain visibly distinct. Mascot/house characters and statues are not zoo
animal instances and are not rescaled. BonBon stays unchanged.

## Animal size table

All heights/dimensions below are **world units**. Root scales are uniform local
X/Y/Z values; multiply by 1.3 for world scale. W × H × D uses animal-local axes,
so changing heading does not change the recorded body dimensions. There are
**21 species / 30 live animal instances**: 20 ParkZoo animals and 10 coast crabs.

> **11 Nov 2026 (user request):** the zoo is now mostly clay animals: **28 ParkZoo animals,
> 28 species** (19 old species, 9 new). The giraffe, bear, elephant, cow, pig, duck and dog are
> the clay models, and the lion was replaced earlier the same day. The new species are panda,
> red panda, gorilla, deer, kangaroo, rhinoceros, zebra, bear cub and flamingo. See
> [clay animals join the zoo](#clay-animals-join-the-zoo-11-nov-2026). The table below records
> the old models. **All zoo animals were then shown 25% bigger:** see
> [all animals bigger](#all-animals-bigger-11-nov-2026).

> **8 Nov 2026 (user request):** the bird and the word *bird* were removed from the game
> (zoo animal `ParkZoo/Bird`, `scenes/animals/bird.tscn`, its `words.json` entry, its
> `park_animals.gd` profile and display height; base step `remove_bird`). Now **20 species / 29
> instances** (19 ParkZoo animals). The Bird rows below are kept as dated measurements.

| Species | Original height | Final height | Original → final root scale | Height / BonBon | Final W × H × D |
| --- | ---: | ---: | --- | ---: | --- |
| Lion | 1.950000 | 2.535000 | 0.606455 → 0.788392 | 1.132× | 1.985 × 2.535 × 3.667 |
| Tiger | 2.080000 | 2.730000 | 0.716525 → 0.940438 | 1.219× | 2.007 × 2.730 × 4.618 |
| Elephant | 3.640000 | 4.095000 | 1.157605 → 1.302306 | 1.829× | 4.949 × 4.095 × 6.638 |
| Bear | 2.405000 | 2.860000 | 0.837892 → 0.996403 | 1.277× | 2.207 × 2.860 × 4.461 |
| Monkey | 1.105000 | 1.105000 | 0.465753 → 0.465753 | 0.493× | 0.502 × 1.105 × 1.376 |
| Snake | 1.014000 | 1.014000 | 0.602782 → 0.602782 | 0.453× | 1.220 × 1.014 × 2.009 |
| Giraffe | 5.000000 | 5.719999 | 1.018579 → 1.165254 | 2.554× | 2.738 × 5.720 × 4.281 |
| Cow | 2.015000 | 2.015000 | 0.849315 → 0.849315 | 0.900× | 0.991 × 2.015 × 2.510 |
| Pig | 1.235000 | 1.235000 | 0.419846 → 0.419846 | 0.552× | 0.971 × 1.235 × 1.829 |
| Horse | 2.469999 | 2.469999 | 0.713213 → 0.713213 | 1.103× | 1.027 × 2.470 × 3.441 |
| Hen | 0.650000 | 1.014000 | 0.282486 → 0.440678 | 0.453× | 0.564 × 1.014 × 0.930 |
| Duck | 0.585000 | 1.014000 | 0.283019 → 0.490566 | 0.453× | 0.628 × 1.014 × 1.035 |
| Sheep | 1.365000 | 1.365000 | 0.478360 → 0.478360 | 0.610× | 1.288 × 1.365 × 2.501 |
| Dog | 1.040000 | 1.040000 | 0.406005 → 0.406005 | 0.464× | 0.802 × 1.040 × 1.808 |
| Cat | 0.715000 | 1.014000 | 0.301370 → 0.427397 | 0.453× | 0.460 × 1.014 × 1.263 |
| Rabbit | 0.650000 | 1.014000 | 0.239234 → 0.373206 | 0.453× | 0.402 × 1.014 × 1.103 |
| Field Mouse | 0.286000 | 1.014000 | 0.120548 → 0.427397 | 0.453× | 0.460 × 1.014 × 1.263 |
| Bird | 0.364000 | 1.014001 | 0.176101 → 0.490567 | 0.453× | 0.628 × 1.014 × 1.035 |
| Turtle | 0.797372 | 1.014000 | 0.202142 → 0.257060 | 0.453× | 0.915 × 1.014 × 1.075 |
| Fish | 0.304626 | 1.014000 | 0.234328 → 0.780000 | 0.453× | 0.840 × 1.014 × 2.164 |
| Crab | 0.406930 | 1.014000 | 1.000000 → 2.491827 | 0.453× | 2.239 × 1.014 × 1.771 |

Full original dimensions/scales are in `docs/evidence/animals-review/before.json`; final per-instance
measurements and movement results are in `docs/evidence/animals-review/measurements.json`.
The crab row covers all eight mainland and two island instances.

## Movement system

`park_animals.gd` is shared by all 20 zoo, farm, meadow and aquatic animal prefabs.
`configure()` runs once the town is loaded: since 6 Nov 2026 each animal saved in `ParkZoo`
calls it itself (`_setup_in_zoo()`, deferred from `_ready()`), because the startup pass that
used to call it (`world_refinements.gd::configure_animal_movement()`) is deleted and a saved
scene keeps no script state. Each animal has its
own deterministic random generator seeded from its scene path, avoiding synchronized
circles. It chooses nearby random destinations, walks with smooth heading changes,
stops briefly, or takes a longer rest. Rest means standing still; this change does
not add skeletal leg animation or new lying-down poses (since 16 Nov 2026 the 17 clay zoo animals
walk with moving legs: [clay animal animation](#clay-animal-animation-16-nov-2026)). Fish remain at their
water elevation and birds at their authored perch/flight elevation.

Species profiles use **parent-local units per second** (world speed = value × 1.3).

| Species | Speed | Home radius | Typical pause (seconds) | Long-rest chance |
| --- | ---: | ---: | ---: | ---: |
| Lion | 0.65 | 3.2 | 3 | 35% |
| Tiger | 0.8 | 3.2 | 2 | 25% |
| Elephant | 0.45 | 3.5 | 3 | 30% |
| Giraffe | 0.55 | 3.2 | 3 | 30% |
| Bear | 0.5 | 3 | 3 | 40% |
| Monkey | 0.9 | 3 | 1 | 15% |
| Snake | 0.18 | 2 | 4 | 40% |
| Cow | 0.4 | 3 | 4 | 40% |
| Pig | 0.55 | 3 | 2 | 30% |
| Horse | 0.85 | 3 | 2.5 | 25% |
| Sheep | 0.45 | 3 | 3 | 30% |
| Hen | 0.55 | 2.5 | 1 | 15% |
| Duck | 0.4 | 2.5 | 2 | 20% |
| Dog | 0.8 | 1.1 | 1.5 | 20% |
| Cat | 0.6 | 1.1 | 3 | 40% |
| Rabbit | 0.7 | 1.1 | 1.5 | 25% |
| Field Mouse | 0.75 | 1.1 | 1 | 20% |
| Turtle | 0.12 | 1.1 | 4 | 40% |
| Fish | 0.4 | 1.8 | 0.6 | 5% |

A normal pause varies from 0.5–1.5 times the listed duration; a long rest triples
it. Walking bouts last 3–8 seconds or end on reaching the destination. Zoo/farm
home radii are 2–3.5 town units; meadow/pond animals retain their smaller existing
1.1/1.8-unit habitat ranges. Animals do not migrate between exhibits.

### Boundaries, obstacles and recovery

* The final transformed zoo/farm lawn rectangles define the outer habitat. They
  are inset by a rotation-invariant full-body footprint (including head/tail) plus
  clearance, so animals remain behind fences even when gates open.
* A home-radius check applies on every step. A destination must satisfy both
  this circle and the inset habitat rectangle. Flat aquatics/meadow ranges retain
  their original home centres; slope followers (below) follow the hill heights.
* Cached cylinder overlap and swept-motion queries probe 0.2 seconds ahead at
  10 Hz. Probes test solid layer 1 bodies, not vocabulary picking areas. The low
  cylinder spans 0.25–0.55 town units above the feet, clearing flat lawn surfaces
  while detecting fences, rocks and furniture. This is a ground obstacle probe,
  not full-height navigation for arbitrary tunnels/overhangs.
* Slope following (6 Nov 2026, replaces the `park_terrain.gd` lambda): an animal follows
  the ground when its home, or a point ±1.3 × its profile radius east/west of it, lies on
  raised park ground (the deleted pass's rule). Heights come from the saved
  `PublicGarden/Rolling park ground` mesh: a 1-unit grid built once per town (about 12,000
  vertices, a few ms) and read bilinearly, the same reading as `docs/evidence/town-checks/park_ground.gd`. The
  animal keeps its saved clearance above the ground at home, so feet stay on the lawn and
  the bird keeps its perch height above it. Lookups are a few dictionary reads per frame,
  with no physics query. Current followers: Dog, Cat, Rabbit, Field Mouse (Bird removed 8 Nov 2026); the zoo,
  farm and water animals stand on level pads or water and do not follow.
* Slope-following animals exclude only their known rolling-ground collision RID;
  other obstacles still block them. Nearby animals use footprint separation checks.
* On obstruction, stop for 0.4 seconds and choose a new direction. At most eight
  candidate destinations are attempted per decision; a completely blocked animal
  waits 0.5 seconds before retrying. No teleport/reset is used to escape obstacles.
* Long frames are clamped to 0.05 seconds, avoiding large movement jumps. Translation
  and turning update every frame; expensive decisions are throttled. No navigation
  mesh bake, per-frame scene traversal, or per-animal mesh duplication is added.

Crabs retain their existing coastal sideways scuttle/bob, with the travel axis
normalized so enlarged body scale does not enlarge their shoreline travel radius.
Their 0.7-unit coastal range is unchanged; they do not use the zoo wander controller.

### Collision and interaction

Each `VocabularyArea` receives an instance-owned BoxShape3D fitted to the visible
model bounds. Its centre and dimensions are in root-local coordinates; the same
uniform root scale applies to both mesh and picking shape. These are the existing
study/picking areas, not new solid barriers for BonBon. Word keys, cards, interaction
routing and farm/zoo gates are preserved. Runtime-only edits preserve prefab designs
and saved scene overrides; restart Main to apply them once.

## Scene and script structure

| File | Responsibility |
| --- | --- |
| `scenes/main.tscn`, `scripts/core/main.gd` | Startup; Apartment scale 1.3; invokes guarded refinements before rendering/batching. |
| `scenes/town/base.scn` | Active saved world since 6 Nov 2026 ([modular town](MODULAR_TOWN.md)): the zoo with its animals at their final sizes, habitats and overrides. (`town_public_garden.tscn`, the world before it, was deleted that day.) |
| `scenes/world/park_zoo.tscn` | Animal instances, lawns, fences, picking ownership, zoo/farm layout. |
| `scenes/animals/*.tscn` | Twenty reusable animal prefabs plus procedural crab prefab. |
| `scripts/world/world_refinements.gd` (deleted 6 Nov 2026) | Was the pass that applied the sizes, snake repair, tiger primitive correction, fitted picking, habitat setup and crab scaling; its result is saved in `base.scn` (git history for the code). Its wander setup (`configure_animal_movement()`) is now done by `park_animals.gd` at load. |
| `scripts/world/park_animals.gd` | Shared movement state and configurable `PROFILES`, cached obstacle queries; self-setup of the `ParkZoo` animals (lawn habitat, slope following from the saved park ground); species display sizes `ANIMAL_HEIGHTS`, `SMALL_ANIMAL_LENGTHS`, `MIN_ANIMAL_WORLD_HEIGHT` (checked by `docs/evidence/part2/verify.gd`). |
| `scripts/world/reference_world_layout.gd` | Was the initial habitat relocation (deleted 6 Nov 2026; result saved). |
| `scripts/world/park_terrain.gd` (deleted 6 Nov 2026) | Built the park ground and gave animals whose roam touches a slope a `ground` callback (a lambda), which a scene cannot save. Fixed 6 Nov 2026: `park_animals.gd` sets `ground` itself from the saved ground mesh ([verification](#verification--6-november-2026)). |
| `scripts/world/crab.gd`; coast in `scenes/town/base.scn` (`scripts/buildings/base.gd`) | Crab mesh and scuttle; the coast/island and crab placement are baked in the base scene (their builder `coast.gd` was deleted 6 Nov 2026). |
| `scenes/player/bonbon_player.tscn`, `scenes/characters/BonBon.tscn` | Playable character/model scale reference. |
| `docs/evidence/town-checks/check_animals.gd` | Minimum, all instance measurements, picking, movement, obstacle, containment, captures and timing. |

## Adding or changing animals

1. Reuse an animal prefab and shared controller; retain a stable `word_key` and
   `VocabularyArea`. Follow the vocabulary procedure for any genuinely new word.
2. Measure visible transformed geometry in the running Main scene. Include all
   ancestors and saved overrides. Use BonBon's 2.239191-unit height for proportion;
   no animal may be below 1.014 world units. Never flatten/stretch individual axes.
3. Set a species display target in `park_animals.gd` (`ANIMAL_HEIGHTS`) and scale the
   animal in the saved town (editor, or a step in an own script, [modular town](MODULAR_TOWN.md#changing-a-building));
   the minimum applies after the species target. Larger species must keep their appropriate hierarchy.
   Refit picking bounds, preserve ground contact, and update the table and evidence.
4. Add a speed/radius/pause/rest profile. Animals saved under `ParkZoo` configure
   themselves at load (habitat = the zoo/farm lawn holding them); elsewhere, call
   `configure()` explicitly. Provide an explicit habitat for new locations. Ensure the full rotating body
   and roam radius fit the habitat, with clear paths around its obstacles.
5. Terrain followers need a valid ground callback (set at load for the rolling park
   ground; another terrain needs its own height source) and only their actual supporting
   terrain excluded. New water/shore/overhang environments need their own boundary
   and clearance checks; the ground probe is not a general navigation solution.
6. Keep probes cached/throttled and candidate retries bounded. Peer separation is
   O(N²) at decision time for the current 20 walkers; use spatial buckets if
   expanding to hundreds. Do not add per-animal mesh scans or scene searches in
   frame updates. Preserve rendering exclusions for moving animal roots.
7. Run resource checks and `docs/evidence/town-checks/check_animals.gd` in an isolated test copy (project
   README), render zoo/farm views, inspect small/large silhouettes, and record exact
   results. Update this guide and the documentation map if ownership changes.

## Verification — 6 November 2026

Runtime self-setup and slope following (Godot 4.7.2, isolated `HOME`, `dev_focus.txt` = `all`,
each check once). Before it, nothing called `configure()` in the modular town, so the zoo
animals did not wander at all (code reading: its only caller was the deleted pass).

* Probe (temporary script, not kept), 600 frames at 60 Hz: all **20 walkers** configured and
  roaming (excursions 0.64–2.78 units). Followers Dog, Cat, Rabbit, Field Mouse and Bird:
  height above the ground mesh's own triangles (independent of the grid) drifted at most
  **0.0027** units while crossing 0.02–0.07 units of relief; Cat, Rabbit and Field Mouse feet
  sit on the lawn relief (0.025 below the mesh, its lift). Rendered close views of the Rabbit
  and Cat on their slopes: standing on the grass, neither buried nor floating.
* `check_park_terrain`: 0 failures, 470 elevated samples, peak 1.375, monument 1.110 (unchanged).
* `docs/evidence/part2/verify`: 1,304 checks, 3 failures, the known `drive clearance Home garage drive 21` ×3.
* `check_animals`: 30 measured, 20 walkers, movement 0.036 ms/frame; **10 failures**, all
  `Fitted picking: Crab…`, every crab (the saved picking box no longer matches their visible bounds;
  crabs do not use this controller; not traced, P3). Walk, pause, containment and obstacle
  checks pass. Its `docs/evidence/animals-review/measurements.json` output was reverted to the 31 Oct record.

## Verification — 31 October 2026

Godot 4.7.2, isolated test save identity `VocabularyTownChecks/animals`:

* `check_animals.gd`: **30 instances, 20 walkers, zero failures**. Two simulated
  minutes at 60 Hz; each walker travels >0.25 units, walks and pauses; every step
  stays in its footprint-inset habitat/home range. Checks fitted picking, actual
  physics rays, minimum height and a deliberately inserted solid obstacle.
* Average movement plus test bookkeeping: **0.0896 ms/frame** for all 20 walkers.
* Rendered zoo/farm views inspected in `docs/evidence/animals-review/zoo.png` and `farm.png`, with
  BonBon placed in each view for reference. Existing stylized designs are preserved.
* Short paired rendered farm samples: movement disabled medians **7.022 / 7.322 ms**,
  enabled **6.332 / 9.213 ms**; p95 disabled **9.174 / 9.364 ms**, enabled
  **9.590 / 9.930 ms**. Frame times vary; these samples show no consistent large
  regression and are not a hardware-independent FPS guarantee.

The simulation exercises the current authored routes and explicit obstacle case;
it does not prove navigation through arbitrary new mazes or every player-created
blockage. Full-game regression status remains in `FINAL_VERIFICATION.md`.

Additional regression results: runtime resource loading **362 checked / 0 failures**
both before and after. Part 2 runs **1304 checks / 3 failures** in both unchanged
and updated copies: the same Home garage drive samples (21, lateral offsets -1.4,
0, +1.4) hit the closed garage door. All animal checks in that suite pass.
`check_zoo_upgrade.gd` completes its 20-animal checks, then fails its historical
`InteriorDetails` assertion for remodeled buildings (line 46); that unrelated
interior check is not claimed as passing. Original property/last-child assumptions
in this older test were updated to species-configured speeds and named picking areas.

## Clay gorilla display (11 Nov 2026)

`scenes/animals/gorilla_clay.tscn` is a static study of the user's "Gorilla Character Blueprint"
turnaround, built by `tools/build_gorilla_clay.gd` from `scripts/characters/gorilla_clay.gd`
(the clay lion's field mesher and the clay giraffe's skin painting; about 105k triangles). One
instance, `ParkZoo/GorillaClayDisplay`, stands on the wild-animal lawn at town (-82.3, 0.12, 111.0),
2.1 town units tall, facing the gate (base steps `gorilla_clay_display`, `gorilla_clay_refine`, `gorilla_clay_eyelids`).
It has a box footprint and no word, movement, animation or interaction; "gorilla" is not in
`ANIMAL_HEIGHTS` or the vocabulary. The bake stores its meshes in `base.scn`, so a rebuilt prefab
reaches the zoo only through a new swap step like `gorilla_clay_refine`.
Renders: `docs/evidence/gorilla-clay-20261111/` (`capture.gd`; studio turnaround, face and eye close-ups,
zoo views including a daylight face close-up, `zoo-face.png`). The eye domes end exactly under
the lid line (user fix, 11 Nov 2026: white had shown outside the lid at the upper nose side).
No test suite was run.

## Clay golden retriever display (11 Nov 2026)

`scenes/animals/golden_retriever_clay.tscn` is a static study of the user's "Golden Retriever
Character Blueprint" turnaround, built by `tools/build_golden_retriever_clay.gd` from
`scripts/characters/golden_retriever_clay.gd` (the clay lion's field mesher, the clay giraffe's
skin painting; 0.8 town units tall, the zoo dog's display height; about 189k triangles). The user
approved it after the ninth pass below; one instance, `ParkZoo/GoldenRetrieverClayDisplay`, stands
at the front of the wild-animal lawn at town (-78.0, 0.12, 120.0), between the clay kangaroo and
the clay red panda, facing the gate (base steps `golden_retriever_clay_display`, `golden_retriever_clay_coat`; a rebuilt prefab
reaches the zoo only through a new swap step like the second). "golden retriever" is not in
`ANIMAL_HEIGHTS` or the vocabulary, and the meadow's dog is unchanged. It has a box footprint and no word, movement, animation or
interaction. Renders: `docs/evidence/golden-retriever-clay-20261111/` (`capture.gd` loads only the prefab:
studio turnaround, face and eye close-ups; `compare.gd` stacks the blueprint over the turnaround
in `comparison.png`). Later passes the same day (user reviews): the fur is broad round-ended clumps
pressed into the body's own clay, the ears are tapered flaps of deeper gold turned 30 degrees so
their faces show from the front, the tail is one continuous plume with painted cream feathers, the
torso has shoulder and haunch masses and a rising belly, the muzzle is shorter, the blaze softer
and the coat lighter and matte; `capture.gd` uses softer light with a fill from behind.
`overlay.gd` draws the model's outlines over the blueprint's side, front and back views
(`overlay-*.png`); the fourth pass used it to correct the ears, the neck ruff's width and the
chest, and the side and front outlines now follow the sheet within a few pixels. Fifth pass (user: the ears were clearly a
different shape from the front): the ears are rebuilt from the sheet's front and side outlines as
level rungs (`D_EAR_RUNGS`), narrow at the crown and flaring out like a bell toward the jaw, and
the skull is narrowed to +-50 px so they overlap the sides of the face. Sixth pass (user: the eye shape and the
ear's small dent): each eye is one painted dome traced from the sheet (`D_EYE_OUTLINE`,
`_eye_colour`; lid, iris, pupil and the white wedge at the outer corner are vertex colours), and
a small groove round the ear's back rim makes the dent (`D_EAR_DENT_Y`); `capture.gd` adds
`eye-close.png` and `ear.png`, and `detail_compare.gd` sets them beside the sheet
(`detail-comparison.png`). Seventh pass: the face is narrowed to +-41 px at the eyes so they face
further outward (the build prints the eye outline's size: 16.3 px wide from the front, 13.3 from
the side, 18.2 tall; the sheet shows 16.4, 15.5 and 18), the pupil is smaller and warmer, the
dent's crease is shorter and two soft folds are painted on each ear. Eighth pass (user: the ears read as round, circular flaps): the
ears are rebuilt as thinner flaps (`D_EAR_RUNGS`: front edge, bend, back edge per level) drawn down
to a soft point by the jaw, their back rim turned in toward the head; the build prints the built
outline beside the sheet's (`D_EAR_OUTLINE`), which it follows within 3 px in the side and front
views. `ear.png` now shows five angles. Ninth pass (user: sharper eyes, more like the original): the eye
outline has a pointed outer corner, a crisp dark line all round, a narrower iris with a dark ring
and a clear white triangle at the corner; the dome is flatter (2.6 px). Known
differences: the ruff is rounder and more even than the sheet's tufts, the flank's cream edge is
smooth, the tail seen from behind sits higher than on the sheet's back view (the sheet's side and
back views disagree), and the paws have no pads underneath.
Placement checks (11 Nov 2026, full town; `dev_focus.txt` read `all` with the user's
`spawn=airport` and was left as found): `bake_unit.gd -- base` applied 1 step; `compare_scenes.gd`
before/after shows only the display's 9 nodes and the step list (10 differences); `zoo_capture.gd`
(isolated `HOME`, `VT_FOCUS=all VT_SPAWN=none`) rendered `zoo-close.png` and `zoo-location.png` and
printed display y 0.156 world, physics ground beside it -0.046, the offset the other clay displays
use. In the town's daylight the coat reads paler and yellower than in the studio renders. The
capture scripts keep their window on top (a covered window is not drawn on macOS and the capture
stalls). Coat deepened the same day (user, after the first zoo view: it read pale and yellow in the town's
daylight): gold `dc9a54` -> `d88c4b`, head `e3a55f` -> `e09a55`, ears `cb813c` -> `c47638`, cream
`e8cba6` -> `e6c092` (a first, stronger try read saturated orange and was halved). Base step
`golden_retriever_clay_coat` swaps the saved display; the bake applied 1 step, `compare_scenes.gd`
shows only the step list changed (it does not compare mesh colours), and `zoo_capture.gd` was run
again (same ground reading). The studio renders (`comparison.png` and the others) were refreshed
and now look more orange than the sheet: the colours are tuned for the town's light, not the
studio's. The town's time of day differed between captures, so the zoo views are not lit alike.
No test suite was run.

## Clay zebra display (11 Nov 2026)

`scenes/animals/zebra_clay.tscn` is a static study of the user's "Zebra Character Blueprint"
turnaround, built by `tools/build_zebra_clay.gd` from `scripts/characters/zebra_clay.gd` (extends
the clay cow; about 313k triangles, 1.7 town units tall, a provisional height between the cow and
the horse). The stripes are painted bands that follow the skin (`_band`, `_stroke`). The user
approved it after the third pass below; one instance, `ParkZoo/ZebraClayDisplay`, stands on the
wild-animal lawn at town (-65.0, 0.12, 110.5), facing the gate (base step `zebra_clay_display`;
a rebuilt prefab reaches the zoo only through a new swap step, like the gorilla's). It has a box
footprint and no word, movement, animation or interaction; "zebra" is not in
`ANIMAL_HEIGHTS` or the vocabulary.
Renders: `docs/evidence/zebra-clay-20261111/` (`capture.gd` loads only the zebra scene: `compare.png` =
each blueprint view above the model's at the same scale, `turnaround.png`, `face.png`,
`eyes.png`; `reference.png` is the user's sheet; the capture window stays on top, because a
covered window is not drawn on macOS and the run stalls). Second pass the same day (user asked
for revisions without naming any): wider smile joined to the muzzle's corners, shaped legs
(knees, hocks, fetlock flare), pinker cream, blockier forelock, fuller tail tuft. Still open: the
mouth is rounder than the sheet's smile and the stripes follow the sheet's layout without being
traced one for one. No test suite was run.
Third pass the same day (user: stripes and mane only): stripes hold their width and end in a
rounded point, with crisp edges (`zebra_clay.gd::_paint` splits triangles by distance to the
painted edge, three times); the small chest, belly and tail-side marks were removed; the mane is
a continuous crest of flattish sections over a core, and the forelock is smaller. The finer
edges raise the model from about 130k to **313k triangles** (12 MB scene): P2, reduce before it
is used in a web build if that proves too heavy (two passes instead of three).
Zoo views (`capture.gd -- zoo`, `dev_focus.txt` = `all` via `VT_FOCUS=all VT_SPAWN=none`, once):
`zoo-close.png`, `zoo-location.png`; it stands on the grass like the other displays (display y
0.156 world, physics ground beside it -0.046, the same offset the other clay displays use). The
zoo bear's roaming range passes close beside it (P3: move one of them if they crowd).

## Clay black bear cub display (11 Nov 2026, awaiting the user's review)

`scenes/animals/black_bear_clay.tscn` is a static study of the user's "Black Bear Character
Blueprint" turnaround, built by `tools/build_black_bear_clay.gd` from
`scripts/characters/black_bear_clay.gd` (extends the clay cow: same mesher, paint and fine
meshing; about 114k triangles). It is a **cub** (user, 11 Nov 2026) beside the roaming zoo bear,
which is unchanged: 1.5 town units to the ear tops against the bear's 2.2 (`ANIMAL_HEIGHTS`);
the user is holding off on changing the cub's size. One instance,
`ParkZoo/BlackBearCubClayDisplay`, stands on the wild-animal lawn at town (-67.5, 0.12, 107.8),
3.2 town units behind the bear's home (-67.5, 111.0), facing the gate (base steps
`black_bear_clay_display`, `black_bear_clay_front_row`, `black_bear_clay_soles`,
`black_bear_cub_beside_bear`, `black_bear_cub_clear_of_zebra`: earlier places were dropped, the
last because it overlapped the clay zebra; the clay elephant stands on the bear's other side).
The file and scene names keep `black_bear_clay`. It has a box
footprint and no word, movement, animation or interaction. The bake stores its meshes in
`base.scn`, so a rebuilt prefab reaches the zoo only through a new swap step like
`black_bear_clay_soles`.
The body, head, legs and tail are one dark piece with a soft fold where the head rests on the
neck; the cream muzzle, the nose, the ears and the claws are separate pieces; the chest chevron
(`_vee`, a front-view outline pressed onto the chest) and the pink of the ears are painted; eyes
(white dome, dark iris and pupil pushed toward the nose, one catch-light), lids, brows and the
W-shaped mouth line are laid on the face. The sheet's side view is turned a little toward the
front, so ears, eyes and mouth corners follow its front view.
Renders: `docs/evidence/black-bear-clay-20261111/` (`capture.gd`, as for the rhino: `turnaround.png`,
`face.png`, `eyes.png`, `compare.png` and `pairs.png` against `reference.png`; with `-- zoo`,
`zoo-close.png`, `zoo-front.png`, `zoo-side.png`, `zoo-location.png`; the roaming bear may stand
in a view, and the zoo render can stall while its window is hidden). Known differences from the sheet: the model
is rendered orthographically; the sheet's body is a little wider at the hips and its legs
merge more softly into the body; the chevron's edge is clean, not feathered; the eyes show
narrower from the side than on the sheet (about 11 px against 17). No test suite was run; the
base was baked while another session was also baking it (lion steps), so check `applied_steps`
if a step seems missing.
Body pass and revert (11 Nov 2026): base step `black_bear_cub_body` gave the cub a reshaped body;
the user meant that for the adult bear below, so `black_bear_cub_body_reverted` put the cub's own
body back (now in `_torso_and_legs()`, which the adult replaces). `black_bears_front_row_pair`
then moved the cub to the front of the lawn at town (-69.5, 0.12, 122.0), beside the adult, so the
two can be compared; this supersedes the places named above. This folder's `turnaround.png`,
`compare.png`, `pairs.png` and `zoo-*.png` were last rendered with the reshaped body and at the
old place, so they are stale for the body and place. No test suite was run.
Baby proportions (user, 11 Nov 2026: a proportionately bigger head, more like a cub): the head,
face and ears are unchanged and the body is drawn in toward the neck (`_body_squash`, `_squash`
in `black_bear_clay.gd`: torso masses 72% as long, 95% as tall, 92% as wide; tail, legs, paws
and claws only move in, so the legs stay thick), about 97k triangles, still 1.5 town units tall.
Base step `black_bear_cub_baby` swapped the saved display. `turnaround.png`, `compare.png` and
`pairs.png` here show this build (the model no longer lines up with the sheet in `pairs.png`, by
design); the cub in the zoo is shown in the adult's `zoo-pair*.png`. Not done: the ears, eyes and
muzzle are not enlarged or rounded for a younger face.
Younger face (user, 11 Nov 2026), which supersedes that last note: `_face_youth()` (1 for the cub,
0 for the adult) makes the eyes 22% larger and sets them 4 px lower and 2 px wider, the ears 18%
larger and the muzzle 22% shorter, with the nose and mouth riding in on it; about 98k triangles.
Base step `black_bear_cub_young_face` swapped the saved display; `face.png` and `eyes.png` here
show it. Known: the enlarged eyes touch the top corners of the cream muzzle.
Lighter fur (user, 11 Nov 2026): `_fur()` gives the cub a lighter black (`625752`; the adult keeps
`B_FUR`, `4a3f3b`), with the crease shade derived from it. Base step `black_bear_cub_lighter_fur`.

## Clay adult black bear display (11 Nov 2026, awaiting the user's review)

`scenes/animals/black_bear_adult_clay.tscn`, built by `tools/build_black_bear_adult_clay.gd` from
`scripts/characters/black_bear_adult_clay.gd`, which extends the cub's script: the same head, face,
ears, chest chevron and colours, with the body replaced (`_torso_and_legs()`, `_aleg()`) and the
finished meshes and footprint enlarged to 2.1 town units at the ear tops (the cub is 1.5; about
114k triangles). Body, after the user's notes against the blueprint: a deep rib cage with a wider
belly behind it and a round rump, round shoulders and hips melted into it, a back that rises over
the shoulders and rolls down to the tail, legs that taper slightly to the ankle, and low paws cut
flat at the sole. One instance, `ParkZoo/BlackBearAdultClayDisplay`, stands at the front of the
wild-animal lawn at town (-72.5, 0.12, 122.0), 3 town units from the cub, facing the gate (base
steps `black_bear_adult_clay_display`, `black_bears_front_row_pair`). Box footprint; no word,
movement, animation or interaction; not in `ANIMAL_HEIGHTS`. A change to the cub's head or face
reaches the adult only when its prefab is rebuilt and swapped in by a new base step.
Renders: `docs/evidence/black-bear-adult-clay-20261111/` (`capture.gd`: studio views framed like the cub's;
with `-- zoo`, the town views and `zoo-pair.png`, `zoo-pair-side.png` showing both bears). Known
differences from the sheet: the belly hangs a little lower between the legs, and the head is
smaller and lower against the body than on the sheet. No test suite was run.

## Clay capybara (17 Nov 2026, approved; since the same day it walks in Wildlife Plains)

`scenes/animals/capybara_clay.tscn` is a static study of the user's "Capybara Character
Blueprint" turnaround (relaxed idle pose), built by `tools/build_capybara_clay.gd` from
`scripts/characters/capybara_clay.gd` (extends the clay cow: same mesher and paint; the clay
pig's ring patches for the eyes; meshed 2.6 times life size; about 104k triangles; 0.95 town
units to the top of the head, the zoo pig's height, the user's choice). The user approved the
design on 17 Nov 2026 after the fifth pass below (the rebuild as lofted masses), and chose a
new display on the wild-animal lawn. One instance, `ParkZoo/CapybaraClayDisplay`, stands at
town (-72.8, 0.12, 124.4): on the grass strip just inside the zoo gate, east of the gate walk
and in front of the WILDLIFE PLAINS fence (outside the fenced zones, so no wandering animal
meets its footprint), turned to face the gate (base step `capybara_clay_display`, which also
stores it as plain nodes with `unpack_clay_animals`). It has a box footprint and no word,
movement, animation or interaction; "Capybara" was not in `ANIMAL_HEIGHTS` or the vocabulary.
**Superseded the same day:** the display was replaced by a wandering, rigged capybara
([clay capybara walks](#clay-capybara-walks-in-the-zoo-17-nov-2026)).
Placement, 17 Nov 2026: the bake applied 1 step; `compare_scenes.gd` against the base before
it shows the display's 7 nodes added and the step list, nothing else (8 differences; shared
palette files 413 -> 414). Town views with `capture.gd -- zoo` (`VT_FOCUS=all VT_SPAWN=none`,
isolated HOME, `dev_focus.txt` = `all`): `zoo-location.png`, `zoo-close.png`, `zoo-front.png`,
`zoo-side.png`; printed display y 0.156 world, physics ground beside it -0.046, the offset
the other clay displays use. The first place tried, (-71.0, 124.2), put its rump in a shrub
on that strip; it was moved before this bake was kept. The check suite was not run.
It is built ready for rigging, like the clay pig (since the fifth pass the ears are part of
`Body` and there is no `Ears` node): `Body` is one fused mesh (torso, head, legs,
paws, tail nub) with the brown muzzle, the brown paws and the blush painted on; `Ears` was one
separate piece until then; `LeftEye` and `RightEye` are separate meshes, each centred on its own node (x
along the lid, y up the eye, z out of the face); lids, brows, nostrils and the mouth lines are
`Face details`. The eyes are half closed: a straight dark lid, its nose end higher, over the
lower half of a flat-set eye whose brown iris fills it to the lower edge (white only at the
corners, no catch-light, as on the sheet). They lie on the slant where the head narrows to the
muzzle, so they show from the front and the side.
Renders: `docs/evidence/capybara-clay-20261116/` (`capture.gd` loads only the capybara scene:
`compare.png` = the blueprint's five views above the model's at the same scale, `overlay.png`,
`face.png`, `eyes.png`, `turnaround.png`). Four passes were compared against the sheet before
the review. Known differences: no fur texture (smooth clay, as the other clay animals); the
views are orthographic, so the 3/4 views show the muzzle larger than the sheet's perspective;
the sheet's side view draws the nostril farther back than its front and 3/4 views, and the
model follows the front views. The check suite was not run (nothing in the town changed).
Second pass (user, 16 Nov 2026: a dent along the top of the head, head too bulky, hamster
cheeks, head and body like separate shapes, body too rectangular): shrinking the head by eye
and blending it into the body was judged "way worse" by the user and was undone.
Third pass (user, same day: trace the sheet with vtracer first): `trace.py` and `cmp.py` in
the evidence folder trace `reference.png` and the model's `turnaround.png` into colour regions
and compare the outlines per scan line (`outline-compare.txt`: model minus sheet, sheet px).
What the trace showed, and the model now follows:
- The torso is one ball, about 128 px in radius centred at sheet (1005, 430), cut by the
  ground; the first passes' loaf, belly and rump masses stood 8 to 25 px too high along the back.
- The head was about 10% too wide (9 to 19 px across at eye height) and its back 15 to 30 px
  too far back; cheeks and jaw are slimmer, and the neck keeps the sheet's shallow fold.
- The sheet's "side" view is turned about 20 degrees toward the front (ears and paws), so
  `capture.gd` now renders it that way; the eyes, ears, chest and front legs sit farther
  forward than first measured. The lids land on the traced lid regions (front view exactly,
  side view within 5 px).
- The hind foot is a long low paw (sheet x 948 to 1095) standing a little proud of the ball.
Result: median outline difference 1 to 4 px in the front and side views. Still different: the
back view's head (the sheet's is narrower and off-centre, a perspective view; up to 15 px), the
neck in the front view (5 to 9 px wider), the soles (about 3 px lower), no fur texture.
Fourth pass (user, 17 Nov 2026: "another pass"): `feat.py` traces finer colour regions (ears,
brows, lids, mouth, paws, feet) in the sheet and the model. Moved to the traced places: front
legs and chest 8 to 10 px back (paws now sheet x 809 to 918 against 809 to 924), hind feet
shorter and tucked in, the belly lifted off the ground behind the front legs, ears a little
larger and farther back, brows forward and higher, the smile and middle line 3 px higher, the
iris centred under the lid. About 105k triangles. Awaiting the user's review again.
Fifth pass, a rebuild from the ground up (user, 17 Nov 2026: the head was boxy, the muzzle
looked pasted on, the body read as an assembly of overlapping shapes): the head and the torso
are now each ONE lofted mass instead of ellipsoids run together. A loft is a row of
cross-sections along the sheet's x (top, bottom, the height where it is widest, half width,
how square its upper and lower halves are) joined by smooth curves, with rounded ends
(`capybara_clay.gd::loft`, sections in `B_HEAD` and `_torso_sections()`). It is a new shape
type for the shared mesher: `lion_clay.gd::_dist` and `_box` accept `{t: "fn", fn, lo, hi}`
(a mass with its own field); the other clay animals do not use it and are unchanged. The
head is one curve from the blunt rounded muzzle up the forehead and over the crown, a wedge
from above, narrower over the crown than at the cheeks; the torso is a ball from the side and
a pear from the front and back (widest low, tapering to the shoulders). Chest, legs and paws
are run into the torso widely; the ears are now part of `Body` (a cup run into the skull at
its base, smaller than the sheet's at the user's request), so there is no `Ears` node; the
scene is `Body`, `LeftEye`, `RightEye`, `Face details`, `Footprint`. `_ray` is the pig's
capped version (the lofts' field is not an exact distance near their ends; face details were
buried without it). `outline-compare.txt` after the rebuild: median difference 1.5 px along
the side view's nose, forehead, jaw and back, 2 to 3 px across the front view, 4 to 5 px
across the back view; the lids land on the traced lid regions within 1 px. Still different:
ears smaller and about 10 px lower than the sheet's (asked), the back view's head (the sheet's
is narrower there, a perspective view), no fur texture. About 94k triangles at 0.9 units
(104k at the placed 0.95). Approved by the user on 17 Nov 2026.

### Clay capybara walks in the zoo (17 Nov 2026)

User, 17 Nov 2026: "rig the capybara so it walks and blinks"; asked where and whether it gets a
word, the user chose Wildlife Plains and a new word.
- **Rig.** `tools/build_capybara_clay_rig.gd` (extends `clay_rig_tool.gd`) builds
  `scenes/animals/capybara_clay_rigged.scn` with meshes in `clay_meshes/capybara_rig/`: 31,437
  triangles against the display's 107,136, one skinned surface (`Body`). Bones: root, body,
  head (no neck bone; it turns about a pivot in the nape), ear_l and ear_r, two stubby front
  legs and the two long hind paws. A slow lateral waddle with the soles kept on the ground
  (`keep_feet_down`), roll 4 degrees, slow breathing. The eyes already sit on their own nodes
  and ride the head (`on_head`); a blink closes the half-open eyes under their lids. The body
  is closed with the zebra tool's `_closed` before thinning.
- **Word and species.** `data/words.json`: `capybara` (el capibara / 水豚, Animals).
  `park_animals.gd`: `PROFILES` "capybara" (slow, long rests) and `ANIMAL_HEIGHTS` "Capybara"
  0.76, which is under the small-animal minimum, so it is shown at the minimum times
  `DISPLAY_SCALE`: 0.975 zoo units, the closest the zoo's sizing allows to the 0.95 the user
  chose for the display.
- **Zoo.** Base step `capybara_clay_walks`: `ParkZoo/CapybaraClayDisplay` goes and a wandering
  `ParkZoo/Capybara` (`_clay_roamer`, then `_clay_walker`) stands in Wildlife Plains at
  (-67.8, 120.0), in the open front of the zone, facing the gate, soles at the tiger's level
  (y 0.155). `compare_scenes.gd`: 13,939 -> 13,946 nodes, 22 differences, all the display's
  nodes removed and the new animal's added, plus the step list. Two homes were tried first:
  (-65.5, 120.3) faced a shrub at the fence, and at (-65.5, 118.4) it never left `idle` in two
  town runs (inside the elephant's footprint distance, `park_animals.gd::_clear_step`).
- **Evidence** `docs/evidence/capybara-anim-20261117/`: `capture.gd` (display and rig only):
  `capybara_clay-compare.png` (rest difference 0.54 to 0.58 levels), `-walk.png`, `-seams.png`,
  `-blink.png`, `-weights.png`, `-tail.png`; `zoo.gd` (full town, `dev_focus.txt` = `all`,
  isolated `HOME`): the capybara has the word, the rig, is in group `clay_animals` and in
  `clay_life`'s list, and reaches `walking`; `zoo-context.png`, `zoo-close.png`, `zoo-walk.png`.
- **Checks** on the final bake, each run once: `run_checks.py --only
  runtime_resources,compact_layout,interaction,part2,vocabulary_report`: all PASS
  (interaction reported 0 s).
- Not checked: a web export or a phone, frame time with 20 rigs, and the full check suite.

## Clay horse (17 Nov 2026, approved, rigged, replaces the zoo horse)

`scenes/animals/horse_clay.tscn` is a static study of the user's "Horse Character Blueprint"
turnaround (relaxed idle pose), built by `tools/build_horse_clay.gd` from
`scripts/characters/horse_clay.gd`, which extends the clay capybara and reuses its lofted
masses, capped surface ray and mesh helpers (about 96k triangles; 1.9 town units to the ear
tips, the zoo horse's species height). The user approved the design on 17 Nov 2026 after the
third pass below and chose: rig it, then replace the zoo horse, at the zoo horse's size (2.4
town units = the species height times `DISPLAY_SCALE`; `ANIMAL_HEIGHTS` unchanged). Record:
[clay horse walks in the zoo](#clay-horse-walks-in-the-zoo-17-nov-2026).
The sheet was traced with vtracer first (`docs/evidence/horse-clay-20261117/`: `trace.py`,
`prof.py` for the outlines per scan line, `hcmp.py` to compare the model's render with them,
`outline-compare.txt`). Torso, neck (a loft running down the sheet, its lower end inside the
torso) and head are each one lofted mass, run together with tapered legs, shoulders and
haunches into one fused `Body`, which also carries the ears and the hooves; the cream muzzle,
the blaze, the socks, the dark hooves and the ears' pink are painted on it. `Mane` (lobes down
the crest and a forelock) and `Tail` are separate pieces; `LeftEye` and `RightEye` are separate
meshes centred on their nodes (y up the eye); lash lines, brows, nostrils and the smile are
`Face details`. Scene: `Body`, `Mane`, `Tail`, `LeftEye`, `RightEye`, `Face details`,
`Footprint`.
For this model the capybara's helpers read the sheet's frame from instance variables
(`_px`, `_ox`, `_gy`, `_fine`, `_stretch` in `capybara_clay.gd`; `loft` also takes an axis), with
the capybara's own values as defaults: a capybara rebuild after the change gave the same
triangle count and left its committed mesh files unchanged in git.
What the trace showed: the sheet's side view is turned about 20 degrees toward the viewer (the
far ear and far hind leg stand about 30 px ahead of the near ones), so `capture.gd` renders the
side view that way and the model is drawn 4% longer than the sheet's side view (`_stretch`);
the face stands steep above a full muzzle and is a wedge from above, which is what lets the
eyes show from the front. `outline-compare.txt`: median difference 2 to 3 px across the front
and back views and 4 px along the side view's rows. Second pass (user, 17 Nov 2026: "another
pass"): the mane is a low ridge with a row of flat pointed locks on the crest and on both
sides of the neck, each over the next (lofts; `loft` gained `side_z`, a mirrored pair, and a
crease flag); the smile is thicker with a flat middle and upturned corners; the coat a little
less orange. Known differences: the mane's locks are plainer than the sheet's and there are
no strands beside the neck in the front view; the forelock and tail are simpler;
(third pass, below, rebuilt the face) the far ear sits about 15 px farther back
than the sheet's in the side view; the front legs read a little wider apart in the side view
(the sheet does not turn them with the body); the coat is a little more orange; no fur texture.
The check suite was not run (nothing in the town changed).
Third pass, the face rebuilt (user, 17 Nov 2026: too long, angular and flat, above all from the
side; body, legs, mane and tail not to change): a finer trace (`ref_fine`, 6-level layers in
`hhead.py`) keeps the cream muzzle apart from the sheet's background, which the first trace
had merged, so the first head was fitted to the coat's edge only. New `H_HEAD` sections: a
short round muzzle whose top slopes up at about 45 degrees to the foot of the face, a face
standing almost upright and rounding over into the crown, a level jaw behind a chin that
hangs a little below it, full cheeks (squarer lower half). The eyes sit in shallow pressed
sockets with a soft shade round the rim, and bulge less; the blaze runs from under the forelock
between the eyes and widens into the muzzle's cream; the smile sits on the muzzle's front.
`head-compare.txt`: side view within 0 to 4 px along the face front, muzzle, chin and jaw
(the forelock's edge, part of the mane, is 7 to 14 px behind the sheet's); front view within
0 to 3 px from the brow to the chin. About 96k triangles. Approved by the user on 17 Nov 2026.

### Clay horse walks in the zoo (17 Nov 2026)

- **Rig.** `tools/build_horse_clay_rig.gd` (extends `clay_rig_tool.gd`) builds
  `scenes/animals/horse_clay_rigged.scn` with meshes in `clay_meshes/horse_rig/`: 34,355
  triangles against the display's 97,582, one skinned surface. Bones: root, body, neck (upright,
  shares the head's look, `neck_share` 0.45), head, tail and tail_2, ear_l and ear_r (the ears
  are part of `Body`), four legs. `Mane` bends over head, neck and body; `Tail` over body and
  the two tail bones; eyes and face details ride the head unskinned (`on_head`). The body is
  closed with the zebra tool's `_closed` before thinning, as for the tiger. A trot (diagonal
  pairs), swing 22 degrees.
- **Zoo.** Base step `horse_clay_walks` (the same steps as `tiger_clay_walks`): `ParkZoo/Horse`
  on the farm lawn is rebuilt with `_clay_roamer` at its old home (55.5, 91.2), facing, child
  index and word `horse`, brought to the shown height (2.375 zoo units, the old horse's) with
  its soles at the old horse's level (y 0.140), then given the rig with `_clay_walker`.
  `compare_scenes.gd`: 14,048 -> 13,939 nodes, 136 differences, all under `ParkZoo/Horse` plus
  the step list.
- **Evidence** `docs/evidence/horse-anim-20261117/`: `capture.gd` (display and rig only):
  `horse_clay-compare.png` (rest difference 0.68 to 0.93 levels), `-walk.png`, `-seams.png`
  (head turned at both extremes of the swing: no tears), `-tail.png`, `-blink.png`,
  `-weights.png`; `zoo.gd` (full town, noon, `dev_focus.txt` = `all`, isolated `HOME`): the
  horse has the word, the rig, is in group `clay_animals` and in `clay_life`'s list, and
  reaches `walking`; `zoo-context.png`, `zoo-close.png`, `zoo-walk.png` (the farm shelter
  hides it in some frames).
- **Checks**: `run_checks.py --only runtime_resources,compact_layout,interaction,part2`, each run once
  (`dev_focus.txt` = `all`, isolated `HOME`): all PASS (interaction reported 0 s).
- Not checked: a web export or a phone, frame time with 19 rigs, and the full check suite.

## Clay monkey display (17 Nov 2026, approved by the user and placed in the zoo)

`scenes/animals/monkey_clay.tscn` is a static study of the user's "Monkey Character Blueprint"
turnaround (relaxed sitting pose), built by `tools/build_monkey_clay.gd` from
`scripts/characters/monkey_clay.gd`, which extends the clay capybara (its lofted masses,
capped surface ray, skin drop and mesh helpers, with the sheet's frame in `_px`, `_ox`, `_gy`,
`_fine`, `_stretch` as for the horse); meshed 3.6 times life size, about 92k triangles; 0.85
town units to the top of the tuft, the `Monkey` height in `park_animals.gd`. One instance,
`ParkZoo/MonkeyClayDisplay`, stands at town (-83.2, 0.12, 124.4): on the grass strip just
inside the zoo gate, west of the gate walk and in front of the BAMBOO GROVE fence (the
capybara's spot mirrored across the walk; outside the zones, so no wandering animal meets its
footprint), turned to face the gate (base step `monkey_clay_display`, which also stores it as
plain nodes with `unpack_clay_animals`). It has a box footprint and no word, movement,
animation or interaction; the zoo's piece-built `Monkey` (Bamboo Grove) is unchanged.
Scene: `Body` (one fused mesh: head, tuft, ears, torso, arms, hands, legs, feet, tail; the tan
face mask, belly, hands and feet, the ears' pink and the blush painted on), `LeftEye`,
`RightEye` (each centred on its own node, y up the eye), `Face details` (upper rims, brows,
nostrils, smile), `Footprint`.
The head is ONE lofted mass (`M_HEAD`: tops and bottoms read column by column from the
sheet's side view, half widths from its front view; the muzzle sections' tops drawn to a soft
ridge so it rises into the nose bridge without a shelf across the face), closed behind by a
round skull ellipsoid that hides the loft's closing point (it shaded as a dimple on the back
of the head). The first head, eight ellipsoids run together (skull, face plate, jowls,
muzzle, chin, nose, two eye pads), matched the sheet's outlines but made a lumpy face: a snout
with a 25 px ledge beside it, a ridge round the brow and cheeks, lumps under the eyes, a notch
under the chin, and eyes tilted on the slope between two shapes (user, 17 Nov 2026: "the face
is so weird"). Lesson: outlines do not check the surface inside them; check a face with a
bare-clay render under a low light and a depth grid (`surface.png`; the depth grid is a ray
per (y, z) from the front), and build a smooth face as one loft, not separate shapes.
The eyes lie on the skin, facing 25 degrees out and 18 degrees up (the skin's own facing under
them), with one catch-light up and to the monkey's left in both eyes (one light, as on the
sheet), not mirrored.
Renders: `docs/evidence/monkey-clay-20261117/` (`capture.gd` loads only the monkey scene:
`compare.png` = the sheet's five views above the model's at the same scale, `overlay.png`,
`face.png`, `eyes.png`, `turnaround.png`; `surface.png` = the bare clay under a low light;
with `-- zoo`: `zoo-location.png`, `zoo-close.png`, `zoo-front.png`). The 3/4 and rear 3/4
camera angles were estimated from the sheet. Known differences: the tuft is rounded knobs, not
the sheet's swept curls; the belly narrows a little at the waist; the face is flatter than the
sheet's in the side view (the user asked for a flat, smooth face); a very faint line behind
the ear where the skull meets the loft shows only in the bare-clay render; no fur texture.
Placement, 17 Nov 2026: the bake applied 1 step; `compare_scenes.gd` against the committed
base shows the display's 7 nodes added and the step list, nothing else (8 differences; shared
palette files 404 -> 405). Town views with `capture.gd -- zoo` (`VT_FOCUS=all VT_SPAWN=none`,
isolated HOME, `dev_focus.txt` = `all`); printed display y 0.156 world, physics ground under
and round it -0.046, the offset the other clay displays use; the hands and feet stand on the
grass. Checks: `run_checks.py --only runtime_resources,zoo_vehicles` PASS (the full suite was
not run).

## Clay pig display (11 Nov 2026)

`scenes/animals/pig_clay.tscn` is a static study of the user's "Pig (Black & White) Character
Blueprint" turnaround, built by `tools/build_pig_clay.gd` from `scripts/characters/pig_clay.gd`
(extends the clay cow: same mesher and paint; meshed 3 times life size, so the clay grid is
1 cm; about 149k triangles, 0.95 town units to the top of the head, the `Pig` height in
`park_animals.gd`). It is separate from the mascot pig (`scenes/animals/pig.tscn`), which is
unchanged. The user approved it after the head, eye and body passes below; one instance,
`ParkZoo/PigClayDisplay`, stands at the front of the wild-animal lawn at town (-65.5, 0.12,
120.5), between the clay deer and the clay duck and in front of the clay cow, facing the gate
(base step `pig_clay_display`; a rebuilt prefab needs a swap step like `gorilla_clay_refine`).
It has a box footprint and no behaviour, word or interaction.
Placement, 11 Nov 2026: the bake applied 1 step; `compare_scenes.gd` against the base before
it shows the pig's 10 nodes added and the step list, nothing else (11 differences; scenes
stored materials 4 -> 3, shared palette files unchanged at 449). Town views with
`capture.gd -- zoo` (`VT_FOCUS=all VT_SPAWN=none`, isolated HOME): `zoo-close.png`,
`zoo-front.png`, `zoo-side.png`, `zoo-location.png`; printed display y 0.156 world, physics
ground beside it -0.046, the offset the other clay displays use; the hooves stand on the grass.
One of the zoo's wandering tigers was standing beside it in those views: the roaming animals
cross this part of the lawn. The check suite was not run for this change.
The dark head and the dark patch round the tail are painted on one cream body (the head's edge
follows the sheet's side view, `P_HEAD_EDGE`, with a U-shaped bib underneath); snout, ears,
hooves and the curled tail are separate pieces. The sheet's side view shows a white blaze up the
forehead that its front and 3/4 views do not; the model follows the front views.
Renders: `docs/evidence/pig-clay-20261111/` (`capture.gd` loads only the pig scene: `compare.png` = the
blueprint above the studio turnaround, `pairs.png` = blueprint views beside the model at the
same scale (five views, with `body-overlay.png`), `head-pairs.png` = the same for the head alone, three times larger, `head-overlay.png`, `eye-pairs.png`, `face.png`,
`eyes.png`).

Head and face pass (user, 11 Nov 2026: "the face proportion is off, the shape of the body is
off; focus on the face and head for now"), measured on `head-pairs.png`:
- Head: one round ball (a circle 202 px across in the sheet's front view). The first pass had
  low cheeks and a jaw, which made it a wide box with a flat bottom edge.
- Ears: long thick paddles of even thickness to a round tip, hanging about 50 degrees below
  level over the sides of the head (nine strands of clay run together; `_shape`). The first
  pass used flat ellipsoids, which read as round discs spread sideways and thinned to a point.
- Snout: a pink disc 14 px thick, pressed flat in front and behind, on a short dark muzzle
  that also ends flat. Before, it was a ball. The flat cuts are the poles of wide thin
  ellipsoids; `lion_clay.gd`'s ellipsoid distance overstates the depth inside those, so
  `pig_clay.gd` has its own `_ray` (capped steps, then halving). Without it the nostrils were
  placed millions of units away and the build was killed for memory.
- Eyes 24 by 29.4 px on the skin (from the sheet's front 3/4 view, which shows one face-on),
  with a faint brown sheen low in the black; brows are short thick dashes placed by rays at
  their front-view positions; the lip and the smile sit in the fold under the muzzle, where
  the snout hides the smile from straight in front, as on the sheet.
- The sheet's "side" view has the head turned toward the viewer (far ear, nostrils and the
  near eye's position show it), so `head-pairs.png` turns the model 15 degrees for that pair.

Third pass, head only (user, 11 Nov 2026), checked on `head-pairs.png` and
`head-overlay.png` (the model half-transparent over the blueprint, same three views):
- Ears: long soft paddles, four flattened lumps of clay run together along a curve, narrow at
  the head, widest past the middle, drawn out to a narrower rounded tip; the broad face turned
  18 degrees forward. The second pass's strands were about 40 px thick (running clay together
  with a blend radius swells it by about half that radius) and read short and bulky; thinner
  strands read as stiff, knuckled plates.
- Snout: 2 px wider each side (87 px), 3 px higher, a squarer rim; still a disc 14 px thick. The
  muzzle, nostrils, lip and smile moved up with it.
- Eyes: 6% larger (25.4 by 31.2 px on the skin), 2 px higher, 2.5 px farther apart each side
  (lateral 47.5), their centres about 3 px outside the snout's edges (4 on the sheet).
- Capture: the 3/4 comparison cameras looked down 6 degrees until this pass, which drew the
  snout and eyes about 9 px low in those views; they are level now.

Fourth pass, eyes only (user, 11 Nov 2026; approved), checked on `eye-pairs.png` (the
eyes cut from the head pairs; blueprint left, model right; rows: front 3/4, front, side):
- Size and shape: 27.7 by 35.4 px on the skin (9% wider, 13.5% taller than the third pass, as
  asked), an egg with the fuller half on top (`P_EYE_EGG`). Rendered from the front they
  measure about 24.5 by 33.3 px against the blueprint's 23.3 by 30.8.
- Build: the eye is no longer a separate dome. `_pig_eyes` drops every point onto the head's
  skin and lifts it 0.7 px plus a 1.5 px bulge at the middle (`_eye_at`), so it follows the
  ball of the head: not a flat sticker, not a protruding ball.
- Colour: near-black, with a soft dark-brown shade only along the bottom (vertex colours; the
  brown patches of the second pass are gone). The white accent is a fine line 88% of the way
  out, strongest low on the outer side, a hair at the top, none on the nose side. One
  reflection with a soft edge, high on the nose side as on the blueprint (so upper-left in
  the pig's left eye, upper-right in its right eye).
- Position unchanged (height 339.4, lateral 47.5). The centres are 94 px apart against the
  blueprint's 90, in step with the snout the user widened in the third pass; they were not
  moved inward because in the front view the snout's top corner already covers the lower
  inner edge of each eye a little (on the blueprint they only touch).
- Capture: runs can hang when the Godot window is not drawn; run `capture.gd` with a time limit.

The user approved the eyes ("Eyes are right", 11 Nov 2026).

Body pass (11 Nov 2026; approved with the whole model, "Approve, place it"), checked on `pairs.png` (now five views: front 3/4,
front, side, back, rear 3/4) and `body-overlay.png` (the model half-transparent over the
blueprint in those views):
- Stance: the legs stand almost square (front 899/893, hind 1099/1093 in sheet x). The first
  passes gave them a 40 px walking stagger copied from the sheet's side view, but that view is
  turned about 13 degrees toward the viewer, which is what sets its far legs forward.
- Legs: taper to the foot (radius 21.5 front, 23.5 hind) and lean in, so the feet stand 100 px
  apart under a 210 px body; a round shoulder or thigh over each carries the body's side down
  into the leg. Before, they were thin straight columns with the body high above them.
- Hooves: small dark blocks about 22 px tall, a touch wider than the feet, two toes in front
  (were wide low domes that read as plates).
- Rump: two soft cheeks with a faint crease between them; belly 4 px shallower.
- Tail: a thicker curl turned more toward the back, dark where it leaves the patch and cream
  beyond; the patch round it is lower and wider.
- Dark head edge: low down it is cut to the head's own circle as seen from the front
  (`_tinted`, "cap"), so the shoulders beside the head stay cream.
Head, ears, snout, eyes, brows, blush and colours were not touched in this pass.

## Clay rhino display (11 Nov 2026)

`scenes/animals/rhino_clay.tscn` is a static study of the user's "Rhino Character Blueprint"
turnaround, built by `tools/build_rhino_clay.gd` from `scripts/characters/rhino_clay.gd` (extends
the clay cow: same mesher, paint and fine meshing; about 185k triangles, about 1.95 town units to
the ear tips). Approved by the user the same day: one instance, `ParkZoo/RhinoClayDisplay`, stands
on the wild-animal lawn at town (-75.0, 0.12, 108.0), behind the clay giraffe and elephant, facing
the gate (base step `rhino_clay_display`). It has a box footprint and no word, movement, animation
or interaction; "rhino" is not in `ANIMAL_HEIGHTS` or the vocabulary. The bake stores its meshes
in `base.scn`, so a rebuilt prefab reaches the zoo only through a new swap step like
`giraffe_clay_colours`.
Second pass the same day (user's refinement list): torso a little longer and rounder; the skin
folds are shallow creases, not overlapping plates; four equal, thicker, straighter legs with
round three-toed feet; head 6% larger with a wider muzzle; both horns one shape in soft ivory;
smoother rump. These deliberately depart from a pixel trace of the sheet's side view.
Renders: `docs/evidence/rhino-clay-20261111/` (`capture.gd`, stage only, soft lamps that ride on the
camera so all views are lit alike: `turnaround.png`, `face.png`, `eyes.png`, `compare.png` and
`pairs.png` against `reference.png`, the user's sheet; with `-- zoo`, the town views `zoo-close.png`,
`zoo-front.png`, `zoo-side.png`, `zoo-location.png`, taken in evening light). Known differences from the sheet: the
model is rendered orthographically (the sheet has perspective), and the lower lip shows less
pink. No test suite was run.

## Zoo lion uses the clay lion (11 Nov 2026)

The user finalised the lion design: the clay lion (`scenes/animals/lion_clay.scn`, built by
`tools/build_lion_clay.gd` from `scripts/characters/lion_clay.gd`). Base step `lion_clay_roams`
(`scripts/buildings/base.gd`) rebuilt the wandering zoo lion `ParkZoo/Lion` around it: same
name, home, facing, child index, `lion` word and `park_animals.gd` wandering. Its children are
`ClayLion` (the model, turned half round because it faces -Z and wanderers face +Z; its
`Footprint` body is switched off, layer and mask 0, so the wander probe does not hit the lion
itself) and a `VocabularyArea` box fitted to the model. The lion is scaled 0.962 to the
1.95-unit species height, with its soles at the old lion's level. A rebuilt `lion_clay.scn` reaches the zoo
through the instance (no swap step needed). The other lion designs, the static clay copy and the
temporary number marks were removed the same day (base step `lion_designs_removed`; files
listed in the [design brief](TOWN_DESIGN_BRIEF.md#final-zoo-lion--11-november-2026)), as was
the original prefab `scenes/animals/lion.tscn`. `docs/evidence/part2/verify.gd` after each bake: 1299 checks,
0 failures (lion display height, wandering origin, picking area, study card, ray pick). Not
rendered by the agent; the user checked it in game.

## Clay animals join the zoo (11 Nov 2026)

User decisions (11 Nov 2026): every clay study model becomes a zoo animal that wanders and
teaches a word, like the [clay lion](#zoo-lion-uses-the-clay-lion-11-nov-2026). Where the
zoo already had that species, the clay model replaces the old one (one version per species).
The bear cub gets its own word. Base step `clay_animals_roam` (`scripts/buildings/base.gd`,
helper `_clay_roamer`, tables `CLAY_REPLACEMENTS` / `CLAY_NEW_SPECIES`) builds each one like
`lion_clay_roams`:
a `park_animals.gd` root with `word_key` metadata, the clay prefab as an instance child named
`Clay<Name>` and turned half round (the models face -Z), its `Footprint` body switched off, a
`VocabularyArea` fitted to the visible meshes, and uniform scale to `ANIMAL_HEIGHTS`. The
small-animal minimum still applies, so the clay duck is 0.78 town units tall rather than its
0.45-unit display height. A rebuilt clay prefab reaches the zoo through the instance, so it needs
no swap step. (Stale: since 13 Nov the zoo models are plain nodes; since 16 Nov a rebuild reaches
the zoo through its mesh files, see [clay file sizes](#clay-file-sizes-16-nov-2026).)

| Node `ParkZoo/…` | Clay prefab | Word (en / es / zh) | Height (town, before [the enlargement](#all-animals-bigger-11-nov-2026)) | Home |
| --- | --- | --- | ---: | --- |
| Giraffe | `giraffe_clay.tscn` | giraffe / la jirafa / 長頸鹿 | 4.4 | old giraffe's |
| Bear | `black_bear_adult_clay.tscn` | bear / el oso / 熊 | 2.2 | old bear's |
| Elephant | `elephant_clay.tscn` | elephant / el elefante / 大象 | 3.15 | old elephant's |
| Cow | `cow_clay.tscn` | cow / la vaca / 牛 | 1.55 | old cow's (farm) |
| Pig | `pig_clay.tscn` | pig / el cerdo / 豬 | 0.95 | old pig's (farm) |
| Duck | `duck_clay.tscn` | duck / el pato / 鴨 | 0.78 (minimum) | old duck's (farm) |
| Dog | `golden_retriever_clay.tscn` | dog / el perro / 狗 | 0.8 | old dog's (meadow, follows the slope) |
| Panda | `panda_clay.tscn` | **new** panda / el panda / 熊貓 | 1.67 | its display's |
| Red Panda | `red_panda_clay.tscn` | **new** red panda / el panda rojo / 小熊貓 | 0.91 | its display's |
| Gorilla | `gorilla_clay.tscn` | **new** gorilla / el gorila / 大猩猩 | 2.11 | its display's |
| Deer | `deer_clay.tscn` | **new** deer / el venado / 鹿 | 2.0 | (-60.5, 104), moved |
| Kangaroo | `kangaroo_clay.tscn` | **new** kangaroo / el canguro / 袋鼠 | 2.3 | its display's |
| Rhinoceros | `rhino_clay.tscn` | **new** rhinoceros / el rinoceronte / 犀牛 | 1.99 | its display's |
| Zebra | `zebra_clay.tscn` | **new** zebra / la cebra / 斑馬 | 1.71 | (-62.5, 109), moved |
| Bear Cub | `black_bear_clay.tscn` | **new** bear cub / el osezno / 小熊 | 1.52 | (-71.5, 113.5), beside the Bear |
| Flamingo | `flamingo_clay.tscn` | **new** flamingo / el flamenco / 火烈鳥 | 1.4 | its display's |

Each replacement keeps the old animal's node name, home, facing, child index and word. The old
model and the static clay copy were removed. The new species start from where their static
display stood, facing the gate as before. Their heights are the built sizes, rounded. Their
wander profiles in `PROFILES` use smaller home radii (1.8–2.5) because the wild-animal lawn is
shared. Wanderers keep their footprints apart, and the deer and cub displays stood on the
tiger's home, so all three were stuck. Base step `clay_animals_spacing` moved the deer to the
open east side and the cub beside the adult bear. It also moved the zebra a little away from the
bear. Word data: nine Animals words in `data/words.json` (now 30 Animals words), with
pinyin for 猩 犀 烈 鳥 in `data/pinyin_zh.json`. Mexican Spanish *venado* was chosen over
*ciervo* (user). The old prefabs (`giraffe.tscn`, `bear.tscn`, `elephant.tscn`, `cow.tscn`,
`pig.tscn`, `duck.tscn`, `dog.tscn`) stay on disk. They are no longer in the town, but the legacy
`scenes/world/park_zoo.tscn` and `docs/evidence/town-checks/check_zoo_vehicles.py` still use them.

**Verification (11 Nov 2026, `dev_focus.txt` = all, isolated HOME, each run once).**
`docs/evidence/clay-zoo-20261111/check.gd -- views` found **0 failures**. All 28 ParkZoo wanderers were
configured and moved in two simulated minutes (0.76–3.31 units), and every step stayed inside
its habitat and home range. All 17 clay animals have a clay model, a word in the vocabulary and
the right study card. Before `clay_animals_spacing`, the same check failed on the deer and the
bear cub, and the tiger did not move either. The run
also rendered `wild-overview.png`, `wild-front-left.png`, `wild-front-right.png`, `dog.png` and
`close-<giraffe|elephant|bear|cow|pig|duck>.png`. In those views every animal stands on the
grass at its species size. Other results with `tools/run_checks.py`:

- **part2**, **interaction**, **vocabulary_categories**, **vocabulary_translations** and
  **vocabulary_report**: PASS. part2 covers display height, wandering origin, pick area, study
  card and ray pick for all 26 `ANIMAL_HEIGHTS` keys. vocabulary_report rewrote
  `docs/guides/vocabulary-report/`.
- **runtime_resources** and **language**: NEW, but neither failure comes from this change.
  The committed `scripts/buildings/chapel.gd` has parse errors at lines 177, 260 and 273
  ("cannot infer the type"). Phrase `restaurant.miss_also` has an extra `{name}` in its zh line.
  This change did not touch either file (P2, untraced).

`docs/evidence/town-checks/check_animals.gd` was not run. It writes `docs/evidence/animals-review/measurements.json`, and it finds
animals by their prefab path, so it would now measure the clay model children instead of the
`ParkZoo` roots (P3: point it at the `wandering_animals` group).

## All animals bigger (11 Nov 2026)

The user asked for every animal to be bigger, the rhinoceros and gorilla relatively bigger
still, and the bear cub smaller. `park_animals.gd` now has `DISPLAY_SCALE := 1.25`, and
`display_height(key, parent_y_scale)` returns max(species height, minimum) × 1.25. Base step
`animals_bigger` rescaled every animal in `ANIMAL_HEIGHTS` to that height. Each animal is
scaled uniformly about its home with its soles kept at the same level, and its
`VocabularyArea` scales with it. `docs/evidence/part2/verify.gd` checks the height through `display_height`.
The species heights stay as the proportions between species. Three of them changed:

| Animal | Species height before → after | Display height now (town units) |
| --- | --- | ---: |
| Rhinoceros | 1.99 → 2.4 | 3.0 (×1.51) |
| Gorilla | 2.11 → 2.3 | 2.875 (×1.36) |
| Bear Cub | 1.52 → 1.05 | 1.31 (×0.86; 48% of the adult bear, was 69%) |

Every other animal grew by ×1.25. The displayed heights in town units are now:

- Giraffe 5.5, Elephant 3.94, Rhinoceros 3.0, Gorilla 2.88, Kangaroo 2.88, Bear 2.75, Tiger 2.63
- Deer 2.5, Lion 2.44, Horse 2.38, Zebra 2.14, Panda 2.09, Cow 1.94, Flamingo 1.75
- Sheep 1.31, Bear Cub 1.31, Pig 1.19, Red Panda 1.14, Monkey 1.06, Dog 1.0
- Snake, Cat, Rabbit, Field Mouse, Hen and Duck: 0.975 each (the minimum × 1.25)

BonBon is 1.72 town units tall. `MIN_ANIMAL_WORLD_HEIGHT` (1.014, the snake reference) is
unchanged. The fish, turtle and coast crabs are not changed. Before the bake, the homes and the
grown footprints were checked: no pair of wild-lawn animals ends up closer than their footprints
allow. The tightest pair is the elephant and panda, at 5.4 units where 5.1 is needed.

**Verification (11–12 Nov 2026, `dev_focus.txt` = all, isolated HOME, each run once).**
part2: PASS. `docs/evidence/clay-zoo-20261111/check.gd -- views`: 0 failures, and all 28 wanderers
moved 0.76–3.31 units while staying inside their areas. The renders in that folder were
replaced with views after the enlargement. In them every animal stands on the grass, and the
rhinoceros and gorilla rank under the elephant, near the bear.

## Clay flamingo display (11 Nov 2026, awaiting the user's review)

`scenes/animals/flamingo_clay.tscn` is a static study of the user's "Flamingo Character Blueprint"
turnaround, built by `tools/build_flamingo_clay.gd` from `scripts/characters/flamingo_clay.gd`
(extends the clay cow; about 122k triangles, 1.4 town units to the top of the crest, a provisional
height: "flamingo" is not in `ANIMAL_HEIGHTS` or the vocabulary). The bird is slim (legs 4 cm
thick), so it is meshed four times larger than life (`FF`; the cow uses 2). Beak, crest, wings with
the tail, and legs are separate clay pieces; each feather is a flattened puff laid on the body's
skin (`_feather`), the pale wing over salmon and dark blades that fan past the rump; the beak's
brown tip and the blush are painted; eyes, lids, lashes, brows and the mouth line are small parts
laid on the face. One instance, `ParkZoo/FlamingoClayDisplay`, stands on the open east side of
the wild-animal lawn at town (-58.5, 0.12, 117.0), facing the gate (base steps
`flamingo_clay_display`, `flamingo_clay_colours`, which swapped in deeper colours: the
sampled sheet colours washed out to pale peach in daylight). It has a box footprint and no word,
movement, animation or interaction; a rebuilt prefab reaches the zoo only through a new swap step.
Renders: `docs/evidence/flamingo-clay-20261111/` (`capture.gd`, stage only: `compare.png` = each blueprint
view above the model's at the same scale, `face-compare.png` the same for the head, `turnaround.png`,
`face.png`, `eyes.png`; `reference.png` is the user's sheet; with `-- zoo`, run once with an isolated
`HOME` and `VT_FOCUS=all VT_SPAWN=none`: `zoo-close.png`, `zoo-side.png`, `zoo-location.png`;
display y 0.156 world, physics ground beside it -0.046, the offset the other clay displays use).
Feather pass the same day (user: "refine feathers"): the back between the wings has painted rows
of round-ended feathers (`_back_feather`: a patch over a darker rim; clay feathers that small stood
off the tightly curved rump like plates, and turning the wing blades in toward the tail jumbled the
side view, so both were dropped), the tail's four feathers hang back instead of tucking under, and
base step `flamingo_clay_back_feathers` swapped the zoo instance.
Known differences from the sheet: the wing's feathers are softer and fewer than the sheet's crisp
scallops, and from behind the wing tips stand a little off the rump (P2); the eye shows
a thin white rim all round where the sheet shows white only on the outer side; in the side view the
eye sits about 10 px further forward than on the sheet (the sheet's front and side views disagree;
the model follows the front and 3/4 views); the head's crown is a little flatter. No test suite
was run.

## Clay duck display (11 Nov 2026, approved by the user and placed in the zoo)

`scenes/animals/duck_clay.tscn` is a static study of the user's "Duck Character Blueprint"
turnaround, built by `tools/build_duck_clay.gd` from `scripts/characters/duck_clay.gd` (extends
the clay cow: same mesher, paint and ray helpers, feathers laid on the skin as on the clay
flamingo; meshed 12 times life size; about 206k triangles, 0.45 town units to the top of the
crest, the `Duck` height in `park_animals.gd`). It is separate from the zoo's wandering ducks,
which are unchanged. One instance, `ParkZoo/DuckClayDisplay`, stands at the front of the
wild-animal lawn at town (-62.0, 0.12, 119.5), between the clay cow and the clay flamingo, facing
the gate (base step `duck_clay_display`; a rebuilt prefab needs a swap step like the gorilla's).
It has a box footprint and no behaviour, word or interaction.
Bill (upper and darker lower half), crest, wings, tail and legs are separate pieces; the blush
is painted; eyes, outline, brows, nostrils and the mouth line are small parts on the face. The
upper bill is cut underneath along a curved mouth surface (`_mouth_y`), which the lower lip and
the mouth line follow (bill revised 11 Nov 2026 at the user's request). The eyes are tall
glossy ovals, nearly filled by the black pupil, with a thin white crescent down the outer side
and one catch-light. The sheet's front view puts the eyes 39 px from the centre line and its
side view shows them full width and further back than one round head allows; the model follows
the front view (42 px), so from the side the eyes sit nearer the bill and look narrower.
Renders: `docs/evidence/duck-clay-20261111/` (`capture.gd` loads only the duck scene: `compare.png` =
blueprint views above the model's at the same scale, `face-compare.png`, `turnaround.png`,
`face.png`, `eyes.png`). Zoo views (`capture.gd -- zoo`, isolated `HOME`, `VT_FOCUS=all
VT_SPAWN=none`, once): `zoo-close.png`, `zoo-side.png`, `zoo-location.png`; printed display y
0.156 world, physics ground beside it -0.046, the offset the other clay displays use; the feet
meet the grass in the views. The bake applied 1 step. In the town's daylight the cream body
reads nearly white (not deepened; open, low priority). Not checked in the running game; no
test suite was run.

## Clay tiger (16 Nov 2026, rebuilt 17 Nov; approved, rigged and in the zoo as its tiger)

`scenes/animals/tiger_clay.tscn` is a static study of the user's "Tiger (Relaxed / Neutral)
Character Blueprint" turnaround, built by `tools/build_tiger_clay.gd` from
`scripts/characters/tiger_clay.gd` (extends the clay zebra: the lion's mesher, the giraffe's
paint, the zebra's painted stripes; the pig's `_rings` for the eyes). 145,468 triangles (body
132,907), built 2.1 town units to the ear tips, the `Tiger` height in `park_animals.gd`; the
zoo shows it at 2.63 like every animal (`DISPLAY_SCALE`). The user approved it on 17 Nov 2026
and chose: rig it first, then replace the zoo's wandering tiger at the same height
([below](#clay-tiger-walks-in-the-zoo-17-nov-2026)). The old piece-built prefab
`scenes/animals/tiger.tscn` is no longer in the town; the file is kept.

**Rebuilt from the ground up on 17 Nov 2026** (user, after two rounds: the head's shape and
proportions were wrong; rebuild the geometry, head first, silhouette before features). What the
first model got wrong, measured on the sheet with `measure.gd`: its skull was 142 px deep, 142
tall and 176 wide where the sheet's is about 175 deep, 156 tall and 184 wide, a near-ball; the width had been made up with cheeks stuck on its sides.
- **Profile solids (new, in `tiger_clay.gd`: `loft`, `_loft_f`, and its own `_dist`/`_box`,
  which pass every other shape to the lion's).** The skull is built from horizontal slices and
  the torso from cross-sections, each a rounded shape whose extents are the sheet's own
  outlines (`_skull`, `_torso`, `B_TOP`/`B_BOTTOM`/`B_WIDE`), so the front and side silhouettes
  are the sheet's by construction and can be corrected directly from an outline comparison.
  The distance used for blending is `f / |grad f|`, floored by the distance to the solid's
  26-direction faceted hull: without that floor the estimate collapses beside the solids' flat
  end planes and a wide blend welds a stray sliver there (found at the top of the skull).
  `lion_clay.gd` is not edited; a subclass's static `_dist` replaces it for that subclass only.
- **Build order and stages** (`stage` in the script, for study only): 1 bare skull; 2 bridge,
  muzzle mound with two whisker pads and a chin, lids, cheek ruffs, all run into the skull with
  wide blends; 3 nose, ears, brows; 4 eyes and face details; 5 torso, legs, paws, tail; 6 coat.
  Each stage was checked against the sheet before the next (`study.gd`).
- **The sheet's views.** Its "side" view is turned 25 degrees toward the front (the eye, the
  brow and both pairs of legs fit that turn), the front 3/4 is at 29 degrees and the rear 3/4
  at 132 from the front; all are close to orthographic and level. Side-view positions are turned
  back with `true_x()`; the animal stands square.
- Ready for rigging like the clay pig: `Body` is one fused mesh (head, torso, legs, cheek ruffs,
  tail); `Nose`, `Ears` and `Brows` (the cream rolls) are separate pieces; `LeftEye` and
  `RightEye` are separate meshes, each on its own node at the eye's centre with local y up the
  eye and local z out of the face (the lid line and lower rim are part of the eye, so a squash
  closes it to one line); whiskers, whisker dots and the mouth are `Face details`.
- Coat: the clay is all orange; cream (belly, chest, throat, jaw, muzzle, ruffs, paws) and the
  brown marks are painted with split edges. The clay grid is about 3 cm and `_paint` runs two
  edge-splitting passes instead of the zebra's three (`_paint_passes`, a variable added to
  `zebra_clay.gd` on 16 Nov whose default leaves the zebra as it was: rebuilt once then,
  313,181 triangles, mesh files unchanged in git).
Evidence, `docs/evidence/tiger-clay-20261116/` (every script loads only the tiger):
`measure.gd` (the sheet's outlines row by row, gridded crops); `study.gd` (a build stage
rendered orthographically from the sheet's angles with the outlines drawn over each other:
`outline-head.png`, `outline-body.png`, `outline-paws.png`, `outline-muzzle.png` for the finished model: sheet with the model's outline
in magenta above, model with the sheet's outline in blue below); `capture.gd` (the saved scene:
`compare.png` = the sheet's five views over the model's, `face.png` and `eyes.png` = sheet
beside model, `turnaround.png` with a true side view and a view from above).

Face and paws pass, 17 Nov 2026 (user: "only refine the face and the paws"; torso, legs, tail
and stripes untouched), measured on enlarged crops of the sheet:
- Paws: three fat toes lying side by side (round-ended rolls from the heel to the front, real
  grooves between them, `P_TOE`/`P_TOE_R`), the leg blended down into them so the grooves fade
  over the top; the heel end spreads a little at the ground. Cream (`_paw_cream`): the toes and
  the foot up to a level edge across the front of the leg, lower along the sides, and a tall
  round arch up the back of each leg, as on the sheet's back view; the grooves are drawn a shade
  darker (`T_TOE_LINE`; they split like the stripes because they are thinner than a triangle).
  Before, each paw was a flat lens with three small bumps and a straight cream edge.
- Face: the whisker pads are round balls about 46 px across and close together (were 54 by 37,
  flat); the chin is softer; the nose has two wide wings over a short stem with a large nostril
  under each wing (was a rounded triangle, sunk in the pads); the mouth line follows the sheet's
  measured "W", lighter and fading toward its ends; one column of two whisker dots a side (the
  sheet's second column is the whiskers' thick roots), three whiskers a side with thick roots;
  the cheek ruffs' three scallops are a little more distinct.
Known differences that remain: the chest is a smooth cream bib without the sheet's fur tufts;
the cheek ruffs are still smoother than the sheet's lobes; the stripes follow the sheet's
pattern but not stripe for stripe; the whites of the eyes have little soft shading; in the
sheet's front and side views the near paws look about 4 px taller than the model's because the
sheet's camera looks slightly down. No test suite was run (no town change).

## Clay rooster display (17 Nov 2026, approved by the user and placed on the farm)

`scenes/animals/rooster_clay.tscn` is a static study of the user's "Rooster Character Blueprint"
turnaround (relaxed idle pose), built by `tools/build_rooster_clay.gd` from
`scripts/characters/rooster_clay.gd` (extends the clay cow: same mesher, paint and ray helpers,
feathers laid like the clay duck's; meshed 6 times life size; 137,632 triangles; 0.6 town units
to the top of the comb, the user's choice, as built). "Rooster" is not in `ANIMAL_HEIGHTS` or the
vocabulary, and the farm's hen is unchanged. One instance, `ParkZoo/RoosterClayDisplay`, stands
on the farm lawn at town (72.5, 0.12, 103.5), right of the path from the farm gate and in front
of the hen's home, facing the gate (base step `rooster_clay_display`, which also stores it as
plain nodes with `unpack_clay_animals`, because the web export leaves the clay prefab scenes
out). It has a box footprint and no word, movement, animation or interaction. A rebuilt prefab
reaches the farm through its mesh files as long as the part names stay the same.

Built ready for rigging like the clay pig: head, neck feathers, body, legs and feet are one fused
mesh (`Body`); `Beak`, `Beak lower`, `Comb`, `Wattles`, `Wings` and `Tail` are separate clay
pieces; each eye is its own mesh centred on its own node (`LeftEye`, `RightEye`: local x across
the eye, y up the eye, z out of the face; one shaded dome with soft iris and pupil edges, built
with the pig's ring builder); lids, brows, nostrils and the mouth line are `Face details`. The
wing is one smooth pad with four low-relief lobes and a painted top-to-bottom shade; the neck
feathers are two layers of tongues round the rim of a smooth cape; the tail is nine sickle
blades (`_blade`).

Renders: `docs/evidence/rooster-clay-20261116/` (`capture.gd` loads only the rooster scene:
`compare.png` = each blueprint view above the model's at the same scale, `face-compare.png`,
`eyes-compare.png`, `turnaround.png`, `face.png`, `eyes.png`; `reference.png` is the user's
sheet). Town views (`capture.gd -- zoo`, isolated `HOME`, `VT_FOCUS=all VT_SPAWN=none`,
`dev_focus.txt` = `all`, once): `zoo-close.png`, `zoo-side.png`, `zoo-location.png`; printed
display y 0.156 world, physics ground beside it -0.046, the offset the other clay displays use;
the feet meet the grass in the views. The bake applied 1 step (14,226 nodes).

Known differences from the sheet (user approved 17 Nov 2026 after four review rounds): the
sheet's front and side views disagree about the eyes; the model follows the front and 3/4
views (eyes face 45° outward), so from the side they look narrower and sit further forward;
the beak is smaller and pointier in profile; the neck hem is more regular; the tail is narrower
from behind; the legs stand level (the sheet's side view staggers them). In the town's daylight
the head and neck read paler and yellower than on the sheet (not deepened; open, low priority).
Not checked: the running game, a web export or a phone; no test suite was run. Walking and
blinking are a separate step the user has not approved yet (needs its own bone setup).

## Clay chick display (18 Nov 2026, approved by the user and placed on the farm)

`scenes/animals/chick_clay.tscn` is a static study of the user's "Chick Character Blueprint"
turnaround (relaxed idle pose), built by `tools/build_chick_clay.gd` from
`scripts/characters/chick_clay.gd` (extends the clay cow: same mesher, paint and ray helpers;
meshed 9 times life size, the beak, crown and tail finer still with `_mesh_fine`; 141,684
triangles; 0.4 town units to the top of the crown feathers, the user's choice, as built).
"Chick" is not in `ANIMAL_HEIGHTS` or the vocabulary, and the farm's hen is unchanged. One
instance, `ParkZoo/ChickClayDisplay`, stands on the farm lawn at town (71.7, 0.12, 103.8),
beside the [clay rooster](#clay-rooster-display-17-nov-2026-approved-by-the-user-and-placed-on-the-farm)
(0.8 town units toward the farm gate from it; the user's choice), facing the gate like the
rooster (base step `chick_clay_display`, which also stores it as plain nodes with
`unpack_clay_animals`). It has a box footprint and no word, movement, animation or interaction.
A rebuilt prefab reaches the farm through its mesh files as long as the part names stay the same.

Built ready for rigging like the clay pig: head, body, legs and feet are one fused mesh (`Body`);
`Beak`, `Crest`, `Wings` and `Tail` are separate clay pieces; each eye is its own mesh centred on
its own node (`LeftEye`, `RightEye`: local x across the eye, y up the eye, z out of the face; one
painted dome that follows the head, with a catch-light). There is no `Face details` part: the
chick has no brows or smile lines, and the mouth is the step between the two halves of the beak.
The cream belly, the blush and a soft shade round each eye are painted on the skin.

Shape (user's direction, 18 Nov 2026, after three earlier passes read as one egg): head and body
are two round volumes with small blends, the head wider and fullest low at the cheeks, a soft
fold at the neck that shows at the sides and back, and a rump behind the head. The crown is
three smooth curved feathers (`_plume`: one round-ended tube each). Each wing is one thick
smooth oval pad along the flank with three scalloped tips at the rear (`_wing_piece`).

Renders: `docs/evidence/chick-clay-20261116/` (`capture.gd` loads only the chick scene:
`compare.png` = each blueprint view above the model's at the same scale, `face.png`,
`details.png`, `overlay.png`, `turnaround.png`; `reference.png` is the user's sheet). Town views
(`capture.gd -- zoo`, isolated `HOME`, `VT_FOCUS=all VT_SPAWN=none`, `dev_focus.txt` = `all`,
once): `zoo-close.png`, `zoo-front.png`, `zoo-side.png`, `zoo-location.png`; printed display y
0.156 world, physics ground beside it -0.046, the offset the other clay displays use; the feet
meet the grass in the views. The bake applied 1 step (13,975 nodes); `compare_scenes.gd` shows
the display's 10 nodes added, and 26 signs gaining `sign_pixel_base` / `sign_outline_base` metas
from the bake tool as it stood that day (not from this step). No test suite was run.

Known differences from the sheet (user approved 18 Nov 2026 after five review rounds): the
sheet's front and side views disagree about the eyes; the model follows the front and 3/4 views,
so from the side they look narrower and sit nearer the beak. The sheet's 3/4 view shows a larger
wing than its side view; the model follows the side view. From the front the toes splay into a
flat pad (the sheet's point forward), and the tall crown feather merges with the short one at
the base. The belly reads paler than the sheet's peach cream. An occasional single-pixel speck
appears in studio renders; the meshes scan clean (no dark vertices, zero normals or flipped
triangles), and the cause was not found. Not done: rigging, walking, blinking, a word.

## Zoo zones (12 Nov 2026)

User design (see the [design record](TOWN_DESIGN_BRIEF.md#zoo-zones--12-november-2026)): the 16
wild-lawn animals moved to four fenced zones (base step `zoo_zones`, table `ZONE_HOMES` in
`scripts/buildings/base.gd`). Each keeps its size, word, profile and model; it faces the visitors
(rotation 0) and its home is its new place, 1.5 cm higher to stand on the zone ground. Its
habitat is now the zone, because `park_animals.gd` `ZOO_LAWNS` lists the zone grounds after the
two lawns (a later match wins). Farm and meadow animals are unchanged.

| Zone | Animals (home x, z) |
| --- | --- |
| Savanna | Giraffe (−94, 89), Rhinoceros (−86, 95), Deer (−84.5, 89.5), Kangaroo (−96.5, 93.5), Zebra (−91, 97) |
| Forest | Bear (−64, 93), Bear Cub (−58.5, 96), Gorilla (−70.5, 96) |
| Bamboo Grove | Panda (−94, 116), Red Panda (−86, 116), Monkey (−83, 119.5) |
| Wildlife Plains | Elephant (−66, 114.5), Lion (−72, 119), Tiger (−59.5, 119), Flamingo (−58.5, 111, in the pond), Snake (−71.5, 110.5) |

Check: `docs/evidence/zoo-zones-20261112/check.gd` (`-- views` renders the overview, each zone, the
entrance and the plaza into that folder).


## Clay file sizes (16 Nov 2026)

Part of the graphics pipeline upgrade (user, 16 Nov 2026: web/PWA performance first, the clay
look unchanged). The 17 clay builds (`tools/build_<animal>_clay.gd`) now save through one shared
step, `tools/clay_save.gd`: the prefab scene (`scenes/animals/<animal>_clay.tscn`, the lion's
`.scn`; same paths) keeps only the nodes, and each part's mesh is its own zstd-compressed binary
file, `scenes/animals/clay_meshes/<animal>/<part>.res` (part name in snake case, e.g.
`face_details.res`), with compressed vertex attributes (`Mesh.ARRAY_FLAG_COMPRESS_ATTRIBUTES`:
16-bit positions in the part's box, packed normals). Vertex colours stay exact 8-bit RGBA and
the triangles are the mesher's own; the mesher scripts (`lion_clay.gd`, `cow_clay.gd`, the
animals' scripts) are unchanged. Base step `clay_meshes_external` gave each zoo model
(`ParkZoo/<Name>/Clay<Name>`) the new meshes part by part, so `base.scn` now names the mesh
files instead of embedding copies (the bake changed nothing else: `compare_scenes.gd`, 14,164
nodes, only `applied_steps` differs). **A rebuilt clay animal now reaches the zoo directly**
through its mesh files, with no swap step or bake, as long as its part names stay the same; a
new or renamed part still needs a base step. The web export keeps leaving the tiny prefab
scenes out and includes `clay_meshes/`.

Measured before → after (`docs/evidence/clay-sizes-20261116/measure.gd`, headless, Apple M5;
`measure-before.md`, `measure-after.md`): files = prefab plus its mesh files; load = the prefab
loaded with the cache ignored, second of two loads.

| Animal | Triangles (vertices), unchanged | Files before → after (MB) | Prefab load before → after (ms) |
| --- | ---: | ---: | ---: |
| black bear cub | 98,357 (74,332) | 2.9 → 1.0 | 263 → 2 |
| black bear adult | 114,043 (82,144) | 3.3 → 1.2 | 288 → 3 |
| cow | 113,167 (81,515) | 3.3 → 1.2 | 286 → 3 |
| deer | 73,369 (58,665) | 2.3 → 0.8 | 203 → 2 |
| duck | 205,636 (131,392) | 5.5 → 2.1 | 489 → 4 |
| elephant | 136,212 (83,232) | 3.5 → 1.4 | 313 → 3 |
| flamingo | 124,270 (90,466) | 3.6 → 1.3 | 319 → 3 |
| giraffe | 97,158 (63,859) | 2.7 → 1.1 | 233 → 2 |
| golden retriever | 188,556 (175,059) | 6.5 → 2.1 | 573 → 4 |
| gorilla | 105,009 (79,127) | 3.1 → 1.1 | 283 → 2 |
| kangaroo | 72,764 (48,383) | 2.0 → 0.8 | 176 → 2 |
| lion (was already binary) | 70,428 (41,308) | 1.3 → 0.7 | 0 → 1 |
| panda | 59,004 (57,794) | 2.1 → 0.6 | 190 → 2 |
| pig | 148,607 (85,680) | 3.7 → 1.5 | 332 → 3 |
| red panda | 99,045 (68,916) | 2.8 → 1.1 | 252 → 2 |
| rhino | 186,149 (116,068) | 6.1 → 1.9 | 556 → 5 |
| zebra | 313,181 (195,238) | 10.5 → 3.4 | 924 → 10 |
| **all 17** | **2,204,955 (1,533,178)** | **65.4 → 23.3** | **5,682 → 52** |

| Town and web | Before | After |
| --- | ---: | ---: |
| `scenes/town/base.scn` on disk | 70.7 MB (clay embedded) | 20.1 MB + 23.8 MB clay mesh files |
| `base.scn` load with its dependencies (headless) | 458 ms | 442 ms |
| Web export `index.pck` (`tools/deploy_web.py`, not published) | 55.0 MB | 46.7 MB |
| clay meshes inside `index.pck` | ≈ 32.7 MB (in `base.compressed.scn`) | 24.4 MB (110 files) |

The export already zstd-compressed `base.scn` (`base.compressed.scn`, 39.7 MB before), so the
web saving (−8.3 MB, −15% of the pack) comes from the compressed vertex attributes; the text
prefabs were never in the web pack. The in-town load time is about the same (the town copy was
already binary); the prefab files load ~100× faster than the old text scenes, which matters to
the tools and anything that loads a prefab (e.g. the pig animation pilot).

Not done, on purpose:
- **No LODs.** `ImporterMesh.generate_lods` halves the zebra body (286k → 143k triangles at
  0.05% geometric error), but it ignores vertex colours: its levels moved the zebra's stripe
  edges and left dark pinhole specks even in the eye close-up (0.2–0.8% of pixels changed per
  animal, against 0.01% without LODs; `lod-trial-zebra-brow-original.png`,
  `lod-trial-zebra-brow-with-lods.png`, `lod-trial-zebra-diff.png`). A colour-safe LOD (for
  example a second, coarser run of the mesher per part) is an open follow-up; the zoo still
  draws 2.2M triangles.
- No visibility ranges (wanderers would pop out) and no coarser clay grid (stripes and creases
  would soften).

Verification (16 Nov 2026, isolated `HOME`, `dev_focus.txt` = `all`, each run once):
resource loading of all 17 prefabs and `base.scn` (`measure.gd`, no errors); the base bake
(1 step) and `compare_scenes.gd` (1 difference, `applied_steps`); `deploy_web.py` export (its
clay-reference check passed). Rendered views, compared pixel by pixel with `views.gd -- diff`:
studio strips of every prefab, old files taken from git vs rebuilt (`views.gd`: front 3/4,
side, face, eyes) differ on 0.008–0.016% of pixels, single pixels along silhouettes from the
16-bit positions (`diff-prefabs.txt`; `prefab-<zebra|pig|lion|golden_retriever>-<before|after|diff>.png`);
the zoo in the town at noon (`zoo.gd`: overview, two mid views, zebra, pig, lion and dog close-ups)
differs on at most 0.026% (`diff-zoo.txt`, `zoo-<overview|zebra|lion>-<before|after|diff>.png`).
Not checked: the running game in a browser or on a phone, and no test suite was run.

## Clay animal animation (16 Nov 2026)

Pilot on one animal, the clay pig, of reusable animation for the clay animals (user, 16 Nov
2026: head, blink, idle and walk without seams, the same pastel clay look, good web
performance). **In the zoo since 16 Nov 2026** (user approved the pilot: "Put it in the zoo"):
base step `pig_clay_walks` swaps `ParkZoo/Pig/ClayPig` for an instance of the rig (same name,
transform and bounds; Footprint off as in `_clay_roamer`), and Main's `clay_life` (a second
`PlushLife`, `follow_group("clay_animals")`, town blink gap) blinks it. **Rolled out to every
clay zoo animal the same day** (user: "do it to all the other animals"; clay animals first):
[all clay zoo animals walk](#all-clay-zoo-animals-walk-16-nov-2026). The 11 older piece-built
animals (tiger, monkey, horse, sheep, hen, cat, rabbit, field mouse, snake, turtle, fish) still
glide.
The rig's meshes and skin are separate files, `scenes/animals/clay_meshes/pig_rig/*.res`
(written by the build tool), because the bake saves an instance's parts as overrides: with the
meshes inside the rig scene, base.scn copied them (+1.35 MB); now it names them (+6.5 KB). The
rig is not a `*_clay` scene, so `unpack_clay_animals()` and the web exclude filter leave it an
instance, and a rebuilt rig reaches the zoo without a new step. The animator's on-screen
notifier is a child named `OnScreen`, reused when present (the bake saves it).
Town checks: [below](#zoo-pig-in-the-town-16-nov-2026).

**Files.** `scripts/characters/clay_rig.gd` (bake-time rigger, any clay display),
`tools/build_pig_clay_rig.gd` (the pig's bones and settings) →
`scenes/animals/pig_clay_rigged.scn` (3 KB + `clay_meshes/pig_rig/`, 0.73 MB), and the runtime component
`scripts/characters/clay_animator.gd`. The rig is built from the finished
`scenes/animals/pig_clay.tscn`; `pig_clay.gd`, `cow_clay.gd`, `lion_clay.gd` and the display
scene are only read. Rebuild the rig after the display changes:
`godot --headless --path . --script res://tools/build_pig_clay_rig.gd` (about 0.5 s).

**How the rig works.** The body, head and legs are one fused mesh, so it is skinned rather than
cut: each bone (root; body; head; tail; four legs; two ears on the head) gets simple shapes
(spheres and capsules in the sheet's pixels), and every vertex blends up to four bones by its
distance to them, `w = exp(-(d - d_min) / blend)` with `blend` 10 sheet px. The weights change
smoothly through the neck fold and the hips, so the clay stretches instead of tearing. Snout and
tail are rigid on the head and tail bones; hooves follow their leg. The skinned parts sharing the
clay material are merged into one surface (`Skeleton3D/Clay`) and thinned at bake time with
Godot's simplifier (`simplify`: body, ears and hooves to 25%, snout 50%; it keeps original
vertices, normals and colours): 39k triangles against the display's 149k. Eyes and the face
details (brows, lip, smile) are not skinned: they sit under a `BoneAttachment3D` named `Head` on
the head bone, the eyes split into `Head/LeftEye` and `Head/RightEye`, each centred on its node
with local y up the eye.

**Component API (`clay_animator.gd`, node `ClayAnimator` beside `Skeleton3D`).**
- Per-species settings are exported properties the build tool writes: `legs` + `leg_phase`
  (gait; the pig trots, diagonal pairs together), `leg_length`, `swing_deg`, `stride_scale`,
  `lift`, `bob`, `roll_deg`, `breath`, `breath_seconds`, `shift_deg`, `head_turn_deg`,
  `look_gap`, `nod_deg`, `tail_deg`, `ear_deg`, `still_speed`.
- Speed is measured from the root's own movement each frame, so any mover drives the walk; the
  cycle advances by speed / stride (stride = 2π × leg length × swing), so the feet roughly keep
  pace with the ground, and the walk fades in and out over a third of a second.
- Standing: slow breathing (body swells sideways), a weight shift from side to side, a gentle
  tail wag and an idle look to one side every 2.5–6 s.
- `look(yaw_deg, seconds)` turns the head (+ = the animal's left, clamped to `head_turn_deg`);
  `speed_override` and `advance(dt)` drive it by hand (captures).
- Hook to `park_animals.gd`: none needed in that file. The animator finds a wanderer among its
  ancestors and, while it walks, turns the head a little toward its `target`.
- Ownership: clay_animator.gd is the only writer of the bone poses; the mover owns the root's
  position and rotation. Eyes belong to `plush_life.gd`: the animator puts the rig's root in
  group `clay_animals`, and one `PlushLife` with `follow_group("clay_animals")` blinks them all
  (it squashes `Head/LeftEye` and `Head/RightEye`, as on the plushes). Not group `figures`: that
  group also means seat occupancy (`seating_controller.gd`). The plush rule "never rotate
  `Head`" stays for plushes; on a clay rig `Head` follows the head bone and is never written.
- Off screen (a `VisibleOnScreenNotifier3D` it adds) and when hidden it does not update the pose.
- Options added for the other species (16 Nov 2026, merged from four parallel rig sessions;
  every default keeps the pig's behaviour, checked bone for bone by
  `docs/evidence/odd-gaits-anim-20261116/pig_check.gd`). Legs and feet: `leg_neutral_deg`
  (displays standing mid-stride swing about a straighter angle) with `straighten_lift` (raise a
  straightened slanted leg so it does not sink; deer, rhino), `feet` (foot bones kept level),
  `lower_legs` + `bend_deg` (a knee that folds while the leg swings; flamingo), `ground_lock`,
  `keep_feet_down`, `foot_reach`, `foot_contacts` + `foot_stretch` (each leg scaled so its rest
  contact point stays on the ground; elephant, giraffe, lion). Body: `hop`, `hop_pitch_deg`,
  `tail_lift_deg` (kangaroo), `twist_deg`, `sway`. Neck and head: `neck` (one bone or a chain)
  with `neck_share`, `neck_pump_deg` (duck, flamingo), `neck_sway_deg` (an S-neck that takes half
  the turn), `head_bob`; `trunk`, `trunk_sway_deg`, `trunk_curl_deg`, `trunk_seconds` (elephant).
  Tail and ears: `tail_axis`, `wag_speed`, `tail_chain` + `tail_lag` (a tail that follows
  through), `ear_axis`, `ear_fan_seconds`. Each species' choices and renders are in its group's
  evidence notes (table below).

**Checks** (`docs/evidence/pig-anim-20261116/`; `capture.gd` loads only the two pig scenes and
`pig_anim_test.tscn`, a stage with the original display beside the rigged pig wandering with
`park_animals.gd` and blinked by a `PlushLife`; run it to watch them):
- `compare.png`: display (top) and rigged pig at rest (bottom), four views, studio light. Pixel
  difference over the pig: mean 0.66–0.74 levels of 255, 0.10–0.18% of pixels more than 8
  levels apart (the thinning; before it, 0.01–0.03 levels). Shading matches.
- `seams.png`: neck and hips close up at both extremes of the swing with the head turned 24°
  (side, above, below): no tears or gaps; the clay stretches over the shoulder and thigh.
- `walk.png` (8 frames of a cycle, side; 4 from the front 3/4), `idle.png` (6 frames 0.6 s
  apart; the motion is deliberately small), `blink.png` (open, half, shut), `head-turn.png`
  (right, centre, left), `wander.png` (the test stage running: the rigged pig walking by itself;
  the static display beside it shows its back).
- `perf.json`, frame times on the Compatibility renderer (Apple M5, macOS, 1000×700, vsync off,
  240 frames after 90 warm-up, pigs idling or walking with `park_animals.gd`):

| Case | Frame ms (mean / p95) | Render CPU ms |
| --- | ---: | ---: |
| Empty stage | 0.44 / 0.62 | 0.04 |
| 10 static display pigs (149k tris each) | 2.12 / 4.55 | 0.14 |
| 1 rigged pig | 0.76 / 0.74 | 0.09 |
| 10 rigged pigs | 2.79 / 5.44 | 1.54 |
| 10 rigged pigs, animator off | 1.01 / 3.60 | 0.09 |
| 10 rigged pigs, camera turned away | 0.36 / 0.41 | 0.03 |

  The first build (six skinned parts per pig, full detail) took 11.9 ms a frame for 10 pigs
  (render CPU 10.6): on this renderer the cost follows the number of skinned surfaces whose pose
  changes, far more than their vertices (thinning alone left it at 11.6 ms; merging into one
  surface brought it to 2.8). GPU time is not reported by the Compatibility renderer on macOS
  (0). A covered window gave meaningless timings (6.9 ms for every case); check that
  `triangles_drawn` changes between cases. `capture.gd` does not exit by itself after its report.

Not checked: a web export or a phone, and the town (the rig was never placed there). The check
suite was not run (no town change).

Risks for a rollout to other species (written before the rollout; how each was met is in
[all clay zoo animals walk](#all-clay-zoo-animals-walk-16-nov-2026)):
- **Bone shapes are per species.** Each needs its own spec (pivots and capsules in its sheet's
  pixels), and its folds may need another `blend`: long necks (giraffe, flamingo), a trunk,
  manes (the lion's mane is its own mesh and would need weights to the head and body), two-legged
  or hopping gaits (gorilla, kangaroo, duck, flamingo) need new `legs`/`leg_phase` settings and
  maybe a gait other than the swing.
- **Rigid parts across a joint** (a mane, a long tail, the cow's udder) need blended weights too,
  or they will slide through the body.
- **Cost with many animals.** About 0.2 ms of render CPU per animated, visible animal on an M5
  here; the zoo has about 25 animals and a phone or the browser will be several times slower.
  Off-screen animals cost nothing; further savings if needed: update far animals at a lower
  rate, or freeze the pose beyond a distance.
- **The display and the rig can drift apart.** A rebuilt display must be followed by a rebuilt
  rig (`tools/build_pig_clay_rig.gd`), and the zoo's saved instance would need a swap step.
- **The wander controller turns the animal while it glides** (`park_animals.gd`): with legs it
  may show foot sliding on sharp turns; tune `stride_scale` per species.

### Zoo pig in the town (16 Nov 2026)

`dev_focus.txt` = `all`, isolated `HOME`, each run once: base bake (`pig_clay_walks`: the pig's
visible bounds identical before and after the swap), `run_checks.py --only
runtime_resources,compact_layout,interaction`: all PASS. Rendered in the full town at noon by
`docs/evidence/pig-zoo-walk-20261116/walk.gd`: `walk.png` (8 frames 0.12 s apart following the
walking zoo pig from the side: legs trot, hooves lift, body bobs) and `context.png` (standing
on its lawn). The same run: the pig is in group `clay_animals` and in `clay_life`'s list.
Not checked: a web export or phone, frame time in the town, and the full check suite.

### Clay tiger walks in the zoo (17 Nov 2026)

User, 17 Nov 2026, on approving the clay tiger: "rig it first then replace the zoo tiger", the
same height as the zoo tiger (2.63 shown).
- **Rig.** `tools/build_tiger_clay_rig.gd` (extends `tools/clay_rig_tool.gd`) →
  `scenes/animals/tiger_clay_rigged.scn` + `clay_meshes/tiger_rig/`: 45,422 triangles (display
  145,468), one skinned surface. Bones: root, body, head (no neck bone: the big skull sits on
  the shoulders and turns about a pivot in the neck, with the muzzle and cheek ruffs), tail and
  tail_2 (the hanging tail swings like a pendulum, its tip a beat behind), ear_l, ear_r, four
  legs (pivots inside the shoulder and thigh, shapes from under the belly to the paw). A
  lateral walk with short steps, the soles kept on the ground (`keep_feet_down`).
- **Two small extensions to shared code**, both no-ops for the other animals: `clay_rig.gd`
  `on_head` pieces keep their own transform, so a display that already has `LeftEye` and
  `RightEye` on their own nodes lists them there instead of `eyes` (the tiger's eyes include
  their lid line and rim, so a blink closes them to one line); `clay_rig_tool.gd` takes an
  optional `prepare` Callable for the display copy. The tiger uses it to close the gaps its
  painted stripes leave in the body (the zebra tool's `_closed`): without that the simplifier
  tore the paws and tail tip (rest difference about 18 levels; 0.7 after).
- **Zoo.** Base step `tiger_clay_walks`: `ParkZoo/Tiger` (the last wild animal still built from
  pieces, about 200 nodes) is rebuilt with `_clay_roamer` at its old home in Wildlife Plains
  (−59.5, 119), facing, child index and word `tiger`, brought to the shown height (2.625 zoo
  units) with its soles at the old tiger's level (y 0.155), then given the rig with
  `_clay_walker`. `compare_scenes.gd`: 14,217 → 14,041 nodes, 203 differences, all under
  `ParkZoo/Tiger` plus the step list.
- **Checks** (`dev_focus.txt` = `all`, isolated `HOME`, each run once): `run_checks.py --only
  runtime_resources,compact_layout,interaction,part2`: all PASS.
  `docs/evidence/tiger-anim-20261117/`: `capture.gd` (display and rig only): `tiger_clay-compare.png`
  (rest difference 0.68–0.76 levels, 0.55–0.74% of pixels over 8 levels), `-walk.png`,
  `-seams.png` (head turned at both extremes of the swing: no tears), `-tail.png`, `-blink.png`,
  `-weights.png`; `zoo.gd` (full town, noon): the tiger has the word, the rig, is in group
  `clay_animals` and in `clay_life`'s list, and reaches `walking` with the walk faded in;
  `zoo-context.png`, `zoo-close.png`, `zoo-walk.png` (8 frames 0.12 s apart).
- Not checked: a web export or a phone, frame time with 18 rigs, and the full check suite.
  A rebuilt display needs the rig rebuilt after it (`tools/build_tiger_clay_rig.gd`); the zoo
  then picks it up with no new step.

### All clay zoo animals walk (16 Nov 2026)

User, 16 Nov 2026: "do it to all the other animals", clay animals first (the 11 older
piece-built animals are not included). Rigs were built in four parallel sessions, one per group of
gaits, each following the pig's method with its own `tools/build_<prefab>_clay_rig.gd` →
`scenes/animals/<prefab>_clay_rigged.scn` + `clay_meshes/<prefab>_rig/`; per-species bone choices,
renders (compare, seams, walk, blink) and limits are in each group's notes:

| Group | Animals | Evidence |
| --- | --- | --- |
| Hoofed | cow, deer, rhino, zebra | [notes](../evidence/hoofed-anim-20261116/notes.md) |
| Big | elephant (trunk), giraffe (neck chain), lion (mane, a second skinned surface) | [notes](../evidence/big-anim-20261116/notes.md) |
| Bears and dog | black bear (adult and cub), panda, red panda, golden retriever | [notes](../evidence/bears-dog-anim-20261116/notes.md) |
| Odd gaits | gorilla (knuckle walk), kangaroo (hop), duck, flamingo (folding ankle) | [notes](../evidence/odd-gaits-anim-20261116/notes.md) |

**Merge.** All four sessions extended `clay_animator.gd`; the merge combined them into one file
(options listed under the component API above). Renamed or changed in the merge: the big
group's per-leg contact points `feet` → `foot_contacts` (`feet` stays the foot bones); the leg
lift for `leg_neutral_deg` is opt-in (`straighten_lift`, deer and rhino); `neck` is one bone or a
chain; the S-neck tilt follows the whole head yaw. Checked: the pig's bone poses equal the
original animator's at 8 phases (`odd-gaits-anim-20261116/pig_check.gd`); each group's renders
rebuilt from the merged animator match its session's (flamingo, giraffe, lion, deer exactly; the
dog about 1% apart, from capture order).

**Zoo.** Base step `clay_animals_walk` swaps the 16 other `ParkZoo/<Name>/Clay<Name>` models for
their rigs with the pig's helper (`_clay_walker`: same name, transform and place among the
children; Footprint off). Visible bounds before/after each swap agree within about 0.3%;
`base.scn` +38 KB (the rig meshes stay external).

**Town checks** (`dev_focus.txt` = `all`, isolated `HOME`, each run once):
`run_checks.py --only runtime_resources,compact_layout,interaction`: all PASS.
`docs/evidence/zoo-walk-20261116/zoo_walk.gd` (full town, noon): every one of the 17 animals
reaches `walking` with the walk fully faded in; 17 rigs in group `clay_animals` and in
`clay_life`'s list. `walkers.png` (each animal caught walking, camera on an unblocked side;
the rhino's tile shows it only at the edge behind the deer) and `overview.png` (forest and wild
lawns from above). Frame time over the zoo with every rig on screen at once, 900×600, Apple M5:
10.64 ms with the 17 animators running, 8.57 ms with them paused (about 2.1 ms for the animation).

Not checked: a web export or a phone (expect several times the M5 cost; the risks above list
the savings), and the full check suite. The golden retriever rig is the heaviest (about 72k
triangles; thinning it further is the first saving). The 11 piece-built animals still glide.
