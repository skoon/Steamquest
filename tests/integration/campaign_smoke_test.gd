extends Node
## Headless play-through of levels 1-6 and the hand-off to the finale. Run as the main scene:
##   Godot_console.exe --headless --path . res://tests/integration/campaign_smoke_test.tscn
## Exits 0 when every check passes, 1 otherwise.

const LEVEL_1: String = "res://scenes/levels/level_01_dispatch_yard.tscn"
const LEVEL_2: String = "res://scenes/levels/level_02_tramline.tscn"
const LEVEL_3: String = "res://scenes/levels/level_03_clockmakers_row.tscn"
const LEVEL_4: String = "res://scenes/levels/level_04_flooded_cisterns.tscn"
const LEVEL_5: String = "res://scenes/levels/level_05_steam_gardens.tscn"
const LEVEL_6: String = "res://scenes/levels/level_06_coal_seam.tscn"
const LEVEL_7: String = "res://scenes/levels/level_07_airship_tower.tscn"
const LEVEL_8: String = "res://scenes/levels/level_08_blueprint_archive.tscn"
const LEVEL_9: String = "res://scenes/levels/level_09_tesla_generator.tscn"
const LEVEL_10: String = "res://scenes/levels/level_10_assembly_line.tscn"
const LEVEL_11: String = "res://scenes/levels/level_11_pressure_exchange.tscn"
const LEVEL_12: String = "res://scenes/levels/level_12_engine_yard.tscn"
const FINALE: String = "res://scenes/world/foundry_level.tscn"
const TEST_SAVE: String = "user://test_campaign_smoke_save.json"
const MIN_DRESSING_PROPS: int = 8

var _failures: PackedStringArray = PackedStringArray()
var _level: Node3D
var _heard: Dictionary = {}
var _completed_to: Array[String] = []
var _notices: Array[String] = []


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
	CampaignProgress.delete_save(TEST_SAVE)
	GameState.reset()
	Audio.sound_played.connect(func(id: StringName) -> void: _heard[id] = int(_heard.get(id, 0)) + 1)
	GameState.level_completed.connect(func(path: String) -> void: _completed_to.append(path))
	GameState.notice_posted.connect(func(text: String) -> void: _notices.append(text))

	await _load_level(LEVEL_1)
	await _test_level_1()
	await _load_level(LEVEL_2)
	await _test_level_2()
	await _load_level(LEVEL_3)
	await _test_level_3()
	await _load_level(LEVEL_4)
	await _test_level_4()
	await _load_level(LEVEL_5)
	await _test_level_5()
	await _load_level(LEVEL_6)
	await _test_level_6()
	await _load_level(LEVEL_7)
	await _test_level_7()
	await _load_level(LEVEL_8)
	await _test_level_8()
	await _load_level(LEVEL_9)
	await _test_level_9()
	await _load_level(LEVEL_10)
	await _test_level_10()
	await _load_level(LEVEL_11)
	await _test_level_11()
	await _load_level(LEVEL_12)
	await _test_level_12()

	print("")
	if _failures.is_empty():
		print("CAMPAIGN SMOKE TEST PASSED")
	else:
		printerr("CAMPAIGN SMOKE TEST FAILED (%d):" % _failures.size())
		for failure: String in _failures:
			printerr("  - " + failure)
	await _unload_level()
	Audio.stop_all()
	CampaignProgress.delete_save(TEST_SAVE)
	await _frames(10)
	get_tree().quit(0 if _failures.is_empty() else 1)


func _load_level(path: String) -> void:
	await _unload_level()
	var scene: PackedScene = load(path) as PackedScene
	_level = scene.instantiate() as Node3D
	_level.set("auto_advance", false)
	add_child(_level)
	await _frames(5)
	print("-- %s" % path.get_file())
	var builder: FoundryBuilder = _level.get_node("Navigation") as FoundryBuilder
	_check(builder.navigation_mesh != null and builder.navigation_mesh.get_polygon_count() > 0, "navigation mesh baked")
	for room: RoomDef in builder.rooms:
		var placed: int = builder.dressed_prop_counts.get(room.room_name, 0)
		print("        %s dressing: %d props" % [room.room_name, placed])
		_check(placed >= MIN_DRESSING_PROPS, "%s is dressed with clutter" % room.room_name)


func _unload_level() -> void:
	if _level == null:
		return
	get_tree().paused = false
	_level.queue_free()
	_level = null
	await _frames(3)


func _player() -> Technician:
	return _level.get_node("Technician") as Technician


func _isolate_enemies(keep: Array[EnemyBase]) -> void:
	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy: EnemyBase = node as EnemyBase
		enemy.set_physics_process(keep.has(enemy))


func _ride_elevator(expected_next: String) -> void:
	var count_before: int = _completed_to.size()
	var elevator: Node3D = _level.get_node("Interactables/Elevator") as Node3D
	_player().global_position = elevator.global_position + Vector3(0.0, 0.1, 0.0)
	await _frames(10)
	_check(_completed_to.size() == count_before + 1 and _completed_to.back() == expected_next, "the exit lift leads to %s" % expected_next.get_file())


# --- Level 1 ------------------------------------------------------------------------------------

