# Current placement

> Historical implementation record. Use the [documentation map](../../README.md)
> for current guides; positions, counts and test results below describe this snapshot.

Soft Plush was selected. The front-yard comparison and original park pig have been removed. Six Soft Plush pigs now live inside the supermarket, library, bank, police station, hospital, and school. The giant rear-meadow landmark remains. The discarded Storybook and comparison scenes are backed up in `backups/pig_distribution_before/`. Original pig resources remain as dependencies of the giant and sculpt helpers.

All six placements passed visible-mesh clearance and vocabulary-selection checks and were inspected in Godot.

The following notes and images record the earlier design comparison.

# Pig character comparison

Three labeled characters are on the front lawn, west of the entrance path, facing the house. Viewed from the house: 1 Original, 2 Storybook, 3 Soft Plush.

- `scenes/characters/pig.tscn`: original, unchanged. Its `pig_sculpt.gd` is also unchanged, so the existing park and BonBons retain their appearance.
- `scenes/characters/pig_storybook.tscn`: art-inspired proportions, broad belly, small rounded-square ears, large rosy cheeks, domed snout with brown rim, tiny feet and brown silhouette outline.
- `scenes/characters/pig_plush.tscn`: deeper body, short outward-drooping mitten arms following the original illustration, softer dimensional shading, no silhouette outline.
- `scripts/characters/pig_art_variants.gd`: optional sculpt implementation. Reuses existing geometry helpers and corrects winding/normals locally.
- `scenes/characters/pig_comparison.tscn`: all three instances and numbered labels; placed in `scenes/world/town_editable.tscn` at (-3.2, 0.02, 17.2).

Original town layout backed up in `backups/pig_options_before/town_editable.tscn.bak`.

Validation: full main-scene instantiation, generated mesh presence, grounded feet, character scale and vocabulary-selection raycasts passed for all three. Project reference checks reported zero errors and warnings. Rendered lineup and oblique views inspected. Original scene and sculpt SHA-256 hashes match their pre-edit values.

The previews show the actual game's lighting and color grading.

Soft Plush refinement: replaced oval arms with sculpted curved mittens and tucked their roots into the body. Both cheeks now share a slightly stronger pink with directional shading disabled, giving equal color on both sides. Front and oblique renders inspected; scene, bounds and selection checks passed. See `plush_refined_front.png` and `plush_refined_angle.png`.
