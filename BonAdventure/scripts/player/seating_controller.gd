extends Node
## Chair/bench interaction and clearance checks; no learning/save ownership.
## Seats keep node-local points, so seats on moving roots (swan boats) stay valid.
## Optional seat metadata: sit_root, sit_label, sit_reach (world Vector2 horizontal/vertical),
## sit_priority (world distance subtracted when choosing), stand_position (node-local),
## sit_message. A seat with meta playground_swing (its swing pivot,
## scripts/world/playground_swing.gd) carries the player: W / S kick, E brakes then stands.
## Beds (word "bed", or meta bed_enabled; bed_disabled opts out) are lying spots: E lies
## down on the mattress top, head toward pillows/headboard. E or Space gets up from any
## seat or bed (swings and seesaws handle their own Space, which brakes first).
## Occupancy: a seat or bed is taken while a figure (group "figures") rests on it, judged
## by its meta seat_point (else its origin), or while the learner uses it.
## Interaction system (12 Nov 2026): each seat node is an Interactable (kind SIT; a sofa's cushions
## share one and E takes the nearest free cushion); the focus pass picks it and E, a click or a
## tap sits. While seated Main's "seat" claim makes E stand up. The old hint line is gone.
var game
var seats: Array[Dictionary] = []
var current: Dictionary = {}
var return_position := Vector3.ZERO
var return_local := Vector3.ZERO
## Seat node -> its seats (a sofa has one per cushion).
var by_node: Dictionary = {}
## Swing input edges (one kick per press) and a pending "get off" while it slows.
var swing_keys := Vector2.ZERO
var swing_exit := false
## Seats whose node has meta "swivel" turn with A / D while seated (rad/s).
const UiText := preload("res://scripts/language/ui_text.gd")
const PlayerPlace := preload("res://scripts/core/player_place.gd")
const Interactable := preload("res://scripts/core/interactable.gd")
## Ranking: a seat behind the player that faces them (between rows) counts this many metres
## farther, unless the player faces it (7 Nov 2026).
const BEHIND_PENALTY := 3.0
const SWIVEL_SPEED := 3.0
## Vocabulary words that are always seats (other furniture opts in with sit_enabled).
const SEAT_WORDS := ["chair","bench","armchair","sofa","wheelchair"]
## A figure within this horizontal distance of a seat point (and the seat nearest to it)
## occupies that seat.
const OCCUPY_RADIUS := 0.6
const FIGURE_LAYER: int = preload("res://scripts/characters/house_characters.gd").FIGURE_LAYER

func setup(scene) -> void:
    game = scene
    name = "SeatingController"
    add_seats(game.apartment)
    # Characters and animals become solid now, after the area vocabulary index was built.
    preload("res://scripts/characters/house_characters.gd").solidify_figures(game)

