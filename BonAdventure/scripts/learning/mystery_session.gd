extends Node
## Mystery Doors (Mystery House, "Casa de las Estrellas"; user brief and approval, 9 Nov 2026;
## design record: docs/guides/TOWN_DESIGN_BRIEF.md "Mystery House and Mystery Doors"). Madame Luna, the
## fortune-teller cat by the crystal ball in the mystery room (MadameLuna, saved in the mystery
## unit by scripts/buildings/mystery.gd), shows the gold "!" while the player is in the room and
## asks in the SHARED dialogue box whether they want to play. Yes starts the game right there
## (user, 10 Nov 2026; no fade, no move): the card (mystery_card.gd) opens and the first round
## is played at the mystery room's own three doors. The right door swaps the player, in the
## same frame, into the identical-looking endless hall below (_swap_into_hall).
##
## Learning goal: colours and shapes (circle, square, triangle, star). Each game is
## Board.rounds() doors (6 in data/activities.json "mystery_luna"). Before each door after the
## first the three leaves are recoloured and show one shape each; the card gives a clue in the language being
## learned. The first third of the rounds name the shape ("Entra por la puerta con la
## estrella."), the second the colour ("Entra por la puerta roja."), the last both ("Entra por
## la puerta roja con la estrella."), where one other door shares the colour and another the
## shape, so the whole sentence matters. The player walks to a door and opens it with E or a
## click (mystery_door.gd hands it here; outside a game the doors are locked: a rattle and
## mystery.locked).
##
## The endless hall (user, 9 Nov 2026): a straight hall of identical rooms. The first round's
## doors are the mystery room's as they are (they get a new random look each time the player
## leaves the house); at its right door the player is moved invisibly to the same spot before
## the hall's wall B, whose doors look the same, and that wall's door opens. Behind the player there is only ever one door: the one they came through (the
## other openings are covered on that side). Every round is at the next door wall. Right door: it
## swings open, "¡Correcto!" on the card, and the player walks through it themselves. Through the
## doorway the card shows the next clue at once and the door slams shut behind them as soon as its
## swing is clear of them (user, 10 Nov 2026); then the session moves them back one room (Mystery.HALL_STEP) where the walls show the same doors, so
## the hall never ends (the hall: mystery.gd ENDLESS). A shut door behind the player rattles:
## mystery.no_way_back. After the last door (user, 9 Nov 2026) the room has a treasure chest:
## E or a click opens it, Luna's diamond shakes, surges up in a rainbow ray and vanishes
## (mystery.treasure_returned); the chest stays open and one door ahead opens. Walking through it
## (a dark doorway, a fade) brings the player out of the matching mystery room door, now in that
## door's colour and shape; Luna shows the "!" and, talked to, thanks them and gives the result.
## Wrong door: it rattles, a puff of smoke, the player is a toad for TOAD_SECONDS and can hop
## about (speed_override on the player: fast in the air, still on landing), another puff and back;
## Luna repeats the clue (mystery.wrong) and the card highlights its key words. The mistake is
## recorded (practice_log.gd: per word, the colour and the shape separately) and the round goes
## on; nothing resets. Only doors opened at the first try move the progress bar. After the last
## door Luna says how many and offers Play again or Finish.
##
## Leaving: the card's leave button or Esc asks "Do you want to leave the game?" (the shared quit
## card); Yes fades back to the mystery room. (The arch doorway trigger only matters if a game
## ever runs in the mystery room itself.) A language change ends the
## game at once. Sounds are ready but not recorded: cues mystery.puff / mystery.croak /
## mystery.hop / mystery.door_open / mystery.door_shut / mystery.door_locked play once
## data/sounds.json has them (the doors also emit opened / slammed / rattled for bindings).
##
## Every text comes from data/phrases.json group "mystery" (colours: warehouse.color_f_*);
## offers follow the shared activity board ("mystery_luna" in data/activities.json).
const Board := preload("res://scripts/learning/activity_board.gd")
const Host := preload("res://scripts/learning/minigame_host.gd")
const Zone := preload("res://scripts/learning/minigame_zone.gd")
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
const ModularTown := preload("res://scripts/world/modular_town.gd")
const Mystery := preload("res://scripts/buildings/mystery.gd")
const MysteryDoor := preload("res://scripts/world/mystery_door.gd")
const ToadModel := preload("res://scripts/characters/toad_model.gd")
const Sound := preload("res://scripts/core/sound.gd")
const ACTIVITY := "mystery_luna"
## How far below her hat-top the talk camera looks for Madame Luna's face (npc_presence.gd).
const LUNA_HAT_DROP := 0.6
const KINDS := ["shape", "color", "both"]
const WALK_AWAY_DISTANCE := 9.0
const MESSAGE_SECONDS := 7.0
## The toad: each change (a puff; the old shape shrinks away in the first half, the new one grows
## in the second; controls locked), the time as a toad, its size against the player.
## (User, 10 Nov 2026: each change 0.75 s longer, the toad 1 s longer.)
const PUFF_SECONDS := 0.95
const TOAD_SECONDS := 3.0
const TOAD_SHARE := 0.55
## The toad's hops: one hop's length, its share in the air, its speed and height.
const HOP_SECONDS := 0.5
const HOP_AIR := 0.62
const HOP_SPEED := 4.2
const HOP_HEIGHT := 0.3
## Pacing after a right door (user, 10 Nov 2026: the slam and the next message came too late).
## Once the player is THROUGH_DEPTH past the wall's far face (through the doorway) the card shows
## the next clue (or the treasure line); the door slams as soon as its swing can no longer
## touch them: the player (or where they will be LEAF_LEAD seconds on at their walking speed) is
## more than the leaf's width plus LEAF_CLEARANCE from the hinge. The camera is not waited for:
## its spring arm pulls in on the shut leaf. Then a short pause before the step back.
const THROUGH_DEPTH := 0.5
const LEAF_CLEARANCE := 0.45
const LEAF_LEAD := 0.3
const SHUT_PAUSE := 0.15

var lexicon
var dialogue_panel
var card
var interaction
var player: Node3D
var world: Node3D
var main
var house: Node3D
var luna: Node3D
var host
var zone
var presence:
	get: return host.presence if host != null else null
## Whether Luna offers the game now (rolled on approach; kept on the host).
var offered: bool:
	get: return host.offered if host != null else false
	set(value):
		if host != null:
			host.offered = value
var _rng := RandomNumberGenerator.new()
var _doorway: Area3D

## The mystery room's three doors, left to right: {"leaf": the word root (mystery_door.gd),
## "material": its own colour, "symbols": the node holding the four shapes, "x": house-local
## centre}.
var doors: Array = []
## The endless hall (hidden outside a game) and its walls A, B, C, three doors each like `doors`.
var hall: Node3D
var hall_walls: Array = []

