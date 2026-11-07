extends Node
## Headless check of the title screen: hover highlight, then New Game shows the loading
## screen and finishes loading level 1; then finishing level 1 shows the loading screen
## and loads level 2. Run as the main scene so autoloads exist:
##   Godot_console.exe --headless --path . res://tests/integration/title_screen_test.tscn

const TITLE_SCENE: PackedScene = preload("res://scenes/ui/title_screen.tscn")
const TEST_SAVE: String = "user://test_title_save.json"
const LOAD_TIMEOUT: float = 30.0

var _failures: PackedStringArray = PackedStringArray()


func _ready() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	print(("  PASS  " if condition else "  FAIL  ") + message)
	if not condition:
		_failures.append(message)


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().process_frame


func _seconds(time: float) -> void:
	await get_tree().create_timer(time).timeout


func _run() -> void:
	GameState.save_path = TEST_SAVE
	CampaignProgress.delete_save(TEST_SAVE)
	var title: Control = TITLE_SCENE.instantiate() as Control
	add_child(title)
	await _frames(3)
	var new_game: Button = title.get("new_game_button") as Button
	var quit_button: Button = title.find_children("*", "Button", true, false).back() as Button
	_check(new_game.has_focus(), "New Game has focus when there is no save")
	_check(new_game.scale.x > 1.0, "focused button is scaled up")

	quit_button.mouse_entered.emit()
	await _seconds(0.3)
	_check(quit_button.has_focus(), "hovering a button moves the highlight to it")
	_check(quit_button.scale.is_equal_approx(Vector2.ONE * BrassButton.HOVER_SCALE), "hovered button grows")
	_check(new_game.scale.is_equal_approx(Vector2.ONE), "previous button shrinks back")
	_check(quit_button.pivot_offset.is_equal_approx(quit_button.size * 0.5), "button grows from its centre")

	new_game.pressed.emit()
	var loading: LoadingScreen = title.get("loading_screen") as LoadingScreen
	_check(loading != null and loading.is_inside_tree(), "New Game shows the loading screen")
	if loading == null:
		_finish()
		return
	loading.change_scene_on_finish = false
	_check(loading.label.text.begins_with("Loading"), "loading screen says Loading")
	_check(new_game.disabled, "menu buttons are disabled while loading")
	var loaded: Array[PackedScene] = []
	loading.finished.connect(func(scene: PackedScene) -> void: loaded.append(scene))
	var start_angle: float = loading.gear.rotation
	var waited: float = 0.0
	while loaded.is_empty() and waited < LOAD_TIMEOUT:
		await _seconds(0.1)
		waited += 0.1
	_check(not is_equal_approx(loading.gear.rotation, start_angle), "gear turns while loading")
	_check(not loaded.is_empty(), "level loads within %d s" % LOAD_TIMEOUT)
	if not loaded.is_empty():
		_check(loaded[0].resource_path == GameState.campaign.level(0).scene_path, "loaded the first campaign level")
		_check(waited >= loading.min_display_time - 0.15, "loading screen stays up for its minimum time")
		title.queue_free()
		await _frames(2)
		await _test_level_exit_shows_loading(loaded[0])
	_finish()


func _test_level_exit_shows_loading(level_scene: PackedScene) -> void:
	var level: Node3D = level_scene.instantiate() as Node3D
	add_child(level)
	await _frames(5)
	var next_path: String = GameState.campaign.level(1).scene_path
	var player: Technician = level.get_node("Technician") as Technician
	var lift: FoundryElevator = null
	for node: Node in level.find_children("*", "Node3D", true, false):
		if node is FoundryElevator:
			lift = node as FoundryElevator
	_check(lift != null, "level 1 has an exit lift")
	if lift == null:
		return
	var camera_rig: CameraRig = get_tree().get_first_node_in_group(&"camera_rig") as CameraRig
	player.global_position = lift.global_position + Vector3.UP * 0.3
	# Snap the view as if the player had walked here, rather than mid-lerp from a teleport.
	camera_rig.global_position = player.global_position
	for i: int in 60:
		if player.is_riding_lift:
			break
		await get_tree().physics_frame
	var start_y: float = player.global_position.y
	var camera_start: Vector3 = camera_rig.global_position
	_check(player.is_riding_lift, "stepping on the lift hands it control of the Technician")
	await _seconds(lift.DESCENT_TIME * 0.6)
	_check(player.global_position.y < start_y - 0.5, "the Technician sinks with the lift")
	_check(camera_rig.global_position.is_equal_approx(camera_start), "the camera holds still while the lift descends")
	await _seconds(level.EXIT_FADE_TIME - lift.DESCENT_TIME * 0.6 + 0.2)
	_check(player.global_position.y < start_y - lift.DESCENT_DEPTH + 0.6, "the lift descends its full depth")
	var loading: LoadingScreen = level.get("loading_screen") as LoadingScreen
	_check(loading != null and loading.is_visible_in_tree(), "finishing a level shows the loading screen")
	if loading == null:
		return
	loading.change_scene_on_finish = false
	var loaded: Array[PackedScene] = []
	loading.finished.connect(func(scene: PackedScene) -> void: loaded.append(scene))
	var waited: float = 0.0
	while loaded.is_empty() and waited < LOAD_TIMEOUT:
		await _seconds(0.1)
		waited += 0.1
	_check(not loaded.is_empty() and loaded[0].resource_path == next_path, "loading screen loads the next level")
	level.queue_free()
	await _frames(2)
	Audio.stop_all()
	await _frames(5)


func _finish() -> void:
	CampaignProgress.delete_save(TEST_SAVE)
	print("")
	if _failures.is_empty():
		print("TITLE SCREEN TEST PASSED")
	else:
		printerr("TITLE SCREEN TEST FAILED (%d):" % _failures.size())
		for failure: String in _failures:
			printerr("  - " + failure)
	get_tree().quit(0 if _failures.is_empty() else 1)
