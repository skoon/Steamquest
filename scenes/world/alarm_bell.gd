class_name AlarmBell
extends Node3D
## A room's alarm. Patrolling sentries report whenever their lantern cone catches the Technician;
## the bell rings and wakes the listed turrets, and lets them sleep again once nobody has seen the
## Technician for `quiet_time` seconds.

signal raised_changed(raised: bool)

@export var quiet_time: float = 20.0
@export var turrets: Array[NodePath] = []
@export var radius: float = 0.8

var alarm: AlarmState
var _time: float = 0.0
var _seen: bool = false
var _lamp: StandardMaterial3D
var _lamp_light: OmniLight3D
var _bell: Node3D
var _ring_timer: float = 0.0


func _ready() -> void:
	alarm = AlarmState.new(quiet_time)
	_build_visuals()


func is_raised() -> bool:
	return alarm.is_raised()


func report_seen() -> void:
	_seen = true


func _physics_process(delta: float) -> void:
	_time += delta
	var changed: bool = alarm.tick(_time, _seen)
	_seen = false
	if changed:
		_on_changed(alarm.is_raised())
	if alarm.is_raised():
		_bell.rotation.z = sin(_time * 18.0) * 0.35
		_ring_timer -= delta
		if _ring_timer <= 0.0:
			_ring_timer = 2.5
			Audio.play_at(&"alarm_bell", global_position + Vector3.UP * 2.4)
	else:
		_bell.rotation.z = 0.0


func _on_changed(raised: bool) -> void:
	_lamp.albedo_color = Color(1.0, 0.15, 0.08) if raised else Color(0.25, 0.06, 0.04)
	_lamp.emission = _lamp.albedo_color
	_lamp_light.light_energy = 3.0 if raised else 0.0
	_ring_timer = 0.0
	GameState.post_notice("ALARM! The turrets are waking." if raised else "The alarm falls quiet. The turrets settle back to sleep.")
	for path: NodePath in turrets:
		var turret: ArcTurret = get_node_or_null(path) as ArcTurret
		if turret != null and not turret.is_dead:
			turret.set_dormant(not raised)
	raised_changed.emit(raised)


func _build_visuals() -> void:
	var wood: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.WOOD)
	var brass: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.BRASS)
	var post: BoxMesh = BoxMesh.new()
	post.size = Vector3(0.16, 2.6, 0.16)
	Layers.add_mesh(self, post, wood, Vector3(0.0, 1.3, 0.0))
	_bell = Node3D.new()
	_bell.position = Vector3(0.0, 2.55, 0.25)
	add_child(_bell)
	var bell: CylinderMesh = CylinderMesh.new()
	bell.top_radius = 0.12
	bell.bottom_radius = 0.28
	bell.height = 0.35
	Layers.add_mesh(_bell, bell, brass, Vector3(0.0, -0.2, 0.0))
	_lamp = FoundryMaterials.emissive(Color(0.25, 0.06, 0.04), 3.0)
	var bulb: SphereMesh = SphereMesh.new()
	bulb.radius = 0.12
	bulb.height = 0.24
	Layers.add_mesh(self, bulb, _lamp, Vector3(0.0, 2.75, 0.0))
	_lamp_light = OmniLight3D.new()
	_lamp_light.light_color = Color(1.0, 0.2, 0.1)
	_lamp_light.light_energy = 0.0
	_lamp_light.omni_range = 9.0
	_lamp_light.position = Vector3(0.0, 2.8, 0.3)
	add_child(_lamp_light)
	Layers.add_static_cylinder(self, 0.12, 2.6, Vector3.ZERO)
