class_name PowerRouter
extends Node3D
## The junction board for a set of JunctionSwitches. Its PowerRouting decides which plate section
## the surplus current is dumped into; the safe routing earths it all and unlocks `unlock_id`.

signal routing_changed(live_section: int)

@export var safe_positions: PackedInt32Array = PackedInt32Array([0, 0, 0])
@export var start_positions: PackedInt32Array = PackedInt32Array([0, 0, 0])
@export var section_count: int = 3
@export var unlock_id: StringName = &""
## Section names for notices, e.g. ["North", "Centre", "South"].
@export var section_names: PackedStringArray = PackedStringArray()

var routing: PowerRouting
var positions: PackedInt32Array


func _ready() -> void:
	assert(unlock_id != &"", "%s: unlock_id is required" % name)
	assert(start_positions.size() == safe_positions.size(), "%s: start and safe positions differ in length" % name)
	assert(section_names.size() == section_count, "%s: needs one name per section" % name)
	routing = PowerRouting.new(safe_positions, section_count)
	positions = start_positions.duplicate()
	assert(not routing.is_safe(positions), "%s: must not start safe" % name)


func is_solved() -> bool:
	return routing.is_safe(positions)


func live_section() -> int:
	return routing.live_section(positions)


## Turns switch `index` one notch on; returns the new live section.
func turn(index: int, at: Vector3) -> int:
	assert(index >= 0 and index < positions.size(), "PowerRouter.turn: switch %d out of range" % index)
	assert(not is_solved(), "PowerRouter.turn: already earthed")
	positions[index] = (positions[index] + 1) % PowerRouting.POSITIONS
	var section: int = live_section()
	Audio.play_at(&"switch_clunk", at)
	if section == PowerRouting.EARTH:
		GameState.unlock_door(unlock_id)
		GameState.post_notice("The current drains into the earth bank. The plates go dead - the way out is clear.")
	else:
		Audio.play_at(&"plate_crackle", at)
		GameState.post_notice("Current rerouted - the %s plates are live!" % section_names[section])
	routing_changed.emit(section)
	return section
