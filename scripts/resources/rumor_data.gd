class_name RumorData
extends Resource
## A lore log found on a RumorTerminal.

@export var rumor_id: StringName = &""
@export var title: String = ""
@export_multiline var body: String = ""
## Short practical hint shown under the log (how to bypass a lock, etc.).
@export var hint: String = ""
