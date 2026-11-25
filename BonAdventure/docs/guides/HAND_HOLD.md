# Holding and inspecting items

User request, 13 November 2026: a reusable left-hand item holder for the player (books,
shopping baskets and more) with a natural arm pose, and an Inspect button that opens a close-up
of the held item, built as a reusable inspection component (today: zoom in and exit; later:
rotate, open, manipulate).

## Pieces

| Piece | File | Role |
| --- | --- | --- |
| Hand holder | `scripts/player/hand_hold.gd` | `player.hand`: a socket on BonBon's left mitten, child of her `Arm` part, so the item follows every arm pose. Hold profiles per kind of object |
| Arm pose | `scripts/player/player_controller.gd` `animate_bonbon()` | While holding, the left arm uses the profile's pose (forward lift, outward lift, share of the walking swing); the right arm is unchanged |
| Inspector | `scripts/player/object_inspector.gd` | Generic close-up of any `Node3D`: glides it in front of the camera with a dim backdrop and back to where it came from |
| Inspect button | `scripts/ui/hold_inspect_ui.gd` | `Main.hold_ui`: the button, the close button, Esc and E, and blocking movement while inspecting; since 24 Nov 2026 also the **Drop** button (above Inspect, key G, action `drop`), shown only while the held item has a `drop()` method (the farm egg: it breaks) |
| Holdable objects | `scenes/props/book.tscn` (`hold_kind` book), `scenes/props/shopping_basket.tscn` (new: one carried basket, handles raised, word *basket*) | Any `Node3D` can be held; the meta `hold_kind` picks its profile |

BonBon has no skeleton: her arms are mesh parts posed in code (`Arm` is her left arm, pivot at the
shoulder `(-0.65, 1.22, 0)` in her frame; she faces −Z). The palm socket is at
`hand_hold.gd PALM` `(-0.86, 0.95, 0.01)`.

## Using the holder (minigames and future features)

```gdscript
var hand = game.player.hand
var previous = hand.hold(book)            # holds; returns what it replaced, detached (or null)
hand.release()                            # puts it back where it was picked up
hand.release(shelf_gap, gap_transform)    # puts it at a new parent / world transform
hand.swap(basket)                         # same as hold(): returns the previous item
hand.held                                 # the item or null; hand.held_changed(item) signal
```

- The item keeps its world size. Its solid `CollisionShape3D`s (under physics bodies) are off
  while held and back on at release; pick areas stay, so a click still names the word.
- Nothing is saved: a held item is a scene node like any other.
- Cost: no per-frame work except a hanging item's sway (the basket), a few lines of maths.

### Profiles

`hand_hold.gd PROFILES`, chosen by `hold(item, kind)`, else the item's `hold_kind` meta, else
`default`. A new kind of object = one new entry:

| Key | Meaning |
| --- | --- |
| `rotation` | Item turn in the hand, degrees, in BonBon's frame (−Z forward, −X outward) |
| `grip` | The point of the item's own bounding box (0–1 per axis) that sits in the palm |
| `offset` | Palm to grip, BonBon units |
| `arm` | x forward lift (rad), y share of the walking swing, z outward lift (rad) |
| `sway` | 0 = held firmly; 1 = hangs and swings like a pendulum from the hand |
| `inspect` | Close-up pose for the inspector: `yaw`, `tilt` (degrees), `fill` (share of the view) |

| Kind | How it is held |
| --- | --- |
| book | Upright at her side, cover facing out, spine forward, gripped near its middle; firm (sway 0); arm 0.1 forward, 0.16 out, half the walking swing |
| basket | Hanging from its handles, long side along her path; swings (sway 1); arm 0.3 out so it clears her body. `shopping_basket.gd give()` passes the kind "basket" (14 Nov 2026: the meta is set only in `_ready()`, so a given basket had used the default profile) |
| egg | A farm egg from the hen house (24 Nov 2026, `farm_egg.gd`): cupped in the mitten, arm 0.38 forward as if carried carefully, a quarter of the walking swing, firm (sway 0) |
| default | Centred in the palm, arm a little forward |

