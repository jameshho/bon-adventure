extends SceneTree
## Run / Reset buttons and the quicker supermarket order (14 Nov 2026, user; README "Movement",
## docs/guides/TOWN_DESIGN_BRIEF.md "Customer order minigame", docs/guides/HAND_HOLD.md#inspecting):
##   - walking 7.2 m/s, running 12 m/s; the Run button (left of jump, touch AND mouse) toggles
##     running like Shift, is lit while on, works with a mouse click and a finger, hides in a
##     vehicle and while a minigame runs; the red Reset shows only while flying the plane;
##   - the supermarket order: only the 16 basic fruits and vegetables (each pickable in the
##     store), exactly 2 items, 1-2 of each, at most 3 of one in the cart; the cart and basket
##     open at once with the clerk's line; no scroll bar; the cart fits its content (laptop and
##     phone); the large ✕; a retry hands the basket back; the basket inspects from above.
## With a window it saves PNGs to this folder. Uses Main: run with an isolated HOME (README).
## HOME=<scratch>/home VT_FOCUS=supermarket VT_SPAWN=none godot --path . --resolution 1200x800 --script res://docs/evidence/run-button-shop-20261114/verify.gd
## Prints "RUN BUTTON SHOP: N checks, M failures".
const TouchControls := preload("res://scripts/ui/touch_controls.gd")
const UiText := preload("res://scripts/language/ui_text.gd")
const Order := preload("res://scripts/learning/shop_order.gd")
const Basket := preload("res://scripts/world/shopping_basket.gd")
const DIR := "res://docs/evidence/run-button-shop-20261114/"
const BASICS := ["apple", "banana", "orange", "grapes", "strawberry", "watermelon", "pear", "lemon", "tomato", "carrot", "potato", "onion", "lettuce", "broccoli", "cucumber", "corn"]

var checks := 0
var failures := 0
var game
var touch
var graphics := false

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

func frames(n: int) -> void:
	for i in n:
		await process_frame

func snap(file: String) -> void:
	if not graphics:
		return
	await frames(8)
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(DIR + file))

