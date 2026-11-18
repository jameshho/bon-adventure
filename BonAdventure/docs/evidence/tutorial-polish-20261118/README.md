# Tutorial polish — 18 November 2026

The user's polish list for the welcome tutorial, the supermarket lot, the basket and the logo.
Design and behaviour: [welcome tutorial, polish of 18 Nov](../../guides/ARCHITECTURE_REVIEW_PART1.md#welcome-tutorial);
vehicles: [parked vehicles](../../guides/ZOO_VEHICLE_IMPLEMENTATION.md#more-parked-vehicles--14-november-2026).

## What changed

| Item | Where |
| --- | --- |
| Line timings: look around 1.8 s; meet my friends / where are they / help find 2.0 / 2.3 / 2.0 s; more to show 3 s; let's go outside 2 s | `data/tutorial.json` say step `seconds`; `tutorial.gd` `say(..., seconds)` |
| View step 2 rad then 2 s; walk step 10 m then 1 s | `tutorial.json` `turn`, `distance`, `pause` steps |
| No ✕ on the dialogue box or on the shopping list | `shop_order_panel.gd` `closable` |
| No clock; Skip button where the clock was, hidden while an instruction strip shows | `day_clock.gd` `set_hidden()`; `tutorial.gd` `_process()`, `SKIP_TOP` |
| "That's not where we are going right now!" and "not there" close after 2 s, "not on our shopping list" after 1.5 s | `tutorial.json` `remark_seconds`; `tutorial.gd` `remark()` |
| No "press E to open the shower curtain" strip | `tutorial.json` (the friend has no `strip`); the phrases are gone |
| Front door opens by itself after "more to show you" | `tutorial.json` door step with `name` |
| Back-to-back close-ups cut from face to face | `npc_presence.gd` `cut_from()`; `tutorial.gd` step loop and `say()` |
| Market cast behind the player, never moving | `tutorial.json` market `place` step (walks and the closing pause removed) |
| Clerk / cashier named in the native language, no article ("Cashier") | `tutorial_shop.gd` `_native_name()` |
| "Great! We got everything! Let's go pay!" one 2 s bubble in BonBon's close-up | phrase `got_everything_pay`; `tutorial_shop.gd` `GO_PAY_SECONDS` |
| Cashier's amount without digits, strip "hold EN" while asking | `tutorial_shop.gd`; `tutorial.gd` `show_peek_strip()` |
| No Inspect button while paying | `hold_inspect_ui.gd` |
| Walking out anywhere past the doorway ends the shop (no "walk out" said outside) | `tutorial_shop.gd` `_walked_out()` |
| Basket: one closed tub, handles hidden while inspected | `shopping_basket.gd` `mesh()`, `handles_mesh()`, `on_inspect_begin/end()` |
| White car three bays from its first spot (the next bay is on the drive); pickup truck to the warehouse lot; the 15 red motorcycles removed | base step `tutorial_lot_clear` (`scripts/buildings/base.gd`), baked into `scenes/town/base.scn` |
| Logo: the brown gaps between lion/cat, pig/beagle, beagle/bear transparent | `assets/branding/source/clear_logo_pockets.gd` (run once) |
| Found on the way: the reply button could stay away if EN was held while the camera eased to a friend's face | `tutorial.gd` `say()` (`withheld`) |
| Found on the way: 豚 (capybara, 水豚) had no pinyin | `data/pinyin_zh.json` |

## Checks (18 Nov 2026, `dev_focus.txt` = `all`)

- `tutorial` (`verify.gd` here, now the runner's `tutorial` check): **PASS, 168 checks, 0 failures**
  (headless, `tools/run_checks.py`). Earlier runs on the way: a native crash from the check calling
  a freed shop node (fixed in the check) and the EN race above (fixed in the game).
- One graphical run of the same check (before the "Cashier" name and list ✕ change): 166 checks,
  0 failures; the views here come from it, so `cashier.png` still shows "The Cashier" and the
  list's ✕.
- `vehicle_arcade`, `zoo_vehicles`: PASS (updated: 16 parked cars, 28 road vehicles, the scooter
  for the motorcycle tests, the truck in the warehouse bay).
- `shop_basket`, `app_flow`, `day_night`, `interaction`, `vehicle_boarding`, `runtime_resources`,
  `language`: PASS. The full suite was not run.
- `basket.gd`: renders the basket (before / after, side, top, inspect view without handles).
- `list_vehicles.gd`: lists the vehicles near the supermarket lot and every motorcycle.

Not checked: a real phone, and the logo on the web build until it is published.

## Views

- `market-cast.png`: the cast behind the player at the supermarket, no clock, Skip at the top.
- `need-food.png`, `found-all.png`: close-ups after a direct cut.
- `cashier.png`: the amount without digits and the EN strip. `pay.png`: no Inspect button.
- `basket-inspect.png`, `basket_*`: the basket before and after.
- `logo_pockets_before.png` / `logo_pockets_after.png`: the logo over green, before and after.
