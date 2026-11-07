class_name SteamWalker
extends EnemyBase
## The Overseer's Steam Walker, boss of the Engine Yard. Its moves change with its health
## (BossPhases): phase 1 stomps; phase 2 alternates stomps with a sweeping steam breath, after
## which it overheats and exposes its boiler valve - three wrench blows on the valve stagger it,
## and it takes double damage while staggered (half otherwise from phase 2 on); phase 3 also
## calls in automatons and charges down a telegraphed lane. It drops the Foundry Seal.

enum Move { CHASE, STOMP, BREATH_WINDUP, BREATH, OVERHEAT, STAGGER, CHARGE_WINDUP, CHARGE, RECOVER }

const STOMP_TELEGRAPH: float = 1.0
const BREATH_WINDUP_TIME: float = 1.0
const BREATH_TIME: float = 1.6
const BREATH_SWEEP_DEGREES: float = 120.0
const BREATH_RANGE: float = 9.0
const BREATH_HALF_ANGLE: float = 14.0
const BREATH_DAMAGE: float = 18.0
const BREATH_HIT_INTERVAL: float = 0.4
const OVERHEAT_TIME: float = 4.0
const STAGGER_TIME: float = 4.0
const VALVE_HITS: int = 3
const CHARGE_WINDUP_TIME: float = 1.2
const CHARGE_SPEED: float = 16.0
const CHARGE_LENGTH: float = 18.0
const CHARGE_DAMAGE: float = 35.0
const CHARGE_KNOCKBACK: float = 20.0
const CHARGE_HIT_RADIUS: float = 2.4
const RECOVER_TIME: float = 1.0
const ADD_INTERVAL: float = 12.0
const MAX_ADDS: int = 4
const STAGGER_MULTIPLIER: float = 2.0
const ARMOURED_MULTIPLIER: float = 0.5

@export var add_scenes: Array[PackedScene] = []
@export var seal_scene: PackedScene
@export var seal_item_id: StringName = &"foundry_seal"
## World positions at the yard edges where called-in automatons appear (cycled in order).
@export var add_spawn_points: PackedVector3Array = PackedVector3Array()

var move: Move = Move.CHASE
var valve_counter: HitCounter
var adds_spawned: int = 0
var _move_time: float = 0.0
var _stomps_since_breath: int = 0
var _breath_from: Vector3 = Vector3.FORWARD
var _breath_facing: Vector3 = Vector3.FORWARD
var _since_breath_hit: float = 0.0
var _charge_dir: Vector3 = Vector3.FORWARD
var _charge_travelled: float = 0.0
var _charge_hit: bool = false
var _since_adds: float = 0.0
var _adds: Array[EnemyBase] = []
var _bar_shown: bool = false
var _ring: MeshInstance3D
var _lane: MeshInstance3D
var _breath_emitter: GPUParticles3D
var _valve: Area3D
var _valve_light: OmniLight3D


func _shadow_radius() -> float:
	return 1.8


func _on_ready() -> void:
	assert(seal_scene != null, "SteamWalker: seal_scene missing")
	assert(not add_scenes.is_empty(), "SteamWalker: add_scenes missing")
	assert(not add_spawn_points.is_empty(), "SteamWalker: add_spawn_points missing")
	valve_counter = HitCounter.new(VALVE_HITS)
	(sprite as Sprite3D).billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_ring = _make_flat_mesh(CylinderMesh.new())
	(_ring.mesh as CylinderMesh).top_radius = 1.0
	(_ring.mesh as CylinderMesh).bottom_radius = 1.0
	(_ring.mesh as CylinderMesh).height = 0.04
	(_ring.mesh as CylinderMesh).radial_segments = 48
	_lane = _make_flat_mesh(BoxMesh.new())
	(_lane.mesh as BoxMesh).size = Vector3(CHARGE_HIT_RADIUS * 1.6, 0.04, CHARGE_LENGTH)
	_breath_emitter = Fx.make_steam_emitter(90, 0.8, 11.0, 10.0)
	_breath_emitter.position = Vector3(0.0, 2.6, 0.0)
	_breath_emitter.emitting = false
	add_child(_breath_emitter)
	_build_valve()


