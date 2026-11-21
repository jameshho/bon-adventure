extends Node
## The welcome tutorial's shopping trip (PWA restructure phase 6, 12 Nov 2026; tutorial.gd step
## "shop", settings in data/tutorial.json "shop"): the store's clerk asks for a fixed order
## (1 apple and 2 bananas), the player clicks the fruit into the shared cart, pays the cashier
## the exact price with the money panel and walks out. Tutorial-only: it borrows the store's
## clerk and cashier as speakers (their own interactables are off meanwhile, so their games never
## start) and the shared cart, dialogue and money panels, whose real sessions ignore events while
## they have no order or round. Picked fruit counts as studied (word_studied); nothing goes to the
## practice log or the activity board.
##
## User review, 14 Nov 2026: the clerk greets the player and hands over a shopping basket
## (shopping_basket.gd give(), held with hand_hold.gd; picked fruit shows in it); the clerk and
## cashier speak the NATIVE language, with the words and the amount in the language being learned
## coloured in the dialogue box (Lexicon.native_line() terms; the amount always shows its
## digits); the cashier's thanks closes itself after 3 s; and until the fruit is paid for, the
## supermarket door holds the player back (minigame_zone.gd make_door_guard(), settings "door").
##
## Tutorial script, 17 Nov 2026 (user): the clerk welcomes the player and hands over the basket in
## two bubbles; the shopping list (settings "items"; 1 apple and 2 bananas since the user's review
## of 17 Nov 2026, the cookies dropped) stays on
## screen until paid, each line ticked green with a small bounce when complete (a sound can hook
## in at _on_pick() once the game has audio); a wrong item gets BonBon's "Oops!"; her hints come
## only when asked and follow what is still missing ("hints" by group: "fruit", then any other
## group such as "cookie" if the list has more than fruit; general to exact); the cashier's "Pay with cash" opens the money panel with only $1 bills and
## quarters (settings "money"), with unlimited tries; leaving unpaid gets BonBon's "Wait!".
##
## Polish, 18 Nov 2026 (user): the clerk's and cashier's names are in the player's language; "Great!
## We got everything! Let's go pay!" is one 2 s bubble in BonBon's close-up; the amount comes without
## its digits and the strip says to hold EN when unsure; walking out anywhere past the doorway counts.
const ShopDialogue := preload("res://scripts/learning/shop_dialogue.gd")
const Currency := preload("res://scripts/learning/currency.gd")
const Interactable := preload("res://scripts/core/interactable.gd")
const Basket := preload("res://scripts/world/shopping_basket.gd")
const HouseCharacters := preload("res://scripts/characters/house_characters.gd")
const SuccessBurst := preload("res://scripts/world/success_burst.gd")
## Seconds the cashier's thanks stays up after paying (user, 14 Nov 2026: no tap needed).
const THANKS_SECONDS := 3.0
## Seconds BonBon's "Great! We got everything! Let's go pay!" stays (user, 18 Nov 2026).
const GO_PAY_SECONDS := 2.0
const PAY := "tutorial_pay"
## Metres from the cashier's front within which the player is "at the till".
const TILL_RADIUS := 2.6
## The apple close-up (user, 20 Nov 2026): the first time the player comes within APPLE_NEAR metres
## of the fruit table's apples (supermarket.gd tutorial_fruit, "Featured apples"), the camera eases
## in on them from the player's side, APPLE_VIEW_DISTANCE metres away and APPLE_VIEW_ELEVATION
## degrees above, and BonBon's "click the apple" line shows like any line until something is
## picked; the player stands still meanwhile and clicks aim from the close-up.
const APPLE_NODE := "Featured apples"
const APPLE_NEAR := 3.0
const APPLE_VIEW_DISTANCE := 1.4
const APPLE_VIEW_ELEVATION := 28.0
const APPLE_VIEW_FOV := 50.0
const APPLE_ZOOM_SECONDS := 0.5
## Seconds in the apple close-up without a click before the "click here" pointer shows on the
## apple (tap_hint.gd; user, 21 Nov 2026).
const TAP_HINT_AFTER := 3.0
## Fruit keys: while any of them is still on the list, BonBon's hints point to the fruit.
const FRUIT := ["apple", "banana"]

