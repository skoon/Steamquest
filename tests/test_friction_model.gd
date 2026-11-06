extends TestCase

const NO_JAM_ROLL: float = 0.999

var rig: FrictionModel


func before_each() -> void:
	rig = FrictionModel.new()
	for socket: int in FrictionModel.SOCKET_COUNT:
		var gear: GearItem = GearItem.new()
		gear.friction_rate = 0.1
		gear.wear_rate = 1.0
		gear.cooling_rate = 0.1
		rig.set_gear(socket, gear)


func test_fresh_rig_runs_at_full_speed() -> void:
	for socket: int in FrictionModel.SOCKET_COUNT:
		assert_almost(rig.speed_multiplier(socket), 1.0, "socket %d full speed" % socket)


func test_work_only_affects_target_socket() -> void:
	rig.apply_work(FrictionModel.Socket.DRIVE, 5.0, NO_JAM_ROLL)
	assert_almost(rig.get_gear(FrictionModel.Socket.DRIVE).friction, 0.5, "drive friction")
	assert_almost(rig.get_gear(FrictionModel.Socket.ARM).friction, 0.0, "arm untouched")
	assert_almost(rig.base_multiplier(FrictionModel.Socket.DRIVE), 1.0 / 1.5, "drive slowed")


func test_broken_gear_falls_back_to_broken_output() -> void:
	rig.get_gear(FrictionModel.Socket.ARM).state = GearItem.GearState.JAMMED
	assert_almost(rig.base_multiplier(FrictionModel.Socket.ARM), rig.broken_output, "jammed uses broken_output")
	rig.set_gear(FrictionModel.Socket.PUMP, null)
	assert_almost(rig.base_multiplier(FrictionModel.Socket.PUMP), rig.broken_output, "empty uses broken_output")


func test_heavy_friction_never_drops_below_broken_output() -> void:
	rig.broken_output = 0.5
	rig.get_gear(FrictionModel.Socket.DRIVE).friction = GearItem.MAX_FRICTION
	assert_almost(rig.base_multiplier(FrictionModel.Socket.DRIVE), 0.5, "floor at broken_output")


func test_overclock_boosts_then_expires() -> void:
	rig.start_overclock(2.0, 0.5)
	assert_true(rig.is_overclocked(), "overclocked")
	assert_almost(rig.speed_multiplier(FrictionModel.Socket.DRIVE), 1.5, "boosted")
	rig.tick(2.5)
	assert_false(rig.is_overclocked(), "expired")
	assert_almost(rig.speed_multiplier(FrictionModel.Socket.DRIVE), 1.0, "back to base")


func test_tick_cools_all_gears() -> void:
	for socket: int in FrictionModel.SOCKET_COUNT:
		rig.get_gear(socket).friction = 1.0
	rig.tick(2.0)
	for socket: int in FrictionModel.SOCKET_COUNT:
		assert_almost(rig.get_gear(socket).friction, 0.8, "cooled socket %d" % socket)


func test_lubricate_all_frees_every_socket() -> void:
	for socket: int in FrictionModel.SOCKET_COUNT:
		rig.get_gear(socket).friction = 1.0
		rig.get_gear(socket).state = GearItem.GearState.JAMMED
	rig.lubricate_all()
	for socket: int in FrictionModel.SOCKET_COUNT:
		assert_almost(rig.get_gear(socket).friction, 0.0, "no friction %d" % socket)
		assert_eq(rig.get_gear(socket).state, GearItem.GearState.OK, "unjammed %d" % socket)


func test_total_friction_is_average() -> void:
	rig.get_gear(FrictionModel.Socket.DRIVE).friction = 0.3
	rig.get_gear(FrictionModel.Socket.ARM).friction = 0.6
	rig.get_gear(FrictionModel.Socket.PUMP).friction = 0.0
	assert_almost(rig.total_friction(), 0.3, "average friction")


