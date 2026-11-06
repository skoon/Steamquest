extends TestCase


func test_starts_full() -> void:
	var p: SteamPressure = SteamPressure.new(100.0, 10.0, 0.5)
	assert_almost(p.current, 100.0, "full")
	assert_true(p.is_full(), "is_full")


func test_spend_succeeds_and_reduces() -> void:
	var p: SteamPressure = SteamPressure.new(100.0, 10.0, 0.5)
	assert_true(p.try_spend(30.0), "spend ok")
	assert_almost(p.current, 70.0, "reduced")


func test_spend_fails_without_enough_pressure() -> void:
	var p: SteamPressure = SteamPressure.new(100.0, 10.0, 0.5)
	p.current = 5.0
	assert_false(p.try_spend(10.0), "insufficient")
	assert_almost(p.current, 5.0, "nothing spent")


func test_regen_waits_for_delay() -> void:
	var p: SteamPressure = SteamPressure.new(100.0, 10.0, 0.5)
	p.try_spend(50.0)
	assert_almost(p.tick(0.4, 1.0), 0.0, "still in delay")
	assert_almost(p.current, 50.0, "no regen during delay")
	var gained: float = p.tick(0.6, 1.0)
	assert_almost(gained, 5.0, "0.1s delay left, 0.5s of regen")
	assert_almost(p.current, 55.0, "regenerated")


func test_regen_scales_with_multiplier() -> void:
	var p: SteamPressure = SteamPressure.new(100.0, 10.0, 0.0)
	p.current = 0.0
	p.tick(1.0, 0.5)
	assert_almost(p.current, 5.0, "half regen from friction")


func test_regen_caps_at_max() -> void:
	var p: SteamPressure = SteamPressure.new(100.0, 10.0, 0.0)
	p.current = 98.0
	assert_almost(p.tick(5.0, 1.0), 2.0, "only gains up to max")
	assert_almost(p.current, 100.0, "capped")


func test_ratio() -> void:
	var p: SteamPressure = SteamPressure.new(80.0, 10.0, 0.0)
	p.current = 20.0
	assert_almost(p.ratio(), 0.25, "ratio")
