class_name Projectile
extends Area3D
## Straight-flying Area3D projectile. Sweeps a ray each physics step so fast rivets never tunnel.
## Anything it hits that implements `receive_hit(damage: float, knockback: Vector3)` takes damage
## (or `receive_projectile_hit`, with the same arguments, when it treats shots differently).

enum ImpactFx { SPARKS, ARC }

@export var impact_fx: ImpactFx = ImpactFx.SPARKS

var direction: Vector3 = Vector3.FORWARD
var speed: float = 20.0
var damage: float = 10.0
var knockback_force: float = 2.0
var lifetime: float = 1.0
var _age: float = 0.0
var _spent: bool = false


func _ready() -> void:
	monitorable = false
	body_entered.connect(_on_body_entered)


func launch(origin: Vector3, p_direction: Vector3, p_speed: float, p_damage: float, p_knockback: float, p_lifetime: float) -> void:
	assert(p_direction.length_squared() > 0.0, "Projectile.launch: direction must be non-zero")
	direction = p_direction.normalized()
	speed = p_speed
	damage = p_damage
	knockback_force = p_knockback
	lifetime = p_lifetime
	global_position = origin
	look_at(origin + direction, Vector3.UP)


func _physics_process(delta: float) -> void:
	if _spent:
		return
	var from: Vector3 = global_position
	var to: Vector3 = from + direction * speed * delta
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to, collision_mask)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		_impact(hit["collider"] as Object, hit["position"] as Vector3)
		return
	global_position = to
	_age += delta
	if _age >= lifetime:
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	_impact(body, global_position)


func _impact(collider: Object, point: Vector3) -> void:
	if _spent:
		return
	_spent = true
	# Targets that react differently to shots (a sentry's shield staggering) take them separately.
	if collider != null and collider.has_method("receive_projectile_hit"):
		collider.call("receive_projectile_hit", damage, direction * knockback_force)
	elif collider != null and collider.has_method("receive_hit"):
		collider.call("receive_hit", damage, direction * knockback_force)
	var fx_parent: Node = get_parent()
	match impact_fx:
		ImpactFx.SPARKS:
			Fx.sparks(fx_parent, point)
			Audio.play_at(&"rivet_ting", point)
		ImpactFx.ARC:
			Fx.arc_sparks(fx_parent, point)
	queue_free()
