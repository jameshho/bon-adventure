extends Node
## One cashier counter's money-selection minigame (a cashier asks for an amount in the foreign language,
## the player counts it out). Ties together the cashier NPC, the SHARED dialogue box
## (shop_order_panel.gd: speaker, foreign/native line, choice buttons, translate toggle),
## the money panel (money_panel.gd) and the pure currency logic (currency.gd). Main creates
## one session per entry in data/shops.json "cashiers"; the bank can add its own
## entry and NPC. Nothing here is saved and no word is studied.
##
## Flow: click/E the cashier -> request dialogue (+ "Count out the money") -> money panel ->
## Hand over -> verdict dialogue. Wrong: "Try again" (selection kept) or "What went wrong?"
## (what was given, short or over). Close/✕ on the money panel -> the shared leave question
## -> yes ends the round, no returns to the panel. A new round (new random amount, empty
## tray) starts the next time the cashier is talked to or "Another charge" is chosen.
##
## Since 9 Nov 2026 the cashier uses the shared NPC host (minigame_host.gd): the gold "!"
## while the player is in the store and the cashier offers rounds (it was missing before),
## talking, the leave question and walking away. The offer is rolled on entering the store
## (_host_near()); a session (from talking to the cashier until goodbye) counts rounds paid
## exactly on the first try (data/activities.json "cashier_<store>"), and at the target the
## cashier thanks the player and the session ends.
const Currency := preload("res://scripts/learning/currency.gd")
const Board := preload("res://scripts/learning/activity_board.gd")
const Host := preload("res://scripts/learning/minigame_host.gd")
## Levels and stars (18 Nov 2026): the level sets the amount range; a round paid wrong once is a miss.
const Progress := preload("res://scripts/learning/game_progress.gd")

const REQUEST_VARIANTS := 5
const WALK_AWAY_DISTANCE := 14.0
const MESSAGE_SECONDS := 9.0
const ZONE_CHECK_INTERVAL := 0.25

var store_id := ""
var dialogue
var panel
var money
var interaction
var zones
var player: Node3D
var cashier: Node3D
var store_zone := ""
## The cashier's gender for the role word ("El Cajero"), from data/shops.json.
var npc_gender := ""
var request_cents := 0
## True from the moment a round starts until it is over (answered, quit or walked away).
var round_active := false
var _last_given := 0
var _request_variant := 1
var _zone_timer := 0.0
var _in_zone := false
var _rng := RandomNumberGenerator.new()
## The activity board id ("cashier_supermarket").
var activity_id := ""
## A wrong hand-over this round: the round no longer counts toward progress.
var _missed := false
## The shared NPC host (minigame_host.gd): the cashier, the "!", talking, leaving.
var host
## Whether the cashier offers rounds now (rolled on entering the store; kept on the host).
var offered: bool:
	get: return host.offered if host != null else false
	set(value):
		if host != null:
			host.offered = value

func setup(for_store: String, shop_dialogue, shop_panel, money_panel, interaction_controller, town_zones, explorer: Node3D, world: Node3D) -> void:
	store_id = for_store
	name = "CashierSession_" + for_store
	dialogue = shop_dialogue
	panel = shop_panel
	money = money_panel
	interaction = interaction_controller
	zones = town_zones
	player = explorer
	var rules: Dictionary = dialogue.cashiers.get(for_store, {})
	store_zone = str(rules.get("zone", for_store))
	npc_gender = str(rules.get("npc_gender", ""))
	activity_id = "cashier_" + for_store
	_rng.randomize()
	cashier = world.find_child(str(rules.get("npc", "")), true, false) as Node3D
	if cashier == null:
		push_warning("cashier_session: no cashier node '%s' for %s" % [rules.get("npc", ""), for_store])
		return
	host = Host.new()
	add_child(host)
	host.setup(self, {"activity": activity_id, "group": "cashier", "not_now": "cashier.no_request",
			"leave_confirm": "cashier.quit_confirm", "leave_yes": "cashier.quit_yes", "leave_no": "cashier.quit_no",
			"walk_away": WALK_AWAY_DISTANCE, "message_seconds": MESSAGE_SECONDS},
			dialogue.lexicon, panel, interaction, player, cashier)
	host.play_chosen.connect(start_game)
	host.choice_made.connect(_on_choice)
	host.talk_closed.connect(_on_talk_closed)
	host.leave_answered.connect(_on_leave_answered)
	money.submitted.connect(_on_submitted)
	money.close_requested.connect(_on_money_close)

# --- Host hooks and the activity board -------------------------------------------------------

## Workers have no personal name, so the box shows their role ("El Cajero").
func _host_speaker() -> Variant:
	return dialogue.speaker_line(str(cashier.get_meta("word_key", "")), npc_gender)

## The cashier calls while the player is in the store (each visit rolls the offer again).
func _host_near(_distance: float) -> bool:
	return _in_zone

## Talking to the cashier asks for money straight away (no greeting question).
func _host_talk(_talker: Node3D) -> bool:
	if not host.gate():
		start_game()
	return true

## For the activity board: a round is in progress.
func activity_running() -> bool:
	return round_active or money.visible

func busy() -> bool:
	return (host != null and host.owns_dialogue()) or money.visible or (host != null and host.is_asking_leave())

## A language change in Settings ends a running round with the cashier's goodbye (user
## decision, 4 Nov 2026); Main calls this on every activity session.
func end_activity() -> void:
	if host == null or not (round_active or busy()):
		return
	host.cancel_leave()
	_end_round(true)

