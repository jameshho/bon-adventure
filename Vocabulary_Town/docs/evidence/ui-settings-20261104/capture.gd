extends SceneTree
## UI Stage 1 views (4 Nov 2026); graphics required, isolated HOME (Main saves progress and
## settings; the script removes its user://settings.json at the end):
## HOME=<scratch>/home VT_FOCUS=supermarket,hospital godot --path . --resolution 1600x1000 --script res://docs/evidence/ui-settings-20261104/capture.gd
const GameSettings := preload("res://scripts/core/game_settings.gd")
func _initialize(): run.call_deferred()

func shot(name: String) -> void:
	for i in range(10): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/ui-settings-20261104/" + name + ".png")

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
	var settings = GameSettings.shared()
	var box = game.shop_panel
	var cashier_session = game.get_node("CashierSession_supermarket")
	cashier_session.set_process(false)
	game.player.global_position = cashier_session.cashier.global_position - cashier_session.cashier.global_basis.z * 3.0
	game.interaction.clerk_activated.emit(cashier_session.cashier)
	await shot("dialogue-foreign")
	box.toggle_translation()
	await shot("dialogue-translated")
	box.toggle_translation()
	settings.set_display(GameSettings.BOTH)
	await shot("dialogue-both")
	settings.set_display(GameSettings.NATIVE)
	await shot("dialogue-native")
	settings.set_display(GameSettings.FOREIGN)
	box.choice_pressed.emit("cashier_count")
	await shot("money-empty")
	game.money_panel.add_piece("bill_20")
	game.money_panel.add_piece("coin_25")
	game.money_panel.toggle_translation()
	await shot("money-translated")
	game.money_panel.toggle_translation()
	game.money_panel.close_requested.emit()
	await shot("money-quit")
	box.choice_pressed.emit("cashier_leave")
	box.hide_dialogue()
	await process_frame
	game.open_settings()
	await shot("settings")
	game.settings_panel.close()
	var family = game.get_node("FamilySession")
	family.open_game()
	await shot("family-question")
	family.close_game()
	box.hide_dialogue()
	game.hud.toggle_help()
	await shot("help-display-mode")
	game.hud.toggle_help()
	settings.set_languages("en", "es")
	settings.set_display(GameSettings.FOREIGN)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))
	print("UI SETTINGS CAPTURE done")
	quit()
