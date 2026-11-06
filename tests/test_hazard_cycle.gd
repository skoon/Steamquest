extends TestCase
## Cycle of 7 s: IDLE [0, 4.3), WARNING [4.3, 5.9), ACTIVE [5.9, 7).


func _cycle(offset: float = 0.0) -> HazardCycle:
	return HazardCycle.new(7.0, 1.6, 1.1, offset)


func test_phases_within_one_cycle() -> void:
	var cycle: HazardCycle = _cycle()
	assert_eq(cycle.phase_at(0.0), HazardCycle.Phase.IDLE, "start idle")
	assert_eq(cycle.phase_at(4.29), HazardCycle.Phase.IDLE, "just before warning")
	assert_eq(cycle.phase_at(4.31), HazardCycle.Phase.WARNING, "warning begins")
	assert_eq(cycle.phase_at(5.89), HazardCycle.Phase.WARNING, "just before active")
	assert_eq(cycle.phase_at(5.91), HazardCycle.Phase.ACTIVE, "active begins")
	assert_eq(cycle.phase_at(6.99), HazardCycle.Phase.ACTIVE, "active until the end")
	assert_eq(cycle.phase_at(7.0), HazardCycle.Phase.IDLE, "next cycle idle")


func test_cycle_repeats() -> void:
	var cycle: HazardCycle = _cycle()
	assert_eq(cycle.phase_at(70.0 + 6.0), HazardCycle.Phase.ACTIVE, "tenth cycle active")
	assert_almost(cycle.cycle_time(15.5), 1.5, "cycle time wraps")


func test_offset_shifts_cycle() -> void:
	var cycle: HazardCycle = _cycle(3.5)
	assert_eq(cycle.phase_at(2.4), HazardCycle.Phase.ACTIVE, "offset brings the pass earlier")
	assert_eq(cycle.phase_at(0.0), HazardCycle.Phase.IDLE, "offset start idle")
	assert_almost(cycle.cycle_time(0.0), 3.5, "offset cycle time")


func test_active_progress() -> void:
	var cycle: HazardCycle = _cycle()
	assert_almost(cycle.active_progress(3.0), 0.0, "zero while idle")
	assert_almost(cycle.active_progress(5.0), 0.0, "zero while warning")
	assert_almost(cycle.active_progress(5.9), 0.0, "zero at active start")
	assert_almost(cycle.active_progress(6.45), 0.5, "half way")
	assert_almost(cycle.active_progress(6.9999), 1.0, "almost done", 0.001)


func test_cycle_index() -> void:
	var cycle: HazardCycle = _cycle()
	assert_eq(cycle.cycle_index(0.0), 0, "first cycle")
	assert_eq(cycle.cycle_index(6.99), 0, "still first")
	assert_eq(cycle.cycle_index(7.0), 1, "second")
	assert_eq(_cycle(3.5).cycle_index(3.5), 1, "offset counts from the shifted start")


func test_zero_warning_goes_straight_to_active() -> void:
	var cycle: HazardCycle = HazardCycle.new(4.0, 0.0, 1.0)
	assert_eq(cycle.phase_at(2.99), HazardCycle.Phase.IDLE, "idle until active")
	assert_eq(cycle.phase_at(3.0), HazardCycle.Phase.ACTIVE, "active without warning")
