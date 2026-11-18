extends Node3D
## The tiles on the mahjong table in front of the home (docs/guides/MAHJONG.md). Made by
## mahjong_session.gd under the table (MahjongTable, home unit) when the town loads: until the
## player sits down they show the preset game in progress (data/mahjong.json "preset"; user,
## 9 Nov 2026), then the player's game, and the preset again after they leave.
##
## 136 tile nodes are made once and placed from the game state (mahjong_game.gd) after every
## change (since 17 Nov 2026 each tile node only holds the pose: all bodies, backs and faces are
## drawn by three MultiMeshes, _sync(), 3 draw calls instead of about 350): the four walls (face down, two high; drawn stacks disappear), each NPC's concealed
## hand standing toward its owner (the player sees the backs; the player's own hand is the
## panel at the bottom of the screen), exposed melds face up at each seat's left, and
## discards face up in rows of six in front of each seat, the last one marked in gold.
## Faces come from one atlas (9 x 4 faces) drawn once in a SubViewport with the same code as
## the panel's tiles (scripts/ui/mahjong_tiles.gd).
##
## Table-local coordinates are town units (the home site; Apartment scale 1.3 applies above).
## Seat s sits along MAHJONG_SEATS[s] (scripts/buildings/home.gd).
const Rules := preload("res://scripts/learning/mahjong_rules.gd")
const Tiles := preload("res://scripts/ui/mahjong_tiles.gd")
const Home := preload("res://scripts/buildings/home.gd")
## Tile size: width, thickness, length (town units; plush scale, the table is 2.0 square, the
## felt 1.84). 10 % larger than first built (user, 9 Nov 2026: 0.073 x 0.053 x 0.1), 0.0803 x
## 0.0583 x 0.11 until 15 Nov 2026. Since then (user, 15 Nov 2026: hard to see on a phone, as
## big as fits, the face-up tiles a little bigger than the face-down ones) two sizes:
## - face down (the walls, the standing hands): TW x TT x TL, 0.95 of that;
## - face up (discards and exposed sets): UP_SCALE times bigger, 1.2 of that.
## The felt has no room for more: the wall's corners need WALL_R - TL / 2 >= 8.5 TW, the
## sets lie between the wall and the rim (0.92), and two rows of discards fill the inside.
const TW := 0.0803 * 0.95
const TT := 0.0583 * 0.95
const TL := 0.11 * 0.95
const UP_SCALE := 1.2 / 0.95
const UW := TW * UP_SCALE
const UT := TT * UP_SCALE
const UL := TL * UP_SCALE
## Felt surface height above the table root (home.gd: top 1.0, felt 0.004 above it).
const SURFACE := Home.MAHJONG_TOP + 0.0045
## Walls (17 stacks, half length 8.5 TW = 0.649) far enough out that the corners clear each other
## (WALL_R - TL / 2 > 0.649) and just outside the player's discards (outer edge 0.655); hands
## and sets lie just outside them, inside the felt (0.92). Until 15 Nov 2026: 0.745, 0.85, 0.86.
const WALL_R := 0.711
const HAND_R := 0.85
const MELD_R := 0.832
## Awoo's exposed sets across the table were hidden behind his wall (user, 9 Nov 2026: "fix the
## hidden sets of awoo by perhaps moving all the walls closer to the player"; then "I do not
## want awoo's shown tile to be vertical"). His sets lie flat like everyone's; his wall stands
## ACROSS_WALL_R out instead of WALL_R, 3 mm clear of his discard pile, so from the player's
## camera about 83 % of each set tile shows above it (the near edge stays hidden; at 0.745 none
## showed). The side walls sit WALL_TOWARD_PLAYER nearer seat 0 so their far ends clear his
## wall's corners (0.13 is the most before their near ends meet the player's hand at 0.82). The
## player's own wall stays: the hand stands right behind it.
## Since 15 Nov 2026 (bigger face-up tiles): his wall 0.541, 3 mm clear of his pile (outer
## edge 0.485), about 87 % of each set tile showing; the side walls 0.12 nearer seat 0.
const ACROSS_WALL_R := 0.541
const WALL_TOWARD_PLAYER := Vector3(0.0, 0.0, 0.12)
## The seat across the table from the player (seat 0).
const ACROSS := 2
## Discards: a square of four piles, each centred on its seat (user, 9 Nov 2026: "more left
## right centered"; until then eight to a row, shifted 0.1 to the seat's left as a pinwheel).
## Six to a row (half a row 0.248) start DISCARD_R out, so neighbouring piles just clear each
## other's corners. The whole square sits DISCARD_TOWARD_PLAYER closer to seat 0 (user, same
## day: "slightly closer to me but still somewhat centred"; 0.08, then 0.085 to clear Awoo's
## nearer wall); seat 0's third row ends 0.682 out, inside its wall (0.69), and Awoo's 0.512,
## inside his (0.515). Three rows hold 18 tiles; later discards lie on top of the first rows
## instead of reaching the wall. Since 15 Nov 2026 the tiles are face-up size (UW x UL), so
## only two rows fit: twelve tiles, then later discards lie on top of the first rows; the
## piles start 0.30 out (half a row 0.298). Superseded the next day by the pinwheel below.
## Since 16 Nov 2026 (user: bigger discards to read on a phone, the camera pulled back to show
## Awoo's face): the discards have their own size, DISCARD_GROW times the face-up size, and the
## pile layout follows from it. The outer edge stays where it was (0.56-0.576 out), against
## the walls; the inner gap is only what the rows need. DISCARD_PINWHEEL slides every pile
## half its depth to its owner's left, so the four piles lock together around the counter
## like a windmill and six-tile rows still fit at the larger size; off, the piles are centred.
## The user chose the pinwheel at 1.3 (16 Nov 2026) over centred rows of five at 1.1, knowing it
## brings back the off-centre piles of 9 Nov: inner gap 0.212 (the counter, 0.39 x 0.21, fits),
## outer edge 0.561, each pile 0.175 to its owner's left.
const DISCARD_ROW := 6
const DISCARD_ROWS := 2
const DISCARD_GROW := 1.3
const DISCARD_PINWHEEL := true
const DISCARD_SIZE := UP_SCALE * DISCARD_GROW
const DW := TW * DISCARD_SIZE
const DL := TL * DISCARD_SIZE
const DT := TT * DISCARD_SIZE
const DISCARD_GAP := 0.003
const ROW_STEP := DL + 0.006
const DISCARD_LENGTH := DISCARD_ROW * (DW + DISCARD_GAP) - DISCARD_GAP
const DISCARD_DEPTH := DL + (DISCARD_ROWS - 1) * ROW_STEP
const DISCARD_SHIFT := DISCARD_DEPTH * 0.5 if DISCARD_PINWHEEL else 0.0
const DISCARD_R := (DISCARD_LENGTH - 2.0 * DISCARD_SHIFT) * 0.5 + 0.003
const DISCARD_TOWARD_PLAYER := Vector3(0.0, 0.0, 0.085)
const HALF_ROW := 0.78
const FACE_PX := Vector2(96, 128)
## Table tiles in stronger colour and contrast than the panel's (user, 9 Nov 2026: easier to
## see), and never glaring (user, same day: "too bright to see clearly" in the midday sun):
## - the atlas is painted through FACE_PUNCH: more saturation, and darker strokes while the
##   ivory stays ivory;
## - every tile surface is capped at TILE_BRIGHTNESS of its colour, so the noon sun and the ACES
##   tone mapping no longer bleach the faces to white and the symbols to pastel;
## - part of each face glows only as the daylight fades (set_daylight(): none in full sun, up
##   to FACE_GLOW at night), so shade and dusk dim it less;
## - the backs are a brighter green than the felt.
const FACE_GLOW := 0.3
const TILE_BRIGHTNESS := 0.75
const BACK_3D := Color("2f9d68")
const FACE_PUNCH := """shader_type canvas_item;
void fragment() {
	vec3 c = COLOR.rgb;
	float grey = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(grey), c, 1.4);
	c = pow(clamp(c, 0.0, 1.0), vec3(1.35));
	COLOR.rgb = clamp(c, 0.0, 1.0);
}
"""
## The tile body is a little smaller than its spacing, so neighbours in a row stand apart with a
## thin shadowed seam instead of reading as one long bar (user, 9 Nov 2026).
## Gaps 30 % smaller than first built (user, 9 Nov 2026): 4.9 % of the width, 2.8 % of the length.
const BODY_W := TW * 0.951
const BODY_L := TL * 0.972

