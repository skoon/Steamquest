class_name EnemyStats
extends Resource
## Tunable numbers shared by all automatons.

@export var display_name: String = "Automaton"
@export var max_health: float = 40.0
@export var move_speed: float = 4.0
@export var armor: float = 0.0
## 0 = full knockback, 1 = immovable.
@export_range(0.0, 1.0) var knockback_resistance: float = 0.0
@export var aggro_range: float = 14.0

@export_group("Attack")
@export var attack_damage: float = 10.0
## Distance at which the automaton begins its attack.
@export var attack_range: float = 1.3
@export var attack_cooldown: float = 1.0
## Wind-up before the attack lands (telegraph / lunge / coil charge).
@export var telegraph_time: float = 0.25
## Radius of area attacks (Piston Bruiser slam).
@export var area_radius: float = 3.5
@export var attack_knockback: float = 6.0
## Speed of projectiles or lunges.
@export var projectile_speed: float = 14.0

@export_group("Loot")
@export_range(0.0, 1.0) var gear_drop_chance: float = 0.3
