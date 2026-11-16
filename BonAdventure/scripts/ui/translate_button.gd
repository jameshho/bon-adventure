extends Button
## The one "show translation" button of every dialogue and minigame (user decision, 4 Nov
## 2026): a speech bubble with the native language's badge (EN, ES, 中 — languages.json),
## outlined while the translation is hidden and filled while it is shown. Place it at the
## top right, left of the ✕. It is hidden in Display Modes without a translation toggle
## (GameSettings.shows_translate_button()). Connect `pressed` as any Button.
## While it shows the translation on screen it tells the practice tracker (practice_log.gd
## translation_shown: "" = the open question's words, or `word_key` for the word card).
const GameSettings := preload("res://scripts/core/game_settings.gd")
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
const EDGE := Color("7abfb3")
const FILL := Color("7abfb3")
const INK := Color("142a38")

var on := false
var factor := 1.0
## The badge drawn inside the bubble (the Button's own text stays empty: a script _draw runs
## after the Button's, so the box would cover it).
var badge := ""
## The word whose translation this bubble shows ("" = the whole question; the word card sets it).
var word_key := ""

func _init() -> void:
	focus_mode = Control.FOCUS_NONE
	flat = true
	clip_text = false

## `revealed`: the translation is showing. `scale`: the window text factor.
func refresh(revealed: bool, scale: float) -> void:
	on = revealed
	factor = scale
	badge = GameSettings.shared().native_badge()
	text = ""
	visible = GameSettings.shared().shows_translate_button()
	custom_minimum_size = Vector2(74, 52) * scale
	queue_redraw()
	if revealed:
		# Deferred: the panel may become visible (or be hidden) after this refresh.
		_report_shown.call_deferred()

func _report_shown() -> void:
	if on and is_visible_in_tree():
		PracticeLog.shared().translation_shown.emit(word_key)

func _draw() -> void:
	var f := factor
	var body := Rect2(Vector2(4, 4) * f, size - Vector2(8, 14) * f)
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(int(12 * f))
	style.bg_color = FILL if on else Color(1, 1, 1, 0.06 if is_hovered() else 0.0)
	style.border_color = EDGE
	style.set_border_width_all(maxi(2, int(2.5 * f)))
	draw_style_box(style, body)
	# The bubble's tail, bottom left.
	var tip := PackedVector2Array([body.position + Vector2(12 * f, body.size.y - 1), body.position + Vector2(26 * f, body.size.y - 1), body.position + Vector2(10 * f, body.size.y + 9 * f)])
	draw_colored_polygon(tip, FILL if on else EDGE)
	var font := get_theme_font("font")
	var font_size := roundi(22 * f)
	var width := font.get_string_size(badge, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var baseline := body.get_center().y + (font.get_ascent(font_size) - font.get_descent(font_size)) / 2.0
	draw_string(font, Vector2(body.get_center().x - width / 2.0, baseline), badge, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, INK if on else Color.WHITE)

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER or what == NOTIFICATION_MOUSE_EXIT:
		queue_redraw()
