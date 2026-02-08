extends Control


func _on_start_button_pressed() -> void:
	GameManager.reset_game()
	GameManager.start_new_game()
