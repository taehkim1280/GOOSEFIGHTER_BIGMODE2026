extends Node

# Persistent Data
var current_health: int = 100
var max_health: int = 100
var gold: int = 0
var level_index: int = 1

# Reset for a fresh game
func reset_game():
	current_health = 100
	gold = 0
	level_index = 1
