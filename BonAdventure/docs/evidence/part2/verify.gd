extends SceneTree
const Animals = preload("res://scripts/world/park_animals.gd")
## Driveway width (the deleted startup pass world_refinements.gd built every refined drive at it).
const DRIVE_WIDTH := 6.8
var failures: Array[String]=[]
var checks := 0
func _initialize(): run.call_deferred()
func check(ok: bool, label: String):
    checks+=1
    if not ok: failures.append(label); print("FAIL: ",label)
func visible_bounds(node: Node3D) -> AABB:
    var result := AABB()
    var first := true
    for mesh in node.find_children("*","MeshInstance3D",true,false):
        if not mesh.visible or mesh.mesh==null: continue
        var box: AABB=node.global_transform.affine_inverse()*mesh.global_transform*mesh.get_aabb()
        result=box if first else result.merge(box)
        first=false
    return result
func closest_road(town: Node3D, point: Vector3) -> Vector3:
    var points: PackedVector3Array=town.get_node("Curving neighborhood road").get_meta("reference_road_points")
    var nearest := points[0]
    var distance := INF
    for i in range(1,points.size()):
        var p := Geometry3D.get_closest_point_to_segment(point,points[i-1],points[i])
        if p.distance_squared_to(point)<distance:
            distance=p.distance_squared_to(point)
            nearest=p
    return nearest
