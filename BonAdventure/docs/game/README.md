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
| [Playing the game](playing.md) | Start screens and profiles, the welcome tutorial, languages, studying words, the journal, controls, touch and the web app, vehicles, outfits, day and night |
| [The town](town.md) | The map and every building and outdoor area |
| [Minigames](minigames.md) | Every minigame: who runs it, where, what you do, and its learning card (purpose, words, tracking, session, progression) |
| [Words in each minigame](words.md) | Generated from the game data: the words each game tests or shows, in all three languages |

## The game in one paragraph

You play BonBon, a plush pig, in a small 3D town. Every object you click shows its word in the
language you are learning (Spanish, Chinese or English) and your own language. Plush characters
around town run short minigames that practise words and phrases in context: shopping, paying,
family, flights, ordering food, grammar, describing people, colours and shapes. A journal keeps
every word you have studied and how you did in the games. It runs on a laptop and as a landscape
web app on phones and tablets.

## Status at a glance

"Last change" is the most recent dated record or commit for that feature (all 2026). A screenshot can be
older than that change; each page dates its screenshot. "Tracked" means the game records right
and wrong answers per word in the journal.

### Minigames

| Minigame | Where | Tracked | Built | Last change |
| --- | --- | --- | --- | --- |
| [Grocery Run](minigames.md#grocery-run) | Supermarket door | Yes | 3 Nov | 14 Nov (shorter orders) |
| [Pay Up!](minigames.md#pay-up) | Supermarket till | No | 4 Nov | 9 Nov |
| [Who's Who?](minigames.md#whos-who) | Hospital entrance | Yes | 4 Nov | 4 Nov |
| [Flight Finder](minigames.md#flight-finder) | Airport information desk | Yes | 5 Nov | 8 Nov |
| [Stack & Pack](minigames.md#stack--pack) | Warehouse | Yes | 5 Nov | 14 Nov (five spatial tasks) |
| [On the Menu](minigames.md#on-the-menu) | Alta Cocina | Yes | 6 Nov | 11 Nov (walk-around flow) |
| [Spot the Suspect](minigames.md#spot-the-suspect) | Police station lobby | No | 6 Nov | 6 Nov |
| [Feel the Clues](minigames.md#feel-the-clues) | Police evidence room | Yes | 6 Nov | 8 Nov (redesign) |
| [Desk Dash](minigames.md#desk-dash) | School classroom | Chinese measure words only | 7 Nov | 14 Nov (5 questions, misses repeated) |
| [Mystery Doors](minigames.md#mystery-doors) | Mystery House | Yes | 9 Nov | 10 Nov |
| [Mahjong Club](minigames.md#mahjong-club) | Table in front of the home | No | 9 Nov | 16 Nov (camera shows Awoo, bigger pinwheel discards) |
| [Radar Patrol](minigames.md#radar-patrol) | Airport control tower | No (pastime) | 9 Nov | 15 Nov (easier taps) |
| [Wire It Up!](minigames.md#wire-it-up) | Electrical box at the home | No (pastime) | 9 Nov | 9 Nov |
| [Library Helper](minigames.md#library-helper) | Library | Yes | 13 Nov | 17 Nov (new categories and titles, tracked words, replenishing cart, cosy library) |

### Start screens and app

| Part | What is there | Last change |
| --- | --- | --- |
| [Title page and profiles](playing.md#starting-up) | The Bon Adventure logo and Play, then up to three profiles | 16 Nov (logo replaces the text title) |
| App name and icon | "Bon Adventure: Little Town of Words" ("Bon Adventure" under the icon); icon is the pig's head on mint (the user's picture) | 16 Nov (renamed, new icon, [evidence](../evidence/bon-adventure-logo-20261116/README.md)) |

### Buildings and areas

| Place | What is there | Last change |
| --- | --- | --- |
| [Home](town.md#home) | BonBon's house, pool, garage, mahjong table, electrical box; tutorial rooms | 14 Nov (plants, fewer plushes) |
| [Supermarket](town.md#supermarket) | Nine departments, every product a word, cashier and clerk | 17 Nov (one word per section: snacks, drinks/home swap) |
| [Library](town.md#library) | Six category shelves (3 books each), NEW BOOKS display at the rear wall, return cart, cosy reading corner | 17 Nov (new categories, desks removed, interior refresh) |
| [Restaurants](town.md#restaurants) | Alta Cocina, Pizza and Burger, Taquería | 12 Nov (Alta Cocina glass) |
| [Bakery / Café](town.md#bakery--café) | Cake counter and seating | 28 Oct |
| [Sports store](town.md#sports-store) | Departments incl. winter sports, plush staff | 9 Nov |
| [Clothing store](town.md#clothing-store) | Racks, checkout, fitting rooms with outfits | 9 Nov (fitting room) |
| [Electronics store](town.md#electronics-store) | Phones, gaming, appliances | 1 Nov |
| [Furniture store](town.md#furniture-store) | Living, bedroom, dining, office and lighting showrooms | 9 Nov |
| [Bank](town.md#bank) | Tellers, vault, office, ATMs, bear banker | 1 Nov |
| [Police station](town.md#police-station) | Lobby, lineup room, evidence room, cell | 8 Nov |
| [Airport and control tower](town.md#airport-and-control-tower) | Terminal, restrooms, walkable tower with deck, airfield | 12 Nov (tower deck) |
| [School](town.md#school) | Grammar classroom and teaching areas | 14 Nov (bigger board) |
| [Hospital](town.md#hospital) | Three floors, elevator, ward doctors, helipad | 14 Nov (elevator picker) |
| [Warehouse](town.md#warehouse) | Hall with loading bays, reception | 14 Nov (redesign) |
| [Mystery House](town.md#mystery-house) | Casa de las Estrellas, mystery room | 9 Nov |
| [Chapel](town.md#chapel) | Rebuilt sanctuary | 12 Nov |
| [Farm barn](town.md#farm-barn) | Hayloft, tools and supplies | 1 Nov |
| [Playground](town.md#playground) | Towers, slide, rideable swings | 1 Nov |
| [Park, zoo and coast](town.md#park-zoo-and-coast) | Public garden, four zoo zones, island; the clay animals walk; the zoo's tiger and the farm's horse are the new clay models; clay rooster on the farm lawn, clay capybara and clay monkey inside the zoo gate | 17 Nov (clay horse replaces the farm horse) |

## Open items worth knowing while reviewing

- **Library Helper** (named 17 Nov) has open assumptions (Cake, the 300 s rest) listed in
  its [design record](../guides/TOWN_DESIGN_BRIEF.md#library-return-cart-and-book-sorting-game--13-november-2026).
- **Hidden for now** (14 Nov, trimming for phones): the minimap, the full map (M) and hyper speed
  are switched off, not deleted ([hidden features](../../README.md#hidden-features)).
- **Shared doors:** the new door components exist, but buildings have not been moved onto them
  yet ([plan](../guides/DOORS.md)).
- **No screenshot yet** of the rebuilt chapel or the Mystery House in the docs.
- Known test failures are listed in the [verification record](../guides/FINAL_VERIFICATION.md).

## Keeping this guide current

When a feature is added or changed in a way a player would notice, update its row above and its
short entry on the page, and point the screenshot at the newest view. Keep the details in the
design record; this guide only summarises and links. Screenshots are linked from the dated
evidence folders in `docs/`, so if one moves, update the link here.
