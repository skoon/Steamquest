class_name JunctionSwitch
extends Interactable
## One rotary junction switch on a PowerRouter. Each turn (F) moves it to the next of its three
## positions, shown on its dial as I, II or III.

const POSITION_LABELS: PackedStringArray = ["I", "II", "III"]

@export var router_path: NodePath
@export var index: int = 0
@export var label: String = "A"
## FoundryBuilder keeps clutter this far away.
@export var radius: float = 1.0

var router: PowerRouter
var _dial: Node3D
var _readout: Label3D


func _ready() -> void:
	router = get_node(router_path) as PowerRouter
	assert(router != null, "%s: router_path must point at a PowerRouter" % name)
	add_trigger_sphere(1.3, 1.0)
	_build_visuals()
	router.routing_changed.connect(func(_section: int) -> void: _refresh())
	_refresh.call_deferred()


func get_prompt() -> String:
	return "[F] Turn junction %s (now %s)" % [label, POSITION_LABELS[router.positions[index]]]


func can_interact() -> bool:
	return not router.is_solved()


func interact(_technician: Node3D) -> void:
	router.turn(index, global_position + Vector3.UP * 1.2)


func current_position() -> int:
	return router.positions[index]


func _refresh() -> void:
	var position_index: int = router.positions[index]
	_readout.text = "%s: %s" % [label, POSITION_LABELS[position_index]]
	create_tween().tween_property(_dial, "rotation:z", -TAU / 3.0 * float(position_index), 0.2)


func _build_visuals() -> void:
	var iron: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.CAST_IRON)
	var brass: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.BRASS)
	var cabinet: BoxMesh = BoxMesh.new()
	cabinet.size = Vector3(0.9, 1.6, 0.5)
	Layers.add_mesh(self, cabinet, iron, Vector3(0.0, 0.8, 0.0))
	_dial = Node3D.new()
	_dial.position = Vector3(0.0, 1.2, 0.27)
	add_child(_dial)
	var face: CylinderMesh = CylinderMesh.new()
	face.top_radius = 0.3
	face.bottom_radius = 0.3
	face.height = 0.05
	var face_instance: MeshInstance3D = Layers.add_mesh(_dial, face, FoundryMaterials.get_material(FoundryMaterials.Kind.GAUGE_FACE), Vector3.ZERO)
	face_instance.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	var pointer: BoxMesh = BoxMesh.new()
	pointer.size = Vector3(0.05, 0.28, 0.04)
	Layers.add_mesh(_dial, pointer, brass, Vector3(0.0, 0.14, 0.04))
	var arc_lamp: SphereMesh = SphereMesh.new()
	arc_lamp.radius = 0.08
	arc_lamp.height = 0.16
	Layers.add_mesh(self, arc_lamp, FoundryMaterials.get_material(FoundryMaterials.Kind.ARC_BLUE), Vector3(0.0, 1.7, 0.0))
	_readout = Label3D.new()
	_readout.font_size = 56
	_readout.outline_size = 12
	_readout.modulate = Color(0.6, 0.9, 1.0)
	_readout.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_readout.position = Vector3(0.0, 2.15, 0.0)
	add_child(_readout)
	Layers.add_static_box(self, Vector3(0.9, 1.6, 0.5), Vector3(0.0, 0.8, 0.0))
