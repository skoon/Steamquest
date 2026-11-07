extends TestCase

const THEMES: Array[RoomDef.DressingTheme] = [
	RoomDef.DressingTheme.BOILER, RoomDef.DressingTheme.CUTTING,
	RoomDef.DressingTheme.SMELTING, RoomDef.DressingTheme.VAULT,
	RoomDef.DressingTheme.YARD, RoomDef.DressingTheme.TRAM, RoomDef.DressingTheme.SHOWROOM,
	RoomDef.DressingTheme.CISTERN, RoomDef.DressingTheme.GARDEN, RoomDef.DressingTheme.MINE,
	RoomDef.DressingTheme.TOWER, RoomDef.DressingTheme.ARCHIVE, RoomDef.DressingTheme.GENERATOR,
]


static func _has_collider(node: Node) -> bool:
	if node is StaticBody3D:
		return true
	for child: Node in node.get_children():
		if _has_collider(child):
			return true
	return false


func test_every_theme_has_all_three_placements() -> void:
	for theme: RoomDef.DressingTheme in THEMES:
		var seen: Dictionary = {}
		for spec: Dictionary in FoundryProps.catalog(theme):
			seen[spec["placement"]] = true
		assert_eq(seen.size(), 3, "theme %d has band props, wall fixtures and scatter" % theme)


func test_every_catalog_prop_builds_with_matching_collision() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 8
	for theme: RoomDef.DressingTheme in THEMES:
		for spec: Dictionary in FoundryProps.catalog(theme):
			var prop: Node3D = FoundryProps.build(spec["kind"], rng)
			assert_true(prop.get_child_count() > 0, "%s has geometry" % spec["kind"])
			assert_eq(_has_collider(prop), bool(spec["collides"]), "%s collision matches its catalog entry" % spec["kind"])
			prop.free()


func test_wall_band_props_block_and_scatter_does_not() -> void:
	for theme: RoomDef.DressingTheme in THEMES:
		for spec: Dictionary in FoundryProps.catalog(theme):
			match spec["placement"]:
				DressingLayout.Placement.WALL_BAND:
					assert_true(spec["collides"], "%s should block movement" % spec["kind"])
				_:
					assert_false(spec["collides"], "%s should not block movement" % spec["kind"])


func test_grime_mixes_are_never_empty() -> void:
	for theme: RoomDef.DressingTheme in THEMES:
		assert_false(FoundryProps.floor_grime(theme).is_empty(), "floor grime for theme %d" % theme)
		assert_false(FoundryProps.wall_grime(theme).is_empty(), "wall grime for theme %d" % theme)
