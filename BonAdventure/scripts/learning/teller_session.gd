extends Node
## Bank teller game (activity "teller_bank", 18 Nov 2026; design: docs/guides/TOWN_DESIGN_BRIEF.md
## "Bank teller game", purpose and progression: docs/game/minigames.md). The bear banker at the
## bank's reception asks the player to cover teller window 2. The screen fades and the player
## stands behind the window; plush customers (house characters) come up from the queue ropes one
## at a time:
##   - a withdrawal: the customer asks for an amount in words ($100-$500, multiples of 5).
##     "Check the account" turns the camera to the window's monitor, which shows the balance in
##     digits; the teller then counts out the cash (the shared money screen, $5/$10/$50/$100
##     bills only) or says "not enough" (one customer per session is short);
##   - change (one customer per session): whole hundreds paid back without $100 bills.
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
const WINDOW_SPOT := Vector3(135.75, 0.03, 107.7)
const QUEUE_SPOT := Vector3(133.2, 0.03, 107.75)
const DOOR_SPOT := Vector3(127.6, 0.03, 108.0)
## Out past the rope at z 109.5 and the reception desk (z above 110.6 near x 129).
const EXIT_PATH := [Vector3(135.4, 0.03, 110.5), Vector3(128.6, 0.03, 109.9), Vector3(127.2, 0.03, 108.6)]
## The customer's talk camera: from the teller's side, above the glass, looking down at the face.
const FACE_CAMERA_AT := Vector3(139.0, 2.75, 107.3)
## Window 2's monitor: screen centre (its face looks +x, toward the teller) and size, and the
## close-up camera's eye.
const MONITOR_AT := Vector3(137.24, 1.41, 107.7)
const MONITOR_SIZE := Vector2(0.46, 0.29)
const MONITOR_EYE := Vector3(137.98, 1.5, 107.7)
const MONITOR_FOV := 42.0
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
## persona, kind ("withdraw" or "change"), dollars, balance, number, missed}.
var current: Dictionary = {}
var waiting: Dictionary = {}
## Customers who have left the window and are walking out.
var _leaving: Array = []
var _walkers: Array = []
var _spawned := 0
var _short_at := -1
var _change_at := -1
var _personas: Array = []
var _last_character := ""
var _finished := false
## The last question in the box, re-asked after "No, I'll keep serving": [id, line, choices, monitor].
var _prompt: Array = []
var _monitor: Node3D
var _screen_top: Label3D
var _screen_amount: Label3D
var _camera: Camera3D
var _previous_camera: Camera3D
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
	step = ""
	Board.shared().begin(ACTIVITY)
	_plan()
	await zone.fade_through(func() -> void:
		zone.place_player(town, TELLER_SPOT, TELLER_LOOK)
		_show_monitor())
	if not playing:
		return
	host.say("teller.start", [], 4.0)
	_call_next()

## Which customers are short of money and which want change (one of each; customer numbers
## from 0). With a target of 5: customers 0-1 whole hundreds, 2 hundreds and fifty, 3 change,
## 4 any multiple of 5; the short one is 1, 2 or 4. Extra customers (after a mistake) bring
## mixed amounts.
func _plan() -> void:
	var target := maxi(1, Board.shared().target(ACTIVITY))
	_spawned = 0
	_change_at = target - 2 if target >= 3 else -1
	var short: Array = []
	for i in range(1, maxi(target, 2)):
		if i != _change_at:
			short.append(i)
	_short_at = -1 if short.is_empty() else int(short[_rng.randi_range(0, short.size() - 1)])
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
	var balance := balance_for(dollars, short, _rng, int(data.get("balance_extra_max", 600)), int(data.get("short_max", 100)))
	if _personas.is_empty():
		_personas = Array(data.get("personas", [])).duplicate()
		_personas.shuffle()
	var persona := str(_personas.pop_back())
	var spec := _pick_character()
	var node: Node3D = HouseCharacters.new().worker(str(spec.scene), "", "person", bank, "TellerCustomer%d" % number,
			town.to_global(spot), _town_direction(Vector3.RIGHT))
	node.set_meta("character_id", str(spec.id))
	node.set_meta("character_name", str(spec.name))
	node.set_meta("talk_camera_at", town.to_global(FACE_CAMERA_AT))
	var presence = Presence.new()
	presence.name = "CustomerPresence%d" % number
	add_child(presence)
	presence.setup(node, player)
	return {"node": node, "presence": presence, "id": str(spec.id), "name": str(spec.name), "persona": persona,
			"kind": kind, "dollars": dollars, "balance": balance, "number": number, "missed": false}

