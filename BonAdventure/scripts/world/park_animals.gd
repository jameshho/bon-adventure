extends Node3D
## Shared wander controller. Positions/speeds/radii are parent-local (town units).
## Decisions and swept obstacle probes run at 10 Hz; translation/turns stay smooth.
const PROFILES := {
    # speed, home radius, usual pause, chance of a longer rest
    "lion":[.65,3.2,3.0,.35], "tiger":[.8,3.2,2.0,.25],
    "elephant":[.45,3.5,3.0,.3], "giraffe":[.55,3.2,3.0,.3],
    "bear":[.5,3.0,3.0,.4], "monkey":[.9,3.0,1.0,.15],
    "snake":[.18,2.0,4.0,.4], "cow":[.4,3.0,4.0,.4],
    "pig":[.55,3.0,2.0,.3], "horse":[.85,3.0,2.5,.25],
    "sheep":[.45,3.0,3.0,.3], "hen":[.55,2.5,1.0,.15],
    "duck":[.4,2.5,2.0,.2], "dog":[.8,1.1,1.5,.2],
    "cat":[.6,1.1,3.0,.4], "rabbit":[.7,1.1,1.5,.25],
    "field mouse":[.75,1.1,1.0,.2],
    "turtle":[.12,1.1,4.0,.4], "fish":[.4,1.8,.6,.05],
    # Clay animals new to the zoo (11 Nov 2026); smaller ranges, the wild-animal lawn is shared.
    "panda":[.35,2.5,4.0,.45], "red panda":[.6,2.0,2.0,.25],
    "gorilla":[.45,2.5,3.0,.35], "deer":[.7,2.5,2.0,.2],
    "kangaroo":[.75,2.5,2.0,.25], "rhinoceros":[.4,2.5,3.0,.35],
    "zebra":[.7,2.5,2.0,.25], "bear cub":[.55,2.0,2.0,.25],
    "flamingo":[.3,1.8,3.0,.3],
    # Clay capybara (17 Nov 2026): slow and mostly resting.
    "capybara":[.3,2.0,4.0,.45],
    # Hen house rooster and chicks (25 Nov 2026, barn step `hen_house_flock`; no word, so their
    # `wander_profile` meta names the profile). Chicks keep close to the hen they follow.
    "rooster":[.5,2.8,1.6,.15], "chick":[.45,1.6,.7,.08]
}
## Procedural gait for the clay animals that have no rig (user, 25 Nov 2026: "have them move
## naturally"): while walking the model child bobs (a hop per stride, `hop` of its height), rolls
## side to side (`roll` radians) and leans into the step (`lean`); `stride` is the ground covered
## per hop in body heights. While idle it now and then pecks (birds: a quick dip, `peck` radians)
## or grazes (a slow dip held a while), and glances about (`glance` radians of head-and-body yaw).
## The root keeps its place, so homes, footprints, picking and feeding are unchanged; rigged
## animals (clay_animator.gd) are left to their animator.
const GAITS := {
    "hen": {"hop": .045, "stride": .55, "roll": .09, "lean": .10, "peck": .55, "peck_time": .32, "graze": false, "glance": .45},
    "rooster": {"hop": .04, "stride": .6, "roll": .08, "lean": .06, "peck": .45, "peck_time": .36, "graze": false, "glance": .5},
    "chick": {"hop": .08, "stride": .45, "roll": .12, "lean": .08, "peck": .6, "peck_time": .26, "graze": false, "glance": .6},
    "sheep": {"hop": .025, "stride": .5, "roll": .035, "lean": .0, "peck": .16, "peck_time": 2.6, "graze": true, "glance": .25},
    "monkey": {"hop": .14, "stride": .8, "roll": .03, "lean": .12, "peck": .0, "peck_time": .0, "graze": false, "glance": .45}
}
## Species display sizes (docs/guides/ANIMAL_SYSTEM.md): visible height in the zoo's town units, or
## length for the aquatic animals, with a fixed minimum world height measured from the snake.
## The zoo animals are saved at these sizes in scenes/town/base.scn (moved here from the
## deleted startup pass world_refinements.gd, 6 Nov 2026); docs/evidence/part2/verify.gd checks them.
## Since 11 Nov 2026 every zoo animal except the tiger, monkey, snake, horse, sheep, hen, cat,
## rabbit, field mouse, turtle and fish is a clay model (base steps lion_clay_roams, clay_animals_roam).
## Do not give every species the same dimensions or rescale the mascot pigs.
const ANIMAL_HEIGHTS = {
    "Lion":1.95, "Tiger":2.1, "Bear":2.2, "Elephant":3.15, "Giraffe":4.4,
    "Monkey":.85, "Snake":.78, "Cow":1.55, "Pig":.95, "Horse":1.9,
    "Sheep":1.05, "Dog":.8, "Cat":.55, "Rabbit":.5, "Field Mouse":.22,
    "Hen":.5, "Duck":.45,
    # Clay animals new to the zoo (11 Nov 2026, base step clay_animals_roam), at their built sizes.
    "Panda":1.67, "Red Panda":.91, "Gorilla":2.3, "Deer":2.0, "Kangaroo":2.3,
    "Rhinoceros":2.4, "Zebra":1.71, "Bear Cub":1.05, "Flamingo":1.4,
    # Clay capybara (17 Nov 2026): the user chose 0.95 shown ("like the pig"); this is under the
    # small-animal minimum, so it is shown at the minimum times DISPLAY_SCALE, about 0.975.
    "Capybara":.76
}
## Every ParkZoo animal is shown this much bigger than its species height above (user, 11 Nov
## 2026: "make everything bigger"; rhinoceros and gorilla raised further and the bear cub made
## smaller through their heights). Applied after the minimum (base step `animals_bigger`).
const DISPLAY_SCALE := 1.25
## Displayed height (town units) of a ParkZoo animal: species height or the minimum, times
## DISPLAY_SCALE. `parent_y_scale` is ParkZoo's world scale (the minimum is in world units).
static func display_height(key: String, parent_y_scale: float) -> float:
    return maxf(ANIMAL_HEIGHTS[key], MIN_ANIMAL_WORLD_HEIGHT / parent_y_scale) * DISPLAY_SCALE

