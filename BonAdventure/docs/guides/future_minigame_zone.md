# Future idea: a shared MiniGameZone (deferred)

> **Built 8 Nov 2026 (user request), so this note is history.** The zone is
> `scripts/learning/minigame_zone.gd` (fade, placing the player, doorway), used by the
> Grammar Classroom; the leave question moved to the wider NPC host `minigame_host.gd`, used
> by five games. How to use both: [Building a minigame](MINIGAMES.md#building-a-minigame).
> The warehouse still has its own copy (section 4).

Developer note, 6 Nov 2026. **Not implemented, on purpose.** Written with the
[Grammar Classroom](GRAMMAR_CLASS.md), at the user's request, so the idea is recorded before
more in-world minigames are built.

## 1. The concept

Several minigames now run *in the world*, not in a panel: the player is moved somewhere,
temporary things appear, a boundary is watched, leaving asks first, and everything is cleaned up
at the end. A `MiniGameZone` would be one small component that owns that shared life cycle, so
each game keeps only its own rules.

## 2. What it would own

- Starting and ending an in-world session, with the fade (`_make_fade` / `_fade_to`).
- Putting the player at a start point, and back at a safe point (position, yaw, camera).
- Turning temporary game objects on and off (labels, highlights, markers).
- Watching an entry or exit boundary (an `Area3D`, or a bounds test).
- Asking "are you sure you want to leave?" through the shared quit card, pausing meanwhile.
- Pause and resume of a running countdown.
- Clean-up, and `end_activity()` on a language change.
- Telling the activity board (`activity_board.gd`) when it is running.

## 3. What the Grammar Classroom would hand over

In `scripts/learning/grammar_session.gd` these functions are already grouped so they could move
with little rewriting:

| Function | Moves to the zone as |
|---|---|
| `_make_fade`, `_fade_to` | the zone's fade |
| `_place_player` (and `School.START`, `School.INSIDE`) | `place_player(spot, look)` |
| `_make_doorway`, `_outside_school` | the boundary watcher |
| `ask_leave`, `_on_leave_answered` (pause, quit card, resume, "No" puts the player back inside) | `ask_leave()` with a `paused` / `resumed` signal |
| `end_class` (the clean-up part), `end_activity` | `end()` |

Classroom-only parts stay in the session: questions, desks, the board, scoring and feedback.

## 4. Other minigames it would fit

- **Warehouse** (`warehouse_session.gd`): the same fade, start point (`_to_station`), bounds
  watch (`_outside_copy`), leave question and clean-up, in a copy of the building.
- **Restaurant, police lineup and evidence, flight**: they use a panel more than the world, so
  only the leave question and the clean-up would apply.
- Future in-world games (sports hall, playground, supermarket aisles).

## 5. Why it is deferred

Only two games (warehouse, classroom) use the world this way, and they differ: the warehouse
builds a copy of the building, while the classroom uses the real room and never moves the
player between questions. A shared class written from two examples would guess at the third.
The duplication today is about 60 lines each, and the shared dialogue panel and activity board
already hold the parts that are truly common.

## 6. When to do it

When a **third** in-world minigame is built, or when a bug fix has to be made in the same place
in two games (the fade, the leave question, or the boundary). At that point, extract the table
above into `scripts/learning/minigame_zone.gd`, move the warehouse and the classroom onto it
one at a time, and run each game's check (`docs/evidence/warehouse-20261105/verify_game.gd`,
`docs/evidence/grammar-class-20261106/verify.gd`).
