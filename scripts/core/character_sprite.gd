class_name CharacterSprite
extends AnimatedSprite3D
## Billboarded character built from the pixel sprite naming convention
## `<sprite_prefix>_<anim>_<n>.png` (n = 1..frame_count).

@export var sprite_prefix: String = "res://assets/sprites/players/player_woman_athletic"
@export var frame_count: int = 4
@export var looping_animations: PackedStringArray = PackedStringArray(["idle", "walk", "side_walk"])
@export var one_shot_animations: PackedStringArray = PackedStringArray(["attack", "death"])
@export var animation_fps: float = 8.0
## Whether the side_walk frames face screen-right (the supplied art faces left).
@export var side_faces_right: bool = false

var _flash_time_left: float = 0.0
var _base_modulate: Color = Color.WHITE


func _ready() -> void:
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	shaded = false
	double_sided = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_base_modulate = modulate
	sprite_frames = _build_frames()
	play(&"idle")


func _process(delta: float) -> void:
	if _flash_time_left > 0.0:
		_flash_time_left -= delta
		modulate = Color(1.0, 0.35, 0.3) if _flash_time_left > 0.0 else _base_modulate


func _build_frames() -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation(&"default")
	for anim: String in looping_animations:
		_add_animation(frames, anim, true)
	for anim: String in one_shot_animations:
		_add_animation(frames, anim, false)
	return frames


func _add_animation(frames: SpriteFrames, anim: String, loop: bool) -> void:
	frames.add_animation(anim)
	frames.set_animation_loop(anim, loop)
	frames.set_animation_speed(anim, animation_fps)
	for i: int in range(1, frame_count + 1):
		var path: String = "%s_%s_%d.png" % [sprite_prefix, anim, i]
		var texture: Texture2D = load(path) as Texture2D
		assert(texture != null, "CharacterSprite: missing frame %s" % path)
		frames.add_frame(anim, texture)


## Picks idle / walk / side_walk from a velocity expressed in screen space (x = right, y = down).
func play_locomotion(screen_velocity: Vector2) -> void:
	if animation == &"attack" and is_playing():
		return
	if screen_velocity.length() < 0.3:
		_play_if_changed(&"idle")
		return
	if sprite_frames.has_animation(&"side_walk") and absf(screen_velocity.x) > absf(screen_velocity.y) * 0.8:
		_play_if_changed(&"side_walk")
		var moving_right: bool = screen_velocity.x > 0.0
		flip_h = moving_right != side_faces_right
	else:
		_play_if_changed(&"walk")
		# Sets without side frames mirror the walk cycle toward the direction of travel.
		flip_h = false if sprite_frames.has_animation(&"side_walk") else screen_velocity.x < 0.0


func play_attack() -> void:
	play(&"attack")
	frame = 0


func play_death() -> void:
	play(&"death")


func flash_hit(duration: float = 0.12) -> void:
	_flash_time_left = duration
	modulate = Color(1.0, 0.35, 0.3)


func _play_if_changed(anim: StringName) -> void:
	if animation != anim or not is_playing():
		play(anim)
