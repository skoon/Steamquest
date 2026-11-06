class_name FoundryAmbience
extends Node3D
## Foundry background: a constant machinery rumble plus distant whistles and clanks from
## random directions around the Technician at irregular intervals.

@export var min_interval: float = 4.0
@export var max_interval: float = 12.0
@export var min_distance: float = 8.0
@export var max_distance: float = 15.0
@export var ambience_seed: int = 1871
@export var events: Array[StringName] = [&"distant_whistle", &"distant_clank", &"distant_clank"]

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _time_to_next: float = 0.0
var _rumble: AudioStreamPlayer


func _ready() -> void:
	assert(min_interval > 0.0 and max_interval >= min_interval, "FoundryAmbience: invalid interval range")
	assert(not events.is_empty(), "FoundryAmbience: no ambient events configured")
	_rng.seed = ambience_seed
	_time_to_next = _rng.randf_range(min_interval, max_interval)
	Audio.wait_until_ready()
	_rumble = AudioStreamPlayer.new()
	_rumble.stream = Audio.library.get_stream(&"ambient_rumble")
	_rumble.bus = SoundRecipes.settings(&"ambient_rumble")["bus"]
	_rumble.volume_db = SoundRecipes.settings(&"ambient_rumble")["volume_db"]
	_rumble.add_to_group(Audio.LOOP_GROUP)
	add_child(_rumble)
	_rumble.play()


func _process(delta: float) -> void:
	_time_to_next -= delta
	if _time_to_next > 0.0:
		return
	_time_to_next = _rng.randf_range(min_interval, max_interval)
	var player: Node3D = get_tree().get_first_node_in_group(&"player") as Node3D
	if player == null:
		return
	var angle: float = _rng.randf_range(0.0, TAU)
	var distance: float = _rng.randf_range(min_distance, max_distance)
	var spot: Vector3 = player.global_position + Vector3(cos(angle) * distance, 2.0, sin(angle) * distance)
	Audio.play_at(events[_rng.randi_range(0, events.size() - 1)], spot, 0.0, 0.15)
