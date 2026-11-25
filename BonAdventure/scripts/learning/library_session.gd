extends Node
## Rosa's book-sorting game (user design, 13 Nov 2026; Rosa's check removed and the dialogue
## reworked 17 Nov 2026, user; docs/guides/MINIGAMES.md, design record
## docs/guides/TOWN_DESIGN_BRIEF.md "Library return cart and book-sorting game"):
##
##   1. Rosa the librarian (`Librarian`, samoyed plush beside the NEW BOOKS display, placed by
##      scripts/buildings/library.gd) shows the gold "!" and asks for help: the full greeting
##      ("Hi! I'm Rosa, the librarian...") the first time in a run, library.greeting_again after
##      that (shared host and dialogue box, minigame_host.gd).
##   2. The rolling return cart beside her (`Return cart/Slots/Slot <n>`) holds 3-6 books,
##      picked at random from the library's own collection (the titles on the NEW BOOKS display:
##      same title, category colour, thickness and topic word); it fills at load and whenever
##      books are "borrowed" (step 6). "Yes" starts sorting them: library.start, then
##      library.start_signs once that line closes.
##   3. The player takes a book in the hand (E on it: library_book.gd `holdable`, hand_hold.gd)
##      and, at any gap on any category bookcase (`Bookcase <Category>/Gaps/Gap ...`, each given
##      an Interactable here), E puts it there, spine out. Right category: the book slides in,
##      hops and gives off a few gold sparks. Wrong category: it wobbles side to side (no
##      sparks), goes back to its cart slot and into the hand again; it never stays on a wrong
##      shelf. Any order; a shelved book can be taken again.
##   4. Talking to Rosa during the game: library.holding while one of the books is in the hand,
##      else how many are left (library.left_one / left_many), with "OK" and "I'll help later"
##      (library.later: the books go away, library.stopped). Rosa does not check the shelves.
##   5. The game ends by itself once every book is on a gap of its own category (after the last
##      flourish): the camera zooms in on Rosa, who says library.perfect (user, 21 Nov 2026: the
##      "Remember: the book ... goes on the ... shelf" recap was removed); the zoom goes back when
##      the line closes. Then the shared results screen (results_flow.gd, for every game):
##      "Books Sorted!", the words practiced and discovered, Continue exploring / Play again
##      (the host's launch(): _start() fills a fresh cart, no walking away needed).
##   6. Replenish (user, 17 Nov 2026; 21 Nov 2026: once the player has walked away, no timer):
##      the sorted books stay on their shelves and the cart stays empty until the player is
##      farther than the host's call_distance from Rosa with the cart and the books out of view.
##      Meanwhile Rosa shows no "!" and says library.all_back. Then the shelved books are
##      "borrowed" (they leave the gaps), a new cart of 3-6 random books fills and Rosa offers
##      again when the player comes back. Runtime only, nothing saved.
##   7. Leaving (25 Nov 2026, GAME-01/02): walking out of the library's zone during the game puts
##      the player back inside, facing Rosa, and asks the shared leave question (the host's
##      ask_leave(), library.leave_confirm; the shop's walk-away pattern); Esc / back asks the same
##      (request_leave(), called by Main). Yes ends the game like "I'll help later" (the HUD and
##      word cards come back when activity_running() turns false); No, Esc or ✕ keeps it.
##   8. Practice (user, 17 Nov 2026): a book's first placement in a cart is one question testing
##      its topic word and its category's word (BOOK_WORDS and CATEGORIES in library.gd), opened
##      when the book is first taken in the hand (practice_log.gd: right shelf positive, wrong
##      negative, a translation shown first: translated).
##
## Text: data/phrases.json group "library"; offers: data/activities.json "library_rosa".
##
## Sounds (25 Nov 2026): the right shelf plays answer.correct, the wrong one answer.wrong (flat UI
## sounds bound in data/sounds.json; this script stays silent).
signal shelved_right
signal shelved_wrong

