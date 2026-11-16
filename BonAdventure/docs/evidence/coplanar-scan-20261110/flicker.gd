extends SceneTree
## Coplanar-fix flicker views (10 Nov 2026), graphics required; method of
## docs/evidence/supermarket-visual-20261108/flicker.gd: each view is drawn at six camera positions
## 0.2 mm apart, z-fighting faces swap colour between such frames while normal surfaces do not,
## and every pixel that changes by more than 60/765 is counted ("FLICKER <view> <px>") and
## painted magenta in <out>/<prefix>-<view>.png (the first frame).
##   VT_FOCUS=all godot --path . --resolution 1200x800 --script res://docs/evidence/coplanar-scan-20261110/flicker.gd -- <out dir> <prefix> [view,view...]
## Use an isolated HOME (Main may save progress). Writes only into <out dir>.
func _initialize(): run.call_deferred()
func run():
	if DisplayServer.get_name()=="headless": quit(1); return
	# A window behind others stalls on vsync (it drew one view in 10 minutes); draw without it.
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var args:=OS.get_cmdline_user_args()
	var folder:String=args[0]
	var prefix:String=args[1]
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	game.hud.hide()
	var town: Node3D=game.apartment
	var camera:=Camera3D.new()
	game.add_child(camera)
	camera.current=true
	camera.near=.08
	camera.far=900.0
	# [name, eye, target, fov] in town coordinates (+X west, +Z north); the largest pairs of the scan.
	var views:=[
		["hospital-parapet",Vector3(41.5,18.6,240.0),Vector3(46.8,17.1,244.5),55.0],
		["bridge-pier",Vector3(-7.5,4.6,135.5),Vector3(-10.0,2.36,139.0),55.0],
		["bakery-hutch",Vector3(137.6,1.25,170.4),Vector3(137.0,.6,172.9),60.0],
		["mystery-sign",Vector3(114.6,2.4,79.0),Vector3(111.9,2.15,77.8),55.0],
		["electronics-theatre",Vector3(143.2,1.7,137.8),Vector3(140.6,1.5,137.0),60.0],
		["pizza-wall-base",Vector3(-17.8,.9,32.5),Vector3(-22.0,.1,34.0),55.0],
		["warehouse-wall-base",Vector3(-16.0,.9,236.5),Vector3(-20.0,-.05,238.8),55.0],
	]
	var only:=args[2].split(",") if args.size()>2 else PackedStringArray()
	for spec in views:
		if not only.is_empty() and not spec[0] in only: continue
		camera.fov=spec[3]
		var eye:Vector3=town.to_global(spec[1])
		var target:Vector3=town.to_global(spec[2])
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
		marked.save_png(folder+"/"+prefix+"-"+spec[0]+".png")
		print("FLICKER %s %d" % [spec[0],changed])
	print("COPLANAR FLICKER CAPTURE done")
	quit()
