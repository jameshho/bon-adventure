@tool
extends Node3D
## Adapted floor targeting / close-move-open sequence from Yni-Viar's MIT
## advanced-elevator-system, revision 273438265a4879f9d78759d8db1d5dd8ee24e367.
## See docs/guides/licenses/advanced-elevator-system-LICENSE.txt and HOSPITAL_THREE_FLOORS.md.
## Shared by the hospital (the defaults) and the airport control tower, whose saved node
## carries its own exports (set by the deleted tower_interior.gd pass). Origin = centre of the shaft
## at floor 1; landing doors face local -Z.
## 29 Oct 2026: every landing gains a framed outer door with threshold and a call button that
## lights while the car is called; hospital floors, sizes and behaviour are otherwise unchanged.
## 31 Oct 2026: the hospital's lift moved to a side tower with a fourth stop on the roof
## (roof_stop: last stop is AZOTEA, button "A", key 4).
## 10 Nov 2026 (user): the landing and cabin buttons are ElevatorCallButtons (glow while their stop
## is called; the old landing button and lamp are gone), and the car waits DEPART_DELAY s with its
## doors open before it leaves, so a rider can choose a floor, step out and send it on alone.
## 10 Nov 2026 review (user: "make all the improvements"): doors no longer sink half into the floor;
## short headers (tower top) fit their title and number; the car eases (ACCEL, MAX_SPEED), stops
## at called floors it passes and leaves queued stops without an extra dwell; the cabin panel sits
## on the front jamb beside the door; light panel, steel doors with a seam, back panel, kick
## plates and a floor mat; two-speed doors that tuck behind the jambs; a window-scaled hint card
## under the clock; signals for sound.
## 10 Nov 2026 rebuild (user: flicker, gaps, "the elevator and the buttons look bad"): shaft walls
## in one piece with no slot between stops and flush door walls; the car 1 cm clear of the shaft,
## a full front wall with the number display centred above the door, a floor finish 3 cm above
## the collision floor (the tower's lobby floor crossed the car floor in the same plane and
## flickered); one steel cabin panel with round numbered buttons; no "choose a floor" card. The
## control tower's shaft is wider (scripts/buildings/airport.gd widen_tower_elevator).
## 12 Nov 2026 (interaction system, docs/guides/ARCHITECTURE_REVIEW_PART1.md#interaction-system): E,
## clicks and taps reach the landing and cabin buttons through their interactables; the
## landing hint card and this node's own E / click handling were removed. Keys 1-4 in the car stay.
## 14 Nov 2026 (user): E at the cabin panel (its own interactable, or E while a cabin button is
## aimed at) opens the floor picker (scripts/ui/elevator_floor_picker.gd): the camera glides to a
## close-up of the panel and a tap on a button calls the car there. A click or tap on a cabin
## button outside the picker still presses it; its pick box is 1.5x wider (clipped to the pitch).