func _test_level_1() -> void:
	var player: Technician = _player()
	_check(GameState.level_index == 0, "level 1 registers as the first campaign level")
	_check(GameState.has_save(), "starting a level writes the save")
	_isolate_enemies([])
	var briefing: RumorTerminal = _level.get_node("Interactables/BriefingTerminal") as RumorTerminal
	briefing.interact(player)
	get_tree().paused = false
	_check(GameState.has_rumor(&"dispatch_briefing"), "the briefing terminal is logged")

	var gate: SteamDoor = _level.get_node("Doors/YardGate") as SteamDoor
	var valve: JammedValve = _level.get_node("Interactables/SeizedValve") as JammedValve
	gate.use_panel()
	_check(not gate.is_open, "yard gate stays shut until the valve is freed")
	for i: int in valve.hits_required:
		valve.receive_bash()
	await _frames(2)
	_check(gate.is_open, "freeing the yard valve opens the gate")
	var office: SteamDoor = _level.get_node("Doors/OfficeDoor") as SteamDoor
	office.use_panel()
	await _frames(2)
	_check(office.is_open, "the office door opens from its panel")

	# Wear the rig and take damage, so the next level can check what carries over.
	GameState.rig.get_gear(FrictionModel.Socket.DRIVE).durability = 60.0
	player.health = 40.0
	await _ride_elevator(LEVEL_2)
	_check(GameState.level_index == 1, "completing level 1 advances the campaign")


# --- Level 2 ------------------------------------------------------------------------------------

func _test_level_2() -> void:
	var player: Technician = _player()
	_check(is_equal_approx(GameState.rig.get_gear(FrictionModel.Socket.DRIVE).durability, 60.0), "gear wear carries into the next level")
	_check(player.health == player.stats.max_health, "health refills on a new level")
	_check(GameState.has_rumor(&"dispatch_briefing"), "the rumor log carries across levels")
	_check(int(GameState.checkpoint["level_index"]) == 1, "a checkpoint is taken for level 2")
	_isolate_enemies([])
	await _test_tram(player)
	await _test_hound_pack(player)

	var freight: SteamDoor = _level.get_node("Doors/FreightDoor") as SteamDoor
	var concourse_valve: JammedValve = _level.get_node("Interactables/ConcourseValve") as JammedValve
	var signal_valve: JammedValve = _level.get_node("Interactables/SignalValve") as JammedValve
	for i: int in concourse_valve.hits_required:
		concourse_valve.receive_bash()
	await _frames(2)
	_check(not freight.is_open, "one valve is not enough for the freight door")
	for i: int in signal_valve.hits_required:
		signal_valve.receive_bash()
	await _frames(2)
	_check(freight.is_open, "both valves open the freight door")
	await _ride_elevator(LEVEL_3)


func _test_tram(player: Technician) -> void:
	var tram: TramCrossing = _level.get_node("Hazards/TramCrossingWest") as TramCrossing
	(_level.get_node("Hazards/TramCrossingEast") as TramCrossing).set_physics_process(false)
	player.global_position = tram.global_position + Vector3(4.0, 0.05, 1.0)
	player.health = player.stats.max_health
	var saw_pass: bool = false
	for i: int in int(tram.interval * 60.0) + 30:
		await get_tree().physics_frame
		saw_pass = saw_pass or tram.is_running()
	_check(saw_pass and player.health == player.stats.max_health, "a passing tram leaves a Technician beside the rails alone")
	player.global_position = tram.global_position + Vector3(0.0, 0.05, 1.0)
	var hit: bool = false
	for i: int in int(tram.interval * 60.0) + 30:
		await get_tree().physics_frame
		player.global_position.x = tram.global_position.x
		if player.health < player.stats.max_health:
			hit = tram.is_running()
			break
	_check(hit, "a tram running over the rails hits the Technician")
	_check(_heard.has(&"tram_bell") and _heard.has(&"tram_rush"), "trams ring a warning bell and rush past")
	tram.set_physics_process(false)
	player.health = player.stats.max_health


func _test_hound_pack(player: Technician) -> void:
	var hounds: Array[EnemyBase] = []
	for name: String in ["Enemies/TunnelHoundA", "Enemies/TunnelHoundB", "Enemies/TunnelHoundC"]:
		hounds.append(_level.get_node(name) as EnemyBase)
	_isolate_enemies(hounds)
	player.global_position = Vector3(21.0, 0.05, 0.0)
	player.aim_direction = Vector3.LEFT
	var bitten: bool = false
	for i: int in 240:
		await get_tree().physics_frame
		if player.health < player.stats.max_health:
			bitten = true
			player.health = player.stats.max_health
	var all_aggro: bool = true
	var targets: Array[Vector3] = []
	for hound: EnemyBase in hounds:
		all_aggro = all_aggro and hound.is_aggro
		targets.append((hound as ClockworkHound).orbit_target())
	var spread: float = INF
	for a: int in targets.size():
		for b: int in range(a + 1, targets.size()):
			spread = minf(spread, targets[a].distance_to(targets[b]))
	_check(all_aggro, "the hound pack hunts the Technician")
	_check(spread > 3.0, "each hound takes its own slot around the Technician (closest slots %.1f m apart)" % spread)
	_check(bitten and _heard.has(&"hound_lunge"), "hounds lunge in and bite")
	for hound: EnemyBase in hounds:
		hound.receive_hit(1000.0, Vector3.ZERO)
	_isolate_enemies([])
	await _frames(5)


# --- Level 3 ------------------------------------------------------------------------------------

