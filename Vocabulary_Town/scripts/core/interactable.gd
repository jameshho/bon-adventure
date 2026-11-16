extends Node
## One interactive thing in the world (12 Nov 2026, user): a small data-only child, always named
## "Interactable", of the object the player can use (a faucet, a door, a seat, a car, an NPC).
## Guide: docs/guides/ARCHITECTURE_REVIEW_PART1.md#interaction-system.
##
## The interaction controller (interaction_controller.gd) runs one focus pass about 10 times a
## second over the "interactables" group and picks ONE focus target: the one under the pointer
## (or screen centre) if it is in range, else the best one in range in front of the player. That
## target gets the "E" badge; E, a click or a tap on it or its badge calls activate().
##
## Load it with preload("res://scripts/core/interactable.gd") (no class_name: headless checks
## need no class-cache refresh).
##
## The owner (the parent) provides the behaviour:
##   use()            what activation does (unless `on_use` is set);
##   can_interact()   optional: true = available, false = not a candidate now (no badge),
##                    a String = focusable, but activation flashes that line instead of use().
## Code that has no owner script (seats, NPC talkers, vehicles) sets the Callables instead.
## An interactable is not a word: clicking it never opens a word card (user, 12 Nov 2026).

const SELF := preload("res://scripts/core/interactable.gd")
const GROUP := "interactables"
const NODE_NAME := "Interactable"

enum Kind { USE, TALK, DRIVE, BOARD, OPEN, SIT, PLAY }
## Discovery icon while the player is within discover_distance and the object is not focused:
## CALL = the gold "!" (an NPC offering a game, while `calling`), STATION = a subtle dot over a
## pastime station (electrical boxes, radar consoles). Nothing for faucets, doors, seats or vehicles.
enum Indicator { NONE, CALL, STATION }

@export var kind: Kind = Kind.USE
## Horizontal metres from the player to point() within which E works.
@export var prompt_distance := 2.2
## Metres within which the discovery icon shows (Indicator STATION; CALL follows `calling`).
@export var discover_distance := 15.0
## Only when roughly in front of the player (not needed when aimed at).
@export var needs_facing := true
## Only when the pointer / screen centre is on it (small controls next to bigger ones).
@export var needs_aim := false
## Added to the score: higher wins among several in range.
@export var priority := 0.0
@export var indicator: Indicator = Indicator.NONE
## Where the E badge sits, in the owner's local space (above an NPC's head, on a handle).
@export var badge_offset := Vector3(0, 0.3, 0)

## Off: never a candidate (warehouse goods while the player carries something).
var enabled := true
## For Indicator CALL: whether the "!" shows (npc_presence.gd sets it from the host's rule).
var calling := false
## Optional replacements for the owner's methods (code-made interactables).
var on_use: Callable
var on_check: Callable
## (from: Vector3) -> Vector3: the world point the distance is measured to (default: the badge point).
var on_point: Callable
## () -> Vector3: the badge's world point (default: owner.to_global(badge_offset)).
var on_badge: Callable
## (from: Vector3, heading: Vector2) -> float: replaces the controller's facing term in the score
## (seats keep their own "behind the chair" rule, seating_controller.gd).
var on_rank: Callable

func _enter_tree() -> void:
	add_to_group(GROUP)

func target() -> Node3D:
	return get_parent() as Node3D

func badge_point() -> Vector3:
	if on_badge.is_valid():
		return on_badge.call()
	return target().to_global(badge_offset)

func point(from: Vector3) -> Vector3:
	if on_point.is_valid():
		return on_point.call(from)
	return badge_point()

## true, false or a reason line (see the header).
func check() -> Variant:
	if not enabled:
		return false
	if on_check.is_valid():
		return on_check.call()
	var owner_node := target()
	if owner_node != null and owner_node.has_method("can_interact"):
		return owner_node.can_interact()
	return true

## Runs the action. Returns "" or the reason line it did not run (the caller shows it).
func activate() -> String:
	var state: Variant = check()
	if state is String and state != "":
		return state
	if state is bool and not state:
		return ""
	if on_use.is_valid():
		on_use.call()
	elif target() != null and target().has_method("use"):
		target().use()
	return ""

## Adds (or returns the existing) Interactable child of `owner_node`; `settings` sets any export
## or Callable by name, e.g. {"kind": Interactable.Kind.TALK, "prompt_distance": 3.0}.
static func attach(owner_node: Node, settings: Dictionary = {}) -> Node:
	var existing := on(owner_node)
	var item: Node = existing if existing != null else SELF.new()
	item.name = NODE_NAME
	for key in settings:
		item.set(key, settings[key])
	if existing == null:
		owner_node.add_child(item)
	return item

## The Interactable on `node` itself (or null).
static func on(node: Node) -> Node:
	if node == null:
		return null
	var item := node.get_node_or_null(NODE_NAME)
	return item if item != null and item.get_script() == SELF else null

## The nearest Interactable on `node` or an ancestor below `stop` (a collider -> its object).
static func find_for(node: Node, stop: Node = null) -> Node:
	while node != null and node != stop:
		var item := on(node)
		if item != null:
			return item
		node = node.get_parent()
	return null
