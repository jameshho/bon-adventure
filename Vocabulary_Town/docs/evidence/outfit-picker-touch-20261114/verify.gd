extends SceneTree
## Outfit picker for touch (14 Nov 2026, user: not mobile friendly; guide: docs/guides/TOWN_DESIGN_BRIEF.md
## "Fitting room outfit picker"): sits BonBon in a clothing-store cabin and checks the paged picker
## (no scroll bar, ‹ / › page buttons, a swipe turns the page without trying an outfit on, A / D
## shows the selected outfit's page, a card on a later page dresses her), that the touch joystick
## and E / jump buttons hide while it shows, and that it fits a phone-sized window.
## With a window it saves laptop.png (1200 × 900) and phone.png (844 × 390) to this folder.
## Uses Main and writes user://settings.json: run with an isolated HOME (README).
## HOME=<scratch>/home VT_FOCUS=clothing VT_SPAWN=none godot --path . --resolution 1200x900 --script res://docs/evidence/outfit-picker-touch-20261114/verify.gd
const PlushCostume := preload("res://scripts/characters/plush_costume.gd")
const BoothScript := preload("res://scripts/world/fitting_booth.gd")
const TouchControls := preload("res://scripts/ui/touch_controls.gd")
const DIR := "res://docs/evidence/outfit-picker-touch-20261114/"
var failures := 0
var checks := 0
var game
var booth
var seat: Dictionary

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

func frames(n: int) -> void:
	for i in range(n): await process_frame

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event)

func mouse_button(at: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = at
	event.global_position = at
	root.push_input(event)

func mouse_move(at: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = at
	event.global_position = at
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(event)

func snap(file: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await frames(8)
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(DIR + file))

func worn() -> String:
	var costume: Node = game.player.get_node("Visual/BonBon").get_node_or_null("Costume")
	if costume == null or costume.is_queued_for_deletion():
		return ""
	return str(costume.outfit)

func shown_cards(picker) -> Array:
	return picker.ids.filter(func(id) -> bool: return picker._cards[id].button.visible)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(10)
	for node in game.apartment.find_children("*", "Node3D", true, false):
		if node.get_script() == BoothScript:
			booth = node
			break
	check(booth != null, "a fitting cabin is in the clothing store")
	if booth == null:
		finish()
		return
	for s in game.seating.seats:
		if s.node == booth.pouf:
			seat = s
	game.player.global_position = seat.point + seat.forward * 0.9
	game.player.velocity = Vector3.ZERO
	await frames(4)
	check(game.interaction.activate_focus(), "sits on the cabin pouf")
	for i in range(240):
		await process_frame
		if booth.active: break
	check(booth.active, "picker opens once seated")
	await frames(30)
	var picker = BoothScript.picker
	var ids := PlushCostume.outfit_ids()
	var graphics := DisplayServer.get_name() != "headless"

	# Paging instead of a scroll bar.
	check(picker.find_children("*", "ScrollContainer", true, false).is_empty(), "no scroll container")
	check(picker.per_page >= 1 and shown_cards(picker).size() == mini(picker.per_page, ids.size()), "one page of cards shows (%d per page)" % picker.per_page)
	check(picker.page == 0 and picker.prev_button.disabled, "starts on the first page, ‹ disabled")
	var pages: int = picker.page_count()
	check(pages > 1 and not picker.next_button.disabled and picker.dots_label.visible, "%d pages, › enabled, dots shown" % pages)
	picker.next_button.pressed.emit()
	await frames(2)
	check(picker.page == 1 and shown_cards(picker)[0] == ids[picker.per_page], "› turns to page 2")
	var last: String = ids[ids.size() - 1]
	picker._cards[last].button.pressed.emit()
	await frames(2)
	check(worn() == last and picker.page == pages - 1, "a card on the last page dresses her (%s)" % last)
	key(KEY_D)
	await frames(2)
	check(worn() == "" and picker.page == 0, "D wraps to her own look and shows page 1")
	key(KEY_A)
	await frames(2)
	check(worn() == last and picker.page == pages - 1, "A shows the last outfit's page")

	if graphics:
		await snap("laptop.png")
		# A swipe right on the cards turns back a page and tries nothing on.
		picker._show_page(1)
		await frames(2)
		var rect: Rect2 = picker.row.get_global_rect()
		var from := rect.get_center()
		var before := worn()
		mouse_button(from, true)
		for step in range(1, 9):
			mouse_move(from + Vector2(step * 20.0, 0.0))
			await process_frame
		mouse_button(from + Vector2(160.0, 0.0), false)
		await frames(3)
		check(picker.page == 0, "swiping right turns back a page")
		check(worn() == before, "a swipe does not try an outfit on")
		# A plain click on a card still tries it on.
		var first: String = shown_cards(picker)[1]
		var at: Vector2 = picker._cards[first].button.get_global_rect().get_center()
		mouse_button(at, true)
		await process_frame
		mouse_button(at, false)
		await frames(3)
		check(worn() == first, "a click on a card tries it on (%s)" % first)

	# Touch controls leave the picker to the GUI.
	var touch: Control
	for node in game.hud.ui_root.get_children():
		if node.get_script() == TouchControls:
			touch = node
	check(picker.card.is_in_group(TouchControls.TOUCH_HIDE), "picker card hides the touch controls")
	if touch != null and graphics:
		touch.touch_mode = true
		await frames(3)
		check(not touch.visible, "joystick and E / jump hidden while the picker shows")
		# Phone landscape.
		DisplayServer.window_set_size(Vector2i(844, 390))
		await frames(20)
		var view: Vector2 = root.get_visible_rect().size
		var box: Rect2 = picker.card.get_global_rect()
		check(Rect2(Vector2.ZERO, view).encloses(box), "picker fits a 844 × 390 window")
		check(box.size.y <= view.y * 0.5, "picker takes at most half the phone screen's height (%d of %d)" % [box.size.y, view.y])
		check(picker._cards[shown_cards(picker)[0]].button.size.y >= 44.0, "cards are at least 44 px tall on the phone")
		check(picker.keep_button.size.y >= 36.0 and picker.prev_button.size.x >= 36.0, "Keep and ‹ are finger-sized on the phone")
		await snap("phone.png")
		DisplayServer.window_set_size(Vector2i(1200, 900))
		await frames(10)

	picker.cancel_button.pressed.emit()
	for i in range(240):
		await process_frame
		if not booth.active: break
	check(worn() == "" and not picker.visible, "Cancel restores her own look and closes")
	if touch != null and graphics:
		await frames(30)
		check(touch.visible, "touch controls come back after leaving the cabin")
	finish()

func finish() -> void:
	print("outfit picker touch: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
