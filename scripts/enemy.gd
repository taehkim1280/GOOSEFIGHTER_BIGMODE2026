extends CharacterBody3D

# --- Constants ---
const SPEED = 3.0
const WALL_SMASH_THRESHOLD = 100.0 # Damage needed to kill on wall hit
const FREEZE_STACK_LIMIT = 3
const SHORT_FREEZE_DURATION = 1.5 # Duration when frozen by 3 stacks

# --- Nodes ---
@onready var label = $Label3D
@onready var anim_player = $AnimationPlayer
@onready var skeleton = $Armature/Skeleton3D
@onready var mesh = $Armature/Skeleton3D/Cube
@onready var stun_bar = $StunBar
@onready var stun_fill = $StunBar/Fill
@onready var stun_bg = $StunBar/Background

# --- Combat Nodes ---
@onready var attackCD = $AttackCD
@onready var attackDone = $AttackDone 
@onready var attackWindup = $AttackWindup
@onready var peckArea = $PeckArea
@onready var peck_col_shape: CollisionShape3D = $PeckArea/PeckCollider
@onready var clapArea = $ClapArea
@onready var clap_col_shape: CollisionShape3D = $ClapArea/ClapCollider

# --- State Variables ---
var player: Node3D = null
var accumulated_damage: float = 0.0 # Replaces "health_percent"
var freeze_stacks: int = 0

var knockback_velocity = Vector3.ZERO
var is_being_knocked_back = false
var is_attacking = false
var attackType = 0 

# --- Freeze/Stun Variables ---
var is_frozen: bool = false
var ice_velocity: Vector3 = Vector3.ZERO
var ice_friction: float = 0.5 
var stun_duration_total: float = 0.0
var stun_timer: float = 0.0

# --- Peck Settings ---
var necklen = 1
var neckoffset = 0.3
var peckattackWindup = 0.8
var peckattackRangeOuter = 2.75
var peckattackRangeInner = 3 
var peckattackRadius = 1

# --- Clap Settings ---
var clapattackWindup = 0.8

# --- Lifecycle ---

func _ready():
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")

	if label:
		label.no_depth_test = true      # Visible through walls
		label.outline_render_priority = 19
		label.render_priority = 20      # Draw on top of Stun Bar
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	
	update_label()
	
	# Connect signals
	attackWindup.timeout.connect(_on_attack_cd_timeout)

	# Randomize neck length for variety
	necklen = randf_range(1, 2.5)
	skeleton.set_bone_pose_scale(skeleton.find_bone("neck"), Vector3(1, (necklen), 1))
	peckattackRangeOuter = necklen * 2 + neckoffset + peckattackRadius

	# Setup visuals
	setup_stun_bar()
	
	if OS.is_debug_build():
		_spawn_debug_lines()

