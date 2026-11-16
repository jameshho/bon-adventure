extends SceneTree
var failures: Array[String]=[]
func check(ok: bool, message: String):
    if not ok:
        failures.append(message)
        push_error(message)
func _initialize():run.call_deferred()
func clear_at(game,point: Vector3):
    var capsule:=CapsuleShape3D.new()
    capsule.radius=.32
    capsule.height=1.7
    var q:=PhysicsShapeQueryParameters3D.new()
    q.shape=capsule
    q.collide_with_areas=false
    q.transform=Transform3D(Basis.IDENTITY,point)
    var hits=game.get_world_3d().direct_space_state.intersect_shape(q,1)
    check(hits.is_empty(),"Clear passage "+str(game.apartment.to_local(point))+" "+str(hits))
func run():
    root.size = Vector2i(1280, 720)
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.interaction.word_studied.disconnect(game._on_word_studied)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    await physics_frame
    await physics_frame
    for name in ["Curving neighborhood road","Loop road sidewalks"]:
        var surface: MeshInstance3D=game.apartment.get_node(name)
        var arrays=surface.mesh.surface_get_arrays(0)
        var v=arrays[Mesh.ARRAY_VERTEX]
        var idx=arrays[Mesh.ARRAY_INDEX]
        var folded:=0
        for i in range(0,idx.size(),3):
            var cross: Vector3=(v[idx[i+1]]-v[idx[i]]).cross(v[idx[i+2]]-v[idx[i]])
            if cross.y>=-0.000001:folded+=1
        check(folded==0,name+": no inverted, overlapping corner triangles ("+str(folded)+")")
    var car: Node3D=game.apartment.get_node("Vehicles/Police_Car")
    check(car.find_children("*","CSGShape3D",true,false).is_empty(),"Police car uses baked mesh geometry")
    for path in ["Body/SculptedBody","Cab/TintedWindowCabin"]:
        var mesh: MeshInstance3D=car.get_node(path)
        var box: AABB=(car.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
        check(absf(box.get_center().z)<.001,"Police part centered on wheel track: "+path)
        check(box.position.z>=-.86 and box.end.z<=.86,"Police part within body width: "+path)
    var total:=0
    for building in ["School","Hospital"]:
        var base: Node3D=game.apartment.get_node("Buildings/"+building)
        var wing: Node3D=base.get_node("LearningWing")
        # Continuous route from the existing entrance into the rear wing.
        for z in range(-13,13):clear_at(game,base.to_global(Vector3(0,1.2,z)))
        # Existing rear-wall opening and the full new corridor.
        for z in range(-2,24):clear_at(game,wing.to_global(Vector3(0,1.2,z)))
        var rooms:=0
        for room in wing.get_children():
            if not room.has_meta("theme"):continue
            rooms+=1
            # Room doors connect to a clear aisle from the main corridor.
            for step in range(9):
                var x=lerpf(0.0,room.position.x,float(step)/8)
                clear_at(game,wing.to_global(Vector3(x,1.2,room.position.z)))
            var items:=0
            for item in room.get_children():
                if not item is Node3D:continue
                if not item.has_meta("word_key") and item.name!="HospitalBed":continue
                items+=1
                total+=1
                var shape: CollisionShape3D=item.get_node_or_null("Interaction/Shape")
                if shape==null:
                    var shapes=item.find_children("*","CollisionShape3D",true,false)
                    if not shapes.is_empty():shape=shapes[0]
                check(shape!=null,"Learning target exists: "+str(item.name))
                if shape==null:continue
                game.player.global_position = room.to_global(Vector3(0,1.6,0)) - Vector3(0, 1.1, 0)
                game.camera.global_position=room.to_global(Vector3(0,1.6,0))
                game.camera.look_at(shape.global_position)
                game.interaction.pointer_position = root.get_visible_rect().size * 0.5
                var target=game.interaction.aimed_object()
                check(target!=null and (target==item or item.is_ancestor_of(target)),str(room.name)+": reliable target "+str(item.name)+" hit="+str(game.interaction.aimed_hit()))
                game.interaction.selected=null
                game.interaction.interact(false)
                check(game.hud.is_card_visible(),"Popup for "+str(item.name))
                if item.has_meta("word_key"):
                    var key: String=item.get_meta("word_key")
                    check(game.hud.current_spanish==game.vocabulary[key],"Spanish metadata "+key)
            var expected_items: int = {"ScienceLab": 2, "GeographyRoom": 5}.get(str(room.name), 6)
            check(items == expected_items, str(room.name) + ": retained vocabulary displays")
        check(rooms==4,building+": four new themed rooms")
    print("CIVIC EXPANSION: ",total," displays; road folds, car bounds, eight rooms, passages, targets and popups: ",failures.size()," failures")
    game.free()
    quit(0 if failures.is_empty() else 1)
