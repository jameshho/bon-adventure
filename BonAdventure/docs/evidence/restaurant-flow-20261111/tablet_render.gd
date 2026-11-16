extends SceneTree
## Standalone render of the order tablet (no town) with a three-course order and the
## translation on, Spanish and Chinese (the requests on the order slip since 11 Nov 2026): the order text must fit without pushing Send order off
## the tablet, and the dish list keeps its width (11 Nov 2026, second request). Changes the
## language setting: run with an isolated HOME (README).
## HOME=<scratch>/home OUT=<folder> godot --path . --resolution 1400x900 --script res://docs/evidence/restaurant-flow-20261111/tablet_render.gd
const Orders := preload("res://scripts/learning/restaurant_orders.gd")
const Currency := preload("res://scripts/learning/currency.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
func _initialize(): run.call_deferred()

func line(lexicon, ref: Dictionary) -> Dictionary:
	return {"foreign": lexicon.text(ref, lexicon.foreign), "native": lexicon.text(ref, lexicon.native)}

func run():
	var lexicon = preload("res://scripts/language/lexicon.gd").shared()
	var bg := ColorRect.new(); bg.color = Color("335566"); bg.anchor_right = 1; bg.anchor_bottom = 1
	root.add_child(bg)
	var panel = preload("res://scripts/ui/restaurant_panel.gd").new()
	root.add_child(panel)
	var failures := 0
	for lang in ["es", "zh"]:
		GameSettings.shared().set_languages("en", lang)
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
		panel.show_native = true
		panel.open({"title": lexicon.line("restaurant.title"), "translate": lexicon.line("common.show_translation"),
			"speaker": {"foreign": "Cocodrilo", "native": "Cocodrilo"}, "species": "crocodile",
			"order": line(lexicon, Orders.intro_ref(wanted)), "requests": by_course,
			"wanted": wanted, "hint": lexicon.line("restaurant.pick_hint"), "pick_course": lexicon.line("restaurant.pick_course"),
			"choose": lexicon.line("restaurant.choose"), "send": lexicon.line("restaurant.send"), "sent": lexicon.line("restaurant.sent"),
			"close": lexicon.line("restaurant.close_tablet"), "finish": lexicon.line("restaurant.finish"),
			"courses": courses, "menu": menu,
			"schema": {"tastes": tastes, "temperature_colors": Orders.properties().temperature.colors, "tags": Orders.tag_ids("ingredient")}})
		panel.inspect(str(requests[0].target))
		panel.choose()
		panel.inspect(str(requests[1].target))
		for i in 30: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("OUT") + "/tablet-three-courses-" + lang + ".png")
		var tablet: Control = panel.get_node("Tablet")
		var send: Control = panel._send
		var fits: bool = send.get_global_rect().end.y <= tablet.get_global_rect().end.y and tablet.size.y <= panel.size.y * 0.911
		var list_width: float = panel._list_page.size.x
		print(("PASS" if fits else "FAIL") + ": %s Send order inside the tablet (order text scale %.2f)" % [lang, panel._bubble_scale])
		print(("PASS" if list_width > 250.0 else "FAIL") + ": %s dish list keeps its width (%d px)" % [lang, list_width])
		failures += (0 if fits else 1) + (0 if list_width > 250.0 else 1)
		var rows_fit := true
		for button in panel._list.get_children():
			for part in button.get_child(0).get_children():
				rows_fit = rows_fit and part.get_combined_minimum_size().y <= button.size.y
		print(("PASS" if rows_fit else "FAIL") + ": %s every dish row holds its wrapped name" % lang)
		failures += 0 if rows_fit else 1
	GameSettings.shared().set_languages("en", "es")
	quit(1 if failures > 0 else 0)