signal arrived(floor_index: int)
## Sound-ready (no audio yet): doors start to open / close at a stop, the car leaves for a stop.
signal doors_opening(floor_index: int)
signal doors_closing(floor_index: int)
signal departed(from_floor: int, to_floor: int)
enum State { OPEN, CLOSING, MOVING, OPENING, WAITING }
## Floor heights above floor 1 (hospital: three floors 5.6 apart).
@export var floor_ys: Array[float] = [0.0,5.6,11.2]
## Shaft footprint: width along x, depth along z (doors on -Z); one door leaf; door height.
@export var shaft_w := 5.0
@export var shaft_d := 5.2
@export var leaf := 1.5
@export var door_h := 3.2
## Wall height above the top floor's level (< 0: same as the lower floors).
@export var top_wall_h := -1.0
## The last stop is the roof terrace (AZOTEA) rather than a numbered floor.
@export var roof_stop := false
## Top speed (town units/s) and acceleration: the car eases in and out (was a constant 2.0).
const MAX_SPEED := 3.0
const ACCEL := 3.5
var speed := 0.0
## Seconds the doors stay open after a floor is chosen before they close (user, 10 Nov 2026).
const DEPART_DELAY := 2.0
const CallButton := preload("res://scenes/props/fixtures/elevator_call_button.tscn")
const Interactable := preload("res://scripts/core/interactable.gd")
## Cabin panel: height of its centre above the car floor, button radius and the buttons' pitch.
const PANEL_Y := 1.3
const CABIN_BUTTON_R := .07
const BUTTON_PITCH := .22
## Cabin button pick box: 1.5x the default 2.8 r square (user, 14 Nov 2026), its height clipped
## to the pitch less a 4 mm gap so neighbouring targets never overlap.
const CABIN_PICK := Vector2(CABIN_BUTTON_R*2.8*1.5, minf(CABIN_BUTTON_R*2.8*1.5, BUTTON_PITCH-.004))
## Cabin buttons glow sky blue (landing buttons keep the amber of the old call lamps).
const CABIN_GLOW := Color("3fb4ff")
## Floor identity colours, then the roof; keep in sync with TINTS in tools/build_hospital_remodel.py.
const FLOOR_TINTS := [Color("2a9d8f"), Color("3d7fc1"), Color("e38b3c"), Color("6d8f9c")]
const SHAFT := Color("f1ede4")
const STEEL := Color("b4bfc2")
const CABIN := Color("efe9dd")
const TRIM := Color("e9ecec")
const DISPLAY := Color("1c2326")
const DISPLAY_TEXT := Color("ffb347")
## Shaft wall and door wall thickness; car inside height (the number display sits above the door).
const WALL := .16
const FRONT := .18
const CAR_H := 3.8
const FINISH := .05
var state := State.OPEN
var current_floor := 0
var target_floor := 0
var door_fraction := 1.0
var car: AnimatableBody3D
var landing_doors: Array[Node3D] = []
## ElevatorCallButtons: one per landing (`Button<i>` on this node) and one per stop in the car.
var landing_buttons: Array[Node3D] = []
var cabin_buttons: Array[Node3D] = []
var car_doors: Node3D
var player: CharacterBody3D
var pending: Array[int] = []
var dwell := 0.0
var depart_wait := 0.0
var status_labels: Array[Label3D] = []
## Landing titles (one per stop); their words follow the world language every frame
## (sign_language.gd say(), 9 Nov 2026). The status line above each landing door and the car's
## display show only the car's stop number (user, 10 Nov 2026).
var title_labels: Array[Label3D] = []
var car_label: Label3D
## The steel strip holding the cabin buttons (its face is the car's +Z); E there opens the picker.
var cabin_panel: Node3D
const SignLanguage := preload("res://scripts/world/sign_language.gd")

func hw() -> float: return shaft_w/2.0
func hd() -> float: return shaft_d/2.0
## Car outer size: 1 cm clear of the shaft's side walls and its door wall, 2 cm of the rear wall
## (was shaft - .2, whose side walls cut 4 cm into the shaft's).
func cw() -> float: return shaft_w-.3
func cd() -> float: return shaft_d-.32
func floors() -> int: return floor_ys.size()
func is_roof(i: int) -> bool: return roof_stop and i==floors()-1
## Button / status name and landing title of a stop.
func stop_name(i: int) -> String: return "A" if is_roof(i) else str(i+1)
func stop_title(i: int) -> String: return SignLanguage.say("ROOF") if is_roof(i) else SignLanguage.say("FLOOR")+" "+str(i+1)
## The stop the car is at or passing (nearest floor level): its number is on every display.
func car_stop() -> int:
    var best := 0
    for i in range(floors()):
        if absf(floor_ys[i]-car.position.y) < absf(floor_ys[best]-car.position.y): best = i
    return best
func stop_tint(i: int) -> Color: return FLOOR_TINTS[3] if is_roof(i) else FLOOR_TINTS[i%3]
func wall_h(i: int) -> float:
    if i+1<floors(): return floor_ys[i+1]-floor_ys[i]-.2
    return top_wall_h if top_wall_h>=0.0 else floor_ys[floors()-1]-floor_ys[floors()-2]-.2