var tutorial
var main
var panel
var money
var interaction
var dialogue
var settings: Dictionary = {}
var clerk: Node3D
var cashier: Node3D
var store_zone := ""
## key -> count still to pick, and in the cart.
var remaining: Dictionary = {}
var cart: Dictionary = {}
var paid := false
## Where the trip is, for BonBon's "where next" line (where()): "order", "pick", "till", "pay",
## "leave", "done".
var phase := "order"
var _paying := false
## The last amount handed over was wrong (the cashier says so before asking again).
var _wrong := false
var _pay_pressed := false
var _speakers: Dictionary = {}
var _turned_off: Array = []
## Times BonBon was asked for a hint since the list last changed (asked()); the list key that just
## became complete (its row bounces once).
var _asks := 0
var _popped := ""
## The basket the clerk handed over (null before the greeting and after the trip).
var basket: Node3D
## The store door's guard (minigame_zone.gd DoorGuard): stands while the player is inside and
## has not paid.
var door
## The apple close-up's camera while it shows (null otherwise).
var _apple_camera: Camera3D

func setup(director, shop_settings: Dictionary) -> void:
	name = "TutorialShop"
	tutorial = director
	main = director.main
	panel = main.shop_panel
	money = main.money_panel
	interaction = main.interaction
	settings = shop_settings
	dialogue = ShopDialogue.new()
	var store := str(settings.store)
	var rules: Dictionary = dialogue.store_rules(store)
	var till: Dictionary = dialogue.cashiers.get(store, {})
	store_zone = str(rules.get("zone", store))
	clerk = main.apartment.find_child(str(rules.get("clerk", "")), true, false) as Node3D
	cashier = main.apartment.find_child(str(till.get("npc", "")), true, false) as Node3D
	# Their names in the player's language, like the rest of the tutorial (user, 18 Nov 2026).
	_speakers[clerk] = _native_name(str(clerk.get_meta("word_key", "")) if clerk != null else "", str(rules.get("clerk_gender", "")))
	_speakers[cashier] = _native_name(str(cashier.get_meta("word_key", "")) if cashier != null else "", str(till.get("npc_gender", "")))
	for npc in [clerk, cashier]:
		var item := Interactable.on(npc)
		if item != null and item.enabled:
			item.enabled = false
			_turned_off.append(item)
	for key in settings.items:
		remaining[str(key)] = int(settings.items[key])
	panel.done_pressed.connect(_on_done)
	panel.remove_pressed.connect(_on_remove)
	panel.choice_pressed.connect(func(id: String) -> void: _pay_pressed = _pay_pressed or id == PAY)
	money.submitted.connect(_on_submitted)
	money.close_requested.connect(_on_money_close)
	_make_door()

## A worker's name in the native language in every Display Mode ("Cashier", not "El Cajero").
func _native_name(word_key: String, gender: String) -> Dictionary:
	var name: String = str(dialogue.lexicon.word(word_key, dialogue.native, "", gender)).capitalize() if word_key != "" else ""
	return {"foreign": name, "native": name}

## The invisible wall in the store's doorway (data/tutorial.json shop "door": its centre "at",
## "size" along the space's axes and the "inward" [x, z] direction, in "space"); walking into
## it says "pay first".
func _make_door() -> void:
	var spec: Dictionary = settings.get("door", {})
	if spec.is_empty():
		return
	var space: Node3D = tutorial._space(str(spec.space))
	var at: Vector3 = tutorial._vec(spec.at)
	var size: Vector3 = tutorial._vec(spec.size)
	var inward: Vector3 = tutorial._look(spec.inward).normalized()
	# The question zone: a 1.2 m strip just inside the wall (sizes are along the space's axes).
	var along_x := absf(inward.x) >= absf(inward.z)
	var depth := size.x if along_x else size.z
	var ask_at := at + inward * (depth * 0.5 + 0.7) + Vector3.UP * size.y * 0.5
	var ask_size := Vector3(1.2, size.y, size.z) if along_x else Vector3(size.x, size.y, 1.2)
	door = tutorial.zone.make_door_guard(space, at + Vector3.UP * size.y * 0.5, size, ask_at, ask_size, "Tutorial store door", {
		"blocking": func() -> bool: return not paid and _inside(space, at, inward, depth * 0.5 + 0.6),
		"ask": func() -> void: tutorial.remark("guide", "tutorial.pay_first"),
		"layer": HouseCharacters.FIGURE_LAYER})