## A house character for the next customer: not skipped, not at the window or in the queue,
## not the last one served.
func _pick_character() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(HouseCharacters.DATA))
	var all: Array = parsed.get("characters", []) if parsed is Dictionary else []
	var taken: Array = Array(data.get("skip", [])) + [_last_character, current.get("id", ""), waiting.get("id", "")]
	var pool := all.filter(func(spec) -> bool: return not taken.has(str(spec.get("id", ""))))
	if pool.is_empty():
		pool = all
	var spec: Dictionary = pool[_rng.randi_range(0, pool.size() - 1)]
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

## The customer's request.
func _ask() -> void:
	step = "ask"
	if current.kind == "change":
		_customer_say("teller.ask", lexicon.line("teller.change_ask", {"amount": _amount(current.dollars)}),
				[host.choice("count", "teller.count_change", "money")])
	else:
		_customer_say("teller.ask", lexicon.line("teller.%s_ask" % current.persona, {"amount": _amount(current.dollars)}),
				[host.choice("check", "teller.check", "look")])

## "Check the account": the monitor shows the balance; the customer asks whether it is enough.
func _check_account() -> void:
	step = "screen"
	_set_screen(true)
	_customer_say("teller.screen", lexicon.line("teller.enough_q", {"amount": _amount(current.dollars)}),
			[host.choice("count", "teller.pay", "money"), host.choice("decline", "teller.decline", "no")], true)

func _on_choice(id: String) -> void:
	if not playing or current.is_empty():
		return
	match id.trim_prefix(host.choice_prefix()):
		"check", "again":
			_check_account()
		"count":
			if current.kind == "withdraw" and current.balance < current.dollars:
				# Counting out more than the account holds.
				_miss()
				_mistake("teller.pay_wrong", {"amount": _amount(current.dollars)}, "again", "teller.look_again")
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
	if current.balance >= current.dollars:
		_miss()
		_mistake("teller.decline_wrong", {}, "again", "teller.look_again")
		return
	PlushLife.play(self, current.node, "shake")
	_served("teller.%s_sad" % current.persona)

## A mistake with this customer: the customer no longer counts, and the session reports one
## miss per customer (Board.add_miss, read by game_progress.gd for a game with levels).
func _miss() -> void:
	if not current.missed:
		current.missed = true
		Board.shared().add_miss(ACTIVITY)

func _mistake(id: String, values: Dictionary, retry: String, label: String) -> void:
	step = "fix"
	PlushLife.play(self, current.node, "tilt")
	_customer_say(id, lexicon.line(id, values), [host.choice(retry, label, "retry")])

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
		PlushLife.play(self, current.node, "hop")
		_served("teller.change_thanks" if change else "teller.%s_thanks" % current.persona)
		return
	_miss()
	if change and Currency.is_exact(money.counts, int(current.dollars) * 100):
		_mistake("teller.change_hundred", {}, "retry", "teller.try_again")
	else:
		_mistake("teller.wrong_amount", {"given": _amount(cents / 100.0), "amount": _amount(current.dollars)}, "retry", "teller.try_again")

## Served right (paid exactly, or a short account declined): counts when right the first time;
## at the target the window closes after this customer.
func _served(id: String) -> void:
	step = "served"
	if not current.missed and Board.shared().add_success(ACTIVITY):
		_finished = true
	_customer_say(id, lexicon.line(id), [host.choice("next", "teller.close_window" if _finished else "teller.next", "next")])

## "Next!": the customer walks out; the next one steps up, or the game ends.
func _send_off() -> void:
	var leaving := current
	current = {}
	step = ""
	_close_up(null)
	host.close_dialogue()
	_leaving.append(leaving)
	_walk(leaving.node, EXIT_PATH, func() -> void: _remove(leaving))
	if _finished:
		_finish(true)
	else:
		_call_next()

