extends Node
## When the results screen shows (user, 21 Nov 2026: "wire them up"; docs/guides/MINIGAMES.md#results-screen).
## One place for every minigame, no session changes: it follows the activity board
## (activity_board.gd started / ended, the same signals missions and achievements use).
##   - A game starts (any route: the NPC, the picker): session_words.gd starts tracking its words.
##   - It ends with its target reached ("completed"): the results card is queued. A mission done
##     by it (missions.gd `completed`, same frame) becomes "Quest updated!" with its XP.
##   - The card shows once the game has let go: no dialogue box (the NPC's thanks closed), no
##     game panel that locks the player, no close-up, and SETTLE seconds after that, so the face
##     zoom has gone back. A game that starts meanwhile drops it.
##   - Play again restarts the same game as Yes would (its host's launch(), or the session's own
##     launch() for a game without an NPC). Continue exploring just closes the card.
## Pastimes (kind "pastime") and games ended early (walked away, "later", quit) show nothing.
## Title and line: results.title_<id> / results.line_<id> (data/phrases.json), else "Well done!".
const Board := preload("res://scripts/learning/activity_board.gd")
const Missions := preload("res://scripts/learning/missions.gd")
const SessionWords := preload("res://scripts/learning/session_words.gd")
const UiText := preload("res://scripts/language/ui_text.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
const MinigameWiring := preload("res://scripts/core/minigame_wiring.gd")

## Seconds of quiet (nothing on screen from the game) before the card shows.
const SETTLE := 0.6

var main: Node
## The finished game waiting for its card ("" = none), its rewards and the quiet time so far.
var pending := ""
var rewards: Array = []
var _quiet := 0.0
## Missions done this frame: game id -> XP (missions.completed may come before or after ended).
var _missions := {}

func setup(game: Node) -> void:
	main = game
	name = "ResultsFlow"
	var board = Board.shared()
	board.started.connect(_on_started)
	board.ended.connect(_on_ended)
	Missions.shared().completed.connect(func(_slot: int, id: String, xp: int) -> void:
		_missions[id] = xp
		if id == pending:
			_add_mission(id))
	main.results_screen.replay_requested.connect(_replay)

func _on_started(id: String) -> void:
	pending = ""
	rewards.clear()
	_missions.clear()
	SessionWords.shared().start(id)

func _on_ended(id: String, summary: Dictionary) -> void:
	if not bool(summary.get("completed", false)) or Board.shared().kind(id) == "pastime":
		return
	pending = id
	rewards.clear()
	_quiet = 0.0
	if _missions.has(id):
		_add_mission(id)

func _add_mission(id: String) -> void:
	if rewards.any(func(r): return str(r.get("kind", "")) == "quest"):
		return
	rewards.append({"kind": "quest", "text": UiText.t("missions." + id)})
	rewards.append({"kind": "xp", "amount": int(_missions.get(id, 0))})

## Something of the game is still on screen: its dialogue line, a locking panel, a close-up.
func _busy() -> bool:
	if main.shop_panel != null and main.shop_panel.is_dialogue_visible():
		return true
	if main.results_screen.visible or MinigameWiring.locks_player(main):
		return true
	if main.hold_ui != null and main.hold_ui.inspecting():
		return true
	return Board.shared().running_id != ""

func _process(delta: float) -> void:
	if pending == "":
		_missions.clear()
		return
	if _busy():
		_quiet = 0.0
		return
	_quiet += delta
	if _quiet >= SETTLE:
		show_now()

## Shows the card for the pending game (checks may call it directly).
func show_now() -> void:
	if pending == "":
		return
	var id := pending
	pending = ""
	_missions.clear()
	var lexicon = Lexicon.shared()
	var title_id := "results.title_" + id
	var line_id := "results.line_" + id
	main.results_screen.set_meta("results_owner", id)
	main.results_screen.show_results({
		"activity": id,
		"title": UiText.t(title_id) if lexicon.phrases.has(title_id) else UiText.t("results.title_done"),
		"line": UiText.t(line_id) if lexicon.phrases.has(line_id) else "",
		"words": SessionWords.shared(),
		"rewards": rewards.duplicate(),
		"replay": _can_replay(id),
	})
	rewards.clear()

func _session(id: String) -> Object:
	return Board.shared().session(id)

func _can_replay(id: String) -> bool:
	var session := _session(id)
	return session != null and (session.get("host") != null or session.has_method("launch"))

## Play again: the same game, as Yes on its greeting (the host's launch()).
func _replay() -> void:
	var id := str(main.results_screen.get_meta("results_owner", ""))
	var session := _session(id)
	if session == null or Board.shared().blocker(id) != "":
		return
	var host = session.get("host")
	if host != null:
		host.launch()
	elif session.has_method("launch"):
		session.launch()