func run():
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    var town: Node3D=game.apartment
    # Group, habitat and pedestal comparisons with the old saved world (town_public_garden.tscn)
    # and the refinement-pass idempotence check were retired with the old passes on 6 Nov 2026.
    var animal_sizes := {}
    for key in Animals.ANIMAL_HEIGHTS:
        var node: Node3D=town.get_node("ParkZoo/"+key)
        node.set_process(false)
        var box: AABB=visible_bounds(node)
        var size: Vector3=box.size*node.scale
        animal_sizes[key]=size
        check(absf(size.y-Animals.display_height(key,node.get_parent().global_basis.get_scale().y))<.015,"animal display height "+key)
        check(node.home.is_equal_approx(node.position),"wandering origin "+key)
        check(node.has_node("VocabularyArea"),"animal picking area "+key)
        game.interaction.show_word(node)
        check(game.hud.current_spanish==game.vocabulary[node.get_meta("word_key")],"animal study card "+key)
    check(animal_sizes.Tiger.y/animal_sizes.Giraffe.y>.38 and animal_sizes.Tiger.y/animal_sizes.Giraffe.y<.5,"tiger/giraffe proportions")
    check(animal_sizes["Field Mouse"].y<=animal_sizes.Cat.y+.001 and animal_sizes.Cat.y<animal_sizes.Dog.y,"minimum-height small species stay below dog")
    var snake: Node3D=town.get_node("ParkZoo/Snake")
    var body: MeshInstance3D=snake.get_node("ContinuousBodyMesh")
    check(body.visible and body.mesh.get_surface_count()==1,"snake continuous single-surface mesh")
    check(not snake.get_node("BodyContinuousCoil").visible,"broken CSG disabled")
    var statue: Node3D=town.get_node("WashingtonStatue")
    check(statue.has_node("SculptureDetails/Tricorn brim"),"rider silhouette detail")
    # Leave parked vehicles registered, but move them off the route for clearance queries.
    for vehicle in game.driveable_vehicles:
        vehicle.set_physics_process(false)
        vehicle.position.y+=100
    for i in range(3): await physics_frame
    for key in Animals.ANIMAL_HEIGHTS.keys()+Animals.SMALL_ANIMAL_LENGTHS.keys():
        var node: Node3D=town.get_node("ParkZoo/"+key)
        node.set_process(false)
        var area: Area3D=node.get_node("VocabularyArea")
        var collision: CollisionShape3D=area.get_child(0)
        var center: Vector3=collision.global_position
        var ray:=PhysicsRayQueryParameters3D.create(center+Vector3(0,2,4),center)
        ray.collide_with_areas=true
        var hit=game.get_world_3d().direct_space_state.intersect_ray(ray)
        check(not hit.is_empty() and hit.collider==area,"physics ray picks scaled animal "+key)
        if Animals.SMALL_ANIMAL_LENGTHS.has(key):
            var size: Vector3=visible_bounds(node).size*node.scale
            check(maxf(size.x,size.z)>=Animals.SMALL_ANIMAL_LENGTHS[key]-.015 and size.y*node.get_parent().global_basis.get_scale().y>=Animals.MIN_ANIMAL_WORLD_HEIGHT-.001,"aquatic length target and minimum height "+key)
    var shape:=BoxShape3D.new()
    shape.size=Vector3(2.0,1.5,2.0)
    var query:=PhysicsShapeQueryParameters3D.new()
    query.shape=shape
    query.collide_with_areas=false
    # The Home drive ends at the overhead garage door (f103d0a), closed until E opens it: not an obstacle.
    var garage: Node3D=game.garage_door()
    if garage!=null:
        query.exclude=garage.find_children("*","StaticBody3D",true,false).map(func(body): return body.get_rid())
    var road_samples := 0
    for node in town.get_children():
        if not node.get_meta("refined_driveway",false): continue
        var points: PackedVector3Array=node.get_meta("reference_road_points")
        check(node.get_meta("reference_road_width")==DRIVE_WIDTH,"consistent driveway width "+node.name)
        var nearest: Vector3=closest_road(town,points[0])
        if node.name=="Airport parking drive" and not town.get_meta("compact_layout",false):
            check(absf(points[0].z-249)<.01,"airport drive meets access road")
        # Since 28 Oct 2026 drives start at the road edge (5.1 from the centreline,
        # tucked just inside the 5.4 half-width), not on the centreline.
        else: check(nearest.distance_to(points[0])>4.8 and nearest.distance_to(points[0])<5.4,"drive meets loop at its edge "+node.name)
        for i in range(0,points.size(),3):
            # A 2m-wide vehicle volume fits center and both sides, above the road surface.
            for offset in [-1.4,0.0,1.4]:
                var tangent: Vector3=(points[mini(i+1,points.size()-1)]-points[maxi(0,i-1)]).normalized()
                var side:=Vector3(-tangent.z,0,tangent.x)
                var p: Vector3=points[i]+side*offset
                query.transform=Transform3D(Basis.IDENTITY,town.to_global(p+Vector3(0,.85,0)))
                var hits=game.get_world_3d().direct_space_state.intersect_shape(query,4)
                check(hits.is_empty(),"drive clearance "+node.name+" "+str(i)+" "+str(offset)+(" "+str(hits[0].collider.get_path()) if not hits.is_empty() else ""))
                road_samples+=1
                var ray:=PhysicsRayQueryParameters3D.create(town.to_global(p+Vector3.UP*2),town.to_global(p-Vector3.UP))
                var hit=game.get_world_3d().direct_space_state.intersect_ray(ray)
                var supported: bool=not hit.is_empty() and hit.collider.get_parent()==node
                if not hit.is_empty() and hit.collider.get_parent().get_meta("blueprint_parking",false): supported=true
                if not hit.is_empty() and hit.collider.get_parent().get_parent().get_meta("blueprint_parking",false): supported=true
                if not hit.is_empty() and node.name=="Home garage drive" and town.get_node("RelocatedSites/Home/Garage floor").is_ancestor_of(hit.collider): supported=true
                if i==0 and not hit.is_empty():
                    var joined: Node=town.get_node("Airport access road" if node.name=="Airport parking drive" and not town.get_meta("compact_layout",false) else "Curving neighborhood road")
                    supported=supported or hit.collider.get_parent()==joined
                check(supported,"drive collision surface and picking root "+node.name)
    check(road_samples>100,"enough route samples")
    var loop: Node3D=town.get_node("Curving neighborhood road")
    var loop_points: PackedVector3Array=loop.get_meta("reference_road_points")
    var loop_samples:=0
    for i in range(0,loop_points.size()-1,4):
        var tangent: Vector3=(loop_points[i+1]-loop_points[i]).normalized()
        var side:=Vector3(-tangent.z,0,tangent.x)
        for offset in [-2.7,0.0,2.7]:
            var p: Vector3=loop_points[i]+side*offset
            query.transform=Transform3D(Basis.IDENTITY,town.to_global(p+Vector3(0,1,0)))
            var hits=game.get_world_3d().direct_space_state.intersect_shape(query,4)
            check(hits.is_empty(),"loop lane clearance "+str(i)+" "+str(offset)+(" "+str(hits[0].collider.get_path()) if not hits.is_empty() else ""))
            loop_samples+=1
    check(loop_points[0].is_equal_approx(loop_points[-1]),"blueprint loop closed")
    var parking_count:=0
    for node in town.get_children():
        if node.get_meta("blueprint_parking",false): parking_count+=1
    # 14 since the warehouse added its front lot (5 Nov 2026; FINAL_VERIFICATION P2 stale count).
    check(parking_count==14,"fourteen marked front parking areas")
    print("BLUEPRINT: ",loop_samples," loop clearance samples; ",parking_count," parking areas")
    print("PART 2: ",checks," checks; ",failures.size()," failures; ",road_samples," road samples")
    quit(0 if failures.is_empty() else 1)
