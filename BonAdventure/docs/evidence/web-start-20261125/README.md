# Late buildings on the web: sculpt cache and material warm-up (25 Nov 2026)

Improvement plan tasks PERF-03 and PERF-06
([tracker](../../guides/improvement-plan/TASK_TRACKER.md)); guide section:
[performance README](../../guides/performance/README.md#late-buildings-sculpt-cache-and-material-warm-up--25-november-2026).

## What changed

- **PERF-03.** The sculpt cache keyed every entry on the source of the character's script
  chain. An exported build packs scripts as tokens with no source, so on the web the key was
  always empty: every launch and every building added later sculpted its plushes again.
  - Now each export writes the hashes into the pack as `res://sculpt_hashes.json`
    (`addons/web_export/sculpt_hashes.gd`), computed from the same sources it packs.
  - `sculpt_cache.gd` reads that list when a script has no source.
  - On the web, the cache files are used only where the browser keeps `user://`
    (`OS.is_userfs_persistent()`).
- **PERF-06.** `scripts/world/unit_warmup.gd` runs when a building unit is added after the town
  is ready (`app.gd` connects it to `Main.unit_added`; there is no `main.gd` change).
  - It draws each new pairing of material and vertex layout once, 4 per frame.
  - It uses one of the unit's own meshes, shrunk far below a pixel, in front of the camera.
  - A stand-in quad warmed only about a third as much (native: restaurants' first-sight stall
    285 → 180 ms with quads, no better with real meshes).
  - Material property names are listed once per class. This cut the scan on the web from
    43/75 ms to 11/15 ms (restaurants/hospital).

## Probe

[`probe.gd`](probe.gd) ([`run_probe.gd`](run_probe.gd) runs it natively). It builds the town
with only the home, as a new profile does. Then, for each unit:

1. It looks from the unit's entrance before the unit exists.
2. It adds the unit from the home's door.
3. It runs the warm-up.
4. It looks from the entrance and from 3 m inside the door ("first").
5. It goes back to the home and looks again ("second").

Each look records the worst and total frame time over 8 frames, as `[worst, total]` ms.

The web was measured with headless Chrome (muted, `--user-data-dir` per run, 1560×720, vsync 60
Hz), served from a scratch export (`tools/deploy_web.py --out`, never published). The probe
was copied into `scripts/` with a temporary `?probe=1` hook in `app.gd` (header of `probe.gd`);
both were removed afterwards.

Native runs used `--audio-driver Dummy` (silent; the render timing is unchanged).

## Web results (M5, Chrome headless, units restaurants / police / hospital / school)

| Run | Conditions | Town ready (home only) | Restaurants add, worst frame | Police | Hospital | School |
| --- | --- | ---: | --- | --- | --- | --- |
| A | fresh profile, cold everything, warm-up on | 18,899 ms | 4,545 ms, 1,852 | 619, 301 | 1,600, 309 | 608, 285 |
| D | warm browser, **sculpt cache off** (`cache=0`, as every web launch before PERF-03) | 4,452 ms | 2,689 ms, 682 | 916, 440 | 1,511, 359 | 643, 331 |
| B | warm browser, **sculpt cache warm** | 3,946 ms | **921 ms, 260** | **217, 63** | **532, 162** | **389, 159** |
| E | as B, after the scan fix | 3,216 ms | 895 ms, 258 | 217, 63 | 512, 160 | 389, 159 |
| C | fresh profile, **warm-up off** (Metal cache already warm) | 4,555 ms | 2,352 ms, 691 | 584, 286 | 1,228, 276 | 591, 277 |

What the runs show:

- **PERF-03 (D against B):** adding a building with a warm cache is about 3× quicker, and its
  worst frame is 2.6–7× shorter: restaurants 682 → 260 ms, police 440 → 63, hospital
  359 → 162, school 331 → 159.
  - After run A, 30 cache entries were in IndexedDB (`cache_files_after`), and the next launch
    read them.
  - The rest of the add is the hook-up (doors, word areas, batching, language), not sculpting.
- **First sight, outside the entrance (worst frame, ms):**

  | Unit | A (cold, warm-up on) | C (no warm-up) | B (warm-up, warm cache) | D | Second look, every run |
  | --- | ---: | ---: | ---: | ---: | ---: |
  | Restaurants | 1,028 | 199 | 85 | 131 | 17–19 |
  | Hospital | 378 | 182 | 65 | 106 | 17–19 (27 outside the hospital) |

  - In run A the warm-up frames themselves took the compiling (restaurants up to 886 ms in a
    frame, hospital 1.7 s over its frames).
  - **A clean cold-web comparison could not be repeated on this Mac.** Run C used a fresh
    Chrome profile, yet its town was ready in 4.6 s (A: 18.9 s). macOS keeps Chrome's Metal
    shader cache across profiles, so only run A was truly cold.
- **Noise:** single long frames turned up on looks that should be quiet: police second look
  inside 1,615 ms (run A) and hospital first look inside 653 ms (run E). They were not
  repeatable; possibly a browser storage sync or garbage collection.

## Native results (M5, 1560×720, vsync off, `--audio-driver Dummy`)

| Unit | Add, cold cache | Add, warm cache | First sight outside, warm-up off | First sight, warm-up on | Second sight |
| --- | --- | --- | ---: | ---: | ---: |
| Restaurants | 2,491 ms (worst 812) | 1,108–1,186 ms (worst 534–557) | 285 ms | 179–181 ms | 5–10 ms |
| Police | 494 (262) | 160–180 (61–69) | 10 | 9 | 6–10 |
| Hospital | 1,213 (276) | 448–486 (200–225) | 270 | 162–171 | 11–17 |
| School | 580 (311) | 233–258 (112–124) | 12 | 8–11 | 5–11 |

Town ready (home only): 5.7 s cold → 5.2–5.5 s warm.

**What remains of first sight is not drawing.** With every node of the hospital hidden (its
parts and its static batches), the first arrival still took 140–150 ms against 11–18 ms the
second time. That is CPU work on first arriving at a new building, and it is not identified
yet: word areas, interactables, the room lookup and the HUD's first text are candidates. It is
a follow-up, not part of PERF-06.

## Cache size

- This run: 31 entries, 39 MB on disk natively, 41 MB of IndexedDB in Chrome (home, the player's
  characters and 4 units).
- The whole town on the developer's desktop: 74 MB in 108 entries (some may be stale).
- Entries of an edited script are deleted when it builds again; nothing else limits the folder.

## Files

| File | Purpose |
| --- | --- |
| `probe.gd`, `run_probe.gd` | The probe and its native runner |
| Raw logs | Not kept (scratch); the numbers above are copied from them |

## Checks

Run once each on 25 Nov, with `dev_focus.txt` = `all`:
`run_checks.py --only app_flow,tutorial,plush_life`.

- All three PASS, each with the known exit -6 crash after the summary.
- The checks run with `VT_SCULPT_CACHE=0`. Only the web runs above exercise the cache files of
  an exported build.
