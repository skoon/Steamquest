class_name ModelPalette
extends RefCounted
## The GLB packs name their materials (SP_MAT_BRASS, SP_MAT_IRON...) but were exported without
## base colours, so every surface imports white. This palette gives each named material its colour
## and roughness; metallic, emission and transparency from the file are kept.

## Material name -> [albedo, roughness]. Alpha in the albedo is ignored (the file's alpha is kept).
const COLORS: Dictionary = {
	&"SP_MAT_BAIZE": [Color(0.16, 0.35, 0.2), 0.9],
	&"SP_MAT_BRASS": [Color(0.78, 0.6, 0.28), 0.35],
	&"SP_MAT_CHARCOAL": [Color(0.12, 0.12, 0.13), 0.8],
	&"SP_MAT_COPPER": [Color(0.72, 0.4, 0.25), 0.4],
	&"SP_MAT_CREAM": [Color(0.9, 0.85, 0.72), 0.6],
	&"SP_MAT_CRIMSON": [Color(0.55, 0.08, 0.1), 0.6],
	&"SP_MAT_DARKBRASS": [Color(0.45, 0.33, 0.16), 0.45],
	&"SP_MAT_DARKWOOD": [Color(0.25, 0.14, 0.08), 0.5],
	&"SP_MAT_EYE_IRIS": [Color(0.25, 0.4, 0.55), 0.3],
	&"SP_MAT_EYE_SCLERA": [Color(0.95, 0.94, 0.9), 0.3],
	&"SP_MAT_GLASS_CLEAR": [Color(0.85, 0.92, 0.95), 0.05],
	&"SP_MAT_GLOW_AMBER": [Color(1.0, 0.68, 0.22), 0.4],
	&"SP_MAT_GLOW_TEAL": [Color(0.25, 1.0, 0.95), 0.4],
	&"SP_MAT_GOLD": [Color(0.95, 0.75, 0.3), 0.25],
	&"SP_MAT_HAIR_ASH": [Color(0.6, 0.58, 0.55), 0.7],
	&"SP_MAT_HAIR_BLACK": [Color(0.06, 0.05, 0.05), 0.7],
	&"SP_MAT_HAIR_BROWN": [Color(0.3, 0.18, 0.1), 0.7],
	&"SP_MAT_HAIR_RED": [Color(0.55, 0.2, 0.08), 0.7],
	&"SP_MAT_HAZARD_GOLD": [Color(0.9, 0.65, 0.1), 0.5],
	&"SP_MAT_IRON": [Color(0.25, 0.25, 0.27), 0.55],
	&"SP_MAT_LACE": [Color(0.92, 0.9, 0.85), 0.8],
	&"SP_MAT_LEATHER": [Color(0.4, 0.24, 0.13), 0.7],
	&"SP_MAT_LEATHER_DK": [Color(0.2, 0.12, 0.07), 0.7],
	&"SP_MAT_LIPS": [Color(0.6, 0.28, 0.28), 0.6],
	&"SP_MAT_MARBLE_CREAM": [Color(0.88, 0.85, 0.78), 0.3],
	&"SP_MAT_NAVY": [Color(0.12, 0.15, 0.3), 0.8],
	&"SP_MAT_OLIVE": [Color(0.35, 0.37, 0.18), 0.8],
	&"SP_MAT_PAPER": [Color(0.92, 0.88, 0.75), 0.9],
	&"SP_MAT_PLUM": [Color(0.35, 0.12, 0.28), 0.8],
	&"SP_MAT_RED": [Color(0.7, 0.12, 0.1), 0.5],
	&"SP_MAT_SHIRT": [Color(0.88, 0.86, 0.8), 0.85],
	&"SP_MAT_SKIN": [Color(0.87, 0.68, 0.55), 0.65],
	&"SP_MAT_SKIN_DK": [Color(0.5, 0.33, 0.22), 0.65],
	&"SP_MAT_STEAM": [Color(0.92, 0.93, 0.95), 0.9],
	&"SP_MAT_STEEL": [Color(0.55, 0.57, 0.6), 0.35],
	&"SP_MAT_STONE": [Color(0.5, 0.48, 0.45), 0.9],
	&"SP_MAT_TAN": [Color(0.7, 0.55, 0.38), 0.8],
	&"SP_MAT_TEAL": [Color(0.2, 0.75, 0.7), 0.3],
	&"SP_MAT_TROUSER": [Color(0.25, 0.22, 0.2), 0.85],
	&"SP_MAT_VELVET": [Color(0.45, 0.07, 0.12), 0.9],
	&"SP_MAT_VEST": [Color(0.35, 0.2, 0.12), 0.8],
	&"SP_MAT_WOOD": [Color(0.45, 0.28, 0.15), 0.6],
}


## Colours every palette material used by meshes under `node`. The imported materials are shared
## resources, so this recolours them for every later instance too.
static func apply(node: Node) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		var mesh: Mesh = (node as MeshInstance3D).mesh
		for surface: int in mesh.get_surface_count():
			_colour(mesh.surface_get_material(surface))
	for child: Node in node.get_children():
		apply(child)


static func _colour(material: Material) -> void:
	var standard: BaseMaterial3D = material as BaseMaterial3D
	if standard == null:
		return
	var key: StringName = StringName(standard.resource_name)
	assert(COLORS.has(key), "ModelPalette: no colour for material %s" % standard.resource_name)
	var entry: Array = COLORS[key]
	var albedo: Color = entry[0]
	standard.albedo_color = Color(albedo.r, albedo.g, albedo.b, standard.albedo_color.a)
	standard.roughness = entry[1]