func box(parent: Node3D, title: String, pos: Vector3, size: Vector3, color: Color, solid := true, moving := false, visual_size := Vector3.ZERO) -> Node3D:
    var body: Node3D = (AnimatableBody3D.new() if moving else StaticBody3D.new()) if solid else Node3D.new()
    body.name = title
    # Before add_child: an AnimatableBody3D entering the tree with sync_to_physics on keeps its
    # physics transform, which put every door leaf's centre at the floor (half the door
    # underground, found 10 Nov 2026).
    if body is AnimatableBody3D: body.sync_to_physics = false
    body.position = pos
    parent.add_child(body)
    var mesh := MeshInstance3D.new()
    var cube := BoxMesh.new()
    cube.size = size if visual_size == Vector3.ZERO else visual_size
    mesh.mesh = cube
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = .65
    mesh.material_override = mat
    body.add_child(mesh)
    if solid:
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        collision.shape = shape
        body.add_child(collision)
    return body

func label(parent: Node3D, text: String, pos: Vector3, font_size := 28, face_front := true) -> Label3D:
    var result := Label3D.new()
    parent.add_child(result)
    result.position = pos
    result.rotation.y = PI if face_front else 0.0
    result.text = text
    result.font_size = font_size
    result.pixel_size = .008
    # The elevator rewrites its own words; sign_language.gd leaves them alone.
    result.set_meta("sign_dynamic", true)
    return result

func doors(parent: Node3D, y: float, z: float) -> Node3D:
    var pair := Node3D.new()
    parent.add_child(pair)
    pair.position = Vector3(0,y,z)
    # Two-speed doors (10 Nov 2026): each side is a fast panel by the centre and a slow one beside
    # it, in planes 5.6 cm apart; open, both stack behind the jamb (a single leaf wider than the
    # jamb stuck out past the free-standing tower shaft). Children: Left, Right (the centre
    # panels), LeftSlow, RightSlow. Brushed steel; the centre panels' meshes leave a 2 cm seam.
    for k in [0,1]:
        for side in [-1,1]:
            var title: String = ("Left" if side<0 else "Right")+("" if k==0 else "Slow")
            var size := Vector3(leaf/2.0,door_h,.05)
            var panel := box(pair,title,Vector3(side*leaf*(.25 if k==0 else .75),door_h/2.0,-.028 if k==0 else .028),size,STEEL,true,true,size-Vector3(.01 if k==0 else 0.0,0,0))
            var mat: StandardMaterial3D = panel.get_child(0).material_override
            mat.metallic = .55
            mat.roughness = .35
    return pair

## An ElevatorCallButton (scripts/world/elevator_call_button.gd) on `parent` with its back at `pos`,
## facing -Z like the doors (face_back false: facing +Z, into the car). No caption: a landing
## button on its own steel plate (amber, ▲▼ on the face); a caption: a cabin button on the car's
## panel with the stop's number on its face and an ice-blue glow.
func call_button(parent: Node3D, pos: Vector3, floor_index: int, caption := "", face_back := true) -> Node3D:
    var b: Node3D = CallButton.instantiate()
    b.name = "Button"+str(floor_index)
    b.floor_index = floor_index
    if caption != "":
        b.caption = caption
        b.glow_color = CABIN_GLOW
        b.plate_size = Vector2.ZERO
        b.button_radius = CABIN_BUTTON_R
        b.pick_size = CABIN_PICK
        b.picker_on_e = true
    parent.add_child(b)
    b.position = pos
    b.rotation.y = PI if face_back else 0.0
    b.elevator = b.get_path_to(self)
    return b

## Dark display with the car's stop number in amber (landings above the door, the car above its
## door inside). `facing_back`: the landing side (-Z).
func number_display(parent: Node3D, pos: Vector3, facing_back: bool, font_size: int) -> Label3D:
    var out := -1.0 if facing_back else 1.0
    var panel := box(parent,"NumberDisplay",pos+Vector3(0,0,out*.01),Vector3(.62,.38,.02),DISPLAY,false)
    var mat: StandardMaterial3D = panel.get_child(0).material_override
    mat.roughness = .15
    var number := label(parent,stop_name(0),pos+Vector3(0,0,out*.035),font_size,facing_back)
    number.modulate = DISPLAY_TEXT
    number.outline_size = 0
    number.double_sided = false
    return number

