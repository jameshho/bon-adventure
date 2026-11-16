extends CanvasLayer
## A small performance readout for measuring on a phone (14 Nov 2026): frames per second, the
## average and slowest frame time, draw calls, triangles, the graphics tier and the GPU memory
## the renderer holds (textures + buffers; added 14 Nov 2026 for the WebGL context loss work), refreshed
## twice a second in the top-left corner under the minimap label.
## On: the page address has ?perf=1 (web), F3 toggles it, or the Settings checkbox "Show FPS".
## Never saved. render_culling.gd attaches it when the town is built.
const GameSettings := preload("res://scripts/core/game_settings.gd")

const NODE_NAME := "Perf readout"
const REFRESH := 0.5
const DESIGN := Vector2(1100, 800)

var _label: Label
var _panel: PanelContainer
var _frames := 0
var _elapsed := 0.0
var _slowest := 0.0


## Adds the readout under `game` once; it starts shown when the page asks for it (?perf=1).
static func attach(game: Node) -> void:
	if game.get_node_or_null(NODE_NAME) != null:
		return
	var readout := new()
	readout.name = NODE_NAME
	game.add_child(readout)
	readout.set_shown(_asked_by_page())


## The readout of the running game, if any (the Settings checkbox).
static func find(tree: SceneTree) -> Node:
	var found := tree.root.find_child(NODE_NAME, true, false)
	return found


static func _asked_by_page() -> bool:
	if not OS.has_feature("web"):
		return false
	var value: Variant = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('perf') || ''", true)
	return str(value) in ["1", "true", "on", "yes"]


func _init() -> void:
	layer = 100
	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.06, 0.09, 0.72)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(8)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	_label = Label.new()
	_label.add_theme_color_override("font_color", Color("e8fff4"))
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_label)
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	get_viewport().size_changed.connect(_layout)
	_layout()


func set_shown(on: bool) -> void:
	visible = on
	set_process(on)
	_frames = 0
	_elapsed = 0.0
	_slowest = 0.0
	if on:
		_label.text = "…"


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_F3:
		set_shown(not visible)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_frames += 1
	_elapsed += delta
	_slowest = maxf(_slowest, delta)
	if _elapsed < REFRESH:
		return
	var draws := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var triangles := Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	var tier := str(GameSettings.shared().graphics).capitalize()
	var scale := get_viewport().scaling_3d_scale
	var gpu := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / 1048576.0
	_label.text = "%d fps  %.1f ms (max %.0f)\n%d draws  %.2f M tris\n%s  3D x%.2f\nGPU %d MB" % [
		roundi(_frames / _elapsed), _elapsed * 1000.0 / _frames, _slowest * 1000.0,
		draws, triangles / 1.0e6, tier, scale, roundi(gpu)]
	_frames = 0
	_elapsed = 0.0
	_slowest = 0.0


# Scales with the window like the other panels (money_panel.gd); sits below the minimap.
func _layout() -> void:
	var screen := get_viewport().get_visible_rect().size
	var f := clampf(minf(screen.y / DESIGN.y, screen.x / DESIGN.x), 0.6, 3.0)
	_label.add_theme_font_size_override("font_size", roundi(18 * f))
	_panel.position = Vector2(16 * f, 330 * f)
