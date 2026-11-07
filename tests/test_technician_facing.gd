extends TestCase


func test_walking_faces_the_direction_of_travel() -> void:
	var facing: Vector3 = Technician.facing_for(Vector3(0.0, 0.0, 5.0), Vector3(0.0, 0.0, -1.0), false)
	assert_vec_almost(facing, Vector3(0.0, 0.0, 1.0), "walking away from the cursor turns the model around")


func test_standing_still_faces_the_aim() -> void:
	var facing: Vector3 = Technician.facing_for(Vector3(0.1, 0.0, 0.0), Vector3(1.0, 0.0, 0.0), false)
	assert_vec_almost(facing, Vector3(1.0, 0.0, 0.0), "idle faces the cursor")


func test_attacking_faces_the_aim_while_moving() -> void:
	var facing: Vector3 = Technician.facing_for(Vector3(0.0, 0.0, 5.0), Vector3(-1.0, 0.0, 0.0), true)
	assert_vec_almost(facing, Vector3(-1.0, 0.0, 0.0), "a swing or shot turns toward the aim")