func _ready() -> void:
    # Rebuilt 10 Nov 2026 (user: flicker, gaps, looks). Every part meets its neighbours face to
    # face or overlaps them; no two visible faces share a plane. Shaft: side and rear walls in one
    # piece from floor 1 to the top, a cap, and per stop a door wall (jambs and the floor-tinted
    # header up to the next stop, no slot between stops) whose ends are flush with the side walls.
    var top: float = floor_ys[floors()-1]+wall_h(floors()-1)
    var bottom: float = floor_ys[0]
    var outer := hw()+WALL/2.0
    for x in [-hw(),hw()]:box(self,"ShaftSide",Vector3(x,(bottom+top)/2.0,(FRONT-WALL)/4.0),Vector3(WALL,top-bottom,shaft_d-FRONT/2.0-WALL/2.0),SHAFT)
    box(self,"ShaftRear",Vector3(0,(bottom+top)/2.0,hd()),Vector3(outer*2.0,top-bottom,WALL),SHAFT)
    box(self,"ShaftCap",Vector3(0,top-.1,0),Vector3(shaft_w,.16,shaft_d),SHAFT,false)
    var jamb_w := outer-leaf
    for i in range(floors()):
        var y: float = floor_ys[i]
        var next: float = floor_ys[i+1] if i+1<floors() else top
        # The wall changes 1 cm below each floor level: a floor slab's top there would share the
        # header's top plane (flickered at the hospital's floors and the tower's radar deck).
        var seam := next-.01 if i+1<floors() else top
        for side in [-1,1]:box(self,"DoorJamb",Vector3(side*(leaf+jamb_w/2.0),y-.01+(door_h+.01)/2.0,-hd()),Vector3(jamb_w,door_h+.01,FRONT),TRIM)
        box(self,"DoorHeader",Vector3(0,(y+door_h+seam)/2.0,-hd()),Vector3(outer*2.0,seam-y-door_h,FRONT),stop_tint(i))
        landing_doors.append(doors(self,y,-hd()-.01))
        # Outer door frame: proud steel trim round the opening and a threshold plate.
        for x in [-(leaf+.07),leaf+.07]:box(self,"LandingFrame",Vector3(x,y+door_h/2.0+.02,-hd()-FRONT/2.0-.015),Vector3(.14,door_h+.04,.03),STEEL,false)
        box(self,"LandingFrame",Vector3(0,y+door_h+.11,-hd()-FRONT/2.0-.015),Vector3(leaf*2+.28,.14,.03),STEEL,false)
        box(self,"LandingThreshold",Vector3(0,y+.0265,-hd()),Vector3(leaf*2,.047,FRONT),Color("8d9a9e"),false)
        # Floor title above a number display showing where the car is; a short header (the
        # tower's top stop) gets a smaller title.
        var header := next-y-door_h
        var short := header < 1.7
        title_labels.append(label(self,stop_title(i),Vector3(0,y+door_h+(.88 if short else 1.0),-hd()-FRONT/2.0-.015),44 if short else 64))
        status_labels.append(number_display(self,Vector3(0,y+door_h+.42,-hd()-FRONT/2.0),true,44))
        # Call button on its plate on the right-hand jamb seen from the landing, beside the
        # frame (the old ↑↓ button and lamp on the left were removed on 10 Nov 2026).
        landing_buttons.append(call_button(self,Vector3(-(leaf+.45),y+1.35,-hd()-FRONT/2.0),i))
    car = AnimatableBody3D.new()
    car.name = "Car"
    car.sync_to_physics = false
    add_child(car)
    # Car shell, .12 thick, 1 cm clear of the shaft and the door wall: floor (its finish FINISH
    # above the collision floor, clear of a room floor, plinth or carpet crossing the shaft; the
    # tower's lobby plinth top is 3.6 cm up and showed through the old floor), walls between the
    # front and back walls, a front wall of two jambs and a header holding the number display.
    var iw := cw()/2.0-.06
    var front := -cd()/2.0
    var car_jamb := cw()/2.0+.06-leaf
    var shell := [
        ["CabinFloor",Vector3(0,FINISH-.1,0),Vector3(cw()+.12,.2,cd()+.12),Color("c9c2b4")],
        ["CabinCeiling",Vector3(0,CAR_H+.06,0),Vector3(cw()+.12,.12,cd()+.12),CABIN],
        ["CabinWall",Vector3(-cw()/2.0,(CAR_H+FINISH)/2.0,0),Vector3(.12,CAR_H-FINISH,cd()-.12),CABIN],
        ["CabinWall",Vector3(cw()/2.0,(CAR_H+FINISH)/2.0,0),Vector3(.12,CAR_H-FINISH,cd()-.12),CABIN],
        ["CabinWall",Vector3(0,(CAR_H+FINISH)/2.0,cd()/2.0),Vector3(cw()+.12,CAR_H-FINISH,.12),CABIN],
        ["CarJamb",Vector3(-(leaf+car_jamb/2.0),(door_h+FINISH)/2.0,front),Vector3(car_jamb,door_h-FINISH,.12),TRIM],
        ["CarJamb",Vector3(leaf+car_jamb/2.0,(door_h+FINISH)/2.0,front),Vector3(car_jamb,door_h-FINISH,.12),TRIM],
        ["CarHeader",Vector3(0,(door_h+CAR_H)/2.0,front),Vector3(cw()+.12,CAR_H-door_h,.12),TRIM]]
    for spec in shell:box(car,spec[0],spec[1],spec[2],spec[3],false)
    # A single moving body owns all cabin collision shapes (floor top at the stop's level).
    for spec in [[Vector3(0,-.1,0),Vector3(cw()+.12,.2,cd()+.12)],[Vector3(-cw()/2.0,CAR_H/2.0,0),Vector3(.12,CAR_H,cd())],[Vector3(cw()/2.0,CAR_H/2.0,0),Vector3(.12,CAR_H,cd())],[Vector3(0,CAR_H/2.0,cd()/2.0),Vector3(cw(),CAR_H,.12)],[Vector3(0,CAR_H+.06,0),Vector3(cw(),.12,cd())],
            [Vector3(-(leaf+car_jamb/2.0),door_h/2.0,front),Vector3(car_jamb,door_h,.12)],[Vector3(leaf+car_jamb/2.0,door_h/2.0,front),Vector3(car_jamb,door_h,.12)],[Vector3(0,(door_h+CAR_H)/2.0,front),Vector3(cw(),CAR_H-door_h,.12)]]:
        var shape := CollisionShape3D.new()
        var cube := BoxShape3D.new()
        cube.size = spec[1]
        shape.shape = cube
        shape.position = spec[0]
        car.add_child(shape)
    car_doors = doors(car,0,front)
    box(car,"CarSill",Vector3(0,FINISH+.005,front),Vector3(leaf*2,.01,.12),STEEL,false)
    # The car's number display centred above the door (user, 10 Nov 2026: "move the number to
    # the top"; only the stop number).
    car_label = number_display(car,Vector3(0,(door_h+CAR_H)/2.0,front+.06),false,52)
    # Cabin panel: a brushed steel strip on the inside of the right-hand front jamb, buttons in
    # one column (floor 1 at the bottom), each with a floor-colour tag beside it; a rider can
    # choose a floor and step straight out.
    var panel_x := (leaf+iw)/2.0
    var panel := box(car,"CabinPanel",Vector3(panel_x,PANEL_Y,front+.06+.007),Vector3(panel_size().x,panel_size().y,.014),Color("c3c7c9"),false)
    cabin_panel = panel
    var panel_mat: StandardMaterial3D = panel.get_child(0).material_override
    panel_mat.metallic = .5
    panel_mat.roughness = .38
    _make_panel_interactive(panel)
    for i in range(floors()):
        var at := Vector3(panel_x+.045,PANEL_Y+(i-(floors()-1)/2.0)*BUTTON_PITCH,front+.06+.014)
        cabin_buttons.append(call_button(car,at,i,stop_name(i),false))
        box(car,"FloorTag",at+Vector3(-.135,0,.002),Vector3(.045,.045,.004),stop_tint(i),false)
    # Wooden handrails on steel brackets 2 cm off the side and back walls.
    for x in [-1,1]:
        box(car,"CabinHandrail",Vector3(x*(iw-.05),1.0,.2),Vector3(.06,.06,cd()-1.4),Color("a8774e"),false)
        for z in [.2-(cd()-1.6)/2.0,.2+(cd()-1.6)/2.0]:box(car,"HandrailBracket",Vector3(x*(iw-.01),1.0,z),Vector3(.02,.04,.04),STEEL,false)
    box(car,"CabinHandrail",Vector3(0,1.0,cd()/2.0-.06-.05),Vector3(iw*2.0-.5,.06,.06),Color("a8774e"),false)
    for x in [-(iw-.45),iw-.45]:box(car,"HandrailBracket",Vector3(x,1.0,cd()/2.0-.06-.01),Vector3(.04,.04,.02),STEEL,false)
    # Light panel on the ceiling, a brushed back panel above the handrail, steel kick plates on
    # the walls and a floor mat on the finished floor.
    var lamp := box(car,"CabinLightPanel",Vector3(0,CAR_H-.01,0),Vector3(minf(1.8,cw()-.8),.02,minf(1.2,cd()-1.0)),Color("fffaf0"),false)
    var lamp_mat: StandardMaterial3D = lamp.get_child(0).material_override
    lamp_mat.emission_enabled = true
    lamp_mat.emission = Color("fff4dc")
    lamp_mat.emission_energy_multiplier = 1.2
    var back := box(car,"CabinBackPanel",Vector3(0,2.25,cd()/2.0-.07),Vector3(cw()-.8,1.6,.02),Color("c9d1d3"),false)
    var back_mat: StandardMaterial3D = back.get_child(0).material_override
    back_mat.metallic = .6
    back_mat.roughness = .2
    for spec in [[Vector3(-iw+.01,FINISH+.13,0),Vector3(.02,.26,cd()-.42)],[Vector3(iw-.01,FINISH+.13,0),Vector3(.02,.26,cd()-.42)],[Vector3(0,FINISH+.13,cd()/2.0-.07),Vector3(iw*2.0-.3,.26,.02)]]:
        box(car,"CabinKickPlate",spec[0],spec[1],STEEL,false)
    box(car,"CabinFloorMat",Vector3(0,FINISH+.003,.15),Vector3(iw*2.0-.5,.006,cd()-.8),Color("b5ab98"),false)
    for child in car.get_children():
        if child.name.begins_with("CabinKickPlate") or child.name.begins_with("CarSill") or child.name.begins_with("HandrailBracket"):
            var steel: StandardMaterial3D = child.get_child(0).material_override
            steel.metallic = .7
            steel.roughness = .3

    var light := OmniLight3D.new()
    car.add_child(light)
    light.position = Vector3(0,CAR_H-.5,0)
    light.omni_range = 6
    light.light_energy = 1.0
    update_doors()
    # Parts hung on the car (the tower's picking box, from the deleted tower_interior.gd) come back from a
    # saved town (modular town, 6 Nov 2026) as children of this node: put them on the new car.
    for child in get_children():
        if child.has_meta("ride_with_car"):
            child.reparent(car, false)

