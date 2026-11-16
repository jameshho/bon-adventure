extends SceneTree
var records: Array=[]
func _initialize(): run.call_deferred()
func collect(node: Node, words: Dictionary, names: Array):
    if node.has_meta("word_key"): words[str(node.get_meta("word_key"))]=true
    if node is Label3D: names.append(node.text)
    for child in node.get_children(): collect(child,words,names)
func run():
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.hud.hide()
    var town=game.apartment
    var camera:=Camera3D.new()
    game.add_child(camera)
    camera.current=true
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    DirAccess.make_dir_recursive_absolute("res://docs/evidence/exterior-audit-20261025/audit-views")
    for facade in town.get_node("Map facades").get_children():
        var source: String=str(facade.get_meta("source_building",""))
        if source=="":
            if facade.name=="HOME": source="RelocatedSites/Home"
            elif facade.name=="GAZEBO": source="RelocatedSites/Gazebo"
            else: continue
        var building=town.get_node(source)
        var bounds: AABB=game.reference_layout.bounds(building)
        var center: Vector3=bounds.get_center()
        var front: Vector3=facade.basis*Vector3.FORWARD
        if facade.name=="HOME": front=facade.basis*Vector3.BACK
        var words: Dictionary={}
        var labels: Array=[]
        collect(building,words,labels)
        records.append({"name":str(facade.name),"path":source,"bounds_town":str(bounds),"word_keys":words.keys(),"labels":labels})
        camera.projection=Camera3D.PROJECTION_ORTHOGONAL
        camera.size=maxf(bounds.size.x,maxf(bounds.size.z,bounds.size.y))*1.6
        camera.global_position=town.to_global(center+front*45+Vector3(0,16,0)+front.cross(Vector3.UP)*8)
        camera.look_at(town.to_global(center))
        for i in range(4): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://docs/evidence/exterior-audit-20261025/audit-views/"+str(facade.name).replace(" / ","-")+".png")
        camera.projection=Camera3D.PROJECTION_PERSPECTIVE
        camera.fov=85
        var depth: float=absf(front.x)*bounds.size.x+absf(front.z)*bounds.size.z
        var eye: Vector3=center+front*(depth/2-1.6)
        eye.y=2.0
        camera.global_position=town.to_global(eye)
        camera.look_at(town.to_global(eye-front*8))
        for i in range(4): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://docs/evidence/exterior-audit-20261025/audit-views/interior-"+str(facade.name).replace(" / ","-")+".png")
    var file=FileAccess.open("res://docs/evidence/exterior-audit-20261025/audit-views/inventory.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(records,"  "))
    quit()
