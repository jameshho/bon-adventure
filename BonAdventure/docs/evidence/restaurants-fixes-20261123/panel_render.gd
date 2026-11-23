extends SceneTree
## Standalone render of the Alta Cocina order tablet (no town), 23 Nov 2026: a three-course order
## with the translation on, after inspecting several dishes one after another and choosing two.
## "Choose this dish" and "Send order" must stay inside the tablet at a laptop window and a
## landscape phone. Changes the language setting: run with an isolated HOME (README).
##   HOME=<scratch>/home OUT=<folder> PREFIX=after godot --path . --resolution 1280x800 \
##     --script res://docs/evidence/restaurants-fixes-20261123/panel_render.gd
## Optional: PEEK=1 (the HUD EN badge held), GAME=1 (inside the game: VT_FOCUS=restaurants VT_SPAWN=none).
## Writes <PREFIX>-panel-<size>-<step>.png into OUT.
const Orders := preload("res://scripts/learning/restaurant_orders.gd")
const Currency := preload("res://scripts/learning/currency.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
func _initialize(): run.call_deferred()

func line(lexicon, ref: Dictionary) -> Dictionary:
	return {"foreign": lexicon.text(ref, lexicon.foreign), "native": lexicon.text(ref, lexicon.native)}

var failures := 0
var panel

func check(ok: bool, label: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + label)
	failures += 0 if ok else 1

func shot(name: String) -> void:
	for i in 12: await process_frame
	await RenderingServer.frame_post_draw
	var dir := OS.get_environment("OUT")
	if dir != "":
		root.get_texture().get_image().save_png(dir + "/%s-panel-%s.png" % [OS.get_environment("PREFIX"), name])

func inside(node: Control, label: String) -> void:
	var tablet: Control = panel.get_node("Tablet")
	var screen: Rect2 = root.get_visible_rect()
	var r: Rect2 = node.get_global_rect()
	check(node.is_visible_in_tree() and r.size.y > 20 and tablet.get_global_rect().encloses(r) and screen.encloses(tablet.get_global_rect()), "%s inside the tablet and the window (%s, tablet %s)" % [label, r, tablet.get_global_rect()])

func run():
	var lexicon = preload("res://scripts/language/lexicon.gd").shared()
	# GAME=1: the tablet inside the running game's HUD (its theme, font and the HUD buttons
	# around it; VT_FOCUS=restaurants), else alone on a plain background.
	if OS.get_environment("GAME") == "1":
		var game = load("res://scenes/main.tscn").instantiate()
		root.add_child(game)
		for i in 10: await process_frame
		panel = game.restaurant_panel
	else:
		var bg := ColorRect.new(); bg.color = Color("335566"); bg.anchor_right = 1; bg.anchor_bottom = 1
		root.add_child(bg)
		panel = preload("res://scripts/ui/restaurant_panel.gd").new()
		root.add_child(panel)
	GameSettings.shared().set_languages("en", "es")
	var orders = Orders.new()
	orders.new_menu()
	var wanted := ["starter", "main", "drink"]
	var requests: Array = wanted.map(func(c): return orders.make_order(c))
	var by_course := {}
	for r in requests:
		by_course[str(r.course)] = line(lexicon, Orders.order_ref(r))
	var courses := []
	for id in Orders.courses():
		courses.append({"id": id, "title": lexicon.line("restaurant.course_" + str(id))})
	var menu := {}
	for c in orders.menu:
		menu[c] = orders.menu[c].map(func(e): return {"id": str(e.id), "name": {"foreign": lexicon.word(str(e.word), lexicon.foreign), "native": lexicon.word(str(e.word), lexicon.native)}, "price": Currency.usd(int(e.price)), "art": e.art, "taste": e.get("taste", {}), "temperature": int(e.temperature), "has": e.get("has", [])})
	var tastes := []
	for id in Orders.taste_ids(): tastes.append([id, str(Orders.properties().taste[id].color)])
	var size := "%dx%d" % [root.get_visible_rect().size.x, root.get_visible_rect().size.y]
	# PEEK=1: the HUD's EN badge held (the translation on every line).
	GameSettings.shared().set_peek(OS.get_environment("PEEK") == "1")
	size += "-en" if GameSettings.shared().peeking else ""
	panel.open({"title": lexicon.line("restaurant.title"), "translate": lexicon.line("common.show_translation"),
		"speaker": {"foreign": "Cocodrilo", "native": "Cocodrilo"}, "species": "crocodile",
		"order": line(lexicon, Orders.intro_ref(wanted)), "requests": by_course,
		"wanted": wanted, "hint": lexicon.line("restaurant.pick_hint"), "pick_course": lexicon.line("restaurant.pick_course"),
		"choose": lexicon.line("restaurant.choose"), "send": lexicon.line("restaurant.send"), "sent": lexicon.line("restaurant.sent"),
		"close": lexicon.line("restaurant.close_tablet"), "finish": lexicon.line("restaurant.finish"),
		"courses": courses, "menu": menu,
		"schema": {"tastes": tastes, "temperature_colors": Orders.properties().temperature.colors, "tags": Orders.tag_ids("ingredient")}})
	# In the game: the HUD's EN badge stays visible and clickable beside the tablet.
	var hud_peek = panel.get_parent().get_node_or_null("Peek native") if OS.get_environment("GAME") == "1" else null
	if hud_peek != null:
		await shot(size + "-open")
		var tablet_rect: Rect2 = panel.get_node("Tablet").get_global_rect()
		var en: Rect2 = hud_peek.get_global_rect()
		check(not tablet_rect.intersects(en), size + " the tablet leaves the HUD's EN badge clear (%s, EN %s)" % [tablet_rect, en])
		check(not panel._has_point(en.get_center()), size + " a click on EN goes to the badge, not the tablet")
	# Several different dishes of the first course, one after another.
	for entry in menu["starter"]:
		panel.inspect(str(entry.id))
		await shot(size + "-starter-" + str(entry.id))
		inside(panel._pick_slot.get_child(0), size + " Choose this dish after " + str(entry.id))
	panel.choose()
	for entry in menu["main"]:
		panel.inspect(str(entry.id))
		await shot(size + "-main")
		inside(panel._pick_slot.get_child(0), size + " Choose this dish (main) after " + str(entry.id))
	panel.choose()
	for entry in menu["drink"].slice(0, 3):
		panel.inspect(str(entry.id))
	panel.choose()
	await shot(size + "-all-chosen")
	panel.show_tab("dessert")
	panel.inspect(str(menu["dessert"][0].id))
	await shot(size + "-not-ordered")
	inside(panel._pick_slot.get_child(0), size + " Choose this dish (disabled) for a course not ordered")
	check(panel._pick_slot.get_child(0).disabled, size + " Choose is disabled for a course not ordered")
	inside(panel._send, size + " Send order with three dishes chosen")
	# Holding the HUD's EN badge (GameSettings peek) switches the tablet to the native language.
	GameSettings.shared().set_peek(not GameSettings.shared().peeking)
	await shot(size + "-peek-toggled")
	check(panel.show_native == GameSettings.shared().peeking, size + " the tablet follows the EN badge")
	GameSettings.shared().set_peek(false)
	GameSettings.shared().set_languages("en", "es")
	quit(1 if failures > 0 else 0)
