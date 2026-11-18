# Welcome tutorial: second review — 17 Nov 2026

The user's nine fixes after playing the "Little Town of Words" tour:

1. In the house only the door where Leo hides opens; every other door stays shut and the guide
   says her friends would not hide there (outside the hunt: "That's not where we're going right
   now!").
2. "You found everyone" and "There's so much more I want to show you" zoom back to the guide
   (also "You found one" and "Let's go outside!", the same moments).
3. Sunny's "But wait... we need some food first!" is in her close-up.
4. A player who picked BonBon (the default avatar) is guided by another character (the next in
   `data/house_characters.json` order: Bruno).
5. The cast no longer boxes the player in at the supermarket: they walk to the store front, south
   of the player's way to the door.
6. "Replay the welcome tour" starts with every home door shut and no one napping on a bed.
7. No house character sits on the couch during the tour (every house twin is hidden, naps off).
8. "Let's take a peek!" is gone.
9. The shopping list is 1 apple and 2 bananas ($1.50).

Design notes: [welcome tutorial](../../guides/ARCHITECTURE_REVIEW_PART1.md#welcome-tutorial).

`verify.gd` (check `tutorial` in `tools/run_checks.py`, replacing
`tutorial-script-20261117/verify.gd`, which it copies and adapts) plays the whole tour with a
BonBon profile and simulated input, then replays it after opening the front door and putting a
house twin to bed. With graphics it saves the views in this folder.

## Result (17 Nov 2026)

`HOME=<scratch> VT_FOCUS=all VT_SPAWN=none godot --path . --resolution 1280x800 --script res://docs/evidence/tutorial-review-20261117/verify.gd`
(`dev_focus.txt` = `all`; the tutorial itself loads only home and supermarket first, the rest
behind the town reveal): **TUTORIAL: 135 checks, 0 failures**, 19 views saved. Godot exits with
code 137 after printing the result (killed while quitting); the result line is what counts.

Views: `found-all.png` (Bruno's close-up from the living room), `need-food.png` (Sunny's
close-up), `market-cast.png` (the cast beside the store front, the way to the door clear; list
1 apple, 2 bananas), `replay-wake.png` (replay: suite door shut, no one on the bed), and the
earlier steps' views as in `tutorial-script-20261117/`.

Notes on the check itself:
- The tutorial opens the guest suite's door ("Guest bath door") and the family bathroom door
  itself; both stand open and cannot be shut. The other home doors stay shut with the guide's line.
- Screenshots wait at most 5 s for a drawn frame: macOS stops drawing a hidden window or one on a
  sleeping or locked display, and an earlier run hung there (no failure in the game). Such a view
  is reported as `NOT DRAWN` instead.
- Progress lines go to stderr (not buffered when redirected); a watchdog ends a run that hangs
  after 6 minutes and names the step it stopped at.
- Not tested by hand on a touch device; the cast's market spots are checked from one start
  position (the act's place step).
