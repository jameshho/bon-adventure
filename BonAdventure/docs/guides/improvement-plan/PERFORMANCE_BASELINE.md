# Improvement plan: performance baseline

## M0 baseline: 25 Nov 2026 (desktop)

### Conditions

- **Probe:** [`docs/evidence/perf-baseline-20261125/probe.gd`](../../evidence/perf-baseline-20261125/probe.gd).
- **Commit:** `278d40f1`, plus uncommitted sheep and restaurant-retry leftovers, which the town does not load.
- **Machine:** Apple M5, Godot 4.7.2 (official), GL Compatibility.
- **Run settings:**
  - window 1560×720, 3D scale 1.0, MSAA 2× (the one graphics setting);
  - vsync and the frame cap off;
  - 2 pm with the clock paused;
  - `VT_FOCUS=all`, isolated HOME, so the plush sculpt cache was cold.
- **Not covered:** this is **not the web build and not a phone**.

### Results

Frame time is over 300 frames after a 240-frame settle. Draw calls and triangles come from
`RenderingServer.get_rendering_info`.

| View | p50 ms | p95 ms | max ms | Draws | Tris (M) |
| --- | --- | --- | --- | --- | --- |
| Street at spawn | 6.25 | 9.50 | 13.46 | 710 | 0.71 |
| Home bedroom (tutorial start) | 4.64 | 8.20 | 15.02 | 591 | 0.23 |
| Mahjong yard | 8.30 | 9.44 | 14.59 | 1,280 | 0.89 |
| Central Park by the zoo, **facing away from the animals** (see notes) | 7.83 | 10.56 | 11.47 | 1,832 | 0.47 |
| Flight 40 m (view 218 m) | 14.25 | 16.34 | 17.30 | 4,687 | 1.00 |
| Flight 100 m (view 330 m) | 13.75 | 15.84 | 17.30 | 4,279 | 0.61 |

### Whole run

- **Load:** `main.tscn` instantiated to the first frame in 9.3 s, and to 40 frames in 12.1 s. This is desktop, without staged loading, with a cold sculpt cache. It is not the web Play→playable time.
- **Video memory:** 372–373 MB (textures 118 MB, buffers 253 MB).
- **Static memory:** 657 MB.
- **Nodes:** 75,619.

### Notes on this run

- **Matches the earlier records:**
  - The bedroom gave 591 draws, against 587 on 17 Nov.
  - Flight at 40 m gave 4,687 draws, against 4,749 on 23 Nov.
  - Video memory is 27 MB above the 345 MB of 14 Nov, after the buildings added since.
- **Four runs were needed:**
  - Run 1: Godot was not on PATH (exit 127).
  - Run 2: a script error on the removed `graphics` setting.
  - Run 3: the `Performance` draw monitors returned a stale 710 draws for every view. Fixed by using `RenderingServer.get_rendering_info`.
  - Run 4 is the one recorded here.
- **Process and physics times are not reported.** The `TIME_PROCESS` monitor read 9–19 ms while the frames were 5–14 ms, so it is stale like the draw monitor. A real CPU profile is still needed.
- **The zoo row** faced away from the animals: its screenshot shows Central Park with no animals in view. The probe now turns toward them, and the next run will replace this row.
- **Godot exited with 137 (killed)** after `quit()` on every run. The results were already written.

## Earlier records

The table below collects the most recent numbers recorded before this programme, with their source and date.

## Recorded numbers (desktop: M5 Mac unless noted)

| Metric | Value | Conditions | Source |
| --- | --- | --- | --- |
| On foot, street | 773 draws, 1.01 M tris, 13.1 ms (vsync-capped) | native, 1560×720, one graphics setting | [performance README](../performance/README.md), 23 Nov |
| Flight 40 m / 100 m / 200 m / 300 m | 4,749 / 4,227 / 3,713 / 1,277 draws; 16.8 ms at 40 m, 10.3 ms at 300 m | same | same, 23 Nov |
| Street at spawn / bedroom / mahjong yard / mahjong close-up | 777 / 587 / 1,566 / 635 draws | native, Low | same, 17 Nov |
| Video memory, full town | 345 MB (328 MB without MSAA); textures 114 MB; buffers about 229 MB; plushes 84–88 MB; clay animals about 50 MB | native | same, 14, 17 and 18 Nov |
| Web FPS | 125 (noon) / 148 (midnight) | headless Chrome, M5, 2× density, **before the 23 Nov one-setting change: stale** | same, 9 Nov |
| Web Play → playable | 7.1–7.3 s warm; cold first launch about 20.7 s of shader compiling | M5 Chrome | [FINAL_VERIFICATION](../FINAL_VERIFICATION.md), 13 Nov |
| Building load hitch (web) | 0.35–0.8 s per building (restaurants 0.8 s; sculpt 1,258 ms uncached against 109 ms cached, native) | | same, 13 Nov |
| Building add on the web (sculpt cache off → warm, PERF-03) | restaurants 2,689 → 921 ms (worst frame 682 → 260), hospital 1,511 → 532 ms (359 → 162); cold first launch 4,545 ms (1,852) | headless Chrome, M5, warm browser | [web-start evidence](../../evidence/web-start-20261125/README.md), 25 Nov |
| Web download | `index.pck` 91.4 MB (voice about 20–30 MB), `index.wasm` about 40 MB (about 10 MB gzipped) | | [VOICE.md](../VOICE.md), 24 Nov |

## Not measured anywhere

These are still open after the 25 Nov desktop run, and they remain the PERF-01 targets:

- **Any phone or tablet:** FPS, frame time, video MB (`?perf=1`), context-loss rate, startup time.
- **The web build since 23 Nov:** frame time on foot and in flight, the hitch when a building loads mid-walk, the stall when a late building is first seen.
- **A long web session:** video memory growth while `nearby_units` loads buildings.
- **CPU time per script:** no profiler capture exists (`_process` cost of animals, doors, room lookup).
- **Physics time;** `Main._ready` and static batching time on the current town.

## Proposed probe (PERF-01)

- **Views:** street at spawn, bedroom, mahjong yard, zoo look-back, flight 40 m, flight 100 m.
- **Per view:** draws, triangles, video MB, p50/p95 frame time over 300 frames.
- **Once per run:** load time to playable.
- **Conditions:** `dev_focus.txt` = `all`, native 1560×720, vsync off for frame time. Report the vsync-capped value separately.
- **Output:** written to `user://` with the commit hash, so a phone or web run can be compared under the same conditions.
- **Phone procedure:** the user opens the web build with `?perf=1`, stands at the same spots (the probe prints how to reach them) and notes the readout.
