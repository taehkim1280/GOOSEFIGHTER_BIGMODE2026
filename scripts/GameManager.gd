extends Node

# Persistent Data
var current_health: int = 100
var max_health: int = 100
var gold: int = 0
var level_index: int = 1
var items: Array = []

# Level Progress
var current_kills: int = 0
var kills_required: int = 5 

signal level_complete 
signal gold_changed   

func _ready():
	calculate_target()

func _input(event):
	# Check for a mouse click (Left Button pressed down)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:

		# Ask Godot: "What Control node is under the mouse right now?"
		var hovered_node = get_viewport().gui_get_hovered_control()

		if hovered_node:
			print("CLICKED ON: ", hovered_node.name)
			print("   -> Parent: ", hovered_node.get_parent().name)
			print("   -> Mouse Filter: ", hovered_node.mouse_filter)
		else:
			print("CLICKED ON: Nothing (Empty space or non-Control node)")

func start_new_game():
	# 1. Reset variables (Health, Gold, etc.)
	reset_game()
	
	# 2. Change the scene (Safe to call here because GameManager is always in the tree)
	get_tree().change_scene_to_file("res://scene/world.tscn")

# --- CALL THIS WHEN YOU DIE OR RESTART THE GAME ---
func reset_game():
	current_health = 100
	gold = 0
	level_index = 1
	items.clear()
	current_kills = 0
	calculate_target()
	# This resets the scene to Level 1 state
	get_tree().change_scene_to_file("res://scene/world.tscn")

# --- CALCULATE NEW TARGET ---
func calculate_target():
	# Example: Level 1 = 5, Level 2 = 10, Level 3 = 15
	kills_required = level_index * 5
	print("Level ", level_index, " - Kills needed: ", kills_required)

# --- TRACK KILLS ---
func add_kill(gold_reward: int):
	current_kills += 1
	gold += gold_reward
	emit_signal("gold_changed")
	
	print("Kills: %s / %s" % [current_kills, kills_required])
	
	if current_kills >= kills_required:
		emit_signal("level_complete")

# --- BUYING LOGIC ---
func buy_item(item_data):
	if gold >= item_data["price"]:
		gold -= item_data["price"]
		items.append(item_data)
		emit_signal("gold_changed")
		return true 
	else:
		print("Not enough gold!")
		return false 

# --- TRANSITION TO NEXT LEVEL ---
func next_level():
	# 1. Increment Difficulty
	level_index += 1
	
	# 2. Reset Level Progress (But KEEP Gold/Items/Health)
	current_kills = 0
	calculate_target()
	
	# 3. Safety: Ensure Game is Unpaused before changing scenes
	get_tree().paused = false
	
	# 4. Reload the World
	# This wipes the current map and loads a fresh one.
	# Since GameManager is separate, your Gold/Items survive this!
	get_tree().change_scene_to_file("res://scene/world.tscn")
