extends Node
## Day-night cycle (9 Nov 2026; guide: docs/guides/performance/README.md#day-night-cycle--9-november-2026).
## Owns the town's only sun ("Soft daylight", a child of Main so render_culling.gd finds it), the
## WorldEnvironment and its procedural sky, and blends them through the keyframes in
## data/day_night.json (cycle length, colours, sun path, lamp glow).
##
## Cost model (performance first): no extra lights are made. While time runs, everything is
## refreshed together REFRESH_INTERVAL times a second, and only values that changed are written;
## a paused clock writes nothing. At night the same DirectionalLight3D is a dim moon without
## shadows. Lamps glow through one shared emissive material per original lamp material, so a
## whole street turns on with one property write (batched MultiMeshes keep that material).
## Interiors stay warm and readable: a few rays from the player every INDOOR_PROBE_INTERVAL
## seconds tell whether a roof and walls are around, and the "indoor" ambient fill then blends in
## (the moon fades too, so it does not shine through roofs; since 25 Nov 2026 the sun as well, as
## there are no shadows to stop it). The sun's direction and colour and the sky are never changed
## indoors (user, 9 Nov 2026: indoors at night lit the outside like noon).
## The fill is local (user, 10 Nov 2026: the street seen through the hospital door was still lit
## like day while the same street seen outdoors was night): the global ambient always keeps the
## outdoor value, and one ReflectionProbe ("Indoor fill", ambient colour only, captures nothing)
## is fitted to the building around the player with rays (_fit_room()). Pixels inside its box
## take the indoor fill and everything outside the walls keeps the time of day's light. One
## probe, no light, hidden outdoors.
## The renderer allocates the whole reflection atlas for it, so project.godot keeps that atlas at
## one 16 px slot (18 Nov 2026: the defaults, 64 slots of 256 px, cost 257 MB of GPU memory; see
## docs/guides/performance/README.md). A second probe needs reflection_count raised.
##
## Use: Main.build_world() calls setup(main); Main._ready() calls bind_town(apartment, player)
## before the render batchers run. The clock (scripts/ui/day_clock.gd) uses set_time(),
## step_hours(), pause(), resume() and the time_changed / paused_changed signals.
## Extend: give any node the group NIGHT_LIGHT_GROUP before bind_town() and its meshes glow at
## night like the streetlights, or SKY_CLOUD_GROUP and its meshes take the clouds' tint.
## The sky decor follows the light too (user, 9 Nov 2026): the baked "Sky sun" disc leaves the
## batched town and sits in the light's direction from the camera (the sun by day, a pale moon by
## night; one transform write per frame), and the cloud puffs share one unshaded material whose
## colour is a keyframe value. Neither adds a light or a draw call. Since 21 Nov 2026 (user: the
## sun looked outdated) the disc is a soft glow (shaders/sky_disc.gdshader) on a camera-facing quad
## just inside the camera's far limit, so all scenery covers it, and it sinks into the haze colour
## at the horizon instead of being cut off by the nearby ground.

signal time_changed(minute: int)
signal paused_changed(paused: bool)

