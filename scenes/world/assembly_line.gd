class_name AssemblyLine
extends Node3D
## The end of the production line. While running it turns out an automaton every `spawn_interval`
## seconds (up to `max_alive`) once the Technician comes near. Smashing every listed DriveGovernor
## jams it for good and unlocks `unlock_id`.

@export var spawn_scenes: Array[PackedScene] = []
@export var spawn_interval: float = 5.0
@export var max_alive: int = 4
@export var activation_range: float = 22.0
@export var governors: Array[NodePath] = []
@export var unlock_id: StringName = &""
## Spawned automatons appear here, relative to this node.
@export var spawn_offset: Vector3 = Vector3(1.5, 0.05, 0.0)
## FoundryBuilder keeps clutter this far away.
@export var radius: float = 2.0

var schedule: SpawnSchedule
var spawned_total: int = 0
var is_jammed: bool = false
var _governors: Array[DriveGovernor] = []
var _since_spawn: float = 0.0
var _alive: Array[EnemyBase] = []
var _lamp: StandardMaterial3D
var _cog: Node3D


func _ready() -> void:
	assert(not spawn_scenes.is_empty(), "%s: spawn_scenes is required" % name)
	assert(unlock_id != &"", "%s: unlock_id is required" % name)
	assert(not governors.is_empty(), "%s: needs governors" % name)
	schedule = SpawnSchedule.new(spawn_interval, max_alive)
	_since_spawn = spawn_interval * 0.5
	for path: NodePath in governors:
		var governor: DriveGovernor = get_node(path) as DriveGovernor
		assert(governor != null, "%s: %s is not a DriveGovernor" % [name, path])
		governor.smashed.connect(_on_governor_smashed)
		_governors.append(governor)
	_build_visuals()


func governors_left() -> int:
	return _governors.filter(func(governor: DriveGovernor) -> bool: return not governor.is_smashed()).size()


func alive_count() -> int:
	_alive = _alive.filter(func(enemy: EnemyBase) -> bool: return is_instance_valid(enemy) and not enemy.is_dead)
	return _alive.size()


func _process(delta: float) -> void:
	if not is_jammed:
		_cog.rotation.z += 1.6 * delta


func _physics_process(delta: float) -> void:
	if is_jammed:
		return
	var player: Technician = get_tree().get_first_node_in_group(&"player") as Technician
	if player == null or player.is_dead or player.global_position.distance_to(global_position) > activation_range:
		return
	_since_spawn += delta
	if schedule.should_spawn(_since_spawn, alive_count()):
		_since_spawn = 0.0
		_spawn()


func _spawn() -> void:
	var enemy: EnemyBase = spawn_scenes[spawned_total % spawn_scenes.size()].instantiate() as EnemyBase
	assert(enemy != null, "%s: spawn scenes must be EnemyBase scenes" % name)
	get_parent().add_child(enemy)
	enemy.global_position = global_position + global_basis * spawn_offset
	enemy.is_aggro = true
	_alive.append(enemy)
	spawned_total += 1
	Fx.steam_puff(get_parent(), enemy.global_position + Vector3.UP * 0.4)
	Audio.play_at(&"nest_pulse", global_position + Vector3.UP)


func _on_governor_smashed(_governor: DriveGovernor) -> void:
	var left: int = governors_left()
	if left > 0:
		GameState.post_notice("A governor flies apart. The line stutters - %d to go." % left)
		return
	is_jammed = true
	_lamp.albedo_color = Color(0.25, 0.06, 0.04)
	_lamp.emission = _lamp.albedo_color
	Fx.steam_puff(get_parent(), global_position + Vector3.UP * 2.5)
	Audio.play_at(&"governor_break", global_position + Vector3.UP * 2.0)
	GameState.post_notice("The line seizes with a shriek of gears. No more guards tonight - the lift is free.")
	GameState.unlock_door(unlock_id)


func _build_visuals() -> void:
	var iron: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.CAST_IRON)
	var brass: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.BRASS)
	var frame: BoxMesh = BoxMesh.new()
	frame.size = Vector3(1.6, 3.0, 3.0)
	Layers.add_mesh(self, frame, iron, Vector3(-0.8, 1.5, 0.0))
	Layers.add_static_box(self, Vector3(1.6, 3.0, 3.0), Vector3(-0.8, 1.5, 0.0))
	var hatch: BoxMesh = BoxMesh.new()
	hatch.size = Vector3(0.05, 1.4, 1.6)
	Layers.add_mesh(self, hatch, FoundryMaterials.emissive(Color(1.0, 0.5, 0.2), 0.8), Vector3(0.01, 0.8, 0.0))
	_cog = GearMeshFactory.build(0.9, 0.2, 12, brass)
	_cog.position = Vector3(-0.8, 2.3, 1.55)
	_cog.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	add_child(_cog)
	_lamp = FoundryMaterials.emissive(Color(0.3, 1.0, 0.45), 3.0)
	var bulb: SphereMesh = SphereMesh.new()
	bulb.radius = 0.15
	bulb.height = 0.3
	Layers.add_mesh(self, bulb, _lamp, Vector3(-0.8, 3.2, 0.0))
