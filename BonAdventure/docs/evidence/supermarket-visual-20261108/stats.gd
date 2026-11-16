extends SceneTree
## Supermarket interior statistics (8 Nov 2026); read-only, prints only.
## HOME=<scratch> VT_FOCUS=supermarket godot --headless --path . --script res://docs/evidence/supermarket-visual-20261108/stats.gd
## Mesh instances, distinct override materials, drawn vertices (before batching), word roots and pick bodies under MarketInterior.
func _initialize(): run.call_deferred()
func run():
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var fit: Node3D=game.apartment.get_node("RelocatedSites/Supermarket/MarketInterior")
	var meshes:=fit.find_children("*","MeshInstance3D",true,false)
	var materials:={}
	var mesh_res:={}
	var mesh_kinds:={}
	var vertices:=0
	for m: MeshInstance3D in meshes:
		if m.mesh:
			for k in m.mesh.get_surface_count(): vertices+=(m.mesh.surface_get_arrays(k)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		if m.material_override: materials[m.material_override]=true
		if m.mesh:
			mesh_res[m.mesh]=true
			mesh_kinds[m.mesh.get_class()]=int(mesh_kinds.get(m.mesh.get_class(),0))+1
	var words:={}
	var roots:=0
	for n in fit.find_children("*","Node3D",true,false):
		if n.has_meta("word_key"):
			roots+=1
			words[str(n.get_meta("word_key"))]=int(words.get(str(n.get_meta("word_key")),0))+1
	var areas:=fit.find_children("*","CollisionObject3D",true,false).size()
	var labels:=fit.find_children("*","Label3D",true,false).size()
	print("STATS meshes=%d materials=%d mesh_resources=%d vertices=%d word_roots=%d words=%d pick_bodies=%d labels=%d" % [meshes.size(),materials.size(),mesh_res.size(),vertices,roots,words.size(),areas,labels])
	print("STATS mesh classes ",mesh_kinds)
	var keys:=words.keys()
	keys.sort()
	print("STATS words ",keys)
	quit()
