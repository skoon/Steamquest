extends TestCase


func test_spawn_waits_for_interval() -> void:
	var schedule: SpawnSchedule = SpawnSchedule.new(5.0, 3)
	assert_false(schedule.should_spawn(4.9, 0), "too soon")
	assert_true(schedule.should_spawn(5.0, 0), "on time")


func test_spawn_respects_cap() -> void:
	var schedule: SpawnSchedule = SpawnSchedule.new(5.0, 3)
	assert_true(schedule.should_spawn(10.0, 2), "below cap")
	assert_false(schedule.should_spawn(10.0, 3), "at cap")
	assert_false(schedule.should_spawn(10.0, 4), "over cap")


func test_hold_fills_while_in_range() -> void:
	var hold: HoldProgress = HoldProgress.new(10.0)
	assert_almost(hold.tick(2.5, true), 0.25, "quarter")
	assert_almost(hold.tick(2.5, true), 0.5, "half")
	assert_false(hold.is_complete(), "not done")


func test_hold_pauses_out_of_range() -> void:
	var hold: HoldProgress = HoldProgress.new(10.0)
	hold.tick(4.0, true)
	assert_almost(hold.tick(30.0, false), 0.4, "no change while away")


func test_hold_completes_and_clamps() -> void:
	var hold: HoldProgress = HoldProgress.new(10.0)
	assert_almost(hold.tick(25.0, true), 1.0, "clamped at 1")
	assert_true(hold.is_complete(), "complete")
