extends Control

@onready var gold_label = $GoldDisplay/GoldLabel
@onready var listings_container = $listings

# Assign your buttons manually or via group
@onready var buttons = [$listings/ShopItem1, $listings/ShopItem2, $listings/ShopItem3]
@onready var desc_label = $DescriptionLabel

var shop_items = {
	"snowball": { 
		"name": "Snowball", 
		"price": 20, 
		"icon": "snowballicon", 
		"desc": "New Snowball Ability." 
	},
	"hat": { 
		"name": "Warm Hat", 
		"price": 10, 
		"icon": "haticon", 
		"desc": "New Freeze Ability." 
	},
	"helmet": { 
		"name": "Safety Helmet", 
		"price": 50, 
		"icon": "helmeticon", 
		"desc": "New Dash Ability." 
	},
	"hockeyglove": { 
		"name": "Hockey Gloves", 
		"price": 40, 
		"icon": "hockeygloveicon", 
		"desc": "+25 Max Health (Permanent)." 
	},
	"tuque": { 
		"name": "Trapper Hat", 
		"price": 15, 
		"icon": "tuqueicon",
		"desc": "+2 Movement Speed."
	},
	"mitten": { 
		"name": "Mitten", 
		"price": 15, 
		"icon": "mittenicon",
		"desc": "+50% Attack Damage."
	}
}

func _input(event):
	# Check for a mouse click (Left Button pressed down)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:

		# Ask Godot: "What Control node is under the mouse right now?"
		var hovered_node = get_viewport().gui_get_hovered_control()

		if hovered_node:
			print("CLICKED ON: ", hovered_node.name)
			print("   -> Parent: ", hovered_node.get_parent().name)
			print("   -> Mouse Filter: ", hovered_node.mouse_filter)
		else:
			print("CLICKED ON: Nothing (Empty space or non-Control node)")

func _ready():
	# Hide shop at start
	self.visible = false
	
	# Connect to GameManager signals
	GameManager.level_complete.connect(open_shop)
	GameManager.gold_changed.connect(update_ui)
	
	# Setup Buttons
	for button in buttons:
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
	print("Listing pressed:", item_key)
	var item_data = shop_items[item_key]
	
	# Try to buy (GameManager handles the math)
	var success = GameManager.buy_item(item_data)
	
	if success:
		button_pressed.disabled = true
		button_pressed.modulate = Color(0.5, 0.5, 0.5) 
		print("Bought: ", item_data["name"])

		if item_key == "hockeyglove":
			# Increase Max Health (Assuming standard is 100, +25 is a good upgrade)
			GameManager.max_health += 25 
			
			# Heal the player by that amount so the new health chunk isn't empty
			GameManager.current_health += 25 
			
			print("Max health increased! New Max: ", GameManager.max_health)
			
		elif item_key == "tuque":
			GameManager.player_speed += 2.0 # Increase speed by 2
			print("Speed increased! New Speed: ", GameManager.player_speed)
	else:
		# Optional: Shake animation or red flash for "Not enough gold"
		pass

func update_ui():
	gold_label.text = "x%s" % GameManager.gold

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
		
		# 1. Disconnect old signals to prevent errors (if re-stocking)
		if button.mouse_entered.is_connected(_on_button_hover):
			button.mouse_entered.disconnect(_on_button_hover)
		if button.mouse_exited.is_connected(_on_button_exit):
			button.mouse_exited.disconnect(_on_button_exit)
			
		# 2. Connect new signals
		# We bind 'key' so the function knows WHICH item we are hovering
		button.mouse_entered.connect(_on_button_hover.bind(key))
		button.mouse_exited.connect(_on_button_exit)

# Connect this to your "Close Shop" / "Go" Button signal
func _on_next_level_pressed():
	self.visible = false
	get_tree().paused = false # Unpause
	GameManager.next_level()

func _on_button_hover(item_key):
	var data = shop_items[item_key]
	desc_label.text = data["desc"]

func _on_button_exit():
	desc_label.text = "" # Clear text when mouse leaves
