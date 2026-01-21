extends VehicleBody3D

@export var max_engine_force = 200.0
@export var max_brake_force = 5.0
@export var max_steer_angle = 0.5

@export var camera_distance = 3.0
@export var camera_height = 1.5

@onready var camera = $Camera3D
@onready var front_left = $FrontLeft
@onready var front_right = $FrontRight
@onready var rear_left = $RearLeft
@onready var rear_right = $RearRight

func _ready():
	if camera:
		camera.position = Vector3(0, camera_height, camera_distance)
		camera.rotation_degrees = Vector3(-10, 0, 0)

func _physics_process(delta):
	var accelerate = Input.get_action_strength("ui_up")
	var brake = Input.get_action_strength("ui_down")
	var steer_left = Input.get_action_strength("ui_left")
	var steer_right = Input.get_action_strength("ui_right")
	
	var steer = 0.0
	if steer_left:
		steer += steer_left
	if steer_right:
		steer -= steer_right
	steer = clamp(steer, -1.0, 1.0)
	
	if front_left and front_right:
		front_left.steering = steer * max_steer_angle
		front_right.steering = steer * max_steer_angle
	
	var engine = 0.0
	if accelerate > 0:
		engine = accelerate * max_engine_force
		rear_left.brake = 0
		rear_right.brake = 0
		front_left.brake = 0
		front_right.brake = 0
	elif brake > 0:
		var brake_force = brake * max_brake_force
		rear_left.brake = brake_force
		rear_right.brake = brake_force
		front_left.brake = brake_force
		front_right.brake = brake_force
	else:
		rear_left.brake = 0.5
		rear_right.brake = 0.5
		front_left.brake = 0.5
		front_right.brake = 0.5
	
	if rear_left and rear_right:
		rear_left.engine_force = engine
		rear_right.engine_force = engine

func _input(event):
	if event.is_action_pressed("ui_select"):
		reset_car()

func reset_car():
	global_transform.basis = Basis()
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
