extends Control
## The "customer order" UI: a clerk dialogue box (80% of the screen width, about 27% of
## its height, bottom centre), the order list and cart (a see-through card top right since 13 Nov 2026; the supermarket
## opens it together with the clerk's order line since 14 Nov 2026) and a quit prompt. It only draws what the session gives it and
## emits signals; it knows nothing about orders or words. Text arrives as
## {"foreign": ..., "native": ...} lines; the "show translation" toggle reveals the
## native line. Order and cart rows whose key is a supermarket product show its picture
## (product_pictures.gd, 8 Nov 2026; docs/guides/TOWN_DESIGN_BRIEF.md, customer order minigame).
##
## Every button has focus_mode NONE so Space (jump) never presses a focused button.
##
## Shared by every NPC (4 Nov 2026 standard, docs/guides/ARCHITECTURE_REVIEW_PART1.md#shared-dialogue-popups-and-settings--4-november-2026):
## the speaker on the left, the translate bubble and ✕ top right, choices centred with an
## optional icon ({"id", "label", "icon"}; names in scripts/ui/ui_icons.gd). What each line
## shows follows the Display Mode (GameSettings.view()).
##
## `compact` (set_compact()): a smaller dialogue box low at the bottom centre with smaller text
## and the same button sizes, for minigames that must keep the scene in view (the Grammar
## Classroom turns it on for a class and off at clean-up). Off, nothing changes.
##
## Words to learn inside a line (user, 14 Nov 2026): a line's optional "terms"
## ([{"text", "gloss", "show"?}], Lexicon.native_line()) are words in the language being learned;
## the box colours them (TERM) and a tap or click on one shows its native meaning after it
## ("(= apple)", phrase common.term_meaning), again to hide it; the translate button shows every
## meaning, and a term with "show" always does (an amount and its digits). No hover needed.
##
## One language toggle (user, 17 Nov 2026): the box has no translate bubble of its own any more;
## holding the HUD's EN button (or L), GameSettings.peeking, shows every open card (dialogue,
## cart, quit prompt) in the native language, and letting go shows the language being learned
## again. The bubbles still exist (sessions set show_native) but stay hidden.
##
## UI art style (user, 18 Nov 2026; docs/guides/UI_STYLE.md, mockup
## design-references/ui/dialogue-box.webp): the dialogue box and the quit card are cream
## (BonStyle "dialogue": white rim, soft shadow; the dialogue box has a small tail pointing up to
## the speaker), the speaker's name sits in a blue pill INSIDE the box's top left, lines are dark
## teal Fredoka, and every button is a BonStyle pill (first choice green, others cream, Leave
## coral, ✕ a cream circle). The cart card keeps its dark glass until phase 2 of the restyle.
const GameSettings := preload("res://scripts/core/game_settings.gd")
const PinyinText := preload("res://scripts/ui/pinyin_text.gd")
const UiIcons := preload("res://scripts/ui/ui_icons.gd")
const TranslateButton := preload("res://scripts/ui/translate_button.gd")
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
const ProductPictures := preload("res://scripts/ui/product_pictures.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
const BonStyle := preload("res://scripts/ui/bon_style.gd")

signal choice_pressed(id: String)
signal dialogue_closed
signal done_pressed
signal remove_pressed(key: String)
signal quit_requested
signal quit_answered(leave: bool)

# The order list and cart (UI art style, 18 Nov 2026): soft blue card, dark teal text.
const FILL := BonStyle.SKY
const EDGE := BonStyle.RIM
const GOLD := BonStyle.INK
const DIM := BonStyle.INK_SOFT
const TOAST := BonStyle.TERM
## A shopping list row that is done (its check and text).
const DONE := Color("3f9a35")
## Words in the language being learned inside a line (see the top comment).
const TERM := BonStyle.TERM
## Dialogue box and quit card text (cream cards, UI_STYLE.md).
const LINE := BonStyle.INK
const LINE_SOFT := BonStyle.INK_SOFT
## The order list and cart (user, 13 Nov 2026: smaller, see-through, modern): a glass card in the
## top right [left, top, right, bottom] of the screen (was 0.56, 0.10, 0.98, 0.90). Since 14 Nov
## 2026 the bottom is unused: the card fits its content, hanging from the top (_fit_cards()).
const CART_RECT := [0.70, 0.18, 0.98, 0.64]
const CART_FILL := Color(0.875, 0.953, 0.957, 0.96)
const CART_EDGE := BonStyle.RIM

var show_native := false
## {"foreign", "native"} text of common.show_translation, set by the sessions (kept for
## them; the translate button itself shows the native language's badge).
var translate_text: Dictionary = {"foreign": "", "native": ""}

var dialogue_card: PanelContainer
## The dialogue box's ✕ and the cart's quit ✕, and whether they show (the welcome tutorial turns
## them off, user 18 Nov 2026: its lines move on by themselves and its list stays until paid).
var dialogue_close: Button
var closable := true:
	set(on):
		closable = on
		if dialogue_close != null:
			dialogue_close.visible = on
		if cart_quit_button != null:
			cart_quit_button.visible = on
## The speaker's blue name pill and its name.
var speaker_tag: PanelContainer
var speaker_label: Label
## The line itself (rich text: coloured terms, see the top comment).
var foreign_label: RichTextLabel
var native_label: Label
## Pinyin under the foreign line when Chinese is the foreign language (GameSettings.reading()).
var reading_label: Label
var choice_row: HBoxContainer
var translate_button: Button
var cart_card: PanelContainer
var list_title: Label
var cart_title: Label
var needed_box: VBoxContainer
var cart_box: VBoxContainer
var toast_label: Label
var done_button: Button
var cart_translate_button: Button
## The cart's (large) ✕: asks to quit the order.
var cart_quit_button: Button
var quit_card: PanelContainer
var quit_label: Label
var quit_native: Label
var quit_yes: Button
var quit_no: Button
## Draws and keeps the product pictures of the order and cart rows.
var pictures: Node

var _line: Dictionary = {}
var _choices: Array = []
var _speaker: Dictionary = {}
var _cart: Dictionary = {}
var _quit: Dictionary = {}
var _auto_close := 0.0
## Term indexes of the current line whose meaning a tap opened.
var _open_terms: Dictionary = {}
## A line without choices closes itself once the player walks WALK_OFF metres from where it was
## shown, when no minigame is running (user, 8 Nov 2026: the goodbye after a game should not
## need a tap). `walker` is the player (minigame_wiring.gd).
const WALK_OFF := 3.0
const Board := preload("res://scripts/learning/activity_board.gd")
var walker: Node3D
var _shown_at := Vector3.ZERO
var _toast_time := 0.0
var _toast_line: Dictionary = {}
## Compact dialogue box (see the top comment).
var compact := false

## Dialogue box rectangles as screen fractions [left, top, right, bottom]: the top is the
## minimum height, the box grows upward for long text.
## (8 Nov 2026: narrower and lower than the 4 Nov box, so the talk camera's face shot stays
## clear; see npc_presence.gd.)
const DIALOGUE_RECT := [0.16, 0.76, 0.84, 0.975]
const COMPACT_RECT := [0.25, 0.83, 0.75, 0.985]
## Text size of the compact box's lines relative to the normal box (buttons keep their size).
const COMPACT_TEXT := 0.72

## The layout was designed at this window height; fonts, buttons and the quit card
## scale with the window so the text stays in proportion to the (proportional) boxes.
const DESIGN_HEIGHT := 800.0

func _init() -> void:
	name = "Customer order UI"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_right = 1.0
	anchor_bottom = 1.0
	_build_dialogue()
	_build_cart()
	_build_quit()
	pictures = ProductPictures.new()
	add_child(pictures)
	# A picture drawn after its row was built: rebuild the rows to show it.
	pictures.finished.connect(func(_key: String, _texture: Texture2D) -> void:
		if cart_card.visible:
			_refresh_cart())
	# Draw order: cart, then the dialogue box (an NPC can speak while the cart is open, e.g.
	# "finish the other task first"), then the quit question on top.
	move_child(cart_card, 0)
	resized.connect(_rescale)

func _ready() -> void:
	get_viewport().size_changed.connect(_rescale)
	GameSettings.shared().peek_changed.connect(_on_peek)
	_rescale()

## The HUD's EN button (hold) or L: the open cards switch language while it is held. A peek at a
## shown line counts as its translation seen (practice_log.gd), as the bubble's press did.
func _on_peek() -> void:
	show_native = GameSettings.shared().peeking
	refresh_display()
	if show_native and (dialogue_card.visible or cart_card.visible):
		PracticeLog.shared().translation_shown.emit("")
	if _auto_close > 0.0:
		_auto_close = maxf(_auto_close, 6.0)

## Sets every font size and minimum size from the sizes recorded at design height.
func _rescale() -> void:
	var factor := clampf(get_viewport_rect().size.y / DESIGN_HEIGHT, 0.6, 3.0)
	_factor = factor
	_scale_node(self, factor)
	if compact:
		for label in [speaker_label, foreign_label, reading_label, native_label]:
			_size_font(label, roundi(int(label.get_meta("base_font")) * factor * COMPACT_TEXT))
	var margin := 18.0 * factor * (0.6 if compact else 1.0)
	dialogue_card.add_theme_stylebox_override("panel", _cream_box(factor, margin, true))
	quit_card.add_theme_stylebox_override("panel", _cream_box(factor, 22.0 * factor, false))
	speaker_tag.add_theme_stylebox_override("panel", _tag_box(factor))
	for button in [translate_button, cart_translate_button]:
		button.refresh(show_native, factor)
		button.tooltip_text = str(translate_text.get("native", ""))
		# One toggle: the HUD's EN button (17 Nov 2026).
		button.visible = false
	_fit_cards.call_deferred()
	# Wrapped labels report their height for the width they had BEFORE this layout, so the
	# cards are measured again once the new width has settled.
	_refit_next_frame()

var _factor := 1.0

func _refit_next_frame() -> void:
	if not is_inside_tree():
		return
	await get_tree().process_frame
	_fit_cards()

## The dialogue and cart cards are placed by hand (their anchors are all 0): anchored
## rectangles plus hand-set sizes fought each other when the window settled at start-up and
## stretched the dialogue box over most of the screen (fixed 4 Nov 2026).
func _fit_cards() -> void:
	var screen := get_viewport_rect().size
	var box: Array = COMPACT_RECT if compact else DIALOGUE_RECT
	# The cart is as tall as its rows (no scroll bar since 14 Nov 2026): it hangs from
	# CART_RECT's top and only moves up when it would run off the bottom of the screen.
	var cart_width := screen.x * (float(CART_RECT[2]) - float(CART_RECT[0]))
	cart_card.size = Vector2(cart_width, 0.0)
	var cart_height := cart_card.get_combined_minimum_size().y
	cart_card.position = Vector2(screen.x * float(CART_RECT[0]), maxf(8.0, minf(screen.y * float(CART_RECT[1]), screen.y - 8.0 - cart_height)))
	cart_card.size = Vector2(cart_width, cart_height)
	for spec in [[dialogue_card] + box]:
		var card: Control = spec[0]
		var width := screen.x * (float(spec[3]) - float(spec[1]))
		card.size = Vector2(width, 0.0)   # let it shrink to its text first
		# Long text makes the card taller than its share of the screen: it grows upward
		# from the anchored bottom edge so the buttons stay on screen.
		var height := maxf(screen.y * (float(spec[4]) - float(spec[2])), card.get_combined_minimum_size().y)
		card.position = Vector2(screen.x * float(spec[1]), screen.y * float(spec[4]) - height)
		card.size = Vector2(width, height)

func _scale_node(node: Node, factor: float) -> void:
	if node.has_meta("button_kind") and node is Button:
		_style_button(node as Button, str(node.get_meta("button_kind")), factor)
	if node.has_meta("base_font"):
		_size_font(node, roundi(int(node.get_meta("base_font")) * factor))
	if node.has_meta("base_min") and node is Control:
		(node as Control).custom_minimum_size = (node.get_meta("base_min") as Vector2) * factor
	if node.has_meta("base_icon") and node is Button:
		(node as Button).add_theme_constant_override("icon_max_width", roundi(float(node.get_meta("base_icon")) * factor))
	if node.has_meta("base_margin") and node is PanelContainer:
		(node as PanelContainer).get_theme_stylebox("panel").set_content_margin_all(float(node.get_meta("base_margin")) * factor)
	for child in node.get_children():
		_scale_node(child, factor)

func _font(node: Control, size: int) -> void:
	node.set_meta("base_font", size)
	_size_font(node, size)

## A label's or rich text's font size.
func _size_font(node: Node, size: int) -> void:
	if node is RichTextLabel:
		for key in ["normal_font_size", "bold_font_size"]:
			node.add_theme_font_size_override(key, size)
	else:
		node.add_theme_font_size_override("font_size", size)

func _min(node: Control, size: Vector2) -> void:
	node.set_meta("base_min", size)
	node.custom_minimum_size = size

func _card(width: float) -> PanelContainer:
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = FILL
	style.border_color = EDGE
	style.set_border_width_all(5)
	style.set_corner_radius_all(24)
	style.set_content_margin_all(14)
	style.shadow_color = Color(0.1, 0.27, 0.32, 0.25)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	style.anti_aliasing = true
	card.add_theme_stylebox_override("panel", style)
	card.set_meta("base_margin", 14)
	if width > 0.0:
		_min(card, Vector2(width, 0))
	card.visible = false
	add_child(card)
	return card

## The cream dialogue box / quit card at `factor` (BonStyle "dialogue"), `tail` pointing up.
func _cream_box(factor: float, margin: float, tail: bool) -> StyleBox:
	var look = BonStyle.box("dialogue", factor)
	look.set_content_margin_all(margin)
	look.content_margin_left = margin * 1.4
	look.content_margin_right = margin * 1.1
	if tail:
		look.tail = 34.0 * factor
		look.tail_at = 0.5
	return look

## The speaker's blue name pill (inside the box, user 18 Nov 2026).
func _tag_box(factor: float) -> StyleBox:
	var look = BonStyle.box("tag", factor)
	look.content_margin_left = 16.0 * factor
	look.content_margin_right = 16.0 * factor
	look.content_margin_top = 3.0 * factor
	look.content_margin_bottom = 5.0 * factor
	return look

func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	BonStyle.use_font(label, 600)
	_font(label, font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

func _button(text: String, kind: String = "secondary") -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	_font(button, 24)
	_min(button, Vector2(0, 46))
	button.set_meta("button_kind", kind)
	_style_button(button, kind, 1.0)
	return button

## Button looks (UI art style, 18 Nov 2026; were teal / dark blue since 8 Nov 2026): "primary"
## (the first choice, Stay, Done) a green pill, "secondary" a cream pill, "leave" (the quit card's
## Leave) coral, "quiet" (✕) a small cream circle. BonStyle draws them.
const BUTTON_KINDS := {"primary": "primary", "secondary": "minor", "leave": "danger", "quiet": "quiet", "soft": "soft_quiet"}

## BonStyle's pill for every state. With an icon, the side padding is wide enough that the icon
## and the words, as one group, sit in the middle of a button wider than its contents.
func _style_button(button: Button, kind: String, factor: float) -> void:
	BonStyle.style_button(button, str(BUTTON_KINDS.get(kind, "minor")), factor, float(button.get_meta("base_font", 24)))
	var pad := 22.0 * factor if button.text != "" else 8.0 * factor
	if button.text != "" and button.has_meta("base_min"):
		var font := button.get_theme_font("font")
		var font_size := roundi(float(button.get_meta("base_font", 24)) * factor)
		var text_width := 0.0
		for line in button.text.split("\n"):
			text_width = maxf(text_width, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
		var group := text_width
		if button.icon != null:
			group += float(button.get_meta("base_icon", 28)) * factor + 10.0   # h_separation (_set_icon)
		pad = maxf(pad, ((button.get_meta("base_min") as Vector2).x * factor - group) * 0.5)
	for state in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
		var look := button.get_theme_stylebox(state)
		look.content_margin_left = pad
		look.content_margin_right = pad
		look.content_margin_top = 6.0 * factor
		look.content_margin_bottom = 8.0 * factor
	button.add_theme_constant_override("h_separation", 10)
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER

func _build_dialogue() -> void:
	dialogue_card = _card(0)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	dialogue_card.add_child(stack)
	var top := HBoxContainer.new()
	stack.add_child(top)
	# The speaker's name on a small tag at the top left.
	var tag := PanelContainer.new()
	speaker_tag = tag
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tag.add_theme_stylebox_override("panel", _tag_box(1.0))
	top.add_child(tag)
	speaker_label = _label(24, Color.WHITE)
	BonStyle.use_font(speaker_label, 700)
	speaker_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	tag.add_child(speaker_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(spacer)
	translate_button = TranslateButton.new()
	translate_button.pressed.connect(toggle_translation)
	top.add_child(translate_button)
	dialogue_close = _icon_button("close")
	dialogue_close.pressed.connect(func() -> void: dialogue_closed.emit())
	top.add_child(dialogue_close)
	foreign_label = RichTextLabel.new()
	foreign_label.bbcode_enabled = true
	foreign_label.fit_content = true
	foreign_label.scroll_active = false
	foreign_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	foreign_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foreign_label.add_theme_color_override("default_color", LINE)
	BonStyle.use_font(foreign_label, 600)
	# PASS: a tap on a term is taken (meta_clicked); any other tap goes on to the card.
	foreign_label.mouse_filter = Control.MOUSE_FILTER_PASS
	foreign_label.meta_clicked.connect(_on_term_tapped)
	_font(foreign_label, 32)
	stack.add_child(foreign_label)
	reading_label = PinyinText.style(_label(22, LINE_SOFT))
	stack.add_child(reading_label)
	native_label = _label(26, LINE_SOFT)
	stack.add_child(native_label)
	choice_row = HBoxContainer.new()
	choice_row.alignment = BoxContainer.ALIGNMENT_CENTER
	choice_row.add_theme_constant_override("separation", 18)
	stack.add_child(choice_row)

## The ✕ of every card: the shared close icon.
func _icon_button(icon: String) -> Button:
	var button := _button("", "quiet")
	button.icon = BonStyle.icon_texture(icon, 96)
	button.set_meta("base_icon", 22)
	button.add_theme_constant_override("icon_max_width", 26)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_min(button, Vector2(52, 52))
	return button

func _build_cart() -> void:
	cart_card = _card(0)
	var glass := cart_card.get_theme_stylebox("panel") as StyleBoxFlat
	glass.bg_color = CART_FILL
	glass.border_color = CART_EDGE
	glass.set_border_width_all(5)
	glass.set_corner_radius_all(26)
	glass.shadow_color = Color(0.1, 0.27, 0.32, 0.25)
	glass.shadow_size = 16
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	cart_card.add_child(stack)
	var head := HBoxContainer.new()
	stack.add_child(head)
	list_title = _label(24, GOLD)
	head.add_child(list_title)
	cart_translate_button = TranslateButton.new()
	cart_translate_button.pressed.connect(toggle_translation)
	head.add_child(cart_translate_button)
	# The cart's ✕ (quit the order): about 1.7 x the other ✕ and edged like Leave, a clear
	# finger-sized target (14 Nov 2026, user).
	var quit := _icon_button("close")
	quit.name = "Cart quit"
	quit.set_meta("button_kind", "leave")
	quit.set_meta("base_icon", 44)
	_min(quit, Vector2(92, 78))
	quit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	quit.pressed.connect(func() -> void: quit_requested.emit())
	head.add_child(quit)
	cart_quit_button = quit
	needed_box = VBoxContainer.new()
	needed_box.add_theme_constant_override("separation", 4)
	stack.add_child(needed_box)
	var rule := HSeparator.new()
	var line_style := StyleBoxLine.new()
	line_style.color = Color(BonStyle.INK_SOFT, 0.3)
	line_style.thickness = 1
	rule.add_theme_stylebox_override("separator", line_style)
	stack.add_child(rule)
	cart_title = _label(24, GOLD)
	stack.add_child(cart_title)
	# No scroll bar (14 Nov 2026, user): an order has 2 items, so the rows fit and the card is
	# as tall as its content (_fit_cards()).
	cart_box = VBoxContainer.new()
	cart_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cart_box.add_theme_constant_override("separation", 6)
	stack.add_child(cart_box)
	toast_label = _label(22, TOAST)
	toast_label.visible = false
	stack.add_child(toast_label)
	done_button = _button("", "primary")
	_min(done_button, Vector2(0, 52))
	_font(done_button, 24)
	done_button.pressed.connect(func() -> void: done_pressed.emit())
	stack.add_child(done_button)

func _build_quit() -> void:
	quit_card = _card(640)
	quit_card.anchor_left = 0.5
	quit_card.anchor_right = 0.5
	quit_card.anchor_top = 0.5
	quit_card.anchor_bottom = 0.5
	quit_card.offset_left = 0
	quit_card.offset_right = 0
	quit_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	quit_card.grow_vertical = Control.GROW_DIRECTION_BOTH
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	quit_card.add_child(stack)
	stack.add_theme_constant_override("separation", 14)
	quit_label = _label(30, LINE)
	quit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(quit_label)
	quit_native = _label(24, LINE_SOFT)
	quit_native.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(quit_native)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	stack.add_child(row)
	# Stay (a play sign, "keep playing", green) on the left and Leave (a door with an arrow,
	# coral) on the right (user, 18 Nov 2026; two icons and colours since 8 Nov 2026).
	quit_no = _button("", "primary")
	_min(quit_no, Vector2(210, 58))
	_set_icon(quit_no, "play")
	quit_no.pressed.connect(func() -> void: quit_answered.emit(false))
	row.add_child(quit_no)
	quit_yes = _button("", "leave")
	_min(quit_yes, Vector2(210, 58))
	_set_icon(quit_yes, "exit")
	quit_yes.pressed.connect(func() -> void: quit_answered.emit(true))
	row.add_child(quit_yes)

# --- Dialogue ---------------------------------------------------------------

## `choices`: [{"id": String, "label": {"foreign", "native"}, "icon": optional icon name}]. With no choices the
## box closes itself after `auto_close` seconds (0 keeps it until closed).
## `speaker`: a name, or a {"foreign", "native"} line that follows the Display Mode.
func show_dialogue(speaker: Variant, line: Dictionary, choices: Array = [], auto_close: float = 0.0) -> void:
	_speaker = speaker if speaker is Dictionary else {"foreign": str(speaker), "native": str(speaker)}
	_line = line
	_choices = choices
	_auto_close = auto_close if choices.is_empty() else 0.0
	_open_terms = {}
	# A new line is in the language being learned unless EN is held right now.
	show_native = GameSettings.shared().peeking
	if is_instance_valid(walker):
		_shown_at = walker.global_position
	dialogue_card.visible = true
	_refresh_dialogue()

## Turns the compact dialogue box on or off (see the top comment).
func set_compact(on: bool) -> void:
	if compact == on:
		return
	compact = on
	if is_inside_tree():
		_rescale()

func hide_dialogue() -> void:
	dialogue_card.visible = false
	_auto_close = 0.0

func is_dialogue_visible() -> bool:
	return dialogue_card.visible

## The line on screen now, so a session can tell whether the box still shows its own line
## (two NPCs a few steps apart share the box: the police lineup and evidence officers).
func current_line() -> Dictionary:
	return _line

func has_choices() -> bool:
	return dialogue_card.visible and not _choices.is_empty()

func _refresh_dialogue() -> void:
	speaker_label.text = GameSettings.shared().view(_speaker, false)[0]
	var shown: Array = GameSettings.shared().view(_line, show_native)
	foreign_label.text = _term_markup(shown[0])
	# A "narration" line (the welcome tutorial, tutorial.gd) is already in the native language:
	# no reading under it and no translation.
	var narration: bool = _line.get("narration", false)
	PinyinText.show(reading_label, {} if narration else _line)
	native_label.text = shown[1]
	native_label.visible = shown[1] != "" and not narration
	for child in choice_row.get_children():
		choice_row.remove_child(child)
		child.queue_free()
	for choice in _choices:
		# Larger than other buttons; the first choice (the "yes" of every question) is teal.
		var button := _button(GameSettings.shared().stacked(choice.label, show_native), "primary" if choice_row.get_child_count() == 0 else "secondary")
		_min(button, Vector2(220, 64))
		_font(button, 30)
		_set_icon(button, str(choice.get("icon", "")))
		var id: String = choice.id
		button.pressed.connect(func() -> void: choice_pressed.emit(id))
		choice_row.add_child(button)
	_rescale()

## BBCode of `text` with the line's terms coloured and tappable, each followed by its meaning
## when opened (see the top comment). Longer terms win where two overlap.
func _term_markup(text: String) -> String:
	var terms: Array = _line.get("terms", [])
	var order: Array = range(terms.size())
	order.sort_custom(func(a: int, b: int) -> bool: return str(terms[a].get("text", "")).length() > str(terms[b].get("text", "")).length())
	var taken := PackedByteArray()
	taken.resize(text.length())
	var spans: Array = []
	for index in order:
		var term := str(terms[index].get("text", ""))
		var from := 0
		while term != "":
			var at := text.findn(term, from)
			if at < 0:
				break
			from = at + term.length()
			if taken.slice(at, from).count(1) > 0:
				continue
			for i in range(at, from):
				taken[i] = 1
			spans.append([at, from, index])
	spans.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var out := ""
	var cursor := 0
	for span in spans:
		var term: Dictionary = terms[span[2]]
		out += _escape(text.substr(cursor, span[0] - cursor))
		out += "[url=term:%d][b][color=#%s]%s[/color][/b][/url]" % [span[2], TERM.to_html(false), _escape(text.substr(span[0], span[1] - span[0]))]
		if term.get("show", false) or show_native or _open_terms.has(span[2]):
			var meaning: String = Lexicon.shared().phrase("common.term_meaning", Lexicon.shared().native, {"meaning": str(term.get("gloss", ""))})
			out += " [color=#%s]%s[/color]" % [LINE_SOFT.to_html(false), _escape(meaning)]
		cursor = span[1]
	return out + _escape(text.substr(cursor))

static func _escape(text: String) -> String:
	return text.replace("[", "[lb]")

## A tap or click on a coloured term: show its meaning after it, or hide it again.
func _on_term_tapped(meta: Variant) -> void:
	var id := str(meta)
	if not id.begins_with("term:"):
		return
	foreign_label.accept_event()
	var index := int(id.trim_prefix("term:"))
	if _open_terms.has(index):
		_open_terms.erase(index)
	else:
		_open_terms[index] = true
	foreign_label.text = _term_markup(GameSettings.shared().view(_line, show_native)[0])
	if _auto_close > 0.0:
		_auto_close = maxf(_auto_close, 6.0)
	_refit_next_frame()

func _set_icon(button: Button, icon: String) -> void:
	if icon == "":
		return
	button.icon = BonStyle.icon_texture(icon, 96)
	button.set_meta("base_icon", 36)
	button.add_theme_constant_override("icon_max_width", roundi(36 * _factor))
	button.add_theme_constant_override("h_separation", 10)

func toggle_translation() -> void:
	show_native = not show_native
	refresh_display()
	if _auto_close > 0.0:
		_auto_close = maxf(_auto_close, 6.0)

## Re-renders every open card (the Display Mode or a language changed).
func refresh_display() -> void:
	_refresh_dialogue()
	_refresh_cart()
	_refresh_quit()
	_rescale()

# --- Cart ------------------------------------------------------------------

## data: {"list_title", "cart_title", "done" (lines), "needed": [{"foreign","native"}],
## "cart": [{"key", "foreign", "native"}]}
func show_cart(data: Dictionary) -> void:
	_cart = data
	cart_card.visible = true
	_refresh_cart()

func update_cart(data: Dictionary) -> void:
	_cart = data
	_refresh_cart()

func hide_cart() -> void:
	cart_card.visible = false
	hide_quit()
	_toast_time = 0.0
	toast_label.visible = false

func is_cart_visible() -> bool:
	return cart_card.visible

func _fill_rows(box: VBoxContainer) -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()

func _text_of(row: Dictionary) -> String:
	return GameSettings.shared().inline(row, show_native, "   ·   ")

func _refresh_cart() -> void:
	if _cart.is_empty():
		return
	list_title.text = GameSettings.shared().inline(_cart.list_title, show_native)
	cart_title.text = GameSettings.shared().inline(_cart.cart_title, show_native)
	_fill_rows(needed_box)
	for row in _cart.needed:
		var item := HBoxContainer.new()
		_add_picture(item, str(row.get("key", "")))
		var label := _label(22, LINE)
		label.text = _text_of(row)
		item.add_child(label)
		# A row may be a shopping list's line (the welcome tutorial, 17 Nov 2026): "done" shows
		# a green check and dims the text; "pop" (the row just completed) gives it a short bounce.
		if row.has("done"):
			var tick := TextureRect.new()
			tick.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tick.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tick.custom_minimum_size = Vector2(34, 34) * _factor
			tick.texture = UiIcons.texture("check", 64)
			tick.modulate = DONE if row.done else Color(1, 1, 1, 0.0)
			item.add_child(tick)
			if row.done:
				label.add_theme_color_override("font_color", DONE)
		needed_box.add_child(item)
		if row.get("pop", false):
			item.pivot_offset = Vector2(0, 20) * _factor
			var bounce := item.create_tween()
			item.scale = Vector2.ONE * 1.18
			bounce.tween_property(item, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_fill_rows(cart_box)
	for row in _cart.cart:
		var line := HBoxContainer.new()
		_add_picture(line, str(row.get("key", "")))
		var label := _label(22, LINE)
		label.text = _text_of(row)
		line.add_child(label)
		var remove := _icon_button("close")
		remove.set_meta("button_kind", "soft")   # soft blue on the soft blue cart
		var key: String = row.key
		remove.pressed.connect(func() -> void: remove_pressed.emit(key))
		line.add_child(remove)
		cart_box.add_child(line)
	done_button.text = _text_of(_cart.done)
	done_button.disabled = _cart.cart.is_empty()
	_rescale()

## The product's picture at the start of an order or cart row (nothing for other keys). It is
## filled in when product_pictures.gd has drawn it.
func _add_picture(line: HBoxContainer, key: String) -> void:
	if not ProductPictures.has_picture(key):
		return
	var icon := TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_min(icon, Vector2(40, 40))
	icon.custom_minimum_size = Vector2(40, 40) * _factor
	icon.texture = pictures.picture(key)
	line.add_child(icon)

## A short message under the cart (for example the item cap).
func toast(line: Dictionary, seconds: float = 2.5) -> void:
	_toast_line = line
	_toast_time = seconds
	_refresh_toast()

func _refresh_toast() -> void:
	toast_label.visible = _toast_time > 0.0
	toast_label.text = _text_of(_toast_line) if _toast_time > 0.0 else ""

# --- Quit prompt -------------------------------------------------------------

func show_quit(prompt: Dictionary, yes: Dictionary, no: Dictionary) -> void:
	_quit = {"prompt": prompt, "yes": yes, "no": no}
	quit_card.visible = true
	_refresh_quit()

func hide_quit() -> void:
	quit_card.visible = false

func is_quit_open() -> bool:
	return quit_card.visible

func _refresh_quit() -> void:
	if _quit.is_empty():
		return
	var shown: Array = GameSettings.shared().view(_quit.prompt, show_native)
	quit_label.text = shown[0]
	quit_native.text = shown[1]
	quit_native.visible = shown[1] != ""
	quit_yes.text = GameSettings.shared().stacked(_quit.yes, show_native)
	quit_no.text = GameSettings.shared().stacked(_quit.no, show_native)
	_rescale()

func _process(delta: float) -> void:
	if dialogue_card.visible and _choices.is_empty() and is_instance_valid(walker) and walker.global_position.distance_to(_shown_at) > WALK_OFF and Board.shared().blocker("") == "":
		hide_dialogue()
		dialogue_closed.emit()
	if _auto_close > 0.0:
		_auto_close -= delta
		if _auto_close <= 0.0:
			hide_dialogue()
			dialogue_closed.emit()
	if _toast_time > 0.0:
		_toast_time -= delta
		if _toast_time <= 0.0:
			_refresh_toast()
