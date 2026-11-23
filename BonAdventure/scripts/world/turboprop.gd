extends "res://scripts/world/driveable_vehicle.gd"
## The small single-engine plane at the airport (docs/guides/aircraft.md). World metres/seconds;
## the model uses town-local units.
##
## Flight model (rewritten 23 Nov 2026, user: the old one wobbled up and down by itself and its
## nose tilt was inconsistent). It is an arcade model, not aerodynamics: the controls set a target
## speed, climb rate and turn rate, and each eases toward its target at a steady rate (first order,
## so nothing overshoots or bobs). The plane travels along its heading at `airspeed` and climbs at
## `flight_velocity.y`; the nose pitch and the bank only show that motion (pitch = the climb angle,
## bank = the turn), they never steer it. Before, a lift / drag / thrust model from
## godot-aircraft-plugin with an autopilot on top ("easy flying"); see git history.
##
## Controls (driveable_vehicle.gd ascend_input(); the ▲ / ▼ Buttons in touch_controls.gd):
##   up / down   climb at CLIMB / sink at SINK; let go: level flight at the current height
##   stick W / S faster (FAST) / slower (SLOW) than CRUISE; on the runway W goes and S brakes
##   stick A / D turn at up to TURN_RATE, banking with it
## On the runway W or up runs to LIFT_OFF speed and lifts off (with W alone it climbs to
## TAKE_OFF_HEIGHT and levels off). Holding down near the ground eases the sink rate to a gentle
## touchdown; on the ground with no input it brakes to a stop.

## The plane is shown at SIZE of the saved model (user, 23 Nov 2026: a smaller plane); BonBon
## sits in it at the same scale.
const SIZE := 0.65
const CRUISE := 17.0
const FAST := 22.0
const SLOW := 12.0
## Descending, it slows to APPROACH (and to SLOW below 10 m).
const APPROACH := 14.0
const LIFT_OFF := 11.0
const CLIMB := 4.0
const SINK := 3.0
## Radians a second with A / D held (a full circle in about 13 s).
const TURN_RATE := .5
const MAX_BANK := .45
const TAKE_OFF_HEIGHT := 15.0
## m/s² speeding up (also the take-off roll), slowing in the air, braking and rolling on the ground.
const ACCEL := 3.0
const DECEL := 2.0
const BRAKE := 4.0
const ROLL_DRAG := 1.5
## 1/s: how quickly the climb rate and the turn rate reach their targets, and the shown pitch / bank.
const EASE := 2.0
const POSE_EASE := 4.0
## Touching down faster than this (m/s down) or banked more than CRASH_BANK is a crash.
const CRASH_SINK := 4.5
const CRASH_BANK := .35

var airspeed := 0.0
var turn_rate := 0.0
## Shown nose-up pitch and right-wing-down bank (radians).
var pitch := 0.0
var bank := 0.0
## Taking off with W alone: the height it climbs to (INF: none).
var climb_to := INF
## For the animation only: the propeller, the control surfaces and the flaps.
var engine_power := 0.0
var flaps := .5
var elevator := 0.0
var aileron := 0.0
var rudder := 0.0
## Exported so a saved town (modular town, 6 Nov 2026) keeps the parts build_model() made.
@export var home_pose := Transform3D.IDENTITY
@export var propeller: Node3D
@export var prop_blur: Node3D
@export var cabin_door: Node3D
@export var left_aileron: Node3D
@export var right_aileron: Node3D
@export var tail_elevator: Node3D
@export var tail_rudder: Node3D
@export var flap_nodes: Array[Node3D] = []
@export var wheels: Array[Node3D] = []
var game
## A crash puts the plane back on the runway after EASY_RECOVER seconds (crashed, crash_clock and
## EASY_RECOVER live in driveable_vehicle.gd since 14 Nov 2026, shared with the helicopter).
## Map edge (user, 14 Nov 2026): the town's reference_map_bounds (town units, the full map's frame)
## grown by MAP_MARGIN world metres. Past it vehicle.map_edge flashes and the plane flies itself
## back (banking toward the town centre; up / down and the speed stick still work),
## a gentle turn rather than a wall. MAP_RESET_MARGIN further out, or unoccupied past the edge, it
## resets to the runway, so it can never be lost outside the map.
const MAP_MARGIN := 150.0
const MAP_RESET_MARGIN := 400.0
## Seconds between repeats of the map-edge message while still outside.
const MAP_EDGE_REPEAT := 6.0
var map_edge_clock := 0.0
var past_edge := false
## Model envelopes (centre, size) used for flight sweeps and the airplane's collision bodies.
const HULLS := [[Vector3(0,1.8,-.3),Vector3(1.9,2.25,7.8)], [Vector3(0,3.2,.1),Vector3(13.6,.28,2.65)], [Vector3(0,2.8,4.5),Vector3(4.2,2.3,1.6)], [Vector3(0,1.95,-4.6),Vector3(3.1,3.1,.3)]]