const Host := preload("res://scripts/learning/minigame_host.gd")
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
const Interactable := preload("res://scripts/core/interactable.gd")
const HandHold := preload("res://scripts/player/hand_hold.gd")
const SignLanguage := preload("res://scripts/world/sign_language.gd")
const Board := preload("res://scripts/learning/activity_board.gd")
const Library := preload("res://scripts/buildings/library.gd")
const Book := preload("res://scripts/world/library_book.gd")
const BOOK_SCENE := preload("res://scenes/props/book.tscn")
const SuccessBurst := preload("res://scripts/world/success_burst.gd")
const NPC := "Librarian"
const ACTIVITY := "library_rosa"
const BOOKS_MIN := 3
const BOOKS_MAX := 6
## Meta on this game's books (the display's own books carry return_book instead).
const SORT_META := "sort_book"
## Where a book stands in a gap (gap frame: on the shelf, spine side -Z): spine out, its cover
## width across the shelf depth.
const SHELVED := Transform3D(Basis(Vector3.UP, PI / 2), Vector3(0, 0, Book.PICTURE.x * .5))
## The right-shelf flourish: slide in from this far out, hop this high (the sparks:
## success_burst.gd).
const SLIDE := .14
## Slightly bigger and more obvious than the shared default (user, 21 Nov 2026): a higher hop, a
## little swell of the book, and more, larger, longer-lived sparks.
const HOP := .1
const SWELL := 1.08
const SPARK_SCALE := 1.35
const SPARK_COUNT := 16
const SPARK_SECONDS := .75
## The wrong-shelf wobble: this far to each side, this many swings, seconds per swing.
const WOBBLE := .035
const WOBBLES := 3
const WOBBLE_SWING := .07
## Seconds from the last right book to Rosa's thanks (the slide and hop take .41 s).
const FINISH_DELAY := .5
## The library's zone (data/zones.json) and how often the player's place in it is checked.
const ZONE := "library"
const ZONE_CHECK_INTERVAL := .25
## The player's last places inside the zone (one per zone check) during a game, oldest first:
## walking out puts them back at the oldest.
const INSIDE_SPOTS := 3

var host
var playing := false
var cart: Node3D
var slots: Array = []
var gaps: Array = []
## The display's books as {title, category, color, thickness}.
var catalog: Array = []
## This game's books.
var books: Array = []
var rng := RandomNumberGenerator.new()
## Rosa has introduced herself this run (later visits use library.greeting_again).
var met := false
## The last book is home and Rosa's thanks are on the way.
var _finishing := false
## After a perfect cart: the sorted books stay until the player walks away (_walked_away()).
var resting := false
## Books whose first placement in this cart has been recorded, and the one with an open question.
var _asked: Array = []
var _asking: Node3D
var _hand: Node3D
var _zone_timer := 0.0
var _inside_spots: Array = []
## The leave question was asked because the player walked out (not by Esc).
var _asked_at_edge := false

func setup(lexicon, dialogue_panel, interaction, player: Node3D, world: Node3D) -> void:
	name = "LibrarySession"
	rng.randomize()
	var librarian := world.find_child(NPC, true, false) as Node3D
	if librarian == null:   # the library is left out by dev_focus.txt: stay inert
		return
	host = Host.new()
	add_child(host)
	host.setup(self, {"activity": ACTIVITY, "group": "library", "speaker": "library.rosa"},
			lexicon, dialogue_panel, interaction, player, librarian)
	host.play_chosen.connect(_start)
	host.choice_made.connect(_on_choice)
	host.talk_closed.connect(_on_talk_closed)
	host.leave_answered.connect(_on_leave_answered)
	var shelves := librarian.get_parent().get_node_or_null("CategoryShelves") as Node3D
	if shelves == null:
		return
	cart = shelves.get_node_or_null("Return cart") as Node3D
	if cart != null and cart.has_node("Slots"):
		slots = cart.get_node("Slots").get_children()
	var display := shelves.get_node_or_null("New books shelf/ReturnBooks")
	if display != null:
		for book in display.get_children():
			if book.has_meta("library_category"):
				var title := str(book.get_meta("book_title", book.title))
				catalog.append({"title": title, "category": str(book.get_meta("library_category")),
						"color": book.spine_color, "thickness": float(book.size.z), "word": str(Library.BOOK_WORDS.get(title, "book"))})
	for gap in shelves.find_children("Gap *", "Node3D", true, false):
		if not gap.has_meta("library_category"):
			continue
		gaps.append(gap)
		Interactable.attach(gap, {
			"prompt_distance": 1.8,
			"priority": 2.5,
			"badge_offset": Vector3(0, .3, .12),
			"on_check": _can_place.bind(gap),
			"on_use": _place.bind(gap),
		})
	_fill_cart()