func _test_level_3() -> void:
	var player: Technician = _player()
	_isolate_enemies([])
	var sentry: BrassSentry = _level.get_node("Enemies/FoyerSentry") as BrassSentry
	_check(sentry.facing.dot(Vector3.LEFT) > 0.85, "the foyer sentry faces the entrance")
	player.global_position = sentry.global_position + sentry.facing * 1.6 + Vector3(0.0, 0.05, 0.0)
	await _frames(3)
	player.aim_direction = -sentry.facing
	var health_before: float = sentry.health
	player._swing_wrench(GameState.rig)
	_check(sentry.health == health_before, "a frontal wrench blow glances off the sentry's shield")
	_check(_heard.has(&"sentry_shield"), "the shield rings when it turns a blow")
	player.global_position = sentry.global_position - sentry.facing * 1.6 + Vector3(0.0, 0.05, 0.0)
	await _frames(3)
	player.aim_direction = sentry.facing
	player._swing_wrench(GameState.rig)
	_check(sentry.health < health_before, "a blow from behind damages the sentry")
	await _test_sentry_rivet_stagger(player)
	await _test_sentry_introduction()

	var service: SteamDoor = _level.get_node("Doors/ServiceDoor") as SteamDoor
	service.use_panel()
	_check(not service.is_open, "the clockwork door stays shut without the key")
	var key: KeyPickup = _level.get_node("Interactables/WindingKey") as KeyPickup
	player.global_position = key.global_position + Vector3(0.0, 0.05, 0.0)
	await _frames(5)
	_check(GameState.has_item(&"winding_key"), "walking over the winding key picks it up")
	_check(_heard.has(&"key_pickup"), "the key ratchets as it's picked up")
	service.use_panel()
	await _frames(2)
	_check(service.is_open, "the winding key opens the clockwork door")

	await _test_death_restores_checkpoint()
	await _ride_elevator(LEVEL_4)


func _test_death_restores_checkpoint() -> void:
	var checkpoint_drive: float = float((GameState.checkpoint["rig"]["sockets"] as Array)[FrictionModel.Socket.DRIVE]["durability"])
	GameState.rig.get_gear(FrictionModel.Socket.DRIVE).durability = 5.0
	var died: Array[bool] = [false]
	GameState.player_died.connect(func() -> void: died[0] = true, CONNECT_ONE_SHOT)
	_player().receive_hit(10000.0, Vector3.ZERO)
	_check(died[0], "the Technician can die")
	await _load_level(LEVEL_3)
	_check(GameState.level_index == 2, "restarting stays on level 3")
	_check(is_equal_approx(GameState.rig.get_gear(FrictionModel.Socket.DRIVE).durability, checkpoint_drive), "dying restores the gears from the level checkpoint")
	_check(not GameState.has_item(&"winding_key"), "the restarted level forgets the key")
	_check(not (_level.get_node("Doors/ServiceDoor") as SteamDoor).is_open, "the restarted level's doors are shut again")
	_check(_player().health == _player().stats.max_health and not _player().is_dead, "the Technician respawns at full health")
	_isolate_enemies([])


func _restore_player(player: Technician) -> void:
	player.health = player.stats.max_health
	player._invulnerable_time = 0.0
	GameState.health_changed.emit(player.health, player.stats.max_health)


func _kill_all_enemies() -> void:
	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy: EnemyBase = node as EnemyBase
		if not enemy.is_dead:
			enemy.receive_crush_hit(100000.0, Vector3.ZERO)
	await _frames(3)


# --- Level 4 ------------------------------------------------------------------------------------

func _test_level_4() -> void:
	var player: Technician = _player()
	_isolate_enemies([])
	_check(GameState.level_index == 3, "level 4 registers as the fourth campaign level")
	var warden: PistonBruiser = _level.get_node("Enemies/CisternWarden") as PistonBruiser
	_check(warden.combo_slams == 3 and warden.stats.max_health > 300.0, "the Cistern Warden is a three-slam bruiser")

	var pool: WaterPool = _level.get_node("Hazards/TankPoolA") as WaterPool
	var turret: ArcTurret = _level.get_node("Enemies/TankTurretA") as ArcTurret
	pool.flood_for(30.0)
	player.global_position = pool.global_position + Vector3(1.5, 0.05, 0.0)
	await _frames(6)
	_check(pool.is_deep(), "a forced flood fills the pool")
	_check(player.terrain_speed < 1.0 and player.terrain_drive_work > 1.0, "deep water slows the Technician and grinds the drive gear")
	_check(turret.disabled, "an Arc Turret standing in deep water shorts out")
	player.global_position = Vector3(20.0, 0.05, 0.0)
	await _frames(6)
	_check(player.terrain_speed == 1.0 and player.terrain_drive_work == 1.0, "leaving the water restores normal footing")

	var outflow: SteamDoor = _level.get_node("Doors/OutflowDoor") as SteamDoor
	var hall_pool: WaterPool = _level.get_node("Hazards/PumpHallPool") as WaterPool
	var valves: Dictionary = {}
	for label: String in ["I", "II", "III"]:
		valves[label] = _level.get_node("Interactables/PumpValve" + label) as PumpValve
	(valves["I"] as PumpValve).interact(player)
	await _frames(2)
	_check(hall_pool.tide.is_forced(hall_pool._time) and _heard.has(&"sequence_wrong"), "a pump turned out of order floods the hall")
	_check(not outflow.is_open, "the outflow stays sealed after a wrong valve")
	for label: String in ["II", "III"]:
		(valves[label] as PumpValve).interact(player)
	_check((valves["II"] as PumpValve).is_lit() and not (valves["I"] as PumpValve).is_lit(), "lamps show the pumps started so far")
	(valves["I"] as PumpValve).interact(player)
	await _frames(2)
	_check(outflow.is_open, "pumps II, III, I open the outflow lock")
	await _ride_elevator(LEVEL_5)


# --- Level 5 ------------------------------------------------------------------------------------

