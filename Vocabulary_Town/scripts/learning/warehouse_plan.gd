extends RefCounted
## The task planner's view of a Warehouse Worker arrangement (user, 8 Nov 2026: all of a game's
## tasks are written and checked before the game starts; guide: docs/guides/WAREHOUSE.md#task-plan-8-nov-2026).
## warehouse_tasks.gd writes its tasks against this object instead of the live goods
## (warehouse_goods.gd): it answers the same questions (on_table, rack_spot, beside, ...) from
## the real starting arrangement, then `apply(task)` moves things where each planned task will
## leave them, so the next task is written for the warehouse as it will be by then.
##
## Since 14 Nov 2026 every task is a placing task (on the table, beside / to the right of the
## reference box, on the top shelf), so where a thing ends up is always known. Nothing here
## moves a body; the live goods are only read.
const Warehouse := preload("res://scripts/world/warehouse.gd")
var real
var items: Dictionary
var carried: RigidBody3D = null
## Things a planned task moved: id -> where it ends up ({"table": true, "rack": [0, level],
## "beside": [ref, side], "floor": true}).
var moved := {}

func _init(goods) -> void:
	real = goods
	items = goods.items

# --- Where things will be --------------------------------------------------------------------

func known(id: String) -> bool:
	return not moved.has(id) or moved[id] != null

func _at(id: String) -> Dictionary:
	var record: Variant = moved.get(id)
	return record if record is Dictionary else {}

func on_table(id: String) -> bool:
	return bool(_at(id).get("table", false)) if moved.has(id) else real.on_table(id)

func rack_spot(id: String) -> Array:
	return _at(id).get("rack", []) if moved.has(id) else real.rack_spot(id)

func on_level(level: int) -> int:
	return items.keys().filter(func(id): return rack_spot(id) == [0, level]).size()

func on_floor(id: String) -> bool:
	return bool(_at(id).get("floor", false)) if moved.has(id) else real.on_floor(id)

func beside(id: String, ref: String, side: String) -> bool:
	if not moved.has(id):
		return real.beside(id, ref, side)
	var record: Array = _at(id).get("beside", [])
	return not record.is_empty() and record[0] == ref and (side == "next_to" or record[1] == side)

func bay_of(ref: String) -> int:
	return -1 if moved.has(ref) else real.bay_of(ref)

func resting(_id: String) -> bool:
	return true

# Sizes and rules do not change with the plan.
func half(id: String) -> Vector3:
	return real.half(id)

func fits_shelf(id: String) -> bool:
	return real.fits_shelf(id)

# --- A planned task's outcome ------------------------------------------------------------------

## Moves the task's thing where the task leaves it.
func apply(task: Dictionary) -> void:
	if str(task.get("kind", "")) == "place":
		moved[task.item] = _placed(task.goal)

## Where a placing goal leaves a thing.
func _placed(goal: Dictionary) -> Variant:
	match str(goal.pos):
		"on":
			return {"table": true}
		"next_to", "right":
			# Beside the reference: "to the right" is also "next to" it.
			return {"beside": [str(goal.ref), str(goal.pos)], "floor": true}
		"top_shelf":
			return {"rack": [0, Warehouse.RACK_LEVELS.size() - 1]}
	return null
