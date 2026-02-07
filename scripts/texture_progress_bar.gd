extends TextureProgressBar

var bomba_timer: Timer

func _ready():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_node("BombaTimer"):
			bomba_timer = player.get_node("BombaTimer")
		else:
			push_error("BombaBar: Could not find 'BombaTimer' on Player!")

func _process(_delta):
	if is_instance_valid(bomba_timer) and not bomba_timer.is_stopped():
		value = bomba_timer.time_left / bomba_timer.wait_time * 100
	else:
		value = 0
