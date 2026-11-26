# Improvement plan: decision log

## Made

| Date | Decision | By | Why |
| --- | --- | --- | --- |
| 25 Nov 2026 | Start with seven read-only audits; no game file changes before the user reviews the plan | user brief | The brief, section 10 |
| 25 Nov 2026 | Tracking files go in `docs/guides/improvement-plan/`, not a new top-level folder | coordinator (to be confirmed by the user) | The [docs layout](../../README.md#folder-layout) forbids new files at the top of `docs/` and allows guides with their own folders |
| 25 Nov 2026 | P0 is reserved for data-loss risks; none has been seen in play, but all three are cheap and protect learner progress | coordinator | Brief: P0 = critical bugs, crashes or data loss |
| 25 Nov 2026 | Performance-sensitive visual work (GFX-01/02) is written by A1 in `render_culling.gd`, with A2 proposing | coordinator | Performance is the user's top priority (one graphics setting since 23 Nov) |
| 25 Nov 2026 | The phone UI-size finding is recorded as "arithmetic confirmed, real device unconfirmed" | coordinator | There is no stretch mode in `project.godot`; the browser pixel ratio decides the real window size |
| 25 Nov 2026 | Recommend sequential milestones with at most one side session | coordinator | Every check loads the whole town; worktrees need a fresh import; verification budget |
| 25 Nov 2026 | D2: mahjong work committed (`278d40f1`); sheep and restaurant-retry leftovers stay uncommitted (not loaded by the town / one check script) | user | M0 known revision |
| 25 Nov 2026 | D3: approve one performance probe run and one full suite | user | M0 baseline |
| 25 Nov 2026 | D5 phone sizes: render at 844×390 and check on the user's phone first, then add the ≈44 px floor and compact layouts panel by panel | user | UI-02 |
| 25 Nov 2026 | D6 contact shadows: **roll out everywhere** (characters, animals, vehicles, props), measuring draw cost as it goes | user | GFX-01 |
| 25 Nov 2026 | D6 **reversed**: no contact shadows. After playing the zoo build the user saw a dark sideways wedge from the plants and chose to remove them rather than fix them ("doesn't really affect the gameplay feel"); the C9 work was reverted uncommitted | user | GFX-01 |
| 25 Nov 2026 | D7 voice: per-language packs downloaded when a language is chosen, cached for offline | user | PERF-04 |
| 25 Nov 2026 | D8 review timing: add a capped real-time term (additive save field). Numbers (built 25 Nov, coordinator session, tune by play): 1 real day = 1 FSRS day (`AWAY_DAY_WEIGHT`) added to the step clock, at most 7 days (`AWAY_DAYS_CAP`; a 2-month break counts as a week, so only words with stability under about a week come due); at most 8 words due only by time away count as due per session (`AWAY_REVIEWS_PER_SESSION`, most forgotten first; a session starts after 3 h without a question), the rest rank first among known words, so new words keep coming. Save: `unix` per word and per language, `away_left` per language; old saves add no time until their next question | user | LEARN-03 |
| 25 Nov 2026 | D9 known words: known = remembered well by the word memory; shown in the journal and on the results card | user | LEARN-04 |
| 25 Nov 2026 | D10 word pools: grow Stack & Pack and Feel the Clues first (from words.json/game data only) | user | LEARN-05 |
| 25 Nov 2026 | D11 levels: build **all** designed levels in one milestone | user | LEARN-06 |
| 25 Nov 2026 | D12 NPCs: face the player while talking (whole figure, eased back); no extra idle gestures | user | ANIM-07 |
| 25 Nov 2026 | D13 BonBon gait: try cadence-follows-distance; user compares walk/sprint/slow-stick renders before it is kept | user | ANIM-03 |
| 25 Nov 2026 | D14 look: try all three (light veil, pastel ground tones, palette tidy-up), each shown as before/after renders | user | P3-15, P3-23, P3-22 |
| 25 Nov 2026 | Journal redesign approved (separate session): a sticker book of places and topics, not built; it supersedes UI-03 and shows LEARN-04's "known" as a flower ([Journal](../JOURNAL.md)) | user | UI-03, LEARN-04 |

## Open decisions

| # | Question | Blocks | Options |
| --- | --- | --- | --- |
| D1 | Approve the plan and milestone order | everything | approve / reorder / trim |
| D4 | One session in order, or a side session for G3/G5 | scheduling | sequential (recommended) / one side session |
| D15 | Where the tracking files live (`docs/guides/improvement-plan/`) and whether to commit them | committing this folder | keep here / elsewhere |
