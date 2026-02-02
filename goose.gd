extends CharacterBody3D

# --- Constants ---
const SPEED = 7
const ATTACK_COOLDOWN_TIME = 0.3
const BOMBA_COOLDOWN = 4.0
const DASH_COOLDOWN = 0.5 

# --- Exports ---
@export var DASH_SPEED: float = 25.0
@export var DASH_KNOCKBACK = 30.0
@export var ATTACK_ANGLE: float = 45.0
@export var attack_line_scene: PackedScene
@export var explosion_scene: PackedScene

# --- Variables ---
var current_health = 100
var ATTACK_RANGE = 2.0
var attack_cooldown: float = 0.0
var current_indicator: Node3D = null
var is_dashing: bool = false
var is_attacking: bool = false
var dash_direction: Vector3 = Vector3.ZERO
var pinned_enemies: Array[Node3D] = []
var is_invincible: bool = false
var ghost_spawn_timer: float = 0.0
var buffered_input: String = ""

# --- Onready Nodes ---
@onready var bomba_timer = $BombaTimer
@onready var dash_duration = $DashDuration
@onready var dash_hitbox = $DashHitbox
@onready var dash_cooldown_timer = $DashCooldownTimer
@onready var camera = get_viewport().get_camera_3d()
@onready var anim_player = $AnimationPlayer
@onready var attack_hitbox = $PrimaryAttackHitbox

# --- Lifecycle ---

func _ready():
	dash_hitbox.body_entered.connect(_on_dash_hitbox_body_entered)
	current_health = GameManager.current_health

func _process(_delta):
	if is_instance_valid(current_indicator):
		var pos = get_mouse_3d_position()
		if pos != Vector3.ZERO:
			current_indicator.global_position = pos

