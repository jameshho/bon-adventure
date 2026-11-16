extends RefCounted
## The evidence objects of the police evidence game (6 Nov 2026) and the labelled ones on the
## evidence room shelves. Since 8 Nov 2026 (second pass, user request: common, distinct and
## good-looking objects) the ten kinds are stone, coconut, frying pan, dumbbell, key, pencil,
## ball, pillow, sponge and towel, modelled in the town's product style (the shared builder of
## scripts/buildings/supermarket_products.gd: one merged low-poly mesh with vertex colours in
## the matte / satin / metal finishes, docs/guides/TOWN_DESIGN_BRIEF.md "Supermarket product art").
## Station-local units, bottom at y 0, long side along local z, one size per kind; the object
## dictionary (detective_clues.gd random_object()) only picks the colour variant (data
## "color"). The tested properties (hard/soft, rough/smooth, heavy/light) show when a tool is
## used: the session animates the object and badge() puts a result icon over it (no words, so
## the word must be understood).
const PATH := "res://data/detective_game.json"

static func load_data() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return parsed if parsed is Dictionary else {}

## The evidence kind whose word is `word` ("" when none).
static func kind_for_word(data: Dictionary, word: String) -> String:
	var objects: Dictionary = data.get("evidence", {}).get("objects", {})
	for kind in objects:
		if str(objects[kind].get("word", "")) == word:
			return str(kind)
	return ""

## The fixed look of a shelf exhibit: the first colour, or data "evidence.shelf".
static func shelf_look(data: Dictionary, kind: String) -> Dictionary:
	var spec: Dictionary = data.get("evidence", {}).get("objects", {}).get(kind, {})
	var look := {"kind": kind, "word": str(spec.get("word", kind))}
	if spec.has("color"):
		look["color"] = spec.color[0]
	look.merge(data.get("evidence", {}).get("shelf", {}).get(kind, {}), true)
	return look

## A new object: root "EvidenceItem" with a child "Body" (what squashes and turns) holding the
## one model mesh. The root's meta "evidence_size" is its half-extents.
static func build(kind: String, item: Dictionary, _game = null) -> Node3D:
	var data := load_data()
	var colors: Dictionary = data.get("evidence", {}).get("colors", {})
	var tint := str(colors.get(str(item.get("color", "")), "9aa1a8"))
	var root := Node3D.new()
	root.name = "EvidenceItem"
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var mesh := MeshInstance3D.new()
	mesh.name = kind.capitalize()
	mesh.mesh = model(kind, tint)
	body.add_child(mesh)
	var box := mesh.mesh.get_aabb() if mesh.mesh != null else AABB(Vector3(-.15, 0, -.15), Vector3(.3, .3, .3))
	root.set_meta("evidence_size", Vector3(maxf(absf(box.position.x), box.end.x), box.end.y / 2.0, maxf(absf(box.position.z), box.end.z)))
	return root

## The mesh of one evidence object of `kind` whose main colour is `tint` (hex).
static func model(kind: String, tint: String) -> ArrayMesh:
	var art = Art.new()
	art.begin()
	match kind:
		"stone": _stone(art, tint)
		"coconut": _coconut(art)
		"pan": _pan(art, tint)
		"dumbbell": _dumbbell(art, tint)
		"key": _key(art, tint)
		"pencil": _pencil(art, tint)
		"ball": _ball(art, tint)
		"pillow": _pillow(art, tint)
		"sponge": _sponge(art, tint)
		"towel": _towel(art, tint)
		_: art.bx(Vector3(0, .1, 0), Vector3(.2, .2, .2), tint)
	return art.finish("Evidence " + kind)

const Art := preload("res://scripts/buildings/supermarket_products.gd")
const MATTE := 0
const SATIN := 1
const METAL := 2
## Along local z: the cylinder primitive's axis turned from y to z.
const ALONG_Z := Vector3(PI / 2, 0, 0)

## Hard, rough, heavy: a grey river stone in three lumps with dark speckles.
static func _stone(art, tint: String) -> void:
	art.ball(Vector3(0, .1, 0), Vector3(.3, .2, .38), tint, MATTE, Vector3(0, .4, 0), 9)
	art.ball(Vector3(.05, .14, -.05), Vector3(.18, .13, .22), art.lighter(tint, .12), MATTE, Vector3(.15, -.3, .2), 8)
	art.ball(Vector3(-.07, .08, .09), Vector3(.15, .1, .18), art.darker(tint, .08), MATTE, Vector3(0, .5, -.15), 8)
	for p in [Vector3(-.05, .195, -.03), Vector3(.05, .2, .05), Vector3(.1, .15, -.1), Vector3(-.11, .13, .07), Vector3(.02, .17, .13), Vector3(-.02, .2, -.12)]:
		art.ball(p, Vector3(.03, .014, .03), art.darker(tint, .4), MATTE, Vector3.ZERO, 6)

