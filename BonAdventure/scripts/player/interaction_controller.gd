extends Node3D

# Owns picking, the interaction focus and study-card selection. Learning state stays
# with the caller, which receives word_studied whenever a card is shown.
#
# Interaction system (12 Nov 2026, user; docs/guides/ARCHITECTURE_REVIEW_PART1.md#interaction-system):
#   - every interactive object has an Interactable child (scripts/core/interactable.gd);
#   - one focus pass (FOCUS_INTERVAL, about 10 Hz) picks ONE focus target and pins the "E"
#     badge to it (scripts/ui/interact_badge.gd), and places the discovery icons;
#   - E (Main.use_pressed), a click or a tap: first the active input claim (a vehicle being
#     driven, a seat, the warehouse game while carrying), else the focus target / the
#     interactable clicked; a plain vocabulary object (no Interactable) shows its word card.
signal word_studied(key: String)

const INTERACT_DISTANCE := 8.0
const FIGURE_LAYER: int = preload("res://scripts/characters/house_characters.gd").FIGURE_LAYER
const EXTERIOR_DISTANCE := 40.0
const Board := preload("res://scripts/learning/activity_board.gd")
const UiText := preload("res://scripts/language/ui_text.gd")
const Interactable := preload("res://scripts/core/interactable.gd")
const InteractIcons := preload("res://scripts/ui/interact_badge.gd")
## Seconds between focus passes.
const FOCUS_INTERVAL := 0.1
## Interactables farther than this (metres, from the owner's origin) are skipped at once.
const COARSE_RANGE := 18.0
## Vertical metres between the player's feet and an interactable's point that still count.
const MAX_RISE := 2.6
## Station dots: how far the dot may sit above / below the player's feet (one storey).
const STATION_ABOVE := 4.5
const STATION_BELOW := 1.5
## Forward cone (cosine) for needs_facing; closer than FACING_FREE metres anything counts.
const FACING_COS := 0.25
const FACING_FREE := 0.7
## Extra priority of an NPC calling with its "!" (an open game offer): in talking range it wins
## over nearer chairs and objects, so the "!" becomes the "E" (aiming still picks anything).
const CALL_BONUS := 2.0
## A click on an interactable counts within its prompt_distance plus this (metres).
const CLICK_SLACK := 0.6

var pointer_position := Vector2.ZERO
var enabled := true
var camera: Camera3D
var player: CharacterBody3D
var apartment: Node3D
var hud
var vocabulary: Dictionary
var vocabulary_categories: Dictionary
var vocabulary_aliases: Dictionary = {}
## While valid (the shopping cart is open), a left click calls this with the aimed object
## (or null) instead of opening a word card, so nothing is studied. See shop_session.gd.
var pick_hook: Callable = Callable()
## Off while the welcome tutorial holds word cards back (tutorial.gd, until its "words" step):
## a click on a plain vocabulary object then shows no card and studies nothing. The pick hook
## and interactables still work.
var word_cards := true
## Optional (word: Node3D) -> bool: a clicked word that would open its card goes here first;
## true = handled, no card (a word on a poster opens the poster close-up instead, user 24 Nov
## 2026; poster_inspect_ui.gd).
var poster_hook: Callable
## Off while the welcome tutorial's control steps or a line of its dialogue hold the player's
## interactions back (tutorial.gd "controls", 17 Nov 2026, user): nothing can be focused or
## clicked; input claims (standing up from the bed with E) still work.
var interact_allowed := true
## Optional (obj: Node3D) -> bool: only objects it accepts open a word card (the welcome
## tutorial's statue step: only the statue, user 13 Nov 2026).
var word_filter: Callable
## Optional (item: Interactable) -> bool: only interactables it accepts can be focused, pressed
## or clicked (the welcome tutorial: doors and BonBon only, user 17 Nov 2026; tutorial.gd).
var interact_filter: Callable
## Optional () -> bool, true while the shared dialogue box shows (Main): a click or tap then
## opens no word card (14 Nov 2026, user), unless word_filter is set: a line that asks for one
## object (the tutorial's statue) lets exactly that object's card open. Interactables, the
## pick hook and an open card's own timing are unchanged.
var dialogue_open: Callable
## Above 0: a word card closes by itself this many seconds after it opened (the welcome
## tutorial's, data/tutorial.json "card_seconds", user 14 Nov 2026); 0 = it stays until dismissed.
var card_seconds := 0.0
var _card_age := 0.0
var selected: Node3D
var selected_point := Vector3.ZERO
var selected_player_position := Vector3.ZERO
## True while the card was opened by a player already walking or in the air (user, 23 Nov 2026:
## a tap on the tiger while jumping did nothing, as the first moving frame closed the card it
## opened). Such a card follows the player instead of closing; once they stand still, the next
## step closes it as usual.
var selected_while_moving := false
## Player speed (m/s) above which a click counts as made while moving.
const MOVING_SPEED := 0.05
var look_away_seconds := 0.0
## Mouse travel (pixels) during a right-button camera drag before the card closes.
const ORBIT_DISMISS_PIXELS := 6.0
var orbit_drag := 0.0
var right_held := false
## The focused Interactable (or null) and the icons.
var focus: Node
var icons
var _focus_timer := 0.0
## Input claims, newest last: {id, wants: Callable -> bool, use: Callable, click: Callable}.
var _claims: Array[Dictionary] = []

