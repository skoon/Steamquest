extends TestCase

const NO_JAM_ROLL: float = 0.999
const ALWAYS_JAM_ROLL: float = 0.0


func _make_gear() -> GearItem:
	var gear: GearItem = GearItem.new()
	gear.friction_rate = 0.1
	gear.wear_rate = 1.0
	gear.max_durability = 100.0
	gear.durability = 100.0
	gear.jam_chance_per_work = 0.5
	gear.cooling_rate = 0.2
	return gear


func test_new_gear_has_no_friction_and_full_output() -> void:
	var gear: GearItem = _make_gear()
	assert_almost(gear.friction, 0.0, "fresh friction")
	assert_almost(gear.penalty_multiplier(), 1.0, "fresh multiplier")
	assert_eq(gear.state, GearItem.GearState.OK, "fresh state")


func test_work_accumulates_friction_by_rate() -> void:
	var gear: GearItem = _make_gear()
	gear.apply_work(2.0, NO_JAM_ROLL)
	assert_almost(gear.friction, 0.2, "friction = rate * work")


func test_friction_is_capped() -> void:
	var gear: GearItem = _make_gear()
	gear.durability = 100000.0
	gear.max_durability = 100000.0
	gear.apply_work(1000.0, NO_JAM_ROLL)
	assert_almost(gear.friction, GearItem.MAX_FRICTION, "friction capped at MAX_FRICTION")


func test_wear_is_amplified_by_friction() -> void:
	var gear: GearItem = _make_gear()
	gear.apply_work(2.0, NO_JAM_ROLL)
	# friction becomes 0.2 first, so wear = 1.0 * 2.0 * 1.2 = 2.4
	assert_almost(gear.durability, 97.6, "durability loss includes friction amplification")
	assert_almost(gear.wear_percent(), 2.4, "wear percent")


func test_penalty_multiplier_formula() -> void:
	var gear: GearItem = _make_gear()
	gear.friction = 1.0
	assert_almost(gear.penalty_multiplier(), 0.5, "1 / (1 + friction)")


func test_cooling_reduces_friction_but_not_below_zero() -> void:
	var gear: GearItem = _make_gear()
	gear.friction = 0.5
	gear.cool(1.0)
	assert_almost(gear.friction, 0.3, "cooled by cooling_rate * delta")
	gear.cool(100.0)
	assert_almost(gear.friction, 0.0, "never negative")


func test_gear_shatters_at_zero_durability() -> void:
	var gear: GearItem = _make_gear()
	gear.durability = 1.0
	gear.apply_work(5.0, NO_JAM_ROLL)
	assert_eq(gear.state, GearItem.GearState.SHATTERED, "shattered")
	assert_almost(gear.durability, 0.0, "durability clamped at zero")
	assert_almost(gear.penalty_multiplier(), 0.0, "shattered gear gives no output")


func test_shattered_gear_ignores_further_work() -> void:
	var gear: GearItem = _make_gear()
	gear.state = GearItem.GearState.SHATTERED
	gear.durability = 0.0
	gear.apply_work(5.0, ALWAYS_JAM_ROLL)
	assert_almost(gear.friction, 0.0, "no friction gained once shattered")
	assert_eq(gear.state, GearItem.GearState.SHATTERED, "stays shattered")


func test_no_jam_above_threshold() -> void:
	var gear: GearItem = _make_gear()
	gear.apply_work(1.0, ALWAYS_JAM_ROLL)
	assert_eq(gear.state, GearItem.GearState.OK, "healthy gear cannot jam")


func test_jams_below_threshold_when_roll_succeeds() -> void:
	var gear: GearItem = _make_gear()
	gear.durability = 20.0
	gear.apply_work(1.0, ALWAYS_JAM_ROLL)
	assert_eq(gear.state, GearItem.GearState.JAMMED, "worn gear jams on a low roll")
	assert_almost(gear.penalty_multiplier(), 0.0, "jammed gear gives no output")


func test_worn_gear_does_not_jam_on_high_roll() -> void:
	var gear: GearItem = _make_gear()
	gear.durability = 20.0
	gear.apply_work(1.0, NO_JAM_ROLL)
	assert_eq(gear.state, GearItem.GearState.OK, "high roll avoids jam")


func test_lubricate_clears_friction_and_jam_but_not_wear() -> void:
	var gear: GearItem = _make_gear()
	gear.durability = 20.0
	gear.friction = 0.9
	gear.state = GearItem.GearState.JAMMED
	gear.lubricate()
	assert_almost(gear.friction, 0.0, "friction purged")
	assert_eq(gear.state, GearItem.GearState.OK, "jam freed")
	assert_almost(gear.durability, 20.0, "wear untouched")


func test_lubricate_does_not_repair_shattered_gear() -> void:
	var gear: GearItem = _make_gear()
	gear.state = GearItem.GearState.SHATTERED
	gear.lubricate()
	assert_eq(gear.state, GearItem.GearState.SHATTERED, "still shattered")


func test_golden_gear_has_zero_rates() -> void:
	var golden: GearItem = GearItem.create_golden()
	assert_true(golden.is_golden_gear, "flagged golden")
	assert_almost(golden.friction_rate, 0.0, "zero friction rate")
	assert_almost(golden.wear_rate, 0.0, "zero wear rate")


func test_golden_gear_is_immune_to_work() -> void:
	var golden: GearItem = GearItem.create_golden()
	golden.durability = 10.0
	golden.apply_work(10000.0, ALWAYS_JAM_ROLL)
	assert_almost(golden.friction, 0.0, "no friction")
	assert_almost(golden.durability, 10.0, "no wear")
	assert_eq(golden.state, GearItem.GearState.OK, "never jams or shatters")
	assert_almost(golden.penalty_multiplier(), 1.0, "full output")


func test_golden_flag_overrides_nonzero_rates() -> void:
	var gear: GearItem = _make_gear()
	gear.is_golden_gear = true
	gear.apply_work(50.0, ALWAYS_JAM_ROLL)
	assert_almost(gear.friction, 0.0, "golden flag alone grants immunity")
	assert_almost(gear.durability, 100.0, "golden flag alone prevents wear")


func test_zero_work_changes_nothing() -> void:
	var gear: GearItem = _make_gear()
	gear.durability = 10.0
	gear.apply_work(0.0, ALWAYS_JAM_ROLL)
	assert_almost(gear.friction, 0.0, "no friction")
	assert_eq(gear.state, GearItem.GearState.OK, "no jam from zero work")


func test_durability_ratio_handles_zero_max() -> void:
	var gear: GearItem = _make_gear()
	gear.max_durability = 0.0
	assert_almost(gear.durability_ratio(), 0.0, "zero max durability is ratio 0")


func test_scrap_table_rolls_within_ranges() -> void:
	var table: ScrapGearTable = ScrapGearTable.new()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1234
	for i: int in 50:
		var gear: GearItem = table.roll(rng)
		assert_true(gear.friction_rate >= table.friction_rate_min and gear.friction_rate <= table.friction_rate_max, "friction rate in range")
		assert_true(gear.wear_rate >= table.wear_rate_min and gear.wear_rate <= table.wear_rate_max, "wear rate in range")
		assert_true(gear.durability >= table.durability_min and gear.durability <= table.durability_max, "durability in range")
		assert_true(table.gear_names.has(gear.gear_name), "name from table")
		assert_false(gear.is_golden_gear, "scrap is never golden")
