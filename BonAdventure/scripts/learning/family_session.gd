extends Node
## The hospital family game: Dr. Li (DrLi in the hospital unit, saved in the town; first placed
## by the deleted world_refinements.gd::remodel_hospital_displays()) shows the gold "!" while the player
## is near, greets them in the SHARED dialogue box (shop_order_panel.gd) and opens the
## family panel (family_panel.gd) with questions from family_questions.gd. Text comes from
## the Lexicon (data/phrases.json group "family"); rules and trees from data/family_game.json.
## Nothing is saved, no word is studied and no coins are paid (deferred).
##
## Flow: E / click Dr. Li -> greeting (+ "let's go" / "not now") -> panel. Tap a person or
## Yes / No: right shows ✓ and "Another question"; wrong shows ✗ and lets the player try
## again. ✕ / Exit / Esc closes the panel with Dr. Li's goodbye. A family is kept for
## QUESTIONS_PER_FAMILY questions, then a new one is made from another tree template.
##
## Offers and progress follow the shared activity board (activity_board.gd, data/activities.json
## "family_dr_li"): the offer is rolled when the player comes within CALL_DISTANCE; while
## another activity runs Dr. Li asks the player to finish it first; a session (panel open to
## closed) counts questions answered right on the first tap, and at the target (20) Dr. Li
## thanks the player and the panel closes.
const Board := preload("res://scripts/learning/activity_board.gd")
const FamilyTree := preload("res://scripts/learning/family_tree.gd")
const Questions := preload("res://scripts/learning/family_questions.gd")
const Host := preload("res://scripts/learning/minigame_host.gd")
## Practice tracking (practice_log.gd): only relation questions test one word (the relative,
## decision 6); the first tap is the answer, solving it completes the question.
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
const Progress := preload("res://scripts/learning/game_progress.gd")
const NPC := "DrLi"
const CALL_DISTANCE := 30.0
const WALK_AWAY_DISTANCE := 14.0
const MESSAGE_SECONDS := 9.0
const QUESTIONS_PER_FAMILY := 3

var lexicon
var dialogue_panel
var panel
var interaction
var player: Node3D
var doctor: Node3D
## The shared NPC host (minigame_host.gd): Dr. Li, the "!", talking.
var host
var presence:
	get: return host.presence if host != null else null
var tree
var question: Dictionary = {}
var _asked_in_family := 0
var _last_kind := ""
var _last_template := ""
## The current level's question kinds and weights ({} = data/family_game.json "kinds").
var _kinds: Dictionary = {}
var _rng := RandomNumberGenerator.new()
const ACTIVITY := "family_dr_li"
## Whether Dr. Li offers the game now (rolled on approach; kept on the host).
var offered: bool:
	get: return host.offered if host != null else false
	set(value):
		if host != null:
			host.offered = value

func setup(shared_lexicon, shared_dialogue_panel, family_panel, interaction_controller, explorer: Node3D, world: Node3D) -> void:
	name = "FamilySession"
	lexicon = shared_lexicon
	dialogue_panel = shared_dialogue_panel
	panel = family_panel
	interaction = interaction_controller
	player = explorer
	_rng.randomize()
	doctor = world.find_child(NPC, true, false) as Node3D
	if doctor == null:
		push_warning("family_session: no '%s' node" % NPC)
		return
	host = Host.new()
	add_child(host)
	host.setup(self, {"activity": ACTIVITY, "group": "family", "speaker": "hospital.dr_li", "call_distance": CALL_DISTANCE, "walk_away": WALK_AWAY_DISTANCE, "message_seconds": MESSAGE_SECONDS}, lexicon, dialogue_panel, interaction, player, doctor)
	host.play_chosen.connect(open_game)
	panel.person_pressed.connect(_on_answer)
	panel.answer_pressed.connect(_on_answer)
	panel.next_pressed.connect(next_question)
	panel.close_requested.connect(close_game)

## For the activity board: the game panel is open.
func activity_running() -> bool:
	return panel.visible

func busy() -> bool:
	return (host != null and host.owns_dialogue()) or panel.visible

func _show(id: String) -> void:
	host.say(id)

# --- Game --------------------------------------------------------------------------------

func open_game() -> void:
	interaction.clear_card()
	panel.show_native = dialogue_panel.show_native
	tree = null
	# Levels (LEARN-06, 25 Nov 2026; docs/game/minigames.md#whos-who): the question kinds
	# and how many questions a session asks.
	var settings: Dictionary = Progress.shared().params(ACTIVITY)
	_kinds = settings.get("kinds", {})
	Board.shared().begin(ACTIVITY, int(settings.get("questions", 0)))
	next_question()
	panel.set_progress(0, Board.shared().target(ACTIVITY))

