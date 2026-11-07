class_name BurstRoute
extends Node3D
## A marked strip of floor under a strained pipe run (length along local X). While the room
## pressure is in the warning band it hisses and leaks wisps; when PressureSystem bursts it, it
## blasts steam for `burst_time` seconds: anyone on it takes `damage` once and is shoved off.

const HAZARD_COLOR: Color = Color(0.95, 0.55, 0.1)

@export var size: Vector2 = Vector2(8.0, 2.0)
@export var burst_time: float = 1.5
@export var damage: float = 25.0
@export var shove: float = 8.0

var is_warning: bool = false
var burst_left: float = 0.0
var _area: Area3D
var _wisps: Array[GPUParticles3D] = []
var _jets: Array[GPUParticles3D] = []
var _stripe: StandardMaterial3D
var _hit_this_burst: Dictionary = {}
var _time: float = 0.0


func _ready() -> void:
	_build_visuals()
	_area = Area3D.new()
	_area.collision_layer = 0
	_area.collision_mask = Layers.PLAYER | Layers.ENEMIES
	_area.monitorable = false
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(size.x, 2.0, size.y)
	shape_node.shape = box
	shape_node.position = Vector3(0.0, 1.0, 0.0)
	_area.add_child(shape_node)
	add_child(_area)


func is_bursting() -> bool:
	return burst_left > 0.0


func set_warning(warning: bool) -> void:
	is_warning = warning
	for wisp: GPUParticles3D in _wisps:
		wisp.emitting = warning
	if warning:
		Audio.play_at(&"press_hiss", global_position + Vector3.UP * 2.0, -6.0)


func burst() -> void:
	burst_left = burst_time
	_hit_this_burst.clear()
	for jet: GPUParticles3D in _jets:
		jet.restart()
		jet.emitting = true
	Audio.play_at(&"pipe_burst", global_position + Vector3.UP * 1.5)


## Circles (x, z, radius) covering the strip, so FoundryBuilder keeps clutter off it.
func keep_clear_zones() -> PackedVector3Array:
	var zones: PackedVector3Array = PackedVector3Array()
	var count: int = maxi(int(ceil(size.x / 1.5)), 1)
	for i: int in count + 1:
		var point: Vector3 = to_global(Vector3(-size.x * 0.5 + size.x * float(i) / float(count), 0.0, 0.0))
		zones.append(Vector3(point.x, point.z, size.y * 0.5 + 0.6))
	return zones


func _physics_process(delta: float) -> void:
	_time += delta
	if is_warning:
		_stripe.emission_energy_multiplier = 0.6 + 0.6 * sin(_time * 10.0)
	else:
		_stripe.emission_energy_multiplier = 0.15
	if burst_left <= 0.0:
		return
	burst_left = maxf(burst_left - delta, 0.0)
	if burst_left <= 0.0:
		for jet: GPUParticles3D in _jets:
			jet.emitting = false
		return
	for body: Node3D in _area.get_overlapping_bodies():
		_scald(body)


func _scald(body: Node3D) -> void:
	if not (body is Technician or body is EnemyBase):
		return
	var id: int = body.get_instance_id()
	if _hit_this_burst.has(id):
		return
	_hit_this_burst[id] = true
	var side: float = signf(to_local(body.global_position).z)
	if side == 0.0:
		side = 1.0
	var push: Vector3 = global_basis.z.normalized() * side * shove
	body.call("receive_hit", damage, push)
	Fx.steam_puff(get_parent(), body.global_position + Vector3.UP * 0.5)


func _build_visuals() -> void:
	var steel: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.DARK_STEEL)
	var copper: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.COPPER_OXIDIZED)
	_stripe = FoundryMaterials.emissive(HAZARD_COLOR, 0.15)
	var stripe: BoxMesh = BoxMesh.new()
	stripe.size = Vector3(size.x, 0.02, 0.18)
	for side: float in [-1.0, 1.0]:
		var edge: MeshInstance3D = Layers.add_mesh(self, stripe, _stripe, Vector3(0.0, 0.015, side * (size.y * 0.5 - 0.09)))
		edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var chevron: BoxMesh = BoxMesh.new()
	chevron.size = Vector3(0.18, 0.02, size.y * 0.6)
	var chevrons: int = maxi(int(size.x / 1.2), 1)
	for i: int in chevrons:
		var x: float = -size.x * 0.5 + (float(i) + 0.5) * size.x / float(chevrons)
		var mark: MeshInstance3D = Layers.add_mesh(self, chevron, _stripe, Vector3(x, 0.015, 0.0))
		mark.rotation = Vector3(0.0, 0.6, 0.0)
		mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pipe: CylinderMesh = CylinderMesh.new()
	pipe.top_radius = 0.2
	pipe.bottom_radius = 0.2
	pipe.height = size.x
	var run: MeshInstance3D = Layers.add_mesh(self, pipe, copper, Vector3(0.0, 0.25, 0.0))
	run.rotation = Vector3(0.0, 0.0, PI * 0.5)
	var flange: CylinderMesh = CylinderMesh.new()
	flange.top_radius = 0.3
	flange.bottom_radius = 0.3
	flange.height = 0.12
	var joints: int = maxi(int(size.x / 3.0), 1)
	for i: int in joints + 1:
		var x: float = -size.x * 0.5 + size.x * float(i) / float(joints)
		var ring: MeshInstance3D = Layers.add_mesh(self, flange, steel, Vector3(x, 0.25, 0.0))
		ring.rotation = Vector3(0.0, 0.0, PI * 0.5)
		var wisp: GPUParticles3D = Fx.make_steam_emitter(8, 1.2, 1.2, 25.0)
		wisp.position = Vector3(x, 0.4, 0.0)
		wisp.emitting = false
		add_child(wisp)
		_wisps.append(wisp)
		var jet: GPUParticles3D = Fx.make_steam_emitter(70, 0.9, 7.5, 18.0)
		jet.position = Vector3(x, 0.4, 0.0)
		jet.emitting = false
		add_child(jet)
		_jets.append(jet)
