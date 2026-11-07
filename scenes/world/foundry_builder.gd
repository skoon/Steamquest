class_name FoundryBuilder
extends NavigationRegion3D
## Builds the foundry's floors, walls, pillars, lights and room triggers from RoomDef resources,
## then bakes the navigation mesh. Rooms run west-to-east along +X, centred on Z = 0, and each
## shared wall gets a door gap at Z = 0 (the SteamDoor scenes sit in those gaps).
## Walls between the camera and the Technician are cut down so the interior stays visible.

@export var rooms: Array[RoomDef] = []
@export var start_x: float = -9.0
@export var wall_height: float = 3.6
@export var wall_thickness: float = 0.6
@export var door_gap: float = 4.0
@export var door_height: float = 3.2
@export var cutaway_height: float = 0.5
@export var cutaway_speed: float = 10.0
@export var player_path: NodePath
@export_group("Dressing")
## Containers whose children (doors, interactables, hazards, props, enemy spawns) keep clutter away.
@export var keep_clear_roots: Array[NodePath] = []
@export var keep_clear_radius: float = 2.2
## Added to a node's own `radius` (cogs, vats) when it has one.
@export var keep_clear_padding: float = 1.4
@export var door_clear_radius: float = 3.4
@export var pillar_clear_radius: float = 1.4
## Large props sit between these distances from the wall.
@export var dressing_band_min: float = 0.6
@export var dressing_band_max: float = 2.2
@export var floor_decal_min_size: float = 1.4
@export var floor_decal_max_size: float = 3.8
@export var wall_decal_height: float = 2.6

## Each entry: { "mesh": MeshInstance3D, "axis": int (0 = runs along X, 2 = runs along Z), "coord": float }
var _walls: Array[Dictionary] = []
## Wall fixtures hidden with their wall: { "node": Node3D, "axis": int, "coord": float }
var _wall_attachments: Array[Dictionary] = []
const RAILING_HEIGHT: float = 1.1

var _player: Node3D
var _player_start: Vector3 = Vector3.ZERO
## Room name -> number of props placed (props + scatter + fixtures).
var dressed_prop_counts: Dictionary = {}


func build() -> void:
	assert(not rooms.is_empty(), "FoundryBuilder: no rooms configured")
	_player = get_node_or_null(player_path) as Node3D
	assert(_player != null, "FoundryBuilder: player_path must point to the Technician")
	_player_start = _player.global_position
	var keep_clear: PackedVector3Array = _keep_clear_zones()
	var x: float = start_x
	var previous_depth: float = 0.0
	for i: int in rooms.size():
		var room: RoomDef = rooms[i]
		var center_x: float = x + room.width * 0.5
		var wall_material: StandardMaterial3D = FoundryMaterials.textured(room.wall_texture, Color(0.85, 0.8, 0.75), Vector3(0.5, 0.5, 0.5))
		wall_material.uv1_triplanar = true
		wall_material.uv1_world_triplanar = true
		_build_floor(room, center_x)
		_build_light(room, center_x)
		_build_room_trigger(room, center_x)
		_build_pillars(room, center_x)
		_build_dressing(room, x, keep_clear)
		var span: float = room.width + wall_thickness
		if room.open_air:
			_build_railing(room, x, -1)
			_build_railing(room, x, 1)
		else:
			_build_pipes(room, center_x)
			_build_wall_along_x(center_x, -room.depth * 0.5, span, wall_material)
			_build_wall_along_x(center_x, room.depth * 0.5, span, wall_material)
		_build_wall_along_z(x, maxf(previous_depth, room.depth), i > 0, wall_material)
		x += room.width
		previous_depth = room.depth
	var last_material: StandardMaterial3D = FoundryMaterials.textured(rooms.back().wall_texture, Color(0.85, 0.8, 0.75), Vector3(0.5, 0.5, 0.5))
	last_material.uv1_triplanar = true
	last_material.uv1_world_triplanar = true
	_build_wall_along_z(x, previous_depth, false, last_material)
	_build_scorch_marks()
	_bake_navigation()


