extends CharacterBody3D

const SPEED = 7
var ATTACK_RANGE = 3

var current_indicator: Node3D = null

@export var attack_line_scene: PackedScene
@export var explosion_scene: PackedScene
@onready var camera = get_viewport().get_camera_3d()

func _process(_delta):
	if is_instance_valid(current_indicator):
		var pos = get_mouse_3d_position()
		if pos != Vector3.ZERO:
			current_indicator.global_position = pos

func _physics_process(_delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var raw_dir := Vector3(input_dir.x, 0, input_dir.y)
	var direction := raw_dir.rotated(Vector3.UP, deg_to_rad(45)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		look_at(position + direction, Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
func _input(event):
	if event.is_action_pressed("ui_accept"): # spacebar
		attack_towards_mouse()
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if current_indicator == null:
			spawn_explosion_sequence()

func attack_towards_mouse():
	var target_pos = get_mouse_3d_position()
	if target_pos == Vector3.ZERO: return
	
	# calculate vector from goose to mouse
	var diff = target_pos - global_position
	var attack_dir_2d = Vector2(diff.x, diff.z).normalized()	
	
	# [DEBUG]
	print("Attacking towards: ", target_pos)
	var line = attack_line_scene.instantiate()
	get_parent().add_child(line) # Add to World, not Goose

	line.global_position = global_position + Vector3(0, 0.5, 0)
	
	var attack_dir_3d = Vector3(attack_dir_2d.x, 0, attack_dir_2d.y)
	line.look_at(line.global_position + attack_dir_3d, Vector3.UP)
	line.scale.z = ATTACK_RANGE
	get_tree().create_timer(0.1).timeout.connect(line.queue_free)
	# [/DEBUG]
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	print("Enemies in group: ", enemies.size())
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= ATTACK_RANGE:
			var enemy_diff = enemy.global_position - global_position
			var to_enemy_2d = Vector2(enemy_diff.x, enemy_diff.z).normalized()
			
			if attack_dir_2d.dot(to_enemy_2d) > 0.7:
				enemy.die()

func get_mouse_3d_position() -> Vector3:
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_direction = camera.project_ray_normal(mouse_pos)
	
	# intersect with a horizontal plane at y=1 (where geese live)
	var plane = Plane(Vector3.UP, 1.0)
	var intersection = plane.intersects_ray(ray_origin, ray_direction)
	
	return intersection if intersection else Vector3.ZERO

func spawn_explosion_sequence():
	current_indicator = explosion_scene.instantiate()
	get_parent().add_child(current_indicator)
	current_indicator.set_as_faint(true)
	
	await get_tree().create_timer(0.3).timeout
	
	if is_instance_valid(current_indicator):
		var locked_pos = current_indicator.global_position
		current_indicator.start_charge_sequence(locked_pos)
		current_indicator = null
