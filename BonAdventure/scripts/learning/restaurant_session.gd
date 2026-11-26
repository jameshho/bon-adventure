extends Node
## The Alta Cocina restaurant game ("On the Menu"). Flow since 11 Nov 2026 (user request;
## design record: docs/guides/TOWN_DESIGN_BRIEF.md, "Restaurant game: reception, tables and order
## tablet"), played in the dining room rather than in one screen:
##   1. Twinkle the beagle waiter at the host stand (BeagleWaiter) shows the gold "!" and asks
##      for help in the SHARED dialogue box (shop_order_panel.gd, through minigame_host.gd).
##   2. "Yes": Twinkle sends the player to one of the two seated customers (house characters
##      without costume on RestaurantCustomerSeat and RestaurantCustomerSeat2, at two
##      different tables), who now shows the "!".
##   3. Talking to that customer: they say what they would like to order, 2 or 3 courses in
##      menu order ("I'd like to order a starter and a drink"), and INTRO_SECONDS later what
##      they want of each ("For a starter, I'd like something salty. To drink, ...";
##      restaurant_orders.gd: each request has exactly one match on today's menu) with "Open
##      the tablet" (user, 11 Nov 2026).
##   4. The order tablet (restaurant_panel.gd): the player inspects dishes, chooses one per
##      course asked and sends the order; the tablet shows "Order sent!" and closes by itself
##      (SENT_SECONDS).
##   5. The customer says thanks, and VERDICT_SECONDS later "Excellent!..." (Twinkle shows the
##      "!" again) or, with any dish wrong, "Oh no, this is not what I ordered. Can you try
##      again?" and RETRY_SECONDS later the tablet opens again on the same order: the right
##      dishes stay on the slip, each wrong dish is marked ✗ and cannot be chosen again for
##      that course (user, 24 Nov 2026: feedback at once, not after walking back to Twinkle).
##      Only the first send is tracked (practice_log.gd first answer).
##   6. Back at Twinkle (only after a right order): "Good job!" (the visit counts towards
##      data/activities.json restaurant_twinkle only when right at the first send; after a
##      retry "X got what they wanted in the end..." and it does not count; user, 24 Nov 2026)
##      with "Next customer" /
##      "Stop serving"; Twinkle never names the next customer ("See if any customers are ready
##      to order"; user, 11 Nov 2026). At the target, the last report offers the words
##      practised on the tablet, and Finish ends the game.
## The other customer meanwhile is "still looking at the menu"; customers are replaced after a
## game. Today's menu is chosen when the town loads and after each game, so the menu book on
## the table by the host stand (RestaurantMenuBook, restaurant_menu_book.gd) shows the dishes
## the next customers order from. No coins, nothing saved, no word studied; practice tracking
## records each request's target dish (one answer per dish). ✕ / Esc on the tablet only closes
## it (talk to the customer to open it again); leaving the game is "Stop serving" at Twinkle,
## or walking to the entrance: like the Mystery House arch, an invisible wall holds the door
## while a game runs and stepping up to it asks the shared quit question (user, 11 Nov 2026).
## Text: the Lexicon (data/phrases.json group "restaurant").
const Board := preload("res://scripts/learning/activity_board.gd")
const Orders := preload("res://scripts/learning/restaurant_orders.gd")
const Progress := preload("res://scripts/learning/game_progress.gd")
const Host := preload("res://scripts/learning/minigame_host.gd")
const Presence := preload("res://scripts/learning/npc_presence.gd")
const Currency := preload("res://scripts/learning/currency.gd")
const HouseCharacters := preload("res://scripts/characters/house_characters.gd")
## Practice tracking (practice_log.gd): each visit tests the target dish of every request
## (decision 6); the dishes sent are the answers.
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
const Zone := preload("res://scripts/learning/minigame_zone.gd")
const NPC := "BeagleWaiter"
const SEATS := ["RestaurantCustomerSeat", "RestaurantCustomerSeat2"]
const MENU_BOOK := "RestaurantMenuBook"
const ACTIVITY := "restaurant_twinkle"
## House characters who may be customers: everyone but BonBon (the player's pig), and
## Twinkle and Bruno, who work here.
const STAFF := ["bonbon", "twinkle", "bruno"]
const CALL_DISTANCE := 16.0
const WALK_AWAY_DISTANCE := 10.0
const MESSAGE_SECONDS := 9.0
## "Order sent!" on the tablet before it closes, and the customer's thanks before the verdict
## (user request: "maybe 2 seconds").
const SENT_SECONDS := 1.1
const VERDICT_SECONDS := 2.0
## The customer's "this is not what I ordered, can you try again?" before the tablet opens again.
const RETRY_SECONDS := 2.5
## The customer's "I'd like to order a starter and a drink" before the requests (user: "wait 2
## seconds").
const INTRO_SECONDS := 2.0
## Courses per visit (user, 11 Nov 2026: "2 to 3 items each time").
const ITEMS_MIN := 2
const ITEMS_MAX := 3
## Courses a customer orders at the current level ([min, max]; ITEMS_MIN..ITEMS_MAX without one).
var _items: Array = [ITEMS_MIN, ITEMS_MAX]
## The entrance in the dining room's frame (Restaurants/Pizza, the seats' parent): the door gap
## x -1.8..1.8 in the front wall at z -7.7, floor y .09. DOOR_WALL holds the gap while a game
## runs (player only: FIGURE_LAYER); DOOR_ASK is the question zone just inside it.
const DOOR_WALL_AT := Vector3(0, 1.79, -7.5)
const DOOR_WALL_SIZE := Vector3(3.9, 3.4, 0.4)
const DOOR_ASK_AT := Vector3(0, 1.5, -6.85)
const DOOR_ASK_SIZE := Vector3(3.8, 3.0, 1.3)
## How many recent order properties to avoid repeating.
const RECENT := 4