## Hard, rough, heavy: a brown coconut with fibre tufts and three eyes.
static func _coconut(art) -> void:
	art.ball(Vector3(0, .145, 0), Vector3(.29, .29, .31), "6d4c3d", MATTE, Vector3.ZERO, 12)
	for k in 14:
		var a := k * TAU / 14.0
		var up := .07 + (k % 3) * .06
		var r := sqrt(maxf(.0, .0225 - pow(up - .145, 2))) * .97
		art.ball(Vector3(cos(a) * r, up, sin(a) * r), Vector3(.07, .045, .07), "7d5948" if k % 2 == 0 else "5a3e30", MATTE, Vector3(0, a, .4), 6)
	for k in 3:
		var a := k * TAU / 3 + .3
		art.ball(Vector3(cos(a) * .028, .285, sin(a) * .028), Vector3(.03, .014, .03), "2e211a", MATTE, Vector3.ZERO, 6)

## Hard, smooth, heavy: a frying pan with a dark cooking surface and a wooden handle.
static func _pan(art, tint: String) -> void:
	var c := Vector3(0, 0, -.09)
	art.cyl(c + Vector3(0, .035, 0), Vector3(.3, .07, .3), tint, MATTE, Vector3.ZERO, 16, 1.2)
	art.cyl(c + Vector3(0, .064, 0), Vector3(.33, .006, .33), "2b2e33", MATTE, Vector3.ZERO, 16)
	art.ring(c + Vector3(0, .07, 0), Vector3(.37, .02, .37), art.lighter(tint, .18), SATIN, Vector3.ZERO, .9, 16)
	art.cyl(c + Vector3(0, .02, .17), Vector3(.05, .05, .05), "c3cbd1", METAL, ALONG_Z, 8)
	art.bx(c + Vector3(0, .045, .3), Vector3(.05, .032, .22), "9b6a3e", MATTE, Vector3(-.12, 0, 0))
	art.cyl(c + Vector3(0, .062, .37), Vector3(.022, .004, .022), "3a2a1e", MATTE, Vector3(-.12, 0, 0), 8)

## Hard, smooth, heavy: a hex dumbbell, coloured weights on a steel bar.
static func _dumbbell(art, tint: String) -> void:
	var y := .078
	art.cyl(Vector3(0, y, 0), Vector3(.036, .26, .036), "c3cbd1", METAL, ALONG_Z, 8)
	art.cyl(Vector3(0, y, 0), Vector3(.046, .13, .046), "5f666e", MATTE, ALONG_Z, 8)
	for side in [-1.0, 1.0]:
		art.cyl(Vector3(0, y, side * .145), Vector3(.17, .09, .17), tint, MATTE, ALONG_Z, 6)
		art.cyl(Vector3(0, y, side * .145), Vector3(.12, .094, .12), art.darker(tint, .2), MATTE, ALONG_Z, 6)
		art.cyl(Vector3(0, y, side * .087), Vector3(.07, .03, .07), "c3cbd1", METAL, ALONG_Z, 10)

## Hard, smooth, light: a big brass or steel key lying flat.
static func _key(art, tint: String) -> void:
	art.ring(Vector3(0, .02, -.12), Vector3(.17, .04, .17), tint, METAL, Vector3.ZERO, .42, 16)
	art.bx(Vector3(0, .02, -.02), Vector3(.075, .04, .04), tint, METAL)
	art.bx(Vector3(0, .02, .09), Vector3(.045, .036, .2), tint, METAL)
	for k in 3:
		art.bx(Vector3(.035, .02, .1 + k * .042), Vector3(.03 + (k % 2) * .015, .034, .026), tint, METAL)
	art.cyl(Vector3(0, .02, .19), Vector3(.045, .036, .045), tint, METAL, Vector3.ZERO, 8)

## Hard, smooth, light: a sharpened hexagonal pencil with a metal band and an eraser.
static func _pencil(art, tint: String) -> void:
	var y := .045
	art.cyl(Vector3(0, y, 0), Vector3(.09, .3, .09), tint, SATIN, ALONG_Z, 6)
	art.cyl(Vector3(0, y, .195), Vector3(.09, .09, .09), "f1d3a2", MATTE, ALONG_Z, 6, .28)
	art.cyl(Vector3(0, y, .25), Vector3(.027, .024, .027), "33363b", MATTE, ALONG_Z, 6, .2)
	art.cyl(Vector3(0, y, -.17), Vector3(.094, .04, .094), "c3cbd1", METAL, ALONG_Z, 10)
	art.cyl(Vector3(0, y, -.21), Vector3(.088, .045, .088), "f29bb0", MATTE, ALONG_Z, 10)

