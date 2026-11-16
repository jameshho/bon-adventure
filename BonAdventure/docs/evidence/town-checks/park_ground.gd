extends RefCounted
## Park ground height for the park checks, read from the saved mesh
## (PublicGarden/Rolling park ground, a 1-unit grid in town coordinates, vertices 0.025 above
## the lawn relief). Replaces the analytic park_terrain.gd height_at() that the startup pass used
## to build that mesh (pass deleted 6 Nov 2026). Town-local points (+X west, +Z north); grid
## points are exact, others are interpolated; 0 off the mesh (level ground, roads, pads, water).
const LIFT := .025
var heights := {}

func _init(town: Node3D) -> void:
	var ground: MeshInstance3D = town.get_node("PublicGarden/Rolling park ground")
	var to_town := preload("res://scripts/world/modular_town.gd").town_transform(town, ground)
	for surface in ground.mesh.get_surface_count():
		for v in ground.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
			var p: Vector3 = to_town * v
			heights[Vector2i(roundi(p.x), roundi(p.z))] = maxf(0.0, p.y - LIFT)

func grid(x: int, z: int) -> float:
	return heights.get(Vector2i(x, z), 0.0)

func height_at(p: Vector3) -> float:
	var x := floori(p.x)
	var z := floori(p.z)
	var fx := p.x - x
	var fz := p.z - z
	return lerpf(lerpf(grid(x, z), grid(x + 1, z), fx), lerpf(grid(x, z + 1), grid(x + 1, z + 1), fx), fz)
