# Spanish world signs — 27 October 2026

> **Stale since 9 Nov 2026:** signs now hold every taught language and the Spanish-authored
> signs switch too; see [world signs](../ARCHITECTURE_REVIEW_PART1.md#vocabulary-data-procedure).
> `verify.gd` here expects the old English → Spanish table and no longer applies.

World signs (every `Label3D` under the town) read in Spanish by default and switch
back to English when the HUD language is English (L / language button). Signs that
were already Spanish, proper names and codes are untouched.

| Piece | Responsibility |
| --- | --- |
| `data/sign_translations.json` | Exact English label text → Spanish sign text (98 entries; `\n` for two-line labels; `_comment` is ignored). Reuse the `data/words.json` wording without the article where a key exists. |
| `scripts/world/sign_language.gd` | `translate_all()` runs last in `world_refinements.gd::build()`: stores `sign_english`, `sign_spanish` and `sign_font_size` metadata, adds the label to the `translated_signs` group, shows Spanish. `set_language()` switches every grouped label. |
| `scripts/ui/vocabulary_hud.gd` | `language_changed(mode)` signal from `cycle_language()`; 0 English, 1 Spanish, 2 both. |
| `scripts/core/main.gd::make_ui()` | Connects the signal: English mode restores English signs; Spanish and Both show Spanish. |

**Fit.** Single-line labels whose Spanish is more than two characters longer than
the English shrink their font in proportion (minimum 50%); wrapped labels keep
their size and reflow. English mode restores the original font size. Check new or
much longer entries in a render: the shrink uses character counts, not measured
glyph widths.

**Adding a sign.** Add the exact English text as a key (case, spacing and bullets
matter), then run `verify.gd`: it lists remaining labels that still contain
English-looking words. Fixed before/after views: `capture.gd`.