## The running game. state: "" (none), "choose", "toad", "walk", "shut", "fade", "paused",
## "treasure" (the chest waits), "diamond" (its animation), "exit" (the door out is open),
## "return" (back in the mystery room, to talk to Luna), "over" (the result and its choices).
var state := ""
var _paused_from := ""
## The arch's door guard (minigame_zone.gd make_door_guard, shared since 11 Nov 2026): the
## barrier (its shape enabled during a game) and the room-side zone in front of it that asks
## the quit question; _asked_at_arch while that question is up.
var arch
var _asked_at_arch: bool:
	get: return arch != null and arch.asked
## The question zone, house-local: the room side of the arch, 1.4 deep.
const ARCH_ASK_AT := Vector3(0.0, Mystery.FLOOR + 2.0, Mystery.HALL_REAR + 0.95)
const ARCH_ASK_SIZE := Vector3(Mystery.ARCH.x + 0.4, 4.0, 1.4)
var rounds: Array = []
var current := -1
## Whether no wrong door was tried in this round yet.
var _first_try := true
## Doors opened at the first try in the finished game (complete() then fills the board's count).
var _first_right := -1
var _timer := 0.0
## Toad phases: "in" (puff, then the toad), "toad", "out" (puff, then the player again).
var _toad_phase := ""
var _toad: Node3D
## Where the toad is in its hop (0 resting, below HOP_AIR in the air).
var _hop := 0.0
## The door the player is walking through (its index on the round's wall).
var _through := -1
## Whether the card already shows what comes after the open door (the player is through it).
var _announced := false
var _was_inside := false
## The ending: the chest, its lid, the diamond, the rainbow ray, the door out (index on wall C) and
## the looks wall C shows (the mystery room takes them).
var treasure: Node3D
var chest: Node3D
var _lid: Node3D
var _diamond: Node3D
var _ray: Node3D
var exit_door := -1
var _exit_looks: Array = []
## Seconds until the mystery room door the player came out of swings shut (0: none).
var _room_door_close := 0.0
## True while the first round is played at the mystery room's own doors.
var _room_round := false
## Seconds the player has been out of the house while a game runs (_guard_place()).
var _outside_time := 0.0
## Fail-safes (23 Nov 2026; a web player was found outside the supermarket with "Door 5 of 6"
## still on screen: Main's fall respawn below y -15 had moved them out of the endless hall, whose
## floor is only 4 m above that line, and the game ran on). A player more than FALL_DEPTH under
## the hall floor is put back on it; one out of the house for OUTSIDE_GRACE seconds (any other
## move: a respawn, a reload's resume, a test) ends the game, its card and hall with it.
const FALL_DEPTH := 1.5
const OUTSIDE_GRACE := 0.5

func setup(shared_lexicon, shared_dialogue_panel, game_card, interaction_controller, explorer: Node3D, town: Node3D, game) -> void:
	name = "MysterySession"
	lexicon = shared_lexicon
	dialogue_panel = shared_dialogue_panel
	card = game_card
	interaction = interaction_controller
	player = explorer
	world = town
	main = game
	_rng.randomize()
	add_to_group(MysteryDoor.GROUP)
	house = ModularTown.building(town, "mystery")
	luna = house.get_node_or_null("MysteryRoom/" + Mystery.LUNA) if house != null else null
	if luna == null:
		push_warning("mystery_session: no mystery unit (dev focus) or no " + Mystery.LUNA)
		return
	# The talk camera frames her face, not her tall wizard hat (plush_costumes.json height 0.6).
	luna.set_meta("talk_face_drop", LUNA_HAT_DROP)
	for i in Mystery.DOOR_NAMES.size():
		var leaf: Node3D = house.get_node_or_null("DoorWall/%s/Hinge/Door leaf" % Mystery.DOOR_NAMES[i])
		if leaf == null:
			push_warning("mystery_session: no door leaf " + Mystery.DOOR_NAMES[i])
			doors = []
			return
		doors.append(_door_entry(leaf, float(Mystery.DOOR_X[i])))
	hall = house.get_node_or_null(Mystery.ENDLESS)
	for wall_name in Mystery.HALL_WALL_NAMES:
		var wall: Array = []
		for i in Mystery.DOOR_NAMES.size():
			var leaf: Node3D = house.get_node_or_null("%s/%s/%s/Hinge/Door leaf" % [Mystery.ENDLESS, wall_name, Mystery.DOOR_NAMES[i]])
			if leaf == null:
				push_warning("mystery_session: no endless hall door %s/%s" % [wall_name, Mystery.DOOR_NAMES[i]])
				doors = []
				return
			var entry := _door_entry(leaf, float(Mystery.DOOR_X[i]))
			var holder: Node = leaf.get_parent().get_parent()
			entry["cover"] = holder.get_node_or_null("Back cover")
			entry["back"] = holder.get_node_or_null("Back")
			wall.append(entry)
		hall_walls.append(wall)
	host = Host.new()
	add_child(host)
	host.setup(self, {"activity": ACTIVITY, "group": "mystery", "speaker": "mystery.luna", "walk_away": WALK_AWAY_DISTANCE, "message_seconds": MESSAGE_SECONDS}, lexicon, dialogue_panel, interaction, player, luna)
	host.play_chosen.connect(start_game)
	host.choice_made.connect(_on_choice)
	host.talk_closed.connect(_on_talk_closed)
	host.leave_answered.connect(_on_leave_answered)
	zone = Zone.new()
	add_child(zone)
	zone.setup(player, main, "MysteryFade")
	treasure = house.get_node_or_null("%s/%s" % [Mystery.ENDLESS, Mystery.TREASURE])
	chest = treasure.get_node_or_null("Chest") if treasure != null else null
	if chest != null:
		_lid = chest.get_node_or_null("Lid")
		_diamond = chest.get_node_or_null("Diamond")
	# Mid-game the arch asks the shared quit question; once the diamond is back ("return", "over")
	# walking out just finishes the game like Finish (ask_leave; user, 10 Nov 2026: it used to
	# keep the game, its card and Luna's call running until the player went back to her).
	_doorway = zone.make_doorway(house, Mystery.DOORWAY, Mystery.DOORWAY_SIZE, "Mystery room doorway", func() -> void:
		if state in ["choose", "return", "over"]:
			ask_leave())
	card.leave_requested.connect(ask_leave)
	# Mid-game the player cannot walk out (user, 10 Nov 2026: the question showed but the player
	# still got out, because any refresh of the controls turned them back on). An invisible wall
	# fills the arch while a game runs (not at the final stage, where walking out finishes it);
	# stepping up to it on the room side asks the quit question, stepping back takes it away.
	# The wall stands except at the final stage ("return", "over") and while the player is
	# already outside the mystery room (e.g. placed by a test or a fade).
	arch = zone.make_door_guard(house,
		Vector3(0, Mystery.FLOOR + (Mystery.ARCH.y + 0.4) * 0.5, Mystery.HALL_REAR),
		Vector3(Mystery.ARCH.x + 0.4, Mystery.ARCH.y + 0.4, Mystery.WALL + 0.2),
		ARCH_ASK_AT, ARCH_ASK_SIZE, "Mystery arch", {
			"blocking": func() -> bool: return in_game() and not state in ["return", "over"] and (_in_mystery_room() or _in_hall()),
			"can_ask": func() -> bool: return state == "choose" and not zone.fading,
			"ask": func() -> void:
				_paused_from = state
				state = "paused"
				host.ask_leave(),
			"cancel": func() -> void:
				host.cancel_leave()
				if state == "paused":
					state = _paused_from
					main.sync_player_controls(),
			"asking": func() -> bool: return host.is_asking_leave()})

