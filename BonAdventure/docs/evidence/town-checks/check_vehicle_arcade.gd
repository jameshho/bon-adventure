extends SceneTree
## Vehicles workstream, 14 Nov 2026 (docs/guides/ZOO_VEHICLE_IMPLEMENTATION.md#arcade-collisions-exit-while-moving-and-resets--14-november-2026):
## parked cars and motorcycles in every lot, arcade wall slides, exit while moving (coast, then
## parked again), aircraft resets (crash, distance) and the plane's map edge.
## Run: python3 tools/run_checks.py --only vehicle_arcade   (isolated HOME; writes no files)
const VehicleControls := preload("res://scripts/core/vehicle_controls.gd")
var game
var town: Node3D
var checks := 0
var failures: Array[String] = []
var walls: Array[Node] = []
func _initialize(): run.call_deferred()
func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        print("FAIL: ", label)

func wall(centre: Vector3, size: Vector3, yaw := 0.0) -> StaticBody3D:
    var body := StaticBody3D.new()
    game.add_child(body)
    body.global_transform = Transform3D(Basis(Vector3.UP, yaw), centre)
    var shape := CollisionShape3D.new()
    shape.shape = BoxShape3D.new()
    shape.shape.size = size
    body.add_child(shape)
    walls.append(body)
    return body

func clear_walls() -> void:
    for body in walls: body.free()
    walls.clear()

func place(vehicle, p: Vector3, yaw := 0.0) -> void:
    vehicle.global_transform = Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * 1.3), p)
    vehicle.road_physics.reset()
    vehicle.current_speed = 0
    vehicle.occupied = true
    vehicle.coasting = false
    for i in range(60): vehicle.drive_step(1.0 / 60, 0, 0, 1)

func planar(vehicle) -> float:
    return Vector2(vehicle.road_physics.velocity.x, vehicle.road_physics.velocity.z).length()

## Coasts `vehicle` (heading `yaw`, speed `speed`) into whatever is ahead; returns
## [speed kept 0.05 s after the first hit / speed just before it, into-wall speed].
func hit_ratio(vehicle, p: Vector3, yaw: float, speed: float) -> Array:
    place(vehicle, p, yaw)
    vehicle.road_physics.velocity = vehicle.travel_forward() * speed
    vehicle.road_physics.last_impact = 0.0
    var before := speed
    for i in range(240):
        var last := planar(vehicle)
        vehicle.drive_step(1.0 / 60, 0, 0, 0)
        if vehicle.road_physics.last_impact > 0:
            before = last
            for j in range(3): vehicle.drive_step(1.0 / 60, 0, 0, 0)
            return [planar(vehicle) / before, vehicle.road_physics.last_impact]
    return [1.0, 0.0]

