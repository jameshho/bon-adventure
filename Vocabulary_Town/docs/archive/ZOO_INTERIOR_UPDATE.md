# Park zoo and interior refresh

> Historical implementation record. Use the [documentation map](../README.md)
> for current guides; positions, counts and test results below describe this snapshot.

The main scene installs `scripts/world/civic_zoo_upgrade.gd` after the existing town layout, including when loading the baked town. Interior decorations are generated at runtime. The zoo is an editable scene at `scenes/world/park_zoo.tscn`, with 20 instanced animal scenes in `scenes/animals/`. These do not alter saved building geometry.

- West park: one wild enclosure centered at (-34, 76), one farm enclosure at (-34, 59), visitor path and Spanish signs, shelters, water troughs and hay.
- Wild: lion, tiger, elephant, bear, monkey, snake, giraffe.
- Farm: cow, pig, horse, hen, duck, sheep.
- Roaming: dog, cat, rabbit, mouse, bird, turtle. Fish swims in the existing pond.
- All 20 animals expose Spanish vocabulary through the existing interaction system. `field mouse` distinguishes the animal from the computer mouse.
- Hospital: teal finishes, floor runner, room lighting, reception details, waiting rug, framed pictures and curtain pleats.
- School: green finishes, floor runner, room lighting, artwork, desk mats and a geography board.
- Clothing store: warm finishes, lighting, feature wall, mirror panels, try-on bench and raised entry sign.

Validation: `docs/evidence/town-checks/check_zoo_upgrade.gd` checks animal count, dictionary entries, physics picking and bounded movement, plus installation of the three interior updates. `docs/evidence/town-checks/check_civic_expansion.gd` passes with zero failures. Screenshots are in `docs/evidence/zoo-review/`. Run the zoo check with `-- --capture` in graphical Godot to refresh them.

## Editing animal assets

Open an individual `scenes/animals/<animal>.tscn` in Godot to edit its model, scale, vocabulary collision area or movement radius/speed. `field_mouse.tscn` is the mouse animal. Each scene is usable on its own and shares `scripts/world/park_animals.gd`. Model parts reference one shared low-poly sphere mesh and shared color materials in `scenes/animals/shared/`; make a material unique before changing a color for only one animal. The same folder contains reusable zoo structure meshes/materials.

Open `scenes/world/park_zoo.tscn` to move animal instances, edit enclosures or change other park-zoo placement. Animal asset roots are centered at the origin, while their zoo positions live in this scene. The interior upgrade script only instantiates the zoo and no longer builds animal geometry.
