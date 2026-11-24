extends Node
## Hong Kong mahjong at the table in front of the home (user request, 9 Nov 2026; guide:
## docs/guides/MAHJONG.md). Four plush players sit at the table (MahjongTable, home unit, baked by
## scripts/buildings/home.gd): Mei (cat, the host, on the north chair), Bao (bear), Awoo
## (samoyed) and Kiko (golden). Talking to Mei (E / click, the shared host) offers a game; Yes
## asks the mode (at least 3 fan to win, or any fan); then the screen fades, Mei gets up and
## stands by the table, the player sits in her chair and a camera looks down at the table.
## Until then the tiles (mahjong_view.gd, made when the town loads) show a fixed game in
## progress (data/mahjong.json "preset", user 9 Nov 2026); sitting down deals a fresh hand, and
## leaving puts the preset back. The game itself (rules, NPC play, camera, panel) runs only
## while the player sits.
##
## One hand per game (mahjong_game.gd): the player is seat 0, Bao, Awoo and Kiko are seats 1-3
## in the order of play (mahjong_ai.gd plays them), the dealer is random, the round wind East.
## The panel (mahjong_panel.gd) shows the player's hand and the call buttons; every call pops
## up as an English word over the table near the caller's edge, and play
## pauses a moment after it (pace.call_hold). At the end the result
## card offers Play again (same mode) or Leave. ✕ / Esc asks the shared leave question. Leaving
## fades back: the player stands up, Mei sits down again, the preset game returns.
##
## Text: data/phrases.json group "mahjong"; rules and pacing: data/mahjong.json; offers: the
## activity board ("mahjong_mei", data/activities.json). No word is tested and no coins exist.
##
## Memory (user, 23 Nov 2026): the profile's mahjong.json (save_store.gd) keeps the mode, the
## visit's won hands (the scoreboard) and the hand in play when the player leaves, closes the
## app or hides the page (save_now()), and after every finished hand. With a game saved, Mei's
## first question after Yes is "Shall we carry on with our last game?": Yes, continue sits down
## at the same hand with the same scores (a new hand when the last one had ended); No, a new
## game goes on to the lesson and mode questions as before (the old save stays until the new
## game is saved over it).
const Board := preload("res://scripts/learning/activity_board.gd")
const Host := preload("res://scripts/learning/minigame_host.gd")
const PlushLife := preload("res://scripts/characters/plush_life.gd")
const Zone := preload("res://scripts/learning/minigame_zone.gd")
const SeatedTable := preload("res://scripts/learning/minigame_table.gd")
const Rules := preload("res://scripts/learning/mahjong_rules.gd")
const Game := preload("res://scripts/learning/mahjong_game.gd")
const AI := preload("res://scripts/learning/mahjong_ai.gd")
const View := preload("res://scripts/learning/mahjong_view.gd")
const HouseCharacters := preload("res://scripts/characters/house_characters.gd")
const Home := preload("res://scripts/buildings/home.gd")
const PopWord3D := preload("res://scripts/ui/pop_word_3d.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")
const SAVE_FILE := "mahjong.json"
const ACTIVITY := "mahjong_mei"
const TABLE := "MahjongTable"
## The players by seat (= game seat and chair): their ids in the NPC registry (data/npcs.json,
## 23 Nov 2026), which gives each one's plush scene and name phrase (PLAYERS).
const PLAYER_IDS := ["mei", "bao", "mahjong_awoo", "kiko"]
const NpcRegistry := preload("res://scripts/characters/npc_registry.gd")
## Seat -> [plush scene, name phrase], read from the registry.
var PLAYERS: Array = PLAYER_IDS.map(func(id: String) -> Array:
	var entry: Dictionary = NpcRegistry.spec(id)
	return [str(entry.get("scene", "")), str(entry.get("name_phrase", ""))])
