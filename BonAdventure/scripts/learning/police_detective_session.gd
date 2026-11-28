extends Node
## The police station's two detective minigames (6 Nov 2026; design and user decisions:
## docs/evidence/police-detective-20261106/PROMPT.md). One script, two instances made by main.gd:
##   mode "lineup":   Officer Rocco (People/CrocodilePoliceOfficer, in the lobby in front of
##                    the lineup room), "Identificar al sospechoso", activity "lineup_rocco";
##   mode "evidence": Officer Mimi (People/CatEvidenceOfficer, behind the evidence counter),
##                    "Examinar las pruebas", activity "evidence_mimi".
## The officer shows the gold "!" while the player is near and greets them in the SHARED
## dialogue box (shop_order_panel.gd). Accepting locks the player (main.gd
## sync_player_controls(): the card is open), eases a fixed camera to the room's anchor
## (LineupCamera / EvidenceCamera, saved in the police unit) and builds the round: five bear
## suspects on the lineup spots (suspect_builder.gd) or four objects on the examination table
## (evidence_props.gd), all generated and checked by detective_clues.gd.
##
## The card (detective_card.gd) shows "Round n of 4", the 2-clue description, feedback and
## the buttons. Clicking a suspect (or keys 1-5) is the accusation: no second click on the card
## (user decision, 8 Nov 2026; the card has no "¡Es este!" button any more). In the
## lineup a wrong guess names the clue that does not fit (detective_clues.failing_clue()).
## EVIDENCE GAME (redesigned 8 Nov 2026, docs/guides/MINIGAMES.md): ONE property word decides each
## round, and the rounds alternate (data "evidence.rounds"):
##   find:   four objects, "¿Qué objeto es blando?"; a click on an object (or keys 1-4) is the
##           answer; a wrong one is told what it really is ("No, la piedra es dura.");
##   report: one object, "¿Es la piedra dura o blanda?"; two answer buttons (or keys 1-2); a
##           wrong answer makes the game use the right tool on the object by itself.
## The tools (keys Z X C) each reveal one property pair on EVERY object at once, one after
## another: Apretar (squeeze: soft objects squash, hard ones clink) -> hard / soft; Tocar
## (touch: a rub) -> rough / smooth; Levantar (lift: light objects fly up, heavy ones barely
## rise and tremble) -> heavy / light. A result icon stays over each object (no words) until
## another tool is used. The solved line names the object, agreeing with its noun in each
## language ("Mira: la piedra es dura." with police.e_hard_f). Each round is one practice
## question (practice_log.gd) on its one word, first answer counts.
## A round counts once solved, however many tries it took; the end-of-game list shows each
## round's object and word, marking rounds solved at the first answer. Suspects breathe,
## blink and lean toward the pointer; the hovered spot lights up.
## After Finish the officer offers another game (Yes / No). Leaving early (card exit button, Esc) asks first; a language change ends the game at once.
## No rewards yet (user decision). Every text comes from data/phrases.json group "police".
const Board := preload("res://scripts/learning/activity_board.gd")
const Host := preload("res://scripts/learning/minigame_host.gd")
const Clues := preload("res://scripts/learning/detective_clues.gd")
const SuspectBuilder := preload("res://scripts/learning/suspect_builder.gd")
const PlushLife := preload("res://scripts/characters/plush_life.gd")
## The lineup blinks a little more often than the town (as since 6 Nov 2026).
const LINEUP_BLINK_GAP := Vector2(2.5, 6.0)
const EvidenceProps := preload("res://scripts/learning/evidence_props.gd")
const Progress := preload("res://scripts/learning/game_progress.gd")
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
## Path inside the police unit (ModularTown.building()) where the case anchors live.
const STATION := "Interior/"
const CALL_DISTANCE := 12.0
const WALK_AWAY_DISTANCE := 8.0
const MESSAGE_SECONDS := 9.0
const CAMERA_SECONDS := 0.8
## Vertical field of view of the game camera.
const FOV := 54.0
## Seconds between the objects when a tool examines the whole table.
const TOOL_STAGGER := .32
## Size of the one object of a report round, against the table's four.
const REPORT_SCALE := 1.5
const MODES := {
	"lineup": {"officer": "People/CrocodilePoliceOfficer", "activity": "lineup_rocco", "name": "police.rocco", "greeting": "police.lineup_greeting", "hint": "police.lineup_hint", "camera": "LineupCamera", "stage": "LineupStage", "two": "police.lineup_two", "three": "police.lineup_three", "one": "police.lineup_one", "correct": "police.correct_suspect", "choose_first": "police.choose_first_suspect", "complete": "police.lineup_complete"},
	"evidence": {"officer": "People/CatEvidenceOfficer", "activity": "evidence_mimi", "name": "police.mimi", "greeting": "police.evidence_greeting", "hint": "police.evidence_hint", "camera": "EvidenceCamera", "stage": "EvidenceTable", "correct": "police.correct_found", "complete": "police.evidence_complete"},
}
## The evidence tools; each reveals the property pair data "evidence.dims" gives it.
const TOOLS := [
	{"id": "squeeze", "phrase": "police.tool_squeeze", "icon": "squeeze", "key": KEY_Z},
	{"id": "touch", "phrase": "police.tool_touch", "icon": "touch", "key": KEY_X},
	{"id": "lift", "phrase": "police.tool_lift", "icon": "lift", "key": KEY_C},
]

