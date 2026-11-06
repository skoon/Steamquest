class_name GearPickup
extends Area3D
## A scavenged gear lying on the floor. Walking over it installs it into the most worn socket.

const SPIN_SPEED: float = 2.0
const BOB_HEIGHT: float = 0.15

var gear: GearItem
var _visual: Node3D
var _time: float = 0.0
var _collected: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.PLAYER
	monitorable = false
	if gear == null:
		gear = GameState.roll_scrap_gear()
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 0.9
	shape_node.shape = sphere
	shape_node.position = Vector3(0.0, 0.6, 0.0)
	add_child(shape_node)
	var mount: Node3D = Node3D.new()
	mount.position = Vector3(0.0, 0.7, 0.0)
	mount.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	add_child(mount)
	_visual = GearMeshFactory.build(0.35, 0.1, 9, FoundryMaterials.get_material(FoundryMaterials.Kind.RUST))
	mount.add_child(_visual)
	var glow: OmniLight3D = OmniLight3D.new()
	glow.light_color = Color(1.0, 0.7, 0.35)
	glow.light_energy = 0.8
	glow.omni_range = 2.0
	glow.position = Vector3(0.0, 0.8, 0.0)
	add_child(glow)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	_visual.rotation.y += SPIN_SPEED * delta
	_visual.get_parent_node_3d().position.y = 0.7 + sin(_time * 3.0) * BOB_HEIGHT


func _on_body_entered(body: Node3D) -> void:
	if _collected or not (body is Technician):
		return
	_collected = true
	var socket: int = GameState.install_scavenged_gear(gear)
	if socket >= 0:
		GameState.post_notice("Installed %s into %s" % [gear.gear_name, FrictionModel.socket_name(socket)])
	Fx.sparks(get_parent(), global_position + Vector3.UP * 0.7)
	Audio.play_at(&"gear_pickup", global_position)
	queue_free()
