extends Node
## Headless play-through of foundry_level.tscn. Run as the main scene so autoloads exist:
##   Godot_console.exe --headless --path . res://tests/integration/smoke_test.tscn
## Exits 0 when every check passes, 1 otherwise.

const LEVEL_SCENE: PackedScene = preload("res://scenes/world/foundry_level.tscn")
const TEST_SAVE: String = "user://test_smoke_save.json"
const MIN_DRESSING_PROPS: int = 8

var _failures: PackedStringArray = PackedStringArray()
var _level: Node3D
## Sound id -> times played.
var _heard: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	print(("  PASS  " if condition else "  FAIL  ") + message)
	if not condition:
		_failures.append(message)


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame


func _run() -> void:
	GameState.save_path = TEST_SAVE
	GameState.reset()
	Audio.sound_played.connect(func(id: StringName) -> void: _heard[id] = int(_heard.get(id, 0)) + 1)
	_level = LEVEL_SCENE.instantiate() as Node3D
	add_child(_level)
	await _frames(5)

	var builder: FoundryBuilder = _level.get_node("Navigation") as FoundryBuilder
	var player: Technician = _level.get_node("Technician") as Technician
	_check(builder.navigation_mesh != null and builder.navigation_mesh.get_polygon_count() > 0, "navigation mesh baked with polygons")
	_check(player != null and player.health == player.stats.max_health, "technician spawned at full health")
	_check(GameState.current_room == "Boiler Room", "room trigger reports Boiler Room")
	for room: RoomDef in builder.rooms:
		var placed: int = builder.dressed_prop_counts.get(room.room_name, 0)
		print("        %s dressing: %d props" % [room.room_name, placed])
		_check(placed >= MIN_DRESSING_PROPS, "%s is dressed with clutter" % room.room_name)

	_check(_heard.has(&"steam_vent_loop") and _heard.has(&"furnace_loop"), "steam vents and furnaces start their looping hiss and roar")
	await _test_movement_wears_drive_gear(player)
	await _test_enemies_aggro_and_attack(player)
	await _test_wrench_and_rivet(player)
	await _test_valve_opens_boiler_door(player)
	await _test_rumor_unlocks_cutting_door(player)
	await _test_bruiser_slam(player)
	await _test_arc_turret(player)
	await _test_gear_pickup_replaces_worn_socket(player)
	await _test_golden_gear_and_victory(player)

	print("")
	if _failures.is_empty():
		print("SMOKE TEST PASSED")
	else:
		printerr("SMOKE TEST FAILED (%d):" % _failures.size())
		for failure: String in _failures:
			printerr("  - " + failure)
	# Tear the level down and silence the pools so no playback is still alive at exit.
	_level.queue_free()
	await _frames(2)
	Audio.stop_all()
	await _frames(10)
	get_tree().quit(0 if _failures.is_empty() else 1)


func _test_movement_wears_drive_gear(player: Technician) -> void:
	var drive: GearItem = GameState.rig.get_gear(FrictionModel.Socket.DRIVE)
	var start: Vector3 = player.global_position
	var start_durability: float = drive.durability
	Input.action_press("move_up")
	await _frames(40)
	Input.action_release("move_up")
	await _frames(10)
	_check(player.global_position.distance_to(start) > 2.0, "WASD moves the technician")
	_check(drive.friction > 0.0, "movement builds DRIVE friction")
	_check(drive.durability < start_durability, "movement wears DRIVE teeth")
	player.global_position = start


func _test_enemies_aggro_and_attack(player: Technician) -> void:
	var skitterer: ScrapSkitterer = _level.get_node("Enemies/BoilerSkittererA") as ScrapSkitterer
	var start_distance: float = skitterer.global_position.distance_to(player.global_position)
	var start_health: float = player.health
	await _frames(240)
	_check(skitterer.is_aggro, "skitterer aggroes on the technician")
	var closest: float = skitterer.global_position.distance_to(player.global_position)
	_check(closest < start_distance or player.health < start_health, "skitterer closes in on the technician")
	_check(player.health < start_health, "skitterer bites damage the technician")
	_check(_heard.has(&"skitter_clack"), "walking skitterers clack")


