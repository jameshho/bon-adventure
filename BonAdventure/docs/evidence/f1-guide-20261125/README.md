# F1 controls guide: window scale, touch view, Settings entry (25 Nov 2026)

Improvement plan UI-04 ([tracker](../../guides/improvement-plan/TASK_TRACKER.md)). Player view:
[playing.md](../../game/playing.md#moving-and-controls). Code: `vocabulary_hud.gd` (the block
after `make_ui_card`: `help_sections()`, `touch_help_sections()`, `_paginate_help()`),
`settings_panel.gd` (`controls_requested`), `main.gd` (`open_controls_guide()`).

## What changed

- **Scale:** the guide's sizes are design sizes × `maxf(BonStyle.factor(view), 0.75)` (the same
  readable floor as the HUD status texts, UI-06). The card is `1240 × 700` × that scale, never
  closer than 16 px to the window edge.
- **No scroll bar:** the section cards are packed into columns and pages that fit, from the fonts'
  line counts (`TextParagraph`, as a Label wraps); a card taller than a page splits and repeats its
  heading. ‹ › and the page number show when there is more than one page; a horizontal swipe
  (or mouse drag) on the cards turns the page too. The page area is a plain Control, so a page can
  never stretch the card off the window.
- **Touch view:** **Keyboard** / **Touch** tabs; the guide opens in the touch view on a touch
  device (`touch_mode`, or a touch screen with no key pressed yet). Its chips look like the real
  controls: the dark round stick, E and jump buttons, the soft blue HUD buttons (Run, Lights,
  Siren, Reset, ▲ ▼, Drop, journal, map, ▶, Passport, gear), the peek badge, and teal gesture
  pills (Tap, Drag, Pinch). No debug toggles in this view (they need keys).
- **Settings → Controls** (next to Switch player / Replay): closes Settings and opens the guide;
  hidden while a minigame runs (the guide is closed then too). It was the only way to the guide
  without a keyboard (the ? button is hidden since 14 Nov).
- **Style:** card, sections, key caps, chips and pills through `BonStyle.flat()`; tabs
  `BonStyle.style_toggle`; ‹ › `"soft"` and ✕ `"soft_quiet"` buttons. The ✕ is 56 design px
  (≥ 52 px) instead of a corner button's size, which made the header twice as tall.
- The identical Helicopter and Turboprop key cards are one **Helicopter & plane** card (both
  views). New phrases `help.tab_*`, `help.page/prev/next`, `help.touch_*`, `help.t_*` (es, en, zh);
  icons `stick`, `pinch` in `ui_icons.gd`. All their Chinese characters were already in the font
  subset (`build_cjk_font.py --check` lists 4 others, 播歌碌首, missing from earlier work).

## Renders

`capture.gd` (usage in its header; graphics, isolated `HOME`, `VT_FOCUS=home VT_SPAWN=none`, so
only the home building is loaded) renders Settings, every page of both views in English, page 1
of both views in Spanish and Chinese, and the guide opened from Settings on a touch device; it
checks every page for cards past the page area or the window (`F1 GUIDE FIT: ok` at both sizes)
and writes the button sizes to `sizes.md`.

| Size | Keyboard (en / es / zh pages) | Touch (en / es / zh) | Guide buttons |
| --- | --- | --- | --- |
| 1280 × 800 ([folder](laptop-1280x800/)) | 1 / 2 / 1 | 1 / 1 / 1 | ✕ 56, tabs 48 high |
| 844 × 390 ([folder](phone-844x390/)) | 3 / 3 / 3 | 3 / 3 / 3 | ✕ 52, tabs and ‹ › 44 |

Key views: [laptop keyboard](laptop-1280x800/keys-en-page1.png),
[laptop touch](laptop-1280x800/touch-en-page1.png), [phone touch](phone-844x390/touch-en-page1.png),
[phone keyboard, Chinese](phone-844x390/keys-zh-page1.png),
[Settings](laptop-1280x800/settings.png), [Settings on a phone](phone-844x390/settings.png),
[from Settings on touch](phone-844x390/settings-to-guide.png).

## Limits

- The Settings **Controls** button is 75 × 25 px on the 844 × 390 phone, like Settings' other
  buttons (Settings shrinks its whole card to fit; the touch-size floor is UI-02, decision D5).
- The day clock still sits over the Settings title on the phone (recorded in
  [ui-scale-20261125](../ui-scale-20261125/README.md)).
- Not tried on a real phone or tablet; swipe paging is checked only by reading the code.
