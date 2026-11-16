extends Node
## One seat's hook for seating_controller.gd, which drives it through the same calls
## as a playground swing (board / release / settled / kick / rest_seat_transform).
## A Node (child of its seat) since 6 Nov 2026, so the modular town can save it.
@export var beam: Node3D
@export var seat: Node3D
@export var side := 1.0
var braking := false

func kick(_direction: float) -> void:
    pass

func settled() -> bool:
    return true

## The player sits on the seat where it is now, high or low.
func rest_seat_transform() -> Transform3D:
    return seat.global_transform

func board(player: Node3D,offset: Vector3) -> void:
    beam.board(self,player,offset)

func release() -> void:
    beam.release(self)
