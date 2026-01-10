extends Node3D

# Spawn settings
@export var spawn_point_path: NodePath
@export var wash_point_path: NodePath
@export var exit_point_path: NodePath
@export var time_between_spawns = 5.0

# Car settings
@export var car_speed = 3.0
@export var rotation_speed = 2.0

# Car prefabs
@export var car_scenes: Array[PackedScene] = []

var current_car = null
var spawn_timer = 0.0
var can_spawn = true

var spawn_point
var wash_point
var exit_point

func _ready():
	# Get node references
	spawn_point = get_node(spawn_point_path)
	wash_point = get_node(wash_point_path)
	exit_point = get_node(exit_point_path)
	
	if car_scenes.size() == 0:
		print("Warning: No car scenes assigned to spawner!")
		return
	
	# Spawn first car
	spawn_car()

func _process(delta):
	# Check if we can spawn a new car
	if can_spawn and current_car == null:
		spawn_timer += delta
		if spawn_timer >= time_between_spawns:
			spawn_car()
			spawn_timer = 0.0

func spawn_car():
	if car_scenes.size() == 0:
		return
	
	# Pick random car
	var car_scene = car_scenes[randi() % car_scenes.size()]
	var car = car_scene.instantiate()
	
	# Position at spawn point
	add_child(car)
	car.global_transform.origin = spawn_point.global_transform.origin
	
	# Setup car
	if car.has_method("set_target"):
		car.set_target(wash_point.global_transform.origin)
		car.set_speed(car_speed)
		car.reached_destination.connect(_on_car_reached_wash_point)
		car.car_washed.connect(_on_car_washed)
	
	current_car = car
	can_spawn = false

func _on_car_reached_wash_point(car):
	print("Car arrived at washing point!")
	# Car is now ready to be washed by player

func _on_car_washed(money):
	print("Car washed! Earned: $", money)
	if current_car:
		# Send car to exit
		current_car.reached_destination.disconnect(_on_car_reached_wash_point)
		current_car.set_target(exit_point.global_transform.origin)
		current_car.reached_destination.connect(_on_car_reached_exit)

func _on_car_reached_exit(car):
	print("Car leaving...")
	# Remove car and allow new spawn
	if car:
		car.queue_free()
	current_car = null
	can_spawn = true
