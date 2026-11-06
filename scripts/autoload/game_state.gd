extends Node
## Global run state (autoload "GameState"). Scenes report into it; the HUD only listens to its signals.

signal health_changed(current: float, maximum: float)
signal pressure_changed(current: float, maximum: float)
signal friction_updated(total_friction: float, worst_wear_percent: float)
signal gears_changed(rig: FrictionModel)
signal overclock_changed(active: bool)
signal vent_cooldown_changed(time_left: float, total: float)
signal rumor_discovered(rumor: RumorData)
signal log_opened(rumor_id: StringName)
signal golden_gear_acquired
signal door_unlocked(door_id: StringName)
signal room_entered(room_name: String)
signal interaction_prompt_changed(text: String)
signal notice_posted(text: String)
signal gear_installed(socket: int, gear: GearItem)
signal player_died
signal victory
signal level_started(info: LevelInfo, index: int)
## Fired when a level's exit is used; the level root changes to `next_scene_path`.
signal level_completed(next_scene_path: String)

const STARTING_GEARS: Array[GearItem] = [
	preload("res://data/gears/drive_cog.tres"),
	preload("res://data/gears/arm_spur_gear.tres"),
	preload("res://data/gears/pump_pinion.tres"),
]
const CAMPAIGN: CampaignDef = preload("res://data/campaign.tres")
const DEFAULT_SAVE_PATH: String = "user://campaign_save.json"

var rig: FrictionModel
var rumors: Dictionary = {}
var rumor_order: Array[StringName] = []
var unlocked_doors: Dictionary = {}
var has_golden_gear: bool = false
var is_victorious: bool = false
var current_room: String = ""
var scrap_table: ScrapGearTable = ScrapGearTable.new()
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var campaign: CampaignDef = CAMPAIGN
## Tests point this somewhere else so they never touch the player's save.
var save_path: String = DEFAULT_SAVE_PATH
## Index into `campaign` of the level being played, or -1 before any level has started.
var level_index: int = -1
## Key items picked up in the current level (item_id -> true).
var items: Dictionary = {}
## Snapshot taken when the current level began; dying restores it.
var checkpoint: Dictionary = {}


func _init() -> void:
	rng.randomize()
	reset()


func reset() -> void:
	rig = FrictionModel.new()
	for socket: int in FrictionModel.SOCKET_COUNT:
		rig.set_gear(socket, STARTING_GEARS[socket].duplicate() as GearItem)
	rumors.clear()
	rumor_order.clear()
	unlocked_doors.clear()
	has_golden_gear = false
	is_victorious = false
	current_room = ""
	items.clear()
	level_index = -1
	checkpoint = {}


# --- Campaign --------------------------------------------------------------------

## Called by a level's root node when it loads. Restores the checkpoint when the same level is
## being replayed (death, or continuing a save); otherwise begins the level with the current rig.
func enter_level(scene_path: String) -> LevelInfo:
	var index: int = campaign.index_of_scene(scene_path)
	assert(index >= 0, "GameState.enter_level: %s is not in the campaign" % scene_path)
	if index == level_index and not checkpoint.is_empty() and int(checkpoint["level_index"]) == index:
		restore_checkpoint()
	else:
		begin_level(index)
	var info: LevelInfo = campaign.level(index)
	# Deferred: levels enter before their HUD is ready to listen.
	level_started.emit.call_deferred(info, index)
	return info


## Starts `index` fresh: per-level state is cleared, the rig carries over and is checkpointed and saved.
func begin_level(index: int) -> void:
	level_index = index
	_clear_level_state()
	checkpoint = CampaignProgress.make_checkpoint(index, rig, rumors, rumor_order)
	var error: Error = CampaignProgress.write_save(save_path, checkpoint)
	assert(error == OK, "GameState.begin_level: could not write save to %s (error %d)" % [save_path, error])


