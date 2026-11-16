# Bon Adventure logo and rename, 16 Nov 2026

The user's logo (five animals over a cloud reading "Bon Adventure", ribbon "Little Town of
Words") replaces the earlier text title on the title page, and the game is renamed
**Bon Adventure: Little Town of Words** (user decision, 16 Nov 2026). This folder has the
VTracer trial, the rendered title page and the new app icon.

## Result

The title page shows a **cleaned raster**, not a VTracer trace. The trace looked slightly worse
everywhere and did not save download size.

- Source, unmodified: `assets/branding/source/bon_adventure_logo_source.webp` (1672 × 941, lossy
  WebP on white, 124 KB). The folder has a `.gdignore`, so it is not imported or exported.
- Cleaned: `assets/branding/bon_adventure_logo.webp` (1530 × 724, lossless WebP, 573 KB in the
  repository), made by `assets/branding/source/clean_logo.py`. The white page around the logo is
  made transparent (a flood fill from the edges; the white cloud and the cat stay because the
  brown outline encloses them), the outline's anti-aliased edge is un-blended against white, and
  the image is trimmed to the logo plus 6 px.
- Imported as Godot **lossy WebP 0.9 with mipmaps**: 248 KB in the web build. Without mipmaps it
  would be 149 KB, but the thin brown outlines alias when a small window shrinks the logo to
  about a third of its size.
- Drawn by `scripts/ui/app_screens.gd` `_splash()`: 820 design pixels wide × the window factor
  (min(h / 800, w / 1100), like every page), above the Play button. The page's fit check shrinks
  both on small landscape phones. If the picture is missing, the `app.title` text appears instead.

## VTracer trial (Python vtracer 0.6.15, run from a scratch folder)

The trace input was the cleaned, transparent PNG. Tracing the white-background original would put
a full-size background path under everything, and it could not be separated from the white cloud
and the white cat. `trace.py` has the three settings and `svg_cleanup.py` the cleanup: it drops
empty paths (VTracer wrote 57 empty ones) and speckles under 30 px² of bounding box, and rounds to
0.1 px. Rendered with Godot's own SVG renderer (ThorVG, `Image.load_svg_from_string`) at 1×.

| Version | Paths | SVG | gzip | Render 1× | Mean abs. diff vs original | Pixels > 40 off |
|---|---|---|---|---|---|---|
| lean | 110 | 111 KB | 38 KB | 4 ms | 7.8 | 4.8 % |
| balanced (`traced_balanced.svg`) | 273 | 359 KB | 120 KB | 11 ms | 7.3 | 4.2 % |
| fine | 3431 | 1.11 MB | 331 KB | 27 ms | 6.9 | 4.0 % |
| cleaned raster as WebP q90 (for scale) | | 131 KB | | | 0.9 | 0.0 % |

**What it looks like** (zoomed crops, original on the left: `cmp_*.webp`, `cmp4x_*.webp`):

- **Lean** loses detail: the "o" in "Town" and "of" fills in solid, the pig's nostrils and
  darker snout merge into one blob, and the faint mane strokes on the lion go.
- **Balanced** is the best trace and reads fine at a glance. Zoomed in, the outlines wobble
  slightly (the ribbon's bottom edge is scalloped), the curves have small notches (the bowl of the
  "d" in "Adventure"), the white cloud becomes a faintly blue #F1FAFD (it was #F9FFFB), there is a
  pale halo between the blue letters and the cloud, and some thin lines go (lion mane strokes).
- **Fine** keeps more lines but adds dirty edges: pale speckles along outlines and on cheeks, and
  doubled edges on the lettering.
- **Lettering:** the traced letters stay legible at all three settings. Only "balanced" keeps the
  counters (the holes in o, d, e) correctly. None of the traces is as smooth as the original's
  letter edges, so tracing does not improve the lettering.

**Size in the web build.** Godot imports an SVG as a bitmap at its import scale, so the build
holds a texture either way. The balanced SVG imports to 183 KB (lossless, no mipmaps). The
cleaned raster imports to 149 KB (lossy 0.9) or 248 KB with mipmaps. The raster lossless import
would be 601 KB: the source's lossy WebP noise compresses badly. So the trace gives no size win.

**Verdict:** a raster. A vector would only help if the logo had to be drawn bigger than its
1530 px source. On screen it is about 740 px on a 1280 × 720 window, about 1200 px on a phone at
device resolution (2532 × 1170, `title_2532x1170.png`) and about 2200 px in a full-screen 4K
window. The 4K case upscales the raster 1.45× and looks slightly soft. It is the
only case where the trace could win, and its lumpy edges would show there too. A clean vector
logo would have to be redrawn by hand or exported from the logo's original design file, not
traced.

## Rendered title page

`capture.gd` (graphics needed; draws only the screens before the town) writes `title_<w>x<h>.png`:
1280 × 720, 1440 × 900 and 1100 × 620 (laptop windows), 844 × 390 and 667 × 375 (phones held
sideways, CSS pixels) and 2532 × 1170 (the same phone at device pixels). Inspected: the logo is
centred above Play at every size with nothing clipped, and the lettering is sharp at the
2532 × 1170 size.

## App icon (user, 16 Nov 2026: the user's own icon picture)

The icon is the user's picture `assets/branding/source/app_icon_source.webp` (988 square: the
pig's head on mint), used as it is. `tools/make_app_icons.gd` scales it down to
`assets/ui/app/icon_{512,192,180,144}.png` (Lanczos). Two earlier versions are in git history: the
vector pig of 13 Nov 2026 (`tools/app_icon.svg`) and, earlier on 16 Nov, the pig cut out of the logo
(first over a cloud ledge, then head only).

`icon_sizes.png` shows the 192 px icon as a square, with iOS corner rounding, in a round launcher
and in the maskable safe zone (the middle 80 % circle that Android keeps), plus 144, 48, 32 and
16 px. The head fills the picture: its outline runs from 2 % to 96 % of the width, so its farthest
point is 0.53 of the width from the centre. Square icons and iOS rounding (the corners are mint)
show it whole. A round crop clips the ear tips and the lower sides of the face, and the maskable
safe zone cuts much more. The manifest does not mark the icons maskable, so Android shows them
whole, at most inside its own background shape. The head is also about 2 % left of centre. It
reads well at 48 and 32 px; at 16 px (a browser-tab favicon) it is a pink face with ears.

## Rename: done and left

Done here: the title page logo, `app.title` (its fallback text), and the web page's title plus the
PWA manifest's `name` and `short_name` ("Bon Adventure"), written by `tools/deploy_web.py` after the
export. `project.godot` `config/name` stays "Vocabulary Town" because desktop saves are keyed to it.
The separate BonBon/Bon Adventure → BonBon rename (16 Nov 2026) owns `config/name` and its save
migration, the remaining old-name text, the repository, the web address and the storage keys.
This session first renamed `config/name` with a migration that copies the whole old folder,
profiles included (tried with an isolated `HOME`: 3 files copied once, the second run copied
nothing). It handed that work to the rename session and reverted it here.

## Checks run

- Resource import (`godot --headless --import`): the logo imports. Running `make_app_icons.gd`
  wrote the four icons.
- `python3 tools/run_checks.py --only language,app_flow`: PASS 2.
- The `deploy_web.py` title and manifest rewrite tried on the published `gh-pages` `index.html`
  and `index.manifest.json` (not a new export).
- Title page rendered as above. **Not run:** a web export, installing on a phone, the new icon on
  a home screen, and the full check suite (only the title page, `app.title`, the icons and the
  deploy step changed).
