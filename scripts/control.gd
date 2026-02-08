extends Control

# update these paths to match your actual scene tree!
@onready var snowball_cd = $HBoxContainer/BombaBar
@onready var petrify_cd = $HBoxContainer/FreezeBar
@onready var dash_cd = $HBoxContainer/DashBar

func _ready():
	update_ability_visibility()

func update_ability_visibility():
	# This does the exact same thing as the big if-statements above
	snowball_cd.visible = GameManager.has_item("Snowball")
	petrify_cd.visible  = GameManager.has_item("Warm Hat")
	dash_cd.visible     = GameManager.has_item("Safety Helmet")
