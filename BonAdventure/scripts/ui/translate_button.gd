extends Button
## The "show translation" bubble of every dialogue and minigame panel (user decision, 4 Nov
## 2026): a speech bubble with the native language's badge (EN, ES, 中 — languages.json),
## outlined while the translation is hidden and filled while it is shown. Connect `pressed` to
## the panel's toggle as any Button.
## One language toggle (user, 17 Nov 2026; every panel since 23 Nov 2026): the bubble is never
## shown. The HUD's top-right EN badge (hold) or L, GameSettings.peeking, is the only toggle: while
## it is held the bubble presses itself so its panel shows the native language, and presses
## again when it is let go (_sync()). A panel that follows peek_changed itself (the dialogue box,
## the grammar card) sets follows_peek = false.
## While it shows the translation on screen it tells the practice tracker (practice_log.gd
## translation_shown: "" = the open question's words, or a word's `word_key`).
const GameSettings := preload("res://scripts/core/game_settings.gd")
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
const BonStyle := preload("res://scripts/ui/bon_style.gd")
# UI art style (18 Nov 2026): a blue bubble, outlined on light blue while hidden, filled while shown.
const EDGE := BonStyle.BLUE_BOTTOM
const FILL := BonStyle.BLUE_BOTTOM
const INK := Color.WHITE

var on := false
var factor := 1.0
## The badge drawn inside the bubble (the Button's own text stays empty: a script _draw runs
## after the Button's, so the box would cover it).
var badge := ""
## The word whose translation this bubble shows ("" = the whole question).
var word_key := ""
## Follow the HUD's hold-to-peek (see above).
var follows_peek := true

func _init() -> void:
	focus_mode = Control.FOCUS_NONE
	flat = true
	clip_text = false
	visible = false   # one toggle: the HUD's EN badge (refresh() keeps it hidden)

## `revealed`: the translation is showing. `scale`: the window text factor.
func refresh(revealed: bool, scale: float) -> void:
	on = revealed
	factor = scale
	badge = GameSettings.shared().native_badge()
	text = ""
	# One toggle: the HUD's EN badge (23 Nov 2026). shows_translate_button() still says whether
	# a Display Mode has a translation at all.
	visible = false
	custom_minimum_size = Vector2(74, 52) * scale
	queue_redraw()
	# A card opened (or refreshed) while EN is held opens in the native language too.
	_sync.call_deferred()
	if revealed:
		# Deferred: the panel may become visible (or be hidden) after this refresh.
		_report_shown.call_deferred()

func _enter_tree() -> void:
	var settings = GameSettings.shared()
	if not settings.peek_changed.is_connected(_sync):
		settings.peek_changed.connect(_sync)

func _exit_tree() -> void:
	var settings = GameSettings.shared()
	if settings.peek_changed.is_connected(_sync):
		settings.peek_changed.disconnect(_sync)

## Presses the bubble when its panel's language differs from the peek. `on` flips at once (the
## panel's toggle may re-render later or only while visible); its next refresh() corrects it.
func _sync() -> void:
	if not follows_peek or not is_inside_tree():
		return
	var settings = GameSettings.shared()
	var want: bool = settings.peeking and settings.shows_translate_button()
	if want == on:
		return
	on = want
	pressed.emit()

## The bubble itself is always hidden since 23 Nov 2026 (one toggle), so its panel's visibility
## decides (25 Nov 2026: is_visible_in_tree() on the bubble was always false, so a peek in a
## panel that relies on the bubble, such as the flight game's, was never recorded as translated).
func _report_shown() -> void:
	var panel := get_parent() as CanvasItem
	if on and panel != null and panel.is_visible_in_tree():
		PracticeLog.shared().translation_shown.emit(word_key)

func _draw() -> void:
	var f := factor
	var body := Rect2(Vector2(4, 4) * f, size - Vector2(8, 14) * f)
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(int(12 * f))
	style.bg_color = FILL if on else (BonStyle.RIM if is_hovered() else BonStyle.SKY_TOP)
	style.border_color = EDGE
	style.set_border_width_all(maxi(2, int(2.5 * f)))
	draw_style_box(style, body)
	# The bubble's tail, bottom left.
	var tip := PackedVector2Array([body.position + Vector2(12 * f, body.size.y - 1), body.position + Vector2(26 * f, body.size.y - 1), body.position + Vector2(10 * f, body.size.y + 9 * f)])
	draw_colored_polygon(tip, FILL if on else EDGE)
	var font: Font = BonStyle.font(700)
	var font_size := roundi(22 * f)
	var width := font.get_string_size(badge, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var baseline := body.get_center().y + (font.get_ascent(font_size) - font.get_descent(font_size)) / 2.0
	draw_string(font, Vector2(body.get_center().x - width / 2.0, baseline), badge, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, INK if on else EDGE)

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER or what == NOTIFICATION_MOUSE_EXIT:
		queue_redraw()
