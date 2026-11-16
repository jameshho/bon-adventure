extends SceneTree
## Supermarket surface-flicker views (8 Nov 2026, step surface_gaps); graphics required.
## VT_FOCUS=supermarket godot --path . --resolution 1200x800 --script res://docs/evidence/supermarket-visual-20261108/flicker.gd -- <prefix> [view,view...]
## Writes <prefix>-flicker-<view>.png into this folder only (use an isolated HOME: Main may save
## progress). Each view is drawn at six camera positions 0.2 mm apart; z-fighting faces swap
## colour between such frames while normal surfaces do not, so the count of pixels that change
## by more than 60/765 between neighbouring frames is printed per view ("FLICKER <view> <px>").
## The PNG is the first frame with every changed pixel painted magenta.
func _initialize(): run.call_deferred()
func run():
	if DisplayServer.get_name()=="headless": quit(1); return
	var folder:="res://docs/evidence/supermarket-visual-20261108"
	var args:=OS.get_cmdline_user_args()
	var prefix:=(args[0]+"-") if args.size()>0 else ""
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	game.hud.hide()
	var market: Node3D=game.apartment.get_node("RelocatedSites/Supermarket")
	var camera:=Camera3D.new()
	game.add_child(camera)
	camera.current=true
	camera.near=.08
	camera.far=900.0
	# [name, eye, target, fov]: market-local; fridge backs face the deli aisle (z 50.6..56.15).
	var views:=[
		["fridge-near",Vector3(-32.8,1.0,52.6),Vector3(-32.8,.5,50.6),60.0],
		["fridge-far",Vector3(-28.5,1.7,55.6),Vector3(-33.0,.9,50.6),60.0],
		["deli-near",Vector3(-33.0,.8,54.2),Vector3(-33.0,.4,56.15),60.0],
		["deli-far",Vector3(-27.0,1.7,51.2),Vector3(-34.0,.6,56.15),60.0],
		["gondola-near",Vector3(-41.4,1.2,45.6),Vector3(-42.64,.9,46.6),55.0],
		["gondola-far",Vector3(-41.3,1.7,41.2),Vector3(-42.6,.8,48.0),60.0],
	]
	var only:=args[1].split(",") if args.size()>1 else PackedStringArray()
	for spec in views:
		if not only.is_empty() and not spec[0] in only: continue
		camera.fov=spec[3]
		var eye:Vector3=market.to_global(spec[1])
		var target:Vector3=market.to_global(spec[2])
		var side:=(target-eye).cross(Vector3.UP).normalized()
		var frames:=[]
		for k in range(6):
			var shift:=side*.0002*k+Vector3.UP*.0001*k
			camera.global_position=eye+shift
			camera.look_at(target+shift)
			for i in range(6): await process_frame
			await RenderingServer.frame_post_draw
			frames.append(root.get_texture().get_image())
		var base:Image=frames[0]
		var marked:=base.duplicate() as Image
		var w:=base.get_width()
		var data:=[]
		for f in frames:
			(f as Image).convert(Image.FORMAT_RGB8)
			data.append((f as Image).get_data())
		var changed:=0
		for i in range(0,(data[0] as PackedByteArray).size(),3):
			for k in range(1,data.size()):
				var a:PackedByteArray=data[k-1]
				var b:PackedByteArray=data[k]
				if absi(a[i]-b[i])+absi(a[i+1]-b[i+1])+absi(a[i+2]-b[i+2])>60:
					changed+=1
					marked.set_pixel((i/3)%w,(i/3)/w,Color.MAGENTA)
					break
		marked.save_png(folder+"/"+prefix+"flicker-"+spec[0]+".png")
		print("FLICKER %s %d" % [spec[0],changed])
	print("SUPERMARKET FLICKER CAPTURE done")
	quit()
