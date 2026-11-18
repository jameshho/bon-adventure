extends SceneTree
## 11 Nov 2026 library category shelves (docs/guides/TOWN_DESIGN_BRIEF.md "Library category shelves"):
## eight category bookcases with translated headers and gaps, the return shelf with the 24
## picture books (each with a fitting home gap on its own category's bookcase), clear routes,
## and Rosa's greeting (since 13 Nov 2026 Yes starts the book-sorting game:
## docs/evidence/library-sorting-20261113/verify.gd covers it).
## Fixture updated 17 Nov 2026 to the current library (six categories since 16 Nov, the 17 Nov
## titles, topic words on the display books, the computer desks gone and the NEW BOOKS display at
## the rear wall); the counts come from library.gd instead of being written here.
## The west aisle route now stops at z 50.6: the old desk corner beyond it holds the cosy room's
## rear corner plant and lamp (a dead end, not a walkway).
## HOME=<scratch> VT_FOCUS=all VT_SPAWN=none godot --headless --path . --script res://docs/evidence/library-shelves-20261111/verify.gd
## Writes nothing (study progress stays in the isolated HOME).
const Library := preload("res://scripts/buildings/library.gd")
const SignLanguage := preload("res://scripts/world/sign_language.gd")
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	await physics_frame
	await physics_frame
	var library: Node3D = game.apartment.get_node("RelocatedSites/Library")
	var words: Dictionary = preload("res://scripts/learning/word_data.gd").load_all().vocabulary
	var shelves: Node3D = library.get_node_or_null("CategoryShelves")
	check(shelves != null, "category shelves built")
	if shelves == null:
		_finish()
		return
	# --- old fittings gone
	for title in ["Bookcase backing", "Shelved book", "FICTION framed sign", "DISCOVER framed sign", "Book Bin"]:
		check(not library.has_node(title), "removed: " + title)
	# --- the category bookcases, headers in the learner's language, books and gaps
	var titles_total := 0
	for category in Library.CATEGORIES:
		titles_total += Library.BOOKS[category[0]].size()
	var cases := {}
	for category in Library.CATEGORIES:
		var frame: Node3D = shelves.get_node_or_null("Bookcase " + String(category[0]).capitalize())
		check(frame != null and str(frame.get_meta("word_key", "")) == "bookshelf", "bookcase " + category[0])
		if frame == null:
			continue
		cases[category[0]] = frame
		var sign := frame.get_node_or_null(category[1] + " sign") as Label3D
		check(sign != null and sign.text in [category[1], SignLanguage.say(category[1], "es")], "%s header reads %s" % [category[0], sign.text if sign else "-"])
		var rows := 0
		for child in frame.get_children():
			if String(child.name).begins_with("Books ") and str(child.get_meta("word_key", "")) == "book" and child.find_children("*", "Area3D", false, false).size() > 0:
				rows += 1
		# Four rows since 12 Nov 2026 (40 % larger books, step big_books; five before).
		check(rows == Library.TIERS.size(), "%s has %d clickable book rows (%d)" % [category[0], Library.TIERS.size(), rows])
		check(frame.get_node("Gaps").get_child_count() >= 3, "%s has gaps" % category[0])
	check(words.has("bookshelf") and words.has("book") and words.has("book bin") and words.has("shelf"), "words exist")
	# --- the picture books and their home gaps
	var books: Node3D = shelves.get_node_or_null("New books shelf/ReturnBooks")
	check(books != null and books.get_child_count() == titles_total, "%d books on the NEW BOOKS display" % titles_total)
	check(shelves.has_node("Book drop") and str(shelves.get_node("Book drop").get_meta("word_key", "")) == "book bin", "book drop keeps the book bin word")
	if books != null:
		var titles := {}
		for book in books.get_children():
			var id := str(book.get_meta("library_category", ""))
			var title := str(book.get_meta("book_title", ""))
			titles[title] = true
			check(bool(book.get_meta("return_book", false)) and str(book.get_meta("word_key", "")) == str(Library.BOOK_WORDS.get(title, "")) and book.has_node("Interaction"), title + " is a clickable book with its topic word")
			check(Library.BOOKS.get(id, []).has(title), title + " belongs to " + id)
			var label := book.find_child(title + " title", true, false) as Label3D
			check(label != null and label.text != "", title + " cover title")
			if not cases.has(id):
				continue
			var gap: Node3D = cases[id].get_node_or_null("Gaps/" + str(book.get_meta("home_gap", "")))
			check(gap != null and str(gap.get_meta("return_book", "")) == String(book.name) and str(gap.get_meta("library_category", "")) == id, title + " has its home gap")
			if gap != null:
				# The reusable book scene (12 Nov 2026) knows its own thickness.
				var thick: float = book.thickness()
				check(float(gap.get_meta("gap_width", 0.0)) > thick, "%s fits its gap (%.3f vs %.3f)" % [title, gap.get_meta("gap_width", 0.0), thick])
		check(titles.size() == titles_total, "%d different titles" % titles_total)
	# --- player-sized routes (library-local; the site is scaled 1.3 in town)
	var space: PhysicsDirectSpaceState3D = game.get_world_3d().direct_space_state
	var capsule := CapsuleShape3D.new()
	capsule.radius = .3
	capsule.height = 1.6
	var shape := PhysicsShapeQueryParameters3D.new()
	shape.shape = capsule
	for route in [[Vector2(-15, 38.2), Vector2(-15, 48.6), "entrance spine"], [Vector2(-15, 48.6), Vector2(-13.2, 48.6), "front of the return shelf"],
			[Vector2(-19.75, 42.5), Vector2(-19.75, 50.6), "west bookcase aisle"], [Vector2(-10.3, 42.5), Vector2(-10.3, 49.0), "east bookcase aisle"],
			[Vector2(-19.5, 47.0), Vector2(-10.5, 47.0), "rear cross aisle"], [Vector2(-13.2, 48.6), Vector2(-12.3, 51.0), "to the NEW BOOKS display"]]:
		var blocked := ""
		for i in range(41):
			var p: Vector2 = route[0].lerp(route[1], i / 40.0)
			shape.transform = Transform3D(library.global_basis.orthonormalized(), library.to_global(Vector3(p.x, 1.0, p.y)))
			var hits := space.intersect_shape(shape, 1)
			if not hits.is_empty():
				blocked = "%s at %s" % [hits[0].collider.get_parent().name, p]
				break
		check(blocked == "", "route " + route[2] + " clear " + blocked)
	# --- Rosa: "!" host, greeting, Yes -> the sorting game's first line
	var rosa: Node3D = library.get_node_or_null(Library.LIBRARIAN)
	check(rosa != null, "Rosa stands in the library")
	var session = game.find_child("LibrarySession", true, false)
	check(session != null and session.host != null, "library session set up")
	if rosa != null and session != null and session.host != null:
		check(is_talker(rosa), "Rosa can be talked to")
		var panel = game.shop_panel
		var lexicon = session.host.lexicon
		session.host.offered = true
		talk_to(rosa)
		await process_frame
		check(panel.is_dialogue_visible() and panel.current_line() == lexicon.line("library.greeting"), "Rosa asks to start a mission")
		panel.choice_pressed.emit("library_play")
		await process_frame
		check(panel.is_dialogue_visible() and panel.current_line() == lexicon.line("library.start") and session.playing, "Yes -> the sorting game starts")
	_finish()

func _finish() -> void:
	print("LIBRARY SHELVES: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

## Interaction system (12 Nov 2026): E goes to the input claim or the focus target (Main.use_pressed).
func press_e(game) -> bool:
	game.use_pressed()
	return true

## Talking to an NPC: its Interactable's use (what E, a click or a tap on it does).
func talk_to(npc: Node) -> void:
	preload("res://scripts/core/interactable.gd").on(npc).activate()

func is_talker(npc: Node) -> bool:
	var item = preload("res://scripts/core/interactable.gd").on(npc)
	return item != null and item.enabled and item.kind == item.Kind.TALK

func calls(npc: Node) -> bool:
	var item = preload("res://scripts/core/interactable.gd").on(npc)
	return item != null and item.calling
