class_name ScrapGearTable
extends Resource
## Value ranges for gears scavenged from destroyed automatons.

@export var gear_names: PackedStringArray = PackedStringArray([
	"Pitted Spur Cog", "Bent Bevel Gear", "Rusted Ratchet", "Chipped Pinion", "Salvaged Worm Gear",
])
@export var friction_rate_min: float = 0.010
@export var friction_rate_max: float = 0.030
@export var wear_rate_min: float = 0.08
@export var wear_rate_max: float = 0.16
@export var durability_min: float = 60.0
@export var durability_max: float = 100.0


func roll(rng: RandomNumberGenerator) -> GearItem:
	assert(gear_names.size() > 0, "ScrapGearTable.roll: gear_names is empty")
	var gear: GearItem = GearItem.new()
	gear.gear_name = gear_names[rng.randi_range(0, gear_names.size() - 1)]
	gear.friction_rate = rng.randf_range(friction_rate_min, friction_rate_max)
	gear.wear_rate = rng.randf_range(wear_rate_min, wear_rate_max)
	gear.max_durability = 100.0
	gear.durability = rng.randf_range(durability_min, durability_max)
	return gear