func setup(view: Camera3D, explorer: CharacterBody3D, world: Node3D,
        study_hud: CanvasLayer, words: Dictionary, categories: Dictionary, aliases: Dictionary = {}) -> void:
    pointer_position = view.get_viewport().get_mouse_position()
    camera = view
    player = explorer
    apartment = world
    hud = study_hud
    vocabulary = words
    vocabulary_categories = categories
    vocabulary_aliases = aliases
    icons = InteractIcons.new()
    add_child(icons)

func refresh_selected_card() -> void:
    if is_instance_valid(selected):
        show_word(selected)

func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion or event is InputEventMouseButton:
        pointer_position = event.position
    elif event is InputEventScreenTouch or event is InputEventScreenDrag:
        pointer_position = event.position
    # Dragging the view with the right mouse button closes the word card; a click
    # without a real drag (under ORBIT_DISMISS_PIXELS) leaves it open.
    # The left button drags the view too (player_controller.gd, 13 Nov 2026), not on touch.
    if event is InputEventMouseButton and (event.button_index == MOUSE_BUTTON_RIGHT or (event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION)):
        right_held = event.pressed
        orbit_drag = 0.0
    elif event is InputEventMouseMotion and right_held:
        orbit_drag += event.relative.length()
        if orbit_drag > ORBIT_DISMISS_PIXELS and is_instance_valid(selected) and hud.is_card_visible():
            clear_card()

func aimed_hit() -> Dictionary:
    if not is_instance_valid(camera) or not is_instance_valid(player):
        return {}
    var pointer := pointer_position
    if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        pointer = get_viewport().get_visible_rect().size * 0.5
    # The camera on screen: a close-up (the tutorial's apple, 20 Nov 2026) aims from where it looks.
    var view: Camera3D = get_viewport().get_camera_3d()
    if view == null:
        view = camera
    var origin := view.project_ray_origin(pointer)
    var ray := PhysicsRayQueryParameters3D.create(origin, origin + view.project_ray_normal(pointer) * (EXTERIOR_DISTANCE + origin.distance_to(player.global_position)))
    ray.exclude = [player.get_rid()]
    ray.collide_with_areas = true
    # Figure blockers (house_characters.gd) only stop the player; words keep their own areas.
    ray.collision_mask = 0xFFFFFFFF & ~FIGURE_LAYER
    return get_world_3d().direct_space_state.intersect_ray(ray)

