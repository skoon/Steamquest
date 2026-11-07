class_name RoomDef
extends Resource
## One rectangular foundry room. Rooms are laid out west-to-east along +X, centred on Z = 0.

@export var room_name: String = "Room"
@export var width: float = 20.0
@export var depth: float = 20.0
@export var floor_texture: Texture2D
@export var wall_texture: Texture2D
@export var floor_tint: Color = Color(1, 1, 1)
@export var light_color: Color = Color(1.0, 0.72, 0.45)
@export var light_energy: float = 2.0
## Cast-iron support pillars, in room-local X/Z coordinates.
@export var pillars: PackedVector2Array = PackedVector2Array()
## Open-air decks get a waist-high railing instead of the north and south walls, no pipes and
## no wall dressing. Things pushed through a railing gap fall off the level.
@export var open_air: bool = false
## Gaps in an open-air room's railing: (room-local X centre, side, width), side -1 north / +1 south.
@export var railing_gaps: PackedVector3Array = PackedVector3Array()

enum DressingTheme { BOILER, CUTTING, SMELTING, VAULT, YARD, TRAM, SHOWROOM, CISTERN, GARDEN, MINE, TOWER, ARCHIVE, GENERATOR }

@export_group("Dressing")
## Which clutter catalog FoundryProps uses for this room.
@export var dressing_theme: DressingTheme = DressingTheme.BOILER
## Seed for the clutter layout, so the room looks the same every run.
@export var dressing_seed: int = 1
## Props per metre of wall (floor scatter and wall fixtures scale from this too).
@export var clutter_density: float = 0.15
## Grime decals per square metre of floor (wall streaks scale from this too).
@export var grime_density: float = 0.5
