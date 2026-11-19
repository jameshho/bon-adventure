@tool
extends Node3D
## Reusable book (user request, 12 Nov 2026; docs/guides/TOWN_DESIGN_BRIEF.md "Library books 50 % larger").
## Drop scenes/props/book.tscn anywhere and set the exports: with a `title` from COVERS it is a
## picture book (coloured boards, cream pages, a spine in `spine_color` wrapping onto the front, a
## cream title band with the title as a Label3D, a small raised picture of the title); with no
## title it is a plain chunky book in `cover_color` with a softly rounded spine, the same look as
## the books drawn into the library's shelf rows (draw_plain(), shared with
## scripts/buildings/library.gd so both stay the same size and style). Built for the library's
## shelving minigame: each book is one "book" word root that can be moved on its own.
##
## The model, the cover title and the pick area are built at load from code (as glass_window.gd
## does), so a unit scene stores only this root, its exports and metas; meshes are cached per
## look, so books that look alike share one mesh and three materials.
##
## Local frame: base centre at the origin, the cover facing -Z, the spine at +X, cover width along
## X, thickness along Z. A book shelved spine-out (spine facing -Z) turns -90 deg about Y.
## Sizes are town units (the library site is scaled 1.3 in the world).

const Art := preload("res://scripts/buildings/supermarket_products.gd")
const Interactable := preload("res://scripts/core/interactable.gd")
const HandHold := preload("res://scripts/player/hand_hold.gd")
const RenderCulling := preload("res://scripts/world/render_culling.gd")
const SignLanguage := preload("res://scripts/world/sign_language.gd")
## Shelved books (user, 12 Nov 2026: 50 % taller and proportionately wider than the 11 Nov books,
## which were 0.11-0.15 thick, 0.33-0.40 tall and 0.3 deep; a first pass the same day used 40 %).
const THICKNESS_RANGE := Vector2(.165, .225)
const HEIGHT_RANGE := Vector2(.495, .6)
const DEPTH := .45
## A picture book's cover, the same size as the shelved books so it fits their gaps: 0.45 wide
## (the shelf depth) and 0.54 tall; its thickness lies in PICTURE_THICKNESS.
const PICTURE := Vector2(.45, .54)
const PICTURE_THICKNESS := Vector2(.165, .2)
## The cover art is authored at the 11 Nov 2026 picture-book size and scaled up to `size`.
const DESIGN := Vector2(.24, .3)
## Cover title, in DESIGN units: text height (em), base font size, the room it may fill on the
## cream band (width, height) and the band's centre height.
const TITLE_EM := .042
const TITLE_FONT := 64.0
const TITLE_BAND := Vector2(.178, .1)
const TITLE_Y := .242
## The cream band behind the title (x centre, width, height).
const BAND := Vector3(-.016, .196, .108)
const TITLE_MIN_FONT := 34
## Narrowest horizontal squeeze of a title with a long word.
const TITLE_SQUEEZE := .8
## Marks the nodes this script builds (rebuilt on every load, never saved).
const PART_META := "library_book_part"

## English title (translated like a sign, data/sign_translations.json); "" = a plain book.
@export var title := "":
	set(value):
		title = value
		_rebuild()
## Cover width (x), height (y) and thickness (z), in the local frame; a plain book's cover width
## is its depth on a shelf.
@export var size := Vector3(PICTURE.x, PICTURE.y, .17):
	set(value):
		size = Vector3(maxf(value.x, .01), maxf(value.y, .01), maxf(value.z, .01))
		_rebuild()
## The spine (and the strip it wraps onto the front) of a picture book: its category colour.
@export var spine_color := Color("6f4fa6"):
	set(value):
		spine_color = value
		_rebuild()
## Boards of a picture book (transparent: the title's colour in COVERS) or a plain book's colour.
@export var cover_color := Color(0, 0, 0, 0):
	set(value):
		cover_color = value
		_rebuild()
## Adds the pick area (layer 2, like the vocabulary prefabs) so a click names the book.
@export var pickable := true:
	set(value):
		pickable = value
		_rebuild()

## Gets an Interactable: E takes it in the player's hand (and puts it back). Set at load for the
## return rack's books (meta return_book); a minigame can set it on any book before adding it.
@export var holdable := false

static var _art
static var _meshes := {}
var art
## The cover title (rebuilt with the model) and the text and size it was last fitted to.
var _title_label: Label3D
var _fitted_text := ""
var _fitted_size := -1
## The title's authored outline (2 or 14 at TITLE_FONT), before any shared-size scaling.
var _title_outline := 0

func _ready() -> void:
	if not has_meta("word_key"):
		set_meta("word_key", "book")
	set_meta("learning_object", true)
	# How the player holds it (scripts/player/hand_hold.gd profile "book").
	set_meta("hold_kind", "book")
	# The return rack's books (meta return_book, scripts/buildings/library.gd) can be picked up.
	if has_meta("return_book"):
		holdable = true
	_rebuild()
	if holdable and not Engine.is_editor_hint():
		Interactable.attach(self, {
			"prompt_distance": 1.8,
			# Rosa stands beside the return rack calling with her "!" (CALL_BONUS 2 in
			# interaction_controller.gd); the same weight lets the book you face win.
			"priority": 2.0,
			"on_point": func(_from: Vector3) -> Vector3: return _hold_point(),
			"on_badge": _hold_point,
		})

## E, a click or a tap (its Interactable): takes the book in the player's left hand
## (scripts/player/hand_hold.gd), first putting back whatever the hand held; on the book in the
## hand, puts it back where it was picked up.
func use() -> void:
	HandHold.toggle(self)

func _hand() -> Node3D:
	return HandHold.of_player(self)

## Where the "E" sits and range is measured to: the middle of the cover; for the book in the
## hand, its empty place (so E near that place puts it back).
func _hold_point() -> Vector3:
	var middle := Vector3(0, size.y * .55, 0)
	var hand := _hand()
	if hand != null and hand.held == self:
		var home: Variant = hand.home_transform()
		if home is Transform3D:
			return (home as Transform3D) * middle
	return to_global(middle)

