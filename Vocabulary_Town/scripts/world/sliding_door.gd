@tool
extends "res://scripts/world/door.gd"
## Reusable sliding door (user request, 13 Nov 2026; docs/guides/DOORS.md): scenes/props/sliding_door.tscn.
## The same door as door.gd (one leaf, bar pulls instead of levers) that slides sideways along the
## wall: with face_offset 0 it is a pocket door that slides into the wall through the jamb;
## otherwise it hangs on that side of the wall (offset along Z) under a track. A closing leaf that
## would hit the player opens again ("safe_slide", door_animator.gd). `hinge`, `swing_to_front`
## and `open_angle` are not used.

enum Slide { TO_LEFT, TO_RIGHT }

## Direction it opens, seen from the front (+Z).
@export var slide := Slide.TO_LEFT:
	set(value):
		slide = value
		_rebuild()
## How far it slides; 0 = the opening's width plus a little (fully clear).
@export var slide_distance := 0.0:
	set(value):
		slide_distance = maxf(value, 0.0)
		_rebuild()
## 0: pocket door in the wall; otherwise the leaf hangs this far in front (+) or behind (-).
@export var face_offset := 0.0:
	set(value):
		face_offset = value
		_rebuild()


func _build_leaves() -> void:
	var leaf := _leaf_node(leaf_name, Vector3(0, 0, face_offset))
	var dir := -1.0 if slide == Slide.TO_LEFT else 1.0
	# A hung leaf overlaps the frame on both sides; a pocket leaf fills the opening exactly.
	var half := width * 0.5 + (frame_width if face_offset != 0.0 and frame_visible else 0.0)
	# The handle sits near the trailing edge (the one that closes against the jamb).
	_leaf_parts(leaf, dir * half, -dir * half, true)
	var distance := slide_distance if slide_distance > 0.0 else width + 0.05
	_register(leaf, {"open": false, "type": "slide", "origin": leaf.position, "shift": Vector3(dir * distance, 0, 0), "safe_slide": true})
	if face_offset != 0.0 and frame_visible:
		# Track over the opening and the run the leaf slides along.
		_box(self, "Door track", Vector3(dir * distance * 0.5, height + frame_width + 0.04, face_offset), Vector3(half * 2.0 + distance + 0.1, 0.08, 0.08), material(frame_color), "frame")
