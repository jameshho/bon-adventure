extends SceneTree
## Current structural layout invariants; run with the README's isolated user directory.
const ZooAnimals:=preload("res://scripts/world/park_animals.gd")
var failures:=0
var checks:=0
func _initialize(): run.call_deferred()
func check(ok: bool,label: String):
    checks+=1
    if not ok: failures+=1; print("FAIL: ",label)
func run():
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    var town: Node3D=game.apartment
    var layout=game.reference_layout
    var road: PackedVector3Array=town.get_node("Curving neighborhood road").get_meta("reference_road_points")
    var extent:=AABB(road[0],Vector3.ZERO)
    for p in road: extent=extent.expand(p)
    check(extent.size.x/extent.size.z>1.55,"wide rectangular street loop")
    check(extent.size.z<150,"shorter north/south loop")
    # The comparisons with the old saved world (town_public_garden.tscn: landmark frames, lagoon
    # outline, bridge and pond placement) were retired with that world on 6 Nov 2026; the saved
    # modular town is now the source of truth.
    var bridge: MeshInstance3D=town.get_node("PublicGarden/Public Garden arched bridge")
    check(is_equal_approx(bridge.mesh.get_aabb().end.y,2.965),"raised bridge crown")
    var zoo: Vector3=layout.bounds(town.get_node("ParkZoo/ANIMALES SALVAJES lawn")).get_center()
    var barn: Vector3=layout.bounds(town.get_node("Barn")).get_center()
    var play: Vector3=layout.bounds(layout.pivots.Playground).get_center()
    var chapel: Vector3=layout.bounds(layout.pivots.Chapel).get_center()
    check(zoo.x< -50 and zoo.z<130,"zoo southeast")
    check(barn.x>40 and barn.z<110,"barn southwest")
    check(play.x>20 and play.z>165,"playground northwest")
    check(chapel.x< -50 and chapel.z>160,"chapel northeast")
    var fronts: Dictionary={"Bakery":Vector3.LEFT,"Electronics":Vector3.LEFT,"Bank":Vector3.LEFT,"Clothing":Vector3.RIGHT,"Supermarket":Vector3.RIGHT,"Library":Vector3.BACK,"Police":Vector3.RIGHT}
    for key in fronts:
        var delta: Transform3D=layout.pivots[key].get_meta("compact_delta")
        check((delta.basis*Vector3.FORWARD).dot(fronts[key])>.99,"inward entrance "+key)
    var site_nodes: Dictionary={}
    for key in layout.data.sites:
        if key in ["Pond","Travel","Gazebo","Playground"]: continue
        var source: String=layout.data.sites[key].scene_path
        var node: Node3D=town.get_node(source) if source!="" and key!="Supermarket" else layout.pivots[key]
        site_nodes[key]=node
        check(layout.site_at(layout.bounds(node).get_center())==key,"location binding "+key)
    for node in town.find_children("*","Node3D",true,false):
        if not node.has_meta("compact_original_transform"): continue
        var before: Transform3D=node.get_meta("compact_original_transform")
        # ParkZoo animals were all scaled up uniformly afterwards (base step animals_bigger, user
        # 11 Nov 2026: "make everything bigger"; park_animals.gd DISPLAY_SCALE), so only their
        # proportions must survive (16 Nov 2026).
        if node.get_parent().name=="ParkZoo" and ZooAnimals.ANIMAL_HEIGHTS.has(String(node.name)):
            var ratio: Vector3=node.basis.get_scale()/before.basis.get_scale()
            check(is_equal_approx(ratio.x,ratio.y) and is_equal_approx(ratio.y,ratio.z),"zoo animal scaled uniformly "+String(node.get_path()))
            continue
        check(before.basis.get_scale().is_equal_approx(node.basis.get_scale()),"rigid move preserves scale "+String(node.get_path()))
    var entries: Array=town.get_meta("reference_map_sites")
    var seen: Array=[]
    for entry in entries:
        check(is_instance_valid(entry.node) and not seen.has(entry.node),"unique live map site "+entry.title)
        seen.append(entry.node)
    for key in ["Barn","Restaurants","Airport"]: site_nodes[key]=town.get_node(key)
    var names:=site_nodes.keys()
    for i in range(names.size()):
        var a: AABB=layout.bounds(site_nodes[names[i]])
        for j in range(i+1,names.size()):
            var b: AABB=layout.bounds(site_nodes[names[j]])
            var ra:=Rect2(a.position.x,a.position.z,a.size.x,a.size.z)
            var rb:=Rect2(b.position.x,b.position.z,b.size.x,b.size.z)
            check(not ra.intersects(rb),"separate building footprints "+names[i]+" / "+names[j])
    # 29 Oct 2026: site-owned Subi (Home garage) and the school bus also register.
    # 9 Nov 2026: 13 = helicopter, turboprop, the eight Vehicles/ (car, truck, bus, taxi, police
    # car, ambulance, fire truck, the motorcycle that is now the scooter), school bus, Subi and the
    # warehouse delivery truck (drivable since 8 Nov). The scooter replaced the motorcycle, not added.
    # 14 Nov 2026: +31 parked cars and motorcycles (base step parked_vehicles), 44 in all.
    if game.driveable_vehicles.size()!=44:
        print("  vehicles: ",game.driveable_vehicles.map(func(v): return str(town.get_path_to(v))))
    check(game.driveable_vehicles.size()==44,"all forty-four road/air vehicles registered (13 + 31 parked)")
    check(game.zoo_gate!=null and game.farm_gate!=null,"relocated gates registered")
    for gate in [game.zoo_gate,game.farm_gate]:
        gate.toggle_gate()
        gate._process(1)
        check(absf(gate.left_hinge.rotation.y)>.5,"gate opens "+gate.name)
        gate.toggle_gate()
        gate._process(1)
        check(absf(gate.left_hinge.rotation.y)<.1,"gate closes "+gate.name)
    print("COMPACT LAYOUT: ",checks," checks; ",failures," failures")
    quit(1 if failures else 0)
