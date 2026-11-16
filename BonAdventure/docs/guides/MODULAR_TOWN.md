# Modular town — one scene per building

Status: **phases 1–3 done, old pipeline deleted** (6 November 2026): the game starts from the
modular town, and a building is changed with its own script and the one-building bake
([Changing a building](#changing-a-building)); the base world has the same kind of bake
([changing the base world](#changing-the-base-world)). The old startup passes, legacy bake tools and old
saved worlds were deleted and their checks reworked or retired
([old pipeline removal](#old-pipeline-removal--6-november-2026)). This guide owns the decision, the target structure, the migration phases,
how to change a building, and the verification.

## Decision — 6 November 2026 (user)

- Split the single saved town (`town_public_garden.tscn`, about 31,500 saved nodes, about
  67,000 after the startup passes) into a **base world** plus **one unit per building**, so
  `dev_focus.txt` loads only the listed buildings and each building can be opened alone.
- **Source of truth: the building's own scene plus its own script.** Today's finished town is
  baked once; afterwards the town-wide startup passes that produced it (`world_refinements.gd`
  and the per-building interior scripts it calls) no longer run at startup and were deleted
  the same day (user, 6 Nov 2026; kept in git history). New changes go in the building's own script, which only touches that
  building, in that building's coordinates.
- **Not in scope:** streaming buildings in while playing (rejected for now), and any visual
  redesign during the move (the town must look and play the same).
- Commits: reasonable verified chunks, without asking before each one during this
  restructure (user, 6 Nov 2026; recorded in `AGENTS.md`). Ask when unsure.

## Measured starting point — 6 November 2026

| Item | Value |
| --- | --- |
| Windowed boot, focus `restaurants, police` | about 11 s (4.2 s engine + scene load, 2.9 s `build_world`, 1.4 s rest of `_ready`, 2.5 s first frames) |
| Nodes after `build_world`, full town | 67,004 |
| Building parts (RelocatedSites, Buildings, Restaurants, Airport, Warehouse, Barn, Map facades) | about 50,800 |
| Base (garden, vehicles, zoo, trees, roads, small top-level nodes) | about 16,000 |
| Expected nodes with focus `restaurants, police` | about 26,000 (about 39 %) |

## Target structure

| Piece | Owner |
| --- | --- |
| Base world: ground, roads, garden, zoo, trees, vehicles, coast, street furniture | `scenes/town/base.scn` |
| One unit per building (all its parts: site pivot, `Buildings/*` shell, map facade, staff) | `scenes/town/<unit>.scn` (binary: about 5× faster to load than text) + optional own script `scripts/buildings/<unit>.gd`. `scenes/buildings/` keeps the older prefabs the units instance |
| Registry: unit id, focus name, its parts and their original parent paths | `data/buildings.json` |
| Loading | `scripts/world/modular_town.gd` (called from `main.gd::build_world()`) loads the focused units into the base and puts every part back at its original node path, so existing code keeps its paths |
| One-building bake (applies a building's own script, saves only that unit; `base` bakes the base world with `scripts/buildings/base.gd`) | `tools/bake_unit.gd` |
| Reviewing a bake (node-by-node diff of two saved scenes) | `tools/compare_scenes.gd` |
| Shared materials (one file per distinct look, used by every scene; [palette](#material-palette)) | `materials/palette/<hash>.tres`, written by `tools/material_palette.gd` during bakes |
| One-time bake from the old pipeline (deleted 6 Nov 2026; in git history at `a5059dd`) | was `tools/bake_modular_town.gd` |
| Development focus and spawn (`dev_focus.txt`, `VT_FOCUS`, `VT_SPAWN`) | `scripts/core/dev_focus.gd` |
| Runtime layout (site pivots and bounds, roads, map entries; read from the base's `baked_layout`, written back by a base bake) | `scripts/world/reference_world_layout.gd::restore()` / `bake_state()` |

Things the bake must carry over because they are not saved by a plain scene save:
door states (`door_state` meta, as the earlier bakers do), sign translation (labels are
saved in their source text and translated at load), vocabulary root links
(`vocabulary_root_path`), map/layout data computed at runtime (site targets, spawn,
map details), and script variables set by passes (for example animal wander settings).

Also carried (found while reaching parity): node references in metadata (`<meta>__ref(s)`),
SubViewport textures on sprites (`viewport_texture` link), vehicle door leaves (`boarding_door`),
elevator parts that ride with the car (`ride_with_car`), and prefab instances a pass moved or
deleted nodes from (saved as plain nodes). Output that scripts rebuild in `_ready` (character
sculpts, costumes, plant models, elevator and crab parts) is stripped. Scripts saved in the town
must not rely on a pass having run: inner classes became own files (`fitting_booth.gd`,
`playground_seesaw*.gd`, `food_icon_sheet.gd`), references a pass set are `@export`ed (turboprop,
swing, swan boat), and `_ready` rebuilds what a scene cannot keep (`ModularTown.find_game()`,
garage-door sections, turboprop sweep hulls, the swan boat's town).

## Phases

1. **Bake and load with full-town parity.** Bake tool, registry, loader. With focus `all` the
   game must match the baseline below: same check results, same rendered views.
2. **Focus mode.** Systems that assume every building exists (town map, minimap, zones, area
   vocabulary, shops, staff, vehicles, sign translation) cope with missing units.
3. **Cut-over.** Startup no longer runs the retired passes; per-building logic that still has
   to run (sessions, anchors, helpers such as `police_interior.gd::mirror_point()`) moves to
   the building's own script. Update the README, architecture guide and `AGENTS.md`.
   *Done 6 Nov 2026:* own scripts plus `tools/bake_unit.gd`; the full bake refuses once a unit has
   own-script steps. Nothing had to move: no retired pass runs at startup, and the runtime code
   that still uses one of their files calls helpers, not passes (`warehouse.gd` builds the
   warehouse game's copy, `school_posters.gd` is the poster kit for `police_posters.gd`,
   `park_animals.gd` is the animals' node script, `world_refinements.gd::dev_focus()/dev_spawn()`);
   `mirror_point()` is used only by checks. The old pass files were first frozen, then deleted
   the same day ([old pipeline removal](#old-pipeline-removal--6-november-2026)).

## Changing a building

The unit scenes in `scenes/town/` are the source of truth. Two ways to change one:

- **In the Godot editor:** open `scenes/town/<unit>.scn`. Its root holds one child per part,
  named by its original path (`RelocatedSites__Police`), stored in town coordinates (Apartment
  space: scale 1.3 is applied by Main, +X west, +Z north). Keep the parts' `unit_*` metas,
  doors' `door_state`, `<meta>__ref(s)` and `node_refs`; signs are saved in their English
  source text and translated at load. Sculpted characters are `@tool` scripts, so the editor
  rebuilds their meshes and saves them in the scene (bigger file, same game).
- **In code (preferred for agents):** add a step to the building's own script and bake it:

  ```gdscript
  # scripts/buildings/police.gd
  extends RefCounted
  const STEPS := ["add_bench"]          # applied in order, each exactly once

  func add_bench(town: Node3D, game) -> void:   # town = Main's Apartment
      var site: Node3D = town.get_node("RelocatedSites/Police")
      ...  # Main's helpers (game.box(), game.cylinder(), ...) and node paths work as usual
  ```

  ```sh
  godot --headless --path . --script res://tools/bake_unit.gd -- police
  ```

  The tool loads the whole modular town (every unit, whatever `dev_focus.txt` says), runs the
  steps the unit has not had yet, and saves only the named units. Applied steps are listed in
  the unit's `applied_steps` meta; never rename or remove a baked step (add a new one that
  undoes it). Doors, signs, node references and generated meshes are handled as in the
  one-time full bake (its helpers now live in `bake_unit.gd`). Map and layout data and the
  outdoor world belong to the base: [changing the base world](#changing-the-base-world).
  Landscape helpers for steps: `natural_town_layout.gd` (`smooth`, `surface`, `patch`, `ribbon`,
  `walk`, `tree`, `bench`); building dimensions the checks use live as constants in the own script
  (`police.gd`, `barn.gd`). Collision for a decorative roof: the shared helper
  `scripts/buildings/roof_solids.gd` (step `solid_roofs` of home, playground, police, airport,
  hospital, restaurants, chapel and base, 7 Nov 2026,
  [record](FINAL_VERIFICATION.md#decorative-roofs-made-solid--7-november-2026)).
  Faces that share a plane and flicker (z-fighting): `scripts/buildings/coplanar_gaps.gd`, steps
  `coplanar_gaps` and `coplanar_gaps_2` in every unit; find new ones with
  `docs/evidence/coplanar-scan-20261110/scan.gd` (10 Nov 2026,
  [record](TOWN_DESIGN_BRIEF.md#coplanar-faces-across-the-town--10-november-2026)). A new step that
  adds geometry can call `separate(town, "<unit>", <next pass number>)` at its end.
  Window glass: the shared component `scenes/props/window.tscn` (`scripts/buildings/glass_windows.gd`
  `replace()`, step `glass_windows` in 13 units, 12 Nov 2026, [guide](WINDOWS.md)).
  Monument plaza art (tulips, fountain centrepieces, bronze statue): `scripts/buildings/monument_plaza.gd`
  (base steps, 8 Nov 2026). A MultiMesh filled in a headless bake is saved empty (the dummy renderer
  keeps no instance data): store the instances with `scripts/objects/baked_multimesh.gd`.
  Grocery products: `scripts/buildings/supermarket_products.gd` (one shared mesh per product
  kind and variant, three shared finishes; `restock()` rebuilds a goods group inside its word root;
  `fitting()` carts, baskets and checkout props; used by `supermarket.gd`, by `bakery.gd` (café
  fridge and bread rack) and by `scripts/ui/product_pictures.gd` (order/cart pictures), 8 Nov 2026,
  [style guide](TOWN_DESIGN_BRIEF.md#supermarket-product-art--8-november-2026)).
  Working toilets and faucets (and washbasins): `scripts/world/bath_fixtures.gd` `add_toilet()` /
  `add_faucet()` (home steps `bath_fixtures`, airport `restrooms`, 8 Nov 2026,
  [record](TOWN_DESIGN_BRIEF.md#bathroom-fixtures--8-november-2026)).
  Shop fixtures and word items (`item()`, `fixture()`, `pick_area()`, player-only blockers) and
  sports product art: `scripts/buildings/sports.gd` with `sports_props.gd`, reused by `restaurants.gd`
  (Pizza and Burger); furniture product art `scripts/buildings/furniture_props.gd`. The prefab
  models are written by `tools/build_sports_props.gd` and `tools/build_furniture_props.gd`; after
  running one, re-bake every unit that places those prefabs (no steps) so stale overrides drop
  (9 Nov 2026, [record](TOWN_DESIGN_BRIEF.md#interiors-polish--9-november-2026),
  [clickability rules](ARCHITECTURE_REVIEW_PART1.md#clickable-word-items--9-november-2026)).

### Changing the base world

Everything that is not a building unit (ground, roads, garden, zoo, trees, vehicles, coast,
street furniture) is saved in `scenes/town/base.scn`, together with the layout data on its root
(`baked_layout`: `spawn_point`, `sites`, `site_bounds`, `roads`, map `entries` and `details`). Its own
script is `scripts/buildings/base.gd`, with steps as above; bake it as `base`, alone or with units:

```sh
cp scenes/town/base.scn /tmp/base-before.scn        # to review the bake afterwards
godot --headless --path . --script res://tools/bake_unit.gd -- base [police ...]
godot --headless --path . --script res://tools/compare_scenes.gd -- /tmp/base-before.scn res://scenes/town/base.scn
```

- A step may add or change base nodes (`town.get_node("PublicGarden")`, Main's `game.box()`, the
  landscape helpers) and the layout in `game.reference_layout` (`sites`, `site_bounds`, `roads`,
  `entries` with a node, `details`, `spawn_point`); `bake_state()` writes the layout back as node
  paths, and `restore()` reads it at load.
- **Clay zoo animals are stored as plain nodes** (13 Nov 2026, smaller web download): the web
  export leaves `scenes/animals/*_clay.*` out, so a step that places a clay scene in the town must
  end with `unpack_clay_animals(town)` (base.gd); `tools/deploy_web.py` refuses a build otherwise.
  Since 16 Nov 2026 their meshes are separate files (`scenes/animals/clay_meshes/`, written by
  `tools/clay_save.gd`) that `base.scn` names, so a rebuilt clay animal reaches the town with no
  step unless its part names change ([clay file sizes](ANIMAL_SYSTEM.md#clay-file-sizes-16-nov-2026)).
- The whole town loads; every unit is split out before the base is saved (so no building is saved
  twice), but only the named units are written. The base takes ~8 s to bake (full town, Apple M5).
- `compare_scenes.gd` instances both scenes without running them and lists added and removed
  node paths and changed classes, transforms, scripts, groups, meta keys, plain meta values and
  material content ([palette](#material-palette)), ending with `COMPARE: <n> nodes vs <m> nodes, <k> differences` (exit 1 when they differ).

**Runtime-built nodes are not saved** (any bake). The loader gives every saved node an owner, so
nodes that are ownerless right after the town loads were built by a script in `_ready` (and
are built again at every load); the bake records them before the steps run and frees them before
saving (`runtime-built dropped` in the report). Nodes the steps add are kept. A runtime-built node
that holds saved nodes would be kept and reported. Today only the hospital helicopter's rotor
blur is dropped: `driveable_vehicle.gd` frees the saved copy and builds a new one at every load.

### Material palette

Since 6 Nov 2026 every bake routes the saved scene's materials through a shared palette
(`tools/material_palette.gd`, called from `bake_unit.gd::save()`): each `StandardMaterial3D` /
`ORMMaterial3D` the town scene stores itself (node `material_override`, surface overrides, CSG
materials, and the materials of the town's own meshes) is replaced by
`materials/palette/<hash>.tres`, where the hash is the first 16 hex digits of SHA-256 over the
material's exact content (class plus every stored property, `resource_name` and metadata
included; textures by file path; a `next_pass` by its own content). Identical looks in different
scenes (or in one scene) therefore become one file and one object at runtime, as Main's
`material_for()` cache made them before the town was split into files. Left as they were:
prefab materials (`scenes/buildings/*.tscn` sub-resources), materials marked
`resource_local_to_scene`, other material classes (ShaderMaterial), and materials with a texture
or `next_pass` that is not a file (14 today, e.g. built-in textures). A step needs no palette
code: it builds materials as usual (`game.material_for()`, `StandardMaterial3D.new()`), and the
bake finds the matching palette file or writes a new one (`palette files written` / `materials
shared` / `materials left unshared` in the report).

**Rule: never change a material found on a town node in place.** A palette material is shared by
every node in every scene with that look, so tinting it would recolour the whole town. Code that
changes a found material must `duplicate()` it first (as `evidence_props.gd` does for wet props);
code that builds its own material (`StandardMaterial3D.new()`) may change it freely. Checked on
6 Nov 2026 with `rg` over `scripts/`: no runtime code edits a saved material in place (the hospital
elevator lamps, rotor blur, zone, hover and highlight materials are all built by their scripts).
`garden_rendering.gd` and `render_culling.gd` batch by colour or material identity, so shared
materials batch across units as they did in the single saved town.

Unused palette files are not deleted automatically. To prune after a building drops a look: a
palette file that no `scenes/town/*.scn` depends on and nothing else references (`rg` over
`scenes/` and `scripts/`). List a scene's palette files with
`ResourceLoader.get_dependencies("res://scenes/town/<unit>.scn")` in a small headless script.
*Stale until 8 Nov 2026:* this said to `grep` the scenes for the path, but they are saved
compressed (`RSCC`), so `grep` finds nothing and reports every palette file unused
([record](FINAL_VERIFICATION.md#supermarket-product-art--8-november-2026)). `compare_scenes.gd` compares
materials by content (a material moved into the palette compares equal) and prints how many
material objects each scene stores itself and how many come from palette files.

Also kept stable across bakes: a part's `unit_index` is taken from its unit scene (the loader
re-inserts parts in index order, so indices read back from the loaded town drifted), and crabs
are saved at their `home` (where they were loaded) rather than where they scuttled to.

Runtime behaviour (sessions, NPC logic, minigames) stays in its own scripts under
`scripts/learning/`, `scripts/world/` and the node scripts; the own script only changes what
the unit scene contains. The old passes are gone. How a building was first built is in the history
before 16 Nov 2026, which this repository does not carry: it is in the private `jameshho/vocabulary-town`
repository and the local backup bundle (for example `git show a5059dd:Vocabulary_Town/scripts/world/police_interior.gd`
there).

The loader gives every saved node it places the town root as owner (as in the old saved town;
prefab internals keep theirs), so nodes built by scripts at runtime stay ownerless and the
bake drops them ([above](#changing-the-base-world)); `find_child()` with its default `owned = true` also finds unit nodes again.

### Finding a building at runtime

Parts keep their historical node paths (`RelocatedSites/Police`, `Buildings/School`,
`Restaurants`, `Warehouse`, ...) because saved data, checks and the bake depend on them; do not
rename them. Runtime code does not spell those paths out: it asks the address book in
`scripts/world/modular_town.gd` (since 6 Nov 2026):

```gdscript
const ModularTown := preload("res://scripts/world/modular_town.gd")
var school := ModularTown.building(town, "school", 1)                  # Buildings/School
var door := ModularTown.building(town, "home", 0, "Garage door")       # RelocatedSites/Home/Garage door
```

`building(town, unit, part := 0, below := "")` takes the unit key of `data/buildings.json`, an
index into its `parts` (0 is the first listed, usually the site under `RelocatedSites`) and an
optional path inside that part. It returns **null when the unit is not loaded** (dev focus; its
site may still exist as an empty layout pivot, which a literal `get_node_or_null()` would find)
or when the node is missing, so every caller handles null. An unknown part index is a script
error. Callers: Main (`current_room()`, spawn, `garage_door()`, the Home roof), the minimap,
`reference_world_layout.gd` (`location_name()`, rotor-blur pick), the warehouse and police
detective sessions and `house_characters.gd`. `docs/evidence/town-checks/check_building_lookup.gd` checks every part
for the loaded units and null for the absent ones, then walks every site (run it with a focus).
Own-script steps run on the whole town and may use either form. Checks under `docs/` keep their
literal paths.

### Units added while the game runs (home first) — 13 November 2026

Since 13 Nov 2026 (user, staged loading for the web) a profile that will play the welcome
tutorial starts with the base world and only `home` and `supermarket` (`app.gd`
`TUTORIAL_UNITS`, set as `Main.initial_units`); the other units wait in `Main.pending_units` and
`app.gd` `_load_rest()` adds them one at a time with `Main.add_unit(key)` at quiet moments of the
tutorial (a fade, the title cutscene, a dialogue line), the rest at once behind the loading screen
when the tutorial ends or is skipped. Profiles that finished the tutorial, checks and tools load
every unit before `town_ready`, as before. Measurements: [FINAL_VERIFICATION.md](FINAL_VERIFICATION.md#staged-loading-home-first--13-november-2026).

- `ModularTown.add_unit(town, key)` puts one unit's parts back like `load_units()`. An absent
  unit's empty site pivot (`reference_world_layout.gd`, meta `unit_placeholder`) is replaced, so
  the part keeps its node path. Base links into units not loaded yet stay as `__ref` / `__refs`
  metas (town meta `pending_node_refs`) until their unit arrives.
- `Main.add_unit(key)` then gives the new parts what `_ready` gives the first units: door states
  and door interactables, map entries (`reference_layout.add_unit()`), translated signs,
  vehicles, word areas (`area_vocabulary.add()`), seats (`seating.add_seats()`), solid figures,
  lamp glow (`day_night.bind_lamps()`), render trim and batches (`render_culling.add_parts()`,
  container `StaticRenderBatches/Unit_<key>`), then the jobs waiting for that unit; the maps are
  rebuilt when the last one is in. It emits `unit_added(key)`.
- Owners (fixed 13 Nov 2026): `_place_parts()` gives every saved node of a placed part the town
  as owner, also when the unit scene's holder still owned it (from a4c5c2c until this fix the
  holder was freed afterwards, which left the parts' nodes ownerless: `find_child()` missed them
  and `tools/bake_unit.gd` dropped a building's contents as runtime-built; caught when a home
  bake wrote a 2 KB `home.scn`, which was not committed).
- **Rule for new code:** anything that finds a building's nodes once at setup (a minigame
  session finding its NPC, an index of the town) must either look again later or run through
  `Main.when_unit_loaded(key, job)`, which runs `job` now or when unit `key` arrives
  (`minigame_wiring.gd` `_when()` does this for every session). Code that calls
  `ModularTown.building()` each time it needs a building needs nothing.
- A unit added later freezes the game while its scripts run `_ready`. Plush characters are
  most of that (sculpting a ~100k-vertex plush, every launch on the web, where `sculpt_cache.gd`
  has no script source to key on), so `Main.add_unit()` holds the unit's top-level
  `*_plush.tscn` nodes back (`ModularTown.add_unit(town, key, held)`) and puts one back per frame
  (`ModularTown.put_back()`, then `finish_refs()`). Longest single frame on a laptop in Chrome:
  restaurants 0.8 s (was 2.2 s), the rest under 0.7 s. Its materials compile on first sight. The tutorial must only go where `TUTORIAL_UNITS` are; add a unit there if a tutorial
  step ever uses another building.

## Old pipeline removal — 6 November 2026

User decision: "delete the frozen old pass files and rework the checks that use them", and
review whether each check is still needed.

**Deleted** (all in git history at `a5059dd`):
- 33 startup pass scripts nothing at runtime reached any more: `world_refinements.gd`,
  `public_garden.gd`, `reference_home.gd`, `park_terrain.gd`, the interior scripts
  (`police_interior.gd`, `barn_interior.gd`, `restaurant_venues.gd`, ...), the exterior,
  coast, playground, rooftop and upgrade passes, and the generators `house_builder.gd`,
  `town_builder.gd`, `town_polish.gd`, `furniture_polish.gd`, `home_rework.gd`.
- 7 legacy tools: `bake_modular_town.gd` (its helpers moved into `bake_unit.gd`),
  `bake_editable_town.gd`, `bake_reference_world.gd`, `bake_public_garden.gd`,
  `bake_police_geometry.gd`, `bake_rooftop_collisions.gd`, `build_rooftop_assets.gd`.
- 5 old saved worlds (about 47 MB): `scenes/world/town_public_garden.tscn`,
  `town_reference.tscn`, `town_complete.tscn`, `town_editable.tscn`, `rear_meadow.tscn`.
  `park_zoo.tscn` and `zoo_gate.tscn` stay (the base instances them).
- Main's legacy construction branches (`town_editable` fallback, `bind()` path, builder
  path, sky decor) and `reference_world_layout.gd`'s relocation pass (`build()`, `bind()`,
  `bake_state()` and helpers); `natural_town_layout.gd` keeps only its landscape helpers.

**Moved** (still needed): `dev_focus()` / `dev_spawn()` → `scripts/core/dev_focus.gd`; animal
display sizes → `park_animals.gd`; police plan constants and `mirror_point()` →
`scripts/buildings/police.gd`; barn dimensions → `scripts/buildings/barn.gd` (both own scripts
have no steps); the rotor-blur pick helper → `reference_world_layout.gd::add_pick()`.
Kept as they are: `warehouse.gd` (its `build()` no longer runs; `build_copy()` makes the warehouse
game's copy) and `school_posters.gd` (poster kit it uses). *Later the same day* (dead-code sweep): `warehouse.gd`
was cut to the shell, hall equipment, constants and `build_copy()`; `school_posters.gd` was
deleted (nothing used it once the warehouse posters code went); Main lost its unused original
neighbourhood builders (`build_neighborhood_exterior()`, `build_exterior_polish()` and helpers,
`piece()`, `add_ceiling_light()`), and comments that named deleted passes as if they ran now
say where the nodes are saved ([record](#building-address-book-and-dead-code-sweep--6-november-2026)).

**Check review**

| Check | Decision | What changed |
| --- | --- | --- |
| `check_compact_layout.gd` (suite) | Kept, reworked | Comparisons with `town_public_garden.tscn` (landmark frames, lagoon outline, bridge/pond placement) and the pass re-run retired: the saved town is the source of truth. Bridge crown height kept. |
| `docs/evidence/part2/verify.gd` (suite) | Kept, reworked | Animal sizes from `park_animals.gd`; helpers inlined; old-world group/habitat/pedestal comparisons and pass re-run retired. Parking count 13 → 14 (the warehouse lot; the stale-count P2 item). |
| `check_public_garden.gd` (suite) | Kept, reworked | Yew count fixed at 28; junction heights from the saved ground mesh; the garden and trail pass re-runs retired. |
| `check_park_terrain.gd` | Kept, reworked | Heights from the saved ground mesh (`docs/evidence/town-checks/park_ground.gd`) instead of the pass's formula; pass re-run retired. |
| `docs/evidence/barn-20261101/verify.gd`, police checks (`docs/evidence/police-detective-20261106/verify.gd`, `play_input.gd`, `capture.gd`, `docs/evidence/police-interior-20261028/verify.gd`, `docs/evidence/police-officer-20261101/verify.gd`) | Kept | Constants from the own scripts; the barn's second-build check is now "one barn interior". |
| `check_building_dimensions`, `check_cafe_bank_exteriors`, `check_map_facades`, `check_market_interior`, `check_rooftops`, `check_school_exterior`, `check_school_partition`, `check_supermarket_exterior` | Kept | Only their last "pass is idempotent" assertion was removed (the pass is gone); `check_rooftops` keeps the roof-label rule inline. The six snapshot checks were later retired (7 Nov 2026) for `check_building_access.gd` ([record](FINAL_VERIFICATION.md#snapshot-checks-retired--7-november-2026)). |
| `tools/language_check.gd` | Kept | Six exceptions for deleted files removed. |
| `docs/evidence/world_expansion/verify.gd` | Retired | Rebuilt the Oct 2026 expansion from `town_complete.tscn`; 23–37 known failures; wrote into `docs/`. |
| `docs/evidence/town_upgrade/verify.gd` | Retired | Already unusable (read a removed backup and hung). |
| `check_building_exteriors.gd` | Retired | Ran the exterior pass on `town_complete.tscn` (known failure); facades are covered by `check_map_facades.gd` and the per-building exterior checks. |
| `docs/evidence/exterior-audit-20261025/check_map_facades_transformed_probe.gd` | Retired | Probe of the deleted exterior pass. |
| `docs/evidence/supermarket-color-20261026/check_supermarket_exterior.gd` | Retired | Dated copy of `docs/check_supermarket_exterior.gd`. |
| `migrate_v27_source.py` | Retired | One-off v27 migration from `/mnt/data`. |

Dated evidence in those folders (PNGs, logs, results) is kept.

**Verification** (each check once, `VT_FOCUS=all`, `VT_SPAWN=none`, isolated `HOME`, headless;
labels compared with the last records, not exit codes):

| Check | Result |
| --- | --- |
| Script parse (all 125 scripts under `scripts/` plus the edited checks and tools) | 0 errors |
| `check_runtime_resources` / `tools/language_check` | 384 resources, 0 failures / PASS 2,988 |
| `check_compact_layout` | 642 checks, 0 failures (fewer: the retired old-world comparisons) |
| `docs/evidence/part2/verify` | 1,304 checks, 3 failures: the known `drive clearance Home garage drive 21` ×3; parking now 14 and passes |
| `check_public_garden` / `check_park_terrain` | 0 failures, 1,815 path samples / 0 failures, 470 elevated samples, peak 1.375, monument 1.110: the same figures as the analytic grading, so the saved mesh reproduces it |
| `docs/evidence/barn-20261101/verify` | 56 checks, 0 failures |
| Police: detective / interior / officer | 115 / 216 / 15 checks, 0 failures |
| `check_map_facades` | 4 failures, the labels recorded on 1 Nov (19 fronts, door clearance, HOSPITAL and FURNITURE street rays) |
| `check_rooftops` | Still broken as recorded on 28 Oct: crashes on the missing `HouseStructure/HomeRoof` (stopped after 103 s), plus 17 roof, helicopter-part and home-roof failures before that |
| Snapshot checks (Oct 25–26 fingerprints, re-baselined 4 Nov): `check_building_dimensions`, `check_school_exterior`, `check_supermarket_exterior`, `check_cafe_bank_exteriors`, `check_market_interior`, `check_school_partition` | 265 / 90 / 29 / 28 / 149 / 71 failures: walk-path samples and "preserved" fingerprints that later approved work changed (restaurants, police, school contents); not caused here, since the saved scenes and the load path are unchanged. Not traced |
| `tools/bake_unit.gd -- police` round trip | Saved; node dump against the original: 1,838 vs 1,838 nodes, 0 differences (the unit now carries an empty `applied_steps`); the original file was put back |

Not run: the rest of the suite (vehicles, aircraft, hospital, seats, interaction) and rendered
views: no saved scene and no runtime code on their path changed beyond the deleted branches
(the game boots through the same modular path as before; every check above loads it). Known
warnings unchanged: costume pieces "owner inconsistent" during unit load (since the sculpt cache;
fixed 7 Nov 2026: restored pieces drop the cache holder's owner, like built ones).

Open after the removal:
- ~~**P2** Animals that wander onto park slopes lost their ground-following callback with the
  modular bake (phase 1; a scene cannot save a lambda).~~ Fixed 6 Nov 2026: the zoo animals
  also had no wander setup at all (only the deleted pass called `configure()`); `park_animals.gd`
  now configures them at load and follows the saved park ground, see
  [animal system](ANIMAL_SYSTEM.md#verification--6-november-2026).
- **P3** `check_animals`: `Fitted picking` fails for all ten crabs (eight mainland, two island;
  found 6 Nov 2026); their saved picking box no longer matches their visible bounds. Not traced.
- Fixed 6 Nov 2026 (risk review): in focus mode, standing on the empty school or hospital plot
  made `reference_world_layout.gd::location_name()` call `get_node()` on the missing building
  every lookup; it now uses `get_node_or_null()`. Probe with only `chapel` loaded: no errors,
  plain names ("School · Floor 2"); full town names unchanged.
- ~~**P2** No bake for the base world (garden, zoo, roads, vehicles); change it in the editor.~~
  Done 6 Nov 2026: `bake_unit.gd -- base` with `scripts/buildings/base.gd`
  ([changing the base world](#changing-the-base-world), [record](#base-world-bake--6-november-2026)).
- ~~**P3** Decide whether the six snapshot checks and `check_rooftops` are still worth keeping.~~
  Done 7 Nov 2026 (user): the six were retired; their uncovered parts live on in
  `check_building_access.gd` ([record](FINAL_VERIFICATION.md#snapshot-checks-retired--7-november-2026));
  `check_rooftops` stays.

## Verification record

### Phases 1 and 2 — 6 November 2026

All runs: `dev_focus.txt=all` (full town) unless stated, isolated `HOME`, Apple M5, Godot 4.7.2.
Baseline = commit `73fca2b` (old pipeline), each check once; modular = after the bake.

| Check | Baseline | Modular |
| --- | --- | --- |
| `check_runtime_resources` | pass, 413 resources | pass, 418 (the new scenes and scripts) |
| `tools/language_check` | PASS 2,988 | same |
| `check_compact_layout`, `check_public_garden`, `check_helicopter_physics`, `check_hospital_departments`, `check_interaction` | pass | same |
| `check_vehicle_boarding` / `check_vehicle_doors` | 73 / 138 checks, 0 failures | same |
| `check_road_physics` | 153 checks, 0 failures | same (speed figures differ in the last digits) |
| `check_aircraft` | 30 checks, 4 known failures | first run 5 (new: "wingtip sweep catches obstacle", sweep hulls not saved) → fixed in `turboprop.gd`; rerun: the same 4 failures |
| `check_seats_and_swan_boats` | 1 known failure (airport seats 37/39) | first run 2 (new: swan boat would not move, its `town` was null) → fixed in `swan_boat.gd`; rerun: the same 1 failure |
| `check_zoo_vehicles`, `check_hospital_remodel`, `docs/evidence/part2/verify` | 5 / 1 / 4 known failures | same labels |
| `docs/evidence/police-detective-20261106/verify` | 4 failures of 115 (all "accusing nobody asks to choose first"; rounds are random) | 0 failures of 114; random rounds, not traced |
| `check_vocabulary_categories.py` / `check_vocabulary_translations.py` | known failures | same |

- **Node parity** (scratch dump of every node: path, class, script, child count, position,
  mesh/text/shape): ignoring positions, the only difference is the random restaurant customer;
  position differences are the wandering crabs.
- **Rendered views** (one batch, old vs new, 19 views: building fronts, Alta Cocina inside and
  posters, police lobby and evidence room, lagoon, airport, barn, warehouse): identical apart from
  moving animals and characters (largest: Alta Cocina posters, 0.23 % of pixels).
- **Focus** `restaurants, police`, `spawn=police`, windowed 1280×800: loads 2 of 18 units, 27,300
  nodes (full town 71,000); the player spawns at the police door with a translated sign, the
  officer inside, and a working minimap. Five warnings name the missing staff of unloaded
  buildings (supermarket, family, flight, warehouse sessions), as designed.

| Boot (6 Nov 2026) | Old pipeline | Modular |
| --- | --- | --- |
| Headless, full town | 16.0 s | 8.5 s |
| Headless, `restaurants, police` | 7.5 s | 4.0 s |
| Windowed to first drawn frame, full town | — | 11.5 s (Main `_ready` 7.1 s) |
| Windowed to first drawn frame, `restaurants, police` | about 11 s | 7.1 s (engine 0.4 s, scene load 0.9 s, Main `_ready` 2.9 s, first frame 3.0 s) |

Limitations and next priorities (corrected the same day: the first frame was 3.0 s, not 4.2 s,
and the render comparison had 19 views, not 24; the boot follow-up below addressed the 7 s):
- **Low:** the missing-staff warnings could be silenced when the unit is simply not loaded.
- Phase 3 (retire the old passes, per-building scripts and a one-building bake) is not done;
  until then a change to a retired pass only shows after a full rebake.

### Boot time follow-up — 6 November 2026

User request: cut the remaining boot time. Measured inside Main's `_ready` (focus `restaurants, police`): the units' 1.7 s and the
player's 0.7 s were almost all **plush characters sculpting their meshes in GDScript (1.5 s)
and costumes measuring their wearer and building garments (0.8 s)**. Of the 3.0 s first frame,
about 0.9 s was **46 character Shader objects for only 7 distinct shader codes**, each
compiled separately.

Change ([`sculpt_cache.gd`](../../scripts/characters/sculpt_cache.gd)): one shared Shader per code
for every character, and the finished sculpt / costume (meshes, the wearer parts a costume hid
or reshaped, and the script variables the build set) kept in `user://sculpt_cache/` and reused
on the next launch. The key hashes the script chain's source, the outfit data, every script
variable and the parts' transforms, so edits rebuild automatically; never used in the editor;
`VT_SCULPT_CACHE=0` turns it off. Two fixes it needed: `plush_sculpt.gd` passes `part_to_root`
as a `Projection` (a `Transform3D` value for the `mat4` uniform was lost when saved: the cat's
colour points vanished), and `golden_sculpt.gd`'s coat colour is a named method like the other
coats (a lambda cannot be kept). `pig_sculpt.gd` is untouched.

| Windowed to first drawn frame (isolated `HOME`) | Before | Cache filled | Cache warm |
| --- | --- | --- | --- |
| `restaurants, police` | 7.1 s (`_ready` 2.9 s, first frame 3.0 s) | about 5.9 s | **3.9 s** (`_ready` 0.7 s, first frame 1.8 s) |
| Full town | 11.5 s (`_ready` 7.1 s) | 9.6 s | **5.4 s** (`_ready` 1.9 s) |

Cache size: about 58 MB for the full town (42 entries; a dressed character's garments are
about 125,000 vertices). Deleting the folder is always safe.
Restored script variables keep their declared type (7 Nov 2026): a typed array such as the
sculpt's `_body_profile` used to come back untyped, `set()` silently kept the pig default, and
code that asks a restored character for its shape (`_front_z`, `_section`) got the pig's body;
the lineup suspects' hair and beards were fitted to it.

Checks (each once, cache on unless stated, `VT_SPAWN=none`):
- Character dump (every mesh of all 38 sculpted characters: vertex/index data, every shader
  parameter, transform, visibility, shadows), cache off vs warm: identical apart from the random
  restaurant customer. The first runs of this dump found the two bugs above and a third (a tail a
  town pass hid came back visible; only the fields a build changes are restored now).
- `check_plush_costumes.gd`: 572 checks, **0 failures** both filling and with a warm cache
  (9 s instead of 32 s). Its house-character part had stopped at a script error since `20faa87`
  added the `Bedtime` helper under `HouseCharacters` ("Nine Home plushes" failed); the check
  now counts only the 3D characters.
- `docs/evidence/police-detective-20261106/verify`: 115 checks, 0 failures (suspects with random hair are
  built normally, not cached). An earlier run picked up `spawn=police` from `dev_focus.txt` and
  failed only "door approach lane is clear", as recorded in FINAL_VERIFICATION; not counted.
- `check_seats_and_swan_boats`: the 1 known failure (airport seats 37/39).
- `check_runtime_resources`: 419 checked, 0 failures.
- `docs/evidence/clothing-interior-20261028/verify`: 1 failure of 130, "centre lane x=-1.4 z=-2", **the same
  with the cache off**, so not caused by it. Not traced (priority: low; the record's last run had
  a different single failure, at the moved checkout counter).
- Views (19, warm cache vs before): police views identical (0.00 %); the rest differ by at most
  0.37 % of pixels, in views with wandering animals.

Still open (priority low): the first frame's remaining 1.8 s (about 1.1 s even with the town
hidden: UI and the player, most likely StandardMaterial3D shader variants).

### Phase 3 — 6 November 2026

- **Round trip:** `bake_unit.gd` re-saved all 18 units with no steps; a node dump (path, class,
  script, child count, position, mesh/text/shape) before and after is identical apart from the
  random restaurant customer and the wandering crabs' positions. Each file grew only by the
  empty `applied_steps` meta; the originals were kept (no binary churn).
- **Step test** (temporary `scripts/buildings/police.gd` adding a box, then removed and
  `police.scn` restored): first bake applied it, a second bake skipped it, the box loads at its
  place with focus `police`, and the full bake then refused with the message above.
- **Loader owner change:** focused boot 3.9–4.6 s to the first frame (Main `_ready` 0.71 s, as
  before); `docs/evidence/police-detective-20261106/verify` 114 checks 0 failures, `check_vehicle_doors` 138
  checks 0 failures. No game code reads `owner` or uses `find_child()`'s default.
- Not re-run: the rest of the suite (no change to their subjects beyond the owner of loaded
  nodes).

### Base world bake — 6 November 2026

Task (from the risk review): a code bake for `scenes/town/base.scn`, so outdoor and layout changes
work like building changes. Added `bake_unit.gd -- base`, `scripts/buildings/base.gd` (no steps),
`reference_world_layout.gd::bake_state()` (brought back from `a5059dd`), `tools/compare_scenes.gd`,
and the runtime-built drop, saved `unit_index` and crab `home` rules
([changing the base world](#changing-the-base-world)). Runs: Godot 4.7.2 headless, isolated
`HOME`, `VT_FOCUS=all`, `VT_SPAWN=none`, `dev_focus.txt=all`.

| Check | Result |
| --- | --- |
| Round trip, no steps: `-- base` + all 18 units in one bake (8 s), each scene compared with a copy | 18 of 19 scenes 0 differences (empty `applied_steps` only). `base.scn`: 10 differences, the crabs' `display_size` meta (saved values from the deleted pass; `crab.gd` sets (.62, .4, .4) at every load, so the game is unchanged). `hospital.scn`: the saved rotor blur and its pick (3 nodes) dropped as runtime-built (`driveable_vehicle.gd` replaces it at every load). The first run also showed `unit_index` drift on 13 units and the crabs' wander positions; fixed as above. Originals put back (no binary churn) |
| Step test (temporary `base.gd` step: a bench beside the Washington statue, a 20 m lane in `roads`, a `TEST BENCH` map entry; then removed and `base.scn` restored) | Applied once (29 differences: 17 bench nodes, the root's metas, `applied_steps`); a second bake skipped it (0 differences against the first); in the game the bench loads, roads 20 → 21, entries 24 → 25 with the bench node; the helicopter has one rotor blur with its pick |
| `check_runtime_resources` | 385 checked, 0 failures |
| `check_compact_layout` | 642 checks, 0 failures |
| `docs/evidence/part2/verify` | 1,304 checks, 3 failures: the known `drive clearance Home garage drive 21` ×3 |
| `check_public_garden` | 0 failures, 1,815 path samples |
| Focus probe, only `chapel` (1 of 18 units, 16,977 nodes) | Loads; 12 map entries, 20 roads; the empty school plot reads "Central Park"; only the six designed missing-staff warnings |

Not run: the rest of the suite and rendered views: the saved scenes are unchanged and the only
runtime code change is the added `bake_state()`. Next base bake will also write the two harmless
normalizations above (crab `display_size`, no saved rotor blur) into `base.scn` / `hospital.scn`
(*done* by the [palette bake](#material-palette-bake--6-november-2026)).

### Building address book and dead-code sweep — 6 November 2026

`modular_town.gd::building()` replaces the literal building paths in runtime code (Main, minimap,
`reference_world_layout.gd`, warehouse and police detective sessions, `house_characters.gd`;
[how](#finding-a-building-at-runtime)); node paths and saved scenes are unchanged. Dead code
removed: `warehouse.gd` 974 → 467 lines (`build()`, exterior, reception, posters, stock, goods
helpers and their constants), `school_posters.gd`, and ~395 lines of Main (the original
neighbourhood builders, `piece()`, `add_ceiling_light()`), all with no caller (checked with `rg`
over `scripts/`, `tools/`, `docs/` and scene signal connections). Comments naming deleted passes
as if they ran were rephrased.

Each check once, isolated `HOME`, `VT_SPAWN=none`, full town unless stated (dev focus `all`):

| Check | Result |
| --- | --- |
| Load of all 302 scripts under `scripts/`, `tools/`, `docs/` | 0 failures |
| `check_runtime_resources` / `tools/language_check` | 384, 0 failures / PASS 2,988 |
| `check_compact_layout` | 642 checks, 0 failures |
| `docs/evidence/part2/verify` | 1,304 checks, 3 failures: the known `drive clearance Home garage drive 21` ×3 |
| `docs/evidence/police-detective-20261106/verify` | 115 checks, 0 failures |
| `docs/evidence/warehouse-20261105/verify_game` (exercises `build_copy()`) | 129 checks, 0 failures |
| New `check_building_lookup.gd`, full town | 18 of 18 units; every part resolves; 17 sites named; minimap rebuilt, journal toggled; 0 failures |
| Same, `VT_FOCUS=chapel` (1 of 18 units) | absent units give null; the 17 sites read plain names ("School · Floor 1"); no script errors, only the six designed missing-staff warnings |

The probe ran with one extra call (an unknown unit key, which logs the intended script error);
that call was then removed from the check. Not run: rendered views (nothing visible changed), the
rest of the suite. Kept and listed rather than deleted (unused, but small API helpers unrelated
to the deleted passes): `police.gd::mirror_direction()`, `garage_door.gd::track_length()`,
`flags.gd::has_flag()`, `vocabulary_hud.gd::is_word_bookmarked()` / `is_bookmarks_open()`,
`live_labels.gd::language_for_mode()`, `detective_clues.gd::words_of()`,
`evidence_props.gd::kind_for_word()` / `shelf_look()`, `family_tree.gd::parse_date()`; the
`copy` branches in `warehouse.gd` (always true now); `natural_town_layout.gd` (helper library for
steps). Site pivots (`RelocatedSites/<site>`, keyed by layout site name) stay with
`reference_world_layout.gd`.

### Material palette bake — 6 November 2026

Task: identical materials were stored once per scene file (Main's `material_for()` cache was
town-wide, so splitting the town copied shared looks into every file). Added
`tools/material_palette.gd`, the palette step in `bake_unit.gd::save()`, material content in
`compare_scenes.gd` ([how](#material-palette)), and re-baked `base` plus all 18 units in one run
(Godot 4.7.2 headless, isolated `HOME`, `dev_focus.txt=all`, Apple M5, 13 s). Runtime code was
checked with `rg` for in-place material edits: none (see the rule above).

| Measure | Before | After |
| --- | --- | --- |
| StandardMaterial3D objects stored in the 19 scenes (node properties and the town's own meshes; prefab materials not counted) | 2,957 | 14 (unshareable: built-in texture or similar) |
| Palette files | — | 1,916 (268 KB text) |
| `scenes/town/` | 21,243,207 bytes | 21,024,379 bytes (plus the palette: about the same in total; the gain is one object per look, not disk) |
| Static batches at load (`render_culling.gd`) | 18,553 meshes in 3,562 batches | 18,753 meshes in 3,592 batches (shared materials batch across units) |

- **Scene comparison** (`compare_scenes.gd`, each scene against a copy taken before the bake):
  18 units and the base have identical node trees, classes, transforms, scripts, groups,
  metadata and material content. Only differences: the two normalizations the base bake record
  predicted (10 crabs' `display_size` meta in `base.scn`; the hospital's runtime-built rotor blur
  and its pick, 3 nodes, not saved).
- **Palette names:** every file reloads to its own hash (1,916 files, 0 mismatches), so later
  bakes reuse them. A second bake of `school` wrote no palette file and compared equal (0
  differences; bytes differ only in internal order, so the first file was kept).
- **Rendered views** (one batch, 1280×800, before vs after: town overview, shop street from above
  and at eye level, park/chapel, Alta Cocina inside): overview and street identical; the rest
  differ by 0.015–0.71 % of pixels, all at the random restaurant customer and small moving objects.
- **Full suite** (`tools/run_checks.py full`, once, 477 s; tree `1929dcf` plus this work): 18 PASS,
  9 KNOWN, 5 NEW, 1 skipped (`check_rooftops`). The 5 NEW were the snapshot checks
  (`school_exterior` 95 vs 90, `supermarket_exterior` 30/29, `cafe_bank_exteriors` 44/28,
  `market_interior` 157/149, `school_partition` 92/71). The five were run once more on the
  pre-merge scenes (put back temporarily; user-approved): exactly the recorded counts. Label diff:
  every added label is a `... preserved <node>` fingerprint (fronts, interiors, school contents);
  no walk-path, pick, collision or door label is new (the runner's "NEW:" list named walk samples
  only because these checks are matched by count). The fingerprints include each mesh's `visible`
  flag, and `render_culling.gd` hides the ~200 more originals it now merges; material values are
  unchanged (scene comparison) and renders identical. `data/expected_check_failures.json` got a
  `" preserved "` entry per check (5 / 1 / 16 / 8 / 21); re-scoring both runs' logs with it: 0 NEW,
  0 FIXED.
- Incident: between the first (faulty, see below) bake and the final one, `materials/palette/` was
  deleted with `rm -rf`; the folder sync of `~/Documents` put 1,694 first-bake files back as
  `"<hash> 2.tres"` conflict copies. All were byte-identical to their originals, referenced by
  nothing, and deleted. Do not delete the palette folder to rebuild it; bakes overwrite in place.
  (The first bake saved dedup'd materials embedded in the scenes because `ResourceSaver.save()`'s
  `FLAG_CHANGE_PATH` only applies during the save; the tool now calls `take_over_path()`.)

### Bake exit errors fixed — 7 November 2026

`bake_unit.gd` printed errors after `BAKE UNIT: done` (seen since the Grammar Classroom bake):
1. `Invalid access to property or key 'position' on a base object of type 'previously freed'`
   from `crab.gd:64`, ten times, whenever the base was not among the baked units. The tool frees
   the nodes scripts built at runtime (each crab's `Body` mesh, 788 nodes in an airport-only bake)
   before saving, but the town kept processing until the process exited, so each crab's next
   `_process` touched its freed body. Harmless to the saved scenes. Fix: Main's root stops
   processing just before those nodes are dropped (it is not saved).
2. Godot's leak report at exit (ObjectDB instances, mesh / texture RIDs, `PagedAllocator`): the unit
   holders the tool builds outside the tree were never freed. Fix: freed after saving.

Verified by round trips: `-- airport` and `-- base chapel` with no pending steps now print nothing
after `BAKE UNIT: done`; the re-saved airport scene is node-for-node identical to the committed
one (all re-saved scenes were then put back to the committed files).
