extends Node3D
class_name ZooGate
## Two physical swinging gate leaves, with a fixed vocabulary selection Area.
## The leaves open away from whoever opens them (user, 23 Nov 2026): from the gate's local -z
## side they swing toward +z, from the +z side toward -z (zoo gate: from inside the zoo they swing
## out, from outside in). Closing keeps the side they opened to.
@export var open_angle_degrees := 100.0
@export var animation_speed := 5.0
var is_open := false
## +1: the leaves swing toward the gate's local +z (the side they always opened to before 23 Nov
## 2026), -1: toward -z.
var swing_side := 1.0
@onready var left_hinge: Node3D = $LeftHinge
@onready var right_hinge: Node3D = $RightHinge

## `from` is the opener's global position (the player); without it the leaves open toward +z.
func toggle_gate(from: Variant = null) -> void:
    is_open = not is_open
    if is_open:
        swing_side = 1.0
        if from is Vector3 and to_local(from).z > 0.0:
            swing_side = -1.0
    set_process(true)

func _process(delta: float) -> void:
    var alpha := 1.0 - exp(-animation_speed * delta)
    var angle := deg_to_rad(open_angle_degrees) * swing_side
    left_hinge.rotation.y = lerp_angle(left_hinge.rotation.y, -angle if is_open else 0.0, alpha)
    var right_target := angle if is_open else 0.0
    right_hinge.rotation.y = lerp_angle(right_hinge.rotation.y, right_target, alpha)
    # Settled: stop until the next toggle_gate() (25 Nov 2026, no per-frame writes at rest).
    if absf(angle_difference(right_hinge.rotation.y, right_target)) < 0.001:
        left_hinge.rotation.y = -right_target
        right_hinge.rotation.y = right_target
        set_process(false)
