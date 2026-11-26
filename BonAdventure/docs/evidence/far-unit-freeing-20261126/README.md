# Freeing far buildings, far plush meshes and arrival spread — 26 November 2026

User, 25–26 Nov 2026: "now free far buildings to fix the memory" (option B of the
[performance guide's proposal](../../guides/performance/README.md#proposal-load-only-nearby-buildings-on-phones--17-november-2026)),
then, relayed from a side chat: also spread each building's arrival over more frames, pre-warm
shaders, and option C (free far plush characters' meshes). Why: a phone's browser kept killing
the page for memory ([restarts](../../guides/FINAL_VERIFICATION.md#web-restarts-save-button-and-home-spawn--25-november-2026)),
because nearby loading only ever added buildings.

All numbers are native (M5, GL Compatibility, 1280 × 800 window) with the web path forced
(`VT_NEARBY=1`); video memory is the renderer's own counter. Nothing here was measured on a phone.

## Checks (each run once on the finished code)

| script | what | result |
| --- | --- | --- |
| [`verify.gd`](verify.gd) | walk from the home to the sports store (273 m): the home, library and restaurants are freed (pending again, stand-in pivot, batches and sessions gone, no freed door, seat or vehicle left); walk back: they return with sessions, batches and all 14 doors, and the sports store goes again; every unit freed and added again; pins (driven vehicle, running minigame) | 42 / 42 PASS, no SCRIPT ERROR |
| [`verify_plush.gd`](verify_plush.gd) | strip and restore the restaurants area's 20 plushes twice; the FarPlushMeshes node strips far plushes and restores them before they are within their 45 m draw range when the player comes back at 120 m/s | 14 / 14 PASS |
| [`time_arrival.gd`](time_arrival.gd) | frame times while a unit arrives (`--prefetch`, `--prepare`) | numbers below |
| `../nearby-loading-20261117/verify.gd` | nearby loading as built on 17 Nov | 19 / 19 PASS |

## B. Freeing far buildings

- Video memory: town start at the home (5 units) 243 MB; at the sports store (10 units, home,
  library and restaurants freed) 265 MB; every unit loaded 370 MB, every unit freed 210 MB, every
  unit loaded again 372 MB (no pile-up after a full cycle).
- Found while testing: a freed minigame session's input claim stayed in the interaction
  controller (`active_claim()` called a lambda on a freed object, many SCRIPT ERRORs); claims
  whose callable is no longer valid are dropped now.
- Radius: load within 150 m (unchanged), free beyond 220 m (`FREE_RADIUS`), the farthest first,
  one per 0.5 s, only when nothing is waiting to be added.

## C. Far plush meshes

- Restaurants area (restaurants, home, police, supermarket, library loaded): 20 plushes, 593
  mesh parts, 451 distinct meshes. Stripping all 20: video 253 → 207 MB (46 MB), the same in the
  second cycle; restoring all 20 took 177–179 ms, the worst single plush 19 ms; video back to
  251 MB.
- Found while testing: `render_culling.gd` kept a triangle count per Mesh object in a dictionary,
  which held every plush mesh alive (stripping first gave 253 → 251 MB). It is keyed by id with a
  weak reference now.
- Each distinct mesh is saved once to `user://far_meshes/` (on the web that folder is in the
  page's memory too, compressed); a restored mesh is shared again by the plushes that shared it
  (451 distinct before and after).

## Arrival spread (and the shader warm-up that was dropped)

Worst frame of a unit's arrival, ms (first arrival / second arrival of the same unit; `—` not run):

| unit | before (17 Nov path) | load ahead only (`--prefetch`) | prepare + split tail (built) | prepare + shader warm-up (dropped) |
| --- | --- | --- | --- | --- |
| restaurants | 176 / 124 | 92 / 76 | 122 / 82 | 158 / 161 |
| hospital | 349 / 144 | 283 / 71 | 245 / 109 | 152 / 150 |
| home | 110 / 101 | 83 / 78 | 69 / 62 | 158 / 159 |
| police | 61 / 43 | — | 38 / 34 | 153 / 152 |
| supermarket | 45 / 36 | — | — | — |

- Built: `nearby_units.gd prepare()` loads a unit's scene in one frame and instances it in the
  next while it is still 150–190 m away; `add_unit()` then only adds the prepared nodes. The end
  of `add_unit()` had render batching (35–54 ms) and the minigame sessions (up to 36 ms) in one
  frame; a frame now separates them.
- The remaining worst frames are the scene `load()` itself (the restaurants' and hospital's
  110–135 ms; the web build has no threads, so it stays on the main thread) and, the first time,
  adding the hospital's nodes (245 ms).
- Shader warm-up, tried and removed: each distinct material (9–25 per unit) drawn once, tiny, in
  front of the camera, as a mesh and a one-instance MultiMesh, lit by a tiny omni light. Warming
  the same unit a second time cost 11–14 ms, so the warmers did compile shaders, but the arrival
  frames were no shorter, and every warm-up added 150–160 ms frames of its own. The arrival's
  first-draw cost is mostly batching and other variants. Not tried on the web, where shader
  compiles cost more.
- Target was 16–30 ms; not reached.

## Not verified

A phone; the web build's memory over a long walk (see the
[FINAL_VERIFICATION entry](../../guides/FINAL_VERIFICATION.md#freeing-far-buildings-and-far-plush-meshes--26-november-2026));
how a returning building looks as it appears in the fog; doors, carts and NPC positions resetting
when a building returns (they do: a returned unit is its saved scene again).