## The default font, emboldened, shared by every cover title.
static var _bold: FontVariation
static func _bold_font() -> Font:
	if _bold == null:
		_bold = FontVariation.new()
		_bold.base_font = ThemeDB.fallback_font
		_bold.variation_embolden = .9
	return _bold

## Signs are translated (and re-translated on a language change) after the book is built, so
## the title is fitted again whenever its text or size was changed from outside. Only a book with
## a cover title processes (set in _rebuild()); plain books never do.
func _process(_delta: float) -> void:
	if _title_label == null or not is_instance_valid(_title_label):
		set_process(false)
	elif _title_label.font_size != _fitted_size or _title_label.text != _fitted_text:
		_fit_title()

## The largest font size (down to TITLE_MIN_FONT) at which every word fits the band's width and
## the wrapped title its height.
func _fit_title() -> void:
	var label := _title_label
	var font: Font = label.font if label.font != null else ThemeDB.fallback_font
	# Fitted at the authored pixel size and outline (sign_language.gd and render_culling.gd may
	# have rescaled both since).
	var pixel := TITLE_EM / TITLE_FONT
	label.pixel_size = pixel
	label.outline_size = _title_outline
	var room := TITLE_BAND.x / pixel
	# A long word is first set a little narrower (down to TITLE_SQUEEZE), then smaller.
	var widest := 1.0
	for word in label.text.split(" ", false):
		if word.unicode_at(0) < 0x2E80:
			widest = maxf(widest, font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, int(TITLE_FONT)).x + label.outline_size)
	var squeeze := clampf(room / widest, TITLE_SQUEEZE, 1.0)
	label.scale.x = squeeze
	room /= squeeze
	label.width = room
	var size := int(TITLE_FONT)
	while size > TITLE_MIN_FONT:
		var fits := true
		for word in label.text.split(" ", false):
			# CJK titles have no spaces and wrap anywhere.
			if word.unicode_at(0) < 0x2E80 and font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + label.outline_size > room:
				fits = false
		if fits:
			var lines := roundi(font.get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_CENTER, room, size).y / font.get_height(size))
			var tall := lines * font.get_height(size) + (lines - 1) * label.line_spacing + label.outline_size
			fits = tall * pixel <= TITLE_BAND.y
		if fits:
			break
		size -= 2
	label.font_size = size
	# Web: drawn at the next shared size with a smaller pixel size (same size in the world), so
	# titles share the town's glyph atlases instead of one per fitted size (sign_language.gd
	# _set_size(), performance guide "Stage 0").
	if SignLanguage.share_sizes:
		for step in RenderCulling.LABEL_SIZES:
			if step >= size:
				var ratio := float(step) / float(size)
				label.font_size = step
				label.pixel_size = pixel / ratio
				label.width = room * ratio
				label.outline_size = maxi(RenderCulling.LABEL_OUTLINE_STEP, roundi(_title_outline * ratio / RenderCulling.LABEL_OUTLINE_STEP) * RenderCulling.LABEL_OUTLINE_STEP)
				break
	_fitted_text = label.text
	_fitted_size = label.font_size

## Thickness of the book (what a shelf gap must fit).
func thickness() -> float:
	return size.z

func _rebuild() -> void:
	if not is_inside_tree():
		return
	for child in get_children():
		if child.has_meta(PART_META):
			remove_child(child)
			child.free()
	_title_label = null
	set_process(false)
	var model := MeshInstance3D.new()
	model.name = "Model"
	model.set_meta(PART_META, true)
	add_child(model)
	if title != "" and COVERS.has(title):
		var k := size.y / DESIGN.y
		model.scale = Vector3(size.x / DESIGN.x, k, k)
		model.mesh = _picture_book(size.z / k)
		# Large, bold title (user, 13 Nov 2026: "hard to read, make them bigger"): about 1.55x the
		# 11 Nov text, thickened by an outline in its own colour; _fit_title() shrinks it only
		# as far as a long word or a third line needs (the text is translated after load).
		var cover := Label3D.new()
		cover.name = title + " title"
		cover.text = title
		cover.font_size = TITLE_FONT
		cover.pixel_size = TITLE_EM / TITLE_FONT
		# On the cover's own colour (user, 13 Nov 2026): bold letters in a deep shade of that
		# colour on a light cover, white letters with that deep shade as a thick outline on a
		# darker one.
		var board := Color(_hex(cover_color, COVERS[title][0]))
		var deep := board.darkened(.68)
		cover.font = _bold_font()
		if board.get_luminance() > .55:
			cover.outline_size = 2
			cover.outline_modulate = deep
			cover.modulate = deep
		else:
			cover.outline_size = 14
			cover.outline_modulate = deep
			cover.modulate = Color(WHITE)
		cover.autowrap_mode = TextServer.AUTOWRAP_WORD
		cover.line_spacing = -8
		cover.width = TITLE_BAND.x / cover.pixel_size
		cover.position = Vector3(BAND.x, TITLE_Y, -size.z / k * .5 - .005)
		cover.rotation.y = PI
		_title_label = cover
		_title_outline = cover.outline_size
		_fitted_text = ""
		_fitted_size = -1
		set_process(true)
		model.add_child(cover)
	else:
		# draw_plain's frame has the spine at -Z; turned -90 deg so it lies at +X.
		model.rotation.y = -PI / 2
		model.mesh = _cached("plain %s %.3f %.3f %.3f" % [_hex(cover_color, "b0502e"), size.x, size.y, size.z], func() -> void:
			draw_plain(_kit(), Vector3(0, 0, -size.x * .5), Vector3(size.z, size.y, size.x), _hex(cover_color, "b0502e")))
	if pickable:
		var area := Area3D.new()
		area.name = "Interaction"
		area.set_meta(PART_META, true)
		area.collision_layer = 2
		area.collision_mask = 0
		var shape := CollisionShape3D.new()
		var cube := BoxShape3D.new()
		cube.size = size + Vector3.ONE * .02
		shape.shape = cube
		shape.position = Vector3(0, size.y * .5, 0)
		area.add_child(shape)
		add_child(area)