var _tiles: Array[Node3D] = []
## Each tile's face kind (-1: no face shown, the tile lies or stands face down).
var _faces: Array[int] = []
## The three MultiMeshes drawing every tile (17 Nov 2026, render cost on phones: ~350 separate
## surfaces were the largest unbatched group in the home's views; docs/guides/performance/README.md
## "Indoor batching"): ivory bodies, green backs and faces (atlas cell in INSTANCE_CUSTOM.xy).
## Instance i follows _tiles[i]; a hidden tile or face is scaled to nothing. _sync() copies the
## poses after a layout and on every frame while tiles slide.
var _bodies: MultiMesh
var _backs: MultiMesh
var _face_batch: MultiMesh
var _face_material: ShaderMaterial
var _dirty := false
const FACE_SHADER := """shader_type spatial;
// The tile faces of mahjong_view.gd: as its per-kind StandardMaterial3D (albedo and emission from
// the atlas, emission colour white, roughness 0.7), the atlas cell from INSTANCE_CUSTOM.xy.
uniform sampler2D atlas : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform float glow = 0.0;
void vertex() {
	UV = UV * vec2(1.0 / 9.0, 0.25) + INSTANCE_CUSTOM.xy;
}
void fragment() {
	vec3 c = texture(atlas, UV).rgb;
	ALBEDO = tint.rgb * c;
	ROUGHNESS = 0.7;
	EMISSION = (vec3(1.0) + c) * glow;
}
"""
const BODY_Y := TT * 0.38 + TT * 0.31
const BACK_Y := TT * 0.19
const FACE_Y := TT + 0.0006
var _materials: Array[StandardMaterial3D] = []
var _atlas: SubViewport
var _marker: MeshInstance3D
var _painter: Control

