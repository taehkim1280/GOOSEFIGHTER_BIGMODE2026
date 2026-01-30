extends Node3D

# enemy *.tscn goes here...
@export var enemy_scene: PackedScene 
const MAX_ENEMIES = 7

func _on_timer_timeout() -> void:
	var enemy_count = get_child_count() - 1
	
	if enemy_count < MAX_ENEMIES:
		spawn_enemy()

func spawn_enemy():
	var new_enemy = enemy_scene.instantiate()
	
	var spawn_x = randf_range(-15.0, 15.0)
	var spawn_z = randf_range(-15.0, 15.0)
	
	new_enemy.position = Vector3(spawn_x, 1.0, spawn_z)
	add_child(new_enemy)
