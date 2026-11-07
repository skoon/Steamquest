class_name GearItem
extends Resource
## A socketable cog. Accumulates Friction and Tooth Wear as it does work.
## Friction lowers output; wear degrades durability until the gear jams or shatters.

enum GearState { OK, JAMMED, SHATTERED }

const MAX_FRICTION: float = 1.5
## Below this durability ratio the gear may jam while working.
const JAM_THRESHOLD_RATIO: float = 0.25

@export var gear_name: String = "Scavenged Cog"
## Friction gained per unit of work.
@export var friction_rate: float = 0.02
## Durability lost per unit of work (before friction amplification).
@export var wear_rate: float = 0.1
@export var max_durability: float = 100.0
@export var durability: float = 100.0
@export var is_golden_gear: bool = false
## Probability of jamming per unit of work once below JAM_THRESHOLD_RATIO.
@export var jam_chance_per_work: float = 0.01
## Friction shed per second, always active.
@export var cooling_rate: float = 0.01

var friction: float = 0.0
var state: GearState = GearState.OK


static func create_golden() -> GearItem:
	var gear: GearItem = GearItem.new()
	gear.gear_name = "The Golden Gear"
	gear.friction_rate = 0.0
	gear.wear_rate = 0.0
	gear.jam_chance_per_work = 0.0
	gear.max_durability = 100.0
	gear.durability = 100.0
	gear.is_golden_gear = true
	return gear


## Applies `work` units of load. `roll` is a uniform random value in [0, 1) used for the jam check,
## passed in so the outcome is deterministic and testable.
func apply_work(work: float, roll: float) -> void:
	assert(work >= 0.0, "GearItem.apply_work: work must be non-negative, got %f" % work)
	if is_golden_gear or state == GearState.SHATTERED or work == 0.0:
		return
	friction = minf(friction + friction_rate * work, MAX_FRICTION)
	durability = maxf(durability - wear_rate * work * (1.0 + friction), 0.0)
	if durability <= 0.0:
		state = GearState.SHATTERED
		return
	if state == GearState.OK and durability_ratio() < JAM_THRESHOLD_RATIO:
		var jam_probability: float = clampf(jam_chance_per_work * work, 0.0, 1.0)
		if roll < jam_probability:
			state = GearState.JAMMED


func cool(delta: float) -> void:
	assert(delta >= 0.0, "GearItem.cool: delta must be non-negative")
	friction = maxf(friction - cooling_rate * delta, 0.0)


## Purges all friction and frees a jam. Does not repair tooth wear.
func lubricate() -> void:
	friction = 0.0
	if state == GearState.JAMMED:
		state = GearState.OK


## Output multiplier of a working gear: 1 / (1 + friction). Golden gears are always 1.0.
## Returns 0.0 for jammed or shattered gears; callers decide the fallback output.
func repair_fully() -> void:
	durability = max_durability
	friction = 0.0
	state = GearState.OK


func penalty_multiplier() -> float:
	if is_golden_gear:
		return 1.0
	if state != GearState.OK:
		return 0.0
	return 1.0 / (1.0 + friction)


func durability_ratio() -> float:
	if max_durability <= 0.0:
		return 0.0
	return clampf(durability / max_durability, 0.0, 1.0)


func wear_percent() -> float:
	return (1.0 - durability_ratio()) * 100.0


func is_functional() -> bool:
	return state == GearState.OK


func state_label() -> String:
	match state:
		GearState.OK:
			return "Running"
		GearState.JAMMED:
			return "JAMMED"
		GearState.SHATTERED:
			return "SHATTERED"
	return "Unknown"