func _test_level_5() -> void:
	var player: Technician = _player()
	_isolate_enemies([])
	var mist: HumidZone = _level.get_node("Hazards/AtriumMist") as HumidZone
	player.global_position = mist.global_position + Vector3(0.0, 0.05, 0.0)
	await _frames(5)
	_check(GameState.rig.wear_multiplier == mist.wear_multiplier, "standing in the hothouse mist speeds up gear wear")
	player.global_position = Vector3(-6.0, 0.05, 4.0)
	await _frames(5)
	_check(GameState.rig.wear_multiplier == 1.0, "stepping out of the mist restores normal wear")

	var nest: EnemyNest = _level.get_node("Hazards/NestA") as EnemyNest
	nest.schedule = SpawnSchedule.new(0.1, 3)
	player.global_position = nest.global_position + Vector3(5.0, 0.05, 4.0)
	await _frames(60)
	_check(nest.spawned_total == 3 and nest.alive_count() == 3, "a nest builds automatons up to its cap (%d built)" % nest.spawned_total)
	await _frames(30)
	_check(nest.spawned_total == 3, "a nest at its cap stops building")
	_isolate_enemies([])
	_restore_player(player)
	var lift_door: SteamDoor = _level.get_node("Doors/GardenLiftDoor") as SteamDoor
	nest.receive_hit(1000.0, Vector3.ZERO)
	(_level.get_node("Hazards/NestB") as EnemyNest).receive_hit(1000.0, Vector3.ZERO)
	await _frames(2)
	_check(not lift_door.is_open, "two smashed nests are not enough")
	(_level.get_node("Hazards/NestC") as EnemyNest).receive_hit(1000.0, Vector3.ZERO)
	await _frames(2)
	_check(lift_door.is_open, "smashing every nest opens the garden lift")
	_check(_heard.has(&"nest_pulse") and _heard.has(&"nest_break"), "nests throb as they build and crunch when smashed")
	await _kill_all_enemies()
	await _ride_elevator(LEVEL_6)


# --- Level 6 ------------------------------------------------------------------------------------

func _test_level_6() -> void:
	var player: Technician = _player()
	_isolate_enemies([])
	_check(player.has_lantern(), "the Technician carries a lantern in the coal seam")
	var environment: Environment = (_level.get_node("WorldEnvironment") as WorldEnvironment).environment
	_check(environment.ambient_light_energy < 0.1, "the coal seam is dark")
	var lantern: WallLanternSwitch = _level.get_node("Interactables/FaceLanternA") as WallLanternSwitch
	lantern.interact(player)
	_check(lantern.is_lit and _heard.has(&"lantern_light"), "a wall lantern lights and stays lit")

	var carts: TramCrossing = _level.get_node("Hazards/CoalFaceCarts") as TramCrossing
	for path: String in ["Hazards/JunctionCartsWest", "Hazards/JunctionCartsEast"]:
		(_level.get_node(path) as TramCrossing).set_physics_process(false)
	_restore_player(player)
	var hit: bool = false
	for i: int in int(carts.interval * 60.0) + 30:
		await get_tree().physics_frame
		player.global_position = carts.global_position + Vector3(0.0, 0.05, 1.0)
		if player.health < player.stats.max_health:
			hit = carts.is_running()
			break
	_check(hit and _heard.has(&"cart_rumble"), "a runaway ore cart rumbles in and hits the Technician")
	carts.set_physics_process(false)
	_restore_player(player)

	var winch: Winch = _level.get_node("Interactables/Winch") as Winch
	var lift_door: SteamDoor = _level.get_node("Doors/MineLiftDoor") as SteamDoor
	_check(not winch.can_interact(), "the seized winch cannot be engaged")
	for i: int in winch.hits_required:
		winch.receive_bash()
	_check(winch.stage == Winch.Stage.READY, "knocking the brake free readies the winch")
	winch.hold = HoldProgress.new(1.0)
	winch.start_winding()
	player.global_position = Vector3(30.0, 0.05, 0.0)
	await _frames(70)
	_check(winch.hold.progress == 0.0, "the winch does not wind while the Technician is away")
	_check(winch.spawned_total > 0, "automatons come for the winch while it winds")
	_isolate_enemies([])
	player.global_position = winch.global_position + Vector3(0.0, 0.05, 3.0)
	await _frames(80)
	_restore_player(player)
	_check(winch.stage == Winch.Stage.DONE, "staying beside the winch winds the cage up")
	await _frames(2)
	_check(lift_door.is_open, "the wound winch opens the mine lift")
	await _kill_all_enemies()
	await _ride_elevator(LEVEL_7)


func _test_sentry_rivet_stagger(player: Technician) -> void:
	var sentry: BrassSentry = _level.get_node("Enemies/GallerySentryA") as BrassSentry
	player.global_position = sentry.global_position + sentry.facing * 4.0 + Vector3(0.0, 0.05, 0.0)
	await _frames(3)
	player.aim_direction = -sentry.facing
	player.pressure.current = player.pressure.max_pressure
	var health_before: float = sentry.health
	player._fire_rivet(GameState.rig)
	for i: int in 30:
		await get_tree().physics_frame
		if sentry.is_staggered():
			break
	_check(sentry.is_staggered() and sentry.health == health_before, "a rivet on the shield staggers the sentry without hurting it")
	player.global_position = sentry.global_position + sentry.facing * 1.6 + Vector3(0.0, 0.05, 0.0)
	await _frames(3)
	player.aim_direction = -sentry.facing
	player._wrench_cooldown = 0.0
	player._swing_wrench(GameState.rig)
	_check(sentry.health < health_before, "a staggered sentry takes a frontal wrench blow")
	sentry.set_physics_process(true)
	sentry.is_aggro = true
	player.global_position = Vector3(-6.0, 0.05, 6.0)
	for i: int in int(sentry.stagger_time * 60.0) + 20:
		await get_tree().physics_frame
	sentry.set_physics_process(false)
	_check(not sentry.is_staggered(), "the shield comes back up after the stagger")
	_check(sentry.blocks(-sentry.facing * 5.0), "a recovered shield blocks again")


func _test_sentry_introduction() -> void:
	var introduced: bool = false
	for text: String in _notices:
		introduced = introduced or text.begins_with("BRASS SENTRY")
	_check(introduced, "the first sentry to spot the Technician explains how to beat it")


# --- Level 7 ------------------------------------------------------------------------------------

