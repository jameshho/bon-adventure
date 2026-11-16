extends SceneTree
## Fitting room outfit picker (9 Nov 2026; guide: docs/guides/TOWN_DESIGN_BRIEF.md "Fitting room outfit
## picker"): sits BonBon in a clothing-store cabin, opens the picker, tries outfits by click and by
## A / D, cancels (her outfit comes back), keeps one (saved to settings.json), leaves with E
## (the kept one stays) and reloads the saved setting. With a window it also saves three views
## to this folder (picker.png, keyboard.png, walk-out.png).
## Uses Main and writes user://settings.json: run with an isolated HOME (README).
## HOME=<scratch>/home VT_FOCUS=clothing VT_SPAWN=none godot --path . --resolution 1200x900 --script res://docs/evidence/fitting-room-20261109/verify.gd
const GameSettings := preload("res://scripts/core/game_settings.gd")
const PlushCostume := preload("res://scripts/characters/plush_costume.gd")
const BoothScript := preload("res://scripts/world/fitting_booth.gd")
const DIR := "res://docs/evidence/fitting-room-20261109/"
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

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event)

func frames(n: int) -> void:
	for i in range(n): await process_frame

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

func sleeves() -> int:
	var count := 0
	for arm in ["Arm", "Arm_2"]:
		for child in game.player.get_node("Visual/BonBon/" + arm).get_children():
			if child.has_meta("bonbon_costume_sleeve") and not child.is_queued_for_deletion():
				count += 1
	return count

## Sleeves sit at the shoulders in BonBon's space (9 Nov 2026: they used to drop under her body
## and show between her feet while walking).
func sleeves_at_shoulders() -> bool:
	var bonbon: Node3D = game.player.get_node("Visual/BonBon")
	var found := 0
	for arm in ["Arm", "Arm_2"]:
		for child in bonbon.get_node(arm).get_children():
			if not child.has_meta("bonbon_costume_sleeve") or child.is_queued_for_deletion(): continue
			var box: AABB = bonbon.global_transform.affine_inverse() * child.global_transform * child.get_aabb()
			if box.position.y < 0.4 or absf(box.get_center().x) < 0.4: return false
			found += 1
	return found == 2

func sit() -> void:
	game.player.global_position = seat.point + seat.forward * 0.9
	game.player.velocity = Vector3.ZERO
	await frames(4)
	check(game.interaction.activate_focus(), "sits on the cabin pouf")
	for i in range(240):
		await process_frame
		if booth.active: break
	check(booth.active, "picker opens once seated")

func wait_standing() -> void:
	for i in range(240):
		await process_frame
		if not game.player.seated and not game.player.sit_transition: break
	await frames(4)

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
	check(not seat.is_empty(), "the cabin pouf is a seat")
	if seat.is_empty():
		finish()
		return
	check(GameSettings.shared().outfit == "" and worn() == "", "starts in BonBon's own look")

	# 1. Click a card: she is dressed at once; Cancel puts her own look back.
	await sit()
	var picker = BoothScript.picker
	var ids := PlushCostume.outfit_ids()
	check(picker.visible and picker._cards.size() == ids.size(), "picker shows one card per outfit (%d)" % ids.size())
	check(picker.selected == "", "own look outlined on entry")
	picker._cards["police"].button.pressed.emit()
	await frames(2)
	check(worn() == "police" and sleeves() == 2, "clicking Police dresses her, sleeves on the arms")
	check(picker.selected == "police", "Police card outlined")
	await frames(60)
	check(booth.preview != null and booth.preview.current, "mirror view camera is current")
	check(absf(angle_difference(game.player.get_node("Visual").rotation.y, PI)) < 0.05, "BonBon turned to face the mirror view")
	check(not booth._curtain_layers.is_empty() and booth._curtain_layers.keys().all(func(n): return n.layers == BoothScript.CURTAIN_LAYER) and booth.preview.cull_mask & BoothScript.CURTAIN_LAYER == 0, "curtain hidden from the mirror view only")
	await snap("picker.png")
	picker.cancel_button.pressed.emit()
	await frames(2)
	check(worn() == "" and sleeves() == 0, "Cancel restores her own look")
	await wait_standing()
	check(not picker.visible and not booth.active, "picker closes when she stands")
	check(GameSettings.shared().outfit == "", "Cancel saves nothing")
	await frames(30)
	check(game.player.camera.current and absf(game.player.get_node("Visual").rotation.y) < 0.05, "player camera and facing back after leaving")
	check(booth._curtain_layers.is_empty(), "curtain layers restored")

	# 2. A / D, then Keep: the outfit is saved and stays on as she walks out.
	await sit()
	key(KEY_D)
	await frames(2)
	check(worn() == ids[1], "D tries the next outfit")
	key(KEY_D)
	key(KEY_A)
	await frames(2)
	check(worn() == ids[1], "A steps back")
	picker._cards["pilot"].button.pressed.emit()
	await frames(30)
	await snap("keyboard.png")
	picker.keep_button.pressed.emit()
	await frames(2)
	check(GameSettings.shared().outfit == "pilot", "Keep saves the outfit")
	await wait_standing()
	await frames(30)
	await snap("walk-out.png")
	check(worn() == "pilot" and sleeves() == 2, "she walks out in the kept outfit")
	check(sleeves_at_shoulders(), "sleeves at the shoulders, not under her body")
	var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(GameSettings.PATH))
	check(saved is Dictionary and saved.get("outfit") == "pilot", "settings.json holds the outfit")

	# 3. Try something else and leave with E: the kept outfit comes back.
	await sit()
	check(picker.selected == "pilot", "the kept outfit is outlined on entry")
	picker._cards["chef"].button.pressed.emit()
	await frames(2)
	check(worn() == "chef", "trying Chef")
	key(KEY_E)
	await wait_standing()
	check(worn() == "pilot" and GameSettings.shared().outfit == "pilot", "leaving with E puts the kept outfit back")

	# 4. Esc acts as Cancel.
	await sit()
	picker._cards["doctor"].button.pressed.emit()
	await frames(2)
	key(KEY_ESCAPE)
	await wait_standing()
	check(worn() == "pilot" and not game.settings_panel.visible, "Esc cancels (no Settings) and restores")

	# 5. A restart reads it back; an unknown id loads as her own look.
	var fresh = GameSettings.new()
	fresh.load_saved()
	check(fresh.outfit == "pilot", "the saved outfit loads")
	var file := FileAccess.open(GameSettings.PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"outfit": "astronaut"}))
	file.close()
	fresh.load_saved()
	check(fresh.outfit == "", "an unknown outfit loads as her own look")
	PlushCostume.dress_player(game.player, "")
	await frames(2)
	check(worn() == "" and sleeves() == 0, "dress_player('') undresses")
	finish()

func finish() -> void:
	print("fitting room: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
