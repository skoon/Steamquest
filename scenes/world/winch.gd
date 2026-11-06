class_name Winch
extends Interactable
## The mine lift's seized winch. Bash it free with the wrench, then start it and stay close while
## it winds the cage up; automatons come at you in waves the whole time. Winding pauses while you
## are away. When it finishes it unlocks `unlock_id`.

enum Stage { SEIZED, READY, WINDING, DONE }

@export var unlock_id: StringName = &""
@export var hits_required: int = 3
@export var wind_duration: float = 40.0
@export var hold_radius: float = 6.0
@export var wave_scenes: Array[PackedScene] = []
@export var wave_interval: float = 7.0
@export var max_alive: int = 4
## Offsets from the winch where waves appear.
@export var spawn_offsets: PackedVector3Array = PackedVector3Array()
@export var radius: float = 2.0

var stage: Stage = Stage.SEIZED
var hold: HoldProgress
var schedule: SpawnSchedule
var spawned_total: int = 0
var _hits: int = 0
var _since_wave: float = 0.0
var _alive: Array[EnemyBase] = []
var _drum: Node3D
var _meter: Label3D
var _crank_timer: float = 0.0


func _ready() -> void:
	assert(unlock_id != &"", "%s: unlock_id is required" % name)
	assert(not wave_scenes.is_empty() and not spawn_offsets.is_empty(), "%s: waves need scenes and spawn offsets" % name)
	hold = HoldProgress.new(wind_duration)
	schedule = SpawnSchedule.new(wave_interval, max_alive)
	add_trigger_sphere(1.8, 1.0)
	_build_visuals()


func get_prompt() -> String:
	return "[F] Engage the winch" if stage == Stage.READY else ""


func can_interact() -> bool:
	return stage == Stage.READY


func interact(_technician: Node3D) -> void:
	start_winding()


func receive_bash() -> void:
	if stage != Stage.SEIZED:
		return
	_hits += 1
	var tween: Tween = create_tween()
	tween.tween_property(_drum, "rotation:x", _drum.rotation.x + 0.4, 0.12)
	if _hits < hits_required:
		GameState.post_notice("The winch brake groans... (%d/%d)" % [_hits, hits_required])
		return
	stage = Stage.READY
	Fx.steam_puff(get_parent(), global_position + Vector3.UP * 1.5)
	Audio.play_at(&"valve_free", global_position + Vector3.UP)
	GameState.post_notice("Brake knocked free. Engage the winch - and hold the line while it winds.")
	_update_meter()


func start_winding() -> void:
	assert(stage == Stage.READY, "%s: winch is not ready" % name)
	stage = Stage.WINDING
	_since_wave = wave_interval
	Audio.play_at(&"winch_crank", global_position + Vector3.UP)
	GameState.post_notice("The winch takes up the cable. Stay close!")
	_update_meter()


func alive_count() -> int:
	_alive = _alive.filter(func(enemy: EnemyBase) -> bool: return is_instance_valid(enemy) and not enemy.is_dead)
	return _alive.size()


func _physics_process(delta: float) -> void:
	if stage != Stage.WINDING:
		return
	var player: Technician = get_tree().get_first_node_in_group(&"player") as Technician
	var near: bool = player != null and not player.is_dead and _flat_distance(player.global_position) <= hold_radius
	hold.tick(delta, near)
	if near:
		_drum.rotation.x += 2.5 * delta
		_crank_timer -= delta
		if _crank_timer <= 0.0:
			_crank_timer = 1.6
			Audio.play_at(&"winch_crank", global_position + Vector3.UP, -6.0)
	_since_wave += delta
	if schedule.should_spawn(_since_wave, alive_count()):
		_since_wave = 0.0
		_spawn_wave_member()
	_update_meter(near)
	if hold.is_complete():
		_finish()


func _flat_distance(point: Vector3) -> float:
	return Vector2(point.x - global_position.x, point.z - global_position.z).length()


func _spawn_wave_member() -> void:
	var scene: PackedScene = wave_scenes[mini(int(spawned_total / 3.0), wave_scenes.size() - 1)]
	var enemy: EnemyBase = scene.instantiate() as EnemyBase
	assert(enemy != null, "%s: wave scenes must be EnemyBase scenes" % name)
	get_parent().add_child(enemy)
	enemy.global_position = global_position + spawn_offsets[spawned_total % spawn_offsets.size()] + Vector3(0.0, 0.05, 0.0)
	enemy.is_aggro = true
	_alive.append(enemy)
	spawned_total += 1
	Fx.steam_puff(get_parent(), enemy.global_position + Vector3.UP * 0.4)


func _finish() -> void:
	stage = Stage.DONE
	Audio.play_at(&"lift_rise", global_position + Vector3.UP)
	GameState.post_notice("The cage clanks home at the top of the shaft. The lift gate unlocks.")
	GameState.unlock_door(unlock_id)
	_update_meter()


func _update_meter(near: bool = true) -> void:
	match stage:
		Stage.SEIZED:
			_meter.text = "WINCH SEIZED"
		Stage.READY:
			_meter.text = "WINCH READY"
		Stage.WINDING:
			_meter.text = "WINDING %d%%%s" % [int(hold.progress * 100.0), "" if near else "  (STAY CLOSE)"]
		Stage.DONE:
			_meter.text = "CAGE UP"


func _build_visuals() -> void:
	var iron: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.CAST_IRON)
	var wood: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.WOOD)
	var brass: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.BRASS)
	var frame: BoxMesh = BoxMesh.new()
	frame.size = Vector3(0.25, 1.6, 0.25)
	for x: float in [-1.0, 1.0]:
		Layers.add_mesh(self, frame, wood, Vector3(x, 0.8, 0.0))
	var base: BoxMesh = BoxMesh.new()
	base.size = Vector3(2.4, 0.2, 1.2)
	Layers.add_mesh(self, base, iron, Vector3(0.0, 0.1, 0.0))
	_drum = Node3D.new()
	_drum.position = Vector3(0.0, 1.3, 0.0)
	add_child(_drum)
	var drum: CylinderMesh = CylinderMesh.new()
	drum.top_radius = 0.45
	drum.bottom_radius = 0.45
	drum.height = 1.7
	var drum_instance: MeshInstance3D = Layers.add_mesh(_drum, drum, iron, Vector3.ZERO)
	drum_instance.rotation = Vector3(0.0, 0.0, PI * 0.5)
	var band: TorusMesh = TorusMesh.new()
	band.inner_radius = 0.44
	band.outer_radius = 0.52
	for x: float in [-0.5, 0.0, 0.5]:
		var band_instance: MeshInstance3D = Layers.add_mesh(_drum, band, brass, Vector3(x, 0.0, 0.0))
		band_instance.rotation = Vector3(0.0, 0.0, PI * 0.5)
	var handle: BoxMesh = BoxMesh.new()
	handle.size = Vector3(0.08, 0.9, 0.08)
	Layers.add_mesh(_drum, handle, brass, Vector3(1.0, 0.35, 0.0))
	_meter = Label3D.new()
	_meter.font_size = 48
	_meter.outline_size = 12
	_meter.modulate = Color(1.0, 0.85, 0.5)
	_meter.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_meter.no_depth_test = true
	_meter.position = Vector3(0.0, 2.6, 0.0)
	add_child(_meter)
	_update_meter()
	Layers.add_static_box(self, Vector3(2.4, 1.6, 1.2), Vector3(0.0, 0.8, 0.0))