## Where Mei stands while the player has her chair (table-local, town units): behind the
## player's left shoulder, facing the table.
const MEI_STANDS := Vector3(-1.75, 0.0, 2.0)
## The game camera (table-local): a seated player's view from behind the chair (user,
## 9 Nov 2026: "too high"; see the NPCs' faces; then "move back slightly" to see the own exposed
## sets; then "slightly closer, a little higher and slightly zoomed in" to see the tiles more
## clearly). The table is about 13% larger on screen than at (0, 2.7, 2.4) with FOV 50; the
## player's exposed sets still lie just above the hand bar (≈ y 683 at 1280x800) and Awoo's
## eyes stay below the status line. Earlier: (0, 3.45, 1.5) looking at (0, 1.0, -0.18);
## (0, 3.8, 1.5) / (0, 1.0, 0.15); (0, 2.7, 2.0) / (0, 1.1, -0.2); (0, 2.7, 2.4) / same, FOV 50.
## Since 15 Nov 2026 (user: "I don't have to see my own tile ... zoom in a bit", tiles still hard
## to read on a phone): closer, steeper and narrower. The four discard piles fill the space
## between the status bar and the hand bar (tiles about 1.5x larger than at (0, 2.8, 2.25) /
## (0, 1.08, -0.12), FOV 45); the player's own wall, standing hand and exposed sets lie under or
## below the hand bar, and the NPCs show mostly as shoulders at the screen edges. Chosen from
## renders at 844x390 (phone landscape), 1280x800 and 1024x768.
## Since 16 Nov 2026 (user: "tilt the angle slightly higher ... maximize the view of the revealed
## tiles"; the hand bar also grew 30 %): higher and further over the table, (0, 3.35, 0.95) looking
## at (0, 1.0, 0.1). The player's own discard row now sits wholly above the larger hand bar.
## Chosen from renders at 844x390 and 1280x800 against (0, 3.1, 1.3) / (0, 1.0, 0.05).
## Since 16 Nov 2026, later (user: "I still want to be able to see the face of the NPC sitting
## across me"; the status bar is to move later, so it was ignored here): back and lower,
## (0, 3.0, 2.0) looking at (0, 1.0, -0.2), FOV 44. Picked by a search over camera height,
## distance, aim and FOV that projected the real discard piles and Awoo's eyes at 844x390: Awoo's
## eyes at least 10 px below the top edge, all four piles (two full rows) above the hand bar, and
## the largest shorter on-screen tile side. That gave (0, 3.0, 2.0) / (0, 1.0, -0.2), FOV 44, with
## tiles about 60 % of the size at (0, 3.35, 0.95). Then (user: "Pinwheel (B)") the discards grew
## 30 % in a pinwheel (mahjong_view.gd DISCARD_GROW, DISCARD_PINWHEEL) and the same search, over
## FOV up to 56, gave (0, 2.5, 1.7) / (0, 1.0, -0.2), FOV 50: at 844x390 the weakest pile's tiles
## are ~15 px and the average ~20 px across their shorter side (centred six-tile rows: 12.9 / 14.7).
const CAMERA_AT := Vector3(0.0, 2.5, 1.7)
const CAMERA_LOOK := Vector3(0.0, 1.0, -0.2)
const CAMERA_FOV := 50.0
## Sitting down, seen in the town (minigame_table.gd): Mei gets up beside her chair
## (MEI_GETS_UP, table-local) and steps to MEI_STANDS; the player sits in her chair.
const MEI_GETS_UP := Vector3(-0.75, 0.0, 1.95)
## While the player sits at the table the sun moves about every SUN_STEP_SECONDS of real time
## and slides over SUN_SLIDE_SECONDS, so shadows do not tick during play (user, 9 Nov 2026).
## The clock runs as usual; leaving restores the town's normal steps.
const SUN_STEP_SECONDS := 30.0
const SUN_SLIDE_SECONDS := 1.0
## Call words (PopWord3D) pop up over the table near the caller's edge, centred on the seat
## (user, 9 Nov 2026: a word pop-up and a short pause give the calls a rhythm; then nearer the
## edge, centred, shorter, cuter colours). Always English ("Pung!", "Chow!", "Kong!",
## "Mahjong!"), whatever the language settings (user, 9 Nov 2026): these are the game's own
## names for the calls. A self-drawn win pops up as "Mahjong!" too. There is no message line
## (user, 9 Nov 2026).
const CALL_POP_AT := 0.78      # out from the table centre toward the seat (felt edge 0.92)
const CALL_POP_HEIGHT := 0.22  # above the table top
const CALL_POP_LANGUAGE := "en"
## A pastel outline per call.
const CALL_POP_OUTLINE := {"pung": Color("ff5f9e"), "chow": Color("3aa6ff"), "kong": Color("9a73ff"), "win": Color("ff9f1c"), "self_win": Color("ff9f1c")}

