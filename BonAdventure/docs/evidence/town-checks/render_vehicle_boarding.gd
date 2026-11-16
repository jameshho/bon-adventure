extends SceneTree
# Renders Subi's boarding/exit sequence in the Home garage and a door on another
# vehicle. Overwrites only docs/evidence/vehicle-boarding-20261029/*.png.
const OUT := "res://docs/evidence/vehicle-boarding-20261029/"
var game
var home: Node3D
var camera: Camera3D
func _initialize(): run.call_deferred()
func step(vehicle,count: int,gas := 0.0,brake := false) -> void:
    for i in range(count):
        vehicle.drive_step(1.0/60,gas,0,1.0 if brake else 0.0)
        game.player._physics_process(1.0/60)
func until(vehicle,progress: float,gas := 0.0) -> void:
    while vehicle.boarding_busy() and absf(vehicle.boarding_progress-progress)>.012:
        step(vehicle,1,gas)
func shot(title: String,from: Vector3,at: Vector3) -> void:
    camera.global_position=home.to_global(from)
    camera.look_at(home.to_global(at))
    for i in range(6): await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(OUT+title+".png")
func run():
    root.size=Vector2i(1280,800)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.hud.hide()
    for v in game.driveable_vehicles: v.set_physics_process(false)
    home=game.apartment.get_node("RelocatedSites/Home")
    home.get_node("Home roof").visible=false
    var garage=game.garage_door()
    if garage!=null:
        garage.toggle()
        for i in range(240): garage._physics_process(1.0/60)
    camera=Camera3D.new()
    camera.fov=55
    game.add_child(camera)
    camera.current=true
    await physics_frame
    await physics_frame
    var subi=home.get_node("SubaruOutback")
    var eye:=Vector3(12.6,2.3,24.2)
    var target:=Vector3(9.4,1.0,18.8)
    game.player.global_position=subi.to_global(Vector3(-.8,.1,2.6))
    game.player.rotation.y=PI
    await shot("1-approach",eye,target)
    game.toggle_vehicle()
    until(subi,.42)
    await shot("2-door-open",eye,target)
    until(subi,.7)
    await shot("3-climbing-in",eye,target)
    until(subi,1.0)
    await shot("4-seated-door-closed",eye,target)
    step(subi,100,1.0)
    step(subi,150,0,true)
    var p: Vector3=home.to_local(subi.global_position)
    await shot("5-driven-out",p+Vector3(5,2.6,5.5),p+Vector3(0,.8,0))
    game.toggle_vehicle()
    until(subi,.62)
    await shot("6-getting-out",p+Vector3(5,2.6,5.5),p+Vector3(0,.8,0))
    until(subi,0.0)
    step(subi,1)
    await shot("7-on-foot",p+Vector3(5,2.6,5.5),p+Vector3(0,.8,0))
    # Another body type uses the same door builder.
    var police=game.apartment.get_node("Vehicles/Police_Car")
    police.boarding_progress=.6
    police.update_driver_door()
    var q: Vector3=home.to_local(police.global_position)
    await shot("8-police-door",q+police.global_basis.z.normalized()*6.5/1.0+Vector3(-3,2.4,0),q+Vector3(0,.9,0))
    print("BOARDING RENDER subi on foot=",game.player.riding_vehicle==null," at ",home.to_local(game.player.global_position))
    quit()