func _physics_process(_delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var raw_dir := Vector3(input_dir.x, 0, input_dir.y)
	var direction := raw_dir.rotated(Vector3.UP, deg_to_rad(45)).normalized()

	#if direction != Vector3.ZERO:
		## ONLY rotate if we are NOT attacking
		##if is_attacking: print("is_attacking is true")
		#if not is_attacking:
				#look_at(position + direction, Vector3.UP)

	if is_dashing:
		velocity = dash_direction * DASH_SPEED
		move_and_slide()
		
		ghost_spawn_timer += _delta
		if ghost_spawn_timer > 0.05: # Spawn a ghost every 0.05 seconds
			spawn_ghost_trail()
			ghost_spawn_timer = 0.0
		
		for enemy in pinned_enemies:
			if is_instance_valid(enemy):
				# offset them slightly in front (1.0 unit) so they don't clip inside you
				enemy.global_position = global_position + (dash_direction * 1.5)
		
		# if we hit a wall while dashing, stop immediately
		if is_on_wall():
			stop_dash()
			
		return

	if attack_cooldown > 0:
		attack_cooldown -= _delta

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		if not is_attacking:
				look_at(position + direction, Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# animation logic
	# 1st priority is attack
	if is_dashing:
		pass
	elif is_attacking:
		pass 
	# 2nd priority is running
	elif direction != Vector3.ZERO:
		anim_player.play("run")
	else:
		anim_player.play("idle")
	
	move_and_slide()

func _input(event):
	if event.is_action_pressed("attack_primary"):
		if is_dashing:
			buffered_input = "attack_primary"
		else:
			attack_towards_mouse()

	if event.is_action_pressed("attack_explosive_cask"):
		if is_dashing:
			buffered_input = "attack_explosive_cask"
		elif current_indicator == null:
			spawn_explosion_sequence()

	if event.is_action_pressed("dash") and not is_dashing and dash_cooldown_timer.is_stopped():
		start_dash()

# --- Dash Mechanics ---

func start_dash():
	var mouse_pos = get_mouse_3d_position()

	if mouse_pos == Vector3.ZERO:
		dash_direction = -global_transform.basis.z
	else:
		var diff = mouse_pos - global_position
		diff.y = 0
		dash_direction = diff.normalized()

		look_at(global_position + dash_direction, Vector3.UP)

	is_dashing = true
	is_invincible = true;
	dash_cooldown_timer.start(DASH_COOLDOWN)
	dash_duration.start(0.2) # dash lasts 0.4 seconds
	anim_player.play("run", -1, 2.0) # play run animation 2x faster

	# wait for timer or manual stop
	await dash_duration.timeout
	stop_dash()

func stop_dash():
	is_dashing = false
	is_invincible = false

	# launch everyone we collected
	for enemy in pinned_enemies:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			# calculate launch direction (Forward + slightly Up for arc)
			var _launch_dir = dash_direction
			
			# if we stopped because of a wall, deal EXTRA damage
			if is_on_wall():
				enemy.take_damage(20.0, global_position, false)
				# bounce them back slightly from the wall
				_launch_dir = -dash_direction 
			else:
				# normal release (dash ended naturally)
				enemy.take_damage(10.0, global_position, false)
			
			# Apply the momentum (This assumes your enemy script handles knockback)
			# You might need to manually apply velocity if take_damage doesn't do it
			# enemy.velocity = launch_dir * DASH_KNOCKBACK 

	# Clear the list for the next dash
	pinned_enemies.clear()

	# Friction stop for the goose
	velocity = velocity * 0.25

	# input buffer
	if buffered_input == "attack_primary":
		attack_towards_mouse()
	elif buffered_input == "attack_explosive_cask":
		if current_indicator == null:
			spawn_explosion_sequence()
			
	# Clear the buffer so it doesn't fire again automatically
	buffered_input = ""

func _on_dash_hitbox_body_entered(body):
	if is_dashing and body.is_in_group("enemies") and not body in pinned_enemies:
		pinned_enemies.append(body)

# --- Combat Mechanics ---

func attack_towards_mouse():
	if attack_cooldown > 0: return

	var target_pos = get_mouse_3d_position()
	if target_pos == Vector3.ZERO: return

	# look at mouse instantly
	var look_target = Vector3(target_pos.x, global_position.y, target_pos.z)
	look_at(look_target, Vector3.UP)
	attack_hitbox.global_transform = attack_hitbox.global_transform
	
	attack_hitbox.force_shapecast_update()
	
	is_attacking = true

	anim_player.play("attack2", -1, 2.0)
	
	if attack_hitbox.is_colliding():
		# Iterate through everyone we hit
		for i in range(attack_hitbox.get_collision_count()):
			var enemy = attack_hitbox.get_collider(i)
			
			# Avoid hitting the same enemy twice in one frame (rare but possible)
			if enemy.is_in_group("enemies") and enemy.has_method("take_damage"):
				enemy.take_damage(7, global_position, true)

	# 3. Cooldown
	attack_cooldown = ATTACK_COOLDOWN_TIME
	
	await get_tree().create_timer(0.25).timeout
	is_attacking = false

func spawn_explosion_sequence():
	if not bomba_timer.is_stopped(): 
		return

	current_indicator = explosion_scene.instantiate()
	get_parent().add_child(current_indicator)
	current_indicator.set_as_faint(true)
	
	await get_tree().create_timer(0.3).timeout
	
	if is_instance_valid(current_indicator):
		var locked_pos = current_indicator.global_position
		bomba_timer.start(BOMBA_COOLDOWN)
		current_indicator.start_charge_sequence(locked_pos)
		current_indicator = null

func take_damage(amount: int) -> void:
	if is_invincible:
		print("[DEBUG] dodged attack with iframes yay!")
		return

	current_health -= amount
	print("Player hit for %s" % amount)

	# 3. Visualization: Update UI / Flash Red
	# emit_signal("health_changed", current_health)

	if current_health <= 0:
		_die()

func _die():
	level_complete()


### TODO: Needs to be put in a WorldController.gd
func level_complete():
	# # Save current state to singleton
	# GameManager.current_health = current_health
	# GameManager.gold += 100 # Reward for winning

	# Go to Shop
	get_tree().change_scene_to_file("res://Shop.tscn")

# --- Utilities ---

func get_mouse_3d_position() -> Vector3:
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_direction = camera.project_ray_normal(mouse_pos)
	
	# intersect with a horizontal plane at y=1 (where geese live)
	var plane = Plane(Vector3.UP, 1.0)
	var intersection = plane.intersects_ray(ray_origin, ray_direction)
	
	return intersection if intersection else Vector3.ZERO

func spawn_ghost_trail():
	var original_mesh = $Armature/Skeleton3D/Cube 
	if not original_mesh: return

	var ghost = MeshInstance3D.new()
	ghost.mesh = original_mesh.mesh
	ghost.transform = original_mesh.global_transform

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.502, 0.8, 1.0, 0.784)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.8, 1.0)
	mat.emission_energy_multiplier = 2.0

	ghost.material_override = mat

	# 4. Add to the WORLD, not the player (so it stays behind)
	get_parent().add_child(ghost)

	var tween = create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.3) # Fade to invisible in 0.3s
	tween.tween_callback(ghost.queue_free)
