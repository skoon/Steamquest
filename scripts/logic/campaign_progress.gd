class_name CampaignProgress
extends RefCounted
## Pure conversion between run state and plain dictionaries, plus the JSON save file.
## A checkpoint is { "level_index": int, "rig": Dictionary, "rumors": Array[Dictionary] }.

const SAVE_VERSION: int = 1


static func gear_to_dict(gear: GearItem) -> Dictionary:
	if gear == null:
		return {}
	return {
		"gear_name": gear.gear_name,
		"friction_rate": gear.friction_rate,
		"wear_rate": gear.wear_rate,
		"max_durability": gear.max_durability,
		"durability": gear.durability,
		"is_golden_gear": gear.is_golden_gear,
		"jam_chance_per_work": gear.jam_chance_per_work,
		"cooling_rate": gear.cooling_rate,
		"friction": gear.friction,
		"state": int(gear.state),
	}


## Inverse of gear_to_dict; an empty dictionary is an empty socket.
static func gear_from_dict(data: Dictionary) -> GearItem:
	if data.is_empty():
		return null
	var gear: GearItem = GearItem.new()
	gear.gear_name = String(data["gear_name"])
	gear.friction_rate = float(data["friction_rate"])
	gear.wear_rate = float(data["wear_rate"])
	gear.max_durability = float(data["max_durability"])
	gear.durability = float(data["durability"])
	gear.is_golden_gear = bool(data["is_golden_gear"])
	gear.jam_chance_per_work = float(data["jam_chance_per_work"])
	gear.cooling_rate = float(data["cooling_rate"])
	gear.friction = float(data["friction"])
	var state: int = int(data["state"])
	assert(state >= 0 and state < GearItem.GearState.size(), "CampaignProgress: bad gear state %d" % state)
	gear.state = state as GearItem.GearState
	return gear


static func rig_to_dict(rig: FrictionModel) -> Dictionary:
	var sockets: Array[Dictionary] = []
	for socket: int in FrictionModel.SOCKET_COUNT:
		sockets.append(gear_to_dict(rig.get_gear(socket)))
	return {"sockets": sockets, "golden_engaged": rig.golden_engaged}


static func rig_from_dict(data: Dictionary) -> FrictionModel:
	var sockets: Array = data["sockets"]
	assert(sockets.size() == FrictionModel.SOCKET_COUNT, "CampaignProgress: rig needs %d sockets" % FrictionModel.SOCKET_COUNT)
	var rig: FrictionModel = FrictionModel.new()
	for socket: int in FrictionModel.SOCKET_COUNT:
		rig.set_gear(socket, gear_from_dict(sockets[socket] as Dictionary))
	rig.golden_engaged = bool(data["golden_engaged"])
	return rig


## Rumors in discovery order.
static func rumors_to_array(rumors: Dictionary, order: Array[StringName]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for rumor_id: StringName in order:
		var rumor: RumorData = rumors[rumor_id] as RumorData
		out.append({"rumor_id": String(rumor.rumor_id), "title": rumor.title, "body": rumor.body, "hint": rumor.hint})
	return out


static func rumors_from_array(data: Array) -> Array[RumorData]:
	var out: Array[RumorData] = []
	for entry: Variant in data:
		var fields: Dictionary = entry as Dictionary
		var rumor: RumorData = RumorData.new()
		rumor.rumor_id = StringName(String(fields["rumor_id"]))
		rumor.title = String(fields["title"])
		rumor.body = String(fields["body"])
		rumor.hint = String(fields["hint"])
		out.append(rumor)
	return out


static func make_checkpoint(level_index: int, rig: FrictionModel, rumors: Dictionary, order: Array[StringName]) -> Dictionary:
	assert(level_index >= 0, "CampaignProgress.make_checkpoint: level_index must be non-negative")
	return {"level_index": level_index, "rig": rig_to_dict(rig), "rumors": rumors_to_array(rumors, order)}


static func write_save(path: String, checkpoint: Dictionary) -> Error:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var payload: Dictionary = checkpoint.duplicate()
	payload["version"] = SAVE_VERSION
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return OK


## Returns the saved checkpoint, or an empty dictionary when there is no save file.
## A file that exists but can't be parsed is a bug or corruption, so it fails loudly.
static func read_save(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	assert(parsed is Dictionary, "CampaignProgress.read_save: %s is not a valid save" % path)
	var data: Dictionary = parsed as Dictionary
	assert(int(data.get("version", -1)) == SAVE_VERSION, "CampaignProgress.read_save: %s has an unknown save version" % path)
	data.erase("version")
	data["level_index"] = int(data["level_index"])
	return data


static func delete_save(path: String) -> void:
	if FileAccess.file_exists(path):
		var error: Error = DirAccess.remove_absolute(path)
		assert(error == OK, "CampaignProgress.delete_save: cannot remove %s" % path)