var lexicon
var dialogue_panel
var panel
## Mei's lessons (mahjong_lesson_panel.gd): before a game from her question, during one from
## the book button; the game waits while they are open.
var lessons
var interaction
var player: Node3D
var main
var host
var zone
var table: Node3D
var chairs: Array = [null, null, null, null]
var npcs: Array = [null, null, null, null]
## The players blink and now and then hop, nod, shake or tilt their heads (plush_life.gd; user,
## 9 Nov 2026: the suspect ID game's liveliness, only once in a while).
var life
## The seated-table choreography (minigame_table.gd): Mei's chair, her standing stand-in, the
## game camera, the HUD.
var sitting
## Mei standing beside the table while the player has her chair (null otherwise).
var mei_standing: Node3D:
	get: return sitting.stand_in if sitting != null else null
var view
var game
## The game camera while the player sits at the table (null otherwise).
var camera: Camera3D:
	get: return sitting.camera if sitting != null else null
var _rng := RandomNumberGenerator.new()
var _playing := false
var _mode := 3
var _dirty := false
var _fresh := false   # the next layout is a new deal: tiles jump, no sliding
var _declined_turn := -1   # the turn on which the player chose Keep playing over a win
## The tile the player double-clicked during another player's turn, played automatically on
## their next turn when no Mahjong! or Kong button shows (user, 9 Nov 2026); -1: none.
var _queued := -1
var _wait := 0.0
var _shown_call: Dictionary = {}
var _result_shown := false
var _call_words: Array = [null, null, null, null]   # PopWord3D per seat, made on first use
var _call_hold := 0.0   # the extra pause after a call, added to the next wait
var _hud_hidden: Array = []
## This visit's won hands ({"winner", "from" (-1 self-drawn), "fan"}) for the scoreboard
## (user, 10 Nov 2026): kept over Play again, cleared when the player sits down or leaves.
var _visit_hands: Array = []
## The profile's save file, fixed at setup (a save while the town is torn down for a profile
## switch still goes to this profile, like player_place_keeper.gd).
var _save_path := ""

## Whether Mei offers the game now (kept on the host, like the other sessions).
var offered: bool:
	get: return host.offered if host != null else false
	set(value):
		if host != null:
			host.offered = value

func setup(shared_lexicon, shared_dialogue_panel, mahjong_panel, interaction_controller, explorer: Node3D, world: Node3D, game_main, lesson_panel = null) -> void:
	name = "MahjongSession"
	lexicon = shared_lexicon
	dialogue_panel = shared_dialogue_panel
	panel = mahjong_panel
	# The corner card (translate, leave) ends left of the HUD's top-right buttons.
	var hud = game_main.get("hud") if game_main != null else null
	if hud != null:
		panel.corner_limit = [hud.get("peek_button"), hud.get("settings_button")].filter(func(b): return b is Control)
	lessons = lesson_panel
	interaction = interaction_controller
	player = explorer
	main = game_main
	_save_path = SaveStore.path(SAVE_FILE)
	_rng.randomize()
	table = world.find_child(TABLE, true, false) as Node3D
	if table == null:   # the home is left out by dev_focus.txt: stay inert
		return
	for child in table.get_children():
		if child.has_meta("mahjong_seat"):
			chairs[int(child.get_meta("mahjong_seat"))] = child
	for seat in 4:
		if chairs[seat] != null:
			npcs[seat] = _seat_npc(seat)
	if npcs[0] == null:
		return
	life = PlushLife.new()
	add_child(life)
	life.setup(npcs, _rng)
	# Deferred: Main's render trim (scripts/world/render_culling.gd) runs after the minigames
	# are set up and merges every still mesh into frozen static batches; tiles made before it
	# would be copied there and stay drawn at their preset places for good. Deferring is not
	# enough in the app's staged loading (the trim waits for later loading steps), so the view
	# also opts out itself (meta keep_own_draw, mahjong_view.gd build(); 15 Nov 2026).
	_show_preset.call_deferred()
	host = Host.new()
	add_child(host)
	host.setup(self, {"activity": ACTIVITY, "group": "mahjong", "speaker": "mahjong.mei"}, lexicon, dialogue_panel, interaction, player, npcs[0])
	host.choice_made.connect(_on_choice)
	host.leave_answered.connect(_on_leave_answered)
	zone = Zone.new()
	add_child(zone)
	zone.setup(player, main, "MahjongFade")
	sitting = SeatedTable.new()
	add_child(sitting)
	sitting.setup(main, player, zone, chairs[0], npcs[0], {
		"scene": str(PLAYERS[0][0]), "name_node": "Mei standing",
		"gets_up_at": table.to_global(MEI_GETS_UP), "stands_at": table.to_global(MEI_STANDS),
		"camera_at": table.to_global(CAMERA_AT), "camera_look": table.to_global(CAMERA_LOOK), "fov": CAMERA_FOV})
	panel.tile_pressed.connect(_on_tile)
	panel.tile_queued.connect(_on_tile_queued)
	panel.action_pressed.connect(_on_action)
	panel.leave_requested.connect(_on_leave_requested)
	panel.again_pressed.connect(_on_again)
	panel.lessons_requested.connect(_open_lessons)
	if lessons != null:
		lessons.closed.connect(_on_lessons_closed)

