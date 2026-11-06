class_name Fx
extends RefCounted
## Procedural GPUParticles3D effects: steam puffs, gear sparks and ember drift.

static var _soft_texture: GradientTexture2D


static func soft_texture() -> GradientTexture2D:
	if _soft_texture != null:
		return _soft_texture
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	_soft_texture = GradientTexture2D.new()
	_soft_texture.gradient = gradient
	_soft_texture.fill = GradientTexture2D.FILL_RADIAL
	_soft_texture.fill_from = Vector2(0.5, 0.5)
	_soft_texture.fill_to = Vector2(1.0, 0.5)
	_soft_texture.width = 64
	_soft_texture.height = 64
	return _soft_texture


static func _draw_mesh(size: float, additive: bool) -> QuadMesh:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = soft_texture()
	if additive:
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(size, size)
	quad.material = mat
	return quad


static func _fade_ramp(color: Color) -> GradientTexture1D:
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, color)
	gradient.set_color(1, Color(color.r, color.g, color.b, 0.0))
	var ramp: GradientTexture1D = GradientTexture1D.new()
	ramp.gradient = gradient
	return ramp


## Continuous upward steam column; toggle `emitting` to control it.
static func make_steam_emitter(amount: int, lifetime: float, speed: float, spread_degrees: float) -> GPUParticles3D:
	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.amount = amount
	particles.lifetime = lifetime
	var process: ParticleProcessMaterial = ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = spread_degrees
	process.initial_velocity_min = speed * 0.6
	process.initial_velocity_max = speed
	process.gravity = Vector3(0.0, 0.6, 0.0)
	process.damping_min = 1.0
	process.damping_max = 2.0
	process.scale_min = 0.6
	process.scale_max = 1.4
	var scale_curve: CurveTexture = CurveTexture.new()
	var curve: Curve = Curve.new()
	curve.add_point(Vector2(0.0, 0.4))
	curve.add_point(Vector2(1.0, 1.6))
	scale_curve.curve = curve
	process.scale_curve = scale_curve
	process.color_ramp = _fade_ramp(Color(0.92, 0.92, 0.9, 0.55))
	particles.process_material = process
	particles.draw_pass_1 = _draw_mesh(0.9, false)
	particles.visibility_aabb = AABB(Vector3(-4, -1, -4), Vector3(8, 10, 8))
	return particles


static func make_ember_emitter(amount: int) -> GPUParticles3D:
	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.amount = amount
	particles.lifetime = 2.2
	var process: ParticleProcessMaterial = ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(0.8, 0.2, 0.4)
	process.direction = Vector3.UP
	process.spread = 25.0
	process.initial_velocity_min = 0.8
	process.initial_velocity_max = 2.0
	process.gravity = Vector3(0.0, 0.3, 0.0)
	process.scale_min = 0.5
	process.scale_max = 1.0
	process.color_ramp = _fade_ramp(Color(1.0, 0.55, 0.15, 1.0))
	particles.process_material = process
	particles.draw_pass_1 = _draw_mesh(0.12, true)
	return particles


## One-shot burst that frees itself once finished.
static func burst(parent: Node, position: Vector3, color: Color, amount: int, speed: float, size: float, gravity: float) -> void:
	assert(parent != null, "Fx.burst: parent required")
	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.amount = amount
	particles.lifetime = 0.6
	var process: ParticleProcessMaterial = ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = 180.0
	process.initial_velocity_min = speed * 0.4
	process.initial_velocity_max = speed
	process.gravity = Vector3(0.0, gravity, 0.0)
	process.damping_min = 2.0
	process.damping_max = 4.0
	process.color_ramp = _fade_ramp(color)
	particles.process_material = process
	# Saturated colours (sparks, arcs) glow additively; near-white steam blends normally.
	particles.draw_pass_1 = _draw_mesh(size, color.s > 0.3)
	parent.add_child(particles)
	particles.global_position = position
	particles.emitting = true
	particles.finished.connect(particles.queue_free)


## Soft dark disc under billboarded characters (sprites themselves cast no shadow).
static func make_blob_shadow(radius: float) -> MeshInstance3D:
	var shadow: MeshInstance3D = MeshInstance3D.new()
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(radius * 2.0, radius * 2.0)
	quad.orientation = PlaneMesh.FACE_Y
	shadow.mesh = quad
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.0, 0.0, 0.0, 0.55)
	mat.albedo_texture = soft_texture()
	shadow.material_override = mat
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shadow.position = Vector3(0.0, 0.03, 0.0)
	shadow.name = "BlobShadow"
	return shadow


static func sparks(parent: Node, position: Vector3) -> void:
	burst(parent, position, Color(1.0, 0.8, 0.35, 1.0), 18, 6.0, 0.1, -9.8)


static func steam_puff(parent: Node, position: Vector3) -> void:
	burst(parent, position, Color(0.9, 0.9, 0.88, 0.6), 22, 3.0, 0.8, 1.0)


static func arc_sparks(parent: Node, position: Vector3) -> void:
	burst(parent, position, Color(0.55, 0.9, 1.0, 1.0), 16, 5.0, 0.12, -4.0)
