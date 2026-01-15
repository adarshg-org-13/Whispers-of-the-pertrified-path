# CarShop.gd
# Attach this to a Node3D in your main scene
extends Node3D

@export var car_scene: PackedScene  # Drag your Vehicle_player.tscn here
@export var car_price: int = 5000
@export var spawn_offset: Vector3 = Vector3(0, 1, 5)  # Spawn in front of player

var player: CharacterBody3D
var washing_system: Node
var ui: CanvasLayer
var shop_ui: Control

func _ready():
	# Find player and cast it 'as CharacterBody3D'
	var found_player = get_tree().get_first_node_in_group("player")
	
	if not found_player:
		found_player = get_parent().get_node_or_null("Player")
	
	# This is the "Cast": it converts the generic Node to CharacterBody3D
	player = found_player as CharacterBody3D
	
	# Check if the cast failed (if the node wasn't actually a CharacterBody3D)
	if not player:
		push_error("Player node found, but it is not a CharacterBody3D!")
		return

	# ... rest of your code ...func setup_shop_ui():
	if not ui:
		return
	
	# Create shop button
	var shop_button = Button.new()
	shop_button.name = "ShopButton"
	shop_button.text = "🚗 SHOP"
	shop_button.custom_minimum_size = Vector2(100, 50)
	
	# Position in top left, below money label
	shop_button.position = Vector2(20, 80)
	shop_button.add_theme_font_size_override("font_size", 20)
	
	# Style the button
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.3, 0.8, 0.8)
	style_normal.corner_radius_bottom_left = 10
	style_normal.corner_radius_bottom_right = 10
	style_normal.corner_radius_top_left = 10
	style_normal.corner_radius_top_right = 10
	shop_button.add_theme_stylebox_override("normal", style_normal)
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.3, 0.4, 0.9, 0.9)
	style_hover.corner_radius_bottom_left = 10
	style_hover.corner_radius_bottom_right = 10
	style_hover.corner_radius_top_left = 10
	style_hover.corner_radius_top_right = 10
	shop_button.add_theme_stylebox_override("hover", style_hover)
	
	# Connect button signal
	shop_button.pressed.connect(_on_shop_button_pressed)
	
	ui.add_child(shop_button)
	
	# Create shop panel (hidden initially)
	create_shop_panel()

func create_shop_panel():
	var shop_panel = Panel.new()
	shop_panel.name = "ShopPanel"
	shop_panel.visible = false
	shop_panel.custom_minimum_size = Vector2(400, 350)
	
	# Center the panel
	shop_panel.anchor_left = 0.5
	shop_panel.anchor_top = 0.5
	shop_panel.anchor_right = 0.5
	shop_panel.anchor_bottom = 0.5
	shop_panel.offset_left = -200
	shop_panel.offset_top = -175
	shop_panel.offset_right = 200
	shop_panel.offset_bottom = 175
	
	# Style the panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0.3, 0.5, 1.0, 1.0)
	panel_style.corner_radius_bottom_left = 15
	panel_style.corner_radius_bottom_right = 15
	panel_style.corner_radius_top_left = 15
	panel_style.corner_radius_top_right = 15
	shop_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Add VBoxContainer for layout
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 15)
	vbox.offset_left = 20
	vbox.offset_right = -20
	vbox.offset_top = 20
	vbox.offset_bottom = -20
	shop_panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "🚗 CAR SHOP 🚗"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1, 1, 0.5))
	vbox.add_child(title)
	
	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer1)
	
	# Car info
	var car_info = Label.new()
	car_info.text = "Personal Sports Car\nPrice: $" + str(car_price) + "\n\nDrive around the city in style!"
	car_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	car_info.add_theme_font_size_override("font_size", 16)
	car_info.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	vbox.add_child(car_info)
	
	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer2)
	
	# Buy button
	var buy_button = Button.new()
	buy_button.name = "BuyCarButton"
	buy_button.text = "💰 BUY CAR ($" + str(car_price) + ")"
	buy_button.custom_minimum_size = Vector2(250, 50)
	buy_button.add_theme_font_size_override("font_size", 20)
	
	var buy_style_normal = StyleBoxFlat.new()
	buy_style_normal.bg_color = Color(0.2, 0.8, 0.2, 0.9)
	buy_style_normal.corner_radius_bottom_left = 10
	buy_style_normal.corner_radius_bottom_right = 10
	buy_style_normal.corner_radius_top_left = 10
	buy_style_normal.corner_radius_top_right = 10
	buy_button.add_theme_stylebox_override("normal", buy_style_normal)
	
	var buy_style_hover = StyleBoxFlat.new()
	buy_style_hover.bg_color = Color(0.3, 0.9, 0.3, 1.0)
	buy_style_hover.corner_radius_bottom_left = 10
	buy_style_hover.corner_radius_bottom_right = 10
	buy_style_hover.corner_radius_top_left = 10
	buy_style_hover.corner_radius_top_right = 10
	buy_button.add_theme_stylebox_override("hover", buy_style_hover)
	
	buy_button.pressed.connect(_on_buy_car_pressed)
	vbox.add_child(buy_button)
	
	# Status label
	var status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = ""
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color.RED)
	vbox.add_child(status_label)
	
	# Spacer
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer3)
	
	# Close button
	var close_button = Button.new()
	close_button.text = "✖ CLOSE"
	close_button.custom_minimum_size = Vector2(150, 40)
	
	var close_style_normal = StyleBoxFlat.new()
	close_style_normal.bg_color = Color(0.8, 0.2, 0.2, 0.8)
	close_style_normal.corner_radius_bottom_left = 8
	close_style_normal.corner_radius_bottom_right = 8
	close_style_normal.corner_radius_top_left = 8
	close_style_normal.corner_radius_top_right = 8
	close_button.add_theme_stylebox_override("normal", close_style_normal)
	
	close_button.pressed.connect(_on_close_shop_pressed)
	vbox.add_child(close_button)
	
	ui.add_child(shop_panel)
	shop_ui = shop_panel

