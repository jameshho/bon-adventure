extends Node
## The shared "NPC host" of every minigame (8 Nov 2026): everything a game does with its NPC
## and the SHARED dialogue box before, around and after the game itself. A session adds one
## as a child, calls setup() and keeps only its own rules. Guide (read before building a
## minigame): docs/MINIGAMES.md.
##
## What it owns:
##   - the NPC: its Interactable (kind TALK, the "!" while calling; interaction system,
##     docs/guides/ARCHITECTURE_REVIEW_PART1.md#interaction-system), character name, the hop and the
##     face camera (npc_presence.gd), extra talkers (add_talker());
##   - the activity board: register, roll whether the game is offered when the player comes
##     near, blocker ("finish the other task first");
##   - talking: E on the NPC -> finish_first / not_now / greeting with Yes and Not now;
##     say() for any line; which session owns the shared box (by the line on screen, so two
##     NPCs a few steps apart can share it); walking away closes a question (a fallback since
##     14 Nov 2026: Main locks the player while the box shows choices, Main.talk_locked());
##   - the shared quit card ("are you sure you want to leave?") and abandoning practice.
## What stays in the session: the game (panel or world), scoring, practice begin/answer,
## what each line says.
##
## The session must define busy() -> bool (talking or playing) and activity_running() -> bool
## (the activity board's question). Optional: _host_talk(talker) -> bool, asked after the
## camera zooms in, to say something itself instead of the default greeting (return true;
## gate() and offer() help); _host_speaker() -> Variant, the speaker line for say() when not
## the NPC (null: the NPC); _host_walked_away(distance) -> bool to replace the distance test.
## It calls tick(delta) from its own _process.
##
## Signals: play_chosen (Yes on the greeting; the box is already closed), choice_made(id)
## (any other choice with this game's prefix; the box stays open), talk_closed(line_id)
## (✕, auto-close or walking away ended this game's line), leave_answered(leave).
const Board := preload("res://scripts/learning/activity_board.gd")
const Presence := preload("res://scripts/learning/npc_presence.gd")
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
const Interactable := preload("res://scripts/core/interactable.gd")
const InteractIcons := preload("res://scripts/ui/interact_badge.gd")
## Metres within which E (or a click / tap) talks to the NPC or another talker.
const TALK_DISTANCE := 3.5

signal play_chosen
## "Not now" on the greeting, just before the goodbye line is said.
signal declined
signal choice_made(id: String)
signal talk_closed(line_id: String)
signal leave_answered(leave: bool)

## Defaults for setup()'s `spec`; text ids default to "<group>.<name>" (data/phrases.json).
const DEFAULTS := {
	"call_distance": 16.0,
	"walk_away": 10.0,
	"message_seconds": 9.0,
}

var session: Node
var spec: Dictionary = {}
var activity := ""
var lexicon
var dialogue_panel
var interaction
var player: Node3D
var npc: Node3D
var presence
## Whether the NPC offers the game now (rolled when the player comes near).
var offered := true
## Who the player is talking to (the NPC or an extra talker).
var talker: Node3D
var _talkers: Array = []
var _near := false
var _rng := RandomNumberGenerator.new()
## The line this game last put in the shared box ("" when it shows none).
var line_id := ""
var _line: Dictionary = {}
var _asking_leave := false

## `spec`: "activity" (activities.json id), "group" (phrases.json group; text ids default to
## <group>.greeting, .play, .not_now, .goodbye, .leave_confirm, .leave_yes, .leave_no),
## "speaker" (phrase id of the NPC's name), optional "choice_prefix" (default "<group>_"),
## any text id override ("greeting", "play", "not_now", "goodbye", "leave_confirm", ...),
## "call_distance", "walk_away", "message_seconds". Returns false (and leaves the game
## inert) when `for_npc` is null, e.g. its building is left out by dev_focus.txt.
func setup(owner_session: Node, game_spec: Dictionary, shared_lexicon, shared_dialogue_panel, interaction_controller, explorer: Node3D, for_npc: Node3D) -> bool:
	name = "MinigameHost"
	session = owner_session
	spec = DEFAULTS.merged(game_spec, true)
	activity = str(spec.activity)
	lexicon = shared_lexicon
	dialogue_panel = shared_dialogue_panel
	interaction = interaction_controller
	player = explorer
	npc = for_npc
	_rng.randomize()
	if npc == null:
		return false
	presence = Presence.new()
	presence.name = "Presence"
	add_child(presence)
	presence.setup(npc, player)
	add_talker(npc)
	refresh_name()
	Board.shared().register(activity, session)
	offered = Board.shared().roll(activity, _rng)
	dialogue_panel.choice_pressed.connect(_on_choice)
	dialogue_panel.dialogue_closed.connect(_on_dialogue_closed)
	dialogue_panel.quit_answered.connect(_on_quit_answered)
	return true