## Soft, smooth, light: a play ball with two crossing white bands.
static func _ball(art, tint: String) -> void:
	art.ball(Vector3(0, .15, 0), Vector3(.3, .3, .3), tint, SATIN, Vector3.ZERO, 16)
	art.cyl(Vector3(0, .15, 0), Vector3(.305, .05, .305), "fafafa", SATIN, Vector3(0, 0, PI / 2), 16)
	art.cyl(Vector3(0, .15, 0), Vector3(.305, .05, .305), "fafafa", SATIN, Vector3(PI / 2, 0, 0), 16)
	art.ball(Vector3(-.06, .25, -.05), Vector3(.06, .03, .05), art.lighter(tint, .45), SATIN, Vector3(.4, 0, .5), 8)

## Soft, smooth, light: a plump pillow on a flatter rim with a piped seam and a centre tuft.
static func _pillow(art, tint: String) -> void:
	art.ball(Vector3(0, .095, 0), Vector3(.33, .17, .45), tint, MATTE, Vector3.ZERO, 14)
	art.ball(Vector3(0, .045, 0), Vector3(.37, .09, .49), tint, MATTE, Vector3.ZERO, 14)
	art.cyl(Vector3(0, .047, 0), Vector3(.372, .012, .492), art.darker(tint, .14), MATTE, Vector3.ZERO, 16)
	art.ball(Vector3(0, .178, 0), Vector3(.05, .012, .05), art.darker(tint, .1), MATTE, Vector3.ZERO, 8)

## Soft, rough, light: a kitchen sponge with a green scouring layer and open pores.
static func _sponge(art, tint: String) -> void:
	art.bx(Vector3(0, .055, 0), Vector3(.22, .11, .34), tint, MATTE)
	art.bx(Vector3(0, .128, 0), Vector3(.22, .036, .34), "2f8a3c", MATTE)
	var pore: String = art.darker(tint, .3)
	for k in 7:
		var z := -.14 + k * .047
		for x in [-1.0, 1.0]:
			art.ball(Vector3(x * .11, .03 + (k % 3) * .028, z + (.012 if x > 0 else 0.0)), Vector3(.012, .022, .026), pore, MATTE, Vector3.ZERO, 6)
	for k in 4:
		for z in [-1.0, 1.0]:
			art.ball(Vector3(-.075 + k * .05, .035 + (k % 2) * .04, z * .17), Vector3(.026, .022, .012), pore, MATTE, Vector3.ZERO, 6)

## Soft, rough, light: a rolled towel with white stripes, its spiral ends and terry loops.
static func _towel(art, tint: String) -> void:
	var y := .095
	art.cyl(Vector3(0, y, 0), Vector3(.19, .34, .19), tint, MATTE, ALONG_Z, 14)
	for z in [-1.0, 1.0]:
		art.cyl(Vector3(0, y, z * .115), Vector3(.193, .03, .193), "f4efe6", MATTE, ALONG_Z, 14)
		art.ring(Vector3(0, y, z * .171), Vector3(.13, .01, .13), art.darker(tint, .2), MATTE, ALONG_Z, .55, 12)
		art.cyl(Vector3(0, y, z * .171), Vector3(.05, .006, .05), art.darker(tint, .3), MATTE, ALONG_Z, 8)
	art.bx(Vector3(.055, .17, 0), Vector3(.07, .02, .34), tint, MATTE, Vector3(0, 0, -.5))
	for k in 12:
		var a := -.9 + (k % 4) * .6
		var z := -.07 + (k / 4) * .07
		art.ball(Vector3(sin(a) * .095, y + cos(a) * .095, z), Vector3(.022, .022, .022), art.lighter(tint, .12), MATTE, Vector3.ZERO, 5)

