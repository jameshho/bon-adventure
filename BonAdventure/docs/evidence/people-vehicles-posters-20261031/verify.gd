extends SceneTree
## People, vehicles, posters and pizza entrance (31 Oct 2026): firefighter, teacher, student
## and old driver removed with their words; lion driver and pilot Awoo added; school bus and
## fire truck parallel to the road; airport time/direction boards now two classroom posters;
## Pizza y Hamburguesas entrance reglazed. One Main load checks everything, then renders views.
## Run with HOME pointing at an empty folder so the learner's saves are untouched:
## HOME=/tmp/vt-home godot --path . --resolution 1200x900 --script res://docs/evidence/people-vehicles-posters-20261031/verify.gd
const FOLDER := "res://docs/evidence/people-vehicles-posters-20261031/after"
const RETIRED_SCENES := ["firefighter","teacher","student","driver"]
const RETIRED_WORDS := ["firefighter","woman","student","child","man","steering wheel"]
const POSTER_WORDS := {
    "time":["today","tomorrow","yesterday","now","later","morning","afternoon","night"],
    "directions":["left","right","straight ahead","near","far"]}
var failures := 0
var town: Node3D
func _initialize(): run.call_deferred()
func check(condition: bool, message: String) -> void:
    if not condition: failures += 1
    print("PASS: " if condition else "FAIL: ", message)

func road_tangent(point: Vector3) -> Vector3:
    var road: Node3D=town.get_node("Curving neighborhood road")
    var points: PackedVector3Array=road.get_meta("reference_road_points")
    var at:=town.to_local(point)
    var q:=Vector2(at.x,at.z)
    var best:=INF
    var tangent:=Vector2.RIGHT
    for i in range(1,points.size()):
        var a:=Vector2(points[i-1].x,points[i-1].z)
        var b:=Vector2(points[i].x,points[i].z)
        var d:=q.distance_to(Geometry2D.get_closest_point_to_segment(q,a,b))
        if d<best and a.distance_to(b)>.01:
            best=d
            tangent=(b-a).normalized()
    return (town.global_basis*Vector3(tangent.x,0,tangent.y)).normalized()

