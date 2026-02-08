extends Label

func _ready():
	# 1. Set the starting text
	text = "x%s" % GameManager.gold
	
	# 2. Listen for changes so it updates instantly when you get gold
	GameManager.gold_changed.connect(update_text)

func update_text():
	text = "x%s" % GameManager.gold
