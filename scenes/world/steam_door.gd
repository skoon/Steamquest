class_name SteamDoor
extends Node3D
## Steam-locked bulkhead between rooms. Spans the Z axis (sits in a wall running along Z).
## Opens when GameState reports `door_id` unlocked; the unlock condition decides who does that.

enum UnlockCondition {
	## Anyone may open it from the lock panel.
	NONE,
	## Opened externally via GameState.unlock_door (e.g. a JammedValve).
	EXTERNAL,
	## Opens from the lock panel once the named rumor has been read.
	RUMOR,
	## Opens automatically when the Golden Gear is acquired.
	GOLDEN_GEAR,
	## Opens automatically once every id in required_unlock_ids is unlocked (e.g. two valves).
	ALL_OF,
	## Opens from the lock panel while the Technician carries required_item_id.
	ITEM,
}

const LOCKED_COLOR: Color = Color(1.0, 0.2, 0.1)
const OPEN_COLOR: Color = Color(0.3, 1.0, 0.4)

@export var door_id: StringName = &""
@export var condition: UnlockCondition = UnlockCondition.EXTERNAL
@export var required_rumor_id: StringName = &""
@export var required_unlock_ids: Array[StringName] = []
@export var required_item_id: StringName = &""
@export var item_prompt: String = "[F] Wind the clockwork door"
@export var locked_hint: String = "The bulkhead is steam-locked."
@export var opening_width: float = 4.0
@export var door_height: float = 3.2
@export var thickness: float = 0.5

var is_open: bool = false
var _panels: Array[Node3D] = []
var _body: StaticBody3D
var _lamp_material: StandardMaterial3D
var _lamp_light: OmniLight3D


func _ready() -> void:
	assert(door_id != &"", "%s: door_id is required" % name)
	assert(condition != UnlockCondition.RUMOR or required_rumor_id != &"", "%s: RUMOR doors need required_rumor_id" % name)
	assert(condition != UnlockCondition.ALL_OF or not required_unlock_ids.is_empty(), "%s: ALL_OF doors need required_unlock_ids" % name)
	assert(condition != UnlockCondition.ITEM or required_item_id != &"", "%s: ITEM doors need required_item_id" % name)
	_build()
	GameState.door_unlocked.connect(_on_door_unlocked)
	GameState.golden_gear_acquired.connect(_on_golden_gear_acquired)
	if GameState.is_door_unlocked(door_id):
		_open(false)


func get_panel_prompt() -> String:
	if is_open:
		return ""
	if condition == UnlockCondition.NONE:
		return "[F] Open bulkhead"
	if condition == UnlockCondition.RUMOR and GameState.has_rumor(required_rumor_id):
		return "[F] Enter override sequence"
	if condition == UnlockCondition.ITEM and GameState.has_item(required_item_id):
		return item_prompt
	return "[F] Inspect steam lock"


## True when every id in `ids` has been unlocked.
static func all_unlocked(ids: Array[StringName], unlocked: Dictionary) -> bool:
	for id: StringName in ids:
		if not unlocked.has(id):
			return false
	return true


static func count_unlocked(ids: Array[StringName], unlocked: Dictionary) -> int:
	var count: int = 0
	for id: StringName in ids:
		if unlocked.has(id):
			count += 1
	return count


func use_panel() -> void:
	if is_open:
		return
	match condition:
		UnlockCondition.NONE:
			GameState.unlock_door(door_id)
		UnlockCondition.RUMOR:
			if GameState.has_rumor(required_rumor_id):
				GameState.unlock_door(door_id)
			else:
				GameState.post_notice(locked_hint)
		UnlockCondition.ITEM:
			if GameState.has_item(required_item_id):
				GameState.unlock_door(door_id)
			else:
				GameState.post_notice(locked_hint)
		UnlockCondition.ALL_OF:
			GameState.post_notice("%s (%d/%d)" % [locked_hint, count_unlocked(required_unlock_ids, GameState.unlocked_doors), required_unlock_ids.size()])
		UnlockCondition.EXTERNAL, UnlockCondition.GOLDEN_GEAR:
			GameState.post_notice(locked_hint)


