extends TestCase

const STEP: float = 1.0 / 60.0


static func _make(model_name: String, rig: CharacterModel.Rig, pack: String = ModelLibrary.ENEMIES) -> CharacterModel:
	var model: CharacterModel = CharacterModel.new()
	model.model_pack = pack
	model.model_name = model_name
	model.model_height = 1.5
	model.rig = rig
	model._ready()
	return model


static func _run(model: CharacterModel, seconds: float) -> void:
	var elapsed: float = 0.0
	while elapsed < seconds:
		model._process(STEP)
		elapsed += STEP


static func _first_part(model: CharacterModel, suffix: String) -> Node3D:
	return _find(model, suffix)


static func _find(node: Node, suffix: String) -> Node3D:
	if String(node.name).ends_with(suffix) and node is Node3D:
		return node as Node3D
	for child: Node in node.get_children():
		var found: Node3D = _find(child, suffix)
		if found != null:
			return found
	return null


func test_rig_parts_are_found_for_each_body_type() -> void:
	var player: CharacterModel = _make("player_woman_athletic", CharacterModel.Rig.BIPED, ModelLibrary.PLAYERS_FEMALE)
	for role: StringName in [&"leg_l", &"leg_r", &"arm_l", &"arm_r", &"torso", &"head"]:
		assert_eq(player.rig_part_count(role), 1, "the Technician has one %s" % role)
	player.free()
	var hound: CharacterModel = _make("enemy_clockwork_hound", CharacterModel.Rig.QUADRUPED)
	assert_eq(hound.rig_part_count(&"leg_l"), 2, "the hound swings one diagonal pair of legs")
	assert_eq(hound.rig_part_count(&"leg_r"), 2, "and the other diagonal pair")
	assert_eq(hound.rig_part_count(&"gears"), 4, "the hound has four flank gears")
	hound.free()
	var spider: CharacterModel = _make("enemy_steam_spider", CharacterModel.Rig.SPIDER)
	assert_eq(spider.rig_part_count(&"spider_a") + spider.rig_part_count(&"spider_b"), 8, "the spider has eight legs")
	spider.free()
	var drone: CharacterModel = _make("enemy_tesla_drone", CharacterModel.Rig.HOVER)
	assert_true(drone.rig_part_count(&"gimbal") >= 3, "the drone has gimbal rings to spin")
	drone.free()
	for model_name: String in ["enemy_diver_brute", "enemy_brass_sentry"]:
		var biped: CharacterModel = _make(model_name, CharacterModel.Rig.BIPED)
		assert_eq(biped.rig_part_count(&"leg_l") + biped.rig_part_count(&"leg_r"), 2, "%s has two legs" % model_name)
		assert_eq(biped.rig_part_count(&"arm_r"), 1, "%s has a right arm to attack with" % model_name)
		biped.free()


func test_locomotion_switches_between_idle_and_walk() -> void:
	var model: CharacterModel = _make("enemy_diver_brute", CharacterModel.Rig.BIPED)
	model.play_locomotion(Vector3(2.0, 0.0, 0.0))
	assert_eq(model.animation, &"walk", "moving plays the walk")
	model.play_locomotion(Vector3(0.05, 0.0, 0.0))
	assert_eq(model.animation, &"idle", "standing still plays idle")
	model.free()


func test_walking_swings_the_legs_and_ticks_frames() -> void:
	var model: CharacterModel = _make("enemy_diver_brute", CharacterModel.Rig.BIPED)
	var leg: Node3D = _first_part(model, "_Rig_leg_l")
	var rest: Basis = leg.basis
	var frames: Array[int] = []
	model.frame_changed.connect(func() -> void: frames.append(model.frame))
	model.play_locomotion(Vector3(0.0, 0.0, 2.6))
	_run(model, 0.4)
	assert_false(leg.basis.is_equal_approx(rest), "the left leg swings while walking")
	_run(model, 1.2)
	assert_true(frames.size() >= 3, "walk frames advance for footstep sounds (got %d)" % frames.size())
	assert_true(frames.has(0) and frames.has(2), "both footfall frames come round")
	model.free()


