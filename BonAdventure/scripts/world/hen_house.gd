extends Node3D
## The farm's hen house and its eggs (user, 24 Nov 2026; record:
## docs/guides/TOWN_DESIGN_BRIEF.md#hen-house-and-eggs--24-november-2026). Built by the barn step
## `hen_house` (scripts/buildings/barn.gd) as `Barn/Hen house`, whose frame is the town's (its
## local coordinates are town coordinates: +X west, +Z north, Apartment scale 1.3 above it).
## Children from the bake: "Coop" (the little red hen house in the paddock, west of the barn),
## "Egg spots" (Marker3D: four nest boxes and seven straw nests on the ground), "Hens" (six
## park_animals.gd hens, given their yard here) and "Egg crate" (on a table inside the barn door,
## "Slots": one Marker3D per egg cup).
##
## The hens lay over time: one roll every ROLL_SECONDS of real time, also while the game is shut
## (caught up at load, at most CATCH_UP rolls). Below COMMON eggs a roll lays one with chance
## P_COMMON, above it (eggs 5 to CAP) with P_RARE: about 3 to 4 eggs after 15 minutes away, a
## 5th now and then, rarely 6 or 7. Each egg is golden with chance P_GOLD. A new profile starts
## with FIRST_ROLLS rolls already made, so the first visit finds eggs.
##
## The player takes one egg in the hand (farm_egg.gd, E / click / tap) and puts it in the crate
## (E / click / tap on the crate): a hop and sparks, a toast with the count. Carried out of the
## farm (FARM), the egg is dropped: it breaks at the player's feet and the HUD says so. The crate
## is emptied when the player leaves the farm (the farmer takes the eggs). Nothing is rewarded yet
## (user: stars later): every delivery notes the achievement events "farm_egg" and, for a golden
## one, "golden_egg", so a reward can count them.
##
## Saved per profile in hen_house.json (save_store.gd): {"eggs": [{"spot", "gold", "brown"}],
## "rolled_at": unix seconds of the last roll}. Cost: one check four times a second.
const FarmEgg := preload("res://scripts/world/farm_egg.gd")
const HandHold := preload("res://scripts/player/hand_hold.gd")
const Interactable := preload("res://scripts/core/interactable.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")
const UiText := preload("res://scripts/language/ui_text.gd")
const SuccessBurst := preload("res://scripts/world/success_burst.gd")
const Achievements := preload("res://scripts/learning/achievements.gd")
const FILE := "hen_house.json"

const ROLL_SECONDS := 60
const COMMON := 4
const CAP := 7
const P_COMMON := .28
const P_RARE := .04
const P_GOLD := .03
const CATCH_UP := 60
const FIRST_ROLLS := 15
## The farm (LA GRANJA lawn, x 42...90, z 73...109) and a little more, in town coordinates: an
## egg carried out of it is dropped.
const FARM := Rect2(41.0, 72.0, 50.0, 38.0)
## Where the hen house's hens wander (town x 73.4...84.6, z 74...82): around the coop, clear of
## the barn wall (x 72) and the sheep's ground (from z 82.3).
const HEN_YARD := Rect2(73.4, 74.0, 11.2, 8.0)
const CHECK_SECONDS := .25

var spots: Array[Node] = []
var slots: Array[Node] = []
var crate: Node3D
var state := {}
var _rng := RandomNumberGenerator.new()
var _in_crate: Array[Node3D] = []
var _timer := 0.0
var _was_on_farm := false

func _ready() -> void:
	if Engine.is_editor_hint() or _baking():
		set_process(false)
		return
	_rng.randomize()
	spots = $"Egg spots".get_children()
	crate = $"Egg crate"
	slots = crate.get_node("Slots").get_children()
	Interactable.attach(crate, {
		"prompt_distance": 1.8,
		# Above the egg in the hand and the farmer close by.
		"priority": 3.0,
		"badge_offset": Vector3(0, .35, 0),
		"on_use": deliver,
		"on_check": _crate_check,
	})
	for hen in $Hens.get_children():
		if hen.has_method("configure"):
			hen.call_deferred("configure", hen._visible_bounds(), HEN_YARD)
	_load()

func _baking() -> bool:
	var node: Node = self
	while node != null:
		if node.has_meta("bake_world_only"):
			return true
		node = node.get_parent()
	return false

# --- Laying -------------------------------------------------------------------------------------

func _load() -> void:
	var parsed: Variant = SaveStore.read_json(SaveStore.path(FILE))
	var now := _now()
	if parsed is Dictionary and parsed.get("eggs") is Array:
		state = parsed
	else:
		state = {"eggs": [], "rolled_at": now - FIRST_ROLLS * ROLL_SECONDS}
	# Drop entries for spots that no longer exist (a later rebuild with fewer spots).
	state.eggs = (state.eggs as Array).filter(func(e): return e is Dictionary and int(e.get("spot", -1)) in range(spots.size()))
	var rolls := int((now - int(state.get("rolled_at", now))) / ROLL_SECONDS)
	for i in mini(rolls, CATCH_UP):
		_roll(false)
	state.rolled_at = now if rolls >= CATCH_UP else int(state.get("rolled_at", now)) + maxi(rolls, 0) * ROLL_SECONDS
	for entry in state.eggs:
		_spawn(entry, false)
	_save()

func _save() -> void:
	SaveStore.write_json(SaveStore.path(FILE), state)

static func _now() -> int:
	return int(Time.get_unix_time_from_system())