func _test_level_7() -> void:
	var player: Technician = _player()
	_isolate_enemies([])
	var builder: FoundryBuilder = _level.get_node("Navigation") as FoundryBuilder
	_check(builder.rooms[1].open_air and builder.rooms[2].open_air, "the cargo deck and gantry are open to the sky")

	var wind: WindZone = _level.get_node("Hazards/CargoWind") as WindZone
	(_level.get_node("Hazards/GantryWind") as WindZone).set_physics_process(false)
	for path: String in ["Hazards/CargoPropeller", "Hazards/CargoPropellerSouth", "Hazards/GantryPropeller"]:
		(_level.get_node(path) as Propeller).set_physics_process(false)
	player.global_position = Vector3(18.0, 0.05, -2.0)
	await _frames(5)
	for i: int in 200:
		if wind.current_phase() == HazardCycle.Phase.ACTIVE:
			break
		wind.advance_time(0.05)
	wind.advance_time(wind.gust_time * 0.3)
	var before: Vector3 = player.global_position
	await _frames(20)
	_check(player.global_position.z > before.z + 0.5 and _heard.has(&"wind_gust"), "a gust shoves the Technician toward the deck edge")
	wind.set_physics_process(false)
	await _frames(10)
	var settled: Vector3 = player.global_position
	await _frames(20)
	_check(player.global_position.distance_to(settled) < 0.3, "the Technician stops drifting once the gust dies down")

	player.global_position = Vector3(18.0, 0.05, 0.0)
	await _frames(5)
	_restore_player(player)
	var room_name: String = GameState.current_room
	player.global_position = Vector3(14.0, 0.3, 11.0)
	var recovered: bool = false
	for i: int in 180:
		await get_tree().physics_frame
		if player.health < player.stats.max_health:
			recovered = true
			break
	await _frames(2)
	var entrance: Vector3 = builder.room_entrance(room_name)
	_check(recovered and room_name == "Cargo Deck", "falling off the deck costs hull")
	_check(player.global_position.distance_to(entrance) < 1.5, "the safety line winches the Technician back to the deck entrance")
	_restore_player(player)

	var skitterer: EnemyBase = _level.get_node("Enemies/CargoSkittererA") as EnemyBase
	_isolate_enemies([skitterer])
	skitterer.global_position = Vector3(24.0, 0.3, 11.0)
	for i: int in 180:
		await get_tree().physics_frame
		if skitterer.is_dead:
			break
	_check(skitterer.is_dead, "an automaton pushed through a railing gap is lost")
	_isolate_enemies([])

	var propeller: Propeller = _level.get_node("Hazards/CargoPropeller") as Propeller
	propeller.set_physics_process(true)
	player.global_position = propeller.global_position + propeller.blow_direction() * 3.0 + Vector3(0.0, 0.05, 0.0)
	before = player.global_position
	await _frames(20)
	_check((player.global_position - before).dot(propeller.blow_direction()) > 0.3, "a propeller wash pushes the Technician along its facing")
	_restore_player(player)
	player.global_position = propeller.to_global(Vector3(0.0, 0.05, -0.7))
	await _frames(5)
	_check(player.health < player.stats.max_health, "the propeller blades hurt on contact")
	propeller.set_physics_process(false)
	_restore_player(player)

	await _test_tesla_drone(player)

	var west_lever: GangwayLever = _level.get_node("Interactables/GangwayLeverWest") as GangwayLever
	var east_lever: GangwayLever = _level.get_node("Interactables/GangwayLeverEast") as GangwayLever
	var gangway: SteamDoor = _level.get_node("Doors/GangwayDoor") as SteamDoor
	_check(not gangway.is_open, "the gangway lift starts locked")
	west_lever.interact(player)
	await _frames(2)
	_check(not gangway.is_open and not west_lever.can_interact(), "one lever alone does not lower the gangway")
	east_lever.interact(player)
	await _frames(2)
	_check(gangway.is_open, "pulling both gangway levers frees the lift")
	await _kill_all_enemies()
	await _ride_elevator(LEVEL_8)


func _test_tesla_drone(player: Technician) -> void:
	var drone: TeslaDrone = _level.get_node("Enemies/GantryDroneA") as TeslaDrone
	_isolate_enemies([drone])
	_check(drone.sprite.position.y > 1.5, "the tesla drone hovers above the deck")
	player.global_position = drone.global_position + Vector3(-7.0, 0.05, 0.0)
	var hurt: bool = false
	for i: int in 400:
		await get_tree().physics_frame
		if player.health < player.stats.max_health:
			hurt = true
			break
	_check(hurt and _heard.has(&"drone_zap"), "the drone keeps its distance and zaps the Technician with an arc")
	_check(drone._distance_to_target() > 3.0, "the drone stands off rather than closing to melee")
	_restore_player(player)
	drone.set_physics_process(false)
	player.global_position = drone.global_position + Vector3(-5.0, 0.05, 0.0)
	await _frames(3)
	player.aim_direction = Vector3.RIGHT
	player.pressure.current = player.pressure.max_pressure
	var health_before: float = drone.health
	player._fire_rivet(GameState.rig)
	await _frames(30)
	_check(drone.health < health_before, "a rivet hits the hovering drone")
	drone.set_physics_process(true)
	drone.stun(0.5)
	_check(drone.is_stunned(), "a stunned drone drops out of the air")
	await _frames(50)
	_check(not drone.is_stunned(), "the drone recovers after its stun")
	_isolate_enemies([])
	_restore_player(player)


# --- Level 8 ------------------------------------------------------------------------------------

