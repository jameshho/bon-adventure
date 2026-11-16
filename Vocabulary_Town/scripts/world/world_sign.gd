extends RefCounted
## World signs: the one way to make or restyle the lettering of a sign in the town (16 Nov 2026,
## user: "signs are hard to read"). docs/guides/COMPONENTS.md#world-signs; the readability rule
## is docs/guides/BUILDING_DESIGN_BLUEPRINT.md#sign-readability.
##
## Measured on 16 Nov 2026 (docs/evidence/world-signs-20261116/): signs blur into blobs when
## their capitals are under about 6 px on screen, which on a landscape phone (390 px high, 70°
## view) is a letter height (em, font_size x pixel_size in metres) under 1/32 of the distance.
## Rule: em >= reading distance / READ_RATIO, where the reading distance is the farthest the
## player should be able to read the sign from (an aisle sign: the aisle; a facade: the street).
##
## A world sign:
##   - is a Label3D at FONT_SIZE (a web LABEL_SIZES step, so it shares one glyph atlas) whose
##     pixel_size gives its em;
##   - never gets smaller than the rule, also when a translation is longer: sign_language.gd
##     shrinks a world sign only to its fit width (meta sign_fit_width, the board's free width)
##     and never below meta sign_min_em; a text that still does not fit wraps when the sign
##     allows lines (max_lines > 1), else it overflows and the check reports it;
##   - gets an outline only when its colour lacks MIN_CONTRAST against its board; the outline is
##     the board colour darkened (light text) or lightened (dark text) until it has that contrast.
## Translation still goes through sign_language.gd (English source text in data/sign_translations.json).
##
## Use:
##   WorldSign.make(parent, "PANTRY label", "PANTRY", position, {"read": 15.0, "colour": c,
##       "board": board_colour, "fit_width": 5.0})          # new lettering, returns the Label3D
##   WorldSign.restyle(label, {"read": 15.0, "board": board_colour, "fit_width": 5.0})
##   WorldSign.fit_board(board_mesh, label, margin)       # grows a too-small board to its text
## Spec keys: read (m, required), em (m, a larger letter height than the rule), colour, board
## (Color behind the text), fit_width (m of free board width), max_lines (default 1), billboard.
const SignLanguage := preload("res://scripts/world/sign_language.gd")

const READ_RATIO := 30.0
const FONT_SIZE := 64
## Outline in font pixels at FONT_SIZE (a multiple of render_culling.gd LABEL_OUTLINE_STEP).
const OUTLINE := 8
## WCAG AA for text; the check tests every world sign against it.
const MIN_CONTRAST := 4.5
## Line spacing of the font, in em (Noto/Open Sans line height is about 1.36 em).
const LINE_HEIGHT := 1.36

## The smallest letter height (em, metres) readable from `read` metres.
static func min_em(read: float) -> float:
	return read / READ_RATIO

static func make(parent: Node, node_name: String, text: String, position: Vector3, spec: Dictionary) -> Label3D:
	var label := Label3D.new()
	label.name = node_name
	label.text = text
	label.position = position
	label.modulate = spec.get("colour", Color.WHITE)
	if spec.has("billboard"):
		label.billboard = spec.billboard
	parent.add_child(label, true)
	restyle(label, spec)
	return label

## Applies the rule to a label already in the tree (its text is the English source or a
## translation sign_language.gd knows). Never makes a sign smaller than it is unless spec.em says so.
static func restyle(label: Label3D, spec: Dictionary) -> void:
	var read: float = spec.read
	var scale := _world_scale(label)
	# A translated sign may be shrunk right now: start from its base size.
	var base_pixel: float = label.get_meta("sign_pixel_size", label.pixel_size)
	var em_now := int(label.get_meta("sign_font_size", label.font_size)) * base_pixel * scale
	var em: float = maxf(float(spec.get("em", em_now)), min_em(read))
	if spec.has("colour"):
		label.modulate = spec.colour
	var pixel := em / scale / FONT_SIZE
	label.font_size = FONT_SIZE
	label.pixel_size = pixel
	label.set_meta("world_sign", true)
	label.set_meta("sign_read", read)
	label.set_meta("sign_min_em", min_em(read))
	label.set_meta("sign_em", em)
	if spec.has("fit_width"):
		label.set_meta("sign_fit_width", float(spec.fit_width))
	var lines := int(spec.get("max_lines", 1))
	label.set_meta("sign_max_lines", lines)
	if lines > 1 and spec.has("fit_width"):
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.width = float(spec.fit_width) / scale / pixel
	else:
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
	if spec.has("board"):
		var board: Color = spec.board
		label.set_meta("sign_board", board)
		if contrast(label.modulate, board) < MIN_CONTRAST:
			label.outline_size = OUTLINE
			label.outline_modulate = outline_for(label.modulate, board)
		else:
			label.outline_size = 0
	# Translated signs keep their base size here; sign_language.gd fits each language from it.
	if label.has_meta("sign_font_size"):
		label.set_meta("sign_font_size", FONT_SIZE)
	label.set_meta("sign_pixel_size", pixel)
	if label.is_in_group(SignLanguage.GROUP):
		SignLanguage.apply(label, SignLanguage.shown_language())

