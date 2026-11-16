# Garden performance and reference polish — 2026-10-19

The saved public garden scene now includes taller coursed stone towers, stepped pier capitals, cornices, and fine suspension hangers. At runtime the pond receives an opaque animated water shader with green depth tones, gentle ripples and a view-dependent sky tint. It does not render a second camera or use screen-space reflections.

Performance changes:
- 1,831 stationary garden primitive meshes render as 174 spatially grouped MultiMeshes. Original nodes remain available to map rebuilds and the source scene remains editable. Vocabulary areas and collision bodies are retained.
- Decorative garden spheres use 16 radial segments / 8 rings. This avoids spending thousands of triangles on each tiny flower.
- The minimap omits individual flower/rail decorations, skips offscreen drawing, stops redraws while the player is stationary, and does no processing while hidden. The full atlas uses the same checks.
- Door transforms stop updating once settled. Sliding doors only perform obstruction queries while moving; interaction still resumes animation normally.
- The scene baker explicitly skips runtime batching so it saves editable geometry.

## Measurement

Godot 4.7.2 Compatibility renderer, Apple M5, 1280×720, VSync disabled, fixed bridge camera, 40 warm-up frames and 120 measured frames. HUD enabled; player stationary. These are local observations, not guaranteed FPS across the town or other devices.

| Metric | Original | Updated |
| --- | ---: | ---: |
| Median frame time | 110.403 ms | 19.721 ms |
| 95th percentile frame time | 123.736 ms | 25.472 ms |
| Frame draw calls | 19,766 | 10,085 |
| Frame primitives | 6,173,030 | 2,178,603 |

Median frame time decreased about 82% (approximately 9 → 51 FPS for this stationary view). The updates reduce render work, not authored node count: source meshes remain hidden at runtime to preserve map rebuilding and editing.

Run `godot --path . --resolution 1280x720 --script res://docs/guides/performance/benchmark.gd` to repeat. `before.png` and `latest.png` capture the comparison. Clean previews are in `docs/guides/public-garden/`.

## Verification

- Active resource loading: 303 resources, zero failures.
- Public garden walking/collision suite: 2,004 path samples, bridge crossed in both directions, dock entry, landmark/vocabulary preservation; zero failures.
- Rendering regression checks: batch count/idempotence, map rebuilding after shader installation, and restarting settled door animation.
- Rendered bridge, overview, dock, statue, and district previews inspected; no shader errors.

Source backups from this change were removed on 27 October 2026 when the project moved to git; repository history starts after it. The preexisting reference-town source remains the basis of regeneration.

## Lighting and sky