## Safe spot just inside the named room's entrance door (the level start for the first room).
func room_entrance(room_name: String) -> Vector3:
	var x: float = start_x
	for i: int in rooms.size():
		if rooms[i].room_name == room_name:
			return _player_start if i == 0 else Vector3(x + 1.6, 0.3, 0.0)
		x += rooms[i].width
	return _player_start


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	var toward_camera: Vector3 = camera.global_basis.z
	var weight: float = 1.0 - exp(-cutaway_speed * delta)
	for attachment: Dictionary in _wall_attachments:
		var node: Node3D = attachment["node"]
		node.visible = not _is_between(attachment["axis"], attachment["coord"], toward_camera)
	for wall: Dictionary in _walls:
		var mesh: MeshInstance3D = wall["mesh"]
		var between: bool = _is_between(wall["axis"], wall["coord"], toward_camera)
		if wall.has("lintel"):
			mesh.visible = not between
			continue
		var target_scale: float = cutaway_height / wall_height if between else 1.0
		mesh.scale.y = lerpf(mesh.scale.y, target_scale, weight)
		mesh.position.y = wall_height * mesh.scale.y * 0.5


## True when the wall at `coord` on `axis` sits between the camera and the Technician.
func _is_between(axis: int, coord: float, toward_camera: Vector3) -> bool:
	var player_coord: float = _player.global_position.z if axis == 0 else _player.global_position.x
	var camera_component: float = toward_camera.z if axis == 0 else toward_camera.x
	return (coord - player_coord) * signf(camera_component) > 0.4


func _bake_navigation() -> void:
	var nav_mesh: NavigationMesh = NavigationMesh.new()
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav_mesh.geometry_collision_mask = Layers.ENVIRONMENT
	nav_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	nav_mesh.geometry_source_group_name = Layers.NAV_GEOMETRY_GROUP
	nav_mesh.cell_size = 0.25
	nav_mesh.cell_height = 0.25
	# Multiples of cell_size / cell_height so the baker doesn't round them.
	nav_mesh.agent_radius = 0.5
	nav_mesh.agent_height = 1.75
	nav_mesh.agent_max_climb = 0.25
	navigation_mesh = nav_mesh
	bake_navigation_mesh(false)


func _build_floor(room: RoomDef, center_x: float) -> void:
	var size: Vector3 = Vector3(room.width, 0.5, room.depth)
	var body: StaticBody3D = Layers.add_static_box(self, size, Vector3(center_x, -0.25, 0.0))
	body.name = "%sFloor" % room.room_name.replace(" ", "")
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	var material: StandardMaterial3D = FoundryMaterials.textured(room.floor_texture, room.floor_tint, Vector3(0.4, 0.4, 0.4))
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	Layers.add_mesh(body, mesh, material, Vector3(center_x, -0.25, 0.0))


func _build_light(room: RoomDef, center_x: float) -> void:
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = room.light_color
	light.light_energy = room.light_energy
	light.omni_range = maxf(room.width, room.depth) * 0.85
	light.omni_attenuation = 0.8
	light.position = Vector3(center_x, 6.0, 0.0)
	add_child(light)


func _build_room_trigger(room: RoomDef, center_x: float) -> void:
	var area: Area3D = Area3D.new()
	area.collision_layer = 0
	area.collision_mask = Layers.PLAYER
	area.monitorable = false
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(room.width - 1.0, 3.0, room.depth - 1.0)
	shape_node.shape = box
	shape_node.position = Vector3(center_x, 1.5, 0.0)
	area.add_child(shape_node)
	add_child(area)
	var room_name: String = room.room_name
	area.body_entered.connect(func(body: Node3D) -> void:
		if body is Technician:
			GameState.enter_room(room_name)
	)


