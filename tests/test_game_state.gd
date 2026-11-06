extends TestCase

const GameStateScript: GDScript = preload("res://scripts/autoload/game_state.gd")
const TEST_SAVE: String = "user://test_game_state_save.json"


func before_each() -> void:
	CampaignProgress.delete_save(TEST_SAVE)


func _make_state() -> Node:
	var state: Node = GameStateScript.new() as Node
	state.save_path = TEST_SAVE
	return state


func _make_rumor(id: StringName) -> RumorData:
	var rumor: RumorData = RumorData.new()
	rumor.rumor_id = id
	rumor.title = "Log %s" % id
	return rumor


func test_reset_installs_starting_gears_as_copies() -> void:
	var state: Node = _make_state()
	var rig: FrictionModel = state.rig
	for socket: int in FrictionModel.SOCKET_COUNT:
		assert_true(rig.get_gear(socket) != null, "socket %d filled" % socket)
		assert_false(rig.get_gear(socket) == GameStateScript.STARTING_GEARS[socket], "socket %d is a duplicate" % socket)
	state.free()


func test_discover_rumor_only_once() -> void:
	var state: Node = _make_state()
	var emitted: Array[int] = [0]
	state.rumor_discovered.connect(func(_r: RumorData) -> void: emitted[0] += 1)
	var rumor: RumorData = _make_rumor(&"boiler")
	assert_true(state.discover_rumor(rumor), "first discovery")
	assert_false(state.discover_rumor(rumor), "duplicate ignored")
	assert_eq(emitted[0], 1, "signal fired once")
	assert_true(state.has_rumor(&"boiler"), "has rumor")
	assert_eq(state.rumor_order.size(), 1, "ordered list")
	state.free()


func test_unlock_door_emits_once() -> void:
	var state: Node = _make_state()
	var emitted: Array[int] = [0]
	state.door_unlocked.connect(func(_id: StringName) -> void: emitted[0] += 1)
	state.unlock_door(&"boiler_door")
	state.unlock_door(&"boiler_door")
	assert_true(state.is_door_unlocked(&"boiler_door"), "unlocked")
	assert_eq(emitted[0], 1, "signal fired once")
	state.free()


func test_acquire_golden_gear() -> void:
	var state: Node = _make_state()
	var emitted: Array[int] = [0]
	state.golden_gear_acquired.connect(func() -> void: emitted[0] += 1)
	state.acquire_golden_gear(GearItem.create_golden())
	state.acquire_golden_gear(GearItem.create_golden())
	assert_true(state.has_golden_gear, "flag set")
	assert_eq(emitted[0], 1, "signal once")
	var rig: FrictionModel = state.rig
	assert_true(rig.golden_engaged, "rig engaged")
	assert_almost(rig.base_multiplier(FrictionModel.Socket.DRIVE), FrictionModel.GOLDEN_MULTIPLIER, "penalties removed")
	state.free()


func test_install_scavenged_gear_replaces_most_worn() -> void:
	var state: Node = _make_state()
	var rig: FrictionModel = state.rig
	rig.get_gear(FrictionModel.Socket.PUMP).state = GearItem.GearState.SHATTERED
	var scrap: GearItem = GearItem.new()
	var socket: int = state.install_scavenged_gear(scrap)
	assert_eq(socket, FrictionModel.Socket.PUMP, "replaced shattered socket")
	assert_eq(rig.get_gear(FrictionModel.Socket.PUMP), scrap, "scrap installed")
	state.free()


func test_reset_clears_progress() -> void:
	var state: Node = _make_state()
	state.discover_rumor(_make_rumor(&"x"))
	state.unlock_door(&"d")
	state.acquire_golden_gear(GearItem.create_golden())
	state.declare_victory()
	state.reset()
	assert_false(state.has_rumor(&"x"), "rumors cleared")
	assert_false(state.is_door_unlocked(&"d"), "doors cleared")
	assert_false(state.has_golden_gear, "golden cleared")
	assert_false(state.is_victorious, "victory cleared")
	var rig: FrictionModel = state.rig
	assert_false(rig.golden_engaged, "fresh rig")
	state.free()


func test_scrap_roll_uses_table() -> void:
	var state: Node = _make_state()
	var gear: GearItem = state.roll_scrap_gear()
	assert_true(gear != null and not gear.is_golden_gear, "scrap gear rolled")
	state.free()


const LEVEL_1: String = "res://scenes/levels/level_01_dispatch_yard.tscn"
const LEVEL_2: String = "res://scenes/levels/level_02_tramline.tscn"
const FINALE: String = "res://scenes/world/foundry_level.tscn"


