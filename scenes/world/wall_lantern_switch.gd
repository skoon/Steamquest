class_name WallLanternSwitch
extends Interactable
## An unlit miner's lantern on a post. Press F or knock it with the wrench to light it; it stays
## lit for the rest of the attempt.

@export var light_range: float = 9.0
@export var radius: float = 0.8

var is_lit: bool = false
var _flame: StandardMaterial3D
var _light: OmniLight3D


func _ready() -> void:
	add_trigger_sphere(1.2, 1.4)
	_build_visuals()


func get_prompt() -> String:
	return "[F] Light the lantern"


func can_interact() -> bool:
	return not is_lit


func interact(_technician: Node3D) -> void:
	light()


func receive_bash() -> void:
	light()


func light() -> void:
	if is_lit:
		return
	is_lit = true
	_flame.albedo_color = Color(1.0, 0.75, 0.35)
	_flame.emission = Color(1.0, 0.65, 0.25)
	_flame.emission_energy_multiplier = 4.0
	_light.visible = true
	Audio.play_at(&"lantern_light", global_position + Vector3.UP * 1.9)
	Fx.sparks(get_parent(), global_position + Vector3.UP * 1.9)


func _build_visuals() -> void:
	var wood: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.WOOD)
	var brass: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.BRASS)
	var post: BoxMesh = BoxMesh.new()
	post.size = Vector3(0.18, 2.2, 0.18)
	Layers.add_mesh(self, post, wood, Vector3(0.0, 1.1, 0.0))
	var arm: BoxMesh = BoxMesh.new()
	arm.size = Vector3(0.5, 0.08, 0.08)
	Layers.add_mesh(self, arm, wood, Vector3(0.22, 2.1, 0.0))
	var cage: CylinderMesh = CylinderMesh.new()
	cage.top_radius = 0.12
	cage.bottom_radius = 0.16
	cage.height = 0.32
	Layers.add_mesh(self, cage, brass, Vector3(0.42, 1.88, 0.0))
	_flame = FoundryMaterials.emissive(Color(0.15, 0.1, 0.07), 0.0)
	var glass: SphereMesh = SphereMesh.new()
	glass.radius = 0.11
	glass.height = 0.22
	Layers.add_mesh(self, glass, _flame, Vector3(0.42, 1.9, 0.0))
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.7, 0.4)
	_light.light_energy = 2.2
	_light.omni_range = light_range
	_light.position = Vector3(0.42, 2.0, 0.0)
	_light.visible = false
	add_child(_light)
	Layers.add_static_cylinder(self, 0.15, 2.2, Vector3.ZERO)