func phase() -> int:
	return BossPhases.phase_for(health / stats.max_health)


func is_staggered() -> bool:
	return move == Move.STAGGER


func is_overheated() -> bool:
	return move == Move.OVERHEAT


func alive_adds() -> int:
	_adds = _adds.filter(func(enemy: EnemyBase) -> bool: return is_instance_valid(enemy) and not enemy.is_dead)
	return _adds.size()


## Skips straight to the overheat (tests reach the valve without surviving a breath).
func force_overheat() -> void:
	_end_breath()


func _exit_tree() -> void:
	if _bar_shown:
		GameState.boss_health_changed.emit(stats.display_name, -1.0)


func receive_hit(damage: float, knockback: Vector3) -> void:
	_take_hit(damage * _damage_multiplier(), knockback)
	_show_health()


func receive_crush_hit(damage: float, knockback: Vector3) -> void:
	receive_hit(damage, knockback)


func _damage_multiplier() -> float:
	if move == Move.STAGGER:
		return STAGGER_MULTIPLIER
	return ARMOURED_MULTIPLIER if phase() >= 2 else 1.0


func _show_health() -> void:
	_bar_shown = true
	GameState.boss_health_changed.emit(stats.display_name, maxf(health, 0.0) / stats.max_health if not is_dead else -1.0)


func _update_behavior(delta: float) -> Vector3:
	if not _bar_shown:
		_show_health()
		GameState.post_notice("The Steam Walker rises from its cradle!")
		Audio.play_at(&"walker_charge", global_position + Vector3.UP * 3.0)
	_move_time -= delta
	if phase() >= 3:
		_tick_adds(delta)
	match move:
		Move.CHASE:
			return _chase(delta)
		Move.STOMP:
			var progress: float = 1.0 - clampf(_move_time / STOMP_TELEGRAPH, 0.0, 1.0)
			var radius: float = lerpf(0.5, stats.area_radius, progress)
			_ring.scale = Vector3(radius, 1.0, radius)
			if _move_time <= 0.0:
				_stomp()
		Move.BREATH_WINDUP:
			if _move_time <= 0.0:
				_begin_breath()
		Move.BREATH:
			_tick_breath(delta)
		Move.OVERHEAT:
			_valve_light.light_energy = 2.0 + sin(Time.get_ticks_msec() * 0.02) * 1.0
			if _move_time <= 0.0:
				_cool_down()
		Move.STAGGER:
			if _move_time <= 0.0:
				sprite.modulate = Color.WHITE
				_recover()
		Move.CHARGE_WINDUP:
			_lane.visible = fmod(_move_time, 0.2) > 0.08
			if _move_time <= 0.0:
				_lane.visible = false
				move = Move.CHARGE
				_charge_travelled = 0.0
				_charge_hit = false
				Audio.play_at(&"walker_charge", global_position + Vector3.UP * 2.0)
		Move.CHARGE:
			return _tick_charge(delta)
		Move.RECOVER:
			if _move_time <= 0.0:
				move = Move.CHASE
	return Vector3.ZERO


func _chase(delta: float) -> Vector3:
	if _attack_cooldown > 0.0:
		return _chase_velocity(stats.move_speed, delta)
	var current: int = phase()
	var distance: float = _distance_to_target()
	if current >= 3 and distance > 6.0 and distance < CHARGE_LENGTH - 2.0:
		_begin_charge()
		return Vector3.ZERO
	if current >= 2 and _stomps_since_breath >= 1 and distance <= BREATH_RANGE - 1.0:
		_begin_breath_windup()
		return Vector3.ZERO
	if distance <= stats.attack_range:
		_begin_stomp()
		return Vector3.ZERO
	return _chase_velocity(stats.move_speed, delta)


