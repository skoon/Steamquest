class_name DecorProp
extends Node3D
## Billboarded decor sprite (boiler tanks, tesla coils...) with an optional cylinder collider.

@export var texture: Texture2D
@export var pixel_size: float = 0.012
@export var has_collision: bool = true
@export var collision_radius: float = 0.8
@export var collision_height: float = 2.0
@export var tint: Color = Color.WHITE


func _ready() -> void:
	assert(texture != null, "%s: texture is required" % name)
	var sprite: Sprite3D = Sprite3D.new()
	sprite.texture = texture
	sprite.pixel_size = pixel_size
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.double_sided = true
	sprite.modulate = tint
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.position = Vector3(0.0, float(texture.get_height()) * pixel_size * 0.5, 0.0)
	add_child(sprite)
	add_child(Fx.make_blob_shadow(collision_radius * 1.1))
	if has_collision:
		Layers.add_static_cylinder(self, collision_radius, collision_height, Vector3.ZERO)
