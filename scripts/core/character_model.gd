class_name CharacterModel
extends Node3D
## A character or enemy built from a GLB model in assets/models, animated procedurally by
## rotating its rig nodes (`<model>_Rig_leg_l`, `_Rig_arm_r`, ...): the packs only ship a static
## showcase pose. Keeps the small API the gameplay code used with the old billboard sprites:
## idle / walk / attack / death, a walk-cycle `frame` with `frame_changed` for footsteps,
## `speed_scale`, `modulate` (tint and fade) and `flash_hit`.

signal frame_changed

## How the rig is animated. STATIC models (turret, boss) only turn and bob.
enum Rig { BIPED, QUADRUPED, SPIDER, HOVER, STATIC }

const OVERLAY_SHADER: Shader = preload("res://scripts/core/character_overlay.gdshader")
const FLASH_COLOR: Color = Color(1.0, 0.3, 0.25)
const WALK_FRAMES: int = 4
const ATTACK_TIME: float = 0.35
const DEATH_TIME: float = 0.55
const MOVING_SPEED: float = 0.3

@export var model_pack: String = ModelLibrary.PLAYERS_FEMALE
@export var model_name: String = "player_woman_athletic"
@export var model_height: float = 1.75
@export var rig: Rig = Rig.BIPED
## Centre the model on this node instead of standing it on it (hovering drones).
@export var center_vertically: bool = false
## Walk cycles per second at `stride_speed` metres per second.
@export var cycle_rate: float = 1.6
@export var stride_speed: float = 4.0
## Leg / arm swing in radians at full stride.
@export var swing: float = 0.6
## Turn toward the direction of travel. Off when the owner calls `face()` itself.
@export var face_movement: bool = true
@export var turn_speed: float = 10.0
## Constant tint mixed over the model (Color.WHITE = none); combined with `modulate`.
@export var tint: Color = Color.WHITE

var animation: StringName = &"idle"
var frame: int = 0
var speed_scale: float = 1.0
var modulate: Color = Color.WHITE:
	set(value):
		modulate = value
		_apply_overlay()

var _model: Node3D
var _pivot: Node3D
var _meshes: Array[GeometryInstance3D] = []
var _overlay: ShaderMaterial
## Rig role -> Array of {node, rest} dictionaries; see _collect_rig.
var _parts: Dictionary = {}
var _phase: float = 0.0
var _stride: float = 0.0
var _anim_time: float = 0.0
var _playing: bool = true
var _flash_left: float = 0.0
var _target_yaw: float = 0.0


func _ready() -> void:
	_pivot = Node3D.new()
	_pivot.name = "Pivot"
	add_child(_pivot)
	_model = ModelLibrary.instance_fitted(model_pack, model_name, model_height, center_vertically)
	_pivot.add_child(_model)
	_collect_meshes(_model)
	_collect_rig()
	_overlay = ShaderMaterial.new()
	_overlay.shader = OVERLAY_SHADER
	for mesh: GeometryInstance3D in _meshes:
		mesh.material_overlay = _overlay
	_target_yaw = _pivot.rotation.y
	_apply_overlay()