## The vocabulary word under the pointer (within reach), or null. Interactables are not words
## (user, 12 Nov 2026): a hit on one returns null.
func aimed_object() -> Node3D:
    if not enabled:
        return null
    var hit: Dictionary = aimed_hit()
    if hit.is_empty() or player.global_position.distance_to(hit["position"]) > EXTERIOR_DISTANCE:
        return null
    if Interactable.find_for(hit["collider"], apartment) != null:
        return null
    # Keep the original range rule: only an exterior ancestor gets the longer reach.
    var surface: Node = hit["collider"]
    while surface != null and surface != apartment:
        if surface is Node3D and surface.has_meta("exterior_word"): return surface as Node3D
        surface = surface.get_parent()
    if player.global_position.distance_to(hit["position"]) > INTERACT_DISTANCE: return null
    return vocabulary_target(hit["collider"], apartment)

## The Interactable under the pointer (any distance), or null.
func aimed_interactable() -> Node:
    var hit: Dictionary = aimed_hit()
    if hit.is_empty():
        return null
    return Interactable.find_for(hit["collider"], apartment)

# Shared by picking and the area index: only actual pickable targets are catalogued.
# `_door_registry` is ignored since 12 Nov 2026 (doors are interactables); older checks pass it.
static func vocabulary_target(body: Node, world: Node3D, _door_registry: Dictionary = {}) -> Node3D:
    # Exterior metadata takes precedence over generic wall/window vocabulary.
    var surface: Node = body as Node
    while surface != null and surface != world:
        if surface is Node3D and surface.has_meta("exterior_word"):
            return surface as Node3D
        surface = surface.get_parent()
    if body is Node and body.has_meta("vocabulary_root_path"):
        var saved_root: Node = body.get_node_or_null(body.get_meta("vocabulary_root_path"))
        if saved_root is Node3D and str(saved_root.get_meta("word_key", "")) != "":
            return saved_root as Node3D
    if body.has_meta("root"):
        var original_root: Variant = body.get_meta("root")
        if is_instance_valid(original_root) and original_root is Node3D:
            var original: Node3D = original_root as Node3D
            if str(original.get_meta("word_key", "")) != "":
                return original
    # Saved PackedScenes cannot serialize live Node references in metadata.
    # Walk up to the nearest vocabulary node instead; this works for both
    # prefab instances and the remaining generated geometry.
    if body is Node:
        var ancestor: Node = body as Node
        while ancestor != null and ancestor != world:
            if ancestor is Node3D and str(ancestor.get_meta("word_key", "")) != "":
                return ancestor as Node3D
            ancestor = ancestor.get_parent()
    return null

func clear_card() -> void:
    selected = null
    look_away_seconds = 0.0
    hud.hide_card()

# --- Input claims ------------------------------------------------------------------------------

## A modal owner of E and the click (the vehicle being driven, the seat, the warehouse game while
## carrying). While `wants` returns true, E calls `use` and a click calls `click` (nothing when
## invalid), and no focus target or badge is shown. Newest claim first; same id replaces.
func claim(id: String, wants: Callable, use: Callable, click: Callable = Callable()) -> void:
    release_claim(id)
    _claims.append({"id": id, "wants": wants, "use": use, "click": click})

func release_claim(id: String) -> void:
    for i in range(_claims.size() - 1, -1, -1):
        if _claims[i].id == id:
            _claims.remove_at(i)

## The claim that holds input now ({} when none).
func active_claim() -> Dictionary:
    for i in range(_claims.size() - 1, -1, -1):
        var entry: Dictionary = _claims[i]
        if entry.wants.call():
            return entry
    return {}

# --- Focus -------------------------------------------------------------------------------------

## Whether interactables can be focused at all now.
func can_focus() -> bool:
    return enabled and interact_allowed and is_instance_valid(player) and player.get("controls_enabled") != false and not player.get("seated") \
        and not player.get("noclip_enabled") and player.get("ladder_node") == null and active_claim().is_empty()

## E, or a tap on the badge: refreshes the focus (the player may have just turned) and activates
## it. False when nothing is focused.
func activate_focus() -> bool:
    refresh_focus()
    return activate(focus)