func run():
    game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    town = game.apartment
    for vehicle in game.driveable_vehicles:
        vehicle.set_physics_process(false)
    await physics_frame
    await physics_frame
    lots()
    var pad = game.box("Arcade fixture", Vector3.ZERO, Vector3(140, .4, 140), Color.WHITE, "", true)
    pad.global_position = Vector3(1000, 0, 1000)
    await physics_frame
    await physics_frame
    var car: DriveableVehicle = town.get_node("Vehicles/Parked car (sports)")
    # The red parked motorcycles left the map on 18 Nov 2026 (base step tutorial_lot_clear): the
    # scooter is the town's motorcycle.
    var bike: DriveableVehicle = town.get_node("Vehicles/Motorcycle")
    var car_home: Transform3D = car.global_transform
    var bike_home: Transform3D = bike.global_transform
    # A long wall along -X at z = 1004 (face z 1003.5); a 20 degree glance at 15 m/s.
    wall(Vector3(970, 1.5, 1004), Vector3(80, 2.6, 1))
    await physics_frame
    var car_glance := hit_ratio(car, Vector3(1010, .45, 1000), deg_to_rad(20), 15)
    var bike_glance := hit_ratio(bike, Vector3(1010, .45, 1000), deg_to_rad(20), 15)
    var car_major := hit_ratio(car, Vector3(1010, .45, 999), deg_to_rad(60), 20)
    print("ARCADE glance car ", car_glance, " bike ", bike_glance, " major car ", car_major)
    check(car_glance[1] > 0 and car_glance[0] > .7, "car glancing a wall keeps most of its speed (%.2f)" % car_glance[0])
    check(bike_glance[1] > 0 and bike_glance[0] > car_glance[0], "motorcycle keeps more speed than a car (%.2f vs %.2f)" % [bike_glance[0], car_glance[0]])
    check(car_major[1] > car.road_physics.MAJOR_IMPACT_SPEED and car_major[0] < .5 and car_major[0] < car_glance[0] - .2, "a hard, near head-on hit slows much more (%.2f)" % car_major[0])
    # Steering still works right after a hit (no yaw cut), and the car slides along the wall.
    place(car, Vector3(1010, .45, 1000), deg_to_rad(20))
    car.road_physics.velocity = car.travel_forward() * 15
    var slid := false
    for i in range(120):
        car.drive_step(1.0 / 60, 1, 0, 0)
        if car.road_physics.last_impact > 0 and planar(car) > 8: slid = true
    check(slid and car.global_position.z < 1003.5, "the car slides along the wall without stopping or passing through it")
    clear_walls()
    # Thin wall (5 cm): head-on and steep at top speed, it never tunnels.
    wall(Vector3(985, 1.5, 1000), Vector3(.05, 2.6, 60))
    await physics_frame
    var through := false
    for spec in [[0.0, 0.0], [deg_to_rad(15), 4.0], [deg_to_rad(-30), -6.0]]:
        for vehicle in [car, bike]:
            place(vehicle, Vector3(1010, .45, 1000 + spec[1]), spec[0])
            vehicle.road_physics.velocity = vehicle.travel_forward() * 27
            for i in range(150):
                vehicle.drive_step(1.0 / 60, 1, 0, 0)
                if vehicle.global_position.x < 985.5: through = true
    check(not through, "no tunnelling through a 5 cm wall at 27 m/s")
    clear_walls()
    # A concave corner: pushed into it, the car stops in it without passing or jittering out.
    wall(Vector3(985, 1.5, 1000), Vector3(1, 2.6, 40))
    wall(Vector3(1000, 1.5, 1008), Vector3(40, 2.6, 1))
    await physics_frame
    place(car, Vector3(1000, .45, 998), deg_to_rad(30))
    car.road_physics.velocity = car.travel_forward() * 15
    var inside := true
    for i in range(240):
        car.drive_step(1.0 / 60, 1, 0, 0)
        inside = inside and car.global_position.x > 985.5 and car.global_position.z < 1007.5
    check(inside and car.can_rotate(car.global_transform, car.road_physics.ground_exclusions), "a corner holds the car without tunnelling (x %.2f z %.2f)" % [car.global_position.x, car.global_position.z])
    clear_walls()
    car.occupied = false
    bike.occupied = false
    car.global_transform = car_home
    bike.global_transform = bike_home
    car.park_road_vehicle()
    bike.park_road_vehicle()
    await exit_while_moving(car)
    await aircraft()
    pad.free()
    print("VEHICLE ARCADE: ", checks, " checks; ", failures.size(), " failures")
    quit(0 if failures.is_empty() else 1)

## The warehouse redesign of 14 Nov 2026 (scripts/world/warehouse.gd): loading bays at
## warehouse-local x -7.2..-3.4 and -2.2..1.6 with an apron at -8.2..2.6 in front of them, the
## glass entrance at -12.2. Tested in the Warehouse root's frame (town (-35, 0, 220.8), +X west),
## so it holds while this worktree still has the old warehouse scene.
func warehouse_layout() -> void:
    var frame := Transform3D(Basis.IDENTITY, Vector3(-35, 0, 220.8))
    # 18 Nov 2026: the supermarket's delivery truck parks in the bay the warehouse motorcycle used.
    for title in ["Parked car (warehouse)", "Truck"]:
        var vehicle: Node3D = town.get_node("Vehicles/" + title)
        var box := AABB()
        var first := true
        for mesh in vehicle.find_children("*", "MeshInstance3D", true, false):
            var b: AABB = frame.affine_inverse() * (town.global_transform.affine_inverse() * mesh.global_transform) * mesh.get_aabb()
            box = b if first else box.merge(b)
            first = false
        # Truck corridors and drive: local x -8.2..3.4 (apron and drive), a metre's margin.
        check(box.position.x > 4.4, "%s is clear of the truck corridors and the drive (local x %.2f..%.2f)" % [title, box.position.x, box.end.x])
        check(box.end.x < 13.0 and box.position.z > -12.0 and box.end.z < -5.8, "%s stays in the lot's west bays (local z %.2f..%.2f)" % [title, box.position.z, box.end.z])
    var walk: MeshInstance3D = town.get_node("Warehouse entrance connection")
    var span: AABB = frame.affine_inverse() * walk.get_aabb()
    check(absf(span.get_center().x + 12.2) < .05 and span.end.z > -.2 and span.position.z < -5.8, "the entrance walk reaches the entrance at local x -12.2 from the lot (%s)" % span)
    check(span.end.x < -8.2 - .5, "the entrance walk stays clear of the loading apron (ends at local x %.2f)" % span.end.x)

