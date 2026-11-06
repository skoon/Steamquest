class_name KeyPickup
extends Area3D
## A key item lying in the level (the clockwork winding key). Walking over it adds `item_id`
## to GameState.items, which ITEM-locked SteamDoors check.

const SPIN_SPEED: float = 1.6
const BOB_HEIGHT: float = 0.15
const KEY_TEXTURE: Texture2D = preload("res://assets/sprites/decor/wind_up_key.png")

@export var item_id: StringName = &""
@export var display_name: String = "Winding Key"
## Clutter keeps this far away (read by FoundryBuilder through the `radius` property).
@export var radius: float = 0.8

var is_collected: bool = false
var _visual: Sprite3D
var _time: float = 0.0


func _ready() -> void:
	assert(item_id != &"", "%s: item_id is required" % name)
	collision_layer = 0
	collision_mask = Layers.PLAYER
	monitorable = false
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 0.9
	shape_node.shape = sphere
	shape_node.position = Vector3(0.0, 0.6, 0.0)
	add_child(shape_node)
	_visual = Sprite3D.new()
	_visual.texture = KEY_TEXTURE
	_visual.pixel_size = 0.006
	_visual.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	_visual.double_sided = true
	_visual.shaded = false
	_visual.position = Vector3(0.0, 0.9, 0.0)
	add_child(_visual)
	var plinth: CylinderMesh = CylinderMesh.new()
	plinth.top_radius = 0.35
	plinth.bottom_radius = 0.45
	plinth.height = 0.3
	Layers.add_mesh(self, plinth, FoundryMaterials.get_material(FoundryMaterials.Kind.BRASS), Vector3(0.0, 0.15, 0.0))
	var glow: OmniLight3D = OmniLight3D.new()
	glow.light_color = Color(1.0, 0.85, 0.45)
	glow.light_energy = 1.4
	glow.omni_range = 2.5
	glow.position = Vector3(0.0, 1.0, 0.0)
	add_child(glow)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	_visual.rotation.y += SPIN_SPEED * delta
	_visual.position.y = 0.9 + sin(_time * 2.5) * BOB_HEIGHT


func _on_body_entered(body: Node3D) -> void:
	if is_collected or not (body is Technician):
		return
	is_collected = true
	GameState.add_item(item_id)
	GameState.post_notice("Picked up the %s" % display_name)
	Fx.sparks(get_parent(), global_position + Vector3.UP * 0.9)
	Audio.play_at(&"key_pickup", global_position)
	queue_free()
