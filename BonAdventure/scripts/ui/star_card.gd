extends Control
## The stars card at the end of a minigame session (progression, user approval 18 Nov 2026;
## docs/guides/MINIGAMES.md#progression). game_progress.gd emits recorded(id, result) when a
## session of a game with levels ends completed; this card shows, at the top centre so the NPC's
## thanks in the dialogue box stays readable: the game's name, its three stars, the level played
## and either "Level up! Level 3 unlocked", "Top level!" or "Get 3 stars for level 3".
## It hides itself after SECONDS; a tap hides it at once. Built by minigame_wiring.gd; interface
## text in the native language (data/phrases.json "progress"), styled with bon_style.gd.
const BonStyle := preload("res://scripts/ui/bon_style.gd")
const Progress := preload("res://scripts/learning/game_progress.gd")
const UiText := preload("res://scripts/language/ui_text.gd")

const SECONDS := 4.5

var card: PanelContainer
var title: Label
var stars: HBoxContainer
var level_line: Label
var note: Label
## The last result shown (checks read it): {"id", "stars", "level", "level_up", ...}.
var shown: Dictionary = {}
var _left := 0.0

func setup() -> void:
	name = "StarCard"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	card = PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(_on_card_input)
	add_child(card)
	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(stack)
	title = BonStyle.label("", 24, BonStyle.INK, 1.0)
	stack.add_child(title)
	stars = BonStyle.stars(0, 56.0)
	stars.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_child(stars)
	level_line = BonStyle.label("", 20, BonStyle.INK_SOFT, 1.0)
	stack.add_child(level_line)
	note = BonStyle.label("", 22, BonStyle.GREEN_TEXT, 1.0)
	stack.add_child(note)
	Progress.shared().recorded.connect(show_result)
	get_viewport().size_changed.connect(_layout)
	_layout()

## Shows one session's result (game_progress.gd recorded()).
func show_result(id: String, result: Dictionary) -> void:
	shown = result.duplicate()
	shown["id"] = id
	title.text = UiText.t("games." + id)
	var earned := int(result.get("stars", 0))
	for i in stars.get_child_count():
		(stars.get_child(i) as TextureRect).texture = BonStyle.icon_texture("star_on" if i < earned else "star_off", 128)
	level_line.text = UiText.t("progress.level", {"n": int(result.get("level", 1))})
	var count := int(result.get("count", 1))
	if bool(result.get("level_up", false)):
		note.text = UiText.t("progress.level_up", {"n": int(result.get("new_level", 1))})
	elif int(result.get("level", 1)) >= count and earned == 3:
		note.text = UiText.t("progress.top_level")
	elif int(result.get("new_level", 1)) < count:
		note.text = UiText.t("progress.next_hint", {"n": int(result.get("new_level", 1)) + 1})
	else:
		note.text = ""
	note.visible = note.text != ""
	get_parent().move_child(self, -1)
	visible = true
	_left = SECONDS
	_layout()

func _on_card_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		visible = false
		accept_event()

func _process(delta: float) -> void:
	if not visible:
		return
	_left -= delta
	if _left <= 0.0:
		visible = false

## Scaled like money_panel.gd (min(height / 800, width / 1100)), centred near the top.
func _layout() -> void:
	var view: Vector2 = get_viewport().get_visible_rect().size
	var f := BonStyle.factor(view)
	var look := BonStyle.flat(BonStyle.SKY, roundi(24 * f), roundi(4 * f))
	look.set_content_margin_all(18.0 * f)
	look.content_margin_left = 36.0 * f
	look.content_margin_right = 36.0 * f
	card.add_theme_stylebox_override("panel", look)
	title.add_theme_font_size_override("font_size", roundi(24 * f))
	level_line.add_theme_font_size_override("font_size", roundi(20 * f))
	note.add_theme_font_size_override("font_size", roundi(22 * f))
	stars.add_theme_constant_override("separation", roundi(8 * f))
	for star in stars.get_children():
		star.custom_minimum_size = Vector2(56, 56) * f
	card.size = Vector2.ZERO
	var need := card.get_combined_minimum_size()
	card.size = need
	card.position = Vector2(roundf((view.x - need.x) * 0.5), roundf(80.0 * f))