func _ready() -> void:
    fixed_wing=true
    boarding_duration=2.4
    # Smaller than the model (SIZE), scaled about the wheels before anything reads the pose. Set,
    # not multiplied: a re-baked town saves the plane already at SIZE (23 Nov 2026: base.scn was
    # baked twice and the plane shrank each time).
    scale=Vector3.ONE*SIZE
    home_pose=global_transform
    super._ready()
    landed=true
    # Loaded from a saved town: the model and its bodies are saved, the sweep shapes are not.
    if propeller!=null and flight_hulls.is_empty(): add_flight_hulls()

func add_flight_hulls() -> void:
    for spec in HULLS:
        var shape:=BoxShape3D.new()
        shape.size=spec[1]*global_basis.get_scale().abs()
        flight_hulls.append({"shape":shape,"center":spec[0],"basis":Basis.IDENTITY})

func build_model(scene) -> void:
    game=scene
    var white:=Color("eee8d5")
    var blue:=Color("285c78")
    var dark:=Color("26343d")
    ellipsoid("Lower fuselage",Vector3(0,1.55,.1),Vector3(.96,.64,3.65),white)
    ellipsoid("Tapered tail boom",Vector3(0,1.75,3.3),Vector3(.51,.46,2.4),white)
    ellipsoid("Turbine cowling",Vector3(0,1.95,-3.0),Vector3(.72,.7,1.65),blue)
    part("Belly stripe",Vector3(0,1.12,.2),Vector3(1.58,.14,5.7),blue)
    part("Cabin floor",Vector3(0,1.5,-.8),Vector3(1.8,.12,3.5),white)
    part("Cabin roof",Vector3(0,3.03,-.55),Vector3(1.93,.13,3.7),white)
    for x in [-.92,.92]:
        # The port sill stops at the door jamb; the lower door is the actual skin.
        part("Cabin sill",Vector3(x,1.88,.375 if x<0 else -.6),Vector3(.11,.36,1.55 if x<0 else 3.5),blue)
        for z in [-2.3,-.4,1.2]: part("Window pillar",Vector3(x,2.46,z),Vector3(.1,1.02,.11),white)
        glass("Cabin glass",Vector3(x,2.47,.4),Vector3(.04,.95,1.45))
    glass("Windshield",Vector3(0,2.45,-2.35),Vector3(1.73,1.0,.045))
    glass("Pilot window",Vector3(.94,2.47,-1.35),Vector3(.04,.95,1.75))
    cabin_door=Node3D.new()
    cabin_door.set_script(VehicleDoors.Door)
    cabin_door.open_angle=-1.3
    cabin_door.name="CabinDoor"
    add_child(cabin_door)
    cabin_door.position=Vector3(-.97,1.87,-2.25)
    cabin_door.seal_pose()
    for spec in [[Vector3(0,0,.9),Vector3(.08,.4,1.75)],[Vector3(0,1.1,.9),Vector3(.08,.08,1.75)],[Vector3(0,.55,1.75),Vector3(.08,1.1,.08)]]:
        var trim:=part("Door trim",spec[0],spec[1],white)
        trim.reparent(cabin_door,false)
    var window:=glass("Door window",Vector3(0,.58,.9),Vector3(.045,.9,1.65))
    window.reparent(cabin_door,false)
    part("Boarding step",Vector3(-1.35,.55,-1.1),Vector3(.8,.12,.85),dark)
    part("Pilot seat cushion",Vector3(0,1.58,-1.1),Vector3(.83,.16,.7),dark)
    part("Pilot seat back",Vector3(0,1.99,-.77),Vector3(.83,.85,.12),dark)
    part("Instrument panel",Vector3(0,2.15,-2.02),Vector3(1.65,.42,.16),dark)
    for x in [-.55,-.2,.2,.55]:
        part("Flight display",Vector3(x,2.2,-1.92),Vector3(.23,.18,.025),Color("68bac4"))
    part("Control yoke",Vector3(0,2.03,-1.68),Vector3(.58,.07,.08),dark)
    for x in [-.7,.7]: rod("Turbine exhaust",Vector3(x,1.7,-2.9),Vector3(x*1.15,1.65,-2.5),.18,dark)
    part("Engine air intake",Vector3(0,1.48,-4.1),Vector3(.55,.15,.18),dark)
    var seat:=Marker3D.new()
    seat.name="PilotSeat"
    seat.position=Vector3(0,1.16,-1.2)
    add_child(seat)
    # High wing, visible separate control surfaces, bracing and fixed landing gear.
    for side in [-1,1]:
        var wing:=part("High wing",Vector3(side*3.7,3.16,.1),Vector3(5.8,.16,2.05),white)
        wing.rotation.z=side*.025
        part("Wingtip",Vector3(side*6.65,3.24,.1),Vector3(.22,.2,2.05),blue)
        rod("Wing strut",Vector3(side*.8,1.25,.4),Vector3(side*4.1,3.12,.4),.09,white)
        var flap:=part("Flap",Vector3(side*2.12,3.13,1.32),Vector3(2.1,.1,.38),blue)
        flap_nodes.append(flap)
        var control:=part("Aileron",Vector3(side*4.8,3.18,1.32),Vector3(2.8,.1,.38),blue)
        if side<0: left_aileron=control
        else: right_aileron=control
        rod("Main gear leg",Vector3(side*.65,1.3,.35),Vector3(side*1.35,.35,.55),.13,dark)
        wheel(Vector3(side*1.35,.34,.55),.34)
        var lamp:=ellipsoid("Navigation light",Vector3(side*6.8,3.24,-.65),Vector3(.09,.09,.13),Color("cb493e") if side<0 else Color("4cba77"))
        lamp.set_meta("navigation_light",true)
    rod("Nose gear",Vector3(0,1.4,-3.1),Vector3(0,.28,-3.1),.11,dark)
    wheel(Vector3(0,.28,-3.1),.28)
    part("Horizontal stabilizer",Vector3(0,2.15,4.25),Vector3(4.1,.12,1.1),white)
    tail_elevator=part("Elevator",Vector3(0,2.15,4.95),Vector3(4.1,.1,.3),blue)
    part("Vertical stabilizer",Vector3(0,2.95,4.35),Vector3(.13,1.85,1.3),blue)
    tail_rudder=part("Rudder",Vector3(0,2.95,5.13),Vector3(.11,1.75,.28),white)
    propeller=Node3D.new()
    propeller.name="Propeller"
    propeller.position=Vector3(0,1.95,-4.55)
    add_child(propeller)
    for i in range(2):
        var blade:=part("Propeller blade",Vector3.ZERO,Vector3(.17,2.95,.07),dark)
        blade.reparent(propeller,false)
        blade.rotation.z=i*PI/2
    prop_blur=game.cylinder("Propeller blur",Vector3.ZERO,1.5,.015,Color("b8c9ce"),"",false)
    prop_blur.reparent(propeller,false)
    prop_blur.rotation.x=PI/2
    var blur_material:=StandardMaterial3D.new()
    blur_material.albedo_color=Color(.7,.8,.83,.12)
    blur_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
    blur_material.cull_mode=BaseMaterial3D.CULL_DISABLED
    prop_blur.get_child(0).material_override=blur_material
    prop_blur.hide()
    var spinner:=ellipsoid("Spinner",Vector3(0,1.95,-4.7),Vector3(.29,.29,.45),white)
    spinner.set_meta("engine_count",1)
    # Reuse the vehicle's physical sweep helpers, with model envelopes in world scale.
    add_flight_hulls()
    for spec in HULLS:
        var body:=StaticBody3D.new()
        body.set_meta("root",self)
        body.set_meta("word","airplane")
        add_child(body)
        body.position=spec[0]
        var collider:=CollisionShape3D.new()
        var local_shape:=BoxShape3D.new()
        local_shape.size=spec[1]
        collider.shape=local_shape
        body.add_child(collider)
        collision_exceptions.append(body.get_rid())
    home_pose=global_transform

