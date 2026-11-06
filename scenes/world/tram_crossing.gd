class_name TramCrossing
extends Node3D
## A pneumatic tram line crossing the room along local Z. On a fixed cycle the signal lamps flash
## and a bell rings, then a tram car thunders the length of the track, hitting the Technician and
## any automaton in its way once per pass.

## TRAM is the pneumatic passenger car; CART is a runaway mine ore cart (smaller, lower).
enum Style { TRAM, CART }

const CAR_LENGTH: float = 4.2
const CAR_WIDTH: float = 2.2
const CAR_HEIGHT: float = 2.5
const CART_LENGTH: float = 2.4
const CART_WIDTH: float = 1.6
const CART_HEIGHT: float = 1.5
const LAMP_FLASH_HZ: float = 3.0
const LAMP_OFF: Color = Color(0.25, 0.08, 0.04)
const LAMP_ON: Color = Color(1.0, 0.3, 0.08)

## Length of rail, centred on this node. Should span the room's depth.
@export var track_length: float = 20.0
@export var interval: float = 7.0
@export var warning_time: float = 1.6
@export var pass_time: float = 1.1
@export var phase_offset: float = 0.0
## +1 runs toward local +Z, -1 toward -Z.
@export var direction: float = 1.0
@export var damage: float = 28.0
@export var enemy_damage: float = 80.0
@export var knockback: float = 14.0
@export var style: Style = Style.TRAM

var cycle: HazardCycle
var _time: float = 0.0
var _car: Node3D
var _car_area: Area3D
var _lamp_materials: Array[StandardMaterial3D] = []
var _lamp_lights: Array[OmniLight3D] = []
var _last_phase: HazardCycle.Phase = HazardCycle.Phase.IDLE
var _hit_this_pass: Dictionary = {}
var _pass_index: int = -1
var _car_length: float = CAR_LENGTH
var _car_width: float = CAR_WIDTH
var _car_height: float = CAR_HEIGHT


func _ready() -> void:
	assert(absf(direction) == 1.0, "%s: direction must be 1 or -1" % name)
	cycle = HazardCycle.new(interval, warning_time, pass_time, phase_offset)
	if style == Style.CART:
		_car_length = CART_LENGTH
		_car_width = CART_WIDTH
		_car_height = CART_HEIGHT
	_build_track()
	_build_lamps()
	if style == Style.CART:
		_build_cart()
	else:
		_build_car()
	_build_car_area()
	_last_phase = cycle.phase_at(_time)


func is_running() -> bool:
	return cycle.phase_at(_time) == HazardCycle.Phase.ACTIVE


## Circles (x, z, radius) along the track for FoundryBuilder, so clutter never sits on the rails.
func keep_clear_zones() -> PackedVector3Array:
	var zones: PackedVector3Array = PackedVector3Array()
	var steps: int = int(ceil(track_length / 2.0))
	for i: int in steps + 1:
		var local_z: float = -track_length * 0.5 + track_length * float(i) / float(steps)
		var point: Vector3 = to_global(Vector3(0.0, 0.0, local_z))
		zones.append(Vector3(point.x, point.z, _car_width))
	return zones


func _physics_process(delta: float) -> void:
	_time += delta
	var phase: HazardCycle.Phase = cycle.phase_at(_time)
	if phase != _last_phase:
		_on_phase_changed(phase)
		_last_phase = phase
	_update_lamps(phase)
	_car.visible = phase == HazardCycle.Phase.ACTIVE
	if phase != HazardCycle.Phase.ACTIVE:
		return
	var travel: float = track_length + _car_length
	var along: float = -travel * 0.5 + travel * cycle.active_progress(_time)
	_car.position = Vector3(0.0, 0.0, along * direction)
	var pass_index: int = cycle.cycle_index(_time)
	if pass_index != _pass_index:
		_pass_index = pass_index
		_hit_this_pass.clear()
	for body: Node3D in _car_area.get_overlapping_bodies():
		_strike(body)


func _on_phase_changed(phase: HazardCycle.Phase) -> void:
	match phase:
		HazardCycle.Phase.WARNING:
			Audio.play_at(&"cart_rumble" if style == Style.CART else &"tram_bell", global_position + Vector3.UP * 2.0)
		HazardCycle.Phase.ACTIVE:
			Audio.play_at(&"tram_rush", global_position + Vector3.UP, -4.0 if style == Style.CART else 0.0)


