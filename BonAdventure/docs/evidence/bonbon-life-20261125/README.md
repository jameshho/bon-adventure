# BonBon life: eased jump, softer blink, glass sky (25 Nov 2026)

Improvement plan P3-19 and P3-20 ([tracker](../../guides/improvement-plan/TASK_TRACKER.md)).
All sheets come from `capture.gd` in this folder (usage in its header; windowed runs with
`--audio-driver Dummy`, isolated `HOME`).

## P3-19 Jump pose and blink

- **Jump** (`player_controller.gd`): take-off used to set `jump_pose` straight to 1 and drop it
  linearly to 0.55, and landing dropped it linearly to 0. Now take-off sets `jump_kick` (fades
  in about 0.6 s), and the pose eases toward the larger of the kick and the airborne hold:
  quickly up (rate 16/s), softer down (8/s).
  `jump_pose` at the strip's frames (0.1 s apart, real physics on a small stage):
  before `0.75, 0.55, 0.55, 0.55, 0.55, 0.55, 0.47, 0.00, 0.00`;
  after `0.40, 0.75, 0.68, 0.60, 0.57, 0.56, 0.55, 0.28, 0.11`.
  [jump-before.png](jump-before.png) | [jump-after.png](jump-after.png): the whole character from
  the side at 1x, and below it the player's own camera (game distance).
- **Blink** (`plush_life.gd`): three steps (half, shut, half, open; ends at 0.04, 0.10 and 0.16 s),
  each written once, for every plush. `soft_blink = false` keeps the old single step.
  BonBon blinks too: her own `PlushLife` (no gestures), made in `bind_model()`; she is kept out
  of the `figures` group, which marks occupied seats.
  Eye height at 0, 0.02, 0.07, 0.13 and 0.17 s: `0.45, 0.45, 0.15, 0.45, 1.00`.
  [blink.png](blink.png): the whole character at 1x, then the face at 2x.

## P3-20 Glass reflects the time of day

The glass shader's reflected sky colour is the global shader parameter `glass_sky_colour`
(`project.godot` `[shader_globals]`). `day_night.gd` writes it once when it changes: 30% of the way
from the hour's horizon colour to its top (the old fixed colour at noon).
[glass.png](glass.png): the supermarket storefront (`VT_FOCUS=supermarket`) at 07:00, 12:00, 18:40
and 22:00, old fixed colour (left) and the hour's (right). Written colours: `c3bbbd`, `a4c9e6`,
`9f778c`, `2a3b72`. The change is subtle by design (the outdoors face reflects 38% at most).

**Phone cost:** one value in the global uniform buffer, written at most 4 times a second by the
existing refresh. There is no new texture, pass, branch or per-window work, and the fragment
arithmetic is the same as before. No frame-time measurement was made: there is nothing per-frame
to measure. The opaque glass fallback does not change.

## Checks (run once, 25 Nov 2026, `dev_focus.txt` = all)

`python3 tools/run_checks.py --only plush_life,day_night,player_place`: plush_life 22 checks,
day_night 64, player_place 235, 0 failures each (plush_life and day_night crashed on exit after
the summary, the known harmless crash). No check covers the jump pose itself; the strip above
is its evidence.
