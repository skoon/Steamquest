class_name PackTactics
extends RefCounted
## Pure geometry for automatons that hunt in packs: spreading around a target and picking the
## moment it is looking the other way.


## Evenly spaced orbit angle for member `slot` of a pack of `count`, turned by `turn`.
static func slot_angle(slot: int, count: int, turn: float) -> float:
	assert(count > 0 and slot >= 0 and slot < count, "PackTactics.slot_angle: slot %d of %d" % [slot, count])
	return turn + TAU * float(slot) / float(count)


static func orbit_point(center: Vector3, angle: float, radius: float) -> Vector3:
	return Vector3(center.x + cos(angle) * radius, center.y, center.z + sin(angle) * radius)


## This member's slot: its position among the pack's ids in ascending order.
static func slot_of(member_id: int, pack_ids: PackedInt64Array) -> int:
	var sorted_ids: PackedInt64Array = pack_ids.duplicate()
	sorted_ids.sort()
	var slot: int = sorted_ids.find(member_id)
	assert(slot >= 0, "PackTactics.slot_of: %d is not in the pack" % member_id)
	return slot


## True when the attacker stands at least `min_degrees` away from where the target is facing,
## i.e. beside or behind it.
static func is_flanking(target_position: Vector3, target_facing: Vector3, attacker_position: Vector3, min_degrees: float) -> bool:
	var to_attacker: Vector3 = Vector3(attacker_position.x - target_position.x, 0.0, attacker_position.z - target_position.z)
	var facing: Vector3 = Vector3(target_facing.x, 0.0, target_facing.z)
	if to_attacker.length_squared() < 0.000001 or facing.length_squared() < 0.000001:
		return true
	return to_attacker.normalized().dot(facing.normalized()) <= cos(deg_to_rad(min_degrees)) + 0.000001
