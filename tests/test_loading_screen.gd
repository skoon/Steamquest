extends TestCase


func test_loading_text_cycles_dots_and_keeps_width() -> void:
	assert_eq(LoadingScreen.loading_text(0.0), "Loading   ", "starts with no dots")
	assert_eq(LoadingScreen.loading_text(LoadingScreen.DOT_INTERVAL * 1.5), "Loading.  ", "one dot")
	assert_eq(LoadingScreen.loading_text(LoadingScreen.DOT_INTERVAL * 3.5), "Loading...", "three dots")
	assert_eq(LoadingScreen.loading_text(LoadingScreen.DOT_INTERVAL * 4.5), "Loading   ", "wraps back to none")
	for step: int in 8:
		assert_eq(LoadingScreen.loading_text(LoadingScreen.DOT_INTERVAL * step).length(), 10, "same width at step %d" % step)


func test_spin_angle_turns_and_wraps() -> void:
	assert_almost(LoadingScreen.spin_angle(0.0), 0.0, "starts upright")
	assert_almost(LoadingScreen.spin_angle(1.0), LoadingScreen.SPIN_SPEED, "turns at the spin speed")
	var full_turn: float = TAU / LoadingScreen.SPIN_SPEED
	assert_almost(LoadingScreen.spin_angle(full_turn + 1.0), LoadingScreen.SPIN_SPEED, "wraps after a full turn", 0.001)


func test_should_finish_waits_for_load_and_minimum_time() -> void:
	assert_false(LoadingScreen.should_finish(false, 5.0, 0.6), "not before the scene loads")
	assert_false(LoadingScreen.should_finish(true, 0.2, 0.6), "not before the minimum time")
	assert_true(LoadingScreen.should_finish(true, 0.6, 0.6), "once loaded and shown long enough")