func _new_family() -> void:
	var templates: Array = FamilyTree.template_ids()
	var choices := templates.filter(func(id): return id != _last_template) if templates.size() > 1 else templates
	var template: String = choices[_rng.randi_range(0, choices.size() - 1)]
	_last_template = template
	tree = FamilyTree.new()
	# Relationship questions must be unique in the language being learned.
	tree.labeler = func(word: String, gender: String, kin: Dictionary) -> String: return lexicon.word(word, lexicon.foreign, "label", gender, kin)
	tree.setup(template, {"f": lexicon.names(lexicon.foreign, "f"), "m": lexicon.names(lexicon.foreign, "m")}, _rng)
	_asked_in_family = 0

## A new validated question (a new family every QUESTIONS_PER_FAMILY questions).
func next_question() -> void:
	if tree == null or _asked_in_family >= QUESTIONS_PER_FAMILY:
		_new_family()
	# A relation question whose word is due or may be new is preferred (word_memory.gd,
	# 24 Nov 2026); the other kinds test no word and are taken as they come.
	var make := func() -> Dictionary:
		for attempt in 10:
			var kind := Questions.pick_kind(_rng, _last_kind, _kinds)
			var made: Dictionary = Questions.generate(tree, kind, _rng)
			if not made.is_empty():
				_last_kind = kind
				return made
		return {}
	var words_of := func(made: Dictionary) -> Array:
		return [str(made.word)] if str(made.get("kind", "")) == "relation" else []
	var picked: Variant = preload("res://scripts/learning/word_memory.gd").shared().pick_round(make, words_of)
	question = picked if picked is Dictionary else {}
	if question.is_empty():
		push_error("family_session: no question for " + tree.template_id)
		return
	_asked_in_family += 1
	if str(question.get("kind", "")) == "relation":
		PracticeLog.shared().begin(ACTIVITY, [str(question.word)])
	else:
		_practice_abandon()
	panel.open(_panel_data())

func _panel_data() -> Dictionary:
	var people: Array = []
	for id in tree.people:
		var person: Dictionary = tree.people[id]
		people.append({"id": id, "name": person.name, "gender": person.gender, "species": person.species,
			"age": lexicon.phrase("posters.age", lexicon.foreign, {"age": person.age}),
			"date": FamilyTree.date_digits(person.birth), "row": person.row, "col": person.col,
			"parents": person.parents, "partner": person.partner})
	return {
		"title": lexicon.line("family.title"),
		"question": {"foreign": lexicon.phrase(question.phrase, lexicon.foreign, question.values), "native": lexicon.phrase(question.phrase, lexicon.native, question.values)},
		"legend": lexicon.line("family.date_legend"),
		"today": lexicon.line("family.today", {"date": FamilyTree.date_digits(tree.reference)}),
		"yes": lexicon.line("family.answer_yes"),
		"no": lexicon.line("family.answer_no"),
		"next": lexicon.line("family.next"),
		"exit": lexicon.line("family.exit"),
		"translate": lexicon.line("common.show_translation"),
		"people": people,
		"named": Questions.named(question),
		"yes_no":bool(question.get("yes_no", false)),
	}

## A tapped person id, or "yes" / "no".
func _on_answer(answer: String) -> void:
	if not panel.visible or question.is_empty() or panel.solved:
		return
	if bool(question.get("yes_no", false)) != (answer in ["yes", "no"]):
		return
	var right: bool = answer == str(question.answer)
	# Only a question answered right on the first tap counts toward progress.
	var first_try: bool = not panel.marks.values().has(false)
	panel.mark(answer, right, lexicon.line("family.correct" if right else "family.wrong"))
	if not right and first_try:
		Board.shared().add_miss(ACTIVITY)
	if PracticeLog.shared().game_id() == ACTIVITY:
		PracticeLog.shared().first_answer(right)
		if right:
			PracticeLog.shared().complete()
	if right and first_try:
		var finished: bool = Board.shared().add_success(ACTIVITY)
		panel.set_progress(Board.shared().done(ACTIVITY), Board.shared().target(ACTIVITY))
		if finished:
			offered = false
			panel.hide_panel()
			question = {}
			_show("family.complete")

## A language change in Settings ends the game with Dr. Li's goodbye; her name follows the
## new languages.
func end_activity() -> void:
	if host == null:
		return
	close_game()
	host.refresh_name()

func _practice_abandon() -> void:
	host.abandon_practice()

func close_game() -> void:
	_practice_abandon()
	if not panel.visible:
		return
	panel.hide_panel()
	question = {}
	_show("family.goodbye")

# --- Each frame -------------------------------------------------------------------------
# Esc reaches this session through Main's popup stack (the ✕ of the family panel or the
# dialogue box, whichever is on top).

func _process(delta: float) -> void:
	if host != null:
		host.tick(delta)
