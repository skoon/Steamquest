class_name BrassSentry
extends EnemyBase
## Upright automaton soldier with a brass shield on its front. Hits arriving inside the shield arc
## glance off; it turns slowly, so the way to beat it is to get behind it, where a glowing boiler
## marks its back. A rivet that strikes the shield knocks it aside and staggers the sentry, leaving
## it open to any blow for a moment. Attacks with a telegraphed bayonet thrust.

enum Phase { ADVANCE, TELEGRAPH, RECOVER, STAGGER }

const RECOVER_TIME: float = 0.7
## Only thrusts once it is roughly facing the Technician.
const THRUST_AIM_DEGREES: float = 35.0
const THRUST_HIT_DEGREES: float = 70.0
const NOTICE_INTERVAL_MSEC: int = 4000
const SHIELD_DISTANCE: float = 0.62
const BOILER_DISTANCE: float = 0.5
const SHIELD_DROP_ANGLE: float = 1.2

## Level index the "how to fight a sentry" notice was last shown on, so it appears once per level.
static var _intro_shown_level: int = -2

## Degrees either side of `facing` the shield covers is shield_arc_degrees / 2.
@export var shield_arc_degrees: float = 120.0
## How fast the sentry can turn, in radians per second.
@export var turn_speed: float = 1.6
## Seconds the shield stays knocked aside after a rivet hits it.
@export var stagger_time: float = 1.3
@export_group("Patrol")
## World-space waypoints. With two or more the sentry patrols and only spots the Technician inside
## its lantern cone, raising the alarm at `alarm_path`.
@export var patrol_points: PackedVector3Array = PackedVector3Array()
@export var sight_range: float = 8.0
@export var sight_half_angle: float = 25.0
@export var alarm_path: NodePath
@export var patrol_speed_scale: float = 0.55

var phase: Phase = Phase.ADVANCE
## Horizontal unit vector the sentry (and its shield) faces.
var facing: Vector3 = Vector3.FORWARD
var _phase_time: float = 0.0
var _shield_pivot: Node3D
var _shield_plate: Node3D
var _arc: MeshInstance3D
var _boiler_light: OmniLight3D
var _was_aggro: bool = false
var _route: PatrolRoute
var _alarm: AlarmBell
var _cone_material: StandardMaterial3D
var _thrust_marker: MeshInstance3D
var _last_notice_msec: int = -NOTICE_INTERVAL_MSEC


func _on_ready() -> void:
	var start_facing: Vector3 = -global_basis.z
	start_facing.y = 0.0
	facing = start_facing.normalized() if start_facing.length_squared() > 0.0001 else Vector3.FORWARD
	_build_shield()
	if patrol_points.size() >= 2:
		_route = PatrolRoute.new(patrol_points)
		_build_sight_cone()
	if not alarm_path.is_empty():
		_alarm = get_node(alarm_path) as AlarmBell
		assert(_alarm != null, "%s: alarm_path must point at an AlarmBell" % name)
	_update_shield_pose()


func is_patrolling() -> bool:
	return _route != null


## Inside the lantern cone with a clear line of sight.
func sees_in_cone() -> bool:
	if target == null or target.is_dead:
		return false
	return SightCone.can_see(global_position, facing, target.global_position, sight_range, sight_half_angle) and _can_see_target(sight_range)


func _detect_target() -> bool:
	if _route == null:
		return super()
	return sees_in_cone()


func _idle_behavior(delta: float) -> Vector3:
	if _route == null:
		return Vector3.ZERO
	var point: Vector3 = _route.next_target(global_position, 0.8)
	nav_agent.target_position = point
	var next: Vector3 = nav_agent.get_next_path_position()
	var to_next: Vector3 = Vector3(next.x - global_position.x, 0.0, next.z - global_position.z)
	if to_next.length_squared() < 0.0025:
		to_next = Vector3(point.x - global_position.x, 0.0, point.z - global_position.z)
	if to_next.length_squared() < 0.0001:
		return Vector3.ZERO
	_turn_toward(to_next.normalized(), turn_speed * 1.5 * delta)
	return to_next.normalized() * stats.move_speed * patrol_speed_scale