func _test_level_8() -> void:
	var player: Technician = _player()
	var sentry: BrassSentry = _level.get_node("Enemies/ReadingSentry") as BrassSentry
	var turret: ArcTurret = _level.get_node("Enemies/ReadingTurret") as ArcTurret
	var alarm: AlarmBell = _level.get_node("Interactables/ReadingAlarm") as AlarmBell
	_isolate_enemies([sentry])
	_check(turret.dormant, "the reading room turret sleeps until the alarm")
	_check(sentry.is_patrolling(), "the reading room sentry walks a patrol")
	player.global_position = Vector3(-6.0, 0.05, 6.0)
	var start: Vector3 = sentry.global_position
	await _frames(60)
	_check(sentry.global_position.distance_to(start) > 0.8 and not alarm.is_raised(), "the sentry patrols without noticing the Technician behind it")
	player.global_position = sentry.global_position + sentry.facing * 3.0 + Vector3(0.0, 0.05, 0.0)
	await _frames(5)
	_check(alarm.is_raised() and not turret.dormant and _heard.has(&"alarm_bell"), "stepping into the lantern cone rings the alarm and wakes the turret")
	sentry.set_physics_process(false)
	alarm.alarm.quiet_time = 0.5
	player.global_position = Vector3(-6.0, 0.05, 6.0)
	await _frames(45)
	_check(not alarm.is_raised() and turret.dormant, "the turret goes back to sleep once the alarm falls quiet")
	_isolate_enemies([])
	_restore_player(player)

	var lift: SteamDoor = _level.get_node("Doors/ArchiveLiftDoor") as SteamDoor
	for i: int in 3:
		_check(not lift.is_open, "the archive lift is locked before page %d" % (i + 1))
		var page: Node3D = _level.get_node("Interactables/BlueprintPage%d" % (i + 1)) as Node3D
		player.global_position = page.global_position + Vector3(0.0, 0.05, 0.0)
		await _frames(5)
		_check(GameState.has_item(StringName("blueprint_%d" % (i + 1))), "blueprint page %d collected" % (i + 1))
	await _frames(2)
	_check(lift.is_open, "all three blueprint pages open the archive lift")
	await _kill_all_enemies()
	await _ride_elevator(LEVEL_9)


# --- Level 9 ------------------------------------------------------------------------------------

func _test_level_9() -> void:
	var player: Technician = _player()
	_isolate_enemies([])
	var plates: ElectricPlates = _level.get_node("Hazards/GalleryPlates") as ElectricPlates
	_restore_player(player)
	var shocked: bool = false
	for i: int in int(plates.pattern.period() * 60.0) + 30:
		await get_tree().physics_frame
		player.global_position = plates.row_center(0) + Vector3(0.0, 0.05, 0.0)
		if player.health < player.stats.max_health:
			shocked = plates.state_of(0) == PlatePattern.State.LIVE
			break
	_check(shocked and _heard.has(&"plate_crackle"), "a live floor plate shocks the Technician")
	plates.set_physics_process(false)
	(_level.get_node("Hazards/CoilHallPlates") as ElectricPlates).set_physics_process(false)
	_restore_player(player)

	var coil: TeslaCoil = _level.get_node("Hazards/CoilWest") as TeslaCoil
	var drone: TeslaDrone = _level.get_node("Enemies/CoilDroneA") as TeslaDrone
	var far_drone: TeslaDrone = _level.get_node("Enemies/CoilDroneC") as TeslaDrone
	_isolate_enemies([drone])
	drone.global_position = coil.global_position + Vector3(3.0, 0.05, -2.0)
	player.global_position = coil.global_position + Vector3(-5.0, 0.05, 0.0)
	await _frames(3)
	player.aim_direction = Vector3.RIGHT
	player.pressure.current = player.pressure.max_pressure
	player._fire_rivet(GameState.rig)
	for i: int in 30:
		await get_tree().physics_frame
		if not coil.is_charged():
			break
	_check(not coil.is_charged() and _heard.has(&"coil_overload"), "a rivet into the coil overloads it")
	_check(drone.is_stunned() and not far_drone.is_stunned(), "the overload knocks nearby drones out of the air")
	_isolate_enemies([])
	_restore_player(player)

	var router: PowerRouter = _level.get_node("Interactables/PowerRouter") as PowerRouter
	var door_plates: ElectricPlates = _level.get_node("Hazards/LiftDoorPlates") as ElectricPlates
	var west_plates: ElectricPlates = _level.get_node("Hazards/SwitchPlatesWest") as ElectricPlates
	var lift: SteamDoor = _level.get_node("Doors/GeneratorLiftDoor") as SteamDoor
	_check(door_plates.state_of(0) == PlatePattern.State.LIVE, "the plates by the lift door start live")
	var junction_a: JunctionSwitch = _level.get_node("Interactables/JunctionA") as JunctionSwitch
	var junction_c: JunctionSwitch = _level.get_node("Interactables/JunctionC") as JunctionSwitch
	junction_c.interact(player)
	await _frames(2)
	_check(west_plates.state_of(0) == PlatePattern.State.LIVE and door_plates.state_of(0) == PlatePattern.State.OFF, "a wrong routing electrifies a different section")
	junction_a.interact(player)
	junction_a.interact(player)
	await _frames(2)
	_check(router.is_solved() and lift.is_open, "the earth-bank routing opens the generator lift")
	_check(west_plates.state_of(0) == PlatePattern.State.OFF and door_plates.state_of(0) == PlatePattern.State.OFF, "with the current earthed every section is dead")
	_check(not junction_a.can_interact(), "the junctions lock once the current is earthed")
	await _kill_all_enemies()
	await _ride_elevator(LEVEL_10)


# --- Level 10 -----------------------------------------------------------------------------------

