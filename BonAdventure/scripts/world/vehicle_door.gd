extends Node3D
## A permanent model assembly. All geometry stays visible in the closed pose.
@export var open_angle := -1.15
@export var slide := Vector3.ZERO
var closed_transform := Transform3D.IDENTITY

func _ready() -> void:
    seal_pose()

func seal_pose() -> void:
    closed_transform = transform

func set_open_amount(amount: float) -> void:
    transform = closed_transform * Transform3D(Basis(Vector3.UP, open_angle * amount), slide * amount)

static func boarding_amount(progress: float) -> float:
    return smoothstep(.28, .44, progress) * (1.0 - smoothstep(.82, .98, progress))
