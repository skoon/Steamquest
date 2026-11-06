class_name GoldenGearPedestal
extends Interactable
## Display pedestal holding The Golden Gear.

const SPIN_SPEED: float = 0.9
const GEAR_HEIGHT: float = 1.9

var is_taken: bool = false
var _gear_mount: Node3D
var _gear_visual: Node3D
var _light: OmniLight3D
var _glints: GPUParticles3D
var _time: float = 0.0


func _ready() -> void:
	add_trigger_sphere(2.0, 1.0)
	_build_visuals()


func _process(delta: float) -> void:
	if is_taken:
		return
	_time += delta
	_gear_visual.rotation.y += SPIN_SPEED * delta
	_gear_mount.position.y = GEAR_HEIGHT + sin(_time * 1.6) * 0.12
	_light.light_energy = 3.0 + sin(_time * 2.3) * 0.6


func get_prompt() -> String:
	return "[F] Recover THE GOLDEN GEAR"


func can_interact() -> bool:
	return not is_taken


func interact(technician: Node3D) -> void:
	if is_taken:
		return
	is_taken = true
	_glints.emitting = false
	Fx.burst(get_parent(), _gear_mount.global_position, Color(1.0, 0.85, 0.35, 1.0), 48, 7.0, 0.16, -2.0)
	Audio.play_ui(&"golden_gear")
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_gear_mount, "global_position", technician.global_position + Vector3.UP * 1.0, 0.6)
	tween.tween_property(_gear_mount, "scale", Vector3.ONE * 0.1, 0.6)
	tween.tween_property(_light, "light_energy", 0.6, 1.2)
	tween.chain().tween_callback(_gear_mount.hide)
	GameState.acquire_golden_gear(GearItem.create_golden())


func _build_visuals() -> void:
	var iron: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.CAST_IRON)
	var brass: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.BRASS)
	var base: CylinderMesh = CylinderMesh.new()
	base.top_radius = 0.9
	base.bottom_radius = 1.1
	base.height = 0.4
	Layers.add_mesh(self, base, iron, Vector3(0.0, 0.2, 0.0))
	var column: CylinderMesh = CylinderMesh.new()
	column.top_radius = 0.45
	column.bottom_radius = 0.55
	column.height = 0.8
	Layers.add_mesh(self, column, iron, Vector3(0.0, 0.8, 0.0))
	var ring: TorusMesh = TorusMesh.new()
	ring.inner_radius = 0.5
	ring.outer_radius = 0.65
	Layers.add_mesh(self, ring, brass, Vector3(0.0, 1.2, 0.0))
	var cradle: CylinderMesh = CylinderMesh.new()
	cradle.top_radius = 0.7
	cradle.bottom_radius = 0.5
	cradle.height = 0.15
	Layers.add_mesh(self, cradle, brass, Vector3(0.0, 1.28, 0.0))

	_gear_mount = Node3D.new()
	_gear_mount.position = Vector3(0.0, GEAR_HEIGHT, 0.0)
	_gear_mount.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	add_child(_gear_mount)
	_gear_visual = GearMeshFactory.build(0.5, 0.14, 16, FoundryMaterials.get_material(FoundryMaterials.Kind.GOLD))
	_gear_mount.add_child(_gear_visual)

	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.8, 0.35)
	_light.light_energy = 3.0
	_light.omni_range = 7.0
	_light.shadow_enabled = true
	_light.position = Vector3(0.0, GEAR_HEIGHT + 0.6, 0.0)
	add_child(_light)

	_glints = Fx.make_ember_emitter(24)
	var glint_process: ParticleProcessMaterial = _glints.process_material as ParticleProcessMaterial
	glint_process.emission_box_extents = Vector3(0.6, 0.4, 0.6)
	glint_process.color_ramp = null
	glint_process.color = Color(1.0, 0.9, 0.5, 1.0)
	_glints.position = Vector3(0.0, GEAR_HEIGHT - 0.4, 0.0)
	add_child(_glints)

	Layers.add_static_cylinder(self, 1.0, 1.3, Vector3.ZERO)