func lots() -> void:
    var found := 0
    for lot in town.get_children():
        if not lot.get_meta("blueprint_parking", false): continue
        var mesh: MeshInstance3D = lot.get_child(0)
        var box: AABB = mesh.get_aabb().grow(1.5)
        var kinds := []
        for vehicle in game.driveable_vehicles:
            var p: Vector3 = lot.to_local(vehicle.global_position)
            if box.has_point(Vector3(p.x, box.get_center().y, p.z)): kinds.append(vehicle.get_meta("word_key", ""))
        # A car in every lot; no motorcycles since 18 Nov 2026 (user: the red ones left the map).
        check(kinds.has("car") or kinds.has("taxi") or kinds.has("police car"), "%s has a car %s" % [lot.name, kinds])
    for vehicle in town.get_node("Vehicles").get_children():
        if not (String(vehicle.name).begins_with("Parked ") or String(vehicle.name).begins_with("Road-side ")): continue
        found += 1
        check(game.driveable_vehicles.has(vehicle), "%s is a registered DriveableVehicle" % vehicle.name)
        vehicle.road_physics.sample_ground(vehicle, 1.0 / 60)
        check(vehicle.road_physics.supported, "%s stands on its wheels" % vehicle.name)
        # The motorcycle's authored body box reaches 10 cm below its tyres (driving lifts it clear),
        # so the body is tested 15 cm up: walls, kerbs, posts, figures and vehicles, not the ground.
        var blockers := []
        var raised: Transform3D = vehicle.global_transform.translated(Vector3.UP * .15)
        for hull in vehicle.flight_hulls:
            for hit in game.get_world_3d().direct_space_state.intersect_shape(vehicle.hull_query(hull, raised, vehicle.road_physics.ground_exclusions), 4):
                blockers.append(str(town.get_path_to(hit.collider)) if town.is_ancestor_of(hit.collider) else str(hit.collider.name))
        check(blockers.is_empty(), "%s is clear of walls, figures and other vehicles %s" % [vehicle.name, blockers])
        for other in game.driveable_vehicles:
            if other != vehicle and other.global_position.distance_to(vehicle.global_position) < 3.0:
                check(false, "%s keeps its distance from %s" % [vehicle.name, other.name])
        for drive in town.get_children():
            if not drive.get_meta("refined_driveway", false): continue
            var points: PackedVector3Array = drive.get_meta("reference_road_points")
            var p := town.to_local(vehicle.global_position)
            for i in range(1, points.size()):
                var q := Geometry3D.get_closest_point_to_segment(Vector3(p.x, 0, p.z), Vector3(points[i - 1].x, 0, points[i - 1].z), Vector3(points[i].x, 0, points[i].z))
                if q.distance_to(Vector3(p.x, 0, p.z)) < 4.4:
                    check(false, "%s is clear of %s" % [vehicle.name, drive.name])
                    break
    # 31 added on 14 Nov 2026, the 15 motorcycles among them removed on 18 Nov 2026.
    check(found == 16, "16 parked cars (%d)" % found)
    warehouse_layout()
    # Backing out of a bay works (nose-in parking): a car on a terrain-level lot and the scooter.
    for title in ["Parked car (hospital)", "Motorcycle"]:
        var vehicle: DriveableVehicle = town.get_node("Vehicles/" + title)
        var home: Transform3D = vehicle.global_transform
        vehicle.occupied = true
        for i in range(30): vehicle.drive_step(1.0 / 60, 0, 0, 1)
        for i in range(150): vehicle.drive_step(1.0 / 60, -1, 0, 0)
        check(vehicle.global_position.distance_to(home.origin) > 2.0, "%s backs out of its bay (%.1f m)" % [title, vehicle.global_position.distance_to(home.origin)])
        vehicle.occupied = false
        vehicle.global_transform = home
        vehicle.park_road_vehicle()