## The game is over (`complete`: the target was reached): fade back to the banker, who thanks the
## player (`speak`), and clear the customers and the monitor.
func _finish(complete: bool, speak := true) -> void:
	playing = false
	step = ""
	host.cancel_leave()
	host.abandon_practice()
	money.reset()
	money.hide_panel()
	_close_up(null)
	host.close_dialogue()
	if complete:
		offered = false
	var clear := func() -> void:
		for customer in [current, waiting] + _leaving:
			_remove(customer)
		current = {}
		waiting = {}
		_leaving.clear()
		_walkers.clear()
		_hide_monitor()
		host.place_player_near()
	if not speak:
		clear.call()
		return
	await zone.fade_through(clear)
	host.zoom(true)
	host.say("teller.complete" if complete else "teller.stopped")

func _remove(customer: Dictionary) -> void:
	if customer.is_empty():
		return
	_leaving.erase(customer)
	if customer.get("presence") != null and is_instance_valid(customer.presence):
		customer.presence.zoom_to_face(false)
		customer.presence.queue_free()
	if is_instance_valid(customer.get("node")):
		customer.node.queue_free()

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
	elif step == "count":
		_open_money()
	elif not _prompt.is_empty() and not current.is_empty():
		_customer_say(str(_prompt[0]), _prompt[1], _prompt[2], bool(_prompt[3]))

# --- Dialogue and cameras ----------------------------------------------------------------------

## An amount for a phrase: words in the foreign language, digits in the native line.
func _amount(dollars: float) -> Dictionary:
	return dialogue.money_values(roundi(dollars * 100.0))

## The customer at the window says `line`; the camera frames their face, or the monitor while
## the player reads the balance (`monitor`).
func _customer_say(id: String, line: Dictionary, choices: Array, monitor := false) -> void:
	_prompt = [id, line, choices, monitor]
	host.show_line(id, line, choices, 0.0, {"foreign": current.name, "native": current.name})
	_close_up(null if monitor else current.presence)
	_monitor_camera(monitor)

## The face close-up on one customer (null: none).
func _close_up(presence) -> void:
	for customer in [current, waiting] + _leaving:
		var other = customer.get("presence")
		if other != null and is_instance_valid(other) and other != presence:
			other.zoom_to_face(false)
	if presence != null and is_instance_valid(presence):
		_monitor_camera(false)
		presence.zoom_to_face(true)

## The close-up of window 2's monitor while the balance is read.
func _monitor_camera(on: bool) -> void:
	if on:
		if _camera == null:
			_camera = Camera3D.new()
			_camera.name = "TellerMonitorCamera"
			_camera.fov = MONITOR_FOV
			add_child(_camera)
		var eye := town.to_global(MONITOR_EYE)
		var at := town.to_global(MONITOR_AT + Vector3(0, -0.07, 0))
		_camera.global_transform = Transform3D(Basis.looking_at(at - eye, Vector3.UP), eye)
		if not _camera.current:
			# Back to the player's own camera afterwards (a face close-up may still be easing out).
			_previous_camera = player.get("camera") as Camera3D
			_camera.make_current()
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
		_screen_top = _screen_label(26, BonStyle.INK_SOFT, 0.07)
		_screen_amount = _screen_label(64, BonStyle.INK, -0.055)
	# Local +z (the label's front) toward the teller: town +x.
	_monitor.global_transform = town.global_transform * Transform3D(Basis.looking_at(Vector3.LEFT, Vector3.UP), MONITOR_AT)
	_monitor.visible = true
	_set_screen(false)

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

## The monitor's text: the window number, or the current customer's account and balance.
func _set_screen(account: bool) -> void:
	if _monitor == null:
		return
	var lang: String = lexicon.foreign
	if account and not current.is_empty():
		_screen_top.text = "%s\n%s" % [lexicon.phrase("teller.screen_account", lang, {"name": current.name}), lexicon.phrase("teller.screen_balance", lang)]
		_screen_amount.text = Currency.usd(int(current.balance) * 100)
		_screen_amount.font_size = 64
	else:
		_screen_top.text = ""
		# Smaller, so "Ventanilla 2" fits on one line.
		_screen_amount.text = lexicon.phrase("teller.screen_idle", lang)
		_screen_amount.font_size = 34

func _hide_monitor() -> void:
	_monitor_camera(false)
	if _monitor != null:
		_monitor.visible = false

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
	host.tick(delta)
