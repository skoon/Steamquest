class_name FoundryElevator
extends Node3D
## Level exit lift. In VICTORY mode (the Master Clock Vault) it stays dormant until the Golden Gear
## is recovered and stepping on it wins; in NEXT_LEVEL mode it is always live and carries the
## Technician on to the next level of the campaign.

enum ExitMode { VICTORY, NEXT_LEVEL }

const DORMANT_COLOR: Color = Color(0.6, 0.15, 0.1)
const ACTIVE_COLOR: Color = Color(1.0, 0.8, 0.3)

@export var platform_radius: float = 1.8
@export var exit_mode: ExitMode = ExitMode.VICTORY

var _activated: bool = false
var _platform: Node3D
var _lamp_material: StandardMaterial3D
var _light: OmniLight3D
var _trigger: Area3D


func _ready() -> void:
	_build_visuals()
	_trigger = Area3D.new()
	_trigger.collision_layer = 0
	_trigger.collision_mask = Layers.PLAYER
	_trigger.monitorable = false
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var cylinder: CylinderShape3D = CylinderShape3D.new()
	cylinder.radius = platform_radius * 0.8
	cylinder.height = 2.0
	shape_node.shape = cylinder
	shape_node.position = Vector3(0.0, 1.0, 0.0)
	_trigger.add_child(shape_node)
	add_child(_trigger)
	_trigger.body_entered.connect(_on_body_entered)
	GameState.golden_gear_acquired.connect(_on_golden_gear_acquired)
	_set_lamp(ACTIVE_COLOR if _is_live() else DORMANT_COLOR)


func _is_live() -> bool:
	return exit_mode == ExitMode.NEXT_LEVEL or GameState.has_golden_gear


func _on_golden_gear_acquired() -> void:
	_set_lamp(ACTIVE_COLOR)


func _on_body_entered(body: Node3D) -> void:
	if _activated or not (body is Technician):
		return
	if not _is_live():
		GameState.post_notice("The elevator's drive is missing a frictionless master cog.")
		return
	_activated = true
	Fx.burst(get_parent(), global_position + Vector3.UP, Color(1.0, 0.85, 0.35, 1.0), 64, 8.0, 0.18, -1.0)
	var tween: Tween = create_tween()
	tween.tween_property(_light, "light_energy", 8.0, 1.0)
	if exit_mode == ExitMode.VICTORY:
		GameState.declare_victory()
		return
	Audio.play_ui(&"lift_rise")
	tween.parallel().tween_property(_platform, "position:y", 0.6, 1.0)
	GameState.post_notice("The lift rattles into motion...")
	GameState.complete_level()


func _set_lamp(color: Color) -> void:
	_lamp_material.albedo_color = color
	_lamp_material.emission = color
	_light.light_color = color


func _build_visuals() -> void:
	var brass: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.BRASS)
	var iron: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.CAST_IRON)
	_platform = Node3D.new()
	add_child(_platform)
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = platform_radius
	disc.bottom_radius = platform_radius
	disc.height = 0.12
	disc.radial_segments = 40
	Layers.add_mesh(_platform, disc, iron, Vector3(0.0, 0.06, 0.0))
	var ring: TorusMesh = TorusMesh.new()
	ring.inner_radius = platform_radius - 0.12
	ring.outer_radius = platform_radius
	Layers.add_mesh(_platform, ring, brass, Vector3(0.0, 0.14, 0.0))
	var inlay: Node3D = GearMeshFactory.build(platform_radius * 0.55, 0.04, 12, brass)
	inlay.position = Vector3(0.0, 0.14, 0.0)
	_platform.add_child(inlay)

	var post: CylinderMesh = CylinderMesh.new()
	post.top_radius = 0.08
	post.bottom_radius = 0.1
	post.height = 4.0
	for i: int in 4:
		var angle: float = TAU * float(i) / 4.0 + PI * 0.25
		Layers.add_mesh(self, post, brass, Vector3(cos(angle), 0.0, sin(angle)) * platform_radius + Vector3.UP * 2.0)
	var crown: TorusMesh = TorusMesh.new()
	crown.inner_radius = platform_radius - 0.1
	crown.outer_radius = platform_radius + 0.05
	Layers.add_mesh(self, crown, brass, Vector3(0.0, 4.0, 0.0))

	var lamp: SphereMesh = SphereMesh.new()
	lamp.radius = 0.25
	lamp.height = 0.5
	_lamp_material = FoundryMaterials.emissive(DORMANT_COLOR, 4.0)
	Layers.add_mesh(self, lamp, _lamp_material, Vector3(0.0, 4.2, 0.0))
	_light = OmniLight3D.new()
	_light.light_energy = 2.5
	_light.omni_range = 6.0
	_light.position = Vector3(0.0, 3.5, 0.0)
	add_child(_light)