## Where a visit stands.
enum Step { NONE, TO_CUSTOMER, WAITING, TO_HOST }

var lexicon
var dialogue_panel
var panel
var book
var interaction
var player: Node3D
var twinkle: Node3D
var menu_book: Node3D
## One per seat: {"seat": Node3D, "node": Node3D or null, "spec": house character,
## "presence": npc_presence.gd (the "!" and the face camera)}.
var tables: Array = []
## The shared NPC host (minigame_host.gd): Twinkle, the customers, the menu book, the "!",
## talking, leaving.
var host
var presence:
	get: return host.presence if host != null else null
var orders
## The visit's requests, one per course asked, in menu order: [{course, target, reqs}, ...].
var requests: Array = []
var playing := false
var step := Step.NONE
## The table (index into `tables`) Twinkle sent the player to.
var current := -1
## The dishes sent (course → dish id) and whether every one was right.
var sent: Dictionary = {}
var sent_right := false
## The visit's wrong dishes so far (course → [dish ids]), marked ✗ on the tablet; and how many
## orders were sent back.
var wrong: Dictionary = {}
var tries := 0
## The customer has said which courses they want (the requests follow).
var _heard := false
## The last report reached the progress target.
var finished := false
var _served: Array = []
var _recent: Array = []
var _practised: Array = []
var _speaker: Variant = null
var _zoomed = null
var _rng := RandomNumberGenerator.new()
## Bumped whenever a visit or the game changes, so a pending timer can tell it is stale.
var _visit_id := 0
## Whether Twinkle offers the game now (rolled on approach; kept on the host).
var offered: bool:
	get: return host.offered if host != null else false
	set(value):
		if host != null:
			host.offered = value
## The current table's customer (old checks read `customer`).
var customer: Node3D:
	get: return tables[current].node if current >= 0 and current < tables.size() else null
## The entrance's door guard (minigame_zone.gd make_door_guard).
var door

func setup(shared_lexicon, shared_dialogue_panel, restaurant_panel, interaction_controller, explorer: Node3D, world: Node3D, menu_book_panel = null) -> void:
	name = "RestaurantSession"
	lexicon = shared_lexicon
	dialogue_panel = shared_dialogue_panel
	panel = restaurant_panel
	book = menu_book_panel
	interaction = interaction_controller
	player = explorer
	_rng.randomize()
	orders = Orders.new(_rng)
	orders.new_menu()
	panel.send_pressed.connect(_on_send)
	panel.finish_pressed.connect(_on_finish)
	panel.close_requested.connect(_on_close)
	if book != null:
		book.close_requested.connect(func() -> void: book.hide_book())
	twinkle = world.find_child(NPC, true, false) as Node3D
	for title in SEATS:
		var seat := world.find_child(title, true, false) as Node3D
		if seat != null:
			tables.append({"seat": seat, "node": null, "spec": {}, "presence": null})
	if twinkle == null or tables.is_empty():
		push_warning("restaurant_session: no '%s' or customer seats" % NPC)
		return
	host = Host.new()
	add_child(host)
	host.setup(self, {"activity": ACTIVITY, "group": "restaurant", "speaker": "restaurant.twinkle", "call_distance": CALL_DISTANCE, "walk_away": WALK_AWAY_DISTANCE, "message_seconds": MESSAGE_SECONDS}, lexicon, dialogue_panel, interaction, player, twinkle)
	host.play_chosen.connect(open_game)
	host.choice_made.connect(_on_choice)
	host.talk_closed.connect(func(_id: String) -> void: _zoom_customer(null))
	host.leave_answered.connect(_on_leave_answered)
	menu_book = world.find_child(MENU_BOOK, true, false) as Node3D
	if menu_book != null and book != null:
		host.add_talker(menu_book)
	for i in tables.size():
		_seat_customer(i)
	_build_door(tables[0].seat.get_parent())

