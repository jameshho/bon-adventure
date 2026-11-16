extends SceneTree
## 1 Nov 2026: plush staff in the bank (bear banker), sports store and furniture showroom
## (golden and sheep salespeople). Run with the README's isolated user directory
## (Main saves progress): godot --headless --path . --script res://docs/evidence/shop-staff-20261101/verify.gd
var failures:=0
var checks:=0
func _initialize(): run.call_deferred()
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        print("FAIL: ",label)
# True when no solid collides with a box of `size` at global `xform` (world units).
func box_clear(space: PhysicsDirectSpaceState3D,xform: Transform3D,size: Vector3) -> bool:
    var box:=BoxShape3D.new()
    box.size=size
    var query:=PhysicsShapeQueryParameters3D.new()
    query.shape=box
    query.transform=xform
    return space.intersect_shape(query,1).is_empty()
func run() -> void:
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    var town: Node3D=game.apartment
    await physics_frame
    await physics_frame
    var space: PhysicsDirectSpaceState3D=game.get_world_3d().direct_space_state
    var interaction:=preload("res://scripts/player/interaction_controller.gd")
    for word in ["banker","salesperson"]:
        check(game.vocabulary.has(word),word+" is a word")
    # [node name, building, species scene, word, outfit, building-local floor spot]
    var staff:=[
        ["BearBanker",town.get_node("RelocatedSites/Bank"),"bear_plush","banker","businessman",Vector3(21.1,.03,38.9)],
        ["GoldenSalesperson",town.get_node("Buildings/SportsStore"),"golden_plush","salesperson","sports_shopkeeper",Vector3(-6.1,.04,11.15)],
        ["SheepSalesperson",town.get_node("Buildings/FurnitureStore"),"sheep_plush","salesperson","furniture_shopkeeper",Vector3(1.7,.03,-6.4)],
    ]
    for spec in staff:
        var building: Node3D=spec[1]
        var npc: Node3D=building.get_node_or_null("Interior/"+spec[0])
        check(npc!=null,spec[0]+" exists inside "+building.name)
        if npc==null: continue
        check(npc.scene_file_path.ends_with(spec[2]+".tscn"),spec[0]+" is a "+spec[2])
        check(String(npc.get_meta("word_key",""))==spec[3],spec[0]+" teaches "+spec[3])
        var costume: Node=npc.get_node_or_null("Costume")
        check(costume!=null and String(costume.get("outfit"))==spec[4],spec[0]+" wears "+spec[4])
        check(npc.global_basis.get_scale().is_equal_approx(Vector3.ONE),spec[0]+" is BonBon-sized (world scale 1)")
        var area: Node=npc.get_node_or_null("StudyArea")
        check(area!=null and interaction.vocabulary_target(area,town)==npc,spec[0]+" click resolves to its word")
        var spot: Vector3=building.to_global(spec[5])
        check(Vector2(npc.global_position.x-spot.x,npc.global_position.z-spot.z).length()<.01,spec[0]+" stands on its spot")
        # Body volume (belly height, a little inside the measured half-widths) is free of solids.
        var body:=Transform3D(npc.global_basis.orthonormalized(),npc.global_position+Vector3(0,.8,0))
        check(box_clear(space,body,Vector3(1.2,1.0,1.0)),spec[0]+" does not stand inside a fixture or wall")
    print("SHOP STAFF: ",failures," failures; ",checks," checks")
    quit(0 if failures==0 else 1)
