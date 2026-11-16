# Editor scene migration

> Historical migration record: Main now instances `town_public_garden.tscn`,
> with additional runtime home/refinement passes. See the [current README](../../README.md)
> before choosing or rebuilding a world scene.

The active scene is now `scenes/world/town_complete.tscn`, instanced by Main. It includes all formerly generated town objects and retains reusable building, character, vehicle and vocabulary scenes. Door and drawer states are saved as metadata, with collider references stored as relative paths.

See [LEARNING_UPDATE.md](LEARNING_UPDATE.md) for current coverage, editor instructions, regeneration boundaries and validation commands. `town_editable.tscn` remains the input for rebuilding procedural source content; it is not the active complete level. The old v0.26 archive remains available under `backups/`.
