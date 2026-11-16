extends Node3D
## Seesaw beam (1 Nov 2026). It always rests tilted: one end on the mulch, the other up.
## When the player sits on the high end, the beam turns about the axle (local Z) until
## that end is down, carrying the rider; sitting on the low end moves nothing. Getting
## off leaves the tilt as it is. The board's collider is a child, so it turns with it.
## A physics-processing node, so render_culling keeps the beam out of static batches.
## (Own file since 6 Nov 2026, so the modular town can save it; was playground.gd's inner class.)
## Rest tilt (rad): the low end's bumper touches the ground. rotation.z = +TILT puts
## the −X end down; −TILT puts the +X end down.
const TILT := .15
## Seconds for the high end to come down.
const DURATION := 1.1
var game
var rider: Node3D
var rider_end
var rider_offset := Vector3.ZERO
var waiting := false
var from_tilt := 0.0
var to_tilt := 0.0
var progress := 1.0

func _ready() -> void:
    if game == null:
        game = preload("res://scripts/world/modular_town.gd").find_game(self)

func board(end,player: Node3D,offset: Vector3) -> void:
    rider=player
    rider_end=end
    rider_offset=offset
    # Start once the rider has settled onto the seat (it stays put meanwhile).
    waiting=true

func release(end) -> void:
    if end!=rider_end: return
    # The beam finishes any motion already under way, then keeps its tilt.
    rider=null
    rider_end=null
    waiting=false

func _physics_process(delta: float) -> void:
    if rider!=null and (not is_instance_valid(rider) or not rider.seated):
        release(rider_end)
    if waiting and rider!=null and not rider.sit_transition:
        waiting=false
        var target: float=-rider_end.side*TILT
        if absf(rotation.z-target)>.005:
            from_tilt=rotation.z
            to_tilt=target
            progress=0.0
    if progress<1.0:
        progress=minf(1.0,progress+delta/DURATION)
        rotation.z=lerpf(from_tilt,to_tilt,smoothstep(0.0,1.0,progress))
    if rider!=null and not rider.sit_transition:
        # Keep the rider upright; only their position follows the seat.
        rider.global_position=rider_end.seat.global_transform.orthonormalized()*rider_offset

func _unhandled_input(event: InputEvent) -> void:
    if rider==null or not is_instance_valid(rider) or not rider.seated or rider.sit_transition or not rider.controls_enabled: return
    if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_SPACE:
        get_viewport().set_input_as_handled()
        game.seating.stand()
