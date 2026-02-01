extends CharacterBody3D

const SPEED = 3.0
var player: Node3D = null
var knockback_velocity = Vector3.ZERO

func _ready():
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	var final_velocity = Vector3.ZERO
	var is_being_knocked_back = knockback_velocity.length() > 1.5
	
	if player and not is_being_knocked_back:
		var dir = (player.global_position - global_position).normalized()
		dir.y = 0
		#if knockback_velocity.length() < 2.0:
			#look_at(global_position + dir, Vector3.UP)
		look_at(global_position + dir, Vector3.UP)
		final_velocity = (dir * SPEED) + knockback_velocity

	velocity = final_velocity + knockback_velocity

	if move_and_slide():
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			# Only bounce if the knockback is active
			if is_being_knocked_back:
				# Use the normal to reflect the vector
				knockback_velocity = knockback_velocity.bounce(collision.get_normal()) * 0.8
	# delta is le friction 
	knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, 15.0 * delta)

func apply_knockback(force: Vector3):
	# overwrite current knockback with the new blast force
	knockback_velocity = force
	
func die():
	queue_free()