func _letters() -> Array:
	var letters: Array = []
	for wind in ["e", "s", "w", "n"]:
		letters.append(lexicon.phrase("mahjong.letter_" + wind, lexicon.foreign))
	return letters

## The tiles of the preset game in progress, laid out as if Mei were playing.
func _show_preset() -> void:
	if view == null:
		view = View.new()
		table.add_child(view)
		view.build(_letters())
	var preset := Game.new()
	preset.load_preset(Rules.config().get("preset", {}))
	view.layout(preset, false, true)

## A plush sitting on chair `seat`, facing the table (the restaurant customer's pose).
func _seat_npc(seat: int) -> Node3D:
	var chair: Node3D = chairs[seat]
	var spot: Vector3 = chair.to_global(Vector3(0, Home.MAHJONG_SEAT, 0))
	var facing := -chair.global_basis.z
	var back: Vector3 = chair.to_global(Vector3(0, Home.MAHJONG_SEAT + 0.4, 0.27))
	var spec: Array = PLAYERS[seat]
	var npc: Node3D = HouseCharacters.new().seated(str(spec[0]), table, "Mahjong player %d" % (seat + 1), spot, facing, back)
	npc.set_meta("word_key", "person")
	npc.set_meta("character_name", lexicon.phrase(str(spec[1]), lexicon.foreign))
	npc.set_meta("npc_id", str(PLAYER_IDS[seat]))
	npc.set_meta("seat_point", spot)
	npc.add_to_group("figures")
	HouseCharacters.fit_blocker(npc)
	# The other three chat when talked to (npc_chatter.gd); Mei is the game's host.
	if seat > 0 and main != null and main.get("npc_chatter") != null:
		main.npc_chatter.attach(npc)
	return npc

func activity_running() -> bool:
	return _playing

func busy() -> bool:
	return (host != null and host.owns_dialogue()) or _playing

func _name(seat: int) -> Dictionary:
	return {"phrase": "mahjong.you" if seat == 0 else str(PLAYERS[seat][1])}

# --- Starting ------------------------------------------------------------------------------

## Mei's own greeting: Yes goes straight on to the mode question in the same close-up.
func _host_talk(_talker: Node3D) -> bool:
	if not host.gate():
		host.say("mahjong.greeting", [host.choice("yes", "mahjong.play", "check"), host.choice("no", "common.reply_no", "no")], 0.0)
	return true

## The test launcher (game_launcher.gd) starts at the mode question.
func _host_launch() -> void:
	_ask_mode()

## After Yes (user, 9 Nov 2026): "Do you know how to play mahjong?" Yes goes on to the mode
## question; No asks which lesson (the basics or scoring). Closing a lesson asks whether to
## take another one or play.
func _ask_lessons() -> void:
	if lessons == null:
		_ask_mode()
		return
	host.say("mahjong.lesson_ask", [host.choice("know", "mahjong.lesson_know", "check"), host.choice("teach", "mahjong.lesson_teach", "book")], 0.0)

## Which lesson: after No, and (with Let's play) after a lesson closes.
func _ask_which(after_lesson: bool = false) -> void:
	var choices: Array = [host.choice("basics", "mahjong.lesson_basics", "book"), host.choice("scoring", "mahjong.lesson_scoring", "book")]
	if after_lesson:
		choices.append(host.choice("know", "mahjong.lesson_play", "play"))
	host.say("mahjong.lesson_more" if after_lesson else "mahjong.lesson_which", choices, 0.0)

func _open_lessons(index: int = 0) -> void:
	if lessons == null or lessons.visible:
		return
	if _playing:
		index = lessons.lesson
	else:
		host.close_dialogue()
		main.hud.hide_for_game(true)   # the minimap, clock and help would show through the card
	lessons.open(index, panel.show_native if _playing else dialogue_panel.show_native)

## Before a game Mei asks: another lesson, or play? During one the game goes on.
func _on_lessons_closed() -> void:
	if not _playing and host != null:
		main.hud.hide_for_game(false)
		host.zoom(true)
		_ask_which(true)

