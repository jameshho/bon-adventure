extends Label3D
## A word that pops up in the 3D world and fades: it grows in, settles, stays, then fades
## (first use: the mahjong calls, mahjong_session.gd, 9 Nov 2026). Reusable by any minigame:
##
##     var word := PopWord3D.new()
##     parent.add_child(word)
##     word.position = ...
##     word.pop("Pung!", Color("ff5f9e"), 0.9, camera)
##
## It is drawn over everything (no depth test) and faces the camera. With a camera it keeps the
## same size on screen at any distance (FULL_SIZE_DISTANCE is where it shows at its label size).

const FILL := Color("fffdf8")
const FULL_SIZE_DISTANCE := 3.2
const GROW_SECONDS := 0.14
const SETTLE_SECONDS := 0.1
const FADE_SECONDS := 0.15
const START_SCALE := 0.3
const OVERSHOOT := 1.2

var _tween: Tween

func _init() -> void:
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	render_priority = 10
	font_size = 96
	pixel_size = 0.0024
	outline_size = 34
	visible = false

## Shows `text` with an `outline` colour for `seconds` in all (grow, stay, fade).
func pop(text_shown: String, outline: Color, seconds: float, camera: Camera3D = null) -> void:
	stop()
	text = text_shown
	visible = true
	modulate = FILL
	outline_modulate = outline
	var size := 1.0
	if camera != null and is_inside_tree():
		size = clampf(camera.global_position.distance_to(global_position) / FULL_SIZE_DISTANCE, 0.4, 1.5)
	scale = Vector3.ONE * START_SCALE * size
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector3.ONE * OVERSHOOT * size, GROW_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector3.ONE * size, SETTLE_SECONDS)
	_tween.tween_interval(maxf(seconds - GROW_SECONDS - SETTLE_SECONDS - FADE_SECONDS, 0.1))
	_tween.tween_property(self, "modulate:a", 0.0, FADE_SECONDS)
	_tween.parallel().tween_property(self, "outline_modulate:a", 0.0, FADE_SECONDS)
	_tween.tween_callback(func() -> void: visible = false)

## Hides the word at once.
func stop() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	visible = false