## The leaf gets its own material (the found one is never changed: it may be shared), on every
## painted part (meta leaf_paint: the leaf's box and its round head; mystery.gd).
func _door_entry(leaf: Node3D, x: float) -> Dictionary:
	var painted: Array = []
	for child in leaf.get_children():
		if child is MeshInstance3D and child.get_meta("leaf_paint", false):
			painted.append(child)
	var material := StandardMaterial3D.new()
	var found: Material = painted[0].get_active_material(0) if not painted.is_empty() else null
	if found is StandardMaterial3D:
		material = found.duplicate()
	for mesh in painted:
		mesh.material_override = material
	return {"leaf": leaf, "material": material, "painted": painted, "symbols": leaf.get_node_or_null("Symbols"), "x": x}

func activity_running() -> bool:
	return state != ""

func in_game() -> bool:
	return state != ""

## For the host: Luna can be talked to during a game (the clue again, the final score), so
## only a fade or her own open line make her busy.
func busy() -> bool:
	return (zone != null and zone.fading) or (host != null and host.line_id != "")

# --- Rounds ---------------------------------------------------------------------------------

## `count` rounds: shape clues first, then colour clues, then both (user approval, 9 Nov 2026);
## the same clue never twice in a row.
## `first`: the doors the first round keeps (the mystery room's, as they look now: user, 9 Nov
## 2026); its target is picked at random.
## Levels (LEARN-06, 25 Nov 2026; data/activities.json mystery_luna "levels"): `kinds` are the
## clue kinds in their order (KINDS when empty: shape, colour, both, a third each) and `colors`
## the door colours (all of Mystery.COLORS when empty); the room's own doors are kept for the
## first round only when their colours are all allowed.
static func make_rounds(count: int, rng: RandomNumberGenerator, first: Array = [], kinds: Array = [], colors: Array = []) -> Array:
	var made: Array = []
	var order: Array = kinds if not kinds.is_empty() else KINDS
	if not colors.is_empty() and first.any(func(look): return not colors.has(str(look[0]))):
		first = []
	for i in count:
		var kind: String = str(order[mini(order.size() - 1, i * order.size() / maxi(count, 1))])
		if i == 0 and first.size() == 3:
			made.append({"kind": kind, "doors": first.duplicate(true), "target": rng.randi_range(0, 2)})
		else:
			# A few tries for a round whose words the word memory wants (word_memory.gd, 24 Nov 2026).
			var previous: Dictionary = made.back() if not made.is_empty() else {}
			made.append(preload("res://scripts/learning/word_memory.gd").shared().pick_round(func(): return make_round(kind, rng, previous, colors), tested_words))
	return made

## One round: {"kind", "doors": [[colour, shape] x3], "target": the right door's index}.
## Shape and colour rounds give every door its own colour and shape; a "both" round gives one
## other door the target's colour and the other its shape.
static func make_round(kind: String, rng: RandomNumberGenerator, previous: Dictionary = {}, allowed: Array = []) -> Dictionary:
	var made: Dictionary = {}
	for attempt in 12:
		var colors: Array = allowed.duplicate() if allowed.size() >= 3 else Mystery.COLORS.keys()
		var shapes: Array = Mystery.SHAPES.duplicate()
		_shuffle(colors, rng)
		_shuffle(shapes, rng)
		var looks: Array = [[colors[0], shapes[0]], [colors[1], shapes[1]], [colors[2], shapes[2]]]
		if kind == "both":
			looks = [[colors[0], shapes[0]], [colors[0], shapes[1]], [colors[1], shapes[0]]]
		var order: Array = [0, 1, 2]
		_shuffle(order, rng)
		var placed: Array = []
		for i in order:
			placed.append(looks[i])
		made = {"kind": kind, "doors": placed, "target": order.find(0)}
		if previous.is_empty() or clue_key(made) != clue_key(previous):
			break
	return made

static func clue_key(round_data: Dictionary) -> String:
	var look: Array = round_data.doors[round_data.target]
	return "%s:%s:%s" % [round_data.kind, look[0] if round_data.kind != "shape" else "", look[1] if round_data.kind != "color" else ""]

static func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap: Variant = items[i]
		items[i] = items[j]
		items[j] = swap

## The clue as a phrase reference (re-rendered in any language; {clue} of mystery.wrong).
static func clue_ref(round_data: Dictionary) -> Dictionary:
	var look: Array = round_data.doors[round_data.target]
	var values := {}
	if round_data.kind != "shape":
		values["color"] = {"phrase": "warehouse.color_f_" + str(look[0])}
	if round_data.kind != "color":
		values["shape"] = {"phrase": "mystery.shape_" + str(look[1])}
	return {"phrase": "mystery.clue_" + str(round_data.kind), "values": values}

## The words a round tests (practice_log.gd keys, words.json): the colour, the shape or both.
static func tested_words(round_data: Dictionary) -> Array:
	var look: Array = round_data.doors[round_data.target]
	var keys: Array = []
	if round_data.kind != "shape":
		keys.append(str(look[0]))
	if round_data.kind != "color":
		keys.append(str(look[1]))
	return keys

func _clue_line(index := -1) -> Dictionary:
	var ref := clue_ref(rounds[current if index < 0 else index])
	return {"foreign": lexicon.text(ref, lexicon.foreign), "native": lexicon.text(ref, lexicon.native)}

## The clue's key words as lines, for the card's highlight.
func _key_lines() -> Array:
	var round_data: Dictionary = rounds[current]
	var look: Array = round_data.doors[round_data.target]
	var keys: Array = []
	if round_data.kind != "shape":
		keys.append(lexicon.line("warehouse.color_f_" + str(look[0])))
	if round_data.kind != "color":
		keys.append(lexicon.line("mystery.shape_" + str(look[1])))
	return keys

## Recolours the mystery room's door `index` and shows one shape on it.
func dress(index: int, color: String, shape: String) -> void:
	_dress_door(doors[index], color, shape)

