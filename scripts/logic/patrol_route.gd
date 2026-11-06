class_name PatrolRoute
extends RefCounted
## A looping list of waypoints (XZ). Advances to the next point once within `arrive_distance`.

var points: PackedVector3Array
var index: int = 0


func _init(p_points: PackedVector3Array) -> void:
	assert(p_points.size() >= 2, "PatrolRoute: needs at least two points")
	points = p_points


func current() -> Vector3:
	return points[index]


## The waypoint to walk toward from `position`, advancing past any that have been reached.
func next_target(position: Vector3, arrive_distance: float) -> Vector3:
	var target: Vector3 = points[index]
	if Vector2(target.x - position.x, target.z - position.z).length() <= arrive_distance:
		index = (index + 1) % points.size()
	return points[index]
