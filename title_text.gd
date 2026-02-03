extends Label

func _ready():
	scale = Vector2(1, 1)
	pivot_offset = size / 2
	
	add_theme_color_override("font_color", Color.WHITE)
	add_theme_constant_override("outline_size", 0) # Start with no "bold" outline
	add_theme_color_override("font_outline_color", Color.RED) # Outline color matches final text
	
	# 3. Animate the 'scale' property to 2x size over 5 seconds
	# Use TransitionType.TRANS_LINEAR to ensure it moves at a constant speed
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(4, 4), 10.0).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(self, "theme_override_colors/font_color", Color.RED, 10.0)
	tween.tween_property(self, "theme_override_constants/outline_size", 3, 10.0)