## Shuts a wall's three doors and gives them `looks` ([colour, shape] each).
func _dress_wall(wall: Array, looks: Array) -> void:
	for i in wall.size():
		wall[i].leaf.shut_now()
		_dress_door(wall[i], looks[i][0], looks[i][1])

func _dress_door(door: Dictionary, color: String, shape: String) -> void:
	door.material.albedo_color = Mystery.COLORS[color]
	door.leaf.set_meta("door_color", color)
	door.leaf.set_meta("door_shape", shape)
	if door.symbols != null:
		for symbol in door.symbols.get_children():
			symbol.visible = str(symbol.name) == shape

## The hall's doors shut and in their default looks, every opening covered behind (and the
## mystery room's doors shut; they keep their look).
func _reset_hall() -> void:
	for door in doors:
		door.leaf.shut_now()
	for wall in hall_walls:
		_dress_wall(wall, Mystery.DOOR_DEFAULTS)
		_set_back(wall, -1)
	_show_treasure(false)

## The chest after the last door (closed, the diamond inside) or none (hidden, not solid).
func _show_treasure(on: bool) -> void:
	if is_instance_valid(_ray):
		_ray.queue_free()
	_ray = null
	if treasure == null:
		return
	treasure.visible = on
	for shape in treasure.find_children("*", "CollisionShape3D", true, false):
		shape.set_deferred("disabled", not on)
	if _lid != null:
		_lid.rotation.x = 0.0
	if _diamond != null:
		_diamond.visible = true
		_diamond.position = Vector3(0, 1.05, 0)
		_diamond.rotation = Vector3.ZERO
		_diamond.scale = Vector3.ONE

## The mystery room's doors as they look now ([colour, shape] each).
func room_looks() -> Array:
	var looks: Array = []
	for door in doors:
		looks.append([str(door.leaf.get_meta("door_color")), str(door.leaf.get_meta("door_shape"))])
	return looks

## A new random look for the mystery room's doors (each colour and shape once).
func randomize_room_doors() -> void:
	var looks: Array = make_round("shape", _rng).doors
	for i in doors.size():
		doors[i].leaf.shut_now()
		dress(i, looks[i][0], looks[i][1])

## The far side of a hall wall: only door `keep` shows (the one just come through, -1 none);
## the other openings are covered by solid lilac panels.
func _set_back(wall: Array, keep: int) -> void:
	for i in wall.size():
		var door: Dictionary = wall[i]
		if door.get("cover") != null:
			door.cover.visible = i != keep
			for shape in door.cover.find_children("*", "CollisionShape3D", true, false):
				shape.set_deferred("disabled", i == keep)
		if door.get("back") != null:
			door.back.visible = i == keep

## The doors of the current round: the mystery room's own in the first round (the game starts in
## place: user, 10 Nov 2026), then always the hall's wall B.
func _round_doors() -> Array:
	return doors if _room_round else hall_walls[1]

func _show_hall(on: bool) -> void:
	if hall != null:
		hall.visible = on

# --- Talking ------------------------------------------------------------------------------

func _say(id: String, choices: Array = [], auto_close: float = MESSAGE_SECONDS, values: Dictionary = {}) -> void:
	host.say(id, choices, auto_close, values)

func _host_talk(_talker: Node3D) -> bool:
	if in_game():
		if state == "over":
			_offer_again()
		elif state == "return":
			state = "over"
			card.hide_card()
			_offer_again()
		elif current >= 0 and current < rounds.size():
			_say("mystery.keep_going", [], MESSAGE_SECONDS, {"clue": clue_ref(rounds[current])})
		return true
	return host.gate()

## The "!" and the offer roll count while the player is in the mystery room.
func _host_near(_distance: float) -> bool:
	return _in_room()

## A question closes when the player leaves the room (the room is wider than a talk distance).
func _host_walked_away(distance: float) -> bool:
	return not _in_room() if in_game() else distance > WALK_AWAY_DISTANCE

func _in_room() -> bool:
	return _in_mystery_room() or _in_hall()

func _in_mystery_room() -> bool:
	var p: Vector3 = house.to_local(player.global_position)
	return p.z > Mystery.HALL_REAR and p.z < Mystery.DOOR_WALL and absf(p.x) < Mystery.W2 and p.y > -1.0 and p.y < Mystery.ROOM_H

## Anywhere in the house, the endless hall below it included.
func _in_house() -> bool:
	var p: Vector3 = house.to_local(player.global_position)
	return absf(p.x) < Mystery.W2 + 0.5 and p.z > Mystery.FRONT - 0.5 and p.z < Mystery.REAR + 0.5 and p.y > Mystery.ENDLESS_FLOOR - 3.0 and p.y < 20.0

func _in_hall() -> bool:
	var p: Vector3 = house.to_local(player.global_position)
	var f := Mystery.ENDLESS_FLOOR
	return p.y > f - 2.0 and p.y < f + Mystery.ROOM_H and absf(p.x) < Mystery.W2 and p.z > float(Mystery.HALL_WALLS[0]) - 1.0 and p.z < float(Mystery.HALL_WALLS[2]) + 2.0

func _on_choice(id: String) -> void:
	match id:
		"mystery_replay":
			host.close_dialogue()
			_play()
		"mystery_finish":
			host.close_dialogue()
			end_game("mystery.finished")

func _on_talk_closed(was: String) -> void:
	if was == "mystery.final" and state == "over":
		end_game("")

# --- The doors ----------------------------------------------------------------------------

## E or a click on a door leaf (mystery_door.gd use()).
func door_used(leaf: Node3D) -> void:
	# Which wall: -1 the mystery room, 0..2 the hall's A, B, C.
	var wall := -2
	var index := -1
	for i in doors.size():
		if doors[i].leaf == leaf:
			wall = -1
			index = i
	for w in hall_walls.size():
		for i in hall_walls[w].size():
			if hall_walls[w][i].leaf == leaf:
				wall = w
				index = i
	if index < 0:
		return
	if state == "":
		_locked(leaf, "mystery.locked")
		return
	if wall == -1:
		# The first round is played at the mystery room's doors (user, 10 Nov 2026).
		if _room_round and state == "choose" and not zone.fading:
			choose(index)
		return
	# In the hall: the doors behind the player stay shut (user, 9 Nov 2026).
	var behind := wall == 0 or (wall == 1 and house.to_local(player.global_position).z > float(Mystery.HALL_WALLS[1]) + Mystery.WALL)
	if behind:
		if not leaf.is_open() and state != "toad":
			_locked(leaf, "mystery.no_way_back")
		return
	if wall == 1 and state == "choose" and not zone.fading:
		choose(index)

func _locked(leaf: Node3D, line: String) -> void:
	leaf.rattle()
	_sound("mystery.door_locked", leaf)
	if host != null and not busy():
		_say(line)

