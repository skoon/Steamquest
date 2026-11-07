class_name Technician
extends CharacterBody3D
## The player: camera-relative movement, steam dash, wrench, rivet gun and lubricant vent.
## All friction/wear math lives in FrictionModel; this script only feeds it work and reads multipliers.

const GRAVITY: float = 20.0
const HUD_BROADCAST_INTERVAL: float = 0.1
const KNOCKBACK_DECAY: float = 30.0
const SWING_FX_TIME: float = 0.14
## After a swing or shot the model keeps facing the aim this long, even while moving.
const AIM_FACE_TIME: float = 0.45

@export var stats: TechnicianStats
@export var rivet_scene: PackedScene

@onready var sprite: CharacterModel = $Model
@onready var aim_pivot: Node3D = $AimPivot
@onready var wrench_hitbox: Area3D = $AimPivot/WrenchHitbox
@onready var wrench_shape: CollisionShape3D = $AimPivot/WrenchHitbox/CollisionShape3D
@onready var muzzle: Marker3D = $AimPivot/Muzzle
@onready var interact_area: Area3D = $InteractArea

var health: float = 0.0
var pressure: SteamPressure
var aim_direction: Vector3 = Vector3.FORWARD
var is_dead: bool = false
## Standing on a descending exit lift: controls and collisions are off and nothing can hurt.
var is_riding_lift: bool = false

var _wrench_cooldown: float = 0.0
var _rivet_cooldown: float = 0.0
var _dash_cooldown: float = 0.0
var _dash_time_left: float = 0.0
var _dash_direction: Vector3 = Vector3.ZERO
var _vent_cooldown: float = 0.0
var _invulnerable_time: float = 0.0
var _knockback: Vector3 = Vector3.ZERO
var _hud_timer: float = 0.0
var _focused: Interactable
var _last_prompt: String = ""
var _rig_signature: String = ""
var _was_overclocked: bool = false
var _swing_time_left: float = 0.0
var _aim_face_time: float = 0.0
var _swing_mesh: MeshInstance3D
var _dash_steam: GPUParticles3D
var _golden_light: OmniLight3D
var _lantern: OmniLight3D
## Movement scale and DRIVE-wear scale set by terrain such as deep water.
var terrain_speed: float = 1.0
var terrain_drive_work: float = 1.0
## External shove for this frame only (wind, propellers); consumed by _update_movement.
var push_velocity: Vector3 = Vector3.ZERO
var _applied_push: Vector3 = Vector3.ZERO


func _ready() -> void:
	assert(stats != null, "Technician: stats resource missing")
	assert(rivet_scene != null, "Technician: rivet_scene missing")
	add_to_group(&"player")
	health = stats.max_health
	pressure = SteamPressure.new(stats.max_pressure, stats.pressure_regen, stats.pressure_regen_delay)
	var wrench_sphere: SphereShape3D = SphereShape3D.new()
	wrench_sphere.radius = stats.wrench_range
	wrench_shape.shape = wrench_sphere
	_build_visuals()
	GameState.golden_gear_acquired.connect(_on_golden_gear_acquired)
	_broadcast_all.call_deferred()


func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = velocity.move_toward(Vector3.ZERO, KNOCKBACK_DECAY * delta)
		move_and_slide()
		return
	var rig: FrictionModel = GameState.rig
	rig.tick(delta)
	_tick_timers(delta)
	_update_aim()
	var wish: Vector3 = _read_move_input()
	_handle_actions(rig, wish)
	_update_movement(delta, rig, wish)
	_regenerate_pressure(delta, rig)
	_update_interaction()
	_update_animation()
	_update_swing_fx(delta)
	_hud_timer -= delta
	if _hud_timer <= 0.0:
		_hud_timer = HUD_BROADCAST_INTERVAL
		_broadcast_periodic(rig)


# --- Input & movement -------------------------------------------------------

func _camera() -> Camera3D:
	var camera: Camera3D = get_viewport().get_camera_3d()
	assert(camera != null, "Technician: no active Camera3D")
	return camera


func _camera_axes() -> Array[Vector3]:
	var basis: Basis = _camera().global_basis
	var forward: Vector3 = Vector3(-basis.z.x, 0.0, -basis.z.z).normalized()
	var right: Vector3 = Vector3(basis.x.x, 0.0, basis.x.z).normalized()
	return [forward, right]


