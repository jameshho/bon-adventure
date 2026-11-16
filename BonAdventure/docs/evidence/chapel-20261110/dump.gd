extends SceneTree
## Prints the node tree of a unit scene (read only).
func _init() -> void:
	var unit := "chapel"
	for a in OS.get_cmdline_user_args(): unit = a
	var root: Node = load("res://scenes/town/%s.scn" % unit).instantiate()
	_walk(root, 0)
	quit()
func _walk(n: Node, d: int) -> void:
	var s := "  ".repeat(d) + n.name + " <" + n.get_class() + ">"
	if n is Node3D:
		var t: Transform3D = n.transform
		s += " pos=%s" % [t.origin.snapped(Vector3.ONE * .01)]
		var sc := t.basis.get_scale()
		if not sc.is_equal_approx(Vector3.ONE): s += " scl=%s" % [sc.snapped(Vector3.ONE*.01)]
		if not t.basis.get_euler().is_zero_approx(): s += " rot=%s" % [(t.basis.get_euler()*57.2958).snapped(Vector3.ONE)]
	if n is MeshInstance3D and n.mesh:
		s += " mesh=%s" % n.mesh.get_class()
		if n.mesh is BoxMesh: s += " size=%s" % [n.mesh.size.snapped(Vector3.ONE*.01)]
		var m = n.get_active_material(0)
		if m is StandardMaterial3D: s += " col=%s" % [m.albedo_color.to_html(false)]
	if n is Label3D: s += " text='%s'" % n.text
	if n.has_meta("word_key"): s += " KEY=" + str(n.get_meta("word_key"))
	if n.has_meta("exterior_word"): s += " EXT=" + str(n.get_meta("exterior_word")) + " BOUNDS=" + str(n.get_meta("facade_bounds"))
	if n is CollisionShape3D and n.shape is BoxShape3D: s += " box=%s" % [n.shape.size.snapped(Vector3.ONE*.01)]
	var metas := []
	for k in n.get_meta_list(): metas.append(str(k))
	if metas: s += " meta=" + str(metas)
	print(s)
	for c in n.get_children(): _walk(c, d + 1)
