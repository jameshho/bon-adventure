extends RefCounted
## Adapt legacy solid models once at construction: partition their actual surfaces
## into a fixed shell and permanent hinged leaves, retaining paint/glass/trim.
## No geometry is created, hidden or replaced during boarding.
const Door = preload("res://scripts/world/vehicle_door.gd")

static func spec(vehicle: Node3D) -> Dictionary:
    if vehicle.has_meta("vehicle_door_spec"):
        return vehicle.get_meta("vehicle_door_spec")
    var key: String = vehicle.get_meta("door_profile", vehicle.get_meta("word_key", "car"))
    if "Subaru" in str(vehicle.name): key = "subaru"
    if key == "school bus": key = "bus"
    # hinge X, latch X, sill Y, header Y, outer Z, inner cut Z.
    var profiles := {
        "car": [-.88, -.08, .42, 1.56, .80, .54],
        "taxi": [-.89, .015, .50, 1.70, .84, .60],
        "police car": [-.88, .005, .58, 1.54, .86, .57],
        "subaru": [-.62, .29, .47, 1.57, .85, .58],
        "truck": [-1.19, .17, .99, 2.19, .92, .72],
        "ambulance": [-2.30, -1.015, 1.10, 2.47, .97, .77],
        "fire truck": [-2.25, -1.205, 1.01, 2.30, .96, .76],
        "bus": [-1.66, -.76, .69, 2.32, -1.23, -.98],
    }
    var d: Array = profiles.get(key, profiles.car)
    return {"hinge": d[0], "length": d[1]-d[0], "bottom":d[2], "top":d[3], "side":d[4], "inner":d[5], "door":key!="motorcycle"}

static func install(vehicle: Node3D) -> Array[Node3D]:
    var result: Array[Node3D] = []
    # New models can author the assemblies directly and skip legacy partitioning.
    for node in vehicle.find_children("*", "Node3D", true, false):
        if node.get_script()==Door and node.get_meta("boarding_door", false):
            result.append(node)
    if not result.is_empty(): return result
    var s := spec(vehicle)
    if not s.door: return result
    if vehicle.helicopter:
        result.append(extract(vehicle, "DriverDoorSwing", AABB(Vector3(-2,.86,-1.49),Vector3(1.30,1.20,1.05)), Vector3(-.96,.86,-1.49), -1.15))
    elif vehicle.get_meta("word_key", "") in ["bus", "school bus"]:
        # Two outward-opening leaves at the actual passenger entrance (-Z).
        var mid: float = s.hinge+s.length*.5
        result.append(extract(vehicle,"DriverDoorSwing",AABB(Vector3(s.hinge,s.bottom,-2),Vector3(s.length*.5,s.top-s.bottom,2+s.inner)),Vector3(s.hinge,s.bottom,s.side),1.15))
        result.append(extract(vehicle,"EntryDoorRear",AABB(Vector3(mid,s.bottom,-2),Vector3(s.length*.5,s.top-s.bottom,2+s.inner)),Vector3(s.hinge+s.length,s.bottom,s.side),-1.15))
    else:
        result.append(extract(vehicle,"DriverDoorSwing",AABB(Vector3(s.hinge,s.bottom,s.inner),Vector3(s.length,s.top-s.bottom,2-s.inner)),Vector3(s.hinge,s.bottom,s.side),-1.15))
    return result

