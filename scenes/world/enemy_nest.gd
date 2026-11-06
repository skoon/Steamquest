class_name EnemyNest
extends StaticBody3D
## A heap of scrap with a glowing assembly core that keeps turning out automatons while the
## Technician is near. Wrench or rivet it to pieces; destroying it unlocks `unlock_id`.

signal destroyed(nest: EnemyNest)

@export var spawn_scenes: Array[PackedScene] = []
@export var spawn_interval: float = 5.0
@export var max_alive: int = 3
@export var max_health: float = 90.0
@export var unlock_id: StringName = &""
## Only builds while the Technician is within this distance.
@export var activation_range: float = 15.0
## FoundryBuilder keeps clutter this far away.
@export var radius: float = 1.6

var health: float = 0.0
var is_destroyed: bool = false
var schedule: SpawnSchedule
var spawned_total: int = 0
var _since_spawn: float = 0.0
var _alive: Array[EnemyBase] = []
var _spawn_turn: int = 0
var _core: StandardMaterial3D
var _core_light: OmniLight3D
var _heap: Node3D
var _pulse: float = 0.0


func _ready() -> void:
	assert(not spawn_scenes.is_empty(), "%s: spawn_scenes is required" % name)
	assert(unlock_id != &"", "%s: unlock_id is required" % name)
	health = max_health
	schedule = SpawnSchedule.new(spawn_interval, max_alive)
	_since_spawn = spawn_interval * 0.6
	collision_layer = Layers.ENEMIES
	collision_mask = 0
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var cylinder: CylinderShape3D = CylinderShape3D.new()
	cylinder.radius = 1.0
	cylinder.height = 1.4
	shape_node.shape = cylinder
	shape_node.position = Vector3(0.0, 0.7, 0.0)
	add_child(shape_node)
	_build_visuals()


func alive_count() -> int:
	_alive = _alive.filter(func(enemy: EnemyBase) -> bool: return is_instance_valid(enemy) and not enemy.is_dead)
	return _alive.size()


func _physics_process(delta: float) -> void:
	if is_destroyed:
		return
	_pulse = maxf(_pulse - delta * 2.0, 0.0)
	_core.emission_energy_multiplier = 1.5 + 4.0 * _pulse
	_core_light.light_energy = 0.8 + 2.5 * _pulse
	var player: Technician = get_tree().get_first_node_in_group(&"player") as Technician
	if player == null or player.is_dead or player.global_position.distance_to(global_position) > activation_range:
		return
	_since_spawn += delta
	if schedule.should_spawn(_since_spawn, alive_count()):
		_since_spawn = 0.0
		_spawn()


func _spawn() -> void:
	var scene: PackedScene = spawn_scenes[spawned_total % spawn_scenes.size()]
	var enemy: EnemyBase = scene.instantiate() as EnemyBase
	assert(enemy != null, "%s: spawn scenes must be EnemyBase scenes" % name)
	var angle: float = TAU * float(_spawn_turn) / 5.0 + 0.4
	_spawn_turn += 1
	get_parent().add_child(enemy)
	enemy.global_position = global_position + Vector3(cos(angle) * 1.9, 0.05, sin(angle) * 1.9)
	enemy.is_aggro = true
	_alive.append(enemy)
	spawned_total += 1
	_pulse = 1.0
	Fx.steam_puff(get_parent(), enemy.global_position + Vector3.UP * 0.4)
	Audio.play_at(&"nest_pulse", global_position + Vector3.UP)


func receive_hit(damage: float, _knockback: Vector3) -> void:
	if is_destroyed:
		return
	health = DamageCalc.apply_to_health(health, damage)
	_pulse = 1.0
	var tween: Tween = create_tween()
	tween.tween_property(_heap, "scale", Vector3(1.08, 0.9, 1.08), 0.06)
	tween.tween_property(_heap, "scale", Vector3.ONE, 0.12)
	if health <= 0.0:
		_destroy()


func _destroy() -> void:
	is_destroyed = true
	collision_layer = 0
	for i: int in 3:
		Fx.sparks(get_parent(), global_position + Vector3(randf_range(-0.6, 0.6), 0.6, randf_range(-0.6, 0.6)))
	Fx.steam_puff(get_parent(), global_position + Vector3.UP * 0.6)
	Audio.play_at(&"nest_break", global_position + Vector3.UP * 0.5)
	GameState.post_notice("Nest smashed - its assembly core gutters out.")
	GameState.unlock_door(unlock_id)
	destroyed.emit(self)
	_core.emission_energy_multiplier = 0.0
	_core_light.light_energy = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(_heap, "scale", Vector3(1.3, 0.25, 1.3), 0.35)


func _build_visuals() -> void:
	_heap = Node3D.new()
	add_child(_heap)
	var rust: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.RUST)
	var iron: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.CAST_IRON)
	var brass: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.BRASS)
	var mound: SphereMesh = SphereMesh.new()
	mound.radius = 1.1
	mound.height = 1.3
	Layers.add_mesh(_heap, mound, rust, Vector3(0.0, 0.3, 0.0))
	var scrap: BoxMesh = BoxMesh.new()
	scrap.size = Vector3(0.5, 0.12, 0.3)
	for i: int in 9:
		var angle: float = TAU * float(i) / 9.0
		var piece: MeshInstance3D = Layers.add_mesh(_heap, scrap, iron if i % 2 == 0 else brass, Vector3(cos(angle) * 0.85, 0.35 + 0.12 * float(i % 3), sin(angle) * 0.85))
		piece.rotation = Vector3(0.4 * float(i % 3), angle, 0.3)
	var ring: TorusMesh = TorusMesh.new()
	ring.inner_radius = 0.35
	ring.outer_radius = 0.48
	Layers.add_mesh(_heap, ring, brass, Vector3(0.0, 0.95, 0.0))
	_core = FoundryMaterials.emissive(Color(1.0, 0.45, 0.15), 1.5)
	var core: SphereMesh = SphereMesh.new()
	core.radius = 0.3
	core.height = 0.6
	Layers.add_mesh(_heap, core, _core, Vector3(0.0, 1.05, 0.0))
	_core_light = OmniLight3D.new()
	_core_light.light_color = Color(1.0, 0.5, 0.2)
	_core_light.light_energy = 0.8
	_core_light.omni_range = 5.0
	_core_light.position = Vector3(0.0, 1.4, 0.0)
	_heap.add_child(_core_light)
