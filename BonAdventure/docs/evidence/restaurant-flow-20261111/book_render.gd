extends SceneTree
## Standalone render of the menu book (no town): cover and desserts, after the 11 Nov 2026 layout
## fix. OUT=<folder> godot --path . --resolution 1400x900 --script res://docs/evidence/restaurant-flow-20261111/book_render.gd
const Orders := preload("res://scripts/learning/restaurant_orders.gd")
const Currency := preload("res://scripts/learning/currency.gd")
func _initialize(): run.call_deferred()
func run():
	var lexicon = preload("res://scripts/language/lexicon.gd").shared()
	var orders = Orders.new()
	orders.new_menu()
	var bg := ColorRect.new(); bg.color = Color("335566"); bg.anchor_right = 1; bg.anchor_bottom = 1
	root.add_child(bg)
	var book = preload("res://scripts/ui/restaurant_menu_book.gd").new()
	root.add_child(book)
	var courses := []
	for id in Orders.courses():
		courses.append({"id": id, "title": lexicon.line("restaurant.course_" + str(id))})
	var menu := {}
	for c in orders.menu:
		menu[c] = orders.menu[c].map(func(e): return {"id": str(e.id), "name": {"foreign": lexicon.word(str(e.word), lexicon.foreign), "native": lexicon.word(str(e.word), lexicon.native)}, "price": Currency.usd(int(e.price)), "art": e.art, "taste": e.get("taste", {}), "temperature": int(e.temperature), "has": e.get("has", [])})
	var tastes := []
	for id in Orders.taste_ids(): tastes.append([id, str(Orders.properties().taste[id].color)])
	var data := {"title": lexicon.line("restaurant.title"), "subtitle": lexicon.line("restaurant.menu_of_day"), "title_short": lexicon.line("posters.menu_title"), "hint": lexicon.line("restaurant.turn_hint"), "translate": lexicon.line("common.show_translation"), "courses": courses, "menu": menu, "schema": {"tastes": tastes, "temperature_colors": Orders.properties().temperature.colors, "tags": Orders.tag_ids("ingredient")}}
	book.open(data)
	for i in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("OUT") + "/book-cover.png")
	book.turn_to(3)
	for i in 40: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("OUT") + "/book-desserts.png")
	quit()