func test_attack_plays_once_and_blocks_locomotion() -> void:
	var model: CharacterModel = _make("enemy_brass_sentry", CharacterModel.Rig.BIPED)
	var arm: Node3D = _first_part(model, "_Rig_arm_r")
	var rest: Basis = arm.basis
	model.play_attack()
	model.play_locomotion(Vector3(3.0, 0.0, 0.0))
	assert_eq(model.animation, &"attack", "moving does not cut the attack short")
	_run(model, CharacterModel.ATTACK_TIME * 0.4)
	assert_false(arm.basis.is_equal_approx(rest), "the right arm swings during the attack")
	_run(model, CharacterModel.ATTACK_TIME)
	assert_eq(model.animation, &"idle", "the attack returns to idle")
	model.free()


func test_death_is_one_shot_and_final() -> void:
	var model: CharacterModel = _make("enemy_clockwork_hound", CharacterModel.Rig.QUADRUPED)
	model.play_death()
	_run(model, CharacterModel.DEATH_TIME + 0.2)
	assert_false(model.is_playing(), "the death finishes")
	model.play_locomotion(Vector3(5.0, 0.0, 0.0))
	assert_eq(model.animation, &"death", "a dead model does not walk again")
	model.free()


func test_model_turns_toward_movement() -> void:
	var model: CharacterModel = _make("enemy_steam_spider", CharacterModel.Rig.SPIDER)
	model.play_locomotion(Vector3(4.0, 0.0, 0.0))
	_run(model, 1.0)
	assert_almost(model.facing_yaw(), PI * 0.5, "the spider turns to face +X", 0.05)
	model.face_movement = false
	model.play_locomotion(Vector3(0.0, 0.0, -4.0))
	_run(model, 1.0)
	assert_almost(model.facing_yaw(), PI * 0.5, "with face_movement off it keeps its facing", 0.05)
	model.face_immediately(Vector3(0.0, 0.0, -1.0))
	assert_almost(absf(model.facing_yaw()), PI, "face_immediately snaps to -Z", 0.01)
	model.free()


func test_modulate_alpha_fades_every_mesh() -> void:
	var model: CharacterModel = _make("enemy_tesla_drone", CharacterModel.Rig.HOVER)
	model.modulate = Color(1.0, 1.0, 1.0, 0.25)
	var meshes: Array[Node] = model.find_children("*", "GeometryInstance3D", true, false)
	assert_true(meshes.size() > 0, "the drone has meshes")
	for mesh: Node in meshes:
		assert_almost((mesh as GeometryInstance3D).transparency, 0.75, "%s fades with modulate alpha" % mesh.name, 0.001)
		assert_true((mesh as GeometryInstance3D).material_overlay != null, "%s carries the tint overlay" % mesh.name)
	model.free()


func test_tint_and_flash_drive_the_overlay() -> void:
	var model: CharacterModel = _make("enemy_diver_brute", CharacterModel.Rig.BIPED)
	var mesh: GeometryInstance3D = model.find_children("*", "GeometryInstance3D", true, false)[0] as GeometryInstance3D
	var overlay: ShaderMaterial = mesh.material_overlay as ShaderMaterial
	assert_almost(float(overlay.get_shader_parameter(&"tint_strength")), 0.0, "white modulate leaves the model untinted")
	model.modulate = Color(0.45, 0.5, 0.6)
	assert_true(float(overlay.get_shader_parameter(&"tint_strength")) > 0.0, "a coloured modulate tints the model")
	model.modulate = Color.WHITE
	model.flash_hit(0.1)
	assert_eq(overlay.get_shader_parameter(&"tint_color"), CharacterModel.FLASH_COLOR, "a hit flashes red")
	_run(model, 0.2)
	assert_almost(float(overlay.get_shader_parameter(&"tint_strength")), 0.0, "the flash wears off")
	model.free()
