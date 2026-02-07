extends Control

@onready var gold_label = $GoldLabel

func _ready():
	update_ui()

func update_ui():
	gold_label.text = "Gold: %s" % GameManager.gold

#func _on_buy_heal_pressed():
	#if GameManager.gold >= 50:
		#GameManager.gold -= 50
		#GameManager.current_health = min(GameManager.current_health + 10, GameManager.max_health)
		#update_ui()

func _on_next_level_pressed():
	GameManager.level_index += 1
	get_tree().change_scene_to_file("res://World.tscn")
