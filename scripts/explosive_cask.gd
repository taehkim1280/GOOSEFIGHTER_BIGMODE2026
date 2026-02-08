extends Node3D

const RADIUS = 3.0
const DAMAGE = 25.0
const VISUAL_OVERSIZE = 1.1 

@export var projectile_scene: PackedScene
@onready var mesh = $MeshInstance3D

# --- 1. SETUP (Copied exactly from PetrifyZone) ---
func set_as_faint(is_faint: bool):
	# Match the transparency logic
	mesh.transparency = 0.5
	scale = Vector3(RADIUS, 1, RADIUS)

	# Ensure the mesh uses a unique material (Logic from Petrify)
	if mesh.get_surface_override_material(0) == null:
		mesh.set_surface_override_material(0, StandardMaterial3D.new())

	var mat = mesh.get_surface_override_material(0)
	if mat:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		# I changed color to ORANGE to distinguish it from Petrify (Blue)
		mat.albedo_color = Color(0, 1, 1, 0.5) 
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.render_priority = 1 # Draw on top of floor

# --- 2. CAST SEQUENCE (Copied from PetrifyZone + Projectile) ---
func start_charge_sequence(pos: Vector3):
	global_position = pos
	
	# Unique Cask Logic: Launch the barrel visual
	_launch_projectile_visual()

	# Visual "Cast Time" (Matches Petrify Tween)
	mesh.transparency = 0.2
	var tween = create_tween()
	tween.tween_property(self, "scale", scale * VISUAL_OVERSIZE, 0.5).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(explode)

# --- 3. EXPLOSION (Unique to Cask) ---
func explode():
	# Damage Enemies (Instead of Freezing them)
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	# Calculate hit radius (Visual Size + slight buffer)
	var hit_threshold = (RADIUS * VISUAL_OVERSIZE) + 0.5
	
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			# Check flat distance (ignoring height)
			var diff = enemy.global_position - global_position
			diff.y = 0
			
			if diff.length() <= hit_threshold:
				enemy.take_damage(DAMAGE, global_position)

	SoundManager.play_sfx("snow_bomb")
	# Camera Shake
	var cam = get_viewport().get_camera_3d()
	if cam and cam.has_method("add_shake"):
		cam.add_shake(0.4)
	
	queue_free()

# --- Helpers ---
func _launch_projectile_visual():
	var player = get_tree().get_first_node_in_group("player")
	if player and projectile_scene:
		var proj = projectile_scene.instantiate()
		get_parent().add_child(proj)
		proj.launch(player.global_position, global_position, 0.5)