## Cabin panel width x height.
func panel_size() -> Vector2: return Vector2(.32,floors()*BUTTON_PITCH+.2)

## The panel answers E (and a click on its steel between the buttons) with the floor picker. Its
## pick is an Area3D just behind the buttons' own picks (they stay in front for direct clicks), so
## it never blocks the player.
func _make_panel_interactive(panel: Node3D) -> void:
    if Engine.is_editor_hint(): return
    var area := Area3D.new()
    area.name = "PanelPick"
    area.monitoring = false
    var shape := CollisionShape3D.new()
    var cube := BoxShape3D.new()
    cube.size = Vector3(panel_size().x+.04,panel_size().y+.04,.02)
    shape.shape = cube
    shape.position.z = .005
    area.add_child(shape)
    panel.add_child(area)
    # In front of the panel within the cabin's reach (as the buttons: about 4 m from the hospital
    # car's middle); no aim needed, so E anywhere facing it works.
    Interactable.attach(panel, {
        "prompt_distance": 4.2,
        "priority": 0.35,
        "badge_offset": Vector3(0,panel_size().y/2.0+.12,.05),
        "on_use": func() -> void: open_floor_picker(),
        # Reach is measured to the panel at the player's height (it hangs 1.3 m up).
        "on_point": func(from: Vector3) -> Vector3:
            var p := panel.global_position
            return Vector3(p.x,from.y,p.z),
    })

