extends CharacterBody3D

@export var run_speed: float = 9.0
@export var jump_speed: float = 9.0
@export var gravity: float = 21.0
@export var lane_width: float = 2.5

var _lane: int = 1
var _controls_enabled: bool = true


func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	floor_snap_length = 0.15
	_build_character()


func _physics_process(delta: float) -> void:
	if not _controls_enabled:
		velocity = Vector3.ZERO
		return

	if Input.is_action_just_pressed("lane_left"):
		_lane = maxi(0, _lane - 1)
	if Input.is_action_just_pressed("lane_right"):
		_lane = mini(2, _lane + 1)

	var target_x := float(_lane - 1) * lane_width
	velocity.x = clampf((target_x - global_position.x) * 12.0, -10.0, 10.0)
	velocity.z = -run_speed

	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_speed
	else:
		velocity.y -= gravity * delta

	move_and_slide()


func set_controls_enabled(enabled: bool) -> void:
	_controls_enabled = enabled


func _build_character() -> void:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.42
	shape.height = 1.75

	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position.y = 0.88
	add_child(collider)

	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = Color(0.12, 0.84, 1.0)
	body_material.metallic = 0.3
	body_material.roughness = 0.25
	body_material.emission_enabled = true
	body_material.emission = Color(0.04, 0.55, 0.8)
	body_material.emission_energy_multiplier = 0.45

	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.42
	body_mesh.height = 1.75

	var body := MeshInstance3D.new()
	body.name = "RunnerBody"
	body.mesh = body_mesh
	body.material_override = body_material
	body.position.y = 0.88
	add_child(body)

	var visor_material := StandardMaterial3D.new()
	visor_material.albedo_color = Color(0.035, 0.07, 0.16)
	visor_material.metallic = 0.6
	visor_material.roughness = 0.2

	var visor_mesh := BoxMesh.new()
	visor_mesh.size = Vector3(0.48, 0.22, 0.1)
	var visor := MeshInstance3D.new()
	visor.name = "Visor"
	visor.mesh = visor_mesh
	visor.material_override = visor_material
	visor.position = Vector3(0.0, 1.22, -0.37)
	add_child(visor)
