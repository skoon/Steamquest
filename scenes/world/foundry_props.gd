class_name FoundryProps
extends RefCounted
## Procedural clutter for dressing foundry rooms, built from primitive meshes.
## Every prop's local +Z faces into the room (its back is to the wall); Y is up.
## Props that block movement add their own Environment-layer colliders, which are part of the nav bake.

const P_BAND: int = DressingLayout.Placement.WALL_BAND
const P_MOUNT: int = DressingLayout.Placement.WALL_MOUNT
const P_FLOOR: int = DressingLayout.Placement.FLOOR

const SOFA_TEXTURE: Texture2D = preload("res://assets/sprites/decor/furniture_sofa.png")
const ARMCHAIR_TEXTURE: Texture2D = preload("res://assets/sprites/decor/furniture_armchair.png")
const CABINET_TEXTURE: Texture2D = preload("res://assets/sprites/decor/furniture_cabinet.png")
const BOOKCASE_TEXTURE: Texture2D = preload("res://assets/sprites/decor/furniture_bookcase.png")
const CLOCK_TEXTURE: Texture2D = preload("res://assets/sprites/decor/furniture_grandfather_clock.png")
const DESK_TEXTURE: Texture2D = preload("res://assets/sprites/decor/furniture_desk.png")

static var _mesh_cache: Dictionary = {}


# --- Catalogs -------------------------------------------------------------------

static func catalog(theme: RoomDef.DressingTheme) -> Array[Dictionary]:
	var shared_band: Array[Dictionary] = [
		_spec(&"barrel", 0.45, 1.0, P_BAND, true),
		_spec(&"crate", 0.65, 1.0, P_BAND, true),
		_spec(&"drum_cluster", 0.9, 0.8, P_BAND, true),
		_spec(&"scrap_heap", 0.8, 0.8, P_BAND, true),
	]
	var entries: Array[Dictionary] = []
	match theme:
		RoomDef.DressingTheme.BOILER:
			entries.append_array(shared_band)
			entries.append_array([
				_spec(&"boiler_horizontal", 1.4, 2.5, P_BAND, true),
				_spec(&"coal_pile", 0.9, 2.0, P_BAND, true),
				_spec(&"valve_manifold", 0.6, 1.5, P_BAND, true),
				_spec(&"gauge_panel", 0.55, 2.0, P_MOUNT, false),
				_spec(&"pipe_riser", 0.3, 2.0, P_MOUNT, false),
				_spec(&"pipe_run", 1.5, 2.5, P_MOUNT, false),
				_spec(&"hanging_chain", 0.25, 0.6, P_MOUNT, false),
				_spec(&"coal_lumps", 0.4, 3.0, P_FLOOR, false),
				_spec(&"bolts", 0.3, 1.5, P_FLOOR, false),
			])
		RoomDef.DressingTheme.CUTTING:
			entries.append_array(shared_band)
			entries.append_array([
				_spec(&"workbench", 1.0, 3.0, P_BAND, true),
				_spec(&"lathe", 1.0, 2.0, P_BAND, true),
				_spec(&"gear_crate", 0.65, 2.0, P_BAND, true),
				_spec(&"gear_stack", 0.6, 1.5, P_BAND, true),
				_spec(&"conveyor", 1.45, 1.0, P_BAND, true),
				_spec(&"tool_board", 0.65, 2.0, P_MOUNT, false),
				_spec(&"pipe_run", 1.5, 1.2, P_MOUNT, false),
				_spec(&"hanging_chain", 0.25, 1.5, P_MOUNT, false),
				_spec(&"gauge_panel", 0.55, 0.8, P_MOUNT, false),
				_spec(&"wall_cog_cluster", 0.7, 1.0, P_MOUNT, false),
				_spec(&"shavings", 0.4, 3.0, P_FLOOR, false),
				_spec(&"bolts", 0.3, 2.0, P_FLOOR, false),
				_spec(&"gear_blank", 0.3, 1.5, P_FLOOR, false),
			])
		RoomDef.DressingTheme.SMELTING:
			entries.append_array(shared_band)
			entries.append_array([
				_spec(&"ingot_stack", 0.6, 2.0, P_BAND, true),
				_spec(&"slag_pile", 0.85, 2.0, P_BAND, true),
				_spec(&"ore_cart", 1.35, 1.5, P_BAND, true),
				_spec(&"ladle_rack", 0.65, 1.2, P_BAND, true),
				_spec(&"pipe_riser", 0.3, 1.5, P_MOUNT, false),
				_spec(&"pipe_run", 1.5, 2.0, P_MOUNT, false),
				_spec(&"hanging_chain", 0.25, 1.5, P_MOUNT, false),
				_spec(&"gauge_panel", 0.55, 0.8, P_MOUNT, false),
				_spec(&"slag_bits", 0.4, 3.0, P_FLOOR, false),
				_spec(&"ingot_single", 0.35, 1.0, P_FLOOR, false),
				_spec(&"bolts", 0.3, 1.0, P_FLOOR, false),
			])
		RoomDef.DressingTheme.VAULT:
			entries.append_array([
				_spec(&"gear_stack", 0.6, 2.0, P_BAND, true),
				_spec(&"crate", 0.65, 1.0, P_BAND, true),
				_spec(&"clock_panel", 0.65, 2.0, P_MOUNT, false),
				_spec(&"brass_plaque", 0.75, 1.5, P_MOUNT, false),
				_spec(&"wall_cog_cluster", 0.7, 2.0, P_MOUNT, false),
				_spec(&"bolts", 0.3, 1.0, P_FLOOR, false),
				_spec(&"gear_blank", 0.3, 1.0, P_FLOOR, false),
			])
		RoomDef.DressingTheme.YARD:
			entries.append_array([
				_spec(&"crate", 0.65, 2.0, P_BAND, true),
				_spec(&"barrel", 0.45, 1.0, P_BAND, true),
				_spec(&"mail_sacks", 0.75, 2.0, P_BAND, true),
				_spec(&"hand_cart", 1.0, 1.0, P_BAND, true),
				_spec(&"pallet_stack", 0.75, 1.5, P_BAND, true),
				_spec(&"dispatch_desk", 0.9, 1.0, P_BAND, true),
				_spec(&"wall_lantern", 0.3, 2.0, P_MOUNT, false),
				_spec(&"notice_board", 0.65, 1.5, P_MOUNT, false),
				_spec(&"pipe_run", 1.5, 1.0, P_MOUNT, false),
				_spec(&"straw", 0.4, 2.0, P_FLOOR, false),
				_spec(&"letters", 0.35, 2.0, P_FLOOR, false),
			])
		RoomDef.DressingTheme.TRAM:
			entries.append_array([
				_spec(&"bench", 1.0, 2.5, P_BAND, true),
				_spec(&"ticket_booth", 0.85, 1.0, P_BAND, true),
				_spec(&"luggage_pile", 0.7, 1.5, P_BAND, true),
				_spec(&"crate", 0.65, 1.0, P_BAND, true),
				_spec(&"barrel", 0.45, 0.8, P_BAND, true),
				_spec(&"signal_lamp", 0.3, 2.0, P_MOUNT, false),
				_spec(&"timetable_board", 0.7, 1.5, P_MOUNT, false),
				_spec(&"pipe_run", 1.5, 2.0, P_MOUNT, false),
				_spec(&"gauge_panel", 0.55, 0.8, P_MOUNT, false),
				_spec(&"tickets", 0.35, 2.0, P_FLOOR, false),
				_spec(&"bolts", 0.3, 1.5, P_FLOOR, false),
			])
		RoomDef.DressingTheme.SHOWROOM:
			entries.append_array([
				_spec(&"display_case", 0.75, 3.0, P_BAND, true),
				_spec(&"clock_pedestal", 0.45, 2.0, P_BAND, true),
				_spec(&"sofa", 0.95, 1.0, P_BAND, true),
				_spec(&"armchair", 0.6, 1.2, P_BAND, true),
				_spec(&"cabinet", 0.6, 1.2, P_BAND, true),
				_spec(&"bookcase", 0.65, 1.0, P_BAND, true),
				_spec(&"grandfather_clock", 0.5, 1.5, P_BAND, true),
				_spec(&"clock_panel", 0.65, 2.0, P_MOUNT, false),
				_spec(&"placard", 0.6, 2.0, P_MOUNT, false),
				_spec(&"brass_plaque", 0.75, 1.0, P_MOUNT, false),
				_spec(&"glass_shards", 0.35, 2.0, P_FLOOR, false),
				_spec(&"gear_blank", 0.3, 1.5, P_FLOOR, false),
			])
		RoomDef.DressingTheme.CISTERN:
			entries.append_array([
				_spec(&"pump_engine", 1.1, 1.5, P_BAND, true),
				_spec(&"valve_manifold", 0.7, 1.5, P_BAND, true),
				_spec(&"barrel", 0.45, 1.0, P_BAND, true),
				_spec(&"bucket_pile", 0.55, 1.5, P_BAND, true),
				_spec(&"pipe_riser", 0.3, 1.5, P_MOUNT, false),
				_spec(&"hanging_chain", 0.3, 1.5, P_MOUNT, false),
				_spec(&"pipe_run", 1.5, 2.0, P_MOUNT, false),
				_spec(&"gauge_panel", 0.55, 1.0, P_MOUNT, false),
				_spec(&"bolts", 0.3, 1.5, P_FLOOR, false),
				_spec(&"puddle_stones", 0.4, 2.0, P_FLOOR, false),
			])
		RoomDef.DressingTheme.GARDEN:
			entries.append_array([
				_spec(&"planter", 0.9, 3.0, P_BAND, true),
				_spec(&"produce_crates", 0.75, 1.5, P_BAND, true),
				_spec(&"water_tank", 0.65, 1.0, P_BAND, true),
				_spec(&"barrel", 0.45, 0.8, P_BAND, true),
				_spec(&"trellis", 0.8, 2.0, P_MOUNT, false),
				_spec(&"pipe_run", 1.5, 1.5, P_MOUNT, false),
				_spec(&"gauge_panel", 0.55, 0.6, P_MOUNT, false),
				_spec(&"leaf_litter", 0.4, 2.5, P_FLOOR, false),
				_spec(&"straw", 0.4, 1.0, P_FLOOR, false),
			])
		RoomDef.DressingTheme.MINE:
			entries.append_array([
				_spec(&"coal_pile", 0.85, 2.5, P_BAND, true),
				_spec(&"slag_pile", 0.8, 1.0, P_BAND, true),
				_spec(&"ore_cart", 1.3, 1.0, P_BAND, true),
				_spec(&"pick_rack", 0.7, 1.5, P_BAND, true),
				_spec(&"crate", 0.65, 1.0, P_BAND, true),
				_spec(&"barrel", 0.45, 0.6, P_BAND, true),
				_spec(&"timber_prop", 0.6, 2.5, P_MOUNT, false),
				_spec(&"hanging_chain", 0.3, 1.0, P_MOUNT, false),
				_spec(&"coal_lumps", 0.3, 2.5, P_FLOOR, false),
				_spec(&"slag_bits", 0.3, 1.0, P_FLOOR, false),
			])
		RoomDef.DressingTheme.TOWER:
			entries.append_array([
				_spec(&"mooring_bollard", 0.5, 2.0, P_BAND, true),
				_spec(&"rope_coil", 0.55, 2.0, P_BAND, true),
				_spec(&"crate", 0.65, 1.5, P_BAND, true),
				_spec(&"mail_sacks", 0.7, 1.0, P_BAND, true),
				_spec(&"barrel", 0.45, 1.0, P_BAND, true),
				_spec(&"signal_lamp", 0.3, 2.0, P_MOUNT, false),
				_spec(&"gauge_panel", 0.55, 1.0, P_MOUNT, false),
				_spec(&"bolts", 0.3, 2.0, P_FLOOR, false),
				_spec(&"straw", 0.4, 1.0, P_FLOOR, false),
			])
		RoomDef.DressingTheme.ARCHIVE:
			entries.append_array([
				_spec(&"bookcase", 0.65, 3.0, P_BAND, true),
				_spec(&"cabinet", 0.6, 1.5, P_BAND, true),
				_spec(&"drafting_table", 0.8, 1.5, P_BAND, true),
				_spec(&"map_chest", 0.75, 1.5, P_BAND, true),
				_spec(&"dispatch_desk", 1.0, 1.0, P_BAND, true),
				_spec(&"armchair", 0.6, 0.6, P_BAND, true),
				_spec(&"clock_panel", 0.65, 1.0, P_MOUNT, false),
				_spec(&"placard", 0.6, 1.5, P_MOUNT, false),
				_spec(&"brass_plaque", 0.75, 1.0, P_MOUNT, false),
				_spec(&"letters", 0.35, 2.0, P_FLOOR, false),
				_spec(&"paper_drift", 0.4, 2.0, P_FLOOR, false),
			])
		RoomDef.DressingTheme.GENERATOR:
			entries.append_array([
				_spec(&"coil_cabinet", 0.7, 2.5, P_BAND, true),
				_spec(&"insulator_stack", 0.45, 2.0, P_BAND, true),
				_spec(&"valve_manifold", 0.7, 1.0, P_BAND, true),
				_spec(&"drum_cluster", 0.75, 1.0, P_BAND, true),
				_spec(&"cable_bundle", 1.2, 2.0, P_MOUNT, false),
				_spec(&"gauge_panel", 0.55, 1.5, P_MOUNT, false),
				_spec(&"pipe_run", 1.5, 1.0, P_MOUNT, false),
				_spec(&"bolts", 0.3, 2.0, P_FLOOR, false),
				_spec(&"shavings", 0.3, 1.0, P_FLOOR, false),
			])
	return entries


