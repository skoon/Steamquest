class_name TestCase
extends RefCounted
## Minimal assertion base for the headless test runner. Test methods are named `test_*`.

var failures: Array[String] = []
var _current_test: String = ""


func begin_test(test_name: String) -> void:
	_current_test = test_name


## Override for per-test setup.
func before_each() -> void:
	return


func fail(message: String) -> void:
	failures.append("%s: %s" % [_current_test, message])


func assert_true(condition: bool, message: String) -> void:
	if not condition:
		fail(message)


func assert_false(condition: bool, message: String) -> void:
	if condition:
		fail(message)


func assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		fail("%s (expected %s, got %s)" % [message, str(expected), str(actual)])


func assert_almost(actual: float, expected: float, message: String, epsilon: float = 0.0001) -> void:
	if absf(actual - expected) > epsilon:
		fail("%s (expected %f, got %f)" % [message, expected, actual])


func assert_vec_almost(actual: Vector3, expected: Vector3, message: String, epsilon: float = 0.0001) -> void:
	if not actual.is_equal_approx(expected) and actual.distance_to(expected) > epsilon:
		fail("%s (expected %s, got %s)" % [message, str(expected), str(actual)])
