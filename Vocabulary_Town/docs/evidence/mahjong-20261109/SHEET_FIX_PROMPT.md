# Prompt: fix the Hong Kong mahjong scoring sheet image (9 Nov 2026)

Give this prompt to an image-editing AI together with the original sheet image. It covers:
- the mistakes found in the review;
- Seven Pairs as a limit hand (user decision);
- a new section listing the common Hong Kong bonuses the sheet leaves out.

The two unclear points ("no flowers" with a flowerless set, and whether Small Three Dragons
includes the dragon pungs) are deliberately left out. The game itself scores only the dragon
pung of the new section's bonuses (docs/guides/MAHJONG.md).

---

You are editing the attached poster "HONG KONG MAHJONG — Common Winning Hands". Keep everything
else exactly as it is: the layout, colours, fonts, borders, titles, fan badges, descriptions, the
tile art style and the order of the 12 panels. Change only the items below.

1. **Panel 6, "Big Three Dragons" (8 fan).** The top row shows only two white dragon tiles (the
   blue-framed blank tiles), but the hand needs a triplet. Show three of each dragon: 中中中,
   發發發 and 白白白 (all three white dragon tiles identical, blue frame).

   The full hand should read, in 14 tiles:
   - 中 中 中
   - 發 發 發
   - 白 白 白
   - 一萬 二萬 三萬
   - a pair of 5 dots

   Keep the existing rows: the dragons on top, then 一二三萬, then the pair. Widen the tile
   spacing or shrink the tiles slightly if needed so that nine dragon tiles fit in the top row.

2. **Panel 1, "All Chows" (1 fan).** Every set must be a sequence of three consecutive numbers in
   one suit, and the dots row currently does not make sequences. Redraw the example as:
   - row 1: 一萬 二萬 三萬 | 四萬 五萬 六萬 (as now);
   - row 2: 1 dot, 2 dots, 3 dots | 7 dots, 8 dots, 9 dots;
   - row 3: a pair of 5 dots.

   Each dots tile must show the standard number of circles, clearly countable.

3. **Scoring notes, item 9 ("All Chows: +1 fan").** Remove it, because it repeats panel 1. Then
   rebalance the right-hand column so items 4–8 are evenly spaced.

4. **Panel 12, "Seven Pairs".** At this table it is a limit hand.
   - Replace the purple "House rules" badge with a red "Limit hand" badge that matches panels
     8–11.
   - Change the description to: "Seven distinct pairs (house rule)."
   - Keep the example tiles.
   - Change the footer banner to: "Seven Pairs and limit-hand scores follow house rules."

5. **Add a new section, "MORE COMMON BONUSES".** It covers standard Hong Kong scoring that the
   sheet leaves out.
   - Place it between the 12 panels and the scoring notes, styled like the scoring notes box
     (dark green header tab, cream background, numbered items in two columns).
   - Shrink the panels or the notes slightly if needed so that the whole poster still fits the
     same page size. Show example tiles only where noted, small and in the same tile style.

   The items, with fan values:
   1. **Dragon pung:** a triplet or quad of any dragon adds +1 fan. Example tiles: 中中中.
   2. **Concealed hand:** winning without claiming any discard adds +1 fan.
   3. **Last tile:** winning on the last tile of the wall adds +1 fan.
   4. **Kong replacement:** winning on the tile drawn after a kong adds +1 fan.
   5. **Robbing a kong:** winning on the tile another player adds to an exposed pung adds +1 fan.
   6. **Heavenly hand:** the dealer wins on the deal. It is a limit hand.
   7. **Earthly hand:** a player wins on the dealer's first discard. It is a limit hand.
   8. **Nine Gates:** 1-1-1-2-3-4-5-6-7-8-9-9-9 of one suit plus any tile of that suit. It is a
      limit hand. Example tiles: 一一一二三四五六七八九九九萬.

**Final check before you finish.** Every example hand must have exactly 14 tiles (Four Kongs: 18),
with no more than four copies of any tile. Count the tiles in every panel, not just the ones you
changed, and make every tile's number or symbol clearly legible. Report any other panel that
fails this check instead of changing it silently.