## The invisible wall in the entrance and the question zone in front of it (see DOOR_WALL_AT;
## the shared door guard of minigame_zone.gd).
func _build_door(room: Node3D) -> void:
	var zone := Zone.new()
	add_child(zone)
	zone.setup(player, null, "RestaurantFade")
	door = zone.make_door_guard(room, DOOR_WALL_AT, DOOR_WALL_SIZE, DOOR_ASK_AT, DOOR_ASK_SIZE, "Restaurant door", {
		"blocking": func() -> bool: return playing and _inside(),
		"can_ask": func() -> bool: return not panel.visible,
		"ask": func() -> void: host.ask_leave("restaurant.leave_door"),
		"cancel": func() -> void: host.cancel_leave(),
		"asking": func() -> bool: return host.is_asking_leave(),
		"layer": HouseCharacters.FIGURE_LAYER})

## The player is in the dining room (inside the front wall), where the door wall may stand.
func _inside() -> bool:
	if door == null or not is_instance_valid(player):
		return false
	var local: Vector3 = door.wall.get_parent().global_transform.affine_inverse() * player.global_position
	return local.z > DOOR_WALL_AT.z + DOOR_WALL_SIZE.z * 0.5 and absf(local.x) < 20.0

## For the activity board: a game is in progress.
func activity_running() -> bool:
	return playing

## Talking to someone else is possible while this game's plain line is still on screen (the
## customer's verdict as the player walks back to Twinkle); a question or a screen is busy.
func busy() -> bool:
	return (host != null and host.owns_dialogue() and dialogue_panel.has_choices()) or panel.visible or (book != null and book.visible)

# --- The customers -----------------------------------------------------------------------

## A random house character (not staff, not anyone seated now) sits down at table `i`.
func _seat_customer(i: int) -> void:
	var taken := {}
	for table in tables:
		taken[str(table.spec.get("id", ""))] = true
	var pool: Array = []
	for spec in HouseCharacters.characters():
		if not STAFF.has(str(spec.id)) and not taken.has(str(spec.id)):
			pool.append(spec)
	if pool.is_empty():
		return
	var table: Dictionary = tables[i]
	if is_instance_valid(table.node):
		host.remove_talker(table.node)
		table.node.queue_free()
	var seat: Node3D = table.seat
	table.spec = pool[_rng.randi_range(0, pool.size() - 1)]
	var facing := -seat.global_basis.z
	var back := seat.global_position - facing * float(seat.get_meta("back_distance", .22))
	var node: Node3D = HouseCharacters.new().seated(str(table.spec.scene), seat.get_parent(), "RestaurantCustomer" + ("" if i == 0 else str(i + 1)), seat.global_position, facing, back)
	node.set_meta("word_key", "person")
	host.add_talker(node)
	node.set_meta("character_id", str(table.spec.id))
	node.set_meta("character_name", str(table.spec.name))
	node.set_meta("character_species", str(table.spec.species))
	node.add_to_group("figures")
	HouseCharacters.fit_blocker(node)
	table.node = node
	# One presence per table, kept across guests (its talk camera may be in use): setup()
	# moves the "!" to the new guest.
	if table.presence == null:
		table.presence = Presence.new()
		table.presence.name = "CustomerPresence%d" % (i + 1)
		add_child(table.presence)
	table.presence.setup(node, player)

## The plush scene name of a customer ("lion" for lion_plush.tscn), for the portrait.
func _species(i: int) -> String:
	return str(tables[i].spec.get("scene", "")).get_file().trim_suffix("_plush.tscn")