var mode := "lineup"
var spec: Dictionary = {}
var lexicon
var dialogue_panel
var card
var interaction
var player: Node3D
var world: Node3D
var officer: Node3D
## The shared NPC host (minigame_host.gd): the officer, the "!", talking (the two officers
## share the dialogue box: the host owns it by the line on screen), the leave question.
var host
var presence:
	get: return host.presence if host != null else null
## Whether the officer offers the game now (rolled on approach; kept on the host).
var offered: bool:
	get: return host.offered if host != null else false
	set(value):
		if host != null:
			host.offered = value
var _rng := RandomNumberGenerator.new()
var _running := false
var clues

## The running round.
var round: Dictionary = {}
var _nodes: Array = []
var _selected := -1
var _hovered := -1
var _solved := false
var _finished := false
var _tool := ""
## Evidence: whether the round's first answer was right, and whether one was given yet.
var _first_try := true
## The current round went wrong at least once (one star miss per round, game_progress.gd).
var _round_missed := false
var _answered := false
## Counts tool presses and rounds, so a delayed tool step from an earlier press or round
## does nothing.
var _tool_serial := 0
var _select_ring: MeshInstance3D
var _hover_ring: MeshInstance3D
var _camera: Camera3D
var _previous_camera: Camera3D
var _camera_tween: Tween
## One entry per solved round: {"number", "object" (word key, evidence), "words": [keys],
## "first_try" (evidence)}.
var _history: Array = []
var _summary := false
var _idle_time := 0.0
## Blinks the lineup's suspects (plush_life.gd owns every plush's eyes).
var _life: Node

func setup(game_mode: String, shared_lexicon, shared_dialogue_panel, detective_card, interaction_controller, explorer: Node3D, town: Node3D) -> void:
	mode = game_mode
	spec = MODES[mode]
	name = "PoliceDetective_" + mode
	lexicon = shared_lexicon
	dialogue_panel = shared_dialogue_panel
	card = detective_card
	interaction = interaction_controller
	player = explorer
	world = town
	_rng.randomize()
	officer = town.get_node_or_null(str(spec.officer)) as Node3D
	if officer == null or _anchor(str(spec.stage)) == null:
		# Dev focus without the police station, or the station is missing.
		officer = null
		return
	clues = Clues.new()
	host = Host.new()
	add_child(host)
	host.setup(self, {"activity": str(spec.activity), "group": "police", "speaker": str(spec.name), "greeting": str(spec.greeting), "choice_prefix": "police_%s_" % mode, "call_distance": CALL_DISTANCE, "walk_away": WALK_AWAY_DISTANCE, "message_seconds": MESSAGE_SECONDS}, lexicon, dialogue_panel, interaction, player, officer)
	host.play_chosen.connect(start_game)
	host.leave_answered.connect(_on_leave_answered)
	card.leave_requested.connect(_on_card_leave)
	card.tool_pressed.connect(_on_tool)
	card.accuse_pressed.connect(accuse)
	if mode == "evidence":
		card.choice_pressed.connect(answer)
	card.next_pressed.connect(next_round)

func activity_running() -> bool:
	return _running

func busy() -> bool:
	return _running or (host != null and host.owns_dialogue())

