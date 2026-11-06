class_name ScrapSkitterer
extends EnemyBase
## Fast clockwork spider: rushes the Technician, lunges when close and bites.

enum Phase { CHASE, WINDUP, LUNGE }

const LUNGE_TRIGGER_RANGE: float = 3.2
const LUNGE_DURATION: float = 0.28

var _phase: Phase = Phase.CHASE
var _phase_time: float = 0.0
var _lunge_direction: Vector3 = Vector3.ZERO
var _bit_this_lunge: bool = false


func _shadow_radius() -> float:
	return 0.55


func _update_behavior(delta: float) -> Vector3:
	_phase_time -= delta
	match _phase:
		Phase.CHASE:
			if _distance_to_target() <= LUNGE_TRIGGER_RANGE and _attack_cooldown <= 0.0:
				_phase = Phase.WINDUP
				_phase_time = stats.telegraph_time
				return Vector3.ZERO
			return _chase_velocity(stats.move_speed, delta)
		Phase.WINDUP:
			if _phase_time <= 0.0:
				_phase = Phase.LUNGE
				_phase_time = LUNGE_DURATION
				_lunge_direction = _direction_to_target()
				_bit_this_lunge = false
				(sprite as CharacterSprite).play_attack()
			return Vector3.ZERO
		Phase.LUNGE:
			if not _bit_this_lunge and _distance_to_target() <= stats.attack_range:
				_bit_this_lunge = true
				_hit_target(stats.attack_damage, stats.attack_knockback)
			if _phase_time <= 0.0:
				_phase = Phase.CHASE
				_attack_cooldown = stats.attack_cooldown
			return _lunge_direction * stats.projectile_speed
	return Vector3.ZERO
