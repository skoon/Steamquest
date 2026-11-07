class_name Conveyor
extends Area3D
## A conveyor belt laid along local X. Anything standing on it (the Technician, automatons) is
## carried along at `speed` metres per second; `direction` -1 runs it the other way.

const ROLLER_SPACING: float = 1.2

## Belt footprint (length along local X, width along local Z).
@export var size: Vector2 = Vector2(12.0, 2.4)
@export var speed: float = 3.0
@export var direction: float = 1.0
## FoundryBuilder keeps clutter off the belt.
@export var radius: float = 1.0

var _belt_material: StandardMaterial3D
var _sound_timer: float = 0.0


func _ready() -> void:
	assert(direction == 1.0 or direction == -1.0, "%s: direction must be 1 or -1" % name)
	collision_layer = 0
	collision_mask = Layers.PLAYER | Layers.ENEMIES
	monitorable = false
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(size.x, 1.0, size.y)
	shape_node.shape = box
	shape_node.position = Vector3(0.0, 0.5, 0.0)
	add_child(shape_node)
	_build_visuals()


## World-space carry velocity.
func carry_velocity() -> Vector3:
	var along: Vector3 = global_basis.x.normalized() * direction
	return Vector3(along.x, 0.0, along.z) * speed


## Circles (x, z, radius) covering the belt, so FoundryBuilder keeps clutter off it.
func keep_clear_zones() -> PackedVector3Array:
	var zones: PackedVector3Array = PackedVector3Array()
	var count: int = maxi(int(ceil(size.x / 1.5)), 1)
	for i: int in count + 1:
		var point: Vector3 = to_global(Vector3(-size.x * 0.5 + size.x * float(i) / float(count), 0.0, 0.0))
		zones.append(Vector3(point.x, point.z, size.y * 0.5 + 0.6))
	return zones


func _process(delta: float) -> void:
	_belt_material.uv1_offset.x -= direction * speed * delta / size.x * 4.0


func _physics_process(delta: float) -> void:
	var carry: Vector3 = carry_velocity()
	var anyone: bool = false
	for body: Node3D in get_overlapping_bodies():
		if body.has_method("apply_push") and body.global_position.y < global_position.y + 0.6:
			body.call("apply_push", carry)
			anyone = anyone or body is Technician
	_sound_timer -= delta
	if anyone and _sound_timer <= 0.0:
		_sound_timer = 1.4
		Audio.play_at(&"conveyor_rattle", global_position + Vector3.UP * 0.4, -4.0)


func _build_visuals() -> void:
	var iron: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.CAST_IRON)
	var brass: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.BRASS)
	_belt_material = StandardMaterial3D.new()
	_belt_material.albedo_texture = _stripe_texture()
	_belt_material.albedo_color = Color(0.45, 0.42, 0.38)
	_belt_material.roughness = 0.85
	_belt_material.uv1_scale = Vector3(size.x / 4.0, 1.0, 1.0)
	var belt: BoxMesh = BoxMesh.new()
	belt.size = Vector3(size.x, 0.06, size.y - 0.3)
	var belt_instance: MeshInstance3D = Layers.add_mesh(self, belt, _belt_material, Vector3(0.0, 0.12, 0.0))
	belt_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var rail: BoxMesh = BoxMesh.new()
	rail.size = Vector3(size.x, 0.2, 0.15)
	for side: float in [-1.0, 1.0]:
		Layers.add_mesh(self, rail, iron, Vector3(0.0, 0.1, side * (size.y * 0.5 - 0.08)))
	var arrow: BoxMesh = BoxMesh.new()
	arrow.size = Vector3(0.5, 0.02, 0.12)
	var paint: StandardMaterial3D = FoundryMaterials.emissive(Color(1.0, 0.6, 0.15), 0.6)
	var count: int = maxi(int(size.x / ROLLER_SPACING), 1)
	for i: int in count:
		var x: float = -size.x * 0.5 + (float(i) + 0.5) * size.x / float(count)
		var roller: CylinderMesh = CylinderMesh.new()
		roller.top_radius = 0.08
		roller.bottom_radius = 0.08
		roller.height = size.y - 0.2
		var roller_instance: MeshInstance3D = Layers.add_mesh(self, roller, brass, Vector3(x, 0.07, 0.0))
		roller_instance.rotation = Vector3(PI * 0.5, 0.0, 0.0)
		if i % 3 == 1:
			for side: float in [-1.0, 1.0]:
				var stroke: MeshInstance3D = Layers.add_mesh(self, arrow, paint, Vector3(x, 0.21, side * (size.y * 0.5 - 0.08)))
				stroke.rotation = Vector3(0.0, direction * side * 0.5, 0.0)


static func _stripe_texture() -> GradientTexture2D:
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 0.55, 1.0])
	gradient.colors = PackedColorArray([Color(0.35, 0.33, 0.3), Color(0.35, 0.33, 0.3), Color(0.12, 0.11, 0.1), Color(0.12, 0.11, 0.1)])
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 32
	texture.height = 4
	return texture
