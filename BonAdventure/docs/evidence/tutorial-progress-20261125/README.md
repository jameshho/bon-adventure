# Tutorial progress and Skip confirm (UI-07) — 25 November 2026

The welcome tutorial shows which part is playing ("Part 1 of 3": house, market, park; the count
comes from `data/tutorial.json`) in a soft blue pill beside Skip, and Skip asks first on the
shared quit card: Stay (green, left) carries on where it was, Skip (coral, right) ends it.
While the card is up the steps and the player are held and clicks do not move a line on. The
tutorial's script, timing and lines are unchanged. Owner: [welcome tutorial](../../guides/ARCHITECTURE_REVIEW_PART1.md#welcome-tutorial).

| View | 1280×800 | 844×390 |
| --- | --- | --- |
| Act 1 marker | [act1-progress-1280x800.png](act1-progress-1280x800.png) | [act1-progress-844x390.png](act1-progress-844x390.png) |
| Act 1 Skip confirm | [act1-skip-confirm-1280x800.png](act1-skip-confirm-1280x800.png) | [act1-skip-confirm-844x390.png](act1-skip-confirm-844x390.png) |
| Act 3 marker | [act3-progress-1280x800.png](act3-progress-1280x800.png) | [act3-progress-844x390.png](act3-progress-844x390.png) |
| Act 3 Skip confirm | [act3-skip-confirm-1280x800.png](act3-skip-confirm-1280x800.png) | [act3-skip-confirm-844x390.png](act3-skip-confirm-844x390.png) |

Views by [`render.gd`](render.gd) (graphics; isolated HOME). Act 3 was started from its checkpoint
for the view, so its first line had already closed and the park is seen before its buildings
come in.

## Checks (25 Nov 2026, once each, `dev_focus.txt` = all)

| Check | Result |
| --- | --- |
| `tutorial` (extended: the marker in each act, the confirm at the replay: Stay left / Skip right, held steps and player, a click does not move the line, Stay carries on, Skip ends) | PASS, 179 checks, 0 failures |
| `app_flow` | PASS |
| `touch_controls` | NEW, 1, not from this change: `record_player_panel` (record player, 57f1d7fb) is missing from the check's list of locking panels |
| `language` | NEW, 1, not from this change: no zh reading for 播 首 歌 碌 刻 (record player and clock text on main); the new phrases' characters are all in the font subset and have readings |

The first run of these checks in this fresh worktree was invalid: committed `scenes/town/home.scn`
uses 29 `materials/palette/*.tres` files that exist only as untracked files in the main checkout,
so the home did not load. They were copied into the worktree (not committed here) for the run above.
