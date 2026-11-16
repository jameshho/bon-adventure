extends Node3D
## Steerable swan boat (28 October 2026). One root gathers a boat's loose public-garden
## parts (built by the deleted public_garden.gd pass, now saved in the base) so it moves as a whole. Town-local units; local -Z
## is the bow, the swan is the stern. The deck, bench seats and swan are standable; each
## bench is a seat, and the saddle on the swan's back steers: W/S pedal, A/D turn.
## The hull stays inside the lagoon outline and stops at anything solid.
const BENCHES := [-2.9,-1.85,-.8,.25,1.3]
const SADDLE := Vector3(0,1.62,3.7)
const TOP_SPEED := 3.2
const REVERSE_SPEED := 1.4
const ACCELERATION := 1.6
const DRAG := 1.0
const TURN_RATE := .7
var game
var town: Node3D
@export var lagoon := PackedVector2Array()
@export var saddle: Node3D
var speed := 0.0
@export var body: AnimatableBody3D
var exclusions: Array[RID] = []
## Swept volumes for motion checks: hull with rails, then the raised swan neck and head.
var hulls := [
    {"center":Vector3(0,.3,0),"size":Vector3(2.15,1.2,7.4)},
    {"center":Vector3(0,2.0,2.9),"size":Vector3(1.0,2.0,1.6)}
]

## Loaded from a saved town (modular town, 6 Nov 2026): setup() ran when it was baked, so only
## the references a scene cannot keep are found again.
func _ready() -> void:
    if game == null:
        game = preload("res://scripts/world/modular_town.gd").find_game(self)
        # setup() made the boat a direct child of the town; Main's `apartment` is not set yet here.
        town = get_parent()
    if exclusions.is_empty():
        for descendant in find_children("*","CollisionObject3D",true,false): exclusions.append(descendant.get_rid())

func setup(scene, hull: Node3D, parts: Array[Node3D]) -> void:
    game=scene
    town=game.apartment
    lagoon=town.get_node("PublicGarden").get_meta("lagoon_polygon",PackedVector2Array())
    name="Swan boat"
    var stern: Node3D=hull
    for part in parts:
        if String(part.name).begins_with("Swan boat feathered body"): stern=part
    var bow:=town.to_local(hull.global_position)-town.to_local(stern.global_position)
    town.add_child(self,true)
    position=town.to_local(hull.global_position)
    rotation.y=atan2(-bow.x,-bow.z)
    for part in parts: part.reparent(self,true)
    body=AnimatableBody3D.new()
    body.name="Swan boat collision"
    # The root moves the boat; a synced body would lag behind and drift from its parent.
    body.sync_to_physics=false
    add_child(body)
    shape("Deck",Vector3(0,.25,0),Vector3(2.15,.12,7.4))
    shape("Swan",Vector3(0,.9,2.95),Vector3(1.4,1.2,1.9))
    for child in get_children():
        if not String(child.name).begins_with("Swan boat wooden seat"): continue
        var z: float=child.position.z
        shape("Bench",Vector3(0,.5,z),Vector3(1.9,.18,.42))
        child.name="Swan boat bench seat"
        child.set_meta("sit_enabled",true)
        child.set_meta("sit_root",self)
        child.set_meta("sit_label","swan boat bench")
        child.set_meta("sit_position",Vector3(0,.04,0))
        child.set_meta("sit_forward",Vector3(0,0,-1))
        child.set_meta("stand_position",Vector3(0,.04,0))
    # Red saddle on the swan's back, behind the neck, where the pilot steers.
    saddle=game.box("Swan pilot saddle",Vector3.ZERO,Vector3(.55,.08,.5),Color("b84d40"),"",false)
    saddle.reparent(self,false)
    saddle.position=SADDLE
    saddle.set_meta("sit_enabled",true)
    saddle.set_meta("sit_root",self)
    saddle.set_meta("sit_label","the swan to steer")
    saddle.set_meta("sit_position",Vector3(0,.04,0))
    saddle.set_meta("sit_forward",Vector3(0,0,-1))
    # Reachable from the last bench and the dock beside the swan, where it wins over benches.
    saddle.set_meta("sit_reach",Vector2(3.4,2.4))
    saddle.set_meta("sit_priority",3.3)
    saddle.set_meta("stand_position",Vector3(0,.59,BENCHES.back())-SADDLE)
    saddle.set_meta("sit_message","seats.swan_message")
    for descendant in find_children("*","CollisionObject3D",true,false): exclusions.append(descendant.get_rid())