## Activates `item` (an Interactable): its reason line, if it gives one, flashes instead.
func activate(item: Node) -> bool:
    if item == null or not is_instance_valid(item):
        return false
    clear_card()
    var reason: String = item.activate()
    if reason != "":
        hud.flash_quest_message(UiText.maybe(reason))
    refresh_focus()
    return true

## Runs the focus pass now (the ~10 Hz pass also calls it).
func refresh_focus() -> void:
    _focus_timer = 0.0
    var bangs: Array[Vector3] = []
    var dots: Array[Vector3] = []
    var next: Node = null
    if is_instance_valid(player) and enabled:
        next = _pick_focus(bangs, dots)
    focus = next
    if focus != null:
        icons.show_badge(focus.badge_point())
    else:
        icons.hide_badge()
    icons.set_icons(bangs, dots)
    hud.set_pointer_active(focus != null and focus == _aimed_cache)

var _aimed_cache: Node

## The interactable the last focus pass found under the pointer (or null).
func aimed_interactable_last() -> Node:
    return _aimed_cache if is_instance_valid(_aimed_cache) else null

## A station's dot shows only on the player's own floor, within discover_distance in 3D and in sight
## (23 Nov 2026, user: the control-tower radars' dots showed from the ground and the deck, far
## below or outside them, because only the flat distance was measured).
func _station_near(item: Node, feet: Vector3) -> bool:
    var at: Vector3 = item.badge_point()
    var rise := at.y - feet.y
    if rise <= -STATION_BELOW or rise >= STATION_ABOVE \
            or at.distance_squared_to(feet) > item.discover_distance * item.discover_distance:
        return false
    # And only in sight: not through a wall, a floor or the control room's glass.
    var ray := PhysicsRayQueryParameters3D.create(feet + Vector3.UP * 1.6, at)
    ray.exclude = [player.get_rid()]
    ray.collision_mask = 0xFFFFFFFF & ~FIGURE_LAYER
    var hit := get_world_3d().direct_space_state.intersect_ray(ray)
    if hit.is_empty():
        return true
    var owner_node: Node = item.get_parent()
    return hit.collider == owner_node or owner_node.is_ancestor_of(hit.collider)

## One pass over the group: discovery icons into `bangs` / `dots`, returns the focus target.
func _pick_focus(bangs: Array[Vector3], dots: Array[Vector3]) -> Node:
    var focusing := can_focus()
    var game_running := minigame_running()
    var feet := player.global_position
    var heading := -player.global_basis.z
    var forward := Vector2(heading.x, heading.z).normalized()
    _aimed_cache = aimed_interactable() if focusing else null
    var ranked: Array = []
    var bang_items: Array[Node] = []
    var dot_items: Array[Node] = []
    for item in get_tree().get_nodes_in_group(Interactable.GROUP):
        var owner_node: Node3D = item.get_parent() as Node3D
        if owner_node == null or not owner_node.is_inside_tree() or not item.enabled:
            continue
        if interact_filter.is_valid() and not interact_filter.call(item):
            continue
        var origin := owner_node.global_position
        var coarse := Vector2(origin.x - feet.x, origin.z - feet.z).length_squared()
        if coarse > COARSE_RANGE * COARSE_RANGE and coarse > item.discover_distance * item.discover_distance:
            continue
        if not _shown(owner_node):
            continue
        # Discovery icons (not for the focus target: its "!" becomes the "E"). None in a vehicle
        # or with a menu open: this pass does not run then (enabled is false, Main).
        if item.indicator == Interactable.Indicator.CALL and item.calling:
            bang_items.append(item)
        elif item.indicator == Interactable.Indicator.STATION and not game_running \
                and _station_near(item, feet):
            dot_items.append(item)
        if not focusing:
            continue
        var aimed: bool = item == _aimed_cache
        if item.needs_aim and not aimed:
            continue
        var at: Vector3 = item.point(feet)
        if absf(at.y - feet.y) > MAX_RISE and not (aimed and at.distance_to(feet) <= item.prompt_distance + MAX_RISE):
            continue
        var flat := Vector2(at.x - feet.x, at.z - feet.z)
        var distance := flat.length()
        if distance > item.prompt_distance:
            continue
        var facing := forward.dot(flat / distance) if distance > 0.001 else 1.0
        if item.needs_facing and not aimed and distance > FACING_FREE and facing < FACING_COS:
            continue
        var turn: float = item.on_rank.call(feet, forward) if item.on_rank.is_valid() else (1.0 - facing) * 0.75
        var score: float = distance + turn - float(item.priority) - (CALL_BONUS if item.calling else 0.0) \
                - (100.0 if aimed else 0.0)
        ranked.append([score, item])
    ranked.sort_custom(func(a, b): return a[0] < b[0])
    var chosen: Node = null
    for entry in ranked:
        var state: Variant = entry[1].check()
        if state is bool and not state:
            continue
        chosen = entry[1]
        break
    # The focused NPC's "!" turns into the "E": one icon over the head.
    for item in bang_items:
        if item != chosen:
            bangs.append(item.badge_point())
    for item in dot_items:
        if item != chosen:
            dots.append(item.badge_point())
    return chosen

