extends CharacterBody3D

const SPEED = 7.0

func _physics_process(_delta: float) -> void:
	# get input vector
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	# get dir in 3d space (x,y plane)
	var raw_dir := Vector3(input_dir.x, 0, input_dir.y)
	var direction := raw_dir.rotated(Vector3.UP, deg_to_rad(45)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		# rotate goose to face direction of movement
		# look at -> curr position + direction
		look_at(position + direction, Vector3.UP)
	else:
		# smooth deceleration
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
