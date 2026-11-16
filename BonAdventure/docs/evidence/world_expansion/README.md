# Reference map layout pass — 19 October 2026

> Historical implementation record. Use the [documentation map](../../README.md)
> for current guides; positions, counts and test results below describe this snapshot.

Open `project.godot` in Godot 4.7 (verified with 4.7.2) and run the main scene. Press M for the updated map. The expanded world is saved in `scenes/world/town_reference.tscn` and appears directly in the editor.

## Layout and reuse

The new island uses 0.30 local world units per reference pixel, with the existing uniform 1.30 town-to-world scale. Its reference positions, coastline, road loop, and spawn are recorded in `data/reference_layout.json`. The two-lane loop is 10.8 local units wide with a 16-unit sidewalk corridor. Airport access, apron, taxiway, and runway connect to that network; building access routes and parking occupy separate space.

Existing hospital, school, furniture, clothing, electronics, bakery, sports, home, library, supermarket, bank, police, and chapel assets are retained. Existing interior meshes, materials, furniture, door origins, vocabulary associations, animals and animations, vehicle scripts, and save keys are preserved. The sports shop, absent from the reference illustration, remains in the northwest civic district rather than being deleted. The previous low cloud remains removed.

Wild and farm animals use their existing models in enlarged, separated enclosures. The original wild gate remains; the farm entrance reuses the same gate scene and E interaction. The pond, bridge, gazebo, playground equipment, benches, trees, signs, lights, transport vocabulary hub and parked vehicles are relocated rather than rebuilt.

Only four new modular exterior scenes are introduced: airport terminal/control tower, three restaurant shells, a farm barn, and a basic Washington statue. New shells have open entrances and empty space. No furnished interiors, detailed textures, new driving systems, or airplane gameplay were added.

## Orientation from the house

Facing out from the home entrance toward town (+Z), west is on the left (+X) and east is on the right (−X). The Washington statue is physically left/front of home, and the airport is to the right. The atlas and rotating minimap use the same orientation. The player and camera now initially face town. These relationships are covered by regression checks.

The manifest keeps its reference-image coordinates; the layout layer converts their horizontal positions into this physical frame. Buildings and their interior contents move as intact groups, without negative scales or mirrored interiors. Reflected terrain geometry has corrected triangle winding and collision faces.

## Editing and regeneration

`scenes/main.tscn` now references the new snapshot. All 499 other pre-existing scene files, including every original building scene and `town_complete.tscn`, are byte-for-byte unchanged. Generated furniture that originally lived outside its building is grouped under `RelocatedSites/<site>`; authored building instances retain their `Buildings/...` paths.

To change the layout consistently, edit the manifest and matching road/path definitions in `scripts/world/reference_world_layout.gd`, then rebuild from the preserved original:

```sh
godot --headless --path . --script res://tools/bake_reference_world.gd
```

The bake preserves scene instances and their editable overrides, including vocabulary pick areas. At startup the snapshot is bound to quest destinations, room detection, map geometry, spawn and gates without rerunning the original content builders. Existing progress and quest save formats are unchanged.

## Verification

```sh
godot --headless --path . --script res://docs/evidence/world_expansion/verify.gd
godot --headless --path . --script res://docs/evidence/town-checks/check_runtime_resources.gd
```

The layout suite completed 1,067 checks with zero failures. It compares the preserved original against the relocated runtime and the saved snapshot, checks all original vocabulary associations and door registries, building scales and separation, land support, entrance clearance, vehicle-sized loop clearance, driving, animal animation anchors, both gates, road connectivity, runway land containment, and quest coordinates. The resource scan loaded all 560 runtime scenes/scripts successfully. The saved snapshot retains the same mesh and collision counts as the runtime build.

`results.txt` contains the detailed checks. `baked_map.png` shows the map loaded from the saved scene; `map_default.png` shows the normal 1280×720 window. Historical checks elsewhere in `docs/` describe the earlier small island; use this suite for the expanded world.

## Remaining work

This is a functional layout foundation, not an exact architectural replica of the illustration. Existing building dimensions and interiors are intentionally retained; some site proportions therefore differ. Airport operations/aircraft, restaurant and barn interiors, detailed statue artwork, dense landscaping, and exterior polish remain future work. No known layout-blocking or resource-loading failures remain in the checks above.
