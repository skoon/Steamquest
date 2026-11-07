class_name Propeller
extends Node3D
## An upright engine propeller on a stand. Its blades grind anything that touches the hub, and it
## blows a steady stream along its facing (local -Z) that shoves bodies in front of it.

const HIT_INTERVAL_MSEC: int = 700

@export var blade_radius: float = 1.4
@export var spin_speed: float = 9.0
@export var contact_damage: float = 14.0
@export var contact_knockback: float = 9.0
@export var blow_range: float = 7.0
@export var blow_strength: float = 4.5
## Clutter keeps this far away.
@export var radius: float = 1.8

var _blades: Node3D
var _contact: Area3D
var _stream: Area3D
var _sound_timer: float = 0.0
## Body instance id -> msec of its last blade hit, so automatons are not shredded every frame.
var _last_hit_msec: Dictionary = {}


func _ready() -> void:
	_build_visuals()
	_contact = _make_area(Vector3(blade_radius * 1.6, 2.6, 1.2), Vector3(0.0, 1.3, -0.4))
	_stream = _make_area(Vector3(blade_radius * 2.0, 2.6, blow_range), Vector3(0.0, 1.3, -blow_range * 0.5 - 0.6))


func blow_direction() -> Vector3:
	return -global_basis.z.normalized()


func _process(delta: float) -> void:
	_blades.rotation.z += spin_speed * delta


func _physics_process(delta: float) -> void:
	_sound_timer -= delta
	if _sound_timer <= 0.0:
		_sound_timer = 2.0
		Audio.play_at(&"propeller_whirr", global_position + Vector3.UP * 1.6, -4.0)
	var now: int = Time.get_ticks_msec()
	for body: Node3D in _contact.get_overlapping_bodies():
		if body.has_method("receive_hit") and now - int(_last_hit_msec.get(body.get_instance_id(), -100000)) >= HIT_INTERVAL_MSEC:
			_last_hit_msec[body.get_instance_id()] = now
			var push: Vector3 = DamageCalc.knockback(global_position, body.global_position, contact_knockback, 0.0)
			body.call("receive_hit", contact_damage, push)
	var push_dir: Vector3 = blow_direction()
	for body: Node3D in _stream.get_overlapping_bodies():
		if body.has_method("apply_push"):
			body.call("apply_push", push_dir * blow_strength)


func _make_area(box_size: Vector3, center: Vector3) -> Area3D:
	var area: Area3D = Area3D.new()
	area.collision_layer = 0
	area.collision_mask = Layers.PLAYER | Layers.ENEMIES
	area.monitorable = false
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = box_size
	shape_node.shape = box
	shape_node.position = center
	area.add_child(shape_node)
	add_child(area)
	return area


func _build_visuals() -> void:
	var iron: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.CAST_IRON)
	var brass: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.BRASS)
	var stand: BoxMesh = BoxMesh.new()
	stand.size = Vector3(0.3, 1.6, 0.3)
	Layers.add_mesh(self, stand, iron, Vector3(0.0, 0.8, 0.3))
	var housing: CylinderMesh = CylinderMesh.new()
	housing.top_radius = 0.35
	housing.bottom_radius = 0.45
	housing.height = 0.9
	var engine: MeshInstance3D = Layers.add_mesh(self, housing, brass, Vector3(0.0, 1.6, 0.45))
	engine.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	Layers.add_static_box(self, Vector3(0.6, 1.6, 0.6), Vector3(0.0, 0.8, 0.3))
	_blades = ModelLibrary.instance_fitted(ModelLibrary.PROPS, "propeller", blade_radius * 2.0, true)
	_blades.position = Vector3(0.0, 1.6, -0.05)
	add_child(_blades)