const DATA_PATH := "res://data/day_night.json"
const GameClock := preload("res://scripts/learning/game_clock.gd")
const DAY_MINUTES := 1440.0
## Seconds of real time between lighting refreshes while the clock runs. At the default 30-minute
## day the sun moves about 0.08 degrees per refresh.
const REFRESH_INTERVAL := 0.25
## The sun (and moon) turns in steps of this many game minutes, not with every refresh: each turn
## re-renders the shadow map from a new angle, and small continuous turns made shadow edges
## shimmer (user, 9 Nov 2026: flicker in the background). Five minutes is about 1 degree
## (yaw_per_hour 12), a jump about every 6 s at the default 30-minute day (user, 9 Nov 2026:
## 30 minutes, was 20). Colours, sky and lamps still blend at every refresh. (No sun shadows since
## 23 Nov 2026; the steps stay.)
const SUN_STEP_MINUTES := 5.0
## A game can ask for rarer, sliding steps while it holds the player in one view
## (set_sun_steps(); mahjong: about every 30 s with a 1 s slide). Time itself runs the same.
var sun_step_minutes := SUN_STEP_MINUTES
var sun_slide_seconds := 0.0
var _sun_tween: Tween
var _sun_goal := Vector3.ZERO
const INDOOR_PROBE_INTERVAL := 0.25
## Indoor/outdoor ambient blend per second (about 1 s for a full change, so the doorway is soft).
const INDOOR_BLEND_SPEED := 1.0
const INDOOR_RAY_LENGTH := 30.0
## How far the side rays look for walls (the airport hall and supermarket are about 40 m wide).
const INDOOR_WALL_REACH := 40.0
## Fitting the indoor fill box: walls are looked for this far from the player, through at most
## ROOM_MAX_WALLS walls per side (rooms off a corridor are inside as long as a roof covers the
## space between two walls). The side rays run ROOM_CEILING_GAP below the ceiling, so they hit
## the wall above a door instead of leaving through it. The box ends ROOM_MARGIN inside the
## outer walls' inner faces, so their outside faces keep the outdoor light.
const ROOM_REACH := 60.0
const ROOM_MAX_WALLS := 8
const ROOM_CEILING_GAP := 0.3
const ROOM_MARGIN := 0.05
const ROOM_SKY_STEP := 1.5
## The sun and moon fade indoors (no shadows stop them at the roof; sun since 25 Nov 2026,
## improvement plan GFX-03); this share of their strength is added to the outdoor ambient
## meanwhile, so the street seen through a door is about as bright as when standing in it.
const LIGHT_FILL_SHARE := 0.5
## Lamp heads that glow at night (baked base world): the 19 streetlight heads and the 8 bridge globes.
const LAMP_PATTERNS: Array[String] = ["Streetlight lamp*", "Bridge globe lamp*"]
const LAMP_NAME := "^(Streetlight lamp|Bridge globe lamp)\\d*$"
const NIGHT_LIGHT_GROUP := "night_lights"
## Glowing lamp heads stay visible this far (render_culling would hide them at 60 m).
const LAMP_RANGE := 140.0
## Sky decor in the baked base world: the sun disc and the cloud puffs (word "cloud", platforms).
const SKY_DISC_NAME := "Sky sun"
const CLOUD_PATTERNS: Array[String] = ["Cloud puff*", "Northern sky cloud*"]
const SKY_CLOUD_GROUP := "sky_clouds"
## The sky disc floats this share of the active camera's far limit away (behind every drawn
## object, so scenery always covers it), with a core radius of DISC_RADIUS of that distance
## (about the size the old fixed disc looked from the town centre).
const DISC_SHADER := preload("res://shaders/sky_disc.gdshader")
const DISC_FAR_SHARE := 0.9
const DISC_RADIUS := 0.045
## Core radius as a share of the quad's half size (the rest is halo); halo strength of the sun and
## of the moon.
const DISC_CORE := 0.28
const SUN_GLOW := 0.8
const MOON_GLOW := 0.35
## Near the horizon (sine of the disc's elevation): it fades out between these two heights, and
## its colour sinks this far into the haze colour below DISC_HAZE_TOP.
const DISC_FADE_LOW := -0.04
const DISC_FADE_HIGH := 0.02
const DISC_HAZE_TOP := 0.25
const DISC_HAZE := 0.4
## Distance fog thickens from this share of the view distance to fully opaque at it,
## so the far cut is hidden in the sky-coloured haze (the fog colour follows the time of day).
const VIEW_FOG_BEGIN_SHARE := 0.4
const VIEW_FOG_CURVE := 1.6
## With no view distance (the town map bake): a faint exponential haze.
const HAZE_DENSITY := 0.0005
## The flight sky (25 Nov 2026, improvement plan GFX-04): above the on-foot view distance
## (render_culling.gd VIEW_DISTANCE, 130 m) the view grows with height and the fogged ground met
## the sky in a hard line at the horizon. Over FLIGHT_SKY_RANGE metres of extra view the sky's
## horizon colour turns to the fog colour, its gradient widens (sky_curve from the on-foot SKY_CURVE)
## and the depth fog veils the sky by up to FLIGHT_FOG_SKY. Stepped in FLIGHT_SKY_STEPS, so a climb
## re-renders the sky a few times, not every frame. On foot nothing changes.
const FLIGHT_SKY_FROM := 130.0
const FLIGHT_SKY_RANGE := 150.0
const FLIGHT_SKY_STEPS := 10.0
const SKY_CURVE := 0.15
const FLIGHT_SKY_CURVE := 0.6
const FLIGHT_FOG_SKY := 0.3

