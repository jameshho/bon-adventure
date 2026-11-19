extends RefCounted
## EXPERIMENT (18 Nov 2026, not used by the game): one shared attachment rig for the nine plush
## characters, measured from each sculpt's own meshes instead of typed per species.
##
## The plush characters have no skeleton. Each is a root at the floor between the feet, facing
## -Z, with parts Torso (body + head), Head (face group), Arm / Arm_2, Foot / Foot_2 and Tail, all
## with their origin at the character's origin (docs/guides/COMPONENTS.md#plush-characters). The
## walk (player_controller.gd animate_bonbon) turns the arms about BonBon's shoulder
## (±0.65, 1.22, 0) and slides the feet. This file:
##   measure(figure)  the anchors of one figure at rest, in its model space:
##       shoulder_l/r  where the arm leaves the body: the arm mesh's inner top corner (for BonBon
##                     this is (±0.645, 1.22, -0.01), the walk's own constant)
##       hand_l/r      the paw tip: the centre of the arm vertices farthest from the shoulder
##       hip_l/r       top centre of each foot; foot_l/r bottom centre (the ground contact)
##       height        top of everything but the tail; crown = top of Torso (+ mane / wool)
##       collar        the costume data's collar_y (art-directed: below chin and hanging ears)
##   walk(...)         animate_bonbon's arithmetic unchanged, except the arm pivot comes from the
##                     figure's own shoulder (ORIGINAL_PIVOT reproduces today's walk exactly)
##   fit(costume_fit, profile)  the costume data's species entry with measured shoulder / hand
##   attach_sleeves(figure, costume)  sleeves moved onto the arms they cover, so they swing
##                     (generalises plush_costume.gd dress_player(), which only does the player)

const ORIGINAL_PIVOT := Vector3(0.65, 1.22, 0.0)
const PARTS := ["Arm", "Arm_2", "Foot", "Foot_2"]


static func _vertices_in(figure: Node3D, node: Node3D) -> PackedVector3Array:
	var out := PackedVector3Array()
	var to_root := figure.global_transform.affine_inverse()
	for mi in ([node] if node is MeshInstance3D else []) + node.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null or not m.visible:
			continue
		var xf: Transform3D = to_root * m.global_transform
		for s in m.mesh.get_surface_count():
			var arrays := m.mesh.surface_get_arrays(s)
			for p in arrays[Mesh.ARRAY_VERTEX]:
				out.append(xf * p)
	return out


static func _box(points: PackedVector3Array) -> AABB:
	var box := AABB(points[0], Vector3.ZERO)
	for p in points:
		box = box.expand(p)
	return box


## Anchors of `figure` at its rest pose. Arm / Arm_2 are the character's left (-X) / right (+X).
static func measure(figure: Node3D, collar := 1.25) -> Dictionary:
	var profile := {"collar": collar}
	for pair in [["Arm", "l"], ["Arm_2", "r"]]:
		var points := _vertices_in(figure, figure.get_node(pair[0]))
		var box := _box(points)
		var side := signf(box.get_center().x)
		var inner := box.position.x if side > 0 else box.end.x
		var shoulder := Vector3(inner, box.end.y, box.get_center().z)
		var far := 0.0
		for p in points:
			far = maxf(far, p.distance_to(shoulder))
		var tip := Vector3.ZERO
		var n := 0
		for p in points:
			if p.distance_to(shoulder) > far * 0.85:
				tip += p
				n += 1
		profile["shoulder_" + pair[1]] = shoulder
		profile["hand_" + pair[1]] = tip / maxf(n, 1)
		profile["arm_length_" + pair[1]] = (tip / maxf(n, 1)).distance_to(shoulder)
	for pair in [["Foot", "l"], ["Foot_2", "r"]]:
		var box := _box(_vertices_in(figure, figure.get_node(pair[0])))
		var c := box.get_center()
		profile["hip_" + pair[1]] = Vector3(c.x, box.end.y, c.z)
		profile["foot_" + pair[1]] = Vector3(c.x, box.position.y, c.z)
		profile["foot_size_" + pair[1]] = box.size
	var body := _box(_vertices_in(figure, figure.get_node("Torso")))
	profile["torso"] = body
	var all := PackedVector3Array()
	for child in figure.get_children():
		if child is Node3D and str(child.name) != "Tail" and str(child.name) != "Costume":
			all.append_array(_vertices_in(figure, child))
	profile["height"] = _box(all).end.y
	profile["bounds"] = _box(all)
	return profile


## The costume system's species entry with the measured arm anchors (right side, as the data
## stores them; plush_costume.gd mirrors for the left). Everything else stays art-directed.
static func fit(species_fit: Dictionary, profile: Dictionary) -> Dictionary:
	var out := species_fit.duplicate(true)
	var s: Vector3 = profile["shoulder_r"]
	var h: Vector3 = profile["hand_r"]
	out["shoulder"] = [s.x, s.y, s.z]
	out["hand"] = [h.x, h.y, h.z]
	return out


static func rest_poses(figure: Node3D) -> Dictionary:
	var rest := {}
	for path in PARTS:
		rest[path] = (figure.get_node(path) as Node3D).transform
	return rest


## One frame of the walk. `visual` is the node that bobs (the player's Visual); `pivot_l` /
## `pivot_r` are null for the original walk (BonBon's constant), else the measured shoulders.
## Body: the same numbers as player_controller.gd animate_bonbon (18 Nov 2026).
static func walk(visual: Node3D, figure: Node3D, rest: Dictionary, phase: float, weight: float, profile = null) -> void:
	visual.position.y = absf(sin(phase)) * 0.055 * weight
	for key in PARTS:
		var part: Node3D = figure.get_node(key)
		var pose: Transform3D = rest[key]
		var side := -1.0 if str(key).ends_with("_2") else 1.0
		var swing := sin(phase) * side * weight
		if str(key).begins_with("Arm"):
			var pivot := Vector3(-ORIGINAL_PIVOT.x * side, ORIGINAL_PIVOT.y, 0)
			if profile != null:
				pivot = profile["shoulder_r" if key == "Arm_2" else "shoulder_l"]
			var turn := Basis(Vector3.RIGHT, swing * 0.42)
			part.transform = Transform3D(turn * pose.basis, pose.origin + pivot - turn * pivot)
		else:
			part.transform = pose
			part.position += Vector3(0, maxf(0, swing) * 0.12, swing * 0.16)


## Sleeves (and anything else built over an arm) move from the Costume node onto that arm, as
## plush_costume.gd dress_player() does for the player, so they follow the swing.
static func attach_sleeves(figure: Node3D, costume: Node3D, rest: Dictionary) -> int:
	var moved := 0
	for piece in costume.get_children():
		if not (piece is MeshInstance3D and str(piece.name).begins_with("Sleeve")):
			continue
		var in_figure: Transform3D = costume.transform * (piece as MeshInstance3D).transform
		var arm_name := "Arm" if (in_figure * (piece as MeshInstance3D).get_aabb()).get_center().x < 0 else "Arm_2"
		var arm: Node3D = figure.get_node(arm_name)
		costume.remove_child(piece)
		arm.add_child(piece)
		piece.transform = (rest[arm_name] as Transform3D).affine_inverse() * in_figure
		moved += 1
	return moved
