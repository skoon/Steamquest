extends TestCase

const INTERIOR: Rect2 = Rect2(0.0, -10.0, 24.0, 20.0)
const BAND_MIN: float = 0.6
const BAND_MAX: float = 2.2

var _catalog: Array[Dictionary] = []


func before_each() -> void:
	_catalog = [
		{"kind": &"crate", "radius": 0.6, "weight": 2.0, "placement": DressingLayout.Placement.WALL_BAND, "collides": true},
		{"kind": &"boiler", "radius": 1.4, "weight": 1.0, "placement": DressingLayout.Placement.WALL_BAND, "collides": true},
		{"kind": &"gauge", "radius": 0.5, "weight": 1.0, "placement": DressingLayout.Placement.WALL_MOUNT, "collides": false},
		{"kind": &"bolts", "radius": 0.3, "weight": 1.0, "placement": DressingLayout.Placement.FLOOR, "collides": false},
	]


func _plan(seed_value: int, exclusions: PackedVector3Array, density: float = 0.3) -> Array[Dictionary]:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var counts: Dictionary = DressingLayout.counts_for(INTERIOR, density)
	return DressingLayout.plan(INTERIOR, BAND_MIN, BAND_MAX, exclusions, _catalog, counts, rng)


func test_counts_scale_with_room_size_and_density() -> void:
	var counts: Dictionary = DressingLayout.counts_for(INTERIOR, 0.25)
	# Perimeter 88 m, area 480 m².
	assert_eq(counts[DressingLayout.Placement.WALL_BAND], 22, "band props per metre of wall")
	assert_eq(counts[DressingLayout.Placement.WALL_MOUNT], roundi(88.0 * 0.25 * DressingLayout.MOUNT_FACTOR), "wall fixtures")
	assert_eq(counts[DressingLayout.Placement.FLOOR], roundi(480.0 * 0.25 * DressingLayout.FLOOR_FACTOR), "floor scatter")


func test_zero_density_plans_nothing() -> void:
	assert_true(_plan(1, PackedVector3Array(), 0.0).is_empty(), "no clutter at density 0")
	var decals: Vector2i = DressingLayout.decal_counts_for(INTERIOR, 0.0)
	assert_eq(decals, Vector2i.ZERO, "no grime at density 0")


func test_same_seed_gives_same_layout() -> void:
	var first: Array[Dictionary] = _plan(42, PackedVector3Array())
	var second: Array[Dictionary] = _plan(42, PackedVector3Array())
	assert_eq(first.size(), second.size(), "same prop count")
	for i: int in first.size():
		assert_eq(first[i]["kind"], second[i]["kind"], "same kind at %d" % i)
		assert_true((first[i]["position"] as Vector2).is_equal_approx(second[i]["position"]), "same position at %d" % i)


func test_different_seeds_differ() -> void:
	var first: Array[Dictionary] = _plan(1, PackedVector3Array())
	var second: Array[Dictionary] = _plan(2, PackedVector3Array())
	var identical: bool = first.size() == second.size()
	if identical:
		for i: int in first.size():
			if not (first[i]["position"] as Vector2).is_equal_approx(second[i]["position"]):
				identical = false
	assert_false(identical, "a new seed rearranges the room")


func test_places_every_placement_kind() -> void:
	var placed: Array[Dictionary] = _plan(7, PackedVector3Array())
	var seen: Dictionary = {}
	for entry: Dictionary in placed:
		seen[entry["placement"]] = true
	assert_true(seen.has(DressingLayout.Placement.WALL_BAND), "band props placed")
	assert_true(seen.has(DressingLayout.Placement.WALL_MOUNT), "wall fixtures placed")
	assert_true(seen.has(DressingLayout.Placement.FLOOR), "floor scatter placed")


func test_props_never_overlap_within_their_layer() -> void:
	var placed: Array[Dictionary] = _plan(3, PackedVector3Array())
	for i: int in placed.size():
		for j: int in range(i + 1, placed.size()):
			var a: Dictionary = placed[i]
			var b: Dictionary = placed[j]
			var a_mounted: bool = a["placement"] == DressingLayout.Placement.WALL_MOUNT
			var b_mounted: bool = b["placement"] == DressingLayout.Placement.WALL_MOUNT
			if a_mounted != b_mounted:
				continue
			var distance: float = (a["position"] as Vector2).distance_to(b["position"])
			assert_true(distance >= float(a["radius"]) + float(b["radius"]), "%s and %s overlap" % [a["kind"], b["kind"]])