## The seats and beds under `under` (the town at setup; a unit added later by the app's staged
## loading, 13 Nov 2026), each an Interactable.
func add_seats(under: Node) -> void:
    var backs: Array[Vector3] = []
    for mesh in under.find_children("*","MeshInstance3D",true,false):
        var title := (str(mesh.name)+" "+str(mesh.get_parent().name)).to_lower()
        if mesh.mesh:
            var bounds := mesh_bounds(mesh)
            var dimensions: Vector3 = mesh.get_aabb().size*mesh.global_basis.get_scale().abs()
            # Generated duplicate names become @Node3D@...; recognize thin back panels too.
            var back_panel := dimensions.y > 0.4 and dimensions.y < 1.6 and minf(dimensions.x,dimensions.z) < 0.3 and maxf(dimensions.x,dimensions.z) > 0.35 and maxf(dimensions.x,dimensions.z) < 3.5
            if ("back" in title or "upholstery" in title or back_panel) and bounds.size.y > 0.3: backs.append(bounds.get_center())
    var beds: Array[Node3D] = []
    for node in under.find_children("*","Node3D",true,false):
        var key := str(node.get_meta("word_key",""))
        var title := str(node.name).to_lower()
        if node.get_meta("sit_disabled",false): continue
        if key == "bed" or node.get_meta("bed_enabled",false):
            if not node.get_meta("bed_disabled",false): beds.append(node)
            continue
        if not node.get_meta("sit_enabled",false) and key not in SEAT_WORDS:
            if key != "" or not ("chair" in title or "bench seat" in title): continue
            if "back" in title or "leg" in title or "foot" in title or "upholstery" in title: continue
        var meshes: Array = node.find_children("*","MeshInstance3D",true,false)
        if node is MeshInstance3D: meshes.append(node)
        var best := AABB()
        var score := -1.0
        # A sofa offers one seat per cushion; the player takes the nearest.
        var cushions: Array[AABB] = []
        for mesh in meshes:
            if mesh.mesh == null: continue
            var box := mesh_bounds(mesh)
            if box.size.y > 0.55 or minf(box.size.x,box.size.z) < 0.3: continue
            if key == "sofa" and "cushion" in str(mesh.name).to_lower(): cushions.append(box)
            var area := box.size.x*box.size.z
            if area > score:
                score = area
                best = box
        if score < 0: continue
        var tops: Array[AABB] = [best]
        if cushions.size() > 1: tops = cushions
        # Exclude only the furniture itself for approach/exit sight lines.
        var rids: Array[RID] = []
        var root: Node = node
        if str(node.name) == "Seat": root = node.get_parent()
        if node.has_meta("sit_root"): root = node.get_meta("sit_root")
        for body in root.find_children("*","CollisionObject3D",true,false): rids.append(body.get_rid())
        for top in tops:
            var point := top.get_center()
            point.y = top.end.y
            var duplicate := false
            for seat in seats:
                if seat.point.distance_to(point) < 0.15: duplicate = true; break
            if duplicate: continue
            var forward: Vector3 = -node.global_basis.z.normalized()
            forward.y = 0
            # Side cushions sit off the back's centre, so a sofa keeps its own facing.
            var nearest := 1.2 if tops.size() == 1 else 0.0
            for back in backs:
                var delta := point-back
                if back.y < point.y+0.1 or back.y > point.y+1.4: continue
                delta.y = 0
                if delta.length() > 0.08 and delta.length() < nearest:
                    nearest = delta.length()
                    forward = delta.normalized()
            if node.has_meta("sit_position"): point = node.to_global(node.get_meta("sit_position"))
            if node.has_meta("sit_forward"): forward = (node.global_basis*node.get_meta("sit_forward")).normalized()
            forward = forward.normalized()
            seats.append({"node":node,"point":point,"forward":forward,"local_point":node.to_local(point),"local_forward":node.global_basis.inverse()*forward,"rids":rids,"reach":node.get_meta("sit_reach",Vector2(2.8,1.65)),"label":node.get_meta("sit_label",key if key in ["sofa","wheelchair"] else "bench" if key=="bench" or "bench" in title else "chair")})
    for node in beds:
        var bed := bed_seat(node)
        if not bed.is_empty(): seats.append(bed)
    make_interactables()

## One Interactable per seat node (see the header).
func make_interactables() -> void:
    by_node.clear()
    for seat in seats:
        if not by_node.has(seat.node): by_node[seat.node] = []
        by_node[seat.node].append(seat)
    for node in by_node:
        var first: Dictionary = by_node[node][0]
        Interactable.attach(node, {
            "kind": Interactable.Kind.SIT,
            "prompt_distance": float(first.reach.x),
            "needs_facing": false,
            "priority": float(node.get_meta("sit_priority", 0.0)),
            "on_point": func(from: Vector3) -> Vector3: return _closest_point(node, from),
            "on_badge": func() -> Vector3: return _closest_point(node, game.player.global_position) + Vector3.UP * 0.45,
            "on_rank": func(from: Vector3, heading: Vector2) -> float: return _behind_penalty(node, from, heading),
            "on_check": func() -> Variant: return not seat_on(node, true).is_empty(),
            "on_use": func() -> void: sit_on(node),
        })

## The nearest seat point of `node` (no reach or sight test: the focus pass's distance).
func _closest_point(node: Node3D, from: Vector3) -> Vector3:
    var best := Vector3.INF
    for seat in by_node.get(node, []):
        refresh(seat)
        if best == Vector3.INF or seat.point.distance_squared_to(from) < best.distance_squared_to(from):
            best = seat.point
    return best

