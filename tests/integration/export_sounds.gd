extends SceneTree
## Dev tool: writes every synthesized sound to WAV files so they can be auditioned outside the game,
## or used as reference when recording replacements for assets/audio/<id>.ogg|.wav.
##   Godot_console.exe --headless --path . --script res://tests/integration/export_sounds.gd -- <output_dir>
## Prints each sound's length and peak. Exits 1 if any sound is silent or clips.


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://sound_export"
	var dir_error: Error = DirAccess.make_dir_recursive_absolute(out_dir)
	assert(dir_error == OK, "export_sounds: cannot create %s" % out_dir)
	var library: SoundLibrary = SoundLibrary.new()
	var problems: int = 0
	for id: StringName in SoundRecipes.ids():
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = library.synth_seed + hash(String(id))
		var samples: PackedFloat32Array = SoundRecipes.build_samples(id, rng)
		var peak: float = Synth.peak(samples)
		var seconds: float = float(samples.size()) / float(Synth.SAMPLE_RATE)
		var path: String = out_dir.path_join("%s.wav" % id)
		var save_error: Error = Synth.to_wav(samples, bool(SoundRecipes.settings(id)["loop"])).save_to_wav(path)
		var ok: bool = save_error == OK and peak > 0.05 and peak <= 1.0
		if not ok:
			problems += 1
		var source: String = "override " + library.override_path(id) if library.override_path(id) != "" else "synth"
		print("%s %-18s %5.2fs  peak %.2f  (%s)" % ["ok " if ok else "BAD", id, seconds, peak, source])
	print("exported %d sounds to %s" % [SoundRecipes.ids().size(), ProjectSettings.globalize_path(out_dir)])
	quit(1 if problems > 0 else 0)