const SMALL_ANIMAL_LENGTHS = {"Turtle":.65, "Fish":.5}
const MIN_ANIMAL_WORLD_HEIGHT := 1.014
## Runtime setup for the animals saved in the town's ParkZoo (see _setup_in_zoo()).
## Later entries win: an animal on a themed zone of the wild-animal lawn keeps to that zone
## (base step `zoo_zones`, 12 Nov 2026; the zone grounds are not named "... lawn", which the
## minimap would label).
const ZOO_LAWNS := ["ANIMALES SALVAJES lawn", "LA GRANJA lawn", "Zone ground SAVANNA", "Zone ground FOREST",
    "Zone ground BAMBOO GROVE", "Zone ground WILDLIFE PLAINS"]
const PARK_GROUND := "PublicGarden/Rolling park ground"
const PARK_GROUND_LIFT := .025 # Mesh vertices sit this far above the lawn relief.
## Height grid of the saved park ground mesh (1-unit grid in town units), shared by all animals
## of one town; built once (~12k vertices, a few ms). Same reading as docs/park_ground.gd.
static var _ground_town := 0
static var _ground_heights := {}
var home := Vector3.ZERO
var clock := 0.0
@export_range(0.0, 10.0) var radius := 0.35
@export_range(0.0, 5.0) var speed := 0.22
## Height (parent-local y) of the ground under a parent-local point; set for slope followers.
var ground: Callable
var habitat := Rect2()
var footprint := 0.3
var state := "idle"
var target := Vector3.ZERO
var pause := 2.0
var rest_chance := .25
var _timer := 0.0
var _probe_timer := 0.0
var _direction := Vector3.ZERO
var _rng := RandomNumberGenerator.new()
var _query := PhysicsShapeQueryParameters3D.new()
var _foot_y := 0.0
var _configured := false
var probe_count := 0
var _to_town := Transform3D.IDENTITY
var _from_town := Transform3D.IDENTITY
var _ground_offset := 0.0
## Feeding (Feeding Time!, 24 Nov 2026; animal_feeding.gd calls offer_food()): the animal walks
## to the food (state "coming"), then eats it, head down and chewing (clay_animator.gd `eat`, or a
## bow of the whole body for an unrigged animal) and hops with joy (state "eating"), or sniffs and
## shakes its head at a food it does not eat ("refusing"). It stays in its habitat and keeps its
## home and picking areas; afterwards it rests and wanders from where it stands. food_done follows.
signal food_done(ate: bool)
const EAT_SECONDS := 3.2
const REFUSE_SECONDS := 2.0
## How much faster than its wander an animal walks to food.
const COME_SPEED := 1.6
var _food := Vector3.ZERO
var _will_eat := true
var _feed_clock := 0.0
var _feed_y := 0.0
var _feed_turn := 0.0
var _animator: Node
var _animator_found := false
## Gait (25 Nov 2026, improvement plan ANIM-02): an animal turns before it walks (speed scales with
## cos of the heading error, none while facing more than 90° away), reaches full speed in about
## ACCEL_SECONDS, slows into its target and turns with frame-rate independent 1-exp(-k·dt) smoothing.
const ACCEL_SECONDS := .25
const TURN_RATE := 5.0
## Arrivals: the animal slows down over the last stretch but never below this share of its speed.
const ARRIVE_MIN := .15
var _pace := 0.0
## Unrigged gait (GAITS): the model child, its rest transform, body height (root-local), phases.
var _gait: Dictionary = {}
var _body: Node3D
var _body_rest := Transform3D.IDENTITY
var _body_h := 1.0
var _stride_phase := 0.0
var _move := 0.0
var _peck_clock := -1.0
var _peck_wait := 1.0
var _glance := 0.0
var _glance_to := 0.0
var _glance_wait := 1.0
## A chick follows a sibling hen (meta "follow": its name): its home moves to the hen at each choice.
var _leader: Node3D

