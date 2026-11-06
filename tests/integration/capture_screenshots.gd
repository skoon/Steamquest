extends Node
## Dev tool: renders the level windowed and saves screenshots of each room.
##   Godot.exe --path . res://tests/integration/capture_screenshots.tscn -- <output_dir> [level_scene]
## Defaults to user://screenshots and the finale. For the finale the hand-picked SHOTS are used;
## any other level gets one shot per room, slightly off each room's centre.

const DEFAULT_LEVEL: String = "res://scenes/world/foundry_level.tscn"
const TEST_SAVE: String = "user://test_screenshots_save.json"
const SHOTS: Dictionary = {
	"boiler_room": Vector3(-6.0, 0.05, 1.0),
	"gear_cutting_floor": Vector3(20.0, 0.05, 1.0),
	"smelting_vats": Vector3(48.0, 0.05, 3.0),
	"master_clock_vault": Vector3(66.0, 0.05, 2.0),
}
const SETTLE_FRAMES: int = 60


func _ready() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://screenshots"
	var dir_error: Error = DirAccess.make_dir_recursive_absolute(out_dir)
	assert(dir_error == OK, "capture_screenshots: cannot create %s" % out_dir)
	var level_path: String = args[1] if args.size() > 1 else DEFAULT_LEVEL
	GameState.save_path = TEST_SAVE
	GameState.reset()
	var level: Node3D = (load(level_path) as PackedScene).instantiate() as Node3D
	level.set("auto_advance", false)
	add_child(level)
	var player: Technician = level.get_node("Technician") as Technician
	for enemy: Node in get_tree().get_nodes_in_group(&"enemies"):
		enemy.set_physics_process(false)
	var shots: Dictionary = SHOTS if level_path == DEFAULT_LEVEL else _room_shots(level.get_node("Navigation") as FoundryBuilder)
	for shot_name: String in shots:
		player.global_position = shots[shot_name]
		for i: int in SETTLE_FRAMES:
			await get_tree().process_frame
		var path: String = out_dir.path_join(shot_name + ".png")
		var save_error: Error = get_viewport().get_texture().get_image().save_png(path)
		assert(save_error == OK, "capture_screenshots: failed to save %s" % path)
		print("saved ", path)
	CampaignProgress.delete_save(TEST_SAVE)
	get_tree().quit()


## Rooms are laid out along +X from start_x; stand a little west of and below each centre.
func _room_shots(builder: FoundryBuilder) -> Dictionary:
	var shots: Dictionary = {}
	var x: float = builder.start_x
	for room: RoomDef in builder.rooms:
		shots[room.room_name.to_snake_case()] = Vector3(x + room.width * 0.4, 0.05, 1.0)
		x += room.width
	return shots