func _test_wrench_and_rivet(player: Technician) -> void:
	player.health = player.stats.max_health
	player.pressure.current = player.pressure.max_pressure
	var skitterers: Array[ScrapSkitterer] = []
	for name: String in ["Enemies/BoilerSkittererA", "Enemies/BoilerSkittererB"]:
		var enemy: ScrapSkitterer = _level.get_node_or_null(name) as ScrapSkitterer
		if enemy != null and not enemy.is_dead:
			skitterers.append(enemy)
	_check(not skitterers.is_empty(), "a skitterer is alive for the weapon test")
	if skitterers.is_empty():
		return
	var target: ScrapSkitterer = skitterers[0]
	target.global_position = player.global_position + Vector3(1.5, 0.0, 0.0)
	target.set_physics_process(false)
	await _frames(3)
	player.aim_direction = Vector3.RIGHT
	var before: float = target.health
	player._swing_wrench(GameState.rig)
	_check(target.health < before, "heavy wrench damages a skitterer in the arc")
	_check(_heard.has(&"wrench_bong"), "wrench hit on an automaton rings a BONG")

	target.global_position = player.global_position + Vector3(5.0, 0.0, 0.0)
	await _frames(3)
	player.aim_direction = Vector3.RIGHT
	player.muzzle.global_position = player.global_position + Vector3(0.7, 0.9, 0.0)
	var pressure_before: float = player.pressure.current
	before = target.health
	player._fire_rivet(GameState.rig)
	_check(player.pressure.current < pressure_before, "rivet gun consumes steam pressure")
	await _frames(20)
	_check(target.health < before or target.is_dead, "rivet projectile damages a skitterer")
	for enemy: ScrapSkitterer in skitterers:
		if is_instance_valid(enemy) and not enemy.is_dead:
			enemy.receive_hit(1000.0, Vector3.ZERO)
	await _frames(5)


func _test_valve_opens_boiler_door(_player: Technician) -> void:
	var door: SteamDoor = _level.get_node("Doors/BoilerBulkhead") as SteamDoor
	var valve: JammedValve = _level.get_node("Interactables/SeizedValve") as JammedValve
	door.use_panel()
	_check(not door.is_open, "boiler bulkhead stays shut before the valve is freed")
	for i: int in valve.hits_required:
		valve.receive_bash()
	await _frames(2)
	_check(valve.is_freed, "valve frees after the required wrench hits")
	_check(door.is_open, "freeing the valve opens the boiler bulkhead")
	_check(_heard.has(&"valve_free") and _heard.has(&"door_open"), "freed valve whistles and the bulkhead hisses open")


func _test_rumor_unlocks_cutting_door(player: Technician) -> void:
	var door: SteamDoor = _level.get_node("Doors/CuttingBulkhead") as SteamDoor
	door.use_panel()
	_check(not door.is_open, "cutting bulkhead stays shut without the override rumor")
	var terminal: RumorTerminal = _level.get_node("Interactables/OverrideTerminal") as RumorTerminal
	terminal.interact(player)
	_check(GameState.has_rumor(&"cutting_floor_override"), "reading the terminal records the rumor")
	_check(get_tree().paused, "reading a terminal opens the log (pauses the game)")
	get_tree().paused = false
	door.use_panel()
	await _frames(2)
	_check(door.is_open, "override rumor lets the lock panel open the cutting bulkhead")


func _isolate_enemies(keep: EnemyBase) -> void:
	for enemy: Node in get_tree().get_nodes_in_group(&"enemies"):
		var automaton: EnemyBase = enemy as EnemyBase
		automaton.set_physics_process(automaton == keep)


