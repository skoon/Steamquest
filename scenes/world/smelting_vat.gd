class_name SmeltingVat
extends Node3D
## Iron crucible brimming with molten metal.

@export var radius: float = 1.6
@export var height: float = 1.6


func _ready() -> void:
	var iron: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.CAST_IRON)
	var brass: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.BRASS)
	var shell: CylinderMesh = CylinderMesh.new()
	shell.top_radius = radius
	shell.bottom_radius = radius * 0.85
	shell.height = height
	shell.radial_segments = 32
	Layers.add_mesh(self, shell, iron, Vector3(0.0, height * 0.5, 0.0))
	var band: TorusMesh = TorusMesh.new()
	band.inner_radius = radius * 0.92
	band.outer_radius = radius * 1.04
	Layers.add_mesh(self, band, brass, Vector3(0.0, height * 0.3, 0.0))
	Layers.add_mesh(self, band, brass, Vector3(0.0, height * 0.95, 0.0))
	var melt: CylinderMesh = CylinderMesh.new()
	melt.top_radius = radius * 0.9
	melt.bottom_radius = radius * 0.9
	melt.height = 0.05
	# The shell is a solid cylinder, so the melt sits just above its top face.
	Layers.add_mesh(self, melt, FoundryMaterials.get_material(FoundryMaterials.Kind.MOLTEN), Vector3(0.0, height + 0.03, 0.0))
	var glow: FurnaceLight = FurnaceLight.new()
	glow.light_color = Color(1.0, 0.45, 0.1)
	glow.base_energy = 2.5
	glow.flicker_amount = 0.6
	glow.omni_range = 6.0
	glow.position = Vector3(0.0, height + 0.8, 0.0)
	add_child(glow)
	var embers: GPUParticles3D = Fx.make_ember_emitter(20)
	embers.position = Vector3(0.0, height, 0.0)
	add_child(embers)
	Layers.add_static_cylinder(self, radius, height, Vector3.ZERO)