func shape(title: String,center: Vector3,size: Vector3) -> void:
    var collision:=CollisionShape3D.new()
    collision.name=title
    var box:=BoxShape3D.new()
    box.size=size
    collision.shape=box
    collision.position=center
    body.add_child(collision)

func piloted() -> bool:
    if game.seating==null or not game.player.seated or game.player.sit_transition or not game.player.controls_enabled: return false
    return game.seating.current.get("node")==saddle

func _physics_process(delta: float) -> void:
    var gas:=0.0
    var steering:=0.0
    if piloted():
        gas=Input.get_action_strength("move_forward")-Input.get_action_strength("move_back")
        steering=Input.get_action_strength("move_left")-Input.get_action_strength("move_right")
    drive(delta,gas,steering)

func drive(delta: float,gas: float,steering: float) -> void:
    var target:=gas*(TOP_SPEED if gas>0 else REVERSE_SPEED)
    speed=move_toward(speed,target,(ACCELERATION if gas!=0 else DRAG)*delta)
    if absf(speed)<.01 and steering==0: return
    # Paddle boats turn slowly even when almost still; reversing swaps the turn.
    var turn:=steering*TURN_RATE*delta*clampf(.35+absf(speed)/TOP_SPEED,0,1)*(-1.0 if speed< -.01 else 1.0)
    if turn!=0:
        var turned:=transform.rotated_local(Vector3.UP,turn)
        if afloat(turned) and clear_at(turned): transform=turned
    if absf(speed)>=.01:
        var motion:=-transform.basis.z*speed*delta
        var fraction:=sweep(motion)
        var next:=Transform3D(transform.basis,position+motion*fraction)
        if fraction<1.0 or not afloat(next): speed=0
        if afloat(next): transform=next
    if game.seating!=null: game.seating.follow_seat()

func query(hull: Dictionary,pose: Transform3D) -> PhysicsShapeQueryParameters3D:
    var world:=town.global_transform*pose
    var box:=BoxShape3D.new()
    box.size=hull.size*world.basis.get_scale().abs()
    var result:=PhysicsShapeQueryParameters3D.new()
    result.shape=box
    result.transform=Transform3D(world.basis.orthonormalized(),world*hull.center)
    var ignored: Array[RID]=exclusions.duplicate()
    ignored.append(game.player.get_rid())
    result.exclude=ignored
    result.margin=.02
    return result

## Fraction of a town-local motion the boat can travel before touching something solid.
func sweep(motion: Vector3) -> float:
    var fraction:=1.0
    var space:=get_world_3d().direct_space_state
    var world_motion:=town.global_basis*motion
    for hull in hulls:
        var probe:=query(hull,transform)
        probe.motion=world_motion
        var safe: float=space.cast_motion(probe)[0]
        if safe<1.0: safe=maxf(0,safe-.01/maxf(world_motion.length(),.00001))
        fraction=minf(fraction,safe)
    return fraction

func clear_at(pose: Transform3D) -> bool:
    for hull in hulls:
        if not get_world_3d().direct_space_state.intersect_shape(query(hull,pose),1).is_empty(): return false
    return true

## The deck's corners all stay over the lagoon.
func afloat(pose: Transform3D) -> bool:
    if lagoon.is_empty(): return true
    for corner in [Vector3(-1.08,0,-3.7),Vector3(1.08,0,-3.7),Vector3(-1.08,0,3.7),Vector3(1.08,0,3.7)]:
        var p: Vector3=pose*corner
        if not Geometry2D.is_point_in_polygon(Vector2(p.x,p.z),lagoon): return false
    return true
