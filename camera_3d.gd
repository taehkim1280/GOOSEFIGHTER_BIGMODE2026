extends Camera3D

@export var target_path: NodePath = "../Goose"
@export var smooth_speed: float = 5.0

var target: Node3D
var offset: Vector3

var shake_intensity: float = 0.0
var shake_decay: float = 3.0 # higher is snappier recovery

func _ready():
	target = get_node(target_path)
	if target:
		offset = global_position - target.global_position

func add_shake(amount: float):
	shake_intensity = clamp(shake_intensity + amount, 0.0, 1.0)

func _physics_process(delta):
	if is_instance_valid(target):
		# follow target
		var target_pos = target.global_position + offset
		global_position = global_position.lerp(target_pos, smooth_speed * delta)
		
	# handle screen shake logic
	if shake_intensity > 0:
		shake_intensity = move_toward(shake_intensity, 0.0, shake_decay * delta)
		
		# use offsets to avoid messing with camera transforms
		var shake_amount = shake_intensity * shake_intensity
		h_offset = randf_range(-1.0, 1.0) * shake_amount
		v_offset = randf_range(-1.0, 1.0) * shake_amount
	else:
		h_offset = 0
		v_offset = 0
