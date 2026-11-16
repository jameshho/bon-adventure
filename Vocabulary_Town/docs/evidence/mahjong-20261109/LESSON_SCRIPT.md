# Mahjong lessons — script for review (9 Nov 2026)

**Status:** approved by the user on 9 Nov 2026, with the payment answers below, and built.
The in-game text is `data/phrases.json` (`mahjong.l1p1_title` … `mahjong.l_hand2`). The page
layout and pictures are `data/mahjong.json` `lessons` and `points`, and the panel is
`scripts/ui/mahjong_lesson_panel.gd` ([MAHJONG.md](../../guides/MAHJONG.md#lessons)). If this script and
the data differ, the data wins.

There are two lessons of three pages each. Each page has one large picture made of real tiles,
drawn with the same code as the game's tiles, and a short text beside it. In the game the text is
in the language being learned, with the usual translate button. The English below is the source
the Spanish and Chinese are translated from.

**Where the lessons appear**
- **Before playing.** *Superseded by the user's flow of 9 Nov 2026: "Do you know how to play
  mahjong?" Yes → the mode question; No → which lesson, the basics or scoring; after a lesson,
  another lesson or Let's play ([MAHJONG.md](../../guides/MAHJONG.md#lessons)).* The draft was: after
  "Yes, let's play", Mei asks: *"Do you know how to play?"*
  - **Teach me the basics**: opens lesson 1.
  - **Teach me scoring**: opens lesson 2.
  - **I know how**: goes to the mode question as now.

  Closing a lesson brings back the same question, so the player can read the other lesson or
  start the game.
- **During the game.** A **?** book icon on the status card (next to translate and leave) opens
  the lessons over the table. The game waits while they are open. The icon has two tabs (Basics,
  Scoring) and Back / Next arrows.

---

## Lesson 1 — The basics

### Page 1 · The tiles

**Picture:** three rows of tiles. Characters 1–9, dots 1–9 and bamboo 1–9, each row labelled with
its suit. Below them, a fourth row: the four winds and the three dragons.

> Mahjong is played with 136 tiles. Most of them belong to **three suits**, numbered 1 to 9:
> **characters**, **dots** and **bamboo**. The number is in the blue corner of every tile.
>
> There are also **honor tiles**: the four **winds** (East, South, West, North) and the three
> **dragons** (red, green and white). Honor tiles have no numbers.
>
> There are **four copies of every tile**. Four players sit around the table, and each one holds
> 13 tiles.

### Page 2 · The goal: four sets and a pair

**Picture:** one winning hand of 14 tiles, split into five groups with a label under each:
- 2-3-4 dots: *set*
- 6-6-6 bamboo: *set*
- 7-8-9 characters: *set*
- East-East-East: *set*
- red dragon, red dragon: *pair*

Below it, small arrows show *draw one → throw one away*.

> To win you need **14 tiles: four sets and one pair**. A **pair** is two identical tiles.
>
> On your turn you **draw** a tile from the wall, then **discard** one tile face up in front of
> you. You keep 13 tiles until the tile that completes your hand arrives.
>
> When your 14 tiles make four sets and a pair, call **"Mahjong!"** You can win with a tile you
> draw yourself, or with a tile another player has just thrown away.

### Page 3 · Chow, pung and kong

**Picture:** three examples side by side, each with its name and a small seat diagram showing
who you may take the tile from:
- **Chow:** 3-4-5 bamboo. The diagram shows only the player before you.
- **Pung:** 7-7-7 characters. The diagram shows any player.
- **Kong:** North ×4. The diagram shows any player, plus an extra tile drawn from the back of the
  wall.

> There are three kinds of set:
>
> - **Chow**: three tiles **in a row in the same suit**, like 3-4-5 bamboo. You can only take a
>   chow tile from the player **just before you**.
> - **Pung**: **three identical tiles**, like three 7 characters. You can take a pung tile from
>   **anyone**.
> - **Kong**: **four identical tiles**. A kong counts as one set, so you draw an extra tile to
>   make up for it.
>
> When you take another player's discard, you show the set face up on the table. Then it is your
> turn, and you discard. If two players want the same tile: **Mahjong** beats **pung or kong**,
> which beats **chow**. Honor tiles can never make a chow.

---

## Lesson 2 — Scoring

### Page 1 · What is a fan?

**Picture:** a scoring card. Each row has three or four mini-tiles, the hand's name and its fan:
- All chows · 1
- All pungs · 3
- Mixed one suit · 3
- Small three dragons · 5
- Small four winds · 6
- Pure one suit · 7
- Big three dragons · 8
- Dragon pung · +1
- Your seat wind or the round wind · +1
- Self-drawn · +1

> Every winning hand is worth **fan** (番), points for how special the hand is. A plain hand of
> mixed sets is worth 0 fan, and is called a **chicken hand**.
>
> Add up everything your hand has. Some hands are patterns, such as all pungs, or one suit with
> honors. Some are bonuses, such as a pung of dragons, a pung of your own wind or the round wind,
> or winning on a tile you drew yourself.
>
> Before you start, the players agree a **minimum**. At Mei's table you choose: **at least 3 fan**,
> or **any fan**.

### Page 2 · Adding up your fan

**Picture:** two worked examples, each a full hand with coloured brackets under the parts that
score, and the sum on the right.

1. **Mixed one suit.** Dots and honors only: 1-2-3 dots, 5-5-5 dots, 7-8-9 dots, red dragon ×3,
   pair of North. Won by self-draw.
   *Mixed one suit 3 + dragon pung 1 + self-drawn 1 = **5 fan***
2. **All pungs.** 2 characters ×3, 9 bamboo ×3, 4 dots ×3, East ×3, pair of 6 dots. You sit East,
   and the round wind is East.
   *All pungs 3 + seat wind 1 + round wind 1 = **5 fan***

> Count every part your hand earns, then add them together.
>
> Some hands are so rare that they are worth the **maximum** straight away, for example
> **thirteen orphans** (one of every 1, 9 and honor, plus one more) or **all honors**. At Mei's
> table, **seven pairs** (seven different pairs) is a house rule worth the maximum too.
>
> Players agree the maximum before they play. It is **usually 8 or 10 fan**; at Mei's table it is
> **13**. No hand can score more than the maximum.

### Page 3 · Points and balances

**Picture:**
- **Top:** four name plates (Mei, Bao, Awoo, Kiko), each showing **0**.
- **Middle:** a small table turning fan into points (an example table, starting at 1 fan; a
  hand under 1 fan pays as 1 fan):
  - 1 fan → 2
  - 2 → 4
  - 3 → 8
  - 4 → 16
  - 5 → 24
  - 6 → 32
  - 7 → 48
  - 8 → 64
  - 9 → 96
  - 10 → 128
- **Bottom:** the name plates after two hands, with arrows showing who paid whom.

> Every player starts the game with a **balance of 0**. When someone wins, the fan is turned into
> points using a table the players agree on. More fan means many more points. A hand with no fan
> pays like **1 fan**.
>
> - **Win on a discard:** the player who threw the winning tile **pays double**.
> - **Self-drawn win:** all three other players pay.
>
> For example, Bao wins with 3 fan on Kiko's discard: Kiko pays 2 × 8 = **16**. Then Awoo draws
> her own winning tile with 4 fan: Mei, Bao and Kiko each pay 16, so Awoo gets **48**. The
> balances always add up to 0.
>
> (Balances after the two hands: Mei −16, Bao 0, Awoo +48, Kiko −32. The smallest win pays 6 when
> self-drawn, 2 × 3, and 4 on a discard, 2 × 2.)
>
> At Mei's table we only count fan. Points and balances are for when you play with friends.

---

## The reviewer's answers (user, 9 Nov 2026)

1. **Payment rule.** The discarder pays **double**: losing a 3-fan hand on your discard costs 16.
   On a self-drawn win each of the other three pays the points once.
2. **Points table.** The table above is right, starting at 1 fan. The minimum payout is the 1-fan
   one: 6 in all from a self-draw (2 × 3), 4 from a discard.
3. **Dragon pung.** Yes, +1, matching the user's corrected scoring chart (the fan values in
   `data/mahjong.json`).
4. **Pictures.** Include pictures and make the lessons look cute.

Open: the table stops at 10 fan while Mei's maximum is 13 (only fan are counted in the game).
