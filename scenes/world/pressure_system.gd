class_name PressureSystem
extends Node3D
## The Pressure Exchange's room-wide steam pressure. It climbs on its own (RoomPressure), shows on
## the HUD, sounds a klaxon in the warning band (which also sets the marked BurstRoutes steaming),
## and bursts every route when it peaks. ReliefValves find it through the `pressure_system` group.

const GROUP: StringName = &"pressure_system"
const KLAXON_INTERVAL: float = 2.5

@export var rise_per_second: float = 0.016
@export var warning_ratio: float = 0.75
@export var after_burst: float = 0.4
@export var start_level: float = 0.25
@export var routes: Array[NodePath] = []

var pressure: RoomPressure
var bursts: int = 0
var _routes: Array[BurstRoute] = []
var _was_warning: bool = false
var _since_klaxon: float = 0.0


func _ready() -> void:
	assert(not routes.is_empty(), "%s: needs burst routes" % name)
	add_to_group(GROUP)
	pressure = RoomPressure.new(rise_per_second, warning_ratio, after_burst, start_level)
	for path: NodePath in routes:
		var route: BurstRoute = get_node(path) as BurstRoute
		assert(route != null, "%s: %s is not a BurstRoute" % [name, path])
		_routes.append(route)
	_emit()


func _exit_tree() -> void:
	GameState.room_pressure_changed.emit(-1.0, false)


## Vents `amount` of pressure; returns how much actually came off.
func bleed(amount: float) -> float:
	var bled: float = pressure.bleed(amount)
	_update_warning()
	_emit()
	return bled


## Skips the climb ahead (tests force a warning or a burst).
func advance(seconds: float) -> void:
	_step(seconds)


func _physics_process(delta: float) -> void:
	_step(delta)


func _step(delta: float) -> void:
	if pressure.tick(delta):
		_burst()
	_update_warning()
	if _was_warning:
		_since_klaxon += delta
		if _since_klaxon >= KLAXON_INTERVAL:
			_since_klaxon = 0.0
			_sound_klaxon()
	_emit()


func _update_warning() -> void:
	var warning: bool = pressure.is_warning()
	if warning == _was_warning:
		return
	_was_warning = warning
	for route: BurstRoute in _routes:
		route.set_warning(warning)
	if warning:
		_since_klaxon = 0.0
		_sound_klaxon()
		GameState.post_notice("PRESSURE CRITICAL - bash a relief valve before the marked pipes burst!")


func _burst() -> void:
	bursts += 1
	for route: BurstRoute in _routes:
		route.burst()
	GameState.post_notice("The pipes burst! Pressure falls back - for now.")


func _sound_klaxon() -> void:
	var player: Node3D = get_tree().get_first_node_in_group(&"player") as Node3D
	if player != null:
		Audio.play_at(&"pressure_klaxon", player.global_position + Vector3.UP * 3.0, -4.0, 0.0)


func _emit() -> void:
	GameState.room_pressure_changed.emit(pressure.level, pressure.is_warning())