func _remove_door() -> void:
	if door == null:
		return
	for node in [door.wall, door.zone, door]:
		if is_instance_valid(node):
			node.queue_free()
	door = null

## The player is more than `margin` past the doorway's centre on the store side (the wall only
## stands then, clear of the player, so the player can walk in).
func _inside(space: Node3D, at: Vector3, inward: Vector3, margin: float) -> bool:
	var offset: Vector3 = space.to_local(main.player.global_position) - at
	return offset.x * inward.x + offset.z * inward.z > margin

## The whole trip; returns when the player has paid and walked out (or the tutorial stopped).
func play() -> void:
	var guide: String = tutorial._speaker("guide")
	var clerk_name: Variant = _speakers.get(clerk, "")
	var cashier_name: Variant = _speakers.get(cashier, "")
	# The clerk welcomes the player and hands over a basket, in the native language; the close-up
	# stays on her between the two lines (user, 21 Nov 2026).
	tutorial._keep_face = true
	await tutorial.say(clerk_name, tutorial.narration("tutorial.clerk_hello"), "", clerk)
	await tutorial.say(clerk_name, tutorial.narration("tutorial.clerk_basket"), "", clerk)
	if not tutorial.running:
		return
	basket = Basket.give(main)
	# The shopping list stays up until paid (clicks on products go to it: pick_hook).
	interaction.clear_card()
	panel.show_cart(_cart_data())
	phase = "pick"
	interaction.pick_hook = _on_pick
	# No "get the list" lines any more (user, 20 Nov 2026): the apple close-up shows what to do.
	await _apple_close_up(guide)
	if not tutorial.running:
		return
	var picked: bool = await tutorial.until(func() -> bool: return remaining.is_empty())
	if not picked:
		return
	if interaction.pick_hook == Callable(self, "_on_pick"):
		interaction.pick_hook = Callable()
	phase = "list_done"
	# One bubble for 2 s, in BonBon's close-up wherever she is (user, 18 Nov 2026).
	await tutorial.say(guide, tutorial.narration("tutorial.got_everything_pay"), "guide", null, {}, true, GO_PAY_SECONDS)
	phase = "till"
	var till := _till()
	var at_till: bool = await tutorial.until(func() -> bool: return tutorial._flat(main.player.global_position, till) <= TILL_RADIUS)
	if not at_till:
		return
	# Paying: the cashier asks for the price in the native language, the amount in the language
	# being learned without its digits (user, 18 Nov 2026: "un dólar con veinticinco centavos" since
	# the price became $1.25 on 21 Nov 2026; the strip reminds the player that holding EN shows it in
	# their language). Since 21 Nov 2026 (user) she asks in her close-up, which stays while the money
	# panel is up and through her next lines, and the shopping list is hidden from here on (the
	# list is complete; _close_cart() after paying).
	phase = "pay"
	panel.hide_cart()
	var request: Dictionary = tutorial.narration("tutorial.cashier_hello", {"amount": {"learn": dialogue.money_values(int(settings.price_cents))}})
	while not paid:
		_pay_pressed = false
		await _hold_cashier_face()
		if not tutorial.running:
			return
		panel.show_dialogue(cashier_name, request, [{"id": PAY, "label": tutorial.narration("tutorial.pay_cash"), "icon": "money"}])
		tutorial.show_peek_strip()
		var pressed: bool = await tutorial.until(func() -> bool: return _pay_pressed)
		tutorial.clear_peek_strip()
		if not pressed:
			return
		_open_money(request)
		var counted: bool = await tutorial.until(func() -> bool: return not _paying)
		if not counted:
			return
		if not paid and _wrong:
			_wrong = false
			tutorial._keep_face = true
			await tutorial.say(cashier_name, tutorial.narration("tutorial.cashier_wrong"), "", cashier)
	_close_cart()
	# The camera pans from the cashier's face to BonBon's for "meet outside", always in her
	# close-up (user, 21 Nov 2026).
	tutorial._keep_face = true
	await tutorial.say(cashier_name, tutorial.narration("tutorial.cashier_thanks"), "", cashier)
	await tutorial.say(guide, tutorial.narration("tutorial.meet_outside"), "guide", null, {}, true)
	phase = "leave"
	await tutorial.until(_walked_out)
	phase = "done"
	_restore()
	_remove_door()
	Basket.take_back(main)
	basket = null