func test_enter_level_begins_and_saves() -> void:
	var state: Node = _make_state()
	var info: LevelInfo = state.enter_level(LEVEL_1)
	assert_eq(info.scene_path, LEVEL_1, "returns the level info")
	assert_eq(state.level_index, 0, "level index set")
	assert_true(state.has_save(), "save written")
	assert_eq(int(CampaignProgress.read_save(TEST_SAVE)["level_index"]), 0, "save records the level")
	assert_eq(int(state.checkpoint["level_index"]), 0, "checkpoint taken")
	state.free()


func test_reentering_level_restores_checkpoint_rig() -> void:
	var state: Node = _make_state()
	state.enter_level(LEVEL_1)
	var start_durability: float = state.rig.get_gear(0).durability
	state.rig.get_gear(0).durability = 3.0
	state.rig.get_gear(1).state = GearItem.GearState.JAMMED
	state.enter_level(LEVEL_1)
	assert_almost(state.rig.get_gear(0).durability, start_durability, "wear undone")
	assert_eq(state.rig.get_gear(1).state, GearItem.GearState.OK, "jam undone")
	state.free()


func test_restore_checkpoint_drops_rumors_found_this_level() -> void:
	var state: Node = _make_state()
	state.discover_rumor(_make_rumor(&"earlier"))
	state.enter_level(LEVEL_1)
	state.discover_rumor(_make_rumor(&"this_level"))
	state.enter_level(LEVEL_1)
	assert_true(state.has_rumor(&"earlier"), "rumors from before the level kept")
	assert_false(state.has_rumor(&"this_level"), "rumors from the failed attempt dropped")
	state.free()


func test_level_state_resets_per_level() -> void:
	var state: Node = _make_state()
	state.enter_level(LEVEL_1)
	state.add_item(&"winding_key")
	state.unlock_door(&"yard_gate")
	state.enter_level(LEVEL_1)
	assert_false(state.has_item(&"winding_key"), "items cleared on restart")
	assert_false(state.is_door_unlocked(&"yard_gate"), "doors cleared on restart")
	state.add_item(&"winding_key")
	state.complete_level()
	state.enter_level(LEVEL_2)
	assert_false(state.has_item(&"winding_key"), "items cleared on the next level")
	state.free()


func test_complete_level_advances_and_carries_wear() -> void:
	var state: Node = _make_state()
	var next_paths: Array[String] = []
	state.level_completed.connect(func(path: String) -> void: next_paths.append(path))
	state.enter_level(LEVEL_1)
	state.rig.get_gear(0).durability = 12.0
	state.complete_level()
	assert_eq(next_paths, [LEVEL_2] as Array[String], "emits the next level's scene")
	assert_eq(state.level_index, 1, "advanced")
	state.enter_level(LEVEL_2)
	assert_almost(state.rig.get_gear(0).durability, 12.0, "wear carries into the next level")
	assert_eq(int(state.checkpoint["level_index"]), 1, "new checkpoint")
	state.free()


func test_completing_finale_declares_victory_and_deletes_save() -> void:
	var state: Node = _make_state()
	var won: Array[int] = [0]
	state.victory.connect(func() -> void: won[0] += 1)
	state.enter_level(FINALE)
	assert_true(state.has_save(), "finale saved on entry")
	state.complete_level()
	assert_eq(won[0], 1, "victory")
	assert_true(state.is_victorious, "victorious")
	assert_false(state.has_save(), "save deleted")
	state.free()


func test_new_campaign_wipes_save() -> void:
	var state: Node = _make_state()
	state.enter_level(LEVEL_2)
	assert_eq(state.new_campaign(), LEVEL_1, "starts at level 1")
	assert_false(state.has_save(), "save deleted")
	assert_eq(state.level_index, -1, "no level in progress")
	state.free()


func test_continue_campaign_resumes_from_save() -> void:
	var writer: Node = _make_state()
	writer.discover_rumor(_make_rumor(&"kept"))
	writer.enter_level(LEVEL_1)
	writer.complete_level()
	writer.rig.get_gear(0).durability = 21.0
	writer.enter_level(LEVEL_2)
	writer.rig.get_gear(0).durability = 2.0
	writer.free()
	var reader: Node = _make_state()
	assert_eq(reader.continue_campaign(), LEVEL_2, "resumes at the saved level")
	assert_eq(reader.level_index, 1, "level index restored")
	assert_almost(reader.rig.get_gear(0).durability, 21.0, "rig as it was when the level began")
	assert_true(reader.has_rumor(&"kept"), "rumors restored")
	reader.enter_level(LEVEL_2)
	assert_almost(reader.rig.get_gear(0).durability, 21.0, "entering the resumed level keeps the checkpoint")
	reader.free()