func _anchor(title: String) -> Node3D:
	return preload("res://scripts/world/modular_town.gd").building(world, "police", 0, STATION + title)

# --- Dialogue box -----------------------------------------------------------------------

func _say(id: String) -> void:
	host.say(id)

# --- Starting and ending ------------------------------------------------------------------

func start_game() -> void:
	if _running:
		return
	_running = true
	# Levels (LEARN-06, 25 Nov 2026; docs/game/minigames.md#spot-the-suspect, #feel-the-clues).
	clues.set_level(Progress.shared().params(str(spec.activity)))
	Board.shared().begin(str(spec.activity))
	clues.reset()
	_finished = false
	_summary = false
	_history.clear()
	card.show_native = dialogue_panel.show_native
	_camera_to(_anchor(str(spec.camera)).global_transform)
	new_round()
	card.set_feedback(lexicon.line(str(spec.hint)), true)

func end_game(farewell: String) -> void:
	if not _running:
		return
	_running = false
	host.cancel_leave()
	host.abandon_practice()
	_summary = false
	card.hide_card()
	_clear_round()
	_camera_back()
	offered = false
	if farewell == str(spec.complete):
		# A finished game: well done, and another case? (user decision, 8 Nov 2026).
		host.zoom(false)
		host.offer(farewell)
	elif farewell != "":
		host.zoom(false)
		_say(farewell)

## A language change in Settings ends the game at once with the officer's goodbye.
func end_activity() -> void:
	if host == null:
		return
	host.cancel_leave()
	host.refresh_name()
	if _running:
		end_game("police.goodbye")

func _on_card_leave() -> void:
	if not _running:
		return
	if _summary:
		end_game(str(spec.complete))
		return
	host.ask_leave()

func _on_leave_answered(leave: bool) -> void:
	if leave:
		end_game("police.left_early")

# --- Rounds -----------------------------------------------------------------------------------

func new_round() -> void:
	_clear_round()
	var done_before: int = Board.shared().done(str(spec.activity))
	round = clues.generate_lineup(_rng) if mode == "lineup" else clues.generate_evidence(_rng, clues.round_type(done_before))
	if round.is_empty():
		end_game("police.goodbye")
		return
	_solved = false
	_selected = -1
	_hovered = -1
	_tool = ""
	_tool_serial += 1
	_first_try = true
	_answered = false
	_round_missed = false
	if mode == "lineup":
		_build_lineup()
	else:
		_build_table()
	_select_ring = _ring(Color("f2c230"), 1.0)
	_hover_ring = _spot_light() if mode == "lineup" else _ring(Color(1, 1, 1, .55), .92)
	var total: int = Board.shared().target(str(spec.activity))
	var done: int = Board.shared().done(str(spec.activity))
	var tools: Array = []
	if mode == "evidence":
		for tool in TOOLS:
			tools.append({"id": tool.id, "label": lexicon.line(str(tool.phrase)), "icon": tool.icon})
	card.open(lexicon.line("police.round_title", {"n": done + 1, "total": total}), _clue_line(), lexicon.line("common.show_translation"), done, total, tools, {})
	card.set_tool(_tool if mode == "evidence" else "")
	if mode == "evidence":
		if round.has("options"):
			var word := _target_word()
			var answers: Array = []
			for option in round.options:
				var adjective := str(option.adjective)
				answers.append(_each_language(func(lang: String) -> Dictionary: return {"phrase": _agreed(adjective, word, lang)}))
			card.set_choices(answers)
		# One practice question on the round's one word (practice_log.gd).
		PracticeLog.shared().begin(str(spec.activity), Clues.words_of(round.clues))

## The officer's line: "El sospechoso es alto y tiene barba." (lineup), "¿Qué objeto es
## blando?" (evidence find) or "¿Es la piedra dura o blanda?" (evidence report).
func _clue_line() -> Dictionary:
	var parts: Array = round.clues
	if mode == "evidence":
		if round.has("options"):
			var word := _target_word()
			return _each_language(func(lang: String) -> Dictionary: return {"phrase": "police.report", "values": {"object": {"word": word}, "a": {"phrase": _agreed(str(round.options[0].adjective), word, lang)}, "b": {"phrase": _agreed(str(round.options[1].adjective), word, lang)}}})
		return lexicon.line("police.find", {"a": {"phrase": parts[0].phrase}})
	var ref: Dictionary
	if parts.size() >= 3:
		ref = {"phrase": spec.three, "values": {"a": {"phrase": parts[0].phrase}, "b": {"phrase": parts[1].phrase}, "c": {"phrase": parts[2].phrase}}}
	elif parts.size() >= 2:
		ref = {"phrase": spec.two, "values": {"a": {"phrase": parts[0].phrase}, "b": {"phrase": parts[1].phrase}}}
	else:
		ref = {"phrase": spec.one, "values": {"a": {"phrase": parts[0].phrase}}}
	return {"foreign": lexicon.text(ref, lexicon.foreign), "native": lexicon.text(ref, lexicon.native)}

