class_name WindZone
extends Area3D
## Open-deck wind. Every so often a gust (announced by the windsock and a warning whistle) shoves
## the Technician and every automaton inside along `direction`, toward the railing gaps.

const NOTICE_INTERVAL_MSEC: int = 15000

## Footprint (x, z), centred on this node.
@export var size: Vector2 = Vector2(20.0, 14.0)
@export var direction: Vector3 = Vector3(0.0, 0.0, 1.0)
@export var strength: float = 7.0
@export var interval: float = 9.0
@export var warning_time: float = 1.5
@export var gust_time: float = 2.0
@export var phase_offset: float = 0.0
## Where the windsock pole stands, relative to this node.
@export var sock_offset: Vector3 = Vector3(0.0, 0.0, -5.0)

var gust: GustCycle
var _time: float = 0.0
var _last_phase: HazardCycle.Phase = HazardCycle.Phase.IDLE
var _sock: Node3D
var _last_notice_msec: int = -NOTICE_INTERVAL_MSEC


func _ready() -> void:
	gust = GustCycle.new(interval, warning_time, gust_time, direction, strength, phase_offset)
	collision_layer = 0
	collision_mask = Layers.PLAYER | Layers.ENEMIES
	monitorable = false
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(size.x, 4.0, size.y)
	shape_node.shape = box
	shape_node.position = Vector3(0.0, 2.0, 0.0)
	add_child(shape_node)
	_build_windsock()


func current_phase() -> HazardCycle.Phase:
	return gust.phase_at(_time)


## Skips the clock ahead (tests jump straight to a gust).
func advance_time(seconds: float) -> void:
	_time += seconds


func _physics_process(delta: float) -> void:
	_time += delta
	var phase: HazardCycle.Phase = gust.phase_at(_time)
	if phase != _last_phase:
		_on_phase_changed(phase)
		_last_phase = phase
	var force: Vector3 = gust.force_at(_time)
	_animate_sock(phase, force.length())
	if force == Vector3.ZERO:
		return
	for body: Node3D in get_overlapping_bodies():
		if body.has_method("apply_push"):
			body.call("apply_push", force)


func _on_phase_changed(phase: HazardCycle.Phase) -> void:
	match phase:
		HazardCycle.Phase.WARNING:
			Audio.play_at(&"wind_warning", global_position + sock_offset + Vector3.UP * 3.0)
			var now: int = Time.get_ticks_msec()
			if now - _last_notice_msec >= NOTICE_INTERVAL_MSEC and _player_inside():
				_last_notice_msec = now
				GameState.post_notice("The windsock snaps taut - a gust is coming. Brace away from the gaps!")
		HazardCycle.Phase.ACTIVE:
			Audio.play_at(&"wind_gust", global_position + Vector3.UP * 2.0)


func _player_inside() -> bool:
	for body: Node3D in get_overlapping_bodies():
		if body is Technician:
			return true
	return false


func _animate_sock(phase: HazardCycle.Phase, force: float) -> void:
	var lift: float = 0.0
	match phase:
		HazardCycle.Phase.IDLE:
			lift = 0.3 + sin(_time * 1.3) * 0.1
		HazardCycle.Phase.WARNING:
			lift = 0.8 + sin(_time * 14.0) * 0.08
		HazardCycle.Phase.ACTIVE:
			lift = 0.9 + minf(force / maxf(strength, 0.01), 1.0) * 0.1 + sin(_time * 20.0) * 0.04
	# Hanging straight down at 0, streaming out along the wind at 1.
	_sock.rotation.x = -PI * 0.5 * lift


func _build_windsock() -> void:
	var iron: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.CAST_IRON)
	var pole: CylinderMesh = CylinderMesh.new()
	pole.top_radius = 0.05
	pole.bottom_radius = 0.07
	pole.height = 3.6
	Layers.add_mesh(self, pole, iron, sock_offset + Vector3(0.0, 1.8, 0.0))
	var mount: Node3D = Node3D.new()
	mount.position = sock_offset + Vector3(0.0, 3.5, 0.0)
	# The mount faces away from the wind (its -Z), so tipping the sock up about X streams it downwind.
	mount.basis = Basis.looking_at(-gust.direction, Vector3.UP)
	add_child(mount)
	_sock = Node3D.new()
	mount.add_child(_sock)
	var cone: CylinderMesh = CylinderMesh.new()
	cone.top_radius = 0.22
	cone.bottom_radius = 0.08
	cone.height = 1.1
	var cloth: StandardMaterial3D = FoundryMaterials.emissive(Color(0.95, 0.4, 0.12), 0.4)
	Layers.add_mesh(_sock, cone, cloth, Vector3(0.0, -0.55, 0.0))