func _on_shop_button_pressed():
	if shop_ui:
		shop_ui.visible = !shop_ui.visible
		
		# Show current money
		if shop_ui.visible and washing_system:
			var status_label = shop_ui.get_node_or_null("VBoxContainer/StatusLabel")
			if status_label:
				status_label.text = "Your money: $" + str(washing_system.total_money)
				status_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))

func _on_buy_car_pressed():
	var status_label = shop_ui.get_node_or_null("VBoxContainer/StatusLabel")
	
	# Check if washing system exists
	if not washing_system:
		if status_label:
			status_label.text = "Error: WashingSystem not found!"
			status_label.add_theme_color_override("font_color", Color.RED)
		return
	
	# Get current money from washing system
	var current_money = washing_system.total_money
	
	# Check if player has enough money
	if current_money < car_price:
		if status_label:
			status_label.text = "Not enough money! Need $" + str(car_price) + "\nYou have: $" + str(current_money)
			status_label.add_theme_color_override("font_color", Color.RED)
		return
	
	# Check if car scene is assigned
	if not car_scene:
		if status_label:
			status_label.text = "Error: Car scene not assigned in inspector!"
			status_label.add_theme_color_override("font_color", Color.RED)
		return
	
	# Deduct money from washing system
	washing_system.total_money -= car_price
	
	# Update money UI
	washing_system.update_money_ui()
	
	# Spawn car near player
	spawn_car()
	
	if status_label:
		status_label.text = "✅ Car purchased!\nSpawned in front of you!"
		status_label.add_theme_color_override("font_color", Color.GREEN)
	
	# Close shop after 2 seconds
	await get_tree().create_timer(2.0).timeout
	if shop_ui:
		shop_ui.visible = false

func _on_close_shop_pressed():
	if shop_ui:
		shop_ui.visible = false

func spawn_car():
	if not car_scene or not player:
		push_error("Cannot spawn car: missing car scene or player")
		return
	
	# Instance the car
	var car = car_scene.instantiate()
	
	# Calculate spawn position (in front of player based on their facing direction)
	var forward = player.get_facing_direction()
	var spawn_pos = player.global_position + forward * spawn_offset.z + Vector3(0, spawn_offset.y, 0)
	
	car.global_position = spawn_pos
	
	# Make car face same direction as player
	car.global_rotation.y = player.head.global_rotation.y
	
	# Add to main scene
	get_tree().root.get_child(0).add_child(car)
	
	print("✅ Car spawned at: ", spawn_pos)
