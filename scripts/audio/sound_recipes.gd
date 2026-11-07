class_name SoundRecipes
extends RefCounted
## One synthesized recipe per sound id. Tunables (length, level, bus, looping) live in SOUNDS;
## the recipe functions describe the sound's structure using Synth.

const BUS_SFX: StringName = &"SFX"
const BUS_AMBIENCE: StringName = &"Ambience"
const BUS_UI: StringName = &"UI"

## id -> { "volume_db": float, "bus": StringName, "loop": bool, "peak": float }
const SOUNDS: Dictionary = {
	&"wrench_bong": {"volume_db": 3.0, "bus": BUS_SFX, "loop": false, "peak": 0.97},
	&"wrench_clang": {"volume_db": 0.0, "bus": BUS_SFX, "loop": false, "peak": 0.8},
	&"wrench_whoosh": {"volume_db": -8.0, "bus": BUS_SFX, "loop": false, "peak": 0.5},
	&"rivet_fire": {"volume_db": -3.0, "bus": BUS_SFX, "loop": false, "peak": 0.75},
	&"rivet_ting": {"volume_db": -6.0, "bus": BUS_SFX, "loop": false, "peak": 0.5},
	&"dash_hiss": {"volume_db": -4.0, "bus": BUS_SFX, "loop": false, "peak": 0.6},
	&"vent_hiss": {"volume_db": -2.0, "bus": BUS_SFX, "loop": false, "peak": 0.65},
	&"vent_whistle": {"volume_db": -6.0, "bus": BUS_SFX, "loop": false, "peak": 0.5},
	&"player_hurt": {"volume_db": -2.0, "bus": BUS_SFX, "loop": false, "peak": 0.8},
	&"skitter_clack": {"volume_db": -9.0, "bus": BUS_SFX, "loop": false, "peak": 0.55},
	&"bruiser_step": {"volume_db": -3.0, "bus": BUS_SFX, "loop": false, "peak": 0.85},
	&"piston_hiss": {"volume_db": -10.0, "bus": BUS_SFX, "loop": false, "peak": 0.45},
	&"bruiser_slam": {"volume_db": 2.0, "bus": BUS_SFX, "loop": false, "peak": 0.98},
	&"turret_charge": {"volume_db": -6.0, "bus": BUS_SFX, "loop": false, "peak": 0.5},
	&"turret_zap": {"volume_db": -3.0, "bus": BUS_SFX, "loop": false, "peak": 0.75},
	&"enemy_death": {"volume_db": -2.0, "bus": BUS_SFX, "loop": false, "peak": 0.8},
	&"steam_vent_loop": {"volume_db": -16.0, "bus": BUS_AMBIENCE, "loop": true, "peak": 0.4},
	&"vent_warn_whistle": {"volume_db": -9.0, "bus": BUS_SFX, "loop": false, "peak": 0.45},
	&"vent_burst": {"volume_db": -4.0, "bus": BUS_SFX, "loop": false, "peak": 0.7},
	&"furnace_loop": {"volume_db": -12.0, "bus": BUS_AMBIENCE, "loop": true, "peak": 0.45},
	&"door_open": {"volume_db": 0.0, "bus": BUS_SFX, "loop": false, "peak": 0.85},
	&"valve_free": {"volume_db": -3.0, "bus": BUS_SFX, "loop": false, "peak": 0.7},
	&"terminal_clack": {"volume_db": -8.0, "bus": BUS_UI, "loop": false, "peak": 0.6},
	&"gear_pickup": {"volume_db": -5.0, "bus": BUS_SFX, "loop": false, "peak": 0.6},
	&"golden_gear": {"volume_db": -3.0, "bus": BUS_UI, "loop": false, "peak": 0.75},
	&"ambient_rumble": {"volume_db": -14.0, "bus": BUS_AMBIENCE, "loop": true, "peak": 0.5},
	&"distant_whistle": {"volume_db": -14.0, "bus": BUS_AMBIENCE, "loop": false, "peak": 0.5},
	&"distant_clank": {"volume_db": -12.0, "bus": BUS_AMBIENCE, "loop": false, "peak": 0.6},
	&"hound_step": {"volume_db": -11.0, "bus": BUS_SFX, "loop": false, "peak": 0.5},
	&"hound_lunge": {"volume_db": -4.0, "bus": BUS_SFX, "loop": false, "peak": 0.7},
	&"sentry_step": {"volume_db": -7.0, "bus": BUS_SFX, "loop": false, "peak": 0.7},
	&"sentry_shield": {"volume_db": -1.0, "bus": BUS_SFX, "loop": false, "peak": 0.8},
	&"sentry_thrust": {"volume_db": -4.0, "bus": BUS_SFX, "loop": false, "peak": 0.7},
	&"tram_bell": {"volume_db": -4.0, "bus": BUS_SFX, "loop": false, "peak": 0.7},
	&"tram_rush": {"volume_db": 0.0, "bus": BUS_SFX, "loop": false, "peak": 0.9},
	&"key_pickup": {"volume_db": -4.0, "bus": BUS_SFX, "loop": false, "peak": 0.65},
	&"lift_rise": {"volume_db": -4.0, "bus": BUS_UI, "loop": false, "peak": 0.7},
	&"water_slosh": {"volume_db": -6.0, "bus": BUS_SFX, "loop": false, "peak": 0.6},
	&"pump_clunk": {"volume_db": -2.0, "bus": BUS_SFX, "loop": false, "peak": 0.8},
	&"sequence_wrong": {"volume_db": -4.0, "bus": BUS_SFX, "loop": false, "peak": 0.7},
	&"warden_roar": {"volume_db": 0.0, "bus": BUS_SFX, "loop": false, "peak": 0.85},
	&"nest_pulse": {"volume_db": -5.0, "bus": BUS_SFX, "loop": false, "peak": 0.6},
	&"nest_break": {"volume_db": 0.0, "bus": BUS_SFX, "loop": false, "peak": 0.9},
	&"cart_rumble": {"volume_db": -3.0, "bus": BUS_SFX, "loop": false, "peak": 0.8},
	&"winch_crank": {"volume_db": -3.0, "bus": BUS_SFX, "loop": false, "peak": 0.75},
	&"lantern_light": {"volume_db": -6.0, "bus": BUS_SFX, "loop": false, "peak": 0.6},
	&"humid_hiss": {"volume_db": -10.0, "bus": BUS_SFX, "loop": false, "peak": 0.5},
	&"wind_gust": {"volume_db": -3.0, "bus": BUS_SFX, "loop": false, "peak": 0.75},
	&"wind_warning": {"volume_db": -8.0, "bus": BUS_SFX, "loop": false, "peak": 0.5},
	&"propeller_whirr": {"volume_db": -9.0, "bus": BUS_SFX, "loop": false, "peak": 0.5},
	&"drone_hum": {"volume_db": -12.0, "bus": BUS_SFX, "loop": false, "peak": 0.45},
	&"drone_zap": {"volume_db": -4.0, "bus": BUS_SFX, "loop": false, "peak": 0.7},
	&"alarm_bell": {"volume_db": -3.0, "bus": BUS_SFX, "loop": false, "peak": 0.75},
	&"plate_crackle": {"volume_db": -6.0, "bus": BUS_SFX, "loop": false, "peak": 0.6},
	&"switch_clunk": {"volume_db": -3.0, "bus": BUS_SFX, "loop": false, "peak": 0.8},
	&"coil_overload": {"volume_db": 0.0, "bus": BUS_SFX, "loop": false, "peak": 0.9},
	&"conveyor_rattle": {"volume_db": -10.0, "bus": BUS_SFX, "loop": false, "peak": 0.5},
	&"press_hiss": {"volume_db": -6.0, "bus": BUS_SFX, "loop": false, "peak": 0.55},
	&"press_slam": {"volume_db": 1.0, "bus": BUS_SFX, "loop": false, "peak": 0.95},
	&"governor_break": {"volume_db": -1.0, "bus": BUS_SFX, "loop": false, "peak": 0.85},
	&"workbench_repair": {"volume_db": -3.0, "bus": BUS_SFX, "loop": false, "peak": 0.75},
	&"relief_vent": {"volume_db": -2.0, "bus": BUS_SFX, "loop": false, "peak": 0.75},
	&"pressure_klaxon": {"volume_db": -5.0, "bus": BUS_SFX, "loop": false, "peak": 0.6},
	&"pipe_burst": {"volume_db": 0.0, "bus": BUS_SFX, "loop": false, "peak": 0.9},
	&"walker_stomp": {"volume_db": 3.0, "bus": BUS_SFX, "loop": false, "peak": 0.98},
	&"walker_breath": {"volume_db": -1.0, "bus": BUS_SFX, "loop": false, "peak": 0.8},
	&"walker_charge": {"volume_db": 0.0, "bus": BUS_SFX, "loop": false, "peak": 0.9},
}


