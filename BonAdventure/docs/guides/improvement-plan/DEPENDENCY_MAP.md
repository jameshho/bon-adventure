# Improvement plan: dependency map

## Prerequisites (M0)

Everything depends on these:

1. **A known revision.** At the audit (`11fc0121`) the tree held uncommitted work on mahjong
   (`mahjong_session/view/panel.gd`, docs), the clay sheep (`scenes/animals/clay_meshes/sheep/*`)
   and evidence images. That work must be committed or set aside by the user before any task
   starts, so that every workstream branches from the same commit.
2. **`dev_focus.txt` = `all`** for the baseline and every milestone's final check.
3. **PERF-01 baseline** before any task whose acceptance is a performance number:
   GFX-01, GFX-02, ANIM-06, PERF-03, PERF-05, PERF-06, PERF-07, P3-01, P3-02.

## Task dependencies

```
ARCH-02 ──► ARCH-03
ARCH-01, ARCH-02 ──► QA-01 (save-robustness check covers them)
ARCH-05 ──► LEARN-01 (same results flow; verify together)
GAME-01 ──► GAME-02 ──► GAME-03, P3-05
UI-01 ──► UI-02, UI-04, UI-05, UI-06
PERF-01 ──► GFX-01 (proof of concept measured) , GFX-02, ANIM-06, PERF-03, PERF-05, PERF-06, PERF-07
ANIM-01 ──► ANIM-02 (both in park_animals.gd) ──► P3-01 (park_animals part), P3-18
ANIM-01 ──► ANIM-05 (hand_hold.gd)
sheep/hen clay work landed ──► PERF-02 (sheep folder), P3-18, P3-24
User decisions ──► PERF-04, LEARN-03..06, ANIM-03, ANIM-07, UI-02, GFX-01 rollout, P3-14/15/22/23
QA-02 (full suite) ──► before the first commit of M1 and after every third milestone
```

## Sequential chains

These must not be split across sessions:

- **Saves:** ARCH-01 → ARCH-02 → ARCH-03 → ARCH-04 → ARCH-05 → ARCH-06. They share
  `save_store.gd`/`profile_manager.gd` and one robustness check.
- **Game exits:** GAME-01 → GAME-02 → GAME-03. They share the leave contract and `main.gd`'s back handler.
- **UI scale:** UI-01 → UI-02 → UI-06/UI-04. `bon_style.gd` and `vocabulary_hud.gd` are in each step.
- **Animal motion:** ANIM-01 → ANIM-02 → the P3 items in `park_animals.gd`.
- **`day_night.gd`:** GFX-03 → GFX-04 → P3-20 → P3-21.

## Parallel groups

These groups write disjoint files (see [FILE_OWNERSHIP.md](FILE_OWNERSHIP.md)), so two of them
can run at the same time in separate worktrees. The shared files listed under "contended" there
are edited only by the coordinator, at integration.

| Group | Tasks | Writes | Can run beside |
| --- | --- | --- | --- |
| G1 Saves | ARCH-01…06, QA-01 save check | `save_store.gd`, `profile_manager.gd`, `vocabulary_progress.gd`, `practice_log.gd` | G3, G4, G5, G6 |
| G2 Game exits | GAME-01…04 | `library_session.gd`, `zoo_feeding_session.gd`, `shop_session.gd`, `radar_console.gd`, `electrical_box.gd`; `main.gd` back handler (owned by G2 for this milestone) | G1, G3, G5, G6. Not beside LEARN-02, which also writes `zoo_feeding_session.gd` |
| G3 Web pack | PERF-02 | `export_presets.cfg`, `tools/deploy_web.py` | everything |
| G4 Learning | LEARN-01, LEARN-02 | `word_memory.gd`, `zoo_feeding_session.gd` | G1 (after ARCH-05 is merged), G3, G5, G6 |
| G5 UI | UI-01, UI-02, UI-03 | `scripts/ui/*` | G1, G2, G3, G4, G6 |
| G6 Motion | ANIM-01, 02, 04, 05 | `park_animals.gd`, `npc_presence.gd`, `plush_life.gd`, `hand_hold.gd`, `driveable_vehicle.gd` | G1, G3, G4, G5 |
| G7 Look | GFX-03, 04, 05, GFX-01 PoC | `day_night.gd`, `data/day_night.json`, `vehicle_controls.gd`, new material | G1, G2, G4, G5. Not beside G6 while GFX-01 attaches to animal or plush scenes |

**Recommendation:** run one group at a time in this checkout, in milestone order, and allow at
most one side session, for G3 or G5, which do not touch the town scenes.

- Each check loads the whole town for minutes.
- A new worktree needs a fresh Godot import.
- The AGENTS.md verification budget allows one check run per change.

Two parallel writers would double the check time without saving much.