## Another character the player can talk to about this game (the restaurant's customer): an
## Interactable of kind TALK whose use is talking (the "!" shows while its presence calls).
func add_talker(node: Node3D) -> void:
	var item := Interactable.attach(node, {
		"kind": Interactable.Kind.TALK,
		"prompt_distance": TALK_DISTANCE,
		"priority": 1.0,
		"indicator": Interactable.Indicator.CALL,
		"badge_offset": Vector3(0, InteractIcons.head_height(node), 0),
		# Range is measured to the NPC itself, not to the badge over its head (a tall NPC's badge
		# can sit higher than the focus pass's rise limit).
		"on_point": func(_from: Vector3) -> Vector3: return node.global_position,
		"on_check": func() -> Variant: return _talkers.has(node) and not session.busy(),
		"on_use": func() -> void: _on_talk(node),
	})
	item.enabled = true
	if not _talkers.has(node):
		_talkers.append(node)

func remove_talker(node: Node3D) -> void:
	_talkers.erase(node)
	var item := Interactable.on(node)
	if item != null:
		item.enabled = false
		item.calling = false

## The phrase id for `key`: the spec's override, else "<group>.<key>".
func text(key: String) -> String:
	return str(spec.get(key, "%s.%s" % [spec.get("group", ""), key]))

func choice_prefix() -> String:
	return str(spec.get("choice_prefix", "%s_" % spec.get("group", "")))

## The NPC's name in the foreign language (the word card); call again after a language change.
func refresh_name() -> void:
	if npc != null and spec.has("speaker"):
		npc.set_meta("character_name", lexicon.phrase(str(spec.speaker), lexicon.foreign))

# --- Talking ------------------------------------------------------------------------------

## Shows `id` in the shared box as this game's NPC (or `speaker`, a {"foreign", "native"}
## line). auto_close < 0 uses message_seconds; choices keep the box open.
func say(id: String, choices: Array = [], auto_close: float = -1.0, values: Dictionary = {}, speaker: Variant = null) -> void:
	show_line(id, lexicon.line(id, values), choices, auto_close, speaker)

## Like say(), for a line the session put together itself ({"foreign", "native"}: joined
## phrases, a generated question); `id` names it for line_id.
func show_line(id: String, line: Dictionary, choices: Array = [], auto_close: float = -1.0, speaker: Variant = null) -> void:
	line_id = id
	_line = line
	dialogue_panel.translate_text = lexicon.line("common.show_translation")
	var who: Variant = speaker
	if who == null and session.has_method("_host_speaker"):
		who = session._host_speaker()
	if who == null:
		who = lexicon.line(str(spec.get("speaker", "")))
	dialogue_panel.show_dialogue(who, _line, choices, float(spec.message_seconds) if auto_close < 0.0 else auto_close)

## A yes / not-now question: the greeting by default. Yes emits play_chosen.
func offer(id: String = "", play_label: String = "") -> void:
	say(id if id != "" else text("greeting"), [
		{"id": choice_prefix() + "play", "label": lexicon.line(play_label if play_label != "" else text("play")), "icon": "check"},
		{"id": choice_prefix() + "no", "label": lexicon.line("common.reply_no"), "icon": "no"}], 0.0)

## A choice for say() with this game's prefix (its press arrives as choice_made(id)).
func choice(id: String, label_id: String, icon: String = "") -> Dictionary:
	return {"id": choice_prefix() + id, "label": lexicon.line(label_id), "icon": icon}

## Whether the shared box still shows this game's line. When another NPC took the box over,
## this game's talk is over: forget it (and zoom back) without touching the box.
func owns_dialogue() -> bool:
	if line_id == "":
		return false
	var ours: bool = dialogue_panel.is_dialogue_visible() and dialogue_panel.current_line() == _line
	if not ours:
		_forget_line()
	return ours

## Closes this game's line and zooms back (no talk_closed: the session chose to close it).
func close_dialogue() -> void:
	var ours := owns_dialogue()
	line_id = ""
	_line = {}
	if ours:
		dialogue_panel.hide_dialogue()
	if presence != null:
		presence.zoom_to_face(false)

func zoom(on: bool) -> void:
	if presence != null:
		presence.zoom_to_face(on)

func _forget_line() -> void:
	line_id = ""
	_line = {}
	if presence != null:
		presence.zoom_to_face(false)

func _on_talk(who: Node3D) -> void:
	if not _talkers.has(who) or session.busy():
		return
	talker = who
	interaction.clear_card()
	if who == npc:
		presence.zoom_to_face(true)
	if session.has_method("_host_talk") and session._host_talk(who):
		return
	if not gate():
		offer()

## Says "finish the other task first" or this game's "not now" when the game cannot start;
## returns true when it said one of them.
func gate() -> bool:
	if Board.shared().blocker(activity) != "":
		say("common.finish_first")
		return true
	if not offered:
		say(text("not_now"))
		return true
	return false

func _on_choice(id: String) -> void:
	if not id.begins_with(choice_prefix()) or not owns_dialogue():
		return
	match id.trim_prefix(choice_prefix()):
		"play":
			close_dialogue()
			play_chosen.emit()
		"no":
			declined.emit()
			say(text("goodbye"))
		_:
			choice_made.emit(id)