func _name(i: int) -> String:
	return str(tables[i].spec.get("name", ""))

func _customer_line(i: int) -> Dictionary:
	return {"foreign": _name(i), "native": _name(i)}

func _table_of(node: Node3D) -> int:
	for i in tables.size():
		if tables[i].node == node:
			return i
	return -1

## The face close-up on a customer while they talk (null: none).
func _zoom_customer(presence_node) -> void:
	if _zoomed != null and is_instance_valid(_zoomed) and _zoomed != presence_node:
		_zoomed.zoom_to_face(false)
	_zoomed = presence_node
	if presence_node != null:
		presence_node.zoom_to_face(true)

# --- Dialogue box ------------------------------------------------------------------------

## A customer's line (`i`) in the shared box.
func _customer_say(i: int, id: String, choices: Array = [], auto_close: float = -1.0, line: Dictionary = {}) -> void:
	_speaker = _customer_line(i)
	host.show_line(id, line if not line.is_empty() else lexicon.line(id), choices, auto_close, _speaker)
	_speaker = null

## Twinkle's line; the face close-up only for a question (the player walks off after a plain
## line, such as being sent to a customer).
func _twinkle_say(id: String, values: Dictionary = {}, choices: Array = [], auto_close: float = -1.0) -> void:
	_zoom_customer(null)
	host.zoom(not choices.is_empty())
	host.say(id, choices, auto_close, values)

func _host_speaker() -> Variant:
	return _speaker

## Talking: the menu book opens; customers answer for themselves; Twinkle during a game says
## where things stand (otherwise the host's greeting).
func _host_talk(talker: Node3D) -> bool:
	if talker == menu_book:
		host.zoom(false)
		open_book()
		return true
	var i := _table_of(talker)
	if i >= 0:
		host.zoom(false)
		_talk_to_customer(i)
		return true
	if not playing:
		return false
	match step:
		Step.TO_HOST:
			_report()
		Step.NONE:
			# Between visits (the report's question was walked away from): ask it again.
			_show_report()
		_:
			_twinkle_say("restaurant.reminder", {}, [host.choice("stop", "restaurant.stop", "no")], 0.0)
	return true

func _talk_to_customer(i: int) -> void:
	_zoom_customer(null)
	if not playing or i != current:
		_customer_say(i, "restaurant.customer_wait" if playing else "restaurant.customer_idle")
		return
	if step != Step.TO_CUSTOMER:
		_customer_say(i, "restaurant.customer_done")
		return
	if _heard:
		_say_requests(i)
		return
	# First the courses ("I'd like to order a starter and a drink"), then the requests.
	_heard = true
	_customer_say(i, "restaurant.order_intro", [], -1.0, _line(Orders.intro_ref(_courses())))
	_zoom_customer(tables[i].presence)
	var visit := _visit_id
	await get_tree().create_timer(INTRO_SECONDS).timeout
	if visit == _visit_id and step == Step.TO_CUSTOMER and not panel.visible and host.owns_dialogue() and host.line_id == "restaurant.order_intro":
		_say_requests(i)

## What the customer wants of each course, with "Open the tablet".
func _say_requests(i: int) -> void:
	_customer_say(i, "restaurant.order", [host.choice("tablet", "restaurant.open_tablet", "check")], 0.0, _line(_requests_ref()))
	_zoom_customer(tables[i].presence)

func _courses() -> Array:
	return requests.map(func(r): return str(r.course))

## Each request as a line, by course (the tablet's order slip).
func _request_lines() -> Dictionary:
	var out := {}
	for request in requests:
		out[str(request.course)] = _line(Orders.order_ref(request))
	return out

func _requests_ref() -> Dictionary:
	return Orders.sentences(requests.map(func(r): return Orders.order_ref(r)))

func _on_choice(id: String) -> void:
	match id.trim_prefix(host.choice_prefix()):
		"tablet":
			host.close_dialogue()
			_zoom_customer(null)
			open_tablet()
		"next":
			host.close_dialogue()
			_next_visit()
		"stop":
			host.close_dialogue()
			host.ask_leave()
		"words":
			host.close_dialogue()
			_show_words()

# --- Menu book ---------------------------------------------------------------------------

