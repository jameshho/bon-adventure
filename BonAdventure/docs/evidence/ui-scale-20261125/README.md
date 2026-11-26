# UI scale, status texts, phone sizes and the light veil (25 Nov 2026)

Improvement plan items UI-01, UI-06, decision D5 (phone render before any size floor) and P3-15
(decision D14, light veil). Rule: [UI_STYLE.md#window-scale](../../guides/UI_STYLE.md#window-scale).

## Scripts

- `capture.gd` renders the start screens, loading, the HUD (plain, word card, status texts),
  Settings, results, the minigame picker, map, Passport and stars card, and writes every visible
  button, slider and text box's pixel size to `sizes.md` (graphics, isolated `HOME`; usage in its
  header). `UI_FLAT=1` hides the 3D world for pixel comparisons.
- `compare.gd` compares two capture folders pixel by pixel. `pair.gd` builds the veil pairs.

## UI-01: `BonStyle.factor()` (no visible change)

The 16 copies of the formula in 15 files now call `BonStyle.factor(view, floor)`, with the same
floors as before (0.5 HUD and panels; 0.6 start screens, loading, tutorial strip, cues and Skip;
`interact_badge.gd` unclamped). Proof of concept first: `results_screen`, `star_card`, `loading_screen`.
`guide_arrow.gd:194` still has its own copy (outside this task's files).

Check: `capture.gd` with `UI_FLAT=1 --fixed-fps 60`, before (HEAD's versions of the 16 files) and
after, at 1280 × 800 and 844 × 390, then `compare.gd`:

| Size | Identical | Differences |
| --- | --- | --- |
| 1280 × 800 | 4 of 14 PNGs; **all control sizes identical** (`sizes.md`) | only the HUD clock (random start time of day) and the avatar's idle animation on the character and players pages |
| 844 × 390 | 8 of 14; all control sizes identical | the clock, plus the HUD status texts and quest toast (UI-06, intended) |

The flat before/after PNGs were not kept; `sizes/laptop-1280x800.md` is the after list.

## UI-06: HUD status texts

FPS, flight line, sprint line, noclip line and quest toast now scale in `_layout_hud` with
`t = maxf(f, 0.75)` (font sizes 15–18 and their offsets × t). At f = 1 (1280 × 800, 1100 × 800)
they are unchanged; on a 844 × 390 phone they are 3/4 size (12–14 px) instead of fixed
(`phone-844x390/hud-status.png`).

## D5: phone render at 844 × 390 (no floor added)

`f` = 0.49 → clamped to 0.5, so 0.5-floored parts are half their laptop size. Renders over the
town in `phone-844x390/` (taken before the veil change); all sizes in `sizes/phone-844x390.md`.

| Screen | Smallest targets on the phone (px) | Laptop 1280 × 800 |
| --- | --- | --- |
| HUD corner buttons | gear/EN 57 × 57; journal, map, picker, passport 52 × 52; Run 60 × 60; clock 88 × 46 | 90, 90, 52–90 |
| Word card | star and speaker **36 × 36** | 72 × 72 |
| Settings | ✕ **24 × 25**; check boxes **24** high; language drop-downs **27** high; Close **92 × 28**; sliders 52 high | ✕ 54, rows ≈ 54 |
| Results card | Play again **111 × 33**, Continue exploring 161 × 33 | 66 high |
| Minigame picker | tabs and tiles 52 high (already floored at 52) | 56 |
| Map | ✕ 44 × 44 | 56 |
| Passport | tabs 47–67 × 52, Go there 115 × 52 | 56 |
| Start: title | Play 205 × 67 | 341 × 112 |
| Start: character | avatar tiles 92 × 101; Back / Next **102 × 37** | 76 high |
| Start: languages | language pills 146 × **37**; Back / Start 106 × **39** | 62 high |
| Start: players | player cards 125 × 143; Delete **106 × 34**; Back / Next 117 × 43 | 64 high |

Bold: under the ≈ 44 px finger size of UI-02. Other phone problems seen in the renders:
- The Settings card is taller than the window: its top and Close button are cut off.
- The day clock sits over the Settings title row and the Passport's first tab.
- The place label under the minimap ("Front yard | 0 words found") is 8 px and unreadable.

## P3-15: light veil (D14 before/after)

`BonStyle.SHADE` (Settings, map, journal) went from a teal shade `(0.1, 0.27, 0.32, 0.38)` to a
cream veil `Color(CREAM, 0.32)`, and the word card's overlay `Color(0.03, 0.07, 0.10, 0.24)` now
uses `BonStyle.SHADE`. Before | after at 1280 × 800: `veil-hud-card.png`, `veil-settings.png`,
`veil-map.png`, `veil-passport.png` (the Passport has no veil: a control). Phone after:
`veil-phone/`. The two runs start at different times of day, so the light differs slightly.