## One plain standing book drawn into the mesh `kit` is building (scripts/buildings/
## supermarket_products.gd): base centre `c` with the spine face at c.z, facing -Z; `s` its
## thickness (x), height, depth. Plain and chunky (user, 11 Nov 2026): one colour, a softly
## rounded spine, no stickers or bands.
static func draw_plain(kit, c: Vector3, s: Vector3, tint: String) -> void:
	var bulge := s.x * .4
	kit.bx(Vector3(c.x, c.y + s.y * .5, c.z + bulge * .5 + (s.z - bulge * .5) * .5), Vector3(s.x, s.y, s.z - bulge * .5), tint, Art.SATIN)
	kit.cyl(Vector3(c.x, c.y + s.y * .5, c.z + bulge * .5), Vector3(s.x, s.y, bulge), tint, Art.SATIN, Vector3.ZERO, 12)

static func _kit():
	if _art == null:
		_art = Art.new()
	return _art

func _cached(key: String, draw: Callable) -> ArrayMesh:
	if not _meshes.has(key):
		art = _kit()
		art.begin()
		draw.call()
		_meshes[key] = art.finish("Book " + key)
	return _meshes[key]

static func _hex(color: Color, fallback: String) -> String:
	return fallback if color.a <= 0.0 else color.to_html(false)

## A picture book `t` thick in DESIGN units (front and back boards in the cover colour, cream
## pages, the spine wrapping onto the front, the cream title band and the picture below it).
func _picture_book(t: float) -> ArrayMesh:
	var w := DESIGN.x
	var h := DESIGN.y
	var look: Array = COVERS[title]
	var board := _hex(cover_color, look[0])
	var spine := spine_color.to_html(false)
	return _cached("%s %s %s %.4f" % [title, board, spine, t], func() -> void:
		art.bx(Vector3(-.009, h * .5, -t * .5 + .003), Vector3(w - .018, h, .006), board)
		art.bx(Vector3(-.009, h * .5, t * .5 - .003), Vector3(w - .018, h, .006), board)
		art.bx(Vector3(-.01, h * .5, 0), Vector3(w - .022, h - .012, t - .012), "f6efdf")
		art.bx(Vector3(w * .5 - .01, h * .5, 0), Vector3(.02, h, t), spine)
		art.bx(Vector3(w * .5 - .018, h * .5, -t * .5 - .001), Vector3(.036, h, .003), spine)
		art.bx(Vector3(BAND.x, TITLE_Y, -t * .5 - .0015), Vector3(BAND.y, BAND.z, .003), board)
		var pc := Vector3(-.015, .108, -t * .5 - .001)
		_flat(pc, 0, 0, .19, .17, look[1], 0)
		_picture(title, pc))

## Cover colour and picture background of each title.
const COVERS := {
	"Dinosaurs": ["6fb04a", "a8dcf0"], "Ocean Animals": ["2f8fd0", "4aa6d9"], "Birds": ["58b24a", "c4e8f5"],
	"The Solar System": ["2b3a8c", "1d2350"], "Rockets": ["2b3a8c", "1d2350"], "Stars": ["4a3f8c", "2b2a63"],
	"Mountains": ["4f8fc0", "a8dcf0"], "World Map": ["3fa0d8", "fdf3dc"], "Rivers": ["4e9e5a", "9fd38a"],
	"Pyramids": ["d9a03a", "a8dcf0"], "Knights": ["3a6fc0", "c4e8f5"], "Kings and Queens": ["6f3fa6", "9a72c8"],
	"Soccer": ["4e9e3a", "7cc35a"], "Basketball": ["e0782c", "f6e7c8"], "Swimming": ["2a9ac8", "6ec3e8"],
	"Painting": ["e8b43a", "fdf3dc"], "Drawing": ["7a5ab8", "fbfaf5"], "Music": ["d0508a", "f9d6e2"],
	"Pancakes": ["d94a3a", "f7e7c8"], "Pizza": ["e8b43a", "fbe6cf"], "Cookies": ["e07a9a", "f9d3dc"],
	"Dolphins": ["2f8fd0", "7cc8ec"], "Cars": ["d9534a", "a8dcf0"], "Trains": ["3f6fb5", "c4e8f5"],
	"Airplanes": ["4aa0d8", "bfe6f7"], "Flowers": ["e07a9a", "c4e8f5"], "Trees": ["4e9e3a", "a8dcf0"],
	"Fairy Tale": ["8a5fc8", "c4e8f5"], "Mystery": ["2f3560", "3b3f6b"], "Adventure": ["4e9e3a", "a8dcf0"],
	# 17 Nov 2026 (user: Animals, Sports, Music, Food, Vehicles, Plants).
	"Dogs": ["c98a4a", "c4e8f5"], "Cats": ["e8963a", "fbe6cf"], "Elephants": ["7f8fa6", "c4e8f5"],
	"Tennis": ["3f8fc0", "7cc35a"], "Guitar": ["d0508a", "fbe6cf"], "Piano": ["2f3560", "e3e8f5"],
	"Drums": ["d9534a", "fbe6cf"], "Cake": ["e07a9a", "f9e3ea"], "Cactus": ["4e9e3a", "f6e2a4"],
}

const DARK := "2a2238"
const WHITE := "fbfaf5"

# Cover pictures (redrawn 12 Nov 2026, user: "simple, like just a plain basketball, but clear and
# easily identifiable"): ONE big object per title, filling the picture, in bold soft colours with
# a little relief, the toy-like look of the rest of the library. The picture is .19 x .17 (x within
# +-.095, y within +-.085 of `pc`), drawn facing -Z; `layer` brings a part 3 mm forward per step so
# overlapping parts never share a plane (a bump of depth d reaches d / 2 further forward).
# Picture x runs to the VIEWER's right (the book's -X: the cover faces -Z), so the helpers mirror
# x and turns; art.ring calls pass -x themselves.
func _flat(pc: Vector3, x: float, y: float, sx: float, sy: float, tint: String, layer := 1, rz := 0.0) -> void:
	art.bx(pc + Vector3(-x, y, -.0015 - layer * .003), Vector3(sx, sy, .003), tint, Art.MATTE, Vector3(0, 0, -rz))