## Real minutes for one full game day (data/day_night.json cycle_minutes).
var cycle_minutes := 30.0
## Game time of day in minutes after midnight, 0 <= minutes < 1440.
var minutes := 720.0
var paused := false
var sun: DirectionalLight3D
var environment: Environment
var sky_material: ProceduralSkyMaterial
var lamp_materials: Array[StandardMaterial3D] = []
## The sun/moon disc (moved out of the town) and the clouds' shared tinted material(s).
var sky_disc: MeshInstance3D
var disc_material: ShaderMaterial
var cloud_materials: Array[StandardMaterial3D] = []
## 0 outdoors, 1 under a roof (blended).
var indoor := 0.0
## The indoor fill: a ReflectionProbe whose box is fitted to the building around the player.
var room_probe: ReflectionProbe
## The view distance (set_view_distance()); 0 = unlimited.
var view_distance := 0.0
## 0 on foot, 1 high in the air (the flight sky, FLIGHT_SKY_FROM).
var flight_sky := 0.0

var _keys: Array = []
var _sun_path: Dictionary = {}
var _indoor_color := Color("fff4e4")
var _indoor_energy := 0.54
var _lamp_color := Color("ffd58a")
var _lamp_energy := 2.2
var _outdoor_color := Color.WHITE
var _outdoor_energy := 0.5
var _outdoor_light := Color.WHITE
var _outdoor_light_energy := 0.0
var _night := false
var _lamp_level := -1.0
var _shown_minute := -1
var _since_refresh := 0.0
var _since_probe := 0.0
var _indoor_target := 0.0
var _player: Node3D
var _ray: PhysicsRayQueryParameters3D
var _fit_ray: PhysicsRayQueryParameters3D
var _disc_dir := Vector3.UP


## Builds the sun, sky and environment under `game` and starts at the shared "now" (game_clock.gd),
## so the HUD clock and the airport board agree at launch.
func setup(game: Node) -> void:
	_load(DATA_PATH)
	sun = DirectionalLight3D.new()
	sun.name = "Soft daylight"
	# No sun shadows: one graphics setting that runs on a phone (23 Nov 2026, render_culling.gd).
	sun.shadow_enabled = false
	# Not drawn in the sky: a dim sun's halo darkens a sunset sky, and a sky that ignores the
	# light is not re-rendered while the sun moves.
	sun.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	game.add_child(sun)
	sky_material = ProceduralSkyMaterial.new()
	var sky := Sky.new()
	sky.sky_material = sky_material
	# Rough materials only see the blurry radiance mips; 64 px keeps sky updates cheap.
	sky.radiance_size = Sky.RADIANCE_SIZE_64
	var world := WorldEnvironment.new()
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	# Warm colour fill keeps interiors stable; sky-sourced ambient washes them out.
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.fog_enabled = true
	environment.fog_density = HAZE_DENSITY
	environment.fog_sky_affect = 0.0
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.1
	environment.adjustment_contrast = 1.08
	environment.adjustment_brightness = 0.9
	world.environment = environment
	game.add_child(world)
	set_time(GameClock.shared().now)


## Gives the lamp heads their glow material and starts the indoor probe. Runs once, before
## garden_rendering.gd and render_culling.gd batch the town (they keep the material).
func bind_town(town: Node3D, player: Node3D) -> void:
	_player = player
	if player is CollisionObject3D:
		_ray = PhysicsRayQueryParameters3D.create(Vector3.ZERO, Vector3.UP, player.collision_mask, [player.get_rid()])
		_fit_ray = PhysicsRayQueryParameters3D.create(Vector3.ZERO, Vector3.UP, player.collision_mask, [player.get_rid()])
		# A ray that starts inside a wall passes out of it (no back faces), so the walls
		# along a side can be found one after another.
		_fit_ray.hit_back_faces = false
		_make_room_probe()
	bind_lamps(town, true)
	_bind_sky(town)
	_lamp_level = -1.0
	_apply()


## The lamp heads under `root` get their glow material (bind_town(); also a unit added later by
## the app's staged loading, 13 Nov 2026, before render_culling.gd batches it). `every_group`:
## every NIGHT_LIGHT_GROUP member, also outside `root` (bind_town()).
func bind_lamps(root: Node, every_group := false) -> void:
	var name_filter := RegEx.create_from_string(LAMP_NAME)
	var lamps: Array = []
	for pattern in LAMP_PATTERNS:
		for node in root.find_children(pattern, "", true, false):
			if name_filter.search(str(node.name)) != null:
				lamps.append(node)
	for node in get_tree().get_nodes_in_group(NIGHT_LIGHT_GROUP):
		if every_group or root.is_ancestor_of(node):
			lamps.append(node)
	var glow_for := {}
	for lamp in lamps:
		var meshes: Array = lamp.find_children("*", "MeshInstance3D", true, false)
		if lamp is MeshInstance3D:
			meshes.append(lamp)
		for mesh_node: MeshInstance3D in meshes:
			_make_glow(mesh_node, glow_for)
	_lamp_level = -1.0