## Builds the atlas, the materials and the tile pool. `letters`: the wind letters in the
## language being learned.
func build(letters: Array) -> void:
	name = "MahjongTiles"
	# Never merged into Main's frozen static batches (render_culling.gd), whenever this is built:
	# in the app's staged loading the town's trim runs frames after the minigames are set up, so
	# the session's deferred preset was copied there and the table kept showing it (user, 15 Nov
	# 2026: "my hand stays the same on the mahjong table").
	set_meta("keep_own_draw", true)
	_atlas = SubViewport.new()
	_atlas.name = "TileAtlas"
	_atlas.size = Vector2i(int(FACE_PX.x) * 9, int(FACE_PX.y) * 4)
	_atlas.transparent_bg = false
	_atlas.render_target_update_mode = SubViewport.UPDATE_ONCE
	_painter = FacePainter.new()
	_painter.letters = letters
	var punch := ShaderMaterial.new()
	punch.shader = Shader.new()
	punch.shader.code = FACE_PUNCH
	_painter.material = punch
	_painter.size = Vector2(_atlas.size)
	_atlas.add_child(_painter)
	add_child(_atlas)
	var texture := _atlas.get_texture()
	for kind in Rules.KINDS:
		var material := StandardMaterial3D.new()
		material.albedo_texture = texture
		material.uv1_scale = Vector3(1.0 / 9.0, 0.25, 1)
		material.uv1_offset = Vector3(float(kind % 9) / 9.0, float(kind / 9) * 0.25, 0)
		material.albedo_color = Color(TILE_BRIGHTNESS, TILE_BRIGHTNESS, TILE_BRIGHTNESS)
		material.roughness = 0.7
		material.emission_enabled = true
		material.emission_texture = texture
		material.emission = Color.WHITE
		material.emission_energy_multiplier = 0.0   # set_daylight()
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		_materials.append(material)
	var ivory := StandardMaterial3D.new()
	ivory.albedo_color = Tiles.IVORY.darkened(0.06) * TILE_BRIGHTNESS   # the sides a shade darker
	ivory.albedo_color.a = 1.0
	ivory.roughness = 0.4
	var back := StandardMaterial3D.new()
	back.albedo_color = BACK_3D * TILE_BRIGHTNESS
	back.albedo_color.a = 1.0
	back.roughness = 0.5
	var ivory_mesh := BoxMesh.new()
	ivory_mesh.size = Vector3(BODY_W, TT * 0.62, BODY_L)
	var back_mesh := BoxMesh.new()
	back_mesh.size = Vector3(BODY_W, TT * 0.38, BODY_L)
	# The face covers the whole top; its atlas cell has a darker rim (FacePainter), so each tile
	# shows its own edge from above.
	var face_mesh := PlaneMesh.new()
	face_mesh.size = Vector2(BODY_W, BODY_L)
	_face_material = ShaderMaterial.new()
	_face_material.shader = Shader.new()
	_face_material.shader.code = FACE_SHADER
	_face_material.set_shader_parameter("atlas", texture)
	_face_material.set_shader_parameter("tint", Color(TILE_BRIGHTNESS, TILE_BRIGHTNESS, TILE_BRIGHTNESS))
	_bodies = _tile_batch("BatchedBodies", ivory_mesh, ivory, true)
	_backs = _tile_batch("BatchedBacks", back_mesh, back, true)
	_face_batch = _tile_batch("BatchedFaces", face_mesh, _face_material, false)
	for i in 136:
		var tile := Node3D.new()
		tile.name = "Tile%d" % i
		tile.visible = false
		add_child(tile)
		_tiles.append(tile)
		_faces.append(-1)
	_marker = MeshInstance3D.new()
	_marker.name = "LastDiscard"
	var ring := BoxMesh.new()
	ring.size = Vector3(DW + 0.02, 0.002, DL + 0.02)
	_marker.mesh = ring
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color("ffd24a")
	gold.emission_enabled = true
	gold.emission = Color("ffb300")
	gold.emission_energy_multiplier = 0.6
	_marker.material_override = gold
	_marker.visible = false
	add_child(_marker)