static func ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in SOUNDS:
		out.append(id)
	return out


static func has(id: StringName) -> bool:
	return SOUNDS.has(id)


static func settings(id: StringName) -> Dictionary:
	assert(SOUNDS.has(id), "SoundRecipes: unknown sound id %s" % id)
	return SOUNDS[id]


## Synthesizes the sound's samples, normalized to its configured peak.
static func build_samples(id: StringName, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var raw: PackedFloat32Array = _raw(id, rng)
	return Synth.normalize(raw, float(settings(id)["peak"]))


static func build_stream(id: StringName, base_seed: int) -> AudioStreamWAV:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = base_seed + hash(String(id))
	return Synth.to_wav(build_samples(id, rng), bool(settings(id)["loop"]))


static func _raw(id: StringName, rng: RandomNumberGenerator) -> PackedFloat32Array:
	match id:
		&"wrench_bong": return _wrench_bong(rng)
		&"wrench_clang": return _wrench_clang(rng)
		&"wrench_whoosh": return _whoosh(rng)
		&"rivet_fire": return _rivet_fire(rng)
		&"rivet_ting": return _ting(1900.0)
		&"dash_hiss": return Synth.envelope_adsr(_hiss(0.5, rng, 2500.0, 9000.0), 0.01, 0.1, 0.5, 0.3)
		&"vent_hiss": return Synth.envelope_adsr(_hiss(1.2, rng, 1800.0, 8000.0), 0.02, 0.2, 0.7, 0.6)
		&"vent_whistle": return _whistle(1250.0, 1.0, 1.12, rng)
		&"player_hurt": return _player_hurt(rng)
		&"skitter_clack": return _skitter_clack(rng)
		&"bruiser_step": return _bruiser_step(rng)
		&"piston_hiss": return Synth.envelope_adsr(_hiss(0.35, rng, 2200.0, 9000.0), 0.005, 0.05, 0.6, 0.25)
		&"bruiser_slam": return _bruiser_slam(rng)
		&"turret_charge": return _turret_charge()
		&"turret_zap": return _turret_zap(rng)
		&"enemy_death": return _enemy_death(rng)
		&"steam_vent_loop": return _steam_loop(rng)
		&"vent_warn_whistle": return _whistle(1650.0, 0.6, 1.05, rng)
		&"vent_burst": return _vent_burst(rng)
		&"furnace_loop": return _furnace_loop(rng)
		&"door_open": return _door_open(rng)
		&"valve_free": return Synth.mix_at(_whistle(1900.0, 1.4, 1.25, rng), Synth.envelope_adsr(_hiss(1.6, rng, 1500.0, 8000.0), 0.05, 0.2, 0.6, 0.6), 0.0, 0.5)
		&"terminal_clack": return _terminal_clack(rng)
		&"gear_pickup": return _gear_pickup(rng)
		&"golden_gear": return _golden_chime()
		&"ambient_rumble": return _ambient_rumble(rng)
		&"distant_whistle": return Synth.biquad(_whistle(880.0, 1.4, 1.08, rng), Synth.Filter.LOWPASS, 2500.0, 0.7)
		&"distant_clank": return Synth.biquad(_clank(210.0, 0.45, rng), Synth.Filter.LOWPASS, 1800.0, 0.7)
		&"hound_step": return _hound_step(rng)
		&"hound_lunge": return _hound_lunge(rng)
		&"sentry_step": return Synth.mix_at(_clank(320.0, 0.12, rng), _thump(110.0, 60.0, 0.12, 0.04), 0.0, 0.8)
		&"sentry_shield": return _sentry_shield(rng)
		&"sentry_thrust": return Synth.mix_at(Synth.envelope_adsr(Synth.biquad(Synth.noise(0.22, rng), Synth.Filter.BANDPASS, 1700.0, 1.1), 0.03, 0.04, 0.6, 0.12), _click(rng, 3200.0), 0.12, 0.9)
		&"tram_bell": return _tram_bell()
		&"tram_rush": return _tram_rush(rng)
		&"key_pickup": return _key_pickup(rng)
		&"lift_rise": return _lift_rise(rng)
		&"water_slosh": return _water_slosh(rng)
		&"pump_clunk": return _pump_clunk(rng)
		&"sequence_wrong": return _sequence_wrong(rng)
		&"warden_roar": return _warden_roar(rng)
		&"nest_pulse": return _nest_pulse(rng)
		&"nest_break": return _nest_break(rng)
		&"cart_rumble": return _cart_rumble(rng)
		&"winch_crank": return _winch_crank(rng)
		&"lantern_light": return _lantern_light(rng)
		&"humid_hiss": return _humid_hiss(rng)
		&"wind_gust": return _wind_gust(rng)
		&"wind_warning": return _wind_warning()
		&"propeller_whirr": return _propeller_whirr(rng)
		&"drone_hum": return _drone_hum()
		&"drone_zap": return _drone_zap(rng)
		&"alarm_bell": return _alarm_bell()
		&"plate_crackle": return _plate_crackle(rng)
		&"switch_clunk": return _switch_clunk(rng)
		&"coil_overload": return _coil_overload(rng)
		&"conveyor_rattle": return _conveyor_rattle(rng)
		&"press_hiss": return Synth.envelope_adsr(_hiss(0.9, rng, 1600.0, 8000.0), 0.15, 0.1, 0.8, 0.3)
		&"press_slam": return _press_slam(rng)
		&"governor_break": return _governor_break(rng)
		&"workbench_repair": return _workbench_repair(rng)
		&"relief_vent": return _relief_vent(rng)
		&"pressure_klaxon": return _pressure_klaxon()
		&"pipe_burst": return _pipe_burst(rng)
		&"walker_stomp": return _walker_stomp(rng)
		&"walker_breath": return _walker_breath(rng)
		&"walker_charge": return _walker_charge(rng)
	assert(false, "SoundRecipes: no recipe for %s" % id)
	return PackedFloat32Array()


# --- Building blocks ------------------------------------------------------------------

static func _hiss(seconds: float, rng: RandomNumberGenerator, highpass: float, lowpass: float) -> PackedFloat32Array:
	var filtered: PackedFloat32Array = Synth.biquad(Synth.noise(seconds, rng), Synth.Filter.HIGHPASS, highpass, 0.7)
	return Synth.biquad(filtered, Synth.Filter.LOWPASS, lowpass, 0.7)


## Very short bright noise burst: the moment of impact.
static func _strike(rng: RandomNumberGenerator, freq: float) -> PackedFloat32Array:
	var burst: PackedFloat32Array = Synth.biquad(Synth.noise(0.03, rng), Synth.Filter.BANDPASS, freq, 1.2)
	return Synth.envelope_exp_decay(burst, 0.0005, 0.005)


static func _thump(f0: float, f1: float, seconds: float, decay: float) -> PackedFloat32Array:
	return Synth.envelope_exp_decay(Synth.sine_sweep(f0, f1, seconds), 0.002, decay)


static func _click(rng: RandomNumberGenerator, freq: float) -> PackedFloat32Array:
	var tick: PackedFloat32Array = Synth.envelope_exp_decay(Synth.biquad(Synth.noise(0.01, rng), Synth.Filter.BANDPASS, freq, 4.0), 0.0003, 0.0015)
	var ring: PackedFloat32Array = Synth.inharmonic_bell(freq * 0.8, PackedFloat32Array([1.0, 1.8]), PackedFloat32Array([0.02, 0.01]), PackedFloat32Array([0.4, 0.2]), 0.05)
	return Synth.mix_at(tick, ring, 0.0, 1.0)


static func _whistle(base: float, seconds: float, rise: float, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var tone: PackedFloat32Array = Synth.sine_sweep(base, base * rise, seconds)
	var overtone: PackedFloat32Array = Synth.sine_sweep(base * 2.0, base * rise * 2.0, seconds)
	var breath: PackedFloat32Array = Synth.biquad(Synth.noise(seconds, rng), Synth.Filter.BANDPASS, base, 6.0)
	var mixed: PackedFloat32Array = Synth.mix_at(Synth.mix_at(tone, overtone, 0.0, 0.15), breath, 0.0, 0.9)
	return Synth.envelope_adsr(mixed, 0.06, 0.1, 0.8, seconds * 0.3)


static func _clank(base: float, decay: float, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var ring: PackedFloat32Array = Synth.inharmonic_bell(base, PackedFloat32Array([1.0, 1.6, 2.4, 3.3]), PackedFloat32Array([decay, decay * 0.65, decay * 0.4, decay * 0.22]), PackedFloat32Array([1.0, 0.6, 0.4, 0.2]), decay * 2.2)
	return Synth.mix_at(ring, _strike(rng, base * 8.0), 0.0, 0.5)


static func _ting(base: float) -> PackedFloat32Array:
	return Synth.inharmonic_bell(base, PackedFloat32Array([1.0, 2.76, 5.4]), PackedFloat32Array([0.14, 0.07, 0.04]), PackedFloat32Array([1.0, 0.5, 0.3]), 0.35)


## Random-onset clicks over `seconds` at roughly `per_second` density.
static func _crackle(seconds: float, per_second: float, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out: PackedFloat32Array = Synth.silence(seconds)
	var count: int = int(seconds * per_second)
	for i: int in count:
		var at: float = rng.randf_range(0.0, maxf(seconds - 0.02, 0.0))
		var pop: PackedFloat32Array = Synth.envelope_exp_decay(Synth.biquad(Synth.noise(0.015, rng), Synth.Filter.LOWPASS, rng.randf_range(1500.0, 4000.0), 0.7), 0.0003, 0.003)
		out = Synth.mix_at(out, pop, at, rng.randf_range(0.3, 1.0))
	return out


# --- Recipes ------------------------------------------------------------------------------

static func _wrench_bong(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var ratios: PackedFloat32Array = PackedFloat32Array([1.0, 1.47, 2.09, 2.56, 3.42, 4.51, 5.9])
	var decays: PackedFloat32Array = PackedFloat32Array([1.6, 1.1, 0.8, 0.6, 0.4, 0.25, 0.15])
	var amps: PackedFloat32Array = PackedFloat32Array([1.0, 0.7, 0.55, 0.4, 0.3, 0.2, 0.12])
	var bell: PackedFloat32Array = Synth.inharmonic_bell(140.0, ratios, decays, amps, 1.8)
	# A slightly detuned twin makes the slow beating of a big struck pipe.
	bell = Synth.mix_at(bell, Synth.inharmonic_bell(141.3, ratios, decays, amps, 1.8), 0.0, 0.5)
	bell = Synth.mix_at(bell, _strike(rng, 2200.0), 0.0, 0.8)
	return Synth.mix_at(bell, _thump(110.0, 55.0, 0.3, 0.08), 0.0, 0.7)


static func _wrench_clang(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var ring: PackedFloat32Array = Synth.inharmonic_bell(430.0, PackedFloat32Array([1.0, 2.32, 3.1, 4.7]), PackedFloat32Array([0.35, 0.22, 0.15, 0.08]), PackedFloat32Array([1.0, 0.6, 0.4, 0.25]), 0.7)
	return Synth.mix_at(ring, _strike(rng, 3000.0), 0.0, 0.8)


static func _whoosh(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var air: PackedFloat32Array = Synth.biquad(Synth.noise(0.28, rng), Synth.Filter.BANDPASS, 900.0, 0.9)
	return Synth.envelope_adsr(air, 0.09, 0.05, 0.6, 0.14)


static func _rivet_fire(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var puff: PackedFloat32Array = Synth.envelope_exp_decay(_hiss(0.25, rng, 1500.0, 9000.0), 0.002, 0.04)
	puff = Synth.mix_at(puff, _thump(200.0, 60.0, 0.12, 0.04), 0.0, 0.8)
	return Synth.mix_at(puff, _click(rng, 2400.0), 0.0, 0.6)


static func _player_hurt(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var thud: PackedFloat32Array = _thump(140.0, 50.0, 0.35, 0.08)
	var body: PackedFloat32Array = Synth.envelope_exp_decay(Synth.biquad(Synth.noise(0.2, rng), Synth.Filter.LOWPASS, 500.0, 0.7), 0.001, 0.05)
	thud = Synth.mix_at(thud, body, 0.0, 0.6)
	var ring: PackedFloat32Array = Synth.inharmonic_bell(260.0, PackedFloat32Array([1.0, 2.4]), PackedFloat32Array([0.12, 0.07]), PackedFloat32Array([0.5, 0.3]), 0.3)
	return Synth.mix_at(thud, ring, 0.0, 0.4)


static func _skitter_clack(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out: PackedFloat32Array = Synth.silence(0.16)
	for at: float in [0.0, rng.randf_range(0.03, 0.05), rng.randf_range(0.08, 0.11)]:
		out = Synth.mix_at(out, _click(rng, rng.randf_range(2500.0, 4000.0)), at, rng.randf_range(0.6, 1.0))
	return out


static func _bruiser_step(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var ring: PackedFloat32Array = Synth.inharmonic_bell(170.0, PackedFloat32Array([1.0, 1.6, 2.5, 3.9]), PackedFloat32Array([0.3, 0.2, 0.12, 0.06]), PackedFloat32Array([1.0, 0.6, 0.4, 0.2]), 0.6)
	ring = Synth.mix_at(ring, _thump(80.0, 40.0, 0.25, 0.07), 0.0, 1.2)
	var scrape: PackedFloat32Array = Synth.envelope_exp_decay(Synth.biquad(Synth.noise(0.15, rng), Synth.Filter.LOWPASS, 300.0, 0.7), 0.001, 0.05)
	return Synth.mix_at(ring, scrape, 0.0, 0.6)


static func _bruiser_slam(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var boom: PackedFloat32Array = _thump(95.0, 28.0, 0.9, 0.35)
	boom = Synth.mix_at(boom, Synth.envelope_exp_decay(Synth.biquad(Synth.noise(0.8, rng), Synth.Filter.LOWPASS, 260.0, 0.7), 0.002, 0.3), 0.0, 0.9)
	boom = Synth.mix_at(boom, Synth.inharmonic_bell(92.0, PackedFloat32Array([1.0, 1.52, 2.3, 3.4]), PackedFloat32Array([0.9, 0.6, 0.4, 0.2]), PackedFloat32Array([0.7, 0.5, 0.35, 0.2]), 1.6), 0.0, 1.0)
	boom = Synth.mix_at(boom, _strike(rng, 1800.0), 0.0, 0.7)
	return Synth.mix_at(boom, Synth.envelope_adsr(_hiss(0.8, rng, 1800.0, 8000.0), 0.05, 0.1, 0.7, 0.5), 0.1, 0.25)


static func _turret_charge() -> PackedFloat32Array:
	var buzz: PackedFloat32Array = Synth.biquad(Synth.saw_sweep(70.0, 340.0, 0.85), Synth.Filter.LOWPASS, 1800.0, 0.8)
	var tremolo: PackedFloat32Array = Synth.sine(28.0, 0.85)
	for i: int in tremolo.size():
		tremolo[i] = 0.8 + 0.2 * tremolo[i]
	buzz = Synth.multiply(buzz, tremolo)
	buzz = Synth.mix_at(buzz, Synth.sine_sweep(400.0, 1600.0, 0.85), 0.0, 0.2)
	return Synth.envelope_adsr(buzz, 0.7, 0.05, 1.0, 0.1)


static func _turret_zap(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sizzle: PackedFloat32Array = Synth.biquad(Synth.noise(0.4, rng), Synth.Filter.HIGHPASS, 900.0, 0.7)
	var gate_length: int = Synth.samples_for(0.002)
	var open: bool = true
	for i: int in sizzle.size():
		if i % gate_length == 0:
			open = rng.randf() < 0.55
		if not open:
			sizzle[i] *= 0.1
	sizzle = Synth.mix_at(sizzle, Synth.saw_sweep(120.0, 90.0, 0.4), 0.0, 0.3)
	return Synth.envelope_exp_decay(sizzle, 0.001, 0.12)


static func _enemy_death(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out: PackedFloat32Array = _thump(120.0, 60.0, 0.25, 0.06)
	var level: float = 1.0
	for i: int in 7:
		var base: float = rng.randf_range(500.0, 2200.0)
		var decay: float = rng.randf_range(0.12, 0.25)
		var bit: PackedFloat32Array = Synth.inharmonic_bell(base, PackedFloat32Array([1.0, 2.7, 4.1]), PackedFloat32Array([decay, decay * 0.5, decay * 0.3]), PackedFloat32Array([1.0, 0.5, 0.3]), decay * 2.0)
		out = Synth.mix_at(out, bit, rng.randf_range(0.0, 0.6), level * 0.6)
		level *= 0.85
	return out


static func _steam_loop(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var hiss: PackedFloat32Array = _hiss(3.5, rng, 1200.0, 6000.0)
	var swell: PackedFloat32Array = Synth.sine(0.7, 3.5)
	for i: int in swell.size():
		swell[i] = 0.8 + 0.2 * swell[i]
	return Synth.crossfade_loop(Synth.multiply(hiss, swell), 0.5)


static func _vent_burst(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var roar: PackedFloat32Array = Synth.biquad(Synth.noise(1.5, rng), Synth.Filter.BANDPASS, 1400.0, 0.5)
	roar = Synth.mix_at(roar, _hiss(1.5, rng, 3000.0, 10000.0), 0.0, 0.5)
	return Synth.envelope_adsr(roar, 0.04, 0.2, 0.75, 0.5)


static func _furnace_loop(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var roar: PackedFloat32Array = Synth.biquad(Synth.noise(4.0, rng), Synth.Filter.LOWPASS, 220.0, 0.7)
	roar = Synth.mix_at(roar, _crackle(4.0, 18.0, rng), 0.0, 0.3)
	return Synth.crossfade_loop(roar, 0.5)


static func _door_open(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out: PackedFloat32Array = _clank(120.0, 0.3, rng)
	out = Synth.mix_at(out, Synth.envelope_adsr(_hiss(1.3, rng, 1500.0, 7000.0), 0.05, 0.2, 0.6, 0.5), 0.05, 0.6)
	return Synth.mix_at(out, _clank(100.0, 0.3, rng), 1.25, 0.9)


static func _terminal_clack(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out: PackedFloat32Array = Synth.silence(0.65)
	for at: float in [0.0, 0.07, 0.15, 0.21, 0.3, 0.38]:
		out = Synth.mix_at(out, _click(rng, rng.randf_range(1800.0, 2600.0)), at, 1.0)
		out = Synth.mix_at(out, _thump(420.0, 300.0, 0.03, 0.008), at, 0.4)
	var ding: PackedFloat32Array = Synth.inharmonic_bell(2600.0, PackedFloat32Array([1.0, 2.1]), PackedFloat32Array([0.25, 0.1]), PackedFloat32Array([0.6, 0.2]), 0.5)
	return Synth.mix_at(out, ding, 0.45, 0.6)


static func _gear_pickup(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out: PackedFloat32Array = Synth.silence(0.5)
	for i: int in 8:
		out = Synth.mix_at(out, _click(rng, 3000.0), 0.03 * float(i), 0.8)
	var chime: PackedFloat32Array = Synth.inharmonic_bell(1320.0, PackedFloat32Array([1.0, 2.0, 3.0]), PackedFloat32Array([0.3, 0.15, 0.08]), PackedFloat32Array([0.6, 0.3, 0.15]), 0.5)
	return Synth.mix_at(out, chime, 0.26, 1.0)


static func _golden_chime() -> PackedFloat32Array:
	var out: PackedFloat32Array = Synth.inharmonic_bell(660.0, PackedFloat32Array([1.0, 2.0, 3.0, 4.2, 5.4]), PackedFloat32Array([1.6, 1.1, 0.7, 0.4, 0.25]), PackedFloat32Array([1.0, 0.5, 0.3, 0.2, 0.1]), 2.4)
	out = Synth.mix_at(out, Synth.inharmonic_bell(990.0, PackedFloat32Array([1.0, 2.0, 3.0]), PackedFloat32Array([1.4, 0.9, 0.5]), PackedFloat32Array([0.6, 0.3, 0.15]), 2.2), 0.12, 1.0)
	return Synth.mix_at(out, Synth.inharmonic_bell(1320.0, PackedFloat32Array([1.0, 2.0]), PackedFloat32Array([1.2, 0.6]), PackedFloat32Array([0.5, 0.2]), 2.0), 0.24, 1.0)


static func _ambient_rumble(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var rumble: PackedFloat32Array = Synth.biquad(Synth.noise(7.0, rng), Synth.Filter.LOWPASS, 90.0, 0.7)
	rumble = Synth.mix_at(rumble, Synth.sine(48.0, 7.0), 0.0, 0.08)
	var swell: PackedFloat32Array = Synth.sine(0.3, 7.0)
	for i: int in swell.size():
		swell[i] = 0.85 + 0.15 * swell[i]
	return Synth.crossfade_loop(Synth.multiply(rumble, swell), 1.0)


# --- Campaign act I ---------------------------------------------------------------------------

static func _hound_step(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out: PackedFloat32Array = Synth.silence(0.12)
	for at: float in [0.0, rng.randf_range(0.04, 0.06)]:
		out = Synth.mix_at(out, _click(rng, rng.randf_range(1600.0, 2400.0)), at, rng.randf_range(0.7, 1.0))
	return Synth.mix_at(out, _ting(rng.randf_range(2600.0, 3000.0)), 0.0, 0.15)


## A ratcheting mechanical snarl as the hound springs.
static func _hound_lunge(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var growl: PackedFloat32Array = Synth.envelope_adsr(Synth.biquad(Synth.saw_sweep(90.0, 170.0, 0.35), Synth.Filter.LOWPASS, 900.0, 1.2), 0.02, 0.05, 0.8, 0.12)
	for i: int in 9:
		growl = Synth.mix_at(growl, _click(rng, 2200.0 + 120.0 * float(i)), 0.03 * float(i), 0.5)
	return Synth.mix_at(growl, _hiss(0.2, rng, 2500.0, 8000.0), 0.15, 0.25)


## Short, bright and dry: clearly a deflection, not the wrench BONG.
static func _sentry_shield(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var ring: PackedFloat32Array = Synth.inharmonic_bell(920.0, PackedFloat32Array([1.0, 2.13, 3.37, 5.1]), PackedFloat32Array([0.12, 0.08, 0.05, 0.03]), PackedFloat32Array([1.0, 0.6, 0.45, 0.25]), 0.35)
	ring = Synth.mix_at(ring, _strike(rng, 4500.0), 0.0, 1.0)
	return Synth.mix_at(ring, _ting(2400.0), 0.02, 0.3)


static func _tram_bell() -> PackedFloat32Array:
	var out: PackedFloat32Array = Synth.silence(1.0)
	for at: float in [0.0, 0.25, 0.5]:
		var ding: PackedFloat32Array = Synth.inharmonic_bell(1050.0, PackedFloat32Array([1.0, 2.0, 2.76, 4.1]), PackedFloat32Array([0.4, 0.25, 0.15, 0.08]), PackedFloat32Array([1.0, 0.4, 0.35, 0.15]), 0.5)
		out = Synth.mix_at(out, ding, at, 1.0)
	return out


static func _tram_rush(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var roar: PackedFloat32Array = Synth.envelope_adsr(Synth.biquad(Synth.noise(1.6, rng), Synth.Filter.LOWPASS, 600.0, 0.7), 0.15, 0.2, 0.85, 0.6)
	roar = Synth.mix_at(roar, Synth.envelope_adsr(Synth.sine_sweep(70.0, 55.0, 1.6), 0.15, 0.2, 0.8, 0.6), 0.0, 0.6)
	roar = Synth.mix_at(roar, Synth.envelope_adsr(_hiss(1.4, rng, 2000.0, 9000.0), 0.1, 0.2, 0.6, 0.5), 0.1, 0.35)
	var clatter: PackedFloat32Array = Synth.silence(1.6)
	for i: int in 12:
		var at: float = 0.1 + 0.11 * float(i)
		clatter = Synth.mix_at(clatter, _clank(rng.randf_range(260.0, 340.0), 0.05, rng), at, 0.5)
		clatter = Synth.mix_at(clatter, _clank(rng.randf_range(260.0, 340.0), 0.05, rng), at + 0.04, 0.35)
	return Synth.mix_at(roar, clatter, 0.0, 0.7)


static func _key_pickup(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out: PackedFloat32Array = Synth.silence(0.9)
	for i: int in 10:
		out = Synth.mix_at(out, _click(rng, 1800.0 + 150.0 * float(i)), 0.035 * float(i), 0.7)
	var chime: PackedFloat32Array = Synth.inharmonic_bell(880.0, PackedFloat32Array([1.0, 2.0, 3.0]), PackedFloat32Array([0.5, 0.3, 0.15]), PackedFloat32Array([0.7, 0.35, 0.15]), 0.6)
	out = Synth.mix_at(out, chime, 0.36, 1.0)
	return Synth.mix_at(out, Synth.inharmonic_bell(1320.0, PackedFloat32Array([1.0, 2.0]), PackedFloat32Array([0.4, 0.2]), PackedFloat32Array([0.5, 0.2]), 0.5), 0.44, 1.0)


static func _lift_rise(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var motor: PackedFloat32Array = Synth.envelope_adsr(Synth.biquad(Synth.saw_sweep(70.0, 190.0, 1.6), Synth.Filter.LOWPASS, 1200.0, 0.9), 0.2, 0.2, 0.8, 0.5)
	var chain: PackedFloat32Array = Synth.silence(1.6)
	for i: int in 16:
		chain = Synth.mix_at(chain, _click(rng, rng.randf_range(1500.0, 2300.0)), 0.1 * float(i), 0.6)
	motor = Synth.mix_at(motor, chain, 0.0, 0.7)
	motor = Synth.mix_at(motor, _clank(140.0, 0.3, rng), 0.0, 0.8)
	return Synth.mix_at(motor, Synth.envelope_adsr(_hiss(1.0, rng, 1500.0, 7000.0), 0.05, 0.2, 0.5, 0.4), 0.2, 0.4)


# --- Campaign batch 2 -------------------------------------------------------------------------

## Water swelling over a stone kerb: filtered noise with a slow swell and a few gulps.
static func _water_slosh(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var swell: PackedFloat32Array = Synth.envelope_adsr(Synth.biquad(Synth.noise(1.4, rng), Synth.Filter.LOWPASS, 700.0, 0.8), 0.4, 0.3, 0.6, 0.6)
	for i: int in 5:
		var gulp: PackedFloat32Array = _thump(rng.randf_range(180.0, 260.0), rng.randf_range(90.0, 130.0), 0.12, 0.05)
		swell = Synth.mix_at(swell, gulp, 0.2 + 0.22 * float(i), 0.35)
	return swell


## A heavy piston engaging, then a wet chug.
static func _pump_clunk(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out: PackedFloat32Array = _clank(150.0, 0.25, rng)
	out = Synth.mix_at(out, _thump(110.0, 55.0, 0.3, 0.12), 0.0, 0.9)
	for i: int in 3:
		out = Synth.mix_at(out, Synth.envelope_exp_decay(Synth.biquad(Synth.noise(0.2, rng), Synth.Filter.BANDPASS, 400.0, 1.5), 0.01, 0.06), 0.25 + 0.18 * float(i), 0.5)
	return out


## Two falling buzzer tones: clearly "no".
static func _sequence_wrong(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out: PackedFloat32Array = Synth.silence(0.8)
	for i: int in 2:
		var buzz: PackedFloat32Array = Synth.biquad(Synth.saw_sweep(220.0 - 60.0 * float(i), 200.0 - 60.0 * float(i), 0.28), Synth.Filter.LOWPASS, 1400.0, 1.0)
		out = Synth.mix_at(out, Synth.envelope_adsr(buzz, 0.01, 0.05, 0.85, 0.06), 0.32 * float(i), 1.0)
	return Synth.mix_at(out, _hiss(0.5, rng, 1500.0, 6000.0), 0.3, 0.15)


## A diving-bell automaton bellowing through a brass helmet.
static func _warden_roar(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var roar: PackedFloat32Array = Synth.biquad(Synth.saw_sweep(70.0, 48.0, 1.3), Synth.Filter.BANDPASS, 380.0, 1.6)
	roar = Synth.envelope_adsr(roar, 0.08, 0.2, 0.8, 0.5)
	roar = Synth.mix_at(roar, Synth.envelope_adsr(_hiss(1.1, rng, 600.0, 3000.0), 0.1, 0.2, 0.6, 0.4), 0.05, 0.5)
	return Synth.mix_at(roar, _clank(95.0, 0.4, rng), 0.0, 0.5)


## The nest's core throbbing as it spits out a new automaton.
static func _nest_pulse(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out: PackedFloat32Array = _thump(140.0, 70.0, 0.35, 0.12)
	out = Synth.mix_at(out, _thump(140.0, 70.0, 0.35, 0.12), 0.18, 0.7)
	for i: int in 6:
		out = Synth.mix_at(out, _click(rng, rng.randf_range(1400.0, 2600.0)), 0.3 + 0.04 * float(i), 0.5)
	return out


## Scrap heap collapsing: metal clatter on a low crunch.
static func _nest_break(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out: PackedFloat32Array = _thump(120.0, 40.0, 0.6, 0.2)
	out = Synth.mix_at(out, Synth.envelope_exp_decay(Synth.biquad(Synth.noise(0.6, rng), Synth.Filter.LOWPASS, 1800.0, 0.7), 0.002, 0.15), 0.0, 0.8)
	for i: int in 10:
		out = Synth.mix_at(out, _clank(rng.randf_range(300.0, 900.0), 0.06, rng), rng.randf_range(0.02, 0.7), rng.randf_range(0.25, 0.55))
	return out


## Iron wheels grinding down the rails toward you.
static func _cart_rumble(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var rumble: PackedFloat32Array = Synth.envelope_adsr(Synth.biquad(Synth.noise(1.4, rng), Synth.Filter.LOWPASS, 260.0, 0.9), 0.6, 0.2, 0.9, 0.2)
	var squeal: PackedFloat32Array = Synth.envelope_adsr(Synth.biquad(Synth.noise(1.4, rng), Synth.Filter.BANDPASS, 3200.0, 8.0), 0.8, 0.1, 0.7, 0.2)
	rumble = Synth.mix_at(rumble, squeal, 0.0, 0.25)
	for i: int in 8:
		rumble = Synth.mix_at(rumble, _clank(rng.randf_range(200.0, 260.0), 0.04, rng), 0.3 + 0.13 * float(i), 0.25 + 0.05 * float(i))
	return rumble


## Ratchet pawl clicking round a cable drum.
static func _winch_crank(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out: PackedFloat32Array = Synth.envelope_adsr(Synth.biquad(Synth.saw_sweep(55.0, 60.0, 1.2), Synth.Filter.LOWPASS, 500.0, 0.8), 0.1, 0.1, 0.7, 0.3)
	for i: int in 12:
		out = Synth.mix_at(out, _click(rng, 1300.0 + rng.randf_range(-100.0, 100.0)), 0.09 * float(i), 0.75)
	return Synth.mix_at(out, _clank(180.0, 0.15, rng), 0.0, 0.5)


## Flint strike and a soft whump of flame.
static func _lantern_light(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out: PackedFloat32Array = _strike(rng, 5000.0)
	out = Synth.mix_at(out, _strike(rng, 4200.0), 0.07, 0.8)
	var whump: PackedFloat32Array = Synth.envelope_adsr(Synth.biquad(Synth.noise(0.5, rng), Synth.Filter.LOWPASS, 900.0, 0.7), 0.04, 0.1, 0.5, 0.25)
	return Synth.mix_at(out, whump, 0.1, 0.8)


static func _humid_hiss(rng: RandomNumberGenerator) -> PackedFloat32Array:
	return Synth.envelope_adsr(_hiss(1.2, rng, 1800.0, 7000.0), 0.3, 0.2, 0.6, 0.5)


# --- Batch 3: tower, archive, generator ------------------------------------------------------

## A rising and falling rush of air.
static func _wind_gust(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var air: PackedFloat32Array = Synth.biquad(Synth.noise(2.2, rng), Synth.Filter.BANDPASS, 700.0, 0.6)
	air = Synth.mix_at(air, Synth.biquad(Synth.noise(2.2, rng), Synth.Filter.LOWPASS, 250.0, 0.7), 0.0, 0.8)
	return Synth.envelope_adsr(air, 0.7, 0.3, 0.8, 0.9)


## Two-note whistle off the windsock mast.
static func _wind_warning() -> PackedFloat32Array:
	var out: PackedFloat32Array = Synth.envelope_adsr(Synth.sine_sweep(900.0, 1300.0, 0.5), 0.05, 0.1, 0.8, 0.15)
	return Synth.mix_at(out, Synth.envelope_adsr(Synth.sine_sweep(1300.0, 1000.0, 0.5), 0.05, 0.1, 0.8, 0.2), 0.55, 0.9)


## Blade chop: noise pulsed at the blade-pass rate over a low drone.
static func _propeller_whirr(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var air: PackedFloat32Array = Synth.biquad(Synth.noise(2.0, rng), Synth.Filter.LOWPASS, 900.0, 0.7)
	var chop: PackedFloat32Array = Synth.sine(18.0, 2.0)
	for i: int in chop.size():
		chop[i] = 0.35 + 0.65 * maxf(chop[i], 0.0)
	air = Synth.multiply(air, chop)
	air = Synth.mix_at(air, Synth.biquad(Synth.saw_sweep(60.0, 62.0, 2.0), Synth.Filter.LOWPASS, 300.0, 0.7), 0.0, 0.4)
	return Synth.envelope_adsr(air, 0.2, 0.1, 0.9, 0.3)


## Warbling coil hum.
static func _drone_hum() -> PackedFloat32Array:
	var hum: PackedFloat32Array = Synth.biquad(Synth.saw_sweep(110.0, 116.0, 1.4), Synth.Filter.LOWPASS, 700.0, 1.0)
	var wobble: PackedFloat32Array = Synth.sine(7.0, 1.4)
	for i: int in wobble.size():
		wobble[i] = 0.75 + 0.25 * wobble[i]
	hum = Synth.multiply(hum, wobble)
	return Synth.envelope_adsr(hum, 0.3, 0.1, 0.9, 0.4)


## A short, bright arc crack with a falling tail.
static func _drone_zap(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var crack: PackedFloat32Array = Synth.biquad(Synth.noise(0.3, rng), Synth.Filter.HIGHPASS, 1500.0, 0.7)
	crack = Synth.mix_at(crack, Synth.sine_sweep(1800.0, 300.0, 0.3), 0.0, 0.5)
	return Synth.envelope_exp_decay(crack, 0.001, 0.08)


## A hand bell rung hard three times: inharmonic partials with a long ring.
static func _alarm_bell() -> PackedFloat32Array:
	var out: PackedFloat32Array = Synth.silence(2.0)
	for strike: int in 3:
		var tone: PackedFloat32Array = Synth.sine(1250.0, 1.2)
		tone = Synth.mix_at(tone, Synth.sine(2710.0, 1.2), 0.0, 0.5)
		tone = Synth.mix_at(tone, Synth.sine(3900.0, 1.2), 0.0, 0.25)
		out = Synth.mix_at(out, Synth.envelope_exp_decay(tone, 0.002, 0.35), 0.28 * float(strike), 0.8)
	return out


## Spitting electrical crackle: gated noise bursts.
static func _plate_crackle(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sizzle: PackedFloat32Array = Synth.biquad(Synth.noise(0.7, rng), Synth.Filter.BANDPASS, 3000.0, 0.8)
	var gate_length: int = Synth.samples_for(0.004)
	var open: bool = true
	for i: int in sizzle.size():
		if i % gate_length == 0:
			open = rng.randf() < 0.35
		if not open:
			sizzle[i] *= 0.05
	sizzle = Synth.mix_at(sizzle, Synth.biquad(Synth.saw_sweep(100.0, 100.0, 0.7), Synth.Filter.LOWPASS, 400.0, 0.7), 0.0, 0.25)
	return Synth.envelope_adsr(sizzle, 0.01, 0.1, 0.8, 0.3)


## A heavy knife switch thrown home.
static func _switch_clunk(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out: PackedFloat32Array = _clank(220.0, 0.12, rng)
	out = Synth.mix_at(out, _click(rng, 2400.0), 0.0, 0.8)
	return Synth.mix_at(out, _clank(140.0, 0.2, rng), 0.05, 0.7)


## A coil dumping its charge: rising whine, then a big crack and sizzle.
static func _coil_overload(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var whine: PackedFloat32Array = Synth.envelope_adsr(Synth.sine_sweep(300.0, 2400.0, 0.35), 0.3, 0.0, 1.0, 0.05)
	var out: PackedFloat32Array = Synth.mix_at(Synth.silence(1.6), whine, 0.0, 0.4)
	var crack: PackedFloat32Array = Synth.envelope_exp_decay(Synth.biquad(Synth.noise(1.2, rng), Synth.Filter.HIGHPASS, 600.0, 0.7), 0.001, 0.25)
	out = Synth.mix_at(out, crack, 0.35, 1.0)
	return Synth.mix_at(out, Synth.envelope_exp_decay(Synth.biquad(Synth.noise(0.6, rng), Synth.Filter.LOWPASS, 200.0, 0.7), 0.001, 0.2), 0.35, 0.8)


## Belt rollers clattering past: an even run of light clanks over a low motor drone.
static func _conveyor_rattle(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out: PackedFloat32Array = Synth.envelope_adsr(Synth.biquad(Synth.saw_sweep(48.0, 48.0, 1.2), Synth.Filter.LOWPASS, 220.0, 0.7), 0.1, 0.1, 0.8, 0.3)
	for i: int in 10:
		out = Synth.mix_at(out, _clank(rng.randf_range(420.0, 520.0), 0.04, rng), 0.05 + 0.11 * float(i), 0.3)
	return out


## The die coming down: a crushing boom with a sheet-metal crunch.
static func _press_slam(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out: PackedFloat32Array = _thump(110.0, 35.0, 0.7, 0.25)
	out = Synth.mix_at(out, Synth.envelope_exp_decay(Synth.biquad(Synth.noise(0.5, rng), Synth.Filter.LOWPASS, 900.0, 0.7), 0.001, 0.12), 0.0, 0.8)
	out = Synth.mix_at(out, _clank(180.0, 0.3, rng), 0.0, 0.6)
	return Synth.mix_at(out, Synth.envelope_adsr(_hiss(0.6, rng, 2000.0, 8000.0), 0.02, 0.1, 0.5, 0.3), 0.08, 0.4)


## A spinning governor flying apart: a high ping, falling clatter and a dying whirr.
static func _governor_break(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out: PackedFloat32Array = _clank(700.0, 0.25, rng)
	out = Synth.mix_at(out, Synth.envelope_exp_decay(Synth.sine_sweep(900.0, 120.0, 1.0), 0.002, 0.4), 0.0, 0.4)
	for i: int in 8:
		out = Synth.mix_at(out, _clank(rng.randf_range(400.0, 1100.0), 0.05, rng), rng.randf_range(0.05, 0.8), rng.randf_range(0.25, 0.5))
	return out


## Grinder whine, a few hammer taps and a bright ring as the gear goes back in.
static func _workbench_repair(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var grind: PackedFloat32Array = Synth.biquad(Synth.noise(0.8, rng), Synth.Filter.BANDPASS, 3500.0, 3.0)
	var out: PackedFloat32Array = Synth.mix_at(Synth.silence(1.8), Synth.envelope_adsr(grind, 0.1, 0.1, 0.8, 0.2), 0.0, 0.5)
	for i: int in 3:
		out = Synth.mix_at(out, _clank(rng.randf_range(600.0, 700.0), 0.08, rng), 0.85 + 0.18 * float(i), 0.6)
	var ring: PackedFloat32Array = Synth.inharmonic_bell(1040.0, PackedFloat32Array([1.0, 2.0, 3.0]), PackedFloat32Array([0.5, 0.3, 0.15]), PackedFloat32Array([0.6, 0.3, 0.15]), 0.7)
	return Synth.mix_at(out, ring, 1.45, 0.8)


## A relief stack venting: a hard roar that thins into a whistle.
static func _relief_vent(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var roar: PackedFloat32Array = Synth.envelope_adsr(Synth.biquad(Synth.noise(1.8, rng), Synth.Filter.BANDPASS, 900.0, 0.5), 0.02, 0.3, 0.6, 0.9)
	return Synth.mix_at(roar, _whistle(1400.0, 1.4, 0.85, rng), 0.3, 0.4)


## Two-tone pressure klaxon.
static func _pressure_klaxon() -> PackedFloat32Array:
	var out: PackedFloat32Array = Synth.silence(1.4)
	for i: int in 2:
		var horn: PackedFloat32Array = Synth.biquad(Synth.saw_sweep(440.0 if i == 0 else 370.0, 440.0 if i == 0 else 370.0, 0.6), Synth.Filter.LOWPASS, 1800.0, 1.2)
		out = Synth.mix_at(out, Synth.envelope_adsr(horn, 0.03, 0.05, 0.9, 0.08), 0.65 * float(i), 0.8)
	return out


## A pipe seam giving way: a bang, then a howling jet.
static func _pipe_burst(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out: PackedFloat32Array = _thump(150.0, 50.0, 0.4, 0.12)
	out = Synth.mix_at(out, _clank(260.0, 0.2, rng), 0.0, 0.7)
	var jet: PackedFloat32Array = Synth.mix_at(Synth.biquad(Synth.noise(1.6, rng), Synth.Filter.BANDPASS, 1600.0, 0.6), _hiss(1.6, rng, 3500.0, 11000.0), 0.0, 0.5)
	return Synth.mix_at(out, Synth.envelope_adsr(jet, 0.01, 0.2, 0.7, 0.6), 0.02, 0.9)


## A boiler-legged giant's footfall: a deep boom with an iron groan.
static func _walker_stomp(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out: PackedFloat32Array = _thump(70.0, 22.0, 1.2, 0.45)
	out = Synth.mix_at(out, Synth.envelope_exp_decay(Synth.biquad(Synth.noise(1.0, rng), Synth.Filter.LOWPASS, 200.0, 0.7), 0.002, 0.35), 0.0, 1.0)
	out = Synth.mix_at(out, Synth.inharmonic_bell(64.0, PackedFloat32Array([1.0, 1.5, 2.2, 3.1]), PackedFloat32Array([1.1, 0.8, 0.5, 0.3]), PackedFloat32Array([0.7, 0.5, 0.35, 0.2]), 1.8), 0.0, 0.9)
	return Synth.mix_at(out, Synth.envelope_adsr(_hiss(0.8, rng, 1500.0, 7000.0), 0.05, 0.2, 0.5, 0.4), 0.15, 0.3)


## The steam breath: a long rushing roar with a low growl underneath.
static func _walker_breath(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var roar: PackedFloat32Array = Synth.biquad(Synth.noise(1.8, rng), Synth.Filter.BANDPASS, 1100.0, 0.4)
	roar = Synth.mix_at(roar, Synth.biquad(Synth.saw_sweep(65.0, 55.0, 1.8), Synth.Filter.LOWPASS, 400.0, 0.8), 0.0, 0.5)
	roar = Synth.mix_at(roar, _hiss(1.8, rng, 3000.0, 10000.0), 0.0, 0.4)
	return Synth.envelope_adsr(roar, 0.08, 0.2, 0.8, 0.5)


## The charge cry: a steam whistle screaming over a rising engine rumble.
static func _walker_charge(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var rumble: PackedFloat32Array = Synth.envelope_adsr(Synth.biquad(Synth.saw_sweep(45.0, 90.0, 1.4), Synth.Filter.LOWPASS, 300.0, 0.9), 0.2, 0.1, 0.9, 0.3)
	return Synth.mix_at(rumble, _whistle(620.0, 1.2, 1.3, rng), 0.05, 0.7)
