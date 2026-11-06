class_name SteamVent
extends Node3D
## Floor grate that periodically blasts scalding steam. A warning lamp glows before each burst.

@export var idle_time: float = 3.0
@export var burst_time: float = 1.4
@export var warning_time: float = 0.8
## Shifts this vent's cycle so neighbouring vents fire out of step.
@export var phase_offset: float = 0.0
@export var damage: float = 8.0
@export var is_damaging: bool = true

var _cycle_time: float = 0.0
var _burst_emitter: GPUParticles3D
var _wisp_emitter: GPUParticles3D
var _lamp_material: StandardMaterial3D
var _area: Area3D
var _was_warning: bool = false
var _was_bursting: bool = false


func _ready() -> void:
	_cycle_time = phase_offset
	var steel: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.DARK_STEEL)
	var frame: BoxMesh = BoxMesh.new()
	frame.size = Vector3(1.6, 0.08, 1.6)
	Layers.add_mesh(self, frame, steel, Vector3(0.0, 0.04, 0.0))
	var slat: BoxMesh = BoxMesh.new()
	slat.size = Vector3(1.4, 0.1, 0.1)
	var iron: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.CAST_IRON)
	for i: int in 5:
		Layers.add_mesh(self, slat, iron, Vector3(0.0, 0.09, -0.56 + 0.28 * float(i)))
	var lamp: SphereMesh = SphereMesh.new()
	lamp.radius = 0.1
	lamp.height = 0.2
	_lamp_material = FoundryMaterials.emissive(Color(0.2, 0.1, 0.05), 3.0)
	Layers.add_mesh(self, lamp, _lamp_material, Vector3(0.85, 0.15, 0.85))

	_wisp_emitter = Fx.make_steam_emitter(6, 2.0, 0.8, 20.0)
	_wisp_emitter.position = Vector3(0.0, 0.1, 0.0)
	add_child(_wisp_emitter)
	_burst_emitter = Fx.make_steam_emitter(60, 1.2, 7.0, 12.0)
	_burst_emitter.position = Vector3(0.0, 0.1, 0.0)
	_burst_emitter.emitting = false
	add_child(_burst_emitter)

	_area = Area3D.new()
	_area.collision_layer = 0
	_area.collision_mask = Layers.PLAYER
	_area.monitorable = false
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var cylinder: CylinderShape3D = CylinderShape3D.new()
	cylinder.radius = 0.9
	cylinder.height = 2.5
	shape_node.shape = cylinder
	shape_node.position = Vector3(0.0, 1.25, 0.0)
	_area.add_child(shape_node)
	add_child(_area)
	# Deferred so the level finishes building while sounds are still being synthesized.
	Audio.make_loop_player.call_deferred(&"steam_vent_loop", self)


func is_bursting() -> bool:
	return fmod(_cycle_time, idle_time + burst_time) >= idle_time


func _physics_process(delta: float) -> void:
	_cycle_time += delta
	var position_in_cycle: float = fmod(_cycle_time, idle_time + burst_time)
	var bursting: bool = position_in_cycle >= idle_time
	var warning: bool = not bursting and position_in_cycle >= idle_time - warning_time
	_burst_emitter.emitting = bursting
	if warning and not _was_warning:
		Audio.play_at(&"vent_warn_whistle", global_position + Vector3.UP * 0.3)
	if bursting and not _was_bursting:
		Audio.play_at(&"vent_burst", global_position + Vector3.UP)
	_was_warning = warning
	_was_bursting = bursting
	var lamp_color: Color = Color(1.0, 0.25, 0.05) if bursting else (Color(1.0, 0.6, 0.1) if warning else Color(0.2, 0.1, 0.05))
	_lamp_material.albedo_color = lamp_color
	_lamp_material.emission = lamp_color
	if not bursting or not is_damaging:
		return
	for body: Node3D in _area.get_overlapping_bodies():
		var technician: Technician = body as Technician
		if technician != null:
			technician.receive_hit(damage, DamageCalc.knockback(global_position, technician.global_position, 5.0, 0.0))
