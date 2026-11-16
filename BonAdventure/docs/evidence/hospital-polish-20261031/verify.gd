extends SceneTree
## Hospital polish (31 Oct 2026): floor word removed, sheep doctor, anatomy model and its
## words, outdoor display gone, landing rails/strips/floor text gone, roof door, big-object
## hover rule. One Main load checks everything, then renders the views. Isolated copy, 1200x900.
## godot --path . --resolution 1200x900 --script res://docs/evidence/hospital-polish-20261031/verify.gd
const ANATOMY_WORDS := ["head","face","hair","eye","ear","nose","mouth","tooth","tongue","neck",
    "shoulder","arm","hand","finger","chest","back","belly","leg","knee","foot","toe",
    "lungs","stomach","liver","small intestine","large intestine","heart","brain"]
const ROOF_Y := 16.925
var failures := 0
func _initialize(): run.call_deferred()
func check(condition: bool, message: String) -> void:
    if not condition: failures += 1
    print("PASS: " if condition else "FAIL: ", message)

func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    var folder := "res://docs/evidence/hospital-polish-20261031/after"
    DirAccess.make_dir_recursive_absolute(folder)
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    await physics_frame
    var town: Node3D=game.apartment
    var hospital: Node3D=town.get_node("Buildings/Hospital")
    var vocabulary: Dictionary=game.interaction.vocabulary
    for level in [1,2,3]:
        check(not hospital.get_node("Floor"+str(level)).has_meta("word_key"),"Floor"+str(level)+" is not a vocabulary word")
    var outline_inside := false
    for node in town.get_children():
        if node is MeshInstance3D and str(node.name).begins_with("Building outline"):
            var c: Vector3=hospital.to_local(node.global_position)
            if absf(c.x-9.08)<.2 and c.z>-1.5 and c.z<11.5: outline_inside=true
    check(not outline_inside,"no runtime eave across the open floor-3 annex")
    var posts_inside := false
    for post in hospital.find_children("AnnexCorner*","",false,false):
        if post.position.x<10: posts_inside=true
    check(not posts_inside,"no annex corner post inside the stairwell")
    for name in ["LandingRail","LandingPost","HallRunner","LandingInset","LiftLobbyInset","AscentArrow"]:
        check(hospital.find_children(name+"*","",true,false).is_empty(),"no "+name+" left in the hospital")
    check(not town.has_node("People/Doctor") and not town.has_node("People/Nurse"),"old Doctor and Nurse removed")
    var doctor: Node3D=hospital.get_node_or_null("Floor1/Room1/SheepDoctor")
    check(doctor!=null and doctor.get_meta("word_key","")=="doctor","sheep doctor teaches doctor")
    if doctor:
        check(not doctor.find_children("Costume*","",true,false).is_empty(),"sheep doctor wears the outfit")
        var ledge: Node3D=hospital.get_node("Floor1/Room1/DeskLedge")
        var top := -INF
        for m in doctor.find_children("*","MeshInstance3D",true,false):
            if m.is_visible_in_tree(): top=maxf(top,(m.global_transform*m.get_aabb()).end.y)
        check(top>ledge.global_position.y+.4,"sheep doctor's head clears the reception ledge")
        var at: Vector3=hospital.get_node("Floor1/Room1").to_local(doctor.global_position)
        check(Vector2(at.x+.35,at.z-2.75).length()<.05,"sheep doctor stands behind the counter (room-local "+str(at)+")")
    var sites: Node3D=town.get_node("RelocatedSites/Hospital")
    for name in ["Anatomy teaching base","Heart","brain","skull","Organ model","Torso"]:
        check(not sites.has_node(name),"outdoor anatomy piece removed: "+name)
    check(not town.get_node("People/Teacher").find_children("Torso","",true,false).is_empty(),"people keep their torsos")
    var model: Node3D=hospital.get_node("Floor2/AnatomyModel")
    var parts := {}
    for node in model.get_children():
        if node.has_meta("word_key"): parts[str(node.get_meta("word_key"))]=node
    for word in ANATOMY_WORDS:
        check(vocabulary.has(word),"dictionary has "+word)
        check(parts.has(word) and not parts[word].find_children("*","CollisionObject3D",true,false).is_empty(),"anatomy model teaches "+word)
    check(str(game.interaction.vocabulary_aliases.get("lung",""))=="lungs","old lung saves resolve to lungs")
    # Front-on picks land on the intended part, small parts included.
    var space: PhysicsDirectSpaceState3D=root.get_world_3d().direct_space_state
    var front: Vector3=-model.global_basis.z.normalized()
    for word in ["eye","nose","tooth","tongue","mouth","finger","toe","knee","lungs","heart","liver","small intestine","chest","belly","hair","brain","face"]:
        if not parts.has(word): continue
        var shape: CollisionShape3D=parts[word].find_children("*","CollisionShape3D",true,false)[0]
        var target: Vector3=shape.global_position
        # The face's centre is the nose; aim between the eyes instead.
        if word=="face": target+=model.global_basis.y*.09
        var ray:=PhysicsRayQueryParameters3D.create(target+front*2.0,target-front*.5)
        ray.collide_with_areas=true
        var hit: Dictionary=space.intersect_ray(ray)
        var got: Node3D=null if hit.is_empty() else game.interaction.vocabulary_target(hit["collider"],town)
        check(got==parts[word],"front click on "+word+" picks "+word+(" (got "+str(got.get_meta("word_key","")) +")" if got and got!=parts[word] else ""))
    # Hover glow: none on buildings or the road, still on a normal object.
    var exterior: Node3D=null
    for node in hospital.find_children("*","Node3D",true,false):
        if node.has_meta("exterior_word"): exterior=node; break
    if exterior: check(not game.interaction.glows(exterior),"no hover glow on the hospital exterior")
    var road: Node3D=town.get_node_or_null("Curving neighborhood road")
    if road: check(not game.interaction.glows(road),"no hover glow on the road")
    check(game.interaction.glows(parts["heart"]),"hover glow kept on small objects (heart)")
    print("HOSPITAL POLISH CHECK: ",failures," failures")
    # Views.
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.hud.hide()
    game.player.hide()
    var lift=hospital.get_node("Elevator")
    if lift.hint: lift.hint.hide()
    hospital.get_node("Azotea/RoofDoor").rotation.y=-1.6
    var camera:=Camera3D.new()
    game.add_child(camera)
    camera.current=true
    camera.fov=68.0
    for spec in [
        ["reception-sheep-doctor",Vector3(5.5,1.8,-11.4),Vector3(5.3,1.5,-5.6)],
        ["waiting-room",Vector3(-2.6,2.7,-11.7),Vector3(-6.4,.7,-6.2)],
        ["waiting-room-from-door",Vector3(-1.2,1.9,-8.35),Vector3(-8,1.0,-8.6)],
        ["floor2-lounge-anatomy",Vector3(1.6,5.6+2.2,5.2),Vector3(8.5,5.6+1.0,10.4)],
        ["anatomy-closeup",Vector3(5.6,5.6+1.5,8.6),Vector3(5.6,5.6+1.2,11.3)],
        ["floor2-hall-tiles",Vector3(0,5.6+1.9,-11.2),Vector3(0,5.6,4)],
        ["floor3-stair-foot",Vector3(1.0,11.2+2.2,.3),Vector3(8,11.2+2.4,.3)],
        ["roof-door-open",Vector3(10.6,ROOF_Y+2.0,.4),Vector3(15.6,ROOF_Y+1.1,2.1)]
    ]:
        camera.global_position=hospital.to_global(spec[1])
        camera.look_at(hospital.to_global(spec[2]))
        for i in range(5): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder+"/"+spec[0]+".png")
    print("HOSPITAL POLISH CAPTURE done")
    quit(0 if failures==0 else 1)
