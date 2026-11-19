extends SceneTree
## 18 Nov 2026: small polish batch, without loading the town.
## - Library books (scripts/world/library_book.gd): only books with a cover title process; a
##   title's fit uses the authored pixel size; on the web (SignLanguage.share_sizes) the title is
##   drawn at a shared RenderCulling.LABEL_SIZES step with the same world size, so books no longer
##   make one glyph atlas per fitted size.
## - The welcome tutorial's Skip button is a BonStyle soft pill (scripts/learning/tutorial.gd).
## HOME=<scratch> godot --path . --resolution 1280x800 --script res://docs/evidence/ui-perf-polish-20261118/verify.gd
## (headless: checks only). With graphics writes books_native.png, books_web.png and skip.png here.
const OUT := "res://docs/evidence/ui-perf-polish-20261118"
const BOOK_SCENE := preload("res://scenes/props/book.tscn")
const Book := preload("res://scripts/world/library_book.gd")
const SignLanguage := preload("res://scripts/world/sign_language.gd")
const RenderCulling := preload("res://scripts/world/render_culling.gd")
const BonStyle := preload("res://scripts/ui/bon_style.gd")
const TITLES := ["Dinosaurs", "Ocean Animals", "The Solar System", "World Map", "Stars", "Rivers"]
var checks := 0
var failures := 0
var graphics := false

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok:
		failures += 1

func title_of(book: Node3D) -> Label3D:
	for label in book.find_children("*", "Label3D", true, false):
		return label
	return null

## Builds a row of books, lets them fit, returns {title: [font_size, world_width, world_em, outline_ratio]}.
func shelf(shared: bool, shot: String) -> Dictionary:
	SignLanguage.share_sizes = shared
	var stage := Node3D.new()
	root.add_child(stage)
	var cam := Camera3D.new()
	cam.position = Vector3(1.25, .35, -1.6)
	cam.rotation.y = PI
	stage.add_child(cam)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.6, PI + 0.3, 0)
	stage.add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("f0fafb")
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = .6
	stage.add_child(env)
	var books := []
	for i in TITLES.size():
		var book: Node3D = BOOK_SCENE.instantiate()
		book.title = TITLES[i]
		book.pickable = false
		book.position = Vector3(i * .5, 0, 0)
		stage.add_child(book)
		books.append(book)
	var plain: Node3D = BOOK_SCENE.instantiate()
	plain.position = Vector3(3.2, 0, 0)
	stage.add_child(plain)
	for i in 3:
		await process_frame
	check(not plain.is_processing(), "%s: a plain book does not process" % shot)
	var out := {}
	for book in books:
		check(book.is_processing(), "%s: %s processes (title fitting)" % [shot, book.title])
		var label := title_of(book)
		var ok_step: bool = label.font_size in RenderCulling.LABEL_SIZES
		if shared:
			check(ok_step, "%s: %s at a shared size (%d)" % [shot, book.title, label.font_size])
		out[book.title] = [label.font_size, label.width * label.pixel_size * label.scale.x, label.font_size * label.pixel_size, label.outline_size * label.pixel_size]
	# A language change resets the title from outside (sign_language.gd apply()): it refits.
	var first: Label3D = title_of(books[0])
	first.text = "Dinosaurios"
	first.font_size = 64
	first.pixel_size = Book.TITLE_EM / Book.TITLE_FONT
	await process_frame
	check(books[0].get("_fitted_text") == "Dinosaurios" and (not shared or first.font_size in RenderCulling.LABEL_SIZES), "%s: refits after an outside change (font %d)" % [shot, first.font_size])
	first.text = "Dinosaurs"
	await process_frame
	await process_frame
	if graphics:
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png(OUT + "/" + shot + ".png")
	stage.queue_free()
	await process_frame
	return out

func run() -> void:
	graphics = DisplayServer.get_name() != "headless"
	var native := await shelf(false, "books_native")
	var web := await shelf(true, "books_web")
	for title in TITLES:
		var a: Array = native[title]
		var b: Array = web[title]
		check(absf(a[1] - b[1]) < 0.002, "%s: same wrap width in the world (%.4f / %.4f)" % [title, a[1], b[1]])
		check(absf(a[2] - b[2]) / a[2] < 0.001, "%s: same letter size in the world (native font %d, web %d)" % [title, a[0], b[0]])
		check(absf(a[3] - b[3]) / maxf(a[3], 0.0001) < 0.35, "%s: outline about the same in the world" % title)
	var sizes := {}
	for title in TITLES:
		sizes[web[title][0]] = true
	print("native sizes: ", TITLES.map(func(t): return native[t][0]), "  web sizes: ", sizes.keys())
	# The tutorial's Skip button as built in tutorial.gd _make_skip_button() / _process().
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color("9fd38a")
	bg.size = Vector2(1280, 800)
	layer.add_child(bg)
	var skip := BonStyle.button("", "soft", "", 1.0, 24.0, Vector2(150, 56))
	layer.add_child(skip)
	var f := 1.0
	skip.text = "Skip"
	BonStyle.style_button(skip, "soft", f, 24.0)
	skip.custom_minimum_size = Vector2(150, 56) * f
	skip.size = skip.get_minimum_size()
	skip.position = Vector2((1280 - skip.size.x) * .5, 10)
	await process_frame
	check(skip.get_theme_stylebox("normal") is BonStyle.BonBox, "Skip button uses a BonStyle box")
	check(skip.get_theme_color("font_color") == BonStyle.INK, "Skip text is INK on soft blue")
	check(skip.size.y >= 56, "Skip button finger sized (%.0f px)" % skip.size.y)
	if graphics:
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().get_region(Rect2i(440, 0, 400, 120)).save_png(OUT + "/skip.png")
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