func _ask_mode() -> void:
	host.say("mahjong.choose_mode", [host.choice("three", "mahjong.mode_three"), host.choice("any", "mahjong.mode_any")], 0.0)

func _on_choice(id: String) -> void:
	match id.trim_prefix(host.choice_prefix()):
		"yes": _ask_continue() if not _saved().is_empty() else _ask_lessons()
		"continue": _begin(_mode, _saved())
		"fresh": _ask_lessons()   # the old game is replaced once the new one is saved
		"teach": _ask_which()
		"basics": _open_lessons(0)
		"scoring": _open_lessons(1)
		"know": _ask_mode()
		"three": _begin(3)
		"any": _begin(0)

## A saved game ({"mode", "hands", "game"}) asks first whether to carry on (user, 23 Nov 2026).
func _ask_continue() -> void:
	var points: int = Rules.balances(_saved().get("hands", []))[0]
	host.say("mahjong.continue_ask", [host.choice("continue", "mahjong.continue_yes", "play"), host.choice("fresh", "mahjong.continue_new", "check")], 0.0, {"points": _signed(points)})

## `resume`: a saved game to carry on (its mode, scores and hand in play); {} deals a new game.
func _begin(mode: int, resume: Dictionary = {}) -> void:
	host.close_dialogue()
	if resume.is_empty():
		_mode = int(Rules.config().get("modes", {}).get("three" if mode > 0 else "any", mode))
	else:
		_mode = int(resume.get("mode", mode))
	_playing = true
	_visit_hands.clear()
	for hand in resume.get("hands", []):
		_visit_hands.append({"winner": int(hand.winner), "from": int(hand.from), "fan": int(hand.fan)})
	Board.shared().begin(ACTIVITY)
	interaction.clear_card()
	# Seen in the town (user, 9 Nov 2026): Mei gets up and steps aside, the player sits down
	# in her chair, and only then the screen fades into the game (minigame_table.gd). A language
	# change (end_activity()) during the walk-up stops it.
	if await sitting.begin(_open_game) and _playing:
		var saved_hand: Variant = resume.get("game")
		if not (saved_hand is Dictionary and _resume_hand(saved_hand)):
			_new_hand()

## Behind the fade into the game: the slow sun, the tiles with the current letters, the panel.
func _open_game() -> void:
	_slow_sun(true)
	main.hud.cluster_off = true   # no journal / map / games / help buttons at the table (user, 10 Nov 2026)
	var letters := _letters()
	if view == null:
		_show_preset()
	view.repaint(letters)
	panel.letters = letters
	panel.show_native = dialogue_panel.show_native
	panel.open()

func _new_hand() -> void:
	game = Game.new()
	game.changed.connect(func() -> void: _dirty = true)
	_result_shown = false
	_shown_call = {}
	_declined_turn = -1
	_set_queued(-1)
	_hide_call_words()
	panel.open()
	_fresh = true
	game.start(_rng, _rng.randi_range(0, 3), _mode)
	_dirty = true

## Sits down at the saved hand; false when it cannot be restored (a new hand is dealt).
func _resume_hand(saved_hand: Dictionary) -> bool:
	var restored := Game.new()
	if not restored.restore(saved_hand):
		return false
	game = restored
	game.changed.connect(func() -> void: _dirty = true)
	_result_shown = false
	_shown_call = {}
	_declined_turn = -1
	_set_queued(-1)
	_hide_call_words()
	panel.open()
	_fresh = true
	_dirty = true
	return true

# --- Memory ------------------------------------------------------------------------------

## The profile's saved game, or {} when there is nothing to carry on (no hand in play and no
## won hand yet).
func _saved() -> Dictionary:
	var data: Variant = SaveStore.read_json(_save_path) if _save_path != "" else null
	if not data is Dictionary:
		return {}
	if data.get("game") is Dictionary or not Array(data.get("hands", [])).is_empty():
		return data
	return {}

func _write_save(data: Dictionary) -> void:
	if _save_path != "":
		SaveStore.write_json(_save_path, data)

## Writes the game at the table now (on leaving, after each hand, when the app closes or the
## page is hidden: web_resume.gd). Nothing while the player is not seated.
func save_now() -> void:
	if not _playing or game == null:
		return
	_write_save({"mode": _mode, "hands": _visit_hands,
		"game": game.to_save() if game.phase != "over" else null})

func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED,
			NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_EXIT_TREE]:
		save_now()

# --- Each frame --------------------------------------------------------------------------

