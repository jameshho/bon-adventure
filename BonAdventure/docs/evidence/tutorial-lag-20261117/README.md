# Tutorial lag — 17 November 2026

User: the first dialogue boxes inside the house lag; the first impression must be smooth, and a
longer first load is fine if the progress bar shows real progress. Change: the tutorial starts
behind the loading screen and the views of its house act are drawn there first; the bar is
weighted to the real work ([welcome tutorial](../../guides/ARCHITECTURE_REVIEW_PART1.md#welcome-tutorial),
"Start behind the loading screen").

## Cause

Every first draw of a material compiles its shader, and in WebGL that stalls the page. The
warm-up (`app.gd` `_warm_up()`) looked round the scene's default player spot, then the tutorial
moved the player to the guest-suite bed, built its cast and zoomed in on BonBon: the bedroom,
the plushes' close-up and the dialogue box were all drawn for the first time while the first line
was on screen. The desktop build does not show it (its driver compiles fast and caches).

## Web, first launch (the measurement that matters)

Local `tools/deploy_web.py --out` builds (not published), served on `127.0.0.1`, each in a fresh
Google Chrome profile (empty shader and IndexedDB caches, background throttling off), 1100 × 700,
driven the same way: Play, BonBon, Start, read the first line 3 s, Next, E (stand), drag to turn,
hold W 1.5 s. Frames over 50 ms, in ms since Start (a CDP script, kept outside the repository).

| | Before (old build) | After |
| --- | --- | --- |
| Loading screen up until | about 5 s | about 7 s |
| Slow frames while BonBon's first line and close-up are on screen | **3483**, 833, 450, 650, 233, 200, **1183** | none |
| Slow frames during stand, turn, walk | 283, 333, 100 | 167 |
| Slow frames under the loading screen | 1067, 650, 383, 367 | 1017, 650, 367, 367, 1517, 484, 517, 233 (bar moving) |

In the app's own browser pane (Chromium, the user's run of the old build) the same first-line
freeze was 1749 ms, and a 1067 ms freeze came around the bathroom close-up. The bathroom part of
the house act was not driven on the web after the change (the walk there is not scripted); on the
desktop build it has no frame over 40 ms.

## Desktop build

`measure.gd` (this folder), first launch, isolated HOME, `VT_FOCUS=all`:
- before: house act worst frame 18 ms; loading 3.2 s with one 1.6 s frame (the bar empty) and the
  bar standing full during "Getting everything ready".
- after: house act worst frame 26 ms; loading 4.0 s; the bar climbs from 0 to 1 in steps over the
  whole load (0.04, 0.07, 0.21 … 0.70, then about +0.02 per warm-up view).

## Checks

- `docs/evidence/tutorial-20261112/verify.gd`, headless, `VT_FOCUS=all`: **113 checks, 0 failures**.
- The title cutscene still stalls (100–580 ms frames) while the remaining buildings load behind
  it; unchanged and left for later (only its pictures stutter).