## Waits until the player comes near the featured apples (or picked something on the way), then
## shows the apple close-up with BonBon's "click the apple" line until something is picked.
func _apple_close_up(guide: String) -> void:
	var line_id := "tutorial.click_apple_touch" if tutorial.is_touch() else "tutorial.click_apple"
	var apples := main.apartment.find_child(APPLE_NODE, true, false) as Node3D
	if apples == null:
		push_error("tutorial_shop: no %s; the click line shows without the close-up" % APPLE_NODE)
		await tutorial.say(guide, tutorial.narration(line_id))
		return
	var near: bool = await tutorial.until(func() -> bool:
		return not cart.is_empty() or tutorial._flat(main.player.global_position, apples.global_position) <= APPLE_NEAR)
	if not near or not cart.is_empty():
		return
	# The player holds still (the view and walking) but can click.
	var gate: Dictionary = tutorial._gate.duplicate()
	tutorial._gate = {"look": false, "move": false, "use": true}
	tutorial._apply_gate()
	var back: Camera3D = get_viewport().get_camera_3d()
	_zoom_apple(apples, back, true)
	var line: Dictionary = tutorial.narration(line_id)
	tutorial.hint(guide, line)
	var shown: Dictionary = panel.current_line()
	var hint_at := Time.get_ticks_msec() + int(TAP_HINT_AFTER * 1000.0)
	await tutorial.until(func() -> bool:
		if not tutorial.tap_hint.is_showing() and Time.get_ticks_msec() >= hint_at:
			tutorial.tap_hint.point_at(apples, tutorial.is_touch(), 0.15)
		return not cart.is_empty())
	tutorial.tap_hint.clear()
	if panel.is_dialogue_visible() and panel.current_line() == shown:
		panel.hide_dialogue()
	_zoom_apple(apples, back, false)
	if tutorial.running:
		tutorial._gate = gate
		tutorial._apply_gate()

## Shows the cashier's face close-up (npc_presence.gd, through the director) and leaves it held
## (tutorial._held_face), so her next line keeps it and the line after pans on from it; the
## director's _stop() releases it if the tutorial ends meanwhile.
func _hold_cashier_face() -> void:
	if cashier == null:
		return
	var face: Node = tutorial._face("", cashier)
	if face == null or (face == tutorial._held_face and face.is_zoomed()):
		return
	tutorial._release_face()
	# As in say(): a close-up still easing back first returns to the player's camera.
	var ends := Time.get_ticks_msec() + 800
	await tutorial.until(func() -> bool: return get_viewport().get_camera_3d() == main.camera or Time.get_ticks_msec() > ends)
	if not tutorial.running:
		return
	if get_viewport().get_camera_3d() == main.camera:
		face.zoom_to_face(true)
	tutorial._held_face = face

