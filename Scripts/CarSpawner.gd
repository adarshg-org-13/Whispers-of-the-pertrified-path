extends Node3D

@export var spawn_point_path: NodePath
@export var wash_point_path: NodePath
@export var exit_point_path: NodePath
@export var time_between_spawns = 5.0

@export var car_speed = 3.0
@export var rotation_speed = 2.0

@export var car_scenes: Array[PackedScene] = []

var current_car = null
var spawn_timer = 0.0
var can_spawn = true

var spawn_point
var wash_point
var exit_point

func _ready():
	spawn_point = get_node(spawn_point_path)
	wash_point = get_node(wash_point_path)
	exit_point = get_node(exit_point_path)
	
	if car_scenes.size() > 0:
		spawn_car()

func _process(delta):
	if can_spawn and current_car == null:
		spawn_timer += delta
		if spawn_timer >= time_between_spawns:
			spawn_car()
			spawn_timer = 0.0

func spawn_car():
	if car_scenes.size() == 0:
		return
	
	var car_scene = car_scenes[randi() % car_scenes.size()]
	var car = car_scene.instantiate()
	
	add_child(car)
	car.global_transform.origin = spawn_point.global_transform.origin
	
	if car.has_method("set_target"):
		car.set_target(wash_point.global_transform.origin)
		car.set_speed(car_speed)
		car.reached_destination.connect(_on_car_reached_wash_point)
		car.car_washed.connect(_on_car_washed)
	
	current_car = car
	can_spawn = false

func _on_car_reached_wash_point(car):
	pass

func _on_car_washed(money):
	if current_car:
		current_car.reached_destination.disconnect(_on_car_reached_wash_point)
		current_car.set_target(exit_point.global_transform.origin)
		current_car.reached_destination.connect(_on_car_reached_exit)

func _on_car_reached_exit(car):
	if car:
		car.queue_free()
	current_car = null
	can_spawn = true

#END
