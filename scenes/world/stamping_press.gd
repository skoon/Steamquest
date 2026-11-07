class_name StampingPress
extends Node3D
## A steam stamping press over the line. On its beat (HazardCycle) it hisses and shudders, then
## the die slams down: the Technician takes heavy damage and is thrown clear, automatons are crushed.

const RAISED_Y: float = 2.6
const DOWN_Y: float = 0.35

@export var interval: float = 3.6
@export var warning_time: float = 0.9
@export var slam_time: float = 0.45
@export var phase_offset: float = 0.0
@export var damage: float = 35.0
@export var enemy_damage: float = 200.0
@export var knockback: float = 9.0
## Die footprint (x, z).
@export var footprint: Vector2 = Vector2(2.2, 2.2)
## FoundryBuilder keeps clutter this far away.
@export var radius: float = 1.8

var cycle: HazardCycle
var _time: float = 0.0
var _last_phase: HazardCycle.Phase = HazardCycle.Phase.IDLE
var _die: Node3D
var _area: Area3D
var _lamp: StandardMaterial3D
var _hit_this_slam: Dictionary = {}


func _ready() -> void:
	cycle = HazardCycle.new(interval, warning_time, slam_time, phase_offset)
	_build_visuals()
	_area = Area3D.new()
	_area.collision_layer = 0
	_area.collision_mask = Layers.PLAYER | Layers.ENEMIES
	_area.monitorable = false
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(footprint.x, 1.6, footprint.y)
	shape_node.shape = box
	shape_node.position = Vector3(0.0, 0.8, 0.0)
	_area.add_child(shape_node)
	add_child(_area)


func current_phase() -> HazardCycle.Phase:
	return cycle.phase_at(_time)


## Skips the clock ahead (tests jump straight to a slam).
func advance_time(seconds: float) -> void:
	_time += seconds


func _physics_process(delta: float) -> void:
	_time += delta
	var phase: HazardCycle.Phase = cycle.phase_at(_time)
	if phase != _last_phase:
		_on_phase_changed(phase)
		_last_phase = phase
	match phase:
		HazardCycle.Phase.IDLE:
			_die.position = Vector3(0.0, move_toward(_die.position.y, RAISED_Y, delta * 3.0), 0.0)
		HazardCycle.Phase.WARNING:
			_die.position = Vector3(sin(_time * 60.0) * 0.03, RAISED_Y + 0.15, 0.0)
		HazardCycle.Phase.ACTIVE:
			_die.position = Vector3(0.0, DOWN_Y, 0.0)
			for body: Node3D in _area.get_overlapping_bodies():
				_crush(body)


func _on_phase_changed(phase: HazardCycle.Phase) -> void:
	match phase:
		HazardCycle.Phase.WARNING:
			_lamp.albedo_color = Color(1.0, 0.2, 0.1)
			_lamp.emission = _lamp.albedo_color
			Audio.play_at(&"press_hiss", global_position + Vector3.UP * 2.5, -3.0)
		HazardCycle.Phase.ACTIVE:
			_hit_this_slam.clear()
			Audio.play_at(&"press_slam", global_position + Vector3.UP * 0.5)
			Fx.steam_puff(get_parent(), global_position + Vector3(footprint.x * 0.5, 0.3, 0.0))
			Fx.steam_puff(get_parent(), global_position + Vector3(-footprint.x * 0.5, 0.3, 0.0))
		HazardCycle.Phase.IDLE:
			_lamp.albedo_color = Color(0.3, 0.1, 0.05)
			_lamp.emission = _lamp.albedo_color


func _crush(body: Node3D) -> void:
	var id: int = body.get_instance_id()
	if _hit_this_slam.has(id) or not (body is Technician or body is EnemyBase):
		return
	_hit_this_slam[id] = true
	var push: Vector3 = DamageCalc.knockback(global_position, body.global_position, knockback, 0.0)
	if push == Vector3.ZERO:
		push = Vector3(0.0, 0.0, knockback)
	if body is EnemyBase:
		(body as EnemyBase).receive_crush_hit(enemy_damage, push)
	else:
		(body as Technician).receive_hit(damage, push)
	Fx.sparks(get_parent(), body.global_position + Vector3.UP * 0.5)


func _build_visuals() -> void:
	var iron: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.CAST_IRON)
	var steel: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.DARK_STEEL)
	var brass: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.BRASS)
	var column: BoxMesh = BoxMesh.new()
	column.size = Vector3(0.4, 4.2, 0.4)
	# Columns stand either side of the die across local Z, leaving local X clear for a belt.
	for side: float in [-1.0, 1.0]:
		var z: float = side * (footprint.y * 0.5 + 0.35)
		Layers.add_mesh(self, column, iron, Vector3(0.0, 2.1, z))
		Layers.add_static_box(self, Vector3(0.4, 4.2, 0.4), Vector3(0.0, 2.1, z))
	var crown: BoxMesh = BoxMesh.new()
	crown.size = Vector3(0.9, 0.6, footprint.y + 1.1)
	Layers.add_mesh(self, crown, iron, Vector3(0.0, 4.3, 0.0))
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.top_radius = 0.35
	cylinder.bottom_radius = 0.35
	cylinder.height = 1.2
	Layers.add_mesh(self, cylinder, brass, Vector3(0.0, 4.9, 0.0))
	_die = Node3D.new()
	_die.position = Vector3(0.0, RAISED_Y, 0.0)
	add_child(_die)
	var head: BoxMesh = BoxMesh.new()
	head.size = Vector3(footprint.x, 0.7, footprint.y)
	Layers.add_mesh(_die, head, steel, Vector3(0.0, 0.0, 0.0))
	var rod: CylinderMesh = CylinderMesh.new()
	rod.top_radius = 0.15
	rod.bottom_radius = 0.15
	rod.height = 2.4
	Layers.add_mesh(_die, rod, brass, Vector3(0.0, 1.5, 0.0))
	var stripes: BoxMesh = BoxMesh.new()
	stripes.size = Vector3(footprint.x + 0.3, 0.02, footprint.y + 0.3)
	var warning: MeshInstance3D = Layers.add_mesh(self, stripes, FoundryMaterials.get_material(FoundryMaterials.Kind.WARNING_RED), Vector3(0.0, 0.015, 0.0))
	warning.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var bed: BoxMesh = BoxMesh.new()
	bed.size = Vector3(footprint.x, 0.03, footprint.y)
	Layers.add_mesh(self, bed, steel, Vector3(0.0, 0.03, 0.0))
	_lamp = FoundryMaterials.emissive(Color(0.3, 0.1, 0.05), 3.0)
	var bulb: SphereMesh = SphereMesh.new()
	bulb.radius = 0.12
	bulb.height = 0.24
	Layers.add_mesh(self, bulb, _lamp, Vector3(0.3, 4.35, footprint.y * 0.5 + 0.35))
