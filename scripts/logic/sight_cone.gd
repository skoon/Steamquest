class_name SightCone
extends RefCounted
## Flat (XZ) vision cone geometry for lantern-carrying patrols. Line of sight is the caller's job.


static func can_see(origin: Vector3, facing: Vector3, target: Vector3, sight_range: float, half_angle_degrees: float) -> bool:
	var to_target: Vector3 = Vector3(target.x - origin.x, 0.0, target.z - origin.z)
	var flat_facing: Vector3 = Vector3(facing.x, 0.0, facing.z)
	if flat_facing.length_squared() < 0.000001:
		return false
	var distance: float = to_target.length()
	if distance > sight_range:
		return false
	if distance < 0.0001:
		return true
	return to_target.normalized().dot(flat_facing.normalized()) >= cos(deg_to_rad(half_angle_degrees)) - 0.000001