func _tile_batch(title: String, mesh: Mesh, material: Material, shadow: bool) -> MultiMesh:
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_custom_data = mesh is PlaneMesh
	batch.mesh = mesh
	batch.instance_count = 136
	for i in 136:
		batch.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))
	var draw := MultiMeshInstance3D.new()
	draw.name = title
	draw.multimesh = batch
	draw.material_override = material
	draw.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(draw)
	return batch

## Copies every tile's pose into the three MultiMeshes (hidden tiles and faces: scaled to nothing).
func _sync() -> void:
	_dirty = false
	var none := Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO)
	for i in _tiles.size():
		var tile := _tiles[i]
		var shown := tile.visible
		var pose := tile.transform
		_bodies.set_instance_transform(i, pose.translated_local(Vector3(0, BODY_Y, 0)) if shown else none)
		_backs.set_instance_transform(i, pose.translated_local(Vector3(0, BACK_Y, 0)) if shown else none)
		var kind := _faces[i]
		_face_batch.set_instance_transform(i, pose.translated_local(Vector3(0, FACE_Y, 0)) if shown and kind >= 0 else none)
		if kind >= 0:
			_face_batch.set_instance_custom_data(i, Color(float(kind % 9) / 9.0, float(kind / 9) * 0.25, 0, 0))
	set_process(not _slides.is_empty())

func _mark() -> void:
	_dirty = true
	set_process(true)

func _process(_delta: float) -> void:
	if _dirty or not _slides.is_empty():
		_sync()
	else:
		set_process(false)

# --- The table-centre counter (user, 10 Nov 2026) ------------------------------------------

