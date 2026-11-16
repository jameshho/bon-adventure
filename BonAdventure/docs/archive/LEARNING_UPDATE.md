# Vocabulary learning update

> Historical learning-update snapshot. Counts, `town_complete.tscn` ownership and
> rebuild commands below describe that phase. For the current world, runtime passes
> and safe editing workflow, start with the [README](../../README.md). Do not run this
> older rebuild sequence as a normal Part 2/world edit.

Open `project.godot` in Godot 4.7, then run `scenes/main.tscn`.

The church and clinic annex have been replaced by walkable sports and furniture shops. The corner café is now a walkable bakery and café. The other buildings, house, NPCs, pigs, vehicles, park, controls, vocabulary journal and saved progress remain.

| Learning area | Individually placed vocabulary objects |
| --- | ---: |
| Sports | 16 |
| Furniture | 16 |
| Bakery and café | 16 |
| Electronics | 16 |
| Supermarket | 20 |
| Clothing | 17 |

147 reusable object scenes live in `scenes/props/vocabulary/`. These include the shop inventory and recognizable replacements for existing school/hospital props: microscopes, notebooks, pencils, a globe, wheelchairs, crutches, IV stands, stethoscopes, medicine, thermometers and bandages. Existing house and civic models are retained in the editable level.

Each new prop contains named mesh parts, one vocabulary root, an `Interaction/Shape` area, English/Spanish/category metadata and, where appropriate, a physical footprint. Strings, spokes, handles, controls, appliance doors, furniture legs and cushions are geometry. No downloaded textures or external assets are required. Clickable bounds remain separate between neighboring inventory objects. Displays face the aisle; smaller items are raised for visibility. The canonical popup/journal vocabulary includes noun articles.

## Editing

`scenes/world/town_complete.tscn` is the complete, editor-visible town used by Main. It contains the previously procedural objects as saved nodes. Open individual building scenes to move inventory instances, or open a vocabulary prefab to edit its named mesh parts. Right-click an instance and enable Editable Children when needed. Moving a prop root moves its mesh and colliders together. Keep the town's inherited scale of 1.3.

Door/drawer states are serialized in `door_state` metadata and restored by Main. Collider references use relative node paths instead of live Object metadata. Existing click, hover highlight, popup, language switch, journal, mission and door animation behavior is preserved. New sports, furniture and bakery missions and the M-key map use the new layout.

The complete scene is authoritative for normal editor work. `town_editable.tscn` and the procedural builders remain source inputs for an explicit rebuild. Do not run the rebuild after manually editing the complete scene unless you intend to replace those level edits.

## Rebuilding generated assets

From this project directory:

```sh
python3 tools/build_learning_assets.py
python3 tools/upgrade_civic_props.py
python3 tools/expand_civic_wings.py
python3 tools/add_vocabulary_articles.py
python3 tools/update_town_map.py
godot --headless --path . --script res://tools/bake_editable_town.gd
```

The Python asset generator overwrites its generated inventory layouts and prefabs; edit the generator for changes that must survive regeneration. Other level edits can be made directly in Godot without regenerating anything.

## Validation

Run with Godot 4.7:

```sh
godot --headless --path . --script res://docs/evidence/town-checks/check_learning_stores.gd
godot --headless --path . --script res://docs/evidence/town-checks/check_interaction.gd
godot --headless --path . --script res://docs/evidence/town-checks/check_town_layout.gd
godot --headless --path . --script res://docs/evidence/town-checks/check_house.gd
godot --headless --path . --script res://docs/evidence/town-checks/check_public_interiors.gd
godot --headless --path . --script res://docs/evidence/town-checks/check_park_bridge.gd
```

Verified: all 147 reusable props load and resolve through the real ray picker and Spanish popup; all 101 shop instances respond to click-to-study; neighboring target bounds do not overlap; six center aisles and doorways are clear; all eight serialized door/drawer animations work; 126 park path samples, eight public interior routes, seven house routes and the bridge walking test pass. Rendered shop views are in `docs/evidence/learning-review/`.

The school and hospital have since gained connected themed rear wings with 48 additional displays. See [CIVIC_EXPANSION.md](CIVIC_EXPANSION.md).
