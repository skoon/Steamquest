extends Node3D
## Root of every campaign level: builds the level geometry, registers the level with GameState,
## moves on to the next level when its exit is used, and restarts after death or victory.

const TITLE_SCENE: String = "res://scenes/ui/title_screen.tscn"
const EXIT_FADE_TIME: float = 1.2
const LOADING_SCENE: PackedScene = preload("res://scenes/ui/loading_screen.tscn")
## Above the HUD so the loading card covers everything.
const LOADING_LAYER: int = 100

## Tests turn this off so using an exit or quitting to the title doesn't replace the test scene.
@export var auto_advance: bool = true
## Dark levels dim the sky and ambient light and hand the Technician a lantern.
@export var dark_level: bool = false

@onready var builder: FoundryBuilder = $Navigation

var loading_screen: LoadingScreen
var pause_menu: PauseMenu
var _run_over: bool = false


## Registered before the children's _ready, so doors, pickups and the rig read this level's fresh
## (or checkpoint-restored) state rather than whatever the previous attempt left behind.
func _enter_tree() -> void:
	GameState.enter_level(scene_file_path)


func _ready() -> void:
	builder.build()
	var ambience: FoundryAmbience = FoundryAmbience.new()
	ambience.name = "Ambience"
	add_child(ambience)
	pause_menu = PauseMenu.new()
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)
	pause_menu.quit_to_title.connect(_on_quit_to_title)
	GameState.player_died.connect(_on_run_over)
	GameState.victory.connect(_on_run_over)
	GameState.level_completed.connect(_on_level_completed)
	if dark_level:
		_darken()


const DARK_AMBIENT_SCALE: float = 0.12
const DARK_SUN_SCALE: float = 0.05


func _darken() -> void:
	var environment: Environment = ($WorldEnvironment as WorldEnvironment).environment.duplicate() as Environment
	environment.ambient_light_energy *= DARK_AMBIENT_SCALE
	($WorldEnvironment as WorldEnvironment).environment = environment
	($Sun as DirectionalLight3D).light_energy *= DARK_SUN_SCALE
	($Technician as Technician).set_lantern(true)


func _on_run_over() -> void:
	_run_over = true
	pause_menu.enabled = false


func _on_quit_to_title() -> void:
	if auto_advance:
		_change_scene(TITLE_SCENE)


func _on_level_completed(next_scene_path: String) -> void:
	pause_menu.enabled = false
	if not auto_advance:
		return
	var tween: Tween = create_tween()
	tween.tween_interval(EXIT_FADE_TIME)
	tween.tween_callback(func() -> void: _show_loading(next_scene_path))


## Covers the level with the loading screen, which switches to the next level once it loads.
func _show_loading(next_scene_path: String) -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = LOADING_LAYER
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	loading_screen = LOADING_SCENE.instantiate() as LoadingScreen
	layer.add_child(loading_screen)
	loading_screen.begin(next_scene_path)


func _unhandled_input(event: InputEvent) -> void:
	if not (_run_over and event.is_action_pressed("restart")):
		return
	if GameState.is_victorious:
		get_tree().paused = false
		GameState.reset()
		_change_scene(TITLE_SCENE)
	else:
		restart_level()


## Reloads this level; GameState.enter_level then restores the checkpoint taken when it began.
func restart_level() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _change_scene(path: String) -> void:
	var error: Error = get_tree().change_scene_to_file(path)
	assert(error == OK, "Level: cannot change scene to %s (error %d)" % [path, error])