## A low dark console in the empty square between the discards, as on an automatic table: the
## round wind as a real tile lying face up, and the tiles left in the wall beside it (cream
## numerals, a small word under them), tilted a little toward the player's seat.
const COUNTER_SIZE := Vector3(0.3, 0.012, 0.16)
const COUNTER_TILT := 0.35   # radians up from flat, toward the player (+Z)
## The whole counter (console, wind tile, number and word) drawn 30 % larger (user, 16 Nov 2026).
const COUNTER_GROWTH := 1.3
var _counter: Node3D
var _counter_tile: MeshInstance3D
var _counter_number: Label3D
var _counter_word: Label3D

## Shows the counter: `left` tiles in the wall, the round wind `wind_kind`, `word` under the number.
func show_counter(left: int, wind_kind: int, word: String) -> void:
	if _counter == null:
		_build_counter()
	_counter.visible = true
	_counter_tile.material_override = _materials[wind_kind]
	_counter_number.text = str(left)
	_counter_word.text = word

func hide_counter() -> void:
	if _counter != null:
		_counter.visible = false

func _build_counter() -> void:
	_counter = Node3D.new()
	_counter.name = "CentreCounter"
	_counter.position = Vector3(0.0, SURFACE, 0.0)
	_counter.scale = Vector3.ONE * COUNTER_GROWTH
	add_child(_counter)
	var console := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = COUNTER_SIZE
	console.mesh = box
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color("142a38")
	dark.roughness = 0.35
	console.material_override = dark
	console.position.y = COUNTER_SIZE.y * 0.5
	_counter.add_child(console)
	var top := COUNTER_SIZE.y + 0.0006
	# The round wind: a tile's face lying on the console, its top toward the far side.
	_counter_tile = MeshInstance3D.new()
	var face := PlaneMesh.new()
	face.size = Vector2(BODY_W, BODY_L)
	_counter_tile.mesh = face
	_counter_tile.position = Vector3(-COUNTER_SIZE.x * 0.27, top, 0.0)
	_counter_tile.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_counter.add_child(_counter_tile)
	# The number and its word, tilted up toward the player so they read at the seated view.
	var reading := Node3D.new()
	reading.position = Vector3(COUNTER_SIZE.x * 0.16, top + 0.022, 0.02)   # lifted: the tilted word stays above the console
	reading.rotation.x = -PI * 0.5 + COUNTER_TILT
	_counter.add_child(reading)
	_counter_number = _counter_label(64, Vector3(0, 0.014, 0.002))
	reading.add_child(_counter_number)
	_counter_word = _counter_label(26, Vector3(0, -0.04, 0.002))
	reading.add_child(_counter_word)

func _counter_label(px: int, at: Vector3) -> Label3D:
	var label := Label3D.new()
	label.font_size = px
	label.pixel_size = 0.0013
	label.outline_size = 0
	label.modulate = Color("fff1c5")
	label.position = at
	label.double_sided = false
	return label

## How much daylight falls on the table, 0 (night) to 1 (full sun): the faces glow by the rest.
func set_daylight(level: float) -> void:
	var glow := FACE_GLOW * (1.0 - clampf(level, 0.0, 1.0))
	if _materials.is_empty() or is_equal_approx(_materials[0].emission_energy_multiplier, glow):
		return
	for material in _materials:
		material.emission_energy_multiplier = glow
	_face_material.set_shader_parameter("glow", glow)

## Repaints the faces with new wind letters (the language may have changed since the build).
func repaint(letters: Array) -> void:
	if _painter.letters == letters:
		return
	_painter.letters = letters
	_painter.queue_redraw()
	_atlas.render_target_update_mode = SubViewport.UPDATE_ONCE

class FacePainter extends Control:
	var letters: Array = []
	func _draw() -> void:
		var cell := Vector2(96, 128)
		draw_rect(Rect2(Vector2.ZERO, size), Tiles.EDGE)
		for kind in 34:
			var rect := Rect2(Vector2(kind % 9, kind / 9) * cell, cell)
			Tiles.draw_face(self, rect.grow(-4), kind, letters)

