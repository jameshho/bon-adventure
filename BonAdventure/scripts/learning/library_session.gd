extends Node
## Rosa's book-sorting game (user design, 13 Nov 2026; docs/guides/MINIGAMES.md, design record
## docs/guides/TOWN_DESIGN_BRIEF.md "Library return cart and book-sorting game"):
##
##   1. Rosa the librarian (`Librarian`, samoyed plush beside the NEW BOOKS display, placed by
##      scripts/buildings/library.gd) shows the gold "!" and asks "Can you help me return these
##      books to their proper shelves?" (shared host and dialogue box, minigame_host.gd).
##   2. "Yes": 3-6 books, picked at random from the library's own collection (the 24 titles on
##      the NEW BOOKS display: same title, category colour and thickness), appear on the rolling
##      return cart beside her (`Return cart/Slots/Slot <n>`).
##   3. The player takes a book in the hand (E on it: library_book.gd `holdable`, hand_hold.gd)
##      and, at any gap on any category bookcase (`Bookcase <Category>/Gaps/Gap ...`, each given
##      an Interactable here), E puts it there, spine out. Right category: the book slides in,
##      hops and gives off a few gold sparks. Wrong category: nothing at all; the book simply
##      stays there. Any order; a shelved book can be taken again.
##   4. Talking to Rosa during the game: "Are you finished?" -> "I'm finished!" makes her check:
##      a book still on the cart or in the hand -> library.cart_left; else a wrong book ->
##      library.wrong_<category> naming that shelf, never the book; else library.perfect and the
##      game ends ("Not yet" / "Stop helping" also offered). The player keeps fixing until
##      perfect. She calls with "!" while the cart is empty and the hand holds none of them.
##   5. The shelved books stay until the next game, which clears them and fills the cart again.
##
## Text: data/phrases.json group "library"; offers: data/activities.json "library_rosa". Nothing
## is saved or practised (titles are signs, not vocabulary words).
const Host := preload("res://scripts/learning/minigame_host.gd")
const Interactable := preload("res://scripts/core/interactable.gd")
const HandHold := preload("res://scripts/player/hand_hold.gd")
const SignLanguage := preload("res://scripts/world/sign_language.gd")
const Board := preload("res://scripts/learning/activity_board.gd")
const Library := preload("res://scripts/buildings/library.gd")
const Book := preload("res://scripts/world/library_book.gd")
const BOOK_SCENE := preload("res://scenes/props/book.tscn")
const NPC := "Librarian"
const ACTIVITY := "library_rosa"
const BOOKS_MIN := 3
const BOOKS_MAX := 6
## Meta on this game's books (the display's own books carry return_book instead).
const SORT_META := "sort_book"
## Where a book stands in a gap (gap frame: on the shelf, spine side -Z): spine out, its cover
## width across the shelf depth.
const SHELVED := Transform3D(Basis(Vector3.UP, PI / 2), Vector3(0, 0, Book.PICTURE.x * .5))
## The right-shelf flourish: slide in from this far out, hop this high, this many sparks.
const SLIDE := .14
const HOP := .07
const SPARKS := 10

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
var _spark_mesh: SphereMesh

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
				catalog.append({"title": str(book.get_meta("book_title", book.title)), "category": str(book.get_meta("library_category")),
						"color": book.spine_color, "thickness": float(book.size.z)})
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

func activity_running() -> bool:
	return playing

## Rosa's line is on screen (the game itself goes on around the library while she is quiet).
func busy() -> bool:
	return host != null and host.owns_dialogue()

# --- Rosa ---------------------------------------------------------------------------------

## "Yes" on the greeting (or the minigame picker): a fresh cart.
func _start() -> void:
	_clear_books()
	if cart == null or slots.is_empty() or catalog.is_empty():
		push_error("library: return cart or collection missing")
		return
	var picks := catalog.duplicate()
	_shuffle(picks)
	var places := slots.duplicate()
	_shuffle(places)
	var count := mini(rng.randi_range(BOOKS_MIN, BOOKS_MAX), mini(picks.size(), places.size()))
	for i in count:
		books.append(_cart_book(picks[i], places[i]))
	playing = true
	Board.shared().begin(ACTIVITY)
	host.say("library.start")

## During the game: "Are you finished?"
func _host_talk(_talker: Node3D) -> bool:
	if not playing:
		return false
	host.say("library.ask_done", [host.choice("done", "library.done", "check"),
			host.choice("later", "library.not_yet", "next"), host.choice("stop", "library.stop", "no")], 0.0)
	return true

func _on_choice(id: String) -> void:
	match id.trim_prefix(host.choice_prefix()):
		"done":
			_check()
		"later":
			host.say("library.keep_going")
		"stop":
			_clear_books()
			playing = false
			host.say("library.stopped")

## Rosa looks over the cart and the shelves.
func _check() -> void:
	for book in books:
		if not _shelved(book):
			host.say("library.cart_left")
			return
	for book in books:
		var category := str(book.get_parent().get_meta("library_category"))
		if category != str(book.get_meta("library_category")):
			host.say("library.wrong_" + category)
			return
	playing = false
	host.offered = true
	host.say("library.perfect")

## Rosa calls the player back once every book is off the cart and out of the hand.
func _host_calling() -> bool:
	if not playing or books.is_empty():
		return false
	for book in books:
		if not _shelved(book):
			return false
	return not host.owns_dialogue()

## A language change in Settings: the game ends; Rosa's name follows the new languages.
func end_activity() -> void:
	if host == null:
		return
	if playing:
		_clear_books()
		playing = false
	host.close_dialogue()
	host.refresh_name()

func _process(delta: float) -> void:
	if host != null:
		host.tick(delta)

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
	slot.add_child(book)
	book.position = Vector3(0, t * .5 * sin(Library.CART_LEAN), t * .5)
	book.rotation.x = Library.CART_LEAN
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
	if book != null and str(book.get_meta("library_category")) == str(gap.get_meta("library_category")):
		_celebrate(book)

## Right shelf: the book slides home, hops, and gold sparks puff out of the gap.
func _celebrate(book: Node3D) -> void:
	var home := book.position
	var out := home + Vector3(0, 0, -SLIDE)
	book.position = out
	var tween := book.create_tween()
	tween.tween_property(book, "position", home, .16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(book, "position", home + Vector3(0, HOP, 0), .11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(book, "position", home, .14).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_sparks(book.get_parent() as Node3D)

func _sparks(gap: Node3D) -> void:
	if _spark_mesh == null:
		_spark_mesh = SphereMesh.new()
		_spark_mesh.radius = .035
		_spark_mesh.height = .07
		_spark_mesh.radial_segments = 8
		_spark_mesh.rings = 4
		var glow := StandardMaterial3D.new()
		glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glow.albedo_color = Color("ffd34d")
		_spark_mesh.material = glow
	var centre := Vector3(0, Book.PICTURE.y * .6, -.02)
	for i in SPARKS:
		var spark := MeshInstance3D.new()
		spark.mesh = _spark_mesh
		spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		gap.add_child(spark)
		spark.position = centre
		var angle := TAU * i / SPARKS + rng.randf_range(-.25, .25)
		var to := centre + Vector3(cos(angle) * .42, sin(angle) * .38 + .1, -.16)
		var tween := spark.create_tween().set_parallel()
		tween.tween_property(spark, "position", to, .5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(spark, "scale", Vector3.ONE * .01, .45).set_delay(.2)
		tween.chain().tween_callback(spark.queue_free)

## Removes this game's books (from the cart, the shelves and the hand).
func _clear_books() -> void:
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
