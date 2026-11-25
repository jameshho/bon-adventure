extends Node
## Bank teller game (activity "teller_bank", 18 Nov 2026; design: docs/guides/TOWN_DESIGN_BRIEF.md
## "Bank teller game", purpose and progression: docs/game/minigames.md). The bear banker at the
## bank's reception asks the player to cover teller window 2. The screen fades and the player
## stands behind the window; plush customers (house characters) come up from the queue ropes one
## at a time:
##   - a withdrawal: the customer asks for an amount in words ($100-$500, multiples of 5) while
##     the window's monitor shows the account (since 24 Nov 2026, user: one request line, no
##     "Check the account" step and no second "Do I have enough?"); the teller counts out the
##     cash (the shared money screen, $5/$10/$50/$100 bills only) or says "not enough" (one
##     customer per session is short);
##   - change (one customer per session): whole hundreds paid back without $100 bills;
##   - an impostor (user, 21 Nov 2026; at most one per session, data/bank_teller.json
##     impostor_chance): the monitor shows each account's name, balance and the owner's headshot
##     (plush_portraits.gd); an impostor claims another character's account, so the photo is a
##     different animal. The hidden alarm (user, 24 Nov 2026: a surprise, no longer a reply
##     button) is a red button on the counter beside the keyboard; pressing it brings a police
##     officer (the beagle in the police costume, like the police station's) who escorts the
##     impostor out of the bank. The banker's and the manager's warnings name the red button.
## The player sits on window 2's chair for the whole game (user, 24 Nov 2026; bank.gd
## teller_seats); BonBon's model is hidden in the teller's own views and shown in the close-up
## of the teller and the manager's walk. A served customer's thanks moves on by itself.
## Since 23 Nov 2026 (user) one view shows both: window 2's monitor stands to the side of the
## window, turned toward the teller, so the account (photo, name, balance) and the customer's face
## behind the glass are on screen together (the camera toggle of 21 Nov is gone). The monitor's
## words follow the world language (EN held shows them in the native language).
## Paying an impostor (user, 23 Nov 2026): the money goes, the impostor leaves happily and the
## bank manager (a crocodile in a suit, new character) walks out of her office through the staff
## door, says it was wrong and warns the player, walks back, and the game goes on; another
## impostor comes later in the session. A second payout in one session: she lets the player go;
## the session ends with a "let go" results card (no Play again; the banker offers the game
## again on a later visit). Nothing is saved. The alarm stays the right answer.
## 70% of withdrawals give a reason (a persona story); the rest just ask and say thanks.
## The customer reacts in character (data/phrases.json group "teller", personas in
## data/bank_teller.json). A customer counts when served right the first time; at the
## progress target the window closes, the screen fades back to the lobby and the banker thanks
## the player. Nothing is saved and no word is tracked (amounts are generated language, like
## the supermarket till).
##
## Shared parts (docs/guides/MINIGAMES.md#building-a-minigame): minigame_host.gd (the banker, the
## "!", talking, the leave question), minigame_zone.gd (the fade and placing the player), the
## shared dialogue box, money_panel.gd, house_characters.gd worker() for the customers,
## npc_presence.gd for their face close-ups and plush_life.gd for their hops.
const Host := preload("res://scripts/learning/minigame_host.gd")
const Zone := preload("res://scripts/learning/minigame_zone.gd")
const Presence := preload("res://scripts/learning/npc_presence.gd")
const Board := preload("res://scripts/learning/activity_board.gd")
const Currency := preload("res://scripts/learning/currency.gd")
const HouseCharacters := preload("res://scripts/characters/house_characters.gd")
const PlushLife := preload("res://scripts/characters/plush_life.gd")
const ModularTown := preload("res://scripts/world/modular_town.gd")
const BonStyle := preload("res://scripts/ui/bon_style.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const PlushPortraits := preload("res://scripts/ui/plush_portraits.gd")
const LiveLabels := preload("res://scripts/language/live_labels.gd")
const ProfileManager := preload("res://scripts/core/profile_manager.gd")
const UiText := preload("res://scripts/language/ui_text.gd")

const ACTIVITY := "teller_bank"
const DATA := "res://data/bank_teller.json"
const BANKER := "BearBanker"

## Spots in TOWN coordinates (the bank unit's parts are stored in town coordinates, so these are
## local to the town root, Main.apartment; measured from scenes/town/bank.scn on 18 Nov 2026).
## The teller line runs along z at x 136.5-137.3 (lobby face 136.54, glass 137.0); window 2 is
## the middle one at z 107.7; the teller chairs reach x 138.15 and the back counter starts near
## x 140.6. The lobby lies toward -x, the entrance at x 126.3; the queue ropes stand at z 106
## and 109.5 between x 132.5 and 134.6.
const TELLER_SPOT := Vector3(139.25, 0.03, 107.7)
const TELLER_LOOK := Vector3(-1, 0, 0)
## Window 2's chair (bank.gd teller_seats): the player sits here for the game; standing up
## starts looking for room at TELLER_SPOT.
const TELLER_SEAT := "Interior/Teller chair seat 2"
## The hidden alarm (24 Nov 2026): a red button on the teller's side of the counter top (top
## 1.15), left of window 2's keyboard as the teller sees it, in the account view.
const ALARM_AT := Vector3(137.2, 1.15, 108.2)
const ALARM_RADIUS := 0.045
const WINDOW_SPOT := Vector3(135.75, 0.03, 107.7)
const QUEUE_SPOT := Vector3(133.2, 0.03, 107.75)
const DOOR_SPOT := Vector3(127.6, 0.03, 108.0)
## Out past the rope at z 109.5 and the reception desk (z above 110.6 near x 129).
const EXIT_PATH := [Vector3(135.4, 0.03, 110.5), Vector3(128.6, 0.03, 109.9), Vector3(127.2, 0.03, 108.6)]
## The police officer: comes in at the door, walks around the queue rope (EXIT_PATH backwards)
## and stops beside the window, north of the customer; leaves a step behind the impostor.
const OFFICER_SCENE := "res://scenes/characters/beagle_plush.tscn"
const OFFICER_SPOT := Vector3(135.05, 0.03, 108.6)
const OFFICER_IN := [Vector3(128.6, 0.03, 109.9), Vector3(135.4, 0.03, 110.5), OFFICER_SPOT]
const OFFICER_FACE_CAMERA_AT := Vector3(139.0, 2.75, 108.3)
const OFFICER_LAG := 0.6
## The customer's talk camera: from the teller's side, above the glass, looking down at the face.
const FACE_CAMERA_AT := Vector3(139.0, 2.75, 107.3)
## Window 2's monitor (moved aside 23 Nov 2026 by bank.gd teller_side_monitor): the centre of the
## prop, turned MONITOR_YAW degrees about y from facing +x (the teller), so it faces VIEW_EYE.
## The account screen lies on its face (MONITOR_FACE in front of the centre), MONITOR_SIZE big.
const MONITOR_CENTRE := Vector3(137.12, 1.41, 107.15)
const MONITOR_YAW := -19.1
const MONITOR_FACE := 0.035
const MONITOR_SIZE := Vector2(0.46, 0.29)
## The account view (user, 23 Nov 2026: monitor and customer at once): from behind the teller's
## chair at eye height, the customer's face behind the glass on the left, the monitor on the
## right, both above a two-row dialogue box.
const VIEW_EYE := Vector3(138.85, 1.72, 107.75)
const VIEW_AT := Vector3(136.0, 1.0, 107.38)
const VIEW_FOV := 50.0
## The bank manager (23 Nov 2026): a crocodile in a suit ("la jefa", word boss) who stands by
## her desk at the back of the office (bank.gd rear_annex), facing the office door. She walks
## to the staff door (bank.gd wider_staff_door since 24 Nov 2026: town x 138.85-140.15 in the
## wall at z 109.525; its open leaf lies along x 140.15 up to z 110.9, so she passes beside it),
## through it and stops beside the teller, north of window 2. MANAGER_DOOR (the turn in the office)
## lies north of the open leaf's end (z 110.9) so her walk from the desk passes beyond it.
## Her plush, outfit, word, gender, desk spot and facing are her entry in the NPC registry
## (data/npcs.json "bank_manager", town frame; 23 Nov 2026).
const MANAGER_ID := "bank_manager"
const NpcRegistry := preload("res://scripts/characters/npc_registry.gd")
## The manager's word, gender, desk spot and facing come from her registry entry (static, so checks
## can read them as Session.MANAGER_HOME).
static var MANAGER_WORD := str(NpcRegistry.spec(MANAGER_ID).get("word", "boss"))
static var MANAGER_GENDER := str(NpcRegistry.spec(MANAGER_ID).get("gender", "f"))
static var MANAGER_HOME: Vector3 = NpcRegistry.point(NpcRegistry.spec(MANAGER_ID).get("at", [143.5, 0.03, 110.3]))
static var MANAGER_LOOK: Vector3 = NpcRegistry.direction(NpcRegistry.spec(MANAGER_ID).get("facing", "-x"))
const MANAGER_DOOR := Vector3(139.5, 0.03, 111.6)
const MANAGER_SPOT := Vector3(139.5, 0.03, 108.75)
const MANAGER_FACE_CAMERA_AT := Vector3(139.1, 2.3, 107.35)
const STAFF_DOOR_LEAF := "Staff door/Staff door leaf"
## The cutscene camera while she walks: high in the corner by the back counter at the vault end
## of the teller area, over the teller's shoulder toward the staff door.
const SCENE_EYE := Vector3(140.45, 2.9, 106.1)
const SCENE_AT := Vector3(139.2, 0.9, 109.4)
const SCENE_FOV := 62.0
## The teller's own close-up (saying "not enough"): from the customer's side, through the glass
## (since 24 Nov 2026 the teller sits close to it), a little to the side, PLAYER_FACE_LIFT above
## the face, with a wider lens; the face sits PLAYER_FACE_SCREEN_Y of the way down the screen
## (as npc_presence.gd frames NPCs), clear of the dialogue box.
const PLAYER_FACE_EYE := Vector3(136.25, 0.0, 107.35)
const PLAYER_FACE_LIFT := 0.35
const PLAYER_FACE_FOV := 55.0
const PLAYER_FACE_SCREEN_Y := 0.34
## Seconds a line without a button stays before the next one: READ_BASE plus READ_PER_CHAR per
## character, at most READ_MAX.
const READ_BASE := 1.4
const READ_PER_CHAR := 0.05
const READ_MAX := 4.0
## The account screen's layout in the monitor's plane (metres from its centre, +x to the
## viewer's right): the headshot card top left, the name and "Balance" beside it.
const PHOTO_SIZE := 0.13
const PHOTO_AT := Vector2(-0.145, 0.06)
const TEXT_AT := Vector2(0.07, 0.06)
const TEXT_WIDTH := 0.27
## Customers walk at this speed (m/s) with a small bounce.
const WALK_SPEED := 2.6
const BOUNCE := 0.06

var dialogue
var lexicon
var panel
var money
var interaction
var player: Node3D
var town: Node3D
var main
var bank: Node3D
var banker: Node3D
var host
var zone
var data: Dictionary = {}
## Whether the banker offers the game now (rolled on approach; kept on the host).
var offered: bool:
	get: return host.offered if host != null else false
	set(value):
		if host != null:
			host.offered = value

var playing := false
## Where the customer at the window stands: "" (none or walking), "ask", "screen", "count",
## "fix" (a mistake line waits for "try again" / "look again"), "served".
var step := ""
## The customer at the window, and the one waiting in the queue: {node, presence, id, name,
## persona, kind ("withdraw" or "change"), dollars, balance, number, missed, impostor, claim_id,
## face (the species on the account photo), real_name; once the police come: officer,
## officer_presence}. An impostor's `name` is the account they claim.
var current: Dictionary = {}
var waiting: Dictionary = {}
## Customers who have left the window and are walking out.
var _leaving: Array = []
var _walkers: Array = []
var _spawned := 0
var _short_at := -1
var _change_at := -1
var _impostor_at := -1
var _personas: Array = []
var _last_character := ""
var _finished := false
## The last question in the box, re-asked after "No, I'll keep serving": [id, line, choices,
## monitor, speaker, presence].
var _prompt: Array = []
var _monitor: Node3D
var _screen_top: Label3D
var _screen_amount: Label3D
## The account holder's headshot on the monitor, on a pale card.
var _screen_photo: Sprite3D
var _screen_card: MeshInstance3D
var _portraits
## "Balance" and the idle "Window 2" (world labels bound to phrases, live_labels.gd).
var _screen_word: Label3D
var _screen_idle: Label3D
## Whether the monitor shows the current customer's account.
var _account_shown := false
## Impostors paid out this session (a second one ends the game, data/bank_teller.json
## payouts_to_fire), the manager and her face close-up.
var _payouts := 0
var manager: Node3D
var _manager_presence
var _camera: Camera3D
var _previous_camera: Camera3D
## The hidden alarm button (made on the first game) and whether the current view shows the
## teller (BonBon's model visible while seated).
var _alarm: Node3D
var _self_view := false
var _rng := RandomNumberGenerator.new()

func setup(shop_dialogue, shop_panel, money_panel, interaction_controller, explorer: Node3D, world: Node3D, game) -> void:
	name = "TellerSession"
	dialogue = shop_dialogue
	lexicon = shop_dialogue.lexicon
	panel = shop_panel
	money = money_panel
	interaction = interaction_controller
	player = explorer
	town = world
	main = game
	_rng.randomize()
	data = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	bank = ModularTown.building(town, "bank", 0)
	banker = bank.find_child(BANKER, true, false) as Node3D if bank != null else null
	if banker == null:
		push_warning("teller_session: no bank unit (dev focus) or no " + BANKER)
		return
	zone = Zone.new()
	add_child(zone)
	zone.setup(player, main, "TellerFade")
	host = Host.new()
	add_child(host)
	host.setup(self, {"activity": ACTIVITY, "group": "teller"}, lexicon, panel, interaction, player, banker)
	host.play_chosen.connect(start_game)
	host.choice_made.connect(_on_choice)
	host.talk_closed.connect(_on_talk_closed)
	host.leave_answered.connect(_on_leave_answered)
	money.submitted.connect(_on_submitted)
	money.close_requested.connect(_on_money_close)
	# During the game a click goes to the alarm test first and E does nothing (the seat's own
	# claim would stand the teller up).
	interaction.claim("teller", func() -> bool: return playing, func() -> void: pass, _on_world_click)
	_add_manager()

## The bank manager at her desk (a runtime character, like the customers; not a word to learn
## beyond her role's tag).
func _add_manager() -> void:
	manager = NpcRegistry.make(town, NpcRegistry.spec(MANAGER_ID), bank, "BankManager")
	manager.set_meta("character_name", "")
	manager.set_meta("talk_camera_at", town.to_global(MANAGER_FACE_CAMERA_AT))
	_manager_presence = Presence.new()
	_manager_presence.name = "ManagerPresence"
	add_child(_manager_presence)
	_manager_presence.setup(manager, player)
	# Between games she chats like any NPC without an activity (npc_chatter.gd).
	if main != null and main.get("npc_chatter") != null:
		main.npc_chatter.attach(manager)

# --- Host hooks and the activity board -------------------------------------------------------

func activity_running() -> bool:
	return playing

func busy() -> bool:
	return host != null and (host.owns_dialogue() or host.is_asking_leave() or zone.fading or (playing and money.visible))

## The banker has no personal name: the box shows his role ("El Banquero").
func _host_speaker() -> Variant:
	return dialogue.speaker_line(str(banker.get_meta("word_key", "banker")), "m")

## Behind the counter the player is far from the banker: his distance never closes a question
## during the game.
func _host_walked_away(distance: float) -> bool:
	return not playing and distance > float(host.spec.walk_away)

## A language change in Settings: the game ends quietly (Main calls this on every session).
func end_activity() -> void:
	if host == null:
		return
	host.cancel_leave()
	if playing:
		_finish(false, false)
	else:
		host.close_dialogue()

# --- The game ---------------------------------------------------------------------------------

## "Yes" on the greeting (or the minigame picker): the fade to window 2 and the first customer.
func start_game() -> void:
	if playing or banker == null:
		return
	playing = true
	_finished = false
	_payouts = 0
	step = ""
	Board.shared().begin(ACTIVITY)
	_plan()
	await zone.fade_through(func() -> void:
		zone.place_player(town, TELLER_SPOT, TELLER_LOOK)
		_sit_down()
		_show_monitor()
		_show_alarm())
	if not playing:
		return
	host.say("teller.start", [], 4.0)
	_call_next()

## Which customers are short of money, which want change and which is an impostor (one of
## each; customer numbers from 0). With a target of 5: customers 0-1 whole hundreds, 2 hundreds
## and fifty, 3 change, 4 any multiple of 5; the short one is 1, 2 or 4, and the impostor (when
## the impostor_chance roll allows one) another of those. Extra customers (after a mistake)
## bring mixed amounts.
func _plan() -> void:
	var target := maxi(1, Board.shared().target(ACTIVITY))
	_spawned = 0
	_change_at = target - 2 if target >= 3 else -1
	var short: Array = []
	for i in range(1, maxi(target, 2)):
		if i != _change_at:
			short.append(i)
	_short_at = -1 if short.is_empty() else int(short[_rng.randi_range(0, short.size() - 1)])
	short.erase(_short_at)
	_impostor_at = -1
	if not short.is_empty() and _rng.randf() < float(data.get("impostor_chance", 0.75)):
		_impostor_at = int(short[_rng.randi_range(0, short.size() - 1)])
	_personas = []

## The amount stage of customer `number` in a session of `target`: "hundreds", "fifties" or
## "mixed" (docs/game/minigames.md, Next, Please! progression).
static func stage_of(number: int, target: int) -> String:
	if number < maxi(1, roundi(target * 0.4)):
		return "hundreds"
	if number < maxi(2, roundi(target * 0.6)):
		return "fifties"
	return "mixed"

## A request in dollars for `stage`, between `low` and `high` (multiples of 100).
static func amount_for(stage: String, rng: RandomNumberGenerator, low := 100, high := 500) -> int:
	match stage:
		"hundreds":
			return rng.randi_range(low / 100, high / 100) * 100
		"fifties":
			return rng.randi_range(low / 100, high / 100 - 1) * 100 + 50
	# Mixed: a multiple of 5 that is not a multiple of 50, so the $10 and $5 bills are needed.
	for attempt in 50:
		var dollars := rng.randi_range(low / 5 + 1, high / 5 - 1) * 5
		if dollars % 50 != 0:
			return dollars
	return low + 35

## The balance on the account: below the request when `short` (by 5 to `short_max`), otherwise
## the request itself (now and then) or more.
static func balance_for(dollars: int, short: bool, rng: RandomNumberGenerator, extra_max := 600, short_max := 100) -> int:
	if short:
		return maxi(5, dollars - rng.randi_range(1, short_max / 5) * 5)
	if rng.randf() < 0.15:
		return dollars
	return dollars + rng.randi_range(1, extra_max / 5) * 5

## Whether a payment of `counts` serves a customer: the exact amount, and for change no $100.
static func paid_right(counts: Dictionary, dollars: int, change: bool) -> bool:
	return Currency.is_exact(counts, dollars * 100) and not (change and int(counts.get("bill_100", 0)) > 0)

func _target() -> int:
	return maxi(1, Board.shared().target(ACTIVITY))

## A new customer at `spot` (town coordinates): who, what they want and how much they have.
func _new_customer(spot: Vector3) -> Dictionary:
	var number := _spawned
	_spawned += 1
	var kind := "change" if number == _change_at else "withdraw"
	var dollars := 0
	if kind == "change":
		var options: Array = data.get("change_dollars", [100, 200])
		dollars = int(options[_rng.randi_range(0, options.size() - 1)])
	else:
		dollars = amount_for(stage_of(number, _target()), _rng, int(data.get("min_dollars", 100)), int(data.get("max_dollars", 500)))
	var short := kind == "withdraw" and number == _short_at
	var impostor := kind == "withdraw" and number == _impostor_at
	var balance := balance_for(dollars, short, _rng, int(data.get("balance_extra_max", 600)), int(data.get("short_max", 100)))
	if _personas.is_empty():
		_personas = Array(data.get("personas", [])).duplicate()
		_personas.shuffle()
	var persona := str(_personas.pop_back())
	# A reason (the persona's story) for most withdrawals; the others just ask (user, 21 Nov 2026).
	var reason := kind == "withdraw" and _rng.randf() < float(data.get("reason_chance", 0.7))
	var plain_asks: Array = data.get("plain_asks", ["plain_ask_1"])
	var plain_thanks: Array = data.get("plain_thanks", ["plain_thanks_1"])
	var spec := _pick_character()
	# An impostor claims someone else's account: a character of another species.
	var claimed := _pick_character(str(spec.scene)) if impostor else spec
	var node: Node3D = HouseCharacters.new().worker(str(spec.scene), "", "person", bank, "TellerCustomer%d" % number,
			town.to_global(spot), _town_direction(Vector3.RIGHT))
	node.set_meta("character_id", str(spec.id))
	node.set_meta("character_name", str(claimed.name))
	node.set_meta("talk_camera_at", town.to_global(FACE_CAMERA_AT))
	var presence = Presence.new()
	presence.name = "CustomerPresence%d" % number
	add_child(presence)
	presence.setup(node, player)
	return {"node": node, "presence": presence, "id": str(spec.id), "name": str(claimed.name), "persona": persona,
			"kind": kind, "dollars": dollars, "balance": balance, "number": number, "missed": false,
			"impostor": impostor, "claim_id": str(claimed.id), "face": species_of(str(claimed.scene)), "real_name": str(spec.name),
			"reason": reason, "ask": "teller.%s" % (persona + "_ask" if reason else str(plain_asks[_rng.randi_range(0, plain_asks.size() - 1)])),
			"thanks": "teller.%s" % (persona + "_thanks" if reason else str(plain_thanks[_rng.randi_range(0, plain_thanks.size() - 1)]))}

## The plush species of a character scene: "res://scenes/characters/pig_plush.tscn" -> "pig"
## (plush_portraits.gd texture()).
static func species_of(scene: String) -> String:
	return scene.get_file().trim_suffix(".tscn").trim_suffix("_plush")

## A house character for the next customer: not skipped, not at the window or in the queue (nor
## an account claimed there), not the last one served. `claim_for`: the scene of an impostor,
## whose claimed account must belong to another species (and is not remembered as served).
func _pick_character(claim_for := "") -> Dictionary:
	var all: Array = HouseCharacters.characters()
	var taken: Array = Array(data.get("skip", [])) + [_last_character, current.get("id", ""), waiting.get("id", ""),
			current.get("claim_id", ""), waiting.get("claim_id", "")]
	if claim_for != "":
		all = all.filter(func(spec) -> bool: return str(spec.get("scene", "")) != claim_for)
	var pool := all.filter(func(spec) -> bool: return not taken.has(str(spec.get("id", ""))))
	if pool.is_empty():
		pool = all
	var spec: Dictionary = pool[_rng.randi_range(0, pool.size() - 1)]
	if claim_for == "":
		_last_character = str(spec.get("id", ""))
	return spec

## The next customer steps up: the one in the queue, or a new one from the queue spot.
func _call_next() -> void:
	if not playing or not current.is_empty():
		return
	if not waiting.is_empty():
		current = waiting
		waiting = {}
	else:
		current = _new_customer(QUEUE_SPOT)
	_set_screen(false)
	var arriving := current
	_walk(current.node, [WINDOW_SPOT], func() -> void:
		if playing and current == arriving:
			_arrived())

func _arrived() -> void:
	current.node.global_basis = Basis.looking_at(_town_direction(Vector3.RIGHT), Vector3.UP)
	PlushLife.play(self, current.node, "nod")
	_ask()
	# The next one joins the queue while this one is served (none after the last one needed).
	if waiting.is_empty() and Board.shared().done(ACTIVITY) + 1 < _target():
		waiting = _new_customer(DOOR_SPOT)
		_walk(waiting.node, [QUEUE_SPOT], func() -> void:
			if not waiting.is_empty() and is_instance_valid(waiting.node):
				waiting.node.global_basis = Basis.looking_at(_town_direction(Vector3.RIGHT), Vector3.UP))

## The customer's request. A withdrawal is asked once, in the account view (24 Nov 2026, user:
## the old second line "I want $300. Do I have enough?" repeated it).
func _ask() -> void:
	step = "ask"
	if current.kind == "change":
		_customer_say("teller.ask", lexicon.line("teller.change_ask", {"amount": _amount(current.dollars)}),
				[host.choice("count", "teller.count_change", "money")])
	else:
		_check_account()

## The account view: the monitor shows the name, the balance and the account holder's photo
## while the customer asks (again, after "Look again"). The replies are the cash and "not
## enough"; the alarm on the counter is no reply (user, 24 Nov 2026: a surprise to find), so
## only the photo tells an impostor apart.
func _check_account() -> void:
	step = "screen"
	_set_screen(true)
	_customer_say(str(current.ask), lexicon.line(str(current.ask), {"amount": _amount(current.dollars)}),
			[host.choice("count", "teller.pay", "money"), host.choice("decline", "teller.decline", "no")], true)

func _on_choice(id: String) -> void:
	if not playing:
		return
	if step == "manager":
		match id.trim_prefix(host.choice_prefix()):
			"sorry":
				_manager_leaves()
			"fired":
				_finish(false, true, true)
		return
	if current.is_empty():
		return
	match id.trim_prefix(host.choice_prefix()):
		"check", "again":
			if current.kind == "change":
				_ask()
			else:
				_check_account()
		"police":
			_call_police()
		"count":
			# An impostor's (claimed) account always has enough: the cash can go (23 Nov 2026).
			if current.kind == "withdraw" and current.balance < current.dollars:
				# Counting out more than the account holds.
				_miss()
				_mistake("teller.pay_wrong", {"amount": _amount(current.dollars)}, "again", "teller.look_again", true)
			else:
				_open_money()
		"retry":
			_open_money()
		"decline":
			_decline()
		"next":
			_send_off()

## "Sorry, not enough": right when the account is short, otherwise the customer protests.
func _decline() -> void:
	if current.get("impostor", false):
		_impostor_missed()
		return
	if current.balance >= current.dollars:
		_miss()
		_mistake("teller.decline_wrong", {}, "again", "teller.look_again", true)
		return
	# The teller says it (a close-up of the player), then the customer cannot believe it.
	step = "declined"
	var line: Dictionary = lexicon.line("teller.no_funds")
	_say_as(_player_speaker(), null, "teller.no_funds", line, [])
	_player_close_up()
	_later(_read_time(line), "declined", func() -> void:
		PlushLife.play(self, current.node, "shake")
		_served("teller.impossible"))

## The alarm: right for an impostor, who owns up; a police officer walks in from the door and
## stops beside them. An honest customer protests ("Look at the photo!").
func _call_police() -> void:
	if not current.get("impostor", false):
		_miss()
		_mistake("teller.police_wrong", {}, "again", "teller.look_again", true)
		return
	step = "escort"
	_set_screen(false)
	# No words while the officer walks in: the camera stays on the impostor.
	_prompt = []
	host.close_dialogue()
	_close_up(current.presence)
	var officer: Node3D = HouseCharacters.new().worker(OFFICER_SCENE, "police", "police officer", bank, "TellerOfficer%d" % current.number,
			town.to_global(DOOR_SPOT), _town_direction(Vector3.LEFT))
	officer.set_meta("talk_camera_at", town.to_global(OFFICER_FACE_CAMERA_AT))
	var presence = Presence.new()
	presence.name = "OfficerPresence%d" % current.number
	add_child(presence)
	presence.setup(officer, player)
	current.officer = officer
	current.officer_presence = presence
	var caught := current
	_walk(officer, OFFICER_IN, func() -> void:
		if playing and current == caught:
			_officer_arrived())

## The officer reaches the window: officer and impostor face each other. "Excuse me. Please come
## with me." "What's happening?" "Please come with me now." (user, 21 Nov 2026); the customer
## counts (when no mistake came first).
func _officer_arrived() -> void:
	var officer: Node3D = current.officer
	var to_customer: Vector3 = current.node.global_position - officer.global_position
	to_customer.y = 0.0
	officer.global_basis = Basis.looking_at(to_customer.normalized(), Vector3.UP)
	current.node.global_basis = Basis.looking_at(-to_customer.normalized(), Vector3.UP)
	PlushLife.play(self, officer, "nod")
	var officer_speaker: Dictionary = dialogue.speaker_line("police officer", "f")
	var excuse: Dictionary = lexicon.line("teller.officer_excuse")
	_say_as(officer_speaker, current.officer_presence, "teller.officer_excuse", excuse, [])
	_later(_read_time(excuse), "escort", func() -> void:
		PlushLife.play(self, current.node, "tilt")
		var what: Dictionary = lexicon.line("teller.impostor_what")
		_customer_say("teller.impostor_what", what, [])
		_later(_read_time(what), "escort", func() -> void:
			PlushLife.play(self, current.officer, "nod")
			_served("teller.officer_now", officer_speaker, current.officer_presence)))

## Calls `then` after `seconds` if the same customer is still at the window in `expect`.
func _later(seconds: float, expect: String, then: Callable) -> void:
	var customer := current
	get_tree().create_timer(seconds).timeout.connect(func() -> void:
		if playing and current == customer and step == expect:
			then.call())

## How long a line without a button stays (its foreign text's length).
func _read_time(line: Dictionary) -> float:
	return minf(READ_BASE + str(line.get("foreign", "")).length() * READ_PER_CHAR, READ_MAX)

## The player as a speaker: the profile's name.
func _player_speaker() -> Dictionary:
	var name := str(ProfileManager.shared().active_profile().get("name", ""))
	if name == "":
		return lexicon.line("teller.you")
	return {"foreign": name, "native": name}

## A close-up of the player behind the window, from the customer's side of the desk.
func _player_close_up() -> void:
	_close_up(null)
	_self_view = true
	_show_self()
	var model := player.get("visual") as Node3D
	var top := player.global_position.y + 1.2
	if model != null:
		var first := true
		for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			if mesh.mesh != null and mesh.is_visible_in_tree():
				var box: AABB = mesh.global_transform * mesh.mesh.get_aabb()
				top = box.end.y if first else maxf(top, box.end.y)
				first = false
	var face := Vector3(player.global_position.x, top - 0.45, player.global_position.z)
	var eye := town.to_global(PLAYER_FACE_EYE)
	eye.y = face.y + PLAYER_FACE_LIFT
	# Look below the face so it sits high on the screen.
	var drop := eye.distance_to(face) * tan(deg_to_rad(PLAYER_FACE_FOV) * 0.5) * (0.5 - PLAYER_FACE_SCREEN_Y) * 2.0
	var at := face - Vector3(0, drop, 0)
	_camera_at(Transform3D(Basis.looking_at(at - eye, Vector3.UP), eye), PLAYER_FACE_FOV)
	_self_view = true

## "Not enough" for an impostor: the banker steps in and points at the photo; the customer no
## longer counts. (Counting out the cash for one is _impostor_paid().)
func _impostor_missed() -> void:
	_miss()
	step = "fix"
	_say_as(_host_speaker(), null, "teller.impostor_warn", lexicon.line("teller.impostor_warn"),
			[host.choice("again", "teller.look_again", "retry")], true)

## Paid out to an impostor (user, 23 Nov 2026): the cash goes, the impostor thanks the teller and
## leaves happily (no longer counting), and the manager comes out: a warning the first time, the
## end of the shift the second time (data/bank_teller.json payouts_to_fire). After a warning
## another impostor comes later in the session (impostor_again), a chance to catch one.
func _impostor_paid() -> void:
	_miss()
	_payouts += 1
	var fire := _payouts >= int(data.get("payouts_to_fire", 2))
	if not fire and bool(data.get("impostor_again", true)):
		_another_impostor()
	step = "paid_out"
	PlushLife.play(self, current.node, "hop")
	var thanks: Dictionary = lexicon.line("teller.impostor_thanks")
	_customer_say("teller.impostor_thanks", thanks, [])
	_later(_read_time(thanks), "paid_out", func() -> void:
		var leaving := current
		current = {}
		_close_up(null)
		host.close_dialogue()
		_leaving.append(leaving)
		_walk(leaving.node, EXIT_PATH, func() -> void: _remove(leaving))
		_manager_comes(fire))

## The next customer not yet in the bank (and not the change or short one) is an impostor.
func _another_impostor() -> void:
	var number := _spawned
	while number == _change_at or number == _short_at:
		number += 1
	_impostor_at = number

## The manager's walk: the camera looks along the teller area while she comes through the staff
## door and stops beside the teller; the teller turns to her.
func _manager_comes(fire: bool) -> void:
	step = "manager"
	_prompt = []
	if manager == null or not is_instance_valid(manager):
		if fire:
			_finish(false, true, true)
		else:
			step = ""
			_call_next()
		return
	_scene_camera()
	_staff_door(true)
	_walk(manager, [MANAGER_DOOR, MANAGER_SPOT], func() -> void:
		if playing and step == "manager":
			_manager_arrived(fire))

func _manager_arrived(fire: bool) -> void:
	var to_player := player.global_position - manager.global_position
	to_player.y = 0.0
	manager.global_basis = Basis.looking_at(to_player.normalized(), Vector3.UP)
	_turn_player(-to_player)
	PlushLife.play(self, manager, "shake")
	var first_id := "teller.manager_fired_1" if fire else "teller.manager_warn_1"
	var first: Dictionary = lexicon.line(first_id)
	_say_as(_manager_speaker(), _manager_presence, first_id, first, [])
	_after(_read_time(first), "manager", func() -> void:
		var second_id := "teller.manager_fired_2" if fire else "teller.manager_warn_2"
		var answer: Dictionary = host.choice("fired", "teller.manager_okay", "next") if fire else host.choice("sorry", "teller.manager_sorry", "next")
		_say_as(_manager_speaker(), _manager_presence, second_id, lexicon.line(second_id), [answer]))

## "Sorry, I'll check the photo": she walks back to her desk; once she is through the door the
## door closes behind her and the next customer steps up.
func _manager_leaves() -> void:
	step = "manager_back"
	_prompt = []
	_close_up(null)
	host.close_dialogue()
	_scene_camera()
	PlushLife.play(self, manager, "nod")
	_walk(manager, [MANAGER_DOOR], func() -> void:
		_staff_door(false)
		_walk(manager, [MANAGER_HOME], func() -> void: _manager_home())
		if playing and step == "manager_back":
			step = ""
			_turn_player(_town_direction(TELLER_LOOK))
			_monitor_camera(false)
			_call_next())

## The manager back at her desk (also when the game ends mid-scene) and the staff door shut.
func _manager_home() -> void:
	if manager == null or not is_instance_valid(manager):
		return
	_walkers = _walkers.filter(func(walker) -> bool: return walker.node != manager)
	var base := manager.global_position.y
	manager.global_position = town.to_global(MANAGER_HOME)
	manager.global_position.y = base
	manager.global_basis = Basis.looking_at(_town_direction(MANAGER_LOOK), Vector3.UP)
	_manager_presence.zoom_to_face(false)
	_staff_door(false)

func _manager_speaker() -> Dictionary:
	return dialogue.speaker_line(MANAGER_WORD, MANAGER_GENDER)

## Opens or shuts the staff door (bank.gd staff_door) through the shared door registry.
func _staff_door(open: bool) -> void:
	var leaf := bank.get_node_or_null(STAFF_DOOR_LEAF)
	if leaf != null and main.doors.has(leaf):
		if bool(main.doors[leaf]["open"]) != open:
			# The door's own sound, as when the player uses it (door_animator.gd, 25 Nov 2026).
			preload("res://scripts/core/door_animator.gd").play_sound(leaf, main.doors[leaf], open)
		main.doors[leaf]["open"] = open

## The cutscene camera along the teller area.
func _scene_camera() -> void:
	_close_up(null)
	var eye := town.to_global(SCENE_EYE)
	var at := town.to_global(SCENE_AT)
	_camera_at(Transform3D(Basis.looking_at(at - eye, Vector3.UP), eye), SCENE_FOV)
	_self_view = true

## Turns the player (behind the counter) to face `direction` (global).
func _turn_player(direction: Vector3) -> void:
	direction.y = 0.0
	if direction.length() < 0.01:
		return
	var yaw := atan2(-direction.x, -direction.z)
	player.rotation.y = yaw
	player.camera_yaw = yaw

## Calls `then` after `seconds` if the game is still in `expect` (scenes with no customer).
func _after(seconds: float, expect: String, then: Callable) -> void:
	get_tree().create_timer(seconds).timeout.connect(func() -> void:
		if playing and step == expect:
			then.call())

## A mistake with this customer: the customer no longer counts, and the session reports one
## miss per customer (Board.add_miss, read by game_progress.gd for a game with levels).
func _miss() -> void:
	if not current.missed:
		current.missed = true
		Board.shared().add_miss(ACTIVITY)

## `account`: a mistake about the account (the account view stays: monitor and customer).
func _mistake(id: String, values: Dictionary, retry: String, label: String, account := false) -> void:
	step = "fix"
	PlushLife.play(self, current.node, "tilt")
	_customer_say(id, lexicon.line(id, values), [host.choice(retry, label, "retry")], account)

func _open_money() -> void:
	step = "count"
	_close_up(null)
	host.close_dialogue()
	money.show_native = panel.show_native
	interaction.clear_card()
	var change: bool = current.kind == "change"
	money.open({
		"request": lexicon.line("teller.panel_change" if change else "teller.panel_request", {"name": current.name, "amount": _amount(current.dollars)}),
		"tray_title": lexicon.line("teller.tray", {"name": current.name}),
		"bills": lexicon.line("money.bills"),
		"coins": lexicon.line("money.coins"),
		"total": lexicon.line("money.total"),
		"submit": lexicon.line("money.submit"),
		"clear": lexicon.line("money.clear"),
		"close": lexicon.line("money.close"),
		"translate": lexicon.line("common.show_translation"),
		"only": data.get("notes", []),
		"hint": GameSettings.shared().inline(lexicon.line("teller.hint_change"), panel.show_native) if change else "",
	})
	money.set_progress(Board.shared().done(ACTIVITY), _target())

## Hand over on the money screen.
func _on_submitted(cents: int) -> void:
	if not playing or step != "count" or not money.visible:
		return
	money.hide_panel()
	var change: bool = current.kind == "change"
	if paid_right(money.counts, int(current.dollars), change):
		money.reset()
		if current.get("impostor", false):
			_impostor_paid()
			return
		PlushLife.play(self, current.node, "hop")
		_served("teller.change_thanks" if change else str(current.thanks))
		return
	_miss()
	if change and Currency.is_exact(money.counts, int(current.dollars) * 100):
		_mistake("teller.change_hundred", {}, "retry", "teller.try_again")
	else:
		_mistake("teller.wrong_amount", {"given": _amount(cents / 100.0), "amount": _amount(current.dollars)}, "retry", "teller.try_again")

## Served right (paid exactly, a short account declined, an impostor caught): counts when right
## the first time; at the target the window closes after this customer. `speaker` / `presence`:
## someone other than the customer says the line (the police officer). The line has no button
## and moves on by itself after its reading time (user, 24 Nov 2026: no "Next!" click).
func _served(id: String, speaker: Variant = null, presence: Variant = null) -> void:
	step = "served"
	if not current.missed and Board.shared().add_success(ACTIVITY):
		_finished = true
	var line: Dictionary = lexicon.line(id)
	if speaker == null:
		_customer_say(id, line, [])
	else:
		_say_as(speaker, presence, id, line, [])
	_send_off_after(_read_time(line))

## "Next!" by itself after `seconds`; while the leave question is open it waits for the answer.
func _send_off_after(seconds: float) -> void:
	_later(seconds, "served", func() -> void:
		if host.is_asking_leave():
			_send_off_after(0.5)
		else:
			_send_off())

## "Next!": the customer walks out; the next one steps up, or the game ends.
func _send_off() -> void:
	var leaving := current
	current = {}
	step = ""
	_close_up(null)
	host.close_dialogue()
	_leaving.append(leaving)
	var officer: Node3D = leaving.get("officer")
	if officer != null and is_instance_valid(officer):
		# Escorted: the impostor walks out first, the officer a step behind; both go at the door.
		_walk(leaving.node, EXIT_PATH, func() -> void:
			if is_instance_valid(leaving.node):
				leaving.node.visible = false)
		get_tree().create_timer(OFFICER_LAG).timeout.connect(func() -> void:
			if is_instance_valid(officer):
				_walk(officer, EXIT_PATH, func() -> void: _remove(leaving)))
	else:
		_walk(leaving.node, EXIT_PATH, func() -> void: _remove(leaving))
	if _finished:
		_finish(true)
	else:
		_call_next()

## The game is over (`complete`: the target was reached): fade back to the banker, who thanks the
## player (`speak`), and clear the customers and the monitor. `fired`: the manager let the player
## go (a second impostor paid): the "let go" results card instead of the banker's thanks, and
## the banker offers the game again only on a later visit.
func _finish(complete: bool, speak := true, fired := false) -> void:
	playing = false
	step = ""
	host.cancel_leave()
	host.abandon_practice()
	money.reset()
	money.hide_panel()
	_close_up(null)
	host.close_dialogue()
	if complete or fired:
		offered = false
	var clear := func() -> void:
		_manager_home()
		for customer in [current, waiting] + _leaving:
			_remove(customer)
		current = {}
		waiting = {}
		_leaving.clear()
		_walkers.clear()
		_hide_monitor()
		if _alarm != null:
			_alarm.visible = false
		_self_view = false
		_show_self()
		_stand_up()
		host.place_player_near()
	if not speak:
		clear.call()
		return
	await zone.fade_through(clear)
	if fired:
		main.results_screen.set_meta("results_owner", ACTIVITY)
		main.results_screen.show_results({"activity": ACTIVITY, "title": UiText.t("results.title_teller_fired"),
				"line": UiText.t("results.line_teller_fired"), "words": {}, "rewards": [], "replay": false})
		return
	host.zoom(true)
	host.say("teller.complete" if complete else "teller.stopped")

func _remove(customer: Dictionary) -> void:
	if customer.is_empty():
		return
	_leaving.erase(customer)
	for key in ["presence", "officer_presence"]:
		var presence = customer.get(key)
		if presence != null and is_instance_valid(presence):
			presence.zoom_to_face(false)
			presence.queue_free()
	for key in ["node", "officer"]:
		if is_instance_valid(customer.get(key)):
			customer[key].queue_free()

# --- Leaving mid-game ---------------------------------------------------------------------------

## ✕ or Esc on a customer's question: the leave question.
func _on_talk_closed(line_id: String) -> void:
	if playing and not zone.fading and not _prompt.is_empty() and line_id == str(_prompt[0]):
		_close_up(null)
		host.ask_leave()

## Close or ✕ on the money screen: the leave question; "no" returns with the tray intact.
func _on_money_close() -> void:
	if not playing or step != "count":
		return
	money.hide_panel()
	host.ask_leave()

func _on_leave_answered(leave: bool) -> void:
	if not playing:
		return
	if leave:
		_finish(false)
		return
	if step == "count":
		_open_money()
	elif not _prompt.is_empty() and (not current.is_empty() or step == "manager"):
		_say_as(_prompt[4], _prompt[5], str(_prompt[0]), _prompt[1], _prompt[2], bool(_prompt[3]))

# --- Dialogue and cameras ----------------------------------------------------------------------

## An amount for a phrase: words in the foreign language, digits in the native line.
func _amount(dollars: float) -> Dictionary:
	return dialogue.money_values(roundi(dollars * 100.0))

## The customer at the window says `line`; the camera frames their face, or the monitor while
## the player reads the balance (`monitor`).
func _customer_say(id: String, line: Dictionary, choices: Array, monitor := false) -> void:
	_say_as({"foreign": current.name, "native": current.name}, current.presence, id, line, choices, monitor)

## `speaker` says `line`; the camera frames `presence`'s face (null: none), or the monitor.
func _say_as(speaker: Variant, presence: Variant, id: String, line: Dictionary, choices: Array, monitor := false) -> void:
	_prompt = [id, line, choices, monitor, speaker, presence]
	_self_view = false
	host.show_line(id, line, choices, 0.0, speaker)
	_close_up(null if monitor else presence)
	_monitor_camera(monitor)

## The face close-up on one customer or officer (null: none).
func _close_up(presence) -> void:
	for customer in [current, waiting] + _leaving:
		for key in ["presence", "officer_presence"]:
			var other = customer.get(key)
			if other != null and is_instance_valid(other) and other != presence:
				other.zoom_to_face(false)
	if _manager_presence != null and _manager_presence != presence:
		_manager_presence.zoom_to_face(false)
	if presence != null and is_instance_valid(presence):
		_monitor_camera(false)
		presence.zoom_to_face(true)

## The game's own fixed camera (the account view, the player's close-up, the manager's walk) at
## `view` (global).
func _camera_at(view: Transform3D, fov := VIEW_FOV) -> void:
	if _camera == null:
		_camera = Camera3D.new()
		_camera.name = "TellerMonitorCamera"
		add_child(_camera)
	_camera.fov = fov
	_camera.global_transform = view
	if not _camera.current:
		# Back to the player's own camera afterwards (a face close-up may still be easing out).
		_previous_camera = player.get("camera") as Camera3D
		_camera.make_current()

## The account view while the balance is read: the monitor and the customer at once (off: back
## to the player's own camera).
func _monitor_camera(on: bool) -> void:
	if on:
		var eye := town.to_global(VIEW_EYE)
		var at := town.to_global(VIEW_AT)
		_camera_at(Transform3D(Basis.looking_at(at - eye, Vector3.UP), eye), VIEW_FOV)
	elif _camera != null and _camera.current:
		if _previous_camera != null and is_instance_valid(_previous_camera):
			_previous_camera.make_current()
		else:
			_camera.clear_current()

# --- The monitor -----------------------------------------------------------------------------

## A screen on window 2's monitor (in-world text in the foreign language, BonStyle colours).
func _show_monitor() -> void:
	if _monitor == null:
		_monitor = Node3D.new()
		_monitor.name = "TellerScreen"
		bank.add_child(_monitor)
		var glow := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = MONITOR_SIZE
		glow.mesh = quad
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = BonStyle.SKY_TOP
		glow.material_override = material
		glow.position.z = 0.004
		_monitor.add_child(glow)
		# The headshot, top left: a pale card with the account holder's portrait on it.
		_screen_card = MeshInstance3D.new()
		var card := QuadMesh.new()
		card.size = Vector2(PHOTO_SIZE, PHOTO_SIZE)
		_screen_card.mesh = card
		var card_material := StandardMaterial3D.new()
		card_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		card_material.albedo_color = BonStyle.CREAM
		_screen_card.material_override = card_material
		_screen_card.position = Vector3(PHOTO_AT.x, PHOTO_AT.y, 0.006)
		_monitor.add_child(_screen_card)
		_screen_photo = Sprite3D.new()
		_screen_photo.shaded = false
		_screen_photo.double_sided = false
		_screen_photo.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		_screen_photo.position = Vector3(PHOTO_AT.x, PHOTO_AT.y, 0.008)
		_monitor.add_child(_screen_photo)
		_screen_top = _screen_label(26, BonStyle.INK_SOFT, 0.09)
		_screen_top.position.x = TEXT_AT.x
		_screen_top.width = TEXT_WIDTH / _screen_top.pixel_size
		_screen_word = _screen_label(26, BonStyle.INK_SOFT, 0.005)
		_screen_word.position.x = TEXT_AT.x
		_screen_amount = _screen_label(56, BonStyle.INK, -0.085)
		_screen_idle = _screen_label(34, BonStyle.INK, 0.0)
		_bind(_screen_word, "teller.screen_balance")
		_bind(_screen_idle, "teller.screen_idle")
	# Local +z (the label's front) out of the monitor's face, toward the teller's view.
	var facing := monitor_facing()
	_monitor.global_transform = town.global_transform * Transform3D(Basis.looking_at(-facing, Vector3.UP), MONITOR_CENTRE + facing * MONITOR_FACE)
	_monitor.visible = true
	_set_screen(false)

## The direction window 2's monitor faces (town coordinates).
static func monitor_facing() -> Vector3:
	return Basis(Vector3.UP, deg_to_rad(MONITOR_YAW)) * Vector3.RIGHT

func _screen_label(size: int, colour: Color, y: float) -> Label3D:
	var label := Label3D.new()
	label.font = BonStyle.font(700)
	label.font_size = size
	label.pixel_size = 0.0016
	label.modulate = colour
	label.outline_size = 0
	label.shaded = false
	label.double_sided = false
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.width = MONITOR_SIZE.x / label.pixel_size * 0.92
	label.position = Vector3(0, y, 0.008)
	_monitor.add_child(label)
	return label

## The monitor's text: the window number, or the current customer's account (the name and
## "Balance" beside the account holder's headshot, the balance in digits underneath). The words
## are world labels: they follow the world language, so EN shows them in the native one.
func _set_screen(account: bool) -> void:
	if _monitor == null:
		return
	_account_shown = account and not current.is_empty()
	for node in [_screen_card, _screen_photo, _screen_top, _screen_word, _screen_amount]:
		node.visible = _account_shown
	_screen_idle.visible = not _account_shown
	if _account_shown:
		if _portraits == null:
			_portraits = PlushPortraits.new()
			_portraits.name = "TellerPortraits"
			add_child(_portraits)
		var photo: Texture2D = _portraits.texture(str(current.get("face", "")))
		_screen_photo.texture = photo
		if photo != null:
			_screen_photo.pixel_size = PHOTO_SIZE * 0.94 / float(photo.get_width())
		_bind(_screen_top, "teller.screen_account", {"name": current.name})
		_screen_amount.text = Currency.usd(int(current.balance) * 100)

## `label` shows phrase `id` in the world language from now on (and after a language change).
func _bind(label: Label3D, id: String, values := {}) -> void:
	LiveLabels.bind(label, {"phrase": id, "values": values})
	LiveLabels.apply(label, GameSettings.shared().world_language())

func _hide_monitor() -> void:
	_monitor_camera(false)
	if _monitor != null:
		_monitor.visible = false

# --- The teller's chair and the alarm ----------------------------------------------------------

## Seats the player on window 2's chair (behind the fade). Without the chair (an older bank
## scene) the player stands at TELLER_SPOT as before.
func _sit_down() -> void:
	var chair := bank.get_node_or_null(TELLER_SEAT) as Node3D
	if chair == null or main.get("seating") == null:
		push_warning("teller_session: no seat " + TELLER_SEAT)
		return
	main.seating.sit_at(chair, chair.to_local(town.to_global(TELLER_SPOT)))

## Off the chair at once at the end of the game, behind the fade (the seat's own standing up is a
## short slide toward a free spot, which would pull the player back after they are placed by
## the banker).
func _stand_up() -> void:
	if not player.get("seated") and not player.get("sit_transition"):
		return
	var slide = player.get("sit_tween")
	if slide is Tween and slide.is_valid():
		slide.kill()
	player.finish_standing()
	if main.get("seating") != null:
		main.seating.current = {}

## BonBon's model: hidden while seated in the teller's own views (the account view sits where
## the head is), shown otherwise.
func _show_self() -> void:
	var model := player.get("visual") as Node3D
	if model != null:
		model.visible = _self_view or not playing or not player.get("seated")

## The red alarm button on the counter: a dark base and a red cap (a runtime prop like the
## monitor's screen; no word, no collision: a click is tested against it directly).
func _show_alarm() -> void:
	if _alarm == null:
		_alarm = Node3D.new()
		_alarm.name = "TellerAlarm"
		bank.add_child(_alarm)
		var base := MeshInstance3D.new()
		var base_mesh := CylinderMesh.new()
		base_mesh.top_radius = ALARM_RADIUS * 1.5
		base_mesh.bottom_radius = ALARM_RADIUS * 1.6
		base_mesh.height = 0.02
		base.mesh = base_mesh
		base.position.y = 0.01
		base.material_override = main.material_for(Color("2d2f3a"))
		_alarm.add_child(base)
		var cap := MeshInstance3D.new()
		var cap_mesh := SphereMesh.new()
		cap_mesh.radius = ALARM_RADIUS
		cap_mesh.height = ALARM_RADIUS * 1.2
		cap.mesh = cap_mesh
		cap.position.y = 0.022
		var red := StandardMaterial3D.new()
		red.albedo_color = BonStyle.CORAL_BOTTOM
		red.emission_enabled = true
		red.emission = BonStyle.CORAL_BOTTOM
		red.emission_energy_multiplier = 0.25
		cap.material_override = red
		_alarm.add_child(cap)
	_alarm.global_transform = town.global_transform * Transform3D(Basis(), ALARM_AT)
	_alarm.visible = true

## A click or tap in the world while the game runs: on the alarm, while a customer waits for an
## answer at the window, it calls the police; elsewhere nothing.
func _on_world_click() -> void:
	if not playing or current.is_empty() or not (step in ["screen", "fix"]) or _alarm == null:
		return
	if alarm_aimed(get_viewport().get_camera_3d(), _pointer()):
		_press_alarm()

## The pointer (the screen centre while the mouse is captured), as the interaction controller aims.
func _pointer() -> Vector2:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		return get_viewport().get_visible_rect().size * 0.5
	return interaction.pointer_position

## Whether `view`'s ray through `pointer` passes within ALARM_HIT radii of the button's cap (a
## generous target, easy to tap on a phone).
const ALARM_HIT := 2.4

func alarm_aimed(view: Camera3D, pointer: Vector2) -> bool:
	if view == null or _alarm == null or not _alarm.visible:
		return false
	var origin := view.project_ray_origin(pointer)
	var direction := view.project_ray_normal(pointer)
	var to := _alarm.to_global(Vector3(0, 0.022, 0)) - origin
	var along := to.dot(direction)
	if along <= 0.0:
		return false
	var reach := ALARM_RADIUS * ALARM_HIT * _alarm.global_basis.get_scale().x
	return (to - direction * along).length() <= reach

func _press_alarm() -> void:
	var cap := _alarm.get_child(1) as Node3D
	var press := create_tween()
	press.tween_property(cap, "position:y", 0.012, 0.08)
	press.tween_property(cap, "position:y", 0.022, 0.15)
	_call_police()

# --- Walking ---------------------------------------------------------------------------------

## A direction given in town coordinates, as a flat global direction.
func _town_direction(direction: Vector3) -> Vector3:
	var global := town.global_basis * direction
	global.y = 0.0
	return global.normalized()

## Walks `node` through `points` (town coordinates) with a small bounce, then calls `then`.
func _walk(node: Node3D, points: Array, then: Callable) -> void:
	_walkers = _walkers.filter(func(walker) -> bool: return walker.node != node)
	_walkers.append({"node": node, "path": points.map(func(p) -> Vector3: return town.to_global(p)),
			"base_y": node.global_position.y, "time": 0.0, "then": then})

func _step_walkers(delta: float) -> void:
	for walker in _walkers.duplicate():
		var node: Node3D = walker.node
		if not is_instance_valid(node):
			_walkers.erase(walker)
			continue
		var at := Vector3(node.global_position.x, walker.base_y, node.global_position.z)
		var target: Vector3 = walker.path[0]
		target.y = walker.base_y
		var to := target - at
		var stride := WALK_SPEED * delta
		walker.time += delta
		if to.length() <= stride:
			at = target
			walker.path.pop_front()
		else:
			at += to.normalized() * stride
			node.global_basis = Basis.looking_at(to.normalized(), Vector3.UP)
		node.global_position = at + Vector3(0, absf(sin(walker.time * 9.0)) * BOUNCE, 0)
		if walker.path.is_empty():
			node.global_position = at
			_walkers.erase(walker)
			walker.then.call()

func _process(delta: float) -> void:
	if host == null:
		return
	if not _walkers.is_empty():
		_step_walkers(delta)
	if playing:
		_show_self()
	host.tick(delta)