func _behind_penalty(node: Node3D, from: Vector3, heading: Vector2) -> float:
    var seats_here: Array = by_node.get(node, [])
    if seats_here.is_empty(): return 0.0
    var seat: Dictionary = seats_here[0]
    if seat.get("bed", false): return 0.0
    var delta: Vector3 = _closest_point(node, from) - from
    var flat := Vector2(delta.x, delta.z)
    var faces_it: bool = flat.length() > 0.05 and flat.normalized().dot(heading) > 0.7
    return BEHIND_PENALTY if not faces_it and flat.dot(Vector2(seat.forward.x, seat.forward.z)) > 0.3 else 0.0

## A bed's lying spot: the centre of its highest broad layer (duvet, blanket, mattress) under
## the bed node or beside it within its footprint; head toward the pillows/headboard
## (bed-local -Z when none is found); "forward" points to the feet. Measured in metres.
func bed_seat(node: Node3D) -> Dictionary:
    var frame_space := Transform3D(node.global_basis.orthonormalized(),node.global_position)
    var inverse := frame_space.affine_inverse()
    var own: Array = node.find_children("*","MeshInstance3D",true,false)
    if node is MeshInstance3D: own.append(node)
    var frame := AABB()
    var first := true
    for mesh in own:
        if mesh.mesh == null: continue
        var box: AABB = inverse*mesh.global_transform*mesh.get_aabb()
        frame = box if first else frame.merge(box)
        first = false
    if first: return {}
    var candidates: Array = own.duplicate()
    var owners := {}
    for sibling in node.get_parent().get_children():
        if sibling == node or not sibling is Node3D: continue
        var found: Array = [sibling] if sibling is MeshInstance3D else []
        for child in sibling.get_children():
            if child is MeshInstance3D: found.append(child)
        for mesh in found:
            candidates.append(mesh)
            owners[mesh] = sibling
    var top := -INF
    var head_sum := 0.0
    var head_count := 0
    var long_z := frame.size.z >= frame.size.x
    var used: Array[Node] = [node]
    for mesh in candidates:
        if mesh.mesh == null: continue
        var box: AABB = inverse*mesh.global_transform*mesh.get_aabb()
        var center := box.get_center()
        if center.x < frame.position.x or center.x > frame.end.x or center.z < frame.position.z or center.z > frame.end.z: continue
        if box.end.y < frame.position.y+0.15 or box.position.y > frame.end.y+0.6: continue
        var title := (str(mesh.name)+" "+str(mesh.get_parent().name)).to_lower()
        var marks_head: bool = "pillow" in title or "headboard" in title or box.size.y > 0.6
        if marks_head:
            head_sum += center.z if long_z else center.x
            head_count += 1
        elif box.size.y < 0.6 and box.size.x*box.size.z > frame.size.x*frame.size.z*0.3:
            top = maxf(top,box.end.y)
        else: continue
        if owners.has(mesh) and not owners[mesh] in used: used.append(owners[mesh])
    if top == -INF: top = frame.end.y
    var middle := frame.get_center()
    var head_sign := -1.0
    if head_count > 0: head_sign = 1.0 if head_sum/head_count > (middle.z if long_z else middle.x) else -1.0
    var head: Vector3 = frame_space.basis*(Vector3(0,0,head_sign) if long_z else Vector3(head_sign,0,0))
    var point: Vector3 = frame_space*Vector3(middle.x,top,middle.z)
    var rids: Array[RID] = []
    for holder in used:
        for body in holder.find_children("*","CollisionObject3D",true,false): rids.append(body.get_rid())
    var half_length: float = (frame.size.z if long_z else frame.size.x)*0.5
    return {"node":node,"point":point,"forward":-head,"local_point":node.to_local(point),"local_forward":node.global_basis.inverse()*-head,"rids":rids,"reach":Vector2(maxf(2.8,half_length+1.4),1.65),"label":"bed","bed":true}

## The figure (or the player) resting on this seat or bed, else null.
func occupant(seat: Dictionary) -> Node:
    if game.player.seated and is_same(current,seat): return game.player
    for figure in get_tree().get_nodes_in_group("figures"):
        if not is_instance_valid(figure) or not figure.is_visible_in_tree(): continue
        var p: Vector3 = figure.get_meta("seat_point",figure.global_position)
        var delta: Vector3 = p-seat.point
        if delta.y < -0.3 or delta.y > 0.6 or Vector2(delta.x,delta.z).length() > OCCUPY_RADIUS: continue
        if is_same(nearest_seat_to(p),seat): return figure
    return null