## Today's menu for the book and the tablet: courses, dishes and the drawing schema.
func _menu_data() -> Dictionary:
	var courses: Array = []
	for id in Orders.courses():
		courses.append({"id": id, "title": lexicon.line("restaurant.course_" + str(id))})
	var menu := {}
	for course in orders.menu:
		menu[course] = orders.menu[course].map(func(entry): return {
			"id": str(entry.id), "name": _word_line(str(entry.word)), "price": Currency.usd(int(entry.price)),
			"art": entry.art, "taste": entry.get("taste", {}), "temperature": int(entry.temperature), "has": entry.get("has", [])})
	var tastes: Array = []
	for id in Orders.taste_ids():
		tastes.append([id, str(Orders.properties().taste[id].color)])
	var tags: Array = []
	for group in Orders.TAG_GROUPS:
		tags.append_array(Orders.tag_ids(group))
	return {
		"title": lexicon.line("restaurant.title"),
		"translate": lexicon.line("common.show_translation"),
		"courses": courses,
		"menu": menu,
		"schema": {"tastes": tastes, "temperature_colors": Orders.properties().temperature.colors, "tags": tags},
		"close": lexicon.line("restaurant.close_tablet"),
	}

func open_book() -> void:
	if book == null:
		return
	interaction.clear_card()
	var data := _menu_data()
	data["subtitle"] = lexicon.line("restaurant.menu_of_day")
	data["title_short"] = lexicon.line("posters.menu_title")
	data["hint"] = lexicon.line("restaurant.turn_hint")
	book.show_native = dialogue_panel.show_native
	book.open(data)

# --- Game --------------------------------------------------------------------------------

## "Yes" on Twinkle's greeting (or the minigame picker): the first visit.
func open_game() -> void:
	interaction.clear_card()
	playing = true
	_served.clear()
	_recent.clear()
	_practised.clear()
	current = -1
	finished = false
	# Levels (LEARN-06, 25 Nov 2026; docs/game/minigames.md#on-the-menu): "courses" [min, max]
	# per order and "difficulty" settings merged over data/restaurant_game.json's (how many needs
	# an order names, un poco / muy, no / sin).
	var settings: Dictionary = Progress.shared().params(ACTIVITY)
	var courses: Array = settings.get("courses", [ITEMS_MIN, ITEMS_MAX])
	_items = [int(courses[0]), int(courses[courses.size() - 1])] if not courses.is_empty() else [ITEMS_MIN, ITEMS_MAX]
	orders.difficulty = Orders.data().get("difficulty", {}).duplicate(true)
	orders.difficulty.merge(settings.get("difficulty", {}), true)
	Board.shared().begin(ACTIVITY)
	_next_visit()

## Twinkle sends the player to the next customer (the other table each time; Twinkle does not
## name them), who will order 2-3 courses.
func _next_visit() -> void:
	if not playing:
		return
	_visit_id += 1
	current = _rng.randi_range(0, tables.size() - 1) if current < 0 else (current + 1) % tables.size()
	if not is_instance_valid(tables[current].node):
		_seat_customer(current)
	var all := Orders.courses()
	var picked: Array = all.duplicate()
	for k in range(picked.size() - 1, 0, -1):
		var j := _rng.randi_range(0, k)
		var t = picked[k]
		picked[k] = picked[j]
		picked[j] = t
	picked = picked.slice(0, mini(all.size(), _rng.randi_range(int(_items[0]), int(_items[1]))))
	var chosen: Array = all.filter(func(c): return picked.has(c))
	requests = _make_requests(chosen, _served, _recent)
	if requests.is_empty():
		# Should never happen (the logic check proves every menu has an order); a new menu.
		orders.new_menu()
		requests = _make_requests(chosen, [], [])
	if requests.is_empty():
		push_error("restaurant_session: no order for " + str(chosen))
		return
	for request in requests:
		for req in request.reqs:
			_recent.append(Orders.prop_of(req))
	_recent = _recent.slice(maxi(0, _recent.size() - RECENT))
	sent.clear()
	sent_right = false
	wrong.clear()
	tries = 0
	_heard = false
	step = Step.TO_CUSTOMER
	_twinkle_say("restaurant.go_to_customer", {}, [], MESSAGE_SECONDS)

## One request per course, or [] when a course has none.
func _make_requests(courses: Array, served: Array, recent: Array) -> Array:
	var out: Array = []
	for course in courses:
		var request: Dictionary = orders.make_order(str(course), served, recent)
		if request.is_empty():
			return []
		out.append(request)
	return out