# --- Layout --------------------------------------------------------------------------------

static func outward(seat: int) -> Vector3:
	return Home.MAHJONG_SEATS[seat]

## The seat's right hand as it faces the table.
static func right_of(seat: int) -> Vector3:
	return (-outward(seat)).cross(Vector3.UP)

## How long a tile takes to slide to its new place, and the short wait before the rest of a
## hand closes up behind a discard (user, 9 Nov 2026: moves between turns read as real play;
## then 60 % faster, 1/1.6 of 0.28 / 0.12 / 0.35 s).
const SLIDE_SECONDS := 0.175
const CLOSE_UP_DELAY := 0.075
## The gap before the tile an NPC has just drawn, at the right end of its hand.
const DRAWN_GAP := 0.03
const DRAW_DELAY := 0.22

## What each pool tile shows now: {"key", "kind", "place"} ({} while unused).
var _info: Array = []
var _slides: Dictionary = {}

## Places every tile from `game`. `reveal` lays every hand face up (the result). Seat 0's hand
## stands on the table like the others, also while the player sits there: the game camera
## leaves it under the hand bar (user, 9 Nov 2026; since 15 Nov 2026 hidden entirely). Unless `instant`, every tile keeps its
## identity between calls and slides to its new place: a drawn tile from the wall into the
## hand (set apart at the right end until its owner discards), a discard from its place in the
## hand to the pile, a claimed tile from the pile into the meld; the rest of a hand closes up
## just after. A new deal or the preset is `instant`.
func layout(game, reveal: bool = false, instant: bool = false) -> void:
	var targets: Array = []
	# Walls: wall order k -> stack k / 2 (top layer first), 17 stacks a side, clockwise from the
	# dealer's side.
	for k in 136:
		if k < game.drawn_front or k >= 136 - game.drawn_back:
			continue
		var stack := k / 2
		var side_seat: int = (game.dealer - stack / 17 + 4) % 4
		var along := (8.0 - float(stack % 17)) * TW
		var o := outward(side_seat)
		var r := right_of(side_seat)
		var radius := ACROSS_WALL_R if side_seat == ACROSS else WALL_R
		var at := o * radius + r * along + Vector3.UP * (SURFACE + (TT if k % 2 == 0 else 0.0))
		if side_seat != 0 and side_seat != ACROSS:
			at += WALL_TOWARD_PLAYER
		targets.append(_target("w%d" % k, "wall", -1, -1, at, Basis(-r, Vector3.DOWN, o)))
	_marker.visible = false
	for seat in 4:
		var o := outward(seat)
		var r := right_of(seat)
		# Concealed hand, sorted, kept to the seat's right (user, 9 Nov 2026: exposed sets on the
		# left). The right end is a fixed place for the tile just drawn, set apart by a gap, so
		# drawing and discarding never shift the whole row; the rest ends just before that gap.
		var hand: Array = game.hands[seat].duplicate()
		var drawn := -1
		if seat == game.turn and game.phase == "turn" and game.drawn >= 0 and hand.has(game.drawn) and not reveal:
			hand.erase(game.drawn)
			drawn = game.drawn
		var row_end := HALF_ROW - TW - DRAWN_GAP
		if drawn >= 0:
			hand.append(drawn)
		var rest := hand.size() - (1 if drawn >= 0 else 0)
		for i in hand.size():
			var x := row_end - (rest - i - 0.5) * TW
			if drawn >= 0 and i == hand.size() - 1:
				x = HALF_ROW - TW * 0.5
			var at := o * HAND_R + r * x + Vector3.UP * SURFACE
			var target: Dictionary
			if reveal:
				target = _target("h%d" % seat, "hand", hand[i], hand[i], at, Basis(r, Vector3.UP, o))
			else:
				target = _target("h%d" % seat, "hand", hand[i], hand[i], at + Vector3.UP * (TL * 0.5), Basis(r, o, Vector3.DOWN))
			targets.append(target)
		# Exposed melds, face up from the seat's left, the first set at the far left.
		var x := -HALF_ROW
		for j in game.melds[seat].size():
			var meld: Dictionary = game.melds[seat][j]
			var tiles := Rules.meld_tiles(meld)
			for t in tiles.size():
				var down: bool = not bool(meld.get("open", true)) and (t == 0 or t == tiles.size() - 1)
				var at := o * MELD_R + r * (x + UW * 0.5) + Vector3.UP * SURFACE
				targets.append(_target("m%d_%d_%d" % [seat, j, t], "meld", tiles[t], -1 if down else tiles[t], at, Basis(-r, Vector3.DOWN, o) if down else Basis(r, Vector3.UP, o), UP_SCALE))
				x += UW
			x += 0.02
		# Discards, rows of six centred in front of the seat.
		var pile: Array = game.discards[seat]
		for i in pile.size():
			var row := i / DISCARD_ROW
			var col := i % DISCARD_ROW
			var layer := row / DISCARD_ROWS
			row %= DISCARD_ROWS
			var at := DISCARD_TOWARD_PLAYER + o * (DISCARD_R + DL * 0.5 + row * ROW_STEP) + r * ((col - (DISCARD_ROW - 1) * 0.5) * (DW + DISCARD_GAP) - DISCARD_SHIFT) + Vector3.UP * (SURFACE + layer * DT)
			targets.append(_target("d%d_%d" % [seat, i], "discard", pile[i], pile[i], at, Basis(r, Vector3.UP, o), DISCARD_SIZE))
			if seat == game.last_from and i == pile.size() - 1 and game.phase == "claim":
				_marker.visible = true
				_marker.position = at + Vector3.UP * 0.0005
				_marker.basis = Basis(r, Vector3.UP, o)
	_assign(targets, instant or _info.is_empty())

