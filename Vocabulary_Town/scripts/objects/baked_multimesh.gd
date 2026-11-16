extends MultiMeshInstance3D
## A MultiMesh whose instance data is saved in the scene as a plain float array.
## Headless bakes run on the dummy renderer, which keeps no MultiMesh instance data, so a
## MultiMesh filled at bake time would be saved with every instance at the origin. The bake
## stores the data here (scripts/buildings/monument_plaza.gd, tulips) and it is applied on load.
## Layout per instance: 12 transform floats (Godot's TRANSFORM_3D buffer order), then 4
## colour floats when the MultiMesh uses colours.
@export var instance_buffer := PackedFloat32Array()

func _ready() -> void:
	if multimesh and not instance_buffer.is_empty():
		multimesh.buffer = instance_buffer