func _make_glow(mesh_node: MeshInstance3D, glow_for: Dictionary) -> void:
	if mesh_node.mesh == null or mesh_node.has_meta("night_glow"):
		return
	var base: Material = mesh_node.material_override
	if base == null and mesh_node.mesh.get_surface_count() > 0:
		base = mesh_node.mesh.surface_get_material(0)
	if not glow_for.has(base):
		var glow: StandardMaterial3D = base.duplicate() if base is StandardMaterial3D else StandardMaterial3D.new()
		glow.emission_enabled = true
		glow.emission = _lamp_color
		glow.emission_energy_multiplier = 0.0
		glow_for[base] = glow
		lamp_materials.append(glow)
	mesh_node.material_override = glow_for[base]
	mesh_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if mesh_node.visibility_range_end == 0.0:
		mesh_node.visibility_range_end = LAMP_RANGE
	# garden_rendering.gd leaves these to render_culling.gd, which batches by material.
	mesh_node.set_meta("night_glow", true)


## Takes the baked sun disc out of the town (so the batchers leave it to move) and gives every
## cloud puff one shared copy of its material to tint.
func _bind_sky(town: Node3D) -> void:
	var holder := town.find_child(SKY_DISC_NAME, true, false)
	if holder != null:
		var found: Array = holder.find_children("*", "MeshInstance3D", true, false)
		var disc: MeshInstance3D = holder if holder is MeshInstance3D else (found[0] if not found.is_empty() else null)
		if disc != null and disc.mesh != null:
			# The baked ball becomes a soft glow on a 2 x 2 quad (half size 1).
			var quad := QuadMesh.new()
			quad.size = Vector2(2.0, 2.0)
			disc_material = ShaderMaterial.new()
			disc_material.shader = DISC_SHADER
			disc_material.set_shader_parameter("core", DISC_CORE)
			disc.get_parent().remove_child(disc)
			disc.name = "Sky disc"
			disc.mesh = quad
			disc.material_override = disc_material
			disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			disc.visibility_range_end = 0.0
			add_child(disc)
			sky_disc = disc
		if holder != disc:
			holder.queue_free()
	var clouds: Array = get_tree().get_nodes_in_group(SKY_CLOUD_GROUP)
	for pattern in CLOUD_PATTERNS:
		clouds.append_array(town.find_children(pattern, "", true, false))
	var tint_for := {}
	for cloud in clouds:
		var meshes: Array = cloud.find_children("*", "MeshInstance3D", true, false)
		if cloud is MeshInstance3D:
			meshes.append(cloud)
		for mesh_node: MeshInstance3D in meshes:
			var base: Material = mesh_node.material_override
			if not tint_for.has(base):
				var tint: StandardMaterial3D = base.duplicate() if base is StandardMaterial3D else StandardMaterial3D.new()
				tint_for[base] = tint
				cloud_materials.append(tint)
			mesh_node.material_override = tint_for[base]


func _process(delta: float) -> void:
	if not paused:
		minutes = fposmod(minutes + delta * DAY_MINUTES / (cycle_minutes * 60.0), DAY_MINUTES)
		_since_refresh += delta
		if _since_refresh >= REFRESH_INTERVAL:
			_since_refresh = 0.0
			_apply()
	_place_disc()
	if _ray != null:
		_since_probe += delta
		if _since_probe >= INDOOR_PROBE_INTERVAL:
			_since_probe = 0.0
			_probe_indoor()
		if indoor != _indoor_target:
			indoor = move_toward(indoor, _indoor_target, delta * INDOOR_BLEND_SPEED)
			_apply_fill()


## Jumps to a time of day (minutes after midnight, wrapped) and applies it at once.
func set_time(value: float) -> void:
	minutes = fposmod(value, DAY_MINUTES)
	_since_refresh = 0.0
	_apply()


## Moves the time by whole hours (the clock's − / + buttons) and pauses the cycle.
func step_hours(hours: int) -> void:
	pause()
	set_time(minutes + hours * 60.0)


## Rarer steps that slide (a game in one view), or back to the normal steps with no arguments.
func set_sun_steps(step_minutes: float = SUN_STEP_MINUTES, slide_seconds: float = 0.0) -> void:
	sun_step_minutes = maxf(step_minutes, 1.0)
	sun_slide_seconds = maxf(slide_seconds, 0.0)
	_apply()