func _ready() -> void:
    home=position
    # Moved every frame in _process: render the set transform, not the physics-tick interpolation,
    # or the motion stutters while physics interpolation is on (ANIM-01, 25 Nov 2026).
    physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
    _rng.seed=hash(str(get_path()))
    _timer=_rng.randf_range(.2,2.5)
    # The deleted startup passes (world_refinements.gd, park_terrain.gd) configured the zoo
    # animals; a saved scene keeps neither script state nor the ground lambda (6 Nov 2026).
    if get_parent() and get_parent().name=="ParkZoo": _setup_in_zoo.call_deferred()

## Replaces configure_animal_movement() and the park_terrain.gd ground callback: habitat from the
## zoo/farm lawn holding the animal, and slope following when its roam touches raised park
## ground (home or ±1.3 × roam radius on the rolling ground, the old pass's rule).
func _setup_in_zoo() -> void:
    if _configured or not is_inside_tree(): return
    var zoo:=get_parent() as Node3D
    var town:=zoo.get_parent() as Node3D
    var enclosure:=Rect2()
    for title in ZOO_LAWNS:
        var lawn:=zoo.get_node_or_null(title) as MeshInstance3D
        if lawn==null: continue
        var box:=lawn.transform*lawn.get_aabb()
        var rect:=Rect2(Vector2(box.position.x,box.position.z),Vector2(box.size.x,box.size.z))
        if rect.has_point(Vector2(position.x,position.z)): enclosure=rect
    var excluded: Array[RID]=[]
    var floor_mesh:=town.get_node_or_null(PARK_GROUND) as MeshInstance3D
    if floor_mesh!=null:
        _to_town=preload("res://scripts/world/modular_town.gd").town_transform(town,zoo)
        _from_town=_to_town.affine_inverse()
        _load_ground(town,floor_mesh)
        var reach: float=PROFILES.get(species(),[0,radius])[1]*1.3
        var origin:=_to_town*position
        if maxf(_park_height(origin),maxf(_park_height(origin+Vector3(reach,0,0)),_park_height(origin-Vector3(reach,0,0))))>.001:
            # Keep the saved clearance above the ground at home (feet, perch or swim depth).
            _ground_offset=origin.y-_park_height(origin)
            ground=_ground_height
            for body in floor_mesh.find_children("*","StaticBody3D",true,false): excluded.append(body.get_rid())
    configure(_visible_bounds(),enclosure,excluded)