## Visible in the tree (a statically batched mesh, render_culling / garden_rendering, is hidden
## while its batch draws it: its parent decides).
static func _shown(node: Node3D) -> bool:
    if node.has_meta("render_batched") and node.get_parent() is Node3D:
        return (node.get_parent() as Node3D).is_visible_in_tree()
    return node.is_visible_in_tree()

# --- Click and tap -----------------------------------------------------------------------------

## A left click or a tap at pointer_position. Order: the active claim; the "E" badge; an
## interactable under the pointer (in range: activates it, otherwise nothing: it is not a word);
## the shopping cart's pick hook; a vocabulary word's card (not while a minigame runs).
func click() -> void:
    var held := active_claim()
    if not held.is_empty():
        if held.click.is_valid():
            held.click.call()
        return
    if not enabled or not interact_allowed or player.get("controls_enabled") == false:
        return
    # An open word card closes on any click or tap, wherever it lands (user, 14 Nov 2026: easy
    # to exit on a phone); that click does nothing else. The card's star and the peek badge
    # take their own presses before this.
    if hud.is_card_visible():
        clear_card()
        return
    var area: Dictionary = icons.badge_hit_area(camera)
    if not area.is_empty() and pointer_position.distance_to(area.center) <= area.radius:
        activate_focus()
        return
    var item := aimed_interactable()
    if item != null and interact_filter.is_valid() and not interact_filter.call(item):
        item = null
    if item != null:
        if item == focus or _clickable(item):
            activate(item)
        elif can_focus() and _shown(item.get_parent()) and _too_far(item):
            _walk_closer()
        return
    var obj: Node3D = aimed_object()
    if pick_hook.is_valid():
        pick_hook.call(obj)
        return
    # No word cards while any minigame runs (user, 8 Nov 2026): clicking is the game's; nor
    # while the welcome tutorial holds them back (user, 13 Nov 2026).
    if minigame_running() or not word_cards:
        clear_card()
        return
    if dialogue_open.is_valid() and dialogue_open.call() and not word_filter.is_valid():
        return
    if not is_instance_valid(obj) or (word_filter.is_valid() and not word_filter.call(obj)):
        clear_card()
        if not is_instance_valid(obj) and _far_word():
            _walk_closer()
    elif selected == obj:
        clear_card()
    else:
        selected = obj
        selected_player_position = player.global_position
        selected_while_moving = player.velocity.length() > MOVING_SPEED
        var hit: Dictionary = aimed_hit()
        selected_point = hit["position"] if not hit.is_empty() else selected.global_position
        if poster_hook.is_valid() and not word_filter.is_valid() and poster_hook.call(obj):
            selected = null
            return
        look_away_seconds = 0.0
        _card_age = 0.0
        show_word(obj)