func _shadow_radius() -> float:
	return 0.7


func is_staggered() -> bool:
	return phase == Phase.STAGGER


## True when a hit carrying `knockback` (which points away from the attacker) meets the shield.
func blocks(knockback: Vector3) -> bool:
	if knockback.length_squared() < 0.000001 or is_staggered():
		return false
	return DamageCalc.is_blocked_by_shield(facing, -knockback, shield_arc_degrees)


func receive_hit(damage: float, knockback: Vector3) -> void:
	if is_dead:
		return
	if not blocks(knockback):
		_take_hit(damage, knockback)
		return
	_deflect(knockback)
	_notice("Its shield turns the blow. Rivet the shield to knock it aside, or get behind it.")


## Rivets that hit the shield don't hurt, but knock it aside and stagger the sentry.
func receive_projectile_hit(damage: float, knockback: Vector3) -> void:
	if is_dead:
		return
	if not blocks(knockback):
		_take_hit(damage, knockback)
		return
	_deflect(knockback)
	_stagger()


func _deflect(knockback: Vector3) -> void:
	is_aggro = true
	_knockback += knockback * 0.15 * (1.0 - stats.knockback_resistance)
	Fx.sparks(get_parent(), global_position + facing * SHIELD_DISTANCE + Vector3.UP * 1.0)
	Audio.play_at(&"sentry_shield", global_position + Vector3.UP)


func _stagger() -> void:
	if phase == Phase.TELEGRAPH:
		(sprite as CharacterSprite).play(&"idle")
	phase = Phase.STAGGER
	_phase_time = stagger_time
	_thrust_marker.visible = false
	_shield_plate.rotation.x = SHIELD_DROP_ANGLE
	_arc.visible = false
	Fx.steam_puff(get_parent(), global_position + Vector3.UP * 1.2)
	_notice("The rivet knocks its shield aside - strike now!")


func _recover_shield() -> void:
	_shield_plate.rotation.x = 0.0
	_arc.visible = true


func _notice(text: String) -> void:
	var now: int = Time.get_ticks_msec()
	if now - _last_notice_msec >= NOTICE_INTERVAL_MSEC:
		_last_notice_msec = now
		GameState.post_notice(text)


## The first sentry to spot the Technician on each level explains how to beat it.
func _introduce() -> void:
	if _intro_shown_level == GameState.level_index:
		return
	_intro_shown_level = GameState.level_index
	_last_notice_msec = Time.get_ticks_msec()
	GameState.post_notice("BRASS SENTRY: its shield blocks from the front. Rivet the shield to stagger it, or hit the glowing boiler on its back.")


func _physics_process(delta: float) -> void:
	super(delta)
	if is_aggro and not _was_aggro and not is_dead:
		_introduce()
		if _cone_material != null:
			_cone_material.albedo_color = Color(1.0, 0.3, 0.2, 0.3)
			_cone_material.emission = Color(1.0, 0.3, 0.2)
	_was_aggro = is_aggro
	if _alarm != null and not is_dead and sees_in_cone():
		_alarm.report_seen()
	if not is_dead and is_aggro and target != null and phase != Phase.TELEGRAPH and phase != Phase.STAGGER:
		_turn_toward(_direction_to_target(), turn_speed * delta)
	if phase == Phase.STAGGER and not is_aggro:
		_update_stagger(delta)
	_boiler_light.light_energy = 1.2 + 0.5 * sin(Time.get_ticks_msec() * 0.006)
	_update_shield_pose()


## Staggers also wear off for a sentry that has lost track of its target.
func _update_stagger(delta: float) -> void:
	_phase_time -= delta
	if _phase_time <= 0.0:
		phase = Phase.ADVANCE
		_recover_shield()


