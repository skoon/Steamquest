class_name PlatePattern
extends RefCounted
## A sweep across `rows` rows of floor plates: each row is live for `live_time`, rows go live one
## after another every `step_time` seconds, and each row flickers for `warning_time` first.
## After the last row the sweep waits `rest_time`, then starts again.

enum State { OFF, WARNING, LIVE }

var rows: int
var step_time: float
var live_time: float
var warning_time: float
var rest_time: float
var reverse: bool
var phase_offset: float


func _init(p_rows: int, p_step_time: float, p_live_time: float, p_warning_time: float, p_rest_time: float, p_reverse: bool = false, p_phase_offset: float = 0.0) -> void:
	assert(p_rows > 0, "PlatePattern: needs at least one row")
	assert(p_step_time > 0.0 and p_live_time > 0.0 and p_warning_time >= 0.0 and p_rest_time >= 0.0, "PlatePattern: bad timings")
	rows = p_rows
	step_time = p_step_time
	live_time = p_live_time
	warning_time = p_warning_time
	rest_time = p_rest_time
	reverse = p_reverse
	phase_offset = p_phase_offset


func period() -> float:
	return warning_time + float(rows - 1) * step_time + live_time + rest_time


func state_at(row: int, time: float) -> State:
	assert(row >= 0 and row < rows, "PlatePattern.state_at: row %d out of range" % row)
	var order: int = rows - 1 - row if reverse else row
	var t: float = fposmod(time + phase_offset, period())
	var live_start: float = warning_time + float(order) * step_time
	if t >= live_start and t < live_start + live_time:
		return State.LIVE
	if t >= live_start - warning_time and t < live_start:
		return State.WARNING
	return State.OFF
