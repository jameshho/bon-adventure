# Home and navigation refresh — October 17, 2026

> Historical implementation record. Use the [documentation map](../README.md)
> for current guides; positions, counts and test results below describe this snapshot.

Open `project.godot` and run `scenes/main.tscn`. The active world is saved in `scenes/world/town_complete.tscn`, so no manual rebuild is required.

## Implemented

- Reusable sofa with separately editable frame, backrest, arms, three seat cushions and two pillows, facing the television. Removed armchair, footstool, excess plants and paintings, welcome plaque, wall hooks and awkward sill.
- Hollow kitchen drawer cabinet with two trays, handles and utensils. E uses the existing smooth slide animation; trays have clear space inside the cabinet and through their outward travel. Upper cupboards retain their hinge interactions.
- Distinct rice, pasta and cereal packages with labels and modeled grains, spaghetti and flakes.
- Repositioned bedside furnishings, added reusable lamps with bases, stems and shades, aligned reusable pleated curtains with the three windows, and cleared bedroom entrances.
- Reusable acoustic guitar with shaped bouts, sound hole, neck, fingerboard, headstock, six strings, frets, tuning pegs and stand. Freestanding entrance coat rack and three folded umbrellas in an open stand.
- Car aligned along the driveway, driver beside the door facing the car. Garage moved back enough to clear the rear bumper; sidewalk remains open.
- Three low-poly reusable tree species: apple, orange and autumn maple. Fifteen instances replace generic trees; unnecessary hedges removed.
- Café moved to (-61, 0, 76), near electronics and the west road. Cook, quest destination, room identification, entrance path and full-screen map moved with it. Removed the former long café path and routed the west beach path around the new building.
- Top-left 208×208 minimap, updating at 30 Hz. Player stays centered with an upward arrow; actual town meshes and building transforms supply the map geometry. Roads, sidewalks, paths, coastline, pond, buildings and zoo pens are represented. Controls moved below it.
- Exterior vocabulary metadata now survives procedural rebuilds, and repeated setup no longer duplicates exterior picking areas. Umbrella vocabulary added; fish asset's cached Spanish metadata synchronized with the existing dictionary.

## Main files

- `scenes/props/home/`: sofa, drawer_cabinet, bedside_lamp, guitar, umbrella_stand, coat_rack, curtains, rice, pasta, cereal scenes.
- `scenes/props/nature/`: apple_tree, orange_tree, maple_tree scenes.
- `scripts/world/home_refinement.gd`: idempotent placement/cleanup pass used when rebuilding.
- `scripts/ui/town_minimap.gd`: cached map geometry, live player projection and drawing.
- `scripts/core/main.gd`, `scripts/ui/vocabulary_hud.gd`: integration and HUD placement.
- `scripts/world/compact_home.gd`, `natural_town_layout.gd`, `building_exteriors.gd`: garage clearance, café approach and durable exterior picking.
- `scenes/world/town_editable.tscn`, `town_complete.tscn`: source placements and active saved world.
- `scripts/learning/learning_quests.gd`, `data/vocabulary*.json`, `assets/maps/town_map.png`.
- `tools/build_home_assets.py`, `scene_writer.py`, `update_town_map.py`: reproducible asset/map generation. Hospital generator now imports the shared scene writer.

To regenerate furniture: `python3 tools/build_home_assets.py`. To rebuild the active world after procedural/source changes: `Godot --headless --path . --script tools/bake_editable_town.gd`. Scene instances remain editable directly in Godot. The minimap reads building transforms live; call its `rebuild()` after adding/removing buildings or changing road meshes during a running game. Normal game startup automatically rebuilds its cache.

## Verification

Passed with Godot 4.7.2:

- Project editor import, active scene load and world bake without parser/script errors.
- `check_home_refresh.gd`: two drawer animations and full tray sweep clearance, redesigned vocabulary physics picking, three tree species, car/garage separation, driver orientation, 45 café approach samples, four minimap headings, player centering and vocabulary coverage.
- `check_house.gd`: seven interior walking routes, four doors, drawer origins and fixtures.
- `check_town_layout.gd`: 163 park/beach route samples and ground support.
- `check_island.gd`: compact beaches, fifteen trees, home placement and civic windows.
- `check_vehicle_collision.gd`: eight vehicle types block movement from four sides and remain selectable.
- `check_interaction.gd`: targeting, highlights, cards, signals, doors and range.
- `check_building_exteriors.gd`: all twelve building types and bilingual picking.
- `check_learning_stores.gd`: 147 reusable assets loaded/ray-tested, eight saved doors, 101 learning objects.
- `check_zoo_upgrade.gd`: twenty independent animal assets, movement, picking and vocabulary.
- Hospital and school floor tests: real player climbs and descends both flights without jumping.
- Graphical inspection: `docs/evidence/home-refresh-review/` contains nine views covering interiors, open drawers, food, car/driver, café, trees and the minimap.

A short 120-frame graphical gameplay sample measured about 40 FPS at 1440×1000 on Apple M5/OpenGL compatibility. This is a smoke-test sample, not a guarantee across the whole town or other hardware. Minimap pose calculation averaged roughly 0.3 microseconds; drawing uses cached geometry and no additional 3D viewport. No known functional blockers remain. Sandboxed headless runs emitted the existing macOS certificate-store warning; the authorized editor import and graphical runs were clean.

Backup before changes: `../backups/comprehensive_before.zip` (project scripts, scenes, data, tools, map, docs and configuration).