func pause() -> void:
	if not paused:
		paused = true
		paused_changed.emit(true)


func resume() -> void:
	if paused:
		paused = false
		_since_refresh = 0.0
		paused_changed.emit(false)


## How much daylight falls on the town now, 0 (dark) to 1 (the strongest sun of the day's
## keyframes): the sun's current energy over that peak. Lets lit things (e.g. the mahjong tile
## faces) brighten as the light fades without copying the keyframe numbers.
func daylight() -> float:
	if sun == null:
		return 1.0
	var peak := 0.0
	for key in _keys:
		peak = maxf(peak, float(key.sun_energy))
	return clampf(sun.light_energy / peak, 0.0, 1.0) if peak > 0.0 else 1.0


func set_cycle_minutes(value: float) -> void:
	cycle_minutes = maxf(value, 0.1)


## The whole game minute shown on clocks (0-1439).
func clock_minute() -> int:
	return int(minutes) % int(DAY_MINUTES)


## Whether the sun is down (the moon is up) at `hour` (0-24).
func is_night(hour: float) -> bool:
	return hour >= float(_sun_path.night_from) or hour < float(_sun_path.night_until)


## The keyframe values blended for `hour` (0-24, wrapping): colours and floats by key name.
func sample(hour: float) -> Dictionary:
	hour = fposmod(hour, 24.0)
	var count := _keys.size()
	var next_index := 0
	while next_index < count and float(_keys[next_index].hour) <= hour:
		next_index += 1
	var a: Dictionary = _keys[(next_index - 1 + count) % count]
	var b: Dictionary = _keys[next_index % count]
	var start := float(a.hour)
	var span := fposmod(float(b.hour) - start, 24.0)
	var t := 0.0 if span <= 0.0 else fposmod(hour - start, 24.0) / span
	var out := {}
	for key in a:
		if key == "hour":
			continue
		out[key] = a[key].lerp(b[key], t) if a[key] is Color else lerpf(a[key], b[key], t)
	return out


## The sun's (or, at night, the moon's) rotation in degrees for `hour`.
func sun_rotation(hour: float) -> Vector3:
	hour = fposmod(hour, 24.0)
	if is_night(hour):
		return Vector3(-float(_sun_path.moon_elevation), float(_sun_path.moon_yaw), 0.0)
	var rise := float(_sun_path.sunrise)
	var t := clampf((hour - rise) / (float(_sun_path.sunset) - rise), 0.0, 1.0)
	var elevation := maxf(float(_sun_path.min_elevation), float(_sun_path.peak_elevation) * sin(PI * t))
	return Vector3(-elevation, float(_sun_path.noon_yaw) + (hour - 12.0) * float(_sun_path.yaw_per_hour), 0.0)


## Where the sky disc sits at `hour`, in degrees like sun_rotation(): the moon at night; by day
## the sun's path without its floor, so the disc sinks below the horizon at dawn and dusk.
func disc_rotation(hour: float) -> Vector3:
	hour = fposmod(hour, 24.0)
	if is_night(hour):
		return sun_rotation(hour)
	var rise := float(_sun_path.sunrise)
	var t := (hour - rise) / (float(_sun_path.sunset) - rise)
	return Vector3(-float(_sun_path.peak_elevation) * sin(PI * t), float(_sun_path.noon_yaw) + (hour - 12.0) * float(_sun_path.yaw_per_hour), 0.0)


## Keeps the disc in the light's direction from the active camera, just inside its far limit, and
## turned to face it. _disc_dir carries the moon's size in its length.
## A hidden disc is only moved when `always` (by _apply(), so it is in place when it shows).
func _place_disc(always := false) -> void:
	if sky_disc == null or not (sky_disc.visible or always):
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var size := _disc_dir.length()
	if size < 0.001:
		return
	var direction := _disc_dir / size
	var distance := camera.far * DISC_FAR_SHARE
	var half_size := distance * DISC_RADIUS / DISC_CORE * size
	var up := Vector3.UP if absf(direction.y) < 0.99 else Vector3.FORWARD
	sky_disc.global_transform = Transform3D(Basis.looking_at(direction, up).scaled(Vector3.ONE * half_size), camera.global_position + direction * distance)