func _begin_stomp() -> void:
	move = Move.STOMP
	_move_time = STOMP_TELEGRAPH
	_ring.visible = true
	_ring.scale = Vector3(0.5, 1.0, 0.5)


func _stomp() -> void:
	_ring.visible = false
	_stomps_since_breath += 1
	for i: int in 8:
		var angle: float = TAU * float(i) / 8.0
		Fx.steam_puff(get_parent(), global_position + Vector3(cos(angle) * 2.5, 0.2, sin(angle) * 2.5))
	Audio.play_at(&"walker_stomp", global_position)
	if _distance_to_target() <= stats.area_radius:
		_hit_target(stats.attack_damage, stats.attack_knockback)
	_recover()


func _begin_breath_windup() -> void:
	move = Move.BREATH_WINDUP
	_move_time = BREATH_WINDUP_TIME
	_breath_from = _direction_to_target().rotated(Vector3.UP, deg_to_rad(-BREATH_SWEEP_DEGREES * 0.5))
	Fx.steam_puff(get_parent(), global_position + Vector3.UP * 2.8)
	Audio.play_at(&"press_hiss", global_position + Vector3.UP * 2.5)


func _begin_breath() -> void:
	move = Move.BREATH
	_move_time = BREATH_TIME
	_since_breath_hit = BREATH_HIT_INTERVAL
	_breath_emitter.emitting = true
	Audio.play_at(&"walker_breath", global_position + Vector3.UP * 2.5)


func _tick_breath(delta: float) -> void:
	var progress: float = 1.0 - clampf(_move_time / BREATH_TIME, 0.0, 1.0)
	_breath_facing = _breath_from.rotated(Vector3.UP, deg_to_rad(BREATH_SWEEP_DEGREES * progress))
	_breath_emitter.basis = Basis.looking_at(_breath_facing, Vector3.UP) * Basis(Vector3.RIGHT, -PI * 0.5)
	_since_breath_hit += delta
	if _since_breath_hit >= BREATH_HIT_INTERVAL and _breath_reaches_target():
		_since_breath_hit = 0.0
		_hit_target(BREATH_DAMAGE, 6.0)
	if _move_time <= 0.0:
		_end_breath()


func _breath_reaches_target() -> bool:
	if not SightCone.can_see(global_position, _breath_facing, target.global_position, BREATH_RANGE, BREATH_HALF_ANGLE):
		return false
	return _can_see_target(BREATH_RANGE + 1.0)


func _end_breath() -> void:
	_breath_emitter.emitting = false
	_stomps_since_breath = 0
	move = Move.OVERHEAT
	_move_time = OVERHEAT_TIME
	valve_counter.reset()
	_valve.monitorable = true
	_valve_light.visible = true
	sprite.modulate = Color(1.0, 0.7, 0.55)
	GameState.post_notice("The Walker's boiler is glowing - its valve is exposed! Bash it!")


func _cool_down() -> void:
	_close_valve()
	sprite.modulate = Color.WHITE
	_recover()


func _close_valve() -> void:
	_valve.monitorable = false
	_valve_light.visible = false


func on_valve_bashed() -> void:
	if move != Move.OVERHEAT:
		return
	Fx.sparks(get_parent(), _valve.global_position)
	if not valve_counter.register():
		GameState.post_notice("The boiler valve buckles... (%d/%d)" % [valve_counter.hits, valve_counter.required])
		return
	_close_valve()
	move = Move.STAGGER
	_move_time = STAGGER_TIME
	sprite.modulate = Color(0.7, 0.75, 1.0)
	Fx.steam_puff(get_parent(), global_position + Vector3.UP * 2.0)
	Fx.steam_puff(get_parent(), global_position + Vector3.UP * 3.0)
	Audio.play_at(&"valve_free", global_position + Vector3.UP * 2.0)
	GameState.post_notice("The Walker staggers, venting everything - hit it now!")


