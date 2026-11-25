# Improvement plan: session handoff

**Read this first in a new session,** then [MASTER_PLAN.md](MASTER_PLAN.md) and the open
decisions in [DECISION_LOG.md](DECISION_LOG.md#open-decisions).

## State on 25 Nov 2026 (afternoon)

- The user approved the plan, answered the 10 design questions ([DECISION_LOG.md](DECISION_LOG.md)) and asked for the [fast track](MASTER_PLAN.md#fast-track-small-chunks-user-25-nov-2026) in parallel sessions.
- **Done by the coordinator:**
  - mahjong work committed (`278d40f1`);
  - M0 performance probe ([baseline](PERFORMANCE_BASELINE.md));
  - one full suite ([results and triage](TEST_RESULTS.md));
  - C0 runner fix;
  - C3 web pack 91.4 → 65.5 MB;
  - zh readings for 掉顆舍.
- **Running in sessions, sharing this checkout:**
  - saves-words (C1, C4)
  - game-exits (C2, C8)
  - motion-light-ui (C6, C7, C5)
  - contact-shadows (C9)
  - characters (C10, C16, ANIM-05)
  - ui-scale (C13, UI-06, phone render, light veil)
  - word-pools (C14)
- **Uncommitted, coordinator:** `crab.gd` (cached player and shared material) and `zoo_gate.gd` (stops processing when settled). These need a check once `main.gd` parses again.

## Next step

1. As each session reports, integrate its notes into `FINAL_VERIFICATION.md`, the game guide and the tracker.
2. Then rebuild the CJK font subset (after all phrase additions).
3. Then triage the NEW labels in [TEST_RESULTS.md](TEST_RESULTS.md).
4. Finally, rerun the full suite once all sessions have committed.

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
