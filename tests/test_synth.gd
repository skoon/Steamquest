extends TestCase


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


static func _rms(samples: PackedFloat32Array, from: int, to: int) -> float:
	var total: float = 0.0
	for i: int in range(from, to):
		total += samples[i] * samples[i]
	return sqrt(total / float(maxi(to - from, 1)))


## Signal power at one frequency (Goertzel algorithm).
static func _power_at(samples: PackedFloat32Array, freq: float) -> float:
	var coeff: float = 2.0 * cos(TAU * freq / float(Synth.SAMPLE_RATE))
	var s1: float = 0.0
	var s2: float = 0.0
	for value: float in samples:
		var s0: float = value + coeff * s1 - s2
		s2 = s1
		s1 = s0
	return s1 * s1 + s2 * s2 - coeff * s1 * s2


func test_sample_counts_match_duration() -> void:
	assert_eq(Synth.samples_for(1.0), Synth.SAMPLE_RATE, "one second")
	assert_eq(Synth.noise(0.5, _rng(1)).size(), Synth.SAMPLE_RATE / 2, "half a second of noise")
	assert_eq(Synth.sine(440.0, 0.25).size(), Synth.SAMPLE_RATE / 4, "quarter second of sine")
	assert_eq(Synth.silence(0.1).size(), Synth.samples_for(0.1), "silence length")


func test_noise_is_deterministic_per_seed() -> void:
	var a: PackedFloat32Array = Synth.noise(0.1, _rng(5))
	var b: PackedFloat32Array = Synth.noise(0.1, _rng(5))
	var c: PackedFloat32Array = Synth.noise(0.1, _rng(6))
	assert_true(a == b, "same seed, same noise")
	assert_false(a == c, "different seed, different noise")


func test_normalize_hits_target_peak() -> void:
	var loud: PackedFloat32Array = Synth.gain(Synth.sine(220.0, 0.2), 3.0)
	var normalized: PackedFloat32Array = Synth.normalize(loud, 0.8)
	assert_almost(Synth.peak(normalized), 0.8, "peak scaled to target", 0.001)


func test_normalize_leaves_silence_alone() -> void:
	var quiet: PackedFloat32Array = Synth.normalize(Synth.silence(0.1), 0.9)
	assert_almost(Synth.peak(quiet), 0.0, "silence stays silent")


func test_exponential_decay_fades_out() -> void:
	var tone: PackedFloat32Array = Synth.envelope_exp_decay(Synth.sine(330.0, 1.0), 0.005, 0.15)
	var early: float = _rms(tone, 0, Synth.samples_for(0.1))
	var late: float = _rms(tone, Synth.samples_for(0.8), tone.size())
	assert_true(late < early * 0.05, "late RMS well below early RMS")


func test_adsr_ends_silent() -> void:
	var shaped: PackedFloat32Array = Synth.envelope_adsr(Synth.sine(440.0, 0.5), 0.05, 0.05, 0.6, 0.1)
	assert_almost(absf(shaped[shaped.size() - 1]), 0.0, "release reaches zero", 0.01)
	assert_almost(absf(shaped[0]), 0.0, "attack starts at zero", 0.01)


func test_lowpass_attenuates_high_frequencies() -> void:
	var high: PackedFloat32Array = Synth.sine(6000.0, 0.3)
	var filtered: PackedFloat32Array = Synth.biquad(high, Synth.Filter.LOWPASS, 300.0, 0.7)
	assert_true(_rms(filtered, 1000, filtered.size()) < _rms(high, 1000, high.size()) * 0.05, "6 kHz removed by a 300 Hz lowpass")


func test_highpass_attenuates_low_frequencies() -> void:
	var low: PackedFloat32Array = Synth.sine(60.0, 0.5)
	var filtered: PackedFloat32Array = Synth.biquad(low, Synth.Filter.HIGHPASS, 2000.0, 0.7)
	assert_true(_rms(filtered, 2000, filtered.size()) < _rms(low, 2000, low.size()) * 0.05, "60 Hz removed by a 2 kHz highpass")


func test_bell_energy_peaks_at_its_base_frequency() -> void:
	var bell: PackedFloat32Array = Synth.inharmonic_bell(140.0, PackedFloat32Array([1.0, 2.09, 3.42]), PackedFloat32Array([1.0, 0.5, 0.3]), PackedFloat32Array([1.0, 0.5, 0.3]), 1.0)
	var at_base: float = _power_at(bell, 140.0)
	assert_true(at_base > _power_at(bell, 200.0) * 10.0, "base partial dominates nearby frequencies")
	assert_true(at_base > _power_at(bell, 140.0 * 2.09), "base partial louder than the second partial")


func test_bell_skips_partials_above_nyquist() -> void:
	var bell: PackedFloat32Array = Synth.inharmonic_bell(10000.0, PackedFloat32Array([1.0, 3.0]), PackedFloat32Array([0.2, 0.2]), PackedFloat32Array([1.0, 1.0]), 0.1)
	assert_true(Synth.peak(bell) <= 1.0 + 0.0001, "aliasing partial dropped")


func test_mix_at_offsets_and_grows() -> void:
	var base: PackedFloat32Array = Synth.silence(0.1)
	var blip: PackedFloat32Array = PackedFloat32Array([1.0, 1.0])
	var mixed: PackedFloat32Array = Synth.mix_at(base, blip, 0.1, 0.5)
	assert_eq(mixed.size(), base.size() + 2, "grows to fit the source")
	assert_almost(mixed[Synth.samples_for(0.1)], 0.5, "source lands at the offset at the given level")
	assert_eq(base.size(), Synth.samples_for(0.1), "input buffer untouched")


func test_crossfade_loop_is_seamless() -> void:
	var raw: PackedFloat32Array = Synth.biquad(Synth.noise(1.0, _rng(3)), Synth.Filter.LOWPASS, 200.0, 0.7)
	var fade: int = Synth.samples_for(0.2)
	var looped: PackedFloat32Array = Synth.crossfade_loop(raw, 0.2)
	assert_eq(looped.size(), raw.size() - fade, "tail folded into the head")
	# The loop wraps from its last sample to its first; that step must be as smooth as any other.
	var wrap_step: float = absf(looped[0] - looped[looped.size() - 1])
	var typical_step: float = 0.0
	for i: int in range(1, looped.size()):
		typical_step = maxf(typical_step, absf(looped[i] - looped[i - 1]))
	assert_true(wrap_step <= typical_step + 0.0001, "no click at the loop point")


func test_to_wav_encodes_16_bit_and_loops() -> void:
	var samples: PackedFloat32Array = PackedFloat32Array([0.0, 0.5, -0.5, 2.0])
	var wav: AudioStreamWAV = Synth.to_wav(samples, true)
	assert_eq(wav.format, AudioStreamWAV.FORMAT_16_BITS, "16-bit")
	assert_eq(wav.mix_rate, Synth.SAMPLE_RATE, "sample rate")
	assert_false(wav.stereo, "mono")
	assert_eq(wav.data.size(), samples.size() * 2, "two bytes per sample")
	assert_eq(wav.data.decode_s16(2), 16384, "0.5 encodes to half scale")
	assert_eq(wav.data.decode_s16(6), 32767, "over-range samples clamp")
	assert_eq(wav.loop_mode, AudioStreamWAV.LOOP_FORWARD, "loop enabled")
	assert_eq(wav.loop_end, samples.size(), "loops the whole buffer")
	assert_eq(Synth.to_wav(samples, false).loop_mode, AudioStreamWAV.LOOP_DISABLED, "one-shots don't loop")
