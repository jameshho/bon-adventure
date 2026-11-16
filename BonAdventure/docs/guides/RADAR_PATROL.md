# Radar Patrol

Game name (user, 10 Nov 2026; [all names](MINIGAMES.md#minigame-index)): **Radar Patrol** · *Guardianes del cielo* · 天空保衛戰.

An arcade pastime on the airport control-tower radars (built 9 Nov 2026). Players watch a
green radar as friendly planes and alien UFOs cross it, and tap the UFOs to destroy them.
Listed in the [minigame index](MINIGAMES.md) and in the [test launcher](MINIGAMES.md#minigame-picker)
under **Pastimes**.

## User decisions (9 Nov 2026)

- Either radar starts the game: the scope in the hidden radar room (level 11) and the wall
  display in the control room (level 22). Both were restyled to look like the game.
- A click, a tap or E on a radar starts the game; it is a pastime station
  [interactable](ARCHITECTURE_REVIEW_PART1.md#interaction-system) (12 Nov 2026): a subtle dot
  within 15 m, the "E" badge in range, no word card and no hover hint.
- The game uses a full-screen panel, and the best score is saved.
- The game shows English arcade text in every language, except its title, which is the translated game name (`games.radar_patrol`, user, 10 Nov 2026). No word is tested and nothing is tracked.
- The design follows the user's two reference images: the play screen (square arcade frame,
  large radar, sweep, pixel planes and UFOs, a score box) and the game-over screen (a chamfered
  "GAME OVER!" banner with FINAL SCORE, the explosion still visible).

## Rules

| Rule | Value (`radar_patrol_game.gd`) |
| --- | --- |
| Controls | Tap or click a UFO. Space or Enter starts or restarts the game; P or the bottom-left button pauses; Esc or ✕ closes the screen. |
| Score | 100 for each UFO, plus 50 for every hit already in the combo (up to +450 at a combo of 10). |
| Combo breaks | On a tap on empty sky, a tap on a plane, or a UFO escaping. A tap near both a UFO and a plane counts as the UFO (see Forgiving taps). |
| Friendly fire | A tap on a plane costs 200 points (never below 0). The plane flashes red and keeps flying. The brief did not say what this should do, so this is an assumption. |
| Escaping UFOs | Leave the radar without ending the game ("ESCAPED"). |
| Game over | A UFO touches a plane on the radar (centre distance < 0.085 radar radii). Nothing collides off screen. |
| Difficulty | Speed ×1 → ×2.6 over about 150 s. A UFO spawns every 1.7 s at first, falling to every 0.45 s; a plane every 3.4 s, falling to every 1.3 s. At most 10 UFOs and 6 planes at a time. More and more UFOs aim at a plane's path (15% → 55%). |
| Help | A UFO about to pass near a plane in the next 1.6 s gets blinking amber/red brackets. |
| Planes never cross paths (user, 9 Nov 2026) | A new plane's whole path, from edge to edge, stays at least 0.14 radii from what is left of every other plane's path. Planes may also fly off-centre routes (they aim within 0.8 of the radius) so that parallel routes exist. |
| No instant game over at a spawn (user, 9 Nov 2026) | A plane does not appear if a UFO would come within 0.4 radii of its entry: the stretch from the edge until it is 0.35 radii in, and at least 1.2 s after entering. The check uses where each UFO will be during that time, not only where it is now. New UFOs follow the same rule against planes, because otherwise a UFO could appear right after a plane, next to it. A spawn tries 16 random spots, and if none is safe it tries again 0.3 s later (`spawn_safe()`). |
| Endless | There are no waves or levels. |
| Most UFOs record (user, 9 Nov 2026) | The game-over screen shows "MOST UFOS n" under BEST: the most UFOs destroyed in one game, saved as `best_kills` in `user://radar_patrol.json` (older saves read as 0). A game that beats it shows a blinking "NEW RECORD: n UFOS!" instead. `capture_panel.gd` stages BEST 25,000 and MOST UFOS 42 for `game-over.png`. |
| Craft size (user, 9 Nov 2026) | Planes and UFOs are drawn 20% bigger than the first build, so they are easier to see and tap (`CRAFT_SCALE` 1.2 in the panel scales the sprites, glow, plane ring and warning brackets). The hit circles grew with them: UFO 0.066, plane 0.06 radar radii (were 0.055 and 0.05). The crash distance was left at 0.085, so the game is not harder. Checks: `rules.gd` 0 failures; `capture_panel.gd` re-rendered `play.png`. |
| Craft size again (user, 15 Nov 2026) | "Make the alien and the airplane icon around 40% bigger … it requires extreme precision" to tap a UFO on a phone. `CRAFT_SCALE` 1.2 → 1.68 (sprites, glow, plane ring, brackets); hit circles UFO 0.092, plane 0.084 radar radii (were 0.066 and 0.06). The crash and threat distances were left as they were, so the game is not harder; bigger sprites now touch a little before a crash. |
| Forgiving taps (user, 15 Nov 2026) | "Make the touch more forgiving … the logo is already big enough": sprites unchanged. In `tap()` any UFO within reach takes the tap before a plane is considered; a UFO's reach also covers where it was `TAP_LAG` 0.18 s ago (a finger lands on what the eye saw); a plane only takes half the slop. The panel's finger slop is 30 px (was 18 px), clamped to 0.06–0.14 radar radii (was 0.03–0.08). Checks: `rules.gd` 0 failures (3 new tap checks). Not yet tried on a real phone. |

## Files

| Part | Owner |
| --- | --- |
| Rules (no drawing) | `scripts/learning/radar_patrol_game.gd` |
| Screen: drawing, taps, pause, the start and game-over cards, the best score, best combo and most UFOs (`user://radar_patrol.json`) | `scripts/ui/radar_patrol_panel.gd` |
| Session: board registration (`radar_patrol` in `data/activities.json`, kind `pastime`, chance 0), refusing to start while another game runs, the launcher's `launch()` | `scripts/learning/radar_patrol_session.gd` |
| The radars: `use()` through their Interactable (added in `_ready()`; until 12 Nov 2026 meta `click_play`) | `scripts/objects/radar_console.gd` |
| Radar look: an animated grid, rings, sweep and blips on a quad, with a bright bezel ring | `shaders/radar_screen.gdshader`, airport step `radar_patrol_screens` (`scripts/buildings/airport.gd`) |
| Wiring | `minigame_wiring.gd` (`radar_panel` in `PANELS`, locking the player); `main.gd` `radar_panel` |
| Test launcher | `game_launcher.gd` `launch()`: a session without an NPC host is started with its own `launch()` |
| Text | `games.radar_patrol` and `hint.play_radar` in `data/phrases.json` |

## Verification (9 Nov 2026)

- `docs/evidence/radar-patrol-20261109/rules.gd` (`radar_patrol_rules` in `tools/run_checks.py`):
  18/18 pass. It covers scoring, combos, misses, friendly fire, collision on and off the radar,
  rising difficulty, and script loading. It also runs ten idle 4-minute games and checks that:
  about 970 planes appeared; no plane path crossed another; no plane appeared with a UFO near
  its start; and none of 376 crashes came within 1 s of either craft entering the radar.
- `capture_panel.gd` renders the screen alone: `ready.png`, `play.png`, `game-over.png`. These
  are staged scenes, so the stats line and best score in `game-over.png` are not real values.
- `capture_radars.gd` renders both baked radars (`radar-scope.png`, `radar-display.png`) and
  confirms that each radar root has the script, `click_play` and the hint (historical: the metas
  were replaced by the interactable on 12 Nov 2026).
- `launcher.gd` (full town, with graphics) starts the game from the test launcher, clicks to
  start, clicks a UFO (it scores), then presses Esc (the screen closes, the player is free and the
  launcher's test ends). Result: 0 failures, plus `launcher-play.png`. It found a bug in the first
  build: under the HUD the panel was 0 × 0, so nothing could be clicked. The panel now fills the
  window itself (`_fit_window()`), rises above later HUD parts, and hides the minimap, clock and
  help while open (`hud.hide_for_game()`).
- **Not run:** walking up the tower and clicking a radar in the town, and the full suite.
- **Fixed 9 Nov 2026 (user report):** E on a radar gave `SCRIPT ERROR: Trying to return a value
  of type "Nil"` in `radar_console.gd:11`. The panel was also in the `radar_patrol` group, so the
  radar could call the panel's `open_game()` (void), skipping the session's busy check. Only the
  session is in the group now. The panel also stopped setting full-rect anchors, which caused the
  "non-equal opposite anchors" warning at startup (`_fit_window()` sizes it). `launcher.gd` now
  also calls `use()` on both baked radars. First run: the 7 new checks passed, but "a click
  starts the game" failed (PAUSED right after starting). No code path explains it, and the test
  window was on the user's screen, so input there probably interfered. A second run at the user's
  request, with the window left alone: 14/14 pass (0 failures), with no script errors or anchor
  warnings.
