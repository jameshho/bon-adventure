# Wayfinding: baked town map and guide arrow (18 Nov 2026)

User's choice (18 Nov 2026): both a map and a guide arrow, the map as a baked top-down render.
Design and ownership: [Town map and guide arrow](../../guides/MINIGAMES.md#town-map-and-guide-arrow).

## Check

`verify.gd` (graphics, isolated `HOME`, `VT_FOCUS=all VT_SPAWN=none VT_NEARBY=0`, 1100 × 800, full
town), run once on 18 Nov 2026 on an Apple M-series Mac: **20 PASS, 0 FAIL** — map button shows;
picture not loaded while closed; M opens the map, loads the picture and stops the player; 21
name pills, all inside the picture; the card fits 1100 × 800 and 844 × 390; a tap picks the
nearest place; the supermarket lists its two games; Go there closes the map, lets the picture go
and starts the guide; the guide card is finger-sized; it clears on arrival with a toast; the
picker's Go there follows Dr. Li's node and closes the picker; phone buttons ≥ 44 px.

Frame time while the player turns 180 frames, vsync off (mean ms a frame):

| Nothing open | Map open | Guide on |
| --- | --- | --- |
| 7.26 | 10.06 | 3.92 |

One run, with other Godot processes from parallel sessions on the machine, so the numbers are
noisy (the guide being faster than nothing open is noise/warm-up). None is near the old live
map's 64 ms (README [hidden features](../../../README.md#hidden-features)). The map's cost is
drawing one 1400 × 1138 picture over the 3D view while it is open; the guide adds one vector
sum a frame. Not measured on a phone or in the web build.

## Views

| File | What |
| --- | --- |
| `map.png` | Map just opened (no place picked) |
| `map_picked.png` | Library picked: its game, Go there |
| `guide.png` | Guide card top left: arrow, Library, 254 m; map button left of ▶ |
| `picker_go.png` | Minigame picker with Go there next to Play |
| `map_phone.png` | 844 × 390: police station with two games, Stop guiding |
| `guide_phone.png` | 844 × 390: guide card to Dr. Li |

## Baking

`tools/bake_town_map.gd` wrote `assets/maps/town_map.png` (1400 × 1138; imported lossy, 173 KB
in `.godot/imported`) and `data/town_map.json` (21 places, 14 games). The process ends with exit
137 after printing its summary (both files are written before `quit()`); reimport afterwards.

## Limitations

- Not tried on a touch device or in the web export.
- The picture is a snapshot: re-bake after a building, entrance or NPC moves.
- The welcome tutorial hides the map button and M; not covered by this check.