## The order tablet for the current order.
func open_tablet() -> void:
	if not playing or step != Step.TO_CUSTOMER:
		return
	interaction.clear_card()
	# A retry is not a new question: the first send was the answer.
	if tries == 0:
		PracticeLog.shared().begin(ACTIVITY, _targets())
	panel.show_native = dialogue_panel.show_native
	panel.set_progress(Board.shared().done(ACTIVITY), Board.shared().target(ACTIVITY))
	panel.open(_panel_data())

## The target dish words of the visit's requests.
func _targets() -> Array:
	return requests.map(func(r): return str(Orders.dish(str(r.target)).word))

func _panel_data() -> Dictionary:
	var data := _menu_data()
	data.merge({
		"speaker": _customer_line(current),
		"species": _species(current),
		# The bubble says which courses; each request is on its row of the tablet's slip.
		"order": _line(Orders.intro_ref(_courses())),
		"requests": _request_lines(),
		"wanted": _courses(),
		"hint": lexicon.line("restaurant.pick_hint"),
		"pick_course": lexicon.line("restaurant.pick_course"),
		"choose": lexicon.line("restaurant.choose"),
		"send": lexicon.line("restaurant.send"),
		"sent": lexicon.line("restaurant.sent"),
		"finish": lexicon.line("restaurant.finish"),
		"wrong": wrong.duplicate(true),
	}, true)
	if tries > 0:
		# Sent back: the customer's complaint in the bubble, the right dishes still on the slip.
		data["order"] = lexicon.line("restaurant.verdict_wrong")
		var kept := {}
		for course in sent:
			if not wrong.get(course, []).has(str(sent[course])):
				kept[course] = str(sent[course])
		data["picks"] = kept
	return data

func _line(ref: Dictionary) -> Dictionary:
	return {"foreign": lexicon.text(ref, lexicon.foreign), "native": lexicon.text(ref, lexicon.native)}

func _word_line(key: String) -> Dictionary:
	return {"foreign": lexicon.word(key, lexicon.foreign), "native": lexicon.word(key, lexicon.native)}

func _practise(key: String) -> void:
	if key != "" and not _practised.has(key):
		_practised.append(key)

## "Send order" with a dish for every course asked (course → dish id): one answer per dish.
## The tablet says "Order sent!" and closes; the customer thanks the player, then gives the
## verdict (right only when every dish is).
func _on_send(picks: Dictionary) -> void:
	if not playing or step != Step.TO_CUSTOMER or requests.is_empty() or not panel.visible:
		return
	for request in requests:
		var entry := Orders.dish(str(picks.get(str(request.course), "")))
		if entry.is_empty() or str(entry.course) != str(request.course):
			return
	sent = picks.duplicate()
	sent_right = true
	var answers := {}
	for request in requests:
		var course := str(request.course)
		var entry := Orders.dish(str(picks[course]))
		var right := Orders.first_miss(entry, request.reqs).is_empty()
		var target := str(Orders.dish(str(request.target)).word)
		answers[target] = right
		if not right:
			sent_right = false
			var list: Array = wrong.get(course, [])
			if not list.has(str(entry.id)):
				list.append(str(entry.id))
			wrong[course] = list
		for req in request.reqs:
			_practise(Orders.word_of(req))
		_practise(target)
		if tries == 0:
			_served.append(str(request.target))
	if PracticeLog.shared().game_id() == ACTIVITY:
		PracticeLog.shared().first_answer(answers)
		PracticeLog.shared().complete()
	step = Step.WAITING
	panel.show_sent(sent)
	var visit := _visit_id
	await get_tree().create_timer(SENT_SECONDS).timeout
	if visit != _visit_id:
		return
	panel.hide_panel()
	var i := current
	_customer_say(i, "restaurant.thanks", [], VERDICT_SECONDS + 0.5)
	await get_tree().create_timer(VERDICT_SECONDS).timeout
	if visit != _visit_id:
		return
	if sent_right:
		step = Step.TO_HOST
		_customer_say(i, "restaurant.verdict_right")
		return
	# Sent back: the complaint, then the tablet again on the same order. The first miss of a
	# visit is one miss on the board (progression stars).
	if tries == 0:
		Board.shared().add_miss(ACTIVITY)
	tries += 1
	_customer_say(i, "restaurant.verdict_wrong", [], RETRY_SECONDS + 0.5)
	_zoom_customer(tables[i].presence)
	await get_tree().create_timer(RETRY_SECONDS).timeout
	if visit != _visit_id or step != Step.WAITING:
		return
	step = Step.TO_CUSTOMER
	if host.owns_dialogue() and host.line_id == "restaurant.verdict_wrong":
		host.close_dialogue()
	_zoom_customer(null)
	open_tablet()

