# Vocabulary usage report

Generated 2026-11-21 by `tools/vocabulary_report.gd -- --write` (whole town loaded; how to run and what each column means: the script's header and [the guide](../ARCHITECTURE_REVIEW_PART1.md#vocabulary-usage-report)). Full table: [report.csv](report.csv).

**Dialogue:** only words that fill a `{slot:form}` in `data/phrases.json` are reported (column `phrase_slots`). Words written as plain text inside dialogue lines are not matched, so a word can appear in dialogue and still be listed here as unused.

## Totals

| | Words |
| --- | ---: |
| In data/words.json | 795 |
| Placed in the saved scenes | 773 |
| Clickable somewhere (study by clicking) | 747 |
| Placed only by scripts at load (runtime) | 0 |
| Only on a bound world label (poster) | 0 |
| Tested by a game | 149 |
| Only shown by a game | 55 |
| Can fill a phrase slot | 36 |
| **Placed nowhere and used by no game** | **22** |
| Placed nowhere but used by a game | 0 |
| Placed but not clickable (no pick collision) | 26 |

## Hard errors (unknown word keys)

None: every key in game data, scenes, labels, aliases and phrase slots exists in `data/words.json`.

## Games and the words they test

Decision 6 (user, 7 Nov 2026). The police lineup is not tracked: each round names two clue words and the answer is a suspect, so no question has one clear tested word. The evidence game is tracked since its redesign (8 Nov 2026): one property word decides each round.

| Game id | Tests | Shows only |
| --- | ---: | ---: |
| `evidence_mimi` | 6 | 10 |
| `family_dr_li` | 19 | 12 |
| `flight_bruno` | 26 | 0 |
| `grammar_lana` | 16 | 0 |
| `library_rosa` | 24 | 0 |
| `lineup_rocco` | 0 | 23 |
| `mystery_luna` | 11 | 0 |
| `restaurant_twinkle` | 38 | 18 |
| `shop_supermarket` | 16 | 0 |
| `warehouse_ramon` | 4 | 0 |

- **evidence_mimi** tests: hard, heavy, light (weight), rough, smooth, soft
- **family_dr_li** tests: aunt, boyfriend, brother, cousin, daughter, father, girlfriend, granddaughter, grandfather, grandmother, grandson, husband, mother, nephew, niece, sister, son, uncle, wife
- **flight_bruno** tests: brazil, canada, day after tomorrow, day before yesterday, france, friday, germany, in one hour, japan, last night, mexico, monday, one hour ago, saturday, spain, sunday, this afternoon, this morning, thursday, today, tomorrow, tonight, tuesday, united states, wednesday, yesterday
- **grammar_lana** tests: apple, bed, book, bowl, cat, cow, desk, dog, duck, fish, horse, knife, map, pants, shirt, water
- **library_rosa** tests: airplane, animal, basketball, cactus, cake, car, cat, cookie, dog, drum, elephant, flower, food, guitar, music, piano, pizza, plant, soccer, sport, tennis, train, tree, vehicle
- **mystery_luna** tests: blue, circle, green, orange, pink, purple, red, square, star, triangle, yellow
- **restaurant_twinkle** tests: apple pie, beef with vegetables, brownie, cheese bread, chocolate cake, coffee, cookie, crispy pork, flan, french fries, fruit salad, fruit yogurt, gazpacho, grilled chicken, hard candy, hot chocolate, ice cream, iced tea, lasagna, lemon fish, lemon shrimp, lemonade, meatballs, milkshake, nachos, orange juice, pizza, roast lamb, salad, soda, soup, sparkling water, spicy wings, steak, taco, tea, tiramisu, water
- **shop_supermarket** tests: apple, banana, broccoli, carrot, corn, cucumber, grapes, lemon, lettuce, onion, orange, pear, potato, strawberry, tomato, watermelon
- **warehouse_ramon** tests: blue, green, red, yellow

## Placed nowhere and used by no game (22)

- **Actions** (2): to listen, to look at
- **Animals** (1): crocodile
- **Around the House** (1): shower curtain
- **Building Parts** (1): base
- **Colors & Descriptions** (16): brown, creamy, crunchy, dark, dry, fizzy, fresh, juicy, loud, medium, noisy, quiet, refreshing, shiny, wet, with ice
- **People** (1): nurse

## Placed but not clickable (26)

airplane, ambulance, armchair, banker, bed, boss, bus, car, electrical box, faucet, fire truck, gate, helicopter, label, motorcycle, pilot, police car, radar, school bus, soccer, sofa, taxi, teacher, tennis, truck, wheelchair

## Same meaning twice (1 groups)

An alias that is also a word key, a singular and plural key both listed, or two keys with the same text in one language (case-insensitive). Some are fine (a Chinese word that covers two English senses); each needs a human look.

- same text (zh) "足球": soccer, soccer ball

## Removed words still placed (0)

`removed_with_objects` lists deleted words whose objects should be gone; no script removes them at load any more (the startup passes were deleted 6 Nov 2026).

None.

## Phrase slots

- `shop.return_to_clerk`: {"clerk":"People"}
- `posters.person`: {"person":"Family"}
- `family.q_relation`: {"relation":"Family"}
