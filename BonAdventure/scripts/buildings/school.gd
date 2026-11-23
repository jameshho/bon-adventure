extends RefCounted
## School own script (docs/guides/MODULAR_TOWN.md, "Changing a building"): code steps for the school
## unit (scenes/town/school.scn) and the classroom constants the Grammar Classroom uses
## (scripts/learning/grammar_session.gd; guide docs/guides/GRAMMAR_CLASS.md).
## Bake:  godot --headless --path . --script res://tools/bake_unit.gd -- school
## Never rename or remove a baked step (add a new one that undoes it).
##
## Coordinates are school-local (Buildings/School: no rotation or scale; town units, Apartment
## scale 1.3 applies). The shell runs x -12..12, front wall z -12.2 (entrance at x 0), rear
## wall z 5.675 (inner face about 5.55); the divider stands at x 0 from z -3.2 to the rear wall.
## The general classroom is the x < 0 half.
const STEPS := ["grammar_classroom", "coplanar_gaps", "coplanar_gaps_2", "glass_windows", "bigger_board", "science_room"]

## Lana, the sheep teacher, under Buildings/School.
const LANA := "TeacherLana"
const LANA_SPOT := Vector3(-2.6, 0, 4.25)
## The answer desks, front row first (A B, then C D); meta grammar_desk / grammar_seat.
const ANSWER_DESKS := ["A", "B", "C", "D"]
## Desk columns and rows (desk centres); the chair stands CHAIR_OFFSET toward -z and is turned
## round (the room used to face the front wall), so seated players face +z, the board.
const COLUMNS := [-8.6, -3.4]
const ROWS := [2.4, -0.4, -3.2]
const CHAIR_OFFSET := -0.95
## The board on the rear wall: centre and size (its word is "whiteboard"). 6 Nov 2026: 4.8 × 2.0
## at x -6.8; since step bigger_board (14 Nov 2026) 6.0 × 2.6 at x -6.5 (x -9.5..-3.5, y 0.8..3.4),
## where the months poster hung beside it. The "GENERAL CLASSROOM" sign above it moves up to
## SIGN_Y. Read the board's size from its grammar_board meta, not from these constants.
const BOARD := Vector3(-6.5, 2.1, 5.5)
const BOARD_SIZE := Vector3(6.0, 2.6, 0.05)
const BOARD_COLOR := Color("fbfcf8")
const BOARD_FRAME := Color("5f6f7a")
const SIGN_Y := 3.98
## The months poster ("Los meses", a word object of the hospital family game) leaves the rear wall
## for the left side wall's front end, above the piano, facing the room (+x): bigger_board.
const MONTHS_POSTER := "Classroom poster months"
const MONTHS_SPOT := Vector3(-11.68, 2.6, -9.6)
const MONTHS_TURN := -PI / 2
## The two rear-wall posters the board replaces move to the front wall's left half (free since
## the old whiteboard went), above the supplies table, facing the room.
const MOVED_POSTERS := {"Classroom poster older younger": Vector3(-9.4, 2.7, -11.89), "Classroom poster before after": Vector3(-6.4, 2.7, -11.89)}
## Where a class starts and where the player is walked back to after each answer: the aisle
## between desks C and D, facing the board (moved from z -2.0, behind the answer desks, closer to
## the board; user, 8 Nov 2026). Runtime only: nothing baked uses it.
const START := Vector3(-6.0, 0, -0.4)
const START_LOOK := Vector3(0, 0, 1)
## The entrance: the class's exit trigger just outside the door line, and the spot just inside
## where "No, I'll stay" puts the player.
const DOOR_Z := -12.2
const DOORWAY := Vector3(0, 1.4, -12.95)
const DOORWAY_SIZE := Vector3(4.6, 2.8, 1.3)
const INSIDE := Vector3(0, 0, -10.4)
const INSIDE_LOOK := Vector3(0, 0, 1)
## The music corner moves from the rear wall (pivot MUSIC_FROM) to the left side wall
## (MUSIC_TO), turned a quarter (its front faces the room, +x), keeping its distance from the
## wall; it runs z -8.8..-0.2, clear of the front walkway at z -9.4 and 1.4 from the desks.
const MUSIC_FROM := Vector3(-6.5, 0, 4.7)
const MUSIC_TO := Vector3(-10.9, 0, -4.4)
const MUSIC_TURN := -PI / 2

