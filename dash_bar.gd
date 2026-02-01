extends TextureProgressBar

var dash_timer: Timer

func _ready():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_node("DashCooldownTimer"):
			dash_timer = player.get_node("DashCooldownTimer")
		else:
			push_error("DashBar: Could not find 'DashCooldownTimer' on Player!")

func _process(_delta):
	if is_instance_valid(dash_timer) and not dash_timer.is_stopped():
		var ratio = dash_timer.time_left / dash_timer.wait_time
		value = ratio * 100
	else:
		value = 0
