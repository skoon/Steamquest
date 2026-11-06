class_name HumidZone
extends Area3D
## A patch of hothouse steam. While the Technician stands in it every gear in the rig wears
## `wear_multiplier` times faster.

const NOTICE_INTERVAL_MSEC: int = 6000

## Footprint (x, z), centred on this node.
@export var size: Vector2 = Vector2(6.0, 6.0)
@export var wear_multiplier: float = 2.0

var _player_inside: bool = false
var _last_notice_msec: int = -NOTICE_INTERVAL_MSEC


func _ready() -> void:
	assert(wear_multiplier >= 1.0, "%s: wear_multiplier must be at least 1" % name)
	collision_layer = 0
	collision_mask = Layers.PLAYER
	monitorable = false
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(size.x, 2.5, size.y)
	shape_node.shape = box
	shape_node.position = Vector3(0.0, 1.25, 0.0)
	add_child(shape_node)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_visuals()


func is_player_inside() -> bool:
	return _player_inside


func _physics_process(_delta: float) -> void:
	# The rig can be swapped out (checkpoint restore), so keep re-asserting while inside.
	if _player_inside:
		GameState.rig.wear_multiplier = wear_multiplier


func _on_body_entered(body: Node3D) -> void:
	if not body is Technician:
		return
	_player_inside = true
	GameState.rig.wear_multiplier = wear_multiplier
	Audio.play_at(&"humid_hiss", body.global_position + Vector3.UP)
	var now: int = Time.get_ticks_msec()
	if now - _last_notice_msec >= NOTICE_INTERVAL_MSEC:
		_last_notice_msec = now
		GameState.post_notice("Thick hothouse steam - your gears grind faster in here.")


func _on_body_exited(body: Node3D) -> void:
	if not body is Technician:
		return
	_player_inside = false
	GameState.rig.wear_multiplier = 1.0


func _build_visuals() -> void:
	var mist: GPUParticles3D = Fx.make_steam_emitter(int(clampf(size.x * size.y * 0.8, 12.0, 64.0)), 4.0, 0.25, 70.0)
	var process: ParticleProcessMaterial = mist.process_material as ParticleProcessMaterial
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(size.x * 0.5, 0.2, size.y * 0.5)
	process.gravity = Vector3(0.0, 0.1, 0.0)
	mist.visibility_aabb = AABB(Vector3(-size.x, -1.0, -size.y), Vector3(size.x * 2.0, 6.0, size.y * 2.0))
	mist.position = Vector3(0.0, 0.3, 0.0)
	add_child(mist)
	var damp: BoxMesh = BoxMesh.new()
	damp.size = Vector3(size.x, 0.01, size.y)
	var sheen: StandardMaterial3D = StandardMaterial3D.new()
	sheen.albedo_color = Color(0.3, 0.45, 0.35, 0.28)
	sheen.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sheen.roughness = 0.1
	var floor_sheen: MeshInstance3D = Layers.add_mesh(self, damp, sheen, Vector3(0.0, 0.015, 0.0))
	floor_sheen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