func _read_move_input() -> Vector3:
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var axes: Array[Vector3] = _camera_axes()
	var wish: Vector3 = axes[1] * input.x + axes[0] * -input.y
	return wish.limit_length(1.0)


func _update_aim() -> void:
	var camera: Camera3D = _camera()
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = camera.project_ray_origin(mouse)
	var ray_normal: Vector3 = camera.project_ray_normal(mouse)
	var aim_plane: Plane = Plane(Vector3.UP, global_position.y)
	var hit: Variant = aim_plane.intersects_ray(ray_origin, ray_normal)
	if hit != null:
		var flat: Vector3 = (hit as Vector3) - global_position
		flat.y = 0.0
		if flat.length_squared() > 0.01:
			aim_direction = flat.normalized()
	aim_pivot.look_at(aim_pivot.global_position + aim_direction, Vector3.UP)


func _update_movement(delta: float, rig: FrictionModel, wish: Vector3) -> void:
	# Last frame's knockback and push are layered on top of the walk velocity; strip them back out
	# so neither builds up from frame to frame.
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z) - _knockback - _applied_push
	if _dash_time_left > 0.0:
		horizontal = _dash_direction * stats.dash_speed
	else:
		var target: Vector3 = wish * stats.move_speed * rig.speed_multiplier(FrictionModel.Socket.DRIVE) * terrain_speed
		horizontal = horizontal.move_toward(target, stats.acceleration * delta)
	_knockback = _knockback.move_toward(Vector3.ZERO, KNOCKBACK_DECAY * delta)
	velocity.x = horizontal.x + _knockback.x + push_velocity.x
	velocity.z = horizontal.z + _knockback.z + push_velocity.z
	_applied_push = push_velocity
	push_velocity = Vector3.ZERO
	velocity.y = 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
	var before: Vector3 = global_position
	move_and_slide()
	var moved: Vector3 = global_position - before
	moved.y = 0.0
	rig.apply_work(FrictionModel.Socket.DRIVE, moved.length() * stats.drive_work_per_meter * terrain_drive_work, GameState.rng.randf())


# --- Actions ----------------------------------------------------------------

func _handle_actions(rig: FrictionModel, wish: Vector3) -> void:
	if Input.is_action_just_pressed("dash"):
		_try_dash(wish)
	if Input.is_action_pressed("attack_primary") and _wrench_cooldown <= 0.0:
		_swing_wrench(rig)
	if Input.is_action_pressed("attack_secondary") and _rivet_cooldown <= 0.0:
		_fire_rivet(rig)
	if Input.is_action_just_pressed("ability_utility"):
		_try_vent(rig)
	if Input.is_action_just_pressed("interact") and _focused != null and is_instance_valid(_focused):
		_focused.interact(self)


func _try_dash(wish: Vector3) -> void:
	if _dash_cooldown > 0.0 or _dash_time_left > 0.0:
		return
	if not pressure.try_spend(stats.dash_cost):
		GameState.post_notice("Not enough steam pressure to dash")
		return
	_dash_direction = wish.normalized() if wish.length_squared() > 0.01 else aim_direction
	_dash_time_left = stats.dash_duration
	_dash_cooldown = stats.dash_cooldown
	_invulnerable_time = maxf(_invulnerable_time, stats.dash_duration + 0.05)
	_dash_steam.restart()
	Fx.steam_puff(get_parent(), global_position + Vector3.UP * 0.4)
	Audio.play_at(&"dash_hiss", global_position)
	GameState.rig.apply_work(FrictionModel.Socket.DRIVE, 1.0, GameState.rng.randf())