## Puts the rig and rumor log back to how they were when the current level began.
func restore_checkpoint() -> void:
	assert(not checkpoint.is_empty(), "GameState.restore_checkpoint: no checkpoint")
	rig = CampaignProgress.rig_from_dict(checkpoint["rig"] as Dictionary)
	rumors.clear()
	rumor_order.clear()
	for rumor: RumorData in CampaignProgress.rumors_from_array(checkpoint["rumors"] as Array):
		rumors[rumor.rumor_id] = rumor
		rumor_order.append(rumor.rumor_id)
	_clear_level_state()


## The current level's exit was used: advance, or win if this was the finale.
func complete_level() -> void:
	assert(level_index >= 0, "GameState.complete_level: no level in progress")
	var next: int = campaign.next_index(level_index)
	if next < 0:
		declare_victory()
		return
	level_index = next
	level_completed.emit(campaign.level(next).scene_path)


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


## Wipes progress and returns the first level's scene path.
func new_campaign() -> String:
	CampaignProgress.delete_save(save_path)
	reset()
	return campaign.level(0).scene_path


## Loads the save and returns the scene path to resume at.
func continue_campaign() -> String:
	var data: Dictionary = CampaignProgress.read_save(save_path)
	assert(not data.is_empty(), "GameState.continue_campaign: no save at %s" % save_path)
	reset()
	checkpoint = data
	level_index = int(data["level_index"])
	restore_checkpoint()
	return campaign.level(level_index).scene_path


func add_item(item_id: StringName) -> void:
	assert(item_id != &"", "GameState.add_item: item needs an id")
	items[item_id] = true


func has_item(item_id: StringName) -> bool:
	return items.has(item_id)


func _clear_level_state() -> void:
	rig.wear_multiplier = 1.0
	unlocked_doors.clear()
	items.clear()
	has_golden_gear = rig.golden_engaged
	is_victorious = false
	current_room = ""


## Records a rumor. Returns true only the first time a given rumor_id is discovered.
func discover_rumor(rumor: RumorData) -> bool:
	assert(rumor != null and rumor.rumor_id != &"", "GameState.discover_rumor: rumor needs an id")
	if rumors.has(rumor.rumor_id):
		return false
	rumors[rumor.rumor_id] = rumor
	rumor_order.append(rumor.rumor_id)
	rumor_discovered.emit(rumor)
	return true


func has_rumor(rumor_id: StringName) -> bool:
	return rumors.has(rumor_id)


func get_rumor(rumor_id: StringName) -> RumorData:
	return rumors.get(rumor_id) as RumorData


func open_log(rumor_id: StringName) -> void:
	log_opened.emit(rumor_id)


func unlock_door(door_id: StringName) -> void:
	if unlocked_doors.has(door_id):
		return
	unlocked_doors[door_id] = true
	door_unlocked.emit(door_id)


func is_door_unlocked(door_id: StringName) -> bool:
	return unlocked_doors.has(door_id)


func acquire_golden_gear(golden: GearItem) -> void:
	if has_golden_gear:
		return
	rig.engage_golden_gear(golden)
	has_golden_gear = true
	golden_gear_acquired.emit()
	notify_rig_changed()


## Installs a scavenged gear into the socket that needs it most. Returns that socket, or -1 if none.
func install_scavenged_gear(gear: GearItem) -> int:
	var socket: int = rig.most_worn_socket()
	if socket < 0:
		return -1
	rig.set_gear(socket, gear)
	gear_installed.emit(socket, gear)
	notify_rig_changed()
	return socket


func roll_scrap_gear() -> GearItem:
	return scrap_table.roll(rng)


func notify_rig_changed() -> void:
	gears_changed.emit(rig)
	friction_updated.emit(rig.total_friction(), rig.worst_wear_percent())


func enter_room(room_name: String) -> void:
	if room_name == current_room:
		return
	current_room = room_name
	room_entered.emit(room_name)


func post_notice(text: String) -> void:
	notice_posted.emit(text)


func declare_victory() -> void:
	if is_victorious:
		return
	is_victorious = true
	CampaignProgress.delete_save(save_path)
	victory.emit()
