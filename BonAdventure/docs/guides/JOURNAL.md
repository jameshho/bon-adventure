# Vocabulary journal: the sticker book

**Approved design (25 Nov 2026); partly built.** **Built 25 Nov 2026:** the baked place index
and the Places tab (contents, chapters, silhouettes, word page, search, ★ Pocket, the total):
see [Built so far](#built-so-far-25-nov-2026). Everything else on this page is not built yet. The
user approved this to replace the spreadsheet-style journal (the table of 8 Nov 2026,
`scripts/ui/vocabulary_book.gd` inside `vocabulary_hud.gd`, now in git history; its record:
[vocabulary book](ARCHITECTURE_REVIEW_PART1.md#vocabulary-book)). User's brief: the journal "feels
cluttered, spreadsheet-like, and unnecessarily complicated". The four directions explored
(sticker book, picture dictionary, word garden, word lens), with wireframes and the comparison,
are on the exploration page (private, the user's claude.ai account):
<https://claude.ai/artifact/FLeLXwAh7zrX7SPpbRWXUh>. The user then answered 23 questions; this page
records those answers and how four open points were settled. Nothing here is built until a
section says so.

## Why the old table is being replaced (findings, 25 Nov 2026)

- 11 controls and a 7-column header come before the first word; about 8 rows show at a time.
- Only 203 of 800 words are tested by any minigame ([usage report](vocabulary-report/summary.md)),
  so for about 600 words Studied / Right / Wrong can only ever read "– 0 0".
- About 456 words can have a [word picture](ARCHITECTURE_REVIEW_PART1.md#word-pictures); the rest
  leave an empty cell, which makes the rows ragged.
- The [word memory](MINIGAMES.md#word-memory) knows how well each tested word is remembered;
  the journal shows none of it.
- "0 of 800" counts 47 words no player can find (see [settled point 1](#1-what-the-total-counts)).

## User decisions (25 Nov 2026)

| # | Topic | Decision |
| ---: | --- | --- |
| 1 | "Word locking" in the brief | A typo; no such feature |
| 2 | Audience | Children and adult beginners equally: a cute look that is still quick for adults |
| 3 | Organisation | Two tabs over the same words: **Places** and **Topics** |
| 4 | Opening tab | The tab used last (Places the very first time) |
| 5 | Words not found yet | A **silhouette with "?"** instead of the word |
| 6 | Searching a word not found yet | Not revealed: the silhouette, the place it is in, and **Find it** (the guide arrow) |
| 7 | Words in many places | Their own **Around town** chapter (rule: 4 or more places) |
| 8 | Look | A **sticker album**: cream pages with a centre fold, white-edged stickers |
| 9 | Stickers per view | **8** (4 per page) at a laptop size; pages turn, no scroll bar |
| 10 | Text on a found sticker | The **foreign word**; a tap flips it to the native word, a second tap opens the word page |
| 11 | Holding L | Flips **every** sticker on the page to the native word while held |
| 12 | Word page | Big picture, word, translation, speaker, plus **where it is found** (with Find one), **how well it is known**, and an **example sentence** |
| 13 | Right / wrong / translated counts | Behind a **Details** button on the word page |
| 14 | How well a word is known | **Plant stages**: seed → sprout → leaves → flower |
| 15 | Words without a 3D picture | **Drawn icons** made from data (swatches, shapes, clocks, calendars, flags, arrows, opposite pairs); a text tag only where nothing fits |
| 16 | ★ Saved | **Just a list** (the Pocket); saved words get no priority in games |
| 17 | Review in the journal | **Yes, in the first version**: a short review round |
| 18 | Which words it reviews | **Due words first** (the word memory decides), then newly found words |
| 19 | Question type | Hear / see the foreign word, **pick the right picture** of 3–4 |
| 20 | Finishing a place | A **celebration and a Passport stamp** |
| 21 | Topics tab | About **12 friendlier chapters with sub-shelves**, not the 23 data categories |
| 22 | A new word found in town | A **sticker flies from the word card into the journal button** |
| 23 | Progress | A **full total with a bar** ("N of M found") **and a count per place**. User: it "encourages the player to discover all the words in the game, similar to how achievements incentivize" |

## Settled open points (25 Nov 2026)

The user asked Claude to settle these four ("Yes, go ahead"). They are working rules; change them
here if the user disagrees.

### 1. What the total counts

- A word is **found** when its word card is opened (today's "studied", `main.gd`
  `_on_word_studied`) **or** the first time it is answered in a tracked minigame (the
  [results screen](MINIGAMES.md#results-screen)'s "first meaningful encounter"). The word card
  writes the per-language studied list and a game answer the
  [practice log](ARCHITECTURE_REVIEW_PART1.md#practice-tracker) (per language learned); the
  journal counts a word found when either has it, so nothing new is saved (corrected 25 Nov
  2026: the first draft said both write the studied list, which game answers do not).
- The total, every chapter and every count only include **findable** words: clickable somewhere
  in town, or tested or shown by a game. Today that is 758 of 800 (753 clickable, plus airplane,
  car, soccer, tennis and bed, which only Library Helper or the grammar class asks).
- The other 42 are not shown, so 100 % can be reached. They are content gaps, listed by the usage
  report: 22 placed nowhere, and words on things a click *uses* instead of naming (vehicles,
  beds, since [interactables stopped being words](ARCHITECTURE_REVIEW_PART1.md#clickable-word-items--9-november-2026)).
  Whether using a vehicle should count as finding "car" is a separate question for the user.

### 2. Example sentences

- One short sentence per word and language, in `data/words.json` as an optional `example`
  (`{"es": …, "en": …, "zh": …}`), next to the word's `text`, so words stay the only source.
- The word page leaves the line out when a word has none. The first batch is the tier 1 words
  (164), then tier 2; existing dialogue in `data/phrases.json` is reused where a line fits.
- `tools/word_data.py` validates them (every language or none); the language check covers them.

### 3. Topic chapters and shelves

- The chapter comes from the word's existing `category` through one fixed map, so most words need
  no new data. Draft for the user's review (findable words today):

  | Chapter | From categories | Words |
  | --- | --- | ---: |
  | Food & kitchen | Food & Drink, Kitchen & Dining | 131 |
  | Home | Furniture, Around the House, Electronics & Appliances, Building Parts | 117 |
  | Town | Places & Rooms, Streets & Town, Vehicles, Shopping & Money | 84 |
  | Time & position | Time & Directions | 81 |
  | Body & health | Health & Body | 67 |
  | School & play | School & Arts, Sports & Play | 65 |
  | Animals & nature | Animals, Nature | 59 |
  | Colours & describing | Colors & Descriptions | 36 |
  | People & family | People, Family | 32 |
  | Travel & world | Travel, Countries | 30 |
  | Doing | Actions | 27 |
  | Clothes | Clothing | 24 |

- **Shelves** split a chapter into groups of about 8–24 words (Food & kitchen → fruit,
  vegetables, drinks, meals, sweets, cookware…). A word's shelf is an optional `shelf` id in
  `data/words.json`, needed only in chapters over 24 words; shelf names go in
  `data/phrases.json` in every language. Shelf lists are drafted for the user's review when the
  Topics tab is built.

### 4. Which words the review can ask

- The review asks only words whose answer picture is unambiguous: a 3D word picture, or a drawn
  icon for a colour, shape, day, month, clock time or country.
- Verbs, positions and describing words are left out of the picture question. Once they have
  example sentences, they can get a fill-the-gap question (a later decision).
- The 2–3 wrong pictures come from other found words of a different shelf, so the choice is
  about the word, not about telling two fruits apart.

## The design

### Screens

- **Header (both tabs):** *(built 25 Nov 2026, without the tabs)* the journal icon and title, the total ("312 of 758 words found" and a
  bar), search, **★ Pocket**, ✕.
- **Places tab, contents:** *(built 25 Nov 2026, without Practise)* one card per place (the [zones](../../data/zones.json)) with its
  icon, "12 of 28" and a small bar; a place not visited yet is greyed. Shelves on the same page:
  **Around town**, **★ Pocket**, and **Practise** with the number of words ready.
- **Topics tab, contents:** the 12 chapters, each with its count; inside, shelves as chips.
- **Chapter:** *(built 25 Nov 2026, without room sections)* a two-page spread of 8 stickers, big page arrows and a swipe. Long place chapters
  (the airport has 92 words) are split into sections by room where the building names its rooms
  (`scripts/world/room_names.gd`); to confirm when built.
- **Sticker:** *(built 25 Nov 2026, without drawn icons and plant stages)* found = picture (3D word picture or drawn icon) and the foreign word, a plant stage
  in a corner, a ★ pin when saved. Not found = the same picture as a soft silhouette (colour
  removed) with "?"; a word with no picture is a plain "?" slot. Tap flips to the native word,
  a second tap opens the word page; flipping another sticker turns the first back.
- **Word page:** *(built 25 Nov 2026, without the plant stage, Find one and the example
  sentence)* big picture, word (with pinyin when Chinese is learned), translation, speaker,
  ★; the plant stage with a short phrase ("Growing"); "Found in" with the places and **Find one**;
  the example sentence; **Details** opens today's right / wrong / translated tiles and per-game
  table. Page arrows step through the chapter.
- **Search:** *(built 25 Nov 2026, without Find it)* one field on every screen, both languages, accents ignored (today's `fold()`).
  Found words open as stickers; unfound words show the silhouette, its place and **Find it**.

### Plant stages

From the word memory (`word_memory.gd`), read only:

| Stage | Meaning |
| --- | --- |
| Seed | Found, never answered in a game or the review |
| Sprout | Answered once |
| Leaves | Answered more than once, still being learned (stability under `LEARNED_STABILITY`) |
| Flower | **Known**: stability at least `LEARNED_STABILITY` (decision D9 in the [improvement plan](improvement-plan/DECISION_LOG.md)) |

A word that is due (recall under the target) shows its stage drooping, never as a failure. The
thresholds are tunable.

### The review round

- **Practise** (contents page) starts about 8 questions, roughly a minute: due words first, then
  newly found words, in the word memory's order (`order()`), within the
  [settled limits](#4-which-words-the-review-can-ask).
- Each question says and shows the foreign word; the player taps the right picture of 3–4.
- Answers are recorded like any game: the practice log under a new game id, so the word memory
  updates; the shared [results screen](MINIGAMES.md#results-screen) ends the round. Its name and
  title are to be chosen with the user.

### In the town

- **A new word:** after the word card, a small sticker of it flies to the journal HUD button,
  which bounces. Built sound-ready (no sound yet).
- **Find it / Find one:** sets the [guide arrow](MINIGAMES.md#town-map-and-guide-arrow) to the
  nearest object carrying the word, or to its building when that building has not loaded yet on
  the web.
- **A finished place:** a short celebration and a stamp on the Passport (a new achievement per
  place in `data/achievements.json`; [Passport](ACHIEVEMENTS.md)).
- **Holding L** flips every sticker on the open page, like the rest of the game.

## How it would be built

- **Baked place index first** *(built 25 Nov 2026, [below](#baked-place-index))*. `area_vocabulary.gd` only knows the buildings that are loaded, and
  on the web buildings load as the player approaches. `tools/vocabulary_report.gd` already works
  out where every word is placed and whether it is clickable; it should also write a small data
  file (word → places, findable) that the journal reads. Around town (4 or more places) is
  computed from it: 54 words today, including apple, cake, fish and orange, which are in shops,
  restaurants and the zoo.
- **Reuse:** the HUD's journal window, `BonStyle` (cards, pills, Fredoka), `word_pictures.gd`,
  the speaker (`sound.gd say_word`), the bookmark functions, `PracticeLog`, `WordMemory`,
  `results_flow.gd` / `session_words.gd`, the guide arrow, `flags.gd`, the achievements tracker.
- **New:** the sticker book view replacing the table in `vocabulary_book.gd`; drawn icons for
  words without a 3D picture; a read-only stage accessor on `word_memory.gd`; the review session;
  the fly-to-book effect; `example`, `shelf` (and for pair icons `opposite`) in `data/words.json`;
  shelf and journal text in `data/phrases.json`.
- **Saves:** no format change. The book reads the studied list, bookmarks, practice log and word
  memory as they are; the review writes the practice log like any game.
- **Performance:** 8 stickers a view stays inside the picture budget (two drawn at a time, 200
  kept).
- **Improvement plan:** when this ships it replaces the table that UI-03 (journal drag-to-scroll)
  fixes, and it is where LEARN-04 (known words in the journal) shows up as the flower.

Suggested order: ~~baked place index → Places tab, word page, silhouettes and the total~~ (built
25 Nov 2026) → drawn icons → plant stages, Find it, fly-to-book and place stamps → review round → Topics tab and
shelves → example sentences in batches.

## Built so far (25 Nov 2026)

Steps 1 and 2 of the suggested order. Check and views:
[`docs/evidence/journal-sticker-book-20261125/`](../evidence/journal-sticker-book-20261125/)
(`verify.gd`, run_checks id `journal_sticker_book`; laptop 1280×800 views and phone-landscape
`-844x390` views). No save format changed.

### Baked place index

- `tools/vocabulary_report.gd -- --write` also writes **`data/journal_places.json`** (only when
  its content changes; no date): `words` = every findable word with its places (data/zones.json
  ids, in that file's order), `from_games` = the words only games find (their places are the
  games' places), `not_findable` = the rest. Rerun it after placing words, moving a
  building's words or a minigame, like the usage report.
- A clickable word's places are the zones of its clickable objects (`area_vocabulary.gd`
  assignments after interactables are dropped). A word no click can study but a game tests or
  shows (airplane, car, soccer, tennis and bed today) gets the places of those games' NPCs
  (`data/town_map.json` `games`): the library, or the school for bed.
- Today (25 Nov 2026): **758 findable, 42 not findable** (as settled in point 1), **50 Around
  town words** (4 or more places; the design's draft said 54: cake is in 3 places, not 4).
- The journal reads the file once (`vocabulary_book.gd` `place_index()`); without it, it falls
  back to the live area index (only the loaded buildings).

### Places tab

- **Where:** `scripts/ui/vocabulary_book.gd` (the album, replacing the table) inside the HUD's
  journal window (`vocabulary_hud.gd`: header with icon, title, "N of M words found" over
  `BonStyle.StripedBar`, the book's search field and ★ Pocket button, ✕). Main watches the book's
  Back button for Esc: word page → chapter → contents → closed.
- **Contents:** 9 cards a page (3 × 3), two pages a spread, page arrows, swipe and mouse wheel:
  Around town first, the places by name, ★ Pocket last (26 places + 2 shelves = 2 spreads).
  A card: a round badge with a line icon (`ui_icons.gd`; **placeholder** until places get drawn
  icons), the name (one or two lines, sized to fit), "12 of 28" and a small bar.
- **Known words** (merged with main's LEARN-04, 25 Nov 2026): a found sticker whose word the word
  memory knows (`word_memory.gd` `is_known()`) has a small daisy at its picture's corner
  (`known_badge()` / `show_known()`), and its word page adds "You know this word". This stands in
  for the plant stages until they are built; the old table's "N known" footer and drag-to-scroll
  list (C5) went with the table.
- **Chapters:** 4 stickers a page (2 × 2), two pages a spread (8); "‹ Places" back, the chapter's
  name and "5 of 83"; "1 / 11" at the bottom right.
- **Stickers:** found = white sticker with the word picture (`word_pictures.gd`) and the foreign
  word, a ★ pin when saved; a found word without a picture shows the word large on the sticker
  (until drawn icons). Not found = a cream-deep slot with the picture as a flat grey shape
  (a canvas shader keeps only its outline) and a big "?"; no picture = just "?". A tap flips the
  sticker (a squash-and-back) to the native word; a second tap opens the word page; flipping
  another turns the first back. Holding L shows every found sticker's native word.
- **Word page:** the left page holds the big picture in a white frame (or the word on it); the
  right page the word (pinyin under Chinese), translation, speaker (when spoken words are on and
  the word has a clip), ★ (saves at once, as the word card's star) and **Details**; under them
  **Found in**: one pill per place (Around town first for its words) that opens that chapter;
  for a word only games find (`from_games`) the heading reads **Found in a game at**. The
  picture is drawn at 256 px for this page (`word_pictures.gd` `BIG`; the 128 px sticker
  picture stands in while it draws). The right side scrolls (drag or bar) when it is taller than
  the page: Details on a landscape phone, or a word many games test.
  Details swaps Found in for today's Right / Wrong / Translated tiles, the per-game table and its
  note (the old detail view, without the Studied tile). The page arrows step through the
  chapter's found words ("2 / 5").
- **Keys:** ← → and Page Up / Page Down turn the spread (on the word page: the next found word);
  W A S D still close the journal. The footer names these keys and Hold L only with keyboard play
  (the HUD's key-hint switch: a touch hides them, a key press shows them again).
- **Search:** the header field, both languages, accents ignored. Results are a chapter
  ("Search: “bread”"); a word not found shows the silhouette, "?" and its first place's name,
  never its word. Clearing the field returns to where the player was.
- **★ Pocket:** the header button or the last contents card: the saved words as stickers
  (found or not), "Words: 2"; empty: how to save a word.

Working rules settled while building (25 Nov 2026; change them here if the user disagrees):

- **Around town is exclusive:** a word in 4 or more places is only in Around town, and only
  counts there; a word in 2–3 places is in each of those chapters and counts in each.
- **Sticker order** in a chapter: by the word's tier in the language learned (starter words on
  the first spread), then by word key, so a sticker keeps its slot when the player changes
  languages. (The foreign text would sort every "el …" before every "la …".)
- **"Not visited yet"** greys a place card while none of its words is found: there is no visit
  record, and the design changes no save.
- **A word not found has no word page:** a tap flips its sticker to "Not found yet".
- **No tab row yet:** Places is the only tab until Topics is built; the last-used-tab memory
  comes with it.
- **Found** = in the studied list or in the practice log of the language learned (see point 1).
- **Wider album on wide, short windows:** the journal window may use up to 1.5 × the
  height-led factor in width (a phone held sideways gets 765 px of 844 instead of 510); sizes
  keep the usual factor `min(h/800, w/1100)`, with floors for a phone: buttons (arrows, Back,
  Pocket, search, speaker, ★, Details, place pills, ✕) at least 44 px high and text at least
  11 px (`TAP`, `MIN_TEXT`).

Not built yet (in the order above): drawn icons, plant stages, Find it / Find one, fly-to-book,
place stamps, the review round and Practise, the Topics tab and shelves, example sentences,
sections by room in long chapters (the airport has 90 words: 12 spreads).

## Still open (ask the user when building)

- Shelf lists and the chapter names above.
- The review's name and results title (a garden word such as "Water my words" fits the plants).
- Whether using a vehicle or a bed should count as finding its word.
- Sections inside long place chapters, once the room names are checked.
- Place icons on the contents cards (line icons today, see [Places tab](#places-tab)).