func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    DirAccess.make_dir_recursive_absolute(FOLDER)
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    await physics_frame
    town=game.apartment
    var vocabulary: Dictionary=game.interaction.vocabulary
    # --- Removed people and words.
    for scene in RETIRED_SCENES:
        var left:=0
        for person in town.get_node("People").get_children():
            if person.scene_file_path.ends_with("/"+scene+".tscn"): left+=1
        check(left==0,"no "+scene+" person left")
    for key in RETIRED_WORDS:
        check(not vocabulary.has(key),"word removed: "+key)
        var stray:=0
        for node in town.find_children("*","Node3D",true,false):
            if str(node.get_meta("word_key",""))==key: stray+=1
        check(stray==0,"no object still teaches "+key)
    check(vocabulary.has("pilot") and vocabulary.has("driver"),"pilot and driver words exist")
    # --- Lion driver beside the taxi.
    var taxi: Node3D=town.get_node("Vehicles/Taxi")
    var lion: Node3D=town.get_node_or_null("People/LionDriver")
    check(lion!=null and lion.get_meta("word_key","")=="driver","lion teaches driver")
    if lion:
        check(not lion.find_children("Costume*","",true,false).is_empty(),"lion wears the driver outfit")
        check(lion.global_position.distance_to(taxi.global_position)<5.0,"lion stands beside the taxi ("+str(snappedf(lion.global_position.distance_to(taxi.global_position),.1))+" m)")
    # --- Pilot Awoo in a waiting seat.
    var awoo: Node3D=town.find_child("PilotAwoo",true,false)
    var terminal: Node3D=awoo.get_parent() if awoo else town.get_node("Airport/Terminal")
    check(awoo!=null and awoo.get_meta("word_key","")=="pilot" and not awoo.has_meta("character_name"),"airport Awoo teaches pilot, not a name")
    if awoo:
        check(not awoo.find_children("Costume*","",true,false).is_empty(),"airport Awoo wears the pilot outfit")
        var near_seat:=INF
        for seat in terminal.find_children("Seat*","Node3D",true,false):
            near_seat=minf(near_seat,Vector2(seat.global_position.x-awoo.global_position.x,seat.global_position.z-awoo.global_position.z).length())
        check(near_seat<.6,"airport Awoo sits on a seat ("+str(snappedf(near_seat,.01))+" m off)")
    check(game.interaction.vocabulary.has("dog"),"home Awoo's dog word unchanged")
    # --- Posters.
    var school: Node3D=town.get_node("Buildings/School")
    var posters:=school.find_children("Classroom poster *","",false,false)
    check(posters.size()==2,"two classroom posters")
    var found:={}
    for poster in posters:
        for placard in poster.get_children():
            if not placard.has_meta("word_key"): continue
            found[str(placard.get_meta("word_key"))]=true
            for label in placard.find_children("*","Label3D",false,false):
                var facing: Vector3=school.global_basis.orthonormalized().inverse()*label.global_basis.z
                check(facing.x<-.9,"poster label faces the classroom: "+str(placard.get_meta("word_key"))+"/"+str(label.name))
    for group in POSTER_WORDS:
        for word in POSTER_WORDS[group]: check(found.has(word),"poster has "+word)
    check(town.find_children("TimeBoard*","",true,false).is_empty() and town.find_children("DirectionBoard*","",true,false).is_empty(),"airport boards removed")
    # --- Vehicles parallel to the road.
    var buses:=[town.get_node("Vehicles/Bus"),town.find_child("SchoolBus",true,false),town.get_node("Vehicles/Fire_Truck")]
    for vehicle in buses:
        var along: float=absf(vehicle.travel_forward().dot(road_tangent(vehicle.global_position)))
        check(along>.98,str(vehicle.name)+" parallel to the road (cos "+str(snappedf(along,.001))+")")
        print("INFO: ",vehicle.name," at town-local ",town.to_local(vehicle.global_position))
    # --- Pizza entrance.
    check(town.find_children("Door glass leaf","",true,false).is_empty(),"no opaque door leaf at Pizza y Hamburguesas")
    check(town.find_children("Door glass *","",true,false).size()>=2,"entrance has two glass door leaves")
    print("PEOPLE VEHICLES POSTERS CHECK: ",failures," failures")
    # --- Views.
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.hud.hide()
    game.player.hide()
    var camera:=Camera3D.new()
    game.add_child(camera)
    camera.current=true
    var views:=[]
    var centre:=Vector3.ZERO
    for vehicle in buses: centre+=vehicle.global_position/buses.size()
    var tangent:=road_tangent(centre)
    var to_school:=(school.global_position-centre)
    var side:=tangent.cross(Vector3.UP).normalized()
    if side.dot(to_school)<0: side=-side
    views.append(["curb-street-level",centre-side*13+tangent*-9+Vector3(0,1.8,0),centre+Vector3(0,1.0,0),68.0])
    views.append(["curb-overhead",centre-side*9+Vector3(0,20,0),centre,60.0])
    views.append(["curb-from-school",centre+side*10+tangent*8+Vector3(0,2.2,0),centre,68.0])
    var truck: Node3D=buses[2]
    views.append(["firetruck-overhead",truck.global_position+Vector3(0,16,0)-side*3,truck.global_position,60.0])
    views.append(["firetruck-street",truck.global_position-side*10+tangent*7+Vector3(0,1.8,0),truck.global_position+Vector3(0,1.0,0),66.0])
    views.append(["posters-wide",school.to_global(Vector3(-9,1.7,1.2)),school.to_global(Vector3(0,2.3,1.2)),70.0])
    views.append(["poster-time",school.to_global(Vector3(-3.6,2.3,-1.0)),school.to_global(Vector3(0,2.3,-1.0)),60.0])
    views.append(["poster-directions",school.to_global(Vector3(-3.2,2.3,3.4)),school.to_global(Vector3(0,2.3,3.4)),60.0])
    if lion:
        views.append(["taxi-lion-driver",lion.global_position+lion.global_basis.x*3.0-lion.global_basis.z*1.2+Vector3(0,1.3,0),lion.global_position+Vector3(0,1.0,0),60.0])
    if awoo:
        views.append(["airport-pilot-awoo",terminal.to_global(Vector3(3.8,2.0,-1.2)),awoo.global_position+Vector3(0,.5,0),60.0])
        views.append(["airport-pilot-awoo-from-door",terminal.to_global(Vector3(0,1.7,-8.3)),awoo.global_position+Vector3(0,.5,0),62.0])
    var burger: Node3D=town.get_node("Restaurants/Burger")
    views.append(["pizza-entrance",burger.to_global(Vector3(3,1.8,-15)),burger.to_global(Vector3(3,1.7,-8.1)),60.0])
    views.append(["pizza-facade",burger.to_global(Vector3(-2,2.4,-26)),burger.to_global(Vector3(-2,2.0,-8.1)),66.0])
    for spec in views:
        camera.fov=spec[3]
        camera.global_position=spec[1]
        camera.look_at(spec[2])
        for i in range(5): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(FOLDER+"/"+spec[0]+".png")
    print("PEOPLE VEHICLES POSTERS CAPTURE done")
    quit(0 if failures==0 else 1)
