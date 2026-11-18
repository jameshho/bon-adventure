extends SceneTree
## Nearby loading, stages 0-3 (17 Nov 2026, docs/guides/performance/README.md "Load only
## nearby buildings on phones"), natively with the web paths forced (VT_NEARBY=1,
## sign_language.share_sizes):
## - a town started for a player at the home holds the near units only (initial_for()),
## - every translated sign stays on a shared LABEL_SIZES step with its world size kept, also
##   after Main.apply_world_language() and after more units are added,
## - nearby_units.gd adds the school when the player stands there and leaves far units alone,
## - the minigame picker builds the police station for Officer Rocco's game and starts it,
## - Main.ensure_unit() (tutorial replay) builds a pending unit.
## Headless; writes no saves with an isolated HOME:
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none VT_NEARBY=1 godot --headless --path . --script res://docs/evidence/nearby-loading-20261117/verify.gd
const SignLanguage := preload("res://scripts/world/sign_language.gd")
const NearbyUnits := preload("res://scripts/world/nearby_units.gd")
const RenderCulling := preload("res://scripts/world/render_culling.gd")
const Board := preload("res://scripts/learning/activity_board.gd")

var main: Node
var failures := 0
var checks := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("PASS " if ok else "FAIL ") + label)

func frames(n: int) -> void:
	for i in n:
		await process_frame

func centre(key: String) -> Vector2:
	var box: Array = NearbyUnits.data().boxes[key][0]
	return Vector2((box[0] + box[2]) * 0.5, (box[1] + box[3]) * 0.5)

func stand_at(key: String) -> void:
	var at := centre(key)
	main.player.global_position = main.apartment.to_global(Vector3(at.x, 3.0, at.y))
	main.player.velocity = Vector3.ZERO

## Every translated sign that is not a world sign: on a shared step, and the same size in the
## world as its authored size times a shrink (font_size x pixel_size / authored pixel = a whole
## font size between half the authored one and the authored one).
func check_signs(when: String) -> void:
	var off_step := 0
	var wrong_size := 0
	var pairs := {}
	var count := 0
	for label: Label3D in main.get_tree().get_nodes_in_group(SignLanguage.GROUP):
		if label.has_meta("world_sign") or not label.has_meta("sign_pixel_base"):
			continue
		# Library book titles: library_book.gd fits their size itself after sign_language
		# (found 17 Nov 2026; a few glyph caches, left to the library's owner).
		if _in_book(label):
			continue
		count += 1
		pairs["%d/%d" % [label.font_size, label.outline_size]] = true
		if not RenderCulling.LABEL_SIZES.has(label.font_size) and label.font_size <= RenderCulling.LABEL_SIZES.back():
			off_step += 1
			print("  off step: ", label.get_path(), " size ", label.font_size, " authored ", label.get_meta("sign_font_size"), " world_sign ", label.has_meta("world_sign"))
		var authored := float(label.get_meta("sign_font_size"))
		var shown := label.font_size * label.pixel_size / float(label.get_meta("sign_pixel_base"))
		if absf(shown - roundf(shown)) > 0.01 or shown > authored + 0.01 or shown < authored * SignLanguage.MIN_SHRINK - 1.0:
			wrong_size += 1
	check(count > 0 and off_step == 0, "%s: %d signs, all on a shared size step (%d off)" % [when, count, off_step])
	check(wrong_size == 0, "%s: signs keep their size in the world (%d wrong)" % [when, wrong_size])
	print("  %s: %d size/outline pairs among signs" % [when, pairs.size()])

func _in_book(node: Node) -> bool:
	while node != null:
		var script: Script = node.get_script()
		if script != null and script.resource_path.ends_with("library_book.gd"):
			return true
		node = node.get_parent()
	return false

func run() -> void:
	SignLanguage.share_sizes = true
	check(NearbyUnits.enabled(), "VT_NEARBY=1 turns nearby loading on")
	check(NearbyUnits.unit_of_activity("lineup_rocco") == "police", "data: Rocco's game lives in the police unit")
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	var apartment: Node3D = main.get_node("Apartment")
	var first: Array = NearbyUnits.initial_for(centre("home"), apartment.transform.basis.get_scale().x, ["home"])
	print("  initial units at the home: ", first)
	check(first.has("home") and first.has("library") and first.has("restaurants"), "start at the home: home, library and restaurants are near")
	check(not first.has("school") and not first.has("police") and not first.has("airport") and not first.has("hospital"), "start at the home: school, police, airport, hospital are not")
	main.staged_loading = true
	main.initial_units = first
	get_root().add_child(main)
	await main.town_ready
	var loaded: Array = main.apartment.get_meta("loaded_units", [])
	check(loaded.size() == first.size() and first.all(func(k) -> bool: return loaded.has(k)), "the town holds exactly the near units")
	check(main.pending_units.has("school") and main.pending_units.has("police"), "far units are pending")
	check_signs("start")
	main.apply_world_language()
	check_signs("after apply_world_language")
	var nearby := NearbyUnits.new()
	nearby.setup(main)
	main.add_child(nearby)
	stand_at("school")
	var waited := 0
	while not main.apartment.get_meta("loaded_units", []).has("school") and waited < 1200:
		stand_at("school")
		await process_frame
		waited += 1
	check(main.apartment.get_meta("loaded_units", []).has("school"), "standing at the school adds it (%d frames)" % waited)
	await frames(240)
	check(main.pending_units.has("police") and main.pending_units.has("supermarket"), "police and supermarket (far west) stay pending")
	check_signs("after adding units")
	# The picker: Rocco's game while the police station is not built.
	await frames(60)
	var launcher = main.game_launcher
	check(launcher.blocked("lineup_rocco") == "", "picker: Rocco's game can be played though its building is pending")
	check(launcher.launch("lineup_rocco"), "picker: Play accepted")
	waited = 0
	while Board.shared().session("lineup_rocco") == null and waited < 600:
		await process_frame
		waited += 1
	await frames(30)
	check(Board.shared().session("lineup_rocco") != null, "picker: the police station was built and Rocco's session exists")
	var police_at := centre("police")
	var here: Vector3 = main.apartment.to_local(main.player.global_position)
	check(Vector2(here.x, here.z).distance_to(police_at) < 40.0, "picker: the player was taken to the police station (%.0f town units from its centre)" % Vector2(here.x, here.z).distance_to(police_at))
	await main.ensure_unit("airport")
	check(main.apartment.get_meta("loaded_units", []).has("airport"), "ensure_unit builds a pending unit (tutorial replay)")
	print("nearby loading verify: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
