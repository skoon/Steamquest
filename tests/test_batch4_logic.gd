extends TestCase


# --- RoomPressure ---------------------------------------------------------------------------

func test_pressure_climbs_and_warns() -> void:
	var pressure: RoomPressure = RoomPressure.new(0.1)
	assert_false(pressure.tick(5.0), "no burst at half")
	assert_almost(pressure.level, 0.5, "climbs at the rise rate")
	assert_false(pressure.is_warning(), "no warning at half")
	pressure.tick(3.0)
	assert_true(pressure.is_warning(), "warning above 75%")


func test_pressure_bursts_and_resets() -> void:
	var pressure: RoomPressure = RoomPressure.new(0.1, 0.75, 0.4, 0.95)
	assert_true(pressure.tick(1.0), "reaching full bursts")
	assert_almost(pressure.level, 0.4, "falls back after the burst")
	assert_false(pressure.tick(0.1), "no second burst right after")


func test_pressure_bleed_never_goes_negative() -> void:
	var pressure: RoomPressure = RoomPressure.new(0.1, 0.75, 0.4, 0.2)
	assert_almost(pressure.bleed(0.3), 0.2, "bleeds only what is there")
	assert_almost(pressure.level, 0.0, "empty")
	pressure.level = 0.8
	assert_almost(pressure.bleed(0.3), 0.3, "full bleed")
	assert_almost(pressure.level, 0.5, "lowered")
	assert_false(pressure.is_warning(), "out of the warning band")


# --- HitCounter -----------------------------------------------------------------------------

func test_hit_counter_reports_the_finishing_blow_once() -> void:
	var counter: HitCounter = HitCounter.new(3)
	assert_false(counter.register(), "first")
	assert_false(counter.register(), "second")
	assert_true(counter.register(), "third completes")
	assert_false(counter.register(), "extra hits are ignored")
	assert_eq(counter.hits, 3, "stops counting at the goal")
	counter.reset()
	assert_false(counter.is_complete(), "reset clears it")


# --- BossPhases -----------------------------------------------------------------------------

func test_boss_phases_by_health() -> void:
	assert_eq(BossPhases.phase_for(1.0), 1, "full health")
	assert_eq(BossPhases.phase_for(0.67), 1, "just above the first threshold")
	assert_eq(BossPhases.phase_for(0.66), 2, "at the first threshold")
	assert_eq(BossPhases.phase_for(0.34), 2, "middle")
	assert_eq(BossPhases.phase_for(0.33), 3, "at the second threshold")
	assert_eq(BossPhases.phase_for(0.0), 3, "dead")


# --- GearItem.repair_fully ------------------------------------------------------------------

func test_repair_fully_restores_a_worn_gear() -> void:
	var gear: GearItem = GearItem.new()
	gear.apply_work(400.0, 1.0)
	assert_true(gear.durability < gear.max_durability and gear.friction > 0.0, "worn")
	gear.repair_fully()
	assert_almost(gear.durability, gear.max_durability, "durability restored")
	assert_almost(gear.friction, 0.0, "friction cleared")
	assert_true(gear.is_functional(), "running")


func test_repair_fully_fixes_a_shattered_gear() -> void:
	var gear: GearItem = GearItem.new()
	gear.apply_work(100000.0, 1.0)
	assert_eq(gear.state, GearItem.GearState.SHATTERED, "shattered")
	gear.repair_fully()
	assert_true(gear.is_functional(), "repaired")


# --- GearWorkbench.most_worn_gear -----------------------------------------------------------

func test_workbench_picks_the_most_worn_socketed_gear() -> void:
	var rig: FrictionModel = FrictionModel.new()
	var fresh: GearItem = GearItem.new()
	var worn: GearItem = GearItem.new()
	worn.durability = 30.0
	rig.set_gear(FrictionModel.Socket.DRIVE, fresh)
	rig.set_gear(FrictionModel.Socket.ARM, worn)
	rig.set_gear(FrictionModel.Socket.PUMP, null)
	assert_true(GearWorkbench.most_worn_gear(rig) == worn, "the worn gear, not the empty socket")
	var broken: GearItem = GearItem.new()
	broken.state = GearItem.GearState.SHATTERED
	broken.durability = 50.0
	rig.set_gear(FrictionModel.Socket.PUMP, broken)
	assert_true(GearWorkbench.most_worn_gear(rig) == broken, "a shattered gear is the most worn")


func test_workbench_ignores_an_empty_or_golden_rig() -> void:
	var rig: FrictionModel = FrictionModel.new()
	for socket: int in FrictionModel.SOCKET_COUNT:
		rig.set_gear(socket as FrictionModel.Socket, null)
	assert_true(GearWorkbench.most_worn_gear(rig) == null, "nothing socketed")
	rig.set_gear(FrictionModel.Socket.DRIVE, GearItem.create_golden())
	assert_true(GearWorkbench.most_worn_gear(rig) == null, "the Golden Gear never needs the bench")
