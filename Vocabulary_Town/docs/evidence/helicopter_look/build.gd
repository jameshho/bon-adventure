extends SceneTree
# Rebuilds the existing editable helicopter scene; no runtime model generator.
var craft:Node3D
var paint:StandardMaterial3D
var trim:StandardMaterial3D
var glass:StandardMaterial3D
var metal:StandardMaterial3D
var rubber:StandardMaterial3D
func material(color:Color,roughness:float=0.8)->StandardMaterial3D:
    var m=StandardMaterial3D.new()
    m.albedo_color=color
    m.roughness=roughness
    return m
func attach(node:Node,parent:Node):
    parent.add_child(node)
    node.owner=craft
func mesh_node(label:String,mesh:Mesh,pos:Vector3,mat:Material,parent:Node=null,solid:bool=false)->MeshInstance3D:
    if parent==null: parent=craft
    var n=MeshInstance3D.new()
    n.name=label
    n.mesh=mesh
    n.position=pos
    n.material_override=mat
    attach(n,parent)
    if solid:
        var body=StaticBody3D.new()
        body.name="Solid"
        attach(body,n)
        var collision=CollisionShape3D.new()
        collision.shape=mesh.create_convex_shape()
        attach(collision,body)
    return n
func box(label:String,size:Vector3,pos:Vector3,mat:Material,parent:Node=null,solid:bool=false)->MeshInstance3D:
    var mesh=BoxMesh.new()
    mesh.size=size
    return mesh_node(label,mesh,pos,mat,parent,solid)
func cylinder(label:String,radius:float,height:float,pos:Vector3,mat:Material,parent:Node=null,solid:bool=false)->MeshInstance3D:
    var mesh=CylinderMesh.new()
    mesh.top_radius=radius
    mesh.bottom_radius=radius
    mesh.height=height
    mesh.radial_segments=16
    return mesh_node(label,mesh,pos,mat,parent,solid)
func surface(label:String,points:Array,mat:Material):
    var s=SurfaceTool.new()
    s.begin(Mesh.PRIMITIVE_TRIANGLES)
    for idx in [0,1,2,0,2,3]: s.add_vertex(points[idx])
    s.generate_normals()
    return mesh_node(label,s.commit(),Vector3.ZERO,mat)
func hull(label:String,rings:Array,mat:Material,solid:bool=true):
    var vertices:Array[Vector3]=[]
    for r in rings:
        var z:float=r[0]; var w:float=r[1]; var low:float=r[2]; var high:float=r[3]
        var bevel=(high-low)*.18
        for p in [Vector2(-w*.7,low),Vector2(w*.7,low),Vector2(w,low+bevel),Vector2(w,high-bevel),Vector2(w*.7,high),Vector2(-w*.7,high),Vector2(-w,high-bevel),Vector2(-w,low+bevel)]:
            vertices.append(Vector3(p.x,p.y,z))
    var s=SurfaceTool.new()
    s.begin(Mesh.PRIMITIVE_TRIANGLES)
    for ring in range(rings.size()-1):
        for i in range(8):
            var a=ring*8+i; var b=ring*8+(i+1)%8; var c=b+8; var d=a+8
            for idx in [a,c,b,a,d,c]: s.add_vertex(vertices[idx])
    for i in range(1,7):
        for idx in [0,i,i+1]: s.add_vertex(vertices[idx])
        var end=(rings.size()-1)*8
        for idx in [end,end+i+1,end+i]: s.add_vertex(vertices[idx])
    s.generate_normals()
    return mesh_node(label,s.commit(),Vector3.ZERO,mat,null,solid)
