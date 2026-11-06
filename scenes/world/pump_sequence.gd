class_name PumpSequence
extends Node3D
## Holds the combination for a set of PumpValves. Turning them in `order` unlocks `unlock_id`;
## a wrong valve resets the sequence and floods the linked pools for one tide cycle.

signal progress_changed(progress: int)

@export var order: Array[StringName] = []
@export var unlock_id: StringName = &""
@export var flood_pools: Array[NodePath] = []
@export var flood_seconds: float = 14.0

var lock: SequenceLock


func _ready() -> void:
	assert(not order.is_empty(), "%s: order is required" % name)
	assert(unlock_id != &"", "%s: unlock_id is required" % name)
	lock = SequenceLock.new(order)


func press(valve_id: StringName, at: Vector3) -> SequenceLock.Result:
	var result: SequenceLock.Result = lock.press(valve_id)
	match result:
		SequenceLock.Result.PROGRESS:
			Audio.play_at(&"pump_clunk", at)
			GameState.post_notice("The pump coughs into life (%d/%d)" % [lock.progress(), order.size()])
		SequenceLock.Result.WRONG:
			Audio.play_at(&"sequence_wrong", at)
			GameState.post_notice("Wrong valve! The pumps reverse and the cistern floods.")
			_flood()
		SequenceLock.Result.SOLVED:
			Audio.play_at(&"pump_clunk", at)
			Audio.play_at(&"valve_free", at + Vector3.UP)
			GameState.post_notice("All pumps running - the outflow lock releases.")
			GameState.unlock_door(unlock_id)
	progress_changed.emit(lock.progress())
	return result


func _flood() -> void:
	for path: NodePath in flood_pools:
		var pool: WaterPool = get_node(path) as WaterPool
		assert(pool != null, "%s: %s is not a WaterPool" % [name, path])
		pool.flood_for(flood_seconds)
