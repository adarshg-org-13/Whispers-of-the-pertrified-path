extends Node

@export var wash_range = 10.0
@export var wash_key = KEY_E

# New variables for the hold timer
@export var hold_duration = 0.5 
var key_hold_timer = 0.0

# UI/FX References
@export_group("UI/FX")
@export var water_particles_scene: PackedScene # Link WaterParticles.tscn here!

var current_washable_car = null
var total_money = 0
var is_washing = false
var ui: CanvasLayer # Assuming your UI is a CanvasLayer or Control node
var active_water_particles: GPUParticles3D = null

# New variable for smooth progress bar update
var target_progress_value = 0.0

func _ready():
	print("=== WashingSystem Starting ===")
	
	await get_tree().process_frame
	
	var player = get_parent()
	ui = player.get_node_or_null("UI")
	
	if not ui:
		print("❌ ERROR: UI not found as child of Player!")
	else:
		print("✅ UI found at: ", ui.get_path())
		test_ui_nodes()
	
	update_money_ui()

# Helper function to find a valid 3D home for the particles, 
# starting from the current node's parent and moving up the tree.
func find_nearest_node3d_parent(start_node: Node) -> Node3D:
	var current_node = start_node
	# Traverse up the tree until a Node3D is found or we hit the scene root
	while current_node != null:
		if current_node is Node3D:
			return current_node as Node3D
		current_node = current_node.get_parent()
	return null

func _process(delta):
	check_nearby_cars()
	
	# Check for wash input (MODIFIED FOR KEY HOLD)
	if Input.is_key_pressed(wash_key) and current_washable_car:
		if current_washable_car.has_method("can_be_washed") and current_washable_car.can_be_washed():
			
			if not is_washing:
				# Increment the timer only if we are not already washing
				key_hold_timer += delta 
				
				update_hold_prompt() # Show hold progress
				
				if key_hold_timer >= hold_duration:
					start_washing()
					key_hold_timer = 0.0 # Reset timer upon starting
	else:
		# If key is released or car is unavailable
		if is_washing:
			stop_washing()

		# Reset the timer immediately if key is released before washing starts
		if key_hold_timer > 0.0:
			key_hold_timer = 0.0
			update_ui_display() # Update UI to remove the hold prompt

func _physics_process(delta):
	# 1. Update target progress value while washing
	if is_washing and current_washable_car and ui:
		var dirt_percent = current_washable_car.get_dirt_percentage()
		var desired_value = 100.0 - dirt_percent 
		target_progress_value = desired_value 
		
		if Engine.get_frames_drawn() % 60 == 0:
			print("🧽 Washing: ", int(desired_value), "% complete")

	# 2. Smoothly interpolate the progress bar value (smooth animation)
	if ui:
		var progress_bar = ui.get_node_or_null("WashProgressBar")
		if progress_bar:
			# lerp(current_value, target_value, speed)
			progress_bar.value = lerp(progress_bar.value, target_progress_value, delta * 10.0)

func check_nearby_cars():
	# MODIFIED to use Node3D parent for positioning if needed
	var cars = get_tree().get_nodes_in_group("washable_cars")
	
	if cars.size() == 0:
		return
	
	var player_node3d = find_nearest_node3d_parent(self)
	if not player_node3d:
		return
	
	var player_pos = player_node3d.global_position
	var closest_car = null
	var closest_distance = wash_range + 1
	
	for car in cars:
		if not car.has_method("can_be_washed"):
			continue
		
		if not car.can_be_washed():
			continue
		
		var distance = player_pos.distance_to(car.global_position)
		
		if distance < wash_range and distance < closest_distance:
			closest_car = car
			closest_distance = distance
	
	# Update current car
	if closest_car != current_washable_car:
		if current_washable_car and is_washing:
			stop_washing()
		
		current_washable_car = closest_car
		update_ui_display()

func start_washing():
	if not current_washable_car or is_washing:
		return
	
	print("🧽 Started washing car and activating particles!")
	is_washing = true
	
	# Start washing on car
	if current_washable_car.has_method("start_washing"):
		current_washable_car.start_washing()
	
	# Connect to signal if not already connected
	if current_washable_car and current_washable_car.has_signal("car_washed"):
		if not current_washable_car.car_washed.is_connected(_on_car_washed):
			current_washable_car.car_washed.connect(_on_car_washed)
			print("  Connected to car_washed signal")

	# --- PARTICLE ACTIVATION CODE ---
	if water_particles_scene and not active_water_particles:
		var attach_target = find_nearest_node3d_parent(self) 
		
		if attach_target and is_instance_valid(attach_target):
			
			active_water_particles = water_particles_scene.instantiate() as GPUParticles3D
			
			if is_instance_valid(active_water_particles):
				
				attach_target.add_child(active_water_particles)
				
				# Position the particles relative to the attach_target (Player/Body)
				active_water_particles.global_transform = attach_target.global_transform
				active_water_particles.position = Vector3(0, 1.0, 0.5) 
				
				active_water_particles.emitting = true
				
		else:
			print("❌ ERROR: Could not find a Node3D to attach particles.")
	
	update_ui_display()

