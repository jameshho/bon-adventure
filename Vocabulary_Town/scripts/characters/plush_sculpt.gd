@tool
extends "res://scripts/characters/pig_sculpt.gd"

# Shared base for new plush characters sized to stand beside BonBon. Faces local -Z.
# A new animal extends this script, sets `_body_profile` and `body_top` in `_build()`,
# then calls `_put()` for each MeshInstance3D in its scene (see lion_sculpt.gd).
# It inherits the pig's body, face, pillow and limb helpers and adds soft shading,
# ground shadows, Siamese-style color points, per-area coat colors (`_color_fn`),
# sculpted fur/wool surfaces (`_furry_body`), puff clouds, tubes, sized arms/paws,
# smoothed outlines for ears and plates, and claw lines. The pig scripts stay untouched.

# Top of the body profile; the pig default is 2.203.
var body_top := 2.203
# Optional coat pattern: called with a character-space body point, returns its Color.
# Bodies built while it is set carry vertex colors; draw them with `_coat_mat()`.
var _color_fn := Callable()
# Blur the coat colors over the mesh grid. Coats drawn with `_edge()` blends
# are already smooth and stay crisper with this off.
var soften_coat := true
# BonBon's plush shading strength, so every character is lit the same way.
const BONBON_SOFTNESS := 0.28
var _plush_shader: Shader
const SculptCache := preload("res://scripts/characters/sculpt_cache.gd")

## Meshes come from the sculpt cache when this exact character was built before.
func _ready() -> void:
	SculptCache.build(self)

func _put(node_path: String, result: ArrayMesh) -> void:
	super._put(node_path, result)
	# Cast real contact shadows on the ground, like BonBon.
	var node := get_node_or_null(NodePath(node_path)) as MeshInstance3D
	if node != null:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		# Color points are placed in character space, so tell the shader where this part sits.
		var material := node.mesh.surface_get_material(0) as ShaderMaterial
		var strength: Variant = material.get_shader_parameter("point_strength") if material != null else null
		if strength != null and float(strength) > 0.0:
			var to_root := node.transform
			var parent := node.get_parent()
			while parent != self and parent is Node3D:
				to_root = (parent as Node3D).transform * to_root
				parent = parent.get_parent()
			# A Projection is the mat4 uniform's own type; a Transform3D value is lost when the
			# material is saved (sculpt_cache.gd).
			material.set_shader_parameter("part_to_root", Projection(to_root))

func _mat(tint: Color, fully_flat: bool = false) -> ShaderMaterial:
	# Cheeks and eyes stay flat so both sides read as the same color.
	return _soft_mat(tint, 0.0 if fully_flat else 1.0)

# Soft illustration shading matching BonBon (pig_art_variants.gd): `softness` is how far
# the side away from the light dims. Callers pass 0..1 as a fraction of BonBon's 0.28.
func _soft_mat(tint: Color, softness: float) -> ShaderMaterial:
	if _plush_shader == null:
		# One shared Shader per code for every character (sculpt_cache.gd).
		_plush_shader = SculptCache.shared_shader("""shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec4 tint_color : source_color = vec4(1.0);
uniform float softness : hint_range(0.0, 1.0) = 1.0;
uniform vec4 point_color : source_color = vec4(1.0);
uniform vec3 point_center = vec3(0.0);
uniform vec2 point_radii = vec2(0.1, 0.4);
uniform float point_strength = 0.0;
uniform mat4 part_to_root = mat4(1.0);
uniform bool use_vertex_color = false;
uniform float fuzz = 0.45;
varying vec3 world_normal;
varying vec3 character_pos;
varying vec3 coat;
void vertex() {
	world_normal = MODEL_NORMAL_MATRIX * NORMAL;
	coat = COLOR.rgb;
	character_pos = (part_to_root * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	// Some helper meshes wind inward; facing the camera keeps every normal outward.
	vec3 n = normalize(world_normal) * (FRONT_FACING ? 1.0 : -1.0);
	// Soft color point: full point color inside the inner radius, fading out by the outer one.
	float point = point_strength * (1.0 - smoothstep(point_radii.x, point_radii.y, distance(character_pos, point_center)));
	vec3 base = mix(use_vertex_color ? coat : tint_color.rgb, point_color.rgb, point);
	// BonBon's plush lighting: one gentle light from the upper front that only dims
	// the color (never shifts its hue), by at most `softness` on the far side.
	// Centered on the art color (BonBon's own colors were picked for the uncentered
	// version): the dim side sits a little below it and the lit side a little above,
	// so whites stay white wherever the character faces.
	float shade = 1.0 - softness + softness * max(dot(n, normalize(vec3(-0.45, 0.75, -0.65))), 0.0);
	vec3 color = base * shade / (1.0 - softness * 0.5);
	// Velvet edge: plush fabric catches light where it turns away from the viewer.
	float rim = 1.0 - clamp(dot(normalize(NORMAL) * (FRONT_FACING ? 1.0 : -1.0), VIEW), 0.0, 1.0);
	ALBEDO = mix(color, min(color * 1.16 + vec3(0.06), vec3(1.0)), fuzz * pow(rim, 2.6));
}
""")
	var m := ShaderMaterial.new()
	m.shader = _plush_shader
	m.set_shader_parameter("tint_color", tint)
	m.set_shader_parameter("softness", softness * BONBON_SOFTNESS)
	return m

