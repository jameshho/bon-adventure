# Police Station Detective Games — revised prompt (draft 6 Nov 2026)

Revised from the user's original prompt with the user's answers of 6 November 2026.
Status: **approved and built 6 Nov 2026.** The decisions are recorded in the
[master design brief](../../guides/TOWN_DESIGN_BRIEF.md#police-station-enlargement-and-detective-games--6-november-2026)
and the [minigame index](../../guides/MINIGAMES.md); this file keeps the prompt and the plan as approved.
**Game 2 (evidence) was redesigned on 8 Nov 2026** and its section below is historical: see
[Police evidence game redesign](../../guides/TOWN_DESIGN_BRIEF.md#police-evidence-game-redesign--8-november-2026).

## Decisions taken in chat (6 Nov 2026)

| Topic | Decision |
| --- | --- |
| Structure | **Two separate minigames**, each with its own officer, "!" offer and activity-board entry (not one game with two activities) |
| Station | **Whole shell enlarged from 12 × 15 to 20 × 22** (model units; ×1.3 in the world). **Front fixed**: facade, door, entrance walk, parking and police car stay; the shell grows rearward and evenly to both sides |
| New rooms | **Suspect lineup room** beside the existing holding cell; **evidence room** with a counter and an examination table |
| Officers | **Crocodile officer moves inside** and runs the lineup by the holding cell (no officer remains outside). A **new cat plush officer** (police outfit) runs the evidence counter. The pig mascot stays at reception |
| Rewards | **None.** Ignore coins and rewards for now; progress bar and first-try counts as in the other games |
| Difficulty | No difficulty levels for now. **Every description uses 2 clues** (one may be a negation, e.g. *no tiene barba*) |
| Suspects | **One plush species: bear.** Only the tested features differ |
| Sound | **No audio for now.** The Escuchar tool is **visual only**: sound waves. Real sounds are documented as a future addition |
| View | **3D rooms with a fixed camera** for the lineup and the evidence table; click suspects or objects; clue and tools in the dialogue panel |
| Posters | **Two teaching posters**: "¿Cómo es?" (appearance) by the lineup, Mirar / Tocar / Escuchar properties in the evidence room; every word clickable |
| Floor plan | **Approved as drafted** (below); small adjustments allowed where existing furniture or doors require them |
| Gender | Suspects may look male or female (women never have a beard or moustache), but **all clue wording stays masculine** (*el sospechoso*, *alto*, *rubio*) |
| Delivery | **One commit at the end** (asked first). Development runs use `dev_focus.txt` = `police`; final checks and the commit use `all` |

## Step 0 — Enlarge the police station

Rebuild the shell at 20 × 22 with the front wall, door and door axis exactly where they are now. Keep
every existing room and its contents (reception desk and pig, two office desks, map, coffee counter,
waiting chairs, bulletin board, records/equipment room, interview room, holding cell with its door and
grille, both working doors, word keys, locker labels), rearranged into the larger plan. Inspect the
baked `RelocatedSites/Police` site and saved overrides first; follow the runtime-resize approach used
for the school and supermarket; keep the police car, parking and entrance corridor clear; update the
`police` zone if the footprint leaves it; preserve all door metadata.

Proposed plan (front at the bottom, door unchanged; sizes approximate, model units):

```
                        REAR WALL (20)
+------------+------+----------+----------------------+
| Interview  |Recs/ | Holding  |  Lineup room  ~8 x 7  |
| room       |equip.| cell     |  height-chart wall,   |
| ~5 x 7     |~3x7  | ~4 x 7   |  5 bear suspects;     |
|            |      | [Croc] → |  viewing line + rail  |
+-----+------+--  --+----  ----+--------  ------------+
| Evidence room ~8 x 7  |                             |
| exam table, shelves,  |      Lobby / reception      |
| boxes; "Mirar/Tocar"  |      [Pig] behind desk,      |
| poster                |      waiting chairs, board   |
| counter [Cat] ======  |                             |
+-----------------------+  office desks L and R,      |
| (lobby side)                coffee counter          |
+--------------------------[ DOOR ]-------------------+
                        FRONT (fixed)
```

## Game 1 — Identificar al sospechoso (lineup officer: crocodile)

- Talk to the crocodile (click / E, standard dialogue panel, "!" offer and activity-board entry).
- Camera moves to a fixed view of the lineup: **5 bear suspects** in front of a height-chart wall.
- The officer gives a **2-clue** description in the foreign language, e.g. *Tiene el pelo corto y barba.*
  / *Es alto y lleva una camisa azul.* / *No tiene barba y tiene el pelo largo.*
- Click a suspect: highlight, then confirm. Wrong → short feedback naming which clue does not fit,
  without revealing the answer; retry. Right → next round.
- **4 rounds** per session (configurable); progress bar; leave question before quitting early.

Appearance attributes (A1–A2):

| Attribute | Values |
| --- | --- |
| Height | alto, bajo |
| Hair length | pelo largo, pelo corto, calvo (no hair) |
| Hair colour | negro, castaño, rubio, pelirrojo (not shown when bald) |
| Facial hair | barba, bigote, sin barba |
| Nose | nariz grande, nariz pequeña |
| Shirt colour | rojo, naranja, amarillo, verde, azul, morado, rosa |

Generator rules: build 5 suspects from attribute combinations; the target is always present; the 2 clues
identify exactly one suspect (verified against the generated data, otherwise regenerate); distractors
share at least one clue with the target; invalid combinations (bald + hair colour/length) are impossible;
order and target position random; avoid repeating the previous clue pair; balance tested attributes.
Every visible feature is built from the same data the clue uses.

## Game 2 — Examinar las pruebas (evidence officer: cat)

- Talk to the cat at the evidence counter; camera moves to a fixed view of the examination table with
  **4 objects** (3–5 configurable).
- The officer describes a mystery object with **2 properties**, e.g. *Es pequeño y duro.* /
  *Es brillante y hace un sonido fuerte.*
- Three tools in the panel; pick a tool, then click an object:
  - **Mirar** (magnifying glass): close-up view of the object (slow turn) and its visible properties:
    grande / pequeño, largo / corto, brillante / oscuro, colour (rojo … rosa).
  - **Tocar** (hand): soft objects squash, hard ones do not move; rough vs smooth close-up texture;
    wet objects show droplets and a glossy surface, dry ones none.
  - **Escuchar** (ear), **visual only**: sound-wave graphic beside the object. Fuerte = tall smooth
    waves, silencioso = flat line, ruidoso = jagged scribble. No audio yet.
- Occasionally the officer adds a tool instruction (*Toca los objetos.*, *Escucha.*); choosing that
  tool first is expected.
- Select the object, confirm; wrong → feedback naming the clue that does not fit; retry.
- 4 rounds per session, progress bar, leave question.

Object database (data file, each with explicit properties): piedra, esponja, llave, campana, tela,
bloque de madera, papel, botella, cuerda, pelota. Properties are confirmed only through the tools.
The same uniqueness, balance and no-repeat rules as Game 1 apply.

## Vocabulary and data

- All text (clues, officer lines, feedback, tool names, posters) lives in `data/words.json` /
  `data/phrases.json` with en / es / zh; no hard-coded language strings. Adjective agreement through
  the existing language rules (clues refer to *el sospechoso* / *el objeto*).
- About 40 new words (appearance, properties, three verbs, new objects, *el sospechoso*, *la prueba*);
  reuse existing ones (azul, verde, amarillo, rojo, grande, pequeño, esponja, botella, pelota, madera,
  nariz, camisa). No duplicate synonyms.
- Game data: `data/detective_game.json` (rounds, suspects attributes, object properties).
- Code: one clue generator / validator shared by both games, two thin session scripts, presentation
  (suspect builder, evidence table, tool effects) separate from logic. Reuse the activity board, npc
  presence, dialogue panel, progress bar, popup stack, player lock and leave question.

## Verification

- Headless generator test: thousands of random rounds per game; every round has exactly one match and
  every rendered feature matches its data.
- Police interior check updated for the new shell; resource load; one batch of rendered views
  (exterior, plan, lineup, evidence table, tool effects, posters). Results recorded in
  `FINAL_VERIFICATION.md` with known suite failures compared by label.

## Future (documented, not built)

- Real audio for Escuchar (bell ring, key jingle, paper rustle, thud), coins/rewards, difficulty
  levels (1 / 2 / 3 clues), more attributes (glasses, hats, age), more tools.

## Build record (6 Nov 2026)

The checkpoint's open issues are closed: the 26 Chinese readings were added to
`data/pinyin_zh.json`; the sleeve error only happened when a suspect was dressed outside the
scene tree (in the game the stage is always in the tree). Built after the checkpoint: the card
(`scripts/ui/detective_card.gd`), one session script for both games
(`scripts/learning/police_detective_session.gd`), the Main wiring, both activities, the tool
icons, the checks (`verify.gd`, updated police-interior and police-officer checks) and the
views (`capture.gd`, `*.png`).

Found in the rendered views: the first build was the mirror image of the approved plan
(the interior code's "left" was the right seen from the door). `police_interior.gd` now mirrors
everything it places about the door axis; `verify.gd` checks that the evidence room is on the
left and the lineup room on the right seen from the door. Results: [final verification](../../guides/FINAL_VERIFICATION.md#police-station-enlargement-and-detective-games--6-november-2026).
