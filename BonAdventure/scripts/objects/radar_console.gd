extends Node3D
## A control-tower radar that starts Radar Patrol (pastime, 9 Nov 2026, user; docs/guides/RADAR_PATROL.md).
## Set by the airport step `radar_patrol_screens` on both radar word roots ("Radar scope" in the
## hidden radar room, "Radar display" in the control room). A pastime station interactable
## (scripts/core/interactable.gd, 12 Nov 2026): a subtle dot within 15 m; E, a click or a tap
## calls use(); the session (radar_patrol_session.gd, group "radar_patrol") opens the arcade screen.
const Interactable := preload("res://scripts/core/interactable.gd")
const InteractIcons := preload("res://scripts/ui/interact_badge.gd")

func _ready() -> void:
	Interactable.attach(self, {
		"kind": Interactable.Kind.PLAY,
		"indicator": Interactable.Indicator.STATION,
		"prompt_distance": 2.6,
		"priority": 0.5,
		"badge_offset": InteractIcons.local_center(self) + Vector3(0, 0.35, 0),
	})

func use() -> bool:
	for session in get_tree().get_nodes_in_group("radar_patrol"):
		if session.has_method("open_game"):
			return session.open_game()
	return false
