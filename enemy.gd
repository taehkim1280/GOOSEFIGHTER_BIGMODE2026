extends CharacterBody3D

const SPEED = 3.0
var player: Node3D = null
var knockback_velocity = Vector3.ZERO
var is_being_knocked_back = false
var necklen = 1
var neckoffset = 0.3

var health_percent: float = 0.0

@onready var label = $Label3D
@onready var anim_player = $AnimationPlayer
@onready var skeleton = $Armature/Skeleton3D


@onready var attackCD = $AttackCD
var is_attacking = false
@onready var attackDone = $AttackDone # if attackDone.is_stopped(), entity is not attacking
@onready var attackWindup = $AttackWindup
var attackType = 0 #0 for peck, 1 for clap

####### PECK ATTACK #########
var peckattackWindup = 0.2
var peckattackRangeOuter = 2.75
var peckattackRangeInner = 3  # also the range for the clap
var peckattackRadius = 1
var peckattackCD = 1
@onready var peckArea = $PeckArea

####### CLAP ATTACK #########
var clapattackWindup = 0.2
@onready var clapArea = $ClapArea


func _ready():
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")
	update_label()
	attackWindup.timeout.connect(_on_attack_cd_timeout)

	#### peck logic ####
	necklen = randf_range(1, 2.5)
	skeleton.set_bone_pose_scale(skeleton.find_bone("neck"), Vector3(1, (necklen), 1))
	peckattackRangeOuter = necklen*2 + neckoffset + peckattackRadius


	#### clap logic ######


	##### debug lines ######
	if OS.is_debug_build():
		_spawn_debug_lines()

func _physics_process(delta):
	is_attacking = not attackDone.is_stopped()
	var final_velocity = Vector3.ZERO
	is_being_knocked_back = knockback_velocity.length() > 1.5

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

	if not is_attacking && (player.global_position - global_position).length() < peckattackRangeOuter:
		try_attack()

	# animation logic
	if not is_attacking:
		anim_player.play("run", -1, (velocity.length())/SPEED)

	update_label()

func update_label():
	label.text = str(round(health_percent)) + "%"
	label.modulate = Color(1, 1 - (health_percent/200.0), 1 - (health_percent/200.0))


func try_attack():
	if not attackCD.is_stopped():
		return
	if player and not is_being_knocked_back:
		var dir = (player.global_position - global_position).normalized()
		dir.y = 0
		look_at(global_position + dir, Vector3.UP)
	else:
		return

	## use distance to choose attack type
	var distToPlayer = (player.global_position - global_position).length()
	if distToPlayer > peckattackRangeInner:
		## Use peck attack
		attackType = 0
		peckArea.global_position = player.global_position
		anim_player.play("attackBase", -1, 1.5)
		attackWindup.start(peckattackWindup)
	else:
		## use clap attack
		attackType = 1
		anim_player.play("attackclap", -1, 3)
		attackWindup.start(clapattackWindup)

	velocity = Vector3.ZERO
	attackCD.start()
	attackDone.start()
	is_attacking = not attackDone.is_stopped()

func _on_attack_cd_timeout():
	if attackType == 0:
		if peckArea.overlaps_body(player):
			player.take_damage(10)
	else:
		if clapArea.overlaps_body(player):
			player.take_damage(20)

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

func _spawn_debug_lines() -> void:
	if OS.is_debug_build():
		# 1. Create a MeshInstance to hold the shape
		var debug_ring = MeshInstance3D.new()

		# 2. Create a Torus (Donut shape)
		var torus = TorusMesh.new()
		torus.outer_radius = peckattackRangeOuter
		torus.inner_radius = peckattackRangeInner

		# 3. Create an Unshaded Material (Bright Red, visible in dark)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1, 0, 0) # Red
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.5 # 50% transparent

		# 4. Assign and attach
		torus.material = mat
		debug_ring.mesh = torus
		debug_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		debug_ring.scale = Vector3(1.0, 0.1, 1.0)
		debug_ring.position.y = -1
		# Add as child so it moves with the enemy
		add_child(debug_ring)