func _physics_process(delta):
	# --------------------------
	# 1. FROZEN STATE LOGIC
	# --------------------------
	if is_frozen:
		# Update Timer
		stun_timer -= delta
		
		# Update Visual Bar
		if stun_bar and stun_fill and stun_duration_total > 0:
			var ratio = stun_timer / stun_duration_total
			stun_fill.scale.x = clamp(ratio, 0.0, 1.0)

		# Check if done
		if stun_timer <= 0:
			thaw()
			return 

		# --- Knockback WHILE Frozen ---
		velocity = ice_velocity + knockback_velocity
		
		# FIX: Use 'if' directly to avoid declaring "var collided" twice
		if move_and_slide():
			for i in get_slide_collision_count():
				var collision = get_slide_collision(i)
				
				# Bounce logic (Frozen)
				if knockback_velocity.length() > 2.0:
					var reflection = knockback_velocity.bounce(collision.get_normal())
					knockback_velocity = Vector3(reflection.x, 0, reflection.z) * 0.7
		
		# --- Decays ---
		ice_velocity = ice_velocity.move_toward(Vector3.ZERO, ice_friction * delta)
		knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, 20.0 * delta)
		
		# Extra Damage if smashed into wall fast (Ice Shatter)
		# --- FATAL WALL COLLISION LOGIC ---
		# Condition 1: Must be Frozen (We are in the if is_frozen block)
		# Condition 2: Must be hitting a wall
		# Condition 3: Must have > 100 accumulated damage
		# Condition 4: Must be moving fast enough to "Splat"
		if is_on_wall():
			if accumulated_damage >= WALL_SMASH_THRESHOLD and (ice_velocity.length() > 5.0 or knockback_velocity.length() > 10.0):
				die() # INSTANT KILL
			elif knockback_velocity.length() > 5.0:
				# Wall hit, but not enough damage stored to kill
				take_damage(10.0, Vector3.ZERO, false) # Add a bit more damage
			
		return # SKIP NORMAL AI MOVEMENT

	# --------------------------
	# 2. NORMAL AI MOVEMENT
	# --------------------------
	is_attacking = not attackDone.is_stopped()
	var final_velocity = Vector3.ZERO
	is_being_knocked_back = knockback_velocity.length() > 1.5

	if player and not is_being_knocked_back:
		var dir = (player.global_position - global_position).normalized()
		dir.y = 0
		look_at(global_position + dir, Vector3.UP)
		final_velocity = dir * SPEED

	# Combine chase speed and current knockback
	velocity = final_velocity + knockback_velocity

	# FIX: Use 'if' directly here as well
	if move_and_slide():
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			
			if knockback_velocity.length() > 5.0:
				var wall_damage = knockback_velocity.length() * 0.1
				# Pass Vector3.ZERO to signal a wall hit (no new knockback)
				take_damage(wall_damage, Vector3.ZERO, false)

				# Reflect the velocity for the bounce
				var reflection = knockback_velocity.bounce(collision.get_normal())
				knockback_velocity = Vector3(reflection.x, 0, reflection.z) * 0.7

	# Decay knockback
	knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, 20.0 * delta)

	# --------------------------
	# 4. ATTACK LOGIC
	# --------------------------
	if not is_attacking and (player.global_position - global_position).length() < peckattackRangeOuter:
		try_attack()

	# Animation
	if not is_attacking:
		anim_player.play("run", -1, (velocity.length()) / SPEED)

	update_label()


# --- Freeze / Stun Mechanics ---

func apply_freeze_stack():
	if is_frozen: return # Already frozen, ignore stacks
	
	freeze_stacks += 1
	update_label()
	
	# Visual feedback for stack (Optional: Flash white?)
	if mesh:
		var tween = create_tween()
		tween.tween_property(mesh, "transparency", 0.5, 0.1)
		tween.tween_property(mesh, "transparency", 0.0, 0.1)

	if freeze_stacks >= FREEZE_STACK_LIMIT:
		apply_freeze(SHORT_FREEZE_DURATION)
		freeze_stacks = 0 # Reset stacks after freezing

func apply_freeze(duration: float):
	is_frozen = true
	stun_duration_total = duration
	stun_timer = duration
	freeze_stacks = 0 # Clear stacks if force-frozen by ability
	
	velocity = Vector3.ZERO 
	ice_velocity = Vector3.ZERO
	
	# Visual: Turn Ice Blue
	if mesh:
		var blue_mat = StandardMaterial3D.new()
		blue_mat.albedo_color = Color(0.3, 0.9, 1.0, 0.6) 
		blue_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		blue_mat.render_priority = 1
		blue_mat.roughness = 0.1 
		blue_mat.emission_enabled = true
		blue_mat.emission = Color(0.1, 0.3, 0.8) 
		mesh.material_override = blue_mat

	if stun_bar:
		stun_bar.visible = true
		stun_fill.scale.x = 1.0
	
	update_label()

func thaw():
	is_frozen = false
	if mesh:
		mesh.material_override = null 
	if stun_bar:
		stun_bar.visible = false
	update_label()

func hit_by_ice_slide(force_dir: Vector3):
	if is_frozen:
		ice_velocity = force_dir * 30.0


# --- Combat Mechanics ---

func try_attack():
	if not attackCD.is_stopped():
		return
		
	if player and not is_being_knocked_back:
		var dir = (player.global_position - global_position).normalized()
		dir.y = 0
		look_at(global_position + dir, Vector3.UP)
	else:
		return

	# Choose attack based on distance
	var distToPlayer = (player.global_position - global_position).length()
	
	if distToPlayer > peckattackRangeInner:
		# Peck Attack
		attackType = 0
		peckArea.global_position = player.global_position
		anim_player.play("attackBase", -1, 1)
		attackWindup.start(peckattackWindup)
		spawn_telegraph(peckArea.global_position, get_collider_radius(peck_col_shape), peckattackWindup)
	else:
		# Clap Attack
		attackType = 1
		anim_player.play("attackclap", -1, 2)
		attackWindup.start(clapattackWindup)
		spawn_telegraph(clapArea.global_position, get_collider_radius(clap_col_shape), clapattackWindup)

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

