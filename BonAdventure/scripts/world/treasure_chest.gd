extends Node3D
## The treasure chest at the end of a Mystery Doors game (scripts/buildings/mystery.gd builds it
## in the endless hall; scripts/learning/mystery_session.gd opens it and flies the diamond back
## to Madame Luna). An interactable (12 Nov 2026): E, a click or a tap calls use(). Hidden (and
## so never focused) until the session shows it.
const MysteryDoor := preload("res://scripts/world/mystery_door.gd")
const Interactable := preload("res://scripts/core/interactable.gd")
const InteractIcons := preload("res://scripts/ui/interact_badge.gd")

func _ready() -> void:
	Interactable.attach(self, {
		"kind": Interactable.Kind.OPEN,
		"prompt_distance": 2.6,
		"badge_offset": InteractIcons.local_center(self) + Vector3(0, 0.55, 0),
	})

func use() -> void:
	var session := get_tree().get_first_node_in_group(MysteryDoor.GROUP)
	if session != null and session.has_method("chest_used"):
		session.chest_used(self)
