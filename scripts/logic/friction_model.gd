class_name FrictionModel
extends RefCounted
## The technician's gear train: three sockets whose gears scale movement, attack speed and steam regen.

enum Socket { DRIVE, ARM, PUMP }

const SOCKET_COUNT: int = 3
## Output multiplier applied to every socket once the Golden Gear is engaged.
const GOLDEN_MULTIPLIER: float = 1.15

## Output of a socket whose gear is jammed, shattered or missing. Keeps the rig limping rather than dead.
var broken_output: float = 0.35
var golden_engaged: bool = false
var overclock_time_left: float = 0.0
var overclock_bonus: float = 0.0
## Scales all incoming wear work, e.g. 2.0 inside a humid zone. Not saved; zones set and clear it.
var wear_multiplier: float = 1.0

var _gears: Array[GearItem] = [null, null, null]


static func socket_name(socket: Socket) -> String:
	match socket:
		Socket.DRIVE:
			return "Drive Socket"
		Socket.ARM:
			return "Arm Socket"
		Socket.PUMP:
			return "Pump Socket"
	return "Unknown Socket"


func get_gear(socket: Socket) -> GearItem:
	return _gears[socket]


## Installs `gear` and returns the gear it replaced (may be null).
func set_gear(socket: Socket, gear: GearItem) -> GearItem:
	var previous: GearItem = _gears[socket]
	_gears[socket] = gear
	return previous


func apply_work(socket: Socket, work: float, roll: float) -> void:
	if golden_engaged:
		return
	var gear: GearItem = _gears[socket]
	if gear == null:
		return
	gear.apply_work(work * wear_multiplier, roll)


func tick(delta: float) -> void:
	assert(delta >= 0.0, "FrictionModel.tick: delta must be non-negative")
	for gear: GearItem in _gears:
		if gear != null:
			gear.cool(delta)
	overclock_time_left = maxf(overclock_time_left - delta, 0.0)


func lubricate_all() -> void:
	for gear: GearItem in _gears:
		if gear != null:
			gear.lubricate()


func start_overclock(duration: float, bonus: float) -> void:
	assert(duration >= 0.0 and bonus >= 0.0, "FrictionModel.start_overclock: negative duration or bonus")
	overclock_time_left = duration
	overclock_bonus = bonus


func is_overclocked() -> bool:
	return overclock_time_left > 0.0


## Friction/wear multiplier for a socket, ignoring overclock.
func base_multiplier(socket: Socket) -> float:
	if golden_engaged:
		return GOLDEN_MULTIPLIER
	var gear: GearItem = _gears[socket]
	if gear == null or not gear.is_functional():
		return broken_output
	return maxf(gear.penalty_multiplier(), broken_output)


## Final multiplier including any active overclock burst.
func speed_multiplier(socket: Socket) -> float:
	var multiplier: float = base_multiplier(socket)
	if is_overclocked():
		multiplier *= 1.0 + overclock_bonus
	return multiplier


## Seats the Golden Gear in the ARM socket and permanently removes friction penalties.
## Returns the gear it displaced.
func engage_golden_gear(golden: GearItem) -> GearItem:
	assert(golden != null and golden.is_golden_gear, "FrictionModel.engage_golden_gear: requires a golden gear")
	var displaced: GearItem = set_gear(Socket.ARM, golden)
	golden_engaged = true
	lubricate_all()
	return displaced


## Average friction across installed, non-golden gears.
func total_friction() -> float:
	if golden_engaged:
		return 0.0
	var sum: float = 0.0
	var count: int = 0
	for gear: GearItem in _gears:
		if gear != null and not gear.is_golden_gear:
			sum += gear.friction
			count += 1
	return sum / float(count) if count > 0 else 0.0


## Highest wear percentage of any socket. An empty socket counts as 100% worn.
func worst_wear_percent() -> float:
	var worst: float = 0.0
	for gear: GearItem in _gears:
		var wear: float = 100.0 if gear == null else gear.wear_percent()
		worst = maxf(worst, wear)
	return worst


## The socket that most needs a replacement gear: empty or shattered first, then lowest durability.
## The golden gear's socket is never chosen. Returns -1 when every socket holds a golden gear.
func most_worn_socket() -> int:
	var best_socket: int = -1
	var best_score: float = INF
	for socket: int in SOCKET_COUNT:
		var gear: GearItem = _gears[socket]
		var score: float
		if gear == null or gear.state == GearItem.GearState.SHATTERED:
			score = -1.0
		elif gear.is_golden_gear:
			continue
		else:
			score = gear.durability_ratio()
		if score < best_score:
			best_score = score
			best_socket = socket
	return best_socket