func _begin_charge() -> void:
	move = Move.CHARGE_WINDUP
	_move_time = CHARGE_WINDUP_TIME
	_charge_dir = _direction_to_target()
	_lane.basis = Basis.looking_at(_charge_dir, Vector3.UP)
	_lane.position = Vector3(0.0, 0.05, 0.0) + _charge_dir * CHARGE_LENGTH * 0.5
	_lane.visible = true
	Audio.play_at(&"tram_bell", global_position + Vector3.UP * 2.0)


func _tick_charge(delta: float) -> Vector3:
	_charge_travelled += CHARGE_SPEED * delta
	if not _charge_hit and _distance_to_target() <= CHARGE_HIT_RADIUS:
		_charge_hit = true
		_hit_target(CHARGE_DAMAGE, CHARGE_KNOCKBACK)
	if _charge_travelled >= CHARGE_LENGTH or (_charge_travelled > 1.0 and is_on_wall()):
		Fx.steam_puff(get_parent(), global_position + Vector3.UP)
		Audio.play_at(&"walker_stomp", global_position, -3.0)
		_recover()
		return Vector3.ZERO
	return _charge_dir * CHARGE_SPEED


func _recover() -> void:
	move = Move.RECOVER
	_move_time = RECOVER_TIME
	_attack_cooldown = stats.attack_cooldown


func _tick_adds(delta: float) -> void:
	_since_adds += delta
	if _since_adds < ADD_INTERVAL:
		return
	_since_adds = 0.0
	for i: int in 3:
		if alive_adds() >= MAX_ADDS:
			return
		_spawn_add(i)


func _spawn_add(slot: int) -> void:
	var scene: PackedScene = add_scenes[mini(slot, add_scenes.size() - 1)]
	var add: EnemyBase = scene.instantiate() as EnemyBase
	assert(add != null, "SteamWalker: add scenes must be EnemyBase scenes")
	get_parent().add_child(add)
	add.global_position = add_spawn_points[adds_spawned % add_spawn_points.size()] + Vector3(0.0, 0.05, 0.0)
	add.is_aggro = true
	_adds.append(add)
	adds_spawned += 1
	Fx.steam_puff(get_parent(), add.global_position + Vector3.UP * 0.4)
	if slot == 0:
		Audio.play_at(&"pressure_klaxon", global_position + Vector3.UP * 3.0, -6.0)
		GameState.post_notice("The Walker's whistle calls the yard's automatons!")


func _on_death() -> void:
	_ring.visible = false
	_lane.visible = false
	_breath_emitter.emitting = false
	_close_valve()
	GameState.boss_health_changed.emit(stats.display_name, -1.0)
	var seal: KeyPickup = seal_scene.instantiate() as KeyPickup
	assert(seal != null, "SteamWalker: seal_scene must be a KeyPickup")
	seal.item_id = seal_item_id
	seal.display_name = "Foundry Seal"
	seal.look = KeyPickup.Look.FOUNDRY_SEAL
	get_parent().add_child.call_deferred(seal)
	seal.set_deferred("position", Vector3(global_position.x, 0.0, global_position.z))
	GameState.post_notice("The Steam Walker collapses in a cloud of steam. Something brass rolls free...")


func _make_flat_mesh(mesh: PrimitiveMesh) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = FoundryMaterials.get_material(FoundryMaterials.Kind.WARNING_RED)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.position = Vector3(0.0, 0.05, 0.0)
	instance.visible = false
	add_child(instance)
	return instance


func _build_valve() -> void:
	_valve = WalkerValve.new()
	_valve.walker = self
	_valve.position = Vector3(0.0, 1.0, 0.0)
	add_child(_valve)
	_valve_light = OmniLight3D.new()
	_valve_light.light_color = Color(1.0, 0.35, 0.1)
	_valve_light.omni_range = 4.0
	_valve_light.position = Vector3(0.0, 1.6, 0.0)
	_valve_light.visible = false
	add_child(_valve_light)
	_close_valve()
