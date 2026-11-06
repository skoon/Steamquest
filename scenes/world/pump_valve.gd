class_name PumpValve
extends Interactable
## One valve of a pump combination. Turning it reports to its PumpSequence; its lamp shows
## whether it is part of the run turned correctly so far.

const LAMP_IDLE: Color = Color(0.35, 0.12, 0.06)
const LAMP_ON: Color = Color(0.3, 1.0, 0.45)

@export var valve_id: StringName = &""
## Stamped on the plate above the valve, and named in the order terminal.
@export var label: String = "I"
@export var sequence_path: NodePath
## FoundryBuilder keeps clutter this far away.
@export var radius: float = 1.0

var sequence: PumpSequence
var _wheel: Node3D
var _lamp: StandardMaterial3D
var _lamp_light: OmniLight3D
var _position_in_order: int = -1


func _ready() -> void:
	assert(valve_id != &"", "%s: valve_id is required" % name)
	sequence = get_node(sequence_path) as PumpSequence
	assert(sequence != null, "%s: sequence_path must point at a PumpSequence" % name)
	_position_in_order = sequence.order.find(valve_id)
	sequence.progress_changed.connect(_on_progress_changed)
	add_trigger_sphere(1.3, 1.0)
	_build_visuals()


func get_prompt() -> String:
	return "[F] Turn pump valve %s" % label


func can_interact() -> bool:
	return not sequence.lock.is_solved()


func interact(_technician: Node3D) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_wheel, "rotation:z", _wheel.rotation.z + PI * 0.5, 0.25)
	sequence.press(valve_id, global_position + Vector3.UP * 1.2)


func is_lit() -> bool:
	return _lamp.albedo_color == LAMP_ON


func _on_progress_changed(progress: int) -> void:
	var lit: bool = _position_in_order >= 0 and _position_in_order < progress
	_lamp.albedo_color = LAMP_ON if lit else LAMP_IDLE
	_lamp.emission = _lamp.albedo_color
	_lamp_light.light_energy = 1.5 if lit else 0.0


func _build_visuals() -> void:
	var iron: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.CAST_IRON)
	var brass: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.BRASS)
	var copper: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.COPPER_OXIDIZED)
	var housing: CylinderMesh = CylinderMesh.new()
	housing.top_radius = 0.45
	housing.bottom_radius = 0.55
	housing.height = 1.0
	Layers.add_mesh(self, housing, copper, Vector3(0.0, 0.5, 0.0))
	var pipe: CylinderMesh = CylinderMesh.new()
	pipe.top_radius = 0.16
	pipe.bottom_radius = 0.16
	pipe.height = 1.6
	var pipe_instance: MeshInstance3D = Layers.add_mesh(self, pipe, iron, Vector3(0.0, 0.6, -0.6))
	pipe_instance.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	_wheel = Node3D.new()
	_wheel.position = Vector3(0.0, 1.25, 0.0)
	add_child(_wheel)
	var rim: TorusMesh = TorusMesh.new()
	rim.inner_radius = 0.38
	rim.outer_radius = 0.48
	var rim_instance: MeshInstance3D = Layers.add_mesh(_wheel, rim, brass, Vector3.ZERO)
	rim_instance.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	var spoke: BoxMesh = BoxMesh.new()
	spoke.size = Vector3(0.85, 0.06, 0.06)
	for i: int in 2:
		var spoke_instance: MeshInstance3D = Layers.add_mesh(_wheel, spoke, brass, Vector3.ZERO)
		spoke_instance.rotation = Vector3(0.0, 0.0, PI * 0.5 * float(i))
	_lamp = FoundryMaterials.emissive(LAMP_IDLE, 3.0)
	var bulb: SphereMesh = SphereMesh.new()
	bulb.radius = 0.12
	bulb.height = 0.24
	Layers.add_mesh(self, bulb, _lamp, Vector3(0.0, 1.9, 0.0))
	_lamp_light = OmniLight3D.new()
	_lamp_light.light_color = LAMP_ON
	_lamp_light.light_energy = 0.0
	_lamp_light.omni_range = 3.0
	_lamp_light.position = Vector3(0.0, 2.0, 0.0)
	add_child(_lamp_light)
	var plate: Label3D = Label3D.new()
	plate.text = label
	plate.font_size = 64
	plate.outline_size = 12
	plate.modulate = Color(1.0, 0.85, 0.5)
	plate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	plate.position = Vector3(0.0, 2.35, 0.0)
	add_child(plate)
	Layers.add_static_cylinder(self, 0.5, 1.0, Vector3.ZERO)