func exit_while_moving(car) -> void:
    var parked: Transform3D = car.global_transform
    place(car, Vector3(1020, .45, 912), PI / 2)
    car.occupied = false
    game.player.global_position = car.global_position + Vector3(4, .2, 0)
    check(game.board_vehicle(car), "board the car")
    car.boarding_progress = 1
    for i in range(150): car.drive_step(1.0 / 60, 1, 0, 0)
    var speed: float = car.current_speed
    check(speed > 10, "car up to speed before the exit (%.1f m/s)" % speed)
    var start: Vector3 = car.global_position
    check(game.toggle_vehicle(), "E while moving")
    var side: float = Vector2(game.player.global_position.x - car.global_position.x, game.player.global_position.z - car.global_position.z).length()
    check(game.active_vehicle == null and game.player.riding_vehicle == null and not car.exiting, "out at once, no door sequence")
    check(side > 2.5 and side < 4.5, "standing beside the car (%.2f m)" % side)
    check(car.coasting and absf(car.current_speed) > speed * .9, "the car keeps its speed and coasts")
    var stopped_after := -1.0
    var last := planar(car)
    var slowing := true
    for i in range(60 * 60):
        car._physics_process(1.0 / 60)
        slowing = slowing and planar(car) <= last + .01
        last = planar(car)
        if not car.coasting:
            stopped_after = i / 60.0
            break
    print("ARCADE coast: %.1f m/s, %.0f m, parked after %.1f s" % [speed, car.global_position.distance_to(start), stopped_after])
    check(slowing and car.global_position.distance_to(start) > 20, "the car coasts on and slows down naturally")
    check(stopped_after > 0 and not car.needs_physics() and planar(car) == 0.0, "then parks again: no physics cost")
    car.global_transform = parked
    car.park_road_vehicle()

