class_name DecorProp
extends Node3D
## A decor model (boiler tanks, clocks...) from the assets/models packs, standing on the floor,
## with an optional cylinder collider.

@export var model_pack: String = ModelLibrary.PROPS
@export var model_name: String = ""
@export var model_height: float = 2.0
@export var has_collision: bool = true
@export var collision_radius: float = 0.8
@export var collision_height: float = 2.0


func _ready() -> void:
	assert(model_name != "", "%s: model_name is required" % name)
	add_child(ModelLibrary.instance_fitted(model_pack, model_name, model_height))
	if has_collision:
		Layers.add_static_cylinder(self, collision_radius, collision_height, Vector3.ZERO)