func nearest_seat_to(p: Vector3) -> Dictionary:
    var best: Dictionary = {}
    var shortest := INF
    for seat in seats:
        var distance: float = seat.point.distance_squared_to(p)
        if distance < shortest:
            shortest = distance
            best = seat
    return best

## True while the player sits or lies within `radius` of `point`, or stands that close.
func player_at(point: Vector3, radius := 1.0) -> bool:
    if game.player.seated and not current.is_empty() and current.point.distance_to(point) < radius: return true
    var delta: Vector3 = game.player.global_position-point
    return absf(delta.y) < 2.0 and Vector2(delta.x,delta.z).length() < radius+0.4

## Where the player's origin rests on a seat given its point and forward (feet for a bed).
func seat_pose(seat: Dictionary, point: Vector3, forward: Vector3) -> Vector3:
    if seat.get("bed",false): return game.player.lie_origin(point,-forward)
    return point+forward*0.12-Vector3.UP*0.17

## Recompute a seat's world point and facing from its node (it may have moved).
func refresh(seat: Dictionary) -> void:
    seat.point = seat.node.to_global(seat.local_point)
    seat.forward = (seat.node.global_basis*seat.local_forward).normalized()

## Keep a seated player on a seat whose root moved this frame.
func follow_seat() -> void:
    if not game.player.seated or game.player.sit_transition or current.is_empty() or not is_instance_valid(current.node): return
    refresh(current)
    game.player.global_position = seat_pose(current,current.point,current.forward)
    game.player.rotation.y = atan2(-current.forward.x,-current.forward.z)

func mesh_bounds(mesh: MeshInstance3D) -> AABB:
    var local := mesh.get_aabb()
    var result := AABB(mesh.to_global(local.position),Vector3.ZERO)
    for i in range(8): result = result.expand(mesh.to_global(local.get_endpoint(i)))
    return result

func clear_line(from: Vector3, to: Vector3, seat: Dictionary) -> bool:
    # Sight lines ignore figures: a sitter beside a free cushion does not hide it.
    var ray := PhysicsRayQueryParameters3D.create(from,to,(game.player.saved_collision_mask if game.player.seated else game.player.collision_mask) & ~FIGURE_LAYER)
    var ignored: Array[RID] = [game.player.get_rid()]
    ignored.append_array(seat.rids)
    ray.exclude = ignored
    return game.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

## The seat of `node` the player would take: the nearest free one in reach with a clear line;
## with any_seat, an occupied one when none is free ({} when out of reach).
func seat_on(node: Node3D, any_seat := false) -> Dictionary:
    if game.player.noclip_enabled or is_instance_valid(game.active_vehicle): return {}
    var free: Dictionary = {}
    var taken: Dictionary = {}
    var free_d := INF
    var taken_d := INF
    for seat in by_node.get(node, []):
        if not is_instance_valid(seat.node): continue
        refresh(seat)
        var delta: Vector3 = seat.point-game.player.global_position
        if absf(delta.y) > seat.reach.y: continue
        var distance := Vector2(delta.x,delta.z).length()
        if distance > seat.reach.x: continue
        var busy := occupant(seat) != null
        if (distance >= taken_d if busy else distance >= free_d): continue
        if not clear_line(game.player.global_position+Vector3.UP,seat.point+Vector3.UP*0.5,seat): continue
        if busy:
            taken = seat
            taken_d = distance
        else:
            free = seat
            free_d = distance
    if not free.is_empty() or not any_seat: return free
    return taken

## The seat the focus target offers now ({} when the focus is no seat): what E would take.
func focused_seat() -> Dictionary:
    game.interaction.refresh_focus()
    var item: Node = game.interaction.focus
    if item == null or not by_node.has(item.get_parent()): return {}
    return seat_on(item.get_parent(), true)