func test_worst_wear_counts_empty_socket_as_fully_worn() -> void:
	rig.get_gear(FrictionModel.Socket.DRIVE).durability = 40.0
	assert_almost(rig.worst_wear_percent(), 60.0, "worst wear from drive")
	rig.set_gear(FrictionModel.Socket.PUMP, null)
	assert_almost(rig.worst_wear_percent(), 100.0, "empty socket is 100% worn")


func test_most_worn_socket_prefers_shattered_then_lowest_durability() -> void:
	rig.get_gear(FrictionModel.Socket.DRIVE).durability = 30.0
	rig.get_gear(FrictionModel.Socket.ARM).durability = 70.0
	assert_eq(rig.most_worn_socket(), FrictionModel.Socket.DRIVE, "lowest durability")
	rig.get_gear(FrictionModel.Socket.PUMP).state = GearItem.GearState.SHATTERED
	assert_eq(rig.most_worn_socket(), FrictionModel.Socket.PUMP, "shattered first")


func test_set_gear_returns_previous() -> void:
	var old: GearItem = rig.get_gear(FrictionModel.Socket.ARM)
	var replacement: GearItem = GearItem.new()
	assert_eq(rig.set_gear(FrictionModel.Socket.ARM, replacement), old, "returns displaced gear")
	assert_eq(rig.get_gear(FrictionModel.Socket.ARM), replacement, "installed")


func test_golden_gear_engagement_removes_all_penalties() -> void:
	for socket: int in FrictionModel.SOCKET_COUNT:
		rig.get_gear(socket).friction = 1.2
	rig.get_gear(FrictionModel.Socket.DRIVE).state = GearItem.GearState.SHATTERED
	rig.engage_golden_gear(GearItem.create_golden())
	assert_true(rig.golden_engaged, "engaged")
	assert_true(rig.get_gear(FrictionModel.Socket.ARM).is_golden_gear, "golden in arm socket")
	for socket: int in FrictionModel.SOCKET_COUNT:
		assert_almost(rig.base_multiplier(socket), FrictionModel.GOLDEN_MULTIPLIER, "golden multiplier socket %d" % socket)
	assert_almost(rig.total_friction(), 0.0, "friction reads zero")


func test_golden_rig_ignores_work() -> void:
	rig.engage_golden_gear(GearItem.create_golden())
	var drive: GearItem = rig.get_gear(FrictionModel.Socket.DRIVE)
	var durability_before: float = drive.durability
	rig.apply_work(FrictionModel.Socket.DRIVE, 500.0, 0.0)
	assert_almost(drive.friction, 0.0, "no friction after golden")
	assert_almost(drive.durability, durability_before, "no wear after golden")


func test_most_worn_socket_skips_golden() -> void:
	rig.get_gear(FrictionModel.Socket.DRIVE).durability = 90.0
	rig.get_gear(FrictionModel.Socket.PUMP).durability = 80.0
	var golden: GearItem = GearItem.create_golden()
	golden.durability = 1.0
	rig.set_gear(FrictionModel.Socket.ARM, golden)
	assert_eq(rig.most_worn_socket(), FrictionModel.Socket.PUMP, "golden socket never selected")


func test_golden_overclock_stacks() -> void:
	rig.engage_golden_gear(GearItem.create_golden())
	rig.start_overclock(1.0, 0.2)
	assert_almost(rig.speed_multiplier(FrictionModel.Socket.ARM), FrictionModel.GOLDEN_MULTIPLIER * 1.2, "golden x overclock")


func test_wear_multiplier_scales_work() -> void:
	rig.wear_multiplier = 2.0
	rig.apply_work(FrictionModel.Socket.DRIVE, 5.0, NO_JAM_ROLL)
	assert_almost(rig.get_gear(FrictionModel.Socket.DRIVE).friction, 1.0, "double work, double friction")


func test_wear_multiplier_defaults_to_one() -> void:
	assert_almost(rig.wear_multiplier, 1.0, "normal wear by default")
