class_name Layers
extends RefCounted
## Physics layer bitmasks (names configured in project.godot).

const ENVIRONMENT: int = 1
const PLAYER: int = 2
const ENEMIES: int = 4
const PLAYER_HITBOXES: int = 8
const INTERACTABLES: int = 16

## Static bodies in this group are parsed when the foundry navigation mesh is baked.
const NAV_GEOMETRY_GROUP: StringName = &"navigation_geometry"


## Adds a StaticBody3D with a cylinder collider on the Environment layer, registered for nav baking.
static func add_static_cylinder(parent: Node3D, radius: float, height: float, offset: Vector3) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.collision_layer = ENVIRONMENT
	body.collision_mask = 0
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var shape: CylinderShape3D = CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	shape_node.shape = shape
	shape_node.position = offset + Vector3(0.0, height * 0.5, 0.0)
	body.add_child(shape_node)
	body.add_to_group(NAV_GEOMETRY_GROUP)
	parent.add_child(body)
	return body


## Adds a StaticBody3D with a box collider on the Environment layer, registered for nav baking.
static func add_static_box(parent: Node3D, size: Vector3, center: Vector3) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.collision_layer = ENVIRONMENT
	body.collision_mask = 0
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	shape_node.shape = shape
	shape_node.position = center
	body.add_child(shape_node)
	body.add_to_group(NAV_GEOMETRY_GROUP)
	parent.add_child(body)
	return body


## Convenience: MeshInstance3D with a primitive mesh and material at a local position.
static func add_mesh(parent: Node3D, mesh: Mesh, material: Material, position: Vector3) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	parent.add_child(instance)
	return instance
