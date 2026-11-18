extends SceneTree
# Run after opening the Godot project, for engine/physics/interaction regression:
# godot --headless --path . --script res://docs/evidence/town-checks/check_zoo_vehicles.gd
var problems: Array[String] = []
var assertions := 0

func verify(condition: bool, label: String) -> void:
    assertions += 1
    if not condition:
        problems.append(label)
        push_error("FAIL: " + label)

func _initialize() -> void:
    call_deferred("run_test")

func run_test() -> void:
    var packed: PackedScene = load("res://scenes/main.tscn")
    verify(packed != null, "main scene loads")
    if packed == null:
        quit(1)
        return
    var game: Variant = packed.instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.interaction.word_studied.disconnect(game._on_word_studied)
    for vehicle in game.driveable_vehicles:
        vehicle.set_physics_process(false)
        vehicle.set_process(false)
    await physics_frame
    await physics_frame
    var gate: ZooGate = game.zoo_gate
    verify(gate != null, "zoo gate registered")
    verify(game.apartment.get_node_or_null("ParkZoo/Giraffe") != null, "giraffe remains")
    verify(game.apartment.get_node_or_null("ParkZoo/Shelter roof2") == null, "odd roof removed")
    verify(game.vocabulary.get("helicopter") == "el helicóptero", "helicopter translation")
    verify(game.vocabulary.get("gate") == "el portón", "gate translation")
    verify(game.vocabulary_categories.get("helicopter") == "Vehicles", "helicopter category")
    # 14 Nov 2026: +31 parked cars and motorcycles (base step parked_vehicles), 43 in all.
    # 9 Nov 2026: 12 = helicopter + eleven road vehicles (the eight Vehicles/ incl. the scooter
    # Motorcycle, school bus, Subi, warehouse delivery truck); the turboprop is fixed-wing.
    # 18 Nov 2026: the 15 red parked motorcycles removed (base step tutorial_lot_clear), 28 in all.
    verify(game.driveable_vehicles.filter(func(v): return not v.fixed_wing).size() == 28, "helicopter and all twenty-seven road vehicles (incl. Subi, school bus, warehouse truck, 16 parked cars) registered")
    if gate != null:
        game.player.global_position = gate.global_position + Vector3(0, 0.8, -2.5)
        verify(game.interaction.activate_focus() and game.interaction.focus.get_parent() == gate, "E action can operate zoo gate")
        gate._process(0.55)
        verify(gate.is_open, "gate opens")
        verify(absf(gate.get_node("LeftHinge").rotation.y) > 0.35, "left gate leaf swings")
        verify(absf(gate.get_node("RightHinge").rotation.y) > 0.35, "right gate leaf swings")
        verify(game.interaction.activate_focus() and game.interaction.focus.get_parent() == gate, "E closes zoo gate")
        gate._process(0.7)
        verify(not gate.is_open, "gate closes")
        verify(absf(gate.get_node("LeftHinge").rotation.y) < 0.35, "gate returns to doorway")
        game.interaction.show_word(gate)
        verify(game.hud.current_spanish == "el portón", "gate vocabulary popup")
    var helicopter: DriveableVehicle = game.apartment.get_node_or_null("Buildings/Hospital/HospitalHelipad/Helicopter") as DriveableVehicle
    verify(helicopter != null, "helicopter scene loads on hospital")
    if helicopter != null:
        game.interaction.show_word(helicopter)
        verify(game.hud.current_spanish == "el helicóptero", "helicopter study popup")
        game.player.global_position = helicopter.global_position + Vector3(0, 1.2, 0)
        verify(game.toggle_vehicle(), "E boards helicopter")
        verify(game.player.riding_vehicle == helicopter, "player occupies helicopter")
        game.player.toggle_noclip()
        verify(not game.player.noclip_enabled and game.player.collision_layer == 0 and game.player.collision_mask == 0, "noclip cannot restore player collisions while seated")
        var original: Transform3D = helicopter.global_transform
        for i in range(240): helicopter.drive_step(1.0/60, 0.0, 0.0, 1.0,true)
        verify(helicopter.global_position.y > original.origin.y+1, "helicopter gains altitude")
        var forward_start: Vector3=helicopter.global_position
        for i in range(120): helicopter.drive_step(1.0/60, 1.0, 0.0, 0.0)
        verify(Vector2(helicopter.global_position.x-forward_start.x,helicopter.global_position.z-forward_start.z).length() > 0.5, "helicopter moves horizontally")
        var heading: Vector3 = helicopter.travel_forward()
        for i in range(60): helicopter.drive_step(1.0/60, 1.0, 1.0, 0.0)
        verify(helicopter.travel_forward().dot(heading.cross(Vector3.UP)) > 0.0, "D steers helicopter right")
        game.player.hyper_enabled = true
        verify(helicopter.safe_exit(game.player).ok and not helicopter.safe_exit(game.player).door,"helicopter exit beside it while airborne (14 Nov 2026)")
        # Exercise a real landing before E; teleporting with residual velocity is not landing.
        var pad=game.box("Vehicle regression pad",Vector3.ZERO,Vector3(90,.4,90),Color.WHITE,"",true)
        pad.global_position=Vector3(500,30,500)
        helicopter.global_transform=Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*1.3),Vector3(500,35,500))
        helicopter.flight_velocity=Vector3.ZERO
        helicopter.helicopter_physics.reset()
        helicopter.rotor_power=1
        await physics_frame
        await physics_frame
        for i in range(600): helicopter.drive_step(1.0/60,0,0,-.35,true)
        verify(helicopter.ground_contact(),"helicopter lands before E exit")
        verify(game.toggle_vehicle(), "E exits helicopter")
        # The door / climb-out sequence plays first (vehicle doors, 5 Nov 2026).
        for i in range(roundi(helicopter.boarding_duration*1.2*60)+2):
            helicopter.drive_step(1.0/60, 0.0, 0.0, 0.0)
            game.player._physics_process(1.0/60)
        verify(game.player.riding_vehicle == null, "player is on foot again")
        verify(game.player.effects.enabled, "hyper effects resume after exiting")
        game.player.hyper_enabled = false
        game.player.effects.set_enabled(false)
        helicopter.global_transform=original
        helicopter.flight_velocity=Vector3.ZERO
        helicopter.helicopter_physics.reset()
        helicopter.rotor_power=0
        pad.free()
    # Each road vehicle is tested on the same clear physical platform after the
    # previous vehicle exited. Check actual ownership, not just an E event being handled.
    var road_pad=game.box("Road regression pad",Vector3.ZERO,Vector3(90,.4,90),Color.WHITE,"",true)
    road_pad.global_position=Vector3(510,0,510)
    for vehicle in game.driveable_vehicles:
        if vehicle.helicopter or vehicle.fixed_wing:
            continue
        verify(vehicle.has_meta("word_key"), "road vehicle vocabulary retained: "+vehicle.name)
        var saved: Transform3D = vehicle.global_transform
        vehicle.global_position = Vector3(510.0, .25, 510.0)
        game.player.global_position = vehicle.global_position + Vector3(0, 1.0, 0)
        await physics_frame
        await physics_frame
        verify(game.toggle_vehicle() and game.active_vehicle==vehicle, "E boards "+vehicle.name)
        if game.active_vehicle!=vehicle: break
        # Door/seat boarding sequence holds the vehicle until it completes.
        for i in range(roundi(vehicle.boarding_duration*60)+2): vehicle.drive_step(1.0/60, 1.0, 0.0, 0.0)
        verify(vehicle.boarding_progress==1.0 and vehicle.global_position.distance_to(Vector3(510.0, .25, 510.0)) < 0.3, "boarding sequence completes before driving "+vehicle.name)
        for i in range(60): vehicle.drive_step(1.0/60, 1.0, 0.0, 0.0)
        verify(vehicle.global_position.distance_to(Vector3(510.0, .25, 510.0)) > 0.5, "drives "+vehicle.name)
        var heading: Vector3 = vehicle.travel_forward()
        vehicle.drive_step(0.2, 1.0, 1.0, 0.0)
        verify(vehicle.travel_forward().dot(heading.cross(Vector3.UP)) > 0.0, "D steers right: "+vehicle.name)
        for i in range(180): vehicle.drive_step(1.0/60,0,0,1)
        await physics_frame
        await physics_frame
        verify(game.toggle_vehicle(), "E starts exit "+vehicle.name)
        for i in range(roundi(vehicle.boarding_duration*60)+2): vehicle.drive_step(1.0/60, 0.0, 0.0, 0.0)
        verify(game.player.riding_vehicle==null and game.active_vehicle==null, "E exits "+vehicle.name)
        if game.player.riding_vehicle!=null: break
        vehicle.global_transform=saved
    road_pad.free()
    print("Zoo and vehicle regression: ", assertions, " checks; ", problems.size(), " failures")
    quit(0 if problems.is_empty() else 1)
