# Expanded Public Garden

**Current monument layout and terrain:** [4 November photographic revision](#boston-inspired-garden--4-november-2026), with the [5 November monument refinement](#washington-monument-refinement--5-november-2026) superseding its bushes, beds and fountain design and the [5 November trail cleanup](#monument-trail-cleanup--5-november-2026) superseding its trail network. Earlier dated layouts below are historical.

*Historical (until 6 Nov 2026):* the main scene then opened `scenes/world/town_public_garden.tscn`, an editable snapshot; it was deleted when the [modular town](../MODULAR_TOWN.md) (`scenes/town/base.scn`) replaced it. The original `town_reference.tscn` and its buildings remain available. All work stays in the existing low-poly style; no downloaded assets are required.

The lagoon has a larger irregular southern basin, a narrow bridge crossing, a smaller northern basin, and a wooded island. The pale arched pedestrian bridge has granite piers/towers, globe lamps, suspension sweeps, diamond lattice railings, a continuous collision deck, and side barriers. Its ends meet the ground without steps. A shoreline loop joins the statue promenade, northern wildlife and playground district, southern library district, gazebo, chapel, and existing neighborhood paths.

The Washington figure and pedestal are retained and augmented with a bronze horse and riding pose. Formal flower beds, willow trees, specimen groves, and benches frame the central garden. The fountain has been removed. Shoreline stones, fish, and turtle are retained and repositioned. The supplied illustration includes swan boats, but the original project snapshot contains no boat geometry; two low-poly green/red/white swan boats and a landing were added. Clicking a hull teaches **boat / el barco**.

The playground moved 10 local units north to clear the northern lagoon loop. Existing zoo, farm, buildings, doors, vehicles, interiors, quests, and vocabulary retain their content. Washington's pedestal is bypassed by a curved promenade rather than obstructing the route. The zoo connection meets the existing gate, operated with E.

Current runtime changes after this saved snapshot are described in the
[Part 2 handoff](../../evidence/part2/HANDOFF.md). See [final verification](../FINAL_VERIFICATION.md)
for current results; the validation counts below are historical.

## Editing and regenerating

The **23 October compact layout** supersedes the northern zoo/southern library
placement described in this saved-snapshot history. Both landmark loops and the
bridge remain intact; runtime destination branches follow the relocated habitats
and buildings. See the [current ownership and coordinate rules](../ARCHITECTURE_REVIEW_PART1.md#coordinates-roads-and-visual-standards)
and [verification](../FINAL_VERIFICATION.md#compact-town-redesign--23-october-2026).

### Central trails matched to blueprint — 22 October 2026

`public_garden.gd::refresh_walks_and_boats()` now authors the runtime trail
centerlines explicitly instead of retaining the saved snapshot's older routes.
The supplied map is interpreted around the existing buildings and lagoon:
one broad statue oval (31 × 27 town-local radii), the retained lagoon loop,
west-to-bridge promenade, zoo/playground branches, northern approach between the
zoo and playground, southern connections beside the farm/library, and the eastern
chapel/gazebo walk. Northern and southern trails meet the inner main-road sidewalk;
the obsolete extensions across that road and redundant statue routes are removed.
The monument's smaller solid plaza remains accessible from both sides.

Route coordinates are canonical (+X east); `world_point()` reflects them once
into the active town. `walking_paths` and `walking_path_names` describe the same
curves used to draw the ribbons. Main walks are 3.6 units wide, branches 2.7;
existing layered sand/limestone surfaces are reused. Nearby existing grove trees
and six flower beds move out of the new walks, retaining their nodes and picking.
Buildings, road geometry, lagoon, bridge, furniture, animal habitats and entrances
retain their existing positions. No saved world is rebaked. The existing
`walks_boats_refreshed` guard still requires a fresh Main scene to preview edits.

[North-up rendered layout](blueprint-trails.png) and
[bridge junction view](blueprint-trails-bridge.png) show the runtime result.
`docs/evidence/town-checks/render_public_garden.gd` now also captures the full central district.
See [final verification](../FINAL_VERIFICATION.md#central-trail-blueprint-follow-up--22-october-2026)
for the baseline, current checks and limitations.

### Runtime trail and swan refresh — 21 October 2026

The saved [town blueprint](../design-references/town-map-blueprint.png) remains the park layout
reference. `public_garden.gd::refresh_walks_and_boats()` runs from world refinements
before planting and batching. It replaces saved walking ribbons with sand-colored
surfaces and layered limestone edges: main loops/promenades are 3.6 town units
wide and secondary connections 2.7. At that date, the existing curved routes, statue oval,
lagoon loop, bridge approaches and landmark connections remain in place, along
with the matching `walking_paths` validation data. The 22 October section above
supersedes that centerline layout.

The user's [swan boat photograph](swan-boat-reference.png) is saved here for future
development. Both boats now have a 9.4-unit long green hull, five wooden slat
benches, red rails, feathered wings and a continuous tapered curved neck. Hulls
retain the existing boat vocabulary selection and the landing is unchanged.
The refresh is guarded by `walks_boats_refreshed`; restart Main to see changes.
Do not clear the guard or rebake the world to preview this pass.

The bake instructions below describe the underlying saved snapshot, not the
runtime refresh above. Current validation is in [Final verification](../FINAL_VERIFICATION.md).

Open `scenes/main.tscn` to play, or `scenes/world/town_public_garden.tscn` to edit. New landscaping and bridge geometry are grouped under `PublicGarden`. Existing pond props remain under `RelocatedSites/Pond`; other attractions retain their existing groups.

The source layout is `scripts/world/public_garden.gd`. To regenerate after changing that script, run:

```
godot --headless --path . --script res://tools/bake_public_garden.gd
```

The bake always begins with the preserved reference town. Direct edits to the generated scene will be replaced by regeneration. The runtime pass is idempotent and skips towns already containing `PublicGarden`.

## Verification

- New park check: 2,004 capsule samples across path centers and both sides, checks that paths avoid lagoon water, landmark preservation, known vocabulary, and idempotence; zero failures.
- A CharacterBody3D walked across the bridge in both directions, passed both shoreline junctions in both directions, and entered the dock via its gangway, all without jumping.
- All 302 active scenes and scripts loaded without failures after duplicate cleanup.
- Overview and bridge views rendered in Godot's Compatibility renderer and visually inspected.
- Existing zoo/vehicle suite: 67 checks, 20 failures. The original scene produces exactly the same 20 failure labels (legacy vehicle motion/exit assertions). Gate operation, animal preservation, vocabulary popups, and boarding assertions pass; no new failures were introduced in this suite.
- Headless Godot prints the host certificate lookup warning independently of these scene checks.

Re-run the park check with `godot --headless --fixed-fps 60 --path . --script res://docs/evidence/town-checks/check_public_garden.gd`. Render previews with `godot --path . --resolution 1400x1100 --script res://docs/evidence/town-checks/render_public_garden.gd`.

## Reference refinements

Washington now faces west, away from the lagoon. The horse, rider, tricorn, and granite steps belong to the WashingtonStatue node. An oval promenade, small beds, flower borders, and lanterns frame the monument. The old zoo welcome board and both posts now sit together beside the zoo gate.

The gazebo moved six local units east, with its approach and the Charles walk adjusted for clearance. A nearby bench moved clear of the shoreline. The shoreline loop passes outside both bridge ends, leaving the promenade and side railings clear. Bridge stone towers now have coursing and layered cornices; the four main towers are taller than the outer abutments. The reference-inspired boat has wooden slatted seats on red frames, red perimeter rails, a green hull and white swan stern. The boarding landing has green fascia, rails, mooring posts, and a sloping entry.

Removed 791 unreferenced numbered file copies (including scenes, scripts, document images, import and UID sidecars) from the active project. Of these, 579 were byte-identical to their canonical files; the remaining unused variants were archived as well. Resource-path and UID references were checked before cleanup, and every archived byte was verified before deleting the active copies. A manifest is in `duplicate-cleanup.json`. The recovery ZIP is outside the Godot project at `../backups/public-garden-revision/unused-numbered-assets.zip`; the previous garden scene is alongside it.

## Walkable rolling terrain — 27 October 2026

Historical profile; superseded by the [4 November subtle grading](#boston-inspired-garden--4-november-2026).

The user authorized building the terrain directly in this project. The active
runtime now adds five broad rises, up to 2.2 town units, that taper toward the
existing low pond shoreline. The water is not lowered. Road edges, habitat pads,
playground, chapel/gazebo, statue plaza, dock and bridge mouths stay level.

`park_terrain.gd::build()` runs after compact layout, species placement and grass
materials, before batching. It creates one static 11,992-triangle mesh with matching
collision, upward smooth normals and the existing grass shader. Only raised land
receives triangles; the original flat floor remains valid below these positive
rises. No underwater excavation, terrain plugin or runtime deformation is used.
Paths and their centerline metadata follow the height function; main path ribbons
receive fitted static collision. Planting roots move with their colliders/picking;
planting-bed meshes conform to the ground. One saved grove tree overlapping the
bridge is moved to the east lawn. Existing movement settings remain unchanged.

`public_garden.gd::refresh_walks_and_boats()` rebuilds the saved bridge using its
existing helper with a 3.0-unit arch rise (formerly 1.765), retaining footprint,
level ends, vocabulary and continuous deck collision. Railing barriers extend to
cover the new crown. The existing refresh guard and `rolling_terrain` guard prevent
duplication. Restart Main to see changes; no saved world was rebaked.

Checks: `docs/evidence/town-checks/check_park_terrain.gd` tests elevated collision, protected flat areas,
normal direction, slope steepness, idempotence and six traversals with the actual
player collider. The compact-layout check now expects the explicitly authorized
bridge rise while preserving its footprint. See the dated verification record for
results and limits; screenshots alone do not establish laptop performance.

## Lagoon Bridge likeness — 28 October 2026

The user supplied three photos of the Boston Public Garden Lagoon Bridge and asked
for the park bridge to look more like it. `public_garden.gd::bridge()` (rebuilt by the
guarded `refresh_walks_and_boats()`) now has:

- **Deck profile** (`height_at`): nearly level over the water with ease-out ramps
  from each abutment, still peaking at 3.0 and meeting the paths at the same end
  height. The walkable deck mesh and invisible railing walls are unchanged in role.
- **Piers:** two full-width rusticated granite piers in the lagoon (x=10 and 30) with
  block courses, staggered joints, a three-step corbel and a footing.
- **Towers:** four tall panelled granite towers on pedestals over the piers (plinth,
  lower shaft, belt course, upper shaft, three-step cornice, cap) and four short end
  posts, each with a globe lamp on a slender dark-green iron post.
- **Chains:** a suspension chain per side sagging between tower tops (the centre span
  dips to just above the handrail) with vertical hangers; shallower side spans.
- **Deck edge:** a brown-grey girder face with a pale cap and rivet strip, an
  underside, and a white lattice railing with posts and a fine diamond pattern.

Parts are visual only (all named `Bridge…`) and batch with the garden. Before/after
views: `docs/evidence/bridge-20261028/` (`capture.gd`). The user's reference photos are not
stored in the repository.


## Pond basin relief — 28 October 2026

Historical raised shoulder; superseded by the [4 November subtle grading](#boston-inspired-garden--4-november-2026).

The requested landscape now places the existing pond at the bottom of a broad,
gently sloping basin. `scripts/world/park_terrain.gd::height_at()` replaces the
previous isolated hill-only profile with a 2.8 town-unit shoulder plus smaller,
broader irregular rises. Water level (since lowered, see the next section), shoreline footprint, bridge geometry,
bridge transform and surrounding properties remain unchanged. Raising the land
rather than moving the water preserves boats, dock and bridge connections.

Edit `BASIN_RISE`, `SHORE_RISE_START` (1.5) and `SHORE_RISE_END` (24.0) to tune
the basin. These are town-local units (world scale 1.3). The shoulder is multiplied
by smooth fades: actual height is lower near water, roads, occupied pads, the
statue plaza, bridge entrances and dock. Five broad low hill contributions break
up the uniform rim. The waterline stays level, and bridge entrances have a
5-unit level apron blending over 23 units into the surrounding land. No bridge
raise was necessary. Restart Main to rebuild; do not reset the runtime guard.

Paths and edging follow the same height field. Their meshes now have twelve
strips across their width so curved ground cannot protrude through a wide,
formerly two-vertex ribbon. Existing path positions, widths and materials are
preserved. Ground collision follows the one-unit terrain grid; path collision
uses the fitted mesh. Whole prop roots and wandering-animal grounding retain
the existing terrain-fitting behavior. Saves, vocabulary and approved zone
boundaries are unaffected.

The broader coverage uses 23,948 ground triangles (previously 11,992); the terrain
check allows 26,000, while retaining the slope-normal and actual-player traversal
checks. Trail junction checks now compare at the sampled terrain height rather
than assuming all junctions lie at y=0. The older rolling-terrain section above
records the previous profile, not this replacement.


Verification (28 October 2026, Godot 4.7.2, isolated copy with
`config/custom_user_dir_name="VocabularyTownChecks/pond-relief"`):

- Baseline terrain: 0 failures, 403 collision samples, six player traversals.
- Revised terrain: 0 failures, 913 elevated collision samples, six actual-player
  slope traversals without jumping; all ground normals y > 0.9; protected flat
  pads, unchanged waterline and raised shoulders verified.
- Public garden: 0 failures, 1,638 path-clearance samples; bridge crossed both
  directions, four shore-junction crossings and dock gangway passed.
- Resource loading: 328 resources, 0 failures. Existing legacy material warnings
  and sandbox log/certificate messages remain; this is not a full-suite claim.
- Rendered overview, bank and bridge-approach views inspected. Broad paths were
  refined after the first render revealed ground showing through their coarse
  cross sections; final views show continuous paved surfaces. Evidence:
  [overview](pond-after-overview.png), [bank](pond-after-bank.png),
  [bridge approach](pond-after-approach.png).

For repeatable visual checks, use `capture_pond.gd` in this directory with a
fresh isolated project: `godot --path <isolated-project> --resolution 1200x800
--script res://docs/guides/public-garden/capture_pond.gd -- after <absolute-output-folder>`.
Create the output folder first. No learner saves were used or changed.


## Lowered lagoon, bridge clearance and water — 28 October 2026

The lagoon surface now sits below its shoreline instead of flush with the ground.
`public_garden.gd` owns `WATER_LEVEL` (-.32) and `LAGOON_BED` (-1.0), in town
units (world scale 1.3). `park_terrain.gd::lagoon_basin()` adds one
vertex-coloured `Lagoon bank and bed` mesh with collision: a bank from the
unchanged shore polygon (y 0, under the granite rim) to -.44 at 0.9 units in,
past the waterline, then to the bed at 3 units in, plus a matching skirt from the
island rim. It lowers the saved water surface, swan boats and the fish by the same
offset. The floating landing stays at shore height; its fascia now reaches the water.
`ground_openings.gd::cut_lagoon()` cuts the lagoon polygon through every flat ground
layer that ran beneath it (natural terrain, meadow, beaches, shallows, sea surface)
and the filled granite shoreline patch, which leaves only its rim. Shore shape,
paths, the basin shoulder and the bridge deck are unchanged. Guard: `lagoon_ground_cut`.

Walking under the bridge was blocked by its invisible railing collision: two
44-unit walls from the ground to 4.1 units along both deck edges. They are now
22 slope-following segments each, from just below the deck to above the handrail,
so the space beneath is open. On land at the ends the deck is too low for the player
to fit under, but the lagoon can be waded under the spans. The granite piers now
reach the bed and are solid, so waders go around them. The bridge's appearance is
unchanged above the water; the extra masonry courses are below it.

`shaders/garden_water.gdshader` follows the home pool's approach: translucent
(clear looking down, near-opaque at grazing angles) so the bed tint shows through,
low roughness with strong specular sun glints, a fresnel sky tint standing in for
reflections (the Compatibility renderer has no screen-space reflections), and
three slow wave trains that tilt the normal. The colours stay pond green-teal.
Tune `shallow_color`, `deep_color`, `sky_color` and `clarity` uniforms there.

Verification (Godot 4.7.2, isolated copy with
`config/custom_user_dir_name="VocabularyTownChecks/isolated"`): public garden 0
failures, with a new check that a player capsule wades under the span at two
points in both directions. With the old walls restored that check fails all four
walks at the deck edges. Park terrain 0 failures, phase 2 trees 0 failures,
runtime resources 328 checked with 0 failures (existing legacy material warnings
remain). Rendered views: [bank](lagoon-bank.png),
[under the bridge](lagoon-under-bridge.png), [island](lagoon-island.png).
The earlier `pond-after-*` captures predate this change.


## Weeping willow design — 28 October 2026

`scenes/props/nature/species/weeping_willow.tscn` remains the editable species
entry point. Its geometry is generated by `scripts/objects/tree_species.gd`,
so this design update belongs in `_willow()` rather than baked scene children.
The crown now follows the user's soft park-willow reference
([preview](willow-design.png)): a taller forked trunk (height 3.3, radius .42
before runtime tree scaling) carries limbs to one crown cluster plus five to seven
side clusters. Each cluster is a dome of fat, smooth, rounded strands that arch over
the top and hang into a ragged hem; a shorter inner tier fills gaps, strands facing
the trunk stay short so limbs show, and a shallow shared-sphere cap covers each dome
top. Three lime shades per profile; all three deterministic profiles keep their
cluster count, palette and lean variants.

The strands are grouped into three opaque static meshes named `Hanging strands N`
(32,000–41,000 triangles per tree, three trees in the garden), with no per-leaf
nodes, alpha sorting or per-frame animation. Do not name them `Willow …`: the
phase 2 check treats that prefix as a leftover assembled willow. New foliage and
branch geometry has no movement collision. The `tree` trunk vocabulary,
`weeping willow` root key, crown StudyArea and runtime placement/height fitting are
retained; study bounds are recomputed from the generated foliage. Other species are
unchanged. Verified 28 October 2026: phase 2 tree checks report 0 failures in an
isolated copy, and pond captures show the new willows in place.

Tune cluster count, reach, height, dome radius and hem ranges, strand counts and
widths inside `_willow()`; strand tube shape lives in `_willow_strand()`. The scene's `profile` property previews variants
in the editor; reopen the scene or restart Main after editing the generator.

### Steerable swan boats — 28 October 2026

Each boat is now one `Swan boat` root under the town (`scripts/world/swan_boat.gd`),
assembled by `world_refinements.gd::swan_boats()` after the lagoon lowering. BonBon can
stand on the deck, benches and swan, sit on any of the five benches, or sit on the red
saddle on the swan's back to steer: W/S pedal, A/D steer, E stand up (onto the last
bench). The hull stops at solids (banks, bridge, island, landing) and stays inside the
lagoon polygon. [Verification](../FINAL_VERIFICATION.md#airport-detector-and-seats-steerable-swan-boats--28-october-2026).


## Monument trail cleanup — 5 November 2026

The user marked up an in-game overview against the [aerial](boston-reference-aerial.png):
red for trails to keep or add, yellow for trails to remove, and asked that every
trail be clean, with no overlapping clusters. The strokes were projected onto a
north-up plan (a ground-plane fit through the fountain, statue and bed-tip
positions) to identify each trail. Supersedes the trail list of both sections below.

- **Removed (yellow):** the outer walk's two bridge-side bends at canonical x≈−18,
  which ran beside the x=−28 cross walk. The outer walk is now open: north
  fountain circle → north lawns → x=−28 cross walk → south carriage walk (the
  separate `Monument east cross walk` and `Garden west carriage walk` routes are folded in).
- **Fountain circles (red):** `North/South fountain walk`, closed rings of radius
  `FOUNTAIN_WALK_RADIUS` 6.4 (width 2.6) around each fountain; their inner edge laps
  the sett apron, as the aerial's paving surrounds each basin. Forecourt arms (from
  the statue ring) and entrance arms (forking from the axis at x=−91) end on them.
- **Added (red):** `North fountain west walk`, north fountain circle to the west road
  sidewalk at (−96,173).
- **Clusters removed:** the entrance arms no longer share the outer walk; the south
  walk now runs south fountain circle → south lawns → lagoon walk at (−9.8,103.6), so
  it no longer shares (−53,112)–(−34,110) with the carriage walk or parallels the
  lagoon walk along z=91. The playground and farm links T into the walks instead of
  doubling back. The north garden walk starts at (−40,164.2), and the northern
  connection meets the lagoon walk square-on at (−10.6,155.5), clear of the rabbit's
  wander circle and the benches.
- Lens beds were shortened (to x −82) and slimmed to clear the circles and entrance arms.

Trees: `clear_trail_trees()` no longer places relocated trees within 10 of a fountain
(they used to be flung on by `compact_greenery()`), and `compact_greenery()` keeps
trees out of the bridge corridor; with the new paths one grove tree had landed on the
bridge's east end. `check_public_garden.gd` now expects four closed loops (island,
lagoon, two fountain circles), checks the x=−91 entrance fork and fails any pair of
trails that stays within 2.4 units of each other for more than 7.5 units at canonical
x < −2. Older east-bank overlaps (Charles walk/lagoon walk, east entrance/gazebo
link) are outside that scope and unchanged.

Renders: [plan](monument-20261105-trails-plan.png), [overview from the user's angle](monument-20261105-trails-trails.png),
[forecourt](monument-20261105-trails-forecourt.png), [fountain](monument-20261105-trails-fountain.png).

## Monument plaza art — 8 November 2026

The user supplied an illustrated view of the forecourt (tulip beds, two fountains with seated
bronze children, the equestrian statue on a stepped pedestal) and asked for the flower beds,
fountains and statue to look like it. Supersedes the lens-bed planting, border flowers, fountain
centrepiece and statue figure of the 5 November section below; positions, walks, bed outlines,
fountain basins, rims, aprons, yews, fences and lamps are unchanged.

Base steps `tulip_beds`, `plaza_fountains`, `bronze_statue` in `scripts/buildings/base.gd`,
geometry in `scripts/buildings/monument_plaza.gd` (merged ArrayMeshes built from lofts, lathes
and ellipsoids; no new assets):

- **Tulips.** The 412 lens-bed balls, the tropical crowns (elephant ears, cannas, dark foliage)
  and the 696 border balls are removed. Each lens bed (outline read from its saved
  `Entrance tapered flower bed` patch) gets a ring of chamfered curb stones
  (`Tulip bed curb`), a domed soil bed (`Tulip bed soil`) and 1,842 tulips in all, in a mixed
  red, yellow, pink, purple, orange, white and magenta palette, taller toward the crown. The
  borders get two tulips per former ball (1,392) in their own colour schemes (gold/orange arcs,
  pink/white straights, red/white island). Each planting is two MultiMeshes, `… leaves` (stem
  and two leaves) and `… blooms` (six-pointed cup, instance colour), without shadows, hidden
  beyond 120 m. **Bake note:** headless bakes run on the dummy renderer, which keeps no MultiMesh
  instance data, so the instances are saved in `scripts/objects/baked_multimesh.gd`'s
  `instance_buffer` and applied in `_ready` (the first bake saved every tulip at the origin).
- **Fountains.** The red granite base, column, capital and flat bowl keep their collision
  bodies but their meshes are hidden; one `Fountain centrepiece` lathe replaces them: a moulded
  plinth, a baluster, a wide bowl with a rounded lip (r 1.23, top y 1.685) holding `Bowl water`
  (the basin's water material) and a seat stone. `Bronze child with bird` sits on it, facing the
  west entrance. 28 arcing streams (`Falling water curtain`, `shaders/fountain_stream.gdshader`:
  translucent bands sliding down) land in a `Splash foam` ring. The old eight stream cylinders
  and six-sphere figure are deleted. A translucent spill sheet was tried and dropped (it read as
  a glass bell).
- **Statue.** `Bronze horse and rider` (one smooth mesh, bronze `5d4c37`, metallic 0.45)
  replaces the sphere-and-box figure: horse walking with the near foreleg raised, mane,
  forelock, tail; rider in a long coat with tricorn, boots, reins and sword. The old pieces are
  hidden, not deleted: `check_public_garden.gd` reads the horse head/body nodes and
  `docs/evidence/part2/verify.gd` the tricorn brim, and the Figure* nodes keep their collision. The pedestal
  gets raised panel mouldings on all four faces and dark engraved-style `WASHINGTON` lettering.

Renders (`capture_monument.gd`, 1200 × 800): [forecourt](monument-20261108-forecourt.png),
[lens bed](monument-20261108-beds.png), [fountain](monument-20261108-fountain.png),
[statue](monument-20261108-statue.png); before: [forecourt](monument-20261108-before-forecourt.png),
[lens bed](monument-20261108-before-beds.png), [fountain](monument-20261108-before-fountain.png),
[statue](monument-20261108-before-statue.png).
Checks: [verification record](../FINAL_VERIFICATION.md#monument-plaza-art--8-november-2026).

### Statue from the character blueprint — 8 November 2026 (later)

The user supplied a "Washington Equestrian Statue — Character Blueprint" sheet (front, side,
back, 3/4, close-ups, scale, palette) and asked for the statue to match it.

**First pass (step `statue_blueprint`, superseded the same evening).** Olive bronze, gilt tack
and cream stone were added, but on the old figure's proportions; the user judged it "does not
look like it". Measured against the blueprint's side view it was wrong in shape, not detail:

| Blueprint | First pass |
| --- | --- |
| Rider saddle-to-hat ≈ 1.3 × horse back height; head ≈ 0.8 m across | 0.85 ×; head 0.5 m |
| Neck nearly upright, ears ≈ 1.9 m above the back, big head | ears 0.95 m above the back, small head |
| Long barrel (≈ 3.2 : 1), legs ≈ body depth | short, fat barrel (2 : 1) |
| Statue hoof-to-hat ≈ 1.45 × pedestal height | 1.1 × (small figure on a big box) |
| Broad coat torso, coat skirts, thick bent arms, boots down the flank | thin tubes (peg-doll look) |
| Stone cap nearly the cornice width under a long plate | narrow 3 m upper plinth |

**Second pass (steps `statue_traced` and `statue_traced_refit`, current).** `statue_traced` in
`monument_plaza.gd` removes the first-pass mesh and rebuilds the bronze from scratch (via
`traced_bronze`), traced from the blueprint:
every point is written in the side view's pixels (x → statue +X, y down, hooves at 375; widths
from the front/back views at the same scale) and converted by `_p()` with `TRACE_SCALE`
0.018 m per pixel. That makes the statue about 5.2 m from hoof to hat (hat top y ≈ 8.8,
was 7.45) and 4.6 m from tail to muzzle, on the unchanged 3.5 m pedestal.

- **Horse** (`traced_horse`): long barrel with a high rounded rump and deep chest, smooth
  haunches and shoulders, an upright thick neck, a big head carried high and nose-down (cheek,
  muzzle, ears, eyes, nostrils), a smooth crest with chunky locks and a forelock, thick legs
  (near foreleg raised and curled, near hind leg back) on flared hooves, a long wavy tail.
- **Tack:** large saddle blanket with a gilt border, saddle with pommel and cantle, gilt bridle
  (noseband, cheek straps, rosettes, bit rings) and gilt reins to both hands.
- **Rider** (`traced_rider`): broad coat torso with a flared coat skirt over the horse's back,
  collar, cravat, gilt lapel piping and buttons, bronze epaulettes with fringe and gilt rims,
  thick bent arms with cuffs, thighs over the barrel and tall boots down the flank, stirrup
  leathers, sword; a big round head with eyes, brows, nose, chin, mouth, ears, wig rolls and a
  queue; a wide tricorn (one corner forward) with a rolled edge.
- **Base:** a rounded bronze plate (blueprint x 812–992, ≈ 3.2 × 1.6 m) on a new wide
  `Statue cap` (3.9 m square with a bevel and a thin moulding, upper-plinth stone). The old
  `UpperPlinth` mesh is hidden; its collision stays.
- **Palette:** bronze `6c6b42`, shade `3d3d24`, gilt `b89a4c` (vertex colours, sRGB),
  roughness 0.55, metallic 0.15. The first pass's warm cream stone (`STATUE_STONE`) and brown
  engraved `WASHINGTON` are kept.
- **Refit** (`statue_traced_refit`, rebuilds only the bronze): ears shortened to the blueprint's
  (tips about at the rider's chin), a chest blob over the barrel's front pole (it showed as a
  dark dot), and a softer sheen (metallic 0.3 → 0.15; at 0.3 the chest mirrored the white path).
- **Known limit:** from the walk in front of the statue the horse's head, 2.4 m in front of the
  rider and nearer the eye, still hides most of the rider's face; the blueprint's front view is
  drawn level with the statue, where the face clears the ears.

Renders (full town, 1200 × 800): [elevated](monument-20261108-traced-statue.png),
[front from the walk](monument-20261108-traced-front.png), [side](monument-20261108-traced-side.png),
[three-quarter](monument-20261108-traced-three.png), [close-up](monument-20261108-traced-close.png);
first pass: [elevated](monument-20261108-blueprint-statue.png),
[front](monument-20261108-blueprint-front.png), [side](monument-20261108-blueprint-side.png),
[three-quarter](monument-20261108-blueprint-three.png), [close-up](monument-20261108-blueprint-close.png);
before both: [statue](monument-20261108-statue.png).
Checks: [verification record](../FINAL_VERIFICATION.md#washington-statue-blueprint--8-november-2026).

## Washington monument refinement — 5 November 2026

The user asked for a review of the statue area against the same four Boston
photographs (beds, avenue, fountain, aerial) to make it recognizably the Public
Garden in the existing style, without changes outside the area. Supersedes the
bushes, entrance beds, fountain approaches and fountain design of the 4 November
section below; its ring, cross-paths, terrain and positions remain.

Review findings (4 November state): the lens beds sat on lawn, but in the aerial
they are islands in a paved forecourt; the twelve round shrubs read as small
domes, not the photographs' tall sheared yews; beds were flat rows of balls
without the photographed layers; the fountains had a tall rim and oversized
figure; the straight walks lacked the black chain fences and lamps of the avenue
photograph; the pedestal was a plain block; random walk-side bushes could break
the monument's symmetry.

`public_garden.gd` (canonical plan, entrance −X):

- **Forecourt.** `North/South fountain forecourt walk` leave the ring at 140°/220°
  and `North/South fountain entrance walk` leave the entrance at x=−86; both end on
  a fountain apron, so each lens bed is enclosed by paving (replacing the old
  `fountain approach` stubs). The entrance-side ring arcs stop at 128°/232°.
- **Lens beds** (`lens_bed()`): banana-shaped, x −66.5…−83.8, spine 4.6–5.05 off the
  axis, fattest toward the entrance. Layers from the edge in: red begonia, purple
  salvia spikes, pale ornamental grass with pink accents, then a crown of
  elephant-ear leaves alternating with dark foliage and orange-flowered cannas.
- **Sheared yews.** `YEW_SPOTS` (28): three pairs along the bridge promenade, three
  pairs on each north/south cross walk, four pairs on the bridge-side cross walk and
  a west-entrance pair. They reuse `shrub.tscn` with the new clipped-yew profile 3
  of `bush_species.gd` (~2.0 × 2.9 town units at scale 1.7/1.9); word key `shrub`
  and StudyArea unchanged.
- **Chain fences and lamps.** `chain_fence()` runs low black posts with sagging
  links along the straight walks, gapped at every junction; decorative, no
  collision. Four globe lamps line the promenade behind the fences.
- **Borders.** Ring arcs are gold/orange; straight borders are pink-and-white and
  moved 5.3–5.4 units off their walks, behind the yews; island strips red/white.
- **Fountains** (`garden_fountain()`, same centers (−77,125)/(−77,153)): a 5.4-radius
  granite-sett apron with darker courses, a wide low rounded curb (outer radius
  4.45), dark water, a reddish granite base/column/capital, a pale shallow bowl
  and a small crouching bronze boy-with-bird figure, eight thin streams.

`park_terrain.gd` levels fountain aprons to radius 5.6 (blend to 12).
`world_refinements.gd::refine_statue()` adds a projecting cornice, fillet and base
course around the retained 4 × 3 × 4 pedestal (decorative; the block keeps its
collision and transform) and lifts the horse's near foreleg as on the Boston
statue. `add_garden_bushes()` skips the monument rectangle (town x 16–96,
z 110–168), so its 16 random bushes land on other walks instead.

Renders (`capture_monument.gd`, 1200 × 800): [plan](monument-20261105-plan.png),
[forecourt](monument-20261105-forecourt.png), [fountain](monument-20261105-fountain.png),
[lens bed](monument-20261105-beds.png), [avenue](monument-20261105-avenue.png),
[statue](monument-20261105-statue.png); before: [plan](monument-20261104-before-plan.png),
[fountain](monument-20261104-before-fountain.png), [avenue](monument-20261104-before-avenue.png).
Checks: [verification record](../FINAL_VERIFICATION.md#washington-monument-refinement--5-november-2026).

## Boston-inspired garden — 4 November 2026

**Current layout authority: the user's [latest aerial photograph](boston-reference-aerial.png).**
The first pass was too flat and retained the wrong bed/path arrangement. The user
requested stronger northeast/northwest statue lawns, bushes and two entrance
fountains, then clarified the flower-bed and trail geometry with this aerial.
It supersedes both the six-oval arrangement and the intermediate four-bed layout.
The old pond fountain remains removed; the new pair belongs by the west entrance.

Other user-supplied references: [beds and monument](boston-reference-beds.png),
[low circular fountain](boston-reference-fountain.png),
[clipped promenade bushes](boston-reference-avenue.png),
[earlier map](boston-reference-plan.png). They are visual references, not measured
grading surveys; preserve the game's low-poly style, statue position, bridge,
lagoon and external destinations.

### Paths and planting

`public_garden.gd::refresh_walks_and_boats()` owns the revised paths and their
collision/validation metadata. The saved `Statue plaza` root is retained but uses
the lawn shader: the statue stands on a grass island, surrounded by an elliptical
walk (11.5 × 10.5 centerline radii, width 3). An irregular outer garden walk replaces
the oversized oval. Straight north/south cross-paths meet the island ring at
canonical x=-53; an east cross-path at x=-28 divides the bridge-side lawns.
Main avenue, lagoon connections and external destination branches remain.
Garden paving is warm gray with pale stone edging, following the photograph.
The active garden now has three closed walking loops (lagoon, outer garden,
statue island), not the older two. No town road or building is relocated.

`monument_planting()` uses existing landscape ribbons/patches and Main's shape
helpers for two tapered entrance beds (canonical x=-82..-66, z=134/144), curved
borders outside the island walk with gaps at its entrances, and narrow straight
borders along lawn-panel edges. Two small flower strips sit inside the island.
Twelve clipped bushes reuse `shrub.tscn`, profile 1; their StudyAreas and existing
word key remain. All beds/flowers are terrain-fitted using the existing owner.
The replaced decorative bed pieces add no vocabulary; no keys or learner saves
change. Tree clearance uses the new path curves, keeping the avenue open.
`world_refinements.gd::compact_greenery()` relocates whole tree roots within eight
units of either fountain, preserving their colliders and vocabulary.

`garden_fountain()` groups each solid stone basin/rim, small seated bronze figure,
falling streams and water under one terrain-grounded root. It reuses Main's
shape/material helpers and the lagoon ripple shader. Fountains are decorative,
not new learnable keys. Canonical centers are (-77,125) and (-77,153), west of the
statue. Curved approach walks connect their aprons to the entrance avenue.

### Grading

`park_terrain.gd::height_at()` retains a .65-town-unit base with broad variations
of .12/.09 and road, habitat, shoreline and bridge-mouth fades. The monument
ellipse and central avenue attenuate this base. Broad northern rises are added at
town-local (29,157) and (65,155), with amplitudes .9 and 1.4 before pad/shore/avenue
fades. Town +X is west and +Z north, so these are northeast and northwest. They
blend over roughly 24–27 units. Fountain centers (77,125)/(77,153) have level
4.3-radius aprons, blending to the lawns over 11 units. The statue island stays
level; the park is neither flat nor surrounded by the older high rim. World scale
is 1.3. The lagoon bank/bed, water level and bridge structure are unchanged.

Restart Main to preview; retain refresh/terrain guards. No saved-world rebake or
standing grass. The terrain check covers bounded grades, visible northern relief,
level fountain aprons, collision and player traversals. The garden check covers
three loops, connected cross-paths, fountains, shrub picking metadata and
path/bridge/dock clearance. `capture_pond.gd` takes seven views including a
north-up plan. See the dated [verification record](../FINAL_VERIFICATION.md)
for final measurements, renders and limitations.


### Sculptural portrait refinement — 8 November 2026

The user's subsequent portrait reference supersedes the chunky character-blueprint style:
warmer aged bronze, curved horse anatomy, flowing mane and tail, an upright tricorn,
more fitted facial proportions, hanging reins, saddle fringe/laurel motifs, stirrups and
corner pilasters on the existing cream pedestal. Implemented by base steps
`statue_reference` and `statue_reference_finish` in `monument_plaza.gd`; the second step
seats the facial relief and brings the pilasters forward after rendered inspection.
The original statue transform, plaque, collision and garden layout are preserved.
This is a stylized procedural interpretation; the portrait's realistic facial sculpture,
continuous anatomical surfaces and fine engraved stone detail are not reproduced.

Views/check: `capture_statue_reference.gd` (same arguments as `capture_monument.gd`).
[Three-quarter view](monument-reference-final-20261108-three.png),
[close view](monument-reference-final-20261108-close.png).


**Portrait follow-up (8 November 2026):** user requested a less round head and more
hair texture. Step `statue_angular_portrait` replaces the ellipsoid head with a
longer, rounded-rectangular section mesh: flatter forehead, cheek planes and squared
jaw. The wig has swept strand ridges, three layered spiral-textured rolls on each
side, and a grooved tied queue. Face relief is rebuilt against the new surface.
`capture_statue_reference.gd` now requests portrait and rear-hair close-ups, but this run stalled before them. Rendered evidence: [three-quarter](monument-angular-20261108-three.png), [side](monument-angular-20261108-side.png). Dedicated close-up verification remains incomplete.


**Temple/proportion follow-up (8 November 2026):** user requested removal of the
additional colour, hair at the temples, and a slightly wider/shorter face. Step
`statue_temple_hair` gives all face/hair vertices one bronze tone (no contrasting
hair highlights or painted facial features), fills both temples with swept locks,
and scales the attached portrait 12% wider across the face, 8% shorter and 4% deeper,
anchored under the hat. The horse, tack and clothing palette remain as before.
The capture script accepts an optional third argument `portrait` for only the two
portrait/hair views, avoiding unnecessary whole-monument views.

Close-up correction step `statue_hair_relief_fit` seats the strand ridges on the
ellipsoidal temple/back hair and tapers the curl ridges to each roll's surface.
Final views: [portrait](monument-temples-final-20261108-portrait.png),
[back of hair](monument-temples-final-20261108-hair.png).


**Single bronze finish (9 November 2026):** the user's repeated request to remove
the different colour applies to the entire horse and rider, including the hat,
uniform trim, reins and saddle. Step `statue_single_bronze` replaces only the
material override with one bronze albedo (`796037`), disables vertex colours and
softens reflections (roughness 0.55, metallic 0.35). All geometry is retained.
This supersedes the retained tack/clothing palette above. Future reference rebuilds
use `uniform_bronze_material()` as well. The cream stone pedestal stays stone.

**Cast-bronze patina finish (9 November 2026):** from the user's photograph of the Boston
statue ("the color and the texture is a little off"). The flat `796037` read as mustard brass
in town light; the photo is dark chocolate bronze, glossy where bare, with grey-green patina
streaks. Steps `statue_patina` and `statue_patina_warm` set `patina_bronze_material()`
(`monument_plaza.gd`) on the whole mesh: still one material, no vertex colours or part
colours. A seamless `NoiseTexture2D` (simplex, seed 1776) is mapped through `PATINA_RAMP`
(bronze `3a2b1d`–`6b5137` into patina `5e5640`–`6d7a5c`) for albedo and through
`PATINA_ROUGH` (bare 0.30–0.36, patina 0.6–0.78) for roughness, projected triplanar (the mesh
has no UVs) with `uv1_scale (0.55, 0.22, 0.55)` so the patina runs down in streaks. Metallic
0.38, specular 0.5. The first values (darker ramp, metallic 0.62) read near-black and
mirrored the blue sky; `statue_patina_warm` lifted them. The material keeps its built-in
textures, so the bake leaves it unshared (not a palette file).
`capture_statue_reference.gd` now asserts this finish (patina textures, triplanar, no vertex
colour) instead of the flat `796037`. Views: [three-quarter](monument-patina-20261109-three.png),
[side](monument-patina-20261109-side.png), [front](monument-patina-20261109-front.png),
[close](monument-patina-20261109-close.png), [portrait](monument-patina-20261109-portrait.png),
[hair](monument-patina-20261109-hair.png).

**Town-style bronze (9 November 2026, supersedes the patina):** the user wants the statue to
look and feel like the rest of the game. The patina's noise read as camouflage blotches up close
and its metal sheen still mirrored the sky. Step `statue_town_bronze` sets
`town_bronze_material()` (`monument_plaza.gd`): one plain dark olive bronze `5c5236`, roughness
0.6, metallic 0, no textures or vertex colours, the same kind of material `material_for()` gives
every other prop (it is a shared palette file again). The slightly lower roughness than the
town's 0.82 keeps the sculpted form visible in sunlight; matte versions read as beige clay.
`capture_statue_reference.gd` asserts this finish. Record:
[verification](../FINAL_VERIFICATION.md#statue-in-the-towns-style--9-november-2026).
