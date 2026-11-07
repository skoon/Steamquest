class_name TeslaDrone
extends EnemyBase
## Hovering coil drone. Flies straight at a stand-off distance (no floor pathing), circles the
## Technician and fires a telegraphed arc bolt from a distance, so the rivet gun is the answer.
## It dips low for a moment after each shot, and drops to the floor when stunned by an overloaded
## coil. Its collision column stays fixed (tall enough for rivets to hit); only the sprite bobs.

enum Phase { ORBIT, CHARGE, SWOOP, STUNNED }

const HOVER_HEIGHT: float = 2.1
const LOW_HEIGHT: float = 0.9
const STUN_HEIGHT: float = 0.45
const SWOOP_TIME: float = 1.2
const HEIGHT_SPEED: float = 4.0

@export var bolt_scene: PackedScene
@export var preferred_distance: float = 7.0
@export var orbit_speed: float = 0.8

@onready var coil_light: OmniLight3D = $CoilLight

var phase: Phase = Phase.ORBIT
var hover: float = HOVER_HEIGHT
var _phase_time: float = 0.0
var _orbit_sign: float = 1.0
var _hum_timer: float = 0.0


func _shadow_radius() -> float:
	return 0.5


func _on_ready() -> void:
	assert(bolt_scene != null, "TeslaDrone: bolt_scene missing")
	_orbit_sign = 1.0 if get_instance_id() % 2 == 0 else -1.0
	_apply_height()


func is_stunned() -> bool:
	return phase == Phase.STUNNED


## Knocked out of the air (an overloaded coil): grounded and harmless for `seconds`.
func stun(seconds: float) -> void:
	if is_dead:
		return
	is_aggro = true
	phase = Phase.STUNNED
	_phase_time = seconds
	sprite.modulate = Color(0.55, 0.8, 1.0)
	coil_light.light_energy = 0.0
	Fx.arc_sparks(get_parent(), global_position + Vector3.UP * hover)


func _physics_process(delta: float) -> void:
	if phase == Phase.STUNNED and not is_dead:
		_phase_time -= delta
		if _phase_time <= 0.0:
			phase = Phase.ORBIT
			sprite.modulate = Color.WHITE
			coil_light.light_energy = 0.6
	var goal: float = HOVER_HEIGHT
	match phase:
		Phase.SWOOP:
			goal = LOW_HEIGHT
		Phase.STUNNED:
			goal = STUN_HEIGHT
	hover = move_toward(hover, goal, HEIGHT_SPEED * delta)
	_apply_height()
	_hum_timer -= delta
	if is_aggro and not is_dead and phase != Phase.STUNNED and _hum_timer <= 0.0:
		_hum_timer = 1.6
		Audio.play_at(&"drone_hum", global_position + Vector3.UP * hover, -6.0)
	super(delta)


func _apply_height() -> void:
	sprite.position.y = hover
	coil_light.position.y = hover + 0.3


func _update_behavior(delta: float) -> Vector3:
	if phase == Phase.STUNNED:
		return Vector3.ZERO
	_phase_time -= delta
	match phase:
		Phase.CHARGE:
			var progress: float = 1.0 - clampf(_phase_time / stats.telegraph_time, 0.0, 1.0)
			coil_light.light_energy = lerpf(0.6, 4.0, progress)
			sprite.modulate = Color.WHITE.lerp(Color(0.6, 0.95, 1.0), progress)
			if _phase_time <= 0.0:
				_fire()
			return Vector3.ZERO
		Phase.SWOOP:
			if _phase_time <= 0.0:
				phase = Phase.ORBIT
			return _orbit_velocity() * 0.5
	if _attack_cooldown <= 0.0 and _distance_to_target() <= stats.attack_range and _can_see_target(stats.attack_range):
		phase = Phase.CHARGE
		_phase_time = stats.telegraph_time
		(sprite as CharacterSprite).play_attack()
		Audio.play_at(&"turret_charge", global_position + Vector3.UP * hover)
		return Vector3.ZERO
	return _orbit_velocity()


## Moves toward the preferred ring around the Technician while circling it.
func _orbit_velocity() -> Vector3:
	var away: Vector3 = global_position - target.global_position
	away.y = 0.0
	var distance: float = away.length()
	var radial: Vector3 = away / distance if distance > 0.01 else Vector3.RIGHT
	var tangent: Vector3 = Vector3(-radial.z, 0.0, radial.x) * _orbit_sign
	var correction: float = clampf((preferred_distance - distance) * 0.8, -1.0, 1.0)
	return (radial * correction + tangent * orbit_speed).normalized() * stats.move_speed


func _fire() -> void:
	phase = Phase.SWOOP
	_phase_time = SWOOP_TIME
	_attack_cooldown = stats.attack_cooldown
	coil_light.light_energy = 0.6
	sprite.modulate = Color.WHITE
	var muzzle: Vector3 = global_position + Vector3.UP * hover
	var aim: Vector3 = target.global_position + Vector3.UP * 0.9 - muzzle
	var bolt: Projectile = bolt_scene.instantiate() as Projectile
	assert(bolt != null, "TeslaDrone: bolt_scene root must use projectile.gd")
	get_parent().add_child(bolt)
	bolt.launch(muzzle, aim, stats.projectile_speed, stats.attack_damage, stats.attack_knockback, 2.0)
	Fx.arc_sparks(get_parent(), muzzle)
	Audio.play_at(&"drone_zap", muzzle)


## Hovering ignores gravity; the body stays at floor level and only its shape and sprite rise.
func _apply_movement(delta: float, desired: Vector3) -> void:
	_knockback = _knockback.move_toward(Vector3.ZERO, KNOCKBACK_DECAY * delta)
	velocity = Vector3(desired.x + _knockback.x + push_velocity.x, 0.0, desired.z + _knockback.z + push_velocity.z)
	push_velocity = Vector3.ZERO
	move_and_slide()
	var character: CharacterSprite = sprite as CharacterSprite
	if character != null:
		character.play_locomotion(_screen_velocity(desired))


func _on_death() -> void:
	coil_light.light_energy = 0.0
	hover = STUN_HEIGHT
	_apply_height()
