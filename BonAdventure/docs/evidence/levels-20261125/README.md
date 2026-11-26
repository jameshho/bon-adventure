# Designed levels for every learning game (LEARN-06, 25 Nov 2026)

Decision D11 (user, 25 Nov 2026): build **all** designed levels in one milestone. Each game's
ladder is owned by its learning card in the [game guide](../../game/minigames.md#how-games-get-harder);
the data keys and code are in [MINIGAMES.md → Progression](../../guides/MINIGAMES.md#progression).

## What changed

- `data/activities.json`: `"levels"` for Who's Who?, Flight Finder, Stack & Pack, On the Menu,
  Spot the Suspect, Feel the Clues, Desk Dash, Mystery Doors, Library Helper (4 each) and
  Wire It Up! (3). Next, Please! keeps its within-session progression (no ladder designed).
- `activity_board.gd`: `begin(id, level_rounds)` (a level's question / door / book count; the
  picker's changed rounds still win) and `complete()` now also finishes a pastime with no target.
- Every covered game calls `add_miss()` once per round that went wrong (before, only Grocery Run,
  On the Menu and Feeding Time! did), so stars and unlocks work. Mystery Doors completes after
  its last door even with misses.
- New phrase `police.lineup_three` (three clues); `grammar.intro` says the level's seconds.

## Choices made where the design left a number open

Recorded on the learning cards: On the Menu L3/L4 add a *no* / *sin* to about one order in three
(`negation_chance` 0.35); Mystery Doors L1 uses colour clues (not shapes) and L1–L2 the four basic
colours; Wire It Up! L3 is 6 wires (the box's maximum); Feel the Clues L4 is 5 objects (the most
the object set allows for every clue); Spot the Suspect L4 has five
suspects (user, 25 Nov: the lineup room has five numbered spots; designed as six). Where a card said "(today)" but a later level adds part of today's game
(Flight Finder's *anteayer* / *hace*, Spot the Suspect's negation, Feel the Clues' report rounds),
the later level has it and the earlier one does not.

## Open

- Desk Dash L3/L4 prefer bank questions of `level` 2 or more, but every question in the three
  banks is level 1: until harder questions are written (and the Chinese reviewed), L3 plays like L2
  and L4 like L2 at 7 s.
- A Replay straight after a finished Mystery Doors game starts a new session before the board's
  `ended` fires, so that game's stars are not recorded (as before; Desk Dash's Replay is similar).

## Checks (25 Nov 2026, `python3 tools/run_checks.py --only …`, isolated HOME, `dev_focus` all)

First run: PASS `flight_logic`, `activity_lifecycle`, `zoo_feeding`, `game_exits`, `language`;
NEW in eight checks, all from a new profile now starting at level 1 (e.g. Desk Dash 15 s, four
suspects, three wires) plus two mistakes in the new tests. The older checks now pick the level
they test with `GameProgress.unlock()` (Stack & Pack, Spot the Suspect, Feel the Clues, Mystery
Doors: 3; Desk Dash, Wire It Up!: 2; Library Helper's cart check: level 2, 4-5 books); the
launcher check takes Library Helper's book count as its rounds. Second run, once each: PASS
`minigame_progression`, `warehouse_game`, `police_detective`, `grammar_class`, `mystery_house`,
`library_sorting`, `electrical_box`, `minigame_launcher` (each with the known harmless Godot abort
after its summary). Not in the runner: Who's Who? and On the Menu have no registered game check;
their levels are covered only by `minigame_progression`'s logic tests. After the user chose five
suspects for Spot the Suspect L4: PASS `minigame_progression`, `police_detective` (once each).
Not played by hand.

## Views

`capture.gd` (graphics, `--audio-driver Dummy`): [lineup-l4.png](lineup-l4.png) (five suspects,
three clues), [evidence-l4.png](evidence-l4.png) (five objects), [library-l4-cart.png](library-l4-cart.png)
(plain spines), [wires-l3.png](wires-l3.png) (six wires).
