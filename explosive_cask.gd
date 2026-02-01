extends Node3D

const RADIUS = 5.0
const KNOCKBACK_STRENGTH = 25.0

@onready var mesh = $MeshInstance3D

func set_as_faint(is_faint: bool):
	if is_faint:
		mesh.transparency = 0.8
		scale = Vector3(0.9, 1, 0.9)

func start_charge_sequence(pos: Vector3):
	global_position = pos
	mesh.transparency = 0.4
	
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(1.1, 1, 1.1), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(explode)

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
	
	var burst = create_tween()
	mesh.transparency = 0.0 # Flash solid
	burst.tween_property(self, "scale", Vector3(1.6, 1, 1.6), 0.1)
	burst.set_parallel(true)
	burst.tween_property(mesh, "transparency", 1.0, 0.1) # Fade out
	burst.chain().tween_callback(queue_free)
