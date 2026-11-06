class_name JammedValve
extends Area3D
## A seized steam valve. Bash it with the Heavy Wrench `hits_required` times to free it,
## which unlocks the door with matching `door_id`.

@export var door_id: StringName = &""
@export var hits_required: int = 3

var is_freed: bool = false
var _hits: int = 0
var _wheel: Node3D
var _wheel_parts: Array[MeshInstance3D] = []


func _ready() -> void:
	assert(door_id != &"", "%s: door_id is required" % name)
	assert(hits_required > 0, "%s: hits_required must be positive" % name)
	collision_layer = Layers.INTERACTABLES
	collision_mask = 0
	monitoring = false
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 0.9
	shape_node.shape = sphere
	shape_node.position = Vector3(0.0, 1.2, 0.0)
	add_child(shape_node)
	_build_visuals()


func _process(delta: float) -> void:
	if is_freed:
		_wheel.rotation.x += 1.5 * delta


func receive_bash() -> void:
	if is_freed:
		return
	_hits += 1
	var tween: Tween = create_tween()
	tween.tween_property(_wheel, "rotation:x", _wheel.rotation.x + PI / 3.0, 0.15)
	if _hits >= hits_required:
		_free_valve()
	else:
		GameState.post_notice("The valve shifts... (%d/%d)" % [_hits, hits_required])


func _free_valve() -> void:
	is_freed = true
	var brass: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.BRASS)
	for part: MeshInstance3D in _wheel_parts:
		part.material_override = brass
	Fx.steam_puff(get_parent(), global_position + Vector3(0.0, 1.6, 0.0))
	Fx.steam_puff(get_parent(), global_position + Vector3(0.0, 2.4, 0.0))
	Audio.play_at(&"valve_free", global_position + Vector3(0.0, 1.6, 0.0))
	GameState.post_notice("Valve freed - steam pressure restored to the bulkhead")
	GameState.unlock_door(door_id)


func _build_visuals() -> void:
	var steel: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.DARK_STEEL)
	var rust: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.RUST)
	var pipe: CylinderMesh = CylinderMesh.new()
	pipe.top_radius = 0.18
	pipe.bottom_radius = 0.22
	pipe.height = 1.2
	Layers.add_mesh(self, pipe, steel, Vector3(0.0, 0.6, 0.0))
	var housing: SphereMesh = SphereMesh.new()
	housing.radius = 0.3
	housing.height = 0.6
	Layers.add_mesh(self, housing, FoundryMaterials.get_material(FoundryMaterials.Kind.COPPER_OXIDIZED), Vector3(0.0, 1.2, 0.0))

	_wheel = Node3D.new()
	_wheel.position = Vector3(0.0, 1.2, 0.0)
	add_child(_wheel)
	var rim: TorusMesh = TorusMesh.new()
	rim.inner_radius = 0.45
	rim.outer_radius = 0.56
	var rim_instance: MeshInstance3D = Layers.add_mesh(_wheel, rim, rust, Vector3(0.35, 0.0, 0.0))
	rim_instance.rotation = Vector3(0.0, 0.0, PI * 0.5)
	_wheel_parts.append(rim_instance)
	var spoke: BoxMesh = BoxMesh.new()
	spoke.size = Vector3(0.06, 1.0, 0.08)
	for i: int in 3:
		var spoke_instance: MeshInstance3D = Layers.add_mesh(_wheel, spoke, rust, Vector3(0.35, 0.0, 0.0))
		spoke_instance.rotation = Vector3(PI / 3.0 * float(i), 0.0, 0.0)
		_wheel_parts.append(spoke_instance)

	Layers.add_static_cylinder(self, 0.3, 1.4, Vector3.ZERO)