func _turn_toward(direction: Vector3, max_angle: float) -> void:
	var angle: float = facing.signed_angle_to(direction, Vector3.UP)
	facing = facing.rotated(Vector3.UP, clampf(angle, -max_angle, max_angle)).normalized()


func _update_behavior(delta: float) -> Vector3:
	_phase_time -= delta
	match phase:
		Phase.ADVANCE:
			var distance: float = _distance_to_target()
			var aimed: bool = rad_to_deg(facing.angle_to(_direction_to_target())) <= THRUST_AIM_DEGREES
			if distance <= stats.attack_range and aimed and _attack_cooldown <= 0.0:
				phase = Phase.TELEGRAPH
				_phase_time = stats.telegraph_time
				_thrust_marker.visible = true
				(sprite as CharacterSprite).play_attack()
				return Vector3.ZERO
			if distance <= stats.attack_range * 0.8:
				return Vector3.ZERO
			return _chase_velocity(stats.move_speed, delta)
		Phase.TELEGRAPH:
			if _phase_time <= 0.0:
				_thrust()
			return Vector3.ZERO
		Phase.RECOVER:
			if _phase_time <= 0.0:
				phase = Phase.ADVANCE
			return Vector3.ZERO
		Phase.STAGGER:
			if _phase_time <= 0.0:
				phase = Phase.ADVANCE
				_recover_shield()
			return Vector3.ZERO
	return Vector3.ZERO


func _thrust() -> void:
	_thrust_marker.visible = false
	phase = Phase.RECOVER
	_phase_time = RECOVER_TIME
	_attack_cooldown = stats.attack_cooldown
	Audio.play_at(&"sentry_thrust", global_position + Vector3.UP)
	var in_reach: bool = _distance_to_target() <= stats.attack_range + 0.4
	if in_reach and DamageCalc.is_in_arc(global_position, facing, target.global_position, THRUST_HIT_DEGREES):
		_hit_target(stats.attack_damage, stats.attack_knockback)


func _on_death() -> void:
	_thrust_marker.visible = false
	_shield_pivot.visible = false


func _update_shield_pose() -> void:
	_shield_pivot.global_rotation = Vector3(0.0, atan2(facing.x, facing.z), 0.0)


func _build_shield() -> void:
	_shield_pivot = Node3D.new()
	_shield_pivot.name = "Shield"
	add_child(_shield_pivot)
	# The plate hangs from a hinge so a rivet can knock it down and aside.
	_shield_plate = Node3D.new()
	_shield_plate.name = "Plate"
	_shield_plate.position = Vector3(0.0, 1.35, SHIELD_DISTANCE)
	_shield_pivot.add_child(_shield_plate)
	var brass: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.BRASS)
	var plate: CylinderMesh = CylinderMesh.new()
	plate.top_radius = 0.42
	plate.bottom_radius = 0.42
	plate.height = 0.06
	plate.radial_segments = 20
	var plate_instance: MeshInstance3D = Layers.add_mesh(_shield_plate, plate, brass, Vector3(0.0, -0.4, 0.0))
	plate_instance.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	var boss: SphereMesh = SphereMesh.new()
	boss.radius = 0.1
	boss.height = 0.2
	Layers.add_mesh(_shield_plate, boss, FoundryMaterials.get_material(FoundryMaterials.Kind.DARK_STEEL), Vector3(0.0, -0.4, 0.05))
	var rim: TorusMesh = TorusMesh.new()
	rim.inner_radius = 0.38
	rim.outer_radius = 0.45
	var rim_instance: MeshInstance3D = Layers.add_mesh(_shield_plate, rim, FoundryMaterials.get_material(FoundryMaterials.Kind.DARK_STEEL), Vector3(0.0, -0.4, 0.0))
	rim_instance.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	# A bright arc on the floor shows which way the shield covers.
	var arc: MeshInstance3D = MeshInstance3D.new()
	_arc = arc
	arc.mesh = Technician._build_arc_mesh(1.5, shield_arc_degrees)
	var arc_mat: StandardMaterial3D = FoundryMaterials.emissive(Color(0.95, 0.75, 0.35), 1.2)
	arc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	arc_mat.albedo_color = Color(0.95, 0.75, 0.35, 0.45)
	arc_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	arc_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	arc.material_override = arc_mat
	arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arc.position = Vector3(0.0, 0.04, 0.0)
	# The arc mesh opens toward -Z; the pivot faces +Z.
	arc.rotation = Vector3(0.0, PI, 0.0)
	_shield_pivot.add_child(arc)
	_build_back_boiler()

	_thrust_marker = MeshInstance3D.new()
	var line: BoxMesh = BoxMesh.new()
	line.size = Vector3(0.35, 0.03, 2.2)
	_thrust_marker.mesh = line
	_thrust_marker.material_override = FoundryMaterials.get_material(FoundryMaterials.Kind.WARNING_RED)
	_thrust_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_thrust_marker.position = Vector3(0.0, 0.05, 1.3)
	_thrust_marker.visible = false
	_shield_pivot.add_child(_thrust_marker)