func _on_dialogue_closed() -> void:
	if line_id == "":
		return
	# Auto-close has hidden the box already; ✕ only asks, so the owner hides it. When another
	# NPC's line is on screen, leave the box alone.
	var was := line_id
	if dialogue_panel.is_dialogue_visible() and dialogue_panel.current_line() == _line:
		dialogue_panel.hide_dialogue()
	_forget_line()
	talk_closed.emit(was)

# --- Leaving -----------------------------------------------------------------------------

## The shared quit card with this game's question (or `question_id`, e.g. the restaurant's
## "leave the restaurant?" at its door); the answer arrives as leave_answered.
func ask_leave(question_id := "") -> void:
	_asking_leave = true
	dialogue_panel.show_quit(lexicon.line(question_id if question_id != "" else text("leave_confirm")), lexicon.line(text("leave_yes")), lexicon.line(text("leave_no")))

func is_asking_leave() -> bool:
	return _asking_leave

## Takes the quit card away without an answer (the game ended some other way).
func cancel_leave() -> void:
	if _asking_leave:
		_asking_leave = false
		dialogue_panel.hide_quit()

func _on_quit_answered(leave: bool) -> void:
	if not _asking_leave:
		return
	_asking_leave = false
	dialogue_panel.hide_quit()
	leave_answered.emit(leave)

## Drops this game's unfinished practice question (practice_log.gd): leaving, finishing, a
## language change.
func abandon_practice() -> void:
	if PracticeLog.shared().game_id() == activity:
		PracticeLog.shared().abandon()

# --- Test launcher (game_launcher.gd) -------------------------------------------------------

## Starts the game for testing: closes any talk, offers the game, puts the player in front of
## the NPC (when farther than `call_distance`) and starts as Yes on the greeting would (or the
## session's _host_launch()).
func launch() -> void:
	if npc == null:
		return
	cancel_leave()
	close_dialogue()
	offered = true
	if npc.global_position.distance_to(player.global_position) > float(spec.call_distance) * 0.5:
		place_player_near()
	if session.has_method("_host_launch"):
		session._host_launch()
	else:
		play_chosen.emit()

## Puts the player about 2 m from the NPC, on the first side (front, either side, back) with
## a clear line from the NPC and floor below, facing the NPC. The caller stands a seated
## player up first (game_launcher.gd).
func place_player_near() -> void:
	var space := npc.get_world_3d().direct_space_state
	var chest := npc.global_position + Vector3(0, 1.0, 0)
	var forward := -npc.global_basis.z
	forward.y = 0.0
	forward = forward.normalized() if forward.length() > 0.01 else Vector3.FORWARD
	var spot := npc.global_position + forward * 2.0
	for turn in [0.0, PI * 0.5, -PI * 0.5, PI]:
		var dir: Vector3 = forward.rotated(Vector3.UP, turn)
		var target: Vector3 = chest + dir * 2.0
		var ray := PhysicsRayQueryParameters3D.create(chest, target)
		ray.exclude = [player.get_rid()] if player is CollisionObject3D else []
		var blocked := space.intersect_ray(ray)
		if not blocked.is_empty() and not npc.is_ancestor_of(blocked.collider):
			continue
		var down := PhysicsRayQueryParameters3D.create(target, target + Vector3(0, -3.0, 0))
		var floor_hit := space.intersect_ray(down)
		if floor_hit.is_empty():
			continue
		spot = floor_hit.position
		break
	player.global_position = spot + Vector3(0, 0.1, 0)
	player.velocity = Vector3.ZERO
	var look := npc.global_position - spot
	var yaw := atan2(-look.x, -look.z)
	player.rotation.y = yaw
	player.camera_yaw = yaw
	player.reset_camera()

# --- Each frame (the session calls it from _process) --------------------------------------

## The "!" while the player is near and the game is offered; a new roll each time the player
## comes near (not during a game); walking away closes a question.
func tick(delta: float) -> void:
	if npc == null or not is_instance_valid(player):
		return
	# Esc or ✕ took the leave question away without an answer: that is "stay".
	if _asking_leave and not dialogue_panel.is_quit_open():
		_asking_leave = false
		leave_answered.emit(false)
	var distance := npc.global_position.distance_to(player.global_position)
	var near: bool = session._host_near(distance) if session.has_method("_host_near") else distance < float(spec.call_distance)
	if near and not _near and not session.activity_running():
		offered = Board.shared().roll(activity, _rng)
	_near = near
	var calling: bool = session.has_method("_host_calling") and session._host_calling()
	presence.animate(delta, calling or (not session.busy() and not session.activity_running() and near and offered and Board.shared().blocker(activity) == ""))
	if line_id != "" and dialogue_panel.has_choices() and owns_dialogue():
		var from: Node3D = talker if is_instance_valid(talker) else npc
		var gone: bool = session._host_walked_away(from.global_position.distance_to(player.global_position)) if session.has_method("_host_walked_away") else from.global_position.distance_to(player.global_position) > float(spec.walk_away)
		if gone:
			var was := line_id
			close_dialogue()
			talk_closed.emit(was)
