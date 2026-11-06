class_name HoldProgress
extends RefCounted
## "Hold the point" progress: fills over `duration` seconds while the holder is in range,
## pauses (never drains) while they are away, and completes at 1.

var duration: float
var progress: float = 0.0


func _init(p_duration: float) -> void:
	assert(p_duration > 0.0, "HoldProgress: duration must be positive")
	duration = p_duration


## Advances and returns the new progress (0..1).
func tick(delta: float, in_range: bool) -> float:
	assert(delta >= 0.0, "HoldProgress.tick: delta must be non-negative")
	if in_range:
		progress = minf(progress + delta / duration, 1.0)
	return progress


func is_complete() -> bool:
	return progress >= 1.0
