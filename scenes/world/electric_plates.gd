class_name ElectricPlates
extends Node3D
## A strip of conductive floor plates in `rows` rows laid along local X. Patterned plates sweep
## live row by row (PlatePattern), flickering blue first. Plates wired to a PowerRouter section
## (`power_section` >= 0) ignore the pattern and stay live while the router feeds that section.
## Live plates shock the Technician and walking automatons; hovering drones are above it all.

const COLOR_OFF: Color = Color(0.12, 0.13, 0.15)
const COLOR_WARNING: Color = Color(0.3, 0.55, 1.0)
const COLOR_LIVE: Color = Color(0.45, 0.85, 1.0)
const SHOCK_INTERVAL_MSEC: int = 500

@export var rows: int = 4
## Size of one row (x along the strip, z across it).
@export var row_size: Vector2 = Vector2(2.5, 8.0)
@export var step_time: float = 1.0
@export var live_time: float = 1.4
@export var warning_time: float = 0.8
@export var rest_time: float = 1.5
@export var reverse: bool = false
@export var phase_offset: float = 0.0
@export var damage: float = 12.0
@export var knockback: float = 3.0
@export_group("Routing")
@export var power_section: int = -1
@export var router_path: NodePath

var pattern: PlatePattern
var router: PowerRouter
var _time: float = 0.0
var _areas: Array[Area3D] = []
var _materials: Array[StandardMaterial3D] = []
var _lights: Array[OmniLight3D] = []
var _states: Array[PlatePattern.State] = []
var _last_shock_msec: Dictionary = {}


func _ready() -> void:
	pattern = PlatePattern.new(rows, step_time, live_time, warning_time, rest_time, reverse, phase_offset)
	if power_section >= 0:
		router = get_node(router_path) as PowerRouter
		assert(router != null, "%s: wired plates need router_path" % name)
	for row: int in rows:
		_build_row(row)
		_states.append(PlatePattern.State.OFF)
	_refresh(true)


func state_of(row: int) -> PlatePattern.State:
	return _states[row]


## Centre of a row, in world space (tests stand the Technician on one).
func row_center(row: int) -> Vector3:
	return to_global(Vector3((float(row) + 0.5) * row_size.x - float(rows) * row_size.x * 0.5, 0.0, 0.0))


## Circles (x, z, radius) covering the whole strip, so FoundryBuilder keeps clutter off the plates.
func keep_clear_zones() -> PackedVector3Array:
	var zones: PackedVector3Array = PackedVector3Array()
	var size: Vector2 = Vector2(row_size.x * float(rows), row_size.y)
	var step: float = 1.5
	var nx: int = maxi(int(ceil(size.x / step)), 1)
	var nz: int = maxi(int(ceil(size.y / step)), 1)
	for ix: int in nx + 1:
		for iz: int in nz + 1:
			var local: Vector3 = Vector3(-size.x * 0.5 + size.x * float(ix) / float(nx), 0.0, -size.y * 0.5 + size.y * float(iz) / float(nz))
			var point: Vector3 = to_global(local)
			zones.append(Vector3(point.x, point.z, 1.2))
	return zones


func _physics_process(delta: float) -> void:
	_time += delta
	_refresh(false)
	var now: int = Time.get_ticks_msec()
	for row: int in rows:
		if _states[row] != PlatePattern.State.LIVE:
			continue
		for body: Node3D in _areas[row].get_overlapping_bodies():
			_shock(body, now)


func _current_state(row: int) -> PlatePattern.State:
	if power_section >= 0:
		return PlatePattern.State.LIVE if router.live_section() == power_section else PlatePattern.State.OFF
	return pattern.state_at(row, _time)


func _refresh(force: bool) -> void:
	for row: int in rows:
		var state: PlatePattern.State = _current_state(row)
		if state == _states[row] and not force and state != PlatePattern.State.WARNING:
			continue
		if state == PlatePattern.State.LIVE and _states[row] != PlatePattern.State.LIVE and not force:
			Audio.play_at(&"plate_crackle", row_center(row) + Vector3.UP * 0.3, -3.0)
		_states[row] = state
		var material: StandardMaterial3D = _materials[row]
		match state:
			PlatePattern.State.OFF:
				material.albedo_color = COLOR_OFF
				material.emission_energy_multiplier = 0.0
				_lights[row].light_energy = 0.0
			PlatePattern.State.WARNING:
				var flicker: float = 0.5 + 0.5 * sin(_time * 30.0)
				material.albedo_color = COLOR_OFF.lerp(COLOR_WARNING, flicker)
				material.emission = COLOR_WARNING
				material.emission_energy_multiplier = flicker * 1.5
				_lights[row].light_energy = 0.0
			PlatePattern.State.LIVE:
				material.albedo_color = COLOR_LIVE
				material.emission = COLOR_LIVE
				material.emission_energy_multiplier = 2.5
				_lights[row].light_energy = 1.8


func _shock(body: Node3D, now: int) -> void:
	if body is TeslaDrone or not body.has_method("receive_hit"):
		return
	var id: int = body.get_instance_id()
	if now - int(_last_shock_msec.get(id, -100000)) < SHOCK_INTERVAL_MSEC:
		return
	_last_shock_msec[id] = now
	body.call("receive_hit", damage, DamageCalc.knockback(global_position, body.global_position, knockback, 0.0))
	Fx.arc_sparks(get_parent(), body.global_position + Vector3.UP * 0.3)


func _build_row(row: int) -> void:
	var center: Vector3 = Vector3((float(row) + 0.5) * row_size.x - float(rows) * row_size.x * 0.5, 0.0, 0.0)
	var plate: BoxMesh = BoxMesh.new()
	plate.size = Vector3(row_size.x - 0.12, 0.04, row_size.y)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = COLOR_OFF
	material.metallic = 0.8
	material.roughness = 0.35
	material.emission_enabled = true
	material.emission = COLOR_LIVE
	material.emission_energy_multiplier = 0.0
	var instance: MeshInstance3D = Layers.add_mesh(self, plate, material, center + Vector3(0.0, 0.02, 0.0))
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_materials.append(material)
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = COLOR_LIVE
	light.light_energy = 0.0
	light.omni_range = maxf(row_size.x, row_size.y) * 0.6
	light.position = center + Vector3(0.0, 0.8, 0.0)
	add_child(light)
	_lights.append(light)
	var area: Area3D = Area3D.new()
	area.collision_layer = 0
	area.collision_mask = Layers.PLAYER | Layers.ENEMIES
	area.monitorable = false
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(row_size.x - 0.2, 0.6, row_size.y - 0.2)
	shape_node.shape = box
	shape_node.position = center + Vector3(0.0, 0.3, 0.0)
	area.add_child(shape_node)
	add_child(area)
	_areas.append(area)
