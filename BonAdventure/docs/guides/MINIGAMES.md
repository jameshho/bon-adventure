# Minigame index

Every minigame in Vocabulary Town in one table. Game names (user, 10 Nov 2026) are the
`games.<activity id>` entries in `data/phrases.json`, one per language. The activity ids never
change (they key the practice log):

| Activity id | English | Chinese | Spanish |
| --- | --- | --- | --- |
| `shop_supermarket` | Grocery Run | 買餸啦！ | ¡Al súper! |
| `family_dr_li` | Who's Who? | 誰是誰？ | ¿Quién es quién? |
| `warehouse_ramon` | Stack & Pack | 搬搬抬抬 | Carga y descarga |
| `flight_bruno` | Flight Finder | 搵航班 | Busca tu vuelo |
| `restaurant_twinkle` | On the Menu | 今日餐牌 | Menú del día |
| `grammar_lana` | Desk Dash | 搶位答題 | ¡A tu pupitre! |
| `lineup_rocco` | Spot the Suspect | 搵疑犯 | ¿Quién fue? |
| `evidence_mimi` | Feel the Clues | 證物實驗室 | Pistas al tacto |
| `mystery_luna` | Mystery Doors | 神秘之門 | Puertas misteriosas |
| `mahjong_mei` | Mahjong Club | 雀友會 | Club de mahjong |
| `radar_patrol` | Radar Patrol | 天空保衛戰 | Guardianes del cielo |
| `electrical_box` | Wire It Up! | 駁電線 | Cable a cable |
| `library_rosa` | Library Helper (user, 17 Nov 2026) | 圖書館小幫手 | Ayudante de biblioteca |
| `teller_bank` | Next, Please! (user, 18 Nov 2026) | 下一位！ | ¡El siguiente! |

