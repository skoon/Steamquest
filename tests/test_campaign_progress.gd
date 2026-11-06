extends TestCase

const TEST_SAVE: String = "user://test_campaign_progress_save.json"
const CAMPAIGN: CampaignDef = preload("res://data/campaign.tres")


func before_each() -> void:
	CampaignProgress.delete_save(TEST_SAVE)


func _make_gear(gear_name: String, state: GearItem.GearState) -> GearItem:
	var gear: GearItem = GearItem.new()
	gear.gear_name = gear_name
	gear.friction_rate = 1.25
	gear.wear_rate = 0.5
	gear.max_durability = 120.0
	gear.durability = 47.5
	gear.jam_chance_per_work = 0.02
	gear.cooling_rate = 3.0
	gear.friction = 0.4
	gear.state = state
	return gear


func _make_rig() -> FrictionModel:
	var rig: FrictionModel = FrictionModel.new()
	rig.set_gear(0, _make_gear("Drive", GearItem.GearState.OK))
	rig.set_gear(1, _make_gear("Weapon", GearItem.GearState.JAMMED))
	rig.set_gear(2, null)
	return rig


func _make_rumor(id: StringName) -> RumorData:
	var rumor: RumorData = RumorData.new()
	rumor.rumor_id = id
	rumor.title = "Title %s" % id
	rumor.body = "Body %s" % id
	rumor.hint = "Hint %s" % id
	return rumor


func _assert_gears_match(actual: GearItem, expected: GearItem, label: String) -> void:
	assert_eq(actual.gear_name, expected.gear_name, label + " name")
	assert_almost(actual.friction_rate, expected.friction_rate, label + " friction rate")
	assert_almost(actual.wear_rate, expected.wear_rate, label + " wear rate")
	assert_almost(actual.max_durability, expected.max_durability, label + " max durability")
	assert_almost(actual.durability, expected.durability, label + " durability")
	assert_eq(actual.is_golden_gear, expected.is_golden_gear, label + " golden flag")
	assert_almost(actual.jam_chance_per_work, expected.jam_chance_per_work, label + " jam chance")
	assert_almost(actual.cooling_rate, expected.cooling_rate, label + " cooling")
	assert_almost(actual.friction, expected.friction, label + " friction")
	assert_eq(actual.state, expected.state, label + " state")


func test_gear_round_trip_keeps_every_field() -> void:
	for state: GearItem.GearState in [GearItem.GearState.OK, GearItem.GearState.JAMMED, GearItem.GearState.SHATTERED]:
		var gear: GearItem = _make_gear("Cog", state)
		_assert_gears_match(CampaignProgress.gear_from_dict(CampaignProgress.gear_to_dict(gear)), gear, "state %d" % state)


func test_golden_gear_round_trip() -> void:
	var gear: GearItem = _make_gear("Golden Gear", GearItem.GearState.OK)
	gear.is_golden_gear = true
	assert_true(CampaignProgress.gear_from_dict(CampaignProgress.gear_to_dict(gear)).is_golden_gear, "golden survives")


func test_empty_socket_round_trips_as_null() -> void:
	assert_eq(CampaignProgress.gear_to_dict(null), {}, "null gear is an empty dictionary")
	assert_eq(CampaignProgress.gear_from_dict({}), null, "empty dictionary is no gear")


func test_rig_round_trip() -> void:
	var rig: FrictionModel = _make_rig()
	rig.golden_engaged = true
	var restored: FrictionModel = CampaignProgress.rig_from_dict(CampaignProgress.rig_to_dict(rig))
	_assert_gears_match(restored.get_gear(0), rig.get_gear(0), "socket 0")
	_assert_gears_match(restored.get_gear(1), rig.get_gear(1), "socket 1")
	assert_eq(restored.get_gear(2), null, "socket 2 stays empty")
	assert_true(restored.golden_engaged, "golden engagement survives")


func test_restored_rig_gears_are_new_objects() -> void:
	var rig: FrictionModel = _make_rig()
	var restored: FrictionModel = CampaignProgress.rig_from_dict(CampaignProgress.rig_to_dict(rig))
	restored.get_gear(0).durability = 1.0
	assert_almost(rig.get_gear(0).durability, 47.5, "wearing the copy leaves the original alone")


func test_rumors_round_trip_in_discovery_order() -> void:
	var rumors: Dictionary = {&"b": _make_rumor(&"b"), &"a": _make_rumor(&"a")}
	var order: Array[StringName] = [&"b", &"a"]
	var restored: Array[RumorData] = CampaignProgress.rumors_from_array(CampaignProgress.rumors_to_array(rumors, order))
	assert_eq(restored.size(), 2, "both rumors")
	assert_eq(restored[0].rumor_id, &"b", "first discovered first")
	assert_eq(restored[1].rumor_id, &"a", "second discovered second")
	assert_eq(restored[0].title, "Title b", "title")
	assert_eq(restored[0].body, "Body b", "body")
	assert_eq(restored[0].hint, "Hint b", "hint")


