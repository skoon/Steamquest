extends TestCase

const SteamDoorScript: GDScript = preload("res://scenes/world/steam_door.gd")


func test_all_unlocked_needs_every_id() -> void:
	var ids: Array[StringName] = [&"a", &"b"]
	assert_false(SteamDoorScript.all_unlocked(ids, {}), "none unlocked")
	assert_false(SteamDoorScript.all_unlocked(ids, {&"a": true}), "one of two")
	assert_true(SteamDoorScript.all_unlocked(ids, {&"a": true, &"b": true}), "both")
	assert_true(SteamDoorScript.all_unlocked(ids, {&"a": true, &"b": true, &"c": true}), "extras don't matter")


func test_count_unlocked() -> void:
	var ids: Array[StringName] = [&"a", &"b", &"c"]
	assert_eq(SteamDoorScript.count_unlocked(ids, {}), 0, "none")
	assert_eq(SteamDoorScript.count_unlocked(ids, {&"b": true, &"z": true}), 1, "only listed ids count")
	assert_eq(SteamDoorScript.count_unlocked(ids, {&"a": true, &"b": true, &"c": true}), 3, "all")
