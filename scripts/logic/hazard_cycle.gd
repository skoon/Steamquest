class_name HazardCycle
extends RefCounted
## Repeating timed hazard: each `interval` seconds ends with an ACTIVE window of `active_time`,
## announced by a WARNING window of `warning_time` just before it. Pure and deterministic.

enum Phase { IDLE, WARNING, ACTIVE }

var interval: float
var warning_time: float
var active_time: float
## Shifts the cycle so several hazards built from the same numbers don't fire together.
var phase_offset: float


func _init(p_interval: float, p_warning_time: float, p_active_time: float, p_phase_offset: float = 0.0) -> void:
	assert(p_active_time > 0.0 and p_warning_time >= 0.0, "HazardCycle: times must be positive")
	assert(p_interval >= p_active_time + p_warning_time, "HazardCycle: interval must fit warning + active")
	interval = p_interval
	warning_time = p_warning_time
	active_time = p_active_time
	phase_offset = p_phase_offset


## Seconds into the current cycle at absolute time `time`.
func cycle_time(time: float) -> float:
	return fposmod(time + phase_offset, interval)


func phase_at(time: float) -> Phase:
	var t: float = cycle_time(time)
	var active_start: float = interval - active_time
	if t >= active_start:
		return Phase.ACTIVE
	if t >= active_start - warning_time:
		return Phase.WARNING
	return Phase.IDLE


## 0 at the start of the ACTIVE window, 1 at its end; 0 outside it.
func active_progress(time: float) -> float:
	var t: float = cycle_time(time) - (interval - active_time)
	return clampf(t / active_time, 0.0, 1.0) if t >= 0.0 else 0.0


## Counts completed cycles, so callers can tell one pass from the next.
func cycle_index(time: float) -> int:
	return int(floor((time + phase_offset) / interval))