## The player opened door `index` during a round.
func choose(index: int) -> void:
	var round_data: Dictionary = rounds[current]
	var target: int = round_data.target
	var chosen: Array = round_data.doors[index]
	var right_look: Array = round_data.doors[target]
	if PracticeLog.shared().game_id() == ACTIVITY:
		var outcome := {}
		if round_data.kind != "shape":
			outcome[str(right_look[0])] = chosen[0] == right_look[0]
		if round_data.kind != "color":
			outcome[str(right_look[1])] = chosen[1] == right_look[1]
		PracticeLog.shared().first_answer(outcome)
	if index == target:
		_right(index)
	else:
		_wrong(index)

func _right(index: int) -> void:
	if _room_round:
		_swap_into_hall()
	var leaf: Node3D = _round_doors()[index].leaf
	leaf.open()
	_sound("mystery.door_open", leaf)
	if PracticeLog.shared().game_id() == ACTIVITY:
		PracticeLog.shared().complete()
	if _first_try:
		Board.shared().add_success(ACTIVITY)
	if host.line_id != "":
		host.close_dialogue()
	card.praise(lexicon.line("mystery.right"), Board.shared().done(ACTIVITY), rounds.size(), lexicon.line("mystery.walk_through"))
	state = "walk"
	_through = index
	_announced = false
	_timer = 0.0
	# In the hall the room behind the open door already shows the next round's doors (wall C),
	# as wall B will after the step back.
	if current + 1 < rounds.size():
		_dress_wall(hall_walls[2], rounds[current + 1].doors)
	else:
		# The last door: the treasure room, and the doors out (new looks: the mystery room will
		# show them when the player comes out of one).
		_exit_looks = make_round("shape", _rng).doors
		exit_door = _rng.randi_range(0, 2)
		_dress_wall(hall_walls[2], _exit_looks)
		_show_treasure(true)
	# Seen from the next room only this door is behind the player (its cover must be gone
	# before the leaf swings through).
	_set_back(hall_walls[1], index)

func _wrong(index: int) -> void:
	# A door missed at its first try: one star miss (game_progress.gd).
	if _first_try:
		Board.shared().add_miss(ACTIVITY)
	_first_try = false
	var leaf: Node3D = _round_doors()[index].leaf
	leaf.rattle()
	_sound("mystery.door_locked", leaf)
	if host.line_id != "":
		host.close_dialogue()
	state = "toad"
	_toad_phase = "in"
	_timer = PUFF_SECONDS
	player.auto_walk.clear()
	player.velocity = Vector3.ZERO
	player.set_controls_enabled(false)
	_puff()

## The player walks through the open door themselves. Through the doorway, the card moves on at
## once; the door slams behind them as soon as its swing is clear of them ("shut").
func _walk_tick(_delta: float) -> void:
	var p: Vector3 = house.to_local(player.global_position)
	var past: float = float(Mystery.HALL_WALLS[1]) + Mystery.WALL
	if p.z < past + THROUGH_DEPTH:
		return
	if not _announced:
		_announced = true
		_announce_next()
	var leaf: Node3D = hall_walls[1][_through].leaf
	if not _clear_of_leaf(leaf, p):
		return
	leaf.slam()
	_sound("mystery.door_shut", leaf)
	state = "shut"
	_timer = 0.0

## Whether the slamming leaf cannot sweep through the player: they are (or, walking on, soon will
## be) farther from its hinge than the leaf is wide. House-local, on the floor plane.
func _clear_of_leaf(leaf: Node3D, p: Vector3) -> bool:
	var hinge: Vector3 = house.to_local(leaf.get_parent().global_position)
	var reach := Mystery.DOOR_W + LEAF_CLEARANCE
	var here := Vector2(p.x - hinge.x, p.z - hinge.z)
	if here.length() > reach:
		return true
	var v: Vector3 = (house.global_basis.inverse() * player.velocity) * LEAF_LEAD
	return (here + Vector2(v.x, v.z)).length() > reach

## Through the open door: the next round's clue (the doors ahead already show it), or after the
## last door the treasure line.
func _announce_next() -> void:
	if current + 1 >= rounds.size():
		card.praise(lexicon.line("mystery.treasure"), Board.shared().done(ACTIVITY), rounds.size(), lexicon.line("mystery.open_chest"))
		_say("mystery.treasure")
		return
	card.set_round(_title(current + 1), _clue_line(current + 1), Board.shared().done(ACTIVITY), rounds.size())

## The door has slammed behind the player in the second room: move them back one room (the
## same view), or after the last door fade back to Luna.
func _shut_tick(delta: float) -> void:
	if not hall_walls[1][_through].leaf.is_shut():
		return
	_timer += delta
	if _timer < SHUT_PAUSE:
		return
	if current + 1 >= rounds.size():
		state = "treasure"
		return
	# Wall A shows the door just shut, from behind; wall B what wall C showed.
	_dress_wall(hall_walls[0], rounds[current].doors)
	_set_back(hall_walls[0], _through)
	var shift: Vector3 = house.global_basis * Vector3(0, 0, -Mystery.HALL_STEP)
	player.global_position += shift
	player.camera_rig.global_position += shift
	player.reset_physics_interpolation()
	player.camera_rig.reset_physics_interpolation()
	_next_round()

## A game starts where the player is (user, 10 Nov 2026: "the game should immediately start on
## the same room as i am having the conversation"): the first round is played at the mystery
## room's doors. The hidden hall is readied (and shown, so nothing has to appear at the swap):
## wall B wears the room's door looks, wall A shows the middle door behind.
func _ready_hall(looks: Array) -> void:
	_reset_hall()
	_dress_wall(hall_walls[0], looks)
	_set_back(hall_walls[0], 1)
	_dress_wall(hall_walls[1], looks)
	_show_hall(true)
	_room_round = true
	dialogue_panel.set_compact(true)

## The right door of the first round (user approval, 10 Nov 2026: the swap as the door opens):
## in the same frame, before the door moves, the player and camera are moved from the mystery
## room's door wall to the same spot before the hall's wall B, which looks the same (step
## room_twin in mystery.gd dresses the hall rooms' door ends like the room's); wall B's door
## then opens instead, and the endless hall goes on from there.
func _swap_into_hall() -> void:
	_room_round = false
	# A door is used from at most INTERACT_DISTANCE away, well inside the first room; the clamp
	# only keeps the player inside the hall should that ever change.
	var p: Vector3 = house.to_local(player.global_position)
	var to_z := maxf(p.z + float(Mystery.HALL_WALLS[1]) - Mystery.DOOR_WALL, float(Mystery.HALL_WALLS[0]) + Mystery.WALL + 0.6)
	var shift: Vector3 = house.global_basis * Vector3(0, Mystery.ENDLESS_FLOOR - Mystery.FLOOR, to_z - p.z)
	player.global_position += shift
	player.camera_rig.global_position += shift
	player.reset_physics_interpolation()
	player.camera_rig.reset_physics_interpolation()
	_dress_wall(hall_walls[1], rounds[current].doors)

