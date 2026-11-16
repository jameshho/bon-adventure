extends RefCounted
## One-time clean-up of a unit's baked interaction metas (12 Nov 2026, interaction system:
## docs/guides/ARCHITECTURE_REVIEW_PART1.md#interaction-system). The old hover hints and click flags
## (action_hint, click_use, click_play, click_hint, label_phrase) were saved on nodes by earlier
## steps; Interactable components (added by the objects' own scripts at load) replaced them.
## Used by each affected unit's `interaction_metas` step (scripts/buildings/<unit>.gd):
##   preload("res://scripts/buildings/interaction_metas.gd").strip(town, "<unit>")
const ModularTown := preload("res://scripts/world/modular_town.gd")
const OLD := ["action_hint", "click_use", "click_play", "click_hint", "label_phrase"]

static func strip(town: Node3D, unit: String) -> void:
	var parts: Array = ModularTown.registry()[unit].parts
	var removed := 0
	for i in parts.size():
		var root := ModularTown.building(town, unit, i)
		if root == null:
			continue
		for node in [root] + root.find_children("*", "", true, false):
			for key in OLD:
				if node.has_meta(key):
					node.remove_meta(key)
					removed += 1
	print("interaction_metas: %s: removed %d metas" % [unit, removed])