# --- Dialogue helpers ----------------------------------------------------------------------------

## A phrase with {name} values; the amount values carry the words and the "$" form.
func _amount_values(cents: int) -> Dictionary:
	return dialogue.money_values(cents)

func _join(parts: Array) -> Dictionary:
	var foreign: PackedStringArray = []
	var native: PackedStringArray = []
	for part in parts:
		foreign.append(part.foreign)
		native.append(part.native)
	return {"foreign": " ".join(foreign), "native": " ".join(native)}

func _money_lines() -> Dictionary:
	return {
		"request": dialogue.line("cashier.request_%d" % _request_variant, {"amount": _amount_values(request_cents)}),
		"tray_title": dialogue.line("money.tray"),
		"bills": dialogue.line("money.bills"),
		"coins": dialogue.line("money.coins"),
		"total": dialogue.line("money.total"),
		"submit": dialogue.line("money.submit"),
		"clear": dialogue.line("money.clear"),
		"close": dialogue.line("money.close"),
		"translate": dialogue.line("common.show_translation"),
	}

# --- Round ----------------------------------------------------------------------------------------

## A new session: the progress starts at 0 and the first amount is asked.
func start_game() -> void:
	Board.shared().begin(activity_id)
	_new_round()
	host.show_level()   # the level badge on the first amount (no greeting question here)

func _new_round() -> void:
	# The amount's range follows the player's level (game_progress.gd, data/activities.json).
	var level: Dictionary = Progress.shared().params(activity_id)
	request_cents = Currency.random_cents(_rng, int(level.get("max_cents", Currency.MAX_CENTS)), int(level.get("step", 1)))
	_request_variant = _rng.randi_range(1, REQUEST_VARIANTS)
	round_active = true
	_missed = false
	_last_given = 0
	money.reset()
	host.show_line("cashier.request", _money_lines().request, [host.choice("count", "cashier.count", "money"), host.choice("bye", "common.reply_no", "exit")], 0.0)

func _open_money() -> void:
	host.close_dialogue()
	money.show_native = panel.show_native
	interaction.clear_card()
	money.open(_money_lines())
	money.set_progress(Board.shared().done(activity_id), Board.shared().target(activity_id))

func _end_round(goodbye: bool) -> void:
	round_active = false
	money.reset()
	money.hide_panel()
	if goodbye:
		host.say("cashier.goodbye")
	else:
		host.close_dialogue()

# --- Choices ----------------------------------------------------------------------------------------

func _on_choice(id: String) -> void:
	match id.trim_prefix(host.choice_prefix()):
		"count", "retry":
			_open_money()
		"why":
			_explain()
		"another":
			_new_round()
		"bye":
			_end_round(true)

## The player pressed Hand over: the verdict comes back through the dialogue.
func _on_submitted(cents: int) -> void:
	if not round_active or not money.visible:
		return
	money.hide_panel()
	_last_given = cents
	if Currency.is_exact(money.counts, request_cents):
		round_active = false
		money.reset()
		# Only a round paid right the first time counts; the target ends the session.
		if not _missed and Board.shared().add_success(activity_id):
			offered = false
			host.say("cashier.complete")
			return
		host.say("cashier.correct", [host.choice("another", "cashier.another", "next"), host.choice("bye", "cashier.bye", "exit")], 0.0)
	else:
		if not _missed:
			Board.shared().add_miss(activity_id)   # stars: one miss per round (game_progress.gd)
		_missed = true
		host.say("cashier.wrong", [host.choice("retry", "cashier.try_again", "retry"), host.choice("why", "cashier.what_wrong", "question")], 0.0)

func _explain() -> void:
	var parts: Array = [dialogue.line("cashier.gave", {"given": _amount_values(_last_given)})]
	if _last_given < request_cents:
		parts.append(dialogue.line("cashier.short", {"diff": _amount_values(request_cents - _last_given)}))
	else:
		parts.append(dialogue.line("cashier.over", {"diff": _amount_values(_last_given - request_cents)}))
	host.show_line("cashier.explain", _join(parts), [host.choice("retry", "cashier.try_again", "retry"), host.choice("bye", "cashier.bye", "exit")], 0.0)

## Close or ✕ on the money panel: the shared leave question; "no" returns to the panel with
## the tray intact.
func _on_money_close() -> void:
	if not round_active:
		return
	money.hide_panel()
	host.ask_leave()

func _on_leave_answered(leave: bool) -> void:
	if not round_active:
		return
	if leave:
		_end_round(true)
	else:
		_open_money()

## ✕, auto-close or walking away ended the cashier's line: the round is over.
func _on_talk_closed(_line_id: String) -> void:
	round_active = false
	money.reset()

# --- Each frame: the store zone and the host ----------------------------------------------------

func _process(delta: float) -> void:
	if host == null or not is_instance_valid(player) or zones == null:
		return
	_zone_timer += delta
	if _zone_timer >= ZONE_CHECK_INTERVAL:
		_zone_timer = 0.0
		var inside: bool = zones.resolve_global(player.global_position) == store_zone
		var left: bool = _in_zone and not inside
		_in_zone = inside
		# Leaving the store ends the round quietly.
		if left and (round_active or money.visible or host.owns_dialogue()):
			host.cancel_leave()
			_end_round(false)
	host.tick(delta)