## Opens the floor picker on this car's panel (scripts/ui/elevator_floor_picker.gd). True when it opened.
func open_floor_picker() -> bool:
    for picker in get_tree().get_nodes_in_group("elevator_floor_picker"):
        if picker.has_method("open"):
            return picker.open(self)
    return false

## Camera transform for the picker's close-up: straight in front of the cabin panel, which fills
## `fill` of the view height at vertical field of view `fov` (degrees).
func panel_view_transform(fov: float, fill := 0.72) -> Transform3D:
    var scale_y := cabin_panel.global_transform.basis.get_scale().y
    var distance := (panel_size().y*scale_y/fill)*.5/tan(deg_to_rad(fov)*.5)
    var face := (cabin_panel.global_transform.basis*Vector3(0,0,1)).normalized()
    var target := cabin_panel.to_global(Vector3(0,0,.02))
    return Transform3D(Basis(),target+face*distance).looking_at(target,Vector3.UP)

func inside_car() -> bool:
    if not is_instance_valid(player): return false
    var p := car.to_local(player.global_position)
    return absf(p.x)<cw()/2.0-.15 and p.z> -cd()/2.0+.6 and p.z<cd()/2.0-.25 and p.y> -.25 and p.y<CAR_H-.1

func obstructed() -> bool:
    if not is_instance_valid(player): return false
    var p := to_local(player.global_position)
    # Expanded by the actual capsule radius at town scale; keep both door planes clear.
    return absf(p.x)<hw()-.35 and p.z> -hd()-.9 and p.z< -hd()+1.0 and absf(p.y-floor_ys[current_floor])<2.0

