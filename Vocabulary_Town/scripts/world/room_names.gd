extends RefCounted
## The room / area name the HUD shows for the player's position (main.current_room()). Moved out
## of main.gd (7 Nov 2026), unchanged: the redesigned Home's rooms, then the reference layout's
## sites, then the legacy town rectangles (model coordinates, before the compact relocations).
const ModularTown := preload("res://scripts/world/modular_town.gd")

static func room_at(main) -> String:
	var player = main.player
	var apartment = main.apartment
	var reference_layout = main.reference_layout
	if not is_instance_valid(player) or not is_instance_valid(apartment):
		return "Home"
	# In the warehouse minigame copy the room is the real warehouse (warehouse_session.gd).
	var point: Vector3 = apartment.to_local(player.get_meta("map_position", player.global_position))
	var redesigned_home: Node3D = ModularTown.building(apartment, "home")
	if redesigned_home != null and redesigned_home.has_meta("floorplan_redesigned"):
		var hp: Vector3 = redesigned_home.to_local(player.global_position)
		# Bigger home since 12 Nov 2026 (scripts/buildings/home_expansion.gd).
		if hp.x >= -11 and hp.x <= 26 and hp.z >= -15 and hp.z <= 23:
			if hp.z < -3 and hp.z >= -12 and hp.x < -2.5: return "Guest suite"
			if hp.z < -8: return "Swimming pool / terrace"
			if hp.z < -3: return "Pool terrace"
			if hp.x > 16 and hp.z >= 14: return "Study"
			if hp.x >= 6 and hp.z >= 14: return "Garage"
			if hp.z > 17: return "Front yard"
			if hp.x > 16:
				if hp.z < 7.5: return "Master bedroom"
				return "Hallway" if hp.x < 18.4 else "Bathroom"
			if hp.x < -5:
				if hp.z < 3: return "Guest bathroom"
				if hp.z < 11: return "Family bathroom"
				return "Yellow bedroom"
			if hp.x > 8: return "Dining room" if hp.z < 4 else "Kitchen"
			if hp.z > 10: return "Entry lounge"
			return "Living room"
	if reference_layout != null:
		var site: String = reference_layout.site_at(point)
		if site != "Home": return reference_layout.location_name(point,site)
		point = reference_layout.sites.Home.pose.affine_inverse()*point
	if point.x > -44 and point.x < -22 and point.z > 33 and point.z < 54:
		return "Supermarket"
	if point.x > -13.2 and point.x < 12.2 and point.z > 103.8 and point.z < 128.6:
		if point.y >= 10.8:
			return "School · Floor 3 · Art & Music"
		if point.y >= 5.2:
			return "School · Floor 2 · Science & Geography"
		return "School · Ground Floor · Classrooms"
	if point.x > -41.2 and point.x < -15.8 and point.z > 103.8 and point.z < 128.6:
		if point.y >= 10.8:
			return "Hospital · Floor 3 · Imaging, Laboratory & Therapy"
		if point.y >= 5.2:
			return "Hospital · Floor 2 · Patient Rooms, ICU & Surgery"
		return "Hospital · Ground Floor · Reception & Urgent Care"
	if point.x > -61 and point.x < -43 and point.z > 103 and point.z < 133:
		return "Furniture Store"
	if point.x > 19 and point.x < 33 and point.z > 104 and point.z < 128:
		return "Sports Store"
	if point.x > -68.5 and point.x < -53.5 and point.z > 63 and point.z < 89:
		return "Bakery & Café"
	if point.z < -3.12:
		return "South Beach" if point.z < -9.0 else "Behind the house"
	if point.z >= 54.0 and point.z < 88.0:
		return "Central Park" if point.x > -36 and point.x < 40 else "Parkside neighborhood"
	# Northern civic district moved back to make room for Central Park.
	if point.z >= 88.0:
		point.z -= 32.0
	if point.z > 73.4 and point.z < 87.0 and point.x > 45.5:
		return "Clothing Store"
	if point.z > 38.0 and point.z < 52.0 and point.x < -54.0:
		return "Electronics Store"
	if point.z > 70.0:
		if point.x < -21.5:
			return "Hospital"
		if point.x < 11.0:
			return "School"
		if point.x < 34.0:
			return "Sports Store"
		return "Northern neighborhood"
	if point.z > 58.0:
		return "Civic Avenue"
	if point.z > 37.5:
		if point.x < -26.0:
			return "Supermarket"
		if point.x < -8.5:
			return "Library"
		if point.x < 16.0:
			return "Park"
		if point.x < 33.0:
			return "Bank"
		return "Police station"
	if point.z > 31.0:
		return "Town square sidewalk"
	if point.z > 21.0:
		return "Main Street"
	point.z -= 6.0 # Home moved toward Main Street.
	if point.z > 13.0:
		return "Front yard"
	if point.z > 9.0:
		return "Entry / porch"
	if point.z > 0.0:
		if point.x < -3.4:
			return "Kitchen"
		if point.x < 3.0:
			return "Dining room"
		return "Living room"
	if point.x < -3.0:
		return "Primary bedroom"
	if point.x < 3.0:
		return "Bathroom"
	return "Study bedroom"
