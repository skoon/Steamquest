class_name Interactable
extends Area3D
## Base for anything the Technician can use with the `interact` action.
## Lives on the Interactables physics layer and is detected by the player's InteractArea.


func _init() -> void:
	collision_layer = Layers.INTERACTABLES
	collision_mask = 0
	monitoring = false


## Text shown in the HUD prompt while this is the focused interactable.
func get_prompt() -> String:
	return "[F] Use"


func can_interact() -> bool:
	return true


func interact(_technician: Node3D) -> void:
	push_error("Interactable.interact not implemented on %s" % name)


## Adds the detection volume the player's InteractArea overlaps.
func add_trigger_sphere(radius: float, height_offset: float) -> void:
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = radius
	shape_node.shape = sphere
	shape_node.position = Vector3(0.0, height_offset, 0.0)
	add_child(shape_node)
