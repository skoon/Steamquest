extends TestCase


func _lock() -> SequenceLock:
	var order: Array[StringName] = [&"b", &"c", &"a"]
	return SequenceLock.new(order)


func test_right_order_solves() -> void:
	var lock: SequenceLock = _lock()
	assert_eq(lock.press(&"b"), SequenceLock.Result.PROGRESS, "first")
	assert_eq(lock.progress(), 1, "one in")
	assert_eq(lock.press(&"c"), SequenceLock.Result.PROGRESS, "second")
	assert_eq(lock.press(&"a"), SequenceLock.Result.SOLVED, "third solves")
	assert_true(lock.is_solved(), "solved")
	assert_eq(lock.progress(), 3, "full progress")


func test_wrong_press_resets() -> void:
	var lock: SequenceLock = _lock()
	lock.press(&"b")
	assert_eq(lock.press(&"a"), SequenceLock.Result.WRONG, "out of order")
	assert_eq(lock.progress(), 0, "reset")
	assert_eq(lock.press(&"b"), SequenceLock.Result.PROGRESS, "can start again")


func test_wrong_first_press() -> void:
	var lock: SequenceLock = _lock()
	assert_eq(lock.press(&"a"), SequenceLock.Result.WRONG, "wrong first valve")
	assert_eq(lock.progress(), 0, "nothing in")


func test_repeating_a_correct_press_is_wrong() -> void:
	var lock: SequenceLock = _lock()
	lock.press(&"b")
	assert_eq(lock.press(&"b"), SequenceLock.Result.WRONG, "same valve twice")


func test_solved_stays_solved() -> void:
	var lock: SequenceLock = _lock()
	for id: StringName in [&"b", &"c", &"a"]:
		lock.press(id)
	assert_eq(lock.press(&"c"), SequenceLock.Result.ALREADY_SOLVED, "further presses ignored")
	assert_true(lock.is_solved(), "still solved")


func test_order_is_copied() -> void:
	var order: Array[StringName] = [&"x", &"y"]
	var lock: SequenceLock = SequenceLock.new(order)
	order[0] = &"z"
	assert_eq(lock.press(&"x"), SequenceLock.Result.PROGRESS, "lock keeps its own order")