func _swing_wrench(rig: FrictionModel) -> void:
	_wrench_cooldown = stats.wrench_cooldown / rig.speed_multiplier(FrictionModel.Socket.ARM)
	var damage: float = DamageCalc.outgoing_damage(stats.wrench_damage, GameState.has_golden_gear, rig.is_overclocked())
	var hit_any: bool = false
	var bong_at: Vector3 = Vector3.INF
	var clang_at: Vector3 = Vector3.INF
	for body: Node3D in wrench_hitbox.get_overlapping_bodies():
		if body == self or not body.has_method("receive_hit"):
			continue
		if not DamageCalc.is_in_arc(global_position, aim_direction, body.global_position, stats.wrench_arc_degrees):
			continue
		var push: Vector3 = DamageCalc.knockback(global_position, body.global_position, stats.wrench_knockback, 0.0)
		body.call("receive_hit", damage, push)
		Fx.sparks(get_parent(), body.global_position + Vector3.UP * 0.8)
		bong_at = body.global_position
		hit_any = true
	for area: Area3D in wrench_hitbox.get_overlapping_areas():
		if not area.has_method("receive_bash"):
			continue
		if not DamageCalc.is_in_arc(global_position, aim_direction, area.global_position, stats.wrench_arc_degrees):
			continue
		area.call("receive_bash")
		Fx.sparks(get_parent(), area.global_position)
		clang_at = area.global_position
		hit_any = true
	rig.apply_work(FrictionModel.Socket.ARM, stats.arm_work_per_attack * (1.0 if hit_any else 0.6), GameState.rng.randf())
	Audio.play_at(&"wrench_whoosh", global_position)
	if bong_at != Vector3.INF:
		Audio.play_at(&"wrench_bong", bong_at, 0.0, 0.05)
	if clang_at != Vector3.INF:
		Audio.play_at(&"wrench_clang", clang_at)
	sprite.play_attack()
	_aim_face_time = AIM_FACE_TIME
	_swing_time_left = SWING_FX_TIME
	_swing_mesh.visible = true


func _fire_rivet(rig: FrictionModel) -> void:
	if not pressure.try_spend(stats.rivet_cost):
		_rivet_cooldown = 0.3
		GameState.post_notice("Rivet gun out of steam pressure")
		return
	_rivet_cooldown = stats.rivet_cooldown / rig.speed_multiplier(FrictionModel.Socket.ARM)
	var damage: float = DamageCalc.outgoing_damage(stats.rivet_damage, GameState.has_golden_gear, rig.is_overclocked())
	var rivet: Projectile = rivet_scene.instantiate() as Projectile
	assert(rivet != null, "Technician: rivet_scene root must use projectile.gd")
	get_parent().add_child(rivet)
	rivet.launch(muzzle.global_position, aim_direction, stats.rivet_speed, damage, stats.rivet_knockback, stats.rivet_lifetime)
	Audio.play_at(&"rivet_fire", muzzle.global_position)
	rig.apply_work(FrictionModel.Socket.ARM, stats.arm_work_per_attack * 0.5, GameState.rng.randf())
	sprite.play_attack()
	_aim_face_time = AIM_FACE_TIME


func _try_vent(rig: FrictionModel) -> void:
	if _vent_cooldown > 0.0:
		GameState.post_notice("Lubricant vent recharging (%.0fs)" % _vent_cooldown)
		return
	_vent_cooldown = stats.vent_cooldown
	rig.lubricate_all()
	rig.start_overclock(stats.overclock_duration, stats.overclock_bonus)
	for i: int in 4:
		var angle: float = TAU * float(i) / 4.0
		Fx.steam_puff(get_parent(), global_position + Vector3(cos(angle), 0.5, sin(angle)) * 0.8)
	Audio.play_at(&"vent_hiss", global_position)
	Audio.play_at(&"vent_whistle", global_position + Vector3.UP)
	GameState.post_notice("Lubricant vented - friction purged, OVERCLOCK engaged!")
	GameState.notify_rig_changed()


func _regenerate_pressure(delta: float, rig: FrictionModel) -> void:
	var gained: float = pressure.tick(delta, rig.speed_multiplier(FrictionModel.Socket.PUMP))
	rig.apply_work(FrictionModel.Socket.PUMP, gained * stats.pump_work_per_pressure, GameState.rng.randf())


func _tick_timers(delta: float) -> void:
	_wrench_cooldown = maxf(_wrench_cooldown - delta, 0.0)
	_rivet_cooldown = maxf(_rivet_cooldown - delta, 0.0)
	_dash_cooldown = maxf(_dash_cooldown - delta, 0.0)
	_dash_time_left = maxf(_dash_time_left - delta, 0.0)
	_vent_cooldown = maxf(_vent_cooldown - delta, 0.0)
	_invulnerable_time = maxf(_invulnerable_time - delta, 0.0)
	_aim_face_time = maxf(_aim_face_time - delta, 0.0)


# --- Damage -----------------------------------------------------------------

func receive_hit(damage: float, knockback: Vector3) -> void:
	if is_dead or is_riding_lift or _invulnerable_time > 0.0 or GameState.is_victorious:
		return
	health = DamageCalc.apply_to_health(health, damage)
	_knockback += knockback
	_invulnerable_time = stats.invulnerability_after_hit
	sprite.flash_hit()
	Audio.play_at(&"player_hurt", global_position)
	GameState.health_changed.emit(health, stats.max_health)
	if health <= 0.0:
		_die()