func _build_pillars(room: RoomDef, center_x: float) -> void:
	var iron: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.CAST_IRON)
	var brass: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.BRASS)
	var column: CylinderMesh = CylinderMesh.new()
	column.top_radius = 0.4
	column.bottom_radius = 0.5
	column.height = wall_height
	var collar: TorusMesh = TorusMesh.new()
	collar.inner_radius = 0.38
	collar.outer_radius = 0.56
	for local: Vector2 in room.pillars:
		var base: Vector3 = Vector3(center_x + local.x, 0.0, local.y)
		var body: StaticBody3D = Layers.add_static_cylinder(self, 0.5, wall_height, base)
		Layers.add_mesh(body, column, iron, base + Vector3(0.0, wall_height * 0.5, 0.0))
		Layers.add_mesh(body, collar, brass, base + Vector3(0.0, 0.3, 0.0))
		Layers.add_mesh(body, collar, brass, base + Vector3(0.0, wall_height - 0.4, 0.0))


func _build_pipes(room: RoomDef, center_x: float) -> void:
	var copper: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.COPPER_OXIDIZED)
	var brass: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.BRASS)
	var run: CylinderMesh = CylinderMesh.new()
	run.top_radius = 0.16
	run.bottom_radius = 0.16
	run.height = room.width - 1.0
	var z: float = -room.depth * 0.5 + wall_thickness * 0.5 + 0.25
	var pipe: MeshInstance3D = Layers.add_mesh(self, run, copper, Vector3(center_x, 2.8, z))
	pipe.rotation = Vector3(0.0, 0.0, PI * 0.5)
	var drop: CylinderMesh = CylinderMesh.new()
	drop.top_radius = 0.12
	drop.bottom_radius = 0.12
	drop.height = 2.8
	var flange: CylinderMesh = CylinderMesh.new()
	flange.top_radius = 0.22
	flange.bottom_radius = 0.22
	flange.height = 0.1
	var count: int = maxi(int(room.width / 6.0), 1)
	for i: int in count:
		var px: float = center_x - room.width * 0.5 + (float(i) + 0.5) * room.width / float(count)
		Layers.add_mesh(self, drop, copper, Vector3(px, 1.4, z))
		Layers.add_mesh(self, flange, brass, Vector3(px, 2.0, z))


func _build_wall_along_x(center_x: float, z: float, length: float, material: StandardMaterial3D) -> void:
	_add_wall_segment(Vector3(center_x, 0.0, z), Vector3(length, wall_height, wall_thickness), material, 0, z)


func _build_wall_along_z(x: float, length: float, with_gap: bool, material: StandardMaterial3D) -> void:
	if not with_gap:
		_add_wall_segment(Vector3(x, 0.0, 0.0), Vector3(wall_thickness, wall_height, length + wall_thickness), material, 2, x)
		return
	var half: float = (length + wall_thickness) * 0.5
	var gap_half: float = door_gap * 0.5
	var segment: float = half - gap_half
	_add_wall_segment(Vector3(x, 0.0, -gap_half - segment * 0.5), Vector3(wall_thickness, wall_height, segment), material, 2, x)
	_add_wall_segment(Vector3(x, 0.0, gap_half + segment * 0.5), Vector3(wall_thickness, wall_height, segment), material, 2, x)
	var lintel: MeshInstance3D = MeshInstance3D.new()
	var lintel_mesh: BoxMesh = BoxMesh.new()
	lintel_mesh.size = Vector3(wall_thickness, wall_height - door_height, door_gap)
	lintel.mesh = lintel_mesh
	lintel.material_override = material
	lintel.position = Vector3(x, door_height + (wall_height - door_height) * 0.5, 0.0)
	add_child(lintel)
	_walls.append({"mesh": lintel, "axis": 2, "coord": x, "lintel": true})