func test_band_props_hug_the_walls() -> void:
	for entry: Dictionary in _plan(5, PackedVector3Array()):
		if entry["placement"] != DressingLayout.Placement.WALL_BAND:
			continue
		var radius: float = entry["radius"]
		var inset: float = DressingLayout.inset_from(INTERIOR, entry["side"], entry["position"])
		assert_true(inset >= BAND_MIN + radius - 0.001, "%s too close to its wall (%f)" % [entry["kind"], inset])
		assert_true(inset <= maxf(BAND_MIN + radius, BAND_MAX) + 0.001, "%s strays into the room (%f)" % [entry["kind"], inset])


func test_band_props_face_into_the_room() -> void:
	for entry: Dictionary in _plan(5, PackedVector3Array()):
		if entry["placement"] != DressingLayout.Placement.WALL_BAND:
			continue
		var facing: Vector2 = Vector2(sin(entry["yaw"]), cos(entry["yaw"]))
		var to_center: Vector2 = (INTERIOR.get_center() - (entry["position"] as Vector2)).normalized()
		assert_true(facing.dot(to_center) > 0.0, "%s faces the wall" % entry["kind"])


func test_everything_stays_inside_the_room() -> void:
	for entry: Dictionary in _plan(9, PackedVector3Array()):
		var position: Vector2 = entry["position"]
		var radius: float = 0.0 if entry["placement"] == DressingLayout.Placement.WALL_MOUNT else entry["radius"]
		assert_true(position.x - radius >= INTERIOR.position.x - 0.001 and position.x + radius <= INTERIOR.end.x + 0.001, "%s outside in X" % entry["kind"])
		assert_true(position.y - radius >= INTERIOR.position.y - 0.001 and position.y + radius <= INTERIOR.end.y + 0.001, "%s outside in Z" % entry["kind"])


func test_exclusion_zones_stay_clear() -> void:
	# A door lane on the west wall and a terminal in the middle of the north wall.
	var exclusions: PackedVector3Array = PackedVector3Array([Vector3(0.0, 0.0, 3.4), Vector3(12.0, -9.0, 2.8)])
	for entry: Dictionary in _plan(11, exclusions, 0.5):
		var position: Vector2 = entry["position"]
		for zone: Vector3 in exclusions:
			var distance: float = position.distance_to(Vector2(zone.x, zone.y))
			assert_true(distance >= float(entry["radius"]) + zone.z - 0.001, "%s inside an exclusion zone" % entry["kind"])


func test_floor_scatter_never_collides() -> void:
	for entry: Dictionary in _plan(13, PackedVector3Array()):
		if entry["placement"] == DressingLayout.Placement.FLOOR:
			assert_false(entry["collides"], "floor scatter must not block movement")
			assert_eq(entry["side"], -1, "floor scatter has no wall")


func test_wall_point_and_inset_round_trip() -> void:
	for side: int in [DressingLayout.Side.NORTH, DressingLayout.Side.SOUTH, DressingLayout.Side.WEST, DressingLayout.Side.EAST]:
		var point: Vector2 = DressingLayout.wall_point(INTERIOR, side, 3.0, 1.25)
		assert_almost(DressingLayout.inset_from(INTERIOR, side, point), 1.25, "inset for side %d" % side)


func test_facing_yaw_points_away_from_each_wall() -> void:
	assert_almost(DressingLayout.facing_yaw(DressingLayout.Side.NORTH), 0.0, "north faces +Z")
	assert_almost(DressingLayout.facing_yaw(DressingLayout.Side.SOUTH), PI, "south faces -Z")
	assert_almost(DressingLayout.facing_yaw(DressingLayout.Side.WEST), PI * 0.5, "west faces +X")
	assert_almost(DressingLayout.facing_yaw(DressingLayout.Side.EAST), -PI * 0.5, "east faces -X")


func test_floor_decals_fit_inside_the_room() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 21
	var decals: Array[Dictionary] = DressingLayout.plan_floor_decals(INTERIOR, 30, 1.4, 3.8, rng)
	assert_eq(decals.size(), 30, "every floor decal planned")
	for decal: Dictionary in decals:
		var half: float = float(decal["size"]) * 0.5
		var position: Vector2 = decal["position"]
		assert_true(INTERIOR.grow(0.001).has_point(position + Vector2(half, half)) and INTERIOR.grow(0.001).has_point(position - Vector2(half, half)), "floor decal spills outside")


func test_wall_decals_avoid_exclusions() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 22
	var exclusions: PackedVector3Array = PackedVector3Array([Vector3(0.0, 0.0, 3.4)])
	for decal: Dictionary in DressingLayout.plan_wall_decals(INTERIOR, 20, exclusions, rng):
		var point: Vector2 = DressingLayout.wall_point(INTERIOR, decal["side"], decal["along"], 0.0)
		assert_true(point.distance_to(Vector2.ZERO) >= 3.4 + float(decal["width"]) * 0.5 - 0.001, "wall streak across a door")
