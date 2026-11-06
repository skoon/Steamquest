class_name TideCycle
extends RefCounted
## Smoothly rising and falling water. level_at() eases between 0 (dry) and 1 (full) once per
## `period`, and a forced flood holds it at 1 until a given time. Pure and deterministic.

var period: float
## Shifts the cycle so neighbouring pools don't rise in lockstep.
var phase_offset: float
var _flood_until: float = -INF


func _init(p_period: float, p_phase_offset: float = 0.0) -> void:
	assert(p_period > 0.0, "TideCycle: period must be positive")
	period = p_period
	phase_offset = p_phase_offset


## 0 at low water (start of each period), 1 at high water (half way), back to 0.
func natural_level_at(time: float) -> float:
	var t: float = fposmod(time + phase_offset, period) / period
	return 0.5 - 0.5 * cos(t * TAU)


func level_at(time: float) -> float:
	return 1.0 if is_forced(time) else natural_level_at(time)


func is_deep(time: float, threshold: float) -> bool:
	return level_at(time) >= threshold


## Holds the water at full until `until` (absolute time).
func force_flood(until: float) -> void:
	_flood_until = maxf(_flood_until, until)


func is_forced(time: float) -> bool:
	return time < _flood_until
