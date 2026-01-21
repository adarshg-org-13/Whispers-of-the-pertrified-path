extends VehicleBody3D

const MAX_ENGINE_FORCE = 700.0
const MAX_BRAKE_FORCE = 10.0
const MAX_STEER_LEFT = 1
const MAX_STEER_RIGHT = 1
const STEER_SPEED = 5.0

const CAMERA_DISTANCE = 8.0
const CAMERA_HEIGHT = 3.5
const CAMERA_LERP_SPEED = 8.0
const CAMERA_LOOK_AHEAD = 2.0

@onready var input_label: Label3D = $Input_label
@onready var camera: Camera3D = get_node_or_null("../Camera")
@onready var instructions: Control = get_node_or_null("../Control")

@onready var wheel_fl: VehicleWheel3D = $WheelFL
@onready var wheel_fr: VehicleWheel3D = $WheelFR
@onready var wheel_rl: VehicleWheel3D = $WheelRL
@onready var wheel_rr: VehicleWheel3D = $WheelRR

@export_group("Audio")
@export var engine_sound: AudioStreamPlayer3D
@export var screech_sound: AudioStreamPlayer3D 
@export var min_pitch = 0.8
@export var max_pitch = 2.5
@export var max_speed_for_pitch = 20.0
@export var drift_threshold = 4.0 
@export var pitch_smooth_speed = 5.0 
@export var brake_required_time = 1.5 

var with_player = false
var current_steering = 0.0
var current_engine_pitch = 1.0 
var brake_timer = 0.0 

func _ready() -> void:
	input_label.hide()
	if instructions: instructions.hide()
	
	if engine_sound: 
		engine_sound.stop()
	if screech_sound: 
		screech_sound.stop()
	
	var wheels = [wheel_fl, wheel_fr, wheel_rl, wheel_rr]
	for i in range(wheels.size()):
		var wheel = wheels[i]
		if wheel:
			wheel.use_as_steering = true if i < 2 else false
			wheel.use_as_traction = true
			wheel.wheel_friction_slip = 2.5
			wheel.suspension_stiffness = 80.0
			wheel.suspension_travel = 0.2
			wheel.damping_compression = 0.9
			wheel.damping_relaxation = 0.95
			wheel.wheel_roll_influence = 0.1
	
	if camera: camera.set_as_top_level(true)

func _physics_process(delta: float) -> void:
	if camera and with_player:
		_update_camera(delta)
	
	_handle_car_audio(delta)

	if not with_player:
		engine_force = 0
		brake = MAX_BRAKE_FORCE
		steering = 0
		current_steering = 0
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
		return
	
	var input_dir := Input.get_vector("right", "left", "up", "down")
	var target_steering = 0.0
	
	if input_dir.x < 0:
		target_steering = input_dir.x * MAX_STEER_LEFT
	elif input_dir.x > 0:
		target_steering = input_dir.x * MAX_STEER_RIGHT
	
	current_steering = lerp(current_steering, target_steering, STEER_SPEED * delta)
	steering = current_steering
	
	if input_dir.y < 0:
		engine_force = MAX_ENGINE_FORCE
		brake = 0
	elif input_dir.y > 0:
		engine_force = -MAX_ENGINE_FORCE * 0.5
		brake = 0
	else:
		engine_force = 0
		brake = MAX_BRAKE_FORCE * 0.3
	
	if Input.is_action_pressed("ui_accept"):
		brake = MAX_BRAKE_FORCE
		engine_force = 0

func _handle_car_audio(delta: float):
	if not with_player:
		if engine_sound and engine_sound.playing: engine_sound.stop()
		if screech_sound and screech_sound.playing: screech_sound.stop()
		brake_timer = 0.0
		return

	if engine_sound:
		if not engine_sound.playing: engine_sound.play()
		var speed = linear_velocity.length()
		var target_pitch = lerp(min_pitch, max_pitch, clamp(speed / max_speed_for_pitch, 0.0, 1.0))
		current_engine_pitch = lerp(current_engine_pitch, target_pitch, pitch_smooth_speed * delta)
		engine_sound.pitch_scale = current_engine_pitch

	if screech_sound:
		var lateral_velocity = global_transform.basis.x.dot(linear_velocity)
		var is_hard_braking = Input.is_action_pressed("ui_accept") or Input.is_action_pressed("down")
		var is_skidding = (abs(lateral_velocity) > drift_threshold or (is_hard_braking and linear_velocity.length() > 5.0))
		
		if is_skidding:
			brake_timer += delta
			if brake_timer >= brake_required_time:
				if not screech_sound.playing: 
					screech_sound.play()
		else:
			brake_timer = 0.0
			if screech_sound.playing: 
				screech_sound.stop()

func _update_camera(delta: float) -> void:
	if not camera: return
	var car_transform = global_transform
	var back_direction = -car_transform.basis.z
	var up_direction = Vector3.UP
	var target_position = global_position + (back_direction * CAMERA_DISTANCE) + (up_direction * CAMERA_HEIGHT)
	camera.global_position = camera.global_position.lerp(target_position, CAMERA_LERP_SPEED * delta)
	var look_at_position = global_position + (car_transform.basis.z * CAMERA_LOOK_AHEAD) + Vector3.UP * 1.0
	camera.look_at(look_at_position, Vector3.UP)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"): input_label.show()

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"): input_label.hide()

func _input(event: InputEvent) -> void:
	var can_enter = input_label.visible and not with_player 
	var can_leave = with_player
	if Input.is_action_just_pressed("interact") and can_enter:
		_enter_car()
	elif Input.is_action_just_pressed("interact") and can_leave:
		_leave_car()

func _enter_car() -> void:
	with_player = true
	if instructions: instructions.show()
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.enter_car()
		if player.has_method("hide"): player.hide()
	input_label.hide()
	if camera:
		var back_dir = -global_transform.basis.z
		camera.global_position = global_position + (back_dir * CAMERA_DISTANCE) + Vector3.UP * CAMERA_HEIGHT
	current_steering = 0.0
	steering = 0.0

func _leave_car() -> void:
	with_player = false
	if instructions: instructions.hide()
	engine_force = 0
	brake = MAX_BRAKE_FORCE
	steering = 0
	current_steering = 0
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	brake_timer = 0.0
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.leave_car()
		var exit_offset = global_transform.basis.x * 3.0
		player.global_position = global_position + exit_offset + Vector3.UP * 0.5
		if player.has_method("show"): player.show()
