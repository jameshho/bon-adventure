# Grammar Classroom

Game name (user, 10 Nov 2026; [all names](MINIGAMES.md#minigame-index)): **Desk Dash** · *¡A tu pupitre!* · 搶位答題.

The school's grammar minigame (built 6–7 Nov 2026 from the user's brief; decisions below).
Lana, a sheep plush teacher, stands by the board in the general classroom. The player answers
fill-in-the-blank questions by **sitting at the desk** that shows the right answer.

## How it plays

1. Talk to Lana (E or click) → "Would you like to join grammar class?" → **Yes** fades the screen
   and puts the player in the aisle between desks C and D (−6, −0.4; moved closer to the board on
   8 Nov 2026). It is the real classroom, not a copy.
2. A class is **5 questions** (user, 14 Nov 2026; was 10) from the bank of the language being
   learned, with no repeats except the **review** (user, 8 and 14 Nov 2026): **every** question
   answered wrong or not at all comes back once at the end ("Question 3 of 6", toast
   `grammar.review_later`); the old "only in classes of more than 5 questions" limit is gone.
   A review answered wrong is not repeated again; it scores like any question. So a class of 5
   has at most **10** questions, and the card's title and points bar count the questions so far
   (5 + reviews queued). A review comes straight after itself only when the class's last
   question was its only remaining miss (nothing else is left to ask in between; the feedback,
   the walk back and reshuffled desks separate the two). The launcher's rounds work the same
   way (n questions, at most 2n). The sentence is on the board, with pinyin under it when Chinese is learned. Its four answers,
   shuffled each time, lie on the four front desks (A B in the front row, C D behind).
3. **10 seconds** per question. The player sits at a desk with E (stepping in from the aisle
   beside the chair, or from behind it while facing it: since 7 Nov 2026 the seating controller
   prefers the chair the player faces, so E behind an answer chair no longer picks the chair in
   the row behind) and may stand up and switch freely. The seconds left are a **large number at
   the top centre of the screen** (above the board, so the question stays readable) with a short
   hint below it: "Hurry! Pick a desk!" while standing, "Press Confirm or wait" while seated
   (`grammar.hurry` / `grammar.seated`); the last 3 seconds turn red and pulse (user, 8 Nov 2026).
   The card's large on-screen **Confirm** button submits at once. It is enabled only at
   an answer desk, and a second press is ignored. When the time runs out, the desk the player
   is sitting at counts; standing anywhere counts as **unanswered**.
4. **Feedback for 2 seconds** after a right answer; after a wrong or missed one it stays until the
   player presses **Continue** (the Confirm button, relabelled; `grammar.continue`) or 10 seconds
   pass (user, 9 Nov 2026). Neither comes out of the next countdown:
   - the right desk turns green;
   - the card shows ✓ or ✗, the right sentence (with its meaning in the player's language);
   - the card shows a one-line explanation.

   **Translation (user, 23 Nov 2026):** the card has no translate bubble of its own. Holding the
   HUD's EN button (or L) shows every line on the card in both languages (title, hint, feedback,
   Confirm/Continue) and, during a question, the question's meaning under the title row; letting
   go shows only the language being learned again. A peek counts as the translation seen for
   practice tracking. Renders: [`grammar-peek-20261123/`](../evidence/grammar-peek-20261123/).

   **Walk back (user decision, 8 Nov 2026; replaces "the player is never moved"):** after every
   answer (right, wrong or unanswered) the game stands the player up and walks them back to the
   start in the aisle: from the aisle side of the chair straight across to the aisle (round
   behind the chair only if she stood up on the wall side), then along it to (−6, −0.4), facing
   the board. Controls are locked meanwhile; the walk runs during the feedback and the
   next question starts only when both are over (a walk takes about 1.5–2.5 s). If BonBon cannot
   stand up, stops making progress for 0.8 s or walks for over 6 s, she is placed at the start.
   The leave question stops the walk; **No** carries on walking. The walk uses the player
   controller's `auto_walk` points (`player_controller.gd`), so physics, collisions and the walk
   animation are the normal ones.
5. After the last question (reviews included), Lana gives the points and offers **Play again** or **Finish**. The box stays
   open anywhere in the school; closing it counts as Finish.
6. **Leaving:** the card's exit button, Esc, or walking out of the school entrance (an `Area3D` just outside the
   door, active only during a class) pauses the countdown and asks "Are you finished with class?"
   - **Yes** ends the class.
   - **No** puts the player just inside the entrance and resumes the same question with
     the time it had left.

   A language change ends the class at once.

