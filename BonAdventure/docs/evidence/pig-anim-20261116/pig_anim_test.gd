extends Node3D
## Test stage for the clay pig animation pilot (16 Nov 2026): the original clay pig display
## (scenes/animals/pig_clay.tscn, static) beside the rigged pig (scenes/animals/pig_clay_rigged.scn)
## wandering with the zoo's park_animals.gd, blinked by one PlushLife (plush_life.gd) that
## follows clay_animator.gd's group. Not in the town.
##   godot --path . res://docs/evidence/pig-anim-20261116/pig_anim_test.tscn
## capture.gd instances this stage for its views and timings.

const PlushLife := preload("res://scripts/characters/plush_life.gd")
const ClayAnimator := preload("res://scripts/characters/clay_animator.gd")
const Animals := preload("res://scripts/world/park_animals.gd")

## Set before adding to the tree: false keeps the camera out (capture.gd brings its own).
var with_camera := true
var original: Node3D
var wanderer: Node3D
var rigged: Node3D
var life: Node


func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("fdf0e9")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("fff4e6")
	env.environment.ambient_light_energy = 0.6
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_energy = 0.9
	add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(12, 12)
	ground.mesh = plane
	var grass := StandardMaterial3D.new()
	grass.albedo_color = Color("d9e8c4")
	ground.material_override = grass
	add_child(ground)
	original = load("res://scenes/animals/pig_clay.tscn").instantiate()
	original.position = Vector3(1.0, 0, 0)
	add_child(original)
	wanderer = make_wanderer(Vector3(-1.0, 0, 0))
	rigged = wanderer.get_child(0)
	life = PlushLife.new()
	add_child(life)
	life.follow_group(ClayAnimator.BLINK_GROUP)
	if with_camera:
		var cam := Camera3D.new()
		cam.fov = 40
		cam.position = Vector3(0, 2.2, 5.5)
		add_child(cam)
		cam.look_at(Vector3(0, 0.4, 0))
		cam.current = true


## A rigged pig inside a park_animals.gd wanderer, set up like base.gd's _clay_roamer (the model
## turned half round: clay models face -Z, wanderers +Z), at the zoo pig's speed and pause.
func make_wanderer(at: Vector3, roam := 1.6) -> Node3D:
	var animal := Node3D.new()
	animal.name = "Pig"
	animal.set_script(Animals)
	animal.set_meta("word_key", "pig")
	var model: Node3D = load("res://scenes/animals/pig_clay_rigged.scn").instantiate()
	model.rotation.y = PI
	var footprint := model.get_node("Footprint") as CollisionObject3D
	footprint.collision_layer = 0
	footprint.collision_mask = 0
	animal.add_child(model)
	animal.position = at
	add_child(animal)
	animal.call("configure", AABB(Vector3(-0.37, 0, -0.67), Vector3(0.74, 0.95, 1.35)), Rect2())
	animal.set("radius", roam)
	return animal
