extends Control

@onready var gold_label = $GoldDisplay/GoldLabel

var items = {
	"snowball": {
		"name": "Snowball",
		"price": 20,
		"icon": "snowballicon" 
	},
	"hat": {
		"name": "Warm Hat",
		"price": 10,
		"icon": "haticon"
	},
	"tuque": {
		"name": "Trapper Hat",
		"price": 15,
		"icon": "tuqueicon"
	},
	"helmet": {
		"name": "Safety Helmet",
		"price": 50,
		"icon": "helmeticon"
	},
	"mitten": {
		"name": "Mitten",
		"price": 15,
		"icon": "mittenicon"
	},
	"hockeyglove": {
		"name": "Hockey Gloves",
		"price": 40,
		"icon": "hockeygloveicon"
	}
}

@onready var listings_container = $listings
@onready var listing1 = $listings/ShopItem1
@onready var listing2 = $listings/ShopItem2
@onready var listing3 = $listings/ShopItem3
@onready var buttons =  [listing1, listing2, listing3]

func _ready():
	update_ui()
	for button in buttons:
		for item in items:
			button.get_node(items[item]["icon"]).visible = false
	
	stock_shop()
	for button in buttons:
		if not button.is_connected("pressed", _on_item_bought):
			button.pressed.connect(_on_item_bought.bind(button))

func _on_item_bought(button_pressed):
	button_pressed.disabled = true
	button_pressed.modulate = Color(0.5, 0.5, 0.5) 
	print(button_pressed.listing_name, "button pressed")
	var item_data = items[button_pressed.listing_name] 
	GameManager.buy_item(item_data)

func update_ui():
	gold_label.text = "%s" % GameManager.gold

func stock_shop():
	var available_items = items.keys()
	available_items.shuffle()

	for i in range(3):
		var button = buttons[i]
		button.visible = true
		var item_data = items[available_items[i]]
		button.get_node("Label").text = item_data["name"]
		button.get_node("GoldLabel2").text = "x%s" % item_data["price"]
		button.get_node(item_data["icon"]).visible = true
		button.listing_name = available_items[i]

#func _on_buy_heal_pressed():
	#if GameManager.gold >= 50:
		#GameManager.gold -= 50
		#GameManager.current_health = min(GameManager.current_health + 10, GameManager.max_health)
		#update_ui()

func _on_next_level_pressed():
	GameManager.level_index += 1
	get_tree().change_scene_to_file("res://World.tscn")
