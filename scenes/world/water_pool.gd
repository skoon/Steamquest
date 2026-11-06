class_name WaterPool
extends Area3D
## A sunken cistern pool whose water rises and falls on a TideCycle. While the water is deep it
## slows everything wading through it, grinds the Technician's DRIVE gear harder, and shorts out
## any Arc Turret standing in it.

const LOW_WATER_Y: float = 0.03
const HIGH_WATER_Y: float = 0.75
const WATER_COLOR: Color = Color(0.16, 0.32, 0.34, 0.72)

## Footprint of the pool (x, z), centred on this node.
@export var size: Vector2 = Vector2(8.0, 6.0)
@export var period: float = 14.0
@export var phase_offset: float = 0.0
## Water level (0..1) above which the pool counts as deep.
@export var deep_threshold: float = 0.55
@export var deep_speed: float = 0.6
@export var deep_drive_work: float = 2.0

var tide: TideCycle
var _time: float = 0.0
var _water: MeshInstance3D
var _was_deep: bool = false
var _inside: Dictionary = {}


func _ready() -> void:
	assert(size.x > 0.0 and size.y > 0.0, "%s: size must be positive" % name)
	tide = TideCycle.new(period, phase_offset)
	collision_layer = 0
	collision_mask = Layers.PLAYER | Layers.ENEMIES
	monitorable = false
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(size.x, 2.0, size.y)
	shape_node.shape = box
	shape_node.position = Vector3(0.0, 1.0, 0.0)
	add_child(shape_node)
	body_entered.connect(func(body: Node3D) -> void: _inside[body.get_instance_id()] = body)
	body_exited.connect(_on_body_exited)
	_build_visuals()
	_was_deep = is_deep()


func level() -> float:
	return tide.level_at(_time)


func is_deep() -> bool:
	return tide.is_deep(_time, deep_threshold)


## Holds the pool at full for `seconds` (a wrong pump valve, for instance).
func flood_for(seconds: float) -> void:
	tide.force_flood(_time + seconds)


## Circles (x, z, radius) covering the pool, so FoundryBuilder never drops clutter in the water.
func keep_clear_zones() -> PackedVector3Array:
	var zones: PackedVector3Array = PackedVector3Array()
	var step: float = 2.0
	var nx: int = int(ceil(size.x / step))
	var nz: int = int(ceil(size.y / step))
	for ix: int in nx + 1:
		for iz: int in nz + 1:
			var local: Vector3 = Vector3(-size.x * 0.5 + size.x * float(ix) / float(nx), 0.0, -size.y * 0.5 + size.y * float(iz) / float(nz))
			var point: Vector3 = to_global(local)
			zones.append(Vector3(point.x, point.z, 1.8))
	return zones


func _physics_process(delta: float) -> void:
	_time += delta
	_water.position.y = lerpf(LOW_WATER_Y, HIGH_WATER_Y, level())
	var deep: bool = is_deep()
	if deep and not _was_deep:
		Audio.play_at(&"water_slosh", global_position + Vector3.UP * 0.5)
	_was_deep = deep
	for id: int in _inside.keys():
		var body: Node3D = _inside[id] as Node3D
		if not is_instance_valid(body):
			_inside.erase(id)
			continue
		_apply_to(body, deep)


func _apply_to(body: Node3D, deep: bool) -> void:
	if body is Technician:
		var technician: Technician = body as Technician
		technician.terrain_speed = deep_speed if deep else 1.0
		technician.terrain_drive_work = deep_drive_work if deep else 1.0
	elif body is ArcTurret:
		(body as ArcTurret).set_disabled(deep)
	elif body is EnemyBase:
		(body as EnemyBase).terrain_speed = deep_speed if deep else 1.0


func _on_body_exited(body: Node3D) -> void:
	_inside.erase(body.get_instance_id())
	_apply_to(body, false)


func _build_visuals() -> void:
	var stone: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.CAST_IRON)
	var bed: BoxMesh = BoxMesh.new()
	bed.size = Vector3(size.x, 0.02, size.y)
	var silt: StandardMaterial3D = StandardMaterial3D.new()
	silt.albedo_color = Color(0.17, 0.16, 0.12)
	silt.roughness = 0.6
	Layers.add_mesh(self, bed, silt, Vector3(0.0, 0.011, 0.0))
	var kerb_x: BoxMesh = BoxMesh.new()
	kerb_x.size = Vector3(size.x + 0.5, 0.14, 0.25)
	var kerb_z: BoxMesh = BoxMesh.new()
	kerb_z.size = Vector3(0.25, 0.14, size.y + 0.5)
	for z: float in [-size.y * 0.5 - 0.12, size.y * 0.5 + 0.12]:
		Layers.add_mesh(self, kerb_x, stone, Vector3(0.0, 0.07, z))
	for x: float in [-size.x * 0.5 - 0.12, size.x * 0.5 + 0.12]:
		Layers.add_mesh(self, kerb_z, stone, Vector3(x, 0.07, 0.0))
	var plane: BoxMesh = BoxMesh.new()
	plane.size = Vector3(size.x, 0.04, size.y)
	var water: StandardMaterial3D = StandardMaterial3D.new()
	water.albedo_color = WATER_COLOR
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.metallic = 0.3
	water.roughness = 0.08
	water.emission_enabled = true
	water.emission = Color(0.05, 0.12, 0.13)
	_water = Layers.add_mesh(self, plane, water, Vector3(0.0, LOW_WATER_Y, 0.0))
	_water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
