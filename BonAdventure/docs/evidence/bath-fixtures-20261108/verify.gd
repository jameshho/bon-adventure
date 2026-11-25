extends SceneTree
## Working toilets and faucets (8 Nov 2026; scripts/world/bath_fixtures.gd, toilet.gd, faucet.gd;
## steps home.gd bath_fixtures and airport.gd restrooms). Headless, writes no files.
## Checks: every fixture exists with its word and the "E" hint and is found by picking; E sits
## on a toilet (9 Nov 2026: E near the bowl sits, E or a click on the lever / push plate flushes)
## and stands up again; a flush runs once and returns the water to rest; a faucet stays on until
## turned off and its water clears afterwards; the sound service (scripts/core/sound.gd) plays
## the flush at the toilet and loops running water at a faucet while it is on; the airport restroom doors are registered and open; the player fits in
## the claim walkways, the doorways and both rooms; the old painted doors are gone and the
## carousel (with its collision) moved; washbasins keep their words.
## Uses Main, which saves progress and settings: run with an isolated HOME (README), e.g.
##   python3 tools/run_checks.py --only bath_fixtures
const Interactable := preload("res://scripts/core/interactable.gd")
const Interaction := preload("res://scripts/player/interaction_controller.gd")
const ModularTown := preload("res://scripts/world/modular_town.gd")
var failures := 0
var checks := 0

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok:
		failures += 1

## Game time (works with or without --fixed-fps).
func wait(seconds: float) -> void:
	await create_timer(seconds).timeout

## Whether a standing player capsule fits at a point (world, feet on the floor).
func fits(game, feet: Vector3) -> bool:
	var shape := CapsuleShape3D.new()
	shape.radius = .76
	shape.height = 2.2
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), feet + Vector3(0, 1.15, 0))
	query.exclude = [game.player.get_rid()]
	query.collision_mask = game.player.collision_mask
	return game.get_world_3d().direct_space_state.intersect_shape(query, 4).is_empty()

const TOILET := "res://scripts/world/toilet.gd"
const FAUCET := "res://scripts/world/faucet.gd"

func fixtures(parent: Node) -> Array:
	return parent.find_children("*", "Node3D", true, false).filter(func(n): return n.get_script() != null and n.get_script().resource_path in [TOILET, FAUCET])

## Points a probe camera (given to the picking controller; the player's spring arm would move
## its own) from `eye` at `target` (toilet-local) with the pointer in the middle, waits a frame
## for the camera to take the new view, then returns what the player would aim at (the real
## picking ray, as E and a click use it). The probe is made the current camera: since 20 Nov 2026
## the controller casts from the viewport's camera (aimed_hit(), the tutorial's close-ups), so a
## probe that is not current left the ray on the player's camera (25 Nov 2026 failure).
var probe: Camera3D
func aim(game, space: Node3D, eye: Vector3, target: Vector3) -> Node3D:
	if probe == null:
		probe = Camera3D.new()
		probe.top_level = true
		# Physics interpolation would ease the probe toward each new view over several frames.
		probe.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		root.add_child(probe)
	game.interaction.camera = probe
	probe.global_position = space.to_global(eye)
	probe.look_at(space.to_global(target))
	probe.make_current()
	probe.reset_physics_interpolation()
	game.interaction.pointer_position = game.get_viewport().get_visible_rect().size * .5
	await process_frame
	# Interactables are not words (12 Nov 2026): the object whose Interactable is aimed at.
	var item: Node = game.interaction.aimed_interactable()
	return item.get_parent() if item != null else game.interaction.aimed_object()

## The sound players (sound.gd) under a node playing a cue.
func sounds(node: Node, cue: String) -> Array:
	return node.get_children().filter(func(n): return n is AudioStreamPlayer3D and str(n.get_meta("sound_cue", "")) == cue)