## The Grammar Classroom remodel (user brief and decisions, 6 Nov 2026): board on the rear
## wall, 6 desks in 2 columns × 3 rows (the front four are the answer desks), the music corner
## to the front-left, Lana by the board. Every word stays learnable.
func grammar_classroom(town: Node3D, game) -> void:
	var school: Node3D = town.get_node("Buildings/School")
	var objects: Node3D = school.get_node("RetainedLearningObjects")
	# 1. Music corner: everything on the rear wall of the classroom half moves as one group.
	var turn := Basis(Vector3.UP, MUSIC_TURN)
	for node in objects.get_children():
		if node is Node3D and node.position.x < 0 and node.position.z > 4.0:
			node.position = MUSIC_TO + turn * (node.position - MUSIC_FROM)
			node.rotation.y += MUSIC_TURN
	# 2. Desks: 8 sets in 4 rows become 6 in 3 rows; the front-most old row is removed.
	var rows := {}
	for node in objects.get_children():
		if not node is Node3D:
			continue
		var key := str(node.get_meta("word_key", ""))
		if key in ["desk", "notebook"] and node.position.x < 0 and node.position.z > -6.0 and node.position.z < 3.0:
			var row: float = snappedf(node.position.z, 0.1)
			rows[row] = rows.get(row, []) + [node]
		elif key == "chair" and node.position.x < 0 and node.position.z > -7.0 and node.position.z < 2.0:
			var row: float = snappedf(node.position.z - CHAIR_OFFSET, 0.1)
			rows[row] = rows.get(row, []) + [node]
	var old_rows: Array = rows.keys()
	old_rows.sort()
	assert(old_rows.size() == 4, "school: expected 4 desk rows, found %s" % [old_rows])
	for node in rows[old_rows[0]]:
		node.free()
	# Old rows -2.8, -0.4, 2.0 -> new rows -3.2, -0.4 (C D), 2.4 (A B).
	var new_rows: Array = [ROWS[2], ROWS[1], ROWS[0]]
	for i in 3:
		for node in rows[old_rows[i + 1]]:
			var column: float = COLUMNS[0] if node.position.x < -7.0 else COLUMNS[1]
			var key := str(node.get_meta("word_key", ""))
			var z: float = new_rows[i] + (CHAIR_OFFSET if key == "chair" else 0.0)
			node.position = Vector3(column, node.position.y, z)
			if key == "chair":
				node.rotation.y += PI
			if i == 0:
				continue
			# Answer desks: A B in front, C D behind; left column first.
			var letter: String = ANSWER_DESKS[(0 if i == 2 else 2) + (0 if column == COLUMNS[0] else 1)]
			match key:
				"desk":
					node.set_meta("grammar_desk", letter)
				"chair":
					node.set_meta("grammar_seat", letter)
				"notebook":
					# The answer is written on the desk top; two notebooks stay on the back row.
					node.free()
	# 3. The board: the tiny whiteboard on the front wall gives way to a large one on the rear.
	# The new board keeps the node name "Whiteboard" (checks and saves find it by path).
	var old_board: Node3D = objects.get_node_or_null("Whiteboard")
	if old_board != null:
		old_board.free()
	_board(game, objects, Vector3(-6.8, 2.1, 5.5), Vector3(4.8, 2.0, 0.05), Color("f7f8f4"), Color("8a9aa5"))
	for title in MOVED_POSTERS:
		var poster: Node3D = school.get_node(title)
		poster.position = MOVED_POSTERS[title]
		poster.rotation.y = PI
	# 4. Lana, the teacher, by the board's right end, facing the class.
	var characters = preload("res://scripts/characters/house_characters.gd").new()
	characters.worker("res://scenes/characters/sheep_plush.tscn", "teacher", "teacher", school, LANA, school.to_global(LANA_SPOT), school.global_basis * Vector3(0, 0, -1))

## The class board (word whiteboard, node "Whiteboard", meta grammar_board = its size) with a
## frame and a marker tray, under `objects`.
func _board(game, objects: Node3D, centre: Vector3, size: Vector3, color: Color, frame: Color) -> Node3D:
	var board: Node3D = _part(game, objects, "Whiteboard", centre, size, color, "whiteboard")
	board.set_meta("learning_object", true)
	board.set_meta("grammar_board", size)
	var w: float = size.x
	var h: float = size.y
	for bar in [[Vector3(0, h * .5 + .04, 0), Vector3(w + .16, .08, .09)], [Vector3(0, -h * .5 - .04, 0), Vector3(w + .16, .08, .09)], [Vector3(-w * .5 - .04, 0, 0), Vector3(.08, h, .09)], [Vector3(w * .5 + .04, 0, 0), Vector3(.08, h, .09)], [Vector3(0, -h * .5 - .1, -.08), Vector3(w * .7, .05, .16)]]:
		_part(game, board, "Board frame", bar[0], bar[1], frame)
	return board

