extends VehicleBody3D

@export var max_engine_force: float = 400.0  # Tune for Lambo speed
@export var max_steer_angle: float = 0.45     # radians (~26°)
@export var steer_speed: float = 3.5
@export var brake_intensity: float = 5.0

# Physics wheels (must match your node names exactly!)
@onready var fl_wheel: VehicleWheel3D = $FL
@onready var fr_wheel: VehicleWheel3D = $FR
@onready var rl_wheel: VehicleWheel3D = $RL
@onready var rr_wheel: VehicleWheel3D = $RR

# Visual wheel meshes (double-check paths in your scene tree!)
@onready var fl_mesh: MeshInstance3D = $CAR Model/Lamborghini Aventador Wheel FL
@onready var fr_mesh: MeshInstance3D = $CAR Model/Lamborghini Aventador Wheel FR
@onready var rl_mesh: MeshInstance3D = $CAR Model/Lamborghini Aventador Wheel RL
@onready var rr_mesh: MeshInstance3D = $CAR Model/Lamborghini Aventador Wheel RR

var driver: Node3D = null

func enter_vehicle_player(player: Node3D) -> void:
	if driver != null:
		return
	driver = player
	print("🏎️ Entered Lambo!")

func exit_vehicle_player(player: Node3D) -> void:
	if driver != player:
		return
	driver = null
	print("Exited Lambo!")

func _physics_process(delta: float) -> void:
	if driver == null:
		engine_force = 0.0
		brake = 0.0
		steering = move_toward(steering, 0.0, steer_speed * delta)
		return

	# Player input
	var forward_input = Input.get_action_strength("up") - Input.get_action_strength("down")
	var turn_input = Input.get_action_strength("right") - Input.get_action_strength("left")

	engine_force = forward_input * max_engine_force
	steering = lerp_angle(steering, turn_input * max_steer_angle, steer_speed * delta)
	brake = Input.get_action_strength("brake") * brake_intensity

	# Sync visual wheels to physics (position, suspension, steering + spin)
	_sync_visual_wheel(fl_wheel, fl_mesh, delta)
	_sync_visual_wheel(fr_wheel, fr_mesh, delta)
	_sync_visual_wheel(rl_wheel, rl_mesh, delta)
	_sync_visual_wheel(rr_wheel, rr_mesh, delta)

func _sync_visual_wheel(physics_wheel: VehicleWheel3D, visual_mesh: MeshInstance3D, delta: float) -> void:
	if visual_mesh == null or physics_wheel == null:
		return

	# 1. Full transform copy → fixes detaching/floating tires
	visual_mesh.global_transform = physics_wheel.global_transform

	# 2. Apply wheel spin using get_rpm() (Godot 4 correct method)
	var rpm = physics_wheel.get_rpm()                     # Built-in RPM
	var angular_speed = rpm * (2 * PI) / 60.0              # Convert to rad/s
	var spin_this_frame = angular_speed * delta

	# 3. Rotate visual mesh (test axis: most wheels use X or Z)
	visual_mesh.rotate_object_local(Vector3.RIGHT, spin_this_frame)  # Try Vector3.RIGHT first
	# If spin is wrong direction → change to Vector3.FORWARD or negate: -spin_this_frame
	# If no spin visible → check if get_rpm() > 0 when driving (print(rpm))
