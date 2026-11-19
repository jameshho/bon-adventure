extends SceneTree
## Rendered views of the UI art style (user, 18 Nov 2026; docs/guides/UI_STYLE.md): the money panel
## rebuilt to the user's mockup (design-references/ui/money-panel.webp), at laptop and landscape-phone
## size, then the outfit picker. Overwrites the PNGs it names in this
## folder. Needs graphics and an isolated HOME:
## HOME=<scratch>/home VT_FOCUS=supermarket VT_SPAWN=none godot --path . --resolution 1280x720 --script res://docs/evidence/ui-style-20261118/capture_money.gd
const OUT := "res://docs/evidence/ui-style-20261118/"
const PlushCostume := preload("res://scripts/characters/plush_costume.gd")

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
	# In a game the HUD's buttons are hidden (the session does this; here it is opened directly).
	game.hud.in_minigame = true
	game.money_panel.open({"request": line("Son 3,25 dólares, por favor.", "That's $3.25, please."), "tray_title": line("Tu mano", "Your hand"),
		"bills": line("Billetes", "Bills"), "coins": line("Monedas", "Coins"), "total": line("Total", "Total"), "submit": line("Pagar", "Hand over"),
		"clear": line("Borrar", "Clear"), "close": line("Salir", "Leave"), "translate": line("Traducir", "Translate")})
	await shot("panel_money_empty")
	game.money_panel.add_piece("bill_1")
	game.money_panel.add_piece("coin_25")
	await shot("panel_money")
	var laptop := root.size
	root.size = Vector2i(844, 390)
	await shot("panel_money_phone")
	root.size = laptop
	game.money_panel.hide_panel()
	var picker = preload("res://scripts/ui/outfit_picker.gd").new()
	var layer := CanvasLayer.new()
	root.add_child(layer)
	layer.add_child(picker)
	var ids: Array = PlushCostume.outfit_ids()
	picker.open(ids, str(ids[0]))
	await shot("panel_outfit")
	print("UI STYLE MONEY CAPTURE done")
	quit(0)
