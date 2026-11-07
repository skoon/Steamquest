class_name BrassButton
extends Button
## Menu button in the brass-and-iron style: lights up and grows when hovered or focused.
## Hovering also takes keyboard focus, so mouse and keyboard share one highlight.

const BRASS: Color = Color(0.78, 0.58, 0.26)
const TEXT: Color = Color(1.0, 0.9, 0.72)
const HIGHLIGHT: Color = Color(1.0, 0.82, 0.42)
const HOVER_SCALE: float = 1.08
const HOVER_TWEEN_TIME: float = 0.1


func _init(label: String, handler: Callable) -> void:
	text = label
	custom_minimum_size = Vector2(260, 48)
	add_theme_font_size_override("font_size", 22)
	var normal: StyleBoxFlat = _style(Color(0.14, 0.1, 0.07), BRASS, 2)
	var hover: StyleBoxFlat = _style(Color(0.34, 0.23, 0.11), HIGHLIGHT, 3)
	var pressed_style: StyleBoxFlat = _style(Color(0.22, 0.15, 0.08), HIGHLIGHT, 3)
	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("focus", hover)
	add_theme_stylebox_override("pressed", pressed_style)
	add_theme_stylebox_override("disabled", normal)
	add_theme_color_override("font_color", TEXT)
	for state: String in ["font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		add_theme_color_override(state, HIGHLIGHT)
	add_theme_color_override("font_disabled_color", TEXT)
	mouse_entered.connect(func() -> void:
		if not disabled:
			grab_focus())
	focus_entered.connect(func() -> void: _tween_scale(HOVER_SCALE))
	focus_exited.connect(func() -> void: _tween_scale(1.0))
	resized.connect(func() -> void: pivot_offset = size * 0.5)
	pressed.connect(handler)


func _tween_scale(target: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * target, HOVER_TWEEN_TIME)


static func _style(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(6)
	return style
