class_name LoadingScreen
extends Control
## Full-screen "Loading" card with a turning brass gear. Loads a scene on a background
## thread, then switches to it once loading finishes and the card has shown long enough
## not to flash.

signal finished(scene: PackedScene)

const GEAR_TEXTURE: Texture2D = preload("res://assets/sprites/decor/gear_brass_large.png")
const BRASS: Color = Color(0.78, 0.58, 0.26)
const BACKGROUND: Color = Color(0.06, 0.045, 0.035)
const GEAR_SIZE: float = 160.0
const SPIN_SPEED: float = 1.6
const DOT_INTERVAL: float = 0.35
const MAX_DOTS: int = 3

## Shortest time the card stays up, so a fast load doesn't flash it.
@export var min_display_time: float = 0.6
## Off for tests that want the loaded scene without replacing the running one.
@export var change_scene_on_finish: bool = true

var gear: TextureRect
var label: Label
var _scene_path: String = ""
var _elapsed: float = 0.0
var _done: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var background: ColorRect = ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var column: VBoxContainer = VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 24)
	add_child(column)

	gear = TextureRect.new()
	gear.texture = GEAR_TEXTURE
	gear.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gear.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gear.custom_minimum_size = Vector2(GEAR_SIZE, GEAR_SIZE)
	gear.pivot_offset = Vector2(GEAR_SIZE, GEAR_SIZE) * 0.5
	var gear_center: CenterContainer = CenterContainer.new()
	gear_center.add_child(gear)
	column.add_child(gear_center)

	label = Label.new()
	label.text = loading_text(0.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", BRASS)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 6)
	column.add_child(label)


## Starts loading `scene_path` in the background.
func begin(scene_path: String) -> void:
	assert(_scene_path.is_empty(), "LoadingScreen: begin() called twice")
	var error: Error = ResourceLoader.load_threaded_request(scene_path, "PackedScene")
	assert(error == OK, "LoadingScreen: cannot start loading %s (error %d)" % [scene_path, error])
	_scene_path = scene_path


func is_loading() -> bool:
	return not _scene_path.is_empty() and not _done


func _process(delta: float) -> void:
	_elapsed += delta
	gear.rotation = spin_angle(_elapsed)
	label.text = loading_text(_elapsed)
	if not is_loading():
		return
	var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(_scene_path)
	assert(status != ResourceLoader.THREAD_LOAD_FAILED and status != ResourceLoader.THREAD_LOAD_INVALID_RESOURCE,
			"LoadingScreen: loading %s failed (status %d)" % [_scene_path, status])
	if not should_finish(status == ResourceLoader.THREAD_LOAD_LOADED, _elapsed, min_display_time):
		return
	_done = true
	var scene: PackedScene = ResourceLoader.load_threaded_get(_scene_path) as PackedScene
	assert(scene != null, "LoadingScreen: %s is not a scene" % _scene_path)
	finished.emit(scene)
	if change_scene_on_finish:
		var error: Error = get_tree().change_scene_to_packed(scene)
		assert(error == OK, "LoadingScreen: cannot change scene to %s (error %d)" % [_scene_path, error])


static func spin_angle(elapsed: float) -> float:
	return fmod(elapsed * SPIN_SPEED, TAU)


## "Loading" followed by 0–3 dots that tick up over time, padded with spaces so the
## centred word doesn't shift as dots appear.
static func loading_text(elapsed: float) -> String:
	var dots: int = int(elapsed / DOT_INTERVAL) % (MAX_DOTS + 1)
	return "Loading" + ".".repeat(dots) + " ".repeat(MAX_DOTS - dots)


static func should_finish(loaded: bool, elapsed: float, min_time: float) -> bool:
	return loaded and elapsed >= min_time
