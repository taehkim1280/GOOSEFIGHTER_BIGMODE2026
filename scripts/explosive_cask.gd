extends Node3D

const RADIUS = 3.0
const KNOCKBACK_STRENGTH = 25.0
const VISUAL_OVERSIZE = 1.1 # Matches the * 1.1 in the tween

@export var projectile_scene: PackedScene
@onready var mesh = $MeshInstance3D

func set_as_faint(is_faint: bool):
	# 1. Setup Material (Exact same logic as PetrifyZone)
	if mesh.material_override == null:
		mesh.material_override = StandardMaterial3D.new()

	var mat = mesh.material_override
	mat.albedo_color = Color(0, 1, 1, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.render_priority = 1 # Draw on top of floor

	# 2. Set Initial Scale
	if is_faint:
		scale = Vector3(RADIUS, 1, RADIUS)
		mesh.transparency = 0.5

func start_charge_sequence(pos: Vector3):
	global_position = pos
	
	_launch_projectile_visual()

	mesh.transparency = 0.2
	
	# Visual "Cast Time" (wait 0.5s before exploding)
	var tween = create_tween()
	# Scale animation: Grow by 10% over 0.5s
	tween.tween_property(self, "scale", scale * VISUAL_OVERSIZE, 0.5).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(explode)

func explode():
	# 1. Damage Enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	# Calculate effective hit radius (Visual Size + Enemy Size Buffer)
	var hit_threshold = (RADIUS * VISUAL_OVERSIZE) + 0.5
	
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			# Check distance
			var dist = _get_flat_distance(enemy.global_position)
			
			if dist <= hit_threshold:
				enemy.take_damage(25.0, global_position)

	# 2. Camera Shake
	var cam = get_viewport().get_camera_3d()
	if cam and cam.has_method("add_shake"):
		cam.add_shake(0.4)
	
	# 3. Cleanup
	queue_free()

# --- Helper Functions ---

func _launch_projectile_visual():
	# This part is unique to Cask (the barrel flying through air)
	# We keep it separate so it doesn't clutter the main animation flow
	var player = get_tree().get_first_node_in_group("player")
	if player and projectile_scene:
		var proj = projectile_scene.instantiate()
		get_parent().add_child(proj)
		proj.launch(player.global_position, global_position, 0.5)
		
		# Hide the main indicator mesh while projectile flies?
		# If you want it exactly like Petrify, maybe keep it visible but faint.
		# mesh.transparency = 1.0 
	else:
		pass

func _get_flat_distance(target_pos: Vector3) -> float:
	var diff = target_pos - global_position
	diff.y = 0
	return diff.length()