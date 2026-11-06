extends Control
## Title screen: start a new campaign, continue from the last level reached, or quit.

const BRASS: Color = Color(0.78, 0.58, 0.26)
const TEXT: Color = Color(1.0, 0.9, 0.72)
const BACKGROUND: Color = Color(0.06, 0.045, 0.035)

var continue_button: Button
var new_game_button: Button


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

	continue_button = _button("Continue", _on_continue)
	continue_button.visible = GameState.has_save()
	column.add_child(_centered(continue_button))
	new_game_button = _button("New Game", _on_new_game)
	column.add_child(_centered(new_game_button))
	column.add_child(_centered(_button("Quit", _on_quit)))
	(continue_button if continue_button.visible else new_game_button).grab_focus.call_deferred()


func _on_continue() -> void:
	_go(GameState.continue_campaign())


func _on_new_game() -> void:
	_go(GameState.new_campaign())


func _on_quit() -> void:
	get_tree().quit()


func _go(scene_path: String) -> void:
	var error: Error = get_tree().change_scene_to_file(scene_path)
	assert(error == OK, "TitleScreen: cannot load %s (error %d)" % [scene_path, error])


func _label(text: String, size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 6)
	return label


func _button(text: String, handler: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(260, 48)
	button.add_theme_font_size_override("font_size", 22)
	var normal: StyleBoxFlat = _style(Color(0.14, 0.1, 0.07))
	var hover: StyleBoxFlat = _style(Color(0.26, 0.18, 0.1))
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_color_override("font_color", TEXT)
	button.pressed.connect(handler)
	return button


func _centered(control: Control) -> CenterContainer:
	var center: CenterContainer = CenterContainer.new()
	center.add_child(control)
	return center


func _style(fill: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = BRASS
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	return style
