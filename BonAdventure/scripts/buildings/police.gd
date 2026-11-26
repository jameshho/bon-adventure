extends RefCounted
## Police station own script (docs/guides/MODULAR_TOWN.md, "Changing a building"); the station itself
## is saved in scenes/town/police.scn. Plan: 20 x 22 shell (enlarged 6 Nov 2026 for the two
## detective minigames, docs/evidence/police-detective-20261106/PROMPT.md), front fixed (facade z 37.5,
## door gap x 41.25..44.75). Inside walls x 33.12..52.88, z 37.62..59.38; walls 5.8 high,
## rooms 3 high. Rear row (z 52..59.38), left to right seen from the door: interview room,
## equipment/records alcove, holding cell, suspect lineup room; front left: evidence room.
##
## DESIGN COORDINATES: the constants below are written as if low x were the left seen from the
## door, but in the station's frame (RelocatedSites/Police children) low x is on the RIGHT, so
## a design point is placed with mirror_point() (mirrored about the door axis x = 43). The
## constants were moved here from the deleted startup pass police_interior.gd (6 Nov 2026);
## the checks in docs/police-*/ use them.
const STEPS := ["solid_roofs", "evidence_poster_words", "evidence_shelf_objects", "lobby_layout", "reception_officer_chairs",
	"interiors_polish",
	"coplanar_gaps", "coplanar_gaps_2", "glass_windows", "real_windows", "two_lockers", "door_sounds"]

const LEFT := 33.12
const RIGHT := 52.88
const FRONT := 37.62
const REAR := 59.38
## Rear rooms: front wall line, and the partitions between them.
const ROW := 52.0
const ROOM_HEIGHT := 3.0
const INTERVIEW_RIGHT := 38.6
const RECORDS_RIGHT := 41.6
const CELL_RIGHT := 45.8
## Lineup doorway in the lineup room's front wall.
const LINEUP_DOOR := Vector2(50.9, 52.5)
## Evidence room (front left): right wall with the counter hatch, rear wall with its doorway.
const EVIDENCE_RIGHT := 39.4
const EVIDENCE_REAR := 47.0
const HATCH := Vector2(42.0, 45.0)
const EVIDENCE_DOOR := Vector2(37.6, 39.0)
## Officer spots (floor level): the crocodile in front of the lineup room, the cat behind the
## evidence counter.
const LINEUP_OFFICER_SPOT := Vector3(45.25, 0, 50.55)
const EVIDENCE_OFFICER_SPOT := Vector3(38.35, 0, 43.5)
## Lineup: suspects stand on this line, centred on the room, LINEUP_PITCH apart.
const LINEUP_Z := 58.45
const LINEUP_CENTER_X := 49.34
const LINEUP_PITCH := 1.38
## Examination table (long axis along z).
const TABLE_CENTER := Vector3(35.35, 0, 42.3)
const TABLE_SIZE := Vector3(1.0, .95, 2.9)
## The door axis the design coordinates are mirrored about.
const AXIS := 43.0

## A design point in the station's frame.
static func mirror_point(p: Vector3) -> Vector3:
	return Vector3(2.0 * AXIS - p.x, p.y, p.z)

## A design direction in the station's frame.
static func mirror_direction(d: Vector3) -> Vector3:
	return Vector3(-d.x, d.y, d.z)

