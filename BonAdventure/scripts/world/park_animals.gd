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
    "flamingo":[.3,1.8,3.0,.3]
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
    "Rhinoceros":2.4, "Zebra":1.71, "Bear Cub":1.05, "Flamingo":1.4
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

func _ready() -> void:
    home=position
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
        var reach: float=PROFILES.get(str(get_meta("word_key","")).to_lower(),[0,radius])[1]*1.3
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

func configure(box: AABB, enclosure: Rect2, ground_bodies: Array[RID]=[]) -> void:
    home=position
    target=home
    var profile: Array=PROFILES.get(str(get_meta("word_key","")).to_lower(),[.4,radius,2.0,.25])
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
        var separation:=Vector2(destination.x-other.position.x,destination.z-other.position.z).length()
        if separation<footprint+other.footprint+.1: return false
    return true

func _choose_target() -> void:
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
        _timer=_rng.randf_range(3.0,8.0)
        return
    _stop(.5) # Bounded retry, so a blocked animal never spins or teleports.

func _stop(duration := -1.0) -> void:
    state="resting" if _rng.randf()<rest_chance else "idle"
    _timer=duration if duration>=0 else _rng.randf_range(pause*.5,pause*1.5)*(3.0 if state=="resting" else 1.0)
    _direction=Vector3.ZERO

func _process(delta: float) -> void:
    if not _configured: return
    # Clamp long frames: no tunnelling or catch-up spikes after a pause.
    var dt:=minf(delta,.05)
    clock+=dt
    _timer-=dt
    _probe_timer-=dt
    if state!="walking":
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
    var next:=position+_direction*minf(speed*dt,offset.length())
    if not inside(next):
        _stop(.4)
        return
    position=next
    if ground.is_valid(): position.y=ground.call(position)
    # Authored animals face +Z. Preserve scale and turn on the shortest arc.
    rotation.y=lerp_angle(rotation.y,atan2(_direction.x,_direction.z),minf(1,dt*4.0))