## A waist-high iron railing along one long edge of an open-air room, broken by its railing gaps.
func _build_railing(room: RoomDef, room_x: float, side: int) -> void:
	var z: float = float(side) * room.depth * 0.5
	var iron: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.CAST_IRON)
	var brass: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.BRASS)
	for span: Vector2 in RailingLayout.solid_spans(room.width, side, room.railing_gaps):
		var length: float = span.y - span.x
		var center: Vector3 = Vector3(room_x + (span.x + span.y) * 0.5, 0.0, z)
		var body: StaticBody3D = Layers.add_static_box(self, Vector3(length, RAILING_HEIGHT, 0.2), center + Vector3(0.0, RAILING_HEIGHT * 0.5, 0.0))
		var rail: BoxMesh = BoxMesh.new()
		rail.size = Vector3(length, 0.08, 0.1)
		Layers.add_mesh(body, rail, brass, center + Vector3(0.0, RAILING_HEIGHT, 0.0))
		Layers.add_mesh(body, rail, iron, center + Vector3(0.0, RAILING_HEIGHT * 0.5, 0.0))
		var post: BoxMesh = BoxMesh.new()
		post.size = Vector3(0.1, RAILING_HEIGHT, 0.1)
		var posts: int = maxi(int(length / 1.5), 1)
		for i: int in posts + 1:
			var px: float = center.x - length * 0.5 + length * float(i) / float(posts)
			Layers.add_mesh(body, post, iron, Vector3(px, RAILING_HEIGHT * 0.5, z))


## Adds one wall block. `base` is the bottom-centre; the visual is a child so it can be cut away.
func _add_wall_segment(base: Vector3, size: Vector3, material: StandardMaterial3D, axis: int, coord: float) -> void:
	var body: StaticBody3D = Layers.add_static_box(self, size, Vector3(base.x, size.y * 0.5, base.z))
	var holder: Node3D = Node3D.new()
	holder.position = Vector3(base.x, 0.0, base.z)
	body.add_child(holder)
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	var instance: MeshInstance3D = Layers.add_mesh(holder, mesh, material, Vector3(0.0, size.y * 0.5, 0.0))
	_walls.append({"mesh": instance, "axis": axis, "coord": coord})


# --- Dressing -----------------------------------------------------------------------

## (x, z, radius) circles that clutter must avoid: placed scene objects, the player start and door lanes.
func _keep_clear_zones() -> PackedVector3Array:
	var zones: PackedVector3Array = PackedVector3Array()
	for path: NodePath in keep_clear_roots:
		var root: Node = get_node(path)
		for child: Node in root.get_children():
			var spot: Node3D = child as Node3D
			if spot == null:
				continue
			if spot.has_method("keep_clear_zones"):
				zones.append_array(spot.call("keep_clear_zones") as PackedVector3Array)
				continue
			var radius: float = keep_clear_radius
			var own_radius: Variant = spot.get("radius")
			if own_radius is float:
				radius = maxf(radius, float(own_radius) + keep_clear_padding)
			zones.append(Vector3(spot.global_position.x, spot.global_position.z, radius))
	zones.append(Vector3(_player.global_position.x, _player.global_position.z, keep_clear_radius))
	var x: float = start_x
	for i: int in rooms.size():
		if i > 0:
			zones.append(Vector3(x, 0.0, door_clear_radius))
		x += rooms[i].width
	return zones


func _build_dressing(room: RoomDef, room_x: float, keep_clear: PackedVector3Array) -> void:
	var interior: Rect2 = Rect2(room_x + wall_thickness * 0.5, -room.depth * 0.5 + wall_thickness * 0.5, room.width - wall_thickness, room.depth - wall_thickness)
	var center_x: float = room_x + room.width * 0.5
	var exclusions: PackedVector3Array = keep_clear.duplicate()
	for pillar: Vector2 in room.pillars:
		exclusions.append(Vector3(center_x + pillar.x, pillar.y, pillar_clear_radius))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = room.dressing_seed
	var holder: Node3D = Node3D.new()
	holder.name = "%sDressing" % room.room_name.replace(" ", "")
	add_child(holder)
	var catalog: Array[Dictionary] = FoundryProps.catalog(room.dressing_theme)
	if room.open_air:
		catalog = Array(catalog.filter(func(entry: Dictionary) -> bool: return entry["placement"] != DressingLayout.Placement.WALL_MOUNT), TYPE_DICTIONARY, &"", null)
	var counts: Dictionary = DressingLayout.counts_for(interior, room.clutter_density)
	var placements: Array[Dictionary] = DressingLayout.plan(interior, dressing_band_min, dressing_band_max, exclusions, catalog, counts, rng)
	for entry: Dictionary in placements:
		var prop: Node3D = FoundryProps.build(entry["kind"], rng)
		var position_2d: Vector2 = entry["position"]
		prop.position = Vector3(position_2d.x, 0.0, position_2d.y)
		prop.rotation = Vector3(0.0, entry["yaw"], 0.0)
		holder.add_child(prop)
		if entry["placement"] == DressingLayout.Placement.WALL_MOUNT:
			_register_attachment(prop, room, room_x, entry["side"])
	dressed_prop_counts[room.room_name] = placements.size()
	_build_grime(room, room_x, interior, exclusions, holder, rng)


