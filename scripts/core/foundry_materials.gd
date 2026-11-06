class_name FoundryMaterials
extends RefCounted
## Shared StandardMaterial3D palette (cached so identical surfaces share one material).

enum Kind { BRASS, COPPER_OXIDIZED, CAST_IRON, DARK_STEEL, FURNACE_GLOW, GOLD, STEAM_GLASS, MOLTEN, WARNING_RED, ARC_BLUE, RUST, WOOD, COAL, SLAG_GLOW, GAUGE_FACE, PAPER, FABRIC, GLASS, VELVET }

static var _cache: Dictionary = {}


static func get_material(kind: Kind) -> StandardMaterial3D:
	if _cache.has(kind):
		return _cache[kind] as StandardMaterial3D
	var mat: StandardMaterial3D = _build(kind)
	_cache[kind] = mat
	return mat


static func textured(texture: Texture2D, tint: Color, uv_scale: Vector3) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_texture = texture
	mat.albedo_color = tint
	mat.uv1_scale = uv_scale
	mat.roughness = 0.75
	mat.metallic = 0.3
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return mat


static func emissive(color: Color, energy: float) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	return mat


static func _build(kind: Kind) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	match kind:
		Kind.BRASS:
			mat.albedo_color = Color(0.78, 0.58, 0.26)
			mat.metallic = 0.9
			mat.roughness = 0.35
		Kind.COPPER_OXIDIZED:
			mat.albedo_color = Color(0.34, 0.62, 0.53)
			mat.metallic = 0.6
			mat.roughness = 0.6
		Kind.CAST_IRON:
			mat.albedo_color = Color(0.17, 0.16, 0.16)
			mat.metallic = 0.7
			mat.roughness = 0.8
		Kind.DARK_STEEL:
			mat.albedo_color = Color(0.3, 0.31, 0.33)
			mat.metallic = 0.8
			mat.roughness = 0.5
		Kind.FURNACE_GLOW:
			mat.albedo_color = Color(1.0, 0.45, 0.1)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.5, 0.12)
			mat.emission_energy_multiplier = 4.0
		Kind.GOLD:
			mat.albedo_color = Color(1.0, 0.82, 0.3)
			mat.metallic = 1.0
			mat.roughness = 0.12
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.75, 0.25)
			mat.emission_energy_multiplier = 1.6
		Kind.STEAM_GLASS:
			mat.albedo_color = Color(0.9, 0.95, 1.0, 0.35)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		Kind.MOLTEN:
			mat.albedo_color = Color(1.0, 0.35, 0.05)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.4, 0.05)
			mat.emission_energy_multiplier = 6.0
		Kind.WARNING_RED:
			mat.albedo_color = Color(1.0, 0.15, 0.1, 0.55)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		Kind.ARC_BLUE:
			mat.albedo_color = Color(0.5, 0.9, 1.0)
			mat.emission_enabled = true
			mat.emission = Color(0.45, 0.85, 1.0)
			mat.emission_energy_multiplier = 5.0
		Kind.RUST:
			mat.albedo_color = Color(0.45, 0.24, 0.13)
			mat.metallic = 0.4
			mat.roughness = 0.9
		Kind.WOOD:
			mat.albedo_color = Color(0.34, 0.22, 0.13)
			mat.metallic = 0.0
			mat.roughness = 0.88
		Kind.COAL:
			mat.albedo_color = Color(0.05, 0.05, 0.055)
			mat.metallic = 0.15
			mat.roughness = 0.55
		Kind.SLAG_GLOW:
			mat.albedo_color = Color(1.0, 0.32, 0.05)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.35, 0.05)
			mat.emission_energy_multiplier = 2.5
		Kind.GAUGE_FACE:
			mat.albedo_color = Color(0.92, 0.86, 0.7)
			mat.roughness = 0.4
			mat.emission_enabled = true
			mat.emission = Color(0.92, 0.8, 0.55)
			mat.emission_energy_multiplier = 0.35
		Kind.PAPER:
			mat.albedo_color = Color(0.86, 0.8, 0.66)
			mat.roughness = 0.95
		Kind.FABRIC:
			mat.albedo_color = Color(0.52, 0.42, 0.28)
			mat.roughness = 1.0
		Kind.GLASS:
			mat.albedo_color = Color(0.75, 0.9, 0.95, 0.3)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.metallic = 0.2
			mat.roughness = 0.05
		Kind.VELVET:
			mat.albedo_color = Color(0.42, 0.08, 0.1)
			mat.roughness = 0.95
	return mat