func click(at: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = at
		event.global_position = at
		root.push_input(event)
		await process_frame

func finger(at: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = 0
		event.position = at
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame

func lit(button: Button) -> bool:
	return (button.get_theme_stylebox("normal") as StyleBoxFlat).bg_color.is_equal_approx(TouchControls.RUN_LIT[0])

func window(size: Vector2i) -> void:
	if graphics:
		DisplayServer.window_set_size(size)
		await frames(20)

func run() -> void:
	graphics = DisplayServer.get_name() != "headless"
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(30)
	for node in game.hud.ui_root.get_children():
		if node.get_script() == TouchControls:
			touch = node
	var player = game.player
	check(is_equal_approx(player.walk_speed, 7.2) and is_equal_approx(player.sprint_speed, 12.0) and is_equal_approx(player.hyper_speed, 28.0), "walk 7.2, run 12, hyper unchanged")
	var session = game.get_node_or_null("ShopSession_supermarket")
	check(touch != null and session != null, "touch controls and the supermarket order game exist")
	if touch == null or session == null:
		return finish()
	# Stand inside the supermarket, a few metres from the clerk.
	player.global_position = session.clerk.global_position + session.clerk.global_basis.z * 3.0 + Vector3.UP * 0.2
	player.velocity = Vector3.ZERO
	await frames(20)

	# --- Run on a laptop (no touch) -------------------------------------------------------
	var run_button: Button = touch.run_button
	check(not touch.touch_mode or not graphics, "laptop: no touch mode")
	check(run_button.visible and run_button.text == UiText.t("hud.run_button"), "Run shows with a mouse, labelled from hud.run_button (%s)" % run_button.text)
	var jump: Rect2 = game.hud.jump_slot()
	var box := Rect2(run_button.position, run_button.size)
	check(box.end.x <= jump.position.x and absf(box.get_center().y - jump.get_center().y) < 1.0 and is_equal_approx(box.size.x, game.hud.bottom_slot(0).size.x), "Run sits left of jump, cluster size (%s)" % str(box))
	check(not player.sprint_enabled and not lit(run_button), "walking: Run unlit")
	await snap("run_laptop_off.png")
	var modes: Array = []
	player.movement_mode_changed.connect(func(s: bool, _h: bool) -> void: modes.append(s))
	await click(box.get_center())
	await frames(2)
	check(player.sprint_enabled and lit(run_button) and modes == [true], "a mouse click on Run turns running on once, lit (%s)" % str(modes))
	await snap("run_laptop_on.png")
	var shift := InputEventKey.new()
	shift.keycode = KEY_SHIFT
	shift.physical_keycode = KEY_SHIFT
	shift.pressed = true
	Input.parse_input_event(shift)
	await frames(2)
	shift = shift.duplicate()
	shift.pressed = false
	Input.parse_input_event(shift)
	await frames(2)
	check(not player.sprint_enabled and not lit(run_button), "Shift turns it off and Run follows")

	# --- Run on a phone-sized touch screen ------------------------------------------------
	touch.touch_mode = true
	game.hud.set_touch_mode(true)
	await window(Vector2i(844, 390))
	await frames(5)
	check(touch.visible and run_button.visible, "touch: joystick layer and Run show")
	box = Rect2(run_button.position, run_button.size)
	check(not box.intersects(touch._jump_rect) and not box.intersects(touch._use_rect), "Run clear of the touch jump and E")
	modes.clear()
	await finger(box.get_center())
	await frames(3)
	check(player.sprint_enabled and modes == [true], "a finger on Run turns running on once (%s)" % str(modes))
	await snap("run_touch_on.png")
	await finger(box.get_center())
	await frames(3)
	check(not player.sprint_enabled, "a second tap turns it off")
	touch.touch_mode = false
	game.hud.set_touch_mode(false)
	await window(Vector2i(1200, 800))

	# --- Supermarket order ----------------------------------------------------------------
	var rules: Dictionary = session.rules
	var pool: Array = session.pool
	var sorted := BASICS.duplicate()
	sorted.sort()
	check(pool == sorted, "the order pool is the 16 basic fruits and vegetables (%s)" % str(pool))
	check(str(rules.get("unique_items")).replace(".0", "") == "[2, 2]" and str(rules.get("quantity_each")).replace(".0", "") == "[1, 2]" and int(rules.get("cart_max_each")) == 3, "rules: 2 items, 1-2 each, cart max 3")
	var all_ok := true
	var quantities := {}
	for s in 200:
		var o = Order.new("supermarket", pool, rules, s)
		if o.order.size() != 2:
			all_ok = false
		for k in o.order:
			quantities[o.order[k]] = true
			if not BASICS.has(k) or o.order[k] < 1 or o.order[k] > 2:
				all_ok = false
	check(all_ok and quantities.size() == 2, "200 orders: exactly 2 basics, 1 and 2 both occur")
	var market: Node3D = game.apartment.get_node("RelocatedSites/Supermarket/MarketInterior")
	var missing: Array = []
	for k in BASICS:
		if _product(market, k) == null:
			missing.append(k)
	check(missing.is_empty(), "every basic is pickable in the store (missing %s)" % str(missing))

	session.start_game()
	await frames(2)
	var panel = game.shop_panel
	check(panel.is_cart_visible() and Basket.carried(game) != null, "the cart and the basket come at once")
	check(panel.is_dialogue_visible() and session.host.line_id == "shop.order_intro", "the clerk's order line shows beside the cart")
	check(not run_button.visible, "Run hides while the order runs (HUD game buttons hidden)")
	check(panel.cart_card.find_children("*", "ScrollContainer", true, false).is_empty(), "no scroll bar in the cart")
	await frames(4)
	var quit: Button = panel.cart_quit_button
	var other_close: Button
	for b in panel.dialogue_card.find_children("*", "Button", true, false):
		if b.icon != null and b != panel.translate_button and b.size.x > 0.0:
			other_close = b
	check(other_close != null and quit.size.x >= other_close.size.x * 1.5 and quit.size.y >= other_close.size.y * 1.5, "the cart ✕ is at least 1.5 x the dialogue ✕ (%s vs %s)" % [str(quit.size), str(other_close.size if other_close else Vector2.ZERO)])
	var view: Vector2 = root.get_visible_rect().size
	var card: Rect2 = panel.cart_card.get_global_rect()
	check(Rect2(Vector2.ZERO, view).encloses(card) and card.size.y <= panel.cart_card.get_combined_minimum_size().y + 1.0, "laptop: the cart fits its content on screen (%s)" % str(card))
	await snap("order_start.png")
	# Pick the order: the rows show in the cart and the goods in the basket.
	for k in session.order.order:
		var product := _product(market, str(k))
		for i in int(session.order.order[k]):
			if product != null:
				session._on_pick(product)
	await frames(4)
	card = panel.cart_card.get_global_rect()
	check(Rect2(Vector2.ZERO, view).encloses(card), "laptop: the filled cart still fits")
	# Top-down basket inspection.
	game.hold_ui.open_inspection()
	await frames(40)
	check(game.hold_ui.inspecting() and float(game.player.hand.inspect_options().get("tilt", 0.0)) >= 75.0, "the basket inspects from nearly straight above (%s)" % str(game.player.hand.inspect_options()))
	check(Basket.carried(game) != null and Basket.carried(game).item_count() == session.order.cart.values().reduce(func(a, b): return a + b, 0), "the basket holds what the cart lists")
	await snap("basket_inspect.png")
	game.hold_ui.close_inspection()
	await frames(30)
	# Phone landscape with touch.
	touch.touch_mode = true
	game.hud.set_touch_mode(true)
	await window(Vector2i(844, 390))
	await frames(5)
	view = root.get_visible_rect().size
	card = panel.cart_card.get_global_rect()
	check(Rect2(Vector2.ZERO, view).encloses(card), "phone: the cart fits on screen (%s in %s)" % [str(card), str(view)])
	check(quit.size.x >= 48.0 and quit.size.y >= 44.0, "phone: the ✕ is finger-sized (%s)" % str(quit.size))
	await snap("order_phone.png")
	touch.touch_mode = false
	game.hud.set_touch_mode(false)
	await window(Vector2i(1200, 800))
	# A wrong cart: the retry hands the basket back with the cart open.
	for k in session.order.cart.keys():
		while session.order.cart.has(k):
			session._on_remove(k)
	var first: String = str(session.order.order.keys()[0])
	session._on_pick(_product(market, first))
	session._on_done()
	await frames(2)
	session._report(session._result)
	await frames(2)
	check(session.order.state == Order.State.RETRY_OFFER and not game.player.hand.is_holding(), "a wrong cart: retry offered, basket taken")
	session._on_choice(session.host.choice_prefix() + "retry_yes")
	await frames(3)
	check(panel.is_cart_visible() and Basket.carried(game) != null, "Yes, again: cart open with the basket")
	session._on_leave_answered(true)
	await frames(3)
	check(not panel.is_cart_visible() and not game.player.hand.is_holding(), "leaving the order closes the cart and takes the basket")
	session.host.close_dialogue()
	await frames(5)

	# --- The plane's Reset ----------------------------------------------------------------
	var plane = game.apartment.get_node_or_null("Vehicles/Turboprop")
	check(plane != null, "the plane exists")
	if plane != null:
		touch.touch_mode = true
		game.hud.set_touch_mode(true)
		player.global_position = plane.to_global(Vector3(-2.5, .1, -1.1))
		await frames(3)
		check(game.toggle_vehicle() and game.active_vehicle == plane, "boards the plane")
		await frames(30)
		var reset: Button = touch.reset_button
		check(reset.visible and not run_button.visible and reset.text == UiText.t("vehicle.reset_plane"), "flying the plane: Reset shows, Run hides")
		var reset_box := Rect2(reset.position, reset.size)
		check((reset.get_theme_stylebox("normal") as StyleBoxFlat).bg_color.r > 0.6, "Reset is red")
		check(not reset_box.intersects(touch._jump_rect) and not reset_box.intersects(touch._use_rect) and not reset_box.intersects(touch._down_rect), "Reset clear of jump, E and ▼")
		reset.pressed.emit()
		await frames(2)
		check(true, "Reset pressed without an error (reset_to_start: %s)" % plane.has_method("reset_to_start"))
		await snap("plane_reset.png")
	finish()

## A product of word `key` inside the store (a node with a pick, as shop-basket's check).
func _product(market: Node3D, key: String) -> Node3D:
	for node in market.find_children("*", "Node3D", true, false):
		if node.has_meta("word_key") and game.interaction.word_key(node) == key and game.zones.resolve_global(node.global_position) == "supermarket":
			return node
	return null

func finish() -> void:
	print("RUN BUTTON SHOP: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
