class_name ArcTurret
extends EnemyBase
## Stationary brass coil. Charges (glow ramps up) and fires timed lightning bolts at the Technician
## whenever it has line of sight.

@export var bolt_scene: PackedScene

@onready var coil_light: OmniLight3D = $CoilLight
@onready var muzzle: Marker3D = $Muzzle

var _charge_time_left: float = -1.0
## Shorted out (e.g. standing in deep water): no charging or firing.
var disabled: bool = false
## Asleep until an alarm wakes it.
@export var dormant: bool = false


func _shadow_radius() -> float:
	return 0.8


func _on_ready() -> void:
	assert(bolt_scene != null, "ArcTurret: bolt_scene missing")
	coil_light.light_energy = 0.4
	if dormant:
		_apply_sleep_look()


func set_dormant(value: bool) -> void:
	if dormant == value:
		return
	dormant = value
	_charge_time_left = -1.0
	if dormant:
		_apply_sleep_look()
	elif not disabled:
		coil_light.light_energy = 0.4
		sprite.modulate = Color.WHITE
		Fx.arc_sparks(get_parent(), muzzle.global_position)
		Audio.play_at(&"turret_charge", muzzle.global_position)


func _apply_sleep_look() -> void:
	coil_light.light_energy = 0.0
	sprite.modulate = Color(0.45, 0.5, 0.6)


func set_disabled(value: bool) -> void:
	if disabled == value:
		return
	disabled = value
	_charge_time_left = -1.0
	coil_light.light_energy = 0.0 if disabled else 0.4
	sprite.modulate = Color(0.45, 0.5, 0.6) if disabled else Color.WHITE
	if disabled and not is_dead:
		Fx.arc_sparks(get_parent(), muzzle.global_position)


func _update_behavior(delta: float) -> Vector3:
	if disabled or dormant:
		return Vector3.ZERO
	var visible_target: bool = _can_see_target(stats.attack_range)
	if _charge_time_left >= 0.0:
		_charge_time_left -= delta
		var progress: float = 1.0 - clampf(_charge_time_left / stats.telegraph_time, 0.0, 1.0)
		coil_light.light_energy = lerpf(0.4, 4.0, progress)
		sprite.modulate = Color(1.0, 1.0, 1.0).lerp(Color(0.6, 0.95, 1.0), progress)
		if _charge_time_left < 0.0:
			_discharge(visible_target)
	elif visible_target and _attack_cooldown <= 0.0:
		_charge_time_left = stats.telegraph_time
		Audio.play_at(&"turret_charge", muzzle.global_position)
	return Vector3.ZERO


func _discharge(visible_target: bool) -> void:
	coil_light.light_energy = 0.4
	sprite.modulate = Color.WHITE
	_attack_cooldown = stats.attack_cooldown
	if not visible_target:
		return
	var bolt: Projectile = bolt_scene.instantiate() as Projectile
	assert(bolt != null, "ArcTurret: bolt_scene root must use projectile.gd")
	get_parent().add_child(bolt)
	var aim_point: Vector3 = target.global_position + Vector3.UP * 0.9
	var direction: Vector3 = aim_point - muzzle.global_position
	direction.y = 0.0
	bolt.launch(muzzle.global_position, direction, stats.projectile_speed, stats.attack_damage, stats.attack_knockback, 2.5)
	Fx.arc_sparks(get_parent(), muzzle.global_position)
	Audio.play_at(&"turret_zap", muzzle.global_position)


func _on_death() -> void:
	coil_light.light_energy = 0.0
