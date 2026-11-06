extends TestCase


func test_level_rises_and_falls() -> void:
	var tide: TideCycle = TideCycle.new(14.0)
	assert_almost(tide.level_at(0.0), 0.0, "low water at the start")
	assert_almost(tide.level_at(3.5), 0.5, "half way up")
	assert_almost(tide.level_at(7.0), 1.0, "high water half way through")
	assert_almost(tide.level_at(10.5), 0.5, "half way down")
	assert_almost(tide.level_at(14.0), 0.0, "low again")


func test_level_stays_in_range() -> void:
	var tide: TideCycle = TideCycle.new(9.0, 2.0)
	for i: int in 200:
		var level: float = tide.level_at(float(i) * 0.137)
		assert_true(level >= 0.0 and level <= 1.0, "level in range at step %d" % i)


func test_offset_shifts_cycle() -> void:
	var tide: TideCycle = TideCycle.new(14.0, 7.0)
	assert_almost(tide.level_at(0.0), 1.0, "offset by half a period starts high")


func test_is_deep_threshold() -> void:
	var tide: TideCycle = TideCycle.new(14.0)
	assert_false(tide.is_deep(1.0, 0.55), "shallow early")
	assert_true(tide.is_deep(7.0, 0.55), "deep at high water")
	assert_false(tide.is_deep(13.0, 0.55), "shallow again")


func test_forced_flood_holds_full_until_time() -> void:
	var tide: TideCycle = TideCycle.new(14.0)
	tide.force_flood(5.0)
	assert_true(tide.is_forced(1.0), "forced during the flood")
	assert_almost(tide.level_at(1.0), 1.0, "full during the flood")
	assert_false(tide.is_forced(5.0), "flood ends at its time")
	assert_almost(tide.level_at(14.0), 0.0, "natural tide resumes")


func test_shorter_flood_never_cuts_a_longer_one() -> void:
	var tide: TideCycle = TideCycle.new(14.0)
	tide.force_flood(10.0)
	tide.force_flood(3.0)
	assert_true(tide.is_forced(8.0), "the longer flood still holds")