func call_elevator(floor_index: int) -> void:
    if floor_index<0 or floor_index>=floors(): return
    if state != State.OPEN:
        # A call at the floor the car is still standing at (user, 10 Nov 2026): hold it like a
        # door-open button, so it takes the caller along instead of queueing a return trip.
        # Waiting: the 2 s start again; closing: the doors reopen and the wait starts again.
        if floor_index == current_floor and state == State.WAITING:
            depart_wait = DEPART_DELAY
            return
        if floor_index == current_floor and state == State.CLOSING:
            state = State.OPENING
            doors_opening.emit(current_floor)
            return
        if floor_index != target_floor and floor_index not in pending: pending.append(floor_index)
        return
    if floor_index == current_floor: return
    target_floor = floor_index
    state = State.WAITING
    depart_wait = DEPART_DELAY

## Whether stop `i` is called and not yet reached: queued, or the trip's target until the car
## arrives there. Read-only; ElevatorCallButton glows from it.
func is_floor_requested(i: int) -> bool:
    return i in pending or (i == target_floor and i != current_floor and state != State.OPEN)

func retarget_en_route() -> void:
    var dir := signf(floor_ys[target_floor]-car.position.y)
    var stopping := speed*speed/(2.0*ACCEL)+.05
    var best := -1
    for p in pending:
        var ahead := (floor_ys[p]-car.position.y)*dir
        if ahead > stopping and ahead < (floor_ys[target_floor]-car.position.y)*dir:
            if best < 0 or ahead < (floor_ys[best]-car.position.y)*dir: best = p
    if best >= 0:
        pending.erase(best)
        pending.push_front(target_floor)
        target_floor = best

func update_doors() -> void:
    for i in range(landing_doors.size()):
        set_pair(landing_doors[i],door_fraction if i==current_floor and state!=State.MOVING else 0.0)
    set_pair(car_doors,door_fraction)