func _test_level_10() -> void:
	var player: Technician = _player()
	_isolate_enemies([])
	var presses: Array[StampingPress] = []
	for press_name: String in ["PressWest", "PressEast", "PressReturn"]:
		var press: StampingPress = _level.get_node("Hazards/" + press_name) as StampingPress
		press.set_physics_process(false)
		presses.append(press)
	var line: AssemblyLine = _level.get_node("Interactables/AssemblyLine") as AssemblyLine
	line.set_physics_process(false)
	_restore_player(player)

	player.global_position = Vector3(19.0, 0.05, -4.5)
	await _frames(30)
	_check(player.global_position.x > 19.8 and absf(player.global_position.z + 4.5) < 0.6, "the outbound belt carries the Technician east")
	player.global_position = Vector3(19.0, 0.05, 4.5)
	await _frames(30)
	_check(player.global_position.x < 18.2, "the return belt carries the Technician west")
	player.global_position = Vector3(19.0, 0.05, 0.0)
	await _frames(3)
	var resting: Vector3 = player.global_position
	await _frames(20)
	_check(player.global_position.distance_to(resting) < 0.2, "off the belt the Technician stops drifting")

	var press_west: StampingPress = presses[0]
	press_west.set_physics_process(true)
	_restore_player(player)
	var crushed: bool = false
	for i: int in int(press_west.interval * 60.0) + 30:
		await get_tree().physics_frame
		if press_west.current_phase() != HazardCycle.Phase.ACTIVE:
			player.global_position = press_west.global_position + Vector3(0.0, 0.05, 0.0)
		if player.health < player.stats.max_health:
			crushed = true
			break
	_check(crushed and absf(player.stats.max_health - player.health - press_west.damage) < 1.0, "a stamping press slam takes %d health" % int(press_west.damage))
	_check(_heard.has(&"press_hiss") and _heard.has(&"press_slam"), "the press hisses before it slams")
	press_west.set_physics_process(false)
	_restore_player(player)
	var press_east: StampingPress = presses[1]
	var victim: EnemyBase = _level.get_node("Enemies/StoreSkittererA") as EnemyBase
	press_east.set_physics_process(true)
	player.global_position = Vector3(26.0, 0.05, 3.0)
	for i: int in int(press_east.interval * 60.0) + 30:
		await get_tree().physics_frame
		if victim.is_dead:
			break
		victim.global_position = press_east.global_position + Vector3(0.0, 0.05, 0.0)
	_check(victim.is_dead, "a press slam crushes an automaton on its bed")
	press_east.set_physics_process(false)

	line.set_physics_process(true)
	player.global_position = Vector3(13.0, 0.05, -1.0)
	for i: int in 240:
		await get_tree().physics_frame
		if line.spawned_total > 0:
			break
	_check(line.spawned_total > 0 and line.alive_count() > 0, "the running line turns out automatons near the Technician")
	_isolate_enemies([])
	var lift: SteamDoor = _level.get_node("Doors/LineLiftDoor") as SteamDoor
	var names: Array[String] = ["GovernorNorth", "GovernorCentre", "GovernorFar"]
	for index: int in names.size():
		_check(not lift.is_open and not line.is_jammed, "the line lift stays shut with %d governors running" % (names.size() - index))
		var governor: DriveGovernor = _level.get_node("Interactables/" + names[index]) as DriveGovernor
		for hit: int in governor.hits_required:
			governor.receive_bash()
		_check(governor.is_smashed(), "%s smashed after %d blows" % [names[index], governor.hits_required])
	await _frames(2)
	_check(line.is_jammed and line.governors_left() == 0 and lift.is_open, "smashing all three governors jams the line and frees the lift")
	_check(_heard.has(&"governor_break"), "governors fly apart with a crash")
	var spawned: int = line.spawned_total
	await _frames(120)
	_check(line.spawned_total == spawned, "a jammed line builds no more automatons")
	await _kill_all_enemies()
	_restore_player(player)

	var bench: GearWorkbench = _level.get_node("Interactables/GearWorkbench") as GearWorkbench
	var drive: GearItem = GameState.rig.get_gear(FrictionModel.Socket.DRIVE)
	drive.durability = 5.0
	drive.friction = 0.6
	_check(bench.can_interact(), "the workbench is ready to use")
	bench.interact(player)
	_check(is_equal_approx(drive.durability, drive.max_durability) and drive.friction == 0.0, "the workbench rebuilds the most worn gear as new")
	_check(not bench.can_interact() and _heard.has(&"workbench_repair"), "the workbench only has stock for one rebuild")
	await _ride_elevator(LEVEL_11)


# --- Level 11 -----------------------------------------------------------------------------------

func _test_level_11() -> void:
	var player: Technician = _player()
	_isolate_enemies([])
	_restore_player(player)
	var hud: Hud = _level.get_node("HUD") as Hud
	var system: PressureSystem = _level.get_node("Interactables/PressureSystem") as PressureSystem
	_check(hud.is_room_pressure_shown(), "the HUD shows the room pressure in the exchange")
	var start: float = system.pressure.level
	await _frames(60)
	_check(system.pressure.level > start, "room pressure climbs on its own")
	system.set_physics_process(false)

	var valve: ReliefValve = _level.get_node("Interactables/ReliefGallery") as ReliefValve
	system.pressure.level = 0.6
	valve.receive_bash()
	_check(is_equal_approx(system.pressure.level, 0.3) and _heard.has(&"relief_vent"), "a relief valve vents 30% of the pressure")
	valve.receive_bash()
	_check(is_equal_approx(system.pressure.level, 0.3) and not valve.is_ready_to_vent(), "a vented valve must reseal before it vents again")

	var route: BurstRoute = _level.get_node("Hazards/RouteStacksWest") as BurstRoute
	system.pressure.level = system.pressure.warning_ratio - 0.01
	system.advance(1.0)
	_check(route.is_warning and _heard.has(&"pressure_klaxon"), "the klaxon sounds and the marked routes steam in the red")
	player.global_position = route.global_position + route.global_basis.x * 2.0 + Vector3(0.0, 0.05, 0.0)
	await _frames(3)
	system.pressure.level = 0.999
	system.advance(0.5)
	await _frames(5)
	_check(system.bursts == 1 and route.is_bursting() and _heard.has(&"pipe_burst"), "peak pressure bursts the marked routes")
	_check(absf(player.stats.max_health - player.health - route.damage) < 1.0, "a burst route scalds the Technician for %d" % int(route.damage))
	_check(system.pressure.level < system.pressure.warning_ratio and not route.is_warning, "after the burst the pressure falls back out of the red")
	await _frames(int(route.burst_time * 60.0) + 10)
	_check(not route.is_bursting(), "the burst blows itself out")
	_restore_player(player)

	var lift: SteamDoor = _level.get_node("Doors/ExchangeLiftDoor") as SteamDoor
	_check(not lift.is_open, "the exchange lift is held shut")
	var stack: JammedValve = _level.get_node("Interactables/MainReliefStack") as JammedValve
	for i: int in stack.hits_required:
		stack.receive_bash()
	await _frames(2)
	_check(lift.is_open, "freeing the Main Relief Stack opens the exchange lift")
	await _kill_all_enemies()
	await _ride_elevator(LEVEL_12)


