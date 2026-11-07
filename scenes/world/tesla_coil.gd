class_name TeslaCoil
extends StaticBody3D
## A charged generator coil. A rivet into it overloads it: a burst of arcs knocks every Tesla Drone
## within `burst_radius` out of the air for `stun_seconds` and scorches nearby arc turrets.
## It then needs `recharge_time` before it can be overloaded again.

const COIL_HEIGHT: float = 2.4

@export var burst_radius: float = 6.0
@export var stun_seconds: float = 3.0
@export var turret_damage: float = 30.0
@export var recharge_time: float = 12.0
## Clutter keeps this far away.
@export var radius: float = 1.2

var _charge_wait: float = 0.0
var _light: OmniLight3D
var _sprite: CharacterModel
var _time: float = 0.0


func _ready() -> void:
	collision_layer = Layers.ENVIRONMENT
	collision_mask = 0
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var cylinder: CylinderShape3D = CylinderShape3D.new()
	cylinder.radius = 0.6
	cylinder.height = 2.6
	shape_node.shape = cylinder
	shape_node.position = Vector3(0.0, 1.3, 0.0)
	add_child(shape_node)
	_build_visuals()


func is_charged() -> bool:
	return _charge_wait <= 0.0


func receive_projectile_hit(_damage: float, _knockback: Vector3) -> void:
	if not is_charged():
		Fx.sparks(get_parent(), global_position + Vector3.UP * 1.8)
		return
	overload()


func overload() -> void:
	_charge_wait = recharge_time
	var center: Vector3 = global_position + Vector3.UP * 2.0
	Audio.play_at(&"coil_overload", center)
	Fx.arc_sparks(get_parent(), center)
	var stunned: int = 0
	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy: EnemyBase = node as EnemyBase
		if enemy == null or enemy.is_dead or _flat_distance(enemy.global_position) > burst_radius:
			continue
		if enemy is TeslaDrone:
			(enemy as TeslaDrone).stun(stun_seconds)
			stunned += 1
		elif enemy is ArcTurret:
			enemy.receive_hit(turret_damage, Vector3.ZERO)
		Fx.arc_sparks(get_parent(), enemy.global_position + Vector3.UP * 1.2)
	GameState.post_notice("The coil overloads!" + (" %d drone%s knocked out of the air." % [stunned, "" if stunned == 1 else "s"] if stunned > 0 else ""))


func _flat_distance(point: Vector3) -> float:
	return Vector2(point.x - global_position.x, point.z - global_position.z).length()


func _process(delta: float) -> void:
	_time += delta
	if _charge_wait > 0.0:
		_charge_wait = maxf(_charge_wait - delta, 0.0)
		_light.light_energy = 0.2
		_sprite.modulate = Color(0.55, 0.55, 0.6)
		if _charge_wait == 0.0:
			Audio.play_at(&"turret_charge", global_position + Vector3.UP * 2.0)
	else:
		_light.light_energy = 1.6 + sin(_time * 9.0) * 0.5
		_sprite.modulate = Color.WHITE


func _build_visuals() -> void:
	var base: CylinderMesh = CylinderMesh.new()
	base.top_radius = 0.6
	base.bottom_radius = 0.75
	base.height = 0.3
	Layers.add_mesh(self, base, FoundryMaterials.get_material(FoundryMaterials.Kind.DARK_STEEL), Vector3(0.0, 0.15, 0.0))
	_sprite = CharacterModel.new()
	_sprite.model_pack = ModelLibrary.PROPS
	_sprite.model_name = "tesla_coil"
	_sprite.model_height = COIL_HEIGHT
	_sprite.rig = CharacterModel.Rig.STATIC
	_sprite.face_movement = false
	_sprite.position = Vector3(0.0, 0.3, 0.0)
	add_child(_sprite)
	_light = OmniLight3D.new()
	_light.light_color = Color(0.5, 0.85, 1.0)
	_light.omni_range = 6.0
	_light.position = Vector3(0.0, 2.6, 0.0)
	add_child(_light)