func part(title: String, p: Vector3, size: Vector3, color: Color) -> Node3D:
    var node: Node3D=game.box(title,p,size,color,"",false)
    node.reparent(self,false)
    return node

func ellipsoid(title: String,p: Vector3,size: Vector3,color: Color) -> Node3D:
    var node: Node3D=game.sphere(title,p,1,color,"",false)
    node.reparent(self,false)
    node.scale=size
    return node

func rod(title: String,a: Vector3,b: Vector3,width: float,color: Color) -> void:
    var node:=part(title,(a+b)/2,Vector3(width,width,a.distance_to(b)),color)
    node.basis=Basis.looking_at(b-a,Vector3.FORWARD if absf((b-a).normalized().y)>.95 else Vector3.UP)

func glass(title: String,p: Vector3,size: Vector3) -> Node3D:
    var node:=part(title,p,size,Color("8dbdc8"))
    var material:=StandardMaterial3D.new()
    material.albedo_color=Color(.46,.75,.83,.16)
    material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
    material.cull_mode=BaseMaterial3D.CULL_DISABLED
    node.get_child(0).material_override=material
    return node

func wheel(p: Vector3,radius: float) -> void:
    var node: Node3D=game.cylinder("Landing wheel",p,radius,.24,Color("283138"),"",false)
    node.reparent(self,false)
    node.rotation.z=PI/2
    wheels.append(node)

