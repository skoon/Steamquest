extends SceneTree
## Headless test runner.
## Usage: Godot_console.exe --headless --path <project> --script res://tests/run_tests.gd
## Exits with code 1 if any test fails.

const TEST_DIR: String = "res://tests/"


func _initialize() -> void:
	var total: int = 0
	var failed: int = 0
	var all_failures: Array[String] = []
	for file_name: String in _test_files():
		var script: GDScript = load(TEST_DIR + file_name) as GDScript
		if script == null:
			all_failures.append("%s: failed to load script" % file_name)
			failed += 1
			continue
		for method: Dictionary in script.get_script_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			var case: TestCase = script.new() as TestCase
			if case == null:
				all_failures.append("%s: does not extend TestCase" % file_name)
				failed += 1
				break
			case.begin_test("%s::%s" % [file_name.get_basename(), method_name])
			case.before_each()
			case.call(method_name)
			total += 1
			if case.failures.is_empty():
				print("  PASS  %s::%s" % [file_name.get_basename(), method_name])
			else:
				failed += 1
				print("  FAIL  %s::%s" % [file_name.get_basename(), method_name])
				all_failures.append_array(case.failures)
	print("")
	for failure: String in all_failures:
		printerr("  - " + failure)
	print("%d tests, %d passed, %d failed" % [total, total - failed, failed])
	quit(1 if failed > 0 else 0)


func _test_files() -> PackedStringArray:
	var files: PackedStringArray = PackedStringArray()
	for file_name: String in DirAccess.get_files_at(TEST_DIR):
		if file_name.begins_with("test_") and file_name.ends_with(".gd") and file_name != "test_case.gd":
			files.append(file_name)
	files.sort()
	return files