## A line built per language by `make` (lang -> text reference): {"foreign", "native"}.
func _each_language(make: Callable) -> Dictionary:
	return {"foreign": lexicon.text(make.call(lexicon.foreign), lexicon.foreign), "native": lexicon.text(make.call(lexicon.native), lexicon.native)}

## The phrase `id`, or its feminine variant (`id` + "_f", when the phrase data has one) when
## `word`'s noun is feminine in `lang` (words.json forms "gender"): "es duro" / "es dura".
func _agreed(id: String, word: String, lang: String) -> String:
	var gender := str(lexicon.word_entry(word, lang).forms.get("gender", ""))
	return id + "_f" if gender == "f" and lexicon.phrases.has(id + "_f") else id

## The word key of the round's answer object.
func _target_word() -> String:
	return str(round.candidates[int(round.target)].get("word", ""))

## "Mira: la piedra es dura." / "No, la piedra es dura.": `line_id` with an object and the
## clue fragment of its value on `dim`, agreeing in each language.
func _object_line(line_id: String, item: Dictionary, dim: String) -> Dictionary:
	var word := str(item.get("word", ""))
	var clue := {}
	for c in clues.data.get("evidence", {}).get("clues", []):
		if str(c.dim) == dim and str(c.value) == str(item.get(dim, "")):
			clue = c
	return _each_language(func(lang: String) -> Dictionary: return {"phrase": line_id, "values": {"object": {"word": word}, "clue": {"phrase": _agreed(str(clue.get("phrase", "")), word, lang)}}})

func _build_lineup() -> void:
	var stage := _anchor(str(spec.stage))
	var pitch: float = float(stage.get_meta("pitch", 1.38))
	var looks: Dictionary = clues.data.get("lineup", {}).get("looks", {})
	var facing: Vector3 = stage.global_basis * Vector3(0, 0, -1)
	var count: int = round.candidates.size()
	for i in count:
		# Suspect 1 stands on spot 1, on the viewer's left (station high x).
		var spot: Vector3 = stage.to_global(Vector3(-(i - (count - 1) / 2.0) * pitch, 0, 0))
		_nodes.append(SuspectBuilder.build(round.candidates[i], looks, stage, spot, facing, i))
	if _life == null:
		_life = PlushLife.new()
		_life.blink_gap = LINEUP_BLINK_GAP
		_life.gestures = false
		add_child(_life)
		_life.setup(_nodes, _rng)
	else:
		_life.set_figures(_nodes)

func _build_table() -> void:
	var table := _anchor(str(spec.stage))
	var length: float = float(table.get_meta("length", 2.5))
	var count: int = round.candidates.size()
	for i in count:
		var item: Dictionary = round.candidates[i]
		var node: Node3D = EvidenceProps.build(str(item.kind), item)
		node.name = "Evidence%d" % (i + 1)
		table.add_child(node)
		# Spread along the table (local z), long side across the view (8 Nov 2026: the objects
		# are at most about .5 long, so they fit side by side). A report round's one object
		# stands, larger, in the middle.
		node.position = Vector3(0, 0, -length / 2 + (i + .5) * length / count)
		if count == 1:
			node.scale = Vector3.ONE * REPORT_SCALE
		node.set_meta("detective_index", i)
		var extent: Vector3 = node.get_meta("evidence_size", Vector3.ONE * .2)
		var area := Area3D.new()
		area.name = "EvidencePick"
		area.set_meta("detective_index", i)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(maxf(extent.x * 2.0, .3), maxf(extent.y * 2.0, .25), maxf(extent.z * 2.0, .3))
		shape.shape = box
		shape.position = Vector3(0, box.size.y / 2, 0)
		area.add_child(shape)
		node.add_child(area)
		_nodes.append(node)

