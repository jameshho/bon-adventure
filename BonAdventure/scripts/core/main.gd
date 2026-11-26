extends Node3D

# Vocabulary Town v0.19. Walkable two-street neighborhood with detailed interiors and static citizens.
const HUD_SCENE = preload("res://scenes/ui/vocabulary_hud.tscn")
const InteractionController = preload("res://scripts/player/interaction_controller.gd")
const VocabularyProgress = preload("res://scripts/learning/vocabulary_progress.gd")
const APARTMENT_SCALE := 1.30
var reference_layout

# Shared resources reduce allocations and GPU state changes across repeated furniture.
var materials_by_color: Dictionary = {}
var box_meshes: Dictionary = {}

var apartment: Node3D
var player
var camera: Camera3D
var hud
var interaction: InteractionController
var money_panel
var family_panel
## Captain Bruno's airport flight game screen; the flight board and schedule booklet are
## interactables that open it for browsing (flight_session.gd).
var flight_panel
var flight_session
## Twinkle's Alta Cocina restaurant game: the order tablet and the menu book (restaurant_session.gd).
var restaurant_panel
var restaurant_menu_book
var warehouse_card
## The police detective games' card (lineup and evidence; police_detective_session.gd).
var detective_card
## The Warehouse Worker game; it claims E and the click while carrying (warehouse_session.gd).
var warehouse_session
## Lana's Grammar Classroom card (grammar_session.gd; docs/guides/GRAMMAR_CLASS.md).
var grammar_card
## The Mystery Doors card (Mystery House; minigame_wiring.gd).
var mystery_card
## Mei's mahjong screen in front of the home (mahjong_session.gd; docs/guides/MAHJONG.md).
var mahjong_panel
## Mei's mahjong lessons (scripts/ui/mahjong_lesson_panel.gd; docs/guides/MAHJONG.md#lessons).
var mahjong_lessons
## Radar Patrol's arcade screen (control-tower radars; docs/guides/RADAR_PATROL.md).
var radar_panel
## The electrical box close-up and its session (scripts/learning/electrical_box_session.gd;
## docs/guides/ELECTRICAL_BOX.md). Each box is an interactable (electrical_box.gd).
var electrical_box_panel
var electrical_box_session
## The elevator floor picker: E at a cabin panel (scripts/ui/elevator_floor_picker.gd).
var elevator_floor_picker
## The record player panel: E at a record player (scripts/ui/record_player_panel.gd).
var record_player_panel
## The minigame picker, F9 or the ▶ corner button (scripts/ui/game_launcher.gd).
var game_launcher
## The Passport: missions, town stamps, the achievement log (scripts/ui/passport_panel.gd).
var passport
## The stars card after a session of a game with levels (scripts/ui/star_card.gd).
var star_card
## The results screen after a minigame (scripts/ui/results_screen.gd, 21 Nov 2026) and what
## decides when it shows for every game (scripts/learning/results_flow.gd).
var results_screen
var results_flow
## Wayfinding (18 Nov 2026): the guide arrow (scripts/ui/guide_arrow.gd) and the town map
## (scripts/ui/town_map_panel.gd, in hud.map_overlay; null while Features.FULL_MAP is off).
var guide
var town_map
var shop_panel
## What sync_player_controls() last saw of talk_locked() (_process() re-syncs on a change).
var player_talk_locked := false
var settings_panel
## Open popups in opening order; Esc closes the top one (scripts/ui/popup_stack.gd).
var popups
## The Inspect button and close-up of the item in the player's hand (scripts/ui/hold_inspect_ui.gd).
var hold_ui
var poster_ui
## The town blinker (scripts/characters/plush_life.gd): every plush in group "figures".
var plush_life
## Blinker for the rigged clay zoo animals (group clay_animator.gd BLINK_GROUP).
var clay_life
## Sun, sky, ambient, lamp glow and the time of day (scripts/world/day_night.gd); its HUD clock.
var day_night
var day_clock
const GameSettings := preload("res://scripts/core/game_settings.gd")
const Sound := preload("res://scripts/core/sound.gd")
## Interface text in the native language (data/phrases.json; UI Stage 3).
const UiText := preload("res://scripts/language/ui_text.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
const ModularTown := preload("res://scripts/world/modular_town.gd")
## Helpers moved out of Main (7 Nov 2026); Main keeps the public methods and fields.
const MinigameWiring := preload("res://scripts/core/minigame_wiring.gd")
const NpcRegistry := preload("res://scripts/characters/npc_registry.gd")
const Board := preload("res://scripts/learning/activity_board.gd")
const VehicleControls := preload("res://scripts/core/vehicle_controls.gd")
const DoorAnimator := preload("res://scripts/core/door_animator.gd")
const PlushLife := preload("res://scripts/characters/plush_life.gd")
const ClayAnimator := preload("res://scripts/characters/clay_animator.gd")
const RoomNames := preload("res://scripts/world/room_names.gd")
## The saved place (save and respawn, 14 Nov 2026) and the node that keeps saving it.
const PlayerPlace := preload("res://scripts/core/player_place.gd")
var place_keeper: Node
## Switched-off features (minimap, full map, hyper speed; README.md#hidden-features).
const Features := preload("res://scripts/core/features.gd")
## The foreign language whose progress studied_words holds (saved per language).
var progress_language := ""
## "native/foreign" when the settings last changed; a change ends running activities.
var ui_languages := ""
var hud_status_timer := 0.0
var vocabulary: Dictionary = {}
var vocabulary_categories: Dictionary = {}
var vocabulary_aliases: Dictionary = {}
var vocabulary_sold_in: Dictionary = {}
## Words whose town object makes no good picture (words.json "picture": false).
var vocabulary_no_picture: Dictionary = {}
var doors: Dictionary = {}
var studied_words: Dictionary = {}
var room_name := ""
var active_vehicle: DriveableVehicle
var driveable_vehicles: Array[DriveableVehicle] = []
var zoo_gate: ZooGate
var farm_gate: ZooGate
var zones: Node3D
var seating
var area_vocabulary
## Idle lines of NPCs without an activity (npc_chatter.gd, 23 Nov 2026).
var npc_chatter
## Journal and results-screen word pictures (word_pictures.gd, 23 Nov 2026).
var word_pictures

## The app scene (scripts/app/app.gd, PWA phase 3) sets staged_loading before adding Main:
## the town then builds over many frames and reports loading_progress, so the loading screen
## can draw. Checks and tools leave it off and get the whole town before _ready returns, as
## before. town_ready is emitted when everything is built, in both cases.
var staged_loading := false
signal loading_progress(fraction: float)
signal town_ready
## Staged loading, home first (13 Nov 2026, user): when the app sets initial_units, only those
## building units load before town_ready; the others stay in pending_units until the app adds
## them one at a time with add_unit() (each a short freeze; see app.gd). Empty: every unit.
var initial_units: Array = []
var pending_units: Array = []
## unit key -> Callables waiting for it (when_unit_loaded(), e.g. a minigame's session).
var _unit_jobs: Dictionary = {}
var _adding_unit := false
var render_culling
var indoor_visibility
var minimaps: Array = []
signal unit_added(key: String)
## Loading steps besides the building units (the awaits in _ready), weighted by how long the
## work before each takes, in building units (17 Nov 2026, first launch, native: a unit about
## 0.6 s; the rest of the world 0.55 s, the player 0.8 s, the HUD 1.0 s, shops 0.25 s, the
## rest 0.35 s), so the bar moves with the real work.
const LOADING_STEP_WEIGHTS := {"world": 0.9, "player": 1.3, "ui": 1.7, "shops": 0.4, "rest": 0.6}
var _loading_done := 0.0
var _loading_total := 1.0

## One step of the staged loading: report progress and wait a frame (nothing when not staged).
## `step`: a LOADING_STEP_WEIGHTS key; none = one building unit.
func _loading_step(step := "") -> void:
	if not staged_loading:
		return
	_loading_done += float(LOADING_STEP_WEIGHTS.get(step, 1.0))
	loading_progress.emit(minf(float(_loading_done) / _loading_total, 1.0))
	await get_tree().process_frame

func _init() -> void:
	# Chinese fallback font (also here: checks run main.tscn without app.tscn).
	preload("res://scripts/ui/cjk_font.gd").install()

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# While the town builds over several frames, nothing in it runs (the player would fall,
	# Main's _process would find no HUD). Restored before town_ready.
	if staged_loading:
		process_mode = Node.PROCESS_MODE_DISABLED
	# tools/bake_unit.gd bakes with Main: no save is ever written then (save_store.gd).
	preload("res://scripts/core/save_store.gd").read_only = get_meta("bake_world_only", false)
	# Before anything reads user://: carry saves over from an earlier project name, then use the
	# chosen profile (app flow), else the last used one, else the flat user:// saves.
	preload("res://scripts/core/save_migration.gd").run()
	preload("res://scripts/core/profile_manager.gd").shared().use_default()
	# The saved languages reach the Lexicon before anything builds text.
	GameSettings.shared().apply()
	load_words()
	progress_language = Lexicon.shared().foreign
	ui_languages = Lexicon.shared().native + "/" + progress_language
	studied_words = VocabularyProgress.load_studied_words(vocabulary, vocabulary_aliases, progress_language)
	_loading_total = (initial_units.size() if not initial_units.is_empty() else ModularTown.focused_units().size()) + LOADING_STEP_WEIGHTS.values().reduce(func(a, b): return a + b, 0.0)
	await build_world()
	# tools/bake_unit.gd: stop with the finished world, before player, UI and sessions.
	if get_meta("bake_world_only", false):
		return
	await _loading_step("world")
	make_player()
	await _loading_step("player")
	register_driveable_vehicles()
	make_ui()
	await _loading_step("ui")
	zones = preload("res://scripts/world/town_zones.gd").new()
	apartment.add_child(zones)
	zones.setup(apartment, player)
	zones.overlay_changed.connect(func(enabled: bool) -> void: hud.set_help_state("zones", enabled))
	interaction = InteractionController.new()
	interaction.name = "InteractionController"
	interaction.setup(camera, player, apartment, hud, vocabulary, vocabulary_categories, vocabulary_aliases)
	interaction.word_studied.connect(_on_word_studied)
	add_child(interaction)
	make_shops()
	npc_chatter = preload("res://scripts/characters/npc_chatter.gd").new()
	add_child(npc_chatter)
	npc_chatter.setup(self)
	npc_chatter.attach_all(self)
	make_popups()
	await _loading_step("shops")
	area_vocabulary = preload("res://scripts/learning/area_vocabulary.gd").new()
	area_vocabulary.build(apartment, zones, vocabulary, vocabulary_aliases)
	word_pictures = preload("res://scripts/ui/word_pictures.gd").new()
	word_pictures.name = "WordPictures"
	add_child(word_pictures)
	word_pictures.setup(area_vocabulary.targets, vocabulary_categories, vocabulary_no_picture)
	seating = preload("res://scripts/player/seating_controller.gd").new()
	add_child(seating)
	seating.setup(self)
	# Interaction system (12 Nov 2026): doors, gates, vehicles are interactables; the vehicle
	# being driven and the seat claim E. Interactables are not words: the area index drops them.
	DoorAnimator.make_interactables(self)
	VehicleControls.make_interactables(self)
	interaction.claim("vehicle", func() -> bool: return is_instance_valid(active_vehicle) and player.controls_enabled, toggle_vehicle)
	interaction.claim("seat", func() -> bool: return player.seated and player.controls_enabled, seating.stand)
	# Held items (player.hand) and their Inspect button (docs/guides/HAND_HOLD.md, 13 Nov 2026).
	hold_ui = preload("res://scripts/ui/hold_inspect_ui.gd").new()
	hold_ui.setup(self)
	# A click on a word of a poster opens the poster close-up (user, 24 Nov 2026).
	poster_ui = preload("res://scripts/ui/poster_inspect_ui.gd").new()
	poster_ui.setup(self)
	# Every plush NPC blinks now and then (plush_life.gd, docs/guides/COMPONENTS.md#plush-characters).
	plush_life = PlushLife.new()
	plush_life.blink_gap = PlushLife.TOWN_BLINK_GAP
	add_child(plush_life)
	plush_life.follow_group("figures")
	# Rigged clay zoo animals blink too (clay_animator.gd puts them in its BLINK_GROUP).
	clay_life = PlushLife.new()
	clay_life.blink_gap = PlushLife.TOWN_BLINK_GAP
	add_child(clay_life)
	clay_life.follow_group(ClayAnimator.BLINK_GROUP)
	clay_life.name = "ClayLife"
	area_vocabulary.drop_interactables(apartment)
	# Sounds (scripts/core/sound.gd, data/sounds.json): binds the fixtures already built. App adds
	# the service earlier (loading music) and plays the town music itself.
	if Sound.shared() == null:
		add_child(Sound.new())
		Sound.shared().play_town()
	# Lamp glow materials go on before the batchers below; the HUD clock opens the time panel.
	day_night.bind_town(apartment, player)
	day_clock = preload("res://scripts/ui/day_clock.gd").new()
	day_clock.add_to_group(hud.GAME_HIDDEN_GROUP)
	hud.ui_root.add_child(day_clock)
	day_clock.setup(day_night, hud)
	popups.watch(day_clock.panel, day_clock.close)
	# Joystick, E and jump buttons, drag-look and pinch-zoom on touch screens (PWA phase 5).
	var touch_controls = preload("res://scripts/ui/touch_controls.gd").new()
	hud.ui_root.add_child(touch_controls)
	touch_controls.setup(self)
	update_progress_display()
	apply_world_language()
	if not get_meta("editing_snapshot", false):
		await _loading_step("rest")
		preload("res://scripts/world/garden_rendering.gd").new().build(apartment)
		# The render trim's building-shell rays need the town's collision in the physics space.
		await get_tree().physics_frame
		render_culling = preload("res://scripts/world/render_culling.gd").new()
		render_culling.build(self)
		# Inside a building only it, its yard and the street outside are drawn (14 Nov 2026).
		indoor_visibility = preload("res://scripts/world/indoor_visibility.gd").new()
		add_child(indoor_visibility)
		indoor_visibility.setup(self)
	await _restore_place()
	process_mode = Node.PROCESS_MODE_INHERIT
	town_ready.emit()

func load_words() -> void:
	# data/words.json is the only word source; see scripts/learning/word_data.gd.
	var words: Dictionary = preload("res://scripts/learning/word_data.gd").load_all()
	vocabulary = words.vocabulary
	vocabulary_categories = words.categories
	vocabulary_aliases = words.aliases
	vocabulary_sold_in = words.sold_in
	vocabulary_no_picture = words.no_picture


func current_room() -> String:
	return RoomNames.room_at(self)

func update_progress_display() -> void:
	if is_instance_valid(hud):
		hud.set_progress(current_room(), studied_words.size())

func material_for(color: Color) -> StandardMaterial3D:
	var key: String = color.to_html(true)
	if not materials_by_color.has(key):
		var result := StandardMaterial3D.new()
		result.albedo_color = color
		result.roughness = 0.82
		materials_by_color[key] = result
	return materials_by_color[key]

func shared_box_mesh(size: Vector3) -> BoxMesh:
	var key: String = str(size.x) + ":" + str(size.y) + ":" + str(size.z)
	if not box_meshes.has(key):
		var result := BoxMesh.new()
		result.size = size
		box_meshes[key] = result
	return box_meshes[key]

func box(name: String, pos: Vector3, size: Vector3, color: Color, word := "", solid := true) -> Node3D:
	var root := Node3D.new()
	root.name = name
	root.position = pos
	if word != "":
		root.set_meta("word_key", word)
	apartment.add_child(root, true)
	var mesh := MeshInstance3D.new()
	mesh.mesh = shared_box_mesh(size)
	mesh.material_override = material_for(color)
	root.add_child(mesh)
	if solid or word != "":
		var body: CollisionObject3D = StaticBody3D.new() if solid else Area3D.new()
		root.add_child(body)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		body.set_meta("object_name", name)
		body.set_meta("root", root)
		if word != "":
			body.set_meta("word", word)
	return root


# Simple procedural shapes, so the project needs no downloaded art assets.
func cylinder(name: String, pos: Vector3, radius: float, height: float, color: Color, word := "", solid := false) -> Node3D:
	var root := Node3D.new()
	root.name = name
	root.position = pos
	if word != "":
		root.set_meta("word_key", word)
	apartment.add_child(root, true)
	var mesh := MeshInstance3D.new()
	var shape_mesh := CylinderMesh.new()
	shape_mesh.top_radius = radius
	shape_mesh.bottom_radius = radius
	shape_mesh.height = height
	mesh.mesh = shape_mesh
	mesh.material_override = material_for(color)
	root.add_child(mesh)
	if solid or word != "":
		var body: CollisionObject3D = StaticBody3D.new() if solid else Area3D.new()
		root.add_child(body)
		var collision := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = radius
		shape.height = height
		collision.shape = shape
		body.add_child(collision)
		body.set_meta("root", root)
		body.set_meta("word", word)
	return root

func sphere(name: String, pos: Vector3, radius: float, color: Color, word := "", solid := false) -> Node3D:
	var root := Node3D.new()
	root.name = name
	root.position = pos
	if word != "":
		root.set_meta("word_key", word)
	apartment.add_child(root, true)
	var mesh := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2.0
	mesh.mesh = sphere_mesh
	mesh.material_override = material_for(color)
	root.add_child(mesh)
	if solid or word != "":
		var body: CollisionObject3D = StaticBody3D.new() if solid else Area3D.new()
		root.add_child(body)
		var collision := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = radius
		collision.shape = shape
		body.add_child(collision)
		body.set_meta("root", root)
		body.set_meta("word", word)
	return root


func build_world() -> void:
	# The modular town (docs/guides/MODULAR_TOWN.md): Main's Apartment is the saved base world
	# (scenes/town/base.scn); the building units in data/buildings.json are added to it.
	# The old startup passes that once built the town were deleted on 6 Nov 2026.
	apartment = get_node("Apartment") as Node3D
	var loaded: Array = await ModularTown.load_units(apartment, _loading_step if staged_loading else Callable(), initial_units)
	pending_units = ModularTown.focused_units().filter(func(key) -> bool: return not loaded.has(key))
	restore_editor_door_states(apartment)
	reference_layout = preload("res://scripts/world/reference_world_layout.gd").new()
	reference_layout.restore(self)
	# Every NPC at its spot in the registry (data/npcs.json, docs/guides/NPCS.md); the registry's own
	# NPCs (the barn farmer) are made here, but never baked into a unit scene.
	NpcRegistry.place(apartment)
	if not get_meta("bake_world_only", false):
		NpcRegistry.spawn(apartment)
	apartment.set_meta("translated_signs", preload("res://scripts/world/sign_language.gd").translate_all(apartment))

	# The sun ("Soft daylight"), sky, fog and ambient fill, blended through the day by
	# scripts/world/day_night.gd from data/day_night.json (9 Nov 2026).
	day_night = preload("res://scripts/world/day_night.gd").new()
	day_night.name = "DayNight"
	add_child(day_night)
	day_night.setup(self)


func restore_editor_door_states(node: Node) -> void:
	DoorAnimator.restore_editor_door_states(self, node)


## Where the player starts and respawns: on the entrance walk just outside the supermarket
## door (market-local frame, door at x -33, z 34.25), facing it. Falls back to the layout's
## spawn point when the supermarket site is missing.
const SPAWN_MARKET_LOCAL := Vector3(-33.0, 0.1, 27.5)
const SPAWN_MARKET_DOOR := Vector3(-33.0, 0.1, 34.25)

## Building entrances, shared by the development spawn (dev_focus.txt `spawn=<name>`, see
## scripts/core/dev_focus.gd) and the respawn outside the building a saved game was left in
## (scripts/core/player_place.gd, 14 Nov 2026): building unit, part index and path below it
## (ModularTown.building()), standing point outside the door and the door point it faces, in that
## node's frame. Every unit has at least one; a unit with several buildings (restaurants, airport)
## lists each, and the respawn takes the one whose door is nearest the saved spot.
const ENTRANCES := {
	"police": ["police", 0, "", Vector3(43.0, 0.1, 33.5), Vector3(43.0, 0.1, 37.5)],
	"restaurant": ["restaurants", 0, "Pizza", Vector3(0.0, 0.1, -11.5), Vector3(0.0, 0.1, -8.0)],
	"mystery": ["mystery", 0, "", Vector3(0.0, 0.1, -20.0), Vector3(0.0, 0.1, -15.0)],
	# Every other building (added 10 Nov 2026): standing point ~4.5 m outside the door, in the site
	# node's frame; outward is -Z there except at the home (+Z) and the airport/barn/warehouse nodes.
	"restaurants": ["restaurants", 0, "Pizza", Vector3(0.0, 0.1, -11.5), Vector3(0.0, 0.1, -8.0)],
	"burger": ["restaurants", 0, "", Vector3(44.0, 0.1, -12.5), Vector3(44.0, 0.1, -8.0)],
	"pizza": ["restaurants", 0, "", Vector3(44.0, 0.1, -12.5), Vector3(44.0, 0.1, -8.0)],
	"taqueria": ["restaurants", 0, "", Vector3(16.0, 0.1, -12.5), Vector3(16.0, 0.1, -8.0)],
	"home": ["home", 0, "", Vector3(1.0, 0.1, 22.0), Vector3(1.0, 0.1, 17.0)],
	"supermarket": ["supermarket", 0, "", SPAWN_MARKET_LOCAL, SPAWN_MARKET_DOOR],
	"library": ["library", 0, "", Vector3(-15.0, 0.1, 33.5), Vector3(-15.0, 0.1, 37.5)],
	"bank": ["bank", 0, "", Vector3(25.0, 0.1, 33.5), Vector3(25.0, 0.1, 37.5)],
	"airport": ["airport", 0, "", Vector3(0.0, 0.1, -21.0), Vector3(0.0, 0.1, -9.0)],
	"barn": ["barn", 0, "", Vector3(0.0, 0.1, -13.0), Vector3(0.0, 0.1, -4.7)],
	"warehouse": ["warehouse", 0, "", Vector3(-12.2, 0.1, -4.5), Vector3(-12.2, 0.1, 0.2)],
	"sports": ["sports", 0, "", Vector3(26.0, 0.1, 99.5), Vector3(26.0, 0.1, 104.0)],
	"clothing": ["clothing", 0, "", Vector3(50.5, 0.1, 99.5), Vector3(50.5, 0.1, 104.0)],
	"electronics": ["electronics", 0, "", Vector3(-59.5, 0.1, 32.5), Vector3(-59.5, 0.1, 37.0)],
	"furniture": ["furniture", 0, "", Vector3(-52.0, 0.1, 99.0), Vector3(-52.0, 0.1, 103.5)],
	"bakery": ["bakery", 0, "", Vector3(-61.0, 0.1, 60.0), Vector3(-61.0, 0.1, 64.7)],
	"hospital": ["hospital", 0, "", Vector3(-32.0, 0.1, 99.5), Vector3(-32.0, 0.1, 104.0)],
	"school": ["school", 0, "", Vector3(-4.0, 0.1, 99.0), Vector3(-4.0, 0.1, 103.9)],
	"chapel": ["chapel", 0, "", Vector3(46.5, 0.1, 63.5), Vector3(46.5, 0.1, 68.5)],
	"playground": ["playground", 0, "", Vector3(15.2, 0.1, 62.5), Vector3(15.2, 0.1, 67.7)],
	# The control tower's ground-floor door (south face of Airport/ControlTower, header at
	# world x -96.3; 14 Nov 2026), in the Airport node's frame.
	"tower": ["airport", 0, "", Vector3(21.95, 0.1, -3.7), Vector3(21.95, 0.1, -0.2)],
}

func dev_spawn_site() -> Array:
	var entry: Array = ENTRANCES.get(preload("res://scripts/core/dev_focus.gd").dev_spawn(), [])
	if entry.is_empty(): return []
	var site := ModularTown.building(apartment, entry[0], entry[1], entry[2])
	return [] if site == null else [site.to_global(entry[3]), site.to_global(entry[4])]

func spawn_position() -> Vector3:
	var dev := dev_spawn_site()
	if not dev.is_empty():
		return dev[0]
	var market := ModularTown.building(apartment, "supermarket")
	if market != null:
		return market.to_global(SPAWN_MARKET_LOCAL)
	return apartment.to_global(reference_layout.spawn_point if reference_layout != null else Vector3(4.5,.1,23))

func spawn_yaw() -> float:
	var dev := dev_spawn_site()
	if not dev.is_empty():
		var facing: Vector3 = dev[1] - dev[0]
		return atan2(-facing.x, -facing.z)
	var market := ModularTown.building(apartment, "supermarket")
	if market != null:
		var toward := market.to_global(SPAWN_MARKET_DOOR) - market.to_global(SPAWN_MARKET_LOCAL)
		return atan2(-toward.x, -toward.z)
	return PI if apartment.get_meta("reference_west_positive_x",false) else 0.0

## A profile's saved game goes on where it was left (scripts/core/player_place.gd, 14 Nov 2026):
## outside the building it was in, else the nearest safe spot near the saved one, else the spawn
## above. Not for a dev `spawn=`, a profile still to play the welcome tutorial, or without a
## profile (checks, tools). The physics frames let every collider in the town reach the space
## before the queries. Then place_keeper saves the place while the town runs.
func _restore_place() -> void:
	if not PlayerPlace.enabled() or get_meta("editing_snapshot", false):
		return
	var profile: Dictionary = preload("res://scripts/core/profile_manager.gd").shared().active_profile()
	var place := PlayerPlace.read()
	if not place.is_empty() and dev_spawn_site().is_empty() and bool(profile.get("tutorial", {}).get("done", false)):
		await get_tree().physics_frame
		await get_tree().physics_frame
		var spot := PlayerPlace.spawn_for(self, place)
		if not spot.is_empty():
			player.global_position = spot.position
			player.velocity = Vector3.ZERO
			player.camera_yaw = spot.yaw
			player.rotation.y = spot.yaw
			player.reset_camera()
	place_keeper = preload("res://scripts/core/player_place_keeper.gd").new()
	add_child(place_keeper)
	place_keeper.setup(self)

func make_player() -> void:
	player = $BonBonPlayer
	# The profile's avatar (profile_manager.gd) replaces BonBon's model; BonBon by default.
	var avatar := str(preload("res://scripts/core/profile_manager.gd").shared().active_profile().get("avatar", "bonbon"))
	var avatar_scene := preload("res://scripts/characters/house_characters.gd").scene_of(avatar)
	if avatar != "bonbon" and avatar_scene != "":
		player.set_avatar(load(avatar_scene))
	if reference_layout != null:
		player.global_position=spawn_position()
		player.camera_yaw=spawn_yaw()
		player.rotation.y=spawn_yaw()
	player.reset_camera()
	# The follow camera (Settings "Camera follows me"), slower indoors (day_night.gd `indoor`).
	player.follow_camera = GameSettings.shared().follow_camera
	player.follow_indoor = func() -> float: return day_night.indoor if day_night != null else 0.0
	# The outfit kept in a fitting room (fitting_booth.gd) is put back on.
	if GameSettings.shared().outfit != "":
		preload("res://scripts/characters/plush_costume.gd").dress_player(player, GameSettings.shared().outfit)
	camera = player.camera
	preload("res://scripts/characters/house_characters.gd").new().build(self)

func register_driveable_vehicles() -> void:
	VehicleControls.register_driveable_vehicles(self)

## Leaves the vehicle being driven, or boards the focused one (E). True when it acted.
func toggle_vehicle() -> bool:
	return VehicleControls.toggle_vehicle(self)

func board_vehicle(vehicle: DriveableVehicle) -> bool:
	return VehicleControls.board(self, vehicle)

func complete_vehicle_exit(vehicle: DriveableVehicle, point: Vector3) -> void:
	VehicleControls.complete_vehicle_exit(self, vehicle, point)

func garage_door() -> Node3D:
	return VehicleControls.garage_door(self)

# Shops, cashiers and every minigame with their panels: scripts/core/minigame_wiring.gd.
func make_shops() -> void:
	MinigameWiring.build(self)
	# No word cards from a click or tap while the dialogue box shows (14 Nov 2026, user).
	interaction.dialogue_open = func() -> bool: return shop_panel.is_dialogue_visible()

# Settings window and the popup stack behind Esc (docs/guides/ARCHITECTURE_REVIEW_PART1.md#shared-dialogue-popups-and-settings--4-november-2026).
# Each popup is registered with what its ✕ does; Esc runs it for the topmost one only.
func make_popups() -> void:
	settings_panel = preload("res://scripts/ui/settings_panel.gd").new()
	hud.ui_root.add_child(settings_panel)
	settings_panel.visibility_changed.connect(sync_player_controls)
	settings_panel.controls_requested.connect(open_controls_guide)
	hud.settings_requested.connect(open_settings)
	# The HUD's book button and the journal's ✕ work like J (the saved words are its Saved tab).
	hud.journal_toggle_requested.connect(toggle_study_journal)
	# The F1 guide's ✕ and the ? button open or close it outside Main's key handling.
	hud.help_toggled.connect(sync_player_controls)
	GameSettings.shared().changed.connect(_on_settings_changed)
	popups = preload("res://scripts/ui/popup_stack.gd").new()
	popups.name = "PopupStack"
	add_child(popups)
	popups.watch(hud.popup_panel, interaction.clear_card)
	if Features.FULL_MAP:
		popups.watch(hud.map_overlay, hud.toggle_map)
	popups.watch(hud.journal_overlay, toggle_study_journal)
	# The sticker book's Back button shows inside a chapter or a word page: Esc goes back one
	# level (word page -> chapter -> contents) before it closes the journal (25 Nov 2026).
	popups.watch(hud.journal_book.back_button, hud.journal_book.go_back)
	popups.watch(hud.help_overlay, hud.toggle_help)
	MinigameWiring.watch_popups(self, popups)
	popups.watch(settings_panel, settings_panel.close)

func open_settings() -> void:
	if not settings_panel.visible:
		settings_panel.controls_allowed = not hud.in_minigame
		settings_panel.open()

## Settings' "Controls" (UI-04): the F1 guide, in its touch view on a touch device.
func open_controls_guide() -> void:
	settings_panel.close()
	if not hud.is_help_open() and not hud.in_minigame:
		hud.toggle_help()

## The Display Mode or a language changed (L, the HUD button or Settings): every open text
## re-renders. Text already built from the old languages (a family tree in progress) keeps
## them until it is shown again.
func _on_settings_changed() -> void:
	player.follow_camera = GameSettings.shared().follow_camera
	# The HUD follows GameSettings.changed itself (and then switches the world labels).
	MinigameWiring.refresh_display(self)
	interaction.refresh_selected_card()
	var lexicon = Lexicon.shared()
	var languages: String = lexicon.native + "/" + lexicon.foreign
	if languages == ui_languages:
		return
	# A language change ends any running minigame with its NPC's goodbye (user decision,
	# 4 Nov 2026) and switches to that foreign language's progress.
	ui_languages = languages
	for child in get_children():
		if child.has_method("end_activity"):
			child.end_activity()
	if lexicon.foreign != progress_language:
		progress_language = lexicon.foreign
		studied_words = VocabularyProgress.load_studied_words(vocabulary, vocabulary_aliases, progress_language)
		if hud.is_journal_open():
			hud.journal_studied = studied_words
			hud.render_journal()
	update_progress_display()

func make_ui() -> void:
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	# The minimap and the full map are switched off for now (Features; 14 Nov 2026): neither is
	# built, so `minimaps` stays empty.
	if Features.MINIMAP:
		var minimap := preload("res://scripts/ui/town_minimap.gd").new()
		minimap.add_to_group(hud.GAME_HIDDEN_GROUP)
		hud.ui_root.add_child(minimap)
		hud.ui_root.move_child(minimap, 0)
		minimap.setup(apartment, player)
		minimaps.append(minimap)
		if Features.FULL_MAP:
			minimap.on_tap = hud.toggle_map
	# Wayfinding (18 Nov 2026, user): the guide arrow, and the town map as a baked picture
	# (tools/bake_town_map.gd) with the places and games of data/town_map.json; nothing is drawn
	# from the town's meshes (the live map it replaced cost up to 64 ms a frame).
	guide = preload("res://scripts/ui/guide_arrow.gd").new()
	# Under every HUD window (as the minimap was); it hides itself in minigames.
	hud.ui_root.add_child(guide)
	hud.ui_root.move_child(guide, 0)
	guide.setup(self)
	if Features.FULL_MAP:
		town_map = preload("res://scripts/ui/town_map_panel.gd").new()
		hud.map_overlay.add_child(town_map)
		town_map.setup(self, guide)
		hud.map_toggled.connect(sync_player_controls)
	# Achievements, town stamps and missions (21 Nov 2026, docs/guides/ACHIEVEMENTS.md).
	preload("res://scripts/learning/achievement_hooks.gd").install(self)
	preload("res://scripts/world/stamp_places.gd").install(self)
	player.movement_mode_changed.connect(hud.set_movement_mode)
	player.infinite_jump_changed.connect(hud.set_infinite_jump)
	hud.set_movement_mode(false, false)
	# World signs are translated at load (sign_language.gd); English mode restores them.
	# Lexicon-bound labels (the school posters) re-render in the shown language.
	hud.language_changed.connect(func(_mode: int): apply_world_language())
	# Holding L (or the HUD peek button) shows the world in the native language (9 Nov 2026).
	GameSettings.shared().peek_changed.connect(apply_world_language)

## World signs (data/sign_translations.json) and Lexicon-bound labels show whatever language
## GameSettings.world_language() names (any taught language, 9 Nov 2026).
## Runs `job` now, or once building unit `key` is added if it is still pending (staged loading).
func when_unit_loaded(key: String, job: Callable) -> void:
	if pending_units.has(key):
		if not _unit_jobs.has(key):
			_unit_jobs[key] = []
		_unit_jobs[key].append(job)
	else:
		job.call()

## Adds building unit `key` now if it is still pending (await it), after any unit being added;
## nothing when it is loaded or not focused. Nearby loading (nearby_units.gd) uses it for the
## minigame picker and the tutorial replay.
func ensure_unit(key: String) -> void:
	while _adding_unit:
		await get_tree().process_frame
	if pending_units.has(key):
		await add_unit(key)

## Adds pending building unit `key` to the running town (staged loading, 13 Nov 2026) and gives
## it what _ready gives the units loaded at start (its plush characters go back one per frame
## first, so their sculpting is spread over frames; await it): doors, map entries, translated signs,
## vehicles, word areas, seats, solid figures, lamp glow, render trim and batches, then the jobs
## waiting for it (minigame sessions). The new buildings appear on the maps once all are added.
func add_unit(key: String) -> void:
	if not pending_units.has(key) or _adding_unit:
		return
	_adding_unit = true
	var held: Array = []
	var parts: Array = ModularTown.add_unit(apartment, key, held)
	for entry in held:
		await get_tree().process_frame
		ModularTown.put_back(apartment, entry)
	ModularTown.finish_refs(apartment)
	NpcRegistry.place(apartment, parts)
	NpcRegistry.spawn(apartment, parts)
	pending_units.erase(key)
	# The hook-up runs over several frames (17 Nov 2026, nearby loading stage 1: in one frame it
	# took 60-130 ms natively, render batching and word areas the most; measured in
	# docs/evidence/nearby-loading-20261117/time_add_unit.gd).
	var SignLanguage := preload("res://scripts/world/sign_language.gd")
	var signs := 0
	for part in parts:
		restore_editor_door_states(part)
		signs += SignLanguage.translate_all(part)
	apartment.set_meta("translated_signs", int(apartment.get_meta("translated_signs", 0)) + signs)
	if reference_layout != null:
		reference_layout.add_unit()
	register_driveable_vehicles()
	await get_tree().process_frame
	for part in parts:
		area_vocabulary.add(part, apartment, zones, vocabulary, vocabulary_aliases)
	await get_tree().process_frame
	for part in parts:
		seating.add_seats(part)
		preload("res://scripts/characters/house_characters.gd").solidify_figures(self, part)
		npc_chatter.attach_all(part)
	DoorAnimator.make_interactables(self)
	VehicleControls.make_interactables(self)
	area_vocabulary.drop_interactables(apartment)
	for part in parts:
		day_night.bind_lamps(part)
	await get_tree().process_frame
	if render_culling != null:
		# The render trim's building-shell rays need the unit's collision in the physics space.
		await get_tree().physics_frame
		render_culling.add_parts(self, parts, key)
	_adding_unit = false
	var jobs: Array = _unit_jobs.get(key, [])
	_unit_jobs.erase(key)
	for job in jobs:
		job.call()
	apply_world_language()
	update_progress_display()
	if pending_units.is_empty():
		for map in minimaps:
			map.rebuild()
	unit_added.emit(key)

func apply_world_language() -> void:
	var lang: String = GameSettings.shared().world_language()
	preload("res://scripts/world/sign_language.gd").set_language(get_tree(), lang)
	preload("res://scripts/language/live_labels.gd").set_language(get_tree(), lang)

func _on_word_studied(key: String) -> void:
	if not studied_words.has(key):
		studied_words[key] = true
		VocabularyProgress.save_studied_words(studied_words, vocabulary, vocabulary_aliases, progress_language)
		update_progress_display()

## The player stands still while the shared dialogue box waits for an answer (it shows choices:
## Next, Yes / Not now, ...; 14 Nov 2026, user): no walking, jumping or touch stick until it
## closes. A line without choices (a tutorial hint, a goodbye that closes when you walk off)
## keeps the player free. _process() notices the box changing.
func talk_locked() -> bool:
	return shop_panel != null and shop_panel.has_choices()

func sync_player_controls() -> void:
	var blocked: bool = talk_locked() or hud.is_map_open() or hud.is_journal_open() or hud.is_help_open() or MinigameWiring.locks_player(self) or (settings_panel != null and settings_panel.visible) or (hold_ui != null and hold_ui.inspecting()) or (poster_ui != null and poster_ui.inspecting())
	player.set_controls_enabled(not blocked)
	interaction.enabled = not blocked and not is_instance_valid(active_vehicle)
	if is_instance_valid(active_vehicle):
		active_vehicle.occupied = not blocked

func _unhandled_input(event: InputEvent) -> void:
	# Keys are InputMap actions (project.godot; PWA phase 2, 12 Nov 2026), so touch buttons
	# can fire the same ones. Hold L (peek): world signs and labels show the native language
	# until it is released.
	if event.is_action("peek") and not event.is_echo():
		GameSettings.shared().set_peek(event.is_pressed())
	# Moving (W, A, S, D or Space) closes the menu windows (user, 10 Nov 2026). A focused text
	# field (the journal's search) keeps its keys, so typing there never gets here.
	if event is InputEventKey and MOVE_ACTIONS.any(func(action: String) -> bool: return event.is_action_pressed(action)):
		close_menus()
	# Keys, and the same actions fired by the touch buttons (scripts/ui/touch_controls.gd).
	if (event is InputEventKey or event is InputEventAction) and event.is_pressed() and not event.is_echo():
		if event.is_action_pressed("back"):
			# The topmost popup closes; with nothing open, a running game may take it to ask the
			# shared leave question (its request_leave() -> bool, docs/guides/MINIGAMES.md; 25 Nov
			# 2026), else Esc opens Settings.
			if not popups.close_top() and not _request_leave():
				open_settings()
			player.release_orbit()
		elif event.is_action_pressed("help"):
			if not hud.in_minigame:
				hud.toggle_help()
		elif event.is_action_pressed("map"):
			# Not while the welcome tutorial hides the map button (18 Nov 2026).
			if Features.FULL_MAP and not hud.in_minigame and (hud.is_map_open() or not hud.tutorial_hidden.get("map", false)):
				if hud.is_journal_open():
					toggle_study_journal()
				hud.toggle_map()
		elif event.is_action_pressed("journal"):
			if not hud.in_minigame:
				if hud.is_map_open():
					hud.toggle_map()
				toggle_study_journal()
		elif event.is_action_pressed("debug_fps"):
			hud.toggle_fps()
		elif event.is_action_pressed("games"):
			if game_launcher != null:
				game_launcher.toggle()
		elif event.is_action_pressed("use"):
			use_pressed()
		elif event.is_action_pressed("debug_noclip"):
			if player.controls_enabled:
				player.toggle_noclip()
				hud.set_noclip(player.noclip_enabled)
		sync_player_controls()
	# A touch's emulated mouse press is left to touch_controls.gd: it taps on release, when
	# the finger did not drag the view.
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION:
		# A click (or a tap: touch is emulated as the mouse) works like E on an interactable and
		# its "E" badge, and shows a plain word's card (interaction_controller.gd click()).
		interaction.click()
		sync_player_controls()

## Esc / back with no popup open: the running game's request_leave() (true when it asked its
## leave question). Games without it let Settings open as before.
func _request_leave() -> bool:
	var running: String = Board.shared().blocker("")
	var session: Object = Board.shared().session(running) if running != "" else null
	return session != null and session.has_method("request_leave") and bool(session.request_leave())

## The E key: the input claim that holds it (driving, seated, the warehouse game while carrying)
## or the focused interactable (docs/guides/ARCHITECTURE_REVIEW_PART1.md#interaction-system).
func use_pressed() -> void:
	var held: Dictionary = interaction.active_claim()
	if not held.is_empty():
		held.use.call()
	elif player.controls_enabled:
		interaction.activate_focus()

## The menu windows a movement action closes: the minigame picker, F1 help, the full map, the
## journal and Settings (not a running minigame's own panels).
const MOVE_ACTIONS: Array[String] = ["move_forward", "move_back", "move_left", "move_right", "jump"]

func close_menus() -> void:
	if game_launcher != null and game_launcher.visible:
		game_launcher.close()
	if passport != null and passport.visible:
		passport.close()
	if hud.is_help_open():
		hud.toggle_help()
	if hud.is_map_open():
		hud.toggle_map()
	if hud.is_journal_open():
		toggle_study_journal()
	if settings_panel != null and settings_panel.visible:
		settings_panel.close()
	sync_player_controls()

## While any minigame is in progress the map, minimap and corner buttons are off; only the
## Settings gear and the peek badge stay (user, 12 Nov 2026). Open map/journal/help windows close.
func sync_minigame_hud() -> void:
	var running: bool = Board.shared().blocker("") != ""
	if running == hud.in_minigame:
		return
	hud.in_minigame = running
	hud.hide_for_game(running, "minigame")
	if running:
		if hud.is_help_open():
			hud.toggle_help()
		if hud.is_map_open():
			hud.toggle_map()
		if hud.is_journal_open():
			toggle_study_journal()
		if game_launcher != null and game_launcher.visible:
			game_launcher.close()
	sync_player_controls()

func toggle_study_journal() -> void:
	hud.toggle_journal(studied_words, vocabulary, vocabulary_categories, area_vocabulary.groups, area_vocabulary.area_names)
	sync_player_controls()

## A player below this world height fell out of the town and starts again at spawn_position().
## -30 since 23 Nov 2026 (was -15): the Mystery House's endless hall floor (house-local -11 at
## the Apartment's 1.3 scale) stands at about -14.3, so a small dip there moved a Mystery Doors
## player to the supermarket with the game still running (mystery_session.gd _guard_place).
const FALL_RESPAWN_Y := -30.0

## Puts the player at `position` (world) facing `yaw` (NAN keeps the view) as a respawn: a fall
## below FALL_RESPAWN_Y and the last-resort unstuck from a blocked seat or vehicle (GAME-05,
## 25 Nov 2026, PlayerPlace.rescue_spot()). A minigame running then ends through its own
## end_activity() (the stop a language change uses, with its NPC's goodbye), so no game is left
## half open with the player somewhere else.
func respawn(position: Vector3, yaw: float = NAN) -> void:
	end_running_game()
	player.global_position = position
	player.velocity = Vector3.ZERO
	if not is_nan(yaw):
		player.camera_yaw = yaw
		player.rotation.y = yaw
	player.reset_camera()

## Ends the minigame in progress (Board.blocker("")) through its end_activity(), if it has one.
func end_running_game() -> void:
	var running: String = Board.shared().blocker("")
	var session: Object = Board.shared().session(running) if running != "" else null
	if session != null and session.has_method("end_activity"):
		session.end_activity()

func _process(delta: float) -> void:
	# Minigame started / ended signals (activity_board.gd watch(), PWA phase 4).
	preload("res://scripts/learning/activity_board.gd").shared().watch()
	if player.global_position.y < FALL_RESPAWN_Y and not player.noclip_enabled and not is_instance_valid(active_vehicle):
		respawn(spawn_position())
	sync_minigame_hud()
	# Also when something else (a fade's end, minigame_zone.gd) switched the controls back on.
	if talk_locked() != player_talk_locked or (player_talk_locked and player.controls_enabled):
		player_talk_locked = talk_locked()
		sync_player_controls()
	hud_status_timer += delta
	if hud_status_timer >= 0.25:
		hud_status_timer = 0.0
		hud.set_flight_status(active_vehicle.flight_status() if is_instance_valid(active_vehicle) else "")
		VehicleControls.update_home(self)
		preload("res://scripts/learning/achievement_hooks.gd").tick(self)
	var next_room := current_room()
	if next_room != room_name:
		room_name = next_room
		update_progress_display()
	DoorAnimator.animate(self, delta)
	VehicleControls.update_flight_view(self, delta)
