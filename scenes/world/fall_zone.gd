class_name FallZone
extends Area3D
## A catch volume far below an open-air level. Automatons that drop into it are lost; the
## Technician is winched back up to the entrance of the room they fell from, minus some hull.

@export var size: Vector3 = Vector3(200.0, 4.0, 80.0)
@export var fall_damage: float = 30.0
@export var builder_path: NodePath

var builder: FoundryBuilder


func _ready() -> void:
	builder = get_node(builder_path) as FoundryBuilder
	assert(builder != null, "%s: builder_path must point at the FoundryBuilder" % name)
	collision_layer = 0
	collision_mask = Layers.PLAYER | Layers.ENEMIES
	monitorable = false
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	shape_node.shape = box
	add_child(shape_node)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body is Technician:
		var technician: Technician = body as Technician
		technician.recover_from_fall(fall_damage, builder.room_entrance(GameState.current_room))
		GameState.post_notice("Your safety line catches you - winched back aboard, a little dented.")
		Audio.play_at(&"winch_crank", technician.global_position)
	elif body is EnemyBase:
		(body as EnemyBase).fall()
