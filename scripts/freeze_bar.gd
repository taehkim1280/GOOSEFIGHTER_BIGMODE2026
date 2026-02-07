extends TextureProgressBar

var freeze_timer: Timer

func _ready():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_node("PetrifyTimer"):
			freeze_timer = player.get_node("PetrifyTimer")
		else:
			push_error("FreezeBar: Could not find 'PetrifyTimer' on Player!")

func _process(_delta):
	if is_instance_valid(freeze_timer) and not freeze_timer.is_stopped():
		value = freeze_timer.time_left / freeze_timer.wait_time * 100
	else:
		value = 0