## Collision for the decorative police roof (7 Nov 2026; scripts/buildings/roof_solids.gd).
func solid_roofs(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/roof_solids.gd").add(town, ["RelocatedSites/Police/Police peaked roof"])

## The evidence room poster after the evidence game redesign (8 Nov 2026,
## docs/guides/MINIGAMES.md): three columns, each tool verb over the two properties it reveals
## (apretar: duro / blando, tocar: áspero / liso, levantar: pesado / ligero). The first nine
## of the poster's 18 word cards are given the new words and moved into the grid; the other
## nine go. The title is the phrase posters.evidence_title.
const EVIDENCE_POSTER_WORDS := [
	["to squeeze", "hard", "soft"],
	["to touch", "rough", "smooth"],
	["to lift", "heavy", "light (weight)"],
]

func evidence_poster_words(town: Node3D, _game) -> void:
	var poster := town.get_node_or_null("RelocatedSites/Police/Interior/Police poster evidence")
	if poster == null:
		push_error("police: evidence poster not found")
		return
	var cards: Array = poster.get_children().filter(func(n: Node) -> bool: return String(n.name).begins_with("Word "))
	# The cards that go are removed first, and the kept ones get temporary names, so every new
	# name ("Word hard") is free when it is given.
	for k in range(9, cards.size()):
		poster.remove_child(cards[k])
		cards[k].free()
	cards = cards.slice(0, 9)
	for k in cards.size():
		cards[k].name = "Evidence card %d" % k
	# Poster frame: the viewer looks along poster +Z and poster-local x is the viewer's left.
	var column_x := [1.25, 0.0, -1.25]
	var row_y := [.33, -.17, -.67]
	var used := 0
	for column in EVIDENCE_POSTER_WORDS.size():
		for row in EVIDENCE_POSTER_WORDS[column].size():
			var key: String = EVIDENCE_POSTER_WORDS[column][row]
			var card: Node3D = cards[used]
			used += 1
			card.name = "Word " + key
			card.set_meta("word_key", key)
			card.position = Vector3(column_x[column], row_y[row], card.position.z)
			for area in card.find_children("*", "Area3D", false, false):
				area.set_meta("object_name", "Word " + key)
				area.set_meta("word", key)
				area.set_meta("root", card)
			for label in card.find_children("*", "Label3D", false, false):
				# Back to the card's base text size first: the old word may have been shrunk to fit.
				label.pixel_size = float(label.get_meta("lexicon_pixel", label.pixel_size))
				preload("res://scripts/language/live_labels.gd").bind(label, {"word": key}, float(label.get_meta("lexicon_fit", 0.5)))

## The evidence room shelves after the object change of 8 Nov 2026 (second pass, user request:
## common, distinct, good-looking objects; docs/guides/TOWN_DESIGN_BRIEF.md "Police evidence game
## redesign"): the ten labelled exhibits show the game's new objects in the shared model style
## (evidence_props.gd). Each exhibit keeps its node, position and pick body; it gets the new
## word (name, word_key, pick metadata) and a new model. Heavy objects on the lower shelf.
const EVIDENCE_SHELF := [
	["stone", "stone"], ["key", "coconut"], ["hand bell", "pan"], ["fabric", "dumbbell"], ["wooden block", "pencil"],
	["paper", "key"], ["rope", "towel"], ["sponge", "sponge"], ["bottle", "pillow"], ["ball", "ball"],
]

func evidence_shelf_objects(town: Node3D, _game) -> void:
	var EvidenceProps := preload("res://scripts/learning/evidence_props.gd")
	var interior := town.get_node_or_null("RelocatedSites/Police/Interior")
	if interior == null:
		push_error("police: interior not found")
		return
	var data := EvidenceProps.load_data()
	var exhibits: Array = []
	for pair in EVIDENCE_SHELF:
		var exhibit: Node3D = interior.get_node_or_null("Evidence " + str(pair[0]))
		if exhibit == null:
			push_error("police: evidence exhibit %s not found" % pair[0])
			return
		exhibits.append(exhibit)
	# Temporary names first, so every new name ("Evidence key") is free when it is given.
	for k in exhibits.size():
		exhibits[k].name = "Evidence exhibit %d" % k
	for k in exhibits.size():
		var exhibit: Node3D = exhibits[k]
		var kind: String = EVIDENCE_SHELF[k][1]
		var look: Dictionary = EvidenceProps.shelf_look(data, kind)
		var key := str(look.word)
		exhibit.name = "Evidence " + key
		exhibit.set_meta("word_key", key)
		for area in exhibit.find_children("*", "Area3D", false, false):
			area.set_meta("object_name", "Evidence " + key)
			area.set_meta("word", key)
			area.set_meta("root", exhibit)
		_remodel_exhibit(exhibit, kind, look)

func _remodel_exhibit(exhibit: Node3D, kind: String, look: Dictionary) -> void:
	var old := exhibit.get_node_or_null("EvidenceItem")
	if old != null:
		exhibit.remove_child(old)
		old.free()
	exhibit.add_child(preload("res://scripts/learning/evidence_props.gd").build(kind, look))

## Lobby rearrangement (user request with a marked-up photo, 8 Nov 2026; docs/guides/TOWN_DESIGN_BRIEF.md
## "Police lobby rearrangement"). STATION coordinates here (low x = the right seen from the door):
## - the reception desk (with its monitor, phone, tray, hanging sign and pendant) turns a quarter
##   so its back is against the right side wall (x 33.12), front to the lobby, centre z 41.6;
## - the three waiting chairs move to the front wall, right of the entrance, under the window;
## - the notice board shifts toward the front so the hanging sign does not cover it;
## - the second officer workstation (desk, chair, monitor, keyboard, radio, folder, report) and
##   its floating OFFICERS / AGENTES sign go; the other workstation keeps every word;
## - the "¿Cómo es?" poster moves to the right side wall between the reception and the lineup
##   room, and the coffee cabinet beside it moves back to make room;
## - the lineup room's open corner doorway gets a door hinged at the side wall, opening inward;
## - the lineup room's front wall gets a dark one-way window where the poster hung.
const LOBBY_DESK_CENTRE := Vector3(33.70, 0, 41.6)
const LOBBY_CHAIR_X := [37.58, 38.30, 39.02]
const LOBBY_CHAIR_Z := 38.25
const LINEUP_DOORWAY := Vector2(33.5, 35.1)
const LINEUP_WINDOW := Rect2(35.6, .95, 4.1, 1.4)

func lobby_layout(town: Node3D, game) -> void:
	var site: Node3D = town.get_node_or_null("RelocatedSites/Police")
	if site == null:
		push_error("police: station not found")
		return
	var interior: Node3D = site.get_node("Interior")
	# Reception: every part turns about the desk's old centre and lands against the side wall.
	var old_centre := Vector3(38.2, 0, 41.1)
	var turn := Basis(Vector3.UP, -PI / 2)
	for path in ["Police reception", "Reception monitor", "Desk phone", "RECEPTION sign lettering",
			"Interior/Reception cladding", "Interior/Reception top", "Interior/Reception front panel",
			"Interior/Reception kick", "Interior/Badge shield", "Interior/Badge tip", "Interior/Badge star",
			"Interior/Report tray", "Interior/Sign cord", "Interior/Reception sign", "Interior/Pendant cord",
			"Interior/Pendant shade", "Interior/Pendant bulb"]:
		var part := site.get_node_or_null(path) as Node3D
		if part == null:
			push_error("police: reception part %s not found" % path)
			continue
		var offset := part.position - old_centre
		part.position = LOBBY_DESK_CENTRE + turn * Vector3(offset.x, 0, offset.z) + Vector3(0, part.position.y, 0)
		part.basis = turn * part.basis
	# Notice board and its pinned notice: toward the front corner, clear of the hanging sign.
	for path in ["Information display", "Interior/Notice", "Interior/Pin"]:
		var part := site.get_node_or_null(path) as Node3D
		if part != null:
			part.position.z -= .85
	# Waiting chairs: along the front wall right of the door, facing into the lobby.
	var chairs := [["Chair9", "Chair back5"], ["Chair10", "Chair back6"], ["Chair11", "Chair back7"]]
	for k in chairs.size():
		var seat := site.get_node(chairs[k][0]) as Node3D
		var back := site.get_node(chairs[k][1]) as Node3D
		seat.position = Vector3(LOBBY_CHAIR_X[k], seat.position.y, LOBBY_CHAIR_Z)
		back.position = Vector3(LOBBY_CHAIR_X[k], back.position.y, LOBBY_CHAIR_Z - .29)
		back.rotation.y = 0.0
	# The second workstation and the floating OFFICERS sign.
	for path in ["Officer workstation surface2", "Officer workstation leg5", "Officer workstation leg6",
			"Officer workstation leg7", "Officer workstation leg8", "Police monitor2", "Keyboard3", "Chair13",
			"Chair back9", "Radio2", "Case folder2", "Office desk pad2", "Case report2", "OFFICERS upgrade sign",
			"Interior/Office desk pad2", "Interior/Case report2"]:
		var gone := site.get_node_or_null(path)
		if gone != null:
			gone.get_parent().remove_child(gone)
			gone.free()
	# The word poster on the right side wall, facing the lobby; the coffee corner moves back.
	var poster := interior.get_node("Police poster appearance") as Node3D
	poster.position = Vector3(33.19, poster.position.y, 46.0)
	poster.rotation.y = -PI / 2
	for path in ["Coffee cabinet", "Coffee cabinet top", "Cabinet seam", "Coffee maker", "Coffee cup"]:
		var part := interior.get_node_or_null(path) as Node3D
		if part != null:
			part.position.z += 2.3
	_lineup_front(site, game)

## The lineup room's front wall (z 52, x 35.1..40.2, 3 high) rebuilt around a dark window, and a
## hinged door in the corner doorway (x 33.5..35.1) that opens into the room.
func _lineup_front(site: Node3D, game) -> void:
	var partitions: Node3D = site.get_node("Partitions")
	var old: Node3D = partitions.get_node("Lineup front wall")
	var wall_mat: Material = (old.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).material_override
	partitions.remove_child(old)
	old.free()
	var z := 52.0
	var t := .14
	var win := LINEUP_WINDOW
	var pieces := [
		["Lineup front wall", Vector3(35.1, 0, 0), Vector3(40.2, win.position.y, 0)],
		["Lineup window header", Vector3(35.1, win.end.y, 0), Vector3(40.2, 3.0, 0)],
		["Lineup window jamb", Vector3(35.1, win.position.y, 0), Vector3(win.position.x, win.end.y, 0)],
		["Lineup window jamb 2", Vector3(win.end.x, win.position.y, 0), Vector3(40.2, win.end.y, 0)],
		["Lineup door header", Vector3(LINEUP_DOORWAY.x, 2.35, 0), Vector3(LINEUP_DOORWAY.y, 3.0, 0)],
	]
	for piece in pieces:
		var a: Vector3 = piece[1]
		var b: Vector3 = piece[2]
		var node: Node3D = game.box(piece[0], Vector3((a.x + b.x) * .5, (a.y + b.y) * .5, z), Vector3(b.x - a.x, b.y - a.y, t), Color.WHITE)
		node.reparent(partitions, false)
		node.position = Vector3((a.x + b.x) * .5, (a.y + b.y) * .5, z)
		(node.get_child(0) as MeshInstance3D).material_override = wall_mat
	# Dark one-way glass ("observation window"), clickable as "window", with a frame both sides.
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(.09, .11, .15, .72)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.metallic = .55
	glass_mat.roughness = .06
	glass_mat.metallic_specular = 1.0
	var centre := Vector3(win.get_center().x, win.get_center().y, z)
	var glass: Node3D = game.box("Lineup observation window", centre, Vector3(win.size.x, win.size.y, .03), Color(.09, .11, .15), "window")
	glass.reparent(site, false)
	glass.position = centre
	(glass.get_child(0) as MeshInstance3D).material_override = glass_mat
	var frame_color := Color("2b3a4f")
	for face in [-1.0, 1.0]:
		var fz: float = z + face * (t * .5 + .02)
		for bar in [[Vector3(centre.x, win.end.y + .04, fz), Vector3(win.size.x + .16, .08, .04)],
				[Vector3(centre.x, win.position.y - .04, fz), Vector3(win.size.x + .16, .08, .04)],
				[Vector3(win.position.x - .04, centre.y, fz), Vector3(.08, win.size.y, .04)],
				[Vector3(win.end.x + .04, centre.y, fz), Vector3(.08, win.size.y, .04)]]:
			var trim: Node3D = game.box("Lineup window frame", bar[0], bar[1], frame_color, "", false)
			trim.reparent(site, false)
			trim.position = bar[0]
	var sill: Node3D = game.box("Lineup window sill", Vector3(centre.x, win.position.y - .06, z - t * .5 - .07), Vector3(win.size.x + .2, .05, .16), frame_color, "", false)
	sill.reparent(site, false)
	sill.position = Vector3(centre.x, win.position.y - .06, z - t * .5 - .07)
	# The door: hinged at the side-wall jamb, swinging into the lineup room (+z) when opened (E).
	var door_mat: Material = null
	var interview := site.get_node_or_null("Interview room")
	if interview != null:
		door_mat = (interview.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).material_override
	var width := LINEUP_DOORWAY.y - LINEUP_DOORWAY.x - .04
	var pivot := Node3D.new()
	pivot.name = "Lineup room door"
	site.add_child(pivot)
	pivot.position = Vector3(LINEUP_DOORWAY.x + .02, 0, z)
	pivot.set_meta("word_key", "door")
	pivot.set_meta("door_state", {"open": false, "type": "hinge", "angle": -1.55})
	var leaf: Node3D = game.box("Lineup door leaf", Vector3.ZERO, Vector3(width, 2.3, .06), Color("2b4f7e"), "door")
	leaf.reparent(pivot, false)
	leaf.position = Vector3(width * .5, 1.15, 0)
	if door_mat != null:
		(leaf.get_child(0) as MeshInstance3D).material_override = door_mat
	for body in leaf.find_children("*", "CollisionObject3D", true, false):
		body.set_meta("root", pivot)
		body.set_meta("object_name", "Lineup room door")
	for face in [-.05, .05]:
		var handle: Node3D = game.box("Lineup door handle", Vector3.ZERO, Vector3(.2, .04, .04), Color("c9d1d6"), "", false)
		handle.reparent(pivot, false)
		handle.position = Vector3(width - .18, 1.0, face)
	if game.get("doors") is Dictionary:
		game.doors[pivot] = pivot.get_meta("door_state").duplicate(true)

## Reception officer and chairs (user request, 8 Nov 2026; docs/guides/TOWN_DESIGN_BRIEF.md "Police lobby
## rearrangement"). The plush characters are about 1.6 deep, so the reception moves 1.7 out from the
## side wall and a beagle in the police uniform stands behind it, facing the lobby (word "police
## officer", like the crocodile and the cat). Every chair in the station (the bare seat-and-back
## boxes, no legs) gets a modelled chair: steel legs, an upholstered seat and backrest; the
## workstation chair is a swivel chair on a five-star base. The chair roots, words and positions
## stay; the separate "Chair back" boxes are folded into the new models.
const RECEPTION_SHIFT := 1.7
const RECEPTION_OFFICER := "ReceptionOfficer"
const RECEPTION_OFFICER_SPOT := Vector3(34.0, 0, 41.6)
const RECEPTION_PLATFORM := .5
## chair root -> [its old back box, style]
const STATION_CHAIRS := {"Chair9": ["Chair back5", "waiting"], "Chair10": ["Chair back6", "waiting"],
	"Chair11": ["Chair back7", "waiting"], "Chair12": ["Chair back8", "office"],
	"Chair14": ["Chair back10", "interview"], "Chair15": ["Chair back11", "interview"]}
const CHAIR_STYLES := {"waiting": ["2f63a8", "3b4149"], "office": ["1f3550", "2f3338"], "interview": ["7d8790", "4a5058"]}
const Art := preload("res://scripts/buildings/supermarket_products.gd")

func reception_officer_chairs(town: Node3D, _game) -> void:
	var site: Node3D = town.get_node_or_null("RelocatedSites/Police")
	if site == null:
		push_error("police: station not found")
		return
	for path in ["Police reception", "Reception monitor", "Desk phone", "RECEPTION sign lettering",
			"Interior/Reception cladding", "Interior/Reception top", "Interior/Reception front panel",
			"Interior/Reception kick", "Interior/Badge shield", "Interior/Badge tip", "Interior/Badge star",
			"Interior/Report tray", "Interior/Sign cord", "Interior/Reception sign", "Interior/Pendant cord",
			"Interior/Pendant shade", "Interior/Pendant bulb"]:
		var part := site.get_node_or_null(path) as Node3D
		if part != null:
			part.position.x += RECEPTION_SHIFT
	# The counter top is 1.49 (1.94 in the world, the station is scaled 1.3): the officer stands on a
	# low staff platform behind it so the face shows above the counter.
	var platform: Node3D = _game.box("Reception platform", Vector3.ZERO, Vector3(1.66, RECEPTION_PLATFORM, 2.7), Color("5b6470"))
	platform.reparent(site, false)
	platform.position = Vector3(33.12 + .83, RECEPTION_PLATFORM * .5, 41.6)
	var nosing: Node3D = _game.box("Reception platform edge", Vector3.ZERO, Vector3(.04, .03, 2.7), Color("c9a24a"), "", false)
	nosing.reparent(site, false)
	nosing.position = Vector3(33.12 + 1.66, RECEPTION_PLATFORM - .015, 41.6)
	var characters = preload("res://scripts/characters/house_characters.gd").new()
	var officer: Node3D = characters.worker("res://scenes/characters/beagle_plush.tscn", "police", "police officer", site,
		RECEPTION_OFFICER, site.to_global(RECEPTION_OFFICER_SPOT), site.global_basis * Vector3(1, 0, 0))
	officer.global_position.y += site.global_basis.get_scale().y * RECEPTION_PLATFORM
	officer.set_meta("reference_site", "Police")
	var art = Art.new()
	for title in STATION_CHAIRS:
		var chair := site.get_node_or_null(title) as Node3D
		var back := site.get_node_or_null(STATION_CHAIRS[title][0]) as Node3D
		if chair == null or back == null:
			push_error("police: chair %s not found" % title)
			continue
		var front := chair.position - back.position
		front.y = 0
		var style: String = STATION_CHAIRS[title][1]
		chair.basis = Basis.looking_at(front.normalized(), Vector3.UP)
		back.get_parent().remove_child(back)
		back.free()
		var mesh: MeshInstance3D = null
		for child in chair.get_children():
			if child is MeshInstance3D:
				mesh = child
		mesh.mesh = _chair_mesh(art, style)
		mesh.material_override = null
		# One box from the floor to the seat and one for the backrest (local: front is -z).
		var body: CollisionObject3D = chair.find_children("*", "CollisionObject3D", false, false)[0]
		var low := body.get_child(0) as CollisionShape3D
		(low.shape as BoxShape3D).size = Vector3(.54, .5, .52)
		low.position = Vector3(0, -.21, 0)
		var high := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(.5, .5, .1)
		high.shape = shape
		high.position = Vector3(0, .32, .25)
		high.name = "Backrest"
		body.add_child(high)

## A chair in the product art style, origin at the seat centre (0.46 above the floor), front -z.
static func _chair_mesh(art, style: String) -> ArrayMesh:
	var cloth: String = CHAIR_STYLES[style][0]
	var steel: String = CHAIR_STYLES[style][1]
	var floor := -.46
	art.begin()
	# Seat: a shell under a plump cushion with a rounded front edge.
	art.bx(Vector3(0, -.05, -.01), Vector3(.5, .03, .48), steel, Art.SATIN)
	art.bx(Vector3(0, .0, .0), Vector3(.48, .08, .44), cloth, Art.MATTE)
	art.cyl(Vector3(0, .0, -.22), Vector3(.08, .48, .08), cloth, Art.MATTE, Vector3(0, 0, PI / 2), 10)
	# Backrest: a cushion tilted back on two posts.
	art.bx(Vector3(0, .33, .24), Vector3(.46, .34, .07), cloth, Art.MATTE, Vector3(.12, 0, 0))
	art.bx(Vector3(0, .33, .275), Vector3(.48, .36, .02), steel, Art.SATIN, Vector3(.12, 0, 0))
	if style == "office":
		art.cyl(Vector3(-.2, .2, .25), Vector3(.03, .44, .03), steel, Art.METAL, Vector3(.12, 0, 0), 8)
		art.cyl(Vector3(.2, .2, .25), Vector3(.03, .44, .03), steel, Art.METAL, Vector3(.12, 0, 0), 8)
		# Gas lift, five-star base and casters; armrests.
		art.cyl(Vector3(0, -.24, 0), Vector3(.06, .36, .06), "9aa3ab", Art.METAL, Vector3.ZERO, 10)
		art.cyl(Vector3(0, -.11, 0), Vector3(.12, .06, .12), steel, Art.SATIN, Vector3.ZERO, 10)
		for k in 5:
			var a := TAU * k / 5.0
			var tip := Vector3(sin(a) * .27, 0, cos(a) * .27)
			art.bx(Vector3(tip.x * .5, floor + .07, tip.z * .5), Vector3(.05, .04, .3), steel, Art.SATIN, Vector3(0, a, 0))
			art.ball(Vector3(tip.x, floor + .03, tip.z), Vector3(.06, .06, .06), "22262b", Art.SATIN)
		for side in [-1.0, 1.0]:
			art.bx(Vector3(side * .25, .12, .0), Vector3(.03, .2, .03), steel, Art.METAL)
			art.bx(Vector3(side * .25, .23, -.02), Vector3(.06, .03, .28), "22262b", Art.SATIN)
	else:
		# Four steel legs with foot caps, side rails, and the back posts carried up from the rear legs.
		for x in [-.22, .22]:
			for z in [-.2, .21]:
				art.cyl(Vector3(x, (floor - .06) * .5, z), Vector3(.035, .4, .035), steel, Art.METAL, Vector3.ZERO, 8)
				art.cyl(Vector3(x, floor + .01, z), Vector3(.045, .02, .045), "22262b", Art.SATIN, Vector3.ZERO, 8)
			art.bx(Vector3(x, floor + .14, 0), Vector3(.02, .02, .4), steel, Art.METAL)
			art.cyl(Vector3(x, .2, .25), Vector3(.03, .46, .03), steel, Art.METAL, Vector3(.12, 0, 0), 8)
		if style == "waiting":
			for side in [-1.0, 1.0]:
				art.bx(Vector3(side * .26, .12, -.04), Vector3(.03, .2, .03), steel, Art.METAL)
				art.bx(Vector3(side * .26, .22, .03), Vector3(.05, .03, .36), steel, Art.SATIN)
	return art.finish("Police chair " + style)


## Interiors polish, 9 Nov 2026 (docs/guides/TOWN_DESIGN_BRIEF.md "Interiors polish"; light pass):
## 1. the invisible blockers around the evidence shelves and the steel equipment shelving were on
##    the pointer's layer, so the ten exhibits and the riot helmets inside them could not be
##    clicked; they now stop the player only (FIGURE_LAYER), like the sports store fixtures;
## 2. things that look like taught words become words with existing keys: the lobby planter and
##    plant, the riot helmets, the report tray, the desk lamp, the interview room's ceiling light
##    and mirror, the cell bench's blanket, the coffee cabinet and the reception's badge emblem.
## The evidence room furniture, the lineup room and the lockers are left as they are.
const POLISH_TAGS := [
	["Planter", "planter"], ["Plant", "plant"], ["Report tray", "tray"], ["Bench blanket", "blanket"],
	["Coffee cabinet", "cabinet"],
]
## [new root name, word, parts (the first gives the root's place)]
const POLISH_GROUPS := [
	["Desk lamp", "lamp", ["Desk lamp shade", "Desk lamp arm", "Desk lamp base"]],
	["Interview ceiling light", "ceiling light", ["Interview lamp", "Interview lamp cord"]],
	["Interview room mirror", "mirror", ["Interview mirror", "Mirror frame"]],
	["Badge emblem", "badge", ["Badge star", "Badge shield", "Badge tip"]],
]

func interiors_polish(town: Node3D, _game) -> void:
	var interior := town.get_node_or_null("RelocatedSites/Police/Interior") as Node3D
	if interior == null:
		push_error("police: interior not found")
		return
	var figure_layer: int = preload("res://scripts/characters/house_characters.gd").FIGURE_LAYER
	for title in ["Evidence shelving collision", "Steel shelving collision"]:
		var body := interior.get_node_or_null(title) as CollisionObject3D
		if body == null:
			push_error("police: %s not found" % title)
			continue
		body.collision_layer = figure_layer
		body.collision_mask = 0
	for pair in POLISH_TAGS:
		var node := interior.get_node_or_null(str(pair[0])) as Node3D
		if node == null:
			push_error("police: %s not found" % pair[0])
			continue
		_polish_word(node, str(pair[1]))
	# The three riot helmets on the equipment shelving (the first is named, the others are copies).
	var first := interior.get_node_or_null("Riot helmet") as Node3D
	if first == null:
		push_error("police: riot helmet not found")
	else:
		for child in interior.get_children():
			if child is Node3D and child.get_child_count() > 0 and absf(child.position.x - first.position.x) < .01 \
					and absf(child.position.y - first.position.y) < .01 and absf(child.position.z - first.position.z) < .7:
				_polish_word(child, "helmet")
	for spec in POLISH_GROUPS:
		var parts: Array = []
		for title in spec[2]:
			var part := interior.get_node_or_null(str(title)) as Node3D
			if part == null:
				push_error("police: %s not found" % title)
			else:
				parts.append(part)
		if parts.is_empty():
			continue
		var group := Node3D.new()
		group.name = str(spec[0])
		interior.add_child(group)
		group.transform = (parts[0] as Node3D).transform
		for part in parts:
			part.reparent(group, true)
		_polish_word(group, str(spec[1]))

## Makes `node` a word root; adds a pick area fitted to its meshes when it has no collision.
func _polish_word(node: Node3D, word: String) -> void:
	node.set_meta("word_key", word)
	node.set_meta("learning_object", true)
	if not node.find_children("*", "CollisionObject3D", true, false).is_empty():
		return
	var inverse := node.global_transform.affine_inverse()
	var box := AABB()
	var first := true
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null:
			continue
		var b: AABB = inverse * mesh.global_transform * mesh.mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	if first:
		return
	var area := Area3D.new()
	area.name = "Interaction"
	area.collision_layer = 2
	area.collision_mask = 0
	var shape := CollisionShape3D.new()
	var cube := BoxShape3D.new()
	cube.size = box.size + Vector3.ONE * .02
	shape.shape = cube
	shape.position = box.get_center()
	area.add_child(shape)
	node.add_child(area)

## Faces that shared a plane and flickered are set apart (10 Nov 2026,
## scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "police")

## Second pass: faces a first move brought into a new plane, and labels widened for translated
## text (10 Nov 2026, scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps_2(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "police", 2)


## Window glass as the shared window component (12 Nov 2026, docs/guides/WINDOWS.md).
func glass_windows(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/glass_windows.gd").migrate(town, "police")


## Real windows (user, 18 Nov 2026; docs/guides/WINDOWS.md "Real windows"): the two front windows
## were stacked panes (facade glazing, storefront panel and pane, pier window) in front of the
## solid pier and painted lining, and the evidence room had a painted "Window light". Each becomes
## one see-through CIVIC window (sky frame, stone sill) in an opening through the pier, the facade
## skin and the lining. Town coordinates (+X west; the station's front faces +X, the room lies
## toward -X): wall layers from x -139.14 (lining) to -138.63 (skin). The window's local x runs
## along town -Z; the evidence window's first glazing bar lines up with the evidence room's
## partition (z 83.6). The lineup's one-way glass and the cell window stay.
const REAL_WINDOWS := [
	{"name": "Lobby window", "z": 74.01, "width": 6.58, "bars": []},
	{"name": "Evidence room window", "z": 85.985, "width": 6.57, "bars": [2.385, -0.45]},
]

func real_windows(town: Node3D, _game) -> void:
	var GlassWindows := preload("res://scripts/buildings/glass_windows.gd")
	var GlassWindow := preload("res://scripts/world/glass_window.gd")
	var site: Node3D = town.get_node("RelocatedSites/Police")
	for spec in REAL_WINDOWS:
		var done: Dictionary = GlassWindows.real_window(town, "police", site, Vector3(-138.885, 2.15, spec.z), Vector3(1, 0, 0), {
			"name": spec.name, "width": spec.width, "height": 2.1, "wall_depth": 0.51,
			"frame_style": GlassWindow.FrameStyle.CIVIC, "frame_accent": "sky",
			"bars": PackedFloat32Array(spec.bars)}, 0.5)
		print("police %s (word '%s'): cut %s, removed %s, left %s" % [spec.name, done.word, done.cut, done.removed, done.partial])
		if done.cut.size() != 3:
			push_error("police: %s expected 3 wall layers cut, got %d" % [spec.name, done.cut.size()])

## Two separate lockers (user, 23 Nov 2026: the pair against the rear wall looked like one
## cabinet and its doors did not open properly). The old pair overlapped (sides 0.09 apart) and
## both doors hung from x 45.9: the second door covered the first locker's opening and the
## second locker stood open. Interior-local, front faces -z, back against the rear wall.
## Each locker is now its own root ("Police locker A" at x 46.44, "Police locker B" at x 45.42,
## 0.06 apart): solid back, sides, top and plinth, a dark inside, a shelf and a coat hook; its
## door is a door_animator hinge (door_state, word "door"; COMPONENTS.md "Things that open")
## hung on the locker's outer side, so the two doors swing apart and never meet; the label
## plate (word "label") is on the door. The six apples (word "apple") stay on the shelves.
const LOCKER_CENTRES := [46.44, 45.42]
const LOCKER_SIZE := Vector3(0.96, 2.0, 0.5)
const LOCKER_BACK_Z := 59.35
const LOCKER_BODY := Color("5f7f9f")
const LOCKER_DOOR := Color("6a8cad")
const LOCKER_INSIDE := Color("3f5770")
const LOCKER_DARK := Color("2d2f3a")
const LOCKER_STEEL := Color("c9d1d6")
const LOCKER_LABEL := Color("f4eee2")

func two_lockers(town: Node3D, game) -> void:
	var interior: Node3D = town.get_node("RelocatedSites/Police/Interior")
	var apples: Array[Node3D] = []
	var removed := 0
	for child in interior.get_children():
		if not child is Node3D:
			continue
		var p: Vector3 = child.position
		if p.x < 44.8 or p.x > 47.0 or p.z < 58.8 or p.z > 59.4 or p.y > 2.1:
			continue
		if str(child.get_meta("word_key", "")) == "apple":
			apples.append(child)
		elif String(child.name).begins_with("Locker") or String(child.name).begins_with("@"):
			interior.remove_child(child)
			child.free()
			removed += 1
	assert(removed == 18, "two_lockers: expected 18 old locker parts, found %d" % removed)
	assert(apples.size() == 6, "two_lockers: expected 6 apples, found %d" % apples.size())
	var w := LOCKER_SIZE.x
	var h := LOCKER_SIZE.y
	var d := LOCKER_SIZE.z
	var mid_z := LOCKER_BACK_Z - d * .5 + .02
	var front_z := mid_z - d * .5
	for i in LOCKER_CENTRES.size():
		var cx: float = LOCKER_CENTRES[i]
		var root := Node3D.new()
		root.name = "Police locker " + ["A", "B"][i]
		root.position = Vector3(cx, 0, mid_z)
		interior.add_child(root)
		var y := .03 + h * .5
		_locker_part(game, root, "Locker back", Vector3(0, y, d * .5 - .02), Vector3(w, h, .04), LOCKER_BODY, true)
		for side in [-1, 1]:
			_locker_part(game, root, "Locker side", Vector3(side * (w * .5 - .02), y, 0), Vector3(.04, h, d), LOCKER_BODY, true)
		_locker_part(game, root, "Locker top", Vector3(0, .03 + h - .02, 0), Vector3(w, .04, d), LOCKER_BODY, true)
		_locker_part(game, root, "Locker plinth", Vector3(0, .09, 0), Vector3(w, .12, d), LOCKER_BODY, true)
		_locker_part(game, root, "Locker inside", Vector3(0, y, d * .5 - .045), Vector3(w - .1, h - .1, .01), LOCKER_INSIDE)
		_locker_part(game, root, "Locker shelf", Vector3(0, 1.33, .01), Vector3(w - .08, .03, d - .06), LOCKER_BODY, true)
		_locker_part(game, root, "Locker coat hook", Vector3(0, 1.1, d * .5 - .07), Vector3(.04, .04, .08), LOCKER_STEEL)
		# The door: a hinge on the locker's outer edge (A: +x, B: -x), the leaf toward the other side.
		var outer := 1.0 if i == 0 else -1.0
		var hinge := Node3D.new()
		hinge.name = "Locker door"
		hinge.position = Vector3(outer * (w * .5 - .005), y, -d * .5 - .02)
		hinge.set_meta("word_key", "door")
		# The leaf lies along `span` from the hinge. Turning about +y by a turns +x toward -z, so
		# the leaf reaches the room (-z) with angle 1.75 * span: both doors open out, apart.
		var span := -outer
		hinge.set_meta("door_state", {"open": false, "type": "hinge", "angle": 1.75 * span})
		root.add_child(hinge)
		var leaf_w := w - .01
		# The pick area belongs to the hinge (the word root and the door), as before.
		var door := _locker_part(game, hinge, "Locker door panel", Vector3(span * leaf_w * .5, 0, 0), Vector3(leaf_w, h - .02, .03), LOCKER_DOOR, false, "door")
		door.remove_meta("word_key")
		for area in door.find_children("*", "Area3D", false, false):
			area.set_meta("root", hinge)
			area.set_meta("object_name", "Locker door")
		for k in 3:
			_locker_part(game, hinge, "Locker vent", Vector3(span * leaf_w * .5, .45 + k * .1, -.02), Vector3(.34, .03, .01), LOCKER_DARK)
		_locker_part(game, hinge, "Locker handle", Vector3(span * (leaf_w - .12), 0, -.03), Vector3(.04, .2, .03), LOCKER_STEEL)
		_locker_part(game, hinge, "Locker label", Vector3(span * leaf_w * .5, .78, -.02), Vector3(.5, .2, .01), LOCKER_LABEL, false, "label")
	# Apples onto the nearest locker's shelf, same place relative to it.
	for apple in apples:
		var nearest: float = LOCKER_CENTRES[0] if absf(apple.position.x - 46.45) < absf(apple.position.x - 45.4) else LOCKER_CENTRES[1]
		var old: float = 46.45 if nearest == LOCKER_CENTRES[0] else 45.4
		apple.position.x += nearest - old
		apple.position.y = 1.33 + .015
		apple.position.z = mid_z + .02
	print("two_lockers: removed %d old parts, built 2 lockers, moved %d apples" % [removed, apples.size()])

## A box part of a locker under `parent` (Main's box(); solid = a static body, word = a pick area).
func _locker_part(game, parent: Node3D, title: String, pos: Vector3, size: Vector3, color: Color, solid := false, word := "") -> Node3D:
	var part: Node3D = game.box(title, Vector3.ZERO, size, color, word, solid)
	part.reparent(parent, false)
	part.position = pos
	return part

## Door sounds (user, 25 Nov 2026: "each door should have different sound"): the holding cell
## rings like a cell door, the two lockers like lockers (door_animator.gd set_sound_kind; cues
## door.cell.* and door.locker.* in data/sounds.json). The other doors keep the usual room and
## sliding sounds.
func door_sounds(town: Node3D, game) -> void:
	var DoorAnimator := preload("res://scripts/core/door_animator.gd")
	var site: Node3D = town.get_node("RelocatedSites/Police")
	var tagged := 0
	for path in ["Holding cell"]:
		tagged += int(DoorAnimator.set_sound_kind(game, site.get_node_or_null(path), "cell"))
	for path in ["Interior/Police locker A/Locker door", "Interior/Police locker B/Locker door"]:
		tagged += int(DoorAnimator.set_sound_kind(game, site.get_node_or_null(path), "locker"))
	if tagged != 3:
		push_error("police door_sounds: expected 3 doors, tagged %d" % tagged)
	print("POLICE door_sounds: %d doors" % tagged)