func _build_grime(room: RoomDef, room_x: float, interior: Rect2, exclusions: PackedVector3Array, holder: Node3D, rng: RandomNumberGenerator) -> void:
	var decal_counts: Vector2i = DressingLayout.decal_counts_for(interior, room.grime_density)
	var floor_kinds: Array[GrimeTextures.Kind] = FoundryProps.floor_grime(room.dressing_theme)
	for entry: Dictionary in DressingLayout.plan_floor_decals(interior, decal_counts.x, floor_decal_min_size, floor_decal_max_size, rng):
		var decal: Decal = FoundryProps.make_floor_decal(floor_kinds[rng.randi_range(0, floor_kinds.size() - 1)], entry["size"])
		var position_2d: Vector2 = entry["position"]
		decal.position = Vector3(position_2d.x, 0.0, position_2d.y)
		decal.rotation = Vector3(0.0, entry["yaw"], 0.0)
		holder.add_child(decal)
	if room.open_air:
		return
	var wall_kinds: Array[GrimeTextures.Kind] = FoundryProps.wall_grime(room.dressing_theme)
	for entry: Dictionary in DressingLayout.plan_wall_decals(interior, decal_counts.y, exclusions, rng):
		var side: int = entry["side"]
		var anchor: Node3D = Node3D.new()
		var point: Vector2 = DressingLayout.wall_point(interior, side, entry["along"], 0.0)
		anchor.position = Vector3(point.x, 0.0, point.y)
		anchor.rotation = Vector3(0.0, DressingLayout.facing_yaw(side), 0.0)
		holder.add_child(anchor)
		var height: float = rng.randf_range(wall_decal_height * 0.6, wall_decal_height)
		var decal: Decal = FoundryProps.make_wall_decal(wall_kinds[rng.randi_range(0, wall_kinds.size() - 1)], entry["width"], height)
		decal.position = Vector3(0.0, wall_height - height * 0.5 - 0.2, 0.0)
		anchor.add_child(decal)
		_register_attachment(anchor, room, room_x, side)


## Scorched floor around every furnace mouth and smelting vat.
func _build_scorch_marks() -> void:
	for path: NodePath in keep_clear_roots:
		for child: Node in get_node(path).get_children():
			var size: float = 0.0
			var center: Vector3 = Vector3.ZERO
			if child is Furnace:
				var furnace: Furnace = child as Furnace
				size = 3.4
				center = furnace.global_position + furnace.global_basis.z.normalized() * 1.6
			elif child is SmeltingVat:
				var vat: SmeltingVat = child as SmeltingVat
				size = vat.radius * 3.2
				center = vat.global_position
			if size <= 0.0:
				continue
			var decal: Decal = FoundryProps.make_floor_decal(GrimeTextures.Kind.SCORCH, size)
			decal.position = Vector3(center.x, 0.0, center.z)
			add_child(decal)


func _register_attachment(node: Node3D, room: RoomDef, room_x: float, side: int) -> void:
	match side:
		DressingLayout.Side.NORTH:
			_wall_attachments.append({"node": node, "axis": 0, "coord": -room.depth * 0.5})
		DressingLayout.Side.SOUTH:
			_wall_attachments.append({"node": node, "axis": 0, "coord": room.depth * 0.5})
		DressingLayout.Side.WEST:
			_wall_attachments.append({"node": node, "axis": 2, "coord": room_x})
		DressingLayout.Side.EAST:
			_wall_attachments.append({"node": node, "axis": 2, "coord": room_x + room.width})
		_:
			assert(false, "FoundryBuilder: wall fixture without a wall side")
