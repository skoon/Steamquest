class_name EnemyBase
extends CharacterBody3D
## Shared automaton behaviour: aggro with line of sight, NavigationAgent3D chasing, damage,
## knockback, hit flash, death and scrap-gear drops. Subclasses implement `_update_behavior`.

signal died(enemy: EnemyBase)

const GRAVITY: float = 20.0
const KNOCKBACK_DECAY: float = 25.0
const REPATH_INTERVAL: float = 0.25
const DEATH_LINGER: float = 0.7

@export var stats: EnemyStats
@export var gear_pickup_scene: PackedScene
@export_group("Sound")
## Played together on the walk-cycle frames listed in step_frames.
@export var step_sounds: Array[StringName] = []
@export var step_frames: PackedInt32Array = PackedInt32Array([0, 2])
@export var step_volume_db: float = 0.0
## Minimum seconds between footsteps, so packs of automatons don't turn into noise.
@export var step_min_interval: float = 0.12

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var sprite: CharacterModel = $Model

var health: float = 0.0
var is_dead: bool = false
var is_aggro: bool = false
var target: Technician
var _knockback: Vector3 = Vector3.ZERO
var _repath_timer: float = 0.0
var _attack_cooldown: float = 0.0
var _last_step_msec: int = 0
## Movement scale set by terrain such as deep water (1 = normal).
var terrain_speed: float = 1.0
## External shove for this frame only (wind, propellers); consumed by _apply_movement.
var push_velocity: Vector3 = Vector3.ZERO
var _fell: bool = false


func _ready() -> void:
	assert(stats != null, "%s: stats resource missing" % name)
	add_to_group(&"enemies")
	health = stats.max_health
	nav_agent.max_speed = stats.move_speed
	add_child(Fx.make_blob_shadow(_shadow_radius()))
	if not step_sounds.is_empty():
		sprite.frame_changed.connect(_on_sprite_frame_changed)
	_on_ready()


func _on_sprite_frame_changed() -> void:
	if is_dead or sprite.animation != &"walk":
		return
	if not step_frames.has(sprite.frame):
		return
	var now: int = Time.get_ticks_msec()
	if float(now - _last_step_msec) < step_min_interval * 1000.0:
		return
	_last_step_msec = now
	for sound: StringName in step_sounds:
		Audio.play_at(sound, global_position, step_volume_db, 0.12)


## Hook for subclasses; called at the end of _ready.
func _on_ready() -> void:
	return


func _shadow_radius() -> float:
	return 0.6


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	if target == null or not is_instance_valid(target):
		target = get_tree().get_first_node_in_group(&"player") as Technician
	if target != null and not is_aggro:
		is_aggro = _detect_target()
	var desired: Vector3 = Vector3.ZERO
	if is_aggro and target != null and not target.is_dead:
		desired = _update_behavior(delta)
	else:
		desired = _idle_behavior(delta)
	_apply_movement(delta, desired)


## How this automaton notices the Technician; patrols override it with a sight cone.
func _detect_target() -> bool:
	return _can_see_target(stats.aggro_range)


## Desired velocity while not hunting (patrols walk their routes).
func _idle_behavior(_delta: float) -> Vector3:
	return Vector3.ZERO


## Adds a shove for this frame, scaled by knockback resistance.
func apply_push(push: Vector3) -> void:
	push_velocity += Vector3(push.x, 0.0, push.z) * (1.0 - stats.knockback_resistance * 0.6)


## Dropped off the edge of the world: destroyed, no salvage.
func fall() -> void:
	if is_dead:
		return
	_fell = true
	health = 0.0
	_die()


## Returns the desired horizontal velocity for this frame.
func _update_behavior(_delta: float) -> Vector3:
	return Vector3.ZERO