## Back in the mystery room after the last door (inside a fade): Luna gives the result.
func _back_to_luna() -> void:
	_show_hall(false)
	_reset_hall()
	zone.place_player(house, Mystery.START, Mystery.START_LOOK)
	_next_round()

# --- The treasure (user, 9 Nov 2026) -----------------------------------------------------------

## The animation's times (seconds from the click): the lid opens, the diamond shakes, surges up
## with a rainbow ray behind it and vanishes; then the line and the door out.
const LID_SECONDS := 0.5
const SHAKE_UNTIL := 1.9
const SURGE_UNTIL := 2.9
const RAY_UNTIL := 3.6
const LID_OPEN := 1.9
const SURGE_HEIGHT := 5.5

## E or a click on the chest (treasure_chest.gd).
func chest_used(_chest: Node3D) -> void:
	if state != "treasure" or zone.fading:
		return
	if host.line_id != "":
		host.close_dialogue()
	state = "diamond"
	_timer = 0.0
	_sound("mystery.chest_open", chest)

func _diamond_tick(delta: float) -> void:
	_timer += delta
	var t := _timer
	if _lid != null:
		_lid.rotation.x = LID_OPEN * smoothstep(0.0, LID_SECONDS, t)
	if _diamond == null:
		t = RAY_UNTIL
	elif t < SHAKE_UNTIL:
		# A few shakes, stronger toward the end.
		var shake := smoothstep(LID_SECONDS, SHAKE_UNTIL, t)
		_diamond.rotation.z = sin(t * 38.0) * 0.18 * shake
		_diamond.position = Vector3(sin(t * 51.0) * 0.03 * shake, 1.05 + 0.15 * smoothstep(LID_SECONDS, LID_SECONDS + 0.3, t), 0)
	elif t < SURGE_UNTIL:
		if _ray == null:
			_ray = _make_ray()
			_sound("mystery.diamond", chest)
		var k := (t - SHAKE_UNTIL) / (SURGE_UNTIL - SHAKE_UNTIL)
		_diamond.rotation = Vector3(0, k * TAU * 2.0, 0)
		_diamond.position = Vector3(0, 1.2 + SURGE_HEIGHT * k * k, 0)
		_diamond.scale = Vector3.ONE * (1.0 + 0.6 * sin(k * PI)) * (1.0 - smoothstep(0.75, 1.0, k))
	else:
		_diamond.visible = false
	if _ray != null:
		var r := clampf((t - SHAKE_UNTIL) / 0.35, 0.0, 1.0) * (1.0 - smoothstep(SURGE_UNTIL, RAY_UNTIL, t))
		_ray.scale = Vector3(maxf(r, 0.01), maxf(r, 0.01), 1.0)
		_ray.rotation.z = t * 0.6
		if _diamond != null and _diamond.visible:
			_ray.position.y = _diamond.position.y + 0.25
	if t < RAY_UNTIL:
		return
	if is_instance_valid(_ray):
		_ray.queue_free()
	_ray = null
	state = "exit"
	var door: Node3D = hall_walls[2][exit_door].leaf
	door.open()
	_sound("mystery.door_open", door)
	card.praise(lexicon.line("mystery.treasure_returned"), Board.shared().done(ACTIVITY), rounds.size(), lexicon.line("mystery.walk_through"))
	_say("mystery.treasure_returned")

## A fan of rainbow rays behind the diamond (facing the room's entrance, -z), built when it
## surges; unshaded and additive so it glows.
func _make_ray() -> Node3D:
	var ray := Node3D.new()
	ray.name = "Rainbow ray"
	chest.add_child(ray)
	ray.position = Vector3(0, 2.6, 0.15)
	var colors := [Color("ff4d4d"), Color("ff9f40"), Color("ffe14d"), Color("5fd16a"), Color("4da6ff"), Color("8a5cff"), Color("e05cff")]
	for i in 14:
		var beam := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(0.32, 7.0)
		quad.center_offset = Vector3(0, 3.5, 0)
		beam.mesh = quad
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		var c: Color = colors[i % colors.size()]
		m.albedo_color = Color(c, 0.55)
		beam.material_override = m
		beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		beam.rotation.z = TAU * i / 14.0
		ray.add_child(beam)
	# The beams fan out in the plane facing the player (the chest faces -z).
	return ray

## The door out is open: walking into the dark doorway behind it brings the player out of the
## matching mystery room door.
func _exit_tick(_delta: float) -> void:
	var p: Vector3 = house.to_local(player.global_position)
	if p.z > float(Mystery.HALL_WALLS[2]) + Mystery.WALL + 0.6 and p.y < Mystery.ENDLESS_FLOOR + 3.0 and not zone.fading:
		state = "fade"
		await zone.fade_through(_out_to_room)

func _out_to_room() -> void:
	_show_hall(false)
	_reset_hall()
	for i in doors.size():
		dress(i, _exit_looks[i][0], _exit_looks[i][1])
	var door: Node3D = doors[exit_door].leaf
	door.open_now()
	_room_door_close = 1.0
	zone.place_player(house, Vector3(Mystery.DOOR_X[exit_door], Mystery.FLOOR, Mystery.DOOR_WALL - 1.4), Vector3(0, 0, -1))
	state = "return"
	card.praise(lexicon.line("mystery.go_back"), Board.shared().done(ACTIVITY), rounds.size())

## Luna calls the player back (the gold "!") once they are out of the hall with her diamond.
func _host_calling() -> bool:
	return state == "return"

func _toad_tick(delta: float) -> void:
	_timer -= delta
	if _toad_phase == "toad" and _toad != null:
		_hop_tick(delta)
	elif player.controls_enabled:
		player.set_controls_enabled(false)
	if _toad_phase == "in" or _toad_phase == "out":
		_change_tick()
	if _timer > 0.0:
		return
	match _toad_phase:
		"in":
			become_toad(true)
			_toad.scale = Vector3.ONE
			_sound("mystery.croak", player)
			_toad_phase = "toad"
			_timer = TOAD_SECONDS
			# The toad can hop about (user, 9 Nov 2026).
			main.sync_player_controls()
		"toad":
			player.set_controls_enabled(false)
			player.velocity = Vector3.ZERO
			_puff()
			_toad_phase = "out"
			_timer = PUFF_SECONDS
		"out":
			become_toad(false)
			_toad_phase = ""
			state = "choose"
			main.sync_player_controls()
			_say("mystery.wrong", [], MESSAGE_SECONDS, {"clue": clue_ref(rounds[current])})
			card.highlight(_key_lines())
			# A toad that hopped out into the entrance hall is asked whether to leave.
			if not _in_room():
				ask_leave()