func activity_running() -> bool:
	return playing

## Rosa calls only while she has a cart to offer (none while the sorted books rest on the shelves).
func _host_near(distance: float) -> bool:
	return not resting and distance < float(host.spec.call_distance)

## Rosa's line is on screen (the game itself goes on around the library while she is quiet).
func busy() -> bool:
	return host != null and host.owns_dialogue()

# --- Rosa ---------------------------------------------------------------------------------

## "Yes" on the greeting (or the minigame picker): sorting the books waiting on the cart (a fresh
## cart when none is waiting, e.g. after "I'll help later" or from the picker during a rest).
func _start() -> void:
	if books.is_empty() or books.any(func(b): return not _on_cart(b)):
		_fill_cart()
	if books.is_empty():
		push_error("library: return cart or collection missing")
		return
	met = true
	resting = false
	_asked_at_edge = false
	_inside_spots.clear()
	_asked.clear()
	playing = true
	_finishing = false
	Board.shared().begin(ACTIVITY)
	host.say("library.start", [], 4.0)

## Clears this game's books (borrowed from the shelves, or left on the cart) and puts 3-6 new
## ones on the cart.
func _fill_cart() -> void:
	_clear_books()
	if cart == null or slots.is_empty() or catalog.is_empty():
		return
	var picks := catalog.duplicate()
	_shuffle(picks)
	# Books whose topic word is due come first, then allowed new ones (word_memory.gd, 24 Nov
	# 2026); the shuffle above breaks ties.
	var ranked: Array = preload("res://scripts/learning/word_memory.gd").shared().order(picks.map(func(e): return str(e.word)), rng)
	picks.sort_custom(func(a, b): return ranked.find(str(a.word)) < ranked.find(str(b.word)))
	var places := slots.duplicate()
	_shuffle(places)
	var count := mini(rng.randi_range(BOOKS_MIN, BOOKS_MAX), mini(picks.size(), places.size()))
	for i in count:
		books.append(_cart_book(picks[i], places[i]))

func _on_cart(book: Node3D) -> bool:
	return is_instance_valid(book) and slots.has(book.get_parent())

## The rest is over: the sorted books are borrowed, a new cart fills and Rosa offers again.
func replenish() -> void:
	resting = false
	_fill_cart()
	host.offered = true

## Talking to Rosa: her first greeting is the host's default; later ones greet the player back.
## During the game she says what is left (she never checks the shelves).
func _host_talk(_talker: Node3D) -> bool:
	if not playing:
		if resting:
			host.say("library.all_back")
		elif not host.gate():
			host.offer("" if not met else "library.greeting_again")
			met = true
		return true
	if _finishing:
		return true
	var hand := HandHold.of_player(self)
	var choices := [host.choice("ok", "library.ok", "check"), host.choice("later", "library.later", "no")]
	if hand != null and books.has(hand.held):
		host.say("library.holding", choices, 0.0)
		return true
	var left := _left()
	if left == 1:
		host.say("library.left_one", choices, 0.0)
	else:
		host.say("library.left_many", choices, 0.0, {"count": _number(left)})
	return true

func _on_choice(id: String) -> void:
	match id.trim_prefix(host.choice_prefix()):
		"ok":
			host.close_dialogue()
		"later":
			_stop()

