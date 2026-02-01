extends Camera3D

@export var target_path: NodePath = "../Goose" # point to goose node
@export var smooth_speed = 10.0

var target: Node3D
var offset: Vector3

func _ready():
	target = get_node(target_path)
	if target:
		offset = global_position - target.position

func _physics_process(delta):
	if is_instance_valid(target):
		var target_pos = target.global_position + offset
		global_position = global_position.lerp(target_pos, smooth_speed * delta)
	