func _process(delta: float) -> void:
	if host == null:
		return
	host.tick(delta)
	_follow_daylight()
	if not _playing or game == null or zone.fading or host.is_asking_leave() or (lessons != null and lessons.visible):
		return
	if _dirty:
		_dirty = false
		_refresh()
		_plan()
	if _wait > 0.0:
		_wait -= delta
		if _wait <= 0.0:
			_act()

func _slow_sun(slow: bool) -> void:
	var cycle = main.get("day_night") if main != null else null
	if cycle == null:
		return
	if slow:
		cycle.set_sun_steps(SUN_STEP_SECONDS * cycle.DAY_MINUTES / (float(cycle.cycle_minutes) * 60.0), SUN_SLIDE_SECONDS)
	else:
		cycle.set_sun_steps()

## The tile faces glow by how far the sun has dimmed (mahjong_view.gd set_daylight()).
func _follow_daylight() -> void:
	if view == null:
		return
	var cycle = main.get("day_night") if main != null else null
	view.set_daylight(cycle.daylight() if cycle != null else 1.0)

func _pace(key: String) -> float:
	return float(Rules.config().get("pace", {}).get(key, 0.8))

## What happens next: an NPC's move after a pause, or the player's choice. After a call the
## pause is longer (`pace.call_hold`), so the word pops up and the claimed tile lands before
## play goes on; a win shows its word before the result card.
func _plan() -> void:
	_wait = 0.0
	var hold := _call_hold
	_call_hold = 0.0
	match str(game.phase):
		"turn":
			if game.turn != 0:
				_wait = _pace("npc_turn") + hold
			elif _auto_tile() >= 0:
				_wait = _pace("auto_discard") + hold
		"claim":
			if game.waiting.has(0):
				_answer_npcs()
			else:
				_wait = _pace("claim_pause") + hold
		"over":
			if hold > 0.0:
				_wait = hold
			else:
				_show_result()

func _act() -> void:
	match str(game.phase):
		"turn":
			if game.turn == 0:
				var tile := _auto_tile()
				if tile >= 0:
					_set_queued(-1)
					game.discard(0, tile)
				return
			var seat: int = game.turn
			var action := AI.turn_action(game, seat)
			match str(action.type):
				"win": game.declare_self_win(seat)
				"kong": game.declare_kong(seat, int(action.tile))
				_: game.discard(seat, int(action.tile))
		"claim":
			_answer_npcs()
		"over":
			_show_result()

func _answer_npcs() -> void:
	for seat in game.waiting.keys():
		if seat != 0:
			game.respond(seat, AI.claim_answer(game, seat, game.waiting[seat]))

## Redraws the table and the panel from the game.
func _refresh() -> void:
	view.layout(game, game.phase == "over", _fresh)
	_fresh = false
	var mine: bool = game.phase == "turn" and game.turn == 0
	panel.set_hand(game.hands[0], game.drawn if mine else -1, mine, 13 - 3 * game.melds[0].size())
	# The status card (user, 10 Nov 2026): the mode and your wind; every player's points are on
	# the scoreboard its star button opens, the tiles left and the round wind on the table.
	panel.set_info([
		lexicon.line("mahjong.status_three" if _mode > 0 else "mahjong.status_any"),
		lexicon.line("mahjong.seat_wind", {"wind": {"phrase": _wind_phrase(game.seat_winds[0])}}),
	], [-1, game.seat_winds[0]])
	_update_scores()
	view.show_counter(game.wall_left(), game.prevailing, lexicon.phrase("mahjong.counter_word", lexicon.foreign))
	if not game.last_call.is_empty() and game.last_call != _shown_call:
		_shown_call = game.last_call.duplicate()
		_pop_call(int(game.last_call.seat), str(game.last_call.type))
		_call_hold = _pace("call_hold")
	# No message line over the table (user, 9 Nov 2026: "remove this sentence and everything
	# shown in this box"): the call words and buttons say what happens.
	var actions: Array = []
	if mine:
		# A winning hand is never declared for the player: they press the big Mahjong! button,
		# or Keep playing to go for a bigger hand (user, 9 Nov 2026).
		if game.can_self_win(0) and _declined_turn != game.turns_played:
			actions.append(_win_action(int(game.self_win_score(0).fan)))
			actions.append({"id": "keep", "label": lexicon.line("mahjong.btn_keep")})
		for kind in game.kong_options(0):
			actions.append({"id": "kong", "label": lexicon.line("mahjong.btn_kong"), "data": kind, "tiles": [kind, kind, kind, kind]})
	elif game.phase == "claim" and game.waiting.has(0):
		var options: Dictionary = game.waiting[0]
		var tile: int = game.last_discard
		if options.has("win"):
			actions.append(_win_action(int(options.win.fan)))
		if options.has("kong"):
			actions.append({"id": "kong", "label": lexicon.line("mahjong.btn_kong"), "data": tile, "tiles": [tile, tile, tile, tile]})
		if options.has("pung"):
			actions.append({"id": "pung", "label": lexicon.line("mahjong.btn_pung"), "data": tile, "tiles": [tile, tile, tile]})
		for chow in options.get("chows", []):
			actions.append({"id": "chow", "label": lexicon.line("mahjong.btn_chow"), "data": int(chow[0]), "tiles": chow})
		actions.append({"id": "pass", "label": lexicon.line("mahjong.btn_pass")})
	panel.set_actions(actions)