## The seat interactable's use: sits on `node` (its nearest free cushion), or says who is there.
func sit_on(node: Node3D) -> bool:
    var seat := seat_on(node)
    if seat.is_empty():
        var taken := seat_on(node, true)
        if taken.is_empty(): return false
        var who: Node = occupant(taken)
        var title := UiText.t("seats.someone")
        if who == null: pass
        elif who.has_meta("character_name"): title = str(who.get_meta("character_name"))
        elif str(who.get_meta("word_key","")) != "":
            var animal := UiText.word(str(who.get_meta("word_key")), UiText.Lexicon.shared().native)
            title = UiText.t("seats.the_word",{"word":animal})
            title = title.left(1).to_upper()+title.substr(1)
        game.hud.flash_quest_message(UiText.t("seats.asleep" if taken.get("bed",false) else "seats.sitting_there",{"who":title}))
        return true
    current = seat
    return_local = seat.node.to_local(game.player.global_position)
    game.interaction.clear_card()
    var point: Vector3 = seat.point
    var forward: Vector3 = seat.forward
    var swing = current_swing()
    if swing:
        # Board the seat where it hangs at rest; the swing eases there meanwhile.
        var rest: Transform3D = swing.rest_seat_transform()
        point = rest*seat.local_point
        forward = (rest.basis*seat.local_forward).normalized()
        swing.board(game.player,seat.local_point+seat.local_forward*0.12-Vector3.UP*0.17)
        swing_exit = false
        swing_keys = Vector2.ONE
    var lie: bool = seat.get("bed",false)
    game.player.begin_sitting(seat_pose(seat,point,forward),atan2(-forward.x,-forward.z),lie)
    if lie:
        game.player.seat_focus = point+Vector3.UP*1.2
        game.hud.flash_quest_message(UiText.maybe(seat.node.get_meta("sit_message","seats.lying")))
        return true
    var message: String = seat.node.get_meta("sit_message","")
    # On a touch screen a message with a "_touch" variant (the swing's) names the joystick, not keys.
    if game.hud.touch_mode and UiText.has(message+"_touch"):
        message = message+"_touch"
    game.hud.flash_quest_message(UiText.maybe(message) if seat.node.has_meta("sit_message") else UiText.t("seats.sitting",{"swivel":UiText.t("seats.swivel_note") if seat.node.get_meta("swivel",false) else ""}))
    return true

## Seats the player on `node`'s seat from a script (a minigame's table, minigame_table.gd):
## the seat's own sitting movement, without the hint line. `stand_back` (local to the node)
## is where standing up starts looking for a free spot. False when `node` is no seat.
func sit_at(node: Node3D, stand_back: Vector3) -> bool:
    for seat in seats:
        if seat.node != node: continue
        if game.player.seated: stand()
        refresh(seat)
        current = seat
        return_local = stand_back
        game.player.begin_sitting(seat_pose(seat,seat.point,seat.forward),atan2(-seat.forward.x,-seat.forward.z))
        return true
    return false

func safe_stand_position() -> Dictionary:
    refresh(current)
    return_position = current.node.to_global(return_local)
    var points: Array[Vector3] = [return_position]
    if current.node.has_meta("stand_position"): points.push_front(current.node.to_global(current.node.get_meta("stand_position")))
    var forward: Vector3 = current.forward
    var side := forward.cross(Vector3.UP)
    for distance in [1.5,2.2,2.9]:
        for direction in [forward,side,-side,-forward]: points.append(current.point+direction*distance)
    for point in points:
        var ray := PhysicsRayQueryParameters3D.create(Vector3(point.x,current.point.y+0.8,point.z),Vector3(point.x,current.point.y-3.0,point.z),game.player.saved_collision_mask & ~FIGURE_LAYER)
        ray.exclude = [game.player.get_rid()]
        var floor_hit: Dictionary=game.get_world_3d().direct_space_state.intersect_ray(ray)
        if floor_hit.is_empty() or floor_hit.normal.y < 0.7: continue
        var foot: Vector3 = floor_hit.position+Vector3.UP*0.06
        if absf(foot.y-return_position.y)>1.0: continue
        # Never step off a bed onto its own mattress or frame.
        if current.get("bed",false) and foot.y > return_position.y+0.3: continue
        var query := PhysicsShapeQueryParameters3D.new()
        query.shape = game.player.get_node("PlayerCollision").shape
        query.transform = Transform3D(Basis.IDENTITY,foot+Vector3.UP*1.1)
        query.collision_mask = game.player.saved_collision_mask
        query.exclude = [game.player.get_rid()]
        if not game.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty(): continue
        if not clear_line(current.point+Vector3.UP*0.8,foot+Vector3.UP, current): continue
        return {"point":foot}
    return {}

