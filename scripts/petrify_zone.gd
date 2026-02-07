extends Node3D

const RADIUS = 4.0  # The size of the zone
const FREEZE_DURATION = 1.5

@onready var mesh = $MeshInstance3D

func set_indicator_mode():
	# Make it look like a "ghost" indicator
	mesh.transparency = 0.5
	# Scale the visual mesh to match the RADIUS (assuming mesh is 1 unit wide)
	scale = Vector3(RADIUS * 1, 1, RADIUS * 1) 

func start_cast_sequence(pos: Vector3):
	global_position = pos
	mesh.transparency = 0.2
	
	# Visual "Cast Time" (wait 0.5s before freezing)
	var tween = create_tween()
	# Optional: scale animation like the cask
	tween.tween_property(self, "scale", scale * 1.1, 0.5).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(activate_petrify)

func activate_petrify():
	# 1. Freeze Enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	for entity in enemies:
		# Check distance using the RADIUS constant
		if global_position.distance_to(entity.global_position) <= RADIUS:
			if entity.has_method("apply_freeze"):
				entity.apply_freeze(FREEZE_DURATION)

	# 2. Freeze Player (Friendly Fire)
	var player = get_tree().get_first_node_in_group("player")
	if player and global_position.distance_to(player.global_position) <= RADIUS:
		if player.has_method("apply_freeze"):
			player.apply_freeze(FREEZE_DURATION)
	
	# Cleanup
	queue_free()
