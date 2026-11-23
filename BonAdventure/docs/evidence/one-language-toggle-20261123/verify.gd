extends SceneTree
## One language toggle (23 Nov 2026): every panel built on translate_button.gd hides its own
## EN bubble and follows the HUD's top-right EN badge (GameSettings.peeking).
## Run: HOME=<tmp> godot --headless --path . --script res://docs/evidence/one-language-toggle-20261123/verify.gd
const GameSettings := preload("res://scripts/core/game_settings.gd")
const TranslateButton := preload("res://scripts/ui/translate_button.gd")
const PANELS := ["mahjong_panel", "mahjong_lesson_panel", "money_panel", "family_panel", "restaurant_panel",
	"restaurant_menu_book", "flight_panel", "mystery_card", "detective_card", "warehouse_task_card",
	"outfit_picker", "grammar_card", "shop_order_panel"]

var failures := 0

func _check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func _bubbles(node: Node, out: Array) -> Array:
	if node.get_script() == TranslateButton:
		out.append(node)
	for child in node.get_children():
		_bubbles(child, out)
	return out

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var settings = GameSettings.shared()
	settings.display = GameSettings.FOREIGN
	for name in PANELS:
		var panel: Node = load("res://scripts/ui/%s.gd" % name).new()
		root.add_child(panel)
		await _frames(3)
		var bubbles := _bubbles(panel, [])
		_check(not bubbles.is_empty(), "%s: has a bubble" % name)
		_check(bubbles.all(func(b: Button) -> bool: return not b.visible), "%s: no EN bubble of its own shown" % name)
		settings.set_peek(true)
		await _frames(3)
		_check(bool(panel.get("show_native")), "%s: top-right EN held -> native" % name)
		settings.set_peek(false)
		await _frames(3)
		_check(not bool(panel.get("show_native")), "%s: EN released -> foreign again" % name)
		panel.queue_free()
		await _frames(1)
	print("ONE LANGUAGE TOGGLE CHECK: %d panels; %d failures" % [PANELS.size(), failures])
	quit(1 if failures else 0)
