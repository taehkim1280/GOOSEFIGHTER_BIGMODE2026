extends Camera3D

@export var target_path: NodePath = "../Goose"
@export var smooth_speed: float = 5.0

# How much "Wider" the view is at the start
@export var intro_zoom_mult: float = 2.15
@export var intro_duration: float = 3.5

var target: Node3D
var offset: Vector3

# We store the size you set in the Inspector as the "Target"
var normal_size: float 

var shake_intensity: float = 0.0
var shake_decay: float = 3.0 

func _ready():
	target = get_node(target_path)
	
	# 1. Remember the normal size and offset
	normal_size = self.size 
	if target:
		offset = global_position - target.global_position

	# 2. Check intro flag
	if not GameManager.has_started_intro:
		start_intro_sequence()

func start_intro_sequence():
	GameManager.has_started_intro = true
	
	# 1. Set the camera size HUGE (Zoomed Out)
	self.size = normal_size * intro_zoom_mult
	
	# 2. Create Tween
	var tween = create_tween()
	
	# --- PAUSE HERE FOR 2 SECONDS ---
	tween.tween_interval(1.5) 
	
	# 3. Configure Smoothness
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# 4. Animate the 'size' property back to normal
	tween.tween_property(self, "size", normal_size, intro_duration)

func add_shake(amount: float):
	shake_intensity = clamp(shake_intensity + amount, 0.0, 1.0)

func _physics_process(delta):
	if is_instance_valid(target):
		# Follow the target smoothly
		var target_pos = target.global_position + offset
		global_position = global_position.lerp(target_pos, smooth_speed * delta)
		
	# Shake Logic
	if shake_intensity > 0:
		shake_intensity = move_toward(shake_intensity, 0.0, shake_decay * delta)
		
		var shake_amount = shake_intensity * shake_intensity
		
		# Apply shake to the H/V offsets of the camera attributes
		h_offset = randf_range(-1.0, 1.0) * shake_amount
		v_offset = randf_range(-1.0, 1.0) * shake_amount
	else:
		h_offset = 0
		v_offset = 0
