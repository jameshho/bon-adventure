# Playing the game

[← Game guide](README.md)

How a player starts, learns, moves and gets around. The full key list is in the
[project README](../../README.md#controls-and-learning); details for developers are linked from
each section.

## Starting up

<img src="../evidence/bon-adventure-logo-20261116/title_1280x720.png" width="480" alt="Title page with the Bon Adventure logo">

*Screenshot 16 Nov (title page); [profile screen](../evidence/app-flow-20261112/profiles.png) 12 Nov.*

A title screen with the **Bon Adventure: Little Town of Words** logo (16 Nov; it replaced
the text title) and Play, then a character screen with up to three profiles, each
with its own avatar (one of the house plushes) and its own saves. A new profile picks the
language it speaks and the one it wants to learn, then the town loads. Each profile remembers
where the player was and comes back at that building's entrance or on clear ground nearby
(14 Nov).
[Project README](../../README.md) (startup flow) ·
[recorded checks](../guides/FINAL_VERIFICATION.md) (search `app_flow`). There is no separate startup guide yet.

## Welcome tutorial

<img src="../evidence/tutorial-review-20261117/market-cast.png" width="480" alt="Welcome tutorial at the supermarket">

*Screenshot 17 Nov (the closing picnic).*

"Welcome to Bon Adventure" runs once for a new profile: wake up in bed, a tour of the house, find
the hiding friends, buy fruit at the supermarket, visit the statue, then open the journal. It
can be skipped, and replayed from Settings. No minigame offers appear while it runs. Since 16 Nov
the rest of the town loads behind the title card after the house tour (with a progress bar), so
the house tour itself no longer stutters. Since 17 Nov the tour also starts behind the loading screen: the characters,
rooms and close-ups of the house tour are drawn there first, so the first lines in the house no
longer freeze on the web, and the loading bar moves with the real work all the way to the end.
Since 17 Nov it follows the user's script "Little Town of Words": lines move on by themselves
(a click or tap skips), a strip at the top says what to do, the controls unlock one at a time,
the two friends can be found in either order (drag the shower curtain open; ask BonBon for
hints), the shopping list is paid in $1 bills and quarters,
the statue card reads "statue of George Washington", and the tour ends with a picnic in the park
(placeholder lines). The journal's book button is cuter, with a clearer J. Since the user's review of
17 Nov: BonBon is shown close up while she talks; "Ready for an adventure?" waits for "Yes!" and
each friend's hello for "Hi! Nice to meet you!"; the view and walking steps wait for a real drag
and a longer walk; the shower curtain opens with E; only doors and BonBon can be used, and other
buildings' doors say it is not the right place; the EN button (hold it to read any line in your
language, now the only language toggle) and the journal button appear and pulse when they are
introduced, and the ▶ games button and the Run button stay hidden; the tour starts at noon and BonBon walks at your
speed; the town card can be skipped only once the whole town is loaded, so the market and park
parts no longer stutter. Since the second review of 17 Nov: in the house only the door where
Leo hides opens (the others stay shut and the guide says her friends wouldn't hide there); the
guide is shown close up when the friends are found and for "There's so much more...", and Sunny
for "we need some food first"; a player who picked BonBon is guided by another character; no
house character sits on the couch or naps on a bed during the tour; the friends no longer box
you in at the supermarket; the list is just 1 apple and 2 bananas; and a replay starts with
the house doors shut.
[Tutorial guide](../guides/ARCHITECTURE_REVIEW_PART1.md#welcome-tutorial)

## Languages

Three languages: **English**, **Spanish** and **Chinese (Hong Kong)**. A player has a native
language and a language being learned, chosen for each profile and changeable in Settings.
Chinese shows pinyin under the text.
- **Native mode** (Settings checkbox) shows everything in the player's own language.
- **Hold L** (or tap the language badge) to see signs, building names and posters in the
  native language for a moment.
- The **translate bubble** in the dialogue box shows a line in the native language.

[Languages and words](../guides/ARCHITECTURE_REVIEW_PART1.md#vocabulary-data-procedure)

## Studying words and the journal

<img src="../evidence/vocabulary-book-20261108/saved-en-es.png" width="480" alt="Journal word list">

*Screenshot 8 Nov.*

Click or tap almost any object to see a **word card** with the word in both languages; that
counts as studying it. Some objects can be **picked up** (books, baskets) and inspected in
BonBon's hand. The **journal** (J, or the book button top right) lists every word, by category or
by area, with ★ saved words, ✓ studied words and the right and wrong answers from the tracked
minigames.
[Vocabulary book](../guides/ARCHITECTURE_REVIEW_PART1.md#vocabulary-book) ·
[holding things](../guides/HAND_HOLD.md)

## Moving and controls

- **Laptop:** WASD to walk, Space to jump, Shift or the Run button to run, E to use things
  (doors, seats, vehicles, toilets, faucets), drag or right-mouse to look around, wheel to zoom,
  Esc for Settings or to close the top window. F1 shows every key.
- **Camera follows me** (on by default since 14 Nov): walking sideways slowly turns the view,
  so one hand can steer.
- **Climb** ladders with W and S; **sit** on chairs, sofas and swings; swivel chairs turn with
  A and D.

[All controls](../../README.md#controls-and-learning)

## Touch and the web app

<img src="../evidence/touch-controls-20261112/touch.png" width="480" alt="Touch controls">

*Screenshot 12 Nov; button layout changed 14 Nov.*

The game also runs as an installable web app in landscape on phones and tablets. A floating
joystick appears where the left thumb touches; buttons on the right jump, use (E) and run; drag
to look, pinch to zoom, tap to use. A phone held upright shows the landscape game turned 90°.
New builds load automatically (15 Nov).
[Web app](../../README.md#web-app-pwa)

## Getting around

<img src="../evidence/vehicle-boarding-20261029/5-driven-out.png" width="480" alt="Driving a car">

*Screenshot 29 Oct.*

- **Cars and trucks:** walk up and press E to open the door and get in; W/S/A/D to drive,
  Space to brake, R to recover. Parked cars and a motorcycle in every lot (14 Nov); the police
  car and the warehouse box truck can be driven too.
- **Scooter:** hop on and ride. [Scooter](../guides/ZOO_VEHICLE_IMPLEMENTATION.md#scooter-and-rider--9-november-2026)
- **Helicopter and plane:** easy flying by default (14 Nov): W to go, A/D to turn, let go and
  it levels or hovers; C switches to expert controls. A Reset button returns the plane to the
  runway. [Aircraft](../guides/aircraft.md#easy-flying)
- **Swan boats** on the pond and **swings** at the playground.

[Road vehicles](../guides/ZOO_VEHICLE_IMPLEMENTATION.md) ·
[helicopter](../guides/helicopter_inertia/README.md)

## Outfits

<img src="../evidence/fitting-room-20261109/picker.png" width="480" alt="Fitting room outfit picker">

*Screenshot 9 Nov; picker paged for touch 14 Nov.*

In the clothing store's fitting rooms BonBon tries on outfits (shopkeeper, police, doctor, waiter,
driver, teacher, gardener, pilot, businessman, chef) and keeps one.
[Fitting room](../guides/TOWN_DESIGN_BRIEF.md#fitting-room-outfit-picker--9-november-2026)

## Day and night

A day lasts 20 minutes, with sun, moon, sky, street lamps and indoor lights. The clock at the
top centre can jump an hour forward or back.
[Day-night cycle](../guides/performance/README.md#day-night-cycle--9-november-2026)

## Characters

The town's people are plush animals: BonBon the pig (the player), the house friends, shop staff in
outfits, and the minigame hosts. They blink and make small gestures. Clicking a house friend
shows its name.
[Plush characters](../guides/COMPONENTS.md#plush-characters)

## Sound

Only a few sounds exist so far (toilets and faucets); the rest of the game is silent for now.