func stop_washing():
	if not is_washing:
		return
		
	print("🛑 Stopped washing and deactivating particles.")
	is_washing = false
	
	# Stop and clean up particles
	if active_water_particles and is_instance_valid(active_water_particles):
		active_water_particles.emitting = false
		
		# Wait for the remaining particles to finish their flight before deleting the node
		if active_water_particles.has_method("get_process_material"):
			var process_mat = active_water_particles.get_process_material()
			if process_mat and process_mat.has_property("lifetime"):
				await get_tree().create_timer(active_water_particles.lifetime).timeout
		else:
			# Fallback delay if lifetime property isn't found
			await get_tree().create_timer(1.0).timeout 
		
		if is_instance_valid(active_water_particles):
			active_water_particles.queue_free()
			active_water_particles = null
	
	if current_washable_car and current_washable_car.has_method("stop_washing"):
		current_washable_car.stop_washing()
	
	update_ui_display()

func _on_car_washed(money_earned):
	print("💰💰💰 CAR WASHED! Earned: $", money_earned)
	
	total_money += money_earned
	print("   Total money now: $", total_money)
	
	update_money_ui()
	show_money_popup(money_earned)
	
	current_washable_car = null
	is_washing = false
	update_ui_display()

func update_money_ui():
	print("=== Updating Money UI ===")
	
	if not ui:
		return
	
	var money_label = ui.get_node_or_null("MoneyLabel")
	if money_label:
		var new_text = "Money: $" + str(total_money)
		money_label.text = new_text
		money_label.visible = true
		
		# Flash Animation using Tween
		var tween = money_label.create_tween()
		money_label.modulate = Color.GREEN # Flash color
		# Tween back to opaque white over 0.25 seconds
		tween.tween_property(money_label, "modulate", Color.WHITE, 0.25).set_ease(Tween.EASE_OUT)
		
	else:
		print("   ❌ MoneyLabel not found")

func update_hold_prompt():
	if not ui:
		return

	var prompt_label = ui.get_node_or_null("PromptLabel")
	
	# Calculate key hold progress percentage
	var hold_percent = int((key_hold_timer / hold_duration) * 100)
	
	if prompt_label and hold_percent < 100:
		prompt_label.text = "Hold E to wash car (" + str(hold_percent) + "%)"
		prompt_label.visible = true

func update_ui_display():
	if not ui:
		return
	
	# Check if the player is currently holding the key to avoid overriding the hold prompt
	if key_hold_timer > 0.0 and not is_washing:
		update_hold_prompt()
		return
	
	var progress_bar = ui.get_node_or_null("WashProgressBar")
	var prompt_label = ui.get_node_or_null("PromptLabel")
	
	if is_washing and current_washable_car:
		# Washing mode
		if progress_bar:
			progress_bar.visible = true
			print("📊 Progress bar: VISIBLE")
		
		if prompt_label:
			prompt_label.text = "Washing... (Release E to stop)"
			prompt_label.visible = true
	
	elif current_washable_car:
		# Can wash mode
		if progress_bar:
			progress_bar.visible = false
		
		if prompt_label:
			prompt_label.text = "Press E to wash car"
			prompt_label.visible = true
	
	else:
		# No car nearby
		if progress_bar:
			progress_bar.visible = false
		
		if prompt_label:
			prompt_label.text = ""
			prompt_label.visible = false

func show_money_popup(amount):
	if not ui:
		return
	
	var popup = ui.get_node_or_null("MoneyPopup")
	if popup:
		popup.text = "+$" + str(amount)
		popup.visible = true
		popup.modulate = Color(0, 1, 0, 1)
		
		# Fade out using Tween
		var tween = popup.create_tween()
		tween.tween_interval(1.0) 
		tween.tween_property(popup, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_OUT)
		
		await tween.finished
		
		if is_instance_valid(popup):
			popup.visible = false
			popup.modulate.a = 1.0 # Reset alpha

# DEBUG FUNCTION (Test UI nodes)
func test_ui_nodes():
	if not ui:
		return
	
	print("=== Testing UI Nodes ===")
	
	var money_label = ui.get_node_or_null("MoneyLabel")
	var prompt_label = ui.get_node_or_null("PromptLabel")
	var progress_bar = ui.get_node_or_null("WashProgressBar")
	var popup = ui.get_node_or_null("MoneyPopup")
	
	print("MoneyLabel: ", "✅ FOUND" if money_label else "❌ NOT FOUND")
	print("PromptLabel: ", "✅ FOUND" if prompt_label else "❌ NOT FOUND")
	print("WashProgressBar: ", "✅ FOUND" if progress_bar else "❌ NOT FOUND")
	print("MoneyPopup: ", "✅ FOUND" if popup else "❌ NOT FOUND")

# DEBUG FUNCTION (Manual Tests)
func _input(event):
	# Press T to test UI
	if Input.is_key_pressed(KEY_T):
		print("\n========== TESTING UI ==========")
		total_money += 50
		update_money_ui()
	
	# Press Y to manually trigger car wash completion (for testing)
	if Input.is_key_pressed(KEY_Y):
		print("🧪 Manual test: Simulating car wash complete")
		_on_car_washed(100)