func entrance_distance(point: Vector3) -> float:
    return point.distance_to(to_global(Vector3(-1.8,.7,-1.1)))

func animated_boarding() -> bool:
    return true

func begin_boarding() -> void:
    exiting=false
    boarding_progress=0

func boarding_step_point() -> Vector3:
    return to_global(Vector3(-1.4,.63,-1.1))

func boarding_seat() -> Transform3D:
    var seat: Transform3D=get_node("PilotSeat").global_transform
    seat.basis=seat.basis.orthonormalized()
    return seat

# Validate the ground beside the actual cabin entrance.
func preferred_exit_points() -> Array[Vector3]:
    return [to_global(Vector3(-2.1,0,-1.1))]

func boarding_seat_scale() -> float:
    return SIZE

func finish_exit() -> void:
    super.finish_exit()
    engine_power=0

## Left in the air, rolling or crashed: exits without the door sequence and glides down unpowered.
func is_moving() -> bool:
    return crashed or not ground_contact() or current_speed>STOPPED_SPEED

func moving_exit_offset() -> float:
    return 10.5*SIZE

func reset_to_start() -> void:
    super.reset_to_start()
    recover()
    past_edge=false

## The town root holding the map bounds (the plane is parked under it).
func town_root() -> Node3D:
    var node := get_parent()
    while node!=null and not node.has_meta("reference_map_bounds"): node=node.get_parent()
    return node as Node3D

## World metres past the map edge (MAP_MARGIN outside the map bounds); 0 or less inside.
func map_overrun() -> float:
    var town:=town_root()
    if town==null: return -INF
    var bounds: Rect2=town.get_meta("reference_map_bounds")
    var p:=town.to_local(global_position)
    var flat:=Vector2(p.x,p.z)
    return (flat-flat.clamp(bounds.position,bounds.end)).length()*town.global_basis.get_scale().x-MAP_MARGIN

## Turn input (+1 right) that points the nose at the centre of the map.
func edge_turn() -> float:
    var town:=town_root()
    var centre: Vector2=town.get_meta("reference_map_bounds").get_center()
    var home: Vector3=town.to_global(Vector3(centre.x,0,centre.y))-global_position
    home.y=0
    var forward:=travel_forward()
    forward.y=0
    if home.length()<1 or forward.length()<.01: return 0.0
    return clampf(-forward.normalized().signed_angle_to(home.normalized(),Vector3.UP)*1.5,-1,1)

## Crashed: back on the runway after EASY_RECOVER seconds (or at once with R while aboard).
func crash_tick(delta: float) -> void:
    crash_clock+=delta
    if crash_clock>EASY_RECOVER or (occupied and Input.is_physical_key_pressed(KEY_R)): reset_to_start()

func travel_forward() -> Vector3:
    return -global_basis.z.normalized()