func test_make_checkpoint_contents() -> void:
	var rumors: Dictionary = {&"a": _make_rumor(&"a")}
	var order: Array[StringName] = [&"a"]
	var checkpoint: Dictionary = CampaignProgress.make_checkpoint(2, _make_rig(), rumors, order)
	assert_eq(checkpoint["level_index"], 2, "level index")
	assert_eq((checkpoint["rig"]["sockets"] as Array).size(), FrictionModel.SOCKET_COUNT, "every socket recorded")
	assert_eq((checkpoint["rumors"] as Array).size(), 1, "rumors recorded")


func test_save_file_round_trip() -> void:
	var rumors: Dictionary = {&"a": _make_rumor(&"a")}
	var order: Array[StringName] = [&"a"]
	var rig: FrictionModel = _make_rig()
	var checkpoint: Dictionary = CampaignProgress.make_checkpoint(1, rig, rumors, order)
	assert_eq(CampaignProgress.write_save(TEST_SAVE, checkpoint), OK, "save written")
	var loaded: Dictionary = CampaignProgress.read_save(TEST_SAVE)
	assert_eq(loaded["level_index"], 1, "level index is an int again")
	assert_false(loaded.has("version"), "version is stripped")
	var restored: FrictionModel = CampaignProgress.rig_from_dict(loaded["rig"] as Dictionary)
	_assert_gears_match(restored.get_gear(1), rig.get_gear(1), "jammed gear from disk")
	assert_eq(restored.get_gear(2), null, "empty socket from disk")
	assert_eq(CampaignProgress.rumors_from_array(loaded["rumors"] as Array)[0].rumor_id, &"a", "rumor from disk")


func test_read_missing_save_is_empty() -> void:
	assert_eq(CampaignProgress.read_save(TEST_SAVE), {}, "no file, no checkpoint")


func test_delete_save_removes_file() -> void:
	CampaignProgress.write_save(TEST_SAVE, CampaignProgress.make_checkpoint(0, _make_rig(), {}, [] as Array[StringName]))
	assert_true(FileAccess.file_exists(TEST_SAVE), "file written")
	CampaignProgress.delete_save(TEST_SAVE)
	assert_false(FileAccess.file_exists(TEST_SAVE), "file deleted")
	CampaignProgress.delete_save(TEST_SAVE)


func test_campaign_order_and_finale() -> void:
	var last: int = CAMPAIGN.level_count() - 1
	assert_true(CAMPAIGN.level_count() >= 4, "act I plus the finale")
	assert_eq(CAMPAIGN.level(last).scene_path, "res://scenes/world/foundry_level.tscn", "the foundry is the finale")
	assert_true(CAMPAIGN.is_final(last), "last level is final")
	assert_false(CAMPAIGN.is_final(0), "first level is not final")
	assert_eq(CAMPAIGN.next_index(0), 1, "first leads to second")
	assert_eq(CAMPAIGN.next_index(last), -1, "nothing after the finale")


func test_campaign_index_of_scene() -> void:
	assert_eq(CAMPAIGN.index_of_scene("res://scenes/levels/level_01_dispatch_yard.tscn"), 0, "level 1")
	assert_eq(CAMPAIGN.index_of_scene("res://scenes/levels/level_03_clockmakers_row.tscn"), 2, "level 3")
	assert_eq(CAMPAIGN.index_of_scene("res://not_a_level.tscn"), -1, "unknown scene")


func test_campaign_levels_have_titles_and_scenes() -> void:
	for i: int in CAMPAIGN.level_count():
		var info: LevelInfo = CAMPAIGN.level(i)
		assert_true(info.title != "", "level %d has a title" % i)
		assert_true(info.act_name != "", "level %d has an act" % i)
		assert_true(ResourceLoader.exists(info.scene_path), "level %d scene exists" % i)


func test_campaign_runs_six_levels_then_finale() -> void:
	assert_eq(CAMPAIGN.level_count(), 7, "six levels and the finale")
	assert_eq(CAMPAIGN.index_of_scene("res://scenes/levels/level_04_flooded_cisterns.tscn"), 3, "level 4")
	assert_eq(CAMPAIGN.index_of_scene("res://scenes/levels/level_06_coal_seam.tscn"), 5, "level 6")
	assert_eq(CAMPAIGN.next_index(5), 6, "level 6 leads to the finale")
