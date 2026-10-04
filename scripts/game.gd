extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")

const LANE_WIDTH: float = 2.5
const START_Z: float = 8.0
const FINISH_Z: float = -70.0
const COURSE_LENGTH: float = START_Z - FINISH_Z
const TRACK_MID_Z: float = -31.0
const TRACK_LENGTH: float = 100.0

var player: CharacterBody3D
var game_camera: Camera3D
var distance_label: Label
var gems_label: Label
var result_label: Label
var retry_button: Button
var gem_count: int = 0
var ended: bool = false


func _ready() -> void:
	_configure_input()
	_build_environment()
	_build_track()
	_build_decor()
	_build_obstacles()
	_spawn_player()
	_setup_camera()
	_build_hud()
	_update_hud()


func _process(delta: float) -> void:
	if player == null:
		return

	if game_camera != null:
		var camera_target := player.global_position + Vector3(0.0, 5.4, 9.5)
		game_camera.global_position = game_camera.global_position.lerp(camera_target, 1.0 - exp(-delta * 4.5))
		game_camera.look_at(player.global_position + Vector3(0.0, 1.0, -3.5), Vector3.UP)

	for coin in get_tree().get_nodes_in_group("gems"):
		coin.rotate_y(delta * 1.8)

	if not ended:
		_update_hud()
		if player.global_position.z <= FINISH_Z:
			_finish(true)


func _configure_input() -> void:
	_ensure_key_action("lane_left", [KEY_A, KEY_LEFT])
	_ensure_key_action("lane_right", [KEY_D, KEY_RIGHT])
	_ensure_key_action("jump", [KEY_SPACE, KEY_UP, KEY_W])


func _ensure_key_action(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_set_deadzone(action, 0.2)
	for key_code in keys:
		var event := InputEventKey.new()
		event.physical_keycode = int(key_code)
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)


func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.025, 0.035, 0.085)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.48, 0.58, 0.82)
	environment.ambient_light_energy = 0.72
	world.environment = environment
	add_child(world)

	var sunlight := DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	sunlight.light_energy = 1.35
	sunlight.shadow_enabled = false
	add_child(sunlight)



func _spawn_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Runner"
	player.set_script(PLAYER_SCRIPT)
	player.position = Vector3(0.0, 0.02, START_Z)
	player.set("lane_width", LANE_WIDTH)
	player.set("run_speed", 9.0)
	add_child(player)