func _visible_bounds() -> AABB:
    var result:=AABB()
    var first:=true
    for mesh in find_children("*","MeshInstance3D",true,false):
        if not mesh.visible or mesh.mesh==null: continue
        var box: AABB=global_transform.affine_inverse()*mesh.global_transform*mesh.get_aabb()
        result=box if first else result.merge(box)
        first=false
    return result

static func _load_ground(town: Node3D, floor_mesh: MeshInstance3D) -> void:
    if _ground_town==town.get_instance_id(): return
    _ground_town=town.get_instance_id()
    _ground_heights={}
    var to_town:=preload("res://scripts/world/modular_town.gd").town_transform(town,floor_mesh)
    for surface in floor_mesh.mesh.get_surface_count():
        for v in floor_mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
            var p: Vector3=to_town*v
            _ground_heights[Vector2i(roundi(p.x),roundi(p.z))]=maxf(0.0,p.y-PARK_GROUND_LIFT)

## Rolling ground height at a town point, bilinear between grid vertices; 0 off the mesh
## (level lawn, pads, paths).
static func _park_height(p: Vector3) -> float:
    var x:=floori(p.x)
    var z:=floori(p.z)
    var fx:=p.x-x
    var fz:=p.z-z
    var a: float=_ground_heights.get(Vector2i(x,z),0.0)
    var b: float=_ground_heights.get(Vector2i(x+1,z),0.0)
    var c: float=_ground_heights.get(Vector2i(x,z+1),0.0)
    var d: float=_ground_heights.get(Vector2i(x+1,z+1),0.0)
    return lerpf(lerpf(a,b,fx),lerpf(c,d,fx),fz)

func _ground_height(local: Vector3) -> float:
    var p:=_to_town*local
    p.y=_ground_offset+_park_height(p)
    return (_from_town*p).y

## Profile key: the `wander_profile` meta (animals without a word), else the word.
func species() -> String:
    return str(get_meta("wander_profile",get_meta("word_key",""))).to_lower()

func configure(box: AABB, enclosure: Rect2, ground_bodies: Array[RID]=[]) -> void:
    home=position
    target=home
    var profile: Array=PROFILES.get(species(),[.4,radius,2.0,.25])
    speed=profile[0]
    radius=profile[1]
    pause=profile[2]
    rest_chance=profile[3]
    # A rotation-invariant footprint includes tails and off-centre heads.
    var extent:=Vector2(maxf(absf(box.position.x),absf(box.end.x))*scale.x,maxf(absf(box.position.z),absf(box.end.z))*scale.z)
    footprint=extent.length()+.08
    habitat=enclosure.grow(-footprint-.15) if enclosure.has_area() else Rect2()
    _foot_y=box.position.y*scale.y
    var shape:=CylinderShape3D.new()
    shape.radius=footprint*get_parent().global_basis.get_scale().x
    # Above the lawn/floor; tests low fences, rocks and furniture without ground hits.
    shape.height=.3*get_parent().global_basis.get_scale().y
    _query.shape=shape
    _query.exclude=ground_bodies
    _query.collision_mask=1
    _query.collide_with_areas=false
    _configured=true
    add_to_group("wandering_animals")
    if has_meta("follow") and get_parent()!=null:
        _leader=get_parent().get_node_or_null(str(get_meta("follow"))) as Node3D
    _setup_gait(box)

