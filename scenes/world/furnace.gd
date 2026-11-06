class_name Furnace
extends Node3D
## Cast-iron furnace with a glowing mouth facing local +Z. Standing in front of the mouth burns.

@export var burn_damage: float = 10.0
@export var burn_reach: float = 1.6

var _burn_area: Area3D


func _ready() -> void:
	var iron: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.CAST_IRON)
	var brass: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.BRASS)
	var body: BoxMesh = BoxMesh.new()
	body.size = Vector3(2.4, 2.6, 1.8)
	Layers.add_mesh(self, body, iron, Vector3(0.0, 1.3, 0.0))
	var trim: BoxMesh = BoxMesh.new()
	trim.size = Vector3(2.5, 0.15, 1.9)
	Layers.add_mesh(self, trim, brass, Vector3(0.0, 2.6, 0.0))
	Layers.add_mesh(self, trim, brass, Vector3(0.0, 0.08, 0.0))
	var chimney: CylinderMesh = CylinderMesh.new()
	chimney.top_radius = 0.3
	chimney.bottom_radius = 0.4
	chimney.height = 2.0
	Layers.add_mesh(self, chimney, iron, Vector3(0.5, 3.6, -0.3))
	var mouth: BoxMesh = BoxMesh.new()
	mouth.size = Vector3(1.3, 0.9, 0.06)
	Layers.add_mesh(self, mouth, FoundryMaterials.get_material(FoundryMaterials.Kind.FURNACE_GLOW), Vector3(0.0, 0.9, 0.91))
	var grate: BoxMesh = BoxMesh.new()
	grate.size = Vector3(0.08, 0.9, 0.08)
	for i: int in 5:
		Layers.add_mesh(self, grate, iron, Vector3(-0.5 + 0.25 * float(i), 0.9, 0.95))

	var flicker: FurnaceLight = FurnaceLight.new()
	flicker.light_color = Color(1.0, 0.5, 0.15)
	flicker.omni_range = 7.0
	flicker.shadow_enabled = true
	flicker.position = Vector3(0.0, 1.0, 1.4)
	add_child(flicker)

	var embers: GPUParticles3D = Fx.make_ember_emitter(30)
	embers.position = Vector3(0.0, 0.9, 1.1)
	add_child(embers)
	var smoke: GPUParticles3D = Fx.make_steam_emitter(14, 3.0, 1.2, 15.0)
	smoke.position = Vector3(0.5, 4.6, -0.3)
	add_child(smoke)

	Layers.add_static_box(self, Vector3(2.4, 2.6, 1.8), Vector3(0.0, 1.3, 0.0))

	_burn_area = Area3D.new()
	_burn_area.collision_layer = 0
	_burn_area.collision_mask = Layers.PLAYER
	_burn_area.monitorable = false
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(1.6, 1.6, burn_reach)
	shape_node.shape = box
	shape_node.position = Vector3(0.0, 0.8, 0.9 + burn_reach * 0.5)
	_burn_area.add_child(shape_node)
	add_child(_burn_area)
	# Deferred so the level finishes building while sounds are still being synthesized.
	Audio.make_loop_player.call_deferred(&"furnace_loop", self)


func _physics_process(_delta: float) -> void:
	for body: Node3D in _burn_area.get_overlapping_bodies():
		var technician: Technician = body as Technician
		if technician != null:
			technician.receive_hit(burn_damage, global_basis.z.normalized() * 6.0)
