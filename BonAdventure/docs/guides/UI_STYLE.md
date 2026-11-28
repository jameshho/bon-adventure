# UI art style: cosy cream and meadow

The one look for every 2D screen, card, dialogue box and button (user, 18 Nov 2026). The user's
mockups are the reference; build to them, do not reinterpret them:

| Mockup | What it shows | Fidelity |
| --- | --- | --- |
| [character-grid.webp](design-references/ui/character-grid.webp) | "Pick your character": 4 × 2 tiles, selected tile, Back / Next; its 8 headshots are the portraits (cut from it at 2×, `assets/ui/avatars/source/cut_headshots.py`, 23 Nov 2026; vtracer traces before) | **Exact** |
| [profiles-and-languages.webp](design-references/ui/profiles-and-languages.webp) | Saved players with Delete and New player; "Choose Your Languages" with Just explore! | **Exact** |
| [loading-bar.png](design-references/ui/loading-bar.png) | Striped green bar (its cloud panel was dropped by the user, 18 Nov 2026) | **Exact** bar, no panel |
| [play-button.png](design-references/ui/play-button.png), [button-gloss.png](design-references/ui/button-gloss.png) | The glossy green pill button with a play triangle; the second is the gloss reference (user, 18 Nov 2026) | **Exact** |
| [money-panel.webp](design-references/ui/money-panel.webp) | Pay Up! (the money panel): request in a cream pill, soft blue section tags with icons, cream hand tray, bills on a light strip, bright rounded bills and coins, dark teal "×1" tags, total in a cream pill with a basket, cream Clear / Leave and green Pay (user, 18 Nov 2026) | **Exact** (`money_panel.gd`, `money_piece.gd`); the pattern for other in-game panels: cream pills and trays for text and holding areas on the soft blue card |
| [dialogue-box.webp](design-references/ui/dialogue-box.webp) | Cream dialogue box, speaker, green reply button | **Similar** (user: the speaker's name goes *inside* the box; the box keeps today's layout and behaviour, only texture, colour and font change) |

Status (18 Nov 2026): phase 1 (start screens, loading screen, dialogue box with its buttons and
quit card) is built and approved by the user (views: `docs/evidence/ui-style-20261118/`). Phase 2
(Settings, the journal, the HUD buttons and word card, the F1 guide) is approved with soft blue
cards and buttons; the minigame panels, cart, clock, translate bubble, instruction strip, progress
bar and "E" badge followed on 18 Nov 2026 (views `panel_*.png`, waiting for the user's review).
The money panel follows the user's mockup exactly. The mahjong table, the elevator floor picker
and the electrical box then took on its pattern: cream pills and trays on the soft blue card, a
green main action and a cream ✕ (views `panel_mahjong*.png`, `panel_electrical*.png`,
`elevator/`). The welcome tutorial's Skip button is a soft pill too (18 Nov 2026,
`docs/evidence/ui-perf-polish-20261118/skip.png`). Mahjong's gold "¡Mahjong!" win button and the gold "!" over NPCs stay gold.
Kept on purpose, as part of a game's own look: the radar arcade screen, the flight departures
board, the restaurant ordering tablet and menu book, the mahjong lesson's pink cards and the
minimap's map drawing.

## The feeling

Soft, warm and toy-like, like a children's picture book on a sunny day: rounded everything,
thick white rims, gentle gradients (no light reflections: user, 18 Nov 2026), never sharp corners, thin lines or dark
panels. Bright scenes stay visible behind the UI (no dark shade over the backdrop).

## Palette

All colours live in `scripts/ui/bon_style.gd` (`BonStyle`); use the names, never new hex values.