func _clear_round() -> void:
	if _life != null:
		_life.set_figures([])
	for node in _nodes:
		if is_instance_valid(node):
			node.queue_free()
	_nodes.clear()
	for ring in [_select_ring, _hover_ring]:
		if is_instance_valid(ring):
			ring.queue_free()
	_select_ring = null
	_hover_ring = null
	round = {}

## A flat ring that marks the selected (gold) or hovered (white) candidate.
func _ring(color: Color, size: float) -> MeshInstance3D:
	var ring := MeshInstance3D.new()
	ring.name = "DetectiveRing"
	var torus := TorusMesh.new()
	torus.inner_radius = .78 * size
	torus.outer_radius = 1.0 * size
	torus.rings = 32
	torus.ring_segments = 8
	ring.mesh = torus
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = material
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.visible = false
	_anchor(str(spec.stage)).add_child(ring)
	return ring

## The lineup's hover mark: the floor square under the suspect lights up (a bright square a
## little larger than the painted spot).
func _spot_light() -> MeshInstance3D:
	var plate := MeshInstance3D.new()
	plate.name = "DetectiveSpotLight"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(2.0, 2.0)
	plate.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, .93, .55, .55)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# The station interior is mirrored, which turns the plane's face away: draw both sides.
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	plate.material_override = material
	plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	plate.visible = false
	_anchor(str(spec.stage)).add_child(plate)
	return plate

## Puts `ring` under candidate `index` (hidden for -1).
func _mark(ring: MeshInstance3D, index: int) -> void:
	if not is_instance_valid(ring):
		return
	ring.visible = index >= 0 and index < _nodes.size()
	if not ring.visible:
		return
	var stage := _anchor(str(spec.stage))
	var node: Node3D = _nodes[index]
	var at: Vector3 = stage.to_local(node.global_position)
	var radius := .5
	if mode == "evidence":
		var extent: Vector3 = node.get_meta("evidence_size", Vector3.ONE * .2) * node.scale.x
		radius = maxf(maxf(extent.x, extent.z), .14) + .06
	ring.position = Vector3(at.x, .03 if ring.name == "DetectiveSpotLight" else .012, at.z)
	ring.scale = Vector3(radius, 1.0, radius)

# --- Choosing and accusing -----------------------------------------------------------------

func select(index: int) -> void:
	if _solved or index < 0 or index >= _nodes.size():
		return
	_selected = index
	_mark(_select_ring, index)
	card.set_feedback({}, true)
	_hop(_nodes[index])

## A click on a suspect or on an object (evidence find rounds) is the answer itself.
func choose(index: int) -> void:
	if _solved or index < 0 or index >= _nodes.size():
		return
	if mode == "evidence" and round.has("options"):
		# A report round is answered with the buttons; a click just nudges the object.
		_hop(_nodes[index])
		return
	select(index)
	accuse()

func accuse() -> void:
	if not _running or _solved:
		return
	if _selected < 0:
		if spec.has("choose_first"):
			card.set_feedback(lexicon.line(str(spec.choose_first)), false)
		return
	if mode == "evidence":
		_answer_object(_selected)
		return
	var candidate: Dictionary = round.candidates[_selected]
	var failing: Dictionary = Clues.failing_clue(candidate, round.clues)
	if failing.is_empty() and _selected == int(round.target):
		_solved = true
		_remember_round()
		_finished = Board.shared().add_success(str(spec.activity))
		card.set_feedback(lexicon.line(str(spec.correct)), true)
		var total: int = Board.shared().target(str(spec.activity))
		card.set_solved(lexicon.line("police.finish" if _finished else "police.next"), Board.shared().done(str(spec.activity)), total)
		_celebrate(_nodes[_selected])
		return
	_count_miss()
	card.set_feedback(lexicon.line("police.wrong", {"clue": {"phrase": failing.get("phrase", round.clues[0].phrase)}}), false)
	_shake(_nodes[_selected])
	_selected = -1
	_mark(_select_ring, -1)

## Evidence find round: object `index` is the answer.
func _answer_object(index: int) -> void:
	var item: Dictionary = round.candidates[index]
	var clue: Dictionary = round.clues[0]
	var right := index == int(round.target)
	_first_answer(right)
	if right:
		_solve(index, _object_line(str(spec.correct), item, str(clue.dim)))
		return
	_count_miss()
	card.set_feedback(_object_line("police.wrong_found", item, str(clue.dim)), false)
	_shake(_nodes[index])
	_selected = -1
	_mark(_select_ring, -1)