func _die() -> void:
	is_dead = true
	sprite.play_death()
	_swing_mesh.visible = false
	GameState.interaction_prompt_changed.emit("")
	GameState.player_died.emit()


# --- Interaction --------------------------------------------------------------

func _update_interaction() -> void:
	var best: Interactable = null
	var best_distance: float = INF
	for area: Area3D in interact_area.get_overlapping_areas():
		var candidate: Interactable = area as Interactable
		if candidate == null or not candidate.can_interact():
			continue
		var distance: float = candidate.global_position.distance_squared_to(global_position)
		if distance < best_distance:
			best_distance = distance
			best = candidate
	_focused = best
	var prompt: String = best.get_prompt() if best != null else ""
	if prompt != _last_prompt:
		_last_prompt = prompt
		GameState.interaction_prompt_changed.emit(prompt)


# --- Presentation -------------------------------------------------------------

func _update_animation() -> void:
	var flat_velocity: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	sprite.play_locomotion(flat_velocity)
	if not is_dead:
		sprite.face(facing_for(flat_velocity, aim_direction, _aim_face_time > 0.0))
	sprite.speed_scale = GameState.rig.speed_multiplier(FrictionModel.Socket.DRIVE)


## The model faces where it is walking, or the aim when standing still or just after attacking.
static func facing_for(flat_velocity: Vector3, aim: Vector3, recently_attacked: bool) -> Vector3:
	if recently_attacked or flat_velocity.length() < CharacterModel.MOVING_SPEED:
		return aim
	return flat_velocity.normalized()


func _update_swing_fx(delta: float) -> void:
	if _swing_time_left <= 0.0:
		return
	_swing_time_left -= delta
	if _swing_time_left <= 0.0:
		_swing_mesh.visible = false


func _build_visuals() -> void:
	add_child(Fx.make_blob_shadow(0.55))

	var indicator: MeshInstance3D = MeshInstance3D.new()
	var indicator_mesh: BoxMesh = BoxMesh.new()
	indicator_mesh.size = Vector3(0.14, 0.04, 0.55)
	indicator.mesh = indicator_mesh
	indicator.material_override = FoundryMaterials.emissive(Color(1.0, 0.75, 0.3), 1.5)
	indicator.position = Vector3(0.0, -0.85, -1.25)
	aim_pivot.add_child(indicator)

	_swing_mesh = MeshInstance3D.new()
	_swing_mesh.mesh = _build_arc_mesh(stats.wrench_range, stats.wrench_arc_degrees)
	var swing_mat: StandardMaterial3D = FoundryMaterials.emissive(Color(1.0, 0.8, 0.45), 2.0)
	swing_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	swing_mat.albedo_color = Color(1.0, 0.8, 0.45, 0.45)
	swing_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	swing_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_swing_mesh.material_override = swing_mat
	_swing_mesh.position = Vector3(0.0, -0.4, 0.0)
	_swing_mesh.visible = false
	aim_pivot.add_child(_swing_mesh)

	_dash_steam = Fx.make_steam_emitter(18, 0.5, 1.5, 70.0)
	_dash_steam.one_shot = true
	_dash_steam.explosiveness = 0.6
	_dash_steam.emitting = false
	_dash_steam.position = Vector3(0.0, 0.3, 0.0)
	add_child(_dash_steam)


## Flat fan in the XZ plane opening toward -Z.
static func _build_arc_mesh(radius: float, arc_degrees: float) -> ArrayMesh:
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments: int = 16
	var half: float = deg_to_rad(arc_degrees * 0.5)
	var inner: float = radius * 0.35
	for i: int in segments:
		var a0: float = -half + (2.0 * half) * float(i) / float(segments)
		var a1: float = -half + (2.0 * half) * float(i + 1) / float(segments)
		var o0: Vector3 = Vector3(sin(a0), 0.0, -cos(a0)) * radius
		var o1: Vector3 = Vector3(sin(a1), 0.0, -cos(a1)) * radius
		var i0: Vector3 = Vector3(sin(a0), 0.0, -cos(a0)) * inner
		var i1: Vector3 = Vector3(sin(a1), 0.0, -cos(a1)) * inner
		surface.add_vertex(i0)
		surface.add_vertex(o0)
		surface.add_vertex(o1)
		surface.add_vertex(i0)
		surface.add_vertex(o1)
		surface.add_vertex(i1)
	return surface.commit()


