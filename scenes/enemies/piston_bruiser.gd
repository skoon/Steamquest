class_name PistonBruiser
extends EnemyBase
## Heavy steam automaton. Lumbers toward the Technician, then telegraphs a ground slam
## with a growing red ring before dealing area damage.

enum Phase { CHASE, TELEGRAPH, RECOVER }

const RECOVER_TIME: float = 0.9

## Slams per attack; the extra slams follow with a shorter telegraph (the Cistern Warden uses 3).
@export var combo_slams: int = 1
@export var combo_telegraph: float = 0.45

var _phase: Phase = Phase.CHASE
var _phase_time: float = 0.0
var _ring: MeshInstance3D
var _slams_left: int = 0
var _telegraph_total: float = 1.0


func _shadow_radius() -> float:
	return 0.9


func _on_ready() -> void:
	_ring = MeshInstance3D.new()
	var ring_mesh: CylinderMesh = CylinderMesh.new()
	ring_mesh.top_radius = 1.0
	ring_mesh.bottom_radius = 1.0
	ring_mesh.height = 0.04
	ring_mesh.radial_segments = 48
	_ring.mesh = ring_mesh
	_ring.material_override = FoundryMaterials.get_material(FoundryMaterials.Kind.WARNING_RED)
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.position = Vector3(0.0, 0.05, 0.0)
	_ring.visible = false
	add_child(_ring)


func _update_behavior(delta: float) -> Vector3:
	_phase_time -= delta
	match _phase:
		Phase.CHASE:
			if _distance_to_target() <= stats.attack_range and _attack_cooldown <= 0.0:
				_begin_telegraph()
				return Vector3.ZERO
			return _chase_velocity(stats.move_speed, delta)
		Phase.TELEGRAPH:
			var progress: float = 1.0 - clampf(_phase_time / _telegraph_total, 0.0, 1.0)
			var radius: float = lerpf(0.3, stats.area_radius, progress)
			_ring.scale = Vector3(radius, 1.0, radius)
			if _phase_time <= 0.0:
				_slam()
			return Vector3.ZERO
		Phase.RECOVER:
			if _phase_time <= 0.0:
				_phase = Phase.CHASE
			return Vector3.ZERO
	return Vector3.ZERO


func _begin_telegraph() -> void:
	_slams_left = combo_slams
	if combo_slams > 1:
		Audio.play_at(&"warden_roar", global_position + Vector3.UP * 1.5)
	_start_ring(stats.telegraph_time)


func _start_ring(telegraph: float) -> void:
	_phase = Phase.TELEGRAPH
	_phase_time = telegraph
	_telegraph_total = telegraph
	_ring.visible = true
	_ring.scale = Vector3(0.3, 1.0, 0.3)
	sprite.play_attack()


func _slam() -> void:
	_ring.visible = false
	_slams_left -= 1
	_phase = Phase.RECOVER
	_phase_time = RECOVER_TIME
	_attack_cooldown = stats.attack_cooldown
	_slam_effects()
	if _slams_left > 0:
		_start_ring(combo_telegraph)


func _slam_effects() -> void:
	for i: int in 6:
		var angle: float = TAU * float(i) / 6.0
		Fx.steam_puff(get_parent(), global_position + Vector3(cos(angle) * 1.5, 0.2, sin(angle) * 1.5))
	Fx.sparks(get_parent(), global_position + Vector3.UP * 0.2)
	Audio.play_at(&"bruiser_slam", global_position)
	if _distance_to_target() <= stats.area_radius:
		_hit_target(stats.attack_damage, stats.attack_knockback)


func _on_death() -> void:
	_ring.visible = false
