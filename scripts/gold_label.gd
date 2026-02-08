extends Label

func _ready():
	text = "%s" % GameManager.gold
	
	GameManager.gold_changed.connect(update_text)

func update_text():
	text = "%s" % GameManager.gold
