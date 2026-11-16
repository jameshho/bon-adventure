extends RefCounted
## Landscape helpers (town coordinates, game = Main): smoothed curves, ground surfaces, patches,
## ribbons (roads and paths), walks, trees and benches, for a building's own script
## (docs/guides/MODULAR_TOWN.md). The 2026 startup pass that built the first park with them (build())
## was deleted on 6 Nov 2026.
var game
var paths: Array[PackedVector3Array] = []
var grass := Color("99b880")
var path_color := Color("d8c8a4")
var tree_scene := preload("res://scenes/props/nature/tree.tscn")

func b(label: String, pos: Vector3, size: Vector3, tint: Color, word := "", solid := false) -> Node3D:
    return game.box(label,pos,size,tint,word,solid)

func smooth(points: Array, closed := false) -> PackedVector3Array:
    var curve := Curve3D.new()
    curve.bake_interval = 0.6
    var count := points.size()
    for i in range(count + (1 if closed else 0)):
        var j := i % count
        var before: Vector3 = points[(j-1+count)%count] if closed else points[maxi(0,j-1)]
        var after: Vector3 = points[(j+1)%count] if closed else points[mini(count-1,j+1)]
        var tangent := (after-before)*0.16
        curve.add_point(points[j],-tangent,tangent)
    return curve.get_baked_points()

func surface(label: String, vertices: PackedVector3Array, triangles: PackedInt32Array, tint: Color, solid := false) -> MeshInstance3D:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for v in vertices:
        st.set_normal(Vector3.UP)
        st.add_vertex(v)
    for index in triangles: st.add_index(index)
    var node := MeshInstance3D.new()
    node.name = label
    node.mesh = st.commit()
    var mat := StandardMaterial3D.new()
    mat.albedo_color = tint
    mat.roughness = 1.0
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    node.material_override = mat
    game.apartment.add_child(node,true)
    if solid: node.create_trimesh_collision()
    return node

func patch(label: String, outline: PackedVector3Array, tint: Color, solid := false) -> void:
    var polygon := PackedVector2Array()
    for p in outline: polygon.append(Vector2(p.x,p.z))
    surface(label,outline,Geometry2D.triangulate_polygon(polygon),tint,solid)

func oval(label: String, center: Vector3, rx: float, rz: float, tint: Color, irregular := false, solid := false) -> void:
    var points := PackedVector3Array()
    for i in range(96):
        var a := TAU*float(i)/96.0
        var wobble := 1.0+0.035*sin(3*a)+0.025*cos(7*a) if irregular else 1.0
        points.append(center+Vector3(cos(a)*rx*wobble,0,sin(a)*rz*wobble))
    patch(label,points,tint,solid)

func ribbon(label: String, points: PackedVector3Array, width: float, y: float, tint: Color) -> void:
    var vertices := PackedVector3Array()
    var triangles := PackedInt32Array()
    for i in range(points.size()):
        var tangent := (points[mini(i+1,points.size()-1)]-points[maxi(i-1,0)]).normalized()
        var side := Vector3(-tangent.z,0,tangent.x)*width*0.5
        var p := Vector3(points[i].x,y,points[i].z)
        vertices.append(p+side)
        vertices.append(p-side)
        if i > 0:
            var k := i*2
            triangles.append_array(PackedInt32Array([k-2,k-1,k,k-1,k+1,k]))
    surface(label,vertices,triangles,tint)

func walk(points: Array, width := 2.5, closed := false) -> void:
    var line := smooth(points,closed)
    paths.append(line)
    ribbon("Park path edging",line,width+0.28,0.075,Color("b5a88c"))
    ribbon("Winding park path",line,width,0.10,path_color)

func tree(p: Vector3, size: float) -> void:
    # Keep trees clear of vocabulary shops and the expanded civic wings.
    if p.x > -44 and p.x < 9 and p.z > 125 and p.z < 159:
        return
    if (p.x > -64 and p.x < -40 and p.z > 99 and p.z < 136) or (p.x > 39 and p.x < 62 and p.z > 122 and p.z < 152):
        return
    var node = tree_scene.instantiate()
    node.name = "LandscapeTree"
    node.position = p
    node.scale = Vector3.ONE*size
    game.apartment.add_child(node,true)

func bench(p: Vector3, angle := 0.0) -> void:
    var pieces := [
        [Vector3(0,0.52,0),Vector3(2.0,0.13,0.55)],
        [Vector3(0,0.94,0.24),Vector3(2.0,0.65,0.12)],
        [Vector3(-0.7,0.23,0),Vector3(0.12,0.46,0.5)],
        [Vector3(0.7,0.23,0),Vector3(0.12,0.46,0.5)]
    ]
    for part in pieces:
        var node := b("Park bench",p+Basis(Vector3.UP,angle)*part[0],part[1],Color("a67f5b"),"bench",true)
        node.rotation.y = angle