## Eases the camera in on the apples from `back` (the camera on screen), or back to it.
func _zoom_apple(apples: Node3D, back: Camera3D, on: bool) -> void:
	if on:
		var focus := apples.global_position + Vector3.UP * 0.15
		var toward: Vector3 = (main.player.global_position as Vector3) - focus
		toward.y = 0.0
		if toward.length() < 0.1:
			toward = back.global_basis.z
			toward.y = 0.0
		var lift := deg_to_rad(APPLE_VIEW_ELEVATION)
		var eye := focus + (toward.normalized() * cos(lift) + Vector3.UP * sin(lift)) * APPLE_VIEW_DISTANCE
		var goal := Transform3D(Basis.looking_at(focus - eye, Vector3.UP), eye)
		_apple_camera = Camera3D.new()
		_apple_camera.name = "TutorialAppleCamera"
		_apple_camera.fov = APPLE_VIEW_FOV
		_apple_camera.near = 0.05
		_apple_camera.far = back.far
		add_child(_apple_camera)
		var start := back.global_transform
		_apple_camera.global_transform = start
		_apple_camera.make_current()
		_apple_camera.create_tween().tween_method(func(t: float) -> void:
			_apple_camera.global_transform = start.interpolate_with(goal, t), 0.0, 1.0, APPLE_ZOOM_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		return
	if not is_instance_valid(_apple_camera):
		return
	var camera := _apple_camera
	_apple_camera = null
	if not is_instance_valid(back):
		camera.queue_free()
		return
	var from := camera.global_transform
	var tween := camera.create_tween()
	tween.tween_method(func(t: float) -> void:
		camera.global_transform = from.interpolate_with(back.global_transform, t), 0.0, 1.0, APPLE_ZOOM_SECONDS * 0.75).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func() -> void:
		if is_instance_valid(back) and camera.current:
			back.make_current()
		camera.queue_free())

## The player is out of the store: past its doorway (settings "door") or near "outside" (user,
## 18 Nov 2026: one who walked out anywhere was still told to walk out).
func _walked_out() -> bool:
	var spec: Dictionary = settings.get("door", {})
	if not spec.is_empty():
		var space: Node3D = tutorial._space(str(spec.space))
		if not _inside(space, tutorial._vec(spec.at), tutorial._look(spec.inward).normalized(), -0.5):
			return true
	var outside: Dictionary = settings.outside
	var exit_at: Vector3 = tutorial._space(str(outside.space)).to_global(tutorial._vec(outside.at))
	return tutorial._flat(main.player.global_position, exit_at) <= float(outside.radius)

## The phrase id of where to go next (BonBon, tutorial.gd where_line()); "" while someone speaks or
## the cashier's request with its button is up. While shopping: the hints for what is still
## missing (settings "hints": "fruit" while an apple or banana is missing, else "cookie"; none
## when that group has no hints), the
## more exact the more often she was asked.
func where() -> String:
	if phase == "pick":
		var group := "fruit" if FRUIT.any(func(key: String) -> bool: return remaining.has(key)) else "cookie"
		var hints: Array = settings.get("hints", {}).get(group, [])
		return str(hints[mini(_asks, hints.size() - 1)]) if not hints.is_empty() else ""
	return {"till": "tutorial.where_till", "leave": "tutorial.where_leave_store"}.get(phase, "")

## BonBon was asked (tutorial.gd _talk_to_guide()): the next hint is more exact.
func asked() -> void:
	_asks += 1

## The point in front of the cashier (where a customer stands).
func _till() -> Vector3:
	if cashier == null:
		return main.player.global_position
	return cashier.global_position - cashier.global_basis.z.normalized() * 1.8

func _rows(items: Dictionary) -> Array:
	var rows: Array = []
	for key in items:
		var single := {key: items[key]}
		rows.append({"key": key, "foreign": dialogue.items_text(single, dialogue.foreign), "native": dialogue.items_text(single, dialogue.native)})
	return rows

func _cart_data() -> Dictionary:
	return {
		"list_title": dialogue.line("shop.list_header"),
		"cart_title": dialogue.line("shop.cart_header"),
		"done": dialogue.line("shop.done_button"),
		"needed": _list_rows(),
		"cart": _rows(cart),
	}

## The shopping list: every item of the order with how many are in the basket ("1/2") and
## "done" once complete (shop_order_panel.gd ticks it; "pop" bounces the row just completed).
func _list_rows() -> Array:
	var rows: Array = []
	for key in settings.items:
		var want := int(settings.items[key])
		var got := int(cart.get(key, 0))
		var single := {key: want}
		var count := "  %d/%d" % [got, want] if got > 0 and got < want else ""
		rows.append({"key": key, "foreign": dialogue.items_text(single, dialogue.foreign) + count, "native": dialogue.items_text(single, dialogue.native) + count,
			"done": got >= want, "pop": key == _popped})
	return rows