## One roll: maybe an egg, at a free spot. `show` makes the egg appear in the town (with a pop).
func _roll(show: bool) -> void:
	var count: int = (state.eggs as Array).size()
	if count >= CAP:
		return
	if _rng.randf() >= (P_COMMON if count < COMMON else P_RARE):
		return
	var used := {}
	for entry in state.eggs:
		used[int(entry.spot)] = true
	var free: Array[int] = []
	for i in spots.size():
		if not used.has(i):
			free.append(i)
	if free.is_empty():
		return
	var entry := {"spot": free[_rng.randi_range(0, free.size() - 1)], "gold": _rng.randf() < P_GOLD, "brown": _rng.randf() < .5}
	state.eggs.append(entry)
	if show:
		_spawn(entry, true)

func _spawn(entry: Dictionary, pop: bool) -> void:
	var spot: Node3D = spots[int(entry.spot)]
	var egg: Node3D = FarmEgg.make(int(entry.spot), bool(entry.get("gold", false)), bool(entry.get("brown", false)))
	spot.add_child(egg)
	if pop:
		egg.scale = Vector3.ONE * .01
		egg.create_tween().tween_property(egg, "scale", Vector3.ONE, .35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _forget(egg: Node3D) -> void:
	state.eggs = (state.eggs as Array).filter(func(e): return int(e.spot) != egg.spot)
	_save()

# --- The crate ----------------------------------------------------------------------------------

func _held_egg() -> Node3D:
	var hand := HandHold.of_player(self)
	if hand == null or not hand.is_holding():
		return null
	var item: Node3D = hand.held
	return item if item.get_script() == FarmEgg and spots.has(_spot_of(item)) else null

func _spot_of(egg: Node3D) -> Node:
	return spots[egg.spot] if egg.spot >= 0 and egg.spot < spots.size() else null

## The crate's E: with an egg in the hand, take it; else a line saying what the crate is for.
func _crate_check() -> Variant:
	return true if _held_egg() != null else UiText.t("toast.egg_crate_hint")

## E, a click or a tap on the crate with an egg in the hand: the egg goes into the next cup.
func deliver() -> void:
	var egg := _held_egg()
	if egg == null:
		return
	if _in_crate.size() >= slots.size():
		_empty_crate()
	var slot: Node3D = slots[_in_crate.size()]
	HandHold.of_player(self).release(slot, slot.global_transform)
	egg.transform = Transform3D.IDENTITY
	egg.delivered = true
	var item := Interactable.on(egg)
	if item != null:
		item.enabled = false
	_in_crate.append(egg)
	_forget(egg)
	Achievements.shared().note("golden_egg" if egg.golden else "farm_egg")
	var camera := get_viewport().get_camera_3d()
	var top := egg.global_position + Vector3(0, .3, 0)
	SuccessBurst.celebrate(egg, top, camera.global_position if camera != null else top + Vector3.BACK, 1.6 if egg.golden else 1.0)
	_toast(UiText.t("toast.golden_egg") if egg.golden else UiText.t("toast.egg_in_crate", {"count": str(_in_crate.size())}))

func _empty_crate() -> void:
	for egg in _in_crate:
		if is_instance_valid(egg):
			egg.queue_free()
	_in_crate.clear()

# --- Dropping -----------------------------------------------------------------------------------

func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = CHECK_SECONDS
	if _now() - int(state.get("rolled_at", 0)) >= ROLL_SECONDS:
		state.rolled_at = int(state.rolled_at) + ROLL_SECONDS
		_roll(true)
		_save()
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	var at := to_local(player.global_position)
	var on_farm := FARM.has_point(Vector2(at.x, at.z))
	if not on_farm:
		var egg := _held_egg()
		if egg != null:
			_drop(egg, at)
		if _was_on_farm:
			_empty_crate()
	_was_on_farm = on_farm

## The egg in the hand leaves the farm: it breaks on the ground under the hand, beside the player
## (`at`, the player's town point, if no ground is found).
func _drop(egg: Node3D, at: Vector3) -> void:
	var ray := PhysicsRayQueryParameters3D.create(egg.global_position, egg.global_position + Vector3.DOWN * 4.0, 1)
	var player := get_tree().get_first_node_in_group("player") as CollisionObject3D
	if player != null:
		ray.exclude = [player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty():
		at = to_local(hit.position)
	HandHold.of_player(self).release()
	_forget(egg)
	egg.queue_free()
	_splat(at, egg.golden)
	_toast(UiText.t("toast.egg_dropped"))

## A broken egg on the ground for a moment: white with a yolk, shrinking away.
func _splat(at: Vector3, golden: bool) -> void:
	var splat := Node3D.new()
	splat.name = "Broken egg"
	add_child(splat)
	splat.position = at + Vector3(0, .02, 0)
	for part in [[.2, .008, Color("f7f1e4")], [.08, .016, Color("f4c542") if golden else Color("f2a91c")]]:
		var mesh := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = part[0]
		disc.bottom_radius = part[0]
		disc.height = part[1]
		disc.radial_segments = 14
		mesh.mesh = disc
		var m := StandardMaterial3D.new()
		m.albedo_color = part[2]
		m.roughness = .3
		mesh.material_override = m
		mesh.position.y = part[1] * .5
		splat.add_child(mesh)
	var tween := splat.create_tween()
	tween.tween_interval(2.5)
	tween.tween_property(splat, "scale", Vector3(.01, 1, .01), .5)
	tween.tween_callback(splat.queue_free)

func _toast(line: String) -> void:
	var node: Node = get_parent()
	while node != null and not ("hud" in node and node.get("hud") != null):
		node = node.get_parent()
	if node != null and node.hud.has_method("flash_quest_message"):
		node.hud.flash_quest_message(line)
