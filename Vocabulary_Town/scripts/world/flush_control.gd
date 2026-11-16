@tool
extends Node3D
## A toilet's flush lever or push plate (9 Nov 2026, user; built by bath_fixtures.gd under the
## toilet's Model as "Flush"). It is its own interactable (needs aim, 12 Nov 2026): E, a click or
## a tap on it flushes, while E on the bowl (the toilet's seat interactable) sits.
const Interactable := preload("res://scripts/core/interactable.gd")
const InteractIcons := preload("res://scripts/ui/interact_badge.gd")

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	Interactable.attach(self, {
		"prompt_distance": 1.9,
		"needs_aim": true,
		"priority": 0.5,
		"badge_offset": InteractIcons.local_center(self, Vector3.ZERO),
	})

## E, a click or a tap: flushes the toilet this control belongs to. Returns true when a flush starts.
func use() -> bool:
	var toilet := get_parent().get_parent()
	return toilet != null and toilet.has_method("flush") and toilet.flush()
