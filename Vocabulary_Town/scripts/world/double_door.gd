@tool
extends "res://scripts/world/door.gd"
## Reusable double door (user request, 13 Nov 2026; docs/guides/DOORS.md): scenes/props/double_door.tscn.
## The same door as door.gd split into two leaves, hinged on both jambs, meeting in the middle
## with no gap. Both swing to the same side (swing_to_front) and open and close together: each
## leaf's `door_partners` meta names the other, and DoorAnimator.toggle() moves both.
## `leaf_name` gets " left" / " right" (seen from the front). `hinge` is not used.


func _build_leaves() -> void:
	var half := width * 0.5
	var made: Array[Node3D] = []
	for dir in [1.0, -1.0]:
		var leaf := _leaf_node(leaf_name + (" left" if dir > 0.0 else " right"), Vector3(-dir * half, 0, 0))
		_leaf_parts(leaf, 0.0, dir * half, false)
		var angle: float = open_angle * -dir * (1.0 if swing_to_front else -1.0)
		_register(leaf, {"open": false, "type": "hinge", "angle": angle})
		made.append(leaf)
	if interactive:
		made[0].set_meta("door_partners", [made[1]])
		made[1].set_meta("door_partners", [made[0]])