func _apply() -> void:
	if sun == null:
		return
	var hour := minutes / 60.0
	var s := sample(hour)
	_night = is_night(hour)
	var rotation := sun_rotation(floorf(minutes / sun_step_minutes) * sun_step_minutes / 60.0)
	if not sun.rotation_degrees.is_equal_approx(rotation) and not (_sun_tween != null and _sun_tween.is_running() and _sun_goal.is_equal_approx(rotation)):
		if _sun_tween != null:
			_sun_tween.kill()
			_sun_tween = null
		# Slide only for a small step while time runs; a jump of the clock (or the switch
		# between sun and moon) moves at once.
		if sun_slide_seconds > 0.0 and not paused and sun.rotation_degrees.distance_to(rotation) < 20.0:
			_sun_goal = rotation
			_sun_tween = sun.create_tween()
			_sun_tween.tween_property(sun, "rotation_degrees", rotation, sun_slide_seconds).set_trans(Tween.TRANS_SINE)
		else:
			sun.rotation_degrees = rotation
	_outdoor_light = s.sun_color
	_outdoor_light_energy = s.sun_energy
	_write(sky_material, "sky_top_color", s.sky_top)
	_write(sky_material, "sky_horizon_color", s.sky_horizon.lerp(s.fog_color, flight_sky))
	_write(sky_material, "sky_curve", lerpf(SKY_CURVE, FLIGHT_SKY_CURVE, flight_sky))
	_write(environment, "fog_sky_affect", FLIGHT_FOG_SKY * flight_sky)
	# With a view distance, everything past it is sky: below the horizon the sky takes the fog
	# colour, so fogged ground and sea run into it without a seam (user, 23 Nov 2026: a hard line
	# under the horizon when flying high at night, where ground_bottom was darker than the fog).
	var fogged := view_distance > 0.0
	_write(sky_material, "ground_horizon_color", s.fog_color if fogged else s.ground_horizon)
	_write(sky_material, "ground_bottom_color", s.fog_color if fogged else s.ground_bottom)
	_write(environment, "fog_light_color", s.fog_color)
	_outdoor_color = s.ambient_color
	_outdoor_energy = s.ambient_energy
	_apply_fill()
	for material in cloud_materials:
		_write(material, "albedo_color", s.clouds)
	if sky_disc != null:
		var size: float = clampf(s.moon_size, 0.0, 1.0) if _night else 1.0
		var toward := Basis.from_euler(disc_rotation(hour) * (PI / 180.0)).z
		var fade := smoothstep(DISC_FADE_LOW, DISC_FADE_HIGH, toward.y)
		sky_disc.visible = size > 0.01 and fade > 0.0
		_disc_dir = toward * size
		_write(disc_material, "shader_parameter/disc_color", s.disc)
		_write(disc_material, "shader_parameter/haze_color", s.fog_color)
		_write(disc_material, "shader_parameter/glow", MOON_GLOW if _night else SUN_GLOW)
		_write(disc_material, "shader_parameter/fade", fade)
		_write(disc_material, "shader_parameter/haze", DISC_HAZE * (1.0 - smoothstep(0.0, DISC_HAZE_TOP, toward.y)))
		_place_disc(true)
	var level: float = clampf(s.lamps, 0.0, 1.0)
	if absf(level - _lamp_level) > 0.004:
		_lamp_level = level
		for material in lamp_materials:
			material.emission_energy_multiplier = level * _lamp_energy
	var minute := clock_minute()
	if minute != _shown_minute:
		_shown_minute = minute
		time_changed.emit(minute)


## The indoor fill probe: ambient colour only. It captures nothing (cull mask 0) and adds no
## reflection, so moving it costs one transform write.
func _make_room_probe() -> void:
	if room_probe != null:
		return
	room_probe = ReflectionProbe.new()
	room_probe.name = "Indoor fill"
	room_probe.update_mode = ReflectionProbe.UPDATE_ONCE
	room_probe.cull_mask = 0
	room_probe.intensity = 0.0
	room_probe.blend_distance = 0.0
	room_probe.ambient_mode = ReflectionProbe.AMBIENT_COLOR
	room_probe.visible = false
	room_probe.set_meta("fitted", false)
	add_child(room_probe)


## Ambient fill. The environment always keeps the outdoor value; the indoor fill probe around
## the player's building blends toward the "indoor" values under a roof. The direct light keeps
## its outdoor colour; the sun or moon fades indoors, where it would otherwise shine through the
## roof, and part of it moves into the outdoor ambient meanwhile.
func _apply_fill() -> void:
	var light_fade := _outdoor_light_energy * indoor
	_write(environment, "ambient_light_color", _outdoor_color)
	_write(environment, "ambient_light_energy", _outdoor_energy + light_fade * LIGHT_FILL_SHARE)
	if room_probe != null:
		var shown: bool = indoor > 0.0 and room_probe.get_meta("fitted")
		if room_probe.visible != shown:
			room_probe.visible = shown
		# The probe takes its colour as given; the environment converts its colour to linear.
		_write(room_probe, "ambient_color", _outdoor_color.lerp(_indoor_color, indoor).srgb_to_linear())
		_write(room_probe, "ambient_color_energy", lerpf(_outdoor_energy, _indoor_energy, indoor))
	_write(sun, "light_color", _outdoor_light)
	_write(sun, "light_energy", _outdoor_light_energy - light_fade)


