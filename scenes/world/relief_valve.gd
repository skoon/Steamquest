class_name ReliefValve
extends Area3D
## A relief stack with a hand wheel. One wrench blow vents `bleed_amount` of the room pressure,
## then the valve needs `reseal_time` seconds to reseal before it can vent again.

const COLOR_READY: Color = Color(0.3, 1.0, 0.45)
const COLOR_RESEALING: Color = Color(1.0, 0.3, 0.12)

@export var bleed_amount: float = 0.3
@export var reseal_time: float = 6.0
## FoundryBuilder keeps clutter this far away.
@export var radius: float = 1.2

var reseal_left: float = 0.0
var _wheel: Node3D
var _lamp: StandardMaterial3D
var _plume: GPUParticles3D


func _ready() -> void:
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


func is_ready_to_vent() -> bool:
	return reseal_left <= 0.0


func _process(delta: float) -> void:
	if reseal_left <= 0.0:
		return
	reseal_left = maxf(reseal_left - delta, 0.0)
	if reseal_left <= 0.0:
		_plume.emitting = false
		_set_lamp(COLOR_READY)


func receive_bash() -> void:
	if not is_ready_to_vent():
		GameState.post_notice("The relief valve is still resealing (%.0fs)." % ceilf(reseal_left))
		return
	var system: PressureSystem = get_tree().get_first_node_in_group(PressureSystem.GROUP) as PressureSystem
	assert(system != null, "%s: no PressureSystem in the level" % name)
	var bled: float = system.bleed(bleed_amount)
	reseal_left = reseal_time
	_plume.emitting = true
	_set_lamp(COLOR_RESEALING)
	var tween: Tween = create_tween()
	tween.tween_property(_wheel, "rotation:x", _wheel.rotation.x + PI, 0.3)
	Audio.play_at(&"relief_vent", global_position + Vector3.UP * 2.5)
	GameState.post_notice("Relief valve vents - pressure down %d%%." % roundi(bled * 100.0))


func _set_lamp(color: Color) -> void:
	_lamp.albedo_color = color
	_lamp.emission = color


func _build_visuals() -> void:
	var iron: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.CAST_IRON)
	var copper: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.COPPER_OXIDIZED)
	var brass: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.BRASS)
	var stack: CylinderMesh = CylinderMesh.new()
	stack.top_radius = 0.28
	stack.bottom_radius = 0.34
	stack.height = 3.2
	Layers.add_mesh(self, stack, copper, Vector3(0.0, 1.6, 0.0))
	var cap: CylinderMesh = CylinderMesh.new()
	cap.top_radius = 0.42
	cap.bottom_radius = 0.3
	cap.height = 0.3
	Layers.add_mesh(self, cap, iron, Vector3(0.0, 3.3, 0.0))
	_wheel = Node3D.new()
	_wheel.position = Vector3(0.35, 1.2, 0.0)
	add_child(_wheel)
	var rim: TorusMesh = TorusMesh.new()
	rim.inner_radius = 0.4
	rim.outer_radius = 0.5
	var rim_instance: MeshInstance3D = Layers.add_mesh(_wheel, rim, brass, Vector3.ZERO)
	rim_instance.rotation = Vector3(0.0, 0.0, PI * 0.5)
	var spoke: BoxMesh = BoxMesh.new()
	spoke.size = Vector3(0.06, 0.9, 0.08)
	for i: int in 3:
		var spoke_instance: MeshInstance3D = Layers.add_mesh(_wheel, spoke, brass, Vector3.ZERO)
		spoke_instance.rotation = Vector3(PI / 3.0 * float(i), 0.0, 0.0)
	_lamp = FoundryMaterials.emissive(COLOR_READY, 3.0)
	var bulb: SphereMesh = SphereMesh.new()
	bulb.radius = 0.12
	bulb.height = 0.24
	Layers.add_mesh(self, bulb, _lamp, Vector3(0.0, 2.4, 0.36))
	_plume = Fx.make_steam_emitter(50, 1.4, 6.0, 10.0)
	_plume.position = Vector3(0.0, 3.5, 0.0)
	_plume.emitting = false
	add_child(_plume)
	Layers.add_static_cylinder(self, 0.34, 3.2, Vector3.ZERO)
