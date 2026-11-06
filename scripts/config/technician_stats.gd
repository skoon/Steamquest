class_name TechnicianStats
extends Resource
## Tunable numbers for the Technician. Instances live in res://data/.

@export_group("Body")
@export var max_health: float = 120.0
@export var move_speed: float = 6.0
@export var acceleration: float = 40.0
@export var invulnerability_after_hit: float = 0.5

@export_group("Steam Dash")
@export var dash_speed: float = 18.0
@export var dash_duration: float = 0.18
@export var dash_cost: float = 20.0
@export var dash_cooldown: float = 0.6

@export_group("Heavy Wrench")
@export var wrench_damage: float = 25.0
@export var wrench_knockback: float = 9.0
@export var wrench_range: float = 2.3
@export var wrench_arc_degrees: float = 120.0
@export var wrench_cooldown: float = 0.45

@export_group("Steam Rivet Gun")
@export var rivet_damage: float = 14.0
@export var rivet_speed: float = 32.0
@export var rivet_cost: float = 12.0
@export var rivet_cooldown: float = 0.22
@export var rivet_lifetime: float = 1.2
@export var rivet_knockback: float = 3.0

@export_group("Steam Pressure")
@export var max_pressure: float = 100.0
@export var pressure_regen: float = 18.0
@export var pressure_regen_delay: float = 0.6

@export_group("Lubricant Vent / Overclock")
@export var vent_cooldown: float = 18.0
@export var overclock_duration: float = 4.0
@export var overclock_bonus: float = 0.35

@export_group("Gear Work")
## DRIVE work per metre travelled.
@export var drive_work_per_meter: float = 0.25
## ARM work per wrench swing or rivet shot.
@export var arm_work_per_attack: float = 1.0
## PUMP work per point of pressure regenerated.
@export var pump_work_per_pressure: float = 0.05