**Dialogue box in class (user, 7 Nov 2026):** from the start of a class to its clean-up, Lana's
lines use the shared dialogue box's compact mode (`shop_order_panel.gd` `set_compact()`): half the
window wide, low at the bottom centre, text at 72 %, buttons at full size, so the board and the
desks stay in view. Outside a class (the invitation, the farewell, every other NPC) the box is the
normal one. Renders: `docs/evidence/grammar-class-20261106/dialogue-*-before.png` / `-after.png`.

No coins or rewards: points only, like the other minigames (user decision, 6 Nov 2026). The
activity board entry is `grammar_lana` (`data/activities.json`); its bar shows the points.

## Files

| What | Where |
|---|---|
| Classroom remodel, Lana, constants (desk grid, board, start, doorway) | `scripts/buildings/school.gd` steps `grammar_classroom` and `bigger_board` (14 Nov 2026), baked into `scenes/town/school.scn` |
| Game flow | `scripts/learning/grammar_session.gd` |
| Question banks: load, pick, shuffle, rules | `scripts/learning/grammar_questions.gd` |
| Questions | `data/grammar_class/es.json`, `zh.json`, `en.json` |
| Card (title, points bar, countdown, feedback, Confirm, leave) | `scripts/ui/grammar_card.gd` |
| Lana's lines and the card's text | `data/phrases.json` group `grammar` |
| Wiring | `scripts/core/minigame_wiring.gd` (called from `main.gd` `make_shops()`, `make_popups()`, `_on_settings_changed()`) |
| Check, renders | `docs/evidence/grammar-class-20261106/verify.gd` (runner id `grammar_class`); bank rules in `tools/language_check.gd`; `capture.gd -- room` / `-- game [code]` / `-- dialogue <suffix>` / `-- board` (14 Nov 2026, into `docs/evidence/grammar-class-20261114/`) (results in [FINAL_VERIFICATION.md](FINAL_VERIFICATION.md#grammar-classroom--7-november-2026)) |
| Deferred shared component | [future_minigame_zone.md](future_minigame_zone.md) |

The board and desk text are `Label3D`s built at runtime (not saved). **Board text (14 Nov
2026, user):** the board is 6.0 × 2.6 (was 4.8 × 2.0); the sentence is 144 px and the pinyin
96 px (half as large again as before) in a deep navy ink (`0f1e3a`) on a brighter board with a
darker frame. The sentence wraps to the board's width; when the sentence and its pinyin
together would be taller than 86 % of the board, both are set smaller (down to 72 px,
`_fit_board()`), and the two lines are stacked and centred a little above the middle. The
board's size is read from its `grammar_board` meta. The board text is in the
language being learned whatever the Display Mode, because it is the exercise. The green desk is
a thin runtime plate with its own material just above the desk top (the top itself is merged
into a static batch by `render_culling.gd`, and its material is shared town-wide, so neither is
touched).

## Question banks

One JSON file per **taught** language, named by its code. A new language needs only its file
(and its text in `phrases.json`), with no code change. A language without a file has no class:
Lana says so. Format and rules are in each file's `about`. In short:

- `text` has exactly one `___`; `choices` are four different answers; `answer` is one of them
  (the word itself, so shuffling can never change it).
- `explain` and the optional `meaning` exist in every other playable language (the player's
  native language). Chinese questions add `noun`, the `words.json` key of their noun.
- **Every wrong choice must be impossible in that sentence**, not merely less usual. Sentences
  where two answers work are left out (for example *feliz* with ser/estar; *the cat is ___ the bed*).
- `tools/language_check.gd` checks the rules and that every Chinese character has pinyin.

**Content decisions (user, 6 Nov 2026):**
- **Spanish:** ser vs estar only.
- **Chinese:** measure words only, using only the measure words that are the same in Mandarin
  and Hong Kong writing; no Simplified Chinese.
- **English:** subject–verb agreement and prepositions only, in the first version.
- **Starter set:** 16 questions per language; the long-term target is about 100 per language.
- **Review:** the Chinese text and the Chinese and Spanish explanations are Claude's draft,
  awaiting review by a speaker.

## The classroom (approved remodel, 6 Nov 2026)

See the [design brief](TOWN_DESIGN_BRIEF.md#grammar-classroom-remodel--6-november-2026) for
the layout, the numbers and the renders.
