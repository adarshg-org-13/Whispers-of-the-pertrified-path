extends Node

@export var wash_range = 10.0
@export var wash_key = KEY_E
@export var hold_duration = 0.5 

@export_group("UI/FX")
@export var water_particles_scene: PackedScene 
@export var money_sound: AudioStreamPlayer 
@export var wash_sound: AudioStreamPlayer # New: Assign your washing SFX here
@export var shake_intensity = 0.05 # New: Subtle camera shake

var key_hold_timer = 0.0
var current_washable_car = null
var total_money = 0
var is_washing = false
var ui: CanvasLayer 
var active_water_particles: GPUParticles3D = null
var target_progress_value = 0.0
var camera: Camera3D = null

func _ready():
	await get_tree().process_frame
	var player = get_parent()
	ui = player.get_node_or_null("UI")
	camera = get_viewport().get_camera_3d()
	update_money_ui()

func find_nearest_node3d_parent(start_node: Node) -> Node3D:
	var current_node = start_node
	while current_node != null:
		if current_node is Node3D:
			return current_node as Node3D
		current_node = current_node.get_parent()
	return null

func _process(delta):
	check_nearby_cars()
	
	if Input.is_key_pressed(wash_key) and current_washable_car:
		if current_washable_car.has_method("can_be_washed") and current_washable_car.can_be_washed():
			if not is_washing:
				key_hold_timer += delta 
				update_hold_prompt()
				if key_hold_timer >= hold_duration:
					start_washing()
					key_hold_timer = 0.0
			else:
				apply_camera_shake()
	else:
		if is_washing:
			stop_washing()
		if key_hold_timer > 0.0:
			key_hold_timer = 0.0
			update_ui_display()

func apply_camera_shake():
	if camera:
		camera.h_offset = randf_range(-shake_intensity, shake_intensity)
		camera.v_offset = randf_range(-shake_intensity, shake_intensity)

func _physics_process(delta):
	if is_washing and current_washable_car and ui:
		var dirt_percent = current_washable_car.get_dirt_percentage()
		var desired_value = 100.0 - dirt_percent 
		target_progress_value = desired_value 
		
		if desired_value >= 100.0:
			stop_washing()
			var reward = 50 
			if "money_to_earn" in current_washable_car:
				reward = current_washable_car.money_to_earn
			_on_car_washed(reward) 

	if ui:
		var progress_bar = ui.get_node_or_null("WashProgressBar")
		if progress_bar:
			progress_bar.value = lerp(progress_bar.value, target_progress_value, delta * 10.0)

func check_nearby_cars():
	var cars = get_tree().get_nodes_in_group("washable_cars")
	if cars.size() == 0: return
	
	var player_node3d = find_nearest_node3d_parent(self)
	if not player_node3d: return
	
	var player_pos = player_node3d.global_position
	var closest_car = null
	var closest_distance = wash_range + 1
	
	for car in cars:
		if not car.has_method("can_be_washed") or not car.can_be_washed(): continue
		
		var distance = player_pos.distance_to(car.global_position)
		if distance < wash_range and distance < closest_distance:
			closest_car = car
			closest_distance = distance
	
	if closest_car != current_washable_car:
		if current_washable_car and is_washing:
			stop_washing()
		current_washable_car = closest_car
		update_ui_display()

func start_washing():
	if not current_washable_car or is_washing: return
	
	is_washing = true
	
	if wash_sound:
		wash_sound.play()
		
	if current_washable_car.has_method("start_washing"):
		current_washable_car.start_washing()
	
	if water_particles_scene and not active_water_particles:
		var player = get_parent()
		var spawn_point = player.find_child("WaterSpawnPoint", true)
		var temp_node = water_particles_scene.instantiate()
		
		if spawn_point:
			spawn_point.add_child(temp_node)
		else:
			add_child(temp_node)
			temp_node.position = Vector3(0, 1.5, -1.5)
		
		if temp_node is GPUParticles3D:
			active_water_particles = temp_node
		else:
			active_water_particles = temp_node.find_child("*", true) as GPUParticles3D
		
		if active_water_particles:
			active_water_particles.set_use_local_coordinates(true)
			var mesh = active_water_particles.draw_pass_1
			if mesh and mesh.material:
				mesh.material.set("billboard_mode", 2)
				mesh.material.set("billboard_keep_scale", true)
			active_water_particles.emitting = true
	update_ui_display()

func stop_washing():
	if not is_washing: return
	is_washing = false
	
	if wash_sound:
		wash_sound.stop()
		
	if camera:
		camera.h_offset = 0
		camera.v_offset = 0
	
	if active_water_particles and is_instance_valid(active_water_particles):
		active_water_particles.emitting = false
		var wait_time = active_water_particles.lifetime
		await get_tree().create_timer(wait_time).timeout
		if is_instance_valid(active_water_particles):
			active_water_particles.queue_free()
			active_water_particles = null
	
	if current_washable_car and current_washable_car.has_method("stop_washing"):
		current_washable_car.stop_washing()
	update_ui_display()

func _on_car_washed(money_earned):
	total_money += money_earned
	if money_sound:
		money_sound.play()
	update_money_ui()
	show_money_popup(money_earned)
	current_washable_car = null
	is_washing = false
	update_ui_display()

func update_money_ui():
	if not ui: return
	var money_label = ui.get_node_or_null("MoneyLabel")
	if money_label:
		money_label.text = "$" + str(total_money)

func update_hold_prompt():
	if not ui: return
	var prompt_label = ui.get_node_or_null("PromptLabel")
	var hold_percent = int((key_hold_timer / hold_duration) * 100)
	if prompt_label and hold_percent < 100:
		prompt_label.text = "Hold E to wash car (" + str(hold_percent) + "%)"
		prompt_label.visible = true

func update_ui_display():
	if not ui: return
	var progress_bar = ui.get_node_or_null("WashProgressBar")
	var prompt_label = ui.get_node_or_null("PromptLabel")
	
	if is_washing:
		if progress_bar: progress_bar.visible = true
		if prompt_label: 
			prompt_label.text = "Washing..."
			prompt_label.visible = true
	elif current_washable_car:
		if progress_bar: progress_bar.visible = false
		if prompt_label: 
			prompt_label.text = "Press E to wash car"
			prompt_label.visible = true
	else:
		if progress_bar: progress_bar.visible = false
		if prompt_label: prompt_label.visible = false

func show_money_popup(amount):
	if not ui: return
	var popup = ui.get_node_or_null("MoneyPopup")
	if popup:
		popup.text = "+$" + str(amount)
		popup.visible = true
		popup.modulate = Color(0, 1, 0, 1) 
		var tween = create_tween().set_parallel(true)
		tween.tween_property(popup, "modulate:a", 0.0, 1.0).from(1.0)
		tween.tween_property(popup, "position:y", popup.position.y - 50, 1.0)
		await tween.finished
		popup.visible = false
		popup.position.y += 50
