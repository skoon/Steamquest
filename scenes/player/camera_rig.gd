class_name CameraRig
extends Node3D
## Isometric orthographic camera that smoothly follows a target, zooms, and rotates in 90° steps.

@export var target_path: NodePath
@export var follow_speed: float = 8.0
@export var pitch_degrees: float = -35.264
@export var base_yaw_degrees: float = 45.0
@export var camera_distance: float = 40.0
@export var start_size: float = 18.0
@export var min_size: float = 10.0
@export var max_size: float = 30.0
@export var zoom_step: float = 1.5
@export var rotate_duration: float = 0.3

@onready var _yaw: Node3D = $Yaw
@onready var _pitch: Node3D = $Yaw/Pitch
@onready var camera: Camera3D = $Yaw/Pitch/Camera3D

var _target: Node3D
var _yaw_steps: int = 0
var _target_size: float = 18.0
var _yaw_tween: Tween


func _ready() -> void:
	_pitch.rotation_degrees = Vector3(pitch_degrees, 0.0, 0.0)
	_yaw.rotation_degrees = Vector3(0.0, base_yaw_degrees, 0.0)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.position = Vector3(0.0, 0.0, camera_distance)
	camera.near = 0.1
	camera.far = camera_distance * 3.0
	_target_size = clampf(start_size, min_size, max_size)
	camera.size = _target_size
	camera.current = true
	add_to_group(&"camera_rig")
	_target = get_node_or_null(target_path) as Node3D
	assert(_target != null, "CameraRig: target_path must point to a Node3D")
	global_position = _target.global_position
	# The orthographic camera sits far from the action, so hear from the follow pivot instead.
	# On the yaw node, stereo panning turns with the view.
	var listener: AudioListener3D = AudioListener3D.new()
	_yaw.add_child(listener)
	listener.make_current()


func _process(delta: float) -> void:
	if is_instance_valid(_target):
		global_position = global_position.lerp(_target.global_position, 1.0 - exp(-follow_speed * delta))
	camera.size = lerpf(camera.size, _target_size, 1.0 - exp(-10.0 * delta))


## Holds the view where it is, e.g. so the Technician can be seen sinking away on the lift.
func stop_following() -> void:
	_target = null


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("rotate_cam_left"):
		_rotate_steps(-1)
	elif event.is_action_pressed("rotate_cam_right"):
		_rotate_steps(1)
	elif event.is_action_pressed("zoom_in"):
		_target_size = clampf(_target_size - zoom_step, min_size, max_size)
	elif event.is_action_pressed("zoom_out"):
		_target_size = clampf(_target_size + zoom_step, min_size, max_size)


func _rotate_steps(direction: int) -> void:
	_yaw_steps += direction
	if _yaw_tween != null and _yaw_tween.is_valid():
		_yaw_tween.kill()
	_yaw_tween = create_tween()
	_yaw_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var target_yaw: float = base_yaw_degrees + 90.0 * float(_yaw_steps)
	_yaw_tween.tween_property(_yaw, "rotation_degrees:y", target_yaw, rotate_duration)