## A glowing firebox on the sentry's back, turning with the shield, so its back is easy to read
## even though the sprite always faces the camera.
func _build_back_boiler() -> void:
	var copper: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.COPPER_OXIDIZED)
	var tank: CylinderMesh = CylinderMesh.new()
	tank.top_radius = 0.22
	tank.bottom_radius = 0.26
	tank.height = 0.7
	Layers.add_mesh(_shield_pivot, tank, copper, Vector3(0.0, 1.15, -BOILER_DISTANCE))
	var glow: SphereMesh = SphereMesh.new()
	glow.radius = 0.14
	glow.height = 0.28
	Layers.add_mesh(_shield_pivot, glow, FoundryMaterials.get_material(FoundryMaterials.Kind.FURNACE_GLOW), Vector3(0.0, 1.05, -BOILER_DISTANCE - 0.18))
	var stack: CylinderMesh = CylinderMesh.new()
	stack.top_radius = 0.06
	stack.bottom_radius = 0.07
	stack.height = 0.45
	Layers.add_mesh(_shield_pivot, stack, FoundryMaterials.get_material(FoundryMaterials.Kind.DARK_STEEL), Vector3(0.12, 1.65, -BOILER_DISTANCE))
	_boiler_light = OmniLight3D.new()
	_boiler_light.light_color = Color(1.0, 0.5, 0.2)
	_boiler_light.light_energy = 1.2
	_boiler_light.omni_range = 2.5
	_boiler_light.position = Vector3(0.0, 1.05, -BOILER_DISTANCE - 0.45)
	_shield_pivot.add_child(_boiler_light)


## The lantern's beam on the floor, so the player can read where the patrol is looking.
func _build_sight_cone() -> void:
	var cone: MeshInstance3D = MeshInstance3D.new()
	cone.name = "SightCone"
	cone.mesh = Technician._build_arc_mesh(sight_range, sight_half_angle * 2.0)
	_cone_material = FoundryMaterials.emissive(Color(1.0, 0.9, 0.55), 0.8)
	_cone_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_cone_material.albedo_color = Color(1.0, 0.9, 0.55, 0.16)
	_cone_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_cone_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	cone.material_override = _cone_material
	cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cone.position = Vector3(0.0, 0.03, 0.0)
	cone.rotation = Vector3(0.0, PI, 0.0)
	_shield_pivot.add_child(cone)
	var lantern: SpotLight3D = SpotLight3D.new()
	lantern.light_color = Color(1.0, 0.85, 0.55)
	lantern.light_energy = 2.0
	lantern.spot_range = sight_range
	lantern.spot_angle = sight_half_angle
	lantern.position = Vector3(0.0, 1.6, 0.3)
	lantern.rotation = Vector3(-0.25, PI, 0.0)
	_shield_pivot.add_child(lantern)

