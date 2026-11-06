class_name Synth
extends RefCounted
## Small deterministic sound synthesizer. Every function is pure: it takes or returns mono
## PackedFloat32Array buffers at SAMPLE_RATE and never touches the scene tree.

const SAMPLE_RATE: int = 32000

enum Filter { LOWPASS, HIGHPASS, BANDPASS }


static func samples_for(seconds: float) -> int:
	assert(seconds >= 0.0, "Synth.samples_for: seconds must be >= 0")
	return int(round(seconds * float(SAMPLE_RATE)))


static func silence(seconds: float) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(samples_for(seconds))
	out.fill(0.0)
	return out


static func noise(seconds: float, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(samples_for(seconds))
	for i: int in out.size():
		out[i] = rng.randf_range(-1.0, 1.0)
	return out


static func sine(freq: float, seconds: float) -> PackedFloat32Array:
	return sine_sweep(freq, freq, seconds)


## Sine whose frequency glides exponentially from f0 to f1.
static func sine_sweep(f0: float, f1: float, seconds: float) -> PackedFloat32Array:
	assert(f0 > 0.0 and f1 > 0.0, "Synth.sine_sweep: frequencies must be positive")
	var out: PackedFloat32Array = PackedFloat32Array()
	var count: int = samples_for(seconds)
	out.resize(count)
	var phase: float = 0.0
	var ratio: float = f1 / f0
	for i: int in count:
		var t: float = float(i) / float(maxi(count - 1, 1))
		var freq: float = f0 * pow(ratio, t)
		phase += TAU * freq / float(SAMPLE_RATE)
		out[i] = sin(phase)
	return out


## Band-limited-enough sawtooth (naive; fine for buzzy low tones).
static func saw_sweep(f0: float, f1: float, seconds: float) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	var count: int = samples_for(seconds)
	out.resize(count)
	var phase: float = 0.0
	for i: int in count:
		var t: float = float(i) / float(maxi(count - 1, 1))
		phase = fmod(phase + lerpf(f0, f1, t) / float(SAMPLE_RATE), 1.0)
		out[i] = phase * 2.0 - 1.0
	return out


## Sum of decaying sine partials at inharmonic ratios: bells, gongs, struck metal.
static func inharmonic_bell(base_hz: float, ratios: PackedFloat32Array, decays: PackedFloat32Array, amps: PackedFloat32Array, seconds: float) -> PackedFloat32Array:
	assert(ratios.size() == decays.size() and ratios.size() == amps.size(), "Synth.inharmonic_bell: partial arrays must match")
	var count: int = samples_for(seconds)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(count)
	out.fill(0.0)
	var nyquist: float = float(SAMPLE_RATE) * 0.5
	for p: int in ratios.size():
		var freq: float = base_hz * ratios[p]
		if freq >= nyquist:
			continue
		var step: float = TAU * freq / float(SAMPLE_RATE)
		var decay_per_sample: float = exp(-1.0 / (decays[p] * float(SAMPLE_RATE)))
		var level: float = amps[p]
		for i: int in count:
			out[i] += sin(step * float(i)) * level
			level *= decay_per_sample
	return out


## RBJ biquad filter.
static func biquad(samples: PackedFloat32Array, filter: Filter, freq: float, q: float) -> PackedFloat32Array:
	var w0: float = TAU * clampf(freq, 10.0, float(SAMPLE_RATE) * 0.49) / float(SAMPLE_RATE)
	var alpha: float = sin(w0) / (2.0 * q)
	var cos_w0: float = cos(w0)
	var b0: float
	var b1: float
	var b2: float
	match filter:
		Filter.LOWPASS:
			b0 = (1.0 - cos_w0) * 0.5
			b1 = 1.0 - cos_w0
			b2 = b0
		Filter.HIGHPASS:
			b0 = (1.0 + cos_w0) * 0.5
			b1 = -(1.0 + cos_w0)
			b2 = b0
		_:
			b0 = alpha
			b1 = 0.0
			b2 = -alpha
	var a0: float = 1.0 + alpha
	var a1: float = -2.0 * cos_w0
	var a2: float = 1.0 - alpha
	b0 /= a0
	b1 /= a0
	b2 /= a0
	a1 /= a0
	a2 /= a0
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(samples.size())
	var x1: float = 0.0
	var x2: float = 0.0
	var y1: float = 0.0
	var y2: float = 0.0
	for i: int in samples.size():
		var x0: float = samples[i]
		var y0: float = b0 * x0 + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
		out[i] = y0
		x2 = x1
		x1 = x0
		y2 = y1
		y1 = y0
	return out


## Linear attack, then exponential decay with time constant `decay` seconds.
static func envelope_exp_decay(samples: PackedFloat32Array, attack: float, decay: float) -> PackedFloat32Array:
	assert(decay > 0.0, "Synth.envelope_exp_decay: decay must be positive")
	var out: PackedFloat32Array = samples.duplicate()
	var attack_samples: int = maxi(samples_for(attack), 1)
	for i: int in out.size():
		var t: float = float(i) / float(SAMPLE_RATE)
		var gain: float = minf(float(i) / float(attack_samples), 1.0) * exp(-maxf(t - attack, 0.0) / decay)
		out[i] *= gain
	return out


## Attack / decay / sustain level / release, all in seconds; release ends at the buffer's end.
static func envelope_adsr(samples: PackedFloat32Array, attack: float, decay: float, sustain: float, release: float) -> PackedFloat32Array:
	var out: PackedFloat32Array = samples.duplicate()
	var total: float = float(out.size()) / float(SAMPLE_RATE)
	var release_start: float = maxf(total - release, 0.0)
	for i: int in out.size():
		var t: float = float(i) / float(SAMPLE_RATE)
		var gain: float
		if t < attack:
			gain = t / maxf(attack, 0.0001)
		elif t < attack + decay:
			gain = lerpf(1.0, sustain, (t - attack) / maxf(decay, 0.0001))
		else:
			gain = sustain
		if t >= release_start:
			gain *= clampf(1.0 - (t - release_start) / maxf(release, 0.0001), 0.0, 1.0)
		out[i] *= gain
	return out


## Multiplies two buffers sample by sample (amplitude modulation); result has a's length.
static func multiply(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var out: PackedFloat32Array = a.duplicate()
	for i: int in out.size():
		out[i] *= b[i] if i < b.size() else 0.0
	return out


static func gain(samples: PackedFloat32Array, amount: float) -> PackedFloat32Array:
	var out: PackedFloat32Array = samples.duplicate()
	for i: int in out.size():
		out[i] *= amount
	return out


## Adds `source` into a copy of `dest` starting `offset_seconds` in, growing dest if needed.
static func mix_at(dest: PackedFloat32Array, source: PackedFloat32Array, offset_seconds: float, level: float) -> PackedFloat32Array:
	var out: PackedFloat32Array = dest.duplicate()
	var offset: int = samples_for(offset_seconds)
	var needed: int = offset + source.size()
	if needed > out.size():
		var old_size: int = out.size()
		out.resize(needed)
		for i: int in range(old_size, needed):
			out[i] = 0.0
	for i: int in source.size():
		out[offset + i] += source[i] * level
	return out


static func peak(samples: PackedFloat32Array) -> float:
	var highest: float = 0.0
	for value: float in samples:
		highest = maxf(highest, absf(value))
	return highest


## Scales so the loudest sample hits `target_peak`. Silent buffers are returned unchanged.
static func normalize(samples: PackedFloat32Array, target_peak: float) -> PackedFloat32Array:
	assert(target_peak > 0.0 and target_peak <= 1.0, "Synth.normalize: peak must be in (0, 1]")
	var current: float = peak(samples)
	if current <= 0.0:
		return samples.duplicate()
	return gain(samples, target_peak / current)


## Makes a seamless loop: the tail is crossfaded into the head and then dropped,
## so the last sample flows into the first.
static func crossfade_loop(samples: PackedFloat32Array, fade_seconds: float) -> PackedFloat32Array:
	var fade: int = samples_for(fade_seconds)
	assert(fade > 0 and fade * 2 < samples.size(), "Synth.crossfade_loop: fade must be shorter than half the buffer")
	var body: int = samples.size() - fade
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(body)
	for i: int in body:
		out[i] = samples[i]
	for i: int in fade:
		var t: float = float(i) / float(fade)
		out[i] = samples[i] * t + samples[body + i] * (1.0 - t)
	return out


## 16-bit mono AudioStreamWAV; clamps to [-1, 1].
static func to_wav(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var data: PackedByteArray = PackedByteArray()
	data.resize(samples.size() * 2)
	for i: int in samples.size():
		data.encode_s16(i * 2, int(round(clampf(samples[i], -1.0, 1.0) * 32767.0)))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = samples.size()
	return stream