Since 9 November 2026 `scripts/world/day_night.gd` (created by `Main.build_world()`) owns
the sun (`Soft daylight`, still a direct child of Main) and the `WorldEnvironment`, and
changes them through the day; no other runtime script changes them, except
`render_culling.gd`, which sets the sun's shadow distance and cascades. See
[Day-night cycle](#day-night-cycle--9-november-2026). Since 27 October 2026 the town
uses a `ProceduralSkyMaterial` gradient sky, depth fog whose color matches the sky
horizon (`c9e2ef` by day) so the sea fades into haze, and ACES tonemapping with light
saturation/contrast grading.

Tuning notes for the Compatibility renderer:
- Keep ambient light on a warm color source. Sky-sourced ambient, even at partial
  contribution, washed out every interior.
- Fog density 0.0016 whited out aerial views; 0.0005 gives haze only at a distance.
- Interiors are lit mostly by ambient fill, so sun changes affect outdoor views only.
  The Home is the exception: its roof lifts while the player is inside, so the sun
  lights its rooms by day; at night it is lamp-lit and darker (9 Nov 2026).

Fixed-camera evidence and the capture script are in `docs/evidence/lighting-sky-20261027/`;
checks and the measured frame-time cost are in the
[verification record](../FINAL_VERIFICATION.md#lighting-and-sky-pass--27-october-2026).

## Day-night cycle — 9 November 2026

User request: a 20-minute day (30 minutes since 9 Nov 2026, user) with sunrise, midday, golden sunset and a cool blue night,
keeping the cute, colorful look. Performance comes first. The old daylight is the
baseline, made slightly softer (sun 0.62 → 0.56, ambient 0.50 → 0.54).

| Part | Where |
| --- | --- |
| Cycle length, sun path, keyframe colors, lamp glow, indoor values | `data/day_night.json` (edit this to tune the look) |
| Sun / moon, sky, fog, ambient, lamps, indoor probe and local indoor fill, time API | `scripts/world/day_night.gd` (`Main.day_night`) |
| HUD clock and time panel | `scripts/ui/day_clock.gd` (`Main.day_clock`; phrases `hud.clock_*`; icons `sun`, `moon`, `pause`, `minus`, `plus`) |
| Check / views and frame times | `docs/evidence/day-night-20261109/verify.gd` (`run_checks.py --only day_night`), `capture.gd` |

**How it works.**
- Keyframes (by hour, wrapping at midnight) are blended linearly. 08:00–16:00 is the
  original daylight.
- The single `DirectionalLight3D` follows a sun arc: rising in the east, 53° high around
  noon at the old direction, setting at 18:30. From 19:00 to 05:30 it is a dim blue moon
  (energy 0.16) without shadows. The light is at zero energy at both switch times, so the
  jump in direction is never visible.
- The sun turns in steps of 5 game minutes (`SUN_STEP_MINUTES`). That is about 1°, a jump about
  every 6 s at the 30-minute day. Turning it a little at every refresh (4 times a second)
  re-rendered the shadows from a new angle each time, and shadow edges shimmered (user,
  9 Nov 2026: flicker in the background). Colours, sky and lamps still blend at every refresh.
- A game that holds the player in one view can ask for rarer steps that slide:
  `set_sun_steps(step_minutes, slide_seconds)`, and with no arguments back to normal. The
  mahjong table uses about every 30 s of real time with a 1 s slide (user, 9 Nov 2026), and
  time runs as usual. A clock jump, or the switch between sun and moon, still moves at once.
- The sun is not drawn in the sky (`SKY_MODE_LIGHT_ONLY`). A dim sun's halo darkened the
  sunset sky, and a sky that ignores the light is not re-rendered while the sun moves.
- **Sun disc, moon and clouds (user, 9 Nov 2026: their colours ignored the time and the
  disc did not match the light).** The baked "Sky sun" ball used to sit south-east of town
  while the noon light comes from the north-east. `bind_town()` now takes it out of the
  batched town and places it every frame 150 m from the camera in the light's direction
  (one transform write). By day it follows the sun's arc without the light's 4° floor, so
  it sinks below the horizon at dawn and dusk. At night it is a pale moon where the
  moonlight comes from, faded in and out by the `moon_size` keyframe value. Its colour is
  the `disc` keyframe value (orange at sunrise and sunset, yellow by day). The 32 cloud
  puffs share one unshaded material tinted by the `clouds` value: peach at dawn, pink at
  dusk, blue-grey at night. Neither adds a light or a draw call. Put a node in the group
  `sky_clouds` before `bind_town()` to tint it with the clouds.
- The 19 streetlight heads and the 8 bridge globe lamps get a shared emissive copy of
  their material before batching (2 materials). One write per material turns all of them
  on. `garden_rendering.gd` skips them (`night_glow` meta) so `render_culling.gd` batches
  them with that material. They stay visible to 140 m and cast no shadows. No `OmniLight3D`
  is added.
- **Adding a light:** put any node in the group `night_lights` before
  `DayNight.bind_town()` runs, and its meshes glow with the lamps.
- **Indoors** means a static roof within 30 m overhead and static walls within 40 m on at
  least 3 of 4 sides. It is probed with 5 rays every 0.25 s, so bridges, awnings and
  porches count as outdoors. Indoors, the warm `indoor` ambient fill blends in (in about
  1 s), and the shadowless moon fades so it does not shine through roofs. The sun, its
  shadows and the sky are never changed indoors. (Until the evening of 9 Nov 2026 the light also
  switched to noon indoors. The user saw the street outside the hospital door lit like noon
  under a night sky, so that was removed.) Shops lit by fill look the same at any hour. The
  Home, lit by the sun through its lifted roof by day, is lamp-lit and darker at night.
- **Indoor fill is local (10 Nov 2026).** Until then the fill was the global ambient, so the
  street seen through the hospital door at night was still lit warm and bright like day,
  while the same street looked like night from outside (user screenshots). Now the
  environment always keeps the outdoor ambient, and one `ReflectionProbe` ("Indoor fill",
  `DayNight.room_probe`) carries the warm fill. It uses an ambient colour only, captures
  nothing (cull mask 0), adds no reflection, and is hidden outdoors. Only pixels inside its
  box take the fill. When the player is indoors and outside the current box,
  `_fit_room()` fits the box to the building with rays. It is turned to the nearest wall.
  On each side it runs 0.3 m under the ceiling, so it hits the wall above a door, and
  passes through the inner walls while a roof covers the gap. It stops at the outer wall
  (the box ends 5 cm inside it). Vertically it reaches from the player's floor to the top
  roof. About 150 rays per fit, once per building entered. While the moon is faded, half its
  strength is added to the outdoor ambient, so the street seen from a door matches the street
  itself. Limits: the box is one rectangle, so an L-shaped building's outdoor corner and a
  covered porch can share the fill; lower floors seen down a stairwell keep the outdoor
  ambient; other buildings' interiors seen from the street are not filled. Views:
  `docs/evidence/indoor-fill-20261110/capture.gd`.
- **Cost:** while time runs, everything refreshes 4 times a second and writes only values
  that changed. A paused clock writes nothing except an indoor blend. Night has no sun
  shadows, so it is cheaper than day.
- **Clock:** the cycle starts at `game_clock.gd`'s launch "now", so the airport board and
  the HUD agree at launch. The board keeps that launch time; the HUD clock then runs on
  its own. The time is not saved.
- **Time panel:** − / + move exactly one hour (wrapping at midnight) and pause the cycle.
  Resume restarts it; Close and Esc keep the chosen time.
- **API:** `set_time(minutes)`, `step_hours(n)`, `pause()`, `resume()`,
  `set_cycle_minutes(m)`, `sample(hour)`, `is_night(hour)`, and the `time_changed(minute)`
  and `paused_changed(paused)` signals.

**Web build (9 Nov 2026):** `export_presets.cfg` has a single-threaded **Web** preset (export: `godot --headless --path . --export-release "Web" <folder>/index.html`; serve the folder with any static server). On an M5 in headless Chrome it ran at 58 FPS at noon and 72 at midnight at 2× pixel density, and 132 / 153 at 1×. Since the same day, web builds draw the 3D at the page's CSS pixel size (`render_culling.gd` `apply_web_3d_scale()`: scale = 1 / density, at least 0.5; the HUD stays sharp; desktop unchanged), which gives 125 / 148 FPS at 2× ([record](../FINAL_VERIFICATION.md#web-build-of-the-day-night-cycle--9-november-2026)). Since 12 Nov 2026 the preset is also an installable web app (PWA) and exports scenes as text (see the [README](../../../README.md#web-app-pwa)).

Window glass (12 Nov 2026): one shared, batched glass material, transparent only where a room is
behind, with an opaque fallback setting ([windows guide](../WINDOWS.md)).

Not done: stars (a sky cover texture would add them cheaply); glowing
windows; the cycle length in Settings. Results are in the
[verification record](../FINAL_VERIFICATION.md#day-night-cycle-and-hud-clock--9-november-2026).

## Vegetation audit and proposed phases — 27 October 2026

**Phase 0 only: implementation awaits user approval.** No vegetation, vocabulary,
world snapshot or gameplay changes were made. Preserve existing positions where
possible, all learning content and entrance/vehicle/lagoon clearance. Do not rebake.
The scope is visual variety and vocabulary reference, not new gameplay.

### Ownership audit

“Baked” below means present in `town_public_garden.tscn`, not reconstructed on normal
Main startup. Its `reference_layout_baked` and `home_refined` guards matter.

| Source | Creation/recoloring and current execution |
| --- | --- |
| `scripts/core/main.gd` | `build_tree_cluster`, `build_park_exterior`, `build_neighborhood_exterior`, `build_shrub_row`, `build_exterior_polish`: legacy primitive trees, park/neighborhood/front-yard grass, civic median, shrubs and park borders. These legacy exterior functions do not build the active saved world. `material_for`, `box`, `sphere`, `cylinder` are shared helpers still used by current passes. `build_world` selects the baked branch. |
| `scripts/world/town_builder.gd` | `decorate_home_yard` creates front lawn and hedge shrubs; `tree`, `shrub`, `hedge_strip` provide primitives; shop-front and detail loops add shrubs; `brookhaven_style_pass` adds trimmed storefront hedges; `polish_town_exteriors` adds four outdoor planter foliage clumps. Historical generator, skipped for current snapshot. Yard/street trees were already migrated to scene instances. |
| `scripts/world/town_polish.gd` | `garden_town_and_park` calls `park_tree` twice (trunk, round crown, three foliage lobes); its “shrubs and flowers” loop actually makes flowers, not bushes. `distant_scenery` makes green hills. Skipped for current snapshot; these two primitive park trees are not surviving active trees. |
| `scripts/world/natural_town_layout.gd` | `terrain` creates grassy island terrain and coastal tree candidates; `park` creates Central Park meadow and further trees; `tree` instances `tree.tscn` subject to exclusions. `surface/patch/oval` allocate colored ground materials, including soil/beach/path surfaces which must not all become grass. Historical generator, skipped at startup; helpers remain in use. |
| `scripts/world/home_refinement.gd` | Historical guarded pass deletes hedge shrubs and replaces generic prefab trees cyclically with apple/orange/maple while preserving transforms. Already baked, skipped on current Main branch. |
| `scripts/world/compact_home.gd` | Historical removal/replacement of old front lawn and hedge shrubs; creates `Compact front lawn`. Baked; current `reference_home.gd::build` clears the old Home children, removing this lawn and the old standalone shrub. No replacement lawn is currently built there. |
| `scripts/world/vocabulary_completion.gd` | Historical `outdoors` content creates the generic `Shrub`; maps `Compact front lawn` to `grass`. Baked content, not a new runtime planting pass. |
| `scripts/world/reference_world_layout.gd` | Rebuild functions recreate terrain/meadow and relocate trees and zoo lawns. Current startup uses `bind`; original scene geometry/placements are baked. Its landscape helpers are reused by subsequent runtime passes. |
| `scenes/world/park_zoo.tscn`, `civic_zoo_upgrade.gd` | Prefab owns wildlife/farm lawn meshes/materials. Upgrade instances this prefab when absent; current copy is baked into the saved world, with overrides. |
| `scripts/world/public_garden.gd` | Guarded `build` creates lagoon island ground, formal soil beds, clipped border shrubs, 13 specimen trees, deterministic grove trees and three assembled willows. Already baked, so `build` returns. `refresh_walks_and_boats` runs from refinements and shifts bed/border/flower geometry; `clear_trail_trees` relocates existing grove/specimen trees around refreshed paths. |
| `scenes/world/town_public_garden.tscn` | Active baked terrain/meadow, zoo lawns, old home lawn, 15 species instances, 30 generic `Garden grove/specimen tree` instances, 3 assembled willows, 108 clipped-border shrubs, 14 trimmed hedges, 1 standalone shrub. Includes saved instance material/mesh overrides; editing only a generator or prefab may not change these. |
| `scripts/world/world_refinements.gd` | Runtime `outdoor_materials` recolors terrain, meadow, zoo/farm lawns and path/shore surfaces; `tree_colors` assumes generic `Canopy/Visual` and `CanopyAccent/Visual` paths. `garden_planting` creates soil/ground beds, low shrubs, flowers and accent trees. `compact_coast` adjusts ground and coastal trees; `compact_greenery` relocates trees for compact-layout clearance. All under the existing once-only guard, before batching. |
| `scripts/world/building_exteriors.gd` | Runtime `decorate` → school/café facade routines create two school shrubs and two café shrubs in planters. Preserve facade coordinates and existing exterior-pick exclusions. |
| `scenes/props/nature/{tree,apple_tree,maple_tree,orange_tree}.tscn` | Four existing reusable scenes; colors live in local materials. Generic tree has trunk/canopy picking Areas, **no solid trunk body**. Fruit/maple trees have trunk bodies; fruit trees retain separately selectable apple/orange fruit. All currently teach generic `tree`, not species. |
| `scripts/world/library_market_interiors.gd` | `plant` helper creates planter foliage (six baked lobes in the library, two indoor potted plants); outside this outdoor scope. |
| `tools/build_home_assets.py` | Offline authoring source for apple/orange/maple geometry and colors. Does not run at startup; do not run the broad generator over unrelated assets. |
| `scripts/world/garden_rendering.gd` | Runtime batching hides original garden box/sphere visuals and renders spatial MultiMeshes; preserves word roots/colliders. Only handles `StandardMaterial3D` overrides and groups by cell, color and primitive type. It also installs lagoon water material. No plant recoloring of its own. |

Other consumers: minimap/atlas read geometry/material colors and need a grass-shader
fallback; vehicle physics recognizes ground names. Do not change those semantics.
Historical world snapshots are inputs, not additional vegetation in the live town.
Indoor potted plants, food/fruit displays and green building paint are outside scope.

### Counts: saved source versus current Main

Counts are whole trees/shrub clumps/hedge sections, not mesh lobes or picking Areas.
Baked instances were counted from scene headers and confirmed by instantiated scene
inspection; live counts were checked after Main's construction and batching.

| Source | Baked | Live |
| --- | ---: | ---: |
| Authored `Trees` group (home refinement species replacement) | 5 trees | 5 trees |
| Natural-layout `LandscapeTree` instances, subsequently replaced with species | 10 trees | 10 trees |
| Public garden specimen trees | 13 | 13 |
| Public garden grove trees | 17 | 17 |
| Public garden assembled willows (12 pieces each) | 3 | 3 |
| Runtime `Town planting` accent trees | 0 | 4 |
| **Total trees** | **48** | **52** |
| Public garden clipped borders: six beds × 18 clumps | 108 shrubs | 108 shrubs |
| Vocabulary-completion standalone shrub, removed with old Home | 1 | 0 |
| Runtime planting: seven beds × five clumps | 0 | 35 shrubs |
| Runtime school / café planters | 0 | 2 / 2 shrubs |
| Baked bank/police outdoor planter foliage | 4 clumps | 4 clumps |
| **Total outdoor shrubs/clumps excluding hedge sections** | **113** | **151** |
| Baked trimmed storefront hedge sections | 14 | 14 |

Species breakdown: 5 apple, 5 orange, 5 maple, 30 generic baked trees, 3 assembled
willows; runtime adds 4 generic trees. Thus 34 generic trees in the live world.
The 15 historical species instances comprise 5 under `Trees`, 8 at town root,
1 at Bakery and 1 at Library. Source generation attempts are not surviving counts. The four outdoor bank/police
planter clumps teach `plant` and are included as bush-like outdoor planting.
Some runtime siblings receive Godot-generated `@...` names: counting name prefixes
alone undercounts them. Seven live beds supersede the old handoff's six-bed claim
for this run; they also contain 84 flower lobes, excluded from shrub counts.

There are five current lawn/grass meshes: `Natural town terrain`, `Central Park
meadow`, the two ParkZoo lawns and `PublicGarden/Lagoon island`. The saved Home lawn
is a sixth baked mesh but is removed at runtime. Formal/perennial bed soil, beach,
shoreline, paths and playground surfacing should retain their distinct materials.

### Proposed implementation, awaiting approval

**Grass:** one shared opaque, rough grass ShaderMaterial, assigned once by an
explicit surface selection in the existing final refinement pass after layout
work and before batching. Use world-position XZ sampling of a small seamless noise
texture, with two gentle scales and restrained green variation. This avoids costly
per-fragment procedural octaves and works with GL Compatibility. No wind, grass
carpet geometry or new lighting changes. Start without optional grass clumps.
Keep map color fallback explicit. Do not globally replace every green material or
convert bed soil to lawn. Remove the competing runtime grass color assignments;
legacy generator defaults can remain because this final pass owns live appearance.

**Trees:** eight ornamental species plus the retained apple and orange trees
(ten recognizable types overall). Separate scenes under `scenes/props/nature/`:

| Canonical key | Spanish | Shape and suggested zone |
| --- | --- | --- |
| oak | el roble | Broad irregular rounded crown; park groups |
| pine | el pino | Soft tiered evergreen silhouette; exposed edges/shore backline |
| palm | la palmera | Curved trunk, distinct simple fronds; sparse warm shoreline accents |
| birch | el abedul | Pale trunk, light crown; park/path-side clusters |
| weeping willow | el sauce llorón | Drooping foliage; replace the three existing waterside assemblies |
| cherry tree | el cerezo | Restrained pink blossom crown; selected park/frontage focal points |
| cypress | el ciprés | Narrow rounded upright silhouette; formal planting/roadside pockets |
| maple | el arce | Upgrade existing maple, warm green/ochre variation; park/frontages |
| apple tree | el manzano | Retain existing five trees and selectable fruit |
| orange tree | el naranjo | Retain existing five trees and selectable fruit |

Use `cherry tree`, not `cherry blossom`, for the whole-tree word; blossom is a
separate concept. Keep generic `tree` discoverable on a retained generic specimen
or a deliberately separate trunk study target, without overlapping species picks.
Retain fruit `apple`/`orange` targets and generic trunk learning on fruit trees as
appropriate. Implement two or three deterministic profiles per species with
exported size/palette/lean controls, shared palette resources and bounded variation.
One solid trunk collider per tree, separate picking Area(s); transform geometry,
trunk collision and pick bounds together. New solid trunks must be tested because
the current generic garden prefab has only Areas.

Replace at final **runtime** positions after compact layout, in the existing
refinement lifecycle, before batching. Preserve root names and reference metadata;
replace old visual/pick/body children deliberately to avoid duplicate collision.
Do not assume new species contain the old canopy node paths: retire the generic
`tree_colors` override for replaced trees. Convert the assembled willow pieces as
three trees without leaving old foliage behind. Keep tree count near 52 initially.

Use low-segment sphere/box foliage with shared StandardMaterial3D palettes wherever
possible so the existing garden batcher continues to work. Cypress/pine silhouettes
can use tapered arrangements of rounded lobes; palm fronds need a small mesh budget.
Only make a narrow batcher extension if measured necessary; do not trade distinctive
species for hundreds of individually drawn parts or unlimited tint permutations.

**Bushes:** four scenes: `shrub` → **el arbusto**, `hedge` → **el cerco vivo / el seto**
(preserve existing accepted translation), `rose bush` → **el rosal**, `fern` →
**el helecho**. A fern should actually have fronds, not teach fern on a grass tuft.
Use varied rounded shrub lobes, tidy but softened hedge sections, small rose accents
and simple fern fronds. No movement collision; separate compact selection Areas
still make the new words learnable. Preserve generic `flower` access separately.

| Zone | Placement proposal |
| --- | --- |
| Park | Replace generic trees with loose oak/maple/birch groups and a few cherry focal points; irregular height/spacing within current anchors. Rework existing clipped borders and seven perennial beds before adding more objects. |
| Pond | Replace existing three willows in place; low fern/shrub groups behind walk edges. Keep lagoon polygon, bridge, landing and boat access open; no new trees in water. |
| Roadsides | Narrow cypress and lighter birch/maple at existing tree positions; low shrubs at corners only outside sightlines and vehicle envelopes. Preserve sidewalks and all entrances. |
| Shoreline | Sparse palm/pine accents at existing coastal anchors; low shrubs/ferns only in appropriate sheltered/moist pockets. Retain open beach and island silhouette. |
| Building foundations | Reuse 14 hedge sections and school/café planters, then add small asymmetric shrub/rose groups at blank facade ends. Keep doors, glazing, signs, parking and airport areas clear. No interior changes. |

Replace existing shrubs first; provisional additional planting cap is 24 small
clumps across foundations, path margins and sheltered shore pockets, reduced if
visual review or performance requires it. Avoid uniform rings around every tree.
Check canopy/lean envelopes, not just trunk centers; evaluate positions in final
+X-west/+Z-north town space with explicit 1.3-scale world conversions.

**Vocabulary procedure:** searches found no existing species/rose-bush/fern canonical
keys or aliases. Existing `tree`, `shrub`, `hedge`, `grass`, `flower`, `apple` and
`orange` must remain. Add the ten specific tree keys and two new bush keys with
Nature categories, matching relevant catalog records/sizes, root `word_key` and
consistent cached Spanish/English/category tags. Do not create redundant `bush`
or `lawn` synonyms. Existing aliases remain unchanged unless a real legacy synonym
needs normalization. Preserve saves and mission IDs. Verify actual cards/picking,
category and translation checks, and alias normalization; report existing failures
by label instead of editing away unrelated stale metadata.

**Phase gates:** grass → trees → bushes; each phase gets a fresh isolated copy,
resource/rendering/garden/Part 2 checks, vocabulary/picking checks when applicable,
fixed-camera before/after images inspected at walking and overview scales, and
repeat graphical benchmarks. Compare cumulative final cost with Phase 0, not +2 ms
per phase. Keep exact camera/resolution/renderer/warm-up/sample settings. Use paired
baseline/changed runs when host variability is large. No rebake, branch change or
commit without the user's explicit authorization; one reviewed commit per phase.

Evidence and current measurements are recorded in the dated
[verification entry](../FINAL_VERIFICATION.md#vegetation-phase-0--27-october-2026).
Fixed cameras: [capture script](../../evidence/vegetation-20261027/capture.gd).

## Shared grass material — Phase 1, 27 October 2026

`world_refinements.gd::grass_surfaces()` is now the sole final runtime owner of
lawn appearance. It runs after `compact_town()` and before UI/garden batching,
assigning the same `shaders/grass.tres` ShaderMaterial to island terrain, Central
Park meadow, both ParkZoo lawns and the lagoon island. The old four runtime green
color overrides were removed. Historical generator colors remain fallback source
values; saved scene overrides are superseded at runtime without rebaking.

`shaders/grass.gdshader` uses world XZ coordinates and two samples of one shared
256×256 seamless, mipmapped noise texture. FastNoiseLite generates that texture
once; it is not evaluated per fragment. The base color is `78965f`, with modest
broad/fine brightness modulation, full roughness and low specular response. There
is no animation, transparency, displacement, blade geometry or added collision.
The shader uses GL Compatibility-supported spatial shader features.

Each grass mesh carries `map_color` from the material's base color. The existing
minimap/atlas surface reader uses that fallback for shader surfaces, retaining the
water fallback otherwise. Garden batching still handles the same 1,986 decorative
meshes in 196 batches; these five grass surfaces draw individually as before.
The rendering check now verifies shared assignment, visibility after batching,
green map fallback and preservation of the beach material.

The Phase 0 source inventory/proposal above is historical planning context; this
section supersedes its grass implementation status only. Trees, bushes, vocabulary,
lighting, geometry and saved-world content are unchanged in Phase 1. Restart Main
to see the material; never clear the refinement guard on an already modified tree.
Phase 1 measurements and rendered evidence belong in the dated verification entry.

## Tree species — Phase 2, 27 October 2026

`world_refinements.gd::tree_species()` runs after `compact_town()` and before
`grass_surfaces()`/garden batching. It replaces, at their final positions and
keeping root names:

| Source | Becomes |
| --- | --- |
| 34 generic `tree.tscn` garden trees (specimen, grove, `Town planting` accent) | by zone: within 5 units of the lagoon → cherry tree; east edge (x > 60) → pine; south road edge (z > 185) → cypress; west (x < −45) → oak; otherwise birch/oak/maple in turn |
| 5 old `maple_tree.tscn` instances | coastal anchors (z < 35 or z > 280) → palm tree; others → new maple |
| 3 assembled willows (trunk, crown, ten hanging pieces each) | one weeping willow each |
| 5 apple / 5 orange trees | kept; root `word_key` set to `apple tree` / `orange tree` |

Live total stays at 52 trees: 10 oak, 7 maple, 5 birch, 5 pine, 5 cypress, 4 cherry
tree, 3 palm tree, 3 weeping willow, 5 apple tree, 5 orange tree. Heights follow the
replaced tree (with per-species factors) and yaw uses a golden-angle step.

Species scenes live in `scenes/props/nature/species/`; all share
`scripts/objects/tree_species.gd` (`@tool`, so the editor previews them). The
`profile` export (0–2) varies proportions, palette and lean. Geometry is built in
`_ready` and never saved. Foliage is unit `SphereMesh`/`BoxMesh` with cached shared
`StandardMaterial3D` overrides, so garden trees batch with the existing
`garden_rendering.gd`; trunks and branches are 8-sided cylinders drawn directly.
Each tree has one `Trunk` node (`word_key` `tree`) holding one solid
`StaticBody3D` cylinder, and a root `StudyArea` box at 85% of the crown bounds
teaching the species word. The old `maple_tree.tscn` and generic `tree.tscn` stay
because saved scenes and older generators still reference them; `tree_colors()`
was removed because every tree it recolored is now replaced.

To retune: species shapes and palettes are in `tree_species.gd`; zone rules and
height factors are in `tree_species()`. Preview with
`docs/evidence/vegetation-20261027/phase2/lineup.gd`; check with `phase2/verify.gd`.

## Bushes — Phase 3, 27 October 2026

`world_refinements.gd::bush_species()` runs right after `tree_species()`, before
garden batching. It refits existing clumps in place, then adds a capped number of
new groups:

| Source | Becomes |
| --- | --- |
| 108 `Garden clipped border` shrubs around the statue beds | tidy clipped shrub (profile 1), fitted to the old bounds so the separate flower lobes still sit on top |
| 35 `Town planting` bed clumps (`63894f` spheres, five per bed) | rose bush / shrub / fern, rotated per bed; 3 clumps that sat inside statue-border shrubs (one bed overlapped a border) are removed |
| 14 `Trimmed hedge` strips at shop/civic entrances | hedge sections of the same length and line, 0.8 tall; cached `english`/`spanish`/`category` tags are copied |
| School and café planter shrubs under `Map facades` | clipped shrub with its `StudyArea` removed: the facade's `exterior_word` would win the pick, and the facade code keeps that planting out of vocabulary |
| Additions (`PublicGarden/Garden bush groups`, cap `BUSH_ADDITIONS` = 16, plan cap 24) | ferns 4–5 units outside each willow; shrub/rose groups 3.6–4.4 units beside walks; all at least 3 units from any walk centerline, outside the lagoon and 2.2 units from trunks |

Live result: 132 shrubs, 17 rose bushes, 11 ferns, 14 hedges (174 bushes, 170
pickable). Bushes share `scripts/objects/bush_species.gd` (`@tool`, `profile`
0–2, hedge `length`) and scenes in `scenes/props/nature/species/`. They reuse
`tree_species.gd`'s cached `shared_material()` and `unit_sphere()`. Each has a
root `StudyArea` and no movement collision.

**Batch budget.** `garden_rendering.gd` makes one MultiMesh per color per 24-unit
cell, so every extra foliage tint adds batches across the park. Garden batches went
196 (grass phase) → 245 (trees) → 316 (bushes) after cutting the bush palette from
about 30 tints to 11 shared ones. Measured cost stayed small (benchmark below), so
the user approved raising `check_rendering.gd`'s bound from 250 to 400 rather than
changing how the batcher groups colors. Keep new plant tints inside the existing
shared greens; if the bound is reached again, the next step is per-instance colors
in the batcher, verified with before/after renders.

### Foundation planting — 27 October 2026

`FOUNDATION_PLANTING` in `world_refinements.gd` adds six single clumps (alternating
rose bush/shrub) under `Foundation planting` at the blank front-wall ends of the
school, hospital and supermarket. Spots were measured by probing from each
entrance-hedge pair to the main roof (height > 4.5, so entrance canopies are not
mistaken for walls), then keeping only grass 1.0 out from the wall and about 2.0 in
from the corner. Library, bank and police fronts are 12.5 wide with their hedges
already at the corners, so they get none. Together with the 16 garden additions
this uses 22 of the plan's 24 clumps. These six are outside `PublicGarden`, so they
are drawn unbatched (36 extra draw calls). Views:
`docs/evidence/vegetation-20261027/phase3/capture_foundations.gd`.

## Interactive grass trial — 27 October 2026

> **Removed 28 October 2026.** Historical record only; see
> [grass clumps removed](#grass-clumps-removed--28-october-2026).

The user authorized trying nearby opaque grass clumps with local player bending.
`Main._ready()` constructs `park_grass.gd` after the player and garden batches are
ready, and skips this pass for editing snapshots. The trial covers three circles
around town-local (22,115), (20,165), and (-58,151), not the entire town.

The deterministic placement creates 1,698 clumps in 25 eight-unit MultiMesh cells.
Each clump has five tapered blades / 15 triangles (25,470 authored triangles total).
Paths have at least 2.5 units of centerline clearance; pond/flat occupied pads and
nearby tree, bench and planting-bed centers are excluded. Roots use the current
park height function. No collision, vocabulary, save or movement changes.

`shaders/park_grass.gdshader` is opaque, double-sided and Compatibility-compatible.
There is no wind or grass shadow pass. Roots remain fixed; tips bend outward up to
0.22 world metres within a 1.1-metre player radius, with smooth spatial falloff and
a vertical separation gate (zero effect at a one-metre height difference).
Grass returns immediately according to distance; there is no persistent trail.

The shader shrinks randomized clumps through distance bands ending at 24–32 world
metres from the active camera, retaining the existing grass ground shader beyond.
Every 0.2 seconds the controller also hides distant cells to remove their actual
GPU work. Bounds include blade height and bend displacement. Shader shrinking
alone does not save vertex work on a visible cell. The MultiMeshes are already
batched and are not passed through the primitive garden batching helper.

Tuning lives on the runtime `PublicGarden/Park grass trial` node (Remote inspector)
and in the script's exported defaults: `grass_enabled`, `density`, `draw_distance`,
`bend_radius`, and `bending_enabled`. Setting `grass_enabled=false` hides all grass;
reducing density hides clumps in the shader but does not shrink the allocated
buffers. For lower GPU cost reduce draw distance or disable the trial.

Verification: `docs/check_park_grass.gd`. Repeat the graphical comparison in an
isolated project with `--script res://docs/guides/performance/grass_trial.gd --
--output=/absolute/output/folder`; it measures off/static/bending in two camera
views and saves screenshots (defaults to `user://grass-trial`). The benchmark is a
short local comparison, not a guaranteed hardware budget. See the dated entry in
`FINAL_VERIFICATION.md` for measurements and limitations.

## Lawn texture and park-wide static grass — 27 October 2026

> The static grass half of this entry was **removed on 28 October 2026**; the lawn
> texture stays. See [grass clumps removed](#grass-clumps-removed--28-october-2026).

The user wanted visible grass texture without motion and with modest cost. Two parts:

- **Lawn texture.** `shaders/grass.gdshader` (shared by every lawn mesh, including
  the rolling park ground) now mixes `lush_color` and `dry_color` in broad patches,
  adds mid-scale clumping and a fine blade grain built from two rotated, stretched
  samples of the same noise texture. The grain fades between `grain_fade_start` and
  `grain_fade_end` (6–38 m) so it does not shimmer at a distance. Still opaque, one
  texture, no animation.
- **Static park grass.** `park_grass.gd` now covers the whole park lawn (`PARK`
  rect, matching `park_terrain.gd`) instead of three trial circles: 28,480 short
  clumps (scale 0.5–0.85) on a jittered 0.5-unit grid in 254 eight-unit cells. It
  skips the lagoon, the five activity pads, the statue plaza, 2.5 units around
  walks and 1.5 around trees, benches, beds and shrubs; those are rasterised once
  into a mask, and terrain height is cached on a 1-unit grid, so placement stays
  fast. `bending_enabled` defaults to **false** (the bending code remains). The
  shader keeps full density within `full_density_distance` (10 m) and thins to
  `far_density` (35%) at `draw_distance`; cells beyond `draw_distance`+9 are hidden.
  The node is still named `Park grass trial`. Town lawns outside the park get the
  texture only.

Cost (Apple M5, 1280×720, two paired runs): standing in the park +0.6 ms median
(17.04/17.35 → 17.74/17.95 ms, +37k primitives, +16 draw calls); town benchmark view
+0.1 ms; Main load about +0.3 s. Views: `docs/evidence/grass-20261027/before` and `after`.

## Grass clumps removed — 28 October 2026

The user kept the lawn texture but asked to remove the standing grass clumps
(originally Codex's trial, later extended park-wide) to free up the park. Removed:
`scripts/world/park_grass.gd`, `shaders/park_grass.gdshader`, their `.uid` files,
the `Main._ready()` call, `docs/check_park_grass.gd` and the trial benchmark
`docs/guides/performance/grass_trial.gd`. The `PublicGarden/Park grass trial` node no longer
exists. Lawns, including the rolling park ground, keep `shaders/grass.tres`
(`grass.gdshader`) unchanged. This reverses the +37k primitives / +16 draw calls and
roughly 0.3 s of Main load measured for the park-wide clumps. The dated
`docs/evidence/grass-20261027` screenshots remain as history.

## Road and sidewalk textures — 28 October 2026

`shaders/road.gdshader` (road, driveways, parking pads) and `shaders/paving.gdshader`
(sidewalks, curbs, walks) are opaque, static and Compatibility-friendly: one 256²
noise texture each, three/two samples per fragment, grain faded with distance. They
replace StandardMaterial3D on a handful of large meshes, so draw calls are unchanged;
materials are shared per colour (`world_refinements.gd::surface_material`).

## Town-wide render trim — 29 October 2026

`scripts/world/render_culling.gd` runs once at the end of `Main._ready()`, after
garden batching; the scene files are not changed. It owns:

- Sun shadows: max distance 50, two cascades instead of the default four.
- Segment budgets for script-built `SphereMesh`/`CylinderMesh` (Godot's default is 64
  segments): 16 to 32 by world radius, never raised; shared meshes use their largest
  use. Vehicles, animals and characters keep their own.
- Visibility ranges: props under 1 m hide past 60 m (no sun shadow); 1 to 3 m props in
  Buildings, RelocatedSites, Restaurants and Airport past 70 m; other props under 10 m
  once below about 1/60 rad. Moving objects (vehicles, animals, characters, anything
  processing) are sized as a whole object: parts at least 30 % of its size stay to
  100× its size, smaller details hide at 40 % of that. Plush characters hide past 45 m.
- Static batching (`Apartment/StaticRenderBatches`): remaining visible static meshes
  become MultiMeshes per 24 m cell (smaller for ranged groups), material, mesh, shadow
  and range setting, and set of omni/spot lights reaching them. Boxes, spheres and
  straight cylinders share unit meshes. Doors, swivel seats, the Home roof,
  processing nodes and vehicle/animal/character scenes are never merged.
  Originals are hidden and tagged `render_batched`. The minimap still reads them, and
  `interaction_controller.highlight_object` shows a tagged original while it is
  highlighted, so hover outlines work on merged word objects. The same tag is now set
  by `garden_rendering.gd`, so garden flowers, whose meshes were already batched,
  should get hover outlines back. That was not tested on its own.

**Interior lights.** The Compatibility renderer draws at most 32 omni/spot lights per
frame by default (`rendering/limits/opengl/max_renderable_lights`), and the town has
124. Before this pass some interior lights were dropped: the school and supermarket
interiors rendered differently at 32 and 256. With merging, they render the same at
either cap, and match the unmerged town at 256, so the ceiling hotspots that appeared
are authored lights that were previously missing. On 31 October 2026 `project.godot`
raised the cap to 256 so views not yet compared cannot drop lights either. Five
exterior views and both interiors showed no measurable frame-time change (two
alternating runs per cap, in the verification record).

Measurements, checks and rendered comparisons are in the
[verification record](../FINAL_VERIFICATION.md#2026-10-29-render-trim-phase-2-segments-ranges-static-batching).

## Graphics tiers: Low default, High kept — 14 November 2026

User decision (14 Nov 2026, mobile playability): the game was very slow on an iPhone
(Safari / installed PWA). **Low is the default everywhere** (web and Mac); the look of before is
kept as **High**, picked in Settings ("Graphics quality": Low (faster) / High). The choice is
saved with the other settings (`GameSettings.graphics`, `"low"`/`"high"` in the profile's
`settings.json`) and applied at once, without a restart, by
`render_culling.gd` `apply_graphics()` (at the end of `build()`, again on
`GameSettings.graphics_changed`, and to each unit added later by `add_parts()`).

| | High (the look of before) | Low (default) |
| --- | --- | --- |
| Sun shadows | on by day (2 cascades, 50 m) | off (`day_night.gd` `sun_shadows`) |
| View distance | camera far 4,000 m, faint exponential haze | camera far `LOW_VIEW_DISTANCE` 130 m; depth fog from 40 % of it, opaque at it (fog colour follows the time of day); the sun/moon disc floats at most 80 % of it away |
| Short visibility ranges (High ≤ `LOW_SHORT_RANGE` 80 m: small props, details, plush characters) | as in the render trim above | × `LOW_RANGE_SHARE` 0.45, never under 20 m (props 60 → 27 m, plush 45 → 20 m) |
| Longer ranges (building parts sized by 60× their size) | as above | unchanged; the far plane and fog cut them (shortening them made a church tower vanish under its spire) |
| Heavy single meshes (≥ 30k triangles: the clay zoo animals, 60k–300k each) | no extra range | hidden beyond 40 m |
| MSAA / screen-space AA / TAA | project values (all off today) | off |
| Web 3D resolution | CSS pixel size, never under 0.5 of the screen | 0.8 of the CSS pixel size, never under 0.25 (an iPhone at 3× renders 0.27) |

Each range's High value is kept on the node as meta `high_range`, so switching back restores it
exactly. Omni-light reach was not changed (optional in the brief; interiors depend on it).

**Perf readout** (`scripts/ui/perf_readout.gd`): fps, average and slowest frame time, draw calls,
triangles, the tier and the 3D scale, top left. On with `?perf=1` in the page address (web), F3,
or the Settings checkbox "Show FPS" (the installed PWA has no address bar). Not saved.

**Measured** (native Mac M5, 1280×800, full town, noon, clock paused, player camera; same probe
for both tiers; frame times on a Mac say little about a phone, draw calls and triangles carry over).
Session B's indoor hiding (`indoor_visibility.gd`) was already in the checkout for both runs,
so indoor views are lower than the plan's baseline for both tiers.

| view | High draws / triangles | Low draws / triangles |
| --- | ---: | ---: |
| street outside the supermarket (spawn) | 1,392 / 1.81 M | **585 / 0.71 M** |
| same spot, looking back over the zoo and park | 5,841 / 3.31 M | 1,209 / 0.80 M |
| home guest suite, facing the window | 297 / 0.16 M | 123 / 0.07 M |
| home guest suite, facing the house | 5,169 / 3.61 M | 1,947 / 0.91 M |
| supermarket interior | 889 / 0.58 M | 570 / 0.43 M |

Before session B's hiding landed (same day, same probe, High): street 1,509, looking back 6,065,
park overview from the benchmark camera 4,290 draws; a first Low (160 m, every range × 0.6) gave
950, 1,375 and 1,764. A sweep of view distance (160/130/110 m) × range share (0.6/0.45/0.35) chose
130 m and 0.45: 0.35 hid props 21 m away. **Not measured:** an iPhone (the user can now read
`?perf=1`), and fill-rate effect of the lower web 3D scale. Rendered views were inspected in the
[verification record](../FINAL_VERIFICATION.md#graphics-tiers-low-default-high-kept--14-november-2026).

## GPU memory on the web — 14 November 2026

User report (14 Nov 2026): on a phone the browser stopped the game with "WebGL context lost,
please reload the page". The user chose **reduce + recover**: lower what fills GPU memory on the
web, and come back to the same spot when it happens anyway (README "Web app (PWA)",
`scripts/core/web_resume.gd`).

**Measured** natively (M5, compatibility renderer, the same GLES3 driver as WebGL 2), full town,
Low, 1280×800, with a scratch probe reading `RenderingServer.get_rendering_info()` and every
mesh surface's byte size (`RenderingServer.mesh_get_surface()`):

| what | MB |
| --- | ---: |
| video memory, empty scene → full town | 14 → **392** |
| textures | 102 (font glyph atlases 65, the 4 icon/tile SubViewports ≈ 9, material textures ≈ 7) |
| buffers | 290 (meshes 224: plush characters 116, clay zoo animals 50, buildings and the rest 54) |

Shadow atlas size and the 3D scale barely show in these numbers: Low has no sun shadows, no other
light casts shadows, and render targets are small (3D scale 0.5 saved 6 MB at 1280×800).
Texture compression does not matter: the only imported textures are 21 small UI images.

**Changed:** each font size + outline pair a Label3D uses gets its own glyph atlas (0.5–2 MB);
the town's 765 labels used 87 pairs. On the web, `render_culling.gd` `share_label_sizes()` moves
each label up to the next of 24/32/48/64/96/128 (pixel size scaled so the text keeps its size in
the world, outline rounded to 2) and frees the atlases no label uses any more:
**87 → 34 pairs, glyph atlases 65 → 43 MB, textures 102 → 84 MB, video memory 392 → 373 MB**
(the probe forced the web-only step natively). Desktop builds are unchanged. The readout
(`?perf=1`, F3) now shows "GPU … MB" so a phone can be read directly.

**Not changed, measured for later** (in order of size):
- Plush characters, 116 MB: each sculpts its own meshes (a beagle's torso 2.1 MB, again for every
  beagle). A web-only lower sculpt resolution, or sharing one mesh between identical characters,
  would cut the most.
- 29 MB of meshes are byte-identical copies (12,922 meshes, 7,993 different; mostly Mystery House
  trim). Sharing them is safe only after checking the code that edits meshes in place (costumes,
  sculpt cache, supermarket products, ground cut).
- Clay zoo animals, 50 MB (60k–300k triangles each).
- The whole town is in memory at once; loading only nearby buildings on phones would be the big
  step and is a design decision.
- The sun's shadow map (4096², about 64 MB) exists only on High with shadows; a `.web` override of
  `rendering/lights_and_shadows/directional_shadow/size` would shrink it if phones pick High.

## Indoor visibility: hide far, keep near — 14 November 2026

User decision (14 Nov 2026, mobile playability): inside a building, draw only that building, its
yard and the street right outside, so windows still show something real; other buildings and the
far town are hidden until the player steps out, with no visible change at the door.
`scripts/world/indoor_visibility.gd` (one node, created by `main.gd` right after the render trim)
owns it; its header lists the constants.

- **What it hides: whole objects.** An object is a building unit part (`data/buildings.json`;
  the moving `People/*` parts are skipped) or a base-world node of at most 60 m: a top-level
  child of the town, else a child or grandchild found by splitting a bigger one (up to three
  levels; deeper or bigger nodes are never hidden). Animals and vehicles are judged by their
  position (± 8 m), again every check. Static batches (`StaticRenderBatches` and its
  `Unit_<key>` containers, the garden's `RenderBatches`) hold pieces of many objects, so each
  merged original is matched to its batch instance (material, mesh, position) and links its
  object to that batch. Objects whose box reaches the keep box (the player's building plus
  `KEEP_MARGIN` 22 m, XZ) stay, and so does everything linked to them, transitively: a kept
  object never loses a batched piece (a tree its canopy, a bridge its towers, a building a
  wall) and a hidden one leaves none behind. Batches with a piece no object owns are never
  hidden. Only `visible` changes, only on nodes visible at setup (merged originals are never
  shown); collision, word areas, doors and the minimap are unchanged. About 3,400 objects, 50
  movers, 4,050 batches (250 never hidden); measuring them takes about 2.6 s of frames after
  loading (1.5 ms per frame), and nothing hides before that. The slowest single toggle (the
  whole home site) took 0.6 ms; changes are spread over frames (2 ms per frame hiding, 8 ms
  revealing).
- **Fixed the same day (graphics-tiers session's report):** the first version hid batches by
  their own box and covered only a few base roots, so from a free camera the park showed bare
  trunks (canopies hidden, trunks not) and bridges without towers; at the kept area's edge a
  building could likewise have lost a batched wall. The links above replace that.
- **When.** Four times a second: five rays (roof overhead, walls on 3 of 4 sides, as
  `day_night.gd`) and the smallest unit-part box around the player that rises above its head.
  Hiding waits for two indoor checks in a row (after entering). Everything is drawn again within
  4 m of a door that leads outside (doors in `Main.doors`, shower curtains skipped; "outside" =
  a spot beside the door with no roof, found once per door) or when an entrance is in reach:
  a clear ray at 0.6 m (under window sills; glass panes have no collision) that leaves the
  building's box within 8 m, or reaches a roofless spot within 2/4/6 m. Shop entrances are
  doorless openings under a canopy with its own roof collider, so the box exit is what finds
  them: the town comes back about 4–5 m inside the supermarket and library entrances. Driving,
  noclip and buildings outside the unit registry never hide anything.
- **Staged loading.** Part boxes are measured over the first frames (1.5 ms per frame), again
  for a unit added later (`Main.unit_added`), whose batch container is picked up then too.

**Measured** (native Mac M5, 1280×800, full town, player camera, component switched off and on
at the same spot in one run; other mobile sessions' uncommitted edits were in the tree):

| view | Low: off → on (draws / triangles) | High: off → on |
| --- | ---: | ---: |
| street at spawn (reference, not hidden) | 585 / 0.71 M | 1,350 / 1.81 M |
| home guest-suite bedroom (tutorial start), local [-4.4, 0, -9.6] | 2,045 / 1.00 M → **1,389 / 0.30 M** | 7,956 / 4.19 M → **3,696 / 1.39 M** |
| supermarket interior, local [-33, 0, 42] | 521 → 516 / 0.41 M | 796 → 791 / 0.56 M |
| library interior, local [-15, 0, 44] | 392 → 392 / 0.37 M | 1,029 → 957 / 0.93 M |
| *after the whole-object fix (Low only):* bedroom | 2,047 / 1.00 M → **1,465 / 0.43 M** | not measured |
| *after the fix:* supermarket / library | 521 → 504 / 392 → 390 | not measured |

The supermarket and library were already at or below the street figure: their walls face the
town and Low's 130 m view distance cuts the rest. The home bedroom is not (1,389 on Low): what is
left is the home itself, seen from above while the Home roof is lifted. In that view the
mahjong table alone gave about 350 unbatched surfaces and each door frame about 35 (unbatched:
doors); batching them is a follow-up, not part of this pass. Rendered views (supermarket door
from outside, inside looking out, doorway from inside, the street after stepping out, the bedroom
windows, the library looking out) are described in the
[verification record](../FINAL_VERIFICATION.md#indoor-visibility-hide-far-keep-near--14-november-2026).
**Not measured:** an iPhone; long-shadow loss on High (hidden buildings beyond 22 m stop casting
sun shadows into the yard while the player is inside).