func _disc(pc: Vector3, x: float, y: float, d: float, tint: String, layer := 1, sides := 24) -> void:
	art.cyl(pc + Vector3(-x, y, -.0015 - layer * .003), Vector3(d, .003, d), tint, Art.MATTE, Vector3(PI / 2, 0, 0), sides)

func _bump(pc: Vector3, x: float, y: float, sx: float, sy: float, tint: String, layer := 1, depth := .012) -> void:
	art.ball(pc + Vector3(-x, y, -.003 - layer * .003), Vector3(sx, sy, depth), tint, Art.SATIN, Vector3.ZERO, 16)

## A triangle with its apex along (-sin rz, cos rz) from its centre (as the viewer sees it).
func _tri(pc: Vector3, x: float, y: float, sx: float, sy: float, tint: String, layer := 1, rz := 0.0) -> void:
	art.prism(pc + Vector3(-x, y, -.0015 - layer * .003), Vector3(sx, sy, .003), tint, Art.MATTE, Vector3(0, 0, -rz))

## A straight stroke `w` wide from a to b, with round ends.
func _seg(pc: Vector3, a: Vector2, b: Vector2, w: float, tint: String, layer := 1) -> void:
	var mid := (a + b) * .5
	var d := b - a
	_flat(pc, mid.x, mid.y, w, d.length(), tint, layer, atan2(-d.x, d.y))
	_disc(pc, a.x, a.y, w, tint, layer, 12)
	_disc(pc, b.x, b.y, w, tint, layer, 12)

## A stroke along a circle (centre, radius) from angle a0 to a1 (degrees, counter-clockwise from +x).
func _arc(pc: Vector3, cx: float, cy: float, r: float, a0: float, a1: float, w: float, tint: String, layer := 1, steps := 8) -> void:
	for k in steps:
		var p := deg_to_rad(lerpf(a0, a1, float(k) / steps))
		var q := deg_to_rad(lerpf(a0, a1, float(k + 1) / steps))
		_seg(pc, Vector2(cx + r * cos(p), cy + r * sin(p)), Vector2(cx + r * cos(q), cy + r * sin(q)), w, tint, layer)

## A five-pointed star of tip radius r.
func _star(pc: Vector3, x: float, y: float, r: float, tint: String, layer := 1) -> void:
	var inner := r * .4
	var h := r - inner * .809
	for k in 5:
		var a := TAU * k / 5.0
		var dist := inner * .809 + h * .5
		_tri(pc, x + sin(a) * dist, y + cos(a) * dist, inner * 1.176, h, tint, layer, -a)
	_disc(pc, x, y, inner * 2.0, tint, layer, 15)

func _tree(pc: Vector3, x: float, y: float, d: float, layer := 2) -> void:
	_flat(pc, x, y - d * .55, d * .22, d * .5, "8a5a2e", layer)
	_bump(pc, x, y, d, d, "3f9a3a", layer + 1)

