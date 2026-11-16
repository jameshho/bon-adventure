extends Node3D
## One fitting cabin (saved in the clothing unit; the deleted clothing_interior.gd built it;
## its own file since 6 Nov 2026 so the modular town can save it): watches whether BonBon sits on its pouf (seating_controller seat with
## sit_root = this node) and closes/opens the curtain.
##
## Outfit picker (user request, 9 Nov 2026; guide: docs/guides/TOWN_DESIGN_BRIEF.md "Fitting room
## outfit picker"): once she is seated the shared picker (scripts/ui/outfit_picker.gd) opens
## at the bottom of the screen. A click on a card, or A / D / ← / →, dresses her at once (she is
## the preview, in the cabin mirror). "Keep this look" or Enter saves the outfit
## (GameSettings.outfit) and she steps out wearing it; Cancel, Esc, E or Space puts back what
## she came in with and she steps out. Any way of standing up that was not Keep restores it.
## Dressing goes through PlushCostume.dress_player(), shared with Main's startup.
## Mirror view: the pouf faces the cabin's back wall, so the player camera only saw her back.
## While the picker is open she turns round to face the curtain and a preview camera in front
## of the cabin shows her; the curtain is on its own render layer, hidden from that camera only.
## Processing keeps the cabin out of render_culling's static batches.
const PlushCostume := preload("res://scripts/characters/plush_costume.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const OutfitPicker := preload("res://scripts/ui/outfit_picker.gd")
var game
@export var pouf: Node3D
@export var curtain: Node3D
@export var left_x := 0.0
@export var closed := 0.0
## One picker for every cabin, added to the HUD the first time anyone sits.
static var picker: Control
## BonBon is seated here with the picker open; `entered_in` is what she came in with,
## `trying` what she has on now.
var active := false
var entered_in := ""
var trying := ""
## Render layer 20: the curtain while the mirror view is on (no other visual uses it).
const CURTAIN_LAYER := 1 << 19
## The mirror view: distance in front of the pouf, camera height and the height it looks at
## (BonBon seated is about 2.5 tall; the picker covers the bottom third of the screen).
const PREVIEW_DISTANCE := 3.0
const PREVIEW_HEIGHT := 1.9
const PREVIEW_LOOK := 1.15
const TURN_TIME := 0.45
var preview: Camera3D
var _turn: Tween
var _curtain_layers: Dictionary = {}

func _ready() -> void:
    if game == null:
        game = preload("res://scripts/world/modular_town.gd").find_game(self)

func set_curtain(amount: float) -> void:
    # amount 0 = bunched open (0.25 wide at the left), 1 = closed (1.15 wide).
    closed=amount
    var width:=lerpf(.25,1.15,amount)
    curtain.scale.x=width/1.15
    curtain.position.x=left_x+width/2.0

func inside() -> bool:
    if game==null or not is_instance_valid(game.player) or not game.player.seated: return false
    var seat: Dictionary=game.seating.current if game.seating else {}
    return not seat.is_empty() and seat.get("node")==pouf

func _process(delta: float) -> void:
    if curtain==null: return
    var seated: bool=inside() and not game.player.sit_transition
    if seated and not active: _enter()
    elif active and not seated: _leave()
    var target:=1.0 if seated else 0.0
    if absf(closed-target)>.001: set_curtain(move_toward(closed,target,delta*2.5))

func _unhandled_input(event: InputEvent) -> void:
    if not active or not (event is InputEventKey and event.pressed and not event.echo): return
    if not game.player.controls_enabled: return
    match event.physical_keycode:
        KEY_A, KEY_LEFT: _step(-1)
        KEY_D, KEY_RIGHT: _step(1)
        KEY_ENTER, KEY_KP_ENTER: keep()
        _: return
    get_viewport().set_input_as_handled()

## The shared picker, made on first use; Esc (Main's popup stack) acts as its Cancel.
func _picker() -> Control:
    if not is_instance_valid(picker):
        picker = OutfitPicker.new()
        game.hud.ui_root.add_child(picker)
        game.popups.watch(picker, func() -> void: picker.cancelled.emit())
    return picker

func _enter() -> void:
    active = true
    entered_in = GameSettings.shared().outfit
    trying = entered_in
    var panel := _picker()
    panel.picked.connect(try_on)
    panel.kept.connect(keep)
    panel.cancelled.connect(cancel)
    panel.open(PlushCostume.outfit_ids(), trying)
    _mirror_view(true)

## BonBon stood up (Keep, Cancel, E, Space or anything else): close the picker and put back
## the outfit she came in with unless she kept the one she has on.
func _leave() -> void:
    active = false
    if is_instance_valid(picker):
        picker.picked.disconnect(try_on)
        picker.kept.disconnect(keep)
        picker.cancelled.disconnect(cancel)
        picker.hide_picker()
    if trying != entered_in:
        try_on(entered_in)
    _mirror_view(false)

## Turns BonBon to face the curtain and cuts to a camera in front of the cabin (on), or turns
## her back and hands the view back to the player camera (off).
func _mirror_view(on: bool) -> void:
    var player_camera: Camera3D = game.player.camera
    var visual: Node3D = game.player.get_node("Visual")
    if _turn: _turn.kill()
    _turn = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    _turn.tween_property(visual, "rotation:y", PI if on else 0.0, TURN_TIME)
    if on:
        var seat: Dictionary = game.seating.current
        var out: Vector3 = -seat.get("forward", -global_basis.z)
        var base := pouf.global_position
        if preview == null:
            preview = Camera3D.new()
            preview.name = "Mirror view"
            add_child(preview)
        preview.fov = player_camera.fov
        preview.cull_mask = player_camera.cull_mask & ~CURTAIN_LAYER
        var target := Transform3D(Basis(), base + out * PREVIEW_DISTANCE + Vector3.UP * PREVIEW_HEIGHT).looking_at(base + Vector3.UP * PREVIEW_LOOK, Vector3.UP)
        # A cut, not a glide: a glide from behind her passes through her head and the cabin.
        preview.global_transform = target
        preview.make_current()
        _curtain_layers.clear()
        for node in [curtain] + curtain.find_children("*", "VisualInstance3D", true, false):
            if node is VisualInstance3D:
                _curtain_layers[node] = node.layers
                node.layers = CURTAIN_LAYER
    else:
        for node in _curtain_layers:
            if is_instance_valid(node): node.layers = _curtain_layers[node]
        _curtain_layers.clear()
        if preview and preview.current:
            player_camera.make_current()

func _step(step: int) -> void:
    var ids := PlushCostume.outfit_ids()
    try_on(ids[posmod(ids.find(trying) + step, ids.size())])

## Dresses BonBon in `id` while she is in the cabin.
func try_on(id: String) -> void:
    trying = id
    PlushCostume.dress_player(game.player, id)
    if is_instance_valid(picker): picker.select(id)

func keep() -> void:
    if not active: return
    GameSettings.shared().set_outfit(trying)
    entered_in = trying
    game.seating.stand()

func cancel() -> void:
    if not active: return
    if trying != entered_in: try_on(entered_in)
    game.seating.stand()
