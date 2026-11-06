class_name PressureGauge
extends Control
## Brass dial showing Steam Pressure with a sweeping needle.

const START_ANGLE: float = deg_to_rad(135.0)
const SWEEP: float = deg_to_rad(270.0)

var value: float = 100.0
var max_value: float = 100.0


func _init() -> void:
	custom_minimum_size = Vector2(116, 116)


func set_pressure(current: float, maximum: float) -> void:
	assert(maximum > 0.0, "PressureGauge.set_pressure: maximum must be positive")
	value = current
	max_value = maximum
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.5 - 4.0
	draw_circle(center, radius + 3.0, Color(0.55, 0.4, 0.18))
	draw_circle(center, radius, Color(0.1, 0.08, 0.06))
	draw_arc(center, radius - 9.0, START_ANGLE, START_ANGLE + SWEEP, 48, Color(0.25, 0.2, 0.15), 8.0)
	var ratio: float = clampf(value / max_value, 0.0, 1.0)
	var fill_color: Color = Color(0.95, 0.35, 0.2) if ratio < 0.25 else Color(0.95, 0.75, 0.35)
	if ratio > 0.0:
		draw_arc(center, radius - 9.0, START_ANGLE, START_ANGLE + SWEEP * ratio, 48, fill_color, 8.0)
	for i: int in 11:
		var tick_angle: float = START_ANGLE + SWEEP * float(i) / 10.0
		var direction: Vector2 = Vector2(cos(tick_angle), sin(tick_angle))
		draw_line(center + direction * (radius - 20.0), center + direction * (radius - 15.0), Color(0.85, 0.7, 0.45), 2.0)
	var needle_angle: float = START_ANGLE + SWEEP * ratio
	var needle: Vector2 = Vector2(cos(needle_angle), sin(needle_angle)) * (radius - 18.0)
	draw_line(center, center + needle, Color(0.95, 0.25, 0.15), 3.0)
	draw_circle(center, 6.0, Color(0.78, 0.58, 0.26))
	var font: Font = get_theme_default_font()
	var text: String = "%d" % int(round(value))
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 18)
	draw_string(font, center + Vector2(-text_size.x * 0.5, radius * 0.55), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color(1.0, 0.9, 0.7))
	var label: String = "STEAM PSI"
	var label_size: Vector2 = font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, 10)
	draw_string(font, center + Vector2(-label_size.x * 0.5, radius * 0.8), label, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(0.8, 0.65, 0.4))
