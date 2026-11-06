class_name GustCycle
extends RefCounted
## Periodic wind: a warning, then a gust that pushes along `direction` at `strength`, easing in and
## out across the gust so it never snaps.

var cycle: HazardCycle
var direction: Vector3
var strength: float


func _init(interval: float, warning_time: float, gust_time: float, p_direction: Vector3, p_strength: float, phase_offset: float = 0.0) -> void:
	var flat: Vector3 = Vector3(p_direction.x, 0.0, p_direction.z)
	assert(flat.length_squared() > 0.0, "GustCycle: direction must be horizontal and non-zero")
	assert(p_strength >= 0.0, "GustCycle: strength must be non-negative")
	cycle = HazardCycle.new(interval, warning_time, gust_time, phase_offset)
	direction = flat.normalized()
	strength = p_strength


func phase_at(time: float) -> HazardCycle.Phase:
	return cycle.phase_at(time)


## Push velocity at `time`: zero outside the gust, peaking mid-gust.
func force_at(time: float) -> Vector3:
	if cycle.phase_at(time) != HazardCycle.Phase.ACTIVE:
		return Vector3.ZERO
	return direction * strength * sin(cycle.active_progress(time) * PI)