func _strike(body: Node3D) -> void:
	var id: int = body.get_instance_id()
	if _hit_this_pass.has(id) or not body.has_method("receive_hit"):
		return
	if not (body is Technician or body is EnemyBase):
		return
	_hit_this_pass[id] = true
	var local: Vector3 = to_local(body.global_position)
	var side: float = 1.0 if local.x >= 0.0 else -1.0
	var push_local: Vector3 = Vector3(side, 0.0, direction * 0.5).normalized() * knockback
	var push: Vector3 = global_basis * push_local
	push.y = 0.0
	if body is EnemyBase:
		(body as EnemyBase).receive_crush_hit(enemy_damage, push)
	else:
		body.call("receive_hit", damage, push)
	Fx.sparks(get_parent(), body.global_position + Vector3.UP * 0.8)


func _update_lamps(phase: HazardCycle.Phase) -> void:
	var lit: bool = phase != HazardCycle.Phase.IDLE and fmod(_time * LAMP_FLASH_HZ, 1.0) < 0.5
	var color: Color = LAMP_ON if lit else LAMP_OFF
	for mat: StandardMaterial3D in _lamp_materials:
		mat.albedo_color = color
		mat.emission = color
	for light: OmniLight3D in _lamp_lights:
		light.light_energy = 2.5 if lit else 0.0


func _build_track() -> void:
	var steel: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.DARK_STEEL)
	var wood: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.WOOD)
	var bed: BoxMesh = BoxMesh.new()
	bed.size = Vector3(_car_width + 0.6, 0.02, track_length)
	Layers.add_mesh(self, bed, FoundryMaterials.get_material(FoundryMaterials.Kind.CAST_IRON), Vector3(0.0, 0.012, 0.0))
	var sleeper: BoxMesh = BoxMesh.new()
	sleeper.size = Vector3(_car_width + 0.2, 0.05, 0.25)
	var count: int = int(track_length / 0.8)
	for i: int in count:
		Layers.add_mesh(self, sleeper, wood, Vector3(0.0, 0.04, -track_length * 0.5 + 0.4 + 0.8 * float(i)))
	var rail: BoxMesh = BoxMesh.new()
	rail.size = Vector3(0.1, 0.08, track_length)
	for x: float in [-_car_width * 0.34, _car_width * 0.34]:
		Layers.add_mesh(self, rail, steel, Vector3(x, 0.09, 0.0))
	var hazard_stripe: BoxMesh = BoxMesh.new()
	hazard_stripe.size = Vector3(0.12, 0.022, track_length)
	var warning: StandardMaterial3D = FoundryMaterials.emissive(Color(0.9, 0.6, 0.1), 0.4)
	for x: float in [-(_car_width * 0.5 + 0.35), _car_width * 0.5 + 0.35]:
		Layers.add_mesh(self, hazard_stripe, warning, Vector3(x, 0.014, 0.0))


func _build_lamps() -> void:
	var iron: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.CAST_IRON)
	var post: CylinderMesh = CylinderMesh.new()
	post.top_radius = 0.06
	post.bottom_radius = 0.08
	post.height = 2.4
	var bulb: SphereMesh = SphereMesh.new()
	bulb.radius = 0.16
	bulb.height = 0.32
	var end_z: float = track_length * 0.5 - 1.0
	for corner: Vector2 in [Vector2(-1.8, -end_z), Vector2(1.8, end_z), Vector2(1.8, -end_z), Vector2(-1.8, end_z)]:
		Layers.add_mesh(self, post, iron, Vector3(corner.x, 1.2, corner.y))
		var mat: StandardMaterial3D = FoundryMaterials.emissive(LAMP_OFF, 4.0)
		Layers.add_mesh(self, bulb, mat, Vector3(corner.x, 2.5, corner.y))
		_lamp_materials.append(mat)
		var light: OmniLight3D = OmniLight3D.new()
		light.light_color = LAMP_ON
		light.light_energy = 0.0
		light.omni_range = 5.0
		light.position = Vector3(corner.x, 2.4, corner.y)
		add_child(light)
		_lamp_lights.append(light)