## The game ends unfinished ("I'll help later", or yes on the leave question): the books go away.
func _stop() -> void:
	host.abandon_practice()
	_clear_books()
	playing = false
	_finishing = false
	host.say("library.stopped")

## A line closed (auto-close, ✕ or walking away): the start's second line follows the first.
func _on_talk_closed(line_id: String) -> void:
	if line_id == "library.start" and playing:
		_say_later.call_deferred("library.start_signs")


func _say_later(id: String) -> void:
	if playing and not host.dialogue_panel.is_dialogue_visible():
		host.say(id)

## How many of this game's books are not yet on their own shelf (on the cart or in the hand).
func _left() -> int:
	var n := 0
	for book in books:
		if not _home(book):
			n += 1
	return n

func _home(book: Node3D) -> bool:
	return _shelved(book) and str(book.get_parent().get_meta("library_category")) == str(book.get_meta("library_category"))

## A number in both languages for a {count} value.
func _number(n: int) -> Dictionary:
	var lexicon = host.lexicon
	return {lexicon.foreign: lexicon.number(n, lexicon.foreign, true), lexicon.native: lexicon.number(n, lexicon.native, true)}

## Every book is home: after the last flourish, the camera zooms in on Rosa and she thanks the
## player (the zoom goes back when her line closes, minigame_host.gd). A line a session says by
## itself does not zoom; only the player starting a talk does (minigame_host.gd _on_talk).
func _finish() -> void:
	if not playing or _left() > 0:
		_finishing = false
		return
	playing = false
	_finishing = false
	resting = true
	host.offered = false
	# The board's "completed" (missions, achievements, the results screen; 21 Nov 2026).
	Board.shared().complete(ACTIVITY)
	host.zoom(true)
	host.say("library.perfect")

## The player has left the sorted books behind: farther than Rosa's call distance, with the cart
## and this game's books off screen, so the new cart never fills in front of them.
func _walked_away() -> bool:
	var player: Node3D = host.player
	if not is_instance_valid(player) or host.npc.global_position.distance_to(player.global_position) <= float(host.spec.call_distance):
		return false
	var view := get_viewport().get_camera_3d()
	if view == null:
		return true
	if cart != null and view.is_position_in_frustum(cart.global_position + Vector3.UP * .8):
		return false
	for book in books:
		if is_instance_valid(book) and book.is_inside_tree() and view.is_position_in_frustum(book.global_position):
			return false
	return true

## A language change in Settings: the game ends; Rosa's name follows the new languages.
func end_activity() -> void:
	if host == null:
		return
	if playing:
		host.abandon_practice()
		_clear_books()
		playing = false
		_fill_cart()
	_finishing = false
	_asked_at_edge = false
	host.cancel_leave()
	host.close_dialogue()
	host.refresh_name()

func _process(delta: float) -> void:
	if host == null:
		return
	_watch_hand()
	_check_zone(delta)
	if resting and not busy() and _walked_away():
		replenish()
	host.tick(delta)

# --- Leaving --------------------------------------------------------------------------------

## Esc / back while the game runs (Main, the request_leave() contract, docs/guides/MINIGAMES.md):
## asks the shared leave question. True when the press was taken.
func request_leave() -> bool:
	if host == null or not playing or _finishing:
		return false
	if not host.is_asking_leave():
		host.ask_leave()
	return true

func _on_leave_answered(leave: bool) -> void:
	var at_edge := _asked_at_edge
	_asked_at_edge = false
	if at_edge:
		if not leave and _zones() != null and _zones().resolve_global(host.player.global_position) != ZONE:
			_step_back_in()
		if get_parent() != null and get_parent().has_method("sync_player_controls"):
			get_parent().sync_player_controls()
	if leave and playing:
		_stop()

## Main's town zones (null before they exist or without Main).
func _zones() -> Object:
	return get_parent().get("zones") if get_parent() != null else null