## A change over PUFF_SECONDS ("in": player to toad, "out": back): the old shape shrinks away in
## the first half, at the middle the models swap inside the smoke, the new one pops up in the second.
func _change_tick() -> void:
	var half := PUFF_SECONDS * 0.5
	var into := _toad_phase == "in"
	if _timer > half:
		var s := lerpf(0.08, 1.0, smoothstep(0.0, 1.0, (_timer - half) / half))
		if into:
			player.visual.scale = Vector3(s, s, s)
		elif _toad != null:
			_toad.scale = Vector3(s, s, s)
		return
	if into != (_toad != null):
		become_toad(into)
	var grow := clampf(1.0 - _timer / half, 0.0, 1.0)
	var g := lerpf(0.08, 1.0, grow) * (1.0 + 0.15 * sin(PI * grow))
	if into:
		_toad.scale = Vector3(g, g, g)
	else:
		player.visual.scale = Vector3(g, g, g)

## The toad moves in hops: while a direction is held it hops on and on (fast in the air, still
## on landing); let go and it finishes the hop and sits.
func _hop_tick(delta: float) -> void:
	var moving: bool = player.controls_enabled and player.movement_direction().length_squared() > 0.001
	if _hop > 0.0 or moving:
		if _hop == 0.0:
			_sound("mystery.hop", player)
		_hop += delta / HOP_SECONDS
		if _hop >= 1.0:
			_hop = _hop - 1.0 if moving else 0.0
			if _hop > 0.0:
				_sound("mystery.hop", player)
	var air := _hop > 0.0 and _hop < HOP_AIR
	player.speed_override = HOP_SPEED if air else 0.0
	var floor_y: float = _toad.get_meta("floor", 0.0)
	if air:
		var t := _hop / HOP_AIR
		_toad.position.y = floor_y + sin(PI * t) * HOP_HEIGHT
		_toad.scale = Vector3(0.94, 1.1, 0.94).lerp(Vector3.ONE, t)
	else:
		# Landing: a squash that eases back.
		var t := 1.0 if _hop == 0.0 else (_hop - HOP_AIR) / (1.0 - HOP_AIR)
		_toad.position.y = floor_y
		_toad.scale = Vector3(1.1, 0.84, 1.1).lerp(Vector3.ONE, t)

## Swaps the player's model for the toad (on) and back (off).
func become_toad(on: bool) -> void:
	if on:
		if _toad == null:
			# Measured at full size (the change shrinks the player first).
			player.visual.scale = Vector3.ONE
			var size := _model_size()
			_toad = ToadModel.build(maxf(size.y * TOAD_SHARE, 0.35))
			_toad.set_meta("floor", size.x)
			player.add_child(_toad)
			_toad.position = Vector3(0, size.x, 0)
		player.visual.visible = false
		# Sitting still until the first hop (_hop_tick).
		player.speed_override = 0.0
	else:
		if is_instance_valid(_toad):
			_toad.queue_free()
		_toad = null
		_hop = 0.0
		player.speed_override = -1.0
		player.visual.scale = Vector3.ONE
		player.visual.visible = true

func is_toad() -> bool:
	return _toad != null

## The player's model in the player's own space: (lowest y, height).
func _model_size() -> Vector2:
	var inverse: Transform3D = player.global_transform.affine_inverse()
	var bounds := AABB()
	var first := true
	for mesh in player.visual.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null or not mesh.is_visible_in_tree():
			continue
		var box: AABB = inverse * mesh.global_transform * mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	return Vector2(bounds.position.y, bounds.size.y) if not first else Vector2(0.0, 1.2)

## A one-shot cloud of smoke around the player (the change to a toad and back).
func _puff() -> void:
	_sound("mystery.puff", player)
	var puff := CPUParticles3D.new()
	puff.name = "Toad puff"
	puff.one_shot = true
	puff.explosiveness = 0.9
	puff.amount = 28
	# Lasts past the swap in the middle of the change (PUFF_SECONDS).
	puff.lifetime = 1.2
	puff.local_coords = false
	puff.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	puff.emission_sphere_radius = 0.4
	puff.direction = Vector3.UP
	puff.spread = 180.0
	puff.gravity = Vector3(0, 0.5, 0)
	puff.initial_velocity_min = 0.6
	puff.initial_velocity_max = 1.6
	puff.damping_min = 2.0
	puff.damping_max = 3.0
	puff.scale_amount_min = 0.14
	puff.scale_amount_max = 0.3
	var ball := SphereMesh.new()
	ball.radius = 1.0
	ball.height = 2.0
	ball.radial_segments = 8
	ball.rings = 4
	var smoke := StandardMaterial3D.new()
	smoke.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smoke.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke.vertex_color_use_as_albedo = true
	ball.material = smoke
	puff.mesh = ball
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(1, 1, 1, 0.95), Color("e3d4ff"), Color(0.85, 0.78, 1.0, 0.0)])
	fade.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	puff.color_ramp = fade
	puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(puff)
	puff.global_position = player.global_position + Vector3(0, 0.5, 0)
	puff.emitting = true
	puff.finished.connect(puff.queue_free)

## Plays a cue once data/sounds.json has it (sound-ready; no Mystery House sounds yet).
func _sound(cue: String, at: Node3D) -> void:
	var sound = Sound.shared()
	if sound != null and sound.cues.has(cue):
		sound.play_at(cue, at)

# --- The game -----------------------------------------------------------------------------

func start_game() -> void:
	if in_game() or zone.fading or doors.is_empty():
		return
	_play()
	_say("mystery.intro")

## A game (Yes or Play again) starts in place, no fade (user, 10 Nov 2026): the first round is
## played at the mystery room's doors as they look now; the hall waits below (_ready_hall).
func _play() -> void:
	var looks := room_looks()
	_ready_hall(looks)
	state = "over"
	_begin_rounds(looks)

func _begin_rounds(first: Array = []) -> void:
	var settings: Dictionary = preload("res://scripts/learning/game_progress.gd").shared().params(ACTIVITY)
	Board.shared().begin(ACTIVITY, int(settings.get("doors", 0)))
	_first_right = -1
	rounds = make_rounds(Board.shared().rounds(ACTIVITY), _rng, first, settings.get("kinds", []), settings.get("colors", []))
	current = -1
	card.show_native = dialogue_panel.show_native
	card.open(_title(), lexicon.line("mystery.card_hint"), lexicon.line("common.show_translation"), 0, rounds.size())
	_next_round()

func _title(index := -1) -> Dictionary:
	var shown := current if index < 0 else index
	return lexicon.line("mystery.round_title", {"n": clampi(shown + 1, 1, maxi(rounds.size(), 1)), "total": rounds.size()})

func _next_round() -> void:
	current += 1
	if current >= rounds.size():
		_finish_rounds()
		return
	var round_data: Dictionary = rounds[current]
	_dress_wall(_round_doors(), round_data.doors)
	_through = -1
	_first_try = true
	PracticeLog.shared().begin(ACTIVITY, tested_words(round_data))
	state = "choose"
	if not zone.fading:
		main.sync_player_controls()
	card.set_round(_title(), _clue_line(), Board.shared().done(ACTIVITY), rounds.size())

