extends CharacterBody3D

const SPEED = 3.0
var player: Node3D = null
var knockback_velocity = Vector3.ZERO

var health_percent: float = 0.0
@onready var label = $Label3D

func _ready():
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")
	update_label()

func _physics_process(delta):
	var final_velocity = Vector3.ZERO
	var is_being_knocked_back = knockback_velocity.length() > 1.5

	if player and not is_being_knocked_back:
		var dir = (player.global_position - global_position).normalized()
		dir.y = 0
		look_at(global_position + dir, Vector3.UP)
		final_velocity = dir * SPEED

	# combine chase speed and current knockback
	velocity = final_velocity + knockback_velocity

	var collided = move_and_slide()

	if collided:
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			
			if knockback_velocity.length() > 5.0:
				var wall_damage = knockback_velocity.length() * 0.1
				# use a specific flag or check to prevent internal knockback override
				# we pass Vector3.ZERO to signal its a wall hit
				take_damage(wall_damage, Vector3.ZERO, false)

				# Reflect the velocity for the bounce
				var reflection = knockback_velocity.bounce(collision.get_normal())
				knockback_velocity = Vector3(reflection.x, 0, reflection.z) * 0.7

	# decay the knockback over time so they dont slide forever
	knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, 20.0 * delta)
	update_label()

func update_label():
	label.text = str(round(health_percent)) + "%"
	label.modulate = Color(1, 1 - (health_percent/200.0), 1 - (health_percent/200.0))

# func take_damage(amount: float, source_pos: Vector3):
# 	health_percent += amount
	
# 	if health_percent >= 100.0:
# 		die()
# 	else:
# 		# calculate knockback direction away from source
# 		var dir = (global_position - source_pos).normalized()
# 		dir.y = 0
		
# 		# scale knockback based on current percent
# 		# higher % = launched further
# 		var power = 10.0 + (health_percent * 0.5) 
# 		apply_knockback(dir * power)
func take_damage(amount: float, source_pos: Vector3, is_lethal: bool = false):
	health_percent += amount

	# ONLY apply new knockback if its NOT a wall hit
	if source_pos != Vector3.ZERO:
		var dir = (global_position - source_pos).normalized()
		dir.y = 0
		var power = 10.0 + (health_percent * 0.5) 
		apply_knockback(dir * power)

	if is_lethal and health_percent >= 100.0:
		die()

	update_label()

func apply_knockback(force: Vector3):
	knockback_velocity = force
	
func die():
	queue_free()
