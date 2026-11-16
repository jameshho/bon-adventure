extends RefCounted
## BonBon riding an open-seat vehicle (the scooter, 9 Nov 2026): she stays visible, climbs on from
## the near side, sits on the seat with her feet on the floorboard and her paws on the grips,
## leans into turns with the scooter, rocks back when accelerating and forward when braking,
## and turns her head with the bars. Uses the vehicle's markers (RiderMount, MountStep, grips
## tagged rider_grip), so the pose follows the model. Called from player_controller.gd while
## riding a DriveableVehicle that has_rider(); boarding progress t runs 0 -> 1 to get on and
## 1 -> 0 to get off (driveable_vehicle.gd). BonBon has no skeleton: like the walking and sitting
## poses, this moves her Arm/Foot/Head parts.

## Paws stay where they stand (tucked under her belly, so they stay joined to her body): the
## floorboard is at her paw soles. Kept as an offset for other open-seat models.
const PAW_OFFSET := Vector3.ZERO
## Arm pivot (shoulder) and the paw end of the hanging arm, BonBon units; side +1 is "Arm".
const SHOULDER := Vector3(-.65, 1.22, 0)
const ARM_TIP := Vector3(-.8, .9, -.02)
## How far an arm may shorten or lengthen to keep its paw on a grip.
const ARM_STRETCH := Vector2(.5, 1.5)
## Riding posture: a slight forward hunch, extra lean into turns, fore-aft rock per m/s^2.
const HUNCH := -.06
const EXTRA_LEAN := .2
const ROCK_PER_ACCEL := .022
const MAX_ROCK := .1
## Lean and rock pivot: where her bottom meets the seat cushion (BonBon units, +Z is behind).
const HIP := Vector3(0, .22, .3)

static func head(player) -> Node3D:
	return player.get_node_or_null("Visual/BonBon/Head") as Node3D

static func grip(vehicle: Node3D, tag: String) -> Node3D:
	for node in vehicle.find_children("*" + tag + "Grip", "MeshInstance3D", true, false):
		if node.get_meta("rider_grip", "") == tag: return node
	return null

## One physics tick of getting on, riding or getting off.
static func pose(player, delta: float) -> void:
	var vehicle = player.riding_vehicle
	var t: float = vehicle.boarding_progress
	var seat: Transform3D = vehicle.boarding_seat()
	var step: Vector3 = vehicle.boarding_step_point()
	var rider_scale: float = vehicle.boarding_seat_scale()
	var visual: Node3D = player.visual
	visual.visible = true
	# Walk to the footboard (0-.4), hop up and over onto the seat (.4-.8), settle (.8-1).
	var walk := smoothstep(0.0, .4, t)
	var hop := smoothstep(.4, .8, t)
	var center: Vector3 = player.boarding_start.origin.lerp(step, walk)
	if t > .4: center = step.lerp(seat.origin, hop)
	center.y += sin(clampf((t - .4) / .4, 0, 1) * PI) * .55
	var size := lerpf(1.0, rider_scale, smoothstep(.15, .8, t))
	# Face the scooter while walking up, then turn to ride forward during the hop.
	var to_bike: Vector3 = seat.origin - step
	to_bike.y = 0
	var face_bike: Quaternion = player.boarding_start.basis.get_rotation_quaternion()
	if to_bike.length_squared() > .0001:
		face_bike = Basis.looking_at(to_bike, Vector3.UP).get_rotation_quaternion()
	var facing: Quaternion = player.boarding_start.basis.get_rotation_quaternion().slerp(face_bike, smoothstep(0, .35, t))
	facing = facing.slerp(seat.basis.get_rotation_quaternion(), smoothstep(.45, .8, t))
	var ride := smoothstep(.6, .95, t)
	var forward_accel: float = vehicle.longitudinal_accel if ride > 0 else 0.0
	var rock := clampf(forward_accel * ROCK_PER_ACCEL, -MAX_ROCK, MAX_ROCK)
	# Lean a little further than the scooter (about the scooter's long axis, BonBon's Z).
	var body := Basis(facing) * Basis(Vector3.BACK, vehicle.lean * EXTRA_LEAN * ride) * Basis(Vector3.RIGHT, (HUNCH + rock) * ride)
	# A soft bounce from the road at speed and a breath at rest, both tiny.
	player.gait_phase += delta * lerpf(1.6, 9.0, clampf(absf(vehicle.current_speed) / 12.0, 0, 1)) if t >= 1 else delta * 10.0
	var bob := sin(player.gait_phase) * lerpf(.008, .018, clampf(absf(vehicle.current_speed) / 12.0, 0, 1)) * ride
	# Rotate about the hip on the seat, not her paws, so leaning keeps her seated.
	var upright := Basis(facing).scaled(Vector3.ONE * size)
	var scaled := body.scaled(Vector3.ONE * size)
	visual.global_transform = Transform3D(scaled, center + upright * HIP - scaled * HIP + seat.basis.y * bob)
	var bonbon: Node3D = visual.get_node("BonBon")
	var to_bonbon: Transform3D = bonbon.global_transform.affine_inverse()
	for key in player.parts:
		var part: Node3D = player.parts[key]
		var rest: Transform3D = player.rest_poses[key]
		var side := -1.0 if str(key).ends_with("_2") else 1.0
		var walking := rest
		if str(key).begins_with("Arm"):
			# Swing while walking, then turn toward the grip; the stretch blends in on its own
			# (Transform3D.interpolate_with would drop an off-axis stretch).
			var shoulder := Vector3(SHOULDER.x * side, SHOULDER.y, SHOULDER.z)
			var hang := Vector3(ARM_TIP.x * side, ARM_TIP.y, ARM_TIP.z) - shoulder
			var swing := Quaternion(Vector3.RIGHT, sin(player.gait_phase) * side * .35 * (1 - walk * .5))
			var turn := swing
			var k := 0.0
			var bar := grip(vehicle, "Near" if side > 0 else "Far")
			if bar != null and ride > 0:
				var reach: Vector3 = to_bonbon * bar.global_position - shoulder
				turn = swing.slerp(Quaternion(hang.normalized(), reach.normalized()), ride)
				# Plush arms give a little, so the paw lands on the grip when leaning or rocking.
				k = (clampf(reach.length() / hang.length(), ARM_STRETCH.x, ARM_STRETCH.y) - 1.0) * ride
			var u := hang.normalized()
			var arm := Basis(turn) * Basis(Vector3.RIGHT + u * u.x * k, Vector3.UP + u * u.y * k, Vector3.BACK + u * u.z * k)
			part.transform = Transform3D(arm * rest.basis, shoulder + arm * (rest.origin - shoulder))
		else:
			walking.origin += Vector3(0, sin(player.gait_phase + side) * .12 * (1 - walk), 0)
			var riding := rest
			riding.origin = rest.origin + PAW_OFFSET
			part.transform = walking.interpolate_with(riding, ride)
	# Look into the turn with the bars.
	var face := head(player)
	if face != null:
		if not player.has_meta("rider_head_rest"): player.set_meta("rider_head_rest", face.transform)
		var head_rest: Transform3D = player.get_meta("rider_head_rest")
		var steer: float = vehicle.road_physics.steering_angle if vehicle.road_physics != null else 0.0
		face.transform = Transform3D(Basis(Vector3.UP, -steer * .7 * ride) * head_rest.basis, head_rest.origin)

## Back to the standing pose after getting off.
static func reset(player) -> void:
	var face := head(player)
	if face != null and player.has_meta("rider_head_rest"):
		face.transform = player.get_meta("rider_head_rest")
