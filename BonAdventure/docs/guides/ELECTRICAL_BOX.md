# Electrical boxes (wire repair)

Game name (user, 10 Nov 2026; [all names](MINIGAMES.md#minigame-index)): **Wire It Up!** · *Cable a cable* · 駁電線.

User request, 9 November 2026. A reusable wall-mounted electrical box: E beside it or a click
on it opens the door, the camera glides to a close-up, and the player connects the loose
wires inside **in 3D** to the sockets of the same colour. Revised the same day (user: "less
cartoony, matches the look and feel of the game, make it 3d"): the first version drew the
puzzle as a flat 2D picture over the screen; now the wires are the box's own meshes and the
screen shows only a slim HUD-style bar.

First box: on the outside of the home's garage side wall, facing the entry path (home step
`electrical_box`, site position x 5.91 (wall face), z 20.6, centre 1.25 above the ground,
box id `home_garage`).

## How it plays

1. **Open.** The box is a pastime station
   [interactable](ARCHITECTURE_REVIEW_PART1.md#interaction-system) (12 Nov 2026): a subtle dot
   within 15 m; within 2.2 m in front of it (no aiming needed) it gets the "E" badge, and E, a
   click or a tap opens it (no word card). Refused while another minigame runs, while seated or
   driving.
2. **Zoom.** The door swings open (0.62 s) while a temporary camera glides from the player
   camera to a straight-on close-up (0.88 s; 10 % slower since 10 Nov 2026); BonBon is hidden past 55 % of the glide (she would
   stand between the camera and the box). A small work light lights the inside.
3. **Wires.** 2–6 wires (default 4) hang from coloured terminal plates on the left; their
   sockets on the right are in another random order (never all straight across). Each
   plate carries a symbol (triangle, cross, circle, star, square, diamond) so colours can be
   told apart without colour vision. Drag a copper end onto a socket: the right one snaps in
   and glows green; a wrong socket flashes red and the wire springs back (0.28 s); a drop
   anywhere else springs back too. Grab and drop radii are measured on screen (48 / 60 px ×
   scale), so they suit a finger.
4. **Repaired.** "Electrical Box Repaired!" shows for 1.12 s in a HUD card, the box's lamp
   turns from blinking red to steady green, then everything runs backwards: door shuts,
   camera returns (0.455 s; 1.575 s from the last wire to a closed box, cut by 30 % on 10 Nov 2026), BonBon reappears and can move. Leaving early returns in 0.65 s.
5. **Leave early.** Esc (popup stack) or the ✕ on the bar: the wires drop back loose and the
   same return runs, without repairing.

Every close resets the box (user, 10 Nov 2026): once the door has shut it is broken again
(lamp blinking red, wires loose), and the next opening shuffles a new puzzle. Nothing is saved.

## Files

| Part | File |
| --- | --- |
| Box model, wires, palette, door, lamp, camera framing; `use()` | `scripts/world/electrical_box.gd`, prefab `scenes/props/electrical_box.tscn` |
| Open / zoom / close sequence, E nearby, activity board, test launcher | `scripts/learning/electrical_box_session.gd` |
| Pointer → 3D wire plane, grab / drop rules, bottom bar, success card | `scripts/ui/electrical_box_panel.gd` |
| Wiring (Esc, player lock) | `scripts/core/minigame_wiring.gd` (`PANELS` with its locks flag, `build()`), fields in `main.gd`, E fallback in `Main.use_pressed()` |
| Text | `data/phrases.json` `electrical_box.*`, `games.electrical_box`; word `electrical box` in `data/words.json` (Building Parts) |
| Activity | `data/activities.json` `electrical_box` (pastime, chance 0) |
| Check, views | `docs/evidence/electrical-box-20261109/verify.gd` (`run_checks.py --only electrical_box`), `capture.gd` (overwrites the PNGs there) |

The box's model is built from code when it loads (as `toilet.gd` does), so unit scenes save
only its root, exports and metas.

## Adding a box elsewhere

Add a step to the building's own script that instances the prefab with its back on a wall and
its front (+Z) facing out, then bake that unit (see the home step `electrical_box` for a ray
that finds the wall face):

```gdscript
const ELECTRICAL_BOX := preload("res://scenes/props/electrical_box.tscn")
func add_electrical_box(town: Node3D, _game) -> void:
	var box: Node3D = ELECTRICAL_BOX.instantiate()
	box.set("box_id", "school_back")
	box.set("wire_count", 5)                      # 2..6 from the default palette
	# or: box.set("wire_colors", PackedColorArray([Color("e8412f"), Color("2f56e0"), Color.WHITE]))
	box.set("conduit", 0.9)                       # pipe to the ground (town units), 0 = none
	site.add_child(box, true)
	box.position = ...                            # site-local, centre of the box's back
	box.rotation.y = ...                          # front (+Z) away from the wall
```

Exports: `box_id`, `wire_count` (2–6), `wire_colors` (replaces the palette; symbols follow
in order), `body_color`, `conduit`. Sizes (town units): 0.56 × 0.72 × 0.16.

Sound hooks (no audio yet): box `door_moved`, `repaired_changed`; session `box_opened`,
`box_repaired`, `box_closed`; panel `wire_connected`, `wire_rejected`.

## Verification — 9 November 2026

- `python3 tools/run_checks.py --only electrical_box`: **PASS, 49 checks, 0 failures** (10 Nov 2026, with the reset on close)
  (full town, isolated HOME). It drives the real picking ray, E nearby / from behind the
  wall, the camera, door, light, 3D wire layout, wrong / empty / right drops, success,
  automatic close, Esc and the configuration exports. Drops are made through the panel's
  own drop at a socket's screen position; real mouse drags are not simulated headless.
- `--only language`: PASS (after adding the pinyin reading of 修 to `data/pinyin_zh.json`).
- Home bake reviewed with `tools/compare_scenes.gd` against the committed scene: only the
  box root and the new `applied_steps` entry differ.
- Views (`capture.gd`, focus `home`, 1280 × 800, 10:30): `1-box-on-wall`,
  `2-zooming-door-opening`, `3-wires-start`, `4-dragging`, `5-repaired`,
  `6-back-repaired-box` in `docs/evidence/electrical-box-20261109/`.
- Not checked: dragging by hand in a window, touch on a device, night lighting, other
  languages' text fit in the bar (it shrinks a long how-to line), the full suite.