func _on_pick(obj: Node3D) -> void:
	if not is_instance_valid(obj) or obj.has_meta("character_name") or obj.has_meta("hold_kind"):
		return
	var key: String = interaction.word_key(obj)
	if main.zones.resolve_global(obj.global_position) != store_zone:
		return
	if not remaining.has(key):
		tutorial.remark("guide", "tutorial.not_on_list")
		return
	remaining[key] = int(remaining[key]) - 1
	_popped = ""
	if int(remaining[key]) <= 0:
		remaining.erase(key)
		_popped = key
		_asks = 0
	cart[key] = int(cart.get(key, 0)) + 1
	# Right item: it hops and gold sparks puff out (the library game's, success_burst.gd; user,
	# 21 Nov 2026).
	var view := get_viewport().get_camera_3d()
	if view != null:
		SuccessBurst.celebrate(obj, obj.global_position + Vector3.UP * 0.15, view.global_position)
	interaction.word_studied.emit(key)
	panel.update_cart(_cart_data())
	_popped = ""
	_fill_basket(obj)

## Shows the cart's contents in the held basket; `picked`: the object just picked.
func _fill_basket(picked: Node3D = null) -> void:
	if not is_instance_valid(basket):
		return
	if picked != null:
		basket.remember(interaction.word_key(picked), picked)
	basket.show_items(cart)

func _on_remove(key: String) -> void:
	if interaction.pick_hook != Callable(self, "_on_pick") or not cart.has(key):
		return
	cart[key] = int(cart[key]) - 1
	if int(cart[key]) <= 0:
		cart.erase(key)
	remaining[key] = int(remaining.get(key, 0)) + 1
	panel.update_cart(_cart_data())
	_fill_basket()

## The cart's Done button: the order is checked as it is picked, so this only reminds.
func _on_done() -> void:
	if interaction.pick_hook == Callable(self, "_on_pick") and not remaining.is_empty():
		tutorial.remark("guide", "tutorial.get_list")

func _close_cart() -> void:
	if interaction.pick_hook == Callable(self, "_on_pick"):
		interaction.pick_hook = Callable()
	panel.hide_cart()

func _open_money(request: Dictionary) -> void:
	_paying = true
	panel.hide_dialogue()
	interaction.clear_card()
	money.show_native = panel.show_native
	money.reset()
	money.open({
		"request": request,
		"tray_title": dialogue.line("money.tray"),
		"bills": dialogue.line("money.bills"),
		"coins": dialogue.line("money.coins"),
		"total": dialogue.line("money.total"),
		"submit": dialogue.line("money.submit"),
		"clear": dialogue.line("money.clear"),
		"close": dialogue.line("money.close"),
		"translate": dialogue.line("common.show_translation"),
		# Only $1 bills and quarters in the introductory payment (user, 17 Nov 2026); what to do
		# shows in the empty tray (the instruction strip would cover the tray).
		"only": settings.get("money", []),
		"hint": tutorial.lexicon.phrase("tutorial.ui_pay", tutorial.lexicon.native, {"amount": Currency.usd(int(settings.price_cents))}),
	})
	money.set_progress(0, 0)
	main.sync_player_controls()

func _on_submitted(_cents: int) -> void:
	if not _paying or not money.visible:
		return
	paid = Currency.is_exact(money.counts, int(settings.price_cents))
	_wrong = not paid
	money.hide_panel()
	money.reset()
	_paying = false
	main.sync_player_controls()

func _on_money_close() -> void:
	if not _paying:
		return
	money.hide_panel()
	_paying = false
	main.sync_player_controls()

func _restore() -> void:
	for item in _turned_off:
		if is_instance_valid(item):
			item.enabled = true
	_turned_off.clear()

## The tutorial stopped mid-trip (skip): close what this trip opened.
func stop() -> void:
	if is_instance_valid(_apple_camera):
		if _apple_camera.current and is_instance_valid(main.camera):
			main.camera.make_current()
		_apple_camera.queue_free()
	_apple_camera = null
	_close_cart()
	Basket.take_back(main)
	basket = null
	_remove_door()
	if _paying:
		money.hide_panel()
		money.reset()
		_paying = false
	_restore()
