class_name PowerRouting
extends RefCounted
## Junction-switch routing: each switch has `POSITIONS` settings, and the combination decides
## which plate section the surplus current is dumped into. Exactly one combination (`safe`) sends it
## to the earth bank (section -1), leaving every section dead so the exit can open.

const POSITIONS: int = 3
const EARTH: int = -1

var safe: PackedInt32Array
var section_count: int


func _init(p_safe: PackedInt32Array, p_section_count: int) -> void:
	assert(p_safe.size() > 0, "PowerRouting: needs at least one switch")
	assert(p_section_count > 0, "PowerRouting: needs at least one section")
	for position: int in p_safe:
		assert(position >= 0 and position < POSITIONS, "PowerRouting: safe position out of range")
	safe = p_safe
	section_count = p_section_count


func is_safe(positions: PackedInt32Array) -> bool:
	return positions == safe


## The live section (0..section_count-1) for these positions, or EARTH when safe.
## Unsafe combinations spread over the sections by how far each switch is from its safe setting.
func live_section(positions: PackedInt32Array) -> int:
	assert(positions.size() == safe.size(), "PowerRouting.live_section: wrong number of switches")
	if is_safe(positions):
		return EARTH
	var code: int = 0
	for i: int in positions.size():
		code = code * POSITIONS + posmod(positions[i] - safe[i], POSITIONS)
	return code % section_count