func _apply_movement(delta: float, desired: Vector3) -> void:
	_knockback = _knockback.move_toward(Vector3.ZERO, KNOCKBACK_DECAY * delta)
	velocity.x = desired.x * terrain_speed + _knockback.x + push_velocity.x
	velocity.z = desired.z * terrain_speed + _knockback.z + push_velocity.z
	push_velocity = Vector3.ZERO
	velocity.y = 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
	move_and_slide()
	sprite.play_locomotion(desired)


## Velocity toward the target along the navigation path.
func _chase_velocity(speed: float, delta: float) -> Vector3:
	_repath_timer -= delta
	if _repath_timer <= 0.0:
		_repath_timer = REPATH_INTERVAL
		nav_agent.target_position = target.global_position
	var next: Vector3 = nav_agent.get_next_path_position()
	var to_next: Vector3 = Vector3(next.x - global_position.x, 0.0, next.z - global_position.z)
	if to_next.length_squared() < 0.0025:
		to_next = Vector3(target.global_position.x - global_position.x, 0.0, target.global_position.z - global_position.z)
	if to_next.length_squared() < 0.0001:
		return Vector3.ZERO
	return to_next.normalized() * speed


func _distance_to_target() -> float:
	var flat: Vector3 = target.global_position - global_position
	flat.y = 0.0
	return flat.length()


func _direction_to_target() -> Vector3:
	var flat: Vector3 = target.global_position - global_position
	flat.y = 0.0
	return flat.normalized() if flat.length_squared() > 0.0001 else Vector3.FORWARD


func _can_see_target(max_range: float) -> bool:
	if target == null or target.is_dead:
		return false
	if global_position.distance_to(target.global_position) > max_range:
		return false
	var from: Vector3 = global_position + Vector3.UP * 1.0
	var to: Vector3 = target.global_position + Vector3.UP * 1.0
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to, Layers.ENVIRONMENT)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


## Deals this automaton's attack to the Technician.
func _hit_target(damage: float, knockback_force: float) -> void:
	var push: Vector3 = DamageCalc.knockback(global_position, target.global_position, knockback_force, 0.0)
	target.receive_hit(damage, push)


func receive_hit(damage: float, knockback: Vector3) -> void:
	_take_hit(damage, knockback)


## Environmental crushing (trams) that no shield can turn aside.
func receive_crush_hit(damage: float, knockback: Vector3) -> void:
	_take_hit(damage, knockback)


func _take_hit(damage: float, knockback: Vector3) -> void:
	if is_dead:
		return
	is_aggro = true
	health = DamageCalc.apply_to_health(health, DamageCalc.mitigated_damage(damage, stats.armor))
	_knockback += knockback * (1.0 - stats.knockback_resistance)
	sprite.flash_hit()
	if health <= 0.0:
		_die()


func _die() -> void:
	is_dead = true
	collision_layer = 0
	collision_mask = Layers.ENVIRONMENT
	_on_death()
	Fx.sparks(get_parent(), global_position + Vector3.UP * 0.8)
	Fx.steam_puff(get_parent(), global_position + Vector3.UP * 0.5)
	Audio.play_at(&"enemy_death", global_position)
	sprite.play_death()
	_maybe_drop_gear()
	died.emit(self)
	var tween: Tween = create_tween()
	tween.tween_interval(DEATH_LINGER)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)


## Hook for subclasses to clean up telegraphs etc.
func _on_death() -> void:
	return


func _maybe_drop_gear() -> void:
	if gear_pickup_scene == null or GameState.has_golden_gear or _fell:
		return
	if GameState.rng.randf() >= stats.gear_drop_chance:
		return
	var pickup: GearPickup = gear_pickup_scene.instantiate() as GearPickup
	assert(pickup != null, "%s: gear_pickup_scene must be a GearPickup" % name)
	pickup.gear = GameState.roll_scrap_gear()
	get_parent().add_child.call_deferred(pickup)
	pickup.set_deferred("position", Vector3(global_position.x, 0.0, global_position.z))
