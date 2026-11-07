class_name GearWorkbench
extends Interactable
## A fitter's bench with a bench grinder and spare teeth. One use: F fully repairs the most-worn
## gear in the rig (durability, friction and any jam or shatter).

## FoundryBuilder keeps clutter this far away.
@export var radius: float = 1.2

var is_used: bool = false
var _lamp: OmniLight3D


func _ready() -> void:
	add_trigger_sphere(1.5, 1.0)
	_build_visuals()


func get_prompt() -> String:
	return "[F] Rebuild your most worn gear at the workbench"


func can_interact() -> bool:
	return not is_used


func interact(_technician: Node3D) -> void:
	var gear: GearItem = most_worn_gear(GameState.rig)
	if gear == null:
		GameState.post_notice("Nothing in the rig needs the bench.")
		return
	gear.repair_fully()
	is_used = true
	_lamp.light_energy = 0.3
	GameState.notify_rig_changed()
	Fx.sparks(get_parent(), global_position + Vector3(0.4, 1.1, 0.0))
	Audio.play_at(&"workbench_repair", global_position + Vector3.UP)
	GameState.post_notice("Rebuilt the %s - good as new. The bench's spare teeth are used up." % gear.gear_name)


## The socketed gear with the least durability left (shattered counts as none); empty sockets and
## the Golden Gear are skipped. Null when nothing is socketed.
static func most_worn_gear(rig: FrictionModel) -> GearItem:
	var worst: GearItem = null
	for socket: int in FrictionModel.SOCKET_COUNT:
		var gear: GearItem = rig.get_gear(socket as FrictionModel.Socket)
		if gear == null or gear.is_golden_gear:
			continue
		var ratio: float = 0.0 if gear.state == GearItem.GearState.SHATTERED else gear.durability_ratio()
		if worst == null or ratio < (0.0 if worst.state == GearItem.GearState.SHATTERED else worst.durability_ratio()):
			worst = gear
	return worst


func _build_visuals() -> void:
	var wood: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.WOOD)
	var iron: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.CAST_IRON)
	var brass: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.BRASS)
	var top: BoxMesh = BoxMesh.new()
	top.size = Vector3(2.0, 0.12, 0.9)
	Layers.add_mesh(self, top, wood, Vector3(0.0, 0.9, 0.0))
	var leg: BoxMesh = BoxMesh.new()
	leg.size = Vector3(0.1, 0.85, 0.1)
	for x: float in [-0.9, 0.9]:
		for z: float in [-0.38, 0.38]:
			Layers.add_mesh(self, leg, iron, Vector3(x, 0.42, z))
	var vice: BoxMesh = BoxMesh.new()
	vice.size = Vector3(0.3, 0.25, 0.3)
	Layers.add_mesh(self, vice, iron, Vector3(-0.6, 1.08, 0.0))
	var wheel: CylinderMesh = CylinderMesh.new()
	wheel.top_radius = 0.22
	wheel.bottom_radius = 0.22
	wheel.height = 0.06
	var grinder: MeshInstance3D = Layers.add_mesh(self, wheel, FoundryMaterials.get_material(FoundryMaterials.Kind.DARK_STEEL), Vector3(0.5, 1.2, 0.0))
	grinder.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	var cog: Node3D = GearMeshFactory.build(0.22, 0.06, 10, brass)
	cog.position = Vector3(0.0, 0.99, 0.15)
	add_child(cog)
	_lamp = OmniLight3D.new()
	_lamp.light_color = Color(1.0, 0.85, 0.55)
	_lamp.light_energy = 1.6
	_lamp.omni_range = 3.5
	_lamp.position = Vector3(0.0, 2.0, 0.0)
	add_child(_lamp)
	Layers.add_static_box(self, Vector3(2.0, 1.0, 0.9), Vector3(0.0, 0.5, 0.0))
