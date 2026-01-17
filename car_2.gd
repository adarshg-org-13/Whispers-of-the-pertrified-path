extends VehicleBody3D

# Vehicle properties
const MAX_ENGINE_FORCE = 700.0
const MAX_BRAKE_FORCE = 10.0
const MAX_STEER_LEFT = 1  # Left turn sensitivity
const MAX_STEER_RIGHT = 1  # Right turn sensitivity (more sensitive now)
const STEER_SPEED = 5.0  # Increased for faster return to center

# Camera properties
const CAMERA_DISTANCE = 8.0
const CAMERA_HEIGHT = 3.5
const CAMERA_LERP_SPEED = 8.0
const CAMERA_LOOK_AHEAD = 2.0

@onready var input_label: Label3D = $Input_label
# Camera is now a sibling, not a child
@onready var camera: Camera3D = get_node_or_null("../Camera")
# Instructions UI - adjust path to match your scene structure
@onready var instructions: Control = get_node_or_null("../Control")

# Reference all wheels explicitly
@onready var wheel_fl: VehicleWheel3D = $WheelFL
@onready var wheel_fr: VehicleWheel3D = $WheelFR
@onready var wheel_rl: VehicleWheel3D = $WheelRL
@onready var wheel_rr: VehicleWheel3D = $WheelRR

var with_player = false
var current_steering = 0.0  # Track steering smoothly

func _ready() -> void:
	input_label.hide()
	
	# Hide instructions initially
	if instructions:
		instructions.hide()
		print("Instructions found and hidden")
	
	# CRITICAL: Configure wheels with better stability settings
	if wheel_fl:
		wheel_fl.use_as_steering = true
		wheel_fl.use_as_traction = true
		wheel_fl.wheel_friction_slip = 2.5  # Lower = better stability
		wheel_fl.suspension_stiffness = 80.0  # Higher = less bouncy
		wheel_fl.suspension_travel = 0.2  # Shorter = more stable
		wheel_fl.damping_compression = 0.9  # Higher = less oscillation
		wheel_fl.damping_relaxation = 0.95  # Higher = smoother
		wheel_fl.wheel_roll_influence = 0.1  # Lower = less tipping
	
	if wheel_fr:
		wheel_fr.use_as_steering = true
		wheel_fr.use_as_traction = true
		wheel_fr.wheel_friction_slip = 2.5
		wheel_fr.suspension_stiffness = 80.0
		wheel_fr.suspension_travel = 0.2
		wheel_fr.damping_compression = 0.9
		wheel_fr.damping_relaxation = 0.95
		wheel_fr.wheel_roll_influence = 0.1
	
	if wheel_rl:
		wheel_rl.use_as_steering = false
		wheel_rl.use_as_traction = true
		wheel_rl.wheel_friction_slip = 2.5
		wheel_rl.suspension_stiffness = 80.0
		wheel_rl.suspension_travel = 0.2
		wheel_rl.damping_compression = 0.9
		wheel_rl.damping_relaxation = 0.95
		wheel_rl.wheel_roll_influence = 0.1
	
	if wheel_rr:
		wheel_rr.use_as_steering = false
		wheel_rr.use_as_traction = true
		wheel_rr.wheel_friction_slip = 2.5
		wheel_rr.suspension_stiffness = 80.0
		wheel_rr.suspension_travel = 0.2
		wheel_rr.damping_compression = 0.9
		wheel_rr.damping_relaxation = 0.95
		wheel_rr.wheel_roll_influence = 0.1
	
	# Set up camera
	if camera:
		camera.set_as_top_level(true)
	
	print("Vehicle ready! Mass: ", mass)

func _physics_process(delta: float) -> void:
	# Always update camera if player is in car
	if camera and with_player:
		_update_camera(delta)
	
	if not with_player:
		# COMPLETE STOP when player is not in car
		engine_force = 0
		brake = MAX_BRAKE_FORCE
		steering = 0
		current_steering = 0
		
		# Force velocity to zero to prevent drifting
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
		return
	
	# Get input - Correct mapping
	var input_dir := Input.get_vector("right", "left", "up", "down")
	
	# Asymmetric steering - different sensitivity for left vs right
	var target_steering = 0.0
	if input_dir.x < 0:  # Turning left (A key)
		target_steering = input_dir.x * MAX_STEER_LEFT
	elif input_dir.x > 0:  # Turning right (D key)
		target_steering = input_dir.x * MAX_STEER_RIGHT
	
	# Smooth steering with gradual return to center
	current_steering = lerp(current_steering, target_steering, STEER_SPEED * delta)
	steering = current_steering
	
	# Engine force (forward/backward - up/down keys)
	if input_dir.y < 0: # Forward (W or Up)
		engine_force = MAX_ENGINE_FORCE
		brake = 0
	elif input_dir.y > 0: # Backward (S or Down)
		engine_force = -MAX_ENGINE_FORCE * 0.5
		brake = 0
	else:
		# No input - apply light brake and no engine
		engine_force = 0
		brake = MAX_BRAKE_FORCE * 0.3
	
	# Handbrake
	if Input.is_action_pressed("ui_accept"):
		brake = MAX_BRAKE_FORCE
		engine_force = 0

func _update_camera(delta: float) -> void:
	if not camera:
		return
	
	# Get the car's transform
	var car_transform = global_transform
	
	# Calculate the direction behind the car
	var back_direction = -car_transform.basis.z
	var up_direction = Vector3.UP
	
	# Target position: behind and above the car
	var target_position = global_position + (back_direction * CAMERA_DISTANCE) + (up_direction * CAMERA_HEIGHT)
	
	# Smoothly move camera to target position
	camera.global_position = camera.global_position.lerp(target_position, CAMERA_LERP_SPEED * delta)
	
	# Calculate the point to look at (slightly ahead of car and higher)
	var look_at_position = global_position + (car_transform.basis.z * CAMERA_LOOK_AHEAD) + Vector3.UP * 1.0
	
	# Make camera look at that point
	camera.look_at(look_at_position, Vector3.UP)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		input_label.show()

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		input_label.hide()

func _input(event: InputEvent) -> void:
	var can_enter = input_label.visible and not with_player 
	var can_leave = with_player
	
	if Input.is_action_just_pressed("interact") and can_enter:
		_enter_car()
	elif Input.is_action_just_pressed("interact") and can_leave:
		_leave_car()

func _enter_car() -> void:
	with_player = true
	print("Player entered car!")
	
	# Show instructions when entering car
	if instructions:
		instructions.show()
		print("Instructions shown")
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.enter_car()
		if player.has_method("hide"):
			player.hide()
	
	input_label.hide()
	
	# Initialize camera position
	if camera:
		var back_dir = -global_transform.basis.z
		camera.global_position = global_position + (back_dir * CAMERA_DISTANCE) + Vector3.UP * CAMERA_HEIGHT
	
	# Reset steering when entering
	current_steering = 0.0
	steering = 0.0

func _leave_car() -> void:
	with_player = false
	print("Player left car!")
	
	# Hide instructions when leaving car
	if instructions:
		instructions.hide()
		print("Instructions hidden")
	
	# FIRST: Stop the car completely
	engine_force = 0
	brake = MAX_BRAKE_FORCE
	steering = 0
	current_steering = 0
	
	# Force all velocities to zero
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	
	# THEN: Handle player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.leave_car()
		# Position player next to the car (driver side)
		var exit_offset = global_transform.basis.x * 3.0
		player.global_position = global_position + exit_offset + Vector3.UP * 0.5
		
		if player.has_method("show"):
			player.show()
