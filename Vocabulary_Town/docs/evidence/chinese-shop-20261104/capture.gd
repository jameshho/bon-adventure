extends SceneTree
## Stage 4d batch 1 views (4 Nov 2026): the cashier's money panel and the supermarket order
## with Chinese as the foreign language (a draft language, so the Lexicon is set directly).
## Graphics required, isolated HOME (Main saves progress):
## HOME=<scratch>/home2 VT_FOCUS=supermarket godot --path . --resolution 1600x1000 --script res://docs/evidence/chinese-shop-20261104/capture.gd
const GameSettings := preload("res://scripts/core/game_settings.gd")
func _initialize(): run.call_deferred()

func shot(name: String) -> void:
	for i in range(10): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/chinese-shop-20261104/" + name + ".png")

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
	var lex = preload("res://scripts/language/lexicon.gd").shared()
	lex.native = "en"
	lex.foreign = "zh"
	# The languages Main last saw, so nothing is taken as a language change (which ends the game).
	game.ui_languages = "en/zh"
	game.progress_language = "zh"
	var box = game.shop_panel
	var cashier = game.get_node("CashierSession_supermarket")
	var shop = game.get_node("ShopSession_supermarket")
	cashier.set_process(false)
	shop.set_process(false)
	game.player.global_position = cashier.cashier.global_position - cashier.cashier.global_basis.z * 3.0
	cashier.offered = true
	game.interaction.clerk_activated.emit(cashier.cashier)
	box.choice_pressed.emit("cashier_count")
	game.money_panel.add_piece("bill_20")
	game.money_panel.show_native = true
	game.money_panel.refresh_display()
	await shot("money")
	var request: String = game.money_panel._request_label.text + " | " + game.money_panel._reading_label.text
	cashier.end_activity()
	box.dialogue_closed.emit()
	shop.needs_help = true
	game.interaction.clerk_activated.emit(shop.clerk)
	box.choice_pressed.emit("yes")
	await shot("order")
	print("CHINESE SHOP CAPTURE done | ", request, " | ", box.foreign_label.text, " | ", box.reading_label.text)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))
	quit()
