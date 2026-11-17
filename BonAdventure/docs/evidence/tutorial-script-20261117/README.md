# Welcome tutorial: "Little Town of Words" script — 17 Nov 2026

The user's revised tutorial script (house, market, park), with their answers: Leo keeps his
place (only his lines changed), lines advance on their own (a click or tap skips), the "UI" lines
go in a new reusable [instruction strip](../../guides/COMPONENTS.md#instruction-strip), and the
tour ends with a simple picnic (placeholder lines). Also: the statue card reads "statue of George
Washington", and the journal's book button is cuter with a clearer J.
Design notes: [welcome tutorial](../../guides/ARCHITECTURE_REVIEW_PART1.md#welcome-tutorial).

`verify.gd` (check `tutorial` in `tools/run_checks.py`) plays the whole tour with simulated
input: the control gates, the strip texts, finding the friends in either order, the drag-only
curtain, BonBon's progressive hints and door remarks, the skippable cutscene and subtitle, the
shopping list's checks and "Oops!", the cash-only payment with a wrong try, the leave guard and
lot limit, the statue word, the journal, the picnic and the stop/restore. With graphics it saves
the views in this folder.

| Run (17 Nov 2026) | Result |
| --- | --- |
| `python3 tools/run_checks.py --only tutorial` (headless, `VT_FOCUS=all`) | 88 checks, 0 failures (before the last picnic and strip tweaks) |
| `verify.gd` with graphics, `VT_FOCUS=all`, isolated HOME | **89 checks, 0 failures** (exit 137 is the usual quit) |

Views: `wake`, `strip-get-up`, `strip-look`, `strip-move`, `curtain-drag`, `friend`, `reveal`
(cutscene with subtitle), `shop-list`, `cookies`, `pay`, `statue-card`, `journal-button`,
`book-icon` (4× crop), `picnic-talk`, `picnic`.

Limitations: `statue-card.png` does not show the word card (the check that the statue's word is "statue of
George Washington" passed, but the card was not seen on screen);
`picnic-talk.png` falls between two lines, so no bubble shows; the cookie hint's wording ("on a
shelf past the fruit, deeper in the store") was not checked against a clear view of the shelf.
The picnic lines are placeholders for the user to rewrite.

Other checks (17 Nov 2026): `python3 tools/run_checks.py` (quick, `VT_FOCUS=all`): 6 PASS and
`language` NEW: seven characters of the new lines had no pinyin (冒 偷 哈 呢 喂 觸 湊); added to
`data/pinyin_zh.json`, then `--only language` PASS. `tools/vocabulary_report.gd -- --write`:
5479 checks, 0 failures, `docs/game/words.md` unchanged (the statue's key is unchanged; the
tutorial is not a minigame). The full suite was not run.
