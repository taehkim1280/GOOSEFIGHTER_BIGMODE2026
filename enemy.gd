extends CharacterBody3D

const SPEED = 3.0
var player: Node3D = null
var knockback_velocity = Vector3.ZERO

func _ready():
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	var final_velocity = Vector3.ZERO
	
	if player:
		# calculate chase direction
		var dir = (player.global_position - global_position).normalized()
		dir.y = 0 # keep it on the floor plane
		
		# only look at player if we aren't being launched away
		if knockback_velocity.length() < 2.0:
			look_at(global_position + dir, Vector3.UP)
		
		final_velocity = (dir * SPEED) + knockback_velocity

	velocity = final_velocity

	# increase the decay speed if they slide too far
	knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, 30.0 * delta)

	move_and_slide()

func apply_knockback(force: Vector3):
	# overwrite current knockback with the new blast force
	knockback_velocity = force
	
func die():
	queue_free()
