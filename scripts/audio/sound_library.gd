class_name SoundLibrary
extends RefCounted
## Resolves sound ids to streams. A file named `<id>.ogg` or `<id>.wav` in `override_dir`
## replaces the synthesized version, so any sound can be swapped for a real recording.

const OVERRIDE_EXTENSIONS: PackedStringArray = ["ogg", "wav"]

var override_dir: String
var synth_seed: int
var _cache: Dictionary = {}


func _init(p_override_dir: String = "res://assets/audio", p_seed: int = 1337) -> void:
	override_dir = p_override_dir
	synth_seed = p_seed


func has_sound(id: StringName) -> bool:
	return SoundRecipes.has(id)


func get_stream(id: StringName) -> AudioStream:
	assert(SoundRecipes.has(id), "SoundLibrary: unknown sound id %s" % id)
	if _cache.has(id):
		return _cache[id] as AudioStream
	var stream: AudioStream = _load_override(id)
	if stream == null:
		stream = SoundRecipes.build_stream(id, synth_seed)
	_cache[id] = stream
	return stream


## Path of the override file used for `id`, or "" when the synthesized sound is used.
func override_path(id: StringName) -> String:
	for extension: String in OVERRIDE_EXTENSIONS:
		var path: String = override_dir.path_join("%s.%s" % [id, extension])
		if ResourceLoader.exists(path) or FileAccess.file_exists(path):
			return path
	return ""


func preload_all() -> void:
	for id: StringName in SoundRecipes.ids():
		get_stream(id)


func _load_override(id: StringName) -> AudioStream:
	var path: String = override_path(id)
	if path == "":
		return null
	var stream: AudioStream
	if ResourceLoader.exists(path):
		stream = load(path) as AudioStream
	elif path.get_extension() == "ogg":
		stream = AudioStreamOggVorbis.load_from_file(path)
	else:
		stream = AudioStreamWAV.load_from_file(path)
	assert(stream != null, "SoundLibrary: override %s exists but could not be loaded" % path)
	if bool(SoundRecipes.settings(id)["loop"]):
		_enable_loop(stream)
	return stream


static func _enable_loop(stream: AudioStream) -> void:
	var wav: AudioStreamWAV = stream as AudioStreamWAV
	if wav != null and wav.loop_mode == AudioStreamWAV.LOOP_DISABLED:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = wav.data.size() / (2 if wav.format == AudioStreamWAV.FORMAT_16_BITS else 1) / (2 if wav.stereo else 1)
	var ogg: AudioStreamOggVorbis = stream as AudioStreamOggVorbis
	if ogg != null:
		ogg.loop = true
