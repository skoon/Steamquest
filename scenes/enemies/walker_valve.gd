class_name WalkerValve
extends Area3D
## The Steam Walker's boiler valve: a bashable target that only counts while the Walker is
## overheated (SteamWalker turns `monitorable` on then, so the wrench can find it).

var walker: SteamWalker


func _ready() -> void:
	assert(walker != null, "WalkerValve: walker not set")
	collision_layer = Layers.INTERACTABLES
	collision_mask = 0
	monitoring = false
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 1.8
	shape_node.shape = sphere
	add_child(shape_node)


func receive_bash() -> void:
	walker.on_valve_bashed()