## A clicked interactable that is not the focus target: in range and available.
func _clickable(item: Node) -> bool:
    if not can_focus() or not _shown(item.get_parent()):
        return false
    var at: Vector3 = item.point(player.global_position)
    if at.distance_to(player.global_position) > item.prompt_distance + CLICK_SLACK + MAX_RISE:
        return false
    if Vector2(at.x - player.global_position.x, at.z - player.global_position.z).length() > item.prompt_distance + CLICK_SLACK:
        return false
    var state: Variant = item.check()
    return not (state is bool and not state)

## Out of reach (P3-06, 25 Nov 2026): a tap or click on an interactable beyond its click range,
## or on a word between INTERACT_DISTANCE and EXTERIOR_DISTANCE, says "Walk closer" instead of
## doing nothing (a touch player cannot see why).
func _too_far(item: Node) -> bool:
    var at: Vector3 = item.point(player.global_position)
    return at.distance_to(player.global_position) > item.prompt_distance + CLICK_SLACK + MAX_RISE \
            or Vector2(at.x - player.global_position.x, at.z - player.global_position.z).length() > item.prompt_distance + CLICK_SLACK

func _far_word() -> bool:
    var hit: Dictionary = aimed_hit()
    if hit.is_empty():
        return false
    var far: float = player.global_position.distance_to(hit["position"])
    if far <= INTERACT_DISTANCE or far > EXTERIOR_DISTANCE or Interactable.find_for(hit["collider"], apartment) != null:
        return false
    return vocabulary_target(hit["collider"], apartment) != null

## The "Walk closer" toast (the HUD's quest toast, native language).
func _walk_closer() -> void:
    if hud != null and hud.has_method("flash_quest_message"):
        hud.flash_quest_message(UiText.t("toast.walk_closer"))

## Whether any minigame (activity_board.gd) is in progress: word cards are off meanwhile.
func minigame_running() -> bool:
    return Board.shared().blocker("") != ""

func word_key(obj: Node3D) -> String:
    var raw_key: String = str(obj.get_meta("exterior_word", obj.get_meta("word_key", obj.name.to_lower())))
    return str(vocabulary_aliases.get(raw_key, raw_key))

func show_word(obj: Node3D) -> void:
    # Named house characters introduce themselves; this is not vocabulary study.
    if obj.has_meta("character_name"):
        hud.show_name_card(str(obj.get_meta("character_name")), str(obj.get_meta("character_species", "")))
        return
    var key: String = word_key(obj)
    var english: String = key.replace("_", " ").capitalize()
    var spanish: String = str(vocabulary.get(key, key))
    hud.show_card(english, spanish, str(vocabulary_categories.get(key, "Everyday")), key)
    word_studied.emit(key)

func _physics_process(delta: float) -> void:
    # Dismiss on the first movement frame, independently of pointer-check timing; a card opened
    # while moving (selected_while_moving) waits until the player has stood still first.
    if is_instance_valid(selected):
        if player.global_position.is_equal_approx(selected_player_position):
            selected_while_moving = false
        elif selected_while_moving:
            selected_player_position = player.global_position
        else:
            clear_card()
    _focus_timer += delta
    if _focus_timer >= FOCUS_INTERVAL:
        refresh_focus()
    elif focus != null and is_instance_valid(focus):
        # Moving targets (a car door, a hopping NPC) keep their badge on them between passes.
        icons.show_badge(focus.badge_point())
    elif focus != null:
        focus = null
        icons.hide_badge()
    if card_seconds > 0.0 and is_instance_valid(selected) and hud.is_card_visible():
        _card_age += delta
        if _card_age >= card_seconds:
            clear_card()
    # Small, unintentional mouse movements do not dismiss the popup.
    if is_instance_valid(selected) and hud.is_card_visible():
        var on_screen: bool = not camera.is_position_behind(selected_point) and get_viewport().get_visible_rect().has_point(camera.unproject_position(selected_point))
        var distance_limit: float = EXTERIOR_DISTANCE if selected.has_meta("exterior_word") else INTERACT_DISTANCE
        if not on_screen or player.global_position.distance_to(selected_point) > distance_limit + 1.2:
            look_away_seconds += delta
            if look_away_seconds > 0.22:
                clear_card()
        else:
            look_away_seconds = 0.0