# A shaded material that blends into `point` around `center` (character space), like
# a Siamese mask or dark paws. Make one per part: each part stores its own placement.
func _point_mat(tint: Color, point: Color, center: Vector3, inner: float, outer: float, strength: float = 1.0) -> ShaderMaterial:
	var m := _soft_mat(tint, 1.0)
	m.set_shader_parameter("point_color", point)
	m.set_shader_parameter("point_center", center)
	m.set_shader_parameter("point_radii", Vector2(inner, outer))
	m.set_shader_parameter("point_strength", strength)
	return m

# One 3x3 blur over the body's color grid, so pattern edges read as soft lines
# instead of stair steps along the mesh rows.
func _soften_edges(colors: PackedColorArray, rows: int, sides: int) -> PackedColorArray:
	var result := PackedColorArray()
	result.resize(colors.size())
	for j in range(rows):
		for i in range(sides):
			var sum := Color(0, 0, 0, 0)
			for dj in [-1, 0, 1]:
				var jj := clampi(j + dj, 0, rows - 1)
				for di in [-1, 0, 1]:
					sum += colors[jj * sides + posmod(i + di, sides)]
			result[j * sides + i] = sum / 9.0
	return result

# Shaded material that takes its colors from the body's `_color_fn` coat pattern.
func _coat_mat(softness: float = 1.0) -> ShaderMaterial:
	var m := _soft_mat(Color.WHITE, softness)
	m.set_shader_parameter("use_vertex_color", true)
	return m

func _make_body(material: Material) -> ArrayMesh:
	return _furry_body(material, 0.0, 1.0, 0, Callable(), 0.0, 96, 64)

# The body of revolution with sculpted fur: soft scalloped layers (`cells` = 0), or
# rows broken into `cells` staggered tufts around the body, about `lobe` apart and
# raised up to `amplitude` along the surface normal. `cell_depth` 0..1 sets how deep
# the creases between tufts go (1 = separate clumps, like wool). `mask(point, theta)`
# scales the fur per point: 0 keeps the plain body (faces, smooth bellies), >1 is thicker.
func _furry_body(material: Material, amplitude: float, lobe: float, cells: int, mask: Callable, cell_depth: float = 0.55, rows: int = 220, sides: int = 128) -> ArrayMesh:
	var points := PackedVector3Array()
	var colors := PackedColorArray()
	var faces := PackedInt32Array()
	var arc := 0.0
	var previous := Vector2.ZERO
	for j in range(rows + 1):
		var yy := lerpf(0.17, body_top, float(j) / float(rows))
		var size := _section(yy)
		var mean := Vector2((size.x + size.y) * 0.5, yy)
		if j > 0:
			arc += mean.distance_to(previous)
		previous = mean
		# Outward normal of the side profile, so fur on the crown pushes up as well as out.
		var below := _section(maxf(0.17, yy - 0.01))
		var above := _section(minf(body_top, yy + 0.01))
		var tangent := Vector2((above.x + above.y - below.x - below.y) * 0.5, minf(body_top, yy + 0.01) - maxf(0.17, yy - 0.01))
		var normal := Vector2(tangent.y, -tangent.x).normalized()
		for i in range(sides):
			var theta := TAU * float(i) / float(sides)
			var base := Vector3(cos(theta) * size.x, yy, sin(theta) * size.y)
			var push := 0.0
			if amplitude > 0.0:
				var amount := float(mask.call(base, theta))
				if amount > 0.0:
					# Rounded lobes with soft creases between rows; the gentle wave keeps rows organic.
					var wave := arc / maxf(lobe, 0.001) + 0.22 * sin(theta * 7.0)
					# A `lobe` of 0 gives a smooth raised layer; the mask then draws any scallops.
					var bump := 1.0 if lobe <= 0.0 else pow(absf(sin(PI * wave)), 0.7)
					if cells > 0:
						var shift := PI * 0.5 if posmod(floori(wave), 2) == 1 else 0.0
						bump *= 1.0 - cell_depth + cell_depth * pow(absf(sin(theta * float(cells) * 0.5 + shift)), 0.45)
					push = amplitude * amount * bump
			points.append(Vector3(cos(theta) * (size.x + push * normal.x), yy + push * normal.y, sin(theta) * (size.y + push * normal.x)))
			colors.append(_color_fn.call(base) if _color_fn.is_valid() else Color.WHITE)
	for j in range(rows):
		for i in range(sides):
			var k := (i + 1) % sides
			var low := j * sides + i
			var next_low := j * sides + k
			var high := (j + 1) * sides + i
			var next_high := (j + 1) * sides + k
			faces.append_array(PackedInt32Array([low, high, next_low, next_low, high, next_high]))
	if _color_fn.is_valid() and soften_coat:
		colors = _soften_edges(colors, rows + 1, sides)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(points.size()):
		tool.set_color(colors[k])
		tool.add_vertex(points[k])
	for index in faces:
		tool.add_index(index)
	tool.generate_normals()
	var mesh: ArrayMesh = tool.commit()
	mesh.surface_set_material(0, material)
	return mesh