func apply_push(push: Vector3) -> void:
	push_velocity += Vector3(push.x, 0.0, push.z)


## Winched back up after falling off a deck: costs hull, lands at `respawn`.
func recover_from_fall(damage: float, respawn: Vector3) -> void:
	if is_dead:
		return
	_invulnerable_time = 0.0
	receive_hit(damage, Vector3.ZERO)
	velocity = Vector3.ZERO
	_knockback = Vector3.ZERO
	_applied_push = Vector3.ZERO
	global_position = respawn


## Hands control to an exit lift, which then moves the Technician itself.
func ride_lift() -> void:
	is_riding_lift = true
	set_physics_process(false)
	velocity = Vector3.ZERO
	collision_layer = 0
	collision_mask = 0


## A carried brass lantern for dark levels.
func set_lantern(enabled: bool) -> void:
	if enabled and _lantern == null:
		_lantern = OmniLight3D.new()
		_lantern.name = "Lantern"
		_lantern.light_color = Color(1.0, 0.78, 0.45)
		_lantern.light_energy = 2.6
		_lantern.omni_range = 6.5
		_lantern.omni_attenuation = 1.2
		_lantern.shadow_enabled = true
		_lantern.position = Vector3(0.0, 1.8, 0.0)
		add_child(_lantern)
	elif _lantern != null:
		_lantern.visible = enabled


func has_lantern() -> bool:
	return _lantern != null and _lantern.visible


func _on_golden_gear_acquired() -> void:
	_golden_light = OmniLight3D.new()
	_golden_light.light_color = Color(1.0, 0.8, 0.35)
	_golden_light.light_energy = 1.5
	_golden_light.omni_range = 4.0
	_golden_light.position = Vector3(0.0, 1.2, 0.0)
	add_child(_golden_light)
	GameState.post_notice("THE GOLDEN GEAR is seated - friction eliminated, rig overclocked!")


# --- HUD broadcasting -------------------------------------------------------------

func _broadcast_all() -> void:
	GameState.health_changed.emit(health, stats.max_health)
	GameState.pressure_changed.emit(pressure.current, pressure.max_pressure)
	GameState.notify_rig_changed()
	GameState.vent_cooldown_changed.emit(_vent_cooldown, stats.vent_cooldown)
	GameState.overclock_changed.emit(false)


func _broadcast_periodic(rig: FrictionModel) -> void:
	GameState.pressure_changed.emit(pressure.current, pressure.max_pressure)
	GameState.friction_updated.emit(rig.total_friction(), rig.worst_wear_percent())
	GameState.vent_cooldown_changed.emit(_vent_cooldown, stats.vent_cooldown)
	var overclocked: bool = rig.is_overclocked()
	if overclocked != _was_overclocked:
		_was_overclocked = overclocked
		GameState.overclock_changed.emit(overclocked)
	var signature: String = _compute_rig_signature(rig)
	if signature != _rig_signature:
		_announce_gear_failures(rig)
		_rig_signature = signature
		GameState.gears_changed.emit(rig)


func _compute_rig_signature(rig: FrictionModel) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for socket: int in FrictionModel.SOCKET_COUNT:
		var gear: GearItem = rig.get_gear(socket)
		parts.append("none" if gear == null else "%s:%d:%d" % [gear.gear_name, gear.state, int(gear.wear_percent())])
	return "|".join(parts)


func _announce_gear_failures(rig: FrictionModel) -> void:
	if _rig_signature.is_empty():
		return
	var previous: PackedStringArray = _rig_signature.split("|")
	for socket: int in FrictionModel.SOCKET_COUNT:
		var gear: GearItem = rig.get_gear(socket)
		if gear == null or socket >= previous.size():
			continue
		var was: String = previous[socket]
		var now_state: String = ":%d:" % gear.state
		if was.contains(now_state):
			continue
		if gear.state == GearItem.GearState.JAMMED:
			GameState.post_notice("%s JAMMED - vent lubricant [R]!" % FrictionModel.socket_name(socket))
		elif gear.state == GearItem.GearState.SHATTERED:
			GameState.post_notice("%s gear SHATTERED - scavenge a replacement!" % FrictionModel.socket_name(socket))