func _on_door_unlocked(unlocked_id: StringName) -> void:
	if unlocked_id == door_id and not is_open:
		_open(true)
	elif condition == UnlockCondition.ALL_OF and required_unlock_ids.has(unlocked_id) and all_unlocked(required_unlock_ids, GameState.unlocked_doors):
		GameState.unlock_door(door_id)


func _on_golden_gear_acquired() -> void:
	if condition == UnlockCondition.GOLDEN_GEAR:
		GameState.unlock_door(door_id)


func _open(animate: bool) -> void:
	is_open = true
	_body.collision_layer = 0
	_lamp_material.albedo_color = OPEN_COLOR
	_lamp_material.emission = OPEN_COLOR
	_lamp_light.light_color = OPEN_COLOR
	var slide: float = opening_width * 0.5
	for i: int in _panels.size():
		var panel: Node3D = _panels[i]
		var side: float = -1.0 if i == 0 else 1.0
		var target_z: float = side * (opening_width * 0.25 + slide)
		if animate:
			var tween: Tween = create_tween()
			tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(panel, "position:z", target_z, 1.2)
		else:
			panel.position.z = target_z
	if animate:
		Audio.play_at(&"door_open", global_position + Vector3.UP * 1.5)
		for i: int in 3:
			Fx.steam_puff(get_parent(), global_position + Vector3(0.0, 0.5 + float(i) * 0.9, 0.0))
		GameState.post_notice("Bulkhead unsealed")


func _build() -> void:
	var iron: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.DARK_STEEL)
	var brass: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.BRASS)
	var half_width: float = opening_width * 0.5
	for side: float in [-1.0, 1.0]:
		var panel: Node3D = Node3D.new()
		panel.position = Vector3(0.0, 0.0, side * opening_width * 0.25)
		add_child(panel)
		var slab: BoxMesh = BoxMesh.new()
		slab.size = Vector3(thickness * 0.6, door_height, half_width)
		Layers.add_mesh(panel, slab, iron, Vector3(0.0, door_height * 0.5, 0.0))
		var band: BoxMesh = BoxMesh.new()
		band.size = Vector3(thickness * 0.7, 0.18, half_width * 0.96)
		for y: float in [0.5, door_height * 0.5, door_height - 0.5]:
			Layers.add_mesh(panel, band, brass, Vector3(0.0, y, 0.0))
		var rivet_wheel: TorusMesh = TorusMesh.new()
		rivet_wheel.inner_radius = 0.2
		rivet_wheel.outer_radius = 0.32
		var wheel: MeshInstance3D = Layers.add_mesh(panel, rivet_wheel, brass, Vector3(thickness * 0.4, door_height * 0.5, -side * half_width * 0.3))
		wheel.rotation = Vector3(0.0, 0.0, PI * 0.5)
		_panels.append(panel)

	var lintel: BoxMesh = BoxMesh.new()
	lintel.size = Vector3(thickness * 1.4, 0.4, opening_width + 0.6)
	Layers.add_mesh(self, lintel, brass, Vector3(0.0, door_height + 0.2, 0.0))

	var lamp: SphereMesh = SphereMesh.new()
	lamp.radius = 0.16
	lamp.height = 0.32
	_lamp_material = FoundryMaterials.emissive(LOCKED_COLOR, 4.0)
	Layers.add_mesh(self, lamp, _lamp_material, Vector3(0.0, door_height + 0.6, 0.0))
	_lamp_light = OmniLight3D.new()
	_lamp_light.light_color = LOCKED_COLOR
	_lamp_light.light_energy = 1.5
	_lamp_light.omni_range = 4.0
	_lamp_light.position = Vector3(0.0, door_height + 0.6, 0.0)
	add_child(_lamp_light)

	_body = StaticBody3D.new()
	_body.collision_layer = Layers.ENVIRONMENT
	_body.collision_mask = 0
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(thickness, door_height, opening_width)
	shape_node.shape = box
	shape_node.position = Vector3(0.0, door_height * 0.5, 0.0)
	_body.add_child(shape_node)
	add_child(_body)

	var panel_trigger: DoorLockPanel = DoorLockPanel.new()
	panel_trigger.door = self
	panel_trigger.add_trigger_sphere(2.4, 1.0)
	add_child(panel_trigger)
