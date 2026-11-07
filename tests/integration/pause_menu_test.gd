extends Node
## Headless check of the Esc pause menu in a real level. Run as the main scene so autoloads exist:
##   Godot_console.exe --headless --path . res://tests/integration/pause_menu_test.tscn

const TEST_SAVE: String = "user://test_pause_save.json"

var _failures: PackedStringArray = PackedStringArray()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	print(("  PASS  " if condition else "  FAIL  ") + message)
	if not condition:
		_failures.append(message)


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().process_frame


func _press_escape() -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = &"pause"
	event.pressed = true
	Input.parse_input_event(event)
	await _frames(2)


func _run() -> void:
	GameState.save_path = TEST_SAVE
	var scene_path: String = GameState.new_campaign()
	var level: Node3D = (load(scene_path) as PackedScene).instantiate() as Node3D
	level.set("auto_advance", false)
	# This test node runs while paused; the level must not inherit that, as it wouldn't in play.
	level.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(level)
	await _frames(5)
	var menu: PauseMenu = level.get("pause_menu") as PauseMenu
	_check(menu != null and not menu.is_open(), "level has a closed pause menu")

	await _press_escape()
	_check(menu.is_open(), "Esc opens the pause menu")
	_check(get_tree().paused, "the game is paused while it is open")
	_check(menu.resume_button.has_focus(), "Resume is focused")
	var player: Technician = level.get_node("Technician") as Technician
	var paused_at: Vector3 = player.global_position
	Input.action_press("move_up")
	await _frames(10)
	Input.action_release("move_up")
	_check(player.global_position.is_equal_approx(paused_at), "the Technician doesn't move while paused")

	var tab: InputEventAction = InputEventAction.new()
	tab.action = &"toggle_log"
	tab.pressed = true
	Input.parse_input_event(tab)
	await _frames(2)
	var hud: Node = level.get_node("HUD")
	_check(not (hud.get("_log_panel") as Control).visible, "Tab doesn't open the log over the pause menu")
	await _press_escape()
	_check(not menu.is_open() and not get_tree().paused, "Esc again resumes")

	await _press_escape()
	menu.resume_button.pressed.emit()
	await _frames(2)
	_check(not menu.is_open() and not get_tree().paused, "Resume closes the menu and unpauses")

	var quit_requests: Array[bool] = []
	menu.quit_to_title.connect(func() -> void: quit_requests.append(true))
	await _press_escape()
	menu.title_button.pressed.emit()
	await _frames(2)
	_check(quit_requests.size() == 1 and not get_tree().paused, "Quit to Title unpauses and asks the level to leave")

	GameState.player_died.emit()
	await _press_escape()
	_check(not menu.is_open(), "Esc does nothing once the run is over")

	get_tree().paused = false
	level.queue_free()
	await _frames(2)
	Audio.stop_all()
	await _frames(5)
	CampaignProgress.delete_save(TEST_SAVE)
	print("")
	if _failures.is_empty():
		print("PAUSE MENU TEST PASSED")
	else:
		printerr("PAUSE MENU TEST FAILED (%d):" % _failures.size())
		for failure: String in _failures:
			printerr("  - " + failure)
	get_tree().quit(0 if _failures.is_empty() else 1)
