# Building exterior repairs

> Historical implementation record. Use the [documentation map](../README.md)
> for current guides; positions, counts and test results below describe this snapshot.

For future façade designs and improvements, use the shared
[building design blueprint](../guides/BUILDING_DESIGN_BLUEPRINT.md). This document records
the earlier exterior repair implementation.

Removed the blank entrance boards, redundant lot signs and trim that obscured civic building names from the saved town and procedural construction. Main facade lettering is centered in front of its panel. Existing shop, school and hospital signs were reviewed in rendered views.

Exterior surfaces across all 12 building types carry `exterior_word` metadata. `building_exteriors.gd` adds non-solid picking areas to the actual meshes, preserving open entrances. The interaction controller shows English and Spanish together on hover and permits building picking from 40 world units away. Furniture keeps its existing 8-unit interaction range and vocabulary.

Validation:

```sh
godot --headless --path . --script res://docs/check_building_exteriors.gd
godot --headless --path . --script res://docs/evidence/town-checks/check_interaction.gd
```

The exterior check verifies removed signs, facade label placement, all building vocabulary coverage, front-facing physics rays, bilingual hover and unobstructed doorway picking. Add `-- --capture` without `--headless` to render facade review images.
