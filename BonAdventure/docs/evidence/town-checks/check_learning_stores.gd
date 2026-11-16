extends SceneTree
# End-to-end regression: saved assets, scene metadata, actual world ray hits,
# popup vocabulary, aisle/entrance capsules, and disjoint interactive bounds.
var failures: Array[String] = []
func check(ok: bool, message: String):
    if not ok:
        failures.append(message)
        push_error(message)
func _initialize(): run.call_deferred()
func run():
    root.size = Vector2i(1280, 720)
    var game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.interaction.word_studied.disconnect(game._on_word_studied)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    var stores = {
        "SportsStore":11,"FurnitureStore":16,"BakeryCafe":23,
        "MarketDisplays":26,"ElectronicsStore/LearningDisplays":16,
        "ClothingStore/LearningDisplays":17}
    await physics_frame
    await physics_frame
    var total := 0
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.32
    capsule.height = 1.75
    for path in stores:
        var store: Node3D = game.apartment.get_node("Buildings/"+path)
        var items: Array[Node3D] = []
        for child in store.get_children():
            if child.get_meta("learning_object",false):items.append(child)
        check(items.size()==stores[path],path+" vocabulary count")
        var boxes: Array[AABB] = []
        for item in items:
            total += 1
            var key: String = item.get_meta("word_key")
            check(game.vocabulary.has(key),"Known word: "+key)
            check(game.vocabulary.has(key) and not item.has_meta("spanish"),"Translation from words.json, no cached copy: "+key)
            check(str(game.vocabulary[key]).begins_with("el ") or str(game.vocabulary[key]).begins_with("la ") or str(game.vocabulary[key]).begins_with("los ") or str(game.vocabulary[key]).begins_with("las "),"Article: "+key)
            var shape: CollisionShape3D = item.get_node("Interaction/Shape")
            var center: Vector3 = item.to_global(shape.position)
            var bounds: Vector3 = shape.shape.size*item.global_basis.get_scale()
            var box: AABB = item.global_transform * AABB(shape.position-shape.shape.size/2,shape.shape.size)
            for old in boxes:check(not box.intersects(old),path+": separated hit boxes "+key)
            boxes.append(box)
            # Aim from the central aisle toward the object's front / side.
            var aisle: Vector3 = store.to_global(Vector3(signf(item.position.x)*1.5,store.to_local(center).y,store.to_local(center).z-0.7))
            game.player.global_position = aisle - Vector3(0, 1.1, 0)
            game.camera.global_position = aisle
            game.camera.look_at(center)
            game.interaction.pointer_position = root.get_visible_rect().size * 0.5
            if game.interaction.aimed_object()!=item:
                print("MISSED ",key," collider: ",game.interaction.aimed_hit())
            game.interaction.pointer_position = root.get_visible_rect().size * 0.5
            check(game.interaction.aimed_object()==item,path+": reliable ray target "+key)
            game.interaction.selected=null
            game.interaction.interact(false)
            check(game.interaction.selected==item and game.hud.is_card_visible(),"Popup: "+key)
            check(game.hud.current_spanish==game.vocabulary[key],"Popup Spanish: "+key)
        # Sample the center aisle from doorway to back; exclude areas.
        var depth := 15.0
        if path=="SportsStore":depth=24
        if path=="FurnitureStore":depth=29
        if path=="BakeryCafe":depth=22
        for z in range(int(-depth/2)-2,int(depth/2)-1):
            var query := PhysicsShapeQueryParameters3D.new()
            query.shape=capsule
            query.transform=Transform3D(Basis.IDENTITY,store.to_global(Vector3(0,1.1,z)))
            query.collide_with_areas=false
            check(game.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty(),path+": clear center aisle "+str(z))
    # Removed geometry must not survive other procedural decoration passes.
    for child in game.apartment.get_children():
        check(not str(child.name).to_lower().contains("church") and not str(child.name).to_lower().contains("clinic annex"),"Removed old building: "+str(child.name))
    # Every reusable asset must load and respond through the real controller.
    var catalog: Dictionary = preload("res://scripts/learning/word_data.gd").load_all().catalog
    for key in catalog:
        var asset: Node3D = load("res://scenes/props/vocabulary/"+key.replace(" ","_")+".tscn").instantiate()
        game.apartment.add_child(asset)
        asset.position=Vector3(0,12,-240)
        await physics_frame
        await physics_frame
        var shape: CollisionShape3D = asset.get_node("Interaction/Shape")
        var center: Vector3 = shape.global_position
        game.player.global_position = center+Vector3(0,0,3) - Vector3(0, 1.1, 0)
        game.camera.global_position=center+Vector3(0,0,3)
        game.camera.look_at(center)
        game.interaction.pointer_position = root.get_visible_rect().size * 0.5
        check(game.interaction.aimed_object()==asset,"Reusable asset ray: "+key)
        game.interaction.selected=null
        game.interaction.interact(false)
        check(game.hud.current_spanish==game.vocabulary[key],"Reusable asset translation: "+key)
        asset.free()
    check(game.doors.size()==8,"Restored all eight saved doors and drawers")
    for object in game.doors:
        game.doors[object]["open"]=true
    game._process(0.15)
    for object in game.doors:
        var state: Dictionary=game.doors[object]
        if state.type=="hinge":check(absf(object.rotation.y)>0.1,"Saved hinge animation")
        else:check(object.position.distance_to(state.origin)>0.1,"Saved drawer animation")
    print("REUSABLE ASSETS: ",catalog.size()," loaded and ray-tested; 8 saved door animations checked")
    print("LEARNING STORES: ",total," objects, ",failures.size()," failures")
    game.free()
    quit(0 if failures.is_empty() else 1)