## Grows `board` (scaling its node) along the label's width and height so the label's text, at its
## current size, fits with `margin` metres free on each side. Returns true when it grew.
static func fit_board(board: MeshInstance3D, label: Label3D, margin: float, texts: Array = []) -> bool:
	var box := board.global_transform * board.get_aabb()
	var right := label.global_transform.basis.x.normalized()
	var up := label.global_transform.basis.y.normalized()
	var need_w := 0.0
	for text in ([label.text] if texts.is_empty() else texts):
		need_w = maxf(need_w, text_width(label, str(text)))
	need_w += 2.0 * margin
	var need_h := em_of(label) * LINE_HEIGHT + 2.0 * margin
	var have_w := absf(box.size.dot(right.abs()))
	var have_h := absf(box.size.dot(up.abs()))
	var grew := false
	var local_right := (board.global_transform.basis.inverse() * right).abs()
	var local_up := (board.global_transform.basis.inverse() * up).abs()
	var s := board.scale
	if need_w > have_w + 0.001:
		s = s * (Vector3.ONE + local_right / local_right.length() * (need_w / have_w - 1.0)).abs()
		grew = true
	if need_h > have_h + 0.001:
		s = s * (Vector3.ONE + local_up / local_up.length() * (need_h / have_h - 1.0)).abs()
		grew = true
	board.scale = s
	return grew

## The board a label is painted on: the smallest mesh under `root` whose box holds the label's
## centre (grown by `reach` metres), no larger than `max_size` metres across, and painted
## `colour` when one is given (alpha > 0). null when none.
static func board_behind(label: Label3D, root: Node, reach: float = 0.25, max_size: float = 12.0, colour := Color(0, 0, 0, 0)) -> MeshInstance3D:
	var best: MeshInstance3D = null
	var best_size := INF
	var at := label.global_position
	for mesh: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null or not mesh.visible:
			continue
		var box: AABB = mesh.global_transform * mesh.get_aabb()
		var size := box.size.length()
		if size > max_size or not box.grow(reach).has_point(at):
			continue
		if colour.a > 0.0 and not board_colour(mesh).is_equal_approx(colour):
			continue
		if size < best_size:
			best = mesh
			best_size = size
	return best

## The colour a board is painted (its first surface's albedo), or `fallback`.
static func board_colour(board: MeshInstance3D, fallback: Color = Color.GRAY) -> Color:
	if board == null:
		return fallback
	var mat = board.get_active_material(0)
	return (mat as StandardMaterial3D).albedo_color if mat is StandardMaterial3D else fallback

## The board's free width for lettering along the label's width, minus `margin` each side.
static func free_width(board: MeshInstance3D, label: Label3D, margin: float) -> float:
	var box: AABB = board.global_transform * board.get_aabb()
	return absf(box.size.dot(label.global_transform.basis.x.normalized().abs())) - 2.0 * margin

## The label's letter height in world metres.
static func em_of(label: Label3D) -> float:
	return label.font_size * label.pixel_size * _world_scale(label)

## The width of `text` (default: the label's) drawn by this label, in world metres.
static func text_width(label: Label3D, text: String = "") -> float:
	var font: Font = label.font if label.font != null else ThemeDB.fallback_font
	var widest := 0.0
	for line in (label.text if text == "" else text).split("\n"):
		widest = maxf(widest, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, label.font_size).x)
	return widest * label.pixel_size * _world_scale(label)

## WCAG contrast ratio between two colours (1 to 21).
static func contrast(a: Color, b: Color) -> float:
	var la := _luminance(a)
	var lb := _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)

## An outline colour for `text` on `board`: the board's colour darkened (light text) or
## lightened (dark text) until the text has MIN_CONTRAST against it.
static func outline_for(text: Color, board: Color) -> Color:
	var darker := _luminance(text) > _luminance(board)
	var c := board
	for i in range(20):
		if contrast(text, c) >= MIN_CONTRAST:
			break
		c = c.darkened(0.15) if darker else c.lightened(0.15)
	return c

static func _luminance(c: Color) -> float:
	var lin := func(v: float) -> float: return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * lin.call(c.r) + 0.7152 * lin.call(c.g) + 0.0722 * lin.call(c.b)

static func _world_scale(node: Node3D) -> float:
	return node.global_transform.basis.get_scale().y if node.is_inside_tree() else 1.0
