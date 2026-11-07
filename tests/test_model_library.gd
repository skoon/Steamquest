extends TestCase

## Every model the game asks for, by pack.
const USED_MODELS: Dictionary = {
	ModelLibrary.PLAYERS_FEMALE: ["player_woman_athletic"],
	ModelLibrary.ENEMIES: ["enemy_clockwork_hound", "enemy_steam_spider", "enemy_tesla_drone", "enemy_diver_brute", "enemy_brass_sentry"],
	ModelLibrary.PROPS: ["tesla_coil", "steam_walker", "boiler_tank", "airship", "gear_stack", "automaton_head", "wind_up_key", "propeller"],
	ModelLibrary.FURNITURE: ["furniture_desk", "furniture_sofa", "furniture_armchair", "furniture_cabinet", "furniture_bookcase", "furniture_grandfather_clock"],
}


func test_every_model_the_game_uses_exists() -> void:
	for pack: String in USED_MODELS:
		for model_name: String in USED_MODELS[pack]:
			assert_true(ModelLibrary.has_model(pack, model_name), "%s has %s" % [pack, model_name])


func test_unknown_model_is_reported_missing() -> void:
	assert_false(ModelLibrary.has_model(ModelLibrary.PROPS, "no_such_model"), "missing models are not found")


func test_instance_removes_the_pack_offset() -> void:
	var boiler: Node3D = ModelLibrary.instance(ModelLibrary.PROPS, "boiler_tank")
	assert_vec_almost(boiler.position, Vector3.ZERO, "the boiler is not left at its spot in the pack")
	var bounds: AABB = ModelLibrary.local_bounds(boiler)
	assert_true(absf(bounds.get_center().x) < 0.5 and absf(bounds.get_center().z) < 0.5, "the boiler sits near the origin")
	boiler.free()


func test_instances_are_independent_copies() -> void:
	var first: Node3D = ModelLibrary.instance(ModelLibrary.PROPS, "gear_stack")
	var second: Node3D = ModelLibrary.instance(ModelLibrary.PROPS, "gear_stack")
	assert_true(first != second, "each call returns a new node")
	assert_eq(first.get_child_count(), second.get_child_count(), "copies have the same parts")
	first.free()
	second.free()


func test_fitted_model_stands_on_the_floor_at_the_requested_height() -> void:
	var clock: Node3D = ModelLibrary.instance_fitted(ModelLibrary.FURNITURE, "furniture_grandfather_clock", 3.0)
	var bounds: AABB = ModelLibrary.local_bounds(clock)
	assert_almost(bounds.size.y, 3.0, "the clock is 3 m tall", 0.01)
	assert_almost(bounds.position.y, 0.0, "the clock stands on y = 0", 0.01)
	assert_almost(bounds.get_center().x, 0.0, "the clock is centred in x", 0.01)
	assert_almost(bounds.get_center().z, 0.0, "the clock is centred in z", 0.01)
	clock.free()


func test_fitted_model_can_be_centred_vertically() -> void:
	var drone: Node3D = ModelLibrary.instance_fitted(ModelLibrary.ENEMIES, "enemy_tesla_drone", 1.2, true)
	var bounds: AABB = ModelLibrary.local_bounds(drone)
	assert_almost(bounds.size.y, 1.2, "the drone is 1.2 m tall", 0.01)
	assert_almost(bounds.get_center().y, 0.0, "the drone is centred on its node", 0.01)
	drone.free()


func test_palette_colours_every_material_in_every_pack() -> void:
	for pack: String in [ModelLibrary.ENEMIES, ModelLibrary.FURNITURE, ModelLibrary.PLAYERS_FEMALE, ModelLibrary.PLAYERS_MALE, ModelLibrary.PROPS]:
		var root: Node = (load(pack) as PackedScene).instantiate()
		ModelPalette.apply(root)
		for node: Node in root.find_children("*", "MeshInstance3D", true, false):
			var mesh: Mesh = (node as MeshInstance3D).mesh
			for surface: int in mesh.get_surface_count():
				var material: BaseMaterial3D = mesh.surface_get_material(surface) as BaseMaterial3D
				assert_true(ModelPalette.COLORS.has(StringName(material.resource_name)), "%s has a palette colour" % material.resource_name)
		root.free()


func test_brass_is_no_longer_white() -> void:
	var sentry: Node3D = ModelLibrary.instance(ModelLibrary.ENEMIES, "enemy_brass_sentry")
	var found_brass: bool = false
	for node: Node in sentry.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = (node as MeshInstance3D).mesh
		for surface: int in mesh.get_surface_count():
			var material: BaseMaterial3D = mesh.surface_get_material(surface) as BaseMaterial3D
			if material.resource_name == "SP_MAT_BRASS":
				found_brass = true
				assert_true(material.albedo_color.b < 0.5, "brass is coloured, not white")
	assert_true(found_brass, "the sentry uses brass")
	sentry.free()