func _front_z(xx: float, yy: float) -> float:
	var r := _section(clampf(yy, 0.17, body_top))
	var fraction := clampf(xx / r.x, -0.995, 0.995)
	return -r.y * sqrt(maxf(0.0, 1.0 - fraction * fraction))

# Depth of a point on a `_face_oval(cx, cy, rx, ry, bump)` surface, for features drawn on it.
func _oval_z(xx: float, yy: float, cx: float, cy: float, rx: float, ry: float, bump: float) -> float:
	var radial := Vector2((xx - cx) / rx, (yy - cy) / ry).length()
	return _front_z(xx, yy) - 0.026 - bump * maxf(0.0, 1.0 - radial * radial)

# Overlapping ellipsoids merged into one mesh: reads as one soft cloud shape.
func _blobs(puffs: Array, material: Material) -> ArrayMesh:
	var sides := 28
	var rings := 16
	var verts := PackedVector3Array()
	var tris := PackedInt32Array()
	for puff in puffs:
		var c: Vector3 = puff[0]
		var r: Vector3 = puff[1]
		var base := verts.size()
		for j in range(rings + 1):
			var phi := PI * float(j) / float(rings)
			for i in range(sides):
				var theta := TAU * float(i) / float(sides)
				verts.append(c + Vector3(sin(phi) * cos(theta) * r.x, cos(phi) * r.y, sin(phi) * sin(theta) * r.z))
		for j in range(rings):
			for i in range(sides):
				var k := (i + 1) % sides
				var a := base + j * sides + i
				var b := base + j * sides + k
				var d := base + (j + 1) * sides + i
				var e := base + (j + 1) * sides + k
				tris.append_array(PackedInt32Array([a, b, d, b, e, d]))
	return _surface(verts, tris, material)