## The big Mahjong! button: {"id": "win", "label", "worth": the hand's fan}. The panel shows
## it on its own above the other buttons (Pass on a discard, Keep playing on a draw).
func _win_action(fan: int) -> Dictionary:
	return {"id": "win", "label": lexicon.line("mahjong.btn_win"), "worth": lexicon.line("mahjong.win_worth", {"fan": fan})}

static func _wind_phrase(wind: int) -> String:
	return "mahjong.wind_" + ["e", "s", "w", "n"][wind - Rules.EAST]

# --- The player's moves --------------------------------------------------------------------

func _on_tile(kind: int) -> void:
	if _playing and game != null and game.phase == "turn" and game.turn == 0:
		_set_queued(-1)
		game.discard(0, kind)

## A double-click while another player plays marks that tile (-1 or the same tile again: unmark).
func _on_tile_queued(kind: int) -> void:
	if not _playing or game == null or game.phase == "over" or (game.phase == "turn" and game.turn == 0):
		return
	_set_queued(kind if game.hands[0].has(kind) else -1)

func _set_queued(kind: int) -> void:
	_queued = kind
	panel.set_queued(kind)

## The marked tile to play now, on the player's turn: -1 when nothing is marked, or when the
## player has a choice to make first (Mahjong!, a kong), which waits for their click.
func _auto_tile() -> int:
	if _queued < 0 or game.phase != "turn" or game.turn != 0 or not game.hands[0].has(_queued):
		return -1
	if game.can_self_win(0) or not game.kong_options(0).is_empty():
		return -1
	return _queued

func _on_action(id: String, data: int) -> void:
	if not _playing or game == null:
		return
	if game.phase == "turn" and game.turn == 0:
		match id:
			"win": game.declare_self_win(0)
			"kong":
				_declined_turn = -1   # the replacement tile may make a new winning hand
				game.declare_kong(0, data)
			"keep":
				_declined_turn = game.turns_played
				_dirty = true
	elif game.phase == "claim" and game.waiting.has(0):
		if id != "pass":
			_set_queued(-1)   # a claim changes the hand: choose the discard again
		var answer := {"type": id}
		if id == "chow":
			answer["tile"] = data
		game.respond(0, answer)

# --- Calls ---------------------------------------------------------------------------------

func _pop_call(seat: int, type: String) -> void:
	var id := "mahjong.call_" + type
	if view == null:
		return
	if _call_words[seat] == null:
		var word := PopWord3D.new()
		word.name = "CallWord%d" % seat
		view.add_child(word)
		word.position = View.outward(seat) * CALL_POP_AT + Vector3.UP * (Home.MAHJONG_TOP + CALL_POP_HEIGHT)
		_call_words[seat] = word
	var text: String = lexicon.phrase("mahjong.call_win" if type == "self_win" else id, CALL_POP_LANGUAGE)
	_call_words[seat].pop(text, CALL_POP_OUTLINE.get(type, CALL_POP_OUTLINE.pung), _pace("call_seconds"), camera)

func _hide_call_words() -> void:
	for word in _call_words:
		if word != null:
			word.stop()

# --- The end of a hand -------------------------------------------------------------------