func _setup_camera() -> void:
	game_camera = Camera3D.new()
	game_camera.name = "FollowCamera"
	game_camera.fov = 68.0
	game_camera.current = true
	game_camera.position = Vector3(0.0, 5.4, START_Z + 9.5)
	add_child(game_camera)
	game_camera.look_at(player.global_position + Vector3(0.0, 1.0, -3.5), Vector3.UP)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)

	var root := Control.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	layer.add_child(root)

	var title := _make_label(root, "NEON TRAIL", Vector2(26.0, 20.0), Vector2(320.0, 48.0), 32, Color(0.88, 0.97, 1.0))
	title.add_theme_color_override("font_shadow_color", Color(0.02, 0.28, 0.45, 0.8))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	_make_label(root, "DODGE  /  JUMP  /  COLLECT", Vector2(29.0, 62.0), Vector2(340.0, 28.0), 15, Color(0.42, 0.78, 0.94))

	distance_label = Label.new()
	distance_label.anchor_left = 1.0
	distance_label.anchor_right = 1.0
	distance_label.offset_left = -330.0
	distance_label.offset_right = -26.0
	distance_label.offset_top = 24.0
	distance_label.offset_bottom = 58.0
	distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	distance_label.add_theme_font_size_override("font_size", 22)
	distance_label.add_theme_color_override("font_color", Color(0.87, 0.96, 1.0))
	root.add_child(distance_label)

	gems_label = Label.new()
	gems_label.anchor_left = 1.0
	gems_label.anchor_right = 1.0
	gems_label.offset_left = -330.0
	gems_label.offset_right = -26.0
	gems_label.offset_top = 58.0
	gems_label.offset_bottom = 86.0
	gems_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	gems_label.add_theme_font_size_override("font_size", 17)
	gems_label.add_theme_color_override("font_color", Color(1.0, 0.74, 0.27))
	root.add_child(gems_label)

	var hint := Label.new()
	hint.anchor_left = 0.2
	hint.anchor_right = 0.8
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.offset_left = 0.0
	hint.offset_right = 0.0
	hint.offset_top = -62.0
	hint.offset_bottom = -28.0
	hint.text = "A / D or LEFT / RIGHT to dodge     SPACE / UP to jump"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.68, 0.8, 0.92))
	root.add_child(hint)

	result_label = Label.new()
	result_label.anchor_left = 0.12
	result_label.anchor_right = 0.88
	result_label.anchor_top = 0.37
	result_label.anchor_bottom = 0.51
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 38)
	result_label.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	result_label.visible = false
	root.add_child(result_label)

	retry_button = Button.new()
	retry_button.text = "RUN IT BACK"
	retry_button.anchor_left = 0.5
	retry_button.anchor_right = 0.5
	retry_button.anchor_top = 0.54
	retry_button.anchor_bottom = 0.54
	retry_button.offset_left = -112.0
	retry_button.offset_right = 112.0
	retry_button.offset_top = 0.0
	retry_button.offset_bottom = 58.0
	retry_button.focus_mode = Control.FOCUS_NONE
	retry_button.add_theme_font_size_override("font_size", 19)
	retry_button.add_theme_color_override("font_color", Color(0.96, 0.99, 1.0))
	_style_button(retry_button, Color(0.12, 0.84, 1.0))
	retry_button.visible = false
	retry_button.pressed.connect(_restart)
	root.add_child(retry_button)

	_make_action_button(root, "←", "lane_left", 0.0, 26.0, 104.0, Color(0.08, 0.82, 1.0))
	_make_action_button(root, "→", "lane_right", 0.0, 116.0, 194.0, Color(0.08, 0.82, 1.0))
	_make_action_button(root, "JUMP", "jump", 1.0, -136.0, -26.0, Color(1.0, 0.28, 0.65))


func _make_action_button(parent: Control, text: String, action: StringName, horizontal_anchor: float, left_offset: float, right_offset: float, accent: Color) -> void:
	var button := Button.new()
	button.text = text
	button.anchor_left = horizontal_anchor
	button.anchor_right = horizontal_anchor
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = left_offset
	button.offset_right = right_offset
	button.offset_top = -112.0
	button.offset_bottom = -28.0
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0))
	_style_button(button, accent)
	button.button_down.connect(func() -> void: Input.action_press(action))
	button.button_up.connect(func() -> void: Input.action_release(action))
	parent.add_child(button)


func _style_button(button: Button, accent: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.035, 0.08, 0.16, 0.86)
	normal.border_color = accent
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(18)
	button.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.08, 0.17, 0.28, 0.96)
	button.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.1, 0.28, 0.4, 0.98)
	button.add_theme_stylebox_override("pressed", pressed)