func _finish_rounds() -> void:
	state = "over"
	card.hide_card()
	_first_right = Board.shared().done(ACTIVITY)
	# Every door played: the session is complete, also with misses (stars, missions, results;
	# LEARN-06, 25 Nov 2026: before this only a game with every door right at the first try was).
	Board.shared().complete(ACTIVITY)
	_offer_again()

func _offer_again() -> void:
	host.zoom(true)
	_say("mystery.final", [host.choice("replay", "mystery.replay", "retry"), host.choice("finish", "mystery.finish", "check")], 0.0, {"total": rounds.size(), "first": _first_right if _first_right >= 0 else Board.shared().done(ACTIVITY)})

func end_game(farewell: String, to_luna := false) -> void:
	if not in_game():
		return
	host.cancel_leave()
	state = ""
	# The card first: nothing below may leave the strip on screen after the game.
	card.hide_card()
	_room_round = false
	_toad_phase = ""
	_through = -1
	become_toad(false)
	player.auto_walk.clear()
	host.abandon_practice()
	dialogue_panel.set_compact(false)
	rounds = []
	current = -1
	card.hide_card()
	offered = false
	if to_luna:
		# Left mid-game (user, 10 Nov 2026): from the hall or the room, across the fortune table
		# from Luna, who says goodbye once the player is there.
		if zone.fading:
			_leave_to_luna(farewell)
		else:
			zone.fade_through(_leave_to_luna.bind(farewell))
		farewell = ""
	elif _in_hall():
		# Out of the endless hall, back to the mystery room.
		if zone.fading:
			_leave_hall()
		else:
			zone.fade_through(_leave_hall)
	else:
		_reset_hall()
		_show_hall(false)
	if not zone.fading:
		main.sync_player_controls()
	if farewell != "":
		_say(farewell)

func _leave_hall() -> void:
	_reset_hall()
	_show_hall(false)
	zone.place_player(house, Mystery.START, Mystery.START_LOOK)

func _leave_to_luna(line: String) -> void:
	_reset_hall()
	_show_hall(false)
	zone.place_player(house, Mystery.GUEST_SPOT, Mystery.GUEST_LOOK)
	if line != "":
		_say(line)

## A language change (Main): the game ends at once.
func end_activity() -> void:
	if host == null:
		return
	if host.line_id != "":
		host.close_dialogue()
	end_game("")
	host.refresh_name()

# --- Leaving ------------------------------------------------------------------------------

func ask_leave() -> void:
	if not in_game() or zone.fading or host.is_asking_leave():
		return
	if state == "over" or state == "return":
		# Won: no question, only the self-closing goodbye. In "return" the result line is
		# skipped (the card already showed the score).
		end_game("mystery.finished")
		return
	# A toad may leave too (user, 10 Nov 2026); end_game turns it back first.
	if not state in ["choose", "walk", "toad", "treasure", "exit"]:
		return
	_paused_from = state
	state = "paused"
	player.set_controls_enabled(false)
	host.ask_leave()

## Esc / back with no popup open (Main, the request_leave() contract, docs/guides/MINIGAMES.md;
## 25 Nov 2026): ask_leave() as the card's Leave and the doorway do (nothing during a fade or a
## door's change). True while a game runs, so Settings does not open mid-game.
func request_leave() -> bool:
	if host == null or not in_game():
		return false
	ask_leave()
	return true

func _on_leave_answered(leave: bool) -> void:
	if state != "paused":
		return
	if arch != null:
		arch.asked = false
	if leave:
		state = _paused_from
		end_game("mystery.sorry_leave", true)
		return
	if not _in_hall() and (_doorway.overlaps_body(player) or not _in_mystery_room()):
		zone.place_player(house, Mystery.INSIDE, Mystery.START_LOOK)
	state = _paused_from
	main.sync_player_controls()

# --- Each frame ---------------------------------------------------------------------------

## The fail-safes above (FALL_DEPTH, OUTSIDE_GRACE). A fall is caught long before Main's respawn
## (about half a second of falling): the player lands back in the hall room they fell from (or,
## from the mystery room, at INSIDE) and the game goes on.
func _guard_place(delta: float) -> void:
	var p: Vector3 = house.to_local(player.global_position)
	if p.y < Mystery.ENDLESS_FLOOR - FALL_DEPTH and absf(p.x) < Mystery.W2 + 8.0 and p.z > Mystery.FRONT - 8.0 and p.z < Mystery.REAR + 8.0:
		push_warning("mystery_session: the player fell out of the hall at %s (state %s); put back" % [p, state])
		if _room_round or hall == null or not hall.visible:
			zone.place_player(house, Mystery.INSIDE, Mystery.START_LOOK)
		else:
			# The room between walls A and B, or (through wall B's door) between B and C.
			var first: Vector2 = Vector2(float(Mystery.HALL_WALLS[0]) + Mystery.WALL, float(Mystery.HALL_WALLS[1])) if p.z < float(Mystery.HALL_WALLS[1]) + Mystery.WALL else Vector2(float(Mystery.HALL_WALLS[1]) + Mystery.WALL, float(Mystery.HALL_WALLS[2]))
			var spot := Vector3(clampf(p.x, -Mystery.W2 + 1.5, Mystery.W2 - 1.5), Mystery.ENDLESS_FLOOR, clampf(p.z, first.x + 1.5, first.y - 1.5))
			zone.place_player(house, spot, Mystery.START_LOOK)
		player.reset_physics_interpolation()
		player.camera_rig.reset_physics_interpolation()
		return
	if _in_house():
		_outside_time = 0.0
		return
	_outside_time += delta
	if _outside_time < OUTSIDE_GRACE:
		return
	_outside_time = 0.0
	push_warning("mystery_session: the player left the house mid-game (state %s); game ended" % state)
	if host.line_id != "":
		host.close_dialogue()
	end_game("")

func _process(delta: float) -> void:
	if host == null or not is_instance_valid(player):
		return
	# A new look for the mystery room's doors each time the player leaves the house (user,
	# 9 Nov 2026); the next game's first round uses it.
	var inside := _in_house()
	if _was_inside and not inside and not in_game():
		randomize_room_doors()
	_was_inside = inside
	if _room_door_close > 0.0:
		_room_door_close -= delta
		if _room_door_close <= 0.0 and exit_door >= 0:
			doors[exit_door].leaf.close()
	if in_game() and not zone.fading:
		_guard_place(delta)
	match state:
		"walk":
			_walk_tick(delta)
		"shut":
			_shut_tick(delta)
		"diamond":
			_diamond_tick(delta)
		"exit":
			_exit_tick(delta)
		"toad":
			_toad_tick(delta)
	host.tick(delta)