# Round tube along a path, with rounded closed ends.
func _tube(control: Array, control_radii: Array, material: Material) -> ArrayMesh:
	# Catmull-Rom resampling turns the control points into a smooth curve.
	var path: Array = []
	var radii: Array = []
	var steps := 6 if control.size() > 3 else 1
	for j in range(control.size() - 1):
		var a: Vector3 = control[maxi(j - 1, 0)]
		var b: Vector3 = control[j]
		var c: Vector3 = control[j + 1]
		var d: Vector3 = control[mini(j + 2, control.size() - 1)]
		for k in range(steps):
			var t := float(k) / float(steps)
			path.append(0.5 * ((2.0 * b) + (c - a) * t + (2.0 * a - 5.0 * b + 4.0 * c - d) * t * t + (-a + 3.0 * b - 3.0 * c + d) * t * t * t))
			radii.append(lerpf(float(control_radii[j]), float(control_radii[j + 1]), t))
	path.append(control[control.size() - 1])
	radii.append(control_radii[control_radii.size() - 1])
	var sides := 20
	var verts := PackedVector3Array()
	var tris := PackedInt32Array()
	var count := path.size()
	var normal := Vector3.FORWARD
	for j in range(count):
		var p: Vector3 = path[j]
		var tangent: Vector3 = (path[mini(j + 1, count - 1)] - path[maxi(j - 1, 0)]).normalized()
		# Parallel-transport the frame so the tube never twists.
		normal = (normal - tangent * normal.dot(tangent)).normalized()
		if normal.length() < 0.1:
			normal = tangent.cross(Vector3.UP).normalized()
		var binormal := tangent.cross(normal)
		for i in range(sides):
			var theta := TAU * float(i) / float(sides)
			verts.append(p + (normal * cos(theta) + binormal * sin(theta)) * float(radii[j]))
	for j in range(count - 1):
		for i in range(sides):
			var k := (i + 1) % sides
			var a := j * sides + i
			var b := j * sides + k
			var c := (j + 1) * sides + i
			var d := (j + 1) * sides + k
			tris.append_array(PackedInt32Array([a, c, b, b, c, d]))
	for end in [0, count - 1]:
		var tip := verts.size()
		var step: Vector3 = (path[end] - path[1 if end == 0 else count - 2]).normalized()
		verts.append(path[end] + step * float(radii[end]) * 0.8)
		for i in range(sides):
			var k := (i + 1) % sides
			var a: int = end * sides + i
			var b: int = end * sides + k
			if end == 0:
				tris.append_array(PackedInt32Array([tip, a, b]))
			else:
				tris.append_array(PackedInt32Array([tip, b, a]))
	return _surface(verts, tris, material)

