class_name FurnaceLight
extends OmniLight3D
## Noise-driven flicker for furnace mouths.

@export var base_energy: float = 3.0
@export var flicker_amount: float = 1.2
@export var flicker_speed: float = 6.0

var _noise: FastNoiseLite = FastNoiseLite.new()
var _time: float = 0.0


func _ready() -> void:
	_noise.seed = randi()
	_noise.frequency = 0.8


func _process(delta: float) -> void:
	_time += delta * flicker_speed
	light_energy = maxf(base_energy + _noise.get_noise_1d(_time) * flicker_amount * 2.0, 0.1)