## Result icons of the evidence tools, as SVG (like ui_icons.gd). Redrawn 8 Nov 2026 (second
## pass) in the detective card's look: a navy pin (card fill 13213a, edge 8fb3e8) pointing down
## at the object, a coloured disc and a white glyph in the tool icons' line style. Each pair
## shares one picture and differs in the result: squeeze -> hard (the press stops on a solid
## block, with a clink) / soft (the cushion dents); touch -> rough (a bumpy slab with grit) /
## smooth (a flat slab with a shine); lift -> heavy (a kettlebell that stays down) / light (a feather that rises).
const BADGES := {
	"hard": ["5f6f8c", '<path d="M12 2.5v5.6M9.3 5.4 12 8.1l2.7-2.7"/><rect x="5.5" y="11" width="13" height="9.5" rx="1.8" fill="#ffffff"/><path d="M8.2 9.2 6.6 7.6M15.8 9.2l1.6-1.6"/>'],
	"soft": ["e2709b", '<path d="M12 2.5v7M9.3 7.1 12 9.8l2.7-2.7"/><path d="M4 13.6c0-1.8 1.1-2.8 2.8-2.8 2 0 3 2.8 5.2 2.8s3.2-2.8 5.2-2.8c1.7 0 2.8 1 2.8 2.8v4.1c0 1.6-1.1 2.8-2.8 2.8H6.8C5.1 20.5 4 19.3 4 17.7z" fill="#ffffff"/>'],
	"rough": ["c47f33", '<path d="M3 20.5v-6.2l1.9-1.9 1.7 1.3 2-2.6 1.8 1.9 2.1-1.4 1.6 2.1 2.2-2.7 1.7 1.9 1.9-1.2 1.1 1v7.8z" fill="#ffffff"/><circle cx="6" cy="6.8" r="1.1" fill="#ffffff" stroke="none"/><circle cx="11.5" cy="4.6" r="1.1" fill="#ffffff" stroke="none"/><circle cx="16.5" cy="7.3" r="1.1" fill="#ffffff" stroke="none"/><circle cx="9" cy="8.9" r=".8" fill="#ffffff" stroke="none"/><circle cx="19.2" cy="4.4" r=".8" fill="#ffffff" stroke="none"/>'],
	"smooth": ["3592d6", '<rect x="3" y="13" width="18" height="7.5" rx="1.6" fill="#ffffff"/><path d="M12 2.8l1.2 3 3 1.2-3 1.2-1.2 3-1.2-3-3-1.2 3-1.2z" fill="#ffffff" stroke-width="1"/><path d="M5 9.5h3.5"/>'],
	"heavy": ["5d4fa6", '<path d="M9 10.5a3 3 0 1 1 6 0"/><path d="M6.6 11h10.8l1.7 7.2c.3 1.3-.6 2.3-1.9 2.3H6.8c-1.3 0-2.2-1-1.9-2.3z" fill="#ffffff"/><path d="M3 4v4.5M1.5 7l1.5 1.5L4.5 7M21 4v4.5M19.5 7l1.5 1.5L22.5 7"/>'],
	"light": ["37a87a", '<path d="M16.5 3C10.5 3.8 6.8 8.6 6.3 16.2c5-.6 9.6-5.4 10.2-13.2z" fill="#ffffff"/><path d="M3.8 20.2l7.4-7.4"/><path d="M19.5 21v-5.5M17.2 17.6l2.3-2.3 2.3 2.3"/>'],
}
const BADGE_PIXELS := 128
## Width of a badge in the world (station units).
const BADGE_WIDTH := .24
const PIN_FILL := "13213a"
const PIN_EDGE := "8fb3e8"

## The pin of `value` as an SVG document (24 wide, 28 high; the tail tip at the bottom).
static func badge_svg(value: String) -> String:
	var spec: Array = BADGES.get(value, ["555555", ""])
	var tail := '<path d="M12 27.3 7.9 20.6h8.2z"/>'
	var outline := '<g fill="#%s" stroke="#%s" stroke-width="1.6" stroke-linejoin="round">%s<circle cx="12" cy="11.6" r="10.8"/></g>' % [PIN_FILL, PIN_EDGE, tail]
	var fill := '<g fill="#%s">%s<circle cx="12" cy="11.6" r="10.8"/></g>' % [PIN_FILL, tail]
	var disc := '<circle cx="12" cy="11.6" r="8.7" fill="#%s"/>' % spec[0]
	var glyph := '<g transform="translate(12 11.6) scale(.6) translate(-12 -12)" fill="none" stroke="#ffffff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">%s</g>' % spec[1]
	return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 28" width="24" height="28">%s%s%s%s</svg>' % [outline, fill, disc, glyph]

## The icon of `value` as a texture, drawn each time (a tool press draws at most four).
static func badge_texture(value: String) -> Texture2D:
	var image := Image.new()
	image.load_svg_from_string(badge_svg(value), BADGE_PIXELS / 24.0)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)

## Puts the result icon of `value` ("soft", "rough", "heavy", ...) over an object, replacing
## the one shown before ("" removes it); the pin's tail points down at the object. Returns the
## badge (null when removed).
static func badge(root: Node3D, value: String) -> Sprite3D:
	var old := root.get_node_or_null("Badge")
	if old != null:
		root.remove_child(old)
		old.queue_free()
	if value == "" or not BADGES.has(value):
		return null
	var sprite := Sprite3D.new()
	sprite.name = "Badge"
	sprite.texture = badge_texture(value)
	sprite.pixel_size = BADGE_WIDTH / BADGE_PIXELS
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.no_depth_test = true
	sprite.render_priority = 10
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var extent: Vector3 = root.get_meta("evidence_size", Vector3.ONE * .2)
	sprite.position = Vector3(0, extent.y * 2.0 + .2, 0)
	sprite.set_meta("badge", value)
	root.add_child(sprite)
	return sprite
