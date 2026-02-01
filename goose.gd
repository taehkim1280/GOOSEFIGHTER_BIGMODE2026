extends CharacterBody3D

# --- Constants ---
const SPEED = 7
const ATTACK_COOLDOWN_TIME = 0.4
const BOMBA_COOLDOWN = 2.0
const DASH_COOLDOWN = 1.5 

# --- Exports ---
@export var DASH_SPEED: float = 25.0
@export var DASH_KNOCKBACK = 30.0
@export var ATTACK_ANGLE: float = 45.0
@export var attack_line_scene: PackedScene
@export var explosion_scene: PackedScene

# --- Variables ---
var ATTACK_RANGE = 2.0
var attack_cooldown: float = 0.0
var current_indicator: Node3D = null
var is_dashing: bool = false
var dash_direction: Vector3 = Vector3.ZERO
var pinned_enemies: Array[Node3D] = []

# --- Onready Nodes ---
@onready var bomba_timer = $BombaTimer
@onready var dash_duration = $DashDuration
@onready var dash_hitbox = $DashHitbox
@onready var dash_cooldown_timer = $DashCooldownTimer
@onready var camera = get_viewport().get_camera_3d()
@onready var anim_player = $AnimationPlayer

# --- Lifecycle ---

func _ready():
	dash_hitbox.body_entered.connect(_on_dash_hitbox_body_entered)

func _process(_delta):
	if is_instance_valid(current_indicator):
		var pos = get_mouse_3d_position()
		if pos != Vector3.ZERO:
			current_indicator.global_position = pos

func _physics_process(_delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var raw_dir := Vector3(input_dir.x, 0, input_dir.y)
	var direction := raw_dir.rotated(Vector3.UP, deg_to_rad(45)).normalized()

	if is_dashing:
		velocity = dash_direction * DASH_SPEED
		move_and_slide()
		
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
		look_at(position + direction, Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# animation logic
	if direction != Vector3.ZERO:
		anim_player.play("run")
	else:
		anim_player.play("idle")
	
	move_and_slide()

func _input(event):
	if event.is_action_pressed("attack_primary"):
		attack_towards_mouse()
	
	if event.is_action_pressed("attack_explosive_cask"):
		if current_indicator == null:
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
	dash_cooldown_timer.start(DASH_COOLDOWN)
	dash_duration.start(0.2) # dash lasts 0.4 seconds
	anim_player.play("run", -1, 2.0) # play run animation 2x faster

	# wait for timer or manual stop
	await dash_duration.timeout
	stop_dash()

func stop_dash():
	is_dashing = false

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

func _on_dash_hitbox_body_entered(body):
	if is_dashing and body.is_in_group("enemies") and not body in pinned_enemies:
		pinned_enemies.append(body)

# --- Combat Mechanics ---

func attack_towards_mouse():
	if attack_cooldown > 0: return

	var target_pos = get_mouse_3d_position()
	var attack_damage = 7
	var is_lethal = true

	if target_pos == Vector3.ZERO: return
	
	# look at mouse instantly
	var look_target = Vector3(target_pos.x, global_position.y, target_pos.z)
	look_at(look_target, Vector3.UP)
	
	# valculate direction vectors
	var attack_dir = (look_target - global_position).normalized()
	var attack_dir_2d = Vector2(attack_dir.x, attack_dir.z)
	
	# [DEBUG] Draw the hitbox on the floor
	debug_draw_cone(attack_dir, ATTACK_RANGE, ATTACK_ANGLE)
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		# cylinder Distance Check
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= ATTACK_RANGE:
			
			# cone Angle Check
			var enemy_dir = enemy.global_position - global_position
			var enemy_dir_2d = Vector2(enemy_dir.x, enemy_dir.z).normalized()
			
			# get the angle difference
			var angle_diff = rad_to_deg(abs(attack_dir_2d.angle_to(enemy_dir_2d)))
			
			if angle_diff <= ATTACK_ANGLE:
				enemy.take_damage(attack_damage, global_position, is_lethal)

	attack_cooldown = ATTACK_COOLDOWN_TIME

func spawn_explosion_sequence():
	if not bomba_timer.is_stopped(): 
		return

	bomba_timer.start(BOMBA_COOLDOWN)

	current_indicator = explosion_scene.instantiate()
	get_parent().add_child(current_indicator)
	current_indicator.set_as_faint(true)
	
	await get_tree().create_timer(0.3).timeout
	
	if is_instance_valid(current_indicator):
		var locked_pos = current_indicator.global_position
		current_indicator.start_charge_sequence(locked_pos)
		current_indicator = null

# --- Utilities ---

func get_mouse_3d_position() -> Vector3:
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_direction = camera.project_ray_normal(mouse_pos)
	
	# intersect with a horizontal plane at y=1 (where geese live)
	var plane = Plane(Vector3.UP, 1.0)
	var intersection = plane.intersects_ray(ray_origin, ray_direction)
	
	return intersection if intersection else Vector3.ZERO

func debug_draw_cone(direction: Vector3, range_val: float, angle_deg: float):
	# Create a temporary mesh instance
	var debug_mesh = MeshInstance3D.new()
	var immediate_mesh = ImmediateMesh.new()
	var material = StandardMaterial3D.new()
	
	material.albedo_color = Color(1, 0, 0, 0.5) # Semi-transparent red
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	debug_mesh.mesh = immediate_mesh
	debug_mesh.material_override = material
	
	# Draw the fan shape
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var segments = 10
	var start_angle = -deg_to_rad(angle_deg)
	var total_angle = deg_to_rad(angle_deg * 2)
	var angle_per_segment = total_angle / segments
	
	# We draw relative to (0,0,0) then rotate the whole node
	for i in range(segments):
		var current_angle = start_angle + (i * angle_per_segment)
		var next_angle = start_angle + ((i + 1) * angle_per_segment)
		
		var p1 = Vector3.ZERO
		var p2 = Vector3(sin(current_angle) * range_val, 0.1, cos(current_angle) * range_val)
		var p3 = Vector3(sin(next_angle) * range_val, 0.1, cos(next_angle) * range_val)
		
		# Add triangle vertices
		immediate_mesh.surface_add_vertex(p1)
		immediate_mesh.surface_add_vertex(p2)
		immediate_mesh.surface_add_vertex(p3)
		
	immediate_mesh.surface_end()
	
	# Add to scene, align rotation, and delete after 0.1s
	get_parent().add_child(debug_mesh)
	debug_mesh.global_position = global_position
	# Align the mesh forward (Z) with our attack direction
	var target_look = global_position + direction
	debug_mesh.look_at(target_look, Vector3.UP)

	debug_mesh.rotate_y(deg_to_rad(180))
	
	# Auto-delete
	var timer = get_tree().create_timer(0.15)
	timer.timeout.connect(debug_mesh.queue_free)
