extends SceneTree
## 1 Nov 2026 storefront redesign: eight fronts restyled from the user's sheet.
## Run with the README's isolated user directory (Main saves progress):
## godot --headless --path . --script res://docs/evidence/exterior-redesign-20261101/verify.gd
const FRONTS := {
    "CLOTHING":"ROPA","ELECTRONICS":"ELECTRÓNICA","SPORTS":"DEPORTES","POLICE STATION":"ESTACIÓN DE POLICÍA",
    "SUPERMARKET":"SUPERMERCADO","SCHOOL":"ESCUELA","BAKERY _ CAFE":"CAFÉ Y PANADERÍA","FURNITURE":"",
}
var failures:=0
var checks:=0
func _initialize(): run.call_deferred()
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        print("FAIL: ",label)
func word_at(node: Object) -> String:
    var n:=node as Node
    while n!=null:
        if n.has_meta("exterior_word"): return String(n.get_meta("exterior_word"))
        if n.has_meta("word"): return String(n.get_meta("word"))
        n=n.get_parent()
    return ""
func run() -> void:
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    await physics_frame
    await physics_frame
    var space: PhysicsDirectSpaceState3D=game.get_world_3d().direct_space_state
    var facades: Node3D=game.apartment.get_node("Map facades")
    var capsule:=CapsuleShape3D.new()
    capsule.radius=.32*1.3
    capsule.height=1.5*1.3
    for title in FRONTS:
        var facade: Node3D=facades.get_node(title)
        var b: AABB=facade.get_meta("facade_bounds")
        var c:=b.get_center()
        check(facade.find_children("*","StaticBody3D",true,false).is_empty(),title+": no solid facade parts")
        # The supermarket's left frontage is the cart shelter, so it gets lamps only.
        var boxes:=facade.find_children("Flower box*","Node3D",false,false)
        check((title=="SUPERMARKET" or not boxes.is_empty()) and boxes.all(func(n): return n.find_children("*","Area3D",true,false).is_empty()),title+": flower boxes present, not pickable")
        check(not facade.find_children("Wall lamp glass","Node3D",true,false).is_empty(),title+": wall lamps")
        # Door approach outside, threshold and first step inside stay walkable.
        for dz in [-1.6,.2,1.6]:
            var query:=PhysicsShapeQueryParameters3D.new()
            query.shape=capsule
            query.transform=Transform3D(Basis.IDENTITY,facade.to_global(Vector3(c.x,1.15,b.position.z+dz)))
            var blocked:=space.intersect_shape(query,1)
            check(blocked.is_empty(),title+": doorway clear at dz %.1f"%dz+("" if blocked.is_empty() else " (blocked by "+str(blocked[0].collider.get_path())+")"))
        # A street ray at a side window still names the building.
        var ray:=PhysicsRayQueryParameters3D.create(facade.to_global(Vector3(c.x+b.size.x*.3,2.0,b.position.z-5)),facade.to_global(Vector3(c.x+b.size.x*.3,2.0,b.position.z+1.5)))
        ray.collide_with_areas=true
        var hit:=space.intersect_ray(ray)
        var expected:=String(facade.get_meta("exterior_word",""))
        check(not hit.is_empty() and word_at(hit.collider)==expected,title+": window ray picks '"+expected+"' (got '"+(word_at(hit.collider) if not hit.is_empty() else "nothing")+"')")
        if FRONTS[title]!="":
            var signs:=facade.find_children("*","Label3D",true,false).filter(func(l): return l.visible and l.text==FRONTS[title])
            check(signs.size()==1,title+": exactly one Spanish name sign (%d)"%signs.size())
    print("STOREFRONT REDESIGN: %d checks, %d failures"%[checks,failures])
    quit(1 if failures>0 else 0)