| Name | Hex | Use |
| --- | --- | --- |
| `INK` | `#16536a` | Titles, headings, dialogue text (dark teal, never black) |
| `INK_SOFT` | `#3a8f9e` | Hints and secondary text ("(Menu, help and translations)") |
| `BROWN` | `#7a4a22` | Text on cream pills and tiles (names, Delete) |
| `CREAM` | `#fdf4e3` | Tiles, name pills, dialogue box, loading panel |
| `CREAM_DEEP` | `#f6e7cc` | Pressed cream, the empty loading track |
| `RIM` | `#fffdf7` | The thick white rim around cards, tiles and buttons |
| `MINT_TOP` / `MINT_BOTTOM` | `#dff3f4` / `#eaf6e4` | Card background gradient (sky mint to meadow) |
| `BAND` | `#d3ecea` | Section bands inside a card ("I speak") |
| `SKY` (`SKY_TOP` / `SKY_BOTTOM`) | `#dff3f4` (`#f0fafb` / `#d5eef0`) | In-game cards and buttons: the word card, HUD buttons, journal table and tiles, F1 sections, Settings pickers and minor buttons (kinds `"soft"`, `"soft_quiet"`; user, 18 Nov 2026: the same soft blue as the page card, not cream) |
| `GREEN_TOP` / `GREEN_BOTTOM` | `#86d65e` / `#45a83c` | Primary buttons, selected tiles, the bar |
| `BLUE_TOP` / `BLUE_BOTTOM` | `#66bdf0` / `#2f87cf` | Back buttons, the speaker tag, Just explore! |
| `CORAL_TOP` / `CORAL_BOTTOM` | `#ff9b8a` / `#e0614f` | Destructive confirm (Delete in the question) |
| `SUN` | `#f7cf3f` | Daisy centres only (no yellow accents: user, 18 Nov 2026) |
| `LEAF` / `LEAF_DARK` | `#8fd067` / `#5aa83a` | Sprout, bushes |
| `TERM` | `#d9661c` | Words to learn inside a dialogue line (readable on cream) |

## Type

- **Fredoka** (SIL OFL, `fonts/Fredoka.ttf`, variable): `BonStyle.font(700)` for titles and
  buttons, `BonStyle.font(600)` for body and dialogue text. Chinese falls back to
  `fonts/NotoSansTC-SemiBold-subset.ttf` (as everywhere, `cjk_font.gd`); the pinyin line keeps
  Noto Sans (`pinyin_text.gd`).
- Sizes at design scale (1100 × 800, multiplied by the window factor `min(h/800, w/1100)`):
  page title 52, button 34 (big Play 48), tile name 26, heading 30, hint 20, dialogue line 30,
  speaker 24.
- Titles sit on a cloud banner; button text is white with a soft darker shadow; nothing has a
  thick outline except text over a photo.

### Window scale

Every 2D size is a design size times the window factor `f`. Get it from
`BonStyle.factor(view_size, low := 0.5, high := 3.0)` (since 25 Nov 2026, improvement plan
UI-01); never write `min(h/800, w/1100)` again. Keep the caller's floor: 0.5 for the HUD and
in-game panels, 0.6 for the start screens (`app_screens.gd`), the loading screen and the
tutorial's strip, cues and Skip button. `interact_badge.gd` passes `0.0, INF` (unclamped; its tap
radius has its own 22 px minimum). At 844 × 390 (a landscape phone) `f` is 0.5, so 0.5-floored
parts are half their laptop size; measured sizes and renders are in
[ui-scale-20261125](../evidence/ui-scale-20261125/). A touch-size floor (UI-02) waits for the
user's phone check (decision D5). The HUD's status texts (FPS, flight, sprint, noclip, quest
toast) scale with `maxf(f, 0.75)` so they stay readable on a phone (UI-06), and so does the F1
controls guide (UI-04), which pages its cards instead of shrinking them further.

## Parts

Build with `BonStyle`; never style a Button or panel by hand again.

In-game panels set `theme = BonStyle.theme()` on their root: every Label inside defaults to `INK`
Fredoka 600 and every Button without overrides is a soft blue pill with a white rim. Code that
resizes `StyleBoxFlat` fields uses `BonStyle.flat()` / `flat_button()`.

