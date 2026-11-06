class_name RotatingCog
extends Node3D
## Procedural spinning cog. Flat cogs on the floor can be hazards that grind the Technician.

@export var radius: float = 2.0
@export var teeth: int = 14
@export var thickness: float = 0.35
## Radians per second; negative spins the other way.
@export var spin_speed: float = 0.8
## Upright cogs spin around the local Z axis (wall-mounted decoration).
@export var upright: bool = false
@export var material_kind: FoundryMaterials.Kind = FoundryMaterials.Kind.BRASS
@export_group("Hazard")
@export var is_hazard: bool = false
@export var hazard_damage: float = 12.0
@export var hazard_knockback: float = 10.0

var _cog: Node3D
var _hazard_area: Area3D


func _ready() -> void:
	var mount: Node3D = Node3D.new()
	if upright:
		mount.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	add_child(mount)
	_cog = GearMeshFactory.build(radius, thickness, teeth, FoundryMaterials.get_material(material_kind))
	mount.add_child(_cog)
	if is_hazard:
		_build_hazard()


func _process(delta: float) -> void:
	_cog.rotation.y += spin_speed * delta


func _physics_process(_delta: float) -> void:
	if not is_hazard:
		return
	for body: Node3D in _hazard_area.get_overlapping_bodies():
		var technician: Technician = body as Technician
		if technician == null:
			continue
		var push: Vector3 = DamageCalc.knockback(global_position, technician.global_position, hazard_knockback, 0.0)
		technician.receive_hit(hazard_damage, push)


func _build_hazard() -> void:
	_hazard_area = Area3D.new()
	_hazard_area.collision_layer = 0
	_hazard_area.collision_mask = Layers.PLAYER
	_hazard_area.monitorable = false
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var cylinder: CylinderShape3D = CylinderShape3D.new()
	cylinder.radius = radius * 1.05
	cylinder.height = 1.2
	shape_node.shape = cylinder
	shape_node.position = Vector3(0.0, 0.6, 0.0)
	_hazard_area.add_child(shape_node)
	add_child(_hazard_area)
	var warning: MeshInstance3D = MeshInstance3D.new()
	var ring: TorusMesh = TorusMesh.new()
	ring.inner_radius = radius * 1.12
	ring.outer_radius = radius * 1.2
	warning.mesh = ring
	warning.material_override = FoundryMaterials.emissive(Color(1.0, 0.55, 0.1), 1.2)
	warning.position = Vector3(0.0, -thickness * 0.4, 0.0)
	add_child(warning)
