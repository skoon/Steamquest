class_name DoorLockPanel
extends Interactable
## Interaction volume of a SteamDoor; forwards prompts and use to its door.

var door: SteamDoor


func get_prompt() -> String:
	return door.get_panel_prompt()


func can_interact() -> bool:
	return door != null and not door.is_open


func interact(_technician: Node3D) -> void:
	door.use_panel()