func take_damage(amount: float, source_pos: Vector3, apply_kb: bool = true):
	accumulated_damage += amount

	if apply_kb and source_pos != Vector3.ZERO:
		var dir = (global_position - source_pos).normalized()
		dir.y = 0
		# Knockback scales with accumulated damage!
		var power = 10.0 + (accumulated_damage * 0.5) 
		apply_knockback(dir * power)

	# Removed logic that calls die() here. Only Wall hits kill now.
	update_label()

func apply_knockback(force: Vector3):
	knockback_velocity = force
	
func die():
	queue_free()


# --- Visuals & Helpers ---

func update_label():
	# Show Stacks and Damage
	var stack_str = ""
	for i in range(freeze_stacks):
		stack_str += "*" # 1 star per stack
	
	label.text = "%s\n%d DMG" % [stack_str, round(accumulated_damage)]
	
	# Color code the label
	if accumulated_damage >= WALL_SMASH_THRESHOLD:
		label.modulate = Color(1, 0.2, 0.2) # Red (Execute Ready)
	else:
		label.modulate = Color(1, 1, 1) # White

func get_collider_radius(col_node: CollisionShape3D) -> float:
	var shape = col_node.shape
	var node_scale = col_node.global_transform.basis.get_scale().x
	return shape.radius * node_scale

func spawn_telegraph(pos: Vector3, radius: float, duration: float) -> void:
	# Create Visual Mesh
	var indicator = MeshInstance3D.new()
	var indicator2 = MeshInstance3D.new()
	var telegraph_mesh = CylinderMesh.new()
	
	telegraph_mesh.top_radius = radius
	telegraph_mesh.bottom_radius = radius
	telegraph_mesh.height = 0.05 
	
	indicator.mesh = telegraph_mesh
	indicator2.mesh = telegraph_mesh

	# Create Material (Semi-transparent Red)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0, 0, 0.3) 
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	mat.render_priority = 1
	
	indicator.material_override = mat
	indicator2.material_override = mat

	get_tree().root.add_child(indicator)
	get_tree().root.add_child(indicator2)
	
	indicator.global_position = pos
	indicator2.global_position = pos
	indicator.global_position.y = 0.05 
	indicator2.global_position.y = 0.05 

	# Animate
	indicator.scale = Vector3(0, 1, 0) 
	indicator2.scale = Vector3(1, 1, 1) 

	var tween = create_tween()
	tween.tween_property(indicator, "scale", Vector3(1, 1, 1), duration).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(func():
		indicator.queue_free()
		indicator2.queue_free()
	)

func setup_stun_bar():
	if not stun_bar: return
	
	stun_bar.visible = false
	stun_bar.position.y = 2.5 
	
	# --- SCALE SETTING ---
	# Increase this number to make the bar bigger!
	# 0.01 = Small
	# 0.02 = Medium
	# 0.04 = Large
	var scale_factor = 0.03 
	# var bar_width_px = 200.0 # Approximate width of your texture in pixels

	# --- BACKGROUND ---
	if stun_bg:
		stun_bg.modulate = Color.BLACK 
		stun_bg.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		stun_bg.no_depth_test = true 
		stun_bg.render_priority = 10
		stun_bg.centered = false 
		
		# APPLY SIZE
		stun_bg.pixel_size = scale_factor 

	# --- FILL ---
	if stun_fill:
		stun_fill.modulate = Color(0.2, 0.9, 1.0) 
		stun_fill.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		stun_fill.no_depth_test = true
		stun_fill.render_priority = 11 
		stun_fill.centered = false 
		
		# APPLY SIZE
		stun_fill.pixel_size = scale_factor 

	# --- RE-CENTERING ---
	# Since we made it bigger, we need to shift it further left to keep it centered.
	# Formula: -(Width_in_Pixels * Scale_Factor) / 2
	# stun_bar.position.x = -(bar_width_px * scale_factor) / 2.0

func _spawn_debug_lines() -> void:
	if OS.is_debug_build() && false:
		var debug_ring = MeshInstance3D.new()
		var torus = TorusMesh.new()
		torus.outer_radius = peckattackRangeOuter
		torus.inner_radius = peckattackRangeInner

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1, 0, 0) 
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.5 

		torus.material = mat
		debug_ring.mesh = torus
		debug_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		debug_ring.scale = Vector3(1.0, 0.1, 1.0)
		debug_ring.position.y = -1
		add_child(debug_ring)
