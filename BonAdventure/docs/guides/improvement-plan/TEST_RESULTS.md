# Improvement plan: test results

Each run is logged here with:

- the commit;
- `dev_focus.txt`;
- the exact command;
- labels compared against [`data/expected_check_failures.json`](../../../data/expected_check_failures.json);
- what was not run.

This log does not replace [FINAL_VERIFICATION.md](../FINAL_VERIFICATION.md), which stays the
project record: milestone results are also written there.

| Date | Milestone / task | Commit | dev_focus | Command | Result (labels) | Not covered |
| --- | --- | --- | --- | --- | --- | --- |
| 25 Nov 2026 | Audit | `11fc0121` + uncommitted work | (not checked) | none: read-only audit, Godot not launched | n/a | everything |
| 25 Nov 2026 | M0 perf probe | `278d40f1` + sheep/restaurant leftovers | all | `probe.gd` (graphics, 1560×720) | see [baseline](PERFORMANCE_BASELINE.md); 4 runs (PATH, removed setting, stale monitor, then valid) | web, phone |
| 25 Nov 2026 | M0 full suite | `278d40f1`, **while 3–7 sessions were editing the same checkout** | all | `run_checks.py full` (11:42–12:20) | Runner totals: CRASH 55, NEW 1, PASS 10, TIMEOUT 4. Re-judged with C0 (crash on exit after the summary): **PASS 53, KNOWN 2, NEW 10, TIMEOUT 1, invalid 4** | invalid: `bank_teller`, `bank_rework`, `bank_teller_polish`, `npc_registry` (a session's `main.gd` edit did not parse while they ran) |
| 25 Nov 2026 | QA-02 full suite after the fast track | `dfd2be4c` + another session's uncommitted sound/door/sheep work | all | `run_checks.py full --jobs 2` (615 s) | **PASS 73, KNOWN 3, NEW 1, CRASH 1**: NEW `bank_rework` (manager timing race, as 24 Nov); CRASH `app_flow` (segfault in the loading screen; passed alone once) | web, phone, renders |

### NEW labels from the 25 Nov suite (triage)

All fixed by the afternoon (see the row above); the table is kept as the morning's record.


| Check | Label (first) | Likely cause | Owner / next |
| --- | --- | --- | --- |
| `language` | zh characters without a reading: 掉 顆 舍 | data added since 16 Nov | A6: add readings |
| `results_screen` | font subset missing 辭飽餵 | new phrases since the CJK subset was built | A5: rebuild the subset (`tools/build_cjk_font.py`) |
| `world_signs` | ANIMAL FOOD / COMIDA PARA ANIMALES too wide for the 2.00 m booth sign | new zoo food booth | A2/A4: shorter sign or wider board |
| `bath_fixtures` | aiming at the bowl or lever does not pick the toilet/flush | picking regression (unknown since 16 Nov) | A4: trace |
| `electrical_box` | picking ray from the path finds nothing | picking regression or a moved box | A4: trace |
| `practice_log` | oldest_youngest untracked; restaurant/warehouse outcomes changed | the check's expectations predate the 24 Nov restaurant retry and the warehouse flow | A6: update the check or fix the tracking |
| `touch_controls` | list of LOCKING panels is out of date | panels added since | A5: update the list |
| `compact_layout` | rigid move preserves scale: Turboprop | unknown | A8: trace |
| `mahjong_ui_polish` | player may claim a discard (turn 36); call buttons | the check's game state vs the 25 Nov revert | owner of mahjong: re-check |
| `day_night` | 48 glowing lamp heads (47 expected); "indoors by day: the sun is unchanged" | the second is the intended GFX-03 change (session updating it); the first unknown | motion-light-ui session |
| `tutorial` | TIMEOUT, 20 labels from the guide's timing | unknown; ran while sessions edited files | A5: re-run alone after the sessions commit |

**Last recorded project state** (from FINAL_VERIFICATION, 18 Nov):

- The last full suite ran on 16 Nov: PASS 47, NEW 6, TIMEOUT 3. After triage and one re-run: PASS 7, KNOWN 2, NEW 0.
- Known failures: `map_facades` and `rooftops`.
- Changes from 17 to 25 Nov have had targeted checks only.