func _setup_gait(box: AABB) -> void:
    if _body!=null or not GAITS.has(species()): return
    for child in get_children():
        if child is Node3D and not child is CollisionObject3D and not child.find_children("*","Skeleton3D",true,false).size():
            _body=child
            break
    if _body==null: return
    _gait=GAITS[species()]
    _body_rest=_body.transform
    _body_h=maxf(box.size.y,.01)
    _peck_wait=_rng.randf_range(.3,2.0)
    _glance_wait=_rng.randf_range(.5,2.5)

## Moves the model child for the unrigged gait (`moved`: root-local distance walked this frame).
func _gait_pose(dt: float, moved: float) -> void:
    if _body==null or not is_instance_valid(_body): return
    var g:=_gait
    var walking:=state=="walking" and moved>0.0
    _move=move_toward(_move,1.0 if walking else 0.0,dt*6.0)
    _stride_phase=fmod(_stride_phase+moved/(g.stride*_body_h),2.0)
    var swing:=sin(_stride_phase*PI)
    var hop: float=absf(swing)*g.hop*_body_h*_move
    var roll: float=sin(_stride_phase*PI*.5)*g.roll*_move
    var pitch: float=g.lean*_move
    # Idle: pecks or grazing dips, glances about (not while resting).
    if state=="idle" and g.peck>0.0:
        if _peck_clock<0.0:
            _peck_wait-=dt
            if _peck_wait<=0.0: _peck_clock=0.0
        else:
            _peck_clock+=dt
            var t: float=_peck_clock/g.peck_time
            pitch+=(smoothstep(0.0,.15,t)*(1.0-smoothstep(.85,1.0,t)) if g.graze else sin(PI*clampf(t,0.0,1.0)))*g.peck
            if t>=1.0:
                _peck_clock=-1.0
                # Birds peck in quick runs of two or three, then look up a while.
                _peck_wait=_rng.randf_range(.08,.2) if not g.graze and _rng.randf()<.55 else _rng.randf_range(.8,3.0)*(2.5 if g.graze else 1.0)
    else:
        _peck_clock=-1.0
    if state!="resting":
        _glance_wait-=dt
        if _glance_wait<=0.0:
            _glance_to=0.0 if walking or absf(_glance_to)>.01 and _rng.randf()<.5 else _rng.randf_range(-1.0,1.0)*g.glance
            _glance_wait=_rng.randf_range(.6,2.2)
    else:
        _glance_to=0.0
    # Birds snap their heads round; mammals turn smoothly.
    _glance=lerp_angle(_glance,_glance_to,1.0-exp(-(18.0 if g.peck_time<1.0 and g.peck>0.0 else 4.0)*dt))
    # Tip about a point a little ahead of the feet, so a peck dips the head, not the chest, into the grass.
    var pivot:=Vector3(0,0,.18*_body_h)
    var turn:=Basis(Vector3.UP,_glance)*Basis(Vector3.RIGHT,pitch)*Basis(Vector3.BACK,roll)
    _body.transform=Transform3D(turn,pivot-turn*pivot+Vector3(0,hop,0))*_body_rest

func inside(point: Vector3) -> bool:
    if Vector2(point.x-home.x,point.z-home.z).length()>radius: return false
    return not habitat.has_area() or habitat.has_point(Vector2(point.x,point.z))

