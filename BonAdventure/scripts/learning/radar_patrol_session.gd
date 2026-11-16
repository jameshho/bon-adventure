extends Node
## Radar Patrol session (pastime, 9 Nov 2026; docs/guides/RADAR_PATROL.md). No NPC: a click or E on
## either radar in the airport control tower (scripts/objects/radar_console.gd, which calls
## open_game() through the group) opens the arcade screen (scripts/ui/radar_patrol_panel.gd).
## Registered on the activity board as "radar_patrol" (data/activities.json, kind "pastime",
## chance 0: never offered), so other games refuse while it runs and the test launcher can
## start it (launch(), used when a session has no NPC host).
const Board := preload("res://scripts/learning/activity_board.gd")
const ID := "radar_patrol"
const GROUP := "radar_patrol"

var panel
var hud
## No NPC host (the test launcher then calls launch()).
var host = null

func setup(radar_panel, world: Node, study_hud = null) -> void:
	panel = radar_panel
	hud = study_hud
	# The minimap, clock and help would show through the screen (as in mahjong_session.gd).
	panel.visibility_changed.connect(func() -> void:
		if hud != null:
			hud.hide_for_game(panel.visible))
	# The airport unit may be left out by dev_focus.txt: then there is no radar and no game.
	var tower := world.get_node_or_null("Airport/ControlTower/Interior")
	if tower == null or tower.get_node_or_null("Radar scope") == null and tower.get_node_or_null("Radar display") == null:
		return
	add_to_group(GROUP)
	Board.shared().register(ID, self)

## A radar was used: open the screen unless another game is in progress.
func open_game() -> bool:
	if panel == null or panel.visible or Board.shared().blocker(ID) != "":
		return false
	# On top of every HUD part added after it.
	panel.get_parent().move_child(panel, -1)
	panel.open_game()
	return true

## The test launcher's Play (no NPC to walk to: the screen opens where the player stands).
func launch() -> void:
	open_game()

func activity_running() -> bool:
	return panel != null and panel.visible

func busy() -> bool:
	return activity_running()
