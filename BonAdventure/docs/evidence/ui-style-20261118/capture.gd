extends SceneTree
## Rendered views of the UI art style, phase 1 (user, 18 Nov 2026; docs/guides/UI_STYLE.md):
## the title page with Play, the saved players (Leo learning Chinese), the character grid, the
## language page (also with Just explore! ticked and at landscape-phone size 844 x 390), the
## delete question, the loading screen, and the dialogue box (Bruno's line with a Yes! reply)
## and quit card over a town picture. Overwrites the PNGs in this folder. Needs graphics and an
## isolated HOME (it creates a profile):
## HOME=<scratch>/home godot --path . --resolution 1280x720 --script res://docs/evidence/ui-style-20261118/capture.gd
const AppScreens := preload("res://scripts/ui/app_screens.gd")
const LoadingScreen := preload("res://scripts/ui/loading_screen.gd")
const ShopOrderPanel := preload("res://scripts/ui/shop_order_panel.gd")
const ProfileManager := preload("res://scripts/core/profile_manager.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")
const CjkFont := preload("res://scripts/ui/cjk_font.gd")
const OUT := "res://docs/evidence/ui-style-20261118/"

func _initialize() -> void:
	run.call_deferred()

func shot(name: String) -> void:
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print("captured ", name)

func run() -> void:
	if FileAccess.file_exists("user://profiles/index.json"):
		print("capture: refusing to run, profiles exist (use an isolated HOME)")
		quit(1)
		return
	CjkFont.install()
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var screens = AppScreens.new()
	layer.add_child(screens)
	screens.show_splash()
	await shot("splash")
	screens.show_new_profile()
	await shot("avatar")
	screens._show("languages")
	await shot("languages")
	screens._draft.explore = true
	screens._pick_language("foreign", "zh")
	await shot("languages_explore")
	var laptop := root.size
	root.size = Vector2i(844, 390)
	screens._draft.explore = false
	screens._pick_language("foreign", "es")
	await shot("languages_phone")
	root.size = laptop
	var manager = ProfileManager.shared()
	var id: String = manager.create("Leo", "Leo", "leo")
	manager.select(id)
	GameSettings.shared().set_languages("en", "zh")
	screens.show_profiles()
	await shot("profiles")
	screens._delete_id = id
	screens._show("delete")
	await shot("delete")
	layer.queue_free()
	var loading = LoadingScreen.new()
	root.add_child(loading)
	loading.set_text("Getting everything ready…")
	loading.set_progress(0.82)
	for i in 120:
		await process_frame
	await shot("loading")
	loading.queue_free()
	var back := TextureRect.new()
	back.texture = load("res://assets/ui/app/shot_2.webp")
	back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	back.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	var ui_layer := CanvasLayer.new()
	root.add_child(ui_layer)
	ui_layer.add_child(back)
	var panel = ShopOrderPanel.new()
	ui_layer.add_child(panel)
	panel.closable = false
	panel.show_dialogue("Bruno", {"foreign": "Good morning! Ready for an adventure?", "native": "Good morning! Ready for an adventure?", "narration": true}, [{"id": "yes", "label": {"foreign": "Yes!", "native": "Yes!"}, "icon": "play"}])
	await shot("dialogue")
	panel.closable = true
	panel.show_dialogue("Ana", {"foreign": "¿Quieres una manzana o dos plátanos?", "native": "Do you want an apple or two bananas?", "terms": []}, [{"id": "a", "label": {"foreign": "Una manzana", "native": "An apple"}, "icon": "check"}, {"id": "b", "label": {"foreign": "Dos plátanos", "native": "Two bananas"}}])
	await shot("dialogue_choices")
	panel.hide_dialogue()
	panel.show_quit({"foreign": "¿Quieres salir del juego?", "native": "Do you want to leave the game?"}, {"foreign": "Salir", "native": "Leave"}, {"foreign": "Quedarme", "native": "Stay"})
	await shot("quit")
	SaveStore.remove_tree("user://profiles")
	quit(0)
