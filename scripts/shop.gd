extends Control

@onready var gold_label = $GoldDisplay/GoldLabel
@onready var listings_container = $listings

# Assign your buttons manually or via group
@onready var buttons = [$listings/ShopItem1, $listings/ShopItem2, $listings/ShopItem3]

var shop_items = {
	"snowball": { "name": "Snowball", "price": 20, "icon": "snowballicon" },
	"hat": { "name": "Warm Hat", "price": 10, "icon": "haticon" },
	"tuque": { "name": "Trapper Hat", "price": 15, "icon": "tuqueicon" },
	"helmet": { "name": "Safety Helmet", "price": 50, "icon": "helmeticon" },
	"mitten": { "name": "Mitten", "price": 15, "icon": "mittenicon" },
	"hockeyglove": { "name": "Hockey Gloves", "price": 40, "icon": "hockeygloveicon" }
}

func _ready():
	# Hide shop at start
	self.visible = false
	
	# Connect to GameManager signals
	GameManager.level_complete.connect(open_shop)
	GameManager.gold_changed.connect(update_ui)
	
	# Setup Buttons
	for button in buttons:
		if not button.is_connected("pressed", _on_item_bought):
			button.pressed.connect(_on_item_bought.bind(button))
			
	update_ui()

func open_shop():
	print("Level Complete! Opening Shop...")
	stock_shop()
	update_ui()
	self.visible = true
	# Optional: Pause the game while shopping
	get_tree().paused = true 

func _on_item_bought(button_pressed):
	var item_key = button_pressed.listing_name
	var item_data = shop_items[item_key]
	
	# Try to buy (GameManager handles the math)
	var success = GameManager.buy_item(item_data)
	
	if success:
		button_pressed.disabled = true
		button_pressed.modulate = Color(0.5, 0.5, 0.5) 
		print("Bought: ", item_data["name"])
	else:
		# Optional: Shake animation or red flash for "Not enough gold"
		pass

func update_ui():
	gold_label.text = "Gold: %s" % GameManager.gold

func stock_shop():
	var available_keys = shop_items.keys()
	available_keys.shuffle()

	for i in range(buttons.size()):
		var button = buttons[i]
		
		# Reset button state
		button.disabled = false
		button.modulate = Color.WHITE
		button.visible = true
		
		# Get data
		var key = available_keys[i]
		var data = shop_items[key]
		
		# Setup UI
		button.get_node("Label").text = data["name"]
		button.get_node("GoldLabel2").text = "%s G" % data["price"]
		button.listing_name = key
		
		# Handle Icons (Hide all, show correct one)
		# Assuming icons are children of the button named "snowballicon", etc.
		for child in button.get_children():
			if "icon" in child.name.to_lower():
				child.visible = false
		
		if button.has_node(data["icon"]):
			button.get_node(data["icon"]).visible = true

# Connect this to your "Close Shop" / "Go" Button signal
func _on_next_level_pressed():
	self.visible = false
	get_tree().paused = false # Unpause
	GameManager.next_level()
