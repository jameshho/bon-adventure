# Pastel trial — 25 Nov 2026 (P3-22, P3-23; decision D14: try, show before/after, user decides)

**Status: rolled out 26 Nov 2026 (user: "Roll out both").** Branch `claude/pastel-f9b9c5`.

## Rollout — 26 Nov 2026

- Step `palette_snap` (hue-guarded) baked into the other 17 units (all 19 now): home 1074 surfaces / 40
  colours, restaurants 849 / 80, airport 614 / 109, mystery 1486 / 15 (its purple and gold stay;
  colour posters and the doors' game colours are untouched), hospital 8 / 3 (almost all prefabs).
- Base step `pastel_ground` (49 road and paving meshes, 6 materials) and the new grass and sand
  values in `shaders/grass.tres` / `sand.tres`.
- `compare_scenes.gd` against the scenes before the bake (all differences printed): node counts
  equal except home (the record player's model and collider, which `record_player.gd` rebuilds at
  every load, were dropped as runtime-built); every other difference is a material, except the
  staff NPCs' runtime `npc_id` meta and a few mm of drift (Dr. Li 0.65 m), which
  `npc_registry.gd` overwrites at every load.
- On-palette area by unit: [palette_report_before.md](palette_report_before.md) (after the
  library/police trial) → [palette_report.md](palette_report.md): home 51 → 93%, supermarket
  43 → 87%, warehouse 21 → 62%, mystery 14 → 45%, restaurants 41 → 61%, chapel 58 → 79%.
- Spot-check views (muted, noon): [rollout-home.png](rollout-home.png),
  [rollout-school.png](rollout-school.png), [rollout-mystery.png](rollout-mystery.png),
  [rollout-warehouse.png](rollout-warehouse.png), [rollout-ground.png](rollout-ground.png).
- Checks (`run_checks.py --only`, once, `dev_focus=all`): PASS runtime_resources, part2,
  public_garden, park_terrain, barn, police_interior, warehouse, police_detective,
  warehouse_game, mystery_house, library_shelves, library_sorting, hospital_remodel, bank_rework,
  grammar_class (15). Not finished, stopped at the user's request (26 Nov): building_access,
  world_signs, signs, map_facades, rooftops, hen_house, fitting_room, bath_fixtures,
  electrical_box.

## Trial

**26 Nov 2026 (user): "Add hue guard first".** `MaterialPalette.compatible()` now lets a colour
match only a palette colour within 20° of hue (when both have colour) that adds at most 0.04 of
chroma, so a grey stays grey. The first bake was undone and both units baked again with the guard:
library 25 colours on 204 surfaces, police 40 colours on 184 surfaces (20 / 30 left as they were);
`compare_scenes.gd`: same node counts, 207 / 185 differences, every one shown a material. Area on
the palette after the snap (report rerun): library 32% → 80%, police 32% → 61%. Views:
`guarded-*.png` (same cameras, muted run). Navy and slate stay; the snap now mostly warms
grey-white walls to cream and merges near-duplicate colours. The `after-*.png` views and the
notes on round 1 below are from the unguarded snap.

## What was tried

- **Report** (`tools/palette_report.gd`, helpers in `tools/material_palette.gd`):
  [palette_report.md](palette_report.md). Every plain colour in each town scene, weighted by
  mesh-box area, clustered in OKLab (0.04) and measured against `scripts/core/game_palette.gd`.
  Library and police were picked: about a third of their area is on the palette, and about 95% of it
  can be recoloured by a step (no prefabs).
- **Building snap** (`scripts/buildings/palette_snap.gd`, step `palette_snap` in `library.gd`
  and `police.gd`, both baked): each plain colour within 0.06 OKLab of a palette colour becomes
  that colour. Word roots of the "Building Parts" category are recoloured too (their keys stay the same).
  Other word roots, prefabs, characters, glass, lights and textures are left as they are. Library: 31 colours
  on 227 surfaces; police: 54 colours on 257 surfaces; 14 / 17 colours further than 0.06 were left as they were.
  `compare_scenes.gd`: same node count (1732 / 1724); every difference shown is a material
  (230 / 258 differences in all; the tool prints the first 40).
- **Ground tones** (in memory only, `render.gd` `PASTEL_GROUND`): grass, sand, road and paving
  lighter and softer. Not written to `shaders/grass.tres` / `sand.tres` or to the road and paving
  materials stored in `base.scn` yet.

## Views (same camera spots; noon; `render.gd`)

| Subject | Before | After |
| --- | --- | --- |
| Library (4 corners + 2 inside) | [before-library.png](before-library.png) | [after-library.png](after-library.png) |
| Police (4 corners + 2 inside) | [before-police.png](before-police.png) | [after-police.png](after-police.png) |
| Ground (raised views of both lots) | [before-ground.png](before-ground.png) | [after-ground.png](after-ground.png) |
| Round 2, hue guard | same before views | [guarded-library.png](guarded-library.png), [guarded-police.png](guarded-police.png), [guarded-ground.png](guarded-ground.png) |

## What was visible in round 1 (no guard)

- Walls: grey-white becomes a warmer cream (library outside, police inside).
- **Hue jumps:** a nearest-colour snap turns the library's slate roof and the police station's navy
  trim, roof and vault door **teal** (`INK` / `INK_SOFT` are the palette's nearest dark blues).
  The sky-blue family (`sky 2` 2a6aa8) is further away. Possible fix if wanted: a hue guard (snap
  only within about 20° of hue), which would keep navy and slate as they are.
- Ground: the grass turns brighter and more yellow-green, the sand pale, the paving lighter, the roads a little lighter.
