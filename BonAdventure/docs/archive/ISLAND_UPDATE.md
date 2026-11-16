# Compact beach island

> Historical implementation record. Use the [documentation map](../README.md)
> for current guides; positions, counts and test results below describe this snapshot.

The active level is `scenes/world/town_complete.tscn`, rebuilt from `town_editable.tscn` and the procedural builders.

- Removed the BonBon and its separate rear meadow from both the source and active town. Small pigs and zoo animals remain.
- Moved the home six local meters toward Main Street, including its furnishings, lights, doors, drawer origins and player spawn. Shortened the front lawn/path/driveway and moved the garage forward four meters. Home HUD labels and the home quest destination follow the move.
- Replaced the large oval mainland and woodland with a compact contour around the occupied town, a continuous eight-meter beach band, coastal shallows and open ocean. Added three beach approaches. Falling off the coast returns the player to the home porch.
- Reduced reusable town trees to 15. Removed woodland clusters and artificial perimeter hills.
- Hospital facade and side windows now use transparent glass with solid collision.
- School now has three furnished floors: classrooms/office/reading/math, science/geography/laboratories/technology, and art/music/creative rooms. It uses switchback stairs, colored floor signs and an entrance directory. Its existing rear learning wing remains connected.
- Updated the in-game map to show the island, beaches, relocated home and zoo.

Authoring: `tools/build_hospital_floors.py` writes the hospital; run with `--school` to write the school. Then run `tools/bake_editable_town.gd` to rebuild the active town from its source. `scripts/world/compact_home.gd` is idempotent via saved metadata, so loading the baked town does not move the home twice. Regenerating overwrites generated scenes, so preserve manual editor edits first.

Validation: `docs/evidence/town-checks/check_island.gd` checks island bounds, beach support, removal of the BonBon, home position, tree count and transparent windows. `docs/check_hospital_floors.gd -- --school` walks the real player up and down the school stairs without jumping. House checks use coordinates relative to HouseStructure. Civic, zoo and town-route checks cover retained learning interactions and paths. Screenshots are in `docs/evidence/island-review/`.
