extends Node3D

@export var wash_range = 3.0
@export var wash_key = KEY_E

var current_washable_car = null
var total_money = 0
var is_washing = false
var ui

func _ready():
	ui = get_node_or_null("/root/player/UI/WashingUI")
	if not ui:
		print("Warning: UI not found! Check the path in WashingSystem.gd")
	update_money_ui()

func _process(delta):
	check_nearby_cars()
	
	if Input.is_key_pressed(wash_key) and current_washable_car:
		if current_washable_car.can_be_washed():
			start_washing()
	else:
		if is_washing:
			stop_washing()

func check_nearby_cars():
	var cars = get_tree().get_nodes_in_group("washable_cars")
	# GET PLAYER POSITION FROM PARENT
	var player_pos = get_parent().global_transform.origin  # ← CHANGED THIS LINE
	var closest_car = null
	var closest_distance = wash_range + 1
	
	for car in cars:
		if not car.has_method("can_be_washed") or not car.can_be_washed():
			continue
		
		var distance = player_pos.distance_to(car.global_transform.origin)
		if distance < wash_range and distance < closest_distance:
			closest_car = car
			closest_distance = distance
	
	if closest_car != current_washable_car:
		if current_washable_car:
			stop_washing()
		current_washable_car = closest_car
		update_prompt_ui()

func start_washing():
	if not current_washable_car or not current_washable_car.can_be_washed():
		return
	
	is_washing = true
	current_washable_car.start_washing()
	
	if not current_washable_car.car_washed.is_connected(_on_car_washed):
		current_washable_car.car_washed.connect(_on_car_washed)
	
	update_washing_ui()

func stop_washing():
	if current_washable_car:
		current_washable_car.stop_washing()
	is_washing = false
	update_washing_ui()

func _on_car_washed(money_earned):
	total_money += money_earned
	update_money_ui()
	show_money_popup(money_earned)

func update_money_ui():
	if ui and ui.has_node("MoneyLabel"):
		ui.get_node("MoneyLabel").text = "Money: $" + str(total_money)

func update_washing_ui():
	if not ui:
		return
	
	if current_washable_car and is_washing:
		if ui.has_node("WashProgressBar"):
			ui.get_node("WashProgressBar").visible = true
		if ui.has_node("PromptLabel"):
			ui.get_node("PromptLabel").text = "Washing... (Release E to stop)"
	elif current_washable_car and current_washable_car.can_be_washed():
		if ui.has_node("WashProgressBar"):
			ui.get_node("WashProgressBar").visible = false
		if ui.has_node("PromptLabel"):
			ui.get_node("PromptLabel").text = "Press E to wash car"
	else:
		if ui.has_node("WashProgressBar"):
			ui.get_node("WashProgressBar").visible = false
		if ui.has_node("PromptLabel"):
			ui.get_node("PromptLabel").text = ""

func update_prompt_ui():
	update_washing_ui()

func _physics_process(delta):
	if is_washing and current_washable_car and ui:
		if ui.has_node("WashProgressBar"):
			var progress_bar = ui.get_node("WashProgressBar")
			progress_bar.value = 100 - current_washable_car.get_dirt_percentage()

func show_money_popup(amount):
	if ui and ui.has_node("MoneyPopup"):
		var popup = ui.get_node("MoneyPopup")
		popup.text = "+$" + str(amount)
		popup.visible = true
		
		# Simple timer to hide popup
		await get_tree().create_timer(1.5).timeout
		popup.visible = false
