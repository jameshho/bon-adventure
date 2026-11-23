# NPCs: the registry, idle chatter and how to add one

Built 23 November 2026 (user: one registry for all NPCs; idle chatter in the world language with
the EN toggle; a farmer in the barn; natural standing spots). Evidence and check:
`docs/evidence/npc-registry-20261123/` (runner id `npc_registry`).

Every character in the town other than the player and the animals has **one entry** in
[`data/npcs.json`](../../data/npcs.json), keyed by a permanent `id`. That file replaced
`data/house_characters.json` (folded in; the cast keeps its ids and order). Read it through
`scripts/characters/npc_registry.gd`; never parse it elsewhere.

## Who owns what

| Need | Use | File |
| --- | --- | --- |
| Look up an NPC, the cast, a node's entry | `NpcRegistry.spec(id)`, `.all()`, `.cast()`, `.of_node(node)` | `scripts/characters/npc_registry.gd` |
| Put the baked NPCs at their registry spots | `NpcRegistry.place(town, parts)` (Main, at load and for each unit added later) | same |
| Make the registry's own NPCs (the barn farmer) | `NpcRegistry.spawn(town, parts)` (Main; never while baking) | same |
| Make a standing NPC from its entry at run time | `NpcRegistry.make(town, entry, parent, title)` (the bank manager) | same |
| The Home seats, profile avatars, tutorial stand-ins | `HouseCharacters.characters()`, `.ids()`, `.spec_of(id)`, `.scene_of(id)` | `scripts/characters/house_characters.gd` |
| Idle lines and brush-offs | `npc_chatter.gd` (`main.npc_chatter`, `NpcChatter.current`) | `scripts/characters/npc_chatter.gd` |
| An NPC that runs a game | the shared host (`minigame_host.gd`); its `gate()` asks the chatter when the game is not on offer | [Minigames](MINIGAMES.md#building-a-minigame) |
| Eyes, gestures, sitting, outfits, solidity | `plush_life.gd`, `house_characters.gd` (`seated()`, `worker()`, `solidify_figures()`), `plush_costume.gd` | [Components](COMPONENTS.md) |

## Coordinates and placement

`at` and `back` are **town coordinates**: the local frame of Main's `Apartment` node (+X west,
+Z north; the Apartment's scale 1.3 applies, so 1 unit is 1.3 m in the world). `facing` is the
direction the NPC looks in the same frame: an `[x, z]` vector or an axis name (`+x`, `-x`, `+z`,
`-z`). Convert with `town.to_global()` / `town.to_local()`; never mix in world metres.

| `placement` | Made by | `at` means |
| --- | --- | --- |
| `house` | `house_characters.gd` build(): seated or lying in the Home (`pose`, optional `back` point on the backrest); naps in a free bed now and then | the seat or mattress surface |
| `scene` | baked into its unit scene at `node` (a path under the town root). `npc_registry.gd place()` moves it to `at` / `facing` at load, so **the registry wins over the baked transform**; a bake of the unit saves the registry spot. A seated node keeps its pose | the node's origin (the floor between its feet) |
| `registry` | `npc_registry.gd spawn()` at load, under the unit part that `node`'s parent path names; never baked | the floor it stands on |
| `runtime` | the `owner` script (a minigame), which reads scene, costume, name and spot from the entry | the owner's spot, or `seat` describes it |
| `cast` | not placed: a profile avatar, tutorial stand-in and random customer | — |

Other fields: `name` (display) or `name_phrase` (a `data/phrases.json` id, shown in the world
language), `species`, `scene` (a `scenes/characters/*_plush.tscn`), `costume` (a
`data/plush_costumes.json` outfit; for the cast it is its own look as an avatar, and
`work_costume` what it wears where it is placed), `gender` (`m` / `f`: its role word, "el
vendedor" / "la vendedora"), `unit` (`data/buildings.json`), `pose` (`stand`, `sit`, `lie`),
`role` (`host` with its `activity` from `data/activities.json`, `ambient`, `customer`), `word`
(its people word in `data/words.json`), `chatter` (its idle-line group), `cast`, `in_house`,
`picker`, `home_seat`, `note`. The file's `about` is the full schema.

Placed NPCs carry meta `npc_id`; the cast at home also keeps `character_id` (saves and profiles
key on it). Node names, `word_key`, `character_name`, `assigned_zone` and every other existing
meta are unchanged.

## Idle chatter

User decisions, 23 November 2026:

- Talking to an NPC (E, a click or a tap; never hover-only) **without an activity, or whose
  activity is not on offer**, shows a random line of its `chatter` group in the shared dialogue
  box: in the language being learned, the HUD's EN (or L) shows the native line. Never the same
  line twice in a row.
- After **3** lines with less than **40 s** between talks, the NPC answers with its brush-off
  set instead ("If there's nothing I can help with, feel free to look around", "Sorry, I'm a bit
  busy right now", ...; friends: "Let's talk later, OK?"); 40 s without talking resets it
  (`npc_chatter.gd` `CHATTY`, `RESET_SECONDS`).
- Lines are A1, role-appropriate, in `data/phrases.json` group `chatter`: `chatter.<group>_<n>`
  (n = 1, 2, ... while they exist) and `chatter.brush_staff_<n>` / `chatter.brush_friend_<n>`;
  `data/npcs.json` `chatter_groups` names each group's brush-off set. Groups: friend, shop,
  cashier, waiter, kitchen, police, bank, office, warehouse, driver, hospital, school, library,
  airport, mystery, farm.
- An NPC without an activity keeps its role word: it stays in its area's word list
  (meta `talk_keeps_word`, `area_vocabulary.gd`), the box names it by that word ("El vendedor" /
  "The salesperson") and talking to an unnamed NPC counts the word as studied, as clicking it
  did. Hosts are unchanged (an interactable is not a word).
- No chatter while any minigame runs, while the box asks a question, or while a house character
  naps (meta `napping`). The player is never locked by a chatter line.

## How to add an NPC

1. Pick a permanent `id` (lowercase, unique, never reused) and add one entry to
   `data/npcs.json` `npcs`: `scene`, `costume` (add an outfit to `data/plush_costumes.json` from
   existing pieces if needed, plus its `outfits.<id>` phrase for the fitting room), `gender`,
   `unit`, `pose`, `at` and `facing` in town coordinates, `role`, `word` if it teaches a people
   word, and `chatter`.
2. Choose how it is made:
   - **A standing NPC with no game** (the farmer): `"placement": "registry"`, `"node":
     "<unit part>/<NodeName>"`. Nothing else: Main makes it at load.
   - **A seated NPC in the Home**: `"placement": "house"` with `pose` and `back`; add
     `"cast": true` only for a new profile avatar.
   - **An NPC that is part of a building's look** (behind a counter, at a desk): build it in the
     unit's step with `house_characters.gd worker()` / `seated()`, bake the unit, then add the
     entry with `"placement": "scene"` and its `node` path.
   - **A minigame host or a game's own NPC**: `"placement": "scene"` or `"runtime"` with
     `owner`; the session reads its entry (`NpcRegistry.spec(id)`, `make()`) and the shared host
     does the talking ([Building a minigame](MINIGAMES.md#building-a-minigame)).
3. Give it a `chatter` group, or add a new group: 3+ lines `chatter.<group>_<n>` in every
   language (and a reading for every new Chinese character in `data/pinyin_zh.json`) and the
   group's brush-off set in `chatter_groups`.
4. Find a natural spot: behind or beside its counter, desk or work, facing where the player comes
   from; not in a corner, not facing a wall, not inside a prop, not in a doorway or walking
   route. Render it (`docs/evidence/npc-registry-20261123/verify.gd` with graphics shows the
   moved NPCs; copy its `_renders()` for yours).
5. Run `python3 tools/npc_report.py --write` (the list below) and the check
   `python3 tools/run_checks.py --only npc_registry,language`. Update the
   [game guide](../game/README.md) if players see it.

## The check

`docs/evidence/npc-registry-20261123/verify.gd` (runner id `npc_registry`, full suite): the
registry is complete (ids, scenes, costumes, units, activities, words, name phrases, chatter
groups with 3+ lines and a brush-off set in every language); every character node in the loaded
town is in the registry and every placed entry is in the town at its spot and facing, in its
costume; no standing NPC is inside a wall or fixture or faces a wall within 1 m; every NPC with a
chatter group can be talked to and keeps its word; the chatter demonstration (three lines, then
brush-offs, normal again after the reset; Lana's idle line when her class is not on offer; the
farmer).

## All NPCs

<!-- npc-report:start -->

Generated by `python3 tools/npc_report.py --write` from `data/npcs.json`; do not edit by hand.

**38 NPCs in the town** (11 with an activity, 27 without), plus 6 cast members who appear only as profile avatars, tutorial stand-ins and random customers. Not counted: the player, zoo and farm animals, and game pieces made during a minigame (lineup suspects, bank customers, restaurant guests, the warehouse game's copy of Ramón, the tutorial's cast).

| Building (unit) | NPCs |
| --- | --- |
| Home (`home`) | 7 |
| Restaurants (Alta Cocina, Pizza and Burger, Taquería) (`restaurants`) | 6 |
| Hospital (`hospital`) | 5 |
| Police station (`police`) | 3 |
| Bank (`bank`) | 2 |
| Clothing store (`clothing`) | 2 |
| Supermarket (`supermarket`) | 2 |
| Warehouse (`warehouse`) | 2 |
| Airport and control tower (`airport`) | 1 |
| Bakery / Café (`bakery`) | 1 |
| Electronics store (`electronics`) | 1 |
| Farm barn (`barn`) | 1 |
| Furniture store (`furniture`) | 1 |
| Library (`library`) | 1 |
| Mystery House (Casa de las Estrellas) (`mystery`) | 1 |
| School (`school`) | 1 |
| Sports store (`sports`) | 1 |

| id | Name | Plush | Costume | Unit | Placed | Town position (at) | Pose | Role | Chatter |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `airport_driver` | (driver) | Lion | driver | airport | `People/LionDriver` | (-72.8, -0.002, 223) | stand | ambient | driver |
| `bruno` | Captain Bruno | Bear | pilot | airport | `Airport/Terminal/Interior/PilotBruno` | (-100.1, 0.078, 239.4) | stand | host: `flight_bruno` | airport |
| `bakery_cook` | (cook) | Samoyed | chef | bakery | `People/SamoyedCook` | (144.3, 0.028, 165.7) | stand | ambient | kitchen |
| `bank_manager` | (boss) | Crocodile | businessman | bank | Made by `teller_session.gd` | (143.5, 0.03, 110.3) | stand | ambient | office |
| `bear_banker` | (banker) | Bear | businessman | bank | `RelocatedSites/Bank/Interior/BearBanker` | (127.9, 0.028, 111.9) | stand | host: `teller_bank` | bank |
| `tomas` | Tomás | Bear | farmer | barn | `Barn/Farmer` | (69.3, 0.16, 81.9) | stand | ambient | farm |
| `clothing_cashier` | (cashier) | Siamese Cat | clothing_shopkeeper | clothing | `Buildings/ClothingStore/Interior/CatCashier` | (-143.3, 0.103, 167.4) | stand | ambient | cashier |
| `clothing_shopper` | (person) | Lion |  | clothing | `Buildings/ClothingStore/Interior/LionShopper` | (-134.9, 0.103, 162.45) | stand | ambient | friend |
| `electronics_clerk` | (salesperson) | Golden Retriever | electronics_shopkeeper | electronics | `Buildings/ElectronicsStore/Interior/Electronics clerk` | (139.66, 0.083, 133.1) | stand | ambient | shop |
| `furniture_clerk` | (salesperson) | Sheep | furniture_shopkeeper | furniture | `Buildings/FurnitureStore/Interior/SheepSalesperson` | (127.7, 0.028, 235.6) | stand | ambient | shop |
| `bao` | Bao | Bear |  | home | Made by `mahjong_session.gd` (RelocatedSites/Home/MahjongTable chair 2) | — | sit | ambient | friend |
| `bonbon` | BonBon | Pig |  | home | Home seat | (12.85, 0.55, 29.7) | sit | ambient | friend |
| `kiko` | Kiko | Golden Retriever |  | home | Made by `mahjong_session.gd` (RelocatedSites/Home/MahjongTable chair 4) | — | sit | ambient | friend |
| `leo` | Leo | Lion |  | home | Home seat | (2.9, 0.81, 32.09) | sit | ambient | friend |
| `mahjong_awoo` | Awoo | Samoyed |  | home | Made by `mahjong_session.gd` (RelocatedSites/Home/MahjongTable chair 3) | — | sit | ambient | friend |
| `mei` | Mei | Siamese Cat |  | home | Made by `mahjong_session.gd` (RelocatedSites/Home/MahjongTable chair 1) | — | sit | host: `mahjong_mei` | friend |
| `sunny` | Sunny | Golden Retriever |  | home | Home seat | (9.15, 0.55, 31.3) | sit | ambient | friend |
| `doctor_floor1` | (doctor) | Pig | doctor | hospital | `Buildings/Hospital/Floor1/Room3/BonBonDoctor` | (48.6, -0.001, 250.25) | stand | ambient | hospital |
| `doctor_floor2` | (doctor) | Siamese Cat | doctor | hospital | `Buildings/Hospital/Floor2/Room3/CatDoctor` | (52.55, 5.598, 247.55) | stand | ambient | hospital |
| `doctor_floor3` | (doctor) | Beagle | doctor | hospital | `Buildings/Hospital/Floor3/Room1/BeagleDoctor` | (63.4, 11.198, 225.85) | stand | ambient | hospital |
| `dr_li` | Dr. Li | Pig | doctor | hospital | `Buildings/Hospital/DrLi` | (52.95, -0.001, 219.3) | stand | host: `family_dr_li` | hospital |
| `hospital_receptionist` | (doctor) | Sheep | doctor | hospital | `Buildings/Hospital/Floor1/Room1/SheepDoctor` | (61.15, -0.002, 227.6) | stand | ambient | hospital |
| `rosa` | Rosa | Samoyed | librarian | library | `RelocatedSites/Library/Librarian` | (50.5, 0.04, 28.1) | stand | host: `library_rosa` | library |
| `madame_luna` | Madame Luna | Siamese Cat | fortune_teller | mystery | `MysteryHouse/MysteryRoom/MadameLuna` | (128.4, 0.598, 73.4) | stand | host: `mystery_luna` | mystery |
| `mimi` | Officer Mimi | Siamese Cat | police | police | `People/CatEvidenceOfficer` | (-145, -0.002, 84.65) | stand | host: `evidence_mimi` | police |
| `police_receptionist` | (police officer) | Beagle | police | police | `RelocatedSites/Police/ReceptionOfficer` | (-143.1, 0.498, 71) | stand | ambient | police |
| `rocco` | Officer Rocco | Crocodile | police | police | `People/CrocodilePoliceOfficer` | (-152.05, -0.002, 77.75) | stand | host: `lineup_rocco` | police |
| `burger_cashier` | (cashier) | Golden Retriever | shopkeeper | restaurants | `Restaurants/Burger/GoldenCashier` | (-83.7, 0.078, 31.4) | stand | ambient | cashier |
| `burger_cook` | (cook) | Lion | chef | restaurants | `Restaurants/Burger/LionChef` | (-79.7, 0.078, 26.9) | stand | ambient | kitchen |
| `pizza_bartender` | (waiter) | Beagle | waiter | restaurants | `Restaurants/Pizza/BeagleBartender` | (-28.6, 0.078, 29.6) | stand | ambient | waiter |
| `pizza_cook` | (cook) | Bear | chef | restaurants | `Restaurants/Pizza/BearChef` | (-44, 0.078, 21.55) | stand | ambient | kitchen |
| `taqueria_cook` | (cook) | Crocodile | chef | restaurants | `Restaurants/Cafe/Taqueria/CrocodileCook` | (-59.6, 0.078, 27.7) | stand | ambient | kitchen |
| `taqueria_waiter` | (waiter) | Siamese Cat | waiter | restaurants | `Restaurants/Cafe/Taqueria/CatWaiter` | (-62.95, 0.078, 35.9) | stand | ambient | waiter |
| `twinkle` | Twinkle | Beagle | waiter | restaurants | `Restaurants/Pizza/BeagleWaiter` | (-33.3, 0.078, 36.75) | stand | host: `restaurant_twinkle` | waiter |
| `lana` | Lana | Sheep | teacher | school | `Buildings/School/TeacherLana` | (7.4, -0.002, 237.45) | stand | host: `grammar_lana` | school |
| `sports_clerk` | (salesperson) | Golden Retriever | sports_shopkeeper | sports | `Buildings/SportsStore/Interior/GoldenSalesperson` | (91.15, 0.038, 248.55) | stand | ambient | shop |
| `grocery_cashier` | (cashier) | Samoyed | grocery_shopkeeper | supermarket | `RelocatedSites/Supermarket/MarketInterior/SamoyedCashier` | (-135.9, 0.098, 120.6) | stand | host: `checkout_supermarket` | cashier |
| `grocery_clerk` | (salesperson) | Beagle | grocery_shopkeeper | supermarket | `RelocatedSites/Supermarket/MarketInterior/BeagleClerk` | (-130, 0.231, 121.4) | stand | host: `shop_supermarket` | shop |
| `paty` | Paty | Golden Retriever | businessman | warehouse | `Warehouse/Reception/Receptionist` | (-46.5, 0.517, 232.121) | sit | ambient | office |
| `ramon` | Ramón | Lion | warehouse_worker | warehouse | `Warehouse/Exterior/Ramon` | (-43.9, -0.002, 218.5) | stand | host: `warehouse_ramon` | warehouse |
| `awoo` | Sam | Samoyed |  | — | Avatar, stand-in, random customer | — | — | customer | friend |
| `cocodrilo` | Cocodrilo | Crocodile |  | — | Avatar, stand-in, random customer | — | — | customer | friend |
| `miso` | Miso | Siamese Cat |  | — | Avatar, stand-in, random customer | — | — | customer | friend |
| `poppy` | Poppy | Sheep |  | — | Avatar, stand-in, random customer | — | — | customer | friend |

<!-- npc-report:end -->

## Open items

| Priority | Item |
| --- | --- |
| Low | The sports store and hospital scenes still hold the clerk's and Dr. Li's old baked transforms; the registry moves them at load. The next bake of those units saves the registry spots (nothing to do by hand). |
| Low | Runtime game pieces (lineup suspects, bank customers, restaurant guests, the tutorial's cast) are not registry entries; they are made from the cast or from game data each round. |
| Low | The check's farmer render came out under Lana's face close-up camera (taken right after her host's line), so `farmer-chatter.png` was dropped; release the host camera before that capture next time. |
| Low | Chatter lines have no sound yet (the TALK interactable's `kind` is the hook). |
