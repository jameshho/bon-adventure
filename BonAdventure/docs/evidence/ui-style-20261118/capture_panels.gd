extends SceneTree
## Rendered views of the UI art style, phase 2 panels (user, 18 Nov 2026; docs/guides/UI_STYLE.md):
## the clock panel, the game picker, the cart with a shopping list, the money and family games, the
## warehouse / mystery / detective / grammar cards, an instruction strip and the keys cue, over the
## real town. Overwrites the PNGs it names in this folder. Needs graphics and an isolated HOME:
## HOME=<scratch>/home VT_FOCUS=supermarket,school VT_SPAWN=none godot --path . --resolution 1280x720 --script res://docs/evidence/ui-style-20261118/capture_panels.gd
const OUT := "res://docs/evidence/ui-style-20261118/"
const InstructionStrip := preload("res://scripts/ui/instruction_strip.gd")
const TutorialCue := preload("res://scripts/ui/tutorial_cue.gd")

func _initialize() -> void:
	run.call_deferred()

func shot(name: String) -> void:
	for i in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print("captured ", name)

func line(foreign: String, native: String) -> Dictionary:
	return {"foreign": foreign, "native": native}

func run() -> void:
	if DisplayServer.get_name() == "headless" or FileAccess.file_exists("user://profiles/index.json"):
		print("capture: needs graphics and an isolated HOME")
		quit(1)
		return
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	for i in 30:
		await process_frame
	# Clock panel, strip and keys cue together.
	game.day_clock.open()
	var strip = InstructionStrip.new()
	root.add_child(strip)
	strip.show_text("Find BonBon's two friends", "1/2")
	var cue = TutorialCue.new()
	game.hud.ui_root.add_child(cue)
	cue.show_cue("move", false)
	await shot("panel_clock_strip")
	game.day_clock.close()
	strip.clear()
	cue.queue_free()
	# Cart with a shopping list.
	game.shop_panel.show_cart({"list_title": line("Lista", "List"), "cart_title": line("Carrito", "Cart"), "done": line("Pagar", "Pay"),
		"needed": [{"key": "apple", "foreign": "1 manzana", "native": "1 apple", "done": true}, {"key": "banana", "foreign": "2 plátanos", "native": "2 bananas", "done": false}],
		"cart": [{"key": "apple", "foreign": "la manzana", "native": "the apple"}]})
	await shot("panel_cart")
	game.shop_panel.hide_cart()
	# Game picker.
	game.game_launcher.open()
	await shot("panel_launcher")
	game.game_launcher.close()
	# Money game (the cashier's lines, opened directly).
	game.money_panel.open({"request": line("Son 3,25 dólares, por favor.", "That's $3.25, please."), "tray_title": line("Tu mano", "Your hand"),
		"bills": line("Billetes", "Bills"), "coins": line("Monedas", "Coins"), "total": line("Total", "Total"), "submit": line("Pagar", "Hand over"),
		"clear": line("Borrar", "Clear"), "close": line("Salir", "Leave"), "translate": line("Traducir", "Translate")})
	game.money_panel.add_piece("bill_1")
	game.money_panel.add_piece("coin_25")
	await shot("panel_money")
	game.money_panel.hide_panel()
	# Family game.
	var family = game.get_node_or_null("FamilySession")
	if family != null:
		family.open_game()
		await shot("panel_family")
		family.close_game() if family.has_method("close_game") else null
		game.shop_panel.hide_dialogue()
	# Cards over the town.
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var warehouse = preload("res://scripts/ui/warehouse_task_card.gd").new()
	layer.add_child(warehouse)
	warehouse.open(line("Tarea 2 de 5", "Task 2 of 5"), line("Lleva la caja azul a la estantería.", "Take the blue box to the shelf."), line("Traducir", "Translate"), 1, 5)
	var detective = preload("res://scripts/ui/detective_card.gd").new()
	layer.add_child(detective)
	detective.open(line("Pista 1 de 3", "Clue 1 of 3"), line("El ladrón lleva un sombrero rojo.", "The thief wears a red hat."), line("Traducir", "Translate"), 0, 3,
		[{"id": "lens", "label": line("Lupa", "Magnifier"), "icon": "search"}, {"id": "ask", "label": line("Preguntar", "Ask"), "icon": "question"}], line("¡Es él!", "It's him!"))
	await shot("panel_cards")
	warehouse.queue_free()
	detective.queue_free()
	var mystery = preload("res://scripts/ui/mystery_card.gd").new()
	layer.add_child(mystery)
	mystery.open(line("Puerta 2 de 4", "Door 2 of 4"), line("Busca la puerta de la cocina.", "Find the kitchen door."), line("Traducir", "Translate"), 1, 4)
	var grammar = preload("res://scripts/ui/grammar_card.gd").new()
	layer.add_child(grammar)
	grammar.open(line("Pregunta 3 de 6", "Question 3 of 6"), line("Confirmar", "Confirm"), line("Traducir", "Translate"), 2, 6)
	await shot("panel_cards2")
	print("UI STYLE PANELS CAPTURE done")
	quit(0)