func _test_bruiser_slam(player: Technician) -> void:
	var bruiser: PistonBruiser = _level.get_node("Enemies/VatsBruiserA") as PistonBruiser
	_isolate_enemies(bruiser)
	player.health = player.stats.max_health
	player.global_position = bruiser.global_position + Vector3(-2.0, 0.05, 0.0)
	var saw_telegraph: bool = false
	for i: int in 150:
		await get_tree().physics_frame
		if bruiser._ring.visible:
			saw_telegraph = true
		if player.health < player.stats.max_health:
			break
	_check(saw_telegraph, "piston bruiser telegraphs its slam with the ground ring")
	_check(player.health < player.stats.max_health, "piston bruiser slam damages the technician")
	_check(_heard.has(&"bruiser_slam"), "piston bruiser slam booms")


func _test_arc_turret(player: Technician) -> void:
	var turret: ArcTurret = _level.get_node("Enemies/VatsTurretNE") as ArcTurret
	_isolate_enemies(turret)
	player.health = player.stats.max_health
	# Clear diagonal between the east vat and the pillar.
	player.global_position = turret.global_position + Vector3(-6.0, 0.05, 6.0)
	for i: int in 240:
		await get_tree().physics_frame
		if player.health < player.stats.max_health:
			break
	_check(turret.is_aggro, "arc turret acquires line of sight")
	_check(player.health < player.stats.max_health, "arc turret lightning damages the technician")
	_check(_heard.has(&"turret_charge") and _heard.has(&"turret_zap"), "arc turret buzzes while charging and zaps when it fires")
	_isolate_enemies(null)
	player.health = player.stats.max_health


func _test_gear_pickup_replaces_worn_socket(player: Technician) -> void:
	var pump: GearItem = GameState.rig.get_gear(FrictionModel.Socket.PUMP)
	pump.durability = 0.0
	pump.state = GearItem.GearState.SHATTERED
	var pickup: GearPickup = _level.get_node("Interactables/ScrapGearCache") as GearPickup
	var scrap: GearItem = pickup.gear
	player.global_position = pickup.global_position + Vector3(0.0, 0.05, 0.0)
	await _frames(5)
	_check(GameState.rig.get_gear(FrictionModel.Socket.PUMP) == scrap, "walking over scrap replaces the shattered socket")


func _test_golden_gear_and_victory(player: Technician) -> void:
	var vault_door: SteamDoor = _level.get_node("Doors/VaultBulkhead") as SteamDoor
	var pedestal: GoldenGearPedestal = _level.get_node("Interactables/GoldenGearPedestal") as GoldenGearPedestal
	_check(not vault_door.is_open, "vault bulkhead sealed before the Golden Gear")
	pedestal.interact(player)
	await _frames(2)
	_check(GameState.has_golden_gear, "pedestal grants the Golden Gear")
	_check(_heard.has(&"golden_gear"), "the Golden Gear chimes")
	_check(GameState.rig.get_gear(FrictionModel.Socket.ARM).is_golden_gear, "Golden Gear seated in the ARM socket")
	_check(vault_door.is_open, "Golden Gear unseals the vault bulkhead")
	var drive: GearItem = GameState.rig.get_gear(FrictionModel.Socket.DRIVE)
	var durability_before: float = drive.durability
	Input.action_press("move_down")
	await _frames(30)
	Input.action_release("move_down")
	_check(drive.friction == 0.0 and drive.durability == durability_before, "no friction or wear once the Golden Gear is engaged")
	_check(GameState.rig.base_multiplier(FrictionModel.Socket.DRIVE) == FrictionModel.GOLDEN_MULTIPLIER, "rig overclocked by the Golden Gear")

	var victory_count: Array[int] = [0]
	GameState.victory.connect(func() -> void: victory_count[0] += 1)
	var elevator: Node3D = _level.get_node("Interactables/Elevator") as Node3D
	player.global_position = elevator.global_position + Vector3(0.0, 0.1, 0.0)
	await _frames(10)
	_check(victory_count[0] == 1 and GameState.is_victorious, "stepping on the elevator wins the run")