func _build_car() -> void:
	_car = Node3D.new()
	_car.name = "TramCar"
	_car.visible = false
	add_child(_car)
	var body_mat: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.COPPER_OXIDIZED)
	var brass: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.BRASS)
	var iron: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.CAST_IRON)
	var hull: BoxMesh = BoxMesh.new()
	hull.size = Vector3(CAR_WIDTH, CAR_HEIGHT - 0.5, CAR_LENGTH)
	Layers.add_mesh(_car, hull, body_mat, Vector3(0.0, 0.25 + (CAR_HEIGHT - 0.5) * 0.5, 0.0))
	var roof: CylinderMesh = CylinderMesh.new()
	roof.top_radius = CAR_WIDTH * 0.5
	roof.bottom_radius = CAR_WIDTH * 0.5
	roof.height = CAR_LENGTH
	var roof_instance: MeshInstance3D = Layers.add_mesh(_car, roof, brass, Vector3(0.0, CAR_HEIGHT - 0.25, 0.0))
	roof_instance.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	roof_instance.scale = Vector3(1.0, 1.0, 0.25)
	var band: BoxMesh = BoxMesh.new()
	band.size = Vector3(CAR_WIDTH + 0.04, 0.12, CAR_LENGTH + 0.04)
	for y: float in [0.45, 1.3]:
		Layers.add_mesh(_car, band, brass, Vector3(0.0, y, 0.0))
	var window: BoxMesh = BoxMesh.new()
	window.size = Vector3(CAR_WIDTH + 0.02, 0.5, 0.7)
	var glass: StandardMaterial3D = FoundryMaterials.emissive(Color(1.0, 0.8, 0.45), 1.5)
	for i: int in 4:
		Layers.add_mesh(_car, window, glass, Vector3(0.0, 1.65, -1.35 + 0.9 * float(i)))
	var bumper: BoxMesh = BoxMesh.new()
	bumper.size = Vector3(CAR_WIDTH * 0.8, 0.3, 0.2)
	for z: float in [-CAR_LENGTH * 0.5 - 0.1, CAR_LENGTH * 0.5 + 0.1]:
		Layers.add_mesh(_car, bumper, iron, Vector3(0.0, 0.4, z))
	var headlamp: OmniLight3D = OmniLight3D.new()
	headlamp.light_color = Color(1.0, 0.85, 0.55)
	headlamp.light_energy = 3.0
	headlamp.omni_range = 7.0
	headlamp.position = Vector3(0.0, 1.0, CAR_LENGTH * 0.5 * direction + direction)
	_car.add_child(headlamp)
	var steam: GPUParticles3D = Fx.make_steam_emitter(16, 0.6, 1.2, 40.0)
	steam.position = Vector3(0.0, CAR_HEIGHT, -CAR_LENGTH * 0.4 * direction)
	_car.add_child(steam)


func _build_cart() -> void:
	_car = Node3D.new()
	_car.name = "OreCart"
	_car.visible = false
	add_child(_car)
	var iron: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.CAST_IRON)
	var rust: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.RUST)
	var coal: StandardMaterial3D = StandardMaterial3D.new()
	coal.albedo_color = Color(0.07, 0.065, 0.06)
	coal.roughness = 0.5
	coal.metallic = 0.2
	var tub: BoxMesh = BoxMesh.new()
	tub.size = Vector3(CART_WIDTH, 0.9, CART_LENGTH)
	Layers.add_mesh(_car, tub, rust, Vector3(0.0, 0.75, 0.0))
	var lip: BoxMesh = BoxMesh.new()
	lip.size = Vector3(CART_WIDTH + 0.1, 0.1, CART_LENGTH + 0.1)
	Layers.add_mesh(_car, lip, iron, Vector3(0.0, 1.2, 0.0))
	var heap: SphereMesh = SphereMesh.new()
	heap.radius = CART_WIDTH * 0.48
	heap.height = 0.7
	var heap_instance: MeshInstance3D = Layers.add_mesh(_car, heap, coal, Vector3(0.0, 1.25, 0.0))
	heap_instance.scale = Vector3(1.0, 1.0, CART_LENGTH / CART_WIDTH)
	var wheel: CylinderMesh = CylinderMesh.new()
	wheel.top_radius = 0.28
	wheel.bottom_radius = 0.28
	wheel.height = 0.12
	for x: float in [-CART_WIDTH * 0.42, CART_WIDTH * 0.42]:
		for z: float in [-CART_LENGTH * 0.3, CART_LENGTH * 0.3]:
			var wheel_instance: MeshInstance3D = Layers.add_mesh(_car, wheel, iron, Vector3(x, 0.28, z))
			wheel_instance.rotation = Vector3(0.0, 0.0, PI * 0.5)
	var sparks: GPUParticles3D = Fx.make_ember_emitter(20)
	sparks.position = Vector3(0.0, 0.15, -CART_LENGTH * 0.5 * direction)
	_car.add_child(sparks)


func _build_car_area() -> void:
	_car_area = Area3D.new()
	_car_area.collision_layer = 0
	_car_area.collision_mask = Layers.PLAYER | Layers.ENEMIES
	_car_area.monitorable = false
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(_car_width + 0.4, _car_height, _car_length + 0.4)
	shape_node.shape = box
	shape_node.position = Vector3(0.0, _car_height * 0.5, 0.0)
	_car_area.add_child(shape_node)
	_car.add_child(_car_area)