func _show_result() -> void:
	if _result_shown:
		return
	_result_shown = true
	var result: Dictionary = game.result
	var winner := int(result.get("winner", -1))
	var data := {"lines": [], "total": {}}
	if winner < 0:
		data.title = lexicon.line("mahjong.draw")
	else:
		data.title = lexicon.line("mahjong.you_win") if winner == 0 else lexicon.line("mahjong.npc_wins", {"name": _name(winner)})
		data.lines.append(lexicon.line("mahjong.from_wall") if result.self_drawn else lexicon.line("mahjong.from_discard", {"name": _name(int(result.from))}))
		var score: Dictionary = result.score
		if score.get("limit", false):
			data.lines.append(lexicon.line("mahjong.limit"))
		for item in score.get("items", []):
			data.lines.append(lexicon.line("mahjong.fan_line", {"hand": {"phrase": "mahjong.hand_" + str(item.id)}, "fan": int(item.fan)}))
		if score.get("items", []).is_empty():
			data.lines.append(lexicon.line("mahjong.no_fan"))
		data.total = lexicon.line("mahjong.total", {"fan": int(score.fan)})
		_visit_hands.append({"winner": winner, "from": -1 if result.self_drawn else int(result.from), "fan": int(score.fan)})
	data.scores = _scoreboard(winner >= 0)
	save_now()
	_update_scores()
	_hide_call_words()
	panel.show_result(data, _again_label(), lexicon.line("mahjong.leave"))

## The scoreboard card's rows (the star button shows the first, the player's total).
func _update_scores() -> void:
	var rows: Array = _scoreboard(false)
	for seat in 4:
		rows[seat].wind = int(game.seat_winds[seat])
	panel.set_scores(rows)

## The result card's scoreboard: the visit's points per seat and what the last hand changed
## ([{"name": line, "face": species, "total": "+12", "change": "+8" or ""}]; change only after
## a win). The face is the plush_portraits.gd species: the player is BonBon (the pig plush), the
## others their PLAYERS plush (11 Nov 2026: faces instead of a "Points this visit" heading).
func _scoreboard(won: bool) -> Array:
	var now: Array = Rules.balances(_visit_hands)
	var before: Array = Rules.balances(_visit_hands.slice(0, _visit_hands.size() - 1)) if won else now
	var rows: Array = []
	for seat in 4:
		var change: int = int(now[seat]) - int(before[seat])
		rows.append({"name": lexicon.line("mahjong.you") if seat == 0 else lexicon.line(str(PLAYERS[seat][1])),
				"face": "pig" if seat == 0 else str(PLAYERS[seat][0]).get_file().trim_suffix("_plush.tscn"),
				"total": _signed(int(now[seat])), "change": _signed(change) if change != 0 else ""})
	return rows

## A score with its sign: +12, -4, 0.
static func _signed(n: int) -> String:
	return ("+%d" % n) if n > 0 else str(n)

## The result card's first button: "Play again" when the data sets no number of hands (as
## always), else "Next hand" while hands remain and none after the last (the test launcher's
## rounds, activity_board.gd set_rounds()).
func _again_label() -> Dictionary:
	var board = Board.shared()
	board.add_success(ACTIVITY)
	if board.target(ACTIVITY) <= 0:
		return lexicon.line("mahjong.again")
	return lexicon.line("mahjong.next_hand") if board.done(ACTIVITY) < board.target(ACTIVITY) else {}

func _on_again() -> void:
	if _playing:
		_new_hand()

# --- Leaving -------------------------------------------------------------------------------

func _on_leave_requested() -> void:
	if not _playing or zone.fading:
		return
	if game != null and game.phase == "over":
		_leave("mahjong.finished")
	else:
		host.ask_leave()

func _on_leave_answered(leave: bool) -> void:
	if leave and _playing:
		_leave("mahjong.left_early")

func _leave(line: String) -> void:
	host.cancel_leave()
	await sitting.end(_close_game)
	_playing = false
	host.say(line)

## Behind the fade back to the town: the game and panel go, the preset returns; the table
## helper then stands the player up and seats Mei again.
func _close_game() -> void:
	save_now()
	panel.hide_panel()
	if view != null:
		view.hide_counter()
	main.hud.cluster_off = false
	_visit_hands.clear()
	if lessons != null and lessons.visible:
		lessons.visible = false   # no `closed`: nothing to ask again
	game = null
	_wait = 0.0
	_set_queued(-1)
	_show_preset()
	_hide_call_words()
	_slow_sun(false)

## A language change in Settings ends the game; the names follow the new languages.
func end_activity() -> void:
	if host == null:
		return
	host.cancel_leave()
	if _playing:
		_close_game()
		sitting.release()
		_playing = false
	host.refresh_name()
	for seat in 4:
		if npcs[seat] != null:
			npcs[seat].set_meta("character_name", lexicon.phrase(str(PLAYERS[seat][1]), lexicon.foreign))
