class_name BossPhases
extends RefCounted
## Boss phase from remaining health: phase 1 above the first threshold, phase 2 down to the
## second, phase 3 below it.


static func phase_for(health_ratio: float, first: float = 0.66, second: float = 0.33) -> int:
	assert(first > second and second > 0.0 and first < 1.0, "BossPhases: thresholds must be ordered inside (0, 1)")
	if health_ratio > first:
		return 1
	if health_ratio > second:
		return 2
	return 3
