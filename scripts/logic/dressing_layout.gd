class_name DressingLayout
extends RefCounted
## Pure placement planner for room clutter. Works in the room's floor plane (Vector2 = world X, Z).
## Large props hug the walls so the middle of each room and the door lanes stay open for combat
## and pathfinding; small scatter can go anywhere; wall fixtures sit on the wall surface.

enum Placement { WALL_BAND, WALL_MOUNT, FLOOR }
## NORTH is the wall at the room's minimum Z, SOUTH at maximum Z, WEST at minimum X, EAST at maximum X.
enum Side { NORTH, SOUTH, WEST, EAST }

const ATTEMPTS_PER_PROP: int = 40
const SPACING: float = 0.15
const MOUNT_INSET: float = 0.05
const FLOOR_MARGIN: float = 0.3
const YAW_JITTER: float = 0.15
## Fractions of clutter_density used for wall fixtures (per metre) and floor scatter (per m²).
const MOUNT_FACTOR: float = 0.7
const FLOOR_FACTOR: float = 0.45
const FLOOR_DECAL_FACTOR: float = 0.05
const WALL_DECAL_FACTOR: float = 0.12


## How many props of each placement a room of this size gets.
static func counts_for(interior: Rect2, clutter_density: float) -> Dictionary:
	assert(clutter_density >= 0.0, "DressingLayout.counts_for: density must be >= 0")
	var perimeter: float = 2.0 * (interior.size.x + interior.size.y)
	var area: float = interior.size.x * interior.size.y
	return {
		Placement.WALL_BAND: roundi(perimeter * clutter_density),
		Placement.WALL_MOUNT: roundi(perimeter * clutter_density * MOUNT_FACTOR),
		Placement.FLOOR: roundi(area * clutter_density * FLOOR_FACTOR),
	}


## How many floor and wall grime decals a room of this size gets.
static func decal_counts_for(interior: Rect2, grime_density: float) -> Vector2i:
	assert(grime_density >= 0.0, "DressingLayout.decal_counts_for: density must be >= 0")
	var perimeter: float = 2.0 * (interior.size.x + interior.size.y)
	var area: float = interior.size.x * interior.size.y
	return Vector2i(roundi(area * grime_density * FLOOR_DECAL_FACTOR), roundi(perimeter * grime_density * WALL_DECAL_FACTOR))


## Plans the room's props.
## catalog entries: { "kind": StringName, "radius": float, "weight": float, "placement": Placement, "collides": bool }
## exclusions: (x, z, radius) circles nothing may enter (doors, interactables, hazards, spawns, pillars).
## Returns entries: { kind, placement, position: Vector2, yaw, radius, collides, side (-1 for floor), inset }.
static func plan(interior: Rect2, band_min: float, band_max: float, exclusions: PackedVector3Array, catalog: Array[Dictionary], counts: Dictionary, rng: RandomNumberGenerator) -> Array[Dictionary]:
	assert(band_min >= 0.0 and band_max >= band_min, "DressingLayout.plan: invalid wall band")
	var placed: Array[Dictionary] = []
	for placement: int in [Placement.WALL_BAND, Placement.WALL_MOUNT, Placement.FLOOR]:
		var options: Array[Dictionary] = Array(catalog.filter(func(spec: Dictionary) -> bool: return spec["placement"] == placement), TYPE_DICTIONARY, &"", null)
		var count: int = counts.get(placement, 0)
		if options.is_empty() or count <= 0:
			continue
		for i: int in count:
			var spec: Dictionary = _pick_weighted(options, rng)
			for attempt: int in ATTEMPTS_PER_PROP:
				var candidate: Dictionary = _propose(spec, interior, band_min, band_max, rng)
				if candidate.is_empty():
					break
				if _is_clear(candidate, placed, exclusions):
					placed.append(candidate)
					break
	return placed