Standing still the arm is at its holding pose and the item does not move; walking and running
swing the arm (scaled by `arm.y`), and a hanging item lags and settles.

## Books on the return rack

User request, 13 November 2026: each of the 24 books on the library's return rack is its own
object the player can pick up with E.

- `library_book.gd` export `holdable`: the book gets an [Interactable](ARCHITECTURE_REVIEW_PART1.md#interaction-system)
  (prompt 1.8 m, priority 2.0) and a `use()`. Rack books (meta `return_book`) turn it on at load,
  so the baked `library.scn` is unchanged; a minigame can set it on any book.
- E (or a click / tap) in front of a rack book takes it in the left hand. Holding a book, E on
  another rack book puts the first back and takes the new one.
- The held book's "E" sits at its empty place on the rack (`hand.home_transform()`): back near
  the rack, E puts it back exactly where it was. Away from the rack it offers nothing.
- Priority 2.0 matches Rosa's calling bonus (`CALL_BONUS`): she stands beside the rack with her
  "!", and without it E near the rack talked to her instead. The book you face (or aim at) wins;
  facing Rosa, she does.
- As interactables, the rack books are no longer word-card targets (the interaction rule); the
  shelf rows still are.

Check `docs/evidence/hand-hold-20261113/rack.gd` (`VT_FOCUS=library`): see [Verification](#verification--13-november-2026).

## Inspecting

Whenever the player holds something, a magnifier button (the bottom-right cluster's size and
style, left of the map button) shows. It hides with an empty hand, while the map, journal or
help is open, or under the dialogue box, and it stays available in minigames.

- Inspect: `object_inspector.gd open(item, camera, options)` moves the item from the hand onto
  a stage in front of the camera (0.35 s), sized so its bounding sphere fills `fill` of the view
  height and turned by the profile's `yaw`/`tilt` (books show their cover; since 14 Nov 2026,
  user, the basket is seen from nearly straight above, tilt 80° and fill 1.0, so the goods inside
  read: [render](../evidence/run-button-shop-20261114/basket_inspect.png)), in front of a backdrop that dims
  the world to about half.
- Movement and word clicks are off meanwhile (`Main.sync_player_controls`). The button becomes a
  ✕; the ✕, Esc (popup stack) or E (input claim `inspect`) closes, and the item glides back into
  the hand.
- Profile options (user, 21 Nov 2026, books): `auto` opens the close-up by itself `delay` s after
  the player picks the item up (`hand_hold.gd` signal `picked_up`, emitted by `toggle()` only, so
  a game putting an item into the hand does not zoom); `seconds` and `gentle` (ease in and out)
  set the glide; `tap_close` hides the ✕ and a press anywhere (mouse or touch, on a button or
  not), Esc or E closes. When a game takes the inspected item out of the hand (`release()`, signal
  `releasing`), the close-up ends at once (`object_inspector.gd close_now()`). Books: no delay (the zoom starts with the E press; 21 Nov 2026, user), a 0.75 s gentle glide, tap to close.

### Extending the inspector

Without changing `object_inspector.gd`:

- `inspector.stage` holds the object; turn it to rotate the object.
- `inspector.add_mode(mode)`: any object with optional `begin(inspector)`,
  `input(event) -> bool` (true = consumed; `hold_inspect_ui.gd` forwards unhandled input),
  `process(delta)` and `end(inspector)`. For example, a drag-to-rotate mode or a page-turn mode.
- The inspected object may define `on_inspect_begin(inspector)` / `on_inspect_end(inspector)`
  (for example, a book could open its cover).
- `opened(item)` / `closed(item)` signals.
- Options `fit: "face"` (a flat object's x × y front fills `fill` of the view height or width,
  not its bounding sphere) and `distance` (the stage sits this close to the camera and the object
  is scaled down to match, so a big object stays in front of nearby walls); 24 Nov 2026.

### Poster close-up — 24 November 2026

User request: some vocabulary posters are too small to read, so a click on one of their words
opens a zoomed view of the poster instead of the word card. `scripts/ui/poster_inspect_ui.gd`
(`Main.poster_ui`): `interaction_controller.gd click()` hands a word that would open its card to
`poster_hook` first; a word whose parent is named "… poster …" or "… menu board" and holds at
least two word cards is on a poster. A copy of the poster (batched originals shown, picking areas
and distance fade off, the restaurant icon sheets shared) glides to 0.7 m in front of the camera
with `fit: "face"`, `fill` 0.8, gentle; the wall poster hides meanwhile and the copy is freed on
closing. The game buttons hide (`hud.hide_for_game(true, "poster")`), movement and word clicks are
off (`Main.sync_player_controls`). Input claim `poster`: a tap closes an open card, else a tap on a
word of the copy (its screen box) shows that word's card and studies it, a tap off the poster
closes; E, Esc (popup stack) and the ✕ (the Inspect button's place) close. Not in minigames or
while the tutorial holds word cards back (as word cards).
Check: `docs/evidence/poster-closeup-20261124/verify.gd` (isolated HOME,
`VT_FOCUS=school,police,restaurants,warehouse,airport`, graphics): **71 checks, 0 failures** on
the family, evidence, Pizza menu board, warehouse verbs and airport "when" posters; renders
`*-closeup.png`, `*-card.png`. Not checked: the Mystery House posters (Chinese titles; same rule),
a real touch tap (the check calls `click()` with a pointer position).

## Verification — 13 November 2026

`docs/evidence/hand-hold-20261113/verify.gd` (isolated HOME, `VT_FOCUS=library`, graphics): **19 checks,
0 failures**: socket on the left arm; book profile; world size kept; button visible only while
holding; still pose stable; walking swing within limits; inspection opens on the stage, blocks
movement, shows ✕, registers with Esc; closing returns the book to the hand and movement; swap
returns the book detached; basket solids off while held and on after release; release returns
the basket home; release to a target. Renders inspected: `book-standing`, `book-walking`,
`book-behind`, `book-inspect`, `basket-standing`, `basket-walking`, `basket-inspect`.
First renders showed the book floating outside the mitten and a fully black inspection
backdrop (instance transparency is ignored in this renderer); fixed (book tucked in; backdrop
fades its material alpha).

Return rack (`docs/evidence/hand-hold-20261113/rack.gd`, `VT_FOCUS=library`), 13 November 2026:
**11 checks, 0 failures** headless: 24 rack books, each an Interactable; standing in front of
one it gets the focus (it lost to Rosa before the 2.0 priority); E holds it and the Inspect button
shows; the held book's focus is at its place; E puts it back exactly; using another book swaps;
no focus for the held book away from the rack; release puts it back. The first graphics run hung
after its first capture (window frames stopped); a second graphics run passed the same 11 and
rendered `rack-focus` (the "E" on the book in front of BonBon, Rosa keeps her "!"), `rack-holding`
(*Aventura* in her left hand beside the rack) and `rack-gap` (the "E" at its empty place, the
Inspect button showing).

Shopping basket (14 Nov 2026, user): the welcome tutorial's clerk and the supermarket's order
game hand the player a basket that fills with what is picked (`shopping_basket.gd` `give()`,
`show_items()`, `take_back()`; [Components](COMPONENTS.md#holding-items)). Checks:
`docs/evidence/tutorial-20261112/verify.gd` (renders `basket`) and `docs/evidence/shop-basket-20261114/verify.gd`.

Not covered: (since 13 Nov 2026 the [book-sorting game](MINIGAMES.md) uses the hand for its cart books: `library_session.gd`); touch was not tested on a device; sitting, driving and ladders keep the item in
the hand (it follows the arm; hidden with BonBon in road vehicles), not reviewed visually.