## Evidence report round: answer button `index` (round "options").
func answer(index: int) -> void:
	if not _running or _solved or mode != "evidence" or not round.has("options") or index < 0 or index >= round.options.size():
		return
	var option: Dictionary = round.options[index]
	var clue: Dictionary = round.clues[0]
	var right := str(option.id) == str(clue.id)
	_first_answer(right)
	if right:
		_solve(int(round.target), _object_line(str(spec.correct), round.candidates[int(round.target)], str(clue.dim)))
		return
	# Show what the right tool finds on this object, so the word meets the feeling.
	var tool := str(clue.get("tool", ""))
	_count_miss()
	card.set_feedback(lexicon.line("police.wrong_report", {"tool": {"phrase": "police.tool_" + tool}}), false)
	_shake(_nodes[int(round.target)])
	get_tree().create_timer(.45).timeout.connect(func() -> void:
		# P3-09: the session may have left the tree before the timer fires.
		if _running and not _solved and is_inside_tree():
			_on_tool(tool))

## A wrong answer: the round's one star miss (activity_board.gd add_miss(), the first time).
func _count_miss() -> void:
	if not _round_missed:
		_round_missed = true
		Board.shared().add_miss(str(spec.activity))

## The first answer of an evidence round is the practice result (practice_log.gd).
func _first_answer(right: bool) -> void:
	if _answered:
		return
	_answered = true
	_first_try = right
	if PracticeLog.shared().game_id() == str(spec.activity):
		PracticeLog.shared().first_answer(right)

## An evidence round is solved: feedback `line`, the progress step, the object celebrates.
func _solve(index: int, line: Dictionary) -> void:
	_solved = true
	select(index)
	if PracticeLog.shared().game_id() == str(spec.activity):
		PracticeLog.shared().complete()
	_remember_round()
	_finished = Board.shared().add_success(str(spec.activity))
	card.set_feedback(line, true)
	var total: int = Board.shared().target(str(spec.activity))
	card.set_solved(lexicon.line("police.finish" if _finished else "police.next"), Board.shared().done(str(spec.activity)), total)
	_celebrate(_nodes[index])

func next_round() -> void:
	if not _running or not _solved:
		return
	if _summary:
		end_game(str(spec.complete))
	elif _finished:
		_show_summary()
	else:
		new_round()

# --- The end-of-game word list ----------------------------------------------------------------

func _remember_round() -> void:
	var words: Array = []
	for clue in round.clues:
		for key in clue.get("words", []):
			if not words.has(key):
				words.append(key)
	var entry := {"number": int(round.target) + 1, "words": words}
	if mode == "evidence":
		entry["object"] = _target_word()
		entry["adjective"] = str(round.clues[0].get("adjective", ""))
		entry["first_try"] = _first_try
	_history.append(entry)

## "Sospechoso 3: alto · la barba" (lineup: dictionary forms, like the restaurant summary) /
## "la piedra: dura" (evidence: the adjective agreeing with the object, as taught in the round).
func _summary_line(entry: Dictionary, lang: String) -> String:
	var parts := PackedStringArray()
	for key in entry.words:
		parts.append(lexicon.word(str(key), lang))
	var words := " · ".join(parts)
	if str(entry.get("adjective", "")) != "":
		words = lexicon.phrase(_agreed(str(entry.adjective), str(entry.object), lang), lang)
	if str(entry.get("object", "")) != "":
		var line: String = lexicon.phrase("police.summary_object", lang, {"object": {"word": str(entry.object)}, "words": words})
		return lexicon.phrase("police.summary_first_try", lang, {"line": line}) if bool(entry.get("first_try", false)) else line
	return lexicon.phrase("police.summary_suspect", lang, {"n": entry.number, "words": words})

func _show_summary() -> void:
	_summary = true
	_clear_round()
	var lines: Array = []
	for entry in _history:
		lines.append({"foreign": _summary_line(entry, lexicon.foreign), "native": _summary_line(entry, lexicon.native)})
	card.show_summary(lexicon.line("police.summary"), lines, lexicon.line("police.finish"))

# --- Tools (evidence game) -------------------------------------------------------------------