func _clear_step(destination: Vector3) -> bool:
    if not inside(destination): return false
    var parent:=get_parent() as Node3D
    var start:=position+Vector3(0,_foot_y+.4,0)
    _query.transform=Transform3D(Basis.IDENTITY,parent.to_global(start))
    _query.motion=parent.global_basis*(destination-position)
    probe_count+=1
    var space:=get_world_3d().direct_space_state
    if not space.intersect_shape(_query,1).is_empty(): return false
    if space.cast_motion(_query)[0]<1.0: return false
    # Only nearby peers; never scan meshes or allocate navigation agents per tick.
    for other in get_tree().get_nodes_in_group("wandering_animals"):
        if other==self or other.get_parent()!=parent: continue
        # A chick may tuck in beside the hen it follows (and she beside it).
        if other==_leader or other.get("_leader")==self: continue
        var separation:=Vector2(destination.x-other.position.x,destination.z-other.position.z).length()
        # Two that already overlap (placed close, 25 Nov 2026 hen yard) may still step apart.
        if separation<footprint+other.footprint+.1 and separation<=Vector2(position.x-other.position.x,position.z-other.position.z).length(): return false
    return true

func _choose_target() -> void:
    if _leader!=null and is_instance_valid(_leader):
        home=Vector3(_leader.position.x,home.y,_leader.position.z)
    for attempt in range(8):
        var angle:=_rng.randf_range(-PI,PI)
        var distance:=sqrt(_rng.randf())*radius
        var candidate:=home+Vector3(cos(angle)*distance,0,sin(angle)*distance)
        candidate.y=position.y
        var direction: Vector3=(candidate-position).normalized()
        if candidate.distance_to(position)<.3 or not inside(candidate): continue
        if not _clear_step(position+direction*speed*.2): continue
        target=candidate
        state="walking"
        _direction=direction
        _timer=_rng.randf_range(3.0,8.0)
        return
    _stop(.5) # Bounded retry, so a blocked animal never spins or teleports.

func _stop(duration := -1.0) -> void:
    state="resting" if _rng.randf()<rest_chance else "idle"
    _timer=duration if duration>=0 else _rng.randf_range(pause*.5,pause*1.5)*(3.0 if state=="resting" else 1.0)
    _direction=Vector3.ZERO
    _pace=0.0

## Turns toward `dir` and walks up to `top` along it (no further than `room`); returns the step.
## Speed eases in and out and is held back while the animal still faces away.
func _gait_step(dir: Vector3, top: float, room: float, dt: float) -> Vector3:
    var yaw:=atan2(dir.x,dir.z)
    # Authored animals face +Z. Preserve scale and turn on the shortest arc.
    rotation.y=lerp_angle(rotation.y,yaw,1.0-exp(-TURN_RATE*dt))
    var accel:=top/ACCEL_SECONDS
    var want:=top*clampf(cos(angle_difference(rotation.y,yaw)),0.0,1.0)
    want=minf(want,maxf(sqrt(2.0*accel*room),top*ARRIVE_MIN))
    _pace=move_toward(_pace,want,accel*dt)
    return dir*minf(_pace*dt,room)

## Brings the animal to food at `point` (parent-local, the ground where it lies): it eats it
## when `eats`, else sniffs and refuses. Ignored until the wander is configured.
func offer_food(point: Vector3, eats: bool) -> void:
    if not _configured: return
    _food=point
    _will_eat=eats
    var to:=Vector3(point.x-position.x,0,point.z-position.z)
    # Stop with the mouth over the food: the footprint reaches from the centre to the nose.
    var reach:=footprint*.8
    var stand:=point-to.normalized()*reach if to.length()>reach else position
    stand.y=position.y
    if habitat.has_area():
        stand.x=clampf(stand.x,habitat.position.x,habitat.end.x)
        stand.z=clampf(stand.z,habitat.position.y,habitat.end.y)
    _set_eat(0.0)
    target=stand
    state="coming"
    _timer=8.0
    _direction=Vector3.ZERO