The index below: This is an index: each game's design
record and ownership section hold the details, so update those first and keep only the
summary here. Each game's purpose and progression design is owned by its learning card in the
[game guide](../game/minigames.md) (user, 16 Nov 2026); its words are generated into
[game/words.md](../game/words.md). Add a row when a new minigame is approved. To try any game quickly, use the
[minigame picker](#minigame-picker) (F9 or the ▶ button).

| Minigame | NPC and place | Learning goals | Words and phrases | Status | Design / ownership |
| --- | --- | --- | --- | --- | --- |
| **Grocery Run** (customer order) | Beagle clerk (Twinkle's species), outside the supermarket door, left; paid at the samoyed cashier's till | Recognise product names and quantities; find the objects; understand the spoken total and count it out | Supermarket products (`sold_in`) with prices (`data/shops.json` `prices`), `shop.*`, `cashier.*`, `money.*` phrases | Built 3 Nov 2026; one round, no progress bar; 4 levels and stars since 18 Nov 2026 ([progression](#progression)); paid at the till, levels by price tier and free shopping with a basket since 21 Nov 2026 | [Design](TOWN_DESIGN_BRIEF.md#customer-order-minigame--3-november-2026), [ownership](ARCHITECTURE_REVIEW_PART1.md#customer-order-ownership--3-november-2026) |
| **Pay Up!** (cashier money) — *retired 21 Nov 2026, now Grocery Run's checkout ([record](TOWN_DESIGN_BRIEF.md#grocery-checkout-and-free-shopping--21-november-2026))* | Samoyed cashier at the supermarket till | Understand spoken amounts ($0.25–$300); count out bills and coins | Generated money amounts (`money_words()`), `cashier.*`, `money.*` | Built 4 Nov 2026; 5 rounds per session; 4 levels (amount range) and stars since 18 Nov 2026; on the shared host with the gold "!" since 9 Nov 2026 (it had none) | [Design](TOWN_DESIGN_BRIEF.md#cashier-money-minigame--4-november-2026), [ownership](ARCHITECTURE_REVIEW_PART1.md#cashier-money-minigame-ownership--4-november-2026) |
| **Who's Who?** (hospital family game) | Dr. Li (pig plush, doctor), outside the hospital, right of the entrance | Family relationships, ages, birthdays, months, older/younger, before/after | Family category, months, `family.*`; taught by four school posters | Built 4 Nov 2026; 20 questions per session | [Design](TOWN_DESIGN_BRIEF.md#hospital-family-game--4-november-2026), [ownership](ARCHITECTURE_REVIEW_PART1.md#hospital-family-game-ownership--4-november-2026) |
| **Flight Finder** (airport flight game) | Capitán Bruno (bear plush, pilot), information desk just right of the airport terminal door | Time expressions within two days of today (anteayer…pasado mañana, esta mañana / anoche, weekdays, a day with a clock time, hace / dentro de 1–3 horas), 4 countries by flag (from 8), past vs future, departures vs arrivals | 66 words (relative time, weekdays, clock, airport, salir/llegar/despegar, new Countries category), `flight.*`; taught by four terminal posters (countries with flags) | Built 5 Nov 2026; 5 questions per session, first-try progress; layout, flags and bilingual rows revised 6 Nov 2026; board-only redesign with near-miss flights 7 Nov 2026; calendar and digital clock, 12-hour times, one day column (weekdays, or dates for weekday questions), 3 of 8 countries × 4 flights, weekday tracking and a play-again question 8 Nov 2026; later that day arrivals (*llegar*) on separate *Salidas* / *Llegadas* tabs (4 countries, 8 flights each), no day names on the calendar, questions of at most 12 words, no flights 7–9 p.m., missed questions first in the summary; that night a board built for each question (6 departures and 6 arrivals, countries mixed, at most 3 a tab, the answer with near misses, country and verb traps) and no scroll bar | [Design](TOWN_DESIGN_BRIEF.md#airport-flight-game--5-november-2026), [ownership](ARCHITECTURE_REVIEW_PART1.md#airport-flight-game-ownership--5-november-2026) |
| **On the Menu** (Alta Cocina restaurant game) | Twinkle (beagle plush, waiter) at the Alta Cocina host stand; two seated house-character customers at two tables; a menu book on a table by the host stand | Taste, temperature, ingredients, intensity (*un poco*, *muy*); dish names; course names | Tastes, temperatures, ingredients and 23 dishes, `restaurant.*`; taught by three dining-room posters and the menu book | Built 6 Nov 2026; **walk-around flow since 11 Nov 2026**: Twinkle sends the player to a customer, who orders 2–3 courses; the dishes are chosen and sent from a tablet, the customer reacts, Twinkle reports back; the entrance asks before leaving mid-game; 4 fully right orders; textures and extras removed; negation built but off | [Design](TOWN_DESIGN_BRIEF.md#alta-cocina-restaurant-game--6-november-2026), [ownership](ARCHITECTURE_REVIEW_PART1.md#restaurant-game-ownership--6-november-2026) |
| **Spot the Suspect** (police lineup) | Officer Rocco (crocodile plush, police) in the station lobby by the holding cell | Describing people: tall/short (a medium height no clue names), hair length and colour, bald, beard, moustache, nose size, shirt colour, negation (*no tiene barba*) | 33 new words shared by both police games (appearance, properties, look/touch/listen, objects, suspect), `police.*`; "¿Cómo es?" poster | Built 6 Nov 2026; 4 rounds of 5 bear suspects, 2 clues each; a round counts once solved; word summary at the end (both police games) | [Design](TOWN_DESIGN_BRIEF.md#police-station-enlargement-and-detective-games--6-november-2026), [ownership](ARCHITECTURE_REVIEW_PART1.md#police-detective-games-ownership--6-november-2026) |
| **Feel the Clues** (police evidence) | Officer Mimi (cat plush, police) behind the evidence counter | **Redesigned 8 Nov 2026:** object properties felt with three tools, one word deciding each round: *duro/blando* (Apretar), *áspero/liso* (Tocar), *pesado/ligero* (Levantar); the 10 object nouns in every answer line, with agreement (*la piedra es dura*) | 6 property words, 3 tool verbs (*apretar* new), 10 objects; `police.find`, `report`, `e_*`/`a_*` (+ `_f`); "Apretar · Tocar · Levantar" poster | Built 6 Nov 2026, redesigned 8 Nov 2026: 4 rounds alternating *find* (4 objects, "¿Qué objeto es blando?") and *report* (1 object, "¿Es la piedra dura o blanda?", two answer buttons); a tool examines every object and leaves a result icon; **tracked** (one word per round); summary marks first-try rounds. Sound waits for real audio. Second pass (8 Nov): objects stone, coconut, frying pan, dumbbell, key, pencil, ball, pillow, sponge, towel in the product art style; navy pin badges; buttons translated with the translate bubble | Same; [redesign](TOWN_DESIGN_BRIEF.md#police-evidence-game-redesign--8-november-2026) |
| **Stack & Pack** (warehouse worker) | Ramón (lion plush, the boss), outside the warehouse | Movement and placing verbs, positions (on, under, behind, left of, top shelf…), colours and sizes, through physical tasks | 22 verbs (new Actions category), 16 position expressions, A1–A2 nouns, colours and sizes; taught by three reception posters | Built 5 Nov 2026 (Phases 1–5): copy, fade, task card, leave question; physics goods, carrying, trolleys, generated tasks per session (10 since 8 Nov 2026, planned and checked before the game, with hints, a play-again question at the end; [task plan](WAREHOUSE.md#task-plan-8-nov-2026)) with checks and wrong-attempt help; refined after play-testing (wall bays for directions, bigger boxes, colour / what / comparison questions). Phase 6 full suite run 5 Nov 2026 (warehouse checks pass; suite not clean, see FINAL_VERIFICATION) | [Warehouse guide](WAREHOUSE.md), [design](TOWN_DESIGN_BRIEF.md#warehouse-and-warehouse-worker-minigame--5-november-2026) |
| **Desk Dash** (grammar classroom) | Lana (sheep plush teacher), by the board in the school's general classroom | Grammar by choosing: Spanish ser/estar, Chinese measure words (shared Mandarin / Hong Kong forms), English subject–verb agreement and prepositions; the player sits at the desk showing the answer | 16 fill-in-the-blank questions per language (`data/grammar_class/<code>.json`), `grammar.*` phrases | Built 7 Nov 2026: 10 questions per class, 10 s each, on-screen Confirm, 2 s feedback with the right desk green, Replay / Finish, doorway leave question; points only. 8 Nov 2026: walked back to the start after every answer; large top-centre countdown with a hint | [Design](TOWN_DESIGN_BRIEF.md#grammar-classroom-remodel--6-november-2026), [guide](GRAMMAR_CLASS.md) |
| **Mystery Doors** (Madame Luna) | Madame Luna (cat plush fortune-teller) by the crystal ball in the Mystery House's mystery room | Colours and shapes (circle, square, triangle, star) in a clue sentence | 7 colours (`warehouse.color_f_*`), 4 shape words, `mystery.*` phrases | Built 9 Nov 2026: 6 doors per game (shape clues, colour clues, both), E or a click on a door; the game starts in place at the mystery room's doors (10 Nov 2026: no fade), and the first right door swaps the player invisibly into the hidden hall; the right door leads on through an endless hall of identical rooms, shutting behind the player; a wrong door: a 0.95 s change, a hopping toad for 3 s, a 0.95 s change back (10 Nov 2026) and the clue again, highlighted; first-try doors count; after the last door a treasure chest (E or click): the diamond flies back to Luna, an open door leads out of a mystery-room door, Luna thanks the player; doorway leave question | [Design](TOWN_DESIGN_BRIEF.md#mystery-house-and-mystery-doors--9-november-2026) |
| **Mahjong Club** (Hong Kong mahjong) | Mei (cat plush, the host) at the table in front of the home; Bao (bear), Awoo (samoyed) and Kiko (golden) play | Game play in the language being learned: calls, wind names, hand names, turn instructions (no tested word) | `mahjong.*` phrases (hand names, winds, calls) | Built 9 Nov 2026: player vs 3 NPCs, one hand per game, 136 tiles (no flowers), mode chosen when sitting down (at least 3 fan or any fan), 3D table with the hand as large tiles at the bottom, corner digits on tiles; not tracked | [Guide](MAHJONG.md) |
| **Radar Patrol** (control-tower arcade) | No NPC: either radar in the airport control tower (the scope in the hidden radar room, the wall display in the control room) | None (pastime: tap UFOs, protect planes) | None; English arcade text in every language | Built 9 Nov 2026: endless, a click or E on a radar opens the arcade screen; best score saved; not tracked | [Guide](RADAR_PATROL.md) |
| **Wire It Up!** (electrical box repair) | No NPC: any electrical box (first: outside the home's garage side wall, facing the entry path) | None (pastime: connect the wires by colour) | Interface text only (native language); the box is the word *electrical box* | Built 9 Nov 2026: E nearby or a click opens it, camera close-up, wires played in 3D; repaired until reload; not tracked | [Guide](ELECTRICAL_BOX.md) |
| **Library Helper** (library; named 17 Nov 2026, was Shelf Mission) | Rosa (samoyed plush librarian) by the NEW BOOKS display, return cart beside her | Book sorting (user design, 13 Nov 2026; reviewed 17 Nov 2026): 3–6 random books on the return cart; take one (E, the hand), put it in any gap of the bookcase for its category (right: slide, hop, sparks; wrong: a wobble, then back in the hand); the game ends by itself when every book is home, with one book recalled; the sorted books rest about 5 minutes, then are borrowed and a new cart fills; talking mid-game says what is left (OK / I'll help later) | `library.*` phrases; the 18 display titles and shelf signs (`data/sign_translations.json`); `BOOK_WORDS` and the category words in `scripts/buildings/library.gd`; gaps as drop targets | Built 13 Nov 2026, reworked 17 Nov 2026 (`scripts/learning/library_session.gd`, shared host); check `docs/evidence/library-refresh-20261117/verify.gd` (`library_sorting`); tracked: a book's first placement tests its topic and category words | [Design](TOWN_DESIGN_BRIEF.md#library-return-cart-and-book-sorting-game--13-november-2026) |
| **Next, Please!** (bank teller) | The bear banker at the bank's reception hosts; the player works behind teller window 2, plush customers (house characters) walk up from the queue ropes | Spanish amounts 100–500 in words (multiples of 5) against a balance in digits; counting out $5, $10, $50 and $100 bills; declining a short account; giving change without $100 bills (user, 18 Nov 2026) | Generated amounts (`money_words()`), `teller.*` phrases (8 customer personas in `data/bank_teller.json`), `money.*` | Built 18 Nov 2026 (`scripts/learning/teller_session.gd`; shared host and zone, `money_panel.gd` with `only`, a balance screen on window 2's monitor); 5 customers per session, first-try counts; amounts get harder within the session; check `docs/evidence/bank-teller-20261118/verify.gd` (`bank_teller`); not tracked | [Design](TOWN_DESIGN_BRIEF.md#bank-teller-game--18-november-2026) |

## Shared systems

Reuse these for any new minigame instead of building parallel ones.

| System | Owner | Used by |
| --- | --- | --- |
| **NPC host: the NPC, "!", talking, greeting, owning the dialogue box, walking away, leave question, abandoning practice** ([how](#building-a-minigame)) | `scripts/learning/minigame_host.gd` | all (shop, cashier and warehouse since 9 Nov 2026) |
| **In-world zone: fade, placing the player, doorway watch, door guard** ([how](#building-a-minigame)) | `scripts/learning/minigame_zone.gd` | grammar, mahjong (fade), warehouse (fade, station; since 9 Nov 2026), Mystery Doors (arch guard), restaurant (entrance guard; since 11 Nov 2026), bank teller (fade behind the counter; 18 Nov 2026) |
| **Seated at a table: the host gets up and steps aside, the player sits in its chair, fade into the game's own camera with the player's model and the HUD overlays hidden; leaving reverses it** — `MinigameTable.new()`, `setup(main, player, zone, chair, host_npc, spec)`, `await begin(open_screen)`, `await end(close_screen)`, `release()` | `scripts/learning/minigame_table.gd` (9 Nov 2026); uses `seating.sit_at(node, stand_back)` and `hud.hide_for_game()` (group `GAME_HIDDEN_GROUP`: put any new HUD part that would cover a game view in it) | mahjong |
| **HUD during any minigame** (user, 12 Nov 2026): while any game's `activity_running()` is true, the full map and minimap, the journal / map / games / help corner buttons, the day clock and the other `GAME_HIDDEN_GROUP` parts are off, and M, J and F1 do nothing; open map, journal, help or picker windows close. Only the Settings gear and the peek badge stay. Nothing to do per game: register on the activity board | `main.gd` `sync_minigame_hud()` (activity board `blocker("")`), `vocabulary_hud.gd` `in_minigame` and `hide_for_game(hide, reason)`; check `docs/evidence/electrical-box-20261109/verify.gd` | all registered games |
| **A word popping up in the world** (grows in, stays, fades; same size on screen at any distance): `PopWord3D.new()`, add it, place it, `pop(text, outline_colour, seconds, camera)` | `scripts/ui/pop_word_3d.gd` (9 Nov 2026) | mahjong (call words) |
| **Lively NPC plushes** (a blink every 4-10 s each; one small hop, body shake, bow or lean every 10-20 s across the group; always back to rest; `blink_gap`, `gestures`, `gesture_gap` are settings): `PlushLife.new()`, add it, `setup([plushes], rng)`; one move on demand: `PlushLife.play(self, figure, kind)`. Moves turn the whole figure, never its `Head` node ([why](COMPONENTS.md#plush-characters)) | `scripts/characters/plush_life.gd` (9 Nov 2026; the one owner of plush eyes and gestures since 13 Nov 2026) | mahjong players, lineup suspects; every other plush NPC blinks through `main.plush_life` |
| **Levels and stars** ([progression](#progression), 18 Nov 2026): a level's settings from `data/activities.json` `"levels"`, 1–3 stars per finished session, unlocks, saved per profile; the picker's level pills and stepper, the greeting's level badge, the end-of-session star card | `scripts/learning/game_progress.gd`, `Board.add_miss()`; UI: `game_launcher.gd`, `minigame_host.gd` `show_level()`, `shop_order_panel.gd` `show_level()`, `scripts/ui/star_card.gd`, `BonStyle.stars()` | Pay Up!, Grocery Run (the rest designed, not built) |
| Offer chance, progress target, one activity at a time; `hold` keeps every game quiet while the welcome tutorial runs ([guide](ARCHITECTURE_REVIEW_PART1.md#welcome-tutorial)) | `scripts/learning/activity_board.gd`, `data/activities.json` (the host registers and rolls) | all |
| Started / ended signals (12 Nov 2026): `started(id)`, `ended(id, summary)` with `rounds`, `target`, `completed`; `running_id` | `activity_board.gd` `watch()`, called once a frame by Main; a game needs nothing extra (it only has to report `activity_running()`) | all |
| Hop, face camera (avoids walls, hides the player in the shot); the "!" since 12 Nov 2026 is drawn by the shared interaction icons from the NPC interactable's `calling` | `scripts/learning/npc_presence.gd` (made by the host), `scripts/ui/interact_badge.gd` | all |
| Dialogue box: speaker, foreign/native line, choices, translate bubble, ✕; a line without choices closes itself once the player walks 3 m away while no minigame runs (user, 8 Nov 2026: the goodbye needs no tap) | `scripts/ui/shop_order_panel.gd` (`WALK_OFF`, `walker`) | all |
| No word cards while any minigame runs (user, 8 Nov 2026): a click talks to an NPC or does the game's action, never opens a card. An interactable (the mystery doors, the chest) works on a click like E, game or not. Nor while the shared dialogue box shows any line (14 Nov 2026, user), unless a `word_filter` names the object the line asks for | `interaction_controller.gd` `minigame_running()` (activity board), `dialogue_open` (set by Main) | all |
| Progress bar | `scripts/ui/progress_bar.gd` | cashier, family, warehouse (task card), flight, police (detective card), grammar (class card) |
| Esc and ✕ order | `scripts/ui/popup_stack.gd` via `Main.make_popups()` and `scripts/core/minigame_wiring.gd` | all |
| Words, phrases, grammar, display mode | Lexicon (`scripts/language/`), `data/words.json`, `data/phrases.json`, `scripts/core/game_settings.gd` | all |
| **Anything used with E, a click or a tap** (NPCs, game objects, stations, a station's discovery dot; the "E" badge; input claims while a game holds E) — [interaction system](ARCHITECTURE_REVIEW_PART1.md#interaction-system), 12 Nov 2026 | `scripts/core/interactable.gd`, `interaction_controller.gd` | all |
| Player lock for full-screen panels; since 14 Nov 2026 (user) also while the dialogue box shows choices (`Main.talk_locked()`, re-checked every frame), so walking away no longer closes a question: its ✕ or a choice does | `Main.sync_player_controls()` | cashier, family, flight, police (card open: fixed camera); every question in the shared box |
| Shared "today" (random 2026–2027 date and time per launch) | `scripts/learning/game_clock.gd` | family, flight |
| Teleport to a built copy and back; map stand-in (`map_position` meta) | `scripts/learning/warehouse_session.gd` | warehouse |
| Leave question | the dialogue panel's quit card, through the host (`ask_leave()`, `leave_answered`) | all with a leave question, through the host (shop cart, cashier money panel and warehouse since 9 Nov 2026); Esc or ✕ on the question means "stay" |
| Physics goods (pushed by weight), carrying with E or a click, lane-bound trolleys (rolled by walking into them, faster when grabbed), hinged doors, readouts, green hint marker | `scripts/learning/warehouse_goods.gd` | warehouse |
| Practice tracking: one outcome (positive, negative, translated) per tested word per question, per learned language ([interface](ARCHITECTURE_REVIEW_PART1.md#practice-tracker)) | `scripts/learning/practice_log.gd` (`user://practice_log.json`) | shop, family (relation questions), restaurant, warehouse, flight (destination country), grammar (Chinese measure-word nouns) |
| Try again / tell me what went wrong | cashier (`cashier_session.gd`), warehouse (`warehouse_session.gd` `_wrong()`) | cashier, warehouse, flight (`flight_questions.gd` `explain()`) |

Not available yet: coins or rewards (none exist; stars and levels since 18 Nov 2026, [progression](#progression)). Physics goods exist only in the warehouse
copy (`warehouse_goods.gd`).

## Building a minigame

**Start here** when adding a minigame or changing how one starts, talks or ends (8 Nov 2026).
A minigame session is one script in `scripts/learning/<game>_session.gd` that keeps only its
own rules. Everything around the game comes from two shared helpers. **Do not copy talking,
"!", offer, leave or fade code into a session:** since 9 Nov 2026 every game uses the helpers
(the shop, cashier and warehouse were moved onto them; before that the cashier had no "!").

**1. The NPC host** (`minigame_host.gd`, every game with an NPC). Add it in `setup()`:

```gdscript
const Host := preload("res://scripts/learning/minigame_host.gd")
var host

func setup(lexicon, dialogue_panel, game_panel, interaction, player, world) -> void:
	var npc := world.find_child("MyNpc", true, false) as Node3D
	if npc == null:   # its building is left out by dev_focus.txt: stay inert
		return
	host = Host.new()
	add_child(host)
	host.setup(self, {"activity": "mygame_npc", "group": "mygame", "speaker": "mygame.npc_name"},
			lexicon, dialogue_panel, interaction, player, npc)
	host.play_chosen.connect(open_game)            # "Yes" on the greeting
	host.leave_answered.connect(_on_leave_answered)

func activity_running() -> bool: return _playing             # the activity board asks
func busy() -> bool: return (host != null and host.owns_dialogue()) or _playing
func _process(delta: float) -> void:
	if host != null: host.tick(delta)                # "!", offer roll, walking away
```

It then does, with no more code:
- the NPC's TALK [interactable](ARCHITECTURE_REVIEW_PART1.md#interaction-system) (E, a click
  or a tap talks; the "E" badge over the head), its name (`refresh_name()` after a language
  change), the gold "!" (the interactable's `calling`, drawn by the shared icons) and the face
  camera;
- the activity board (register, the offer roll when the player comes near, "finish the
  other task first");
- E on the NPC: `<group>.not_now`, or `<group>.greeting` with Yes (`<group>.play`) and
  Not now (`common.reply_no`, then `<group>.goodbye`);
- the box closing when the player walks away from a question.

What a session calls on it:

| Call | When |
| --- | --- |
| `host.say(id, choices, auto_close, values)` | any NPC line in the shared box (`choices` from `host.choice("replay", "mygame.replay", "retry")` arrive as `choice_made(id)`) |
| `host.close_dialogue()`, `host.zoom(on)` | closing this game's line; the face close-up by hand |
| `host.ask_leave()` → `leave_answered(leave)` | ✕ / Exit / Esc during a game (`<group>.leave_confirm`, `.leave_yes`, `.leave_no`; `ask_leave("<phrase id>")` asks a game's own question, e.g. `restaurant.leave_door`); `cancel_leave()` when the game ends otherwise. A room the player must not walk out of mid-game: an invisible player-only wall in the doorway plus a question zone in front of it (Mystery House arch `_arch_tick`, Alta Cocina entrance `_door_tick` in `restaurant_session.gd`) |
| `host.abandon_practice()` | leaving, finishing or a language change (the [practice tracker](ARCHITECTURE_REVIEW_PART1.md#practice-tracker)) |
| `host.offered` | read or set (the sessions keep an `offered` pass-through for checks) |

Hooks a session may define: `_host_talk(talker) -> bool` (say something else when the
player talks: a class in progress, a second talker; `host.gate()` and `host.offer()` help),
`_host_speaker()` (who speaks when not the NPC), `_host_walked_away(distance) -> bool`,
`_host_near(distance) -> bool` (when the player counts as near: the shop and cashier use the
store's zone), `_host_calling() -> bool` (the "!" whatever else holds: the grocery clerk waiting
after Done) and `_host_launch()` (how the [minigame picker](#minigame-picker) starts the game when
not as Yes on the greeting: mahjong asks the mode). `host.show_line(id, line, ...)` says a
line the session put together (joined phrases, a generated question).
Extra characters to talk to: `host.add_talker(node)` (each gets its own TALK interactable;
`remove_talker()` disables it). Text ids default to `<group>.<name>`;
override any of them in the spec (`"play": "grammar.join"`, `"greeting": ...`), as well as
`call_distance`, `walk_away` and `message_seconds`. Two NPCs may share the box: the host owns
it by the line on screen (the police officers). Examples: `family_session.gd` (simplest),
`flight_session.gd` (leave question), `restaurant_session.gd` (several talkers, customers with their own "!", a usable object),
`grammar_session.gd` (talking during the game).

**2. The in-world zone** (`minigame_zone.gd`, only for games played in the world rather
than in a panel). `zone.setup(player, main, "MyGameFade")`, then
`await zone.fade_through(func(): zone.place_player(building, START, START_LOOK))`,
`zone.make_doorway(building, position, size, title, on_enter)` for a "did they walk out?"
trigger, and `zone.fading` to ignore input during a fade. Example: `grammar_session.gd`.
**Door guard** (11 Nov 2026, user): `zone.make_door_guard(room, wall_at, wall_size, ask_at,
ask_size, title, {blocking, can_ask, ask, cancel, asking, layer})` keeps the player in the room
mid-game: an invisible wall in the doorway while `blocking()` is true, and a question zone just
inside it that calls `ask()` (usually `host.ask_leave("<group>.leave_...")`); stepping back out of
the zone calls `cancel()`. Clear `guard.asked` in `leave_answered`. Examples: the Mystery House
arch (`mystery_session.gd`, pauses the game while asked) and the Alta Cocina entrance
(`restaurant_session.gd`, `layer` FIGURE_LAYER so the pointer passes). With only `blocking`,
`ask` and `layer` it is a "not yet" door: the welcome tutorial's supermarket door stands while the
player is inside and has not paid, and its zone shows a toast (`tutorial_shop.gd`, 14 Nov 2026).

**3. The rest of the checklist** (each links to its rules):
- Can the player walk out of the game's room mid-game? For a game played by walking around a
  room with a clear exit, use the door guard (above) and a `<group>.leave_*` question; games at
  one spot or in one panel ask through ✕ / Esc instead (user, 11 Nov 2026: consider it for every
  game, not a rule).
- `data/activities.json`: offer chance and progress target ([activity board](ARCHITECTURE_REVIEW_PART1.md#shared-dialogue-popups-and-settings--4-november-2026));
  a `progress_bar.gd` in the game's panel or card.
- `data/phrases.json` group `<group>` in every language (es, en, zh), plus `games.<activity>`
  for the vocabulary book. No text in code.
- `scripts/core/minigame_wiring.gd` `build()`: create the panel and session; add the panel to
  `PANELS` (Esc), with a third value `true` if it locks the player.
- Practice tracking for one clear tested word per question: `PracticeLog` begin / first
  answer / complete ([practice tracker](ARCHITECTURE_REVIEW_PART1.md#practice-tracker)), and
  its source in `tools/vocabulary_report.gd` `_game_words()`. The full suite then refreshes
  `docs/guides/vocabulary-report/` ([report](ARCHITECTURE_REVIEW_PART1.md#vocabulary-usage-report));
  commit it when the `vocabulary_report` details say "updated".
- UI: reuse the shared dialogue box and quit card (`shop_order_panel.gd`); large buttons that
  scale with the window (`min(height/800, width/1100)`).
- A check under `docs/evidence/<game>-<date>/verify.gd`, registered in `tools/run_checks.py`, and a
  row in the table above.
- Rounds: read `Board.shared().target(id)` (progress bar) or `rounds(id)` (at least 1) rather
  than a constant, so the [minigame picker](#minigame-picker) can change them.
- Levels ([progression](#progression)): a `"levels"` list in `data/activities.json`, read once per
  session with `GameProgress.shared().params(id)`, and `Board.shared().add_miss(id)` for a round
  that went wrong. The design (what each level changes) goes on the game's learning card in
  [game/minigames.md](../game/minigames.md).

## Minigame picker

The ▶ button in the HUD's top right (under the peek badge since 14 Nov 2026; it was in the bottom-right cluster), or **F9**, opens a window with every game in
`data/activities.json`. Built 9 Nov 2026 as a debug-only test launcher; since 10 Nov 2026
(user) it is a **player feature** in every build, the rounds stepper is part of it, and games
started from it **record practice** like any other (the practice log is no longer paused).

- Two tabs by `kind`: **Learning games** and **Just for fun** (pastimes: no tested word).
- A tile per game: its icon (`ICONS` in `game_launcher.gd`, drawn by `ui_icons.gd`), its short
  name (`games.<id>`, [names](#minigame-index)) and who and where (`games_host.<id>`). A tap
  selects it; tiles are at least 52 px tall, and the window fits and centres on the shown tab.
- The detail bar under the tiles: the selected game's name, host line, what it practises
  (`games_learn.<id>`), the rounds stepper (1–30, starting at the data's number; "No rounds"
  for Radar Patrol, the electrical box, the library cart and, since 15 Nov 2026, mahjong:
  `ENDLESS`, which also sets no rounds on Play), for a game with levels a **Level** stepper over the
  unlocked levels (18 Nov 2026; it sets the current level, [progression](#progression)) and a large
  **Play**. A tile of a game with levels shows its level ("Lv 2") and best stars at it.

Play closes the window, stands a seated player up, puts them about 2 m in front of the game's
NPC and starts the game through `minigame_host.gd` `launch()` (no offer roll or greeting).
While that game runs its rounds are the chosen number (`activity_board.gd` `set_rounds()`),
undone once the game neither talks nor plays.

| Game | What a round is |
| --- | --- |
| Customer order | one order; with more than 1 the clerk asks for another after each (`shop.another_order`) |
| Cashier, family, flight, restaurant, police, warehouse, Mystery Doors | the progress bar's target |
| Grammar | questions in the class |
| Mahjong | not used since 15 Nov 2026 (user: keep playing): in `ENDLESS`, so no stepper and always "Play again" (before: hands, "Next hand" until the last, then only Leave) |
| Radar Patrol | not used: one endless game; Play opens the screen where the player stands (no NPC: the launcher calls the session's `launch()`) |
| Electrical box repair | not used: one puzzle; Play opens the box nearest the player (the camera flies there) |

The window scales like `money_panel.gd`, but its tiles, tabs, Play, −, + and close buttons
never go under 52 px (touch UI rule, 9 Nov 2026), and it fits a 1280 × 720 window with no
scroll bar.

A game whose building is left out by `dev_focus.txt` shows "Building not loaded"; Play is off
while any game runs or the player is in a vehicle. Owner: `scripts/ui/game_launcher.gd`
(built in `minigame_wiring.gd`, `PANELS`, locking the player; F9 in `main.gd`); text in the
`launcher`, `games`, `games_host` and `games_learn` groups of `data/phrases.json` (native
language). Check:
`docs/evidence/minigame-launcher-20261109/verify.gd` (`minigame_launcher` in `tools/run_checks.py`).

**Go there** (18 Nov 2026, user): next to Play, it closes the window and starts the
[guide arrow](#town-map-and-guide-arrow) to the selected game's NPC (or box) instead of starting
the game; off while a game runs and hidden for a building left out by `dev_focus.txt`.

## Town map and guide arrow

Wayfinding (user, 18 Nov 2026). The live minimap and full map were switched off on 14 Nov 2026
because they redrew the town from its meshes (8.4 → 64 ms a frame while turning,
[hidden features](../../README.md#hidden-features)); the user chose a baked map plus a guide arrow.

- **Baked picture:** `tools/bake_town_map.gd` (needs a window) renders the whole town once from
  straight above (orthographic, noon, no fog, sun disc and clouds hidden) into
  `assets/maps/town_map.png` (1400 × 1138, imported lossy) and writes `data/town_map.json`:
  the picture's frame in town coordinates (north up, +X west on the left), each building's
  entrance (`at`, `door`, from `Main.ENTRANCES`) and each minigame's NPC (or box) spot. **Run it
  again after a building, an entrance or a minigame NPC moves**, then reimport
  (`godot --headless --path . --import`) so the game loads the new picture.
- **Map** (`scripts/ui/town_map_panel.gd`, in `hud.map_overlay`; M, the map button in the
  second top-right row left of ▶, its ✕, Esc or moving close it): the picture, a name pill per
  building (placed once on open, no overlaps), a "you are here" dot with the view direction
  (moved 5 times a second, only while open). A tap picks the place whose pill or entrance is
  nearest; the side column lists its games (tap: guide to that game) and a green **Go there**;
  **Stop guiding** while a guide runs. The picture is loaded on open and let go on close.
  Hidden during minigames and the welcome tutorial (`tutorial_hidden.map`).
- **Guide arrow** (`scripts/ui/guide_arrow.gd`, under the place line in the top left, below every
  window): a green dial whose arrow points to the target relative to the camera, the name, the
  metres left and a ✕. It follows a live NPC node when its building is loaded, otherwise the baked
  spot; clears itself within 7 m (toast `map.arrived`) or when the target game starts; hidden,
  not cleared, while a minigame hides the HUD. Not processing while no target is set.
- Text: `map.*` and `help.map` in `data/phrases.json`; place names `places.*`.
- Check and views: `docs/evidence/wayfinding-20261118/verify.gd` (graphics; not in
  `run_checks.py`, it overwrites its PNGs) and its [README](../evidence/wayfinding-20261118/README.md).

## Progression

Levels and stars for the minigames (user approval, 18 Nov 2026). The player-facing design, the
star rule and each game's level ladder are owned by the [game guide](../game/minigames.md#how-games-get-harder);
this section is the code. Built for Grocery Run (and Pay Up! until it was retired into Grocery
Run's checkout on 21 Nov 2026); the other learning games are designed (their learning cards) but
not wired yet.

**Data.** `data/activities.json`, per game:
- `"levels"`: a list of settings dictionaries, level 1 first. The keys belong to the game:
  Grocery Run's are its `data/shops.json` order rules, merged over the store's (`unique_items`,
  `quantity_each`, `order_words`, where `[]` means every product sold in the store, and since
  21 Nov 2026 `order_tiers` n, the products of the store's first n price tiers; `retries` is gone).
  Pay Up! read `max_cents` and `step` until it was retired. An empty `{}`
  is the game as it is in the data.
- `"stars_at"` (optional, default `[1.0, 0.6]`): the share of rounds right first time for ★★★ and ★★.
  Grocery Run uses `[1.0, 0.5]` so one retry is ★★.

A game without `"levels"` has no progression and nothing changes for it.

**API** (`scripts/learning/game_progress.gd`, `GameProgress.shared()`):

| Call | Use |
| --- | --- |
| `params(id)` | the current level's settings, read when a session starts (`{}` without levels) |
| `level(id)`, `unlocked(id)`, `count(id)`, `has_levels(id)`, `best(id, level)` | for UI |
| `set_level(id, n)` | the picker's stepper (capped at `unlocked`) |
| `recorded(id, result)` signal | a scored session: `stars`, `level`, `best`, `level_up`, `new_level`, `count` |
| `record(id, needed, misses, custom)` | scores a session by hand (checks); the game never calls it |

A game itself only calls `params()` and, once per round that went wrong (or per retry),
`Board.shared().add_miss(id)`. Scoring is automatic: the activity board's `ended(id, summary)`
now carries `misses`, `needed` (the rounds the session needed when `begin()` ran, at least 1) and
`custom` (the picker changed the rounds). A session with at least `needed` rounds done scores
`needed / (needed + misses)` against `stars_at`; ★★★ at the highest unlocked level unlocks the next and
makes it current, except for `custom` sessions. Unfinished sessions record nothing.

**Shown in:** the picker (tile pill and stars, Level stepper), the greeting (`minigame_host.gd`
`offer()` calls `show_level()`; a game with no greeting calls `host.show_level()` on its first
line, as the cashier does), and the star card at the top centre after each scored session
(`scripts/ui/star_card.gd`, built by `minigame_wiring.gd`, 4.5 s or a tap). Text: the `progress`
group and `launcher.level` in `data/phrases.json` (native language). Stars are `BonStyle.stars()`
(`star_on` / `star_off` SVGs).

**Save:** `game_progress.json` per profile (`save_store.gd` `PROFILE_FILES`; reset with the other
singletons on a profile switch), keyed by learned language then activity id:
`{"es": {"shop_supermarket": {"level", "unlocked", "best": {"1": 3}, "plays"}}}` (an old
`cashier_supermarket` record from Pay Up! stays in the file, unused). Saves without
the file start at level 1; nothing to migrate.

**Check:** `docs/evidence/minigame-progression-20261118/verify.gd` (`minigame_progression`, full suite).
With graphics it saves `picker.png`, `greeting.png` and `star-card.png` there.

**Rolling it out to another game:** add its `"levels"` from its learning card, read `params()` in
its session's start, call `add_miss()` where a round goes wrong (the restaurant, police and
warehouse games count a round "when done", so they need it most), add checks to the progression
check, and mark the card's Progression row as built.