func set_pair(pair: Node3D, fraction: float) -> void:
    # Centre panels travel leaf+.05, the slow ones half as far; open, both sit side by side behind
    # the jamb at |x| = leaf+.05 .. leaf*1.5+.05.
    pair.get_child(0).position.x = -leaf*.25-(leaf+.05)*fraction
    pair.get_child(1).position.x = leaf*.25+(leaf+.05)*fraction
    pair.get_child(2).position.x = -leaf*.75-(leaf*.5+.05)*fraction
    pair.get_child(3).position.x = leaf*.75+(leaf*.5+.05)*fraction

func _physics_process(delta: float) -> void:
    if Engine.is_editor_hint(): return
    if not is_instance_valid(player): player = get_tree().root.find_child("BonBonPlayer",true,false) as CharacterBody3D
    if state == State.WAITING:
        # Doors stay open DEPART_DELAY s; someone in the doorway holds the car until it is clear.
        depart_wait = maxf(0,depart_wait-delta)
        if depart_wait == 0 and not obstructed():
            state = State.CLOSING
            doors_closing.emit(current_floor)
    elif state == State.CLOSING:
        if obstructed():
            state = State.OPENING
            doors_opening.emit(current_floor)
        else:
            door_fraction = move_toward(door_fraction,0.0,delta*1.25)
            if door_fraction == 0.0:
                state = State.MOVING
                speed = 0.0
                departed.emit(current_floor,target_floor)
    elif state == State.MOVING:
        # A called floor the car is about to pass, with room to stop, becomes the next stop; the
        # trip's target waits at the front of the queue (10 Nov 2026).
        retarget_en_route()
        # Physics-step motion of a vertical AnimatableBody3D (adapted from the upstream waypoint
        # motion), now eased: accelerate to MAX_SPEED, brake so it stops exactly at the floor.
        # Godot carries grounded CharacterBody3D passengers.
        var left := absf(floor_ys[target_floor]-car.position.y)
        speed = minf(minf(speed+ACCEL*delta,MAX_SPEED),sqrt(2.0*ACCEL*left)+ACCEL*delta*.5)
        car.position.y = move_toward(car.position.y,floor_ys[target_floor],speed*delta)
        if is_equal_approx(car.position.y,floor_ys[target_floor]):
            current_floor = target_floor
            speed = 0.0
            state = State.OPENING
            arrived.emit(current_floor)
            doors_opening.emit(current_floor)
    elif state == State.OPENING:
        door_fraction = move_toward(door_fraction,1.0,delta*1.25)
        if door_fraction == 1.0:
            if target_floor != current_floor:
                # Reopened for someone in the doorway: the call is kept and leaves after the delay.
                state = State.WAITING
                depart_wait = DEPART_DELAY
            else:
                # No extra dwell before a queued stop: its own DEPART_DELAY wait follows (was
                # 1.5 s + 2 s per stop).
                state = State.OPEN
                dwell = 0.0
    elif state == State.OPEN:
        dwell = maxf(0,dwell-delta)
        if dwell == 0 and not pending.is_empty() and not obstructed(): call_elevator(pending.pop_front())
    update_doors()
    var number := stop_name(car_stop())
    for status in status_labels: status.text = number
    for i in title_labels.size(): title_labels[i].text = stop_title(i)
    car_label.text = number

func nearby_floor() -> int:
    if not is_instance_valid(player): return -1
    var p := to_local(player.global_position)
    for i in range(floors()):
        if absf(p.x)<hw() and p.z< -hd()+.1 and p.z> -hd()-1.9 and absf(p.y-floor_ys[i])<.5: return i
    return -1

func _input(event: InputEvent) -> void:
    if Engine.is_editor_hint() or not is_instance_valid(player) or not player.get("controls_enabled") or player.get("riding_vehicle")!=null or player.get("seated")==true: return
    if event is InputEventKey and event.pressed and not event.echo:
        if inside_car() and event.physical_keycode>=KEY_1 and event.physical_keycode<KEY_1+floors():
            call_elevator(event.physical_keycode-KEY_1)
            get_viewport().set_input_as_handled()