## During a game, remembers where the player stands inside the library and asks to leave when
## they walk out.
func _check_zone(delta: float) -> void:
	_zone_timer += delta
	if _zone_timer < ZONE_CHECK_INTERVAL:
		return
	_zone_timer = 0.0
	var zones := _zones()
	if not playing or zones == null or not is_instance_valid(host.player):
		_inside_spots.clear()
		return
	if zones.resolve_global(host.player.global_position) == ZONE:
		_inside_spots.append(host.player.global_position)
		if _inside_spots.size() > INSIDE_SPOTS:
			_inside_spots.pop_front()
	elif not _finishing and not _inside_spots.is_empty():
		_ask_at_edge()

func _ask_at_edge() -> void:
	_step_back_in()
	if _asked_at_edge or host.is_asking_leave():
		return
	_asked_at_edge = true
	host.player.set_controls_enabled(false)
	host.ask_leave()

## Puts the player at their oldest remembered spot inside the library, facing Rosa.
func _step_back_in() -> void:
	if _inside_spots.is_empty():
		return
	var player: Node3D = host.player
	player.global_position = _inside_spots[0]
	player.velocity = Vector3.ZERO
	var look: Vector3 = host.npc.global_position - player.global_position
	if Vector2(look.x, look.z).length() > 0.1:
		var yaw := atan2(-look.x, -look.z)
		player.rotation.y = yaw
		player.camera_yaw = yaw
	player.reset_camera()

# --- Practice -------------------------------------------------------------------------------

## The words a book's placement tests: its topic and its category.
func _words(book: Node3D) -> Array:
	var category := str(book.get_meta("library_category"))
	for entry in Library.CATEGORIES:
		if entry[0] == category:
			return [str(book.get_meta("word_key")), str(entry[3])]
	return [str(book.get_meta("word_key"))]

## Opens a book's question the first time it is taken in the hand during a game.
func _watch_hand() -> void:
	if _hand == null or not is_instance_valid(_hand):
		_hand = HandHold.of_player(self)
		if _hand == null:
			return
		_hand.held_changed.connect(_on_held)

func _on_held(item: Node3D) -> void:
	if not playing or item == null or not books.has(item) or _asked.has(item) or _asking == item:
		return
	_asking = item
	PracticeLog.shared().begin(ACTIVITY, _words(item))

## A book's first placement answers its question (later tries are not recorded).
func _answer(book: Node3D, right: bool) -> void:
	if _asked.has(book):
		return
	_asked.append(book)
	if _asking == book and PracticeLog.shared().game_id() == ACTIVITY:
		PracticeLog.shared().first_answer(right)
		PracticeLog.shared().complete()
	_asking = null

# --- Books --------------------------------------------------------------------------------

## A copy of a display book on a cart slot, leaning back like the books on the display.
func _cart_book(entry: Dictionary, slot: Node3D) -> Node3D:
	var book: Node3D = BOOK_SCENE.instantiate()
	book.name = "Cart book " + str(entry.title)
	book.title = entry.title
	var t: float = entry.thickness
	book.size = Vector3(Book.PICTURE.x, Book.PICTURE.y, t)
	book.spine_color = entry.color
	book.holdable = true
	book.set_meta(SORT_META, true)
	book.set_meta("library_category", entry.category)
	book.set_meta("book_title", entry.title)
	book.set_meta("word_key", entry.word)
	slot.add_child(book)
	book.position = Vector3(0, t * .5 * sin(Library.CART_LEAN), t * .5)
	book.rotation.x = Library.CART_LEAN
	book.set_meta("cart_slot", slot)
	book.set_meta("cart_transform", book.transform)
	SignLanguage.translate_all(book)
	return book

func _shelved(book: Node3D) -> bool:
	return is_instance_valid(book) and gaps.has(book.get_parent())

func _gap_free(gap: Node3D) -> bool:
	for child in gap.get_children():
		if child.has_meta(SORT_META):
			return false
	return true

## A gap offers "E" while the hand holds one of this game's books and nothing stands in it.
func _can_place(gap: Node3D) -> bool:
	if not playing:
		return false
	var hand := HandHold.of_player(self)
	return hand != null and books.has(hand.held) and _gap_free(gap)

