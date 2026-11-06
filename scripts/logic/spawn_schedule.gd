class_name SpawnSchedule
extends RefCounted
## When a spawner may produce another automaton: every `interval` seconds, while fewer than
## `max_alive` of its spawns are still alive.

var interval: float
var max_alive: int


func _init(p_interval: float, p_max_alive: int) -> void:
	assert(p_interval > 0.0, "SpawnSchedule: interval must be positive")
	assert(p_max_alive > 0, "SpawnSchedule: max_alive must be positive")
	interval = p_interval
	max_alive = p_max_alive


func should_spawn(time_since_last: float, alive: int) -> bool:
	return time_since_last >= interval and alive < max_alive
