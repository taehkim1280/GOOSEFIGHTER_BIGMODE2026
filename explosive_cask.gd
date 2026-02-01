extends Node3D

const RADIUS = 5.0
const KNOCKBACK_STRENGTH = 25.0

@export var projectile_scene: PackedScene

@onready var mesh = $MeshInstance3D

func set_as_faint(is_faint: bool):
	if is_faint:
		mesh.transparency = 0.8
		scale = Vector3(0.9, 1, 0.9)

func start_charge_sequence(pos: Vector3):
	global_position = pos
	
	# spawning the visual projectile
	var player = get_tree().get_first_node_in_group("player")
	if player and projectile_scene:
		var proj = projectile_scene.instantiate()
		get_parent().add_child(proj)
		# launch from player to this cask's locked position
		proj.launch(player.global_position, global_position, 0.5)
		
		# hide the cask mesh while the projectile is in the air
		mesh.transparency = 1.0 
	else:
		# fallback if no projectile or player: just show the faint indicator
		mesh.transparency = 0.4

	# timing the explosion
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(1.1, 1, 1.1), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(explode)

func explode():
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			var diff = enemy.global_position - self.global_position
			diff.y = 0 # ignore height
			var dist = diff.length()
			
			if dist <= RADIUS:
				# var push_dir = diff.normalized()
				# if push_dir == Vector3.ZERO: push_dir = Vector3.FORWARD
				# enemy.apply_knockback(push_dir * KNOCKBACK_STRENGTH)
				var damage_amount = 25.0
				enemy.take_damage(damage_amount, self.global_position)

	var cam = get_viewport().get_camera_3d()
	if cam.has_method("add_shake"):
		cam.add_shake(0.4) # Intensity of 0.4
	
	var burst = create_tween()
	mesh.transparency = 0.0 # Flash solid
	burst.tween_property(self, "scale", Vector3(1.6, 1, 1.6), 0.1)
	burst.set_parallel(true)
	burst.tween_property(mesh, "transparency", 1.0, 0.1) # Fade out
	burst.chain().tween_callback(queue_free)
