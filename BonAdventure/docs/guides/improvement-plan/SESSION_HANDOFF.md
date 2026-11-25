# Improvement plan: session handoff

**Read this first in a new session,** then [MASTER_PLAN.md](MASTER_PLAN.md) and the open
decisions in [DECISION_LOG.md](DECISION_LOG.md#open-decisions).

## State on 25 Nov 2026 (end of the fast track)

- The user approved the plan, answered the 10 design questions ([DECISION_LOG.md](DECISION_LOG.md))
  and ran the [fast track](MASTER_PLAN.md#fast-track-small-chunks-user-25-nov-2026) in eight
  parallel sessions sharing this checkout. All of them committed; every commit and check is in
  [FINAL_VERIFICATION](../FINAL_VERIFICATION.md#improvement-plan-fast-track-nine-sessions--25-november-2026).
- **Done:** C0, M0 desktop probe, C1, C3, C4, C2, C8, C5, C6, C7, C10, C13 (UI-01, UI-06), C14
  (Stack & Pack only), C16, P3-15, the stale-check fixes, the font rebuild. Statuses are in the
  [tracker](TASK_TRACKER.md).
- **Rejected:** C9 contact shadows (built, then removed uncommitted; D6 reversed). The patch is
  kept outside the repo in the session notes folder.
- **Full suite** at `dfd2be4c`: PASS 73, KNOWN 3, NEW 1 (`bank_rework` timing race), CRASH 1
  (`app_flow`, once; passed alone). [Results](TEST_RESULTS.md).

## Next step

1. P2: watch `app_flow` (one segfault in the loading screen). `bank_rework` is traced and fixed.
2. Wave 2 left: C11 known words (LEARN-04), C12 real-time review (LEARN-03), per-language voice
   packs (PERF-04), `request_leave()` in the other in-world games, the phone size floor (UI-02,
   after the user's phone check).
3. Wave 3: all designed levels (LEARN-06), the web sculpt cache (PERF-03), shader warm-up
   (PERF-06), palette tidy-up and ground tones (P3-22, P3-23), the web and phone perf runs.
4. Bamboo voice clips need the user's `aws sso login`.

## Commit history note (25 Nov 2026, user: leave it)

The sessions share one git index. While the ui-scale session had its files staged, the
characters session committed, so:

- `65385841` ("Calling NPC eases down from its hop…") also holds **the whole UI-01 change**:
  `BonStyle.factor()` in `bon_style.gd`, the 15 UI scripts that use it, the `UI_STYLE.md`
  section and `docs/evidence/ui-scale-20261125/`.
- `aa99be5f` ("UI-01: one window scale formula") holds only a one-word comment fix in
  `capture.gd`.

The user chose not to rewrite history. To find the UI-01 work, look at `65385841`.

## How to resume a milestone

1. Read its rows in the tracker.
2. Re-check the cited line numbers, which may have moved.
3. Set the tasks to In Progress.
4. Make the change.
5. Run its listed checks once.
6. Log the results.
7. Ask the user before committing.
8. Set the tasks to Completed and update this file.

If a session ends mid-milestone, write down here:

- what is done;
- what is half-done (files and the exact point reached);
- what was not verified.