func _initialize():
    craft=Node3D.new()
    craft.name="Helicopter"
    craft.set_script(load("res://scripts/world/driveable_vehicle.gd"))
    craft.set("helicopter",true)
    craft.set_meta("word_key","helicopter")
    paint=material(Color("343c32"))
    trim=material(Color("475044"))
    glass=material(Color("426879"),.24)
    glass.metallic=.15
    glass.cull_mode=BaseMaterial3D.CULL_DISABLED
    metal=material(Color("626960"),.48)
    rubber=material(Color("151918"))
    hull("Fuselage",[[-2.22,.45,.96,1.45],[-1.3,.94,.65,2.1],[.95,1,.65,2.13],[1.8,.56,1.05,1.93]],paint)
    # Four separate cockpit panes, framing is the exposed hull between panels.
    surface("WindshieldLeft",[Vector3(-.04,1.59,-2.11),Vector3(-.48,1.59,-2.11),Vector3(-.65,2.13,-1.32),Vector3(-.04,2.13,-1.32)],glass)
    surface("WindshieldRight",[Vector3(.48,1.59,-2.11),Vector3(.04,1.59,-2.11),Vector3(.04,2.13,-1.32),Vector3(.65,2.13,-1.32)],glass)
    for side in [-1,1]:
        var suffix="Left" if side<0 else "Right"
        surface("PilotWindow"+suffix,[Vector3(side*.96,1.4,-1.25),Vector3(side*.98,1.4,-.52),Vector3(side*.98,1.94,-.52),Vector3(side*.95,1.92,-1.25)],glass)
        box("PilotDoor"+suffix,Vector3(.035,.55,.75),Vector3(side*.96,1.08,-.9),trim)
        box("CabinDoor"+suffix,Vector3(.045,1.18,1.25),Vector3(side*1.005,1.38,.35),trim)
        box("DoorWindow"+suffix,Vector3(.025,.47,.85),Vector3(side*1.035,1.72,.3),glass)
        box("DoorRail"+suffix,Vector3(.05,.045,1.55),Vector3(side*1.04,2.01,.4),metal)
        box("DoorHandle"+suffix,Vector3(.055,.045,.19),Vector3(side*1.05,1.4,.79),metal)
        box("CabinStep"+suffix,Vector3(.3,.07,.9),Vector3(side*1.1,.65,.4),metal)
        var engine=hull("Engine"+suffix,[[-.95,.27,2.14,2.57],[.6,.3,2.13,2.64],[1.22,.24,2.14,2.48]],trim)
        engine.position.x=side*.51
        var intake=cylinder("Intake"+suffix,.21,.06,Vector3(side*.51,2.36,-.97),rubber)
        intake.rotation.x=PI/2
        var exhaust=cylinder("Exhaust"+suffix,.21,.32,Vector3(side*.51,2.35,1.2),metal)
        exhaust.rotation.x=PI/2
        var exhaust_hole=cylinder("ExhaustOpening"+suffix,.16,.015,Vector3(side*.51,2.35,1.37),rubber)
        exhaust_hole.rotation.x=PI/2
        for i in range(4):
            box("EngineVent"+suffix+str(i),Vector3(.025,.15,.045),Vector3(side*.82,2.39,.2+i*.13),rubber)
        var strut=box("MainGearStrut"+suffix,Vector3(.11,.65,.12),Vector3(side*1.01,.67,0),metal)
        strut.rotation.z=side*.3
        var wheel=cylinder("MainWheel"+suffix,.29,.3,Vector3(side*1.12,.31,0),rubber,null,true)
        wheel.rotation.z=PI/2
        var hub=cylinder("WheelHub"+suffix,.13,.315,Vector3(side*1.12,.31,0),metal)
        hub.rotation.z=PI/2
    hull("TailBoom",[[1.35,.46,1.22,1.92],[3.4,.22,1.63,2.05],[4.6,.11,1.84,2.17]],paint)
    var fin=box("TailFin",Vector3(.15,1.25,.65),Vector3(0,2.25,4.45),trim,null,true)
    fin.rotation.x=.23
    box("TailStabilizer",Vector3(2.1,.08,.48),Vector3(0,1.87,3.8),trim,null,true)
    box("TailWheelStrut",Vector3(.08,1.15,.08),Vector3(0,.9,3.35),metal)
    var tail_wheel=cylinder("TailWheel",.23,.19,Vector3(0,.31,3.35),rubber,null,true)
    tail_wheel.rotation.z=PI/2
    cylinder("RotorMast",.10,.65,Vector3(0,2.88,.12),metal)
    var rotor=Node3D.new()
    rotor.name="MainRotor"
    rotor.position=Vector3(0,3.22,.12)
    rotor.rotation.y=.24
    attach(rotor,craft)
    cylinder("Hub",.24,.13,Vector3.ZERO,metal,rotor)
    # Four individually modeled blades, all parented to the animated pivot.
    for i in range(4):
        var angle=i*PI/2
        var blade=box("Blade"+str(i),Vector3(.23,.045,3.55),Vector3(sin(angle)*2.14,0,cos(angle)*2.14),rubber,rotor)
        blade.rotation.y=angle
        var tip=box("BladeTip"+str(i),Vector3(.235,.047,.13),Vector3(sin(angle)*3.85,0,cos(angle)*3.85),metal,rotor)
        tip.rotation.y=angle
    var tail=Node3D.new()
    tail.name="TailRotor"
    tail.position=Vector3(.27,2.18,4.72)
    attach(tail,craft)
    var tail_hub=cylinder("Hub",.12,.2,Vector3.ZERO,metal,tail)
    tail_hub.rotation.z=PI/2
    for i in range(2):
        var blade=box("Blade"+str(i),Vector3(.065,1.55,.12),Vector3.ZERO,rubber,tail)
        blade.rotation.x=PI/4+i*PI/2
    var light=material(Color("dece9d"),.3)
    box("LandingLamp",Vector3(.24,.12,.04),Vector3(0,1.08,-2.23),light)
    box("NoseAntenna",Vector3(.025,.22,.025),Vector3(0,1.5,-2.1),rubber)
    box("DorsalAntenna",Vector3(.035,.25,.035),Vector3(0,2.31,1.43),rubber)
    var scene=PackedScene.new()
    scene.pack(craft)
    var result=ResourceSaver.save(scene,"res://scenes/props/vehicles/helicopter.tscn")
    print("Helicopter model saved: ",result)
    craft.free()
    quit(result)
