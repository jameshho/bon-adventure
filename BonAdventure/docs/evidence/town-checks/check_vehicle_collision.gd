extends SceneTree
const InteractableScript = preload("res://scripts/core/interactable.gd")
var failures: Array[String] = []
func check(ok: bool, message: String):
    if not ok:
        failures.append(message)
        push_error(message)
func _initialize(): run.call_deferred()
func run():
    root.size = Vector2i(1280, 720)
    var test_world := Node3D.new()
    root.add_child(test_world)
    var player = load("res://scenes/player/bonbon_player.tscn").instantiate()
    test_world.add_child(player)
    player.set_physics_process(false)
    var vehicles := []
    for key in ["car","truck","taxi","bus","police_car","ambulance","fire_truck","motorcycle"]:
        var vehicle = load("res://scenes/props/vehicles/"+key+".tscn").instantiate()
        vehicle.position.x = vehicles.size()*20
        test_world.add_child(vehicle)
        vehicles.append(vehicle)
    await physics_frame
    await physics_frame
    for vehicle in vehicles:
        var body = vehicle.get_node("StudyArea")
        check(body is StaticBody3D,"Solid vehicle: "+str(vehicle.name))
        var shape = body.get_node("StudyShape")
        var half: Vector3 = shape.shape.size/2
        for direction in [Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD,Vector3.BACK]:
            var distance: float = half.x+2 if absf(direction.x)>.5 else half.z+2
            var origin: Vector3 = vehicle.global_position+direction*distance+Vector3(0,.05,0)
            var hit := KinematicCollision3D.new()
            var blocked: bool = player.test_move(Transform3D(Basis.IDENTITY,origin),-direction*distance*2,hit)
            check(blocked and hit.get_collider()==body,"Player blocked from "+str(direction)+" by "+str(vehicle.name))
        var origin: Vector3 = vehicle.global_position+Vector3(-half.x-1.2,.05,half.z+1.2)
        check(not player.test_move(Transform3D(Basis.IDENTITY,origin),Vector3((half.x+1.2)*2,0,0)),"Can walk around "+str(vehicle.name))
    test_world.free()
    var game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    await physics_frame
    await physics_frame
    var town_count := 0
    for vehicle in game.apartment.get_node("Vehicles").get_children():
        var body = vehicle.get_node_or_null("StudyArea")
        if body == null: continue
        town_count += 1
        check(body is StaticBody3D,"Saved town instance solid: "+str(vehicle.name))
        var shape = body.get_node("StudyShape")
        var target: Vector3 = shape.global_position
        # Since 12 Nov 2026 a vehicle is an Interactable (click or tap = board/drive, like E), not
        # a word: aimed_object() skips it by design. So aim as a player does: stand on the ground
        # beside the cabin, point at the vehicle (camera above it, clear of neighbours) and the
        # click must find this vehicle's Interactable, in range.
        var side: Vector3 = vehicle.global_basis.z.normalized()
        game.player.global_position = Vector3(target.x, vehicle.global_position.y, target.z) + side*(shape.shape.size.z/2+1.0)
        game.camera.global_position = target+Vector3(0,4.5,0)
        game.camera.look_at(target,Vector3.FORWARD)
        game.interaction.pointer_position = root.get_visible_rect().size * 0.5
        var item = game.interaction.aimed_interactable()
        check(item!=null and item==InteractableScript.on(vehicle) and game.interaction._clickable(item),"Vehicle remains selectable: "+str(vehicle.name)+" (aimed "+(str(item.get_parent().name) if item!=null else "nothing")+")")
        check(game.interaction.aimed_object()==null,"Vehicle opens no word card (it is an interactable): "+str(vehicle.name))
    check(town_count>=8,"All vehicle types present in active town")
    print("VEHICLES: ",failures.size()," failures; 8 types block player from four directions, allow walking around, and ",town_count," saved instances remain selectable (their Interactable is aimed and clickable)")
    game.queue_free()
    await process_frame
    quit(0 if failures.is_empty() else 1)
