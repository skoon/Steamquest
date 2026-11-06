class_name SequenceLock
extends RefCounted
## A combination lock driven by pressing ids in order. A wrong id resets it; once solved it stays solved.

enum Result { PROGRESS, WRONG, SOLVED, ALREADY_SOLVED }

var order: Array[StringName]
var _next: int = 0
var _solved: bool = false


func _init(p_order: Array[StringName]) -> void:
	assert(not p_order.is_empty(), "SequenceLock: order must not be empty")
	order = p_order.duplicate()


func press(id: StringName) -> Result:
	if _solved:
		return Result.ALREADY_SOLVED
	if order[_next] != id:
		_next = 0
		return Result.WRONG
	_next += 1
	if _next == order.size():
		_solved = true
		return Result.SOLVED
	return Result.PROGRESS


func reset() -> void:
	_next = 0


## How many ids in a row have been pressed correctly.
func progress() -> int:
	return order.size() if _solved else _next


func is_solved() -> bool:
	return _solved