## Grime decal mix per theme: floor kinds and wall streak kinds.
static func floor_grime(theme: RoomDef.DressingTheme) -> Array[GrimeTextures.Kind]:
	match theme:
		RoomDef.DressingTheme.BOILER:
			return [GrimeTextures.Kind.SOOT, GrimeTextures.Kind.OIL, GrimeTextures.Kind.PUDDLE, GrimeTextures.Kind.PUDDLE]
		RoomDef.DressingTheme.CUTTING:
			return [GrimeTextures.Kind.OIL, GrimeTextures.Kind.OIL, GrimeTextures.Kind.SOOT]
		RoomDef.DressingTheme.SMELTING:
			return [GrimeTextures.Kind.SCORCH, GrimeTextures.Kind.SOOT, GrimeTextures.Kind.OIL]
		RoomDef.DressingTheme.YARD:
			return [GrimeTextures.Kind.PUDDLE, GrimeTextures.Kind.OIL, GrimeTextures.Kind.SOOT]
		RoomDef.DressingTheme.TRAM:
			return [GrimeTextures.Kind.OIL, GrimeTextures.Kind.SOOT, GrimeTextures.Kind.OIL]
		RoomDef.DressingTheme.SHOWROOM:
			return [GrimeTextures.Kind.SOOT]
		RoomDef.DressingTheme.CISTERN:
			return [GrimeTextures.Kind.PUDDLE, GrimeTextures.Kind.PUDDLE, GrimeTextures.Kind.OIL]
		RoomDef.DressingTheme.GARDEN:
			return [GrimeTextures.Kind.PUDDLE, GrimeTextures.Kind.SOOT]
		RoomDef.DressingTheme.MINE:
			return [GrimeTextures.Kind.SOOT, GrimeTextures.Kind.SOOT, GrimeTextures.Kind.SCORCH]
		RoomDef.DressingTheme.TOWER:
			return [GrimeTextures.Kind.PUDDLE, GrimeTextures.Kind.OIL]
		RoomDef.DressingTheme.ARCHIVE:
			return [GrimeTextures.Kind.SOOT]
		RoomDef.DressingTheme.GENERATOR:
			return [GrimeTextures.Kind.SCORCH, GrimeTextures.Kind.OIL, GrimeTextures.Kind.SOOT]
		_:
			return [GrimeTextures.Kind.OIL]


static func wall_grime(theme: RoomDef.DressingTheme) -> Array[GrimeTextures.Kind]:
	match theme:
		RoomDef.DressingTheme.SMELTING:
			return [GrimeTextures.Kind.SOOT_STREAK, GrimeTextures.Kind.SOOT_STREAK, GrimeTextures.Kind.RUST_STREAK]
		RoomDef.DressingTheme.VAULT:
			return [GrimeTextures.Kind.RUST_STREAK]
		RoomDef.DressingTheme.SHOWROOM:
			return [GrimeTextures.Kind.SOOT_STREAK]
		RoomDef.DressingTheme.CISTERN:
			return [GrimeTextures.Kind.RUST_STREAK, GrimeTextures.Kind.RUST_STREAK]
		RoomDef.DressingTheme.MINE:
			return [GrimeTextures.Kind.SOOT_STREAK]
		RoomDef.DressingTheme.ARCHIVE:
			return [GrimeTextures.Kind.SOOT_STREAK]
		RoomDef.DressingTheme.GENERATOR:
			return [GrimeTextures.Kind.SOOT_STREAK, GrimeTextures.Kind.RUST_STREAK]
		_:
			return [GrimeTextures.Kind.RUST_STREAK, GrimeTextures.Kind.SOOT_STREAK]


static func _spec(kind: StringName, radius: float, weight: float, placement: int, collides: bool) -> Dictionary:
	return {"kind": kind, "radius": radius, "weight": weight, "placement": placement, "collides": collides}


# --- Entry point ------------------------------------------------------------------

static func build(kind: StringName, rng: RandomNumberGenerator) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = String(kind).to_pascal_case()
	match kind:
		&"barrel": _barrel(root, rng, Vector3.ZERO, true)
		&"crate": _crate(root, rng)
		&"drum_cluster": _drum_cluster(root, rng)
		&"scrap_heap": _scrap_heap(root, rng)
		&"boiler_horizontal": _boiler(root, rng)
		&"coal_pile": _coal_pile(root, rng)
		&"valve_manifold": _valve_manifold(root, rng)
		&"gauge_panel": _gauge_panel(root, rng)
		&"pipe_riser": _pipe_riser(root, rng)
		&"pipe_run": _pipe_run(root, rng)
		&"hanging_chain": _hanging_chain(root, rng)
		&"workbench": _workbench(root, rng)
		&"lathe": _lathe(root, rng)
		&"gear_crate": _gear_crate(root, rng)
		&"gear_stack": _gear_stack(root, rng)
		&"conveyor": _conveyor(root, rng)
		&"tool_board": _tool_board(root, rng)
		&"wall_cog_cluster": _wall_cog_cluster(root, rng)
		&"ingot_stack": _ingot_stack(root, rng)
		&"slag_pile": _slag_pile(root, rng)
		&"ore_cart": _ore_cart(root, rng)
		&"ladle_rack": _ladle_rack(root, rng)
		&"clock_panel": _clock_panel(root, rng)
		&"brass_plaque": _brass_plaque(root, rng)
		&"coal_lumps": _coal_lumps(root, rng)
		&"bolts": _bolts(root, rng)
		&"shavings": _shavings(root, rng)
		&"gear_blank": _gear_blank(root, rng)
		&"slag_bits": _slag_bits(root, rng)
		&"ingot_single": _ingot_single(root, rng)
		&"mail_sacks": _mail_sacks(root, rng)
		&"hand_cart": _hand_cart(root, rng)
		&"pallet_stack": _pallet_stack(root, rng)
		&"dispatch_desk": _sprite_prop(root, DESK_TEXTURE, 0.008, 0.85, 1.0)
		&"wall_lantern": _wall_lantern(root, rng)
		&"notice_board": _notice_board(root, rng)
		&"straw": _straw(root, rng)
		&"letters": _letters(root, rng)
		&"bench": _bench(root, rng)
		&"ticket_booth": _ticket_booth(root, rng)
		&"luggage_pile": _luggage_pile(root, rng)
		&"signal_lamp": _signal_lamp(root, rng)
		&"timetable_board": _timetable_board(root, rng)
		&"tickets": _tickets(root, rng)
		&"display_case": _display_case(root, rng)
		&"clock_pedestal": _clock_pedestal(root, rng)
		&"sofa": _sprite_prop(root, SOFA_TEXTURE, 0.009, 0.9, 1.0)
		&"armchair": _sprite_prop(root, ARMCHAIR_TEXTURE, 0.007, 0.55, 1.0)
		&"cabinet": _sprite_prop(root, CABINET_TEXTURE, 0.008, 0.55, 1.6)
		&"bookcase": _sprite_prop(root, BOOKCASE_TEXTURE, 0.01, 0.6, 2.0)
		&"grandfather_clock": _sprite_prop(root, CLOCK_TEXTURE, 0.011, 0.45, 2.2)
		&"placard": _placard(root, rng)
		&"glass_shards": _glass_shards(root, rng)
		&"pump_engine": _pump_engine(root, rng)
		&"bucket_pile": _bucket_pile(root, rng)
		&"puddle_stones": _puddle_stones(root, rng)
		&"planter": _planter(root, rng)
		&"produce_crates": _produce_crates(root, rng)
		&"water_tank": _water_tank(root, rng)
		&"trellis": _trellis(root, rng)
		&"leaf_litter": _leaf_litter(root, rng)
		&"pick_rack": _pick_rack(root, rng)
		&"timber_prop": _timber_prop(root, rng)
		&"mooring_bollard": _mooring_bollard(root, rng)
		&"rope_coil": _rope_coil(root, rng)
		&"drafting_table": _drafting_table(root, rng)
		&"map_chest": _map_chest(root, rng)
		&"paper_drift": _paper_drift(root, rng)
		&"coil_cabinet": _coil_cabinet(root, rng)
		&"insulator_stack": _insulator_stack(root, rng)
		&"cable_bundle": _cable_bundle(root, rng)
		_:
			assert(false, "FoundryProps.build: unknown prop kind %s" % kind)
	return root


## Floor stain projected straight down.
static func make_floor_decal(kind: GrimeTextures.Kind, size: float) -> Decal:
	var decal: Decal = Decal.new()
	decal.size = Vector3(size, 0.8, size)
	decal.set_texture(Decal.TEXTURE_ALBEDO, GrimeTextures.get_texture(kind))
	decal.normal_fade = 0.5
	return decal


## Wall streak; the parent's local +Z must point out of the wall. Projects back into the wall (-Z).
static func make_wall_decal(kind: GrimeTextures.Kind, width: float, height: float) -> Decal:
	var decal: Decal = Decal.new()
	decal.size = Vector3(width, 0.5, height)
	decal.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	decal.set_texture(Decal.TEXTURE_ALBEDO, GrimeTextures.get_texture(kind))
	decal.normal_fade = 0.5
	return decal


# --- Primitive helpers ---------------------------------------------------------------

static func _m(kind: FoundryMaterials.Kind) -> StandardMaterial3D:
	return FoundryMaterials.get_material(kind)


static func _pick(rng: RandomNumberGenerator, kinds: Array[FoundryMaterials.Kind]) -> StandardMaterial3D:
	return _m(kinds[rng.randi_range(0, kinds.size() - 1)])


