extends Node3D

const RADIUS = 5.0
const KNOCKBACK_STRENGTH = 20.0

func explode():
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if enemy is CharacterBody3D:
			var diff = enemy.global_position - self.global_position
			diff.y = 0 # ignore height
			var dist = diff.length()
			
			if dist <= RADIUS:
				var push_dir = diff.normalized()
				if push_dir == Vector3.ZERO: push_dir = Vector3.FORWARD
				
				enemy.apply_knockback(push_dir * KNOCKBACK_STRENGTH)
	
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(1.5, 1, 1.5), 0.1)
	tween.tween_property(self, "modulate:a", 0.0, 0.1)
	tween.tween_callback(queue_free)
