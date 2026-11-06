extends TestCase


# --- SightCone ------------------------------------------------------------------------------

func test_sight_cone_sees_ahead_in_range() -> void:
	assert_true(SightCone.can_see(Vector3.ZERO, Vector3.FORWARD, Vector3(0.0, 0.0, -5.0), 8.0, 25.0), "straight ahead")
	assert_true(SightCone.can_see(Vector3.ZERO, Vector3.FORWARD, Vector3(1.5, 3.0, -5.0), 8.0, 25.0), "slightly off, height ignored")


func test_sight_cone_misses_outside() -> void:
	assert_false(SightCone.can_see(Vector3.ZERO, Vector3.FORWARD, Vector3(0.0, 0.0, -9.0), 8.0, 25.0), "too far")
	assert_false(SightCone.can_see(Vector3.ZERO, Vector3.FORWARD, Vector3(4.0, 0.0, -4.0), 8.0, 25.0), "45 degrees off a 25 degree half-angle")
	assert_false(SightCone.can_see(Vector3.ZERO, Vector3.FORWARD, Vector3(0.0, 0.0, 3.0), 8.0, 25.0), "behind")


func test_sight_cone_degenerate_input() -> void:
	assert_false(SightCone.can_see(Vector3.ZERO, Vector3.ZERO, Vector3(0.0, 0.0, -1.0), 8.0, 25.0), "no facing sees nothing")
	assert_true(SightCone.can_see(Vector3.ZERO, Vector3.FORWARD, Vector3.ZERO, 8.0, 25.0), "same spot is seen")


# --- AlarmState -----------------------------------------------------------------------------

func test_alarm_raises_on_sight_and_clears_after_quiet() -> void:
	var alarm: AlarmState = AlarmState.new(20.0)
	assert_false(alarm.tick(0.0, false), "nothing to change")
	assert_true(alarm.tick(1.0, true), "raised on sight")
	assert_true(alarm.is_raised(), "raised")
	assert_false(alarm.tick(15.0, false), "still raised during the quiet period")
	assert_true(alarm.tick(21.0, false), "cleared 20 s after last sight")
	assert_false(alarm.is_raised(), "cleared")


func test_alarm_sighting_resets_quiet_period() -> void:
	var alarm: AlarmState = AlarmState.new(20.0)
	alarm.tick(0.0, true)
	alarm.tick(15.0, true)
	alarm.tick(30.0, false)
	assert_true(alarm.is_raised(), "second sighting extends the alarm")
	alarm.tick(35.0, false)
	assert_false(alarm.is_raised(), "clears 20 s after the second sighting")


# --- PatrolRoute ----------------------------------------------------------------------------

func test_patrol_advances_and_loops() -> void:
	var route: PatrolRoute = PatrolRoute.new(PackedVector3Array([Vector3(0, 0, 0), Vector3(10, 0, 0), Vector3(10, 0, 10)]))
	assert_vec_almost(route.next_target(Vector3(5.0, 0.0, 0.0), 0.5), Vector3(0, 0, 0), "heads for the first point")
	assert_vec_almost(route.next_target(Vector3(0.2, 0.0, 0.0), 0.5), Vector3(10, 0, 0), "arrives and moves on")
	route.next_target(Vector3(10.0, 0.0, 0.1), 0.5)
	assert_vec_almost(route.next_target(Vector3(10.0, 5.0, 10.0), 0.5), Vector3(0, 0, 0), "loops back to the start, height ignored")


# --- GustCycle ------------------------------------------------------------------------------

func test_gust_pushes_only_during_gust() -> void:
	var gust: GustCycle = GustCycle.new(9.0, 1.5, 2.0, Vector3(0.0, 3.0, 2.0), 8.0)
	assert_vec_almost(gust.force_at(1.0), Vector3.ZERO, "calm")
	assert_eq(gust.phase_at(6.0), HazardCycle.Phase.WARNING, "warning before the gust")
	assert_vec_almost(gust.force_at(6.0), Vector3.ZERO, "no push during the warning")
	assert_vec_almost(gust.force_at(8.0), Vector3(0.0, 0.0, 8.0), "peak mid-gust, flattened to horizontal")
	assert_true(gust.force_at(7.2).length() < 8.0, "eases in")


# --- PlatePattern ---------------------------------------------------------------------------

func test_plates_sweep_row_by_row() -> void:
	var pattern: PlatePattern = PlatePattern.new(3, 1.0, 1.2, 0.8, 2.0)
	assert_eq(pattern.state_at(0, 0.0), PlatePattern.State.WARNING, "first row flickers first")
	assert_eq(pattern.state_at(0, 0.9), PlatePattern.State.LIVE, "then goes live")
	assert_eq(pattern.state_at(1, 1.1), PlatePattern.State.WARNING, "next row warns while the first is live")
	assert_eq(pattern.state_at(2, 0.9), PlatePattern.State.OFF, "last row still off")
	assert_eq(pattern.state_at(2, 2.9), PlatePattern.State.LIVE, "last row live in turn")
	assert_eq(pattern.state_at(0, 2.9), PlatePattern.State.OFF, "first row finished")
	assert_almost(pattern.period(), 0.8 + 2.0 + 1.2 + 2.0, "period covers warning, sweep, live and rest")
	assert_eq(pattern.state_at(0, pattern.period() + 0.9), PlatePattern.State.LIVE, "repeats")


func test_plates_reverse_and_offset() -> void:
	var pattern: PlatePattern = PlatePattern.new(3, 1.0, 1.2, 0.8, 2.0, true)
	assert_eq(pattern.state_at(2, 0.9), PlatePattern.State.LIVE, "reverse starts at the last row")
	assert_eq(pattern.state_at(0, 0.9), PlatePattern.State.OFF, "first row waits")
	var shifted: PlatePattern = PlatePattern.new(3, 1.0, 1.2, 0.8, 2.0, false, 0.9)
	assert_eq(shifted.state_at(0, 0.0), PlatePattern.State.LIVE, "offset shifts the sweep")


# --- PowerRouting ---------------------------------------------------------------------------

func test_safe_routing_earths_the_current() -> void:
	var routing: PowerRouting = PowerRouting.new(PackedInt32Array([2, 0, 1]), 3)
	assert_true(routing.is_safe(PackedInt32Array([2, 0, 1])), "the safe combination")
	assert_eq(routing.live_section(PackedInt32Array([2, 0, 1])), PowerRouting.EARTH, "nothing live")


func test_unsafe_routings_make_a_section_live() -> void:
	var routing: PowerRouting = PowerRouting.new(PackedInt32Array([2, 0, 1]), 3)
	var seen: Dictionary = {}
	for a: int in 3:
		for b: int in 3:
			for c: int in 3:
				var positions: PackedInt32Array = PackedInt32Array([a, b, c])
				if routing.is_safe(positions):
					continue
				var section: int = routing.live_section(positions)
				assert_true(section >= 0 and section < 3, "unsafe %s feeds a real section" % positions)
				seen[section] = true
	assert_eq(seen.size(), 3, "every section can be fed by some wrong routing")


func test_routing_changes_with_one_switch() -> void:
	var routing: PowerRouting = PowerRouting.new(PackedInt32Array([0, 0, 0]), 3)
	assert_true(routing.live_section(PackedInt32Array([0, 0, 1])) != routing.live_section(PackedInt32Array([0, 0, 2])), "turning one switch moves the current")
