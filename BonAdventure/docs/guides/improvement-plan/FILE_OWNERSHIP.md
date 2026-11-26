# Improvement plan: file and system ownership

The rules come from the user's 25 Nov brief and AGENTS.md:

- One writer per file at a time.
- A workstream that needs a file outside its list asks the coordinator (A8) first. The request and the answer are recorded in [DECISION_LOG.md](DECISION_LOG.md).
- Ownership below is **for this programme only**. The project's own component ownership in [COMPONENTS.md](../COMPONENTS.md) still applies:
  - eyes are written only by `plush_life.gd`;
  - a plush's `Head` is never rotated;
  - door, hold and seat behaviour lives in their shared components.

## Contended files

These are touched by many systems. Only the named owner writes them, one milestone at a time.

| File / resource | Wanted by | Write owner | Rule |
| --- | --- | --- | --- |
| `project.godot` | A1, A2, A3 (interpolation) | A8 | No task plans to change it. Any change needs a decision-log entry and the user's approval |
| `export_presets.cfg`, `tools/deploy_web.py` | A1 | A1 (G3) | |
| `scripts/core/main.gd` | A4 (back handler, respawn, F9), A1 (per-frame room lookup) | A4 during M2, then A8 | P3-01 waits until M2 is merged |
| `scripts/core/minigame_wiring.gd` | A4 | A4 | |
| `scripts/core/save_store.gd`, `profile_manager.gd` | A7, A6 (session reset) | A7 (G1) | ARCH-05 is done by A7 |
| `scripts/learning/practice_log.gd`, `vocabulary_progress.gd` | A7, A6 (P3-13) | A7 until M1 is merged, then A6 | |
| `scripts/learning/word_memory.gd` | A6 | A6 (G4) | |
| `scripts/learning/zoo_feeding_session.gd` | A4 (GAME-02/03), A6 (LEARN-02) | A4 in M2, then A6 in M4 | Never in parallel |
| `scripts/ui/bon_style.gd` | A5, A2 (none planned) | A5 (G5) | UI_STYLE.md is updated in the same change |
| `scripts/ui/vocabulary_hud.gd` | A5 (UI-02/04/05/06, P3-15/16) | A5 | The busiest UI file: one task per commit |
| `scripts/ui/touch_controls.gd` | A5 (UI-05), A7 (P3-10) | A5 | P3-10 goes after UI-05 |
| `scripts/ui/vocabulary_book.gd` | A5 (UI-03), A6 (LEARN-04) | A5, then A6 | |
| `scripts/world/park_animals.gd` | A3 (ANIM-01/02, P3-18), A1 (P3-01) | A3 (G6) | A1's change waits |
| `scripts/characters/plush_life.gd` | A3 (ANIM-01/07, P3-19) | A3 | COMPONENTS.md is updated with any API change |
| `scripts/characters/clay_animator.gd` | A3/A1 (ANIM-06) | A3 | After PERF-01 |
| `scripts/world/render_culling.gd` | A2 (GFX-01/02), A1 (PERF-05, P3-02) | A1 | A2 proposes, A1 writes and measures |
| `scripts/world/day_night.gd`, `data/day_night.json` | A2 | A2 (G7) | |
| `scripts/core/vehicle_controls.gd` | A2 (GFX-05), A1 (PERF-05) | A2, then A1 | |
| `scripts/player/player_controller.gd` | A3 (ANIM-03, P3-19), A2 (camera near) | A3 | |
| `scripts/core/door_animator.gd` | A4 (P3-07), A1 (P3-01) | A4 | The shared-door migration is paused: [DOORS.md](../DOORS.md) |
| `data/phrases.json` | A4, A5 | A8 merges | Every new key needs es/en/zh. Keys are added only, never renamed |
| `data/words.json`, game data files | A6 (LEARN-05) | A6 | Never hand-write word lists; rerun `vocabulary_report.gd -- --write` |
| `scenes/town/*.scn`, `materials/palette/*` | A2 (P3-22), A3 (if a bake is needed) | A8 schedules bakes | One bake per unit, through `tools/bake_unit.gd` only |
| `scenes/animals/*` clay scenes and meshes | A2 (P3-24), A1 (P3-03) | Frozen until the sheep/hen work lands | |
| `tools/run_checks.py`, `data/expected_check_failures.json` | all | A8 | |
| Docs: `docs/game/*`, `FINAL_VERIFICATION.md`, `README.md`, `docs/README.md`, this folder | all | A8 | A workstream's owning guide (UI_STYLE, ANIMAL_SYSTEM, MINIGAMES, COMPONENTS, performance README, VOICE) is updated by that workstream within its task |

## Workstream write lists

Each workstream may write only the files in its list (plus its own `docs/evidence/<topic>-<date>/` folder).

- **A1 Performance:**
  - `export_presets.cfg`, `tools/deploy_web.py`, `addons/web_export/*`
  - `scripts/characters/sculpt_cache.gd`, `scripts/core/sound.gd` (PERF-04 only)
  - `render_culling.gd`, `nearby_units.gd`, `app.gd` (warm-up)
  - `crab.gd`, `zoo_gate.gd`, `room_names.gd`
  - `docs/guides/performance/*`
- **A2 Graphics:**
  - `day_night.gd`, `data/day_night.json`, `vehicle_controls.gd`
  - new contact-shadow material, `shaders/*.tres` (P3-23 after approval)
- **A3 Animation:**
  - `park_animals.gd`, `npc_presence.gd`, `plush_life.gd`, `npc_chatter.gd`
  - `hand_hold.gd`, `driveable_vehicle.gd` (rotor only), `player_controller.gd`, `clay_animator.gd`
  - `ANIMAL_SYSTEM.md`, `NPCS.md`, `COMPONENTS.md` (own sections)
- **A4 Gameplay:**
  - `library_session.gd`, `zoo_feeding_session.gd` (M2), `shop_session.gd`
  - `radar_console.gd`, `electrical_box.gd`
  - `seating_controller.gd`, `playground_swing.gd`, `playground_seesaw.gd`
  - `player_place.gd`, `game_launcher.gd`, `interaction_controller.gd`
  - `main.gd` (M2), `MINIGAMES.md`
- **A5 UI:**
  - `scripts/ui/*` except `game_launcher.gd`
  - `tutorial.gd`, `data/tutorial.json`, `UI_STYLE.md`
- **A6 Learning:**
  - `word_memory.gd`, `session_words.gd`, `results_flow.gd`, `missions.gd`
  - `zoo_feeding_session.gd` (M4), `data/activities.json`
  - `docs/game/minigames.md` learning cards (through A8)
- **A7 Architecture:**
  - `save_store.gd`, `profile_manager.gd`, `vocabulary_progress.gd`, `practice_log.gd`
  - session timer guards (P3-09)
  - `tools/build_clay.gd` (P3-11)
  - the save sections of `ARCHITECTURE_REVIEW_PART1.md`
- **A8 Coordinator:**
  - this folder, `run_checks.py`, `expected_check_failures.json`
  - `FINAL_VERIFICATION.md`, `docs/game/*`, `docs/README.md`, `README.md`
  - `phrases.json` merges
