# DrivableCar.gd
# Attach this to VehicleBody3D in your Vehicle_player scene
extends VehicleBody3D

# Car properties
@export var max_engine_force = 200.0
@export var max_brake_force = 5.0
@export var max_steer_angle = 0.5

# Camera properties
@export var camera_distance = 3.0
@export var camera_height = 1.5

# Enter/Exit properties
@export var interaction_distance = 3.0

@onready var camera = $Camera3D
@onready var front_left = $FrontLeft
@onready var front_right = $FrontRight
@onready var rear_left = $RearLeft
@onready var rear_right = $RearRight

var is_player_inside = false
var player: CharacterBody3D
var player_camera: Camera3D
var ui: CanvasLayer
var washing_system: Node

func _ready():
	# Setup camera position (front view of car)
	if camera:
		camera.position = Vector3(0, camera_height, camera_distance)
		camera.rotation_degrees = Vector3(-10, 0, 0)
		camera.current = false  # Start with camera off
	
	print("🚗 Car ready! Walk close and press F to enter")

func _physics_process(delta):
	# Check for nearby player when not inside
	if not is_player_inside:
		check_for_player()
	else:
		# Drive the car
		drive_car()

func check_for_player():
	# Find player if not found yet
	if not player:
		player = get_tree().get_first_node_in_group("player")
		if not player:
			# Try direct search
			player = get_tree().root.get_node_or_null("Main/Player")
		
		# Find UI and washing system
		if player:
			ui = player.get_node_or_null("UI")
			washing_system = player.get_node_or_null("WashingSystem")
		
		if not player:
			return
	
	# Check distance
	var distance = global_position.distance_to(player.global_position)
	
	if distance <= interaction_distance:
		# Show prompt
		show_prompt("Press F to enter car")
		
		# Check for input (F key)
		if Input.is_key_pressed(KEY_F):
			enter_car()
	else:
		hide_prompt()

func enter_car():
	if not player:
		return
	
	is_player_inside = true
	
	# Hide player
	player.visible = false
	
	# Disable player movement
	player.set_can_move(false)
	
	# Store player's camera and disable it
	player_camera = player.get_node_or_null("Head/Camera3D")
	if player_camera:
		player_camera.current = false
	
	# Enable car camera
	if camera:
		camera.current = true
	
	# Hide washing UI prompts
	hide_prompt()
	
	# Stop any active washing
	if washing_system and washing_system.has_method("stop_washing"):
		washing_system.stop_washing()
	
	print("🚗 Entered car! Use WASD to drive, E to exit")

func exit_car():
	if not player:
		return
	
	is_player_inside = false
	
	# Position player next to car (on the side)
	player.global_position = global_position + Vector3(2.5, 1, 0)
	
	# Show player
	player.visible = true
	
	# Enable player movement
	player.set_can_move(true)
	
	# Restore player camera
	if player_camera:
		player_camera.current = true
	
	# Disable car camera
	if camera:
		camera.current = false
	
	print("🚶 Exited car!")

func drive_car():
	# Check for exit input (E key)
	if Input.is_key_pressed(KEY_E):
		exit_car()
		return
	
	# Get input
	var accelerate = Input.get_action_strength("ui_up")
	var brake_input = Input.get_action_strength("ui_down")
	var steer_left = Input.get_action_strength("ui_left")
	var steer_right = Input.get_action_strength("ui_right")
	
	# Calculate steering
	var steer = 0.0
	if steer_left:
		steer += steer_left
	if steer_right:
		steer -= steer_right
	steer = clamp(steer, -1.0, 1.0)
	
	# Apply steering to front wheels
	if front_left and front_right:
		front_left.steering = steer * max_steer_angle
		front_right.steering = steer * max_steer_angle
	
	# Apply engine force
	var engine = 0.0
	if accelerate > 0:
		engine = accelerate * max_engine_force
		# Release brake when accelerating
		if rear_left and rear_right:
			rear_left.brake = 0
			rear_right.brake = 0
		if front_left and front_right:
			front_left.brake = 0
			front_right.brake = 0
	elif brake_input > 0:
		# Apply brake
		var brake_force = brake_input * max_brake_force
		if rear_left and rear_right:
			rear_left.brake = brake_force
			rear_right.brake = brake_force
		if front_left and front_right:
			front_left.brake = brake_force
			front_right.brake = brake_force
	else:
		# No input - slight brake for stopping
		if rear_left and rear_right:
			rear_left.brake = 0.5
			rear_right.brake = 0.5
		if front_left and front_right:
			front_left.brake = 0.5
			front_right.brake = 0.5
	
	# Apply engine force to rear wheels
	if rear_left and rear_right:
		rear_left.engine_force = engine
		rear_right.engine_force = engine

func show_prompt(text: String):
	if ui:
		var prompt_label = ui.get_node_or_null("PromptLabel")
		if prompt_label:
			prompt_label.text = text
			prompt_label.visible = true

func hide_prompt():
	if ui:
		var prompt_label = ui.get_node_or_null("PromptLabel")
		if prompt_label:
			prompt_label.visible = false

func _input(event):
	# Reset car if it flips (only when inside) - Spacebar
	if is_player_inside and event.is_action_pressed("ui_select"):
		reset_car()

func reset_car():
	# Reset car to upright position
	global_transform.basis = Basis()
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	print("🔄 Car reset!")