## The view distance (render_culling.gd apply_view(); raised while flying, vehicle_controls.gd
## update_flight_view()): depth fog that is opaque at that distance. 0 = no view distance, only a
## faint exponential haze (the town map bake, tools/bake_town_map.gd).
func set_view_distance(distance: float) -> void:
	var switched := (distance > 0.0) != (view_distance > 0.0)
	view_distance = distance
	var high := snappedf(clampf((distance - FLIGHT_SKY_FROM) / FLIGHT_SKY_RANGE, 0.0, 1.0), 1.0 / FLIGHT_SKY_STEPS)
	if high != flight_sky:
		flight_sky = high
		switched = true
	if switched and sky_material != null and is_inside_tree():
		_apply() # the sky below the horizon (fog colour or the keyframe's ground colours)
	if environment != null:
		if distance > 0.0:
			environment.fog_mode = Environment.FOG_MODE_DEPTH
			environment.fog_density = 1.0
			environment.fog_depth_begin = distance * VIEW_FOG_BEGIN_SHARE
			environment.fog_depth_end = distance
			environment.fog_depth_curve = VIEW_FOG_CURVE
		else:
			environment.fog_mode = Environment.FOG_MODE_EXPONENTIAL
			environment.fog_density = HAZE_DENSITY
	if sun != null and is_inside_tree():
		_apply_fill()
		_place_disc()


## Indoors = a static roof overhead and static walls on at least 3 of 4 sides, so bridges,
## awnings and porches stay outdoors. Five short rays every INDOOR_PROBE_INTERVAL seconds.
func _probe_indoor() -> void:
	if not is_instance_valid(_player) or not _player.is_inside_tree():
		return
	var space := _player.get_world_3d().direct_space_state
	var from := _player.global_position + Vector3.UP * 1.6
	if not _solid(space, from, from + Vector3.UP * INDOOR_RAY_LENGTH):
		_indoor_target = 0.0
		return
	var walls := 0
	for side in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		if _solid(space, from, from + side * INDOOR_WALL_REACH):
			walls += 1
	_indoor_target = 1.0 if walls >= 3 else 0.0
	if _indoor_target > 0.0 and room_probe != null and not in_room_fill(from):
		_fit_room(space, from)


## Whether `point` is inside the fitted indoor fill box (0.2 m in from its faces).
func in_room_fill(point: Vector3) -> bool:
	if room_probe == null or not room_probe.get_meta("fitted"):
		return false
	var local := room_probe.global_transform.affine_inverse() * point
	var half := room_probe.size * 0.5 - Vector3.ONE * 0.2
	return absf(local.x) <= half.x and absf(local.y) <= half.y and absf(local.z) <= half.z


## Fits the indoor fill box to the building around `from` (the player's head): turned to the
## nearest wall, out to the outer wall on each side (_room_reach()), from just under the
## player's floor to the highest roof above. The fill keeps the usual blend: a building entered
## from outside warms up in about a second, a refit inside the same building does not flash.
func _fit_room(space: PhysicsDirectSpaceState3D, from: Vector3) -> void:
	var up := _static_hit(space, from, from + Vector3.UP * INDOOR_RAY_LENGTH)
	if up.is_empty():
		return
	var ceiling: float = up.position.y
	var down := _static_hit(space, from, from + Vector3.DOWN * INDOOR_RAY_LENGTH)
	var bottom: float = (down.position.y if not down.is_empty() else from.y - 1.6) - 0.3
	var top := ceiling
	var above: Vector3 = up.position
	for i in ROOM_MAX_WALLS:
		var hit := _static_hit(space, above + Vector3.UP * 0.02, above + Vector3.UP * INDOOR_RAY_LENGTH)
		if hit.is_empty():
			break
		above = hit.position
		top = above.y
	top += 0.5
	var level := from
	level.y = maxf(from.y - 0.4, ceiling - ROOM_CEILING_GAP)
	var axis := Vector3.RIGHT
	var nearest := INF
	for side in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		var hit := _static_hit(space, level, level + side * INDOOR_WALL_REACH)
		if hit.is_empty():
			continue
		var normal: Vector3 = hit.normal * Vector3(1, 0, 1)
		var distance := level.distance_to(hit.position)
		if normal.length() > 0.5 and distance < nearest:
			nearest = distance
			axis = normal.normalized()
	var basis := Basis(axis, Vector3.UP, axis.cross(Vector3.UP))
	var x_plus := _room_reach(space, level, basis.x)
	var x_minus := _room_reach(space, level, -basis.x)
	var z_plus := _room_reach(space, level, basis.z)
	var z_minus := _room_reach(space, level, -basis.z)
	var size := Vector3(x_plus + x_minus + 2.0 * ROOM_MARGIN, top - bottom, z_plus + z_minus + 2.0 * ROOM_MARGIN)
	var center := level + basis.x * (x_plus - x_minus) * 0.5 + basis.z * (z_plus - z_minus) * 0.5
	center.y = (top + bottom) * 0.5
	room_probe.global_transform = Transform3D(basis, center)
	room_probe.size = size
	room_probe.set_meta("fitted", true)
	_apply_fill()


