extends SceneTree
func _initialize(): run.call_deferred()
func run():
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.player.set_physics_process(false)
    game.apartment.hide() # Map projection remains live; skip the hidden 3D render.
    game.hud.toggle_map()
    for spec in [[Vector2i(1440,1000),"baked_map"],[Vector2i(1280,720),"map_default"]]:
        root.size=spec[0]
        for i in range(8): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://docs/evidence/world_expansion/"+spec[1]+".png")
        var atlas=game.hud.map_overlay.get_node("TownMinimap")
        var overlaps:=0
        for i in range(atlas.label_rects.size()):
            for j in range(i):
                if atlas.label_rects[i].intersects(atlas.label_rects[j]): overlaps+=1
        print(spec[1]," labels: ",atlas.label_rects.size(),"; overlaps: ",overlaps)
        if overlaps>0: quit(1); return
    quit()
