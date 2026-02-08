extends Node

# 1. Load the original images
var raw_normal = preload("res://assets/cursor.png")
var raw_click = preload("res://assets/cursor_click.png")

# 2. Variables to hold the new "Small" versions
var cursor_normal: Texture2D
var cursor_click: Texture2D

# Hotspot is top-left
var hotspot = Vector2(0, 0)

# Persistent Data
var current_health: int = 100
var max_health: int = 100
var gold: int = 0
var level_index: int = 1
var items: Array = []
var player_speed = 7.0
var player_damage = 4.0

# Level Progress
var current_kills: int = 0
var kills_required: int = 5 

signal level_complete 
signal gold_changed   

func _ready():
	# --- RESIZE CURSORS START ---
	# Create smaller versions (half size)
	cursor_normal = _resize_texture(raw_normal, 0.5)
	cursor_click = _resize_texture(raw_click, 0.5)
	
	# Set the initial cursor using the new small texture
	Input.set_custom_mouse_cursor(cursor_normal, Input.CURSOR_ARROW, hotspot)
	# --- RESIZE CURSORS END ---
	
	calculate_target()

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Use the SMALL version
			Input.set_custom_mouse_cursor(cursor_click, Input.CURSOR_ARROW, hotspot)
		else:
			# Use the SMALL version
			Input.set_custom_mouse_cursor(cursor_normal, Input.CURSOR_ARROW, hotspot)

# --- HELPER: Resizes a texture via code ---
func _resize_texture(original: Texture2D, scale_factor: float) -> ImageTexture:
	# 1. Get the raw image data
	var image = original.get_image()
	
	# 2. Calculate new size
	var new_width = int(image.get_width() * scale_factor)
	var new_height = int(image.get_height() * scale_factor)
	
	# 3. Resize it (Using cubic interpolation for smoothness)
	image.resize(new_width, new_height, Image.INTERPOLATE_CUBIC)
	
	# 4. Convert back to a Texture that the Input system can use
	return ImageTexture.create_from_image(image)

func start_new_game():
	reset_game()
	get_tree().change_scene_to_file("res://scene/world.tscn")

func reset_game():
	current_health = 100
	player_speed = 7.0
	player_damage = 4.0
	gold = 0
	level_index = 1
	items.clear()
	current_kills = 0
	calculate_target()
	get_tree().change_scene_to_file("res://scene/world.tscn")

func calculate_target():
	kills_required = level_index * 5
	print("Level ", level_index, " - Kills needed: ", kills_required)

func add_kill(gold_reward: int):
	current_kills += 1
	gold += gold_reward
	emit_signal("gold_changed")
	
	print("Kills: %s / %s" % [current_kills, kills_required])
	
	if current_kills >= kills_required:
		emit_signal("level_complete")

func buy_item(item_data):
	if gold >= item_data["price"]:
		gold -= item_data["price"]
		items.append(item_data)
		emit_signal("gold_changed")
		return true 
	else:
		print("Not enough gold!")
		return false 

func has_item(item_name: String) -> bool:
	for item in items:
		if item["name"] == item_name:
			return true
	return false

func next_level():
	level_index += 1
	current_kills = 0
	calculate_target()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/world.tscn")
