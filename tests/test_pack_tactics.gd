extends TestCase


func test_slot_angles_are_evenly_spaced() -> void:
	assert_almost(PackTactics.slot_angle(0, 3, 0.0), 0.0, "first slot")
	assert_almost(PackTactics.slot_angle(1, 3, 0.0), TAU / 3.0, "second slot")
	assert_almost(PackTactics.slot_angle(2, 3, 0.0), TAU * 2.0 / 3.0, "third slot")


func test_slot_angles_turn_together() -> void:
	assert_almost(PackTactics.slot_angle(1, 2, 0.5), 0.5 + PI, "turn added to every slot")


func test_orbit_points_are_distinct_and_on_the_ring() -> void:
	var center: Vector3 = Vector3(2.0, 0.5, -1.0)
	var points: Array[Vector3] = []
	for slot: int in 3:
		points.append(PackTactics.orbit_point(center, PackTactics.slot_angle(slot, 3, 0.3), 4.0))
	for point: Vector3 in points:
		assert_almost(Vector2(point.x - center.x, point.z - center.z).length(), 4.0, "on the ring")
		assert_almost(point.y, center.y, "same height")
	assert_true(points[0].distance_to(points[1]) > 6.0, "slots 0/1 far apart")
	assert_true(points[1].distance_to(points[2]) > 6.0, "slots 1/2 far apart")


func test_orbit_point_at_angle_zero() -> void:
	assert_vec_almost(PackTactics.orbit_point(Vector3.ZERO, 0.0, 3.0), Vector3(3.0, 0.0, 0.0), "angle 0 is +X")
	assert_vec_almost(PackTactics.orbit_point(Vector3.ZERO, PI * 0.5, 3.0), Vector3(0.0, 0.0, 3.0), "quarter turn is +Z")


func test_slot_of_uses_sorted_ids() -> void:
	var ids: PackedInt64Array = PackedInt64Array([30, 10, 20])
	assert_eq(PackTactics.slot_of(10, ids), 0, "lowest id first")
	assert_eq(PackTactics.slot_of(20, ids), 1, "middle")
	assert_eq(PackTactics.slot_of(30, ids), 2, "highest last")
	assert_eq(ids[0], 30, "input array untouched")


func test_flanking() -> void:
	var facing: Vector3 = Vector3.FORWARD
	assert_false(PackTactics.is_flanking(Vector3.ZERO, facing, Vector3(0.0, 0.0, -3.0), 70.0), "in front is not a flank")
	assert_false(PackTactics.is_flanking(Vector3.ZERO, facing, Vector3(1.0, 0.0, -3.0), 70.0), "slightly off front is not")
	assert_true(PackTactics.is_flanking(Vector3.ZERO, facing, Vector3(3.0, 0.0, 0.0), 70.0), "beside is a flank")
	assert_true(PackTactics.is_flanking(Vector3.ZERO, facing, Vector3(0.0, 0.0, 3.0), 70.0), "behind is a flank")


func test_flanking_ignores_height_and_degenerate_input() -> void:
	assert_true(PackTactics.is_flanking(Vector3.ZERO, Vector3.FORWARD, Vector3(3.0, 5.0, 0.0), 70.0), "height ignored")
	assert_true(PackTactics.is_flanking(Vector3.ZERO, Vector3.ZERO, Vector3(0.0, 0.0, -3.0), 70.0), "no facing counts as flank")
	assert_true(PackTactics.is_flanking(Vector3.ZERO, Vector3.FORWARD, Vector3.ZERO, 70.0), "same spot counts as flank")