## Plans floor grime decals: { position: Vector2, size: float, yaw: float }.
static func plan_floor_decals(interior: Rect2, count: int, min_size: float, max_size: float, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var decals: Array[Dictionary] = []
	for i: int in count:
		var size: float = rng.randf_range(min_size, max_size)
		var half: float = minf(size * 0.5, minf(interior.size.x, interior.size.y) * 0.5)
		var position: Vector2 = Vector2(
			rng.randf_range(interior.position.x + half, interior.end.x - half),
			rng.randf_range(interior.position.y + half, interior.end.y - half))
		decals.append({"position": position, "size": size, "yaw": rng.randf_range(0.0, TAU)})
	return decals


## Plans wall streak decals: { side: Side, along: float (metres from the side's start), width: float }.
static func plan_wall_decals(interior: Rect2, count: int, exclusions: PackedVector3Array, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var decals: Array[Dictionary] = []
	for i: int in count:
		for attempt: int in ATTEMPTS_PER_PROP:
			var side: int = _pick_side(interior, rng)
			var length: float = side_length(interior, side)
			var width: float = rng.randf_range(0.6, 1.6)
			if length < width:
				break
			var along: float = rng.randf_range(width * 0.5, length - width * 0.5)
			var point: Vector2 = wall_point(interior, side, along, 0.0)
			if _clear_of_exclusions(point, width * 0.5, exclusions):
				decals.append({"side": side, "along": along, "width": width})
				break
	return decals


static func side_length(interior: Rect2, side: int) -> float:
	return interior.size.x if side == Side.NORTH or side == Side.SOUTH else interior.size.y


## Point `along` metres down a wall and `inset` metres in from its surface.
static func wall_point(interior: Rect2, side: int, along: float, inset: float) -> Vector2:
	match side:
		Side.NORTH:
			return Vector2(interior.position.x + along, interior.position.y + inset)
		Side.SOUTH:
			return Vector2(interior.position.x + along, interior.end.y - inset)
		Side.WEST:
			return Vector2(interior.position.x + inset, interior.position.y + along)
		_:
			return Vector2(interior.end.x - inset, interior.position.y + along)


## Yaw that turns a prop's local +Z toward the room from this wall.
static func facing_yaw(side: int) -> float:
	match side:
		Side.NORTH:
			return 0.0
		Side.SOUTH:
			return PI
		Side.WEST:
			return PI * 0.5
		_:
			return -PI * 0.5


## Distance from a point to the given wall's interior surface.
static func inset_from(interior: Rect2, side: int, point: Vector2) -> float:
	match side:
		Side.NORTH:
			return point.y - interior.position.y
		Side.SOUTH:
			return interior.end.y - point.y
		Side.WEST:
			return point.x - interior.position.x
		_:
			return interior.end.x - point.x


static func _pick_weighted(options: Array[Dictionary], rng: RandomNumberGenerator) -> Dictionary:
	var total: float = 0.0
	for spec: Dictionary in options:
		total += float(spec["weight"])
	assert(total > 0.0, "DressingLayout: catalog weights must be positive")
	var roll: float = rng.randf() * total
	for spec: Dictionary in options:
		roll -= float(spec["weight"])
		if roll <= 0.0:
			return spec
	return options.back()


static func _pick_side(interior: Rect2, rng: RandomNumberGenerator) -> int:
	var roll: float = rng.randf() * (interior.size.x + interior.size.y) * 2.0
	if roll < interior.size.x:
		return Side.NORTH
	roll -= interior.size.x
	if roll < interior.size.x:
		return Side.SOUTH
	roll -= interior.size.x
	return Side.WEST if roll < interior.size.y else Side.EAST


static func _propose(spec: Dictionary, interior: Rect2, band_min: float, band_max: float, rng: RandomNumberGenerator) -> Dictionary:
	var radius: float = spec["radius"]
	var placement: int = spec["placement"]
	var candidate: Dictionary = {
		"kind": spec["kind"],
		"placement": placement,
		"radius": radius,
		"collides": spec["collides"],
	}
	if placement == Placement.FLOOR:
		var margin: float = radius + FLOOR_MARGIN
		if interior.size.x < margin * 2.0 or interior.size.y < margin * 2.0:
			return {}
		candidate["position"] = Vector2(
			rng.randf_range(interior.position.x + margin, interior.end.x - margin),
			rng.randf_range(interior.position.y + margin, interior.end.y - margin))
		candidate["yaw"] = rng.randf_range(0.0, TAU)
		candidate["side"] = -1
		candidate["inset"] = 0.0
		return candidate
	var side: int = _pick_side(interior, rng)
	var length: float = side_length(interior, side)
	var inset: float = MOUNT_INSET
	var end_margin: float = radius + FLOOR_MARGIN
	if placement == Placement.WALL_BAND:
		var inset_min: float = band_min + radius
		inset = rng.randf_range(inset_min, maxf(inset_min, band_max))
		end_margin = radius + band_min
	if length < end_margin * 2.0:
		return {}
	var along: float = rng.randf_range(end_margin, length - end_margin)
	candidate["position"] = wall_point(interior, side, along, inset)
	var jitter: float = rng.randf_range(-YAW_JITTER, YAW_JITTER) if placement == Placement.WALL_BAND else 0.0
	candidate["yaw"] = facing_yaw(side) + jitter
	candidate["side"] = side
	candidate["inset"] = inset
	return candidate


static func _is_clear(candidate: Dictionary, placed: Array[Dictionary], exclusions: PackedVector3Array) -> bool:
	var position: Vector2 = candidate["position"]
	var radius: float = candidate["radius"]
	if not _clear_of_exclusions(position, radius, exclusions):
		return false
	var mounted: bool = candidate["placement"] == Placement.WALL_MOUNT
	for other: Dictionary in placed:
		# Wall fixtures hang above floor props, so only fixtures crowd other fixtures.
		var other_mounted: bool = other["placement"] == Placement.WALL_MOUNT
		if mounted != other_mounted:
			continue
		var min_distance: float = radius + float(other["radius"]) + SPACING
		if position.distance_to(other["position"] as Vector2) < min_distance:
			return false
	return true


static func _clear_of_exclusions(position: Vector2, radius: float, exclusions: PackedVector3Array) -> bool:
	for zone: Vector3 in exclusions:
		if position.distance_to(Vector2(zone.x, zone.y)) < radius + zone.z:
			return false
	return true
