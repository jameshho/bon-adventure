extends Node3D
class_name ZooGate
## Two physical swinging gate leaves, with a fixed vocabulary selection Area.
@export var open_angle_degrees := 100.0
@export var animation_speed := 5.0
var is_open := false
@onready var left_hinge: Node3D = $LeftHinge
@onready var right_hinge: Node3D = $RightHinge

func toggle_gate() -> void:
    is_open = not is_open

func _process(delta: float) -> void:
    var alpha := 1.0 - exp(-animation_speed * delta)
    left_hinge.rotation.y = lerp_angle(left_hinge.rotation.y, deg_to_rad(-open_angle_degrees) if is_open else 0.0, alpha)
    right_hinge.rotation.y = lerp_angle(right_hinge.rotation.y, deg_to_rad(open_angle_degrees) if is_open else 0.0, alpha)