func _make_label(parent: Control, text: String, position: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	label.size = label_size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _build_track() -> void:
	var track_material := _make_material(Color(0.055, 0.085, 0.16), 0.05, 0.42)
	var rail_material := _make_material(Color(0.08, 0.2, 0.34), 0.12, 0.55)
	var cyan_material := _make_material(Color(0.08, 0.82, 1.0), 0.85, 0.12)
	var blue_line_material := _make_material(Color(0.14, 0.34, 0.68), 0.45, 0.1)

	_add_static_box("Runway", Vector3(0.0, -0.25, TRACK_MID_Z), Vector3(10.0, 0.5, TRACK_LENGTH), track_material)
	_add_static_box("LeftRail", Vector3(-4.88, 0.45, TRACK_MID_Z), Vector3(0.18, 0.9, TRACK_LENGTH), rail_material)
	_add_static_box("RightRail", Vector3(4.88, 0.45, TRACK_MID_Z), Vector3(0.18, 0.9, TRACK_LENGTH), rail_material)

	_add_visual_box(self, "LeftNeonEdge", Vector3(-4.62, 0.025, TRACK_MID_Z), Vector3(0.06, 0.035, TRACK_LENGTH), cyan_material)
	_add_visual_box(self, "RightNeonEdge", Vector3(4.62, 0.025, TRACK_MID_Z), Vector3(0.06, 0.035, TRACK_LENGTH), cyan_material)
	_add_visual_box(self, "LeftLaneMark", Vector3(-LANE_WIDTH * 0.5, 0.015, TRACK_MID_Z), Vector3(0.035, 0.025, TRACK_LENGTH - 2.0), blue_line_material)
	_add_visual_box(self, "RightLaneMark", Vector3(LANE_WIDTH * 0.5, 0.015, TRACK_MID_Z), Vector3(0.035, 0.025, TRACK_LENGTH - 2.0), blue_line_material)

	_add_gate(4.2, _make_material(Color(0.08, 0.82, 1.0), 1.15, 0.15))
	_add_gate(FINISH_Z, _make_material(Color(1.0, 0.22, 0.68), 1.25, 0.15))

	var finish_stripe_a := _make_material(Color(0.9, 0.97, 1.0), 0.3, 0.05)
	var finish_stripe_b := _make_material(Color(0.08, 0.82, 1.0), 0.95, 0.1)
	for index in range(12):
		var stripe_material: Material = finish_stripe_a if index % 2 == 0 else finish_stripe_b
		var x_position := -4.25 + float(index) * 0.77
		_add_visual_box(self, "FinishStripe_%02d" % index, Vector3(x_position, 0.03, FINISH_Z), Vector3(0.72, 0.04, 0.3), stripe_material)


func _build_decor() -> void:
	var cyan := _make_material(Color(0.04, 0.8, 1.0), 1.0, 0.1)
	var pink := _make_material(Color(1.0, 0.16, 0.55), 1.0, 0.1)
	var gold := _make_material(Color(1.0, 0.68, 0.13), 0.8, 0.1)

	for index in range(9):
		var z_position := 12.0 - float(index) * 9.5
		var beacon_material: Material = cyan if index % 2 == 0 else pink
		_add_visual_box(self, "BeaconLeft_%02d" % index, Vector3(-5.55, 1.35, z_position), Vector3(0.14, 2.7, 0.14), beacon_material)
		_add_visual_box(self, "BeaconRight_%02d" % index, Vector3(5.55, 1.35, z_position), Vector3(0.14, 2.7, 0.14), gold if index % 2 == 0 else cyan)


func _build_obstacles() -> void:
	var patterns: Array[Dictionary] = [
		{"lane": 1, "z": -1.0},
		{"lane": 0, "z": -10.0},
		{"lane": 2, "z": -19.0},
		{"lane": 1, "z": -28.0},
		{"lane": 0, "z": -37.0},
		{"lane": 2, "z": -46.0},
		{"lane": 1, "z": -55.0},
		{"lane": 0, "z": -63.0},
	]
	for index in range(patterns.size()):
		var obstacle: Dictionary = patterns[index]
		var lane: int = int(obstacle["lane"])
		var z_position: float = float(obstacle["z"])
		_add_hazard(lane, z_position, index)
		_add_gem((lane + 1 + (index % 2)) % 3, z_position - 2.2)


func _add_hazard(lane: int, z_position: float, index: int) -> void:
	var hazard := Area3D.new()
	hazard.name = "Hazard_%02d" % index
	hazard.collision_layer = 0
	hazard.collision_mask = 1
	hazard.position = Vector3(float(lane - 1) * LANE_WIDTH, 0.0, z_position)

	var shape := BoxShape3D.new()
	shape.size = Vector3(1.82, 1.12, 1.0)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position.y = 0.56
	hazard.add_child(collider)

	var hazard_material := _make_material(Color(1.0, 0.19, 0.42), 0.65, 0.12)
	var block_mesh := BoxMesh.new()
	block_mesh.size = shape.size
	var block := MeshInstance3D.new()
	block.mesh = block_mesh
	block.material_override = hazard_material
	block.position.y = 0.56
	hazard.add_child(block)

	var stripe_mesh := BoxMesh.new()
	stripe_mesh.size = Vector3(1.84, 0.1, 1.02)
	var stripe := MeshInstance3D.new()
	stripe.mesh = stripe_mesh
	stripe.material_override = _make_material(Color(1.0, 0.74, 0.28), 0.95, 0.08)
	stripe.position = Vector3(0.0, 1.12, 0.0)
	hazard.add_child(stripe)

	add_child(hazard)
	hazard.body_entered.connect(_on_hazard_body_entered)


func _add_gem(lane: int, z_position: float) -> void:
	var gem := Area3D.new()
	gem.name = "Gem"
	gem.add_to_group("gems")
	gem.collision_layer = 0
	gem.collision_mask = 1
	gem.position = Vector3(float(lane - 1) * LANE_WIDTH, 0.0, z_position)

	var shape := SphereShape3D.new()
	shape.radius = 0.62
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position.y = 1.45
	gem.add_child(collider)

	var material := _make_material(Color(1.0, 0.72, 0.16), 1.15, 0.22)
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.34
	sphere_mesh.height = 0.68
	var visual := MeshInstance3D.new()
	visual.mesh = sphere_mesh
	visual.material_override = material
	visual.position.y = 1.45
	gem.add_child(visual)

	add_child(gem)
	gem.body_entered.connect(_on_gem_body_entered.bind(gem))


func _add_gate(z_position: float, material: Material) -> void:
	_add_visual_box(self, "GateLeft", Vector3(-4.18, 1.95, z_position), Vector3(0.18, 3.9, 0.22), material)
	_add_visual_box(self, "GateRight", Vector3(4.18, 1.95, z_position), Vector3(0.18, 3.9, 0.22), material)
	_add_visual_box(self, "GateTop", Vector3(0.0, 3.88, z_position), Vector3(8.5, 0.18, 0.22), material)


func _add_static_box(node_name: String, box_position: Vector3, box_size: Vector3, material: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = box_position

	var shape := BoxShape3D.new()
	shape.size = box_size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)

	var mesh := BoxMesh.new()
	mesh.size = box_size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material
	body.add_child(visual)

	add_child(body)
	return body


func _add_visual_box(parent: Node3D, node_name: String, box_position: Vector3, box_size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = box_size
	var visual := MeshInstance3D.new()
	visual.name = node_name
	visual.mesh = mesh
	visual.material_override = material
	visual.position = box_position
	parent.add_child(visual)
	return visual


func _make_material(color: Color, glow: float = 0.0, metal: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.36
	material.metallic = metal
	if glow > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = glow
	return material


func _on_hazard_body_entered(body: Node3D) -> void:
	if body == player:
		_finish(false)


func _on_gem_body_entered(body: Node3D, gem: Area3D) -> void:
	if body != player or not is_instance_valid(gem):
		return
	if gem.get_meta("collected", false):
		return
	gem.set_meta("collected", true)
	gem_count += 1
	gem.queue_free()
	_update_hud()


func _update_hud() -> void:
	if distance_label == null or gems_label == null or player == null:
		return
	var travelled := clampf(START_Z - player.global_position.z, 0.0, COURSE_LENGTH)
	var percent := roundi((travelled / COURSE_LENGTH) * 100.0)
	distance_label.text = "COURSE  %02d%%" % percent
	gems_label.text = "GEMS  %02d" % gem_count


func _finish(won: bool) -> void:
	if ended:
		return
	ended = true
	player.call("set_controls_enabled", false)
	result_label.text = "COURSE COMPLETE!" if won else "OOPS! TRY AGAIN"
	retry_button.visible = true


func _restart() -> void:
	get_tree().reload_current_scene()