## Whether the animal is busy with food (coming, eating or refusing).
func feeding() -> bool:
    return state in ["coming","eating","refusing"]

func _feed_step(dt: float) -> void:
    if state=="coming":
        var offset:=target-position
        offset.y=0
        if offset.length()<.06 or _timer<=0:
            state="eating" if _will_eat else "refusing"
            _pace=0.0
            _feed_clock=0.0
            _feed_y=position.y
            _feed_turn=rotation.y
            return
        position+=_gait_step(offset.normalized(),speed*COME_SPEED,offset.length(),dt)
        if ground.is_valid(): position.y=ground.call(position)
        return
    _feed_clock+=dt
    var total:=EAT_SECONDS if state=="eating" else REFUSE_SECONDS
    var t:=_feed_clock/total
    var face:=Vector3(_food.x-position.x,0,_food.z-position.z)
    var facing:=atan2(face.x,face.z) if face.length()>.02 else rotation.y
    if state=="eating":
        # Bow in, chew, lift the head, then a happy hop.
        var bow:=smoothstep(0.0,.15,t)*(1.0-smoothstep(.72,.82,t))
        _set_eat(bow)
        rotation.y=lerp_angle(rotation.y,facing,1.0-exp(-TURN_RATE*dt))
        var hop:=sin(PI*clampf((t-.84)/.16,0.0,1.0))
        position.y=_feed_y+hop*maxf(.12,footprint*.18)
    else:
        # Sniff, then shake the head (the whole body turns a little each way) and look away.
        var sniff:=smoothstep(0.0,.2,t)*(1.0-smoothstep(.4,.5,t))*.55
        _set_eat(sniff)
        var shake:=sin(clampf((t-.45)/.4,0.0,1.0)*TAU*2.0)*.28*(1.0-smoothstep(.8,.85,t)) if t>.45 else 0.0
        _feed_turn=lerp_angle(_feed_turn,facing,1.0-exp(-TURN_RATE*dt))
        rotation.y=_feed_turn+shake
    if t>=1.0:
        var ate:=state=="eating"
        position.y=_feed_y
        _set_eat(0.0)
        _stop(pause)
        food_done.emit(ate)

## Head down for eating: the clay rig's animator when there is one, else a bow of the whole animal
## (it faces +Z here, so a bow is a positive turn about its side axis).
func _set_eat(amount: float) -> void:
    if not _animator_found:
        _animator_found=true
        for node in find_children("*","Node",true,false):
            if node.get_script()!=null and "eat" in node and "skeleton" in node:
                _animator=node
                break
    if _animator!=null and is_instance_valid(_animator):
        _animator.set("eat",amount)
    else:
        rotation.x=amount*.22

func _process(delta: float) -> void:
    if not _configured: return
    # Clamp long frames: no tunnelling or catch-up spikes after a pause.
    var dt:=minf(delta,.05)
    clock+=dt
    _timer-=dt
    _probe_timer-=dt
    if feeding():
        if _body!=null: _body.transform=_body_rest
        _feed_step(dt)
        return
    if state!="walking":
        _gait_pose(dt,0.0)
        if _timer<=0 and _probe_timer<=0:
            _probe_timer=.1
            _choose_target()
        return
    var offset:=target-position
    offset.y=0
    if offset.length()<.12 or _timer<=0:
        _stop()
        return
    if _probe_timer<=0:
        _probe_timer=.1
        _direction=offset.normalized()
        if not _clear_step(position+_direction*minf(speed*.2,offset.length())):
            _stop(.4)
            return
    # The arrival radius counts as reached, so the ease-out ends there.
    var next:=position+_gait_step(_direction,speed,offset.length()-.12,dt)
    if not inside(next):
        _stop(.4)
        return
    if _body!=null: _gait_pose(dt,Vector2(next.x-position.x,next.z-position.z).length())
    position=next
    if ground.is_valid(): position.y=ground.call(position)
