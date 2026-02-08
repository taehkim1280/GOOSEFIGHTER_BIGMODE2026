extends Node3D

# enemy *.tscn goes here...
@export var enemy_scene_white: PackedScene 
@export var enemy_scene_grey: PackedScene 
@export var enemy_scene_brown: PackedScene 
@onready var enemies = [enemy_scene_white,enemy_scene_grey,enemy_scene_brown]
const MAX_ENEMIES = 5
const ARENA_HALFSIZE = 10.0

func _on_timer_timeout() -> void:
	var enemy_count = get_tree().get_nodes_in_group("enemies").size()
	
	if enemy_count < MAX_ENEMIES:
		spawn_enemy()

func spawn_enemy():
	var i  = randi_range(0,2)
	var new_enemy = enemies[i].instantiate()

	var local_pos = Vector3(
		randf_range(-ARENA_HALFSIZE, ARENA_HALFSIZE),
		0.0,
		randf_range(-ARENA_HALFSIZE, ARENA_HALFSIZE)
	)
	
	get_parent().add_child(new_enemy)
	
	new_enemy.global_position = self.to_global(local_pos)
	
	new_enemy.global_position.y = 1.0
