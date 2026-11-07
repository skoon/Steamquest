class_name ModelLibrary
extends RefCounted
## Pulls single named models out of the GLB packs in assets/models. Each pack is one scene with
## many models side by side as named roots; a copy of one root is returned with its pack offset
## removed, optionally scaled to a target height with its lowest point on y = 0.

const ENEMIES: String = "res://assets/models/steampunk_enemies.glb"
const FURNITURE: String = "res://assets/models/steampunk_furniture_doors.glb"
const PLAYERS_FEMALE: String = "res://assets/models/steampunk_players_female.glb"
const PLAYERS_MALE: String = "res://assets/models/steampunk_players_male.glb"
const PROPS: String = "res://assets/models/steampunk_props.glb"

## "pack|model" -> PackedScene of that one model, split out of its pack on first use.
static var _models: Dictionary = {}


## A fresh copy of `model_name` from `pack`, at its natural size, with its root at the origin.
static func instance(pack: String, model_name: String) -> Node3D:
	var key: String = "%s|%s" % [pack, model_name]
	if not _models.has(key):
		_split_pack(pack)
	assert(_models.has(key), "ModelLibrary: no model '%s' in %s" % [model_name, pack])
	var copy: Node3D = (_models[key] as PackedScene).instantiate() as Node3D
	copy.transform = Transform3D.IDENTITY
	return copy


## A copy scaled uniformly so it stands `height` tall, with its lowest point on y = 0
## (or, with `center_vertically`, its middle on y = 0), centred over the origin in x and z.
static func instance_fitted(pack: String, model_name: String, height: float, center_vertically: bool = false) -> Node3D:
	assert(height > 0.0, "ModelLibrary: height must be positive")
	var model: Node3D = instance(pack, model_name)
	var bounds: AABB = local_bounds(model)
	assert(bounds.size.y > 0.0, "ModelLibrary: model '%s' has no visible geometry" % model_name)
	var factor: float = height / bounds.size.y
	var centre: Vector3 = bounds.get_center()
	var base_y: float = centre.y if center_vertically else bounds.position.y
	var holder: Node3D = Node3D.new()
	holder.name = model_name
	model.scale = Vector3.ONE * factor
	model.position = Vector3(-centre.x, -base_y, -centre.z) * factor
	holder.add_child(model)
	return holder


static func has_model(pack: String, model_name: String) -> bool:
	var key: String = "%s|%s" % [pack, model_name]
	if not _models.has(key):
		_split_pack(pack)
	return _models.has(key)


## Combined AABB of every visual under `node`, in `node`'s own space.
static func local_bounds(node: Node3D) -> AABB:
	return _bounds(node, Transform3D.IDENTITY, true)


static func _bounds(node: Node3D, to_root: Transform3D, is_root: bool) -> AABB:
	var xf: Transform3D = to_root if is_root else to_root * node.transform
	var result: AABB = AABB()
	var found: bool = false
	if node is VisualInstance3D:
		result = xf * (node as VisualInstance3D).get_aabb()
		found = true
	for child: Node in node.get_children():
		if not child is Node3D:
			continue
		var sub: AABB = _bounds(child as Node3D, xf, false)
		if sub.size == Vector3.ZERO and not child is VisualInstance3D:
			continue
		result = sub if not found else result.merge(sub)
		found = true
	return result


## Packs every root model of `pack` into its own PackedScene (cheap to instance repeatedly).
static func _split_pack(pack: String) -> void:
	var scene: PackedScene = load(pack) as PackedScene
	assert(scene != null, "ModelLibrary: cannot load %s" % pack)
	var root: Node = scene.instantiate()
	ModelPalette.apply(root)
	for child: Node in root.get_children():
		if not child is Node3D:
			continue
		_own_descendants(child, child)
		var packed: PackedScene = PackedScene.new()
		var error: Error = packed.pack(child)
		assert(error == OK, "ModelLibrary: cannot pack %s from %s" % [child.name, pack])
		_models["%s|%s" % [pack, child.name]] = packed
	root.free()


static func _own_descendants(node: Node, owner_node: Node) -> void:
	for child: Node in node.get_children():
		child.owner = owner_node
		_own_descendants(child, owner_node)
