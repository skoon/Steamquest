extends TestCase


func test_outgoing_damage_base() -> void:
	assert_almost(DamageCalc.outgoing_damage(20.0, false, false), 20.0, "no bonuses")


func test_outgoing_damage_golden_bonus() -> void:
	assert_almost(DamageCalc.outgoing_damage(20.0, true, false), 20.0 * DamageCalc.GOLDEN_DAMAGE_BONUS, "golden bonus")


func test_outgoing_damage_bonuses_stack_multiplicatively() -> void:
	var expected: float = 20.0 * DamageCalc.GOLDEN_DAMAGE_BONUS * DamageCalc.OVERCLOCK_DAMAGE_BONUS
	assert_almost(DamageCalc.outgoing_damage(20.0, true, true), expected, "golden x overclock")


func test_armor_subtracts_flat() -> void:
	assert_almost(DamageCalc.mitigated_damage(25.0, 4.0), 21.0, "flat armor")


func test_armor_respects_minimum_ratio() -> void:
	assert_almost(DamageCalc.mitigated_damage(10.0, 50.0), 10.0 * DamageCalc.MIN_DAMAGE_RATIO, "min damage floor")


func test_zero_armor_is_full_damage() -> void:
	assert_almost(DamageCalc.mitigated_damage(13.0, 0.0), 13.0, "no armor")


func test_apply_to_health_clamps_at_zero() -> void:
	assert_almost(DamageCalc.apply_to_health(30.0, 12.0), 18.0, "subtract")
	assert_almost(DamageCalc.apply_to_health(10.0, 50.0), 0.0, "clamped")


func test_knockback_direction_and_magnitude() -> void:
	var kb: Vector3 = DamageCalc.knockback(Vector3.ZERO, Vector3(3.0, 5.0, 0.0), 10.0, 0.0)
	assert_vec_almost(kb, Vector3(10.0, 0.0, 0.0), "horizontal push away from source")


func test_knockback_resistance_scales() -> void:
	var kb: Vector3 = DamageCalc.knockback(Vector3.ZERO, Vector3(0.0, 0.0, -2.0), 10.0, 0.7)
	assert_vec_almost(kb, Vector3(0.0, 0.0, -3.0), "30% of force", 0.001)


func test_full_resistance_means_no_knockback() -> void:
	var kb: Vector3 = DamageCalc.knockback(Vector3.ZERO, Vector3(1.0, 0.0, 1.0), 10.0, 1.0)
	assert_vec_almost(kb, Vector3.ZERO, "immovable")


func test_knockback_from_same_position_is_zero() -> void:
	var kb: Vector3 = DamageCalc.knockback(Vector3.ONE, Vector3.ONE, 10.0, 0.0)
	assert_vec_almost(kb, Vector3.ZERO, "degenerate direction")


func test_arc_check() -> void:
	var facing: Vector3 = Vector3(0.0, 0.0, -1.0)
	assert_true(DamageCalc.is_in_arc(Vector3.ZERO, facing, Vector3(0.0, 0.0, -2.0), 120.0), "straight ahead")
	assert_true(DamageCalc.is_in_arc(Vector3.ZERO, facing, Vector3(1.0, 0.0, -1.0), 120.0), "45 degrees off")
	assert_false(DamageCalc.is_in_arc(Vector3.ZERO, facing, Vector3(2.0, 0.0, 0.0), 120.0), "90 degrees off")
	assert_false(DamageCalc.is_in_arc(Vector3.ZERO, facing, Vector3(0.0, 0.0, 2.0), 120.0), "behind")


func test_arc_ignores_height() -> void:
	assert_true(DamageCalc.is_in_arc(Vector3.ZERO, Vector3(0.0, 0.0, -1.0), Vector3(0.0, 4.0, -1.0), 30.0), "height ignored")


func test_shield_blocks_frontal_attacks() -> void:
	assert_true(DamageCalc.is_blocked_by_shield(Vector3.LEFT, Vector3.LEFT, 120.0), "head on")
	assert_true(DamageCalc.is_blocked_by_shield(Vector3.LEFT, Vector3(-1.0, 0.0, 1.0), 120.0), "45 degrees off is inside 60")
	assert_true(DamageCalc.is_blocked_by_shield(Vector3.LEFT, Vector3(-1.0, 3.0, 0.0), 120.0), "height ignored")


func test_shield_misses_side_and_rear_attacks() -> void:
	assert_false(DamageCalc.is_blocked_by_shield(Vector3.LEFT, Vector3.FORWARD, 120.0), "from the side")
	assert_false(DamageCalc.is_blocked_by_shield(Vector3.LEFT, Vector3.RIGHT, 120.0), "from behind")
	assert_false(DamageCalc.is_blocked_by_shield(Vector3.LEFT, Vector3(-1.0, 0.0, 2.0), 120.0), "63 degrees off is outside 60")


func test_shield_ignores_zero_vectors() -> void:
	assert_false(DamageCalc.is_blocked_by_shield(Vector3.ZERO, Vector3.LEFT, 120.0), "no facing")
	assert_false(DamageCalc.is_blocked_by_shield(Vector3.LEFT, Vector3.ZERO, 120.0), "no direction")