func _place(gap: Node3D) -> void:
	var hand := HandHold.of_player(self)
	if hand == null or not books.has(hand.held) or not _gap_free(gap):
		return
	var book: Node3D = hand.release(gap, gap.global_transform * SHELVED)
	if book == null:
		return
	if str(book.get_meta("library_category")) != str(gap.get_meta("library_category")):
		_answer(book, false)
		shelved_wrong.emit()
		_wobble(book, gap)
		return
	_answer(book, true)
	shelved_right.emit()
	_celebrate(book)
	if _left() == 0 and not _finishing:
		_finishing = true
		get_tree().create_timer(FINISH_DELAY).timeout.connect(_finish)

## Wrong shelf: the book wobbles side to side in the gap (no sparks), then goes back to its cart
## slot and into the hand (when the hand is still free), so it never stays on a wrong shelf.
func _wobble(book: Node3D, gap: Node3D) -> void:
	var home := book.position
	# Along the shelf (gap frame: X along the shelf, Z into its depth).
	var side := Vector3.RIGHT
	var tween := book.create_tween()
	for i in WOBBLES:
		tween.tween_property(book, "position", home + side * WOBBLE, WOBBLE_SWING * .5).set_trans(Tween.TRANS_SINE)
		tween.tween_property(book, "position", home - side * WOBBLE, WOBBLE_SWING).set_trans(Tween.TRANS_SINE)
	tween.tween_property(book, "position", home, WOBBLE_SWING * .5).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(_back_to_hand.bind(book, gap))

func _back_to_hand(book: Node3D, gap: Node3D) -> void:
	if not is_instance_valid(book) or book.get_parent() != gap or not books.has(book):
		return   # taken again during the wobble, or the game ended
	var slot: Node3D = book.get_meta("cart_slot")
	gap.remove_child(book)
	slot.add_child(book)
	book.transform = book.get_meta("cart_transform")
	var hand := HandHold.of_player(self)
	if playing and hand != null and not hand.is_holding():
		hand.hold(book)

## Right shelf: the book slides home, hops, and gold sparks puff out of the gap.
func _celebrate(book: Node3D) -> void:
	var home := book.position
	var out := home + Vector3(0, 0, -SLIDE)
	book.position = out
	var tween := book.create_tween()
	tween.tween_property(book, "position", home, .16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(book, "position", home + Vector3(0, HOP, 0), .11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(book, "position", home, .14).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	# The swell stops touching the book once it is taken from the gap again (the hand sets its size).
	var size := book.scale
	var gap := book.get_parent()
	var grow := func(k: float) -> void:
		if is_instance_valid(book) and book.get_parent() == gap:
			book.scale = size * k
	var swell := book.create_tween()
	swell.tween_interval(.16)
	swell.tween_method(grow, 1.0, SWELL, .11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	swell.tween_method(grow, SWELL, 1.0, .18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_sparks(book.get_parent() as Node3D)

func _sparks(gap: Node3D) -> void:
	# The shared burst (success_burst.gd, moved out of here 21 Nov 2026), in the gap's frame and size.
	var centre := Vector3(0, Book.PICTURE.y * .6, -.02)
	SuccessBurst.sparks(gap, gap.global_transform * Transform3D(Basis(), centre), gap.global_basis.get_scale().x * SPARK_SCALE, SPARK_COUNT, SPARK_SECONDS)

## Removes this game's books (from the cart, the shelves and the hand).
func _clear_books() -> void:
	_asked.clear()
	_asking = null
	var hand := HandHold.of_player(self)
	if hand != null and books.has(hand.held):
		hand.release(null, null, false)
	for book in books:
		if is_instance_valid(book):
			if book.get_parent() != null:
				book.get_parent().remove_child(book)
			book.queue_free()
	books.clear()

func _shuffle(list: Array) -> void:
	for i in list.size():
		var j := rng.randi_range(i, list.size() - 1)
		var swap = list[i]
		list[i] = list[j]
		list[j] = swap
