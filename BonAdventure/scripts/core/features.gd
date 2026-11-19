extends RefCounted
## Features switched off for now (user, 14 Nov 2026: trimming the game for phones). Each one
## is not built or loaded at all while its switch is false; its code stays in place so it can
## come back by setting the switch to true, or be deleted after review. The list, what each
## switch removes and how to bring it back: README.md#hidden-features.

## The minimap in the top-left corner (town_minimap.gd). It rebuilt the town outline from every
## mesh (~0.1 s each time, several times while loading) and redrew it while the player moved:
## measured on an M-series Mac, 8.4 ms -> 64 ms per frame while turning.
const MINIMAP := false
## The town map: the M key, the map button (second top-right row), its F1 guide row and the
## baked picture assets/maps/town_map.png (scripts/ui/town_map_panel.gd). Back on since 18 Nov
## 2026 (wayfinding, user) as a picture baked by tools/bake_town_map.gd instead of the live
## drawing; the guide arrow (guide_arrow.gd) is always built.
const FULL_MAP := true
## Hyper speed: the H key, the touch lightning button, its F1 guide row and HUD line.
const HYPER_SPEED := false
## Infinite jump (the I key toggles it) at the start of a game; was on.
const INFINITE_JUMP_AT_START := false
