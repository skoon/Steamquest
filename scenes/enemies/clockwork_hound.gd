class_name ClockworkHound
extends EnemyBase
## Fast pack hunter. Runs in, then circles the Technician with the rest of its pack, each hound
## holding its own slot around the ring, and lunges when it is beside or behind the Technician's aim.

enum Phase { CHASE, CIRCLE, WINDUP, LUNGE }

const PACK_GROUP: StringName = &"hounds"
## Starts circling inside this distance; gives up circling and runs back in beyond LEAVE_RANGE.
const ENGAGE_RANGE: float = 7.0
const LEAVE_RANGE: float = 10.0
const ORBIT_RADIUS: float = 4.0
## Radians per second the whole ring turns, so the pack keeps moving.
const ORBIT_SPEED: float = 0.6
## A hound lunges from this far away at most.
const LUNGE_RANGE: float = 5.0
const LUNGE_DURATION: float = 0.3
## Beside or behind: at least this many degrees off the Technician's aim.
const FLANK_DEGREES: float = 70.0
## A hound that hasn't found an opening by now lunges anyway.
const MAX_CIRCLE_TIME: float = 2.4

var phase: Phase = Phase.CHASE
var _phase_time: float = 0.0
var _circle_time: float = 0.0
var _lunge_direction: Vector3 = Vector3.ZERO
var _bit_this_lunge: bool = false
var _seek_timer: float = 0.0


func _on_ready() -> void:
	add_to_group(PACK_GROUP)


func _shadow_radius() -> float:
	return 0.6


## Where this hound wants to stand on the ring right now.
func orbit_target() -> Vector3:
	var pack: PackedInt64Array = PackedInt64Array()
	for node: Node in get_tree().get_nodes_in_group(PACK_GROUP):
		var hound: ClockworkHound = node as ClockworkHound
		if hound != null and not hound.is_dead and hound.is_aggro:
			pack.append(hound.get_instance_id())
	if not pack.has(get_instance_id()):
		pack.append(get_instance_id())
	var slot: int = PackTactics.slot_of(get_instance_id(), pack)
	var ring_turn: float = float(Time.get_ticks_msec()) * 0.001 * ORBIT_SPEED
	return PackTactics.orbit_point(target.global_position, PackTactics.slot_angle(slot, pack.size(), ring_turn), ORBIT_RADIUS)


func _update_behavior(delta: float) -> Vector3:
	_phase_time -= delta
	match phase:
		Phase.CHASE:
			if _distance_to_target() <= ENGAGE_RANGE:
				phase = Phase.CIRCLE
				_circle_time = 0.0
			return _chase_velocity(stats.move_speed, delta)
		Phase.CIRCLE:
			_circle_time += delta
			var distance: float = _distance_to_target()
			if distance > LEAVE_RANGE:
				phase = Phase.CHASE
				return _chase_velocity(stats.move_speed, delta)
			if _attack_cooldown <= 0.0 and distance <= LUNGE_RANGE and _has_opening():
				phase = Phase.WINDUP
				_phase_time = stats.telegraph_time
				return Vector3.ZERO
			return _seek_velocity(orbit_target(), stats.move_speed * 0.85, delta)
		Phase.WINDUP:
			if _phase_time <= 0.0:
				phase = Phase.LUNGE
				_phase_time = LUNGE_DURATION
				_lunge_direction = _direction_to_target()
				_bit_this_lunge = false
				sprite.play_attack()
				Audio.play_at(&"hound_lunge", global_position)
			return Vector3.ZERO
		Phase.LUNGE:
			if not _bit_this_lunge and _distance_to_target() <= stats.attack_range:
				_bit_this_lunge = true
				_hit_target(stats.attack_damage, stats.attack_knockback)
			if _phase_time <= 0.0:
				phase = Phase.CIRCLE
				_circle_time = 0.0
				_attack_cooldown = stats.attack_cooldown
			return _lunge_direction * stats.projectile_speed
	return Vector3.ZERO


func _has_opening() -> bool:
	if _circle_time >= MAX_CIRCLE_TIME:
		return true
	return PackTactics.is_flanking(target.global_position, target.aim_direction, global_position, FLANK_DEGREES)


## Velocity along the navigation path toward an arbitrary point.
func _seek_velocity(point: Vector3, speed: float, delta: float) -> Vector3:
	_seek_timer -= delta
	if _seek_timer <= 0.0:
		_seek_timer = REPATH_INTERVAL
		nav_agent.target_position = point
	var next: Vector3 = nav_agent.get_next_path_position()
	var to_next: Vector3 = Vector3(next.x - global_position.x, 0.0, next.z - global_position.z)
	if to_next.length_squared() < 0.04:
		to_next = Vector3(point.x - global_position.x, 0.0, point.z - global_position.z)
	if to_next.length_squared() < 0.04:
		return Vector3.ZERO
	return to_next.normalized() * speed
