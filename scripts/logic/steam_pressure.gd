class_name SteamPressure
extends RefCounted
## Steam Pressure reservoir spent by the rivet gun and dash, refilled by the PUMP socket.

var max_pressure: float
var current: float
var regen_rate: float
var regen_delay: float
var _delay_left: float = 0.0


func _init(p_max_pressure: float, p_regen_rate: float, p_regen_delay: float) -> void:
	assert(p_max_pressure > 0.0, "SteamPressure: max_pressure must be positive")
	assert(p_regen_rate >= 0.0 and p_regen_delay >= 0.0, "SteamPressure: negative regen settings")
	max_pressure = p_max_pressure
	current = p_max_pressure
	regen_rate = p_regen_rate
	regen_delay = p_regen_delay


## Spends `amount` if available. Returns false (spending nothing) when pressure is insufficient.
func try_spend(amount: float) -> bool:
	assert(amount >= 0.0, "SteamPressure.try_spend: amount must be non-negative")
	if current < amount:
		return false
	current -= amount
	_delay_left = regen_delay
	return true


## Advances regeneration. Returns the amount of pressure regenerated this tick.
func tick(delta: float, regen_multiplier: float) -> float:
	assert(delta >= 0.0 and regen_multiplier >= 0.0, "SteamPressure.tick: negative input")
	if _delay_left > 0.0:
		var used: float = minf(_delay_left, delta)
		_delay_left -= used
		delta -= used
	if delta <= 0.0 or current >= max_pressure:
		return 0.0
	var gained: float = minf(regen_rate * regen_multiplier * delta, max_pressure - current)
	current += gained
	return gained


func ratio() -> float:
	return current / max_pressure


func is_full() -> bool:
	return current >= max_pressure