func _process(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left = maxf(_flash_left - delta, 0.0)
		_apply_overlay()
	_pivot.rotation.y = lerp_angle(_pivot.rotation.y, _target_yaw, clampf(turn_speed * delta, 0.0, 1.0))
	if not _playing:
		return
	var scaled: float = delta * speed_scale
	_anim_time += scaled
	match animation:
		&"walk":
			_phase = fmod(_phase + scaled * TAU * cycle_rate * clampf(_stride / stride_speed, 0.5, 1.6), TAU)
			_update_frame()
		&"attack":
			if _anim_time >= ATTACK_TIME:
				animation = &"idle"
				_anim_time = 0.0
		&"death":
			if _anim_time >= DEATH_TIME:
				_anim_time = DEATH_TIME
				_playing = false
	_pose()


## Picks idle or walk from a world-space velocity and turns toward it.
func play_locomotion(world_velocity: Vector3) -> void:
	if animation == &"death" or (animation == &"attack" and _playing):
		return
	var flat: Vector3 = Vector3(world_velocity.x, 0.0, world_velocity.z)
	_stride = flat.length()
	if _stride < MOVING_SPEED:
		_play_if_changed(&"idle")
		return
	_play_if_changed(&"walk")
	if face_movement:
		face(flat)


## Turns the model's front (+Z) toward the world-space `direction` on the ground plane.
func face(direction: Vector3) -> void:
	var local: Vector3 = global_basis.inverse() * direction if is_inside_tree() else direction
	if Vector2(local.x, local.z).length_squared() < 0.0001:
		return
	_target_yaw = atan2(local.x, local.z)


## Snaps to the facing instead of turning toward it.
func face_immediately(direction: Vector3) -> void:
	face(direction)
	_pivot.rotation.y = _target_yaw


func facing_yaw() -> float:
	return _pivot.rotation.y


func play(anim: StringName) -> void:
	assert(anim in [&"idle", &"walk", &"attack", &"death"], "CharacterModel: unknown animation %s" % anim)
	animation = anim
	_anim_time = 0.0
	_playing = true
	if anim == &"walk":
		_phase = 0.0
		frame = 0


func is_playing() -> bool:
	return _playing


func play_attack() -> void:
	play(&"attack")


func play_death() -> void:
	play(&"death")


func flash_hit(duration: float = 0.12) -> void:
	_flash_left = duration
	_apply_overlay()


func rig_part_count(role: StringName) -> int:
	return (_parts.get(role, []) as Array).size()


func _play_if_changed(anim: StringName) -> void:
	if animation != anim or not _playing:
		play(anim)


func _update_frame() -> void:
	var next: int = int(_phase / TAU * float(WALK_FRAMES)) % WALK_FRAMES
	if next != frame:
		frame = next
		frame_changed.emit()


# --- Overlay ------------------------------------------------------------------

func _apply_overlay() -> void:
	if _overlay == null:
		return
	var tone: Color = Color(tint.r * modulate.r, tint.g * modulate.g, tint.b * modulate.b)
	var tone_strength: float = 0.0 if tone.is_equal_approx(Color.WHITE) else 0.45
	var flash: float = 0.65 if _flash_left > 0.0 else 0.0
	_overlay.set_shader_parameter(&"tint_color", FLASH_COLOR if flash > 0.0 else tone)
	_overlay.set_shader_parameter(&"tint_strength", maxf(flash, tone_strength))
	var fade: float = clampf(1.0 - modulate.a, 0.0, 1.0)
	for mesh: GeometryInstance3D in _meshes:
		mesh.transparency = fade


# --- Rig ----------------------------------------------------------------------

func _collect_meshes(node: Node) -> void:
	if node is GeometryInstance3D:
		_meshes.append(node as GeometryInstance3D)
	for child: Node in node.get_children():
		_collect_meshes(child)


## Rig nodes are named `<model>_Rig_<part>`; each role keeps the part's rest pose.
func _collect_rig() -> void:
	var roles: Dictionary = {
		&"leg_l": ["leg_l", "leg_fl", "leg_br"],
		&"leg_r": ["leg_r", "leg_fr", "leg_bl"],
		&"arm_l": ["arm_l"],
		&"arm_r": ["arm_r"],
		&"torso": ["torso"],
		&"head": ["head"],
		&"body": ["pelvis", "body"],
		&"tail": ["tail"],
		&"jaw": ["jaw"],
		&"gimbal": ["gimbal_outer", "gimbal_mid", "gimbal_inner", "arcs"],
		&"gears": ["gear_main_l", "gear_main_r", "gear_small_l", "gear_small_r"],
		&"spider_a": ["leg_L0", "leg_R1", "leg_L2", "leg_R3"],
		&"spider_b": ["leg_R0", "leg_L1", "leg_R2", "leg_L3"],
	}
	var by_suffix: Dictionary = {}
	_index_rig(_model, by_suffix)
	for role: StringName in roles:
		var entries: Array = []
		for suffix: String in roles[role]:
			if by_suffix.has(suffix):
				var node: Node3D = by_suffix[suffix]
				entries.append({"node": node, "rest": node.transform})
		_parts[role] = entries


func _index_rig(node: Node, by_suffix: Dictionary) -> void:
	var marker: int = String(node.name).find("_Rig_")
	if marker >= 0 and node is Node3D:
		by_suffix[String(node.name).substr(marker + 5)] = node
	for child: Node in node.get_children():
		_index_rig(child, by_suffix)


func _pose() -> void:
	var walk: float = sin(_phase) if animation == &"walk" else 0.0
	var breath: float = sin(Time.get_ticks_msec() * 0.003)
	_pivot.position = Vector3.ZERO
	_pivot.rotation.x = 0.0
	_pivot.rotation.z = 0.0
	match rig:
		Rig.BIPED:
			_rotate(&"leg_l", Vector3.RIGHT, -walk * swing)
			_rotate(&"leg_r", Vector3.RIGHT, walk * swing)
			_rotate(&"arm_l", Vector3.RIGHT, walk * swing * 0.7)
			_rotate(&"arm_r", Vector3.RIGHT, -walk * swing * 0.7 + _attack_arm())
			_rotate(&"torso", Vector3.RIGHT, breath * 0.02 + _attack_curve() * 0.15)
			_rotate(&"head", Vector3.UP, 0.0)
			_pivot.position.y = absf(walk) * 0.04 * model_height / 1.75
		Rig.QUADRUPED:
			_rotate(&"leg_l", Vector3.RIGHT, -walk * swing)
			_rotate(&"leg_r", Vector3.RIGHT, walk * swing)
			_rotate(&"tail", Vector3.UP, sin(Time.get_ticks_msec() * 0.008) * 0.4)
			_rotate(&"head", Vector3.RIGHT, _attack_curve() * 0.5 + breath * 0.03)
			_rotate(&"jaw", Vector3.RIGHT, _attack_curve() * 0.6)
			_spin(&"gears", 0.004)
			_pivot.position.y = absf(walk) * 0.03
		Rig.SPIDER:
			var gait: float = walk * swing * 0.6
			_rotate(&"spider_a", Vector3.UP, gait)
			_rotate(&"spider_b", Vector3.UP, -gait)
			_rotate(&"body", Vector3.RIGHT, -_attack_curve() * 0.35 + breath * 0.02)
			_pivot.position.y = absf(walk) * 0.025
		Rig.HOVER:
			_spin(&"gimbal", 0.003 + _attack_curve() * 0.02)
			_pivot.position.y = breath * 0.08
			_pivot.rotation.x = clampf(_stride / stride_speed, 0.0, 1.0) * 0.2
		Rig.STATIC:
			_pivot.position.y = absf(walk) * 0.06 * model_height / 2.0
			_pivot.rotation.x = -_attack_curve() * 0.12
	if animation == &"death":
		var t: float = clampf(_anim_time / DEATH_TIME, 0.0, 1.0)
		var ease_t: float = t * t
		if rig == Rig.HOVER:
			_pivot.position.y -= ease_t * model_height
			_pivot.rotation.z = ease_t * 0.6
		else:
			_pivot.rotation.x = -ease_t * PI * 0.48
			_pivot.position.y = -ease_t * 0.1


## 0 -> 1 -> 0 over the attack.
func _attack_curve() -> float:
	if animation != &"attack":
		return 0.0
	return sin(clampf(_anim_time / ATTACK_TIME, 0.0, 1.0) * PI)


## The right arm raises forward, then chops down.
func _attack_arm() -> float:
	if animation != &"attack":
		return 0.0
	var t: float = clampf(_anim_time / ATTACK_TIME, 0.0, 1.0)
	return -2.3 * sin(t * PI) if t < 0.5 else -2.3 * sin(t * PI) * 0.6


func _rotate(role: StringName, axis: Vector3, angle: float) -> void:
	for entry: Dictionary in _parts.get(role, []):
		var node: Node3D = entry["node"]
		var rest: Transform3D = entry["rest"]
		node.transform = Transform3D(rest.basis * Basis(axis, angle), rest.origin)


## Turns gears about their axle (x) and drone gimbals about alternating axes.
func _spin(role: StringName, rate: float) -> void:
	var angle: float = Time.get_ticks_msec() * rate
	var index: int = 0
	for entry: Dictionary in _parts.get(role, []):
		var node: Node3D = entry["node"]
		var rest: Transform3D = entry["rest"]
		var axis: Vector3 = Vector3.RIGHT if role == &"gears" else [Vector3.UP, Vector3.RIGHT, Vector3.FORWARD][index % 3]
		node.transform = Transform3D(rest.basis * Basis(axis, angle * (1.0 + 0.3 * index)), rest.origin)
		index += 1
