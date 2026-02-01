extends TextureProgressBar

@export var timer_path: NodePath = "../../../Goose/BombaTimer"
var target_timer: Timer

func _ready():
	target_timer = get_node(timer_path)

func _process(_delta):
	if is_instance_valid(target_timer) and not target_timer.is_stopped():
		var fill_ratio = target_timer.time_left / target_timer.wait_time
		value = fill_ratio * 100
	else:
		value = 0
