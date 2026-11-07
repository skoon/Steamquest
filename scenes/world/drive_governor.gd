class_name DriveGovernor
extends Area3D
## A flyball governor regulating the assembly line. Three wrench blows smash it.

signal smashed(governor: DriveGovernor)

@export var hits_required: int = 3
## FoundryBuilder keeps clutter this far away.
@export var radius: float = 1.0

var counter: HitCounter
var _spinner: Node3D
var _spin_speed: float = 6.0


func _ready() -> void:
	counter = HitCounter.new(hits_required)
	collision_layer = Layers.INTERACTABLES
	collision_mask = 0
	monitoring = false
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 0.9
	shape_node.shape = sphere
	shape_node.position = Vector3(0.0, 1.3, 0.0)
	add_child(shape_node)
	_build_visuals()


func is_smashed() -> bool:
	return counter.is_complete()


func _process(delta: float) -> void:
	_spinner.rotation.y += _spin_speed * delta


func receive_bash() -> void:
	if is_smashed():
		return
	var finished: bool = counter.register()
	Fx.sparks(get_parent(), global_position + Vector3.UP * 1.6)
	var tween: Tween = create_tween()
	tween.tween_property(_spinner, "scale", Vector3(1.2, 0.8, 1.2), 0.06)
	tween.tween_property(_spinner, "scale", Vector3.ONE, 0.12)
	if not finished:
		Audio.play_at(&"wrench_clang", global_position + Vector3.UP * 1.5)
		GameState.post_notice("The governor wobbles... (%d/%d)" % [counter.hits, counter.required])
		return
	_spin_speed = 0.0
	_spinner.rotation = Vector3(0.5, _spinner.rotation.y, 0.3)
	Fx.steam_puff(get_parent(), global_position + Vector3.UP * 1.6)
	Audio.play_at(&"governor_break", global_position + Vector3.UP * 1.5)
	smashed.emit(self)


func _build_visuals() -> void:
	var iron: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.CAST_IRON)
	var brass: StandardMaterial3D = FoundryMaterials.get_material(FoundryMaterials.Kind.BRASS)
	var housing: BoxMesh = BoxMesh.new()
	housing.size = Vector3(0.8, 1.0, 0.8)
	Layers.add_mesh(self, housing, iron, Vector3(0.0, 0.5, 0.0))
	var spindle: CylinderMesh = CylinderMesh.new()
	spindle.top_radius = 0.05
	spindle.bottom_radius = 0.05
	spindle.height = 1.2
	Layers.add_mesh(self, spindle, brass, Vector3(0.0, 1.6, 0.0))
	_spinner = Node3D.new()
	_spinner.position = Vector3(0.0, 1.6, 0.0)
	add_child(_spinner)
	var arm: BoxMesh = BoxMesh.new()
	arm.size = Vector3(0.6, 0.04, 0.04)
	var ball: SphereMesh = SphereMesh.new()
	ball.radius = 0.16
	ball.height = 0.32
	for side: float in [-1.0, 1.0]:
		var arm_instance: MeshInstance3D = Layers.add_mesh(_spinner, arm, brass, Vector3(side * 0.25, -0.1, 0.0))
		arm_instance.rotation = Vector3(0.0, 0.0, side * -0.5)
		Layers.add_mesh(_spinner, ball, brass, Vector3(side * 0.5, -0.25, 0.0))
	var cap: SphereMesh = SphereMesh.new()
	cap.radius = 0.12
	cap.height = 0.24
	Layers.add_mesh(self, cap, FoundryMaterials.get_material(FoundryMaterials.Kind.WARNING_RED), Vector3(0.0, 2.25, 0.0))
	Layers.add_static_box(self, Vector3(0.8, 1.0, 0.8), Vector3(0.0, 0.5, 0.0))
