class_name GearMeshFactory
extends RefCounted
## Builds toothed cog visuals from primitives. The cog lies flat (axis = local Y).


static func build(radius: float, thickness: float, teeth: int, material: Material) -> Node3D:
	assert(radius > 0.0 and thickness > 0.0 and teeth >= 3, "GearMeshFactory.build: invalid dimensions")
	var root: Node3D = Node3D.new()
	root.name = "Cog"

	var rim: MeshInstance3D = MeshInstance3D.new()
	var rim_mesh: CylinderMesh = CylinderMesh.new()
	rim_mesh.top_radius = radius
	rim_mesh.bottom_radius = radius
	rim_mesh.height = thickness
	rim_mesh.radial_segments = maxi(teeth * 2, 16)
	rim.mesh = rim_mesh
	rim.material_override = material
	root.add_child(rim)

	var hub: MeshInstance3D = MeshInstance3D.new()
	var hub_mesh: CylinderMesh = CylinderMesh.new()
	hub_mesh.top_radius = radius * 0.28
	hub_mesh.bottom_radius = radius * 0.28
	hub_mesh.height = thickness * 1.6
	hub.mesh = hub_mesh
	hub.material_override = FoundryMaterials.get_material(FoundryMaterials.Kind.CAST_IRON)
	root.add_child(hub)

	var tooth_mesh: BoxMesh = BoxMesh.new()
	var tooth_width: float = TAU * radius / float(teeth) * 0.5
	tooth_mesh.size = Vector3(tooth_width, thickness, radius * 0.22)
	for i: int in teeth:
		var angle: float = TAU * float(i) / float(teeth)
		var tooth: MeshInstance3D = MeshInstance3D.new()
		tooth.mesh = tooth_mesh
		tooth.material_override = material
		tooth.rotation.y = angle
		tooth.position = Vector3(sin(angle), 0.0, cos(angle)) * (radius + radius * 0.09)
		root.add_child(tooth)
	return root