func _picture(title: String, pc: Vector3) -> void:
	match title:
		"Dinosaurs":
			var g := "5fae45"
			_flat(pc, 0, -.072, .19, .026, "7cc35a", 1)
			_tri(pc, -.055, -.022, .035, .075, g, 2, PI / 2)
			for x in [-.04, -.02, .015, .035]:
				_flat(pc, x, -.05, .018, .04, g, 2)
			_seg(pc, Vector2(.03, -.01), Vector2(.055, .045), .026, g, 2)
			_bump(pc, -.005, -.02, .1, .062, g, 3)
			_bump(pc, .063, .055, .046, .03, g, 3)
			_disc(pc, .07, .06, .009, DARK, 6)
			for spot in [Vector3(-.025, -.005, .018), Vector3(.008, -.008, .014), Vector3(-.04, -.025, .011)]:
				_disc(pc, spot.x, spot.y, spot.z, "9fd96e", 6)
		"Dolphins":
			_flat(pc, 0, -.074, .19, .022, "3f86d0", 1)
			_tri(pc, -.07, .0, .05, .045, "5a9fe0", 2, -PI / 2 - .5)
			_bump(pc, -.01, -.005, .13, .075, "7aa6d6", 3)
			_tri(pc, -.005, .045, .04, .045, "5a86bb", 3)
			_bump(pc, .045, -.012, .06, .035, "7aa6d6", 4)
			_bump(pc, .0, -.025, .1, .035, "eaf3fb", 5)
			_disc(pc, .04, .008, .014, WHITE, 6)
			_disc(pc, .042, .008, .008, DARK, 7)
			for b in [Vector3(.075, .058, .014), Vector3(.083, .075, .01)]:
				_disc(pc, b.x, b.y, b.z, "d4f0fb", 2)
		"Cars":
			_flat(pc, 0, -.07, .19, .02, "8a8f98", 1)
			_bump(pc, 0, -.012, .15, .05, "d9534a", 2)
			_bump(pc, -.005, .022, .09, .052, "d9534a", 3)
			_flat(pc, -.025, .024, .035, .03, "a9d6ee", 4)
			_flat(pc, .02, .024, .035, .03, "a9d6ee", 4)
			for x in [-.045, .045]:
				_disc(pc, x, -.045, .048, DARK, 5)
				_disc(pc, x, -.045, .022, "d8dde2", 6)
			_disc(pc, .068, -.01, .016, "f2d27a", 5)
		"Trains":
			_flat(pc, 0, -.062, .19, .012, "6b6f78", 1)
			_flat(pc, -.01, -.005, .15, .068, "3f6fb5", 2)
			_flat(pc, -.04, .052, .05, .042, "3f6fb5", 2)
			_flat(pc, .04, .052, .026, .042, "d9534a", 2)
			_flat(pc, .062, -.02, .032, .03, "d9534a", 2)
			for x in [-.05, -.012, .026]:
				_flat(pc, x, .003, .026, .028, "e6f4fb", 4)
			for x in [-.055, -.01, .04]:
				_disc(pc, x, -.05, .034, DARK, 5)
				_disc(pc, x, -.05, .014, "d8dde2", 6)
			_disc(pc, .07, .06, .016, "f0f0f0", 3)
		"Airplanes":
			_tri(pc, -.07, .02, .04, .05, "2f7fc0", 2, 0)
			_tri(pc, -.015, -.03, .09, .06, "2f7fc0", 2, PI * .72)
			_tri(pc, -.015, .06, .06, .04, "2f7fc0", 2, PI * .72)
			_bump(pc, .0, .015, .15, .05, "f4f6f8", 3)
			_tri(pc, .088, .015, .03, .04, "d9534a", 3, -PI / 2)
			for x in [-.03, 0.0, .03]:
				_disc(pc, x, .02, .012, "6ea8d8", 4)
			_bump(pc, -.015, -.03, .05, .02, "dfe5ea", 5)
		"Flowers":
			_flat(pc, 0, -.076, .19, .016, "7cc35a", 1)
			_flat(pc, 0, -.025, .014, .085, "3f9a3a", 2)
			_tri(pc, .02, -.045, .03, .018, "3f9a3a", 2, -PI / 2 + .6)
			for k in 6:
				var a := TAU * k / 6.0
				_bump(pc, sin(a) * .036, .045 + cos(a) * .036, .05, .05, "f08aa8", 3, .01)
			_bump(pc, 0, .045, .04, .04, "f2c231", 6, .012)
		"Trees":
			_flat(pc, 0, -.076, .19, .016, "7cc35a", 1)
			_flat(pc, 0, -.035, .028, .07, "8a5a2e", 2)
			_bump(pc, 0, .025, .12, .1, "3f9a3a", 3)
			_bump(pc, -.025, .005, .08, .07, "58b24a", 4)
			_bump(pc, .03, .04, .07, .06, "58b24a", 4)
			for a in [Vector2(-.02, .03), Vector2(.03, .0), Vector2(.0, .06)]:
				_disc(pc, a.x, a.y, .014, "d9534a", 6)
		"Birds":
			_seg(pc, Vector2(-.09, -.058), Vector2(.09, -.048), .016, "8a5a2e", 2)
			_bump(pc, -.07, -.045, .032, .018, "6fbf4a", 3)
			_bump(pc, .072, -.035, .032, .018, "6fbf4a", 3)
			for x in [-.012, .008]:
				_seg(pc, Vector2(x, -.03), Vector2(x, -.05), .006, "f2a02a", 2)
			_tri(pc, -.058, .005, .035, .05, "2f6fb8", 2, PI * .62)
			_bump(pc, -.005, -.005, .1, .075, "3f86d0", 3)
			_bump(pc, .038, .035, .055, .05, "3f86d0", 4)
			_bump(pc, .008, -.02, .06, .04, "eaf6fb", 6)
			_bump(pc, -.022, .002, .055, .032, "2f6fb8", 6)
			_tri(pc, .074, .035, .024, .026, "f2a02a", 5, -PI / 2)
			_disc(pc, .048, .045, .014, DARK, 8)
			_disc(pc, .051, .048, .005, WHITE, 9)
		"The Solar System":
			for st in [Vector2(.0, .07), Vector2(.08, .07), Vector2(.085, -.07), Vector2(-.01, -.072), Vector2(.05, .03)]:
				_disc(pc, st.x, st.y, .006, "fff2b0", 1)
			_disc(pc, -.044, 0, .1, "f28c28", 2)
			_disc(pc, -.044, 0, .086, "f7c23a", 3)
			_disc(pc, .025, .05, .034, "3f7fd0", 2)
			_bump(pc, .02, .055, .014, .012, "5fae45", 3, .006)
			_bump(pc, .032, .043, .01, .01, "5fae45", 3, .006)
			_disc(pc, .028, -.05, .026, "d9534a", 2)
			_disc(pc, .066, 0, .03, "e8c06a", 2)
			art.ring(pc + Vector3(-.066, 0, -.012), Vector3(.058, .004, .018), "f2dca0", Art.SATIN, Vector3(PI / 2 + .25, 0, 0), .75, 20)
		"Rockets":
			for st in [Vector2(-.07, .06), Vector2(.07, .05), Vector2(-.06, -.04), Vector2(.075, -.05), Vector2(-.03, .075)]:
				_disc(pc, st.x, st.y, .007, "fff2b0", 1)
			_tri(pc, 0, -.063, .04, .04, "f28c28", 2, PI)
			_tri(pc, 0, -.06, .02, .026, "f7d23a", 3, PI)
			for sx in [-1.0, 1.0]:
				_tri(pc, sx * .03, -.028, .032, .05, "d9534a", 2)
			_bump(pc, 0, .0, .052, .11, WHITE, 3)
			_tri(pc, 0, .058, .04, .036, "d9534a", 6)
			_disc(pc, 0, .012, .032, "9aa3ab", 6)
			_disc(pc, 0, .012, .022, "5ab0e8", 7)
		"Stars":
			for st in [Vector3(-.065, .06, .022), Vector3(.07, .06, .018), Vector3(-.07, -.06, .016), Vector3(.068, -.058, .02)]:
				_star(pc, st.x, st.y, st.z * .5, "fff2b0", 1)
			_star(pc, 0, -.005, .078, "d99a1a", 2)
			_star(pc, 0, -.005, .07, "f7c23a", 3)
			_bump(pc, 0, -.005, .05, .05, "f9d45c", 4, .01)
		"Mountains":
			_disc(pc, .062, .055, .032, "f7c23a", 1)
			_tri(pc, .042, -.025, .1, .1, "8fa3b8", 2)
			_tri(pc, .042, .006, .038, .038, WHITE, 3)
			_tri(pc, -.025, -.015, .14, .12, "6f86a0", 4)
			_tri(pc, -.025, .022, .052, .046, WHITE, 5)
			_flat(pc, 0, -.076, .19, .018, "7cc35a", 6)
		"World Map":
			_flat(pc, 0, -.078, .07, .012, "8a5a2e", 1)
			_flat(pc, 0, -.07, .012, .02, "8a5a2e", 1)
			_bump(pc, 0, .006, .13, .13, "3f86d0", 2, .03)
			for c in [Vector4(-.03, .03, .045, .035), Vector4(-.018, -.022, .03, .045), Vector4(.035, .018, .04, .05), Vector4(.032, -.038, .022, .02)]:
				_bump(pc, c.x, c.y, c.z, c.w, "5fae45", 6, .012)
			art.ring(pc + Vector3(0, .006, -.012), Vector3(.152, .008, .152), "c9a24a", Art.METAL, Vector3(PI / 2, 0, 0), .9, 28)
		"Rivers":
			var pts := [Vector2(.025, .085), Vector2(-.03, .045), Vector2(.025, .0), Vector2(-.025, -.045), Vector2(.012, -.085)]
			for k in pts.size() - 1:
				_seg(pc, pts[k], pts[k + 1], .042, "3f86d0", 2)
				_seg(pc, pts[k] + Vector2(.006, 0), pts[k + 1] + Vector2(.006, 0), .012, "8fd0f2", 3)
			for tr in [Vector2(-.065, .045), Vector2(.065, .05), Vector2(.062, -.035), Vector2(-.068, -.04)]:
				_tree(pc, tr.x, tr.y, .036, 2)
		"Pyramids":
			_disc(pc, .062, .055, .03, "f28c28", 1)
			_tri(pc, .05, -.04, .08, .06, "c98a2e", 2)
			_tri(pc, -.018, -.02, .14, .11, "e8a83a", 3)
			for y in [-.05, -.025, 0.0]:
				_flat(pc, -.018, y, .14 * (.035 - y) / .11 - .012, .004, "b87a2a", 4)
			_flat(pc, 0, -.077, .19, .016, "f2d27a", 5)
		"Knights":
			_seg(pc, Vector2(-.045, -.052), Vector2(.065, .07), .016, "c3cbd1", 2)
			_seg(pc, Vector2(-.064, -.034), Vector2(-.028, -.07), .012, "c9a24a", 3)
			_seg(pc, Vector2(-.047, -.054), Vector2(-.066, -.073), .011, "8a5a2e", 3)
			_flat(pc, 0, .022, .1, .06, "1f3f78", 4)
			_tri(pc, 0, -.028, .1, .062, "1f3f78", 4, PI)
			_flat(pc, 0, .024, .088, .052, "3a6fc0", 5)
			_tri(pc, 0, -.026, .088, .054, "3a6fc0", 5, PI)
			_flat(pc, 0, -.004, .016, .09, "f2c231", 6)
			_flat(pc, 0, .022, .074, .016, "f2c231", 6)
		"Kings and Queens":
			_bump(pc, 0, -.06, .16, .04, "d9534a", 2)
			for sx in [-1.0, 1.0]:
				_disc(pc, sx * .078, -.062, .014, "f2c231", 4)
			for x in [-.045, 0.0, .045]:
				_tri(pc, x, .006, .04, .05, "f2c231", 5)
				_bump(pc, x, .033, .016, .016, "fff2b0", 6)
			_flat(pc, 0, -.03, .12, .036, "e8b42a", 6)
			_disc(pc, -.035, -.03, .016, "d9534a", 7)
			_disc(pc, 0, -.03, .018, "3f7fd0", 7)
			_disc(pc, .035, -.03, .016, "4e9e3a", 7)
		"Soccer":
			_flat(pc, 0, -.045, .19, .02, "8fd06a", 1)
			_disc(pc, 0, 0, .145, "3a3a3a", 2)
			_disc(pc, 0, 0, .135, WHITE, 3)
			for k in 5:
				var a := TAU * k / 5.0
				_seg(pc, Vector2(sin(a), cos(a)) * .02, Vector2(sin(a), cos(a)) * .05, .004, "3a3a3a", 4)
				_disc(pc, sin(a) * .052, cos(a) * .052, .028, "2a2a2a", 5, 5)
			_disc(pc, 0, 0, .042, "2a2a2a", 5, 5)
		"Basketball":
			_disc(pc, 0, 0, .148, "7a3a12", 2)
			_disc(pc, 0, 0, .138, "e8772e", 3)
			_bump(pc, -.03, .03, .04, .03, "f59a52", 3, .004)
			_seg(pc, Vector2(0, -.066), Vector2(0, .066), .006, "3a1e0e", 5)
			_seg(pc, Vector2(-.066, 0), Vector2(.066, 0), .006, "3a1e0e", 5)
			_arc(pc, -.11, 0, .085, -38, 38, .006, "3a1e0e", 5)
			_arc(pc, .11, 0, .085, 142, 218, .006, "3a1e0e", 5)
		"Swimming":
			for y in [-.068, .068]:
				for x in [-.07, -.035, 0.0, .035, .07]:
					_arc(pc, x, y - .006, .016, 20, 160, .006, "d4f0fb", 1, 5)
			art.ring(pc + Vector3(0, 0, -.012), Vector3(.13, .03, .13), "e8463a", Art.SATIN, Vector3(PI / 2, 0, 0), .48, 28)
			for k in 4:
				var a := PI / 4 + k * PI / 2
				_bump(pc, cos(a) * .048, sin(a) * .048, .03, .03, WHITE, 5, .028)
		"Painting":
			_bump(pc, -.008, -.002, .155, .118, "d9b07a", 2)
			_disc(pc, -.045, -.03, .026, "fdf3dc", 5)
			var paints := [["d9534a", -.045, .022], ["f2c231", -.008, .036], ["3f7fd0", .03, .026], ["4e9e3a", .048, -.008], ["b2437e", .01, -.036]]
			for paint in paints:
				_bump(pc, paint[1], paint[2], .03, .028, paint[0], 4, .01)
			_seg(pc, Vector2(.085, -.08), Vector2(.03, -.022), .012, "8a5a2e", 7)
			_seg(pc, Vector2(.03, -.022), Vector2(.018, -.009), .015, "c3cbd1", 7)
			_bump(pc, .01, .0, .022, .022, "d9534a", 8)
		"Drawing":
			_arc(pc, -.03, -.06, .03, 180, 0, .006, "3f7fd0", 1, 6)
			_arc(pc, .03, -.06, .03, 180, 360, .006, "3f7fd0", 1, 6)
			var tip := Vector2(-.042, -.03)
			var back := Vector2(.07, .075)
			var d := (back - tip).normalized()
			var wood := tip + d * .03
			_seg(pc, wood + d * .012, back - d * .028, .032, "f2c231", 3)
			_flat(pc, (wood.x + back.x) * .5 - d.y * .0, (wood.y + back.y) * .5, .006, (back - wood).length() - .04, "e0a82a", 4, atan2(-d.x, d.y))
			_seg(pc, back - d * .028, back - d * .016, .034, "c3cbd1", 3)
			_seg(pc, back - d * .012, back - d * .002, .032, "f08aa8", 3)
			_tri(pc, tip.x + d.x * .018, tip.y + d.y * .018, .032, .032, "f0cc96", 3, atan2(d.x, -d.y))
			_tri(pc, tip.x + d.x * .006, tip.y + d.y * .006, .011, .01, "3a3a3a", 4, atan2(d.x, -d.y))
		"Music":
			var ink := "4a2a6a"
			_bump(pc, -.035, -.048, .046, .032, ink, 3)
			_bump(pc, .042, -.036, .046, .032, ink, 3)
			_flat(pc, -.0165, -.002, .009, .095, ink, 3)
			_flat(pc, .0605, .01, .009, .095, ink, 3)
			_seg(pc, Vector2(-.0165, .048), Vector2(.0605, .06), .02, ink, 3)
			for sp in [Vector2(-.07, .06), Vector2(.075, -.065), Vector2(-.075, -.01)]:
				_star(pc, sp.x, sp.y, .012, "f2c231", 2)
		"Pancakes":
			_bump(pc, 0, -.068, .17, .026, WHITE, 2)
			for k in 3:
				var y := -.05 + k * .024
				_bump(pc, 0, y - .004, .132, .03, "c98a3a", 3 + k * 2)
				_bump(pc, 0, y, .128, .026, "edb55a", 4 + k * 2)
			_bump(pc, 0, .016, .11, .016, "8a4a1e", 10)
			_bump(pc, -.035, .0, .014, .03, "8a4a1e", 10)
			_bump(pc, .03, -.006, .012, .04, "8a4a1e", 10)
			_flat(pc, 0, .028, .032, .02, "f7e28a", 12)
		"Pizza":
			_tri(pc, 0, -.012, .132, .132, "e0603a", 1, PI)
			_tri(pc, 0, -.01, .12, .12, "f6c445", 2, PI)
			_bump(pc, 0, .055, .14, .032, "c98a3a", 3)
			for pep in [Vector3(-.024, .028, .026), Vector3(.024, .025, .024), Vector3(0, -.018, .022)]:
				_disc(pc, pep.x, pep.y, pep.z, "c0392b", 4)
		"Cookies":
			_disc(pc, 0, 0, .148, "a8743a", 2)
			_disc(pc, 0, 0, .138, "dba35c", 3)
			_disc(pc, .062, .052, .05, "f9d3dc", 4)
			for chip in [Vector3(-.035, .025, .02), Vector3(.0, .042, .016), Vector3(-.008, -.005, .02), Vector3(.035, .002, .018), Vector3(-.042, -.03, .016), Vector3(.012, -.042, .02), Vector3(.045, -.035, .015)]:
				_bump(pc, chip.x, chip.y, chip.z, chip.z, "5a3420", 4, .008)
		"Dogs":
			var fur := "c98a4a"
			for sx in [-1.0, 1.0]:
				_bump(pc, sx * .058, .012, .036, .078, "8a5a2e", 2)
			_bump(pc, 0, .0, .11, .1, fur, 3)
			_bump(pc, 0, -.03, .06, .042, "f3dcb6", 4)
			_disc(pc, -.026, .018, .016, DARK, 5)
			_disc(pc, .026, .018, .016, DARK, 5)
			_bump(pc, 0, -.016, .026, .018, DARK, 6, .008)
			_bump(pc, 0, -.048, .016, .02, "e8687a", 5, .006)
		"Cats":
			var fur := "f0a24a"
			for sx in [-1.0, 1.0]:
				_tri(pc, sx * .042, .052, .042, .046, fur, 2, sx * .25)
				_tri(pc, sx * .042, .048, .02, .024, "f6c8b0", 3, sx * .25)
			_bump(pc, 0, -.004, .12, .1, fur, 3)
			for sx in [-1.0, 1.0]:
				_flat(pc, sx * .03, .02, .022, .006, "c96f22", 5, sx * .2)
				_disc(pc, sx * .026, .0, .018, "4e9e3a", 5)
				_flat(pc, sx * .026, .0, .005, .015, DARK, 6)
				for k in 2:
					_seg(pc, Vector2(sx * .024, -.026 + k * .012), Vector2(sx * .075, -.032 + k * .022), .003, "5a3a22", 6)
			_tri(pc, 0, -.018, .016, .012, "e8687a", 6, PI)
		"Elephants":
			var skin := "9aa7b8"
			for sx in [-1.0, 1.0]:
				_bump(pc, sx * .055, .015, .06, .08, "8494a8", 2)
				_bump(pc, sx * .055, .015, .04, .058, "f0b8c4", 3, .006)
			_bump(pc, 0, .02, .08, .08, skin, 4)
			_seg(pc, Vector2(0, -.005), Vector2(0, -.055), .028, skin, 5)
			_seg(pc, Vector2(0, -.055), Vector2(.022, -.072), .024, skin, 5)
			_disc(pc, -.022, .03, .012, DARK, 7)
			_disc(pc, .022, .03, .012, DARK, 7)
			for sx in [-1.0, 1.0]:
				_tri(pc, sx * .026, -.022, .012, .03, WHITE, 6, PI + sx * .3)
		"Tennis":
			_disc(pc, 0, 0, .148, "9fbf2a", 2)
			_disc(pc, 0, 0, .138, "d8ee4a", 3)
			_bump(pc, -.03, .03, .04, .03, "eaf77a", 3, .004)
			_arc(pc, -.1, 0, .072, -48, 48, .009, WHITE, 5)
			_arc(pc, .1, 0, .072, 132, 228, .009, WHITE, 5)
		"Guitar":
			var wood := "d98a3a"
			_seg(pc, Vector2(.0, .0), Vector2(.0, .078), .02, "7a4a22", 2)
			_flat(pc, 0, .078, .03, .02, "5a3420", 3)
			_disc(pc, 0, -.048, .085, wood, 3)
			_disc(pc, 0, -.0, .065, wood, 3)
			_disc(pc, 0, -.03, .026, "5a3420", 4)
			_flat(pc, 0, -.064, .04, .008, "5a3420", 4)
			for x in [-.004, .004]:
				_flat(pc, x, .012, .0015, .13, "eae3d2", 5)
		"Piano":
			_flat(pc, 0, -.004, .18, .118, DARK, 1)
			for k in 7:
				_flat(pc, -.0765 + k * .0255, -.01, .023, .1, WHITE, 2)
			for k in [0, 1, 3, 4, 5]:
				_flat(pc, -.064 + k * .0255, .016, .014, .056, DARK, 3)
		"Drums":
			_bump(pc, 0, -.03, .15, .1, "c0392b", 2)
			_flat(pc, 0, -.03, .15, .078, "d9534a", 2)
			for x in [-.05, -.017, .017, .05]:
				_seg(pc, Vector2(x, -.062), Vector2(x + .015, .002), .004, "f2c231", 3)
			_bump(pc, 0, .012, .15, .038, "f4efe2", 4)
			_seg(pc, Vector2(-.06, .02), Vector2(-.02, .078), .008, "c98a4a", 6)
			_seg(pc, Vector2(.06, .02), Vector2(.02, .078), .008, "c98a4a", 6)
			_disc(pc, -.06, .02, .016, "f4efe2", 7)
			_disc(pc, .06, .02, .016, "f4efe2", 7)
		"Cake":
			_bump(pc, 0, -.07, .17, .022, WHITE, 2)
			_flat(pc, 0, -.04, .13, .046, "f08aa8", 3)
			_flat(pc, 0, .01, .1, .05, "f6c8d8", 3)
			for k in 5:
				_disc(pc, -.052 + k * .026, -.016, .022, WHITE, 4)
			for k in 4:
				_disc(pc, -.038 + k * .025, .036, .02, WHITE, 4)
			_flat(pc, 0, .052, .01, .03, "7aa6d6", 5)
			_bump(pc, 0, .074, .014, .02, "f2c231", 6, .008)
			_disc(pc, -.03, -.044, .014, "c0392b", 5)
			_disc(pc, .03, -.044, .014, "c0392b", 5)
		"Cactus":
			var green := "4e9e3a"
			_flat(pc, 0, -.064, .08, .04, "c0703a", 2)
			_flat(pc, 0, -.044, .09, .012, "a85a2e", 3)
			_seg(pc, Vector2(0, -.035), Vector2(0, .06), .042, green, 3)
			_seg(pc, Vector2(-.021, .0), Vector2(-.05, .0), .022, green, 3)
			_seg(pc, Vector2(-.05, .0), Vector2(-.05, .035), .022, green, 3)
			_seg(pc, Vector2(.021, -.012), Vector2(.048, -.012), .022, green, 3)
			_seg(pc, Vector2(.048, -.012), Vector2(.048, .02), .022, green, 3)
			_flat(pc, 0, .012, .004, .08, "3a7a2a", 4)
			_bump(pc, 0, .078, .024, .02, "f08aa8", 5, .008)
		"Fairy Tale":
			_flat(pc, 0, -.077, .19, .016, "9fd38a", 1)
			var wall := "f59ac0"
			var roof := "7a4fb8"
			_flat(pc, 0, -.042, .09, .056, wall, 2)
			for sx in [-1.0, 1.0]:
				_flat(pc, sx * .052, -.03, .032, .09, wall, 2)
				_tri(pc, sx * .052, .035, .044, .04, roof, 3)
				_disc(pc, sx * .052, -.01, .012, roof, 3)
			_flat(pc, 0, -.01, .036, .08, wall, 3)
			_tri(pc, 0, .055, .05, .05, roof, 4)
			_tri(pc, .006, .084, .012, .012, "f2c231", 4, -PI / 2)
			_flat(pc, 0, -.062, .022, .03, roof, 4)
			_disc(pc, 0, -.047, .022, roof, 4)
		"Mystery":
			_seg(pc, Vector2(.024, -.026), Vector2(.072, -.076), .022, "8a5a2e", 2)
			_disc(pc, -.015, .015, .1, "bfe3f5", 2)
			art.ring(pc + Vector3(.015, .015, -.012), Vector3(.114, .012, .114), "c9a24a", Art.METAL, Vector3(PI / 2, 0, 0), .82, 28)
			_arc(pc, -.015, .032, .019, 165, -60, .012, "2f3560", 4, 8)
			_seg(pc, Vector2(-.0055, .0155), Vector2(-.015, .002), .012, "2f3560", 4)
			_disc(pc, -.015, -.018, .014, "2f3560", 4)
		"Adventure":
			_flat(pc, 0, -.072, .19, .026, "f0cc6b", 1)
			_flat(pc, 0, -.04, .12, .056, "a0612e", 2)
			_bump(pc, 0, .0, .124, .05, "b8733a", 2)
			_flat(pc, 0, -.012, .124, .008, "7a4a22", 3)
			for sx in [-1.0, 1.0]:
				_flat(pc, sx * .042, -.02, .012, .09, "f2c231", 5)
			_flat(pc, 0, -.022, .024, .028, "f2c231", 6)
			_disc(pc, 0, -.02, .008, DARK, 7)
			for coin in [Vector3(-.075, -.064, .022), Vector3(.074, -.066, .02), Vector3(.058, -.06, .018)]:
				_disc(pc, coin.x, coin.y, coin.z, "f2c231", 3)
