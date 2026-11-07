class_name KeyPickup
extends Area3D
## A key item lying in the level (the clockwork winding key, a blueprint page). Walking over it
## adds `item_id` to GameState.items, which ITEM-locked SteamDoors check, and unlocks `unlock_id`
## when set, which ALL_OF doors count (three pages open the archive lift).

const SPIN_SPEED: float = 1.6
const BOB_HEIGHT: float = 0.15
const KEY_TEXTURE: Texture2D = preload("res://assets/sprites/decor/wind_up_key.png")

enum Look { WINDING_KEY, BLUEPRINT_PAGE, FOUNDRY_SEAL }

@export var item_id: StringName = &""
@export var display_name: String = "Winding Key"
@export var unlock_id: StringName = &""
@export var look: Look = Look.WINDING_KEY
## Clutter keeps this far away (read by FoundryBuilder through the `radius` property).
@export var radius: float = 0.8

var is_collected: bool = false
var _visual: Node3D
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
	if look == Look.BLUEPRINT_PAGE:
		_visual = _build_page()
	elif look == Look.FOUNDRY_SEAL:
		_visual = _build_seal()
	else:
		_visual = Sprite3D.new()
		(_visual as Sprite3D).texture = KEY_TEXTURE
		(_visual as Sprite3D).pixel_size = 0.006
		(_visual as Sprite3D).alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		(_visual as Sprite3D).double_sided = true
		(_visual as Sprite3D).shaded = false
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
	if unlock_id != &"":
		GameState.unlock_door(unlock_id)
	GameState.post_notice("Picked up the %s" % display_name)
	Fx.sparks(get_parent(), global_position + Vector3.UP * 0.9)
	Audio.play_at(&"key_pickup", global_position)
	queue_free()


## A rolled-open blueprint sheet: blue paper with white ruled lines.
func _build_page() -> Node3D:
	var page: Node3D = Node3D.new()
	var sheet: QuadMesh = QuadMesh.new()
	sheet.size = Vector2(0.6, 0.45)
	var paper: StandardMaterial3D = FoundryMaterials.emissive(Color(0.2, 0.4, 0.85), 0.6)
	paper.cull_mode = BaseMaterial3D.CULL_DISABLED
	Layers.add_mesh(page, sheet, paper, Vector3.ZERO)
	var line: QuadMesh = QuadMesh.new()
	line.size = Vector2(0.48, 0.02)
	var ink: StandardMaterial3D = FoundryMaterials.emissive(Color(0.9, 0.95, 1.0), 1.0)
	ink.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i: int in 4:
		Layers.add_mesh(page, line, ink, Vector3(0.0, 0.15 - float(i) * 0.1, 0.005))
	return page


## The Foundry Seal: a brass medallion with the Hargreaves cog in its face.
func _build_seal() -> Node3D:
	var seal: Node3D = Node3D.new()
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = 0.32
	disc.bottom_radius = 0.32
	disc.height = 0.06
	var face: MeshInstance3D = Layers.add_mesh(seal, disc, FoundryMaterials.emissive(Color(0.95, 0.72, 0.3), 0.5), Vector3.ZERO)
	face.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	var cog: Node3D = GearMeshFactory.build(0.2, 0.1, 10, FoundryMaterials.get_material(FoundryMaterials.Kind.DARK_STEEL))
	cog.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	seal.add_child(cog)
	return seal