## A tool examines every object on the table, one after another, and leaves its result icon
## over each (evidence_props.gd badge()); the icons of the previous tool go.
func _on_tool(id: String) -> void:
	if not _running or _solved or mode != "evidence":
		return
	_tool = id
	_tool_serial += 1
	card.set_tool(id)
	var dim := _dim_of(id)
	var serial := _tool_serial
	for i in _nodes.size():
		EvidenceProps.badge(_nodes[i], "")
		var index := i
		get_tree().create_timer(i * TOOL_STAGGER).timeout.connect(func() -> void:
			if is_inside_tree() and serial == _tool_serial and index < _nodes.size() and is_instance_valid(_nodes[index]):
				_examine(_nodes[index], round.candidates[index], id, dim))

## The property pair (data "evidence.dims") a tool reveals: "hardness", "texture", "weight".
func _dim_of(tool: String) -> String:
	var dims: Dictionary = clues.data.get("evidence", {}).get("dims", {})
	for dim in dims:
		if str(dims[dim].get("tool", "")) == tool:
			return str(dim)
	return ""

## One object examined with `tool`: its little animation, then the result icon pops up.
func _examine(node: Node3D, item: Dictionary, tool: String, dim: String) -> void:
	var value := str(item.get(dim, ""))
	var body := node.get_node("Body") as Node3D
	var tween := create_tween()
	match tool:
		"squeeze":
			if value == "soft":
				tween.tween_property(body, "scale", Vector3(1.14, .5, 1.14), .25).set_trans(Tween.TRANS_SINE)
				tween.tween_property(body, "scale", Vector3.ONE, .45).set_trans(Tween.TRANS_ELASTIC)
			else:
				for k in 3:
					tween.tween_property(body, "position:x", .018 if k % 2 == 0 else -.018, .05)
				tween.tween_property(body, "position:x", 0.0, .05)
		"touch":
			for k in 4:
				tween.tween_property(body, "rotation:y", .12 if k % 2 == 0 else -.12, .09)
			tween.tween_property(body, "rotation:y", 0.0, .09)
		"lift":
			if value == "light":
				tween.tween_property(body, "position:y", .32, .22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				tween.tween_interval(.25)
				tween.tween_property(body, "position:y", 0.0, .35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			else:
				tween.tween_property(body, "position:y", .03, .35).set_trans(Tween.TRANS_SINE)
				for k in 5:
					tween.tween_property(body, "rotation:z", .035 if k % 2 == 0 else -.035, .06)
				tween.tween_property(body, "rotation:z", 0.0, .05)
				tween.tween_property(body, "position:y", 0.0, .12)
	var sprite := EvidenceProps.badge(node, value)
	if sprite != null and _nodes.size() == 1:
		# A report round's card is taller: the icon goes beside the one object, not above it.
		var extent: Vector3 = node.get_meta("evidence_size", Vector3.ONE * .2)
		sprite.position = Vector3(0, extent.y, -(extent.z + .16))
	if sprite != null:
		var full := sprite.pixel_size
		sprite.pixel_size = full * .2
		create_tween().tween_property(sprite, "pixel_size", full, .2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# --- Little animations ------------------------------------------------------------------------

## Lineup suspects breathe and lean a little toward the pointer; they blink through _life.
func _idle(delta: float) -> void:
	_idle_time += delta
	for i in _nodes.size():
		var bear := _nodes[i] as Node3D
		if not is_instance_valid(bear):
			continue
		if not bear.has_meta("base_scale"):
			bear.set_meta("base_scale", bear.scale)
		var base: Vector3 = bear.get_meta("base_scale")
		var breath := sin(_idle_time * 2.0 + i * 1.7) * .008
		bear.scale = Vector3(base.x * (1.0 - breath * .5), base.y * (1.0 + breath), base.z * (1.0 - breath * .5))
		var lean := .07 if i == _hovered and not _solved else 0.0
		bear.rotation.z = lerpf(bear.rotation.z, lean, minf(1.0, delta * 8.0))

## The shared plush gestures (plush_life.gd): the lineup's hop is a little higher (0.08).
func _hop(node: Node3D) -> void:
	PlushLife.play(self, node, "hop", 0.08 / 0.06)

func _shake(node: Node3D) -> void:
	PlushLife.play(self, node, "shake")

func _celebrate(node: Node3D) -> void:
	var tween := create_tween()
	var y := node.position.y
	for k in 2:
		tween.tween_property(node, "position:y", y + .18, .16).set_trans(Tween.TRANS_SINE)
		tween.tween_property(node, "position:y", y, .16).set_trans(Tween.TRANS_SINE)

# --- Camera -----------------------------------------------------------------------------------

func _camera_to(goal: Transform3D) -> void:
	goal = goal.orthonormalized()
	if _camera == null:
		_camera = Camera3D.new()
		_camera.name = "DetectiveCamera"
		_camera.fov = FOV
		_camera.near = .05
		add_child(_camera)
	if not _camera.current:
		# Start from whatever shows now (often the officer's face camera), but return to the
		# player's own camera at the end, never to the face camera.
		var showing := get_viewport().get_camera_3d()
		_previous_camera = player.get("camera") as Camera3D
		if _previous_camera == null:
			_previous_camera = showing
		if showing != null:
			_camera.global_transform = showing.global_transform
			_camera.far = showing.far
		_camera.make_current()
	if _camera_tween != null:
		_camera_tween.kill()
	var from := _camera.global_transform
	_camera_tween = create_tween()
	_camera_tween.tween_method(func(t: float) -> void: _camera.global_transform = from.interpolate_with(goal, t), 0.0, 1.0, CAMERA_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _camera_back() -> void:
	if _camera == null or not _camera.current:
		return
	if _camera_tween != null:
		_camera_tween.kill()
	var back := _previous_camera
	if back == null or not is_instance_valid(back):
		_camera.clear_current()
		return
	var from := _camera.global_transform
	_camera_tween = create_tween()
	_camera_tween.tween_method(func(t: float) -> void: _camera.global_transform = from.interpolate_with(back.global_transform, t), 0.0, 1.0, CAMERA_SECONDS * .75).set_trans(Tween.TRANS_SINE)
	# Only if no other game's camera took over meanwhile (the other detective game).
	_camera_tween.tween_callback(func() -> void:
		if _camera.current and is_instance_valid(back):
			back.make_current())

# --- Input ------------------------------------------------------------------------------------

## The candidate under the mouse (-1 for none).
func _pick(screen: Vector2) -> int:
	if _camera == null or not _camera.current:
		return -1
	var from := _camera.project_ray_origin(screen)
	var to := from + _camera.project_ray_normal(screen) * 40.0
	var space := _camera.get_world_3d().direct_space_state
	var exclude: Array[RID] = []
	for attempt in 8:
		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.collide_with_areas = true
		query.exclude = exclude
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			return -1
		var collider: Object = hit.collider
		if collider is Area3D and collider.has_meta("detective_index") and _owns(collider):
			return int(collider.get_meta("detective_index"))
		if collider is Area3D:
			exclude.append(collider.get_rid())
		else:
			return -1
	return -1

func _owns(area: Node) -> bool:
	for node in _nodes:
		if is_instance_valid(node) and node.is_ancestor_of(area):
			return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if not _running or host.is_asking_leave() or dialogue_panel.is_quit_open():
		return
	if event is InputEventMouseMotion:
		var hovered := _pick(event.position) if not _solved else -1
		if hovered != _hovered:
			_hovered = hovered
			_mark(_hover_ring, hovered if hovered != _selected or mode == "lineup" else -1)
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var index := _pick(event.position)
		if index >= 0 and not _solved:
			choose(index)
			get_viewport().set_input_as_handled()
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key: int = event.keycode
	if key >= KEY_1 and key <= KEY_9:
		var index := key - KEY_1
		if mode == "evidence" and round.has("options"):
			answer(index)
			get_viewport().set_input_as_handled()
		elif index < _nodes.size():
			choose(index)
			get_viewport().set_input_as_handled()
	elif (key == KEY_ENTER or key == KEY_KP_ENTER) and _solved:
		next_round()
		get_viewport().set_input_as_handled()
	elif mode == "evidence":
		for tool in TOOLS:
			if key == int(tool.key):
				_on_tool(str(tool.id))
				get_viewport().set_input_as_handled()

# --- Each frame: "!", walking away ------------------------------------------------------------

func _process(delta: float) -> void:
	if officer == null or not is_instance_valid(player):
		return
	if _running:
		if mode == "lineup":
			_idle(delta)
		return
	host.tick(delta)