## A bigger, clearer board (14 Nov 2026, user): 6.0 × 2.6 (was 4.8 × 2.0), brighter with a
## darker frame; the months poster moves to the left side wall to make room; the classroom sign
## above the board moves up. The board is rebuilt under the same name with the old one's metas.
func bigger_board(town: Node3D, game) -> void:
	var school: Node3D = town.get_node("Buildings/School")
	var objects: Node3D = school.get_node("RetainedLearningObjects")
	var old_board: Node3D = objects.get_node("Whiteboard")
	var metas := {}
	for key in old_board.get_meta_list():
		metas[key] = old_board.get_meta(key)
	var index := old_board.get_index()
	old_board.free()
	var board := _board(game, objects, BOARD, BOARD_SIZE, BOARD_COLOR, BOARD_FRAME)
	for key in metas:
		if key != "grammar_board":
			board.set_meta(key, metas[key])
	objects.move_child(board, index)
	var months: Node3D = school.get_node(MONTHS_POSTER)
	months.position = MONTHS_SPOT
	months.rotation.y = MONTHS_TURN
	for node in school.get_node("ApprovedShell").get_children():
		if node is Label3D and node.text == "GENERAL CLASSROOM":
			node.position.y = SIGN_Y
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "school", 3)

## A plain box part (Main's box(): mesh, and a pick area when it has a word) under `parent`.
func _part(game, parent: Node3D, title: String, pos: Vector3, size: Vector3, color: Color, word := "") -> Node3D:
	var part: Node3D = game.box(title, Vector3.ZERO, size, color, word, false)
	part.reparent(parent, false)
	part.position = pos
	return part

## Faces that shared a plane and flickered are set apart (10 Nov 2026,
## scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "school")

## Second pass: faces a first move brought into a new plane, and labels widened for translated
## text (10 Nov 2026, scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps_2(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "school", 2)


