extends GPUParticles3D

func _ready():
	# 1. Force Visibility Settings via Code
	_setup_material_overrides()

	# 2. Force Particle Restart
	emitting = false
	await get_tree().physics_frame # Wait 1 frame for setup
	
	restart()
	emitting = true
	
	# 3. Cleanup when done
	await finished
	queue_free()

func _setup_material_overrides():
	var mesh = draw_pass_1
	if not mesh: return

	var mat = mesh.surface_get_material(0)
	if not mat:
		mat = StandardMaterial3D.new()
		mesh.surface_set_material(0, mat)
	
	# Priority 20 forces it to draw ON TOP of walls/floors/stun bars
	mat.render_priority = 20 
	
	# Disable Depth Test = "X-Ray Vision" (See through walls)
	mat.no_depth_test = true 
	
	# Make it bright and flat (matches your art style)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	# Alpha Scissor makes it look like solid chunks, not ghost fog
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.params_alpha_scissor_threshold = 0.5
	
	# Ensure Vertex Color is used (so particles can fade out)
	mat.vertex_color_use_as_albedo = true