| Part | Look | Call |
| --- | --- | --- |
| **Card** | Mint gradient, white rim (6), radius 40, soft blue glow; bushes and daisies along the bottom (`decor`) | `BonStyle.card(content, f, decor)` |
| **Title banner** | Soft cream cloud: a pill base with a flat bottom, 3-5 big round puffs of different sizes along the top and round puffs at both ends, thin warm edge, soft shadow; `INK` text; a green sprout on the middle puff | `BonStyle.title(text, f)` |
| **Primary button** | Candy pill to the user's reference (18 Nov 2026, `design-references/ui/button-gloss.png`): green lighter at the top, darker at the bottom; no white reflections or streaks (user, 18 Nov 2026: the gradient alone gives the depth); a cream rim (5) with a faint warm edge and a soft warm shadow underneath so it sits raised. Soft and candy-like, never shiny or metallic. White text with a soft shadow; white icon (the play triangle has a dark green edge) | `BonStyle.button(text, "primary", icon, f)` |
| **Back button** | Same pill in blue, left arrow | kind `"back"` |
| **Minor button** | Cream pill, `BROWN` text and icon (Delete) | kind `"minor"` |
| **Danger button** | Coral pill (confirming a delete) | kind `"danger"` |
| **Centred contents** | Every button's icon and words sit in the middle as one group, and an icon-only button's icon is centred (user, 26 Nov 2026; the record player's ◀ ▶ were off to the left). Automatic for every button styled by `BonStyle.style_button` with centred words; list rows with left-aligned words are left alone | `BonStyle.center_contents()` |
| **Tile** | Cream rounded square (radius 24), white rim, soft shadow; a cream name pill at the bottom; selected = green gradient and a green check badge top-right | `BonStyle.tile(...)` |
| **Choice pill** | Cream pill with a round flag; selected = green with white text and a check | `BonStyle.choice(...)` |
| **Section band** | `BAND` rounded strip with heading (`INK`, 30) and hint (`INK_SOFT`, 20) | `BonStyle.band(...)` |
| **Progress bar** | Cream track with a dark `INK` outline; green fill with lighter diagonal stripes that drift slowly; on the loading screen it sits low with the line above it in light Fredoka with an `INK` edge, no panel behind | `BonStyle.StripedBar` |
| **Dialogue box** | Cream, white rim, radius 28, no tail (user, 24 Nov 2026: "remove the triangle in dialogue boxes, all"; the Mahjong lesson bubble lost its point too); the speaker's name in a blue pill *inside* the top-left; line in `INK` 600; replies are primary pills | `shop_order_panel.gd` |
| **Pastel icon** | The mockups' icon look (user, 24 Nov 2026): a thick `INK` outline (4.5 of 64) with pastel fills (sky blue `bfe6fa`, cream, a gold accent), never tinted by the button. The journal (a book with a gold star and ribbon; HUD button and the journal's title) and the speaker (the word card) | `BonStyle.icon_texture("journal" / "speaker")` |
| **Key hint** | A small `INK` circle (a pill for "Esc", "F9") with a white rim and a white key letter on a HUD button's bottom-left corner. Only while playing with a keyboard (user, 24 Nov 2026): hidden after a touch, back after a key press; the key is read from the input map | `vocabulary_hud.gd` `add_key_hint()` |
| **Name tag** | A small cream pill with a white rim and the button's short name in `INK` 600 (`hud.name_*`, `passport.title`) over the bottom edge of an icon-only HUD button (gear, journal, map, ▶ picker, Passport). The opposite of the key hint: shown for touch players (no tooltips), hidden after a key press (P3-16, 25 Nov 2026; [view](../evidence/touch-fixes-20261125/README.md)) | `vocabulary_hud.gd` `add_name_tag()` |
| **Slider** | Thick cream track that fills green up to a big white knob with a green rim; finger-sized | `BonStyle.style_slider(slider, f)` |

Decorations (sprout, daisy, check badge, flags, gamepad, plus, journal, speaker, knob) are SVG text in
`bon_style.gd`, rasterised at the needed size like `ui_icons.gd`: no image files, crisp at every
scale. Shapes (pills, cards, cloud banner, bushes) are drawn by `scripts/ui/bon_box.gd`
(a StyleBox) and `BonStyle` controls.

## Rules

- Big, friendly targets (AGENTS.md): buttons at least 64 design px tall, tiles 160+.
- Green = go / confirm / selected; blue = back / informational; cream = minor; coral = destroy.
  One green action per page, bottom right; Back bottom left.
- Selection is shown two ways at once: green fill and check badge (never colour alone).
- No yellow accents (sparkle dashes were removed, user 18 Nov 2026).
- Questions that leave something: the safe choice (Stay) green on the LEFT, the leaving one
  (Leave, coral) on the RIGHT (user, 18 Nov 2026).
- Text on cream or mint is `INK` / `BROWN`, never white; white text only on green, blue, coral.
- A page card should sit in proportion to the screen, not fill its whole height: the language
  page is built at 0.8 scale with a plain title (no cloud or sprout; user, 18 Nov 2026).
- Keep the scene bright: no dark full-screen shades behind cards. The veil behind Settings, the map,
  the journal and the word card is `BonStyle.SHADE`, a light cream veil (`CREAM` at 32 %; it was a
  teal shade until 25 Nov 2026, P3-15: [before/after](../evidence/ui-scale-20261125/README.md#p3-15-light-veil-d14-beforeafter)).
- In-game screens (everything after the start screens) use soft blue (`SKY`, kinds `"soft"`) where the start screens use cream; green stays for on/selected/go. Cream stays on the start screens (exact mockups) and the dialogue box.
- Motion is gentle: Play breathes (scale 1.04, 0.9 s), the bar's stripes drift, a press squashes
  to 0.96. Nothing flashes.