func run():
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(20): await process_frame
	game.player.set_physics_process(false)
	var home: Node3D = ModularTown.building(game.apartment, "home")
	var terminal: Node3D = game.apartment.get_node_or_null("Airport/Terminal")
	check(home != null and terminal != null, "home and airport loaded (VT_FOCUS must include both)")
	if home == null or terminal == null:
		quit(1)
		return
	var interior: Node3D = terminal.get_node("Interior")
	# --- Fixtures and words -----------------------------------------------------------------
	var home_fixtures := fixtures(home)
	var airport_fixtures := fixtures(interior)
	var words := {}
	for f in home_fixtures + airport_fixtures:
		var key := str(f.get_meta("word_key", ""))
		words[key] = words.get(key, 0) + 1
		check(Interactable.on(f) != null and not f.has_meta("action_hint"), "%s is an interactable (the E badge, no hint meta)" % f.name)
		var body: Node = f.get_node("Solid") if f.has_node("Solid") else f.get_node("Pick")
		check(Interactable.find_for(body, game.apartment) == Interactable.on(f), "%s is picked from its own body" % f.name)
		if f.get_script().resource_path == TOILET:
			var flush: Node3D = f.get_node("Model/Flush")
			check(Interactable.find_for(flush.get_node("Pick"), game.apartment) == Interactable.on(flush) and Interactable.on(flush).needs_aim and not flush.has_meta("click_use"),
				"%s: its flush control is a separate interactable (aimed) that E and a click use" % f.name)
			check(not f.has_method("use"), "%s: E on the bowl does not flush (no use())" % f.name)
			check(game.seating.seats.any(func(seat): return seat.node == f and seat.label == "toilet"), "%s is a seat" % f.name)
	check(AudioServer.get_bus_index("SFX") > 0, "SFX bus exists (default_bus_layout.tres)")
	# The bigger home (13 Nov 2026, home_furnishing.gd): guest suite, family and east-wing baths,
	# each with a toilet, a vanity faucet and a tub faucet, plus the kitchen's Sink tap.
	check(home_fixtures.size() == 10, "home: 3 toilets + 7 faucets (%d)" % home_fixtures.size())
	check(airport_fixtures.size() == 4, "airport: 2 toilets + 2 faucets (%d)" % airport_fixtures.size())
	check(words.get("toilet", 0) == 5 and words.get("faucet", 0) == 9, "words: 5 toilet, 9 faucet (%s)" % words)
	check(home.get_node_or_null("Tap spout") == null and home.get_node_or_null("Sink tap") in home_fixtures, "kitchen: one faucet named Sink tap")
	var sinks := 0
	for n in home.get_children() + interior.get_children():
		if str(n.get_meta("word_key", "")) == "sink": sinks += 1
	check(sinks == 3, "kitchen and airport sinks keep the word sink (home 1, airport 2: %d)" % sinks)
	for title in ["Suite vanity", "Family vanity", "East vanity"]:
		var basin: Node = home.find_child(title + " basin", true, false)
		check(basin != null and str(basin.get_meta("word_key", "")) == "sink", "%s basin keeps the word sink" % title)
	# --- Toilet flush -----------------------------------------------------------------------
	var toilet: Node3D = interior.get_node("Women's restroom toilet")
	var house_toilet: Node3D = home.get_node("Guest bathroom toilet")
	var water: Node3D = house_toilet.get_node("Model/Water")
	var rest := water.position
	var events := []
	house_toilet.flush_started.connect(func(): events.append("start"))
	house_toilet.refill_started.connect(func(): events.append("refill"))
	house_toilet.flush_finished.connect(func(): events.append("done"))
	# Standing in front of the guest toilet: the camera ray over the bowl finds the lever.
	game.player.global_position = house_toilet.to_global(Vector3(0, .05, 1.4))
	check(await aim(game, house_toilet, Vector3(-.2, 1.5, 1.2), Vector3(0, .55, .75)) == house_toilet, "aiming at the bowl picks the toilet")
	check(await aim(game, house_toilet, Vector3(-.2, 1.5, 1.2), Vector3(-.31, .93, .25)) == house_toilet.get_node("Model/Flush"), "aiming at the lever picks the flush lever (word %s)" % house_toilet.get_node("Model/Flush").get_meta("word_key"))
	game.use_pressed()
	check(house_toilet.flushing and not game.player.seated, "E on the lever flushes")
	check(not house_toilet.get_node("Model/Flush").use(), "a second press during a flush is ignored")
	var flush_sounds := sounds(house_toilet, "toilet.flush")
	check(flush_sounds.size() == 1 and flush_sounds[0].playing and not flush_sounds[0].stream.loop_mode, "flush sound plays at the toilet (%d players)" % flush_sounds.size())
	if flush_sounds.size() == 1:
		check(absf(flush_sounds[0].stream.get_length() - 2.8) < .05 and flush_sounds[0].bus == "SFX", "flush sound is the 2.8 s cue on the SFX bus (%.2f s)" % flush_sounds[0].stream.get_length())
	# A click on the public toilet's push plate flushes too.
	game.player.global_position = toilet.to_global(Vector3(0, .05, 1.4))
	check(await aim(game, toilet, Vector3(0, 1.5, 1.2), Vector3(0, 1.05, .04)) == toilet.get_node("Model/Flush"), "aiming at the push plate picks it")
	game.interaction.click()
	check(toilet.flushing, "a click on the push plate flushes")
	await wait(.9)
	check(water.position.y < rest.y - .03, "bowl water drops while flushing")
	check(absf(house_toilet.get_node("Model/Flush/Lever").rotation.x) < .05, "lever back up after the press")
	await wait(2.3)
	check(not house_toilet.flushing and water.position.is_equal_approx(rest), "flush finishes and the water is back at rest")
	check(events == ["start", "refill", "done"], "flush signals in order (%s)" % [events])
	check(sounds(house_toilet, "toilet.flush").is_empty(), "flush sound player freed when it ends")
	# E near the toilet (aiming at the bowl) sits on it; E again stands up.
	game.player.global_position = house_toilet.to_global(Vector3(0, .05, 1.4))
	game.player.look_at(house_toilet.global_position, Vector3.UP)
	await aim(game, house_toilet, Vector3(-.2, 1.5, 1.2), Vector3(0, .55, .75))
	game.use_pressed()
	check(game.player.seated and game.seating.current.get("node") == house_toilet and not house_toilet.flushing, "E at the bowl sits on the toilet without flushing")
	await wait(1.0)
	var seat_local: Vector3 = house_toilet.to_local(game.player.global_position)
	check(absf(seat_local.x) < .1 and seat_local.z > .4 and seat_local.z < .7, "seated over the bowl (toilet-local %s)" % seat_local)
	var flush_node: Node3D = house_toilet.get_node("Model/Flush")
	await aim(game, house_toilet, Vector3(-.2, 1.5, 1.2), Vector3(-.31, .93, .25))
	game.interaction.click()
	# Seated, the seat claims E and a click does nothing (user, 12 Nov 2026).
	check(not house_toilet.flushing and game.player.seated, "seated, a click on the lever does nothing")
	game.use_pressed()
	await wait(1.0)
	check(not game.player.seated and fits(game, game.player.global_position), "E stands up again, clear of the toilet")
	await wait(2.5)
	# --- Faucet -----------------------------------------------------------------------------
	# The guest bathroom's basin went with the 13 Nov 2026 re-layout: the family vanity's faucet.
	var faucet: Node3D = home.find_child("Family vanity faucet", true, false)
	var stream: MeshInstance3D = faucet.get_node("Model/Stream")
	check(not stream.visible, "faucet starts off")
	faucet.use()
	await wait(.6)
	check(faucet.is_on and stream.visible and is_equal_approx(faucet.head, faucet.drop), "turned on: the stream reaches the basin")
	var runs := sounds(faucet, "faucet.run")
	check(runs.size() == 1 and runs[0].playing and runs[0].stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "running water loops at the faucet (%d players)" % runs.size())
	if runs.size() == 1:
		check(runs[0].global_position.is_equal_approx(faucet.global_position), "running water comes from the faucet")
	check(faucet.get_node("Model/Splash").visible, "splash shows where the water lands")
	await wait(1.5)
	check(faucet.is_on and stream.visible, "stays on until turned off")
	faucet.use()
	await wait(.8)
	check(not faucet.is_on and not stream.visible and absf(faucet.get_node("Model/Lever").rotation.x) < .01, "turned off: water clears, lever down")
	check(sounds(faucet, "faucet.run").is_empty(), "turned off: running water sound stops")
	# --- Airport restroom -------------------------------------------------------------------
	for title in ["Restroom door frame", "Restroom door", "Restroom icon", "Icon head"]:
		check(interior.get_node_or_null(title) == null, "old painted %s removed" % title)
	var collision: Node3D = interior.get_node("Carousel collision")
	var carousel_z: float = (terminal.global_transform.affine_inverse() * collision.global_transform).origin.z
	check(absf(carousel_z - (-5.4)) < .05, "carousel collision moved with the carousel (z %.2f)" % carousel_z)
	var board: Node3D = interior.get_node("Restroom sign")
	check(str(board.get_meta("word_key", "")) == "bathroom", "RESTROOMS board teaches bathroom")
	var doors := []
	for title in ["Women's restroom door", "Men's restroom door"]:
		var door: Node3D = interior.get_node(title)
		check(game.doors.has(door), "%s registered" % title)
		doors.append(door)
	var at := func(x: float, z: float) -> Vector3: return terminal.to_global(Vector3(x, .1, z))
	check(not fits(game, at.call(11.92, -1.9)), "closed women's door blocks its doorway")
	for door in doors: game.doors[door]["open"] = true
	await wait(1.0)
	for spot in [["claim walkway", 12.5, -3.05], ["claim front walkway", 11.0, -7.75], ["women's doorway", 11.92, -1.9],
			["men's doorway", 15.93, -1.9], ["inside women's room", 12.2, -1.0], ["inside men's room", 15.55, -1.0]]:
		check(fits(game, at.call(spot[1], spot[2])), "player fits: %s" % spot[0])
	print("BATH FIXTURES: %d checks, %d failed" % [checks, failures])
	quit(1 if failures > 0 else 0)
