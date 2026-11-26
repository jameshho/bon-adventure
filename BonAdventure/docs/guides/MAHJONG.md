# Hong Kong mahjong with Mei

Game name (user, 10 Nov 2026; [all names](MINIGAMES.md#minigame-index)): **Mahjong Club** · *Club de mahjong* · 雀友會.

A table of Hong Kong mahjong in the front yard of the home: the player against three plush NPCs.
Built 9 Nov 2026 at the user's request. This guide is the design record and the ownership map.
For the minigame table and the shared systems, see [MINIGAMES.md](MINIGAMES.md#building-a-minigame).

## User decisions (9 Nov 2026)

- **Place.** The table stands in front of the house *for now*. Its centre is at town (-3.6, 0, 51.0),
  west of the entry path and north of the front door, near the spawn point. Moving it later means
  changing `MAHJONG_CENTER` in `scripts/buildings/home.gd` through a new step.
- **Players.** Four plush NPCs sit at the table. The player talks to one of them (Mei, the host).
  When a game starts she gets up and stands beside the table, and the player takes her chair.
  The game is the player against the other three.
- **Modes.** Mei asks for a mode after Yes: **at least 3 fan to win**, or **any fan** (a 0-fan
  "chicken hand" counts). The minimum applies to every player.
- **Length.** One hand per game, then Play again (same mode) or Leave.
  From the minigame picker (▶) mahjong has no rounds either (user, 15 Nov 2026: "it shouldn't be a
  round setting to it, so I can keep playing"): `game_launcher.gd` lists it in `ENDLESS` and sets no
  number of hands, so the result card always offers Play again.
- **Tiles.** 136 tiles, no flowers. None of the flower bonuses apply, and neither does "no flowers +1".
- **View.** The camera looks down on the real 3D table. The player's own hand is drawn as large
  clickable tiles along the bottom of the screen.
  - **Sizes (16 Nov 2026, user).** The hand bar's tiles are 30 % larger (`HAND_GROWTH` in
    `mahjong_panel.gd`; smaller only when the bar would not fit the window's width), the status
    card at the top left is 50 % larger (`INFO_GROWTH`: text, small tiles, buttons and icons) and
    the centre counter is 30 % larger (`COUNTER_GROWTH` in `mahjong_view.gd`). The status card's
    icons and margins scale with the window like its text (before, its icons had fixed pixel
    sizes), and the card is scaled down to at most 19 % of the screen's height (`INFO_MAX_HEIGHT`),
    so on a phone (844×390) it stays clear of the far discard row (user: "fit on phone").
    *Superseded 24 Nov 2026 by the UI polish below (status card about 25 % smaller).*
  - **UI polish (24 Nov 2026, user: more cohesive, less cluttered, same look and gameplay).**
    One look for every part of `mahjong_panel.gd`: thin 3 px outlines (`LINE`), light shadows
    (`SOFT_SHADOW`), corner radii 20 for cards and 16 for buttons, gentle motion (a small lift
    under the mouse, a squash when pressed, the call buttons fading in). Checked by
    [`mahjong-ui-polish-20261124/verify.gd`](../evidence/mahjong-ui-polish-20261124/) at
    1280×800 and 844×390.
    - **Status card** (top left) about 25 % smaller: 10 % of the screen's height on a laptop,
      14 % on a phone (`INFO_HEIGHT_LAPTOP`, `INFO_HEIGHT_PHONE`; it was up to 19 %). The book,
      ★ and leave buttons are small cream rounded squares with a thin outline (no thick round
      rims or heavy shadows); `INFO_GROWTH` 1.1, `INFO_TEXT_GROWTH` 1.45.
    - **Pull tab** instead of the round ▾ button: see "Hiding the hand" below.
    - **Call buttons**: Pung, Kong and Chow soft pastel green with a green outline and green
      words (the primary choice), their tiles in a light well of their own at the right; Pass
      and Keep playing cream with a pale outline (secondary); Mahjong! stays gold with red words
      and its pulse (the main choice) in the same shape.
    - **Reverted 25 Nov 2026 (user):** the opponents' nameplates and the cream centre counter
      plaque from the same polish were removed; the counter is the dark console again (30 %
      larger, `COUNTER_GROWTH` 1.3) and there are no nameplates (see git history, `11fc0121`).
  - **Top of the screen clear for Awoo (16 Nov 2026, user: "make the top status bar easy to read
    but not block awoo's face").** The status bar is split in two:
    - the status card (top left) keeps the mode, your wind, the book and the ★;
    - a corner card (`corner_card`) holds translate and leave, ending left of the HUD's EN and
      gear (`corner_limit`, set by the session).
    - Both are scaled to stay out of a band `FACE_CLEAR` (0.23) × the screen's height to each
      side of the centre, where Awoo's face is on any window (the camera keeps its vertical FOV).
    - **EN (23 Nov 2026, user).** While the HUD's EN is held the panel shows only the native text
      (`_text()`, never "foreign / native"), and every text-sized part (status lines, call and
      result buttons) keeps the width of its widest language (`_hold_width()`), so the status
      card's scale, and with it the book, ★ and leave buttons, no longer change on EN.
    - Where there is room (a phone) the status card grows up to `INFO_MAX_GROW` (1.4), still
      within `INFO_MAX_HEIGHT`. Its two lines are drawn larger than its buttons
      (`INFO_TEXT_GROWTH` 1.85), so on a phone they are about 17 px instead of 14.
    - Mei, standing beside the table, is out of the game camera's view, so she was not moved.
  - **Discards (16 Nov 2026, user: "Pinwheel (B)").** Discards are 30 % larger than the
    exposed sets (`DISCARD_GROW` 1.3 in `mahjong_view.gd`), still six to a row and two rows
    before stacking. Each pile slides 0.175 to its owner's left (`DISCARD_PINWHEEL`), so the
    four lock together around the counter like a windmill. Their outer edge (0.561) stays
    against the walls. The user chose this over centred rows of five at 1.1×, knowing it
    brings back the off-centre piles they had moved away from on 9 Nov.
  - **Camera (16 Nov 2026, user: "I still want to be able to see the face of the NPC sitting
    across me").** `CAMERA_AT` (0, 2.5, 1.7), `CAMERA_LOOK` (0, 1.0, -0.2), FOV 50 in
    `mahjong_session.gd`, ignoring the status bar (moved off his face the same day, below). With the
    pinwheel discards the weakest pile's tiles are about 15 px and the average about 20 px
    across their shorter side on a phone (centred six-tile rows: 12.9 / 14.7 px). First tried
    with the old discards: (0, 3.0, 2.0) / (0, 1.0, -0.2), FOV 44.
    - Picked by a search that projected the real discard piles and Awoo's eyes at 844×390
      (phone landscape): his eyes at least 10 px below the top edge, two full rows of every pile
      above the hand bar, and the largest shorter on-screen tile side.
    - The trade-off on a phone: the side piles' tiles are about 12.5 px across against about 21 px
      at the camera below (face off screen), and 10.5 px on 9 Nov. Requiring his whole face
      (eyes 45 px down) left about 11 px.
    - Earlier the same day (user: "tilt the angle slightly higher"): (0, 3.35, 0.95) /
      (0, 1.0, 0.1), FOV 38, with the player's own discard row wholly above the larger hand bar
      and Awoo's face off screen.
    - 15 Nov 2026 (user): (0, 3.1, 1.3) / (0, 1.0, 0.05), FOV 38.
    - The user asked to zoom in because the tiles were hard to read on a phone, and does not
      need to see their own tiles on the table (the hand bar shows the hand). The discard piles
      fill the space between the status bar and the hand bar, with tiles about 1.5× larger than
      before.
    - The player's own wall, standing hand and exposed sets are under or below the hand bar.
      The NPCs show mostly as shoulders at the screen edges; Awoo's exposed sets show top right.
    - Chosen from renders at 844×390 (phone landscape), 1280×800 and 1024×768.
    - Until 15 Nov 2026: (0, 2.8, 2.25) / (0, 1.08, -0.12), FOV 45 (9 Nov 2026, user: "slightly
      closer, a little higher and slightly zoomed in"), which showed Awoo's face and the
      player's exposed sets above the hand bar.
    - While seated, the sun moves only about every 30 s and slides over 1 s
      (`SUN_STEP_SECONDS`, `day_night.set_sun_steps()`), so shadows do not tick during play.
      Leaving restores the town's steps.
    - The game hides the HUD day clock (it sat over the old message line) with the minimap.
- **Numbers.** Every suit tile shows its number as a large digit in a navy badge in the top-left
  corner. Wind tiles show their letter in the language being learned (Spanish E S O N,
  English E S W N, Chinese 東南西北).
- **Loading.** The rules, NPC play, camera and panel run only while the player sits at the
  table. The table, chairs, the four seated NPCs and the tiles are always there.
  - **Changed 9 Nov 2026 (user):** before anyone sits, the table shows a game in progress. This
    fixed game is `data/mahjong.json` `preset`, laid out from the user's screenshot:
    - Bao dealt. Kiko has a pung of white dragons, and Mei a 2-3-4 bamboo chow.
    - Every player has discards.
    - The far wall is full and Kiko's is partly used.

    Sitting down deals a **fresh hand**; leaving puts the preset back. Keeping the tiles costs one
    136-tile pool (three shared meshes) and one 864×512 face atlas, made when the town loads.
    The tiles are made one frame after setup (`call_deferred`), **after** Main's render trim
    (`scripts/world/render_culling.gd`). That pass merges every still mesh into frozen static
    batches. Tiles made before it were copied there and stayed drawn at the preset places under
    the real game (found 9 Nov 2026; `play.gd` now checks that no tile is batched).
- **Tile look (9 Nov 2026, user).** Rows read as separate tiles, not one bar:
  - Tiles are a little narrower than their spacing. The gaps were cut by 30 % after the first
    look: 4.9 % of the width, 2.8 % of the length.
  - Each face has a darker rim, and the sides are a shade darker.
  - **Size and contrast (user, 9 Nov 2026).** The table tiles are 10 % larger than first built:
    0.0803 x 0.0583 x 0.11, up from 0.073 x 0.053 x 0.1. The walls, hands and sets moved out
    to fit (`WALL_R` 0.745, `HAND_R` 0.85, `MELD_R` 0.86).
    - **Bigger face-up tiles (user, 15 Nov 2026).** "Make the mahjongs on the table at least 50 %
      bigger, as it is hard to see them on a phone screen"; told that 1.5x does not fit the felt
      (a wall of 17 stacks would be wider than the table), the user chose "increase it to a point
      that would fit" with "the face up tile slightly bigger than the face down tiles". Face-up
      tiles (discards, exposed sets) are now 1.2x the 9 Nov size (0.0964 x 0.07 x 0.132,
      `UP_SCALE` over the face-down size); face-down ones (walls, standing hands, the hands laid
      open at the end) 0.95x (0.0763 x 0.0554 x 0.1045). That is the most that fits: the wall
      corners need `WALL_R - TL/2 >= 8.5 TW`, the sets lie between the wall and the rim (0.92), and
      the discards inside the wall. Discard piles hold two rows of six (was three); later discards
      lie on top of the first rows. `WALL_R` 0.711, `MELD_R` 0.832, `ACROSS_WALL_R` 0.541 (about
      87 % of Awoo's sets show), side walls 12 cm nearer the player, `DISCARD_R` 0.30.
    - Their faces are painted with stronger colour than the panel's (`FACE_PUNCH`: saturation
      x1.4, strokes darkened by a 1.35 power curve while the ivory stays ivory).
    - **Brightness cap (user: "too bright to see clearly" in the midday sun).** Every tile
      surface is drawn at 75 % of its colour (0.8 at first; the user chose 0.75) (`TILE_BRIGHTNESS`), so the noon sun and the ACES
      tone mapping no longer bleach faces to white and symbols to pastel.
    - The faces glow only as the daylight fades: none in full sun, up to `FACE_GLOW` 0.3 at
      night. `MahjongSession._follow_daylight()` passes the sun's energy to `set_daylight()`.
    - The backs are a brighter green than the felt (`BACK_3D`).
  - The 8 bamboo is traced from the user's reference. In each half, two upright outer sticks are
    joined to the middle by two short slanted sticks: a "W" (|/\|) over an "M" (|\/|).
- **Hand bar (9 Nov 2026, user).**
  - It has one place per concealed tile (13, less 3 for each exposed set), a gap, then a place for
    the drawn tile that stays even when empty.
  - It is centred, and shrinks only when a set is exposed. Drawing or discarding never moves it.
  - Right after a claim, the extra tile sits in the drawn place.
  - The slots are reused between turns (not rebuilt), so nothing flickers.
- **Moves on the table (9 Nov 2026, user: "realistic, not random").** Every 3D tile keeps its
  identity between turns and slides (0.175 s; 0.28 s until the user asked for 60 % faster, 9 Nov 2026) to its new place:
  - A discard slides from its place in the hand to the pile; the rest of the hand closes up just
    after.
  - The next player's draw comes from the wall once the discard has landed (0.35 s later), and
    sits apart at the right end of their hand until they discard.
  - Each concealed hand is kept to its owner's right with a fixed place for the drawn tile, so a
    draw or discard never shifts the whole row.
  - A claimed tile slides from the pile into the meld.
  - The player's own hand also stands on the table, so their draw and discard move like the
    NPCs'.
  - A new deal and the preset appear at once (`mahjong_view.gd` `layout(..., instant)`).
- **Sitting down (9 Nov 2026, user).** After the mode is chosen, the steps happen in the town,
  before any fade:
  1. Mei gets up beside her chair and steps back to her place behind the player's left.
  2. The player sits down in her chair.
  3. Only then does the screen fade into the game.
- **Status card and call buttons (9 Nov 2026, user).** The "your wind" and "round wind" lines
  show their wind tile. Tiles on the call buttons keep a tile's shape (wider and shorter than
  before) instead of stretching to the button's height.

## Rules

The scoring follows the user's "Hong Kong Mahjong — common winning hands" sheet.
The values live in `data/mahjong.json`:

| Hand | Fan |
| --- | --- |
| All Chows (four chows and a pair) | 1 |
| All Pungs | 3 |
| Mixed One Suit (one suit plus honors) | 3 |
| Pure One Suit | 7 |
| Small Three Dragons | 5 (replaces the dragon pungs) |
| Big Three Dragons | 8 |
| Small Four Winds | 6 (replaces the wind bonuses) |
| Big Four Winds, All Honors, Thirteen Orphans, Four Kongs | limit = 13 |
| Seven Pairs (house rule; seven *distinct* pairs) | limit = 13 (user, 9 Nov 2026; 4 fan before) |
| Prevailing wind pung (East) / seat wind pung | +1 each; an East player's East pung gets +2 |
| Self-drawn | +1 |
| **Dragon pung** (any dragon outside the three-dragon hands) | +1. Standard HK scoring, **not on the user's sheet**; set `dragon_pung` to 0 to drop it |

Other rules:

- **Fan.** A hand's fan is the best of all the ways to split it into sets. No hand scores more
  than the limit.
- **Seats and turns.** The dealer is random and sits East. The round wind is East. Play passes to
  the player on the right.
- **Claims.** Only the next player may chow a discard. Anyone may pung, kong or win on it. A win
  beats a pung or kong, which beats a chow. If two players win on the same tile, the first in turn
  order after the discarder takes it.
- **Kongs.** A kong (from a discard, four in hand, or adding to an exposed pung) draws a
  replacement from the back of the wall.
- **Self-drawn win.** It is not possible straight after a claim.
- **Mahjong after a pung or chow (user, 23 Nov 2026).** A player who pungs (or chows) the tile
  that completes their hand still gets the Mahjong! button on their turn, beside discarding
  (Keep playing). It scores as a win on that discard, paid by the discarder
  (`mahjong_game.gd` `claimed_from`).
- **End of the hand.** An empty wall is a draw. There is no dead wall and no robbing a kong.

The NPC players (`mahjong_ai.gd`) are simple:

- **Any-fan mode.** They discard by shanten (distance from a ready hand).
- **3-fan mode.** Each turn they pick the closest plan (one suit plus honors, all pungs, or seven
  pairs) and play towards it.

Simulated results with four NPC players:

| Mode | NPC wins | Note |
| --- | --- | --- |
| 3 fan | 38 of 80 hands | The rest are draws (P3). |
| Any fan | 59 of 60 hands | |
| Time per decision | about 2 ms average, under 60 ms worst | |

## Flow

1. **Talking to Mei.** Click or press E on Mei (cat, north chair, gold "!"). She greets the player;
   Yes leads to "Do you know how to play mahjong?" (user, 9 Nov 2026). **Yes, I know how** leads
   to the mode question with **Mínimo 3 fan** and **Cualquier fan** buttons; **No, teach me**
   asks which lesson ([Lessons](#lessons)). When this profile left a game unfinished, Yes first
   asks **"Shall we carry on with our last game? You have +N points."** ([Memory](#memory)).
2. **Sitting down.** Mei gets up and steps to the player's left-back corner, and the player sits in
   her chair (seen in the town), then a fade. The player's model, the minimap, the controls help and the walk line are hidden.
   So is the whole bottom-right button cluster (journal, map, ▶ games, help; user, 10 Nov 2026):
   `vocabulary_hud.gd` `cluster_off`, set and cleared by `mahjong_session.gd`. The gear stays, and the
   M, J and F1 keys still work. The
   game camera and the panel open, and the player is locked: the `true` locks flag of its `PANELS` entry in
   `scripts/core/minigame_wiring.gd`.
3. **Your turn.** The status card (top left) shows the mode and your wind (user, 10 Nov 2026:
   reorganized), with the lessons book and the ★ scoreboard button (it shows your points this
   visit); translate and leave sit at the top right (16 Nov 2026). The ★ opens a scoreboard card under the status card: each player's face
   (plush portrait, `plush_portraits.gd`; the player is BonBon, the pig) with their wind tile as a
   corner badge, name and points; ★ or its round ✕ (top right) closes it, and play goes on
   meanwhile. Since 11 Nov 2026 (user) neither scoreboard has a "Points this visit" heading: the
   faces and numbers say it.
   The tiles left and the round wind are on a dark console in the middle of the table
   (`mahjong_view.gd` `show_counter()`): the round wind as a face-up tile, the number and the word
   "fichas" in the language being learned, tilted toward the player's seat.
   There is no message line over the table at all (user, 9 Nov 2026: "remove this sentence and everything shown in this box"): no "Awoo's turn…", no claim prompt, no "too few fan" note; the buttons and call words say what happens.
   - **Discarding.** Click a tile to discard it. The tile just drawn sits apart on the right.
   - **Hiding the hand (user, 24 Nov 2026).** A small cream pull tab centred on the hand tray's top
     edge, with a dark teal ▾, slides the tray down off the screen (0.22 s, `TRAY_SLIDE`), so the
     player can see their own tiles on the table under it (exposed sets, standing hand, nearest
     discards); the tab stays at the bottom edge with ▴ to slide it back. The tab's touch area
     (150 × 50 × scale, at least 0.6) is larger than the drawn tab, and the call buttons sit above
     it (UI polish, same day; it was a round button above the bar's right end). The start of
     the player's next turn (a draw or a claim) and a new hand bring it back by themselves; call
     buttons still show while it is hidden (`mahjong_panel.gd` `hand_toggle`, `set_hand_hidden()`).
     When anyone calls Mahjong the tray tucks itself away so the winning hand on the table shows
     (user, 25 Nov 2026: "when mahjong, auto collapse my hand"; `mahjong_session.gd`
     `_on_game_changed()`); the next hand brings it back.
   - **Sound and music (user, 25 Nov 2026).** The tiles washed at the deal, your draws, every
     discard, the calls spoken in Cantonese (碰 / 上 / 槓 / 食, for every language) and a tune
     when you win; the game's own energetic `mahjong` track. Details:
     [Mahjong sounds](VOICE.md#sound-effects-25-nov-2026).
   - **Playing ahead (user, 9 Nov 2026).** While another player plays, double-click (or tap twice)
     a hand tile to mark it: it lifts with a pink border and a ▶ badge. On the player's next turn
     it is discarded automatically after 0.5 s (`pace.auto_discard`), unless a **Mahjong!** or
     **Kong** button shows; then the player chooses, and the mark stays until they discard.
     - A single click on someone else's turn does nothing; a second double-click unmarks.
     - Pung, chow, kong or Mahjong! on a discard waits for the player's choice. Claiming clears
       the mark (the hand changed); Pass keeps it.
     - Clicking twice on the player's own turn discards once and marks nothing.
   - **Winning is the player's click and choice (user, 9 Nov 2026).** A winning hand is never
     declared for the player.
     - A big pulsing golden **Mahjong!** button appears above the hand, with what the hand is
       worth under it ("Your hand is worth 2 fan").
     - On a draw, **Keep playing** plays on for a bigger hand: the player discards as usual. A
       kong's replacement tile can bring the offer back.
     - On another player's discard, **Pass** does the same.
     - In 3-fan mode a complete hand under 3 fan shows no button (and, since 9 Nov 2026, no note).
   - **Kongs.** One Kong button for each possible kong.
4. **Claims.** After another player's discard, the call buttons appear when the player can use it:
   the big Mahjong! button (as above), Kong, Pung, one Chow button per way (showing its three
   tiles), and Pass.
5. **Calls (9 Nov 2026, user: "a word pop-up and a slight delay … more of a rhythm").** Every call
   (also the player's own) pops up as a word over the table near the caller's edge, centred
   on their seat.
   - **Always English** ("Pung!", "Chow!", "Kong!", "Mahjong!"), whatever the language settings
     (user, 9 Nov 2026). A self-drawn win also pops up as "Mahjong!".
   - White letters with a pastel outline per call: pink pung, blue chow, lavender kong, orange
     Mahjong!
   - The word grows in, settles, stays and fades in 0.9 s (`pace.call_seconds`, 0.15 s fade);
     it was 1.6 s with a 0.3 s fade until the user found both too long. It is the same size on
     screen at every seat.
   - Play then pauses 1.0 s longer than usual (`pace.call_hold`), so the claimed tile lands before
     the next move; a win shows its word before the result card.
   - The result card and a new hand clear the words.
6. **The table.** Walls are face down, two high. Awoo's sets were hidden behind his wall
   (user, 9 Nov 2026), so his wall stands 0.57 from the centre instead of 0.745
   (`ACROSS_WALL_R`, 3 mm clear of his discard pile) and the camera sees about 83 % of each of
   his flat sets above it. Both side walls sit 13 cm nearer the player so they clear his wall's
   corners (13 cm is the most before they meet the player's hand; since 15 Nov 2026, with the
   bigger face-up tiles, 0.541 and 12 cm: see [Bigger face-up tiles](#user-decisions-9-nov-2026)). All sets lie flat (user, same
   day: standing ones looked "unnatural"). NPC hands stand toward their owners. Exposed melds
   lie face up at each seat's left (user, 9 Nov 2026), the first set at the far left; a concealed kong shows its two end tiles face down. Discards
   lie in a square of four piles, each centred on its seat, six to a row (user, 9 Nov 2026:
   "more left right centered"; until then a pinwheel of eight to a row, each pile 0.1 to its
   seat's left).
   - The whole square sits 8.5 cm closer to the player (user, 9 Nov 2026: "slightly closer to
     me but still somewhat centred"; 8 cm, then 8.5 to clear Awoo's nearer wall).
   - Three rows hold 18 tiles; any later discards lie on top of the first rows instead of
     reaching the wall.
   - A gold marker shows the last discard while it can be claimed.
7. **The result.** At the end every hand is laid face up. The result card shows the winner, where
   the tile came from, each scoring hand with its fan, and the total, with **Jugar otra vez** and
   **Salir** buttons.
   - **Visit scoreboard (user, 10 Nov 2026).** Every won hand pays by the [points rule](#lessons)
     (`mahjong_rules.gd` `points_for()` / `balances()`, shared with the lessons). Under the fan total
     the card shows each player's face, name and total and, under it, what that hand changed
     (green / red); the ★ scoreboard card closes while the result shows. Totals carry over Play again and the mode change, and are cleared on sitting
     down and on leaving (`_visit_hands` in `mahjong_session.gd`). A draw pays nothing. Since
     23 Nov 2026 they are also saved with the game ([Memory](#memory)).
8. **Leaving.** ✕, Esc, or Salir. During a hand the shared leave question asks first. A fade, then
   the player stands, Mei sits again, and the tiles and camera are freed. Mei says goodbye.

Nothing is tracked by the practice log (no single word is tested) or paid (no coins exist).

## Memory

User, 23 Nov 2026: a player can come back to an unfinished game, with its hand and scores.

- **What is saved.** The profile's `mahjong.json` (`save_store.gd` `PROFILE_FILES`):
  `{"mode": min fan, "hands": the visit's won hands (the scoreboard), "game": the hand in play
  (mahjong_game.gd to_save()) or null}`. `mahjong_session.gd` `save_now()` writes it on leaving
  (also a language change), after every finished hand, and when the app closes, loses focus or the
  web page is hidden (`web_resume.gd`). The path is fixed when the session is set up, so a profile
  switch saves to the profile that played.
- **Asking.** With a hand in play or at least one won hand saved, Mei's first question after Yes
  is "Shall we carry on with our last game? You have +N points." (`mahjong.continue_ask`), instead
  of the lesson and mode questions. **Yes, continue** sits down in the saved mode with the saved
  scores, at the same hand tile for tile (a new hand when the last one had ended). **No, a new
  game** goes on to the lesson and mode questions as before; the old save stays until the new game
  is saved over it (on leaving or after a hand), so walking away keeps it.
- **Restoring a hand.** `mahjong_game.gd` `restore()` turns the JSON numbers back into ints, asks
  `claim_options()` again for the seats still to answer a discard and settles a claim everyone had
  answered. Not kept: a tile marked to play ahead, a declined Mahjong! (the button shows again),
  and a hand that ended in the moment before its result card showed.
- The test launcher's games are saved the same way.

## Lessons

Built 9 Nov 2026 from the user-approved script
[LESSON_SCRIPT.md](../evidence/mahjong-20261109/LESSON_SCRIPT.md) ("include some images and make it look
cute"). There are two lessons, **Basics** and **Scoring**, of three pages each:

| Lesson | Page | Picture |
| --- | --- | --- |
| Basics | The tiles | the three suits 1-9 and the honours, a row each with its name |
| Basics | Four sets and a pair | a winning hand in five labelled groups; draw one, discard one |
| Basics | Chow, pung and kong | each set in its call colour, with a small table showing who you may take the tile from |
| Scoring | What is a fan? | the scoring card: mini tiles, the hand's name and its fan (`data/mahjong.json` `fan`) |
| Scoring | Adding up your fan | two worked hands: coloured bars under the parts that score, and the sum |
| Scoring | Points and balances | everyone at 0, the points table, two example hands, the balances after |

- **Where.** After Yes, Mei asks "Do you know how to play mahjong?" (user, 9 Nov 2026):
  - **Yes, I know how** goes on to the mode question.
  - **No, teach me**: "Sure! What would you like to learn?" with **The basics** and **Scoring**.
  - Closing a lesson: "Would you like another lesson, or shall we play?" with The basics,
    Scoring and **Let's play!** (the mode question). During a game the **book** button on the status card opens the lessons over the
  table, and the game waits until they close (`mahjong_session.gd` `_process`).
- **Look.** A cream card with a pink border, a mint picture area with sparkles, Mei's portrait
  (`plush_portraits.gd`) above a speech bubble with her text, pill tabs and Back / Next / Got it!
  buttons, and tile-shaped page dots. The minimap, clock and help are hidden while it is open.
- **Text.** Mei's paragraphs mark **bold** words in `data/phrases.json`; pinyin shows under
  Chinese, and the translate bubble adds the translation in green italics. The paragraphs shrink
  to fit the bubble, so no page scrolls.
- **Points (user, 9 Nov 2026).** `data/mahjong.json` `points` holds the example table (1 fan → 2,
  2 → 4, 3 → 8, 4 → 16, 5 → 24, 6 → 32, 7 → 48, 8 → 64, 9 → 96, 10 → 128). A hand under 1 fan
  pays as 1 fan. The discarder pays double: losing a 3-fan hand on your discard costs 16. On a
  self-drawn win each other player pays once, so the smallest win is 6 self-drawn (2 × 3) or 4
  on a discard (2 × 2). Since 10 Nov 2026 the game's visit scoreboard pays by the same rule.
- **Data.** `data/mahjong.json` `lessons` lists each page's title, text ids and picture; the
  panel `scripts/ui/mahjong_lesson_panel.gd` (`Main.mahjong_lessons`) draws them and knows no
  rules. Esc and ✕ close it (`PANELS`); it locks the player (`PANELS` locks flag).

## Ownership

| What | Where |
| --- | --- |
| **Table and chairs** (plush scale like the oak dining table): baked steps `mahjong_table`, `mahjong_chair_back` (Awoo's chair 0.2 further back, her fur had touched the table) | `scripts/buildings/home.gd` (`MAHJONG_*` constants), `scenes/town/home.scn` (`RelocatedSites__Home/MahjongTable`) |
| Table top | word *table*; top 1.0, 2.0 square, green felt and rim |
| Chairs | word *chair*; seats 0.55, 1.75 from the centre, meta `mahjong_seat` 0-3. Seat 0 is the player's (north); 1-3 follow the order of play (+X, south, -X) |
| **Rules:** tiles, complete hands, fan scoring, shanten | `scripts/learning/mahjong_rules.gd`, `data/mahjong.json` |
| **One hand:** wall, turns, claims, result; no nodes | `scripts/learning/mahjong_game.gd` |
| **NPC players** | `scripts/learning/mahjong_ai.gd` |
| **The 3D tiles:** pool of 136, face atlas in a SubViewport, layout | `scripts/learning/mahjong_view.gd` |
| Call words over the table (reusable for any game) | `scripts/ui/pop_word_3d.gd` (`PopWord3D`) |
| The players' signs of life (reusable): a blink now and then, an occasional hop, body shake, bow or lean | `scripts/characters/plush_life.gd` (`PlushLife`, `session.life`) |
| **Tile faces in code** (shared by the panel and the atlas) | `scripts/ui/mahjong_tiles.gd` |
| **The screen:** hand, call buttons, status, result | `scripts/ui/mahjong_panel.gd` (`Main.mahjong_panel`) |
| **Lessons:** pages, pictures, points table | `scripts/ui/mahjong_lesson_panel.gd` (`Main.mahjong_lessons`), `data/mahjong.json` `lessons` and `points` |
| **Session:** seated NPCs, host, mode, sitting, camera, pacing, call words, leaving | `scripts/learning/mahjong_session.gd` (`MahjongSession` under Main) |
| Wiring, Esc, player lock | `scripts/core/minigame_wiring.gd` |
| Offers | `data/activities.json` `mahjong_mei` (chance 1.0, no progress bar) |
| Text: names Mei, Bao, Awoo, Kiko; hand names; calls; buttons; lessons (`lesson_*`, `l1p1_*` … `l_*`) | `data/phrases.json` group `mahjong`, plus `games.mahjong_mei` |

The players are runtime plush figures (`house_characters.gd` `seated()`), not saved in the scene.
They come alive only once in a while (user, 9 Nov 2026: the suspect ID game's blinking and
movement, "only once in a while so it's not annoying"): each blinks every 4-10 s, and every
10-20 s one of them hops, shakes, bows or leans (`plush_life.gd`). Since 13 Nov 2026 these move
the whole figure: the earlier head moves turned the `Head` node, which is only the face and
pivots at the feet, so the face slid off the body (user: "looks pretty bad";
[components guide](COMPONENTS.md#plush-characters)). Nothing moves all
the time; the eye squash and moves are the lineup's (`police_detective_session.gd`).


| Seat | Name | Plush | Role |
| --- | --- | --- | --- |
| 0 | Mei | cat | The host; she gets up when the player plays |
| 1 | Bao | bear | NPC player |
| 2 | Awoo | samoyed | NPC player. Named Lin until 9 Nov 2026; the home's dining-table samoyed, formerly Awoo, is now **Sam** (`data/npcs.json`, id `awoo` unchanged) |
| 3 | Kiko | golden | NPC player |

The pacing (`data/mahjong.json` `pace`) is 0.56 s for an NPC turn and 0.44 s after a discard
nobody can claim, plus 1.0 s after any call (`call_hold`). The NPC pauses and the tile slides
were made 60 % faster (1/1.6 of the time) on 9 Nov 2026 (user: "taking too much time"); the
call words and the pause after a call kept their timing.

## Verification (9 Nov 2026)

- `docs/evidence/mahjong-20261109/verify.gd` (`mahjong_logic`, no town) checks the rules and the NPC players:
  - every hand on the sheet and the bonuses score as in the table above;
  - incomplete hands score nothing, and shanten is right;
  - 60 hands per mode run with four NPC players: tiles are conserved, every winner has the mode's
    minimum fan, every hand ends, and decisions are timed.
- `docs/evidence/mahjong-20261109/play.gd` (`mahjong_table`) checks the table in the town:
  - the chairs and the four seated players;
  - talk, then mode, then sit: Mei stands, the player sits, the game camera is current, 136 tiles
    exist, the panel is open and the player is locked;
  - two hands in each mode, played through the session with the NPC logic standing in for the
    player's clicks, then the result card;
  - leaving: the player stands, Mei sits, and everything is freed;
  - signs of life: the four players have `PlushLife`, their eyes are not batched, a blink and a
    lean show and end at rest, and the next move is at most 20 s away;
  - playing ahead: real clicks on a hand tile during another turn (one click marks nothing, a
    double-click marks, another unmarks), the marked tile played on the player's turn or waiting
    when Mahjong! or Kong shows, and no mark from clicking twice on the player's own turn;
  - the lessons: Mei's question, both lessons page by page, the points rule and balances, the
    worked examples' fan by the real scoring, Chinese with pinyin, the book button in a game
    (the game waits), and closing.

  With graphics the same check saves `approach.png`, `mode.png`, `game.png`, `result.png` and
  the lesson pages (`lesson-1-1.png` … `lesson-2-3.png`, `lesson-translated.png`,
  `lesson-zh-*.png`, `lesson-in-game.png`) in
  that folder (rendered at 1280×800 with only the home loaded, `VT_FOCUS=home`).
- `docs/evidence/mahjong-memory-20261123/verify.gd` (`mahjong_memory`, 23 Nov 2026) checks the
  [memory](#memory): hands saved through JSON mid-turn and mid-claim restore exactly and play on to
  the same end; at the table, leave mid-hand, the continue question with the points, the same hand
  and scores back, a finished hand saved and continued as a new hand, and No, a new game. With
  graphics it saves `continue-ask.png` and `continued.png` (1280×800, `VT_FOCUS=home`).
- `docs/evidence/mahjong-hand-toggle-20261124/verify.gd` (`mahjong_hand_toggle`, 24 Nov 2026)
  checks the hide/show button: its place and size, hiding and showing, and the player's next turn
  bringing the hand back. With graphics it saves `hand-shown.png` and `hand-hidden.png`.
- Results are recorded in [FINAL_VERIFICATION.md](FINAL_VERIFICATION.md#mahjong-table--9-november-2026).

## Code review (9 Nov 2026, user request)

The parts, and whether each has one job:
- **Rules** `mahjong_rules.gd`, **game** `mahjong_game.gd` and **NPC play** `mahjong_ai.gd` use
  no nodes; they are static or `RefCounted`, driven by data (`data/mahjong.json`) and covered
  by `verify.gd` (17120 checks).
- **3D table** `mahjong_view.gd` and **screen** `mahjong_panel.gd` only draw what they are
  given and emit signals; they know no rules.
- **Session** `mahjong_session.gd` connects them, and reuses the shared host, zone, activity
  board, seating and character helpers.

Fixed in the review:
- **Kong bug.** After Keep playing, a kong's replacement tile that completed the hand did not
  bring the Mahjong! offer back.
- **Cancelled sitting.** The sitting sequence went on (seated the player, dealt) if a language
  change ended the game during its waits.
- **Reusable call word.** The pop-up call word is now `scripts/ui/pop_word_3d.gd` (listed in
  MINIGAMES.md).
- **Copied day-cycle numbers.** The tile glow asked for the noon sun energy copied from the
  day-cycle data; it now uses `day_night.daylight()`. The slow sun uses `DAY_MINUTES`, not 1440.
- **Day clock.** It is hidden by reference (`main.day_clock`), not by its script's file name.
- **Pool guard.** The view refuses more targets than its 136-tile pool, with an error, instead
  of crashing (only a broken game state can cause it).
- **Shared table helper (follow-up, user: "work on the two larger items").** The sitting
  choreography moved into `scripts/learning/minigame_table.gd`, shared by any seated table
  game:
  - Mei gets up, the player sits in her chair, the fade, the game camera, the hidden model and
    HUD, standing up again.
  - It sits the player with the seating controller's new `sit_at(node, stand_back)` instead of
    setting its internals.
  - A language change during the walk-up or the fade stops it cleanly.
- **HUD group.** HUD parts that would cover a game view are in one group
  (`vocabulary_hud.gd` `GAME_HIDDEN_GROUP`, `hide_for_game()`): the controls help, the place
  line, the walk line, the minimap and the day clock. A new HUD part joins the group instead of
  being added to a list in each game. Since 23 Nov 2026 any `hide_for_game()` reason also hides
  the corner buttons (`cluster_hidden()`: journal, ▶ games, passport), so they no longer show
  over Mei's lesson card before a game.
- **Smaller cleanups.**
  - The unused `layout()` parameter is gone.
  - Honour checks use `Rules.is_honor()` instead of the literal 27.
  - The session's and panel's constants are at the top.
  - The panel's three button builders share `_button()`.

## Open issues
- **Fixed (15 Nov 2026, user: "my hand stays the same on the mahjong table even though I play
  different cards").** In the app's staged loading (title → character → loading) the town's static
  render batching runs frames after the minigames are set up, so the deferred preset tiles were
  merged into frozen batches and the table kept drawing the preset over the live game. The tile
  view now carries meta `keep_own_draw` (`mahjong_view.gd` `build()`), which the batching skips
  however late it runs. `play.gd` loads `main.tscn` directly, so it never saw this.
- **P3** The points table stops at 10 fan while Mei's maximum is 13, so an 11–13 fan hand pays
  as 10 fan (128) on the visit scoreboard. Ask the user before extending it.

- **P3** In 3-fan mode about half the hands end in a draw (NPCs only). Stronger NPC planning
  (fan from honour pungs, defending against the player) is possible later.
- **P3** No sound yet (sound-ready: the calls are lines and events).
- **P3** No fan card on the game screen itself; the book button opens the scoring lesson's card.
- **P3** The table is placed "for now": the user may move it to another building later.