func _physics_process(delta: float) -> void:
    if not needs_physics(): return
    if crashed:
        crash_tick(delta)
        return
    var overrun:=map_overrun()
    if not occupied:
        # Left flying (exit while moving): glides down unpowered until it rests; past the edge, reset.
        if coasting and overrun>0:
            reset_to_start()
            return
        fly_step(delta,0,0,0,false)
        if coasting and not crashed: settle(delta,landed and current_speed<.3)
        return
    if overrun>MAP_RESET_MARGIN:
        reset_to_start()
        return
    var turn:=Input.get_action_strength("move_right")-Input.get_action_strength("move_left")
    if overrun>0 and not landed and not boarding_busy():
        # Past the map edge it turns itself back toward town (up / down and speed still work).
        map_edge_clock-=delta
        if not past_edge or map_edge_clock<=0:
            map_edge_reached.emit(self)
            map_edge_clock=MAP_EDGE_REPEAT
        past_edge=true
        turn=edge_turn()
    else:
        past_edge=false
    fly_step(delta,ascend_input(),turn,speed_input())

## Stick forward (+1: faster, take off) or back (-1: slower, brake on the ground).
func speed_input() -> float:
    return Input.get_action_strength("move_forward")-Input.get_action_strength("move_back")

func _process(delta: float) -> void:
    if propeller: propeller.rotation.z=fposmod(propeller.rotation.z+engine_power*95*delta,TAU)
    if prop_blur: prop_blur.visible=engine_power>.3
    if cabin_door: cabin_door.set_open_amount(VehicleDoors.Door.boarding_amount(boarding_progress))
    if left_aileron:
        left_aileron.rotation.x=aileron*.35
        right_aileron.rotation.x=-aileron*.35
        tail_elevator.rotation.x=-elevator*.35
        tail_rudder.rotation.y=rudder*.3
        for flap in flap_nodes: flap.rotation.x=flaps*.5
        var radius:=.34*global_basis.get_scale().x
        for gear in wheels: gear.rotate_object_local(Vector3.UP,current_speed*delta/radius)

## One step of flight. `up` +1 climb / -1 descend, `turn` +1 right, `stick` +1 faster / -1 slower
## (the module header). With `engine` off (nobody aboard) it glides down slowly and brakes once down.
func fly_step(delta: float,up: float,turn: float,stick: float,engine: bool=true) -> void:
    var dt:=clampf(delta,0,1.0/30)
    if crashed:
        crash_tick(delta)
        return
    if boarding_busy():
        advance_boarding(dt)
        return
    if not occupied and not coasting: return
    var heading:=global_basis.orthonormalized().get_euler().y
    var ground:=support()
    var vs:=flight_velocity.y
    landed=not ground.is_empty() and global_position.y-ground.position.y<.25 and vs<=.1
    var target_pitch:=0.0
    var target_bank:=0.0
    var power:=0.0
    if landed:
        var go:=engine and (up>.1 or stick>.1)
        if go: airspeed=move_toward(airspeed,FAST,ACCEL*dt)
        else: airspeed=move_toward(airspeed,0,(BRAKE if engine else ROLL_DRAG)*dt)
        # Steering on the ground (the nose wheel), less when barely rolling.
        heading-=turn*.6*clampf(airspeed/3,0,1)*dt
        turn_rate=0
        vs=0
        climb_to=INF
        power=1.0 if go else (.25 if engine else 0.0)
        if go and airspeed>LIFT_OFF*.8: target_pitch=.1
        if go and airspeed>=LIFT_OFF:
            vs=1.5
            landed=false
            if up<=.1: climb_to=ground.position.y+TAKE_OFF_HEIGHT
        # Rolling, the wheels follow the ground; parked, it stays exactly where it was put.
        if airspeed>0 or vs>0: global_position.y=ground.position.y+.09
        flaps=.5
    else:
        var height:=height_above_ground()
        var target_speed:=CRUISE+stick*(FAST-CRUISE if stick>0 else CRUISE-SLOW)
        var target_vs:=up*(CLIMB if up>0 else SINK)
        if absf(up)>.05: climb_to=INF
        elif climb_to<INF:
            target_vs=clampf((climb_to-global_position.y)*.5,0,CLIMB)
            if global_position.y>climb_to-.3: climb_to=INF
        if not engine:
            target_vs=-SINK*.8
            target_speed=SLOW
        if target_vs<0:
            target_speed=minf(target_speed,APPROACH if height>10 else SLOW)
            # Near the ground the sink eases off: about 0.5 m/s at touchdown.
            if height<10: target_vs=maxf(target_vs,-(.5+height*.25))
        airspeed=move_toward(airspeed,target_speed,(ACCEL if target_speed>airspeed else DECEL)*dt)
        vs=lerpf(vs,target_vs,1-exp(-EASE*dt))
        turn_rate=lerpf(turn_rate,turn*TURN_RATE,1-exp(-EASE*dt))
        heading-=turn_rate*dt
        # Bank for a coordinated turn, kept small close to the ground.
        var bank_limit:=MAX_BANK*clampf((height-1)/8,.15,1)
        target_bank=clampf(atan(airspeed*turn_rate/9.81),-bank_limit,bank_limit)
        target_pitch=atan2(vs,maxf(airspeed,1))+.04
        power=0.0 if not engine else clampf(.55+.35*stick+.3*maxf(up,0)-.3*maxf(-up,0),.2,1)
        flaps=1.0 if target_vs<0 and height<25 else (.5 if airspeed<14 else 0.0)
    pitch=lerpf(pitch,target_pitch,1-exp(-POSE_EASE*dt))
    bank=lerpf(bank,target_bank,1-exp(-POSE_EASE*dt))
    engine_power=move_toward(engine_power,power,dt)
    elevator=move_toward(elevator,clampf(up,-1,1),dt*3)
    aileron=move_toward(aileron,turn,dt*3)
    rudder=move_toward(rudder,turn*.5,dt*3)
    var forward:=Vector3(-sin(heading),0,-cos(heading))
    flight_velocity=forward*airspeed+Vector3.UP*vs
    var next:=global_transform
    next.basis=Basis.from_euler(Vector3(pitch,heading,-bank)).scaled(global_basis.get_scale())
    if can_rotate(next): global_transform=next
    var movement:=flight_velocity*dt
    if not landed and not ground.is_empty() and vs<0 and global_position.y+movement.y<=ground.position.y+.09:
        # Touchdown: gentle is a landing, too fast or banked a crash.
        if vs< -CRASH_SINK or absf(bank)>CRASH_BANK:
            crash()
            return
        movement.y=ground.position.y+.09-global_position.y
        flight_velocity.y=0
        landed=true
    var fraction:=flight_fraction(movement)
    global_position+=movement*fraction
    if fraction<.999:
        if airspeed>5 or absf(vs)>CRASH_SINK:
            crash()
            return
        airspeed=0
        flight_velocity=Vector3.ZERO
    current_speed=flight_velocity.length()
    if global_position.y< -8 or global_position.length()>2500: crash()

