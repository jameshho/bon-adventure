extends SceneTree
var failures := 0
func _initialize(): run.call_deferred()
func check(condition: bool, message: String):
    if not condition:
        failures += 1
        print("FAIL: ",message)
func run():
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    var garden=game.apartment.get_node("PublicGarden")
    var batches=garden.get_node("RenderBatches")
    check(garden.get_meta("batched_mesh_count")>1500,"garden decorations batched")
    # One batch per color per 24-unit cell. Raised from 250 to 400 for the 27 Oct 2026
    # tree/bush species (316 batches, +0.5 ms median); see performance/README.md.
    check(batches.get_child_count()<400,"bounded batch count")
    var count=batches.get_child_count()
    load("res://scripts/world/garden_rendering.gd").new().build(game.apartment)
    check(batches.get_child_count()==count,"batching idempotent")
    for batch in batches.get_children():
        check(batch.multimesh.instance_count>0,"batch has instances")
    var map=game.hud.ui_root.get_node("TownMinimap")
    map.rebuild()
    check(not map.surfaces.is_empty(),"map rebuild works with animated water")
    var grass=load("res://shaders/grass.tres")
    for path in ["Natural town terrain","Central Park meadow","ParkZoo/ANIMALES SALVAJES lawn","ParkZoo/LA GRANJA lawn","PublicGarden/Lagoon island"]:
        var surface=game.apartment.get_node(path)
        check(surface.material_override==grass,"shared grass material: "+path)
        check(surface.visible,"grass remains visible after batching: "+path)
    var grass_map_surfaces=0
    for surface in map.surfaces:
        if surface.color==grass.get_shader_parameter("base_color"): grass_map_surfaces+=1
    check(grass_map_surfaces>=2,"grass map surfaces retain green shader fallback")
    check(game.apartment.get_node("Island beaches").material_override is StandardMaterial3D,"beach retains its own material")
    # Settled doors must stay exactly at their endpoint, and still respond when opened.
    for obj in game.doors:
        var state=game.doors[obj]
        if state.get("type")=="hinge":
            obj.rotation.y=0.0
            state.open=false
            game._process(1.0/60.0)
            check(obj.rotation.y==0.0,"closed hinge stays settled")
            state.open=true
            game._process(1.0/60.0)
            check(absf(obj.rotation.y)>0.001,"settled hinge resumes on interaction")
            break
    print("RENDERING CHECKS: ",failures," failures")
    quit(0 if failures==0 else 1)
