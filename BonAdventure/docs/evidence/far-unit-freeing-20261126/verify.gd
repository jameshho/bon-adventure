extends SceneTree
## Far-unit freeing (26 Nov 2026, user: "free far buildings to fix the memory"; option B of
## docs/guides/performance/README.md "Load only nearby buildings on phones"), natively with the
## web path forced (VT_NEARBY=1):
## - nearby_units.gd frees a loaded unit once the player is far from it (Main.remove_unit()):
##   its parts, its batches (StaticRenderBatches/Unit_<key>) and its minigame sessions go, it is
##   pending again and its site has an empty stand-in pivot;
## - walking back adds it again with its sessions, doors, seats and words;
## - every unit can be freed and added again (each, then all) with the town still running;
## - pins: no unit goes while a minigame runs or while the player drives one of its vehicles;
## - video memory after freeing far units is lower than with them, and back near the start after
##   a full cycle (printed; the GPU numbers are the renderer's own counters).
## Look in the log for "SCRIPT ERROR" / "previously freed" too: stale references print there.
## Headless; writes no saves with an isolated HOME:
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none VT_NEARBY=1 godot --headless --path . --script res://docs/evidence/far-unit-freeing-20261126/verify.gd
const NearbyUnits := preload("res://scripts/world/nearby_units.gd")
const ModularTown := preload("res://scripts/world/modular_town.gd")

var main: Node
var failures := 0
var checks := 0
var removed: Array = []

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

func video_mb() -> float:
	return RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / 1048576.0

func loaded() -> Array:
	return main.apartment.get_meta("loaded_units", [])

## Nodes under Main made for unit `key` (its minigame sessions).
func sessions_of(key: String) -> Array:
	return (main._unit_nodes.get(key, []) as Array).filter(func(node) -> bool: return is_instance_valid(node))

func wait_until(condition: Callable, limit: int) -> int:
	var waited := 0
	while not condition.call() and waited < limit:
		await process_frame
		waited += 1
	return waited

func run() -> void:
	check(NearbyUnits.enabled(), "VT_NEARBY=1 turns nearby loading on")
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	var apartment: Node3D = main.get_node("Apartment")
	var first: Array = NearbyUnits.initial_for(centre("home"), apartment.transform.basis.get_scale().x, ["home"])
	main.staged_loading = true
	main.initial_units = first
	get_root().add_child(main)
	await main.town_ready
	main.unit_removed.connect(func(key: String) -> void: removed.append(key))
	await frames(10)
	stand_at("home")
	print("  start units: ", loaded(), "  video %.0f MB" % video_mb())
	check(main.apartment.has_node("StaticRenderBatches/Unit_home"), "per-unit batches: the home has its own Unit_home")
	check(sessions_of("home").size() > 0, "the home's sessions are known (%d)" % sessions_of("home").size())
	var home_doors: int = main.doors.keys().filter(func(door) -> bool: return is_instance_valid(door) and ModularTown.unit_parts(main.apartment, "home").any(func(p) -> bool: return p.is_ancestor_of(door))).size()
	check(home_doors > 0, "the home's doors are registered (%d)" % home_doors)
	var nearby := NearbyUnits.new()
	nearby.setup(main)
	main.add_child(nearby)

	# Walk to the sports store (273 m from the home): it arrives, the home and its neighbours go.
	var start_mb := video_mb()
	await wait_until(func() -> bool:
		stand_at("sports")
		return loaded().has("sports") and not loaded().has("home"), 3000)
	await frames(120)
	print("  at the sports store: ", loaded(), "  removed ", removed, "  video %.0f MB" % video_mb())
	check(loaded().has("sports"), "standing at the sports store adds it")
	check(not loaded().has("home") and main.pending_units.has("home"), "the home is freed and pending again")
	check(main.apartment.get_node_or_null("RelocatedSites/Home") != null and main.apartment.get_node("RelocatedSites/Home").has_meta("unit_placeholder"), "the home's site has an empty stand-in pivot")
	check(not main.apartment.has_node("StaticRenderBatches/Unit_home"), "the home's batches are gone")
	check(sessions_of("home").is_empty() and main._unit_jobs.has("home"), "the home's sessions are freed and wait for it")
	check(main.doors.keys().all(func(door) -> bool: return is_instance_valid(door)), "no freed door left in Main.doors")
	check(main.seating.seats.all(func(seat) -> bool: return is_instance_valid(seat.node)), "no freed seat left")
	check(main.driveable_vehicles.all(func(v) -> bool: return is_instance_valid(v)), "no freed vehicle left")

	# Back home: it returns with its sessions, doors and seats.
	await wait_until(func() -> bool:
		stand_at("home")
		return loaded().has("home"), 3000)
	await frames(180)
	print("  back home: ", loaded(), "  video %.0f MB" % video_mb())
	check(loaded().has("home"), "walking back adds the home again")
	check(sessions_of("home").size() > 0, "the home's sessions are made again (%d)" % sessions_of("home").size())
	check(main.apartment.has_node("StaticRenderBatches/Unit_home"), "the home is batched again")
	var doors_again: int = main.doors.keys().filter(func(door) -> bool: return is_instance_valid(door) and ModularTown.unit_parts(main.apartment, "home").any(func(p) -> bool: return p.is_ancestor_of(door))).size()
	check(doors_again == home_doors, "the home's doors are registered again (%d of %d)" % [doors_again, home_doors])
	# Freed farthest first (furniture 284 m, then sports 273 m), one per tick after the arrivals.
	var waited := await wait_until(func() -> bool:
		stand_at("home")
		return not loaded().has("sports"), 3000)
	check(not loaded().has("sports"), "the sports store went again when far (%d frames)" % waited)
	nearby.set_process(false)

	# Every unit: added, freed, added again, with frames in between (stale references error).
	var all: Array = ModularTown.focused_units()
	for key in all:
		await main.ensure_unit(key)
	await frames(30)
	var full_mb := video_mb()
	print("  every unit loaded: video %.0f MB" % full_mb)
	for key in all:
		check(main.remove_unit(key), "remove_unit(%s)" % key)
		await frames(5)
	await frames(30)
	var empty_mb := video_mb()
	print("  every unit freed: video %.0f MB" % empty_mb)
	check(loaded().is_empty() and main.pending_units.size() == all.size(), "every unit is pending")
	check(empty_mb < full_mb - 50.0, "freeing every unit gives back video memory (%.0f -> %.0f MB)" % [full_mb, empty_mb])
	for key in all:
		await main.ensure_unit(key)
		await frames(3)
	await frames(30)
	print("  every unit again: video %.0f MB" % video_mb())
	check(loaded().size() == all.size(), "every unit added again")
	check(video_mb() < full_mb + 30.0, "a full cycle does not pile up video memory (%.0f vs %.0f MB)" % [video_mb(), full_mb])

	# Pins.
	var car: Node = main.driveable_vehicles.filter(func(v) -> bool: return ModularTown.unit_parts(main.apartment, "home").any(func(p) -> bool: return p.is_ancestor_of(v))).front() if not main.driveable_vehicles.is_empty() else null
	if car != null:
		main.active_vehicle = car
		check(main.unit_pin("home", 0.0) == "vehicle" and not main.remove_unit("home"), "the unit of the driven vehicle stays")
		main.active_vehicle = null
	main.hud.in_minigame = true
	check(main.unit_pin("airport", 0.0) == "game" and not main.remove_unit("airport"), "no unit goes while a minigame runs")
	main.hud.in_minigame = false
	print("  start %.0f MB, all %.0f, none %.0f" % [start_mb, full_mb, empty_mb])
	print("far unit freeing verify: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
