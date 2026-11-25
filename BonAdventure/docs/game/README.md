# Game guide

What is in **Bon Adventure: Little Town of Words** (the game's name since 16 Nov 2026; earlier
Vocabulary Town) today, for reviewing the game. Each page gives a few lines
and one current screenshot per feature, then links to the design record or guide with the
details. It describes what is **built**; approved but unbuilt building plans live in the
[master design blueprint](../guides/TOWN_DESIGN_BRIEF.md#start-here-current-approved-design), and how to
change the code lives in the [documentation map](../README.md).

Since 16 Nov 2026 (user) this guide is also the **source for each minigame's purpose and
progression design** ([minigames](minigames.md)). Word lists are generated from the game data
([words](words.md)); the dated design records keep the detailed history.

**Names (16 Nov 2026, user decision).** The pig player character is **BonBon** (é¦é¦, still a girl;
Spanish keeps feminine forms), renamed from her earlier name. The game is **Bon Adventure: Little Town of
Words**, and the repository is moving to `jameshho/bon-adventure` (the old web address will not redirect).
The rename covers current files and the dated evidence and archive text; git history is unchanged.

| Page | What it covers |
| --- | --- |
| [Playing the game](playing.md) | Start screens and profiles, the welcome tutorial, languages, studying words, the journal, controls, touch and the web app, finding places (town map, guide arrow), vehicles, outfits, day and night |
| [The town](town.md) | The map and every building and outdoor area |
| [Minigames](minigames.md) | Every minigame: who runs it, where, what you do, and its learning card (purpose, words, tracking, session, progression) |
| [Words in each minigame](words.md) | Generated from the game data: the words each game tests or shows, in all three languages |

## The game in one paragraph

You play BonBon, a plush pig, in a small 3D town. Every object you click shows its word in the
language you are learning (Spanish, Chinese or English) and your own language. Plush characters
around town run short minigames that practise words and phrases in context: shopping, paying,
family, flights, ordering food, grammar, describing people, colours and shapes. A journal keeps
every word you have studied and how you did in the games. Grocery Run has levels and 1–3 stars
per session (18 Nov; Pay Up! had them too until it became Grocery Run's checkout on 21 Nov); the
other games will follow. It runs on a laptop and as a landscape
web app on phones and tablets.

## Status at a glance

"Last change" is the most recent dated record or commit for that feature (all 2026). A screenshot can be
older than that change; each page dates its screenshot. "Tracked" means the game records right
and wrong answers per word in the journal. **Levels** ([how games get harder](minigames.md#how-games-get-harder),
18 Nov): built for Grocery Run (and Pay Up! until 21 Nov); designed, not built, for the other learning games.
**Which words come up** ([word memory](minigames.md#which-words-come-up), 24 Nov): every tracked
game picks its words from one shared memory, so new words come in gradually and words about to
be forgotten come back.

### Minigames

| Minigame | Where | Tracked | Built | Last change |
| --- | --- | --- | --- | --- |
| [Grocery Run](minigames.md#grocery-run) | Supermarket door and till | Yes | 3 Nov | 25 Nov (Esc mid-game asks whether to stop); 21 Nov (paid at the till; prices; free shopping with a basket) |
| [Pay Up!](minigames.md#pay-up) (retired) | Supermarket till | No | 4 Nov | 21 Nov (became Grocery Run's checkout) |
| [Who's Who?](minigames.md#whos-who) | Hospital entrance | Yes | 4 Nov | 4 Nov |
| [Flight Finder](minigames.md#flight-finder) | Airport information desk | Yes | 5 Nov | 8 Nov |
| [Stack & Pack](minigames.md#stack--pack) | Warehouse | Yes | 5 Nov | 25 Nov (also tracks the position words on, next to, right, up); 21 Nov (two-level shelf, tap to place; no cardboard box) |
| [On the Menu](minigames.md#on-the-menu) | Alta Cocina | Yes | 6 Nov | 24 Nov (wrong order sent back at once, retry with wrong dishes blocked) |
| [Spot the Suspect](minigames.md#spot-the-suspect) | Police station lobby | No | 6 Nov | 6 Nov |
| [Feel the Clues](minigames.md#feel-the-clues) | Police evidence room | Yes | 6 Nov | 8 Nov (redesign) |
| [Desk Dash](minigames.md#desk-dash) | School classroom | Chinese measure words only | 7 Nov | 23 Nov (card translated by holding the HUD's EN button) |
| [Mystery Doors](minigames.md#mystery-doors) | Mystery House | Yes | 9 Nov | 10 Nov |
| [Mahjong Club](minigames.md#mahjong-club) | Table in front of the home | No | 9 Nov | 25 Nov (nameplates and cream counter removed; 24 Nov: UI polish, soft call buttons, pull tab; hide the hand to see your tiles; 23 Nov: carry on an unfinished game; one EN button, top right; Mahjong! still offered after a pung) |
| [Radar Patrol](minigames.md#radar-patrol) | Airport control tower | No (pastime) | 9 Nov | 15 Nov (easier taps) |
| [Wire It Up!](minigames.md#wire-it-up) | Electrical box at the home | No (pastime) | 9 Nov | 9 Nov |
| [Library Helper](minigames.md#library-helper) | Library | Yes | 13 Nov | 25 Nov (walking out of the library or Esc mid-game asks whether to stop; [view](../evidence/game-exits-20261125/leave-question.png)); 25 Nov (a marimba chime on the right shelf, two soft falling notes on a wrong one, [sound](playing.md#sound)); 21 Nov (book close-up on pick-up, bigger right-shelf burst, thanks with a zoom on Rosa, results card, new cart after walking away) |
| [Next, Please!](minigames.md#next-please) | Bank teller window 2 | No | 18 Nov | 24 Nov (seated at window 2, one request line, thanks move on by themselves, a hidden red alarm button instead of "Call the police"; [screenshots](../evidence/bank-teller-polish-20261124/); 23 Nov: monitor and customer in one view, the bank manager) |
| [Feeding Time!](minigames.md#feeding-time) | Zoo food booth, inside the gate | Yes | 24 Nov | 25 Nov (walking out of the zoo on foot mid-game puts you back by Nico and asks whether to stop); 24 Nov (food booth, paper bag, free feeding, 4 levels; [screenshots](../evidence/zoo-feeding-20261124/)) |

### Start screens and app

| Part | What is there | Last change |
| --- | --- | --- |
| [Title page and profiles](playing.md#starting-up) | The Bon Adventure logo and Play, then up to three profiles, the character grid and the language page; loading bar; dialogue box | 18 Nov (new cream-and-meadow art style from the user's mockups: candy buttons, cloud titles, Fredoka font, cream dialogue box; [style guide](../guides/UI_STYLE.md)); 23 Nov: character headshots cut from the mockup, sharp at any window size) |
| [Welcome tutorial](playing.md#welcome-tutorial) | Wake up, find the friends, buy fruit, the statue, the journal, a picnic | 21 Nov (camera pans between speakers with the box after the pan, $1.25 price and tag, cashier close-up, shorter market and journal lines, new last line, bigger picnic blanket where the friends stay to chat; checked from the market on, the house act's 20 Nov changes not re-checked) |
| In-game screens | Settings, journal, F1 guide, HUD buttons, word card, poster close-up, clock, cart, game picker and minigame cards | 25 Nov (a light cream veil behind Settings, the map, the journal and the word card instead of the dark shade, [before/after](../evidence/ui-scale-20261125/veil-settings.png); drag the journal's word list to scroll it; the HUD status lines shrink on a phone); 25 Nov (sound effects: a chime for a stamp coin, its own open and close sound for each kind of door, the chapel bell, Library Helper's right and wrong shelf; set by the Sound effects slider; [sound](playing.md#sound)); 25 Nov (demo lofi music: its own track on the loading screen, another in the town, and one of five moods during each minigame (quiz, errands, mystery, focus, outdoors); it dips while a word is spoken; set by the Music slider; [sound](playing.md#sound)); 24 Nov (a word on a poster opens a close-up of the whole poster, [view](../evidence/poster-closeup-20261124/classroom-poster-family-closeup.png); Settings has Main volume, Music, Sound effects and Spoken words sliders; a new pastel journal icon on the HUD button and the journal's title; with a keyboard, small key circles (J, Esc, L, F9, M) on the HUD buttons; the word card's speaker button is built but hidden until spoken words are switched on; [views](../evidence/sound-ui-20261124/)); 23 Nov (nouns show a picture of their object in the journal and on the results card; [journal](../evidence/word-pictures-20261123/journal-furniture.png)); 18 Nov (same art style in soft blue: soft blue cards and buttons with white rims, dark teal Fredoka text; [views](../evidence/ui-style-20261118/), [style guide](../guides/UI_STYLE.md)) |
| [Passport](playing.md#passport-missions-stamps-and-achievements) | Missions (3 at a time, 10-minute refresh, Go there, stars on the map), town stamps page, Exploration log of every activity, XP | 21 Nov (new; 18 stamp coins placed in the town, one per building; the bank safe opens, the chapel is bigger with a bell tower to climb and a bell to ring) |
| [Town map and guide arrow](playing.md#finding-places) | M or the map button: a picture of the town with every building's name and a "you are here" dot; tap a place, then Go there for an arrow that points the way; Go there in the ▶ picker too | 18 Nov (new; the old live map stays off) |
| [Vehicles](playing.md#getting-around) | Cars, trucks, buses, the scooter, the helicopter and the plane; E to get in | 25 Nov (engine sounds: car, truck, helicopter and plane, rising with speed, [sound](../guides/VOICE.md#sound-effects-25-nov-2026); not heard in the game yet); 25 Nov (high up, the horizon blends into the sky with no hard line, [views](../evidence/light-indoor-flight-20261125/flight.png)); 23 Nov (the view from the air reaches further the higher you fly and tilts down to the town, [views](../evidence/flight-view-20261123/); one graphics setting for every device, the Settings graphics row removed; one set of flying controls for the plane and helicopter on every device, on-screen ▲ / ▼; the plane is smaller and slower with a new steady flight model, [views](../evidence/small-plane-20261123/); no hands-on play-test yet); 21 Nov (headlights for every road vehicle, siren and flashing lights for the police car, ambulance and fire truck; [night view](../evidence/vehicle-lights-20261121/night-red.png); earlier 21 Nov: cars keep turning while A/D is held, camera swings behind, [views](../evidence/car-driving-20261121/); no hands-on play-test yet) |
| [Townspeople](../guides/NPCS.md) | Every NPC (38 in the town) is in one registry; talk to anyone without a game on offer (E, click or tap) for a short everyday line in the language you learn (hold EN for your own); keep asking and they politely brush you off for a while | 25 Nov (whoever you talk to turns to face you while the line shows, then turns back, [views](../evidence/characters-20261125/); a calling NPC eases down from its hop); 23 Nov (new; [chatter](../evidence/npc-registry-20261123/chatter-line.png), [brush-off](../evidence/npc-registry-20261123/chatter-brush-off.png)) |
| App name and icon | "Bon Adventure: Little Town of Words" ("Bon Adventure" under the icon); icon is the pig's head on mint (the user's picture) | 16 Nov (renamed, new icon, [evidence](../evidence/bon-adventure-logo-20261116/README.md)) |

### Buildings and areas

| Place | What is there | Last change |
| --- | --- | --- |
| [Home](town.md#home) | BonBon's house, pool, garage, mahjong table, electrical box, record player; tutorial rooms | 25 Nov (a record player beside the living room TV: pick, skip or stop the music, [view](../evidence/record-player-20261125/closeup.png)); 23 Nov (no bicycle in the garage) |
| [Supermarket](town.md#supermarket) | Nine departments, every product a word, cashier and clerk | 18 Nov (compact layout with a staff wall and a cold wall; bigger, clay-toy products; real front windows) |
| [Library](town.md#library) | Six category shelves (3 books each), NEW BOOKS display at the rear wall, return cart, cosy reading corner | 17 Nov (new categories, desks removed, interior refresh, readable signs) |
| [Restaurants](town.md#restaurants) | Alta Cocina, Pizza and Burger, Taquería | 23 Nov (taller facade signs, Pizza and Burger glass double door, no tray at the taquería waiter's face) |
| [Bakery / Café](town.md#bakery--café) | Cake counter and seating with clay-style meals on the tables | 23 Nov (table meals redrawn) |
| [Sports store](town.md#sports-store) | Departments incl. winter sports, plush staff | 23 Nov (clerk moved from the rear corner to the front of the checkout, [view](../evidence/npc-registry-20261123/sports_clerk-front.png)); 18 Nov (shop-row storefront: meadow green) |
| [Clothing store](town.md#clothing-store) | Racks, checkout, fitting rooms with outfits | 18 Nov (shop-row storefront: rose pink) |
| [Electronics store](town.md#electronics-store) | Computers, phones, cameras, audio, TV wall, gaming corner, appliances (toaster, kettle, blender and rice cooker are words), plush clerk | 23 Nov (small products 20% bigger; small appliances became words) |
| [Furniture store](town.md#furniture-store) | Living, bedroom, dining, office and lighting showrooms | 18 Nov (shop-row storefront: teal) |
| [Bank](town.md#bank) | Tellers, vault, safe-deposit room, manager's office, ATMs, bear banker, manager | 24 Nov (wider staff door, teller chairs to sit on; 23 Nov: grown backward: bigger vault room, safe-deposit room, office; staff door behind the counter; slow heavy vault door) |
| [Police station](town.md#police-station) | Lobby, lineup room, evidence room, cell; real front windows | 23 Nov (two separate lockers whose doors open, [views](../evidence/civic-fixes-20261123/)) |
| [Airport and control tower](town.md#airport-and-control-tower) | Terminal, restrooms, walkable tower with deck, airfield | 23 Nov (deck floor, ladder, stair rails) |
| [School](town.md#school) | Grammar classroom and teaching areas | 23 Nov (science room: mountain picture and continent chart instead of the wall triangle and green blob, named plaques; the CLASSROOM and MAIN HALL plaques now face the room, notes on the notice board) |
| [Hospital](town.md#hospital) | Three floors, elevator, ward doctors, helipad | 23 Nov (Dr. Li stands clear of the entrance hedge); 14 Nov (elevator picker) |
| [Warehouse](town.md#warehouse) | Hall with loading bays, reception | 23 Nov (the supply cabinet opens outside the game) |
| [Mystery House](town.md#mystery-house) | Casa de las Estrellas, mystery room | 9 Nov |
| [Chapel](town.md#chapel) | Rebuilt sanctuary; bell tower climbed by a ladder inside, from a doorway in the nave | 25 Nov (the bell sounds a ding-dong when rung, heard across the square); 23 Nov (ladder moved inside, two pew rows removed) |
| [Farm barn](town.md#farm-barn) | Hayloft, tools and supplies, Tomás the farmer (bear in overalls and a straw hat; farm chatter); hen house with six hens and eggs to collect | 24 Nov (walk-in hen house: find eggs, carry them to the crate by its door, Drop button, [view](../evidence/hen-house-walkin-20261124/coop-door.png)); 23 Nov (farmer added) |
| [Playground](town.md#playground) | Towers, slide, rideable swings | 1 Nov |
| [Park, zoo and coast](town.md#park-zoo-and-coast) | Public garden, four zoo zones, island; the clay animals walk; the zoo's tiger and the farm's horse are the new clay models; clay capybara walks in Wildlife Plains (word: capybara); clay rooster, chick and hen on the farm lawn, clay monkey inside the zoo gate; no red motorcycles (only BonBon's teal scooter) | 25 Nov (animals turn on the spot before they walk off and ease in and out of their steps; the zoo food booth sign fits in every language, on two lines); 24 Nov (clay hen on the farm lawn) |

## Open items worth knowing while reviewing


- **Library Helper** (named 17 Nov) has an open assumption (Cake) listed in
  its [design record](../guides/TOWN_DESIGN_BRIEF.md#library-return-cart-and-book-sorting-game--13-november-2026).
- **Hidden for now** (14 Nov, trimming for phones): the minimap and hyper speed are switched off,
  not deleted ([hidden features](../../README.md#hidden-features)). The map (M) is back since 18 Nov
  as a baked picture with a guide arrow ([finding places](playing.md#finding-places)).
- **Shared doors:** the new door components exist, but buildings have not been moved onto them
  yet ([plan](../guides/DOORS.md)).
- **No screenshot yet** of the rebuilt chapel or the Mystery House in the docs.
- Known test failures are listed in the [verification record](../guides/FINAL_VERIFICATION.md).

## Keeping this guide current

When a feature is added or changed in a way a player would notice, update its row above and its
short entry on the page, and point the screenshot at the newest view. Keep the details in the
design record; this guide only summarises and links. Screenshots are linked from the dated
evidence folders in `docs/`, so if one moves, update the link here.
