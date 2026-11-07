class_name RoomPressure
extends RefCounted
## A level-wide steam pressure (0..1) that keeps climbing. Relief valves bleed it off; above
## `warning_ratio` the marked pipe routes start to steam, and reaching 1.0 bursts them, after
## which the pressure falls back to `after_burst`.

var rise_per_second: float
var warning_ratio: float
var after_burst: float
var level: float = 0.0


func _init(p_rise_per_second: float, p_warning_ratio: float = 0.75, p_after_burst: float = 0.4, p_start: float = 0.0) -> void:
	assert(p_rise_per_second > 0.0, "RoomPressure: rise must be positive")
	assert(p_warning_ratio > 0.0 and p_warning_ratio < 1.0, "RoomPressure: warning ratio must be inside (0, 1)")
	assert(p_after_burst >= 0.0 and p_after_burst < 1.0, "RoomPressure: after_burst must be inside [0, 1)")
	rise_per_second = p_rise_per_second
	warning_ratio = p_warning_ratio
	after_burst = p_after_burst
	level = clampf(p_start, 0.0, 1.0)


## Advances the climb; returns true when this tick burst the pipes.
func tick(delta: float) -> bool:
	assert(delta >= 0.0, "RoomPressure.tick: delta must be non-negative")
	level = minf(level + rise_per_second * delta, 1.0)
	if level >= 1.0:
		level = after_burst
		return true
	return false


## Vents `amount` of pressure (never below zero); returns how much was actually bled.
func bleed(amount: float) -> float:
	assert(amount >= 0.0, "RoomPressure.bleed: amount must be non-negative")
	var before: float = level
	level = maxf(level - amount, 0.0)
	return before - level


func is_warning() -> bool:
	return level >= warning_ratio
