class_name LevelInfo
extends Resource
## One entry in the campaign: which scene to load and how the intro card names it.

@export var title: String = "Level"
@export var act_name: String = "Act I"
@export_file("*.tscn") var scene_path: String = ""