func aircraft() -> void:
    var heli: DriveableVehicle = null
    var plane = town.get_node("Vehicles/Turboprop")
    for vehicle in game.driveable_vehicles:
        if vehicle.helicopter: heli = vehicle
    check(heli != null and plane != null, "helicopter and plane found")
    if heli == null or plane == null: return
    var heli_start: Transform3D = heli.start_pose()
    check(heli_start.origin.distance_to(heli.global_position) < .01 and plane.start_pose().origin.distance_to(plane.home_pose.origin) < .05, "start poses are the parked poses")
    # Helicopter left in the air: BonBon falls beside it and lands; it crashes and resets to its pad.
    heli.global_transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 1.3), Vector3(1000, 30, 1000))
    game.player.global_position = heli.global_position + Vector3(4, 0, 0)
    heli.occupied = false
    check(game.board_vehicle(heli), "board the helicopter")
    heli.boarding_progress = 1
    heli.rotor_power = 1
    heli.landed = false
    heli.flight_velocity = Vector3(0, 0, -6)
    var result: Dictionary = heli.safe_exit(game.player)
    check(result.ok and not result.get("door", true), "airborne helicopter exit is allowed, beside it")
    check(game.toggle_vehicle() and game.active_vehicle == null, "E in the air")
    var gap: float = Vector2(game.player.global_position.x - heli.global_position.x, game.player.global_position.z - heli.global_position.z).length()
    check(gap > 6.5, "let out clear of the rotor (%.1f m)" % gap)
    check(heli.coasting, "the helicopter flies on unpowered")
    game.player.set_physics_process(true)
    var crashed := false
    var landed_at := -1.0
    var fastest := 0.0
    for i in range(60 * 12):
        await physics_frame
        heli._physics_process(1.0 / 60)
        crashed = crashed or heli.crashed
        fastest = minf(fastest, heli.flight_velocity.y)
        if landed_at < 0 and game.player.is_on_floor(): landed_at = i / 60.0
    game.player.set_physics_process(false)
    print("ARCADE heli: player landed after %.1f s at y %.2f; heli fastest descent %.1f m/s, crashed %s, at start %s, at %s" % [landed_at, game.player.global_position.y, fastest, crashed, heli.global_position.distance_to(heli_start.origin) < .05, heli.global_position])
    check(landed_at > 0 and absf(game.player.global_position.y - .2) < .6, "BonBon falls to the ground and lands")
    # Unpowered it comes down (autorotating, or a crash that resets it to its pad), then parks.
    var at_start: bool = heli.global_position.distance_to(heli_start.origin) < .05
    check((at_start or (heli.landed and heli.global_position.y < 2)) and not heli.crashed and not heli.coasting and not heli.needs_physics() and heli.rotor_power == 0.0, "the unpowered helicopter comes down and parks (no physics cost)")
    # Flown into a wall: a crash, then back on the pad with the pilot aboard.
    heli.global_transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 1.3), Vector3(1000, 30, 1000))
    wall(Vector3(1000, 30, 990), Vector3(40, 30, 1))
    await physics_frame
    heli.occupied = true
    heli.rotor_power = 1
    heli.flight_velocity = Vector3(0, 0, -12)
    for i in range(60 * 4): heli.drive_step(1.0 / 60, 1, 0, 0)
    check(heli.global_position.distance_to(heli_start.origin) < .05 and heli.occupied, "a wall hit at speed resets the helicopter to its pad, pilot aboard")
    clear_walls()
    heli.occupied = false
    heli.reset_to_start()
    # Plane: a crash resets it; left far away it resets.
    plane.global_position += Vector3(30, 0, 0)
    plane.crash()
    for i in range(60 * 3): plane._physics_process(1.0 / 60)
    check(not plane.crashed and plane.global_position.distance_to(plane.home_pose.origin) < .05, "a crashed plane resets to the runway by itself")
    game.player.global_position = Vector3(0, 1, 0)
    plane.global_position = game.player.global_position + Vector3(350, 40, 0)
    heli.global_position = game.player.global_position + Vector3(-350, 40, 0)
    VehicleControls.update_aircraft(game)
    check(plane.global_position.distance_to(plane.home_pose.origin) < .05 and heli.global_position.distance_to(heli_start.origin) < .05, "aircraft left more than 300 m away reset")
    plane.global_position = game.player.global_position + Vector3(200, 40, 0)
    VehicleControls.update_aircraft(game)
    check(plane.global_position.distance_to(plane.home_pose.origin) > 10, "an aircraft within 300 m stays")
    plane.reset_to_start()
    # Map edge: flying out past it turns the plane back toward town.
    var bounds: Rect2 = town.get_meta("reference_map_bounds")
    var outward: Vector3 = (town.global_basis * Vector3(1, 0, 0)).normalized()
    var out_point: Vector3 = town.to_global(Vector3(bounds.end.x, 0, bounds.get_center().y)) + outward * (plane.MAP_MARGIN + 40) + Vector3.UP * 120
    game.player.global_position = plane.global_position + Vector3(0, 1, 3)
    check(game.board_vehicle(plane), "board the plane")
    plane.boarding_progress = 1
    DriveableVehicle.easy_flying = true
    plane.global_transform = Transform3D(Basis.looking_at(outward, Vector3.UP).scaled(Vector3.ONE * 1.3), out_point)
    plane.flight_velocity = outward * 38
    plane.landed = false
    plane.throttle = .6
    plane.engine_power = .6
    plane.easy_hold_y = out_point.y
    var flashes := [0]
    var on_edge := func(_v): flashes[0] += 1
    plane.map_edge_reached.connect(on_edge)
    var max_overrun := -INF
    var back := false
    for i in range(60 * 40):
        plane._physics_process(1.0 / 60)
        max_overrun = maxf(max_overrun, plane.map_overrun())
        if plane.map_overrun() < -20:
            back = true
            break
    print("ARCADE map edge: flashes %d, furthest %.0f m past the edge, back %s, crashed %s" % [flashes[0], max_overrun, back, plane.crashed])
    check(flashes[0] >= 1, "flying past the edge shows vehicle.map_edge")
    check(back and not plane.crashed and max_overrun < plane.MAP_RESET_MARGIN, "the plane turns back toward town by itself")
    plane.map_edge_reached.disconnect(on_edge)
    # Far past the edge (or unoccupied past it): reset to the runway.
    plane.global_position = out_point + outward * (plane.MAP_RESET_MARGIN + 50)
    plane._physics_process(1.0 / 60)
    check(plane.global_position.distance_to(plane.home_pose.origin) < .05 and game.active_vehicle == plane, "far past the edge the plane resets, pilot aboard")
    # The HUD Reset button: main.active_vehicle.reset_to_start() keeps the pilot in the cockpit.
    plane.global_position += Vector3(40, 30, 0)
    plane.flight_velocity = Vector3(0, 0, 30)
    game.active_vehicle.reset_to_start()
    check(plane.global_position.distance_to(plane.home_pose.origin) < .05 and plane.flight_velocity == Vector3.ZERO and plane.occupied and game.player.riding_vehicle == plane, "reset_to_start() while flying: at the start, stopped, still aboard")
    game.complete_vehicle_exit(plane, plane.global_position + Vector3(0, 0, 12))
    plane.occupied = false
    plane.coasting = true
    plane.global_position = out_point
    plane._physics_process(1.0 / 60)
    check(plane.global_position.distance_to(plane.home_pose.origin) < .05 and not plane.coasting, "an unoccupied plane past the edge resets")