func _circle(center: Vector2, radius: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	var count := 64
	for i in range(count):
		var theta := TAU * float(i) / float(count)
		result.append(center + Vector2(cos(theta), sin(theta)) * radius)
	return result

# Two short claw lines on the front of each foot made by the pig `_foot` helper.
func _toes(sign_x: float, material: Material) -> ArrayMesh:
	return _claw_lines(sign_x * 0.190, -0.279, [-0.045, 0.045], material)

# Vertical claw lines on the front of a foot centered at `foot_x`, front surface at `front_z`.
func _claw_lines(foot_x: float, front_z: float, offsets: Array, material: Material, height: float = 0.07) -> ArrayMesh:
	var parts: Array = []
	for offset in offsets:
		var xx: float = foot_x + float(offset)
		parts.append(_tube([Vector3(xx, 0.030, front_z), Vector3(xx, 0.030 + height * 0.5, front_z - 0.005), Vector3(xx, 0.030 + height, front_z)], [0.010, 0.011, 0.010], material))
	return _merge(parts, material)

# Soft 0..1 blend for coat patterns: `inside` is a signed distance, positive inside.
func _edge(inside: float, width: float = 0.015) -> float:
	return smoothstep(-width, width, inside)

# BonBon's flat-backed mitten arm (pig_art_variants.gd), hung from the body side at
# height `y` and scaled by `size`, so it blends into the body with no visible joint.
func _mitten_arm(sign_x: float, y: float, size: float, material: Material, z: float = 0.0) -> ArrayMesh:
	var root := Vector2(_section(y).x - 0.06, y)
	var contour := _bezier(Vector2(0.65, 1.22), [
		[Vector2(0.70, 1.17), Vector2(0.74, 1.12), Vector2(0.86, 1.08)],
		[Vector2(0.98, 1.04), Vector2(0.98, 0.91), Vector2(0.88, 0.89)],
		[Vector2(0.80, 0.86), Vector2(0.76, 0.89), Vector2(0.72, 0.95)],
		[Vector2(0.66, 1.00), Vector2(0.63, 1.14), Vector2(0.65, 1.22)]
	], 16)
	for i in range(contour.size()):
		contour[i] = root + (contour[i] - Vector2(0.65, 1.22)) * size
	if sign_x < 0:
		contour = _mirror(contour)
	return _pillow(contour, z - 0.17 * size, z + 0.18 * size, material)

# Center of a `_mitten_arm` paw tip, for color points like white mittens.
func _mitten_tip(sign_x: float, y: float, size: float) -> Vector3:
	return Vector3(sign_x * (_section(y).x - 0.06 + 0.27 * size), y - 0.27 * size, 0.0)

# The pig's stubby arm, resized: `root` is where it leaves the body on the +X side.
func _nub_arm(sign_x: float, root: Vector3, length: float, radius: float, material: Material) -> ArrayMesh:
	var centers: Array[Vector3] = []
	var radii: Array[Vector2] = []
	var offsets := [0.0, 0.04, 0.08, 0.13, 0.18, 0.21, 0.235]
	var yr := [0.090, 0.114, 0.147, 0.154, 0.142, 0.100, 0.003]
	var zr := [0.091, 0.115, 0.152, 0.160, 0.146, 0.107, 0.003]
	for j in range(offsets.size()):
		var a: float = float(offsets[j]) * length / 0.235
		centers.append(Vector3(sign_x * (root.x + a), root.y - 0.28 * a, root.z))
		radii.append(Vector2(float(yr[j]) * radius / 0.154, float(zr[j]) * radius / 0.154))
	return _limb_rings(centers, radii, material)

# The pig's rounded foot, resized: half-widths `rx`/`rz`, centered at x = sign_x * `x`.
func _paw(sign_x: float, x: float, z: float, height: float, rx: float, rz: float, material: Material) -> ArrayMesh:
	var centers: Array[Vector3] = []
	var radii: Array[Vector2] = []
	var yvals := [0.002, 0.025, 0.050, 0.085, 0.125, 0.170, 0.208, 0.238]
	var xr := [0.005, 0.113, 0.143, 0.159, 0.151, 0.128, 0.082, 0.005]
	var zr := [0.005, 0.123, 0.161, 0.172, 0.163, 0.132, 0.089, 0.005]
	for j in range(yvals.size()):
		centers.append(Vector3(sign_x * x, float(yvals[j]) * height / 0.238, z))
		radii.append(Vector2(float(xr[j]) * rx / 0.159, float(zr[j]) * rz / 0.172))
	return _limb_rings(centers, radii, material, 1)

# Rounded triangle ear outline pointing up from `base_center`, leaning by `tilt` radians.
func _ear_triangle(base_center: Vector2, width: float, height: float, tilt: float) -> PackedVector2Array:
	var outline := _smooth_outline(PackedVector2Array([Vector2(-width * 0.5, 0.0), Vector2(0.0, height), Vector2(width * 0.5, 0.0)]), 5)
	for i in range(outline.size()):
		outline[i] = base_center + outline[i].rotated(tilt)
	return outline

# Chaikin corner cutting: rounds a rough polygon (floppy ears, fur fringes, plates)
# into a soft plush outline. Zig-zag points become scallops.
func _smooth_outline(points: PackedVector2Array, passes: int = 4) -> PackedVector2Array:
	var result := points
	for pass_index in range(passes):
		var smoother := PackedVector2Array()
		for i in range(result.size()):
			var a := result[i]
			var b := result[(i + 1) % result.size()]
			smoother.append(a.lerp(b, 0.25))
			smoother.append(a.lerp(b, 0.75))
		result = smoother
	return result

# Rounded downward-pointing triangle nose.
func _nose_shape(center: Vector2, half_width: float, half_height: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	var count := 60
	for i in range(count):
		var theta := TAU * float(i) / float(count)
		var xx := cos(theta) * half_width
		var yy := sin(theta) * half_height
		xx *= lerpf(0.42, 1.0, clampf((yy + half_height) / (2.0 * half_height), 0.0, 1.0))
		result.append(center + Vector2(xx, yy))
	return result

# Re-places a finished mesh, e.g. a pillow outline built flat and turned to face sideways.
func _moved(mesh: ArrayMesh, placement: Transform3D) -> ArrayMesh:
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var normal_basis := placement.basis.inverse().transposed()
	for i in range(verts.size()):
		verts[i] = placement * verts[i]
		normals[i] = (normal_basis * normals[i]).normalized()
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	# A mirroring placement (like SIDEWAYS) turns triangles inside out; the shader
	# picks the lit side from the winding, so restore it or bumps shade as dents.
	if placement.basis.determinant() < 0.0:
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		for i in range(0, indices.size(), 3):
			var swap := indices[i + 1]
			indices[i + 1] = indices[i + 2]
			indices[i + 2] = swap
		arrays[Mesh.ARRAY_INDEX] = indices
	var moved := ArrayMesh.new()
	moved.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	moved.surface_set_material(0, mesh.surface_get_material(0))
	return moved

# Swaps x and z: an outline drawn as (depth, height) becomes a plate on the center line.
const SIDEWAYS := Transform3D(Basis(Vector3(0, 0, 1), Vector3(0, 1, 0), Vector3(1, 0, 0)), Vector3.ZERO)

func _merge(meshes: Array, material: Material) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for mesh in meshes:
		tool.append_from(mesh, 0, Transform3D.IDENTITY)
	var merged: ArrayMesh = tool.commit()
	merged.surface_set_material(0, material)
	return merged
