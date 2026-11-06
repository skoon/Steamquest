extends TestCase

const OVERRIDE_DIR: String = "user://test_sound_overrides"


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(OVERRIDE_DIR)
	for file_name: String in DirAccess.get_files_at(OVERRIDE_DIR):
		DirAccess.remove_absolute(OVERRIDE_DIR.path_join(file_name))


func test_every_recipe_builds_a_normalized_sound() -> void:
	for id: StringName in SoundRecipes.ids():
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = 99
		var samples: PackedFloat32Array = SoundRecipes.build_samples(id, rng)
		assert_true(samples.size() > Synth.samples_for(0.05), "%s has audible length" % id)
		assert_almost(Synth.peak(samples), float(SoundRecipes.settings(id)["peak"]), "%s peak" % id, 0.001)


func test_recipe_settings_are_complete() -> void:
	for id: StringName in SoundRecipes.ids():
		var settings: Dictionary = SoundRecipes.settings(id)
		for key: String in ["volume_db", "bus", "loop", "peak"]:
			assert_true(settings.has(key), "%s missing %s" % [id, key])
		assert_true([SoundRecipes.BUS_SFX, SoundRecipes.BUS_AMBIENCE, SoundRecipes.BUS_UI].has(settings["bus"]), "%s on a known bus" % id)


func test_the_wrench_bong_is_the_loudest_hit() -> void:
	var bong: Dictionary = SoundRecipes.settings(&"wrench_bong")
	assert_true(float(bong["peak"]) >= 0.95, "BONG uses nearly full scale")
	for id: StringName in [&"wrench_clang", &"bruiser_step", &"rivet_ting", &"skitter_clack"]:
		assert_true(float(bong["volume_db"]) > float(SoundRecipes.settings(id)["volume_db"]), "BONG louder than %s" % id)


func test_loops_are_flagged_as_loops() -> void:
	var library: SoundLibrary = SoundLibrary.new(OVERRIDE_DIR)
	for id: StringName in [&"steam_vent_loop", &"furnace_loop", &"ambient_rumble"]:
		var wav: AudioStreamWAV = library.get_stream(id) as AudioStreamWAV
		assert_true(wav != null and wav.loop_mode == AudioStreamWAV.LOOP_FORWARD, "%s loops" % id)
	assert_eq((library.get_stream(&"wrench_bong") as AudioStreamWAV).loop_mode, AudioStreamWAV.LOOP_DISABLED, "one-shots don't loop")


func test_has_sound_knows_the_catalog() -> void:
	var library: SoundLibrary = SoundLibrary.new(OVERRIDE_DIR)
	assert_true(library.has_sound(&"wrench_bong"), "known id")
	assert_false(library.has_sound(&"kazoo"), "unknown id")


func test_streams_are_cached() -> void:
	var library: SoundLibrary = SoundLibrary.new(OVERRIDE_DIR)
	assert_true(library.get_stream(&"skitter_clack") == library.get_stream(&"skitter_clack"), "same stream instance reused")


func test_synthesis_is_deterministic_per_seed() -> void:
	var a: AudioStreamWAV = SoundRecipes.build_stream(&"enemy_death", 5)
	var b: AudioStreamWAV = SoundRecipes.build_stream(&"enemy_death", 5)
	assert_true(a.data == b.data, "same seed, same sound")


func test_override_file_replaces_the_synth() -> void:
	var replacement: AudioStreamWAV = Synth.to_wav(Synth.sine(500.0, 0.3), false)
	var path: String = OVERRIDE_DIR.path_join("wrench_bong.wav")
	assert_eq(replacement.save_to_wav(path), OK, "override written")
	var library: SoundLibrary = SoundLibrary.new(OVERRIDE_DIR)
	assert_eq(library.override_path(&"wrench_bong"), path, "override detected")
	assert_eq(library.override_path(&"wrench_clang"), "", "other sounds still synthesized")
	var stream: AudioStreamWAV = library.get_stream(&"wrench_bong") as AudioStreamWAV
	assert_true(stream != null, "override loaded")
	assert_almost(stream.get_length(), 0.3, "override's own length, not the 1.8 s synth", 0.02)


func test_looping_override_is_forced_to_loop() -> void:
	var replacement: AudioStreamWAV = Synth.to_wav(Synth.noise(0.5, RandomNumberGenerator.new()), false)
	assert_eq(replacement.save_to_wav(OVERRIDE_DIR.path_join("furnace_loop.wav")), OK, "override written")
	var stream: AudioStreamWAV = SoundLibrary.new(OVERRIDE_DIR).get_stream(&"furnace_loop") as AudioStreamWAV
	assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD, "ambient override loops")
	assert_true(stream.loop_end > 0, "loop covers the clip")
