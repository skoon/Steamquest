extends Control
## Title screen: start a new campaign, continue from the last level reached, or quit.

const BRASS: Color = BrassButton.BRASS
const TEXT: Color = BrassButton.TEXT
const BACKGROUND: Color = Color(0.06, 0.045, 0.035)
const LOADING_SCENE: PackedScene = preload("res://scenes/ui/loading_screen.tscn")

var continue_button: Button
var new_game_button: Button
var loading_screen: LoadingScreen


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var background: ColorRect = ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var column: VBoxContainer = VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 14)
	add_child(column)

	column.add_child(_label("THE GOLDEN GEAR", 64, BRASS))
	column.add_child(_label("A descent into the Hargreaves Foundry", 20, TEXT))
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	column.add_child(spacer)

	continue_button = BrassButton.new("Continue", _on_continue)
	continue_button.visible = GameState.has_save()
	column.add_child(_centered(continue_button))
	new_game_button = BrassButton.new("New Game", _on_new_game)
	column.add_child(_centered(new_game_button))
	column.add_child(_centered(BrassButton.new("Quit", _on_quit)))
	(continue_button if continue_button.visible else new_game_button).grab_focus.call_deferred()


func _on_continue() -> void:
	_go(GameState.continue_campaign())


func _on_new_game() -> void:
	_go(GameState.new_campaign())


func _on_quit() -> void:
	get_tree().quit()


func _go(scene_path: String) -> void:
	for button: Button in find_children("*", "Button", true, false):
		button.disabled = true
	loading_screen = LOADING_SCENE.instantiate() as LoadingScreen
	add_child(loading_screen)
	loading_screen.begin(scene_path)


func _label(text: String, size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 6)
	return label


func _centered(control: Control) -> CenterContainer:
	var center: CenterContainer = CenterContainer.new()
	center.add_child(control)
	return center
