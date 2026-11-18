# Nearby loading measurements — 17 November 2026

Evidence for the proposal in
[performance guide: "Proposal: load only nearby buildings on phones"](../../guides/performance/README.md#proposal-load-only-nearby-buildings-on-phones--17-november-2026)
and for what the user then approved and was built the same day (the label fix, then option A:
[Built](../../guides/performance/README.md#built--17-november-2026)). The measurements below were
taken before any game code changed, except `results_signs_fixed.json`, `time_add_unit.gd` and
`verify.gd`.

## Files

| File | What |
| --- | --- |
| `measure_units.gd` | Scratch probe (graphics, isolated `HOME`). Starts Main like the app (staged loading) with only the base world and one unit, then `Main.add_unit()`s every other unit and records per unit: `load()` and bare `instantiate()` time, `add_unit()` wall time / frames / worst frame, video/buffer/texture/node deltas, mesh bytes new to the unit, plush count and plush mesh bytes, font glyph atlas growth, part boxes. Then frees four units (Main paused) to see what memory returns. Header has the command. |
| `results.json` | Last run (all units after `barn`), warm sculpt cache. |
| `results_barn.json` | `barn` alone (`first=playground only=barn`). |
| `results_all_at_once.json` | Whole town loaded at once (`first=all only=none`), as a profile that finished the tutorial loads it: video, font sizes in use. |
| `results_first_snapshot.json` | First (cold-cache) run, ~1 h earlier: same method; differs where sibling sessions' work landed in between (below). |
| `radius_table.py` / `radius_table.txt` | Which units a player holds at each loading radius and their buffer cost (entrances and a 5 m grid). |
| `results_signs_fixed.json` | After stage 0 (the sign fix), the probe run like `results.json` with the web sign path forced (`web_signs=1`). |
| `time_add_unit.gd` | Times each step of `Main.add_unit()` for named units (before the stage 1 split); the output is quoted under "After the fix". |
| `verify.gd` | Check for stages 0–3 with nearby loading forced natively (`VT_NEARBY=1`); header has the command. |

Machine: Apple M5, Compatibility renderer (GLES3 over Metal, as WebGL 2), 1280 × 800, Low tier.
Native only: the web build was not exported or measured.

## Limits (read before quoting a number)

- **The checkout was changing while this ran.** Four other sessions were editing
  `render_culling.gd` (batching), `sculpt_cache.gd` (mesh sharing), clay animals and library signs.
  Between the first and last run mystery's buffers fell 15.3 → 6.4 MB and restaurants'
  55.2 → 43.4 MB; the last run logged 21 `render_culling.gd _merge_leaf` script errors (that work
  in progress); two diagnostic runs logged a `library.gd` parse error. Treat per-unit figures as ±30 %
  and re-measure once those sessions land.
- Video memory: `RenderingServer.get_rendering_info()`. Mesh bytes: `mesh_get_surface()` sizes of
  unique mesh RIDs; plush mesh bytes count each plush's meshes even when shared (an upper bound).
- Hitch times are native M5. The web on a laptop already showed 100–580 ms frames while units load
  behind the title cutscene ([tutorial lag](../tutorial-lag-20261117/README.md)); a phone is slower.
- The radius grid covers sea and park too, so its mean is only a spread, not where players stand.

## Results (last run)

Base world alone (+ barn), staged: 131 MB video, 81 MB buffers. Whole town loaded at once: **334 MB
video** (textures 84, buffers 250, font glyph atlases 45 MB in 61 size/outline pairs).

| unit | buffers MB | plush (mesh MB) | nodes | load ms | add ms (frames) | worst frame ms |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| restaurants | 43.4 (+7.4 textures) | 9 (22.2) | 9,057 | 34 | 317 (9) | 214 |
| hospital | 14.9 | 5 (15.2) | 6,761 | 125 | 282 (7) | 235 |
| supermarket | 12.1 | 2 (8.5) | 4,142 | 22 | 150 (4) | 120 |
| airport | 9.3 | 1 (4.3) | 4,910 | 40 | 150 (3) | 154 |
| warehouse | 9.2 | 2 (8.0) | 1,997 | 16 | 98 (4) | 174 |
| school | 8.7 | 1 (5.4) | 3,054 | 51 | 150 (3) | 160 |
| home | 7.5 | 4 (3.4) | 4,818 | 52 | 150 (2) | 270 |
| police | 6.8 | 1 (4.2) | 1,998 | 19 | 94 (3) | 107 |
| mystery | 6.4 | 1 (2.7) | 4,556 | 26 | 114 (3) | 238 |
| library | 6.3 | 1 (3.8) | 2,025 | 10 | 109 (3) | 115 |
| sports, bank, furniture, clothing, bakery | 3–4.5 each | 0–2 | 1,200–2,300 | 15–40 | 53–94 | 14–100 |
| playground, chapel, electronics, barn | 0.4–2.3 each | 0 | 1,100–1,700 | 9–16 | 34–62 | 10–22 |
| **all 19 units** | **150 (157 with textures)** | **32 (≈ 93)** | ≈ 56,000 | | | |

- `instantiate()` alone: 1–23 ms per unit. The freeze is the plush sculpts (one per frame already),
  scripts' `_ready`, and Main's hook-up (word areas, seats, doors, batching) in the last frame.
- **Freeing a unit's nodes and its `Unit_<key>` batches gave back little**: mystery 0.6 MB of
  6.4, supermarket 1.9 of 12.1, school 2.1 of 8.7, restaurants 27.8 (20.4 buffers + 7.4 textures)
  of 51. Something still holds the meshes (candidates in the proposal: `sculpt_cache.gd` `_built` /
  `_shared`, `indoor_visibility.gd` `_pieces`, render_culling's shared unit meshes, the
  `ResourceLoader` cache of the unit scene).
- **Font atlases in staged loading:** after all units were added one by one the default font held
  170 size/outline caches and **303 MB** of glyph atlases (texture total 430 MB), against 61 caches
  / 37.5 MB when the town loads at once. Each `add_unit()` runs `Main.apply_world_language()`,
  whose `sign_language.gd apply()` puts every sign in the town back to its own font size
  (`sign_font_size`), undoing render_culling's `share_label_sizes()`, which on the web is re-run
  only for the new unit's parts. The probe re-shared the whole town after each unit (natively),
  so the size of the effect on the web is not measured; see the proposal's stage 0.

## After the fix (17 Nov 2026, native M5, each run once)

- **Stage 0** (`results_signs_fixed.json`, every unit added one by one, web sign path forced):
  video 341 MB (was 660), textures 117 MB (was 430), default font 91 size/outline caches and
  52.9 MB of atlases (was 170 and 303 MB). The whole town at once had read 334 MB.
- **`add_unit()` steps** (`time_add_unit.gd`, ms; before the split into four frames):

  | unit | place + ready | reference layout | word areas | seats | batching (add_parts) |
  | --- | ---: | ---: | ---: | ---: | ---: |
  | home | 70 | 19 | 9 | 9 | 31 |
  | restaurants | 103 | 21 | 41 | 16 | 41 |
  | mystery | 33 | 20 | 2 | 8 | 21 |
  | hospital | 172 | 20 | 16 | 13 | 46 |
  | library | 40 | 20 | 10 | 4 | 9 |

  Other steps 0.1–6 ms each. The worst frame after the split was not measured.
- **`verify.gd`: 19 checks, 0 failures.** The first run had 18 of 19: two library book titles off
  a shared size step, because `library_book.gd` sizes them itself after `sign_language.gd`; the
  check now skips them.
- **`tools/run_checks.py --only tutorial,minigame_launcher,signs`: PASS 3** (37, 71, 8 s).
- Not measured: the web build, a phone, the full suite.
