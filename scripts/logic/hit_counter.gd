class_name HitCounter
extends RefCounted
## Counts blows toward a goal (a drive governor, the Walker's boiler valve). Hits past the goal
## are ignored until `reset`.

var required: int
var hits: int = 0


func _init(p_required: int) -> void:
	assert(p_required > 0, "HitCounter: required must be positive")
	required = p_required


## Registers one blow; returns true on the blow that reaches the goal.
func register() -> bool:
	if is_complete():
		return false
	hits += 1
	return is_complete()


func is_complete() -> bool:
	return hits >= required


func reset() -> void:
	hits = 0