# --- Level 12 -----------------------------------------------------------------------------------

func _test_level_12() -> void:
	var player: Technician = _player()
	var hud: Hud = _level.get_node("HUD") as Hud
	var walker: SteamWalker = _level.get_node("Enemies/SteamWalker") as SteamWalker
	_isolate_enemies([walker])
	_restore_player(player)
	_check(not hud.is_boss_bar_shown() and not hud.is_room_pressure_shown(), "no boss bar or pressure gauge before the fight")
	player.global_position = walker.global_position + Vector3(-9.0, 0.0, 0.0)
	await _frames(10)
	_check(walker.is_aggro and hud.is_boss_bar_shown(), "the Steam Walker wakes and its health bar appears")

	_restore_player(player)
	var stomped: bool = false
	for i: int in 240:
		await get_tree().physics_frame
		player.global_position = walker.global_position + Vector3(-3.0, 0.05, 0.0)
		if player.health < player.stats.max_health:
			stomped = true
			break
	_check(stomped and _heard.has(&"walker_stomp") and walker.phase() == 1, "in phase 1 the Walker stomps")
	_restore_player(player)

	walker.health = walker.stats.max_health * 0.6
	_check(walker.phase() == 2, "below two thirds health the Walker enters phase 2")
	var before: float = walker.health
	walker.receive_hit(100.0, Vector3.ZERO)
	_check(before - walker.health < 60.0, "outside a stagger the armoured Walker shrugs off half the damage")

	player.global_position = walker.global_position + Vector3(-5.0, 0.05, 0.0)
	await _frames(2)
	walker._begin_breath_windup()
	for i: int in 200:
		await get_tree().physics_frame
		player.global_position = walker.global_position + Vector3(-5.0, 0.05, 0.0)
		if walker.is_overheated():
			break
	_check(_heard.has(&"walker_breath") and player.health < player.stats.max_health, "the sweeping steam breath scalds the Technician")
	_check(walker.is_overheated(), "after the breath the Walker overheats")
	_restore_player(player)

	player.global_position = walker.global_position + Vector3(-2.4, 0.05, 0.0)
	await _frames(2)
	player.aim_direction = Vector3.RIGHT
	for i: int in SteamWalker.VALVE_HITS:
		player.aim_direction = Vector3.RIGHT
		player._swing_wrench(GameState.rig)
		await _frames(2)
	_check(walker.is_staggered(), "three wrench blows on the exposed valve stagger the Walker")
	before = walker.health
	walker.receive_hit(100.0, Vector3.ZERO)
	_check(before - walker.health > 150.0, "a staggered Walker takes double damage")
	_restore_player(player)

	walker.health = walker.stats.max_health * 0.3
	walker.move = SteamWalker.Move.RECOVER
	walker._since_adds = SteamWalker.ADD_INTERVAL - 0.05
	await _frames(10)
	_check(walker.phase() == 3 and walker.alive_adds() == 3, "in phase 3 the Walker whistles up two skitterers and a hound")
	_isolate_enemies([walker])
	player.global_position = walker.global_position + Vector3(-10.0, 0.05, 0.0)
	await _frames(2)
	walker._begin_charge()
	_restore_player(player)
	var charged: bool = false
	for i: int in 150:
		await get_tree().physics_frame
		if player.health < player.stats.max_health:
			charged = true
			break
	_check(charged and _heard.has(&"walker_charge") and player.health <= player.stats.max_health - SteamWalker.CHARGE_DAMAGE + 1.0, "the telegraphed charge runs the Technician down")
	_restore_player(player)

	var gate: SteamDoor = _level.get_node("Doors/FoundryGate") as SteamDoor
	walker.receive_hit(100000.0, Vector3.ZERO)
	await _frames(5)
	_check(walker.is_dead and not hud.is_boss_bar_shown(), "the Walker falls and its health bar goes")
	var seal: KeyPickup = null
	for child: Node in _level.get_node("Enemies").get_children():
		if child is KeyPickup and (child as KeyPickup).item_id == &"foundry_seal":
			seal = child as KeyPickup
	_check(seal != null, "the Walker drops the Foundry Seal")
	gate.use_panel()
	_check(not gate.is_open, "the Foundry Gate stays shut without the seal")
	if seal != null:
		player.global_position = seal.global_position + Vector3(0.0, 0.05, 0.0)
		await _frames(5)
	_check(GameState.has_item(&"foundry_seal"), "the Technician picks up the Foundry Seal")
	gate.use_panel()
	await _frames(2)
	_check(gate.is_open, "the Foundry Seal opens the Foundry Gate")
	await _kill_all_enemies()
	await _ride_elevator(FINALE)