func current_swing():
    if current.is_empty() or not is_instance_valid(current.node): return null
    if not current.node.has_meta("playground_swing"): return null
    var swing: Variant = current.node.get_meta("playground_swing")
    return swing if is_instance_valid(swing) else null

func stand() -> void:
    if game.player.sit_transition: return
    var swing = current_swing()
    if swing and not swing.settled():
        # Drag feet: the swing brakes, and the player steps off once it has stopped.
        swing.braking = true
        swing_exit = true
        game.hud.flash_quest_message(UiText.t("seats.swing_brake"))
        return
    var exit := safe_stand_position()
    if exit.is_empty():
        unstuck(swing)
        return
    if swing:
        swing.release()
        swing_exit = false
        # The swing tilted BonBon with it; stand up level.
        game.player.rotation = Vector3(0,game.player.rotation.y,0)
    game.player.end_sitting(exit.point)
    game.hud.flash_quest_message(UiText.t("seats.standing"))

## No clear spot beside the seat (GAME-05, 25 Nov 2026): the last-resort unstuck instead of a dead
## E. A clear spot further off on the same floor and in sight (PlayerPlace.rescue_spot()), else a
## respawn outside the building (Main.respawn(), which also ends a running game).
func unstuck(swing) -> void:
    var ignore: Array[RID] = []
    ignore.append_array(current.get("rids", []))
    var spot := PlayerPlace.rescue_spot(game, current.point, return_position.y, ignore)
    if swing:
        swing.release()
        swing_exit = false
    game.player.rotation = Vector3(0, spot.yaw, 0)
    if spot.how == "nearby":
        game.player.end_sitting(spot.position)
        game.hud.flash_quest_message(UiText.t("seats.standing"))
        return
    if game.player.sit_tween: game.player.sit_tween.kill()
    game.player.finish_standing()
    game.respawn(spot.position, spot.yaw)
    game.hud.flash_quest_message(UiText.t("toast.unstuck"))

## Space (the "jump" action, so the touch Jump button too) gets up like E from any seat or
## bed. Swings and seesaws (meta playground_swing) take it themselves; vehicles never reach
## here (the player is not seated in them).
func _unhandled_input(event: InputEvent) -> void:
    if not event.is_action_pressed("jump"): return
    if not game.player.seated or not game.player.controls_enabled or current_swing() != null: return
    get_viewport().set_input_as_handled()
    stand()

func _physics_process(delta: float) -> void:
    if not game.player.seated or game.player.sit_transition: return
    var swing = current_swing()
    if swing:
        if swing_exit:
            if swing.settled():
                swing_exit = false
                swing.braking = false
                stand()
            return
        # W / S (or Up / Down): one kick per press, forward or backward. The touch joystick
        # sends only move_forward / move_back (with strength), so pushing it more than halfway
        # up or down counts as a press too (25 Nov 2026: the swing did nothing on mobile).
        var keys := Vector2.ZERO
        if game.player.controls_enabled:
            keys = Vector2(
                float(Input.is_action_pressed("climb_up") or Input.get_action_strength("move_forward") > 0.5),
                float(Input.is_action_pressed("climb_down") or Input.get_action_strength("move_back") > 0.5))
        if keys.x > swing_keys.x: swing.kick(1.0)
        elif keys.y > swing_keys.y: swing.kick(-1.0)
        swing_keys = keys
        return
    # Swivel: A / D turn the chair (and the player on it) about the seat's own vertical axis.
    if not game.player.controls_enabled: return
    if current.is_empty() or not is_instance_valid(current.node) or not current.node.get_meta("swivel",false): return
    var turn := Input.get_action_strength("move_left")-Input.get_action_strength("move_right")
    if turn == 0.0: return
    current.node.rotation.y += turn*SWIVEL_SPEED*delta
    follow_seat()