## Back at Twinkle (after a right order): praise; then the next customer, or the end.
func _report() -> void:
	_visit_id += 1
	step = Step.NONE
	# Only an order right at the first send counts (user, 24 Nov 2026).
	finished = tries == 0 and Board.shared().add_success(ACTIVITY)
	if finished:
		offered = false
	_show_report()

## Twinkle's report of the last visit, with its question (again, if it was walked away from).
func _show_report() -> void:
	var name_value := _name(current)
	var ref := {"phrase": "restaurant.report_last" if finished else ("restaurant.report_right" if tries == 0 else "restaurant.report_retry"), "values": {"name": name_value}}
	var choices: Array = [host.choice("words", "restaurant.see_words", "check")] if finished else _next_choices()
	_zoom_customer(null)
	host.zoom(true)
	host.show_line(str(ref.phrase), _line(ref), choices, 0.0)

func _next_choices() -> Array:
	return [host.choice("next", "restaurant.next_customer", "next"), host.choice("stop", "restaurant.stop", "no")]

## The end: the tablet lists the words practised; Finish closes it with Twinkle's thanks.
func _show_words() -> void:
	var lines: Array = []
	for key in _practised:
		lines.append(_word_line(key))
	panel.show_native = dialogue_panel.show_native
	panel.set_progress(Board.shared().done(ACTIVITY), Board.shared().target(ACTIVITY))
	panel.ui = _panel_data() if not requests.is_empty() else _menu_data()
	panel.show_summary(lexicon.line("restaurant.summary"), lines, lexicon.line("restaurant.complete"))

func _on_finish() -> void:
	_end_game()
	_twinkle_say("restaurant.goodbye")

func _end_game() -> void:
	_zoom_customer(null)
	host.abandon_practice()
	_visit_id += 1
	playing = false
	step = Step.NONE
	requests = []
	current = -1
	panel.hide_panel()
	# New guests take both seats, and tomorrow's menu is on the table.
	orders.new_menu()
	for i in tables.size():
		_seat_customer(i)

## ✕ or Esc on the tablet: the summary finishes the game; an order in progress only closes the
## tablet (the customer opens it again).
func _on_close() -> void:
	if not panel.visible:
		return
	if not panel.summary.is_empty():
		_on_finish()
		return
	if step == Step.TO_CUSTOMER:
		host.abandon_practice()
		panel.hide_panel()

## Esc / back with no popup open (Main, the request_leave() contract, docs/guides/MINIGAMES.md;
## 25 Nov 2026): the leave question, as Twinkle's "stop". The door guard keeps the player in the
## dining room meanwhile. True while a game runs.
func request_leave() -> bool:
	if host == null or not playing:
		return false
	if not host.is_asking_leave():
		host.ask_leave()
	return true

func _on_leave_answered(leave: bool) -> void:
	if door != null:
		door.asked = false
	if leave:
		_end_game()
		_twinkle_say("restaurant.left_early")

## A language change in Settings ends the game with Twinkle's goodbye.
func end_activity() -> void:
	if host == null:
		return
	host.cancel_leave()
	if book != null:
		book.hide_book()
	if playing:
		_end_game()
		_twinkle_say("restaurant.left_early")
	host.refresh_name()

# --- Each frame -------------------------------------------------------------------------

## Twinkle calls while a report is due; the customer the player was sent to shows the "!"
## until the order is taken.
func _host_calling() -> bool:
	return playing and step == Step.TO_HOST

func _process(delta: float) -> void:
	if host == null:
		return
	host.tick(delta)
	for i in tables.size():
		var marker = tables[i].presence
		if marker == null or not is_instance_valid(marker) or not is_instance_valid(tables[i].node):
			continue
		var talking: bool = host.talker == tables[i].node and host.owns_dialogue()
		var calling: bool = playing and i == current and step == Step.TO_CUSTOMER and not panel.visible and not talking
		marker.animate(delta, calling)
		# Seated guests do not hop: only the "!" bobs.
		tables[i].node.position = marker.rest_position
