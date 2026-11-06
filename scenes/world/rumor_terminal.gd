class_name RumorTerminal
extends Interactable
## Pneumatic-tube log terminal. Reading it records the rumor and opens the Rumor & Blueprint Log.

const UNREAD_COLOR: Color = Color(1.0, 0.62, 0.2)
const READ_COLOR: Color = Color(0.45, 0.85, 0.55)

@export var rumor: RumorData

var _screen_material: StandardMaterial3D
var _screen_light: OmniLight3D


func _ready() -> void:
	assert(rumor != null and rumor.rumor_id != &"", "%s: rumor with an id is required" % name)
	add_trigger_sphere(1.6, 0.9)
	_build_visuals()
	_set_read_look(GameState.has_rumor(rumor.rumor_id))


func get_prompt() -> String:
	var verb: String = "Re-read" if GameState.has_rumor(rumor.rumor_id) else "Read"
	return "[F] %s log: %s" % [verb, rumor.title]


func interact(_technician: Node3D) -> void:
	var is_new: bool = GameState.discover_rumor(rumor)
	Audio.play_ui(&"terminal_clack")
	GameState.open_log(rumor.rumor_id)
	if is_new:
		Fx.steam_puff(get_parent(), global_position + Vector3(0.0, 2.2, 0.0))
	_set_read_look(true)


func _set_read_look(read: bool) -> void:
	var color: Color = READ_COLOR if read else UNREAD_COLOR
	_screen_material.albedo_color = color
	_screen_material.emission = color
	_screen_light.light_color = color


func _build_visuals() -> void:
	var cabinet: BoxMesh = BoxMesh.new()
	cabinet.size = Vector3(0.9, 1.5, 0.6)
	Layers.add_mesh(self, cabinet, FoundryMaterials.get_material(FoundryMaterials.Kind.CAST_IRON), Vector3(0.0, 0.75, 0.0))

	var trim: BoxMesh = BoxMesh.new()
	trim.size = Vector3(1.0, 0.08, 0.7)
	var brass: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.BRASS)
	Layers.add_mesh(self, trim, brass, Vector3(0.0, 1.52, 0.0))
	Layers.add_mesh(self, trim, brass, Vector3(0.0, 0.04, 0.0))

	var screen: BoxMesh = BoxMesh.new()
	screen.size = Vector3(0.6, 0.45, 0.04)
	_screen_material = FoundryMaterials.emissive(UNREAD_COLOR, 2.5)
	Layers.add_mesh(self, screen, _screen_material, Vector3(0.0, 1.1, 0.31))

	var tube: CylinderMesh = CylinderMesh.new()
	tube.top_radius = 0.09
	tube.bottom_radius = 0.09
	tube.height = 1.6
	Layers.add_mesh(self, tube, FoundryMaterials.get_material(FoundryMaterials.Kind.COPPER_OXIDIZED), Vector3(0.3, 2.3, -0.15))

	var canister: CylinderMesh = CylinderMesh.new()
	canister.top_radius = 0.16
	canister.bottom_radius = 0.16
	canister.height = 0.35
	Layers.add_mesh(self, canister, brass, Vector3(0.3, 1.7, -0.15))

	_screen_light = OmniLight3D.new()
	_screen_light.light_energy = 1.2
	_screen_light.omni_range = 3.0
	_screen_light.position = Vector3(0.0, 1.1, 0.7)
	add_child(_screen_light)

	Layers.add_static_box(self, Vector3(0.9, 1.5, 0.6), Vector3(0.0, 0.75, 0.0))
