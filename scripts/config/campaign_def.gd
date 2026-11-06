class_name CampaignDef
extends Resource
## The ordered list of levels the Technician plays through. The last one is the finale.

@export var levels: Array[LevelInfo] = []


func level_count() -> int:
	return levels.size()


func level(index: int) -> LevelInfo:
	assert(index >= 0 and index < levels.size(), "CampaignDef.level: index %d out of range" % index)
	return levels[index]


func is_final(index: int) -> bool:
	return index == levels.size() - 1


## The level after `index`, or -1 when `index` is the finale.
func next_index(index: int) -> int:
	assert(index >= 0 and index < levels.size(), "CampaignDef.next_index: index %d out of range" % index)
	return -1 if is_final(index) else index + 1


## Position of the level whose scene is `scene_path`, or -1 if the campaign doesn't include it.
func index_of_scene(scene_path: String) -> int:
	for i: int in levels.size():
		if levels[i].scene_path == scene_path:
			return i
	return -1