static func _box(parent: Node3D, size: Vector3, mat: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var key: String = "box%s" % size
	if not _mesh_cache.has(key):
		var box: BoxMesh = BoxMesh.new()
		box.size = size
		_mesh_cache[key] = box
	var instance: MeshInstance3D = Layers.add_mesh(parent, _mesh_cache[key] as Mesh, mat, pos)
	instance.rotation = rot
	return instance


static func _cyl(parent: Node3D, top: float, bottom: float, height: float, mat: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO, segments: int = 16) -> MeshInstance3D:
	var key: String = "cyl%f_%f_%f_%d" % [top, bottom, height, segments]
	if not _mesh_cache.has(key):
		var cylinder: CylinderMesh = CylinderMesh.new()
		cylinder.top_radius = top
		cylinder.bottom_radius = bottom
		cylinder.height = height
		cylinder.radial_segments = segments
		cylinder.rings = 1
		_mesh_cache[key] = cylinder
	var instance: MeshInstance3D = Layers.add_mesh(parent, _mesh_cache[key] as Mesh, mat, pos)
	instance.rotation = rot
	return instance


static func _sphere(parent: Node3D, radius: float, mat: Material, pos: Vector3, scale: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var key: String = "sph%f" % radius
	if not _mesh_cache.has(key):
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radius = radius
		sphere.height = radius * 2.0
		sphere.radial_segments = 12
		sphere.rings = 6
		_mesh_cache[key] = sphere
	var instance: MeshInstance3D = Layers.add_mesh(parent, _mesh_cache[key] as Mesh, mat, pos)
	instance.scale = scale
	return instance


static func _torus(parent: Node3D, inner: float, outer: float, mat: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var key: String = "tor%f_%f" % [inner, outer]
	if not _mesh_cache.has(key):
		var torus: TorusMesh = TorusMesh.new()
		torus.inner_radius = inner
		torus.outer_radius = outer
		torus.rings = 16
		torus.ring_segments = 8
		_mesh_cache[key] = torus
	var instance: MeshInstance3D = Layers.add_mesh(parent, _mesh_cache[key] as Mesh, mat, pos)
	instance.rotation = rot
	return instance


## Round gauge facing local +Z with a needle at a random reading.
static func _gauge(parent: Node3D, pos: Vector3, radius: float, rng: RandomNumberGenerator) -> void:
	_cyl(parent, radius, radius, 0.05, _m(FoundryMaterials.Kind.BRASS), pos, Vector3(PI * 0.5, 0.0, 0.0), 20)
	_cyl(parent, radius * 0.82, radius * 0.82, 0.01, _m(FoundryMaterials.Kind.GAUGE_FACE), pos + Vector3(0.0, 0.0, 0.026), Vector3(PI * 0.5, 0.0, 0.0), 20)
	var pivot: Node3D = Node3D.new()
	pivot.position = pos + Vector3(0.0, 0.0, 0.034)
	pivot.rotation = Vector3(0.0, 0.0, rng.randf_range(-2.2, 2.2))
	parent.add_child(pivot)
	_box(pivot, Vector3(0.012, radius * 0.75, 0.008), _m(FoundryMaterials.Kind.CAST_IRON), Vector3(0.0, radius * 0.3, 0.0))


static func _valve_wheel(parent: Node3D, pos: Vector3, radius: float, mat: Material) -> void:
	var facing: Vector3 = Vector3(PI * 0.5, 0.0, 0.0)
	_torus(parent, radius * 0.78, radius, mat, pos, facing)
	_box(parent, Vector3(radius * 1.7, 0.025, 0.025), mat, pos)
	_box(parent, Vector3(0.025, radius * 1.7, 0.025), mat, pos)
	_cyl(parent, 0.025, 0.025, 0.12, _m(FoundryMaterials.Kind.DARK_STEEL), pos + Vector3(0.0, 0.0, -0.06), facing, 8)


static func _crate_visual(parent: Node3D, size: Vector3, pos: Vector3, yaw: float) -> void:
	var holder: Node3D = Node3D.new()
	holder.position = pos
	holder.rotation = Vector3(0.0, yaw, 0.0)
	parent.add_child(holder)
	var wood: StandardMaterial3D = _m(FoundryMaterials.Kind.WOOD)
	var strap: StandardMaterial3D = _m(FoundryMaterials.Kind.DARK_STEEL)
	_box(holder, size, wood, Vector3(0.0, size.y * 0.5, 0.0))
	for y: float in [size.y * 0.2, size.y * 0.8]:
		_box(holder, Vector3(size.x + 0.02, 0.05, size.z + 0.02), strap, Vector3(0.0, y, 0.0))
	var brace_length: float = Vector2(size.x, size.y).length() * 0.9
	_box(holder, Vector3(brace_length, 0.07, 0.02), wood, Vector3(0.0, size.y * 0.5, size.z * 0.5 + 0.012), Vector3(0.0, 0.0, atan2(size.y, size.x)))


static func _barrel(parent: Node3D, rng: RandomNumberGenerator, offset: Vector3, with_collider: bool) -> void:
	var body: StandardMaterial3D = _pick(rng, [FoundryMaterials.Kind.RUST, FoundryMaterials.Kind.DARK_STEEL, FoundryMaterials.Kind.COPPER_OXIDIZED, FoundryMaterials.Kind.RUST])
	var iron: StandardMaterial3D = _m(FoundryMaterials.Kind.CAST_IRON)
	_cyl(parent, 0.38, 0.38, 1.0, body, offset + Vector3(0.0, 0.5, 0.0))
	_torus(parent, 0.37, 0.41, iron, offset + Vector3(0.0, 0.18, 0.0))
	_torus(parent, 0.37, 0.41, iron, offset + Vector3(0.0, 0.82, 0.0))
	_cyl(parent, 0.34, 0.34, 0.02, iron, offset + Vector3(0.0, 1.005, 0.0))
	_cyl(parent, 0.05, 0.05, 0.04, _m(FoundryMaterials.Kind.BRASS), offset + Vector3(0.17, 1.02, 0.08), Vector3.ZERO, 8)
	if with_collider:
		Layers.add_static_cylinder(parent, 0.4, 1.0, offset)


# --- Shared props --------------------------------------------------------------------

static func _crate(root: Node3D, rng: RandomNumberGenerator) -> void:
	_crate_visual(root, Vector3(1.0, 0.8, 0.9), Vector3.ZERO, 0.0)
	var height: float = 0.8
	if rng.randf() < 0.5:
		_crate_visual(root, Vector3(0.7, 0.6, 0.7), Vector3(rng.randf_range(-0.1, 0.1), 0.8, rng.randf_range(-0.1, 0.1)), rng.randf_range(-0.4, 0.4))
		height = 1.4
	Layers.add_static_box(root, Vector3(1.0, height, 0.9), Vector3(0.0, height * 0.5, 0.0))


static func _drum_cluster(root: Node3D, rng: RandomNumberGenerator) -> void:
	for offset: Vector3 in [Vector3(-0.42, 0.0, -0.25), Vector3(0.42, 0.0, -0.25), Vector3(0.0, 0.0, 0.4)]:
		_barrel(root, rng, offset, false)
	Layers.add_static_cylinder(root, 0.85, 1.0, Vector3.ZERO)


static func _scrap_heap(root: Node3D, rng: RandomNumberGenerator) -> void:
	var kinds: Array[FoundryMaterials.Kind] = [FoundryMaterials.Kind.RUST, FoundryMaterials.Kind.DARK_STEEL, FoundryMaterials.Kind.CAST_IRON, FoundryMaterials.Kind.COPPER_OXIDIZED, FoundryMaterials.Kind.RUST]
	_sphere(root, 0.75, _m(FoundryMaterials.Kind.RUST), Vector3(0.0, 0.0, 0.0), Vector3(1.0, 0.4, 1.0))
	for i: int in rng.randi_range(7, 10):
		var angle: float = rng.randf_range(0.0, TAU)
		var distance: float = rng.randf_range(0.0, 0.55)
		var size: Vector3 = Vector3(rng.randf_range(0.2, 0.6), rng.randf_range(0.04, 0.14), rng.randf_range(0.1, 0.4))
		var pos: Vector3 = Vector3(cos(angle) * distance, 0.32 - distance * 0.3, sin(angle) * distance)
		var rot: Vector3 = Vector3(rng.randf_range(-0.6, 0.6), rng.randf_range(0.0, TAU), rng.randf_range(-0.6, 0.6))
		_box(root, size, _pick(rng, kinds), pos, rot)
	_cyl(root, 0.08, 0.08, 0.9, _m(FoundryMaterials.Kind.COPPER_OXIDIZED), Vector3(0.1, 0.3, 0.1), Vector3(0.3, rng.randf_range(0.0, TAU), PI * 0.45), 10)
	var gear_holder: Node3D = Node3D.new()
	gear_holder.position = Vector3(-0.2, 0.35, 0.15)
	gear_holder.rotation = Vector3(1.1, rng.randf_range(0.0, TAU), 0.0)
	root.add_child(gear_holder)
	gear_holder.add_child(GearMeshFactory.build(0.3, 0.08, 9, _m(FoundryMaterials.Kind.RUST)))
	Layers.add_static_cylinder(root, 0.7, 0.5, Vector3.ZERO)


# --- Boiler Room ---------------------------------------------------------------------

static func _boiler(root: Node3D, rng: RandomNumberGenerator) -> void:
	var shell: StandardMaterial3D = _pick(rng, [FoundryMaterials.Kind.CAST_IRON, FoundryMaterials.Kind.RUST])
	var brass: StandardMaterial3D = _m(FoundryMaterials.Kind.BRASS)
	var iron: StandardMaterial3D = _m(FoundryMaterials.Kind.CAST_IRON)
	var axis_x: Vector3 = Vector3(0.0, 0.0, PI * 0.5)
	_cyl(root, 0.62, 0.62, 2.4, shell, Vector3(0.0, 0.85, 0.0), axis_x, 24)
	for side: float in [-1.0, 1.0]:
		_sphere(root, 0.62, shell, Vector3(side * 1.2, 0.85, 0.0), Vector3(0.35, 1.0, 1.0))
		_box(root, Vector3(0.25, 0.5, 1.05), iron, Vector3(side * 0.75, 0.25, 0.0))
	for x: float in [-0.8, 0.0, 0.8]:
		_torus(root, 0.6, 0.68, brass, Vector3(x, 0.85, 0.0), axis_x)
	_box(root, Vector3(0.45, 0.38, 0.05), brass, Vector3(-0.35, 0.82, 0.63))
	_cyl(root, 0.04, 0.04, 0.22, _m(FoundryMaterials.Kind.COPPER_OXIDIZED), Vector3(0.45, 1.55, 0.25), Vector3.ZERO, 8)
	_gauge(root, Vector3(0.45, 1.68, 0.27), 0.13, rng)
	_cyl(root, 0.07, 0.07, 0.4, _m(FoundryMaterials.Kind.COPPER_OXIDIZED), Vector3(-0.6, 1.62, 0.0), Vector3.ZERO, 10)
	_cyl(root, 0.11, 0.11, 0.06, brass, Vector3(-0.6, 1.84, 0.0), Vector3.ZERO, 10)
	var wisp: GPUParticles3D = Fx.make_steam_emitter(4, 1.6, 0.5, 12.0)
	wisp.position = Vector3(-0.6, 1.9, 0.0)
	root.add_child(wisp)
	Layers.add_static_box(root, Vector3(2.7, 1.5, 1.3), Vector3(0.0, 0.75, 0.0))


static func _coal_pile(root: Node3D, rng: RandomNumberGenerator) -> void:
	var coal: StandardMaterial3D = _m(FoundryMaterials.Kind.COAL)
	_sphere(root, 0.85, coal, Vector3.ZERO, Vector3(1.0, 0.32, 1.0))
	for i: int in rng.randi_range(12, 18):
		var angle: float = rng.randf_range(0.0, TAU)
		var distance: float = sqrt(rng.randf()) * 0.75
		var size: float = rng.randf_range(0.12, 0.26)
		_sphere(root, size, coal, Vector3(cos(angle) * distance, 0.3 * (1.0 - distance / 0.85), sin(angle) * distance), Vector3(1.0, 0.7, 1.0))
	var tilt: Vector3 = Vector3(0.35, rng.randf_range(-0.5, 0.5), 0.3)
	_cyl(root, 0.025, 0.025, 1.05, _m(FoundryMaterials.Kind.WOOD), Vector3(0.38, 0.75, 0.15), tilt, 8)
	_box(root, Vector3(0.24, 0.3, 0.03), _m(FoundryMaterials.Kind.DARK_STEEL), Vector3(0.22, 0.32, 0.0), tilt)
	Layers.add_static_cylinder(root, 0.8, 0.45, Vector3.ZERO)


static func _valve_manifold(root: Node3D, rng: RandomNumberGenerator) -> void:
	var copper: StandardMaterial3D = _m(FoundryMaterials.Kind.COPPER_OXIDIZED)
	_box(root, Vector3(1.0, 0.12, 0.4), _m(FoundryMaterials.Kind.CAST_IRON), Vector3(0.0, 0.06, -0.2))
	for x: float in [-0.3, 0.0, 0.3]:
		_cyl(root, 0.08, 0.08, 1.25, copper, Vector3(x, 0.7, -0.2), Vector3.ZERO, 10)
		_cyl(root, 0.12, 0.12, 0.05, _m(FoundryMaterials.Kind.BRASS), Vector3(x, 0.45, -0.2), Vector3.ZERO, 10)
	_cyl(root, 0.1, 0.1, 0.9, copper, Vector3(0.0, 1.32, -0.2), Vector3(0.0, 0.0, PI * 0.5), 10)
	for x: float in [-0.3, 0.3]:
		var wheel_mat: StandardMaterial3D = _pick(rng, [FoundryMaterials.Kind.RUST, FoundryMaterials.Kind.BRASS])
		_valve_wheel(root, Vector3(x, 0.85, -0.06), 0.13, wheel_mat)
	_gauge(root, Vector3(0.0, 1.0, -0.1), 0.1, rng)
	Layers.add_static_box(root, Vector3(1.0, 1.4, 0.5), Vector3(0.0, 0.7, -0.2))


static func _gauge_panel(root: Node3D, rng: RandomNumberGenerator) -> void:
	_box(root, Vector3(1.0, 0.7, 0.06), _m(FoundryMaterials.Kind.DARK_STEEL), Vector3(0.0, 1.65, 0.03))
	for corner: Vector2 in [Vector2(-0.44, 1.95), Vector2(0.44, 1.95), Vector2(-0.44, 1.35), Vector2(0.44, 1.35)]:
		_sphere(root, 0.025, _m(FoundryMaterials.Kind.BRASS), Vector3(corner.x, corner.y, 0.065))
	var count: int = rng.randi_range(2, 3)
	for i: int in count:
		var x: float = (float(i) - float(count - 1) * 0.5) * 0.3
		_gauge(root, Vector3(x, 1.72, 0.085), 0.11, rng)
	_cyl(root, 0.035, 0.035, 1.3, _m(FoundryMaterials.Kind.COPPER_OXIDIZED), Vector3(0.38, 0.65, 0.06), Vector3.ZERO, 8)


static func _pipe_riser(root: Node3D, rng: RandomNumberGenerator) -> void:
	var pipe_mat: StandardMaterial3D = _pick(rng, [FoundryMaterials.Kind.COPPER_OXIDIZED, FoundryMaterials.Kind.RUST])
	var brass: StandardMaterial3D = _m(FoundryMaterials.Kind.BRASS)
	_cyl(root, 0.11, 0.11, 3.3, pipe_mat, Vector3(0.0, 1.65, 0.18), Vector3.ZERO, 12)
	for y: float in [0.3, 1.8, 3.1]:
		_cyl(root, 0.17, 0.17, 0.06, brass, Vector3(0.0, y, 0.18), Vector3.ZERO, 12)
	for y: float in [1.0, 2.5]:
		_box(root, Vector3(0.12, 0.07, 0.16), _m(FoundryMaterials.Kind.DARK_STEEL), Vector3(0.0, y, 0.08))
	_valve_wheel(root, Vector3(0.0, 1.25, 0.35), 0.15, _pick(rng, [FoundryMaterials.Kind.RUST, FoundryMaterials.Kind.BRASS]))
	_cyl(root, 0.11, 0.11, 0.2, pipe_mat, Vector3(0.0, 3.3, 0.09), Vector3(PI * 0.5, 0.0, 0.0), 12)


## Horizontal pipe bundle along the wall with elbows dropping into the floor.
static func _pipe_run(root: Node3D, rng: RandomNumberGenerator) -> void:
	var brass: StandardMaterial3D = _m(FoundryMaterials.Kind.BRASS)
	var steel: StandardMaterial3D = _m(FoundryMaterials.Kind.DARK_STEEL)
	var axis_x: Vector3 = Vector3(0.0, 0.0, PI * 0.5)
	var count: int = rng.randi_range(1, 3)
	for i: int in count:
		var radius: float = rng.randf_range(0.06, 0.12)
		var y: float = rng.randf_range(0.5, 1.6) + float(i) * 0.3
		var z: float = 0.12 + float(i) * 0.05
		var mat: StandardMaterial3D = _pick(rng, [FoundryMaterials.Kind.COPPER_OXIDIZED, FoundryMaterials.Kind.RUST, FoundryMaterials.Kind.DARK_STEEL])
		_cyl(root, radius, radius, 2.8, mat, Vector3(0.0, y, z), axis_x, 10)
		for x: float in [-1.0, 0.0, 1.0]:
			_cyl(root, radius + 0.04, radius + 0.04, 0.05, brass, Vector3(x, y, z), axis_x, 10)
		if rng.randf() < 0.5:
			var drop_x: float = 1.4 if rng.randf() < 0.5 else -1.4
			_sphere(root, radius * 1.15, mat, Vector3(drop_x, y, z))
			_cyl(root, radius, radius, y, mat, Vector3(drop_x, y * 0.5, z), Vector3.ZERO, 10)
	for x: float in [-1.2, 1.2]:
		_box(root, Vector3(0.08, 1.8, 0.04), steel, Vector3(x, 1.2, 0.02))
	if rng.randf() < 0.6:
		_valve_wheel(root, Vector3(rng.randf_range(-0.8, 0.8), rng.randf_range(0.9, 1.4), 0.32), 0.12, _pick(rng, [FoundryMaterials.Kind.RUST, FoundryMaterials.Kind.BRASS]))


static func _hanging_chain(root: Node3D, rng: RandomNumberGenerator) -> void:
	var steel: StandardMaterial3D = _pick(rng, [FoundryMaterials.Kind.DARK_STEEL, FoundryMaterials.Kind.RUST])
	_box(root, Vector3(0.08, 0.08, 0.55), _m(FoundryMaterials.Kind.DARK_STEEL), Vector3(0.0, 3.3, 0.27))
	var y: float = 3.2
	for i: int in rng.randi_range(8, 12):
		var rot: Vector3 = Vector3(PI * 0.5, 0.0, 0.0) if i % 2 == 0 else Vector3(PI * 0.5, 0.0, PI * 0.5)
		_torus(root, 0.03, 0.055, steel, Vector3(0.0, y, 0.52), rot)
		y -= 0.1
	_torus(root, 0.06, 0.09, steel, Vector3(0.0, y - 0.04, 0.52), Vector3(0.0, 0.0, PI * 0.5))


# --- Gear Cutting Floor ----------------------------------------------------------------

static func _workbench(root: Node3D, rng: RandomNumberGenerator) -> void:
	var wood: StandardMaterial3D = _m(FoundryMaterials.Kind.WOOD)
	var iron: StandardMaterial3D = _m(FoundryMaterials.Kind.CAST_IRON)
	var steel: StandardMaterial3D = _m(FoundryMaterials.Kind.DARK_STEEL)
	_box(root, Vector3(1.8, 0.08, 0.8), wood, Vector3(0.0, 0.9, 0.0))
	for x: float in [-0.82, 0.82]:
		for z: float in [-0.32, 0.32]:
			_box(root, Vector3(0.08, 0.86, 0.08), iron, Vector3(x, 0.43, z))
	_box(root, Vector3(1.7, 0.05, 0.7), wood, Vector3(0.0, 0.25, 0.0))
	_box(root, Vector3(0.25, 0.12, 0.2), steel, Vector3(0.65, 1.0, 0.25))
	_box(root, Vector3(0.22, 0.14, 0.04), steel, Vector3(0.65, 1.12, 0.33))
	_box(root, Vector3(0.22, 0.14, 0.04), steel, Vector3(0.65, 1.12, 0.2))
	_cyl(root, 0.02, 0.02, 0.32, steel, Vector3(0.65, 1.08, 0.48), Vector3(PI * 0.5, 0.0, 0.0), 8)
	_box(root, Vector3(0.36, 0.02, 0.05), steel, Vector3(-0.15, 0.95, 0.15), Vector3(0.0, rng.randf_range(0.0, TAU), 0.0))
	_cyl(root, 0.02, 0.02, 0.3, wood, Vector3(0.2, 0.96, -0.15), Vector3(0.0, rng.randf_range(0.0, TAU), PI * 0.5), 8)
	var blank: Node3D = GearMeshFactory.build(0.16, 0.04, 10, _m(FoundryMaterials.Kind.BRASS))
	blank.position = Vector3(-0.55, 0.96, -0.1)
	root.add_child(blank)
	_crate_visual(root, Vector3(0.45, 0.3, 0.4), Vector3(-0.45, 0.28, 0.0), rng.randf_range(-0.3, 0.3))
	_cyl(root, 0.08, 0.08, 0.18, _m(FoundryMaterials.Kind.RUST), Vector3(0.4, 0.37, 0.1), Vector3.ZERO, 10)
	Layers.add_static_box(root, Vector3(1.8, 0.95, 0.8), Vector3(0.0, 0.475, 0.0))


static func _lathe(root: Node3D, rng: RandomNumberGenerator) -> void:
	var iron: StandardMaterial3D = _m(FoundryMaterials.Kind.CAST_IRON)
	var steel: StandardMaterial3D = _m(FoundryMaterials.Kind.DARK_STEEL)
	for x: float in [-0.65, 0.65]:
		_box(root, Vector3(0.35, 0.75, 0.45), iron, Vector3(x, 0.375, 0.0))
	_box(root, Vector3(1.8, 0.18, 0.4), steel, Vector3(0.0, 0.84, 0.0))
	_box(root, Vector3(0.45, 0.4, 0.42), iron, Vector3(-0.65, 1.13, 0.0))
	_box(root, Vector3(0.25, 0.28, 0.32), iron, Vector3(0.6, 1.07, 0.0))
	_box(root, Vector3(0.12, 0.12, 0.16), steel, Vector3(0.1, 1.0, 0.14))
	_cyl(root, 0.05, 0.05, 0.75, _m(FoundryMaterials.Kind.BRASS), Vector3(0.05, 1.13, 0.0), Vector3(0.0, 0.0, PI * 0.5), 12)
	_valve_wheel(root, Vector3(-0.65, 1.0, 0.25), 0.1, _m(FoundryMaterials.Kind.BRASS))
	_cyl(root, 0.16, 0.16, 0.4, iron, Vector3(-0.65, 0.5, -0.32), Vector3(0.0, 0.0, PI * 0.5), 14)
	# The spinning chuck: a small RotatingCog turned onto the lathe axis.
	var chuck_holder: Node3D = Node3D.new()
	chuck_holder.position = Vector3(-0.38, 1.13, 0.0)
	chuck_holder.rotation = Vector3(0.0, 0.0, PI * 0.5)
	root.add_child(chuck_holder)
	var chuck: RotatingCog = RotatingCog.new()
	chuck.radius = 0.16
	chuck.teeth = 8
	chuck.thickness = 0.12
	chuck.spin_speed = rng.randf_range(2.0, 3.5)
	chuck.material_kind = FoundryMaterials.Kind.DARK_STEEL
	chuck_holder.add_child(chuck)
	Layers.add_static_box(root, Vector3(1.8, 1.35, 0.5), Vector3(0.0, 0.675, 0.0))


static func _gear_crate(root: Node3D, rng: RandomNumberGenerator) -> void:
	_crate_visual(root, Vector3(1.0, 0.7, 0.8), Vector3.ZERO, 0.0)
	var kinds: Array[FoundryMaterials.Kind] = [FoundryMaterials.Kind.BRASS, FoundryMaterials.Kind.DARK_STEEL, FoundryMaterials.Kind.RUST]
	for i: int in 3:
		var radius: float = rng.randf_range(0.18, 0.3)
		var holder: Node3D = Node3D.new()
		holder.position = Vector3(-0.3 + 0.3 * float(i), 0.7 + radius * 0.4, rng.randf_range(-0.15, 0.15))
		holder.rotation = Vector3(PI * 0.5, rng.randf_range(-0.4, 0.4), 0.0)
		root.add_child(holder)
		holder.add_child(GearMeshFactory.build(radius, 0.06, rng.randi_range(8, 12), _pick(rng, kinds)))
	Layers.add_static_box(root, Vector3(1.0, 1.0, 0.8), Vector3(0.0, 0.5, 0.0))


static func _gear_stack(root: Node3D, rng: RandomNumberGenerator) -> void:
	_box(root, Vector3(1.0, 0.12, 1.0), _m(FoundryMaterials.Kind.WOOD), Vector3(0.0, 0.06, 0.0))
	var kinds: Array[FoundryMaterials.Kind] = [FoundryMaterials.Kind.BRASS, FoundryMaterials.Kind.DARK_STEEL, FoundryMaterials.Kind.RUST, FoundryMaterials.Kind.COPPER_OXIDIZED]
	var y: float = 0.18
	var radius: float = 0.48
	for i: int in rng.randi_range(3, 5):
		var gear: Node3D = GearMeshFactory.build(radius, 0.12, maxi(8, int(radius * 30.0)), _pick(rng, kinds))
		gear.position = Vector3(rng.randf_range(-0.04, 0.04), y, rng.randf_range(-0.04, 0.04))
		gear.rotation = Vector3(0.0, rng.randf_range(0.0, TAU), 0.0)
		root.add_child(gear)
		y += 0.14
		radius -= 0.07
	Layers.add_static_cylinder(root, 0.55, y, Vector3.ZERO)


static func _conveyor(root: Node3D, rng: RandomNumberGenerator) -> void:
	var steel: StandardMaterial3D = _m(FoundryMaterials.Kind.DARK_STEEL)
	var iron: StandardMaterial3D = _m(FoundryMaterials.Kind.CAST_IRON)
	for z: float in [-0.32, 0.32]:
		_box(root, Vector3(2.4, 0.12, 0.06), steel, Vector3(0.0, 0.7, z))
		for x: float in [-1.05, 1.05]:
			_box(root, Vector3(0.08, 0.66, 0.08), iron, Vector3(x, 0.33, z))
	var broken: int = rng.randi_range(2, 7)
	for i: int in 10:
		if i == broken or i == broken + 1:
			continue
		var x: float = -1.08 + 0.24 * float(i)
		_cyl(root, 0.05, 0.05, 0.62, _m(FoundryMaterials.Kind.BRASS), Vector3(x, 0.72, 0.0), Vector3(PI * 0.5, 0.0, 0.0), 10)
	_box(root, Vector3(0.35, 0.4, 0.5), iron, Vector3(-1.37, 0.6, 0.0))
	_cyl(root, 0.12, 0.12, 0.08, _m(FoundryMaterials.Kind.BRASS), Vector3(-1.37, 0.7, 0.28), Vector3(PI * 0.5, 0.0, 0.0), 12)
	_crate_visual(root, Vector3(0.4, 0.3, 0.4), Vector3(0.5, 0.77, 0.0), rng.randf_range(-0.4, 0.4))
	var blank: Node3D = GearMeshFactory.build(0.2, 0.05, 10, _m(FoundryMaterials.Kind.RUST))
	blank.position = Vector3(-0.5, 0.8, 0.0)
	root.add_child(blank)
	Layers.add_static_box(root, Vector3(2.8, 0.85, 0.75), Vector3(-0.15, 0.425, 0.0))


static func _tool_board(root: Node3D, rng: RandomNumberGenerator) -> void:
	var steel: StandardMaterial3D = _m(FoundryMaterials.Kind.DARK_STEEL)
	_box(root, Vector3(1.2, 0.8, 0.04), _m(FoundryMaterials.Kind.WOOD), Vector3(0.0, 1.7, 0.02))
	for i: int in 3:
		var x: float = -0.42 + 0.17 * float(i)
		var length: float = rng.randf_range(0.3, 0.45)
		_cyl(root, 0.012, 0.012, 0.05, steel, Vector3(x, 1.95, 0.06), Vector3(PI * 0.5, 0.0, 0.0), 6)
		_torus(root, 0.025, 0.045, steel, Vector3(x, 1.9, 0.06), Vector3(PI * 0.5, 0.0, 0.0))
		_box(root, Vector3(0.04, length, 0.015), steel, Vector3(x, 1.88 - length * 0.5, 0.06))
	_box(root, Vector3(0.45, 0.12, 0.01), steel, Vector3(0.25, 1.85, 0.05))
	_box(root, Vector3(0.12, 0.1, 0.03), _m(FoundryMaterials.Kind.WOOD), Vector3(0.52, 1.85, 0.055))
	_cyl(root, 0.015, 0.015, 0.32, _m(FoundryMaterials.Kind.WOOD), Vector3(0.25, 1.55, 0.06), Vector3.ZERO, 6)
	_box(root, Vector3(0.14, 0.06, 0.06), steel, Vector3(0.25, 1.72, 0.06))


static func _wall_cog_cluster(root: Node3D, rng: RandomNumberGenerator) -> void:
	var direction: float = 1.0 if rng.randf() < 0.5 else -1.0
	for i: int in 2:
		var cog: RotatingCog = RotatingCog.new()
		cog.radius = rng.randf_range(0.3, 0.55)
		cog.teeth = maxi(8, int(cog.radius * 24.0))
		cog.thickness = 0.12
		cog.upright = true
		cog.spin_speed = direction * rng.randf_range(0.4, 0.9) * (1.0 if i == 0 else -1.0)
		cog.material_kind = FoundryMaterials.Kind.BRASS if rng.randf() < 0.6 else FoundryMaterials.Kind.COPPER_OXIDIZED
		cog.position = Vector3(-0.28 + 0.56 * float(i), rng.randf_range(1.9, 2.5), 0.1)
		root.add_child(cog)


# --- Smelting Vats ----------------------------------------------------------------------

static func _ingot_stack(root: Node3D, rng: RandomNumberGenerator) -> void:
	var mat: StandardMaterial3D = _m(FoundryMaterials.Kind.BRASS) if rng.randf() < 0.3 else _m(FoundryMaterials.Kind.DARK_STEEL)
	for layer: int in 4:
		var yaw: float = 0.0 if layer % 2 == 0 else PI * 0.5
		for i: int in 3:
			var offset: float = -0.24 + 0.24 * float(i)
			var pos: Vector3 = Vector3(0.0, 0.065 + 0.13 * float(layer), offset).rotated(Vector3.UP, yaw)
			_box(root, Vector3(0.7, 0.12, 0.2), mat, pos, Vector3(0.0, yaw, 0.0))
	Layers.add_static_box(root, Vector3(0.75, 0.55, 0.75), Vector3(0.0, 0.275, 0.0))


static func _slag_pile(root: Node3D, rng: RandomNumberGenerator) -> void:
	var iron: StandardMaterial3D = _m(FoundryMaterials.Kind.CAST_IRON)
	_sphere(root, 0.8, iron, Vector3.ZERO, Vector3(1.0, 0.35, 1.0))
	for i: int in rng.randi_range(9, 13):
		var angle: float = rng.randf_range(0.0, TAU)
		var distance: float = sqrt(rng.randf()) * 0.65
		_sphere(root, rng.randf_range(0.1, 0.24), _pick(rng, [FoundryMaterials.Kind.CAST_IRON, FoundryMaterials.Kind.RUST, FoundryMaterials.Kind.COAL]), Vector3(cos(angle) * distance, 0.26 * (1.0 - distance / 0.8), sin(angle) * distance), Vector3(1.0, 0.65, 1.0))
	for i: int in rng.randi_range(3, 4):
		var angle: float = rng.randf_range(0.0, TAU)
		var distance: float = rng.randf_range(0.1, 0.55)
		_sphere(root, rng.randf_range(0.07, 0.11), _m(FoundryMaterials.Kind.SLAG_GLOW), Vector3(cos(angle) * distance, 0.27 * (1.0 - distance / 0.8), sin(angle) * distance))
	Layers.add_static_cylinder(root, 0.75, 0.4, Vector3.ZERO)


static func _ore_cart(root: Node3D, rng: RandomNumberGenerator) -> void:
	var steel: StandardMaterial3D = _m(FoundryMaterials.Kind.DARK_STEEL)
	for z: float in [-0.3, 0.3]:
		_box(root, Vector3(2.6, 0.05, 0.06), steel, Vector3(0.0, 0.025, z))
	for i: int in 5:
		_box(root, Vector3(0.12, 0.04, 0.8), _m(FoundryMaterials.Kind.WOOD), Vector3(-1.1 + 0.55 * float(i), 0.02, 0.0))
	var offset: float = rng.randf_range(-0.4, 0.4)
	for x: float in [-0.4, 0.4]:
		for z: float in [-0.3, 0.3]:
			_cyl(root, 0.15, 0.15, 0.06, _m(FoundryMaterials.Kind.CAST_IRON), Vector3(offset + x, 0.18, z), Vector3(PI * 0.5, 0.0, 0.0), 12)
	_box(root, Vector3(1.1, 0.55, 0.75), _m(FoundryMaterials.Kind.RUST), Vector3(offset, 0.56, 0.0))
	_box(root, Vector3(1.15, 0.06, 0.8), steel, Vector3(offset, 0.84, 0.0))
	for i: int in 7:
		_sphere(root, rng.randf_range(0.12, 0.2), _pick(rng, [FoundryMaterials.Kind.COAL, FoundryMaterials.Kind.RUST]), Vector3(offset + rng.randf_range(-0.4, 0.4), 0.85, rng.randf_range(-0.25, 0.25)), Vector3(1.0, 0.7, 1.0))
	Layers.add_static_box(root, Vector3(1.2, 0.95, 0.85), Vector3(offset, 0.475, 0.0))


static func _ladle_rack(root: Node3D, rng: RandomNumberGenerator) -> void:
	var steel: StandardMaterial3D = _m(FoundryMaterials.Kind.DARK_STEEL)
	for x: float in [-0.5, 0.5]:
		_box(root, Vector3(0.08, 1.3, 0.08), steel, Vector3(x, 0.65, -0.1))
	_cyl(root, 0.04, 0.04, 1.1, steel, Vector3(0.0, 1.25, -0.1), Vector3(0.0, 0.0, PI * 0.5), 8)
	var count: int = rng.randi_range(2, 3)
	for i: int in count:
		var x: float = (float(i) - float(count - 1) * 0.5) * 0.32
		_box(root, Vector3(0.035, 0.62, 0.035), steel, Vector3(x, 0.93, -0.1))
		_cyl(root, 0.15, 0.1, 0.18, _m(FoundryMaterials.Kind.CAST_IRON), Vector3(x, 0.55, -0.1), Vector3.ZERO, 14)
	Layers.add_static_box(root, Vector3(1.1, 1.3, 0.3), Vector3(0.0, 0.65, -0.1))


# --- Master Clock Vault --------------------------------------------------------------------

static func _clock_panel(root: Node3D, rng: RandomNumberGenerator) -> void:
	var facing: Vector3 = Vector3(PI * 0.5, 0.0, 0.0)
	var center: Vector3 = Vector3(0.0, 2.1, 0.0)
	_cyl(root, 0.62, 0.62, 0.06, _m(FoundryMaterials.Kind.DARK_STEEL), center + Vector3(0.0, 0.0, 0.03), facing, 28)
	_torus(root, 0.55, 0.62, _m(FoundryMaterials.Kind.BRASS), center + Vector3(0.0, 0.0, 0.07), facing)
	_cyl(root, 0.53, 0.53, 0.01, _m(FoundryMaterials.Kind.GAUGE_FACE), center + Vector3(0.0, 0.0, 0.065), facing, 28)
	for i: int in 12:
		var angle: float = TAU * float(i) / 12.0
		var tick: MeshInstance3D = _box(root, Vector3(0.03, 0.08, 0.01), _m(FoundryMaterials.Kind.CAST_IRON), center + Vector3(sin(angle) * 0.45, cos(angle) * 0.45, 0.075))
		tick.rotation = Vector3(0.0, 0.0, -angle)
	for hand: Vector2 in [Vector2(0.28, 0.035), Vector2(0.42, 0.02)]:
		var pivot: Node3D = Node3D.new()
		pivot.position = center + Vector3(0.0, 0.0, 0.08)
		pivot.rotation = Vector3(0.0, 0.0, rng.randf_range(0.0, TAU))
		root.add_child(pivot)
		_box(pivot, Vector3(hand.y, hand.x, 0.01), _m(FoundryMaterials.Kind.CAST_IRON), Vector3(0.0, hand.x * 0.45, 0.0))
	var cog: RotatingCog = RotatingCog.new()
	cog.radius = 0.25
	cog.teeth = 10
	cog.thickness = 0.08
	cog.upright = true
	cog.spin_speed = rng.randf_range(-0.8, 0.8)
	cog.position = Vector3(0.55, 1.55, 0.06)
	root.add_child(cog)


static func _brass_plaque(root: Node3D, rng: RandomNumberGenerator) -> void:
	var brass: StandardMaterial3D = _m(FoundryMaterials.Kind.BRASS)
	_box(root, Vector3(1.4, 0.14, 0.03), brass, Vector3(0.0, 1.2, 0.015))
	_box(root, Vector3(1.4, 0.05, 0.02), brass, Vector3(0.0, 0.45, 0.01))
	for i: int in 6:
		_sphere(root, 0.02, _m(FoundryMaterials.Kind.DARK_STEEL), Vector3(-0.6 + 0.24 * float(i), 1.2, 0.035))
	_box(root, Vector3(0.5, 0.26, 0.02), _m(FoundryMaterials.Kind.DARK_STEEL), Vector3(rng.randf_range(-0.3, 0.3), 1.55, 0.01))


# --- Floor scatter (no collision) -------------------------------------------------------------

static func _coal_lumps(root: Node3D, rng: RandomNumberGenerator) -> void:
	for i: int in rng.randi_range(4, 7):
		var radius: float = rng.randf_range(0.05, 0.11)
		_sphere(root, radius, _m(FoundryMaterials.Kind.COAL), Vector3(rng.randf_range(-0.32, 0.32), radius * 0.5, rng.randf_range(-0.32, 0.32)), Vector3(1.0, 0.7, 1.0))


static func _bolts(root: Node3D, rng: RandomNumberGenerator) -> void:
	for i: int in rng.randi_range(4, 7):
		var bolt: Node3D = Node3D.new()
		bolt.position = Vector3(rng.randf_range(-0.25, 0.25), 0.0, rng.randf_range(-0.25, 0.25))
		bolt.rotation = Vector3(0.0, rng.randf_range(0.0, TAU), 0.0)
		root.add_child(bolt)
		var mat: StandardMaterial3D = _pick(rng, [FoundryMaterials.Kind.DARK_STEEL, FoundryMaterials.Kind.BRASS, FoundryMaterials.Kind.RUST])
		_cyl(bolt, 0.04, 0.04, 0.03, mat, Vector3(0.0, 0.04, 0.0), Vector3(0.0, 0.0, PI * 0.5), 6)
		_cyl(bolt, 0.018, 0.018, 0.12, mat, Vector3(0.07, 0.02, 0.0), Vector3(0.0, 0.0, PI * 0.5), 6)


static func _shavings(root: Node3D, rng: RandomNumberGenerator) -> void:
	for i: int in rng.randi_range(7, 12):
		var mat: StandardMaterial3D = _pick(rng, [FoundryMaterials.Kind.DARK_STEEL, FoundryMaterials.Kind.BRASS, FoundryMaterials.Kind.BRASS])
		var curl: MeshInstance3D = _torus(root, 0.03, 0.042, mat, Vector3(rng.randf_range(-0.3, 0.3), 0.02, rng.randf_range(-0.3, 0.3)), Vector3(rng.randf_range(-1.2, 1.2), rng.randf_range(0.0, TAU), rng.randf_range(-1.2, 1.2)))
		curl.scale = Vector3(1.0, 1.0, rng.randf_range(0.3, 0.7))


static func _gear_blank(root: Node3D, rng: RandomNumberGenerator) -> void:
	for i: int in rng.randi_range(1, 2):
		var gear: Node3D = GearMeshFactory.build(rng.randf_range(0.12, 0.24), 0.04, rng.randi_range(8, 12), _pick(rng, [FoundryMaterials.Kind.RUST, FoundryMaterials.Kind.BRASS]))
		gear.position = Vector3(rng.randf_range(-0.1, 0.1), 0.02 + 0.04 * float(i), rng.randf_range(-0.1, 0.1))
		gear.rotation = Vector3(rng.randf_range(-0.08, 0.08), rng.randf_range(0.0, TAU), 0.0)
		root.add_child(gear)


static func _slag_bits(root: Node3D, rng: RandomNumberGenerator) -> void:
	for i: int in rng.randi_range(4, 6):
		var radius: float = rng.randf_range(0.04, 0.1)
		_sphere(root, radius, _m(FoundryMaterials.Kind.CAST_IRON), Vector3(rng.randf_range(-0.3, 0.3), radius * 0.4, rng.randf_range(-0.3, 0.3)), Vector3(1.0, 0.6, 1.0))
	_sphere(root, 0.05, _m(FoundryMaterials.Kind.SLAG_GLOW), Vector3(rng.randf_range(-0.2, 0.2), 0.02, rng.randf_range(-0.2, 0.2)), Vector3(1.0, 0.6, 1.0))


static func _ingot_single(root: Node3D, rng: RandomNumberGenerator) -> void:
	_box(root, Vector3(0.6, 0.12, 0.18), _m(FoundryMaterials.Kind.DARK_STEEL), Vector3(0.0, 0.06, 0.0))
	if rng.randf() < 0.5:
		_box(root, Vector3(0.6, 0.12, 0.18), _m(FoundryMaterials.Kind.DARK_STEEL), Vector3(0.05, 0.12, 0.1), Vector3(0.35, 0.6, 0.1))


# --- Act I: dispatch yard, tramline, showroom ------------------------------------------------

## Billboarded furniture sprite from assets/sprites/decor, standing on the floor, with a collider.
static func _sprite_prop(root: Node3D, texture: Texture2D, pixel_size: float, radius: float, height: float) -> void:
	var sprite: Sprite3D = Sprite3D.new()
	sprite.texture = texture
	sprite.pixel_size = pixel_size
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.double_sided = true
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.position = Vector3(0.0, float(texture.get_height()) * pixel_size * 0.5, 0.0)
	root.add_child(sprite)
	root.add_child(Fx.make_blob_shadow(radius))
	Layers.add_static_cylinder(root, radius, height, Vector3.ZERO)


static func _sack(parent: Node3D, pos: Vector3, scale: Vector3, yaw: float) -> void:
	var sack: MeshInstance3D = _sphere(parent, 0.35, _m(FoundryMaterials.Kind.FABRIC), pos, scale)
	sack.rotation = Vector3(0.0, yaw, 0.0)
	_cyl(parent, 0.06, 0.09, 0.12, _m(FoundryMaterials.Kind.FABRIC), pos + Vector3(0.0, 0.35 * scale.y, 0.0), Vector3.ZERO, 8)


static func _mail_sacks(root: Node3D, rng: RandomNumberGenerator) -> void:
	for i: int in rng.randi_range(3, 5):
		var angle: float = rng.randf_range(0.0, TAU)
		var distance: float = rng.randf_range(0.0, 0.4)
		_sack(root, Vector3(cos(angle) * distance, 0.28, sin(angle) * distance), Vector3(1.0, rng.randf_range(0.75, 1.0), 0.8), rng.randf_range(0.0, TAU))
	if rng.randf() < 0.6:
		_sack(root, Vector3(0.05, 0.75, 0.0), Vector3(0.9, 0.7, 0.75), rng.randf_range(0.0, TAU))
	_box(root, Vector3(0.25, 0.01, 0.12), _m(FoundryMaterials.Kind.PAPER), Vector3(0.3, 0.5, 0.35), Vector3(0.4, 0.3, 0.0))
	Layers.add_static_cylinder(root, 0.7, 0.9, Vector3.ZERO)


static func _hand_cart(root: Node3D, rng: RandomNumberGenerator) -> void:
	var wood: StandardMaterial3D = _m(FoundryMaterials.Kind.WOOD)
	var iron: StandardMaterial3D = _m(FoundryMaterials.Kind.CAST_IRON)
	_box(root, Vector3(1.4, 0.08, 0.8), wood, Vector3(0.0, 0.5, 0.0))
	for z: float in [-0.38, 0.38]:
		_box(root, Vector3(1.4, 0.3, 0.05), wood, Vector3(0.0, 0.68, z))
		_cyl(root, 0.28, 0.28, 0.06, iron, Vector3(0.1, 0.28, z + signf(z) * 0.08), Vector3(PI * 0.5, 0.0, 0.0), 14)
	for z: float in [-0.25, 0.25]:
		_cyl(root, 0.025, 0.025, 1.0, wood, Vector3(-1.1, 0.75, z), Vector3(0.0, 0.0, PI * 0.38), 8)
	_box(root, Vector3(0.08, 0.45, 0.06), iron, Vector3(0.6, 0.25, 0.0))
	_crate_visual(root, Vector3(0.6, 0.45, 0.55), Vector3(0.25, 0.54, 0.0), rng.randf_range(-0.3, 0.3))
	if rng.randf() < 0.5:
		_sack(root, Vector3(-0.35, 0.8, 0.05), Vector3(0.8, 0.6, 0.7), rng.randf_range(0.0, TAU))
	Layers.add_static_box(root, Vector3(1.6, 1.0, 1.0), Vector3(0.0, 0.5, 0.0))


static func _pallet(parent: Node3D, y: float, yaw: float) -> void:
	var holder: Node3D = Node3D.new()
	holder.position = Vector3(0.0, y, 0.0)
	holder.rotation = Vector3(0.0, yaw, 0.0)
	parent.add_child(holder)
	var wood: StandardMaterial3D = _m(FoundryMaterials.Kind.WOOD)
	for z: float in [-0.4, 0.0, 0.4]:
		_box(holder, Vector3(1.1, 0.08, 0.12), wood, Vector3(0.0, 0.04, z))
	for x: float in [-0.45, -0.15, 0.15, 0.45]:
		_box(holder, Vector3(0.14, 0.03, 1.0), wood, Vector3(x, 0.095, 0.0))


static func _pallet_stack(root: Node3D, rng: RandomNumberGenerator) -> void:
	var count: int = rng.randi_range(3, 6)
	for i: int in count:
		_pallet(root, 0.11 * float(i), rng.randf_range(-0.12, 0.12))
	if rng.randf() < 0.5:
		_crate_visual(root, Vector3(0.7, 0.55, 0.7), Vector3(0.0, 0.11 * float(count), 0.0), rng.randf_range(-0.4, 0.4))
	var height: float = 0.11 * float(count) + 0.6
	Layers.add_static_box(root, Vector3(1.15, height, 1.05), Vector3(0.0, height * 0.5, 0.0))


static func _wall_lantern(root: Node3D, rng: RandomNumberGenerator) -> void:
	var iron: StandardMaterial3D = _m(FoundryMaterials.Kind.CAST_IRON)
	_box(root, Vector3(0.05, 0.05, 0.4), iron, Vector3(0.0, 2.4, 0.2))
	_box(root, Vector3(0.14, 0.2, 0.04), iron, Vector3(0.0, 2.4, 0.02))
	_cyl(root, 0.11, 0.13, 0.3, _m(FoundryMaterials.Kind.STEAM_GLASS), Vector3(0.0, 2.15, 0.38), Vector3.ZERO, 8)
	_cyl(root, 0.15, 0.08, 0.1, _m(FoundryMaterials.Kind.BRASS), Vector3(0.0, 2.35, 0.38), Vector3.ZERO, 8)
	var flame: Color = Color(1.0, 0.72, 0.38)
	_sphere(root, 0.06, FoundryMaterials.emissive(flame, 4.0), Vector3(0.0, 2.13, 0.38))
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = flame
	light.light_energy = rng.randf_range(0.8, 1.1)
	light.omni_range = 4.5
	light.position = Vector3(0.0, 2.1, 0.5)
	root.add_child(light)


static func _notice_board(root: Node3D, rng: RandomNumberGenerator) -> void:
	_box(root, Vector3(1.2, 0.85, 0.05), _m(FoundryMaterials.Kind.WOOD), Vector3(0.0, 1.65, 0.025))
	_box(root, Vector3(1.28, 0.07, 0.07), _m(FoundryMaterials.Kind.DARK_STEEL), Vector3(0.0, 2.1, 0.03))
	for i: int in rng.randi_range(3, 6):
		var size: Vector2 = Vector2(rng.randf_range(0.18, 0.32), rng.randf_range(0.22, 0.36))
		var pos: Vector3 = Vector3(rng.randf_range(-0.42, 0.42), rng.randf_range(1.38, 1.92), 0.055)
		_box(root, Vector3(size.x, size.y, 0.005), _m(FoundryMaterials.Kind.PAPER), pos, Vector3(0.0, 0.0, rng.randf_range(-0.15, 0.15)))
		_sphere(root, 0.015, _m(FoundryMaterials.Kind.BRASS), pos + Vector3(0.0, size.y * 0.4, 0.01))


static func _straw(root: Node3D, rng: RandomNumberGenerator) -> void:
	var straw: StandardMaterial3D = _m(FoundryMaterials.Kind.FABRIC)
	for i: int in rng.randi_range(8, 14):
		_box(root, Vector3(rng.randf_range(0.15, 0.3), 0.01, 0.015), straw, Vector3(rng.randf_range(-0.3, 0.3), 0.01, rng.randf_range(-0.3, 0.3)), Vector3(0.0, rng.randf_range(0.0, TAU), 0.0))


static func _letters(root: Node3D, rng: RandomNumberGenerator) -> void:
	for i: int in rng.randi_range(2, 5):
		_box(root, Vector3(0.22, 0.005, 0.14), _m(FoundryMaterials.Kind.PAPER), Vector3(rng.randf_range(-0.25, 0.25), 0.005 + 0.004 * float(i), rng.randf_range(-0.25, 0.25)), Vector3(0.0, rng.randf_range(0.0, TAU), 0.0))


static func _bench(root: Node3D, rng: RandomNumberGenerator) -> void:
	var wood: StandardMaterial3D = _m(FoundryMaterials.Kind.WOOD)
	var iron: StandardMaterial3D = _m(FoundryMaterials.Kind.CAST_IRON)
	for z: float in [-0.12, 0.0, 0.12]:
		_box(root, Vector3(1.8, 0.04, 0.1), wood, Vector3(0.0, 0.46, z))
	for y: float in [0.65, 0.8]:
		_box(root, Vector3(1.8, 0.1, 0.04), wood, Vector3(0.0, y, -0.2))
	for x: float in [-0.8, 0.8]:
		_box(root, Vector3(0.06, 0.46, 0.4), iron, Vector3(x, 0.23, -0.02))
		_box(root, Vector3(0.06, 0.5, 0.05), iron, Vector3(x, 0.7, -0.22))
	if rng.randf() < 0.35:
		_box(root, Vector3(0.3, 0.02, 0.22), _m(FoundryMaterials.Kind.PAPER), Vector3(rng.randf_range(-0.5, 0.5), 0.49, 0.0), Vector3(0.0, rng.randf_range(-0.5, 0.5), 0.0))
	Layers.add_static_box(root, Vector3(1.8, 0.9, 0.5), Vector3(0.0, 0.45, -0.05))


static func _ticket_booth(root: Node3D, rng: RandomNumberGenerator) -> void:
	var wood: StandardMaterial3D = _m(FoundryMaterials.Kind.WOOD)
	var brass: StandardMaterial3D = _m(FoundryMaterials.Kind.BRASS)
	_box(root, Vector3(1.4, 1.0, 1.0), wood, Vector3(0.0, 0.5, -0.1))
	_box(root, Vector3(1.5, 0.06, 1.1), brass, Vector3(0.0, 1.02, -0.1))
	for x: float in [-0.67, 0.67]:
		_box(root, Vector3(0.08, 1.2, 0.08), wood, Vector3(x, 1.6, 0.35))
	_box(root, Vector3(1.4, 0.6, 0.02), _m(FoundryMaterials.Kind.GLASS), Vector3(0.0, 1.5, 0.36))
	_box(root, Vector3(1.5, 0.3, 1.1), wood, Vector3(0.0, 2.3, -0.1))
	_box(root, Vector3(0.9, 0.18, 0.02), brass, Vector3(0.0, 2.3, 0.46))
	_sphere(root, 0.07, FoundryMaterials.emissive(Color(1.0, 0.75, 0.4), 2.0), Vector3(rng.randf_range(-0.3, 0.3), 1.25, 0.0))
	Layers.add_static_box(root, Vector3(1.5, 2.4, 1.1), Vector3(0.0, 1.2, -0.1))


static func _luggage_pile(root: Node3D, rng: RandomNumberGenerator) -> void:
	var kinds: Array[FoundryMaterials.Kind] = [FoundryMaterials.Kind.WOOD, FoundryMaterials.Kind.FABRIC, FoundryMaterials.Kind.VELVET, FoundryMaterials.Kind.RUST]
	var y: float = 0.0
	for i: int in rng.randi_range(2, 4):
		var size: Vector3 = Vector3(rng.randf_range(0.6, 0.95), rng.randf_range(0.25, 0.4), rng.randf_range(0.4, 0.55))
		var holder: Node3D = Node3D.new()
		holder.position = Vector3(rng.randf_range(-0.1, 0.1), y, rng.randf_range(-0.1, 0.1))
		holder.rotation = Vector3(0.0, rng.randf_range(-0.5, 0.5), 0.0)
		root.add_child(holder)
		_box(holder, size, _pick(rng, kinds), Vector3(0.0, size.y * 0.5, 0.0))
		_box(holder, Vector3(size.x + 0.02, 0.04, size.z * 0.3), _m(FoundryMaterials.Kind.BRASS), Vector3(0.0, size.y * 0.5, 0.0))
		y += size.y
	Layers.add_static_box(root, Vector3(1.1, y, 0.8), Vector3(0.0, y * 0.5, 0.0))


static func _signal_lamp(root: Node3D, rng: RandomNumberGenerator) -> void:
	var iron: StandardMaterial3D = _m(FoundryMaterials.Kind.CAST_IRON)
	_box(root, Vector3(0.36, 0.8, 0.12), iron, Vector3(0.0, 2.2, 0.08))
	var colors: Array[Color] = [Color(1.0, 0.25, 0.1), Color(1.0, 0.75, 0.2), Color(0.3, 1.0, 0.45)]
	var lit: int = rng.randi_range(0, 2)
	for i: int in 3:
		var energy: float = 3.0 if i == lit else 0.3
		_sphere(root, 0.09, FoundryMaterials.emissive(colors[i], energy), Vector3(0.0, 2.45 - 0.25 * float(i), 0.15))
		_cyl(root, 0.12, 0.12, 0.04, _m(FoundryMaterials.Kind.DARK_STEEL), Vector3(0.0, 2.5 - 0.25 * float(i), 0.17), Vector3(PI * 0.35, 0.0, 0.0), 10)
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = colors[lit]
	light.light_energy = 0.8
	light.omni_range = 3.0
	light.position = Vector3(0.0, 2.45 - 0.25 * float(lit), 0.4)
	root.add_child(light)


static func _timetable_board(root: Node3D, rng: RandomNumberGenerator) -> void:
	_box(root, Vector3(1.3, 0.9, 0.05), _m(FoundryMaterials.Kind.CAST_IRON), Vector3(0.0, 1.9, 0.025))
	_box(root, Vector3(1.38, 0.08, 0.07), _m(FoundryMaterials.Kind.BRASS), Vector3(0.0, 2.38, 0.03))
	for row: int in 5:
		var width: float = rng.randf_range(0.6, 1.1)
		_box(root, Vector3(width, 0.06, 0.005), _m(FoundryMaterials.Kind.PAPER), Vector3(-0.55 + width * 0.5, 2.18 - 0.14 * float(row), 0.055))
	_gauge(root, Vector3(0.45, 2.18, 0.06), 0.09, rng)


static func _tickets(root: Node3D, rng: RandomNumberGenerator) -> void:
	for i: int in rng.randi_range(3, 7):
		_box(root, Vector3(0.1, 0.004, 0.05), _m(FoundryMaterials.Kind.PAPER), Vector3(rng.randf_range(-0.3, 0.3), 0.004, rng.randf_range(-0.3, 0.3)), Vector3(0.0, rng.randf_range(0.0, TAU), 0.0))
	if rng.randf() < 0.5:
		_sphere(root, 0.04, _m(FoundryMaterials.Kind.COAL), Vector3(rng.randf_range(-0.2, 0.2), 0.02, rng.randf_range(-0.2, 0.2)), Vector3(1.0, 0.6, 1.0))


static func _display_case(root: Node3D, rng: RandomNumberGenerator) -> void:
	var wood: StandardMaterial3D = _m(FoundryMaterials.Kind.WOOD)
	var brass: StandardMaterial3D = _m(FoundryMaterials.Kind.BRASS)
	_box(root, Vector3(1.3, 0.8, 0.7), wood, Vector3(0.0, 0.4, 0.0))
	_box(root, Vector3(1.36, 0.05, 0.76), brass, Vector3(0.0, 0.82, 0.0))
	_box(root, Vector3(1.2, 0.03, 0.6), _m(FoundryMaterials.Kind.VELVET), Vector3(0.0, 0.86, 0.0))
	if rng.randf() >= 0.4:
		_box(root, Vector3(1.3, 0.45, 0.7), _m(FoundryMaterials.Kind.GLASS), Vector3(0.0, 1.1, 0.0))
	for corner: Vector2 in [Vector2(-0.63, -0.33), Vector2(0.63, -0.33), Vector2(-0.63, 0.33), Vector2(0.63, 0.33)]:
		_box(root, Vector3(0.04, 0.47, 0.04), brass, Vector3(corner.x, 1.1, corner.y))
	_box(root, Vector3(1.36, 0.04, 0.76), brass, Vector3(0.0, 1.34, 0.0))
	for i: int in rng.randi_range(1, 3):
		var exhibit: Node3D = GearMeshFactory.build(rng.randf_range(0.1, 0.18), 0.04, rng.randi_range(8, 14), _pick(rng, [FoundryMaterials.Kind.BRASS, FoundryMaterials.Kind.GOLD, FoundryMaterials.Kind.DARK_STEEL]))
		exhibit.position = Vector3(-0.35 + 0.35 * float(i), 0.92, rng.randf_range(-0.1, 0.1))
		exhibit.rotation = Vector3(rng.randf_range(0.6, 1.2), rng.randf_range(0.0, TAU), 0.0)
		root.add_child(exhibit)
	Layers.add_static_box(root, Vector3(1.36, 1.36, 0.76), Vector3(0.0, 0.68, 0.0))


static func _clock_pedestal(root: Node3D, rng: RandomNumberGenerator) -> void:
	var wood: StandardMaterial3D = _m(FoundryMaterials.Kind.WOOD)
	var brass: StandardMaterial3D = _m(FoundryMaterials.Kind.BRASS)
	_cyl(root, 0.3, 0.38, 0.9, wood, Vector3(0.0, 0.45, 0.0), Vector3.ZERO, 12)
	_cyl(root, 0.36, 0.36, 0.05, brass, Vector3(0.0, 0.92, 0.0), Vector3.ZERO, 12)
	var facing: Vector3 = Vector3(PI * 0.5, 0.0, 0.0)
	var center: Vector3 = Vector3(0.0, 1.22, 0.0)
	_cyl(root, 0.24, 0.24, 0.12, brass, center, facing, 20)
	_cyl(root, 0.2, 0.2, 0.01, _m(FoundryMaterials.Kind.GAUGE_FACE), center + Vector3(0.0, 0.0, 0.061), facing, 20)
	for hand: Vector2 in [Vector2(0.12, 0.02), Vector2(0.17, 0.012)]:
		var pivot: Node3D = Node3D.new()
		pivot.position = center + Vector3(0.0, 0.0, 0.068)
		pivot.rotation = Vector3(0.0, 0.0, rng.randf_range(0.0, TAU))
		root.add_child(pivot)
		_box(pivot, Vector3(hand.y, hand.x, 0.006), _m(FoundryMaterials.Kind.CAST_IRON), Vector3(0.0, hand.x * 0.45, 0.0))
	_sphere(root, 0.05, brass, center + Vector3(0.0, 0.27, 0.0))
	Layers.add_static_cylinder(root, 0.4, 1.4, Vector3.ZERO)


## Framed advertising placard for the Perpetual Engine.
static func _placard(root: Node3D, rng: RandomNumberGenerator) -> void:
	var brass: StandardMaterial3D = _m(FoundryMaterials.Kind.BRASS)
	_box(root, Vector3(0.9, 1.2, 0.04), brass, Vector3(0.0, 1.8, 0.02))
	_box(root, Vector3(0.78, 1.08, 0.01), _m(FoundryMaterials.Kind.PAPER), Vector3(0.0, 1.8, 0.045))
	var gear: Node3D = GearMeshFactory.build(0.22, 0.02, 12, _m(FoundryMaterials.Kind.GOLD))
	gear.position = Vector3(0.0, 1.95, 0.06)
	gear.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	root.add_child(gear)
	for row: int in 3:
		_box(root, Vector3(rng.randf_range(0.4, 0.6), 0.04, 0.004), _m(FoundryMaterials.Kind.VELVET), Vector3(0.0, 1.6 - 0.1 * float(row), 0.052))


static func _glass_shards(root: Node3D, rng: RandomNumberGenerator) -> void:
	for i: int in rng.randi_range(5, 9):
		var size: Vector3 = Vector3(rng.randf_range(0.04, 0.12), 0.006, rng.randf_range(0.03, 0.09))
		_box(root, size, _m(FoundryMaterials.Kind.GLASS), Vector3(rng.randf_range(-0.3, 0.3), 0.006, rng.randf_range(-0.3, 0.3)), Vector3(rng.randf_range(-0.1, 0.1), rng.randf_range(0.0, TAU), 0.0))


# --- Cistern ------------------------------------------------------------------------------

static func _pump_engine(root: Node3D, rng: RandomNumberGenerator) -> void:
	var iron: StandardMaterial3D = _m(FoundryMaterials.Kind.CAST_IRON)
	var copper: StandardMaterial3D = _m(FoundryMaterials.Kind.COPPER_OXIDIZED)
	var brass: StandardMaterial3D = _m(FoundryMaterials.Kind.BRASS)
	_box(root, Vector3(2.0, 0.25, 1.1), iron, Vector3(0.0, 0.125, -0.1))
	_cyl(root, 0.4, 0.45, 1.4, copper, Vector3(-0.5, 0.95, -0.1), Vector3.ZERO, 16)
	_cyl(root, 0.45, 0.45, 0.08, brass, Vector3(-0.5, 1.68, -0.1), Vector3.ZERO, 16)
	_cyl(root, 0.08, 0.08, 1.2, _m(FoundryMaterials.Kind.DARK_STEEL), Vector3(0.1, 1.55, -0.1), Vector3(0.0, 0.0, PI * 0.5), 10)
	var flywheel_tilt: float = rng.randf_range(0.0, PI)
	_torus(root, 0.42, 0.52, iron, Vector3(0.6, 0.95, -0.1), Vector3(flywheel_tilt, 0.0, PI * 0.5))
	_cyl(root, 0.06, 0.06, 0.95, iron, Vector3(0.6, 0.95, -0.1), Vector3(flywheel_tilt, 0.0, 0.0), 8)
	_gauge(root, Vector3(-0.5, 1.1, 0.32), 0.12, rng)
	Layers.add_static_box(root, Vector3(2.0, 1.7, 1.1), Vector3(0.0, 0.85, -0.1))


static func _bucket_pile(root: Node3D, rng: RandomNumberGenerator) -> void:
	var mats: Array[FoundryMaterials.Kind] = [FoundryMaterials.Kind.RUST, FoundryMaterials.Kind.DARK_STEEL, FoundryMaterials.Kind.WOOD]
	for i: int in rng.randi_range(3, 5):
		var pos: Vector3 = Vector3(rng.randf_range(-0.35, 0.35), 0.0, rng.randf_range(-0.3, 0.3))
		if rng.randf() < 0.3:
			_cyl(root, 0.2, 0.15, 0.32, _pick(rng, mats), pos + Vector3(0.0, 0.15, 0.0), Vector3(PI * 0.5, rng.randf_range(0.0, TAU), 0.0), 12)
		else:
			_cyl(root, 0.2, 0.15, 0.34, _pick(rng, mats), pos + Vector3(0.0, 0.17, 0.0), Vector3.ZERO, 12)
	Layers.add_static_cylinder(root, 0.5, 0.4, Vector3.ZERO)


static func _puddle_stones(root: Node3D, rng: RandomNumberGenerator) -> void:
	var stone: StandardMaterial3D = _m(FoundryMaterials.Kind.CAST_IRON)
	for i: int in rng.randi_range(3, 6):
		_sphere(root, rng.randf_range(0.06, 0.13), stone, Vector3(rng.randf_range(-0.3, 0.3), 0.02, rng.randf_range(-0.3, 0.3)), Vector3(1.0, 0.45, 1.0))


# --- Garden -------------------------------------------------------------------------------

static func _leaf_material(rng: RandomNumberGenerator) -> StandardMaterial3D:
	var key: String = "leaf%d" % rng.randi_range(0, 2)
	if not _mesh_cache.has(key):
		var leaf: StandardMaterial3D = StandardMaterial3D.new()
		leaf.albedo_color = [Color(0.25, 0.42, 0.18), Color(0.33, 0.5, 0.2), Color(0.42, 0.45, 0.16)][int(key.right(1))]
		leaf.roughness = 0.8
		_mesh_cache[key] = leaf
	return _mesh_cache[key] as StandardMaterial3D


static func _planter(root: Node3D, rng: RandomNumberGenerator) -> void:
	var wood: StandardMaterial3D = _m(FoundryMaterials.Kind.WOOD)
	_box(root, Vector3(1.7, 0.5, 0.8), wood, Vector3(0.0, 0.25, 0.0))
	_box(root, Vector3(1.6, 0.04, 0.7), _m(FoundryMaterials.Kind.COAL), Vector3(0.0, 0.5, 0.0))
	for i: int in 5:
		var x: float = -0.64 + 0.32 * float(i)
		var height: float = rng.randf_range(0.35, 0.8)
		_cyl(root, 0.015, 0.02, height, _leaf_material(rng), Vector3(x, 0.5 + height * 0.5, rng.randf_range(-0.15, 0.15)), Vector3.ZERO, 6)
		_sphere(root, rng.randf_range(0.14, 0.24), _leaf_material(rng), Vector3(x, 0.5 + height, rng.randf_range(-0.15, 0.15)), Vector3(1.0, 0.8, 1.0))
	_cyl(root, 0.03, 0.03, 1.7, _m(FoundryMaterials.Kind.COPPER_OXIDIZED), Vector3(0.0, 0.62, -0.36), Vector3(0.0, 0.0, PI * 0.5), 8)
	Layers.add_static_box(root, Vector3(1.7, 0.6, 0.8), Vector3(0.0, 0.3, 0.0))


static func _produce_crates(root: Node3D, rng: RandomNumberGenerator) -> void:
	_crate_visual(root, Vector3(0.8, 0.45, 0.6), Vector3(-0.3, 0.0, 0.0), rng.randf_range(-0.2, 0.2))
	_crate_visual(root, Vector3(0.8, 0.45, 0.6), Vector3(0.45, 0.0, 0.1), rng.randf_range(-0.2, 0.2))
	var crops: Array[Color] = [Color(0.75, 0.3, 0.12), Color(0.85, 0.65, 0.2), Color(0.5, 0.25, 0.4)]
	for i: int in 10:
		var crop: StandardMaterial3D = StandardMaterial3D.new()
		crop.albedo_color = crops[rng.randi_range(0, crops.size() - 1)]
		var x: float = -0.3 if i < 5 else 0.45
		_sphere(root, 0.09, crop, Vector3(x + rng.randf_range(-0.28, 0.28), 0.48, rng.randf_range(-0.2, 0.2)))
	Layers.add_static_box(root, Vector3(1.6, 0.55, 0.75), Vector3(0.08, 0.27, 0.05))


static func _water_tank(root: Node3D, rng: RandomNumberGenerator) -> void:
	var copper: StandardMaterial3D = _m(FoundryMaterials.Kind.COPPER_OXIDIZED)
	var brass: StandardMaterial3D = _m(FoundryMaterials.Kind.BRASS)
	_cyl(root, 0.55, 0.55, 1.5, copper, Vector3(0.0, 0.95, 0.0), Vector3.ZERO, 16)
	_sphere(root, 0.55, brass, Vector3(0.0, 1.7, 0.0), Vector3(1.0, 0.45, 1.0))
	for angle: float in [0.6, 2.7, 4.8]:
		_cyl(root, 0.04, 0.04, 0.3, _m(FoundryMaterials.Kind.DARK_STEEL), Vector3(cos(angle) * 0.4, 0.15, sin(angle) * 0.4), Vector3.ZERO, 6)
	_torus(root, 0.53, 0.6, brass, Vector3(0.0, 0.6 + rng.randf_range(0.0, 0.6), 0.0))
	_gauge(root, Vector3(0.0, 1.2, 0.56), 0.1, rng)
	Layers.add_static_cylinder(root, 0.6, 2.0, Vector3.ZERO)


static func _trellis(root: Node3D, rng: RandomNumberGenerator) -> void:
	var wood: StandardMaterial3D = _m(FoundryMaterials.Kind.WOOD)
	for x: float in [-0.6, -0.2, 0.2, 0.6]:
		_box(root, Vector3(0.04, 1.8, 0.04), wood, Vector3(x, 1.1, 0.0))
	for y: float in [0.5, 1.0, 1.5]:
		_box(root, Vector3(1.4, 0.04, 0.04), wood, Vector3(0.0, y, 0.0))
	for i: int in rng.randi_range(6, 10):
		_sphere(root, rng.randf_range(0.1, 0.2), _leaf_material(rng), Vector3(rng.randf_range(-0.6, 0.6), rng.randf_range(0.4, 1.9), 0.05), Vector3(1.0, 0.8, 0.5))


static func _leaf_litter(root: Node3D, rng: RandomNumberGenerator) -> void:
	for i: int in rng.randi_range(5, 9):
		_box(root, Vector3(0.1, 0.01, 0.06), _leaf_material(rng), Vector3(rng.randf_range(-0.3, 0.3), 0.01, rng.randf_range(-0.3, 0.3)), Vector3(0.0, rng.randf_range(0.0, TAU), 0.0))


# --- Mine ---------------------------------------------------------------------------------

static func _pick_rack(root: Node3D, rng: RandomNumberGenerator) -> void:
	var wood: StandardMaterial3D = _m(FoundryMaterials.Kind.WOOD)
	var steel: StandardMaterial3D = _m(FoundryMaterials.Kind.DARK_STEEL)
	_box(root, Vector3(1.2, 0.08, 0.3), wood, Vector3(0.0, 1.1, -0.15))
	_box(root, Vector3(1.2, 0.08, 0.3), wood, Vector3(0.0, 0.2, -0.15))
	for x: float in [-0.55, 0.55]:
		_box(root, Vector3(0.08, 1.2, 0.08), wood, Vector3(x, 0.6, -0.25))
	for i: int in rng.randi_range(2, 4):
		var x: float = -0.35 + 0.25 * float(i)
		var lean: float = rng.randf_range(-0.15, 0.15)
		_cyl(root, 0.025, 0.025, 1.1, wood, Vector3(x, 0.65, -0.05), Vector3(0.15, 0.0, lean), 6)
		_box(root, Vector3(0.4, 0.05, 0.05), steel, Vector3(x - lean * 0.5, 1.18, -0.05), Vector3(0.0, 0.0, 0.25))
	Layers.add_static_box(root, Vector3(1.2, 1.2, 0.4), Vector3(0.0, 0.6, -0.15))


static func _timber_prop(root: Node3D, rng: RandomNumberGenerator) -> void:
	var wood: StandardMaterial3D = _m(FoundryMaterials.Kind.WOOD)
	var gap: float = rng.randf_range(0.9, 1.2)
	for x: float in [-gap * 0.5, gap * 0.5]:
		_box(root, Vector3(0.22, 2.6, 0.22), wood, Vector3(x, 1.3, 0.0))
	_box(root, Vector3(gap + 0.4, 0.24, 0.26), wood, Vector3(0.0, 2.55, 0.0))
	_box(root, Vector3(0.12, 0.8, 0.12), wood, Vector3(-gap * 0.5 + 0.2, 2.2, 0.0), Vector3(0.0, 0.0, -0.7))


# --- Tower ---------------------------------------------------------------------------------

static func _mooring_bollard(root: Node3D, rng: RandomNumberGenerator) -> void:
	var iron: StandardMaterial3D = _m(FoundryMaterials.Kind.CAST_IRON)
	_cyl(root, 0.3, 0.38, 0.8, iron, Vector3(0.0, 0.4, 0.0))
	_cyl(root, 0.42, 0.42, 0.1, iron, Vector3(0.0, 0.85, 0.0))
	_torus(root, 0.3, 0.42, _m(FoundryMaterials.Kind.FABRIC), Vector3(0.0, 0.3 + rng.randf_range(0.0, 0.3), 0.0))
	Layers.add_static_cylinder(root, 0.42, 0.9, Vector3.ZERO)


static func _rope_coil(root: Node3D, rng: RandomNumberGenerator) -> void:
	var rope: StandardMaterial3D = _m(FoundryMaterials.Kind.FABRIC)
	for i: int in rng.randi_range(4, 6):
		_torus(root, 0.25, 0.5 - 0.02 * float(i), rope, Vector3(0.0, 0.06 + 0.1 * float(i), 0.0))
	if rng.randf() < 0.5:
		_box(root, Vector3(0.9, 0.06, 0.06), rope, Vector3(0.5, 0.03, 0.2), Vector3(0.0, rng.randf_range(-0.8, 0.8), 0.0))
	Layers.add_static_cylinder(root, 0.5, 0.6, Vector3.ZERO)


# --- Archive -------------------------------------------------------------------------------

static func _drafting_table(root: Node3D, rng: RandomNumberGenerator) -> void:
	var wood: StandardMaterial3D = _m(FoundryMaterials.Kind.WOOD)
	var brass: StandardMaterial3D = _m(FoundryMaterials.Kind.BRASS)
	for x: float in [-0.6, 0.6]:
		_box(root, Vector3(0.08, 0.9, 0.6), wood, Vector3(x, 0.45, 0.0))
	_box(root, Vector3(1.5, 0.05, 0.9), wood, Vector3(0.0, 1.0, 0.0), Vector3(-0.35, 0.0, 0.0))
	_box(root, Vector3(1.1, 0.01, 0.7), FoundryMaterials.emissive(Color(0.2, 0.38, 0.75), 0.25), Vector3(0.0, 1.03, 0.0), Vector3(-0.35, 0.0, 0.0))
	_box(root, Vector3(1.4, 0.03, 0.04), brass, Vector3(0.0, 1.06, 0.1 + rng.randf_range(-0.2, 0.2)), Vector3(-0.35, 0.0, 0.0))
	_cyl(root, 0.02, 0.02, 0.6, brass, Vector3(0.55, 1.35, -0.3))
	_sphere(root, 0.08, FoundryMaterials.emissive(Color(1.0, 0.8, 0.45), 1.5), Vector3(0.55, 1.65, -0.2))
	Layers.add_static_box(root, Vector3(1.5, 1.1, 0.9), Vector3(0.0, 0.55, 0.0))


static func _map_chest(root: Node3D, rng: RandomNumberGenerator) -> void:
	var wood: StandardMaterial3D = _m(FoundryMaterials.Kind.WOOD)
	var brass: StandardMaterial3D = _m(FoundryMaterials.Kind.BRASS)
	_box(root, Vector3(1.4, 0.9, 0.8), wood, Vector3(0.0, 0.45, 0.0))
	var open_drawer: int = rng.randi_range(0, 4)
	for i: int in 5:
		var y: float = 0.12 + 0.17 * float(i)
		var pull: float = 0.25 if i == open_drawer else 0.0
		_box(root, Vector3(1.3, 0.13, 0.04), wood, Vector3(0.0, y, 0.41 + pull))
		_box(root, Vector3(0.2, 0.03, 0.03), brass, Vector3(0.0, y, 0.44 + pull))
	_box(root, Vector3(0.6, 0.01, 0.45), _m(FoundryMaterials.Kind.PAPER), Vector3(rng.randf_range(-0.3, 0.3), 0.91, 0.0), Vector3(0.0, rng.randf_range(-0.4, 0.4), 0.0))
	Layers.add_static_box(root, Vector3(1.4, 0.9, 0.8), Vector3(0.0, 0.45, 0.0))


static func _paper_drift(root: Node3D, rng: RandomNumberGenerator) -> void:
	var blueprint: StandardMaterial3D = FoundryMaterials.emissive(Color(0.2, 0.38, 0.75), 0.2)
	for i: int in rng.randi_range(4, 8):
		var mat: StandardMaterial3D = blueprint if rng.randf() < 0.35 else _m(FoundryMaterials.Kind.PAPER)
		_box(root, Vector3(0.3, 0.004, 0.22), mat, Vector3(rng.randf_range(-0.35, 0.35), 0.004 + 0.003 * float(i), rng.randf_range(-0.35, 0.35)), Vector3(0.0, rng.randf_range(0.0, TAU), 0.0))


# --- Generator -----------------------------------------------------------------------------

static func _coil_cabinet(root: Node3D, rng: RandomNumberGenerator) -> void:
	var steel: StandardMaterial3D = _m(FoundryMaterials.Kind.DARK_STEEL)
	var copper: StandardMaterial3D = _m(FoundryMaterials.Kind.COPPER_OXIDIZED)
	_box(root, Vector3(1.2, 1.8, 0.8), steel, Vector3(0.0, 0.9, 0.0))
	for i: int in 3:
		_cyl(root, 0.12, 0.12, 0.5, copper, Vector3(-0.35 + 0.35 * float(i), 2.05, 0.0))
		_sphere(root, 0.1, _m(FoundryMaterials.Kind.ARC_BLUE), Vector3(-0.35 + 0.35 * float(i), 2.35, 0.0))
	_box(root, Vector3(0.5, 0.3, 0.02), _m(FoundryMaterials.Kind.WARNING_RED), Vector3(0.0, 1.3, 0.41))
	_gauge(root, Vector3(0.35, 0.9, 0.41), 0.1, rng)
	Layers.add_static_box(root, Vector3(1.2, 1.8, 0.8), Vector3(0.0, 0.9, 0.0))


static func _insulator_stack(root: Node3D, rng: RandomNumberGenerator) -> void:
	var porcelain: StandardMaterial3D = _m(FoundryMaterials.Kind.GAUGE_FACE)
	var count: int = rng.randi_range(4, 6)
	for i: int in count:
		_cyl(root, 0.3, 0.38, 0.18, porcelain, Vector3(0.0, 0.12 + 0.24 * float(i), 0.0))
	_cyl(root, 0.06, 0.06, 0.4, _m(FoundryMaterials.Kind.COPPER_OXIDIZED), Vector3(0.0, 0.24 * float(count) + 0.2, 0.0))
	Layers.add_static_cylinder(root, 0.38, 0.24 * float(count) + 0.2, Vector3.ZERO)


static func _cable_bundle(root: Node3D, rng: RandomNumberGenerator) -> void:
	var rubber: StandardMaterial3D = _m(FoundryMaterials.Kind.DARK_STEEL)
	for i: int in rng.randi_range(3, 5):
		_cyl(root, 0.05, 0.05, 2.2, rubber, Vector3(0.0, 2.4 - 0.12 * float(i), 0.08), Vector3(0.0, 0.0, PI * 0.5), 6)
	for x: float in [-0.9, 0.0, 0.9]:
		_box(root, Vector3(0.08, 0.5, 0.12), _m(FoundryMaterials.Kind.BRASS), Vector3(x, 2.2, 0.06))
