class_name PauseMenu
extends CanvasLayer
## Esc pauses the level and shows a small Resume / Quit overlay; Esc again resumes.
## Quitting to the title is left to the level, which owns scene changes.

signal quit_to_title

const LAYER: int = 50
const DIM: Color = Color(0.0, 0.0, 0.0, 0.55)
const PANEL_FILL: Color = Color(0.08, 0.06, 0.045, 0.96)

## Off once the run is over or the exit lift is moving, so Esc can't interrupt those.
var enabled: bool = true
var resume_button: BrassButton
var title_button: BrassButton
var _root: Control


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)

	var dim: ColorRect = ColorRect.new()
	dim.color = DIM
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	var panel_style: StyleBoxFlat = BrassButton._style(PANEL_FILL, BrassButton.BRASS, 2)
	panel_style.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	var title: Label = Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", BrassButton.BRASS)
	column.add_child(title)
	resume_button = BrassButton.new("Resume", close)
	column.add_child(resume_button)
	title_button = BrassButton.new("Quit to Title", _on_quit_to_title)
	column.add_child(title_button)
	column.add_child(BrassButton.new("Quit Game", func() -> void: get_tree().quit()))


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if is_open():
		close()
		get_viewport().set_input_as_handled()
	elif can_open():
		open()
		get_viewport().set_input_as_handled()


func is_open() -> bool:
	return _root.visible


## Not while disabled, or while something else (the log panel) already has the game paused.
func can_open() -> bool:
	return enabled and not get_tree().paused


func open() -> void:
	assert(can_open(), "PauseMenu: open() while it can't open")
	_root.visible = true
	get_tree().paused = true
	resume_button.grab_focus()


func close() -> void:
	_root.visible = false
	get_tree().paused = false


func _on_quit_to_title() -> void:
	close()
	quit_to_title.emit()
