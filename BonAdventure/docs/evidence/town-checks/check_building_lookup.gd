extends SceneTree
## Building address book (scripts/world/modular_town.gd building(), 6 Nov 2026) and focus mode.
## Run with any dev focus (VT_FOCUS=all, or e.g. VT_FOCUS=chapel), isolated HOME (README):
## every part of every loaded unit resolves and every absent unit gives null; then the player
## stands on every site in reference_layout.site_bounds while current_room(), location_name(),
## the minimap and the journal run. Writes no files. Script errors show in the log.
## The minimap part runs only while Features.MINIMAP is on (hidden since 14 Nov 2026).
const ModularTown := preload("res://scripts/world/modular_town.gd")
const Features := preload("res://scripts/core/features.gd")
var failures := 0
var checks := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var town: Node3D = game.apartment
	var loaded: Array = town.get_meta("loaded_units", [])
	var units: Dictionary = ModularTown.registry()
	print("loaded units: ", loaded.size(), " of ", units.size(), " ", loaded)
	for key in units:
		for i in units[key].parts.size():
			var node := ModularTown.building(town, key, i)
			if loaded.has(key):
				check(node != null, "loaded part %s %d" % [key, i])
			else:
				check(node == null, "absent unit gives null %s %d" % [key, i])
	check(ModularTown.building(town, "home", 0, "Garage door") == game.garage_door(), "garage door via lookup")
	var layout = game.reference_layout
	var minimap = game.hud.ui_root.get_node_or_null("TownMinimap")
	if not Features.MINIMAP and not Features.FULL_MAP:
		check(minimap == null, "no minimap or map while both features are off")
	for key in layout.site_bounds:
		var bounds: AABB = layout.site_bounds[key]
		var point: Vector3 = bounds.get_center()
		point.y = bounds.position.y + .5
		game.player.global_position = town.to_global(point)
		game.player.set_meta("map_position", game.player.global_position)
		var room: String = game.current_room()
		var name: String = layout.location_name(point, layout.site_at(point))
		check(room != "" and name != "", "names at site " + key)
		print("site ", key, ": room '", room, "', location '", name, "'")
	if Features.MINIMAP:
		if minimap != null and minimap.has_method("rebuild"):
			minimap.rebuild()
		else:
			check(false, "minimap found")
	game.spawn_position()
	game.spawn_yaw()
	game.toggle_study_journal()
	await process_frame
	game.toggle_study_journal()
	await process_frame
	print("BUILDING LOOKUP: ", checks, " checks, ", failures, " failures")
	quit(1 if failures > 0 else 0)
