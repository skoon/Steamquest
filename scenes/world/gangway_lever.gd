class_name GangwayLever
extends Interactable
## A big brass lever. Pulling it (F) lowers a gangway or releases a lift by unlocking `unlock_id`.

@export var unlock_id: StringName = &""
@export var prompt: String = "[F] Pull the gangway lever"
@export var pulled_notice: String = "The gangway clanks down."
## FoundryBuilder keeps clutter this far away.
@export var radius: float = 1.0

var is_pulled: bool = false
var _handle: Node3D
var _lamp: StandardMaterial3D


func _ready() -> void:
	assert(unlock_id != &"", "%s: unlock_id is required" % name)
	add_trigger_sphere(1.3, 1.0)
	_build_visuals()
	if GameState.is_door_unlocked(unlock_id):
		_set_pulled(false)


func get_prompt() -> String:
	return prompt


func can_interact() -> bool:
	return not is_pulled


func interact(_technician: Node3D) -> void:
	_set_pulled(true)
	GameState.unlock_door(unlock_id)
	GameState.post_notice(pulled_notice)


func _set_pulled(animate: bool) -> void:
	is_pulled = true
	_lamp.albedo_color = Color(0.3, 1.0, 0.45)
	_lamp.emission = _lamp.albedo_color
	if animate:
		create_tween().tween_property(_handle, "rotation:x", 0.8, 0.35)
		Audio.play_at(&"switch_clunk", global_position + Vector3.UP)
	else:
		_handle.rotation.x = 0.8


func _build_visuals() -> void:
	var iron: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.CAST_IRON)
	var brass: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.BRASS)
	var base: BoxMesh = BoxMesh.new()
	base.size = Vector3(0.7, 0.9, 0.5)
	Layers.add_mesh(self, base, iron, Vector3(0.0, 0.45, 0.0))
	_handle = Node3D.new()
	_handle.position = Vector3(0.0, 0.9, 0.0)
	_handle.rotation.x = -0.8
	add_child(_handle)
	var arm: CylinderMesh = CylinderMesh.new()
	arm.top_radius = 0.05
	arm.bottom_radius = 0.06
	arm.height = 1.0
	Layers.add_mesh(_handle, arm, brass, Vector3(0.0, 0.5, 0.0))
	var knob: SphereMesh = SphereMesh.new()
	knob.radius = 0.12
	knob.height = 0.24
	Layers.add_mesh(_handle, knob, FoundryMaterials.get_material(FoundryMaterials.Kind.WARNING_RED), Vector3(0.0, 1.0, 0.0))
	_lamp = FoundryMaterials.emissive(Color(0.35, 0.12, 0.06), 3.0)
	var bulb: SphereMesh = SphereMesh.new()
	bulb.radius = 0.1
	bulb.height = 0.2
	Layers.add_mesh(self, bulb, _lamp, Vector3(0.25, 1.0, 0.2))
	Layers.add_static_box(self, Vector3(0.7, 0.9, 0.5), Vector3(0.0, 0.45, 0.0))
