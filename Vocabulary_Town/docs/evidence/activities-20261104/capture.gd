extends SceneTree
## UI Stage 2 views (4 Nov 2026): the progress bar in the money and family panels, the
## completion thanks and the "finish the other task first" refusal. Graphics required,
## isolated HOME (Main saves progress):
## HOME=<scratch>/home VT_FOCUS=supermarket,hospital godot --path . --resolution 1600x1000 --script res://docs/evidence/activities-20261104/capture.gd
const Board := preload("res://scripts/learning/activity_board.gd")
func _initialize(): run.call_deferred()

func shot(name: String) -> void:
	for i in range(10): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/activities-20261104/" + name + ".png")

func run():
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	await process_frame
	var board = Board.shared()
	var box = game.shop_panel
	var cashier = game.get_node("CashierSession_supermarket")
	var shop = game.get_node("ShopSession_supermarket")
	cashier.set_process(false)
	shop.set_process(false)
	game.player.global_position = cashier.cashier.global_position - cashier.cashier.global_basis.z * 3.0
	game.interaction.clerk_activated.emit(cashier.cashier)
	board._done["cashier_supermarket"] = 2
	box.choice_pressed.emit("cashier_count")
	await shot("money-progress")
	board._done["cashier_supermarket"] = 4
	var left: int = cashier.request_cents
	var ordered: Array = preload("res://scripts/learning/currency.gd").DENOMS.duplicate()
	ordered.sort_custom(func(a, b): return a.cents > b.cents)
	for d in ordered:
		while left >= int(d.cents):
			game.money_panel.add_piece(d.id)
			left -= int(d.cents)
	game.money_panel._submit_button.pressed.emit()
	await shot("cashier-complete")
	box.dialogue_closed.emit()
	cashier.offered = true
	# A grocery order is running; the cashier refuses.
	shop.needs_help = true
	game.interaction.clerk_activated.emit(shop.clerk)
	box.choice_pressed.emit("yes")
	box.dialogue_closed.emit()
	game.interaction.clerk_activated.emit(cashier.cashier)
	await shot("finish-first")
	box.dialogue_closed.emit()
	shop._on_quit_answered(true)
	box.dialogue_closed.emit()
	# The family game at 7/20.
	var family = game.get_node("FamilySession")
	game.player.global_position = family.doctor.global_position - family.doctor.global_basis.z * 3.0
	family._process(.1)
	family.open_game()
	board._done["family_dr_li"] = 6
	family._on_answer(str(family.question.answer))
	await shot("family-progress")
	print("ACTIVITIES CAPTURE done")
	quit()
