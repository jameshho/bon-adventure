# Small polish batch — 18 November 2026

- **Library book titles** (`scripts/world/library_book.gd`): only books with a cover title process;
  the refit check compares text and size directly (no string per book per frame); titles are fitted
  at the authored pixel size and outline; on the web (`SignLanguage.share_sizes`) the fitted size
  is drawn at the next `RenderCulling.LABEL_SIZES` step with a smaller pixel size, so titles share
  glyph atlases ([performance guide](../../guides/performance/README.md#built--17-november-2026)).
  `books_native.png` / `books_web.png`: the same six covers in both modes look the same.
- **Tutorial Skip button** (`scripts/learning/tutorial.gd`): a `BonStyle` soft pill instead of the
  hand-styled dark navy and gold box; restyled only when the window scale or text changes
  (`skip.png`).

Checks: `verify.gd` (graphics, no town) 43/43; `run_checks.py --only tutorial,library_sorting,signs` all PASS (full town, `dev_focus.txt` = all, once each).
Not measured: glyph-atlas memory on the web or a phone.
