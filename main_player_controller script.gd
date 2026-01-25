extends CharacterBody3D

signal interact_object
var collider
var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 5
const SENSITIVITY = 0.004

const BOB_FREQ = 2.4
const BOB_AMP = 0.08
var t_bob = 0.0

const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

@export_group("Audio")
@export var footstep_audio: AudioStreamPlayer3D 
@export var step_distance: float = 2.2 
@export var walk_volume_db: float = -10.0 
@export var sprint_volume_db: float = -2.0 

var distance_walked: float = 0.0

var gravity = 10.1
var can_move = true

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var ray_cast_3d = $Head/Camera3D/RayCast3D

func _ready():
	camera.current = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	
	if footstep_audio:
		footstep_audio.autoplay = false
		footstep_audio.volume_db = -80.0

func _process(delta: float) -> void:	
	if ray_cast_3d.is_colliding():
		collider = ray_cast_3d.get_collider()
		interact_object.emit(collider)
	else: 
		interact_object.emit(null)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-85), deg_to_rad(90))

func _physics_process(delta):	
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	var is_sprinting = Input.is_action_pressed("sprint")
	speed = SPRINT_SPEED if is_sprinting else WALK_SPEED

	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var has_input = input_dir.length() > 0.1
	var is_moving = has_input and is_on_floor() and can_move
	
	if is_on_floor():
		if has_input: 
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			
			if can_move:
				_handle_footsteps(delta, is_sprinting)
				t_bob += delta * velocity.length()
				camera.transform.origin = _headbob(t_bob)
		else:
			velocity.x = 0
			velocity.z = 0
			distance_walked = 0
			t_bob = 0.0 
			camera.transform.origin = Vector3.ZERO 
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
		camera.transform.origin = camera.transform.origin.lerp(Vector3.ZERO, delta * 5.0)

	if footstep_audio:
		if not is_moving:
			footstep_audio.volume_db = -80.0
			if footstep_audio.playing:
				footstep_audio.stop()
		else:
			footstep_audio.volume_db = sprint_volume_db if is_sprinting else walk_volume_db

	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	if not can_move:
		return
	move_and_slide()

func _handle_footsteps(delta: float, sprinting: bool):
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	
	if horizontal_speed > 1.5:
		distance_walked += horizontal_speed * delta
		
		if distance_walked >= step_distance:
			if footstep_audio:
				footstep_audio.pitch_scale = randf_range(0.85, 1.15)
				footstep_audio.play()
			distance_walked = 0.0

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

func enter_car():
	set_physics_process(false)
	hide()
	camera.current = false
	if footstep_audio: 
		footstep_audio.stop()
		footstep_audio.volume_db = -80.0
	
func leave_car():
	set_physics_process(true)
	show()
	camera.current = true

func set_can_move(value: bool):
	can_move = value
	if not can_move:
		velocity = Vector3.ZERO
		camera.transform.origin = Vector3.ZERO
		if footstep_audio: 
			footstep_audio.volume_db = -80.0

#END