## Metres from the wheels down to whatever is below (INF when nothing within 120 m).
func height_above_ground() -> float:
    var ray:=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*.5,global_position-Vector3.UP*120)
    ray.exclude=collision_exceptions
    ray.collision_mask=0xFFFFFEFF # skip figure blockers (layer 256)
    var hit:=get_world_3d().direct_space_state.intersect_ray(ray)
    return INF if hit.is_empty() else global_position.y-hit.position.y

func support() -> Dictionary:
    var ray:=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*.7,global_position-Vector3.UP*2.5)
    ray.exclude=collision_exceptions
    ray.collision_mask=0xFFFFFEFF # skip figure blockers (layer 256)
    var hit:=get_world_3d().direct_space_state.intersect_ray(ray)
    if hit.is_empty() or hit.normal.y<.85: return {}
    return hit

func ground_contact() -> bool:
    var hit:=support()
    return not hit.is_empty() and global_position.y-hit.position.y<.18 and absf(flight_velocity.y)<.5

func crash() -> void:
    super.crash()
    engine_power=0

func recover() -> void:
    global_transform=home_pose
    flight_velocity=Vector3.ZERO
    current_speed=0
    airspeed=0
    turn_rate=0
    pitch=0
    bank=0
    climb_to=INF
    elevator=0
    aileron=0
    rudder=0
    engine_power=0
    crashed=false
    landed=true

func safe_exit(player: CharacterBody3D) -> Dictionary:
    if boarding_progress<1: return {"ok":false,"reason":UiText.t("vehicle.cockpit")}
    # Existing swept-capsule/ground checks select a clear exit beside the cabin; moving, in the
    # air or crashed, BonBon is let out beside the wing (DriveableVehicle.moving_exit()).
    return super.safe_exit(player)

func flight_status() -> String:
    if boarding_progress<1: return UiText.t("vehicle.status_plane_boarding")
    if crashed: return UiText.t("vehicle.status_plane_crash")
    var state:=UiText.t("vehicle.plane_ground" if landed else "vehicle.plane_airborne")
    return UiText.t("vehicle.status_plane",{"speed":int(airspeed*1.944),"height":int(maxf(0,global_position.y-home_pose.origin.y)),"state":state})
