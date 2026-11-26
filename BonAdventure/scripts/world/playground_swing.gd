extends Node3D
## Playground swing (1 Nov 2026): a damped pendulum hanging from the beam; it turns
## about its local X axis and positive angles carry the seat forward (local −Z).
## The seating controller seats the player, feeds W / S kicks and asks it to stop;
## while seated, the rider is placed here every physics frame so it never lags the seat.
## Units are world metres (the playground holder cancels the Apartment's 1.3 scale).
## Playground pace: gravity is scaled so the 3.2 m ropes swing back and forth in ~2.6 s
## (real gravity gives 3.6 s). The kick, damping and settle values below are scaled with
## it (by PACE or √PACE), so height builds over the same number of swings as before.
const PACE := 1.9
const GRAVITY := 9.8*PACE
## Peak angular acceleration of one kick (rad/s²) and its duration (s). A kick in the
## direction the swing is already moving adds energy; against it, it takes energy away.
const KICK := 1.25*PACE
const KICK_TIME := 0.44
## Linear (bearing) and quadratic (air) damping: an unpushed swing settles in ~30 s.
const DAMPING := 0.165
const DRAG := 0.04
## Extra damping while the rider drags their feet to get off.
const BRAKE := 3.3
## Kicks that would lift the seat higher fade out approaching this angle (rad).
const MAX_ANGLE := 1.2
## Below these the swing counts as stopped (safe to get off).
const SETTLED_ANGLE := 0.07
const SETTLED_SPEED := 0.28

@export var length := 3.2
var angle := 0.0
var speed := 0.0
var kick_direction := 0.0
var kick_left := 0.0
var braking := false
@export var seat: Node3D
var rider: Node3D
## Main scene (found in _ready, since the swing is loaded from the saved town),
## for Space → seating.stand().
var game
## The rider's root in seat space (matches seating_controller's seat offset).
var rider_offset := Vector3.ZERO

func _ready() -> void:
    if game == null:
        game = preload("res://scripts/world/modular_town.gd").find_game(self)

func kick(direction: float) -> void:
    if braking: return
    kick_direction = direction
    kick_left = KICK_TIME

func settled() -> bool:
    return absf(angle) < SETTLED_ANGLE and absf(speed) < SETTLED_SPEED

## Seat transform with the swing hanging straight down (boarding target).
func rest_seat_transform() -> Transform3D:
    return get_parent().global_transform*Transform3D(Basis.IDENTITY,position)*seat.transform

func board(player: Node3D, offset: Vector3) -> void:
    rider = player
    rider_offset = offset
    braking = false
    kick_left = 0.0

func release() -> void:
    rider = null
    braking = false
    kick_left = 0.0

func _physics_process(delta: float) -> void:
    var push := 0.0
    if kick_left > 0.0:
        # Half-sine envelope: the push starts and ends smoothly, so the motion never jerks.
        push = KICK*kick_direction*sin(PI*(1.0-kick_left/KICK_TIME))
        if signf(push) == signf(angle):
            push *= 1.0-smoothstep(MAX_ANGLE*0.7,MAX_ANGLE,absf(angle))
        kick_left -= delta
    if is_instance_valid(rider) and rider.sit_transition and rider.seated:
        # Boarding: the player steadies the seat while settling onto it.
        speed = 0.0
        angle = lerpf(angle,0.0,1.0-exp(-10.0*delta))
    else:
        var damping := DAMPING+(BRAKE if braking else 0.0)
        # Semi-implicit Euler is stable at 60 Hz for this light damping.
        speed += (-GRAVITY/length*sin(angle)-damping*speed-DRAG*speed*absf(speed)+push)*delta
        angle += speed*delta
        if not is_instance_valid(rider) and absf(angle) < 0.0005 and absf(speed) < 0.0005:
            angle = 0.0
            speed = 0.0
    rotation.x = angle
    carry()

func carry() -> void:
    if rider == null: return
    if not is_instance_valid(rider) or not rider.seated:
        release()
        return
    if rider.sit_transition: return
    var frame := seat.global_transform.orthonormalized()
    rider.global_transform = Transform3D(frame.basis,frame*rider_offset)
    # Camera: follow halfway between the rider and the swing's rest point, so the view
    # conveys the arc without being thrown about.
    var rest := rest_seat_transform()*rider_offset
    rider.seat_focus = rider.global_position.lerp(rest,0.5)+Vector3.UP*2.1

## Space or the touch Jump button (the "jump" action) gets off like E: the seating controller brakes the swing, then stands the rider.
func _unhandled_input(event: InputEvent) -> void:
    if rider == null or not is_instance_valid(rider) or not rider.seated or rider.sit_transition or not rider.controls_enabled: return
    if event.is_action_pressed("jump"):
        get_viewport().set_input_as_handled()
        game.seating.stand()
