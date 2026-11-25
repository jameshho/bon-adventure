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
| A shopping basket the player carries while shopping, showing what was picked (or, since 24 Nov 2026, the zoo booth's paper bag: `give(node, ShoppingBasket.BAG)`) | `ShoppingBasket.give(node)`, `basket.remember(key, picked)` + `show_items(counts)`, `ShoppingBasket.take_back(node)` | `scripts/world/shopping_basket.gd` (holds through `hand_hold.gd`) | [Holding items](#holding-items) |
| An invisible wall in a doorway while a game runs (with a "leave?" or "not yet" zone inside it) | `MinigameZone.make_door_guard()` | `scripts/learning/minigame_zone.gd` | [Minigames](MINIGAMES.md#building-a-minigame); users: Mystery House, Alta Cocina, the welcome tutorial's store door (until paid, 14 Nov 2026) |
| Words of the language being learned inside a native-language dialogue line, coloured, tap for the meaning | `Lexicon.native_line(id, {slot: {"learn": value}}, extra_terms)` (line `terms`) | `scripts/language/lexicon.gd`, drawn by `scripts/ui/shop_order_panel.gd` | [Coloured words](#coloured-words-in-the-dialogue-box) |
| A one-line "what to do now" instruction, top centre, apart from speech (with an optional "1/2") | `InstructionStrip`: `show_text(line, note)`, `clear()`, `hidden_when` | `scripts/ui/instruction_strip.gd` | [Instruction strip](#instruction-strip) |
| Paying with money: pick bills and coins (only some denominations, an instruction in the tray) | `money_panel.gd open(lines)` with `only` / `hint` | `scripts/ui/money_panel.gd` | [Money panel options](#money-panel-options) |
| A close-up of an item | `object_inspector.gd open(item, camera, options)` | `scripts/player/object_inspector.gd` | [Holding guide](HAND_HOLD.md#inspecting) |
| An elevator call or floor button; the cabin's floor picker (E at the panel: camera close-up, tap a 3D button; 14 Nov 2026) | `ElevatorCallButton` (`pick_size`, `picker_on_e`), built by `hospital_elevator.gd`; `elevator_floor_picker.gd` | `scripts/world/elevator_call_button.gd`, `scripts/ui/elevator_floor_picker.gd` | [Hospital guide](HOSPITAL_THREE_FLOORS.md#floor-picker--14-november-2026) |
| Heavy goods carried in front, trolleys pushed and pulled | the warehouse game's own physics carry | `scripts/learning/warehouse_goods.gd` | [Holding items](#holding-items) |
| A seat, bench, bed or swing | word `chair` / `bench` / `sofa` / `bed`, or the seat metas | `scripts/player/seating_controller.gd` | [Sitting and lying](#sitting-and-lying) |
| An NPC sits or lies somewhere | `HouseCharacters.seated()`, `data/npcs.json` | `scripts/characters/house_characters.gd` | [Sitting and lying](#sitting-and-lying) |
| Any NPC: its id, spot, costume, role; idle chatter and brush-offs when it has no game on offer | `data/npcs.json` via `npc_registry.gd` (`spec()`, `place()`, `spawn()`, `make()`); `npc_chatter.gd` (`main.npc_chatter`) | `scripts/characters/` | [NPCs](NPCS.md) (23 Nov 2026) |
| Eyes: blink, shut, sleep | `PlushLife` | `scripts/characters/plush_life.gd` | [Plush characters](#plush-characters) |
| A small move: hop, shake, nod, lean | `PlushLife.play(host, figure, kind)` | `scripts/characters/plush_life.gd` | [Plush characters](#plush-characters) |
| An NPC that talks, calls with "!" and gets a face close-up | `minigame_host.gd`, `npc_presence.gd` (spec `"board": false` for an NPC that talks through the host but is no activity, the supermarket till since 21 Nov 2026; meta `talk_face_drop` for a hat; meta `talk_camera_at`, a global point, fixes the close-up camera where walls block the automatic one, 13 Nov 2026) | `scripts/learning/` | [Minigames](MINIGAMES.md#building-a-minigame) |
| Animals that wander | `park_animals.gd` profiles | `scripts/world/park_animals.gd` | [Animal system](ANIMAL_SYSTEM.md) |
| An animal comes to food and eats it (or sniffs and refuses it) (24 Nov 2026) | `animal.offer_food(parent_local_point, eats)` and its `food_done(ate)` signal (`park_animals.gd`); the head bows through `clay_animator.gd` `eat` (an unrigged animal bows its whole body); feeding from a carried bag: `animal_feeding.gd` | `scripts/world/park_animals.gd`, `scripts/characters/clay_animator.gd`, `scripts/world/animal_feeding.gd` | [Feeding Time!](../game/minigames.md#feeding-time) |
| A clay animal walks, breathes, turns its head (the 17 clay zoo animals, 16 Nov 2026, and the tiger, 17 Nov; a new species needs its own `tools/build_<prefab>_clay_rig.gd` bone spec; a display that already has `LeftEye`/`RightEye` nodes lists them in `on_head`) | `clay_rig.gd` at bake time, then `clay_animator.gd` at run time; blinking through `PlushLife.follow_group("clay_animals")` | `scripts/characters/clay_rig.gd`, `scripts/characters/clay_animator.gd` | [Clay animal animation](ANIMAL_SYSTEM.md#clay-animal-animation-16-nov-2026) |
| A window: glass, frame, sill; a real opening in a wall (18 Nov 2026: frame presets HOUSE / SHOPFRONT / CIVIC / ARCHED in the game palette) | `scenes/props/window.tscn`; `GlassWindows.real_window(town, unit, parent, centre, outward, look)` in a building step | `scripts/world/glass_window.gd`, `scripts/buildings/glass_windows.gd` | [Windows](WINDOWS.md#real-windows--18-november-2026) |
| Praise for a right answer on a 3D object: a hop and gold sparks (21 Nov 2026) | `SuccessBurst.celebrate(node, at, viewer)`, `SuccessBurst.sparks(parent, frame)` | `scripts/world/success_burst.gd` | Users: the library game (a book shelved right), the welcome tutorial's shopping list |
| The end of a minigame: what the player achieved, the words practiced and discovered, a small reward (21 Nov 2026) | Nothing in the game: `results_flow.gd` shows it for every game that ends `completed` (`Board.complete(id)` for a game whose end is not a round count); `show_results({...})` directly for anything else | `scripts/ui/results_screen.gd`, `scripts/learning/results_flow.gd`, `scripts/learning/session_words.gd` | [Results screen](MINIGAMES.md#results-screen); every learning game |
| "Click / tap this" on a 3D object: a pulsing ring with a mouse pointer or fingertip (21 Nov 2026) | `tap_hint.gd` `point_at(node, touch, up)`, `clear()` on a full-screen CanvasLayer | `scripts/ui/tap_hint.gd` | User: the welcome tutorial's apple (after 3 s without a click) |
| Something found once and kept, like an achievement: a floating gold coin with BonBon's face, collected by walking into it (21 Nov 2026) | `StampCoin.make(stamp_id)` or `scenes/props/stamp_coin.tscn`; any one-off activity: `Achievements.shared().note(event)` | `scripts/world/stamp_coin.gd`, `scripts/learning/achievements.gd`; placed in the town from `data/achievements.json` by `scripts/world/stamp_places.gd` (`gate`: a door that must be open first) | [Passport guide](ACHIEVEMENTS.md#town-stamps) |
| A bell (or anything) that swings when used and signals for a sound (21 Nov 2026) | `chapel_bell.gd` on a node with a `Bell clapper` child; signal `rung` | `scripts/world/chapel_bell.gd` | [Chapel record](TOWN_DESIGN_BRIEF.md#stamp-places-storage-room-bank-safe-grand-chapel--21-november-2026) |
| A road vehicle's headlights; a siren with flashing red / blue lights (21 Nov 2026) | `vehicle.toggle_headlights()` / `toggle_siren()`, or `Headlights.of(vehicle)` / `EmergencyLights.of(vehicle)` with `set_on()`, `toggle()`, `is_on`, `switched` | `scripts/world/vehicle_headlights.gd`, `scripts/world/emergency_lights.gd` | [Vehicle lights](ZOO_VEHICLE_IMPLEMENTATION.md#headlights-siren-and-flashing-lights--21-november-2026); users: every road vehicle; the police car, ambulance and fire truck |
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
- To allow only some interactables for a while (the welcome tutorial: doors and BonBon, 17 Nov
  2026), set `interaction_controller.gd` `interact_filter` (item -> bool); the others are not
  focused and a click on them does nothing. Clear it (`Callable()`) afterwards. A rejected item's
  own `on_check` is not run; to answer with a line instead ("not the right place"), leave it
  allowed and set its `on_check` to return the line.

## Things that open

| Mechanism | Owner | Why it is separate |
| --- | --- | --- |
| Hinged doors, sliding doors and drawers, shower curtains | `door_animator.gd`: one registry (`main.doors`), types `hinge`, `slide`, `curtain`; every entry is an interactable | The standard. A new door or drawer is a node with a `door_state` meta. A hinge door may name a `spin` child (and `spin_angle`): that wheel turns first and the door waits for it (the bank safe, 21 Nov 2026). A hinge door with `seconds` (door scenes: `swing_seconds`) swings slowly and heavily over that time (the bank vault, 23 Nov 2026) |
| Walk-through doors (frame, leaf, handles, sign) | `scenes/props/door.tscn`, `double_door.tscn`, `sliding_door.tscn` ([Doors guide](DOORS.md)) | Build the door and register its leaf with the animator. **Paused 13 Nov 2026: built, no building migrated yet** |
| Garage door | `scripts/world/garage_door.gd` | Sectional panels on a curved track; reverses mid-travel |
| Zoo and farm gates | `scripts/world/zoo_gate.gd` | Two leaves at their own speed. Could move to the animator, but its swing speed would change; left as it is (user, 13 Nov 2026). Since 23 Nov 2026 `toggle_gate(from)` opens the leaves away from the opener (the player's position) |
| Vehicle doors | `scripts/world/vehicle_door.gd`, `vehicle_doors.gd` | Driven by the boarding sequence, not by E |
| Mystery House doors | `scripts/world/mystery_door.gd` | Game doors: rattle, slam, recolour |
| Warehouse cabinet (minigame copy) | `warehouse_goods.gd set_cabinet()` | Lives in the minigame's copy of the hall. The town warehouse's cabinet is an ordinary `door_animator.gd` hinge pair since 23 Nov 2026 (warehouse step `openable_cabinet`), like the police lockers (police step `two_lockers`) |
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

A held item that can be dropped gives itself a `drop()` method: the **Drop** button (above
Inspect, key G; `hold_inspect_ui.gd`, 24 Nov 2026) then shows and calls it. The farm egg
(`farm_egg.gd`) is the only one so far; it breaks.

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
in `data/shops.json` (`shop_session.gd`: the supermarket), and since 21 Nov 2026 free shopping at
the supermarket (`cashier_session.gd`: E on a basket stack, an Interactable on each `basket_racks`
node, gives a basket; an empty one goes back the same way). Since 24 Nov 2026 the zoo food booth
(Feeding Time!) uses the same component as a **paper bag**: `give(node, BAG)` (meta `carrier`,
word *shopping bag*, hand profile `bag`, its items peek out of the top; `is_bag()`), handed out by
the booth's till (`data/shops.json` store `zoo`: `"carrier": "bag"`, `"keep_paid": true` keeps the
paid bag, its food in meta `food`) and fed to the animals by `animal_feeding.gd`. A pick hook should ignore objects with
a `hold_kind` meta (the held basket's own pick area).

Since 18 Nov 2026 (user) the body is one closed tapered tub (no slits at the corners or the
floor) and the handles are a separate `Handles` mesh that hides while the basket is inspected
(`on_inspect_begin()` / `on_inspect_end()`, the hooks `object_inspector.gd` calls on any held
item). The Inspect button also hides while the money panel is open.

The dialogue box's ✕ can be turned off with `shop_panel.closable = false` (the welcome tutorial,
18 Nov 2026), and `npc_presence.gd` `cut_from(other)` cuts from another NPC's face close-up to
this one's without easing through the player's view.

## Coloured words in the dialogue box

User, 14 Nov 2026: in a line spoken in the native language (the welcome tutorial, its clerk and
cashier), words in the language being learned are coloured, and a tap or click on one shows its
meaning after it ("(= apple)", phrase `common.term_meaning`); a second tap hides it; holding
the HUD's EN button (or L) shows them all (since 17 Nov 2026 the one language toggle: the box
has no translate bubble of its own; `shop_order_panel.gd` follows `GameSettings.peek_changed`). No hover, so it works on touch. Build the line with
`Lexicon.native_line(id, values, extra_terms)` (or `tutorial.narration()`): a value
`{"learn": <word ref, per-language text, ...>}` is written in the language being learned and
becomes a term `{"text", "gloss"}`; `"show": true` on it always shows the meaning (amounts:
"dos dólares con cincuenta centavos (= $2.50)"); `extra_terms` adds words already inside another
value (`lexicon.word_term(key)`). Any line with a `terms` list gets this in the shared dialogue
box (`shop_order_panel.gd`, its line is a `RichTextLabel`); nothing names a language in code.

## Instruction strip

User, 17 Nov 2026 (the welcome tutorial's "UI" lines): one slim line of what to do now, top
centre, with a gold pointer, apart from the speech bubble of whoever talks. `scripts/ui/instruction_strip.gd`
is its own CanvasLayer (layer 58): add one to the tree, then `show_text("Press E to get up.")`,
`show_text("Find BonBon's two friends", "1/2")` or `clear()`. It stays until replaced or cleared,
slides in with a short glow when the text changes, never takes a click or a finger and scales
with the window like the panels (min(height / 800, width / 1100)). `hidden_when` (a `() -> bool`)
hides it meanwhile without forgetting the text (journal, map, Settings, money panel open);
`top` (pixels at scale 1) places it under other top-centre UI. User: the welcome tutorial
(`tutorial.gd` `show_strip()`); any guided activity may reuse it rather than writing its own.

## Money panel options

`money_panel.gd open(lines)` takes, besides its labels: `only` (17 Nov 2026), the denomination
ids to offer (`Currency.DENOMS` ids such as `bill_1`, `coin_25`; empty = all), and `hint`, a
line shown inside the empty tray (the welcome tutorial: "Pay $2.50", so the instruction sits
where the player looks instead of a strip covering the tray). With no coin among `only` the Coins section is hidden (18 Nov 2026, the
bank teller game: $5, $10, $50 and $100 bills). The tray shows the pieces in the order they
were first picked, left to right (user, 21 Nov 2026; a denomination taken back out to none goes
to the end when picked again). The shared dialogue box's answer buttons wrap onto a second row
when they do not fit (`shop_order_panel.gd`, 21 Nov 2026).

Since 23 Nov 2026 (user: the card covered the HUD's EN): `clear_of`, an Array of Controls (set
once by `minigame_wiring.gd` to the HUD's EN, `peek_button`), keeps them visible and clickable:
the card starts below them, clicks on them pass through the panel (`_has_point`), and the L key
(action "peek") is no longer swallowed. When the content is taller than the card (the lowered
card, the translation lines while EN is held) everything inside shrinks to fit (`_fit`). Empty
`clear_of` = the whole screen, as before.

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
lane numbers and OPEN tags, PRODUCE, price board, MARKET, facades). The electronics store (`electronics_makeover.gd`, 18 Nov 2026: its six signs). Not yet migrated, with their
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
| Medium | Clay animal animation: the 17 clay zoo animals walk (16 Nov 2026); not checked on the web or a phone, the golden retriever rig is heavy (72k triangles), and the 11 older piece-built animals still glide ([rollout](ANIMAL_SYSTEM.md#all-clay-zoo-animals-walk-16-nov-2026)) |
| Low | The player's arm swing uses BonBon's shoulder point; measure it when another plush needs to walk |
| Low | Static `lie` characters in `data/npcs.json` keep their eyes open; a `hold_eyes()` call would shut them if wanted |
| Low | Zoo gate and warehouse cabinet could join `door_animator.gd` at the cost of a small timing change |