## `size`: 1 for a face-down-size tile, UP_SCALE for a face-up one (the pool's meshes are
## face-down size; the node is scaled).
func _target(key: String, place: String, kind: int, face: int, at: Vector3, basis: Basis, size: float = 1.0) -> Dictionary:
	if basis.y.y < -0.5:
		at += Vector3.UP * TT * size   # face down: the tile hangs below its origin
	return {"key": key, "place": place, "kind": kind, "face": face, "transform": Transform3D(basis.scaled_local(Vector3.ONE * size), at), "hidden": false}

## Gives every target a pool tile: the same tile as before where it can (same place in the
## wall, pile or meld; the same kind in the same hand), then a tile that left its place (a
## discard or claimed tile of that kind, a tile drawn from the wall), then any free one.
func _assign(targets: Array, instant: bool) -> void:
	if _info.size() != _tiles.size():
		_info.resize(_tiles.size())
		_info.fill({})
	var chosen: Array = []
	chosen.resize(targets.size())
	chosen.fill(-1)
	var taken := {}
	if not instant:
		var by_key := {}
		var by_hand := {}
		for index in _info.size():
			var was: Dictionary = _info[index]
			if was.is_empty():
				continue
			if str(was.place) == "hand":
				var hand_key := "%s/%d" % [was.key, int(was.kind)]
				if not by_hand.has(hand_key):
					by_hand[hand_key] = []
				by_hand[hand_key].append(index)
			else:
				by_key[str(was.key)] = index
		for i in targets.size():   # same place in the wall, a pile or a meld
			var t: Dictionary = targets[i]
			if str(t.place) == "hand":
				continue
			var index: int = by_key.get(str(t.key), -1)
			if index >= 0 and int(_info[index].kind) == int(t.kind):
				chosen[i] = index
				taken[index] = true
		for i in targets.size():   # the same kind in the same hand
			var t: Dictionary = targets[i]
			if str(t.place) != "hand":
				continue
			for index in by_hand.get("%s/%d" % [t.key, int(t.kind)], []):
				if not taken.has(index):
					chosen[i] = index
					taken[index] = true
					break
		# Tiles that left their place: by kind, and the wall tiles just drawn.
		var loose := {}
		var from_wall: Array = []
		for index in _info.size():
			var was: Dictionary = _info[index]
			if was.is_empty() or taken.has(index):
				continue
			if str(was.place) == "wall":
				from_wall.append(index)
			else:
				if not loose.has(int(was.kind)):
					loose[int(was.kind)] = []
				loose[int(was.kind)].append(index)
		for i in targets.size():
			if chosen[i] >= 0:
				continue
			var t: Dictionary = targets[i]
			var same: Array = loose.get(int(t.kind), [])
			if str(t.place) == "hand" and not from_wall.is_empty():
				chosen[i] = from_wall.pop_back()   # a drawn tile comes from the wall
			elif not same.is_empty():
				chosen[i] = same.pop_front()       # a discard or a claimed tile
			if chosen[i] >= 0:
				taken[chosen[i]] = true
	var free: Array = []
	for index in _tiles.size():
		if not taken.has(index):
			free.append(index)
	var next_info: Array = []
	next_info.resize(_tiles.size())
	next_info.fill({})
	if targets.size() > _tiles.size():   # only an inconsistent game state has more than 136
		push_error("Mahjong view: %d tiles to place, the pool has %d" % [targets.size(), _tiles.size()])
		targets = targets.slice(0, _tiles.size())
	for i in targets.size():
		if chosen[i] < 0:
			chosen[i] = free.pop_front()
			taken[chosen[i]] = true
		var index: int = chosen[i]
		var t: Dictionary = targets[i]
		var was: Dictionary = _info[index]
		var moved: bool = not was.is_empty() and str(was.key) != str(t.key)
		_show(index, t, instant or was.is_empty(), moved, not was.is_empty() and str(was.place) == "wall")
		next_info[index] = {"key": t.key, "place": t.place, "kind": t.kind}
	for index in _tiles.size():
		if next_info[index].is_empty():
			_stop_slide(index)
			_tiles[index].visible = false
	_info = next_info
	_mark()

