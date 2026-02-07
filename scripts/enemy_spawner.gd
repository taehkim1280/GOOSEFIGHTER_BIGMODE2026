extends Node3D

# enemy *.tscn goes here...
@export var enemy_scene: PackedScene 
const MAX_ENEMIES = 3
const ARENA_HALFSIZE = 10.0

func _on_timer_timeout() -> void:
	var enemy_count = get_tree().get_nodes_in_group("enemies").size()
	
	if enemy_count < MAX_ENEMIES:
		spawn_enemy()

func spawn_enemy():
	var new_enemy = enemy_scene.instantiate()
	
	var local_pos = Vector3(
		randf_range(-ARENA_HALFSIZE, ARENA_HALFSIZE),
		0.0,
		randf_range(-ARENA_HALFSIZE, ARENA_HALFSIZE)
	)
	
	get_parent().add_child(new_enemy)
	
	new_enemy.global_position = self.to_global(local_pos)
	
	new_enemy.global_position.y = 1.0
