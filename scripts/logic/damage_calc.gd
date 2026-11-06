class_name DamageCalc
extends RefCounted
## Pure damage and knockback math shared by the player and automatons.

const GOLDEN_DAMAGE_BONUS: float = 1.25
const OVERCLOCK_DAMAGE_BONUS: float = 1.1
## Armor can never reduce a hit below this fraction of its raw value.
const MIN_DAMAGE_RATIO: float = 0.2


static func outgoing_damage(base: float, golden_active: bool, overclocked: bool) -> float:
	assert(base >= 0.0, "DamageCalc.outgoing_damage: base must be non-negative")
	var multiplier: float = 1.0
	if golden_active:
		multiplier *= GOLDEN_DAMAGE_BONUS
	if overclocked:
		multiplier *= OVERCLOCK_DAMAGE_BONUS
	return base * multiplier


static func mitigated_damage(incoming: float, armor: float) -> float:
	assert(incoming >= 0.0 and armor >= 0.0, "DamageCalc.mitigated_damage: negative input")
	return maxf(incoming - armor, incoming * MIN_DAMAGE_RATIO)


static func apply_to_health(health: float, damage: float) -> float:
	assert(damage >= 0.0, "DamageCalc.apply_to_health: damage must be non-negative")
	return maxf(health - damage, 0.0)


## Horizontal knockback pushing `to` away from `from`, scaled by `force * (1 - resistance)`.
static func knockback(from: Vector3, to: Vector3, force: float, resistance: float) -> Vector3:
	var flat: Vector3 = Vector3(to.x - from.x, 0.0, to.z - from.z)
	if flat.length_squared() < 0.000001:
		return Vector3.ZERO
	return flat.normalized() * force * (1.0 - clampf(resistance, 0.0, 1.0))


## True when `target` lies within a horizontal cone of `arc_degrees` around `facing` from `origin`.
static func is_in_arc(origin: Vector3, facing: Vector3, target: Vector3, arc_degrees: float) -> bool:
	var to_target: Vector3 = Vector3(target.x - origin.x, 0.0, target.z - origin.z)
	var flat_facing: Vector3 = Vector3(facing.x, 0.0, facing.z)
	if to_target.length_squared() < 0.000001:
		return true
	if flat_facing.length_squared() < 0.000001:
		return false
	var cos_half: float = cos(deg_to_rad(arc_degrees * 0.5))
	return to_target.normalized().dot(flat_facing.normalized()) >= cos_half - 0.000001


## True when a hit arriving from `attacker_direction` (pointing from the defender toward the
## attacker) lands inside the defender's frontal shield arc of `arc_degrees` around `facing`.
static func is_blocked_by_shield(facing: Vector3, attacker_direction: Vector3, arc_degrees: float) -> bool:
	var flat_facing: Vector3 = Vector3(facing.x, 0.0, facing.z)
	var flat_incoming: Vector3 = Vector3(attacker_direction.x, 0.0, attacker_direction.z)
	if flat_facing.length_squared() < 0.000001 or flat_incoming.length_squared() < 0.000001:
		return false
	var cos_half: float = cos(deg_to_rad(arc_degrees * 0.5))
	return flat_incoming.normalized().dot(flat_facing.normalized()) >= cos_half - 0.000001