## Window glass as the shared window component (12 Nov 2026, docs/guides/WINDOWS.md).
func glass_windows(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/glass_windows.gd").migrate(town, "school")

## The science room (the x > 0 half, on the left coming in) and a stray plaque (user, 23 Nov 2026:
## "improve the interior, especially the left side; remove the random triangles on the wall";
## docs/evidence/civic-fixes-20261123/):
## - the bare green triangle on the front wall (PaintedMountain_11, the only "mountain" in town)
##   becomes a framed mountain picture: sky, two peaks with snow, a green hill, a sun;
## - the large green blob by the east wall (Continent_9, the only "continent") becomes a framed
##   wall chart, a green continent on a blue sea, on the east wall;
## - the blank Biology and Geography plaques get their names (signs, translated at load);
## - two plaques with their labels (RelocatedSites/School: "Classroom plaque" / CLASSROOM and
##   "Main Hall plaque" / MAIN HALL, the only places of the words "classroom" and "main hall")
##   hung 0.7 off the front wall with their lettering toward the wall (blank from inside; the
##   first over the before-and-after poster, the second in the entrance). They now sit flat on
##   the front wall, lettering to the room: CLASSROOM above the general classroom's posters,
##   MAIN HALL above the entrance;
## - the empty notice board (word "notice") gets three pinned notes.
const PICTURE_FRAME := Color("ad7b50")
const PICTURE_SKY := Color("bfe0f5")
const PICTURE_SEA := Color("6f9eb3")
const PICTURE_LAND := Color("7d9f62")
const PICTURE_ROCK := Color("8a9a9c")
const PICTURE_SNOW := Color("fbfcf8")
const PICTURE_SUN := Color("f2c230")
const PLAQUE_TEXT := Color("1f5a5c")

func science_room(town: Node3D, game) -> void:
	var school: Node3D = town.get_node("Buildings/School")
	var objects: Node3D = school.get_node("RetainedLearningObjects")
	# The two plaques onto the front wall (school-local spots; the site has its own frame, so
	# they are placed through global transforms with the school's axes: lettering toward +z).
	var site: Node3D = town.get_node("RelocatedSites/School")
	var moved := 0
	for spec in [["Classroom plaque", "CLASSROOM upgrade sign", Vector3(-6.4, 4.0, -11.91)], ["Main Hall plaque", "MAIN HALL upgrade sign", Vector3(0.0, 4.0, -11.91)]]:
		var plaque := site.get_node(spec[0]) as Node3D
		var label := site.get_node(spec[1]) as Label3D
		plaque.global_transform = Transform3D(school.global_basis, school.to_global(spec[2]))
		label.global_transform = Transform3D(school.global_basis, school.to_global(spec[2] + Vector3(0, 0, .045)))
		moved += 1
	assert(moved == 2, "science_room: expected two plaques, moved %d" % moved)
	# Pinned notes on the notice board (its cork face is +z, 0.03 in front of its centre).
	var notice := objects.get_node("Notice") as Node3D
	for note in [[-.22, .08, .05, Color("f2c230")], [.08, .12, -.06, Color("bfe0f5")], [.24, -.12, .08, Color("f6c1c1")]]:
		var paper := _part(game, notice, "Pinned note", Vector3(note[0], note[1], .036), Vector3(.24, .28, .01), note[3])
		paper.rotation.z = note[2]
		for line in 3:
			_part(game, paper, "Note line", Vector3(0, .05 - line * .06, .006), Vector3(.16, .015, .004), Color("6f7b88"))
		_part(game, paper, "Note pin", Vector3(0, .11, .012), Vector3(.03, .03, .02), Color("d9534a"))
	# The mountain picture where the triangle was (front wall, facing +z).
	var triangle := objects.get_node("PaintedMountain_11") as Node3D
	var at := Vector3(triangle.position.x, 2.45, -11.92)
	triangle.free()
	var picture := _part(game, objects, "Mountain picture", at, Vector3(1.9, 1.3, .05), PICTURE_FRAME, "mountain")
	_part(game, picture, "Picture sky", Vector3(0, 0, .03), Vector3(1.74, 1.14, .02), PICTURE_SKY)
	_part(game, picture, "Picture hill", Vector3(0, -.42, .045), Vector3(1.74, .3, .02), PICTURE_LAND)
	for peak in [[-.3, .95, .8], [.38, .7, .62]]:
		var mountain := _prism(game, picture, "Picture peak", Vector3(peak[0], -.27 + peak[2] * .5, .05), Vector3(peak[1], peak[2], .02), PICTURE_ROCK)
		# The cap is the peak's top 0.2: as wide as the peak is at that height.
		_prism(game, mountain, "Picture snow", Vector3(0, peak[2] * .5 - .1, .005), Vector3(peak[1] * .2 / peak[2], .2, .02), PICTURE_SNOW)
	var sun: Node3D = game.cylinder("Picture sun", Vector3.ZERO, .11, .02, PICTURE_SUN)
	sun.reparent(picture, false)
	sun.position = Vector3(.62, .32, .045)
	sun.rotation.x = PI / 2
	# The continent chart on the east wall (facing -x: the root turns its local -z to -x).
	var blob := objects.get_node("Continent_9") as Node3D
	blob.free()
	var chart := Node3D.new()
	chart.name = "Continent chart"
	chart.position = Vector3(11.68, 2.3, -10.0)
	chart.rotation.y = PI / 2
	objects.add_child(chart)
	var board := _part(game, chart, "Continent chart board", Vector3.ZERO, Vector3(1.9, 1.3, .05), PICTURE_FRAME, "continent")
	_part(game, board, "Chart sea", Vector3(0, 0, -.03), Vector3(1.74, 1.14, .02), PICTURE_SEA)
	for land in [[-.2, .1, .3], [.12, .05, .26], [-.02, -.2, .22], [.3, .25, .14], [-.42, .22, .16], [.18, -.33, .12]]:
		var disc: Node3D = game.cylinder("Chart land", Vector3.ZERO, land[2], .02, PICTURE_LAND)
		disc.reparent(board, false)
		disc.position = Vector3(land[0], land[1], -.045)
		disc.rotation.x = PI / 2
	# Plaque names (English source text; sign_language.gd shows the language at load).
	_plaque_name(objects.get_node("Biology plaque"), "BIOLOGY", false)
	_plaque_name(objects.get_node("Geography plaque"), "GEOGRAPHY", true)
	print("science_room: plaques remounted, notes pinned, mountain picture, continent chart, plaque names")

## A triangular prism (Main has no prism helper): mesh only, under `parent`.
func _prism(game, parent: Node3D, title: String, pos: Vector3, size: Vector3, color: Color) -> Node3D:
	var mesh := MeshInstance3D.new()
	mesh.name = title
	var prism := PrismMesh.new()
	prism.size = size
	mesh.mesh = prism
	mesh.material_override = game.material_for(color)
	parent.add_child(mesh)
	mesh.position = pos
	return mesh

## Lettering on a 1.5 x 0.5 plaque's room face (+z, or -z when `back`).
func _plaque_name(plaque: Node3D, text: String, back: bool) -> void:
	var label := Label3D.new()
	label.name = text.capitalize() + " lettering"
	label.text = text
	label.font_size = 64
	label.pixel_size = .26 / 64.0
	label.outline_size = 0
	label.modulate = PLAQUE_TEXT
	label.position = Vector3(0, 0, -.045 if back else .045)
	if back:
		label.rotation.y = PI
	plaque.add_child(label)
