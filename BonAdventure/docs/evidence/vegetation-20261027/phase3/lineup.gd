extends SceneTree
## Bush lineup: 4 types x 3 profiles on grass, with Main's sun/sky values.
## godot --path . --resolution 1600x900 --script res://docs/evidence/vegetation-20261027/phase3/lineup.gd
const SCENES := ["shrub", "rose_bush", "fern", "hedge"]
func _initialize(): run.call_deferred()
func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    var stage := Node3D.new()
    root.add_child(stage)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-53,-18,0)
    sun.light_color = Color("fff1dc")
    sun.light_energy = 0.62
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 160.0
    stage.add_child(sun)
    var sky_material := ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color("4f8fd0")
    sky_material.sky_horizon_color = Color("c9e2ef")
    sky_material.ground_horizon_color = Color("c9e2ef")
    sky_material.ground_bottom_color = Color("6fa9bf")
    var env := WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_SKY
    env.environment.sky = Sky.new()
    env.environment.sky.sky_material = sky_material
    env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_color = Color("fff4e4")
    env.environment.ambient_light_energy = 0.50
    env.environment.tonemap_mode = Environment.TONE_MAPPER_ACES
    env.environment.adjustment_enabled = true
    env.environment.adjustment_saturation = 1.1
    env.environment.adjustment_contrast = 1.08
    env.environment.adjustment_brightness = 0.9
    stage.add_child(env)
    var ground := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(40, 30)
    ground.mesh = plane
    ground.material_override = load("res://shaders/grass.tres")
    stage.add_child(ground)
    for i in range(SCENES.size()):
        for p in range(3):
            var tree: Node3D = load("res://scenes/props/nature/species/"+SCENES[i]+".tscn").instantiate()
            tree.profile = p
            tree.position = Vector3(-4.5 + i * 3.0, 0, -3 + p * 3.0)
            stage.add_child(tree)
    var camera := Camera3D.new()
    stage.add_child(camera)
    camera.current = true
    camera.fov = 42
    camera.position = Vector3(0, 5.5, 10)
    camera.look_at(Vector3(0, 0.3, 0))
    for i in range(6): await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://docs/evidence/vegetation-20261027/phase3/lineup.png")
    print("BUSH LINEUP: ", SCENES.size() * 3, " bushes")
    quit()
