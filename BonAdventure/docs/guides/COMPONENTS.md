# Reusable components: interaction and character behaviour

**Read this before adding anything a player can use, hold, open or sit on, or anything a
character does with its body or face, or any lettering on a sign in the town.** Each row below is the one implementation of that
behaviour. Reuse it; if it does not quite fit, extend it (a new setting, profile or gesture)
instead of writing a second version beside it. If you find a second version, fold it into the
component here and update this page.

Audited and consolidated 13 November 2026 (user request). Evidence: `docs/evidence/plush-rig-20261113/`.

## Index

| Need | Use | File | Details |
| --- | --- | --- | --- |
| The player can use something (E, click, tap) | `Interactable.attach(owner, {...})` and a `use()` on the owner | `scripts/core/interactable.gd`, `scripts/player/interaction_controller.gd` | [Interaction](#interaction) |
| Something owns E for a while (driving, seated, carrying) | `interaction.claim(id, wants, use, click)` | `interaction_controller.gd` | [Interaction](#interaction) |
| A door, drawer, cabinet door or curtain | a `door_state` meta; the shared door scenes for walk-through doors | `scripts/core/door_animator.gd`, `scripts/world/door.gd` | [Things that open](#things-that-open) |
| The player holds a small item | `player.hand.hold(item)`, `HandHold.toggle(item)` | `scripts/player/hand_hold.gd` | [Holding items](#holding-items) |
| A shopping basket the player carries while shopping, showing what was picked | `ShoppingBasket.give(node)`, `basket.remember(key, picked)` + `show_items(counts)`, `ShoppingBasket.take_back(node)` | `scripts/world/shopping_basket.gd` (holds through `hand_hold.gd`) | [Holding items](#holding-items) |
| An invisible wall in a doorway while a game runs (with a "leave?" or "not yet" zone inside it) | `MinigameZone.make_door_guard()` | `scripts/learning/minigame_zone.gd` | [Minigames](MINIGAMES.md#building-a-minigame); users: Mystery House, Alta Cocina, the welcome tutorial's store door (until paid, 14 Nov 2026) |
| Words of the language being learned inside a native-language dialogue line, coloured, tap for the meaning | `Lexicon.native_line(id, {slot: {"learn": value}}, extra_terms)` (line `terms`) | `scripts/language/lexicon.gd`, drawn by `scripts/ui/shop_order_panel.gd` | [Coloured words](#coloured-words-in-the-dialogue-box) |
| A close-up of an item | `object_inspector.gd open(item, camera, options)` | `scripts/player/object_inspector.gd` | [Holding guide](HAND_HOLD.md#inspecting) |
| An elevator call or floor button; the cabin's floor picker (E at the panel: camera close-up, tap a 3D button; 14 Nov 2026) | `ElevatorCallButton` (`pick_size`, `picker_on_e`), built by `hospital_elevator.gd`; `elevator_floor_picker.gd` | `scripts/world/elevator_call_button.gd`, `scripts/ui/elevator_floor_picker.gd` | [Hospital guide](HOSPITAL_THREE_FLOORS.md#floor-picker--14-november-2026) |
| Heavy goods carried in front, trolleys pushed and pulled | the warehouse game's own physics carry | `scripts/learning/warehouse_goods.gd` | [Holding items](#holding-items) |
| A seat, bench, bed or swing | word `chair` / `bench` / `sofa` / `bed`, or the seat metas | `scripts/player/seating_controller.gd` | [Sitting and lying](#sitting-and-lying) |
| An NPC sits or lies somewhere | `HouseCharacters.seated()`, `data/house_characters.json` | `scripts/characters/house_characters.gd` | [Sitting and lying](#sitting-and-lying) |
| Eyes: blink, shut, sleep | `PlushLife` | `scripts/characters/plush_life.gd` | [Plush characters](#plush-characters) |
| A small move: hop, shake, nod, lean | `PlushLife.play(host, figure, kind)` | `scripts/characters/plush_life.gd` | [Plush characters](#plush-characters) |
| An NPC that talks, calls with "!" and gets a face close-up | `minigame_host.gd`, `npc_presence.gd` (meta `talk_face_drop` for a hat; meta `talk_camera_at`, a global point, fixes the close-up camera where walls block the automatic one, 13 Nov 2026) | `scripts/learning/` | [Minigames](MINIGAMES.md#building-a-minigame) |
| Animals that wander | `park_animals.gd` profiles | `scripts/world/park_animals.gd` | [Animal system](ANIMAL_SYSTEM.md) |
| A clay animal walks, breathes, turns its head (the zoo pig only, 16 Nov 2026; other species need their own bone spec) | `clay_rig.gd` at bake time, then `clay_animator.gd` at run time; blinking through `PlushLife.follow_group("clay_animals")` | `scripts/characters/clay_rig.gd`, `scripts/characters/clay_animator.gd` | [Clay animal animation](ANIMAL_SYSTEM.md#clay-animal-animation-16-nov-2026-the-zoo-pig-walks) |
| Lettering on a sign, board or tag in the town (readable size, translation, contrast) | `WorldSign.make(...)` / `WorldSign.restyle(label, {"read": metres, ...})`, `WorldSign.fit_board(...)` | `scripts/world/world_sign.gd` (translation: `scripts/world/sign_language.gd`) | [World signs](#world-signs) |

## Interaction

The full contract is in the architecture guide's
[Interaction system](ARCHITECTURE_REVIEW_PART1.md#interaction-system). In short:

```gdscript
const Interactable := preload("res://scripts/core/interactable.gd")

func _ready() -> void:
	if Engine.is_editor_hint():      # @tool scripts only
		return
	Interactable.attach(self, {"prompt_distance": 2.2, "badge_offset": Vector3(0, 0.4, 0)})

func use() -> void:                  # E, a click or a tap
	...

func can_interact() -> Variant:      # optional: true, false (no badge) or a reason line
	return true
```

- Never add a key handler, a click meta, a hint label or a proximity check of your own.
- An object that holds E for a while registers an input claim instead of reading the key.
- `kind` (USE, TALK, DRIVE, ...) is set by every interactable but read by nothing yet. Keep
  setting it: it is the hook for the planned sounds. It does not change behaviour.

## Things that open

| Mechanism | Owner | Why it is separate |
| --- | --- | --- |
| Hinged doors, sliding doors and drawers, shower curtains | `door_animator.gd`: one registry (`main.doors`), types `hinge`, `slide`, `curtain`; every entry is an interactable | The standard. A new door or drawer is a node with a `door_state` meta |
| Walk-through doors (frame, leaf, handles, sign) | `scenes/props/door.tscn`, `double_door.tscn`, `sliding_door.tscn` ([Doors guide](DOORS.md)) | Build the door and register its leaf with the animator. **Paused 13 Nov 2026: built, no building migrated yet** |
| Garage door | `scripts/world/garage_door.gd` | Sectional panels on a curved track; reverses mid-travel |
| Zoo and farm gates | `scripts/world/zoo_gate.gd` | Two leaves at their own speed. Could move to the animator, but its swing speed would change; left as it is (user, 13 Nov 2026) |
| Vehicle doors | `scripts/world/vehicle_door.gd`, `vehicle_doors.gd` | Driven by the boarding sequence, not by E |
| Mystery House doors | `scripts/world/mystery_door.gd` | Game doors: rattle, slam, recolour |
| Warehouse cabinet | `warehouse_goods.gd set_cabinet()` | Lives in the minigame's copy of the hall |
| Lift doors | `scripts/world/hospital_elevator.gd` | Part of the lift's own sequence |

Do not add another door animation. A new kind of motion (for example a lid) is a new `type`
in `door_animator.gd animate()`.

## Holding items

Two mechanics, on purpose:

- **In the hand** (`hand_hold.gd`, [guide](HAND_HOLD.md)): hand-sized things that ride on
  BonBon's left arm. A new kind of object is one new entry in `PROFILES` and a `hold_kind` meta.
- **Carried in front** (`warehouse_goods.gd`): big physics goods that float ahead of the
  player with a put-down preview, and trolleys driven with W / S. Used only inside the
  Warehouse Worker game. Do not use it for small items, and do not copy it.

A holdable object's `use()` is one line (the book, `library_book.gd`, is the example):

```gdscript
const HandHold := preload("res://scripts/player/hand_hold.gd")

func use() -> void:
	HandHold.toggle(self)   # take it; on the item already held, put it back where it was
```

`HandHold.of_player(node)` returns the player's hand from anywhere in the tree. The hand is
created once; when a profile's avatar replaces the player's model it moves to the new arm
(`rebind()`).

Shopping basket (14 Nov 2026, user): a shop hands the player a basket with
`ShoppingBasket.give(node)` (a new `scenes/props/shopping_basket.tscn` in the hand, profile
`basket`; whatever was held is put back first), shows the order in it with
`basket.remember(key, picked_object)` and `basket.show_items({key: count})` (a small model of each
item: the store's product model, else the picked object's first mesh; at most 12), and removes it
with `ShoppingBasket.take_back(node)` (only a basket that `give()` handed out). Users: the welcome
tutorial's shop (`tutorial_shop.gd`) and the customer order game of stores with `"basket": true`
in `data/shops.json` (`shop_session.gd`: the supermarket). A pick hook should ignore objects with
a `hold_kind` meta (the held basket's own pick area).

## Coloured words in the dialogue box

User, 14 Nov 2026: in a line spoken in the native language (the welcome tutorial, its clerk and
cashier), words in the language being learned are coloured, and a tap or click on one shows its
meaning after it ("(= apple)", phrase `common.term_meaning`); a second tap hides it; the
translate button shows them all. No hover, so it works on touch. Build the line with
`Lexicon.native_line(id, values, extra_terms)` (or `tutorial.narration()`): a value
`{"learn": <word ref, per-language text, ...>}` is written in the language being learned and
becomes a term `{"text", "gloss"}`; `"show": true` on it always shows the meaning (amounts:
"dos dólares con cincuenta centavos (= $2.50)"); `extra_terms` adds words already inside another
value (`lexicon.word_term(key)`). Any line with a `terms` list gets this in the shared dialogue
box (`shop_order_panel.gd`, its line is a `RichTextLabel`); nothing names a language in code.

## Sitting and lying

| Who | Owner | How |
| --- | --- | --- |
| Player | `seating_controller.gd` finds and offers seats; `player_controller.gd` `begin_sitting()` / `end_sitting()` blends the pose | Seats are found by word or meta; nothing to write per chair |
| Player, from a script | `seating.sit_at(node, stand_back)` | Minigame tables (`minigame_table.gd`) |
| NPC | `house_characters.gd` `_sit()` computes a seated pose from the figure's own meshes; `seated()` places one on any seat; `Bedtime` moves nappers between seat and bed while unseen | NPCs snap into the pose, they do not animate |

The two poses are different by nature (the player's blends each frame, an NPC's is computed
once), so they stay separate. What they share lives in `plush_life.gd`: shut eyes and the
sleeping breath.

## Plush characters

### The rig

All ten plush scenes (`scenes/characters/*_plush.tscn` and `BonBon.tscn`) share one structure, so
code written for one works on all:

| Node | What it is |
| --- | --- |
| `Torso` | The whole body **including the head**: one mesh |
| `Head` | Only the face group: eyes, cheeks, snout or muzzle, ears. **Its origin is at the feet** |
| `Head/LeftEye`, `Head/RightEye` | Eye meshes, each centred on its own node |
| `Arm`, `Arm_2`, `Foot`, `Foot_2` | Left and right limbs. Origins at the feet; pivot in code |
| `Tail` | Optional |

Every part's origin is the character's origin (the floor between its feet), facing local −Z.
Measured sizes are in `docs/evidence/plush-rig-20261113/measure.json` (`measure.gd`): total height
2.21–2.35, eye height 1.56–1.80, arm centre height 0.89–1.06.

Decisions (user, 13 Nov 2026):

- **Proportions are not normalised.** The differences are small and are each species' look.
  Code that poses a part must measure the figure (its mesh bounds) instead of assuming BonBon's
  numbers. Known exception: `player_controller.gd` uses BonBon's shoulder point
  `(±0.65, 1.22, 0)` for the arm swing; generalise that before making NPCs walk.
- **Never rotate the `Head` node.** It turns the face about the feet: a nod pushes the face
  into the body and a tilt pulls the ears off (`docs/evidence/plush-rig-20261113/gestures.png`, columns
  2–4). There is no separate head to turn, so there is no look-at; a character "looks" by
  turning its whole body.

### Eyes, blinking, sleeping, gestures: `plush_life.gd`

```gdscript
const PlushLife := preload("res://scripts/characters/plush_life.gd")

# A game's own figures: blinking, and optionally a small move now and then.
var life := PlushLife.new()
life.blink_gap = Vector2(4, 10)     # seconds, min and max (the default)
life.gestures = true                # one figure at a time, every gesture_gap seconds
add_child(life)
life.setup([npc_a, npc_b], rng)
life.set_figures(new_figures)       # a game that rebuilds its figures each round

# Anything else that moves a plush:
PlushLife.hold_eyes(figure, true)       # asleep: shut until hold_eyes(figure, false)
PlushLife.set_eyes_open(figure, 0.4)    # a slow close, 0 shut ... 1 open
PlushLife.breath_scale(rest, breath)    # torso scale for a sleeper's breath, -1 ... 1
PlushLife.play(self, figure, "nod")     # "hop", "shake", "nod", "tilt"; returns the Tween
```

Who uses it:

| Where | Use |
| --- | --- |
| Every plush NPC in town | `main.plush_life`: one node that blinks every plush in group `figures` each 6–14 s (`TOWN_BLINK_GAP`). No gestures. New figures join by being in the group |
| Mahjong players | Their own `PlushLife` (blink 4–10 s, a gesture every 10–20 s) |
| Police lineup | Its own `PlushLife` (blink 2.5–6 s, no random gestures); `_hop` and `_shake` call `PlushLife.play()`. Its breathing and lean toward the pointer stay in the session |
| Napping house characters | `hold_eyes()` and `breath_scale()` |
| The player lying in a bed | `hold_eyes()`, `set_eyes_open()` with the pose blend, `breath_scale()`. The player does not blink |

### Ownership and priority

One writer per property. When two want it, the higher row wins and the lower one yields.

| Property | Owner | Yields to |
| --- | --- | --- |
| Eye transform | `plush_life.gd` only. Never scale or move an eye node elsewhere | A hold (`hold_eyes`) beats a blink: a held figure is skipped and a blink in progress does not reopen it |
| A figure's blinking | The `PlushLife` whose set it is in (meta `plush_life_owned`) | The town blinker skips owned figures |
| An NPC's position and rotation | `npc_presence.gd` while it calls with its "!" (the hop) | `PlushLife` makes no gesture on a calling figure; one gesture at a time per figure |
| `Head` node transform | Nobody. Leave it at rest | — |
| The player's body parts (`Arm`, `Foot`, `Visual`) | `player_controller.gd`, one state per frame in this order: seated or lying, riding (`animate_boarding`, `motorcycle_rider.gd`), walking (`animate_bonbon`) | The hand only supplies an arm pose to `animate_bonbon` (`hand.arm_pose()`); it never writes the arm |
| The player's `Visual` scale | `mystery_session.gd` during the toad sequence only | — |

Adding a gesture: a new `match` branch in `PlushLife.play()` that tweens the figure's
`position` or `rotation` and ends on the starting value; add its name to `GESTURES` if it
should happen at random.

## World signs

Built 16 November 2026 (user: signs were hard to read). The rule is the blueprint's
[sign readability](BUILDING_DESIGN_BLUEPRINT.md#sign-readability): letter height ≥ reading
distance / 30, contrast 4.5. `scripts/world/world_sign.gd` is the one way to size and colour sign
lettering; a building script calls it from a step and bakes the unit.

| Call | Does |
| --- | --- |
| `WorldSign.make(parent, name, text, position, spec)` | A new `Label3D` sign (English text; register it with `sign_language.gd` as before) |
| `WorldSign.restyle(label, spec)` | Brings an existing label up to the rule; never makes it smaller unless `spec.em` says so |
| `WorldSign.fit_board(board, label, margin, texts)` | Grows a too-small board or tag to the widest of `texts` (all languages) |
| `WorldSign.board_behind(label, root, reach, max_size, colour)`, `board_colour()`, `free_width()` | Finds the panel a label is painted on and its free width (give `colour` where meshes overlap) |

`spec`: `read` (metres, required), `em` (a letter height above the rule), `colour`, `board`
(the colour behind the text), `fit_width` (free board width), `max_lines` (wraps when > 1),
`billboard`.

A world sign uses one font size (`FONT_SIZE` 64, one of the web build's shared label sizes in
`render_culling.gd`) and sets its letter height with `pixel_size`. Its metas (`world_sign`,
`sign_read`, `sign_min_em`, `sign_fit_width`, `sign_max_lines`, `sign_board`, `sign_pixel_size`)
tell `sign_language.gd` how far it may shrink for a longer translation: to the fit width, never
below `sign_min_em`. `tools/bake_unit.gd` keeps the base pixel size in the scene. An outline is
added only when the lettering lacks contrast against its board.

Users: the supermarket (`supermarket.gd` step `world_signs`, 16 Nov 2026: department bands,
lane numbers and OPEN tags, PRODUCE, price board, MARKET, facades). Not yet migrated, with their
own sign code: `base.gd` (`_zz_sign`), `sports.gd`, `home_expansion.gd`, `restaurants.gd`,
`library.gd`, `chapel.gd`, `mystery.gd`, `warehouse.gd`, `town_zones.gd`,
`hospital_elevator.gd`, `coplanar_gaps.gd` and the door scenes' signs. The check
`docs/evidence/world-signs-20261116/verify.gd` (runner id `world_signs`) tests every world sign
in every language and prints which buildings still have small labels.

## Open items

| Priority | Item |
| --- | --- |
| Medium | Shared doors: migrate the buildings ([steps](DOORS.md#steps-to-finish)) |
| Medium | World signs: migrate the other buildings' sign code, one building script step and bake each ([list](#world-signs)); the check prints which still have small labels |
| Medium | Clay animal animation: the zoo pig walks (16 Nov 2026); every other species still glides and needs its own bone spec, not yet approved ([risks](ANIMAL_SYSTEM.md#clay-animal-animation-16-nov-2026-the-zoo-pig-walks)) |
| Low | The player's arm swing uses BonBon's shoulder point; measure it when another plush needs to walk |
| Low | Static `lie` characters in `house_characters.json` keep their eyes open; a `hold_eyes()` call would shut them if wanted |
| Low | Zoo gate and warehouse cabinet could join `door_animator.gd` at the cost of a small timing change |
