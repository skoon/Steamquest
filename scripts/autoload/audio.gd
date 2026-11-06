extends Node
## Global sound player (autoload `Audio`). Gameplay code calls play_at / play_ui / make_loop_player
## with a sound id; streams come from SoundLibrary (synthesized, or an override file in assets/audio).

signal sound_played(id: StringName)

const POOL_3D_SIZE: int = 24
const POOL_UI_SIZE: int = 6
## Full volume within this distance of the listener; fades with inverse distance beyond it.
const UNIT_SIZE: float = 9.0
const MAX_DISTANCE: float = 40.0
const LOOP_GROUP: StringName = &"audio_loops"
## Bus name -> volume (dB). Created at startup unless a bus layout already defines them.
const BUSES: Dictionary = {
	SoundRecipes.BUS_SFX: 0.0,
	SoundRecipes.BUS_AMBIENCE: -2.0,
	SoundRecipes.BUS_UI: -2.0,
}

var library: SoundLibrary = SoundLibrary.new()
var generation_msec: int = 0
var _pool_3d: Array[AudioStreamPlayer3D] = []
var _pool_ui: Array[AudioStreamPlayer] = []
var _next_3d: int = 0
var _next_ui: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _generation_task: int = -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	# Synthesis takes a moment, so it runs on a worker while the level loads; the first
	# request for a sound waits for it to finish.
	_generation_task = WorkerThreadPool.add_task(_generate_all, true, "Synthesize sounds")
	for i: int in POOL_3D_SIZE:
		var player: AudioStreamPlayer3D = _make_3d_player()
		add_child(player)
		_pool_3d.append(player)
	for i: int in POOL_UI_SIZE:
		var ui_player: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(ui_player)
		_pool_ui.append(ui_player)


func _process(_delta: float) -> void:
	if _generation_task != -1 and WorkerThreadPool.is_task_completed(_generation_task):
		_finish_generation()


func _notification(what: int) -> void:
	# Stop everything before the tree is torn down so no playback outlives its player.
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		stop_all()


func _exit_tree() -> void:
	_finish_generation()


func stop_all() -> void:
	for player: AudioStreamPlayer3D in _pool_3d:
		player.stop()
	for player: AudioStreamPlayer in _pool_ui:
		player.stop()
	if is_inside_tree():
		for node: Node in get_tree().get_nodes_in_group(LOOP_GROUP):
			node.call(&"stop")


## Blocks until every sound has been prepared. Safe to call repeatedly.
func wait_until_ready() -> void:
	_finish_generation()


func _generate_all() -> void:
	var started: int = Time.get_ticks_msec()
	library.preload_all()
	generation_msec = Time.get_ticks_msec() - started


func _finish_generation() -> void:
	if _generation_task == -1:
		return
	var error: Error = WorkerThreadPool.wait_for_task_completion(_generation_task)
	assert(error == OK, "Audio: sound generation task failed (%s)" % error_string(error))
	_generation_task = -1
	print_verbose("Audio: prepared %d sounds in %d ms" % [SoundRecipes.ids().size(), generation_msec])


## One-shot positional sound.
func play_at(id: StringName, position: Vector3, volume_db: float = 0.0, pitch_jitter: float = 0.06) -> void:
	wait_until_ready()
	var settings: Dictionary = SoundRecipes.settings(id)
	var player: AudioStreamPlayer3D = _take_3d_player()
	player.stream = library.get_stream(id)
	player.bus = settings["bus"]
	player.volume_db = float(settings["volume_db"]) + volume_db
	player.pitch_scale = 1.0 + _rng.randf_range(-pitch_jitter, pitch_jitter)
	player.global_position = position
	player.play()
	sound_played.emit(id)


## One-shot non-positional sound (menus, log terminal, pickups that should never fade).
func play_ui(id: StringName, volume_db: float = 0.0) -> void:
	wait_until_ready()
	var settings: Dictionary = SoundRecipes.settings(id)
	var player: AudioStreamPlayer = _pool_ui[_next_ui]
	_next_ui = (_next_ui + 1) % _pool_ui.size()
	player.stream = library.get_stream(id)
	player.bus = settings["bus"]
	player.volume_db = float(settings["volume_db"]) + volume_db
	player.play()
	sound_played.emit(id)


## Looping positional sound owned by `parent` (it pauses and frees with its owner).
func make_loop_player(id: StringName, parent: Node3D, volume_db: float = 0.0) -> AudioStreamPlayer3D:
	wait_until_ready()
	var settings: Dictionary = SoundRecipes.settings(id)
	assert(bool(settings["loop"]), "Audio.make_loop_player: %s is not a looping sound" % id)
	var player: AudioStreamPlayer3D = _make_3d_player()
	player.stream = library.get_stream(id)
	player.bus = settings["bus"]
	player.volume_db = float(settings["volume_db"]) + volume_db
	player.add_to_group(LOOP_GROUP)
	parent.add_child(player)
	# Start each loop at a different point so identical loops don't phase against each other.
	player.play(_rng.randf_range(0.0, maxf(player.stream.get_length() - 0.1, 0.0)))
	sound_played.emit(id)
	return player


func _make_3d_player() -> AudioStreamPlayer3D:
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	player.unit_size = UNIT_SIZE
	player.max_distance = MAX_DISTANCE
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	player.panning_strength = 0.7
	return player


## Reuses an idle player, or steals the oldest one when every player is busy.
func _take_3d_player() -> AudioStreamPlayer3D:
	for i: int in _pool_3d.size():
		var candidate: AudioStreamPlayer3D = _pool_3d[(_next_3d + i) % _pool_3d.size()]
		if not candidate.playing:
			_next_3d = (_next_3d + i + 1) % _pool_3d.size()
			return candidate
	var stolen: AudioStreamPlayer3D = _pool_3d[_next_3d]
	_next_3d = (_next_3d + 1) % _pool_3d.size()
	return stolen


func _ensure_buses() -> void:
	for bus_name: StringName in BUSES:
		if AudioServer.get_bus_index(bus_name) != -1:
			continue
		AudioServer.add_bus()
		var index: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, &"Master")
		AudioServer.set_bus_volume_db(index, BUSES[bus_name])
		if bus_name == SoundRecipes.BUS_SFX:
			var reverb: AudioEffectReverb = AudioEffectReverb.new()
			reverb.room_size = 0.55
			reverb.damping = 0.6
			reverb.wet = 0.12
			reverb.dry = 1.0
			AudioServer.add_bus_effect(index, reverb)
	var master: int = AudioServer.get_bus_index(&"Master")
	var has_limiter: bool = false
	for effect_index: int in AudioServer.get_bus_effect_count(master):
		if AudioServer.get_bus_effect(master, effect_index) is AudioEffectHardLimiter:
			has_limiter = true
	if not has_limiter:
		AudioServer.add_bus_effect(master, AudioEffectHardLimiter.new())