## Puts tile `index` at its target: at once (`snap`), or sliding there. A tile changing place
## (discarded, claimed) goes first; tiles only shifting along their row follow after
## CLOSE_UP_DELAY; a tile drawn from the wall waits until a discard has landed (DRAW_DELAY), so
## one turn reads as discard, then the next player's draw.
func _show(index: int, t: Dictionary, snap: bool, moved: bool, drawn: bool = false) -> void:
	var tile := _tiles[index]
	var kind := int(t.face)
	_faces[index] = kind
	var hidden: bool = bool(t.hidden)
	var goal: Transform3D = t.transform
	if snap or not tile.visible and hidden:
		_stop_slide(index)
		tile.transform = goal
		tile.visible = not hidden
		return
	if _slides.has(index):
		if Transform3D(_slides[index].goal).is_equal_approx(goal):
			_slides[index].hidden = hidden   # already on its way there
			return
	elif tile.transform.is_equal_approx(goal):
		tile.visible = not hidden
		return
	_stop_slide(index)
	tile.visible = true
	var slide := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if drawn:
		slide.tween_interval(DRAW_DELAY)
	elif not moved:
		slide.tween_interval(CLOSE_UP_DELAY)
	slide.tween_property(tile, "transform", goal, SLIDE_SECONDS)
	slide.tween_callback(func() -> void: _end_slide(index))
	_slides[index] = {"tween": slide, "goal": goal, "hidden": hidden}

func _end_slide(index: int) -> void:
	if _slides.has(index):
		_tiles[index].visible = not bool(_slides[index].hidden)
		_slides.erase(index)
		_mark()

func _stop_slide(index: int) -> void:
	if _slides.has(index):
		var slide: Tween = _slides[index].tween
		if slide.is_valid():
			slide.kill()
		_slides.erase(index)

## Every sliding tile jumps to its place now (checks that step the game without frames).
func finish_slides() -> void:
	for index in _slides.keys():
		var slide: Dictionary = _slides[index]
		if (slide.tween as Tween).is_valid():
			slide.tween.kill()
		_tiles[index].transform = slide.goal
		_end_slide(index)
	_mark()
