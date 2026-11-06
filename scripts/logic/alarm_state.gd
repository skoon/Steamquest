class_name AlarmState
extends RefCounted
## A room alarm: raised the moment anyone is spotted, cleared once nobody has been seen for
## `quiet_time` seconds.

var quiet_time: float
var _raised: bool = false
var _last_seen: float = -INF


func _init(p_quiet_time: float) -> void:
	assert(p_quiet_time > 0.0, "AlarmState: quiet_time must be positive")
	quiet_time = p_quiet_time


## Advances to absolute `time`; `seen` says whether the intruder is visible right now.
## Returns true when the raised state changed this tick.
func tick(time: float, seen: bool) -> bool:
	var was: bool = _raised
	if seen:
		_last_seen = time
		_raised = true
	elif _raised and time - _last_seen >= quiet_time:
		_raised = false
	return was != _raised


func is_raised() -> bool:
	return _raised