## How far the building reaches from `origin` along `direction`. The walls along that side are
## found one after another; the gaps between them are checked for open sky (no roof overhead)
## at their middle and every ROOM_SKY_STEP. The box stops at the wall before the first gap with
## open sky. Sky before the first wall (an open side, or a ray out through a tall opening) ends
## it at the last covered step.
func _room_reach(space: PhysicsDirectSpaceState3D, origin: Vector3, direction: Vector3) -> float:
	var walls: Array[float] = []
	var start := origin
	while walls.size() < ROOM_MAX_WALLS:
		var hit := _static_hit(space, start, origin + direction * ROOM_REACH)
		if hit.is_empty():
			break
		var distance := origin.distance_to(hit.position)
		walls.append(distance)
		start = origin + direction * (distance + 0.02)
	var gap_start := 0.0
	for i in walls.size() + 1:
		var gap_end: float = walls[i] if i < walls.size() else ROOM_REACH
		var d := gap_start + ROOM_SKY_STEP * 0.5
		var covered := gap_start
		var open := false
		while not open and d < gap_end:
			if _roofed(space, origin + direction * d):
				covered = d
			else:
				open = true
			d += ROOM_SKY_STEP
		if not open:
			open = not _roofed(space, origin + direction * (gap_start + gap_end) * 0.5)
		if open:
			return covered if i == 0 else gap_start
		if i < walls.size():
			gap_start = walls[i]
	return walls[walls.size() - 1] if not walls.is_empty() else ROOM_REACH


func _roofed(space: PhysicsDirectSpaceState3D, point: Vector3) -> bool:
	return not _static_hit(space, point, point + Vector3.UP * INDOOR_RAY_LENGTH).is_empty()


## The first static body between `from` and `to`, looking past vehicles, people and animals.
func _static_hit(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> Dictionary:
	var direction := (to - from).normalized()
	_fit_ray.to = to
	_fit_ray.from = from
	for i in 4:
		var hit := space.intersect_ray(_fit_ray)
		if hit.is_empty() or hit.collider is StaticBody3D:
			return hit
		_fit_ray.from = hit.position + direction * 0.02
	return {}


func _solid(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> bool:
	_ray.from = from
	_ray.to = to
	var hit := space.intersect_ray(_ray)
	return not hit.is_empty() and hit.collider is StaticBody3D


## Writes a property only when it changed (sky and environment writes re-render the sky).
func _write(target: Object, property: StringName, value: Variant) -> void:
	var current: Variant = target.get(property)
	if value is Color and current is Color:
		if (value as Color).is_equal_approx(current):
			return
	elif value is float and current is float:
		if is_equal_approx(value, current):
			return
	target.set(property, value)


func _load(path: String) -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	cycle_minutes = float(data.get("cycle_minutes", 30.0))
	_sun_path = data.sun
	_indoor_color = Color(str(data.indoor.ambient_color))
	_indoor_energy = float(data.indoor.ambient_energy)
	_lamp_color = Color(str(data.lamp_glow))
	_lamp_energy = float(data.lamp_energy)
	_keys.clear()
	for raw in data.keyframes:
		var key := {}
		for name in raw:
			var value: Variant = raw[name]
			key[name] = Color(value) if value is String else float(value)
		_keys.append(key)
	_keys.sort_custom(func(a, b): return a.hour < b.hour)
