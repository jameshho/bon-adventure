# Welcome tutorial, second review (21 Nov 2026)

The user's second review list and follow-ups ([guide](../../guides/ARCHITECTURE_REVIEW_PART1.md#welcome-tutorial),
"Review 2, 21 Nov 2026"). `verify.gd` starts a new profile at the market act (the house act is
covered by `tutorial-polish-20261118/verify.gd`) and plays to the end, then talks to the picnic
party, replays and skips.

Run (graphics, isolated saves; keep the window uncovered or macOS stops drawing it):

```sh
HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --always-on-top --path . --script res://docs/evidence/tutorial-review2-20261121/verify.gd
```

Result, 21 Nov 2026 (dev focus `all`): **REVIEW2: 64 checks, 0 failures.** An earlier run with the
window covered drew nothing; its shot timeouts broke the line timing (7 failures), so it is not
counted.

| View | Shows |
| --- | --- |
| [cashier-ask](cashier-ask.png) | The cashier asks for "un dólar con veinticinco centavos" in her close-up; no shopping list |
| [cashier-pay](cashier-pay.png) | The money panel: make $1.25 from $1 bills and quarters |
| [cashier-thanks](cashier-thanks.png), [meet-outside](meet-outside.png) | Her thanks, then the pan to BonBon's "Great job! Let's meet outside!" |
| [everyone-ready](everyone-ready.png), [picnic-time](picnic-time.png) | The two lines outside the store (BonBon, then Leo) |
| [look-over-there](look-over-there.png), [closer-look](closer-look.png) | Sunny, then the pan to BonBon |
| [statue-card](statue-card.png), [statue-name](statue-name.png) | The statue's card; its name 0.2 s after the card closed (measured 204 ms) |
| [picnic-eat](picnic-eat.png), [picnic-yum](picnic-yum.png), [picnic-thanks](picnic-thanks.png), [goodbye](goodbye.png) | Every picnic line in its speaker's close-up; each box waited for the pan (about 1.55 s without a box: 0.6 s gap, 0.7 s pan, 0.25 s) |
| [party-top](party-top.png), [party-wide](party-wide.png), [party-back](party-back.png) | After the tutorial: the 6 x 4.75 m blanket with BonBon, Sunny and Leo seated on its edges (player hidden) |
| [party-player](party-player.png), [party-talk-bonbon](party-talk-bonbon.png), [party-talk-sunny](party-talk-sunny.png), [party-talk-leo](party-talk-leo.png) | The player's view and each character's first chat line (each rotates three lines) |
| [price-tag](price-tag.png) | The produce tag reads $1.25 (taken during the skip's fade, with the last chat bubble still up) |

Not covered: the house act (not re-run), touch input, the web build. A chat bubble still showing
when a replay starts stays until it times out (seen in `price-tag`; low priority).