static func extract(vehicle: Node3D, title: String, region: AABB, hinge: Vector3, angle: float) -> Node3D:
    var leaf := Node3D.new()
    leaf.set_script(Door)
    leaf.name = title
    vehicle.add_child(leaf)
    leaf.position = hinge
    leaf.open_angle = angle
    leaf.seal_pose()
    var planes: Array[Plane] = []
    for axis in range(3):
        var normal := Vector3.ZERO
        normal[axis] = 1
        planes.append(Plane(normal,region.end[axis]))
        planes.append(Plane(-normal,-region.position[axis]))
    var nodes := vehicle.find_children("*", "Node3D", true, false)
    for node in nodes:
        if node == leaf or node.is_ancestor_of(leaf): continue
        if inside_door(node) or node.has_meta("door_partitioned"): continue
        var path := str(vehicle.get_path_to(node))
        if "Tire" in path or "Wheel" in path or "Rotor" in path or "Lamp" in path: continue
        var local: Transform3D = vehicle.global_transform.affine_inverse()*node.global_transform
        if node is Label3D:
            if region.has_point(local.origin): node.reparent(leaf, true)
            continue
        var source: Mesh
        var material: Material
        if node is MeshInstance3D:
            source = node.mesh
            material = node.material_override
        elif node is CSGPolygon3D and node.mode == CSGPolygon3D.MODE_DEPTH:
            source = polygon_mesh(node)
            material = node.material
        else: continue
        if source == null or not (local*source.get_aabb()).intersects(region): continue
        var fixed := ArrayMesh.new()
        var moving := ArrayMesh.new()
        for surface in range(source.get_surface_count()):
            var arrays := source.surface_get_arrays(surface)
            if arrays.is_empty(): continue
            var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
            var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
            var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
            var stay := SurfaceTool.new()
            var move := SurfaceTool.new()
            stay.begin(Mesh.PRIMITIVE_TRIANGLES)
            move.begin(Mesh.PRIMITIVE_TRIANGLES)
            var counts := [0,0]
            var total := indices.size() if not indices.is_empty() else vertices.size()
            for i in range(0,total,3):
                var poly: Array = []
                for j in range(3):
                    var index: int = indices[i+j] if not indices.is_empty() else i+j
                    poly.append([local*vertices[index], (local.basis.inverse().transposed()*normals[index]).normalized()])
                for plane in planes:
                    var outside := clip(poly,plane,false)
                    counts[0] += triangles(stay,outside,Vector3.ZERO)
                    poly = clip(poly,plane,true)
                    if poly.is_empty(): break
                counts[1] += triangles(move,poly,hinge)
            var paint: Material = material if material else source.surface_get_material(surface)
            if counts[0]>0:
                stay.set_material(paint)
                stay.commit(fixed)
            if counts[1]>0:
                move.set_material(paint)
                move.commit(moving)
        if moving.get_surface_count()==0: continue
        if fixed.get_surface_count()>0:
            var shell := MeshInstance3D.new()
            shell.name = str(node.name)+"FixedShell"
            vehicle.add_child(shell)
            shell.mesh = fixed
        var skin := MeshInstance3D.new()
        skin.name = str(node.name)+"DoorSkin"
        leaf.add_child(skin)
        skin.mesh = moving
        # Keep original nodes/metadata/colliders and references intact.
        node.layers = 0
        node.set_meta("door_partitioned", true)
    return leaf

static func inside_door(node: Node) -> bool:
    var p := node
    while p != null:
        if p.get_script()==Door: return true
        p = p.get_parent()
    return false

static func clip(poly: Array, plane: Plane, inside: bool) -> Array:
    var out: Array = []
    if poly.is_empty(): return out
    var a: Array = poly.back()
    var da := plane.distance_to(a[0])
    for b in poly:
        var db := plane.distance_to(b[0])
        var take_a := da<=0 if inside else da>0
        var take_b := db<=0 if inside else db>0
        if take_a!=take_b:
            var t := da/(da-db)
            out.append([a[0].lerp(b[0],t),a[1].lerp(b[1],t).normalized()])
        if take_b: out.append(b)
        a = b
        da = db
    return out

static func triangles(tool: SurfaceTool, poly: Array, offset: Vector3) -> int:
    if poly.size()<3: return 0
    for i in range(1,poly.size()-1):
        for vertex in [poly[0],poly[i],poly[i+1]]:
            tool.set_normal(vertex[1])
            tool.add_vertex(vertex[0]-offset)
    return poly.size()-2

static func polygon_mesh(node: CSGPolygon3D) -> Mesh:
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var points := node.polygon
    var ids := Geometry2D.triangulate_polygon(points)
    for back in [false,true]:
        for i in range(0,ids.size(),3):
            for j in ([0,1,2] if back else [2,1,0]):
                var p := points[ids[i+j]]
                tool.set_normal(Vector3.BACK if not back else Vector3.FORWARD)
                tool.add_vertex(Vector3(p.x,p.y,-node.depth if back else 0))
    var clockwise := Geometry2D.is_polygon_clockwise(points)
    for i in range(points.size()):
        var a := points[i]
        var b := points[(i+1)%points.size()]
        var n := Vector3(b.y-a.y,a.x-b.x,0).normalized()
        var edge := [Vector3(b.x,b.y,-node.depth),Vector3(a.x,a.y,-node.depth),Vector3(a.x,a.y,0),Vector3(b.x,b.y,0),Vector3(b.x,b.y,-node.depth),Vector3(a.x,a.y,0)]
        if clockwise:
            n = -n
            edge.reverse()
        for v in edge:
            tool.set_normal(n)
            tool.add_vertex(v)
    return tool.commit()
